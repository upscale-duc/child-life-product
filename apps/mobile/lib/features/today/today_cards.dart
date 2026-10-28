import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memories_screen.dart' show memoryCtx;
import '../memories/memory_sheets.dart' show showAddSheet;
import '../reminders/reminder_screens.dart' show showReminderSheet;
import '../spending/spending_calc.dart';
import '../spending/spending_format.dart';
import '../spending/spending_models.dart';
import '../spending/spending_repository.dart';
import '../spending/spending_sheets.dart' show showExpenseSheet;
import '../spending/spending_widgets.dart' show watchSpending;
import '../vaccines/vaccine_format.dart';
import '../home/home_shell.dart';
import 'today_layout.dart';

/// The opt-in parts of Hôm nay (owner, 2026-10-12), chosen in "Tuỳ chỉnh Hôm nay".

/// "Tạo nhanh": one tap to a new reminder, an expense, the vaccination book or a memory.
class TodayQuickActions extends ConsumerWidget {
  const TodayQuickActions({required this.layout, super.key});
  final TodayLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final allowed = allowedActions(me);
    final actions = [
      for (final a in layout.actionOrder)
        if (allowed.contains(a) && !layout.hiddenActions.contains(a)) a,
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    // Kept listening so the expense sheet opens with "Lần trước" and the categories.
    final spending = actions.contains(QuickAction.expense)
        ? watchSpending(ref)
        : null;

    void run(QuickAction a) {
      switch (a) {
        case QuickAction.reminder:
          unawaited(showReminderSheet(context));
        case QuickAction.expense:
          if (spending != null) {
            unawaited(showExpenseSheet(context, scope: spending));
          }
        case QuickAction.vaccine:
          unawaited(context.push(Routes.vaccines));
        case QuickAction.memory:
          final c = memoryCtx(context, ref);
          if (c != null) unawaited(showAddSheet(context, ref, c));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.sectionQuickActions),
        const SizedBox(height: ClSpace.s2),
        Row(
          children: [
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s2),
              Expanded(
                child: ClPressable(
                  key: Key('quick-${a.name}'),
                  onPressed: () => run(a),
                  semanticLabel: quickActionHint(l10n, a),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: ClSpace.s3,
                      horizontal: ClSpace.s1,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: cl.shadows.card,
                    ),
                    child: Column(
                      children: [
                        QuickActionIcon(action: a),
                        const SizedBox(height: ClSpace.s2),
                        Text(
                          quickActionLabel(l10n, a),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// "Mũi tiêm sắp tới": the next (or overdue) shots, opening the vaccination book.
class TodayVaccineCard extends ConsumerWidget {
  const TodayVaccineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final (title, subtitle) = switch (ref.watch(vaccineBookProvider(me))) {
      VaccineBookReady(:final book) when book.overdue.isNotEmpty => (
        l10n.vxTileOverdue(book.overdue.length),
        l10n.todayVaccineOpen,
      ),
      VaccineBookReady(:final book) => switch (book.nextGroup) {
        final g? => (
          l10n.vxTileNext(vxDay(g.date)),
          l10n.todayVaccineShots(g.items.length),
        ),
        null => (l10n.vxTileAllDone, l10n.todayVaccineOpen),
      },
      _ => (l10n.vxTileBook, l10n.todayVaccineOpen),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.sectionVaccine),
        const SizedBox(height: ClSpace.s2),
        _CardRow(
          key: const Key('todayVaccine'),
          icon: ClIcons.heart,
          soft: cl.colors.peachSoft,
          ink: cl.care.growth.ink,
          title: title,
          subtitle: subtitle,
          onTap: () => context.push(Routes.vaccines),
        ),
      ],
    );
  }
}

/// "Chi tiêu tháng này": the month's total against the budget, opening Chi tiêu.
class TodaySpendingCard extends ConsumerWidget {
  const TodaySpendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null || !scope.access.viewAll) return const SizedBox.shrink();
    final locale = spLocale(context);
    // Chi tiêu currencies (D-075 #4): the household's currency, the others apart.
    final s = MonthSummary.of(
      scope.expenses,
      monthOf(scope.today),
      scope.today,
      currency: scope.currency,
    );
    final budget =
        ref.watch(budgetProvider(scope.babyId)).value ?? Budget.empty;
    final budgetHere =
        budget.isSet && budget.currencyOr(scope.currency) == scope.currency;
    final total = budget.monthlyTotal ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.sectionSpending),
        const SizedBox(height: ClSpace.s2),
        _CardRow(
          key: const Key('todaySpending'),
          icon: ClIcons.grid,
          soft: cl.care.growth.soft,
          ink: cl.care.growth.ink,
          title: monthMoney(locale, s, scope.currency),
          subtitle: budgetHere
              ? l10n.spBudgetShare(
                  percent(s.total / total),
                  money(locale, total, scope.currency),
                )
              : l10n.todaySpendingNoBudget,
          onTap: () => context.push(Routes.spending),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.icon,
    required this.soft,
    required this.ink,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final ClIcons icon;
  final Color soft;
  final Color ink;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '$title, $subtitle',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 20, color: ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
