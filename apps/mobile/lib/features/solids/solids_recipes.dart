import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../library/content_models.dart';
import '../library/content_repository.dart';
import '../library/library_routes.dart';
import '../library/library_widgets.dart';
import '../nutrition/nutrition_widgets.dart' show NuBanner;
import 'solids_calc.dart';
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_repository.dart';
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';
import 'solids_suggest.dart';
import 'solids_widgets.dart' show SdTag;

/// Recipes of Ăn dặm (phase C; Figma 5f `314:1987`, 5g `314:2095`; plan §3 #9, #11, §5): the
/// rows of 5f, the recipe page 5g with "Lưu" and "Ghi vào nhật ký", and the list a suggestion's
/// "Xem công thức" opens.

// ---------- Saved recipes (4f "Đã lưu › Ăn dặm") ----------

/// One saved recipe.
typedef SdSavedRecipe = ({String id, DateTime savedAt});

/// Recipes saved by this person: `users/{uid}/savedArticles`, shared with the guides (the Rules
/// accept `rcp_…` ids, D-085), so a saved recipe follows the person to another phone.
final sdSavedRecipesProvider = Provider<List<SdSavedRecipe>>(
  (ref) => [
    for (final s in ref.watch(lbSavedProvider).value ?? const <LbSaved>[])
      if (sdRecipeId(s.id)) (id: s.id, savedAt: s.savedAt ?? DateTime.now()),
  ],
);

/// The saved recipes that are still published, newest save first (4f).
final sdSavedRecipeListProvider =
    Provider<List<({SdRecipe recipe, DateTime savedAt})>>((ref) {
      final byId = {
        for (final r
            in ref.watch(sdRecipesProvider).value?.items ?? const <SdRecipe>[])
          r.id: r,
      };
      return [
        for (final s in ref.watch(sdSavedRecipesProvider))
          if (byId[s.id] case final r?) (recipe: r, savedAt: s.savedAt),
      ];
    });

/// "Lưu" / "Bỏ lưu" with the library's toasts ("Xem" opens 4f on Ăn dặm; "Hoàn tác").
void sdToggleSavedRecipe(BuildContext context, WidgetRef ref, SdRecipe r) {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return;
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final router = GoRouter.of(context);
  final store = ref.read(contentStoreProvider);
  final uid = session.user.uid;
  // As 4e: Firestore applies the write at once (and syncs later offline); a refusal comes later.
  void failed(Object _) =>
      toaster.show(message: l10n.lbSaveFailed, error: true);
  if (ref.read(sdSavedRecipesProvider).any((s) => s.id == r.id)) {
    unawaited(store.unsave(uid, r.id).catchError(failed));
    toaster.show(
      message: l10n.lbUnsavedToast,
      actionLabel: l10n.lbUndo,
      onAction: () =>
          unawaited(store.saveId(uid, r.id, r.revision).catchError(failed)),
    );
  } else {
    unawaited(store.saveId(uid, r.id, r.revision).catchError(failed));
    toaster.show(
      message: l10n.lbSavedToast,
      actionLabel: l10n.lbView,
      onAction: () =>
          unawaited(router.push(LbRoutes.savedFor(LbLibrary.solids))),
    );
  }
}

// ---------- Rows ----------

/// 5f recipe row (Photo 56, the title, "Công thức · 15 phút", chevron) and 4f's saved row
/// ([meta] and a bookmark).
class SdRecipeRow extends StatelessWidget {
  const SdRecipeRow({
    required this.recipe,
    required this.onTap,
    this.meta,
    this.saved,
    this.onBookmark,
    super.key,
  });

  final SdRecipe recipe;
  final VoidCallback onTap;

  /// Defaults to "Công thức · 15 phút".
  final String? meta;

  /// Null = a chevron instead of the bookmark.
  final bool? saved;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final title = recipe.title.of(context);
    final line = meta ?? l10n.sdRecipeMeta(recipe.totalMinutes);
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$title. $line',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            LbPicture(
              image: recipe.cover?.id,
              width: 56,
              height: 56,
              radius: 12,
              topic: LbTopic.feeding,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    line,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (saved == null)
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted)
            else
              ClPressable(
                key: Key('sdRecipeBookmark_${recipe.id}'),
                onPressed: onBookmark,
                selected: saved,
                semanticLabel: saved! ? l10n.lbUnsave : l10n.lbSave,
                child: ClIcon(
                  saved! ? ClIcons.bookmarkFill : ClIcons.bookmark,
                  size: 18,
                  color: saved! ? cl.colors.mintText : cl.colors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 4f row of a saved recipe: "Công thức · lưu 02/10".
class SdSavedRecipeRow extends ConsumerWidget {
  const SdSavedRecipeRow({
    required this.recipe,
    required this.savedAt,
    required this.today,
    super.key,
  });
  final SdRecipe recipe;
  final DateTime savedAt;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final at = savedAt.toLocal();
    final meta = DateUtils.isSameDay(at, today) || at.isAfter(today)
        ? l10n.lbSavedToday(l10n.sdRecipes)
        : l10n.lbSavedOn(
            l10n.sdRecipes,
            DateFormat('dd/MM', locale).format(at),
          );
    return SdRecipeRow(
      key: Key('lbSavedRecipe_${recipe.id}'),
      recipe: recipe,
      meta: meta,
      saved: true,
      onBookmark: () => sdToggleSavedRecipe(context, ref, recipe),
      onTap: () => context.push(SdRoutes.recipe(recipe.id)),
    );
  }
}

// ---------- 5g Công thức ----------

class SdRecipeScreen extends ConsumerWidget {
  const SdRecipeScreen({required this.recipeId, super.key});
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final feed = ref.watch(sdRecipesProvider);
    final recipe = (feed.value?.items ?? const <SdRecipe>[])
        .where((r) => r.id == recipeId)
        .firstOrNull;
    if (recipe == null) {
      return LbPage(
        children: [
          if (!feed.isLoading)
            LbEmpty(
              icon: ClIcons.journal,
              title: l10n.sdRecipeMissing,
              body: l10n.sdRecipeMissingBody,
            ),
        ],
      );
    }
    final foods = {
      for (final f
          in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
        f.id: f,
    };
    final s = ref.watch(sdStateProvider);
    final tracking = s != null && s.tracking && s.me.sdReads;
    final tried = {
      if (tracking)
        for (final t in ref.watch(sdTriedProvider)) t.key: t,
    };
    final cleared = s?.settings.cleared ?? const <String>[];
    final saved = ref.watch(
      sdSavedRecipesProvider.select((l) => l.any((x) => x.id == recipe.id)),
    );
    final allergens = sdContainsLine(l10n, sdRecipeAllergens(recipe, foods));
    final months = s?.months;
    final dob = s?.baby.dob;
    final articles = {
      for (final a
          in ref.watch(lbArticlesProvider).value?.items ?? const <LbArticle>[])
        a.id: a,
    };
    final related = [for (final id in recipe.relatedArticleIds) ?articles[id]];
    final steps = recipe.steps.pick(locale);
    final bottle = cl.care.bottle;

    return LbPage(
      bottom: _RecipeBar(
        saved: saved,
        onSave: () => sdToggleSavedRecipe(context, ref, recipe),
        // "Ghi vào nhật ký" (P-164 #9): 5c with the dish, its catalogue foods and the recipe.
        onLog: tracking && s.me.sdLogs
            ? () => unawaited(
                openMealSheet(
                  context,
                  prefill: SdMealPrefill(
                    dish: _clip(recipe.title.pick(locale), SdLimits.mealDish),
                    foodIds: recipe.foodIds.take(SdLimits.mealFoods).toList(),
                    recipeId: recipe.id,
                  ),
                ),
              )
            : null,
      ),
      children: [
        LbPicture(
          image: recipe.cover?.id,
          alt: recipe.cover?.alt?.of(context),
          width: double.infinity,
          height: 190,
          radius: 22,
          topic: LbTopic.feeding,
        ),
        const SizedBox(height: ClSpace.s4),
        Wrap(
          key: const Key('sdRecipeChips'),
          spacing: 8,
          runSpacing: 8,
          children: [
            LbChip(l10n.sdRecipes, fill: bottle.soft, ink: bottle.ink),
            LbChip(sdRecipeAgeLabel(l10n, recipe)),
            LbChip(l10n.lbMinutesShort(recipe.totalMinutes)),
            LbChip(sdTextureLabel(l10n, recipe.texture)),
            if (recipe.methods.isNotEmpty)
              LbChip(
                [
                  for (final m in SdRecipeMethod.values)
                    if (recipe.methods.contains(m))
                      sdRecipeMethodLabel(l10n, m),
                ].join(' · '),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(
            recipe.title.of(context),
            style: cl.text.largeTitle.copyWith(fontSize: 26, height: 1.25),
          ),
        ),
        if (recipe.summary != null) ...[
          const SizedBox(height: ClSpace.s2),
          Text(
            recipe.summary!.of(context),
            style: cl.text.body.copyWith(
              fontSize: 15,
              height: 1.5,
              color: cl.colors.inkMuted,
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s2),
        Text(
          [
            l10n.sdServings(recipe.servings),
            l10n.sdPrepCook(recipe.prepMinutes, recipe.cookMinutes),
          ].join(' · '),
          key: const Key('sdRecipeServings'),
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cl.colors.inkMuted,
          ),
        ),
        // Plan §5 5g: a notice when the recipe starts above the baby's age.
        if (s != null &&
            months != null &&
            dob != null &&
            recipe.ageFrom > months) ...[
          const SizedBox(height: ClSpace.s3),
          NuBanner(
            key: const Key('sdRecipeAge'),
            text: l10n.sdAgeNotice(
              recipe.ageFrom,
              s.baby.name,
              ageShort(l10n, dob, s.baby.today),
            ),
          ),
        ],
        if (allergens != null) ...[
          const SizedBox(height: ClSpace.s3),
          Container(
            key: const Key('sdRecipeAllergens'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cl.colors.sunshineSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.alert, size: 16, color: cl.colors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allergens,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Container(
          key: const Key('sdRecipeIngredients'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sdIngredients,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final (n, i) in recipe.ingredients.indexed)
                _IngredientRow(
                  key: Key('sdIngredientRow_$n'),
                  ingredient: i,
                  qty: sdIngredientQty(l10n, tag, i),
                  // ✦ "Bé chưa thử" while tracking (P-164 #7); ⚠ for symptoms (#6).
                  notTried:
                      tracking &&
                      i.foodId != null &&
                      !tried.containsKey(i.foodId),
                  signs:
                      i.foodId != null &&
                      (tried[i.foodId]?.flagged ?? false) &&
                      !cleared.contains(i.foodId),
                ),
            ],
          ),
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s6),
          Semantics(
            header: true,
            child: Text(
              l10n.sdSteps,
              style: cl.text.headline.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          for (final (n, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.mintSoft,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      '${n + 1}',
                      style: cl.text.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cl.colors.mintText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: cl.text.body.copyWith(fontSize: 15, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (recipe.storage != null) ...[
          LbSection(l10n.sdStorage),
          Text(
            recipe.storage!.of(context),
            key: const Key('sdRecipeStorage'),
            style: cl.text.body.copyWith(fontSize: 15, height: 1.5),
          ),
        ],
        if (recipe.tip != null) ...[
          LbSection(l10n.sdTip),
          NuBanner(
            key: const Key('sdRecipeTip'),
            text: recipe.tip!.of(context),
            warm: false,
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        // D-082: the footnote until a qualified reviewer signs it, then the reviewer.
        if (recipe.illustrative || recipe.review == null)
          const LbGuidanceNote()
        else
          Row(
            key: const Key('sdRecipeReview'),
            children: [
              ClIcon(ClIcons.check, size: 14, color: cl.colors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lbReviewLabel(l10n, recipe.review!),
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    color: cl.colors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        if (recipe.sources.isNotEmpty) ...[
          LbSection(l10n.lbSources),
          for (final src in recipe.sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '· ${src.label}',
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
        ],
        if (related.isNotEmpty) ...[
          LbSection(l10n.lbRelated),
          LbGroup(
            children: [
              for (final a in related)
                LbArticleRow(
                  key: Key('sdRecipeRelated_${a.id}'),
                  article: a,
                  thumb: 52,
                  meta: l10n.lbMinutesShort(a.readingMinutes),
                  onTap: () => context.push(LbRoutes.articleOf(a.id)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

/// An ingredient: check, the name (and its note), the quantity, and the ✦ / ⚠ marks.
class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.qty,
    required this.notTried,
    required this.signs,
    super.key,
  });

  final SdIngredient ingredient;
  final String? qty;
  final bool notTried;
  final bool signs;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final note = ingredient.note?.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name.of(context),
                  style: cl.text.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                if (notTried || signs) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (notTried)
                        SdTag(
                          l10n.sdNotTriedMark,
                          key: const Key('sdNotTriedMark'),
                          fill: cl.colors.sunshineSoft,
                          ink: cl.colors.ink,
                        ),
                      if (signs)
                        SdTag(
                          l10n.sdSignsMark,
                          key: const Key('sdSignsMark'),
                          fill: cl.colors.errorSoft,
                          ink: cl.colors.error,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (qty != null) ...[
            const SizedBox(width: 8),
            Text(
              qty!,
              style: cl.text.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 5g bar: "Lưu" pill · primary "Ghi vào nhật ký" (who logs, while tracking is on).
class _RecipeBar extends StatelessWidget {
  const _RecipeBar({required this.saved, required this.onSave, this.onLog});
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback? onLog;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final fill = saved ? cl.colors.mintSoft : cl.colors.surface2;
    final ink = saved ? cl.colors.mintText : cl.colors.ink;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        border: Border(top: BorderSide(color: cl.colors.separator)),
      ),
      child: Row(
        children: [
          ClPressable(
            key: const Key('sdRecipeSave'),
            onPressed: onSave,
            selected: saved,
            semanticLabel: saved ? l10n.lbUnsave : l10n.lbSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(
                    saved ? ClIcons.bookmarkFill : ClIcons.bookmark,
                    size: 14,
                    color: ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    saved ? l10n.lbSaved : l10n.lbSave,
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          if (onLog != null)
            Expanded(
              child: ClButton(
                key: const Key('sdRecipeLog'),
                label: l10n.sdLogRecipe,
                icon: ClIcons.plus,
                expand: true,
                onPressed: onLog,
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

// ---------- "Xem công thức" (plan §7) ----------

/// The "Dành cho {bé}" ranking for a card's foods: recipes with one of [foodIds] for the baby's
/// age and method. Without tracking (or an age), the published recipes with those foods.
class SdRecipeListScreen extends ConsumerWidget {
  const SdRecipeListScreen({required this.foodIds, super.key});
  final List<String> foodIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final recipes =
        ref.watch(sdRecipesProvider).value?.items ?? const <SdRecipe>[];
    final foods = {
      for (final f
          in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
        f.id: f,
    };
    final s = ref.watch(sdStateProvider);
    final wanted = foodIds.toSet();
    final List<SdRecipe> list;
    if (s != null && s.tracking && s.months != null) {
      list = sdRecipesFor(
        recipes: recipes,
        months: s.months!,
        settings: s.settings,
        foods: foods,
        tried: {for (final t in ref.watch(sdTriedProvider)) t.key: t},
        suggested: wanted,
      );
    } else {
      list = [
        for (final r in recipes)
          if (r.foodIds.any(wanted.contains)) r,
      ];
    }
    final names = sdOrList(l10n, [
      for (final id in foodIds.take(3)) sdFoodName(id, foods, locale),
    ]);
    return LbPage(
      children: [
        LbTitle(l10n.sdRecipesWith(names)),
        const SizedBox(height: ClSpace.s4),
        if (list.isEmpty)
          LbEmpty(
            icon: ClIcons.search,
            title: l10n.sdRecipesNone,
            body: l10n.sdRecipesWithNone,
          )
        else
          LbGroup(
            children: [
              for (final r in list)
                SdRecipeRow(
                  key: Key('sdRecipe_${r.id}'),
                  recipe: r,
                  onTap: () => context.push(SdRoutes.recipe(r.id)),
                ),
            ],
          ),
      ],
    );
  }
}
