import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/reminders/reminder_screens.dart'
    show ReminderPeek;
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// v1.0 improvement · NavBar v1.0.1: the Chăm sóc tab (370:1971 / 370:2174), "Tôi" from the
/// header avatar (370:1898) and "Tuỳ chỉnh Hôm nay" (370:1525).
/// The real tab shell over stub tab screens, each with a 'sub' screen.
GoRouter _shellRouter(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.family,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: root,
                builder: (_, _) => Scaffold(body: Text('tab $root')),
                routes: [
                  GoRoute(
                    path: 'sub',
                    builder: (_, _) => const Scaffold(body: Text('sub')),
                  ),
                ],
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  group('Chăm sóc', () {
    testWidgets('parent: daily care and teasers, no settings', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      expect(find.text('Chăm sóc'), findsWidgets);
      // No "Cài đặt" section; no collapsed title over the baby header when scrolled.
      expect(find.text('Cài đặt'), findsNothing);
      expect(find.text('Tuỳ chỉnh theo dõi'), findsNothing);
      expect(
        tester
            .widget<ClPinnedHeaderScaffold>(find.byType(ClPinnedHeaderScaffold))
            .collapsedTitle,
        isNull,
      );
      for (final t in ['Nhắc nhở', 'Thống kê', 'Lịch sử', 'Tăng trưởng']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.history);
    });

    testWidgets('Tăng trưởng opens History on growth', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Tăng trưởng'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.history}?filter=growth');
    });

    testWidgets('Thống kê asks which statistics', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(find.text('Xem thống kê'), findsOneWidget);
      await tester.tap(find.text('Thống kê bú'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.feedStats);
    });

    testWidgets('coming-soon tiles only say so', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.ensureVisible(find.text('Wonder Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wonder Week'));
      await tester.pump();
      expect(
        find.text('Phần này sẽ có trong bản cập nhật tới.'),
        findsOneWidget,
      );
      expect(visits, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('caregiver: no Tăng trưởng (370:2174)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(me: lan),
      );
      expect(find.text('Nhắc nhở'), findsOneWidget);
      expect(find.text('Tăng trưởng'), findsNothing);
    });

    testWidgets('search filters tiles and rows', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.enterText(find.byType(TextField), 'lịch');
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử'), findsOneWidget);
      expect(find.text('Nhắc nhở'), findsNothing);
      expect(find.text('Wonder Week'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Không có mục nào khớp.'), findsOneWidget);
    });
  });

  testWidgets('a screen opened from a tab hides the dock; back shows it', (
    tester,
  ) async {
    final router = _shellRouter(Routes.care);
    await pumpRouted(
      tester,
      const SizedBox(),
      overrides: [...careOverrides(), ...memoryOverrides()],
      router: router,
    );
    bool dockHidden() => tester
        .widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byType(ClTabDock),
                matching: find.byType(IgnorePointer),
              )
              .first,
        )
        .ignoring;
    expect(find.text('tab ${Routes.care}'), findsOneWidget);
    expect(dockHidden(), isFalse);
    router.go('${Routes.care}/sub');
    await tester.pumpAndSettle();
    expect(find.text('sub'), findsOneWidget);
    expect(dockHidden(), isTrue);
    router.go(Routes.care);
    await tester.pumpAndSettle();
    expect(dockHidden(), isFalse);
  });

  testWidgets(
    '"+" above the dock: Ghi nhanh on Hôm nay, add photos on Kỷ niệm',
    (tester) async {
      final router = _shellRouter(Routes.today);
      await pumpRouted(
        tester,
        const SizedBox(),
        overrides: [...careOverrides(), ...memoryOverrides()],
        router: router,
      );
      expect(find.bySemanticsLabel('Ghi nhanh'), findsOneWidget);
      router.go(Routes.memories);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ghi nhanh'), findsNothing);
      expect(find.bySemanticsLabel('Thêm vào Kỷ niệm'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Thêm vào Kỷ niệm'));
      await tester.pumpAndSettle();
      // The same sheet as the "+" in the Kỷ niệm header.
      expect(find.text('Thêm vào Kỷ niệm'), findsWidgets);
      Navigator.of(tester.element(find.byType(ClTabDock))).maybePop();
      await tester.pumpAndSettle();
      router.go(Routes.care);
      await tester.pumpAndSettle();
      expect(find.byType(ClQuickLogButton), findsNothing);
    },
  );

  group('Tôi from the avatar', () {
    testWidgets('the header avatar opens Tôi', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.me);
    });
  });

  group('Tuỳ chỉnh Hôm nay', () {
    test('a saved layout survives unknown names and gains new sections', () {
      final layout = TodayLayout.fromJson({
        'order': ['rhythm', 'gone', 'tiles'],
        'hidden': ['reminders'],
        'hiddenTiles': ['pump', 'nope'],
      });
      expect(layout.order, [
        TodaySection.rhythm,
        TodaySection.tiles,
        TodaySection.reminders,
      ]);
      expect(layout.shows(TodaySection.reminders), isFalse);
      expect(layout.hiddenTiles, {TrackerKind.pump});
      expect(TodayLayout.fromJson(layout.toJson()).toJson(), layout.toJson());
    });

    testWidgets('hide a section and a tile; Xong keeps it, Đặt lại undoes', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      expect(find.byType(CareTile), findsNWidgets(4));
      expect(find.byType(ReminderPeek), findsOneWidget);

      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      expect(find.text('Tuỳ chỉnh Hôm nay'), findsOneWidget);
      expect(find.text('Ô theo dõi nhanh'), findsOneWidget);
      expect(find.text('Nhịp trong ngày'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Nhắc việc sắp tới'),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(ClToggle),
        ),
      );
      // The sheet's chip (the day's legend below also says Bú bình).
      final bottleChip = find
          .descendant(of: find.byType(Wrap), matching: find.text('Bú bình'))
          .last;
      await tester.ensureVisible(bottleChip);
      await tester.tap(bottleChip);
      // Nothing changes until Xong.
      await tester.pump();
      expect(find.byType(ReminderPeek), findsOneWidget);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPeek), findsNothing);
      expect(find.byType(CareTile), findsNWidgets(3));
      expect(container.read(todayLayoutProvider(teddyId)).hiddenTiles, {
        TrackerKind.bottle,
      });

      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại'));
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPeek), findsOneWidget);
      expect(find.byType(CareTile), findsNWidgets(4));
    });

    testWidgets('the saved order is per baby and read back', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
        prefs: {
          'today.layout.$teddyId':
              '{"order":["rhythm","reminders","tiles"],"hidden":[],"hiddenTiles":[]}',
        },
      );
      final rhythm = tester.getTopLeft(find.byType(DayRhythm)).dy;
      final peek = tester.getTopLeft(find.byType(ReminderPeek)).dy;
      expect(rhythm, lessThan(peek));
    });

    testWidgets('relatives see no Tuỳ chỉnh (read-only Today)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(me: hoa),
      );
      expect(find.text('Tuỳ chỉnh'), findsNothing);
    });
  });
}
