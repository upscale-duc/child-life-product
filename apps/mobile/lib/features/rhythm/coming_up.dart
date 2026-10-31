import '../care/care_calc.dart' show careNightFromHour, careNightToHour;
import '../care/care_models.dart';
import '../care/care_repository.dart' show inBabyZone;

/// "Sắp tới" and "Bé dậy chưa?" (sprint wow W1 / lumi-plan §7.1 L6, owner 2026-10-30): what this
/// baby's own log says usually comes next. Pure, so every rule is tested without a phone.
///
/// The ranges follow `routinePatterns` (contracts `personalization-v2.ts`, P-172 A1–A2): the
/// middle half (25th–75th percentile) of recorded intervals over the last 14 days, at least five
/// of them on three days, the latest within three days, never wider than ×2, rounded to 5 min.
/// They describe the family's log ("thường"), never a target, a schedule or a clinical norm.

const comingUpLookbackDays = 14;

/// The family's night window: the app's one window, 18:00–06:00 in the baby's zone (D-151 #1,
/// replacing lumi-plan §7.1's 19:00).
const nightFromHour = careNightFromHour;
const nightToHour = careNightToHour;

/// A usual range of minutes from this baby's log.
class RoutineRange {
  const RoutineRange({
    required this.lowMinutes,
    required this.highMinutes,
    required this.samples,
  });

  final int lowMinutes;
  final int highMinutes;
  final int samples;

  @override
  bool operator ==(Object other) =>
      other is RoutineRange &&
      other.lowMinutes == lowMinutes &&
      other.highMinutes == highMinutes &&
      other.samples == samples;

  @override
  int get hashCode => Object.hash(lowMinutes, highMinutes, samples);

  @override
  String toString() => 'RoutineRange($lowMinutes–$highMinutes, n=$samples)';
}

typedef _Point = ({DateTime at, double minutes});

String _dayKey(String zone, DateTime at) {
  final l = inBabyZone(zone, at);
  return '${l.year}-${l.month}-${l.day}';
}

bool _isNight(String zone, DateTime at) {
  final h = inBabyZone(zone, at).hour;
  return h >= nightFromHour || h < nightToHour;
}

RoutineRange? _range(List<_Point> points, DateTime now, String zone) {
  if (points.length < 5) return null;
  final days = {for (final p in points) _dayKey(zone, p.at)}.length;
  if (days < 3) return null;
  final latest = points.map((p) => p.at).reduce((a, b) => a.isAfter(b) ? a : b);
  if (now.difference(latest) > const Duration(days: 3)) return null;
  final sorted = [for (final p in points) p.minutes]..sort();
  final low = sorted[((sorted.length - 1) * 0.25).floor()];
  final high = sorted[((sorted.length - 1) * 0.75).ceil()];
  if (low <= 0 || high / low > 2) return null;
  return RoutineRange(
    lowMinutes: (low / 5).floor() * 5,
    highMinutes: (high / 5).ceil() * 5,
    samples: points.length,
  );
}

List<CareRecord> _window(List<CareRecord> records, DateTime now) {
  final since = now.subtract(const Duration(days: comingUpLookbackDays));
  return [
    for (final r in records)
      if (!r.deleted &&
          !r.occurredAt.isBefore(since) &&
          !r.occurredAt.isAfter(now))
        r,
  ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
}

bool _isFeed(CareRecord r) =>
    r.type == CareType.bottle || r.type == CareType.breast;

/// Minutes between the starts of two feeds on the same local day (30 min – 6 h).
RoutineRange? feedIntervalRange(
  List<CareRecord> records,
  DateTime now,
  String zone,
) {
  final feeds = _window(records, now).where(_isFeed).toList();
  final points = <_Point>[];
  for (var i = 1; i < feeds.length; i++) {
    final a = feeds[i - 1].occurredAt, b = feeds[i].occurredAt;
    if (_dayKey(zone, a) != _dayKey(zone, b)) continue;
    final m = b.difference(a).inSeconds / 60;
    if (m >= 30 && m <= 360) points.add((at: b, minutes: m));
  }
  return _range(points, now, zone);
}

List<CareRecord> _sleeps(List<CareRecord> records, DateTime now) => [
  for (final r in _window(records, now))
    if (r.type == CareType.sleep &&
        r.endedAt != null &&
        !r.endedAt!.isAfter(now))
      r,
];

bool _overlaps(CareRecord r, List<CareRecord> all) => all.any(
  (o) =>
      o.id != r.id &&
      o.occurredAt.isBefore(r.endedAt!) &&
      o.endedAt!.isAfter(r.occurredAt),
);

/// Daytime sleeps (start 06:00–18:00, 10 min – 3 h), as `routinePatterns`' `day_sleep`.
RoutineRange? daySleepRange(
  List<CareRecord> records,
  DateTime now,
  String zone,
) {
  final sleeps = _sleeps(records, now);
  final points = <_Point>[
    for (final s in sleeps)
      if (!_isNight(zone, s.occurredAt) && !_overlaps(s, sleeps))
        if (s.endedAt!.difference(s.occurredAt).inSeconds / 60 case final m
            when m >= 10 && m <= 180)
          (at: s.occurredAt, minutes: m),
  ];
  return _range(points, now, zone);
}

/// Daytime awake stretches: from the end of one sleep to the start of the next, both on the same
/// local day, the waking in the day window (20 min – 6 h).
RoutineRange? awakeRange(List<CareRecord> records, DateTime now, String zone) {
  final sleeps = _sleeps(
    records,
    now,
  ).where((s) => !_overlaps(s, _sleeps(records, now))).toList();
  final points = <_Point>[];
  for (var i = 1; i < sleeps.length; i++) {
    final woke = sleeps[i - 1].endedAt!, next = sleeps[i].occurredAt;
    if (_dayKey(zone, woke) != _dayKey(zone, next) || _isNight(zone, woke)) {
      continue;
    }
    final m = next.difference(woke).inSeconds / 60;
    if (m >= 20 && m <= 360) points.add((at: next, minutes: m));
  }
  return _range(points, now, zone);
}

enum ComingUpKind { feed, sleep, wake }

/// One line of "Sắp tới": usually between [from] and [to], counted from [since].
class ComingUpRow {
  const ComingUpRow({
    required this.kind,
    required this.from,
    required this.to,
    required this.since,
  });

  final ComingUpKind kind;
  final DateTime from;
  final DateTime to;

  /// The last feed's start, the waking, or the start of the running sleep.
  final DateTime since;
}

class ComingUp {
  const ComingUp({this.feed, this.sleep});

  final ComingUpRow? feed;

  /// The next sleep while awake, or the waking while a daytime sleep timer runs.
  final ComingUpRow? sleep;

  bool get isEmpty => feed == null && sleep == null;
}

/// How long ago a "since" may be and still mean today's rhythm (a parent who stopped logging).
const _staleAfter = Duration(hours: 6);

/// What usually comes next for this baby, from its own log. A row needs a usual range and a
/// recent start; nothing is guessed from other babies, ages or norms.
ComingUp comingUp({
  required List<CareRecord> records,
  required DateTime now,
  required String zone,
  DateTime? sleepTimerSince,
  bool feedTimerRunning = false,
}) {
  ComingUpRow? feed;
  if (!feedTimerRunning) {
    final range = feedIntervalRange(records, now, zone);
    final last = _window(records, now).where(_isFeed).lastOrNull;
    if (range != null &&
        last != null &&
        now.difference(last.occurredAt) < _staleAfter) {
      feed = ComingUpRow(
        kind: ComingUpKind.feed,
        from: last.occurredAt.add(Duration(minutes: range.lowMinutes)),
        to: last.occurredAt.add(Duration(minutes: range.highMinutes)),
        since: last.occurredAt,
      );
    }
  }

  ComingUpRow? sleep;
  if (sleepTimerSince != null) {
    // A night sleep has no daytime pattern to follow; only naps get a waking range.
    final range = _isNight(zone, sleepTimerSince)
        ? null
        : daySleepRange(records, now, zone);
    if (range != null) {
      sleep = ComingUpRow(
        kind: ComingUpKind.wake,
        from: sleepTimerSince.add(Duration(minutes: range.lowMinutes)),
        to: sleepTimerSince.add(Duration(minutes: range.highMinutes)),
        since: sleepTimerSince,
      );
    }
  } else {
    final woke = _sleeps(records, now).lastOrNull?.endedAt;
    final range = awakeRange(records, now, zone);
    if (woke != null &&
        range != null &&
        !_isNight(zone, woke) &&
        now.difference(woke) < _staleAfter) {
      final from = woke.add(Duration(minutes: range.lowMinutes));
      // A next sleep in the night window is bedtime, not a nap: the daytime range says nothing.
      if (!_isNight(zone, from)) {
        sleep = ComingUpRow(
          kind: ComingUpKind.sleep,
          from: from,
          to: woke.add(Duration(minutes: range.highMinutes)),
          since: woke,
        );
      }
    }
  }
  return ComingUp(feed: feed, sleep: sleep);
}

// ---------- "Bé dậy chưa?" (lumi-plan §7.1, L6) ----------

int _median(List<int> xs) {
  final s = [...xs]..sort();
  return s.length.isOdd
      ? s[s.length ~/ 2]
      : ((s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2).round();
}

int? _minutesOf(String? hhmm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm ?? '');
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

/// [at] (UTC) moved to [minutes] after local midnight of the same baby-zone day, as UTC. The zone
/// offset is taken from [at], which is exact away from a DST change on that day.
DateTime _atLocalMinutes(String zone, DateTime at, int minutes) {
  final local = inBabyZone(zone, at);
  final offset = DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
  ).difference(at.toUtc());
  final midnight = DateTime.utc(local.year, local.month, local.day);
  return midnight.add(Duration(minutes: minutes)).subtract(offset);
}

/// The person's usual first log of the morning (median start, 05:00–11:00, last 14 days), else
/// 07:00; never before the end of the night window.
int usualMorningMinutes(List<CareRecord> records, DateTime now, String zone) {
  final firsts = <String, int>{};
  for (final r in _window(records, now)) {
    final l = inBabyZone(zone, r.occurredAt);
    final m = l.hour * 60 + l.minute;
    if (m < 5 * 60 || m >= 11 * 60) continue;
    final key = _dayKey(zone, r.occurredAt);
    if (!firsts.containsKey(key) || m < firsts[key]!) firsts[key] = m;
  }
  final usual = firsts.length >= 3 ? _median(firsts.values.toList()) : 7 * 60;
  return usual < nightToHour * 60 ? nightToHour * 60 : usual;
}

bool _inQuiet(String zone, DateTime at, int? quietFrom, int? quietTo) {
  if (quietFrom == null || quietTo == null || quietFrom == quietTo) {
    return false;
  }
  final l = inBabyZone(zone, at);
  final m = l.hour * 60 + l.minute;
  return quietFrom < quietTo
      ? (m >= quietFrom && m < quietTo)
      : (m >= quietFrom || m < quietTo);
}

/// When to ask "Bé dậy chưa?" for a sleep timer started at [start], or null when there is nothing
/// to ask (already past). From this baby's sleeps of the same kind (nap or night by the start):
/// max(median × 1.3, median + 20 min) with at least five of them; else a nap asks after 2 h 30 and
/// a night only in the morning. Never in the night window or the person's quiet hours: then it
/// asks at the person's usual first log of the morning (or the end of the quiet hours).
DateTime? wakeCheckAt({
  required List<CareRecord> records,
  required DateTime start,
  required DateTime now,
  required String zone,
  String? quietFrom,
  String? quietTo,
}) => wakeCheckTimes(
  records: records,
  start: start,
  now: now,
  zone: zone,
  quietFrom: quietFrom,
  quietTo: quietTo,
)?.ask;

/// [wakeCheckAt] with what "Vẫn ngủ" needs (lumi-plan §7.1): it asks once more after half the
/// expected length (at least 30 min), and only before [until], the first moment from [ask] in
/// the night window or the quiet hours (or the timer's 18-hour limit).
({DateTime ask, int againMinutes, DateTime until})? wakeCheckTimes({
  required List<CareRecord> records,
  required DateTime start,
  required DateTime now,
  required String zone,
  String? quietFrom,
  String? quietTo,
}) {
  final night = _isNight(zone, start);
  final same = [
    for (final s in _sleeps(records, now))
      if (_isNight(zone, s.occurredAt) == night)
        if (s.endedAt!.difference(s.occurredAt).inMinutes case final m
            when m >= 10 && m <= 18 * 60)
          m,
  ];
  final morning = usualMorningMinutes(records, now, zone);
  DateTime nextMorning(DateTime after) {
    var at = _atLocalMinutes(zone, after, morning);
    if (!at.isAfter(after)) {
      at = _atLocalMinutes(zone, after.add(const Duration(days: 1)), morning);
    }
    return at;
  }

  DateTime ask;
  // A night with few sleeps to go by is asked in the morning: 30 min later is enough.
  final expected = same.length >= 5 ? _median(same) : (night ? 60 : 150);
  if (same.length >= 5) {
    final med = expected;
    final wait = (med * 1.3).round() > med + 20
        ? (med * 1.3).round()
        : med + 20;
    ask = start.add(Duration(minutes: wait));
  } else if (!night) {
    ask = start.add(const Duration(minutes: 150));
  } else {
    ask = nextMorning(start);
  }
  if (_isNight(zone, ask)) ask = nextMorning(ask);
  final qFrom = _minutesOf(quietFrom), qTo = _minutesOf(quietTo);
  if (_inQuiet(zone, ask, qFrom, qTo)) {
    var end = _atLocalMinutes(zone, ask, qTo!);
    if (!end.isAfter(ask)) {
      end = _atLocalMinutes(zone, ask.add(const Duration(days: 1)), qTo);
    }
    ask = end;
    if (_isNight(zone, ask)) ask = nextMorning(ask);
  }
  // The timer's own 18-hour review takes over beyond that (lumi-plan §7.1).
  final limit = start.add(const Duration(hours: 18));
  if (ask.isAfter(limit) || !ask.isAfter(now)) return null;
  var until = ask;
  while (until.isBefore(limit) &&
      !_isNight(zone, until) &&
      !_inQuiet(zone, until, qFrom, qTo)) {
    until = until.add(const Duration(minutes: 5));
  }
  return (
    ask: ask,
    againMinutes: expected ~/ 2 < 30 ? 30 : expected ~/ 2,
    until: until.isAfter(limit) ? limit : until,
  );
}
