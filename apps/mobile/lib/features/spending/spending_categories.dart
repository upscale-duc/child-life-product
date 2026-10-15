import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'spending_calc.dart' show totalsByCurrency;
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_repository.dart';
import 'spending_widgets.dart';

/// 8m–8o: the family's categories (P-140), Cùng nuôi only. Opened over the 8c sheet too, so these
/// screens go on the root navigator.

Future<void> openCategories(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));

/// 8n. Returns the id saved (a new category is then chosen in 8c).
Future<String?> openCategoryEditor(
  BuildContext context, {
  required SpendingScope scope,
  SpendingCategory? category,
}) => Navigator.of(context, rootNavigator: true).push<String>(
  MaterialPageRoute<String>(
    builder: (_) => CategoryEditorScreen(category: category),
  ),
);

// ---------- 8m Danh mục ----------

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  /// The order just dragged, shown until the write comes back.
  List<String>? _order;

  void _reorder(
    SpendingScope scope,
    List<SpendingCategory> movable,
    int from,
    int to,
  ) {
    final ids = [for (final c in movable) c.id];
    final id = ids.removeAt(from);
    ids.insert(to, id);
    setState(() => _order = ids);
    final byId = {for (final c in scope.categories) c.id: c};
    final changed = [
      for (var i = 0; i < ids.length; i++)
        if (byId[ids[i]]!.order != i || !byId[ids[i]]!.stored)
          byId[ids[i]]!.copyWith(order: i),
    ];
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref
        .read(spendingRepositoryProvider)
        .saveCategories(
          scope.familyId,
          scope.me,
          changed,
          onError: (_) => toaster.show(message: l10n.spSaveFailed),
        );
  }

  void _show(SpendingScope scope, SpendingCategory c) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final maxOrder = scope.visible
        .where((v) => !v.locked)
        .fold(0, (m, v) => v.order > m ? v.order : m);
    ref.read(spendingRepositoryProvider).saveCategories(
      scope.familyId,
      scope.me,
      [c.copyWith(hidden: false, order: maxOrder + 1)],
      onError: (_) => toaster.show(message: l10n.spSaveFailed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final counts = <String, int>{};
    for (final e in scope.expenses) {
      counts[e.categoryId] = (counts[e.categoryId] ?? 0) + 1;
    }
    var movable = [
      for (final c in scope.visible)
        if (!c.locked) c,
    ];
    if (_order case final order?) {
      final byId = {for (final c in movable) c.id: c};
      if (order.length == movable.length && order.every(byId.containsKey)) {
        movable = [for (final id in order) byId[id]!];
      }
    }
    final other = scope.category(otherCategoryId);
    final hidden = [
      for (final c in scope.categories)
        if (c.hidden) c,
    ];
    String sub(SpendingCategory c) {
      final n = counts[c.id] ?? 0;
      if (c.locked) return l10n.spCategoryLocked;
      return c.builtIn ? l10n.spItems(n) : l10n.spCategoryCustom(n);
    }

    return SpPage(
      bottom: SpBottomButton(
        label: l10n.spAddCategory,
        onPressed: () => openCategoryEditor(context, scope: scope),
      ),
      children: [
        SpTitle(l10n.spCategories),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.spCategoriesIntro,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClSectionHeader(title: l10n.spCategoriesInUse),
        const SizedBox(height: ClSpace.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) => _reorder(scope, movable, from, to),
                children: [
                  for (var i = 0; i < movable.length; i++)
                    _CategoryRow(
                      key: ValueKey(movable[i].id),
                      category: movable[i],
                      subline: sub(movable[i]),
                      handle: ReorderableDragStartListener(
                        index: i,
                        child: const _Handle(),
                      ),
                      onTap: () => openCategoryEditor(
                        context,
                        scope: scope,
                        category: movable[i],
                      ),
                    ),
                ],
              ),
              Container(height: 1, color: cl.colors.separator),
              _CategoryRow(
                category: other,
                subline: sub(other),
                handle: const SizedBox(width: 22),
                locked: true,
              ),
            ],
          ),
        ),
        if (hidden.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s6),
          ClSectionHeader(title: l10n.spCategoriesHidden),
          const SizedBox(height: ClSpace.s2),
          SpGroup(
            children: [
              for (final c in hidden)
                Opacity(
                  opacity: 0.6,
                  child: _CategoryRow(
                    category: c,
                    subline: l10n.spCategoryHiddenSub(counts[c.id] ?? 0),
                    handle: const SizedBox.shrink(),
                    action: ClPressable(
                      onPressed: () => _show(scope, c),
                      semanticLabel: l10n.spShowAgain,
                      child: Text(
                        l10n.spShowAgain,
                        style: cl.text.label.copyWith(
                          color: cl.colors.mintText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: AppLocalizations.of(context).spDragHandle,
      child: SizedBox(
        width: 22,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 3),
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: cl.colors.controlBorder,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.subline,
    required this.handle,
    this.onTap,
    this.locked = false,
    this.action,
    super.key,
  });

  final SpendingCategory category;
  final String subline;
  final Widget handle;
  final VoidCallback? onTap;
  final bool locked;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final name = categoryName(l10n, category);
    final row = Container(
      color: cl.colors.surface,
      padding: const EdgeInsets.fromLTRB(ClSpace.s3, 8, ClSpace.s4, 8),
      child: Row(
        children: [
          handle,
          const SizedBox(width: ClSpace.s2),
          CategoryBadge(category: category),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: spRowTitle(context)),
                Text(
                  subline,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          action ??
              ClIcon(
                locked ? ClIcons.lock : ClIcons.chevronRight,
                size: 18,
                color: cl.colors.inkMuted,
              ),
        ],
      ),
    );
    if (onTap == null) return row;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$name, $subline',
      child: SizedBox(width: double.infinity, child: row),
    );
  }
}

// ---------- 8n Thêm / sửa danh mục ----------

class CategoryEditorScreen extends ConsumerStatefulWidget {
  const CategoryEditorScreen({this.category, super.key});

  /// Null: a new one.
  final SpendingCategory? category;

  @override
  ConsumerState<CategoryEditorScreen> createState() =>
      _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends ConsumerState<CategoryEditorScreen> {
  SpendingCategory? get _c => widget.category;
  late final _name = TextEditingController();
  late ClIcons _icon = _c?.icon ?? ClIcons.journal;
  late CategoryTint _tint = _c?.tint ?? CategoryTint.sunshine;
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filled && _c != null) {
      _filled = true;
      _name.text = categoryName(AppLocalizations.of(context), _c!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save(SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      showClToast(context, message: l10n.spCategoryNameMissing);
      return;
    }
    final folded = name.toLowerCase();
    final clash = scope.categories.any(
      (c) => c.id != _c?.id && categoryName(l10n, c).toLowerCase() == folded,
    );
    if (clash) {
      showClToast(context, message: l10n.spCategoryNameTaken);
      return;
    }
    final toaster = ClToaster.of(context);
    final SpendingCategory saved;
    if (_c case final c?) {
      // A built-in keeps its translated name unless it was changed.
      final keep = c.builtIn && c.name == null && name == categoryName(l10n, c);
      saved = c.copyWith(
        name: () => keep ? null : name,
        icon: _icon,
        tint: _tint,
      );
    } else {
      final maxOrder = scope.categories
          .where((v) => !v.locked)
          .fold(0, (m, v) => v.order > m ? v.order : m);
      saved = SpendingCategory(
        id: newCategoryId(),
        name: name,
        icon: _icon,
        tint: _tint,
        order: (maxOrder + 1).clamp(0, 98),
      );
    }
    ref.read(spendingRepositoryProvider).saveCategories(
      scope.familyId,
      scope.me,
      [saved],
      onError: (_) => toaster.show(message: l10n.spSaveFailed),
    );
    Navigator.of(context).pop(saved.id);
  }

  void _hide(SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref.read(spendingRepositoryProvider).saveCategories(
      scope.familyId,
      scope.me,
      [_c!.copyWith(hidden: true)],
      onError: (_) => toaster.show(message: l10n.spSaveFailed),
    );
    Navigator.of(context).pop();
    toaster.show(message: l10n.spCategoryHiddenToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final t = tintColors(context, _tint);
    final preview = _name.text.trim().isEmpty
        ? l10n.spCategoryNamePlaceholder
        : _name.text.trim();
    final c = _c;
    return SpPage(
      close: true,
      showBaby: false,
      bottom: SpBottomButton(
        label: l10n.spSaveCategory,
        onPressed: () => _save(scope),
      ),
      children: [
        SpTitle(c == null ? l10n.spNewCategory : l10n.spEditCategory),
        const SizedBox(height: ClSpace.s4),
        SpCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: t.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: ClIcon(_icon, size: 22, color: t.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Text(
                  preview,
                  style: cl.text.headline.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SpLabel(l10n.spCategoryName),
        ClTextField(
          key: const Key('spCategoryName'),
          controller: _name,
          placeholder: l10n.spCategoryNamePlaceholder,
          standalone: true,
          maxLength: SpendingLimits.categoryNameMax,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s1),
        Text(
          l10n.spCategoryNameHelp,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        SpLabel(l10n.spCategoryIcon),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final icon in categoryIcons)
              ClPressable(
                onPressed: () => setState(() => _icon = icon),
                semanticLabel: icon.name,
                selected: icon == _icon,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: icon == _icon ? t.soft : cl.colors.surface,
                    border: Border.all(
                      color: icon == _icon
                          ? cl.colors.ink
                          : cl.colors.separator,
                      width: icon == _icon ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    icon,
                    size: 20,
                    color: icon == _icon ? t.ink : cl.colors.ink,
                  ),
                ),
              ),
          ],
        ),
        SpLabel(l10n.spCategoryColor),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tint in CategoryTint.values)
              ClPressable(
                onPressed: () => setState(() => _tint = tint),
                semanticLabel: l10n.spColorN(tint.index + 1),
                selected: tint == _tint,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tintColors(context, tint).soft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tint == _tint
                          ? cl.colors.ink
                          : cl.colors.separator,
                      width: tint == _tint ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (c != null && !c.locked) ...[
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.spHideCategory,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => _hide(scope),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            key: const Key('spDeleteCategory'),
            label: l10n.spDeleteCategory,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () async {
              final done = await showDeleteCategorySheet(
                context,
                scope: scope,
                category: c,
              );
              if (done && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

// ---------- 8o Xoá danh mục ----------

/// True when the category was deleted or hidden.
Future<bool> showDeleteCategorySheet(
  BuildContext context, {
  required SpendingScope scope,
  required SpendingCategory category,
}) async =>
    await showClSheet<bool>(
      context: context,
      builder: (_) => _DeleteSheet(scope: scope, category: category),
    ) ??
    false;

class _DeleteSheet extends ConsumerStatefulWidget {
  const _DeleteSheet({required this.scope, required this.category});
  final SpendingScope scope;
  final SpendingCategory category;

  @override
  ConsumerState<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends ConsumerState<_DeleteSheet> {
  String _moveTo = otherCategoryId;
  bool _busy = false;

  Future<void> _pickOther() async {
    final l10n = AppLocalizations.of(context);
    final options = [
      for (final c in widget.scope.visible)
        if (c.id != widget.category.id && !c.locked) c,
    ];
    final id = await showClSheet<String>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.spChooseCategory),
          Flexible(
            child: SingleChildScrollView(
              child: SpGroup(
                children: [
                  for (final c in options)
                    ClPressable(
                      onPressed: () => Navigator.of(sheet).pop(c.id),
                      semanticLabel: categoryName(l10n, c),
                      pressedOpacity: ClPressable.surfaceOpacity,
                      child: Padding(
                        padding: const EdgeInsets.all(ClSpace.s3),
                        child: Row(
                          children: [
                            CategoryBadge(category: c),
                            const SizedBox(width: ClSpace.s3),
                            Expanded(
                              child: Text(
                                categoryName(l10n, c),
                                style: sheet.cl.text.body,
                              ),
                            ),
                            ClRadio(selected: c.id == _moveTo),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
        ],
      ),
    );
    if (id != null && mounted) setState(() => _moveTo = id);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(spendingRepositoryProvider)
          .deleteCategory(
            babyId: widget.scope.babyId,
            categoryId: widget.category.id,
            moveTo: _moveTo,
          );
      nav.pop(true);
      toaster.show(message: l10n.spCategoryDeleted);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _busy = false);
      toaster.show(
        message: e.code == 'unavailable'
            ? l10n.spNeedsNetwork
            : l10n.spSaveFailed,
      );
    } on Object {
      if (mounted) setState(() => _busy = false);
      toaster.show(message: l10n.spNeedsNetwork);
    }
  }

  void _hide() {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref.read(spendingRepositoryProvider).saveCategories(
      widget.scope.familyId,
      widget.scope.me,
      [widget.category.copyWith(hidden: true)],
      onError: (_) => toaster.show(message: l10n.spSaveFailed),
    );
    Navigator.of(context).pop(true);
    toaster.show(message: l10n.spCategoryHiddenToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final c = widget.category;
    final items = [
      for (final e in widget.scope.expenses)
        if (e.categoryId == c.id) e,
    ];
    // D-075 #4: per currency, never added together.
    final sums = totalsByCurrency(items, first: widget.scope.currency);
    final otherName = _moveTo == otherCategoryId
        ? null
        : categoryName(l10n, widget.scope.category(_moveTo));
    Widget option({
      required bool selected,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) => ClPressable(
      onPressed: onTap,
      semanticLabel: title,
      selected: selected,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface,
          border: Border.all(
            color: selected ? cl.colors.mintDeep : cl.colors.controlBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClRadio(selected: selected),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: spRowTitle(context)),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.spDeleteCategoryTitle(categoryName(l10n, c))),
        Text(
          items.isEmpty
              ? l10n.spDeleteCategoryEmpty
              : l10n.spDeleteCategoryBody(
                  items.length,
                  moneyList(locale, sums),
                ),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        option(
          selected: _moveTo == otherCategoryId,
          title: l10n.spMoveToOther,
          subtitle: l10n.spMoveToOtherSub,
          onTap: () => setState(() => _moveTo = otherCategoryId),
        ),
        const SizedBox(height: ClSpace.s2),
        option(
          selected: _moveTo != otherCategoryId,
          title: l10n.spMoveToAnother,
          subtitle: otherName ?? l10n.spChooseCategory,
          onTap: () => unawaited(_pickOther()),
        ),
        const SizedBox(height: ClSpace.s3),
        SpBanner(icon: ClIcons.eye, text: l10n.spHideInstead),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('spConfirmDeleteCategory'),
          label: items.isEmpty
              ? l10n.spDeleteCategory
              : l10n.spDeleteAndMove(items.length),
          style: ClButtonStyle.destructive,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : () => unawaited(_delete()),
        ),
        const SizedBox(height: ClSpace.s1),
        ClButton(
          label: l10n.spHideCategoryInstead,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: _busy ? null : _hide,
        ),
      ],
    );
  }
}
