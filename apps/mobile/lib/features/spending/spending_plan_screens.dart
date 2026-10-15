import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../vaccines/vaccine_sheets.dart' show pickVxDate;
import 'spending_calc.dart';
import 'spending_currency.dart';
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_repository.dart';
import 'spending_sheets.dart';
import 'spending_widgets.dart';

/// An amount typed in a sheet (in [currency]'s minor units). 0 = "Bỏ mức" ([clearLabel]);
/// null = closed.
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  int? initial,
  String? clearLabel,
  String currency = legacyCurrency,
}) => showClSheet<int>(
  context: context,
  builder: (_) => _AmountSheet(
    title: title,
    initial: initial,
    clearLabel: clearLabel,
    currency: currency,
  ),
);

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.currency,
    this.initial,
    this.clearLabel,
  });
  final String title;
  final int? initial;
  final String? clearLabel;
  final String currency;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initial != null && widget.initial! > 0 && _amount.text.isEmpty) {
      _amount.text = moneyPlain(
        spLocale(context),
        widget.initial!,
        widget.currency,
      );
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: widget.title),
        const SizedBox(height: ClSpace.s2),
        SpAmountInput(
          controller: _amount,
          autofocus: true,
          currency: widget.currency,
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          key: const Key('spAmountDone'),
          label: l10n.actionSave,
          expand: true,
          onPressed: () {
            final v = parseMoney(
              _amount.text,
              widget.currency,
              spLocale(context),
            );
            Navigator.of(context).pop(v == null || v <= 0 ? 0 : v);
          },
        ),
        if (widget.clearLabel != null && (widget.initial ?? 0) > 0)
          ClButton(
            label: widget.clearLabel!,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(context).pop(0),
          ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- 8h Ngân sách tháng ----------

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  /// The edited budget; null until the stored one has loaded.
  Budget? _draft;

  /// The currency [_draft]'s amounts are in (D-075 #4: the household's).
  String? _draftCurrency;

  void _save(SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final d = _draft!;
    ref
        .read(spendingRepositoryProvider)
        .saveBudget(
          scope.babyId,
          scope.me,
          // The budget counts the household's currency (D-075 #4).
          Budget(
            monthlyTotal: d.monthlyTotal,
            caps: d.caps,
            alert80: d.alert80,
            currency: scope.currency,
          ),
          onError: (_) => toaster.show(message: l10n.spSaveFailed),
        );
    Navigator.of(context).maybePop();
    toaster.show(message: l10n.spBudgetSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final stored = ref.watch(budgetProvider(scope.babyId));
    if (!stored.hasValue) {
      return SpPage(children: [SpTitle(l10n.spBudgetTitle)]);
    }
    // D-075 #4: amounts are in the household's currency. A budget kept in another one (the
    // household changed since) starts empty, with a note, until saved again.
    final cur = scope.currency;
    final kept = stored.value!;
    final keptElsewhere =
        kept.stored &&
        kept.currencyOr(cur) != cur &&
        (kept.isSet || kept.caps.isNotEmpty);
    if (_draft == null || _draftCurrency != cur) {
      _draftCurrency = cur;
      _draft = keptElsewhere ? Budget(alert80: kept.alert80) : kept;
    }
    final b = _draft!;
    final canEdit = scope.access.parent;
    final month = MonthSummary.of(
      scope.expenses,
      monthOf(scope.today),
      scope.today,
      currency: cur,
    );
    final total = b.monthlyTotal ?? 0;
    final used = total == 0 ? 0.0 : month.total / total;
    final rows = [
      for (final c in scope.categories)
        if (!c.hidden || b.caps.containsKey(c.id)) c,
    ];
    return SpPage(
      bottom: canEdit
          ? SpBottomButton(
              key: const Key('spSaveBudget'),
              label: l10n.spSaveBudget,
              onPressed: () => _save(scope),
            )
          : null,
      children: [
        SpTitle(l10n.spBudgetTitle),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.spBudgetIntro,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        // D-075 #4 "Tiền tệ chính": the household's, set by a Cùng nuôi.
        SpGroup(
          children: [
            SpActionRow(
              key: const Key('spMainCurrency'),
              icon: ClIcons.globe,
              label: l10n.spCurrencyMain,
              value: canEdit
                  ? '$cur · ${currencyName(l10n, cur)}'
                  : l10n.spBudgetCurrencyNote(cur),
              onTap: canEdit
                  ? () async {
                      final toaster = ClToaster.of(context);
                      final picked = await pickSpCurrency(context, cur);
                      if (picked == null || picked == cur || !mounted) return;
                      ref
                          .read(spendingRepositoryProvider)
                          .saveCurrency(
                            scope.familyId,
                            scope.me,
                            picked,
                            onError: (_) =>
                                toaster.show(message: l10n.spSaveFailed),
                          );
                      toaster.show(message: l10n.spCurrencyMainSaved);
                    }
                  : null,
            ),
          ],
        ),
        if (canEdit) ...[
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.spCurrencyMainSub,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        if (keptElsewhere) ...[
          const SizedBox(height: ClSpace.s3),
          SpBanner(
            icon: ClIcons.globe,
            text: l10n.spBudgetOldCurrency(kept.currencyOr(cur), cur),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        ClPressable(
          onPressed: canEdit
              ? () async {
                  final v = await showAmountSheet(
                    context,
                    title: l10n.spBudgetPerMonth,
                    initial: b.monthlyTotal,
                    clearLabel: l10n.spClearCap,
                    currency: cur,
                  );
                  if (v != null && mounted) {
                    setState(
                      () => _draft = Budget(
                        monthlyTotal: v == 0 ? null : v,
                        caps: b.caps,
                        alert80: b.alert80,
                      ),
                    );
                  }
                }
              : null,
          semanticLabel: l10n.spBudgetPerMonth,
          child: SpCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spBudgetPerMonth,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ClTabularText(
                        total == 0 ? l10n.spNoCap : money(locale, total, cur),
                        style: cl.text.title.copyWith(
                          fontWeight: FontWeight.w700,
                          color: total == 0 ? cl.colors.inkMuted : null,
                        ),
                      ),
                    ),
                    if (canEdit)
                      ClIcon(ClIcons.edit, size: 18, color: cl.colors.inkMuted),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: ClSpace.s2),
                  ShareBar(
                    share: used,
                    color: used > 1 ? cl.colors.error : cl.colors.mintDeep,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.spBudgetUsed(scope.today.month, percent(used)),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(title: l10n.spByCategory),
        const SizedBox(height: ClSpace.s2),
        SpGroup(
          children: [
            for (final c in rows)
              _CapRow(
                category: c,
                spent: month.byCategory[c.id] ?? 0,
                cap: b.caps[c.id],
                currency: cur,
                onTap: canEdit
                    ? () async {
                        final v = await showAmountSheet(
                          context,
                          title: categoryName(l10n, c),
                          initial: b.caps[c.id],
                          clearLabel: l10n.spClearCap,
                          currency: cur,
                        );
                        if (v == null || !mounted) return;
                        final caps = {...b.caps};
                        if (v == 0) {
                          caps.remove(c.id);
                        } else {
                          caps[c.id] = v;
                        }
                        setState(
                          () => _draft = Budget(
                            monthlyTotal: b.monthlyTotal,
                            caps: caps,
                            alert80: b.alert80,
                          ),
                        );
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        SpGroup(
          children: [
            SpActionRow(
              icon: ClIcons.bell,
              label: l10n.spAlert80,
              value: l10n.spAlert80Sub,
              trailing: ClToggle(
                value: b.alert80,
                semanticLabel: l10n.spAlert80,
                onChanged: canEdit
                    ? (v) => setState(
                        () => _draft = Budget(
                          monthlyTotal: b.monthlyTotal,
                          caps: b.caps,
                          alert80: v,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapRow extends StatelessWidget {
  const _CapRow({
    required this.category,
    required this.spent,
    required this.cap,
    required this.currency,
    this.onTap,
  });

  final SpendingCategory category;
  final int spent;
  final int? cap;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final t = tintColors(context, category.tint);
    final cap = this.cap;
    final state = cap == null ? CapState.fine : capState(spent, cap);
    final share = cap == null || cap == 0 ? 0.0 : spent / cap;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          CategoryBadge(category: category),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryName(l10n, category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: spRowTitle(context),
                      ),
                    ),
                    if (cap == null)
                      Text(
                        l10n.spNoCap,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      )
                    else
                      // Plain figures: tabular digits would push the name out.
                      Text(
                        '${moneyPlain(locale, spent, currency)} / '
                        '${moneyPlain(locale, cap, currency)}',
                        style: spRowTitle(
                          context,
                        ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    if (cap == null && onTap != null) ...[
                      const SizedBox(width: ClSpace.s2),
                      ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText),
                    ],
                  ],
                ),
                if (cap != null) ...[
                  const SizedBox(height: 6),
                  ShareBar(
                    share: share,
                    color: state == CapState.fine ? t.accent : cl.colors.error,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    switch (state) {
                      CapState.fine => l10n.spUsedShare(percent(share)),
                      CapState.near => l10n.spNearCap(
                        money(locale, cap - spent, currency),
                      ),
                      CapState.over => l10n.spOverCap(
                        money(locale, spent - cap, currency),
                      ),
                    },
                    style: cl.text.caption.copyWith(
                      color: state == CapState.fine
                          ? cl.colors.inkMuted
                          : cl.colors.error,
                      fontWeight: state == CapState.fine
                          ? null
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: categoryName(l10n, category),
      child: SizedBox(width: double.infinity, child: row),
    );
  }
}

// ---------- 8i Khoản định kỳ ----------

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final items =
        ref.watch(recurringExpensesProvider(scope.babyId)).value ??
        const <RecurringExpense>[];
    final canEdit = scope.access.parent;
    // The next one the daily job will add.
    ({DateTime day, RecurringExpense item})? next;
    for (final r in items.where((r) => r.enabled)) {
      final d = r.schedule.nextAfter(scope.today);
      if (d != null && (next == null || d.isBefore(next.day))) {
        next = (day: d, item: r);
      }
    }
    return SpPage(
      children: [
        SpTitle(l10n.spRecurringTitle),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.spRecurringIntro,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        if (items.isEmpty)
          SpBanner(icon: ClIcons.retry, text: l10n.spRecurringEmpty)
        else
          SpGroup(
            children: [
              for (final r in items)
                _RecurringRow(
                  item: r,
                  category: scope.category(r.categoryId),
                  onTap: canEdit
                      ? () => showRecurringSheet(context, scope: scope, item: r)
                      : null,
                  onToggle: canEdit
                      ? (v) => ref
                            .read(spendingRepositoryProvider)
                            .setRecurringEnabled(
                              scope.babyId,
                              r.id,
                              scope.me,
                              v,
                              onError: (_) => ClToaster.of(
                                context,
                              ).show(message: l10n.spSaveFailed),
                            )
                      : null,
                ),
            ],
          ),
        if (canEdit) ...[
          const SizedBox(height: ClSpace.s4),
          ClButton(
            key: const Key('spAddRecurring'),
            label: l10n.spAddRecurring,
            icon: ClIcons.plus,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => showRecurringSheet(context, scope: scope),
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: ClSpace.s4),
          SpBanner(
            icon: ClIcons.clock,
            mint: true,
            text: l10n.spRecurringNext(
              DateFormat('d/M').format(next.day),
              next.item.title,
              money(locale, next.item.amount, next.item.currency),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.item,
    required this.category,
    this.onTap,
    this.onToggle,
  });

  final RecurringExpense item;
  final SpendingCategory category;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final sub = [
      scheduleLabel(l10n, item.schedule),
      if (item.payer != null) l10n.spPays(payerLabel(l10n, item.payer)),
    ].join(' · ');
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          CategoryBadge(category: category),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: spRowTitle(context)),
                Text(
                  sub,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: 2),
                ClTabularText(
                  money(spLocale(context), item.amount, item.currency),
                  style: cl.text.label.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Row(
      children: [
        Expanded(
          child: onTap == null
              ? body
              : ClPressable(
                  onPressed: onTap,
                  pressedOpacity: ClPressable.surfaceOpacity,
                  semanticLabel: '${item.title}, $sub',
                  child: SizedBox(width: double.infinity, child: body),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: ClSpace.s3),
          child: ClToggle(
            value: item.enabled,
            semanticLabel: item.title,
            onChanged: onToggle,
          ),
        ),
      ],
    );
  }
}

enum _Kind { monthly, weeks, yearly }

Future<void> showRecurringSheet(
  BuildContext context, {
  required SpendingScope scope,
  RecurringExpense? item,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _RecurringSheet(scope: scope, item: item),
);

class _RecurringSheet extends ConsumerStatefulWidget {
  const _RecurringSheet({required this.scope, this.item});
  final SpendingScope scope;
  final RecurringExpense? item;

  @override
  ConsumerState<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends ConsumerState<_RecurringSheet> {
  RecurringExpense? get _item => widget.item;
  SpendingScope get _scope => widget.scope;

  late final _title = TextEditingController(text: _item?.title);
  final _amount = TextEditingController();

  /// D-075 #4: each occurrence is written in it.
  late String _currency = _item?.currency ?? _scope.currency;
  late String _category =
      _item?.categoryId ?? _scope.visible.firstOrNull?.id ?? otherCategoryId;
  late Payer? _payer = _item == null ? Payer.of(_scope.me) : _item!.payer;
  late bool _enabled = _item?.enabled ?? true;
  late _Kind _kind = switch (_item?.schedule) {
    EveryWeeks() => _Kind.weeks,
    Yearly() => _Kind.yearly,
    _ => _Kind.monthly,
  };
  late List<int> _days = switch (_item?.schedule) {
    Monthly(:final days) => [...days],
    _ => [_scope.today.day],
  };
  late int _every = switch (_item?.schedule) {
    EveryWeeks(:final every) => every,
    _ => 2,
  };
  late DateTime _start = switch (_item?.schedule) {
    EveryWeeks(:final startOn) => startOn,
    _ => _scope.today,
  };
  late DateTime _yearly = switch (_item?.schedule) {
    Yearly(:final month, :final day) => DateTime(_scope.today.year, month, day),
    _ => _scope.today,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_item != null && _amount.text.isEmpty) {
      _amount.text = moneyPlain(
        spLocale(context),
        _item!.amount,
        _item!.currency,
      );
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await pickSpCurrency(context, _currency);
    if (picked == null || picked == _currency || !mounted) return;
    setState(() {
      _currency = picked;
      _amount.clear();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  RecurringSchedule get _schedule => switch (_kind) {
    _Kind.monthly => Monthly(([..._days]..sort()).take(2).toList()),
    _Kind.weeks => EveryWeeks(every: _every, startOn: _start),
    _Kind.yearly => Yearly(month: _yearly.month, day: _yearly.day),
  };

  Future<void> _pickDays() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<List<int>>(
      context: context,
      builder: (_) => _DaysSheet(initial: _days, title: l10n.spScheduleDays),
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _days = picked);
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final amount = parseMoney(_amount.text, _currency, spLocale(context));
    final title = _title.text.trim();
    if (title.isEmpty) {
      showClToast(context, message: l10n.spRecurringTitleMissing);
      return;
    }
    if (amount == null || amount <= 0) {
      showClToast(context, message: l10n.spAmountMissing);
      return;
    }
    final toaster = ClToaster.of(context);
    ref
        .read(spendingRepositoryProvider)
        .saveRecurring(
          babyId: _scope.babyId,
          me: _scope.me,
          id: _item?.id,
          title: title,
          categoryId: _category,
          amount: amount,
          currency: _currency,
          payer: _payer,
          schedule: _schedule,
          enabled: _enabled,
          onError: (_) => toaster.show(message: l10n.spSaveFailed),
        );
    Navigator.of(context).pop();
    toaster.show(message: l10n.spRecurringSaved);
  }

  void _delete() {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref
        .read(spendingRepositoryProvider)
        .deleteRecurring(
          _scope.babyId,
          _item!.id,
          onError: (_) => toaster.show(message: l10n.spSaveFailed),
        );
    Navigator.of(context).pop();
    toaster.show(message: l10n.spRecurringDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final dmy = DateFormat('dd/MM/yyyy');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: _item == null ? l10n.spAddRecurring : l10n.spEditRecurring,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SpAmountInput(
                  controller: _amount,
                  autofocus: _item == null,
                  currency: _currency,
                  onCurrency: () => unawaited(_pickCurrency()),
                ),
                SpLabel(l10n.spRecurringName),
                ClTextField(
                  key: const Key('spRecurringName'),
                  controller: _title,
                  placeholder: l10n.spRecurringNameHint,
                  standalone: true,
                  maxLength: SpendingLimits.recurringTitleMax,
                  textCapitalization: TextCapitalization.sentences,
                ),
                SpLabel(l10n.spCategory),
                CategoryPicker(
                  scope: _scope,
                  value: _category,
                  onChanged: (id) => setState(() => _category = id),
                ),
                SpLabel(l10n.spPayer),
                PayerPicker(
                  babyId: _scope.babyId,
                  value: _payer,
                  onChanged: (p) => setState(() => _payer = p),
                ),
                SpLabel(l10n.spSchedule),
                ClSegmented<_Kind>(
                  options: _Kind.values,
                  selected: _kind,
                  labelOf: (k) => switch (k) {
                    _Kind.monthly => l10n.spKindMonthly,
                    _Kind.weeks => l10n.spKindWeeks,
                    _Kind.yearly => l10n.spKindYearly,
                  },
                  onChanged: (k) => setState(() => _kind = k),
                ),
                const SizedBox(height: ClSpace.s3),
                ClCardGroupLike(
                  children: [
                    if (_kind == _Kind.monthly)
                      SpActionRow(
                        icon: ClIcons.today,
                        label: l10n.spScheduleDays,
                        value: scheduleLabel(l10n, _schedule),
                        onTap: () => unawaited(_pickDays()),
                      ),
                    if (_kind == _Kind.weeks) ...[
                      SpActionRow(
                        icon: ClIcons.retry,
                        label: l10n.spScheduleWeeks(_every),
                        trailing: _Stepper(
                          value: _every,
                          min: 1,
                          max: 8,
                          onChanged: (v) => setState(() => _every = v),
                        ),
                      ),
                      SpActionRow(
                        icon: ClIcons.today,
                        label: l10n.spStartOn,
                        value: dmy.format(_start),
                        onTap: () async {
                          final d = await pickVxDate(
                            context,
                            initial: _start,
                            first: DateTime(_scope.today.year - 1),
                            last: DateTime(_scope.today.year + 1, 12, 31),
                          );
                          if (d != null && mounted) setState(() => _start = d);
                        },
                      ),
                    ],
                    if (_kind == _Kind.yearly)
                      SpActionRow(
                        icon: ClIcons.today,
                        label: l10n.spScheduleOn,
                        value: scheduleLabel(l10n, _schedule),
                        onTap: () async {
                          final d = await pickVxDate(
                            context,
                            initial: _yearly,
                            first: DateTime(_scope.today.year, 1, 1),
                            last: DateTime(_scope.today.year, 12, 31),
                          );
                          if (d != null && mounted) {
                            setState(() => _yearly = d);
                          }
                        },
                      ),
                    SpActionRow(
                      icon: ClIcons.bell,
                      label: l10n.spRecurringOn,
                      trailing: ClToggle(
                        value: _enabled,
                        semanticLabel: l10n.spRecurringOn,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.spRecurringHelp,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                if (_item != null) ...[
                  const SizedBox(height: ClSpace.s3),
                  ClButton(
                    label: l10n.spDeleteRecurring,
                    style: ClButtonStyle.plain,
                    expand: true,
                    onPressed: _delete,
                  ),
                ],
                const SizedBox(height: ClSpace.s3),
              ],
            ),
          ),
        ),
        ClButton(
          key: const Key('spSaveRecurring'),
          label: l10n.actionSave,
          expand: true,
          onPressed: _save,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpRoundIcon(
          icon: ClIcons.back,
          label: l10n.spLess,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: ClSpace.s2),
        SpRoundIcon(
          icon: ClIcons.plus,
          label: l10n.spMore,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

/// One or two days of the month.
class _DaysSheet extends StatefulWidget {
  const _DaysSheet({required this.initial, required this.title});
  final List<int> initial;
  final String title;

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  late final _days = [...widget.initial];

  void _tap(int d) => setState(() {
    if (_days.contains(d)) {
      if (_days.length > 1) _days.remove(d);
    } else {
      if (_days.length == 2) _days.removeAt(0);
      _days.add(d);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: widget.title),
        Text(
          l10n.spScheduleDaysHelp,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var d = 1; d <= 31; d++)
              ClPressable(
                onPressed: () => _tap(d),
                semanticLabel: '$d',
                selected: _days.contains(d),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _days.contains(d)
                        ? cl.colors.mintDeep
                        : cl.colors.surface2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$d',
                    style: cl.text.label.copyWith(
                      color: _days.contains(d)
                          ? cl.colors.onMintDeep
                          : cl.colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.actionSave,
          expand: true,
          onPressed: () => Navigator.of(context).pop([..._days]..sort()),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}
