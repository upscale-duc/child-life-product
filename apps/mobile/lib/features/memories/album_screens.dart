import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart';
import 'album_models.dart';
import '../care/care_models.dart';
import '../stories/story_models.dart';
import 'media_bytes.dart';
import 'media_viewer.dart';
import 'memories_screen.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_sheets.dart' show AudienceCards;
import 'memory_widgets.dart';
import 'social_widgets.dart';
import 'upload_queue.dart';

/// Albums (S10): 10d / 11e tab, 10e / 10e2 / 11f detail, milestone collections, 10e3–10e10
/// options, 10h5 / 10b3 album picker and "Album mới".

const favoritesKey = 'favorites';
String milestoneKey(String id) => 'ms:$id';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Ready items I can see, newest first (the album pages' source).
List<MediaItem> _visible(WidgetRef ref, MemoryCtx c) => visibleMedia(
  ref.watch(mediaProvider((c.babyId, c.isParent))).value ?? const [],
  const MemoryView(),
  c.parentView,
);

Set<String> _favorites(WidgetRef ref, MemoryCtx c) =>
    ref.watch(favoritesProvider((c.babyId, c.me.uid))).value ?? const {};

List<Album> _albums(WidgetRef ref, MemoryCtx c) => [
  for (final a
      in ref.watch(albumsProvider((c.babyId, c.isParent))).value ??
          const <Album>[])
    if (c.parentView || a.audience == Audience.family) a,
];

/// "cập nhật hôm qua" / "cập nhật 5 thg 10".
String _when(AppLocalizations l10n, MemoryCtx c, DateTime? at) {
  if (at == null) return '';
  final local = inBabyZone(c.zone, at);
  final today = babyToday(c.zone, c.now);
  final diff = today
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  return switch (diff) {
    0 => l10n.dayToday,
    1 => l10n.dayYesterday,
    _ => DateFormat('d MMM', c.locale).format(local),
  };
}

// ---------- 10d / 11e tab ----------

/// A cover with no picture: the soft mint of the brand with the album mark, and for an empty
/// album the way in ("Thêm ảnh" for parents), instead of a blank grey square.
class _EmptyCover extends StatelessWidget {
  const _EmptyCover({required this.empty, required this.canAdd});
  final bool empty;
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: cl.colors.mintSoft,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(
                empty && canAdd ? ClIcons.plus : ClIcons.memories,
                size: 24,
                color: cl.colors.mintText,
              ),
            ),
            if (empty && canAdd) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.albCoverAdd,
                style: cl.text.label.copyWith(
                  color: cl.colors.mintText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AlbumsView extends ConsumerWidget {
  const AlbumsView({required this.ctx, super.key});
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = ctx;
    final albums = _albums(ref, c);
    final media = _visible(ref, c);
    final byId = {for (final m in media) m.id: m};
    final favs = [
      for (final m in media)
        if (_favorites(ref, c).contains(m.id)) m,
    ];
    final milestones = <String, (MilestoneRef, List<MediaItem>)>{};
    for (final m in media) {
      final ms = m.milestone;
      if (ms == null) continue;
      milestones.putIfAbsent(ms.id, () => (ms, [])).$2.add(m);
    }

    Widget card({
      required String name,
      required String? coverPath,
      required Widget badge,
      required String meta,
      required VoidCallback onTap,
      bool empty = false,
      bool addable = true,
    }) => ClPressable(
      onPressed: onTap,
      semanticLabel: '$name. $meta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.card - 6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverPath != null) ...[
                    ColoredBox(color: cl.colors.surface2),
                    Image(image: StorageImage(coverPath), fit: BoxFit.cover),
                  ] else
                    _EmptyCover(empty: empty, canAdd: c.parentView && addable),
                  Positioned(left: 8, top: 8, child: badge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cl.text.bodyStrong,
          ),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );

    Widget badge(ClIcons icon) => Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClIcon(icon, size: 14, color: Colors.white),
    );

    final favMeta = countsLabel(
      l10n,
      favs.where((i) => !i.isVideo).length,
      favs.where((i) => i.isVideo).length,
      ' · ',
    );
    final cards = <Widget>[
      card(
        name: l10n.albFavorites,
        coverPath: favs.firstOrNull?.thumbPath,
        badge: badge(ClIcons.lock),
        empty: favs.isEmpty,
        // Filled with the bookmark on a photo, not by adding to it.
        addable: false,
        meta: favs.isEmpty
            ? l10n.albCoverEmptyMeta
            : c.parentView
            ? favMeta
            : '$favMeta · ${l10n.albFavoritesMine}',
        onTap: () => context.push('${Routes.memories}/album/$favoritesKey'),
      ),
      for (final a in albums)
        card(
          name: a.name,
          coverPath: byId[a.coverMediaId]?.thumbPath,
          badge: badge(
            a.audience == Audience.family ? ClIcons.family : ClIcons.lock,
          ),
          empty: a.photos + a.videos == 0,
          // "Chưa có ảnh" instead of "0 ảnh".
          meta: a.photos + a.videos == 0
              ? l10n.albCoverEmptyMeta
              : countsLabel(l10n, a.photos, a.videos, ' · '),
          onTap: () => context.push('${Routes.memories}/album/${a.id}'),
        ),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s2,
          ClSpace.s4,
          ClTabDock.contentBottomPadding + 88,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.isParent
                      ? l10n.albCount(albums.length)
                      : l10n.albShared(albums.length),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              if (c.parentView)
                ClButton(
                  label: l10n.albNew,
                  icon: ClIcons.plus,
                  style: ClButtonStyle.tinted,
                  onPressed: () => showNewAlbumSheet(context, ref, c),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ClSpace.s4,
            crossAxisSpacing: ClSpace.s3,
            childAspectRatio: 0.74,
            children: cards,
          ),
          if (albums.isEmpty && c.parentView) ...[
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.albEmptyBody,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          if (milestones.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s6),
            Text(
              c.parentView ? l10n.albFromMilestones : l10n.albByMilestone,
              style: cl.text.headline,
            ),
            const SizedBox(height: ClSpace.s3),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: milestones.length,
                separatorBuilder: (_, _) => const SizedBox(width: ClSpace.s3),
                itemBuilder: (_, i) {
                  final (ms, items) = milestones.values.elementAt(i);
                  return SizedBox(
                    width: 120,
                    child: card(
                      name: '★ ${ms.name}',
                      coverPath: items.first.thumbPath,
                      badge: const SizedBox.shrink(),
                      meta: l10n.memItemCount(items.length),
                      onTap: () => context.push(
                        '${Routes.memories}/album/${milestoneKey(ms.id)}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 10e / 10e2 / 11f detail ----------

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({required this.albumKey, super.key});

  /// An album id, [favoritesKey] or [milestoneKey].
  final String albumKey;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  Set<String>? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final key = widget.albumKey;
    final media = _visible(ref, c);
    final favorites = key == favoritesKey;
    final milestone = key.startsWith('ms:') ? key.substring(3) : null;
    Album? album;
    List<MediaItem> items;
    String title;
    if (favorites) {
      final favs = _favorites(ref, c);
      items = [
        for (final m in media)
          if (favs.contains(m.id)) m,
      ];
      title = l10n.albFavorites;
    } else if (milestone != null) {
      items = [
        for (final m in media)
          if (m.milestone?.id == milestone) m,
      ];
      title = items.isEmpty ? '' : '★ ${items.first.milestone!.name}';
    } else {
      album = _albums(ref, c).where((a) => a.id == key).firstOrNull;
      final added =
          ref.watch(albumItemsProvider((c.babyId, key))).value ?? const {};
      items = sortAlbumItems(
        [
          for (final m in media)
            if (added.containsKey(m.id)) m,
        ],
        album?.sort ?? AlbumSort.newest,
        added,
      );
      title = album?.name ?? '';
    }
    final byId = {for (final m in media) m.id: m};
    final cover = album?.coverMediaId != null
        ? byId[album!.coverMediaId]
        : items.firstOrNull;
    final photos = items.where((i) => !i.isVideo).length;
    final counts = countsLabel(l10n, photos, items.length - photos, ' · ');
    final selecting = _selected != null;
    final parentAlbum = album != null && c.parentView;
    final top = MediaQuery.paddingOf(context).top;

    Widget pill(ClIcons icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: cl.text.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    Widget round(ClIcons icon, String label, VoidCallback? onTap) =>
        ClPressable(
          onPressed: onTap,
          semanticLabel: label,
          child: Container(
            width: ClSpace.tapMin,
            height: ClSpace.tapMin,
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: 20, color: Colors.white),
          ),
        );

    final audiencePill = favorites
        ? pill(ClIcons.lock, l10n.albOnlyYou)
        : album == null
        ? const SizedBox.shrink()
        : !c.parentView && album.author != null
        ? pill(
            ClIcons.family,
            l10n.albSharedBy(whoLabel(l10n, album.author!, false)),
          )
        : pill(
            album.audience == Audience.family ? ClIcons.family : ClIcons.lock,
            album.audience == Audience.family
                ? l10n.audFamily
                : l10n.audParents,
          );

    void open(MediaItem i) =>
        openViewer(context, items: items, start: items.indexOf(i));

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: cl.colors.mintDeep),
                      if (cover?.displayPath != null)
                        Image(
                          image: StorageImage(cover!.displayPath!),
                          fit: BoxFit.cover,
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black26,
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: ClSpace.s4,
                        right: ClSpace.s4,
                        top: top + ClSpace.s2,
                        child: Row(
                          children: [
                            if (!selecting)
                              round(
                                ClIcons.back,
                                l10n.a11yBack,
                                () => context.pop(),
                              ),
                            const Spacer(),
                            if (selecting)
                              ClButton(
                                label: l10n.actionDone,
                                style: ClButtonStyle.secondary,
                                onPressed: () =>
                                    setState(() => _selected = null),
                              )
                            else if (parentAlbum)
                              round(
                                ClIcons.sliders,
                                l10n.albOptions,
                                () => _options(c, album!, items),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: ClSpace.s4,
                        right: ClSpace.s4,
                        bottom: ClSpace.s4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: cl.text.largeTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              favorites
                                  ? '$counts · ${l10n.albFavoritesHint}'
                                  : album == null
                                  ? counts
                                  : l10n.albUpdated(
                                      counts,
                                      _when(l10n, c, album.updatedAt),
                                    ),
                              style: cl.text.label.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: ClSpace.s2),
                            audiencePill,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(ClSpace.s6),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.albNoItems,
                      textAlign: TextAlign.center,
                      style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final m = items[i];
                    return MediaTile(
                      item: m,
                      radius: 0,
                      favorite: favorites,
                      selecting: selecting,
                      selected: _selected?.contains(m.id) ?? false,
                      onTap: selecting
                          ? () => setState(() {
                              _toggle(_selected!, m.id);
                            })
                          : () => open(m),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: MediaQuery.paddingOf(context).bottom + ClSpace.s4,
            child: Center(
              child: selecting
                  ? _Bar(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ClSpace.s3,
                            ),
                            child: Text(
                              l10n.memSelected(_selected!.length),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cl.text.bodyStrong,
                            ),
                          ),
                        ),
                        ClButton(
                          label: l10n.albRemove,
                          style: ClButtonStyle.destructive,
                          onPressed: _selected!.isEmpty
                              ? null
                              : () => _remove(c, album!, _selected!.toList()),
                        ),
                      ],
                    )
                  : parentAlbum
                  ? _Bar(
                      children: [
                        _BarIcon(
                          icon: album.audience == Audience.family
                              ? ClIcons.family
                              : ClIcons.lock,
                          label: l10n.albWhoButton,
                          onTap: () => showAlbumAudienceSheet(
                            context,
                            ref,
                            c,
                            album!,
                            items.length,
                          ),
                        ),
                        ClButton(
                          label: l10n.albAddPhotos,
                          icon: ClIcons.plus,
                          onPressed: () => _addPhotos(c, album!, media, items),
                        ),
                        _BarIcon(
                          icon: ClIcons.spark,
                          label: l10n.albStory,
                          onTap: () =>
                              _storyFromAlbum(context, c, album!, items),
                        ),
                      ],
                    )
                  : album != null
                  ? _Bar(
                      children: [
                        LoveButton(
                          target: LoveTarget.album,
                          targetId: album.id,
                          count: album.loveCount,
                        ),
                        const SizedBox(width: ClSpace.s2),
                        ClButton(
                          label: l10n.actDownload,
                          icon: ClIcons.download,
                          style: ClButtonStyle.secondary,
                          onPressed: () => showDownloadAlbumSheet(
                            context,
                            ref,
                            album!.name,
                            items,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(MemoryCtx c, Album album, List<String> ids) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    try {
      await ref
          .read(memoryRepositoryProvider)
          .removeFromAlbum(c.babyId, album.id, ids);
      toaster.show(message: l10n.albRemoved(ids.length));
      if (mounted) setState(() => _selected = null);
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    }
  }

  Future<void> _addPhotos(
    MemoryCtx c,
    Album album,
    List<MediaItem> all,
    List<MediaItem> inAlbum,
  ) async {
    final l10n = AppLocalizations.of(context);
    final have = {for (final i in inAlbum) i.id};
    final picked = await pickFromMemories(context, [
      for (final m in all)
        if (!have.contains(m.id)) m,
    ]);
    if (picked == null || picked.isEmpty || !mounted) return;
    final toaster = ClToaster.of(context);
    try {
      await ref
          .read(memoryRepositoryProvider)
          .addToAlbum(c.babyId, album.id, picked);
      toaster.show(message: l10n.albAdded(picked.length, album.name));
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    }
  }

  Future<void> _options(MemoryCtx c, Album album, List<MediaItem> items) async {
    final l10n = AppLocalizations.of(context);
    final photos = items.where((i) => !i.isVideo).length;
    final counts = countsLabel(l10n, photos, items.length - photos, ' · ');
    final size = byteSize(
      c.locale,
      items.fold<int>(
        0,
        (s, i) => s + (i.sizeBytes > 0 ? i.sizeBytes : 3 * 1024 * 1024),
      ),
    );
    final choice = await showClSheet<String>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        Widget row(
          ClIcons icon,
          String title,
          String? subtitle,
          String value, {
          String? trailing,
        }) => ClListRow(
          title: title,
          subtitle: [subtitle, trailing].whereType<String>().join(' · '),
          leading: ClIcon(icon, size: 20, color: cl.colors.mintText),
          onTap: () => Navigator.of(sheet).pop(value),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: album.name),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClCardGroup(
                      color: cl.colors.surface2,
                      children: [
                        row(ClIcons.edit, l10n.albRename, null, 'rename'),
                        row(ClIcons.camera, l10n.albCover, null, 'cover'),
                        row(
                          ClIcons.family,
                          l10n.albWhoButton,
                          album.audience == Audience.family
                              ? l10n.albWhoFamilyHint
                              : l10n.audParentsHint,
                          'audience',
                        ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s3),
                    ClCardGroup(
                      color: cl.colors.surface2,
                      children: [
                        row(
                          ClIcons.check,
                          l10n.albSelect,
                          l10n.albSelectHint,
                          'select',
                        ),
                        row(
                          ClIcons.clock,
                          l10n.albSort,
                          null,
                          'sort',
                          trailing: switch (album.sort) {
                            AlbumSort.newest => l10n.sortNewest,
                            AlbumSort.oldest => l10n.sortOldest,
                            AlbumSort.added => l10n.sortAdded,
                          },
                        ),
                        row(
                          ClIcons.download,
                          l10n.albDownload,
                          l10n.albDownloadHint(counts, size),
                          'download',
                        ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s3),
                    ClPressable(
                      onPressed: () => Navigator.of(sheet).pop('delete'),
                      semanticLabel: l10n.albDelete,
                      child: Container(
                        padding: const EdgeInsets.all(ClSpace.s4),
                        decoration: BoxDecoration(
                          color: cl.colors.errorSoft,
                          borderRadius: BorderRadius.circular(
                            ClRadius.card - 6,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.albDelete,
                              style: cl.text.bodyStrong.copyWith(
                                color: cl.colors.error,
                              ),
                            ),
                            Text(
                              l10n.albDeleteHint,
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'rename':
        await showAlbumNameSheet(context, ref, c, album: album);
      case 'cover':
        await _cover(c, album, items);
      case 'audience':
        await showAlbumAudienceSheet(context, ref, c, album, items.length);
      case 'select':
        setState(() => _selected = {});
      case 'sort':
        await _sort(c, album);
      case 'download':
        await showDownloadAlbumSheet(context, ref, album.name, items);
      case 'delete':
        await _delete(c, album, items.length);
    }
  }

  Future<void> _cover(MemoryCtx c, Album album, List<MediaItem> items) async {
    final l10n = AppLocalizations.of(context);
    final photos = [
      for (final i in items)
        if (!i.isVideo) i,
    ];
    if (photos.isEmpty) return;
    var chosen = photos.firstWhere(
      (p) => p.id == album.coverMediaId,
      orElse: () => photos.first,
    );
    final picked = await showClSheet<MediaItem>(
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setState) {
          final cl = context.cl;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l10n.albCoverTitle),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ClRadius.card - 6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (chosen.displayPath != null)
                        Image(
                          image: StorageImage(chosen.displayPath!),
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        left: ClSpace.s3,
                        bottom: ClSpace.s3,
                        child: Text(
                          album.name,
                          style: cl.text.title2.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s3),
              SizedBox(
                height: 170,
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final p in photos)
                      MediaTile(
                        item: p,
                        selecting: true,
                        selected: p.id == chosen.id,
                        onTap: () => setState(() => chosen = p),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              ClButton(
                label: l10n.albSetCover,
                expand: true,
                onPressed: () => Navigator.of(sheet).pop(chosen),
              ),
            ],
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    await _change(c, album, {
      'kind': 'cover',
      'mediaId': picked.id,
    }, l10n.albCoverSet);
  }

  Future<void> _sort(MemoryCtx c, Album album) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<AlbumSort>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.albSort),
          ClCardGroup(
            color: sheet.cl.colors.surface2,
            children: [
              for (final (s, t, h) in [
                (AlbumSort.newest, l10n.sortNewest, l10n.sortNewestHint),
                (AlbumSort.oldest, l10n.sortOldest, l10n.sortOldestHint),
                (AlbumSort.added, l10n.sortAdded, l10n.sortAddedHint),
              ])
                ClOptionRow(
                  title: t,
                  subtitle: h,
                  selected: album.sort == s,
                  onTap: () => Navigator.of(sheet).pop(s),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked == null || picked == album.sort || !mounted) return;
    await _change(c, album, {'kind': 'sort', 'sort': picked.name}, null);
  }

  Future<void> _delete(MemoryCtx c, Album album, int count) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.albDeleteTitle(album.name)),
            Text(l10n.albDeleteBody(count), style: cl.text.body),
            if (album.audience == Audience.family) ...[
              const SizedBox(height: ClSpace.s3),
              Row(
                children: [
                  ClIcon(ClIcons.family, size: 18, color: cl.colors.inkMuted),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.albDeleteFamily,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.albDelete,
              style: ClButtonStyle.destructive,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            ClButton(
              label: l10n.actionCancel,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(memoryRepositoryProvider).deleteAlbum(c.babyId, album.id);
      toaster.show(message: l10n.albDeleted);
      router.pop();
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    }
  }

  Future<void> _change(
    MemoryCtx c,
    Album album,
    Map<String, Object?> change,
    String? done,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    try {
      await ref
          .read(memoryRepositoryProvider)
          .updateAlbum(c.babyId, album.id, change);
      if (done != null) toaster.show(message: done);
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    }
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.card,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: cl.colors.ink),
      ),
    );
  }
}

// ---------- Sheets ----------

/// "Album mới" (10d, 10h5) or 10e4 "Đổi tên album".
Future<String?> showAlbumNameSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c, {
  Album? album,
  List<String> mediaIds = const [],
  Audience initialAudience = Audience.family,
}) => showClSheet<String>(
  context: context,
  builder: (_) => _AlbumNameSheet(
    ctx: c,
    album: album,
    mediaIds: mediaIds,
    initialAudience: initialAudience,
  ),
);

Future<String?> showNewAlbumSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c, {
  List<String> mediaIds = const [],
}) => showAlbumNameSheet(context, ref, c, mediaIds: mediaIds);

class _AlbumNameSheet extends ConsumerStatefulWidget {
  const _AlbumNameSheet({
    required this.ctx,
    required this.album,
    required this.mediaIds,
    required this.initialAudience,
  });
  final MemoryCtx ctx;
  final Album? album;
  final List<String> mediaIds;
  final Audience initialAudience;

  @override
  ConsumerState<_AlbumNameSheet> createState() => _AlbumNameSheetState();
}

class _AlbumNameSheetState extends ConsumerState<_AlbumNameSheet> {
  late final _name = TextEditingController(text: widget.album?.name);
  late var _audience = widget.album?.audience ?? widget.initialAudience;
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.albNameRequired);
      return;
    }
    setState(() => _busy = true);
    final toaster = ClToaster.of(context);
    final repo = ref.read(memoryRepositoryProvider);
    try {
      if (widget.album != null) {
        await repo.updateAlbum(widget.ctx.babyId, widget.album!.id, {
          'kind': 'rename',
          'name': name,
        });
        if (mounted) Navigator.of(context).pop(widget.album!.id);
      } else {
        final id = newAlbumId();
        await repo.createAlbum(
          widget.ctx.babyId,
          id,
          name,
          _audience,
          widget.mediaIds,
        );
        toaster.show(message: l10n.albCreated(name));
        if (mounted) Navigator.of(context).pop(id);
      }
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final renaming = widget.album != null;
    final suggestions = renaming
        ? [l10n.albSuggestBath, l10n.albSuggestSun, l10n.albSuggestSwim]
        : [l10n.albSuggestBath, l10n.albSuggestHands, l10n.albSuggestSleep];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: renaming ? l10n.albRename : l10n.albNew),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClTextField(
                  label: l10n.albName,
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: cl.text.label.copyWith(color: cl.colors.error),
                  ),
                const SizedBox(height: ClSpace.s3),
                Text(
                  l10n.albSuggestions,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s2,
                  children: [
                    for (final sug in suggestions)
                      ClFilterChip(
                        label: sug,
                        selected: false,
                        onTap: () => setState(() {
                          _name.text = sug;
                          _error = null;
                        }),
                      ),
                  ],
                ),
                if (!renaming) ...[
                  const SizedBox(height: ClSpace.s4),
                  Text(l10n.composeWho, style: cl.text.headline),
                  const SizedBox(height: ClSpace.s2),
                  AudienceCards(
                    value: _audience,
                    onChanged: (a) => setState(() => _audience = a),
                  ),
                ],
                const SizedBox(height: ClSpace.s4),
                ClButton(
                  label: renaming ? l10n.albSaveName : l10n.albCreate,
                  expand: true,
                  onPressed: _save,
                  loading: _busy,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 10e6 "Ai thấy album này" with the count note and one generic notice (R-104, D-002).
Future<void> showAlbumAudienceSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  Album album,
  int count,
) async {
  final l10n = AppLocalizations.of(context);
  var audience = album.audience;
  var notify = true;
  final result = await showClSheet<(Audience, bool)>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final cl = context.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.albWhoButton),
            AudienceCards(
              value: audience,
              onChanged: (a) => setState(() => audience = a),
            ),
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control + 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.albAppliesTo(count), style: cl.text.bodyStrong),
                  Text(
                    l10n.albLaterFollow,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            if (audience == Audience.family) ...[
              const SizedBox(height: ClSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.composeNotify, style: cl.text.bodyStrong),
                        Text(
                          l10n.albNoticeHint,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClToggle(
                    value: notify,
                    onChanged: (v) => setState(() => notify = v),
                  ),
                ],
              ),
            ],
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.actionSave,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop((audience, notify)),
            ),
          ],
        );
      },
    ),
  );
  if (result == null || result.$1 == album.audience || !context.mounted) return;
  final toaster = ClToaster.of(context);
  try {
    final staying = await ref
        .read(memoryRepositoryProvider)
        .updateAlbum(c.babyId, album.id, {
          'kind': 'audience',
          'audience': result.$1.name,
          'notifyFamily': result.$1 == Audience.family && result.$2,
        });
    toaster.show(
      message: result.$1 == Audience.parents && staying > 0
          ? l10n.albStayShared(staying)
          : l10n.albAudienceSaved,
    );
  } on Object {
    toaster.show(message: l10n.toastActionFailed);
  }
}

/// 10e9 "Tải về máy": into a same-named Photos album, videos wait for Wi-Fi when asked.
Future<void> showDownloadAlbumSheet(
  BuildContext context,
  WidgetRef ref,
  String name,
  List<MediaItem> items,
) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  var wifiOnly = true;
  final size = byteSize(
    locale,
    items.fold<int>(
      0,
      (s, i) => s + (i.sizeBytes > 0 ? i.sizeBytes : 3 * 1024 * 1024),
    ),
  );
  final go = await showClSheet<bool>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final cl = context.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.dlTitle),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control + 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dlSummary(items.length, size),
                    style: cl.text.bodyStrong,
                  ),
                  Text(
                    l10n.dlInto(name),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.dlWifi, style: cl.text.bodyStrong),
                      Text(
                        l10n.dlWifiHint,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClToggle(
                  value: wifiOnly,
                  onChanged: (v) => setState(() => wifiOnly = v),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.dlN(items.length),
              icon: ClIcons.download,
              expand: true,
              onPressed: items.isEmpty
                  ? null
                  : () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.dlFootnote,
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        );
      },
    ),
  );
  if (go != true || !context.mounted) return;
  final toaster = ClToaster.of(context);
  final onWifi = ref.read(networkKindProvider).value == NetworkKind.wifi;
  final now = [
    for (final i in items)
      if (!i.isVideo || !wifiOnly || onWifi) i,
  ];
  toaster.show(message: l10n.toastSaving);
  try {
    if (!await Gal.hasAccess(toAlbum: true)) {
      await Gal.requestAccess(toAlbum: true);
    }
    var saved = 0;
    for (final i in now) {
      final path = i.paths?.original;
      if (path == null) continue;
      final file = await mediaBytes.file(path);
      i.isVideo
          ? await Gal.putVideo(file.path, album: name)
          : await Gal.putImage(file.path, album: name);
      saved++;
    }
    toaster.show(
      message: now.length < items.length
          ? l10n.dlNeedsWifi
          : l10n.toastSaved(saved),
    );
  } on Object {
    toaster.show(message: l10n.toastSaveFailed);
  }
}

/// 10h5 / 10b3 "Thêm vào album": several albums, "Tạo album mới" (D-002 note).
Future<List<String>?> showAlbumPicker(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c, {
  List<String> selected = const [],
  List<String> mediaIds = const [],
}) => showClSheet<List<String>>(
  context: context,
  builder: (_) => _AlbumPicker(ctx: c, initial: selected, mediaIds: mediaIds),
);

class _AlbumPicker extends ConsumerStatefulWidget {
  const _AlbumPicker({
    required this.ctx,
    required this.initial,
    required this.mediaIds,
  });
  final MemoryCtx ctx;
  final List<String> initial;
  final List<String> mediaIds;

  @override
  ConsumerState<_AlbumPicker> createState() => _AlbumPickerState();
}

class _AlbumPickerState extends ConsumerState<_AlbumPicker> {
  late final _chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = widget.ctx;
    final albums = _albums(ref, c);
    final media = {for (final m in _visible(ref, c)) m.id: m};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.albPickTitle),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClPressable(
                  onPressed: () async {
                    final id = await showNewAlbumSheet(context, ref, c);
                    if (id != null) setState(() => _chosen.add(id));
                  },
                  semanticLabel: l10n.albPickNew,
                  child: Container(
                    padding: const EdgeInsets.all(ClSpace.s3),
                    decoration: BoxDecoration(
                      color: cl.colors.mintSoft,
                      borderRadius: BorderRadius.circular(ClRadius.control + 4),
                    ),
                    child: Row(
                      children: [
                        ClIcon(
                          ClIcons.plus,
                          size: 20,
                          color: cl.colors.mintText,
                        ),
                        const SizedBox(width: ClSpace.s3),
                        Text(
                          l10n.albPickNew,
                          style: cl.text.bodyStrong.copyWith(
                            color: cl.colors.mintText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                for (final a in albums)
                  ClPressable(
                    onPressed: () => setState(() {
                      _toggle(_chosen, a.id);
                    }),
                    selected: _chosen.contains(a.id),
                    semanticLabel: a.name,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(ClRadius.sm),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: media[a.coverMediaId]?.thumbPath == null
                                  ? ColoredBox(color: cl.colors.surface2)
                                  : Image(
                                      image: StorageImage(
                                        media[a.coverMediaId]!.thumbPath!,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: ClSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: cl.text.bodyStrong),
                                Row(
                                  children: [
                                    AudienceIcon(
                                      audience: a.audience,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      countsLabel(
                                        l10n,
                                        a.photos,
                                        a.videos,
                                        ' · ',
                                      ),
                                      style: cl.text.caption.copyWith(
                                        color: cl.colors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _chosen.contains(a.id)
                                  ? cl.colors.mintDeep
                                  : null,
                              border: _chosen.contains(a.id)
                                  ? null
                                  : Border.all(
                                      color: cl.colors.inkMuted,
                                      width: 1.8,
                                    ),
                            ),
                            child: _chosen.contains(a.id)
                                ? ClIcon(
                                    ClIcons.check,
                                    size: 16,
                                    color: cl.colors.onMintDeep,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.albPickHint,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s4),
                ClButton(
                  label: l10n.actionDone,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(_chosen.toList()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Thêm ảnh" into an album: pick from what is already in Kỷ niệm.
Future<List<String>?> pickFromMemories(
  BuildContext context,
  List<MediaItem> items, {
  int? max,
  String? title,
}) {
  final selected = <String>{};
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (page) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context);
          final cl = context.cl;
          return Scaffold(
            backgroundColor: cl.colors.cloud,
            body: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      ClButton(
                        label: l10n.actionCancel,
                        style: ClButtonStyle.plain,
                        onPressed: () => Navigator.of(page).pop(),
                      ),
                      Expanded(
                        child: Text(
                          title ?? l10n.albPickFromMemories,
                          textAlign: TextAlign.center,
                          style: cl.text.headline,
                        ),
                      ),
                      const SizedBox(width: 72),
                    ],
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(l10n.pickEmpty))
                        : GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                ),
                            itemCount: items.length,
                            itemBuilder: (_, i) => MediaTile(
                              item: items[i],
                              radius: 0,
                              selecting: true,
                              selected: selected.contains(items[i].id),
                              onTap: () => setState(() {
                                // A story photo group holds at most 4 (R-133).
                                if (max != null &&
                                    !selected.contains(items[i].id) &&
                                    selected.length >= max) {
                                  return;
                                }
                                _toggle(selected, items[i].id);
                              }),
                            ),
                          ),
                  ),
                  if (selected.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(ClSpace.s4),
                      child: ClButton(
                        label: l10n.pickAdd(selected.length),
                        expand: true,
                        onPressed: () =>
                            Navigator.of(page).pop(selected.toList()),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Shared helper for the albums row in compose (10h): "Giờ tắm" / "Giờ tắm +1" / "Chưa chọn".
String albumsValue(AppLocalizations l10n, List<Album> all, List<String> ids) {
  final names = [
    for (final a in all)
      if (ids.contains(a.id)) a.name,
  ];
  if (names.isEmpty) return l10n.albPickNone;
  return names.length == 1
      ? names.single
      : l10n.albPickMore(names.first, names.length - 1);
}

String capitalised(String s) => _cap(s);

void _toggle(Set<String> set, String id) {
  if (!set.remove(id)) set.add(id);
}

/// 10e "Kể thành chuyện": a new story titled after the album, its photos in groups of 4 (S12).
void _storyFromAlbum(
  BuildContext context,
  MemoryCtx c,
  Album album,
  List<MediaItem> items,
) {
  final photos = [
    for (final m in items)
      if (!m.isVideo) m.id,
  ].take(9).toList();
  final blank = Story.blank(
    babyId: c.babyId,
    uid: c.me.uid,
    author: CareAuthor.of(c.me),
    now: c.now,
  );
  final rest = photos.skip(1).toList();
  final story = blank.copyWith(
    title: album.name,
    coverMediaId: photos.firstOrNull,
    audience: album.audience,
    blocks: [
      ...blank.blocks,
      for (var i = 0; i < rest.length; i += 4)
        PhotosBlock(newBlockId(), [
          for (final id in rest.skip(i).take(4)) StoryPhoto(id),
        ]),
    ],
  );
  context.push('${Routes.story}/${story.id}/edit', extra: story);
}
