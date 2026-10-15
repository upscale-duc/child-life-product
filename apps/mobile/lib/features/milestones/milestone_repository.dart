import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import '../care/care_models.dart';
import '../memories/memory_models.dart';
import '../memories/upload_queue.dart' show PickedMedia;
import 'milestone_models.dart';

/// Mốc phát triển reads and writes. Records are written straight to Firestore like Kỷ niệm's
/// family milestones (R-105); the Rules check the shape, the role (Cùng nuôi only, `moments.create`)
/// and the author. Nothing about the child is logged.
abstract class MilestoneRepository {
  /// Published reference milestones (`contentMilestones`, `status == 'published'`).
  Stream<List<ReferenceMilestone>> watchReference();

  /// The baby's records (Cùng nuôi only; others are refused by the Rules).
  Stream<List<MilestoneRecord>> watchRecords(String babyId);

  /// 3c "Lưu mốc": observe a reference milestone (creates or updates `p_<id>`).
  Future<void> observeReference(
    Membership me,
    ReferenceMilestone m, {
    required String name,
    required DateTime date,
    String? note,
    MilestoneRecord? existing,
  });

  /// 3b "Lưu để theo dõi".
  Future<void> follow(
    Membership me,
    ReferenceMilestone m, {
    required String name,
  });

  /// 3g "Lưu mốc": a custom milestone; returns its id.
  Future<String> createCustom(
    Membership me, {
    required String name,
    required DateTime date,
    String? note,
    RecordSource source = RecordSource.milestones,
  });

  /// Edit the day, note or (custom) name.
  Future<void> edit(
    Membership me,
    MilestoneRecord r, {
    required String name,
    required DateTime date,
    String? note,
  });

  /// 3e / 3f: the memory made from or tagged with this record.
  Future<void> linkMemory(Membership me, MilestoneRecord r, String memoryId);

  /// "Xoá ghi nhận" / "Bỏ theo dõi". Memories keep their tag (denormalised).
  Future<void> remove(String babyId, String recordId);
}

class FirestoreMilestoneRepository implements MilestoneRepository {
  FirestoreMilestoneRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<ReferenceMilestone>> watchReference() => _db
      .collection('contentMilestones')
      // The Rules allow lists only with this filter (contracts milestones.ts).
      .where('status', isEqualTo: 'published')
      .snapshots()
      .map(
        (q) => sortReference([
          for (final d in q.docs) ?ReferenceMilestone.fromJson(d.id, d.data()),
        ]),
      );

  @override
  Stream<List<MilestoneRecord>> watchRecords(String babyId) => _db
      .collection('babies/$babyId/milestones')
      .snapshots()
      .map((q) => [for (final d in q.docs) ?MilestoneRecord.fromSnapshot(d)]);

  DocumentReference<Map<String, dynamic>> _doc(String babyId, String id) =>
      _db.doc('babies/$babyId/milestones/$id');

  Map<String, Object?> _new(
    Membership me, {
    required String id,
    required RecordKind kind,
    required String? referenceId,
    required String name,
    required RecordStatus status,
    required DateTime? date,
    required String? note,
    required RecordSource source,
    List<String> memoryIds = const [],
  }) => {
    'id': id,
    'babyId': me.babyId,
    'kind': kind.name,
    'referenceId': referenceId,
    'name': _name(name),
    'status': status.name,
    'date': date == null ? null : isoDateOf(date),
    'note': _note(note),
    'memoryIds': memoryIds,
    'source': source.name,
    'createdBy': me.uid,
    'author': CareAuthor.of(me).toJson(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedBy': me.uid,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Every field a record holds after an edit (old Kỷ niệm milestones gain the new ones).
  Map<String, Object?> _edit(
    Membership me,
    MilestoneRecord r, {
    String? name,
    RecordStatus? status,
    DateTime? date,
    String? note,
    List<String>? memoryIds,
  }) => {
    'kind': r.kind.name,
    'referenceId': r.referenceId,
    'source': r.source.name,
    'name': _name(name ?? r.name),
    'status': (status ?? r.status).name,
    'date': (date ?? r.date) == null ? null : isoDateOf(date ?? r.date!),
    'note': _note(note),
    'memoryIds': memoryIds ?? r.memoryIds,
    'updatedBy': me.uid,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static String _name(String s) {
    final t = s.trim();
    return t.length > MilestoneLimits.nameMax
        ? t.substring(0, MilestoneLimits.nameMax).trim()
        : t;
  }

  static String? _note(String? s) {
    final t = s?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.length > MilestoneLimits.noteMax
        ? t.substring(0, MilestoneLimits.noteMax).trim()
        : t;
  }

  @override
  Future<void> observeReference(
    Membership me,
    ReferenceMilestone m, {
    required String name,
    required DateTime date,
    String? note,
    MilestoneRecord? existing,
  }) {
    if (existing != null) {
      return _doc(me.babyId, existing.id).update(
        _edit(
          me,
          existing,
          name: name,
          status: RecordStatus.observed,
          date: date,
          note: note,
        ),
      );
    }
    return _doc(me.babyId, m.recordId).set(
      _new(
        me,
        id: m.recordId,
        kind: RecordKind.reference,
        referenceId: m.id,
        name: name,
        status: RecordStatus.observed,
        date: date,
        note: note,
        source: RecordSource.milestones,
      ),
    );
  }

  @override
  Future<void> follow(
    Membership me,
    ReferenceMilestone m, {
    required String name,
  }) => _doc(me.babyId, m.recordId).set(
    _new(
      me,
      id: m.recordId,
      kind: RecordKind.reference,
      referenceId: m.id,
      name: name,
      status: RecordStatus.following,
      date: null,
      note: null,
      source: RecordSource.milestones,
    ),
  );

  @override
  Future<String> createCustom(
    Membership me, {
    required String name,
    required DateTime date,
    String? note,
    RecordSource source = RecordSource.milestones,
  }) async {
    final id = newMilestoneId();
    await _doc(me.babyId, id).set(
      _new(
        me,
        id: id,
        kind: RecordKind.custom,
        referenceId: null,
        name: name,
        status: RecordStatus.observed,
        date: date,
        note: note,
        source: source,
      ),
    );
    return id;
  }

  @override
  Future<void> edit(
    Membership me,
    MilestoneRecord r, {
    required String name,
    required DateTime date,
    String? note,
  }) => _doc(
    me.babyId,
    r.id,
  ).update(_edit(me, r, name: name, date: date, note: note));

  @override
  Future<void> linkMemory(Membership me, MilestoneRecord r, String memoryId) {
    final ids = [...r.memoryIds.where((m) => m != memoryId), memoryId];
    final kept = ids.length > MilestoneLimits.memoryIdsMax
        ? ids.sublist(ids.length - MilestoneLimits.memoryIdsMax)
        : ids;
    return _doc(
      me.babyId,
      r.id,
    ).update(_edit(me, r, note: r.note, memoryIds: kept));
  }

  @override
  Future<void> remove(String babyId, String recordId) =>
      _doc(babyId, recordId).delete();
}

final milestoneRepositoryProvider = Provider<MilestoneRepository>(
  (ref) => FirestoreMilestoneRepository(ref.watch(firestoreProvider)),
);

final referenceMilestonesProvider = StreamProvider<List<ReferenceMilestone>>(
  (ref) => ref.watch(milestoneRepositoryProvider).watchReference(),
);

final milestoneRecordsProvider =
    StreamProvider.family<List<MilestoneRecord>, String>(
      (ref, babyId) =>
          ref.watch(milestoneRepositoryProvider).watchRecords(babyId),
    );

/// A reference milestone's picture (`content/library/{id}.webp`, public). Tests replace it.
final milestoneImageProvider = Provider<ImageProvider Function(String id)>((
  ref,
) {
  return (id) {
    final bucket = FirebaseStorage.instance.bucket;
    return NetworkImage(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
      '${Uri.encodeComponent('content/library/$id.webp')}?alt=media',
    );
  };
});

/// Photos picked in 3c / 3g, kept on this phone until "Tạo kỷ niệm" sends them to Kỷ niệm
/// (3d shows them meanwhile). Keyed by record id; never uploaded on their own.
final pendingMilestonePhotosProvider =
    NotifierProvider<PendingMilestonePhotos, Map<String, List<PickedMedia>>>(
      PendingMilestonePhotos.new,
    );

class PendingMilestonePhotos extends Notifier<Map<String, List<PickedMedia>>> {
  @override
  Map<String, List<PickedMedia>> build() => const {};

  void set(String recordId, List<PickedMedia> photos) =>
      state = {...state, recordId: photos};

  void clear(String recordId) => state = {...state}..remove(recordId);
}
