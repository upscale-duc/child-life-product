import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show authorLabel, decimal;
import '../family/family_labels.dart' show relationLabel;
import '../library/content_models.dart';
import '../nutrition/nutrition_format.dart' show nuAgeLabel;
import '../nutrition/nutrition_models.dart' show NuStage;
import 'solids_calc.dart';
import 'solids_family.dart';
import 'solids_models.dart';
import 'solids_state.dart';

/// Labels of Ăn dặm (vi and en in the ARB files, D-012). Wording rules (P-164 #17): no labels such
/// as "biếng ăn", no amounts as targets; "Chưa hợp" stays neutral; never "dị ứng" as a fact.

String sdSlotLabel(AppLocalizations l10n, SdSlot s) => switch (s) {
  SdSlot.morning => l10n.sdSlotMorning,
  SdSlot.noon => l10n.sdSlotNoon,
  SdSlot.afternoon => l10n.sdSlotAfternoon,
  SdSlot.evening => l10n.sdSlotEvening,
  SdSlot.snack => l10n.sdSlotSnack,
};

/// "Bữa sáng" on 5b cards.
String sdSlotMealLabel(AppLocalizations l10n, SdSlot s) => switch (s) {
  SdSlot.morning => l10n.sdMealMorning,
  SdSlot.noon => l10n.sdMealNoon,
  SdSlot.afternoon => l10n.sdMealAfternoon,
  SdSlot.evening => l10n.sdMealEvening,
  SdSlot.snack => l10n.sdMealSnack,
};

String sdPresetLabel(AppLocalizations l10n, SdAmountPreset p) => switch (p) {
  SdAmountPreset.fewSpoons => l10n.sdAmountFewSpoons,
  SdAmountPreset.halfBowl => l10n.sdAmountHalfBowl,
  SdAmountPreset.fullBowl => l10n.sdAmountFullBowl,
};

/// "Tự nhập" unit chips.
String sdUnitLabel(AppLocalizations l10n, SdUnit u) => switch (u) {
  SdUnit.spoon => l10n.sdUnitSpoon,
  SdUnit.bowl => l10n.sdUnitBowl,
  SdUnit.ml => 'ml',
  SdUnit.g => 'g',
};

/// "Vài thìa", "4 thìa", "1,5 chén", "120 ml".
String sdAmountLabel(AppLocalizations l10n, String locale, SdAmount a) {
  final preset = a.preset;
  if (preset != null) return sdPresetLabel(l10n, preset);
  final v = a.value!;
  final unit = a.unit!;
  final whole = v == v.roundToDouble();
  return switch (unit) {
    SdUnit.spoon when whole => l10n.sdAmountSpoons(v.round()),
    SdUnit.bowl when whole => l10n.sdAmountBowls(v.round()),
    _ => l10n.sdAmountValue(
      whole ? '${v.round()}' : decimal(locale, v.toDouble()),
      sdUnitLabel(l10n, unit),
    ),
  };
}

String sdReactionLabel(AppLocalizations l10n, SdReaction r) => switch (r) {
  SdReaction.liked => l10n.sdReactionLiked,
  SdReaction.neutral => l10n.sdReactionNeutral,
  SdReaction.notYet => l10n.sdReactionNotYet,
};

String sdSymptomLabel(AppLocalizations l10n, SdSymptom s) => switch (s) {
  SdSymptom.rash => l10n.sdSymptomRash,
  SdSymptom.vomit => l10n.sdSymptomVomit,
  SdSymptom.diarrhea => l10n.sdSymptomDiarrhea,
  SdSymptom.fussy => l10n.sdSymptomFussy,
  SdSymptom.swelling => l10n.sdSymptomSwelling,
  SdSymptom.breathing => l10n.sdSymptomBreathing,
  SdSymptom.other => l10n.sdSymptomOther,
};

/// 5e groups; null = "Khác".
String sdGroupLabel(AppLocalizations l10n, SdGroup? g) => switch (g) {
  SdGroup.vegetable => l10n.sdGroupVegetable,
  SdGroup.fruit => l10n.sdGroupFruit,
  SdGroup.grain => l10n.sdGroupGrain,
  SdGroup.animalProtein => l10n.sdGroupProtein,
  SdGroup.legumeNut => l10n.sdGroupLegume,
  SdGroup.dairy => l10n.sdGroupDairy,
  SdGroup.fat => l10n.sdGroupFat,
  null => l10n.sdGroupOther,
};

String sdMethodLabel(AppLocalizations l10n, SdMethod m) => switch (m) {
  SdMethod.spoon => l10n.sdMethodSpoon,
  SdMethod.blw => l10n.sdMethodBlw,
  SdMethod.mixed => l10n.sdMethodMixed,
};

String sdMethodHelp(AppLocalizations l10n, SdMethod m) => switch (m) {
  SdMethod.spoon => l10n.sdMethodSpoonHelp,
  SdMethod.blw => l10n.sdMethodBlwHelp,
  SdMethod.mixed => l10n.sdMethodMixedHelp,
};

String sdFormatLabel(AppLocalizations l10n, LbFormat f) => switch (f) {
  LbFormat.article => l10n.sdFormatArticle,
  LbFormat.stepGuide => l10n.sdFormatStepGuide,
  LbFormat.quickQa => l10n.sdFormatQuickQa,
};

/// "6–8 tháng" (the band's last month included).
String sdBandLabel(AppLocalizations l10n, SdBand b) =>
    l10n.lbRangeMonths(b.from, b.to - 1);

/// "08:10".
String sdTime(String locale, DateTime at) => DateFormat.Hm(locale).format(at);

/// "Hôm nay", "Hôm qua", "Thứ Tư 07/10".
String sdDayLabel(
  AppLocalizations l10n,
  String locale,
  DateTime day,
  DateTime today,
) {
  if (day == today) return l10n.sdToday;
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return l10n.sdYesterday;
  }
  return toBeginningOfSentenceCase(
    DateFormat('EEEE dd/MM', locale).format(day),
  );
}

/// "07/10".
String sdShortDate(String locale, DateTime day) =>
    DateFormat('dd/MM', locale).format(day);

/// What a meal is called: the dish, else its ingredients joined.
String sdMealTitle(SdMeal m, Map<String, SdFood> foods, Locale locale) {
  if (m.dish.trim().isNotEmpty) return m.dish.trim();
  return [
    for (final id in m.foodIds) sdFoodName(id, foods, locale),
    ...m.freeFoods,
  ].join(', ');
}

/// A catalogue food's name (a readable id when it is no longer published).
String sdFoodName(String id, Map<String, SdFood> foods, Locale locale) =>
    foods[id]?.name.pick(locale) ??
    id.replaceFirst(RegExp('^fd_'), '').replaceAll('_', ' ');

/// "½ chén · Thích" (either part may be missing).
String sdMealLine(AppLocalizations l10n, String locale, SdMeal m) => [
  if (m.amount != null) sdAmountLabel(l10n, locale, m.amount!),
  if (m.reaction != null) sdReactionLabel(l10n, m.reaction!),
].join(' · ');

/// "Mẹ ghi" / "Cô Lan ghi" / "Bạn ghi".
String sdLoggedBy(AppLocalizations l10n, SdMeal m, String myUid) =>
    l10n.careLoggedBy(
      authorLabel(
        l10n,
        m.author,
        isMe: m.createdBy == myUid,
        relationLabel: (r, c) => relationLabel(l10n, r, c),
      ),
    );

/// 5b day header's information line (P-164 #15): "Giai đoạn 6–8 tháng · 2–3 bữa · nghiền, đặc
/// dần", never a target.
String? sdStageLine(AppLocalizations l10n, NuStage? stage, Locale locale) {
  final solids = stage?.solids;
  if (stage == null || solids == null) return null;
  return [
    l10n.careNutritionStage(nuAgeLabel(l10n, stage.age)),
    solids.meals.pick(locale),
    ?solids.texture?.pick(locale),
  ].join(' · ');
}

/// The Care tile's subline (plan §5).
String sdTileLine(AppLocalizations l10n, SdState? s, SdDaySummary? today) {
  if (s == null) return l10n.careSolidsSub;
  if (s.tracking && s.me.sdReads) return l10n.sdTileToday(today?.count ?? 0);
  if (!s.me.sdReads) return l10n.careSolidsSub;
  return switch (s.age) {
    null => s.me.sdManages ? l10n.careNutritionNoDob : l10n.careSolidsSub,
    SdAgeState.tooYoung => l10n.sdTileFrom6,
    SdAgeState.soon => l10n.sdTileSoon,
    SdAgeState.ready => l10n.sdTileStart,
  };
}

// ---------- Recipes (5f, 5g) ----------

String sdTextureLabel(AppLocalizations l10n, SdTexture t) => switch (t) {
  SdTexture.smooth => l10n.sdTextureSmooth,
  SdTexture.mashed => l10n.sdTextureMashed,
  SdTexture.softPieces => l10n.sdTextureSoftPieces,
  SdTexture.finger => l10n.sdTextureFinger,
  SdTexture.family => l10n.sdTextureFamily,
};

/// "Truyền thống" / "BLW" (the 5a method names).
String sdRecipeMethodLabel(AppLocalizations l10n, SdRecipeMethod m) =>
    switch (m) {
      SdRecipeMethod.spoon => l10n.sdMethodSpoon,
      SdRecipeMethod.blw => l10n.sdMethodBlw,
    };

/// "6–8 tháng" (the recipe's last month included).
String sdRecipeAgeLabel(AppLocalizations l10n, SdRecipe r) =>
    l10n.lbRangeMonths(r.ageFrom, r.ageTo - 1);

/// "trứng", "đậu phộng" (lower case, in sentences).
String sdAllergenLabel(AppLocalizations l10n, SdAllergen a) => switch (a) {
  SdAllergen.egg => l10n.sdAllergenEgg,
  SdAllergen.peanut => l10n.sdAllergenPeanut,
  SdAllergen.milk => l10n.sdAllergenMilk,
  SdAllergen.wheat => l10n.sdAllergenWheat,
  SdAllergen.soy => l10n.sdAllergenSoy,
  SdAllergen.fish => l10n.sdAllergenFish,
  SdAllergen.shellfish => l10n.sdAllergenShellfish,
  SdAllergen.sesame => l10n.sdAllergenSesame,
  SdAllergen.treeNut => l10n.sdAllergenTreeNut,
};

/// S3: how to offer it ("trứng chín kỹ", "bơ đậu phộng pha loãng").
String sdAllergenTry(AppLocalizations l10n, SdAllergen a) => switch (a) {
  SdAllergen.egg => l10n.sdTryEgg,
  SdAllergen.peanut => l10n.sdTryPeanut,
  SdAllergen.milk => l10n.sdTryMilk,
  SdAllergen.wheat => l10n.sdTryWheat,
  SdAllergen.soy => l10n.sdTrySoy,
  SdAllergen.fish => l10n.sdTryFish,
  SdAllergen.shellfish => l10n.sdTryShellfish,
  SdAllergen.sesame => l10n.sdTrySesame,
  SdAllergen.treeNut => l10n.sdTryTreeNut,
};

/// 5g allergen line ("Có trứng, đậu phộng"); null without one.
String? sdContainsLine(AppLocalizations l10n, List<SdAllergen> allergens) =>
    allergens.isEmpty
    ? null
    : l10n.sdContains(
        [for (final a in allergens) sdAllergenLabel(l10n, a)].join(', '),
      );

/// A recipe quantity: "30 g", "400 ml", "1 thìa cà phê", "2 chén", "0,5 chén"; null without one.
String? sdIngredientQty(AppLocalizations l10n, String locale, SdIngredient i) {
  final q = i.qty;
  if (q == null) return null;
  final whole = q == q.roundToDouble();
  final value = whole ? '${q.round()}' : decimal(locale, q.toDouble());
  return switch (i.unit) {
    null => value,
    SdIngredientUnit.g => l10n.sdAmountValue(value, 'g'),
    SdIngredientUnit.ml => l10n.sdAmountValue(value, 'ml'),
    SdIngredientUnit.tbsp => l10n.sdAmountValue(value, l10n.sdIngUnitTbsp),
    SdIngredientUnit.tsp => l10n.sdAmountValue(value, l10n.sdIngUnitTsp),
    SdIngredientUnit.bowl when whole => l10n.sdIngBowls(q.round()),
    SdIngredientUnit.bowl => l10n.sdAmountValue(value, l10n.sdIngUnitBowl),
    SdIngredientUnit.piece when whole => l10n.sdIngPieces(q.round()),
    SdIngredientUnit.piece => l10n.sdAmountValue(value, l10n.sdIngUnitPiece),
  };
}

/// "Bí đỏ, Khoai lang hoặc Thịt gà".
String sdOrList(AppLocalizations l10n, List<String> names) {
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} '
      '${l10n.sdOr} ${names.last}';
}

// ---------- Dishes made and family recipes (D-086) ----------

/// "Na thích" / "Na ăn bình thường" / "Na chưa hợp" (neutral, P-164 #17).
String sdMadeReaction(AppLocalizations l10n, SdReaction r, String name) =>
    switch (r) {
      SdReaction.liked => l10n.sdMadeLiked(name),
      SdReaction.neutral => l10n.sdMadeNeutral(name),
      SdReaction.notYet => l10n.sdMadeNotYet(name),
    };

/// "Nhà mình đã làm 3 lần · gần nhất 07/10 · Na thích"; null when never made.
String? sdMadeLine(
  AppLocalizations l10n,
  String tag,
  SdDishesMade made,
  String zone,
  String name,
) {
  final last = made.meals.firstOrNull;
  if (last == null) return null;
  return [
    l10n.sdMadeCount(made.meals.length),
    l10n.sdMadeLast(sdShortDate(tag, sdDayOf(zone, last.occurredAt))),
    if (made.reaction != null) sdMadeReaction(l10n, made.reaction!, name),
  ].join(' · ');
}

/// A family recipe quantity ("30 g", "1 thìa cà phê"); null without one.
String? sdFamilyQty(
  AppLocalizations l10n,
  String locale,
  SdFamilyIngredient i,
) => sdIngredientQty(l10n, locale, i.asIngredient);

/// The unit chips of the family recipe editor ("g", "thìa canh", "miếng").
String sdIngredientUnitLabel(AppLocalizations l10n, SdIngredientUnit u) =>
    switch (u) {
      SdIngredientUnit.g => 'g',
      SdIngredientUnit.ml => 'ml',
      SdIngredientUnit.tbsp => l10n.sdIngUnitTbsp,
      SdIngredientUnit.tsp => l10n.sdIngUnitTsp,
      SdIngredientUnit.bowl => l10n.sdIngUnitBowl,
      SdIngredientUnit.piece => l10n.sdIngUnitPiece,
    };

/// A nudge in words (D-086 §12 #2: points things out, never blocks).
String sdNudgeText(AppLocalizations l10n, SdNudge n) => switch (n.kind) {
  SdNudgeKind.honey => l10n.sdNudgeHoney,
  SdNudgeKind.tooYoung => l10n.sdNudgeTooYoung(
    n.names.join(', '),
    n.minAgeMonths ?? SdLimits.startMonths,
  ),
  SdNudgeKind.seasoning => l10n.sdNudgeSeasoning(n.names.join(', ')),
  SdNudgeKind.choking => l10n.sdNudgeChoking(n.names.first, n.names.last),
};

/// The common allergens in a family recipe's catalogue foods ("Có trứng").
List<SdAllergen> sdFamilyAllergens(
  SdFamilyRecipe r,
  Map<String, SdFood> foods,
) {
  final found = {for (final id in r.foodIds) ?foods[id]?.allergen};
  return [
    for (final a in SdAllergen.values)
      if (found.contains(a)) a,
  ];
}
