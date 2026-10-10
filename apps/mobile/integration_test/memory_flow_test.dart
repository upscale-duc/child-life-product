// End-to-end S9 flow on a simulator / emulator against the local Firebase emulators (Functions
// process uploads with sharp, Storage Rules read Firestore):
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   xcrun simctl privacy <udid> grant photos app.childlife.dev                       # iOS
//   adb shell pm grant app.childlife.dev android.permission.READ_MEDIA_IMAGES        # Android
//   flutter test integration_test/memory_flow_test.dart --flavor dev \
//     --dart-define=CL_EMULATORS=true -d <device>
//
// A parent opens Kỷ niệm, writes a note (10a2 → 10h), then adds a photo from the library (10g →
// 10h "Tải lên 1 mục"): the upload session reserves quota, the bytes go to the reserved slot, the
// server re-encodes them and the entry appears with its thumbnail read through Storage Rules.
// On Ảnh the photo becomes Chỉ ba mẹ ("Ai thấy"), goes into a new Gia đình album (seen by the
// family again, D-002), becomes a favourite and is then deleted (10b4, R-111).
import 'package:child_life/features/memories/media_picker.dart';
import 'package:child_life/features/memories/memory_widgets.dart';
import 'package:child_life/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'memories.e2e@example.com';
const _password = 'e2e-only-password';

Future<String> _seedBaby() async {
  final uid = await emulatorSignUp(_email, _password);
  await emulatorVerifyEmail(uid);
  final token = await emulatorIdToken(_email, _password);
  final result = await callFunction('createBabyProfile', token, {
    'requestId': '9e1d2c3b-4a5f-4b6c-8d7e-0f1a2b3c4d5e',
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

Future<List<Map<String, dynamic>>> _docs(String path) async {
  final list = await firestoreGet(path);
  return [
    for (final d in (list['documents'] as List? ?? const []))
      (d as Map).cast<String, dynamic>(),
  ];
}

Object? _v(Map<String, dynamic> doc, String key) {
  final node = (doc['fields'] as Map?)?[key];
  if (node is Map) {
    return node['stringValue'] ??
        node['booleanValue'] ??
        node['integerValue'] ??
        (node.containsKey('nullValue') ? null : node);
  }
  return null;
}

Future<List<Map<String, dynamic>>> _until(
  WidgetTester tester,
  String path,
  bool Function(List<Map<String, dynamic>> docs) ok, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  var docs = <Map<String, dynamic>>[];
  while (DateTime.now().isBefore(end)) {
    docs = await _docs(path);
    if (ok(docs)) return docs;
    await tester.pump(const Duration(milliseconds: 500));
  }
  throw TestFailure('Timed out waiting for $path: $docs');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S9: note, photo upload and processing, audience, delete', (
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

    // Kỷ niệm tab.
    final tab = find.bySemanticsLabel(l10n.tabMemories);
    await pumpUntil(tester, tab);
    await tester.tap(tab.first);
    await pumpUntil(tester, find.text(l10n.memEmptyTitle));

    // 10a2 → "Viết ghi chú" → saved and shown at once.
    await tester.tap(find.bySemanticsLabel(l10n.a11yAddMemory).first);
    await tapText(tester, l10n.addNote);
    await pumpUntil(tester, find.text(l10n.composeSaveNote));
    await tester.enterText(
      find.byType(EditableText).first,
      'Đêm qua con ngủ ngon.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 600));
    await tapText(tester, l10n.composeSaveNote);
    await pumpUntil(
      tester,
      find.text('Đêm qua con ngủ ngon.'),
      timeout: const Duration(seconds: 30),
    );

    // 10a2 → 10g: the first photo of the library → 10h "Tải lên 1 mục".
    await tester.tap(find.bySemanticsLabel(l10n.a11yAddMemory).first);
    await tapText(tester, l10n.addLibrary);
    final picker = find.byType(LibraryPicker);
    await pumpUntil(tester, picker);
    final thumbs = find.descendant(of: picker, matching: find.byType(Image));
    await pumpUntil(tester, thumbs, timeout: const Duration(seconds: 30));
    await tester.tap(thumbs.first);
    await tester.pump(const Duration(milliseconds: 400));
    await tapText(tester, l10n.pickAdd(1));
    await pumpUntil(tester, find.text(l10n.composeUpload(1)));
    await tapText(tester, l10n.composeUpload(1));

    // Server: reserved, uploaded, re-encoded, ready; the memory is published.
    final media = await _until(
      tester,
      'babies/$babyId/media',
      (d) => d.length == 1 && _v(d.single, 'status') == 'ready',
      timeout: const Duration(seconds: 90),
    );
    final mediaId = (media.single['name'] as String).split('/').last;
    final memories = await _until(
      tester,
      'babies/$babyId/memories',
      (d) => d.length == 2 && d.every((m) => _v(m, 'state') == 'published'),
    );
    expect(memories, hasLength(2));
    final family = await firestoreGet(
      'families/${_v((await firestoreGet('babies/$babyId')), 'familyId')}',
    );
    expect(int.parse(_v(family, 'usedBytes')! as String), greaterThan(0));
    expect(_v(family, 'reservedBytes'), '0');

    // The entry shows its thumbnail, read through Storage Rules.
    await pumpUntil(
      tester,
      find.byType(MediaTile),
      timeout: const Duration(seconds: 30),
    );

    // Ảnh → Chọn → the tile → "Ai thấy" → Chỉ ba mẹ.
    await tester.tap(find.text(l10n.memPhotos).last);
    await pumpUntil(tester, find.text(l10n.memSelect));
    await tapText(tester, l10n.memSelect);
    await tester.tap(find.byType(MediaTile).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel(l10n.a11yShareOptions).first);
    await pumpUntil(tester, find.text(l10n.actWho));
    await tapText(tester, l10n.actWho);
    await pumpUntil(tester, find.text(l10n.audParents));
    await tapText(tester, l10n.audParents);
    await tapText(tester, l10n.viewApply);
    await _until(
      tester,
      'babies/$babyId/media',
      (d) => _v(d.single, 'effectiveAudience') == 'parents',
    );

    // Album → "Album mới" → "Giờ tắm", Gia đình (10d, 10e10).
    await tester.tap(find.text(l10n.memAlbums).last);
    await pumpUntil(tester, find.text(l10n.albNew));
    await tapText(tester, l10n.albNew);
    await pumpUntil(tester, find.text(l10n.albSuggestBath));
    await tester.tap(find.text(l10n.albSuggestBath).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, l10n.albCreate);
    await _until(tester, 'babies/$babyId/albums', (d) => d.length == 1);

    // Ảnh → Chọn → the tile → Album → "Giờ tắm" → Xong: in a Gia đình album the photo is
    // seen by the family again (D-002, P-035).
    await tester.tap(find.text(l10n.memPhotos).last);
    await pumpUntil(tester, find.text(l10n.memSelect));
    await tapText(tester, l10n.memSelect);
    await tester.tap(find.byType(MediaTile).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel(l10n.a11yShareOptions).first);
    await pumpUntil(tester, find.text(l10n.actFavorite));
    await tester.tap(find.text(l10n.actAlbum).last);
    await pumpUntil(tester, find.text(l10n.albPickTitle));
    await pumpUntil(tester, find.text(l10n.albSuggestBath));
    await tester.tap(find.text(l10n.albSuggestBath).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, l10n.actionDone);
    await _until(
      tester,
      'babies/$babyId/media',
      (d) => _v(d.single, 'effectiveAudience') == 'family',
    );
    await _until(
      tester,
      'babies/$babyId/albums',
      (d) => _v(d.single, 'photos') == '1',
    );

    // Chọn → the tile → "Thêm vào Yêu thích" (private to me, R-107).
    await pumpUntil(tester, find.text(l10n.memSelect));
    await tapText(tester, l10n.memSelect);
    await tester.tap(find.byType(MediaTile).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel(l10n.a11yShareOptions).first);
    await pumpUntil(tester, find.text(l10n.actFavorite));
    await tapText(tester, l10n.actFavorite);
    await _until(tester, 'babies/$babyId/favorites', (d) => d.length == 1);

    // Chọn → the tile → delete → "Xoá 1 mục" → "Đã xoá gần đây".
    await tapText(tester, l10n.memSelect);
    await tester.tap(find.byType(MediaTile).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel(l10n.a11yDeleteSelected).first);
    await pumpUntil(tester, find.text(l10n.delN(1)));
    await tapText(tester, l10n.delN(1));
    final deleted = await _until(
      tester,
      'babies/$babyId/media',
      (d) => _v(d.single, 'deleted') == true,
    );
    expect((deleted.single['name'] as String).endsWith(mediaId), isTrue);
    await pumpUntil(tester, find.text(l10n.memEmptyTitle));
  });
}
