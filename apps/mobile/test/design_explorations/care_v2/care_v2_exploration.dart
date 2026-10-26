// Design exploration only (D-112, Care workflow v2). Renders the current Care screens and the
// prototype directions into docs/design/explorations/care-v2/assets/. Not a regression test:
//
//   cd apps/mobile && flutter test --update-goldens test/design_explorations/care_v2/care_v2_exploration.dart
//
// `--update-goldens` writes ONLY the images this file names (under docs/…/assets/); production
// baselines in test/golden/goldens are never touched. No `_test.dart` suffix: CI never runs it.
// Filter with --plain-name "<id>".
import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:child_life/features/care/history_screen.dart';
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
import '../../helpers/family_fixtures.dart';
import '../../helpers/library_fixtures.dart';
import '../../helpers/nutrition_fixtures.dart';
import '../../helpers/rhythm_fixtures.dart';
import '../../features/timer_test.dart' show sleepTimer;
import 'care_v2_prototypes.dart';

const _assets = '../../../../../docs/design/explorations/care-v2/assets';

class _Case {
  const _Case(this.build, this.overrides, {this.act, this.height = 812});
  final Widget Function() build;
  final List<Override> Function() overrides;
  final Future<void> Function(WidgetTester t)? act;
  final double height;
}

Widget _today() => const Scaffold(body: TodayScreen());
Future<void> _quickLog(WidgetTester t) async {
  showQuickLog(t.element(find.byType(TodayScreen)));
  await t.pumpAndSettle();
}

List<Override> _care() => careOverrides(growth: mockGrowth());

/// The hub as families see it on dev: every feature live (Nhịp lớn lên on, stages and articles
/// published, a nutrition stage for the baby's age). Without these the care fixture shows
/// "Sớm ra mắt" teasers that no real family sees.
List<Override> _careLive() => [
  ...careOverrides(growth: mockGrowth()),
  ...libraryOverrides(),
  ...nutritionOverrides(),
  capabilitiesProvider.overrideWith(
    (ref, babyId) async => Capabilities.fromJson(rhythmCaps(rhythm: true)),
  ),
];
List<Override> _sleeping() =>
    careOverrides(timers: {TimerType.sleep: sleepTimer()});

final _cases = <String, _Case>{
  // Production screens (the "before" set was copied to *_before_* on 2026-10-25 before D-112).
  'hub_current': _Case(() => const Scaffold(body: CareHubScreen()), _care, height: 1500),
  'hub_live_current': _Case(() => const Scaffold(body: CareHubScreen()), _careLive, height: 1500),
  'history_current': _Case(() => const HistoryScreen(filter: HistoryFilter.all), _care, height: 1700),
  'quicklog_current': _Case(_today, _care, act: _quickLog),
  'timer_current': _Case(() => const TimerScreen(type: TimerType.sleep), _sleeping),
  'manual_current': _Case(() => const ManualSleepScreen(), careOverrides),
  'manual_overnight_current': _Case(
    () => ManualSleepScreen(edit: rec(CareType.sleep, vn(7, 21, 40), minh, endedAt: vn(8, 4, 30))),
    careOverrides,
  ),
  // Prototypes.
  ...prototypeCases.map((k, v) => MapEntry(k, _Case(v.build, v.sleeping ? _sleeping : _care, act: v.quickLog ? (t) async {
        await t.tap(find.byKey(const Key('openProto')));
        await t.pumpAndSettle();
      } : null, height: v.height))),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        for (final scale in const [1.0, 2.0]) {
          // 200 % only in Light vi: the large-text check for each candidate.
          if (scale == 2.0 && (palette != ClPalette.light || locale.languageCode != 'vi')) continue;
          testWidgets('$name ${palette.name} ${locale.languageCode} $scale', (tester) async {
            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            final size = Size(375, scale == 2.0 ? 812 : c.height);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final router = GoRouter(routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(path: '/:a', builder: (_, _) => const Scaffold(body: Text('stub'))),
              GoRoute(path: '/:a/:b', builder: (_, _) => const Scaffold(body: Text('stub'))),
            ]);
            await tester.pumpWidget(ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith((ref) => Stream.value(DateTime(2026, 10, 8, 10))),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true, textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 47, bottom: 34)),
                child: RepaintBoundary(
                  key: const ValueKey('shot'),
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: buildClTheme(palette),
                    locale: locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
                    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
                    routerConfig: router,
                  ),
                ),
              ),
            ));
            await tester.pumpAndSettle();
            await c.act?.call(tester);
            final errors = <String>[];
            Object? e;
            while ((e = tester.takeException()) != null) {
              errors.add('$e'.split('\n').first);
            }
            if (errors.isNotEmpty) debugPrint('OVERFLOW $name ${palette.name} ${locale.languageCode} $scale: ${errors.toSet().join(' | ')}');
            debugDisableShadows = false;
            try {
              await expectLater(find.byKey(const ValueKey('shot')),
                  matchesGoldenFile('$_assets/${name}_${palette.name}_${locale.languageCode}${scale == 2.0 ? '_200' : ''}.png'));
            } finally {
              debugDisableShadows = true;
            }
          });
        }
      }
    }
  }
}
