// End-to-end S11 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/me_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A parent opens Tôi (13a) → Dung lượng (13b, from getFamilyStorage) → "Liên hệ quản trị" →
// +20 GB → "Gửi yêu cầu" (13e, D-010); edits the baby (13k); turns a notification kind off
// (G-056); sends a help ticket (G-057); then deletes the baby (13l): the server purge runs as a
// job and the profile is gone only once it is verified (flow F).
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'me.e2e@example.com';
const _password = 'e2e-only-password';

Future<String> _seedBaby() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '7a1d2c3b-4a5f-4b6c-8d7e-0f1a2b3c4d5f',
    'nickname': 'Teddy',
    'dateOfBirth': '2026-09-17',
    'gender': 'boy',
    'timeZone': {'mode': 'auto', 'zone': 'Asia/Ho_Chi_Minh'},
    'avatarPreset': 1,
    'trackers': ['bottle', 'breast', 'sleep', 'diaper'],
    'self': {'displayName': 'Mai', 'relation': 'mother'},
  });
  return result['babyId'] as String;
}

Future<List<Map<String, dynamic>>> _docs(String path) async {
  final list = await firestoreGet(path);
  return [
    for (final d in (list['documents'] as List? ?? const []))
      (d as Map).cast<String, dynamic>(),
  ];
}

Future<void> _until(
  WidgetTester tester,
  Future<bool> Function() ok, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (await ok()) return;
    await tester.pump(const Duration(milliseconds: 500));
  }
  throw TestFailure('Timed out');
}

Future<void> _openMe(WidgetTester tester, String label) async {
  final tab = find.bySemanticsLabel(label);
  await pumpUntil(tester, tab);
  await tester.tap(tab.first);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tapRow(WidgetTester tester, String text) async {
  await pumpUntil(tester, find.text(text));
  await tester.scrollUntilVisible(
    find.text(text).last,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _back(WidgetTester tester, String _) async {
  await pumpUntil(tester, find.byType(ClBackButton));
  await tester.tap(find.byType(ClBackButton).last);
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S11: storage request, baby edit, notifications, help, delete', (
    tester,
  ) async {
    await resetEmulators();
    final babyId = await _seedBaby();
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

    // Tôi (13a) → Dung lượng (13b) → 13e: +20 GB.
    await _openMe(tester, l10n.tabMe);
    await pumpUntil(tester, find.text(l10n.meStorageShared));
    await _tapRow(tester, l10n.meStorage);
    await _tapRow(tester, l10n.stContact);
    await tapText(tester, '+20 GB');
    await tapText(tester, l10n.stReqSend);
    await _until(tester, () async {
      final r = await _docs('storageRequests');
      return r.length == 1 && stringField(r.single, 'status') == 'open';
    });
    expect((await _docs('mail')).length, 2);
    await _back(tester, l10n.a11yBack);

    // Hồ sơ các bé (13i) → Teddy (13j) → Sửa (13k): "Teddy" → "Tí".
    await _tapRow(tester, l10n.meBabies);
    await _tapRow(tester, 'Teddy');
    await tapText(tester, l10n.actionEdit);
    await pumpUntil(tester, find.text(l10n.bpSave));
    await tester.enterText(find.byType(EditableText).first, 'Tí');
    await tester.pump();
    await tapText(tester, l10n.bpSave);
    await _until(
      tester,
      () async =>
          stringField(await firestoreGet('babies/$babyId'), 'nickname') == 'Tí',
    );
    await _back(tester, l10n.a11yBack);
    await _back(tester, l10n.a11yBack);

    // Thông báo (G-056): "Kỷ niệm mới" off.
    await _tapRow(tester, l10n.meNotifications);
    await pumpUntil(tester, find.text(l10n.ntMemories));
    await tester.tap(find.byType(ClToggle).first);
    await _until(tester, () async {
      final users = await _docs('users');
      final uid = (users.single['name'] as String).split('/').last;
      final prefs = await firestoreGet('users/$uid/settings/notifications');
      final f = (prefs['fields'] as Map?)?['memories'] as Map?;
      return f?['booleanValue'] == false;
    });
    await _back(tester, l10n.a11yBack);

    // Trợ giúp & liên hệ (G-057), without diagnostics.
    await _tapRow(tester, l10n.meHelp);
    await tapText(tester, l10n.hpCatStorage);
    await tester.enterText(find.byType(EditableText).first, 'E2E help');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byType(ClToggle).first);
    await tester.pump();
    await _tapRow(tester, l10n.messageSend);
    await _until(tester, () async {
      final t = await _docs('supportTickets');
      return t.length == 1 && stringField(t.single, 'ticket') == 'CL-1001';
    });

    // Xoá hồ sơ (13l): writes lock, the job purges, and only then the profile is gone.
    await _tapRow(tester, l10n.meBabies);
    await _tapRow(tester, 'Tí');
    await _tapRow(tester, l10n.bpDelete('Tí'));
    await pumpUntil(tester, find.text(l10n.bpDelConfirm));
    await tester.enterText(find.byType(EditableText).last, 'Tí');
    await tester.pump();
    await tapText(tester, l10n.bpDelConfirm);
    await _until(tester, () async {
      final job = await firestoreGet('deletionJobs/del_$babyId');
      return stringField(job, 'state') == 'done';
    }, timeout: const Duration(seconds: 90));
    final baby = await firestoreGet('babies/$babyId');
    expect(baby['fields'], isNull, reason: 'baby document purged');
    final members = await _docs('babies/$babyId/members');
    expect(members, isEmpty);
    // The account has no baby left: setup opens again.
    await pumpUntil(
      tester,
      find.text(l10n.whoTitle),
      timeout: const Duration(seconds: 30),
    );
  });
}
