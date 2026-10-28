@Tags(['golden'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/paywall_price_cache.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/premium_v2_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final scenario in ['cached', 'loading', 'retry', 'retry_large']) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        testWidgets('$scenario ${palette.name} $lang', (tester) async {
          final pending = Completer<FamilyPlanV2?>();
          final (_, container) = await pumpRouted(
            tester,
            const PaywallScreen(entry: PaywallEntry.plan),
            palette: palette,
            locale: Locale(lang),
            textScaler: TextScaler.linear(scenario == 'retry_large' ? 2 : 1),
            prefs: {
              if (scenario == 'cached')
                PaywallPriceCache.key(mai.uid, teddyId, true): jsonEncode({
                  'at': DateTime.now().millisecondsSinceEpoch,
                  'month': 59000,
                  'year': 599000,
                }),
            },
            overrides: premiumV2Overrides(
              plan: null,
              loadPlan: () => scenario.startsWith('retry')
                  ? Future.value(null)
                  : pending.future,
            ),
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/premium_price/${scenario}_${palette.name}_$lang.png',
            ),
          );
          await tester.pumpWidget(const SizedBox());
          container.dispose();
        });
      }
    }
  }
}
