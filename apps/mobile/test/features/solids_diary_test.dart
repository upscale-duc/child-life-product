import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/solids/solids_history.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// "Which day the baby ate what" (D-086; plan §12 #3): 5d's "Lịch" (a month calendar with the
/// meals per day, back to the first meal, a day's meals in the 5b cards), the 5d search over
/// dish, ingredient and recipe names, food detail's every day (paged) and the 5b week strip's
/// "Hôm nay". Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh; Teddy's diary starts on 28/09.

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _see(WidgetTester tester, Finder f) => tester.scrollUntilVisible(
  f,
  200,
  scrollable: find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first,
);

Finder _in(String key, Finder matching) =>
    find.descendant(of: find.byKey(Key(key)), matching: matching);

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  group('5d "Lịch"', () {
    testWidgets('meals per day; a day\'s meals as 5b cards; months back to '
        'the first meal', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const MealHistoryScreen(),
        overrides: solidsOverrides(),
      );
      await tester.tap(find.text('Lịch'));
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdCalMonth'), 'Tháng 10 năm 2026');
      expect(_in('sdCal_2026-10-7', find.text('2')), findsOneWidget);
      expect(_in('sdCal_2026-10-8', find.text('2')), findsOneWidget);
      expect(find.byKey(const Key('sdCalCount_10-9')), findsNothing);
      // Today first.
      expect(_text(tester, 'sdCalDayHeader'), 'Hôm nay · 2 bữa');
      await _tap(tester, 'sdCal_2026-10-6');
      expect(_text(tester, 'sdCalDayHeader'), 'Thứ Ba 06/10 · 2 bữa');
      expect(find.text('Cà rốt hấp nghiền'), findsOneWidget);
      expect(find.byType(SdMealCard), findsNWidgets(2));
      await tester.tap(find.text('Cà rốt hấp nghiền'));
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith('/care/solids/meal/m_'));
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      // A future day does nothing; no month after this one.
      await _tap(tester, 'sdCal_2026-10-20');
      expect(_text(tester, 'sdCalDayHeader'), 'Thứ Ba 06/10 · 2 bữa');
      await _tap(tester, 'sdCalNext');
      expect(_text(tester, 'sdCalMonth'), 'Tháng 10 năm 2026');
      // September: the first meal (28/09) is chosen; no month before it.
      await _tap(tester, 'sdCalPrev');
      expect(_text(tester, 'sdCalMonth'), 'Tháng 9 năm 2026');
      expect(_text(tester, 'sdCalDayHeader'), 'Thứ Tư 30/09 · 1 bữa');
      expect(_in('sdCal_2026-9-28', find.text('1')), findsOneWidget);
      await _tap(tester, 'sdCalPrev');
      expect(_text(tester, 'sdCalMonth'), 'Tháng 9 năm 2026');
      await _tap(tester, 'sdCal_2026-9-28');
      expect(find.text('Cháo gạo'), findsOneWidget);
    });

    testWidgets('a swipe changes the month; a month without meals asks for a '
        'day', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          meal(vnOn(8, 20, 11, 0), foods: ['fd_rice'], dish: 'Cháo đầu tiên'),
          ...naMeals(),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const MealHistoryScreen(calendar: true),
        overrides: solidsOverrides(store: store),
      );
      expect(_text(tester, 'sdCalMonth'), 'Tháng 10 năm 2026');
      await tester.fling(
        find.byKey(const Key('sdCalMonth')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdCalMonth'), 'Tháng 9 năm 2026');
      await _tap(tester, 'sdCalPrev');
      expect(_text(tester, 'sdCalMonth'), 'Tháng 8 năm 2026');
      expect(_text(tester, 'sdCalDayHeader'), 'Thứ Năm 20/08 · 1 bữa');
    });
  });

  group('5d search', () {
    testWidgets('"cà rốt": every day with carrot, by day, newest first', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(vnOn(10, 2, 17, 0), dish: 'Súp', free: ['Cà rốt baby']),
          meal(vnOn(10, 4, 17, 0), dish: 'Bữa tối', recipeId: 'rcp_ga_khoai'),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const MealHistoryScreen(),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      await tester.enterText(find.byKey(const Key('sdHistoryQuery')), 'cà rốt');
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdHistorySearchCount'), '2 bữa có “cà rốt”');
      expect(find.text('Thứ Ba 06/10'), findsOneWidget);
      expect(find.text('Thứ Sáu 02/10'), findsOneWidget);
      expect(find.text('Hôm nay · Thứ Năm 08/10'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Thứ Ba 06/10')).dy,
        lessThan(tester.getTopLeft(find.text('Thứ Sáu 02/10')).dy),
      );
      // A recipe's name finds the meals cooked from it.
      await tester.enterText(
        find.byKey(const Key('sdHistoryQuery')),
        'cháo gà khoai',
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdHistorySearchCount'), '1 bữa có “cháo gà khoai”');
      expect(find.text('Bữa tối'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('sdHistoryQuery')), 'tôm');
      await tester.pumpAndSettle();
      expect(
        _text(tester, 'sdHistorySearchCount'),
        'Chưa có bữa nào có “tôm”.',
      );
      // Cleared: every day again.
      await tester.enterText(find.byKey(const Key('sdHistoryQuery')), '');
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay · Thứ Năm 08/10'), findsOneWidget);
      expect(find.byKey(const Key('sdHistorySearchCount')), findsNothing);
    });
  });

  group('food detail: every day it was eaten', () {
    testWidgets('day, time, amount, reaction and signs; 15 at a time', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          for (var d = 1; d <= 12; d++)
            meal(vnOn(9, d + 15, 17, 0), foods: ['fd_rice'], dish: 'Cháo $d'),
          meal(
            vnOn(10, 8, 13, 0),
            foods: ['fd_rice'],
            dish: 'Cháo trưa',
            reaction: SdReaction.notYet,
            symptoms: [SdSymptom.rash],
          ),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const FoodDetailScreen(foodKey: 'fd_rice'),
        overrides: solidsOverrides(store: store),
      );
      await _see(tester, find.byKey(const Key('sdFoodDays')));
      // 8 meals in the diary + 12 + 1.
      expect(find.text('Những lần bé đã ăn · 21'), findsOneWidget);
      await _see(tester, find.text('Hôm nay · 13:00 · Chưa hợp'));
      final first = find.ancestor(
        of: find.text('Hôm nay · 13:00 · Chưa hợp'),
        matching: find.byType(SdMealRow),
      );
      expect(
        find.descendant(
          of: first,
          matching: find.byKey(const Key('sdSignsTag')),
        ),
        findsOneWidget,
      );
      await _see(tester, find.byKey(const Key('sdFoodDaysMore')));
      expect(
        _in('sdFoodDays', find.byType(SdMealRow)).evaluate().length,
        lessThanOrEqualTo(15),
      );
      await _tap(tester, 'sdFoodDaysMore');
      expect(find.byKey(const Key('sdFoodDaysMore')), findsNothing);
      await _see(tester, find.text('Thứ Tư 16/09 · 17:00'));
    });
  });

  group('5b week strip', () {
    testWidgets('earlier weeks, and "Hôm nay" back', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(),
      );
      await tester.ensureVisible(find.byKey(const Key('sdWeekStrip')));
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdWeekRange'), '05/10 – 11/10');
      expect(find.byKey(const Key('sdWeekToday')), findsNothing);
      await tester.tap(find.byKey(const Key('sdDay_2026-10-6')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sdWeekToday')), findsOneWidget);
      await _tap(tester, 'sdWeekToday');
      expect(find.text('Hôm nay · 2 bữa'), findsOneWidget);
      expect(find.byKey(const Key('sdWeekToday')), findsNothing);
      await tester.drag(
        find.byKey(const Key('sdWeekStrip')),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdWeekRange'), '28/09 – 04/10');
      await _tap(tester, 'sdWeekToday');
      expect(_text(tester, 'sdWeekRange'), '05/10 – 11/10');
      expect(find.byKey(const Key('sdDay_2026-10-8')), findsOneWidget);
    });
  });

  group('Night care and English', () {
    testWidgets('5d calendar and search', (tester) async {
      await pumpRouted(
        tester,
        const MealHistoryScreen(calendar: true),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Calendar'), findsOneWidget);
      expect(_text(tester, 'sdCalMonth'), 'October 2026');
      expect(_text(tester, 'sdCalDayHeader'), 'Today · 2 meals');
      await tester.tap(find.text('Meals'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sdHistoryQuery')), 'carrot');
      await tester.pumpAndSettle();
      expect(_text(tester, 'sdHistorySearchCount'), '1 meal with “carrot”');
    });

    testWidgets('food detail and the week strip', (tester) async {
      await pumpRouted(
        tester,
        const FoodDetailScreen(foodKey: 'fd_carrot'),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      expect(tester.takeException(), isNull);
      await _see(tester, find.byKey(const Key('sdFoodDays')));
      expect(find.text('Every time baby had it · 1'), findsOneWidget);
      await pumpRouted(
        tester,
        const SolidsScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      await tester.ensureVisible(find.byKey(const Key('sdWeekStrip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sdDay_2026-10-6')));
      await tester.pumpAndSettle();
      expect(_in('sdWeekToday', find.text('Today')), findsOneWidget);
    });
  });
}
