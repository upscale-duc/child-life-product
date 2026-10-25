import 'package:flutter/material.dart';

import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'premium_style.dart';
import 'premium_v2.dart';

/// Who is reading the paywall and what its footer can do.
enum PaywallFooter {
  /// The manager, with in-app purchase open: period tiles and the gold CTA.
  buy,

  /// The manager while in-app purchase is not open yet (owner: IAP comes later).
  soon,

  /// A member who does not manage the plan (PW07): ask the manager.
  member,

  /// The family already has Premium.
  premium,
}

/// PW01–PW08 (Figma 1021:17681…): headline and reason by entry, the six-card carousel opened at
/// the entry's card, Free vs Premium with "Bạn đang cần" on the entry's row, the promises and
/// the footer. The reason line shows only from an entry point (Note · PW01); opened on purpose
/// (PW06) it has none and no tag. Numbers come from the plan config (`getFamilyPlan`).
class PaywallV2View extends StatefulWidget {
  const PaywallV2View({
    required this.entry,
    required this.footer,
    required this.babyName,
    required this.onClose,
    this.plan,
    this.reason,
    this.vnd = true,
    this.storeName,
    this.managerName,
    this.busy = false,
    this.onBuy,
    this.onRestore,
    this.onAskManager,
    this.onOpenPlan,
    super.key,
  });

  final PremiumEntry entry;
  final PaywallFooter footer;
  final String babyName;
  final FamilyPlanV2? plan;

  /// What is waiting (the entry's work), shown under the headline; null when opened on purpose.
  final String? reason;
  final bool vnd;
  final String? storeName;
  final String? managerName;
  final bool busy;
  final VoidCallback onClose;

  /// Yearly (true) or monthly; only with [PaywallFooter.buy].
  final void Function(bool yearly)? onBuy;
  final VoidCallback? onRestore;
  final VoidCallback? onAskManager;
  final VoidCallback? onOpenPlan;

  @override
  State<PaywallV2View> createState() => _PaywallV2State();
}

class _PaywallV2State extends State<PaywallV2View> {
  var _yearly = true;
  late final PageController _pages = PageController(
    viewportFraction: 0.78,
    initialPage: widget.entry.firstCard.index,
  );
  late int _page = widget.entry.firstCard.index;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _headline(AppLocalizations l10n) => switch (widget.entry) {
    PremiumEntry.video => l10n.pv2HeadVideo(widget.babyName),
    PremiumEntry.card => l10n.pv2HeadCard(widget.babyName),
    PremiumEntry.lumi => l10n.pv2HeadLumi(widget.babyName),
    PremiumEntry.storage => l10n.pv2HeadStorage,
    PremiumEntry.caregivers => l10n.pv2HeadCaregivers(widget.babyName),
    PremiumEntry.explore => l10n.pv2HeadExplore,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = widget.plan;
    final free = plan?.free ?? PlanOffer.free;
    final premium = plan?.premiumOffer ?? PlanOffer.premium;
    final price = plan?.priceVn != null && widget.vnd
        ? plan!.priceVn
        : (plan?.priceIntl ?? const PlanPrice(month: 5.99, year: 49.99));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final explore = widget.entry == PremiumEntry.explore;

    return Scaffold(
      backgroundColor: PremiumPalette.deep,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PremiumPalette.deepTop, PremiumPalette.deep],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
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
                      child: Row(
                        children: [
                          _CloseButton(
                            label: l10n.a11yClose,
                            onTap: widget.onClose,
                          ),
                          const Spacer(),
                          if (widget.onRestore case final r?)
                            ClPressable(
                              onPressed: widget.busy ? null : r,
                              semanticLabel: l10n.pv2Restore,
                              child: Padding(
                                padding: const EdgeInsets.all(ClSpace.s2),
                                child: Text(
                                  l10n.pv2Restore,
                                  style: const TextStyle(
                                    color: PremiumPalette.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: ClSpace.s6),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              ClSpace.s6,
                              ClSpace.s3,
                              ClSpace.s6,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PremiumCrest(),
                                const SizedBox(height: ClSpace.s2),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    _headline(l10n),
                                    style: const TextStyle(
                                      fontFamily: PremiumPalette.serif,
                                      color: PremiumPalette.text,
                                      fontSize: 25,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (widget.reason case final r?
                                    when !explore) ...[
                                  const SizedBox(height: ClSpace.s2),
                                  Text(
                                    r,
                                    style: const TextStyle(
                                      color: PremiumPalette.textMuted,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: ClSpace.s4),
                          SizedBox(
                            height: 318,
                            child: PageView.builder(
                              controller: _pages,
                              itemCount: PremiumCard.values.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, i) => AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: (i - _page).abs() <= 1
                                    ? (i == _page ? 1 : 0.4)
                                    : 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ClSpace.s2,
                                  ),
                                  child: PremiumFeatureCard(
                                    card: PremiumCard.values[i],
                                    free: free,
                                    premium: premium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: ClSpace.s3),
                          _Dots(
                            count: PremiumCard.values.length,
                            active: _page,
                          ),
                          const SizedBox(height: ClSpace.s6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ClSpace.s4,
                            ),
                            child: _Compare(
                              free: free,
                              premium: premium,
                              need: explore ? null : widget.entry,
                            ),
                          ),
                          const SizedBox(height: ClSpace.s4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ClSpace.s4,
                            ),
                            child: Wrap(
                              spacing: ClSpace.s2,
                              runSpacing: ClSpace.s2,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final p in [
                                  l10n.pv2PromiseCancel,
                                  l10n.pv2PromiseNoTopUps,
                                  l10n.pv2PromiseYours,
                                ])
                                  _Promise(label: p),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              kind: widget.footer,
              yearly: _yearly,
              price: price,
              vnd: widget.vnd,
              storeName: widget.storeName,
              managerName: widget.managerName ?? l10n.pv2TheManager,
              busy: widget.busy,
              bottom: bottom,
              onPeriod: (y) => setState(() => _yearly = y),
              onBuy: widget.onBuy == null ? null : () => widget.onBuy!(_yearly),
              onAskManager: widget.onAskManager,
              onOpenPlan: widget.onOpenPlan,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onTap,
    semanticLabel: label,
    child: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: PremiumPalette.fill,
        shape: BoxShape.circle,
      ),
      child: const ClIcon(ClIcons.close, size: 20, color: PremiumPalette.text),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? PremiumPalette.gold : PremiumPalette.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    ),
  );
}

class _Promise extends StatelessWidget {
  const _Promise({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 6),
    decoration: BoxDecoration(
      color: PremiumPalette.fill,
      borderRadius: BorderRadius.circular(ClRadius.pill),
      border: Border.all(color: PremiumPalette.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ClIcon(ClIcons.check, size: 14, color: PremiumPalette.gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: PremiumPalette.textMuted, fontSize: 12),
        ),
      ],
    ),
  );
}

/// Component · Premium · Thẻ tính năng (1019:17008): a demo panel, then eyebrow, title,
/// benefit and the limit line in gold.
class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    required this.card,
    required this.free,
    required this.premium,
    super.key,
  });

  final PremiumCard card;
  final PlanOffer free;
  final PlanOffer premium;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gb = premiumGb(context, premium.storageBytes).replaceAll(' GB', '');
    final (eyebrow, title, body, limit) = switch (card) {
      PremiumCard.video => (
        l10n.pv2CardVideoEyebrow,
        l10n.pv2CardVideoTitle,
        l10n.pv2CardVideoBody,
        l10n.pv2CardVideoLimit(premium.videoExports),
      ),
      PremiumCard.card => (
        l10n.pv2CardCardEyebrow,
        l10n.pv2CardCardTitle,
        l10n.pv2CardCardBody,
        l10n.pv2CardCardLimit,
      ),
      PremiumCard.lumi => (
        l10n.pv2CardLumiEyebrow,
        l10n.pv2CardLumiTitle,
        l10n.pv2CardLumiBody,
        l10n.pv2CardLumiLimit(premium.lumiCredits),
      ),
      PremiumCard.rhythm => (
        l10n.pv2CardRhythmEyebrow,
        l10n.pv2CardRhythmTitle,
        l10n.pv2CardRhythmBody,
        l10n.pv2CardRhythmLimit(premium.lumiCredits),
      ),
      PremiumCard.storage => (
        l10n.pv2CardStorageEyebrow,
        l10n.pv2CardStorageTitle,
        l10n.pv2CardStorageBody,
        l10n.pv2CardStorageLimit(gb),
      ),
      PremiumCard.caregivers => (
        l10n.pv2CardCaregiversEyebrow,
        l10n.pv2CardCaregiversTitle,
        l10n.pv2CardCaregiversBody,
        l10n.pv2CardCaregiversLimit(
          premium.caregiverSeats,
          free.caregiverSeats,
        ),
      ),
    };
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $body. $limit',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: PremiumPalette.gold.withValues(alpha: 0.55),
            width: 1.2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PremiumPalette.cardTop, PremiumPalette.cardBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: PremiumPalette.gold.withValues(alpha: 0.12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 124,
              width: double.infinity,
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _Demo(card: card),
            ),
            const SizedBox(height: ClSpace.s3),
            Text(
              eyebrow,
              style: const TextStyle(
                color: PremiumPalette.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: ClSpace.s1),
            Text(
              title,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: PremiumPalette.serif,
                color: PremiumPalette.text,
                fontSize: 18,
                height: 1.2,
              ),
            ),
            const SizedBox(height: ClSpace.s1),
            Text(
              body,
              maxLines: 3,
              style: const TextStyle(
                color: Color(0xA8FFFFFF),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              limit,
              maxLines: 2,
              style: const TextStyle(
                color: PremiumPalette.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small picture of each card (never the family's data: illustrative copy only).
class _Demo extends StatelessWidget {
  const _Demo({required this.card});
  final PremiumCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const muted = TextStyle(color: PremiumPalette.textMuted, fontSize: 11);
    Widget row(ClIcons icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Row(
        children: [
          ClIcon(icon, size: 16, color: PremiumPalette.mint),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: PremiumPalette.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
    return switch (card) {
      PremiumCard.video => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(ClSpace.s2),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.pv2CardVideoDemo1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: PremiumPalette.serif,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF3A2E22),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2C6A0), Color(0xFF8FC9C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(ClSpace.s2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  l10n.pv2CardVideoDemo2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                ),
              ),
            ),
          ),
        ],
      ),
      PremiumCard.card => Row(
        children: [
          for (final (bg, ink) in const [
            (Color(0xFFF7EFE6), Color(0xFF6B4F3A)),
            (Color(0xFFFBE3E8), Color(0xFFB0506A)),
            (Color(0xFF1C2938), Color(0xFFFAD173)),
          ]) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.pv2CardCardDemo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: PremiumPalette.serif,
                    color: ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ]..removeLast(),
      ),
      PremiumCard.lumi => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s3,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: PremiumPalette.gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l10n.pv2CardLumiDemoQ,
                style: const TextStyle(
                  color: PremiumPalette.onGold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Container(
            padding: const EdgeInsets.all(ClSpace.s2),
            decoration: BoxDecoration(
              color: PremiumPalette.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pv2CardLumiDemoA,
                  style: const TextStyle(
                    color: PremiumPalette.text,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: ClSpace.s1),
                Text(l10n.pv2CardLumiDemoSource, style: muted),
              ],
            ),
          ),
        ],
      ),
      PremiumCard.rhythm => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (label, value, h, gold) in [
            (l10n.pv2CardRhythmDemoLast, '8g45', 36.0, false),
            (l10n.pv2CardRhythmDemoThis, '9g10', 52.0, true),
          ])
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClTabularText(
                  value,
                  style: TextStyle(
                    color: gold
                        ? PremiumPalette.gold
                        : PremiumPalette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ClSpace.s1),
                Container(
                  width: 40,
                  height: h,
                  decoration: BoxDecoration(
                    color: gold ? PremiumPalette.gold : PremiumPalette.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: ClSpace.s1),
                Text(label, style: muted),
              ],
            ),
        ],
      ),
      PremiumCard.storage => Column(
        children: [
          Row(
            children: [
              for (final c in const [
                Color(0xFFF2C6A0),
                Color(0xFF8FC9C2),
                Color(0xFFE8B4C0),
                Color(0xFFB9C9E8),
                Color(0xFFF4DD9B),
              ]) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ]..removeLast(),
          ),
          const Spacer(),
          row(ClIcons.check, l10n.pv2CardStorageDemo),
        ],
      ),
      PremiumCard.caregivers => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          row(ClIcons.feed, l10n.pv2CardCaregiversDemo1),
          row(ClIcons.sleep, l10n.pv2CardCaregiversDemo2),
        ],
      ),
    };
  }
}

/// "Free và Premium" (Bảng so sánh), "Bạn đang cần" on the entry's row.
class _Compare extends StatelessWidget {
  const _Compare({required this.free, required this.premium, this.need});
  final PlanOffer free;
  final PlanOffer premium;
  final PremiumEntry? need;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (
        l10n.pv2RowLumi,
        l10n.pv2RowLumiFree(free.lumiCredits),
        l10n.pv2RowLumiPremium(premium.lumiCredits),
        need == PremiumEntry.lumi,
      ),
      (
        l10n.pv2RowStorage,
        premiumGb(context, free.storageBytes),
        l10n.pv2RowStoragePremium(
          premiumGb(context, premium.storageBytes).replaceAll(' GB', ''),
        ),
        need == PremiumEntry.storage,
      ),
      (
        l10n.pv2RowVideo,
        l10n.pv2RowVideoFree(free.videoExports),
        l10n.pv2RowVideoPremium(premium.videoExports),
        need == PremiumEntry.video,
      ),
      (
        l10n.pv2RowTemplates,
        l10n.pv2RowTemplatesFree,
        l10n.pv2RowTemplatesPremium,
        need == PremiumEntry.card,
      ),
      (
        l10n.pv2RowCaregivers,
        l10n.pv2RowPeople(free.caregiverSeats),
        l10n.pv2RowPeople(premium.caregiverSeats),
        need == PremiumEntry.caregivers,
      ),
      (l10n.pv2RowRelatives, l10n.pv2Unlimited, l10n.pv2Unlimited, false),
    ];
    const head = TextStyle(
      color: PremiumPalette.textFaint,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.pv2CompareTitle,
            style: const TextStyle(
              fontFamily: PremiumPalette.serif,
              color: PremiumPalette.text,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Container(
          decoration: BoxDecoration(
            color: PremiumPalette.fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PremiumPalette.line),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s3,
                  ClSpace.s3,
                  ClSpace.s3,
                  ClSpace.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(l10n.pv2CompareBenefit, style: head),
                    ),
                    const Expanded(flex: 4, child: Text('Free', style: head)),
                    const Expanded(
                      flex: 4,
                      child: Text(
                        'Premium',
                        style: TextStyle(
                          color: PremiumPalette.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final (label, f, p, here) in rows)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: ClSpace.s3,
                  ),
                  decoration: BoxDecoration(
                    color: here
                        ? PremiumPalette.gold.withValues(alpha: 0.10)
                        : null,
                    border: const Border(
                      top: BorderSide(color: PremiumPalette.line),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: PremiumPalette.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (here) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: PremiumPalette.gold,
                                  borderRadius: BorderRadius.circular(
                                    ClRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  l10n.pv2YouNeed,
                                  style: const TextStyle(
                                    color: PremiumPalette.onGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          f,
                          style: const TextStyle(
                            color: PremiumPalette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          p,
                          style: const TextStyle(
                            color: PremiumPalette.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Component · Premium · Chọn gói (1020:17820), or what stands in for it (PW07, soon, has).
class _Footer extends StatelessWidget {
  const _Footer({
    required this.kind,
    required this.yearly,
    required this.price,
    required this.vnd,
    required this.storeName,
    required this.managerName,
    required this.busy,
    required this.bottom,
    required this.onPeriod,
    this.onBuy,
    this.onAskManager,
    this.onOpenPlan,
  });

  final PaywallFooter kind;
  final bool yearly;
  final PlanPrice price;
  final bool vnd;
  final String? storeName;
  final String managerName;
  final bool busy;
  final double bottom;
  final ValueChanged<bool> onPeriod;
  final VoidCallback? onBuy;
  final VoidCallback? onAskManager;
  final VoidCallback? onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(num v) => premiumPrice(context, v, vnd: vnd);
    final perMonth = vnd
        ? (price.year / 12 / 100).floor() * 100
        : (price.year / 12 * 100).floor() / 100;
    final saving = price.month <= 0
        ? 0
        : (100 - price.year / (price.month * 12) * 100).round();

    final children = <Widget>[];
    switch (kind) {
      case PaywallFooter.buy || PaywallFooter.soon:
        children.addAll([
          Row(
            children: [
              Expanded(
                child: _PeriodTile(
                  label: l10n.pv2PeriodYear,
                  badge: saving > 0 ? '−$saving%' : null,
                  price: money(price.year),
                  note: l10n.pv2PerMonthApprox(money(perMonth)),
                  selected: yearly,
                  onTap: () => onPeriod(true),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: _PeriodTile(
                  label: l10n.pv2PeriodMonth,
                  price: money(price.month),
                  note: l10n.pv2EachMonth,
                  selected: !yearly,
                  onTap: () => onPeriod(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          if (kind == PaywallFooter.buy) ...[
            PremiumGoldButton(
              label: yearly
                  ? l10n.pv2SubscribeYear(money(price.year))
                  : l10n.pv2SubscribeMonth(money(price.month)),
              onPressed: busy ? null : onBuy,
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              yearly
                  ? l10n.pv2LegalYear(money(price.year), storeName ?? '')
                  : l10n.pv2LegalMonth(money(price.month), storeName ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PremiumPalette.textFaint,
                fontSize: 10.5,
              ),
            ),
          ] else
            _Soon(title: l10n.pv2SoonTitle, body: l10n.pv2SoonBody),
        ]);
      case PaywallFooter.member:
        children.addAll([
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PremiumPalette.gold.withValues(alpha: 0.2),
                child: Text(
                  managerName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: PremiumPalette.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pv2ManagedBy(managerName),
                      style: const TextStyle(
                        color: PremiumPalette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.pv2OnlyManager(managerName),
                      style: const TextStyle(
                        color: PremiumPalette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          PremiumGoldButton(
            label: l10n.pv2AskManager(managerName),
            onPressed: onAskManager,
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.pv2AskPrivacy(managerName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PremiumPalette.textFaint,
              fontSize: 11,
            ),
          ),
        ]);
      case PaywallFooter.premium:
        children.addAll([
          Text(
            l10n.pv2HasPremium,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PremiumPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          PremiumGoldButton(
            label: l10n.pv2OpenFamilyPlan,
            onPressed: onOpenPlan,
          ),
        ]);
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s4,
        ClSpace.s4,
        bottom + ClSpace.s3,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: PremiumPalette.gold.withValues(alpha: 0.25)),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA121C1A), Color(0xFF0A1212)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(ClSpace.s3),
    decoration: BoxDecoration(
      color: PremiumPalette.fill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PremiumPalette.line),
    ),
    child: Row(
      children: [
        const ClIcon(ClIcons.clock, size: 20, color: PremiumPalette.gold),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PremiumPalette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: PremiumPalette.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.label,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: '$label, $price, $note',
    excludeSemantics: true,
    child: ClPressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: selected
              ? PremiumPalette.gold.withValues(alpha: 0.12)
              : PremiumPalette.fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? PremiumPalette.gold : PremiumPalette.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? PremiumPalette.gold
                          : PremiumPalette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge case final b?) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: PremiumPalette.gold,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: PremiumPalette.onGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: ClSpace.s1),
            ClTabularText(
              price,
              style: const TextStyle(
                fontFamily: PremiumPalette.serif,
                color: PremiumPalette.text,
                fontSize: 20,
              ),
            ),
            Text(
              note,
              style: const TextStyle(
                color: PremiumPalette.textFaint,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
