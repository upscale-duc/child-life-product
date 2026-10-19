import 'dart:async';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/content_repository.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_repository.dart';
import 'package:child_life/features/first_aid/first_aid_models.dart';
import 'package:child_life/features/first_aid/first_aid_modes.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/vaccines/vaccine_photos.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'care_fixtures.dart';
import 'family_fixtures.dart';
import 'library_fixtures.dart';

/// Ăn dặm fixtures, TEST ONLY (plan §10 QA seeds): Na — here the fixture baby Teddy — born
/// 2026-03-01, viewed on Thursday 2026-10-08 15:05 in Hồ Chí Minh (7 months), method Kết hợp,
/// started 2026-09-28. Published foods in the `contentFoodSchema` shape parsed through the app's
/// own `fromDoc`; meals as the app writes them. Never shipped.

final naBorn = DateTime(2026, 3, 1);

Map<String, Object?> _l(String vi, String en) => {'vi': vi, 'en': en};

/// A published `contentFoods/{id}` document.
Map<String, Object?> foodDoc(
  String id,
  String vi,
  String en,
  String group, {
  String? allergen,
  bool ironRich = false,
  int minAgeMonths = 6,
  List<String> synonymsVi = const [],
  int priority = 50,
}) => {
  'id': id,
  'name': _l(vi, en),
  'synonyms': {'vi': synonymsVi, 'en': <String>[]},
  'group': group,
  'allergen': allergen,
  'ironRich': ironRich,
  'minAgeMonths': minAgeMonths,
  'prep': <Object?>[],
  'chokingNote': _l('', ''),
  'suggest': true,
  'priority': priority,
  'sources': <Object?>[],
  'status': 'published',
  'revision': 1,
  'review': null,
  'illustrative': true,
  'reviewDueOn': '2027-10-01',
  'publishedAt': '2026-10-01T03:00:00.000Z',
  'firstPublishedAt': '2026-10-01T03:00:00.000Z',
};

final foodDocs = [
  foodDoc('fd_rice', 'Gạo', 'Rice', 'grain', priority: 90),
  foodDoc(
    'fd_pumpkin',
    'Bí đỏ',
    'Pumpkin',
    'vegetable',
    synonymsVi: ['bí ngô'],
    priority: 80,
  ),
  foodDoc('fd_carrot', 'Cà rốt', 'Carrot', 'vegetable'),
  foodDoc('fd_sweet_potato', 'Khoai lang', 'Sweet potato', 'grain'),
  foodDoc('fd_potato', 'Khoai tây', 'Potato', 'grain'),
  foodDoc('fd_zucchini', 'Bí ngòi', 'Zucchini', 'vegetable'),
  foodDoc('fd_katuk', 'Rau ngót', 'Katuk', 'vegetable'),
  foodDoc('fd_broccoli', 'Bông cải xanh', 'Broccoli', 'vegetable'),
  foodDoc('fd_peas', 'Đậu Hà Lan', 'Peas', 'legumeNut'),
  foodDoc('fd_avocado', 'Bơ', 'Avocado', 'fruit'),
  foodDoc('fd_banana', 'Chuối', 'Banana', 'fruit'),
  foodDoc('fd_apple', 'Táo', 'Apple', 'fruit'),
  foodDoc('fd_pear', 'Lê', 'Pear', 'fruit'),
  foodDoc('fd_papaya', 'Đu đủ', 'Papaya', 'fruit'),
  foodDoc(
    'fd_chicken',
    'Thịt gà',
    'Chicken',
    'animalProtein',
    ironRich: true,
    priority: 70,
  ),
  foodDoc(
    'fd_egg',
    'Trứng gà',
    'Egg',
    'animalProtein',
    allergen: 'egg',
    ironRich: true,
  ),
  foodDoc('fd_honey', 'Mật ong', 'Honey', 'fat', minAgeMonths: 12),
  foodDoc(
    'fd_peanut',
    'Đậu phộng',
    'Peanut',
    'legumeNut',
    allergen: 'peanut',
    synonymsVi: ['lạc'],
  ),
];

List<SdFood> fixtureFoods() => [
  for (final d in foodDocs) SdFood.fromDoc(d['id']! as String, d)!,
];

/// A recipe ingredient (`{ foodId, name, qty, unit, note }`).
Map<String, Object?> ing(
  String? foodId,
  String vi,
  String en, [
  num? qty,
  String? unit,
]) => {
  'foodId': foodId,
  'name': _l(vi, en),
  'qty': qty,
  'unit': unit,
  'note': _l('', ''),
};

/// A published `contentRecipes/{id}` document (`contentRecipeSchema`).
Map<String, Object?> recipeDoc(
  String id,
  String vi,
  String en, {
  required List<Map<String, Object?>> ingredients,
  int from = 6,
  int to = 9,
  String texture = 'smooth',
  List<String> methods = const ['spoon'],
  int prep = 5,
  int cook = 10,
  String publishedAt = '2026-09-20T03:00:00.000Z',
  Map<String, Object?>? review,
  List<String> related = const [],
}) => {
  'id': id,
  'title': _l(vi, en),
  'summary': _l('Món mềm, dễ ăn cho bé.', 'A soft, easy dish for baby.'),
  'cover': null,
  'ageMonths': {'from': from, 'to': to},
  'texture': texture,
  'methods': methods,
  'servings': 2,
  'prepMinutes': prep,
  'cookMinutes': cook,
  'ingredients': ingredients,
  'steps': {
    'vi': ['Nấu chín mềm.', 'Nghiền mịn, để nguội bớt.'],
    'en': ['Cook until soft.', 'Mash smooth and let it cool a little.'],
  },
  'storage': _l(
    'Cất tủ lạnh, dùng trong 24 giờ.',
    'Refrigerate and use within 24 hours.',
  ),
  'tip': _l(
    'Bé mới ăn vài thìa là bình thường.',
    'A few spoonfuls is normal at first.',
  ),
  'relatedArticleIds': related,
  'sources': [
    {'label': 'WHO 2023', 'url': 'https://www.who.int/'},
  ],
  'status': 'published',
  'revision': 1,
  'review': review,
  'illustrative': review == null,
  'reviewDueOn': '2027-10-01',
  'publishedAt': publishedAt,
  'firstPublishedAt': publishedAt,
};

/// Recipes for Na (7 months, Kết hợp): two with only foods she knows, one with a new egg, one
/// with a new chicken, one with both (two untried) and one from 9 months.
final recipeDocs = [
  recipeDoc(
    'rcp_chao_bi_do',
    'Cháo bí đỏ cho bé mới tập',
    'Pumpkin congee for beginners',
    ingredients: [
      ing('fd_rice', 'Gạo tẻ', 'Rice', 30, 'g'),
      ing('fd_pumpkin', 'Bí đỏ', 'Pumpkin', 60, 'g'),
      ing(null, 'Nước', 'Water', 400, 'ml'),
    ],
    related: ['art_solids_first_meals'],
  ),
  recipeDoc(
    'rcp_chao_trung',
    'Cháo bí đỏ trứng',
    'Pumpkin congee with egg',
    ingredients: [
      ing('fd_rice', 'Gạo tẻ', 'Rice', 30, 'g'),
      ing('fd_pumpkin', 'Bí đỏ', 'Pumpkin', 60, 'g'),
      ing('fd_egg', 'Lòng đỏ trứng', 'Egg yolk', 1, 'piece'),
      ing(null, 'Dầu ăn', 'Oil', 1, 'tsp'),
    ],
    publishedAt: '2026-10-01T03:00:00.000Z',
  ),
  recipeDoc(
    'rcp_ga_khoai',
    'Cháo gà khoai lang',
    'Chicken and sweet potato congee',
    texture: 'mashed',
    methods: ['spoon', 'blw'],
    prep: 10,
    cook: 30,
    ingredients: [
      ing('fd_rice', 'Gạo tẻ', 'Rice', 30, 'g'),
      ing('fd_chicken', 'Thịt gà', 'Chicken', 40, 'g'),
      ing('fd_sweet_potato', 'Khoai lang', 'Sweet potato', 0.5, 'bowl'),
    ],
    publishedAt: '2026-09-25T03:00:00.000Z',
    review: {
      'reviewer': 'ThS. Lê Thu',
      'credential': 'Dinh dưỡng',
      'reviewedOn': '2026-09-15',
    },
  ),
  recipeDoc(
    'rcp_trung_ga',
    'Trứng hấp thịt gà',
    'Steamed egg with chicken',
    ingredients: [
      ing('fd_egg', 'Trứng gà', 'Egg', 1, 'piece'),
      ing('fd_chicken', 'Thịt gà', 'Chicken', 30, 'g'),
    ],
    publishedAt: '2026-10-05T03:00:00.000Z',
  ),
  recipeDoc(
    'rcp_banh_chuoi',
    'Bánh chuối mềm cầm tay',
    'Soft banana finger cakes',
    from: 9,
    to: 13,
    texture: 'finger',
    methods: ['blw'],
    ingredients: [
      ing('fd_banana', 'Chuối', 'Banana', 1, 'piece'),
      ing('fd_egg', 'Trứng gà', 'Egg', 1, 'piece'),
    ],
    publishedAt: '2026-10-06T03:00:00.000Z',
  ),
];

List<SdRecipe> fixtureRecipes() => [
  for (final d in recipeDocs) SdRecipe.fromDoc(d['id']! as String, d)!,
];

var _seq = 0;

/// A meal at [at] by [by] (default Mai), as the app writes it.
SdMeal meal(
  DateTime at, {
  List<String> foods = const [],
  List<String> free = const [],
  String dish = '',
  SdSlot? slot,
  SdAmount? amount,
  SdReaction? reaction,
  List<SdSymptom> symptoms = const [],
  Membership? by,
  bool pending = false,
  String? recipeId,
}) {
  final who = by ?? mai;
  return SdMeal(
    id: 'm_${(++_seq).toRadixString(16).padLeft(32, '0')}',
    babyId: teddyId,
    occurredAt: at,
    slot: slot ?? SdSlot.noon,
    dish: dish,
    foodIds: foods,
    freeFoods: free,
    amount: amount,
    reaction: reaction,
    symptoms: symptoms,
    recipeId: recipeId,
    createdBy: who.uid,
    author: CareAuthor.of(who),
    createdAt: pending ? null : at.add(const Duration(minutes: 1)),
    clientCreatedAt: at.add(const Duration(minutes: 1)),
    pending: pending,
  );
}

/// A time in Hồ Chí Minh (GMT+7) on [month]/[day] 2026.
DateTime vnOn(int month, int day, int hour, int minute) =>
    DateTime.utc(2026, month, day, hour - 7, minute).toLocal();

/// Na's diary from 28/09 to today (08/10, 15:05): 14 foods tried, Gạo first, Khoai lang new
/// today; no chicken yet (QA seed #3).
List<SdMeal> naMeals() => [
  meal(
    vnOn(9, 28, 11, 0),
    foods: ['fd_rice'],
    dish: 'Cháo gạo',
    reaction: SdReaction.liked,
  ),
  meal(vnOn(9, 29, 11, 0), foods: ['fd_rice'], reaction: SdReaction.liked),
  meal(vnOn(9, 30, 11, 0), foods: ['fd_rice', 'fd_potato']),
  meal(
    vnOn(10, 1, 11, 0),
    foods: ['fd_rice', 'fd_pumpkin'],
    dish: 'Cháo bí đỏ',
    reaction: SdReaction.liked,
  ),
  meal(vnOn(10, 2, 11, 0), foods: ['fd_pumpkin', 'fd_zucchini']),
  meal(vnOn(10, 3, 10, 30), foods: ['fd_rice', 'fd_pumpkin', 'fd_katuk']),
  meal(vnOn(10, 4, 11, 0), foods: ['fd_pumpkin', 'fd_papaya']),
  meal(
    vnOn(10, 5, 8, 0),
    foods: ['fd_rice', 'fd_pumpkin'],
    slot: SdSlot.morning,
  ),
  meal(
    vnOn(10, 5, 15, 0),
    foods: ['fd_apple', 'fd_pear'],
    dish: 'Táo lê hấp',
    slot: SdSlot.afternoon,
  ),
  meal(
    vnOn(10, 6, 11, 0),
    foods: ['fd_carrot'],
    dish: 'Cà rốt hấp nghiền',
    amount: const SdAmount.preset(SdAmountPreset.fewSpoons),
    reaction: SdReaction.notYet,
  ),
  meal(
    vnOn(10, 6, 16, 0),
    foods: ['fd_broccoli', 'fd_peas'],
    slot: SdSlot.afternoon,
  ),
  meal(
    vnOn(10, 7, 8, 0),
    foods: ['fd_rice', 'fd_pumpkin'],
    dish: 'Cháo bí đỏ',
    slot: SdSlot.morning,
    amount: const SdAmount.custom(3, SdUnit.spoon),
    reaction: SdReaction.neutral,
  ),
  meal(
    vnOn(10, 7, 11, 15),
    foods: ['fd_avocado', 'fd_banana'],
    dish: 'Bơ nghiền chuối',
    amount: const SdAmount.preset(SdAmountPreset.fewSpoons),
    reaction: SdReaction.liked,
  ),
  meal(
    vn(8, 8, 10),
    foods: ['fd_rice', 'fd_pumpkin'],
    dish: 'Cháo bí đỏ',
    slot: SdSlot.morning,
    amount: const SdAmount.custom(4, SdUnit.spoon),
    reaction: SdReaction.liked,
  ),
  meal(
    vn(8, 11, 30),
    foods: ['fd_sweet_potato'],
    dish: 'Khoai lang nghiền',
    amount: const SdAmount.preset(SdAmountPreset.halfBowl),
    reaction: SdReaction.neutral,
    by: lan,
  ),
];

/// Tracking on since 28/09, Kết hợp, shown on Hôm nay.
SdSettings naSettings({
  bool enabled = true,
  bool showOnToday = true,
  List<String> hidden = const [],
  List<String> cleared = const [],
}) => SdSettings(
  enabled: enabled,
  startedOn: DateTime(2026, 9, 28),
  showOnToday: showOnToday,
  hidden: hidden,
  cleared: cleared,
  updatedBy: mai.uid,
);

var _familySeq = 0;

/// A family recipe ("Công thức nhà mình", D-086) by [by] (default Mai), as the app writes it.
SdFamilyRecipe familyRecipe(
  String title, {
  List<SdFamilyIngredient>? ingredients,
  List<String> steps = const ['Nấu chín mềm.', 'Nghiền mịn.'],
  String note = '',
  String? photoPath,
  Membership? by,
  DateTime? createdAt,
  String? id,
}) {
  final who = by ?? mai;
  final at = createdAt ?? vnOn(10, 1, 9, 0);
  return SdFamilyRecipe(
    id: id ?? 'fr_${(++_familySeq).toRadixString(16).padLeft(32, '0')}',
    babyId: teddyId,
    title: title,
    ingredients:
        ingredients ??
        const [
          SdFamilyIngredient(
            foodId: 'fd_rice',
            name: 'Gạo',
            qty: 30,
            unit: SdIngredientUnit.g,
          ),
          SdFamilyIngredient(
            foodId: 'fd_pumpkin',
            name: 'Bí đỏ',
            qty: 50,
            unit: SdIngredientUnit.g,
          ),
        ],
    steps: steps,
    note: note,
    photoPath: photoPath,
    createdBy: who.uid,
    author: CareAuthor.of(who),
    createdAt: at,
    clientCreatedAt: at,
    updatedAt: at,
  );
}

/// An in-memory store: writes land in [meals] / [settings] / [family] and the streams update, as
/// the Firestore cache does on the device.
class FakeSolidsStore extends SolidsStore {
  FakeSolidsStore({
    List<SdMeal>? meals,
    this.settings,
    List<SdFood>? foods,
    List<SdFamilyRecipe>? family,
  }) : meals = [...?meals],
       family = [...?family],
       foods = foods ?? fixtureFoods(),
       super(() => throw UnimplementedError());

  final List<SdMeal> meals;
  SdSettings? settings;
  final List<SdFood> foods;

  /// "Công thức nhà mình" (D-086).
  final List<SdFamilyRecipe> family;
  final calls = <String>[];
  final _mealsNow = StreamController<List<SdMeal>>.broadcast();
  final _settingsNow = StreamController<SdSettings?>.broadcast();
  final _familyNow = StreamController<List<SdFamilyRecipe>>.broadcast();

  List<SdFamilyRecipe> get _liveFamily => [
    for (final r in family)
      if (!r.deleted) r,
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Stream<List<SdFamilyRecipe>> watchFamilyRecipes(String babyId) async* {
    yield _liveFamily;
    yield* _familyNow.stream;
  }

  void _emitFamily() => _familyNow.add(_liveFamily);

  @override
  void createFamilyRecipe(
    SdFamilyRecipe recipe, {
    void Function(Object error)? onError,
  }) {
    calls.add('createRecipe ${recipe.id}');
    family.add(recipe);
    _emitFamily();
  }

  @override
  void editFamilyRecipe(
    SdFamilyRecipe recipe,
    String uid, {
    void Function(Object error)? onError,
  }) {
    calls.add('editRecipe ${recipe.id}');
    family[family.indexWhere((r) => r.id == recipe.id)] = recipe;
    _emitFamily();
  }

  @override
  void softDeleteFamilyRecipe(
    SdFamilyRecipe recipe,
    String uid, {
    void Function(Object error)? onError,
  }) {
    calls.add('deleteRecipe ${recipe.id}');
    family.removeWhere((r) => r.id == recipe.id);
    _emitFamily();
  }

  @override
  void restoreFamilyRecipe(
    SdFamilyRecipe recipe,
    String uid, {
    void Function(Object error)? onError,
  }) {
    calls.add('restoreRecipe ${recipe.id}');
    family.add(recipe);
    _emitFamily();
  }

  List<SdMeal> get _live => [
    for (final m in meals)
      if (!m.deleted) m,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Stream<List<SdMeal>> watchMeals(String babyId) async* {
    yield _live;
    yield* _mealsNow.stream;
  }

  @override
  Stream<SdSettings?> watchSettings(String babyId) async* {
    yield settings;
    yield* _settingsNow.stream;
  }

  /// Settings writes and who made them (who may write is the Rules' job; the app shows the
  /// controls to Cùng nuôi only).
  final saved = <(SdSettings, String)>[];

  @override
  void saveSettings(
    String babyId,
    SdSettings settings,
    String uid, {
    void Function(Object error)? onError,
  }) {
    saved.add((settings, uid));
    this.settings = settings;
    _settingsNow.add(settings);
  }

  void _emit() => _mealsNow.add(_live);

  @override
  void create(SdMeal meal, {void Function(Object error)? onError}) {
    calls.add('create ${meal.id}');
    meals.add(meal);
    _emit();
  }

  @override
  void edit(SdMeal meal, String uid, {void Function(Object error)? onError}) {
    calls.add('edit ${meal.id}');
    meals[meals.indexWhere((m) => m.id == meal.id)] = meal;
    _emit();
  }

  @override
  void softDelete(
    SdMeal meal,
    String uid, {
    void Function(Object error)? onError,
  }) {
    calls.add('delete ${meal.id}');
    meals.removeWhere((m) => m.id == meal.id);
    _emit();
  }

  @override
  void restore(
    SdMeal meal,
    String uid, {
    void Function(Object error)? onError,
  }) {
    calls.add('restore ${meal.id}');
    meals.add(meal);
    _emit();
  }
}

/// The care mock plus Ăn dặm: [me] (default Mai), born [dob] (default Na's 2026-03-01); caregivers
/// read it from the vaccine plan (P-133).
List<Override> solidsOverrides({
  Membership? me,
  DateTime? dob,
  bool noDob = false,
  FakeSolidsStore? store,
  List<LbArticle>? articles,
  List<LbSaved> saved = const [],
  FakeContentStore? contentStore,
  ReminderRepository? reminderRepo,
  List<Reminder> reminders = const [],
  FirstAidPack? firstAid,
  FirstAidDevice? firstAidDevice,
  List<SdRecipe> recipes = const [],
  VaccinePhotoStore? photos,
  bool online = true,
  List<Override> extra = const [],
}) {
  final s = store ?? FakeSolidsStore(meals: naMeals(), settings: naSettings());
  final born = dob ?? naBorn;
  return [
    ...careOverrides(
      me: me,
      reminders: reminders,
      firstAid: firstAid,
      firstAidDevice: firstAidDevice,
      vaccinePhotos: photos,
      online: online,
      vaccinePlan: VaccinePlan(scheduleFrom: noDob ? null : born),
    ).where(
      (o) =>
          !'$o'.contains('<BabyPrivateProfile?') &&
          (reminderRepo == null ||
              !'$o'.contains('Provider<ReminderRepository>')),
    ),
    if (reminderRepo != null)
      reminderRepositoryProvider.overrideWithValue(reminderRepo),
    babyPrivateProfileProvider.overrideWith(
      (ref, id) => Stream.value(
        noDob
            ? BabyPrivateProfile.fromJson(const {'dateOfBirth': ''})
            : BabyPrivateProfile(dateOfBirth: born, gender: Gender.girl),
      ),
    ),
    ...libraryOverrides(articles: articles, saved: saved, store: contentStore),
    solidsStoreProvider.overrideWithValue(s),
    sdSettingsProvider.overrideWith((ref, id) => s.watchSettings(id)),
    sdMealsProvider.overrideWith((ref, id) => s.watchMeals(id)),
    sdFamilyRecipesProvider.overrideWith((ref, id) => s.watchFamilyRecipes(id)),
    sdFoodsProvider.overrideWith(
      (ref) => Stream.value((items: s.foods, fromCache: false)),
    ),
    sdRecipesProvider.overrideWith(
      (ref) => Stream.value((items: recipes, fromCache: false)),
    ),
    ...extra,
  ];
}

/// Solids guides of 5f (`library: 'solids'`), each format once, plus the care fixtures.
Map<String, Object?> solidsArticle(
  String id,
  String vi,
  String en, {
  required int from,
  required int to,
  String format = 'article',
  String publishedAt = '2026-09-20T03:00:00.000Z',
  int minutes = 4,
}) => {
  ...articleDoc(
    id: id,
    topic: 'feeding',
    vi: vi,
    en: en,
    from: from,
    to: to,
    minutes: minutes,
    publishedAt: publishedAt,
    library: 'solids',
  ),
  'format': format,
};

final solidsArticleDocs = [
  solidsArticle(
    'art_solids_readiness',
    'Bé đã sẵn sàng ăn dặm chưa?',
    'Is baby ready for solids?',
    from: 17,
    to: 30,
    format: 'quick_qa',
    minutes: 2,
    publishedAt: '2026-09-10T03:00:00.000Z',
  ),
  solidsArticle(
    'art_solids_first_meals',
    'Những bữa ăn dặm đầu tiên: chuẩn bị gì?',
    'The first solid meals: what to prepare?',
    from: 22,
    to: 39,
    format: 'step_guide',
    minutes: 5,
    publishedAt: '2026-10-01T03:00:00.000Z',
  ),
  solidsArticle(
    'art_solids_iron',
    'Thực phẩm giàu sắt cho bé ăn dặm',
    'Iron-rich foods for babies',
    from: 26,
    to: 104,
    publishedAt: '2026-09-25T03:00:00.000Z',
  ),
  solidsArticle(
    'art_solids_family_meals',
    'Bé ăn cùng gia đình từ 12 tháng',
    'Family meals from 12 months',
    from: 52,
    to: 156,
    publishedAt: '2026-09-28T03:00:00.000Z',
  ),
];

List<LbArticle> articlesWithSolids() => [
  ...fixtureArticles(),
  for (final d in solidsArticleDocs) LbArticle.fromDoc(d['id']! as String, d)!,
];
