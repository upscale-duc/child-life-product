import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/rhythm/coming_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';

const zone = 'Asia/Ho_Chi_Minh'; // UTC+7, no DST

/// 2026-10-[day] [h]:[m] in Hà Nội, as an instant.
DateTime vn(int day, int h, [int m = 0]) =>
    DateTime.utc(2026, 10, day, h, m).subtract(const Duration(hours: 7));

var _n = 0;
CareRecord rec(CareType type, DateTime at, [DateTime? end]) => CareRecord(
  id: 'r_${(++_n).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  type: type,
  occurredAt: at,
  endedAt: end,
  createdBy: 'u_mai',
  author: CareAuthor.of(mai),
);

/// Bottles every [gap] minutes from 07:00 to 19:00 on days [from]..[to].
List<CareRecord> feeds(int from, int to, {int gap = 180}) => [
  for (var d = from; d <= to; d++)
    for (var m = 7 * 60; m <= 19 * 60; m += gap)
      rec(CareType.bottle, vn(d, m ~/ 60, m % 60)),
];

/// Naps of [length] minutes at 09:00, 12:30 and 16:00 on days [from]..[to].
List<CareRecord> naps(int from, int to, {int length = 60}) => [
  for (var d = from; d <= to; d++)
    for (final (h, m) in const [(9, 0), (12, 30), (16, 0)])
      rec(
        CareType.sleep,
        vn(d, h, m),
        vn(d, h, m).add(Duration(minutes: length)),
      ),
];

void main() {
  setUpAll(ensureTimeZones);

  group('feed', () {
    test('the next feed is the last feed plus the usual middle half', () {
      final records = [
        ...feeds(20, 24),
        rec(CareType.bottle, vn(25, 7)),
        rec(CareType.bottle, vn(25, 10, 10)),
      ];
      final up = comingUp(records: records, now: vn(25, 11), zone: zone);
      expect(feedIntervalRange(records, vn(25, 11), zone)?.lowMinutes, 180);
      expect(up.feed?.kind, ComingUpKind.feed);
      expect(up.feed?.since, vn(25, 10, 10));
      expect(up.feed?.from, vn(25, 13, 10));
      expect(up.feed?.to, vn(25, 13, 10));
    });

    test('too few days, an old last feed or a running breastfeed: no line', () {
      expect(
        comingUp(records: feeds(24, 25), now: vn(25, 20), zone: zone).feed,
        isNull,
      );
      expect(
        comingUp(records: feeds(20, 24), now: vn(25, 9), zone: zone).feed,
        isNull,
        reason: 'last feed 19:00 yesterday is more than 6 h ago',
      );
      expect(
        comingUp(
          records: feeds(20, 25),
          now: vn(25, 19, 30),
          zone: zone,
          feedTimerRunning: true,
        ).feed,
        isNull,
      );
    });

    test(
      'a scattered log (wider than ×2) gives nothing rather than a guess',
      () {
        final records = [
          for (var d = 20; d <= 25; d++) ...[
            rec(CareType.bottle, vn(d, 7)),
            rec(CareType.bottle, vn(d, 7, 40)),
            rec(CareType.bottle, vn(d, 12)),
            rec(CareType.bottle, vn(d, 17)),
          ],
        ];
        expect(feedIntervalRange(records, vn(25, 18), zone), isNull);
      },
    );
  });

  group('sleep', () {
    test('awake: the next nap from the usual awake stretch', () {
      // Awake 10:00→12:30 and 13:30→16:00: 150 min each.
      final records = naps(20, 25);
      final up = comingUp(records: records, now: vn(25, 14), zone: zone);
      expect(awakeRange(records, vn(25, 14), zone)?.lowMinutes, 150);
      expect(up.sleep?.kind, ComingUpKind.sleep);
      expect(up.sleep?.since, vn(25, 13, 30));
      expect(up.sleep?.from, vn(25, 16));
    });

    test('the next sleep would be at night: bedtime is not a nap, no line', () {
      final records = naps(20, 25);
      // Woke 17:00; 17:00 + 150 min = 19:30, in the night window.
      expect(
        comingUp(records: records, now: vn(25, 17, 30), zone: zone).sleep,
        isNull,
      );
    });

    test('a running nap: when the baby usually wakes', () {
      final up = comingUp(
        records: naps(20, 24),
        now: vn(25, 9, 30),
        zone: zone,
        sleepTimerSince: vn(25, 9),
      );
      expect(up.sleep?.kind, ComingUpKind.wake);
      expect(up.sleep?.from, vn(25, 10));
      expect(up.sleep?.to, vn(25, 10));
    });

    test('a running night sleep has no daytime pattern', () {
      final up = comingUp(
        records: naps(20, 24),
        now: vn(25, 21),
        zone: zone,
        sleepTimerSince: vn(25, 20),
      );
      expect(up.sleep, isNull);
    });
  });

  group('Bé dậy chưa? (lumi-plan §7.1)', () {
    test('a nap asks at max(median × 1.3, median + 20)', () {
      // Median nap 60 min → 80 min; 120 min → 156 min.
      expect(
        wakeCheckAt(
          records: naps(20, 24),
          start: vn(25, 9),
          now: vn(25, 9),
          zone: zone,
        ),
        vn(25, 10, 20),
      );
      expect(
        wakeCheckAt(
          records: naps(20, 24, length: 120),
          start: vn(25, 9),
          now: vn(25, 9),
          zone: zone,
        ),
        vn(25, 11, 36),
      );
    });

    test('fewer than five naps: after 2 h 30', () {
      expect(
        wakeCheckAt(
          records: const [],
          start: vn(25, 13),
          now: vn(25, 13),
          zone: zone,
        ),
        vn(25, 15, 30),
      );
    });

    test(
      'a night sleep asks at the usual first log of the morning, else 07:00',
      () {
        expect(
          wakeCheckAt(
            records: const [],
            start: vn(25, 20),
            now: vn(25, 20),
            zone: zone,
          ),
          vn(26, 7),
        );
        // First logs 06:30 on five mornings.
        final mornings = [
          for (var d = 20; d <= 24; d++) rec(CareType.diaper, vn(d, 6, 30)),
        ];
        expect(
          wakeCheckAt(
            records: mornings,
            start: vn(25, 22),
            now: vn(25, 22),
            zone: zone,
          ),
          vn(26, 6, 30),
        );
      },
    );

    test('a nap that would ask in the night window asks in the morning', () {
      // 18:00 + 150 min = 20:30.
      expect(
        wakeCheckAt(
          records: const [],
          start: vn(25, 18),
          now: vn(25, 18),
          zone: zone,
        ),
        vn(26, 7),
      );
    });

    test('quiet hours move it to their end', () {
      expect(
        wakeCheckAt(
          records: const [],
          start: vn(25, 12),
          now: vn(25, 12),
          zone: zone,
          quietFrom: '13:00',
          quietTo: '15:00',
        ),
        vn(25, 15),
      );
    });

    test('"Vẫn ngủ" waits half the usual sleep, at least 30 min', () {
      // Median nap 120 min → 60; no naps → 150 / 2 = 75; a night → 30.
      expect(
        wakeCheckTimes(
          records: naps(20, 24, length: 120),
          start: vn(25, 9),
          now: vn(25, 9),
          zone: zone,
        )!.againMinutes,
        60,
      );
      expect(
        wakeCheckTimes(
          records: const [],
          start: vn(25, 9),
          now: vn(25, 9),
          zone: zone,
        )!.againMinutes,
        75,
      );
      expect(
        wakeCheckTimes(
          records: const [],
          start: vn(25, 21),
          now: vn(25, 21),
          zone: zone,
        )!.againMinutes,
        30,
      );
    });

    test('the second ask stops before quiet hours or the night window', () {
      expect(
        wakeCheckTimes(
          records: const [],
          start: vn(25, 9),
          now: vn(25, 9),
          zone: zone,
          quietFrom: '12:00',
          quietTo: '13:30',
        )!.until,
        vn(25, 12),
      );
      // Asked 15:30 for a 13:00 nap: no second ask after 19:00.
      expect(
        wakeCheckTimes(
          records: const [],
          start: vn(25, 13),
          now: vn(25, 13),
          zone: zone,
        )!.until,
        vn(25, 19),
      );
    });

    test('already past: nothing to schedule', () {
      expect(
        wakeCheckAt(
          records: const [],
          start: vn(25, 9),
          now: vn(25, 12),
          zone: zone,
        ),
        isNull,
      );
    });
  });
}
