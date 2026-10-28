import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/adaptive/explore_screen.dart';
import 'package:child_life/features/baby/baby_models.dart';
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
  Set<String> drafts = const {},
  int loggedDays = 0,
  BabyPrivateProfile? profile,
  CarePlanFamilySettings family = const CarePlanFamilySettings(),
}) async {
  final repo = FakeCarePlanRepository();
  await pumpRouted(
    tester,
    const CarePlanScreen(),
    viewport: const Size(375, 1600),
    prefs: {if (hintDone) 'carePlan.swipeHint.done': true},
    overrides: [
      ...familyOverrides(
        me: me ?? mai,
        now: carePlanNow,
        carePlan: false,
        profile: profile,
      ),
      ...carePlanOverrides(
        days: days,
        everyday: everyday,
        repo: repo,
        drafts: drafts,
        loggedDays: loggedDays,
        family: family,
      ),
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
    expect(find.byKey(const Key('cp_editor_save')), findsNothing);
    await _tap(tester, find.byKey(ValueKey('cp_ring_${plan[1].id}')));
    expect(repo.calls.single.$1, 'status');
  });

  testWidgets('04-0: Mẹ makes today from yesterday in one tap', (tester) async {
    final repo = await _pump(
      tester,
      days: {'2026-10-27': planFresh()},
      everyday: 2,
    );
    expect(find.text(l.cpEmptyToday), findsOneWidget);
    // Only "Giống hôm qua" to offer: it is picked already.
    await _tap(tester, find.byKey(const Key('cp_start')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'yesterday',
    });
  });

  testWidgets('04-0 leads with the way the family chose ("Đã chọn")', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      days: {'2026-10-27': planFresh()},
      loggedDays: 7,
      family: const CarePlanFamilySettings(method: 'rhythm'),
    );
    expect(find.text(l.cpChosen), findsOneWidget);
    await _tap(tester, find.byKey(const Key('cp_start')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'rhythm',
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

  testWidgets('05: "Giao cả ca" needs someone, then gives the whole morning', (
    tester,
  ) async {
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
  });

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
        expect(find.byKey(const Key('cp_editor_save')), findsOneWidget);
      }
    },
  );

  // ---------- Step 4 (D-136): how a day's plan is chosen, the draft ----------

  testWidgets('01 offers "Theo nhịp" only after 7 logged days', (tester) async {
    await _pump(tester, days: const {}, loggedDays: 6);
    await _tap(tester, find.byKey(const Key('cp_choose_way')));
    expect(find.byKey(const ValueKey('cp_way_rhythm')), findsNothing);
    final repo = await _pump(tester, days: const {}, loggedDays: 7);
    await _tap(tester, find.byKey(const Key('cp_choose_way')));
    // It leads and is picked; it makes a draft, so the action is "Xem trước lịch".
    expect(find.text(l.cpPreview), findsOneWidget);
    await _tap(tester, find.byKey(const Key('cp_way_go')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'rhythm',
    });
  });

  testWidgets('01: the sample plans (dev, in review) start a draft', (
    tester,
  ) async {
    final repo = await _pump(tester, days: const {});
    await _tap(tester, find.byKey(const Key('cp_choose_way')));
    expect(find.text(l.cpEasySection), findsOneWidget);
    expect(find.text(l.cpTemplatesNote), findsOneWidget);
    // Teddy is 5 weeks old: EASY 3.5 fits the age.
    expect(find.text(l.cpFitsAge), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('cp_way_easy4')));
    await _tap(tester, find.byKey(const Key('cp_way_go')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'easy4',
    });
  });

  testWidgets(
    'EASY only under 6 months (D-136 #4); a 3-year-old sees the basic plan',
    (tester) async {
      await _pump(
        tester,
        days: const {},
        profile: BabyPrivateProfile(
          dateOfBirth: DateTime(2023, 9, 1),
          gender: Gender.boy,
        ),
      );
      await _tap(tester, find.byKey(const Key('cp_choose_way')));
      expect(find.byKey(const ValueKey('cp_way_basic')), findsOneWidget);
      expect(find.byKey(const ValueKey('cp_way_easy35')), findsNothing);
      expect(find.byKey(const ValueKey('cp_way_easy4')), findsNothing);
      expect(find.text(l.cpEasySection), findsNothing);
      expect(
        carePlanAgeMonths(DateTime(2026, 4, 30), DateTime(2026, 10, 28)),
        5,
      );
      expect(
        carePlanAgeMonths(DateTime(2026, 4, 28), DateTime(2026, 10, 28)),
        6,
      );
    },
  );

  testWidgets('a draft: Mẹ edits it and uses it; no rings until then', (
    tester,
  ) async {
    final plan = planFresh();
    final repo = await _pump(
      tester,
      days: {carePlanToday: plan},
      drafts: {carePlanToday},
    );
    expect(find.text(l.cpDraftHeading('Teddy')), findsOneWidget);
    expect(find.byKey(ValueKey('cp_ring_${plan.first.id}')), findsNothing);
    // Still editable like any plan.
    expect(find.byKey(const ValueKey('cp_add_morning')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('cp_draft_use')));
    _expectCall(repo.calls.single, 'publish', {'date': carePlanToday});
    expect(find.text(l.cpDraftUsed), findsOneWidget);
  });

  testWidgets('"Đổi cách khác" lists the other ways; back keeps the draft', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      days: {carePlanToday: planFresh()},
      drafts: {carePlanToday},
      loggedDays: 7,
    );
    await _tap(tester, find.byKey(const Key('cp_draft_change')));
    expect(find.text(l.cpChooseTitle('Teddy')), findsOneWidget);
    // The draft was made by rhythm: that way is not offered again.
    expect(find.byKey(const ValueKey('cp_way_rhythm')), findsNothing);
    await _tap(tester, find.bySemanticsLabel(l.a11yBack));
    expect(find.text(l.cpDraftHeading('Teddy')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('cp_draft_change')));
    await _tap(tester, find.byKey(const ValueKey('cp_way_basic')));
    await _tap(tester, find.byKey(const Key('cp_way_go')));
    _expectCall(repo.calls.single, 'start', {
      'date': carePlanToday,
      'from': 'basic',
    });
  });

  testWidgets('Cô Lan never sees a draft', (tester) async {
    await _pump(
      tester,
      me: lan,
      days: {carePlanToday: planFresh()},
      drafts: {carePlanToday},
    );
    expect(find.text(l.cpDraftHeading('Teddy')), findsNothing);
    expect(find.text(l.cpEmptyViewer), findsOneWidget);
    expect(find.text(l.cpTaskVitamin), findsNothing);
  });

  testWidgets('200 % text: the ways to start and a draft do not overflow', (
    tester,
  ) async {
    for (final language in ['vi', 'en']) {
      for (final drafts in [
        <String>{},
        {carePlanToday},
      ]) {
        await pumpRouted(
          tester,
          const CarePlanScreen(),
          locale: Locale(language),
          textScaler: const TextScaler.linear(2),
          viewport: const Size(375, 3200),
          prefs: {'carePlan.swipeHint.done': true},
          overrides: [
            ...familyOverrides(me: mai, now: carePlanNow, carePlan: false),
            ...carePlanOverrides(
              days: {
                if (drafts.isNotEmpty) carePlanToday: planFresh(),
                '2026-10-27': planFresh(),
              },
              everyday: 2,
              drafts: drafts,
              loggedDays: 7,
            ),
          ],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // 01, every way at once.
        await _tap(
          tester,
          find.byKey(Key(drafts.isEmpty ? 'cp_choose_way' : 'cp_draft_change')),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('cp_way_go')), findsOneWidget);
      }
    }
  });
}
