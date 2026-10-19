import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../baby/baby_models.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../library/content_calc.dart' show lbFold, lbScore;
import '../library/content_models.dart';
import 'solids_models.dart';

/// Pure rules of Ăn dặm (plan §3, §5), mirroring `solidsAgeState` / `slotForTime` in
/// `packages/contracts/src/solids.ts`. Tried foods, first tries, counts and the latest reaction are
/// derived on the device from the meals and never stored (plan §4), so 5b, 5e and 5h agree.

// ---------- Age (P-164 #2, owner D-085 #4) ----------

/// The Care tile and 5a by age: "Từ 6 tháng" · "Sắp đến lúc ăn dặm" · ready.
enum SdAgeState { tooYoung, soon, ready }

/// `solidsAgeState` (completed months, as Dinh dưỡng counts them: `nuMonthsOld`).
SdAgeState sdAgeState(int months) {
  if (months >= SdLimits.startMonths) return SdAgeState.ready;
  return months >= SdLimits.soonMonths ? SdAgeState.soon : SdAgeState.tooYoung;
}

/// The first local day on which the baby has [months] completed months (`nuMonthsOld`): the
/// same day of the month, or the 1st of the next month when that month is shorter.
DateTime sdMonthDay(DateTime dob, int months) {
  final first = DateTime(dob.year, dob.month + months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return dob.day <= last
      ? DateTime(first.year, first.month, dob.day)
      : DateTime(first.year, first.month + 1);
}

/// The diary opens on this day (6 completed months); meals are never dated before it (Rules do
/// not check it, the app does).
DateTime sdSixMonthDay(DateTime dob) => sdMonthDay(dob, SdLimits.startMonths);

/// "Nhắc tôi khi bé gần 6 tháng" (P-164 #2): one reminder at 5 months and 2 weeks; once that day
/// has passed, the 6-month day; null from 6 months on.
DateTime? sdReminderDay(DateTime dob, DateTime today) {
  final five = sdMonthDay(dob, 5);
  final near = DateTime(five.year, five.month, five.day + 14);
  final day = DateTime(today.year, today.month, today.day);
  if (near.isAfter(day)) return near;
  final six = sdSixMonthDay(dob);
  return six.isAfter(day) ? six : null;
}

// ---------- Slots and days ----------

/// `slotForTime`: Sáng 5–10 · Trưa 10–14 · Chiều 14–17 · Tối 17–21 · else Phụ.
SdSlot sdSlotForTime(int hour) {
  if (hour >= 5 && hour < 10) return SdSlot.morning;
  if (hour >= 10 && hour < 14) return SdSlot.noon;
  if (hour >= 14 && hour < 17) return SdSlot.afternoon;
  if (hour >= 17 && hour < 21) return SdSlot.evening;
  return SdSlot.snack;
}

/// The baby's calendar day of [at] (R-061: days follow the baby's time zone).
DateTime sdDayOf(String zone, DateTime at) {
  final l = inBabyZone(zone, at);
  return DateTime(l.year, l.month, l.day);
}

/// Monday of [day]'s week (the 5b strip runs T2 → CN).
DateTime sdWeekStart(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));

/// Meals on the local [day], in time order (5b cards: morning first).
List<SdMeal> sdMealsOn(Iterable<SdMeal> meals, String zone, DateTime day) => [
  for (final m in meals)
    if (!m.deleted && sdDayOf(zone, m.occurredAt) == day) m,
]..sort(sdCompareMeals);

/// The local days that have at least one meal (5b dots).
Set<DateTime> sdMealDays(Iterable<SdMeal> meals, String zone) => {
  for (final m in meals)
    if (!m.deleted) sdDayOf(zone, m.occurredAt),
};

/// Oldest first: by time, then by when it was logged, then by id (a stable order for ties).
int sdCompareMeals(SdMeal a, SdMeal b) {
  final t = a.occurredAt.compareTo(b.occurredAt);
  if (t != 0) return t;
  final l = a.loggedAt.compareTo(b.loggedAt);
  return l != 0 ? l : a.id.compareTo(b.id);
}

// ---------- Foods tried (P-164 #7) ----------

/// A free-text ingredient's key (group "Khác"): its folded name, so "Bí ngòi" and "bí ngòi" are
/// one food. Path-safe (food detail route).
String sdFreeKey(String name) {
  final folded = lbFold(name);
  if (folded.isNotEmpty) return 'x_${folded.replaceAll(' ', '_')}';
  return 'x_${name.trim().toLowerCase().runes.map((r) => r.toRadixString(16)).join('_')}';
}

/// Every food key of a meal: catalogue ids, then free names (each once).
List<String> sdMealKeys(SdMeal m) =>
    {...m.foodIds, for (final f in m.freeFoods) sdFreeKey(f)}.toList();

/// "Lần đầu" (✦): the meal's catalogue foods that no earlier meal has. Free names count as
/// tried but are never marked (plan §3 #7).
Set<String> sdFirstTryIds(SdMeal meal, Iterable<SdMeal> all) {
  final earlier = <String>{
    for (final m in all)
      if (!m.deleted && m.id != meal.id && sdCompareMeals(m, meal) < 0)
        ...m.foodIds,
  };
  return {
    for (final id in meal.foodIds)
      if (!earlier.contains(id)) id,
  };
}

/// One food the baby has had (5b chips, 5e rows, food detail).
@immutable
class SdTried {
  const SdTried({
    required this.key,
    required this.firstAt,
    required this.lastAt,
    required this.times,
    required this.meals,
    this.foodId,
    this.freeName,
    this.food,
    this.latestReaction,
    this.flagged = false,
  });

  /// The catalogue id, or [sdFreeKey] of a free name.
  final String key;
  final String? foodId;
  final String? freeName;

  /// The published food (null for free names, or a food no longer published).
  final SdFood? food;
  final DateTime firstAt;
  final DateTime lastAt;
  final int times;

  /// The reaction of the latest meal with it that has one (extraction Q3).
  final SdReaction? latestReaction;

  /// "Có dấu hiệu sau khi ăn" (P-164 #6): a meal where it was new had symptoms.
  final bool flagged;

  /// Meals with it, newest first.
  final List<SdMeal> meals;

  /// 5e groups; null = "Khác" (free names, and foods no longer published).
  SdGroup? get group => food?.group;

  String name(Locale locale) =>
      food?.name.pick(locale) ??
      freeName ??
      (foodId ?? key).replaceFirst(RegExp('^fd_'), '').replaceAll('_', ' ');
}

/// The foods tried, newest first try first (5e order).
///
/// Symptoms (P-164 #6): a meal with symptoms marks the foods that were new in it; when it had no
/// new food, all of its foods (a family that sees a reaction to a known food still gets the tag).
List<SdTried> sdTriedFoods(Iterable<SdMeal> meals, Map<String, SdFood> foods) {
  final sorted = [
    for (final m in meals)
      if (!m.deleted) m,
  ]..sort(sdCompareMeals);
  final seen = <String>{};
  final first = <String, DateTime>{};
  final last = <String, DateTime>{};
  final times = <String, int>{};
  final reaction = <String, SdReaction>{};
  final flagged = <String>{};
  final byKey = <String, List<SdMeal>>{};
  final free = <String, String>{};
  for (final m in sorted) {
    final keys = sdMealKeys(m);
    for (final f in m.freeFoods) {
      free.putIfAbsent(sdFreeKey(f), () => f.trim());
    }
    final fresh = {
      for (final k in keys)
        if (!seen.contains(k)) k,
    };
    if (m.hasSymptoms) flagged.addAll(fresh.isNotEmpty ? fresh : keys);
    for (final k in keys) {
      first.putIfAbsent(k, () => m.occurredAt);
      last[k] = m.occurredAt;
      times[k] = (times[k] ?? 0) + 1;
      if (m.reaction != null) reaction[k] = m.reaction!;
      (byKey[k] ??= []).insert(0, m);
    }
    seen.addAll(keys);
  }
  final out = [
    for (final k in first.keys)
      SdTried(
        key: k,
        foodId: sdFoodId(k) ? k : null,
        freeName: free[k],
        food: foods[k],
        firstAt: first[k]!,
        lastAt: last[k]!,
        times: times[k]!,
        latestReaction: reaction[k],
        flagged: flagged.contains(k),
        meals: byKey[k]!,
      ),
  ];
  out.sort((a, b) {
    final t = b.firstAt.compareTo(a.firstAt);
    return t != 0 ? t : a.key.compareTo(b.key);
  });
  return out;
}

/// 5e chips: how many tried foods per group (null = "Khác").
Map<SdGroup?, int> sdGroupCounts(Iterable<SdTried> tried) {
  final out = <SdGroup?, int>{};
  for (final t in tried) {
    out[t.group] = (out[t.group] ?? 0) + 1;
  }
  return out;
}

/// The 5e chip order: the 7 catalogue groups, then "Khác".
const sdGroupOrder = <SdGroup?>[...SdGroup.values, null];

// ---------- Today (5h, Care tile, Dinh dưỡng 9b) ----------

/// The day's meals: how many, the latest, and the foods tried for the first time that day.
typedef SdDaySummary = ({int count, SdMeal? latest, List<String> firstTries});

SdDaySummary sdDaySummary(Iterable<SdMeal> meals, String zone, DateTime day) {
  final on = sdMealsOn(meals, zone, day);
  return (
    count: on.length,
    latest: on.lastOrNull,
    firstTries: {for (final m in on) ...sdFirstTryIds(m, meals)}.toList(),
  );
}

/// When tracking started: the date set in 5a, else the first meal's day.
DateTime? sdStartedOn(SdSettings s, Iterable<SdMeal> meals, String zone) {
  if (s.startedOn != null) return s.startedOn;
  final firstMeal =
      [
        for (final m in meals)
          if (!m.deleted) m,
      ].fold<SdMeal?>(
        null,
        (a, m) => a == null || sdCompareMeals(m, a) < 0 ? m : a,
      );
  return firstMeal == null ? null : sdDayOf(zone, firstMeal.occurredAt);
}

// ---------- Roles (P-164 #13) ----------

extension SdRoles on Membership {
  /// Cùng nuôi: everything (settings, hidden foods, "Bác sĩ đã cho ăn lại").
  bool get sdManages => role == MemberRole.coParent;

  /// Cùng nuôi and Người chăm sóc log meals.
  bool get sdLogs =>
      role == MemberRole.coParent || role == MemberRole.caregiver;

  /// Who reads the diary (Rules `canReadCare`): also Người thân with daily-care rights.
  bool get sdReads => sdLogs || extraRights.viewDailyCare;

  /// Edit and delete: Cùng nuôi any meal, a caregiver their own (as `canEditRecord`).
  bool sdEdits(SdMeal m) =>
      role == MemberRole.coParent ||
      (role == MemberRole.caregiver && m.createdBy == uid);

  /// "Công thức nhà mình" (D-086): the writer or a Cùng nuôi edits and deletes it.
  bool sdEditsRecipe(SdFamilyRecipe r) =>
      role == MemberRole.coParent ||
      (role == MemberRole.caregiver && r.createdBy == uid);
}

// ---------- Ingredient picker (5c) ----------

/// Catalogue foods matching [query] (names and synonyms, both languages, without marks). The
/// foods the baby liked come first, then the others tried (latest first), then the catalogue's
/// priority and the name.
List<SdFood> sdSearchFoods(
  Iterable<SdFood> foods,
  String query, {
  Map<String, SdTried> tried = const {},
  Locale locale = const Locale('vi'),
}) {
  final words = lbFold(query).split(' ').where((w) => w.isNotEmpty).toList();
  // Every word must start a word of a name; whole words and the food's own name weigh more.
  int score(SdFood f) {
    if (words.isEmpty) return 1;
    final names = ' ${lbFold('${f.name.vi} ${f.name.en}')} ';
    final others = ' ${lbFold(f.searchNames.join(' '))} ';
    var s = 0;
    for (final w in words) {
      if (names.contains(' $w ')) {
        s += 4;
      } else if (others.contains(' $w ')) {
        s += 3;
      } else if (names.contains(' $w')) {
        s += 2;
      } else if (others.contains(' $w')) {
        s += 1;
      } else {
        return 0;
      }
    }
    return s;
  }

  int rank(SdFood f) => switch (tried[f.id]) {
    null => 2,
    SdTried(latestReaction: SdReaction.liked) => 0,
    _ => 1,
  };

  final hits = [
    for (final f in foods)
      if (score(f) case final s when s > 0) (f, s),
  ];
  hits.sort((x, y) {
    if (x.$2 != y.$2) return y.$2.compareTo(x.$2);
    final r = rank(x.$1).compareTo(rank(y.$1));
    if (r != 0) return r;
    final tx = tried[x.$1.id]?.lastAt;
    final ty = tried[y.$1.id]?.lastAt;
    if (tx != null && ty != null && tx != ty) return ty.compareTo(tx);
    if (x.$1.priority != y.$1.priority) {
      return y.$1.priority.compareTo(x.$1.priority);
    }
    return x.$1.name.pick(locale).compareTo(y.$1.name.pick(locale));
  });
  return [for (final (f, _) in hits) f];
}

// ---------- Recipe pictures (D-087, P-166 #5) ----------

/// What a recipe's placeholder picture shows: its main ingredient's group, else its texture.
enum SdRecipeArt {
  vegetable,
  fruit,
  animalProtein,
  egg,
  legumeNut,
  dairy,
  grain,

  /// No catalogue food: by texture (purées, soft pieces, finger food), or a plain dish.
  puree,
  pieces,
  finger,
  dish,
}

/// The main ingredient is the first linked catalogue food that is not a grain (nor a fat, which
/// is never the dish), else the first grain; egg (the allergen) gets its own picture. Without
/// one, the [texture] decides (family recipes have none: a plain dish).
SdRecipeArt sdRecipeArt(
  Iterable<String> foodIds,
  Map<String, SdFood> foods, {
  SdTexture? texture,
}) {
  final linked = [for (final id in foodIds) ?foods[id]];
  final main =
      linked
          .where((f) => f.group != SdGroup.grain && f.group != SdGroup.fat)
          .firstOrNull ??
      linked.where((f) => f.group == SdGroup.grain).firstOrNull;
  if (main != null) {
    return switch (main.group) {
      SdGroup.vegetable => SdRecipeArt.vegetable,
      SdGroup.fruit => SdRecipeArt.fruit,
      SdGroup.animalProtein =>
        main.allergen == SdAllergen.egg
            ? SdRecipeArt.egg
            : SdRecipeArt.animalProtein,
      SdGroup.legumeNut => SdRecipeArt.legumeNut,
      SdGroup.dairy => SdRecipeArt.dairy,
      SdGroup.grain || SdGroup.fat => SdRecipeArt.grain,
    };
  }
  return switch (texture) {
    SdTexture.smooth || SdTexture.mashed => SdRecipeArt.puree,
    SdTexture.softPieces || SdTexture.family => SdRecipeArt.pieces,
    SdTexture.finger => SdRecipeArt.finger,
    null => SdRecipeArt.dish,
  };
}

// ---------- Library (5f, P-164 #11) ----------

/// 5f age bands in completed months, `to` exclusive: 4–5 · 6–8 · 9–11 · 12–23 · 24–36 tháng.
enum SdBand {
  m4to5(4, 6),
  m6to8(6, 9),
  m9to11(9, 12),
  m12to23(12, 24),
  m24to36(24, 37);

  const SdBand(this.from, this.to);
  final int from;
  final int to;

  /// Articles keep their ages in completed weeks (`ageWeeks`).
  int get fromWeeks => (from * 30.4375 / 7).round();
  int get toWeeks => (to * 30.4375 / 7).round();
}

/// The band preset from the baby's age: under 4 months the first one (what comes next), none past
/// 36 months or without a date of birth.
SdBand? sdBandFor(int? months) {
  if (months == null) return null;
  if (months < SdBand.m4to5.from) return SdBand.m4to5;
  return SdBand.values
      .where((b) => months >= b.from && months < b.to)
      .firstOrNull;
}

/// 5f content types (P-164 #11): Hướng dẫn (solids articles) and Công thức (recipes).
enum SdLibraryType { guides, recipes }

/// What 5f shows: a query, an age band, a content type, a guide format and a recipe method (one
/// of each at most). A format implies guides; a method only narrows recipes.
@immutable
class SdLibraryFilter {
  const SdLibraryFilter({
    this.query = '',
    this.band,
    this.format,
    this.type,
    this.method,
  });
  final String query;
  final SdBand? band;
  final LbFormat? format;
  final SdLibraryType? type;
  final SdRecipeMethod? method;

  SdLibraryFilter copyWith({
    String? query,
    SdBand? band,
    bool clearBand = false,
    LbFormat? format,
    bool clearFormat = false,
    SdLibraryType? type,
    bool clearType = false,
    SdRecipeMethod? method,
    bool clearMethod = false,
  }) => SdLibraryFilter(
    query: query ?? this.query,
    band: clearBand ? null : (band ?? this.band),
    format: clearFormat ? null : (format ?? this.format),
    type: clearType ? null : (type ?? this.type),
    method: clearMethod ? null : (method ?? this.method),
  );

  List<String> get _words =>
      lbFold(query).split(' ').where((w) => w.isNotEmpty).toList();

  bool matches(LbArticle a) =>
      type != SdLibraryType.recipes &&
      a.library == LbLibrary.solids &&
      (band == null || a.weeks.overlaps(band!.fromWeeks, band!.toWeeks)) &&
      (format == null || a.format == format);

  /// Matching solids guides: best match first with a query, else newest first.
  List<LbArticle> apply(Iterable<LbArticle> articles) {
    final words = _words;
    final scored = <(LbArticle, int)>[
      for (final a in articles)
        if (matches(a))
          if (words.isEmpty ? 1 : lbScore(a, words) case final s when s > 0)
            (a, s),
    ];
    int newest(LbArticle a, LbArticle b) => (b.publishedAt ?? DateTime(2000))
        .compareTo(a.publishedAt ?? DateTime(2000));
    scored.sort(
      (x, y) => y.$2 != x.$2 ? y.$2.compareTo(x.$2) : newest(x.$1, y.$1),
    );
    return [for (final (a, _) in scored) a];
  }

  /// A recipe for the band (its months overlap), the method, and no guide-only filter.
  bool matchesRecipe(SdRecipe r) =>
      type != SdLibraryType.guides &&
      format == null &&
      (band == null || (r.ageFrom < band!.to && r.ageTo > band!.from)) &&
      (method == null || r.methods.contains(method));

  /// Matching recipes. The query searches titles and ingredient names, with the linked foods'
  /// names and synonyms ("bí ngô" finds Bí đỏ), both languages, without marks: every word must
  /// start a word; the title weighs more. Best match first, else the youngest age, then newest.
  List<SdRecipe> applyRecipes(
    Iterable<SdRecipe> recipes, {
    Map<String, SdFood> foods = const {},
  }) {
    final words = _words;
    int score(SdRecipe r) {
      if (words.isEmpty) return 1;
      final title = ' ${lbFold('${r.title.vi} ${r.title.en}')} ';
      final names =
          ' ${lbFold([
            for (final i in r.ingredients) ...[i.name.vi, i.name.en, ...?foods[i.foodId]?.searchNames],
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

    DateTime newest(SdRecipe r) =>
        r.firstPublishedAt ?? r.publishedAt ?? DateTime(2000);
    final scored = <(SdRecipe, int)>[
      for (final r in recipes)
        if (matchesRecipe(r))
          if (score(r) case final s when s > 0) (r, s),
    ];
    scored.sort((x, y) {
      if (x.$2 != y.$2) return y.$2.compareTo(x.$2);
      if (x.$1.ageFrom != y.$1.ageFrom) {
        return x.$1.ageFrom.compareTo(y.$1.ageFrom);
      }
      final n = newest(y.$1).compareTo(newest(x.$1));
      return n != 0 ? n : x.$1.id.compareTo(y.$1.id);
    });
    return [for (final (r, _) in scored) r];
  }
}

// ---------- Dishes made (D-086 §12 #1) ----------

/// "Nhà mình đã làm N lần · gần nhất 07/10 · Na thích": the meals cooked from a recipe (their
/// `recipeId`), newest first, and the reaction of the latest one that has one.
typedef SdDishesMade = ({List<SdMeal> meals, SdReaction? reaction});

SdDishesMade sdDishesMade(Iterable<SdMeal> meals, String recipeId) {
  final made = [
    for (final m in meals)
      if (!m.deleted && m.recipeId == recipeId) m,
  ]..sort((a, b) => sdCompareMeals(b, a));
  return (
    meals: made,
    reaction: made.where((m) => m.reaction != null).firstOrNull?.reaction,
  );
}

/// The latest meal cooked from each recipe (5c "Món nhà mình": recently made first).
Map<String, DateTime> sdLastMadeByRecipe(Iterable<SdMeal> meals) {
  final out = <String, DateTime>{};
  for (final m in meals) {
    final id = m.recipeId;
    if (m.deleted || id == null) continue;
    final last = out[id];
    if (last == null || m.occurredAt.isAfter(last)) out[id] = m.occurredAt;
  }
  return out;
}

// ---------- Which day the baby ate what (D-086 §12 #3) ----------

/// 5d search over dish, ingredient (catalogue names and synonyms, free names) and recipe names
/// ([recipeNames]: id → both titles): every word of [query] must start a word (folded, without
/// marks), so "Cà rốt" finds every meal with carrot. Newest first; empty without a query.
List<SdMeal> sdSearchMeals(
  Iterable<SdMeal> meals,
  String query, {
  Map<String, SdFood> foods = const {},
  Map<String, String> recipeNames = const {},
}) {
  final words = lbFold(query).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  bool hit(SdMeal m) {
    final text =
        ' ${lbFold([
          m.dish,
          for (final id in m.foodIds) ...[...?foods[id]?.searchNames, id.replaceFirst('fd_', '').replaceAll('_', ' ')],
          ...m.freeFoods,
          ?recipeNames[m.recipeId],
        ].join(' '))} ';
    return words.every((w) => text.contains(' $w'));
  }

  return [
    for (final m in meals)
      if (!m.deleted && hit(m)) m,
  ]..sort((a, b) => sdCompareMeals(b, a));
}

/// 5d "Lịch": how many meals on each local day.
Map<DateTime, int> sdMealCounts(Iterable<SdMeal> meals, String zone) {
  final out = <DateTime, int>{};
  for (final m in meals) {
    if (m.deleted) continue;
    final d = sdDayOf(zone, m.occurredAt);
    out[d] = (out[d] ?? 0) + 1;
  }
  return out;
}

/// The months "Lịch" pages through, newest first: today's month back to the first meal's (just
/// today's month without meals).
List<DateTime> sdCalendarMonths(DateTime? firstMeal, DateTime today) {
  final last = DateTime(today.year, today.month);
  final first = firstMeal == null
      ? last
      : DateTime(firstMeal.year, firstMeal.month);
  return [
    for (var m = last; !m.isBefore(first); m = DateTime(m.year, m.month - 1)) m,
  ];
}

/// [month]'s grid, Monday first: null for the padding days before the 1st and after the last.
List<DateTime?> sdMonthGrid(DateTime month) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final lead = first.weekday - DateTime.monday;
  final cells = <DateTime?>[
    for (var i = 0; i < lead; i++) null,
    for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}
