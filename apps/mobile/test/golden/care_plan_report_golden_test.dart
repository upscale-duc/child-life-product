@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care_plan/care_plan_done.dart';
import 'package:child_life/features/care_plan/care_plan_history.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con D-138: 11 Cùng nhau chăm (a week of the family's tasks, badges), 12 the share
// card, 20 Lịch sử thay đổi, and 10 Vừa xong.
typedef _Case = ({
  Widget screen,
  Future<void> Function(WidgetTester)? act,
  double height,
});

final _cases = <String, _Case>{
  'report_week': (
    screen: const CarePlanReportScreen(),
    act: null,
    height: 1100,
  ),
  'share_card': (
    screen: const CarePlanReportScreen(),
    act: (t) async {
      await t.tap(find.byKey(const Key('cpReportShow')));
      await t.pumpAndSettle();
    },
    height: 812,
  ),
  'change_history': (
    screen: const CarePlanHistoryScreen(),
    act: null,
    height: 812,
  ),
  // 10 Vừa xong: Mẹ thanks Ba for the bath (a heart already from Cô Lan).
  'just_done': (
    screen: CarePlanDoneScreen(date: carePlanToday, itemId: _bath.id),
    act: (t) async {
      await t.tap(find.byKey(const Key('cp_react_heart')));
      await t.tap(find.byKey(const ValueKey('cp_thanks_thanksName')));
      await t.pumpAndSettle();
    },
    height: 812,
  ),
};

final _bath = planItem(
  CarePlanTask.bath,
  '18:30',
  who: [minh.uid],
  status: CarePlanStatus.done,
  doneBy: minh.uid,
  doneAt: DateTime.utc(2026, 10, 28, 11, 42),
  reactions: {lan.uid: const CarePlanReaction(heart: true)},
);

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('care plan report $name ${palette.name} $language', (
          tester,
        ) async {
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              c.screen,
              locale: Locale(language),
              palette: palette,
              viewport: Size(375, c.height),
              overrides: <Override>[
                ...familyOverrides(me: mai, now: carePlanNow, carePlan: false),
                ...carePlanOverrides(
                  days: {
                    carePlanToday: [...planFresh(), _bath],
                  },
                ),
              ],
            );
            await tester.pumpAndSettle();
            await c.act?.call(tester);
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Overlay).first,
              matchesGoldenFile(
                'goldens/care_plan_report/${name}_${palette.name}_$language.png',
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
