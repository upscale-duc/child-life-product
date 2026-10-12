import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../onboarding/setup_screens.dart' show relationLabel;
import '../vaccines/vaccine_photos.dart';
import 'spending_calc.dart';
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_repository.dart';
import 'spending_sheets.dart';
import 'spending_widgets.dart';

// ---------- 8b Chi tiêu · tháng này / 8j lần đầu ----------

class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  YearMonth? _month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    if (!scope.access.any) {
      return SpPage(
        children: [
          SpTitle(l10n.spTitle),
          const SizedBox(height: ClSpace.s4),
          SpBanner(icon: ClIcons.lock, text: l10n.spNoAccess),
        ],
      );
    }
    if (scope.loading) return SpPage(children: [SpTitle(l10n.spTitle)]);
    if (scope.expenses.isEmpty && scope.access.record) {
      return _FirstUse(scope: scope);
    }
    if (!scope.access.viewAll) return _OwnOnly(scope: scope);
    final current = monthOf(scope.today);
    final month = _month ?? current;
    return _Month(
      scope: scope,
      month: month,
      onMonth: (m) => setState(() => _month = m),
    );
  }
}

/// 8j: nothing recorded yet for this baby.
class _FirstUse extends StatelessWidget {
  const _FirstUse({required this.scope});
  final SpendingScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    Widget chip(Color soft, Color ink, ClIcons icon) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: ClIcon(icon, size: 20, color: ink),
    );
    Widget point(ClIcons icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: 18, color: cl.colors.mintText),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              text,
              style: cl.text.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    final name = scope.baby?.nickname ?? '';
    return SpPage(
      children: [
        SpTitle(l10n.spTitle),
        const SizedBox(height: ClSpace.s4),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              chip(care.bottle.soft, care.bottle.ink, ClIcons.feed),
              const SizedBox(width: ClSpace.s3),
              chip(care.diaper.soft, care.diaper.ink, ClIcons.diaper),
              const SizedBox(width: ClSpace.s3),
              chip(care.pump.soft, care.pump.ink, ClIcons.heart),
              const SizedBox(width: ClSpace.s3),
              chip(care.growth.soft, care.growth.ink, ClIcons.family),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.spFirstTitle(name),
          textAlign: TextAlign.center,
          style: cl.text.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          scope.access.parent ? l10n.spFirstBody : l10n.spFirstBodyRecorder,
          textAlign: TextAlign.center,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        SpGroup(
          children: [
            point(ClIcons.plus, l10n.spFirstPoint1),
            if (scope.access.viewAll) ...[
              point(ClIcons.grid, l10n.spFirstPoint2),
              point(ClIcons.sliders, l10n.spFirstPoint3),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          key: const Key('spFirstAdd'),
          label: l10n.spFirstAdd,
          expand: true,
          onPressed: () => showExpenseSheet(context, scope: scope),
        ),
        if (scope.access.parent) ...[
          const SizedBox(height: ClSpace.s1),
          ClButton(
            key: const Key('spFirstImport'),
            label: l10n.spFirstImport,
            icon: ClIcons.download,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => context.push(Routes.spendingImport),
          ),
          ClButton(
            label: l10n.spFirstBudget,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => context.push(Routes.spendingBudget),
          ),
        ],
      ],
    );
  }
}

/// "Ghi khoản đã chi" without "Xem toàn bộ": only one's own items, no totals (8l banner).
class _OwnOnly extends StatelessWidget {
  const _OwnOnly({required this.scope});
  final SpendingScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpPage(
      bottom: SpBottomButton(
        label: l10n.spAdd,
        onPressed: () => showExpenseSheet(context, scope: scope),
      ),
      children: [
        SpTitle(l10n.spTitle),
        const SizedBox(height: ClSpace.s3),
        SpBanner(icon: ClIcons.lock, text: l10n.spOwnOnlyNote),
        const SizedBox(height: ClSpace.s4),
        ClSectionHeader(title: l10n.spMine),
        const SizedBox(height: ClSpace.s2),
        _DayGroups(scope: scope, items: scope.expenses),
      ],
    );
  }
}

class _Month extends ConsumerWidget {
  const _Month({
    required this.scope,
    required this.month,
    required this.onMonth,
  });

  final SpendingScope scope;
  final YearMonth month;
  final ValueChanged<YearMonth> onMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final current = monthOf(scope.today);
    final isCurrent = month == current;
    final s = MonthSummary.of(scope.expenses, month, scope.today);
    final budget =
        ref.watch(budgetProvider(scope.babyId)).value ?? Budget.empty;
    final name = scope.baby?.nickname ?? '';
    final recent = s.items.take(4).toList();
    final ranked = s.ranked;
    return SpPage(
      bottom: scope.access.record
          ? SpBottomButton(
              key: const Key('spAdd'),
              label: l10n.spAdd,
              onPressed: () => showExpenseSheet(context, scope: scope),
            )
          : null,
      children: [
        SpTitle(l10n.spTitle),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            _MonthArrow(
              icon: ClIcons.back,
              label: l10n.spPrevMonth,
              onPressed: () => onMonth(addMonths(month, -1)),
            ),
            const SizedBox(width: ClSpace.s2),
            Text(
              l10n.spMonthLabel(month.month, month.year),
              style: cl.text.bodyStrong,
            ),
            const SizedBox(width: ClSpace.s2),
            _MonthArrow(
              icon: ClIcons.chevronRight,
              label: l10n.spNextMonth,
              onPressed: isCurrent ? null : () => onMonth(addMonths(month, 1)),
            ),
            const Spacer(),
            if (isCurrent)
              Text(
                l10n.spUpTo(DateFormat('dd/MM').format(scope.today)),
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        _TotalCard(
          title: l10n.spSpentOn(name),
          summary: s,
          budget: budget,
          locale: locale,
        ),
        const SizedBox(height: ClSpace.s3),
        // One line that scrolls sideways (four shortcuts with "Nhập", D-060).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              SpPill(
                icon: ClIcons.grid,
                label: l10n.spStats,
                onPressed: () => context.push(Routes.spendingStats),
              ),
              const SizedBox(width: ClSpace.s2),
              SpPill(
                icon: ClIcons.sliders,
                label: l10n.spBudget,
                onPressed: () => context.push(Routes.spendingBudget),
              ),
              const SizedBox(width: ClSpace.s2),
              SpPill(
                icon: ClIcons.retry,
                label: l10n.spRecurring,
                onPressed: () => context.push(Routes.spendingRecurring),
              ),
              // Nhập chi tiêu (D-060), Cùng nuôi only.
              if (scope.access.parent) ...[
                const SizedBox(width: ClSpace.s2),
                SpPill(
                  key: const Key('spImport'),
                  icon: ClIcons.download,
                  label: l10n.spImport,
                  onPressed: () => context.push(Routes.spendingImport),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        ClSectionHeader(
          title: l10n.spByCategory,
          linkLabel: ranked.isEmpty ? null : l10n.spSeeStats,
          onLink: () => context.push(Routes.spendingStats),
        ),
        const SizedBox(height: ClSpace.s2),
        if (ranked.isEmpty)
          SpBanner(icon: ClIcons.today, text: l10n.spMonthEmpty)
        else
          SpGroup(
            children: [
              for (final e in ranked)
                CategoryShareRow(
                  category: scope.category(e.key),
                  amount: e.value,
                  share: s.total == 0 ? 0 : e.value / s.total,
                  subline: _categorySub(l10n, s, e.key),
                ),
            ],
          ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s6),
          ClSectionHeader(
            title: l10n.spRecent,
            linkLabel: l10n.spSeeAll,
            onLink: () => context.push(Routes.spendingHistory),
          ),
          const SizedBox(height: ClSpace.s2),
          SpGroup(
            children: [
              for (final e in recent)
                ExpenseRow(
                  expense: e,
                  category: scope.category(e.categoryId),
                  subline: expenseSubline(
                    l10n,
                    e,
                    lead: spDayShort(l10n, e.spentOn, scope.today),
                  ),
                  onTap: () =>
                      context.push('${Routes.spendingExpense}/${e.id}'),
                ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          scope.access.parent ? l10n.spParentsOnly : l10n.spSharedWithYou,
          textAlign: TextAlign.center,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }

  static String _categorySub(
    AppLocalizations l10n,
    MonthSummary s,
    String categoryId,
  ) {
    final n = s.countIn(categoryId);
    final shots = s.vaccinesIn(categoryId);
    return [
      l10n.spItems(n),
      if (shots > 0) l10n.spIncludesShots(shots),
    ].join(' · ');
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final ClIcons icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: ClPressable(
        onPressed: onPressed,
        semanticLabel: label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cl.colors.surface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: ClIcon(icon, size: 16, color: cl.colors.ink),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.title,
    required this.summary,
    required this.budget,
    required this.locale,
  });

  final String title;
  final MonthSummary summary;
  final Budget budget;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final s = summary;
    final total = budget.monthlyTotal ?? 0;
    final share = total == 0 ? 0.0 : s.total / total;
    final over = total > 0 && s.total > total;
    final change = s.change;
    final prevMonth = addMonths(s.month, -1).month;
    Widget kpi(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClTabularText(
              value,
              style: cl.text.body.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
    return SpCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          ClTabularText(
            money(locale, s.total),
            style: cl.text.largeTitle.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (budget.isSet) ...[
            const SizedBox(height: ClSpace.s2),
            ShareBar(
              share: share,
              height: 10,
              color: over ? cl.colors.error : cl.colors.mintDeep,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.spBudgetShare(percent(share), money(locale, total)),
                    style: cl.text.label.copyWith(
                      color: cl.colors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Text(
                  over
                      ? l10n.spOverBy(money(locale, s.total - total))
                      : l10n.spLeft(money(locale, total - s.total)),
                  style: cl.text.label.copyWith(
                    color: over ? cl.colors.error : cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              kpi(money(locale, s.averagePerDay), l10n.spAvgPerDay),
              const SizedBox(width: ClSpace.s2),
              kpi(
                change == null
                    ? '—'
                    : change.abs() < 0.005
                    ? l10n.spSame
                    : change < 0
                    ? l10n.spLower(percent(change.abs()))
                    : l10n.spHigher(percent(change)),
                l10n.spComparedWith(prevMonth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- 8f Tất cả khoản chi ----------

class SpendingHistoryScreen extends ConsumerStatefulWidget {
  const SpendingHistoryScreen({super.key});

  @override
  ConsumerState<SpendingHistoryScreen> createState() =>
      _SpendingHistoryScreenState();
}

class _SpendingHistoryScreenState extends ConsumerState<SpendingHistoryScreen> {
  ExpenseFilter? _filter;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<T?> _choose<T>({
    required String title,
    required List<(T?, String)> options,
    required T? current,
  }) => showClSheet<T>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        Flexible(
          child: SingleChildScrollView(
            child: ClCardGroupLike(
              children: [
                for (final (value, label) in options)
                  ClPressable(
                    onPressed: () => Navigator.of(sheet).pop(value),
                    semanticLabel: label,
                    selected: value == current,
                    pressedOpacity: ClPressable.surfaceOpacity,
                    child: Padding(
                      padding: const EdgeInsets.all(ClSpace.s4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(label, style: sheet.cl.text.body),
                          ),
                          ClRadio(selected: value == current),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final f = _filter ?? ExpenseFilter(month: monthOf(scope.today));
    final items = [
      for (final e in scope.expenses)
        if (f.matches(e, (id) => categoryName(l10n, scope.category(id)))) e,
    ];
    final months =
        <YearMonth>{
            monthOf(scope.today),
            for (final e in scope.expenses) monthOf(e.spentOn),
          }.toList()
          ..sort((a, b) => (b.year * 12 + b.month) - (a.year * 12 + a.month));
    final payers = <String, Payer?>{
      for (final e in scope.expenses) e.payer?.uid ?? '': e.payer,
    };
    void set(ExpenseFilter next) => setState(() => _filter = next);
    Widget chip(
      String label,
      bool on,
      VoidCallback onTap, {
      bool menu = true,
    }) => ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: on,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: on ? cl.colors.ink : cl.colors.surface,
          border: on ? null : Border.all(color: cl.colors.separator),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: cl.text.label.copyWith(
                color: on ? cl.colors.surface : cl.colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (menu) ...[
              const SizedBox(width: 4),
              ClIcon(
                ClIcons.chevronDown,
                size: 14,
                color: on ? cl.colors.surface : cl.colors.ink,
              ),
            ],
          ],
        ),
      ),
    );
    return SpPage(
      children: [
        SpTitle(l10n.spAllTitle),
        const SizedBox(height: ClSpace.s3),
        _SearchField(
          controller: _query,
          placeholder: l10n.spSearch,
          onChanged: (q) => set(f.copyWith(query: q)),
        ),
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              chip(
                f.month == null
                    ? l10n.spAllMonths
                    : l10n.spMonthShort(f.month!.month, f.month!.year),
                f.month != null,
                () async {
                  final m = await _choose<YearMonth>(
                    title: l10n.spFilterMonth,
                    current: f.month,
                    options: [
                      (null, l10n.spAllMonths),
                      for (final m in months)
                        (m, l10n.spMonthLabel(m.month, m.year)),
                    ],
                  );
                  if (mounted) set(f.copyWith(month: () => m));
                },
              ),
              const SizedBox(width: ClSpace.s2),
              chip(
                f.categoryId == null
                    ? l10n.spAllCategories
                    : categoryName(l10n, scope.category(f.categoryId!)),
                f.categoryId != null,
                () async {
                  final c = await _choose<String>(
                    title: l10n.spCategory,
                    current: f.categoryId,
                    options: [
                      (null, l10n.spAllCategories),
                      for (final c in scope.categories)
                        (c.id, categoryName(l10n, c)),
                    ],
                  );
                  if (mounted) set(f.copyWith(categoryId: () => c));
                },
              ),
              const SizedBox(width: ClSpace.s2),
              chip(
                f.payerUid == null
                    ? l10n.spPayer
                    : payerLabel(l10n, payers[f.payerUid]),
                f.payerUid != null,
                () async {
                  final p = await _choose<String>(
                    title: l10n.spPayer,
                    current: f.payerUid,
                    options: [
                      (null, l10n.spAnyone),
                      for (final e in payers.entries)
                        (e.key, payerLabel(l10n, e.value)),
                    ],
                  );
                  if (mounted) set(f.copyWith(payerUid: () => p));
                },
              ),
              const SizedBox(width: ClSpace.s2),
              chip(
                l10n.spHasReceipt,
                f.receiptOnly,
                () => set(f.copyWith(receiptOnly: !f.receiptOnly)),
                menu: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s6),
            child: Text(
              scope.expenses.isEmpty ? l10n.spNothingYet : l10n.spNoMatch,
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          )
        else
          _DayGroups(scope: scope, items: items),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        border: Border.all(color: cl.colors.controlBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: TextField(
              key: const Key('spSearch'),
              controller: controller,
              onChanged: onChanged,
              style: cl.text.body,
              cursorColor: cl.colors.mintDeep,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Day headers with the day's total, then the day's items (8f).
class _DayGroups extends StatelessWidget {
  const _DayGroups({required this.scope, required this.items});
  final SpendingScope scope;
  final List<Expense> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: ClSpace.s4),
        child: Text(
          l10n.spNothingYet,
          textAlign: TextAlign.center,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
      );
    }
    final days = <DateTime, List<Expense>>{};
    for (final e in items) {
      days.putIfAbsent(e.spentOn, () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in days.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, ClSpace.s3, 4, ClSpace.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    spDayHeader(l10n, entry.key, scope.today),
                    style: cl.text.label.copyWith(
                      color: cl.colors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ClTabularText(
                  money(locale, sumOf(entry.value)),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          SpGroup(
            children: [
              for (final e in entry.value)
                ExpenseRow(
                  expense: e,
                  category: scope.category(e.categoryId),
                  subline: expenseSubline(l10n, e),
                  onTap: () =>
                      context.push('${Routes.spendingExpense}/${e.id}'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------- 8g Chi tiết khoản chi ----------

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final e = scope.expenses.where((x) => x.id == expenseId).firstOrNull;
    if (e == null) {
      return SpPage(
        children: [
          if (!scope.loading)
            Padding(
              padding: const EdgeInsets.only(top: ClSpace.s8),
              child: Text(
                l10n.spGone,
                textAlign: TextAlign.center,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
            ),
        ],
      );
    }
    final locale = spLocale(context);
    final c = scope.category(e.categoryId);
    final t = tintColors(context, c.tint);
    final canEdit = scope.access.canEdit(e);
    final title = e.note.isEmpty ? categoryName(l10n, c) : e.note;
    final at = e.createdAt == null
        ? null
        : DateFormat(
            'dd/MM, HH:mm',
          ).format(inBabyZone(scope.zone, e.createdAt!));
    final recorder = authorLabel(
      l10n,
      e.author,
      isMe: e.createdBy == scope.me.uid,
      relationLabel: (r, cu) => relationLabel(l10n, r, cu),
    );
    Widget info(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: 12),
      child: Row(
        children: [
          Text(label, style: spRowTitle(context)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
    return SpPage(
      trailing: canEdit
          ? SpRoundIcon(
              icon: ClIcons.edit,
              label: l10n.actionEdit,
              onPressed: () =>
                  showExpenseSheet(context, scope: scope, expense: e),
            )
          : const SizedBox.shrink(),
      children: [
        const SizedBox(height: ClSpace.s2),
        Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: ClIcon(c.icon, size: 28, color: t.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Center(
          child: ClTabularText(
            money(locale, e.amount),
            style: cl.text.largeTitle.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(title, textAlign: TextAlign.center, style: cl.text.bodyStrong),
        if (e.pending)
          Text(
            l10n.spPending,
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        const SizedBox(height: ClSpace.s4),
        SpGroup(
          children: [
            info(l10n.spCategory, categoryName(l10n, c)),
            info(l10n.spDate, DateFormat('dd/MM/yyyy').format(e.spentOn)),
            info(l10n.spPayer, payerLabel(l10n, e.payer)),
            info(l10n.spRecordedBy, at == null ? recorder : '$recorder · $at'),
            if (e.source == ExpenseSource.import && e.sourceRef != null)
              SpActionRow(
                icon: ClIcons.download,
                label: l10n.spSource,
                value: l10n.spFromImportFull,
                onTap: () =>
                    context.push('${Routes.spendingImport}/${e.sourceRef}'),
              ),
            if (e.source == ExpenseSource.recurring)
              info(l10n.spSource, l10n.spFromRecurringFull),
            if (e.source == ExpenseSource.vaccine && e.sourceRef != null)
              SpActionRow(
                icon: ClIcons.heart,
                label: l10n.spLink,
                value: l10n.spLinkVaccine(e.note),
                onTap: () =>
                    context.push('${Routes.vaccineDose}/${e.sourceRef}'),
              ),
          ],
        ),
        if (e.receiptPath case final path?) ...[
          const SizedBox(height: ClSpace.s6),
          Text(l10n.spReceiptTitle, style: cl.text.headline),
          const SizedBox(height: ClSpace.s2),
          ClPressable(
            onPressed: () => showVxPhotoViewer(context, [path]),
            semanticLabel: l10n.spReceiptOpen,
            child: SpCard(
              radius: 16,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image(
                        image: vxPhotoImage(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: cl.colors.surface2),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.spReceiptOpen,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: ClSpace.s6),
          ClButton(
            key: const Key('spDeleteExpense'),
            label: l10n.spDelete,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () {
              final toaster = ClToaster.of(context);
              final repo = ref.read(spendingRepositoryProvider);
              void failed(Object _) => toaster.show(message: l10n.spSaveFailed);
              repo.deleteExpense(scope.babyId, e.id, scope.me, onError: failed);
              Navigator.of(context).maybePop();
              toaster.show(
                message: l10n.spDeleted,
                actionLabel: l10n.undo,
                onAction: () => repo.deleteExpense(
                  scope.babyId,
                  e.id,
                  scope.me,
                  undo: true,
                  onError: failed,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
