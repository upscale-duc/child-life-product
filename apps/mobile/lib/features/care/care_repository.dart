import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../baby/time_zones.dart';
import 'care_models.dart';
import 'timer_models.dart';

/// How far back Today looks for "lần cuối" per tile (older entries show "Chưa có").
const recentWindow = Duration(days: 14);

/// Care records (S4). Writes go straight to Firestore, which queues them on the device while
/// offline and across restarts (SyncStatus 8:84: "Pending saves must survive an app restart");
/// nothing is awaited from the server, so the UI updates at once from the local cache.
class CareRepository {
  CareRepository(this._db, [this._functions]);

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;

  CollectionReference<Map<String, dynamic>> _records(String babyId) =>
      _db.collection('babies/$babyId/records');

  /// Live (not deleted) records of the last two weeks, newest first, with pending flags.
  Stream<List<CareRecord>> watchRecent(String babyId, DateTime now) =>
      _records(babyId)
          .where('deleted', isEqualTo: false)
          .where(
            'occurredAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              now.subtract(recentWindow),
            ),
          )
          .orderBy('occurredAt', descending: true)
          .limit(500)
          .snapshots(includeMetadataChanges: true)
          .map(_parse);

  /// "Các lần đo trước" (28) and the growth tile.
  Stream<List<CareRecord>> watchGrowth(String babyId) => _records(babyId)
      .where('type', isEqualTo: CareType.growth.name)
      .where('deleted', isEqualTo: false)
      .orderBy('occurredAt', descending: true)
      .limit(30)
      .snapshots(includeMetadataChanges: true)
      .map(_parse);

  Stream<CareRecord?> watchRecord(String babyId, String id) => _records(babyId)
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map(CareRecord.fromSnapshot);

  static List<CareRecord> _parse(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs) ?CareRecord.fromSnapshot(d),
  ];

  /// Saves without waiting for the server. Failures (e.g. access removed meanwhile) surface
  /// through [onError]; the cache rolls the write back.
  void create(CareRecord record, {void Function(Object error)? onError}) {
    _records(record.babyId)
        .doc(record.id)
        .set(record.toCreateJson())
        .catchError((Object e) => onError?.call(e));
  }

  void edit(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _records(record.babyId)
        .doc(record.id)
        .update(record.toEditJson(uid))
        .catchError((Object e) => onError?.call(e));
  }

  /// "Xóa bản ghi": soft delete into the 30-day bin.
  void softDelete(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _records(record.babyId)
        .doc(record.id)
        .update({
          'deleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        })
        .catchError((Object e) => onError?.call(e));
  }

  /// "Hoàn tác".
  void restore(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _records(record.babyId)
        .doc(record.id)
        .update({
          'deleted': false,
          'deletedAt': null,
          'deletedBy': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        })
        .catchError((Object e) => onError?.call(e));
  }

  // ---------- Timers (S5, P-011) ----------

  DocumentReference<Map<String, dynamic>> _timer(
    String babyId,
    TimerType type,
  ) => _db.doc('babies/$babyId/timers/${type.name}');

  Stream<CareTimer?> watchTimer(String babyId, TimerType type) => _timer(
    babyId,
    type,
  ).snapshots(includeMetadataChanges: true).map(CareTimer.fromSnapshot);

  /// Starts a timer. If another device already runs one, the server refuses this start and
  /// the listener falls back to theirs — this device joins it.
  void startTimer(CareTimer timer, {void Function(Object error)? onError}) {
    _timer(timer.babyId, timer.type)
        .set(timer.toJson(timer.startedBy))
        .catchError((Object e) => onError?.call(e));
  }

  void updateTimer(
    CareTimer timer,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _timer(timer.babyId, timer.type)
        .update(timer.toUpdateJson(uid))
        .catchError((Object e) => onError?.call(e));
  }

  /// "Hủy, không lưu".
  void cancelTimer(CareTimer timer, {void Function(Object error)? onError}) {
    _timer(
      timer.babyId,
      timer.type,
    ).delete().catchError((Object e) => onError?.call(e));
  }

  /// "Kết thúc": the record and the end of the timer in one atomic write; the record id comes
  /// from the session, so a second device ending it too cannot create a duplicate.
  void endTimer(
    CareTimer timer,
    CareRecord record, {
    void Function(Object error)? onError,
  }) {
    final batch = _db.batch()
      ..set(_records(record.babyId).doc(record.id), record.toCreateJson())
      ..delete(_timer(timer.babyId, timer.type));
    batch.commit().catchError((Object e) => onError?.call(e));
  }

  // ---------- Overlapping sleeps (27) ----------

  Stream<List<SleepConflict>> watchOpenConflicts(String babyId) => _db
      .collection('babies/$babyId/conflicts')
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) SleepConflict.fromJson(d.id, d.data())],
      );

  /// "Giữ bản đã chọn". Throws [FirebaseFunctionsException] (reason `not-allowed`).
  Future<void> resolveConflict({
    required String babyId,
    required String conflictId,
    required String keepRecordId,
  }) async {
    await _functions!.httpsCallable('resolveSleepOverlap').call<Object?>({
      'babyId': babyId,
      'conflictId': conflictId,
      'keepRecordId': keepRecordId,
    });
  }

  /// "Thử lại ngay" (9b): nudge the network and wait briefly for the queue to drain.
  Future<bool> retryNow() async {
    try {
      await _db.enableNetwork();
      await _db.waitForPendingWrites().timeout(const Duration(seconds: 8));
      return true;
    } on Object {
      return false;
    }
  }
}

final careRepositoryProvider = Provider<CareRepository>(
  (ref) => CareRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final careTimerProvider =
    StreamProvider.family<CareTimer?, (String, TimerType)>(
      (ref, key) =>
          ref.watch(careRepositoryProvider).watchTimer(key.$1, key.$2),
    );

final openConflictsProvider =
    StreamProvider.family<List<SleepConflict>, String>(
      (ref, babyId) =>
          ref.watch(careRepositoryProvider).watchOpenConflicts(babyId),
    );

/// Ticks on each minute boundary so "45 phút trước", "Bây giờ · 15:05" and the "now" marker
/// stay current. Tests override it with a fixed time.
final careClockProvider = StreamProvider<DateTime>((ref) async* {
  final now = DateTime.now();
  yield now;
  await Future<void>.delayed(
    Duration(seconds: 60 - now.second, milliseconds: -now.millisecond),
  );
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final recentRecordsProvider = StreamProvider.family<List<CareRecord>, String>(
  (ref, babyId) =>
      ref.watch(careRepositoryProvider).watchRecent(babyId, DateTime.now()),
);

final growthRecordsProvider = StreamProvider.family<List<CareRecord>, String>(
  (ref, babyId) => ref.watch(careRepositoryProvider).watchGrowth(babyId),
);

final careRecordProvider = StreamProvider.family<CareRecord?, (String, String)>(
  (ref, key) => ref.watch(careRepositoryProvider).watchRecord(key.$1, key.$2),
);

/// Device connectivity for "Đang offline" (9a). Firestore itself decides when to sync.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  try {
    yield online(await connectivity.checkConnectivity());
  } on Object {
    yield true;
  }
  yield* connectivity.onConnectivityChanged.map(online);
});

/// The baby's calendar day containing [at] (R-061: days follow the baby's time zone).
({DateTime start, DateTime end}) babyDayBounds(String zone, DateTime at) {
  ensureTimeZones();
  try {
    final location = tz.getLocation(zone);
    final local = tz.TZDateTime.from(at, location);
    final start = tz.TZDateTime(location, local.year, local.month, local.day);
    final end = tz.TZDateTime(location, local.year, local.month, local.day + 1);
    return (start: start.toUtc(), end: end.toUtc());
  } on Object catch (e) {
    debugPrint('babyDayBounds fallback: $e');
    final start = DateTime(at.year, at.month, at.day);
    return (start: start, end: start.add(const Duration(days: 1)));
  }
}

/// [at] as wall-clock time in the baby's zone (labels such as "Hôm nay, 14:20").
DateTime inBabyZone(String zone, DateTime at) {
  ensureTimeZones();
  try {
    final local = tz.TZDateTime.from(at, tz.getLocation(zone));
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  } on Object {
    return at.toLocal();
  }
}

/// Last choices per baby ("Remembers the last choice as the default", 9:124 / 45:386).
class CareMemory {
  CareMemory(this.read, this.write);

  final String? Function(String key) read;
  final void Function(String key, String value) write;

  static String _key(String babyId, String what) => 'care.$babyId.$what';

  T? get<T extends Enum>(String babyId, String what, List<T> values) =>
      values.asNameMap()[read(_key(babyId, what))];

  void set(String babyId, String what, Enum value) =>
      write(_key(babyId, what), value.name);
}

final careMemoryProvider = Provider<CareMemory>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CareMemory(prefs.getString, (k, v) => prefs.setString(k, v));
});

/// "Now" for running timers (elapsed time, ending); tests pin it.
final timerClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Per-second refresh on timer screens and live tiles; tests turn it off.
final timerTicksProvider = Provider<bool>((ref) => true);
