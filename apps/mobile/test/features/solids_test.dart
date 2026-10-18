import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/nutrition/nutrition_calc.dart';
import 'package:child_life/features/solids/solids_calc.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/solids_fixtures.dart';

/// Ăn dặm rules (D-085, plan §3–§5, §10), mirroring `packages/contracts/src/solids.ts`.

const _zone = 'Asia/Ho_Chi_Minh';

Map<String, SdFood> _foods() => {for (final f in fixtureFoods()) f.id: f};

void main() {
  group('age (P-164 #2, owner D-085 #4)', () {
    test('solidsAgeState: from 6 months; "soon" from 4', () {
      expect(sdAgeState(0), SdAgeState.tooYoung);
      expect(sdAgeState(3), SdAgeState.tooYoung);
      expect(sdAgeState(4), SdAgeState.soon);
      expect(sdAgeState(5), SdAgeState.soon);
      expect(sdAgeState(6), SdAgeState.ready);
      expect(sdAgeState(30), SdAgeState.ready);
    });

    test('the 6-month day agrees with nuMonthsOld, short months included', () {
      expect(sdSixMonthDay(naBorn), DateTime(2026, 9, 1));
      for (final dob in [
        DateTime(2026, 1, 31),
        DateTime(2025, 8, 31),
        DateTime(2026, 3, 30),
        DateTime(2024, 2, 29),
      ]) {
        for (var m = 1; m <= 12; m++) {
          final day = sdMonthDay(dob, m);
          expect(nuMonthsOld(dob, day), m, reason: '$dob +$m → $day');
          expect(
            nuMonthsOld(dob, day.subtract(const Duration(days: 1))),
            m - 1,
            reason: 'the day before $day',
          );
        }
      }
    });

    test('QA #1: born 01/07, the reminder is at 5 months 2 weeks', () {
      expect(
        sdReminderDay(DateTime(2026, 7, 1), DateTime(2026, 10, 8)),
        DateTime(2026, 12, 15),
      );
      // QA #2: at 5 months 20 days that day has passed: the 6-month day instead.
      final dob = DateTime(2026, 4, 18);
      expect(nuMonthsOld(dob, DateTime(2026, 10, 8)), 5);
      expect(sdReminderDay(dob, DateTime(2026, 10, 8)), DateTime(2026, 10, 18));
      // From 6 months, no reminder.
      expect(
        sdReminderDay(DateTime(2026, 4, 8), DateTime(2026, 10, 8)),
        isNull,
      );
    });
  });

  test('slotForTime: Sáng 5–10 · Trưa 10–14 · Chiều 14–17 · Tối 17–21', () {
    final slots = {for (var h = 0; h < 24; h++) h: sdSlotForTime(h)};
    expect(slots[4], SdSlot.snack);
    expect(slots[5], SdSlot.morning);
    expect(slots[9], SdSlot.morning);
    expect(slots[10], SdSlot.noon);
    expect(slots[13], SdSlot.noon);
    expect(slots[14], SdSlot.afternoon);
    expect(slots[16], SdSlot.afternoon);
    expect(slots[17], SdSlot.evening);
    expect(slots[20], SdSlot.evening);
    expect(slots[21], SdSlot.snack);
  });

  group('foods tried (P-164 #7)', () {
    test('Na: 14 foods, counts, first dates and groups agree', () {
      final tried = sdTriedFoods(naMeals(), _foods());
      expect(tried, hasLength(14));
      // Newest first try first: Khoai lang today.
      expect(tried.first.key, 'fd_sweet_potato');
      expect(tried.last.key, 'fd_rice');
      final rice = tried.last;
      expect(rice.times, 8);
      expect(sdDayOf(_zone, rice.firstAt), DateTime(2026, 9, 28));
      expect(tried.firstWhere((t) => t.key == 'fd_pumpkin').times, 7);
      expect(sdGroupCounts(tried), {
        SdGroup.grain: 3,
        SdGroup.vegetable: 5,
        SdGroup.legumeNut: 1,
        SdGroup.fruit: 5,
      });
      expect(
        tried.map((t) => t.name(const Locale('vi'))),
        contains('Bông cải xanh'),
      );
    });

    test('the latest reaction is the last meal that has one (Q3)', () {
      final carrot = sdTriedFoods(
        naMeals(),
        _foods(),
      ).firstWhere((t) => t.key == 'fd_carrot');
      expect(carrot.latestReaction, SdReaction.notYet);
      final later = [
        ...naMeals(),
        meal(vn(8, 14, 0), foods: ['fd_carrot'], reaction: SdReaction.liked),
        // No reaction: the liked one stays the latest.
        meal(vn(8, 15, 0), foods: ['fd_carrot']),
      ];
      final again = sdTriedFoods(
        later,
        _foods(),
      ).firstWhere((t) => t.key == 'fd_carrot');
      expect(again.latestReaction, SdReaction.liked);
      expect(again.times, 3);
    });

    test('QA #3: Gạo, Cà rốt, Thịt gà → only Thịt gà is a first try; 15', () {
      final meals = naMeals();
      final next = meal(
        vn(8, 16, 20),
        foods: ['fd_rice', 'fd_carrot', 'fd_chicken'],
        dish: 'Cháo cà rốt thịt gà',
      );
      expect(sdFirstTryIds(next, meals), {'fd_chicken'});
      final all = [...meals, next];
      expect(sdTriedFoods(all, _foods()), hasLength(15));
      final today = sdDaySummary(all, _zone, DateTime(2026, 10, 8));
      expect(today.count, 3);
      expect(today.latest?.dish, 'Cháo cà rốt thịt gà');
      expect(today.firstTries, ['fd_sweet_potato', 'fd_chicken']);
      // An earlier meal is never a first try of what it already had before.
      expect(sdFirstTryIds(meals[13], meals), isEmpty);
      expect(sdFirstTryIds(meals[14], meals), {'fd_sweet_potato'});
    });

    test('QA #4: symptoms mark the foods new in that meal', () {
      final next = meal(
        vn(8, 16, 20),
        foods: ['fd_rice', 'fd_carrot', 'fd_chicken'],
        symptoms: [SdSymptom.breathing],
      );
      final tried = {
        for (final t in sdTriedFoods([...naMeals(), next], _foods())) t.key: t,
      };
      expect(tried['fd_chicken']!.flagged, isTrue);
      expect(tried['fd_rice']!.flagged, isFalse);
      expect(tried['fd_carrot']!.flagged, isFalse);
      // Signs after a meal of known foods only: all of them are marked.
      final known = meal(
        vn(8, 16, 30),
        foods: ['fd_avocado', 'fd_banana'],
        symptoms: [SdSymptom.rash],
      );
      final again = {
        for (final t in sdTriedFoods([...naMeals(), known], _foods())) t.key: t,
      };
      expect(again['fd_avocado']!.flagged, isTrue);
      expect(again['fd_banana']!.flagged, isTrue);
      expect(again['fd_rice']!.flagged, isFalse);
      expect(SdSymptom.values.where((s) => s.urgent), [
        SdSymptom.swelling,
        SdSymptom.breathing,
      ]);
    });

    test('free names: one food per folded name, group Khác, never ✦', () {
      final meals = [
        meal(vn(7, 11, 0), free: ['Bí ngòi xào ']),
        meal(vn(8, 11, 0), free: ['bí ngòi xào'], foods: ['fd_egg']),
      ];
      final tried = sdTriedFoods(meals, _foods());
      expect(tried, hasLength(2));
      final free = tried.firstWhere((t) => t.foodId == null);
      expect(free.key, 'x_bi_ngoi_xao');
      expect(free.group, isNull);
      expect(free.times, 2);
      expect(free.name(const Locale('vi')), 'Bí ngòi xào');
      expect(sdFirstTryIds(meals[1], meals), {'fd_egg'});
      // Deleted meals do not count.
      expect(
        sdTriedFoods([
          SdMeal.fromJson(meals[0].id, {
            ...meals[0].toCreateJson(),
            'occurredAt': meals[0].occurredAt,
            'deleted': true,
          })!,
        ], _foods()),
        isEmpty,
      );
    });

    test('days: 5b dots, the day in time order, the start date', () {
      final meals = naMeals();
      expect(sdMealDays(meals, _zone), hasLength(11));
      final day = sdMealsOn(meals, _zone, DateTime(2026, 10, 8));
      expect(day.map((m) => m.dish), ['Cháo bí đỏ', 'Khoai lang nghiền']);
      expect(sdWeekStart(DateTime(2026, 10, 8)), DateTime(2026, 10, 5));
      expect(sdWeekStart(DateTime(2026, 10, 11)), DateTime(2026, 10, 5));
      expect(sdStartedOn(SdSettings.off, meals, _zone), DateTime(2026, 9, 28));
      expect(
        sdStartedOn(
          naSettings().copyWith(startedOn: DateTime(2026, 9, 20)),
          meals,
          _zone,
        ),
        DateTime(2026, 9, 20),
      );
    });
  });

  test('roles (P-164 #13)', () {
    final parentsMeal = naMeals().first;
    final lansMeal = naMeals().last;
    expect(mai.sdManages && mai.sdLogs && mai.sdReads, isTrue);
    expect(mai.sdEdits(lansMeal), isTrue);
    expect(lan.sdManages, isFalse);
    expect(lan.sdLogs && lan.sdReads, isTrue);
    expect(lan.sdEdits(lansMeal), isTrue);
    expect(lan.sdEdits(parentsMeal), isFalse);
    // A relative reads only with daily-care rights, and never logs.
    expect(hoa.sdReads || hoa.sdLogs, isFalse);
    final reader = member(
      'u_ba',
      'Bà ngoại',
      MemberRole.relative,
      Relation.grandmother,
      extra: const ExtraRights(viewDailyCare: true),
    );
    expect(reader.sdReads, isTrue);
    expect(reader.sdLogs || reader.sdEdits(lansMeal), isFalse);
  });

  group('documents (mealSchema, solidsSettingsSchema)', () {
    test('a new meal has exactly the contract keys', () {
      final m = SdMeal.create(
        id: newMealId(),
        me: lan,
        occurredAt: vn(8, 16, 20),
        slot: SdSlot.afternoon,
        dish: '  Cháo cà rốt thịt gà ',
        foodIds: ['fd_rice', 'fd_chicken'],
        freeFoods: [' Nước hầm xương '],
        amount: const SdAmount.preset(SdAmountPreset.halfBowl),
        reaction: SdReaction.liked,
        symptoms: [SdSymptom.rash],
      );
      expect(sdMealId(m.id), isTrue);
      final j = m.toCreateJson();
      expect(j.keys.toSet(), {
        'id',
        'babyId',
        'occurredAt',
        'slot',
        'dish',
        'foodIds',
        'freeFoods',
        'amount',
        'reaction',
        'symptoms',
        'note',
        'recipeId',
        'photoPath',
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
      expect(j['dish'], 'Cháo cà rốt thịt gà');
      expect(j['freeFoods'], ['Nước hầm xương']);
      expect(j['amount'], {'preset': 'halfBowl'});
      expect(j['symptoms'], ['rash']);
      expect(j['createdBy'], 'u_lan');
      expect(j['updatedBy'], 'u_lan');
      expect(j['author'], {
        'name': 'Cô Lan',
        'relation': 'nanny',
        'relationCustom': null,
      });
      expect(j['deleted'], isFalse);
      expect(m.toEditJson('u_mai').keys.toSet(), {
        'occurredAt',
        'slot',
        'dish',
        'foodIds',
        'freeFoods',
        'amount',
        'reaction',
        'symptoms',
        'note',
        'recipeId',
        'photoPath',
        'updatedAt',
        'updatedBy',
      });
      expect(const SdAmount.custom(4, SdUnit.spoon).toJson(), {
        'value': 4,
        'unit': 'spoon',
      });
    });

    test('meals read back; bad ids and shapes are skipped', () {
      final m = naMeals()[9];
      final back = SdMeal.fromJson(m.id, {
        ...m.toCreateJson(),
        'occurredAt': m.occurredAt,
      })!;
      expect(back.foodIds, ['fd_carrot']);
      expect(back.amount, const SdAmount.preset(SdAmountPreset.fewSpoons));
      expect(back.reaction, SdReaction.notYet);
      expect(back.author.name, 'Mai');
      expect(SdMeal.fromJson('r_123', {'occurredAt': m.occurredAt}), isNull);
      expect(
        SdMeal.fromJson(m.id, {'occurredAt': m.occurredAt, 'slot': 'brunch'}),
        isNull,
      );
      final odd = SdMeal.fromJson(m.id, {
        'occurredAt': m.occurredAt,
        'slot': 'snack',
        'foodIds': ['fd_ok', 'nope', 3],
        'symptoms': ['rash', 'sneeze'],
        'amount': {'value': -1, 'unit': 'g'},
      })!;
      expect(odd.foodIds, ['fd_ok']);
      expect(odd.symptoms, [SdSymptom.rash]);
      expect(odd.amount, isNull);
    });

    test('settings: the whole strict document', () {
      final j = naSettings(hidden: ['fd_honey']).toJson('u_mai');
      expect(j.keys.toSet(), {
        'enabled',
        'startedOn',
        'showOnToday',
        'method',
        'hidden',
        'cleared',
        'updatedAt',
        'updatedBy',
      });
      expect(j['startedOn'], '2026-09-28');
      expect(j['method'], 'mixed');
      final back = SdSettings.fromJson({
        ...j,
        'hidden': ['fd_honey', 'bad id'],
      })!;
      expect(back.hidden, ['fd_honey']);
      expect(back.startedOn, DateTime(2026, 9, 28));
      expect(SdSettings.fromJson(null), isNull);
      expect(SdSettings.off.enabled, isFalse);
      expect(SdSettings.off.showOnToday, isTrue);
      expect(SdSettings.off.method, SdMethod.mixed);
    });

    test('published foods only', () {
      final egg = _foods()['fd_egg']!;
      expect(egg.allergen, SdAllergen.egg);
      expect(egg.ironRich, isTrue);
      expect(_foods()['fd_honey']!.minAgeMonths, 12);
      expect(
        SdFood.fromDoc('fd_x', {...foodDocs.first, 'status': 'draft'}),
        isNull,
      );
      expect(SdFood.fromDoc('food_x', foodDocs.first), isNull);
    });
  });

  test('ingredient picker: synonyms, then liked and recent first', () {
    final foods = fixtureFoods();
    final tried = {for (final t in sdTriedFoods(naMeals(), _foods())) t.key: t};
    // "bí ngô" (a synonym of Bí đỏ) before the prefix match "Bí ngòi".
    expect(sdSearchFoods(foods, 'bí ngô', tried: tried).map((f) => f.id), [
      'fd_pumpkin',
      'fd_zucchini',
    ]);
    expect(sdSearchFoods(foods, 'thit', tried: tried).map((f) => f.id), [
      'fd_chicken',
    ]);
    final all = sdSearchFoods(
      foods,
      '',
      tried: tried,
    ).map((f) => f.id).toList();
    // Liked foods first (latest first), then tried, then the rest by priority.
    expect(all.first, 'fd_rice');
    expect(all.indexOf('fd_carrot'), lessThan(all.indexOf('fd_chicken')));
    expect(all.indexOf('fd_avocado'), lessThan(all.indexOf('fd_carrot')));
    expect(all.indexOf('fd_chicken'), lessThan(all.indexOf('fd_egg')));
  });

  group('5f library', () {
    test('the age band preset from the baby', () {
      expect(sdBandFor(null), isNull);
      expect(sdBandFor(2), SdBand.m4to5);
      expect(sdBandFor(5), SdBand.m4to5);
      expect(sdBandFor(7), SdBand.m6to8);
      expect(sdBandFor(11), SdBand.m9to11);
      expect(sdBandFor(18), SdBand.m12to23);
      expect(sdBandFor(36), SdBand.m24to36);
      expect(sdBandFor(37), isNull);
      expect(SdBand.m6to8.fromWeeks, 26);
      expect(SdBand.m6to8.toWeeks, 39);
    });

    test('solids guides only, by band and format, newest first', () {
      final articles = articlesWithSolids();
      List<String> ids(SdLibraryFilter f) => [
        for (final a in f.apply(articles)) a.id,
      ];
      expect(ids(const SdLibraryFilter()), [
        'art_solids_first_meals',
        'art_solids_family_meals',
        'art_solids_iron',
        'art_puree',
        'art_solids_readiness',
      ]);
      expect(ids(const SdLibraryFilter(band: SdBand.m6to8)), [
        'art_solids_first_meals',
        'art_solids_iron',
        'art_puree',
        'art_solids_readiness',
      ]);
      expect(ids(const SdLibraryFilter(band: SdBand.m12to23)), [
        'art_solids_family_meals',
        'art_solids_iron',
      ]);
      expect(ids(const SdLibraryFilter(format: LbFormat.quickQa)), [
        'art_solids_readiness',
      ]);
      expect(ids(const SdLibraryFilter(query: 'sat')), ['art_solids_iron']);
      expect(
        articles.firstWhere((a) => a.id == 'art_solids_first_meals').format,
        LbFormat.stepGuide,
      );
    });
  });
}
