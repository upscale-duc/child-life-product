import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cl_theme.dart';

/// Haptics per the Motion spec (271:537): light on tap, success when a save completes,
/// warning before delete / duplicate time. Night care: no haptics except success.
abstract final class ClHaptics {
  static void tap(BuildContext context) {
    if (!context.cl.isNightCare) HapticFeedback.lightImpact();
  }

  static void success() => HapticFeedback.mediumImpact();

  static void warning(BuildContext context) {
    if (!context.cl.isNightCare) HapticFeedback.heavyImpact();
  }
}
