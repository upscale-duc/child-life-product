import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'auto_save_engine.dart';

/// Tự lưu runs on iOS only in the beta (D-066 #3).
bool get autoSaveSupported => !kIsWeb && Platform.isIOS;

/// What the photo-library permission allows (AS05, AS13, AS14).
enum LibraryAccess { full, limited, denied, notDetermined }

LibraryAccess _access(String? s) => switch (s) {
  'full' => LibraryAccess.full,
  'limited' => LibraryAccess.limited,
  'notDetermined' => LibraryAccess.notDetermined,
  _ => LibraryAccess.denied,
};

/// Items added to the library since the last check, newest first.
@immutable
class LibraryChanges {
  const LibraryChanges({
    required this.ids,
    this.token,
    this.fromHistory = false,
    this.inserted = -1,
    this.videos = 0,
  });
  final List<String> ids;

  /// Where the next check starts (PhotoKit persistent change token).
  final Uint8List? token;

  /// True when [ids] came from the change history; false when they are everything created since
  /// a date and may include items already seen.
  final bool fromHistory;

  /// Dev diagnostics: ids the change history reported (−1 when it was not used), and videos in [ids].
  final int inserted;
  final int videos;
}

/// The phone's side (ios/Runner/AutoSave.swift). Every call fails soft: a broken library read
/// must never break Kỷ niệm.
class AutoSaveNative {
  AutoSaveNative({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('childlife/autosave'),
      supported = supported ?? autoSaveSupported;

  final MethodChannel _channel;

  /// False off iOS: every call answers "no access" without touching the channel.
  final bool supported;

  Future<LibraryAccess> access() async {
    if (!supported) return LibraryAccess.denied;
    try {
      return _access(await _channel.invokeMethod<String>('access'));
    } on Object {
      return LibraryAccess.denied;
    }
  }

  /// Shows the iOS prompt the first time; afterwards answers at once.
  Future<LibraryAccess> requestAccess() async {
    if (!supported) return LibraryAccess.denied;
    try {
      return _access(await _channel.invokeMethod<String>('requestAccess'));
    } on Object {
      return LibraryAccess.denied;
    }
  }

  /// AS13 "Chọn thêm ảnh": the iOS limited-library picker.
  Future<void> pickMore() => _quiet('pickMore');

  /// AS13 / AS14 "Mở Cài đặt điện thoại".
  Future<void> openSettings() => _quiet('openSettings');

  Future<LibraryChanges> changes({
    Uint8List? token,
    DateTime? since,
    bool photos = true,
    bool videos = true,
  }) async {
    final out = await _channel.invokeMapMethod<String, Object?>('changes', {
      'token': token,
      'since': since?.millisecondsSinceEpoch,
      'photos': photos,
      'videos': videos,
    });
    return LibraryChanges(
      ids: [for (final id in (out?['ids'] as List?) ?? const []) id as String],
      token: out?['token'] as Uint8List?,
      fromHistory: out?['fromHistory'] == true,
      inserted: (out?['inserted'] as num?)?.toInt() ?? -1,
      videos: (out?['videos'] as num?)?.toInt() ?? 0,
    );
  }

  /// Describes library items; items the library no longer has are left out.
  Future<List<AssetInfo>> analyze(List<String> ids) async {
    final out = await _channel.invokeListMethod<Object?>('analyze', {
      'ids': ids,
    });
    return [
      for (final m in out ?? const [])
        ?AssetInfo.fromMap(m! as Map<Object?, Object?>),
    ];
  }

  /// Describes a sample photo taken from Kỷ niệm (a file in the app's media cache).
  Future<AssetInfo?> analyzeFile(String path) async {
    final out = await _channel.invokeMapMethod<Object?, Object?>(
      'analyzeFile',
      {'path': path},
    );
    return out == null ? null : AssetInfo.fromMap({...out, 'captureAt': 0});
  }

  /// Saves a downloaded original to the library and returns its PhotoKit id (P-150).
  Future<String?> save(
    String path, {
    required bool video,
    String? album,
  }) async {
    final out = await _channel.invokeMapMethod<String, Object?>('save', {
      'path': path,
      'video': video,
      'album': album,
    });
    return out?['id'] as String?;
  }

  /// Dev diagnostics: the newest library items with their file names and dates.
  Future<List<Map<String, Object?>>> inspectRecent() async {
    final out = await _channel.invokeListMethod<Object?>('inspectRecent');
    return [
      for (final m in out ?? const [])
        (m! as Map<Object?, Object?>).cast<String, Object?>(),
    ];
  }

  Future<void> excludeFromBackup(String path) =>
      _quiet('excludeFromBackup', {'path': path});

  /// Calls from the phone: `backgroundCheck` (a background check is due) and `stopBackground`
  /// (iOS wants the time back). [onCheck] returns the notification text, or null.
  void listen({
    required Future<Map<String, Object?>?> Function() onCheck,
    required void Function() onStop,
  }) {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'backgroundCheck':
          return onCheck();
        case 'stopBackground':
          onStop();
      }
      return null;
    });
  }

  /// This Dart side can run background checks now ([headless]: started only for one).
  Future<void> backgroundReady({bool headless = false}) =>
      _quiet('backgroundReady', {'headless': headless});

  /// Asks iOS for the next background check (AR03), or cancels it.
  Future<void> schedule() => _quiet('schedule');
  Future<void> unschedule() => _quiet('unschedule');
  Future<bool> cancelProactiveAlerts() async {
    if (!supported) return true;
    try {
      return await _channel.invokeMethod<bool>('cancelProactiveAlerts') == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> notificationCapability() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('notificationCapability') ==
          true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _quiet(String method, [Object? args]) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on Object {
      // Nothing to do: the screen stays as it was.
    }
  }
}
