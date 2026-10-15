@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_personalize.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/hn_fixtures.dart';
import '../helpers/reminder_fixtures.dart';

/// Hôm nay · cá nhân hoá (D-076 #1, #4, #8): EN01, EN02, EN03, Hôm nay with the invite
/// (559:57870), "Dành cho bé hôm nay" (559:57583) and Tuỳ chỉnh Hôm nay with the section after
/// the tiles — Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/hn_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
  double height,
});

Future<void> _continue(WidgetTester t) async {
  await t.tap(find.byType(ClButton).first);
  await t.pumpAndSettle();
}

/// The section as it sits on Hôm nay, under the tiles.
Widget _section() => Builder(
  builder: (context) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        children: const [TodayForBabySection()],
      ),
    ),
  ),
);

CheckIn _soothing(String date, String uid) => CheckIn(
  id: 'ci_$date$uid',
  babyId: teddyId,
  date: date,
  authorUid: uid,
  observation: Observation.soothing,
);

final _cases = <String, _Case>{
  // EN01 559:2288 with three interests picked.
  'en01_interests': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: (t) async {
      final tiles = find.byType(InterestTile);
      for (final i in const [0, 1, 2]) {
        await t.tap(tiles.at(i));
      }
      await t.pumpAndSettle();
    },
    height: 900,
  ),
  // EN02 559:2383: the evening round-up, quiet hours on.
  'en02_digest': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: _continue,
    height: 812,
  ),
  // EN03 559:2458, on a phone that does not show notifications yet.
  'en03_notifications': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(),
      notifications: FakeReminderNotifications(on: false),
    ),
    act: (t) async {
      await _continue(t);
      await _continue(t);
    },
    height: 812,
  ),
  // 559:57870 for someone who has not personalised (joined by invite, or skipped).
  'home_invite': (
    build: () => const Scaffold(body: TodayScreen()),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: null,
    height: 812,
  ),
  // 559:57583: interests line, Nhịp lớn lên card with the family's soothing notes, the
  // check-in and age cards of Nhịp lớn lên, then small cards from other modules.
  'home_for_baby': (
    build: _section,
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(
        preferences: personalized(),
        checkIns: [
          _soothing('2026-10-07', 'u_mai'),
          _soothing('2026-10-06', 'u_minh'),
        ],
      ),
      articles: sampleForBabyCards().take(1).toList(),
      milestones: sampleForBabyCards().skip(1).toList(),
    ),
    act: null,
    height: 1100,
  ),
  // Tuỳ chỉnh Hôm nay: "Dành cho bé hôm nay" right after the tiles (D-076 #8).
  'customize': (
    build: () => const Scaffold(body: TodayScreen()),
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(preferences: personalized()),
    ),
    act: (t) async {
      showTodayCustomizeSheet(t.element(find.byType(TodayScreen)));
      await t.pumpAndSettle();
    },
    height: 900,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({
            // The first-run tour already ran.
            'tour.today.done': true,
            'rhythm.setupSeen.u_mai.$teddyId': true,
          });
          final prefs = await SharedPreferences.getInstance();
          final size = Size(375, c.height);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
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
                  size: size,
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
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
                'goldens/hn/${name}_${palette.name}_${locale.languageCode}.png',
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
