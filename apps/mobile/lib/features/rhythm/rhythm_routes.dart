import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import 'activity_screens.dart';
import 'age_screens.dart';
import 'checkin_screens.dart';
import 'health_screen.dart';
import 'result_screen.dart';
import 'rhythm_models.dart';

/// Nhịp lớn lên routes, full screen above the tabs (no new tab, plan §7.1). Flat on purpose:
/// each is pushed on top of Hôm nay, and leaving the flow pops back to it (`closeFlow`).
/// The flow screens slide up with a close button (C01, PS01, HL01, AC01).
List<RouteBase> rhythmRoutes() => [
  _page(Routes.rhythm, (_, _) => const RhythmComingScreen()),
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
  _page(Routes.rhythmMilestone, (_, _) => const RhythmComingScreen()),
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
