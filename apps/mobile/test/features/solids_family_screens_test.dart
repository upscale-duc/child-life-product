import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/solids/solids_family_screens.dart';
import 'package:child_life/features/solids/solids_history.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_recipes.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_sheet.dart';
import 'package:child_life/features/solids/solids_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// "Công thức nhà mình" and dishes made on the screens (D-086; plan §12 #1, #2, #4): the recipe
/// pages' "Nhà mình đã làm" and "Các lần đã làm", meal detail's "Theo công thức" and "Lưu thành
/// công thức", the editor (prefill, ingredients, steps, nudges that never block), the family
/// recipe page ("Sửa", "Xoá" with undo, "Ghi vào nhật ký"), roles, 5f "Nhà mình", 4f, the 5c
/// chips and "Dành cho {bé}". Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh; Teddy is 7 months.

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

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = _in(key, find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// A family recipe with a quantity, two steps and a note, by Mai.
SdFamilyRecipe _porridge({Membership? by, String? photoPath}) => familyRecipe(
  'Cháo bí đỏ nhà mình',
  id: 'fr_${'1' * 32}',
  by: by,
  photoPath: photoPath,
  ingredients: const [
    SdFamilyIngredient(
      foodId: 'fd_rice',
      name: 'Gạo',
      qty: 30,
      unit: SdIngredientUnit.g,
    ),
    SdFamilyIngredient(foodId: 'fd_pumpkin', name: 'Bí đỏ'),
    SdFamilyIngredient(foodId: 'fd_egg', name: 'Lòng đỏ trứng'),
    SdFamilyIngredient(name: 'Nước dùng rau'),
  ],
  steps: const ['Nấu cháo nhừ.', 'Thêm bí đỏ hấp nghiền.'],
  note: 'Bé thích ăn ấm.',
  createdAt: vnOn(10, 2, 9, 0),
);

void main() {
  group('dishes made (§12 #1)', () {
    testWidgets('5g: "Nhà mình đã làm 2 lần", "Các lần đã làm" open the meal', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 5, 17, 0),
            dish: 'Cháo bí đỏ',
            foods: ['fd_rice', 'fd_pumpkin'],
            recipeId: 'rcp_chao_bi_do',
            reaction: SdReaction.neutral,
          ),
          meal(
            vnOn(10, 7, 17, 30),
            dish: 'Cháo bí đỏ tối',
            foods: ['fd_rice', 'fd_pumpkin'],
            recipeId: 'rcp_chao_bi_do',
            reaction: SdReaction.liked,
          ),
        ],
        settings: naSettings(),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_bi_do'),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('sdMadeLine'))).data,
        'Nhà mình đã làm 2 lần · gần nhất 07/10 · Teddy thích',
      );
      await _see(tester, find.byKey(const Key('sdMadeList')));
      expect(find.text('Các lần đã làm'), findsOneWidget);
      final rows = _in('sdMadeList', find.byType(SdMealRow));
      expect(rows, findsNWidgets(2));
      // Newest first, each with its day.
      expect(tester.widget<SdMealRow>(rows.first).meal.dish, 'Cháo bí đỏ tối');
      expect(
        _in('sdMadeList', find.text('Hôm qua · 17:30 · Thích')),
        findsOneWidget,
      );
      await tester.tap(rows.first);
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith('/care/solids/meal/m_'));
      // The editorial footnote stays on Child Life recipes.
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await _see(tester, find.byKey(const Key('lbIllustrative')));
    });

    testWidgets('nothing before a meal is logged from it', (tester) async {
      await pumpRouted(
        tester,
        const SdRecipeScreen(recipeId: 'rcp_chao_bi_do'),
        overrides: solidsOverrides(recipes: fixtureRecipes()),
      );
      expect(find.byKey(const Key('sdMade')), findsNothing);
      expect(find.byKey(const Key('sdMadeList')), findsNothing);
    });

    testWidgets('meal detail: "Theo công thức" opens the recipe; '
        '"Lưu thành công thức"', (tester) async {
      final family = _porridge();
      final fromRecipe = meal(
        vnOn(10, 8, 12, 0),
        dish: 'Cháo trưa',
        foods: ['fd_rice'],
        recipeId: 'rcp_chao_bi_do',
      );
      final fromFamily = meal(
        vnOn(10, 8, 13, 0),
        dish: 'Cháo nhà',
        foods: ['fd_rice'],
        recipeId: family.id,
      );
      final store = FakeSolidsStore(
        meals: [...naMeals(), fromRecipe, fromFamily],
        settings: naSettings(),
        family: [family],
      );
      final (visits, _) = await pumpRouted(
        tester,
        MealDetailScreen(mealId: fromRecipe.id),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      expect(
        find.text('Theo công thức: Cháo bí đỏ cho bé mới tập'),
        findsOneWidget,
      );
      await _tap(tester, 'sdFromRecipe');
      expect(visits.last.location, '/care/solids/recipe/rcp_chao_bi_do');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await _tap(tester, 'sdSaveAsRecipe');
      expect(
        visits.last.location,
        '/care/solids/family/new?meal=${fromRecipe.id}',
      );

      // From a family recipe: the link, no "Lưu thành công thức" (it is one).
      await pumpRouted(
        tester,
        MealDetailScreen(mealId: fromFamily.id),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      expect(find.text('Theo công thức: Cháo bí đỏ nhà mình'), findsOneWidget);
      expect(find.byKey(const Key('sdSaveAsRecipe')), findsNothing);

      // A relative reads, never saves.
      final relative = member(
        'u_ba',
        'Bà ngoại',
        MemberRole.relative,
        Relation.grandmother,
        extra: const ExtraRights(viewDailyCare: true, viewBabyInfo: true),
      );
      await pumpRouted(
        tester,
        MealDetailScreen(mealId: fromRecipe.id),
        overrides: solidsOverrides(
          me: relative,
          store: store,
          recipes: fixtureRecipes(),
        ),
      );
      expect(find.byKey(const Key('sdFromRecipe')), findsOneWidget);
      expect(find.byKey(const Key('sdSaveAsRecipe')), findsNothing);
    });
  });

  group('the editor (§12 #2)', () {
    testWidgets('"Lưu thành công thức": the dish and its ingredients; qty, '
        'unit, steps reordered, a seasoning nudge that does not block', (
      tester,
    ) async {
      final source = meal(
        vnOn(10, 8, 12, 0),
        dish: 'Cháo gà bí đỏ',
        foods: ['fd_rice', 'fd_chicken'],
        free: ['Hành lá'],
      );
      final store = FakeSolidsStore(
        meals: [...naMeals(), source],
        settings: naSettings(),
      );
      final (visits, _) = await pumpRouted(
        tester,
        SdFamilyEditorScreen(fromMealId: source.id),
        overrides: solidsOverrides(store: store),
      );
      expect(find.text('Thêm công thức nhà mình'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              _in('sdFamilyTitle', find.byType(EditableText)),
            )
            .controller
            .text,
        'Cháo gà bí đỏ',
      );
      expect(_in('sdFamilyIng_0', find.text('Gạo')), findsOneWidget);
      expect(_in('sdFamilyIng_1', find.text('Thịt gà')), findsOneWidget);
      // Teddy had all of them in that meal: no ✦.
      expect(find.text('✦ Bé chưa thử'), findsNothing);
      expect(_in('sdFamilyIng_2', find.text('Hành lá')), findsOneWidget);
      await _type(tester, 'sdFamilyQty_0', '30');
      await _tap(tester, 'sdFamilyUnit_0');
      await _tap(tester, 'sdUnitOpt_g');
      expect(_in('sdFamilyUnit_0', find.text('g')), findsOneWidget);
      await _tap(tester, 'sdFamilyRemove_2');
      expect(find.text('Hành lá'), findsNothing);
      await _type(tester, 'sdFamilyStep_0', 'Nêm chút nước mắm.');
      await _tap(tester, 'sdFamilyAddStep');
      await _type(tester, 'sdFamilyStep_1', 'Nấu cháo nhừ.');
      await _tap(tester, 'sdFamilyStepUp_1');
      await _type(tester, 'sdFamilyNote', 'Ăn ấm.');
      // The seasoning nudge, saving still works.
      await _see(tester, find.byKey(const Key('sdNudges')));
      expect(
        find.text(
          '· Có thêm gia vị (Nêm chút nước mắm). Thức ăn của bé không cần muối, '
          'đường hay nước mắm.',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'sdFamilySave');
      final saved = store.family.single;
      expect(sdFamilyRecipeId(saved.id), isTrue);
      expect(saved.title, 'Cháo gà bí đỏ');
      expect(saved.ingredients, const [
        SdFamilyIngredient(
          foodId: 'fd_rice',
          name: 'Gạo',
          qty: 30,
          unit: SdIngredientUnit.g,
        ),
        SdFamilyIngredient(foodId: 'fd_chicken', name: 'Thịt gà'),
      ]);
      expect(saved.steps, ['Nấu cháo nhừ.', 'Nêm chút nước mắm.']);
      expect(saved.note, 'Ăn ấm.');
      expect(saved.createdBy, mai.uid);
      expect(store.calls.last, 'createRecipe ${saved.id}');
      // The new recipe's page takes the editor's place.
      expect(visits.last.location, '/care/solids/recipe/${saved.id}');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('from scratch: a title and an ingredient are needed; honey '
        'for 7 months is a nudge, not a block', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SdFamilyEditorScreen(),
        overrides: solidsOverrides(store: store),
      );
      await _tap(tester, 'sdFamilySave');
      expect(find.text('Thêm tên món.'), findsOneWidget);
      await _type(tester, 'sdFamilyTitle', 'Chuối nghiền mật ong');
      await _tap(tester, 'sdFamilySave');
      expect(find.text('Thêm ít nhất một nguyên liệu.'), findsOneWidget);
      await _tap(tester, 'sdFamilyAddIngredient');
      await _tap(tester, 'sdFood_fd_banana');
      await tester.enterText(find.byKey(const Key('sdFoodQuery')), 'Mật ong');
      await tester.pumpAndSettle();
      await _tap(tester, 'sdFood_fd_honey');
      await tester.enterText(find.byKey(const Key('sdFoodQuery')), 'Nước ấm');
      await tester.pumpAndSettle();
      await _tap(tester, 'sdAddFree');
      await _tap(tester, 'sdFoodsDone');
      expect(_in('sdFamilyIng_2', find.text('Nước ấm')), findsOneWidget);
      await _type(tester, 'sdFamilyQty_0', 'abc');
      await _tap(tester, 'sdFamilySave');
      expect(
        find.text('Nhập lượng từ 0,1 đến 2000, hoặc để trống.'),
        findsOneWidget,
      );
      await _type(tester, 'sdFamilyQty_0', '1');
      await _see(tester, find.byKey(const Key('sdNudges')));
      expect(
        find.text(
          '· Mật ong chỉ cho bé từ 12 tháng tuổi: trước đó có nguy cơ ngộ độc.',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'sdFamilySave');
      final saved = store.family.single;
      expect(saved.foodIds, ['fd_banana', 'fd_honey']);
      expect(saved.freeNames, ['Nước ấm']);
      expect(saved.ingredients.first.qty, 1);
      expect(saved.steps, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Sửa": prefilled, saved as an edit; a caregiver cannot edit '
        'a parent\'s recipe', (tester) async {
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [_porridge()],
      );
      await pumpRouted(
        tester,
        SdFamilyEditorScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(store: store),
      );
      expect(find.text('Sửa công thức'), findsOneWidget);
      expect(find.text('Nước dùng rau'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              _in('sdFamilyQty_0', find.byType(EditableText)),
            )
            .controller
            .text,
        '30',
      );
      await _type(tester, 'sdFamilyTitle', 'Cháo bí đỏ trứng');
      await _tap(tester, 'sdFamilyStepDown_0');
      await _tap(tester, 'sdFamilySave');
      final edited = store.family.single;
      expect(store.calls.last, 'editRecipe ${edited.id}');
      expect(edited.title, 'Cháo bí đỏ trứng');
      expect(edited.steps, ['Thêm bí đỏ hấp nghiền.', 'Nấu cháo nhừ.']);
      expect(edited.createdBy, mai.uid);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await pumpRouted(
        tester,
        SdFamilyEditorScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdFamilySave')), findsNothing);
      expect(
        find.text('Công thức này do người khác thêm: bạn chỉ xem được.'),
        findsOneWidget,
      );
    });
  });

  group('the photo (`recipes` folder, as meal photos)', () {
    setUp(() => mediaBytes = FakeMediaBytes());

    testWidgets('a parent adds one; replacing it deletes the old object', (
      tester,
    ) async {
      final photos = FakeVaccinePhotoStore();
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SdFamilyEditorScreen(),
        overrides: solidsOverrides(store: store, photos: photos),
      );
      await _type(tester, 'sdFamilyTitle', 'Bơ nghiền');
      await _tap(tester, 'sdPhotoAdd');
      await _tap(tester, 'sdPhotoCamera');
      final first = photos.uploaded.single;
      expect(first, startsWith('babies/$teddyId/recipes/'));
      expect(sdRecipePhotoPath(first), isTrue);
      await _tap(tester, 'sdFamilyAddIngredient');
      await _tap(tester, 'sdFood_fd_avocado');
      await _tap(tester, 'sdFoodsDone');
      await _tap(tester, 'sdFamilySave');
      final saved = store.family.single;
      expect(saved.photoPath, first);
      expect(photos.removed, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await pumpRouted(
        tester,
        SdFamilyEditorScreen(recipeId: saved.id),
        overrides: solidsOverrides(store: store, photos: photos),
      );
      await _tap(tester, 'sdPhotoReplace');
      await _tap(tester, 'sdPhotoLibrary');
      await _tap(tester, 'sdFamilySave');
      expect(store.family.single.photoPath, photos.uploaded.last);
      expect(photos.removed, [first]);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a caregiver replacing her photo only changes the path', (
      tester,
    ) async {
      final photos = FakeVaccinePhotoStore();
      const old = 'babies/$teddyId/recipes/oldphoto00000000.jpg';
      final mine = familyRecipe('Súp cô Lan', by: lan, photoPath: old);
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [mine],
      );
      await pumpRouted(
        tester,
        SdFamilyEditorScreen(recipeId: mine.id),
        overrides: solidsOverrides(me: lan, store: store, photos: photos),
      );
      await _tap(tester, 'sdPhotoReplace');
      await _tap(tester, 'sdPhotoLibrary');
      await _tap(tester, 'sdFamilySave');
      expect(store.family.single.photoPath, photos.uploaded.single);
      expect(photos.removed, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('the family recipe page (§12 #2)', () {
    testWidgets('5g layout without the footnote; ✦ and ⚠; nudges; '
        '"Ghi vào nhật ký" keeps the recipe', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 8, 13, 0),
            foods: ['fd_pumpkin'],
            symptoms: [SdSymptom.rash],
          ),
        ],
        settings: naSettings(),
        family: [_porridge()],
      );
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      expect(find.byType(SdFamilyRecipeScreen), findsOneWidget);
      expect(find.text('Cháo bí đỏ nhà mình'), findsOneWidget);
      expect(
        _in('sdRecipeChips', find.text('Công thức nhà mình')),
        findsOneWidget,
      );
      expect(_in('sdRecipeChips', find.text('4 nguyên liệu')), findsOneWidget);
      expect(find.text('Bạn thêm'), findsOneWidget);
      expect(find.text('Có trứng'), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdIngredientRow_3')));
      expect(_in('sdIngredientRow_0', find.text('30 g')), findsOneWidget);
      expect(
        _in('sdIngredientRow_2', find.text('✦ Bé chưa thử')),
        findsOneWidget,
      );
      // Signs after a meal of pumpkin alone: ⚠ on it.
      expect(
        _in('sdIngredientRow_1', find.text('⚠ Có dấu hiệu')),
        findsOneWidget,
      );
      expect(find.text('⚠ Có dấu hiệu'), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdFamilyNoteText')));
      expect(find.text('Thêm bí đỏ hấp nghiền.'), findsOneWidget);
      expect(find.text('Bé thích ăn ấm.'), findsOneWidget);
      expect(find.byKey(const Key('lbIllustrative')), findsNothing);
      expect(find.byKey(const Key('sdFamilyViewOnly')), findsNothing);

      await _tap(tester, 'sdRecipeLog');
      Finder sheet(String text) => find.descendant(
        of: find.byType(MealSheet),
        matching: find.text(text),
      );
      expect(sheet('Cháo bí đỏ nhà mình'), findsOneWidget);
      expect(sheet('Trứng gà · lần đầu'), findsOneWidget);
      expect(sheet('Nước dùng rau'), findsOneWidget);
      await _tap(tester, 'sdSaveMeal');
      final logged = store.meals.last;
      expect(logged.recipeId, _porridge().id);
      expect(logged.toCreateJson()['recipeId'], _porridge().id);
      expect(logged.freeFoods, ['Nước dùng rau']);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Now it has been made once.
      await tester.scrollUntilVisible(
        find.byKey(const Key('sdMadeLine')),
        -200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('sdMadeLine'))).data,
        'Nhà mình đã làm 1 lần · gần nhất 08/10',
      );
    });

    testWidgets('"Sửa" opens the editor; "Xoá" with undo', (tester) async {
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [_porridge()],
      );
      final (visits, _) = await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(store: store),
      );
      await _tap(tester, 'sdFamilyEdit');
      expect(visits.last.location, '/care/solids/family/${_porridge().id}');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await _tap(tester, 'sdFamilyDelete');
      expect(find.text('Xoá công thức này?'), findsOneWidget);
      await _tap(tester, 'sdFamilyDeleteConfirm');
      expect(store.calls, ['deleteRecipe ${_porridge().id}']);
      expect(find.text('Đã xoá công thức'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(store.calls.last, 'restoreRecipe ${_porridge().id}');
      expect(store.family, hasLength(1));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('roles: a caregiver logs from a parent\'s recipe, edits only '
        'her own; a relative reads', (tester) async {
      final mine = familyRecipe('Súp cô Lan', by: lan, id: 'fr_${'2' * 32}');
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [_porridge(), mine],
      );
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdFamilyEdit')), findsNothing);
      expect(find.byKey(const Key('sdFamilyDelete')), findsNothing);
      expect(find.byKey(const Key('sdRecipeLog')), findsOneWidget);
      expect(find.text('Mẹ thêm'), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdFamilyViewOnly')));

      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: mine.id),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdFamilyEdit')), findsOneWidget);
      expect(find.byKey(const Key('sdFamilyDelete')), findsOneWidget);

      final relative = member(
        'u_ba',
        'Bà ngoại',
        MemberRole.relative,
        Relation.grandmother,
        extra: const ExtraRights(viewDailyCare: true, viewBabyInfo: true),
      );
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(me: relative, store: store),
      );
      expect(find.text('Cháo bí đỏ nhà mình'), findsOneWidget);
      expect(find.byKey(const Key('sdFamilyEdit')), findsNothing);
      expect(find.byKey(const Key('sdRecipeLog')), findsNothing);
      // Without daily-care rights there is nothing to read.
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        overrides: solidsOverrides(me: hoa, store: store),
      );
      expect(find.text('Cháo bí đỏ nhà mình'), findsNothing);
    });

    testWidgets('a deleted or missing recipe', (tester) async {
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: 'fr_${'9' * 32}'),
        overrides: solidsOverrides(),
      );
      expect(find.text('Không tìm thấy công thức'), findsOneWidget);
      expect(find.text('Công thức có thể đã được xoá.'), findsOneWidget);
    });
  });

  group('where family recipes show (§12 #2, #4)', () {
    testWidgets('5f: "Nhà mình" first, search, "Thêm"; "Dành cho" ranks them', (
      tester,
    ) async {
      final fresh = familyRecipe(
        'Cháo bí đỏ nhà mình',
        id: 'fr_${'3' * 32}',
        createdAt: vnOn(10, 7, 9, 0),
      );
      final soup = familyRecipe(
        'Súp gà',
        id: 'fr_${'4' * 32}',
        ingredients: const [
          SdFamilyIngredient(foodId: 'fd_chicken', name: 'Thịt gà'),
          SdFamilyIngredient(foodId: 'fd_egg', name: 'Trứng'),
        ],
      );
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [fresh, soup],
      );
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          store: store,
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
        ),
      );
      expect(find.byKey(Key('sdFamily_${fresh.id}')), findsOneWidget);
      expect(find.byKey(Key('sdFamily_${soup.id}')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(Key('sdFamily_${fresh.id}'))).dy,
        lessThan(tester.getTopLeft(find.text('Dành cho Teddy')).dy),
      );
      // "Dành cho Teddy": the family's porridge (both foods liked, newest) first, tagged.
      final forBaby = find.byKey(Key('sdForBaby_${fresh.id}'));
      expect(forBaby, findsOneWidget);
      expect(
        find.descendant(of: forBaby, matching: find.byType(SdFamilyTag)),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(forBaby).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('sdForBaby_rcp_chao_trung')))
              .dy,
        ),
      );
      // Two untried foods: not for Teddy yet.
      expect(find.byKey(Key('sdForBaby_${soup.id}')), findsNothing);
      await tester.enterText(find.byKey(const Key('sdLibraryQuery')), 'súp');
      await tester.pumpAndSettle();
      expect(find.byKey(Key('sdFamily_${soup.id}')), findsOneWidget);
      expect(find.byKey(Key('sdFamily_${fresh.id}')), findsNothing);
      await tester.enterText(find.byKey(const Key('sdLibraryQuery')), '');
      await tester.pumpAndSettle();
      await _tap(tester, 'sdFamilyAdd');
      expect(visits.last.location, '/care/solids/family/new');
    });

    testWidgets('5f before any: the "Thêm công thức nhà mình" card; not for '
        'relatives', (tester) async {
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(articles: articlesWithSolids()),
      );
      expect(find.text('Thêm công thức nhà mình'), findsOneWidget);
      final relative = member(
        'u_ba',
        'Bà ngoại',
        MemberRole.relative,
        Relation.grandmother,
        extra: const ExtraRights(viewDailyCare: true, viewBabyInfo: true),
      );
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          me: relative,
          articles: articlesWithSolids(),
        ),
      );
      expect(find.byKey(const Key('sdFamilyAdd')), findsNothing);
    });

    testWidgets('4f "Đã lưu › Ăn dặm": "Nhà mình", then "Bạn đã lưu"', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [_porridge()],
      );
      await pumpRouted(
        tester,
        const SavedArticlesScreen(library: LbLibrary.solids),
        overrides: solidsOverrides(
          store: store,
          articles: articlesWithSolids(),
          recipes: fixtureRecipes(),
          saved: [
            (
              id: 'art_solids_iron',
              savedAt: DateTime.utc(2026, 10, 2),
              revision: 1,
            ),
          ],
        ),
      );
      final family = find.byKey(Key('lbSavedFamily_${_porridge().id}'));
      expect(family, findsOneWidget);
      // The header, and the tag on the row.
      expect(find.text('Nhà mình'), findsNWidgets(2));
      expect(find.text('Bạn đã lưu'), findsOneWidget);
      expect(
        tester.getTopLeft(family).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('lbSaved_art_solids_iron')))
              .dy,
        ),
      );
      // Only family recipes: no empty state.
      await pumpRouted(
        tester,
        const SavedArticlesScreen(library: LbLibrary.solids),
        overrides: solidsOverrides(store: store),
      );
      expect(family, findsOneWidget);
      expect(find.text('Bạn đã lưu'), findsNothing);
      expect(find.text('Chưa lưu bài nào'), findsNothing);
    });

    testWidgets('5c "Món nhà mình": one tap fills the meal and keeps the id', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [_porridge()],
      );
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      expect(find.text('Món nhà mình'), findsOneWidget);
      await _tap(tester, 'sdFamilyChip_${_porridge().id}');
      expect(
        tester
            .widget<SdPill>(find.byKey(Key('sdFamilyChip_${_porridge().id}')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<EditableText>(_in('sdDish', find.byType(EditableText)))
            .controller
            .text,
        'Cháo bí đỏ nhà mình',
      );
      expect(find.byKey(const Key('sdIngredient_fd_egg')), findsOneWidget);
      await _tap(tester, 'sdSaveMeal');
      final logged = store.meals.last;
      expect(logged.recipeId, _porridge().id);
      expect(logged.foodIds, ['fd_rice', 'fd_pumpkin', 'fd_egg']);
      expect(logged.freeFoods, ['Nước dùng rau']);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a suggestion\'s "Xem công thức" counts the family\'s recipes', (
      tester,
    ) async {
      final eggPorridge = familyRecipe(
        'Cháo trứng nhà mình',
        id: 'fr_${'5' * 32}',
        ingredients: const [
          SdFamilyIngredient(foodId: 'fd_rice', name: 'Gạo'),
          SdFamilyIngredient(foodId: 'fd_egg', name: 'Trứng'),
        ],
      );
      final store = FakeSolidsStore(
        meals: naMeals(),
        settings: naSettings(),
        family: [eggPorridge],
      );
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      // Two recipes fit egg now (one Child Life, one the family's): the list opens.
      await _tap(tester, 'sdSuggestionAction_s3:egg');
      expect(visits.last.location, startsWith('/care/solids/recipes?food='));

      await pumpRouted(
        tester,
        const SdRecipeListScreen(foodIds: ['fd_egg']),
        overrides: solidsOverrides(store: store, recipes: fixtureRecipes()),
      );
      expect(find.byKey(const Key('sdRecipe_rcp_chao_trung')), findsOneWidget);
      expect(find.byKey(Key('sdRecipe_${eggPorridge.id}')), findsOneWidget);
      expect(find.byType(SdFamilyTag), findsOneWidget);
    });
  });

  group('Night care and English', () {
    testWidgets('the family recipe page', (tester) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            vnOn(10, 7, 17, 0),
            foods: ['fd_rice'],
            recipeId: _porridge().id,
            reaction: SdReaction.notYet,
          ),
        ],
        settings: naSettings(),
        family: [_porridge()],
      );
      await pumpRouted(
        tester,
        SdRecipeScreen(recipeId: _porridge().id),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(store: store),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Family recipe'), findsOneWidget);
      expect(find.text('Added by you'), findsOneWidget);
      expect(
        find.text("Made at home once · last on 07/10 · Teddy wasn't keen yet"),
        findsOneWidget,
      );
      expect(find.text('Log to diary'), findsOneWidget);
    });

    testWidgets('the editor with a nudge', (tester) async {
      await pumpRouted(
        tester,
        const SdFamilyEditorScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Add a family recipe'), findsOneWidget);
      await _type(tester, 'sdFamilyNote', 'Add a pinch of salt');
      await _see(tester, find.byKey(const Key('sdNudges')));
      expect(find.text('Worth knowing'), findsOneWidget);
    });
  });
}
