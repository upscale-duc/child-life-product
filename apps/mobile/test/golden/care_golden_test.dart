@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_screens.dart';
import 'package:child_life/features/care/care_sheets.dart';
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

/// S4 screens and sheets in Light / Night care × vi / en at 375 × 812 (Figma frame size), on
/// the 19 mock day (Thursday 8 Oct, 15:05). Sheets open over Today, as drawn.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _today() => const Scaffold(body: TodayScreen());

Future<void> Function(WidgetTester) _open(
  CareType type, [
  List<String> typed = const [],
]) => (tester) async {
  openCareLog(tester.element(find.byType(TodayScreen)), type);
  await tester.pumpAndSettle();
  for (final (i, text) in typed.indexed) {
    await tester.enterText(find.byType(EditableText).at(i), text);
  }
  await tester.pumpAndSettle();
};

final _bottle = mockDay().first;

final _cases = <String, _Case>{
  '19_today': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: null,
  ),
  '9a_today_offline': (
    build: _today,
    overrides: () => careOverrides(
      records: mockDay(offline: true),
      growth: mockGrowth(),
      online: false,
    ),
    act: null,
  ),
  '9b_pending': (
    build: _today,
    overrides: () => careOverrides(
      records: mockDay(offline: true),
      growth: mockGrowth(),
      online: false,
    ),
    act: (t) async {
      await t.tap(
        find.textContaining(RegExp('offline', caseSensitive: false)).first,
      );
      await t.pumpAndSettle();
    },
  ),
  '19a_quick_log': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: (t) async {
      showQuickLog(t.element(find.byType(TodayScreen)));
      await t.pumpAndSettle();
    },
  ),
  '22_bottle': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.bottle, ['120']),
  ),
  '23_breast': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.breast, ['15']),
  ),
  '23a_pump': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.pump, ['90']),
  ),
  '24_diaper': (
    build: _today,
    overrides: () => careOverrides(growth: mockGrowth()),
    act: _open(CareType.diaper),
  ),
  '28_growth': (
    build: () => const GrowthScreen(),
    overrides: () => careOverrides(growth: mockGrowth()),
    act: (t) async {
      await t.enterText(find.byType(EditableText).at(0), '4,3');
      await t.enterText(find.byType(EditableText).at(1), '54,5');
      await t.pumpAndSettle();
    },
  ),
  '21_record_detail': (
    build: () => RecordDetailScreen(recordId: _bottle.id),
    overrides: () => careOverrides(byId: {_bottle.id: _bottle}),
    act: null,
  ),
  '12e_view_only': (
    build: () => RecordDetailScreen(recordId: _bottle.id),
    overrides: () => careOverrides(me: lan, byId: {_bottle.id: _bottle}),
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
                'goldens/s4/${name}_${palette.name}_${locale.languageCode}.png',
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
