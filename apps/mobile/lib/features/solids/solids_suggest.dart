import 'package:flutter/foundation.dart';

import 'solids_calc.dart';
import 'solids_models.dart';

/// "Gợi ý cho {bé}" (plan §7; P-164 #12; owner: free for every family, D-085 #1): pure rules on
/// the device from the baby's age, the meals, the tried foods, the settings and the published
/// foods and recipes. No meal data leaves the device for this and nothing is sent to analytics
/// (CLAUDE.md, plan §4). The screens turn the cards into words (`solids_personal.dart`).
///
/// Rules S1–S9 run in priority order; each makes at most one card; at most 1 primary + 2
/// secondary ([sdMaxCards]). Guardrails (plan §7): never a food above its `minAgeMonths`, a hidden
/// food (or one snoozed on this device), one with symptoms that a Cùng nuôi has not cleared, a
/// food the catalogue does not let the engine propose (`suggest`), or a free name.

/// 1 primary + 2 secondary (P-164 #12).
const sdMaxCards = 3;

/// "Để sau" hides a card on this device for 3 days (plan §7 Feedback).
const sdSnoozeDays = 3;

/// A caregiver's "Không gợi ý món này" hides the food on this device (settings are Cùng nuôi's,
/// P-164 #13); for 30 days.
const sdFoodSnoozeDays = 30;

/// The rules of plan §7, in priority order.
enum SdRule {
  /// S1 Safety after symptoms: a meal in the last 3 days had symptoms.
  s1,

  /// S2 First foods: fewer than 5 foods tried.
  s2,

  /// S3 Allergen introduction: ≥ 5 foods, ≥ 7 days since start, no new allergen in 3 days.
  s3,

  /// S4 Keep allergens up: an introduced allergen without symptoms not offered in 7 days.
  s4,

  /// S5 Iron: meals on the last 2 days, none with an iron-rich food.
  s5,

  /// S6 Next new food: no new food in 2 days.
  s6,

  /// S7 Retry a "Chưa hợp": no symptoms, last offered ≥ 3 days ago, fewer than 10 tries.
  s7,

  /// S8 Variety: a group not offered in 7 days.
  s8,

  /// S9 Texture step: first open in a new Dinh dưỡng stage.
  s9,
}

/// The one action of a card.
enum SdCardAction {
  /// S1 "Đọc: Nhận biết phản ứng".
  readReactions,

  /// "Ghi bữa" (5c prefilled with [SdCard.prefill]).
  logMeal,

  /// "Xem công thức": the "Dành cho {bé}" ranking for [SdCard.foodIds].
  viewRecipes,

  /// S8 "Xem gợi ý": foods of the group.
  viewIdeas,

  /// S9 "Đọc hướng dẫn".
  readTextures,
}

/// One suggestion card: what the screens need to word its title and its "vì sao" line.
@immutable
class SdCard {
  const SdCard({
    required this.rule,
    required this.action,
    this.primary = false,
    this.foodIds = const [],
    this.allergen,
    this.group,
    this.date,
    this.count = 0,
    this.days = 0,
    this.likedFoodId,
    this.mealId,
    this.stageId,
  });

  final SdRule rule;
  final SdCardAction action;

  /// The top card; 5h shows its title as a second line.
  final bool primary;

  /// The suggested catalogue foods, best first (S2–S8). A meal logged today with one of them
  /// completes the card (plan §7 Feedback).
  final List<String> foodIds;

  /// S3, S4.
  final SdAllergen? allergen;

  /// S6 (the group with the fewest tries), S8 (the group not offered).
  final SdGroup? group;

  /// S1: the day of the meal with symptoms; S4, S8: the day last offered.
  final DateTime? date;

  /// S2, S3: foods tried; S6: foods tried in [group]; S7: tries of the food.
  final int count;

  /// S3: days since tracking started.
  final int days;

  /// S7: a food the baby liked, to mix with.
  final String? likedFoodId;

  /// S1: the meal with symptoms.
  final String? mealId;

  /// S9: the new Dinh dưỡng stage.
  final String? stageId;

  /// What "Để sau" snoozes: the rule, or the rule and its subject when the rule has one per food,
  /// allergen or group (another subject may then take its place).
  String get key => switch (rule) {
    SdRule.s3 || SdRule.s4 => '${rule.name}:${allergen!.name}',
    SdRule.s7 => '${rule.name}:${foodIds.first}',
    SdRule.s8 => '${rule.name}:${group!.name}',
    _ => rule.name,
  };

  /// What "Ghi bữa" puts in 5c: the first suggestion (they are alternatives), and for S7 the
  /// liked food to mix it with.
  List<String> get prefill => [
    if (foodIds.isNotEmpty) foodIds.first,
    ?likedFoodId,
  ];

  SdCard asPrimary() => SdCard(
    rule: rule,
    action: action,
    primary: true,
    foodIds: foodIds,
    allergen: allergen,
    group: group,
    date: date,
    count: count,
    days: days,
    likedFoodId: likedFoodId,
    mealId: mealId,
    stageId: stageId,
  );
}

/// Everything the rules read (plan §7 Inputs), all on the device.
@immutable
class SdSuggestInput {
  const SdSuggestInput({
    required this.months,
    required this.today,
    required this.zone,
    required this.settings,
    required this.meals,
    required this.foods,
    this.snoozed = const {},
    this.snoozedFoods = const {},
    this.newStageId,
  });

  /// Completed months.
  final int months;

  /// The baby's calendar day (R-061).
  final DateTime today;
  final String zone;
  final SdSettings settings;
  final List<SdMeal> meals;

  /// The published catalogue by id.
  final Map<String, SdFood> foods;

  /// Card keys ([SdCard.key]) snoozed on this device ("Để sau").
  final Set<String> snoozed;

  /// Foods a caregiver snoozed on this device ("Không gợi ý món này").
  final Set<String> snoozedFoods;

  /// S9: the Dinh dưỡng stage opened for the first time today ([sdStageStep]).
  final String? newStageId;
}

/// Calendar days from [from] to [to] (both local calendar days).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The facts the rules share.
class _Facts {
  _Facts(this.i) {
    live = [
      for (final m in i.meals)
        if (!m.deleted) m,
    ]..sort(sdCompareMeals);
    for (final t in sdTriedFoods(live, i.foods)) {
      tried[t.key] = t;
    }
    for (final m in live) {
      final day = dayOf(m.occurredAt);
      if (day.isBefore(i.today)) {
        triedBeforeToday.addAll(sdMealKeys(m));
      } else if (day == i.today) {
        today.addAll(m.foodIds);
      }
    }
    final started = sdStartedOn(i.settings, live, i.zone);
    daysSinceStart = started == null ? 0 : _daysBetween(started, i.today);
  }

  final SdSuggestInput i;
  late final List<SdMeal> live;
  final tried = <String, SdTried>{};
  final triedBeforeToday = <String>{};

  /// Catalogue foods in today's meals.
  final today = <String>{};
  late final int daysSinceStart;

  DateTime dayOf(DateTime at) => sdDayOf(i.zone, at);
  int ago(DateTime at) => _daysBetween(dayOf(at), i.today);

  /// Symptoms not cleared by a Cùng nuôi ("Bác sĩ đã cho ăn lại", P-164 #6).
  bool flagged(String id) =>
      (tried[id]?.flagged ?? false) && !i.settings.cleared.contains(id);

  bool hidden(String id) =>
      i.settings.hidden.contains(id) || i.snoozedFoods.contains(id);

  /// The guardrails (plan §7).
  bool allowed(SdFood f) =>
      f.suggest &&
      f.minAgeMonths <= i.months &&
      !hidden(f.id) &&
      !flagged(f.id);

  /// Every catalogue food the baby has had with this allergen.
  List<SdTried> withAllergen(SdAllergen a) => [
    for (final t in tried.values)
      if (t.food?.allergen == a) t,
  ];

  bool introduced(SdAllergen a) => withAllergen(a).isNotEmpty;

  /// Higher priority first, then the id (stable).
  int byPriority(SdFood a, SdFood b) => a.priority != b.priority
      ? b.priority.compareTo(a.priority)
      : a.id.compareTo(b.id);

  /// Liked first, then tried, then "Chưa hợp", then untried; then priority (S5, S8 ideas).
  int byLiking(SdFood a, SdFood b) {
    int rank(SdFood f) => switch (tried[f.id]) {
      null => 3,
      SdTried(latestReaction: SdReaction.liked) => 0,
      SdTried(latestReaction: SdReaction.notYet) => 2,
      _ => 1,
    };
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : byPriority(a, b);
  }
}

/// "Gợi ý cho {bé} hôm nay": at most [sdMaxCards] cards, the first one primary. Empty while
/// tracking is off, under 6 months, or with no published foods (the feature still logs).
List<SdCard> sdSuggest(SdSuggestInput i) {
  if (!i.settings.enabled ||
      i.foods.isEmpty ||
      i.months < SdLimits.startMonths) {
    return const [];
  }
  final f = _Facts(i);
  final out = <SdCard>[];
  void add(SdCard? c) {
    if (c == null || out.length >= sdMaxCards) return;
    if (i.snoozed.contains(c.key)) return;
    // A meal logged today with a suggested food completes the card.
    if (c.foodIds.any(f.today.contains)) return;
    out.add(c);
  }

  final s1 = _s1(f);
  add(s1);
  // S1 says "tạm chưa thử món mới vài ngày": while it holds (3 days, even when its card is
  // snoozed) nothing new and no allergen is suggested (S2, S3, S4, S6), and S5 keeps to foods the
  // baby has eaten.
  final safety = s1 != null;
  final firstFoods = f.tried.length < 5;
  if (!safety) {
    add(_s2(f));
    add(_s3(f));
    add(_s4(f));
  }
  add(_s5(f, triedOnly: safety));
  // S2 already proposes the next new foods while fewer than 5 are tried: no second card of
  // new foods.
  if (!firstFoods && !safety) add(_s6(f));
  add(_s7(f));
  add(_s8(f));
  if (i.newStageId case final stage?) {
    add(
      SdCard(
        rule: SdRule.s9,
        action: SdCardAction.readTextures,
        stageId: stage,
      ),
    );
  }
  return [for (final (n, c) in out.indexed) n == 0 ? c.asPrimary() : c];
}

/// S1: the latest meal of the last 3 days (today and the 2 before) with symptoms.
SdCard? _s1(_Facts f) {
  final m = f.live.reversed
      .where((m) => m.hasSymptoms && f.ago(m.occurredAt) <= 2)
      .firstOrNull;
  if (m == null) return null;
  return SdCard(
    rule: SdRule.s1,
    action: SdCardAction.readReactions,
    mealId: m.id,
    date: f.dayOf(m.occurredAt),
  );
}

/// S2: three first foods, not allergens (S3 handles those), not tried before today (stable all
/// day): the best iron-rich one last ("Bí đỏ, Khoai lang hoặc Thịt gà (giàu sắt)"), fruit after
/// the others.
SdCard? _s2(_Facts f) {
  if (f.tried.length >= 5) return null;
  final pool = [
    for (final food in f.i.foods.values)
      if (f.allowed(food) &&
          food.allergen == null &&
          !f.triedBeforeToday.contains(food.id))
        food,
  ];
  if (pool.isEmpty) return null;
  final iron = ([
    for (final food in pool)
      if (food.ironRich) food,
  ]..sort(f.byPriority)).firstOrNull;
  final others = [
    for (final food in pool)
      if (food != iron) food,
  ];
  others.sort((a, b) {
    final fa = a.group == SdGroup.fruit ? 1 : 0;
    final fb = b.group == SdGroup.fruit ? 1 : 0;
    return fa != fb ? fa.compareTo(fb) : f.byPriority(a, b);
  });
  return SdCard(
    rule: SdRule.s2,
    action: SdCardAction.logMeal,
    foodIds: [
      for (final food in others.take(iron == null ? 3 : 2)) food.id,
      ?iron?.id,
    ],
    count: f.tried.length,
  );
}

/// S3: the next allergen in `allergenIntroOrder` not introduced yet that has an allowed food
/// (one the family hid is skipped), with its foods best first.
SdCard? _s3(_Facts f) {
  if (f.tried.length < 5 || f.daysSinceStart < 7) return null;
  final recent = f.tried.values.any(
    (t) => t.food?.allergen != null && f.ago(t.firstAt) < 3,
  );
  if (recent) return null;
  for (final a in sdAllergenIntroOrder) {
    if (f.introduced(a)) continue;
    final foods = [
      for (final food in f.i.foods.values)
        if (food.allergen == a && f.allowed(food)) food,
    ]..sort(f.byPriority);
    if (foods.isEmpty) continue;
    return SdCard(
      rule: SdRule.s3,
      action: SdCardAction.viewRecipes,
      allergen: a,
      foodIds: [for (final food in foods) food.id],
      count: f.tried.length,
      days: f.daysSinceStart,
    );
  }
  return null;
}

/// S4: of the allergens introduced without symptoms, the one offered longest ago (7 days or
/// more), with the food the baby knows best (liked first, then the latest).
SdCard? _s4(_Facts f) {
  SdCard? best;
  DateTime? bestDay;
  for (final a in sdAllergenIntroOrder) {
    final had = f.withAllergen(a);
    if (had.isEmpty || had.any((t) => f.flagged(t.key))) continue;
    if (f.i.snoozed.contains('${SdRule.s4.name}:${a.name}')) continue;
    final last = had
        .map((t) => t.lastAt)
        .reduce((x, y) => x.isAfter(y) ? x : y);
    if (f.ago(last) < 7) continue;
    final known = [
      for (final t in had)
        if (t.food != null && f.allowed(t.food!)) t,
    ];
    if (known.isEmpty) continue;
    known.sort((x, y) {
      final lx = x.latestReaction == SdReaction.liked ? 0 : 1;
      final ly = y.latestReaction == SdReaction.liked ? 0 : 1;
      return lx != ly ? lx.compareTo(ly) : y.lastAt.compareTo(x.lastAt);
    });
    final day = f.dayOf(last);
    if (bestDay == null || day.isBefore(bestDay)) {
      bestDay = day;
      best = SdCard(
        rule: SdRule.s4,
        action: SdCardAction.logMeal,
        allergen: a,
        foodIds: [known.first.key],
        date: day,
      );
    }
  }
  return best;
}

/// S5: meals on each of the 2 days before today and none with an iron-rich food since (today's
/// included): three iron-rich foods, tried and liked first. An untried allergen is never one of
/// them (S3 introduces those).
SdCard? _s5(_Facts f, {bool triedOnly = false}) {
  final i = f.i;
  final yesterday = DateTime(i.today.year, i.today.month, i.today.day - 1);
  final before = DateTime(i.today.year, i.today.month, i.today.day - 2);
  final recent = [
    for (final m in f.live)
      if (!f.dayOf(m.occurredAt).isBefore(before)) m,
  ];
  bool hasMeal(DateTime d) => recent.any((m) => f.dayOf(m.occurredAt) == d);
  if (!hasMeal(yesterday) || !hasMeal(before)) return null;
  final iron = recent.any(
    (m) => m.foodIds.any((id) => i.foods[id]?.ironRich ?? false),
  );
  if (iron) return null;
  final foods = [
    for (final food in i.foods.values)
      if (food.ironRich &&
          f.allowed(food) &&
          (triedOnly || food.allergen != null
              ? f.tried.containsKey(food.id)
              : true))
        food,
  ]..sort(f.byLiking);
  if (foods.isEmpty) return null;
  return SdCard(
    rule: SdRule.s5,
    action: SdCardAction.viewRecipes,
    foodIds: [for (final food in foods.take(3)) food.id],
  );
}

/// S6: three untried foods, not allergens, from the group with the fewest foods tried (early on,
/// the first 30 days, vegetables come before fruit), then by priority; filled from the next
/// groups.
SdCard? _s6(_Facts f) {
  final i = f.i;
  final lastNew = f.tried.values
      .map((t) => t.firstAt)
      .fold<DateTime?>(null, (a, d) => a == null || d.isAfter(a) ? d : a);
  if (lastNew == null || f.ago(lastNew) < 2) return null;
  final byGroup = <SdGroup, List<SdFood>>{};
  for (final food in i.foods.values) {
    if (f.allowed(food) &&
        food.allergen == null &&
        !f.tried.containsKey(food.id)) {
      (byGroup[food.group] ??= []).add(food);
    }
  }
  if (byGroup.isEmpty) return null;
  final counts = sdGroupCounts(f.tried.values);
  final groups = byGroup.keys.toList()
    ..sort((a, b) {
      final c = (counts[a] ?? 0).compareTo(counts[b] ?? 0);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
  final veg = groups.indexOf(SdGroup.vegetable);
  final fruit = groups.indexOf(SdGroup.fruit);
  if (f.daysSinceStart < 30 && veg > 0 && fruit >= 0 && fruit < veg) {
    groups
      ..removeAt(fruit)
      ..insert(veg, SdGroup.fruit);
  }
  final picked = <String>[];
  for (final g in groups) {
    for (final food in byGroup[g]!..sort(f.byPriority)) {
      if (picked.length < 3) picked.add(food.id);
    }
  }
  return SdCard(
    rule: SdRule.s6,
    action: SdCardAction.logMeal,
    foodIds: picked,
    group: groups.first,
    count: counts[groups.first] ?? 0,
  );
}

/// S7: a food whose latest reaction is "Chưa hợp" (no symptoms), last offered 3 days ago or
/// more, tried fewer than 10 times: the most recently offered one, with a liked food to mix in.
SdCard? _s7(_Facts f) {
  final i = f.i;
  final retry =
      [
        for (final t in f.tried.values)
          if (t.food != null &&
              t.latestReaction == SdReaction.notYet &&
              !t.flagged &&
              t.times < 10 &&
              f.ago(t.lastAt) >= 3 &&
              f.allowed(t.food!) &&
              !i.snoozed.contains('${SdRule.s7.name}:${t.key}'))
            t,
      ]..sort((a, b) {
        final l = b.lastAt.compareTo(a.lastAt);
        return l != 0 ? l : a.key.compareTo(b.key);
      });
  final t = retry.firstOrNull;
  if (t == null) return null;
  final liked =
      [
        for (final x in f.tried.values)
          if (x.food != null &&
              x.key != t.key &&
              x.latestReaction == SdReaction.liked &&
              f.allowed(x.food!))
            x,
      ]..sort((a, b) {
        final c = b.times.compareTo(a.times);
        return c != 0 ? c : b.lastAt.compareTo(a.lastAt);
      });
  return SdCard(
    rule: SdRule.s7,
    action: SdCardAction.logMeal,
    foodIds: [t.key],
    likedFoodId: liked.firstOrNull?.key,
    count: t.times,
  );
}

/// S8: of the groups the baby already knows, the one offered longest ago (7 days or more), with
/// up to 5 allowed foods of it, liked first.
SdCard? _s8(_Facts f) {
  final i = f.i;
  final last = <SdGroup, DateTime>{};
  for (final t in f.tried.values) {
    final g = t.group;
    if (g == null) continue;
    final day = f.dayOf(t.lastAt);
    if (last[g] == null || day.isAfter(last[g]!)) last[g] = day;
  }
  final stale =
      [
        for (final e in last.entries)
          if (_daysBetween(e.value, i.today) >= 7 &&
              !i.snoozed.contains('${SdRule.s8.name}:${e.key.name}'))
            e,
      ]..sort((a, b) {
        final c = a.value.compareTo(b.value);
        return c != 0 ? c : a.key.index.compareTo(b.key.index);
      });
  for (final e in stale) {
    final ideas = [
      for (final food in i.foods.values)
        if (food.group == e.key &&
            f.allowed(food) &&
            (food.allergen == null || f.tried.containsKey(food.id)))
          food,
    ]..sort(f.byLiking);
    if (ideas.isEmpty) continue;
    return SdCard(
      rule: SdRule.s8,
      action: SdCardAction.viewIdeas,
      group: e.key,
      date: e.value,
      foodIds: [for (final food in ideas.take(5)) food.id],
    );
  }
  return null;
}

// ---------- S9: the stage seen on this device ----------

/// The Dinh dưỡng stage last opened on this device for a baby: its id, the day it was first
/// opened and whether it replaced an earlier one (a new stage, not the first ever).
typedef SdStageSeen = ({String id, DateTime on, bool fresh});

/// Opening the suggestions with the baby in [stageId]: the first stage ever seen is only
/// remembered; a different one is a new stage.
SdStageSeen sdStageVisit(SdStageSeen? seen, String stageId, DateTime today) {
  if (seen == null) return (id: stageId, on: today, fresh: false);
  if (seen.id != stageId) return (id: stageId, on: today, fresh: true);
  return seen;
}

/// S9 fires on the day the new stage was first opened.
bool sdStageStep(SdStageSeen? seen, String? stageId, DateTime today) =>
    seen != null &&
    stageId != null &&
    seen.fresh &&
    seen.id == stageId &&
    seen.on == today;

// ---------- Snoozes ----------

/// The keys still snoozed on [today] (a snooze set on day D for N days ends on D + N).
Set<String> sdActiveSnoozes(Map<String, DateTime> until, DateTime today) => {
  for (final e in until.entries)
    if (e.value.isAfter(today)) e.key,
};

// ---------- "Dành cho {bé}" (plan §7 Recipes) ----------

/// Published recipes for the baby's age and feeding method with no hidden food and no food with
/// symptoms not cleared, no ingredient above its minimum age, and at most one untried catalogue
/// ingredient. With [suggested] foods ("Xem công thức" of a card), a recipe has one of them and
/// only one of them may be untried. Ranked by the ingredients tried and liked, then newest.
List<SdRecipe> sdRecipesFor({
  required Iterable<SdRecipe> recipes,
  required int months,
  required SdSettings settings,
  required Map<String, SdFood> foods,
  required Map<String, SdTried> tried,
  Set<String> snoozedFoods = const {},
  Set<String> suggested = const {},
}) {
  bool methodFits(SdRecipe r) =>
      r.methods.isEmpty ||
      switch (settings.method) {
        SdMethod.spoon => r.methods.contains(SdRecipeMethod.spoon),
        SdMethod.blw => r.methods.contains(SdRecipeMethod.blw),
        SdMethod.mixed => true,
      };
  bool safe(String id) {
    final food = foods[id];
    if (food != null && food.minAgeMonths > months) return false;
    if (settings.hidden.contains(id) || snoozedFoods.contains(id)) {
      return false;
    }
    return !((tried[id]?.flagged ?? false) && !settings.cleared.contains(id));
  }

  int liked(SdRecipe r) => r.foodIds
      .where((id) => tried[id]?.latestReaction == SdReaction.liked)
      .length;
  final out = <SdRecipe>[];
  for (final r in recipes) {
    if (months < r.ageFrom || months >= r.ageTo || !methodFits(r)) continue;
    final ids = r.foodIds;
    if (!ids.every(safe)) continue;
    final untried = [
      for (final id in ids)
        if (!tried.containsKey(id)) id,
    ];
    if (untried.length > 1) continue;
    if (suggested.isNotEmpty &&
        (!ids.any(suggested.contains) || !untried.every(suggested.contains))) {
      continue;
    }
    out.add(r);
  }
  DateTime newest(SdRecipe r) =>
      r.firstPublishedAt ?? r.publishedAt ?? DateTime(2000);
  out.sort((a, b) {
    final l = liked(b).compareTo(liked(a));
    if (l != 0) return l;
    final n = newest(b).compareTo(newest(a));
    return n != 0 ? n : a.id.compareTo(b.id);
  });
  return out;
}
