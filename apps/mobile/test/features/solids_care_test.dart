import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// Meals in Lịch sử and Thống kê (owner, D-085 #3; plan §3 #4): an "Ăn dặm" chip and meal rows
/// in the timeline, a "Bữa ăn dặm" card in Thống kê bú, while tracking is on. The care mock:
/// Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh; Na's diary from 28/09.

Finder _down() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> _see(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 250, scrollable: _down());

Finder _meal(String dish) => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('historyMeal_'),
  ),
  matching: find.text(dish),
);

void main() {
  group('Lịch sử', () {
    testWidgets('"Tất cả" shows today\'s meals among the records; "Ăn dặm" '
        'narrows to them and opens meal detail', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const HistoryScreen(),
        overrides: solidsOverrides(),
      );
      expect(find.byKey(const Key('historySolids')), findsOneWidget);
      await _see(tester, _meal('Khoai lang nghiền'));
      expect(
        find.text('Ăn dặm · ½ chén · Bình thường · Cô Lan ghi'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('historySolids')),
        -250,
        scrollable: _down(),
      );
      await tester.ensureVisible(find.byKey(const Key('historySolids')));
      await tester.tap(find.byKey(const Key('historySolids')));
      await tester.pumpAndSettle();
      expect(find.text('Ăn dặm hôm nay'), findsOneWidget);
      expect(find.text('2 bữa'), findsOneWidget);
      expect(find.text('1 món'), findsOneWidget);
      expect(_meal('Cháo bí đỏ'), findsOneWidget);
      expect(_meal('Khoai lang nghiền'), findsOneWidget);
      // Care records stay out of the "Ăn dặm" filter.
      expect(find.text('Đã ghi hôm nay'), findsNothing);
      await tester.tap(_meal('Cháo bí đỏ'));
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith('/care/solids/meal/m_'));
    });

    testWidgets('a meal with signs shows the tag; the link opens the diary', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 8, 13, 0),
            foods: ['fd_chicken'],
            dish: 'Thịt gà nghiền',
            symptoms: [SdSymptom.rash],
          ),
        ],
        settings: naSettings(),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.solids),
        overrides: solidsOverrides(store: store),
      );
      expect(_meal('Thịt gà nghiền'), findsOneWidget);
      expect(find.text('Có dấu hiệu'), findsOneWidget);
      expect(find.text('3 bữa'), findsOneWidget);
      await tester.tap(find.text('Nhật ký ăn dặm'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/solids');
    });

    testWidgets('an empty day offers "Ghi bữa ăn dặm"', (tester) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.solids),
        overrides: solidsOverrides(
          store: FakeSolidsStore(settings: naSettings()),
        ),
      );
      expect(find.text('Chưa ghi bữa ăn dặm hôm nay'), findsOneWidget);
      await tester.tap(find.text('Ghi bữa ăn dặm'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi bữa ăn'), findsOneWidget);
    });

    testWidgets('no "Ăn dặm" chip or rows while tracking is off', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.solids),
        overrides: solidsOverrides(
          store: FakeSolidsStore(
            meals: naMeals(),
            settings: naSettings(enabled: false),
          ),
        ),
      );
      expect(find.byKey(const Key('historySolids')), findsNothing);
      // Falls back to "Tất cả".
      expect(find.text('Đã ghi hôm nay'), findsOneWidget);
      expect(_meal('Cháo bí đỏ'), findsNothing);
    });

    testWidgets('Night care, English', (tester) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.solids),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Solids'), findsWidgets);
      expect(find.text('2 meals'), findsOneWidget);
      expect(find.text('Solids · 4 spoons · Liked · by you'), findsOneWidget);
    });
  });

  group('Thống kê', () {
    testWidgets('7 days: meals per day and new foods per week, information '
        'only', (tester) async {
      await pumpRouted(
        tester,
        const FeedStatsScreen(),
        overrides: solidsOverrides(),
      );
      await _see(tester, find.byKey(const Key('sdStatsKpis')));
      expect(find.text('Bữa ăn dặm'), findsOneWidget);
      expect(find.text('7 ngày gần đây · chỉ để tham khảo'), findsOneWidget);
      // 11 meals from 02/10 to 08/10; 8 foods new this week (from Monday 05/10).
      expect(find.text('1,6'), findsOneWidget);
      expect(find.text('8 món'), findsWidgets);
      expect(find.byKey(const Key('sdStatsChart')), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdStatsWeek_1')));
      expect(find.text('Tuần từ 05/10'), findsOneWidget);
      expect(find.text('Tuần từ 28/09'), findsOneWidget);
      expect(find.text('6 món'), findsOneWidget);
      expect(
        find.text(
          'Đây là ghi chép của gia đình, không phải mục tiêu số bữa hay số món.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('today: meals today and new foods this week', (tester) async {
      await pumpRouted(
        tester,
        const FeedStatsScreen(),
        prefs: {'stats.feed.window': 'today'},
        overrides: solidsOverrides(),
      );
      await _see(tester, find.byKey(const Key('sdStatsKpis')));
      expect(find.text('Hôm nay · chỉ để tham khảo'), findsOneWidget);
      expect(find.text('Bữa hôm nay'), findsOneWidget);
      expect(find.text('2 bữa'), findsOneWidget);
      expect(find.byKey(const Key('sdStatsChart')), findsNothing);
    });

    testWidgets('no card while tracking is off', (tester) async {
      await pumpRouted(
        tester,
        const FeedStatsScreen(),
        overrides: solidsOverrides(
          store: FakeSolidsStore(
            meals: naMeals(),
            settings: naSettings(enabled: false),
          ),
        ),
      );
      await tester.drag(_down(), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Bữa ăn dặm'), findsNothing);
    });

    testWidgets('Night care, English', (tester) async {
      await pumpRouted(
        tester,
        const FeedStatsScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      await _see(tester, find.byKey(const Key('sdStatsKpis')));
      expect(tester.takeException(), isNull);
      expect(find.text('Solid meals'), findsOneWidget);
      expect(find.text('Last 7 days · for information only'), findsOneWidget);
      expect(find.text('1.6'), findsOneWidget);
    });
  });
}
