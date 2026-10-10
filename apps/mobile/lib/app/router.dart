import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.g.dart';
import '../features/appearance/appearance_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/onboarding/setup_screens.dart';
import '../features/onboarding/welcome_screens.dart';
import '../features/showcase/showcase_screen.dart';
import '../features/today/today_screen.dart';
import 'route_guard.dart';
import 'session.dart';

GuardState guardStateOf(Session session, Set<String> verifyDeferred) =>
    switch (session) {
      SessionLoading() => GuardState.loading,
      SessionSignedOut() => GuardState.signedOut,
      SessionSignedIn(hasBaby: true) => GuardState.ready,
      SessionSignedIn(:final user) && final s
          when s.emailUnverified && !verifyDeferred.contains(user.uid) =>
        GuardState.needsVerifyPrompt,
      SessionSignedIn() => GuardState.needsSetup,
    };

/// Splash → Welcome and → Today crossfade (36:2233 "then crossfade"); other screens use the
/// platform default transition (D-013).
Page<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: ClMotion.standard,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(splashDoneProvider, (_, _) => refresh.value++)
    ..listen(verifyDeferredProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => guardRoute(
      state: guardStateOf(
        ref.read(sessionProvider),
        ref.read(verifyDeferredProvider),
      ),
      location: state.uri.toString(),
      splashDone: ref.read(splashDoneProvider),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (_, s) => _fade(s, const WelcomeScreen()),
      ),
      GoRoute(path: Routes.tour, builder: (_, _) => const TourScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.email, builder: (_, _) => const EmailScreen()),
      GoRoute(
        path: Routes.forgot,
        builder: (_, s) => ForgotPasswordScreen(
          initialEmail: s.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.exists,
        builder: (_, _) => const AccountExistsScreen(),
      ),
      GoRoute(
        path: Routes.verify,
        pageBuilder: (_, s) => _fade(s, const VerifyEmailScreen()),
      ),
      GoRoute(
        path: Routes.who,
        pageBuilder: (_, s) => _fade(s, const WhoAreYouScreen()),
      ),
      GoRoute(
        path: Routes.babyProfile,
        builder: (_, _) => const BabyProfileScreen(),
      ),
      GoRoute(path: Routes.trackers, builder: (_, _) => const TrackersScreen()),
      GoRoute(
        path: Routes.today,
        pageBuilder: (_, s) => _fade(s, const TodayScreen()),
      ),
      GoRoute(
        path: Routes.appearance,
        builder: (_, _) => const AppearanceScreen(),
      ),
      GoRoute(path: Routes.showcase, builder: (_, _) => const ShowcaseScreen()),
      GoRoute(
        path: Routes.diagnostics,
        builder: (_, _) => const DiagnosticsScreen(),
      ),
    ],
  );
});
