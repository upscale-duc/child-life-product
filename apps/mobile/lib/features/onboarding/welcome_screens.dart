import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'widgets/journey_hero.dart';
import 'widgets/onboarding_layout.dart';

/// 00 Splash: one splash only (owner, 2026-10-11, D-048). It draws exactly what the native
/// launch screen shows (flutter_native_splash.yaml: the 150 pt mark centred on cloud, Light or
/// Night by the system appearance), so the hand-over from iOS/Android to Flutter is invisible;
/// the router then crossfades to the next screen (≤ 1 s, R-006). No glow, wordmark or tagline,
/// which made it read as a second splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// The launch image's size in points (600 px source at 4x).
  static const markSize = 150.0;

  @override
  Widget build(BuildContext context) {
    // The native launch screen can only follow the system appearance, while the app's palette
    // also follows "Sáng"/"Tối", the Night care schedule and running timers; match the former.
    final palette = MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? ClPalette.nightCare
        : ClPalette.light;
    final cl = ClTheme.of(palette);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: clStatusBarStyle(palette),
      child: Theme(
        data: buildClTheme(palette),
        child: ColoredBox(
          color: cl.colors.cloud,
          // Centred on the whole screen, not the safe area, like the launch storyboard.
          child: const Center(child: ClLogo(height: markSize)),
        ),
      ),
    );
  }
}

/// 01 Chào mừng (v1.0 368:843; was 26:4): the growth journey, "Bắt đầu chặng đầu cùng con" → tour, Đăng nhập → 06, Mã mời → 15 (S3); moon = theme toggle.
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
        const JourneyHero(),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.welcomeTitle,
          style: cl.text.title.copyWith(color: cl.colors.ink),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.welcomeBody,
          style: cl.text.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cl.colors.inkMuted,
          ),
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
