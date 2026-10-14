import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import '../care/care_models.dart';
import 'album_models.dart';
import 'memory_models.dart';

/// Memories (S9). Reads follow the Rules: Cùng nuôi query everything, relatives only what is
/// shared with the family (D-002, R-119); caregivers never reach these providers. Every change
/// goes through a callable (ADR-004) except family milestones (R-105).
class MemoryRepository {
  MemoryRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Timeline entries, newest first.
  Stream<List<Memory>> watchMemories(String babyId, {required bool parent}) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/memories');
    if (!parent) {
      q = q
          .where('audience', isEqualTo: Audience.family.name)
          .where('state', isEqualTo: 'published');
    }
    return q
        .where('deleted', isEqualTo: false)
        .orderBy('occurredAt', descending: true)
        .limit(1000)
        .snapshots()
        .map((s) => [for (final d in s.docs) ?Memory.fromSnapshot(d)]);
  }

  /// Items, newest capture first; parents also see uploads in progress.
  Stream<List<MediaItem>> watchMedia(String babyId, {required bool parent}) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/media');
    if (!parent) {
      q = q
          .where('effectiveAudience', isEqualTo: Audience.family.name)
          .where('status', isEqualTo: MediaStatus.ready.name);
    }
    return q
        .where('deleted', isEqualTo: false)
        .orderBy('captureAt', descending: true)
        .limit(5000)
        .snapshots()
        .map((s) => [for (final d in s.docs) ?MediaItem.fromSnapshot(d)]);
  }

  Stream<List<FamilyMilestone>> watchMilestones(String babyId) => _db
      .collection('babies/$babyId/milestones')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?FamilyMilestone.fromSnapshot(d)]);

  /// The uploader's batch: who was told (UploadPill "Đã báo cho Bà nội, Ông ngoại").
  Stream<List<CareAuthor>?> watchNotified(String babyId, String batchId) =>
      _db.doc('babies/$babyId/uploadBatches/$batchId').snapshots().map((s) {
        if (s.data()?['notifiedAt'] == null) return null;
        return [
          for (final r in (s.data()?['notified'] as List? ?? const []))
            CareAuthor.fromJson(r),
        ];
      });

  /// 10h4 "Tạo & gắn mốc".
  Future<MilestoneRef> createMilestone(
    String babyId,
    Membership me,
    String name,
    DateTime date,
  ) async {
    final id = newMilestoneId();
    final ref = MilestoneRef(id: id, name: name.trim(), date: date);
    await _db.doc('babies/$babyId/milestones/$id').set({
      'id': id,
      'babyId': babyId,
      'name': ref.name,
      'date': isoDateOf(date),
      'createdBy': me.uid,
      'author': CareAuthor.of(me).toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref;
  }

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    final result = await _functions.httpsCallable(name).call<Object?>(data);
    final value = result.data;
    return value is Map ? value.cast<String, Object?>() : const {};
  }

  /// 10h "Tải lên N mục": reserved ids upload now, the rest wait for quota (R-121).
  Future<({List<String> reserved, List<String> waitingQuota})> createSession(
    Map<String, Object?> request,
  ) async {
    final r = await _call('createMemorySession', request);
    List<String> ids(String key) => [
      for (final id in (r[key] as List? ?? const []))
        if (id is String) id,
    ];
    return (reserved: ids('reserved'), waitingQuota: ids('waitingQuota'));
  }

  Future<List<String>> reserve(String babyId, List<String> mediaIds) async {
    final r = await _call('reserveMemoryUploads', {
      'babyId': babyId,
      'mediaIds': mediaIds,
    });
    return [
      for (final id in (r['reserved'] as List? ?? const []))
        if (id is String) id,
    ];
  }

  /// What the server made of an item (`uploading`, `ready`, …), or null when unknown. Tells
  /// "Storage refused the bytes" from "Storage already has them" (a file that finished while the
  /// app was gone, 10j).
  Future<String?> mediaStatus(String babyId, String mediaId) async {
    final d = await _db.doc('babies/$babyId/media/$mediaId').get();
    return d.data()?['status'] as String?;
  }

  Future<void> cancel(String babyId, List<String> mediaIds) =>
      _call('cancelMemoryUploads', {'babyId': babyId, 'mediaIds': mediaIds});

  /// A video held for Wi-Fi on this device does not hold up the family notice (D-033).
  Future<void> markWaitingWifi(String babyId, String mediaId, bool waiting) =>
      _db.doc('babies/$babyId/media/$mediaId').update({
        'clientState': waiting ? 'waitingWifi' : null,
      });

  // ---------- S10: albums, favourites, loves, messages ----------

  /// Parents: every album; relatives: the shared ones (11e).
  Stream<List<Album>> watchAlbums(String babyId, {required bool parent}) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/albums');
    if (!parent) q = q.where('audience', isEqualTo: Audience.family.name);
    return q.snapshots().map((s) {
      final list = [for (final d in s.docs) ?Album.fromSnapshot(d)];
      list.sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
      return list;
    });
  }

  /// mediaId → when it joined the album ("Mới thêm vào album", 10e7).
  Stream<Map<String, DateTime>> watchAlbumItems(
    String babyId,
    String albumId,
  ) => _db
      .collection('babies/$babyId/albums/$albumId/items')
      .snapshots()
      .map(
        (s) => {
          for (final d in s.docs)
            d.id: dateOf(d.data()['addedAt']) ?? DateTime(2000),
        },
      );

  Future<void> createAlbum(
    String babyId,
    String albumId,
    String name,
    Audience audience,
    List<String> mediaIds,
  ) => _call('createMemoryAlbum', {
    'babyId': babyId,
    'albumId': albumId,
    'name': name,
    'audience': audience.name,
    'mediaIds': mediaIds,
  });

  /// rename / cover / sort / audience (10e4–10e7); returns how many items stay shared (D-002).
  Future<int> updateAlbum(
    String babyId,
    String albumId,
    Map<String, Object?> change,
  ) async {
    final r = await _call('updateMemoryAlbum', {
      'babyId': babyId,
      'albumId': albumId,
      'change': change,
    });
    return (r['stayingShared'] as num?)?.toInt() ?? 0;
  }

  Future<void> addToAlbum(
    String babyId,
    String albumId,
    List<String> mediaIds,
  ) => _call('addToMemoryAlbum', {
    'babyId': babyId,
    'albumId': albumId,
    'mediaIds': mediaIds,
  });

  Future<void> removeFromAlbum(
    String babyId,
    String albumId,
    List<String> mediaIds,
  ) => _call('removeFromMemoryAlbum', {
    'babyId': babyId,
    'albumId': albumId,
    'mediaIds': mediaIds,
  });

  Future<void> deleteAlbum(String babyId, String albumId) =>
      _call('deleteMemoryAlbum', {'babyId': babyId, 'albumId': albumId});

  /// "Yêu thích" — mine only (R-107).
  Stream<Set<String>> watchFavorites(String babyId, String uid) => _db
      .collection('babies/$babyId/favorites')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => {for (final d in s.docs) d.data()['mediaId'] as String? ?? ''},
      );

  Future<void> setFavorite(String babyId, String uid, String mediaId, bool on) {
    final ref = _db.doc(
      'babies/$babyId/favorites/${favoriteIdOf(uid, mediaId)}',
    );
    return on
        ? ref.set({
            'uid': uid,
            'mediaId': mediaId,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : ref.delete();
  }

  /// Parents: every love (to name who loved); relatives: their own.
  Stream<List<Love>> watchLoves(
    String babyId,
    String uid, {
    required bool parent,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/reactions');
    if (!parent) q = q.where('uid', isEqualTo: uid);
    return q
        .limit(5000)
        .snapshots()
        .map((s) => [for (final d in s.docs) ?Love.fromSnapshot(d)]);
  }

  Future<void> setLove(
    Membership me,
    LoveTarget target,
    String targetId,
    bool on,
  ) {
    final ref = _db.doc(
      'babies/${me.babyId}/reactions/${loveIdOf(target, targetId, me.uid)}',
    );
    return on
        ? ref.set({
            'uid': me.uid,
            'target': target.name,
            'targetId': targetId,
            'author': CareAuthor.of(me).toJson(),
            'createdAt': FieldValue.serverTimestamp(),
          })
        : ref.delete();
  }

  /// "Nhắn ba mẹ" / "Nhắn Mẹ" (D-034).
  Future<void> sendMessage(
    Membership me,
    MessageContext context,
    String contextId,
    String text,
  ) {
    final id = newMessageId();
    return _db.doc('babies/${me.babyId}/messages/$id').set({
      'id': id,
      'babyId': me.babyId,
      'from': me.uid,
      'author': CareAuthor.of(me).toJson(),
      'context': {'kind': context.name, 'id': contextId},
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String, Object?>{},
    });
  }

  /// Parents: all messages ("Lời nhắn"); anyone else: what they sent.
  Stream<List<ParentMessage>> watchMessages(
    String babyId,
    String uid, {
    required bool parent,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/messages');
    if (!parent) q = q.where('from', isEqualTo: uid);
    return q
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((s) => [for (final d in s.docs) ?ParentMessage.fromSnapshot(d)]);
  }

  Future<void> markRead(String babyId, String messageId, String uid) => _db
      .doc('babies/$babyId/messages/$messageId')
      .update({'readBy.$uid': true});

  /// 10b3 / 10b4 / 10o.
  Future<void> update(
    String babyId,
    List<String> mediaIds,
    Map<String, Object?> change,
  ) => _call('updateMemoryMedia', {
    'babyId': babyId,
    'mediaIds': mediaIds,
    'change': change,
  });
}

final memoryRepositoryProvider = Provider<MemoryRepository>(
  (ref) => MemoryRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// (babyId, parent?)
typedef MemoryKey = (String, bool);

final memoriesProvider = StreamProvider.family<List<Memory>, MemoryKey>(
  (ref, key) =>
      ref.watch(memoryRepositoryProvider).watchMemories(key.$1, parent: key.$2),
);

final mediaProvider = StreamProvider.family<List<MediaItem>, MemoryKey>(
  (ref, key) =>
      ref.watch(memoryRepositoryProvider).watchMedia(key.$1, parent: key.$2),
);

final familyMilestonesProvider =
    StreamProvider.family<List<FamilyMilestone>, String>(
      (ref, babyId) =>
          ref.watch(memoryRepositoryProvider).watchMilestones(babyId),
    );

final notifiedProvider =
    StreamProvider.family<List<CareAuthor>?, (String, String)>(
      (ref, key) =>
          ref.watch(memoryRepositoryProvider).watchNotified(key.$1, key.$2),
    );

/// Global limits mirrored to `publicConfig/limits` (D-011): batch size and quota.
@immutable
class PublicLimits {
  const PublicLimits({
    this.mediaItemsPerAdd = 30,
    this.familyQuotaBytes = 10 * 1024 * 1024 * 1024,
    this.autoSaveItemsPerApprove = 200,
  });
  final int mediaItemsPerAdd;
  final int familyQuotaBytes;

  /// Tự lưu: at most this many items per "Tải lên" (D-070).
  final int autoSaveItemsPerApprove;
}

final publicLimitsProvider = StreamProvider<PublicLimits>(
  (ref) => ref
      .watch(firestoreProvider)
      .doc('publicConfig/limits')
      .snapshots()
      .map((s) {
        final d = s.data() ?? const {};
        return PublicLimits(
          mediaItemsPerAdd: (d['mediaItemsPerAdd'] as num?)?.toInt() ?? 30,
          familyQuotaBytes:
              (d['familyQuotaBytes'] as num?)?.toInt() ??
              10 * 1024 * 1024 * 1024,
          autoSaveItemsPerApprove:
              (d['autoSaveItemsPerApprove'] as num?)?.toInt() ?? 200,
        );
      }),
);

final albumsProvider = StreamProvider.family<List<Album>, MemoryKey>(
  (ref, key) =>
      ref.watch(memoryRepositoryProvider).watchAlbums(key.$1, parent: key.$2),
);

final albumItemsProvider =
    StreamProvider.family<Map<String, DateTime>, (String, String)>(
      (ref, key) =>
          ref.watch(memoryRepositoryProvider).watchAlbumItems(key.$1, key.$2),
    );

/// (babyId, uid)
final favoritesProvider = StreamProvider.family<Set<String>, (String, String)>(
  (ref, key) =>
      ref.watch(memoryRepositoryProvider).watchFavorites(key.$1, key.$2),
);

/// (babyId, uid, parent)
final lovesProvider = StreamProvider.family<List<Love>, (String, String, bool)>(
  (ref, key) => ref
      .watch(memoryRepositoryProvider)
      .watchLoves(key.$1, key.$2, parent: key.$3),
);

/// (babyId, uid, parent)
final messagesProvider =
    StreamProvider.family<List<ParentMessage>, (String, String, bool)>(
      (ref, key) => ref
          .watch(memoryRepositoryProvider)
          .watchMessages(key.$1, key.$2, parent: key.$3),
    );
