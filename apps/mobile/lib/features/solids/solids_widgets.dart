import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart' show SavedBabyAvatar;
import '../baby/baby_repository.dart';
import '../care/history_screen.dart' show weekdayShort;
import '../home/home_shell.dart';
import 'solids_calc.dart';
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_photos.dart' show SdPhotoTile;

/// Shared pieces of Ăn dặm (Figma 5a–5h). Night care: ink on the soft warm fills (sunshine-soft
/// first-try chips), mint text on mint-soft.

/// A pushed Ăn dặm page (under Chăm sóc, no dock): back, the baby switcher, the scrolling body,
/// an optional floating button ("Ghi bữa") and an optional fixed bar.
class SdPage extends ConsumerWidget {
  const SdPage({
    required this.children,
    this.fab,
    this.bottom,
    this.trailing,
    super.key,
  });

  final List<Widget> children;
  final Widget? fab;
  final Widget? bottom;

  /// Replaces the baby switcher (e.g. "Sửa" on meal detail).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      floatingActionButton: fab,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: () => context.pop(),
                trailing:
                    trailing ??
                    (baby == null
                        ? null
                        : ClBabySwitcher(
                            label: baby.nickname,
                            avatar: SavedBabyAvatar(baby: baby, size: 32),
                          )),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  (bottom == null ? media.padding.bottom : 0) +
                      (fab == null ? ClSpace.s8 : 96),
                ),
                children: children,
              ),
            ),
            if (bottom != null)
              Container(
                color: cl.colors.cloud,
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s3,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// 5b FAB "Ghi bữa" (mint-deep pill, plus 18, Bold 16).
class SdFab extends StatelessWidget {
  const SdFab({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('sdLogMeal'),
      onPressed: onPressed,
      semanticLabel: l10n.sdLogMeal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: cl.colors.mintDeep,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(ClIcons.plus, size: 18, color: cl.colors.onMintDeep),
            const SizedBox(width: 8),
            Text(
              l10n.sdLogMeal,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cl.colors.onMintDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How an ingredient chip looks.
enum SdChipLook {
  /// surface-2 (5b cards).
  plain,

  /// ✦ "lần đầu": sunshine-soft with the spark (ink on it, also in Night care).
  firstTry,

  /// White with a hairline (5b "Món đã thử").
  outline,
}

/// An ingredient chip (5b, 5c): optional leading close (removable) and ✦ first try.
class SdFoodChip extends StatelessWidget {
  const SdFoodChip(
    this.label, {
    this.look = SdChipLook.plain,
    this.onTap,
    this.onRemove,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final SdChipLook look;
  final VoidCallback? onTap;

  /// 5c: a leading ✕ removes it.
  final VoidCallback? onRemove;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (fill, ink, border) = switch (look) {
      SdChipLook.plain => (cl.colors.surface2, cl.colors.ink, null),
      SdChipLook.firstTry => (cl.colors.sunshineSoft, cl.colors.ink, null),
      SdChipLook.outline => (
        cl.colors.surface,
        cl.colors.ink,
        Border.all(color: cl.colors.separator),
      ),
    };
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRemove != null) ...[
            ClIcon(ClIcons.close, size: 12, color: ink),
            const SizedBox(width: 5),
          ],
          if (look == SdChipLook.firstTry) ...[
            ClIcon(ClIcons.spark, size: 12, color: ink),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
    final tap = onRemove ?? onTap;
    if (tap == null) {
      return Semantics(
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: chip,
      );
    }
    return ClPressable(
      onPressed: tap,
      semanticLabel: semanticLabel ?? label,
      child: chip,
    );
  }
}

/// A selectable pill (5a method, 5c amount / reaction / symptoms, 5f filters). [danger]: the
/// urgent symptoms, selected in the error colours.
class SdPill extends StatelessWidget {
  const SdPill(
    this.label, {
    required this.selected,
    required this.onTap,
    this.soft = false,
    this.danger = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Selected as mint-soft / mint-text (5c reaction) instead of mint-deep.
  final bool soft;
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (fill, ink, border) = !selected
        ? (cl.colors.surface, cl.colors.ink, cl.colors.controlBorder)
        : danger
        ? (cl.colors.errorSoft, cl.colors.error, cl.colors.error)
        : soft
        ? (cl.colors.mintSoft, cl.colors.mintText, cl.colors.mintSoft)
        : (cl.colors.mintDeep, cl.colors.onMintDeep, cl.colors.mintDeep);
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        width: expand ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
      ),
    );
  }
}

/// A small tag: the latest reaction (5e) or "Có dấu hiệu" (5b, 5d, 5e).
class SdTag extends StatelessWidget {
  const SdTag(this.label, {required this.fill, required this.ink, super.key});

  /// "Thích" mint; the others neutral (P-164 #17: "Chưa hợp" is not a warning).
  factory SdTag.reaction(BuildContext context, SdReaction r) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return r == SdReaction.liked
        ? SdTag(
            sdReactionLabel(l10n, r),
            fill: cl.colors.mintSoft,
            ink: cl.colors.mintText,
          )
        : SdTag(
            sdReactionLabel(l10n, r),
            fill: cl.colors.surface2,
            ink: cl.colors.inkMuted,
          );
  }

  /// "Có dấu hiệu" (never "dị ứng", P-164 #6).
  factory SdTag.signs(BuildContext context) {
    final cl = context.cl;
    return SdTag(
      AppLocalizations.of(context).sdSignsTag,
      key: const Key('sdSignsTag'),
      fill: cl.colors.errorSoft,
      ink: cl.colors.error,
    );
  }

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(ClRadius.pill),
    ),
    child: Text(
      label,
      style: context.cl.text.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}

/// The meal's picture (5b cards, 5d rows): its photo (D-085 #2), else the ingredient icon. Inside
/// a card or row that opens the meal, so the photo itself does not open full screen.
class SdMealThumb extends StatelessWidget {
  const SdMealThumb({required this.meal, this.size = 56, super.key});
  final SdMeal meal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = meal.photoPath;
    if (photo != null) {
      return SdPhotoTile(
        key: Key('sdThumb_${meal.id}'),
        path: photo,
        size: size,
        open: false,
      );
    }
    final bottle = context.cl.care.bottle;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bottle.soft,
        borderRadius: BorderRadius.circular(size >= 56 ? 14 : 12),
      ),
      alignment: Alignment.center,
      child: ClIcon(ClIcons.feed, size: size * 0.42, color: bottle.ink),
    );
  }
}

/// 5b meal card: picture, "Bữa sáng · 08:10", the dish, "½ chén · Thích", ingredient chips (✦ for
/// a first try), "Có dấu hiệu", who logged it and the pending state.
class SdMealCard extends StatelessWidget {
  const SdMealCard({
    required this.meal,
    required this.foods,
    required this.firstTries,
    required this.myUid,
    required this.onTap,
    super.key,
  });

  final SdMeal meal;
  final Map<String, SdFood> foods;
  final Set<String> firstTries;
  final String myUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final title = sdMealTitle(meal, foods, locale);
    final line = sdMealLine(l10n, tag, meal);
    final head = l10n.sdSlotTime(
      sdSlotMealLabel(l10n, meal.slot),
      sdTime(tag, meal.occurredAt),
    );
    final who = [
      sdLoggedBy(l10n, meal, myUid),
      if (meal.pending) l10n.carePending,
    ].join(' · ');
    final firsts = [
      for (final id in meal.foodIds)
        if (firstTries.contains(id)) sdFoodName(id, foods, locale),
    ];
    return ClPressable(
      key: Key('sdMeal_${meal.id}'),
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [
        head,
        title,
        if (line.isNotEmpty) line,
        if (firsts.isNotEmpty) l10n.sdFirstToday(firsts.join(', ')),
        if (meal.hasSymptoms) l10n.sdSignsTag,
        who,
      ].join('. '),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SdMealThumb(meal: meal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        head,
                        style: cl.text.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (line.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          line,
                          style: cl.text.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (meal.hasSymptoms) ...[
                  const SizedBox(width: 8),
                  SdTag.signs(context),
                ],
              ],
            ),
            if (meal.foodIds.isNotEmpty || meal.freeFoods.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in meal.foodIds)
                    SdFoodChip(
                      sdFoodName(id, foods, locale),
                      look: firstTries.contains(id)
                          ? SdChipLook.firstTry
                          : SdChipLook.plain,
                      semanticLabel: firstTries.contains(id)
                          ? l10n.sdFirstTryChip(sdFoodName(id, foods, locale))
                          : null,
                    ),
                  for (final f in meal.freeFoods) SdFoodChip(f),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              who,
              style: cl.text.caption.copyWith(
                fontSize: 12,
                color: meal.pending ? cl.colors.pending : cl.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5b week strip: seven days T2 → CN with a dot on days with meals; swipe right for earlier
/// weeks, back to [today]'s week at most. Days after today and before [first] are muted and not
/// selectable. Above it, the week shown ("05/10 – 11/10") and, away from today, "Hôm nay"
/// (D-086 §12 #3).
class SdWeekStrip extends StatefulWidget {
  const SdWeekStrip({
    required this.today,
    required this.selected,
    required this.mealDays,
    required this.onSelect,
    this.first,
    super.key,
  });

  final DateTime today;
  final DateTime selected;
  final Set<DateTime> mealDays;
  final ValueChanged<DateTime> onSelect;

  /// The earliest day with a diary (the 6-month day or the first meal).
  final DateTime? first;

  @override
  State<SdWeekStrip> createState() => _SdWeekStripState();
}

class _SdWeekStripState extends State<SdWeekStrip> {
  late final PageController _pages = PageController(
    initialPage: _weeksBack(widget.selected),
  );
  late int _page = _weeksBack(widget.selected);

  /// "Hôm nay": today selected, back to this week.
  void _toToday() {
    widget.onSelect(widget.today);
    if (_pages.hasClients) {
      final duration = context.motion(ClMotion.standard);
      if (duration == Duration.zero) {
        _pages.jumpToPage(0);
      } else {
        unawaited(
          _pages.animateToPage(
            0,
            duration: duration,
            curve: Curves.easeOutCubic,
          ),
        );
      }
    }
    setState(() => _page = 0);
  }

  int _weeksBack(DateTime day) =>
      sdWeekStart(widget.today).difference(sdWeekStart(day)).inDays ~/ 7;

  int get _count {
    final first = widget.first;
    if (first == null || first.isAfter(widget.today)) return 1;
    return (_weeksBack(first) + 1).clamp(1, 260);
  }

  @override
  void didUpdateWidget(SdWeekStrip old) {
    super.didUpdateWidget(old);
    final page = _weeksBack(widget.selected);
    if (old.selected != widget.selected &&
        _pages.hasClients &&
        _pages.page?.round() != page &&
        page < _count) {
      _pages.jumpToPage(page);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = widget.today;
    Widget cell(DateTime d) {
      final future = d.isAfter(today);
      final before = widget.first != null && d.isBefore(widget.first!);
      final off = future || before;
      final selected = d == widget.selected;
      final dot = widget.mealDays.contains(d);
      final ink = selected
          ? cl.colors.onMintDeep
          : off
          ? cl.colors.inkMuted
          : cl.colors.ink;
      final label = '${weekdayShort(locale, d)} ${d.day}';
      return Expanded(
        child: ClPressable(
          key: Key('sdDay_${d.year}-${d.month}-${d.day}'),
          onPressed: off ? null : () => widget.onSelect(d),
          selected: selected,
          semanticLabel: label,
          child: AnimatedContainer(
            duration: context.motion(ClMotion.quick),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cl.colors.mintDeep : cl.colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  weekdayShort(locale, d),
                  style: cl.text.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected ? cl.colors.onMintDeep : cl.colors.inkMuted,
                  ),
                ),
                Text(
                  '${d.day}',
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dot
                        ? (selected ? cl.colors.onMintDeep : cl.colors.mintText)
                        : const Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final start = sdWeekStart(today);
    final shown = DateTime(start.year, start.month, start.day - 7 * _page);
    final away = _page != 0 || widget.selected != today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${sdShortDate(locale, shown)} – '
                  '${sdShortDate(locale, DateTime(shown.year, shown.month, shown.day + 6))}',
                  key: const Key('sdWeekRange'),
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cl.colors.inkMuted,
                  ),
                ),
              ),
              if (away)
                ClPressable(
                  key: const Key('sdWeekToday'),
                  onPressed: _toToday,
                  semanticLabel: l10n.sdToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.mintSoft,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      l10n.sdToday,
                      style: cl.text.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cl.colors.mintText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 64,
          child: PageView.builder(
            key: const Key('sdWeekStrip'),
            controller: _pages,
            reverse: true,
            itemCount: _count,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) {
              final start = sdWeekStart(today);
              final monday = DateTime(
                start.year,
                start.month,
                start.day - 7 * i,
              );
              return Row(
                children: [
                  for (var k = 0; k < 7; k++) ...[
                    if (k > 0) const SizedBox(width: 6),
                    cell(DateTime(monday.year, monday.month, monday.day + k)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 5c slot control: five options in one pill row (Sáng · Trưa · Chiều · Tối · Phụ).
class SdSlotPicker extends StatelessWidget {
  const SdSlotPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });
  final SdSlot selected;
  final ValueChanged<SdSlot> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        children: [
          for (final s in SdSlot.values)
            Expanded(
              child: ClPressable(
                key: Key('sdSlot_${s.name}'),
                onPressed: () => onChanged(s),
                selected: s == selected,
                pressedOpacity: 1,
                semanticLabel: sdSlotLabel(l10n, s),
                child: AnimatedContainer(
                  duration: context.motion(ClMotion.quick),
                  height: 38,
                  decoration: BoxDecoration(
                    color: s == selected
                        ? cl.colors.surface
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                    boxShadow: s == selected ? cl.shadows.card : null,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      sdSlotLabel(l10n, s),
                      style: cl.text.label.copyWith(
                        fontSize: 14,
                        fontWeight: s == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: s == selected
                            ? cl.colors.ink
                            : cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A field label (SemiBold 13 muted) above a 5c control.
class SdLabel extends StatelessWidget {
  const SdLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: context.cl.text.label.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.cl.colors.inkMuted,
      ),
    ),
  );
}

/// The 5e footnote (P-164 #17).
class SdFootnote extends StatelessWidget {
  const SdFootnote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s4),
    child: Text(
      text,
      key: const Key('sdFootnote'),
      style: context.cl.text.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: context.cl.colors.inkMuted,
      ),
    ),
  );
}
