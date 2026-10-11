import 'dart:io';

import 'package:child_life/features/memories/background_uploads.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 10j on iOS: the Dart side of the background URLSession uploader. The native side is faked
/// here; what matters is that a file is never sent twice and outcomes map to the queue's errors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('childlife/uploads');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<String, Map<String, Object?>> native;
  late List<Map<String, Object?>> starts;
  late List<String> calls;
  late List<bool> tokenRefreshes;

  /// What the native start answers for a path (default: running).
  late Map<String, Object?> Function(String path) onStart;

  Future<void> event(Map<String, Object?> e) => messenger.handlePlatformMessage(
    channel.name,
    channel.codec.encodeMethodCall(MethodCall('event', e)),
    (_) {},
  );

  BackgroundTransport transport() => BackgroundTransport(
    token: (refresh) async {
      tokenRefreshes.add(refresh);
      return refresh ? 'fresh-token' : 'token';
    },
    bucket: 'child-life-dev.firebasestorage.app',
    host: 'localhost',
  );

  final job = UploadJob(
    path: 'babies/b_1/uploads/med_1',
    file: File('/tmp/med_1.jpg'),
    contentType: 'image/jpeg',
    babyId: 'b_1',
  );

  setUp(() {
    native = {};
    starts = [];
    calls = [];
    tokenRefreshes = [];
    onStart = (_) => {'state': 'running', 'sent': 0};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
      final path = args['path'] as String? ?? '';
      switch (call.method) {
        case 'status':
          return native[path];
        case 'start':
          starts.add(args);
          await Future<void>.delayed(Duration.zero);
          return native[path] = onStart(path);
        case 'forget':
          native.remove(path);
          return null;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('hands the file over with the token, bucket and Wi-Fi rule', () async {
    final t = transport();
    final video = UploadJob(
      path: 'babies/b_1/uploads/med_2',
      file: File('/tmp/med_2.mov'),
      contentType: 'video/quicktime',
      babyId: 'b_1',
      video: true,
      wifiOnly: true,
    );
    await t.handOff([video]);
    expect(starts.single, {
      'path': video.path,
      'file': '/tmp/med_2.mov',
      'contentType': 'video/quicktime',
      'token': 'token',
      'bucket': 'child-life-dev.firebasestorage.app',
      'host': 'localhost',
      'babyId': 'b_1',
      'video': true,
      'wifiOnly': true,
    });
  });

  test('joins a file already handed over and finishes on its event', () async {
    final t = transport();
    await t.handOff([job]);
    final sent = <int>[];
    final done = t.upload(job, sent.add);
    await pumpEventQueue();
    expect(starts, hasLength(1), reason: 'not sent twice');
    await event({'event': 'progress', 'path': job.path, 'sent': 512});
    await event({'event': 'done', 'path': job.path});
    await done;
    expect(sent, [0, 512]);
  });

  test(
    'a file that finished while the app was gone is not sent again',
    () async {
      native[job.path] = {'state': 'done', 'sent': 10, 'total': 10};
      await transport().upload(job, (_) {});
      expect(starts, isEmpty);
    },
  );

  test(
    'the hand-off and the loop asking together start the file once',
    () async {
      final t = transport();
      final handOff = t.handOff([job]);
      final upload = t.upload(job, (_) {});
      await handOff;
      await pumpEventQueue();
      expect(starts, hasLength(1));
      await event({'event': 'done', 'path': job.path});
      await upload;
    },
  );

  test('an earlier failure is forgotten and sent afresh', () async {
    native[job.path] = {'state': 'failed', 'code': 'network'};
    final t = transport();
    final upload = t.upload(job, (_) {});
    await pumpEventQueue();
    expect(calls, containsAllInOrder(['status', 'forget', 'start']));
    await event({'event': 'done', 'path': job.path});
    await upload;
  });

  test('Storage refusing the file is a rejection the queue shows', () async {
    onStart = (_) => {'state': 'failed', 'code': 'unauthorized'};
    await expectLater(
      transport().upload(job, (_) {}),
      throwsA(isA<UploadRejected>()),
    );
  });

  test('an expired ID token is refreshed once', () async {
    var first = true;
    onStart = (_) {
      if (first) {
        first = false;
        return {'state': 'failed', 'code': 'unauthenticated'};
      }
      return {'state': 'running', 'sent': 0};
    };
    final t = transport();
    final upload = t.upload(job, (_) {});
    await pumpEventQueue();
    expect(tokenRefreshes, [false, true]);
    expect(starts.last['token'], 'fresh-token');
    await event({'event': 'done', 'path': job.path});
    await upload;
  });

  Future<void> fail(String code) async {
    native[job.path] = {'state': 'failed', 'code': code};
    await event({'event': 'failed', 'path': job.path, 'code': code});
  }

  test('a broken upload session is started afresh once by itself', () async {
    final t = transport();
    final upload = t.upload(job, (_) {});
    await pumpEventQueue();
    // iOS resent a finished "finalize" and Storage said 400: a new session, not a failure.
    await fail('http-400');
    await pumpEventQueue();
    expect(starts, hasLength(2));
    await event({'event': 'done', 'path': job.path});
    await upload;
  });

  test(
    'a network failure twice is a Storage error the queue retries',
    () async {
      final t = transport();
      final upload = t.upload(job, (_) {});
      final failed = expectLater(
        upload,
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'network'),
        ),
      );
      await pumpEventQueue();
      await fail('network');
      await pumpEventQueue();
      await fail('network');
      await failed;
      expect(starts, hasLength(2));
    },
  );

  test('"Tạm dừng" stops everything handed over', () async {
    final t = transport();
    final upload = t.upload(job, (_) {});
    await pumpEventQueue();
    t.cancelAll();
    await expectLater(upload, throwsA(isA<UploadCancelled>()));
    await pumpEventQueue();
    expect(calls, contains('cancelAll'));
  });
}
