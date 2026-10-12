import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../appearance/appearance_providers.dart';

/// Dữ liệu tham chiếu (P-138, Figma C01–C04): tables approved on the portal by a second person
/// and published to `publicConfig/reference_*` (Rules: anyone may `get`). The app reads a table
/// once per launch through Firestore (which serves its offline cache when there is no network),
/// validates it with the dataset's own parser, and keeps the last valid copy in preferences so a
/// cold start offline uses it at once. Anything missing or invalid means the bundled copy.
class ReferenceRepository {
  ReferenceRepository(this._db, this._prefs);

  /// Lazy: reading the cache never needs Firebase (widget tests, first frame).
  final FirebaseFirestore Function() _db;
  final SharedPreferences _prefs;

  static String _cacheKey(String docId) => 'reference.$docId';

  /// The published document, or null when there is none.
  Future<Map<String, dynamic>?> read(String docId) async =>
      (await _db().doc('publicConfig/$docId').get()).data();

  /// The last valid copy of [docId] kept on this device, or null.
  T? cached<T>(String docId, T? Function(Object? data) parse) {
    final raw = _prefs.getString(_cacheKey(docId));
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  /// Reads the published [docId] and returns it parsed, remembering it; null (and the cache
  /// cleared) when nothing valid is published. Throws when it cannot be read at all (offline
  /// with an empty Firestore cache): the caller keeps what it has.
  Future<T?> refresh<T>(
    String docId,
    T? Function(Object? data) parse,
    Object? Function(T value) toJson,
  ) async {
    final value = parse(await read(docId));
    if (value == null) {
      await _prefs.remove(_cacheKey(docId));
    } else {
      await _prefs.setString(_cacheKey(docId), jsonEncode(toJson(value)));
    }
    return value;
  }
}

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(
    () => ref.read(firestoreProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);
