import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import '../care/care_models.dart' show CareAuthor;
import '../library/content_models.dart';

/// Ăn dặm (D-085, P-164; Figma 5a–5h; plan `docs/product/solids-plan.md` §3–§5). Mirrors
/// `packages/contracts/src/solids.ts`:
///
/// - the food catalogue, published by the portal to `contentFoods/{fd_…}` (`contentFoodSchema`);
/// - per baby, written by the app: `babies/{babyId}/solids/settings` (`solidsSettingsSchema`,
///   Cùng nuôi only) and `babies/{babyId}/meals/{m_…}` (`mealSchema`, written like care records:
///   client ids, the Firestore cache as the offline outbox, soft delete only).
///
/// Meals, tried foods, symptoms and settings are child data: never in logs, analytics or crash
/// keys (CLAUDE.md, plan §4).

/// `solidsLimits`.
abstract final class SdLimits {
  /// The diary opens at 6 completed months (owner, D-085 #4).
  static const startMonths = 6;

  /// "Sắp đến lúc ăn dặm" from 4 months.
  static const soonMonths = 4;
  static const maxAgeMonths = 36;
  static const mealDish = 60;
  static const mealNote = 300;
  static const mealFoods = 12;
  static const mealFree = 3;
  static const freeName = 40;
  static const amountMax = 1000;
  static const hidden = 50;

  /// A meal can be logged up to 7 days back (5c date field).
  static const backDays = 7;
}

/// 5e groups (`foodGroups`): Rau củ · Trái cây · Tinh bột · Đạm động vật · Đậu và hạt · Sữa và chế
/// phẩm · Chất béo. Free-text foods sit in "Khác" (a null group).
enum SdGroup { vegetable, fruit, grain, animalProtein, legumeNut, dairy, fat }

/// `foodAllergens`.
enum SdAllergen {
  egg,
  peanut,
  milk,
  wheat,
  soy,
  fish,
  shellfish,
  sesame,
  treeNut,
}

/// `textureStages`: Nghiền mịn · Nghiền lợn cợn · Cắt nhỏ, mềm · Cầm tay · Ăn cùng gia đình.
enum SdTexture { smooth, mashed, softPieces, finger, family }

/// The order rule S3 introduces them in (`allergenIntroOrder`, plan §7).
const sdAllergenIntroOrder = <SdAllergen>[
  SdAllergen.egg,
  SdAllergen.peanut,
  SdAllergen.milk,
  SdAllergen.wheat,
  SdAllergen.fish,
  SdAllergen.soy,
  SdAllergen.sesame,
  SdAllergen.shellfish,
  SdAllergen.treeNut,
];

/// 5a "Cách cho ăn" (`feedingMethods`): Truyền thống · BLW · Kết hợp.
enum SdMethod { spoon, blw, mixed }

/// A recipe suits spoon feeding, BLW, or both (`recipeMethods`).
enum SdRecipeMethod { spoon, blw }

/// Recipe quantities (`ingredientUnits`).
enum SdIngredientUnit { g, ml, tbsp, tsp, bowl, piece }

/// 5c slots (`mealSlots`): Sáng · Trưa · Chiều · Tối · Phụ.
enum SdSlot { morning, noon, afternoon, evening, snack }

/// 5c "Lượng bé ăn" (`mealAmountPresets`): Vài thìa · ½ chén · 1 chén.
enum SdAmountPreset { fewSpoons, halfBowl, fullBowl }

/// "Tự nhập" units (`mealAmountUnits`): thìa · chén · ml · g.
enum SdUnit { spoon, bowl, ml, g }

/// 5c "Bé ăn thế nào" (`mealReactions`): Thích · Bình thường · Chưa hợp.
enum SdReaction { liked, neutral, notYet }

/// "Có dấu hiệu bất thường sau khi ăn?" (`mealSymptoms`, P-164 #6).
enum SdSymptom {
  rash,
  vomit,
  diarrhea,
  fussy,
  swelling,
  breathing,
  other;

  /// `urgentSymptoms`: "Sưng môi, mặt" and "Khó thở, ho, khò khè" show the "Gọi 115" card at once.
  bool get urgent => this == swelling || this == breathing;
}

T? _enum<T extends Enum>(List<T> values, Object? name) =>
    name is String ? values.asNameMap()[name] : null;

final _foodId = RegExp(r'^fd_[a-z0-9_]{2,40}$');
final _recipeId = RegExp(r'^rcp_[a-z0-9_]{2,40}$');
final _mealId = RegExp(r'^m_[a-f0-9]{32}$');
final _articleId = RegExp(r'^art_[a-z0-9_]{2,60}$');

/// A meal photo in Storage: `babies/{babyId}/meals/{file}.jpg` (Storage Rules:
/// `^[A-Za-z0-9_-]{8,64}[.]jpg$`, JPEG ≤ 4 MB; owner: photos allowed, D-085 #2).
final _mealPhoto = RegExp(r'^babies/[^/]+/meals/[A-Za-z0-9_-]{8,64}[.]jpg$');

bool sdFoodId(Object? id) => id is String && _foodId.hasMatch(id);
bool sdRecipeId(Object? id) => id is String && _recipeId.hasMatch(id);
bool sdMealId(Object? id) => id is String && _mealId.hasMatch(id);
bool sdMealPhotoPath(Object? p) => p is String && _mealPhoto.hasMatch(p);

/// `m_` + 32 hex: generated once per sheet so a double tap or a retry writes the same doc.
String newMealId() => 'm_${const Uuid().v4().replaceAll('-', '')}';

// ---------- Food (catalogue, `contentFoods`) ----------

/// How to prepare a food at a texture stage ("Nho: cắt dọc làm tư").
typedef SdPrep = ({SdTexture texture, LbText text});

@immutable
class SdFood {
  const SdFood({
    required this.id,
    required this.name,
    required this.group,
    this.synonyms = LbTextList.empty,
    this.allergen,
    this.ironRich = false,
    this.minAgeMonths = SdLimits.startMonths,
    this.prep = const [],
    this.chokingNote,
    this.suggest = true,
    this.priority = 0,
  });

  final String id;
  final LbText name;
  final LbTextList synonyms;
  final SdGroup group;
  final SdAllergen? allergen;
  final bool ironRich;

  /// Honey and cow's milk as a drink: 12.
  final int minAgeMonths;
  final List<SdPrep> prep;
  final LbText? chokingNote;

  /// Whether the suggestions (phase D) may propose it.
  final bool suggest;
  final int priority;

  /// Every searchable name, both languages.
  Iterable<String> get searchNames sync* {
    yield* [name.vi, name.en];
    yield* synonyms.vi;
    yield* synonyms.en;
  }

  /// A published food the app can use, else null.
  static SdFood? fromDoc(String id, Map<String, Object?>? j) {
    if (j == null || !_foodId.hasMatch(id) || j['status'] != 'published') {
      return null;
    }
    final name = LbText.parse(j['name']);
    final group = _enum(SdGroup.values, j['group']);
    if (name == null || group == null) return null;
    final min = j['minAgeMonths'];
    final priority = j['priority'];
    return SdFood(
      id: id,
      name: name,
      group: group,
      synonyms: LbTextList.parse(j['synonyms']),
      allergen: _enum(SdAllergen.values, j['allergen']),
      ironRich: j['ironRich'] == true,
      minAgeMonths: min is num ? min.toInt() : SdLimits.startMonths,
      prep: [
        if (j['prep'] is List)
          for (final p in j['prep']! as List)
            if (p is Map)
              if ((
                    _enum(SdTexture.values, p['texture']),
                    LbText.parse(p['text']),
                  )
                  case (final SdTexture t, final LbText text))
                (texture: t, text: text),
      ],
      chokingNote: LbText.parse(j['chokingNote']),
      suggest: j['suggest'] != false,
      priority: priority is num ? priority.toInt() : 0,
    );
  }
}

// ---------- Recipe (`contentRecipes`, phase C) ----------

/// One recipe ingredient (`{ foodId | null, name, qty, unit, note }`): [foodId] links the
/// catalogue (null for water or a free name).
@immutable
class SdIngredient {
  const SdIngredient({
    required this.name,
    this.foodId,
    this.qty,
    this.unit,
    this.note,
  });
  final String? foodId;
  final LbText name;
  final num? qty;
  final SdIngredientUnit? unit;
  final LbText? note;
}

/// A published recipe (5f, 5g; `contentRecipeSchema`). Allergens are derived from the linked
/// foods ([sdRecipeAllergens]); the server refuses a recipe that starts below one of its foods'
/// minimum ages (`food-too-young`) or adds a seasoning (`unsafe-copy`, P-164 #10).
@immutable
class SdRecipe {
  const SdRecipe({
    required this.id,
    required this.title,
    required this.ageFrom,
    required this.ageTo,
    required this.texture,
    required this.methods,
    required this.ingredients,
    required this.steps,
    this.summary,
    this.cover,
    this.servings = 1,
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.storage,
    this.tip,
    this.relatedArticleIds = const [],
    this.sources = const [],
    this.review,
    this.illustrative = true,
    this.revision = 1,
    this.publishedAt,
    this.firstPublishedAt,
  });

  final String id;
  final LbText title;
  final LbText? summary;
  final LbImage? cover;

  /// Completed months, [ageTo] exclusive (`solidsAgeSchema`).
  final int ageFrom;
  final int ageTo;
  final SdTexture texture;
  final Set<SdRecipeMethod> methods;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final List<SdIngredient> ingredients;
  final LbTextList steps;
  final LbText? storage;
  final LbText? tip;
  final List<String> relatedArticleIds;
  final List<LbSource> sources;
  final LbReview? review;

  /// The D-082 footnote until a qualified reviewer signs it.
  final bool illustrative;
  final int revision;
  final DateTime? publishedAt;
  final DateTime? firstPublishedAt;

  /// "15 phút" in 5f and the 5g clock chip.
  int get totalMinutes => prepMinutes + cookMinutes;

  /// The linked catalogue foods, each once, in recipe order.
  List<String> get foodIds => {
    for (final i in ingredients)
      if (i.foodId != null) i.foodId!,
  }.toList();

  /// A published recipe the app can show, else null.
  static SdRecipe? fromDoc(String id, Map<String, Object?>? j) {
    if (j == null || !_recipeId.hasMatch(id) || j['status'] != 'published') {
      return null;
    }
    final title = LbText.parse(j['title']);
    final texture = _enum(SdTexture.values, j['texture']);
    final age = j['ageMonths'];
    if (title == null || texture == null || age is! Map) return null;
    final from = age['from'];
    final to = age['to'];
    if (from is! num || to is! num || to <= from) return null;
    int minutes(Object? v) => v is num && v >= 0 ? v.toInt() : 0;
    final servings = j['servings'];
    final review = LbReview.parse(j['review']);
    final revision = j['revision'];
    return SdRecipe(
      id: id,
      title: title,
      summary: LbText.parse(j['summary']),
      cover: LbImage.parse(j['cover']),
      ageFrom: from.toInt(),
      ageTo: to.toInt(),
      texture: texture,
      methods: {
        if (j['methods'] is List)
          for (final m in j['methods']! as List)
            ?_enum(SdRecipeMethod.values, m),
      },
      servings: servings is num && servings >= 1 ? servings.toInt() : 1,
      prepMinutes: minutes(j['prepMinutes']),
      cookMinutes: minutes(j['cookMinutes']),
      ingredients: [
        if (j['ingredients'] is List)
          for (final i in j['ingredients']! as List)
            if (i is Map)
              if (LbText.parse(i['name']) case final name?)
                SdIngredient(
                  name: name,
                  foodId: sdFoodId(i['foodId']) ? i['foodId'] as String : null,
                  qty: i['qty'] is num && (i['qty'] as num) > 0
                      ? i['qty'] as num
                      : null,
                  unit: _enum(SdIngredientUnit.values, i['unit']),
                  note: LbText.parse(i['note']),
                ),
      ],
      steps: LbTextList.parse(j['steps']),
      storage: LbText.parse(j['storage']),
      tip: LbText.parse(j['tip']),
      relatedArticleIds: [
        if (j['relatedArticleIds'] is List)
          for (final r in j['relatedArticleIds']! as List)
            if (r is String && _articleId.hasMatch(r)) r,
      ],
      sources: LbSource.list(j['sources']),
      review: review,
      // Never trust a "reviewed" flag without the review itself (P-141).
      illustrative: j['illustrative'] != false || review == null,
      revision: revision is num ? revision.toInt() : 1,
      publishedAt: lbDate(j['publishedAt']),
      firstPublishedAt: lbDate(j['firstPublishedAt']),
    );
  }
}

/// `recipeAllergens`: the common allergens a recipe contains, from its catalogue foods, in the
/// `foodAllergens` order ("Có trứng").
List<SdAllergen> sdRecipeAllergens(SdRecipe r, Map<String, SdFood> foods) {
  final found = {
    for (final i in r.ingredients)
      if (i.foodId != null) ?foods[i.foodId]?.allergen,
  };
  return [
    for (final a in SdAllergen.values)
      if (found.contains(a)) a,
  ];
}

// ---------- Settings (`babies/{babyId}/solids/settings`) ----------

/// 5a, per baby; written by Cùng nuôi only (Rules mirror `solidsSettingsSchema`).
@immutable
class SdSettings {
  const SdSettings({
    this.enabled = false,
    this.startedOn,
    this.showOnToday = true,
    this.method = SdMethod.mixed,
    this.hidden = const [],
    this.cleared = const [],
    this.updatedBy,
  });

  /// No document yet: tracking off, the 5a defaults.
  static const off = SdSettings();

  final bool enabled;

  /// The first meal's date, editable (local calendar date); null = from the first meal.
  final DateTime? startedOn;

  /// "Hiện “Ăn dặm hôm nay” trên Hôm nay" (default on).
  final bool showOnToday;
  final SdMethod method;

  /// "Không gợi ý món này".
  final List<String> hidden;

  /// "Bác sĩ đã cho ăn lại": foods with past symptoms that may be suggested again.
  final List<String> cleared;
  final String? updatedBy;

  SdSettings copyWith({
    bool? enabled,
    DateTime? startedOn,
    bool clearStartedOn = false,
    bool? showOnToday,
    SdMethod? method,
    List<String>? hidden,
    List<String>? cleared,
  }) => SdSettings(
    enabled: enabled ?? this.enabled,
    startedOn: clearStartedOn ? null : (startedOn ?? this.startedOn),
    showOnToday: showOnToday ?? this.showOnToday,
    method: method ?? this.method,
    hidden: hidden ?? this.hidden,
    cleared: cleared ?? this.cleared,
    updatedBy: updatedBy,
  );

  /// The whole document (`solidsSettingsSchema`, strict): `updatedAt == request.time`.
  Map<String, Object?> toJson(String uid) => {
    'enabled': enabled,
    'startedOn': startedOn == null ? null : isoDate(startedOn!),
    'showOnToday': showOnToday,
    'method': method.name,
    'hidden': hidden.take(SdLimits.hidden).toList(),
    'cleared': cleared.take(SdLimits.hidden).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
  };

  static SdSettings? fromJson(Map<String, Object?>? j) {
    if (j == null) return null;
    List<String> ids(Object? v) => [
      if (v is List)
        for (final id in v)
          if (sdFoodId(id)) id as String,
    ];
    final started = j['startedOn'];
    return SdSettings(
      enabled: j['enabled'] == true,
      startedOn: started is String ? DateTime.tryParse(started) : null,
      showOnToday: j['showOnToday'] != false,
      method: _enum(SdMethod.values, j['method']) ?? SdMethod.mixed,
      hidden: ids(j['hidden']),
      cleared: ids(j['cleared']),
      updatedBy: j['updatedBy'] as String?,
    );
  }
}

// ---------- Meals (`babies/{babyId}/meals/{mealId}`) ----------

/// 5c "Lượng bé ăn": a preset, or "Tự nhập" (a number and a unit) — `mealAmountSchema`.
@immutable
class SdAmount {
  const SdAmount.preset(SdAmountPreset this.preset) : value = null, unit = null;
  const SdAmount.custom(num this.value, SdUnit this.unit) : preset = null;

  final SdAmountPreset? preset;
  final num? value;
  final SdUnit? unit;

  Map<String, Object?> toJson() => preset != null
      ? {'preset': preset!.name}
      : {'value': value, 'unit': unit!.name};

  static SdAmount? fromJson(Object? j) {
    if (j is! Map) return null;
    final preset = _enum(SdAmountPreset.values, j['preset']);
    if (preset != null) return SdAmount.preset(preset);
    final value = j['value'];
    final unit = _enum(SdUnit.values, j['unit']);
    if (value is! num || value <= 0 || unit == null) return null;
    return SdAmount.custom(value, unit);
  }

  @override
  bool operator ==(Object other) =>
      other is SdAmount &&
      other.preset == preset &&
      other.value == value &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(preset, value, unit);
}

/// One logged meal (5c). Rules mirror `mealSchema`; [pending] = saved on this device only.
@immutable
class SdMeal {
  const SdMeal({
    required this.id,
    required this.babyId,
    required this.occurredAt,
    required this.slot,
    required this.createdBy,
    required this.author,
    this.dish = '',
    this.foodIds = const [],
    this.freeFoods = const [],
    this.amount,
    this.reaction,
    this.symptoms = const [],
    this.note = '',
    this.recipeId,
    this.photoPath,
    this.createdAt,
    this.clientCreatedAt,
    this.deleted = false,
    this.pending = false,
  });

  final String id;
  final String babyId;
  final DateTime occurredAt;
  final SdSlot slot;
  final String dish;

  /// Catalogue foods (`fd_…`, ≤ 12) and free-text names (≤ 3, group "Khác").
  final List<String> foodIds;
  final List<String> freeFoods;
  final SdAmount? amount;
  final SdReaction? reaction;
  final List<SdSymptom> symptoms;
  final String note;

  /// From 5g "Ghi vào nhật ký".
  final String? recipeId;

  /// `babies/{babyId}/meals/{file}.jpg` (owner: photos allowed, D-085 #2; `solids_photos.dart`).
  final String? photoPath;
  final String createdBy;

  /// "Mẹ ghi" / "Cô Lan ghi": the writer's membership at logging time (as care records).
  final CareAuthor author;
  final DateTime? createdAt;
  final DateTime? clientCreatedAt;
  final bool deleted;
  final bool pending;

  bool get hasSymptoms => symptoms.isNotEmpty;

  /// "Ghi lúc": the server time, or the device time while pending.
  DateTime get loggedAt => createdAt ?? clientCreatedAt ?? occurredAt;

  static SdMeal create({
    required String id,
    required Membership me,
    required DateTime occurredAt,
    required SdSlot slot,
    String dish = '',
    List<String> foodIds = const [],
    List<String> freeFoods = const [],
    SdAmount? amount,
    SdReaction? reaction,
    List<SdSymptom> symptoms = const [],
    String note = '',
    String? recipeId,
    String? photoPath,
  }) => SdMeal(
    id: id,
    babyId: me.babyId,
    occurredAt: occurredAt,
    slot: slot,
    dish: dish,
    foodIds: foodIds,
    freeFoods: freeFoods,
    amount: amount,
    reaction: reaction,
    symptoms: symptoms,
    note: note,
    recipeId: recipeId,
    photoPath: photoPath,
    createdBy: me.uid,
    author: CareAuthor.of(me),
    clientCreatedAt: DateTime.now(),
    pending: true,
  );

  /// "Sửa": everything but who and when it was logged.
  SdMeal edited({
    required DateTime occurredAt,
    required SdSlot slot,
    required String dish,
    required List<String> foodIds,
    required List<String> freeFoods,
    required SdAmount? amount,
    required SdReaction? reaction,
    required List<SdSymptom> symptoms,
    required String note,
    required String? photoPath,
  }) => SdMeal(
    id: id,
    babyId: babyId,
    occurredAt: occurredAt,
    slot: slot,
    dish: dish,
    foodIds: foodIds,
    freeFoods: freeFoods,
    amount: amount,
    reaction: reaction,
    symptoms: symptoms,
    note: note,
    recipeId: recipeId,
    photoPath: photoPath,
    createdBy: createdBy,
    author: author,
    createdAt: createdAt,
    clientCreatedAt: clientCreatedAt,
    deleted: deleted,
    pending: true,
  );

  Map<String, Object?> _body() => {
    'occurredAt': Timestamp.fromDate(occurredAt),
    'slot': slot.name,
    'dish': dish.trim(),
    'foodIds': foodIds.take(SdLimits.mealFoods).toList(),
    'freeFoods': [
      for (final f in freeFoods.take(SdLimits.mealFree))
        if (f.trim().isNotEmpty) f.trim(),
    ],
    'amount': amount?.toJson(),
    'reaction': reaction?.name,
    'symptoms': [for (final s in symptoms) s.name],
    'note': note.trim(),
    'recipeId': recipeId,
    'photoPath': photoPath,
  };

  /// The whole new document (`mealSchema`, strict; Rules as `validNewRecord`).
  Map<String, Object?> toCreateJson() => {
    'id': id,
    'babyId': babyId,
    ..._body(),
    'createdBy': createdBy,
    'author': author.toJson(),
    'createdAt': FieldValue.serverTimestamp(),
    'clientCreatedAt': Timestamp.fromDate(clientCreatedAt ?? DateTime.now()),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': createdBy,
    'deleted': false,
    'deletedAt': null,
    'deletedBy': null,
  };

  /// "Sửa" (Rules as `validRecordUpdate`: the body only, plus who and when).
  Map<String, Object?> toEditJson(String uid) => {
    ..._body(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
  };

  static SdMeal? fromJson(
    String id,
    Map<String, Object?>? j, {
    bool pending = false,
  }) {
    if (j == null || !_mealId.hasMatch(id)) return null;
    final at = dateOf(j['occurredAt']);
    final slot = _enum(SdSlot.values, j['slot']);
    if (at == null || slot == null) return null;
    final recipe = j['recipeId'];
    final photo = j['photoPath'];
    return SdMeal(
      id: id,
      babyId: j['babyId'] as String? ?? '',
      occurredAt: at,
      slot: slot,
      dish: (j['dish'] as String? ?? '').trim(),
      foodIds: [
        if (j['foodIds'] is List)
          for (final f in j['foodIds']! as List)
            if (sdFoodId(f)) f as String,
      ],
      freeFoods: [
        if (j['freeFoods'] is List)
          for (final f in j['freeFoods']! as List)
            if (f is String && f.trim().isNotEmpty) f.trim(),
      ],
      amount: SdAmount.fromJson(j['amount']),
      reaction: _enum(SdReaction.values, j['reaction']),
      symptoms: [
        if (j['symptoms'] is List)
          for (final s in j['symptoms']! as List) ?_enum(SdSymptom.values, s),
      ],
      note: (j['note'] as String? ?? '').trim(),
      recipeId: recipe is String && _recipeId.hasMatch(recipe) ? recipe : null,
      photoPath: photo is String && photo.isNotEmpty ? photo : null,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      createdAt: dateOf(j['createdAt']),
      clientCreatedAt: dateOf(j['clientCreatedAt']),
      deleted: j['deleted'] == true,
      pending: pending,
    );
  }

  static SdMeal? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      fromJson(doc.id, doc.data(), pending: doc.metadata.hasPendingWrites);
}
