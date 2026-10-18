import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nutrition_growth_screen.dart';
import 'nutrition_milk_screen.dart';
import 'nutrition_nutrient_screen.dart';
import 'nutrition_screens.dart';
import 'nutrition_vitamin_screen.dart';

/// Dinh dưỡng (D-083, Figma 9b–9g): pages under Chăm sóc, so they keep the tab and hide the dock
/// like Tiêm chủng (and get their overlay twins, D-076 nav).
abstract final class NuRoutes {
  /// 9b.
  static const home = '/care/nutrition';

  /// 9c.
  static const milk = '/care/nutrition/milk';

  /// 9f.
  static const stages = '/care/nutrition/stages';

  /// 9f → one stage, read-only: `/care/nutrition/stages/{stageId}`.
  static String stage(String id) => '$stages/$id';

  /// 9d: `/care/nutrition/n/{nutrientId}`.
  static String nutrient(String id) => '$home/n/$id';

  /// 9e: `/care/nutrition/growth/{ruleId}` (Cùng nuôi only).
  static String growth(String ruleId) => '$home/growth/$ruleId';

  /// 9g: `/care/nutrition/vitamin/{nutrientId}`.
  static String vitamin(String id) => '$home/vitamin/$id';
}

GoRoute _page(
  String path,
  Widget Function(BuildContext, GoRouterState) builder, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  routes: routes,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    name: state.path,
    arguments: {...state.pathParameters, ...state.uri.queryParameters},
    restorationId: state.pageKey.value,
    child: builder(context, state),
  ),
);

/// `nutrition` under the Chăm sóc route (registered once in `app/router.dart`).
GoRoute nutritionRoute() => _page(
  'nutrition',
  (_, _) => const NutritionScreen(),
  routes: [
    _page('milk', (_, _) => const NutritionMilkScreen()),
    _page(
      'stages',
      (_, _) => const NutritionStagesScreen(),
      routes: [
        _page(
          ':id',
          (_, s) => NutritionStageScreen(stageId: s.pathParameters['id'] ?? ''),
        ),
      ],
    ),
    _page(
      'n/:id',
      (_, s) => NutrientScreen(nutrientId: s.pathParameters['id'] ?? ''),
    ),
    _page(
      'growth/:ruleId',
      (_, s) => NutritionGrowthScreen(ruleId: s.pathParameters['ruleId'] ?? ''),
    ),
    _page(
      'vitamin/:id',
      (_, s) => VitaminScreen(nutrientId: s.pathParameters['id'] ?? ''),
    ),
  ],
);
