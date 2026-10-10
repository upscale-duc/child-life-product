import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/haptics.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_feedback.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Presents a bottom sheet per the Motion spec pattern "Mở và đóng sheet" (270:108):
/// opens with motion.standard (spring, ≤4px settle) while the scrim fades 0 → 32 %, closes with
/// motion.exit; drag past 30 % or flick to close (light haptic); otherwise springs back.
/// Night care: no bounce, 250 ms ease-out. Reduce Motion: 150 ms fade, no slide. No haptic on open.
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
  });

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
    final scrimColor = ClTheme.of(
      nightCare ? ClPalette.nightCare : ClPalette.light,
    ).colors.scrim;
    final curved = CurvedAnimation(
      parent: animation,
      curve: nightCare ? ClCurves.quick : ClCurves.standard,
      reverseCurve: ClCurves.exit,
    );
    final sheet = reduceMotion
        ? FadeTransition(opacity: animation, child: child)
        : SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
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
        Align(alignment: Alignment.bottomCenter, child: sheet),
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

class _SheetBodyState extends State<_SheetBody>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _drag = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
  );

  double get _height => _key.currentContext?.size?.height ?? 1;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!widget.route.dismissible) return;
    _drag.value = (_drag.value + d.primaryDelta! / _height).clamp(0, 1);
  }

  void _onEnd(DragEndDetails d) {
    if (!widget.route.dismissible) return;
    final flick = d.primaryVelocity != null && d.primaryVelocity! > 700;
    if (flick || _drag.value > 0.3) {
      ClHaptics.tap(context);
      Navigator.of(context).pop();
    } else {
      _drag.animateBack(
        0,
        duration: context.motion(ClMotion.quick),
        curve: ClCurves.quick,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final media = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: _drag,
      builder: (context, child) => FractionalTranslation(
        translation: Offset(0, _drag.value),
        child: child,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: media.viewInsets.bottom,
          top: media.padding.top + ClSpace.s6,
        ),
        child: GestureDetector(
          onVerticalDragUpdate: _onUpdate,
          onVerticalDragEnd: _onEnd,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              key: _key,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ClRadius.sheet),
                ),
                boxShadow: cl.shadows.sheet,
              ),
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                ClSpace.s6 + media.padding.bottom,
              ),
              child: SafeArea(top: false, bottom: false, child: widget.child),
            ),
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
