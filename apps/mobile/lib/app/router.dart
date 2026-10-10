import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.g.dart';
import '../features/appearance/appearance_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/care/care_models.dart';
import '../features/care/care_screens.dart';
import '../features/care/timer_models.dart';
import '../features/care/timer_screens.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/family/family_models.dart';
import '../features/family/family_screen.dart';
import '../features/family/invite_screens.dart';
import '../features/family/join_screens.dart';
import '../features/family/save_account.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/setup_screens.dart';
import '../features/onboarding/welcome_screens.dart';
import '../features/showcase/showcase_screen.dart';
import '../features/today/today_screen.dart';
import 'route_guard.dart';
import 'session.dart';

GuardState guardStateOf(
  Session session,
  Set<String> verifyDeferred, {
  bool merging = false,
}) => switch (session) {
  SessionLoading() => GuardState.loading,
  SessionSignedOut() => GuardState.signedOut,
  SessionSignedIn(hasBaby: true) => GuardState.ready,
  SessionSignedIn() when merging => GuardState.loading,
  SessionSignedIn(isAnonymous: true) => GuardState.joining,
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
    ..listen(lostAccessBabyIdProvider, (_, _) => refresh.value++)
    ..listen(accountMergeInProgressProvider, (_, _) => refresh.value++)
    ..listen(addingBabyProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  // go_router rebuilds pushed pages without their `extra` when it refreshes (e.g. the session
  // changes after "Vào ngay"), so flow arguments are remembered per location.
  final lastArgs = <String, Object>{};
  T? argsOf<T extends Object>(GoRouterState s) {
    final extra = s.extra;
    if (extra is T) return lastArgs[s.matchedLocation] = extra;
    final kept = lastArgs[s.matchedLocation];
    return kept is T ? kept : null;
  }

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => guardRoute(
      state: guardStateOf(
        ref.read(sessionProvider),
        ref.read(verifyDeferredProvider),
        merging: ref.read(accountMergeInProgressProvider),
      ),
      location: state.uri.toString(),
      splashDone: ref.read(splashDoneProvider),
      lostAccess: ref.read(lostAccessBabyIdProvider) != null,
      addingBaby: ref.read(addingBabyProvider),
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
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fade(state, HomeShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.memories,
                builder: (_, _) => const MemoriesPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.family,
                builder: (_, _) => const FamilyScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.growth,
        builder: (_, s) => GrowthScreen(edit: s.extra as CareRecord?),
      ),
      GoRoute(
        path: '${Routes.timer}/:type',
        builder: (_, s) => TimerScreen(
          type:
              TimerType.values.asNameMap()[s.pathParameters['type']] ??
              TimerType.sleep,
        ),
      ),
      GoRoute(
        path: Routes.manualSleep,
        builder: (_, s) => ManualSleepScreen(edit: s.extra as CareRecord?),
      ),
      GoRoute(
        path: '${Routes.overlap}/:id',
        builder: (_, s) =>
            OverlapScreen(conflictId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.record}/:id',
        builder: (_, s) =>
            RecordDetailScreen(recordId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: Routes.invite, builder: (_, _) => const InviteRoleScreen()),
      GoRoute(
        path: Routes.inviteSend,
        redirect: (_, s) =>
            argsOf<InviteSendArgs>(s) == null ? Routes.family : null,
        builder: (_, s) => InviteSendScreen(args: argsOf<InviteSendArgs>(s)!),
      ),
      GoRoute(
        path: Routes.inviteSent,
        redirect: (_, s) =>
            argsOf<InviteSendArgs>(s) == null ? Routes.family : null,
        builder: (_, s) => InviteSentScreen(args: argsOf<InviteSendArgs>(s)!),
      ),
      GoRoute(path: Routes.join, builder: (_, _) => const EnterCodeScreen()),
      GoRoute(
        path: Routes.joinScan,
        builder: (_, _) => const ScanInviteScreen(),
      ),
      GoRoute(
        path: Routes.joinInvite,
        redirect: (_, s) => argsOf<JoinArgs>(s) == null ? Routes.join : null,
        builder: (_, s) {
          final args = argsOf<JoinArgs>(s)!;
          return AcceptInviteScreen(lookup: args.lookup, preview: args.preview);
        },
      ),
      GoRoute(
        path: Routes.joinConfirm,
        redirect: (_, s) => argsOf<JoinArgs>(s) == null ? Routes.join : null,
        builder: (_, s) => ConfirmJoinScreen(args: argsOf<JoinArgs>(s)!),
      ),
      GoRoute(
        path: Routes.joinClosed,
        builder: (_, s) => InviteClosedScreen(
          reason:
              InviteClosedReason.values
                  .asNameMap()[s.uri.queryParameters['reason']] ??
              InviteClosedReason.notFound,
        ),
      ),
      // App Links / universal links from QR codes, emails and messages (plan §3.5).
      GoRoute(
        path: '${Routes.inviteLink}/:token',
        builder: (_, s) => AcceptInviteScreen(
          lookup: InviteLookup.token(s.pathParameters['token'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.saveAccountEmail,
        builder: (_, _) => const SaveAccountEmailScreen(),
      ),
      GoRoute(
        path: Routes.lostAccess,
        pageBuilder: (_, s) => _fade(s, const LostAccessScreen()),
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
