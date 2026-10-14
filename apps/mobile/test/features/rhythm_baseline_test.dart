import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';

/// Nhịp lớn lên part 2 (plan §7.1 R2): the sleep facts computed on the phone. The baseline runs
/// the contracts' fixture pack (`premium-v2.json`, B01–B06); valid days mirror the cases in
/// `packages/contracts/test/rhythm.test.ts` (D-073 #1: automatic, missing is never zero).
final _pack =
    jsonDecode(
          File(
            '../../packages/contracts/test/vectors/premium-v2.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const _zone = 'Asia/Ho_Chi_Minh';

/// [h]:[m] on 13 Oct 2026 (or [day]) in Hồ Chí Minh.
DateTime _at(int h, [int m = 0, int day = 13]) =>
    DateTime.utc(2026, 10, day, h - 7, m);

CareSpan _sleep(DateTime a, DateTime? b) =>
    (sleep: true, occurredAt: a, endedAt: b);
CareSpan _feed(DateTime a) => (sleep: false, occurredAt: a, endedAt: null);

final _now = DateTime.utc(2026, 10, 15);
final _fullDay = [
  _sleep(_at(0, 0, 13), _at(5, 0, 13)),
  _feed(_at(5, 30)),
  _sleep(_at(8), _at(10)),
  _feed(_at(11)),
  _feed(_at(14)),
  _sleep(_at(15), _at(16)),
  _feed(_at(18)),
  _sleep(_at(20), _at(23, 59)),
];

DayQuality _q(
  List<CareSpan> records, {
  DateTime? now,
  DateTime? timer,
  int conflicts = 0,
}) => dayQuality(
  zone: _zone,
  date: '2026-10-13',
  now: now ?? _now,
  records: records,
  openSleepTimerSince: timer,
  openConflicts: conflicts,
);

void main() {
  group('fixture pack · baseline B01–B06', () {
    final cases = [
      for (final c in _pack['cases'] as List)
        if ((c as Map)['kind'] == 'baseline') c.cast<String, dynamic>(),
    ];
    test('has the six cases', () {
      expect(
        [for (final c in cases) c['id']],
        ['B01', 'B02', 'B03', 'B04', 'B05', 'B06'],
      );
    });
    for (final c in cases) {
      test('${c['id']} → ${(c['expected'] as Map)['status']}', () {
        final input = (c['input'] as Map).cast<String, dynamic>();
        List<num?> minutes(Object? v) => [
          for (final x in v! as List) x as num?,
        ];
        final r = sleepBaseline(
          minutes(input['baseline_minutes']),
          minutes(input['recent_minutes']),
        );
        final expected = (c['expected'] as Map).cast<String, dynamic>();
        expect(r.status.wire, expected['status']);
        if (r.status != SleepStatus.insufficientData) {
          expect(r.baseline, expected['baseline']);
          expect(r.recent, expected['recent']);
          expect(r.delta, expected['delta']);
        } else {
          expect(r.baseline, isNull);
        }
      });
    }
  });

  group('valid days, automatic (D-073 #1)', () {
    test('a well-logged finished day counts, with its sleep', () {
      final q = _q(_fullDay);
      expect(q.valid, isTrue);
      expect(q.reasons, isEmpty);
      expect(q.sleepMinutes, 5 * 60 + 120 + 60 + 239);
    });

    test(
      'missing is not zero: sparse, no sleep, open timer, overlap, today',
      () {
        expect(_q([_feed(_at(9)), _feed(_at(18))]).reasons, [
          DayInvalidReason.noSleep,
          DayInvalidReason.sparse,
        ]);
        expect(_q(_fullDay.sublist(0, 4)).reasons, [DayInvalidReason.sparse]);
        expect(_q(_fullDay, timer: _at(21)).reasons, [
          DayInvalidReason.openTimer,
        ]);
        expect(_q(_fullDay, conflicts: 1).reasons, [DayInvalidReason.overlap]);
        expect(_q(_fullDay, now: _at(22)).reasons, [
          DayInvalidReason.notFinished,
        ]);
      },
    );

    test('a running sleep (no end) never counts as sleep', () {
      final q = _q([..._fullDay.where((r) => !r.sleep), _sleep(_at(1), null)]);
      expect(q.reasons, contains(DayInvalidReason.noSleep));
      expect(q.sleepMinutes, 0);
    });

    test('sleep crossing midnight is clipped to the day', () {
      final q = dayQuality(
        zone: _zone,
        date: '2026-10-14',
        now: _now,
        records: [_sleep(_at(22, 0, 13), _at(6, 0, 14))],
      );
      expect(q.sleepMinutes, 6 * 60);
    });

    test('windows: 3 recent completed days, baseline from the 14 before', () {
      final days = [
        for (var i = 0; i < 17; i++)
          DayQuality(
            date: '2026-10-${'${i + 1}'.padLeft(2, '0')}',
            valid: i % 4 != 0,
            reasons: const [],
            sleepMinutes: 700 + i,
            longestGapMinutes: 0,
          ),
      ];
      final w = sleepWindows('2026-10-18', days);
      expect(w.recentDates, ['2026-10-15', '2026-10-16', '2026-10-17']);
      // 17 Oct is one of the invalid days in this series: null, never zero.
      expect(w.recent, [714, 715, null]);
      expect(w.baseline, hasLength(defaultRhythmRules.baselineMaxDays));
      expect(w.baseline.last, 713);
    });
  });

  group('sleep summary on the phone', () {
    // A steady 13 h of logged sleep a day, with feeds every 3 hours.
    List<CareRecord> day(String date, {int sleepHours = 13}) {
      final p = date.split('-').map(int.parse).toList();
      DateTime at(int h) => DateTime.utc(p[0], p[1], p[2], h - 7);
      return [
        rec(CareType.sleep, at(0), mai, endedAt: at(sleepHours ~/ 2)),
        for (final h in [7, 10, 13, 16, 19]) rec(CareType.bottle, at(h), mai),
        rec(
          CareType.sleep,
          at(24 - (sleepHours - sleepHours ~/ 2)),
          mai,
          endedAt: at(24).subtract(const Duration(minutes: 1)),
        ),
      ];
    }

    final today = '2026-10-18';
    final now = DateTime.utc(2026, 10, 18, 3);

    test('enough valid days: no change on a steady log', () {
      final s = sleepSummary(
        zone: _zone,
        today: today,
        now: now,
        records: [
          for (var i = 1; i <= 17; i++)
            ...day('2026-10-${'$i'.padLeft(2, '0')}'),
        ],
      );
      expect(s.days, hasLength(17));
      expect(s.result.status, SleepStatus.noChange);
      expect(s.result.validBaselineDays, 7);
      expect(s.result.validRecentDays, 3);
    });

    test('less logged sleep on the recent days is a change', () {
      final s = sleepSummary(
        zone: _zone,
        today: today,
        now: now,
        records: [
          for (var i = 1; i <= 14; i++)
            ...day('2026-10-${'$i'.padLeft(2, '0')}'),
          for (var i = 15; i <= 17; i++) ...day('2026-10-$i', sleepHours: 10),
        ],
      );
      expect(s.result.status, SleepStatus.changeDetected);
      expect(s.result.delta, lessThan(0));
    });

    test('an open overlap invalidates the days it touches', () {
      final records = [for (var i = 12; i <= 17; i++) ...day('2026-10-$i')];
      // The first sleep of 16 Oct (records of a day: sleep, five feeds, sleep).
      final overlapping = records[4 * 7].id;
      final s = sleepSummary(
        zone: _zone,
        today: today,
        now: now,
        records: records,
        conflicts: [
          [overlapping, 'not-in-the-window'],
        ],
      );
      final byDate = {for (final d in s.days) d.date: d};
      expect(byDate['2026-10-16']!.reasons, [DayInvalidReason.overlap]);
      expect(byDate['2026-10-15']!.valid, isTrue);
      // 3 of 5 baseline days: honest "not enough data", never a guess.
      expect(s.result.status, SleepStatus.insufficientData);
      expect(s.result.validBaselineDays, 3);
      expect(s.result.validRecentDays, 2);
    });
  });

  group('episodes (NL07b) and due-date limits', () {
    test('suggests grouping after two changed days among the last three', () {
      expect(
        suggestEpisode([
          (date: '2026-10-06', state: ObservationState.reportedChange),
          (date: '2026-10-07', state: ObservationState.normal),
          (date: '2026-10-08', state: ObservationState.mixed),
        ]),
        isTrue,
      );
      expect(
        suggestEpisode([
          (date: '2026-10-08', state: ObservationState.reportedChange),
        ]),
        isFalse,
      );
    });

    test(
      'due date: 28 days before to 126 days after birth, like setDueDate',
      () {
        expect(dueDateAllowed('2026-09-17', '2026-08-20'), isTrue);
        expect(dueDateAllowed('2026-09-17', '2026-08-19'), isFalse);
        expect(dueDateAllowed('2026-09-17', '2027-01-21'), isTrue);
        expect(dueDateAllowed('2026-09-17', '2027-01-22'), isFalse);
        // 22w0d and 44w0d are the extremes the estimate can reach.
        expect(
          dueDateAllowed('2026-09-17', estimateDueDate('2026-09-17', 22, 0)),
          isTrue,
        );
        expect(
          dueDateAllowed('2026-09-17', estimateDueDate('2026-09-17', 44, 0)),
          isTrue,
        );
        expect(
          dueDateAllowed('2026-09-17', estimateDueDate('2026-09-17', 44, 6)),
          isFalse,
        );
        expect(gestationValid(21, 6), isFalse);
        expect(gestationValid(39, 3), isTrue);
      },
    );
  });
}
