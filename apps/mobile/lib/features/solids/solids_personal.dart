import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart' show isoDate;
import '../library/content_models.dart';
import '../library/content_repository.dart';
import '../library/library_routes.dart';
import '../nutrition/nutrition_format.dart' show nuAgeLabel;
import '../nutrition/nutrition_models.dart' show NuStage;
import '../nutrition/nutrition_state.dart';
import '../nutrition/nutrition_widgets.dart' show NuSection;
import 'solids_calc.dart';
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_repository.dart';
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';
import 'solids_suggest.dart';

/// "Gợi ý cho {bé}" on the screens (plan §7, phase D): the device's own state (snoozes, the stage
/// last opened), the cards in words, their one action and the feedback ("Để sau", "Không gợi ý
/// món này"), the 5b section and "Dành cho {bé}". Free for every family (D-085 #1). Everything
/// stays on the device: no meal data leaves it for this and nothing goes to analytics.

/// S1 "Đọc: Nhận biết phản ứng" and S9 "Đọc hướng dẫn" (solids guides, `solids-seed.ts`); the
/// library opens instead while they are not published.
const sdReactionsArticle = 'art_solids_reactions';
const sdTexturesArticle = 'art_solids_textures_by_month';

// ---------- On this device ----------

/// "Để sau" (cards) and a caregiver's "Không gợi ý món này" (foods), per baby: key → the day the
/// snooze ends. Kept on the device only (plan §4).
typedef SdSnoozes = ({
  Map<String, DateTime> cards,
  Map<String, DateTime> foods,
});

final sdSnoozesProvider =
    NotifierProvider.family<SdSnoozesNotifier, SdSnoozes, String>(
      SdSnoozesNotifier.new,
    );

class SdSnoozesNotifier extends Notifier<SdSnoozes> {
  SdSnoozesNotifier(this.babyId);
  final String babyId;

  String get _key => 'solids.snooze.$babyId';

  @override
  SdSnoozes build() {
    Map<String, DateTime> days(Object? v) => {
      if (v is Map)
        for (final e in v.entries)
          if (e.key is String && DateTime.tryParse('${e.value}') != null)
            e.key as String: DateTime.parse('${e.value}'),
    };
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      final j = raw == null ? const {} : jsonDecode(raw) as Map;
      return (cards: days(j['cards']), foods: days(j['foods']));
    } on Object {
      return (cards: const {}, foods: const {});
    }
  }

  /// "Để sau": [sdSnoozeDays] from [today].
  void snoozeCard(String key, DateTime today) => _write((
    cards: {...state.cards, key: _plus(today, sdSnoozeDays)},
    foods: state.foods,
  ), today);

  /// A caregiver's "Không gợi ý món này": [sdFoodSnoozeDays] from [today].
  void snoozeFood(String foodId, DateTime today) => _write((
    cards: state.cards,
    foods: {...state.foods, foodId: _plus(today, sdFoodSnoozeDays)},
  ), today);

  static DateTime _plus(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  void _write(SdSnoozes next, DateTime today) {
    // Ended snoozes are dropped.
    Map<String, String> live(Map<String, DateTime> m) => {
      for (final e in m.entries)
        if (e.value.isAfter(today)) e.key: isoDate(e.value),
    };
    state = next;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(
            _key,
            jsonEncode({'cards': live(next.cards), 'foods': live(next.foods)}),
          ),
    );
  }
}

/// The Dinh dưỡng stage last opened with the suggestions on this device (S9), per baby.
final sdStageSeenProvider =
    NotifierProvider.family<SdStageSeenNotifier, SdStageSeen?, String>(
      SdStageSeenNotifier.new,
    );

class SdStageSeenNotifier extends Notifier<SdStageSeen?> {
  SdStageSeenNotifier(this.babyId);
  final String babyId;

  String get _key => 'solids.stage.$babyId';

  @override
  SdStageSeen? build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map;
      final on = DateTime.tryParse('${j['on']}');
      if (j['id'] is! String || on == null) return null;
      return (id: j['id'] as String, on: on, fresh: j['fresh'] == true);
    } on Object {
      return null;
    }
  }

  void visit(String stageId, DateTime today) {
    final next = sdStageVisit(state, stageId, today);
    if (next == state) return;
    state = next;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(
            _key,
            jsonEncode({
              'id': next.id,
              'on': isoDate(next.on),
              'fresh': next.fresh,
            }),
          ),
    );
  }
}

// ---------- The cards ----------

/// The engine's cards for the selected baby (tracking on, a member who reads the diary, a known
/// age). Recomputed on open and after each saved meal (the meals stream).
final sdCardsProvider = Provider<List<SdCard>>((ref) {
  final s = ref.watch(sdStateProvider);
  if (s == null || !s.tracking || !s.me.sdReads || s.months == null) {
    return const [];
  }
  final b = s.baby;
  final today = b.today;
  final snoozes = ref.watch(sdSnoozesProvider(b.babyId));
  final stage = ref.watch(nuContentProvider)?.stage;
  String? newStage;
  if (stage != null && stage.solids?.texture != null) {
    final seen = ref.watch(sdStageSeenProvider(b.babyId));
    final next = sdStageVisit(seen, stage.id, today);
    if (next != seen) {
      // Remember the stage once these suggestions have been worked out (S9 "first open").
      Future.microtask(() {
        if (ref.mounted) {
          ref
              .read(sdStageSeenProvider(b.babyId).notifier)
              .visit(stage.id, today);
        }
      });
    }
    if (sdStageStep(next, stage.id, today)) newStage = stage.id;
  }
  return sdSuggest(
    SdSuggestInput(
      months: s.months!,
      today: today,
      zone: b.zone,
      settings: s.settings,
      meals: s.meals,
      foods: s.foods,
      snoozed: sdActiveSnoozes(snoozes.cards, today),
      snoozedFoods: sdActiveSnoozes(snoozes.foods, today),
      newStageId: newStage,
    ),
  );
});

/// A card in words: the title, the "vì sao" line and the action label.
@immutable
class SdSuggestion {
  const SdSuggestion({
    required this.card,
    required this.title,
    required this.why,
    required this.action,
  });

  final SdCard card;
  final String title;
  final String why;
  final String action;

  /// [SdCard.key].
  String get id => card.key;

  /// The top card (at most one); 5h shows its title as a second line.
  bool get primary => card.primary;

  /// Cards about foods offer "Không gợi ý món này" (S2–S7).
  bool get canHide =>
      card.foodIds.isNotEmpty &&
      card.rule != SdRule.s8 &&
      card.rule != SdRule.s1;
}

/// "Gợi ý cho {bé} hôm nay" in [languageCode] (5b top slot, the 5h second line): hidden while
/// empty.
final sdSuggestionsProvider = Provider.family<List<SdSuggestion>, String>((
  ref,
  languageCode,
) {
  final cards = ref.watch(sdCardsProvider);
  if (cards.isEmpty) return const [];
  final s = ref.watch(sdStateProvider)!;
  final locale = Locale(languageCode == 'en' ? 'en' : 'vi');
  final l10n = lookupAppLocalizations(locale);
  final stage = ref.watch(nuContentProvider)?.stage;
  return [for (final c in cards) _words(l10n, locale, s, c, stage)];
});

SdSuggestion _words(
  AppLocalizations l10n,
  Locale locale,
  SdState s,
  SdCard c,
  NuStage? stage,
) {
  final tag = locale.toLanguageTag();
  final name = s.baby.name;
  String food(String id) => sdFoodName(id, s.foods, locale);
  String lower(String id) => food(id).toLowerCase();
  String foods({bool ironMark = false}) => sdOrList(l10n, [
    for (final id in c.foodIds.take(3))
      ironMark && (s.foods[id]?.ironRich ?? false)
          ? l10n.sdIronMark(food(id))
          : food(id),
  ]);
  String date() => c.date == null ? '' : sdShortDate(tag, c.date!);
  String group() => sdGroupLabel(l10n, c.group).toLowerCase();
  final (title, why, action) = switch (c.rule) {
    SdRule.s1 => () {
      final meal = s.meals.where((m) => m.id == c.mealId).firstOrNull;
      final fresh = meal == null
          ? const <String>{}
          : sdFirstTryIds(meal, s.meals);
      final about = meal == null
          ? const <String>[]
          : fresh.isNotEmpty
          ? [
              for (final id in meal.foodIds)
                if (fresh.contains(id)) food(id),
            ]
          : [for (final id in meal.foodIds) food(id), ...meal.freeFoods];
      return (
        about.isEmpty
            ? l10n.sdS1TitlePlain(date())
            : l10n.sdS1Title(date(), about.join(', ')),
        l10n.sdS1Why(date()),
        l10n.sdActReadReactions,
      );
    }(),
    SdRule.s2 => (
      l10n.sdS2Title(name, foods(ironMark: true)),
      l10n.sdS2Why(name, c.count),
      l10n.sdLogMeal,
    ),
    SdRule.s3 => (
      l10n.sdS3Title(sdAllergenTry(l10n, c.allergen!)),
      l10n.sdS3Why(name, c.count, c.days),
      l10n.sdActRecipes,
    ),
    SdRule.s4 => (
      l10n.sdS4Title(name, sdAllergenLabel(l10n, c.allergen!)),
      l10n.sdS4Why(sdAllergenLabel(l10n, c.allergen!), date()),
      l10n.sdLogMeal,
    ),
    SdRule.s5 => (
      l10n.sdS5Title(foods()),
      l10n.sdS5Why(name),
      l10n.sdActRecipes,
    ),
    SdRule.s6 => (
      l10n.sdS6Title(foods()),
      l10n.sdS6Why(name, group(), c.count),
      l10n.sdLogMeal,
    ),
    SdRule.s7 => (
      c.likedFoodId == null
          ? l10n.sdS7TitlePlain(lower(c.foodIds.first))
          : l10n.sdS7Title(lower(c.foodIds.first), lower(c.likedFoodId!), name),
      l10n.sdS7Why(name, lower(c.foodIds.first), c.count),
      l10n.sdLogMeal,
    ),
    SdRule.s8 => (
      l10n.sdS8Title(name, group()),
      l10n.sdS8Why(group(), date()),
      l10n.sdActIdeas,
    ),
    SdRule.s9 => (
      l10n.sdS9Title(
        name,
        s.months ?? 0,
        stage?.solids?.texture?.pick(locale) ?? '',
      ),
      l10n.sdS9Why(name, stage == null ? '' : nuAgeLabel(l10n, stage.age)),
      l10n.sdActGuide,
    ),
  };
  return SdSuggestion(card: c, title: title, why: why, action: action);
}

/// "Dành cho {bé}" (plan §7 Recipes, 5f): the ranked recipes while tracking is on.
final sdForBabyProvider = Provider<List<SdRecipe>>((ref) {
  final s = ref.watch(sdStateProvider);
  if (s == null || !s.tracking || !s.me.sdReads || s.months == null) {
    return const [];
  }
  final recipes =
      ref.watch(sdRecipesProvider).value?.items ?? const <SdRecipe>[];
  if (recipes.isEmpty) return const [];
  final snoozes = ref.watch(sdSnoozesProvider(s.baby.babyId));
  return sdRecipesFor(
    recipes: recipes,
    months: s.months!,
    settings: s.settings,
    foods: s.foods,
    tried: {for (final t in ref.watch(sdTriedProvider)) t.key: t},
    snoozedFoods: sdActiveSnoozes(snoozes.foods, s.baby.today),
  );
});

// ---------- Actions and feedback ----------

/// The card's one action.
Future<void> sdRunSuggestion(
  BuildContext context,
  WidgetRef ref,
  SdSuggestion suggestion,
) async {
  final c = suggestion.card;
  void read(String articleId) {
    final published =
        ref
            .read(lbArticlesProvider)
            .value
            ?.items
            .any((a) => a.id == articleId && a.library == LbLibrary.solids) ??
        false;
    unawaited(
      context.push(
        published ? LbRoutes.articleOf(articleId) : SdRoutes.library,
      ),
    );
  }

  switch (c.action) {
    case SdCardAction.readReactions:
      read(sdReactionsArticle);
    case SdCardAction.readTextures:
      read(sdTexturesArticle);
    case SdCardAction.logMeal:
      await openMealSheet(context, prefill: SdMealPrefill(foodIds: c.prefill));
    case SdCardAction.viewRecipes:
      // One recipe opens itself; otherwise the ranked list for these foods.
      // Kept alive while it loads (5b watches it while such a card shows).
      final keep = ref.listenManual(sdRecipesProvider, (_, _) {});
      final List<SdRecipe> published;
      try {
        published =
            ref.read(sdRecipesProvider).value?.items ??
            (await ref
                    .read(sdRecipesProvider.future)
                    .timeout(
                      const Duration(seconds: 3),
                      onTimeout: () =>
                          (items: const <SdRecipe>[], fromCache: true),
                    ))
                .items;
      } finally {
        keep.close();
      }
      if (!context.mounted) return;
      final s = ref.read(sdStateProvider);
      final recipes = s == null || s.months == null
          ? const <SdRecipe>[]
          : sdRecipesFor(
              recipes: published,
              months: s.months!,
              settings: s.settings,
              foods: s.foods,
              tried: {for (final t in ref.read(sdTriedProvider)) t.key: t},
              suggested: c.foodIds.toSet(),
            );
      unawaited(
        context.push(
          recipes.length == 1
              ? SdRoutes.recipe(recipes.single.id)
              : SdRoutes.recipesFor(c.foodIds),
        ),
      );
    case SdCardAction.viewIdeas:
      final id = await showClSheet<String>(
        context: context,
        builder: (_) => _IdeasSheet(card: c),
      );
      if (id != null && context.mounted) {
        await openMealSheet(context, prefill: SdMealPrefill(foodIds: [id]));
      }
  }
}

/// "Để sau": this card stays hidden on this device for 3 days.
void sdSnoozeSuggestion(
  BuildContext context,
  WidgetRef ref,
  SdSuggestion suggestion,
) {
  final s = ref.read(sdStateProvider);
  if (s == null) return;
  ref
      .read(sdSnoozesProvider(s.baby.babyId).notifier)
      .snoozeCard(suggestion.id, s.baby.today);
  ClToaster.of(
    context,
  ).show(message: AppLocalizations.of(context).sdSuggestSnoozed);
}

/// "Không gợi ý món này": a Cùng nuôi adds the food to `hidden` (settings); a caregiver snoozes
/// it on this device (P-164 #13). A card with several foods asks which one.
Future<void> sdHideSuggested(
  BuildContext context,
  WidgetRef ref,
  SdSuggestion suggestion,
) async {
  final s = ref.read(sdStateProvider);
  if (s == null) return;
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final toaster = ClToaster.of(context);
  final ids = suggestion.card.foodIds;
  final id = ids.length == 1
      ? ids.single
      : await showClSheet<String>(
          context: context,
          builder: (_) => _HideSheet(foodIds: ids),
        );
  if (id == null) return;
  final name = sdFoodName(id, s.foods, locale);
  if (s.me.sdManages) {
    if (!s.settings.hidden.contains(id)) {
      ref
          .read(solidsStoreProvider)
          .saveSettings(
            s.baby.babyId,
            s.settings.copyWith(hidden: [...s.settings.hidden, id]),
            s.me.uid,
            onError: (_) =>
                toaster.show(message: l10n.careSaveFailed, error: true),
          );
    }
    toaster.show(message: l10n.sdSuggestHidden(name));
  } else {
    ref
        .read(sdSnoozesProvider(s.baby.babyId).notifier)
        .snoozeFood(id, s.baby.today);
    toaster.show(message: l10n.sdSuggestSnoozedFood(name));
  }
}

// ---------- 5b section ----------

/// 5b "Gợi ý cho {bé} hôm nay": 1 primary card and up to 2 smaller ones; nothing while there is
/// nothing to say.
class SdSuggestionsSection extends ConsumerWidget {
  const SdSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final items = ref.watch(sdSuggestionsProvider(lang));
    final s = ref.watch(sdStateProvider);
    if (items.isEmpty || s == null) return const SizedBox.shrink();
    // "Xem công thức" ranks the published recipes: keep them at hand.
    if (items.any((c) => c.card.action == SdCardAction.viewRecipes)) {
      ref.watch(sdRecipesProvider);
    }
    return Column(
      key: const Key('sdSuggestions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NuSection(l10n.sdSuggestionsTitle(s.baby.name)),
        for (final c in items) ...[
          SdSuggestionCard(suggestion: c),
          const SizedBox(height: ClSpace.s2),
        ],
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// One card: an icon, the title, the "vì sao" line, the action, "Để sau" and (for foods)
/// "Không gợi ý món này". The primary card is larger.
class SdSuggestionCard extends ConsumerWidget {
  const SdSuggestionCard({required this.suggestion, super.key});
  final SdSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final c = suggestion.card;
    final primary = suggestion.primary;
    // Người thân read the diary but do not log (P-164 #13): no "Ghi bữa" for them.
    final logs = ref.watch(sdStateProvider)?.me.sdLogs ?? false;
    final acts =
        logs ||
        (c.action != SdCardAction.logMeal &&
            c.action != SdCardAction.viewIdeas);
    // Night care: ink on the soft warm fills, error text on error-soft (memory notes).
    final (icon, fill, ink) = switch (c.rule) {
      SdRule.s1 => (ClIcons.alert, cl.colors.errorSoft, cl.colors.error),
      SdRule.s2 ||
      SdRule.s6 => (ClIcons.spark, cl.colors.sunshineSoft, cl.colors.ink),
      SdRule.s3 ||
      SdRule.s4 => (ClIcons.star, cl.colors.mintSoft, cl.colors.mintText),
      SdRule.s5 => (ClIcons.heart, cl.care.bottle.soft, cl.care.bottle.ink),
      SdRule.s7 => (ClIcons.retry, cl.colors.surface2, cl.colors.ink),
      SdRule.s8 => (ClIcons.grid, cl.colors.mintSoft, cl.colors.mintText),
      SdRule.s9 => (ClIcons.journal, cl.care.bottle.soft, cl.care.bottle.ink),
    };
    Widget link(Key key, String label, VoidCallback onTap) => ClPressable(
      key: key,
      onPressed: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          label,
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cl.colors.inkMuted,
          ),
        ),
      ),
    );
    return Container(
      key: Key('sdSuggestion_${c.key}'),
      padding: EdgeInsets.fromLTRB(16, primary ? 16 : 12, 16, 6),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(primary ? 20 : 16),
        boxShadow: primary ? cl.shadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: primary ? 34 : 28,
                height: primary ? 34 : 28,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(primary ? 12 : 10),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: primary ? 18 : 15, color: ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: primary ? 16 : 14,
                        fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.why,
                      key: Key('sdWhy_${c.key}'),
                      style: cl.text.caption.copyWith(
                        fontSize: primary ? 13 : 12,
                        height: 1.45,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              if (acts)
                ClPressable(
                  key: Key('sdSuggestionAction_${c.key}'),
                  onPressed: () =>
                      unawaited(sdRunSuggestion(context, ref, suggestion)),
                  semanticLabel: suggestion.action,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primary ? cl.colors.mintDeep : cl.colors.mintSoft,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      suggestion.action,
                      style: cl.text.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primary
                            ? cl.colors.onMintDeep
                            : cl.colors.mintText,
                      ),
                    ),
                  ),
                ),
              link(
                Key('sdSuggestionLater_${c.key}'),
                l10n.sdSuggestLater,
                () => sdSnoozeSuggestion(context, ref, suggestion),
              ),
              if (suggestion.canHide)
                link(
                  Key('sdSuggestionHide_${c.key}'),
                  l10n.sdHide,
                  () => unawaited(sdHideSuggested(context, ref, suggestion)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Không gợi ý món nào?": the card's foods.
class _HideSheet extends ConsumerWidget {
  const _HideSheet({required this.foodIds});
  final List<String> foodIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final foods = ref.watch(sdStateProvider)?.foods ?? const <String, SdFood>{};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.sdSuggestHideWhich),
        for (final id in foodIds)
          ClPressable(
            key: Key('sdHideFood_$id'),
            onPressed: () => Navigator.of(context).pop(id),
            semanticLabel: sdFoodName(id, foods, locale),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sdFoodName(id, foods, locale),
                      style: cl.text.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ClIcon(ClIcons.close, size: 16, color: cl.colors.inkMuted),
                ],
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s3),
      ],
    );
  }
}

/// S8 "Xem gợi ý": foods of the group, liked first; a tap logs a meal with it.
class _IdeasSheet extends ConsumerWidget {
  const _IdeasSheet({required this.card});
  final SdCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final foods = ref.watch(sdStateProvider)?.foods ?? const <String, SdFood>{};
    final tried = {for (final t in ref.watch(sdTriedProvider)) t.key: t};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.sdIdeasTitle(sdGroupLabel(l10n, card.group))),
        Text(
          l10n.sdIdeasHint,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: 8),
        for (final id in card.foodIds)
          ClPressable(
            key: Key('sdIdea_$id'),
            onPressed: () => Navigator.of(context).pop(id),
            semanticLabel: sdFoodName(id, foods, locale),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sdFoodName(id, foods, locale),
                          style: cl.text.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          switch (tried[id]) {
                            null => l10n.sdNotTried,
                            SdTried(latestReaction: final r?) =>
                              l10n.sdTriedReaction(sdReactionLabel(l10n, r)),
                            _ => l10n.sdTried,
                          },
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText),
                ],
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s3),
      ],
    );
  }
}
