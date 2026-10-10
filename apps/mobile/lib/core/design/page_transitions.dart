import 'package:flutter/material.dart';

/// Screen transitions are each platform's default (D-013): iOS push with swipe-back,
/// Android predictive back. With Reduce Motion the screen fades instead of sliding
/// (Motion spec "Chuyển màn hình": "Mờ dần 150ms, không trượt").
class ClPageTransitionsBuilder extends PageTransitionsBuilder {
  const ClPageTransitionsBuilder(this.platformDefault);

  final PageTransitionsBuilder platformDefault;

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
