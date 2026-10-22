import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../reminders/reminder_notifications.dart';
import 'notification_models.dart';

/// Notification centre (D-076 #2): the person's inbox (EN06) and switches (EN07). The inbox is
/// written by Functions only; the app may set `readAt` / `archivedAt` once (Rules).
abstract class NotificationRepository {
  /// The newest rows first (at most [limit] read); archived and expired ones left out.
  Stream<InboxPage> watchInbox(String uid, {int limit});

  /// Unread rows (at most [unreadCap]) for the bell, whatever page the inbox has loaded.
  Stream<int> watchUnreadCount(String uid);
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
  Stream<InboxPage> watchInbox(String uid, {int limit = inboxPageSize}) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) {
            final now = DateTime.now();
            return InboxPage(
              items: [
                for (final d in q.docs)
                  if (InboxItem.fromDoc(d.id, d.data()) case final item?
                      when !item.hiddenAt(now))
                    item,
              ],
              more: q.docs.length >= limit,
            );
          });

  /// Equality on `readAt` alone uses the automatic single-field index (no composite index);
  /// archived and expired rows are dropped here.
  @override
  Stream<int> watchUnreadCount(String uid) => _inbox(uid)
      .where('readAt', isNull: true)
      .limit(unreadCap)
      .snapshots()
      .map((q) {
        final now = DateTime.now();
        return q.docs.where((d) {
          final item = InboxItem.fromDoc(d.id, d.data());
          return item != null && !item.hiddenAt(now);
        }).length;
      });

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

/// EN06 loads [inboxPageSize] rows, then [inboxPageSize] more each time the end is reached.
const inboxPageSize = 30;

/// The bell counts at most this many unread rows.
const unreadCap = 99;

/// One loaded window of the inbox; [more] while the query filled its limit.
class InboxPage {
  const InboxPage({required this.items, required this.more});
  final List<InboxItem> items;
  final bool more;
}

final inboxProvider =
    StreamProvider.family<InboxPage, ({String uid, int limit})>(
      (ref, key) => ref
          .watch(notificationRepositoryProvider)
          .watchInbox(key.uid, limit: key.limit),
    );

final unreadCountProvider = StreamProvider.family<int, String>(
  (ref, uid) => ref.watch(notificationRepositoryProvider).watchUnreadCount(uid),
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
  return ref.watch(unreadCountProvider(session.user.uid)).value ?? 0;
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
