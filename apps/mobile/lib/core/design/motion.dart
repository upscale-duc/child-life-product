import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// Motion helpers over the Figma Motion spec tokens (269:41). Reduce Motion removes movement.
/// Screen transitions are each platform's default (D-013), configured in the theme.
extension ClMotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// The token duration, or zero when the user asked for reduced motion.
  Duration motion(Duration token) => reduceMotion ? Duration.zero : token;
}

/// The `motion.standard` spring ("nảy rất nhẹ"): iOS `.spring(response: 0.35, dampingFraction: 0.86)`,
/// Android `spring(dampingRatio = 0.86, stiffness = 380)`.
SpringDescription standardSpring({TargetPlatform? platform}) {
  final target = platform ?? defaultTargetPlatform;
  if (target == TargetPlatform.android) {
    const stiffness = ClMotion.standardAndroidStiffness;
    return SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: stiffness,
      ratio: ClMotion.standardAndroidDampingRatio,
    );
  }
  const response = ClMotion.standardSpringResponse;
  final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
  return SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: stiffness,
    ratio: ClMotion.standardSpringDampingFraction,
  );
}

/// A [Curve] driven by a spring, for implicit animations that run over [ClMotion.standard].
class SpringCurve extends Curve {
  SpringCurve(this.spring, {this.duration = ClMotion.standard});

  final SpringDescription spring;
  final Duration duration;

  late final SpringSimulation _simulation = SpringSimulation(spring, 0, 1, 0);

  @override
  double transformInternal(double t) => _simulation.x(
    t * duration.inMicroseconds / Duration.microsecondsPerSecond,
  );
}

abstract final class ClCurves {
  static const Curve instant = ClMotion.instantCurve;
  static const Curve quick = ClMotion.quickCurve;
  static const Curve exit = ClMotion.exitCurve;
  static const Curve gentle = ClMotion.gentleCurve;
  static final Curve standard = SpringCurve(
    standardSpring(platform: _platformOrNull),
  );

  static TargetPlatform? get _platformOrNull {
    if (kIsWeb) return null;
    try {
      return Platform.isAndroid ? TargetPlatform.android : TargetPlatform.iOS;
    } on Object {
      return null;
    }
  }
}

/// Staggered entrance: 30 ms apart, at most 6 items (269:111). Index beyond 6 appears with the 6th.
Duration staggerDelay(int index) => Duration(
  milliseconds: ClMotion.staggerMs * math.min(index, ClMotion.staggerMax - 1),
);
