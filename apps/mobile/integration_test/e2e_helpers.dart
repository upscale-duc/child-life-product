// Shared helpers for the end-to-end tests against the local Firebase emulators.
import 'dart:convert';
import 'dart:io';

import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const project = 'child-life-dev';
final host = defaultTargetPlatform == TargetPlatform.android
    ? '10.0.2.2'
    : 'localhost';

Future<String> http(
  String method,
  String url, {
  Map<String, String> headers = const {},
  Object? json,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.parse(url));
    headers.forEach(request.headers.set);
    if (json != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(json));
    }
    final response = await request.close();
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

Map<String, dynamic> _decode(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

/// Auth emulator: creates an email account; returns its uid.
Future<String> emulatorSignUp(String email, String password) async =>
    _decode(
          await http(
            'POST',
            'http://$host:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator',
            json: {
              'email': email,
              'password': password,
              'returnSecureToken': true,
            },
          ),
        )['localId']
        as String;

/// Auth emulator admin: marks the email verified (invites need it, D-015).
Future<void> emulatorVerifyEmail(String uid) => http(
  'POST',
  'http://$host:9099/identitytoolkit.googleapis.com/v1/projects/$project/accounts:update',
  headers: {'Authorization': 'Bearer owner'},
  json: {'localId': uid, 'emailVerified': true},
);

/// Auth emulator: an ID token for [email].
Future<String> emulatorIdToken(String email, String password) async =>
    _decode(
          await http(
            'POST',
            'http://$host:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator',
            json: {
              'email': email,
              'password': password,
              'returnSecureToken': true,
            },
          ),
        )['idToken']
        as String;

/// Calls a callable Function on the emulator as the holder of [idToken].
Future<Map<String, dynamic>> callFunction(
  String name,
  String idToken,
  Map<String, Object?> data,
) async {
  final body = _decode(
    await http(
      'POST',
      'http://$host:5001/$project/asia-southeast1/$name',
      headers: {'Authorization': 'Bearer $idToken'},
      json: {'data': data},
    ),
  );
  if (body['error'] != null) {
    throw TestFailure('$name failed: ${body['error']}');
  }
  return (body['result'] as Map?)?.cast<String, dynamic>() ?? const {};
}

/// Firestore emulator read that bypasses Rules (admin "owner" token).
Future<Map<String, dynamic>> firestoreGet(String path) async => _decode(
  await http(
    'GET',
    'http://$host:8080/v1/projects/$project/databases/(default)/documents/$path',
    headers: {'Authorization': 'Bearer owner'},
  ),
);

/// `fields.<name>.stringValue` of a Firestore REST document.
String? stringField(Map<String, dynamic> doc, String name) =>
    ((doc['fields'] as Map?)?[name] as Map?)?['stringValue'] as String?;

Future<void> resetEmulators() async {
  await http(
    'DELETE',
    'http://$host:9099/emulator/v1/projects/$project/accounts',
  );
  await http(
    'DELETE',
    'http://$host:8080/emulator/v1/projects/$project/databases/(default)/documents',
  );
}

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Navigator).first));

/// Waits for [text], lets any route transition finish, then taps it.
Future<void> tapText(WidgetTester tester, String text) async {
  await pumpUntil(tester, find.text(text));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 400));
}
