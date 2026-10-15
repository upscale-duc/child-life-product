import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';

/// Lumi, the assistant's mascot (Figma 627:62667; D-076 #11): a speech bubble from teal to
/// indigo with one gold eye, a soft smile and a gold sparkle, on a soft glow. Brand art like the
/// logo: the same colours in Light and Night care (gold `sunshine` is the same in both); only the
/// glow is softer at night.
abstract final class LumiColors {
  static const teal = Color(0xFF2CBFB3);
  static const deep = Color(0xFF0B8A84);
  static const indigo = Color(0xFF5B5FD6);
  static const gold = Color(0xFFFFD166);
}

/// The face alone ([size] square; the sparkles reach a little past the top-right corner).
class LumiMascot extends StatelessWidget {
  const LumiMascot({this.size = 56, this.twinkle, super.key});
  final double size;

  /// 0…1 while the attention sweep runs: the gold sparkle grows a little and back.
  final Animation<double>? twinkle;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _MascotPainter(
        twinkle: twinkle,
        smile: Colors.white.withValues(alpha: 0.55),
      ),
    ),
  );
}

/// The bubble: round corners, the bottom-right one tighter (the tail of a speech bubble).
RRect _bubble(Rect r, double unit, {double grow = 0}) =>
    RRect.fromRectAndCorners(
      r.inflate(grow),
      topLeft: Radius.circular(18 * unit + grow),
      topRight: Radius.circular(18 * unit + grow),
      bottomLeft: Radius.circular(18 * unit + grow),
      bottomRight: Radius.circular(6 * unit + grow),
    );

/// A four-point sparkle centred on [c], tips at [r] (curves through the centre: concave sides).
Path _sparkle(Offset c, double r) {
  final tips = [
    c + Offset(0, -r),
    c + Offset(r, 0),
    c + Offset(0, r),
    c + Offset(-r, 0),
  ];
  final path = Path()..moveTo(tips[0].dx, tips[0].dy);
  for (var i = 1; i <= 4; i++) {
    final t = tips[i % 4];
    path.quadraticBezierTo(c.dx, c.dy, t.dx, t.dy);
  }
  return path..close();
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.smile, this.twinkle}) : super(repaint: twinkle);
  final Animation<double>? twinkle;
  final Color smile;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final u = s / 56;
    final rect = Offset.zero & size;
    final body = _bubble(rect, u);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LumiColors.teal, LumiColors.deep, LumiColors.indigo],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // A thin light edge, so the face reads on dark and mint backgrounds alike.
    canvas.drawRRect(
      body.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    // One gold eye.
    canvas.drawCircle(
      Offset(0.57 * s, 0.37 * s),
      3.6 * u,
      Paint()..color = LumiColors.gold,
    );
    // The smile: a soft bowl.
    final mouth = Path()
      ..moveTo(0.30 * s, 0.53 * s)
      ..lineTo(0.72 * s, 0.53 * s)
      ..cubicTo(0.72 * s, 0.66 * s, 0.62 * s, 0.71 * s, 0.51 * s, 0.71 * s)
      ..cubicTo(0.40 * s, 0.71 * s, 0.30 * s, 0.66 * s, 0.30 * s, 0.53 * s)
      ..close();
    canvas.drawPath(mouth, Paint()..color = smile);
    // The sparkles at the top-right corner.
    final t = twinkle?.value ?? 0;
    final grow = 1 + 0.2 * math.sin(math.pi * t);
    canvas.drawPath(
      _sparkle(Offset(0.92 * s, 0.05 * s), 10.5 * u * grow),
      Paint()..color = LumiColors.gold,
    );
    // The small one is white with a teal edge, so it reads on a light page too.
    final small = _sparkle(Offset(1.05 * s, 0.31 * s), 4.5 * u);
    canvas
      ..drawPath(small, Paint()..color = Colors.white)
      ..drawPath(
        small,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * u
          ..color = LumiColors.teal.withValues(alpha: 0.6),
      );
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.twinkle != twinkle || old.smile != smile;
}

/// Chat/Nút trợ lý as Lumi (627:62667) with an attention ring around it (D-076 #11): a gradient
/// sheen sweeps once around the bubble, rests, and sweeps again. Nothing moves with Reduce
/// Motion (a still ring instead), while the button is off screen (another screen on top: its
/// ticker is muted) or while the app is in the background; the sweep repaints only its own
/// layer. [highlight] draws the ring of the first-run tooltip (669:64442).
class AsFloatingButton extends StatefulWidget {
  const AsFloatingButton({
    required this.onPressed,
    this.highlight = false,
    this.attention = true,
    super.key,
  });

  final VoidCallback onPressed;
  final bool highlight;

  /// Whether the sheen sweeps at all (off for the copy above the tooltip's scrim).
  final bool attention;

  /// One sweep and the pause after it.
  static const sweep = Duration(milliseconds: 2400);
  static const rest = Duration(seconds: 4);

  @override
  State<AsFloatingButton> createState() => AsFloatingButtonState();
}

class AsFloatingButtonState extends State<AsFloatingButton>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: AsFloatingButton.sweep,
  )..addStatusListener(_onStatus);
  late final AppLifecycleListener _life;
  Timer? _rest;
  var _reduce = false;
  var _onScreen = true;
  var _foreground = true;

  /// The sheen is sweeping or waiting for its next sweep.
  @visibleForTesting
  bool get attentionRunning => _sweep.isAnimating || _rest != null;

  bool get _shouldRun =>
      widget.attention && !_reduce && _onScreen && _foreground;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _life = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = context.reduceMotion;
    _onScreen = TickerMode.valuesOf(context).enabled;
    _update();
  }

  @override
  void didUpdateWidget(AsFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attention != widget.attention) _update();
  }

  void _onLifecycle(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _update();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _sweep.value = 0;
    _rest?.cancel();
    _rest = Timer(AsFloatingButton.rest, () {
      _rest = null;
      if (mounted && _shouldRun) _sweep.forward(from: 0);
    });
  }

  void _update() {
    if (_shouldRun) {
      if (!attentionRunning) _sweep.forward(from: 0);
    } else {
      _rest?.cancel();
      _rest = null;
      _sweep
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rest?.cancel();
    _life.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: widget.onPressed,
      semanticLabel: l10n.asFabLabel,
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('lumi.ring'),
          painter: _GlowPainter(night: cl.isNightCare),
          foregroundPainter: _RingPainter(
            sweep: _sweep,
            still: cl.colors.mint.withValues(alpha: cl.isNightCare ? 0.5 : 0.4),
            sheen: cl.colors.mint,
            highlight: widget.highlight ? cl.colors.mint : null,
          ),
          child: LumiMascot(twinkle: _sweep),
        ),
      ),
    );
  }
}

/// The soft glow under the bubble (teal and indigo, like 627:62667).
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.night});
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 56;
    final body = _bubble(Offset.zero & size, u);
    canvas.drawRRect(
      body.shift(Offset(0, 4 * u)),
      Paint()
        ..color = LumiColors.teal.withValues(alpha: night ? 0.22 : 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      body.shift(Offset(3 * u, 6 * u)).deflate(6 * u),
      Paint()
        ..color = LumiColors.indigo.withValues(alpha: night ? 0.2 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.night != night;
}

/// A still ring around the bubble, the sheen sweeping over it while [sweep] runs, and the
/// tooltip's highlight ring.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.sweep,
    required this.still,
    required this.sheen,
    this.highlight,
  }) : super(repaint: sweep);

  final Animation<double> sweep;
  final Color still;
  final Color sheen;
  final Color? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 56;
    final rect = Offset.zero & size;
    final ring = _bubble(rect, u, grow: 4 * u);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * u
      ..color = still;
    canvas.drawRRect(ring, stroke);
    if (highlight case final h?) {
      canvas.drawRRect(
        _bubble(rect, u, grow: 7 * u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * u
          ..color = h,
      );
    }
    final p = sweep.value;
    if (p <= 0 || p >= 1) return;
    // One eased turn; the sheen fades in and out so it never pops.
    final turn = Curves.easeInOut.transform(p);
    final fade = math.sin(math.pi * p);
    final bounds = ring.outerRect;
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * u
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            sheen.withValues(alpha: 0),
            sheen.withValues(alpha: 0),
            sheen.withValues(alpha: fade),
            LumiColors.gold.withValues(alpha: fade),
            sheen.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 0.82, 0.94, 1],
          transform: GradientRotation(2 * math.pi * turn - math.pi / 2),
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.sweep != sweep ||
      old.still != still ||
      old.sheen != sheen ||
      old.highlight != highlight;
}
