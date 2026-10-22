import 'package:flutter/cupertino.dart';

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
    final cupertino = platformDefault is CupertinoPageTransitionsBuilder;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      Widget curved() => delegated(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
      )!;
      if (!cupertino) return curved();
      // A screen under a root-level page whose own route is not Cupertino (the shell's fade
      // page) slides by this delegated transition, which always eases. During an edge swipe
      // the drag runs it linearly; on release the controller reverses and the curve switches
      // mid-flight, so the shell jumped sideways. Follow the finger linearly while the gesture
      // (and its drop animation, which Flutter keeps "in progress") lasts, as Cupertino pages do.
      return ValueListenableBuilder<bool>(
        valueListenable: Navigator.of(context).userGestureInProgressNotifier,
        builder: (context, swiping, _) => swiping
            ? SlideTransition(
                position: secondaryAnimation.drive(_middleLeft),
                textDirection: Directionality.of(context),
                transformHitTests: false,
                child: child,
              )
            : curved(),
      );
    };
  }

  // Cupertino's parallax: the covered screen moves a third of its width to the start side.
  static final _middleLeft = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1.0 / 3.0, 0.0),
  );

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
