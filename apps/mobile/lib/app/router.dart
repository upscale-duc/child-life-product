import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.g.dart';
import '../features/keepsakes/keepsake_occasions.dart';
import '../features/keepsakes/memory_story_screens.dart';
import '../features/keepsakes/milestone_card_screens.dart';
import '../features/appearance/appearance_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/email_link.dart';
import '../features/auto_save/auto_save_home.dart';
import '../features/auto_save/auto_save_review.dart';
import '../features/auto_save/auto_save_setup.dart';
import '../features/care/care_models.dart';
import '../features/care/care_hub_screen.dart';
import '../features/care/care_screens.dart';
import '../features/care/history_screen.dart';
import '../features/care/stats_screens.dart';
import '../features/care/timer_models.dart';
import '../features/care/timer_screens.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/family/family_models.dart';
import '../features/family/family_screen.dart';
import '../features/family/invite_screens.dart';
import '../features/family/invite_link_join.dart';
import '../features/family/join_screens.dart';
import '../features/family/save_account.dart';
import '../features/home/home_shell.dart';
import '../features/memories/album_screens.dart';
import '../features/memories/memories_screen.dart';
import '../features/memories/messages_screen.dart';
import '../features/stories/share_screens.dart';
import '../features/stories/story_editor.dart';
import '../features/stories/story_models.dart';
import '../features/stories/story_reader.dart';
import '../features/me/account_screen.dart';
import '../features/me/baby_profile_screens.dart';
import '../features/me/help_screen.dart';
import '../features/me/me_screen.dart';
import '../features/me/notifications_screen.dart';
import '../features/premium/plan_screen.dart';
import '../features/rhythm/rhythm_routes.dart';
import '../features/me/profile_screen.dart';
import '../features/me/storage_screens.dart';
import '../features/reminders/reminder_screens.dart';
import '../features/reminders/rule_screens.dart';
import '../features/feedback/feedback_repository.dart';
import '../features/feedback/feedback_screens.dart';
import '../features/first_aid/first_aid_screens.dart';
import '../features/utilities/utilities_screen.dart';
import '../features/vaccines/vaccine_screens.dart';
import '../features/onboarding/setup_screens.dart';
import '../features/onboarding/welcome_screens.dart';
import '../features/showcase/showcase_screen.dart';
import '../features/spending/import/import_screens.dart';
import '../features/spending/spending_categories.dart';
import '../features/spending/spending_plan_screens.dart';
import '../features/spending/spending_screens.dart';
import '../features/spending/spending_stats.dart';
import '../features/today/today_screen.dart';
import 'route_guard.dart';
import 'providers.dart';
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

/// Every other screen: an explicit [MaterialPage], so iOS gets the Cupertino slide and edge
/// swipe-back and Android its predictive back (D-013). go_router's own fallback looks for
/// `material_ui`'s MaterialApp, misses ours (`package:flutter/material.dart`) and would hand out
/// a NoTransitionPage instead.
GoRoute _route({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  GoRouterRedirect? redirect,
  List<RouteBase> routes = const [],

  /// Slides up with a close button instead of Back (FB2 Góp ý).
  bool modal = false,
}) => GoRoute(
  path: path,
  redirect: redirect,
  routes: routes,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    fullscreenDialog: modal,
    name: state.name ?? state.path,
    arguments: {...state.pathParameters, ...state.uri.queryParameters},
    restorationId: state.pageKey.value,
    child: builder(context, state),
  ),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, session) {
      // A real account (not a "Vào ngay" identity) marks the device as returning (P-128).
      if (session case SessionSignedIn(isAnonymous: false)) {
        ref.read(signedInBeforeProvider.notifier).mark();
      }
      refresh.value++;
    })
    ..listen(splashDoneProvider, (_, _) => refresh.value++)
    ..listen(verifyDeferredProvider, (_, _) => refresh.value++)
    ..listen(lostAccessBabyIdProvider, (_, _) => refresh.value++)
    ..listen(accountMergeInProgressProvider, (_, _) => refresh.value++)
    ..listen(addingBabyProvider, (_, _) => refresh.value++)
    ..listen(signedInBeforeProvider, (_, _) => refresh.value++)
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

  InviteLookup? lookupOf(GoRouterState s) =>
      JoinArgs.lookupOf(s.uri.queryParameters);
  // 16 / 16a: the pushed arguments, else the invite in the location with its preview seen in
  // this run.
  JoinArgs? joinArgsOf(GoRouterState s) {
    final args = argsOf<JoinArgs>(s);
    if (args != null) return args;
    final lookup = lookupOf(s);
    final preview = lookup == null ? null : JoinArgs.previewOf(lookup);
    return lookup == null || preview == null
        ? null
        : JoinArgs(lookup: lookup, preview: preview);
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
      location: appLocation(state.uri),
      splashDone: ref.read(splashDoneProvider),
      lostAccess: ref.read(lostAccessBabyIdProvider) != null,
      addingBaby: ref.read(addingBabyProvider),
      returning: ref.read(signedInBeforeProvider),
    ),
    routes: [
      _route(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (_, s) => _fade(s, const WelcomeScreen()),
      ),
      _route(path: Routes.tour, builder: (_, _) => const TourScreen()),
      _route(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.welcomeBack,
        pageBuilder: (_, s) => _fade(s, const SignInScreen(returning: true)),
      ),
      _route(
        path: Routes.email,
        builder: (_, s) => EmailScreen(
          mode: EmailMode.values.asNameMap()[s.uri.queryParameters['mode']],
        ),
      ),
      _route(
        path: Routes.emailLinkSent,
        builder: (_, s) =>
            EmailLinkSentScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),
      // The sign-in link from 07b's email, opened as a Universal / App Link (D-064). Rebuilt on
      // the website's origin, which is what Firebase reads it from.
      _route(
        path: Routes.emailLink,
        builder: (_, s) => EmailLinkScreen(
          link: Uri.parse(
            ref.read(environmentProvider).webOrigin,
          ).replace(path: '${Routes.emailLink}/', query: s.uri.query),
        ),
      ),
      _route(
        path: Routes.forgot,
        builder: (_, s) => ForgotPasswordScreen(
          initialEmail: s.uri.queryParameters['email'] ?? '',
        ),
      ),
      _route(
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
      _route(
        path: Routes.babyProfile,
        builder: (_, _) => const BabyProfileScreen(),
      ),
      _route(path: Routes.trackers, builder: (_, _) => const TrackersScreen()),
      _route(path: Routes.messages, builder: (_, _) => const MessagesScreen()),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fade(state, HomeShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              _route(
                path: Routes.today,
                builder: (_, _) => const TodayScreen(),
                // Before v1.0.1 these lived under Hôm nay; links already handed out (scheduled
                // reminder notifications, widgets) still arrive here.
                routes: [
                  for (final (old, now) in const [
                    ('history', Routes.history),
                    ('stats/feed', Routes.feedStats),
                    ('stats/sleep', Routes.sleepStats),
                    ('reminders', Routes.reminders),
                  ])
                    GoRoute(
                      path: old,
                      redirect: (_, s) => Uri(
                        path: now,
                        queryParameters: s.uri.queryParameters.isEmpty
                            ? null
                            : s.uri.queryParameters,
                      ).toString(),
                    ),
                  GoRoute(
                    path: 'reminders/:id',
                    redirect: (_, s) =>
                        '${Routes.reminders}/${s.pathParameters['id']}',
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                path: Routes.memories,
                builder: (_, _) => const MemoriesScreen(),
                // S10: album, favourites and milestone pages (10e, 11f); like every screen opened
                // from a tab, they hide the dock (owner, 2026-10-11).
                routes: [
                  _route(
                    path: 'album/:key',
                    builder: (_, s) => AlbumDetailScreen(
                      albumKey: s.pathParameters['key'] ?? '',
                    ),
                  ),
                  // Thiệp cột mốc (D-068, MM10 – MM12).
                  _route(
                    path: 'card',
                    builder: (_, s) => KeepsakeKindsScreen(
                      video: false,
                      occasion: Occasion.fromWire(
                        s.uri.queryParameters['occasion'],
                      ),
                      // Photos chosen in Kỷ niệm ("Tạo thiệp cột mốc" on a selection).
                      photoIds: s.extra is List<String>
                          ? s.extra! as List<String>
                          : null,
                    ),
                    routes: [
                      _route(
                        path: 'preview',
                        redirect: (_, s) => argsOf<CardPreviewArgs>(s) == null
                            ? Routes.milestoneCard
                            : null,
                        builder: (_, s) => CardTemplatePreviewScreen(
                          args: argsOf<CardPreviewArgs>(s)!,
                        ),
                      ),
                      _route(
                        path: 'edit',
                        // argsOf: go_router rebuilds pushed pages without `extra` when it
                        // refreshes; a null draft crashed (owner, 2026-10-14).
                        redirect: (_, s) => argsOf<CardDraft>(s) == null
                            ? Routes.milestoneCard
                            : null,
                        builder: (_, s) => MilestoneCardEditScreen(
                          draft: argsOf<CardDraft>(s)!,
                        ),
                      ),
                      _route(
                        path: 'done',
                        redirect: (_, s) => argsOf<CardResult>(s) == null
                            ? Routes.memories
                            : null,
                        builder: (_, s) => MilestoneCardDoneScreen(
                          result: argsOf<CardResult>(s)!,
                        ),
                      ),
                    ],
                  ),
                  // Video kỷ niệm (D-068, MM04 – MM09, MM13, MM14).
                  _route(
                    path: 'video',
                    builder: (_, s) => KeepsakeKindsScreen(
                      video: true,
                      occasion: Occasion.fromWire(
                        s.uri.queryParameters['occasion'],
                      ),
                      // Photos chosen in Kỷ niệm ("Tạo video kỷ niệm" on a selection).
                      photoIds: s.extra is List<String>
                          ? s.extra! as List<String>
                          : null,
                    ),
                    routes: [
                      _route(
                        path: 'photos',
                        redirect: (_, s) => argsOf<VideoDraft>(s) == null
                            ? Routes.memoryStory
                            : null,
                        builder: (_, s) => MemoryStoryPhotosScreen(
                          draft: argsOf<VideoDraft>(s)!,
                        ),
                      ),
                      _route(
                        path: 'finish',
                        redirect: (_, s) => argsOf<VideoDraft>(s) == null
                            ? Routes.memoryStory
                            : null,
                        builder: (_, s) => MemoryStoryFinishScreen(
                          draft: argsOf<VideoDraft>(s)!,
                        ),
                      ),
                      _route(
                        path: 'job/:jobId',
                        builder: (_, s) => MemoryStoryJobScreen(
                          babyId: s.uri.queryParameters['baby'] ?? '',
                          jobId: s.pathParameters['jobId'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  // Tự lưu kỷ niệm (D-066, AS02 – AS19).
                  _route(
                    path: 'auto-save',
                    builder: (_, _) => const AutoSaveHomeScreen(),
                    routes: [
                      _route(
                        path: 'setup',
                        builder: (_, _) => const AutoSaveSetupScreen(),
                      ),
                      _route(
                        path: 'review',
                        builder: (_, _) => const AutoSaveReviewScreen(),
                        routes: [
                          _route(
                            path: 'confirm',
                            redirect: (_, s) =>
                                argsOf<AutoSaveDecision>(s) == null
                                ? Routes.autoSaveReview
                                : null,
                            builder: (_, s) => AutoSaveConfirmScreen(
                              decision: argsOf<AutoSaveDecision>(s)!,
                            ),
                          ),
                        ],
                      ),
                      _route(
                        path: 'settings',
                        builder: (_, _) => const AutoSaveSettingsScreen(),
                      ),
                      _route(
                        path: 'samples/:babyId',
                        builder: (_, s) => AutoSaveSamplesScreen(
                          babyId: s.pathParameters['babyId'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // v1.0 improvement: Chăm sóc (370:1971) holds reminders, stats, history and growth.
          StatefulShellBranch(
            routes: [
              _route(
                path: Routes.care,
                builder: (_, _) => const CareHubScreen(),
                routes: [
                  _route(
                    path: 'history',
                    builder: (_, s) => HistoryScreen(
                      filter:
                          HistoryFilter.values
                              .asNameMap()[s.uri.queryParameters['filter']] ??
                          HistoryFilter.all,
                    ),
                  ),
                  _route(
                    path: 'stats/feed',
                    builder: (_, _) => const FeedStatsScreen(),
                  ),
                  _route(
                    path: 'stats/sleep',
                    builder: (_, _) => const SleepStatsScreen(),
                  ),
                  // Sổ tiêm chủng (VX 0 – VX 9a).
                  _route(
                    path: 'vaccines',
                    builder: (_, _) => const VaccineBookScreen(),
                    routes: [
                      _route(
                        path: 'setup',
                        builder: (_, _) => const VaccineSetupScreen(),
                      ),
                      _route(
                        path: 'age/:months',
                        builder: (_, s) => VaccineMilestoneScreen(
                          months:
                              int.tryParse(s.pathParameters['months'] ?? '') ??
                              0,
                        ),
                      ),
                      _route(
                        path: 'dose/:key',
                        builder: (_, s) => VaccineDoseScreen(
                          doseKey: s.pathParameters['key'] ?? '',
                        ),
                      ),
                      _route(
                        path: 'info/:id',
                        builder: (_, s) => VaccineInfoScreen(
                          vaccineId: s.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  // S7 reminders (8a–8e, 12f).
                  _route(
                    path: 'reminders',
                    builder: (_, _) => const RemindersScreen(),
                    routes: [
                      // v1.0 rule reminders (1b–1h), before the one-time ':id'.
                      _route(
                        path: 'rules/new',
                        builder: (_, _) => const RuleEditorScreen(),
                      ),
                      _route(
                        path: 'rules/:ruleId',
                        builder: (_, s) => RuleDetailScreen(
                          ruleId: s.pathParameters['ruleId'] ?? '',
                        ),
                        routes: [
                          _route(
                            path: 'edit',
                            builder: (_, s) => RuleEditorScreen(
                              ruleId: s.pathParameters['ruleId'],
                            ),
                          ),
                        ],
                      ),
                      _route(
                        path: ':id',
                        builder: (_, s) => ReminderDetailScreen(
                          reminderId: s.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tiện ích (v1.0 improvement 450:6597) replaces the Gia đình tab: Sơ cứu, Chi tiêu and
          // Gia đình (members, invites) open from here.
          StatefulShellBranch(
            routes: [
              _route(
                path: Routes.utilities,
                builder: (_, _) => const UtilitiesScreen(),
                routes: [
                  _route(
                    path: 'family',
                    builder: (_, _) => const FamilyScreen(),
                  ),
                  // Chi tiêu (v1.1 8b–8m; D-055 … D-057).
                  _route(
                    path: 'spending',
                    builder: (_, _) => const SpendingScreen(),
                    routes: [
                      _route(
                        path: 'history',
                        builder: (_, _) => const SpendingHistoryScreen(),
                      ),
                      _route(
                        path: 'expense/:id',
                        builder: (_, s) => ExpenseDetailScreen(
                          expenseId: s.pathParameters['id'] ?? '',
                        ),
                      ),
                      _route(
                        path: 'budget',
                        builder: (_, _) => const BudgetScreen(),
                      ),
                      _route(
                        path: 'recurring',
                        builder: (_, _) => const RecurringScreen(),
                      ),
                      _route(
                        path: 'stats',
                        builder: (_, _) => const SpendingStatsScreen(),
                      ),
                      _route(
                        path: 'categories',
                        builder: (_, _) => const CategoriesScreen(),
                      ),
                      // Nhập chi tiêu (D-060).
                      _route(
                        path: 'import',
                        builder: (_, _) => const SpendingImportScreen(),
                        routes: [
                          _route(
                            path: ':id',
                            builder: (_, s) => SpendingImportResultScreen(
                              importId: s.pathParameters['id'] ?? '',
                            ),
                            routes: [
                              _route(
                                path: 'review',
                                builder: (_, s) => SpendingImportReviewScreen(
                                  importId: s.pathParameters['id'] ?? '',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Sơ cứu trẻ em (v1.1 7b–7i, TH01–TH24; D-058).
                  _route(
                    path: 'first-aid',
                    builder: (_, _) => const FirstAidHomeScreen(),
                    routes: [
                      _route(
                        path: 'search',
                        builder: (_, _) => const FirstAidSearchScreen(),
                      ),
                      _route(
                        path: 'saved',
                        builder: (_, _) => const FirstAidSavedScreen(),
                      ),
                      _route(
                        path: 's/:id',
                        builder: (_, s) => FirstAidSituationScreen(
                          situationId: s.pathParameters['id'] ?? '',
                          variantId: s.uri.queryParameters['v'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // S11 "Tôi" (13a–13n), opened from the header avatar: pushed, without the dock (370:1898).
      _route(
        path: Routes.me,
        builder: (_, _) => const MeScreen(),
        routes: [
          _route(
            path: 'storage',
            builder: (_, _) => const StorageScreen(),
            routes: [
              _route(
                path: 'videos',
                builder: (_, _) => const LargestVideosScreen(),
              ),
            ],
          ),
          _route(
            path: 'babies',
            builder: (_, _) => const BabyProfilesScreen(),
            routes: [
              _route(
                path: ':id',
                builder: (_, s) =>
                    BabyProfileViewScreen(babyId: s.pathParameters['id'] ?? ''),
              ),
            ],
          ),
          _route(path: 'profile', builder: (_, _) => const ProfileScreen()),
          _route(path: 'account', builder: (_, _) => const AccountScreen()),
          _route(
            path: 'notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          _route(path: 'plan', builder: (_, _) => const HouseholdPlanScreen()),
          _route(path: 'help', builder: (_, _) => const HelpScreen()),
          // FB2 / FB3 Góp ý (D-065); FB4 "Báo lỗi" opens it with `?type=bug`.
          _route(
            path: 'feedback',
            modal: true,
            builder: (_, s) => FeedbackScreen(
              type:
                  FeedbackType.values
                      .asNameMap()[s.uri.queryParameters['type']] ??
                  FeedbackType.idea,
            ),
            routes: [
              _route(
                path: 'sent',
                modal: true,
                builder: (_, s) => FeedbackSentScreen(
                  reply: s.uri.queryParameters['reply'] != '0',
                ),
              ),
            ],
          ),
          // 14m (S13).
          _route(path: 'shared', builder: (_, _) => const SharedOutScreen()),
        ],
      ),
      // S12 stories (14b–14g, 11i): full screen.
      _route(
        path: '${Routes.story}/:id',
        builder: (_, s) =>
            StoryReaderScreen(storyId: s.pathParameters['id'] ?? ''),
        routes: [
          _route(
            path: 'edit',
            builder: (_, s) => StoryEditorScreen(
              storyId: s.pathParameters['id'] ?? '',
              initial: s.extra is Story ? s.extra! as Story : null,
            ),
          ),
        ],
      ),
      _route(
        path: '${Routes.baby}/:id',
        builder: (_, s) =>
            BabyProfileViewScreen(babyId: s.pathParameters['id'] ?? ''),
      ),
      _route(
        path: '${Routes.babyEdit}/:id',
        builder: (_, s) => BabyEditScreen(babyId: s.pathParameters['id'] ?? ''),
      ),
      _route(
        path: Routes.growth,
        builder: (_, s) => GrowthScreen(edit: s.extra as CareRecord?),
      ),
      _route(
        path: '${Routes.timer}/:type',
        builder: (_, s) => TimerScreen(
          type:
              TimerType.values.asNameMap()[s.pathParameters['type']] ??
              TimerType.sleep,
        ),
      ),
      _route(
        path: Routes.manualSleep,
        builder: (_, s) => ManualSleepScreen(
          edit: s.extra is CareRecord ? s.extra! as CareRecord : null,
          endAt: s.extra is DateTime ? s.extra! as DateTime : null,
        ),
      ),
      _route(
        path: '${Routes.overlap}/:id',
        builder: (_, s) =>
            OverlapScreen(conflictId: s.pathParameters['id'] ?? ''),
      ),
      ...rhythmRoutes(),
      _route(
        path: '${Routes.record}/:id',
        builder: (_, s) =>
            RecordDetailScreen(recordId: s.pathParameters['id'] ?? ''),
      ),
      _route(path: Routes.invite, builder: (_, _) => const InviteRoleScreen()),
      _route(
        path: Routes.inviteSend,
        redirect: (_, s) =>
            argsOf<InviteSendArgs>(s) == null ? Routes.family : null,
        builder: (_, s) => InviteSendScreen(args: argsOf<InviteSendArgs>(s)!),
      ),
      _route(
        path: Routes.inviteSent,
        redirect: (_, s) =>
            argsOf<InviteSendArgs>(s) == null ? Routes.family : null,
        builder: (_, s) => InviteSentScreen(args: argsOf<InviteSendArgs>(s)!),
      ),
      _route(path: Routes.join, builder: (_, _) => const EnterCodeScreen()),
      _route(
        path: Routes.joinScan,
        builder: (_, _) => const ScanInviteScreen(),
      ),
      // The invite is in the query (`?code=`), so losing `extra` never sends people back to 15:
      // 16 reads the preview again when it is not known.
      _route(
        path: Routes.joinInvite,
        redirect: (_, s) =>
            joinArgsOf(s) == null && lookupOf(s) == null ? Routes.join : null,
        builder: (_, s) {
          final args = joinArgsOf(s);
          final lookup = args?.lookup ?? lookupOf(s)!;
          return AcceptInviteScreen(lookup: lookup, preview: args?.preview);
        },
      ),
      _route(
        path: Routes.joinConfirm,
        redirect: (_, s) {
          if (joinArgsOf(s) != null) return null;
          // Known invite, preview not: back to 16, which reads it.
          final lookup = lookupOf(s);
          return lookup == null
              ? Routes.join
              : Uri(
                  path: Routes.joinInvite,
                  queryParameters: lookup.toJson(),
                ).toString();
        },
        builder: (_, s) => ConfirmJoinScreen(args: joinArgsOf(s)!),
      ),
      _route(
        path: Routes.joinClosed,
        builder: (_, s) => InviteClosedScreen(
          reason:
              InviteClosedReason.values
                  .asNameMap()[s.uri.queryParameters['reason']] ??
              InviteClosedReason.notFound,
        ),
      ),
      // App Links / universal links from QR codes, emails and messages (plan §3.5).
      _route(
        path: '${Routes.inviteLink}/:token',
        // A tapped link joins at once (owner, 2026-10-12).
        builder: (_, s) => InviteLinkScreen(
          lookup: InviteLookup.token(s.pathParameters['token'] ?? ''),
        ),
      ),
      _route(
        path: Routes.saveAccountEmail,
        builder: (_, _) => const SaveAccountEmailScreen(),
      ),
      GoRoute(
        path: Routes.lostAccess,
        pageBuilder: (_, s) => _fade(s, const LostAccessScreen()),
      ),
      _route(
        path: Routes.appearance,
        builder: (_, _) => const AppearanceScreen(),
      ),
      _route(path: Routes.showcase, builder: (_, _) => const ShowcaseScreen()),
      _route(
        path: Routes.diagnostics,
        builder: (_, _) => const DiagnosticsScreen(),
      ),
    ],
  );
});
