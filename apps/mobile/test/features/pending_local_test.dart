import 'package:child_life/features/reminders/rule_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('childlife/rules');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('iOS: the plugin\'s pending notifications, by id and payload', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pendingLocal');
      return [
        {'id': 268435712, 'payload': '{"k":"wake_check"}'},
        {'id': 7},
      ];
    });
    expect(await const RuleNotificationChannel().pendingLocal(), [
      (id: 268435712, payload: '{"k":"wake_check"}'),
      (id: 7, payload: null),
    ]);
  });

  test('elsewhere (no such method) falls back to the plugin', () async {
    expect(await const RuleNotificationChannel().pendingLocal(), isNull);
  });
}
