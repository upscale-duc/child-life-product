import '../care/care_models.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../care/growth_reference.dart';
import '../care/who_growth.dart';
import 'nutrition_models.dart';

/// Pure rules of Dinh dưỡng theo giai đoạn (D-083, P-163), mirroring
/// `packages/contracts/src/nutrition.ts` (`monthsOld`, `nutritionStageFor`, `campaignRounds`) so the
/// app, the server and the portal agree on ages, stages and rounds. Everything runs on the device
/// from the baby's own logs; nothing about the child leaves it (plan §3).

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Whole days from [a] to [b] (calendar dates, no DST surprises).
int nuDaysBetween(DateTime a, DateTime b) => _day(b).difference(_day(a)).inDays;

// ---------- Ages and stages ----------

/// `monthsOld`: completed calendar months between [dob] and [today] (local dates), ≥ 0. A month
/// is complete on the same day of the month.
int nuMonthsOld(DateTime dob, DateTime today) {
  var m = (today.year - dob.year) * 12 + (today.month - dob.month);
  if (today.day < dob.day) m -= 1;
  return m < 0 ? 0 : m;
}

/// `sortNutritionStages`: by start, then by end.
List<NuStage> nuSortStages(Iterable<NuStage> stages) => [...stages]
  ..sort(
    (a, b) => a.age.from != b.age.from
        ? a.age.from.compareTo(b.age.from)
        : a.age.to.compareTo(b.age.to),
  );

/// `nutritionStageFor`: the stage covering [months] (narrowest first, then the earlier one);
/// past the last stage, the last one with [past] (P-163 #9); null when none covers the age.
({NuStage stage, bool past})? nuStageFor(List<NuStage> stages, int months) {
  final sorted = nuSortStages(stages);
  final hits = [
    for (final (i, s) in sorted.indexed)
      if (s.age.contains(months)) (i, s),
  ];
  if (hits.isNotEmpty) {
    // Stable: equal widths keep the sorted order.
    hits.sort((x, y) {
      final w = (x.$2.age.to - x.$2.age.from).compareTo(
        y.$2.age.to - y.$2.age.from,
      );
      return w != 0 ? w : x.$1.compareTo(y.$1);
    });
    return (stage: hits.first.$2, past: false);
  }
  final last = sorted.lastOrNull;
  if (last != null && months >= last.age.to) return (stage: last, past: true);
  return null;
}

/// Where a stage sits against the baby (9f rail: past · current · future).
enum NuStageTime { past, current, future }

NuStageTime nuStageTime(NuStage s, NuStage? current, int months) {
  if (current != null && s.id == current.id) return NuStageTime.current;
  return months >= s.age.to ? NuStageTime.past : NuStageTime.future;
}

// ---------- Milk (9b / 9c, P-163 #3–#5) ----------

/// Bottle totals per local day in the baby's [zone], oldest first, for the [days] days ending on
/// [today]. Only bottle feeds with an amount count (formula or expressed milk); breastfeeds by
/// duration and pumping do not (P-163 #3). Days without a log are 0.
List<int> nuDailyBottleMl(
  Iterable<CareRecord> records,
  String zone,
  DateTime today, {
  int days = 14,
}) {
  final totals = List<int>.filled(days, 0);
  for (final r in records) {
    if (r.deleted || r.type != CareType.bottle) continue;
    final ml = r.amountMl;
    if (ml == null || ml <= 0) continue;
    final local = inBabyZone(zone, r.occurredAt);
    final back = nuDaysBetween(local, today);
    if (back < 0 || back >= days) continue;
    totals[days - 1 - back] += ml;
  }
  return totals;
}

/// Days with bottle amounts a 7-day average needs (P-163 #4).
const nuMinMilkDays = 3;

/// The 7-day average (the last 7 entries of [daily], today included): the mean of the days
/// with amounts, rounded to 10 ml; null with fewer than [nuMinMilkDays] such days.
int? nuMilkAverage(List<int> daily) {
  final last = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;
  final days = [
    for (final v in last)
      if (v > 0) v,
  ];
  if (days.length < nuMinMilkDays) return null;
  final mean = days.fold<int>(0, (a, b) => a + b) / days.length;
  return (mean / 10).round() * 10;
}

/// Where the average sits against the stage's daily band (never a judgement, P-163 #5).
enum NuMilkPosition { below, within, above }

NuMilkPosition? nuMilkPosition(int? average, NuRange? band) {
  if (average == null || band == null) return null;
  if (average < band.min) return NuMilkPosition.below;
  if (average > band.max) return NuMilkPosition.above;
  return NuMilkPosition.within;
}

// ---------- Growth (9b card, 9e, P-163 #6) ----------

/// One measurement of a metric: its date, value, the baby's age that day and its WHO position
/// (null without a date of birth or a known sex).
typedef NuMeasure = ({
  DateTime on,
  double value,
  int? ageDays,
  GrowthBand? band,
});

GrowthMeasure nuGrowthMeasure(NuMetric m) =>
    m == NuMetric.length ? GrowthMeasure.length : GrowthMeasure.weight;

/// The measurements of [measure], newest first, placed against the band (P3–P97).
List<NuMeasure> nuMeasures(
  Iterable<CareRecord> growth,
  GrowthMeasure measure, {
  required DateTime? dob,
  required bool? boy,
  GrowthReference reference = GrowthReference.bundled,
}) {
  final out = <NuMeasure>[];
  for (final r in growth) {
    if (r.deleted || r.type != CareType.growth) continue;
    final value = r.measure(measure);
    if (value == null || value <= 0) continue;
    final on = r.measuredOn ?? r.occurredAt;
    final day = DateTime(on.year, on.month, on.day);
    final age = dob == null ? null : nuDaysBetween(dob, day);
    final band = age == null || age < 0 || boy == null
        ? null
        : reference.band(measure, boy: boy, ageDays: age, value: value);
    out.add((
      on: day,
      value: value,
      ageDays: age == null || age < 0 ? null : age,
      band: band,
    ));
  }
  out.sort((a, b) => b.on.compareTo(a.on));
  return out;
}

/// A growth rule fires when the 2 latest measurements of its metric are both in its age range
/// (age on the day measured) and both on its side of P3–P97 (P-163 #6). One low reading followed
/// by a normal one does not.
bool nuGrowthRuleFires(NuRule rule, List<NuMeasure> newestFirst, DateTime dob) {
  if (!rule.isGrowth) return false;
  final side = switch (rule.condition) {
    NuCondition.belowRange => GrowthBand.below,
    NuCondition.aboveRange => GrowthBand.above,
    _ => null,
  };
  if (side == null || newestFirst.length < 2) return false;
  for (final m in newestFirst.take(2)) {
    if (m.band != side) return false;
    if (!rule.age.contains(nuMonthsOld(dob, m.on))) return false;
  }
  return true;
}

/// The milk rule: the 7-day average (≥ 3 days) outside the stage's daily band, at an age the
/// rule covers.
bool nuMilkRuleFires(NuRule rule, int months, int? average, NuRange? band) =>
    rule.metric == NuMetric.milk &&
    rule.condition == NuCondition.milkOutsideStage &&
    rule.age.contains(months) &&
    switch (nuMilkPosition(average, band)) {
      NuMilkPosition.below || NuMilkPosition.above => true,
      _ => false,
    };

/// No weight or length for the rule's days (default 30); with nothing ever measured, once the
/// baby is that many days old.
bool nuNoMeasurementFires(
  NuRule rule,
  int months, {
  required DateTime? lastMeasured,
  required DateTime dob,
  required DateTime today,
}) {
  if (rule.metric != NuMetric.measurement ||
      rule.condition != NuCondition.noMeasurement ||
      !rule.age.contains(months)) {
    return false;
  }
  final days = rule.days ?? 30;
  return nuDaysBetween(lastMeasured ?? dob, today) >= days;
}

/// What the baby's own data matches today: at most one growth rule per metric (weight first),
/// the milk rule and the no-measurement rule. Rules are taken in id order.
typedef NuSignals = ({
  List<NuRule> growth,
  NuRule? milk,
  NuRule? noMeasurement,
});

const NuSignals nuNoSignals = (growth: [], milk: null, noMeasurement: null);

NuSignals nuEvaluate({
  required List<NuRule> rules,
  required int months,
  required DateTime dob,
  required DateTime today,
  required List<NuMeasure> weights,
  required List<NuMeasure> lengths,
  required int? milkAverage,
  required NuRange? milkBand,
  required DateTime? lastMeasured,
}) {
  final sorted = [...rules]..sort((a, b) => a.id.compareTo(b.id));
  NuRule? growthFor(NuMetric m, List<NuMeasure> measures) => sorted
      .where((r) => r.metric == m && nuGrowthRuleFires(r, measures, dob))
      .firstOrNull;
  return (
    growth: [
      ?growthFor(NuMetric.weight, weights),
      ?growthFor(NuMetric.length, lengths),
    ],
    milk: sorted
        .where((r) => nuMilkRuleFires(r, months, milkAverage, milkBand))
        .firstOrNull,
    noMeasurement: sorted
        .where(
          (r) => nuNoMeasurementFires(
            r,
            months,
            lastMeasured: lastMeasured,
            dob: dob,
            today: today,
          ),
        )
        .firstOrNull,
  );
}

// ---------- Vitamin A rounds (9g, P-163 #12) ----------

/// `RoundState`: taken (recorded), the next one ahead, a past one not recorded (neutral grey,
/// never red), before the eligible age, later ones, past the eligible age.
enum NuRoundState { taken, next, past, tooYoung, later, tooOld }

typedef NuVitaminRound = ({
  /// "2026-12": the key of the taken record.
  String key,
  DateTime from,
  DateTime to,
  NuRoundState state,
  DateTime? takenOn,
});

String _pad(int n) => n.toString().padLeft(2, '0');

/// `YYYY-MM-DD`.
String nuIsoDay(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

DateTime? nuParseDay(String? iso) {
  if (iso == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

DateTime _clampedDay(int y, int m, int d) {
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d > last ? last : d);
}

/// `campaignRounds`: this year's and next year's rounds for a baby born on [dob], on [today]
/// (calendar dates in the baby's zone), with what each round is for that baby.
List<NuVitaminRound> nuCampaignRounds(
  NuCampaign campaign,
  DateTime dob,
  DateTime today,
  Map<String, String> taken,
) {
  final year = today.year;
  final ordered = [...campaign.rounds]
    ..sort((a, b) => a.month.compareTo(b.month));
  final rounds = [
    for (final y in [year, year + 1])
      for (final r in ordered)
        (
          key: '$y-${_pad(r.month)}',
          from: _clampedDay(y, r.month, r.fromDay),
          to: _clampedDay(y, r.month, r.toDay),
        ),
  ]..sort((a, b) => a.from.compareTo(b.from));
  final day = _day(today);
  var nextGiven = false;
  return [
    for (final r in rounds)
      () {
        final months = nuMonthsOld(dob, r.from);
        final takenOn = nuParseDay(taken[r.key]);
        NuRoundState state;
        if (taken[r.key] != null) {
          state = NuRoundState.taken;
        } else if (months < campaign.age.from) {
          state = NuRoundState.tooYoung;
        } else if (months >= campaign.age.to) {
          state = NuRoundState.tooOld;
        } else if (_day(r.to).isBefore(day)) {
          state = NuRoundState.past;
        } else if (!nextGiven) {
          state = NuRoundState.next;
          nextGiven = true;
        } else {
          state = NuRoundState.later;
        }
        return (
          key: r.key,
          from: r.from,
          to: r.to,
          state: state,
          takenOn: takenOn,
        );
      }(),
  ];
}

/// The first round the baby can have (9g before 6 months: "Bé sẽ được uống từ 6 tháng tuổi").
NuVitaminRound? nuFirstEligible(List<NuVitaminRound> rounds) => rounds
    .where((r) => r.state == NuRoundState.next || r.state == NuRoundState.later)
    .firstOrNull;

/// A vitamin A reminder (P-163 #13): due at 08:00 on the round's first day with "Báo trước 1
/// ngày", so it rings at 08:00 the day before; once that has passed, at 08:00 on the day; null
/// when both are past. [instant] turns a wall-clock time in the baby's zone into an instant.
({DateTime wallFire, DateTime dueWall, int lead})? nuVitaminReminderTime(
  DateTime roundFrom,
  DateTime now,
  DateTime Function(DateTime wall) instant,
) {
  final due = DateTime(roundFrom.year, roundFrom.month, roundFrom.day, 8);
  final before = DateTime(
    roundFrom.year,
    roundFrom.month,
    roundFrom.day - 1,
    8,
  );
  if (instant(before).isAfter(now)) {
    return (wallFire: before, dueWall: due, lead: 1440);
  }
  if (instant(due).isAfter(now)) return (wallFire: due, dueWall: due, lead: 0);
  return null;
}

// ---------- Calendar file (9g "Thêm vào lịch", P-163 #13) ----------

String _icsEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll(RegExp(r'\r?\n'), r'\n');

/// RFC 5545 folding: lines of at most 75 octets, continued with a space.
String _icsFold(String line) {
  final out = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final size = rune < 0x80
        ? 1
        : rune < 0x800
        ? 2
        : rune < 0x10000
        ? 3
        : 4;
    if (bytes + size > 74) {
      out.write('\r\n ');
      bytes = 1;
    }
    out.write(ch);
    bytes += size;
  }
  return out.toString();
}

/// An all-day event over the round's days with an alarm at 08:00 the day before (no calendar
/// permission: the file is shared, P-163 #13).
String nuVitaminIcs({
  required String uid,
  required DateTime from,
  required DateTime to,
  required String summary,
  required String location,
  required String description,
  required DateTime now,
}) {
  String date(DateTime d) => '${d.year}${_pad(d.month)}${_pad(d.day)}';
  final u = now.toUtc();
  final stamp = '${date(u)}T${_pad(u.hour)}${_pad(u.minute)}${_pad(u.second)}Z';
  final end = DateTime(to.year, to.month, to.day + 1);
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Child Life//Nutrition//VI',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:$uid',
    'DTSTAMP:$stamp',
    'DTSTART;VALUE=DATE:${date(from)}',
    'DTEND;VALUE=DATE:${date(end)}',
    'SUMMARY:${_icsEscape(summary)}',
    if (location.isNotEmpty) 'LOCATION:${_icsEscape(location)}',
    if (description.isNotEmpty) 'DESCRIPTION:${_icsEscape(description)}',
    'BEGIN:VALARM',
    'ACTION:DISPLAY',
    'DESCRIPTION:${_icsEscape(summary)}',
    // 16 h before midnight of the first day: 08:00 the day before.
    'TRIGGER:-PT16H',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ].map(_icsFold).join('\r\n');
}
