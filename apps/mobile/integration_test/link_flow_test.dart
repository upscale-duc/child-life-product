// End-to-end S13 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test/link_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A saved Gia đình story gets a private link (14k, created through the callable — the OS share
// sheet cannot be driven from a test); the recipient page `/s/{token}` shows the story with the
// nickname and age only (14l, P-095); the parent revokes it in Tôi → "Đã chia sẻ ra ngoài" (14m)
// and the page is gone.
import 'dart:convert';
import 'dart:io';

import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'links.e2e@example.com';
const _password = 'e2e-only-password';
final _story = 'sto_${'5'.padLeft(32, '5')}';

Future<(int, String)> _page(String token) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse(
        'http://$host:5001/$project/asia-southeast1/shareView/s/$token',
      ),
    );
    request.headers.set('Accept-Language', 'vi');
    final response = await request.close();
    return (response.statusCode, await response.transform(utf8.decoder).join());
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S13: private link → recipient page → revoke from Tôi', (
    tester,
  ) async {
    await resetEmulators();
    final uid = await emulatorSignUp(_email, _password);
    await emulatorVerifyEmail(uid);
    final idToken = await emulatorIdToken(_email, _password);
    final created = await callFunction('createBabyProfile', idToken, {
      'requestId': '6a1d2c3b-4a5f-4b6c-8d7e-0f1a2b3c4d51',
      'nickname': 'Teddy',
      'dateOfBirth': '2026-09-17',
      'gender': 'boy',
      'timeZone': {'mode': 'auto', 'zone': 'Asia/Ho_Chi_Minh'},
      'avatarPreset': 1,
      'trackers': ['bottle', 'breast', 'sleep', 'diaper'],
      'self': {'displayName': 'Nguyễn Mai', 'relation': 'mother'},
    });
    final babyId = created['babyId'] as String;
    await firestoreSet('babies/$babyId/stories/$_story', {
      'id': _story,
      'babyId': babyId,
      'kind': 'story',
      'origin': 'manual',
      'suggestion': false,
      'status': 'saved',
      'audience': 'family',
      'title': 'Tuần Teddy biết cười',
      'coverMediaId': null,
      'blocks': [
        {
          'id': 'b0',
          'type': 'paragraph',
          'text': 'Sáng thứ Hai, Teddy cười.',
          'ai': false,
        },
      ],
      'createdBy': uid,
      'author': {
        'name': 'Nguyễn Mai',
        'relation': 'mother',
        'relationCustom': null,
      },
      'loveCount': 0,
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      'savedAt': DateTime.now().toUtc(),
    });
    final link = await callFunction('createStoryLink', idToken, {
      'requestId': '6a1d2c3b-4a5f-4b6c-8d7e-0f1a2b3c4d52',
      'babyId': babyId,
      'storyId': _story,
      'expiry': '7d',
      'hideIdentity': true,
      'allowDownload': false,
      'passcode': false,
    });
    final token = link['token'] as String;
    expect(link['url'] as String, endsWith('/s/$token-teddy'));

    // 14l: the recipient sees the story, the nickname and age, never the birth date.
    final (status, html) = await _page('$token-teddy');
    expect(status, 200);
    expect(html, contains('Tuần Teddy biết cười'));
    expect(html, contains('Teddy · '));
    expect(html, contains('Mai chia sẻ'));
    expect(html, isNot(contains('2026-09-17')));
    expect(html, isNot(contains('sinh ngày')));

    // App: Tôi → "Đã chia sẻ ra ngoài" → "Thu hồi" → confirm.
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
    final me = find.bySemanticsLabel(l10n.tabMe);
    await pumpUntil(tester, me);
    await tester.tap(me.first);
    await tester.pump(const Duration(milliseconds: 600));
    await pumpUntil(tester, find.text(l10n.soTitle));
    await tester.scrollUntilVisible(
      find.text(l10n.soTitle).last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.soTitle).last);
    await tester.pump(const Duration(milliseconds: 600));
    await pumpUntil(tester, find.textContaining('Tuần Teddy biết cười'));
    await tapText(tester, l10n.soRevoke);
    await pumpUntil(tester, find.text(l10n.soRevokeTitle));
    await tapText(tester, l10n.soRevoke);

    final end = DateTime.now().add(const Duration(seconds: 30));
    var revoked = false;
    while (DateTime.now().isBefore(end) && !revoked) {
      final doc = await firestoreGet('shareLinks/$token');
      revoked = stringField(doc, 'status') == 'revoked';
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(revoked, isTrue);
    final (after, _) = await _page('$token-teddy');
    expect(after, 404);
  });
}
