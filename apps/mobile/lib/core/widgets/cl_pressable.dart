import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../design/motion.dart';
import '../design/tokens.g.dart';

/// Press feedback shared by buttons and tiles: the system button highlight (D-048, replacing
/// the Motion spec's 0.96 scale) — dims on touch down and fades back on release with
/// [CupertinoButton]'s timings, playing in full even for a quick tap. Light haptic (none in
/// Night care), 40 % opacity when disabled. The hit area is at least tap-min (44).
class ClPressable extends StatefulWidget {
  const ClPressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.pressedOpacity = 0.4,
    this.isButton = true,
    this.selected,
    this.minSize = const Size(ClSpace.tapMin, ClSpace.tapMin),
    this.onLongPress,
    super.key,
  });

  /// Opacity while held: 0.4 like a system button, lighter for large surfaces (rows, tiles),
  /// 1 for controls whose selection change is the feedback (tabs, segments).
  static const double surfaceOpacity = 0.7;

  /// Secondary action (e.g. a Today tile opens its last record).
  final VoidCallback? onLongPress;

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double pressedOpacity;
  final bool isButton;
  final bool? selected;
  final Size minSize;

  @override
  State<ClPressable> createState() => _ClPressableState();
}

// CupertinoButton's highlight timings, plus the touch-down wait (UIKit delays content touches
// in scroll views by about 150 ms; Flutter already holds a tap down 100 ms there) and the quick
// fade when a scroll takes the touch.
const _fadeOut = Duration(milliseconds: 120);
const _fadeIn = Duration(milliseconds: 180);
const _settle = Duration(milliseconds: 50);
const _abortFade = Duration(milliseconds: 90);

class _ClPressableState extends State<ClPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _held = AnimationController(
    vsync: this,
    value: 0,
  );
  bool _heldDown = false;

  /// Between onTapDown and onTapUp / onTapCancel. The recognizer reports moves before it has
  /// sent a tap down, and sends no cancel for a tap that never went down, so moves only count
  /// inside a started tap; otherwise a finger's jitter at the start of a scroll left the
  /// control dimmed for good.
  bool _tapActive = false;
  DateTime? _dimmedAt;
  Timer?
  _dimSoon; // the short wait before dimming, so a scroll can take the touch first
  Timer? _release;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(ClPressable old) {
    super.didUpdateWidget(old);
    if (!_enabled && _heldDown) _abort();
  }

  @override
  void deactivate() {
    // Leaving the tree mid-press (a route or tab change) must not keep the dim.
    _tapActive = false;
    _dimSoon?.cancel();
    _release?.cancel();
    _heldDown = false;
    _held.value = 0;
    super.deactivate();
  }

  @override
  void dispose() {
    _dimSoon?.cancel();
    _release?.cancel();
    _held.dispose();
    super.dispose();
  }

  // Like a UIKit control in a scroll view: the highlight waits a moment after touch down, a
  // scroll that takes the touch removes it at once (no lingering dim while scrolling), and a
  // tap always plays the whole highlight so it never flickers.

  void _press() {
    _tapActive = true;
    if (!_enabled || _heldDown) return;
    _heldDown = true;
    _release?.cancel();
    _dimSoon?.cancel();
    _dimSoon = Timer(_settle, _dim);
  }

  void _dim() {
    _dimSoon?.cancel();
    _dimmedAt = DateTime.now();
    if (context.reduceMotion) {
      _held.value = 1;
    } else {
      _held.animateTo(
        1,
        duration: _fadeOut,
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  /// The tap went through: finish the highlight, then fade back.
  void _complete() {
    _tapActive = false;
    _heldDown = false;
    if (_dimSoon?.isActive ?? false) _dim();
    final shown = DateTime.now().difference(_dimmedAt ?? DateTime.now());
    final wait = _fadeOut - shown;
    _release?.cancel();
    if (context.reduceMotion || wait <= Duration.zero) {
      _fadeBack();
    } else {
      _release = Timer(wait, _fadeBack);
    }
  }

  /// Scrolling took the touch, or the finger left the control: drop the highlight now.
  void _abort() {
    _tapActive = false;
    _heldDown = false;
    _dimSoon?.cancel();
    _release?.cancel();
    if (_held.value == 0 && !_held.isAnimating) return;
    _fadeBack(duration: _abortFade);
  }

  void _moved(Offset global) {
    if (!_enabled || !_tapActive) return;
    final inside = _inside(global);
    if (inside && !_heldDown) {
      _heldDown = true;
      _dim(); // back over the control: show it at once
    } else if (!inside && _heldDown) {
      _abort();
      _tapActive =
          true; // still the same tap: coming back over the control re-dims it
    }
  }

  void _fadeBack({Duration duration = _fadeIn}) {
    if (!mounted || _heldDown) return;
    if (context.reduceMotion) {
      _held.value = 0;
    } else {
      _held.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
    }
  }

  bool _inside(Offset global) {
    final box = context.findRenderObject()! as RenderBox;
    return box.paintBounds
        .inflate(CupertinoButton.tapMoveSlop())
        .contains(box.globalToLocal(global));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final opacity = Tween<double>(
      begin: 1,
      end: widget.pressedOpacity,
    ).animate(_held);
    return Semantics(
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(postAcceptSlopTolerance: null),
                // Always listening, so a disabled control still takes the tap instead of
                // letting it reach the row underneath.
                (tap) {
                  tap
                    ..onTapDown = ((_) => _press())
                    ..onTapMove = ((d) => _moved(d.globalPosition))
                    ..onTapCancel = _abort
                    ..onTapUp = (d) {
                      final inside = _inside(d.globalPosition);
                      if (!enabled || !inside) {
                        _abort();
                        return;
                      }
                      _complete();
                      widget.onPressed!();
                    };
                },
              ),
          if (widget.onLongPress != null)
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  LongPressGestureRecognizer.new,
                  (press) => press.onLongPress = widget.onLongPress,
                ),
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize.width,
            minHeight: widget.minSize.height,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : ClMotion.disabledOpacity,
              duration: context.motion(ClMotion.instant),
              child: FadeTransition(opacity: opacity, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
