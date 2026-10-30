@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/rhythm/coming_up.dart';
import 'package:child_life/features/rhythm/coming_up_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';

/// 2026-10-25 [h]:[m] in Hà Nội.
DateTime vn(int h, [int m = 0]) =>
    DateTime.utc(2026, 10, 25, h, m).subtract(const Duration(hours: 7));

/// Sprint wow W1 "Sắp tới": awake (next feed + next nap) and asleep (the waking only).
final _cases = {
  'awake': ComingUp(
    feed: ComingUpRow(
      kind: ComingUpKind.feed,
      from: vn(14, 10),
      to: vn(14, 40),
      since: vn(11, 40),
    ),
    sleep: ComingUpRow(
      kind: ComingUpKind.sleep,
      from: vn(14, 50),
      to: vn(15, 20),
      since: vn(12, 20),
    ),
  ),
  'asleep': ComingUp(
    sleep: ComingUpRow(
      kind: ComingUpKind.wake,
      from: vn(15),
      to: vn(15),
      since: vn(13, 30),
    ),
  ),
};

void main() {
  setUpAll(ensureTimeZones);
  for (final MapEntry(key: name, value: up) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        for (final scale in [1.0, 2.0]) {
          if (scale == 2.0 && (name != 'awake' || palette != ClPalette.light)) {
            continue;
          }
          testWidgets('coming up $name ${palette.name} $lang $scale', (
            tester,
          ) async {
            await pumpRouted(
              tester,
              Scaffold(
                // In a scroll view, as on Hôm nay.
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ComingUpView(up: up, zone: 'Asia/Ho_Chi_Minh'),
                ),
              ),
              locale: Locale(lang),
              palette: palette,
              textScaler: TextScaler.linear(scale),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/coming_up/${name}_${palette.name}_${lang}_$scale.png',
              ),
            );
          });
        }
      }
    }
  }
}
