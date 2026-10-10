import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import '../care/care_models.dart';
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

  Future<void> cancel(String babyId, List<String> mediaIds) =>
      _call('cancelMemoryUploads', {'babyId': babyId, 'mediaIds': mediaIds});

  /// A video held for Wi-Fi on this device does not hold up the family notice (D-033).
  Future<void> markWaitingWifi(String babyId, String mediaId, bool waiting) =>
      _db.doc('babies/$babyId/media/$mediaId').update({
        'clientState': waiting ? 'waitingWifi' : null,
      });

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
  });
  final int mediaItemsPerAdd;
  final int familyQuotaBytes;
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
        );
      }),
);
