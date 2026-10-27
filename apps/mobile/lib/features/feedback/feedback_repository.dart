import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../auth/auth_repository.dart';

/// FB2 "Ý tưởng · Báo lỗi · Khác".
enum FeedbackType { idea, bug, other }

/// A screenshot to send with a Góp ý: picked (JPEG) or captured by FB4 (PNG).
class FeedbackShot {
  const FeedbackShot(this.bytes, {required this.png});
  final Uint8List bytes;
  final bool png;
}

/// FB3 "Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ": a ticket or a Góp ý sent from here.
class MyTicket {
  const MyTicket({
    required this.ticket,
    required this.category,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String ticket;
  final String category;
  final FeedbackType? type;
  final String message;

  /// `new` · `claimed` · `waiting` (answered) · `closed`.
  final String status;
  final DateTime createdAt;

  static MyTicket? fromJson(Object? json) {
    if (json is! Map) return null;
    final ticket = json['ticket'];
    final created = DateTime.tryParse('${json['createdAt']}');
    if (ticket is! String || created == null) return null;
    return MyTicket(
      ticket: ticket,
      category: '${json['category']}',
      type: FeedbackType.values.asNameMap()[json['feedbackType']],
      message: '${json['message'] ?? ''}',
      status: '${json['status']}',
      createdAt: created.toLocal(),
    );
  }
}

/// Góp ý & đánh giá (D-065): `sendFeedback`, `myHelpTickets`; the screenshot goes to Storage
/// first (`feedback/{uid}/{requestId}.{jpg|png}`).
class FeedbackRepository {
  FeedbackRepository(this._functions, this._storage, this._uid);

  final FirebaseFunctions Function() _functions;

  /// Read only when a screenshot goes up, so tests without Firebase never touch it.
  final FirebaseStorage Function() _storage;
  final String? Function() _uid;

  /// The screenshot gets this long to go up (Storage would otherwise retry for ~10 minutes).
  static const shotTimeout = Duration(seconds: 60);

  /// [requestId] is the draft's, kept across "Gửi" retries: the server makes one ticket per
  /// id, so a retry after a lost answer never files the same Góp ý twice (FB-1).
  Future<String> send({
    required String requestId,
    required FeedbackType type,
    required String message,
    required FeedbackShot? shot,
    required Map<String, Object?>? diagnostics,
    required bool replyByEmail,
    required String locale,
  }) async {
    final uid = _uid();
    if (uid == null) throw StateError('signed out');
    final ext = shot == null ? null : (shot.png ? 'png' : 'jpg');
    if (shot != null) {
      final task = _storage()
          .ref('feedback/$uid/$requestId.$ext')
          .putData(
            shot.bytes,
            SettableMetadata(
              contentType: shot.png ? 'image/png' : 'image/jpeg',
            ),
          );
      try {
        await task.timeout(shotTimeout);
      } on TimeoutException {
        unawaited(task.cancel().then((_) {}, onError: (Object _) {}));
        rethrow;
      }
    }
    final result = await _functions()
        .httpsCallable('sendFeedback')
        .call<Object?>({
          'requestId': requestId,
          'type': type.name,
          'message': message.trim(),
          'screenshot': ext,
          'diagnostics': diagnostics,
          'replyByEmail': replyByEmail,
          'locale': locale,
        });
    return (result.data! as Map)['ticket'] as String;
  }

  Future<List<MyTicket>> mine() async {
    final result = await _functions()
        .httpsCallable('myHelpTickets')
        .call<Object?>({});
    final data = result.data;
    return [
      if (data is List)
        for (final t in data) ?MyTicket.fromJson(t),
    ];
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(
    () => ref.read(functionsProvider),
    () => FirebaseStorage.instance,
    () => ref.read(authRepositoryProvider).currentUser?.uid,
  ),
);

/// Trợ giúp & liên hệ "Đã gửi"; refreshed after sending.
final myTicketsProvider = FutureProvider.autoDispose<List<MyTicket>>(
  (ref) => ref.watch(feedbackRepositoryProvider).mine(),
  // Offline: the list stays hidden until the screen opens again.
  retry: (_, _) => null,
);

/// The screenshot FB4 captured, waiting for FB2 to pick it up.
final pendingShotProvider = NotifierProvider<PendingShot, FeedbackShot?>(
  PendingShot.new,
);

class PendingShot extends Notifier<FeedbackShot?> {
  @override
  FeedbackShot? build() => null;

  // ignore: use_setters_to_change_properties
  void set(FeedbackShot? shot) => state = shot;
}
