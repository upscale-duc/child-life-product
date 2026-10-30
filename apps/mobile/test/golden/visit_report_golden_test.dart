@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/visit_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';
import '../helpers/visit_fixtures.dart';

/// U1 "Chuẩn bị đi khám" (sprint Premium): Light / Night care × vi / en.
void main() {
  for (final palette in ClPalette.values) {
    for (final lang in ['vi', 'en']) {
      testWidgets('visit report ${palette.name} $lang', (tester) async {
        await pumpRouted(
          tester,
          const VisitReportScreen(),
          overrides: visitOverrides(),
          locale: Locale(lang),
          palette: palette,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/visit/report_${palette.name}_$lang.png'),
        );
      });
    }
  }
}
