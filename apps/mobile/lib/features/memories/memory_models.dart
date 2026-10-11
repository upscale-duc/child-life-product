import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import '../care/care_models.dart';

/// Memories (S9, Figma 10a–10o). Mirrors `packages/contracts/src/memories.ts`; the server owns
/// `memories` and `media` (Functions + Rules), the app reads them and asks for changes through
/// callables (ADR-004).

/// "Chỉ ba mẹ" / "Gia đình" (D-001: Gia đình preselected).
enum Audience { parents, family }

enum MediaKind { photo, video }

/// Server states; device-only upload states live in the upload queue.
enum MediaStatus { waitingQuota, uploading, ready, unreadable, cancelled }

String _hex() => const Uuid().v4().replaceAll('-', '');
String newMemoryId() => 'mem_${_hex()}';
String newMediaId() => 'med_${_hex()}';
String newBatchId() => 'bat_${_hex()}';
String newMilestoneId() => 'ms_${_hex()}';

final _isoDate = DateFormat('yyyy-MM-dd');
String isoDateOf(DateTime d) => _isoDate.format(d);

/// "★ Lần đầu cười · 5 thg 10", denormalised on the memory and its items.
@immutable
class MilestoneRef {
  const MilestoneRef({
    required this.id,
    required this.name,
    required this.date,
  });

  final String id;
  final String name;

  /// A calendar date in the baby's zone.
  final DateTime date;

  bool get isPreset => id.startsWith('p_');

  static MilestoneRef? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], date = json['date'];
    if (id is! String || name is! String || date is! String) return null;
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    return MilestoneRef(id: id, name: name, date: parsed);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'date': isoDateOf(date),
  };

  @override
  bool operator ==(Object other) =>
      other is MilestoneRef &&
      other.id == id &&
      other.name == name &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, name, date);
}

@immutable
class MediaPaths {
  const MediaPaths({this.original, this.display, this.thumb, this.poster});
  final String? original;
  final String? display;
  final String? thumb;
  final String? poster;

  static MediaPaths? fromJson(Object? json) {
    if (json is! Map) return null;
    return MediaPaths(
      original: json['original'] as String?,
      display: json['display'] as String?,
      thumb: json['thumb'] as String?,
      poster: json['poster'] as String?,
    );
  }
}

/// One photo or video ("MediaTile 131:860").
@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.babyId,
    required this.memoryId,
    required this.type,
    required this.status,
    required this.audience,
    required this.effectiveAudience,
    required this.captureAt,
    required this.createdBy,
    this.author = const CareAuthor(name: '', relation: Relation.other),
    this.batchId = '',
    this.position = 0,
    this.durationMs,
    this.width,
    this.height,
    this.paths,
    this.milestone,
    this.deleted = false,
    this.deletedAt,
    this.waitingWifi = false,
    this.sizeBytes = 0,
    this.albumIds = const [],
    this.loveCount = 0,
  });

  final String id;
  final String babyId;
  final String memoryId;
  final String batchId;
  final int position;
  final MediaKind type;
  final MediaStatus status;
  final Audience audience;

  /// What relatives go by (D-002, P-035): Gia đình if the item or any of its albums is.
  final Audience effectiveAudience;
  final DateTime captureAt;
  final String createdBy;

  /// "Mẹ đăng" (10f).
  final CareAuthor author;
  final int? durationMs;
  final int? width;
  final int? height;
  final MediaPaths? paths;
  final MilestoneRef? milestone;
  final bool deleted;
  final DateTime? deletedAt;
  final bool waitingWifi;
  final int sizeBytes;
  final List<String> albumIds;

  /// "♥ 4": the whole family's loves (counts for everyone, names for parents).
  final int loveCount;

  bool get isVideo => type == MediaKind.video;
  bool get isReady => status == MediaStatus.ready;
  bool get isPrivate => effectiveAudience == Audience.parents;

  /// Best small picture: the thumbnail, else the display copy, else the poster.
  String? get thumbPath => paths?.thumb ?? paths?.display ?? paths?.poster;

  /// What the viewer shows for a photo, or the poster of a video.
  String? get displayPath => paths?.display ?? paths?.poster ?? paths?.thumb;

  static MediaItem? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    if (j == null) return null;
    final captureAt = dateOf(j['captureAt']);
    final type = MediaKind.values.asNameMap()[j['type']];
    final status = MediaStatus.values.asNameMap()[j['status']];
    if (captureAt == null || type == null || status == null) return null;
    final audience =
        Audience.values.asNameMap()[j['audience']] ?? Audience.parents;
    return MediaItem(
      id: doc.id,
      babyId: j['babyId'] as String? ?? '',
      memoryId: j['memoryId'] as String? ?? '',
      batchId: j['batchId'] as String? ?? '',
      position: (j['position'] as num?)?.toInt() ?? 0,
      type: type,
      status: status,
      audience: audience,
      effectiveAudience:
          Audience.values.asNameMap()[j['effectiveAudience']] ?? audience,
      captureAt: captureAt,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      durationMs: (j['durationMs'] as num?)?.toInt(),
      width: (j['width'] as num?)?.toInt(),
      height: (j['height'] as num?)?.toInt(),
      paths: MediaPaths.fromJson(j['paths']),
      milestone: MilestoneRef.fromJson(j['milestone']),
      deleted: j['deleted'] == true,
      deletedAt: dateOf(j['deletedAt']),
      waitingWifi: j['clientState'] == 'waitingWifi',
      sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
      albumIds: [
        for (final a in (j['albumIds'] as List? ?? const []))
          if (a is String) a,
      ],
      loveCount: (j['loveCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One compose action: caption, milestone, audience and its items ("Entry" cards on 10a).
@immutable
class Memory {
  const Memory({
    required this.id,
    required this.babyId,
    required this.audience,
    required this.occurredAt,
    required this.createdBy,
    required this.author,
    this.caption,
    this.milestone,
    this.mediaIds = const [],
    this.photos = 0,
    this.videos = 0,
    this.published = true,
    this.deleted = false,
    this.loveCount = 0,
  });

  final String id;
  final String babyId;
  final String? caption;
  final Audience audience;
  final DateTime occurredAt;
  final MilestoneRef? milestone;
  final List<String> mediaIds;
  final int photos;
  final int videos;
  final bool published;
  final bool deleted;
  final String createdBy;
  final CareAuthor author;
  final int loveCount;

  bool get isNote => mediaIds.isEmpty;

  static Memory? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    if (j == null) return null;
    final occurredAt = dateOf(j['occurredAt']);
    if (occurredAt == null) return null;
    final counts = j['counts'] is Map ? j['counts'] as Map : const {};
    return Memory(
      id: doc.id,
      babyId: j['babyId'] as String? ?? '',
      caption: j['caption'] as String?,
      audience: Audience.values.asNameMap()[j['audience']] ?? Audience.parents,
      occurredAt: occurredAt,
      milestone: MilestoneRef.fromJson(j['milestone']),
      mediaIds: [
        for (final id in (j['mediaIds'] as List? ?? const []))
          if (id is String) id,
      ],
      photos: (counts['photos'] as num?)?.toInt() ?? 0,
      videos: (counts['videos'] as num?)?.toInt() ?? 0,
      published: j['state'] == 'published',
      deleted: j['deleted'] == true,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      loveCount: (j['loveCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// "Mốc nhà mình đã tạo" (10h3, R-105).
@immutable
class FamilyMilestone {
  const FamilyMilestone({
    required this.id,
    required this.name,
    required this.date,
  });
  final String id;
  final String name;
  final DateTime date;

  MilestoneRef get ref => MilestoneRef(id: id, name: name, date: date);

  static FamilyMilestone? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final j = doc.data();
    final date = DateTime.tryParse(j?['date'] as String? ?? '');
    final name = j?['name'];
    if (date == null || name is! String) return null;
    return FamilyMilestone(id: doc.id, name: name, date: date);
  }
}

/// "Tuần thứ 3" (R-113): week n holds days 7(n−1)…7n−1 after birth; 0 is "before birth".
int ageWeekOf(DateTime dateOfBirth, DateTime day) {
  final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
  final d = DateTime(day.year, day.month, day.day);
  final days = d.difference(dob).inDays;
  return days < 0 ? 0 : days ~/ 7 + 1;
}

/// The calendar days of age-week [week] (1-based).
({DateTime first, DateTime last}) ageWeekRange(DateTime dateOfBirth, int week) {
  final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
  final first = DateTime(dob.year, dob.month, dob.day + 7 * (week - 1));
  return (first: first, last: DateTime(first.year, first.month, first.day + 6));
}

/// "Tháng thứ 2" (v1.0 10b "Tháng tuổi"): month n runs from the n−1th monthly birthday to the
/// day before the nth; 0 is "before birth".
int ageMonthOf(DateTime dateOfBirth, DateTime day) {
  final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
  final d = DateTime(day.year, day.month, day.day);
  if (d.isBefore(dob)) return 0;
  var months = (d.year - dob.year) * 12 + d.month - dob.month;
  if (d.day < dob.day) months -= 1;
  return months + 1;
}

/// The calendar days of age-month [month] (1-based).
({DateTime first, DateTime last}) ageMonthRange(DateTime dateOfBirth, int month) {
  final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
  return (
    first: DateTime(dob.year, dob.month + month - 1, dob.day),
    last: DateTime(dob.year, dob.month + month, dob.day - 1),
  );
}

/// Age-based milestone suggestions ("Gợi ý cho bé 3 tuần", 10h3). The first six follow Figma for
/// a newborn; the later ones are engineering suggestions (for design review).
enum PresetMilestone {
  firstSmile('p_first_smile', 0, 12),
  firstBath('p_first_bath', 0, 8),
  liftsHead('p_lifts_head', 0, 16),
  firstOuting('p_first_outing', 0, 12),
  oneMonth('p_one_month', 2, 6),
  meetsGrandparents('p_meets_grandparents', 0, 16),
  rollsOver('p_rolls_over', 8, 30),
  laughs('p_laughs', 8, 26),
  firstSolids('p_first_solids', 20, 40),
  sitsUp('p_sits_up', 20, 44),
  firstTooth('p_first_tooth', 20, 60),
  crawls('p_crawls', 26, 60),
  firstWord('p_first_word', 36, 104),
  firstSteps('p_first_steps', 40, 104),
  firstBirthday('p_first_birthday', 48, 56);

  const PresetMilestone(this.id, this.fromWeek, this.toWeek);
  final String id;
  final int fromWeek;
  final int toWeek;

  static List<PresetMilestone> forAgeWeeks(int weeks) => [
    for (final p in values)
      if (weeks >= p.fromWeek && weeks <= p.toWeek) p,
  ];
}
