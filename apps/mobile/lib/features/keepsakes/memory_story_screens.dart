import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auto_save/library_save.dart';
import '../memories/media_bytes.dart';
import '../memories/media_picker.dart';
import '../memories/media_viewer.dart';
import '../memories/memories_screen.dart' show MemoryCtx, memoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart' show PlayGlyph;
import '../memories/upload_queue.dart';
import 'keepsake_access.dart';
import 'keepsake_card_content.dart' show keepsakeVideoLabel;
import 'keepsake_card_view.dart' show keepsakeAssetImageProvider;
import 'keepsake_entries.dart' show markKeepsakeVideoSeen;
import 'keepsake_catalog.dart';
import 'keepsake_jobs.dart';
import 'keepsake_live.dart';
import 'keepsake_occasions.dart';
import 'keepsake_preview.dart';
import 'milestone_card_screens.dart'
    show
        KeepsakeActionTile,
        KeepsakePage,
        KeepsakePreviewPage,
        KeepsakeRoundIcon,
        keepsakePhotosLabel,
        OccasionFilter,
        TierBadge;

/// Video kỷ niệm (D-068; Figma MM06 `529:9070` chọn ảnh, MM07 `530:9248` hoàn thiện, MM08
/// `530:9372` đang tạo, MM09 `530:9423` đã sẵn sàng, MM13 `531:9447` chưa đủ ảnh, MM14
/// `531:9555` chưa thành công). The template list stands in for MM04 / MM05, which were not
/// found in the file (G-107). Rendering happens on the server (Remotion on Cloud Run) and goes on
/// with the app closed; the video lands in Kỷ niệm as Chỉ ba mẹ unless chosen otherwise.

final _day = DateFormat('dd.MM.yyyy');

/// The choices between MM04 and MM07.
@immutable
class VideoDraft {
  const VideoDraft({
    required this.babyId,
    required this.template,
    this.occasion,
    this.mediaIds = const [],
    this.title,
    this.message,
    this.audience = Audience.parents,
    this.requestId,
  });

  final String babyId;
  final KeepsakeTemplate template;
  final Occasion? occasion;

  /// In scene order.
  final List<String> mediaIds;
  final String? title;
  final String? message;
  final Audience audience;

  /// Kept across retries of the same "Tạo video" press.
  final String? requestId;

  VideoDraft copyWith({
    KeepsakeTemplate? template,
    List<String>? mediaIds,
    String? title,
    String? message,
    Audience? audience,
    String? requestId,
  }) => VideoDraft(
    babyId: babyId,
    template: template ?? this.template,
    occasion: occasion,
    mediaIds: mediaIds ?? this.mediaIds,
    title: title ?? this.title,
    message: message ?? this.message,
    audience: audience ?? this.audience,
    requestId: requestId ?? this.requestId,
  );
}

String _fill(String s, String name) => s.replaceAll('{name}', name);

/// The occasion's day for the cover and "Ngày mốc" (today when there is none).
DateTime videoDay(MemoryCtx c, Occasion? o, List<MediaItem> media) {
  final dob = c.dob;
  if (o == null || dob == null) return c.now;
  return o.dateFor(dob, [for (final m in media) ?m.milestone]) ?? c.now;
}

/// Photos suited to a template: taken within its age window (all ready photos when it has none).
List<MediaItem> suitedPhotos(
  List<MediaItem> media,
  KeepsakeTemplate t,
  DateTime? dob,
) {
  final photos = [
    for (final m in media)
      if (m.isReady && !m.deleted && !m.isVideo && m.generatedKind == null) m,
  ];
  final age = t.ageDays;
  if (age == null || dob == null) return photos;
  final from = DateTime(dob.year, dob.month, dob.day + age.min);
  final to = DateTime(dob.year, dob.month, dob.day + age.max + 1);
  return [
    for (final m in photos)
      if (!m.captureAt.isBefore(from) && m.captureAt.isBefore(to)) m,
  ];
}

/// A 9:16 cover: the first photo, the mark ("1"), the title (MM07 – MM09, MM14).
class VideoCover extends StatelessWidget {
  const VideoCover({
    required this.width,
    required this.title,
    this.photoPath,
    this.image,
    this.mark,
    this.dateLine,
    this.dim = false,
    this.overlay,
    this.duration,
    super.key,
  });
  final double width;
  final String title;
  final String? photoPath;

  /// A picture drawn as is (the template's own cover), in place of [photoPath].
  final ImageProvider? image;
  final String? mark;
  final String? dateLine;
  final bool dim;
  final Widget? overlay;
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final s = width / 160;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14 * s),
      child: SizedBox(
        width: width,
        height: width * 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cl.colors.surface2),
            if (image != null || photoPath != null)
              Image(
                image: image ?? StorageImage(photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            if (title.isNotEmpty || mark != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1],
                    colors: [Color(0x00000000), Color(0xB3000000)],
                  ),
                ),
              ),
            if (dim) const ColoredBox(color: Color(0x8C000000)),
            Positioned(
              left: 10 * s,
              right: 10 * s,
              bottom: 12 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mark != null)
                    Text(
                      mark!,
                      style: TextStyle(
                        fontSize: 44 * s,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(
                          alpha: dim ? 0.45 : 0.95,
                        ),
                      ),
                    ),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15 * s,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(
                          alpha: dim ? 0.45 : 0.95,
                        ),
                      ),
                    ),
                  if (dateLine != null) ...[
                    SizedBox(height: 4 * s),
                    Text(
                      dateLine!,
                      style: TextStyle(
                        fontSize: 11 * s,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (duration != null)
              Positioned(
                right: 8 * s,
                top: 8 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * s,
                    vertical: 2 * s,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x8C000000),
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    duration!,
                    style: TextStyle(
                      fontSize: 10 * s,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

String _mmss(int? ms) {
  final s = ((ms ?? 0) / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------------------------
// MM04 / MM05 (not found in Figma, G-107): choose a template

class MemoryStoryTemplatesScreen extends ConsumerStatefulWidget {
  const MemoryStoryTemplatesScreen({
    this.occasion,
    this.photoIds,
    this.embedded = false,
    super.key,
  });

  /// A page of [KeepsakeKindsScreen]: no back button or title of its own.
  final bool embedded;
  final Occasion? occasion;

  /// Photos chosen in Kỷ niệm (a selection's "Tạo video kỷ niệm"): they fill the scenes first.
  final List<String>? photoIds;

  @override
  ConsumerState<MemoryStoryTemplatesScreen> createState() => _TemplatesState();
}

class _TemplatesState extends ConsumerState<MemoryStoryTemplatesScreen> {
  /// The dịp chip; null is "Tất cả". Starts on the occasion we came for (MM03, MM12).
  late Occasion? _filter = widget.occasion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = memoryCtx(context, ref);
    final access = ref.watch(selectedKeepsakeAccessProvider);
    if (c == null || !c.isParent || !access.videos) {
      return KeepsakePage(
        title: l10n.ksVideoTitle,
        children: [
          ClEmptyState(
            icon: ClIcons.camera,
            title: l10n.ksUnavailableTitle,
            message: l10n.ksUnavailableBodyVideo,
          ),
        ],
      );
    }
    final catalog = ref.watch(keepsakeCatalogProvider);
    final media = ref.watch(mediaProvider((c.babyId, true))).value ?? const [];
    final milestones = [for (final m in media) ?m.milestone];
    // "Gợi ý": the chosen dịp, else the one the baby's age is near (the same rule as Thiệp cột
    // mốc), else templates whose age window holds the baby's age today.
    final dob = c.dob;
    final near = dob == null ? null : suggestedOccasion(dob, c.now);
    final focus = _filter ?? near;
    final ageDays = dob == null
        ? null
        : DateTime(
            c.now.year,
            c.now.month,
            c.now.day,
          ).difference(DateTime(dob.year, dob.month, dob.day)).inDays;
    bool suggested(KeepsakeTemplate t) =>
        (focus != null && t.occasions.contains(focus.wire)) ||
        (_filter == null &&
            ageDays != null &&
            t.ageDays != null &&
            ageDays >= t.ageDays!.min &&
            ageDays <= t.ageDays!.max);
    // A dịp shows its own templates, then those made for any day.
    final videos =
        [
          for (final t in catalog.value?.videos ?? const <KeepsakeTemplate>[])
            if (_filter == null ||
                t.occasions.isEmpty ||
                t.occasions.contains(_filter!.wire))
              t,
        ]..sort((a, b) {
          final ma = suggested(a) ? 0 : 1;
          final mb = suggested(b) ? 0 : 1;
          return ma != mb ? ma - mb : a.order.compareTo(b.order);
        });
    final locale = Localizations.localeOf(context);
    final assetOf = ref.watch(keepsakeAssetImageProvider);
    return KeepsakePage(
      title: l10n.ksVideoTitle,
      embedded: widget.embedded,
      children: [
        // The same "Chọn dịp" row as Thiệp; "Tất cả" first, since here it filters.
        if (dob != null)
          OccasionFilter(
            occasions: Occasion.chipsFor(
              dob,
              c.now,
              milestones,
              current: _filter,
            ),
            selected: _filter,
            suggested: near,
            allLabel: l10n.filterAll,
            onSelect: (o) => setState(() => _filter = o),
          ),
        const SizedBox(height: ClSpace.s4),
        if (catalog.isLoading && !catalog.hasValue)
          const ClSkeleton(height: 280)
        else if (videos.isEmpty)
          ClEmptyState(
            icon: ClIcons.camera,
            title: l10n.ksNoTemplates,
            message: l10n.ksNoTemplatesBody,
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - ClSpace.s3) / 2;
              return Wrap(
                spacing: ClSpace.s3,
                runSpacing: ClSpace.s4,
                children: [
                  for (final t in videos)
                    _VideoTemplateTile(
                      template: t,
                      width: w,
                      name: c.nickname,
                      // The template's own cover (made in the portal); the baby's photo for a
                      // template published without one.
                      cover: t.thumb == null ? null : assetOf(t.thumb!),
                      photo: t.thumb != null
                          ? null
                          : suitedPhotos(
                              media,
                              t,
                              c.dob,
                            ).firstOrNull?.displayPath,
                      suggested: suggested(t),
                      badge: catalog.value!.badges,
                      locale: locale,
                      // The template first, with what it needs; "Dùng mẫu này" there goes
                      // on to MM06 (owner, 2026-10-14).
                      onTap: () => context.push(
                        Routes.memoryStoryPreview,
                        extra: VideoPreviewArgs(
                          draft: VideoDraft(
                            babyId: c.babyId,
                            template: t,
                            mediaIds: [...?widget.photoIds?.take(t.photosMax)],
                            occasion:
                                (_filter != null &&
                                        (t.occasions.isEmpty ||
                                            t.occasions.contains(_filter!.wire))
                                    ? _filter
                                    : null) ??
                                (focus != null &&
                                        t.occasions.contains(focus.wire)
                                    ? focus
                                    : t.occasions.length == 1
                                    ? Occasion.fromWire(t.occasions.first)
                                    : null),
                          ),
                          name: c.nickname,
                          cover: t.thumb == null ? null : assetOf(t.thumb!),
                          photo: t.thumb != null
                              ? null
                              : suitedPhotos(
                                  media,
                                  t,
                                  c.dob,
                                ).firstOrNull?.displayPath,
                          suggested: suggested(t),
                          badge: catalog.value!.badges,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// What a video template's preview needs: the draft "Dùng mẫu này" goes on with, and the
/// cover as drawn in the grid.
class VideoPreviewArgs {
  const VideoPreviewArgs({
    required this.draft,
    required this.name,
    this.cover,
    this.photo,
    this.suggested = false,
    this.badge = true,
  });
  final VideoDraft draft;
  final String name;
  final ImageProvider? cover;
  final String? photo;
  final bool suggested;
  final bool badge;
}

/// A video template before it is used (owner, 2026-10-14): the cover large with "Xem mẫu", its
/// name and tier, length, photos, format and dịp, and "Dùng mẫu này" on to MM06. Not drawn
/// in Figma.
class VideoTemplatePreviewScreen extends ConsumerWidget {
  const VideoTemplatePreviewScreen({required this.args, super.key});
  final VideoPreviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final t = args.draft.template;
    final title = _fill(
      t.text('title')?.defaultText.of(locale) ?? '',
      args.name,
    );
    final mark = t.occasions.length == 1
        ? Occasion.fromWire(t.occasions.first)?.title(l10n).split(' ').first
        : null;
    final number = mark != null && int.tryParse(mark) != null ? mark : null;
    final occasions = [
      for (final o in t.occasions) ?Occasion.fromWire(o)?.label(l10n),
    ];
    return KeepsakePreviewPage(
      name: t.name.of(locale),
      premium: t.premium,
      badge: args.badge,
      note: args.suggested ? l10n.ksSuggested : null,
      preview: Center(
        child: Stack(
          children: [
            VideoCover(
              width: 220,
              title: args.cover != null ? '' : title,
              image: args.cover,
              photoPath: args.photo,
              mark: args.cover == null ? number : null,
              duration: t.durationSec == null
                  ? null
                  : _mmss(t.durationSec! * 1000),
            ),
            // "Xem mẫu": the template playing with sample pictures (MM04 / MM05).
            Positioned.fill(
              child: Center(
                child: ClPressable(
                  onPressed: () => ref.read(keepsakePreviewLauncherProvider)(
                    context,
                    demoPreview(
                      t,
                      name: args.name,
                      locale: locale,
                      track: ref
                          .read(keepsakeCatalogProvider)
                          .value
                          ?.track(t.defaultMusic),
                      mark: number,
                    ),
                  ),
                  semanticLabel: l10n.ksPreviewSample,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xE6FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: PlayGlyph(size: 20, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      facts: [
        if (t.durationSec != null)
          (l10n.ksInfoDuration, _mmss(t.durationSec! * 1000)),
        (
          l10n.ksInfoPhotos,
          keepsakePhotosLabel(l10n, t.photosMin, t.photosMax),
        ),
        (l10n.ksInfoFormat, l10n.ksFormatStory),
        (
          l10n.ksInfoOccasion,
          occasions.isEmpty ? l10n.ksAnyOccasion : occasions.join(' · '),
        ),
      ],
      onUse: () => context.push(Routes.memoryStoryPhotos, extra: args.draft),
    );
  }
}

class _VideoTemplateTile extends StatelessWidget {
  const _VideoTemplateTile({
    required this.template,
    required this.width,
    required this.name,
    required this.cover,
    required this.photo,
    required this.suggested,
    required this.badge,
    required this.locale,
    required this.onTap,
  });
  final KeepsakeTemplate template;
  final double width;
  final String name;
  final ImageProvider? cover;
  final String? photo;
  final bool suggested;
  final bool badge;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final title = _fill(
      template.text('title')?.defaultText.of(locale) ?? '',
      name,
    );
    final mark = template.occasions.length == 1
        ? Occasion.fromWire(
            template.occasions.first,
          )?.title(l10n).split(' ').first
        : null;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: template.name.of(locale),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                VideoCover(
                  width: width,
                  // The cover already shows the template; the name is under it.
                  title: cover != null ? '' : title,
                  image: cover,
                  photoPath: photo,
                  mark:
                      cover == null &&
                          mark != null &&
                          int.tryParse(mark) != null
                      ? mark
                      : null,
                  duration: template.durationSec == null
                      ? null
                      : _mmss(template.durationSec! * 1000),
                ),
                if (badge)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: TierBadge(premium: template.premium),
                  ),
                // "Xem mẫu": the template playing with sample pictures (MM04 / MM05, G-107).
                Positioned.fill(
                  child: Center(
                    child: Consumer(
                      builder: (context, ref, _) => ClPressable(
                        onPressed: () =>
                            ref.read(keepsakePreviewLauncherProvider)(
                              context,
                              demoPreview(
                                template,
                                name: name,
                                locale: locale,
                                track: ref
                                    .read(keepsakeCatalogProvider)
                                    .value
                                    ?.track(template.defaultMusic),
                                mark: mark != null && int.tryParse(mark) != null
                                    ? mark
                                    : null,
                              ),
                            ),
                        semanticLabel: l10n.ksPreviewSample,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xE6FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: PlayGlyph(size: 16, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(
                    template.name.of(locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.label.copyWith(
                      color: cl.colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (suggested) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.ksSuggested,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              l10n.ksVideoNeeds(template.photosMin, template.photosMax),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// MM06 / MM13 · chọn ảnh cho video

class MemoryStoryPhotosScreen extends ConsumerStatefulWidget {
  const MemoryStoryPhotosScreen({required this.draft, super.key});
  final VideoDraft draft;

  @override
  ConsumerState<MemoryStoryPhotosScreen> createState() => _PhotosState();
}

/// MM06: the photos that suit a scene, best first. Those tagged with its milestone (or, for a
/// scene with no time of its own, with the video's) come first; then those taken in its window,
/// closest to its middle. A scene with no window takes the template's photos, newest first (or
/// closest to the occasion's [day]).
List<MediaItem> scenePhotos(
  List<MediaItem> photos,
  KeepsakeTemplate template,
  KeepsakeScene? scene, {
  required DateTime? dob,
  Occasion? occasion,
  DateTime? day,
}) {
  final window = scene?.ageDays;
  final milestone =
      Occasion.fromWire(scene?.occasion)?.milestoneId ??
      (window == null ? occasion?.milestoneId : null);
  int? ageOf(MediaItem m) => dob == null
      ? null
      : DateTime(
          m.captureAt.year,
          m.captureAt.month,
          m.captureAt.day,
        ).difference(DateTime(dob.year, dob.month, dob.day)).inDays;
  bool tagged(MediaItem m) => milestone != null && m.milestone?.id == milestone;
  final pool = window == null
      ? suitedPhotos(photos, template, dob)
      : [
          // The baby's own photos only (never a card or a video Child Life made).
          for (final m in suitedPhotos(photos, template.copyWithoutAge(), dob))
            if (tagged(m) ||
                (ageOf(m) != null &&
                    ageOf(m)! >= window.min &&
                    ageOf(m)! <= window.max))
              m,
        ];
  final mid = window == null ? null : (window.min + window.max) / 2;
  int rank(MediaItem a, MediaItem b) {
    final t = (tagged(a) ? 0 : 1) - (tagged(b) ? 0 : 1);
    if (t != 0) return t;
    if (mid != null) {
      return (ageOf(a)! - mid).abs().compareTo((ageOf(b)! - mid).abs());
    }
    if (day != null && occasion != null) {
      return a.captureAt
          .difference(day)
          .abs()
          .compareTo(b.captureAt.difference(day).abs());
    }
    return b.captureAt.compareTo(a.captureAt);
  }

  return pool..sort(rank);
}

class _PhotosState extends ConsumerState<MemoryStoryPhotosScreen> {
  late VideoDraft _d = widget.draft;

  /// The photo of each scene (null: empty), in scene order.
  late var _slots = _slotted(widget.draft.mediaIds, _d.template.photosMax);

  /// The scene the photos below are suggested for, and that a tap fills.
  late var _active = math.max(0, _slots.indexOf(null));

  /// Photos sent from the phone's library (as Chỉ ba mẹ memories): picked once they are ready.
  final _importing = <String>{};
  var _fromDevice = false;

  static List<String?> _slotted(List<String> ids, int slots) => [
    for (var i = 0; i < slots; i++) i < ids.length ? ids[i] : null,
  ];

  List<String> get _picked => [for (final id in _slots) ?id];

  /// The next empty scene after [from] (wrapping), else [from].
  int _nextEmpty(int from) {
    for (var k = 1; k <= _slots.length; k++) {
      final i = (from + k) % _slots.length;
      if (_slots[i] == null) return i;
    }
    return from;
  }

  /// A photo tapped: into the chosen scene (moved there if another scene had it), or out of it.
  void _assign(String id) => setState(() {
    if (_slots[_active] == id) {
      _slots[_active] = null;
      return;
    }
    final was = _slots.indexOf(id);
    if (was >= 0) _slots[was] = null;
    _slots[_active] = id;
    _active = _nextEmpty(_active);
  });

  Future<void> _addFromDevice(MemoryCtx c) async {
    final l10n = AppLocalizations.of(context);
    final picked = await pickFromLibrary(context, ref);
    final photos = [
      for (final p in picked ?? const <PickedMedia>[])
        if (p.type == MediaKind.photo) p,
    ];
    setState(() => _fromDevice = false);
    if (photos.isEmpty || !mounted) return;
    final memoryId = newMemoryId();
    await ref
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: c.babyId,
          request: {
            'babyId': c.babyId,
            'memoryId': memoryId,
            'batchId': newBatchId(),
            'caption': null,
            'audience': Audience.parents.name,
            'notifyFamily': false,
            'dateMode': 'capture',
            'date': null,
            'milestone': null,
            'albumIds': const <String>[],
          },
          picked: photos,
        );
    if (!mounted) return;
    setState(() => _importing.add(memoryId));
    ClToaster.of(context).show(message: l10n.ksVideoImporting(photos.length));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c == null) return const SizedBox.shrink();
    final t = _d.template;
    final locale = Localizations.localeOf(context);
    final media = ref.watch(mediaProvider((c.babyId, true))).value ?? const [];
    final byId = {for (final m in media) m.id: m};
    // Photos sent from the phone fill the empty scenes once processed, from the chosen one on.
    for (final m in media) {
      if (_importing.contains(m.memoryId) &&
          m.isReady &&
          !m.isVideo &&
          !_slots.contains(m.id) &&
          _slots.contains(null)) {
        final i = _slots[_active] == null ? _active : _nextEmpty(_active);
        _slots[i] = m.id;
        _active = _nextEmpty(i);
      }
    }
    final suited = suitedPhotos(media, t, c.dob);
    final suitedIds = {for (final m in suited) m.id};
    // The baby's own photos (never a card or a video Child Life made).
    final all = suitedPhotos(media, t.copyWithoutAge(), c.dob);
    final picked = _picked;
    final enough =
        suited.length + picked.where((id) => !suitedIds.contains(id)).length >=
        t.photosMin;
    final count = picked.length;
    final needMore = t.photosMin - count;
    final scene = _active < t.scenes.length ? t.scenes[_active] : null;
    final day = videoDay(c, _d.occasion, media);
    // Photos already in another scene are not suggested again; they wait at the end of Ảnh khác.
    final elsewhere = {
      for (var i = 0; i < _slots.length; i++)
        if (i != _active) ?_slots[i],
    };
    final forScene = [
      for (final m in scenePhotos(
        all,
        t,
        scene,
        dob: c.dob,
        occasion: _d.occasion,
        day: day,
      ))
        if (!elsewhere.contains(m.id)) m,
    ];
    final forSceneIds = {for (final m in forScene) m.id};
    final unsorted = [
      for (final m in [
        ...(suited..sort((a, b) => a.captureAt.compareTo(b.captureAt))),
        ...[
          for (final m in all)
            if (!suitedIds.contains(m.id)) m,
        ]..sort((a, b) => b.captureAt.compareTo(a.captureAt)),
      ])
        if (!forSceneIds.contains(m.id)) m,
    ];
    final others = [
      for (final m in unsorted)
        if (!elsewhere.contains(m.id)) m,
      for (final m in unsorted)
        if (elsewhere.contains(m.id)) m,
    ];
    final window = scene?.ageDays;
    final dob = c.dob;
    final dmy = DateFormat('dd.MM.yyyy');
    final when = window == null || dob == null
        ? l10n.ksVideoSceneAny
        : l10n.ksVideoSceneWindow(
            dmy.format(DateTime(dob.year, dob.month, dob.day + window.min)),
            dmy.format(DateTime(dob.year, dob.month, dob.day + window.max)),
          );
    // MM13 "Đổi sang mẫu ngắn hơn": one that needs fewer photos and has enough suited to it.
    final shorter = [
      for (final v
          in ref.watch(keepsakeCatalogProvider).value?.videos ??
              const <KeepsakeTemplate>[])
        if (v.id != t.id &&
            v.photosMin < t.photosMin &&
            suitedPhotos(media, v, c.dob).length >= v.photosMin)
          v,
    ]..sort((a, b) => b.photosMin.compareTo(a.photosMin));

    Widget grid(List<MediaItem> items) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      sliver: SliverGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final m in items)
            _PickTile(
              item: m,
              order: _slots.indexOf(m.id) + 1,
              onTap: () => _assign(m.id),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            ClBackButton(
                              semanticLabel: l10n.a11yBack,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            Text(
                              t.name.of(locale),
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ClSpace.s3),
                        Text(
                          l10n.ksVideoPhotosTitle,
                          style: cl.text.largeTitle,
                        ),
                        const SizedBox(height: ClSpace.s4),
                        _SceneStrip(
                          template: t,
                          slots: [for (final id in _slots) byId[id]],
                          active: _active,
                          enough: count >= t.photosMin,
                          onSelect: (i) => setState(() => _active = i),
                          onClear: (i) => setState(() {
                            _slots[i] = null;
                            _active = i;
                          }),
                        ),
                        if (!enough) ...[
                          const SizedBox(height: ClSpace.s3),
                          _NotEnough(
                            name: c.nickname,
                            have: suited.length,
                            need: t.photosMin,
                            shorter: shorter.firstOrNull,
                            onDevice: () => _addFromDevice(c),
                            onShorter: (v) => setState(() {
                              _d = _d.copyWith(template: v);
                              _slots = _slotted(_picked, v.photosMax);
                              _active = math.max(0, _slots.indexOf(null));
                            }),
                          ),
                        ],
                        const SizedBox(height: ClSpace.s4),
                        ClSegmented<bool>(
                          options: const [false, true],
                          selected: _fromDevice,
                          labelOf: (d) =>
                              d ? l10n.ksFromDevice : l10n.ksFromMemories,
                          onChanged: (d) {
                            setState(() => _fromDevice = d);
                            if (d) unawaited(_addFromDevice(c));
                          },
                        ),
                        if (scene != null) ...[
                          const SizedBox(height: ClSpace.s4),
                          Row(
                            children: [
                              ClIcon(
                                ClIcons.spark,
                                size: 14,
                                color: cl.colors.mintText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.ksVideoForScene(
                                    _active + 1,
                                    scene.hint.of(locale),
                                  ),
                                  style: cl.text.label.copyWith(
                                    color: cl.colors.mintText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              when,
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ),
                          if (forScene.isEmpty) ...[
                            const SizedBox(height: ClSpace.s2),
                            Text(
                              scene.optional
                                  ? l10n.ksVideoSceneEmptyOptional
                                  : l10n.ksVideoSceneEmpty,
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: ClSpace.s3),
                      ],
                    ),
                  ),
                  grid(forScene),
                  if (others.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ClSpace.s4,
                        ClSpace.s4,
                        ClSpace.s4,
                        ClSpace.s3,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n.ksVideoOtherPhotos,
                          style: cl.text.label.copyWith(
                            color: cl.colors.inkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    grid(others),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: ClSpace.s6)),
                ],
              ),
            ),
            _BottomBar(
              left: l10n.ksVideoPicked(count),
              right: needMore > 0
                  ? l10n.ksVideoNeedMore(needMore)
                  : l10n.ksVideoCanAdd(t.photosMax - count),
              warn: needMore > 0,
              button: ClButton(
                label: l10n.actionContinue,
                expand: true,
                onPressed: needMore > 0
                    ? null
                    : () => context.push(
                        Routes.memoryStoryFinish,
                        extra: _d.copyWith(mediaIds: picked),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on KeepsakeTemplate {
  /// The same template with no age window (every photo is a candidate).
  KeepsakeTemplate copyWithoutAge() => KeepsakeTemplate(
    id: id,
    version: version,
    kind: kind,
    name: name,
    tier: tier,
    order: order,
    palette: palette,
    photosMin: photosMin,
    photosMax: photosMax,
  );
}

/// MM06: every scene with its photo or what it wants; the chosen one is outlined.
class _SceneStrip extends StatefulWidget {
  const _SceneStrip({
    required this.template,
    required this.slots,
    required this.active,
    required this.enough,
    required this.onSelect,
    required this.onClear,
  });
  final KeepsakeTemplate template;
  final List<MediaItem?> slots;
  final int active;
  final bool enough;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClear;

  @override
  State<_SceneStrip> createState() => _SceneStripState();
}

class _SceneStripState extends State<_SceneStrip> {
  static const _w = 84.0;
  static const _gap = 8.0;
  final _scroll = ScrollController();

  /// Keeps the chosen scene in view (centred when it can be).
  void _reveal({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      final x = (widget.active * (_w + _gap) - (p.viewportDimension - _w) / 2)
          .clamp(0.0, p.maxScrollExtent);
      if (animate) {
        unawaited(
          _scroll.animateTo(
            x,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        );
      } else {
        _scroll.jumpTo(x);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _reveal(animate: false);
  }

  @override
  void didUpdateWidget(_SceneStrip old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _reveal();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final t = widget.template;
    final filled = widget.slots.where((m) => m != null).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s3, ClSpace.s3, 0, ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: ClSpace.s3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ksVideoScenesFilled(filled, widget.slots.length),
                    style: cl.text.bodyStrong,
                  ),
                ),
                Text(
                  l10n.ksVideoMinimum(t.photosMin),
                  style: cl.text.caption.copyWith(
                    color: widget.enough ? cl.colors.inkMuted : cl.colors.peach,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          SizedBox(
            height: _w * 4 / 3 + 58,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: ClSpace.s3),
              itemCount: widget.slots.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final scene = i < t.scenes.length ? t.scenes[i] : null;
                return _SceneCard(
                  n: i + 1,
                  width: _w,
                  hint: scene?.hint.of(locale),
                  optional: scene?.optional ?? false,
                  photo: widget.slots[i],
                  active: i == widget.active,
                  onTap: () => widget.onSelect(i),
                  onClear: () => widget.onClear(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.n,
    required this.width,
    required this.hint,
    required this.optional,
    required this.photo,
    required this.active,
    required this.onTap,
    required this.onClear,
  });
  final int n;
  final double width;
  final String? hint;
  final bool optional;
  final MediaItem? photo;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final m = photo;
    return SizedBox(
      width: width,
      child: ClPressable(
        onPressed: onTap,
        selected: active,
        minSize: Size.zero,
        semanticLabel: l10n.ksVideoScene(n, hint ?? ''),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width,
              height: width * 4 / 3,
              decoration: BoxDecoration(
                color: active ? cl.colors.mintSoft : cl.colors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? cl.colors.mint : cl.colors.controlBorder,
                  width: active ? 2.5 : 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (m?.thumbPath != null)
                      Image(
                        image: StorageImage(m!.thumbPath!),
                        fit: BoxFit.cover,
                      )
                    else
                      Center(
                        child: ClIcon(
                          ClIcons.plus,
                          size: 18,
                          color: active
                              ? cl.colors.mintText
                              : cl.colors.inkMuted,
                        ),
                      ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: _OrderBadge(n, size: 18),
                    ),
                    if (m != null)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: ClPressable(
                          onPressed: onClear,
                          minSize: const Size(28, 28),
                          semanticLabel: l10n.ksVideoClearScene(n),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0x99000000),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const ClIcon(
                              ClIcons.close,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint ?? l10n.ksVideoSceneN(n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                color: active ? cl.colors.ink : cl.colors.inkMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
            if (optional)
              Text(
                l10n.ksVideoSceneOptionalTag,
                style: cl.text.caption.copyWith(
                  color: cl.colors.inkMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge(this.n, {this.size = 20});
  final int n;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: cl.colors.mint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: size * 0.58,
          fontWeight: FontWeight.w700,
          color: cl.colors.onMintDeep,
        ),
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.item,
    required this.order,
    required this.onTap,
  });
  final MediaItem item;
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final on = order > 0;
    return ClPressable(
      onPressed: onTap,
      selected: on,
      semanticLabel: AppLocalizations.of(context).ksToolPhoto,
      minSize: Size.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: on ? cl.colors.mint : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: cl.colors.surface2),
              if (item.thumbPath != null)
                Image(image: StorageImage(item.thumbPath!), fit: BoxFit.cover),
              Positioned(
                right: 5,
                top: 5,
                child: on
                    ? _OrderBadge(order)
                    : Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black26,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MM13: not enough suitable photos — from the phone, a shorter template.
class _NotEnough extends StatelessWidget {
  const _NotEnough({
    required this.name,
    required this.have,
    required this.need,
    required this.shorter,
    required this.onDevice,
    required this.onShorter,
  });
  final String name;
  final int have;
  final int need;
  final KeepsakeTemplate? shorter;
  final VoidCallback onDevice;
  final ValueChanged<KeepsakeTemplate> onShorter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.sunshineSoft,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClIcon(ClIcons.alert, size: 18, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.ksVideoNotEnough(name, have, need),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            ClListRow(
              title: l10n.ksVideoMoreFromDevice,
              subtitle: l10n.ksVideoMoreFromDeviceHint,
              onTap: onDevice,
            ),
            if (shorter != null)
              ClListRow(
                title: l10n.ksVideoShorter,
                subtitle: l10n.ksVideoShorterHint(
                  shorter!.name.of(locale),
                  shorter!.photosMin,
                ),
                onTap: () => onShorter(shorter!),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.button,
    this.left,
    this.right,
    this.warn = false,
    this.note,
  });
  final Widget button;
  final String? left;
  final String? right;
  final bool warn;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        MediaQuery.paddingOf(context).bottom + ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (left != null || right != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s2),
              child: Row(
                children: [
                  if (left != null) Text(left!, style: cl.text.bodyStrong),
                  const Spacer(),
                  if (right != null)
                    Text(
                      right!,
                      style: cl.text.label.copyWith(
                        color: warn ? cl.colors.peach : cl.colors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          button,
          if (note != null) ...[
            const SizedBox(height: ClSpace.s2),
            Text(
              note!,
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// MM07 · hoàn thiện video

class MemoryStoryFinishScreen extends ConsumerStatefulWidget {
  const MemoryStoryFinishScreen({required this.draft, super.key});
  final VideoDraft draft;

  @override
  ConsumerState<MemoryStoryFinishScreen> createState() => _FinishState();
}

class _FinishState extends ConsumerState<MemoryStoryFinishScreen> {
  late VideoDraft _d = widget.draft;
  late final List<String> _order = [...widget.draft.mediaIds];
  TextEditingController? _title;
  TextEditingController? _message;

  /// Chapter 01 texts the template offers (E-9), in this order; each follows its default until
  /// the parent edits it.
  static const _extraKeys = ['headline', 'lines', 'letter', 'closing'];
  final _extra = <String, TextEditingController>{};
  final _extraEdited = <String>{};

  Map<String, String> get _extraTexts => {
    for (final e in _extra.entries) e.key: e.value.text.trim(),
  };

  /// Until the parent edits them, the texts follow the defaults (the name may load after).
  var _titleEdited = false;
  var _messageEdited = false;
  var _busy = false;

  /// MM07 "Nhạc nền": null until the parent picks (the template's default then plays);
  /// `(id: null)` is "Không dùng nhạc".
  ({String? id})? _music;

  KeepsakeMusic? _track(KeepsakeCatalog? catalog) =>
      catalog?.track(_music == null ? _d.template.defaultMusic : _music!.id);

  @override
  void dispose() {
    _title?.dispose();
    _message?.dispose();
    for (final c in _extra.values) {
      c.dispose();
    }
    super.dispose();
  }

  var _previewing = false;

  Future<void> _preview(
    MemoryCtx c,
    Map<String, MediaItem> byId,
    DateTime day,
    String? mark,
  ) async {
    setState(() => _previewing = true);
    try {
      final track = _track(ref.read(keepsakeCatalogProvider).value);
      final request = await personalPreview(
        _d.template,
        photoPaths: [for (final id in _order) ?byId[id]?.thumbPath],
        title: _title!.text.trim(),
        message: _message!.text.trim(),
        extra: _extraTexts,
        locale: Localizations.localeOf(context).languageCode,
        labels: [
          for (final id in _order)
            c.dob == null || byId[id] == null
                ? null
                : keepsakeVideoLabel(
                    AppLocalizations.of(context),
                    c.dob!,
                    byId[id]!.captureAt,
                  ),
        ],
        name: c.nickname,
        dateLine: _day.format(day),
        mark: mark,
        music: _music != null && _music!.id == null
            ? null
            : keepsakeMusicAsset(_d.template, track),
      );
      if (!mounted) return;
      await ref.read(keepsakePreviewLauncherProvider)(context, request);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _pickAudience() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<Audience>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.ksVideoWho),
          ClCardGroup(
            children: [
              for (final a in Audience.values)
                ClOptionRow(
                  title: a == Audience.parents
                      ? l10n.ksAudienceParents
                      : l10n.ksAudienceFamily,
                  selected: a == _d.audience,
                  onTap: () => Navigator.of(sheet).pop(a),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ],
      ),
    );
    if (picked != null) setState(() => _d = _d.copyWith(audience: picked));
  }

  Future<void> _pickMusic(List<KeepsakeMusic> tracks, String? current) async {
    final picked = await showClSheet<({String? id})>(
      context: context,
      builder: (sheet) => KeepsakeMusicSheet(
        tracks: tracks,
        selected: current,
        defaultId: _d.template.defaultMusic,
        onPick: (id) => Navigator.of(sheet).pop((id: id)),
      ),
    );
    if (picked != null) setState(() => _music = picked);
  }

  Future<void> _create(MemoryCtx c) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final requestId = _d.requestId ?? newKeepsakeRequestId();
    setState(() {
      _busy = true;
      _d = _d.copyWith(requestId: requestId);
    });
    try {
      final jobId = await ref
          .read(keepsakeJobRepositoryProvider)
          .request(
            requestId: requestId,
            babyId: c.babyId,
            template: _d.template,
            mediaIds: _order,
            title: _title!.text.trim(),
            message: _message!.text.trim(),
            extra: _extraTexts,
            locale: Localizations.localeOf(context).languageCode,
            audience: _d.audience,
            occasion: _d.occasion,
            music: _music,
          );
      if (!mounted) return;
      // On iPhone it also shows on the lock screen and in the Dynamic Island until it is done.
      unawaited(
        ref
            .read(keepsakeLiveProvider)
            .start(
              babyId: c.babyId,
              jobId: jobId,
              templateName: _d.template.name.of(
                Localizations.localeOf(context),
              ),
              l10n: l10n,
            ),
      );
      unawaited(
        context.push('${Routes.memoryStoryJob}/$jobId?baby=${c.babyId}'),
      );
      // A new press after coming back is a new video.
      setState(
        () => _d = VideoDraft(
          babyId: _d.babyId,
          template: _d.template,
          occasion: _d.occasion,
          mediaIds: _order,
          audience: _d.audience,
        ),
      );
    } on KeepsakeJobException catch (e) {
      toaster.show(message: _reasonText(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context);
    final t = _d.template;
    final defaultTitle =
        _d.title ??
        _fill(t.text('title')?.defaultText.of(locale) ?? '', c.nickname);
    final defaultMessage =
        _d.message ??
        _fill(t.text('message')?.defaultText.of(locale) ?? '', c.nickname);
    _title ??= TextEditingController(text: defaultTitle);
    _message ??= TextEditingController(text: defaultMessage);
    if (!_titleEdited && _title!.text != defaultTitle) {
      _title!.text = defaultTitle;
    }
    if (!_messageEdited && _message!.text != defaultMessage) {
      _message!.text = defaultMessage;
    }
    for (final key in _extraKeys) {
      final own = t.text(key);
      if (own == null) continue;
      final value = _fill(own.defaultText.of(locale), c.nickname);
      final ctrl = _extra.putIfAbsent(
        key,
        () => TextEditingController(text: value),
      );
      if (!_extraEdited.contains(key) && ctrl.text != value) ctrl.text = value;
    }
    final media = ref.watch(mediaProvider((c.babyId, true))).value ?? const [];
    final byId = {for (final m in media) m.id: m};
    final day = videoDay(c, _d.occasion, media);
    final dob = c.dob;
    final age = _d.occasion?.byAge == true
        ? _d.occasion!.title(l10n)
        : (dob == null ? '' : ageLong(l10n, dob, day));
    final mark = _d.occasion?.byAge == true
        ? _d.occasion!.title(l10n).split(' ').first
        : null;
    final catalog = ref.watch(keepsakeCatalogProvider).value;
    final tracks = catalog?.music ?? const <KeepsakeMusic>[];
    final track = _track(catalog);
    final noMusic = _music != null && _music!.id == null;

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                children: [
                  Row(
                    children: [
                      ClBackButton(
                        semanticLabel: l10n.a11yBack,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      // "Xem trước" before "Tạo video": the same composition, played on the phone.
                      ClPressable(
                        onPressed: _previewing
                            ? null
                            : () => _preview(c, byId, day, mark),
                        semanticLabel: l10n.ksPreview,
                        child: Text(
                          l10n.ksPreview,
                          style: cl.text.label.copyWith(
                            color: cl.colors.mintText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Text(l10n.ksVideoFinishTitle, style: cl.text.largeTitle),
                  const SizedBox(height: ClSpace.s4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VideoCover(
                        width: 78,
                        title: _title!.text,
                        photoPath: _order.isEmpty
                            ? null
                            : byId[_order.first]?.displayPath,
                        mark: mark,
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cl.colors.mintSoft,
                                borderRadius: BorderRadius.circular(
                                  ClRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClIcon(
                                    ClIcons.check,
                                    size: 12,
                                    color: cl.colors.mintText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.ksVideoPrefilled,
                                    style: cl.text.caption.copyWith(
                                      color: cl.colors.mintText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: ClSpace.s2),
                            _Fact(
                              label: l10n.ksVideoBaby,
                              value: '${c.nickname} · $age',
                            ),
                            _Fact(
                              label: l10n.ksVideoDay,
                              value: _day.format(day),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s4),
                  // The template's texts, 12 apart (title and message for the first set).
                  for (final (i, field) in [
                    if (t.text('title') != null || t.texts.isEmpty)
                      ClTextField(
                        label: l10n.ksVideoFieldTitle,
                        controller: _title,
                        maxLength: t.text('title')?.max ?? 60,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() => _titleEdited = true),
                      ),
                    if (t.text('message') != null || t.texts.isEmpty)
                      ClTextField(
                        label: l10n.ksVideoFieldMessage,
                        controller: _message,
                        maxLength: t.text('message')?.max ?? 140,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => _messageEdited = true,
                      ),
                    for (final key in _extraKeys)
                      if (_extra[key] case final ctrl?)
                        ClTextField(
                          label: switch (key) {
                            'headline' => l10n.ksVideoFieldHeadline,
                            'lines' => l10n.ksVideoFieldLines,
                            'letter' => l10n.ksVideoFieldLetter,
                            _ => l10n.ksVideoFieldClosing,
                          },
                          controller: ctrl,
                          maxLength: t.text(key)?.max ?? 140,
                          maxLines: key == 'letter' || key == 'lines' ? 6 : 2,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => _extraEdited.add(key),
                        ),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(height: ClSpace.s3),
                    field,
                  ],
                  const SizedBox(height: ClSpace.s4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.ksVideoOrder(_order.length),
                          style: cl.text.label.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ),
                      Text(
                        l10n.ksVideoReorderHint,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s2),
                  SizedBox(
                    height: 54,
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      onReorderItem: (from, to) => setState(() {
                        _order.insert(to, _order.removeAt(from));
                      }),
                      footer: ClPressable(
                        onPressed: () => Navigator.of(context).maybePop(),
                        semanticLabel: l10n.ksVideoAddPhotos,
                        child: Container(
                          width: 46,
                          height: 54,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: cl.colors.surface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: ClIcon(
                              ClIcons.plus,
                              size: 16,
                              color: cl.colors.ink,
                            ),
                          ),
                        ),
                      ),
                      children: [
                        for (final (i, id) in _order.indexed)
                          ReorderableDelayedDragStartListener(
                            key: ValueKey(id),
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 46,
                                  height: 54,
                                  child: byId[id]?.thumbPath == null
                                      ? ColoredBox(color: cl.colors.surface2)
                                      : Image(
                                          image: StorageImage(
                                            byId[id]!.thumbPath!,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  ClCardGroup(
                    children: [
                      ClListRow(
                        leading: ClIcon(
                          ClIcons.clock,
                          size: 18,
                          color: context.cl.colors.ink,
                        ),
                        title: l10n.ksVideoMusic,
                        subtitle: noMusic
                            ? l10n.ksMusicNone
                            : track != null
                            ? track.title.of(locale)
                            : t.musicAsset != null
                            ? l10n.ksVideoMusicTemplate
                            : l10n.ksVideoMusicNone,
                        onTap: tracks.isEmpty
                            ? null
                            : () => _pickMusic(
                                tracks,
                                noMusic ? null : track?.id,
                              ),
                      ),
                      ClListRow(
                        leading: ClIcon(
                          ClIcons.lock,
                          size: 18,
                          color: context.cl.colors.ink,
                        ),
                        title: l10n.ksVideoWho,
                        subtitle: _d.audience == Audience.parents
                            ? l10n.ksVideoWhoParents
                            : l10n.ksVideoWhoFamily,
                        onTap: _pickAudience,
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s6),
                ],
              ),
            ),
            _BottomBar(
              note: l10n.ksVideoTakes,
              button: ClButton(
                label: l10n.ksVideoCreate,
                expand: true,
                loading: _busy,
                onPressed: _busy ? null : () => _create(c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          Expanded(child: Text(value, style: cl.text.bodyStrong)),
        ],
      ),
    );
  }
}

String _reasonText(AppLocalizations l10n, String reason) => switch (reason) {
  'busy' => l10n.ksVideoErrBusy,
  'daily-limit' => l10n.ksVideoErrDaily,
  'quota-full' => l10n.ksVideoErrQuota,
  'photo-unavailable' => l10n.ksVideoErrPhoto,
  'template-unavailable' => l10n.ksVideoErrTemplate,
  'not-enabled' => l10n.ksUnavailableTitle,
  _ => l10n.toastActionFailed,
};

// ---------------------------------------------------------------------------------------------
// MM08 · đang tạo, MM09 · đã sẵn sàng, MM14 · chưa thành công

class MemoryStoryJobScreen extends ConsumerStatefulWidget {
  const MemoryStoryJobScreen({
    required this.babyId,
    required this.jobId,
    super.key,
  });
  final String babyId;
  final String jobId;

  @override
  ConsumerState<MemoryStoryJobScreen> createState() => _JobState();
}

class _JobState extends ConsumerState<MemoryStoryJobScreen> {
  var _busy = false;

  void _close() => context.go(Routes.memories);

  /// MM14 "Xoá bản nháp", after a confirm; back to Kỷ niệm.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.ksVideoDeleteDraftTitle),
          Text(
            l10n.ksVideoDeleteDraftBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.ksVideoDeleteDraft,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await withClProgress(
        context,
        () => ref
            .read(keepsakeJobRepositoryProvider)
            .delete(widget.babyId, widget.jobId),
      );
      if (!mounted) return;
      _close();
      toaster.show(message: l10n.ksVideoDraftDeleted);
    } on Object {
      if (mounted) setState(() => _busy = false);
      toaster.show(message: l10n.toastActionFailed, error: true);
    }
  }

  Future<void> _retry() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(keepsakeJobRepositoryProvider)
          .retry(widget.babyId, widget.jobId);
    } on KeepsakeJobException catch (e) {
      toaster.show(message: _reasonText(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(MediaItem video) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      final file = await mediaBytes.file(video.paths!.original!);
      if (!mounted) return;
      await saveToLibrary(context, file, video: true);
      toaster.show(message: l10n.ksSavedToDevice);
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(MediaItem video) async {
    final file = await mediaBytes.file(video.paths!.original!);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'video/mp4')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    // The iPhone Live Activity follows the job while this screen is open.
    ref.listen(keepsakeJobProvider((widget.babyId, widget.jobId)), (_, next) {
      final j = next.value;
      if (j != null) unawaited(ref.read(keepsakeLiveProvider).update(j));
    });
    final job = ref
        .watch(keepsakeJobProvider((widget.babyId, widget.jobId)))
        .value;
    // A finished video seen here is no longer announced by Kỷ niệm's banner (MM17).
    if (job?.status == KeepsakeJobStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(markKeepsakeVideoSeen(ref, job!.id));
      });
    }
    if (c == null || job == null) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final media =
        ref.watch(mediaProvider((widget.babyId, true))).value ?? const [];
    final byId = {for (final m in media) m.id: m};
    final cover = job.mediaIds.isEmpty
        ? null
        : byId[job.mediaIds.first]?.displayPath;
    final video = job.outputMediaId == null ? null : byId[job.outputMediaId];

    Widget body;
    switch (job.status) {
      case KeepsakeJobStatus.queued:
      case KeepsakeJobStatus.rendering:
        final steps = ['arrange', 'compose', 'export'];
        final at = math.max(0, steps.indexOf(job.step ?? 'arrange'));
        body = Column(
          children: [
            VideoCover(
              width: 190,
              title: job.title,
              photoPath: cover,
              mark: job.mark,
              dim: true,
              overlay: Center(child: _Ring(progress: job.progress / 100)),
            ),
            const SizedBox(height: ClSpace.s6),
            Text(
              l10n.ksVideoMaking(c.nickname),
              textAlign: TextAlign.center,
              style: cl.text.title,
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.ksVideoMakingBody,
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.control + 4),
              ),
              child: Column(
                children: [
                  for (final (i, s) in steps.indexed)
                    _StepLine(
                      text: switch (s) {
                        'arrange' => l10n.ksVideoStepArrange(
                          job.mediaIds.length,
                        ),
                        'compose' => l10n.ksVideoStepCompose,
                        _ => l10n.ksVideoStepExport,
                      },
                      done: i < at,
                      current: i == at,
                    ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.ksVideoBackToMemories,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: _close,
            ),
          ],
        );
      case KeepsakeJobStatus.completed:
        final week = c.dob == null || video == null
            ? null
            : ageWeekOf(c.dob!, video.captureAt);
        body = Column(
          children: [
            ClPressable(
              onPressed: video == null
                  ? null
                  : () => openViewer(context, items: [video], start: 0),
              semanticLabel: l10n.ksVideoWatch,
              child: VideoCover(
                width: 205,
                title: job.title,
                photoPath: video?.displayPath ?? cover,
                mark: job.mark,
                duration: _mmss(job.durationMs),
                overlay: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: PlayGlyph(size: 20, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s6),
            Text(l10n.ksVideoReady, style: cl.text.title),
            const SizedBox(height: ClSpace.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(ClIcons.check, size: 12, color: cl.colors.mintText),
                  const SizedBox(width: 6),
                  Text(
                    video == null
                        ? l10n.ksVideoFiling
                        : [
                            l10n.ksVideoSaved,
                            if (week != null && week > 0)
                              l10n.ksVideoWeek(week),
                            job.audience == Audience.parents
                                ? l10n.ksAudienceParents
                                : l10n.ksAudienceFamily,
                          ].join(' · '),
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s4),
            Row(
              children: [
                Expanded(
                  child: KeepsakeActionTile(
                    icon: ClIcons.download,
                    label: l10n.ksSaveDevice,
                    onTap: video == null || _busy ? null : () => _save(video),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: KeepsakeActionTile(
                    icon: ClIcons.link,
                    label: l10n.ksShare,
                    onTap: video == null ? null : () => _share(video),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: KeepsakeActionTile(
                    icon: ClIcons.memories,
                    label: l10n.ksVideoOpen,
                    onTap: video == null
                        ? null
                        : () => openViewer(context, items: [video], start: 0),
                  ),
                ),
              ],
            ),
            if (job.occasion != null &&
                ref.watch(selectedKeepsakeAccessProvider).cards) ...[
              const SizedBox(height: ClSpace.s3),
              ClCardGroup(
                children: [
                  ClListRow(
                    leading: ClIcon(
                      ClIcons.star,
                      size: 18,
                      color: context.cl.colors.ink,
                    ),
                    title: l10n.ksVideoAlsoCard(job.occasion!.label(l10n)),
                    subtitle: l10n.ksVideoAlsoCardHint,
                    onTap: () => context.push(
                      '${Routes.milestoneCard}?occasion=${job.occasion!.wire}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      case KeepsakeJobStatus.failed:
        body = Column(
          children: [
            VideoCover(
              width: 170,
              title: job.title,
              photoPath: cover,
              mark: job.mark,
              dim: true,
              overlay: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cl.colors.error.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ClIcon(
                      ClIcons.alert,
                      size: 24,
                      color: cl.colors.error,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s6),
            Text(l10n.ksVideoFailed, style: cl.text.title),
            const SizedBox(height: ClSpace.s2),
            Text(
              switch (job.error) {
                'photo-missing' => l10n.ksVideoFailedPhoto,
                'timeout' || 'unavailable' => l10n.ksVideoFailedBusy,
                _ => l10n.ksVideoFailedNetwork,
              },
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.actionRetry,
              expand: true,
              loading: _busy,
              onPressed: _busy || job.error == 'photo-missing' ? null : _retry,
            ),
            const SizedBox(height: ClSpace.s2),
            ClButton(
              label: l10n.ksVideoEditChoices,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.push(
                    job.occasion == null
                        ? Routes.memoryStory
                        : '${Routes.memoryStory}?occasion=${job.occasion!.wire}',
                  );
                }
              },
            ),
            ClButton(
              label: l10n.ksVideoDeleteDraft,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: _busy ? null : _delete,
            ),
            Text(
              l10n.ksVideoDraftNote,
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        );
    }

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          children: [
            Row(
              children: [
                KeepsakeRoundIcon(
                  icon: ClIcons.close,
                  label: l10n.a11yClose,
                  onTap: _close,
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
            body,
            const SizedBox(height: ClSpace.s6),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.02, 1),
              strokeWidth: 9,
              backgroundColor: Colors.white24,
              color: cl.colors.mint,
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.text,
    required this.done,
    required this.current,
  });
  final String text;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done ? cl.colors.mint : Colors.transparent,
              shape: BoxShape.circle,
              border: done
                  ? null
                  : Border.all(color: cl.colors.mint, width: 1.6),
            ),
            child: Center(
              child: ClIcon(
                done ? ClIcons.check : ClIcons.clock,
                size: 12,
                color: done ? cl.colors.onMintDeep : cl.colors.mint,
              ),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              text,
              style: (current ? cl.text.bodyStrong : cl.text.body).copyWith(
                color: current || done ? cl.colors.ink : cl.colors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays a few seconds of a Thư viện nhạc track in the MM07 sheet; tests replace it.
abstract class TrackSampler {
  Future<void> play(String url);
  Future<void> stop();
  void dispose();
}

class _AudioTrackSampler implements TrackSampler {
  AudioPlayer? _player;

  @override
  Future<void> play(String url) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(UrlSource(url));
    } on Object {
      // No audio (offline, simulator): the list still works.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } on Object {
      // Nothing playing.
    }
  }

  @override
  void dispose() => unawaited(_player?.dispose());
}

final trackSamplerProvider = Provider<TrackSampler Function()>(
  (_) => _AudioTrackSampler.new,
);

/// MM07 "Nhạc nền": the licensed tracks from the portal, each with a "Nghe thử", plus
/// "Không dùng nhạc" (owner, 2026-10-14).
class KeepsakeMusicSheet extends ConsumerStatefulWidget {
  const KeepsakeMusicSheet({
    required this.tracks,
    required this.selected,
    required this.defaultId,
    required this.onPick,
    super.key,
  });
  final List<KeepsakeMusic> tracks;

  /// Null: "Không dùng nhạc".
  final String? selected;
  final String? defaultId;
  final ValueChanged<String?> onPick;

  @override
  ConsumerState<KeepsakeMusicSheet> createState() => _MusicSheetState();
}

class _MusicSheetState extends ConsumerState<KeepsakeMusicSheet> {
  TrackSampler? _sampler;
  String? _playing;

  @override
  void dispose() {
    if (_sampler case final sampler?) {
      unawaited(sampler.stop());
      sampler.dispose();
    }
    super.dispose();
  }

  void _toggle(KeepsakeMusic m) {
    final sampler = _sampler ??= ref.read(trackSamplerProvider)();
    if (_playing == m.id) {
      unawaited(sampler.stop());
      setState(() => _playing = null);
    } else {
      unawaited(sampler.play(keepsakeAssetUrl(m.asset)));
      setState(() => _playing = m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.ksVideoMusic),
        Flexible(
          child: SingleChildScrollView(
            child: ClCardGroup(
              children: [
                for (final m in widget.tracks)
                  Row(
                    children: [
                      const SizedBox(width: ClSpace.s4),
                      ClPressable(
                        onPressed: () => _toggle(m),
                        semanticLabel: _playing == m.id
                            ? l10n.ksMusicStop
                            : l10n.ksMusicListen(m.title.of(locale)),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cl.colors.mintSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _playing == m.id
                                ? ClIcon(
                                    ClIcons.stop,
                                    size: 16,
                                    color: cl.colors.mintText,
                                  )
                                : PlayGlyph(
                                    size: 12,
                                    color: cl.colors.mintText,
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClOptionRow(
                          title: m.title.of(locale),
                          subtitle: [
                            if (m.artist.isNotEmpty) m.artist,
                            if (m.durationSec > 0) _mmss(m.durationSec * 1000),
                            if (m.id == widget.defaultId) l10n.ksMusicDefault,
                          ].join(' · '),
                          selected: m.id == widget.selected,
                          onTap: () => widget.onPick(m.id),
                        ),
                      ),
                    ],
                  ),
                ClOptionRow(
                  title: l10n.ksMusicNone,
                  selected: widget.selected == null,
                  onTap: () => widget.onPick(null),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(ClSpace.s4),
          child: Text(
            l10n.ksMusicNote,
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    );
  }
}
