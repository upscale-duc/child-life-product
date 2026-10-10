@Tags(['golden'])
library;

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/appearance/appearance_screen.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/auth/auth_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:child_life/features/onboarding/welcome_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S2 screens in Light / Night care × vi / en at 375 × 812 (Figma frame size).
/// Regenerate on macOS: flutter test --tags golden --update-goldens
class _FixedDraft extends SetupDraftController {
  @override
  SetupDraft build() => SetupDraft(
    displayName: 'Mai',
    nickname: 'Teddy',
    dateOfBirth: DateTime(2026, 9, 17),
    timeZone: const TimeZoneSetting(zone: 'Asia/Ho_Chi_Minh', auto: true),
    requestId: '6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f',
  );
}

final _screens = <String, Widget Function()>{
  '01_welcome': () => const WelcomeScreen(),
  '02_tour': () => const TourScreen(),
  '06_sign_in': () => const SignInScreen(),
  '07_email': () => const EmailScreen(),
  '09_forgot': () => const ForgotPasswordScreen(),
  '10a_who': () => const WhoAreYouScreen(),
  '11_baby': () => const BabyProfileScreen(),
  '12_trackers': () => const TrackersScreen(),
  '13_appearance': () => const AppearanceScreen(),
};

void main() {
  for (final MapEntry(key: name, value: build) in _screens.entries) {
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
            routes: [GoRoute(path: '/', builder: (_, _) => build())],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                setupDraftProvider.overrideWith(_FixedDraft.new),
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
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/s2/${name}_${palette.name}_${locale.languageCode}.png',
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
