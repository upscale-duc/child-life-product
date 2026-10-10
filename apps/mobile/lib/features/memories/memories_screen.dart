import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import 'album_models.dart';
import 'album_screens.dart';
import 'media_viewer.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_sheets.dart';
import 'memory_widgets.dart';
import 'social_widgets.dart';
import 'upload_queue.dart';
import '../stories/stories_view.dart';

// ---------- View state (10c) and selection (10b2) ----------

enum MemoryTab { journal, photos, albums, stories }

enum MemoryGroup { day, week, month }

enum MemoryLayout { small, large, list }

enum MemoryShow { all, photos, videos, milestones }

enum MemoryWho { all, family, parents }

@immutable
class MemoryView {
  const MemoryView({
    this.tab = MemoryTab.journal,
    this.group = MemoryGroup.week,
    this.layout = MemoryLayout.small,
    this.show = MemoryShow.all,
    this.who = MemoryWho.all,
    this.asRelative = false,
  });

  final MemoryTab tab;
  final MemoryGroup group;
  final MemoryLayout layout;
  final MemoryShow show;
  final MemoryWho who;

  /// "Xem như người thân" (10c): what relatives see, nothing private.
  final bool asRelative;

  MemoryView copyWith({
    MemoryTab? tab,
    MemoryGroup? group,
    MemoryLayout? layout,
    MemoryShow? show,
    MemoryWho? who,
    bool? asRelative,
  }) => MemoryView(
    tab: tab ?? this.tab,
    group: group ?? this.group,
    layout: layout ?? this.layout,
    show: show ?? this.show,
    who: who ?? this.who,
    asRelative: asRelative ?? this.asRelative,
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
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final view = ref.watch(memoryViewProvider);
    final selection = ref.watch(memorySelectionProvider);
    final key = (c.babyId, c.isParent);
    final memories = ref.watch(memoriesProvider(key)).value;
    final media = ref.watch(mediaProvider(key)).value;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final pillBottom = (bottom > 0 ? bottom : ClSpace.s6) + 68 + ClSpace.s3;

    final body = switch (view.tab) {
      MemoryTab.journal => JournalView(
        ctx: c,
        memories: memories,
        media: media,
      ),
      MemoryTab.photos => PhotosView(ctx: c, media: media),
      MemoryTab.albums => AlbumsView(ctx: c),
      MemoryTab.stories => StoriesView(ctx: c),
    };

    return ColoredBox(
      color: cl.colors.cloud,
      child: Stack(
        children: [
          Positioned.fill(child: body),
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
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: pillBottom,
            child: Center(
              child: selection != null
                  ? _SelectionPill(
                      count: selection.length,
                      onShare: selection.isEmpty
                          ? null
                          : () => showSelectionActions(context, ref, c),
                      onDelete: selection.isEmpty || !c.isParent
                          ? null
                          : () => confirmDeleteSelection(context, ref, c),
                    )
                  : _MemoryTabs(
                      tab: view.tab,
                      onSelect: (t) =>
                          ref.read(memoryViewProvider.notifier).tab(t),
                      labels: [
                        l10n.memJournal,
                        l10n.memPhotos,
                        l10n.memAlbums,
                        l10n.memStories,
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header: baby switcher, "Cách xem" (10c) and "+" (10a2, parents only).
class MemoryHeader extends ConsumerWidget {
  const MemoryHeader({required this.ctx, required this.title, super.key});
  final MemoryCtx ctx;
  final String title;

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
        const SizedBox(height: ClSpace.s4),
        Semantics(header: true, child: Text(title, style: cl.text.largeTitle)),
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

/// Floating "Nhật ký · Ảnh · Album · Câu chuyện" (layer "Memory tabs (floating)").
class _MemoryTabs extends StatelessWidget {
  const _MemoryTabs({
    required this.tab,
    required this.onSelect,
    required this.labels,
  });
  final MemoryTab tab;
  final ValueChanged<MemoryTab> onSelect;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in MemoryTab.values)
            ClPressable(
              onPressed: () => onSelect(t),
              selected: t == tab,
              semanticLabel: labels[t.index],
              haptic: false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s3,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: t == tab ? cl.colors.ink : null,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  labels[t.index],
                  style: cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t == tab ? cl.colors.surface : cl.colors.inkMuted,
                  ),
                ),
              ),
            ),
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

    final bottom = ClTabDock.contentBottomPadding + 64;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s2,
              ClSpace.s4,
              0,
            ),
            sliver: SliverList.list(
              children: [
                MemoryHeader(
                  ctx: c,
                  title: c.isParent ? l10n.memJournal : l10n.tabMemories,
                ),
                if (!c.isParent)
                  Text(
                    l10n.relSubtitle,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                if (c.isParent) ...[
                  const SizedBox(height: ClSpace.s3),
                  UploadPill(
                    babyId: c.babyId,
                    onOpen: () {
                      // 13f "Hết dung lượng · chạm để xem" opens Dung lượng (13d).
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
                          open.every(
                            (i) => i.state == QueueState.waitingQuota,
                          )) {
                        context.push(Routes.meStorage);
                      } else {
                        showQueueSheet(context, ref, c);
                      }
                    },
                  ),
                ],
                const SizedBox(height: ClSpace.s3),
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
          for (final g in order)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s3,
                ClSpace.s4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(left: ClSpace.s3),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: cl.colors.mint, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(g.title, style: cl.text.headline),
                      Text(
                        g.subtitle,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      for (final (m, items) in g.entries) ...[
                        const SizedBox(height: ClSpace.s3),
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
            ),
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
  final _monthKeys = <DateTime, GlobalKey>{};
  DateTime? _visibleMonth;

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

  void _trackMonth() {
    DateTime? best;
    for (final e in _monthKeys.entries) {
      final box = e.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y <= 160) best = e.key;
    }
    best ??= _monthKeys.keys.firstOrNull;
    if (best != _visibleMonth) setState(() => _visibleMonth = best);
  }

  void jumpTo(DateTime month) {
    final ctx = _monthKeys[month]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
      );
    }
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
    final items = visibleMedia(widget.media ?? const [], view, c.parentView);
    final months = <DateTime, List<MediaItem>>{};
    for (final i in items) {
      final l = inBabyZone(c.zone, i.captureAt);
      months.putIfAbsent(DateTime(l.year, l.month), () => []).add(i);
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
      haptic: false,
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
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    MemoryHeader(ctx: c, title: l10n.memPhotos),
                    const SizedBox(height: ClSpace.s3),
                    Row(
                      children: [
                        chip(l10n.filterAll, on: true, onTap: () {}),
                        const SizedBox(width: ClSpace.s2),
                        chip(
                          l10n.memFilterMonth,
                          on: false,
                          trailing: ClIcons.chevronDown,
                          onTap: months.isEmpty
                              ? null
                              : () => showGotoMonth(context, c, months, jumpTo),
                        ),
                        const Spacer(),
                        if (c.parentView || selecting)
                          chip(
                            selecting ? l10n.actionDone : l10n.memSelect,
                            on: selecting,
                            icon: selecting ? null : ClIcons.check,
                            onTap: () {
                              final sel = ref.read(
                                memorySelectionProvider.notifier,
                              );
                              selecting ? sel.end() : sel.start();
                            },
                          ),
                      ],
                    ),
                    if (widget.media != null && items.isEmpty)
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
                            monthTitle(l10n, c.locale, e.key),
                            style: cl.text.headline,
                          ),
                        ),
                        if (selecting)
                          ClPressable(
                            onPressed: () {
                              final ids = [for (final i in e.value) i.id];
                              final all = ids.every(selection.contains);
                              ref
                                  .read(memorySelectionProvider.notifier)
                                  .setAll(ids, !all);
                            },
                            semanticLabel: l10n.memSelectMonth,
                            haptic: false,
                            child: Text(
                              l10n.memSelectMonth,
                              style: cl.text.label.copyWith(
                                color: cl.colors.mintText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            countsLabel(
                              l10n,
                              e.value.where((i) => !i.isVideo).length,
                              e.value.where((i) => i.isVideo).length,
                              ' · ',
                            ),
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
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
                          itemCount: e.value.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: ClSpace.s2),
                          itemBuilder: (_, n) {
                            final i = e.value[n];
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
                          itemBuilder: (_, n) {
                            final i = e.value[n];
                            return MediaTile(
                              item: i,
                              favorite: favorites.contains(i.id),
                              selecting: selecting,
                              selected: selection?.contains(i.id) ?? false,
                              onTap: () => selecting ? toggle(i) : open(i),
                              onLongPress: c.parentView && !selecting
                                  ? () => ref
                                        .read(memorySelectionProvider.notifier)
                                        .start(i.id)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: ClTabDock.contentBottomPadding + 64),
              ),
            ],
          ),
          if (scrubber != null && !selecting)
            Positioned(
              right: ClSpace.s4,
              bottom: MediaQuery.paddingOf(context).bottom + 160,
              child: ClPressable(
                onPressed: () => showGotoMonth(context, c, months, jumpTo),
                semanticLabel: l10n.gotoTitle,
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
                        c.locale.startsWith('vi')
                            ? l10n.scrubberMonth(
                                scrubber.month,
                                scrubber.year,
                                '',
                              )
                            : l10n.scrubberMonth(
                                0,
                                scrubber.year,
                                DateFormat.MMM(c.locale).format(scrubber),
                              ),
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
      haptic: false,
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
