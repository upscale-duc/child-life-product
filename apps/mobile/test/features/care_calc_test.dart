import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_calc.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';

/// Shared with packages/contracts/test/care.test.ts: both sides must compute the same day.
final _vectors =
    (jsonDecode(
              File(
                '../../packages/contracts/test/vectors/care-day.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>)['vectors']
        as List;

var _n = 0;
CareRecord _fromJson(Map<String, dynamic> j) {
  final data = (j['data'] as Map).cast<String, Object?>();
  return CareRecord(
    id: 'r_${(++_n).toRadixString(16).padLeft(32, '0')}',
    babyId: teddyId,
    type: CareType.values.byName(j['type'] as String),
    occurredAt: DateTime.parse(j['occurredAt'] as String),
    endedAt: j['endedAt'] == null
        ? null
        : DateTime.parse(j['endedAt'] as String),
    createdBy: 'u_mai',
    author: CareAuthor.of(mai),
    amountMl: (data['amountMl'] as num?)?.toInt(),
    durationMin: (data['durationMin'] as num?)?.toInt(),
    leftMin: (data['leftMin'] as num?)?.toInt(),
    rightMin: (data['rightMin'] as num?)?.toInt(),
    side: Side.values.asNameMap()[data['side']],
    endSide: Side.values.asNameMap()[data['endSide']],
    diaper: DiaperKind.values.asNameMap()[data['kind']],
  );
}

/// A reconciled week for Teddy (GMT+7), ending Thursday 8 Oct 15:05: every night a long sleep
/// that grows from 3 h 30 to 6 h 30, bottles at 00:20 / 04:00 / 08:00 / 14:20 / 21:00, one
/// breastfeed at 11:30 ended on the right.
List<CareRecord> _week() {
  DateTime vnAt(int day, int h, int m) => DateTime.utc(2026, 10, day, h - 7, m);
  final list = <CareRecord>[];
  CareRecord rec(
    CareType t,
    DateTime at, {
    DateTime? end,
    int? ml,
    int? min,
    Side? side,
    Side? endSide,
    int? l,
    int? r,
  }) => CareRecord(
    id: 'r_${(++_n).toRadixString(16).padLeft(32, '0')}',
    babyId: teddyId,
    type: t,
    occurredAt: at,
    endedAt: end,
    createdBy: 'u_mai',
    author: CareAuthor.of(mai),
    amountMl: ml,
    durationMin: min,
    side: side,
    endSide: endSide,
    leftMin: l,
    rightMin: r,
  );
  for (var d = 2; d <= 8; d++) {
    final i = d - 2; // 0..6
    // Night sleep ending the morning of day d: starts 22:00 of d-1, lasts 3 h 30 + 30 min/day.
    final nightStart = vnAt(d - 1, 22, 0);
    list.add(
      rec(
        CareType.sleep,
        nightStart,
        end: nightStart.add(Duration(minutes: 210 + 30 * i)),
      ),
    );
    list.add(rec(CareType.sleep, vnAt(d, 11, 45), end: vnAt(d, 13, 5)));
    for (final (h, m, ml) in [
      (0, 20, 90),
      (4, 0, 90),
      (8, 0, 120),
      (14, 20, 120),
    ]) {
      list.add(rec(CareType.bottle, vnAt(d, h, m), ml: ml));
    }
    if (d < 8) list.add(rec(CareType.bottle, vnAt(d, 21, 0), ml: 120));
    list.add(
      rec(
        CareType.breast,
        vnAt(d, 11, 30),
        end: vnAt(d, 11, 45),
        min: 15,
        side: Side.both,
        endSide: Side.right,
        l: 8,
        r: 7,
      ),
    );
  }
  return list;
}

void main() {
  setUpAll(ensureTimeZones);

  group('shared day vectors (TS ↔ Dart)', () {
    for (final v in _vectors.cast<Map<String, dynamic>>()) {
      test(v['name'] as String, () {
        final zone = v['zone'] as String;
        final date = DateTime.parse('${v['date']}T12:00:00Z');
        // Noon UTC is inside the local day for both test zones.
        final day = babyDayBounds(zone, date);
        final records = [
          for (final r in (v['records'] as List)) _fromJson((r as Map).cast()),
        ];
        final e = (v['expect'] as Map).cast<String, dynamic>();
        final totals = DayTotals.of(records, day.start, day.end);
        expect(totals.bottleCount, e['bottle']['count']);
        expect(totals.bottleMl, e['bottle']['ml']);
        expect(totals.breastCount, e['breast']['count']);
        expect(totals.breastMinutes, e['breast']['minutes']);
        expect(totals.sleepMinutes, e['sleepMinutes']);
        expect(totals.diaperCount, e['diaper']['count']);
        final diapers = diaperDay(records, day.start, day.end);
        expect(diapers.wet, e['diaper']['wet']);
        expect(diapers.dirty, e['diaper']['dirty']);
        final pump = pumpDay(records, day.start, day.end);
        expect(pump.ml, e['pump']['ml']);
        expect(
          feedDay(records, day.start, day.end).averageGap?.inMinutes,
          e['feedGapMinutes'],
        );
        final sleep = sleepDay(records, day.start, day.end);
        expect(sleep.count, e['sleepCount']);
        expect(sleep.longest.inMinutes, e['longestSleepMinutes']);
      });
    }
  });

  group('history day (20 – 20c)', () {
    final v = (_vectors.first as Map).cast<String, dynamic>();
    final records = [
      for (final r in (v['records'] as List)) _fromJson((r as Map).cast()),
    ];
    final zone = v['zone'] as String;
    final day = babyDayBounds(zone, DateTime.utc(2026, 10, 8, 5));

    test(
      'timeline: newest first, by period; the overnight sleep keeps its real start',
      () {
        final t = timelineOf(records, zone, day.start, day.end);
        expect(t.first.record.amountMl, 120); // 14:20
        expect(t.first.period, CarePeriod.afternoon);
        expect(t.last.record.type, CareType.sleep);
        expect(t.last.startedBefore, isTrue);
        expect(t.last.period, CarePeriod.night);
        expect(t.map((e) => e.period).toSet(), {
          CarePeriod.afternoon,
          CarePeriod.noon,
          CarePeriod.morning,
          CarePeriod.night,
        });
      },
    );

    test('Bú: last feed and mean gap 08:00 / 11:30 / 14:20 → 3 h 10', () {
      final f = feedDay(records, day.start, day.end);
      expect(f.averageGap, const Duration(hours: 3, minutes: 10));
      expect(f.lastFeedAt, DateTime.utc(2026, 10, 8, 7, 20));
    });

    test(
      'Ngủ: total clipped, longest the full overnight sleep (D-027), awake since 13:05',
      () {
        final s = sleepDay(records, day.start, day.end);
        expect(s.total, const Duration(hours: 7, minutes: 50));
        expect(s.longest, const Duration(hours: 8, minutes: 48));
        expect(s.lastWokeAt, DateTime.utc(2026, 10, 8, 6, 5));
      },
    );

    test('periods follow 59:431', () {
      expect(periodOfHour(4), CarePeriod.night);
      expect(periodOfHour(5), CarePeriod.morning);
      expect(periodOfHour(11), CarePeriod.noon);
      expect(periodOfHour(13), CarePeriod.afternoon);
      expect(periodOfHour(18), CarePeriod.evening);
      expect(periodOfHour(22), CarePeriod.lateNight);
    });
  });

  group('statistics (20g, 20g2, 20h)', () {
    const zone = 'Asia/Ho_Chi_Minh';
    final now = DateTime.utc(2026, 10, 8, 8, 5); // 15:05
    final week = _week();

    test('feeding, Hôm nay = 18:00 yesterday → now', () {
      final s = feedStats(week, zone, now, StatsWindow.today);
      // 21:00 yesterday 120 + 00:20 90 + 04:00 90 + 08:00 120 + 14:20 120
      expect(s.bottleMl, 540);
      expect(s.bottleFeeds, 5);
      expect(s.breastFeeds, 1);
      expect(s.nightMl, 300, reason: 'Đêm qua 18–06');
      expect(s.dayMl, 240, reason: 'Hôm nay từ 06:00');
      expect(s.lastNightFeeds, 3);
      expect(s.lastNightGap!.length, const Duration(hours: 3, minutes: 40));
      expect(s.leftMinutes, 8);
      expect(s.rightMinutes, 7);
      expect(s.nextSide, Side.left);
      expect(s.todayFeeds, hasLength(5));
    });

    test('Hôm nay counts a feed logged earlier in the current minute', () {
      final justNow = DateTime.utc(2026, 10, 8, 8, 5, 40); // 15:05:40
      final minute = DateTime.utc(2026, 10, 8, 8, 5); // what the clock says
      final r = CareRecord(
        id: 'r_${'f' * 32}',
        babyId: teddyId,
        type: CareType.bottle,
        occurredAt: justNow,
        createdBy: 'u_mai',
        author: CareAuthor.of(mai),
        amountMl: 120,
      );
      final s = feedStats([r], zone, minute, StatsWindow.today);
      expect(s.bottleMl, 120);
    });

    test('feeding, 7 ngày: per-day averages and the peak hour', () {
      final s = feedStats(week, zone, now, StatsWindow.week);
      // 6 full days × 540 ml + today 420 ml = 3660 / 7 ≈ 523
      expect(s.bottleMl, 523);
      expect(s.breastPerDay, 1);
      expect(s.breastMinutesPerFeed, 15);
      expect(s.peakHour, 8);
      expect(s.hourlyMl[8], closeTo(120, 0.01));
    });

    test(
      'sleep, 7 ngày: night grows 3 h 30 → 6 h 30, longest per day, rows split at midnight',
      () {
        final s = sleepStats(week, zone, now, StatsWindow.week);
        expect(s.rows, hasLength(7));
        expect(s.firstNightLongest, const Duration(hours: 3, minutes: 30));
        expect(s.lastNightLongest, const Duration(hours: 6, minutes: 30));
        expect(s.longest, const Duration(hours: 6, minutes: 30));
        expect(s.rows.last.bars.first.fromHour, 0);
        expect(s.rows.last.longest, const Duration(hours: 6, minutes: 30));
        expect(s.sleepsPerDay, 2);
      },
    );

    test('30 ngày and Hôm nay reuse the same calculation (D-028)', () {
      expect(
        sleepStats(week, zone, now, StatsWindow.month).rows,
        hasLength(30),
      );
      expect(sleepStats(week, zone, now, StatsWindow.today).rows, hasLength(1));
    });
  });
}
