import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import 'reminder_models.dart';

/// Reminders (S7). Like care records, writes go straight to Firestore so the local cache is the
/// offline outbox; nothing waits for the server. Failures surface through `onError`.
class ReminderRepository {
  ReminderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String babyId) =>
      _db.collection('babies/$babyId/reminders');

  Stream<List<Reminder>> watch(String babyId) => _col(babyId)
      .orderBy('dueAt')
      .limit(500)
      .snapshots(includeMetadataChanges: true)
      .map((s) => [for (final d in s.docs) ?Reminder.fromSnapshot(d)]);

  void _run(Future<void> write, void Function(Object error)? onError) =>
      write.catchError((Object e) => onError?.call(e));

  void create(Reminder r, {void Function(Object error)? onError}) =>
      _run(_col(r.babyId).doc(r.id).set(r.toCreateJson()), onError);

  void edit(
    Reminder before,
    Reminder after,
    String uid, {
    void Function(Object error)? onError,
  }) => _run(
    _col(after.babyId).doc(after.id).update(after.toEditJson(before, uid)),
    onError,
  );

  /// "Đánh dấu đã xong" and its undo (D-030).
  void setDone(
    Reminder r,
    Membership me, {
    required bool done,
    void Function(Object error)? onError,
  }) => _run(
    _col(r.babyId).doc(r.id).update(reminderDoneJson(me, done: done)),
    onError,
  );

  /// "Thông báo" → this device (D-029).
  void moveNotifications(
    Reminder r,
    NotifyDevice device, {
    void Function(Object error)? onError,
  }) => _run(
    _col(r.babyId).doc(r.id).update({
      'notifyDevice': device.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': device.uid,
    }),
    onError,
  );

  void delete(Reminder r, {void Function(Object error)? onError}) =>
      _run(_col(r.babyId).doc(r.id).delete(), onError);
}

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.watch(firestoreProvider)),
);

/// Every reminder of a baby, soonest first (relatives never reach this, D-018).
final remindersProvider = StreamProvider.family<List<Reminder>, String>(
  (ref, babyId) => ref.watch(reminderRepositoryProvider).watch(babyId),
);
