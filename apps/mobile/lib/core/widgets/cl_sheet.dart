import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_feedback.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Presents a bottom sheet per the Motion spec pattern "Mở và đóng sheet" (270:108):
/// opens with motion.standard (spring, ≤4px settle) while the scrim fades 0 → 32 %, closes with
/// motion.exit; drag past 30 % or flick to close (light haptic); otherwise springs back.
/// Night care: no bounce, 250 ms ease-out. Reduce Motion: 150 ms fade, no slide. A medium haptic on
/// open (D-048).
Future<T?> showClSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  final theme = Theme.of(context);
  dismissClToasts();
  // Above everything, the tab dock included (19a, 22: the sheet covers the dock).
  return Navigator.of(context, rootNavigator: true).push<T>(
    ClSheetRoute<T>(
      builder: builder,
      dismissible: dismissible,
      nightCare: context.cl.isNightCare,
      reduceMotion: context.reduceMotion,
      theme: theme,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

class ClSheetRoute<T> extends PopupRoute<T> {
  ClSheetRoute({
    required this.builder,
    required this.dismissible,
    required this.nightCare,
    required this.reduceMotion,
    required this.theme,
    required this.barrierLabel,
    this.customSurface = false,
    this.scrimColor,
  });

  /// The child owns its surface and safe-area padding (for branded sheets).
  /// Motion, scrim, drag-to-dismiss and keyboard avoidance remain shared.
  final bool customSurface;

  /// Optional branded scrim; drag and transitions still animate its opacity.
  final Color? scrimColor;
  final WidgetBuilder builder;
  final bool dismissible;
  final bool nightCare;
  final bool reduceMotion;
  final ThemeData theme;

  @override
  final String? barrierLabel;

  @override
  bool get barrierDismissible => dismissible;

  /// The scrim is drawn by [buildTransitions] so it can follow the sheet's drag.
  @override
  Color? get barrierColor => null;

  @override
  Duration get transitionDuration => reduceMotion
      ? const Duration(milliseconds: 150)
      : nightCare
      ? const Duration(milliseconds: 250)
      : ClMotion.standard;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? const Duration(milliseconds: 150) : ClMotion.exit;

  // The route's own controller is the sheet's position (1 = open, 0 = off screen): the open
  // spring, the finger, the release and the close all drive it, so the scrim always tracks the
  // sheet and a flick carries its speed into the close instead of restarting a curve.
  final ValueNotifier<bool> _dragged = ValueNotifier(false);
  double? _releaseVelocity;

  @override
  TickerFuture didPush() {
    super.didPush();
    final c = controller!;
    if (reduceMotion || nightCare) {
      return c.animateTo(
        1,
        duration: transitionDuration,
        curve: reduceMotion ? Curves.linear : ClCurves.quick,
      );
    }
    return c.animateWith(
      SpringSimulation(standardSpring(), c.value, 1, 0, snapToEnd: true),
    );
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    final c = controller!;
    final velocity = _releaseVelocity;
    // Already off screen (dragged all the way down): super's reverse has finished the route.
    if (c.isDismissed) return popped;
    if (velocity != null) {
      // Closed by a drag: keep the finger's speed (Motion spec 270:108 step 4).
      c.fling(velocity: math.min(velocity, -2));
    } else {
      c.animateBack(
        0,
        duration: reverseTransitionDuration * c.value,
        curve: reduceMotion ? Curves.linear : ClCurves.exit,
      );
    }
    return popped;
  }

  @override
  void dispose() {
    _dragged.dispose();
    super.dispose();
  }

  void _dragUpdate(double delta, double height) {
    _dragged.value = true;
    controller!.value -= delta / height;
  }

  /// Past 30 % or a fast flick closes (light haptic); otherwise springs back with the
  /// finger's velocity. Returns whether the sheet is closing.
  bool _dragEnd(double velocity, double height) {
    final c = controller!;
    final v = -velocity / height; // sheet units per second, + = opening
    if (velocity > 700 || c.value < 0.7) {
      _releaseVelocity = v;
      return true;
    }
    final spring = nightCare || reduceMotion
        ? SpringDescription.withDampingRatio(mass: 1, stiffness: 500, ratio: 1)
        : standardSpring();
    c
        .animateWith(SpringSimulation(spring, c.value, 1, v, snapToEnd: true))
        .whenCompleteOrCancel(() {
          // Back in place: Reduce Motion closes with a fade again.
          if (isActive) _dragged.value = false;
        });
    return false;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Theme(
    data: theme,
    child: _SheetBody(
      route: this,
      child: Builder(builder: builder),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scrimColor =
        this.scrimColor ??
        ClTheme.of(
          nightCare ? ClPalette.nightCare : ClPalette.light,
        ).colors.scrim;
    final slide = SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: animation,
              child: ColoredBox(color: scrimColor),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          // Reduce Motion: open and close fade without sliding; a drag still moves the sheet.
          child: reduceMotion
              ? ValueListenableBuilder(
                  valueListenable: _dragged,
                  child: child,
                  builder: (_, dragged, child) => dragged
                      ? slide
                      : FadeTransition(opacity: animation, child: child),
                )
              : slide,
        ),
      ],
    );
  }
}

/// Sheet surface with drag-to-dismiss (30 % threshold or a fast flick).
class _SheetBody extends StatefulWidget {
  const _SheetBody({required this.route, required this.child});

  final ClSheetRoute<dynamic> route;
  final Widget child;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  final _key = GlobalKey();

  double get _height => _key.currentContext?.size?.height ?? 1;

  bool get _canDrag => widget.route.dismissible && widget.route.isCurrent;

  void _onUpdate(DragUpdateDetails d) {
    if (!_canDrag) return;
    widget.route._dragUpdate(d.primaryDelta!, _height);
  }

  void _onEnd(DragEndDetails d) {
    if (!_canDrag) return;
    if (widget.route._dragEnd(d.primaryVelocity ?? 0, _height)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final padding = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        top: padding.top + ClSpace.s6,
      ),
      child: GestureDetector(
        onVerticalDragUpdate: _onUpdate,
        onVerticalDragEnd: _onEnd,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            key: _key,
            width: double.infinity,
            decoration: widget.route.customSurface
                ? null
                : BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ClRadius.sheet),
                    ),
                    boxShadow: cl.shadows.sheet,
                  ),
            padding: widget.route.customSurface
                ? EdgeInsets.zero
                : EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s2,
                    ClSpace.s4,
                    ClSpace.s6 + padding.bottom,
                  ),
            child: SafeArea(top: false, bottom: false, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Sheet header (37:293): grabber, 24/32 title, 44px close labelled "Đóng".
class ClSheetHeader extends StatelessWidget {
  const ClSheetHeader({
    required this.title,
    this.titleColor,
    this.onClose,
    super.key,
  });

  final String title;
  final Color? titleColor;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: cl.colors.separator,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: cl.text.title2.copyWith(color: titleColor),
                ),
              ),
            ),
            ClPressable(
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              semanticLabel: AppLocalizations.of(context).a11yClose,
              child: ClIcon(ClIcons.close, color: cl.colors.ink),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}
