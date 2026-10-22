import 'dart:async';
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
    q = q
        .where('deleted', isEqualTo: false)
        .orderBy('occurredAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    return _historyPages(
      q,
      'occurredAt',
      Memory.fromSnapshot,
      pageSize: 1000,
    ).map((p) => p.items);
  }

  /// Items, newest capture first; parents also see uploads in progress.
  Stream<List<MediaItem>> watchMedia(String babyId, {required bool parent}) {
    Query<Map<String, dynamic>> q = _db.collection('babies/$babyId/media');
    if (!parent) {
      q = q
          .where('effectiveAudience', isEqualTo: Audience.family.name)
          .where('status', isEqualTo: MediaStatus.ready.name);
    }
    q = q
        .where('deleted', isEqualTo: false)
        .orderBy('captureAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    return _historyPages(
      q,
      'captureAt',
      MediaItem.fromSnapshot,
      pageSize: 5000,
    ).map((p) => p.items);
  }

  // Keep the former initial coverage for existing pickers/weekly compositions. These
  // are now first windows, not history caps; every continuation uses a 200-item cursor.
  static const historyPageSize = 200;

  /// A live page has a frozen inclusive end cursor, so inserts never push an
  /// unseen boundary item between pages. Deletions/visibility changes remain live.
  Stream<HistorySlice<T>> _historyPages<T>(
    Query<Map<String, dynamic>> query,
    String field,
    T? Function(DocumentSnapshot<Map<String, dynamic>>) decode, {
    int pageSize = historyPageSize,
  }) async* {
    final first = await query.limit(pageSize).get();
    final last = first.docs.lastOrNull;
    final cursor = last == null ? null : (dateOf(last.data()[field])!, last.id);
    HistorySlice<T> slice(QuerySnapshot<Map<String, dynamic>> snap) =>
        HistorySlice(
          [for (final d in snap.docs) ?decode(d)],
          cursor,
          first.docs.length == pageSize,
        );
    yield slice(first);
    if (first.docs.length < pageSize) {
      // Includes an initially empty journal and later backdated inserts.
      yield* query.snapshots().map(slice);
    } else if (last != null) {
      yield* query.endAt([last.data()[field], last.id]).snapshots().map(slice);
    }
  }

  Stream<HistorySlice<MediaItem>> olderMedia(
    MemoryKey key,
    (DateTime, String) cursor,
  ) {
    Query<Map<String, dynamic>> q = _db
        .collection('babies/${key.$1}/media')
        .where('deleted', isEqualTo: false);
    if (!key.$2) {
      q = q
          .where('effectiveAudience', isEqualTo: 'family')
          .where('status', isEqualTo: 'ready');
    }
    q = q
        .orderBy('captureAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .startAfter([Timestamp.fromDate(cursor.$1), cursor.$2]);
    return _historyPages(q, 'captureAt', MediaItem.fromSnapshot);
  }

  Stream<HistorySlice<Memory>> olderMemories(
    MemoryKey key,
    (DateTime, String) cursor,
  ) {
    Query<Map<String, dynamic>> q = _db
        .collection('babies/${key.$1}/memories')
        .where('deleted', isEqualTo: false);
    if (!key.$2) {
      q = q
          .where('audience', isEqualTo: 'family')
          .where('state', isEqualTo: 'published');
    }
    q = q
        .orderBy('occurredAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .startAfter([Timestamp.fromDate(cursor.$1), cursor.$2]);
    return _historyPages(q, 'occurredAt', Memory.fromSnapshot);
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

  Stream<String?> watchMediaStatus(String babyId, String mediaId) => _db
      .doc('babies/$babyId/media/$mediaId')
      .snapshots()
      .map((d) => d.data()?['status'] as String?);

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

class HistorySlice<T> {
  const HistorySlice(this.items, this.cursor, this.hasMore);
  final List<T> items;
  final (DateTime, String)? cursor;
  final bool hasMore;
}

class HistoryTail {
  const HistoryTail({
    this.media = const [],
    this.memories = const [],
    this.loading = false,
    this.mediaEnd = false,
    this.memoryEnd = false,
    this.error = false,
  });
  final List<MediaItem> media;
  final List<Memory> memories;
  final bool loading, mediaEnd, memoryEnd, error;
}

final historyTailProvider =
    NotifierProvider<HistoryTailController, Map<MemoryKey, HistoryTail>>(
      HistoryTailController.new,
    );

class HistoryTailController extends Notifier<Map<MemoryKey, HistoryTail>> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _busy = <MemoryKey>{};
  final _mediaPages = <MemoryKey, List<HistorySlice<MediaItem>>>{};
  final _memoryPages = <MemoryKey, List<HistorySlice<Memory>>>{};
  @override
  Map<MemoryKey, HistoryTail> build() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _mediaPages.clear();
    _memoryPages.clear();
    _busy.clear();
    ref.onDispose(() {
      for (final s in _subscriptions) {
        unawaited(s.cancel());
      }
    });
    return {};
  }

  void _publish(MemoryKey key, {bool loading = false, bool error = false}) {
    if (!ref.mounted) return;
    final media = _mediaPages[key] ?? [];
    final memories = _memoryPages[key] ?? [];
    state = {
      ...state,
      key: HistoryTail(
        media: [for (final p in media) ...p.items],
        memories: [for (final p in memories) ...p.items],
        mediaEnd: media.isNotEmpty
            ? !media.last.hasMore
            : (ref.read(mediaProvider(key)).value?.length ?? 0) <
                  MemoryRepository.historyPageSize,
        memoryEnd: memories.isNotEmpty
            ? !memories.last.hasMore
            : (ref.read(memoriesProvider(key)).value?.length ?? 0) <
                  MemoryRepository.historyPageSize,
        loading: _busy.contains(key),
        error: error,
      ),
    };
  }

  Future<void> loadMore(MemoryKey key) async {
    if (_busy.contains(key)) return;
    _busy.add(key);
    final repo = ref.read(memoryRepositoryProvider);
    final currentMedia = ref.read(mediaProvider(key)).value ?? [];
    final currentMemories = ref.read(memoriesProvider(key)).value ?? [];
    _publish(key, loading: true);
    try {
      final work = <Future<void>>[];
      if (!(state[key]?.mediaEnd ?? false) && currentMedia.isNotEmpty) {
        final pages = _mediaPages.putIfAbsent(key, () => []);
        final cursor = pages.isEmpty
            ? (currentMedia.last.captureAt, currentMedia.last.id)
            : pages.last.cursor;
        if (cursor != null) {
          final done = Completer<void>();
          final index = pages.length;
          pages.add(const HistorySlice([], null, true));
          _subscriptions.add(
            repo
                .olderMedia(key, cursor)
                .listen(
                  (page) {
                    pages[index] = page;
                    _publish(key, loading: !done.isCompleted);
                    if (!done.isCompleted) done.complete();
                  },
                  cancelOnError: true,
                  onError: (Object e) {
                    if (!done.isCompleted) {
                      done.completeError(e);
                    } else {
                      _publish(key, error: true);
                    }
                  },
                ),
          );
          work.add(done.future);
        }
      }
      if (!(state[key]?.memoryEnd ?? false) && currentMemories.isNotEmpty) {
        final pages = _memoryPages.putIfAbsent(key, () => []);
        final cursor = pages.isEmpty
            ? (currentMemories.last.occurredAt, currentMemories.last.id)
            : pages.last.cursor;
        if (cursor != null) {
          final done = Completer<void>();
          final index = pages.length;
          pages.add(const HistorySlice([], null, true));
          _subscriptions.add(
            repo
                .olderMemories(key, cursor)
                .listen(
                  (page) {
                    pages[index] = page;
                    _publish(key, loading: !done.isCompleted);
                    if (!done.isCompleted) done.complete();
                  },
                  cancelOnError: true,
                  onError: (Object e) {
                    if (!done.isCompleted) {
                      done.completeError(e);
                    } else {
                      _publish(key, error: true);
                    }
                  },
                ),
          );
          work.add(done.future);
        }
      }
      await Future.wait(work);
      _busy.remove(key);
      _publish(key);
    } catch (_) {
      _busy.remove(key);
      if (_mediaPages[key]?.lastOrNull?.cursor == null) {
        _mediaPages[key]?.removeLast();
      }
      if (_memoryPages[key]?.lastOrNull?.cursor == null) {
        _memoryPages[key]?.removeLast();
      }
      _publish(key, error: true);
    }
  }
}

/// Sorts [items] by [compare] unless they already are: the live window comes newest first from
/// its query and older pages follow it, so most snapshots skip the sort.
List<T> _sortIfNeeded<T>(List<T> items, Comparator<T> compare) {
  for (var i = 1; i < items.length; i++) {
    if (compare(items[i - 1], items[i]) > 0) return items..sort(compare);
  }
  return items;
}

final completeMediaProvider =
    Provider.family<AsyncValue<List<MediaItem>>, MemoryKey>(buildCompleteMedia);

AsyncValue<List<MediaItem>> buildCompleteMedia(Ref ref, MemoryKey key) {
  final tail = ref.watch(historyTailProvider.select((s) => s[key]));
  return ref.watch(mediaProvider(key)).whenData((recent) {
    // The live window wins over the same id in older pages.
    final byId = {for (final i in recent) i.id: i};
    final older = {for (final i in tail?.media ?? <MediaItem>[]) i.id: i};
    for (final i in older.values) {
      byId.putIfAbsent(i.id, () => i);
    }
    return _sortIfNeeded(byId.values.toList(), (a, b) {
      final byTime = b.captureAt.compareTo(a.captureAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  });
}

final completeMemoriesProvider =
    Provider.family<AsyncValue<List<Memory>>, MemoryKey>(buildCompleteMemories);

AsyncValue<List<Memory>> buildCompleteMemories(Ref ref, MemoryKey key) {
  final tail = ref.watch(historyTailProvider.select((s) => s[key]));
  return ref.watch(memoriesProvider(key)).whenData((recent) {
    // The live window wins over the same id in older pages.
    final byId = {for (final i in recent) i.id: i};
    final older = {for (final i in tail?.memories ?? <Memory>[]) i.id: i};
    for (final i in older.values) {
      byId.putIfAbsent(i.id, () => i);
    }
    return _sortIfNeeded(byId.values.toList(), (a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  });
}

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
