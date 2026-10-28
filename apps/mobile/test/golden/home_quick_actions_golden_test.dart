@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/baby/baby_models.dart';
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
  for (final state in ['evening', 'afternoon', 'long_name', 'large']) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        testWidgets('$state ${palette.name} $lang', (tester) async {
          final bytes = (await rootBundle.load(
            'assets/premium/baby-newborn.jpg',
          )).buffer.asUint8List();
          final baby = Baby(
            id: teddy.id,
            familyId: teddy.familyId,
            ownerUid: teddy.ownerUid,
            nickname: state == 'long_name' ? 'Minh Khôi' : 'Teddy',
            avatar: teddy.avatar,
            trackers: TrackerKind.values,
            timeZone: teddy.timeZone,
          );
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              Scaffold(
                body: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(padding: const EdgeInsets.only(top: 40)),
                    child: const TodayScreen(),
                  ),
                ),
              ),
              viewport: const Size(430, 932),
              palette: palette,
              locale: Locale(lang),
              textScaler: TextScaler.linear(state == 'large' ? 2 : 1),
              overrides: [
                ...familyOverrides(
                  baby: baby,
                  now: DateTime.utc(
                    2026,
                    10,
                    8,
                    state == 'evening' ? 14 : 8,
                    39,
                  ),
                  records: mockDay(),
                  growth: mockGrowth(),
                ),
                ...adaptiveOverrides(
                  band: AgeBand.b0_1,
                  repo: FakeExperienceRepository(
                    Experience.defaults(AgeBand.b0_1).copyWith(
                      shown: [WidgetId.tiles, WidgetId.careDuty],
                      hidden: WidgetId.values
                          .where(
                            (w) =>
                                w != WidgetId.tiles && w != WidgetId.careDuty,
                          )
                          .toList(),
                    ),
                  ),
                ),
                careDutyProvider(teddyId).overrideWith(
                  (ref) => Stream.value(CareDuty(uid: mai.uid, since: careNow)),
                ),
                headerPhotoProvider.overrideWith(
                  (ref, settings) => MemoryImage(bytes),
                ),
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
                'goldens/hv/${state}_${palette.name}_$lang.png',
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
