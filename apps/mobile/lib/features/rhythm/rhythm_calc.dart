import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import '../baby/baby_models.dart';
import '../baby/time_zones.dart' show ensureTimeZones;
import '../care/care_models.dart';
import 'rhythm_models.dart';

/// Dart ports of the pure parts of `packages/contracts/src/rhythm.ts` and `personalization.ts`
/// the phone needs offline (reference calendar, observations, age cards, valid days and the sleep
/// baseline). Unit tests run the same fixture pack as the contracts (`premium-v2.json`, B01–B06,
/// C01–C06, X01–X03) and the contract's day-quality cases.

// ---------- Dates (date-only, YYYY-MM-DD, in the baby's time zone) ----------

/// The local calendar date of [d] as YYYY-MM-DD.
String isoOf(DateTime d) => isoDate(d);

DateTime _utc(String date) {
  final p = date.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// `addDaysIso`.
String addDaysIso(String date, int days) {
  final d = _utc(date);
  return isoOf(DateTime.utc(d.year, d.month, d.day + days));
}

/// `daysBetweenIso`.
int daysBetweenIso(String from, String to) =>
    (_utc(to).difference(_utc(from)).inHours / 24).round();

/// Due date = birth + (280 − gestational age in days) (`estimateDueDate`).
String estimateDueDate(String birthDate, int weeks, int days) =>
    addDaysIso(birthDate, 280 - (weeks * 7 + days));

// ---------- Reference calendar (NL03, NL04) ----------

enum CalendarState {
  unset('unset'),
  upcoming('upcoming'),
  inReferenceWindow('in_reference_window'),
  completedReferenceRange('completed_reference_range');

  const CalendarState(this.wire);
  final String wire;
}

typedef StageWindow = ({String start, String end});

/// One stage's window: due date + offsets, inclusive, date-only.
StageWindow stageWindow(
  String dueDate, {
  required int startOffsetDays,
  required int endOffsetDays,
}) => (
  start: addDaysIso(dueDate, startOffsetDays),
  end: addDaysIso(dueDate, endOffsetDays),
);

CalendarState calendarState(
  String? dueDate,
  String today, {
  required int startOffsetDays,
  required int endOffsetDays,
}) {
  if (dueDate == null) return CalendarState.unset;
  final w = stageWindow(
    dueDate,
    startOffsetDays: startOffsetDays,
    endOffsetDays: endOffsetDays,
  );
  if (today.compareTo(w.start) < 0) return CalendarState.upcoming;
  return today.compareTo(w.end) <= 0
      ? CalendarState.inReferenceWindow
      : CalendarState.completedReferenceRange;
}

CalendarState stageState(String? dueDate, String today, ReferenceStage s) =>
    calendarState(
      dueDate,
      today,
      startOffsetDays: s.startOffsetDays,
      endOffsetDays: s.endOffsetDays,
    );

StageWindow windowOf(String dueDate, ReferenceStage s) => stageWindow(
  dueDate,
  startOffsetDays: s.startOffsetDays,
  endOffsetDays: s.endOffsetDays,
);

/// The stages whose windows hold [today] (overlapping windows show both), else the next one.
({List<ReferenceStage> current, ReferenceStage? next}) currentStages(
  String? dueDate,
  String today,
  List<ReferenceStage> stages,
) {
  if (dueDate == null) return (current: const [], next: null);
  final sorted = [...stages]
    ..sort((a, b) => a.startOffsetDays.compareTo(b.startOffsetDays));
  return (
    current: [
      for (final s in sorted)
        if (stageState(dueDate, today, s) == CalendarState.inReferenceWindow) s,
    ],
    next: sorted
        .where((s) => stageState(dueDate, today, s) == CalendarState.upcoming)
        .firstOrNull,
  );
}

// ---------- Observations (X01–X03) ----------

enum ObservationState {
  normal('normal'),
  reportedChange('reported_change'),
  mixed('mixed');

  const ObservationState(this.wire);
  final String wire;
}

/// What a day's check-ins say together; both authors are kept (brief p.12).
ObservationState observationState(Iterable<bool> changed) {
  final normal = changed.any((c) => !c);
  final change = changed.any((c) => c);
  return normal && change
      ? ObservationState.mixed
      : change
      ? ObservationState.reportedChange
      : ObservationState.normal;
}

ObservationState observationStateOf(Iterable<CheckIn> checkIns) =>
    observationState(checkIns.map((c) => c.changed));

// ---------- Age content (H01, PS01F) ----------

/// Actual age in days from the date of birth (never the corrected age, brief p.13).
int ageInDays(DateTime dateOfBirth, DateTime today) =>
    DateTime.utc(today.year, today.month, today.day)
        .difference(
          DateTime.utc(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day),
        )
        .inDays;

/// A baby born at least this many days before the due date (under 37 weeks) is preterm.
const correctedAgeMinEarlyDays = 21;

/// Corrected age applies until 24 months of actual age.
const correctedAgeUntilDays = 730;

/// The age "Tuần này của {bé}" is chosen by (expert review 2026-10-30, D3; contracts
/// `cardAgeDays`): the corrected age for a preterm baby with a due date (`YYYY-MM-DD`), until
/// 24 months of actual age; otherwise the actual age.
int cardAgeDays(DateTime dateOfBirth, String? dueDate, DateTime today) {
  final actual = ageInDays(dateOfBirth, today);
  final due = dueDate == null ? null : DateTime.tryParse(dueDate);
  if (due == null || actual >= correctedAgeUntilDays) return actual;
  final early = ageInDays(dateOfBirth, due);
  return early >= correctedAgeMinEarlyDays
      ? (actual - early).clamp(0, actual)
      : actual;
}

/// `ageCardFor`: the narrowest published range holding [ageDays].
AgeCard? ageCardFor(List<AgeCard> cards, int ageDays) {
  final fit =
      [
        for (final c in cards)
          if (c.status == ContentStatus.published && c.ageDays.holds(ageDays))
            c,
      ]..sort(
        (a, b) => (a.ageDays.to - a.ageDays.from).compareTo(
          b.ageDays.to - b.ageDays.from,
        ),
      );
  return fit.firstOrNull;
}

/// The signs NL05b asks for [ageDays] (unknown age: every sign, the safe side).
List<HealthSignContent> signsFor(HealthPack? pack, int? ageDays) {
  final signs = pack?.signs.isNotEmpty == true
      ? pack!.signs
      : [
          for (final s in HealthSign.values)
            HealthSignContent(
              sign: s,
              label: const Localized('', ''),
              maxAgeDays: s == HealthSign.feverYoung ? 90 : null,
            ),
        ];
  return [
    for (final s in signs)
      if (ageDays == null || s.maxAgeDays == null || ageDays < s.maxAgeDays!) s,
  ];
}

// ---------- Due date limits (NL02b, as `setDueDate` checks) ----------

/// Gestation 22–44 weeks at birth: the due date lies 4 weeks before to 18 weeks after birth.
const dueDateMinOffsetDays = -28;
const dueDateMaxOffsetDays = 126;

/// Whether `setDueDate` accepts [dueDate] for a baby born on [birthDate] (both YYYY-MM-DD).
bool dueDateAllowed(String birthDate, String dueDate) {
  final offset = daysBetweenIso(birthDate, dueDate);
  return offset >= dueDateMinOffsetDays && offset <= dueDateMaxOffsetDays;
}

/// Whether the contract's gestation range holds [weeks] + [days] (22w0d–44w6d).
bool gestationValid(int weeks, int days) =>
    weeks >= 22 && weeks <= 44 && days >= 0 && days <= 6;

// ---------- Valid days, automatic (D-073 #1) ----------

/// Versioned thresholds (`config/rhythm.rules`), not clinical norms (`rhythmRulesSchema`).
class RhythmRules {
  const RhythmRules({
    this.version = 'rules-v1-draft',
    this.maxGapMinutes = 360,
    this.pointCoverMinutes = 30,
    this.baselineMinDays = 5,
    this.baselineMaxDays = 7,
    this.baselineLookbackDays = 14,
    this.recentDays = 3,
    this.recentMinDays = 2,
    this.minDeltaMinutes = 60,
    this.minDeltaShare = 0.15,
    this.minSameDirectionDays = 2,
    this.cooldownDays = 3,
  });

  final String version;
  final int maxGapMinutes;
  final int pointCoverMinutes;
  final int baselineMinDays;
  final int baselineMaxDays;
  final int baselineLookbackDays;
  final int recentDays;
  final int recentMinDays;
  final int minDeltaMinutes;
  final double minDeltaShare;
  final int minSameDirectionDays;
  final int cooldownDays;
}

/// `defaultRhythmRules`.
const defaultRhythmRules = RhythmRules();

enum DayInvalidReason with WireEnum {
  notFinished('not_finished'),
  openTimer('open_timer'),
  overlap('overlap'),
  noSleep('no_sleep'),
  sparse('sparse');

  const DayInvalidReason(this.wire);
  @override
  final String wire;
}

/// One logged care record as the day-quality rule sees it.
typedef CareSpan = ({bool sleep, DateTime occurredAt, DateTime? endedAt});

/// The live records of a care log as spans (deleted ones never count).
List<CareSpan> careSpansOf(Iterable<CareRecord> records) => [
  for (final r in records)
    if (!r.deleted)
      (
        sleep: r.type == CareType.sleep,
        occurredAt: r.occurredAt,
        endedAt: r.endedAt,
      ),
];

class DayQuality {
  const DayQuality({
    required this.date,
    required this.valid,
    required this.reasons,
    required this.sleepMinutes,
    required this.longestGapMinutes,
  });

  final String date;
  final bool valid;
  final List<DayInvalidReason> reasons;

  /// Logged sleep clipped to the day; reported for every day, used only when valid.
  final int sleepMinutes;

  /// Longest stretch in the day without any logged care.
  final int longestGapMinutes;
}

/// `dayBoundsIn`: the instants where [date] starts and ends in [zone].
({DateTime start, DateTime end}) dayBoundsIn(String zone, String date) {
  final p = date.split('-').map(int.parse).toList();
  ensureTimeZones();
  try {
    final location = tz.getLocation(zone);
    return (
      start: tz.TZDateTime(location, p[0], p[1], p[2]).toUtc(),
      end: tz.TZDateTime(location, p[0], p[1], p[2] + 1).toUtc(),
    );
  } on Object {
    final start = DateTime.utc(p[0], p[1], p[2]);
    return (start: start, end: start.add(const Duration(days: 1)));
  }
}

/// The calendar date of [at] in [zone], YYYY-MM-DD.
String localDateIn(String zone, DateTime at) {
  ensureTimeZones();
  try {
    return isoOf(tz.TZDateTime.from(at, tz.getLocation(zone)));
  } on Object {
    return isoOf(at.toUtc());
  }
}

/// `datesTouched`: the local dates a record touches (both days for a span crossing midnight).
List<String> datesTouched(String zone, CareSpan r) {
  final first = localDateIn(zone, r.occurredAt);
  final last = localDateIn(zone, r.endedAt ?? r.occurredAt);
  final dates = [first];
  var cursor = first;
  for (var i = 0; i < 3 && cursor.compareTo(last) < 0; i++) {
    cursor = addDaysIso(cursor, 1);
    dates.add(cursor);
  }
  return dates;
}

/// `dayQuality`: whether [date] counts toward the baseline, with no question to the parent
/// (D-073 #1): finished, no sleep timer still running from it, no unresolved overlap on it, at
/// least one sleep record, and no stretch longer than `maxGapMinutes` without logged care.
/// Missing is never zero (brief p.12).
DayQuality dayQuality({
  required String zone,
  required String date,
  required DateTime now,
  required Iterable<CareSpan> records,
  DateTime? openSleepTimerSince,
  int openConflicts = 0,
  RhythmRules rules = defaultRhythmRules,
}) {
  final bounds = dayBoundsIn(zone, date);
  final s = bounds.start.millisecondsSinceEpoch;
  final e = bounds.end.millisecondsSinceEpoch;
  final reasons = <DayInvalidReason>[];
  if (now.millisecondsSinceEpoch < e) reasons.add(DayInvalidReason.notFinished);
  if (openSleepTimerSince != null &&
      openSleepTimerSince.millisecondsSinceEpoch < e) {
    reasons.add(DayInvalidReason.openTimer);
  }
  if (openConflicts > 0) reasons.add(DayInvalidReason.overlap);

  final cover = rules.pointCoverMinutes * 60000;
  final spans = <(int, int)>[];
  var sleepMs = 0;
  var sleeps = 0;
  for (final r in records) {
    final from = r.occurredAt.millisecondsSinceEpoch;
    if (r.sleep) {
      final ended = r.endedAt;
      if (ended == null) continue;
      final a = math.max(from, s);
      final b = math.min(ended.millisecondsSinceEpoch, e);
      if (b <= a) continue;
      sleeps += 1;
      sleepMs += b - a;
      spans.add((a, b));
    } else if (from >= s - cover && from < e + cover) {
      spans.add((math.max(from - cover, s), math.min(from + cover, e)));
    }
  }
  if (sleeps == 0) reasons.add(DayInvalidReason.noSleep);
  spans.sort((x, y) => x.$1.compareTo(y.$1));
  var cursor = s;
  var gap = 0;
  for (final (a, b) in spans) {
    if (a > cursor) gap = math.max(gap, a - cursor);
    cursor = math.max(cursor, b);
  }
  gap = math.max(gap, e - cursor);
  final longest = (gap / 60000).round();
  if (longest > rules.maxGapMinutes) reasons.add(DayInvalidReason.sparse);
  return DayQuality(
    date: date,
    valid: reasons.isEmpty,
    reasons: reasons,
    sleepMinutes: (sleepMs / 60000).round(),
    longestGapMinutes: longest,
  );
}

// ---------- Sleep baseline (B01–B06, brief p.12) ----------

/// `BaselineResult`: the numbers are null when [status] is insufficient data.
class BaselineResult {
  const BaselineResult({
    required this.status,
    required this.validBaselineDays,
    required this.validRecentDays,
    this.baseline,
    this.recent,
    this.delta,
    this.threshold,
  });

  final SleepStatus status;
  final double? baseline;
  final double? recent;
  final double? delta;
  final double? threshold;
  final int validBaselineDays;
  final int validRecentDays;
}

double _median(List<num> values) {
  final v = [...values]..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid].toDouble() : (v[mid - 1] + v[mid]) / 2;
}

/// `sleepBaseline`: compares the recent window with the baseline. Lists hold one value per
/// completed day in each window (disjoint), null for a day that is not valid.
BaselineResult sleepBaseline(
  List<num?> baselineMinutes,
  List<num?> recentMinutes, {
  RhythmRules rules = defaultRhythmRules,
}) {
  final b = [...baselineMinutes.nonNulls];
  final r = [...recentMinutes.nonNulls];
  if (b.length < rules.baselineMinDays || r.length < rules.recentMinDays) {
    return BaselineResult(
      status: SleepStatus.insufficientData,
      validBaselineDays: b.length,
      validRecentDays: r.length,
    );
  }
  final baseline = _median(b);
  final recent = _median(r);
  final delta = recent - baseline;
  final threshold = math.max(
    rules.minDeltaMinutes.toDouble(),
    rules.minDeltaShare * baseline,
  );
  final same = r
      .where(
        (v) => delta < 0
            ? v - baseline <= -threshold
            : delta > 0
            ? v - baseline >= threshold
            : false,
      )
      .length;
  return BaselineResult(
    status: delta.abs() >= threshold && same >= rules.minSameDirectionDays
        ? SleepStatus.changeDetected
        : SleepStatus.noChange,
    baseline: baseline,
    recent: recent,
    delta: delta,
    threshold: threshold,
    validBaselineDays: b.length,
    validRecentDays: r.length,
  );
}

/// `sleepWindows`: recent = the last `recentDays` completed days before [today]; baseline = up
/// to `baselineMaxDays` latest valid days in the `baselineLookbackDays` before the recent
/// window. Days missing from [days] count as invalid.
({List<int?> baseline, List<int?> recent, List<String> recentDates})
sleepWindows(
  String today,
  Iterable<DayQuality> days, {
  RhythmRules rules = defaultRhythmRules,
}) {
  final byDate = {for (final d in days) d.date: d};
  int? value(String date) {
    final d = byDate[date];
    return d != null && d.valid ? d.sleepMinutes : null;
  }

  final recentDates = [
    for (var i = 0; i < rules.recentDays; i++)
      addDaysIso(today, -rules.recentDays + i),
  ];
  final firstRecent = recentDates.first;
  final valid = [
    for (var i = 0; i < rules.baselineLookbackDays; i++)
      ?value(addDaysIso(firstRecent, -rules.baselineLookbackDays + i)),
  ];
  return (
    baseline: valid.sublist(math.max(0, valid.length - rules.baselineMaxDays)),
    recent: [for (final d in recentDates) value(d)],
    recentDates: recentDates,
  );
}

/// NL07 "Nhịp riêng của con": the days and the comparison the phone computed from the care log.
class SleepSummary {
  const SleepSummary({
    required this.days,
    required this.result,
    required this.recentDates,
  });

  /// Every day of the lookback and recent windows, oldest first.
  final List<DayQuality> days;
  final BaselineResult result;
  final List<String> recentDates;
}

/// How many unresolved overlaps touch each local date: every day either record of an open
/// conflict touches ([conflicts]: the record ids of each one).
Map<String, int> overlapDaysOf(
  String zone,
  List<CareRecord> records,
  List<List<String>> conflicts,
) {
  final byId = {for (final r in records) r.id: r};
  final overlapDays = <String, int>{};
  for (final ids in conflicts) {
    final touched = <String>{
      for (final id in ids)
        if (byId[id] case final r?)
          ...datesTouched(zone, (
            sleep: r.type == CareType.sleep,
            occurredAt: r.occurredAt,
            endedAt: r.endedAt,
          )),
    };
    for (final d in touched) {
      overlapDays[d] = (overlapDays[d] ?? 0) + 1;
    }
  }
  return overlapDays;
}

/// The facts builder of `nextAction` on the phone: quality of each day over the baseline
/// lookback plus the recent window, then [sleepBaseline]. An unresolved overlap invalidates every
/// day either record touches ([conflicts]: the record ids of each open conflict).
SleepSummary sleepSummary({
  required String zone,
  required String today,
  required DateTime now,
  required List<CareRecord> records,
  DateTime? openSleepTimerSince,
  List<List<String>> conflicts = const [],
  RhythmRules rules = defaultRhythmRules,
}) {
  final spans = careSpansOf(records);
  final overlapDays = overlapDaysOf(zone, records, conflicts);
  final span = rules.baselineLookbackDays + rules.recentDays;
  final days = [
    for (var i = 0; i < span; i++)
      dayQuality(
        zone: zone,
        date: addDaysIso(today, -span + i),
        now: now,
        records: spans,
        openSleepTimerSince: openSleepTimerSince,
        openConflicts: overlapDays[addDaysIso(today, -span + i)] ?? 0,
        rules: rules,
      ),
  ];
  final windows = sleepWindows(today, days, rules: rules);
  return SleepSummary(
    days: days,
    result: sleepBaseline(windows.baseline, windows.recent, rules: rules),
    recentDates: windows.recentDates,
  );
}

// ---------- Episodes (NL07b) ----------

/// `suggestEpisode`: grouping is suggested when ≥2 of the last 3 days with updates report a
/// change. Only a suggestion: parents confirm; silence never ends an episode.
bool suggestEpisode(Iterable<({String date, ObservationState state})> days) {
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  final lastThree = sorted.sublist(math.max(0, sorted.length - 3));
  return lastThree.where((d) => d.state != ObservationState.normal).length >= 2;
}
