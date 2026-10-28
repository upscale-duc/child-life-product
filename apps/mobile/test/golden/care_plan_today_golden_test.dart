@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_settings.dart';
import 'package:child_life/features/care_plan/care_plan_today.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con step 2 (D-135): Hôm nay with "n việc cần làm" first under the header (14), the
// "Đến giờ rồi" sheet for one task and for tasks due together (15), and the person's reminder
// settings (13 / N1). Synthetic data, Light / Night care × vi / en.
// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/care_plan_today_golden_test.dart

/// Ba's day on 8/10 (the care fixtures' Hôm nay): Vitamin next, then the evening.
List<CarePlanItem> _day() => [
  for (final i in planFresh())
    if (i.time == '07:00')
      i.copyWith(status: CarePlanStatus.done, doneBy: mai.uid)
    else
      i,
];

typedef _Case = ({
  Widget child,
  Membership me,
  CarePlanPrefs prefs,
  Future<void> Function(WidgetTester)? act,
  double height,
});

Future<void> _sheet(WidgetTester tester, List<CarePlanItem> items) async {
  final context = tester.element(find.byType(Scaffold).first);
  // ignore: discarded_futures
  showClSheet<Object?>(
    context: context,
    builder: (_) => CarePlanDueSheet(items: items),
  );
  await tester.pumpAndSettle();
}

final _cases = <String, _Case>{
  'today_tasks': (
    child: const Scaffold(body: TodayScreen()),
    me: minh,
    prefs: const CarePlanPrefs(),
    act: null,
    height: 1100,
  ),
  'due_one': (
    child: const Scaffold(body: SizedBox.expand()),
    me: minh,
    prefs: const CarePlanPrefs(),
    act: (t) => _sheet(t, [_day().firstWhere((i) => i.time == '09:00')]),
    height: 812,
  ),
  'due_many': (
    child: const Scaffold(body: SizedBox.expand()),
    me: minh,
    prefs: const CarePlanPrefs(),
    act: (t) => _sheet(t, [
      for (final i in _day())
        if (i.assignees.contains(minh.uid) && i.time.compareTo('20:00') >= 0) i,
    ]),
    height: 812,
  ),
  'settings': (
    child: const CarePlanSettingsScreen(),
    me: minh,
    prefs: const CarePlanPrefs(),
    act: null,
    height: 812,
  ),
  'settings_off': (
    child: const CarePlanSettingsScreen(),
    me: lan,
    prefs: const CarePlanPrefs(leadMinutes: 0),
    act: null,
    height: 812,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('care plan today $name ${palette.name} $language', (
          tester,
        ) async {
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              c.child,
              locale: Locale(language),
              palette: palette,
              viewport: Size(375, c.height),
              overrides: <Override>[
                ...careOverrides(me: c.me, carePlan: false),
                ...carePlanOverrides(
                  days: {'2026-10-08': _day()},
                  prefs: c.prefs,
                ),
              ],
            );
            await tester.pumpAndSettle();
            await c.act?.call(tester);
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Overlay).first,
              matchesGoldenFile(
                'goldens/care_plan_today/${name}_${palette.name}_$language.png',
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
