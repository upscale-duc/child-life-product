import 'package:child_life/features/care/visit_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';
import '../helpers/visit_fixtures.dart';

void main() {
  test('the two weeks are complete days before today', () {
    final w = visitWeeks('2026-10-08');
    expect((w.recent.start, w.recent.end), ('2026-10-01', '2026-10-07'));
    expect((w.before.start, w.before.end), ('2026-09-24', '2026-09-30'));
    expect(perDay('vi', 36), '5,1');
    expect(perDay('en', 36), '5.1');
  });

  testWidgets('U1: per-day feeds against the week before, growth, questions', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const VisitReportScreen(),
      overrides: visitOverrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chuẩn bị đi khám'), findsWidgets);
    expect(find.text('5 cữ · 600 ml'), findsOneWidget);
    expect(find.text('Tuần trước: 3 cữ · 300 ml'), findsOneWidget);
    expect(find.text('Ướt 2 · Bẩn 0'), findsOneWidget);
    expect(find.text('6,2 kg'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(EditableText),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byType(EditableText).last,
      'Bé ọc sữa có sao không?',
    );
    await tester.pump();
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Bé ọc sữa có sao không?'), findsOneWidget);
  });

  testWidgets('without rhythm.advanced: nothing is shown', (tester) async {
    await pumpRouted(
      tester,
      const VisitReportScreen(),
      overrides: visitOverrides(premium: false),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('visitShare')), findsNothing);
  });
}
