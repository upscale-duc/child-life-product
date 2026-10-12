@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/utilities/utilities_screen.dart';
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
import '../helpers/family_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';

/// Tiện ích tab (v1.0 improvement 450:6597; caregiver 450:6873) in Light / Night care × vi / en.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

final _pack = seedFirstAidPack();

final _cases = <String, _Case>{
  'ut_parent': (
    build: () => const Scaffold(body: UtilitiesScreen()),
    overrides: () => careOverrides(firstAid: _pack),
    prefs: const {},
    act: null,
  ),
  'ut_caregiver': (
    build: () => const Scaffold(body: UtilitiesScreen()),
    overrides: () => careOverrides(me: lan, firstAid: _pack),
    prefs: const {},
    act: null,
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
                'goldens/ut/${name}_${palette.name}_${locale.languageCode}.png',
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
