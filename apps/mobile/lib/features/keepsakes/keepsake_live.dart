import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'keepsake_jobs.dart';

/// MM08 on iPhone: a Video kỷ niệm being made, as a Live Activity on the lock screen and in the
/// Dynamic Island (ios/Runner/KeepsakeLive.swift, ios/widget/KeepsakeLive.swift). Started on
/// "Tạo video"; its push token goes to Functions (`attachMemoryStoryLive`), which move it on as
/// the job renders, even with the app closed; while the app is open the job moves it on too.
/// Step and percent only — never a photo, a text or the baby's name (R-116).
class KeepsakeLive {
  KeepsakeLive(
    this._jobs, {
    MethodChannel? channel,
    Future<String?> Function()? fcmToken,
  }) : _channel = channel ?? const MethodChannel('childlife/keepsakeLive'),
       _fcmToken = fcmToken ?? (() => FirebaseMessaging.instance.getToken());

  final KeepsakeJobRepository _jobs;
  final MethodChannel _channel;
  final Future<String?> Function() _fcmToken;

  static bool get _on => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Hands Functions each activity's push token, also the ones still running after a relaunch.
  void listen() {
    if (!_on) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'token' || call.arguments is! Map) return;
      final a = (call.arguments as Map).cast<String, Object?>();
      final fcm = await _fcmToken();
      if (fcm == null) return;
      try {
        await _jobs.attachLive(
          babyId: a['babyId']! as String,
          jobId: a['jobId']! as String,
          token: a['token']! as String,
          fcm: fcm,
        );
      } on Object {
        // The job still finishes and tells them by push; the activity follows while the app is
        // open.
      }
    });
    unawaited(_invoke('resume', const {}));
  }

  /// "Tạo video": the activity for [jobId], in the app's language.
  Future<void> start({
    required String babyId,
    required String jobId,
    required String? templateName,
    required AppLocalizations l10n,
  }) => _invoke('start', {
    'jobId': jobId,
    'babyId': babyId,
    'status': 'queued',
    'progress': 0,
    'copy': keepsakeLiveCopy(l10n, templateName),
  });

  /// The job as the app sees it (ends the activity once it finishes).
  Future<void> update(KeepsakeJob job) => _invoke('update', {
    'jobId': job.id,
    'status': job.status.name,
    'step': job.step,
    'progress': job.progress,
  });

  Future<void> _invoke(String method, Map<String, Object?> args) async {
    if (!_on) return;
    try {
      await _channel.invokeMethod<Object?>(method, args);
    } on Object {
      // No Live Activities on this device or OS version.
    }
  }
}

/// The Live Activity's copy (D-012), by the keys ios/widget/KeepsakeLive.swift reads.
Map<String, String> keepsakeLiveCopy(
  AppLocalizations l10n,
  String? templateName,
) => {
  'appName': 'Child Life',
  'title': l10n.ksVideoTitle,
  'template': ?templateName,
  'queued': l10n.ksLiveQueued,
  'arrange': l10n.ksLiveArrange,
  'compose': l10n.ksLiveCompose,
  'export': l10n.ksLiveExport,
  'completed': l10n.ksVideoReady,
  'completedSub': l10n.ksLiveReadySub,
  'failed': l10n.ksVideoFailed,
  'failedSub': l10n.ksLiveFailedSub,
};

final keepsakeLiveProvider = Provider<KeepsakeLive>(
  (ref) => KeepsakeLive(ref.watch(keepsakeJobRepositoryProvider))..listen(),
);
