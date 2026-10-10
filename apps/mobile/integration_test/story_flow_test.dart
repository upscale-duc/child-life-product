// End-to-end S12 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/story_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A week with captions and photos gets "Gợi ý tuần này" (P-090, template provider without an
// OpenAI key); the parent opens the draft, saves it for the family with one notice (14f), reads it
// (14g) and deletes it (G-050) — the photos stay in Kỷ niệm.
import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'stories.e2e@example.com';
const _password = 'e2e-only-password';

Map<String, Object?> _flag(bool on) => {
  'enabled': on,
  'scope': 'all',
  'percent': 0,
  'notice': null,
};

Future<(String, String)> _seed() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '5a1d2c3b-4a5f-4b6c-8d7e-0f1a2b3c4d50',
    'nickname': 'Teddy',
    'dateOfBirth': '2026-09-17',
    'gender': 'boy',
    'timeZone': {'mode': 'auto', 'zone': 'Asia/Ho_Chi_Minh'},
    'avatarPreset': 1,
    'trackers': ['bottle', 'breast', 'sleep', 'diaper'],
    'self': {'displayName': 'Mai', 'relation': 'mother'},
  });
  final babyId = result['babyId'] as String;
  final baby = await firestoreGet('babies/$babyId');
  final familyId = stringField(baby, 'familyId')!;
  await firestoreSet('config/flags', {
    for (final k in [
      'media_upload',
      'video_upload',
      'story_share_link',
      'invites',
      'lock_widgets',
      'night_auto',
    ])
      k: _flag(false),
    'ai_story_drafts': _flag(true),
  });
  final now = DateTime.now().toUtc();
  for (var i = 0; i < 6; i++) {
    final id = 'med_${(i + 1).toString().padLeft(32, '0')}';
    await firestoreSet('babies/$babyId/media/$id', {
      'id': id,
      'babyId': babyId,
      'familyId': familyId,
      'memoryId': 'mem_${'1'.padLeft(32, '0')}',
      'type': 'photo',
      'audience': 'family',
      'effectiveAudience': 'family',
      'albumIds': <Object?>[],
      'status': 'ready',
      'deleted': false,
      'captureAt': now.subtract(Duration(hours: i + 1)),
      'createdBy': uid,
    });
  }
  await firestoreSet('babies/$babyId/memories/mem_${'1'.padLeft(32, '0')}', {
    'occurredAt': now.subtract(const Duration(hours: 1)),
    'caption': 'Sáng nay Teddy cười khi mẹ hát ru.',
    'audience': 'family',
    'state': 'published',
    'deleted': false,
    'mediaIds': <Object?>[],
    'createdBy': uid,
    'author': {'name': 'Mai', 'relation': 'mother', 'relationCustom': null},
  });
  final s = await callFunction('requestStorySuggestion', token, {
    'babyId': babyId,
    'locale': 'vi',
  });
  return (babyId, s['storyId'] as String);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S12: weekly suggestion → save for the family → read → delete', (
    tester,
  ) async {
    await resetEmulators();
    final (babyId, storyId) = await _seed();
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

    // Kỷ niệm → Câu chuyện → "Xem bản nháp".
    final tab = find.bySemanticsLabel(l10n.tabMemories);
    await pumpUntil(tester, tab);
    await tester.tap(tab.first);
    await tester.pump(const Duration(milliseconds: 600));
    await tapText(tester, l10n.memStories);
    await tapText(tester, l10n.srySuggestCta);

    // 14b → 14f "Lưu câu chuyện" (Gia đình, Báo cho gia đình on).
    await tapText(tester, l10n.sryPreviewSave);
    await tapText(tester, l10n.srySaveTitle);
    final end = DateTime.now().add(const Duration(seconds: 40));
    var saved = false;
    while (DateTime.now().isBefore(end) && !saved) {
      final s = await firestoreGet('babies/$babyId/stories/$storyId');
      saved = stringField(s, 'status') == 'saved';
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(saved, isTrue);
    final notices = await firestoreGet('babies/$babyId/notifications');
    final kinds = [
      for (final d in (notices['documents'] as List? ?? const []))
        stringField((d as Map).cast<String, dynamic>(), 'kind'),
    ];
    expect(kinds, contains('story'));

    // 14g reader → ••• → "Xoá câu chuyện".
    await pumpUntil(tester, find.bySemanticsLabel(l10n.sryMore));
    await tester.tap(find.bySemanticsLabel(l10n.sryMore).first);
    await tester.pump(const Duration(milliseconds: 600));
    await tapText(tester, l10n.sryDelete);
    final end2 = DateTime.now().add(const Duration(seconds: 30));
    var gone = false;
    while (DateTime.now().isBefore(end2) && !gone) {
      final s = await firestoreGet('babies/$babyId/stories/$storyId');
      gone = s['fields'] == null;
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(gone, isTrue);
    final media = await firestoreGet('babies/$babyId/media');
    expect((media['documents'] as List).length, 6);
  });
}
