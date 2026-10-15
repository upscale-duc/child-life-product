import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../spending/spending_currency.dart';
import '../spending/spending_format.dart';
import '../spending/spending_sheets.dart' show SpAmountInput, pickSpCurrency;
import 'assistant_widgets.dart' show AsChip;
import 'lumi_button.dart' show LumiMascot;

/// What the person typed in "Hết bao nhiêu tiền?": minor units and their currency.
typedef AsTypedAmount = ({int minor, String currency});

/// LUMI-16 (owner 2026-10-16): "mua hai hộp sữa", "vừa mua bỉm ở Con Cưng", "đặt tã online" make
/// an expense draft without an amount. Lumi asks for it on the card — "Hết bao nhiêu tiền?" —
/// with the amount field (Chi tiêu's own: grouping as typed, the household currency, its picker)
/// and, for a currency without cents, chips that complete the thousands the way people say it
/// ("35" → 35.000 / 350.000 / 3.500.000). [builder] gets the block and the amount typed so far
/// (null while empty), so the card's "Lưu chi tiêu" enables as soon as there is one.
class AsAmountAsk extends StatefulWidget {
  const AsAmountAsk({required this.currency, required this.builder, super.key});

  /// The draft's currency: the household's (`spendingSettings`), set by the server.
  final String currency;
  final Widget Function(BuildContext context, Widget ask, AsTypedAmount? typed)
  builder;

  @override
  State<AsAmountAsk> createState() => _AsAmountAskState();
}

class _AsAmountAskState extends State<AsAmountAsk> {
  final _amount = TextEditingController();
  late String _currency = isSpCurrency(widget.currency)
      ? widget.currency
      : legacyCurrency;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  AsTypedAmount? _typed(String locale) {
    final v = parseMoney(_amount.text, _currency, locale);
    if (v == null || v <= 0 || v > spCurrency(_currency).max) return null;
    return (minor: v, currency: _currency);
  }

  /// "35" typed → 35.000 · 350.000 · 3.500.000 (VND, JPY, KRW only; never past the maximum).
  List<int> _thousands(String locale) {
    final c = spCurrency(_currency);
    if (c.exponent != 0) return const [];
    final v = parseMoney(_amount.text, _currency, locale);
    if (v == null || v <= 0 || v >= 1000) return const [];
    return [
      for (final m in const [1000, 10000, 100000])
        if (v * m <= c.max) v * m,
    ];
  }

  void _set(String locale, int minor) {
    final text = moneyPlain(locale, minor, _currency);
    _amount.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final locale = spLocale(context);
    final chips = _thousands(locale);
    final ask = Column(
      key: const ValueKey('as.amountAsk'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const LumiMascot(size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.asAskAmount,
                style: cl.text.bodyStrong.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: c.cloud,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.controlBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.spAmount,
                style: cl.text.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: SpAmountInput(
                  controller: _amount,
                  large: false,
                  currency: _currency,
                  onCurrency: _pickCurrency,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s2),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final (i, v) in chips.indexed)
                AsChip(
                  key: ValueKey('as.amountAsk.$i'),
                  label: moneyPlain(locale, v, _currency),
                  onPressed: () => _set(locale, v),
                ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s2),
      ],
    );
    return widget.builder(context, ask, _typed(locale));
  }
}
