import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/navigation.dart' show SafePushContext;
import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../app/session.dart';
import '../first_aid/first_aid_repository.dart';
import '../care/care_repository.dart' show onlineProvider;
import 'content_calc.dart';
import 'content_models.dart';
import 'content_repository.dart';
import 'library_routes.dart';
import 'library_widgets.dart';

/// Thư viện chăm bé (Figma v1.1 4a home, 4b search, 4c filters, 4d reader, 4e saved toast, 4f
/// saved list; D-076 #7). Only the "Chăm bé" library: Ăn dặm (5f) has its own screens later.

/// Published care-library articles (Ăn dặm excluded).
List<LbArticle> _care(LbFeed<LbArticle>? feed) => [
  for (final a in feed?.items ?? const <LbArticle>[])
    if (a.library == LbLibrary.care) a,
];

/// "Lưu" / "Đã lưu" (4e): saving shows "Đã lưu · xem trong Thư viện › Đã lưu" with a way there;
/// removing offers "Hoàn tác".
Future<void> lbToggleSaved(
  BuildContext context,
  WidgetRef ref,
  LbArticle article,
) async {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return;
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final router = GoRouter.of(context);
  final store = ref.read(contentStoreProvider);
  final uid = session.user.uid;
  final saved = (ref.read(lbSavedProvider).value ?? const <LbSaved>[]).any(
    (s) => s.id == article.id,
  );
  // Firestore applies the write locally at once (and syncs later when offline); a refusal
  // arrives later, so it is reported then.
  void failed(Object _) =>
      toaster.show(message: l10n.lbSaveFailed, error: true);
  if (saved) {
    unawaited(store.unsave(uid, article.id).catchError(failed));
    toaster.show(
      message: l10n.lbUnsavedToast,
      actionLabel: l10n.lbUndo,
      onAction: () => unawaited(store.save(uid, article).catchError(failed)),
    );
  } else {
    unawaited(store.save(uid, article).catchError(failed));
    toaster.show(
      message: l10n.lbSavedToast,
      actionLabel: l10n.lbView,
      onAction: () => unawaited(router.push(LbRoutes.saved)),
    );
  }
}

Set<String> _savedIds(WidgetRef ref) => {
  for (final s in ref.watch(lbSavedProvider).value ?? const <LbSaved>[]) s.id,
};

/// The search field look (white, control border, search icon 18).
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.child, this.trailing});
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
          const SizedBox(width: 10),
          Expanded(child: child),
          ?trailing,
        ],
      ),
    );
  }
}

/// Nothing published yet (or nothing cached while offline): honest, no sample content.
Widget _libraryEmpty(BuildContext context, bool offline) {
  final l10n = AppLocalizations.of(context);
  return LbEmpty(
    icon: offline ? ClIcons.cloudOff : ClIcons.journal,
    title: offline ? l10n.lbEmptyOfflineTitle : l10n.lbEmptyTitle,
    body: offline ? l10n.lbEmptyOfflineBody : l10n.lbEmptyBody,
  );
}

// ---------- 4a Thư viện chăm bé ----------

class LibraryHomeScreen extends ConsumerWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final feed = ref.watch(lbArticlesProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final articles = _care(feed.value);
    final baby = ref.watch(lbBabyProvider);
    final saved = _savedIds(ref);
    final ageLabel = lbAgeLabel(l10n, baby);
    final weeks = baby?.dob == null
        ? null
        : lbAgeIn(LbUnit.week, baby!.dob!, baby.today);
    final forAge = weeks == null
        ? const <LbArticle>[]
        : lbForAge(articles, weeks);
    final recent = lbRecent(articles).take(5).toList();
    final band = weeks == null
        ? null
        : LbAgeBand.values
              .where((b) => weeks >= b.fromWeeks && weeks < b.toWeeks)
              .firstOrNull;

    return LbPage(
      trailing: LbPillButton(
        key: const Key('lbSavedList'),
        icon: ClIcons.bookmark,
        label: l10n.lbSaved,
        onPressed: () => context.push(LbRoutes.saved),
      ),
      children: [
        LbTitle(l10n.lbTitle),
        const SizedBox(height: ClSpace.s4),
        ClPressable(
          key: const Key('lbSearch'),
          onPressed: () => context.push(LbRoutes.searchFor(focus: true)),
          pressedOpacity: ClPressable.surfaceOpacity,
          semanticLabel: l10n.lbSearchHint,
          child: _SearchBox(
            child: Text(
              l10n.lbSearchHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.body.copyWith(
                fontSize: 15,
                color: cl.colors.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        _TopicGrid(onTopic: (t) => context.push(LbRoutes.searchFor(topic: t))),
        LbOfflineNote(l10n.lbOfflineLibrary, top: ClSpace.s3),
        if (feed.isLoading && articles.isEmpty)
          const SizedBox(height: 120)
        else if (articles.isEmpty)
          _libraryEmpty(context, !online)
        else ...[
          if (forAge.isNotEmpty && ageLabel != null) ...[
            LbSection(
              l10n.lbForBaby(baby!.name, ageLabel),
              link: band == null ? null : l10n.lbSeeMore,
              onLink: band == null
                  ? null
                  : () => context.push(LbRoutes.searchFor(age: band)),
            ),
            SizedBox(
              height: 214,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: forAge.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ArticleCard(article: forAge[i]),
              ),
            ),
          ],
          LbSection(l10n.lbRecent),
          LbGroup(
            children: [
              for (final a in recent)
                LbArticleRow(
                  key: Key('lbRow_${a.id}'),
                  article: a,
                  meta: lbMeta(l10n, a),
                  saved: saved.contains(a.id),
                  onBookmark: () => unawaited(lbToggleSaved(context, ref, a)),
                  onTap: () => context.push(LbRoutes.articleOf(a.id)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 4a topic tiles, 3 × 2: tinted, icon 20, SemiBold 13.
class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.onTopic});
  final ValueChanged<LbTopic> onTopic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget tile(LbTopic t) {
      final look = lbTopicLook(context, t);
      final label = lbTopicLabel(l10n, t);
      return Expanded(
        child: ClPressable(
          key: Key('lbTopic_${t.wire}'),
          onPressed: () => onTopic(t),
          pressedOpacity: ClPressable.surfaceOpacity,
          semanticLabel: label,
          child: Container(
            height: 76,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
            decoration: BoxDecoration(
              color: look.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClIcon(look.icon, size: 20, color: look.ink),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.label.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: look.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    const t = LbTopic.values;
    return Column(
      children: [
        for (var i = 0; i < t.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              tile(t[i]),
              const SizedBox(width: 10),
              tile(t[i + 1]),
              const SizedBox(width: 10),
              tile(t[i + 2]),
            ],
          ),
        ],
      ],
    );
  }
}

/// 4a "Hợp với …" card: white, r 18, picture 220 × 120, title, meta.
class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final LbArticle article;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final title = article.title.of(context);
    final meta = [
      lbTopicLabel(l10n, article.topic),
      l10n.lbMinutesShort(article.readingMinutes),
    ].join(' · ');
    return ClPressable(
      key: Key('lbCard_${article.id}'),
      onPressed: () => context.push(LbRoutes.articleOf(article.id)),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$title. $meta',
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cl.shadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                LbPicture(
                  image: article.cover?.id,
                  width: 220,
                  height: 120,
                  radius: 0,
                  topic: article.topic,
                ),
                if (article.illustrative)
                  const Positioned(
                    left: 8,
                    top: 8,
                    child: LbIllustrativeBadge(compact: true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 4b Tìm & lọc ----------

class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({
    this.initial = const LbFilter(),
    this.focus = false,
    super.key,
  });
  final LbFilter initial;
  final bool focus;

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  late LbFilter _filter = widget.initial;
  late final _query = TextEditingController(text: widget.initial.query);

  @override
  void initState() {
    super.initState();
    _query.addListener(() {
      if (_query.text != _filter.query) {
        setState(() => _filter = _filter.copyWith(query: _query.text));
      }
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<LbArticle> articles) async {
    final next = await showLibraryFilters(context, _filter, articles);
    if (next != null && mounted) setState(() => _filter = next);
  }

  Future<void> _openSort() async {
    final l10n = AppLocalizations.of(context);
    final next = await showClSheet<LbSort>(
      context: context,
      builder: (context) {
        final cl = context.cl;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l10n.lbSortTitle),
              for (final s in LbSort.values)
                ClPressable(
                  key: Key('lbSort_${s.name}'),
                  onPressed: () => Navigator.of(context).pop(s),
                  selected: s == _filter.sort,
                  semanticLabel: _sortLabel(l10n, s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_sortLabel(l10n, s), style: cl.text.body),
                        ),
                        if (s == _filter.sort)
                          ClIcon(
                            ClIcons.check,
                            size: 18,
                            color: cl.colors.mintText,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (next != null && mounted) {
      setState(() => _filter = _filter.copyWith(sort: next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final feed = ref.watch(lbArticlesProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final articles = _care(feed.value);
    final results = _filter.apply(articles);
    final saved = _savedIds(ref);

    Widget removable(String label, Color fill, Color ink, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClPressable(
            onPressed: onTap,
            semanticLabel: l10n.lbRemoveFilter(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(ClIcons.close, size: 12, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    final count = _filter.count;
    return LbPage(
      children: [
        _SearchBox(
          trailing: _query.text.isEmpty
              ? null
              : ClPressable(
                  key: const Key('lbClearQuery'),
                  onPressed: _query.clear,
                  semanticLabel: l10n.lbClearSearch,
                  child: ClIcon(ClIcons.close, size: 16, color: cl.colors.ink),
                ),
          child: TextField(
            key: const Key('lbQuery'),
            controller: _query,
            autofocus: widget.focus,
            textInputAction: TextInputAction.search,
            style: cl.text.body.copyWith(fontSize: 15),
            decoration: InputDecoration.collapsed(
              hintText: l10n.lbSearchHint,
              hintStyle: cl.text.body.copyWith(
                fontSize: 15,
                color: cl.colors.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              ClPressable(
                key: const Key('lbFilters'),
                onPressed: () => unawaited(_openFilters(articles)),
                semanticLabel: count == 0
                    ? l10n.lbFilters
                    : l10n.lbFiltersCount(count),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.ink,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClIcon(ClIcons.sliders, size: 14, color: cl.colors.cloud),
                      const SizedBox(width: 6),
                      Text(
                        count == 0
                            ? l10n.lbFilters
                            : l10n.lbFiltersCount(count),
                        style: cl.text.label.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cl.colors.cloud,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final t in LbTopic.values)
                if (_filter.topics.contains(t))
                  removable(
                    lbTopicLabel(l10n, t),
                    lbTopicLook(context, t).soft,
                    lbTopicLook(context, t).ink,
                    () => setState(
                      () => _filter = _filter.copyWith(
                        topics: {..._filter.topics}..remove(t),
                      ),
                    ),
                  ),
              for (final b in LbAgeBand.values)
                if (_filter.ages.contains(b))
                  removable(
                    lbBandLabel(l10n, b),
                    cl.colors.surface2,
                    cl.colors.ink,
                    () => setState(
                      () => _filter = _filter.copyWith(
                        ages: {..._filter.ages}..remove(b),
                      ),
                    ),
                  ),
              for (final r in LbReadTime.values)
                if (_filter.times.contains(r))
                  removable(
                    lbTimeLabel(l10n, r),
                    cl.colors.surface2,
                    cl.colors.ink,
                    () => setState(
                      () => _filter = _filter.copyWith(
                        times: {..._filter.times}..remove(r),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        LbOfflineNote(l10n.lbOfflineLibrary, top: ClSpace.s3),
        if (feed.isLoading && articles.isEmpty)
          const SizedBox(height: 120)
        else if (articles.isEmpty)
          _libraryEmpty(context, !online)
        else ...[
          const SizedBox(height: ClSpace.s4),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.lbResults(results.length),
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ClPressable(
                key: const Key('lbSort'),
                onPressed: () => unawaited(_openSort()),
                semanticLabel:
                    '${l10n.lbSortTitle}: ${_sortLabel(l10n, _filter.sort)}',
                child: Row(
                  children: [
                    Text(
                      _sortLabel(l10n, _filter.sort),
                      style: cl.text.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cl.colors.mintText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ClIcon(
                      ClIcons.chevronDown,
                      size: 14,
                      color: cl.colors.mintText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          if (results.isEmpty)
            LbEmpty(
              icon: ClIcons.search,
              title: l10n.lbNoResults,
              body: l10n.lbNoResultsHint,
            )
          else
            LbGroup(
              children: [
                for (final a in results)
                  LbArticleRow(
                    key: Key('lbRow_${a.id}'),
                    article: a,
                    meta: lbMeta(l10n, a, age: true),
                    saved: saved.contains(a.id),
                    onBookmark: () => unawaited(lbToggleSaved(context, ref, a)),
                    onTap: () => context.push(LbRoutes.articleOf(a.id)),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

String _sortLabel(AppLocalizations l10n, LbSort s) => switch (s) {
  LbSort.relevant => l10n.lbSortRelevant,
  LbSort.newest => l10n.lbSortNewest,
  LbSort.shortest => l10n.lbSortShortest,
};

String lbBandLabel(AppLocalizations l10n, LbAgeBand b) => switch (b) {
  LbAgeBand.m0to3 => l10n.lbRangeMonths(0, 3),
  LbAgeBand.m3to6 => l10n.lbRangeMonths(3, 6),
  LbAgeBand.m6to12 => l10n.lbRangeMonths(6, 12),
  LbAgeBand.y1to2 => l10n.lbRangeYears(1, 2),
};

String lbTimeLabel(AppLocalizations l10n, LbReadTime r) => switch (r) {
  LbReadTime.short => l10n.lbTimeShort,
  LbReadTime.medium => l10n.lbTimeMedium,
  LbReadTime.long => l10n.lbTimeLong,
};

// ---------- 4c Bộ lọc ----------

/// The filter sheet: topic, age and reading time chips (multi-select), "Đặt lại" and
/// "Xem N bài" with the live count. Returns the new filter, or null when closed.
Future<LbFilter?> showLibraryFilters(
  BuildContext context,
  LbFilter current,
  List<LbArticle> articles,
) => showClSheet<LbFilter>(
  context: context,
  builder: (_) => _FilterSheet(initial: current, articles: articles),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.articles});
  final LbFilter initial;
  final List<LbArticle> articles;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late LbFilter _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final count = _f.apply(widget.articles).length;

    Widget group(String label, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: cl.text.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );

    Widget chip(String key, String label, bool on, VoidCallback toggle) =>
        ClPressable(
          key: Key('lbChip_$key'),
          onPressed: toggle,
          selected: on,
          semanticLabel: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: on ? cl.colors.mintDeep : cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.pill),
              border: on ? null : Border.all(color: cl.colors.controlBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (on) ...[
                  ClIcon(ClIcons.check, size: 14, color: cl.colors.onMintDeep),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: on ? cl.colors.onMintDeep : cl.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        );

    Set<T> flip<T>(Set<T> s, T v) =>
        s.contains(v) ? ({...s}..remove(v)) : {...s, v};

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.lbFilters),
          group(l10n.lbFilterTopic, [
            for (final t in LbTopic.values)
              chip(
                t.wire,
                lbTopicLabel(l10n, t),
                _f.topics.contains(t),
                () => setState(
                  () => _f = _f.copyWith(topics: flip(_f.topics, t)),
                ),
              ),
          ]),
          group(l10n.lbFilterAge, [
            for (final b in LbAgeBand.values)
              chip(
                b.name,
                lbBandLabel(l10n, b),
                _f.ages.contains(b),
                () => setState(() => _f = _f.copyWith(ages: flip(_f.ages, b))),
              ),
          ]),
          group(l10n.lbFilterTime, [
            for (final r in LbReadTime.values)
              chip(
                r.name,
                lbTimeLabel(l10n, r),
                _f.times.contains(r),
                () =>
                    setState(() => _f = _f.copyWith(times: flip(_f.times, r))),
              ),
          ]),
          const SizedBox(height: ClSpace.s2),
          Row(
            children: [
              ClButton(
                key: const Key('lbReset'),
                label: l10n.lbReset,
                style: ClButtonStyle.secondary,
                onPressed: () => setState(
                  () => _f = _f.copyWith(topics: {}, ages: {}, times: {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClButton(
                  key: const Key('lbApply'),
                  label: l10n.lbShowN(count),
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(_f),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- 4d Bài viết (+ 4e Đã lưu) ----------

const _textScaleKey = 'lbTextScale';
const _textScales = [1.0, 1.15, 1.3];

class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({required this.articleId, super.key});
  final String articleId;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  bool _markedRead = false;

  double _scale() {
    try {
      final v = ref.read(sharedPreferencesProvider).getDouble(_textScaleKey);
      return _textScales.contains(v) ? v! : 1.0;
    } on Object {
      return 1.0;
    }
  }

  void _cycleScale() {
    final now = _scale();
    final next =
        _textScales[(_textScales.indexOf(now) + 1) % _textScales.length];
    unawaited(
      ref.read(sharedPreferencesProvider).setDouble(_textScaleKey, next),
    );
    setState(() {});
  }

  /// Opening the newer revision of a saved article clears the 4f "đã được cập nhật" banner.
  void _markRead(LbArticle a, List<LbSaved> saved) {
    if (_markedRead) return;
    final mine = saved.where((s) => s.id == a.id).firstOrNull;
    final session = ref.read(sessionProvider);
    if (mine == null || mine.revision >= a.revision) return;
    if (session is! SessionSignedIn) return;
    _markedRead = true;
    unawaited(
      ref
          .read(contentStoreProvider)
          .markRead(session.user.uid, a.id, a.revision)
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final feed = ref.watch(lbArticlesProvider);
    final all = feed.value?.items ?? const <LbArticle>[];
    final article = all.where((a) => a.id == widget.articleId).firstOrNull;
    final savedList = ref.watch(lbSavedProvider).value ?? const <LbSaved>[];
    if (article == null) {
      return LbPage(
        children: [
          if (!feed.isLoading)
            LbEmpty(
              icon: ClIcons.journal,
              title: l10n.lbArticleMissing,
              body: l10n.lbArticleMissingBody,
            ),
        ],
      );
    }
    _markRead(article, savedList);
    final saved = savedList.any((s) => s.id == article.id);
    final scale = _scale();
    final look = lbTopicLook(context, article.topic);
    final related = [
      for (final id in article.related)
        ?all.where((a) => a.id == id).firstOrNull,
    ];
    final firstAid = ref.watch(firstAidPackProvider).value != null;

    return LbPage(
      bottom: _ArticleBar(
        saved: saved,
        onSave: () => unawaited(lbToggleSaved(context, ref, article)),
        onTextSize: _cycleScale,
      ),
      children: [
        if (article.cover != null) ...[
          LbPicture(
            image: article.cover!.id,
            alt: article.cover!.alt?.of(context),
            width: double.infinity,
            height: 190,
            radius: 22,
            topic: article.topic,
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LbChip(
              lbTopicLabel(l10n, article.topic),
              fill: look.soft,
              ink: look.ink,
            ),
            LbChip(lbWeeksLabel(l10n, article.weeks)),
            LbChip(l10n.lbMinutes(article.readingMinutes)),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(
            article.title.of(context),
            style: cl.text.largeTitle.copyWith(
              fontSize: 28 * scale,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        if (article.illustrative)
          const Align(
            alignment: Alignment.centerLeft,
            child: LbIllustrativeBadge(),
          )
        else if (article.review != null)
          Row(
            children: [
              ClIcon(ClIcons.check, size: 14, color: cl.colors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lbReviewLabel(l10n, article.review!),
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    color: cl.colors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: ClSpace.s4),
        LbBlocks(
          blocks: article.blocksFor(locale),
          scale: scale,
          topic: article.topic,
          firstAid: firstAid,
        ),
        if (article.sources.isNotEmpty) ...[
          LbSection(l10n.lbSources),
          for (final s in article.sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '· ${s.label}',
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
        ],
        if (related.isNotEmpty) ...[
          LbSection(l10n.lbRelated),
          LbGroup(
            children: [
              for (final a in related)
                LbArticleRow(
                  key: Key('lbRelated_${a.id}'),
                  article: a,
                  thumb: 52,
                  meta: [
                    lbTopicLabel(l10n, a.topic),
                    l10n.lbMinutesShort(a.readingMinutes),
                  ].join(' · '),
                  onTap: () => context.push(LbRoutes.articleOf(a.id)),
                ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.lbArticleFootnote,
          style: cl.text.caption.copyWith(
            fontSize: 12,
            color: cl.colors.inkMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// 4d bottom bar: "Lưu" / "Đã lưu" (mint, filled bookmark) · spacer · "Aa".
class _ArticleBar extends StatelessWidget {
  const _ArticleBar({
    required this.saved,
    required this.onSave,
    required this.onTextSize,
  });
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onTextSize;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    Widget pill({
      required Key key,
      required String label,
      required VoidCallback onTap,
      ClIcons? icon,
      bool on = false,
      String? semantic,
    }) {
      final fill = on ? cl.colors.mintSoft : cl.colors.surface2;
      final ink = on ? cl.colors.mintText : cl.colors.ink;
      return ClPressable(
        key: key,
        onPressed: onTap,
        selected: on,
        semanticLabel: semantic ?? label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                ClIcon(icon, size: 14, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        border: Border(top: BorderSide(color: cl.colors.separator)),
      ),
      child: Row(
        children: [
          pill(
            key: const Key('lbSave'),
            label: saved ? l10n.lbSaved : l10n.lbSave,
            semantic: saved ? l10n.lbUnsave : l10n.lbSave,
            icon: saved ? ClIcons.bookmarkFill : ClIcons.bookmark,
            on: saved,
            onTap: onSave,
          ),
          const Spacer(),
          pill(
            key: const Key('lbTextSize'),
            label: 'Aa',
            semantic: l10n.lbTextSize,
            onTap: onTextSize,
          ),
        ],
      ),
    );
  }
}

/// Renders the safe block model as native text (never HTML): paragraph, heading, bullets,
/// image with caption, callout. "Khi nào nên hỏi bác sĩ" callouts offer Sơ cứu when the guide is
/// on the device.
class LbBlocks extends StatelessWidget {
  const LbBlocks({
    required this.blocks,
    this.scale = 1,
    this.topic,
    this.firstAid = false,
    super.key,
  });

  final List<LbBlock> blocks;
  final double scale;
  final LbTopic? topic;
  final bool firstAid;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final body = cl.text.body.copyWith(
      fontSize: 16 * scale,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );
    Widget block(LbBlock b) => switch (b) {
      LbParagraph(:final text) => Text(text, style: body),
      LbHeading(:final text) => Semantics(
        header: true,
        child: Text(
          text,
          style: cl.text.headline.copyWith(
            fontSize: 19 * scale,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
      LbBullets(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, t) in items.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10 * scale, left: 2, right: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cl.colors.mintText,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: Text(t, style: body)),
              ],
            ),
          ],
        ],
      ),
      LbFigure(:final image, :final caption, :final alt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LbPicture(
            image: image,
            alt: alt,
            width: double.infinity,
            height: 160,
            radius: 16,
            topic: topic,
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              style: cl.text.caption.copyWith(
                fontSize: 12 * scale,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
        ],
      ),
      LbCallout(:final tone, :final title, :final text) => _Callout(
        tone: tone,
        title: title,
        text: text,
        scale: scale,
        firstAidLabel: tone == LbCalloutTone.doctor && firstAid
            ? l10n.lbOpenFirstAid
            : null,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in blocks.indexed) ...[
          if (i > 0) SizedBox(height: b is LbHeading ? 20 : 12),
          block(b),
        ],
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.tone,
    required this.text,
    required this.scale,
    this.title,
    this.firstAidLabel,
  });
  final LbCalloutTone tone;
  final String? title;
  final String text;
  final double scale;
  final String? firstAidLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    // Ink on soft warm fills (also in Night care); mint text on mint-soft.
    final (fill, ink, icon) = switch (tone) {
      LbCalloutTone.doctor => (
        cl.colors.sunshineSoft,
        cl.colors.ink,
        ClIcons.alert,
      ),
      LbCalloutTone.tip => (
        cl.colors.mintSoft,
        cl.colors.mintText,
        ClIcons.spark,
      ),
      LbCalloutTone.note => (cl.colors.surface2, cl.colors.ink, ClIcons.heart),
    };
    return Container(
      key: Key('lbCallout_${tone.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(icon, size: 16, color: ink),
              const SizedBox(width: 8),
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: cl.text.body.copyWith(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: ink,
            ),
          ),
          if (firstAidLabel != null) ...[
            const SizedBox(height: 10),
            ClPressable(
              key: const Key('lbOpenFirstAid'),
              // D-076 nav: articles are above the tabs; Sơ cứu is a Tiện ích page.
              onPressed: () => context.pushSafe(Routes.firstAid),
              semanticLabel: firstAidLabel,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstAidLabel!,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cl.colors.danger,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ClIcon(
                    ClIcons.chevronRight,
                    size: 14,
                    color: cl.colors.danger,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 4f Bài đã lưu ----------

class SavedArticlesScreen extends ConsumerWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final saved = ref.watch(lbSavedProvider);
    final all =
        ref.watch(lbArticlesProvider).value?.items ?? const <LbArticle>[];
    final byId = {for (final a in all) a.id: a};
    final baby = ref.watch(lbBabyProvider);
    final today = baby?.today ?? DateTime.now();
    final rows = [
      for (final s in saved.value ?? const <LbSaved>[])
        if (byId[s.id] case final a?) (a, s),
    ];
    final updated = rows.where((r) => r.$1.revision > r.$2.revision).toList();

    String savedOn(LbArticle a, LbSaved s) {
      final at = s.savedAt;
      final topic = lbTopicLabel(l10n, a.topic);
      if (at == null ||
          DateUtils.isSameDay(at.toLocal(), today) ||
          at.isAfter(today)) {
        return l10n.lbSavedToday(topic);
      }
      final locale = Localizations.localeOf(context).toLanguageTag();
      return l10n.lbSavedOn(
        topic,
        DateFormat('dd/MM', locale).format(at.toLocal()),
      );
    }

    return LbPage(
      children: [
        LbTitle(l10n.lbSaved),
        LbOfflineNote(l10n.lbOfflineLibrary, top: ClSpace.s3),
        const SizedBox(height: ClSpace.s4),
        if (saved.isLoading && rows.isEmpty)
          const SizedBox(height: 120)
        else if (rows.isEmpty)
          LbEmpty(
            icon: ClIcons.bookmark,
            title: l10n.lbSavedEmptyTitle,
            body: l10n.lbSavedEmptyBody,
          )
        else ...[
          LbGroup(
            children: [
              for (final (a, s) in rows)
                LbArticleRow(
                  key: Key('lbSaved_${a.id}'),
                  article: a,
                  thumb: 56,
                  meta: savedOn(a, s),
                  saved: true,
                  onBookmark: () => unawaited(lbToggleSaved(context, ref, a)),
                  onTap: () => context.push(LbRoutes.articleOf(a.id)),
                ),
            ],
          ),
          for (final (a, _) in updated) ...[
            const SizedBox(height: ClSpace.s3),
            ClPressable(
              key: Key('lbUpdated_${a.id}'),
              onPressed: () => context.push(LbRoutes.articleOf(a.id)),
              pressedOpacity: ClPressable.surfaceOpacity,
              semanticLabel: l10n.lbUpdated(a.title.of(context)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.mintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClIcon(ClIcons.retry, size: 16, color: cl.colors.mintText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.lbUpdated(a.title.of(context)),
                        style: cl.text.label.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: cl.colors.mintText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
