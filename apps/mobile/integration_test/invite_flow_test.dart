// End-to-end S3 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/invite_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// Owner (seeded over REST: verified email, baby Teddy) signs in → 14a → 14b (Bà · Người chăm
// sóc) → 14c → Email tab → 14d, and the pending row appears. Sign out → 01 "Mã mời" → 15 → 16
// → 16b "Vào ngay" → 16a → Today as a temporary caregiver with the 16c banner → 16d "Dùng
// email" keeps the same uid. The owner then removes the member → 9d on this device.
import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only accounts that exist solely in the local Auth emulator.
const _ownerEmail = 'owner.e2e@example.com';
const _ownerPassword = 'e2e-only-password';
const _inviteeEmail = 'ba.ngoai.e2e@example.com';
const _inviteePassword = 'e2e-only-password-2';

Future<String> _seedOwnerWithTeddy() async {
  final uid = await emulatorSignUp(_ownerEmail, _ownerPassword);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_ownerEmail, _ownerPassword);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '0b0f4a8e-5a43-4c55-9f0e-2f1c7c2d9a11',
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

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.bySemanticsLabel(label);
  await pumpUntil(tester, tab);
  await tester.tap(tab.first);
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S3: invite by email, join with the code, save, lose access', (
    tester,
  ) async {
    await resetEmulators();
    final babyId = await _seedOwnerWithTeddy();

    final testOnError = FlutterError.onError;
    await app.main();
    FlutterError.onError = testOnError;
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 2));
    final l10n = l10nOf(tester);

    // Owner signs in → Today → Gia đình.
    await tapText(tester, l10n.welcomeSignIn);
    await tapText(tester, l10n.signInEmail);
    await tapText(tester, l10n.emailSignInTab);
    await tester.enterText(find.byType(EditableText).at(0), _ownerEmail);
    await tester.enterText(find.byType(EditableText).at(1), _ownerPassword);
    await tester.pump();
    await tapText(tester, l10n.emailSignInButton);
    await pumpUntil(
      tester,
      find.text(l10n.todayTileEmpty),
      timeout: const Duration(seconds: 45),
    );
    await _openTab(tester, l10n.tabFamily);
    await pumpUntil(tester, find.text(l10n.familySubtitle('Teddy')));
    expect(find.text(l10n.familyYou), findsOneWidget);

    // 14b → 14c
    await tapText(tester, l10n.familyInvite);
    await tapText(tester, l10n.relationGrandmother);
    await tapText(tester, l10n.inviteNext);
    await pumpUntil(
      tester,
      find.text(l10n.inviteSendTitle(l10n.relationGrandmother)),
      timeout: const Duration(seconds: 30),
    );
    final pending = await firestoreGet('babies/$babyId/pendingInvites');
    final invite =
        (pending['documents'] as List).single as Map<String, dynamic>;
    final code = stringField(invite, 'code')!;
    expect(code, matches(RegExp(r'^\d{6}$')));
    expect(stringField(invite, 'role'), 'caregiver');

    // Email tab → 14d; the mail is queued (SES is not configured on the emulator).
    await tapText(tester, l10n.inviteChannelEmail);
    await tester.enterText(find.byType(EditableText).first, _inviteeEmail);
    await tester.pump();
    await tapText(tester, l10n.inviteEmailSend);
    await pumpUntil(
      tester,
      find.text(l10n.inviteSentTitle(l10n.relationGrandmother)),
      timeout: const Duration(seconds: 30),
    );
    final mail = await firestoreGet('mail');
    final queued = (mail['documents'] as List).single as Map<String, dynamic>;
    expect(stringField(queued, 'to'), _inviteeEmail);
    await tapText(tester, l10n.actionDone);
    await pumpUntil(tester, find.text(_inviteeEmail));
    expect(find.text(l10n.familyPending(1)), findsOneWidget);

    // Sign out → 01 "Mã mời" → 15 → 16.
    await _openTab(tester, l10n.tabMe);
    await tapText(tester, l10n.meSignOut);
    await tapText(tester, l10n.welcomeInviteCode);
    await pumpUntil(tester, find.text(l10n.joinCodeTitle));
    await tester.enterText(find.byType(EditableText).first, code);
    await pumpUntil(
      tester,
      find.text(l10n.joinInviterTitle('${l10n.relationMother} Mai')),
      timeout: const Duration(seconds: 30),
    );
    expect(find.text(l10n.roleCaregiver), findsOneWidget);

    // 16b "Vào ngay" → 16a → Today as a temporary caregiver.
    await tapText(tester, l10n.joinJoin);
    await tapText(tester, l10n.joinNow);
    await pumpUntil(
      tester,
      find.text(l10n.joinConfirmTitle('Teddy')),
      timeout: const Duration(seconds: 30),
    );
    await tester.enterText(find.byType(EditableText).first, 'Hoa');
    await tester.pump();
    await tapText(tester, l10n.joinConfirmGo('Teddy'));
    await pumpUntil(
      tester,
      find.text(l10n.unsavedBannerTitle),
      timeout: const Duration(seconds: 45),
    );
    final temporary = FirebaseAuth.instance.currentUser!;
    expect(temporary.isAnonymous, isTrue);
    final membership = await firestoreGet(
      'babies/$babyId/members/${temporary.uid}',
    );
    expect(stringField(membership, 'role'), 'caregiver');
    expect(stringField(membership, 'relation'), 'grandmother');
    expect(stringField(membership, 'displayName'), 'Hoa');
    // Caregivers have no Kỷ niệm tab (124:13717).
    expect(find.bySemanticsLabel(l10n.tabMemories), findsNothing);

    // 16c "Lưu" → 16d "Dùng email" → same uid, banner gone (R-031).
    await tapText(tester, l10n.unsavedBannerAction);
    await tapText(tester, l10n.signInEmail);
    await pumpUntil(tester, find.text(l10n.saveEmailSubtitle));
    await tester.enterText(find.byType(EditableText).at(0), _inviteeEmail);
    await tester.enterText(find.byType(EditableText).at(1), _inviteePassword);
    await tester.pump();
    await tapText(tester, l10n.saveAccountTitle);
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (find.text(l10n.unsavedBannerTitle).evaluate().isNotEmpty &&
        DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text(l10n.unsavedBannerTitle), findsNothing);
    final saved = FirebaseAuth.instance.currentUser!;
    expect(saved.uid, temporary.uid);
    expect(saved.isAnonymous, isFalse);

    // The owner removes Hoa → 9d here (R-025).
    final ownerToken = await emulatorIdToken(_ownerEmail, _ownerPassword);
    await callFunction('removeFamilyMember', ownerToken, {
      'babyId': babyId,
      'uid': saved.uid,
    });
    await pumpUntil(
      tester,
      find.text(l10n.lostAccessTitle),
      timeout: const Duration(seconds: 30),
    );
    await tapText(tester, l10n.lostAccessHome);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(l10n.lostAccessTitle), findsNothing);
    expect(find.text(l10n.unsavedBannerTitle), findsNothing);
  });
}
