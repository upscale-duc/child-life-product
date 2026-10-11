import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import 'media_bytes.dart';
import 'album_models.dart';
import 'memories_screen.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_widgets.dart';
import 'social_widgets.dart';
import 'viewer_video.dart';

/// 10f Xem toàn màn hình (135:18156): swipe through items, audience pill, milestone, caption,
/// "Thứ Hai, 5 tháng 10 · Mẹ đăng", Tải về and Chia sẻ (R-114). Thương and Yêu thích come
/// with S10; edit and delete are not in the viewer (delete is a selection action).
Future<void> openViewer(
  BuildContext context, {
  required List<MediaItem> items,
  required int start,
  Memory? memory,
}) {
  if (items.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => MediaViewer(
        items: items,
        start: start.clamp(0, items.length - 1),
        memory: memory,
      ),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

/// Saves originals to the photo library (10f / 10b3 "Tải về").
Future<void> saveToPhotos(BuildContext context, List<MediaItem> items) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  toaster.show(message: l10n.toastSaving);
  try {
    if (!await Gal.hasAccess()) await Gal.requestAccess();
    var saved = 0;
    for (final i in items) {
      final path = i.paths?.original;
      if (path == null) continue;
      final file = await mediaBytes.file(path);
      i.isVideo ? await Gal.putVideo(file.path) : await Gal.putImage(file.path);
      saved++;
    }
    toaster.show(message: l10n.toastSaved(saved));
  } on Object {
    toaster.show(message: l10n.toastSaveFailed);
  }
}

/// "Gửi đi" / "Chia sẻ": the OS share sheet with the originals.
Future<void> shareItems(BuildContext context, List<MediaItem> items) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  try {
    final files = <XFile>[];
    for (final i in items) {
      final path = i.paths?.original;
      if (path == null) continue;
      files.add(XFile((await mediaBytes.file(path)).path));
    }
    if (files.isEmpty) return;
    await SharePlus.instance.share(ShareParams(files: files));
  } on Object {
    toaster.show(message: l10n.toastActionFailed);
  }
}

class MediaViewer extends ConsumerStatefulWidget {
  const MediaViewer({
    required this.items,
    required this.start,
    this.memory,
    super.key,
  });

  final List<MediaItem> items;
  final int start;
  final Memory? memory;

  @override
  ConsumerState<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends ConsumerState<MediaViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;

  /// Close, audience, caption and actions float over the media; a tap on the media hides them
  /// (and the status bar) so the photo or video is seen whole.
  var _chrome = true;

  /// While a photo is zoomed, one-finger drags pan it instead of paging.
  var _zoomed = false;

  /// The player of each opened video page, for the controls in the bottom chrome.
  final _players = <int, ViewerVideo>{};

  @override
  void dispose() {
    if (!_chrome) _showSystemUi(true);
    _pages.dispose();
    super.dispose();
  }

  void _showSystemUi(bool show) => unawaited(
    SystemChrome.setEnabledSystemUIMode(
      show ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    ).catchError((Object _) {}),
  );

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    _showSystemUi(_chrome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    final item = widget.items[_index];
    final me = ref.watch(selectedMembershipProvider);
    final memories = c == null
        ? null
        : ref.watch(memoriesProvider((c.babyId, c.isParent))).value;
    final memory =
        widget.memory ??
        memories?.where((m) => m.id == item.memoryId).firstOrNull;
    final milestone = item.milestone ?? memory?.milestone;
    final caption = memory?.caption;
    final who = whoLabel(l10n, item.author, item.createdBy == me?.uid);
    final date = c == null ? '' : entryDate(l10n, c, item.captureAt);
    // Relatives download photos and videos too (D-036).
    final canDownload = me != null;
    final parent = me?.role == MemberRole.coParent;
    final albums = c == null
        ? const <Album>[]
        : ref.watch(albumsProvider((c.babyId, c.isParent))).value ?? const [];
    final albumName = albums
        .where((a) => item.albumIds.contains(a.id))
        .map((a) => a.name)
        .firstOrNull;
    final posted = parent
        ? l10n.viewerPosted(date, who)
        : l10n.viewerShared(date, who);
    final meta = albumName == null
        ? posted
        : l10n.viewerInAlbum(posted, albumName);
    final thread = parent && me != null
        ? [
            for (final m
                in ref
                        .watch(messagesProvider((me.babyId, me.uid, true)))
                        .value ??
                    const <ParentMessage>[])
              if (m.contextId == item.id || m.contextId == item.memoryId) m,
          ]
        : const <ParentMessage>[];
    final white = Colors.white;
    final player = item.isVideo ? _players[_index] : null;

    final top = Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s6,
        ClSpace.s4,
        ClSpace.s6,
      ),
      child: Row(
        children: [
          ClPressable(
            onPressed: () => Navigator.of(context).pop(),
            semanticLabel: l10n.a11yClose,
            child: Container(
              width: ClSpace.tapMin,
              height: ClSpace.tapMin,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(ClIcons.close, size: 20, color: white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AudienceIcon(audience: item.effectiveAudience, color: white),
                const SizedBox(width: 6),
                Text(
                  item.effectiveAudience == Audience.family
                      ? l10n.audFamily
                      : l10n.audParents,
                  style: cl.text.label.copyWith(
                    color: white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Icon-only actions stand in a column on the right, TikTok-style.
    final rail = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoveButton(
          target: LoveTarget.media,
          targetId: item.id,
          count: item.loveCount,
          rail: true,
        ),
        const SizedBox(height: ClSpace.s3),
        FavoriteButton(mediaId: item.id, rail: true),
        if (canDownload) ...[
          const SizedBox(height: ClSpace.s3),
          RailButton(
            icon: ClIcons.download,
            semanticLabel: l10n.actDownload,
            onPressed: () => saveToPhotos(context, [item]),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        if (parent)
          RailButton(
            icon: ClIcons.upload,
            semanticLabel: l10n.viewerShare,
            onPressed: () => shareItems(context, [item]),
          )
        else
          RailButton(
            icon: ClIcons.mail,
            semanticLabel: l10n.messageAction,
            onPressed: () => showMessageComposer(
              context,
              kind: MessageContext.media,
              contextId: item.id,
            ),
          ),
      ],
    );

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (milestone != null) ...[
          MilestoneChip(milestone: milestone, compact: true),
          const SizedBox(height: ClSpace.s2),
        ],
        if (caption != null && caption.isNotEmpty) ...[
          Text(caption, style: cl.text.headline.copyWith(color: white)),
          const SizedBox(height: 4),
        ],
        Text(meta, style: cl.text.caption.copyWith(color: Colors.white70)),
        if (thread.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s2),
            child: ClPressable(
              onPressed: () => _showThread(context, thread),
              semanticLabel: l10n.messagesOnItem(thread.length),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(ClIcons.mail, size: 16, color: white),
                  const SizedBox(width: 6),
                  Text(
                    l10n.messagesOnItem(thread.length),
                    style: cl.text.label.copyWith(
                      color: white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    // Top to bottom: the rail on the right, the caption, the scrubber, then the strip of
    // thumbnails, all on one left edge.
    final bottom = Padding(
      padding: const EdgeInsets.only(top: ClSpace.s8, bottom: ClSpace.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.centerRight, child: rail),
                const SizedBox(height: ClSpace.s4),
                info,
                if (player != null) ...[
                  const SizedBox(height: ClSpace.s1),
                  _VideoBar(video: player),
                ],
              ],
            ),
          ),
          if (widget.items.length > 1) ...[
            SizedBox(height: player == null ? ClSpace.s3 : ClSpace.s1),
            _ThumbStrip(
              items: widget.items,
              index: _index,
              onSelect: (i) {
                if (i != _index) _pages.jumpToPage(i);
              },
            ),
          ],
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // The media is full-bleed and never moves when the chrome comes and goes.
            PageView.builder(
              controller: _pages,
              physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() {
                _index = i;
                _zoomed = false;
              }),
              itemBuilder: (_, i) {
                final it = widget.items[i];
                return it.isVideo
                    ? _VideoPage(
                        key: ValueKey(it.id),
                        item: it,
                        active: i == _index,
                        onTap: _toggleChrome,
                        onPlayer: (v) {
                          if (!mounted) return;
                          if (v == null) {
                            _players.remove(i);
                          } else {
                            setState(() => _players[i] = v);
                          }
                        },
                      )
                    : _PhotoPage(
                        key: ValueKey(it.id),
                        item: it,
                        onTap: _toggleChrome,
                        onZoomed: (z) {
                          if (mounted && z != _zoomed && i == _index) {
                            setState(() => _zoomed = z);
                          }
                        },
                      );
              },
            ),
            IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                key: const Key('viewerChrome'),
                opacity: _chrome ? 1 : 0,
                duration: context.motion(ClMotion.quick),
                curve: ClCurves.quick,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _Scrim(
                        fromTop: true,
                        onTap: _toggleChrome,
                        child: SafeArea(bottom: false, child: top),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _Scrim(
                        fromTop: false,
                        onTap: _toggleChrome,
                        child: SafeArea(top: false, child: bottom),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft black fade behind the floating chrome so white text reads on any photo.
class _Scrim extends StatelessWidget {
  const _Scrim({
    required this.fromTop,
    required this.onTap,
    required this.child,
  });
  final bool fromTop;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    // Taps between the buttons hide the chrome like taps on the media.
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: fromTop
              ? const [Color(0x8C000000), Color(0x00000000)]
              : const [Color(0xB3000000), Color(0x66000000), Color(0x00000000)],
        ),
      ),
      child: child,
    ),
  );
}

/// "Lời nhắn (2)" under an item, for parents (D-034); opening marks them read.
Future<void> _showThread(BuildContext context, List<ParentMessage> thread) =>
    showClSheet<void>(
      context: context,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context);
          final me = ref.read(selectedMembershipProvider);
          if (me != null) {
            for (final m in thread) {
              if (!m.readByUid(me.uid)) {
                unawaited(
                  ref
                      .read(memoryRepositoryProvider)
                      .markRead(me.babyId, m.id, me.uid)
                      .catchError((Object _) {}),
                );
              }
            }
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l10n.messagesOnItem(thread.length)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: thread.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: ClSpace.s2),
                  itemBuilder: (_, i) => MessageTile(message: thread[i]),
                ),
              ),
            ],
          );
        },
      ),
    );

/// A photo, full width on black: pinch or double-tap to zoom, drag to pan while zoomed.
class _PhotoPage extends StatefulWidget {
  const _PhotoPage({
    required this.item,
    required this.onTap,
    required this.onZoomed,
    super.key,
  });
  final MediaItem item;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomed;

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage>
    with SingleTickerProviderStateMixin {
  static const _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final _zoom = AnimationController(
    vsync: this,
    duration: ClMotion.standard,
  );
  Animation<Matrix4>? _zoomTween;
  var _tapAt = Offset.zero;
  var _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    _zoom.addListener(() {
      final t = _zoomTween;
      if (t != null) _transform.value = t.value;
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomed(zoomed);
  }

  void _toggleZoom() {
    final p = _tapAt;
    const s = _doubleTapScale;
    final target = _zoomed
        ? Matrix4.identity()
        // Zoom around the tapped point: it stays under the finger.
        : (Matrix4.identity()
            ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
            ..scaleByDouble(s, s, 1, 1));
    if (context.reduceMotion) {
      _transform.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoom, curve: ClCurves.standard));
    unawaited(_zoom.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.item.displayPath;
    return Semantics(
      image: true,
      onTapHint: AppLocalizations.of(context).viewerToggleChrome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTapDown: (d) => _tapAt = d.localPosition,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _transform,
          maxScale: 4,
          // Unzoomed, one-finger drags belong to the pager.
          panEnabled: _zoomed,
          child: SizedBox.expand(
            child: path == null
                ? const SizedBox.shrink()
                : Image(
                    image: StorageImage(path),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          ),
        ),
      ),
    );
  }
}

/// A video: poster first, then the file (Rules-gated, cached) plays in place with media_kit.
class _VideoPage extends ConsumerStatefulWidget {
  const _VideoPage({
    required this.item,
    required this.active,
    required this.onTap,
    required this.onPlayer,
    super.key,
  });
  final MediaItem item;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<ViewerVideo?> onPlayer;

  @override
  ConsumerState<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<_VideoPage> {
  ViewerVideo? _video;
  var _loading = false;
  var _failed = false;

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (!widget.active) unawaited(_video?.pause());
  }

  @override
  void dispose() {
    widget.onPlayer(null);
    unawaited(_video?.dispose());
    super.dispose();
  }

  Future<void> _play() async {
    final existing = _video;
    if (existing != null) {
      existing.state.value.playing
          ? await existing.pause()
          : await existing.play();
      return;
    }
    final path = widget.item.paths?.original;
    if (path == null || _loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    ViewerVideo? v;
    try {
      final File file = await mediaBytes.file(path);
      if (!mounted) return;
      v = ref.read(viewerVideoProvider)();
      await v.open(file.path);
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() {
        _video = v;
        _loading = false;
      });
      widget.onPlayer(v);
    } on Object {
      // Never log the path or item: child media (CLAUDE.md security).
      if (v != null && _video == null) unawaited(v.dispose());
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final v = _video;
    final poster = widget.item.paths?.poster ?? widget.item.thumbPath;
    return Semantics(
      onTapHint: l10n.viewerToggleChrome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (v != null) v.view(context),
            // Keyed so it is not reloaded when the video slides in under it.
            if (poster != null)
              KeyedSubtree(
                key: const ValueKey('poster'),
                child: v == null
                    ? _Poster(path: poster)
                    : ValueListenableBuilder(
                        valueListenable: v.state,
                        builder: (_, s, child) =>
                            s.rendered ? const SizedBox.shrink() : child!,
                        child: _Poster(path: poster),
                      ),
              ),
            Center(
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _failed
                  ? Text(
                      l10n.viewerVideoFailed,
                      style: cl.text.label.copyWith(color: Colors.white),
                    )
                  : v == null
                  ? _PlayButton(onTap: _play)
                  : ValueListenableBuilder(
                      valueListenable: v.state,
                      builder: (_, s, _) => s.playing
                          ? const SizedBox.shrink()
                          : _PlayButton(onTap: _play),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => Image(
    image: StorageImage(path),
    fit: BoxFit.contain,
    gaplessPlayback: true,
  );
}

/// Small thumbnails of every item along the bottom; the current one is outlined and kept in
/// view, a tap jumps to an item.
class _ThumbStrip extends StatefulWidget {
  const _ThumbStrip({
    required this.items,
    required this.index,
    required this.onSelect,
  });
  final List<MediaItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  State<_ThumbStrip> createState() => _ThumbStripState();
}

class _ThumbStripState extends State<_ThumbStrip> {
  static const _size = 44.0;
  static const _gap = 6.0;
  static const _inset = ClSpace.s4;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Opened on a later item: bring it into view once the strip is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_offsetFor(widget.index, _scroll.position));
      }
    });
  }

  @override
  void didUpdateWidget(_ThumbStrip old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _reveal();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The offset that shows item [i] whole, moving as little as possible.
  static double _offsetFor(int i, ScrollPosition p) {
    final start = i * (_size + _gap);
    final end = start + _size + _inset * 2;
    final viewport = p.viewportDimension;
    final target = start < p.pixels
        ? start
        : end > p.pixels + viewport
        ? end - viewport
        : p.pixels;
    return target.clamp(p.minScrollExtent, p.maxScrollExtent);
  }

  void _reveal() {
    if (!_scroll.hasClients) return;
    final to = _offsetFor(widget.index, _scroll.position);
    if (to == _scroll.offset) return;
    context.reduceMotion
        ? _scroll.jumpTo(to)
        : unawaited(
            _scroll.animateTo(
              to,
              duration: context.motion(ClMotion.quick),
              curve: ClCurves.quick,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = widget.items.length;
    return SizedBox(
      height: _size,
      child: ListView.separated(
        key: const Key('viewerThumbs'),
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _inset),
        itemCount: n,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (_, i) {
          final on = i == widget.index;
          final path = widget.items[i].thumbPath;
          return ClPressable(
            onPressed: () => widget.onSelect(i),
            semanticLabel: l10n.viewerThumb(i + 1, n),
            selected: on,
            haptic: false,
            minSize: Size.zero,
            child: AnimatedOpacity(
              opacity: on ? 1 : 0.55,
              duration: context.motion(ClMotion.quick),
              curve: ClCurves.quick,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(ClRadius.sm),
                  border: Border.all(
                    color: on ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: path == null
                    ? null
                    : Image(
                        image: StorageImage(path),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onTap,
    semanticLabel: AppLocalizations.of(context).a11yPlay,
    child: Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const PlayGlyph(size: 26),
    ),
  );
}

/// Play / pause and the scrubber, shown with the rest of the chrome.
class _VideoBar extends StatefulWidget {
  const _VideoBar({required this.video});
  final ViewerVideo video;

  @override
  State<_VideoBar> createState() => _VideoBarState();
}

class _VideoBarState extends State<_VideoBar> {
  /// The scrubber position while a finger is on it.
  double? _dragMs;
  var _resume = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final time = cl.text.caption.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ValueListenableBuilder(
      valueListenable: widget.video.state,
      builder: (context, s, _) {
        final total = s.duration.inMilliseconds.toDouble();
        final at = (_dragMs ?? s.position.inMilliseconds.toDouble()).clamp(
          0.0,
          total <= 0 ? 0.0 : total,
        );
        return Row(
          children: [
            ClPressable(
              onPressed: () => unawaited(
                s.playing ? widget.video.pause() : widget.video.play(),
              ),
              semanticLabel: s.playing ? l10n.a11yPause : l10n.a11yPlay,
              child: SizedBox(
                width: ClSpace.tapMin - ClSpace.s2,
                height: ClSpace.tapMin,
                // Flush left, on the caption's edge.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: s.playing
                      ? const _PauseGlyph(size: 18)
                      : const PlayGlyph(size: 18),
                ),
              ),
            ),
            Text(videoDuration(at.round()), style: time),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: 20,
                  ),
                ),
                child: Slider(
                  value: at,
                  max: total <= 0 ? 1 : total,
                  semanticFormatterCallback: (v) =>
                      '${l10n.viewerSeek} ${videoDuration(v.round())}',
                  onChangeStart: total <= 0
                      ? null
                      : (v) {
                          _resume = s.playing;
                          unawaited(widget.video.pause());
                          setState(() => _dragMs = v);
                        },
                  onChanged: total <= 0
                      ? null
                      : (v) => setState(() => _dragMs = v),
                  onChangeEnd: total <= 0
                      ? null
                      : (v) async {
                          await widget.video.seek(
                            Duration(milliseconds: v.round()),
                          );
                          if (_resume) await widget.video.play();
                          if (mounted) setState(() => _dragMs = null);
                        },
                ),
              ),
            ),
            Text(videoDuration(s.duration.inMilliseconds), style: time),
          ],
        );
      },
    );
  }
}

class _PauseGlyph extends StatelessWidget {
  const _PauseGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: size * 0.3,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.08),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [bar, bar],
      ),
    );
  }
}
