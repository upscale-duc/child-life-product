import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/adaptive_signals.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/hn_fixtures.dart';
import '../helpers/router_pump.dart';

/// Phase E (plan §4.4, §4.8): usage, MET-01 details, AX33.
void main() {
  group('usage (28 days, on the phone)', () {
    test(
      'counts taps per widget, normalised to the most used, last 28 days',
      () {
        final mem = <String, String>{};
        final store = UsageStore((k) => mem[k], (k, v) => mem[k] = v);
        final now = DateTime(2026, 10, 24);
        for (var i = 0; i < 4; i++) {
          store.record('u', 'b', WidgetId.spending, now);
        }
        store.record('u', 'b', WidgetId.growth, now);
        store.record('u', 'b', WidgetId.reminders, DateTime(2026, 9, 1));
        final usage = store.usage('u', 'b', now);
        expect(usage[WidgetId.spending], 1);
        expect(usage[WidgetId.growth], 0.25);
        expect(usage[WidgetId.reminders], 0);
        // Another child, another person: nothing.
        expect(store.usage('u', 'other', now), isEmpty);
      },
    );
  });

  testWidgets('a tap counts as use; a scroll ending on the widget does not', (
    tester,
  ) async {
    final mem = <String, String>{};
    final store = UsageStore((k) => mem[k], (k, v) => mem[k] = v);
    await pumpRouted(
      tester,
      const Scaffold(
        body: AdaptiveTapTracker(
          id: WidgetId.growth,
          child: SizedBox(width: 300, height: 300),
        ),
      ),
      overrides: [
        ...hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
        ...adaptiveOverrides(
          band: AgeBand.b0_1,
          repo: FakeExperienceRepository(),
        ),
        usageStoreProvider.overrideWithValue(store),
      ],
    );
    final box = find.byType(AdaptiveTapTracker);
    await tester.drag(box, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(store.usage('u_mai', teddyId, DateTime.now()), isEmpty);
    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(mem.values.single, contains('growth'));
  });

  test('AX14 "Xong" reports what changed, as closed details', () {
    final before = Experience.defaults(AgeBand.b3_6);
    final after = before.copyWith(
      pinned: const [WidgetId.reminders],
      hidden: const [WidgetId.spending],
      order: const [WidgetId.reminders, WidgetId.momentToday],
      goals: const [Goal.memories],
    );
    expect(customizeDetails(before, after), [
      'pin',
      'hide',
      'reorder',
      'goals',
    ]);
    expect(customizeDetails(before, before), isEmpty);
  });

  group('AX33', () {
    final teddy = Experience.defaults(AgeBand.b0_1);

    test(
      '12 months: memories first, feeds off the quick log, sleep and diapers kept',
      () {
        final r = applyStage(teddy, 12, stageOptions(12).toSet());
        expect(r.exp.bandApplied, AgeBand.b1_3);
        expect(r.exp.stagePrompts[12], StageAnswer.applied);
        expect(r.hideTiles, {
          TrackerKind.bottle,
          TrackerKind.breast,
          TrackerKind.pump,
        });
        final noSleep = applyStage(teddy, 12, {StageOption.leadNewBand});
        expect(
          noSleep.hideTiles,
          containsAll([TrackerKind.sleep, TrackerKind.diaper]),
        );
      },
    );

    test('unticking everything only records the answer', () {
      final r = applyStage(teddy, 12, {StageOption.keepSleepDiaper});
      expect(r.exp.bandApplied, AgeBand.b0_1);
      expect(r.hideTiles, isEmpty);
      expect(stagePromptDue(r.exp, 13), isNull);
    });

    test('36 and 72 months', () {
      final na = Experience.defaults(AgeBand.b1_3);
      final r = applyStage(na, 36, stageOptions(36).toSet());
      expect(r.exp.bandApplied, AgeBand.b3_6);
      expect(r.exp.hidden, contains(WidgetId.tiles));
      final bin = applyStage(
        Experience.defaults(AgeBand.b3_6),
        72,
        stageOptions(72).toSet(),
      );
      expect(bin.exp.bandApplied, AgeBand.b6_12);
      expect(bin.exp.shown, contains(WidgetId.growth));
    });

    for (final (label, key, applied) in [
      ('Áp dụng', 'axStageApply', true),
      ('Giữ như cũ', 'axStageKeep', false),
    ]) {
      testWidgets('on Hôm nay at 12 months: "$label" is kept, the card goes', (
        tester,
      ) async {
        final repo = FakeExperienceRepository(teddy);
        await pumpRouted(
          tester,
          const Scaffold(body: TodayScreen()),
          overrides: [
            ...hnOverrides(
              repo: StampingRhythmRepository(preferences: personalized()),
            ),
            ...adaptiveOverrides(band: AgeBand.b1_3, repo: repo, months: 12),
          ],
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Teddy tròn 1 tuổi rồi!'), findsOneWidget);
        expect(find.byKey(const Key('axStageCard')), findsOneWidget);
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(
          repo.stored!.stagePrompts[12],
          applied ? StageAnswer.applied : StageAnswer.kept,
        );
        expect(repo.stored!.bandApplied, applied ? AgeBand.b1_3 : AgeBand.b0_1);
        expect(find.byKey(const Key('axStageCard')), findsNothing);
      });
    }
  });
}
