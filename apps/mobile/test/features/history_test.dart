import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/widgets/cl_choices.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_screens.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

Finder _chip(String label) => find.widgetWithText(ClFilterChip, label);

void main() {
  setUpAll(ensureTimeZones);

  group('entry points', () {
    testWidgets('Today "Lịch sử" opens History', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      await tester.scrollUntilVisible(
        find.text('Lịch sử'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(visits.single.location, Routes.history);
    });

    testWidgets('growth "Xem tất cả" opens History on the growth filter', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const GrowthScreen(),
        overrides: careOverrides(growth: mockGrowth()),
      );
      await tester.ensureVisible(find.text('Xem tất cả'));
      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      expect(visits.single.location, '${Routes.history}?filter=growth');
    });
  });

  group('History (20 – 20f)', () {
    testWidgets('today: summary, period sections and the overnight sleep', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(),
        overrides: careOverrides(),
      );
      expect(find.text('Đã ghi hôm nay'), findsOneWidget);
      expect(find.text('Chiều'), findsOneWidget);
      expect(findTabular('14:20'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Đêm'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      // The night sleep that began yesterday keeps its real start (D-027).
      expect(find.textContaining('hôm qua'), findsWidgets);
    });

    testWidgets('filters narrow the day and link to the stats', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const HistoryScreen(),
        overrides: careOverrides(),
      );
      await tester.tap(_chip('Ngủ'));
      await tester.pumpAndSettle();
      expect(find.text('Ngủ hôm nay'), findsOneWidget);
      expect(findTabular('14:20'), findsNothing, reason: 'bottle filtered out');
      await tester.tap(find.text('Xem thống kê ngủ'));
      await tester.pumpAndSettle();
      expect(visits.single.location, Routes.sleepStats);
    });

    testWidgets('the day strip switches day', (tester) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.feed),
        overrides: careOverrides(),
      );
      // 21:00 bottles exist on every day but today (8 Oct).
      expect(findTabular('21:00'), findsNothing);
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      expect(findTabular('21:00'), findsOneWidget);
    });

    testWidgets(
      'an empty past day back-logs at the same time of day on that date',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          const HistoryScreen(filter: HistoryFilter.diaper),
          overrides: careOverrides(range: const [], repo: repo),
        );
        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa ghi thay tã ngày 7 thg 10'), findsOneWidget);
        await tester.tap(find.text('Ghi bù thay tã'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        final saved = repo.created.single;
        expect(saved.type, CareType.diaper);
        expect(saved.occurredAt, vn(7, 15, 5));
      },
    );

    testWidgets(
      'a caregiver is told only their own records are editable (12d)',
      (tester) async {
        await pumpRouted(
          tester,
          const HistoryScreen(),
          overrides: careOverrides(me: lan),
        );
        expect(
          find.text(
            'Bạn sửa được bản ghi của mình. Bản ghi của ba mẹ chỉ xem.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('a relative sees the day read-only, with no back-log', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.diaper),
        overrides: careOverrides(me: hoa, range: const []),
      );
      expect(find.textContaining('Ghi thay tã'), findsNothing);
      expect(find.textContaining('Ghi bù'), findsNothing);
    });

    testWidgets('the date picker marks logged days and jumps to one', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.feed),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Tháng 10'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày'), findsOneWidget);
      // Before the birth date (17 Sep) and after today nothing is selectable.
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày'), findsNothing);
      expect(findTabular('21:00'), findsOneWidget);
    });
  });

  group('Statistics (20g, 20g2, 20h)', () {
    testWidgets('feed: 7 ngày by default, KPIs, and the window is remembered', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const FeedStatsScreen(),
        overrides: careOverrides(),
      );
      expect(find.text('523 ml'), findsOneWidget);
      // v1.0 improvement: the range is a pill opening "Khoảng thời gian".
      await tester.tap(find.text('7 ngày'));
      await tester.pumpAndSettle();
      expect(find.text('Khoảng thời gian'), findsOneWidget);
      expect(find.text('Tuỳ chọn'), findsOneWidget);
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();
      expect(find.text('540 ml'), findsOneWidget);
      expect(find.text('Từ 18h hôm qua'), findsOneWidget);
      expect(find.text('Từng cữ hôm nay'), findsOneWidget);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('stats.feed.window'),
        'today',
      );
    });

    testWidgets('feed: "Loại bú" switches the cards (v1.0 improvement)', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const FeedStatsScreen(),
        overrides: careOverrides(),
      );
      expect(find.text('Bú mỗi ngày'), findsOneWidget);
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      expect(find.text('Loại bú'), findsOneWidget);
      await tester.tap(find.text('Theo lượng sữa (ml)'));
      await tester.pumpAndSettle();
      expect(find.text('Lượng sữa mỗi ngày'), findsOneWidget);
      expect(find.text('TB mỗi cữ'), findsOneWidget);
      expect(
        container.read(sharedPreferencesProvider).getString('stats.feed.kind'),
        'bottle',
      );
      // The kind pill (the day timeline below also says "Bú bình" on its rows).
      await tester.tap(find.text('Bú bình').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theo thời gian bú (phút)'));
      await tester.pumpAndSettle();
      expect(find.text('Thời gian bú mẹ mỗi ngày'), findsOneWidget);
      expect(
        find.text(
          'Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sleep: night trend insight over 7 days', (tester) async {
      await pumpRouted(
        tester,
        const SleepStatsScreen(),
        overrides: careOverrides(),
      );
      final insight = find.text(
        'Giấc đêm dài nhất tăng từ 3 giờ 30 phút lên 6 giờ 30 phút trong 7 ngày.',
      );
      await tester.scrollUntilVisible(insight, 300);
      expect(insight, findsOneWidget);
      // Below "Tổng giờ ngủ mỗi ngày" and "Ngủ ngày và đêm" (v1.0 improvement).
      await tester.scrollUntilVisible(find.text('Nhịp ngủ 7 ngày'), 300);
      expect(find.text('Nhịp ngủ 7 ngày'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('30 ngày'), -300);
      await tester.tap(find.text('30 ngày'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Nhịp ngủ 30 ngày'), 300);
      expect(find.text('Nhịp ngủ 30 ngày'), findsOneWidget);
    });
  });
}
