import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cl_theme.dart';

/// Haptics only where they mean something (owner request 2026-10-11, replacing the Motion
/// spec's tap / sheet / warning haptics): switching the main tab, and a save that shows its
/// success toast. Taps, sheets and confirmations stay silent. Night care: success only.
abstract final class ClHaptics {
  /// Switching the main tab (D-048), like the iOS selection tick.
  static void selection(BuildContext context) {
    if (!context.cl.isNightCare) HapticFeedback.selectionClick();
  }

  /// Call right where the success toast is shown, and nowhere else.
  static void success() => HapticFeedback.mediumImpact();
}
