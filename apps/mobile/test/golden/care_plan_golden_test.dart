@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care_plan/care_plan_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con (D-135, step 1): 04 / 04b / 04-0, the one-time swipe hint, and the sheets
// 05 Giao việc, 06 Thêm việc, 06b Sửa việc and the everyday delete confirm. Step 4 (D-136): the
// ways to start a day (7 logged days, the dev-only sample plans), a draft and "Đổi cách khác".
typedef _Case = ({
  Membership me,
  Map<String, List<dynamic>?> days,
  int everyday,
  bool hintDone,
  Future<void> Function(WidgetTester, AppLocalizations)? act,
  double height,
});

Future<void> _tap(WidgetTester tester, Finder f) async {
  // The list builds lazily: scroll until the target exists, then into view.
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

final _cases = <String, _Case>{
  // 04: nothing done yet; Mẹ sees the hint once.
  'plan_fresh': (
    me: mai,
    days: {carePlanToday: planFresh()},
    everyday: 2,
    hintDone: false,
    act: null,
    height: 1500,
  ),
  // 04b: under way; who did what, a skipped task, the next one edged.
  'plan_underway': (
    me: mai,
    days: {carePlanToday: planUnderway()},
    everyday: 2,
    hintDone: true,
    act: null,
    height: 1500,
  ),
  // Cô Lan: ticks tasks, cannot plan (no add, no assign, no swipe).
  'plan_caregiver': (
    me: lan,
    days: {carePlanToday: planUnderway()},
    everyday: 2,
    hintDone: false,
    act: null,
    height: 1300,
  ),
  // 04-0 for Mẹ: her baby's rhythm (7 logged days), everyday tasks, yesterday, and on dev the
  // sample plans in review.
  'start_parent': (
    me: mai,
    days: {'2026-10-27': planFresh()},
    everyday: 2,
    hintDone: true,
    act: null,
    height: 812,
  ),
  // 04-0 for Cô Lan: nothing to do but wait.
  'start_caregiver': (
    me: lan,
    days: const {},
    everyday: 2,
    hintDone: true,
    act: null,
    height: 812,
  ),
  // 05 "Giao cả buổi" for the morning.
  'assign_group': (
    me: mai,
    days: {carePlanToday: planFresh()},
    everyday: 2,
    hintDone: true,
    act: (t, l) => _tap(t, find.byKey(const ValueKey('cp_assign_morning'))),
    height: 812,
  ),
  // 06 Thêm việc in the evening.
  'add_task': (
    me: mai,
    days: {carePlanToday: planFresh()},
    everyday: 2,
    hintDone: true,
    act: (t, l) => _tap(t, find.byKey(const ValueKey('cp_add_evening'))),
    height: 1000,
  ),
  // 06b: tap a task to edit it.
  'edit_task': (
    me: mai,
    days: {carePlanToday: planFresh()},
    everyday: 2,
    hintDone: true,
    act: (t, l) => _tap(t, find.text(l.cpTaskVitamin)),
    height: 1000,
  ),
  // 02: a drafted day for Mẹ, "Dùng lịch này" on top, no rings yet.
  'plan_draft': (
    me: mai,
    days: {carePlanToday: planFresh()},
    everyday: 2,
    hintDone: true,
    act: null,
    height: 1500,
  ),
  // "Đổi cách khác" on a draft made from the rhythm.
  'change_way': (
    me: mai,
    days: {carePlanToday: planFresh(), '2026-10-27': planFresh()},
    everyday: 2,
    hintDone: true,
    act: (t, l) => _tap(t, find.byKey(const Key('cp_draft_change'))),
    height: 1000,
  ),
};

/// Step 4 fixtures: the draft days and how many days before have a feed and a sleep.
const _drafts = {
  'plan_draft': {carePlanToday},
  'change_way': {carePlanToday},
};
const _loggedDays = {'start_parent': 7, 'change_way': 7};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('care plan $name ${palette.name} $language', (
          tester,
        ) async {
          final locale = Locale(language);
          final l = lookupAppLocalizations(locale);
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              const CarePlanScreen(),
              locale: locale,
              palette: palette,
              viewport: Size(375, c.height),
              prefs: {if (c.hintDone) 'carePlan.swipeHint.done': true},
              overrides: <Override>[
                ...familyOverrides(me: c.me, now: carePlanNow, carePlan: false),
                ...carePlanOverrides(
                  days: c.days.cast(),
                  everyday: c.everyday,
                  drafts: _drafts[name] ?? const {},
                  loggedDays: _loggedDays[name] ?? 0,
                ),
              ],
            );
            await tester.pumpAndSettle();
            await c.act?.call(tester, l);
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Overlay).first,
              matchesGoldenFile(
                'goldens/care_plan/${name}_${palette.name}_$language.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
