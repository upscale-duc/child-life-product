import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_status.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show authorFull;
import '../family/family_labels.dart' show relationLabel;
import '../nutrition/nutrition_widgets.dart';
import 'solids_calc.dart';
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_photos.dart' show SdPhotoTile;
import 'solids_repository.dart';
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';
import 'solids_widgets.dart';

/// 5d Lịch sử bữa ăn (`314:1786`), 5e Món đã thử (`314:1901`), meal detail and food detail
/// (P-164 #7, #14). Counts come from the meals, so 5b and 5e always agree.

/// Nothing to show: tracking is off (or this member does not read the diary).
Widget _off(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return SdPage(
    children: [NuEmpty(title: l10n.sdOffTitle, body: l10n.sdOffBody)],
  );
}

// ---------- 5d / 5e ----------

class MealHistoryScreen extends ConsumerStatefulWidget {
  const MealHistoryScreen({this.foods = false, super.key});

  /// Open on "Món đã thử".
  final bool foods;

  @override
  ConsumerState<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends ConsumerState<MealHistoryScreen> {
  late bool _foods = widget.foods;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.tracking || !s.me.sdReads) return _off(context);
    return SdPage(
      children: [
        NuTitle(l10n.sdHistoryTitle),
        const SizedBox(height: ClSpace.s3),
        ClSegmented<bool>(
          key: const Key('sdHistorySegments'),
          options: const [false, true],
          selected: _foods,
          labelOf: (f) => f ? l10n.sdTriedTab : l10n.sdMealsTab,
          onChanged: (f) => setState(() => _foods = f),
        ),
        const SizedBox(height: ClSpace.s3),
        if (_foods) const _TriedList() else const _MealList(),
      ],
    );
  }
}

class _MealList extends ConsumerStatefulWidget {
  const _MealList();

  @override
  ConsumerState<_MealList> createState() => _MealListState();
}

class _MealListState extends ConsumerState<_MealList> {
  /// Days shown; "Xem thêm" adds more (a long diary stays light to build).
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider)!;
    final zone = s.baby.zone;
    final today = s.baby.today;
    final byDay = <DateTime, List<SdMeal>>{};
    for (final m in s.meals) {
      (byDay[sdDayOf(zone, m.occurredAt)] ??= []).add(m);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) {
      return NuEmpty(title: l10n.sdHistoryEmpty, body: l10n.sdHistoryEmptyBody);
    }
    String header(DateTime d) {
      final date = toBeginningOfSentenceCase(
        DateFormat('EEEE dd/MM', tag).format(d),
      );
      if (d == today) return '${l10n.sdToday} · $date';
      if (d == DateTime(today.year, today.month, today.day - 1)) {
        return '${l10n.sdYesterday} · $date';
      }
      return date;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in days.take(_days)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              header(d),
              style: cl.text.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cl.colors.inkMuted,
              ),
            ),
          ),
          NuGroup(
            inset: 74,
            children: [
              for (final m in byDay[d]!..sort((a, b) => sdCompareMeals(b, a)))
                _MealRow(meal: m, foods: s.foods, myUid: s.me.uid),
            ],
          ),
        ],
        if (days.length > _days)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s3),
            child: ClButton(
              label: l10n.sdShowMore,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () => setState(() => _days += 30),
            ),
          ),
      ],
    );
  }
}

/// 5d row: picture 48, the dish, "16:20 · ½ chén · Thích", who logged it, "Có dấu hiệu".
class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.foods,
    required this.myUid,
  });
  final SdMeal meal;
  final Map<String, SdFood> foods;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final title = sdMealTitle(meal, foods, locale);
    final line = [
      sdTime(tag, meal.occurredAt),
      if (sdMealLine(l10n, tag, meal) case final l when l.isNotEmpty) l,
    ].join(' · ');
    final who = [
      sdLoggedBy(l10n, meal, myUid),
      if (meal.pending) l10n.carePending,
    ].join(' · ');
    return ClPressable(
      key: Key('sdRow_${meal.id}'),
      onPressed: () => context.push(SdRoutes.meal(meal.id)),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$title. $line. $who',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SdMealThumb(meal: meal, size: 48),
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
                    ),
                  ),
                  Text(
                    line,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          who,
                          style: cl.text.caption.copyWith(
                            fontSize: 12,
                            color: meal.pending
                                ? cl.colors.pending
                                : cl.colors.inkMuted,
                          ),
                        ),
                      ),
                      if (meal.hasSymptoms) ...[
                        const SizedBox(width: 6),
                        SdTag.signs(context),
                      ],
                    ],
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

class _TriedList extends ConsumerStatefulWidget {
  const _TriedList();

  @override
  ConsumerState<_TriedList> createState() => _TriedListState();
}

class _TriedListState extends ConsumerState<_TriedList> {
  /// Null = "Tất cả"; otherwise the group, with [_other] for "Khác".
  SdGroup? _group;
  bool _other = false;
  bool get _all => _group == null && !_other;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider)!;
    final today = s.baby.today;
    final tried = ref.watch(sdTriedProvider);
    final counts = sdGroupCounts(tried);
    final shown = [
      for (final t in tried)
        if (_all || (_other ? t.group == null : t.group == _group)) t,
    ];

    Widget chip(String key, String label, bool selected, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClPressable(
            key: Key('sdGroup_$key'),
            onPressed: onTap,
            selected: selected,
            semanticLabel: label,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? cl.colors.ink : cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.pill),
                border: selected
                    ? null
                    : Border.all(color: cl.colors.separator),
              ),
              child: Text(
                label,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cl.colors.cloud : cl.colors.ink,
                ),
              ),
            ),
          ),
        );

    if (tried.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NuEmpty(title: l10n.sdTriedEmptyTitle, body: l10n.sdTriedEmpty),
          SdFootnote(l10n.sdTriedFootnote),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              chip(
                'all',
                l10n.sdGroupCount(l10n.sdAll, tried.length),
                _all,
                () => setState(() {
                  _group = null;
                  _other = false;
                }),
              ),
              for (final g in sdGroupOrder)
                if ((counts[g] ?? 0) > 0)
                  chip(
                    g?.name ?? 'other',
                    l10n.sdGroupCount(sdGroupLabel(l10n, g), counts[g]!),
                    g == null ? _other : _group == g,
                    () => setState(() {
                      _group = g;
                      _other = g == null;
                    }),
                  ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        NuGroup(
          inset: 14,
          children: [
            for (final t in shown)
              ClPressable(
                key: Key('sdTried_${t.key}'),
                onPressed: () => context.push(SdRoutes.food(t.key)),
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: [
                  t.name(locale),
                  _firstLine(l10n, tag, t, today, s.baby.zone),
                  if (t.latestReaction != null)
                    sdReactionLabel(l10n, t.latestReaction!),
                  if (t.flagged) l10n.sdSignsTag,
                ].join('. '),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name(locale),
                              style: cl.text.bodyStrong.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _firstLine(l10n, tag, t, today, s.baby.zone),
                              style: cl.text.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (t.flagged) ...[
                        SdTag.signs(context),
                        const SizedBox(width: 6),
                      ],
                      if (t.latestReaction != null)
                        SdTag.reaction(context, t.latestReaction!),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SdFootnote(l10n.sdTriedFootnote),
      ],
    );
  }
}

/// "Lần đầu hôm nay · 1 lần", "Lần đầu 07/10 · 3 lần".
String _firstLine(
  AppLocalizations l10n,
  String tag,
  SdTried t,
  DateTime today,
  String zone,
) {
  final first = sdDayOf(zone, t.firstAt);
  final day = first == today ? l10n.sdTodayLower : sdShortDate(tag, first);
  return l10n.sdFirstTried(day, t.times);
}

// ---------- Meal detail ----------

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.mealId, super.key});
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.me.sdReads) return _off(context);
    final meal = s.meals.where((m) => m.id == mealId).firstOrNull;
    if (meal == null) {
      return SdPage(
        children: [
          NuEmpty(title: l10n.sdMealMissing, body: l10n.sdMealMissingBody),
        ],
      );
    }
    final editable = s.me.sdEdits(meal);
    final firsts = sdFirstTryIds(meal, s.meals);
    final today = s.baby.today;
    final day = sdDayOf(s.baby.zone, meal.occurredAt);
    final author = authorFull(
      l10n,
      meal.author,
      isMe: meal.createdBy == s.me.uid,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: value),
        ],
      ),
    );
    Widget text(String v) => Text(v, style: cl.text.bodyStrong);

    return SdPage(
      bottom: editable
          ? Row(
              children: [
                Expanded(
                  child: ClButton(
                    key: const Key('sdDeleteMeal'),
                    label: l10n.sdDelete,
                    style: ClButtonStyle.destructive,
                    expand: true,
                    onPressed: () =>
                        unawaited(_confirmDelete(context, ref, meal)),
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: ClButton(
                    key: const Key('sdEditMeal'),
                    label: l10n.actionEdit,
                    icon: ClIcons.edit,
                    style: ClButtonStyle.tinted,
                    expand: true,
                    onPressed: () =>
                        unawaited(openMealSheet(context, edit: meal)),
                  ),
                ),
              ],
            )
          : null,
      children: [
        Text(
          l10n.sdSlotTime(
            sdSlotMealLabel(l10n, meal.slot),
            sdDayLabel(l10n, tag, day, today),
          ),
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cl.care.bottle.ink,
          ),
        ),
        const SizedBox(height: 6),
        NuTitle(sdMealTitle(meal, s.foods, locale), size: 26),
        const SizedBox(height: ClSpace.s4),
        // D-085 #2: the meal photo, full screen on tap.
        if (meal.photoPath != null) ...[
          SdPhotoTile(
            key: const Key('sdMealPhoto'),
            path: meal.photoPath!,
            size: 200,
            width: double.infinity,
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        NuGroup(
          inset: 0,
          children: [
            row(l10n.sdTime, text(sdTime(tag, meal.occurredAt))),
            if (meal.dish.isNotEmpty) row(l10n.sdDish, text(meal.dish)),
            if (meal.foodIds.isNotEmpty || meal.freeFoods.isNotEmpty)
              row(
                l10n.sdIngredients,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final id in meal.foodIds)
                      SdFoodChip(
                        firsts.contains(id)
                            ? l10n.sdFirstTryChip(
                                sdFoodName(id, s.foods, locale),
                              )
                            : sdFoodName(id, s.foods, locale),
                        look: firsts.contains(id)
                            ? SdChipLook.firstTry
                            : SdChipLook.plain,
                        onTap: () => context.push(SdRoutes.food(id)),
                      ),
                    for (final f in meal.freeFoods)
                      SdFoodChip(
                        f,
                        onTap: () => context.push(SdRoutes.food(sdFreeKey(f))),
                      ),
                  ],
                ),
              ),
            if (meal.amount != null)
              row(l10n.sdAmount, text(sdAmountLabel(l10n, tag, meal.amount!))),
            if (meal.reaction != null)
              row(l10n.sdReaction, text(sdReactionLabel(l10n, meal.reaction!))),
            row(
              l10n.sdSymptomsTitle,
              meal.hasSymptoms
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final x in meal.symptoms)
                          SdTag(
                            sdSymptomLabel(l10n, x),
                            fill: cl.colors.errorSoft,
                            ink: cl.colors.error,
                          ),
                      ],
                    )
                  : text(l10n.sdSymptomsNone),
            ),
            if (meal.note.isNotEmpty) row(l10n.sdNote, text(meal.note)),
            row(l10n.detailBy, text(author)),
            row(l10n.detailLoggedAt, text(sdTime(tag, meal.loggedAt))),
            row(
              l10n.detailSync,
              Align(
                alignment: Alignment.centerLeft,
                child: ClSyncStatus(
                  state: meal.pending
                      ? ClSyncState.pending
                      : ClSyncState.synced,
                  label: meal.pending ? l10n.carePending : l10n.retrySynced,
                ),
              ),
            ),
          ],
        ),
        if (meal.hasSymptoms) ...[
          const SizedBox(height: ClSpace.s3),
          NuBanner(text: l10n.sdSymptomsNote),
        ],
        if (!editable) ...[
          const SizedBox(height: ClSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.sdViewOnly,
                  key: const Key('sdViewOnly'),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SdMeal meal,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sdDeleteTitle),
          Text(
            l10n.deleteConfirmBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            key: const Key('sdDeleteConfirm'),
            label: l10n.sdDelete,
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
    if (confirmed != true || !context.mounted) return;
    final s = ref.read(sdStateProvider);
    if (s == null) return;
    final repo = ref.read(solidsStoreProvider);
    final toaster = ClToaster.of(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    repo.softDelete(meal, s.me.uid, onError: failed);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(SdRoutes.home);
    }
    toaster.show(
      message: l10n.sdDeletedToast,
      actionLabel: l10n.undo,
      visibleFor: const Duration(seconds: 5),
      onAction: () => repo.restore(meal, s.me.uid, onError: failed),
    );
  }
}

// ---------- Food detail ----------

class FoodDetailScreen extends ConsumerWidget {
  const FoodDetailScreen({required this.foodKey, super.key});
  final String foodKey;

  void _setLists(
    WidgetRef ref,
    BuildContext context,
    SdState s, {
    List<String>? hidden,
    List<String>? cleared,
  }) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref
        .read(solidsStoreProvider)
        .saveSettings(
          s.baby.babyId,
          s.settings.copyWith(hidden: hidden, cleared: cleared),
          s.me.uid,
          onError: (_) =>
              toaster.show(message: l10n.careSaveFailed, error: true),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    if (s == null || !s.tracking || !s.me.sdReads) return _off(context);
    final tried = ref
        .watch(sdTriedProvider)
        .where((t) => t.key == foodKey)
        .firstOrNull;
    final food = s.foods[foodKey];
    if (tried == null && food == null) {
      return SdPage(
        children: [
          NuEmpty(title: l10n.sdFoodMissing, body: l10n.sdFoodMissingBody),
        ],
      );
    }
    final name =
        tried?.name(locale) ??
        food?.name.pick(locale) ??
        foodKey.replaceAll('_', ' ');
    final catalogue = sdFoodId(foodKey);
    final hidden = s.settings.hidden.contains(foodKey);
    final cleared = s.settings.cleared.contains(foodKey);
    final manages = s.me.sdManages;
    final signs = [
      for (final m in tried?.meals ?? const <SdMeal>[])
        if (m.hasSymptoms) m,
    ];
    final today = s.baby.today;

    return SdPage(
      children: [
        Text(
          sdGroupLabel(l10n, food?.group ?? tried?.group),
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cl.care.bottle.ink,
          ),
        ),
        const SizedBox(height: 6),
        NuTitle(name, size: 26),
        const SizedBox(height: ClSpace.s3),
        if (tried != null)
          NuCard(
            key: const Key('sdFoodSummary'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _firstLine(l10n, tag, tried, today, s.baby.zone),
                    style: cl.text.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                if (tried.flagged) ...[
                  SdTag.signs(context),
                  const SizedBox(width: 6),
                ],
                if (tried.latestReaction != null)
                  SdTag.reaction(context, tried.latestReaction!),
              ],
            ),
          )
        else
          Text(
            l10n.sdNotTried,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        if (tried?.flagged ?? false) ...[
          const SizedBox(height: ClSpace.s3),
          NuBanner(
            key: const Key('sdFoodSigns'),
            text: cleared ? l10n.sdClearedNote : l10n.sdFoodSignsNote,
          ),
        ],
        if (signs.isNotEmpty) ...[
          NuSection(l10n.sdSymptomsTitle),
          NuGroup(
            inset: 16,
            children: [
              for (final m in signs)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${sdDayLabel(l10n, tag, sdDayOf(s.baby.zone, m.occurredAt), today)} · ${sdTime(tag, m.occurredAt)}',
                        style: cl.text.caption.copyWith(
                          fontSize: 12,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          for (final x in m.symptoms) sdSymptomLabel(l10n, x),
                        ].join(', '),
                        style: cl.text.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (tried != null) ...[
          NuSection(l10n.sdFoodMeals(tried.times)),
          NuGroup(
            inset: 74,
            children: [
              for (final m in tried.meals.take(20))
                _MealRow(meal: m, foods: s.foods, myUid: s.me.uid),
            ],
          ),
        ],
        // P-164 #13: hidden foods and "Bác sĩ đã cho ăn lại" are Cùng nuôi's (settings).
        if (catalogue && manages) ...[
          const SizedBox(height: ClSpace.s4),
          if ((tried?.flagged ?? false))
            ClButton(
              key: const Key('sdCleared'),
              label: cleared ? l10n.sdUnclear : l10n.sdClear,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () => _setLists(
                ref,
                context,
                s,
                cleared: cleared
                    ? [
                        for (final id in s.settings.cleared)
                          if (id != foodKey) id,
                      ]
                    : [...s.settings.cleared, foodKey],
              ),
            ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            key: const Key('sdHide'),
            label: hidden ? l10n.sdUnhide : l10n.sdHide,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => _setLists(
              ref,
              context,
              s,
              hidden: hidden
                  ? [
                      for (final id in s.settings.hidden)
                        if (id != foodKey) id,
                    ]
                  : [...s.settings.hidden, foodKey],
            ),
          ),
        ],
        SdFootnote(l10n.sdTriedFootnote),
      ],
    );
  }
}
