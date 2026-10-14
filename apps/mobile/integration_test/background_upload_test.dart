// 10j on Android (android-plan.md A3): the WorkManager uploader behind `childlife/uploads`,
// driven through the same BackgroundTransport the app uses, against local Auth and Storage
// emulators on their own ports (so a shared emulator suite is left alone):
//
//   firebase emulators:start --only auth,storage --project demo-a3   # auth 9188, storage 9491,
//                                                                     # rules: signed-in writes
//   flutter test integration_test/background_upload_test.dart --flavor dev -d <android>
//
// A 3 MB file goes up with progress and arrives whole; asking again does not send it twice; a
// recording gets its index moved first (FastStart.kt).
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:child_life/features/memories/background_uploads.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _auth = String.fromEnvironment('A3_AUTH', defaultValue: '10.0.2.2:9188');
const _storage = String.fromEnvironment(
  'A3_STORAGE',
  defaultValue: '10.0.2.2:9491',
);
const _bucket = 'demo-a3.appspot.com';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'a3.device@example.com';
const _password = 'a3-device-only-password';

Future<Map<String, dynamic>> _post(
  String url,
  Map<String, Object?> body,
) async {
  final client = HttpClient();
  try {
    final r = await client.postUrl(Uri.parse(url));
    r.headers.contentType = ContentType.json;
    r.write(jsonEncode(body));
    final res = await r.close();
    return jsonDecode(await res.transform(utf8.decoder).join())
        as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<String> _token() async {
  final base = 'http://$_auth/identitytoolkit.googleapis.com/v1/accounts';
  final body = {
    'email': _email,
    'password': _password,
    'returnSecureToken': true,
  };
  var r = await _post('$base:signInWithPassword?key=emulator', body);
  if (r['idToken'] == null) r = await _post('$base:signUp?key=emulator', body);
  return r['idToken'] as String;
}

Future<Map<String, dynamic>> _object(String path, String token) async {
  final client = HttpClient();
  try {
    final r = await client.getUrl(
      Uri.parse(
        'http://$_storage/v0/b/$_bucket/o/${Uri.encodeComponent(path)}',
      ),
    );
    r.headers.set('Authorization', 'Firebase $token');
    final res = await r.close();
    return jsonDecode(await res.transform(utf8.decoder).join())
        as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Uint8List _box(String type, List<int> body) {
  final b = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, 8 + body.length)).buffer.asUint8List())
    ..add(ascii.encode(type))
    ..add(body);
  return b.toBytes();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final android = defaultTargetPlatform == TargetPlatform.android;

  testWidgets('a file goes up through WorkManager, once', (tester) async {
    final token = await _token();
    final dir = await getTemporaryDirectory();
    final bytes = Uint8List.fromList(
      List.generate(3 * 1024 * 1024, (i) => Random(i).nextInt(256)),
    );
    final file = File('${dir.path}/a3.bin')..writeAsBytesSync(bytes);
    final path = 'tests/a3-${DateTime.now().millisecondsSinceEpoch}.bin';
    final transport = BackgroundTransport(
      token: (_) async => token,
      bucket: _bucket,
      host: _storage,
    );
    final job = UploadJob(
      path: path,
      file: file,
      contentType: 'application/octet-stream',
      babyId: 'b_test',
    );

    final seen = <int>[];
    await transport.upload(job, seen.add).timeout(const Duration(minutes: 2));
    final object = await _object(path, token);
    expect(object['size'], '${bytes.length}');
    expect(seen, isNotEmpty);

    // Asked again (a restart that does not know it finished): nothing is sent twice.
    seen.clear();
    await transport.upload(job, seen.add).timeout(const Duration(seconds: 10));
    expect(seen.where((s) => s > 0 && s < bytes.length), isEmpty);
  }, skip: !android);

  // Built as the app (-t this file, --dart-define=A3_HANDOFF=true): hands a 300 MB file over and
  // returns while it is still going, so the process can be killed from adb and the job seen to
  // finish anyway.
  testWidgets(
    'hand off and leave',
    (tester) async {
      final token = await _token();
      final dir = await getTemporaryDirectory();
      // 300 MB of zeros, written sparse, so the kill lands mid-transfer.
      final file = File('${dir.path}/a3-handoff.bin');
      file.openSync(mode: FileMode.write)
        ..setPositionSync(300 * 1024 * 1024 - 1)
        ..writeByteSync(0)
        ..closeSync();
      final transport = BackgroundTransport(
        token: (_) async => token,
        bucket: _bucket,
        host: _storage,
      );
      await transport.handOff([
        UploadJob(
          path: 'tests/handoff.bin',
          file: file,
          contentType: 'application/octet-stream',
          babyId: 'b_test',
        ),
      ]);
      await tester.pump(const Duration(seconds: 8));
    },
    skip: !android || !const bool.fromEnvironment('A3_HANDOFF'),
  );

  testWidgets('a recording gets its index first', (tester) async {
    final dir = await getTemporaryDirectory();
    final ftyp = _box('ftyp', ascii.encode('isom\x00\x00\x02\x00isomiso2mp41'));
    final mdat = _box('mdat', List.filled(1000, 7));
    final stco = _box('stco', [
      ...[0, 0, 0, 0, 0, 0, 0, 1],
      ...(ByteData(4)..setUint32(0, ftyp.length + 8)).buffer.asUint8List(),
    ]);
    final moov = _box(
      'moov',
      _box('trak', _box('mdia', _box('minf', _box('stbl', stco)))),
    );
    final src = File('${dir.path}/rec.mp4')
      ..writeAsBytesSync([...ftyp, ...mdat, ...moov]);
    final dst = File('${dir.path}/rec-fast.mp4');
    expect(await faststartVideo(src.path, dst.path), isTrue);
    final out = dst.readAsBytesSync();
    expect(ascii.decode(out.sublist(ftyp.length + 4, ftyp.length + 8)), 'moov');
    expect(out.length, src.lengthSync());
  }, skip: !android);
}
