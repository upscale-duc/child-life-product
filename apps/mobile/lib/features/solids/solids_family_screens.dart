import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show authorLabel;
import '../family/family_labels.dart' show relationLabel;
import '../library/library_widgets.dart';
import '../nutrition/nutrition_widgets.dart';
import '../vaccines/vaccine_photos.dart'
    show VaccinePhotoStore, vaccinePhotoStoreProvider;
import 'solids_calc.dart';
import 'solids_family.dart';
import 'solids_format.dart';
import 'solids_history.dart' show SdMealRow;
import 'solids_models.dart';
import 'solids_photos.dart';
import 'solids_recipes.dart' show SdIngredientRow, SdRecipeSteps;
import 'solids_repository.dart';
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';
import 'solids_widgets.dart';

/// "Công thức nhà mình" on the screens (D-086; plan §12 #1, #2): the dishes-made block of a recipe
/// page, the family recipe page (5g's layout without the editorial footnote, with "Sửa", "Xoá" and
/// "Ghi vào nhật ký"), the editor, the 5f "Nhà mình" section, the 4f section and the 5c "Món nhà
/// mình" chips. Roles as meals (P-164 #13): Cùng nuôi and Người chăm sóc add; the writer or a Cùng
/// nuôi edits and deletes; relatives with daily-care rights read. Child data: nothing logged.

// ---------- Dishes made (D-086 §12 #1) ----------

/// "Nhà mình đã làm 3 lần · gần nhất 07/10 · Na thích" under a recipe's title (5g, a family
/// recipe); nothing until a meal is logged from it (or while tracking is off).
class SdDishesMadeLine extends ConsumerWidget {
  const SdDishesMadeLine({required this.recipeId, super.key});
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.tracking || !s.me.sdReads) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final line = sdMadeLine(
      l10n,
      tag,
      sdDishesMade(s.meals, recipeId),
      s.baby.zone,
      s.baby.name,
    );
    if (line == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Container(
        key: const Key('sdMade'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClIcon(ClIcons.check, size: 16, color: cl.colors.mintText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                key: const Key('sdMadeLine'),
                style: cl.text.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.mintText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Các lần đã làm": the meals cooked from a recipe, newest first, 5 at a time; a row opens the
/// meal.
class SdDishesMadeList extends ConsumerStatefulWidget {
  const SdDishesMadeList({required this.recipeId, super.key});
  final String recipeId;

  @override
  ConsumerState<SdDishesMadeList> createState() => _SdDishesMadeListState();
}

class _SdDishesMadeListState extends ConsumerState<SdDishesMadeList> {
  static const _page = 5;
  int _shown = _page;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.tracking || !s.me.sdReads) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final made = sdDishesMade(s.meals, widget.recipeId).meals;
    if (made.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('sdMadeList'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LbSection(l10n.sdMadeTitle),
        NuGroup(
          inset: 74,
          children: [
            for (final m in made.take(_shown))
              SdMealRow(meal: m, foods: s.foods, myUid: s.me.uid, dated: true),
          ],
        ),
        if (made.length > _shown)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s3),
            child: ClButton(
              key: const Key('sdMadeMore'),
              label: l10n.sdShowMore,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () => setState(() => _shown += _page),
            ),
          ),
      ],
    );
  }
}

// ---------- Rows, sections, chips ----------

/// The family recipe's picture: its photo, else its main ingredient's icon and tint (D-087).
class _FamilyThumb extends ConsumerWidget {
  const _FamilyThumb({required this.recipe});
  final SdFamilyRecipe recipe;
  static const double size = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = recipe.photoPath;
    if (photo != null) {
      return SdPhotoTile(path: photo, size: size, open: false);
    }
    final look = sdFamilyRecipeLook(
      context,
      recipe,
      ref.watch(sdFoodsByIdProvider),
    );
    return Container(
      key: Key('sdFamilyThumb_${recipe.id}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: look.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: ClIcon(look.icon, size: size * 0.42, color: look.ink),
    );
  }
}

/// "Nhà mình" tag (D-086 §12 #4).
class SdFamilyTag extends StatelessWidget {
  const SdFamilyTag({super.key});

  @override
  Widget build(BuildContext context) => SdTag(
    AppLocalizations.of(context).sdFamily,
    key: const Key('sdFamilyTag'),
    fill: context.cl.colors.mintSoft,
    ink: context.cl.colors.mintText,
  );
}

/// A family recipe row (5f "Nhà mình", "Dành cho {bé}", 4f, "Xem công thức"): picture 56, the
/// title with the "Nhà mình" tag, "đã làm 3 lần · 4 nguyên liệu", chevron.
class SdFamilyRecipeRow extends ConsumerWidget {
  const SdFamilyRecipeRow({
    required this.recipe,
    required this.onTap,
    super.key,
  });
  final SdFamilyRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(sdStateProvider);
    final made = s == null || !s.tracking
        ? 0
        : sdDishesMade(s.meals, recipe.id).meals.length;
    final meta = [
      if (made > 0) l10n.sdFamilyMade(made),
      l10n.sdFamilyIngredientsCount(recipe.ingredients.length),
      if (recipe.pending) l10n.carePending,
    ].join(' · ');
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '${recipe.title}. ${l10n.sdFamily}. $meta',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _FamilyThumb(recipe: recipe),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SdFamilyTag(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: recipe.pending
                          ? cl.colors.pending
                          : cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// 5f "Nhà mình" (D-086 §12 #2): the family's recipes first (3, then "Xem tất cả"), matching
/// [query]; "Thêm" for who logs. With none yet, the "Thêm công thức nhà mình" card.
class SdFamilyLibrarySection extends ConsumerStatefulWidget {
  const SdFamilyLibrarySection({
    required this.query,
    this.foods = const {},
    super.key,
  });
  final String query;
  final Map<String, SdFood> foods;

  @override
  ConsumerState<SdFamilyLibrarySection> createState() =>
      _SdFamilyLibrarySectionState();
}

class _SdFamilyLibrarySectionState
    extends ConsumerState<SdFamilyLibrarySection> {
  static const _preview = 3;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.me.sdReads) return const SizedBox.shrink();
    final family = ref.watch(sdFamilyListProvider);
    final searching = widget.query.trim().isNotEmpty;
    final logs = s.me.sdLogs;
    if (family.isEmpty) {
      if (!logs || searching) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(top: ClSpace.s4),
        child: _AddFamilyCard(),
      );
    }
    final list = sdSearchFamily(family, widget.query, foods: widget.foods);
    if (list.isEmpty) return const SizedBox.shrink();
    final shown = _all || searching ? list : list.take(_preview).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: ClSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.sdFamily,
                    style: cl.text.headline.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (logs)
                ClPressable(
                  key: const Key('sdFamilyAdd'),
                  onPressed: () => context.push(SdRoutes.familyNew),
                  semanticLabel: l10n.sdFamilyAdd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClIcon(ClIcons.plus, size: 14, color: cl.colors.mintText),
                      const SizedBox(width: 4),
                      Text(
                        l10n.sdFamilyAddShort,
                        style: cl.text.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cl.colors.mintText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        LbGroup(
          key: const Key('sdFamily'),
          children: [
            for (final r in shown)
              SdFamilyRecipeRow(
                key: Key('sdFamily_${r.id}'),
                recipe: r,
                onTap: () => context.push(SdRoutes.recipe(r.id)),
              ),
            if (shown.length < list.length)
              ClPressable(
                key: const Key('sdFamilyAll'),
                onPressed: () => setState(() => _all = true),
                semanticLabel: l10n.sdFamilyAll(list.length),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.sdFamilyAll(list.length),
                    textAlign: TextAlign.center,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Thêm công thức nhà mình" (5f, before the family has any).
class _AddFamilyCard extends StatelessWidget {
  const _AddFamilyCard();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('sdFamilyAdd'),
      onPressed: () => context.push(SdRoutes.familyNew),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '${l10n.sdFamilyAdd}. ${l10n.sdFamilyAddBody}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            NuIconChip(
              icon: ClIcons.plus,
              fill: cl.colors.sunshineSoft,
              ink: cl.colors.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sdFamilyAdd,
                    style: cl.text.bodyStrong.copyWith(fontSize: 15),
                  ),
                  Text(
                    l10n.sdFamilyAddBody,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// 4f "Đã lưu › Ăn dặm": the selected baby's family recipes under "Nhà mình" (D-086).
class SdFamilySavedSection extends ConsumerWidget {
  const SdFamilySavedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(sdFamilyListProvider);
    if (family.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('lbSavedFamily'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s3),
          child: Semantics(
            header: true,
            child: Text(
              l10n.sdFamily,
              style: context.cl.text.headline.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        LbGroup(
          children: [
            for (final r in family)
              SdFamilyRecipeRow(
                key: Key('lbSavedFamily_${r.id}'),
                recipe: r,
                onTap: () => context.push(SdRoutes.recipe(r.id)),
              ),
          ],
        ),
      ],
    );
  }
}

/// 5c "Món nhà mình" (D-086): recent family recipes, one tap fills the meal and keeps the
/// recipe's id; nothing while the family has none.
class SdFamilyChips extends ConsumerWidget {
  const SdFamilyChips({
    required this.selected,
    required this.onPick,
    super.key,
  });

  /// The meal's `recipeId`.
  final String? selected;
  final ValueChanged<SdFamilyRecipe> onPick;

  /// Chips shown (recently made first).
  static const max = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(sdFamilyListProvider);
    if (family.isEmpty) return const SizedBox.shrink();
    final meals = ref.watch(sdStateProvider)?.meals ?? const <SdMeal>[];
    final recent = sdRecentFamily(family, meals).take(max).toList();
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('sdFamilyChips'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SdLabel(l10n.sdFamilyChips),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (i, r) in recent.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                SdPill(
                  r.title,
                  key: Key('sdFamilyChip_${r.id}'),
                  selected: r.id == selected,
                  soft: true,
                  onTap: () => onPick(r),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// The nudges (D-086 §12 #2): honey under 12 months, a food usually given later, added
/// seasonings, choking notes. Points things out, never blocks.
class SdNudgeCard extends StatelessWidget {
  const SdNudgeCard({required this.nudges, super.key});
  final List<SdNudge> nudges;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('sdNudges'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.alert, size: 16, color: cl.colors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.sdNudgeTitle,
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cl.colors.ink,
                  ),
                ),
              ),
            ],
          ),
          for (final (i, n) in nudges.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '· ${sdNudgeText(l10n, n)}',
                key: Key('sdNudge_${n.kind.name}_$i'),
                style: cl.text.label.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: cl.colors.ink,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.sdNudgeFooter,
            style: cl.text.caption.copyWith(
              fontSize: 12,
              height: 1.4,
              color: cl.colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- The family recipe page ----------

/// A family recipe (D-086 §12 #2): the 5g layout without the editorial footnote. The photo, the
/// title and who added it, the dishes made, the nudges, the allergen line, the ingredients (✦ Bé
/// chưa thử, ⚠ Có dấu hiệu), the steps and the note; "Sửa" and "Xoá" for the writer or a Cùng
/// nuôi, "Ghi vào nhật ký" for who logs while tracking is on.
class SdFamilyRecipeScreen extends ConsumerWidget {
  const SdFamilyRecipeScreen({required this.recipeId, super.key});
  final String recipeId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SdFamilyRecipe recipe,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sdFamilyDeleteTitle),
          Text(
            l10n.sdFamilyDeleteBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            key: const Key('sdFamilyDeleteConfirm'),
            label: l10n.sdFamilyDelete,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final s = ref.read(sdStateProvider);
    if (s == null || !s.me.sdEditsRecipe(recipe)) return;
    final repo = ref.read(solidsStoreProvider);
    final toaster = ClToaster.of(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    repo.softDeleteFamilyRecipe(recipe, s.me.uid, onError: failed);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(SdRoutes.library);
    }
    toaster.show(
      message: l10n.sdFamilyDeletedToast,
      actionLabel: l10n.undo,
      visibleFor: const Duration(seconds: 5),
      onAction: () =>
          repo.restoreFamilyRecipe(recipe, s.me.uid, onError: failed),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    final recipe = ref
        .watch(sdFamilyListProvider)
        .where((r) => r.id == recipeId)
        .firstOrNull;
    if (s == null || recipe == null) {
      final loading =
          s != null &&
          s.me.sdReads &&
          ref.watch(sdFamilyRecipesProvider(s.baby.babyId)).isLoading;
      return LbPage(
        children: [
          if (!loading)
            LbEmpty(
              icon: ClIcons.journal,
              title: l10n.sdRecipeMissing,
              body: l10n.sdFamilyMissingBody,
            ),
        ],
      );
    }
    final foods = {
      for (final f
          in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
        f.id: f,
    };
    final tracking = s.tracking && s.me.sdReads;
    final tried = {
      if (tracking)
        for (final t in ref.watch(sdTriedProvider)) t.key: t,
    };
    final editable = s.me.sdEditsRecipe(recipe);
    final logs = tracking && s.me.sdLogs;
    final nudges = sdFamilyNudges(
      ingredients: recipe.ingredients,
      foods: foods,
      months: s.months,
      title: recipe.title,
      steps: recipe.steps,
      note: recipe.note,
      locale: locale,
    );
    final allergens = sdContainsLine(l10n, sdFamilyAllergens(recipe, foods));
    final who = [
      l10n.sdFamilyAddedBy(
        authorLabel(
          l10n,
          recipe.author,
          isMe: recipe.createdBy == s.me.uid,
          relationLabel: (r, c) => relationLabel(l10n, r, c),
        ),
      ),
      if (recipe.pending) l10n.carePending,
    ].join(' · ');
    final bottle = cl.care.bottle;

    return LbPage(
      trailing: editable
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LbRoundButton(
                  key: const Key('sdFamilyDelete'),
                  icon: ClIcons.trash,
                  label: l10n.sdFamilyDelete,
                  onPressed: () => unawaited(_delete(context, ref, recipe)),
                ),
                const SizedBox(width: ClSpace.s2),
                LbPillButton(
                  key: const Key('sdFamilyEdit'),
                  icon: ClIcons.edit,
                  label: l10n.actionEdit,
                  onPressed: () => context.push(SdRoutes.familyEdit(recipe.id)),
                ),
              ],
            )
          : null,
      // "Ghi vào nhật ký": 5c with the dish, the ingredients and the recipe's id.
      bottom: logs
          ? _LogBar(
              onLog: () {
                final fill = sdFamilyMealFill(recipe);
                unawaited(
                  openMealSheet(
                    context,
                    prefill: SdMealPrefill(
                      dish: fill.dish,
                      foodIds: fill.foodIds,
                      freeFoods: fill.freeFoods,
                      recipeId: recipe.id,
                    ),
                  ),
                );
              },
            )
          : null,
      children: [
        if (recipe.photoPath != null)
          SdPhotoTile(
            key: const Key('sdFamilyPhoto'),
            path: recipe.photoPath!,
            size: 190,
            width: double.infinity,
          )
        else
          LbPicture(
            image: null,
            width: double.infinity,
            height: 150,
            radius: 22,
            look: sdFamilyRecipeLook(context, recipe, foods),
          ),
        const SizedBox(height: ClSpace.s4),
        Wrap(
          key: const Key('sdRecipeChips'),
          spacing: 8,
          runSpacing: 8,
          children: [
            LbChip(l10n.sdFamilyRecipes, fill: bottle.soft, ink: bottle.ink),
            LbChip(l10n.sdFamilyIngredientsCount(recipe.ingredients.length)),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(
            recipe.title,
            style: cl.text.largeTitle.copyWith(fontSize: 26, height: 1.25),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          who,
          key: const Key('sdFamilyWho'),
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: recipe.pending ? cl.colors.pending : cl.colors.inkMuted,
          ),
        ),
        SdDishesMadeLine(recipeId: recipe.id),
        if (nudges.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          SdNudgeCard(nudges: nudges),
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
                SdIngredientRow(
                  key: Key('sdIngredientRow_$n'),
                  ingredient: i.asIngredient,
                  qty: sdFamilyQty(l10n, tag, i),
                  notTried: tracking && sdNotTried(i, tried),
                  signs: sdHasSigns(i, tried, s.settings.cleared),
                ),
            ],
          ),
        ),
        if (recipe.steps.isNotEmpty) ...[
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
          SdRecipeSteps(steps: recipe.steps),
        ],
        if (recipe.note.isNotEmpty) ...[
          LbSection(l10n.sdFamilyNote),
          Text(
            recipe.note,
            key: const Key('sdFamilyNoteText'),
            style: cl.text.body.copyWith(fontSize: 15, height: 1.5),
          ),
        ],
        SdDishesMadeList(recipeId: recipe.id),
        if (!editable) ...[
          const SizedBox(height: ClSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.sdFamilyViewOnly,
                  key: const Key('sdFamilyViewOnly'),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The family recipe bar: "Ghi vào nhật ký" (who logs, while tracking is on).
class _LogBar extends StatelessWidget {
  const _LogBar({required this.onLog});
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
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
      child: ClButton(
        key: const Key('sdRecipeLog'),
        label: AppLocalizations.of(context).sdLogRecipe,
        icon: ClIcons.plus,
        expand: true,
        onPressed: onLog,
      ),
    );
  }
}

// ---------- The editor ----------

/// One ingredient being edited: the catalogue food or free name, the quantity text and the unit.
class _IngDraft {
  _IngDraft({required this.name, this.foodId, num? qty, this.unit})
    : qty = TextEditingController(
        text: qty == null
            ? ''
            : qty == qty.roundToDouble()
            ? '${qty.round()}'
            : '$qty',
      );

  factory _IngDraft.of(SdFamilyIngredient i) =>
      _IngDraft(name: i.name, foodId: i.foodId, qty: i.qty, unit: i.unit);

  final String? foodId;
  final String name;
  final TextEditingController qty;
  SdIngredientUnit? unit;

  /// The quantity: null when empty; [_invalid] when not a number from 0.1 to 2000.
  num? get value {
    final t = qty.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = num.tryParse(t);
    if (v == null || v <= 0 || v > SdLimits.maxQty) return _invalid;
    return v;
  }

  static const _invalid = -1;

  SdFamilyIngredient toIngredient() {
    final v = value;
    return SdFamilyIngredient(
      name: name,
      foodId: foodId,
      qty: v == null || v == _invalid ? null : v,
      unit: unit,
    );
  }
}

/// "Thêm công thức nhà mình" / "Sửa công thức" (D-086 §12 #2): title, one photo (`recipes`
/// folder, the meal photo store), ingredients from the catalogue picker or free names with an
/// optional quantity and unit, up to 12 steps (reordered with ↑ ↓), a note. The nudges update
/// live and never block saving. From a meal ([fromMealId]): the dish as the title and its
/// ingredients. Saved like meals: at once to the local cache, synced later offline.
class SdFamilyEditorScreen extends ConsumerStatefulWidget {
  const SdFamilyEditorScreen({this.recipeId, this.fromMealId, super.key});

  /// "Sửa" of this family recipe.
  final String? recipeId;

  /// "Lưu thành công thức" of this meal.
  final String? fromMealId;

  @override
  ConsumerState<SdFamilyEditorScreen> createState() =>
      _SdFamilyEditorScreenState();
}

class _SdFamilyEditorScreenState extends ConsumerState<SdFamilyEditorScreen> {
  late final String _id = widget.recipeId ?? newFamilyRecipeId();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _ings = <_IngDraft>[];
  final _steps = <TextEditingController>[TextEditingController()];
  String? _photoPath;

  /// The recipe being edited, once it has arrived.
  SdFamilyRecipe? _editing;

  /// Filled from the recipe or the meal (once).
  bool _filled = false;
  ProviderSubscription<Object?>? _fill;

  final _uploaded = <String>{};
  bool _uploading = false;
  bool _saved = false;
  late final VaccinePhotoStore _photos;
  bool _manages = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(vaccinePhotoStoreProvider);
    // The recipe or the meal may still be on its way (first open, slow network).
    if (widget.recipeId != null) {
      _fill = ref.listenManual<List<SdFamilyRecipe>>(
        sdFamilyListProvider,
        (_, _) => _tryFill(),
      );
    } else if (widget.fromMealId != null) {
      _fill = ref.listenManual<SdState?>(sdStateProvider, (_, _) => _tryFill());
    }
  }

  bool _built = false;
  Locale _locale = const Locale('vi');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.maybeLocaleOf(context) ?? _locale;
    _tryFill();
  }

  /// Once: from the recipe ("Sửa") or the meal ("Lưu thành công thức"); later changes on another
  /// device do not overwrite this draft.
  void _tryFill() {
    if (_filled) return;
    final recipe = widget.recipeId == null
        ? null
        : ref
              .read(sdFamilyListProvider)
              .where((r) => r.id == widget.recipeId)
              .firstOrNull;
    final s = ref.read(sdStateProvider);
    final meal = widget.fromMealId == null
        ? null
        : s?.meals.where((m) => m.id == widget.fromMealId).firstOrNull;
    if (recipe == null && meal == null) return;
    _filled = true;
    void apply() {
      if (recipe != null) {
        _editing = recipe;
        _title.text = recipe.title;
        _note.text = recipe.note;
        _photoPath = recipe.photoPath;
        _ings.addAll(recipe.ingredients.map(_IngDraft.of));
        for (final c in _steps) {
          c.dispose();
        }
        _steps
          ..clear()
          ..addAll([
            for (final st in recipe.steps) TextEditingController(text: st),
          ]);
        if (_steps.isEmpty) _steps.add(TextEditingController());
      } else if (meal != null) {
        final draft = sdFamilyDraftFromMeal(
          meal,
          s?.foods ?? const {},
          _locale,
        );
        _title.text = draft.title;
        _ings.addAll(draft.ingredients.map(_IngDraft.of));
      }
    }

    if (_built) {
      setState(apply);
    } else {
      apply();
    }
    final sub = _fill;
    _fill = null;
    if (sub != null) Future.microtask(sub.close);
  }

  @override
  void dispose() {
    _fill?.close();
    // Closed without saving: a photo uploaded here belongs to no recipe.
    if (!_saved) sdDropPhotos(_photos, _uploaded, manages: _manages);
    _title.dispose();
    _note.dispose();
    for (final i in _ings) {
      i.qty.dispose();
    }
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  List<SdFamilyIngredient> get _ingredients => [
    for (final i in _ings) i.toIngredient(),
  ];

  List<String> get _stepTexts => [
    for (final c in _steps)
      if (c.text.trim().isNotEmpty) c.text.trim(),
  ];

  Future<void> _pickIngredients(Map<String, SdFood> foods) async {
    final locale = Localizations.localeOf(context);
    final picked = await sdPickFoods(
      context,
      ids: [
        for (final i in _ings)
          if (i.foodId != null) i.foodId!,
      ],
      free: [
        for (final i in _ings)
          if (i.foodId == null) i.name,
      ],
      maxIds: SdLimits.familyIngredients,
      maxFree: SdLimits.familyIngredients,
      maxTotal: SdLimits.familyIngredients,
    );
    if (picked == null || !mounted) return;
    setState(() {
      final keep = <_IngDraft>[];
      for (final i in _ings) {
        final stays = i.foodId != null
            ? picked.ids.contains(i.foodId)
            : picked.free.contains(i.name);
        if (stays) {
          keep.add(i);
        } else {
          i.qty.dispose();
        }
      }
      for (final id in picked.ids) {
        if (!keep.any((i) => i.foodId == id)) {
          keep.add(
            _IngDraft(
              foodId: id,
              name: _clip(
                sdFoodName(id, foods, locale),
                SdLimits.ingredientName,
              ),
            ),
          );
        }
      }
      for (final f in picked.free) {
        if (!keep.any((i) => i.foodId == null && i.name == f)) {
          keep.add(_IngDraft(name: _clip(f, SdLimits.ingredientName)));
        }
      }
      _ings
        ..clear()
        ..addAll(keep);
      _error = null;
    });
  }

  Future<void> _pickUnit(_IngDraft i) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<({SdIngredientUnit? unit})>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        Widget option(String key, String label, SdIngredientUnit? u) =>
            ClPressable(
              key: Key('sdUnitOpt_$key'),
              onPressed: () => Navigator.of(sheet).pop((unit: u)),
              selected: i.unit == u,
              semanticLabel: label,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: cl.text.body)),
                    if (i.unit == u)
                      ClIcon(
                        ClIcons.check,
                        size: 18,
                        color: cl.colors.mintText,
                      ),
                  ],
                ),
              ),
            );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.sdFamilyUnit),
            option('none', l10n.sdFamilyUnitNone, null),
            for (final u in SdIngredientUnit.values)
              option(u.name, sdIngredientUnitLabel(l10n, u), u),
          ],
        );
      },
    );
    if (picked != null && mounted) setState(() => i.unit = picked.unit);
  }

  void _moveStep(int from, int to) {
    if (to < 0 || to >= _steps.length) return;
    setState(() {
      final c = _steps.removeAt(from);
      _steps.insert(to, c);
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final s = ref.read(sdStateProvider);
    if (s == null || !s.me.sdLogs) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.sdFamilyNeedTitle);
      return;
    }
    if (_ings.isEmpty) {
      setState(() => _error = l10n.sdFamilyNeedIngredient);
      return;
    }
    if (_ings.any((i) => i.value == _IngDraft._invalid)) {
      setState(() => _error = l10n.sdFamilyQtyInvalid);
      return;
    }
    final repo = ref.read(solidsStoreProvider);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    final editing = _editing;
    final SdFamilyRecipe recipe;
    if (editing != null) {
      if (!s.me.sdEditsRecipe(editing)) return;
      recipe = editing.edited(
        title: title,
        photoPath: _photoPath,
        ingredients: _ingredients,
        steps: _stepTexts,
        note: _note.text.trim(),
      );
      repo.editFamilyRecipe(recipe, s.me.uid, onError: failed);
    } else {
      recipe = SdFamilyRecipe.create(
        id: _id,
        me: s.me,
        title: title,
        photoPath: _photoPath,
        ingredients: _ingredients,
        steps: _stepTexts,
        note: _note.text.trim(),
      );
      repo.createFamilyRecipe(recipe, onError: failed);
    }
    // As meal photos: a Cùng nuôi deletes a replaced or dropped photo; a caregiver only clears it.
    _saved = true;
    sdDropPhotos(
      _photos,
      [..._uploaded, editing?.photoPath].where((p) => p != _photoPath),
      manages: s.me.sdManages,
    );
    ClHaptics.success();
    if (editing != null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(SdRoutes.recipe(recipe.id));
      }
      toaster.show(message: l10n.editedToast);
    } else {
      // The new recipe's page takes the editor's place.
      router.pushReplacement(SdRoutes.recipe(recipe.id));
      toaster.show(message: l10n.sdFamilySavedToast(recipe.title));
    }
  }

  @override
  Widget build(BuildContext context) {
    _built = true;
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final s = ref.watch(sdStateProvider);
    final foods = {
      for (final f
          in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
        f.id: f,
    };
    _manages = s?.me.sdManages ?? false;
    final editing = _editing;
    final title = widget.recipeId == null
        ? l10n.sdFamilyAdd
        : l10n.sdFamilyEditTitle;
    if (s == null) return ColoredBox(color: cl.colors.cloud);
    // "Sửa" waits for the recipe (never a blank form that would save over it).
    if (widget.recipeId != null && editing == null) {
      final loading = ref
          .watch(sdFamilyRecipesProvider(s.baby.babyId))
          .isLoading;
      return SdPage(
        children: [
          NuTitle(title, size: 26),
          if (!loading) ...[
            const SizedBox(height: ClSpace.s4),
            NuEmpty(
              title: l10n.sdRecipeMissing,
              body: l10n.sdFamilyMissingBody,
            ),
          ],
        ],
      );
    }
    if (!s.me.sdLogs || (editing != null && !s.me.sdEditsRecipe(editing))) {
      return SdPage(
        children: [NuEmpty(title: title, body: l10n.sdFamilyViewOnly)],
      );
    }
    final tracking = s.tracking;
    final tried = {
      if (tracking)
        for (final t in ref.watch(sdTriedProvider)) t.key: t,
    };
    final nudges = sdFamilyNudges(
      ingredients: _ingredients,
      foods: foods,
      months: s.months,
      title: _title.text,
      steps: _stepTexts,
      note: _note.text,
      locale: locale,
    );
    final full = _ings.length >= SdLimits.familyIngredients;

    return SdPage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Next to the button, so it is seen wherever the form is scrolled.
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s2),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const Key('sdFamilyError'),
                  style: cl.text.label.copyWith(color: cl.colors.error),
                ),
              ),
            ),
          ClButton(
            key: const Key('sdFamilySave'),
            label: l10n.sdFamilySave,
            expand: true,
            onPressed: _uploading ? null : _save,
          ),
        ],
      ),
      children: [
        NuTitle(title, size: 26),
        SdLabel(l10n.sdFamilyName),
        ClTextField(
          key: const Key('sdFamilyTitle'),
          controller: _title,
          placeholder: l10n.sdFamilyNameHint,
          maxLength: SdLimits.familyTitle,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() => _error = null),
        ),
        SdLabel(l10n.sdFamilyPhoto),
        SdPhotoField(
          babyId: s.baby.babyId,
          path: _photoPath,
          busy: _uploading,
          folder: 'recipes',
          addLabel: l10n.sdFamilyPhotoAdd,
          onBusy: (busy) {
            if (mounted) setState(() => _uploading = busy);
          },
          onChanged: (p) {
            if (!mounted) {
              sdDropPhotos(_photos, [p], manages: _manages);
              return;
            }
            setState(() {
              if (p != null) _uploaded.add(p);
              _photoPath = p;
            });
          },
        ),
        SdLabel(l10n.sdIngredients),
        if (_ings.isNotEmpty)
          NuGroup(
            inset: 14,
            children: [
              for (final (n, i) in _ings.indexed)
                _IngredientEditRow(
                  key: Key('sdFamilyIng_$n'),
                  index: n,
                  draft: i,
                  notTried: tracking && sdNotTried(i.toIngredient(), tried),
                  signs: sdHasSigns(
                    i.toIngredient(),
                    tried,
                    s.settings.cleared,
                  ),
                  onChanged: () => setState(() => _error = null),
                  onUnit: () => unawaited(_pickUnit(i)),
                  onRemove: () => setState(() {
                    _ings.removeAt(n);
                    i.qty.dispose();
                  }),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            ClButton(
              key: const Key('sdFamilyAddIngredient'),
              label: l10n.sdAddFood,
              icon: ClIcons.plus,
              style: ClButtonStyle.tinted,
              onPressed: () => unawaited(_pickIngredients(foods)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                full ? '' : l10n.sdFamilyIngredientsHint,
                style: cl.text.caption.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
          ],
        ),
        SdLabel(l10n.sdSteps),
        for (final (n, c) in _steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    width: 26,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 3),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClTextField(
                        key: Key('sdFamilyStep_$n'),
                        controller: c,
                        placeholder: l10n.sdFamilyStepHint(n + 1),
                        maxLength: SdLimits.familyStep,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                      ),
                      // ↑ ↓ reorder, × removes (up to 12 steps).
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _IconTap(
                            key: Key('sdFamilyStepUp_$n'),
                            icon: ClIcons.chevronDown,
                            flip: true,
                            label: l10n.sdFamilyStepUp(n + 1),
                            onTap: n == 0 ? null : () => _moveStep(n, n - 1),
                          ),
                          _IconTap(
                            key: Key('sdFamilyStepDown_$n'),
                            icon: ClIcons.chevronDown,
                            label: l10n.sdFamilyStepDown(n + 1),
                            onTap: n == _steps.length - 1
                                ? null
                                : () => _moveStep(n, n + 1),
                          ),
                          _IconTap(
                            key: Key('sdFamilyStepRemove_$n'),
                            icon: ClIcons.close,
                            label: l10n.sdFamilyStepRemove(n + 1),
                            onTap: () => setState(() {
                              _steps.removeAt(n).dispose();
                              if (_steps.isEmpty) {
                                _steps.add(TextEditingController());
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_steps.length < SdLimits.familySteps)
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              key: const Key('sdFamilyAddStep'),
              label: l10n.sdFamilyAddStep,
              icon: ClIcons.plus,
              style: ClButtonStyle.plain,
              onPressed: () =>
                  setState(() => _steps.add(TextEditingController())),
            ),
          ),
        SdLabel(l10n.sdFamilyNote),
        ClTextField(
          key: const Key('sdFamilyNote'),
          controller: _note,
          placeholder: l10n.sdFamilyNoteHint,
          maxLength: SdLimits.familyNote,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        if (nudges.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          SdNudgeCard(nudges: nudges),
        ],
      ],
    );
  }
}

String _clip(String s, int max) {
  final t = s.trim();
  return t.length <= max ? t : t.substring(0, max).trim();
}

/// A 32-point icon button (step ↑ ↓ ✕).
class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.label,
    required this.onTap,
    this.flip = false,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback? onTap;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final glyph = ClIcon(
      icon,
      size: 14,
      color: onTap == null ? cl.colors.separator : cl.colors.inkMuted,
    );
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: flip ? RotatedBox(quarterTurns: 2, child: glyph) : glyph,
        ),
      ),
    );
  }
}

/// An ingredient in the editor: the name (✦ / ⚠), the quantity, the unit and "×".
class _IngredientEditRow extends StatelessWidget {
  const _IngredientEditRow({
    required this.index,
    required this.draft,
    required this.notTried,
    required this.signs,
    required this.onChanged,
    required this.onUnit,
    required this.onRemove,
    super.key,
  });
  final int index;
  final _IngDraft draft;
  final bool notTried;
  final bool signs;
  final VoidCallback onChanged;
  final VoidCallback onUnit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final unit = draft.unit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.name,
                  style: cl.text.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (draft.foodId == null)
                  Text(
                    l10n.sdGroupOther,
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
                          fill: cl.colors.sunshineSoft,
                          ink: cl.colors.ink,
                        ),
                      if (signs)
                        SdTag(
                          l10n.sdSignsMark,
                          fill: cl.colors.errorSoft,
                          ink: cl.colors.error,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: Key('sdFamilyQty_$index'),
            width: 64,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cl.colors.controlBorder),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: draft.qty,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              style: cl.text.body.copyWith(fontSize: 15),
              decoration: InputDecoration.collapsed(
                hintText: l10n.sdFamilyQtyHint,
                hintStyle: cl.text.body.copyWith(
                  fontSize: 14,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ClPressable(
            key: Key('sdFamilyUnit_$index'),
            onPressed: onUnit,
            semanticLabel:
                '${l10n.sdFamilyUnit}: ${unit == null ? l10n.sdFamilyUnitNone : sdIngredientUnitLabel(l10n, unit)}',
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                unit == null
                    ? l10n.sdFamilyUnit
                    : sdIngredientUnitLabel(l10n, unit),
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: unit == null ? cl.colors.inkMuted : cl.colors.ink,
                ),
              ),
            ),
          ),
          _IconTap(
            key: Key('sdFamilyRemove_$index'),
            icon: ClIcons.close,
            label: l10n.sdRemoveFood(draft.name),
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}
