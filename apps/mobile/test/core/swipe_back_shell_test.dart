import 'package:child_life/core/design/page_transitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell (tab bar) sits under every root-level screen. Releasing an iOS edge swipe must
/// slide it back in smoothly: its x never jumps between two frames.
void main() {
  Future<List<double>> swipeBack(WidgetTester tester, Route<void> shell) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: ClPageTransitionsBuilder(
                CupertinoPageTransitionsBuilder(),
              ),
            },
          ),
        ),
        onGenerateRoute: (_) => shell,
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ColoredBox(color: Color(0xFF00FF00)),
      ),
    );
    await tester.pumpAndSettle();
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    double shellX() =>
        tester.getTopLeft(find.byKey(const ValueKey('shell'))).dx;

    final gesture = await tester.startGesture(const Offset(5, 300));
    // Slow drag far to the right, then hold still and release (no fling).
    for (var x = 5.0; x < width * 0.85; x += 20) {
      await gesture.moveTo(Offset(x, 300));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 200));
    final xs = [shellX()];
    await gesture.up();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      xs.add(shellX());
    }
    await tester.pumpAndSettle();
    return xs;
  }

  double maxStep(List<double> xs) => [
    for (var i = 1; i < xs.length; i++) (xs[i] - xs[i - 1]).abs(),
  ].reduce((a, b) => a > b ? a : b);

  testWidgets('a fade page under a Cupertino page slides back without a jump', (
    tester,
  ) async {
    final xs = await swipeBack(
      tester,
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            const ColoredBox(key: ValueKey('shell'), color: Color(0xFFFF0000)),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    // ignore: avoid_print
    print(
      'shell x after release: ${xs.map((x) => x.toStringAsFixed(1)).join(' ')}',
    );
    expect(xs.first, lessThan(0), reason: 'parallax: shell starts left');
    expect(xs.last, closeTo(0, 1));
    expect(
      maxStep(xs),
      lessThan(20),
      reason: 'no jump between two 8 ms frames',
    );
  });
}
