@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/first_aid/first_aid_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';

/// Sơ cứu trẻ em (Figma v1.1 7b–7i, TH01–TH24) in Light / Night care × vi / en at 375 × 812 with
/// the seed pack; pictures are flat colours (the real ones come from Storage).
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

final _pack = seedFirstAidPack();

_Case _c(
  Widget Function() build, {
  Future<void> Function(WidgetTester t)? act,
}) => (
  build: build,
  overrides: () => careOverrides(firstAid: _pack),
  prefs: const {},
  act: act,
);

final _cases = <String, _Case>{
  'fa7b_index': _c(() => const FirstAidHomeScreen()),
  'fa7c_search': _c(
    () => const FirstAidSearchScreen(),
    act: (t) async {
      await t.enterText(find.byKey(const Key('faQuery')), 'sốt');
      await t.pumpAndSettle();
    },
  ),
  'fa7d_choking': _c(
    () => const FirstAidSituationScreen(situationId: 'choking'),
  ),
  'fa_th24_jaundice': _c(
    () => const FirstAidSituationScreen(situationId: 'jaundice'),
  ),
  'fa_th01_cpr': _c(
    () =>
        const FirstAidSituationScreen(situationId: 'cpr', variantId: 'under-1'),
  ),
  'fa_th08_read_aloud': _c(
    () => const FirstAidSituationScreen(situationId: 'nosebleed'),
  ),
  'fa7h_calling': _c(
    () =>
        const FirstAidSituationScreen(situationId: 'cpr', variantId: 'under-1'),
    act: (t) async {
      await t.tap(find.byKey(const Key('faCall')).last);
      await t.pump();
    },
  ),
};

/// Storage images decode outside the fake clock: let every visible one finish first.
Future<void> _precacheImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isEmpty) return;
  await tester.runAsync(() async {
    for (final image in images) {
      final element = tester.element(find.byWidget(image).first);
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

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
          await _precacheImages(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/fa/${name}_${palette.name}_${locale.languageCode}.png',
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
