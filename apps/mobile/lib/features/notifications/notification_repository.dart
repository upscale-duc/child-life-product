import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../reminders/reminder_notifications.dart';
import 'notification_models.dart';

/// Notification centre (D-076 #2): the person's inbox (EN06) and switches (EN07). The inbox is
/// written by Functions only; the app may set `readAt` / `archivedAt` once (Rules).
abstract class NotificationRepository {
  /// The newest rows first (at most [limit]); archived ones left out.
  Stream<List<InboxItem>> watchInbox(String uid, {int limit});
  Future<void> markRead(String uid, Iterable<String> ids);
  Future<void> archive(String uid, String id);
  Stream<NotificationSettings> watchSettings(String uid);
  Future<void> saveSettings(String uid, NotificationSettings settings);
}

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection('users/$uid/notifications');

  @override
  Stream<List<InboxItem>> watchInbox(String uid, {int limit = 100}) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (q) => [
              for (final d in q.docs)
                if (InboxItem.fromDoc(d.id, d.data()) case final item?
                    when item.archivedAt == null)
                  item,
            ],
          );

  @override
  Future<void> markRead(String uid, Iterable<String> ids) async {
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 400) {
      final batch = _db.batch();
      for (final id in list.skip(i).take(400)) {
        batch.update(_inbox(uid).doc(id), {
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> archive(String uid, String id) =>
      _inbox(uid).doc(id).update({'archivedAt': FieldValue.serverTimestamp()});

  @override
  Stream<NotificationSettings> watchSettings(String uid) => _db
      .doc('users/$uid/settings/notifications')
      .snapshots()
      .map((d) => NotificationSettings.fromMap(d.data()));

  @override
  Future<void> saveSettings(String uid, NotificationSettings settings) =>
      _db.doc('users/$uid/settings/notifications').set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => FirestoreNotificationRepository(ref.watch(firestoreProvider)),
);

final inboxProvider = StreamProvider.family<List<InboxItem>, String>(
  (ref, uid) => ref.watch(notificationRepositoryProvider).watchInbox(uid),
);

final notificationSettingsProvider =
    StreamProvider.family<NotificationSettings, String>(
      (ref, uid) =>
          ref.watch(notificationRepositoryProvider).watchSettings(uid),
    );

/// Unread rows for the signed-in person: the bell's red dot.
final unreadNotificationsProvider = Provider<int>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return 0;
  final items = ref.watch(inboxProvider(session.user.uid)).value ?? const [];
  return items.where((i) => i.unread).length;
});

/// Whether the OS lets this app show notifications (EN07 master card). Re-read after a request
/// or on return from system settings.
final osNotificationsEnabledProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    return await ref.read(reminderNotificationsProvider).enabled();
  } on Object {
    return false;
  }
});
