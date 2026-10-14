@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_gate.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/premium_test.dart' show answer;
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';

/// Premium & Cá nhân hoá, Slice 1 (plan §7 E4 / Q1): PR03 Gói của hộ and MO02 in Light /
/// Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

List<Override> _caps(Map<String, Object?> json, {bool owner = true}) => [
  selectedMembershipProvider.overrideWithValue(owner ? mai : minh),
  capabilitiesProvider.overrideWith(
    (ref, babyId) async => Capabilities.fromJson(json),
  ),
];

final _cases = <String, _Case>{
  // PR03 593:6931, free household, the owner's view.
  'pr03_free_owner': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(answer()),
    prefs: const {},
    act: null,
  ),
  // PR03, Premium bought by the owner; Ba sees "Hộ đã có Premium" (D-072 #1).
  'pr03_premium_member': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(
        plan: 'premium',
        templates: true,
        owner: false,
        validUntil: '2026-11-14T00:00:00.000Z',
        autoRenew: true,
      ),
      owner: false,
    ),
    prefs: const {},
    act: null,
  ),
  // PR03, beta of group A until a date.
  'pr03_beta': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(plan: 'beta', validUntil: '2026-12-01T00:00:00.000Z'),
    ),
    prefs: const {},
    act: null,
  ),
  // MO02 592:6782 for a beta family: the beta does not include Premium templates.
  'mo02_beta': (
    build: () => Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: TextButton(
            onPressed: () => ensureTemplateAllowed(
              context,
              ref,
              template: seedCatalog().cards.firstWhere(
                (t) => t.id == 'card_blush',
              ),
              catalog: const KeepsakeCatalog(
                [],
                premiumAccess: PremiumAccess.subscribers,
              ),
              babyId: teddyId,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: _caps(answer(plan: 'beta')),
    prefs: const {},
    act: (tester) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    },
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
                'goldens/pm/${name}_${palette.name}_${locale.languageCode}.png',
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
