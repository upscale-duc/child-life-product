import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_feedback.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
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
  });

  group('buttons', () {
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
