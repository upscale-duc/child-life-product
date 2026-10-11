import 'package:flutter/material.dart';

import '../../../core/design/cl_theme.dart';
import '../../../core/widgets/cl_art.dart';
import '../../../core/widgets/cl_icon.dart';
import '../../../l10n/app_localizations.dart';

/// The v1.0 "growth journey" (368:930 on 01 Chào mừng, behind 06 and R1): a landscape with a
/// path from the first year to 12, stage chips and three floating cards. Built from widgets so
/// its small captions are translated (D-012); the photo node uses the privacy-safe illustrated
/// baby (Illustration/Photo). Laid out on the Figma 354 × 334 canvas and scaled to fit.
class JourneyHero extends StatelessWidget {
  const JourneyHero({super.key});

  static const canvas = Size(354, 334);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.a11yJourney,
      image: true,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: canvas.width / canvas.height,
          child: FittedBox(
            child: SizedBox.fromSize(size: canvas, child: const _Canvas()),
          ),
        ),
      ),
    );
  }
}

/// Node centres on the canvas, first year → 12.
const _nodes = [
  Offset(100, 269),
  Offset(167, 209),
  Offset(227, 171),
  Offset(288, 115),
];
const _card = Rect.fromLTWH(41, 10, 297, 298);

class _Canvas extends StatelessWidget {
  const _Canvas();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget at(Offset c, double w, double h, Widget child) => Positioned(
      left: c.dx - w / 2,
      top: c.dy - h / 2,
      width: w,
      height: h,
      child: child,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: _card,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: CustomPaint(
              painter: const _Landscape(),
              // Night care: the drawn landscape is daylight; veil it so it does not glare
              // (only Light is designed).
              foregroundPainter: Theme.of(context).brightness == Brightness.dark
                  ? _Veil(cl.colors.cardNight.withValues(alpha: 0.35))
                  : null,
            ),
          ),
        ),
        // Stage nodes: photo (mint-deep), star (sunshine), spark (sleep), globe (bottle).
        at(
          _nodes[0],
          48,
          48,
          _Node(
            ring: cl.colors.mintDeep,
            width: 3,
            child: const ClArt(ClIllustration.babyFace, fit: BoxFit.cover),
          ),
        ),
        at(
          _nodes[1],
          35,
          35,
          _Node(
            ring: const Color(0xFFFFD166),
            child: ClIcon(
              ClIcons.star,
              size: 13,
              color: const Color(0xFFE0A100),
            ),
          ),
        ),
        at(
          _nodes[2],
          31,
          31,
          _Node(
            ring: cl.care.sleep.accent,
            child: ClIcon(ClIcons.spark, size: 12, color: cl.care.sleep.accent),
          ),
        ),
        at(
          _nodes[3],
          27,
          27,
          _Node(
            ring: cl.care.bottle.accent,
            child: ClIcon(
              ClIcons.globe,
              size: 11,
              color: cl.care.bottle.accent,
            ),
          ),
        ),
        for (final (i, label) in [
          l10n.journeyStage1,
          l10n.journeyStage2,
          l10n.journeyStage3,
          l10n.journeyStage4,
        ].indexed)
          Positioned(
            left: _nodes[i].dx - 40,
            width: 80,
            top: _nodes[i].dy + [27.0, 22.0, 19.0, 17.0][i],
            child: Center(child: _StageChip(label)),
          ),
        Positioned(
          left: 19,
          top: 61,
          child: _FloatCard(
            lead: _Lead(
              color: cl.care.bottle.soft,
              child: ClIcon(
                ClIcons.feed,
                size: 9,
                color: cl.care.bottle.accent,
              ),
            ),
            title: l10n.journeyFeed,
            subtitle: l10n.journeyFeedWho,
          ),
        ),
        Positioned(
          left: 13,
          top: 193,
          child: _FloatCard(
            lead: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 22,
                height: 22,
                color: cl.colors.peachSoft,
                child: const ClArt(
                  ClIllustration.babyAvatar,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: l10n.journeySmile,
            subtitle: l10n.journeySmileSaved,
            subtitleColor: cl.colors.mintText,
          ),
        ),
        Positioned(
          left: 151,
          top: 295,
          child: _FloatCard(
            lead: ClIcon(ClIcons.heart, size: 8, color: cl.colors.mintDeep),
            title: l10n.journeyLove,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _Landscape extends CustomPainter {
  const _Landscape();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5D9), Color(0xFFE0F5F0)],
        ).createShader(r),
    );
    // Sun and halo.
    const sun = Offset(244, 51);
    canvas
      ..drawCircle(sun, 35, Paint()..color = const Color(0x40FFD166))
      ..drawCircle(sun, 25, Paint()..color = const Color(0xFFFFD166));
    // Clouds.
    final cloud = Paint()..color = const Color(0xE6FFFFFF);
    for (final (c, s) in [
      (const Offset(157, 32), 1.0),
      (const Offset(63, 51), 1.3),
    ]) {
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: c + Offset(-11 * s, 2 * s),
            width: 22 * s,
            height: 13 * s,
          ),
          cloud,
        )
        ..drawOval(
          Rect.fromCenter(center: c, width: 22 * s, height: 17 * s),
          cloud,
        )
        ..drawOval(
          Rect.fromCenter(
            center: c + Offset(11 * s, 2 * s),
            width: 20 * s,
            height: 12 * s,
          ),
          cloud,
        );
    }
    // Hills: peach, mint, then green in front.
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(82, 297), width: 494, height: 230),
        Paint()..color = const Color(0xFFFDEDE2),
      )
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(286, 313),
          width: 440,
          height: 208,
        ),
        Paint()..color = const Color(0xFFE6F7F5),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(93, 330), width: 384, height: 164),
        Paint()..color = const Color(0xFFE7F4E3),
      );
    // The road between the stages: white band with a dashed centre line.
    final points = [for (final n in _nodes) n - _card.topLeft];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final mid = (a.dx + b.dx) / 2;
      path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF),
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFDCE8E7);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 1.2), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_Landscape oldDelegate) => false;
}

class _Veil extends CustomPainter {
  const _Veil(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = color);

  @override
  bool shouldRepaint(_Veil oldDelegate) => oldDelegate.color != color;
}

class _Node extends StatelessWidget {
  const _Node({required this.ring, required this.child, this.width = 2.5});
  final Color ring;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.cl.colors.surface,
      border: Border.all(color: ring, width: width),
      boxShadow: context.cl.shadows.chip,
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: child,
  );
}

class _StageChip extends StatelessWidget {
  const _StageChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: cl.text.caption.copyWith(
          fontSize: 7,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: cl.colors.ink,
        ),
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(5),
    ),
    alignment: Alignment.center,
    child: child,
  );
}

class _FloatCard extends StatelessWidget {
  const _FloatCard({
    required this.lead,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.compact = false,
  });

  final Widget lead;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final base = cl.text.caption.copyWith(height: 1.25);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 7,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(compact ? 999 : 10),
        boxShadow: cl.shadows.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          SizedBox(width: compact ? 4 : 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: base.copyWith(
                  fontSize: compact ? 6.8 : 7.6,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: base.copyWith(
                    fontSize: 6.4,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor ?? cl.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
