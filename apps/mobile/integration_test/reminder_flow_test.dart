// End-to-end S7 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   # Android only, while the test runs (flutter test reinstalls the app, dropping grants):
//   while true; do adb shell pm grant app.childlife.dev android.permission.POST_NOTIFICATIONS; sleep 1; done
//   flutter test integration_test/reminder_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A parent opens Nhắc việc from Today's ReminderPeek, creates a reminder (8b); the server keeps it
// with this install as the notifying device (R-091). With notifications allowed (Android, granted
// over adb) the OS holds exactly one pending notification at due − "Báo trước"; on the iOS
// simulator (cannot pre-grant) 8c is answered "Để sau" and 8d's card shows. A caregiver-style
// mark done from 8e, the undo from the list ring (D-030), then "Xoá nhắc việc" removes it.
import 'dart:io';

import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'reminder.e2e@example.com';
const _password = 'e2e-only-password';

Future<String> _seedBaby() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '7c2d4e6f-8a9b-4c1d-9e2f-3a4b5c6d7e8f',
    'nickname': 'Teddy',
    'dateOfBirth': '2026-09-17',
    'gender': 'boy',
    'timeZone': {'mode': 'auto', 'zone': 'Asia/Ho_Chi_Minh'},
    'avatarPreset': 1,
    'trackers': ['bottle', 'breast', 'sleep', 'diaper', 'pump', 'growth'],
    'self': {'displayName': 'Mai', 'relation': 'mother'},
  });
  return result['babyId'] as String;
}

Map<String, dynamic>? _fields(Map<String, dynamic> doc) =>
    doc['fields'] as Map<String, dynamic>?;

Future<List<Map<String, dynamic>>> _reminders(String babyId) async {
  final list = await firestoreGet('babies/$babyId/reminders');
  return [
    for (final d in (list['documents'] as List? ?? const []))
      (d as Map).cast<String, dynamic>(),
  ];
}

Future<List<Map<String, dynamic>>> _untilReminders(
  String babyId,
  bool Function(List<Map<String, dynamic>> docs) ok,
) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  var docs = <Map<String, dynamic>>[];
  while (DateTime.now().isBefore(end)) {
    docs = await _reminders(babyId);
    if (ok(docs)) return docs;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TestFailure('Timed out waiting for reminders: $docs');
}

Object? _value(Map<String, dynamic> doc, String key, [String? sub]) {
  Object? node = _fields(doc)?[key];
  if (sub != null) {
    node = ((node as Map?)?['mapValue'] as Map?)?['fields'];
    node = (node as Map?)?[sub];
  }
  if (node is Map) {
    return node['stringValue'] ??
        node['integerValue'] ??
        node['booleanValue'] ??
        node['timestampValue'] ??
        (node.containsKey('nullValue') ? null : node);
  }
  return node;
}

Future<bool> _waitForGrant(WidgetTester tester) async {
  final plugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    if (await plugin?.areNotificationsEnabled() ?? false) return true;
    await tester.pump(const Duration(milliseconds: 500));
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S7: create, notify on this device, done, undo, delete', (
    tester,
  ) async {
    await resetEmulators();
    final babyId = await _seedBaby();
    // 8c is asked once per install; start as a fresh one.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminders.notificationsAsked');

    final testOnError = FlutterError.onError;
    await app.main();
    FlutterError.onError = testOnError;
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 2));
    final l10n = l10nOf(tester);

    await tapText(tester, l10n.welcomeSignIn);
    await tapText(tester, l10n.signInEmail);
    await tapText(tester, l10n.emailSignInTab);
    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await tester.pump();
    await tapText(tester, l10n.emailSignInButton);
    await pumpUntil(
      tester,
      find.text(l10n.todayTileEmpty),
      timeout: const Duration(seconds: 45),
    );
    await skipTourIfShown(tester);
    // Notifications allowed: Android with the grant applied over adb (see the header).
    final android = Platform.isAndroid && await _waitForGrant(tester);
    debugPrint('S7 e2e: notifications allowed = $android');

    // ReminderPeek (empty) → 8b straight away for a parent.
    await tester.ensureVisible(find.text(l10n.reminderPeekEmpty));
    await tapText(tester, l10n.reminderPeekEmpty);
    await pumpUntil(tester, find.text(l10n.reminderSave));
    await tester.enterText(find.byType(EditableText).first, 'Tiêm 6 trong 1');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 600));
    await tapText(tester, l10n.reminderSave);

    if (!android) {
      // 8c after the first save; "Để sau" keeps the reminder (R-092) → 8d.
      await pumpUntil(tester, find.text(l10n.notifPromptTitle));
      await tapText(tester, l10n.actionLater);
    }

    var docs = await _untilReminders(babyId, (d) => d.length == 1);
    final doc = docs.single;
    expect(_value(doc, 'title'), 'Tiêm 6 trong 1');
    expect(_value(doc, 'leadMinutes'), '60');
    expect(_value(doc, 'done'), false);
    expect(
      _value(doc, 'notifyDevice', 'id').toString(),
      matches(RegExp(r'^d_[a-f0-9]{32}$')),
    );
    final uid = FirebaseAuth.instance.currentUser!.uid;
    expect(_value(doc, 'notifyDevice', 'uid'), uid);
    final dueAt = DateTime.parse(_value(doc, 'dueAt')! as String);

    if (android) {
      // Granted over adb: exactly one pending notification at due − 1 giờ, nothing else.
      final plugin = FlutterLocalNotificationsPlugin();
      final end = DateTime.now().add(const Duration(seconds: 10));
      var pending = <PendingNotificationRequest>[];
      while (DateTime.now().isBefore(end)) {
        pending = await plugin.pendingNotificationRequests();
        if (pending.isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(pending, hasLength(1));
      expect(pending.single.title, 'Tiêm 6 trong 1');
      expect(pending.single.payload, contains('"at":'));
      expect(
        pending.single.payload,
        contains(
          '${dueAt.subtract(const Duration(hours: 1)).millisecondsSinceEpoch}',
        ),
      );
    }

    // Today's peek counts it; 8a → 8e → "Đánh dấu đã xong".
    await pumpUntil(tester, find.text(l10n.reminderPeekLabel(1)));
    await tapText(tester, 'Tiêm 6 trong 1');
    await pumpUntil(tester, find.text(l10n.remindersTitle));
    // 8d: saved, but this device cannot notify (iOS: "Để sau" on 8c).
    expect(
      find.text(l10n.remindersNotifOff),
      android ? findsNothing : findsOneWidget,
    );
    await tapText(tester, 'Tiêm 6 trong 1');
    await pumpUntil(tester, find.text(l10n.reminderMarkDone));
    await tapText(tester, l10n.reminderMarkDone);
    docs = await _untilReminders(
      babyId,
      (d) => d.isNotEmpty && _value(d.single, 'done') == true,
    );
    expect(_value(docs.single, 'doneBy'), uid);

    if (android) {
      // Done → the notification is cancelled.
      final end = DateTime.now().add(const Duration(seconds: 10));
      var pending = await FlutterLocalNotificationsPlugin()
          .pendingNotificationRequests();
      while (pending.isNotEmpty && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 300));
        pending = await FlutterLocalNotificationsPlugin()
            .pendingNotificationRequests();
      }
      expect(pending, isEmpty);
    }

    // Undo from the list ring (D-030).
    await pumpUntil(tester, find.text(l10n.remindersDone));
    final ring = find.bySemanticsLabel(l10n.a11yUndoDone('Tiêm 6 trong 1'));
    await pumpUntil(tester, ring);
    await tester.tap(ring.first);
    await tester.pump(const Duration(milliseconds: 400));
    await _untilReminders(
      babyId,
      (d) => d.isNotEmpty && _value(d.single, 'done') == false,
    );

    // 8e → "Sửa nhắc việc" → "Xoá nhắc việc" (D-030).
    await tapText(tester, 'Tiêm 6 trong 1');
    await pumpUntil(tester, find.text(l10n.reminderEditTitle));
    await tapText(tester, l10n.reminderEditTitle);
    await pumpUntil(tester, find.text(l10n.reminderDelete));
    await tapText(tester, l10n.reminderDelete);
    await pumpUntil(tester, find.text(l10n.reminderDeleteTitle));
    await tapText(tester, l10n.reminderDelete);
    await _untilReminders(babyId, (d) => d.isEmpty);
    await pumpUntil(tester, find.text(l10n.remindersTitle));
  });
}
