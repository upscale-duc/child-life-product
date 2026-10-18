import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/who_growth.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/nutrition/nutrition_calc.dart';
import 'package:child_life/features/nutrition/nutrition_format.dart';
import 'package:child_life/features/nutrition/nutrition_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/nutrition_fixtures.dart';

/// Dinh dưỡng theo giai đoạn (D-083, P-163): the pure rules, mirroring
/// `packages/contracts/test/nutrition.test.ts` where the contract has the same function.

NuStage _stage(int from, int to) => NuStage(
  id: 'nst_${from}_$to',
  age: NuAge(from, to),
  title: const LbText('t', 't'),
);

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));

  group('ages and stages (monthsOld, nutritionStageFor)', () {
    test('counts completed calendar months', () {
      expect(nuMonthsOld(DateTime(2026, 3, 18), DateTime(2026, 10, 18)), 7);
      expect(nuMonthsOld(DateTime(2026, 3, 19), DateTime(2026, 10, 18)), 6);
      expect(nuMonthsOld(DateTime(2026, 10, 20), DateTime(2026, 10, 18)), 0);
    });

    test('labels ranges as the design writes them', () {
      expect(const NuAge(0, 1).label, (from: 0, to: 1));
      expect(const NuAge(6, 9).label, (from: 6, to: 8));
      expect(const NuAge(24, 37).label, (from: 24, to: 36));
      expect(nuAgeLabel(vi, const NuAge(6, 9)), '6–8 tháng');
    });

    final stages = [
      _stage(24, 37),
      _stage(0, 1),
      _stage(1, 4),
      _stage(4, 6),
      _stage(6, 9),
      _stage(9, 12),
      _stage(12, 24),
    ];

    test('picks the stage for an age; past the last stage the last one', () {
      expect(nuStageFor(stages, 7)!.stage.id, 'nst_6_9');
      expect(nuStageFor(stages, 36)!.stage.id, 'nst_24_37');
      expect(nuStageFor(stages, 36)!.past, isFalse);
      expect(nuStageFor(stages, 40)!.past, isTrue);
      expect(nuStageFor(const [], 7), isNull);
      expect(nuStageFor([_stage(6, 9)], 3), isNull);
      // Overlapping: the narrowest wins.
      expect(nuStageFor([_stage(0, 24), _stage(6, 9)], 7)!.stage.id, 'nst_6_9');
      expect(nuSortStages(stages).first.id, 'nst_0_1');
    });

    test('stage times for the 9f rail', () {
      final current = nuStageFor(stages, 7)!.stage;
      expect(nuStageTime(_stage(0, 1), current, 7), NuStageTime.past);
      expect(nuStageTime(current, current, 7), NuStageTime.current);
      expect(nuStageTime(_stage(9, 12), current, 7), NuStageTime.future);
    });
  });

  group('published documents parse defensively', () {
    test('a stage, its parts and the {name} token', () {
      final s = stagesOf([stageDoc(id: 'nst_solids', from: 6, to: 9)]).single;
      expect(s.age, const NuAge(6, 9));
      expect(s.milk!.perDayMl, const NuRange(600, 900));
      // The unknown "brunch" slot is dropped, the rest kept.
      expect(s.sampleDay.map((r) => r.slot), [
        NuSlot.morning,
        NuSlot.noon,
        NuSlot.night,
      ]);
      expect(s.illustrative, isTrue);
      expect(
        nuText(s.tips.single.body, const Locale('vi'), 'Teddy'),
        'Thịt bò, gan gà, lòng đỏ trứng cho Teddy.',
      );
      expect(
        nuText(s.tips.single.body, const Locale('en'), 'Teddy'),
        'Beef, liver, egg yolk for Teddy.',
      );
    });

    test('drafts, bad ids and missing essentials are skipped', () {
      final ok = stageDoc(id: 'nst_xx', from: 0, to: 1);
      expect(NuStage.fromDoc('nst_xx', ok), isNotNull);
      expect(NuStage.fromDoc('nst_xx', {...ok, 'status': 'draft'}), isNull);
      expect(NuStage.fromDoc('stg_xx', ok), isNull);
      expect(NuStage.fromDoc('nst_xx', {...ok, 'title': null}), isNull);
      expect(
        NuStage.fromDoc('nst_bad', stageDoc(id: 'nst_bad', from: 5, to: 3)),
        isNull,
      );
      // A broken band is dropped on its own.
      final broken = stageDoc(
        id: 'nst_bb',
        from: 0,
        to: 1,
        milk: {
          'perFeedMl': null,
          'feedsPerDay': null,
          'perDayMl': {'min': 900, 'max': 600},
          'breastfeedingNote': {'vi': 'theo nhu cầu', 'en': 'on demand'},
        },
      );
      final b = NuStage.fromDoc('nst_bb', broken)!;
      expect(b.milk!.perDayMl, isNull);
      expect(b.milk!.breastfeedingNote, isNotNull);
    });

    test(
      'nutrients: unknown keys read as other; the campaign is structured',
      () {
        final a = nutrientsOf([vitaminADoc()]).single;
        expect(a.key, NuNutrientKey.vitaminA);
        expect(a.campaign!.rounds.map((r) => r.month), [12, 6]);
        expect(a.campaign!.age, const NuAge(6, 37));
        final odd = NuNutrient.fromDoc('nut_odd', {
          ...ironDoc(),
          'key': 'boron',
        })!;
        expect(odd.key, NuNutrientKey.other);
      },
    );

    test('rules: the condition must fit the metric', () {
      expect(rulesOf([ruleDoc()]).single.isGrowth, isTrue);
      expect(
        NuRule.fromDoc(
          'nru_x',
          ruleDoc(id: 'nru_x', metric: 'milk', condition: 'belowRange'),
        ),
        isNull,
      );
      final r = rulesOf([ruleDoc(remindAfterDays: 3)]).single;
      expect(r.remindAfterDays, isNull);
    });

    test('the vitamin A record keeps only well-formed rounds', () {
      expect(
        nuParseTaken({
          '2026-06': '2026-06-01',
          '2026-13': '2026-06-01',
          'june': '2026-06-01',
          '2026-12': 'soon',
        }),
        {'2026-06': '2026-06-01'},
      );
    });
  });

  group('milk (P-163 #3–#5)', () {
    test(
      'bottle totals per local day; breastfeeds and pumping do not count',
      () {
        final records = [
          rec(CareType.bottle, vn(8, 0, 20), mai, amountMl: 100),
          rec(CareType.bottle, vn(8, 14, 0), mai, amountMl: 120),
          // 23:30 on the 7th in Hồ Chí Minh.
          rec(CareType.bottle, vn(7, 23, 30), mai, amountMl: 90),
          rec(CareType.pump, vn(8, 10, 0), mai, amountMl: 200),
          rec(CareType.breast, vn(8, 11, 0), mai, durationMin: 15),
          rec(CareType.bottle, vn(1, 9, 0), mai, amountMl: 80),
        ];
        final daily = nuDailyBottleMl(
          records,
          'Asia/Ho_Chi_Minh',
          DateTime(2026, 10, 8),
        );
        expect(daily.length, 14);
        expect(daily.last, 220);
        expect(daily[12], 90);
        expect(daily[6], 80);
      },
    );

    test('the 7-day average needs 3 days and rounds to 10 ml', () {
      expect(nuMilkAverage([0, 0, 0, 0, 700, 0, 720]), isNull);
      // 9c values: the last 7 days average 718.6 → 720.
      expect(
        nuMilkAverage([
          690, 740, 700, 760, 720, 680, 730, //
          710, 750, 700, 720, 690, 740, 720,
        ]),
        720,
      );
      // Acceptance #2: 5 days averaging 718 → 720; empty days are left out.
      expect(nuMilkAverage([0, 700, 720, 0, 730, 710, 730]), 720);
    });

    test('the card prints only the amounts a stage has', () {
      // 12–36 months (the seed): milk is a drink, a daily amount only.
      const drink = NuMilk(
        perDayMl: NuRange(350, 500),
        breastfeedingNote: LbText('bú mẹ tiếp nếu mẹ và bé muốn', 'keep going'),
      );
      expect(
        nuMilkLine(
          vi,
          'vi',
          name: 'Teddy',
          average: 420,
          milk: drink,
          breastNote: 'bú mẹ tiếp nếu mẹ và bé muốn',
        ),
        'Teddy trung bình 420 ml/ngày (7 ngày qua) · Tham khảo 350–500 ml mỗi '
        'ngày. Bú mẹ: bú mẹ tiếp nếu mẹ và bé muốn',
      );
      // 0–1 month: per feed and feeds, no daily band.
      const first = NuMilk(
        perFeedMl: NuRange(30, 90),
        feedsPerDay: NuRange(8, 12),
      );
      expect(
        nuMilkLine(
          vi,
          'vi',
          name: 'Teddy',
          average: null,
          milk: first,
          breastNote: '',
        ),
        'Chưa đủ cữ bú bình 7 ngày qua để tính trung bình · 8–12 cữ, 30–90 ml '
        'mỗi cữ.',
      );
      // A stage opened from 9f: no personal average.
      expect(
        nuMilkLine(
          vi,
          'vi',
          name: 'Teddy',
          average: 720,
          milk: drink,
          breastNote: '',
          personal: false,
        ),
        'Tham khảo 350–500 ml mỗi ngày.',
      );
    });

    test('the milk rule fires outside the band, never without an average', () {
      final rule = rulesOf([
        ruleDoc(id: 'nru_milk', metric: 'milk', condition: 'milkOutsideStage'),
      ]).single;
      const band = NuRange(600, 900);
      expect(nuMilkRuleFires(rule, 7, 1000, band), isTrue);
      expect(nuMilkRuleFires(rule, 7, 500, band), isTrue);
      expect(nuMilkRuleFires(rule, 7, 720, band), isFalse);
      expect(nuMilkRuleFires(rule, 7, null, band), isFalse);
      expect(nuMilkRuleFires(rule, 7, 1000, null), isFalse);
      expect(nuMilkPosition(1000, band), NuMilkPosition.above);
    });
  });

  group('growth rules (P-163 #6)', () {
    final dob = DateTime(2026, 3, 8);
    double low(DateTime on) =>
        WhoGrowth.range(
          GrowthMeasure.weight,
          boy: true,
          ageDays: nuDaysBetween(dob, on),
        )!.low -
        0.4;
    double normal(DateTime on) => WhoGrowth.range(
      GrowthMeasure.weight,
      boy: true,
      ageDays: nuDaysBetween(dob, on),
    )!.median;
    CareRecord g(DateTime on, double kg) =>
        rec(CareType.growth, on, mai, weightKg: kg, measuredOn: on);
    final rule = rulesOf([ruleDoc()]).single;
    final sep = DateTime(2026, 9, 20);
    final oct = DateTime(2026, 10, 5);

    List<NuMeasure> weights(List<CareRecord> r) =>
        nuMeasures(r, GrowthMeasure.weight, dob: dob, boy: true);

    test('the 2 latest below P3 fire; WHO positions are placed', () {
      final m = weights([g(sep, low(sep)), g(oct, low(oct))]);
      expect(m.first.on, oct);
      expect(m.first.band, GrowthBand.below);
      expect(nuGrowthRuleFires(rule, m, dob), isTrue);
    });

    test('one low then a normal one does not (acceptance #5)', () {
      final m = weights([g(sep, low(sep)), g(oct, normal(oct))]);
      expect(nuGrowthRuleFires(rule, m, dob), isFalse);
      expect(
        nuGrowthRuleFires(rule, weights([g(oct, low(oct))]), dob),
        isFalse,
      );
    });

    test('both must be in the rule\'s age range; no sex, no position', () {
      final young = rulesOf([ruleDoc(from: 0, to: 6)]).single;
      final m = weights([g(sep, low(sep)), g(oct, low(oct))]);
      expect(nuGrowthRuleFires(young, m, dob), isFalse);
      final unknown = nuMeasures(
        [g(sep, low(sep)), g(oct, low(oct))],
        GrowthMeasure.weight,
        dob: dob,
        boy: null,
      );
      expect(unknown.first.band, isNull);
      expect(nuGrowthRuleFires(rule, unknown, dob), isFalse);
    });

    test('no measurement for the rule\'s days', () {
      final none = rulesOf([
        ruleDoc(
          id: 'nru_measure',
          metric: 'measurement',
          condition: 'noMeasurement',
          days: 30,
        ),
      ]).single;
      final today = DateTime(2026, 10, 18);
      expect(
        nuNoMeasurementFires(
          none,
          7,
          lastMeasured: DateTime(2026, 9, 10),
          dob: dob,
          today: today,
        ),
        isTrue,
      );
      expect(
        nuNoMeasurementFires(
          none,
          7,
          lastMeasured: DateTime(2026, 10, 5),
          dob: dob,
          today: today,
        ),
        isFalse,
      );
      final signals = nuEvaluate(
        rules: [rule, none],
        months: 7,
        dob: dob,
        today: today,
        weights: weights([g(sep, low(sep)), g(oct, low(oct))]),
        lengths: const [],
        milkAverage: null,
        milkBand: null,
        lastMeasured: oct,
      );
      expect(signals.growth.map((r) => r.id), ['nru_weight_low']);
      expect(signals.noMeasurement, isNull);
    });
  });

  group('vitamin A rounds (campaignRounds)', () {
    final campaign = nutrientsOf([vitaminADoc()]).single.campaign!;

    test('a 7-month baby on 18/10: June too young, December next', () {
      final r = nuCampaignRounds(
        campaign,
        DateTime(2026, 3, 18),
        DateTime(2026, 10, 18),
        const {},
      );
      expect(
        [for (final x in r) (x.key, x.state)],
        [
          ('2026-06', NuRoundState.tooYoung),
          ('2026-12', NuRoundState.next),
          ('2027-06', NuRoundState.later),
          ('2027-12', NuRoundState.later),
        ],
      );
      expect(r[1].from, DateTime(2026, 12, 1));
      expect(r[1].to, DateTime(2026, 12, 2));
    });

    test('a recorded round is taken; a missed one is past', () {
      final taken = nuCampaignRounds(
        campaign,
        DateTime(2025, 1, 10),
        DateTime(2026, 10, 18),
        const {'2026-06': '2026-06-01'},
      );
      expect(taken.first.state, NuRoundState.taken);
      expect(taken.first.takenOn, DateTime(2026, 6, 1));
      final missed = nuCampaignRounds(
        campaign,
        DateTime(2025, 1, 10),
        DateTime(2026, 10, 18),
        const {},
      );
      expect(missed.first.state, NuRoundState.past);
    });

    test('the reminder rings at 08:00 the day before, else on the day', () {
      DateTime instant(DateTime wall) => wall;
      final from = DateTime(2026, 12, 1);
      final ahead = nuVitaminReminderTime(
        from,
        DateTime(2026, 10, 18),
        instant,
      )!;
      expect(ahead.wallFire, DateTime(2026, 11, 30, 8));
      expect(ahead.dueWall, DateTime(2026, 12, 1, 8));
      expect(ahead.lead, 1440);
      final late = nuVitaminReminderTime(
        from,
        DateTime(2026, 11, 30, 9),
        instant,
      )!;
      expect(late.lead, 0);
      expect(late.wallFire, DateTime(2026, 12, 1, 8));
      expect(
        nuVitaminReminderTime(from, DateTime(2026, 12, 1, 9), instant),
        isNull,
      );
    });

    test(
      'the calendar file: an all-day event with an alarm the day before',
      () {
        final ics = nuVitaminIcs(
          uid: 'nut_vitamin_a-2026-12@childlife.app',
          from: DateTime(2026, 12, 1),
          to: DateTime(2026, 12, 2),
          summary: 'Uống Vitamin A cho bé tại trạm y tế, phường',
          location: 'Trạm y tế phường, xã',
          description: 'Lịch cụ thể theo thông báo của trạm y tế địa phương.',
          now: DateTime.utc(2026, 10, 18, 3),
        );
        expect(ics, contains('DTSTART;VALUE=DATE:20261201\r\n'));
        expect(ics, contains('DTEND;VALUE=DATE:20261203\r\n'));
        expect(ics, contains('TRIGGER:-PT16H'));
        expect(
          ics,
          contains(r'SUMMARY:Uống Vitamin A cho bé tại trạm y tế\, phường'),
        );
        for (final line in ics.split('\r\n')) {
          expect(line.codeUnits.isNotEmpty, isTrue);
          expect(
            const Utf8Length().of(line),
            lessThanOrEqualTo(75),
            reason: line,
          );
        }
      },
    );
  });

  test('the doctor\'s summary: age, measurements, milk, no name', () {
    final dob = DateTime(2026, 3, 8);
    final today = DateTime(2026, 10, 18);
    final weights = nuMeasures(
      [
        rec(
          CareType.growth,
          DateTime(2026, 10, 5),
          mai,
          weightKg: 6.2,
          lengthCm: 64,
          measuredOn: DateTime(2026, 10, 5),
        ),
      ],
      GrowthMeasure.weight,
      dob: dob,
      boy: true,
    );
    final text = nuDoctorReport(
      vi,
      locale: 'vi',
      dob: dob,
      today: today,
      boy: true,
      weights: weights,
      lengths: const [],
      milkAverage: 720,
      banner: '2 lần đo gần nhất của bé thấp hơn khoảng chuẩn.',
    );
    expect(text, contains('Tuổi: 7 tháng tuổi'));
    expect(text, contains('Giới tính: bé trai'));
    expect(text, contains('• 05/10/2026 · 6,2 kg (thấp hơn khoảng chuẩn)'));
    expect(text, contains('720 ml/ngày'));
    expect(text, contains('Ghi chú từ app: 2 lần đo gần nhất của bé'));
    expect(text, isNot(contains('Teddy')));
  });
}

/// UTF-8 octets of a line (RFC 5545 folds at 75).
class Utf8Length {
  const Utf8Length();
  int of(String s) {
    var n = 0;
    for (final r in s.runes) {
      n += r < 0x80
          ? 1
          : r < 0x800
          ? 2
          : r < 0x10000
          ? 3
          : 4;
    }
    return n;
  }
}
