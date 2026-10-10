@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/care/timer_screens.dart';
import 'package:child_life/features/home/today_tour.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../features/timer_test.dart' show breastTimer, pumpTimer, sleepTimer;

/// S5 timers, sleep, overlap and the first-run tour in Light / Night care × vi / en at 375 × 812 (Figma frame size), on
/// the 19 mock day (Thursday 8 Oct, 15:05). Sheets open over Today, as drawn.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _today() => const Scaffold(body: TodayScreen());

final _dads = rec(CareType.sleep, vn(7, 21, 40), minh, endedAt: vn(7, 23, 6));
final _mine = rec(
  CareType.sleep,
  vn(7, 21, 42),
  mai,
  endedAt: vn(7, 23, 10),
  pending: true,
);
final _conflict = SleepConflict(
  id: '${_dads.id}__${_mine.id}',
  recordIds: [_dads.id, _mine.id],
  laterAuthor: mai.uid,
);

final _cases = <String, _Case>{
  '25_sleep_timer': (
    build: () => const TimerScreen(type: TimerType.sleep),
    overrides: () => careOverrides(timers: {TimerType.sleep: sleepTimer()}),
    act: null,
  ),
  '9c_timer_offline': (
    build: () => const TimerScreen(type: TimerType.sleep),
    overrides: () =>
        careOverrides(timers: {TimerType.sleep: sleepTimer(pending: true)}),
    act: null,
  ),
  '23b_breast_timer': (
    build: () => const TimerScreen(type: TimerType.breast),
    overrides: () => careOverrides(timers: {TimerType.breast: breastTimer()}),
    act: null,
  ),
  '23c_pump_timer': (
    build: () => const TimerScreen(type: TimerType.pump),
    overrides: () => careOverrides(timers: {TimerType.pump: pumpTimer()}),
    act: null,
  ),
  '25a_sleep_chooser': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: (t) async {
      await t.tap(
        find.byWidgetPredicate(
          (w) => w is CareTile && w.type == CareType.sleep,
        ),
      );
      await t.pumpAndSettle();
    },
  ),
  '26_manual_sleep': (
    build: () => const ManualSleepScreen(),
    overrides: () => careOverrides(),
    act: null,
  ),
  '27_overlap': (
    build: () => OverlapScreen(conflictId: _conflict.id),
    overrides: () => careOverrides(
      conflicts: [_conflict],
      byId: {_dads.id: _dads, _mine.id: _mine},
    ),
    act: (t) async {
      await t.tap(findTabular('21:40 – 23:06'));
      await t.pumpAndSettle();
    },
  ),
  '19_sleep_running': (
    build: _today,
    overrides: () => careOverrides(
      growth: mockGrowth(),
      timers: {TimerType.sleep: sleepTimer()},
    ),
    act: null,
  ),
  '18_tour': (
    build: () => const Scaffold(
      body: Stack(
        children: [
          TodayScreen(),
          Positioned.fill(child: TodayTour(babyNickname: 'Teddy')),
        ],
      ),
    ),
    overrides: () =>
        careOverrides(records: const [], growth: const [], reminders: const []),
    act: (t) async => t.pumpAndSettle(),
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: buildClTheme(palette),
                    locale: locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    routerConfig: router,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/s5/${name}_${palette.name}_${locale.languageCode}.png',
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
