import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../baby/baby_models.dart';
import '../family/family_repository.dart';
import '../vaccines/vaccine_photos.dart';
import '../vaccines/vaccine_sheets.dart' show pickVxDate;
import 'spending_calc.dart';
import 'spending_categories.dart';
import 'spending_currency.dart';
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_repository.dart';
import 'spending_widgets.dart';

/// "1020000" typed → "1.020.000" shown (the locale's grouping), caret at the end. A currency
/// with cents (D-075 #4) keeps the decimal mark and up to its digits as typed ("12,5" → "12,5").
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter(this.locale, [this.currency = legacyCurrency]);
  final String locale;
  final String currency;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final c = spCurrency(currency);
    final amount = parseMoney(newValue.text, currency, locale);
    if (amount == null) return TextEditingValue.empty;
    var text = moneyPlain(locale, amount > c.max ? c.max : amount, currency);
    if (c.exponent > 0 && amount <= c.max) {
      // Keep what is being typed after the mark: "12," and "12,5" stay as they are.
      final split = splitMoney(newValue.text, c.exponent, locale);
      final whole = NumberFormat(
        '#,##0',
        locale,
      ).format(int.tryParse(split.whole.isEmpty ? '0' : split.whole) ?? 0);
      final frac = split.frac;
      text = frac == null
          ? whole
          : '$whole${NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP}'
                '${frac.length > c.exponent ? frac.substring(0, c.exponent) : frac}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// The currency picker (D-075 #4): every currency Chi tiêu keeps, [current] ticked.
Future<String?> pickSpCurrency(BuildContext context, String current) =>
    showClSheet<String>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.spCurrencyTitle),
            Flexible(
              child: SingleChildScrollView(
                child: ClCardGroup(
                  children: [
                    for (final c in spCurrencies)
                      ClOptionRow(
                        key: Key('spCur-${c.code}'),
                        title: '${c.code} · ${c.symbol}',
                        subtitle: currencyName(l10n, c.code),
                        selected: c.code == current,
                        onTap: () => Navigator.of(sheet).pop(c.code),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s4),
          ],
        );
      },
    );

/// The large centred amount ("Số tiền", 8c / 8k / 8h).
class SpAmountInput extends StatelessWidget {
  const SpAmountInput({
    required this.controller,
    this.autofocus = false,
    this.large = true,
    this.onChanged,
    this.currency = legacyCurrency,
    this.onCurrency,
    super.key,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool large;
  final ValueChanged<String>? onChanged;

  /// D-075 #4: what the amount is in; [onCurrency] makes its sign a picker.
  final String currency;
  final VoidCallback? onCurrency;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final style = (large ? cl.text.numeralXl : cl.text.title).copyWith(
      fontSize: large ? 36 : null,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        IntrinsicWidth(
          child: TextField(
            key: const Key('spAmount'),
            controller: controller,
            autofocus: autofocus,
            keyboardType: spCurrency(currency).exponent > 0
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [MoneyInputFormatter(spLocale(context), currency)],
            onChanged: onChanged,
            style: style,
            cursorColor: cl.colors.mintDeep,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: '0',
              hintStyle: style.copyWith(color: cl.colors.inkMuted),
              semanticCounterText: '',
            ),
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
          ),
        ),
        const SizedBox(width: 6),
        if (onCurrency == null)
          Text(
            spCurrency(currency).symbol,
            semanticsLabel: currency == legacyCurrency
                ? l10n.spCurrencyName
                : currencyName(l10n, currency),
            style: style.copyWith(color: cl.colors.inkMuted),
          )
        else
          ClPressable(
            key: const Key('spCurrency'),
            onPressed: onCurrency,
            semanticLabel: l10n.spCurrencyPick(currency),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spCurrency(currency).symbol,
                    style: style.copyWith(
                      color: cl.colors.ink,
                      fontSize: large ? 22 : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ClIcon(
                    ClIcons.chevronDown,
                    size: 14,
                    color: cl.colors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Ai trả" (D-056): the baby's members by their label, then "Khác".
class PayerPicker extends ConsumerWidget {
  const PayerPicker({
    required this.babyId,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String babyId;
  final Payer? value;
  final ValueChanged<Payer?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members =
        ref.watch(familyMembersProvider(babyId)).value ?? const <Membership>[];
    final known = members.map((m) => m.uid).toSet();
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final m in members)
          SpChoiceChip(
            label: payerLabel(l10n, Payer.of(m)),
            selected: value?.uid == m.uid,
            onTap: () => onChanged(Payer.of(m)),
          ),
        // A departed member keeps their snapshot on old items.
        if (value != null && !known.contains(value!.uid))
          SpChoiceChip(
            label: payerLabel(l10n, value),
            selected: true,
            onTap: () {},
          ),
        SpChoiceChip(
          label: l10n.spPayerOther,
          selected: value == null,
          onTap: () => onChanged(null),
        ),
      ],
    );
  }
}

/// Category chips (8c): the visible ones, plus "+ Danh mục" for Cùng nuôi.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.scope,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final SpendingScope scope;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = [
      ...scope.visible,
      // An item kept in a category hidden since keeps showing it.
      if (scope.visible.every((c) => c.id != value)) scope.category(value),
    ];
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final c in shown)
          SpChoiceChip(
            key: Key('spCat-${c.id}'),
            label: categoryName(l10n, c),
            icon: c.icon,
            tint: c.tint,
            selected: c.id == value,
            onTap: () => onChanged(c.id),
          ),
        if (scope.access.parent)
          SpChoiceChip(
            label: l10n.spAddCategoryChip,
            icon: ClIcons.plus,
            dashed: true,
            selected: false,
            onTap: () async {
              final id = await openCategoryEditor(context, scope: scope);
              if (id != null) onChanged(id);
            },
          ),
      ],
    );
  }
}

/// Receipt photo row: add, or show it with remove.
class ReceiptField extends ConsumerStatefulWidget {
  const ReceiptField({
    required this.babyId,
    required this.value,
    required this.onChanged,
    required this.onBusy,
    super.key,
  });

  final String babyId;
  final String? value;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool> onBusy;

  @override
  ConsumerState<ReceiptField> createState() => _ReceiptFieldState();
}

class _ReceiptFieldState extends ConsumerState<ReceiptField> {
  bool _busy = false;

  Future<void> _add() async {
    final path = await addVxPhoto(
      context,
      ref,
      widget.babyId,
      receipt: true,
      onBusy: (busy) {
        if (!mounted) return;
        setState(() => _busy = busy);
        widget.onBusy(busy);
      },
    );
    if (path != null && mounted) widget.onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final path = widget.value;
    return SpActionRow(
      icon: ClIcons.camera,
      label: l10n.spReceipt,
      value: path == null ? null : l10n.spReceiptAttached,
      onTap: _busy
          ? null
          : path == null
          ? () => unawaited(_add())
          : () => showVxPhotoViewer(context, [path]),
      trailing: _busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cl.colors.mintDeep,
              ),
            )
          : path == null
          ? ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText)
          : ClPressable(
              onPressed: () => widget.onChanged(null),
              semanticLabel: l10n.spReceiptRemove,
              child: Padding(
                padding: const EdgeInsets.all(ClSpace.s1),
                child: ClIcon(
                  ClIcons.close,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
    );
  }
}

String spDateLabel(AppLocalizations l10n, DateTime day, DateTime today) {
  final dm = DateFormat('dd/MM').format(day);
  final diff = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (diff == 0) return l10n.spDateToday(dm);
  if (diff == 1) return l10n.spDateYesterday(dm);
  return DateFormat('dd/MM/yyyy').format(day);
}

// ---------- 8c Thêm khoản chi / Sửa khoản chi ----------

Future<void> showExpenseSheet(
  BuildContext context, {
  required SpendingScope scope,
  Expense? expense,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _ExpenseSheet(scope: scope, expense: expense),
);

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet({required this.scope, this.expense});
  final SpendingScope scope;
  final Expense? expense;

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  SpendingScope get _scope => widget.scope;
  Expense? get _editing => widget.expense;

  late final _amount = TextEditingController();
  late final _note = TextEditingController(text: _editing?.note);
  late String _category =
      _editing?.categoryId ?? _scope.visible.firstOrNull?.id ?? otherCategoryId;
  late Payer? _payer = _editing == null ? Payer.of(_scope.me) : _editing!.payer;
  late DateTime _day = _editing?.spentOn ?? _scope.today;
  late String? _receipt = _editing?.receiptPath;

  /// D-075 #4: the household's by default; any expense may use another.
  late String _currency = _editing?.currency ?? _scope.currency;
  bool _repeat = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editing != null && _amount.text.isEmpty) {
      _amount.text = moneyPlain(
        spLocale(context),
        _editing!.amount,
        _editing!.currency,
      );
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _value => parseMoney(_amount.text, _currency, spLocale(context));

  void _setAmount(int v) {
    final capped = v.clamp(0, amountMaxFor(_currency));
    setState(
      () => _amount.text = moneyPlain(spLocale(context), capped, _currency),
    );
  }

  /// Another currency: the typed number stays, read in the new currency's units.
  Future<void> _pickCurrency() async {
    final locale = spLocale(context);
    final picked = await pickSpCurrency(context, _currency);
    if (picked == null || picked == _currency || !mounted) return;
    final typed = parseMoney(_amount.text, _currency, locale);
    setState(() {
      final from = spCurrency(_currency), to = spCurrency(picked);
      _currency = picked;
      if (typed == null) return;
      // Same number of whole units ("12" stays "12"), within the new ceiling.
      final whole = typed ~/ from.unit;
      _amount.text = moneyPlain(
        locale,
        (whole * to.unit).clamp(0, to.max),
        picked,
      );
    });
  }

  void _dropReceipt() {
    final path = _receipt;
    setState(() => _receipt = null);
    // Uploaded in this form and dropped before saving: not kept.
    if (path != null && path != _editing?.receiptPath) {
      unawaited(ref.read(vaccinePhotoStoreProvider).remove(path));
    }
  }

  void _save() {
    final amount = _value;
    final l10n = AppLocalizations.of(context);
    if (amount == null || amount <= 0) {
      showClToast(context, message: l10n.spAmountMissing);
      return;
    }
    final toaster = ClToaster.of(context);
    final repo = ref.read(spendingRepositoryProvider);
    void failed(Object _) => toaster.show(message: l10n.spSaveFailed);
    repo.saveExpense(
      babyId: _scope.babyId,
      me: _scope.me,
      id: _editing?.id,
      amount: amount,
      currency: _currency,
      categoryId: _category,
      note: _note.text,
      spentOn: _day,
      payer: _payer,
      receiptPath: _receipt,
      onError: failed,
    );
    if (_repeat && _editing == null) {
      repo.saveRecurring(
        babyId: _scope.babyId,
        me: _scope.me,
        title: _note.text.trim().isEmpty
            ? categoryName(l10n, _scope.category(_category))
            : _note.text,
        categoryId: _category,
        amount: amount,
        currency: _currency,
        payer: _payer,
        schedule: Monthly([_day.day]),
        enabled: true,
        recordedOn: _day,
        onError: failed,
      );
    }
    Navigator.of(context).pop();
    toaster.show(message: _editing == null ? l10n.spSaved : l10n.spUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final last = lastAmount(_scope.expenses, _category, currency: _currency);
    final value = _value ?? 0;
    // "+100.000" / "+500.000" for VND; "+10" / "+50" whole units elsewhere.
    final unit = spCurrency(_currency).unit;
    final steps = _currency == legacyCurrency
        ? const [100000, 500000]
        : [10 * unit, 50 * unit];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: _editing == null ? l10n.spAddTitle : l10n.spEditTitle,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.spAmount,
                  textAlign: TextAlign.center,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s1),
                SpAmountInput(
                  controller: _amount,
                  autofocus: _editing == null,
                  onChanged: (_) => setState(() {}),
                  currency: _currency,
                  onCurrency: () => unawaited(_pickCurrency()),
                ),
                const SizedBox(height: ClSpace.s3),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s2,
                  children: [
                    if (last != null)
                      _Suggestion(
                        label: l10n.spLastTime(
                          moneyPlain(locale, last, _currency),
                        ),
                        onTap: () => _setAmount(last),
                      ),
                    for (final step in steps)
                      _Suggestion(
                        label: _currency == legacyCurrency
                            ? '+${moneyPlain(locale, step)}'
                            : '+${step ~/ unit}',
                        onTap: () => _setAmount(value + step),
                      ),
                  ],
                ),
                SpLabel(
                  l10n.spCategory,
                  trailing: _scope.access.parent
                      ? ClPressable(
                          onPressed: () => openCategories(context),
                          semanticLabel: l10n.spEditCategories,
                          child: Text(
                            l10n.spEditCategories,
                            style: cl.text.label.copyWith(
                              color: cl.colors.mintText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
                Consumer(
                  builder: (context, ref, _) {
                    // Categories added from here show at once.
                    final cats = ref
                        .watch(spendingCategoriesProvider(_scope.familyId))
                        .value;
                    final scope = cats == null
                        ? _scope
                        : SpendingScope(
                            me: _scope.me,
                            baby: _scope.baby,
                            access: _scope.access,
                            today: _scope.today,
                            expenses: _scope.expenses,
                            categories: cats,
                            loading: false,
                            currency: _scope.currency,
                          );
                    return CategoryPicker(
                      scope: scope,
                      value: _category,
                      onChanged: (id) => setState(() => _category = id),
                    );
                  },
                ),
                SpLabel(l10n.spNote),
                ClTextField(
                  controller: _note,
                  placeholder: l10n.spNoteHint,
                  standalone: true,
                  maxLength: SpendingLimits.noteMax,
                  textCapitalization: TextCapitalization.sentences,
                ),
                SpLabel(l10n.spPayer),
                PayerPicker(
                  babyId: _scope.babyId,
                  value: _payer,
                  onChanged: (p) => setState(() => _payer = p),
                ),
                const SizedBox(height: ClSpace.s4),
                ClCardGroupLike(
                  children: [
                    SpActionRow(
                      icon: ClIcons.today,
                      label: spDateLabel(l10n, _day, _scope.today),
                      onTap: () async {
                        final d = await pickVxDate(
                          context,
                          initial: _day,
                          first: DateTime(_scope.today.year - 6),
                          last: _scope.today,
                        );
                        if (d != null && mounted) setState(() => _day = d);
                      },
                    ),
                    ReceiptField(
                      babyId: _scope.babyId,
                      value: _receipt,
                      onChanged: (p) {
                        if (p == null) {
                          _dropReceipt();
                        } else {
                          setState(() => _receipt = p);
                        }
                      },
                      onBusy: (b) => setState(() => _busy = b),
                    ),
                    if (_editing == null && _scope.access.parent)
                      SpActionRow(
                        icon: ClIcons.retry,
                        label: l10n.spRepeatMonthly,
                        value: _repeat
                            ? l10n.spRepeatMonthlyOn(_day.day)
                            : null,
                        trailing: ClToggle(
                          value: _repeat,
                          semanticLabel: l10n.spRepeatMonthly,
                          onChanged: (v) => setState(() => _repeat = v),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
              ],
            ),
          ),
        ),
        ClButton(
          key: const Key('spSave'),
          label: l10n.spSave,
          expand: true,
          onPressed: _busy ? null : _save,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: cl.text.caption.copyWith(
              color: cl.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A surface-2 group inside a sheet (rows separated by hairlines).
class ClCardGroupLike extends StatelessWidget {
  const ClCardGroupLike({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cl.colors.surface,
        border: Border.all(color: cl.colors.separator),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: cl.colors.separator),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ---------- 8k Ghi chi phí mũi tiêm ----------

/// After a dose is recorded as given: offer to save its cost in Y tế & tiêm chủng. Skipped when
/// the caller may not record spending or the dose already has a cost.
///
/// [context] outlives the dose sheet (its navigator's), so it is read through the container.
Future<void> offerVaccineCost(
  BuildContext context, {
  required Membership me,
  required String doseKey,
  required String doseTitle,
  required DateTime givenOn,
}) async {
  final access = SpendingAccess.of(me);
  if (!access.record) return;
  final container = ProviderScope.containerOf(context, listen: false);
  final provider = expensesProvider((me.babyId, access));
  // Riverpod pauses a provider nobody listens to: hold it while reading.
  final hold = container.listen(provider, (_, _) {});
  final List<Expense> mine;
  try {
    mine = await container
        .read(provider.future)
        .timeout(const Duration(seconds: 3));
  } on Object {
    return;
  } finally {
    hold.close();
  }
  if (mine.any(
    (e) => e.source == ExpenseSource.vaccine && e.sourceRef == doseKey,
  )) {
    return;
  }
  final currency = await householdCurrencyOf(container, me);
  if (!context.mounted) return;
  await showClSheet<void>(
    context: context,
    builder: (_) => _VaccineCostSheet(
      me: me,
      doseKey: doseKey,
      doseTitle: doseTitle,
      givenOn: givenOn,
      suggested: lastVaccineCost(mine, doseKey),
      currency: currency,
    ),
  );
}

class _VaccineCostSheet extends ConsumerStatefulWidget {
  const _VaccineCostSheet({
    required this.me,
    required this.doseKey,
    required this.doseTitle,
    required this.givenOn,
    required this.suggested,
    required this.currency,
  });

  final Membership me;
  final String doseKey;
  final String doseTitle;
  final DateTime givenOn;

  /// The last cost of the same vaccine, in its own currency (D-075 #4).
  final ({int amount, String currency})? suggested;

  /// The household's currency (used when nothing was paid before).
  final String currency;

  @override
  ConsumerState<_VaccineCostSheet> createState() => _VaccineCostSheetState();
}

class _VaccineCostSheetState extends ConsumerState<_VaccineCostSheet> {
  final _amount = TextEditingController();
  late Payer? _payer = Payer.of(widget.me);
  String? _receipt;
  bool _busy = false;
  bool _saved = false;
  late String _currency = widget.suggested?.currency ?? widget.currency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = widget.suggested;
    if (s != null && _amount.text.isEmpty) {
      _amount.text = moneyPlain(spLocale(context), s.amount, s.currency);
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
    // Skipped after adding a receipt: the upload is not kept.
    if (!_saved && _receipt != null) {
      unawaited(ref.read(vaccinePhotoStoreProvider).remove(_receipt!));
    }
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final amount = parseMoney(_amount.text, _currency, spLocale(context));
    if (amount == null || amount <= 0) {
      showClToast(context, message: l10n.spAmountMissing);
      return;
    }
    final toaster = ClToaster.of(context);
    ref
        .read(spendingRepositoryProvider)
        .saveExpense(
          babyId: widget.me.babyId,
          me: widget.me,
          amount: amount,
          currency: _currency,
          categoryId: healthCategoryId,
          note: widget.doseTitle.length > SpendingLimits.noteMax
              ? widget.doseTitle.substring(0, SpendingLimits.noteMax)
              : widget.doseTitle,
          spentOn: widget.givenOn,
          payer: _payer,
          receiptPath: _receipt,
          doseKey: widget.doseKey,
          onError: (_) => toaster.show(message: l10n.spSaveFailed),
        );
    _saved = true;
    Navigator.of(context).pop();
    toaster.show(message: l10n.spVaccineSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.spVaccineTitle),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.spVaccineBody,
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
                SpLabel(l10n.spAmount),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    border: Border.all(color: cl.colors.controlBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SpAmountInput(
                    controller: _amount,
                    large: false,
                    autofocus: widget.suggested == null,
                    currency: _currency,
                    onCurrency: () => unawaited(_pickCurrency()),
                  ),
                ),
                SpLabel(l10n.spPayer),
                PayerPicker(
                  babyId: widget.me.babyId,
                  value: _payer,
                  onChanged: (p) => setState(() => _payer = p),
                ),
                const SizedBox(height: ClSpace.s4),
                ClCardGroupLike(
                  children: [
                    ReceiptField(
                      babyId: widget.me.babyId,
                      value: _receipt,
                      onChanged: (p) {
                        final old = _receipt;
                        setState(() => _receipt = p);
                        if (p == null && old != null) {
                          unawaited(
                            ref.read(vaccinePhotoStoreProvider).remove(old),
                          );
                        }
                      },
                      onBusy: (b) => setState(() => _busy = b),
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
              ],
            ),
          ),
        ),
        ClButton(
          key: const Key('spVaccineSave'),
          label: l10n.spVaccineSave,
          expand: true,
          onPressed: _busy ? null : _save,
        ),
        const SizedBox(height: ClSpace.s1),
        ClButton(
          label: l10n.spSkip,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
