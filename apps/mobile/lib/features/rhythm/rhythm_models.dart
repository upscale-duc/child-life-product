import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import '../premium/premium_models.dart' show GateReason;

/// Nhịp lớn lên (Growing Rhythm), Slice 2 (plan `docs/product/premium-personalization-plan.md`
/// §5.4, §7.1; D-072, D-073). Hand-written mirrors of `packages/contracts/src/rhythm.ts` and
/// `personalization.ts`. Every published document and callable answer is parsed tolerantly: an
/// unknown value drops that one item (or falls back), never the whole screen, so an older app
/// keeps working when the server grows. Nothing here is ever logged (no child data in logs).

/// A wire value (`snake_case` on the server).
mixin WireEnum on Enum {
  String get wire;
}

T? wireOf<T extends WireEnum>(List<T> values, Object? v) =>
    values.where((x) => x.wire == v).firstOrNull;

List<T> wireList<T extends WireEnum>(List<T> values, Object? v) => [
  for (final x in (v is List ? v : const []))
    if (wireOf(values, x) case final T t) t,
];

/// C01: one observation, never a default answer (`observations`).
enum Observation with WireEnum {
  sleep('sleep'),
  feeding('feeding'),
  soothing('soothing'),
  newSkill('new_skill'),
  usual('usual'),
  health('health');

  const Observation(this.wire);
  @override
  final String wire;
}

/// NL05b signs, exactly `healthSigns` in rhythm.ts; any "Có" routes to HL01 (no paywall, no AI).
enum HealthSign with WireEnum {
  feverYoung('fever_young'),
  breathing('breathing'),
  lethargic('lethargic'),
  poorFeeding('poor_feeding'),
  inconsolable('inconsolable'),
  lostSkill('lost_skill'),
  dehydration('dehydration'),
  seizure('seizure');

  const HealthSign(this.wire);
  @override
  final String wire;
}

/// C02 "Đã thử gì chưa?" (`triedSoothing`).
enum Tried with WireEnum {
  rocking('rocking'),
  whiteNoise('white_noise'),
  feeding('feeding'),
  skinToSkin('skin_to_skin'),
  swaddle('swaddle'),
  none('none');

  const Tried(this.wire);
  @override
  final String wire;
}

/// C02 "Khi nào?".
enum CheckInWhen with WireEnum {
  night('night'),
  day('day'),
  both('both');

  const CheckInWhen(this.wire);
  @override
  final String wire;
}

/// C02 "Từ bao giờ?".
enum CheckInSince with WireEnum {
  today('today'),
  days2to3('days_2_3'),
  longer('longer');

  const CheckInSince(this.wire);
  @override
  final String wire;
}

/// AC01 / AC02 / H02 / PS01 feedback (`feedbackKinds`).
enum FeedbackKind with WireEnum {
  /// "Mình sẽ thử" / "Thử tối nay" / "Thử hôm nay".
  started('started'),
  helpful('helpful'),
  unsure('unsure'),

  /// "Không phù hợp với con": excluded for this baby until reset.
  notSuitable('not_suitable'),

  /// "Không phải hôm nay" / "Để sau" / "Gợi ý khác": cooldown only.
  notToday('not_today');

  const FeedbackKind(this.wire);
  @override
  final String wire;
}

/// Why a suggestion was chosen (`reasonCodes`); drawn as the "Vì …" line.
enum ReasonCode with WireEnum {
  selfReportedNeed('SELF_REPORTED_NEED'),
  dataInsight('DATA_INSIGHT'),
  previousHelpful('PREVIOUS_HELPFUL'),
  ageContent('AGE_CONTENT'),
  interest('INTEREST');

  const ReasonCode(this.wire);
  @override
  final String wire;
}

/// PS02 "Đã thay đổi".
enum RecChange with WireEnum {
  prefersHelpful('prefers_helpful'),
  excludedNotSuitable('excluded_not_suitable'),
  coolingDown('cooling_down');

  const RecChange(this.wire);
  @override
  final String wire;
}

enum RecState with WireEnum {
  suggested('suggested'),
  started('started'),
  done('done'),
  dismissed('dismissed');

  const RecState(this.wire);
  @override
  final String wire;
}

/// `nextAction` / `composeHome` outcome.
enum AnswerState with WireEnum {
  normal('normal'),
  health('health'),
  suggestion('suggestion'),
  freeContent('free_content'),
  noSuggestion('no_suggestion');

  const AnswerState(this.wire);
  @override
  final String wire;
}

/// Content tags for the current need (`needs`).
enum Need with WireEnum {
  sleep('sleep'),
  feeding('feeding'),
  soothing('soothing'),
  play('play'),
  milestone('milestone'),
  bonding('bonding');

  const Need(this.wire);
  @override
  final String wire;
}

/// EN01 "điều bạn quan tâm" (`interests`).
enum Interest with WireEnum {
  sleep('sleep'),
  feeding('feeding'),
  milestones('milestones'),
  vaccines('vaccines'),
  nutrition('nutrition'),
  moments('moments');

  const Interest(this.wire);
  @override
  final String wire;
}

/// Best time of day for an activity: "Thử tối nay" vs "Thử hôm nay".
enum ActivityTime with WireEnum {
  any('any'),
  evening('evening'),
  day('day');

  const ActivityTime(this.wire);
  @override
  final String wire;
}

enum ContentStatus with WireEnum {
  draft('draft'),
  published('published'),
  retired('retired');

  const ContentStatus(this.wire);
  @override
  final String wire;
}

enum SleepStatus with WireEnum {
  insufficientData('insufficient_data'),
  changeDetected('change_detected'),
  noChange('no_change');

  const SleepStatus(this.wire);
  @override
  final String wire;
}

/// `needOf` in personalization.ts.
Need? needOf(Observation o) => switch (o) {
  Observation.sleep => Need.sleep,
  Observation.feeding => Need.feeding,
  Observation.soothing => Need.soothing,
  Observation.newSkill => Need.milestone,
  Observation.usual || Observation.health => null,
};

// ---------- Small parsing helpers ----------

String? _str(Object? v, {int max = 4000}) =>
    v is String && v.isNotEmpty && v.length <= max ? v : null;

int? _int(Object? v) => v is num && v == v.roundToDouble() ? v.toInt() : null;

Map<String, Object?> _map(Object? v) =>
    v is Map ? v.cast<String, Object?>() : const {};

List<Object?> _list(Object? v) => v is List ? v : const [];

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
String? _date(Object? v) => v is String && _isoDate.hasMatch(v) ? v : null;

/// `{vi, en}`; shown in the app's language, the other one as a fallback.
@immutable
class Localized {
  const Localized(this.vi, this.en);
  final String vi;
  final String en;

  String of(Locale locale) => locale.languageCode == 'en' ? en : vi;

  static Localized? fromJson(Object? json) {
    final m = _map(json);
    final vi = _str(m['vi']);
    final en = _str(m['en']);
    if (vi == null && en == null) return null;
    return Localized(vi ?? en!, en ?? vi!);
  }

  Map<String, String> toJson() => {'vi': vi, 'en': en};
}

@immutable
class LocalizedList {
  const LocalizedList(this.vi, this.en);
  final List<String> vi;
  final List<String> en;

  static const empty = LocalizedList([], []);

  List<String> of(Locale locale) => locale.languageCode == 'en'
      ? (en.isEmpty ? vi : en)
      : (vi.isEmpty ? en : vi);

  static LocalizedList fromJson(Object? json) {
    final m = _map(json);
    List<String> items(Object? v) => [
      for (final s in _list(v))
        if (_str(s, max: 400) case final String t) t,
    ];
    return LocalizedList(items(m['vi']), items(m['en']));
  }
}

/// Who signed the content off; null = engineering draft, "Nội dung minh hoạ · chờ chuyên môn
/// duyệt" (D-073 #2).
@immutable
class ContentReview {
  const ContentReview({
    required this.reviewer,
    required this.credential,
    required this.reviewedOn,
  });
  final String reviewer;
  final String credential;
  final String reviewedOn;

  static ContentReview? fromJson(Object? json) {
    final m = _map(json);
    final reviewer = _str(m['reviewer']);
    final credential = _str(m['credential']);
    final on = _date(m['reviewedOn']);
    if (reviewer == null || credential == null || on == null) return null;
    return ContentReview(
      reviewer: reviewer,
      credential: credential,
      reviewedOn: on,
    );
  }
}

@immutable
class ContentSource {
  const ContentSource(this.label, this.url);
  final String label;
  final String url;

  static List<ContentSource> listOf(Object? json) => [
    for (final s in _list(json))
      if ((_str(_map(s)['label']), _str(_map(s)['url'])) case (
        final String label,
        final String url,
      ))
        ContentSource(label, url),
  ];
}

@immutable
class AgeRange {
  const AgeRange(this.from, this.to);
  final int from;
  final int to;

  bool holds(int ageDays) => ageDays >= from && ageDays <= to;

  static AgeRange? fromJson(Object? json) {
    final m = _map(json);
    final from = _int(m['from']);
    final to = _int(m['to']);
    if (from == null || to == null || from < 0 || to < from) return null;
    return AgeRange(from, to);
  }
}

// ---------- Due date (NL02b) ----------

/// `babies/{b}/restricted/profile.dueDate` (`dueDateSchema`). "Ước tính" stays on the label when
/// [estimated]; never silently replaced by the birth date (brief p.13).
@immutable
class DueDate {
  const DueDate({
    required this.date,
    required this.estimated,
    this.gestationWeeks,
    this.gestationDays,
  });

  /// YYYY-MM-DD.
  final String date;
  final bool estimated;
  final int? gestationWeeks;
  final int? gestationDays;

  static DueDate? fromJson(Object? json) {
    final m = _map(json);
    final date = _date(m['date']);
    if (date == null) return null;
    final g = _map(m['gestation']);
    final weeks = _int(g['weeks']);
    final days = _int(g['days']);
    final validGestation =
        weeks != null &&
        weeks >= 22 &&
        weeks <= 44 &&
        days != null &&
        days >= 0 &&
        days <= 6;
    return DueDate(
      date: date,
      estimated: m['estimated'] == true,
      gestationWeeks: validGestation ? weeks : null,
      gestationDays: validGestation ? days : null,
    );
  }

  Map<String, Object?> toJson() => {
    'date': date,
    'estimated': estimated,
    'gestation': gestationWeeks == null
        ? null
        : {'weeks': gestationWeeks, 'days': gestationDays ?? 0},
  };

  @override
  bool operator ==(Object other) =>
      other is DueDate &&
      other.date == date &&
      other.estimated == estimated &&
      other.gestationWeeks == gestationWeeks &&
      other.gestationDays == gestationDays;

  @override
  int get hashCode =>
      Object.hash(date, estimated, gestationWeeks, gestationDays);
}

/// What Nhịp lớn lên reads from the restricted profile: Cùng nuôi and relatives with "Thông tin
/// bé" only (Rules); everyone else never asks for it.
@immutable
class RhythmProfile {
  const RhythmProfile({this.dateOfBirth, this.dueDate});
  final DateTime? dateOfBirth;
  final DueDate? dueDate;

  static RhythmProfile fromJson(Map<String, Object?>? json) {
    final m = json ?? const {};
    final dob = _date(m['dateOfBirth']);
    return RhythmProfile(
      dateOfBirth: dob == null ? null : DateTime.tryParse(dob),
      dueDate: DueDate.fromJson(m['dueDate']),
    );
  }
}

// ---------- Reference calendar (NL03, NL04) ----------

final _stageId = RegExp(r'^[a-z0-9_-]{2,40}$');

@immutable
class ReferenceStage {
  const ReferenceStage({
    required this.id,
    required this.number,
    required this.startOffsetDays,
    required this.endOffsetDays,
    required this.name,
    this.signs = LocalizedList.empty,
    this.skills = LocalizedList.empty,
    this.activityIds = const [],
    this.noticeTitle,
    this.noticeBody,
  });

  final String id;
  final int number;

  /// Days after the due date, inclusive on both ends.
  final int startOffsetDays;
  final int endOffsetDays;
  final Localized name;

  /// "Dấu hiệu có thể gặp": possible, never certain.
  final LocalizedList signs;

  /// "Kỹ năng tham khảo theo tuổi".
  final LocalizedList skills;
  final List<String> activityIds;
  final Localized? noticeTitle;
  final Localized? noticeBody;

  static ReferenceStage? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id']);
    final number = _int(m['number']);
    final start = _int(m['startOffsetDays']);
    final end = _int(m['endOffsetDays']);
    final name = Localized.fromJson(m['name']);
    if (id == null ||
        !_stageId.hasMatch(id) ||
        number == null ||
        start == null ||
        end == null ||
        start < 0 ||
        end < start ||
        name == null) {
      return null;
    }
    final notice = _map(m['notice']);
    return ReferenceStage(
      id: id,
      number: number,
      startOffsetDays: start,
      endOffsetDays: end,
      name: name,
      signs: LocalizedList.fromJson(m['signs']),
      skills: LocalizedList.fromJson(m['skills']),
      activityIds: [
        for (final a in _list(m['activityIds']))
          if (_str(a, max: 60) case final String s) s,
      ],
      noticeTitle: Localized.fromJson(notice['title']),
      noticeBody: Localized.fromJson(notice['body']),
    );
  }
}

/// `publicConfig/rhythm_reference` (PN01): one published version at a time.
@immutable
class ReferenceModel {
  const ReferenceModel({
    required this.version,
    required this.label,
    required this.stages,
    this.sources = const [],
    this.review,
    this.publishedAt,
  });

  final String version;

  /// e.g. "Wonder Weeks": a reference, never a partner (D-072 #7).
  final String label;
  final List<ReferenceStage> stages;
  final List<ContentSource> sources;
  final ContentReview? review;
  final String? publishedAt;

  static ReferenceModel? fromJson(Object? json) {
    final m = _map(json);
    final version = _str(m['version']);
    final stages = [
      for (final s in _list(m['stages'])) ?ReferenceStage.fromJson(s),
    ];
    if (version == null || stages.isEmpty) return null;
    return ReferenceModel(
      version: version,
      label: _str(m['label']) ?? '',
      stages: stages,
      sources: ContentSource.listOf(m['sources']),
      review: ContentReview.fromJson(m['review']),
      publishedAt: _str(m['publishedAt']),
    );
  }
}

// ---------- Content (PN03, R0) ----------

final _activityId = RegExp(r'^act_[a-z0-9_]{2,40}$');
final _ageCardId = RegExp(r'^age_[a-z0-9_]{2,40}$');

/// One suggested activity (AC01): steps, age, needs, safety, sources, review.
@immutable
class Activity {
  const Activity({
    required this.id,
    required this.version,
    required this.status,
    required this.title,
    required this.summary,
    required this.steps,
    required this.durationMin,
    required this.ageDays,
    required this.needs,
    this.safety,
    this.interests = const [],
    this.timeOfDay = ActivityTime.any,
    this.locales = const ['vi', 'en'],
    this.regions = const [],
    this.sources = const [],
    this.review,
  });

  final String id;
  final int version;
  final ContentStatus status;
  final Localized title;
  final Localized summary;
  final LocalizedList steps;

  /// "Không khi…".
  final Localized? safety;
  final int durationMin;
  final AgeRange ageDays;
  final List<Need> needs;
  final List<Interest> interests;
  final ActivityTime timeOfDay;
  final List<String> locales;
  final List<String> regions;
  final List<ContentSource> sources;
  final ContentReview? review;

  static Activity? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id']);
    final version = _int(m['version']);
    final title = Localized.fromJson(m['title']);
    final age = AgeRange.fromJson(m['ageDays']);
    final duration = _int(m['durationMin']);
    final needs = wireList(Need.values, m['needs']);
    if (id == null ||
        !_activityId.hasMatch(id) ||
        version == null ||
        title == null ||
        age == null ||
        duration == null ||
        needs.isEmpty) {
      return null;
    }
    return Activity(
      id: id,
      version: version,
      status: wireOf(ContentStatus.values, m['status']) ?? ContentStatus.draft,
      title: title,
      summary: Localized.fromJson(m['summary']) ?? title,
      steps: LocalizedList.fromJson(m['steps']),
      safety: Localized.fromJson(m['safety']),
      durationMin: duration,
      ageDays: age,
      needs: needs,
      interests: wireList(Interest.values, m['interests']),
      timeOfDay:
          wireOf(ActivityTime.values, m['timeOfDay']) ?? ActivityTime.any,
      locales: [
        for (final l in _list(m['locales']))
          if (l == 'vi' || l == 'en') l as String,
      ],
      regions: [
        for (final r in _list(m['regions']))
          if (r is String && RegExp(r'^[A-Z]{2}$').hasMatch(r)) r,
      ],
      sources: ContentSource.listOf(m['sources']),
      review: ContentReview.fromJson(m['review']),
    );
  }
}

/// "Tuần này của {bé}" (Q-067): one free card per week of age, then per month.
@immutable
class AgeCard {
  const AgeCard({
    required this.id,
    required this.version,
    required this.status,
    required this.ageDays,
    required this.title,
    required this.body,
    this.tips = LocalizedList.empty,
    this.watchFor = LocalizedList.empty,
    this.interests = const [],
    this.sources = const [],
    this.review,
  });

  final String id;
  final int version;
  final ContentStatus status;

  /// Actual age from the date of birth, never the corrected one (brief p.13).
  final AgeRange ageDays;
  final Localized title;
  final Localized body;
  final LocalizedList tips;

  /// When to ask a doctor at this age.
  final LocalizedList watchFor;
  final List<Interest> interests;
  final List<ContentSource> sources;
  final ContentReview? review;

  static AgeCard? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id']);
    final version = _int(m['version']);
    final age = AgeRange.fromJson(m['ageDays']);
    final title = Localized.fromJson(m['title']);
    final body = Localized.fromJson(m['body']);
    if (id == null ||
        !_ageCardId.hasMatch(id) ||
        version == null ||
        age == null ||
        title == null ||
        body == null) {
      return null;
    }
    return AgeCard(
      id: id,
      version: version,
      status: wireOf(ContentStatus.values, m['status']) ?? ContentStatus.draft,
      ageDays: age,
      title: title,
      body: body,
      tips: LocalizedList.fromJson(m['tips']),
      watchFor: LocalizedList.fromJson(m['watchFor']),
      interests: wireList(Interest.values, m['interests']),
      sources: ContentSource.listOf(m['sources']),
      review: ContentReview.fromJson(m['review']),
    );
  }
}

/// A sign as published (NL05b); only ids the check-in can store are kept.
@immutable
class HealthSignContent {
  const HealthSignContent({
    required this.sign,
    required this.label,
    this.maxAgeDays,
  });
  final HealthSign sign;
  final Localized label;

  /// Shown only below this age (e.g. fever under 3 months); null = any age.
  final int? maxAgeDays;
}

/// HL01 health routing, free in every plan state. Emergency numbers come only from [regions]: a
/// country without an entry shows "Gọi bác sĩ của bé", never a default hotline.
@immutable
class HealthPack {
  const HealthPack({
    required this.signs,
    this.whileWaiting = LocalizedList.empty,
    this.disclaimer,
    this.regions = const {},
    this.sources = const [],
    this.review,
  });

  final List<HealthSignContent> signs;
  final LocalizedList whileWaiting;
  final Localized? disclaimer;

  /// Country (ISO 3166) → emergency number.
  final Map<String, String> regions;
  final List<ContentSource> sources;
  final ContentReview? review;

  String? emergencyNumberFor(String? country) =>
      country == null ? null : regions[country];

  static HealthPack? fromJson(Object? json) {
    final m = _map(json);
    if (m.isEmpty) return null;
    final signs = <HealthSignContent>[];
    for (final s in _list(m['signs'])) {
      final sm = _map(s);
      final sign = wireOf(HealthSign.values, sm['id']);
      final label = Localized.fromJson(sm['label']);
      if (sign == null || label == null) continue;
      signs.add(
        HealthSignContent(
          sign: sign,
          label: label,
          maxAgeDays: _int(sm['maxAgeDays']),
        ),
      );
    }
    return HealthPack(
      signs: signs,
      whileWaiting: LocalizedList.fromJson(m['whileWaiting']),
      disclaimer: Localized.fromJson(m['disclaimer']),
      regions: {
        for (final r in _list(m['regions']))
          if ((_str(_map(r)['country']), _str(_map(r)['emergencyNumber']))
              case (final String c, final String n)
              when RegExp(r'^[A-Z]{2}$').hasMatch(c) &&
                  RegExp(r'^[0-9]{2,4}$').hasMatch(n))
            c: n,
      },
      sources: ContentSource.listOf(m['sources']),
      review: ContentReview.fromJson(m['review']),
    );
  }
}

/// `publicConfig/content_rhythm`: activities, age cards and health routing, one version.
@immutable
class RhythmContent {
  const RhythmContent({
    required this.version,
    this.activities = const [],
    this.ageCards = const [],
    this.health,
    this.publishedAt,
  });

  final String version;
  final List<Activity> activities;
  final List<AgeCard> ageCards;
  final HealthPack? health;
  final String? publishedAt;

  Activity? activity(String id) =>
      activities.where((a) => a.id == id).firstOrNull;
  AgeCard? ageCard(String id) => ageCards.where((a) => a.id == id).firstOrNull;

  static RhythmContent? fromJson(Object? json) {
    final m = _map(json);
    final version = _str(m['version']);
    if (version == null) return null;
    return RhythmContent(
      version: version,
      activities: [
        for (final a in _list(m['activities'])) ?Activity.fromJson(a),
      ],
      ageCards: [for (final a in _list(m['ageCards'])) ?AgeCard.fromJson(a)],
      health: HealthPack.fromJson(m['health']),
      publishedAt: _str(m['publishedAt']),
    );
  }
}

// ---------- Check-ins and feedback (written by the phone) ----------

final _checkInId = RegExp(r'^ci_[a-f0-9]{32}$');
final _feedbackId = RegExp(r'^fb_[a-f0-9]{32}$');

bool isCheckInId(String id) => _checkInId.hasMatch(id);
bool isFeedbackId(String id) => _feedbackId.hasMatch(id);

/// `babies/{b}/checkins/{ci_<32 hex>}` (`checkInSchema`): one per author per observation per
/// day; edits bump [revision]. The id is the idempotency key.
@immutable
class CheckIn {
  const CheckIn({
    required this.id,
    required this.babyId,
    required this.date,
    required this.authorUid,
    required this.observation,
    this.when,
    this.since,
    this.tried = const [],
    this.healthSigns = const [],
    this.note,
    this.revision = 1,
    this.pending = false,
  });

  final String id;
  final String babyId;

  /// Baby-local date the observation is about (YYYY-MM-DD).
  final String date;
  final String authorUid;
  final Observation observation;
  final CheckInWhen? when;
  final CheckInSince? since;
  final List<Tried> tried;

  /// NL05b: only the signs answered "Có".
  final List<HealthSign> healthSigns;

  /// Free text: untrusted data, never instructions; never logged.
  final String? note;
  final int revision;

  /// Still queued on this phone (not yet on the server).
  final bool pending;

  static const noteMaxLength = 500;

  /// `checkInState`: "Như mọi ngày" is normal, anything else a change.
  bool get changed => observation != Observation.usual;

  /// `needsHealthSupport`: the health route wins over everything.
  bool get needsHealthSupport => healthSigns.isNotEmpty;

  CheckIn copyWith({
    Observation? observation,
    CheckInWhen? Function()? when,
    CheckInSince? Function()? since,
    List<Tried>? tried,
    List<HealthSign>? healthSigns,
    String? Function()? note,
    int? revision,
  }) => CheckIn(
    id: id,
    babyId: babyId,
    date: date,
    authorUid: authorUid,
    observation: observation ?? this.observation,
    when: when == null ? this.when : when(),
    since: since == null ? this.since : since(),
    tried: tried ?? this.tried,
    healthSigns: healthSigns ?? this.healthSigns,
    note: note == null ? this.note : note(),
    revision: revision ?? this.revision,
    pending: pending,
  );

  /// Exactly the schema's fields (the repository adds the server timestamps).
  Map<String, Object?> toJson() => {
    'id': id,
    'babyId': babyId,
    'date': date,
    'authorUid': authorUid,
    'observation': observation.wire,
    'when': when?.wire,
    'since': since?.wire,
    'tried': [for (final t in tried) t.wire],
    'healthSigns': [for (final s in healthSigns) s.wire],
    'note': note,
    'revision': revision,
  };

  static CheckIn? fromJson(Map<String, Object?> json, {bool pending = false}) {
    final id = _str(json['id']);
    final babyId = _str(json['babyId']);
    final date = _date(json['date']);
    final author = _str(json['authorUid']);
    final observation = wireOf(Observation.values, json['observation']);
    if (id == null ||
        !isCheckInId(id) ||
        babyId == null ||
        date == null ||
        author == null ||
        observation == null) {
      return null;
    }
    return CheckIn(
      id: id,
      babyId: babyId,
      date: date,
      authorUid: author,
      observation: observation,
      when: wireOf(CheckInWhen.values, json['when']),
      since: wireOf(CheckInSince.values, json['since']),
      tried: wireList(Tried.values, json['tried']),
      healthSigns: wireList(HealthSign.values, json['healthSigns']),
      note: _str(json['note'], max: noteMaxLength),
      revision: _int(json['revision']) ?? 1,
      pending: pending,
    );
  }
}

/// `babies/{b}/recFeedback/{fb_<32 hex>}` (`recFeedbackSchema`): free data; using it in the
/// ranking needs `rhythm.advanced`.
@immutable
class RecFeedback {
  const RecFeedback({
    required this.id,
    required this.babyId,
    required this.authorUid,
    required this.contentId,
    required this.contentVersion,
    required this.kind,
    required this.date,
    this.note,
    this.createdAt,
    this.pending = false,
  });

  final String id;
  final String babyId;
  final String authorUid;
  final String contentId;
  final int contentVersion;
  final FeedbackKind kind;

  /// Baby-local date the feedback is about ("Tối qua thế nào?").
  final String date;
  final String? note;

  /// Server time, null while pending.
  final DateTime? createdAt;
  final bool pending;

  static const noteMaxLength = 300;

  Map<String, Object?> toJson() => {
    'id': id,
    'babyId': babyId,
    'authorUid': authorUid,
    'contentId': contentId,
    'contentVersion': contentVersion,
    'kind': kind.wire,
    'date': date,
    'note': note,
  };

  static RecFeedback? fromJson(
    Map<String, Object?> json, {
    DateTime? createdAt,
    bool pending = false,
  }) {
    final id = _str(json['id']);
    final babyId = _str(json['babyId']);
    final author = _str(json['authorUid']);
    final content = _str(json['contentId'], max: 60);
    final version = _int(json['contentVersion']);
    final kind = wireOf(FeedbackKind.values, json['kind']);
    final date = _date(json['date']);
    if (id == null ||
        !isFeedbackId(id) ||
        babyId == null ||
        author == null ||
        content == null ||
        version == null ||
        kind == null ||
        date == null) {
      return null;
    }
    return RecFeedback(
      id: id,
      babyId: babyId,
      authorUid: author,
      contentId: content,
      contentVersion: version,
      kind: kind,
      date: date,
      note: _str(json['note'], max: noteMaxLength),
      createdAt: createdAt,
      pending: pending,
    );
  }
}

// ---------- Recommendations and callable answers ----------

/// `Recommendation` (H02, PS01, PS02); stored at `babies/{b}/recommendations/{id}` by the server.
@immutable
class Recommendation {
  const Recommendation({
    required this.id,
    required this.contentId,
    required this.contentVersion,
    required this.reasonCode,
    this.supportingIds = const [],
    this.state = RecState.suggested,
    this.changes = const [],
    this.cooldownUntil,
    this.generatedAt,
    this.expiresAt,
    this.sourceRevision,
  });

  final String id;
  final String contentId;
  final int contentVersion;
  final ReasonCode reasonCode;

  /// Check-in / feedback ids the reason rests on (readable links, never "[F1]").
  final List<String> supportingIds;
  final RecState state;

  /// PS02 "Đã thay đổi".
  final List<RecChange> changes;
  final String? cooldownUntil;
  final DateTime? generatedAt;
  final DateTime? expiresAt;
  final int? sourceRevision;

  bool get active => state == RecState.suggested || state == RecState.started;

  /// The check-in the reason rests on, if any.
  String? get checkInId => supportingIds.where(isCheckInId).firstOrNull;

  static Recommendation? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id']);
    final content = _str(m['contentId'], max: 60);
    final version = _int(m['contentVersion']);
    if (id == null || content == null || version == null) return null;
    return Recommendation(
      id: id,
      contentId: content,
      contentVersion: version,
      // An unknown code still explains itself as "from what you noted".
      reasonCode:
          wireOf(ReasonCode.values, m['reasonCode']) ??
          ReasonCode.selfReportedNeed,
      supportingIds: [
        for (final s in _list(m['supportingIds']))
          if (_str(s, max: 128) case final String t) t,
      ],
      state: wireOf(RecState.values, m['state']) ?? RecState.suggested,
      changes: wireList(RecChange.values, m['changes']),
      cooldownUntil: _date(m['cooldownUntil']),
      generatedAt: DateTime.tryParse('${m['generatedAt']}'),
      expiresAt: DateTime.tryParse('${m['expiresAt']}'),
      sourceRevision: _int(m['sourceRevision']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'contentId': contentId,
    'contentVersion': contentVersion,
    'reasonCode': reasonCode.wire,
    'supportingIds': supportingIds,
    'state': state.wire,
    'changes': [for (final c in changes) c.wire],
    'cooldownUntil': cooldownUntil,
    'generatedAt': generatedAt?.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'sourceRevision': sourceRevision,
  };
}

/// "Từ nhật ký": the sleep comparison, when the data allows it (DATA_INSIGHT).
@immutable
class SleepFacts {
  const SleepFacts({
    required this.status,
    this.baseline,
    this.recent,
    this.validDays = 0,
  });
  final SleepStatus status;

  /// Minutes per day (medians).
  final double? baseline;
  final double? recent;
  final int validDays;

  static SleepFacts? fromJson(Object? json) {
    final m = _map(json);
    final status = wireOf(SleepStatus.values, m['status']);
    if (status == null) return null;
    double? n(Object? v) => v is num ? v.toDouble() : null;
    return SleepFacts(
      status: status,
      baseline: n(m['baseline']),
      recent: n(m['recent']),
      validDays: _int(m['validDays']) ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
    'status': status.wire,
    'baseline': baseline,
    'recent': recent,
    'validDays': validDays,
  };
}

/// The feedback a recommendation rests on (PS02 "Tối 08/10 Mẹ chọn Có ích…").
@immutable
class FeedbackRef {
  const FeedbackRef({
    required this.id,
    required this.contentId,
    required this.kind,
    required this.date,
    required this.authorUid,
  });
  final String id;
  final String contentId;
  final FeedbackKind kind;
  final String date;
  final String authorUid;

  static FeedbackRef? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id']);
    final content = _str(m['contentId'], max: 60);
    final kind = wireOf(FeedbackKind.values, m['kind']);
    final date = _date(m['date']);
    final author = _str(m['authorUid']);
    if (id == null ||
        content == null ||
        kind == null ||
        date == null ||
        author == null) {
      return null;
    }
    return FeedbackRef(
      id: id,
      contentId: content,
      kind: kind,
      date: date,
      authorUid: author,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'contentId': contentId,
    'kind': kind.wire,
    'date': date,
    'authorUid': authorUid,
  };
}

/// `nextAction` (PS01 / PS01F / HL01). `gate` explains why only the free result came back; the
/// free path never disappears, and only [GateReason.premiumRequired] may lead to the plan.
@immutable
class NextActionAnswer {
  const NextActionAnswer({
    required this.state,
    this.recommendation,
    this.secondary = const [],
    this.ageCardId,
    this.gate,
    this.sleep,
  });

  final AnswerState state;
  final Recommendation? recommendation;

  /// ≤2 other activities: (contentId, contentVersion).
  final List<(String, int)> secondary;
  final String? ageCardId;

  /// The raw reason code (`PREMIUM_REQUIRED`, `REGION_UNAVAILABLE`…).
  final String? gate;
  final SleepFacts? sleep;

  GateReason? get gateReason => GateReason.fromWire(gate);

  /// Anything unreadable is "no suggestion", never a crash or an unlock.
  static NextActionAnswer fromJson(Object? json) {
    final m = _map(json);
    final rec = Recommendation.fromJson(m['recommendation']);
    var state =
        wireOf(AnswerState.values, m['state']) ?? AnswerState.noSuggestion;
    if (state == AnswerState.suggestion && rec == null) {
      state = AnswerState.noSuggestion;
    }
    return NextActionAnswer(
      state: state,
      recommendation: rec,
      secondary: _secondary(m['secondary']),
      ageCardId: _str(m['ageCardId'], max: 60),
      gate: _str(m['gate'], max: 60),
      sleep: SleepFacts.fromJson(m['sleep']),
    );
  }

  Map<String, Object?> toJson() => {
    'state': state.wire,
    'recommendation': recommendation?.toJson(),
    'secondary': [
      for (final (id, v) in secondary) {'contentId': id, 'contentVersion': v},
    ],
    'ageCardId': ageCardId,
    'gate': gate,
    'sleep': sleep?.toJson(),
  };
}

List<(String, int)> _secondary(Object? json) => [
  for (final s in _list(json))
    if ((_str(_map(s)['contentId'], max: 60), _int(_map(s)['contentVersion']))
        case (final String id, final int v))
      (id, v),
];

/// `composeHome` (H02 / PS02): the household's current primary suggestion and the latest
/// feedback behind it (`ComposeHomeAnswer`).
@immutable
class HomeComposition extends NextActionAnswer {
  const HomeComposition({
    required super.state,
    super.recommendation,
    super.secondary,
    super.ageCardId,
    super.gate,
    super.sleep,
    this.lastFeedback,
  });

  final FeedbackRef? lastFeedback;

  static HomeComposition fromJson(Object? json) {
    final a = NextActionAnswer.fromJson(json);
    return HomeComposition(
      state: a.state,
      recommendation: a.recommendation,
      secondary: a.secondary,
      ageCardId: a.ageCardId,
      gate: a.gate,
      sleep: a.sleep,
      lastFeedback: FeedbackRef.fromJson(_map(json)['lastFeedback']),
    );
  }

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'lastFeedback': lastFeedback?.toJson(),
  };
}

// ---------- Preferences (EN01, EN02; per person, free) ----------

final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// `users/{uid}/settings/personalization` (`userPreferencesSchema`): per person, never a
/// household fact.
@immutable
class UserPreferences {
  const UserPreferences({
    this.interests = const [],
    this.digestTime,
    this.quietFrom = '22:00',
    this.quietTo = '06:00',
    this.fewer = const [],
    this.updatedAt,
  });

  final List<Interest> interests;

  /// "HH:mm" local; null = no digest.
  final String? digestTime;

  /// Quiet hours for suggestions only; both null = none.
  final String? quietFrom;
  final String? quietTo;

  /// "Ít gợi ý kiểu này hơn" (EN05); free forever.
  final List<Interest> fewer;
  final String? updatedAt;

  static const defaults = UserPreferences();

  static UserPreferences fromJson(Object? json) {
    final m = _map(json);
    if (m.isEmpty) return defaults;
    final quiet = m['quietHours'];
    final q = _map(quiet);
    final from = q['from'] is String && _hhmm.hasMatch(q['from']! as String)
        ? q['from']! as String
        : null;
    final to = q['to'] is String && _hhmm.hasMatch(q['to']! as String)
        ? q['to']! as String
        : null;
    final digest = m['digestTime'];
    return UserPreferences(
      interests: wireList(Interest.values, m['interests']),
      digestTime: digest is String && _hhmm.hasMatch(digest) ? digest : null,
      quietFrom: quiet == null
          ? null
          : (from != null && to != null ? from : '22:00'),
      quietTo: quiet == null
          ? null
          : (from != null && to != null ? to : '06:00'),
      fewer: wireList(Interest.values, m['fewer']),
      updatedAt: _str(m['updatedAt']),
    );
  }

  /// The schema's shape; the repository stamps `updatedAt`.
  Map<String, Object?> toJson() => {
    'interests': [for (final i in interests) i.wire],
    'digestTime': digestTime,
    'quietHours': quietFrom == null || quietTo == null
        ? null
        : {'from': quietFrom, 'to': quietTo},
    'fewer': [for (final i in fewer) i.wire],
    'updatedAt': updatedAt,
  };

  UserPreferences copyWith({
    List<Interest>? interests,
    String? Function()? digestTime,
    (String, String)? Function()? quietHours,
    List<Interest>? fewer,
  }) {
    final quiet = quietHours == null
        ? (quietFrom == null || quietTo == null ? null : (quietFrom!, quietTo!))
        : quietHours();
    return UserPreferences(
      interests: interests ?? this.interests,
      digestTime: digestTime == null ? this.digestTime : digestTime(),
      quietFrom: quiet?.$1,
      quietTo: quiet?.$2,
      fewer: fewer ?? this.fewer,
      updatedAt: updatedAt,
    );
  }
}

// ---------- Observation episodes (NL07b; written by the phone) ----------

final _episodeId = RegExp(r'^ep_[a-f0-9]{32}$');

bool isEpisodeId(String id) => _episodeId.hasMatch(id);

enum EpisodeStatus with WireEnum {
  open('open'),
  closed('closed');

  const EpisodeStatus(this.wire);
  @override
  final String wire;
}

/// `babies/{b}/episodes/{ep_<32 hex>}` (`observationEpisodeSchema`, contracts `rhythm.ts`): a
/// member confirms the grouping the app suggested (NL07b); it stays open, whatever the
/// silence, until someone taps "Con đã ổn hơn" (never auto-closed).
@immutable
class ObservationEpisode {
  const ObservationEpisode({
    required this.id,
    required this.babyId,
    required this.startDate,
    required this.confirmedBy,
    this.endDate,
    this.checkInIds = const [],
    this.status = EpisodeStatus.open,
    this.closedBy,
    this.pending = false,
  });

  final String id;
  final String babyId;

  /// Baby-local YYYY-MM-DD of the first changed day grouped in.
  final String startDate;

  /// Set when closed ("con đã ổn hơn" that day).
  final String? endDate;

  /// Who confirmed the grouping.
  final String confirmedBy;
  final List<String> checkInIds;
  final EpisodeStatus status;
  final String? closedBy;

  /// Still queued on this phone.
  final bool pending;

  bool get open => status == EpisodeStatus.open;

  /// `observationEpisodeSchema.checkInIds`: 1–30.
  static const maxCheckIns = 30;

  ObservationEpisode close({required String uid, required String date}) =>
      ObservationEpisode(
        id: id,
        babyId: babyId,
        startDate: startDate,
        endDate: date,
        confirmedBy: confirmedBy,
        checkInIds: checkInIds,
        status: EpisodeStatus.closed,
        closedBy: uid,
      );

  /// Exactly the schema's fields (the repository adds the server timestamps).
  Map<String, Object?> toJson() => {
    'id': id,
    'babyId': babyId,
    'startDate': startDate,
    'endDate': endDate,
    'confirmedBy': confirmedBy,
    'checkInIds': checkInIds,
    'status': status.wire,
    'closedBy': closedBy,
  };

  static ObservationEpisode? fromJson(
    Map<String, Object?> json, {
    bool pending = false,
  }) {
    final id = _str(json['id']);
    final babyId = _str(json['babyId']);
    final start = _date(json['startDate']);
    final by = _str(json['confirmedBy']);
    final status = wireOf(EpisodeStatus.values, json['status']);
    if (id == null ||
        !isEpisodeId(id) ||
        babyId == null ||
        start == null ||
        by == null ||
        status == null) {
      return null;
    }
    return ObservationEpisode(
      id: id,
      babyId: babyId,
      startDate: start,
      endDate: _date(json['endDate']),
      confirmedBy: by,
      checkInIds: [
        for (final c in _list(json['checkInIds']).take(maxCheckIns))
          if (_str(c, max: 40) case final String s when isCheckInId(s)) s,
      ],
      status: status,
      closedBy: _str(json['closedBy']),
      pending: pending,
    );
  }
}
