import 'package:flutter/material.dart';

/// PS11 → PS12/14, PS14/24 → PS30N, PS30N → PS33: prototype
/// SMART_ANIMATE / EASE_OUT / 300ms. Fullscreen book controls use 350ms.
/// No keyframe tracks were returned by Figma; these are prototype transitions.
abstract final class PrintMotion {
  static const screen = Duration(milliseconds: 300);
  static const fullscreen = Duration(milliseconds: 350);
  static const reduced = Duration(milliseconds: 150);
  static const curve = Curves.easeOut;
  static Duration duration(BuildContext context, {bool full = false}) =>
      MediaQuery.disableAnimationsOf(context)
      ? reduced
      : full
      ? fullscreen
      : screen;
  static AnimationStyle sheet(BuildContext context) => AnimationStyle(
    duration: duration(context),
    reverseDuration: duration(context),
  );
}

/// The wizard keeps one route, so its internal steps need their own transition.
/// Identity is a step/style, never form data: typing must not restart a transition.
class PrintFlowTransition extends StatelessWidget {
  const PrintFlowTransition({
    required this.identity,
    required this.child,
    super.key,
  });
  final Object identity;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: PrintMotion.duration(context),
    switchInCurve: PrintMotion.curve,
    switchOutCurve: PrintMotion.curve,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topLeft,
      children: [
        for (final old in previous)
          IgnorePointer(
            child: ExcludeFocus(child: ExcludeSemantics(child: old)),
          ),
        ?current,
      ],
    ),
    child: KeyedSubtree(key: ValueKey(identity), child: child),
  );
}

/// Preserve native push/back gestures (D-013), with PS21's 350ms timing.
class PrintBookRoute<T> extends MaterialPageRoute<T> {
  PrintBookRoute({required BuildContext context, required super.builder})
    : _duration = PrintMotion.duration(context, full: true);
  final Duration _duration;
  @override
  Duration get transitionDuration => _duration;
  @override
  Duration get reverseTransitionDuration => _duration;
}
