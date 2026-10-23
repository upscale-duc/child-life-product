import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../care/history_screen.dart' show weekdayShort;
import '../nutrition/nutrition_widgets.dart' show NuCard;
import 'solids_calc.dart';
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_routes.dart';
import 'solids_state.dart';
import 'solids_widgets.dart';

/// 5d "Lịch" (D-086 §12 #3: "which day the baby ate what"): a month calendar with a dot and the
/// number of meals on each day, months back to the first meal (‹ ›, or a swipe), and the chosen
/// day's meals in the 5b card layout. Days come from the baby's time zone (R-061).
class SdCalendarView extends ConsumerStatefulWidget {
  const SdCalendarView({super.key});

  @override
  ConsumerState<SdCalendarView> createState() => _SdCalendarViewState();
}

class _SdCalendarViewState extends ConsumerState<SdCalendarView> {
  /// Index in the months, 0 = this month.
  int _index = 0;

  /// The chosen day; null = today (while this month shows).
  DateTime? _day;

  void _go(int index, List<DateTime> months, Map<DateTime, int> counts) {
    if (index < 0 || index >= months.length) return;
    final month = months[index];
    // The latest day with meals in that month (none: nothing chosen until a tap).
    final days = [
      for (final d in counts.keys)
        if (d.year == month.year && d.month == month.month) d,
    ]..sort();
    setState(() {
      _index = index;
      _day = days.lastOrNull ?? DateTime(month.year, month.month, 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    if (s == null) return const SizedBox.shrink();
    final b = s.baby;
    final today = b.today;
    final counts = sdMealCounts(s.meals, b.zone);
    final first = counts.keys.fold<DateTime?>(
      null,
      (a, d) => a == null || d.isBefore(a) ? d : a,
    );
    final months = sdCalendarMonths(first, today);
    final index = _index.clamp(0, months.length - 1);
    final month = months[index];
    final selected = _day ?? today;
    final inMonth =
        selected.year == month.year && selected.month == month.month;
    final meals = inMonth
        ? sdMealsOn(s.meals, b.zone, selected)
        : const <SdMeal>[];
    final firsts = {for (final m in meals) m.id: sdFirstTryIds(m, s.meals)};
    final label = toBeginningOfSentenceCase(
      DateFormat.yMMMM(tag).format(month),
    );
    // Weekday names, Monday first.
    final monday = sdWeekStart(today);

    Widget arrow(Key key, ClIcons icon, String label, int to) {
      final enabled = to >= 0 && to < months.length;
      return ClPressable(
        key: key,
        onPressed: enabled ? () => _go(to, months, counts) : null,
        semanticLabel: label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cl.colors.surface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: ClIcon(
            icon,
            size: 16,
            color: enabled ? cl.colors.ink : cl.colors.separator,
          ),
        ),
      );
    }

    Widget cell(DateTime? d) {
      if (d == null) return const Expanded(child: SizedBox(height: 52));
      final count = counts[d] ?? 0;
      final future = d.isAfter(today);
      final isSelected = inMonth && d == selected;
      final ink = isSelected
          ? cl.colors.onMintDeep
          : future
          ? cl.colors.inkMuted
          : cl.colors.ink;
      final dayLabel = sdDayLabel(l10n, tag, d, today);
      return Expanded(
        child: ClPressable(
          key: Key('sdCal_${d.year}-${d.month}-${d.day}'),
          onPressed: future ? null : () => setState(() => _day = d),
          selected: isSelected,
          semanticLabel: l10n.sdStatsDayTip(dayLabel, count),
          child: Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? cl.colors.mintDeep
                  : d == today
                  ? cl.colors.mintSoft
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${d.day}',
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 15,
                    fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w500,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 14,
                  child: count == 0
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cl.colors.onMintDeep
                                    : cl.colors.mintText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$count',
                              key: Key('sdCalCount_${d.month}-${d.day}'),
                              style: cl.text.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? cl.colors.onMintDeep
                                    : cl.colors.mintText,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final grid = sdMonthGrid(month);
    return Column(
      key: const Key('sdCalendar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          // Swipe right for the month before, left for the next.
          onHorizontalDragEnd: (e) {
            final v = e.primaryVelocity ?? 0;
            if (v > 200) _go(index + 1, months, counts);
            if (v < -200) _go(index - 1, months, counts);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              boxShadow: cl.shadows.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    arrow(
                      const Key('sdCalPrev'),
                      ClIcons.back,
                      l10n.sdCalendarPrev,
                      index + 1,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          label,
                          key: const Key('sdCalMonth'),
                          textAlign: TextAlign.center,
                          style: cl.text.headline.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    arrow(
                      const Key('sdCalNext'),
                      ClIcons.chevronRight,
                      l10n.sdCalendarNext,
                      index - 1,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var k = 0; k < 7; k++)
                        Expanded(
                          child: Text(
                            weekdayShort(
                              tag,
                              DateTime(
                                monday.year,
                                monday.month,
                                monday.day + k,
                              ),
                            ),
                            textAlign: TextAlign.center,
                            style: cl.text.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (var r = 0; r < grid.length; r += 7)
                  Row(
                    children: [for (final d in grid.sublist(r, r + 7)) cell(d)],
                  ),
              ],
            ),
          ),
        ),
        if (inMonth) ...[
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: ClSpace.s3),
            child: Semantics(
              header: true,
              child: Text(
                l10n.sdDayMeals(
                  sdDayLabel(l10n, tag, selected, today),
                  meals.length,
                ),
                key: const Key('sdCalDayHeader'),
                style: cl.text.headline.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (meals.isEmpty)
            NuCard(
              flat: true,
              child: Text(
                selected == today ? l10n.sdEmptyToday : l10n.sdEmptyDay,
                textAlign: TextAlign.center,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
            )
          else
            for (final m in meals) ...[
              SdMealCard(
                meal: m,
                foods: s.foods,
                firstTries: firsts[m.id]!,
                myUid: s.me.uid,
                onTap: () => context.push(SdRoutes.meal(m.id)),
              ),
              const SizedBox(height: ClSpace.s3),
            ],
        ] else
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s4),
            child: Text(
              l10n.sdCalendarHint,
              textAlign: TextAlign.center,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
      ],
    );
  }
}
