@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:child_life/features/app_update/app_update_models.dart';
import 'package:child_life/features/app_update/app_update_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_update_fixtures.dart';

/// App updates (v1.0 improvement UP1–UP6, D-061) in Light / Night care × vi / en.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

final _v = AppVersion.tryParse;

final _cases = <String, _Case>{
  // UP1 469:6454.
  'up1_required': (
    build: () => const AppUpdateGate(child: SizedBox()),
    overrides: appUpdateOverrides(config: sampleConfig(minimum: '1.1.0')),
    prefs: const {},
    act: null,
  ),
  // UP2 469:6502 (the sheet; Hôm nay behind it is out of scope).
  'up2_available': (
    build: () => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showClSheet<void>(
              context: context,
              builder: (_) => UpdateSheet(
                status: UpdateAvailable(
                  installed: _v('1.0.3')!,
                  latest: _v('1.2.0')!,
                ),
                release: sampleRelease(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: appUpdateOverrides(config: sampleConfig()),
    prefs: const {},
    act: (tester) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    },
  ),
  // UP3 469:6583 (no picture in tests: the placeholder stands in).
  'up3_whats_new': (
    build: () => WhatsNewScreen(release: sampleRelease()),
    overrides: appUpdateOverrides(config: sampleConfig(), installed: '1.2.0'),
    prefs: const {},
    act: null,
  ),
  // UP5 469:54000 and UP6 469:54094.
  'up5_up6_banner_row': (
    build: () => const Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 60, 16, 0),
        child: Column(
          children: [
            WhatsNewBanner(),
            SizedBox(height: 16),
            ClCardGroup(children: [AppVersionRow()]),
          ],
        ),
      ),
    ),
    overrides: appUpdateOverrides(
      config: sampleConfig(latest: '1.3.0'),
      installed: '1.2.0',
    ),
    prefs: const {'appUpdate.lastRun': '1.0.3'},
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
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...c.overrides,
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp(
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
                    home: c.build(),
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
                'goldens/up/${name}_${palette.name}_${locale.languageCode}.png',
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
