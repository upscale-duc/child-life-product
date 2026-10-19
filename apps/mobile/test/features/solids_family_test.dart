import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/solids/solids_calc.dart';
import 'package:child_life/features/solids/solids_family.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/solids_fixtures.dart';

/// "Công thức nhà mình" and "which day the baby ate what" (D-086; plan §12), the pure rules: the
/// family recipe document (mirrors `familyRecipeSchema`), the seasoning checks mirrored from
/// `solidsCopyProblems`, the nudges, dishes made, the 5c fill, the 5d search and calendar, and
/// the "Dành cho {bé}" ranking with the family's recipes. Na (Teddy) is 7 months on 8 Oct 2026.

Map<String, SdFood> _foods() => {for (final f in fixtureFoods()) f.id: f};

const _rice = SdFamilyIngredient(foodId: 'fd_rice', name: 'Gạo');
const _egg = SdFamilyIngredient(foodId: 'fd_egg', name: 'Trứng gà');
const _chicken = SdFamilyIngredient(foodId: 'fd_chicken', name: 'Thịt gà');

void main() {
  group('the family recipe document (familyRecipeSchema)', () {
    test('ids: fr_ + 32 hex; a meal may point at rcp_ or fr_', () {
      final id = newFamilyRecipeId();
      expect(RegExp(r'^fr_[a-f0-9]{32}$').hasMatch(id), isTrue);
      expect(sdFamilyRecipeId(id), isTrue);
      expect(sdFamilyRecipeId('fr_123'), isFalse);
      expect(sdMealRecipeRef(id), isTrue);
      expect(sdMealRecipeRef('rcp_chao_bi_do'), isTrue);
      expect(sdMealRecipeRef('m_${'a' * 32}'), isFalse);
      final m = SdMeal.fromJson('m_${'b' * 32}', {
        'occurredAt': Timestamp.fromDate(DateTime(2026, 10, 8, 11)),
        'slot': 'noon',
        'dish': 'Cháo',
        'recipeId': id,
      });
      expect(m!.recipeId, id);
      expect(
        SdMeal.fromJson('m_${'b' * 32}', {
          'occurredAt': Timestamp.fromDate(DateTime(2026, 10, 8, 11)),
          'slot': 'noon',
          'dish': 'Cháo',
          'recipeId': 'fr_bad',
        })!.recipeId,
        isNull,
      );
    });

    test('create, edit and read back the strict shape', () {
      final r = SdFamilyRecipe.create(
        id: 'fr_${'c' * 32}',
        me: lan,
        title: '  Cháo bí đỏ thịt bằm  ',
        photoPath: 'babies/$teddyId/recipes/abcdefgh12345678.jpg',
        ingredients: const [
          SdFamilyIngredient(
            foodId: 'fd_rice',
            name: 'Gạo',
            qty: 30,
            unit: SdIngredientUnit.g,
          ),
          SdFamilyIngredient(name: 'Thịt heo', qty: 0.5),
        ],
        steps: [for (var i = 1; i <= 14; i++) 'Bước $i', '  '],
        note: 'Cất tủ lạnh.',
      );
      expect(r.pending, isTrue);
      expect(r.foodIds, ['fd_rice']);
      expect(r.freeNames, ['Thịt heo']);
      final j = r.toCreateJson();
      expect(j.keys.toSet(), {
        'id',
        'babyId',
        'title',
        'photoPath',
        'ingredients',
        'steps',
        'note',
        'createdBy',
        'author',
        'createdAt',
        'clientCreatedAt',
        'updatedAt',
        'updatedBy',
        'deleted',
        'deletedAt',
        'deletedBy',
      });
      expect(j['id'], 'fr_${'c' * 32}');
      expect(j['babyId'], teddyId);
      expect(j['title'], 'Cháo bí đỏ thịt bằm');
      expect(j['createdBy'], lan.uid);
      expect(j['updatedBy'], lan.uid);
      expect(j['deleted'], isFalse);
      expect(j['createdAt'], isA<FieldValue>());
      expect(j['clientCreatedAt'], isA<Timestamp>());
      expect(j['ingredients'], [
        {'foodId': 'fd_rice', 'name': 'Gạo', 'qty': 30, 'unit': 'g'},
        {'foodId': null, 'name': 'Thịt heo', 'qty': 0.5, 'unit': null},
      ]);
      // Up to 12 steps, blank ones dropped.
      expect(j['steps'], [for (var i = 1; i <= 12; i++) 'Bước $i']);
      final edit = r
          .edited(
            title: 'Cháo bí đỏ',
            photoPath: null,
            ingredients: const [_rice],
            steps: const ['Nấu.'],
            note: '',
          )
          .toEditJson(mai.uid);
      expect(edit.keys.toSet(), {
        'title',
        'photoPath',
        'ingredients',
        'steps',
        'note',
        'updatedAt',
        'updatedBy',
      });
      expect(edit['updatedBy'], mai.uid);

      final back = SdFamilyRecipe.fromJson(r.id, {
        ...j,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      })!;
      expect(back.title, 'Cháo bí đỏ thịt bằm');
      expect(back.ingredients.first.unit, SdIngredientUnit.g);
      expect(back.ingredients.last.qty, 0.5);
      expect(back.steps, hasLength(12));
      expect(back.author.name, 'Cô Lan');
      // Not a family recipe without an ingredient, a title, or a valid id.
      expect(SdFamilyRecipe.fromJson(r.id, {...j, 'ingredients': []}), isNull);
      expect(SdFamilyRecipe.fromJson(r.id, {...j, 'title': ' '}), isNull);
      expect(SdFamilyRecipe.fromJson('fr_x', j), isNull);
    });

    test('read defensively (Rules cannot check foodId, qty, unit); written '
        'as the Rules expect', () {
      final j = {
        'title': 'Cháo',
        'photoPath': 'babies/$teddyId/meals/abcdefgh12345678.jpg',
        'ingredients': [
          {'foodId': 'fd_rice', 'name': 'Gạo', 'qty': -1, 'unit': 'cup'},
          {'foodId': 'not an id', 'name': 'Bí', 'qty': 5000, 'unit': 'g'},
          {'foodId': null, 'name': 'Nước', 'qty': 'x', 'unit': null},
          {'foodId': 'fd_egg', 'name': 'Trứng', 'qty': 1.5, 'unit': 'piece'},
        ],
        'steps': ['Nấu'],
        'note': '',
        'createdBy': mai.uid,
        'author': CareAuthor.of(mai).toJson(),
      };
      final r = SdFamilyRecipe.fromJson('fr_${'d' * 32}', j)!;
      expect(r.ingredients, const [
        SdFamilyIngredient(foodId: 'fd_rice', name: 'Gạo'),
        SdFamilyIngredient(name: 'Bí', unit: SdIngredientUnit.g),
        SdFamilyIngredient(name: 'Nước'),
        SdFamilyIngredient(
          foodId: 'fd_egg',
          name: 'Trứng',
          qty: 1.5,
          unit: SdIngredientUnit.piece,
        ),
      ]);
      // A meal photo path is not a recipe photo.
      expect(r.photoPath, isNull);
      final out = r
          .edited(
            title: 'Cháo\u001Fbí',
            photoPath: 'babies/$teddyId/meals/abcdefgh12345678.jpg',
            ingredients: const [
              SdFamilyIngredient(foodId: 'fd_rice', name: 'Gạo', qty: 3000),
            ],
            steps: ['  Nấu\ncháo\u001F nhừ  ', '   ${'a' * 305}'],
            note: '',
          )
          .toEditJson(mai.uid);
      expect(out['title'], 'Cháo bí');
      expect(out['photoPath'], isNull);
      expect(out['ingredients'], [
        {'foodId': 'fd_rice', 'name': 'Gạo', 'qty': null, 'unit': null},
      ]);
      final steps = out['steps']! as List<String>;
      expect(steps.first, 'Nấu cháo  nhừ');
      expect(steps.last, 'a' * 300);
      expect(
        steps.every((x) => !x.contains(RegExp('[\u0000-\u001F]'))),
        isTrue,
      );
    });

    test('recipe photos may be dropped like meal photos', () {
      expect(
        sdRecipePhotoPath('babies/$teddyId/recipes/abcdefgh12345678.jpg'),
        isTrue,
      );
      expect(
        sdRecipePhotoPath('babies/$teddyId/meals/abcdefgh12345678.jpg'),
        isFalse,
      );
    });
  });

  group('seasonings (mirrors solidsCopyProblems)', () {
    test('an ingredient named after a seasoning', () {
      final hits = sdSeasoningProblems(
        ingredients: ['Muối', 'Nước mắm Phú Quốc', 'Gạo', 'Bí đỏ'],
      );
      expect(hits.map((h) => h.path), ['ingredients.0', 'ingredients.1']);
      expect(hits.map((h) => h.match), ['muối', 'nước mắm']);
    });

    for (final phrase in [
      'Nêm chút nước mắm cho thơm.',
      'Thêm một ít đường.',
      'Nêm nếm vừa ăn rồi tắt bếp.',
      'Add a pinch of salt.',
      'Season to taste.',
      'Cho thêm hạt nêm.',
    ]) {
      test('flags "$phrase"', () {
        expect(sdSeasoningProblems(steps: [phrase]), hasLength(1));
      });
    }

    for (final phrase in [
      'Không nêm muối.',
      'Không thêm đường.',
      'No added salt.',
      'Do not add sugar.',
      'Cho bí đỏ vào nồi.',
    ]) {
      test('lets "$phrase" pass', () {
        expect(sdSeasoningProblems(steps: [phrase]), isEmpty);
      });
    }

    test('the title and the note count too', () {
      final hits = sdSeasoningProblems(
        title: 'Cháo nêm nếm',
        note: 'thêm chút đường',
      );
      expect(hits.map((h) => h.path), ['title', 'note']);
    });
  });

  group('nudges (never blocks)', () {
    test('honey under 12 months, not twice as a seasoning', () {
      final n = sdFamilyNudges(
        ingredients: const [
          _rice,
          SdFamilyIngredient(name: 'Mật ong'),
        ],
        foods: _foods(),
        months: 7,
      );
      expect(n.map((x) => x.kind), [SdNudgeKind.honey]);
      expect(n.single.names, ['Mật ong']);
      // The catalogue's honey (minimum age 12) is honey too.
      final c = sdFamilyNudges(
        ingredients: const [SdFamilyIngredient(foodId: 'fd_honey', name: 'x')],
        foods: _foods(),
        months: 7,
      );
      expect(c.map((x) => x.kind), [SdNudgeKind.honey]);
      expect(c.single.names, ['Mật ong']);
    });

    test('from 12 months honey is still an added sweetener', () {
      final n = sdFamilyNudges(
        ingredients: const [SdFamilyIngredient(name: 'Mật ong')],
        foods: _foods(),
        months: 13,
      );
      expect(n.map((x) => x.kind), [SdNudgeKind.seasoning]);
      expect(n.single.names, ['mật ong']);
    });

    test('a food usually given later, seasonings, the choking note', () {
      final foods = {
        ..._foods(),
        'fd_milk': SdFood.fromDoc(
          'fd_milk',
          foodDoc(
            'fd_milk',
            'Sữa bò tươi',
            'Cow milk',
            'dairy',
            allergen: 'milk',
            minAgeMonths: 12,
          ),
        )!,
        'fd_grape': SdFood.fromDoc('fd_grape', {
          ...foodDoc('fd_grape', 'Nho', 'Grapes', 'fruit'),
          'chokingNote': {
            'vi': 'Cắt dọc làm tư.',
            'en': 'Cut lengthways into quarters.',
          },
        })!,
      };
      final n = sdFamilyNudges(
        ingredients: const [
          SdFamilyIngredient(foodId: 'fd_milk', name: 'Sữa'),
          SdFamilyIngredient(foodId: 'fd_grape', name: 'Nho'),
        ],
        foods: foods,
        months: 7,
        steps: const ['Nêm chút muối.'],
      );
      expect(n.map((x) => x.kind), [
        SdNudgeKind.tooYoung,
        SdNudgeKind.seasoning,
        SdNudgeKind.choking,
      ]);
      expect(n.first.minAgeMonths, 12);
      expect(n.first.names, ['Sữa bò tươi']);
      expect(n.last.names, ['Nho', 'Cắt dọc làm tư.']);
      // English names and notes.
      final en = sdFamilyNudges(
        ingredients: const [
          SdFamilyIngredient(foodId: 'fd_grape', name: 'Nho'),
        ],
        foods: foods,
        months: 7,
        locale: const Locale('en'),
      );
      expect(en.single.names, ['Grapes', 'Cut lengthways into quarters.']);
      // Unknown age: no age nudges.
      expect(
        sdFamilyNudges(
          ingredients: const [
            SdFamilyIngredient(foodId: 'fd_milk', name: 'Sữa'),
          ],
          foods: foods,
        ),
        isEmpty,
      );
    });

    test('✦ not tried and ⚠ signs', () {
      final meals = [
        ...naMeals(),
        meal(
          vnOn(10, 8, 13, 0),
          foods: ['fd_chicken'],
          symptoms: [SdSymptom.rash],
        ),
      ];
      final tried = {for (final t in sdTriedFoods(meals, _foods())) t.key: t};
      expect(sdNotTried(_egg, tried), isTrue);
      expect(sdNotTried(_rice, tried), isFalse);
      expect(
        sdNotTried(const SdFamilyIngredient(name: 'Nước'), tried),
        isFalse,
      );
      expect(sdHasSigns(_chicken, tried, const []), isTrue);
      expect(sdHasSigns(_chicken, tried, const ['fd_chicken']), isFalse);
    });
  });

  group('dishes made, 5c, "Lưu thành công thức"', () {
    test('the meals from a recipe, newest first, the latest reaction', () {
      final meals = [
        ...naMeals(),
        meal(
          vnOn(10, 5, 11, 0),
          dish: 'Cháo bí đỏ',
          recipeId: 'rcp_chao_bi_do',
          reaction: SdReaction.liked,
        ),
        meal(
          vnOn(10, 7, 12, 0),
          dish: 'Cháo bí đỏ',
          recipeId: 'rcp_chao_bi_do',
        ),
        meal(vnOn(10, 6, 12, 0), dish: 'Khác', recipeId: 'rcp_ga_khoai'),
      ];
      final made = sdDishesMade(meals, 'rcp_chao_bi_do');
      expect(made.meals, hasLength(2));
      expect(made.meals.first.occurredAt, vnOn(10, 7, 12, 0));
      // The latest one with a reaction.
      expect(made.reaction, SdReaction.liked);
      expect(sdDishesMade(meals, 'rcp_trung_ga').meals, isEmpty);
      final last = sdLastMadeByRecipe(meals);
      expect(last['rcp_chao_bi_do'], vnOn(10, 7, 12, 0));
    });

    test('recently made first, then newest saved', () {
      final a = familyRecipe('A', createdAt: vnOn(9, 30, 9, 0));
      final b = familyRecipe('B', createdAt: vnOn(10, 2, 9, 0));
      final c = familyRecipe('C', createdAt: vnOn(10, 1, 9, 0));
      final meals = [meal(vnOn(10, 6, 11, 0), dish: 'A', recipeId: a.id)];
      expect(sdRecentFamily([a, b, c], meals).map((r) => r.title), [
        'A',
        'B',
        'C',
      ]);
    });

    test('a family recipe fills 5c: 12 foods, 3 free names at most', () {
      final r = familyRecipe(
        'Cháo ${'rất ' * 20}ngon',
        ingredients: [
          for (final f in fixtureFoods().take(13))
            SdFamilyIngredient(foodId: f.id, name: f.name.vi),
          for (final n in ['Nước dùng', 'Thịt heo', 'Hành', 'Rau mùi'])
            SdFamilyIngredient(name: n),
        ],
      );
      final fill = sdFamilyMealFill(r);
      expect(fill.dish.length, lessThanOrEqualTo(SdLimits.mealDish));
      expect(fill.foodIds, hasLength(12));
      expect(fill.freeFoods, ['Nước dùng', 'Thịt heo', 'Hành']);
    });

    test('a meal saves as: the dish, else the ingredients joined', () {
      final withDish = meal(
        vnOn(10, 8, 11, 0),
        dish: 'Cháo gà',
        foods: ['fd_rice', 'fd_chicken'],
        free: ['Hành lá'],
      );
      final d = sdFamilyDraftFromMeal(withDish, _foods(), const Locale('vi'));
      expect(d.title, 'Cháo gà');
      expect(d.ingredients, const [
        SdFamilyIngredient(foodId: 'fd_rice', name: 'Gạo'),
        SdFamilyIngredient(foodId: 'fd_chicken', name: 'Thịt gà'),
        SdFamilyIngredient(name: 'Hành lá'),
      ]);
      final noDish = meal(
        vnOn(10, 8, 11, 0),
        foods: ['fd_avocado', 'fd_banana'],
      );
      expect(
        sdFamilyDraftFromMeal(noDish, _foods(), const Locale('en')).title,
        'Avocado, Banana',
      );
    });
  });

  group('which day the baby ate what (5d)', () {
    test('search: dish, ingredients, free names, recipe names', () {
      final meals = [
        ...naMeals(),
        meal(vnOn(10, 4, 17, 0), free: ['Cà rốt baby'], dish: 'Súp'),
        meal(vnOn(10, 3, 17, 0), dish: 'Bữa tối', recipeId: 'rcp_chao_bi_do'),
      ];
      final foods = _foods();
      final carrot = sdSearchMeals(meals, 'Cà rốt', foods: foods);
      // The catalogue carrot (06/10) and the free name (04/10), newest first.
      expect(carrot.map((m) => m.occurredAt), [
        vnOn(10, 6, 11, 0),
        vnOn(10, 4, 17, 0),
      ]);
      // Without marks, by synonym.
      expect(sdSearchMeals(meals, 'bi ngo', foods: foods), hasLength(7));
      expect(
        sdSearchMeals(
          meals,
          'mới tập',
          foods: foods,
          recipeNames: sdRecipeNames(fixtureRecipes(), const []),
        ).single.dish,
        'Bữa tối',
      );
      expect(sdSearchMeals(meals, '  ', foods: foods), isEmpty);
    });

    test('meals per day, the months back to the first meal, the grid', () {
      final counts = sdMealCounts(naMeals(), 'Asia/Ho_Chi_Minh');
      expect(counts[DateTime(2026, 10, 7)], 2);
      expect(counts[DateTime(2026, 9, 28)], 1);
      expect(counts[DateTime(2026, 10, 9)], isNull);
      expect(sdCalendarMonths(DateTime(2026, 8, 20), DateTime(2026, 10, 8)), [
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2026, 8),
      ]);
      expect(sdCalendarMonths(null, DateTime(2026, 10, 8)), [
        DateTime(2026, 10),
      ]);
      // 1 Oct 2026 is a Thursday: three blank days, then 31 days, to full weeks.
      final grid = sdMonthGrid(DateTime(2026, 10));
      expect(grid.take(3), everyElement(isNull));
      expect(grid[3], DateTime(2026, 10, 1));
      expect(grid.length % 7, 0);
      expect(grid.whereType<DateTime>(), hasLength(31));
    });
  });

  group('"Dành cho {bé}" with the family\'s recipes (§12 #4)', () {
    final foods = _foods();
    final tried = {for (final t in sdTriedFoods(naMeals(), foods)) t.key: t};
    final settings = naSettings();

    test('same rules: hidden, signs, honey, more than one untried', () {
      final ok = familyRecipe('Cháo bí đỏ nhà mình');
      final egg = familyRecipe('Cháo trứng', ingredients: const [_rice, _egg]);
      final two = familyRecipe('Trứng gà', ingredients: const [_egg, _chicken]);
      final honey = familyRecipe(
        'Chuối mật ong',
        ingredients: const [
          SdFamilyIngredient(foodId: 'fd_banana', name: 'Chuối'),
          SdFamilyIngredient(name: 'Mật ong'),
        ],
      );
      List<String> titles({SdSettings? s, Set<String> suggested = const {}}) =>
          [
            for (final r in sdFamilyRecipesFor(
              family: [ok, egg, two, honey],
              months: 7,
              settings: s ?? settings,
              foods: foods,
              tried: tried,
              suggested: suggested,
            ))
              r.title,
          ];
      expect(titles(), ['Cháo bí đỏ nhà mình', 'Cháo trứng']);
      expect(titles(s: naSettings(hidden: ['fd_pumpkin'])), ['Cháo trứng']);
      expect(titles(suggested: {'fd_egg'}), ['Cháo trứng']);
    });

    test('one ranking: liked ingredients, then newest; the tag on family', () {
      final fresh = familyRecipe(
        'Cháo bí đỏ nhà mình',
        createdAt: vnOn(10, 7, 9, 0),
      );
      final picks = sdForBabyPicks(
        recipes: fixtureRecipes(),
        family: [fresh],
        months: 7,
        settings: settings,
        foods: foods,
        tried: tried,
      );
      expect(picks.map((p) => p.id), [
        fresh.id,
        'rcp_chao_trung',
        'rcp_chao_bi_do',
        'rcp_ga_khoai',
      ]);
      expect(picks.first.isFamily, isTrue);
      expect(picks[1].isFamily, isFalse);
    });

    test('5f search on the family\'s recipes', () {
      final a = familyRecipe('Cháo bí đỏ', createdAt: vnOn(10, 1, 9, 0));
      final b = familyRecipe(
        'Súp gà',
        ingredients: const [_chicken],
        createdAt: vnOn(10, 2, 9, 0),
      );
      expect(sdSearchFamily([a, b], '').map((r) => r.title), [
        'Súp gà',
        'Cháo bí đỏ',
      ]);
      expect(
        sdSearchFamily([a, b], 'bí ngô', foods: foods).map((r) => r.title),
        ['Cháo bí đỏ'],
      );
      expect(
        sdSearchFamily([a, b], 'chicken', foods: foods).map((r) => r.title),
        ['Súp gà'],
      );
    });
  });
}
