import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Motion spec P10 272:368 · "Đồng hồ đang ngủ (chuyển động nền)" plus Ambient rules 272:425.
///
/// - One breath every 4 s ("4 s/nhịp"): 0 s rest → 2 s peak → 4 s rest, looping, slow like breathing.
/// - The moon "thở": scale 1.0 → 1.04 → 1.0.
/// - The halo "đậm dần": radial sleep-accent glow, centre opacity 0.35 → 0.55 → 0.35 (measured on
///   the 170 px halo of the 150 px ring), fading to 0 at its edge.
/// - The progress ring does not breathe; it advances evenly with the seconds ("chạy đều theo giây").
/// - No haptic while it runs (P10; 5.2 "Không rung").
/// - Night care: the storyboard is drawn on the Night care background (#0c1719), so the values
///   are the same; per principle 03 nothing bounces or flashes (a sine, never above the peak),
///   and the cycle stays 4 s — ambient motion must stay slow, so it is not shortened.
/// - Paused when the app is not visible, the device asks for reduced motion, or ticks are off;
///   then it rests at the 0 s frame and only the counter moves ("chỉ còn số đếm").
abstract final class SleepBreath {
  static const Duration cycle = Duration(seconds: 4);
  static const double moonScalePeak = 1.04;
  static const double haloOpacityRest = 0.35;
  static const double haloOpacityPeak = 0.55;

  /// Halo diameter relative to the ring (170 px over 150 px in 272:368).
  static const double haloToRing = 170 / 150;

  /// The breath at [t] ∈ [0, 1) of a cycle: 0 at rest, 1 at the 2 s peak. A raised cosine,
  /// so it eases in and out with no overshoot.
  static double phase(double t) => (1 - math.cos(2 * math.pi * t)) / 2;

  static double moonScale(double phase) => 1 + (moonScalePeak - 1) * phase;

  static double haloOpacity(double phase) =>
      haloOpacityRest + (haloOpacityPeak - haloOpacityRest) * phase;
}

/// The breathing [SleepBreath.phase] of a repeating controller.
class SleepBreathCurve extends Curve {
  const SleepBreathCurve();

  @override
  double transformInternal(double t) => SleepBreath.phase(t);
}

/// Radial halo behind the sleep ring; repaints from [phase] without rebuilding widgets.
class SleepHaloPainter extends CustomPainter {
  SleepHaloPainter({required this.phase, required this.color})
    : super(repaint: phase);

  final Animation<double> phase;
  final Color color;

  /// The halo's centre opacity this frame.
  double get opacity => SleepBreath.haloOpacity(phase.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(SleepHaloPainter old) =>
      old.color != color || old.phase != phase;
}
