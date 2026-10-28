import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/adaptive/explore_screen.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con (D-135, step 1): what each tap asks the plan Functions to do, and who may do it.
final l = lookupAppLocalizations(const Locale('vi'));

Future<FakeCarePlanRepository> _pump(
  WidgetTester tester, {
  required Map<String, List<CarePlanItem>?> days,
  dynamic me,
  int everyday = 0,
  bool hintDone = true,
}) async {
  final repo = FakeCarePlanRepository();
  await pumpRouted(
    tester,
    const CarePlanScreen(),
    viewport: const Size(375, 1600),
    prefs: {if (hintDone) 'carePlan.swipeHint.done': true},
    overrides: [
      ...familyOverrides(me: me ?? mai, now: carePlanNow, carePlan: false),
      ...carePlanOverrides(days: days, everyday: everyday, repo: repo),
    ],
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void _expectCall(
  (String, Map<String, Object?>) call,
  String name,
  Map<String, Object?> args,
) {
  expect(call.$1, name);
  expect(call.$2, args);
}

void main() {
  test('groups by time; the day key is the wall date', () {
    expect(CarePlanPeriod.ofTime('06:00'), CarePlanPeriod.morning);
    expect(CarePlanPeriod.ofTime('11:59'), CarePlanPeriod.morning);
    expect(CarePlanPeriod.ofTime('12:00'), CarePlanPeriod.afternoon);
    expect(CarePlanPeriod.ofTime('18:00'), CarePlanPeriod.evening);
    expect(carePlanDateKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(newCarePlanItemId(), matches(RegExp(r'^pi_[a-f0-9]{32}$')));
  });

  testWidgets(
    'the ring marks a task done (who did it is the server’s) with undo',
    (tester) async {
      final plan = planFresh();
      final repo = await _pump(tester, days: {carePlanToday: plan});
      await _tap(tester, find.byKey(ValueKey('cp_ring_${plan.first.id}')));
      _expectCall(repo.calls.single, 'status', {
        'itemId': plan.first.id,
        'status': 'done',
      });
      expect(find.text(l.cpDoneToast(l.cpTaskBottle)), findsOneWidget);
      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      _expectCall(repo.calls.last, 'status', {
        'itemId': plan.first.id,
        'status': 'open',
      });
    },
  );

  testWidgets('Người chăm sóc ticks tasks but cannot plan', (tester) async {
    final plan = planFresh();
    final repo = await _pump(tester, me: lan, days: {carePlanToday: plan});
    expect(find.byKey(const ValueKey('cp_add_morning')), findsNothing);
    expect(find.byKey(const ValueKey('cp_assign_morning')), findsNothing);
    expect(find.byKey(const Key('cp_swipe_hint')), findsNothing);
    // Tapping the card opens nothing.
    await tester.tap(find.text(l.cpTaskVitamin));
    await tester.pumpAndSettle();
    expect(find.text(l.cpEditTask), findsNothing);
    await _tap(tester, find.byKey(ValueKey('cp_ring_${plan[1].id}')));
    expect(repo.calls.single.$1, 'status');
  });

  testWidgets('04-0: Mẹ starts from yesterday; Cô Lan only waits', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      days: {'2026-10-27': planFresh()},
      everyday: 2,
    );
    expect(find.text(l.cpEmptyToday), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('cp_start_yesterday')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'yesterday',
    });
  });

  testWidgets('04-0 for a caregiver has no way to start', (tester) async {
    await _pump(tester, me: lan, days: const {}, everyday: 2);
    expect(find.text(l.cpEmptyViewer), findsOneWidget);
    expect(find.byKey(const Key('cp_start_empty')), findsNothing);
  });

  testWidgets('06: add a task in the evening, for Ba, every day', (
    tester,
  ) async {
    final repo = await _pump(tester, days: {carePlanToday: planFresh()});
    await _tap(tester, find.byKey(const ValueKey('cp_add_evening')));
    // Nothing chosen yet: nothing to save.
    expect(
      tester
          .widget<ClButton>(find.byKey(const Key('cp_editor_save')))
          .onPressed,
      isNull,
    );
    await _tap(tester, find.byKey(const ValueKey('cp_task_bath')));
    await _tap(tester, find.byKey(ValueKey('cp_who_${minh.uid}')));
    await _tap(tester, find.text(l.cpEveryDay));
    await _tap(tester, find.byKey(const Key('cp_editor_save')));
    final (name, args) = repo.calls.single;
    expect(name, 'save');
    expect(args, containsPair('task', 'bath'));
    expect(args, containsPair('time', '19:00'));
    expect(args, containsPair('assignees', [minh.uid]));
    expect(args, containsPair('everyDay', true));
    expect(find.text(l.cpAddTask), findsWidgets);
  });

  testWidgets(
    '05: "Giao cả buổi" needs someone, then gives the whole morning',
    (tester) async {
      final plan = planFresh();
      final repo = await _pump(tester, days: {carePlanToday: plan});
      await _tap(tester, find.byKey(const ValueKey('cp_assign_morning')));
      expect(
        tester
            .widget<ClButton>(find.byKey(const Key('cp_assign_confirm')))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byKey(ValueKey('cp_assign_${lan.uid}')));
      await _tap(tester, find.byKey(const Key('cp_assign_confirm')));
      final (name, args) = repo.calls.single;
      expect(name, 'assign');
      expect(args['assignees'], [lan.uid]);
      expect(args['itemIds'], [
        for (final i in plan)
          if (i.period == CarePlanPeriod.morning) i.id,
      ]);
    },
  );

  testWidgets('06b: skip today from the edit sheet; delete an everyday task', (
    tester,
  ) async {
    final plan = planFresh();
    final vitamin = plan.firstWhere((i) => i.task == CarePlanTask.vitamin);
    final repo = await _pump(tester, days: {carePlanToday: plan});
    await _tap(tester, find.text(l.cpTaskVitamin));
    await _tap(tester, find.byKey(const Key('cp_editor_skip')));
    _expectCall(repo.calls.last, 'status', {
      'itemId': vitamin.id,
      'status': 'skipped',
    });
    await _tap(tester, find.text(l.cpTaskVitamin));
    await _tap(tester, find.byKey(const Key('cp_editor_delete')));
    // An everyday task asks whether to keep it for the days to come.
    await _tap(tester, find.byKey(const Key('cp_delete_today')));
    _expectCall(repo.calls.last, 'delete', {
      'itemId': vitamin.id,
      'everyDay': false,
    });
  });

  testWidgets('the swipe hint shows once, then stays away', (tester) async {
    await _pump(tester, days: {carePlanToday: planFresh()}, hintDone: false);
    expect(find.byKey(const Key('cp_swipe_hint')), findsOneWidget);
    await _tap(tester, find.text(l.cpGotIt));
    expect(find.byKey(const Key('cp_swipe_hint')), findsNothing);
  });

  for (final (who, listed) in [(mai, true), (lan, true), (hoa, false)]) {
    testWidgets('Khám phá lists Cùng Chăm Con: ${who.displayName} $listed', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: familyOverrides(me: who, now: carePlanNow),
      );
      expect(
        container.read(exploreAvailableProvider).contains(ExploreItem.carePlan),
        listed,
      );
    });
  }

  testWidgets(
    '200 % text: the day and the edit sheet lay out without overflow',
    (tester) async {
      for (final language in ['vi', 'en']) {
        await pumpRouted(
          tester,
          const CarePlanScreen(),
          locale: Locale(language),
          textScaler: const TextScaler.linear(2),
          viewport: const Size(375, 2400),
          prefs: {'carePlan.swipeHint.done': false},
          overrides: [
            ...familyOverrides(me: mai, now: carePlanNow, carePlan: false),
            ...carePlanOverrides(days: {carePlanToday: planUnderway()}),
          ],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final el = lookupAppLocalizations(Locale(language));
        await _tap(tester, find.text(el.cpTaskVitamin));
        expect(tester.takeException(), isNull);
        expect(find.text(el.cpEditTask), findsOneWidget);
      }
    },
  );
}
