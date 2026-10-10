import 'dart:async';

import 'package:flutter/material.dart';

import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Toast with optional action (Motion spec "Lưu một lần ghi" 270:22): slides up 24px in
/// motion.quick, hides after 4 s with motion.exit. Reduce Motion: fades only. Night care: dark
/// toast without glow. Announced to screen readers.
OverlayEntry showClToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration visibleFor = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  // Read now: the caller's context may be gone (sheet closed, route replaced) when the
  // overlay rebuilds.
  final theme = Theme.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastHost(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      visibleFor: visibleFor,
      onDone: () => entry.remove(),
      theme: theme,
    ),
  );
  overlay.insert(entry);
  return entry;
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.visibleFor,
    required this.onDone,
    required this.theme,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration visibleFor;
  final VoidCallback onDone;
  final ThemeData theme;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _controller.duration = context.motion(ClMotion.quick);
    _controller.reverseDuration = context.motion(ClMotion.exit);
    _controller.forward();
    _timer = Timer(widget.visibleFor, _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.theme,
      child: Builder(
        builder: (context) {
          final cl = context.cl;
          final reduce = context.reduceMotion;
          final curved = CurvedAnimation(
            parent: _controller,
            curve: ClCurves.quick,
            reverseCurve: ClCurves.exit,
          );
          final bottom = MediaQuery.paddingOf(context).bottom + 96;
          Widget toast = Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s2,
              ClSpace.s2,
              ClSpace.s2,
            ),
            decoration: BoxDecoration(
              color: cl.isNightCare ? cl.colors.surface2 : cl.colors.ink,
              borderRadius: BorderRadius.circular(ClRadius.pill),
              boxShadow: cl.isNightCare ? null : cl.shadows.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClIcon(
                  ClIcons.check,
                  size: 18,
                  color: cl.isNightCare ? cl.colors.mintText : cl.colors.mint,
                ),
                const SizedBox(width: ClSpace.s2),
                Flexible(
                  child: Text(
                    widget.message,
                    style: cl.text.label.copyWith(
                      color: cl.isNightCare ? cl.colors.ink : cl.colors.surface,
                    ),
                  ),
                ),
                if (widget.actionLabel != null)
                  ClPressable(
                    onPressed: () {
                      widget.onAction?.call();
                      _hide();
                    },
                    semanticLabel: widget.actionLabel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClSpace.s3,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cl.isNightCare
                              ? cl.colors.mintText
                              : cl.colors.mint,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: ClSpace.s2),
              ],
            ),
          );
          toast = FadeTransition(opacity: curved, child: toast);
          if (!reduce) {
            toast = AnimatedBuilder(
              animation: curved,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, (1 - curved.value) * ClMotion.shiftToast),
                child: child,
              ),
              child: toast,
            );
          }
          return Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: bottom,
            // Without an action the toast is information only: taps reach the screen below
            // (it floats over the thumb-zone buttons).
            child: IgnorePointer(
              ignoring: widget.actionLabel == null,
              child: Semantics(
                liveRegion: true,
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: toast,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton loader (Motion spec "Đang tải dữ liệu" 271:393): content-shaped grey blocks with a
/// light sweep every 1.2 s. Static under Reduce Motion and in Night care.
class ClSkeleton extends StatefulWidget {
  const ClSkeleton({this.width, this.height = 16, this.radius = 14, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  State<ClSkeleton> createState() => _ClSkeletonState();
}

class _ClSkeletonState extends State<ClSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final animate =
        !context.reduceMotion &&
        !cl.isNightCare &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
    final base = cl.colors.surface2;
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (!animate) return ExcludeSemantics(child: box);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final x = -1 + 3 * _controller.value;
            return LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x, 0),
              colors: [base, cl.colors.surface.withValues(alpha: 0.9), base],
            ).createShader(rect);
          },
          child: child,
        ),
        child: box,
      ),
    );
  }
}
