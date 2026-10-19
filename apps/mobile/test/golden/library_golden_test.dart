@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/library/stage_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/library_fixtures.dart';
import '../helpers/solids_fixtures.dart' show articlesWithSolids;

/// Thư viện chăm bé (4a, 4b, 4c, 4d, 4f) and Giai đoạn của bé (2a, 2b, 2c) in Light / Night care
/// × vi / en at 375 × 812, on the TEST-ONLY fixtures (pictures are the topic placeholders).
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/library_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

_Case _c(
  Widget Function() build, {
  List<Override> Function()? overrides,
  Future<void> Function(WidgetTester t)? act,
}) => (
  build: build,
  overrides:
      overrides ??
      () => [
        ...careOverrides(firstAid: seedFirstAidPack()),
        ...libraryOverrides(
          saved: [
            (
              id: 'art_diaper_rash',
              savedAt: DateTime(2026, 9, 28),
              revision: 1,
            ),
          ],
        ),
      ],
  act: act,
);

List<Override> _guide() => [
  ...careOverrides(firstAid: seedFirstAidPack()),
  ...libraryOverrides(articles: [...articlesWithSolids(), readerGuide()]),
];

final _cases = <String, _Case>{
  'lb4a_library': _c(() => const LibraryHomeScreen()),
  'lb4b_search': _c(
    () => const LibrarySearchScreen(),
    act: (t) async {
      await t.enterText(find.byKey(const Key('lbQuery')), 'ngủ');
      await t.pumpAndSettle();
    },
  ),
  'lb4c_filters': _c(
    () => const LibrarySearchScreen(),
    act: (t) async {
      await t.tap(find.byKey(const Key('lbFilters')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('lbChip_sleep')));
      await t.tap(find.byKey(const Key('lbChip_m0to3')));
      await t.pumpAndSettle();
    },
  ),
  'lb4d_article': _c(() => const ArticleScreen(articleId: 'art_newborn_sleep')),
  // D-087 reading layouts (P-166 #2–#3) on an Ăn dặm step guide: takeaways, contents, steps;
  // further down the myth cards and "Lên đầu", then the urgent callout with "Gọi 115".
  'lb4d_guide': _c(
    () => const ArticleScreen(articleId: 'art_solids_first_meal_guide'),
    overrides: _guide,
  ),
  'lb4d_guide_end': _c(
    () => const ArticleScreen(articleId: 'art_solids_first_meal_guide'),
    overrides: _guide,
    act: (t) async {
      await t.drag(find.byType(ListView), const Offset(0, -700));
      await t.pumpAndSettle();
    },
  ),
  'lb4d_guide_urgent': _c(
    () => const ArticleScreen(articleId: 'art_solids_first_meal_guide'),
    overrides: _guide,
    act: (t) async {
      await t.drag(find.byType(ListView), const Offset(0, -1000));
      await t.pumpAndSettle();
    },
  ),
  'lb4e_saved_toast': _c(
    () => const ArticleScreen(articleId: 'art_bath'),
    act: (t) async {
      await t.tap(find.byKey(const Key('lbSave')));
      await t.pump(const Duration(milliseconds: 400));
    },
  ),
  'lb4f_saved': _c(
    () => const SavedArticlesScreen(),
    overrides: () => [
      ...careOverrides(),
      ...libraryOverrides(
        saved: [
          (
            id: 'art_newborn_sleep',
            savedAt: DateTime(2026, 10, 8, 9),
            revision: 1,
          ),
          (id: 'art_pumping', savedAt: DateTime(2026, 10, 2), revision: 1),
          (id: 'art_diaper_rash', savedAt: DateTime(2026, 9, 28), revision: 1),
        ],
      ),
    ],
  ),
  'lb2a_stages': _c(() => const StagesScreen()),
  'lb2b_stage': _c(() => const StageDetailScreen(stageId: 'stg_w3')),
  // 2c as drawn: no date of birth, and offline with the copy on the phone.
  'lb2c_no_dob': _c(
    () => const StagesScreen(),
    overrides: () => [
      ...careOverrides(
        online: false,
      ).where((o) => !'$o'.contains('<BabyPrivateProfile?')),
      ...libraryOverrides(fromCache: true),
      babyPrivateProfileProvider.overrideWith(
        (ref, id) => Stream.value(
          BabyPrivateProfile.fromJson(const {'dateOfBirth': ''}),
        ),
      ),
    ],
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues(const {});
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
                'goldens/lb/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
          // Let the toast's timer run out.
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
