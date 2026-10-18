import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_recipes.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_sheet.dart';
import 'package:child_life/features/solids/solids_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/library_fixtures.dart' show FakeContentStore;
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// Recipes (phase C, app side; Figma 5f `314:1987`, 5g `314:2095`; plan §3 #9, #11, §5): the 5f
/// sections and filters, "Dành cho {bé}" (plan §7), the recipe page with its marks, allergen
/// line and footnote, "Lưu" into 4f "Đã lưu › Ăn dặm" and "Ghi vào nhật ký". Na (the fixture
/// baby) is 7 months on Thursday 8 Oct 2026.

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

List<String> _rowIds(WidgetTester tester, String group, String prefix) => [
  for (final w in tester.widgetList<SdRecipeRow>(
    _in(group, find.byType(SdRecipeRow)),
  ))
    (w.key! as ValueKey<String>).value.replaceFirst(prefix, ''),
];

void main() {
  group('5f Thư viện ăn dặm', () {
    testWidgets('"Dành cho Teddy", "Công thức · 6–8 tháng" and "Xem tất cả"', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      // Ranked for Na: tried-and-liked foods first, then newest; at most one untried food.
      expect(find.text('Dành cho Teddy'), findsOneWidget);
      expect(_rowIds(tester, 'sdForBaby', 'sdForBaby_'), [
        'rcp_chao_trung',
        'rcp_chao_bi_do',
        'rcp_ga_khoai',
      ]);
      await _see(tester, find.byKey(const Key('sdRecipes')));
      expect(find.text('Công thức · 6–8 tháng'), findsOneWidget);
      expect(_rowIds(tester, 'sdRecipes', 'sdRecipe_'), hasLength(3));
      expect(find.text('Công thức · 15 phút'), findsWidgets);
      final row = _in('sdRecipes', find.text('Cháo gà khoai lang'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/solids/recipe/rcp_ga_khoai');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      // "Công thức" only: all four for the band, no guides.
      expect(_rowIds(tester, 'sdRecipes', 'sdRecipe_'), [
        'rcp_trung_ga',
        'rcp_chao_trung',
        'rcp_ga_khoai',
        'rcp_chao_bi_do',
      ]);
      expect(find.byKey(const Key('sdGuide_art_solids_iron')), findsNothing);
    });

    testWidgets('type, method and search on titles and ingredient names', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      await _tap(tester, 'sdType_recipes');
      await _tap(tester, 'sdRecipeMethod_blw');
      expect(_rowIds(tester, 'sdRecipes', 'sdRecipe_'), ['rcp_ga_khoai']);
      await _tap(tester, 'sdRecipeMethod_blw');
      // "bí ngô" is a synonym of Bí đỏ (the linked food).
      await tester.enterText(find.byKey(const Key('sdLibraryQuery')), 'bí ngô');
      await tester.pumpAndSettle();
      expect(_rowIds(tester, 'sdRecipes', 'sdRecipe_'), [
        'rcp_chao_trung',
        'rcp_chao_bi_do',
      ]);
      await tester.enterText(find.byKey(const Key('sdLibraryQuery')), '');
      await tester.pumpAndSettle();
      // Guides only: no recipes.
      await _tap(tester, 'sdType_guides');
      expect(find.byKey(const Key('sdRecipes')), findsNothing);
      expect(find.byKey(const Key('sdForBaby')), findsNothing);
      expect(find.byKey(const Key('sdGuide_art_solids_iron')), findsOneWidget);
    });

    testWidgets('without tracking: recipes, no "Dành cho"', (tester) async {
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          store: FakeSolidsStore(),
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      expect(find.byKey(const Key('sdForBaby')), findsNothing);
      await _see(tester, find.byKey(const Key('sdRecipes')));
      expect(find.byKey(const Key('sdRecipes')), findsOneWidget);
    });
  });

  group('5g Công thức', () {
    testWidgets('chips, quantities, ✦ Bé chưa thử, "Có trứng", steps, '
        'footnote', (tester) async {
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_trung'),
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      expect(find.text('Cháo bí đỏ trứng'), findsOneWidget);
      for (final chip in [
        'Công thức',
        '6–8 tháng',
        '15 phút',
        'Nghiền mịn',
        'Truyền thống',
      ]) {
        expect(_in('sdRecipeChips', find.text(chip)), findsOneWidget);
      }
      expect(
        find.text('2 phần ăn · Sơ chế 5 phút · nấu 10 phút'),
        findsOneWidget,
      );
      expect(find.text('Có trứng'), findsOneWidget);
      expect(find.byKey(const Key('sdRecipeAge')), findsNothing);
      await _see(tester, find.byKey(const Key('sdIngredientRow_3')));
      expect(_in('sdIngredientRow_0', find.text('30 g')), findsOneWidget);
      expect(_in('sdIngredientRow_2', find.text('1 miếng')), findsOneWidget);
      expect(
        _in('sdIngredientRow_3', find.text('1 thìa cà phê')),
        findsOneWidget,
      );
      // Na has not had egg; she knows rice and pumpkin.
      expect(
        _in('sdIngredientRow_2', find.text('✦ Bé chưa thử')),
        findsOneWidget,
      );
      expect(find.text('✦ Bé chưa thử'), findsOneWidget);
      await _see(tester, find.text('Nấu chín mềm.'));
      expect(find.text('Cách làm'), findsOneWidget);
      await _see(tester, find.byKey(const Key('lbIllustrative')));
      expect(find.text('Cất tủ lạnh, dùng trong 24 giờ.'), findsOneWidget);
      expect(find.text('Bé mới ăn vài thìa là bình thường.'), findsOneWidget);
      expect(find.text('· WHO 2023'), findsOneWidget);
    });

    testWidgets('"Ghi vào nhật ký" opens 5c with the dish, foods and recipe', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_trung'),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      await tester.tap(find.byKey(const Key('sdRecipeLog')));
      await tester.pumpAndSettle();
      expect(find.text('Ghi bữa ăn'), findsOneWidget);
      Finder sheet(String text) => find.descendant(
        of: find.byType(MealSheet),
        matching: find.text(text),
      );
      expect(sheet('Cháo bí đỏ trứng'), findsOneWidget);
      expect(sheet('Gạo'), findsOneWidget);
      expect(sheet('Bí đỏ'), findsOneWidget);
      expect(sheet('Trứng gà · lần đầu'), findsOneWidget);
      await _tap(tester, 'sdSaveMeal');
      final saved = store.meals.last;
      expect(saved.recipeId, 'rcp_chao_trung');
      expect(saved.dish, 'Cháo bí đỏ trứng');
      expect(saved.foodIds, ['fd_rice', 'fd_pumpkin', 'fd_egg']);
      expect(saved.toCreateJson()['recipeId'], 'rcp_chao_trung');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('⚠ for a food with signs; the reviewer line once reviewed', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 8, 13, 0),
            foods: ['fd_chicken'],
            symptoms: [SdSymptom.rash],
          ),
        ],
        settings: naSettings(),
      );
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_ga_khoai'),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      await _see(tester, find.byKey(const Key('sdIngredientRow_2')));
      expect(
        _in('sdIngredientRow_1', find.text('⚠ Có dấu hiệu')),
        findsOneWidget,
      );
      expect(_in('sdIngredientRow_2', find.text('0,5 chén')), findsOneWidget);
      expect(find.text('✦ Bé chưa thử'), findsNothing);
      await _see(tester, find.byKey(const Key('sdRecipeReview')));
      expect(find.byKey(const Key('lbIllustrative')), findsNothing);
    });

    testWidgets('a recipe from 9 months: the age notice', (tester) async {
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_banh_chuoi'),
        overrides: solidsOverrides(recipes: fixtureRecipes()),
      );
      final notice = find.byKey(const Key('sdRecipeAge'));
      await _see(tester, notice);
      expect(
        find.textContaining('Công thức cho bé từ 9 tháng. Teddy mới 7 tháng'),
        findsOneWidget,
      );
    });

    testWidgets(
      'no "Ghi vào nhật ký" while tracking is off; a missing recipe',
      (tester) async {
        await pumpRouted(
          tester,
          const SdRecipeScreen(recipeId: 'rcp_chao_bi_do'),
          overrides: solidsOverrides(
            store: FakeSolidsStore(),
            recipes: fixtureRecipes(),
          ),
        );
        expect(find.byKey(const Key('sdRecipeLog')), findsNothing);
        expect(find.byKey(const Key('sdRecipeSave')), findsOneWidget);
        expect(find.text('✦ Bé chưa thử'), findsNothing);

        await pumpRouted(
          tester,
          const SdRecipeScreen(recipeId: 'rcp_gone'),
          overrides: solidsOverrides(recipes: fixtureRecipes()),
        );
        expect(find.text('Không tìm thấy công thức'), findsOneWidget);
      },
    );

    testWidgets('"Lưu" keeps it in 4f "Đã lưu › Ăn dặm" next to the guides', (
      tester,
    ) async {
      // Saved like the guides, in `users/{uid}/savedArticles` (the Rules accept `rcp_…`).
      final store = FakeContentStore();
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_bi_do'),
        overrides: solidsOverrides(
          recipes: fixtureRecipes(),
          contentStore: store,
        ),
      );
      await tester.tap(find.byKey(const Key('sdRecipeSave')));
      await tester.pumpAndSettle();
      expect(store.calls, ['save rcp_chao_bi_do r1']);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await pumpRouted(
        tester,
        const SavedArticlesScreen(library: LbLibrary.solids),
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
          contentStore: store,
          saved: [
            (
              id: 'rcp_chao_bi_do',
              savedAt: DateTime.utc(2026, 10, 3),
              revision: 1,
            ),
            (
              id: 'art_solids_iron',
              savedAt: DateTime.utc(2026, 10, 2),
              revision: 1,
            ),
          ],
        ),
      );
      expect(
        find.byKey(const Key('lbSavedRecipe_rcp_chao_bi_do')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lbSaved_art_solids_iron')), findsOneWidget);
      expect(find.text('Công thức · lưu 03/10'), findsOneWidget);
      // Newest save first.
      expect(
        tester
            .getTopLeft(find.byKey(const Key('lbSavedRecipe_rcp_chao_bi_do')))
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('lbSaved_art_solids_iron')))
              .dy,
        ),
      );
      await tester.tap(
        find.byKey(const Key('sdRecipeBookmark_rcp_chao_bi_do')),
      );
      await tester.pumpAndSettle();
      expect(store.calls.last, 'unsave rcp_chao_bi_do');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Night care, English', (tester) async {
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_trung'),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(recipes: fixtureRecipes()),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Pumpkin congee with egg'), findsOneWidget);
      expect(find.text('Contains egg'), findsOneWidget);
      expect(find.text('Log to diary'), findsOneWidget);
      expect(
        find.text('2 servings · Prep 5 min · cook 10 min'),
        findsOneWidget,
      );
      await _see(tester, find.text('✦ Not tried yet'));
      expect(find.text('1 piece'), findsOneWidget);
    });

    testWidgets('5f in Night care, English', (tester) async {
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('For Teddy'), findsOneWidget);
      expect(
        tester.widget<SdPill>(find.byKey(const Key('sdType_recipes'))).label,
        'Recipes',
      );
    });
  });
}
