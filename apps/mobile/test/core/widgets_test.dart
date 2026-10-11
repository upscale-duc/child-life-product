import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_feedback.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/widgets/cl_segmented.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  group('roles', () {
    test('tabs per role follow NavBar 44:362', () {
      expect(tabsForRole(ClRole.parent), [
        ClTab.today,
        ClTab.memories,
        ClTab.family,
        ClTab.me,
      ]);
      expect(tabsForRole(ClRole.caregiver), [
        ClTab.today,
        ClTab.family,
        ClTab.me,
      ]);
      expect(tabsForRole(ClRole.relative), [
        ClTab.memories,
        ClTab.family,
        ClTab.me,
      ]);
    });

    testWidgets('relatives get no quick-log button', (tester) async {
      await pumpCl(
        tester,
        ClTabDock(
          role: ClRole.relative,
          active: ClTab.memories,
          onSelect: (_) {},
          initial: 'H',
          onQuickLog: () {},
        ),
      );
      expect(find.bySemanticsLabel('Ghi nhanh'), findsNothing);
      await pumpCl(
        tester,
        ClTabDock(
          role: ClRole.caregiver,
          active: ClTab.today,
          onSelect: (_) {},
          initial: 'L',
          onQuickLog: () {},
        ),
      );
      expect(find.bySemanticsLabel('Ghi nhanh'), findsOneWidget);
    });

    testWidgets('every tab is labelled for screen readers, in both languages', (
      tester,
    ) async {
      await pumpCl(
        tester,
        ClNavBar(
          role: ClRole.parent,
          active: ClTab.today,
          onSelect: (_) {},
          initial: 'M',
        ),
      );
      for (final label in ['Hôm nay', 'Kỷ niệm', 'Gia đình', 'Tôi']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      await pumpCl(
        tester,
        ClNavBar(
          role: ClRole.parent,
          active: ClTab.today,
          onSelect: (_) {},
          initial: 'M',
        ),
        locale: const Locale('en'),
      );
      for (final label in ['Today', 'Memories', 'Family', 'Me']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
    });

    testWidgets('tapping a tab reports it', (tester) async {
      ClTab? selected;
      await pumpCl(
        tester,
        ClNavBar(
          role: ClRole.parent,
          active: ClTab.today,
          onSelect: (t) => selected = t,
          initial: 'M',
        ),
      );
      await tester.tap(find.bySemanticsLabel('Gia đình'));
      expect(selected, ClTab.family);
    });

    testWidgets('the pill, label and icon move together on a tab change '
        '(D-048)', (tester) async {
      Widget bar(ClTab active) => SizedBox(
        width: 360,
        child: ClNavBar(
          role: ClRole.parent,
          active: active,
          onSelect: (_) {},
          initial: 'M',
        ),
      );
      double width(String label) =>
          tester.getSize(find.bySemanticsLabel(label)).width;
      await pumpCl(tester, bar(ClTab.today));
      final full = width('Hôm nay');
      await tester.pumpWidget(clHarness(bar(ClTab.memories)));
      await tester.pump(const Duration(milliseconds: 80));
      expect(width('Hôm nay'), lessThan(full));
      expect(width('Kỷ niệm'), greaterThan(52));
      await tester.pumpAndSettle();
      expect(width('Kỷ niệm'), closeTo(full, 0.5));
    });

    testWidgets('first to last tab: the tabs in between stay icon-only', (
      tester,
    ) async {
      Widget bar(ClTab active) => SizedBox(
        width: 360,
        child: ClNavBar(
          role: ClRole.parent,
          active: active,
          onSelect: (_) {},
          initial: 'M',
        ),
      );
      double width(String label) =>
          tester.getSize(find.bySemanticsLabel(label)).width;
      await pumpCl(tester, bar(ClTab.today));
      await tester.pumpWidget(clHarness(bar(ClTab.me)));
      for (var ms = 0; ms < 400; ms += 40) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(width('Kỷ niệm'), closeTo(52, 0.5));
        expect(width('Gia đình'), closeTo(52, 0.5));
      }
      expect(width('Tôi'), greaterThan(150));
    });
  });

  testWidgets(
    'the baby chip is tappable with one baby too (opens the profile)',
    (tester) async {
      var taps = 0;
      await pumpCl(
        tester,
        ClBabySwitcher(
          label: 'Teddy · 3 tuần',
          avatar: const SizedBox(),
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.text('Teddy · 3 tuần'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(
        find.byWidgetPredicate(
          (w) => w is ClIcon && w.icon == ClIcons.chevronDown,
        ),
        findsNothing,
      );
    },
  );

  group('buttons', () {
    testWidgets('finger jitter before a scroll does not leave a row dimmed', (
      tester,
    ) async {
      // Real fingers move a few px before the 100 ms tap-down deadline; the recognizer reports
      // those moves but sends no cancel when the scroll then wins.
      await pumpCl(
        tester,
        ListView(
          children: [
            ClPressable(
              onPressed: () {},
              child: const SizedBox(height: 200, child: Text('row')),
            ),
            const SizedBox(height: 3000),
          ],
        ),
      );
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(ClPressable),
                  matching: find.byType(FadeTransition),
                )
                .at(1),
          )
          .opacity
          .value;
      final g = await tester.startGesture(tester.getCenter(find.text('row')));
      await g.moveBy(const Offset(0, -2));
      await tester.pump(const Duration(milliseconds: 30));
      await g.moveBy(const Offset(1, -2));
      await tester.pump(const Duration(milliseconds: 30));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(0, -10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(opacity(), 1);
    });

    testWidgets('scrolling over a tile never leaves it dimmed (D-048)', (
      tester,
    ) async {
      await pumpCl(
        tester,
        ListView(
          children: [
            ClPressable(
              onPressed: () {},
              pressedOpacity: ClPressable.surfaceOpacity,
              child: const SizedBox(height: 200, child: Text('tile')),
            ),
            const SizedBox(height: 3000),
          ],
        ),
      );
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(ClPressable),
                  matching: find.byType(FadeTransition),
                )
                .at(1),
          )
          .opacity
          .value;

      // A finger that rests ~120 ms then scrolls: the dim has not started yet.
      var g = await tester.startGesture(tester.getCenter(find.text('tile')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(opacity(), 1);
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, -12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(opacity(), 1);
      await g.up();
      await tester.pumpAndSettle();

      // Resting longer dims it, and the scroll that takes over clears it within ~100 ms.
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      g = await tester.startGesture(tester.getCenter(find.text('tile')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(), lessThan(0.9));
      for (var i = 0; i < 3; i++) {
        await g.moveBy(const Offset(0, -12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(), closeTo(1, 0.01));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a quick tap still plays the whole highlight (D-048)', (
      tester,
    ) async {
      var taps = 0;
      await pumpCl(tester, ClButton(label: 'Lưu', onPressed: () => taps++));
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(ClPressable),
                  matching: find.byType(FadeTransition),
                )
                .at(1), // under the disabled-state AnimatedOpacity
          )
          .opacity
          .value;
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(), lessThan(0.6));
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      expect(taps, 1);
    });

    testWidgets('disabled buttons do not fire and are 40 % opaque', (
      tester,
    ) async {
      await pumpCl(tester, const ClButton(label: 'Lưu', onPressed: null));
      await tester.tap(find.text('Lưu'));
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.4);
    });

    testWidgets('enabled buttons fire once per tap', (tester) async {
      var taps = 0;
      await pumpCl(tester, ClButton(label: 'Lưu', onPressed: () => taps++));
      await tester.tap(find.text('Lưu'));
      expect(taps, 1);
    });
  });

  testWidgets('segmented control changes selection', (tester) async {
    var value = 'a';
    await pumpCl(
      tester,
      StatefulBuilder(
        builder: (context, setState) => ClSegmented<String>(
          options: const ['a', 'b'],
          selected: value,
          onChanged: (v) => setState(() => value = v),
          labelOf: (v) => v == 'a' ? 'Sữa mẹ' : 'Sữa công thức',
        ),
      ),
    );
    await tester.tap(find.text('Sữa công thức'));
    await tester.pumpAndSettle();
    expect(value, 'b');
  });

  group('sheet', () {
    Widget opener() => Builder(
      builder: (context) => ClButton(
        label: 'Mở',
        onPressed: () => showClSheet<void>(
          context: context,
          builder: (_) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClSheetHeader(title: 'Ghi cữ bú'),
              SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );

    testWidgets('opens, closes with the labelled close button', (tester) async {
      await pumpCl(tester, opener());
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is ClIcon && w.icon == ClIcons.close),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsNothing);
    });

    testWidgets('drag past 30 % closes, a small drag springs back', (
      tester,
    ) async {
      await pumpCl(tester, opener());
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('Ghi cữ bú'), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsOneWidget);
      await tester.drag(find.text('Ghi cữ bú'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsNothing);
    });

    testWidgets('the scrim follows the finger and a flick closes at speed', (
      tester,
    ) async {
      await pumpCl(tester, opener());
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      final scrim = find.byWidgetPredicate(
        (w) => w is FadeTransition && w.child is ColoredBox,
      );
      double scrimOpacity() =>
          tester.widget<FadeTransition>(scrim.first).opacity.value;
      expect(scrimOpacity(), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Ghi cữ bú')),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      final dragged = scrimOpacity();
      expect(dragged, lessThan(1));
      expect(dragged, greaterThan(0.5));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scrimOpacity(), 1);

      await tester.flingFrom(
        tester.getCenter(find.text('Ghi cữ bú')),
        const Offset(0, 80),
        2000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(scrimOpacity(), lessThan(0.05));
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsNothing);
    });

    testWidgets(
      'Reduce Motion and Night care use the shorter, non-bouncing timings',
      (tester) async {
        final route = ClSheetRoute<void>(
          builder: (_) => const SizedBox(),
          dismissible: true,
          nightCare: true,
          reduceMotion: false,
          theme: buildClTheme(ClPalette.nightCare),
          barrierLabel: null,
        );
        expect(route.transitionDuration, const Duration(milliseconds: 250));
        final reduced = ClSheetRoute<void>(
          builder: (_) => const SizedBox(),
          dismissible: true,
          nightCare: false,
          reduceMotion: true,
          theme: buildClTheme(ClPalette.light),
          barrierLabel: null,
        );
        expect(reduced.transitionDuration, const Duration(milliseconds: 150));
        expect(
          reduced.reverseTransitionDuration,
          const Duration(milliseconds: 150),
        );
      },
    );
  });

  testWidgets('toast hides itself after 4 s and runs its action', (
    tester,
  ) async {
    var undone = false;
    await pumpCl(
      tester,
      Builder(
        builder: (context) => ClButton(
          label: 'Ghi',
          onPressed: () => showClToast(
            context,
            message: 'Đã ghi',
            actionLabel: 'Hoàn tác',
            onAction: () => undone = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ghi'));
    await tester.pumpAndSettle();
    expect(find.text('Đã ghi'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Đã ghi'), findsNothing);

    await tester.tap(find.text('Ghi'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Đã ghi'), findsNothing);
  });
}
