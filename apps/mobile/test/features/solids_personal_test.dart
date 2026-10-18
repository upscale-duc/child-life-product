import 'dart:convert';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_recipes.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_sheet.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/nutrition_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// "Gợi ý cho {bé}" on the screens (plan §7, phase D; free, D-085 #1): the 5b cards with their
/// "vì sao" line and one action, the 5h second line, "Để sau", "Không gợi ý món này" (parents:
/// settings; caregivers: this device), a logged meal completing a card, S9 on a new stage.
/// Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh; Na (Teddy here) is 7 months.

const _s3Egg = 'Đã đến lúc thử trứng chín kỹ: buổi sáng, ở nhà, một lượng nhỏ.';
const _s5 = 'Hôm nay thêm một món giàu sắt: Thịt gà.';

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _in(String key, Finder matching) =>
    find.descendant(of: find.byKey(Key(key)), matching: matching);

/// 6 foods, a new one yesterday, peas last on 30/09: S3, S5 and S8 (legumes).
List<SdMeal> _varietyMeals() => [
  meal(vnOn(9, 28, 11, 0), foods: ['fd_rice']),
  meal(vnOn(9, 29, 11, 0), foods: ['fd_pumpkin']),
  meal(vnOn(9, 30, 11, 0), foods: ['fd_peas']),
  meal(vnOn(10, 1, 11, 0), foods: ['fd_carrot']),
  meal(vnOn(10, 2, 11, 0), foods: ['fd_banana']),
  for (var d = 3; d <= 6; d++)
    meal(vnOn(10, d, 11, 0), foods: ['fd_rice', 'fd_pumpkin']),
  meal(vnOn(10, 7, 11, 0), foods: ['fd_rice', 'fd_apple']),
  meal(vnOn(10, 8, 11, 0), foods: ['fd_rice', 'fd_pumpkin']),
];

void main() {
  group('5b "Gợi ý cho Teddy hôm nay"', () {
    testWidgets('the primary card and a smaller one, each with "vì sao"', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(),
      );
      expect(find.text('Gợi ý cho Teddy hôm nay'), findsOneWidget);
      expect(_in('sdSuggestion_s3:egg', find.text(_s3Egg)), findsOneWidget);
      expect(
        find.text(
          'Vì Teddy đã quen 14 món và ăn dặm được 10 ngày: các món thường gây '
          'dị ứng nên cho làm quen từng món một, cách nhau vài ngày.',
        ),
        findsOneWidget,
      );
      expect(_in('sdSuggestion_s5', find.text(_s5)), findsOneWidget);
      expect(
        find.text(
          'Vì 2 ngày qua các bữa của Teddy chưa có món giàu sắt; từ 6 tháng bé '
          'cần sắt từ thức ăn mỗi ngày.',
        ),
        findsOneWidget,
      );
      // The primary card comes first.
      expect(
        tester.getTopLeft(find.byKey(const Key('sdSuggestion_s3:egg'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('sdSuggestion_s5'))).dy,
        ),
      );
    });

    testWidgets('5h shows the primary title as a second line', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('sdTodayCard')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('sdTodaySuggestion'))).data,
        _s3Egg,
      );
    });

    testWidgets('"Để sau" hides the card for 3 days on this device', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      final (_, container) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await _tap(tester, 'sdSuggestionLater_s3:egg');
      expect(find.text('Sẽ gợi ý lại sau 3 ngày'), findsOneWidget);
      expect(find.byKey(const Key('sdSuggestion_s3:egg')), findsNothing);
      expect(find.byKey(const Key('sdSuggestion_s5')), findsOneWidget);
      final raw = container
          .read(sharedPreferencesProvider)
          .getString('solids.snooze.$teddyId')!;
      expect(jsonDecode(raw), {
        'cards': {'s3:egg': '2026-10-11'},
        'foods': <String, Object?>{},
      });
      // Nothing about it leaves the device.
      expect(store.saved, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a parent: "Không gợi ý món này" hides egg in settings; '
        'peanut comes next', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await _tap(tester, 'sdSuggestionHide_s3:egg');
      final (settings, uid) = store.saved.single;
      expect(uid, mai.uid);
      expect(settings.hidden, ['fd_egg']);
      expect(find.text('Sẽ không gợi ý Trứng gà nữa'), findsOneWidget);
      expect(
        find.text(
          'Đã đến lúc thử bơ đậu phộng pha loãng (không cho cả hạt): buổi sáng, '
          'ở nhà, một lượng nhỏ.',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a caregiver: the food is hidden on this device only', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      final (_, container) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(me: lan, store: store),
      );
      await _tap(tester, 'sdSuggestionHide_s3:egg');
      expect(store.saved, isEmpty);
      expect(
        find.text('Đã ẩn Trứng gà khỏi gợi ý trên máy này trong 30 ngày'),
        findsOneWidget,
      );
      final raw = container
          .read(sharedPreferencesProvider)
          .getString('solids.snooze.$teddyId')!;
      expect((jsonDecode(raw) as Map)['foods'], {'fd_egg': '2026-11-07'});
      expect(find.byKey(const Key('sdSuggestion_s3:peanut')), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('S2 "Ghi bữa" opens 5c prefilled; the logged meal completes '
        'the card', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          meal(vnOn(10, 5, 11, 0), foods: ['fd_rice']),
          meal(vnOn(10, 6, 11, 0), foods: ['fd_pumpkin']),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      expect(
        find.text(
          'Món tiếp theo cho Teddy: Bông cải xanh, Cà rốt hoặc Thịt gà (giàu sắt).',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'sdSuggestionAction_s2');
      expect(
        find.descendant(
          of: find.byType(MealSheet),
          matching: find.text('Bông cải xanh · lần đầu'),
        ),
        findsOneWidget,
      );
      await _tap(tester, 'sdSaveMeal');
      expect(store.meals.last.foodIds, ['fd_broccoli']);
      expect(find.byKey(const Key('sdSuggestion_s2')), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('S5 completes once an iron-rich food is logged today', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      expect(find.byKey(const Key('sdSuggestion_s5')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      await _tap(tester, 'sdAddFood');
      await tester.enterText(find.byKey(const Key('sdFoodQuery')), 'thịt gà');
      await tester.pumpAndSettle();
      await _tap(tester, 'sdFood_fd_chicken');
      await _tap(tester, 'sdFoodsDone');
      await _tap(tester, 'sdSaveMeal');
      expect(find.byKey(const Key('sdSuggestion_s5')), findsNothing);
      expect(find.byKey(const Key('sdSuggestion_s3:egg')), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Xem công thức" opens the one recipe that fits', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(recipes: fixtureRecipes()),
      );
      await _tap(tester, 'sdSuggestionAction_s3:egg');
      expect(visits.last.location, '/care/solids/recipe/rcp_chao_trung');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await _tap(tester, 'sdSuggestionAction_s5');
      expect(visits.last.location, '/care/solids/recipe/rcp_ga_khoai');
    });

    testWidgets('S1 after "Khó thở": primary, reads the reactions guide, '
        'no "Không gợi ý"', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 8, 14, 0),
            foods: ['fd_rice', 'fd_carrot', 'fd_chicken'],
            dish: 'Cháo cà rốt thịt gà',
            symptoms: [SdSymptom.breathing],
          ),
        ],
        settings: naSettings(),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      expect(
        find.text(
          'Theo dõi sau dấu hiệu hôm 08/10 (Thịt gà). Tạm chưa thử món mới vài '
          'ngày và hỏi bác sĩ nếu còn lo.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Vì bữa hôm 08/10 có ghi dấu hiệu sau khi ăn.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sdSuggestion_s3:egg')), findsNothing);
      expect(find.byKey(const Key('sdSuggestionHide_s1')), findsNothing);
      await _tap(tester, 'sdSuggestionAction_s1');
      // The guide is not published in this fixture: the library opens.
      expect(visits.last.location, '/care/solids/library');
    });

    testWidgets('S8 "Xem gợi ý" lists the group; a food logs a meal', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: _varietyMeals(),
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      expect(
        find.text('Tuần này Teddy chưa ăn đậu và hạt nào.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sdSuggestionHide_s8:legumeNut')),
        findsNothing,
      );
      await _tap(tester, 'sdSuggestionAction_s8:legumeNut');
      expect(find.text('Gợi ý: Đậu và hạt'), findsOneWidget);
      await _tap(tester, 'sdIdea_fd_peas');
      expect(
        find.descendant(
          of: find.byType(MealSheet),
          matching: find.text('Đậu Hà Lan'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('S9 on the first open in a new Dinh dưỡng stage', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const SolidsScreen(),
        prefs: {
          'solids.stage.$teddyId': jsonEncode({
            'id': 'nst_first',
            'on': '2026-09-01',
            'fresh': false,
          }),
        },
        overrides: [...solidsOverrides(), ...nutritionOverrides()],
      );
      expect(find.text('Teddy 7 tháng: Bột loãng → cháo rây.'), findsOneWidget);
      expect(
        find.text(
          'Vì Teddy vừa sang giai đoạn 6–8 tháng trong Dinh dưỡng; thức ăn thô dần '
          'theo từng giai đoạn.',
        ),
        findsOneWidget,
      );
      expect(
        jsonDecode(
          container
              .read(sharedPreferencesProvider)
              .getString('solids.stage.$teddyId')!,
        ),
        {'id': 'nst_solids', 'on': '2026-10-08', 'fresh': true},
      );
    });

    testWidgets('no S9 the first time a stage is ever seen', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: [...solidsOverrides(), ...nutritionOverrides()],
      );
      expect(find.byKey(const Key('sdSuggestion_s9')), findsNothing);
      expect(
        jsonDecode(
          container
              .read(sharedPreferencesProvider)
              .getString('solids.stage.$teddyId')!,
        ),
        {'id': 'nst_solids', 'on': '2026-10-08', 'fresh': false},
      );
    });

    testWidgets('a relative with daily-care rights reads the cards, without '
        '"Ghi bữa"', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          meal(vnOn(10, 5, 11, 0), foods: ['fd_rice']),
          meal(vnOn(10, 6, 11, 0), foods: ['fd_pumpkin']),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(
          me: member(
            'u_hoa',
            'Bà Hoa',
            MemberRole.relative,
            Relation.grandmother,
            extra: const ExtraRights(viewDailyCare: true, viewBabyInfo: true),
          ),
          store: store,
        ),
      );
      expect(find.byKey(const Key('sdSuggestion_s2')), findsOneWidget);
      expect(find.byKey(const Key('sdSuggestionAction_s2')), findsNothing);
      expect(find.byKey(const Key('sdSuggestionLater_s2')), findsOneWidget);
    });

    testWidgets('nothing without published foods', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(
          store: FakeSolidsStore(
            meals: naMeals(),
            settings: naSettings(),
            foods: const [],
          ),
        ),
      );
      expect(find.byKey(const Key('sdSuggestions')), findsNothing);
    });

    testWidgets('Night care, English', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ideas for Teddy today'), findsOneWidget);
      expect(
        find.text(
          'Time to try well-cooked egg: in the morning, at home, a small amount.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Add an iron-rich food today: Chicken.'),
        findsOneWidget,
      );
      expect(find.text('Later'), findsWidgets);
    });
  });

  group('"Xem công thức" list', () {
    testWidgets('the ranking for the foods, or every recipe with them', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SdRecipeListScreen(foodIds: ['fd_egg']),
        overrides: solidsOverrides(recipes: fixtureRecipes()),
      );
      expect(find.text('Công thức có Trứng gà'), findsOneWidget);
      expect(find.byKey(const Key('sdRecipe_rcp_chao_trung')), findsOneWidget);
      expect(find.byKey(const Key('sdRecipe_rcp_trung_ga')), findsNothing);

      await pumpRouted(
        tester,
        const SdRecipeListScreen(foodIds: ['fd_egg']),
        overrides: solidsOverrides(
          store: FakeSolidsStore(),
          recipes: fixtureRecipes(),
        ),
      );
      for (final id in ['rcp_chao_trung', 'rcp_trung_ga', 'rcp_banh_chuoi']) {
        expect(find.byKey(Key('sdRecipe_$id')), findsOneWidget);
      }
    });
  });
}
