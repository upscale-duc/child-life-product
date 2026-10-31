@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/insights/insight_models.dart';
import 'package:child_life/features/insights/insight_screens.dart';
import 'package:child_life/features/insights/insight_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/insight_fixtures.dart';
import '../helpers/router_pump.dart';

/// Hiểu con P2 (Figma 1104:1883 AI01–AI04; D-150, D-151), synthetic data on 8 Oct 2026.
void main() {
  setUpAll(ensureTimeZones);

  const card = Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: InsightTodayCard(),
    ),
  );
  final cases = <String, (Widget, List<Object>, Size)>{
    // AI01: today's insight on Hôm nay; the Free invite (kind only).
    'today': (card, [insightDoc()], const Size(375, 420)),
    'invite': (
      card,
      [insightDoc(premium: false, teaser: 'night_longest'), false],
      const Size(375, 300),
    ),
    // AI02: Hiểu con with two insights; AI04: not enough nights.
    'screen': (const InsightsScreen(), [insightDoc()], const Size(375, 1300)),
    'sparse': (
      const InsightsScreen(),
      [insightDoc(items: const [], validNights: 2, today: null)],
      const Size(375, 900),
    ),
    // AI03: one insight and its basis.
    'detail': (
      const InsightDetailScreen(kind: InsightKind.nightLongest),
      [insightDoc()],
      const Size(375, 1150),
    ),
    // AI03 with Lumi on for the family (D-151 #7: the 0-credit question).
    'detail_lumi': (
      const InsightDetailScreen(kind: InsightKind.nightLongest),
      [insightDoc(), true, 'lumi'],
      const Size(375, 1300),
    ),
  };

  for (final MapEntry(key: name, value: (screen, args, size))
      in cases.entries) {
    final doc = args.first as Map<String, dynamic>;
    final premium = args.length < 2 || args[1] != false;
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        for (final scale in [1.0, 2.0]) {
          // 200 % text once per screen shape (light, vi).
          if (scale == 2.0 &&
              (palette != ClPalette.light ||
                  lang != 'vi' ||
                  name == 'invite' ||
                  name == 'detail_lumi')) {
            continue;
          }
          final suffix = scale == 2.0 ? '_x2' : '';
          testWidgets('insights $name ${palette.name} $lang $scale', (
            tester,
          ) async {
            await pumpRouted(
              tester,
              screen,
              locale: Locale(lang),
              palette: palette,
              viewport: scale == 2.0
                  ? Size(size.width, size.height * 1.8)
                  : size,
              textScaler: TextScaler.linear(scale),
              overrides: [
                // The mock week (2–8 Oct) for "Theo từng việc".
                ...careOverrides(records: mockWeek()),
                ...insightOverrides(premium: premium, doc: doc),
                if (args.contains('lumi'))
                  assistantAccessProvider.overrideWith(
                    (ref, babyId) => const AssistantAccess(),
                  ),
              ],
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/insights/${name}_${palette.name}_$lang$suffix.png',
              ),
            );
          });
        }
      }
    }
  }
}
