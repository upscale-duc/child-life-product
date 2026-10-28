@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final palette in ClPalette.values) {
    for (final lang in ['vi', 'en']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('direct offline ${palette.name} $lang $scale', (
          tester,
        ) async {
          await pumpRouted(
            tester,
            Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: scale == 1 ? 193 : 343,
                  height: scale == 1 ? 220 : 330,
                  child: CareTile(
                    type: CareType.bottle,
                    quickActions: true,
                    last: null,
                    myUid: mai.uid,
                    now: careNow,
                    onTap: () {},
                  ),
                ),
              ),
            ),
            locale: Locale(lang),
            palette: palette,
            textScaler: TextScaler.linear(scale),
            overrides: careOverrides(records: [], online: false),
          );
          await tester.tap(find.byKey(const Key('care-bottle-60 ml')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/direct_care/offline_${palette.name}_${lang}_$scale.png',
            ),
          );
        });
      }
    }
  }
}
