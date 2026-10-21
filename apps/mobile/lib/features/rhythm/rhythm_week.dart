import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/care_calc.dart' show diaperDay, feedDay;
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/timer_models.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import 'rhythm_calc.dart';
import 'rhythm_models.dart';

/// EN09 "Tóm tắt tuần" (561:3102), computed on the phone from what the family logged: the free
/// records of the week (feeds, sleep over automatic valid days with its coverage, diapers,
/// growth, Kỷ niệm, who logged) and the facts the group A look-back stands on (the week's
/// check-ins, what was tried). Facts only; nothing is scored or compared with other babies.

// ---------- The week ----------

/// The summary week: **Monday to Sunday in the baby's time zone** (EN09 draws "5 – 11 tháng 10",
/// a Mon–Sun week, and EN07 sends it on Sunday 20:30). On a Sunday it is the week ending today,
/// still running ([inProgress]: today is not a valid day yet, D-073 #1); Monday to Saturday it
/// is the last completed week.
@immutable
class SummaryWeek {
  const SummaryWeek({
    required this.start,
    required this.end,
    required this.inProgress,
  });

  /// Monday, YYYY-MM-DD.
  final String start;

  /// Sunday, YYYY-MM-DD.
  final String end;
  final bool inProgress;

  /// The seven dates, Monday first.
  List<String> get dates => [for (var i = 0; i < 7; i++) addDaysIso(start, i)];

  /// "Tuần tới": the following Monday–Sunday.
  String get nextStart => addDaysIso(end, 1);
  String get nextEnd => addDaysIso(end, 7);

  @override
  bool operator ==(Object other) =>
      other is SummaryWeek &&
      other.start == start &&
      other.end == end &&
      other.inProgress == inProgress;

  @override
  int get hashCode => Object.hash(start, end, inProgress);
}

/// The week to summarise on [today] (the baby-local date, YYYY-MM-DD).
SummaryWeek summaryWeekFor(String today) {
  final weekday = DateTime.parse(today).weekday;
  final end = weekday == DateTime.sunday ? today : addDaysIso(today, -weekday);
  return SummaryWeek(
    start: addDaysIso(end, -6),
    end: end,
    inProgress: end == today,
  );
}

/// "Tuần n của {bé}": the week of life on the week's Sunday, counted from the date of birth
/// (days 0–6 = week 1). Null when the baby was not born by then.
int? weekOfLife(DateTime dateOfBirth, SummaryWeek week) {
  final age = ageInDays(dateOfBirth, DateTime.parse(week.end));
  return age < 0 ? null : age ~/ 7 + 1;
}

/// A whole week has passed: the baby was born by the week's Monday, so every day of it is a day
/// of life. Unknown date of birth (a caregiver): true.
bool weekHasPassed(DateTime? dateOfBirth, SummaryWeek week) =>
    dateOfBirth == null ||
    ageInDays(dateOfBirth, DateTime.parse(week.start)) >= 0;

// ---------- Free records ----------

/// One person's entries in the week's log ("Mẹ 41 lần"), in the order they first logged.
typedef AuthorCount = ({String uid, CareAuthor author, int count});

/// EN09 "Đã ghi trong tuần".
@immutable
class WeekFacts {
  const WeekFacts({
    required this.week,
    required this.bottleCount,
    required this.bottleMl,
    required this.breastCount,
    required this.breastMinutes,
    required this.diapers,
    required this.wet,
    required this.dirty,
    required this.days,
    required this.minValidDays,
    required this.authors,
    this.growth,
    this.previousWeight,
    this.photos = 0,
    this.videos = 0,
    this.notes = 0,
  });

  final SummaryWeek week;
  final int bottleCount;

  /// Bottle millilitres; breastfeeding stays in minutes (never converted).
  final int bottleMl;
  final int breastCount;
  final int breastMinutes;
  final int diapers;
  final int wet;
  final int dirty;

  /// The quality of each day, Monday first (sleep counts only on valid days).
  final List<DayQuality> days;

  /// The fewest valid days an average stands on ([RhythmRules.baselineMinDays]).
  final int minValidDays;
  final List<AuthorCount> authors;

  /// The latest measurement of the week, and the weighing before it.
  final CareRecord? growth;
  final CareRecord? previousWeight;
  final int photos;
  final int videos;
  final int notes;

  int get feeds => bottleCount + breastCount;
  int get validDays => days.where((d) => d.valid).length;

  /// Mean logged sleep per valid day; null under [minValidDays]. Days that are not valid are
  /// left out, never counted as zero.
  int? get averageSleepMinutes {
    final valid = [
      for (final d in days)
        if (d.valid) d.sleepMinutes,
    ];
    if (valid.length < minValidDays) return null;
    return (valid.fold<int>(0, (s, m) => s + m) / valid.length).round();
  }

  bool get hasMemories => photos + videos + notes > 0;
}

/// The calendar date of a measurement: the day it was measured on, else when it was logged.
String measuredDate(String zone, CareRecord r) => r.measuredOn != null
    ? isoOf(r.measuredOn!)
    : localDateIn(zone, r.occurredAt);

/// EN09's free records for [week] in [zone]. [records] = the care log around the week (a day
/// before for sleeps crossing into Monday); [growth] = every measurement; [memories] = what this
/// person may see of Kỷ niệm, or null when unavailable.
WeekFacts weekFacts({
  required String zone,
  required SummaryWeek week,
  required DateTime now,
  required List<CareRecord> records,
  List<CareRecord> growth = const [],
  List<Memory>? memories,
  DateTime? openSleepTimerSince,
  List<List<String>> conflicts = const [],
  RhythmRules rules = defaultRhythmRules,
}) {
  final from = dayBoundsIn(zone, week.start).start;
  final to = dayBoundsIn(zone, week.end).end;
  bool inWeek(DateTime at) => !at.isBefore(from) && at.isBefore(to);

  final feeds = feedDay(records, from, to);
  final diapers = diaperDay(records, from, to);
  final spans = careSpansOf(records);
  final overlaps = overlapDaysOf(zone, records, conflicts);
  final days = [
    for (final date in week.dates)
      dayQuality(
        zone: zone,
        date: date,
        now: now,
        records: spans,
        openSleepTimerSince: openSleepTimerSince,
        openConflicts: overlaps[date] ?? 0,
        rules: rules,
      ),
  ];

  // "Cả nhà đã cùng chăm": every live entry of the week by its author, in the order people first
  // logged (never sorted by count: no ranking).
  final counts = <String, int>{};
  final authors = <String, CareAuthor>{};
  final ordered = [
    for (final r in records)
      if (!r.deleted && inWeek(r.occurredAt)) r,
  ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  for (final r in ordered) {
    counts[r.createdBy] = (counts[r.createdBy] ?? 0) + 1;
    authors.putIfAbsent(r.createdBy, () => r.author);
  }

  final measured = [
    for (final r in growth)
      if (!r.deleted && r.type == CareType.growth) r,
  ]..sort((a, b) => measuredDate(zone, a).compareTo(measuredDate(zone, b)));
  final thisWeek = [
    for (final r in measured)
      if (measuredDate(zone, r).compareTo(week.start) >= 0 &&
          measuredDate(zone, r).compareTo(week.end) <= 0)
        r,
  ];
  final latest = thisWeek.lastOrNull;
  CareRecord? before;
  if (latest?.weightKg != null) {
    final day = measuredDate(zone, latest!);
    before = measured
        .where(
          (r) => r.weightKg != null && measuredDate(zone, r).compareTo(day) < 0,
        )
        .lastOrNull;
  }

  var photos = 0, videos = 0, notes = 0;
  for (final m in memories ?? const <Memory>[]) {
    if (m.deleted || !inWeek(m.occurredAt)) continue;
    photos += m.photos;
    videos += m.videos;
    if (m.isNote) notes++;
  }

  return WeekFacts(
    week: week,
    bottleCount: feeds.bottleCount,
    bottleMl: feeds.bottleMl,
    breastCount: feeds.breastCount,
    breastMinutes: feeds.breastMinutes,
    diapers: diapers.total,
    wet: diapers.wet,
    dirty: diapers.dirty,
    days: days,
    minValidDays: rules.baselineMinDays,
    authors: [
      for (final e in counts.entries)
        (uid: e.key, author: authors[e.key]!, count: e.value),
    ],
    growth: latest,
    previousWeight: before,
    photos: photos,
    videos: videos,
    notes: notes,
  );
}

// ---------- Group A look-back (facts only) ----------

/// The week's check-ins as EN09's look-back tells them: days with a reported change, days noted
/// as usual, days where two people saw it differently (both kept, X03), and which changes on
/// how many days. Health worries go to HL01 and are not summed up here.
@immutable
class WeekNotes {
  const WeekNotes({
    required this.changedDays,
    required this.usualDays,
    required this.mixedDays,
    required this.observations,
  });

  final int changedDays;
  final int usualDays;
  final int mixedDays;

  /// Each reported change with the number of days it was noted, in the C01 order.
  final List<({Observation observation, int days})> observations;

  bool get isEmpty => changedDays == 0 && usualDays == 0;
}

WeekNotes weekNotes(Iterable<CheckIn> checkIns, SummaryWeek week) {
  final byDay = <String, List<CheckIn>>{};
  for (final c in checkIns) {
    if (c.observation == Observation.health) continue;
    if (c.date.compareTo(week.start) < 0 || c.date.compareTo(week.end) > 0) {
      continue;
    }
    (byDay[c.date] ??= []).add(c);
  }
  var changed = 0, usual = 0, mixed = 0;
  final obsDays = <Observation, Set<String>>{};
  for (final MapEntry(key: date, value: day) in byDay.entries) {
    switch (observationStateOf(day)) {
      case ObservationState.normal:
        usual++;
      case ObservationState.reportedChange:
        changed++;
      case ObservationState.mixed:
        changed++;
        mixed++;
    }
    for (final c in day) {
      if (c.changed) (obsDays[c.observation] ??= {}).add(date);
    }
  }
  return WeekNotes(
    changedDays: changed,
    usualDays: usual,
    mixedDays: mixed,
    observations: [
      for (final o in Observation.values)
        if (obsDays[o] case final dates?) (observation: o, days: dates.length),
    ],
  );
}

/// "Đã thử trong tuần": the latest answer per activity given during the week (put-offs left
/// out), newest first ([feedback] is newest first).
List<RecFeedback> weekTried(Iterable<RecFeedback> feedback, SummaryWeek week) {
  final seen = <String>{};
  return [
    for (final f in feedback)
      if (f.kind != FeedbackKind.notToday &&
          f.date.compareTo(week.start) >= 0 &&
          f.date.compareTo(week.end) <= 0 &&
          seen.add(f.contentId))
        f,
  ];
}

// ---------- Providers ----------

/// (baby, zone, baby-local today, whether the viewer is a Cùng nuôi for Kỷ niệm's audience).
typedef WeekKey = ({String babyId, String zone, String today, bool parent});

/// The care log EN09 reads: the week plus the day before (a sleep crossing into Monday) and the
/// point-cover after Sunday, as the day-quality rule reads it.
(String, DateTime, DateTime) weekRangeKey(WeekKey k) {
  final week = summaryWeekFor(k.today);
  return (
    k.babyId,
    dayBoundsIn(k.zone, addDaysIso(week.start, -1)).start,
    dayBoundsIn(
      k.zone,
      week.end,
    ).end.add(Duration(minutes: defaultRhythmRules.pointCoverMinutes)),
  );
}

/// [weekFacts] over what this phone has of the log (works offline); null while it loads. The
/// screen decides who may see it (`history.read`).
final weekFactsProvider = Provider.autoDispose.family<WeekFacts?, WeekKey>((
  ref,
  k,
) {
  final records = ref.watch(rangeRecordsProvider(weekRangeKey(k))).value;
  if (records == null) return null;
  final growth = ref.watch(growthRecordsProvider(k.babyId)).value;
  final memories = ref
      .watch(completeMemoriesProvider((k.babyId, k.parent)))
      .value;
  final timer = ref.watch(careTimerProvider((k.babyId, TimerType.sleep))).value;
  final conflicts =
      ref.watch(openConflictsProvider(k.babyId)).value ??
      const <SleepConflict>[];
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  return weekFacts(
    zone: k.zone,
    week: summaryWeekFor(k.today),
    now: now,
    records: records,
    growth: growth ?? const [],
    memories: memories,
    openSleepTimerSince: timer?.startedAt,
    conflicts: [for (final c in conflicts) c.recordIds],
  );
});
