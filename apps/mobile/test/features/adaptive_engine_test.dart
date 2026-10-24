import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// Same fixtures as packages/contracts/test/adaptive.test.ts (Figma 930:11858).
void main() {
  List<WidgetId> visible(Experience exp, Iterable<WidgetId> available) => [
    for (final w in rankToday(exp, available))
      if (w.visible) w.id,
  ];

  group('age (AX00 rule 7)', () {
    test('whole calendar months, end-of-month birthdays included', () {
      expect(ageInMonths(DateTime(2026, 8, 17), DateTime(2026, 10, 23)), 2);
      expect(ageInMonths(DateTime(2022, 3, 12), DateTime(2026, 10, 24)), 55);
      expect(ageInMonths(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 1);
      expect(ageInMonths(DateTime(2026, 1, 31), DateTime(2026, 2, 27)), 0);
      expect(ageInMonths(DateTime(2026, 10, 24), DateTime(2026, 10, 24)), 0);
    });

    test('bands 0–1, 1–3, 3–6, 6+', () {
      expect([0, 11, 12, 35, 36, 71, 72, 200].map(ageBandFor), [
        AgeBand.b0_1,
        AgeBand.b0_1,
        AgeBand.b1_3,
        AgeBand.b1_3,
        AgeBand.b3_6,
        AgeBand.b3_6,
        AgeBand.b6_12,
        AgeBand.b6_12,
      ]);
    });
  });

  test('goal list puts the band presets first (AX03 / AX04)', () {
    expect(goalOrder(AgeBand.b3_6), [
      Goal.memories,
      Goal.spending,
      Goal.family,
      Goal.trackCare,
      Goal.growthVaccines,
      Goal.reminders,
    ]);
  });

  group('rankToday', () {
    const core = [
      WidgetId.tiles,
      WidgetId.reminders,
      WidgetId.recentMemories,
      WidgetId.growth,
      WidgetId.momentToday,
      WidgetId.createFromMemories,
      WidgetId.spending,
      WidgetId.familyView,
      WidgetId.vaccine,
      WidgetId.quickActions,
    ];

    test('preset goals give the AX00 default per band (AX10–AX13)', () {
      expect(visible(Experience.defaults(AgeBand.b0_1), core), [
        WidgetId.tiles,
        WidgetId.reminders,
        WidgetId.recentMemories,
        WidgetId.growth,
      ]);
      expect(visible(Experience.defaults(AgeBand.b1_3), core), [
        WidgetId.recentMemories,
        WidgetId.tiles,
        WidgetId.reminders,
        WidgetId.growth,
      ]);
      expect(visible(Experience.defaults(AgeBand.b3_6), core), [
        WidgetId.momentToday,
        WidgetId.createFromMemories,
        WidgetId.spending,
        WidgetId.reminders,
        WidgetId.familyView,
      ]);
      expect(visible(Experience.defaults(AgeBand.b6_12), core), [
        WidgetId.recentMemories,
        WidgetId.reminders,
        WidgetId.spending,
        WidgetId.growth,
      ]);
    });

    test('AX14: quick log and growth start under "Đã ẩn" for Na', () {
      final ranked = rankToday(Experience.defaults(AgeBand.b3_6), const [
        WidgetId.tiles,
        WidgetId.growth,
        WidgetId.reminders,
      ]);
      final byId = {for (final w in ranked) w.id: w};
      expect(byId[WidgetId.tiles]!.visible, isFalse);
      expect(byId[WidgetId.growth]!.visible, isFalse);
      expect(byId[WidgetId.reminders]!.visible, isTrue);
      expect(byId[WidgetId.reminders]!.reason, isA<ReasonAge>());
    });

    test(
      'an added goal goes up and shows; a removed preset goal goes down',
      () {
        final na = Experience.defaults(AgeBand.b3_6);
        expect(
          visible(
            na.copyWith(goals: [...na.goals, Goal.growthVaccines]),
            const [WidgetId.momentToday, WidgetId.growth, WidgetId.reminders],
          ),
          [WidgetId.growth, WidgetId.momentToday, WidgetId.reminders],
        );
        final teddy = Experience.defaults(
          AgeBand.b0_1,
        ).copyWith(goals: const [Goal.memories]);
        expect(
          visible(teddy, const [
            WidgetId.tiles,
            WidgetId.reminders,
            WidgetId.recentMemories,
          ]).last,
          WidgetId.tiles,
        );
      },
    );

    test('pinned first and never moved; hidden stays hidden', () {
      final exp = Experience.defaults(AgeBand.b3_6).copyWith(
        pinned: const [WidgetId.reminders],
        hidden: const [WidgetId.spending],
      );
      final ranked = rankToday(
        exp,
        WidgetId.values,
        const RankSignals(
          usage: {WidgetId.spending: 1, WidgetId.momentToday: 1},
        ),
      );
      expect(ranked.first.id, WidgetId.reminders);
      expect(ranked.first.reason, isA<ReasonPinned>());
      expect(
        ranked.firstWhere((w) => w.id == WidgetId.spending).visible,
        isFalse,
      );
    });

    test('usage and recency reorder a ranked Today, never a manual one', () {
      const avail = [WidgetId.recentMemories, WidgetId.growth];
      const used = RankSignals(
        usage: {WidgetId.growth: 1},
        recent: {WidgetId.growth},
      );
      expect(
        rankToday(Experience.defaults(AgeBand.b6_12), avail, used).first.id,
        WidgetId.growth,
      );
      final manual = Experience.defaults(
        AgeBand.b3_6,
      ).copyWith(order: const [WidgetId.reminders, WidgetId.momentToday]);
      expect(
        rankToday(
          manual,
          const [WidgetId.reminders, WidgetId.momentToday, WidgetId.spending],
          const RankSignals(usage: {WidgetId.momentToday: 1}),
        ).map((w) => w.id),
        [WidgetId.reminders, WidgetId.momentToday, WidgetId.spending],
      );
    });
  });

  group('stage transition (AX33)', () {
    test('once per milestone, only when the band is newer', () {
      final teddy = Experience.defaults(AgeBand.b0_1);
      expect(stagePromptDue(teddy, 11), isNull);
      expect(stagePromptDue(teddy, 12), 12);
      final kept = teddy.copyWith(stagePrompts: const {12: StageAnswer.kept});
      expect(stagePromptDue(kept, 13), isNull);
      expect(stagePromptDue(kept, 36), 36);
      expect(stagePromptDue(Experience.defaults(AgeBand.b3_6), 55), isNull);
    });

    test('Áp dụng keeps pins and hides; Khôi phục clears hides', () {
      final exp = Experience.defaults(AgeBand.b0_1).copyWith(
        pinned: const [WidgetId.growth],
        hidden: const [WidgetId.tiles],
        order: const [WidgetId.reminders],
      );
      final applied = applyBand(exp, AgeBand.b1_3);
      expect(applied.bandApplied, AgeBand.b1_3);
      expect(applied.pinned, [WidgetId.growth]);
      expect(applied.hidden, [WidgetId.tiles]);
      expect(applied.order, isEmpty);
      expect(applyBand(exp, AgeBand.b1_3, restore: true).hidden, isEmpty);
    });
  });

  group('document', () {
    test('round-trips and drops ids from a newer app', () {
      final exp = Experience.defaults(AgeBand.b1_3).copyWith(
        pinned: const [WidgetId.growth],
        stagePrompts: const {12: StageAnswer.applied},
      );
      expect(Experience.fromJson(exp.toJson('b1')), exp);
      final newer = {
        ...exp.toJson('b1'),
        'hidden': ['learning', 'tiles'],
        'goals': ['memories', 'projects'],
      };
      final read = Experience.fromJson(newer)!;
      expect(read.hidden, [WidgetId.tiles]);
      expect(read.goals, [Goal.memories]);
      expect(Experience.fromJson(const {'bandApplied': 'b12_18'}), isNull);
    });

    test(
      'a layout saved on this device becomes a manual arrangement (P-177)',
      () {
        final exp = migrateTodayLayout(
          band: AgeBand.b0_1,
          order: const ['tiles', 'reminders', 'forYou', 'spending'],
          hidden: const ['spending', 'vaccine'],
        );
        expect(exp.goalsSource, GoalsSource.migrated);
        expect(exp.order, [
          WidgetId.tiles,
          WidgetId.reminders,
          WidgetId.forYou,
          WidgetId.spending,
        ]);
        expect(
          visible(exp, const [
            WidgetId.tiles,
            WidgetId.reminders,
            WidgetId.forYou,
            WidgetId.spending,
          ]),
          [WidgetId.tiles, WidgetId.reminders, WidgetId.forYou],
        );
      },
    );
  });
}
