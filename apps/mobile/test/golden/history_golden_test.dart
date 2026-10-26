@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
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

/// S6 history and statistics in Light / Night care × vi / en at 375 × 812, on the mock week
/// ending Thursday 8 Oct, 15:05.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

_Case _history(
  HistoryFilter filter, {
  List<CareRecord>? range,
  bool loading = false,
  List<CareRecord> Function() growth = mockGrowth,
  Membership? me,
  Future<void> Function(WidgetTester tester)? act,
}) => (
  build: () => HistoryScreen(filter: filter),
  overrides: () => careOverrides(
    range: range,
    rangeLoading: loading,
    growth: growth(),
    me: me,
  ),
  prefs: const {},
  act: act,
);

Future<void> _headTab(WidgetTester t) async {
  final vi = find.text('Vòng đầu');
  await t.tap(vi.evaluate().isNotEmpty ? vi : find.text('Head'));
  await t.pumpAndSettle();
}

final _cases = <String, _Case>{
  '20_history': _history(HistoryFilter.all),
  '20a_history_feed': _history(HistoryFilter.feed),
  '20b_history_sleep': _history(HistoryFilter.sleep),
  '20c_history_diaper': _history(HistoryFilter.diaper),
  '20d_history_growth': _history(HistoryFilter.growth),
  // Owner 2026-10-16: the "Vòng đầu" tab, measured and not measured yet.
  '20d_history_growth_head': _history(
    HistoryFilter.growth,
    growth: mockGrowthWithHead,
    act: _headTab,
  ),
  '20d_history_growth_head_none': _history(HistoryFilter.growth, act: _headTab),
  '20e_history_empty': _history(HistoryFilter.diaper, range: const []),
  // Care pass (D-109): records still loading draw a skeleton, never the empty day.
  '20i_history_loading': _history(HistoryFilter.diaper, loading: true),
  '20f_date_picker': _history(
    HistoryFilter.all,
    act: (t) async {
      await t.tap(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_MonthChip'),
      );
      await t.pumpAndSettle();
    },
  ),
  '12d_history_caregiver': _history(HistoryFilter.all, me: lan),
  '20g_feed_stats': (
    build: () => const FeedStatsScreen(),
    overrides: careOverrides,
    prefs: const {},
    act: null,
  ),
  '20j_sleep_stats_loading': (
    build: () => const SleepStatsScreen(),
    overrides: () => careOverrides(rangeLoading: true),
    prefs: const {},
    act: null,
  ),
  '20g2_feed_stats_today': (
    build: () => const FeedStatsScreen(),
    overrides: careOverrides,
    prefs: const {'stats.feed.window': 'today'},
    act: null,
  ),
  '20g_feed_stats_30': (
    build: () => const FeedStatsScreen(),
    overrides: careOverrides,
    prefs: const {'stats.feed.window': 'month'},
    act: null,
  ),
  '20h_sleep_stats': (
    build: () => const SleepStatsScreen(),
    overrides: careOverrides,
    prefs: const {},
    act: null,
  ),
  // "Từng ngày" (owner 2026-10-22): the range day by day, 0–24 h, with the day's totals.
  '20g_feed_stats_days': (
    build: () => const FeedStatsScreen(),
    overrides: careOverrides,
    prefs: const {},
    act: (t) async {
      await t.scrollUntilVisible(
        find.byType(CareDaysTimeline),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Its title at the top of the screen.
      await t.ensureVisible(find.byType(CareDaysTimeline));
      await t.pumpAndSettle();
    },
  ),
  '20h_sleep_stats_days': (
    build: () => const SleepStatsScreen(),
    overrides: careOverrides,
    prefs: const {},
    act: (t) async {
      await t.scrollUntilVisible(
        find.byType(CareDaysTimeline),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Its title at the top of the screen.
      await t.ensureVisible(find.byType(CareDaysTimeline));
      await t.pumpAndSettle();
    },
  ),
  '20h_sleep_stats_today': (
    build: () => const SleepStatsScreen(),
    overrides: careOverrides,
    prefs: const {'stats.sleep.window': 'today'},
    act: null,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues(c.prefs);
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
                'goldens/s6/${name}_${palette.name}_${locale.languageCode}.png',
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
