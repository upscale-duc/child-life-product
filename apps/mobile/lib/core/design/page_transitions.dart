import 'package:flutter/material.dart';

/// Screen transitions are each platform's default (D-013): iOS push with swipe-back,
/// Android predictive back. With Reduce Motion the screen fades instead of sliding
/// (Motion spec "Chuyển màn hình": "Mờ dần 150ms, không trượt").
class ClPageTransitionsBuilder extends PageTransitionsBuilder {
  const ClPageTransitionsBuilder(this.platformDefault);

  final PageTransitionsBuilder platformDefault;

  // Routes read their timing and the outgoing screen's motion (iOS parallax) from the theme's
  // builder, so forward them; otherwise iOS pushes run 300 ms over a static screen.
  @override
  Duration get transitionDuration => platformDefault.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      platformDefault.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final delegated = platformDefault.delegatedTransition;
    if (delegated == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) =>
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? child
        : delegated(
            context,
            animation,
            secondaryAnimation,
            allowSnapshotting,
            child,
          );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }
    return platformDefault.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
