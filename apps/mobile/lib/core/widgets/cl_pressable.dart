import 'package:flutter/widgets.dart';

import '../design/haptics.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';

/// Press feedback shared by buttons and tiles (Motion spec 269:41): scale 0.96 within
/// motion.instant, light haptic (none in Night care), 40 % opacity when disabled.
/// The hit area is at least tap-min (44).
class ClPressable extends StatefulWidget {
  const ClPressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.pressedScale = ClMotion.pressScale,
    this.isButton = true,
    this.selected,
    this.haptic = true,
    this.minSize = const Size(ClSpace.tapMin, ClSpace.tapMin),
    this.onLongPress,
    super.key,
  });

  /// Secondary action (e.g. a Today tile opens its last record).
  final VoidCallback? onLongPress;

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double pressedScale;
  final bool isButton;
  final bool? selected;
  final bool haptic;
  final Size minSize;

  @override
  State<ClPressable> createState() => _ClPressableState();
}

class _ClPressableState extends State<ClPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool value) {
    if (_enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final duration = context.motion(ClMotion.instant);
    return Semantics(
      button: widget.isButton,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onLongPress: widget.onLongPress,
        onTap: _enabled
            ? () {
                if (widget.haptic) ClHaptics.tap(context);
                widget.onPressed!();
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize.width,
            minHeight: widget.minSize.height,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedOpacity(
              opacity: _enabled ? 1 : ClMotion.disabledOpacity,
              duration: duration,
              child: AnimatedScale(
                scale: _pressed ? widget.pressedScale : 1,
                duration: duration,
                curve: ClCurves.instant,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
