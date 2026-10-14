import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../care/care_repository.dart' show babyToday;
import '../premium/premium_models.dart' show GateReason;
import 'rhythm_calc.dart';
import 'rhythm_models.dart';

/// A refused or failed rhythm call. [reason] is a gate code (`PREMIUM_REQUIRED`…), a request
/// problem (`checkin-not-found`) or a transport code (`unavailable`).
class RhythmException implements Exception {
  const RhythmException(this.reason);
  final String reason;

  GateReason? get gate => GateReason.fromWire(reason);

  /// No connection (or the server could not be reached): "Sẽ đồng bộ khi có mạng".
  bool get offline => const {
    'unavailable',
    'deadline-exceeded',
    'timeout',
    'offline',
  }.contains(reason);

  @override
  String toString() => 'RhythmException($reason)';
}

/// How far back Home reads check-ins and feedback (the reason line, PS02, the health card).
const checkInWindowDays = 14;
const feedbackWindowDays = 60;

/// `ci_` + 32 hex: one per author per observation per baby-local day (the schema's rule), so
/// saving the same observation again edits it instead of piling up copies.
String checkInIdFor({
  required String babyId,
  required String uid,
  required String date,
  required Observation observation,
}) =>
    'ci_${sha256.convert(utf8.encode('$babyId|$uid|$date|${observation.wire}')).toString().substring(0, 32)}';

/// `fb_` + 32 hex, random: every answer is its own row (the newest wins per kind).
String newFeedbackId() => 'fb_${const Uuid().v4().replaceAll('-', '')}';

/// Baby-local today as YYYY-MM-DD.
String babyTodayIso(String zone, DateTime now) => isoOf(babyToday(zone, now));

/// Nhịp lớn lên data (plan §7.1). Check-ins and feedback go straight to Firestore like care
/// records: nothing waits for the server, the local cache updates at once and the queue
/// survives offline and restarts; the client id is the idempotency key. Published content and
/// the reference model are public config read as streams (the offline cache keeps the last
/// version). `nextAction`, `composeHome` and `setDueDate` are callables; the last Home answer
/// is kept on the phone so Home draws offline. Never logs child data.
class RhythmRepository {
  RhythmRepository(this._db, this._functions, this._prefs);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final SharedPreferences _prefs;

  /// Writes still on their way, by document id ([committed]).
  final _writes = <String, Future<void>>{};

  // ---------- Published (public config) ----------

  Stream<RhythmContent?> watchContent() => _db
      .doc('publicConfig/content_rhythm')
      .snapshots()
      .map((s) => RhythmContent.fromJson(s.data()));

  Stream<ReferenceModel?> watchReference() => _db
      .doc('publicConfig/rhythm_reference')
      .snapshots()
      .map((s) => ReferenceModel.fromJson(s.data()));

  /// Date of birth and due date. Only for members who may read the restricted profile.
  Stream<RhythmProfile> watchProfile(String babyId) => _db
      .doc('babies/$babyId/restricted/profile')
      .snapshots()
      .map((s) => RhythmProfile.fromJson(s.data()));

  // ---------- Check-ins (C01, C02, NL05b) ----------

  /// Check-ins about [since] or later, newest day first.
  Stream<List<CheckIn>> watchCheckIns(String babyId, String since) => _db
      .collection('babies/$babyId/checkins')
      .where('date', isGreaterThanOrEqualTo: since)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => [
          for (final d in s.docs)
            ?CheckIn.fromJson(d.data(), pending: d.metadata.hasPendingWrites),
        ]..sort((a, b) => b.date.compareTo(a.date)),
      );

  /// Saves [checkIn] without waiting for the server ([previous]: the same id already stored,
  /// so this is an edit and the revision moves on). Failures surface through [onError].
  CheckIn saveCheckIn(
    CheckIn checkIn, {
    CheckIn? previous,
    void Function(Object error)? onError,
  }) {
    final saved = previous == null
        ? checkIn
        : checkIn.copyWith(revision: previous.revision + 1);
    final data = <String, Object?>{
      ...saved.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (previous == null) 'createdAt': FieldValue.serverTimestamp(),
    };
    final doc = _db.doc('babies/${saved.babyId}/checkins/${saved.id}');
    _track(
      saved.id,
      previous == null ? doc.set(data) : doc.set(data, SetOptions(merge: true)),
      onError,
    );
    return saved;
  }

  // ---------- Feedback (AC01, AC02, H02, PS01) ----------

  Stream<List<RecFeedback>> watchFeedback(String babyId, String since) => _db
      .collection('babies/$babyId/recFeedback')
      .where('date', isGreaterThanOrEqualTo: since)
      .snapshots(includeMetadataChanges: true)
      .map((s) {
        final rows = [
          for (final d in s.docs)
            ?RecFeedback.fromJson(
              d.data(),
              createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              pending: d.metadata.hasPendingWrites,
            ),
        ];
        return newestFirst(rows);
      });

  RecFeedback saveFeedback(
    RecFeedback feedback, {
    void Function(Object error)? onError,
  }) {
    _track(
      feedback.id,
      _db.doc('babies/${feedback.babyId}/recFeedback/${feedback.id}').set({
        ...feedback.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      onError,
    );
    return feedback;
  }

  /// The household's stored suggestions (`history.read`), newest first.
  Stream<List<Recommendation>> watchRecommendations(String babyId) => _db
      .collection('babies/$babyId/recommendations')
      .orderBy('generatedAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?Recommendation.fromJson(d.data())]);

  // ---------- Preferences (EN01, EN02; owner only) ----------

  Stream<UserPreferences> watchPreferences(String uid) => _db
      .doc('users/$uid/settings/personalization')
      .snapshots()
      .map((s) => UserPreferences.fromJson(s.data()));

  void savePreferences(
    String uid,
    UserPreferences preferences, {
    void Function(Object error)? onError,
  }) {
    _track(
      'prefs_$uid',
      _db.doc('users/$uid/settings/personalization').set({
        ...preferences.toJson(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      onError,
    );
  }

  /// Completes when the write of [id] reached the server; null when none is in flight.
  Future<void>? committed(String id) => _writes[id];

  void _track(String id, Future<void> write, void Function(Object)? onError) {
    final done = write.catchError((Object e) {
      onError?.call(e);
      throw e;
    });
    _writes[id] = done;
    // The map only keeps writes in flight (the latest per id); errors were reported above.
    void forget(Object? _) {
      if (identical(_writes[id], done)) _writes.remove(id);
    }

    unawaited(done.then(forget, onError: forget));
  }

  // ---------- Callables ----------

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return r.data is Map
          ? Map<String, dynamic>.from(r.data! as Map)
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw RhythmException(
        details is Map && details['reason'] is String
            ? details['reason'] as String
            : (e.message != null && GateReason.fromWire(e.message) != null)
            ? e.message!
            : e.code,
      );
    }
  }

  /// PS01 / PS01F / HL01 after a check-in (`nextAction`).
  Future<NextActionAnswer> nextAction({
    required String babyId,
    required String checkInId,
    required String locale,
  }) async => NextActionAnswer.fromJson(
    await _call('nextAction', {
      'babyId': babyId,
      'checkInId': checkInId,
      'locale': locale == 'en' ? 'en' : 'vi',
    }),
  );

  static String _homeKey(String babyId, String locale) =>
      'rhythm.home.$babyId.$locale';

  HomeComposition? cachedHome(String babyId, String locale) {
    final raw = _prefs.getString(_homeKey(babyId, locale));
    if (raw == null) return null;
    try {
      return HomeComposition.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// H02 / PS02 (`composeHome`). Offline or failing: the last answer this phone got. A member
  /// who may not read it any more forgets it.
  Future<HomeComposition?> composeHome(String babyId, String locale) async {
    final lang = locale == 'en' ? 'en' : 'vi';
    try {
      final home = HomeComposition.fromJson(
        await _call('composeHome', {'babyId': babyId, 'locale': lang}),
      );
      unawaited(
        _prefs.setString(_homeKey(babyId, lang), jsonEncode(home.toJson())),
      );
      return home;
    } on RhythmException catch (e) {
      if (e.gate == GateReason.roleDenied || e.gate == GateReason.notMember) {
        unawaited(_prefs.remove(_homeKey(babyId, lang)));
        return null;
      }
      return cachedHome(babyId, lang);
    } on Object {
      return cachedHome(babyId, lang);
    }
  }

  /// NL02b (Cùng nuôi): null clears it, the calendar goes back to "chưa thiết lập".
  Future<void> setDueDate(String babyId, DueDate? dueDate) =>
      _call('setDueDate', {'babyId': babyId, 'dueDate': dueDate?.toJson()});
}

/// Newest first: by date, then by server time (pending rows count as newest).
List<RecFeedback> newestFirst(Iterable<RecFeedback> rows) =>
    [...rows]..sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      final at = a.createdAt ?? DateTime(9999);
      final bt = b.createdAt ?? DateTime(9999);
      return bt.compareTo(at);
    });

// ---------- Providers ----------

final rhythmRepositoryProvider = Provider<RhythmRepository>(
  (ref) => RhythmRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// `publicConfig/content_rhythm`, null until published (or unreadable).
final rhythmContentProvider = StreamProvider<RhythmContent?>(
  (ref) => ref.watch(rhythmRepositoryProvider).watchContent(),
);

/// `publicConfig/rhythm_reference`.
final rhythmReferenceProvider = StreamProvider<ReferenceModel?>(
  (ref) => ref.watch(rhythmRepositoryProvider).watchReference(),
);

/// DOB and due date of a baby: watch only when the member can read the restricted profile.
final rhythmProfileProvider = StreamProvider.family<RhythmProfile, String>(
  (ref, babyId) => ref.watch(rhythmRepositoryProvider).watchProfile(babyId),
);

/// Recent check-ins of a baby (all authors), newest day first.
final checkInsProvider = StreamProvider.family<List<CheckIn>, String>((
  ref,
  babyId,
) {
  final since = isoOf(
    DateTime.now().subtract(const Duration(days: checkInWindowDays + 1)),
  );
  return ref.watch(rhythmRepositoryProvider).watchCheckIns(babyId, since);
});

/// Recent feedback of a baby (all authors), newest first.
final recFeedbackProvider = StreamProvider.family<List<RecFeedback>, String>((
  ref,
  babyId,
) {
  final since = isoOf(
    DateTime.now().subtract(const Duration(days: feedbackWindowDays + 1)),
  );
  return ref.watch(rhythmRepositoryProvider).watchFeedback(babyId, since);
});

final recommendationsProvider =
    StreamProvider.family<List<Recommendation>, String>(
      (ref, babyId) =>
          ref.watch(rhythmRepositoryProvider).watchRecommendations(babyId),
    );

final userPreferencesProvider = StreamProvider.family<UserPreferences, String>(
  (ref, uid) => ref.watch(rhythmRepositoryProvider).watchPreferences(uid),
);

/// `composeHome` for (babyId, language); refreshed after a check-in or feedback.
final homeCompositionProvider = FutureProvider.autoDispose
    .family<HomeComposition?, (String, String)>(
      (ref, key) =>
          ref.watch(rhythmRepositoryProvider).composeHome(key.$1, key.$2),
      retry: (_, _) => null,
    );

typedef NextActionKey = ({
  String babyId,
  String checkInId,
  int revision,
  String locale,
});

/// `nextAction` once the check-in reached the server (it may still be queued on the phone).
/// Offline or failing → [RhythmException]; the screen then shows "Ghi nhận vẫn lưu trên máy".
final nextActionProvider = FutureProvider.autoDispose
    .family<NextActionAnswer, NextActionKey>((ref, k) async {
      final repo = ref.watch(rhythmRepositoryProvider);
      final write = repo.committed(k.checkInId);
      if (write != null) {
        try {
          await write.timeout(const Duration(seconds: 10));
        } on TimeoutException {
          throw const RhythmException('offline');
        }
      }
      Future<NextActionAnswer> ask() => repo.nextAction(
        babyId: k.babyId,
        checkInId: k.checkInId,
        locale: k.locale,
      );
      try {
        return await ask();
      } on RhythmException catch (e) {
        // The write landed a moment after the call: ask once more.
        if (e.reason != 'checkin-not-found') rethrow;
        await Future<void>.delayed(const Duration(seconds: 2));
        return ask();
      }
    }, retry: (_, _) => null);

/// Opens the phone app dialling [number] (empty: just the dialler); false when it could not.
/// Tests replace it.
final rhythmDialerProvider = Provider<Future<bool> Function(String number)>(
  (ref) => (number) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } on Object {
      return false;
    }
  },
);
