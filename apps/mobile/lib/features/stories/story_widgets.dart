import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import 'story_models.dart';

/// The baby's media the viewer may see, by id (story photos are references, R-133).
Map<String, MediaItem> storyMedia(WidgetRef ref, String babyId, bool parent) =>
    {
      for (final m
          in ref.watch(mediaProvider((babyId, parent))).value ??
              const <MediaItem>[])
        if (m.isReady && !m.deleted) m.id: m,
    };

/// "hôm nay" / "hôm qua" / "5 thg 10" in the baby's zone.
String storyWhen(
  AppLocalizations l10n,
  String zone,
  DateTime now,
  DateTime at,
  String locale,
) {
  final local = inBabyZone(zone, at);
  final today = babyToday(zone, now);
  final diff = today
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  return switch (diff) {
    0 => l10n.dayToday,
    1 => l10n.dayYesterday,
    _ => DateFormat('d MMM', locale).format(local),
  };
}

/// "Mẹ kể" / "Ba viết": who wrote it.
String storyAuthor(AppLocalizations l10n, Story s, String myUid) =>
    s.author == null ? '' : whoLabel(l10n, s.author!, s.createdBy == myUid);

/// A story photo from Kỷ niệm; a soft placeholder when the viewer cannot see it.
class StoryImage extends StatelessWidget {
  const StoryImage({
    required this.item,
    this.display = false,
    this.radius = 0,
    super.key,
  });
  final MediaItem? item;
  final bool display;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final path = display ? item?.displayPath : item?.thumbPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: cl.colors.surface2),
          if (path != null) Image(image: StorageImage(path), fit: BoxFit.cover),
          if (item?.isVideo == true) const Center(child: PlayGlyph(size: 16)),
        ],
      ),
    );
  }
}

/// "★ Lần đầu cười · 5 thg 10" chip (14a, 14g).
class StoryMilestoneChip extends StatelessWidget {
  const StoryMilestoneChip({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 4),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.star, size: 12, color: cl.colors.ink),
          const SizedBox(width: 4),
          Text(
            label,
            style: cl.text.caption.copyWith(
              color: cl.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Letters and the 14f preview sit on cream paper ("Story · thư", #FBF6ED); a warm dark sheet
/// in Night care.
Color storyPaper(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2A2620)
    : const Color(0xFFFBF6ED);
