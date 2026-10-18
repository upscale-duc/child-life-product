import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'solids_history.dart';
import 'solids_models.dart' show sdFoodId;
import 'solids_recipes.dart';
import 'solids_screens.dart';

/// Ăn dặm (D-085, Figma 5a–5h): pages under Chăm sóc like Dinh dưỡng, so they keep the tab and
/// hide the dock (and get their overlay twins, D-076 nav).
abstract final class SdRoutes {
  /// 5a until tracking is on (or "Chưa đến lúc" under 6 months), then 5b: `?tab=library` opens
  /// the "Thư viện ăn dặm" segment.
  static const home = '/care/solids';

  /// 5b with the library segment selected.
  static const diaryLibrary = '/care/solids?tab=library';

  /// 5f on its own (from 5a, or for members who do not read the diary).
  static const library = '/care/solids/library';

  /// 5d; `?tab=foods` opens 5e.
  static const history = '/care/solids/history';
  static const foods = '/care/solids/history?tab=foods';

  /// Meal detail: `/care/solids/meal/{mealId}`.
  static String meal(String id) => '$home/meal/$id';

  /// Food detail: `/care/solids/food/{fd_… | x_…}` (path-safe keys, `sdFreeKey`).
  static String food(String key) => '$home/food/$key';

  /// 5g: `/care/solids/recipe/{rcp_…}`.
  static String recipe(String id) => '$home/recipe/$id';

  /// "Xem công thức" of a suggestion: the recipes with one of [foodIds].
  static String recipesFor(List<String> foodIds) =>
      '$home/recipes?food=${foodIds.join(',')}';
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

/// `solids` under the Chăm sóc route (registered once in `app/router.dart`).
GoRoute solidsRoute() => _page(
  'solids',
  (_, s) => SolidsScreen(library: s.uri.queryParameters['tab'] == 'library'),
  routes: [
    _page('library', (_, _) => const SolidsLibraryScreen()),
    _page(
      'history',
      (_, s) =>
          MealHistoryScreen(foods: s.uri.queryParameters['tab'] == 'foods'),
    ),
    _page(
      'meal/:id',
      (_, s) => MealDetailScreen(mealId: s.pathParameters['id'] ?? ''),
    ),
    _page(
      'food/:key',
      (_, s) => FoodDetailScreen(foodKey: s.pathParameters['key'] ?? ''),
    ),
    _page(
      'recipe/:id',
      (_, s) => SdRecipeScreen(recipeId: s.pathParameters['id'] ?? ''),
    ),
    _page(
      'recipes',
      (_, s) => SdRecipeListScreen(
        foodIds: [
          for (final id in (s.uri.queryParameters['food'] ?? '').split(','))
            if (sdFoodId(id)) id,
        ],
      ),
    ),
  ],
);
