import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../family/family_labels.dart';
import 'media_bytes.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'upload_queue.dart';

/// "0:24" / "1:02:05".
String videoDuration(int? ms) {
  final s = ((ms ?? 0) / 1000).round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final two = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$two' : '$m:$two';
}

/// "2,1 MB" / "2.1 MB".
String byteSize(String locale, int bytes) {
  if (bytes < 1024 * 1024) {
    return '${NumberFormat('#,##0', locale).format((bytes / 1024).ceil())} KB';
  }
  final mb = bytes / (1024 * 1024);
  return '${NumberFormat(mb < 10 ? '#,##0.0' : '#,##0', locale).format(mb)} MB';
}

/// "Mẹ" / "Ba" / "Bà nội Hoa" / "Bạn" (D-024 attribution).
String whoLabel(AppLocalizations l10n, CareAuthor author, bool isMe) =>
    authorLabel(
      l10n,
      author,
      isMe: isMe,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );

/// ▶ drawn, so it never depends on an icon font.
class PlayGlyph extends StatelessWidget {
  const PlayGlyph({this.size = 10, this.color = Colors.white, super.key});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PlayPainter(color));
}

class _PlayPainter extends CustomPainter {
  _PlayPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.08)
      ..lineTo(size.width * 0.92, size.height * 0.5)
      ..lineTo(size.width * 0.18, size.height * 0.92)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PlayPainter old) => old.color != color;
}

/// "★ Lần đầu cười · 5 thg 10" (sunshine chip).
class MilestoneChip extends StatelessWidget {
  const MilestoneChip({
    required this.milestone,
    this.compact = false,
    super.key,
  });
  final MilestoneRef milestone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = compact
        ? milestone.name
        : l10n.msChip(
            milestone.name,
            DateFormat('d MMM', locale).format(milestone.date),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.star, size: 14, color: cl.colors.onWarm),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                color: cl.colors.onWarm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lock = Chỉ ba mẹ, family = Gia đình (entry header, album badge).
class AudienceIcon extends StatelessWidget {
  const AudienceIcon({
    required this.audience,
    this.size = 16,
    this.color,
    super.key,
  });
  final Audience audience;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: audience == Audience.family ? l10n.audFamily : l10n.audParents,
      child: ClIcon(
        audience == Audience.family ? ClIcons.family : ClIcons.lock,
        size: size,
        color: color ?? context.cl.colors.inkMuted,
      ),
    );
  }
}

/// MediaTile (131:860): Default · Selected · Uploading. Overlays: video duration, Private lock.
class MediaTile extends StatelessWidget {
  const MediaTile({
    required this.item,
    this.onTap,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
    this.radius = 6,
    this.favorite = false,
    super.key,
  });

  final MediaItem item;

  /// In my Yêu thích: bookmark bottom-right (R-107).
  final bool favorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final path = item.thumbPath;
    return ClPressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: item.isVideo
          ? '${l10n.pickVideos} ${videoDuration(item.durationMs)}'
          : l10n.memPhotos,
      selected: selecting ? selected : null,
      haptic: false,
      minSize: Size.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cl.colors.surface2),
            if (path != null)
              Image(
                image: StorageImage(path),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              )
            else if (item.isVideo)
              Center(
                child: ClIcon(
                  ClIcons.memories,
                  size: 22,
                  color: cl.colors.inkMuted,
                ),
              ),
            if (!item.isReady)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (item.isVideo)
              Positioned(
                left: 6,
                bottom: 6,
                child: _Badge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      Text(
                        videoDuration(item.durationMs),
                        style: cl.text.caption.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (favorite)
              Positioned(
                right: 6,
                bottom: 6,
                child: _Badge(
                  child: ClIcon(
                    ClIcons.bookmark,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            if (item.isPrivate)
              Positioned(
                left: 6,
                top: 6,
                child: _Badge(
                  child: ClIcon(ClIcons.lock, size: 12, color: Colors.white),
                ),
              ),
            if (selecting)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? cl.colors.mintDeep : Colors.black26,
                    border: Border.all(color: Colors.white, width: 1.8),
                  ),
                  child: selected
                      ? ClIcon(
                          ClIcons.check,
                          size: 14,
                          color: cl.colors.onMintDeep,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
    ),
    child: child,
  );
}

/// The author's initial in a mint circle ("M" · "Mẹ", 10a).
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({required this.name, super.key});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initialOf(name),
        style: cl.text.caption.copyWith(
          color: cl.colors.mintText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One journal entry (10a "Entry · 1 ảnh / 1 video / 2 ảnh / ghi chú / nhiều ảnh").
class MemoryEntryCard extends StatelessWidget {
  const MemoryEntryCard({
    required this.memory,
    required this.items,
    required this.myUid,
    required this.dateLabel,
    required this.onOpen,
    this.favorites = const {},
    this.footer,
    super.key,
  });

  final Memory memory;

  /// My Yêu thích (bookmark on tiles).
  final Set<String> favorites;

  /// Loves and "Nhắn ba mẹ" (S10).
  final Widget? footer;

  /// Its visible items, in order.
  final List<MediaItem> items;
  final String myUid;
  final String dateLabel;
  final void Function(MediaItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final note = items.isEmpty;
    final who = whoLabel(l10n, memory.author, memory.createdBy == myUid);
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: note ? cl.colors.sunshineSoft : cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 4),
        boxShadow: note ? null : cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuthorAvatar(name: memory.author.name),
              const SizedBox(width: ClSpace.s2),
              Text(
                who,
                style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              AudienceIcon(audience: memory.audience),
            ],
          ),
          if (memory.milestone != null) ...[
            const SizedBox(height: ClSpace.s2),
            MilestoneChip(milestone: memory.milestone!),
          ],
          if (memory.caption != null && memory.caption!.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s2),
            Text(
              memory.caption!,
              style: (note ? cl.text.body : cl.text.label).copyWith(
                color: note ? cl.colors.onWarm : cl.colors.ink,
              ),
            ),
          ],
          if (!note) ...[
            const SizedBox(height: ClSpace.s2),
            _EntryMedia(items: items, onOpen: onOpen, favorites: favorites),
          ],
          if (footer != null) ...[const SizedBox(height: ClSpace.s2), footer!],
        ],
      ),
    );
  }
}

class _EntryMedia extends StatelessWidget {
  const _EntryMedia({
    required this.items,
    required this.onOpen,
    required this.favorites,
  });
  final Set<String> favorites;
  final List<MediaItem> items;
  final void Function(MediaItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) {
      final i = items.single;
      final ratio = (i.width != null && i.height != null && i.height! > 0)
          ? (i.width! / i.height!).clamp(0.75, 1.6)
          : 4 / 3;
      return AspectRatio(
        aspectRatio: ratio,
        child: MediaTile(
          item: i,
          favorite: favorites.contains(i.id),
          radius: ClRadius.control,
          onTap: () => onOpen(i),
        ),
      );
    }
    if (items.length == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(
          children: [
            for (final (n, i) in items.indexed) ...[
              if (n > 0) const SizedBox(width: 4),
              Expanded(
                child: MediaTile(
                  item: i,
                  favorite: favorites.contains(i.id),
                  radius: ClRadius.control,
                  onTap: () => onOpen(i),
                ),
              ),
            ],
          ],
        ),
      );
    }
    final shown = items.take(6).toList();
    final extra = items.length - shown.length;
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (final (n, i) in shown.indexed)
          Stack(
            fit: StackFit.expand,
            children: [
              MediaTile(
                item: i,
                favorite: favorites.contains(i.id),
                onTap: () => onOpen(i),
              ),
              if (extra > 0 && n == shown.length - 1)
                IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: Text(
                          '+$extra',
                          style: context.cl.text.headline.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// UploadPill (132:898): Uploading · Paused · Failed · Done (+ Wi-Fi and quota waits).
class UploadPill extends ConsumerWidget {
  const UploadPill({required this.babyId, required this.onOpen, super.key});
  final String babyId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(uploadQueueProvider);
    final batches = [
      for (final b in view.batches)
        if (b.babyId == babyId && !b.dismissed) b,
    ];
    if (batches.isEmpty) return const SizedBox.shrink();
    final items = [for (final b in batches) ...b.items];
    final live = items.where((i) => i.state != QueueState.cancelled).toList();
    if (live.isEmpty) return const SizedBox.shrink();
    int count(QueueState s) => live.where((i) => i.state == s).length;
    final done = count(QueueState.uploaded);
    final failed = count(QueueState.failed);
    final unreadable = count(QueueState.unreadable);
    final wifi = count(QueueState.waitingWifi);
    final quota = count(QueueState.waitingQuota);
    final preparing = count(QueueState.pendingSession);
    final paused = live.any((i) => i.state == QueueState.paused);
    final finished = batches.every((b) => b.done);
    final total = live.length;
    final sent = live.fold<int>(0, (s, i) => s + math.min(i.sent, i.bytes));
    final bytes = live.fold<int>(0, (s, i) => s + i.bytes);
    final progress = bytes == 0 ? 0.0 : sent / bytes;

    String title;
    String subtitle;
    // A waiting or failed upload shows a still icon, never a spinner (only active work spins).
    ClIcons? still;
    var tone = cl.colors.mintSoft;
    var ink = cl.colors.ink;
    if (finished) {
      title = l10n.upDone(done);
      final last = batches.last;
      final notified = last.notifyFamily
          ? ref.watch(notifiedProvider((babyId, last.batchId))).value
          : null;
      subtitle = notified != null && notified.isNotEmpty
          ? l10n.upToldFamily(
              notified.map((a) => whoLabel(l10n, a, false)).join(', '),
            )
          : last.notifyFamily
          ? l10n.upUploadingHint
          : l10n.upParentsOnly;
    } else if (quota > 0 && quota + done + unreadable == total) {
      title = l10n.upWaitingQuota(quota);
      subtitle = l10n.upWaitingQuotaHint;
      still = ClIcons.clock;
      tone = cl.colors.errorSoft;
    } else if (failed + unreadable > 0 && failed + unreadable + done == total) {
      title = l10n.upFailed(failed + unreadable);
      subtitle = l10n.upFailedHint;
      still = ClIcons.alert;
      tone = cl.colors.errorSoft;
      ink = cl.colors.error;
    } else if (batches.any((b) => b.paused)) {
      title = l10n.upUploadsPaused;
      subtitle = l10n.upUploadsPausedHint;
      still = ClIcons.clock;
      tone = cl.colors.sunshineSoft;
    } else if (view.paused) {
      title = l10n.upPausedByYou;
      subtitle = l10n.upPausedByYouHint;
      still = ClIcons.clock;
      tone = cl.colors.sunshineSoft;
    } else if (paused) {
      title = l10n.upPaused;
      subtitle = l10n.upPausedHint;
      still = ClIcons.cloudOff;
      tone = cl.colors.sunshineSoft;
    } else if (wifi > 0 && wifi + done + unreadable == total) {
      title = l10n.upWaitingWifi(wifi);
      subtitle = l10n.upWaitingWifiHint;
      still = ClIcons.clock;
      tone = cl.colors.sunshineSoft;
    } else if (preparing == total) {
      title = l10n.upPreparing(total);
      subtitle = l10n.upUploadingHint;
    } else {
      title = l10n.upUploading(done, total);
      subtitle = l10n.upUploadingHint;
    }
    final thumb = live.firstWhere(
      (i) => !i.isVideo || i.posterPath != null,
      orElse: () => live.first,
    );
    final thumbPath = thumb.isVideo ? thumb.posterPath : thumb.localPath;

    return ClPressable(
      onPressed: onOpen,
      semanticLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: tone,
          borderRadius: BorderRadius.circular(ClRadius.card - 4),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.sm),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: cl.colors.surface2),
                    if (thumbPath != null && File(thumbPath).existsSync())
                      Image.file(
                        File(thumbPath),
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                      ),
                    if (!finished && still != null)
                      ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: ClIcon(still, size: 20, color: Colors.white),
                        ),
                      )
                    else if (!finished)
                      ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: progress == 0 ? null : progress,
                              strokeWidth: 2.4,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                      )
                    else
                      ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: ClIcon(
                            ClIcons.check,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(color: ink)),
                  if (!finished) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: cl.colors.mintDeep,
                        backgroundColor: cl.colors.surface,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClIcon(ClIcons.chevronRight, size: 20, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
