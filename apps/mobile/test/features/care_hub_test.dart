import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/reminders/reminder_screens.dart'
    show ReminderPeek;
import 'package:child_life/features/today/today_cards.dart';
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
      await tester.ensureVisible(find.text('Wonder Weeks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wonder Weeks'));
      await tester.pump();
      expect(
        find.text('Phần này sẽ có trong bản cập nhật tới.'),
        findsOneWidget,
      );
      expect(visits, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    // D-076 nav: Mốc phát triển is live, with or without a published guide (own milestones).
    testWidgets('"Mốc phát triển" opens 3a, never "Sớm ra mắt"', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      final tile = find.byKey(const Key('careMilestones'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text('Phần này sẽ có trong bản cập nhật tới.'), findsNothing);
      expect(visits.last.location, Routes.milestones);
    });

    testWidgets('grouped as the owner asked (D-069)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      for (final t in [
        'Chăm hằng ngày',
        'Hiểu con & phát triển',
        'Kiến thức chăm bé',
      ]) {
        await tester.scrollUntilVisible(
          find.text(t),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.scrollUntilVisible(
        find.text('Thư viện chăm bé'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(y('Mốc phát triển'), lessThan(y('Kiến thức chăm bé')));
      expect(y('Kiến thức chăm bé'), lessThan(y('Thư viện chăm bé')));
      // D-076 #5: "Thẻ theo tuổi" is "Giai đoạn của bé" in the app.
      expect(find.text('Giai đoạn của bé'), findsOneWidget);
      // D-083: Dinh dưỡng in "Chăm hằng ngày" (a teaser until a stage is published); D-085:
      // "Ăn dặm" is a live tile right after it (P-164 #1; Teddy is 3 weeks: "Từ 6 tháng").
      await tester.scrollUntilVisible(
        find.text('Ăn dặm'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(y('Dinh dưỡng'), lessThan(y('Hiểu con & phát triển')));
      expect(y('Dinh dưỡng'), lessThan(y('Ăn dặm')));
      expect(y('Ăn dặm'), lessThan(y('Hiểu con & phát triển')));
      expect(find.text('Từ 6 tháng'), findsOneWidget);
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
      // Missing parts go in their default place; the opt-in ones stay hidden.
      expect(layout.order, [
        TodaySection.rhythm,
        TodaySection.tiles,
        // D-076 #8: right after the tiles.
        TodaySection.forYou,
        // D-085: 5h "Ăn dặm hôm nay", shown while solids tracking is on.
        TodaySection.solids,
        TodaySection.reminders,
        TodaySection.quickActions,
        TodaySection.vaccine,
        TodaySection.spending,
      ]);
      expect(layout.shows(TodaySection.reminders), isFalse);
      expect(layout.shows(TodaySection.quickActions), isFalse);
      expect(layout.hiddenTiles, {TrackerKind.pump});
      expect(layout.actionOrder, QuickAction.values);
      expect(TodayLayout.fromJson(layout.toJson()).toJson(), layout.toJson());
    });

    test('the default is the design: tiles, reminders, rhythm', () {
      const d = TodayLayout();
      expect(
        [
          for (final s in d.order)
            if (d.shows(s)) s,
        ],
        // "Dành cho bé hôm nay" draws only with the family's rhythm flag; "Ăn dặm hôm nay" only
        // while solids tracking is on (D-085).
        [
          TodaySection.tiles,
          // D-076 #8: "Dành cho bé hôm nay" right after the tiles.
          TodaySection.forYou,
          TodaySection.solids,
          TodaySection.reminders,
          TodaySection.rhythm,
        ],
      );
      expect(
        const TodayLayout(
          tileOrder: [TrackerKind.diaper, TrackerKind.pump],
        ).tiles([TrackerKind.bottle, TrackerKind.sleep, TrackerKind.diaper]),
        [TrackerKind.diaper, TrackerKind.bottle, TrackerKind.sleep],
      );
      // Moving what the viewer sees keeps the rest in place.
      expect(reorderVisible([1, 2, 3, 4], [1, 3, 4], 2, 0), [4, 2, 1, 3]);
    });

    test('shortcuts and parts follow the viewer\'s rights', () {
      expect(allowedActions(mai), QuickAction.values);
      expect(allowedActions(lan), [QuickAction.reminder, QuickAction.vaccine]);
      expect(allowedActions(hoa), isEmpty);
      expect(
        allowedSections(lan, hasTiles: true),
        isNot(contains(TodaySection.spending)),
      );
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
      // The tile's chip, right under "Ô theo dõi nhanh".
      final bottleChip = find.byKey(const Key('tileChip-bottle'));
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
      await tester.tap(find.text('Về mặc định'));
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPeek), findsOneWidget);
      expect(find.byType(CareTile), findsNWidgets(4));
    });

    testWidgets('opt-in parts: Tạo nhanh, Mũi tiêm sắp tới, Chi tiêu', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      expect(find.byType(TodayQuickActions), findsNothing);
      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      for (final part in [
        'Tạo nhanh',
        'Mũi tiêm sắp tới',
        'Chi tiêu tháng này',
      ]) {
        final toggle = find.descendant(
          of: find
              .ancestor(
                of: find.descendant(
                  of: find.byKey(const Key('customizeSections')),
                  matching: find.text(part),
                ),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(ClToggle),
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();
      }
      // One shortcut off, ticked right under "Tạo nhanh".
      final memory = find.byKey(const Key('actionChip-memory'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(memory);
      await tester.pumpAndSettle();
      await tester.tap(memory);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      final layout = container.read(todayLayoutProvider(teddyId));
      expect(layout.shows(TodaySection.quickActions), isTrue);
      expect(layout.hiddenActions, {QuickAction.memory});
      await tester.scrollUntilVisible(
        find.byType(TodayQuickActions),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('quick-reminder')), findsOneWidget);
      expect(find.byKey(const Key('quick-expense')), findsOneWidget);
      expect(find.byKey(const Key('quick-memory')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('todaySpending')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('todayVaccine')), findsOneWidget);
    });

    testWidgets('drag by the handle, or press and hold a row', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      Finder inGroup(String key, String text) =>
          find.descendant(of: find.byKey(Key(key)), matching: find.text(text));
      // Handle: "Nhịp trong ngày" (last) to the top.
      final rhythm = inGroup('customizeSections', 'Nhịp trong ngày');
      final handle = find.descendant(
        of: find.ancestor(of: rhythm, matching: find.byType(Row)).first,
        matching: find.byType(ReorderableDragStartListener),
      );
      final top = tester.getCenter(
        inGroup('customizeSections', 'Ô theo dõi nhanh'),
      );
      final start = tester.getCenter(handle);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      // A real finger moves in steps; the list makes room as it goes.
      for (var y = start.dy - 20; y > top.dy - 40; y -= 20) {
        await gesture.moveTo(Offset(start.dx, y));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();
      // Long press anywhere on a row: "Nhắc việc sắp tới" back to the top.
      final reminders = inGroup('customizeSections', 'Nhắc việc sắp tới');
      final first = tester.getCenter(
        inGroup('customizeSections', 'Nhịp trong ngày'),
      );
      final from = tester.getCenter(reminders);
      final hold = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 600));
      for (var y = from.dy - 20; y > first.dy - 40; y -= 20) {
        await hold.moveTo(Offset(from.dx, y));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await hold.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      final layout = container.read(todayLayoutProvider(teddyId));
      // "Dành cho bé hôm nay" (not offered without the rhythm flag) and "Ăn dặm hôm nay" (not
      // offered while solids tracking is off) keep their places.
      expect(
        layout.order
            .where((s) => s != TodaySection.forYou && s != TodaySection.solids)
            .take(2),
        [TodaySection.reminders, TodaySection.rhythm],
      );
    });

    testWidgets('tiles follow the order chosen here', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
        prefs: {
          'today.layout.$teddyId':
              '{"order":["tiles","reminders","rhythm"],"hidden":[],'
              '"tileOrder":["diaper","sleep"],"hiddenTiles":[]}',
        },
      );
      final tiles = tester.widgetList<CareTile>(find.byType(CareTile)).toList();
      expect(tiles.first.type, CareType.diaper);
      expect(tiles[1].type, CareType.sleep);
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
