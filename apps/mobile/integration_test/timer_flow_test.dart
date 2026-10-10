// End-to-end S5 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/timer_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// First-run tour (skipped) → Giấc ngủ tile → 25a → timer 25 → "Kết thúc giấc ngủ": one sleep
// record, the shared timer slot is gone. A sleep "by Ba" is seeded on the server, then an
// overlapping sleep is entered by hand (26): the server finds the overlap and 27 opens by
// itself; keeping Ba's moves mine to the 30-day bin. Breastfeed timer 23b: switch side, end →
// per-side minutes on the record.
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'timer.e2e@example.com';
const _password = 'e2e-only-password';

Future<String> _seedBaby() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '7c2d1e4f-3a5b-4c6d-8e9f-0a1b2c3d4e5f',
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

Object? _field(Map<String, dynamic> doc, String name) {
  final v = (doc['fields'] as Map?)?[name] as Map?;
  return v?['stringValue'] ?? v?['booleanValue'] ?? v?['integerValue'];
}

Future<List<Map<String, dynamic>>> _records(String babyId) async {
  final list = await firestoreGet('babies/$babyId/records');
  return ((list['documents'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
}

Future<void> _settleFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S5: sleep timer, overlap resolved, breastfeed timer', (
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

    // 18: the tour greets an empty Today (once per device); skip it.
    await pumpUntil(
      tester,
      find.text(l10n.todayTileEmpty),
      timeout: const Duration(seconds: 45),
    );
    await skipTourIfShown(tester);

    // 25a → 25 → end.
    await tester.tap(
      find.byWidgetPredicate((w) => w is CareTile && w.type == CareType.sleep),
    );
    await tapText(tester, l10n.sleepStartTimer);
    await pumpUntil(tester, find.text(l10n.sleepTimerTitle('Teddy')));
    await pumpUntil(tester, find.text(l10n.timerFamilySees));
    await _settleFor(tester, const Duration(seconds: 3));
    await tapText(tester, l10n.endSleep);
    await pumpUntil(tester, find.textContaining(l10n.awakeFor('').trim()));
    var records = await _records(babyId);
    expect(records.where((r) => _field(r, 'type') == 'sleep'), hasLength(1));
    final timerDoc = await firestoreGet('babies/$babyId/timers/sleep');
    expect(timerDoc['fields'], isNull, reason: 'the timer slot is freed');

    // A sleep by Ba, already on the server: 60 → 20 minutes ago.
    final now = DateTime.now();
    const dadsId = 'r_00000000000000000000000000000dad';
    await firestoreSet('babies/$babyId/records/$dadsId', {
      'id': dadsId,
      'babyId': babyId,
      'type': 'sleep',
      'occurredAt': now.subtract(const Duration(minutes: 60)),
      'endedAt': now.subtract(const Duration(minutes: 20)),
      'data': <String, Object?>{},
      'createdBy': 'u_dad',
      'author': {'name': 'Minh', 'relation': 'father', 'relationCustom': null},
      'createdAt': now.subtract(const Duration(minutes: 19)),
      'clientCreatedAt': now.subtract(const Duration(minutes: 19)),
      'updatedAt': now.subtract(const Duration(minutes: 19)),
      'updatedBy': 'u_dad',
      'deleted': false,
      'deletedAt': null,
      'deletedBy': null,
      'source': 'app',
    });

    // 26 by long-pressing "Ngủ" in "+": the last hour (default) overlaps Ba's.
    final plus = find.bySemanticsLabel(l10n.a11yQuickLog);
    await pumpUntil(tester, plus);
    await tester.tap(plus.first);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.longPress(find.text(l10n.quickSleep).last);
    await pumpUntil(tester, find.text(l10n.manualSleepTitle));
    await tapText(tester, l10n.saveSleep);

    // 27 opens by itself; keep Ba's.
    await pumpUntil(
      tester,
      find.text(l10n.overlapTitle),
      timeout: const Duration(seconds: 30),
    );
    await tester.tap(
      find.textContaining(l10n.careLoggedBy(l10n.relationFather)).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, l10n.keepSelected);
    await pumpUntil(tester, find.text(l10n.overlapKept));
    records = await _records(babyId);
    final binned = records.where(
      (r) => _field(r, 'deletedReason') == 'overlap',
    );
    expect(binned, hasLength(1));
    expect(
      _field(binned.single, 'createdBy'),
      FirebaseAuth.instance.currentUser!.uid,
    );

    // 23 → "Bấm giờ thay vì nhập" → 23b → switch side → end.
    await _settleFor(tester, const Duration(seconds: 4)); // let the toast go
    final breastTile = find.byWidgetPredicate(
      (w) => w is CareTile && w.type == CareType.breast,
    );
    await tester.ensureVisible(breastTile);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(breastTile);
    await pumpUntil(tester, find.text(l10n.feedSheetTitle));
    await tapText(tester, l10n.timerInstead);
    await pumpUntil(tester, find.text(l10n.breastTimerTitle('Teddy')));
    await _settleFor(tester, const Duration(seconds: 2));
    await tapText(tester, l10n.tapToSwitch);
    await _settleFor(tester, const Duration(seconds: 2));
    await tapText(tester, l10n.endFeed);
    final end = DateTime.now().add(const Duration(seconds: 20));
    Map<String, dynamic>? breast;
    while (breast == null && DateTime.now().isBefore(end)) {
      breast = (await _records(
        babyId,
      )).where((r) => _field(r, 'type') == 'breast').firstOrNull;
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(breast, isNotNull);
    final data =
        ((breast!['fields'] as Map)['data'] as Map)['mapValue']['fields']
            as Map;
    expect(data.keys, containsAll(['leftMin', 'rightMin', 'endSide']));
    expect((data['endSide'] as Map)['stringValue'], 'right');
  });
}
