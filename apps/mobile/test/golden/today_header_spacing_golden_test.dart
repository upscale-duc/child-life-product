@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:child_life/features/auto_save/auto_save_today.dart';
import 'package:child_life/features/auto_save/auto_save_widgets.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final state in ['photo', 'hidden', 'large', 'evening_no_banner']) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        testWidgets('$state ${palette.name} $lang', (tester) async {
          final hideDuty = state == 'hidden' || state == 'evening_no_banner';
          final bytes = (await rootBundle.load(
            'assets/premium/baby-newborn.jpg',
          )).buffer.asUint8List();
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              Scaffold(
                body: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(padding: const EdgeInsets.only(top: 47)),
                    child: const TodayScreen(),
                  ),
                ),
              ),
              palette: palette,
              locale: Locale(lang),
              textScaler: TextScaler.linear(state == 'large' ? 2 : 1),
              overrides: [
                if (state == 'evening_no_banner')
                  ...familyOverrides(
                    now: DateTime.utc(2026, 10, 8, 13),
                    records: mockDay(),
                  )
                else
                  ...careOverrides(),
                ...adaptiveOverrides(
                  band: AgeBand.b0_1,
                  repo: FakeExperienceRepository(
                    Experience.defaults(AgeBand.b0_1).copyWith(
                      shown: [
                        WidgetId.rhythm,
                        if (!hideDuty) WidgetId.careDuty,
                      ],
                      hidden: [if (hideDuty) WidgetId.careDuty],
                    ),
                  ),
                ),
                careDutyProvider(teddyId).overrideWith(
                  (ref) => Stream.value(CareDuty(uid: mai.uid, since: careNow)),
                ),
                headerPhotoProvider.overrideWith(
                  (ref, settings) => MemoryImage(bytes),
                ),
                libraryThumbLoaderProvider.overrideWithValue(
                  (_) async => bytes,
                ),
                autoSaveBannerProvider.overrideWithValue([
                  for (
                    var i = 0;
                    i < (state == 'evening_no_banner' ? 0 : 3);
                    i++
                  )
                    Candidate(
                      asset: AssetInfo(
                        id: 'portrait_$i',
                        captureAt: careNow.subtract(Duration(days: i)),
                      ),
                      match: const FaceMatch(
                        babyId: teddyId,
                        distance: .05,
                        face: 0,
                      ),
                    ),
                ]),
              ],
            );
            await tester.runAsync(
              () => precacheImage(
                MemoryImage(bytes),
                tester.element(find.byType(TodayScreen)),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Scaffold).first,
              matchesGoldenFile(
                'goldens/ths/${state}_${palette.name}_$lang.png',
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
