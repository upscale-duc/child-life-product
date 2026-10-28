import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/tokens.g.dart';
import '../../core/design/motion.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'premium_style.dart';
import 'premium_v2.dart';

/// Who is reading the paywall and what its footer can do.
enum PaywallFooter {
  /// The manager: period tiles and the gold CTA (before in-app purchase the CTA says the payment
  /// step is coming, owner 2026-10-25).
  buy,

  /// A member who does not manage the plan (PW07): ask the manager.
  member,

  /// The family already has Premium.
  premium,
}

/// Reviewed Premium v2 (1153:5491): shared plans, five benefits with details, and a sticky
/// payment summary. Contextual introductions live at the entry point. Config supplies prices.
class PaywallV2View extends StatefulWidget {
  const PaywallV2View({
    required this.entry,
    required this.footer,
    required this.babyName,
    required this.onClose,
    this.plan,
    this.preparedPrice,
    this.vnd = true,
    this.storeName,
    this.managerName,
    this.busy = false,
    this.busyLine,
    this.onRetryPrice,
    this.onBuy,
    this.onRestore,
    this.onAskManager,
    this.onOpenPlan,
    this.onTerms,
    this.onPrivacy,
    super.key,
  });

  final PremiumEntry entry;
  final PaywallFooter footer;
  final String babyName;
  final FamilyPlanV2? plan;

  /// A recent configured display price while the family answer refreshes.
  final PlanPrice? preparedPrice;

  final bool vnd;
  final String? storeName;
  final String? managerName;
  final bool busy;

  /// What is happening while [busy] ("Đang mở App Store…", "Đang xác nhận giao dịch…", P-4).
  final String? busyLine;

  /// Reloads the plan when its prices are unknown (P-3).
  final VoidCallback? onRetryPrice;
  final VoidCallback onClose;

  /// Yearly (true) or monthly; only with [PaywallFooter.buy].
  final void Function(bool yearly)? onBuy;
  final VoidCallback? onRestore;
  final VoidCallback? onAskManager;
  final VoidCallback? onOpenPlan;

  /// "Điều khoản" / "Quyền riêng tư" at the end of the legal line.
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  @override
  State<PaywallV2View> createState() => _PaywallV2State();
}

class _PaywallV2State extends State<PaywallV2View> {
  var _yearly = true;
  final _scroll = ScrollController();
  bool _scrolled = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _details(int index) => showPremiumDetails<void>(
    context: context,
    builder: (sheet) => _BenefitDetails(
      initial: index,
      free: widget.plan?.free ?? PlanOffer.free,
      premium: widget.plan?.premiumOffer ?? PlanOffer.premium,
      babyName: widget.babyName,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = widget.plan;
    final free = plan?.free ?? PlanOffer.free;
    final premium = plan?.premiumOffer ?? PlanOffer.premium;
    // P-3: no configured price → no price shown and no CTA, never "0đ" or a guessed one.
    final price = widget.preparedPrice ?? plan?.price(vnd: widget.vnd);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final benefits = _benefits(context, l10n, free, premium);
    final equivalent = price == null
        ? 0
        : widget.vnd
        ? (price.year / 12 / 100).floor() * 100
        : (price.year / 12 * 100).floor() / 100;
    final saving = price == null
        ? 0
        : (100 - price.year / (price.month * 12) * 100).round();
    String money(num n) => premiumPrice(context, n, vnd: widget.vnd);

    // Dark page: white status bar; leaving it, the screen below applies its own again.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PremiumPalette.deep,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [PremiumPalette.deepTop, PremiumPalette.deep],
                  ),
                ),
              ),
            ),
            // "Glow · mint" (top left) and "Glow · gold" (top right).
            const Positioned(
              left: -120,
              top: -120,
              child: _Glow(width: 420, height: 320, color: Color(0x472EC4A6)),
            ),
            const Positioned(
              left: 150,
              top: 40,
              child: _Glow(width: 360, height: 280, color: Color(0x38E9C77B)),
            ),
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        controller: _scroll,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.paddingOf(context).top + 49,
                          16,
                          24,
                        ),
                        children: [
                          _Head(
                            headline: l10n.pv2HeadExplore,
                            reason: l10n.premiumSharedPlans,
                          ),
                          const SizedBox(height: 24),
                          if (widget.footer == PaywallFooter.buy &&
                              price == null)
                            _PriceUnknown(onRetry: widget.onRetryPrice)
                          else if (widget.footer == PaywallFooter.buy &&
                              price != null) ...[
                            Text(
                              l10n.premiumChoosePlan,
                              style: _premiumText(14, .75, FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            _PeriodTile(
                              label: l10n.pv2PeriodYear,
                              price: money(price.year),
                              suffix: l10n.premiumYearSuffix,
                              note: l10n.pv2PerMonthApprox(money(equivalent)),
                              badge: saving > 0
                                  ? l10n.premiumSavePercent(saving)
                                  : null,
                              selected: _yearly,
                              onTap: widget.busy
                                  ? null
                                  : () => setState(() => _yearly = true),
                            ),
                            const SizedBox(height: 12),
                            _PeriodTile(
                              label: l10n.pv2PeriodMonth,
                              price: money(price.month),
                              suffix: l10n.premiumMonthSuffix,
                              note: l10n.pv2EachMonth,
                              selected: !_yearly,
                              onTap: widget.busy
                                  ? null
                                  : () => setState(() => _yearly = false),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            l10n.premiumBenefits,
                            style: _premiumText(14, .75, FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .10),
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < benefits.length; i++)
                                  _BenefitRow(
                                    benefit: benefits[i],
                                    onTap: () => _details(i),
                                    last: i == benefits.length - 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ColoredBox(
                        color: _scrolled
                            ? PremiumPalette.deepTop
                            : Colors.transparent,
                        child: SafeArea(
                          bottom: false,
                          child: _TopBar(
                            onClose: widget.onClose,
                            onRestore: widget.busy ? null : widget.onRestore,
                          ),
                        ),
                      ),
                    ],
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
                  busyLine: widget.busyLine,
                  bottom: bottom,
                  onBuy: widget.onBuy == null
                      ? null
                      : () => widget.onBuy!(_yearly),
                  onAskManager: widget.onAskManager,
                  onOpenPlan: widget.onOpenPlan,
                  onTerms: widget.onTerms,
                  onDetails: () => showPremiumDetails<void>(
                    context: context,
                    builder: (sheet) => _PaymentDetails(
                      yearly: _yearly,
                      price: price,
                      equivalent: equivalent,
                      vnd: widget.vnd,
                      storeName: widget.storeName,
                      onBuy: widget.busy || widget.onBuy == null
                          ? null
                          : () {
                              Navigator.of(sheet).pop();
                              widget.onBuy!(_yearly);
                            },
                    ),
                  ),
                  onPrivacy: widget.onPrivacy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.width, required this.height, required this.color});
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: width,
      height: height,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(
              Radius.elliptical(width / 2, height / 2),
            ),
          ),
        ),
      ),
    ),
  );
}

// Values below follow the approved Premium Figma, separate from care-screen typography.
TextStyle _premiumText(
  double size,
  double opacity, [
  FontWeight weight = FontWeight.w500,
]) => TextStyle(
  fontFamily: 'Be Vietnam Pro Keepsake',
  fontSize: size,
  letterSpacing: 0,
  height: 1.25,
  color: Colors.white.withValues(alpha: opacity),
  fontWeight: weight,
);

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, this.onRestore});
  final VoidCallback onClose;
  final VoidCallback? onRestore;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Transform.translate(
        offset: const Offset(0, -4),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              ClPressable(
                onPressed: onRestore,
                semanticLabel: l.pv2Restore,
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.pv2Restore,
                      style: _premiumText(13, .6, FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Transform.translate(
                offset: const Offset(5, 0),
                child: ClPressable(
                  onPressed: onClose,
                  semanticLabel: l.a11yClose,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .1),
                          ),
                        ),
                        child: const ClIcon(
                          ClIcons.close,
                          size: 16,
                          color: PremiumPalette.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.headline, this.reason});
  final String headline;
  final String? reason;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Transform.rotate(
            angle: .785398,
            child: const SizedBox(
              width: 7,
              height: 7,
              child: ColoredBox(color: PremiumPalette.gold),
            ),
          ),
          const SizedBox(width: 13),
          Text(
            AppLocalizations.of(context).pv2Crest,
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro Keepsake',
              color: PremiumPalette.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.42,
              height: 1.25,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Semantics(
        header: true,
        child: Text(
          headline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: PremiumPalette.serif,
            fontWeight: FontWeight.w400,
            fontSize: 24,
            height: 1.33,
            color: PremiumPalette.text,
          ),
        ),
      ),
      if (reason != null) ...[
        const SizedBox(height: 6),
        Text(reason!, textAlign: TextAlign.center, style: _premiumText(13, .7)),
      ],
    ],
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
            duration: context.motion(ClMotion.quick),
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            width: i == active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active
                  ? PremiumPalette.gold
                  : Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    ),
  );
}

// ---------- Component · Premium · Thẻ tính năng (1019:17008) ----------

const _goldText = TextStyle(color: PremiumPalette.gold);

/// Thẻ tính năng's glow + depth (0 0 28 gold 18 %, 0 16 32 black 55 %).
const _cardShadow = [
  BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 16)),
  BoxShadow(color: Color(0x2EE8BF66), blurRadius: 28),
];
const _white92 = Color(0xEBFFFFFF);

/// A 300-wide card: the demo panel (276 × 156) and its text block, as in the component.
class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    required this.card,
    required this.free,
    required this.premium,
    this.babyName = '',
    this.shadow = true,
    this.detail = false,
    super.key,
  });

  /// The carousel draws the glow once behind its centre slot instead (smooth swipe).
  final bool shadow;

  /// The reviewed benefit sheet shows only the illustration, eyebrow and title.
  final bool detail;
  final PremiumCard card;
  final PlanOffer free;
  final PlanOffer premium;
  final String babyName;

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
        l10n.premiumSeatsCardLimit(premium.caregiverSeats, free.caregiverSeats),
      ),
    };
    final shownEyebrow = detail && card == PremiumCard.lumi
        ? l10n.premiumLumiListTitle.toUpperCase()
        : eyebrow;
    final detailTitle = switch (card) {
      PremiumCard.lumi => l10n.premiumLumiDetailTitle,
      PremiumCard.rhythm => l10n.premiumRhythmDetailTitle,
      _ => title,
    };
    final name = babyName.isEmpty ? 'Teddy' : babyName;
    return Semantics(
      container: true,
      label: detail
          ? '$shownEyebrow. $detailTitle'
          : '$eyebrow. $title. $body. $limit',
      excludeSemantics: true,
      child: Container(
        width: 300,
        // Figma's 1.2 stroke sits inside the 12 padding: the demo panel stays 276 wide.
        padding: const EdgeInsets.all(12),
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
          boxShadow: shadow ? _cardShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 156,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 276,
                maxWidth: 276,
                minHeight: 156,
                maxHeight: 156,
                child: Container(
                  width: 276,
                  height: 156,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    // Exported Vietnamese panels already contain Figma's 28% black fill.
                    color:
                        Localizations.localeOf(context).languageCode == 'vi' &&
                            card != PremiumCard.card
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 276,
                      height: 156,
                      child: MediaQuery.withNoTextScaling(
                        child: switch (card) {
                          PremiumCard.video
                              when Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'vi' =>
                            Image.asset(
                              'assets/premium/keepsakes-demo-vi.png',
                              width: 276,
                              height: 156,
                              excludeFromSemantics: true,
                            ),
                          PremiumCard.video => Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: _CardDemo(name: name, single: true),
                              ),
                              Expanded(
                                child: FittedBox(
                                  child: SizedBox(
                                    width: 276,
                                    height: 156,
                                    child: _VideoDemo(name: name),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          PremiumCard.card => _CardDemo(name: name),
                          PremiumCard.lumi
                              when Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'vi' =>
                            Image.asset(
                              'assets/premium/lumi-demo-vi.png',
                              width: 276,
                              height: 156,
                              excludeFromSemantics: true,
                            ),
                          PremiumCard.lumi => const _LumiDemo(),
                          PremiumCard.rhythm
                              when Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'vi' =>
                            Image.asset(
                              'assets/premium/rhythm-demo-vi.png',
                              width: 276,
                              height: 156,
                              excludeFromSemantics: true,
                            ),
                          PremiumCard.rhythm => const _RhythmDemo(),
                          PremiumCard.storage
                              when Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'vi' =>
                            Image.asset(
                              'assets/premium/storage-demo-vi.png',
                              width: 276,
                              height: 156,
                              excludeFromSemantics: true,
                            ),
                          PremiumCard.storage => const _StorageDemo(),
                          PremiumCard.caregivers
                              when Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'vi' =>
                            Image.asset(
                              'assets/premium/caregivers-demo-vi.png',
                              width: 276,
                              height: 156,
                              excludeFromSemantics: true,
                            ),
                          PremiumCard.caregivers => const _CaregiversDemo(),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shownEyebrow,
                    style: _goldText.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      fontSize: 9,
                      height: 11 / 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.44,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail ? detailTitle : title,
                    style: const TextStyle(
                      fontFamily: PremiumPalette.serif,
                      fontWeight: FontWeight.w400,
                      color: _white92,
                      fontSize: 17,
                      height: 20 / 17,
                    ),
                  ),
                  if (!detail) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Color(0xA8FFFFFF),
                        fontFamily: 'Be Vietnam Pro Keepsake',
                        fontSize: 12,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      limit,
                      style: _goldText.copyWith(
                        fontFamily: 'Be Vietnam Pro Keepsake',
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The demo panel's own padding and gap (10, 7).
class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 7),
          c,
        ],
      ],
    ),
  );
}

Widget _photo(
  String asset, {
  double? width,
  double? height,
  double radius = 0,
}) => ClipRRect(
  borderRadius: BorderRadius.circular(radius),
  child: Image.asset(
    'assets/premium/$asset',
    width: width,
    height: height,
    // Decoded at about the size drawn (3x), not the file's.
    cacheWidth: ((width ?? 80) * 3).round(),
    fit: BoxFit.cover,
    excludeFromSemantics: true,
  ),
);

class _VideoDemo extends StatelessWidget {
  const _VideoDemo({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget scene(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 80, height: 104, child: child),
    );
    return _Panel(
      children: [
        Row(
          children: [
            scene(
              ColoredBox(
                color: const Color(0xFFF7F2E5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      l10n.pv2CardVideoDemo1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: PremiumPalette.serif,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF3B3329),
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            scene(
              Stack(
                fit: StackFit.expand,
                children: [
                  _photo('baby-sleeping.jpg'),
                  Positioned(
                    left: 5,
                    top: 86,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.pv2CardVideoDemo2,
                        style: const TextStyle(
                          color: _white92,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            scene(
              Stack(
                fit: StackFit.expand,
                children: [
                  _photo('baby-newborn.jpg'),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 1],
                        colors: [Color(0x00000000), Color(0xBF000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5,
                    right: 5,
                    top: 62,
                    child: Text(
                      l10n.pv2DemoVideoEnd(name),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: PremiumPalette.serif,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              '▸ 0:12 / 0:35',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 150,
              height: 4,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Container(
                width: 58,
                height: 4,
                decoration: BoxDecoration(
                  color: PremiumPalette.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.pv2DemoMuted,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Color(0x8CFFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardDemo extends StatelessWidget {
  const _CardDemo({required this.name, this.single = false});
  final bool single;
  final String name;

  static const _shadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const rad = 7 * 3.1415926535 / 180;
    Widget dot(String file, double left, double top, double size) => Positioned(
      left: left,
      top: top,
      child: SvgPicture.asset(
        'assets/premium/$file',
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
    );
    Text center(
      String s,
      double size,
      Color color, {
      String? family,
      FontWeight weight = FontWeight.w700,
      double spacing = 0,
    }) => Text(
      s,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.15,
      ),
    );
    // Print/minimal/portrait.
    final minimal = Container(
      width: 78,
      height: 108,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F3EA),
        boxShadow: _shadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7.2,
            top: 8.4,
            child: _photo('baby-newborn.jpg', width: 63.6, height: 68.7),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 80.7,
            child: center(
              name,
              10.8,
              const Color(0xFF3B3229),
              family: PremiumPalette.serif,
              weight: FontWeight.w400,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 95.7,
            child: center(
              l10n.pv2DemoCardDate,
              3.3,
              const Color(0xFFB89B72),
              weight: FontWeight.w300,
              spacing: 0.6,
            ),
          ),
        ],
      ),
    );
    // Print/playful/info (Quicksand is not shipped: the app's rounded Baloo 2 stands in).
    const ink = Color(0xFF2F4858);
    const orange = Color(0xFFE9A23B);
    const baloo = 'Baloo 2 Keepsake';
    final playful = Container(
      width: 78,
      height: 108,
      decoration: const BoxDecoration(
        color: Color(0xFFFCEEF1),
        boxShadow: _shadow,
      ),
      child: Stack(
        children: [
          dot('card-dot-c4ee9.svg', 6.24, 6.48, 6),
          dot('card-dot-0b23b.svg', 67.08, 10.8, 4.2),
          dot('card-dot-266a7.svg', 70.2, 84.24, 5.4),
          dot('card-dot-97ebc.svg', 4.68, 90.72, 3.6),
          Positioned(
            left: 0,
            right: 0,
            top: 13.2,
            child: center(l10n.pv2DemoCardHello, 3.3, orange, family: baloo),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 18,
            child: center(name, 16.8, ink, family: baloo),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 46.2,
            child: center(l10n.pv2DemoCardDays, 7.2, orange, family: baloo),
          ),
          const Positioned(
            left: 30,
            top: 62.4,
            child: SizedBox(
              width: 18,
              height: 0.36,
              child: ColoredBox(color: orange),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 67.2,
            child: center(
              l10n.pv2DemoCardBorn,
              2.5,
              orange,
              family: baloo,
              spacing: 0.3,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 70.2,
            child: center('17.08.2026', 5.1, ink, family: baloo),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 79.2,
            child: center(
              l10n.pv2DemoCardSize,
              2.5,
              orange,
              family: baloo,
              spacing: 0.3,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 82.2,
            child: center('3,2 kg · 50 cm', 5.1, ink, family: baloo),
          ),
          Positioned(
            left: 9,
            right: 9,
            top: 96,
            child: center(l10n.pv2DemoCardThanks, 3.6, ink, family: baloo),
          ),
        ],
      ),
    );
    // Print/timeless/collage.
    final timeless = Container(
      width: 78,
      height: 108,
      decoration: const BoxDecoration(
        color: Color(0xFFECE5DA),
        boxShadow: _shadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              width: 72,
              height: 102,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8C7B66), width: 0.48),
              ),
            ),
          ),
          Positioned(
            left: 4.2,
            top: 4.2,
            child: Container(
              width: 69.6,
              height: 99.6,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x998C7B66), width: 0.24),
              ),
            ),
          ),
          Positioned(
            left: 7.2,
            top: 8.4,
            child: _photo(
              'baby-smile.jpg',
              width: 30.6,
              height: 35.2,
              radius: 0.6,
            ),
          ),
          Positioned(
            left: 40.2,
            top: 8.4,
            child: _photo(
              'baby-hands.jpg',
              width: 30.6,
              height: 35.2,
              radius: 0.6,
            ),
          ),
          Positioned(
            left: 7.2,
            top: 46,
            child: _photo(
              'baby-feet.jpg',
              width: 30.6,
              height: 35.2,
              radius: 0.6,
            ),
          ),
          Positioned(
            left: 40.2,
            top: 46,
            child: _photo(
              'baby-portrait.jpg',
              width: 30.6,
              height: 35.2,
              radius: 0.6,
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: 84.8,
            child: center(
              name,
              7.2,
              const Color(0xFF4A3F35),
              family: 'Cormorant Garamond Keepsake',
              weight: FontWeight.w500,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 94.4,
            child: center(
              '25.11.2026',
              4.8,
              const Color(0xFF8C7B66),
              family: 'Dancing Script',
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
    if (single) {
      return Center(
        child: Transform.rotate(angle: rad, child: minimal),
      );
    }
    Widget chip(String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        s,
        style: const TextStyle(
          color: _white92,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 4.84 + (90.58 - 78) / 2,
          top: 16 + (116.7 - 108) / 2,
          child: Transform.rotate(angle: rad, child: minimal),
        ),
        Positioned(left: 98, top: 6, child: playful),
        Positioned(
          left: 178 + (90.58 - 78) / 2,
          top: 6.49 + (116.7 - 108) / 2,
          child: Transform.rotate(angle: -rad, child: timeless),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 134,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              chip(l10n.pv2DemoStyleMinimal),
              const SizedBox(width: 4),
              chip(l10n.pv2DemoStylePlayful),
              const SizedBox(width: 4),
              chip(l10n.pv2DemoStyleClassic),
            ],
          ),
        ),
      ],
    );
  }
}

class _LumiDemo extends StatelessWidget {
  const _LumiDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Panel(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: PremiumPalette.gold.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              l10n.pv2CardLumiDemoQ,
              style: const TextStyle(
                color: PremiumPalette.onGold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _Box(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          radius: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pv2CardLumiDemoA,
                style: const TextStyle(
                  color: _white92,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.pv2DemoLumiLast,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.pv2CardLumiDemoSource,
                style: _goldText.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RhythmDemo extends StatelessWidget {
  const _RhythmDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget week(String value, String label, double height, bool now) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 26,
          height: height,
          decoration: BoxDecoration(
            color: now
                ? PremiumPalette.gold
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: now ? Colors.white : const Color(0x99FFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
    return _Panel(
      children: [
        Text(
          l10n.pv2DemoRhythm,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: PremiumPalette.serif,
            fontWeight: FontWeight.w400,
            color: _white92,
            fontSize: 13,
            height: 1.32,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            week('8g45', l10n.pv2CardRhythmDemoLast, 38, false),
            const SizedBox(width: 12),
            week('9g10', l10n.pv2CardRhythmDemoThis, 46, true),
          ],
        ),
        Text(
          l10n.pv2CardLumiDemoSource,
          style: _goldText.copyWith(fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    this.radius = 10,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: child,
  );
}

/// A demo row: a gold lead (a mark or a role), the line, and a muted trailing value.
Widget _demoRow(String lead, String text, [String? trailing]) => _Box(
  child: Row(
    children: [
      Text(
        lead,
        style: _goldText.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _white92,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (trailing != null) ...[
        const SizedBox(width: 7),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0x8CFFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  ),
);

class _StorageDemo extends StatelessWidget {
  const _StorageDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Owner, 2026-10-25: the benefit is more room, not auto-save; the demo shows the room
    // growing and photos waiting for it.
    final free = premiumGb(context, PlanOffer.free.storageBytes);
    final premium = premiumGb(context, PlanOffer.premium.storageBytes);
    Widget bar(String label, double share, bool gold) => Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: gold ? PremiumPalette.gold : const Color(0x99FFFFFF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: gold
                      ? PremiumPalette.gold
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return _Panel(
      children: [
        bar(l10n.pv2DemoStorageFree(free), 0.1, false),
        bar(l10n.pv2DemoStoragePremium(premium), 1, true),
        Row(
          children: [
            for (final (i, f) in const [
              'baby-sleeping.jpg',
              'baby-newborn.jpg',
              'baby-smile.jpg',
              'family-1.jpg',
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              _photo(f, width: 40, height: 40, radius: 8),
            ],
            const SizedBox(width: 4),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Text(
                '+8',
                style: TextStyle(
                  color: _white92,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        _demoRow('↑', l10n.pv2DemoStorageWaiting),
      ],
    );
  }
}

class _CaregiversDemo extends StatelessWidget {
  const _CaregiversDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Panel(
      children: [
        _demoRow(l10n.pv2DemoMum, l10n.pv2DemoMumDid),
        _demoRow(l10n.pv2DemoDad, l10n.pv2DemoDadDid),
        _demoRow(l10n.pv2DemoGran, l10n.pv2DemoGranDid, '10:32'),
        Text(
          l10n.pv2DemoCareNote,
          style: const TextStyle(
            color: Color(0x8CFFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------- Compare (1021:17841) ----------

/// "Free và Premium" (Bảng so sánh), "Bạn đang cần" on the entry's row.
// ---------- Component · Premium · Chọn gói (1020:17820) ----------

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
    this.busyLine,
    this.onBuy,
    this.onAskManager,
    this.onOpenPlan,
    this.onTerms,
    this.onPrivacy,
    this.onDetails,
  });

  final VoidCallback? onDetails;
  final PaywallFooter kind;
  final bool yearly;
  final PlanPrice? price;
  final bool vnd;
  final String? storeName;
  final String managerName;
  final bool busy;
  final String? busyLine;
  final double bottom;
  final VoidCallback? onBuy;
  final VoidCallback? onAskManager;
  final VoidCallback? onOpenPlan;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(num v) => premiumPrice(context, v, vnd: vnd);
    const legal = TextStyle(
      fontFamily: 'Be Vietnam Pro Keepsake',
      color: Color(0x73FFFFFF),
      fontSize: 10,
      height: 1.45,
      fontWeight: FontWeight.w500,
    );
    TextSpan link(String label, VoidCallback? onTap) => TextSpan(
      text: label,
      style: legal.copyWith(
        decoration: onTap == null ? null : TextDecoration.underline,
      ),
      recognizer: onTap == null
          ? null
          : (TapGestureRecognizer()..onTap = onTap),
    );

    final children = <Widget>[];
    switch (kind) {
      case PaywallFooter.buy when price == null:
        // P-3: the period tiles say the price is unknown; the CTA waits for it.
        children.add(
          PremiumGoldButton(label: l10n.pv2SubscribeNoPrice, onPressed: null),
        );
      case PaywallFooter.buy:
        final price = this.price!;
        children.addAll([
          ClPressable(
            onPressed: onDetails,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.premiumTodayTotal,
                      style: _premiumText(13, .7),
                    ),
                  ),
                  Text(
                    money(yearly ? price.year : price.month),
                    style: const TextStyle(
                      fontFamily: PremiumPalette.serif,
                      fontWeight: FontWeight.w400,
                      fontSize: 22,
                      height: 1.32,
                      color: PremiumPalette.text,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  const RotatedBox(
                    quarterTurns: 2,
                    child: ClIcon(
                      ClIcons.chevronDown,
                      size: 16,
                      color: PremiumPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2.5),
          PremiumGoldButton(
            label: yearly
                ? l10n.pv2SubscribeYear(money(price.year))
                : l10n.pv2SubscribeMonth(money(price.month)),
            loading: busy,
            onPressed: busy ? null : onBuy,
          ),
          const SizedBox(height: 10),
          if (busy && busyLine != null) ...[
            Text(
              busyLine!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PremiumPalette.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text.rich(
            TextSpan(
              style: legal,
              children: [
                TextSpan(text: l10n.premiumLegalIntro(storeName ?? '')),
                link(l10n.pv2Terms, onTerms),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ]);
      case PaywallFooter.member:
        children.addAll([
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PremiumPalette.gold.withValues(alpha: 0.2),
                // P-8: an empty name must not crash the footer.
                child: Text(
                  (managerName.characters.firstOrNull ?? '·').toUpperCase(),
                  style: _goldText.copyWith(fontWeight: FontWeight.w700),
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
                        color: _white92,
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
          const SizedBox(height: 10),
          PremiumGoldButton(
            label: l10n.pv2AskManager(managerName),
            onPressed: onAskManager,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.pv2AskPrivacy(managerName),
            textAlign: TextAlign.center,
            style: legal,
          ),
        ]);
      case PaywallFooter.premium:
        children.addAll([
          Text(
            l10n.pv2HasPremium,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _white92,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          PremiumGoldButton(
            label: l10n.pv2OpenFamilyPlan,
            onPressed: onOpenPlan,
          ),
        ]);
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        kind == PaywallFooter.buy && price != null ? 6.5 : 14,
        16,
        28 + (bottom > 34 ? bottom - 34 : 0),
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: PremiumPalette.gold.withValues(alpha: 0.2)),
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

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.label,
    required this.price,
    required this.suffix,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final String label, price, suffix, note;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: '$label, $price$suffix, $note',
    excludeSemantics: true,
    child: ClPressable(
      onPressed: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: selected
                  ? PremiumPalette.gold.withValues(alpha: .1)
                  : Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? PremiumPalette.gold
                    : Colors.white.withValues(alpha: .12),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: _premiumText(
                          14,
                          selected ? .95 : .7,
                          FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: TextStyle(
                                fontFamily: PremiumPalette.serif,
                                fontWeight: FontWeight.w400,
                                fontSize: 26,
                                height: 35 / 26,
                                color: selected
                                    ? PremiumPalette.gold
                                    : const Color(0xE6FFFFFF),
                              ),
                            ),
                            TextSpan(
                              text: ' $suffix',
                              style: _premiumText(13, .8, FontWeight.w600)
                                  .copyWith(
                                    color: selected
                                        ? PremiumPalette.gold
                                        : const Color(0xCCFFFFFF),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(note, style: _premiumText(12, .55)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? PremiumPalette.gold : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? PremiumPalette.gold
                          : Colors.white.withValues(alpha: .3),
                    ),
                  ),
                  child: selected
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PremiumPalette.deep,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -12.5,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PremiumPalette.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontFamily: 'Be Vietnam Pro Keepsake',
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: PremiumPalette.onGold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Five reviewed benefits. Video and card share one detail, never two competing upgrades.
typedef _Benefit = ({
  String title,
  String subtitle,
  PremiumCard card,
  ClIcons icon,
});
List<_Benefit> _benefits(
  BuildContext context,
  AppLocalizations l,
  PlanOffer free,
  PlanOffer paid,
) => [
  (
    title: l.premiumMemories,
    subtitle: l.premiumMemoriesSubtitle,
    card: PremiumCard.video,
    icon: ClIcons.camera,
  ),
  (
    title: l.premiumLumiListTitle,
    subtitle: l.pv2CardLumiLimit(paid.lumiCredits),
    card: PremiumCard.lumi,
    icon: ClIcons.spark,
  ),
  (
    title: l.premiumRhythm,
    subtitle: l.premiumRhythmSubtitle,
    card: PremiumCard.rhythm,
    icon: ClIcons.sleep,
  ),
  (
    title: l.premiumStorageListTitle(premiumGb(context, paid.storageBytes)),
    subtitle: l.premiumStorageSubtitle,
    card: PremiumCard.storage,
    icon: ClIcons.cloudOff,
  ),
  (
    title: l.premiumSeatsListTitle(paid.caregiverSeats),
    subtitle: l.premiumSeatsSubtitle,
    card: PremiumCard.caregivers,
    icon: ClIcons.family,
  ),
];

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.benefit,
    required this.onTap,
    this.last = false,
  });
  final _Benefit benefit;
  final VoidCallback onTap;
  final bool last;
  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .07)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PremiumPalette.gold.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClIcon(benefit.icon, size: 20, color: PremiumPalette.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: _premiumText(14, .92, FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.subtitle,
                  style: _premiumText(12, .55).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ClIcon(
            ClIcons.chevronRight,
            size: 16,
            color: PremiumPalette.textMuted,
          ),
        ],
      ),
    ),
  );
}

class _BenefitDetails extends StatefulWidget {
  const _BenefitDetails({
    required this.initial,
    required this.free,
    required this.premium,
    required this.babyName,
  });
  final int initial;
  final PlanOffer free;
  final PlanOffer premium;
  final String babyName;
  @override
  State<_BenefitDetails> createState() => _BenefitDetailsState();
}

/// Figma sheets own their dark surface; the shared route owns dismissal and motion.
class _BenefitDetailsState extends State<_BenefitDetails> {
  // Latest Figma's tallest detail (Lumi). One height across all five pages prevents jumps.
  // The route clamps it on smaller screens; large text scrolls inside the page.
  static const _sheetHeight = 552.0;
  late int _page = 5000 + widget.initial;
  late final _controller = PageController(initialPage: _page);
  int get _index => _page % 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(bool next) {
    final target = _page + (next ? 1 : -1);
    if (context.reduceMotion) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: context.motion(ClMotion.quick),
        curve: ClCurves.quick,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = _benefits(context, l, widget.free, widget.premium);
    final allBullets = [
      [
        l.premiumMemoriesBullet1,
        l.premiumMemoriesBullet2,
        l.premiumMemoriesBullet3,
      ],
      [
        l.premiumLumiBullet1,
        l.premiumLumiBullet2,
        l.premiumLumiBullet3(widget.premium.lumiCredits),
      ],
      [l.premiumRhythmBullet1, l.premiumRhythmBullet2, l.premiumRhythmBullet3],
      [
        l.premiumStorageBullet1(
          premiumGb(context, widget.premium.storageBytes),
        ),
        l.premiumStorageBullet2,
        l.premiumStorageBullet3,
      ],
      [
        l.premiumSeatsBullet1,
        l.premiumSeatsBullet2,
        l.premiumSeatsBullet3(widget.premium.caregiverSeats),
      ],
    ];

    final titles = [
      for (var i = 0; i < items.length; i++)
        '${i + 1}/5 · ${switch (i) {
          1 => l.premiumLumiPager,
          2 => l.premiumRhythmPager,
          4 => l.premiumSeatsPager,
          _ => items[i].title,
        }}',
    ];
    final titleStyle = _premiumText(12, .8, FontWeight.w600);
    Widget arrow(bool next) => SizedBox(
      width: 44,
      height: 44,
      child: ClPressable(
        onPressed: () => _move(next),
        semanticLabel: next
            ? MaterialLocalizations.of(context).nextPageTooltip
            : MaterialLocalizations.of(context).previousPageTooltip,
        child: Align(
          alignment: next ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .08),
            ),
            child: ClIcon(
              next ? ClIcons.chevronRight : ClIcons.back,
              size: 16,
              color: PremiumPalette.textMuted,
            ),
          ),
        ),
      ),
    );
    Widget page(int index) {
      final item = items[index];
      final bullets = allBullets[index];
      return SingleChildScrollView(
        key: PageStorageKey('premium-benefit-$index'),
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PremiumFeatureCard(
                card: item.card,
                free: widget.free,
                premium: widget.premium,
                babyName: widget.babyName,
                shadow: true,
                detail: true,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < bullets.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClIcon(
                    ClIcons.check,
                    size: 12,
                    color: PremiumPalette.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullets[i],
                      style: _premiumText(13, .8).copyWith(height: 19 / 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      key: const ValueKey('premium-benefit-sheet'),
      height: _sheetHeight,
      child: _DetailSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DetailGrabber(),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                // Reserve the longest localized title at this text scale, so the header also stays still.
                double titleHeight = 0;
                for (final title in titles) {
                  final painter = TextPainter(
                    text: TextSpan(text: title, style: titleStyle),
                    textScaler: MediaQuery.textScalerOf(context),
                    textDirection: Directionality.of(context),
                    locale: Localizations.localeOf(context),
                  )..layout(maxWidth: constraints.maxWidth - 88);
                  if (painter.height > titleHeight) {
                    titleHeight = painter.height;
                  }
                  painter.dispose();
                }
                return Row(
                  children: [
                    arrow(false),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: titleHeight,
                            child: Center(
                              child: Text(
                                titles[_index],
                                textAlign: TextAlign.center,
                                style: titleStyle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _Dots(count: 5, active: _index),
                        ],
                      ),
                    ),
                    arrow(true),
                  ],
                );
              },
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                allowImplicitScrolling: true,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => page(index % 5),
              ),
            ),
            const SizedBox(height: 14),
            PremiumGoldButton(
              label: l.premiumBackToPlans,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      30 +
          (MediaQuery.paddingOf(context).bottom > 34
              ? MediaQuery.paddingOf(context).bottom - 34
              : 0),
    ),
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      border: Border.all(color: PremiumPalette.gold.withValues(alpha: .2)),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [PremiumPalette.sheetTop, PremiumPalette.sheetBottom],
      ),
    ),
    child: child,
  );
}

class _DetailGrabber extends StatelessWidget {
  const _DetailGrabber();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

class _PaymentDetails extends StatelessWidget {
  const _PaymentDetails({
    required this.yearly,
    required this.price,
    required this.equivalent,
    required this.vnd,
    required this.storeName,
    required this.onBuy,
  });
  final bool yearly, vnd;
  final PlanPrice? price;
  final num equivalent;
  final String? storeName;
  final VoidCallback? onBuy;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String money(num v) => premiumPrice(context, v, vnd: vnd);
    final total = price == null
        ? ''
        : money(yearly ? price!.year : price!.month);
    Widget row(String title, String value, {bool total = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: _premiumText(
              total ? 14 : 13,
              .7,
              total ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Text(
          value,
          style: total
              ? const TextStyle(
                  fontFamily: PremiumPalette.serif,
                  fontWeight: FontWeight.w400,
                  color: PremiumPalette.gold,
                  fontSize: 22,
                  height: 1.32,
                )
              : _premiumText(13, .85, FontWeight.w600),
        ),
      ],
    );
    return _DetailSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DetailGrabber(),
            const SizedBox(height: 12),
            Text(
              l.premiumPaymentDetails,
              style: const TextStyle(
                fontFamily: PremiumPalette.serif,
                fontWeight: FontWeight.w400,
                fontSize: 20,
                height: 1.35,
                color: PremiumPalette.text,
              ),
            ),
            const SizedBox(height: 12),
            row(
              'Premium · ${yearly ? l.pv2PeriodYear : l.pv2PeriodMonth}',
              total,
            ),
            if (yearly && price != null) ...[
              const SizedBox(height: 12),
              row(l.premiumPaymentEquivalent, money(equivalent)),
              const SizedBox(height: 12),
              row(
                l.premiumPaymentSaving,
                '${money(price!.month * 12 - price!.year)}${l.premiumYearSuffix}',
              ),
            ],
            const SizedBox(height: 12),
            row(l.premiumPaymentTax, l.premiumPaymentTaxValue),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withValues(alpha: .1)),
            const SizedBox(height: 12),
            row(l.premiumTodayTotal, total, total: true),
            const SizedBox(height: 12),
            Text(
              l.premiumPaymentRenewal(total, storeName ?? ''),
              style: _premiumText(11, .55).copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            PremiumGoldButton(
              label: yearly
                  ? l.premiumSubscribeYearShort
                  : l.premiumSubscribeMonthShort,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}

/// P-3: the plan's prices could not be read; nothing to choose until they are.
class _PriceUnknown extends StatelessWidget {
  const _PriceUnknown({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: PremiumPalette.fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PremiumPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pv2PriceUnknown,
            style: const TextStyle(color: PremiumPalette.text, fontSize: 15),
          ),
          if (onRetry case final retry?) ...[
            const SizedBox(height: ClSpace.s2),
            PremiumTextButton(label: l10n.actionRetry, onPressed: retry),
          ],
        ],
      ),
    );
  }
}
