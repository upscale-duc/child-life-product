@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/adaptive_setup.dart';
import 'package:child_life/features/adaptive/explore_screen.dart';
import 'package:child_life/features/assistant/lumi_button.dart';
import 'package:child_life/features/home/home_shell.dart'
    show adaptiveNavProvider;
import 'package:child_life/features/me/me_screen.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:child_life/features/adaptive/today_adaptive.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// Adaptive Experience (Figma 930:11858, P-175, D-097): Hôm nay per age band (AX10–AX13), the
/// first run (AX40, AX42), Tuỳ chỉnh Hôm nay (AX14) and the goals (AX04), in Light / Night care
/// × vi / en at 375 × 812, on the S4 mock day. Regenerate on macOS:
/// flutter test --tags golden --update-goldens test/golden/adaptive_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _today() => const Scaffold(body: TodayScreen());

final _photos = [
  for (var d = 0; d < 3; d++) mediaItem('mem_$d', DateTime(2026, 10, 7 - d)),
];

List<Override> _band(
  AgeBand band, {
  bool empty = false,
  bool nav = false,
  int? months,
  Experience? exp,
}) => [
  ...careOverrides(
    records: empty ? const [] : null,
    growth: empty ? const [] : mockGrowth(),
  ),
  ...adaptiveOverrides(
    band: band,
    repo: FakeExperienceRepository(exp ?? Experience.defaults(band)),
    media: empty ? const [] : _photos,
    nav: nav,
    months: months,
  ),
];

/// Setup for Na, 4 years 7 months on the mock day (8 Oct 2026), goals as preset.
List<Override> _setup({AdaptiveSetup setup = const AdaptiveSetup()}) => [
  setupAdaptiveProvider.overrideWithValue(true),
  sessionProvider.overrideWithValue(
    SessionSignedIn(
      user: FakeUser(uid: mai.uid),
      memberships: const [],
    ),
  ),
  setupDraftProvider.overrideWith(
    () => _Draft(
      SetupDraft(
        nickname: 'Na',
        dateOfBirth: DateTime(2022, 3, 12),
        trackers: const {TrackerKind.growth},
        requestId: '00000000-0000-4000-8000-000000000001',
      ),
    ),
  ),
  adaptiveSetupProvider.overrideWith(() => _Setup(setup)),
];

class _Draft extends SetupDraftController {
  _Draft(this.initial);
  final SetupDraft initial;
  @override
  SetupDraft build() => initial;
}

class _Setup extends AdaptiveSetupController {
  _Setup(this.initial);
  final AdaptiveSetup initial;
  @override
  AdaptiveSetup build() => initial;
}

final _cases = <String, _Case>{
  'ax02_baby_4y': (build: BabyProfileScreen.new, overrides: _setup, act: null),
  'ax04_setup_goals_4y': (
    build: SetupGoalsScreen.new,
    overrides: _setup,
    act: null,
  ),
  'ax06_preview_4y': (
    build: SetupPreviewScreen.new,
    overrides: () => _setup(
      setup: const AdaptiveSetup(
        goals: [Goal.memories, Goal.family, Goal.spending],
      ),
    ),
    act: null,
  ),
  'ax20_explore_0_1': (
    build: () => const Scaffold(body: ExploreScreen()),
    overrides: () => _band(AgeBand.b0_1, nav: true),
    act: null,
  ),
  'ax21_explore_3_6': (
    build: () => const Scaffold(body: ExploreScreen()),
    overrides: () => _band(AgeBand.b3_6, nav: true),
    act: null,
  ),
  'ax45_explore_none': (
    build: () => const Scaffold(body: ExploreScreen()),
    overrides: () => _band(AgeBand.b3_6, nav: true),
    act: (t) async {
      await t.enterText(find.byType(TextField), 'học tập');
      await t.pumpAndSettle();
    },
  ),
  'ax34_profile': (
    build: () => const MeScreen(asTab: true),
    overrides: () => [
      ...careOverrides(growth: mockGrowth()),
      ...memoryOverrides(),
      ...meOverrides(),
      adaptiveNavProvider.overrideWithValue(true),
    ],
    act: null,
  ),
  'ax_dock_v2': (
    build: () => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ClTabDock(
          role: ClRole.parent,
          tabs: tabsForRoleV2(ClRole.parent),
          active: ClTab.today,
          onSelect: (_) {},
          action: ClDockAction(label: 'Ghi nhanh', onPressed: () {}),
          trailing: AsFloatingButton(onPressed: () {}, attention: false),
        ),
      ),
    ),
    overrides: () => _band(AgeBand.b0_1),
    act: null,
  ),
  'ax33_stage_12m': (
    build: _today,
    overrides: () =>
        _band(AgeBand.b1_3, months: 12, exp: Experience.defaults(AgeBand.b0_1)),
    act: null,
  ),
  'ax10_today_0_1': (
    build: _today,
    overrides: () => _band(AgeBand.b0_1),
    act: null,
  ),
  'ax11_today_1_3': (
    build: _today,
    overrides: () => _band(AgeBand.b1_3),
    act: null,
  ),
  'ax12_today_3_6': (
    build: _today,
    overrides: () => _band(AgeBand.b3_6),
    act: null,
  ),
  'ax13_today_6_12': (
    build: _today,
    overrides: () => _band(AgeBand.b6_12),
    act: null,
  ),
  'ax40_first_0_1': (
    build: _today,
    overrides: () => _band(AgeBand.b0_1, empty: true),
    act: null,
  ),
  'ax42_first_3_6': (
    build: _today,
    overrides: () => _band(AgeBand.b3_6, empty: true),
    act: null,
  ),
  'ax14_customize_3_6': (
    build: AxCustomizeScreen.new,
    overrides: () => _band(AgeBand.b3_6),
    act: null,
  ),
  'ax04_goals_3_6': (
    build: () => AxGoalsScreen(
      name: 'Teddy',
      band: AgeBand.b3_6,
      selected: presetGoals[AgeBand.b3_6]!,
      ageLabel: '4 tuổi',
    ),
    overrides: () => _band(AgeBand.b3_6),
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
                'goldens/ax/${name}_${palette.name}_${locale.languageCode}.png',
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
