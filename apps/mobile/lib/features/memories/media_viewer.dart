import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/cl_theme.dart';
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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  0,
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
                          AudienceIcon(
                            audience: item.effectiveAudience,
                            color: white,
                          ),
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
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: widget.items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final it = widget.items[i];
                    return it.isVideo
                        ? _VideoPage(item: it, active: i == _index)
                        : InteractiveViewer(
                            maxScale: 4,
                            child: Center(
                              child: it.displayPath == null
                                  ? const SizedBox.shrink()
                                  : Image(
                                      image: StorageImage(it.displayPath!),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      gaplessPlayback: true,
                                    ),
                            ),
                          );
                  },
                ),
              ),
              if (widget.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: ClSpace.s3),
                  child: widget.items.length <= 12
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var d = 0; d < widget.items.length; d++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: d == _index ? 8 : 6,
                                height: d == _index ? 8 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: d == _index ? white : Colors.white38,
                                ),
                              ),
                          ],
                        )
                      : Text(
                          '${_index + 1}/${widget.items.length}',
                          style: cl.text.caption.copyWith(color: white),
                        ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (milestone != null) ...[
                      MilestoneChip(milestone: milestone, compact: true),
                      const SizedBox(height: ClSpace.s2),
                    ],
                    if (caption != null && caption.isNotEmpty) ...[
                      Text(
                        caption,
                        style: cl.text.headline.copyWith(color: white),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      meta,
                      style: cl.text.caption.copyWith(color: Colors.white70),
                    ),
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
                    const SizedBox(height: ClSpace.s3),
                    Wrap(
                      spacing: ClSpace.s2,
                      runSpacing: ClSpace.s2,
                      children: [
                        LoveButton(
                          target: LoveTarget.media,
                          targetId: item.id,
                          count: item.loveCount,
                          dark: true,
                          showLabel: false,
                        ),
                        FavoriteButton(mediaId: item.id, dark: true),
                        if (canDownload) ...[
                          _Action(
                            icon: ClIcons.download,
                            label: l10n.actDownload,
                            onTap: () => saveToPhotos(context, [item]),
                          ),
                        ],
                        if (parent)
                          _Action(
                            icon: ClIcons.upload,
                            label: l10n.viewerShare,
                            onTap: () => shareItems(context, [item]),
                          )
                        else
                          _Action(
                            icon: ClIcons.mail,
                            label: l10n.messageAction,
                            onTap: () => showMessageComposer(
                              context,
                              kind: MessageContext.media,
                              contextId: item.id,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
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
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A video: poster first, then the file (Rules-gated, cached) plays in place.
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.item, required this.active});
  final MediaItem item;
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _video;
  var _loading = false;
  var _failed = false;

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (!widget.active) _video?.pause();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_video != null) {
      _video!.value.isPlaying ? await _video!.pause() : await _video!.play();
      setState(() {});
      return;
    }
    final path = widget.item.paths?.original;
    if (path == null) return;
    setState(() => _loading = true);
    try {
      final File file = await mediaBytes.file(path);
      final v = VideoPlayerController.file(file);
      await v.initialize();
      v.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() {
        _video = v;
        _loading = false;
      });
      unawaited(v.play());
    } on Object {
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
    return GestureDetector(
      onTap: _play,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (v != null && v.value.isInitialized)
            AspectRatio(aspectRatio: v.value.aspectRatio, child: VideoPlayer(v))
          else if (poster != null)
            Image(
              image: StorageImage(poster),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          if (_loading)
            const CircularProgressIndicator(color: Colors.white)
          else if (_failed)
            Text(
              l10n.viewerVideoFailed,
              style: cl.text.label.copyWith(color: Colors.white),
            )
          else if (v == null || !v.value.isPlaying)
            Semantics(
              button: true,
              label: l10n.a11yPlay,
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
            ),
        ],
      ),
    );
  }
}
