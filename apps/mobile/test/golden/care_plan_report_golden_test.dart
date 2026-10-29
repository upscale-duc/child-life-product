@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care_plan/care_plan_history.dart';
import 'package:child_life/features/care_plan/care_plan_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con D-138: 11 Cùng nhau chăm (a week of the family's tasks, badges), 12 the share
// card, and 20 Lịch sử thay đổi.
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
};

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
                ...carePlanOverrides(days: {carePlanToday: planFresh()}),
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
