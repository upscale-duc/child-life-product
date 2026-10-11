import 'package:child_life/features/care/who_growth.dart';
import 'package:flutter_test/flutter_test.dart';

double r1(double v) => (v * 10).round() / 10;

void main() {
  group('WHO growth standards (20i)', () {
    test('boys weight by week matches the Figma table and WHO', () {
      // Figma 20i (Bé trai, Cân nặng, Theo tuần): Thấp · Trung vị · Cao.
      const expected = {
        0: (2.5, 3.3, 4.3),
        1: (2.6, 3.5, 4.5),
        2: (2.8, 3.8, 4.9),
        3: (3.1, 4.1, 5.2),
        4: (3.4, 4.4, 5.6),
        5: (3.6, 4.7, 5.9),
        // WHO 6.252 → 6.3 (the frame shows 6,2).
        6: (3.8, 4.9, 6.3),
      };
      for (final MapEntry(key: w, value: e) in expected.entries) {
        final r = WhoGrowth.range(
          GrowthMeasure.weight,
          boy: true,
          ageDays: w * 7,
        )!;
        expect((r1(r.low), r1(r.median), r1(r.high)), e, reason: 'week $w');
      }
    });

    test('well-known medians: girls, length, and later months', () {
      double median(GrowthMeasure m, bool boy, int days) =>
          r1(WhoGrowth.range(m, boy: boy, ageDays: days)!.median);
      expect(median(GrowthMeasure.weight, false, 0), 3.2);
      expect(median(GrowthMeasure.length, true, 0), 49.9);
      expect(median(GrowthMeasure.length, false, 0), 49.1);
      // 12 months (365 days): boys 9.6 kg, 75.7 cm; girls 8.9 kg, 74.0 cm.
      expect(median(GrowthMeasure.weight, true, 365), 9.6);
      expect(median(GrowthMeasure.length, true, 365), 75.7);
      expect(median(GrowthMeasure.weight, false, 365), 8.9);
      expect(median(GrowthMeasure.length, false, 365), 74.0);
    });

    test('a measurement is placed against the band', () {
      // 20d: Teddy, 3 weeks, 4.3 kg → normal.
      expect(
        WhoGrowth.band(
          GrowthMeasure.weight,
          boy: true,
          ageDays: 21,
          value: 4.3,
        ),
        GrowthBand.normal,
      );
      expect(
        WhoGrowth.band(
          GrowthMeasure.weight,
          boy: true,
          ageDays: 21,
          value: 2.9,
        ),
        GrowthBand.below,
      );
      expect(
        WhoGrowth.band(
          GrowthMeasure.length,
          boy: false,
          ageDays: 21,
          value: 60,
        ),
        GrowthBand.above,
      );
      final z = WhoGrowth.zScore(
        GrowthMeasure.weight,
        boy: true,
        ageDays: 0,
        value: 3.3464,
      )!;
      expect(z.abs(), lessThan(0.001));
    });

    test('ages and the baby\'s row', () {
      final weeks = WhoGrowth.ages(weeks: true);
      expect(weeks, hasLength(14));
      expect(WhoGrowth.rowFor(weeks, 23), 3);
      final months = WhoGrowth.ages(weeks: false);
      expect(months, hasLength(25));
      expect(months[12].days, 365);
      expect(WhoGrowth.rowFor(months, 70), 2);
      expect(
        WhoGrowth.range(GrowthMeasure.weight, boy: true, ageDays: 3000),
        isNull,
      );
    });
  });
}
