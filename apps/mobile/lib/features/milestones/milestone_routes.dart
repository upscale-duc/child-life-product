import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'milestone_screens.dart';

/// Mốc phát triển under Tiện ích (D-076 #6): `/utilities/milestones` (3a), `/own` (3g, slides
/// up with a close button) and `/:id` (3b / 3d / 3f: a reference id or a custom record's `ms_…`).
/// Inside the Tiện ích branch, so the Home card and the card editor (Kỷ niệm branch) are reached
/// with ordinary pushes from the tab shell.
GoRoute milestonesRoute() => _page(
  'milestones',
  (_, _) => const MilestonesScreen(),
  routes: [
    _page('own', modal: true, (_, _) => const OwnMilestoneScreen()),
    _page(
      ':id',
      // Lumi L5: `?record=YYYY-MM-DD` opens "Bé đã làm được" on that day, once.
      (_, s) => MilestoneDetailScreen(
        id: s.pathParameters['id'] ?? '',
        recordOn: DateTime.tryParse(s.uri.queryParameters['record'] ?? ''),
      ),
    ),
  ],
);

GoRoute _page(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  bool modal = false,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
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
