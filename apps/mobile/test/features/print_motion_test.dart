import 'package:child_life/features/print_studio/print_motion.dart';
import 'package:child_life/features/print_studio/print_screen.dart';
import 'package:child_life/features/print_studio/print_ui.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/print_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  setUp(() => mediaBytes = PrintFixtureBytes());
  testWidgets(
    'forward and back have intermediate frames, not an instant content swap',
    (t) async {
      await pumpRouted(
        t,
        const MediaQuery(
          data: MediaQueryData(size: Size(375, 812), disableAnimations: false),
          child: PrintStudioScreen(),
        ),
        overrides: printOverrides(),
      );
      final root = find.byType(PrintFlowTransition).first;
      await t.tap(find.text('Tiếp tục').last);
      await t.pump();
      final switcher = t.widget<AnimatedSwitcher>(
        find
            .descendant(of: root, matching: find.byType(AnimatedSwitcher))
            .first,
      );
      expect(switcher.duration, PrintMotion.screen);
      await t.pump(const Duration(milliseconds: 150));
      final fades = t
          .widgetList<FadeTransition>(
            find.descendant(of: root, matching: find.byType(FadeTransition)),
          )
          .where((f) => f.opacity.value > 0 && f.opacity.value < 1)
          .toList();
      expect(fades, isNotEmpty);
      expect(find.text('Phong cách'), findsOneWidget);
      expect(find.text('Chọn kích thước & khung'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('Phong cách'), findsNothing);
      await t.tap(
        find
            .descendant(
              of: find.byType(PrintHeader),
              matching: find.byType(ClPressable),
            )
            .first,
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      expect(
        t
            .widgetList<FadeTransition>(
              find.descendant(of: root, matching: find.byType(FadeTransition)),
            )
            .any((f) => f.opacity.value > 0 && f.opacity.value < 1),
        true,
      );
      await t.pumpAndSettle();
      expect(find.text('Phong cách'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Reduce Motion shortens the fade and adds no spatial movement', (
    t,
  ) async {
    await pumpRouted(t, const PrintStudioScreen(), overrides: printOverrides());
    await t.tap(find.text('Tiếp tục').last);
    await t.pump();
    final root = find.byType(PrintFlowTransition).first;
    expect(
      t
          .widget<AnimatedSwitcher>(
            find
                .descendant(of: root, matching: find.byType(AnimatedSwitcher))
                .first,
          )
          .duration,
      PrintMotion.reduced,
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'updating content without changing screen identity does not restart its transition',
    (t) async {
      var label = 'A';
      late StateSetter change;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (c, set) {
                change = set;
                return PrintFlowTransition(
                  identity: 'same-screen',
                  child: Text(label),
                );
              },
            ),
          ),
        ),
      );
      change(() => label = 'B');
      await t.pump();
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(t.hasRunningAnimations, false);
    },
  );
}
