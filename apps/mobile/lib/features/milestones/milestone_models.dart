import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../care/care_models.dart';
import '../memories/memory_models.dart';

/// Mốc phát triển (Figma v1.1 3a–3g, portal B07 / B08; D-076 #6). Mirrors
/// `packages/contracts/src/milestones.ts`: published reference milestones from
/// `contentMilestones/{id}` and the baby's records in `babies/{b}/milestones/{id}`, the same
/// collection as Kỷ niệm's family milestones (R-105). A reference milestone's record is
/// `p_<referenceId>`; a custom one is `ms_<hex>`.

/// `contentEmergencyToken` (same as the library's `lbEmergencyToken`).
const _emergencyToken = '{emergency}';

/// "Vận động", "Giao tiếp", "Nhận thức", "Cảm xúc – xã hội".
enum MilestoneGroup {
  motor('motor'),
  communication('communication'),
  cognitive('cognitive'),
  socialEmotional('socialEmotional');

  const MilestoneGroup(this.wire);
  final String wire;

  static MilestoneGroup? fromWire(Object? w) =>
      values.where((g) => g.wire == w).firstOrNull;
}

/// The contract's limits (`milestoneLimits`).
abstract final class MilestoneLimits {
  static const nameMax = 60;
  static const noteMax = 500;
  static const memoryIdsMax = 20;
  static const lookAheadDays = 42;
}

enum AgeUnit { weeks, months }

/// "tham khảo 1–3 tháng", both ends inclusive, from the date of birth.
@immutable
class MilestoneAgeRange {
  const MilestoneAgeRange(this.unit, this.from, this.to);
  final AgeUnit unit;
  final int from;
  final int to;

  static MilestoneAgeRange? fromJson(Object? j) {
    if (j is! Map) return null;
    final unit = switch (j['unit']) {
      'weeks' => AgeUnit.weeks,
      'months' => AgeUnit.months,
      _ => null,
    };
    final from = j['from'], to = j['to'];
    if (unit == null || from is! num || to is! num || to < from) return null;
    return MilestoneAgeRange(unit, from.toInt(), to.toInt());
  }

  /// The calendar window for a baby born on [dob] (contracts `milestoneWindow`).
  ({DateTime start, DateTime end}) windowFor(DateTime dob) {
    final b = DateTime(dob.year, dob.month, dob.day);
    if (unit == AgeUnit.weeks) {
      return (
        start: DateTime(b.year, b.month, b.day + from * 7),
        end: DateTime(b.year, b.month, b.day + to * 7 + 6),
      );
    }
    return (
      start: addMonths(b, from),
      end: addMonths(b, to + 1).subtract(const Duration(days: 1)),
    );
  }

  /// The typical age of this range in days, for sorting.
  int get midDays => unit == AgeUnit.weeks
      ? ((from + to) * 7 / 2).round()
      : ((from + to) * 30.44 / 2).round();
}

/// [d] + [months] calendar months; 31 Jan + 1 = 28/29 Feb.
DateTime addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, d.day > last ? last : d.day);
}

/// `{vi, en}`, read in the app's language (Vietnamese when the language has none).
@immutable
class MtText {
  const MtText(this.vi, this.en);
  final String vi;
  final String en;

  String of(String languageCode) => languageCode == 'en' ? en : vi;

  /// Both languages with [number] in place of every `{emergency}` (D-087).
  MtText withEmergency(String number) => MtText(
    vi.replaceAll(_emergencyToken, number),
    en.replaceAll(_emergencyToken, number),
  );

  static MtText? fromJson(Object? j) {
    if (j is! Map) return null;
    final vi = j['vi'], en = j['en'];
    if (vi is! String || en is! String || vi.trim().isEmpty) return null;
    return MtText(vi, en.trim().isEmpty ? vi : en);
  }
}

/// One published reference milestone (`contentMilestones/{id}`).
@immutable
class ReferenceMilestone {
  const ReferenceMilestone({
    required this.id,
    required this.group,
    required this.order,
    required this.ageRange,
    required this.title,
    required this.howToRecognise,
    this.talkToDoctor,
    this.illustration,
    this.illustrationAlt,
    this.sources = const [],
    this.illustrative = true,
    this.reviewer,
  });

  final String id;
  final MilestoneGroup group;
  final int order;
  final MilestoneAgeRange ageRange;
  final MtText title;
  final MtText howToRecognise;
  final MtText? talkToDoctor;

  /// `content/library/{illustration}.webp`.
  final String? illustration;
  final MtText? illustrationAlt;
  final List<({String label, String url})> sources;

  /// "Nội dung minh hoạ · chờ chuyên môn duyệt" until a qualified review is recorded.
  final bool illustrative;

  /// "{reviewer} · {credential}" once reviewed.
  final String? reviewer;

  /// The baby's record id for this milestone.
  String get recordId => 'p_$id';

  /// The family's emergency number in the texts (D-087, P-166 #1; `contentEmergencyToken`).
  ReferenceMilestone withEmergency(String number) => ReferenceMilestone(
    id: id,
    group: group,
    order: order,
    ageRange: ageRange,
    title: title.withEmergency(number),
    howToRecognise: howToRecognise.withEmergency(number),
    talkToDoctor: talkToDoctor?.withEmergency(number),
    illustration: illustration,
    illustrationAlt: illustrationAlt?.withEmergency(number),
    sources: sources,
    illustrative: illustrative,
    reviewer: reviewer,
  );

  static ReferenceMilestone? fromJson(String id, Map<String, Object?> j) {
    if (j['status'] != 'published') return null;
    final group = MilestoneGroup.fromWire(j['group']);
    final range = MilestoneAgeRange.fromJson(j['ageRange']);
    final title = MtText.fromJson(j['title']);
    final how = MtText.fromJson(j['howToRecognise']);
    if (group == null || range == null || title == null || how == null) {
      return null;
    }
    final ill = j['illustration'];
    final review = j['review'];
    return ReferenceMilestone(
      id: id,
      group: group,
      order: (j['order'] as num?)?.toInt() ?? 0,
      ageRange: range,
      title: title,
      howToRecognise: how,
      talkToDoctor: MtText.fromJson(j['talkToDoctor']),
      illustration: ill is Map && ill['image'] is String
          ? ill['image'] as String
          : null,
      illustrationAlt: ill is Map ? MtText.fromJson(ill['alt']) : null,
      sources: [
        for (final s in (j['sources'] as List? ?? const []))
          if (s is Map && s['label'] is String && s['url'] is String)
            (label: s['label'] as String, url: s['url'] as String),
      ],
      // Unknown is treated as not reviewed.
      illustrative: j['illustrative'] != false || review is! Map,
      reviewer: review is Map && review['reviewer'] is String
          ? [
              review['reviewer'],
              if (review['credential'] is String) review['credential'],
            ].join(' · ')
          : null,
    );
  }
}

enum RecordKind { reference, custom }

enum RecordStatus { observed, following }

/// Where a record was made (contracts `babyMilestoneSources`).
enum RecordSource { memories, milestones, rhythm, keepsakes }

/// One record in `babies/{b}/milestones` (old Kỷ niệm milestones read as custom, observed ones).
@immutable
class MilestoneRecord {
  const MilestoneRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.status,
    required this.author,
    required this.createdBy,
    this.referenceId,
    this.date,
    this.note,
    this.memoryIds = const [],
    this.source = RecordSource.memories,
    this.legacy = false,
  });

  final String id;
  final RecordKind kind;
  final String? referenceId;
  final String name;
  final RecordStatus status;

  /// The day the baby did it (baby's zone); null while following.
  final DateTime? date;
  final String? note;
  final List<String> memoryIds;
  final RecordSource source;
  final String createdBy;
  final CareAuthor author;

  /// Written by Kỷ niệm's "Tạo mốc mới" or MS01 before the new fields existed.
  final bool legacy;

  bool get observed => status == RecordStatus.observed;

  MilestoneRef? get ref =>
      date == null ? null : MilestoneRef(id: id, name: name, date: date!);

  static MilestoneRecord? fromJson(String id, Map<String, Object?> j) {
    final name = j['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final reference = id.startsWith('p_');
    final kind = switch (j['kind']) {
      'reference' => RecordKind.reference,
      'custom' => RecordKind.custom,
      _ => reference ? RecordKind.reference : RecordKind.custom,
    };
    final status = j['status'] == 'following'
        ? RecordStatus.following
        : RecordStatus.observed;
    final date = DateTime.tryParse(j['date'] as String? ?? '');
    if (status == RecordStatus.observed && date == null) return null;
    return MilestoneRecord(
      id: id,
      kind: kind,
      referenceId: kind == RecordKind.reference
          ? (j['referenceId'] as String? ?? id.substring(2))
          : null,
      name: name,
      status: status,
      date: date == null ? null : DateTime(date.year, date.month, date.day),
      note: (j['note'] as String?)?.trim().isEmpty ?? true
          ? null
          : j['note'] as String,
      memoryIds: [
        for (final m in (j['memoryIds'] as List? ?? const []))
          if (m is String) m,
      ],
      source:
          RecordSource.values.asNameMap()[j['source']] ?? RecordSource.memories,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      legacy: !j.containsKey('kind'),
    );
  }

  static MilestoneRecord? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return data == null ? null : fromJson(doc.id, data);
  }
}

/// 3a's states for a reference milestone (contracts `milestoneState`): never "late".
enum MilestoneState { seen, following, now, upcoming, notRecorded }

MilestoneState milestoneState(
  MilestoneRecord? record,
  ({DateTime start, DateTime end})? window,
  DateTime today,
) {
  if (record?.status == RecordStatus.observed) return MilestoneState.seen;
  if (record?.status == RecordStatus.following) {
    return MilestoneState.following;
  }
  if (window == null) return MilestoneState.notRecorded;
  final t = DateTime(today.year, today.month, today.day);
  if (!t.isBefore(window.start) && !t.isAfter(window.end)) {
    return MilestoneState.now;
  }
  final ahead = DateTime(
    t.year,
    t.month,
    t.day + MilestoneLimits.lookAheadDays,
  );
  if (t.isBefore(window.start) && !window.start.isAfter(ahead)) {
    return MilestoneState.upcoming;
  }
  return MilestoneState.notRecorded;
}

/// Reference milestones in list order: by `order`, then the age range, then the id.
List<ReferenceMilestone> sortReference(Iterable<ReferenceMilestone> items) =>
    [...items]..sort((a, b) {
      final o = a.order.compareTo(b.order);
      if (o != 0) return o;
      final m = a.ageRange.midDays.compareTo(b.ageRange.midDays);
      return m != 0 ? m : a.id.compareTo(b.id);
    });
