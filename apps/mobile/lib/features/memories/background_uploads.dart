import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'upload_queue.dart';

const _useEmulators = bool.fromEnvironment('CL_EMULATORS');

/// 10j "Khoá máy · tải nền & báo xong": files go through the app's background URLSession on iOS
/// (ios/Runner/BackgroundUploads.swift) and WorkManager on Android (BackgroundUploads.kt), so they
/// keep uploading with the phone locked or the app closed; iOS shows the upload Live Activity,
/// Android an ongoing progress notice, and both the "Đã tải xong" notice.
///
/// The native side remembers each file's outcome by storage path. Before sending, this asks for
/// it: a file that finished while the app was gone is not sent again (Storage would refuse it —
/// the slot is no longer "uploading" — and the item would wrongly show as failed).
class BackgroundTransport implements UploadTransport {
  static Future<void> cancelDeviceWork() async {
    try {
      await const MethodChannel(
        'childlife/uploads',
      ).invokeMethod<void>('cancelAll', {'forget': true});
    } on MissingPluginException {
      // No native transport on this platform/test host.
    }
  }

  BackgroundTransport({
    required this.token,
    required this.bucket,
    this.host,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('childlife/uploads') {
    _channel.setMethodCallHandler(_onEvent);
  }

  factory BackgroundTransport.forApp() => BackgroundTransport(
    token: (refresh) async =>
        FirebaseAuth.instance.currentUser?.getIdToken(refresh),
    bucket: Firebase.app().options.storageBucket ?? '',
    host: _useEmulators ? emulatorHost : null,
  );

  /// The person's Firebase ID token (refreshed when asked).
  final Future<String?> Function(bool refresh) token;
  final String bucket;

  /// The Storage emulator host (port 9199), or null for Firebase.
  final String? host;
  final MethodChannel _channel;

  final _waiting = <String, Completer<String?>>{};
  final _progress = <String, void Function(int)>{};
  final _starting = <String, Future<Map<String, Object?>>>{};

  Future<Object?> _onEvent(MethodCall call) async {
    if (call.method != 'event') return null;
    final e = (call.arguments as Map).cast<String, Object?>();
    final path = e['path'] as String? ?? '';
    switch (e['event']) {
      case 'progress':
        _progress[path]?.call((e['sent'] as num? ?? 0).toInt());
      case 'done':
        _settle(path, null);
      case 'failed':
        _settle(path, e['code'] as String? ?? 'unknown');
      case 'cancelled':
        _settle(path, 'cancelled');
    }
    return null;
  }

  /// null = done; otherwise the failure code.
  void _settle(String path, String? code) {
    final c = _waiting.remove(path);
    if (c != null && !c.isCompleted) c.complete(code);
  }

  Future<Map<String, Object?>> _start(UploadJob job, {bool refresh = false}) {
    // One start per file at a time: the hand-off and the loop may ask together.
    return _starting[job.path] ??= () async {
      try {
        final id = await token(refresh);
        if (id == null) {
          return {'state': 'failed', 'code': 'unauthenticated'};
        }
        final r = await _channel.invokeMapMethod<String, Object?>('start', {
          'path': job.path,
          'file': job.file.path,
          'contentType': job.contentType,
          'token': id,
          'bucket': bucket,
          'host': host,
          'babyId': job.babyId,
          'video': job.video,
          'wifiOnly': job.wifiOnly,
        });
        return r ?? {'state': 'failed', 'code': 'unknown'};
      } finally {
        _starting.remove(job.path);
      }
    }();
  }

  Future<Map<String, Object?>?> _status(String path) =>
      _channel.invokeMapMethod<String, Object?>('status', {'path': path});

  /// Starts at a time: each "start" is a round trip to Storage, so 24 files one after another
  /// kept the first byte waiting ~8 s; a few at once keep the order near enough.
  static const _handOffWidth = 3;

  @override
  Future<void> handOff(List<UploadJob> jobs) async {
    Future<void> one(UploadJob job) async {
      final known = await _status(job.path);
      if (known != null && known['state'] != 'failed') return;
      await _start(job);
    }

    for (var i = 0; i < jobs.length; i += _handOffWidth) {
      await Future.wait(jobs.skip(i).take(_handOffWidth).map(one));
    }
  }

  @override
  Future<void> expect(String babyId, int count) =>
      _channel.invokeMethod<void>('expect', {'babyId': babyId, 'count': count});

  /// A broken resumable session (closed, expired), a dropped connection, or a transfer the
  /// platform lost while the app was gone (`lost`, see the native reconcile): one fresh start.
  static const _restartable = {
    'network',
    'http-400',
    'http-404',
    'http-410',
    'lost',
  };

  @override
  Future<void> upload(UploadJob job, void Function(int sent) onProgress) async {
    // An expired ID token is refreshed once, and a broken session started afresh once;
    // everything else is the queue's to show and retry.
    var refreshed = false;
    var restarted = false;
    while (true) {
      final code = await _send(job, onProgress, refresh: refreshed);
      if (code == null) return;
      if (code == 'unauthenticated' && !refreshed) {
        refreshed = true;
        continue;
      }
      if (_restartable.contains(code) && !restarted) {
        restarted = true;
        continue;
      }
      throw switch (code) {
        'cancelled' => UploadCancelled(),
        'unauthorized' => const UploadRejected('unauthorized'),
        _ => FirebaseException(plugin: 'storage', code: code),
      };
    }
  }

  Future<String?> _send(
    UploadJob job,
    void Function(int sent) onProgress, {
    required bool refresh,
  }) async {
    final waiter = _waiting[job.path] ??= Completer<String?>();
    _progress[job.path] = onProgress;
    try {
      final known = await _status(job.path);
      switch (known?['state']) {
        case 'done':
          _settle(job.path, null);
        case 'running':
          onProgress((known!['sent'] as num? ?? 0).toInt());
        default:
          // Never sent, or a failure from before: send it (again).
          if (known != null) {
            await _channel.invokeMethod<void>('forget', {'path': job.path});
          }
          final r = await _start(job, refresh: refresh);
          if (r['state'] == 'done') _settle(job.path, null);
          if (r['state'] == 'failed') {
            _settle(job.path, r['code'] as String? ?? 'unknown');
          }
      }
      return await waiter.future;
    } finally {
      _waiting.remove(job.path);
      _progress.remove(job.path);
    }
  }

  @override
  void cancel(String storagePath) {
    unawaited(_channel.invokeMethod<void>('cancel', {'path': storagePath}));
    _settle(storagePath, 'cancelled');
  }

  @override
  void cancelAll() {
    unawaited(_channel.invokeMethod<void>('cancelAll'));
    for (final path in [..._waiting.keys]) {
      _settle(path, 'cancelled');
    }
  }
}

/// The host machine as the phone sees it, for the local emulators (Android: 10.0.2.2).
String get emulatorHost =>
    defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
