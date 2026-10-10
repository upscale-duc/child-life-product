// End-to-end S4 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/care_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A parent (seeded over REST with all six trackers) logs a bottle from its tile (22), a diaper
// from "+" (19a → 24), then pumping while Firestore is offline: the tile reads "Chờ đồng bộ"
// and 9b lists it until "Thử lại ngay". The server's day summary and the member's record count
// follow (onCareRecordWrite). The bottle is deleted from 21 and restored with "Hoàn tác"; a
// growth measurement is saved from 28.
import 'package:child_life/features/care/care_format.dart';
import 'package:child_life/main.dart' as app;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'care.e2e@example.com';
const _password = 'e2e-only-password';

Future<String> _seedBaby() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '5a1e3c9d-2b7f-4e61-8c0a-9d4b2f6e7a18',
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

/// Today's date in the baby's zone (GMT+7, no DST).
String _babyToday() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 7))
    .toIso8601String()
    .substring(0, 10);

Future<Map<String, dynamic>> _until(
  String path,
  bool Function(Map<String, dynamic> doc) ok,
) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  var doc = <String, dynamic>{};
  while (DateTime.now().isBefore(end)) {
    doc = await firestoreGet(path);
    if (doc['fields'] != null && ok(doc)) return doc;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TestFailure('Timed out waiting for $path: $doc');
}

Object? _field(Map<String, dynamic> doc, List<String> path) {
  Object? node = doc['fields'];
  for (final key in path) {
    node = (node as Map?)?[key];
    if (node is Map && node['mapValue'] != null) {
      node = (node['mapValue'] as Map)['fields'];
    }
  }
  if (node is Map) {
    return node['integerValue'] ?? node['stringValue'] ?? node['booleanValue'];
  }
  return node;
}

/// Android shows the software keyboard (the sheet then scrolls); tap on with it closed.
Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'S4: log, offline save and sync, totals, delete and undo, growth',
    (tester) async {
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

      // 22: tile → 120 ml formula → "Lưu cữ bú".
      await tapText(tester, l10n.trackerBottle);
      await pumpUntil(tester, find.text(l10n.feedSheetTitle));
      await tester.enterText(find.byType(EditableText).first, '120');
      await _hideKeyboard(tester);
      await tapText(tester, l10n.milkFormula);
      await tapText(tester, l10n.saveFeed);
      await pumpUntil(tester, find.text(l10n.amountMl(120)));
      await pumpUntil(tester, find.text(l10n.careLoggedBy(l10n.careYou)));

      // 19a "+" → 24 Thay tã → "Lưu" (default Ướt).
      final plus = find.bySemanticsLabel(l10n.a11yQuickLog);
      await pumpUntil(tester, plus);
      await tester.tap(plus.first);
      await tester.pump(const Duration(milliseconds: 600));
      await tapText(tester, l10n.trackerDiaper);
      await pumpUntil(tester, find.text(l10n.diaperTitle));
      await tapText(tester, l10n.actionSave);
      await pumpUntil(tester, find.text(l10n.diaperWetValue));

      // Offline: pumping is saved on the device and shown as waiting (9a / 9b).
      await FirebaseFirestore.instance.disableNetwork();
      await tapText(tester, l10n.trackerPump);
      await pumpUntil(tester, find.text(l10n.pumpTitle));
      await tester.enterText(find.byType(EditableText).first, '90');
      await _hideKeyboard(tester);
      await tapText(tester, l10n.savePump);
      await pumpUntil(tester, find.text(l10n.amountMl(90)));
      await pumpUntil(tester, find.text(l10n.carePending));
      final banner = find.textContaining(l10n.syncingBanner(1));
      await pumpUntil(tester, banner);
      await tester.tap(banner.first);
      await pumpUntil(tester, find.text(l10n.pendingOnlyHere));
      await tapText(tester, l10n.retryNow); // also turns the network back on
      final end = DateTime.now().add(const Duration(seconds: 20));
      while (find.text(l10n.carePending).evaluate().isNotEmpty &&
          DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text(l10n.carePending), findsNothing);

      // Server: the day summary and "đã ghi N lần" follow the records.
      final day = await _until(
        'babies/$babyId/days/${_babyToday()}',
        (d) => _field(d, ['pump', 'ml']) == '90',
      );
      expect(_field(day, ['bottle', 'count']), '1');
      expect(_field(day, ['bottle', 'ml']), '120');
      expect(_field(day, ['diaper', 'wet']), '1');
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _until(
        'babies/$babyId/members/$uid',
        (d) => _field(d, ['recordCount']) == '3',
      );

      // 21: long-press the bottle tile → delete → "Hoàn tác".
      await tester.longPress(find.text(l10n.amountMl(120)).first);
      await pumpUntil(tester, find.text(l10n.deleteRecord));
      await tapText(tester, l10n.deleteRecord);
      await pumpUntil(tester, find.text(l10n.deleteConfirmTitle));
      await tapText(tester, l10n.deleteRecord);
      await pumpUntil(tester, find.text(l10n.undo));
      await tester.tap(find.text(l10n.undo).last);
      await tester.pump(const Duration(seconds: 1));
      await pumpUntil(tester, find.text(l10n.amountMl(120)));
      final records = await firestoreGet('babies/$babyId/records');
      final docs = (records['documents'] as List).cast<Map<String, dynamic>>();
      expect(docs, hasLength(3));
      expect(docs.every((d) => _field(d, ['deleted']) == false), isTrue);

      // 28: growth from its tile.
      await tester.ensureVisible(find.text(l10n.trackerGrowth));
      await tapText(tester, l10n.trackerGrowth);
      await pumpUntil(tester, find.text(l10n.saveGrowth));
      await tester.enterText(find.byType(EditableText).at(0), '4,3');
      await _hideKeyboard(tester);
      await tapText(tester, l10n.saveGrowth);
      final locale = Localizations.localeOf(
        tester.element(find.byType(Navigator).first),
      ).toLanguageTag();
      await pumpUntil(tester, find.text(l10n.weightKg(decimal(locale, 4.3))));
    },
  );
}
