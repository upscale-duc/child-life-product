import '../baby/baby_models.dart';
import 'rhythm_models.dart';

/// Dart ports of the pure parts of `packages/contracts/src/rhythm.ts` and `personalization.ts`
/// the phone needs offline (reference calendar, observations, age cards). Unit tests run the
/// same fixture pack as the contracts (`premium-v2.json`, C01–C06, X01–X03).

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
