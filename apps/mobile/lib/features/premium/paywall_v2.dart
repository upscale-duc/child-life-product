import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/tokens.g.dart';
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
    this.onTerms,
    this.onPrivacy,
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

  /// "Điều khoản" / "Quyền riêng tư" at the end of the legal line.
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  @override
  State<PaywallV2View> createState() => _PaywallV2State();
}

class _PaywallV2State extends State<PaywallV2View> {
  var _yearly = true;
  late final PageController _pages = PageController(
    // Component · Carousel: a 270 card centred in 375 with 12 between cards.
    viewportFraction: 282 / 375,
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
    PremiumEntry.rhythm => l10n.pv2HeadRhythm(widget.babyName),
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
    final price = widget.vnd
        ? (plan?.priceVn ?? const PlanPrice(month: 59000, year: 599000))
        : (plan?.priceIntl ?? const PlanPrice(month: 5.99, year: 49.99));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final explore = widget.entry == PremiumEntry.explore;

    return Scaffold(
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
            child: _Glow(width: 420, height: 320, color: Color(0x332CBFB3)),
          ),
          const Positioned(
            left: 150,
            top: 40,
            child: _Glow(width: 360, height: 280, color: Color(0x26E9C77B)),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _TopBar(
                        onClose: widget.onClose,
                        onRestore: widget.busy ? null : widget.onRestore,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: ClSpace.s6),
                          children: [
                            _Head(
                              headline: _headline(l10n),
                              reason: explore ? null : widget.reason,
                            ),
                            const SizedBox(height: 12),
                            _Carousel(
                              controller: _pages,
                              page: _page,
                              onPage: (i) => setState(() => _page = i),
                              free: free,
                              premium: premium,
                              babyName: widget.babyName,
                            ),
                            const SizedBox(height: 19),
                            _Compare(
                              free: free,
                              premium: premium,
                              need: explore ? null : widget.entry,
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
                onBuy: widget.onBuy == null
                    ? null
                    : () => widget.onBuy!(_yearly),
                onAskManager: widget.onAskManager,
                onOpenPlan: widget.onOpenPlan,
                onTerms: widget.onTerms,
                onPrivacy: widget.onPrivacy,
              ),
            ],
          ),
        ],
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
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// "Top": close (34) at the left, "Khôi phục" at the right.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, this.onRestore});
  final VoidCallback onClose;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            ClPressable(
              onPressed: onClose,
              semanticLabel: l10n.a11yClose,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
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
            const Spacer(),
            if (onRestore != null)
              ClPressable(
                onPressed: onRestore,
                semanticLabel: l10n.pv2Restore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: Text(
                    l10n.pv2Restore,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Head": crest, headline (Playfair 21) and the reason line.
class _Head extends StatelessWidget {
  const _Head({required this.headline, this.reason});
  final String headline;
  final String? reason;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumCrest(),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            headline,
            style: const TextStyle(
              fontFamily: PremiumPalette.serif,
              color: PremiumPalette.text,
              fontSize: 21,
              height: 1.18,
            ),
          ),
        ),
        if (reason case final r?) ...[
          const SizedBox(height: 4),
          Text(
            r,
            style: const TextStyle(
              color: PremiumPalette.textMuted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Component · Premium · Carousel (1020:17765): the card in view at 270 (0.9 of the 300 card),
/// the ones beside it at 228 (0.76) and 35 % opacity, the rest hidden; the scale follows the
/// swipe ("vuốt có hiệu ứng", PV00B). Dots under it: the active one a 22 pill.
class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.controller,
    required this.page,
    required this.onPage,
    required this.free,
    required this.premium,
    required this.babyName,
  });

  final PageController controller;
  final int page;
  final ValueChanged<int> onPage;
  final PlanOffer free;
  final PlanOffer premium;
  final String babyName;

  static const _big = 0.9;
  static const _small = 0.76;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          // The tallest card (Dung lượng / Người chăm, 298) at 0.9.
          height: 270,
          child: PageView.builder(
            controller: controller,
            clipBehavior: Clip.none,
            itemCount: PremiumCard.values.length,
            onPageChanged: onPage,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final current =
                    controller.hasClients &&
                        controller.position.hasContentDimensions
                    ? (controller.page ?? page.toDouble())
                    : page.toDouble();
                final d = (i - current).abs().clamp(0.0, 2.0);
                final t = d.clamp(0.0, 1.0);
                final scale = _big - (_big - _small) * t;
                final opacity = d >= 2
                    ? 0.0
                    : (d <= 1 ? 1 - 0.65 * t : 0.35 * (2 - d));
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    // Beside the current card the smaller one keeps the 12 gap on its near side.
                    alignment: i > current
                        ? Alignment.topLeft
                        : i < current
                        ? Alignment.topRight
                        : Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: 300,
                maxWidth: 300,
                maxHeight: 340,
                child: PremiumFeatureCard(
                  card: PremiumCard.values[i],
                  free: free,
                  premium: premium,
                  babyName: babyName,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Dots(count: PremiumCard.values.length, active: page),
      ],
    );
  }
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
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            width: i == active ? 22 : 6,
            height: 6,
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
const _white92 = Color(0xEBFFFFFF);

/// A 300-wide card: the demo panel (276 × 156) and its text block, as in the component.
class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    required this.card,
    required this.free,
    required this.premium,
    this.babyName = '',
    super.key,
  });

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
        l10n.pv2CardCaregiversLimit(
          premium.caregiverSeats,
          free.caregiverSeats,
        ),
      ),
    };
    final name = babyName.isEmpty ? 'Teddy' : babyName;
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $body. $limit',
      excludeSemantics: true,
      child: Container(
        width: 300,
        // Figma's 1.2 stroke sits inside the 12 padding: the demo panel stays 276 wide.
        padding: const EdgeInsets.all(12 - 1.2),
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
          boxShadow: const [
            BoxShadow(color: Color(0x2EE8BF66), blurRadius: 28),
            BoxShadow(
              color: Color(0x8C000000),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 276,
              height: 156,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
              ),
              child: switch (card) {
                PremiumCard.video => _VideoDemo(name: name),
                PremiumCard.card => _CardDemo(name: name),
                PremiumCard.lumi => const _LumiDemo(),
                PremiumCard.rhythm => const _RhythmDemo(),
                PremiumCard.storage => const _StorageDemo(),
                PremiumCard.caregivers => const _CaregiversDemo(),
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: _goldText.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.44,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: PremiumPalette.serif,
                      color: _white92,
                      fontSize: 17,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xA8FFFFFF),
                      fontSize: 12,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    limit,
                    style: _goldText.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
  const _CardDemo({required this.name});
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
    return _Panel(
      children: [
        Row(
          children: [
            for (final (i, f) in const [
              'baby-sleeping.jpg',
              'baby-newborn.jpg',
              'baby-smile.jpg',
              'family-1.jpg',
              'family-2.jpg',
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              _photo(f, width: 48, height: 48, radius: 8),
            ],
          ],
        ),
        _demoRow('✓', l10n.pv2CardStorageDemo, '09:41'),
        _demoRow('↑', l10n.pv2DemoUploading, '68%'),
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
        // Nhịp lớn lên counts in the Lumi credit ("Gồm trong 200 credit").
        need == PremiumEntry.lumi || need == PremiumEntry.rhythm,
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
      color: Color(0x80FFFFFF),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    Widget cols(Widget a, Widget b, Widget c) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 110, child: a),
        const SizedBox(width: 8),
        Expanded(flex: 90, child: b),
        const SizedBox(width: 8),
        Expanded(flex: 99, child: c),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.pv2CompareTitle,
              style: const TextStyle(
                fontFamily: PremiumPalette.serif,
                color: _white92,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: cols(
                    Text(l10n.pv2CompareBenefit, style: head),
                    Text(l10n.pv2PlanFree, style: head),
                    Text(
                      l10n.pv2PlanPremium,
                      style: head.copyWith(color: PremiumPalette.gold),
                    ),
                  ),
                ),
                for (final (label, f, p, here) in rows)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: here
                          ? PremiumPalette.gold.withValues(alpha: 0.1)
                          : null,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    child: cols(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: _white92,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (here) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: PremiumPalette.gold,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.pv2YouNeed,
                                style: const TextStyle(
                                  color: PremiumPalette.onGold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        f,
                        style: const TextStyle(
                          color: Color(0x8CFFFFFF),
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        p,
                        style: _goldText.copyWith(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final s in [
                l10n.pv2PromiseCancel,
                l10n.pv2PromiseNoTopUps,
                l10n.pv2PromiseYours,
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    required this.onPeriod,
    this.onBuy,
    this.onAskManager,
    this.onOpenPlan,
    this.onTerms,
    this.onPrivacy,
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
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

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
    const legal = TextStyle(
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
      case PaywallFooter.buy:
        children.addAll([
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(width: 8),
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
          ),
          const SizedBox(height: 10),
          PremiumGoldButton(
            label: yearly
                ? l10n.pv2SubscribeYear(money(price.year))
                : l10n.pv2SubscribeMonth(money(price.month)),
            onPressed: busy ? null : onBuy,
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: legal,
              children: [
                TextSpan(
                  text: yearly
                      ? l10n.pv2LegalYear(money(price.year), storeName ?? '')
                      : l10n.pv2LegalMonth(money(price.month), storeName ?? ''),
                ),
                const TextSpan(text: ' · '),
                link(l10n.pv2Terms, onTerms),
                const TextSpan(text: ' · '),
                link(l10n.pv2Privacy, onPrivacy),
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
                child: Text(
                  managerName.characters.first.toUpperCase(),
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
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottom > 0 ? bottom : 28),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: PremiumPalette.gold.withValues(alpha: 0.25)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? PremiumPalette.gold.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? PremiumPalette.gold
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? PremiumPalette.gold
                        : const Color(0xB3FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (badge case final b?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PremiumPalette.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: PremiumPalette.onGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontFamily: PremiumPalette.serif,
                color: selected ? Colors.white : const Color(0xBFFFFFFF),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
