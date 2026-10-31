import 'package:flutter/foundation.dart';

import 'care_models.dart';
import 'care_repository.dart' show babyDayBounds, inBabyZone;

/// Business calculations behind History (20–20f) and Statistics (20g–20h), free of UI and
/// Firebase so every number is unit-tested. All days and hours are in the baby's time zone
/// (R-061). Rules quoted from extract 02 "Computation rules" and D-027 / D-028.

/// TimeSectionHeader (59:431): Sáng 05–11 · Trưa 11–13 · Chiều 13–18 · Tối 18–22 · Đêm 22–05.
enum CarePeriod { lateNight, evening, afternoon, noon, morning, night }

CarePeriod periodOfHour(int hour) => switch (hour) {
  >= 22 => CarePeriod.lateNight,
  >= 18 => CarePeriod.evening,
  >= 13 => CarePeriod.afternoon,
  >= 11 => CarePeriod.noon,
  >= 5 => CarePeriod.morning,
  _ => CarePeriod.night,
};

/// A record's place on a day's timeline. Spans that started the day before keep their real
/// start (D-027) but are placed at the day's start.
@immutable
class TimelineEntry {
  const TimelineEntry({
    required this.record,
    required this.period,
    required this.startedBefore,
  });

  final CareRecord record;
  final CarePeriod period;

  /// "21:42 hôm qua – 06:30".
  final bool startedBefore;
}

bool touchesDay(CareRecord r, DateTime start, DateTime end) {
  if (r.endedAt == null) {
    return !r.occurredAt.isBefore(start) && r.occurredAt.isBefore(end);
  }
  return r.occurredAt.isBefore(end) && r.endedAt!.isAfter(start);
}

/// Newest first, grouped by period; only records that fall on the day.
List<TimelineEntry> timelineOf(
  Iterable<CareRecord> records,
  String zone,
  DateTime dayStart,
  DateTime dayEnd,
) {
  final entries = <TimelineEntry>[];
  for (final r in records) {
    if (r.deleted || !touchesDay(r, dayStart, dayEnd)) continue;
    final before = r.occurredAt.isBefore(dayStart);
    final placed = before ? dayStart : r.occurredAt;
    entries.add(
      TimelineEntry(
        record: r,
        period: periodOfHour(inBabyZone(zone, placed).hour),
        startedBefore: before,
      ),
    );
  }
  entries.sort((a, b) {
    final ta = a.startedBefore ? dayStart : a.record.occurredAt;
    final tb = b.startedBefore ? dayStart : b.record.occurredAt;
    return tb.compareTo(ta);
  });
  return entries;
}

Duration _overlap(
  DateTime aStart,
  DateTime aEnd,
  DateTime bStart,
  DateTime bEnd,
) {
  final from = aStart.isAfter(bStart) ? aStart : bStart;
  final to = aEnd.isBefore(bEnd) ? aEnd : bEnd;
  return to.isAfter(from) ? to.difference(from) : Duration.zero;
}

bool _isFeed(CareRecord r) =>
    r.type == CareType.bottle || r.type == CareType.breast;

/// 20a "Bú hôm nay".
@immutable
class FeedDay {
  const FeedDay({
    required this.bottleCount,
    required this.bottleMl,
    required this.breastCount,
    required this.breastMinutes,
    required this.lastFeedAt,
    required this.averageGap,
  });

  final int bottleCount;
  final int bottleMl;
  final int breastCount;
  final int breastMinutes;

  /// "Cữ gần nhất": start of the last feed (bottle or breast).
  final DateTime? lastFeedAt;

  /// "Cách nhau trung bình": mean gap between consecutive feed starts in the day.
  final Duration? averageGap;
}

Duration? _meanGap(List<DateTime> starts) {
  if (starts.length < 2) return null;
  final sorted = [...starts]..sort();
  var total = Duration.zero;
  for (var i = 1; i < sorted.length; i++) {
    total += sorted[i].difference(sorted[i - 1]);
  }
  return Duration(seconds: total.inSeconds ~/ (sorted.length - 1));
}

FeedDay feedDay(Iterable<CareRecord> records, DateTime start, DateTime end) {
  final feeds = [
    for (final r in records)
      if (!r.deleted &&
          _isFeed(r) &&
          !r.occurredAt.isBefore(start) &&
          r.occurredAt.isBefore(end))
        r,
  ];
  final starts = [for (final r in feeds) r.occurredAt];
  return FeedDay(
    bottleCount: feeds.where((r) => r.type == CareType.bottle).length,
    bottleMl: feeds
        .where((r) => r.type == CareType.bottle)
        .fold(0, (s, r) => s + (r.amountMl ?? 0)),
    breastCount: feeds.where((r) => r.type == CareType.breast).length,
    breastMinutes: feeds
        .where((r) => r.type == CareType.breast)
        .fold(0, (s, r) => s + (r.durationMin ?? 0)),
    lastFeedAt: starts.isEmpty
        ? null
        : starts.reduce((a, b) => a.isAfter(b) ? a : b),
    averageGap: _meanGap(starts),
  );
}

/// 20b "Ngủ hôm nay" (finished sleeps; a running one is not counted, R-076).
@immutable
class SleepDay {
  const SleepDay({
    required this.total,
    required this.count,
    required this.longest,
    required this.lastWokeAt,
  });

  /// Clipped to the day.
  final Duration total;

  /// Sleeps touching the day.
  final int count;

  /// D-027: the longest full sleep that ended on this day.
  final Duration longest;

  /// "Đang thức … · từ 13:05".
  final DateTime? lastWokeAt;
}

SleepDay sleepDay(Iterable<CareRecord> records, DateTime start, DateTime end) {
  var total = Duration.zero;
  var count = 0;
  var longest = Duration.zero;
  DateTime? woke;
  for (final r in records) {
    if (r.deleted || r.type != CareType.sleep || r.endedAt == null) continue;
    final part = _overlap(r.occurredAt, r.endedAt!, start, end);
    if (part > Duration.zero) {
      total += part;
      count++;
    }
    final endsToday = !r.endedAt!.isBefore(start) && r.endedAt!.isBefore(end);
    if (endsToday) {
      final full = r.endedAt!.difference(r.occurredAt);
      if (full > longest) longest = full;
      if (woke == null || r.endedAt!.isAfter(woke)) woke = r.endedAt;
    }
  }
  return SleepDay(
    total: total,
    count: count,
    longest: longest,
    lastWokeAt: woke,
  );
}

/// 20c "Tã hôm nay": "Cả hai" counts as both Ướt and Bẩn.
@immutable
class DiaperDay {
  const DiaperDay({
    required this.total,
    required this.wet,
    required this.dirty,
    required this.lastAt,
  });

  final int total;
  final int wet;
  final int dirty;
  final DateTime? lastAt;
}

DiaperDay diaperDay(
  Iterable<CareRecord> records,
  DateTime start,
  DateTime end,
) {
  var total = 0, wet = 0, dirty = 0;
  DateTime? last;
  for (final r in records) {
    if (r.deleted || r.type != CareType.diaper) continue;
    if (r.occurredAt.isBefore(start) || !r.occurredAt.isBefore(end)) continue;
    total++;
    if (r.diaper != DiaperKind.dirty) wet++;
    if (r.diaper != DiaperKind.wet) dirty++;
    if (last == null || r.occurredAt.isAfter(last)) last = r.occurredAt;
  }
  return DiaperDay(total: total, wet: wet, dirty: dirty, lastAt: last);
}

/// Pumping summary (no design; D-026 keeps it apart from intake).
@immutable
class PumpDay {
  const PumpDay({required this.count, required this.ml, required this.minutes});
  final int count;
  final int ml;
  final int minutes;
}

PumpDay pumpDay(Iterable<CareRecord> records, DateTime start, DateTime end) {
  var count = 0, ml = 0, minutes = 0;
  for (final r in records) {
    if (r.deleted || r.type != CareType.pump) continue;
    if (r.occurredAt.isBefore(start) || !r.occurredAt.isBefore(end)) continue;
    count++;
    ml += r.amountMl ?? 0;
    minutes += r.durationMin ?? 0;
  }
  return PumpDay(count: count, ml: ml, minutes: minutes);
}

// ---------- Statistics (20g / 20g2 / 20h) ----------

enum StatsWindow { today, week, month }

/// 20g "Loại bú" (v1.0 improvement 391:3185): all feeds, bottle only, breastfeeding only.
enum FeedKind { all, bottle, breast }

/// 20g "Tuỳ chọn" (391:3373): [days] whole local days ending on the day of [end].
typedef CustomRange = ({DateTime end, int days});

int daysOf(StatsWindow w) => switch (w) {
  StatsWindow.today => 1,
  StatsWindow.week => 7,
  StatsWindow.month => 30,
};

/// Local days of a window, oldest first, each as (start, end) instants.
List<({DateTime start, DateTime end})> windowDays(
  String zone,
  DateTime now,
  int days,
) {
  final today = babyDayBounds(zone, now);
  final list = <({DateTime start, DateTime end})>[];
  var cursor = today;
  for (var i = 0; i < days; i++) {
    list.insert(0, cursor);
    cursor = babyDayBounds(
      zone,
      cursor.start.subtract(const Duration(hours: 1)),
    );
  }
  return list;
}

/// The one night window of the app: 18:00–06:00 in the baby's zone (20g / 20h, R-086; D-151 #1
/// extends it to "Sắp tới", "Bé dậy chưa?" and Lumi). Mirrors contracts `careNightWindow`.
const careNightFromHour = 18;
const careNightToHour = 6;

bool isNightHour(int hour) =>
    hour >= careNightFromHour || hour < careNightToHour;

@immutable
class LongestGap {
  const LongestGap(this.from, this.to);
  final DateTime from;
  final DateTime to;
  Duration get length => to.difference(from);
}

LongestGap? longestGap(List<DateTime> starts) {
  if (starts.length < 2) return null;
  final sorted = [...starts]..sort();
  LongestGap? best;
  for (var i = 1; i < sorted.length; i++) {
    final gap = LongestGap(sorted[i - 1], sorted[i]);
    if (best == null || gap.length > best.length) best = gap;
  }
  return best;
}

/// Thống kê bú. For [StatsWindow.today] the window is 18:00 yesterday → now (20g2); for 7 / 30
/// days, whole local days ending today, averaged per day.
@immutable
class FeedStats {
  const FeedStats({
    required this.window,
    required this.bottleMl,
    required this.feeds,
    required this.bottleFeeds,
    required this.breastFeeds,
    required this.averageGap,
    required this.dayMl,
    required this.nightMl,
    required this.dayFeeds,
    required this.nightFeeds,
    required this.lastNightFeeds,
    required this.lastNightGap,
    required this.hourlyMl,
    required this.breastPerDay,
    required this.breastMinutesPerFeed,
    required this.leftMinutes,
    required this.rightMinutes,
    required this.nextSide,
    required this.todayFeeds,
    this.days = const [],
    this.dayMinutes = 0,
    this.nightMinutes = 0,
    this.lastNightBreasts = 0,
    this.lastNightBreastMinutes = 0,
    this.lastNightBreastFrom,
    this.lastNightBreastTo,
  });

  /// Bú mẹ day / night by minutes (per-day averages; today: totals).
  final int dayMinutes;
  final int nightMinutes;

  /// "Đêm qua bú mẹ 1 cữ, 16 phút (02:10)." (346:590).
  final int lastNightBreasts;
  final int lastNightBreastMinutes;
  final DateTime? lastNightBreastFrom;
  final DateTime? lastNightBreastTo;

  final StatsWindow window;

  /// 20g "Bú mỗi ngày" (v1.0 improvement): each day of a 7 / 30-day window, oldest first.
  final List<FeedDayBar> days;

  /// Today: totals in the window. 7 / 30: per-day averages (rounded).
  final int bottleMl;
  final int feeds;
  final int bottleFeeds;
  final int breastFeeds;
  final Duration? averageGap;

  /// Day 06–18 vs night 18–06 by bottle ml (percent by ml) and feed counts. Today: "Hôm nay
  /// từ 06:00" vs "Đêm qua 18–06"; 7 / 30: per-day averages.
  final int dayMl;
  final int nightMl;
  final int dayFeeds;
  final int nightFeeds;

  /// "Đêm qua bú 3 cữ, khoảng nghỉ dài nhất …" (last 18:00 → 06:00).
  final int lastNightFeeds;
  final LongestGap? lastNightGap;

  /// 7 / 30: average bottle ml per clock hour 0–23.
  final List<double> hourlyMl;

  final double breastPerDay;
  final int breastMinutesPerFeed;
  final int leftMinutes;
  final int rightMinutes;

  /// "Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái".
  final Side? nextSide;

  /// 20g2 "Từng cữ hôm nay": the calendar day's feeds.
  final List<CareRecord> todayFeeds;

  int? get peakHour {
    if (hourlyMl.every((v) => v == 0)) return null;
    var best = 0;
    for (var h = 1; h < 24; h++) {
      if (hourlyMl[h] > hourlyMl[best]) best = h;
    }
    return best;
  }
}

({int left, int right}) _sides(CareRecord r) {
  if (r.leftMin != null || r.rightMin != null) {
    return (left: r.leftMin ?? 0, right: r.rightMin ?? 0);
  }
  final m = r.durationMin ?? 0;
  return switch (r.side) {
    Side.left => (left: m, right: 0),
    Side.right => (left: 0, right: m),
    _ => (left: m ~/ 2, right: m - m ~/ 2),
  };
}

FeedStats feedStats(
  Iterable<CareRecord> all,
  String zone,
  DateTime now,
  StatsWindow window, {
  FeedKind kind = FeedKind.all,
  CustomRange? custom,
}) {
  final live = [
    for (final r in all)
      if (!r.deleted &&
          _isFeed(r) &&
          switch (kind) {
            FeedKind.all => true,
            FeedKind.bottle => r.type == CareType.bottle,
            FeedKind.breast => r.type == CareType.breast,
          })
        r,
  ];
  final today = babyDayBounds(zone, now);
  if (custom != null) window = StatsWindow.month;
  final days = custom?.days ?? daysOf(window);
  // The last day of the window: today, or the custom range's end.
  final anchor = custom?.end ?? now;
  final DateTime from;
  final DateTime to;
  if (custom != null) {
    from = windowDays(zone, anchor, days).first.start;
    to = babyDayBounds(zone, anchor).end;
  } else if (window == StatsWindow.today) {
    from = today.start.subtract(const Duration(hours: 6)); // 18:00 yesterday
    // To the end of the day, not `now`: the care clock is minute-aligned, and a feed logged
    // earlier in this minute must already count (records are never in the future, G-021).
    to = today.end;
  } else {
    from = windowDays(zone, now, days).first.start;
    to = today.end;
  }
  final feeds = [
    for (final r in live)
      if (!r.occurredAt.isBefore(from) && r.occurredAt.isBefore(to)) r,
  ];
  final bottles = feeds.where((r) => r.type == CareType.bottle).toList();
  final breasts = feeds.where((r) => r.type == CareType.breast).toList();
  final per = window == StatsWindow.today ? 1 : days;

  var dayMl = 0, nightMl = 0, dayFeeds = 0, nightFeeds = 0;
  var dayMinutes = 0, nightMinutes = 0;
  final hourly = List<double>.filled(24, 0);
  for (final r in feeds) {
    final hour = inBabyZone(zone, r.occurredAt).hour;
    final night = window == StatsWindow.today
        ? r.occurredAt.isBefore(today.start.add(const Duration(hours: 6)))
        : isNightHour(hour);
    final minutes = r.type == CareType.breast ? (r.durationMin ?? 0) : 0;
    if (night) {
      nightFeeds++;
      nightMl += r.amountMl ?? 0;
      nightMinutes += minutes;
    } else {
      dayFeeds++;
      dayMl += r.amountMl ?? 0;
      dayMinutes += minutes;
    }
    if (r.type == CareType.bottle) hourly[hour] += (r.amountMl ?? 0) / per;
  }

  // Last night: 18:00 yesterday → 06:00 today (or now, before 06:00).
  final sixToday = today.start.add(const Duration(hours: 6));
  final lastNightStart = today.start.subtract(const Duration(hours: 6));
  final lastNightEnd = now.isBefore(sixToday) ? now : sixToday;
  final lastNight = [
    for (final r in live)
      if (!r.occurredAt.isBefore(lastNightStart) &&
          r.occurredAt.isBefore(lastNightEnd))
        r,
  ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  final nightStarts = [for (final r in lastNight) r.occurredAt];
  final nightBreasts = lastNight.where((r) => r.type == CareType.breast);

  var left = 0, right = 0, breastMinutes = 0;
  for (final r in breasts) {
    final s = _sides(r);
    left += s.left;
    right += s.right;
    breastMinutes += r.durationMin ?? 0;
  }
  final lastBreast = [...live.where((r) => r.type == CareType.breast)]
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final endSide =
      lastBreast.firstOrNull?.endSide ??
      (lastBreast.firstOrNull?.side == Side.both
          ? null
          : lastBreast.firstOrNull?.side);

  int avg(int v) => (v / per).round();
  return FeedStats(
    window: window,
    bottleMl: avg(bottles.fold(0, (s, r) => s + (r.amountMl ?? 0))),
    feeds: avg(feeds.length),
    bottleFeeds: avg(bottles.length),
    breastFeeds: avg(breasts.length),
    averageGap: _meanGap([for (final r in feeds) r.occurredAt]),
    dayMl: avg(dayMl),
    nightMl: avg(nightMl),
    dayFeeds: avg(dayFeeds),
    nightFeeds: avg(nightFeeds),
    dayMinutes: avg(dayMinutes),
    nightMinutes: avg(nightMinutes),
    lastNightBreasts: nightBreasts.length,
    lastNightBreastMinutes: nightBreasts.fold(
      0,
      (t, r) => t + (r.durationMin ?? 0),
    ),
    lastNightBreastFrom: nightBreasts.firstOrNull?.occurredAt,
    lastNightBreastTo: nightBreasts.lastOrNull?.occurredAt,
    lastNightFeeds: nightStarts.length,
    lastNightGap: longestGap(nightStarts),
    hourlyMl: hourly,
    breastPerDay: breasts.length / per,
    breastMinutesPerFeed: breasts.isEmpty
        ? 0
        : (breastMinutes / breasts.length).round(),
    leftMinutes: left,
    rightMinutes: right,
    nextSide: switch (endSide) {
      Side.left => Side.right,
      Side.right => Side.left,
      _ => null,
    },
    todayFeeds: [
      for (final r in live)
        if (!r.occurredAt.isBefore(today.start) &&
            r.occurredAt.isBefore(today.end))
          r,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)),
    days: window == StatsWindow.today
        ? const []
        : [
            for (final d in windowDays(zone, anchor, days))
              () {
                final inDay = [
                  for (final r in feeds)
                    if (!r.occurredAt.isBefore(d.start) &&
                        r.occurredAt.isBefore(d.end))
                      r,
                ];
                final b = inDay.where((r) => r.type == CareType.bottle);
                final m = inDay.where((r) => r.type == CareType.breast);
                int ml(MilkType? milk) => b
                    .where((r) => milk == null || r.milk == milk)
                    .fold(0, (s, r) => s + (r.amountMl ?? 0));
                final sides = [for (final r in m) _sides(r)];
                return FeedDayBar(
                  start: d.start,
                  bottles: b.length,
                  breasts: m.length,
                  bottleMl: ml(null),
                  breastMinutes: m.fold(0, (s, r) => s + (r.durationMin ?? 0)),
                  // No milk recorded counts as formula (the sheet's default is "Sữa mẹ";
                  // older records without it are bottle formula, inferred).
                  breastMilkMl: ml(MilkType.breastMilk),
                  formulaMl: ml(null) - ml(MilkType.breastMilk),
                  leftMinutes: sides.fold(0, (s, x) => s + x.left),
                  rightMinutes: sides.fold(0, (s, x) => s + x.right),
                );
              }(),
          ],
  );
}

/// One day of "Bú mỗi ngày": feeds by kind, bottle ml and breastfeeding minutes.
@immutable
class FeedDayBar {
  const FeedDayBar({
    required this.start,
    required this.bottles,
    required this.breasts,
    required this.bottleMl,
    required this.breastMinutes,
    this.breastMilkMl = 0,
    this.formulaMl = 0,
    this.leftMinutes = 0,
    this.rightMinutes = 0,
  });

  final DateTime start;
  final int bottles;
  final int breasts;
  final int bottleMl;
  final int breastMinutes;

  /// Bú bình: "Sữa mẹ vắt" / "Sữa công thức" ml (346:354).
  final int breastMilkMl;
  final int formulaMl;

  /// Bú mẹ: minutes per side (346:590).
  final int leftMinutes;
  final int rightMinutes;

  int get feeds => bottles + breasts;
}

/// One sleep piece on a day row of "Nhịp ngủ" (split at midnight), in hours 0–24.
@immutable
class SleepBar {
  const SleepBar(this.fromHour, this.toHour);
  final double fromHour;
  final double toHour;
}

@immutable
class SleepDayRow {
  const SleepDayRow({
    required this.start,
    required this.bars,
    required this.longest,
    required this.total,
    this.night = Duration.zero,
    this.day = Duration.zero,
  });

  final DateTime start;
  final List<SleepBar> bars;

  /// 20h "Tổng giờ ngủ mỗi ngày": sleep in the night window (18–06) and in the day (06–18).
  final Duration night;
  final Duration day;

  /// D-027: the longest full sleep that ended this day.
  final Duration longest;
  final Duration total;
}

/// Thống kê ngủ (20h; Hôm nay and 30 ngày per D-028).
@immutable
class SleepStats {
  const SleepStats({
    required this.window,
    required this.perDay,
    required this.sleepsPerDay,
    required this.longest,
    required this.nightPerDay,
    required this.dayPerDay,
    required this.nightCounts,
    required this.dayCounts,
    required this.rows,
    required this.firstNightLongest,
    required this.lastNightLongest,
  });

  final StatsWindow window;
  final Duration perDay;
  final double sleepsPerDay;
  final Duration longest;
  final Duration nightPerDay;
  final Duration dayPerDay;

  /// Sleeps per day starting at night / in the day: (min, max) across the window.
  final (int, int) nightCounts;
  final (int, int) dayCounts;
  final List<SleepDayRow> rows;

  /// "Giấc đêm dài nhất tăng từ 3 giờ 30 lên 6 giờ 30 trong 7 ngày."
  final Duration firstNightLongest;
  final Duration lastNightLongest;
}

SleepStats sleepStats(
  Iterable<CareRecord> all,
  String zone,
  DateTime now,
  StatsWindow window,
) {
  final sleeps = [
    for (final r in all)
      if (!r.deleted && r.type == CareType.sleep && r.endedAt != null) r,
  ];
  final days = windowDays(zone, now, daysOf(window));
  var total = Duration.zero, night = Duration.zero, day = Duration.zero;
  var count = 0;
  var longest = Duration.zero;
  final nightCounts = <int>[];
  final dayCounts = <int>[];
  final rows = <SleepDayRow>[];
  final nightLongest = <Duration>[];
  for (final d in days) {
    final bars = <SleepBar>[];
    var dayTotal = Duration.zero;
    var dayLongest = Duration.zero;
    var nightLong = Duration.zero;
    var rowNight = Duration.zero, rowDay = Duration.zero;
    var n = 0, dd = 0;
    for (final r in sleeps) {
      final part = _overlap(r.occurredAt, r.endedAt!, d.start, d.end);
      if (part > Duration.zero) {
        final from = r.occurredAt.isBefore(d.start) ? d.start : r.occurredAt;
        final to = r.endedAt!.isAfter(d.end) ? d.end : r.endedAt!;
        double h(DateTime t) => t.difference(d.start).inMinutes / 60;
        bars.add(SleepBar(h(from), h(to)));
        dayTotal += part;
        // Night / day share by duration, in 30-minute steps of the piece.
        for (
          var t = from;
          t.isBefore(to);
          t = t.add(const Duration(minutes: 30))
        ) {
          final step = to.difference(t) < const Duration(minutes: 30)
              ? to.difference(t)
              : const Duration(minutes: 30);
          if (isNightHour(inBabyZone(zone, t).hour)) {
            night += step;
            rowNight += step;
          } else {
            day += step;
            rowDay += step;
          }
        }
      }
      final ends = !r.endedAt!.isBefore(d.start) && r.endedAt!.isBefore(d.end);
      if (ends) {
        count++;
        final full = r.endedAt!.difference(r.occurredAt);
        if (full > dayLongest) dayLongest = full;
        if (isNightHour(inBabyZone(zone, r.occurredAt).hour)) {
          n++;
          if (full > nightLong) nightLong = full;
        } else {
          dd++;
        }
      }
    }
    bars.sort((a, b) => a.fromHour.compareTo(b.fromHour));
    rows.add(
      SleepDayRow(
        start: d.start,
        bars: bars,
        longest: dayLongest,
        total: dayTotal,
        night: rowNight,
        day: rowDay,
      ),
    );
    total += dayTotal;
    if (dayLongest > longest) longest = dayLongest;
    nightCounts.add(n);
    dayCounts.add(dd);
    nightLongest.add(nightLong);
  }
  final per = days.length;
  (int, int) range(List<int> v) => v.isEmpty
      ? (0, 0)
      : (v.reduce((a, b) => a < b ? a : b), v.reduce((a, b) => a > b ? a : b));
  return SleepStats(
    window: window,
    perDay: Duration(minutes: total.inMinutes ~/ per),
    sleepsPerDay: count / per,
    longest: longest,
    nightPerDay: Duration(minutes: night.inMinutes ~/ per),
    dayPerDay: Duration(minutes: day.inMinutes ~/ per),
    nightCounts: range(nightCounts),
    dayCounts: range(dayCounts),
    rows: rows,
    firstNightLongest: nightLongest.firstWhere(
      (d) => d > Duration.zero,
      orElse: () => Duration.zero,
    ),
    lastNightLongest: nightLongest.lastWhere(
      (d) => d > Duration.zero,
      orElse: () => Duration.zero,
    ),
  );
}
