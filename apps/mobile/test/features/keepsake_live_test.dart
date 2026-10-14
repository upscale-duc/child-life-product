import 'package:child_life/features/keepsakes/keepsake_live.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/keepsake_fixtures.dart';

/// MM08 on Android (A6): no Live Activity; "Tạo video" shows the progress notice and has
/// Functions send the job's moments to this phone's FCM token.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/keepsakeLive');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  test(
    'Android: the notice starts and the job is attached by FCM only',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final jobs = FakeKeepsakeJobs();
      await KeepsakeLive(
        jobs,
        channel: channel,
        fcmToken: () async => 'fcm-1',
      ).start(
        babyId: 'b1',
        jobId: 'job_1',
        templateName: 'Tháng đầu',
        l10n: AppLocalizationsVi(),
      );
      expect(calls.single.method, 'start');
      expect(
        (calls.single.arguments as Map)['copy'],
        containsPair('title', isNotEmpty),
      );
      expect(jobs.live, ['job_1:null']);
    },
  );

  test(
    'iOS: the activity starts; its token is attached when the phone sends it',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final jobs = FakeKeepsakeJobs();
      await KeepsakeLive(
        jobs,
        channel: channel,
        fcmToken: () async => 'fcm-1',
      ).start(
        babyId: 'b1',
        jobId: 'job_1',
        templateName: null,
        l10n: AppLocalizationsVi(),
      );
      expect(calls.single.method, 'start');
      expect(jobs.live, isEmpty);
    },
  );
}
