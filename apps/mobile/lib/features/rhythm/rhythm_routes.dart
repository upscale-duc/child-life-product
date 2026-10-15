import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../ai/ai_consent_screen.dart';
import '../ai/handover_screen.dart';
import 'activity_screens.dart';
import 'age_screens.dart';
import 'checkin_screens.dart';
import 'health_screen.dart';
import 'milestone_screen.dart';
import 'preferences_screens.dart';
import 'result_screen.dart';
import 'rhythm_calendar.dart';
import 'rhythm_models.dart';
import 'rhythm_overview.dart';
import 'rhythm_setup.dart';
import 'week_screen.dart';

/// Nhịp lớn lên routes, full screen above the tabs (no new tab, plan §7.1). Flat on purpose:
/// each is pushed on top of Hôm nay, and leaving the flow pops back to it (`closeFlow`).
/// The flow screens slide up with a close button (C01, PS01, HL01, AC01, NL02, MS01).
List<RouteBase> rhythmRoutes() => [
  _page(Routes.rhythm, (_, _) => const RhythmOverviewScreen()),
  _page(Routes.rhythmSetup, modal: true, (_, _) => const RhythmSetupScreen()),
  _page(
    Routes.rhythmDueDate,
    modal: true,
    (_, s) => RhythmSetupScreen(
      start: RhythmSetupStep.dueDate,
      single: true,
      estimate: s.uri.queryParameters['estimate'] == '1',
    ),
  ),
  _page(
    Routes.rhythmReminders,
    modal: true,
    (_, _) =>
        const RhythmSetupScreen(start: RhythmSetupStep.reminders, single: true),
  ),
  _page(Routes.rhythmCalendar, (_, _) => const ReferenceCalendarScreen()),
  _page(
    '${Routes.rhythmCalendar}/:id',
    (_, s) => StageDetailScreen(stageId: s.pathParameters['id'] ?? ''),
  ),
  _page(Routes.rhythmPersonalize, (_, _) => const PersonalizeScreen()),
  _page(Routes.rhythmInterests, (_, _) => const InterestsScreen()),
  _page(Routes.rhythmDigest, (_, _) => const DigestScreen()),
  _page(Routes.rhythmFeedbackHistory, (_, _) => const FeedbackHistoryScreen()),
  _page(Routes.rhythmCheckIn, modal: true, (_, _) => const CheckInScreen()),
  _page(
    Routes.rhythmCheckInMore,
    (_, s) => CheckInMoreScreen(
      observation:
          wireOf(Observation.values, s.uri.queryParameters['o']) ??
          Observation.sleep,
    ),
  ),
  _page(Routes.rhythmCheckInHealth, (_, _) => const HealthQuestionsScreen()),
  _page(
    Routes.rhythmResult,
    modal: true,
    redirect: (_, s) => s.extra is CheckIn ? null : Routes.today,
    (_, s) => RhythmResultScreen(checkIn: s.extra! as CheckIn),
  ),
  _page(
    Routes.rhythmHealth,
    modal: true,
    (_, s) => HealthSupportScreen(
      signs: wireList(
        HealthSign.values,
        (s.uri.queryParameters['signs'] ?? '').split(','),
      ),
    ),
  ),
  _page(
    '${Routes.rhythmActivity}/:id',
    modal: true,
    (_, s) => ActivityScreen(
      contentId: s.pathParameters['id'] ?? '',
      checkInId: s.uri.queryParameters['ci'],
    ),
  ),
  _page(
    '${Routes.rhythmActivity}/:id/feedback',
    (_, s) => ActivityFeedbackScreen(contentId: s.pathParameters['id'] ?? ''),
  ),
  _page(
    '${Routes.rhythmAge}/:id',
    (_, s) => AgeCardScreen(cardId: s.pathParameters['id'] ?? ''),
  ),
  _page(Routes.rhythmWeek, modal: true, (_, _) => const WeekSummaryScreen()),
  _page(Routes.rhythmHandover, (_, _) => const HandoverScreen()),
  _page(Routes.rhythmAiConsent, (_, _) => const AiConsentScreen()),
  _page(
    Routes.rhythmMilestone,
    modal: true,
    (_, s) => RhythmMilestoneScreen(
      note: s.extra is String ? s.extra! as String : null,
    ),
  ),
];

GoRoute _page(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  bool modal = false,
  GoRouterRedirect? redirect,
}) => GoRoute(
  path: path,
  redirect: redirect,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    fullscreenDialog: modal,
    name: state.name ?? state.path,
    arguments: {...state.pathParameters, ...state.uri.queryParameters},
    restorationId: state.pageKey.value,
    child: builder(context, state),
  ),
);
