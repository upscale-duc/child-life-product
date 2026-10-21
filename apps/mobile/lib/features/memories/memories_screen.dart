import '../engagement/engagement_widgets.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../keepsakes/keepsake_entries.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../auto_save/auto_save_widgets.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import 'album_models.dart';
import 'album_screens.dart';
import 'media_bytes.dart';
import 'media_viewer.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_sheets.dart';
import 'memory_widgets.dart';
import 'social_widgets.dart';
import 'upload_queue.dart';
import '../stories/stories_view.dart';

// ---------- View state (10c) and selection (10b2) ----------

/// Owner request (2026-10-11): Ảnh first, then Album, Nhật ký, Câu chuyện; Kỷ niệm opens on Ảnh.
enum MemoryTab { photos, albums, journal, stories }

enum MemoryGroup { day, week, month }

enum MemoryLayout { small, large, list }

enum MemoryShow { all, photos, videos, milestones }

enum MemoryWho { all, family, parents }

/// v1.0 10b "Xem ảnh theo": week of age, month of age, calendar month.
enum PhotoGroup { ageWeek, ageMonth, month }

/// v1.0 10b "Hiển thị".
enum PhotoShow { all, photos, videos, favorites }

@immutable
class MemoryView {
  const MemoryView({
    this.tab = MemoryTab.photos,
    this.group = MemoryGroup.week,
    this.layout = MemoryLayout.small,
    this.show = MemoryShow.all,
    this.who = MemoryWho.all,
    this.asRelative = false,
    this.photoGroup = PhotoGroup.ageWeek,
    this.photoShow = PhotoShow.all,
  });

  final MemoryTab tab;
  final MemoryGroup group;
  final MemoryLayout layout;
  final MemoryShow show;
  final MemoryWho who;
  final PhotoGroup photoGroup;
  final PhotoShow photoShow;

  /// "Xem như người thân" (10c): what relatives see, nothing private.
  final bool asRelative;

  MemoryView copyWith({
    MemoryTab? tab,
    MemoryGroup? group,
    MemoryLayout? layout,
    MemoryShow? show,
    MemoryWho? who,
    bool? asRelative,
    PhotoGroup? photoGroup,
    PhotoShow? photoShow,
  }) => MemoryView(
    tab: tab ?? this.tab,
    group: group ?? this.group,
    layout: layout ?? this.layout,
    show: show ?? this.show,
    who: who ?? this.who,
    asRelative: asRelative ?? this.asRelative,
    photoGroup: photoGroup ?? this.photoGroup,
    photoShow: photoShow ?? this.photoShow,
  );
}

final memoryViewProvider = NotifierProvider<MemoryViewState, MemoryView>(
  MemoryViewState.new,
);

class MemoryViewState extends Notifier<MemoryView> {
  @override
  MemoryView build() => const MemoryView();

  void set(MemoryView v) => state = v;
  void tab(MemoryTab t) => state = state.copyWith(tab: t);
}

/// Selected media ids, or null when not selecting (10b2).
final memorySelectionProvider = NotifierProvider<MemorySelection, Set<String>?>(
  MemorySelection.new,
);

class MemorySelection extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  void start([String? first]) => state = {?first};
  void end() => state = null;
  void toggle(String id) {
    final s = {...?state};
    if (!s.remove(id)) s.add(id);
    state = s;
  }

  void setAll(Iterable<String> ids, bool on) {
    final s = {...?state};
    on ? s.addAll(ids) : s.removeAll(ids);
    state = s;
  }
}

// ---------- What the screen works with ----------

@immutable
class MemoryCtx {
  const MemoryCtx({
    required this.me,
    required this.baby,
    required this.zone,
    required this.dob,
    required this.isParent,
    required this.parentView,
    required this.now,
    required this.locale,
  });

  final Membership me;
  final Baby? baby;
  final String zone;
  final DateTime? dob;

  /// Cùng nuôi (may add, change, delete).
  final bool isParent;

  /// Shows private things (a parent not previewing as a relative).
  final bool parentView;
  final DateTime now;
  final String locale;

  String get babyId => me.babyId;
  String get nickname => baby?.nickname ?? '';
}

MemoryCtx? memoryCtx(BuildContext context, WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  final isParent = me.role == MemberRole.coParent;
  final dob = me.canViewBabyInfo
      ? ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
      : null;
  final view = ref.watch(memoryViewProvider);
  return MemoryCtx(
    me: me,
    baby: baby,
    zone: baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
    dob: dob,
    isParent: isParent,
    parentView: isParent && !view.asRelative,
    now: ref.watch(careClockProvider).value ?? ref.read(timerClockProvider)(),
    locale: Localizations.localeOf(context).toLanguageTag(),
  );
}

bool _shown(MediaItem i, MemoryView v, bool parentView) {
  if (!i.isReady || i.deleted) return false;
  if (!parentView && i.effectiveAudience != Audience.family) return false;
  if (parentView) {
    if (v.who == MemoryWho.family && i.effectiveAudience != Audience.family) {
      return false;
    }
    if (v.who == MemoryWho.parents && i.effectiveAudience != Audience.parents) {
      return false;
    }
  }
  return switch (v.show) {
    MemoryShow.all => true,
    MemoryShow.photos => !i.isVideo,
    MemoryShow.videos => i.isVideo,
    MemoryShow.milestones => i.milestone != null,
  };
}

/// Ready items the viewer may see under the view options, newest first.
List<MediaItem> visibleMedia(
  List<MediaItem> all,
  MemoryView v,
  bool parentView,
) => [
  for (final i in all)
    if (_shown(i, v, parentView)) i,
];

String countsLabel(AppLocalizations l10n, int photos, int videos, String sep) =>
    [
      if (photos > 0 || videos == 0) l10n.memPhotoCount(photos),
      if (videos > 0) l10n.memVideoCount(videos),
    ].join(sep);

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Hôm nay · 9:20" / "Hôm qua · 19:05" / "Thứ Ba, 6 thg 10" (R-113).
String entryDate(AppLocalizations l10n, MemoryCtx c, DateTime at) {
  final local = inBabyZone(c.zone, at);
  final today = babyToday(c.zone, c.now);
  final day = DateTime(local.year, local.month, local.day);
  final time = DateFormat('H:mm').format(local);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l10n.memTodayAt(time);
  if (diff == 1) return l10n.memYesterdayAt(time);
  return _cap(DateFormat('EEEE, d MMM', c.locale).format(local));
}

/// "Tháng 10, 2026" / "October 2026".
String monthTitle(AppLocalizations l10n, String locale, DateTime month) =>
    locale.startsWith('vi')
    ? l10n.memMonth(month.month, month.year, '')
    : l10n.memMonth(0, month.year, DateFormat.MMMM(locale).format(month));

// ---------- The tab ----------

/// Kỷ niệm (10a Nhật ký, 10b Ảnh; Album and Câu chuyện arrive with S10 / S12). Cùng nuôi see
/// both audiences; relatives what is shared (R-119); caregivers never get this tab (12a).
class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

/// The four tabs are pages side by side: a swipe moves between them, a tap on a title slides
/// to it (owner request 2026-10-11).
class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  late final _pages = PageController(
    initialPage: ref.read(memoryViewProvider).tab.index,
  );

  /// While a tapped title slides the pages, the pages passed on the way are not chosen.
  var _sliding = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _slideTo(MemoryTab t) async {
    // Already there, or the finger is moving the pages (the tab follows the swipe).
    if (!_pages.hasClients || _pages.page?.round() == t.index) return;
    if (context.reduceMotion) {
      _pages.jumpToPage(t.index);
      return;
    }
    _sliding = true;
    try {
      await _pages.animateToPage(
        t.index,
        duration: context.motion(ClMotion.standard),
        curve: ClCurves.standard,
      );
    } finally {
      _sliding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final view = ref.watch(memoryViewProvider);
    final selection = ref.watch(memorySelectionProvider);
    // The upload pill moved to the shell; keep the queue loaded here too without rebuilding the
    // tab on every progress tick.
    ref.listen(uploadQueueProvider, (_, _) {});
    ref.listen(
      memoryViewProvider.select((v) => v.tab),
      (_, t) => unawaited(_slideTo(t)),
    );
    final key = (c.babyId, c.isParent);
    final memories = ref.watch(completeMemoriesProvider(key)).value;
    final media = ref.watch(completeMediaProvider(key)).value;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // The dock sits in a SafeArea and floats 24 above it (ClTabDock), and is 68 tall: the
    // tabs / selection pill float 12 above the dock, and above its "+" (parents' add).
    final pillBottom =
        bottom +
        ClSpace.s6 +
        68 +
        ClSpace.s3 +
        (c.isParent ? ClTabDock.actionExtent : 0);

    final body = PageView.builder(
      key: const Key('memoryPages'),
      controller: _pages,
      // Picking items stays on its tab.
      physics: selection != null ? const NeverScrollableScrollPhysics() : null,
      itemCount: MemoryTab.values.length,
      onPageChanged: (i) {
        if (_sliding) return;
        ref.read(memoryViewProvider.notifier).tab(MemoryTab.values[i]);
      },
      itemBuilder: (_, i) => switch (MemoryTab.values[i]) {
        MemoryTab.journal => JournalView(
          ctx: c,
          memories: memories,
          media: media,
        ),
        MemoryTab.photos => PhotosView(ctx: c, media: media),
        MemoryTab.albums => AlbumsView(ctx: c),
        MemoryTab.stories => StoriesView(ctx: c),
      },
    );

    // In MemoryTab order.
    final labels = [
      for (final t in MemoryTab.values)
        switch (t) {
          MemoryTab.photos => l10n.memPhotos,
          MemoryTab.albums => l10n.memAlbums,
          MemoryTab.journal => l10n.memJournal,
          MemoryTab.stories => l10n.memStories,
        },
    ];
    return Stack(
      children: [
        // The baby header and the title tabs stay pinned; the tab's content scrolls under them
        // (owner feedback 2026-10-11: the big title is the tab bar, no floating bar above the
        // dock).
        Positioned.fill(
          child: ClPinnedHeaderScaffold(
            header: MemoryHeader(
              ctx: c,
              tab: view.tab,
              labels: labels,
              onSelect: (t) => ref.read(memoryViewProvider.notifier).tab(t),
            ),
            body: body,
            scrollDepth: 1,
          ),
        ),
        if (view.asRelative)
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            top: MediaQuery.paddingOf(context).top + ClSpace.s2,
            child: _RelativePreviewBanner(
              onExit: () => ref
                  .read(memoryViewProvider.notifier)
                  .set(view.copyWith(asRelative: false)),
            ),
          ),
        // MM17 "Video đã sẵn sàng" (D-068), above the dock while nothing is selected.
        if (selection == null)
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: pillBottom,
            child: KeepsakeReadyBanner(ctx: c),
          ),
        if (selection != null)
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: pillBottom,
            child: Center(
              child: _SelectionPill(
                count: selection.length,
                onShare: selection.isEmpty
                    ? null
                    : () => showSelectionActions(context, ref, c),
                onDelete: selection.isEmpty || !c.isParent
                    ? null
                    : () => confirmDeleteSelection(context, ref, c),
              ),
            ),
          ),
      ],
    );
  }
}

/// Header: baby switcher, "Cách xem" (10c) and "+" (10a2, parents only), then the tabs as
/// large titles "Nhật ký · Ảnh · Album · Câu chuyện" (the selected one in ink).
class MemoryHeader extends ConsumerWidget {
  const MemoryHeader({
    required this.ctx,
    required this.tab,
    required this.labels,
    required this.onSelect,
    super.key,
  });
  final MemoryCtx ctx;
  final MemoryTab tab;
  final List<String> labels;
  final ValueChanged<MemoryTab> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BabyHeader(
          actions: [
            ClPressable(
              onPressed: () => showViewOptions(context, ref, ctx),
              semanticLabel: l10n.a11yViewOptions,
              child: Container(
                width: ClSpace.tapMin,
                height: ClSpace.tapMin,
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClIcon(ClIcons.sliders, size: 20, color: cl.colors.ink),
              ),
            ),
            if (ctx.isParent) ...[
              const SizedBox(width: ClSpace.s2),
              ClPressable(
                onPressed: () => showAddSheet(context, ref, ctx),
                semanticLabel: l10n.a11yAddMemory,
                child: Container(
                  width: ClSpace.tapMin,
                  height: ClSpace.tapMin,
                  decoration: BoxDecoration(
                    color: cl.colors.mintDeep,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    ClIcons.plus,
                    size: 20,
                    color: cl.colors.onMintDeep,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        _MemoryTitleTabs(tab: tab, labels: labels, onSelect: onSelect),
      ],
    );
  }
}

class _RelativePreviewBanner extends StatelessWidget {
  const _RelativePreviewBanner({required this.onExit});
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, 4, 4, 4),
      decoration: BoxDecoration(
        color: cl.colors.ink,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.eye, size: 18, color: cl.colors.surface),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              l10n.viewAsRelativeBanner,
              style: cl.text.label.copyWith(color: cl.colors.surface),
            ),
          ),
          ClButton(
            label: l10n.viewAsRelativeExit,
            style: ClButtonStyle.plain,
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}

/// The tabs as large titles: the selected one in ink, the others muted; scrolls sideways when
/// the labels outgrow the width and keeps the selected one in view.
class _MemoryTitleTabs extends StatefulWidget {
  const _MemoryTitleTabs({
    required this.tab,
    required this.onSelect,
    required this.labels,
  });
  final MemoryTab tab;
  final ValueChanged<MemoryTab> onSelect;
  final List<String> labels;

  @override
  State<_MemoryTitleTabs> createState() => _MemoryTitleTabsState();
}

class _MemoryTitleTabsState extends State<_MemoryTitleTabs> {
  final _keys = {for (final t in MemoryTab.values) t: GlobalKey()};

  @override
  void didUpdateWidget(_MemoryTitleTabs old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _keys[widget.tab]!.currentContext;
        if (target == null || !mounted) return;
        Scrollable.ensureVisible(
          target,
          alignment: 0.5,
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final duration = context.motion(ClMotion.quick);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final t in MemoryTab.values) ...[
            if (t.index > 0) const SizedBox(width: ClSpace.s4),
            ClPressable(
              key: _keys[t],
              onPressed: () => widget.onSelect(t),
              selected: t == widget.tab,
              semanticLabel: widget.labels[t.index],
              pressedOpacity: 1,
              minSize: Size.zero,
              child: Semantics(
                header: t == widget.tab,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: ClCurves.quick,
                  style: cl.text.title.copyWith(
                    color: t == widget.tab
                        ? cl.colors.ink
                        : cl.colors.inkMuted.withValues(alpha: 0.55),
                  ),
                  child: Text(widget.labels[t.index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 10b2 "Selection pill": share & options · "{n} mục đã chọn" · delete.
class _SelectionPill extends StatelessWidget {
  const _SelectionPill({
    required this.count,
    required this.onShare,
    required this.onDelete,
  });
  final int count;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget round(
      ClIcons icon,
      String label,
      VoidCallback? onTap,
      Color color,
    ) => ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: ClIcon(icon, size: 20, color: color),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          round(ClIcons.upload, l10n.a11yShareOptions, onShare, cl.colors.ink),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Text(l10n.memSelected(count), style: cl.text.bodyStrong),
          ),
          round(
            ClIcons.trash,
            l10n.a11yDeleteSelected,
            onDelete,
            cl.colors.error,
          ),
        ],
      ),
    );
  }
}

// ---------- 10a Nhật ký ----------

class _Group {
  _Group(this.key, this.title, this.subtitle);
  final Object key;
  final String title;
  String subtitle;
  final entries = <(Memory, List<MediaItem>)>[];
}

/// Pull to refresh (Nhật ký, Ảnh): failed uploads try again and the lists re-subscribe.
Future<void> refreshMemories(WidgetRef ref, MemoryCtx c) async {
  final key = (c.babyId, c.isParent);
  unawaited(ref.read(uploadQueueProvider.notifier).retry());
  ref.invalidate(memoriesProvider(key));
  ref.invalidate(mediaProvider(key));
  try {
    await ref
        .read(mediaProvider(key).future)
        .timeout(const Duration(seconds: 8));
  } on Object {
    // Offline: the lists keep what they have and update when back online.
  }
}

/// Lets pull-to-refresh work on Android too (D-004: Android follows the iOS design).
const _pullPhysics = BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
);

class JournalView extends ConsumerWidget {
  const JournalView({
    required this.ctx,
    required this.memories,
    required this.media,
    super.key,
  });

  final MemoryCtx ctx;
  final List<Memory>? memories;
  final List<MediaItem>? media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(memoryViewProvider);
    final c = ctx;
    final favorites =
        ref.watch(favoritesProvider((c.babyId, c.me.uid))).value ?? const {};
    final byId = {for (final m in media ?? const <MediaItem>[]) m.id: m};
    final groups = <Object, _Group>{};
    final order = <_Group>[];

    for (final m in memories ?? const <Memory>[]) {
      if (!m.published || m.deleted) continue;
      if (!c.parentView && m.audience != Audience.family) continue;
      if (c.parentView &&
          view.who == MemoryWho.family &&
          m.audience != Audience.family) {
        continue;
      }
      if (c.parentView &&
          view.who == MemoryWho.parents &&
          m.audience != Audience.parents) {
        continue;
      }
      final items = [
        for (final id in m.mediaIds)
          if (byId[id] case final i? when _shown(i, view, c.parentView)) i,
      ];
      if (m.mediaIds.isNotEmpty && items.isEmpty) continue;
      if (m.isNote && view.show != MemoryShow.all) continue;
      final local = inBabyZone(c.zone, m.occurredAt);
      final day = DateTime(local.year, local.month, local.day);
      final group = view.group == MemoryGroup.week && c.dob == null
          ? MemoryGroup.month
          : view.group;
      final (Object k, String title) = switch (group) {
        MemoryGroup.week => () {
          final w = ageWeekOf(c.dob!, day);
          return (w, w == 0 ? l10n.memBeforeBirth : l10n.memWeek(w));
        }(),
        MemoryGroup.day => (
          day,
          _cap(DateFormat('EEEE, d MMMM', c.locale).format(day)),
        ),
        MemoryGroup.month => (
          DateTime(day.year, day.month),
          monthTitle(l10n, c.locale, day),
        ),
      };
      final g = groups.putIfAbsent(k, () {
        final g = _Group(k, title, '');
        order.add(g);
        return g;
      });
      g.entries.add((m, items));
    }
    for (final g in order) {
      final all = [for (final e in g.entries) ...e.$2];
      final photos = all.where((i) => !i.isVideo).length;
      final videos = all.length - photos;
      final counts = countsLabel(l10n, photos, videos, ', ');
      if (g.key is int && (g.key as int) > 0 && c.dob != null) {
        final r = ageWeekRange(c.dob!, g.key as int);
        g.subtitle = '${_dayRange(c.locale, r.first, r.last)} · $counts';
      } else {
        g.subtitle = counts;
      }
    }

    final bottom = ClTabDock.contentBottomPadding + 88;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: _pullPhysics,
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => refreshMemories(ref, ctx),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s2,
              ClSpace.s4,
              0,
            ),
            sliver: SliverList.list(
              children: [
                if (!c.isParent)
                  Text(
                    l10n.relSubtitle,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                const SizedBox(height: ClSpace.s3),
                if (c.parentView)
                  // 20 pt above (8 + 12) and below (8 + the first week's 12).
                  AutoSaveEntryCard(
                    babyId: c.babyId,
                    name: c.nickname,
                    padding: const EdgeInsets.only(bottom: ClSpace.s2),
                  ),
                if (memories != null && order.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ClSpace.s8),
                    child: ClEmptyState(
                      icon: ClIcons.memories,
                      title: c.isParent
                          ? l10n.memEmptyTitle
                          : l10n.relEmptyTitle,
                      message:
                          view.show != MemoryShow.all ||
                              view.who != MemoryWho.all
                          ? l10n.memNoMatch
                          : c.isParent
                          ? l10n.memEmptyBody(c.nickname)
                          : l10n.relEmptyBody,
                    ),
                  ),
              ],
            ),
          ),
          for (final (n, g) in order.indexed)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                n == 0 ? ClSpace.s3 : 20,
                ClSpace.s4,
                0,
              ),
              // 10a (382:2794): "Tuần thứ 3" left, "1 – 7 tháng 10 · 13 ảnh, 3 video" right.
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            g.title,
                            style: cl.text.bodyStrong.copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Text(
                            g.subtitle,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final (m, items) in g.entries) ...[
                      const SizedBox(height: 10),
                      MemoryEntryCard(
                        memory: m,
                        items: items,
                        myUid: c.me.uid,
                        favorites: favorites,
                        footer: _EntryFooter(memory: m, ctx: c),
                        dateLabel: entryDate(l10n, c, m.occurredAt),
                        onOpen: (i) => openViewer(
                          context,
                          items: items,
                          start: items.indexOf(i),
                          memory: m,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(child: MemoryHistoryMore(ctx: c)),
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }
}

/// "1 – 8 tháng 10" / "28 tháng 9 – 4 tháng 10".
String _dayRange(String locale, DateTime a, DateTime b) {
  final full = DateFormat('d MMMM', locale);
  if (a.month == b.month && a.year == b.year) {
    return '${a.day} – ${full.format(b)}';
  }
  return '${full.format(a)} – ${full.format(b)}';
}

// ---------- 10b Ảnh ----------

class PhotosView extends ConsumerStatefulWidget {
  const PhotosView({required this.ctx, required this.media, super.key});
  final MemoryCtx ctx;
  final List<MediaItem>? media;

  @override
  ConsumerState<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends ConsumerState<PhotosView> {
  final _scroll = ScrollController();

  /// Section anchors: a week or month of age (int) or a calendar month (DateTime).
  final _monthKeys = <Object, GlobalKey>{};
  Object? _visibleMonth;

  /// Ids already on screen while this tab is open: anything new fades in.
  final _seen = <String>{};
  var _primed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackMonth);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Where the grid shows under the pinned filter bar, in global coordinates.
  double get _gridTop {
    final box = context.findRenderObject();
    final top = box is RenderBox && box.attached
        ? box.localToGlobal(Offset.zero).dy
        : 0.0;
    return top + _FilterBar.height;
  }

  void _trackMonth() {
    Object? best;
    // A section is current once its title reaches the pinned filter bar.
    final line = _gridTop + ClSpace.s6;
    for (final e in _monthKeys.entries) {
      final box = e.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y <= line) best = e.key;
    }
    best ??= _monthKeys.keys.firstOrNull;
    if (best != _visibleMonth) setState(() => _visibleMonth = best);
  }

  /// Scrolls the section's title to just under the pinned filter bar.
  void jumpTo(Object section) {
    final box = _monthKeys[section]?.currentContext?.findRenderObject();
    if (box == null || !_scroll.hasClients) return;
    final p = _scroll.position;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0);
    final target = (reveal.offset - _FilterBar.height - ClSpace.s2).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    unawaited(
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: ClCurves.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = widget.ctx;
    final view = ref.watch(memoryViewProvider);
    final selection = ref.watch(memorySelectionProvider);
    final selecting = selection != null;
    final favorites =
        ref.watch(favoritesProvider((c.babyId, c.me.uid))).value ?? const {};
    // v1.0 10b: "Hiển thị" filters by type or Yêu thích; the 10c "Hiện" option is the journal's.
    final base = visibleMedia(
      widget.media ?? const [],
      view.copyWith(show: MemoryShow.all),
      c.parentView,
    );
    final items = [
      for (final i in base)
        if (switch (view.photoShow) {
          PhotoShow.all => true,
          PhotoShow.photos => !i.isVideo,
          PhotoShow.videos => i.isVideo,
          PhotoShow.favorites => favorites.contains(i.id),
        })
          i,
    ];
    // Rebuild when an upload moves on, not on every progress tick.
    ref.watch(uploadQueueProvider.select((q) => _queueKey(q, c.babyId)));
    final landing = c.parentView && view.photoShow != PhotoShow.favorites
        ? landingCells(
            ref.read(uploadQueueProvider),
            widget.media ?? const [],
            view.copyWith(
              show: switch (view.photoShow) {
                PhotoShow.photos => MemoryShow.photos,
                PhotoShow.videos => MemoryShow.videos,
                _ => MemoryShow.all,
              },
            ),
            c.babyId,
          )
        : const <PhotoCell>[];
    // Week or month of age need the birthday; without it, calendar months.
    final mode = c.dob == null ? PhotoGroup.month : view.photoGroup;
    Object sectionOf(DateTime at) {
      final l = inBabyZone(c.zone, at);
      final day = DateTime(l.year, l.month, l.day);
      return switch (mode) {
        PhotoGroup.ageWeek => ageWeekOf(c.dob!, day),
        PhotoGroup.ageMonth => ageMonthOf(c.dob!, day),
        PhotoGroup.month => DateTime(l.year, l.month),
      };
    }

    final months = <Object, List<PhotoCell>>{};
    for (final cell in _merge([
      for (final i in items) PhotoCell.ready(i),
    ], landing)) {
      months.putIfAbsent(sectionOf(cell.at), () => []).add(cell);
    }
    final readyMonths = {
      for (final e in months.entries)
        if (e.key is DateTime && e.value.any((x) => x.item != null))
          e.key as DateTime: [for (final x in e.value) ?x.item],
    };
    String sectionTitle(Object k) => switch (k) {
      final DateTime m => monthTitle(l10n, c.locale, m),
      0 => l10n.memBeforeBirth,
      final int n when mode == PhotoGroup.ageWeek => l10n.memWeek(n),
      final int n => l10n.photoAgeMonth(n),
      _ => '',
    };
    String? sectionRange(Object k) {
      if (k is! int || k == 0 || c.dob == null) return null;
      final r = mode == PhotoGroup.ageWeek
          ? ageWeekRange(c.dob!, k)
          : ageMonthRange(c.dob!, k);
      return _dayRange(c.locale, r.first, r.last);
    }

    String sectionCaption(Object k, List<PhotoCell> cells) {
      // MM17 "18 ảnh, 1 video, 1 thiệp": milestone cards are counted apart (D-068).
      final cards = cells.where((x) => x.item?.generatedKind == 'card').length;
      final counts = [
        countsLabel(
          l10n,
          cells
              .where(
                (x) =>
                    x.item?.isVideo == false && x.item?.generatedKind != 'card',
              )
              .length,
          cells.where((x) => x.item?.isVideo == true).length,
          ', ',
        ),
        if (cards > 0) l10n.ksCardCount(cards),
      ].where((s) => s.isNotEmpty).join(', ');
      final range = sectionRange(k);
      return range == null ? counts : '$range · $counts';
    }

    void gotoSection() {
      if (mode == PhotoGroup.month) {
        showGotoMonth(context, c, readyMonths, jumpTo);
        return;
      }
      final current = _visibleMonth ?? months.keys.firstOrNull;
      showGotoSection(
        context,
        title: mode == PhotoGroup.ageWeek
            ? l10n.photoGotoWeek
            : l10n.photoGotoAgeMonth,
        current: current,
        jumpTo: jumpTo,
        sections: [
          for (final e in months.entries)
            if (e.value.any((x) => x.item != null))
              (
                key: e.key,
                title: sectionTitle(e.key),
                subtitle: [
                  ?sectionRange(e.key),
                  l10n.memItemCount(
                    e.value.where((x) => x.item != null).length,
                  ),
                ].join(' · '),
                cover: e.value.firstWhere((x) => x.item != null).item,
              ),
        ],
      );
    }

    final fresh = <String>{};
    if (widget.media != null) {
      for (final cells in months.values) {
        for (final cell in cells) {
          if (_seen.add(cell.id) && _primed) fresh.add(cell.id);
        }
      }
      _primed = true;
    }
    _monthKeys.removeWhere((k, _) => !months.containsKey(k));
    for (final m in months.keys) {
      _monthKeys.putIfAbsent(m, GlobalKey.new);
    }
    final cols = switch (view.layout) {
      MemoryLayout.small => 4,
      MemoryLayout.large => 2,
      MemoryLayout.list => 1,
    };
    void open(MediaItem i) =>
        openViewer(context, items: items, start: items.indexOf(i));
    void toggle(MediaItem i) =>
        ref.read(memorySelectionProvider.notifier).toggle(i.id);

    Widget chip(
      String label, {
      required bool on,
      VoidCallback? onTap,
      ClIcons? icon,
      ClIcons? trailing,
    }) => ClPressable(
      onPressed: onTap,
      selected: on,
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: on ? cl.colors.ink : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ClIcon(
                icon,
                size: 16,
                color: on ? cl.colors.surface : cl.colors.ink,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: on ? cl.colors.surface : cl.colors.ink,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              ClIcon(
                trailing,
                size: 14,
                color: on ? cl.colors.surface : cl.colors.ink,
              ),
            ],
          ],
        ),
      ),
    );

    final scrubber = _visibleMonth ?? months.keys.firstOrNull;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: _pullPhysics,
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => refreshMemories(ref, widget.ctx),
              ),
              // The filters stay at the top while the grid scrolls under them (owner, 2026-10-11).
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBar(
                  Row(
                    children: [
                      // 10b: "Theo tuần tuổi ▾" (grouping) and "Ảnh & video ▾" (type).
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterPill(
                                icon: ClIcons.cake,
                                label: switch (mode) {
                                  PhotoGroup.ageWeek => l10n.photoPillWeek,
                                  PhotoGroup.ageMonth => l10n.photoPillAgeMonth,
                                  PhotoGroup.month => l10n.photoPillMonth,
                                },
                                onTap: c.dob == null
                                    ? null
                                    : () => showPhotoGroupSheet(context, ref),
                              ),
                              const SizedBox(width: 6),
                              _FilterPill(
                                icon: ClIcons.camera,
                                label: switch (view.photoShow) {
                                  PhotoShow.all => l10n.photoShowAll,
                                  PhotoShow.photos => l10n.photoShowPhotos,
                                  PhotoShow.videos => l10n.photoShowVideos,
                                  PhotoShow.favorites =>
                                    l10n.photoShowFavorites,
                                },
                                onTap: () => showPhotoShowSheet(
                                  context,
                                  ref,
                                  items: base,
                                  favorites: favorites,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      // "Chọn" is not on 10b: a round icon keeps room for the two pills.
                      if (selecting)
                        chip(
                          l10n.actionDone,
                          on: true,
                          onTap: () =>
                              ref.read(memorySelectionProvider.notifier).end(),
                        )
                      else if (c.parentView)
                        ClPressable(
                          key: const Key('photoSelect'),
                          onPressed: () => ref
                              .read(memorySelectionProvider.notifier)
                              .start(),
                          semanticLabel: l10n.memSelect,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cl.colors.surface2,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ClIcon(
                              ClIcons.check,
                              size: 16,
                              color: cl.colors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  0,
                  ClSpace.s4,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    // AS01: the way into Tự lưu (D-066), for parents.
                    if (c.parentView)
                      // 4 pt left under the pills + 12 = the 16 pt the section header adds below.
                      AutoSaveEntryCard(
                        babyId: c.babyId,
                        name: c.nickname,
                        padding: const EdgeInsets.only(top: ClSpace.s3),
                      ),
                    const EngagementShelf(),
                    // MM01 "Tạo từ kỷ niệm" (D-068); shows only in the beta, for parents.
                    KeepsakeCreateSection(ctx: c),
                    if (landing.isNotEmpty) _LandingLine(count: landing.length),
                    if (widget.media != null &&
                        items.isEmpty &&
                        landing.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s8),
                        child: ClEmptyState(
                          icon: ClIcons.memories,
                          title: l10n.memEmptyTitle,
                          message:
                              view.show != MemoryShow.all ||
                                  view.who != MemoryWho.all
                              ? l10n.memNoMatch
                              : l10n.memPhotosEmpty(c.nickname),
                        ),
                      ),
                  ],
                ),
              ),
              for (final e in months.entries) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s4,
                    ClSpace.s4,
                    ClSpace.s2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      key: _monthKeys[e.key],
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            sectionTitle(e.key),
                            style: cl.text.headline.copyWith(fontSize: 18),
                          ),
                        ),
                        if (selecting)
                          ClPressable(
                            onPressed: () {
                              final ids = [
                                for (final cell in e.value)
                                  if (cell.item != null) cell.id,
                              ];
                              final all = ids.every(selection.contains);
                              ref
                                  .read(memorySelectionProvider.notifier)
                                  .setAll(ids, !all);
                            },
                            semanticLabel: mode == PhotoGroup.month
                                ? l10n.memSelectMonth
                                : l10n.photoSelectSection,
                            child: Text(
                              mode == PhotoGroup.month
                                  ? l10n.memSelectMonth
                                  : l10n.photoSelectSection,
                              style: cl.text.label.copyWith(
                                color: cl.colors.mintText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: Text(
                              sectionCaption(e.key, e.value),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                  sliver: view.layout == MemoryLayout.list
                      ? SliverList.separated(
                          itemCount: e.value
                              .where((x) => x.item != null)
                              .length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: ClSpace.s2),
                          itemBuilder: (_, n) {
                            final i = [for (final x in e.value) ?x.item][n];
                            return _ListRow(
                              item: i,
                              ctx: c,
                              selecting: selecting,
                              selected: selection?.contains(i.id) ?? false,
                              onTap: () => selecting ? toggle(i) : open(i),
                            );
                          },
                        )
                      : SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemCount: e.value.length,
                          // Cells follow their item when others land before them.
                          findChildIndexCallback: (key) {
                            final at = e.value.indexWhere(
                              (x) => ValueKey(x.id) == key,
                            );
                            return at < 0 ? null : at;
                          },
                          itemBuilder: (_, n) {
                            final cell = e.value[n];
                            final i = cell.item;
                            return _GridCell(
                              key: ValueKey(cell.id),
                              appear: fresh.contains(cell.id),
                              readyThumb: i?.thumbPath,
                              landing: i != null
                                  ? null
                                  : _LandingTile(
                                      path: cell.local,
                                      waiting: cell.waiting,
                                      onTap: () => openUploads(context, ref, c),
                                    ),
                              ready: i == null
                                  ? null
                                  : MediaTile(
                                      item: i,
                                      favorite: favorites.contains(i.id),
                                      selecting: selecting,
                                      selected:
                                          selection?.contains(i.id) ?? false,
                                      onTap: () =>
                                          selecting ? toggle(i) : open(i),
                                      onLongPress: c.parentView && !selecting
                                          ? () => ref
                                                .read(
                                                  memorySelectionProvider
                                                      .notifier,
                                                )
                                                .start(i.id)
                                          : null,
                                    ),
                            );
                          },
                        ),
                ),
              ],
              SliverToBoxAdapter(child: MemoryHistoryMore(ctx: c)),
              SliverToBoxAdapter(
                child: SizedBox(height: ClTabDock.contentBottomPadding + 88),
              ),
            ],
          ),
          if (scrubber != null && !selecting)
            Positioned(
              right: ClSpace.s4,
              bottom: MediaQuery.paddingOf(context).bottom + 160,
              child: ClPressable(
                key: const Key('photoScrubber'),
                onPressed: gotoSection,
                semanticLabel: mode == PhotoGroup.month
                    ? l10n.gotoTitle
                    : mode == PhotoGroup.ageWeek
                    ? l10n.photoGotoWeek
                    : l10n.photoGotoAgeMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                    boxShadow: cl.shadows.card,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        switch (scrubber) {
                          final int n when mode == PhotoGroup.ageWeek =>
                            l10n.photoScrubWeek(n),
                          final int n => l10n.photoScrubAgeMonth(n),
                          final DateTime m when c.locale.startsWith('vi') =>
                            l10n.scrubberMonth(m.month, m.year, ''),
                          final DateTime m => l10n.scrubberMonth(
                            0,
                            m.year,
                            DateFormat.MMM(c.locale).format(m),
                          ),
                          _ => '',
                        },
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ClIcon(
                        ClIcons.chevronDown,
                        size: 16,
                        color: cl.colors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 10b filter pill: surface, separator border, icon · label · chevron.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.icon, required this.label, this.onTap});
  final ClIcons icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(color: cl.colors.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 14, color: cl.colors.ink),
            const SizedBox(width: 5),
            Text(
              label,
              style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 3),
              ClIcon(ClIcons.chevronDown, size: 12, color: cl.colors.ink),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Ảnh filters ("Theo tuần tuổi ▾", "Ảnh & video ▾", select), pinned on the screen colour.
class _FilterBar extends SliverPersistentHeaderDelegate {
  _FilterBar(this.child);
  final Widget child;

  /// The row is a tap target tall (the pills are 36 inside 44), with the screen's top gap.
  static const double height = ClSpace.tapMin + ClSpace.s2;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: context.cl.colors.cloud,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            0,
          ),
          child: child,
        ),
      );

  // The row is rebuilt with the screen (selection, filters).
  @override
  bool shouldRebuild(_FilterBar old) => true;
}

/// A cell of the Ảnh grid: a ready item, or one still landing (sent from this phone, or
/// being processed) shown from the copy on the device until the server's arrives.
@immutable
class PhotoCell {
  PhotoCell.ready(MediaItem this.item)
    : id = item.id,
      at = item.captureAt,
      local = null,
      waiting = false;
  const PhotoCell.landing({
    required this.id,
    required this.at,
    this.local,
    this.waiting = false,
  }) : item = null;

  final String id;
  final DateTime at;
  final MediaItem? item;

  /// The picture on this phone (thumbnail, photo or video poster), if still there.
  final String? local;

  /// Held (Wi-Fi only, paused, no session yet): a clock instead of a spinner.
  final bool waiting;
}

String _queueKey(QueueView q, String babyId) => [
  for (final b in q.batches)
    if (b.babyId == babyId)
      for (final i in b.items) '${i.mediaId}:${i.state.name}:${i.thumbPath}',
].join(',');

bool _onTheWay(QueueState s) => switch (s) {
  QueueState.pendingSession ||
  QueueState.queued ||
  QueueState.waitingWifi ||
  QueueState.uploading ||
  QueueState.paused ||
  QueueState.uploaded => true,
  QueueState.waitingQuota ||
  QueueState.failed ||
  QueueState.unreadable ||
  QueueState.cancelled => false,
};

bool _landingShown(bool video, Audience audience, MemoryView v) {
  final who = switch (v.who) {
    MemoryWho.all => true,
    MemoryWho.family => audience == Audience.family,
    MemoryWho.parents => audience == Audience.parents,
  };
  return who &&
      switch (v.show) {
        MemoryShow.all => true,
        MemoryShow.photos => !video,
        MemoryShow.videos => video,
        MemoryShow.milestones => false,
      };
}

/// What is on its way into Ảnh (parents only), newest first: items this phone is sending, and
/// items it has sent that the server is still processing. Without them an upload "finished" in
/// the pill but was missing from the grid for a while.
///
/// Only this phone's queue counts. A server item left "uploading" with nothing behind it here
/// (an abandoned or removed upload, released by the server after 24 h) is not landing, and
/// neither is a sent item whose server copy is gone (deleted) — both once showed as "Đang
/// thêm 3 mục…" that never ended.
List<PhotoCell> landingCells(
  QueueView queue,
  List<MediaItem> media,
  MemoryView v,
  String babyId,
) {
  final queued = {
    for (final b in queue.batches)
      if (b.babyId == babyId && !b.dismissed)
        for (final i in b.items) i.mediaId: (b, i),
  };
  String? local(QueueItem i) => [
    i.thumbPath,
    if (i.isVideo) i.posterPath else i.localPath,
  ].nonNulls.where((p) => File(p).existsSync()).firstOrNull;
  final cells = <PhotoCell>[];
  final docs = <String>{};
  for (final m in media) {
    docs.add(m.id);
    if (m.status != MediaStatus.uploading || m.deleted) continue;
    final q = queued[m.id];
    if (q == null || !_onTheWay(q.$2.state) || q.$1.refused) continue;
    if (!_landingShown(m.isVideo, m.effectiveAudience, v)) continue;
    cells.add(
      PhotoCell.landing(
        id: m.id,
        at: m.captureAt,
        local: local(q.$2),
        waiting: _held(q.$2.state),
      ),
    );
  }
  for (final (b, i) in queued.values) {
    if (docs.contains(i.mediaId) || !_onTheWay(i.state) || b.refused) continue;
    // Sent, yet no live server item: deleted or released since, not on its way.
    if (i.state == QueueState.uploaded && b.sessionCreated) continue;
    final audience = b.request['audience'] == Audience.family.name
        ? Audience.family
        : Audience.parents;
    if (!_landingShown(i.isVideo, audience, v)) continue;
    cells.add(
      PhotoCell.landing(
        id: i.mediaId,
        at: i.captureAt,
        local: local(i),
        waiting: _held(i.state),
      ),
    );
  }
  cells.sort((a, b) => b.at.compareTo(a.at));
  return cells;
}

bool _held(QueueState s) =>
    s == QueueState.waitingWifi ||
    s == QueueState.paused ||
    s == QueueState.pendingSession;

/// Two newest-first lists as one, keeping each list's own order.
List<PhotoCell> _merge(List<PhotoCell> a, List<PhotoCell> b) {
  final out = <PhotoCell>[];
  var i = 0;
  var j = 0;
  while (i < a.length || j < b.length) {
    if (j >= b.length || (i < a.length && !b[j].at.isAfter(a[i].at))) {
      out.add(a[i++]);
    } else {
      out.add(b[j++]);
    }
  }
  return out;
}

/// "Đang thêm 3 mục…" over the grid while uploads land, so a finished upload that is not in
/// the grid yet is never a surprise.
class _LandingLine extends StatelessWidget {
  const _LandingLine({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cl.colors.mintText,
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              AppLocalizations.of(context).memLanding(count),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// An item still landing: the picture from this phone, dimmed, with a spinner (or a clock
/// while held). A tap opens the upload queue.
class _LandingTile extends StatelessWidget {
  const _LandingTile({
    required this.path,
    required this.waiting,
    required this.onTap,
  });
  final String? path;
  final bool waiting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final path = this.path;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: AppLocalizations.of(context).memLanding(1),
      minSize: Size.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cl.colors.surface2),
            if (path != null)
              Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 360,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
            Center(
              child: waiting
                  ? const ClIcon(ClIcons.clock, size: 20, color: Colors.white)
                  : const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One grid cell. A new cell fades and grows in; a landing item turns into the server's once
/// that picture is loaded, cross-fading in place, so the grid never blinks.
class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.appear,
    this.ready,
    this.readyThumb,
    this.landing,
    super.key,
  });
  final bool appear;
  final Widget? ready;
  final String? readyThumb;
  final Widget? landing;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell>
    with SingleTickerProviderStateMixin {
  late final _in = AnimationController(
    vsync: this,
    duration: ClMotion.standard,
    value: widget.appear ? 0 : 1,
  );
  late var _showReady = widget.ready != null;

  @override
  void initState() {
    super.initState();
    if (widget.appear) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.reduceMotion ? _in.value = 1 : unawaited(_in.forward());
      });
    }
  }

  @override
  void didUpdateWidget(_GridCell old) {
    super.didUpdateWidget(old);
    if (widget.ready == null) {
      _showReady = false;
    } else if (!_showReady) {
      final thumb = widget.readyThumb;
      if (thumb == null) {
        _showReady = true;
      } else {
        // Keep the phone's picture until the server's is decoded.
        unawaited(
          precacheImage(
            StorageImage(thumb),
            context,
            onError: (_, _) {},
          ).whenComplete(() {
            if (mounted) setState(() => _showReady = true);
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.ready;
    final child = _showReady && ready != null
        ? KeyedSubtree(key: const ValueKey('ready'), child: ready)
        : KeyedSubtree(
            key: const ValueKey('landing'),
            child: widget.landing ?? ready ?? const SizedBox.shrink(),
          );
    final curved = CurvedAnimation(parent: _in, curve: ClCurves.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.88, end: 1.0).animate(curved),
        child: AnimatedSwitcher(
          duration: context.motion(ClMotion.standard),
          child: child,
        ),
      ),
    );
  }
}

/// "Danh sách" layout (10c).
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.ctx,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });
  final MediaItem item;
  final MemoryCtx ctx;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: MediaTile(
              item: item,
              selecting: selecting,
              selected: selected,
              onTap: onTap,
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryDate(l10n, ctx, item.captureAt),
                  style: cl.text.label,
                ),
                if (item.milestone != null) ...[
                  const SizedBox(height: 4),
                  MilestoneChip(milestone: item.milestone!, compact: true),
                ],
              ],
            ),
          ),
          AudienceIcon(audience: item.effectiveAudience),
        ],
      ),
    );
  }
}

/// Loves under an entry (parents see names) and, for relatives, "♡ Thương · ✉ Nhắn ba mẹ"
/// (11c, D-034).
class _EntryFooter extends StatelessWidget {
  const _EntryFooter({required this.memory, required this.ctx});
  final Memory memory;
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final line = LovesLine(
      target: LoveTarget.memory,
      targetId: memory.id,
      count: memory.loveCount,
    );
    if (ctx.isParent) return line;
    return Row(
      children: [
        LoveButton(
          target: LoveTarget.memory,
          targetId: memory.id,
          count: memory.loveCount,
        ),
        const SizedBox(width: ClSpace.s2),
        ClPressable(
          onPressed: () => showMessageComposer(
            context,
            kind: MessageContext.memory,
            contextId: memory.id,
          ),
          semanticLabel: l10n.messageParents,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClIcon(ClIcons.mail, size: 18, color: cl.colors.ink),
                const SizedBox(width: 6),
                Text(
                  l10n.messageParents,
                  style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens what an upload pill points at: Dung lượng when everything left waits for space (13f),
/// otherwise the queue (10i).
void openUploads(BuildContext context, WidgetRef ref, MemoryCtx c) {
  final open = [
    for (final b in ref.read(uploadQueueProvider).batches)
      if (b.babyId == c.babyId)
        for (final i in b.items)
          if (i.state != QueueState.uploaded &&
              i.state != QueueState.cancelled &&
              i.state != QueueState.unreadable)
            i,
  ];
  if (open.isNotEmpty &&
      open.every((i) => i.state == QueueState.waitingQuota)) {
    context.push(Routes.meStorage);
  } else {
    showQueueSheet(context, ref, c);
  }
}

/// The upload pill (382:2807) floating above the tab dock on every tab, so an upload started
/// from anywhere stays visible (owner, 2026-10-11, D-048). A finished batch shows its result for
/// a few seconds and then steps aside; it stays in the queue until dismissed there.
class GlobalUploadPill extends ConsumerStatefulWidget {
  const GlobalUploadPill({super.key});

  @override
  ConsumerState<GlobalUploadPill> createState() => _GlobalUploadPillState();
}

class _GlobalUploadPillState extends ConsumerState<GlobalUploadPill> {
  static const _showDone = Duration(seconds: 4);
  final _hidden = <String>{};
  final _timers = <String, Timer>{};

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watched first and always: this keeps the queue loaded and running from app start.
    final queue = ref.watch(uploadQueueProvider);
    final c = memoryCtx(context, ref);
    // Parents upload; the selection pill takes this place while picking in Kỷ niệm.
    if (c == null ||
        !c.isParent ||
        ref.watch(memorySelectionProvider) != null) {
      return const SizedBox.shrink();
    }
    for (final b in queue.batches) {
      if (b.babyId != c.babyId || !b.done || _hidden.contains(b.batchId)) {
        continue;
      }
      // Shown once already (an earlier app session): stay hidden, no second 4 s show.
      if (b.resultShown) {
        _hidden.add(b.batchId);
        continue;
      }
      _timers.putIfAbsent(
        b.batchId,
        () => Timer(_showDone, () {
          if (mounted) setState(() => _hidden.add(b.batchId));
          unawaited(
            ref.read(uploadQueueProvider.notifier).markResultShown(b.batchId),
          );
        }),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClRadius.card - 4),
        boxShadow: context.cl.shadows.card,
      ),
      child: UploadPill(
        babyId: c.babyId,
        hidden: _hidden,
        onOpen: () => openUploads(context, ref, c),
      ),
    );
  }
}

/// The end of the loaded window is not the end of a child's history (MEM-02).
class MemoryHistoryMore extends ConsumerWidget {
  const MemoryHistoryMore({required this.ctx, super.key});
  final MemoryCtx ctx;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (ctx.babyId, ctx.isParent);
    final tail = ref.watch(historyTailProvider.select((s) => s[key]));
    final media = ref.watch(mediaProvider(key)).value;
    final memories = ref.watch(memoriesProvider(key)).value;
    if (media == null || memories == null) return const SizedBox.shrink();
    final initialHasMore =
        media.length >= MemoryRepository.historyPageSize ||
        memories.length >= MemoryRepository.historyPageSize;
    if (!initialHasMore && tail == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    if (tail?.mediaEnd == true && tail?.memoryEnd == true) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l.historyEnd, textAlign: TextAlign.center),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClButton(
        label: tail?.error == true ? l.historyLoadFailed : l.historyLoadEarlier,
        loading: tail?.loading ?? false,
        onPressed: tail?.loading == true
            ? null
            : () => ref.read(historyTailProvider.notifier).loadMore(key),
      ),
    );
  }
}
