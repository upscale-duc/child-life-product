import 'package:child_life/core/widgets/cl_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

/// Buttons that call the server show they are working: a spinner, the label kept, no second tap,
/// and not dimmed like an unavailable button.
void main() {
  testWidgets('loading shows a spinner, keeps the label and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    // The spinner never settles, so pump frames instead of pumpCl's pumpAndSettle.
    await tester.pumpWidget(
      clHarness(ClButton(label: 'Lưu', onPressed: () => taps++, loading: true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    await tester.tap(find.text('Lưu'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 0);
    final dimmed = tester
        .widgetList<AnimatedOpacity>(
          find.ancestor(
            of: find.text('Lưu'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .any((o) => o.opacity < 1);
    expect(dimmed, isFalse);
  });

  testWidgets('idle buttons have no spinner and take taps', (tester) async {
    var taps = 0;
    await pumpCl(tester, ClButton(label: 'Lưu', onPressed: () => taps++));
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    await tester.tap(find.text('Lưu'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });
}
