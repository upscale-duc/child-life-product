// Care pass probe (not a baseline): renders Care screens at 200 % text and records overflows.
// Run: flutter test --update-goldens test/design_explorations/care_probe/care_scale_probe_test.dart
import 'dart:io';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_screens.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/care/timer_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/care_fixtures.dart';
import '../../features/timer_test.dart' show breastTimer, pumpTimer, sleepTimer;

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _today() => const Scaffold(body: TodayScreen());
Future<void> Function(WidgetTester) _open(CareType type) => (tester) async {
  openCareLog(tester.element(find.byType(TodayScreen)), type);
  await tester.pumpAndSettle();
};
final _bottle = mockDay().first;

final _cases = <String, _Case>{
  'hub': (
    build: () => const Scaffold(body: CareHubScreen()),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  'quick_log': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: (t) async {
      showQuickLog(t.element(find.byType(TodayScreen)));
      await t.pumpAndSettle();
    },
  ),
  'bottle': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.bottle),
  ),
  'breast': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.breast),
  ),
  'pump': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.pump),
  ),
  'diaper': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.diaper),
  ),
  'detail': (
    build: () => RecordDetailScreen(recordId: _bottle.id),
    overrides: () => careOverrides(byId: {_bottle.id: _bottle}),
    act: null,
  ),
  'growth': (
    build: () => const GrowthScreen(),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  'history': (
    build: () => const HistoryScreen(filter: HistoryFilter.all),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  'history_feed': (
    build: () => const HistoryScreen(filter: HistoryFilter.feed),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  'history_sleep': (
    build: () => const HistoryScreen(filter: HistoryFilter.sleep),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  'feed_stats': (
    build: () => const FeedStatsScreen(),
    overrides: careOverrides,
    act: null,
  ),
  'sleep_stats': (
    build: () => const SleepStatsScreen(),
    overrides: careOverrides,
    act: null,
  ),
  'sleep_timer': (
    build: () => const TimerScreen(type: TimerType.sleep),
    overrides: () => careOverrides(timers: {TimerType.sleep: sleepTimer()}),
    act: null,
  ),
  'breast_timer': (
    build: () => const TimerScreen(type: TimerType.breast),
    overrides: () => careOverrides(timers: {TimerType.breast: breastTimer()}),
    act: null,
  ),
  'pump_timer': (
    build: () => const TimerScreen(type: TimerType.pump),
    overrides: () => careOverrides(timers: {TimerType.pump: pumpTimer()}),
    act: null,
  ),
  'manual_sleep': (
    build: () => const ManualSleepScreen(),
    overrides: () => careOverrides(),
    act: null,
  ),
  'sleep_chooser': (
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
};

const _scale = int.fromEnvironment('SCALE', defaultValue: 200) / 100;

void main() {
  final log = File('test/design_explorations/care_probe/overflows_$_scale.txt');
  setUpAll(() {
    if (log.existsSync()) log.deleteSync();
  });
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      testWidgets('$name ${locale.languageCode}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) =>
            errors.add(d.exceptionAsString().split('\n').first);
        addTearDown(() => FlutterError.onError = old);
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
              data: MediaQueryData(
                size: Size(375, 812),
                disableAnimations: true,
                textScaler: TextScaler.linear(_scale),
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: RepaintBoundary(
                key: const ValueKey('golden'),
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: buildClTheme(ClPalette.light),
                  locale: locale,
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(_scale)),
                    child: child!,
                  ),
                  routerConfig: router,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        try {
          await c.act?.call(tester);
        } catch (e) {
          errors.add('act: $e'.split('\n').first);
        }
        Object? e;
        while ((e = tester.takeException()) != null) {
          errors.add('$e'.split('\n').first);
        }
        log.writeAsStringSync(
          '$name ${locale.languageCode}: ${errors.isEmpty ? 'ok' : errors.toSet().join(' | ')}\n',
          mode: FileMode.append,
        );
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('out_$_scale/${name}_${locale.languageCode}.png'),
        );
      });
    }
  }
}
