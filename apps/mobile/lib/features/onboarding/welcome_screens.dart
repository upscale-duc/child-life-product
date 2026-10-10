import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/heroes.dart';
import 'widgets/onboarding_layout.dart';

/// 00 Splash (36:2233): logo rises 8 px and fades in, then the router crossfades to the next
/// screen (≤ 1 s). Reduce Motion: static logo. The native launch screen is the same without glow.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ClMotion.standard,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FadeTransition(
                    opacity: curve,
                    child: AnimatedBuilder(
                      animation: curve,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, 8 * (1 - curve.value)),
                        child: child,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ClLogo(height: 104),
                          const SizedBox(height: ClSpace.s3),
                          SvgPicture.asset(
                            'assets/logo/wordmark-color.svg',
                            height: 46,
                            colorFilter: ColorFilter.mode(
                              cl.colors.ink,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s8),
              child: Text(
                AppLocalizations.of(context).splashTagline,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 01 Chào mừng (26:4): Khám phá → tour, Đăng nhập → 06, Mã mời → 15 (S3); moon = theme toggle.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return OnboardingScaffold(
      topBar: ClTopBar(
        brand: const ClLogo(kind: ClLogoKind.lockup, height: 28),
        trailing: ClPressable(
          semanticLabel: l10n.a11yToggleAppearance,
          onPressed: () => _toggleTheme(ref),
          child: Container(
            width: ClSpace.tapMin,
            height: ClSpace.tapMin,
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(ClIcons.sleep, size: 20, color: cl.colors.ink),
          ),
        ),
      ),
      content: [
        const WelcomeHero(),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.welcomeTitle,
          style: cl.text.title.copyWith(color: cl.colors.ink),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.welcomeExplore,
          onPressed: () => context.push(Routes.tour),
          expand: true,
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            Expanded(
              child: ClButton(
                label: l10n.welcomeSignIn,
                style: ClButtonStyle.secondary,
                onPressed: () => context.push(Routes.signIn),
                expand: true,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: ClButton(
                label: l10n.welcomeInviteCode,
                style: ClButtonStyle.secondary,
                // `go`, not `push`: routing re-checks the base location when the session
                // changes ("Vào ngay"), so the join flow must be the base, not Welcome.
                onPressed: () => context.go(Routes.join),
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Switches Light ↔ Night care immediately ("Áp dụng ngay cho cả app").
  void _toggleTheme(WidgetRef ref) {
    final controller = ref.read(appearanceSettingsProvider.notifier);
    final settings = ref.read(appearanceSettingsProvider);
    final nightNow = ref.read(paletteProvider) == ClPalette.nightCare;
    controller.update(
      settings.copyWith(
        theme: nightNow ? ThemePreference.light : ThemePreference.dark,
      ),
    );
  }
}

/// 02–05 feature tour (26:85…26:277): swipe or round Next, "Bỏ qua", last page "Tạo hồ sơ bé".
class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == 3) return _finish();
    // Reduce Motion: change page without sliding (Motion spec "Chuyển màn hình").
    if (context.reduceMotion) {
      _pages.jumpToPage(_index + 1);
    } else {
      _pages.nextPage(duration: ClMotion.standard, curve: ClCurves.quick);
    }
  }

  /// Both "Bỏ qua" and "Tạo hồ sơ bé" lead to sign-in: a profile needs an account (flow 1).
  void _finish() => context.push(Routes.signIn);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pages = [
      (const TourCareHero(), l10n.tourCareTitle, l10n.tourCareBody),
      (const TourShareHero(), l10n.tourShareTitle, l10n.tourShareBody),
      (const TourStoryHero(), l10n.tourStoryTitle, l10n.tourStoryBody),
      (const TourPrivateHero(), l10n.tourPrivateTitle, l10n.tourPrivateBody),
    ];
    final last = _index == pages.length - 1;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(onSkip: last ? null : _finish),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (hero, title, body) = pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      ClSpace.s4,
                      ClSpace.s4,
                      ClSpace.s4,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        hero,
                        const SizedBox(height: ClSpace.s6),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: cl.text.title.copyWith(color: cl.colors.ink),
                          ),
                        ),
                        const SizedBox(height: ClSpace.s2),
                        Text(
                          body,
                          style: cl.text.body.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                ClSpace.s4,
              ),
              child: SizedBox(
                height: ClSpace.nextButton,
                child: Row(
                  children: [
                    ClPageDots(count: pages.length, index: _index),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: context.motion(ClMotion.quick),
                      child: last
                          ? ClButton(
                              key: const ValueKey('create'),
                              label: l10n.tourCreateProfile,
                              onPressed: _finish,
                            )
                          : ClRoundButton(
                              key: const ValueKey('next'),
                              semanticLabel: l10n.a11yNext,
                              icon: ClIcons.arrowRight,
                              onPressed: _next,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
