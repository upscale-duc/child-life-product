import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/milestones/milestone_models.dart';
import 'package:child_life/features/milestones/milestone_repository.dart';

/// Mốc phát triển without Firebase: the seed published as the portal would (engineering draft,
/// `review: null`), and the baby's records in memory.

/// `content/milestones/milestones.seed.json`, every item published.
List<ReferenceMilestone> seedMilestones() {
  final seed =
      jsonDecode(
            File(
              '../../content/milestones/milestones.seed.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return sortReference([
    for (final m in (seed['milestones']! as List).cast<Map<String, Object?>>())
      ?ReferenceMilestone.fromJson(m['id']! as String, {
        ...m,
        'status': 'published',
        'review': null,
        'illustrative': true,
      }),
  ]);
}

MilestoneRecord observed(
  String id,
  String name,
  DateTime date, {
  String? note,
  List<String> memoryIds = const [],
  CareAuthor author = const CareAuthor(name: 'Mai', relation: Relation.mother),
  String createdBy = 'u_mai',
}) => MilestoneRecord(
  id: id,
  kind: id.startsWith('p_') ? RecordKind.reference : RecordKind.custom,
  referenceId: id.startsWith('p_') ? id.substring(2) : null,
  name: name,
  status: RecordStatus.observed,
  date: date,
  note: note,
  memoryIds: memoryIds,
  source: RecordSource.milestones,
  author: author,
  createdBy: createdBy,
);

/// 3a as drawn: "Nhìn theo mặt người" (05/10) and "Lần đầu tắm cùng ba" (01/10).
List<MilestoneRecord> drawnRecords() => [
  observed('p_follows_faces', 'Nhìn theo mặt người', DateTime(2026, 10, 5)),
  observed(
    'ms_${'1' * 32}',
    'Lần đầu tắm cùng ba',
    DateTime(2026, 10, 1),
    author: const CareAuthor(name: 'Tuấn', relation: Relation.father),
    createdBy: 'u_tuan',
  ),
];

class FakeMilestoneRepository implements MilestoneRepository {
  FakeMilestoneRepository({
    List<ReferenceMilestone>? reference,
    List<MilestoneRecord> records = const [],
  }) : reference = reference ?? seedMilestones(),
       _records = [...records];

  final List<ReferenceMilestone> reference;
  final List<MilestoneRecord> _records;
  final _changes = StreamController<List<MilestoneRecord>>.broadcast();

  /// What the screens wrote, in order ("observe p_x", "follow p_x", …).
  final writes = <String>[];
  var _seq = 0;

  List<MilestoneRecord> get records => List.unmodifiable(_records);

  void _set(MilestoneRecord r) {
    _records
      ..removeWhere((x) => x.id == r.id)
      ..add(r);
    _changes.add(records);
  }

  @override
  Stream<List<ReferenceMilestone>> watchReference() => Stream.value(reference);

  @override
  Stream<List<MilestoneRecord>> watchRecords(String babyId) async* {
    yield records;
    yield* _changes.stream;
  }

  MilestoneRecord _of(
    Membership me,
    String id, {
    required String name,
    required RecordStatus status,
    DateTime? date,
    String? note,
    List<String> memoryIds = const [],
  }) => MilestoneRecord(
    id: id,
    kind: id.startsWith('p_') ? RecordKind.reference : RecordKind.custom,
    referenceId: id.startsWith('p_') ? id.substring(2) : null,
    name: name,
    status: status,
    date: date,
    note: note == null || note.trim().isEmpty ? null : note.trim(),
    memoryIds: memoryIds,
    source: RecordSource.milestones,
    author: CareAuthor.of(me),
    createdBy: me.uid,
  );

  @override
  Future<void> observeReference(
    Membership me,
    ReferenceMilestone m, {
    required String name,
    required DateTime date,
    String? note,
    MilestoneRecord? existing,
  }) async {
    writes.add('observe ${m.recordId}');
    _set(
      _of(
        me,
        m.recordId,
        name: name,
        status: RecordStatus.observed,
        date: date,
        note: note,
        memoryIds: existing?.memoryIds ?? const [],
      ),
    );
  }

  @override
  Future<void> follow(
    Membership me,
    ReferenceMilestone m, {
    required String name,
  }) async {
    writes.add('follow ${m.recordId}');
    _set(_of(me, m.recordId, name: name, status: RecordStatus.following));
  }

  @override
  Future<String> createCustom(
    Membership me, {
    required String name,
    required DateTime date,
    String? note,
    RecordSource source = RecordSource.milestones,
  }) async {
    final id = 'ms_${(++_seq).toRadixString(16).padLeft(32, '0')}';
    writes.add('custom $id');
    _set(
      _of(
        me,
        id,
        name: name,
        status: RecordStatus.observed,
        date: date,
        note: note,
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
  }) async {
    writes.add('edit ${r.id}');
    _set(
      _of(
        me,
        r.id,
        name: name,
        status: RecordStatus.observed,
        date: date,
        note: note,
        memoryIds: r.memoryIds,
      ),
    );
  }

  @override
  Future<void> linkMemory(
    Membership me,
    MilestoneRecord r,
    String memoryId,
  ) async {
    writes.add('link ${r.id} $memoryId');
    final current = _records.where((x) => x.id == r.id).firstOrNull ?? r;
    _set(
      _of(
        me,
        r.id,
        name: current.name,
        status: current.status,
        date: current.date,
        note: current.note,
        memoryIds: [...current.memoryIds, memoryId],
      ),
    );
  }

  @override
  Future<void> remove(String babyId, String recordId) async {
    writes.add('remove $recordId');
    _records.removeWhere((x) => x.id == recordId);
    _changes.add(records);
  }
}
