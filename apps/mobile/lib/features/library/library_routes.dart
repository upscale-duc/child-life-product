import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'content_calc.dart';
import 'content_models.dart';
import 'library_screens.dart';
import 'stage_screens.dart';

/// Thư viện chăm bé (4a–4f) and Giai đoạn của bé (2a–2c): full screen above the tabs, like
/// Nhịp lớn lên, so Hôm nay and Chăm sóc both open them without switching tab.
abstract final class LbRoutes {
  /// 4a.
  static const library = '/library';

  /// 4b (+ 4c sheet): `?q=…&topic=sleep&age=m0to3&focus=1`.
  static const search = '/library/search';

  /// 4f; `?library=solids` opens the "Ăn dặm" segment (D-085).
  static const saved = '/library/saved';

  static String savedFor(LbLibrary library) =>
      library == LbLibrary.solids ? '$saved?library=solids' : saved;

  /// 4d / 4e: `/library/a/{articleId}`.
  static const article = '/library/a';

  /// 2a / 2c.
  static const stages = '/stages';

  /// 2b: `/stages/{stageId}`.
  static String stage(String id) => '$stages/$id';

  static String articleOf(String id) => '$article/$id';

  static String searchFor({
    LbTopic? topic,
    LbAgeBand? age,
    bool focus = false,
  }) => Uri(
    path: search,
    queryParameters: {
      if (topic != null) 'topic': topic.wire,
      if (age != null) 'age': age.name,
      if (focus) 'focus': '1',
    },
  ).toString();
}

GoRoute _page(
  String path,
  Widget Function(BuildContext, GoRouterState) builder,
) => GoRoute(
  path: path,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    name: state.path,
    arguments: {...state.pathParameters, ...state.uri.queryParameters},
    restorationId: state.pageKey.value,
    child: builder(context, state),
  ),
);

/// Registered once in `app/router.dart`.
List<RouteBase> libraryRoutes() => [
  _page(LbRoutes.library, (_, _) => const LibraryHomeScreen()),
  _page(LbRoutes.search, (_, s) {
    final q = s.uri.queryParameters;
    return LibrarySearchScreen(
      initial: LbFilter(
        query: q['q'] ?? '',
        topics: {?LbTopic.parse(q['topic'])},
        ages: {?LbAgeBand.values.asNameMap()[q['age']]},
      ),
      focus: q['focus'] == '1',
    );
  }),
  _page(
    LbRoutes.saved,
    (_, s) => SavedArticlesScreen(
      library: s.uri.queryParameters['library'] == 'solids'
          ? LbLibrary.solids
          : LbLibrary.care,
    ),
  ),
  _page(
    '${LbRoutes.article}/:id',
    (_, s) => ArticleScreen(articleId: s.pathParameters['id'] ?? ''),
  ),
  _page(LbRoutes.stages, (_, _) => const StagesScreen()),
  _page(
    '${LbRoutes.stages}/:id',
    (_, s) => StageDetailScreen(stageId: s.pathParameters['id'] ?? ''),
  ),
];
