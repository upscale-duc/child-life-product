import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../library/content_calc.dart' show lbFold;
import 'solids_calc.dart';
import 'solids_models.dart';
import 'solids_suggest.dart' show sdRecipesFor;

/// "Công thức nhà mình" (D-086; plan §12 #2, #4), the pure rules: the nudges (the family's own
/// text is never blocked, P-164 #10 only nudges here), the "Dành cho {bé}" ranking with the Child
/// Life recipes, what a family recipe puts in 5c, what a meal saves as, and the 5f search. All on
/// the device; recipes, meals and foods tried are child data (never logged).

// ---------- Seasonings (mirrors `solidsCopyProblems`, P-164 #10) ----------

/// `solidsSeasonings`: what a recipe for a baby never adds (WHO, NHS: no added salt or sugar).
const sdSeasonings = <String>[
  'muối',
  'đường',
  'nước mắm',
  'hạt nêm',
  'bột nêm',
  'bột canh',
  'bột ngọt',
  'mì chính',
  'nước tương',
  'xì dầu',
  'dầu hào',
  'mật ong',
  'salt',
  'sugar',
  'fish sauce',
  'stock cube',
  'msg',
  'soy sauce',
  'oyster sauce',
  'honey',
];

/// The contract's phrases, as written there: negations ("không nêm muối", "no added salt", "do
/// not add sugar") make a phrase safe.
const _negated =
    r"(?<!(?:không|đừng|chưa|không cần|no|without|don't|do not|never)\s)";
const _viSeasoning =
    r'(?:muối|đường|nước mắm|hạt nêm|bột nêm|bột canh|bột ngọt|mì chính|nước tương|xì dầu|dầu hào|mật ong)';
const _viAmount =
    r'(?:(?:một|1|nửa)\s+)?(?:chút|chút xíu|ít|tí|tẹo|xíu|nhúm|giọt|vài giọt|thìa(?:\s+cà phê)?)\s+';
const _enSeasoning =
    r'(?:salt|sugar|honey|fish sauce|soy sauce|oyster sauce|stock(?: cube)?|msg)';
const _enAmount =
    r'(?:(?:a|one|1|half a)\s+)?(?:pinch|dash|drop|few drops|little|bit|touch|splash|teaspoon|tsp|tablespoon|tbsp|spoon)(?:\s+of)?\s+|some\s+';

/// Adding a seasoning in any of the usual phrasings ("nêm chút nước mắm", "thêm một ít đường",
/// "nêm nếm vừa ăn", "add a pinch of salt", "season to taste"), unless negated.
final _seasoningActions = [
  '(?:nêm|thêm|cho|rắc|chấm)(?:\\s+thêm)?\\s+(?:$_viAmount)?$_viSeasoning',
  r'nêm(?:\s+nếm)?(?:\s+cho)?\s+vừa(?:\s+(?:ăn|miệng))?',
  'nêm nếm',
  '\\b(?:add(?:ed|ing)?|sprinkle|stir in|mix in|season with)\\s+(?:$_enAmount)?$_enSeasoning',
  r'\b(?:a\s+)?(?:pinch|dash)\s+of\s+(?:salt|sugar)',
  r'\b(?:salt|sugar|season(?:ing)?)\s+to taste',
  r'\bseason with\b',
].map((a) => RegExp('$_negated$a', caseSensitive: false, unicode: true));

/// A seasoning found: where ("title", "ingredients.2", "steps.0", "note") and what matched.
typedef SdSeasoningHit = ({String path, String match});

/// The seasoning checks of `solidsCopyProblems` on a family recipe: an ingredient named after a
/// seasoning (the whole name, or its first or last word), or an instruction to add one in the
/// title, a step or the note.
List<SdSeasoningHit> sdSeasoningProblems({
  String title = '',
  List<String> ingredients = const [],
  List<String> steps = const [],
  String note = '',
}) {
  final out = <SdSeasoningHit>[];
  for (final (n, raw) in ingredients.indexed) {
    final name = raw.toLowerCase().trim();
    final hit = sdSeasonings
        .where(
          (w) => name == w || name.startsWith('$w ') || name.endsWith(' $w'),
        )
        .firstOrNull;
    if (hit != null) out.add((path: 'ingredients.$n', match: hit));
  }
  void scan(String path, String value) {
    for (final action in _seasoningActions) {
      final m = action.firstMatch(value);
      if (m != null) {
        out.add((path: path, match: m[0]!));
        return;
      }
    }
  }

  scan('title', title);
  for (final (n, s) in steps.indexed) {
    scan('steps.$n', s);
  }
  scan('note', note);
  return out;
}

// ---------- Nudges (D-086 §12 #2) ----------

/// Honey: never before 12 months (botulism), whatever the catalogue says.
const sdHoneyMonths = 12;

bool _isHoney(String name) {
  final f = ' ${lbFold(name)} ';
  return f.contains(' mat ong ') || f.contains(' honey ');
}

/// What the editor and the family recipe page point out, never blocking a save.
enum SdNudgeKind {
  /// Honey for a baby under 12 months.
  honey,

  /// A catalogue food usually given later ("Thường từ 12 tháng").
  tooYoung,

  /// An added seasoning ([sdSeasoningProblems]).
  seasoning,

  /// The catalogue's choking note for a food in it.
  choking,
}

@immutable
class SdNudge {
  const SdNudge(
    this.kind, {
    this.names = const [],
    this.minAgeMonths,
    this.foodId,
  });
  final SdNudgeKind kind;

  /// The foods (honey, too young), the seasonings that matched, or the food and its choking note.
  final List<String> names;

  /// [SdNudgeKind.tooYoung].
  final int? minAgeMonths;

  /// [SdNudgeKind.choking], [SdNudgeKind.tooYoung]: the catalogue food.
  final String? foodId;
}

/// The nudges for a family recipe (draft or saved) for a baby of [months] completed months
/// (unknown: no age nudges). Catalogue names in [locale].
List<SdNudge> sdFamilyNudges({
  required List<SdFamilyIngredient> ingredients,
  required Map<String, SdFood> foods,
  int? months,
  String title = '',
  List<String> steps = const [],
  String note = '',
  Locale locale = const Locale('vi'),
}) {
  final out = <SdNudge>[];
  String nameOf(SdFamilyIngredient i) =>
      foods[i.foodId]?.name.pick(locale) ?? i.name;
  bool honey(SdFamilyIngredient i) =>
      _isHoney(i.name) || (foods[i.foodId]?.searchNames.any(_isHoney) ?? false);
  final young = months != null && months < sdHoneyMonths;
  final honeys = [
    for (final i in ingredients)
      if (young && honey(i)) nameOf(i),
  ];
  if (honeys.isNotEmpty) {
    out.add(SdNudge(SdNudgeKind.honey, names: honeys.toSet().toList()));
  }
  if (months != null) {
    final seen = <String>{};
    for (final i in ingredients) {
      final f = foods[i.foodId];
      if (f == null || honey(i) || !seen.add(f.id)) continue;
      if (f.minAgeMonths > months) {
        out.add(
          SdNudge(
            SdNudgeKind.tooYoung,
            names: [nameOf(i)],
            minAgeMonths: f.minAgeMonths,
            foodId: f.id,
          ),
        );
      }
    }
  }
  // Honey under 12 months is said above; at any age it is an added sweetener (WHO).
  final seasonings = {
    for (final h in sdSeasoningProblems(
      title: title,
      ingredients: [for (final i in ingredients) i.name],
      steps: steps,
      note: note,
    ))
      if (!(honeys.isNotEmpty && _isHoney(h.match))) h.match.trim(),
  };
  if (seasonings.isNotEmpty) {
    out.add(SdNudge(SdNudgeKind.seasoning, names: seasonings.toList()));
  }
  final choking = <String>{};
  for (final i in ingredients) {
    final f = foods[i.foodId];
    final note = f?.chokingNote?.pick(locale).trim() ?? '';
    if (f == null || note.isEmpty || !choking.add(f.id)) continue;
    out.add(
      SdNudge(SdNudgeKind.choking, names: [nameOf(i), note], foodId: f.id),
    );
  }
  return out;
}

/// ✦ "Bé chưa thử" (while tracking): a catalogue food the baby has not had.
bool sdNotTried(SdFamilyIngredient i, Map<String, SdTried> tried) =>
    i.foodId != null && !tried.containsKey(i.foodId);

/// ⚠ "Có dấu hiệu": a catalogue food with symptoms a Cùng nuôi has not cleared.
bool sdHasSigns(
  SdFamilyIngredient i,
  Map<String, SdTried> tried,
  List<String> cleared,
) =>
    i.foodId != null &&
    (tried[i.foodId]?.flagged ?? false) &&
    !cleared.contains(i.foodId);

// ---------- 5c and "Lưu thành công thức" ----------

String _clip(String s, int max) {
  final t = s.trim();
  return t.length <= max ? t : t.substring(0, max).trim();
}

/// What a "Món nhà mình" chip puts in 5c (D-086): the title as the dish, its catalogue foods (up to
/// 12) and free names (up to 3); the meal keeps the recipe's id.
typedef SdFamilyMealFill = ({
  String dish,
  List<String> foodIds,
  List<String> freeFoods,
});

SdFamilyMealFill sdFamilyMealFill(SdFamilyRecipe r) => (
  dish: _clip(r.title, SdLimits.mealDish),
  foodIds: r.foodIds.take(SdLimits.mealFoods).toList(),
  freeFoods: [
    for (final f in r.freeNames.take(SdLimits.mealFree))
      _clip(f, SdLimits.freeName),
  ],
);

/// "Lưu thành công thức" on a meal: the dish as the title (else the ingredients joined), its
/// catalogue foods (named in [locale]) then its free names.
({String title, List<SdFamilyIngredient> ingredients}) sdFamilyDraftFromMeal(
  SdMeal m,
  Map<String, SdFood> foods,
  Locale locale,
) {
  String name(String id) =>
      foods[id]?.name.pick(locale) ??
      id.replaceFirst('fd_', '').replaceAll('_', ' ');
  final ingredients = [
    for (final id in m.foodIds)
      SdFamilyIngredient(
        foodId: id,
        name: _clip(name(id), SdLimits.ingredientName),
      ),
    for (final f in m.freeFoods)
      SdFamilyIngredient(name: _clip(f, SdLimits.ingredientName)),
  ].take(SdLimits.familyIngredients).toList();
  final title = m.dish.trim().isNotEmpty
      ? m.dish
      : [for (final i in ingredients) i.name].join(', ');
  return (title: _clip(title, SdLimits.familyTitle), ingredients: ingredients);
}

/// The family recipes that recently made a meal first (5c chips), then the newest saved.
List<SdFamilyRecipe> sdRecentFamily(
  Iterable<SdFamilyRecipe> family,
  Iterable<SdMeal> meals,
) {
  final made = sdLastMadeByRecipe(meals);
  final out = [...family];
  out.sort((a, b) {
    final ma = made[a.id];
    final mb = made[b.id];
    if (ma != null || mb != null) {
      if (ma == null) return 1;
      if (mb == null) return -1;
      final c = mb.compareTo(ma);
      if (c != 0) return c;
    }
    final n = b.savedAt.compareTo(a.savedAt);
    return n != 0 ? n : a.id.compareTo(b.id);
  });
  return out;
}

// ---------- 5f search, 5d recipe names ----------

/// 5f search on the family's recipes: titles and ingredient names, with the linked foods' names
/// and synonyms; every word must start a word; the title weighs more. Best first, then newest.
/// Without a query, newest first.
List<SdFamilyRecipe> sdSearchFamily(
  Iterable<SdFamilyRecipe> family,
  String query, {
  Map<String, SdFood> foods = const {},
}) {
  final words = lbFold(query).split(' ').where((w) => w.isNotEmpty).toList();
  int score(SdFamilyRecipe r) {
    if (words.isEmpty) return 1;
    final title = ' ${lbFold(r.title)} ';
    final names =
        ' ${lbFold([
          for (final i in r.ingredients) ...[i.name, ...?foods[i.foodId]?.searchNames],
        ].join(' '))} ';
    var s = 0;
    for (final w in words) {
      if (title.contains(' $w')) {
        s += 2;
      } else if (names.contains(' $w')) {
        s += 1;
      } else {
        return 0;
      }
    }
    return s;
  }

  final scored = [
    for (final r in family)
      if (score(r) case final s when s > 0) (r, s),
  ];
  scored.sort((x, y) {
    if (x.$2 != y.$2) return y.$2.compareTo(x.$2);
    final n = y.$1.savedAt.compareTo(x.$1.savedAt);
    return n != 0 ? n : x.$1.id.compareTo(y.$1.id);
  });
  return [for (final (r, _) in scored) r];
}

/// Recipe names for the 5d search: id → both titles (Child Life) or the family's title.
Map<String, String> sdRecipeNames(
  Iterable<SdRecipe> recipes,
  Iterable<SdFamilyRecipe> family,
) => {
  for (final r in recipes) r.id: '${r.title.vi} ${r.title.en}',
  for (final r in family) r.id: r.title,
};

// ---------- "Dành cho {bé}" with the family's recipes (D-086 §12 #4) ----------

/// A Child Life recipe or one of the family's, in one ranked list ("Dành cho {bé}", a
/// suggestion's "Xem công thức"). Family recipes carry the "Nhà mình" tag on screen.
@immutable
class SdPick {
  const SdPick.editorial(SdRecipe this.recipe) : family = null;
  const SdPick.family(SdFamilyRecipe this.family) : recipe = null;

  final SdRecipe? recipe;
  final SdFamilyRecipe? family;

  bool get isFamily => family != null;
  String get id => recipe?.id ?? family!.id;
  List<String> get foodIds => recipe?.foodIds ?? family!.foodIds;

  /// Newest: first published (Child Life), first saved (the family's).
  DateTime get newest {
    final r = recipe;
    if (r != null) return r.firstPublishedAt ?? r.publishedAt ?? DateTime(2000);
    return family!.savedAt;
  }
}

/// The family's recipes under the rules of `sdRecipesFor` that apply to them (they carry no age
/// range or feeding method): no hidden food and no food with symptoms not cleared, no ingredient
/// above its minimum age, at most one untried catalogue ingredient, and with [suggested] foods one
/// of them, the only one that may be untried.
List<SdFamilyRecipe> sdFamilyRecipesFor({
  required Iterable<SdFamilyRecipe> family,
  required int months,
  required SdSettings settings,
  required Map<String, SdFood> foods,
  required Map<String, SdTried> tried,
  Set<String> snoozedFoods = const {},
  Set<String> suggested = const {},
}) {
  bool safe(String id) {
    final food = foods[id];
    if (food != null && food.minAgeMonths > months) return false;
    if (settings.hidden.contains(id) || snoozedFoods.contains(id)) {
      return false;
    }
    return !((tried[id]?.flagged ?? false) && !settings.cleared.contains(id));
  }

  return [
    for (final r in family)
      if (r.foodIds case final ids
          when ids.every(safe) &&
              // Honey under 12 months, even as a free name.
              !(months < sdHoneyMonths &&
                  r.ingredients.any((i) => _isHoney(i.name))) &&
              ids.where((id) => !tried.containsKey(id)).length <= 1 &&
              (suggested.isEmpty ||
                  (ids.any(suggested.contains) &&
                      ids
                          .where((id) => !tried.containsKey(id))
                          .every(suggested.contains))))
        r,
  ];
}

/// One ranking for both: the ingredients tried and liked, then newest, then the id (the order of
/// `sdRecipesFor`), so a dish the family makes and the baby likes comes back when it fits.
List<SdPick> sdForBabyPicks({
  required Iterable<SdRecipe> recipes,
  required Iterable<SdFamilyRecipe> family,
  required int months,
  required SdSettings settings,
  required Map<String, SdFood> foods,
  required Map<String, SdTried> tried,
  Set<String> snoozedFoods = const {},
  Set<String> suggested = const {},
}) {
  final picks = [
    for (final r in sdRecipesFor(
      recipes: recipes,
      months: months,
      settings: settings,
      foods: foods,
      tried: tried,
      snoozedFoods: snoozedFoods,
      suggested: suggested,
    ))
      SdPick.editorial(r),
    for (final r in sdFamilyRecipesFor(
      family: family,
      months: months,
      settings: settings,
      foods: foods,
      tried: tried,
      snoozedFoods: snoozedFoods,
      suggested: suggested,
    ))
      SdPick.family(r),
  ];
  int liked(SdPick p) => p.foodIds
      .where((id) => tried[id]?.latestReaction == SdReaction.liked)
      .length;
  picks.sort((a, b) {
    final l = liked(b).compareTo(liked(a));
    if (l != 0) return l;
    final n = b.newest.compareTo(a.newest);
    return n != 0 ? n : a.id.compareTo(b.id);
  });
  return picks;
}
