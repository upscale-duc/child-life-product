import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/solids/solids_calc.dart';
import 'package:child_life/features/solids/solids_format.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_suggest.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/solids_fixtures.dart';

/// "Gợi ý cho {bé}" (plan §7, phase D; D-085 #1) and "Dành cho {bé}", with the §10 QA seeds: Na
/// (the fixture baby) born 2026-03-01, viewed on 2026-10-08 (7 months), Kết hợp, started
/// 2026-09-28.

const _zone = 'Asia/Ho_Chi_Minh';
final _today = DateTime(2026, 10, 8);

Map<String, SdFood> _foods() => {for (final f in fixtureFoods()) f.id: f};

SdSuggestInput _in(
  List<SdMeal> meals, {
  DateTime? today,
  int months = 7,
  SdSettings? settings,
  Set<String> snoozed = const {},
  Set<String> snoozedFoods = const {},
  String? stage,
  Map<String, SdFood>? foods,
}) => SdSuggestInput(
  months: months,
  today: today ?? _today,
  zone: _zone,
  settings: settings ?? naSettings(),
  meals: meals,
  foods: foods ?? _foods(),
  snoozed: snoozed,
  snoozedFoods: snoozedFoods,
  newStageId: stage,
);

List<SdRule> _rules(SdSuggestInput i) => [for (final c in sdSuggest(i)) c.rule];

SdCard? _card(SdSuggestInput i, SdRule r) =>
    sdSuggest(i).where((c) => c.rule == r).firstOrNull;

DateTime _day(int month, int day) => DateTime(2026, month, day);

/// Lunch at 11:00 in Hồ Chí Minh.
SdMeal _lunch(
  int month,
  int day,
  List<String> foods, {
  SdReaction? reaction,
  List<SdSymptom> symptoms = const [],
  int hour = 11,
}) => meal(
  vnOn(month, day, hour, 0),
  foods: foods,
  reaction: reaction,
  symptoms: symptoms,
);

/// QA #6: five foods from 28/09 to 02/10, no allergen yet (started 28/09).
List<SdMeal> _fiveFoods() => [
  _lunch(9, 28, ['fd_rice']),
  _lunch(9, 29, ['fd_pumpkin']),
  _lunch(9, 30, ['fd_carrot']),
  _lunch(10, 1, ['fd_sweet_potato']),
  _lunch(10, 2, ['fd_zucchini']),
];

void main() {
  group('when the section shows (plan §7)', () {
    test('nothing while tracking is off, under 6 months or without foods', () {
      expect(
        sdSuggest(_in(naMeals(), settings: naSettings(enabled: false))),
        isEmpty,
      );
      expect(sdSuggest(_in(naMeals(), months: 5)), isEmpty);
      expect(sdSuggest(_in(naMeals(), foods: const {})), isEmpty);
    });

    test('Na on 08/10: S3 egg is primary, S5 iron secondary, at most 3', () {
      final cards = sdSuggest(_in(naMeals()));
      expect([for (final c in cards) c.rule], [SdRule.s3, SdRule.s5]);
      expect(cards.first.primary, isTrue);
      expect(cards.skip(1).every((c) => !c.primary), isTrue);
      // Many rules at once: still 1 + 2, in priority order.
      final busy = sdSuggest(_in(naMeals(), today: _day(10, 13)));
      expect(busy, hasLength(sdMaxCards));
      expect([for (final c in busy) c.rule], [SdRule.s3, SdRule.s6, SdRule.s7]);
    });
  });

  group('S1 safety after symptoms (QA #4)', () {
    final reaction = _lunch(
      10,
      8,
      ['fd_rice', 'fd_carrot', 'fd_chicken'],
      symptoms: [SdSymptom.breathing],
      hour: 14,
    );
    final later = [
      ...naMeals(),
      reaction,
      _lunch(10, 9, ['fd_rice']),
      _lunch(10, 10, ['fd_rice']),
    ];

    test('primary for 3 days; nothing new and no allergen meanwhile', () {
      final eaten = {for (final m in later) ...m.foodIds};
      for (final d in [8, 9, 10]) {
        final cards = sdSuggest(_in(later, today: _day(10, d)));
        expect(cards.first.rule, SdRule.s1, reason: '$d/10');
        expect(cards.first.mealId, reaction.id);
        expect(cards.first.date, _day(10, 8));
        expect(cards.first.action, SdCardAction.readReactions);
        final rules = _rules(_in(later, today: _day(10, d)));
        for (final held in [SdRule.s2, SdRule.s3, SdRule.s4, SdRule.s6]) {
          expect(rules, isNot(contains(held)), reason: '$held on $d/10');
        }
        // Iron keeps to foods the baby has eaten while S1 holds.
        for (final c in cards.where((c) => c.rule == SdRule.s5)) {
          expect(c.foodIds.every(eaten.contains), isTrue, reason: '$d/10');
        }
      }
      final after = _rules(_in(later, today: _day(10, 11)));
      expect(after, isNot(contains(SdRule.s1)));
      expect(after.first, SdRule.s3);
    });

    test('the food with signs is never suggested until a parent clears it', () {
      for (var d = 8; d <= 20; d++) {
        for (final c in sdSuggest(_in(later, today: _day(10, d)))) {
          expect(c.foodIds, isNot(contains('fd_chicken')), reason: '$d/10');
        }
      }
      // Cleared ("Bác sĩ đã cho ăn lại"): S5 may offer it again.
      final s5 = _card(
        _in(
          later,
          today: _day(10, 11),
          settings: naSettings(cleared: ['fd_chicken']),
        ),
        SdRule.s5,
      );
      expect(s5?.foodIds, ['fd_chicken']);
    });

    test('snoozing S1 does not lift the wait on allergens', () {
      final rules = _rules(_in(later, snoozed: {'s1'}));
      expect(rules, isNot(contains(SdRule.s1)));
      expect(rules, isNot(contains(SdRule.s3)));
    });
  });

  group('S2 first foods', () {
    final two = [
      _lunch(10, 5, ['fd_rice']),
      _lunch(10, 6, ['fd_pumpkin']),
    ];

    test('fewer than 5 foods: two first foods and an iron-rich one last', () {
      final c = _card(_in(two), SdRule.s2)!;
      expect(c.primary, isTrue);
      expect(c.foodIds, ['fd_broccoli', 'fd_carrot', 'fd_chicken']);
      expect(c.count, 2);
      expect(c.action, SdCardAction.logMeal);
      expect(c.prefill, ['fd_broccoli']);
      // No allergen (S3's), nothing above its age (honey), no second card of new foods (S6).
      expect(c.foodIds, isNot(anyOf(contains('fd_egg'), contains('fd_honey'))));
      expect(_rules(_in(two)), isNot(contains(SdRule.s6)));
    });

    test('hidden foods and caregiver snoozes are skipped', () {
      final c = _card(
        _in(
          two,
          settings: naSettings(hidden: ['fd_broccoli']),
          snoozedFoods: {'fd_carrot'},
        ),
        SdRule.s2,
      )!;
      expect(c.foodIds, ['fd_katuk', 'fd_peas', 'fd_chicken']);
    });

    test('a meal today with a suggested food completes the card', () {
      expect(
        _rules(
          _in([
            ...two,
            _lunch(10, 8, ['fd_carrot']),
          ]),
        ),
        isNot(contains(SdRule.s2)),
      );
      // Another new food does not (the card stays the same all day).
      final other = _card(
        _in([
          ...two,
          _lunch(10, 8, ['fd_apple']),
        ]),
        SdRule.s2,
      );
      expect(other?.foodIds, ['fd_broccoli', 'fd_carrot', 'fd_chicken']);
      // From 5 foods, S2 is done.
      expect(_rules(_in(_fiveFoods())), isNot(contains(SdRule.s2)));
    });
  });

  group('S3 allergen introduction and S4 keep-up (QA #6)', () {
    test('5 foods, started 10 days ago, no allergen yet: egg', () {
      final c = _card(_in(_fiveFoods()), SdRule.s3)!;
      expect(c.allergen, SdAllergen.egg);
      expect(c.foodIds, ['fd_egg']);
      expect(c.count, 5);
      expect(c.days, 10);
      expect(c.action, SdCardAction.viewRecipes);
      expect(c.key, 's3:egg');
    });

    test('after an egg meal without symptoms, peanut 3 days later', () {
      final meals = [
        ..._fiveFoods(),
        _lunch(10, 8, ['fd_egg']),
      ];
      for (final d in [8, 9, 10]) {
        expect(
          _rules(_in(meals, today: _day(10, d))),
          isNot(contains(SdRule.s3)),
          reason: '$d/10',
        );
      }
      final c = _card(_in(meals, today: _day(10, 11)), SdRule.s3)!;
      expect(c.allergen, SdAllergen.peanut);
      expect(c.foodIds, ['fd_peanut']);
    });

    test('S4 fires on day 8 without egg', () {
      final meals = [
        ..._fiveFoods(),
        _lunch(10, 8, ['fd_egg']),
      ];
      expect(
        _rules(_in(meals, today: _day(10, 14))),
        isNot(contains(SdRule.s4)),
      );
      final c = _card(_in(meals, today: _day(10, 15)), SdRule.s4)!;
      expect(c.allergen, SdAllergen.egg);
      expect(c.foodIds, ['fd_egg']);
      expect(c.date, _day(10, 8));
      expect(c.prefill, ['fd_egg']);
      // An egg meal again keeps it up.
      expect(
        _rules(
          _in([
            ...meals,
            _lunch(10, 13, ['fd_egg']),
          ], today: _day(10, 15)),
        ),
        isNot(contains(SdRule.s4)),
      );
    });

    test('not before 7 days of tracking, nor with fewer than 5 foods', () {
      expect(
        _rules(
          _in(
            _fiveFoods(),
            settings: SdSettings(enabled: true, startedOn: _day(10, 4)),
          ),
        ),
        isNot(contains(SdRule.s3)),
      );
      expect(
        _rules(_in(_fiveFoods().take(4).toList())),
        isNot(contains(SdRule.s3)),
      );
    });

    test('a hidden allergen food is skipped; a snoozed card waits', () {
      expect(
        _card(
          _in(_fiveFoods(), settings: naSettings(hidden: ['fd_egg'])),
          SdRule.s3,
        )?.allergen,
        SdAllergen.peanut,
      );
      expect(
        _rules(_in(_fiveFoods(), snoozed: {'s3:egg'})),
        isNot(contains(SdRule.s3)),
      );
    });

    test('S4 skips an allergen with signs; another one takes its place', () {
      final meals = [
        ..._fiveFoods(),
        _lunch(10, 1, ['fd_egg'], symptoms: [SdSymptom.rash], hour: 17),
        _lunch(10, 2, ['fd_peanut'], hour: 17),
      ];
      final c = _card(_in(meals, today: _day(10, 12)), SdRule.s4)!;
      expect(c.allergen, SdAllergen.peanut);
      expect(
        _rules(_in(meals, today: _day(10, 12), snoozed: {'s4:peanut'})),
        isNot(contains(SdRule.s4)),
      );
    });
  });

  group('S5 iron (QA #7)', () {
    test('two days of meals without iron at 7 months', () {
      final c = _card(_in(naMeals()), SdRule.s5)!;
      expect(c.foodIds, ['fd_chicken']);
      expect(c.action, SdCardAction.viewRecipes);
    });

    test('prefers a tried, liked iron food', () {
      final likedChicken = [
        _lunch(9, 30, ['fd_chicken'], reaction: SdReaction.liked, hour: 17),
        _lunch(10, 1, ['fd_egg'], reaction: SdReaction.neutral, hour: 17),
        ...naMeals(),
      ];
      expect(_card(_in(likedChicken), SdRule.s5)!.foodIds, [
        'fd_chicken',
        'fd_egg',
      ]);
      final likedEgg = [
        _lunch(9, 30, ['fd_chicken'], reaction: SdReaction.neutral, hour: 17),
        _lunch(10, 1, ['fd_egg'], reaction: SdReaction.liked, hour: 17),
        ...naMeals(),
      ];
      expect(_card(_in(likedEgg), SdRule.s5)!.foodIds, [
        'fd_egg',
        'fd_chicken',
      ]);
    });

    test('not with an iron-rich food in the last 2 days or today', () {
      expect(
        _rules(
          _in([
            ...naMeals(),
            _lunch(10, 7, ['fd_chicken'], hour: 18),
          ]),
        ),
        isNot(contains(SdRule.s5)),
      );
      expect(
        _rules(
          _in([
            ...naMeals(),
            _lunch(10, 8, ['fd_chicken'], hour: 14),
          ]),
        ),
        isNot(contains(SdRule.s5)),
      );
      // Not without meals on both days.
      expect(
        _rules(_in(naMeals(), today: _day(10, 10))),
        isNot(contains(SdRule.s5)),
      );
    });
  });

  group('S6 next new food', () {
    final quiet = [
      _lunch(9, 28, ['fd_rice']),
      _lunch(9, 29, ['fd_pumpkin']),
      _lunch(9, 30, ['fd_carrot']),
      _lunch(10, 1, ['fd_avocado']),
      _lunch(10, 2, ['fd_banana']),
      _lunch(10, 5, ['fd_apple']),
      _lunch(10, 6, ['fd_rice']),
      _lunch(10, 7, ['fd_rice']),
    ];

    test('no new food in 2 days: the group with the fewest tries', () {
      final c = _card(_in(quiet), SdRule.s6)!;
      expect(c.foodIds, ['fd_chicken', 'fd_peas', 'fd_potato']);
      expect(c.group, SdGroup.animalProtein);
      expect(c.count, 0);
      expect(c.foodIds, isNot(contains('fd_peanut')));
      // A new food yesterday: not yet.
      expect(
        _rules(
          _in([
            ...quiet,
            _lunch(10, 7, ['fd_pear'], hour: 17),
          ]),
        ),
        isNot(contains(SdRule.s6)),
      );
    });

    test('vegetables before fruit early on, then the counts decide', () {
      final tried = [
        _lunch(9, 28, ['fd_rice', 'fd_potato', 'fd_sweet_potato']),
        _lunch(9, 29, ['fd_pumpkin', 'fd_carrot']),
        _lunch(9, 30, ['fd_avocado']),
        _lunch(10, 1, ['fd_chicken', 'fd_peas']),
        _lunch(10, 6, ['fd_rice']),
      ];
      expect(_card(_in(tried, today: _day(10, 9)), SdRule.s6)!.foodIds, [
        'fd_broccoli',
        'fd_katuk',
        'fd_zucchini',
      ]);
      final late = _card(
        _in(
          tried,
          today: _day(10, 9),
          settings: SdSettings(enabled: true, startedOn: _day(9, 1)),
        ),
        SdRule.s6,
      )!;
      expect(late.group, SdGroup.fruit);
      expect(late.foodIds, ['fd_apple', 'fd_banana', 'fd_papaya']);
    });
  });

  group('S7 retry a "Chưa hợp"', () {
    test('3 days after, with a food the baby likes', () {
      expect(_rules(_in(naMeals())), isNot(contains(SdRule.s7)));
      final c = _card(_in(naMeals(), today: _day(10, 9)), SdRule.s7)!;
      expect(c.foodIds, ['fd_carrot']);
      expect(c.likedFoodId, 'fd_rice');
      expect(c.count, 1);
      expect(c.prefill, ['fd_carrot', 'fd_rice']);
      expect(c.key, 's7:fd_carrot');
    });

    test('not after 10 tries, with signs, or snoozed', () {
      final ten = [
        for (var d = 1; d <= 10; d++)
          _lunch(9, 10 + d, ['fd_carrot'], reaction: SdReaction.notYet),
        ...naMeals(),
      ];
      expect(_rules(_in(ten, today: _day(10, 9))), isNot(contains(SdRule.s7)));
      final signs = [
        ...naMeals(),
        _lunch(10, 6, ['fd_carrot'], symptoms: [SdSymptom.rash], hour: 18),
      ];
      expect(
        _rules(_in(signs, today: _day(10, 12))),
        isNot(contains(SdRule.s7)),
      );
      expect(
        _rules(_in(naMeals(), today: _day(10, 9), snoozed: {'s7:fd_carrot'})),
        isNot(contains(SdRule.s7)),
      );
    });
  });

  group('S8 variety and S9 texture', () {
    test('a known group not offered in 7 days', () {
      final i = _in(
        naMeals(),
        today: _day(10, 13),
        snoozed: {'s3:egg', 's6', 's7:fd_carrot'},
      );
      final c = _card(i, SdRule.s8)!;
      expect(c.group, SdGroup.legumeNut);
      expect(c.date, _day(10, 6));
      expect(c.foodIds, ['fd_peas']);
      expect(c.action, SdCardAction.viewIdeas);
      expect(
        _rules(
          _in(
            naMeals(),
            today: _day(10, 12),
            snoozed: {'s3:egg', 's6', 's7:fd_carrot'},
          ),
        ),
        isNot(contains(SdRule.s8)),
      );
    });

    test('S9 on the day a new stage is first opened', () {
      final c = _card(_in(naMeals(), stage: 'nst_9_11'), SdRule.s9)!;
      expect(c.stageId, 'nst_9_11');
      expect(c.action, SdCardAction.readTextures);
      final first = sdStageVisit(null, 'nst_6_8', _day(10, 8));
      expect(first.fresh, isFalse);
      expect(sdStageStep(first, 'nst_6_8', _day(10, 8)), isFalse);
      expect(sdStageVisit(first, 'nst_6_8', _day(10, 9)), first);
      final next = sdStageVisit(first, 'nst_9_11', _day(12, 1));
      expect(next.fresh, isTrue);
      expect(sdStageStep(next, 'nst_9_11', _day(12, 1)), isTrue);
      expect(sdStageStep(next, 'nst_9_11', _day(12, 2)), isFalse);
    });

    test('snoozes end after their days', () {
      final until = {'s5': _day(10, 11)};
      expect(sdActiveSnoozes(until, _day(10, 10)), {'s5'});
      expect(sdActiveSnoozes(until, _day(10, 11)), isEmpty);
    });
  });

  group('"Dành cho {bé}" (plan §7 Recipes)', () {
    Map<String, SdTried> tried(List<SdMeal> meals) => {
      for (final t in sdTriedFoods(meals, _foods())) t.key: t,
    };
    List<String> ids(
      List<SdMeal> meals, {
      int months = 7,
      SdSettings? settings,
      Set<String> suggested = const {},
    }) => [
      for (final r in sdRecipesFor(
        recipes: fixtureRecipes(),
        months: months,
        settings: settings ?? naSettings(),
        foods: _foods(),
        tried: tried(meals),
        suggested: suggested,
      ))
        r.id,
    ];

    test('age, method, at most one untried, liked first, then newest', () {
      expect(ids(naMeals()), [
        'rcp_chao_trung',
        'rcp_chao_bi_do',
        'rcp_ga_khoai',
      ]);
      expect(
        ids(naMeals(), settings: naSettings().copyWith(method: SdMethod.blw)),
        ['rcp_ga_khoai'],
      );
      expect(ids(naMeals(), months: 9), ['rcp_banh_chuoi']);
    });

    test('a suggestion\'s foods: one of them, the only untried', () {
      expect(ids(naMeals(), suggested: {'fd_chicken'}), ['rcp_ga_khoai']);
      expect(ids(naMeals(), suggested: {'fd_egg'}), ['rcp_chao_trung']);
    });

    test('no hidden food, no food with signs unless cleared', () {
      expect(ids(naMeals(), settings: naSettings(hidden: ['fd_pumpkin'])), [
        'rcp_ga_khoai',
      ]);
      final signs = [
        ...naMeals(),
        _lunch(10, 8, ['fd_chicken'], symptoms: [SdSymptom.vomit], hour: 14),
      ];
      expect(ids(signs), isNot(contains('rcp_ga_khoai')));
      expect(
        ids(signs, settings: naSettings(cleared: ['fd_chicken'])),
        contains('rcp_ga_khoai'),
      );
    });
  });

  group('recipes (contentRecipeSchema, recipeAllergens)', () {
    test('published recipes parse; allergens come from the foods', () {
      final r = {for (final r in fixtureRecipes()) r.id: r};
      final egg = r['rcp_chao_trung']!;
      expect(egg.totalMinutes, 15);
      expect(egg.foodIds, ['fd_rice', 'fd_pumpkin', 'fd_egg']);
      expect(egg.methods, {SdRecipeMethod.spoon});
      expect(egg.ingredients.last.foodId, isNull);
      expect(sdRecipeAllergens(egg, _foods()), [SdAllergen.egg]);
      expect(sdRecipeAllergens(r['rcp_chao_bi_do']!, _foods()), isEmpty);
      expect(r['rcp_ga_khoai']!.illustrative, isFalse);
      expect(
        SdRecipe.fromDoc('rcp_x', {...recipeDocs.first, 'status': 'draft'}),
        isNull,
      );
      expect(SdRecipe.fromDoc('recipe_x', recipeDocs.first), isNull);
    });

    test('quantities and the allergen line', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final r = {for (final r in fixtureRecipes()) r.id: r};
      final qty = [
        for (final i in r['rcp_chao_trung']!.ingredients)
          sdIngredientQty(l10n, 'vi', i),
      ];
      expect(qty, ['30 g', '60 g', '1 miếng', '1 thìa cà phê']);
      expect(
        sdIngredientQty(l10n, 'vi', r['rcp_ga_khoai']!.ingredients.last),
        '0,5 chén',
      );
      expect(
        sdIngredientQty(en, 'en', r['rcp_chao_trung']!.ingredients[2]),
        '1 piece',
      );
      expect(sdContainsLine(l10n, [SdAllergen.egg]), 'Có trứng');
      expect(
        sdContainsLine(en, [SdAllergen.egg, SdAllergen.peanut]),
        'Contains egg, peanut',
      );
      expect(
        sdOrList(l10n, ['Bí đỏ', 'Khoai lang', 'Thịt gà']),
        'Bí đỏ, Khoai lang hoặc Thịt gà',
      );
    });

    test('5f: band, method, type and search on titles and ingredients', () {
      final recipes = fixtureRecipes();
      List<String> ids(SdLibraryFilter f) => [
        for (final r in f.applyRecipes(recipes, foods: _foods())) r.id,
      ];
      const band = SdLibraryFilter(band: SdBand.m6to8);
      expect(ids(band), [
        'rcp_trung_ga',
        'rcp_chao_trung',
        'rcp_ga_khoai',
        'rcp_chao_bi_do',
      ]);
      expect(ids(band.copyWith(method: SdRecipeMethod.blw)), ['rcp_ga_khoai']);
      expect(ids(band.copyWith(type: SdLibraryType.guides)), isEmpty);
      expect(ids(band.copyWith(format: LbFormat.article)), isEmpty);
      // "bí ngô" is a synonym of Bí đỏ; "trứng" matches titles before ingredients.
      expect(ids(band.copyWith(query: 'bí ngô')), [
        'rcp_chao_trung',
        'rcp_chao_bi_do',
      ]);
      expect(ids(const SdLibraryFilter(query: 'trứng')), [
        'rcp_trung_ga',
        'rcp_chao_trung',
        'rcp_banh_chuoi',
      ]);
    });
  });
}
