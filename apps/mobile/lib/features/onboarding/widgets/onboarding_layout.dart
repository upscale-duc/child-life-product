import 'package:flutter/material.dart';

import '../../../core/design/cl_theme.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/widgets/cl_art.dart';

/// Page frame for onboarding, auth and setup screens: top bar, scrollable content and the
/// primary action pinned in the thumb zone (Button 8:33 "one per screen in the thumb zone").
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.content,
    this.topBar,
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: ClSpace.s4),
    super.key,
  });

  final Widget? topBar;
  final List<Widget> content;
  final List<Widget>? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cl.colors.cloud,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (topBar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  0,
                ),
                child: topBar,
              ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding.copyWith(top: ClSpace.s4, bottom: ClSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  ClSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: bottom!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Screen title + optional subtitle as drawn on 07, 10a, 12 ("Theo dõi gì?").
class ScreenHeading extends StatelessWidget {
  const ScreenHeading({
    required this.title,
    this.subtitle,
    this.large = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: (large ? cl.text.largeTitle : cl.text.title).copyWith(
              color: cl.colors.ink,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: ClSpace.s1),
          Text(
            subtitle!,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ],
    );
  }
}

/// A Figma hero card: card colour + exported artwork + live overlays positioned in the
/// artboard's own coordinates, scaled as a whole to the available width.
class HeroArt extends StatelessWidget {
  const HeroArt({
    required this.illustration,
    required this.size,
    required this.color,
    this.overlays = const [],
    this.radius = ClRadius.hero,
    super.key,
  });

  final ClIllustration illustration;
  final Size size;
  final Color color;
  final List<Widget> overlays;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: color,
          child: FittedBox(
            child: SizedBox.fromSize(
              size: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClArt(illustration, width: size.width, height: size.height),
                  ...overlays,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pops a hero chip in once (scale 0.92 → 1, fade) with the Motion spec stagger of 30 ms per
/// item; static with Reduce Motion.
class PopIn extends StatefulWidget {
  const PopIn({
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 180),
    super.key,
  });

  final Widget child;
  final int index;
  final Duration baseDelay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ClMotion.gentle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      final delay =
          widget.baseDelay +
          Duration(milliseconds: 30 * widget.index.clamp(0, 5));
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: ClCurves.gentle);
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(curve),
        child: widget.child,
      ),
    );
  }
}
