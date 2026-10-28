@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:child_life/features/today/header_appearance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final palette in ClPalette.values) {
    for (final lang in ['vi', 'en']) {
      testWidgets('settings ${palette.name} $lang', (tester) async {
        debugDisableShadows = false;
        try {
          await pumpRouted(
            tester,
            const RepaintBoundary(
              key: Key('settings-golden'),
              child: HeaderAppearanceScreen(),
            ),
            palette: palette,
            locale: Locale(lang),
            overrides: familyOverrides(now: DateTime.utc(2026, 10, 8, 7)),
          );
          await expectLater(
            find.byKey(const Key('settings-golden')),
            matchesGoldenFile('goldens/lh/settings_${palette.name}_$lang.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
  // D-135: the duty chip left the header, so "hidden" (no chip) is the only header now.
  const cases = [
    (name: 'morning', hour: 8, photo: false, scale: 1.0),
    (name: 'afternoon', hour: 14, photo: false, scale: 1.0),
    (name: 'evening', hour: 20, photo: false, scale: 1.0),
    (name: 'photo', hour: 20, photo: true, scale: 1.0),
    (name: 'large_photo', hour: 20, photo: true, scale: 2.0),
  ];
  for (final c in cases) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        testWidgets('${c.name} ${palette.name} $lang', (tester) async {
          debugDisableShadows = false;
          try {
            final now = DateTime.utc(2026, 10, 8, c.hour - 7);
            await pumpRouted(
              tester,
              Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          padding: const EdgeInsets.only(top: 47),
                          textScaler: TextScaler.linear(c.scale),
                        ),
                        child: RepaintBoundary(
                          key: const Key('header-golden'),
                          child: const TodayLivingHeader(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              palette: palette,
              locale: Locale(lang),
              overrides: [
                ...familyOverrides(
                  now: now,
                  duty: CareDuty(
                    uid: 'u_lan',
                    since: now.subtract(const Duration(minutes: 30)),
                  ),
                ),
                if (c.photo)
                  headerPhotoProvider.overrideWith(
                    (ref, settings) =>
                        const AssetImage('assets/premium/baby-newborn.jpg'),
                  ),
              ],
            );
            if (c.photo) {
              await tester.runAsync(
                () => precacheImage(
                  const AssetImage('assets/premium/baby-newborn.jpg'),
                  tester.element(find.byKey(const Key('header-golden'))),
                ),
              );
              await tester.pumpAndSettle();
            }
            await expectLater(
              find.byKey(const Key('header-golden')),
              matchesGoldenFile(
                'goldens/lh/${c.name}_${palette.name}_$lang.png',
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
