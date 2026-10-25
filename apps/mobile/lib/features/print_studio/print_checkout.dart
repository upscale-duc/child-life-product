import 'package:flutter/material.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memory_models.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_widgets.dart';

/// PS30N 1006:13863. All order decisions live on this ONE page.
class PrintCheckout extends StatelessWidget {
  const PrintCheckout({
    required this.design,
    required this.media,
    required this.catalog,
    required this.quantity,
    required this.approved,
    required this.address,
    required this.gift,
    required this.payment,
    required this.onQuantity,
    required this.onApproved,
    required this.onGift,
    required this.onGiftMessage,
    required this.giftController,
    required this.onPayment,
    required this.onAddress,
    required this.onProof,
    required this.onPolicy,
    this.busy = false,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final PrintCatalog catalog;
  final int quantity;
  final bool approved, gift, busy;
  final Map<String, dynamic> address;
  final String payment;
  final TextEditingController giftController;
  final ValueChanged<String> onGiftMessage;
  final ValueChanged<int> onQuantity;
  final ValueChanged<bool> onApproved, onGift;
  final ValueChanged<String> onPayment;
  final VoidCallback onAddress, onProof, onPolicy;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl, d = design;
    final totals = catalog.totals(d, quantity, giftWrap: gift);
    Widget section(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(text, style: psText(context, 17, weight: FontWeight.w700)),
    );
    Widget paymentRow(String value, String title, String help) => InkWell(
      onTap: busy ? null : () => onPayment(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            PrintRadio(payment == value),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: psText(context, 15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    help,
                    style: psText(
                      context,
                      12,
                      color: cl.colors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrintCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cl.colors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 65,
                      height: 90,
                      child: PrintArtwork(design: d, media: media),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${printProductName(l, d.product)} · ${d.title}',
                          style: psText(context, 15, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.size.replaceAll('x', '×')} · ${d.frame == 'white' ? l.psMaterialShortWhite : l.psMaterialShortWood} · ${printStyleName(l, d.style)}',
                          style: psText(context, 12, color: cl.colors.inkMuted),
                        ),
                        Text(
                          printMoney(
                            context,
                            (catalog.price(d) ?? 0) * quantity,
                          ),
                          style: psText(
                            context,
                            14,
                            weight: FontWeight.w700,
                            color: cl.colors.mintText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: cl.colors.surface2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QtyButton(
                          '−',
                          onTap: busy || quantity <= 1
                              ? null
                              : () => onQuantity(quantity - 1),
                        ),
                        Text(
                          '$quantity',
                          style: psText(context, 14, weight: FontWeight.w700),
                        ),
                        _QtyButton(
                          '+',
                          onTap: busy || quantity >= 10
                              ? null
                              : () => onQuantity(quantity + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 65,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: d.isBook ? 2 : d.count,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, p) => SizedBox(
                          width: d.isBook ? 65 : 47,
                          child: PrintArtwork(design: d, media: media, page: p),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : onProof,
                    child: Text(
                      l.psReviewPrint,
                      style: psText(
                        context,
                        13,
                        weight: FontWeight.w600,
                        color: cl.colors.mintText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: busy ? null : () => onApproved(!approved),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: approved,
                          onChanged: busy
                              ? null
                              : (v) => onApproved(v ?? false),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          activeColor: cl.colors.mintDeep,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.psCheckoutProof,
                          style: psText(context, 13, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        section(l.psDeliverTo),
        PrintCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: busy ? null : onAddress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address['recipient']?.toString().isNotEmpty == true
                          ? '${address['recipient']} · ${address['phone']}'
                          : l.psAddAddress,
                      style: psText(context, 14, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.psEdit,
                    style: psText(
                      context,
                      13,
                      color: cl.colors.mintText,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (address['address']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  address['address'] as String,
                  style: psText(context, 13, color: cl.colors.inkMuted),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.psDeliveryEstimate('${catalog.leadDays}'),
                        style: psText(context, 12, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        section(l.psPayment),
        PrintCard(
          lifted: false,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              paymentRow('cod', l.psCod, l.psCodHelp),
              paymentRow('bankTransfer', l.psTransfer, l.psTransferHelp),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrintCard(
          lifted: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.psWrap,
                      style: psText(context, 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${printMoney(context, catalog.giftWrapFee)}',
                      style: psText(context, 12, color: cl.colors.inkMuted),
                    ),
                  ],
                ),
              ),
              PrintToggle(value: gift, onChanged: busy ? null : onGift),
            ],
          ),
        ),
        if (gift)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: giftController,
              onChanged: onGiftMessage,
              maxLength: 200,
              maxLines: 2,
              style: psText(context, 13),
              decoration: InputDecoration(labelText: l.psGiftNote),
            ),
          ),
        const SizedBox(height: 14),
        PrintCard(
          child: Column(
            children: [
              for (final row in [
                (l.psSubtotal, totals.subtotal),
                (l.psShippingFee, totals.shipping),
                (l.psTotal, totals.total),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.$1,
                          style: psText(
                            context,
                            row.$1 == l.psTotal ? 15 : 13,
                            weight: row.$1 == l.psTotal
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: row.$1 == l.psTotal
                                ? cl.colors.ink
                                : cl.colors.inkMuted,
                          ),
                        ),
                      ),
                      Text(
                        printMoney(context, row.$2),
                        style: psText(
                          context,
                          row.$1 == l.psTotal ? 17 : 13,
                          weight: row.$1 == l.psTotal
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onPolicy,
          child: Text(
            l.psCheckoutPolicy,
            style: psText(context, 12, color: cl.colors.inkMuted, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton(this.text, {this.onTap});
  final String text;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 30,
      height: 34,
      child: Center(
        child: Text(
          text,
          style: psText(
            context,
            14,
            weight: FontWeight.w700,
            color: onTap == null
                ? context.cl.colors.inkMuted
                : context.cl.colors.ink,
          ),
        ),
      ),
    ),
  );
}

class PrintOrderSuccess extends StatelessWidget {
  const PrintOrderSuccess({
    required this.id,
    required this.name,
    required this.total,
    required this.days,
    required this.onView,
    required this.onMemories,
    super.key,
  });
  final String id, name;
  final int total, days;
  final VoidCallback onView, onMemories;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 114, 16, 40),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: ClIcon(ClIcons.check, size: 32, color: cl.colors.mintDeep),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.psOrderSuccess,
          textAlign: TextAlign.center,
          style: psText(context, 24, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          l.psOrderCode(id),
          style: psText(
            context,
            14,
            weight: FontWeight.w600,
            color: cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: 14),
        PrintNotice(l.psOrderSuccessHelp(name)),
        const SizedBox(height: 14),
        PrintCard(
          child: Column(
            children: [
              for (final row in [
                (l.psOrderAccepted, id),
                (l.psProduction, l.psPendingShort),
                (l.psDelivery, l.psExpectedDays('$days')),
                (l.psPayOnReceipt, printMoney(context, total)),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cl.colors.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${[l.psOrderAccepted, l.psProduction, l.psDelivery, l.psPayOnReceipt].indexOf(row.$1) + 1}',
                          style: psText(context, 12, weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          row.$1,
                          style: psText(context, 14, weight: FontWeight.w600),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          row.$2,
                          textAlign: TextAlign.right,
                          style: psText(context, 13, color: cl.colors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClButton(label: l.psViewOrder, expand: true, onPressed: onView),
        const SizedBox(height: 14),
        ClButton(
          label: l.psBackMemories,
          expand: true,
          style: ClButtonStyle.secondary,
          onPressed: onMemories,
        ),
      ],
    );
  }
}
