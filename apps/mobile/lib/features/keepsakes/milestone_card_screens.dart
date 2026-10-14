import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../l10n/app_localizations.dart';
import '../auto_save/library_save.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart' show growthRecordsProvider;
import '../memories/media_bytes.dart';
import '../memories/media_picker.dart';
import '../memories/memories_screen.dart' show MemoryCtx, memoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_sheets.dart' show presetName;
import '../memories/upload_queue.dart';
import '../premium/premium_gate.dart';
import 'keepsake_access.dart';
import 'keepsake_card_content.dart';
import 'keepsake_card_view.dart';
import 'keepsake_catalog.dart';
import 'keepsake_occasions.dart';
import 'memory_story_screens.dart' show MemoryStoryTemplatesScreen;

/// Thiệp cột mốc (D-068; Figma MM10 `530:9515` chọn mẫu, MM11 `530:9663` chỉnh sửa, MM12
/// `531:9375` thiệp đã sẵn sàng). The card is drawn on the phone from the template's layers
/// (artwork from the portal, D-068 #7), exported at 2160 px wide, saved to Kỷ niệm through the
/// usual upload (Chỉ ba mẹ, no family notice, counted in the quota: D-068 #5) and shared or saved
/// to the phone as PNG or JPG.

/// Where the flow stands between MM10 and MM12.
@immutable
class CardDraft {
  const CardDraft({
    required this.babyId,
    required this.occasion,
    required this.date,
    required this.format,
    required this.template,
    required this.palette,
    required this.quote,
    this.photos = const [],
    this.slot = 0,
  });

  final String babyId;
  final Occasion occasion;

  /// The occasion's day: the card shows it, the memory is dated on it (today if still ahead).
  final DateTime date;
  final KeepsakeFormat format;
  final KeepsakeTemplate template;
  final KeepsakePalette palette;
  final String quote;

  /// One per photo slot of the template (index = slot); each keeps its own position and zoom,
  /// so a two-photo template (Then & Now) is cropped photo by photo.
  final List<CardPhoto?> photos;

  /// The slot "Ảnh" fills next: the one last tapped on the card.
  final int slot;

  CardPhoto? photoAt(int i) => i < photos.length ? photos[i] : null;

  /// Every slot the template requires (below its minimum) has a photo in this format.
  bool get ready => [
    for (final s in template.photoSlots(format))
      if (s < template.photosMin) s,
  ].every((s) => photoAt(s) != null);

  CardDraft copyWith({
    KeepsakeTemplate? template,
    KeepsakeFormat? format,
    KeepsakePalette? palette,
    String? quote,
    List<CardPhoto?>? photos,
    int? slot,
  }) => CardDraft(
    babyId: babyId,
    occasion: occasion,
    date: date,
    format: format ?? this.format,
    template: template ?? this.template,
    palette: palette ?? this.palette,
    quote: quote ?? this.quote,
    photos: photos ?? this.photos,
    slot: slot ?? this.slot,
  );

  /// [photo] in [slotIndex] (the active slot by default); the other slots stay as they are.
  CardDraft withPhoto(CardPhoto photo, [int? slotIndex]) {
    final i = slotIndex ?? slot;
    final next = [...photos];
    while (next.length <= i) {
      next.add(null);
    }
    next[i] = photo;
    return copyWith(photos: next);
  }
}

/// What MM12 shows and exports.
@immutable
class CardResult {
  const CardResult({required this.draft, required this.png, required this.jpg});
  final CardDraft draft;
  final File png;
  final File jpg;
}

/// The draft's texts (E-2): the template's own with the baby's name and age, the note, the
/// photo labels and the birth stats from the first growth record.
CardContent cardContent(
  AppLocalizations l10n,
  Locale locale,
  MemoryCtx c,
  CardDraft d,
  Iterable<CareRecord> growth,
) => keepsakeCardContent(
  l10n: l10n,
  locale: locale,
  template: d.template,
  occasion: d.occasion,
  name: c.nickname,
  dob: c.dob,
  date: d.date,
  note: d.quote,
  photos: d.photos,
  growth: growth,
);

/// The best photos for a card, best first (the baby's own photos, never a card or video Child Life
/// made): those tagged with the occasion's milestone, then
/// the ones taken closest to the occasion's day.
List<MediaItem> defaultPhotos(
  List<MediaItem> media,
  Occasion o,
  DateTime date, {
  int count = 1,
}) {
  final photos = [
    for (final m in media)
      if (m.isReady &&
          !m.deleted &&
          !m.isVideo &&
          m.generatedKind == null &&
          m.displayPath != null)
        m,
  ];
  int tagged(MediaItem m) => m.milestone?.id == o.milestoneId ? 0 : 1;
  photos.sort((a, b) {
    final t = tagged(a) - tagged(b);
    if (t != 0) return t;
    return a.captureAt
        .difference(date)
        .abs()
        .compareTo(b.captureAt.difference(date).abs());
  });
  return photos.take(count).toList();
}

/// The best photo for a card (the first of [defaultPhotos]).
MediaItem? defaultPhoto(List<MediaItem> media, Occasion o, DateTime date) =>
    defaultPhotos(media, o, date).firstOrNull;

/// The photo at full size for the export (the original rendition, ≤ 4096 px).
CardPhoto photoOf(MediaItem m) => CardPhoto(
  StorageImage(m.paths?.original ?? m.displayPath!),
  takenAt: m.captureAt,
);

// ---------------------------------------------------------------------------------------------
// MM10 · chọn mẫu

class MilestoneCardScreen extends ConsumerStatefulWidget {
  const MilestoneCardScreen({
    this.occasion,
    this.photoIds,
    this.embedded = false,
    super.key,
  });

  /// A page of [KeepsakeKindsScreen]: no back button or title of its own.
  final bool embedded;

  /// Preselected from MM03's "Tạo thiệp" or MM09's cross-sell.
  final Occasion? occasion;

  /// Photos chosen in Kỷ niệm (a selection's "Tạo thiệp cột mốc"); the card uses up to 4.
  final List<String>? photoIds;

  @override
  ConsumerState<MilestoneCardScreen> createState() =>
      _MilestoneCardScreenState();
}

class _MilestoneCardScreenState extends ConsumerState<MilestoneCardScreen> {
  Occasion? _occasion;
  var _format = KeepsakeFormat.portrait;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = memoryCtx(context, ref);
    final access = ref.watch(selectedKeepsakeAccessProvider);
    if (c == null || !c.isParent || !access.cards || c.dob == null) {
      return KeepsakePage(
        title: l10n.ksCardTitle,
        children: [
          ClEmptyState(
            icon: ClIcons.star,
            title: l10n.ksUnavailableTitle,
            message: l10n.ksUnavailableBody,
          ),
        ],
      );
    }
    final dob = c.dob!;
    final media = ref.watch(mediaProvider((c.babyId, true))).value ?? const [];
    // Photos chosen in Kỷ niệm come first, in the order chosen; the dịp is the one near them.
    final chosen = [
      for (final id in widget.photoIds ?? const <String>[])
        ?defaultPhotos(
          media.where((m) => m.id == id).toList(),
          Occasion.birth,
          c.now,
        ).firstOrNull,
    ].take(4).toList();
    final newest = chosen.isEmpty
        ? null
        : chosen.map((m) => m.captureAt).reduce((a, b) => a.isAfter(b) ? a : b);
    final suggested = suggestedOccasion(dob, newest ?? c.now);
    final occasion = _occasion ?? widget.occasion ?? suggested;
    final milestones = [for (final m in media) ?m.milestone];
    final date = occasion.dateFor(dob, milestones) ?? c.now;
    // Enough for the template with the most slots; each template uses as many as it has.
    final best = chosen.isNotEmpty
        ? chosen
        : defaultPhotos(media, occasion, date, count: 4);
    final catalog = ref.watch(keepsakeCatalogProvider);
    final cards = [
      for (final t in catalog.value?.cards ?? const <KeepsakeTemplate>[])
        if (t.layouts.containsKey(_format)) t,
    ];
    final previews = [
      for (final m in best)
        CardPhoto(StorageImage(m.displayPath!), takenAt: m.captureAt),
    ];
    final growth =
        ref.watch(growthRecordsProvider(c.babyId)).value ??
        const <CareRecord>[];

    return KeepsakePage(
      title: l10n.ksCardTitle,
      embedded: widget.embedded,
      children: [
        OccasionFilter(
          occasions: Occasion.chipsFor(
            dob,
            c.now,
            milestones,
            current: occasion,
          ),
          selected: occasion,
          suggested: suggested,
          onSelect: (o) => setState(() => _occasion = o),
        ),
        const SizedBox(height: ClSpace.s4),
        ClSegmented<KeepsakeFormat>(
          options: KeepsakeFormat.values,
          selected: _format,
          onChanged: (f) => setState(() => _format = f),
          labelOf: (f) => switch (f) {
            KeepsakeFormat.portrait => l10n.ksFormatPortrait,
            KeepsakeFormat.square => l10n.ksFormatSquare,
            KeepsakeFormat.story => l10n.ksFormatStory,
          },
        ),
        const SizedBox(height: ClSpace.s4),
        if (catalog.isLoading && !catalog.hasValue)
          const _GridSkeleton()
        else if (catalog.hasError && !catalog.hasValue)
          ClEmptyState(
            icon: ClIcons.alert,
            title: l10n.ksLoadFailed,
            message: l10n.toastActionFailed,
            actionLabel: l10n.actionRetry,
            onAction: () => ref.invalidate(keepsakeCatalogProvider),
          )
        else if (cards.isEmpty)
          ClEmptyState(
            icon: ClIcons.star,
            title: l10n.ksNoTemplates,
            message: l10n.ksNoTemplatesBody,
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - ClSpace.s3) / 2;
              return Wrap(
                spacing: ClSpace.s3,
                runSpacing: ClSpace.s3,
                children: [
                  for (final t in cards)
                    () {
                      final content = keepsakeCardContent(
                        l10n: l10n,
                        locale: Localizations.localeOf(context),
                        template: t,
                        occasion: occasion,
                        name: c.nickname,
                        dob: dob,
                        date: date,
                        note: occasion.quote(l10n),
                        photos: previews,
                        growth: growth,
                      );
                      return _TemplateTile(
                        template: t,
                        format: _format,
                        width: w,
                        badge: catalog.value!.badges,
                        content: content,
                        // The template first, larger and with what it needs; "Dùng mẫu
                        // này" there goes on to MM11 (owner, 2026-10-14).
                        onTap: () => context.push(
                          Routes.milestoneCardPreview,
                          extra: CardPreviewArgs(
                            draft: CardDraft(
                              babyId: c.babyId,
                              occasion: occasion,
                              date: date,
                              format: _format,
                              template: t,
                              palette: t.palette,
                              quote: occasion.quote(l10n),
                              photos: [
                                for (final m in best.take(t.photosMax))
                                  photoOf(m),
                              ],
                            ),
                            content: content,
                            badge: catalog.value!.badges,
                          ),
                        ),
                      );
                    }(),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// "Chọn dịp" and its chips in one sideways row, the same on Thiệp and Video (owner,
/// 2026-10-14: "đồng nhất filter"); the chosen chip is brought into view once it is there. With
/// [allLabel] (Video, where the dịp filters the templates) "Tất cả" comes first and stands for
/// null; Thiệp has none, its dịp only changes the words on every card.
class OccasionFilter extends StatefulWidget {
  const OccasionFilter({
    required this.occasions,
    required this.selected,
    required this.suggested,
    required this.onSelect,
    this.allLabel,
    super.key,
  });

  final List<Occasion> occasions;
  final Occasion? selected;
  final Occasion? suggested;
  final ValueChanged<Occasion?> onSelect;
  final String? allLabel;

  @override
  State<OccasionFilter> createState() => _OccasionFilterState();
}

class _OccasionFilterState extends State<OccasionFilter> {
  final _chosen = GlobalKey();
  final _row = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centreChosen());
  }

  @override
  void dispose() {
    _row.dispose();
    super.dispose();
  }

  /// Brings the chosen chip into the middle of the row, sideways only and only the first time:
  /// Scrollable.ensureVisible also scrolled the list around it, so the screen jumped whenever
  /// the row was rebuilt on the way back up (owner, 2026-10-14: "scroll gần lên đầu thì bị
  /// giật"). The row's own offset is kept (PageStorage) when it is rebuilt.
  void _centreChosen() {
    if (!mounted || !_row.hasClients) return;
    final storage = PageStorage.maybeOf(context);
    if (storage?.readState(context, identifier: _centred) == true) return;
    storage?.writeState(context, true, identifier: _centred);
    final chip = _chosen.currentContext?.findRenderObject() as RenderBox?;
    final row = _row.position.context.notificationContext?.findRenderObject();
    if (chip == null || row is! RenderBox) return;
    final x = chip.localToGlobal(Offset.zero, ancestor: row).dx + _row.offset;
    final target =
        x + chip.size.width / 2 - _row.position.viewportDimension / 2;
    _row.jumpTo(target.clamp(0.0, _row.position.maxScrollExtent));
  }

  String get _centred => 'occasionCentred.${widget.allLabel != null}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final all = widget.allLabel;
    final chips = [
      if (all != null)
        OccasionChip(
          key: widget.selected == null ? _chosen : null,
          label: all,
          selected: widget.selected == null,
          onTap: () => widget.onSelect(null),
        ),
      for (final o in widget.occasions)
        OccasionChip(
          key: o == widget.selected ? _chosen : null,
          label: o.label(l10n),
          icon: o.icon,
          selected: o == widget.selected,
          suggested: o == widget.suggested,
          onTap: () => widget.onSelect(o),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ksChooseOccasion,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          key: PageStorageKey('occasionRow.${all != null}'),
          controller: _row,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (i, chip) in chips.indexed) ...[
                if (i > 0) const SizedBox(width: ClSpace.s2),
                chip,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A dịp chip (Thiệp cột mốc, Video kỷ niệm); "Gợi ý" on the one the baby's age is near.
class OccasionChip extends StatelessWidget {
  const OccasionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.suggested = false,
    super.key,
  });
  final String label;
  final ClIcons? icon;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = selected ? cl.colors.onMintDeep : cl.colors.ink;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintDeep : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ClIcon(icon!, size: 14, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: cl.text.body.copyWith(
                fontWeight: FontWeight.w500,
                color: ink,
              ),
            ),
            if (suggested) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? cl.colors.onMintDeep.withValues(alpha: 0.18)
                      : cl.colors.mintSoft,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  AppLocalizations.of(context).ksSuggested,
                  style: cl.text.caption.copyWith(
                    color: selected ? ink : cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Miễn phí" / "★ Cao cấp" (MM10). Whether Cao cấp is open, hidden or (later) paid, and whether
/// the badge shows, is set in the portal (D-068 #8); during the beta both are free (D-068 #3).
class TierBadge extends StatelessWidget {
  const TierBadge({required this.premium, super.key});
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Fixed colours, as drawn: the badge sits on the card's own artwork in both themes.
    const ink = Color(0xFF1A1F26);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: premium ? const Color(0xFFFFD166) : const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) ...[
            const ClIcon(ClIcons.star, size: 10, color: ink),
            const SizedBox(width: 3),
          ],
          Text(
            premium ? l10n.ksPremium : l10n.ksFree,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// What a template's preview needs: the draft "Dùng mẫu này" goes on with, and the card as
/// drawn in the grid.
class CardPreviewArgs {
  const CardPreviewArgs({
    required this.draft,
    required this.content,
    this.badge = true,
  });
  final CardDraft draft;
  final CardContent content;

  /// The portal's "Hiện nhãn Miễn phí / Cao cấp" (D-068 #8).
  final bool badge;
}

/// A template before it is used (owner, 2026-10-14: "ấn vào item thì mở màn hình xem trước"):
/// the card large with the baby's details, its name and tier, what it needs and offers, and
/// "Dùng mẫu này" on to MM11. Not drawn in Figma.
class CardTemplatePreviewScreen extends ConsumerWidget {
  const CardTemplatePreviewScreen({required this.args, super.key});
  final CardPreviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = args.draft.template;
    final format = args.draft.format;
    return KeepsakePreviewPage(
      name: t.name.of(Localizations.localeOf(context)),
      premium: t.premium,
      badge: args.badge,
      preview: LayoutBuilder(
        builder: (context, box) {
          final width = math.min(box.maxWidth - ClSpace.s8, 300.0);
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: KeepsakeCardView(
                template: t,
                format: format,
                content: args.content,
                width: width,
              ),
            ),
          );
        },
      ),
      facts: [
        (
          l10n.ksInfoPhotos,
          keepsakePhotosLabel(l10n, t.photosMin, t.photosMax),
        ),
        (
          l10n.ksInfoFormat,
          [for (final f in t.formats) keepsakeFormatLabel(l10n, f)].join(' · '),
        ),
        (l10n.ksInfoOccasion, args.draft.occasion.label(l10n)),
        if (t.palettes.length > 1)
          (l10n.ksInfoPalettes, l10n.ksPalettesCount(t.palettes.length)),
      ],
      onUse: () async {
        // MO02 (Q1): a Cao cấp card in `subscribers` mode needs templates.premium.
        final ok = await ensureTemplateAllowed(
          context,
          ref,
          template: t,
          catalog: ref.read(keepsakeCatalogProvider).value,
          babyId: args.draft.babyId,
        );
        if (ok && context.mounted) {
          await context.push(Routes.milestoneCardEdit, extra: args.draft);
        }
      },
    );
  }
}

String keepsakeFormatLabel(AppLocalizations l10n, KeepsakeFormat f) =>
    switch (f) {
      KeepsakeFormat.portrait => l10n.ksFormatPortrait,
      KeepsakeFormat.square => l10n.ksFormatSquare,
      KeepsakeFormat.story => l10n.ksFormatStory,
    };

/// "4 ảnh" / "1–4 ảnh".
String keepsakePhotosLabel(AppLocalizations l10n, int min, int max) =>
    min == max ? l10n.ksPhotosCount(max) : l10n.ksPhotosRange(min, max);

/// The shared layout of the template previews: back, the picture, the name with its tier,
/// a card of facts, and "Dùng mẫu này" pinned at the bottom.
class KeepsakePreviewPage extends StatelessWidget {
  const KeepsakePreviewPage({
    required this.name,
    required this.premium,
    required this.preview,
    required this.facts,
    required this.onUse,
    this.badge = true,
    this.note,
    super.key,
  });

  final String name;
  final bool premium;
  final bool badge;
  final Widget preview;

  /// Label and value, one row each.
  final List<(String, String)> facts;
  final VoidCallback onUse;

  /// A line under the name (e.g. "Gợi ý cho tuổi của bé").
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClBackButton(
                  semanticLabel: l10n.a11yBack,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClSpace.s6,
                ),
                children: [
                  preview,
                  const SizedBox(height: ClSpace.s6),
                  Row(
                    children: [
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(name, style: cl.text.title2),
                        ),
                      ),
                      if (badge) ...[
                        const SizedBox(width: ClSpace.s2),
                        TierBadge(premium: premium),
                      ],
                    ],
                  ),
                  if (note != null) ...[
                    const SizedBox(height: ClSpace.s1),
                    Text(
                      note!,
                      style: cl.text.label.copyWith(color: cl.colors.mintText),
                    ),
                  ],
                  const SizedBox(height: ClSpace.s4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (final (i, (label, value)) in facts.indexed) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: ClSpace.s4,
                              color: cl.colors.separator,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ClSpace.s4,
                              vertical: ClSpace.s3,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: cl.text.body.copyWith(
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: ClSpace.s4),
                                Expanded(
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.end,
                                    style: cl.text.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                bottom > 0 ? bottom : ClSpace.s4,
              ),
              child: ClButton(
                label: l10n.ksUseTemplate,
                expand: true,
                onPressed: onUse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.format,
    required this.width,
    required this.badge,
    required this.content,
    required this.onTap,
  });
  final KeepsakeTemplate template;
  final KeepsakeFormat format;
  final double width;

  /// The portal's "Hiện nhãn Miễn phí / Cao cấp" (D-068 #8).
  final bool badge;
  final CardContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final name = template.name.of(Localizations.localeOf(context));
    return ClPressable(
      onPressed: onTap,
      semanticLabel: name,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  KeepsakeCardView(
                    template: template,
                    format: format,
                    content: content,
                    width: width,
                  ),
                  if (badge)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: TierBadge(premium: template.premium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: cl.text.caption.copyWith(
                color: cl.colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - ClSpace.s3) / 2;
      return Wrap(
        spacing: ClSpace.s3,
        runSpacing: ClSpace.s3,
        children: [
          for (var i = 0; i < 4; i++)
            ClSkeleton(width: w, height: w * 5 / 4, radius: 12),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------------------------
// MM11 · chỉnh sửa

enum _Tool { photo, layout, message, color }

class MilestoneCardEditScreen extends ConsumerStatefulWidget {
  const MilestoneCardEditScreen({required this.draft, super.key});
  final CardDraft draft;

  @override
  ConsumerState<MilestoneCardEditScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<MilestoneCardEditScreen> {
  final _boundary = GlobalKey();
  late CardDraft _d = widget.draft;
  late final _quote = TextEditingController(text: widget.draft.quote);
  var _tool = _Tool.layout;
  var _busy = false;

  @override
  void dispose() {
    _quote.dispose();
    super.dispose();
  }

  Future<void> _pickDevice() async {
    final picked = await pickFromLibrary(context, ref);
    final p = picked?.where((m) => m.type == MediaKind.photo).firstOrNull;
    if (p == null || !mounted) return;
    setState(() => _d = _d.withPhoto(CardPhoto(FileImage(p.file))));
  }

  Future<void> _save(MemoryCtx c) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      // Everything at full size before the picture is taken (fonts are bundled).
      final assetOf = ref.read(keepsakeAssetImageProvider);
      await Future.wait([
        for (final p in _d.photos)
          if (p != null) precacheImage(p.image, context),
        for (final a in _d.template.assets(_d.format))
          precacheImage(assetOf(a), context),
        precacheKeepsakeBrand(),
      ]);
      await WidgetsBinding.instance.endOfFrame;
      final result = await exportCard(_boundary, _d);
      await _upload(c, l10n, result);
      if (!mounted) return;
      context.pushReplacement(Routes.milestoneCardDone, extra: result);
    } on Object {
      toaster.show(message: l10n.ksSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload(MemoryCtx c, AppLocalizations l10n, CardResult r) {
    final preset = PresetMilestone.values
        .where((p) => p.id == r.draft.occasion.milestoneId)
        .firstOrNull;
    final req = cardMemoryRequest(
      draft: r.draft,
      today: c.now,
      milestoneName: preset == null
          ? r.draft.occasion.label(l10n)
          : presetName(l10n, preset),
    );
    final day = DateTime.parse(req['date']! as String);
    return ref
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: r.draft.babyId,
          request: req,
          picked: [
            PickedMedia(
              file: r.jpg,
              type: MediaKind.photo,
              name: r.jpg.uri.pathSegments.last,
              captureAt: DateTime(day.year, day.month, day.day, 12),
              width: KeepsakeFormat.exportWidth.round(),
              height: (KeepsakeFormat.exportWidth / r.draft.format.aspect)
                  .round(),
            ),
          ],
        );
  }

  void _preview(MemoryCtx c) {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialog) => GestureDetector(
          onTap: () => Navigator.of(dialog).pop(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = math.min(
                  box.maxWidth - 32,
                  (box.maxHeight - 64) * _d.format.aspect,
                );
                return KeepsakeCardView(
                  template: _d.template,
                  format: _d.format,
                  palette: _d.palette,
                  content: cardContent(
                    l10n,
                    Localizations.localeOf(context),
                    c,
                    _d,
                    _growth,
                  ),
                  width: w,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Growth records for C01's birth stats (kept for the full-screen preview's callback).
  Iterable<CareRecord> _growth = const [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    if (c != null) {
      _growth =
          ref.watch(growthRecordsProvider(c.babyId)).value ??
          const <CareRecord>[];
    }
    if (c == null) return const SizedBox.shrink();
    final catalog = ref.watch(keepsakeCatalogProvider).value;
    final layouts = [
      for (final t in catalog?.cards ?? [_d.template])
        if (t.layouts.containsKey(_d.format)) t,
    ];
    final palettes = _d.template.palettes.isEmpty
        ? [_d.template.palette]
        : _d.template.palettes;
    final tools = [
      _Tool.photo,
      _Tool.layout,
      if (_d.template.shows(_d.format, 'quote')) _Tool.message,
      if (palettes.length > 1) _Tool.color,
    ];
    final tool = tools.contains(_tool) ? _tool : _Tool.layout;

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Row(
                children: [
                  KeepsakeRoundIcon(
                    icon: ClIcons.close,
                    label: l10n.a11yClose,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  ClPressable(
                    onPressed: () => _preview(c),
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
            ),
            const SizedBox(height: ClSpace.s3),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = math.min(
                    box.maxWidth - 2 * ClSpace.s8 - 30,
                    box.maxHeight * _d.format.aspect,
                  );
                  return Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18 * w / 250),
                          child: RepaintBoundary(
                            key: _boundary,
                            child: KeepsakeCardView(
                              template: _d.template,
                              format: _d.format,
                              palette: _d.palette,
                              content: cardContent(
                                l10n,
                                Localizations.localeOf(context),
                                c,
                                _d,
                                _growth,
                              ),
                              width: w,
                              onPhotoTap: (slot) => setState(() {
                                _tool = _Tool.photo;
                                _d = _d.copyWith(slot: slot);
                              }),
                              onPhotoChanged: (slot, p) =>
                                  setState(() => _d = _d.withPhoto(p, slot)),
                              // Which slot "Ảnh" fills; on screen only (hidden while saving).
                              activeSlot:
                                  !_busy &&
                                      _d.template.photoSlots(_d.format).length >
                                          1
                                  ? _d.slot
                                  : null,
                              photoPlaceholder: Text(
                                l10n.ksChoosePhoto,
                                style: cl.text.caption.copyWith(
                                  color: _d.palette.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Outside the boundary: never part of the export.
                        if (_d.photoAt(0) != null &&
                            _d.template.photoSlots(_d.format).length == 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: w / _d.format.aspect * 0.42,
                            child: IgnorePointer(
                              child: Center(
                                child: KeepsakePhotoHint(l10n.ksPhotoHint),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Row(
                children: [
                  for (final (i, t) in tools.indexed) ...[
                    if (i > 0) const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: _ToolTile(
                        icon: switch (t) {
                          _Tool.photo => ClIcons.camera,
                          _Tool.layout => ClIcons.grid,
                          _Tool.message => ClIcons.edit,
                          _Tool.color => ClIcons.spark,
                        },
                        label: switch (t) {
                          _Tool.photo => l10n.ksToolPhoto,
                          _Tool.layout => l10n.ksToolLayout,
                          _Tool.message => l10n.ksToolMessage,
                          _Tool.color => l10n.ksToolColor,
                        },
                        selected: t == tool,
                        onTap: () => setState(() => _tool = t),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            SizedBox(
              height: 96,
              child: switch (tool) {
                _Tool.layout => _LayoutStrip(
                  templates: layouts,
                  selected: _d.template,
                  draft: _d,
                  content: cardContent(
                    l10n,
                    Localizations.localeOf(context),
                    c,
                    _d,
                    _growth,
                  ),
                  onPick: (t) => setState(
                    () => _d = _d.copyWith(template: t, palette: t.palette),
                  ),
                ),
                _Tool.photo => _PhotoStrip(
                  babyId: c.babyId,
                  occasion: _d.occasion,
                  date: _d.date,
                  onDevice: _pickDevice,
                  onPick: (m) => setState(() => _d = _d.withPhoto(photoOf(m))),
                ),
                _Tool.message => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                  child: ClTextField(
                    label: l10n.ksMessageLabel,
                    controller: _quote,
                    maxLength: _d.template.text('quote')?.max ?? 60,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (v) =>
                        setState(() => _d = _d.copyWith(quote: v.trim())),
                  ),
                ),
                _Tool.color => _PaletteStrip(
                  palettes: palettes,
                  selected: _d.palette,
                  onPick: (p) => setState(() => _d = _d.copyWith(palette: p)),
                ),
              },
            ),
            Container(
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
                children: [
                  ClButton(
                    label: l10n.ksSaveCard,
                    expand: true,
                    loading: _busy,
                    onPressed: _busy || !_d.ready ? null : () => _save(c),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.ksPrefilled(c.nickname),
                    textAlign: TextAlign.center,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
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

/// The `createMemorySession` request for a saved card: Chỉ ba mẹ, no family notice (D-068),
/// dated on the occasion (today if it is still ahead), tagged with its milestone, and keeping the
/// template and version it was made with.
Map<String, Object?> cardMemoryRequest({
  required CardDraft draft,
  required DateTime today,
  required String milestoneName,
}) {
  final t = DateTime(today.year, today.month, today.day);
  final day = draft.date.isAfter(t) ? t : draft.date;
  return {
    'babyId': draft.babyId,
    'memoryId': newMemoryId(),
    'batchId': newBatchId(),
    'caption': null,
    'audience': Audience.parents.name,
    'notifyFamily': false,
    'dateMode': 'single',
    'date': isoDateOf(day),
    'milestone': MilestoneRef(
      id: draft.occasion.milestoneId,
      name: milestoneName,
      date: day,
    ).toJson(),
    'albumIds': const <String>[],
    'generated': {
      'kind': 'card',
      'templateId': draft.template.id,
      'templateVersion': draft.template.version,
      'occasion': draft.occasion.wire,
      'format': draft.format.name,
    },
  };
}

/// Draws the boundary at the export size: 2160 px wide, PNG, plus a JPEG copy (quality 92) for
/// Kỷ niệm and the "JPG" choice.
Future<CardResult> exportCard(GlobalKey boundary, CardDraft d) async {
  final box =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await box.toImage(
    pixelRatio: KeepsakeFormat.exportWidth / box.size.width,
  );
  final png = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  final jpg = await FlutterImageCompress.compressWithList(
    png,
    minWidth: image.width,
    minHeight: image.height,
    quality: 92,
  );
  image.dispose();
  final dir = await getTemporaryDirectory();
  final name = 'child-life-card-${const Uuid().v4().substring(0, 8)}';
  final pngFile = File('${dir.path}/$name.png');
  final jpgFile = File('${dir.path}/$name.jpg');
  await pngFile.writeAsBytes(png, flush: true);
  await jpgFile.writeAsBytes(jpg, flush: true);
  return CardResult(draft: d, png: pngFile, jpg: jpgFile);
}

class KeepsakePhotoHint extends StatelessWidget {
  const KeepsakePhotoHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x8C000000),
      borderRadius: BorderRadius.circular(ClRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ClIcon(ClIcons.camera, size: 12, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class KeepsakeRoundIcon extends StatelessWidget {
  const KeepsakeRoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: c.ink),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final ClIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = selected ? cl.colors.mintText : cl.colors.ink;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        height: 57,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.control),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClIcon(icon, size: 18, color: ink),
            const SizedBox(height: 4),
            Text(
              label,
              style: cl.text.caption.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutStrip extends StatelessWidget {
  const _LayoutStrip({
    required this.templates,
    required this.selected,
    required this.draft,
    required this.content,
    required this.onPick,
  });
  final List<KeepsakeTemplate> templates;
  final KeepsakeTemplate selected;
  final CardDraft draft;
  final CardContent content;
  final ValueChanged<KeepsakeTemplate> onPick;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    const w = 70.0;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(width: ClSpace.s2),
      itemBuilder: (context, i) {
        final t = templates[i];
        final on = t.id == selected.id;
        return ClPressable(
          onPressed: () => onPick(t),
          selected: on,
          semanticLabel: t.name.of(Localizations.localeOf(context)),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(
                color: on ? cl.colors.mint : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: KeepsakeCardView(
                template: t,
                format: draft.format,
                content: content,
                width: w,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoStrip extends ConsumerWidget {
  const _PhotoStrip({
    required this.babyId,
    required this.occasion,
    required this.date,
    required this.onDevice,
    required this.onPick,
  });
  final String babyId;
  final Occasion occasion;
  final DateTime date;
  final VoidCallback onDevice;
  final ValueChanged<MediaItem> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final media = ref.watch(mediaProvider((babyId, true))).value ?? const [];
    final photos = [
      for (final m in media)
        if (m.isReady &&
            !m.deleted &&
            !m.isVideo &&
            m.generatedKind == null &&
            m.thumbPath != null)
          m,
    ];
    // Tagged with the occasion first, then closest to its day.
    photos.sort((a, b) {
      final ta = a.milestone?.id == occasion.milestoneId ? 0 : 1;
      final tb = b.milestone?.id == occasion.milestoneId ? 0 : 1;
      if (ta != tb) return ta - tb;
      return a.captureAt
          .difference(date)
          .abs()
          .compareTo(b.captureAt.difference(date).abs());
    });
    const size = 80.0;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      children: [
        ClPressable(
          onPressed: onDevice,
          semanticLabel: l10n.ksFromDevice,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(ClRadius.control),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClIcon(ClIcons.plus, size: 18, color: cl.colors.ink),
                const SizedBox(height: 4),
                Text(
                  l10n.ksFromDevice,
                  textAlign: TextAlign.center,
                  style: cl.text.caption.copyWith(color: cl.colors.ink),
                ),
              ],
            ),
          ),
        ),
        for (final m in photos.take(60)) ...[
          const SizedBox(width: ClSpace.s2),
          ClPressable(
            onPressed: () => onPick(m),
            semanticLabel: l10n.ksToolPhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.control),
              child: Image(
                image: StorageImage(m.thumbPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({
    required this.palettes,
    required this.selected,
    required this.onPick,
  });
  final List<KeepsakePalette> palettes;
  final KeepsakePalette selected;
  final ValueChanged<KeepsakePalette> onPick;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: 12),
      itemCount: palettes.length,
      separatorBuilder: (_, _) => const SizedBox(width: ClSpace.s3),
      itemBuilder: (context, i) {
        final p = palettes[i];
        final on = p == selected;
        return ClPressable(
          onPressed: () => onPick(p),
          selected: on,
          semanticLabel: '${AppLocalizations.of(context).ksToolColor} ${i + 1}',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: on ? cl.colors.mint : cl.colors.separator,
                width: on ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: p.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------
// MM12 · thiệp đã sẵn sàng

class MilestoneCardDoneScreen extends ConsumerStatefulWidget {
  const MilestoneCardDoneScreen({required this.result, super.key});
  final CardResult result;

  @override
  ConsumerState<MilestoneCardDoneScreen> createState() => _DoneState();
}

class _DoneState extends ConsumerState<MilestoneCardDoneScreen> {
  var _jpg = false;
  var _busy = false;

  File get _file => _jpg ? widget.result.jpg : widget.result.png;

  Future<void> _saveToDevice() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await saveToLibrary(context, _file, video: false);
      toaster.show(message: l10n.ksSavedToDevice);
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_file.path, mimeType: _jpg ? 'image/jpeg' : 'image/png')],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final d = widget.result.draft;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          child: Column(
            children: [
              Row(
                children: [
                  KeepsakeRoundIcon(
                    icon: ClIcons.close,
                    label: l10n.a11yClose,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  // Edit again: a new card is saved next to this one.
                  KeepsakeRoundIcon(
                    icon: ClIcons.edit,
                    label: l10n.ksEditAgain,
                    onTap: () => context.pushReplacement(
                      Routes.milestoneCardEdit,
                      extra: d,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final w = math.min(
                      box.maxWidth * 0.66,
                      box.maxHeight * 0.8 * d.format.aspect,
                    );
                    return Center(
                      child: Transform.rotate(
                        angle: 0.06,
                        child: Container(
                          width: w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: cl.colors.sunshine.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 60,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              widget.result.png,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Text(l10n.ksCardReady, style: cl.text.title),
              const SizedBox(height: ClSpace.s2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                      l10n.ksSavedParents,
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
                  Text(
                    l10n.ksExport,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                  const Spacer(),
                  for (final jpg in [false, true]) ...[
                    const SizedBox(width: ClSpace.s2),
                    ClPressable(
                      onPressed: () => setState(() => _jpg = jpg),
                      selected: _jpg == jpg,
                      semanticLabel: jpg ? 'JPG' : 'PNG',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _jpg == jpg
                              ? cl.colors.mintDeep
                              : cl.colors.surface2,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          jpg ? 'JPG' : 'PNG',
                          style: cl.text.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _jpg == jpg
                                ? cl.colors.onMintDeep
                                : cl.colors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: KeepsakeActionTile(
                      icon: ClIcons.download,
                      label: l10n.ksSaveDevice,
                      onTap: _busy ? null : _saveToDevice,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: KeepsakeActionTile(
                      icon: ClIcons.link,
                      label: l10n.ksShare,
                      onTap: _share,
                    ),
                  ),
                  // MM12 "Tạo video 1 tháng" once Video kỷ niệm is open to the family.
                  if (ref.watch(selectedKeepsakeAccessProvider).videos) ...[
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: KeepsakeActionTile(
                        icon: ClIcons.camera,
                        label: l10n.ksMakeVideoFor(d.occasion.label(l10n)),
                        onTap: () => context.push(
                          '${Routes.memoryStory}?occasion=${d.occasion.wire}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ClSpace.s4),
            ],
          ),
        ),
      ),
    );
  }
}

class KeepsakeActionTile extends StatelessWidget {
  const KeepsakeActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });
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
        height: 82,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.control + 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 16, color: cl.colors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: cl.text.caption.copyWith(
                color: cl.colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain page with a back button and a large title (MM10).
class KeepsakePage extends StatelessWidget {
  const KeepsakePage({
    required this.title,
    required this.children,
    this.header,
    this.embedded = false,
    super.key,
  });
  final String title;
  final List<Widget> children;

  /// Only the scrolling content, for a page of [KeepsakeKindsScreen].
  final bool embedded;

  /// In place of the title (the Thiệp / Video tabs).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    if (embedded) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          ClSpace.s4,
          0,
          ClSpace.s4,
          MediaQuery.paddingOf(context).bottom + ClSpace.s6,
        ),
        children: children,
      );
    }
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            ClSpace.s4,
            0,
            ClSpace.s4,
            MediaQuery.paddingOf(context).bottom + ClSpace.s6,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ClBackButton(
                semanticLabel: l10n.a11yBack,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            header ??
                Semantics(
                  header: true,
                  child: Text(title, style: cl.text.largeTitle),
                ),
            const SizedBox(height: ClSpace.s4),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// "Thiệp · Video" as large titles, like Kỷ niệm's "Ảnh · Album": the page in view in ink.
/// They follow the swipe between the two pages and move to one when tapped.
class KeepsakeKindTabs extends StatelessWidget {
  const KeepsakeKindTabs({required this.pages, super.key});
  final PageController pages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) {
        final page = pages.hasClients && pages.position.haveDimensions
            ? pages.page ?? pages.initialPage.toDouble()
            : pages.initialPage.toDouble();
        Widget tab(String label, int index) {
          final t = (1 - (page - index).abs()).clamp(0.0, 1.0);
          return ClPressable(
            onPressed: () => unawaited(
              pages.animateToPage(
                index,
                duration: ClMotion.gentle,
                curve: Curves.easeOutCubic,
              ),
            ),
            selected: t > 0.5,
            semanticLabel: label,
            pressedOpacity: 1,
            minSize: Size.zero,
            child: Semantics(
              header: t > 0.5,
              child: Text(
                label,
                style: cl.text.title.copyWith(
                  color: Color.lerp(
                    cl.colors.inkMuted.withValues(alpha: 0.55),
                    cl.colors.ink,
                    t,
                  ),
                ),
              ),
            ),
          );
        }

        return Row(
          children: [
            tab(l10n.ksTabCards, 0),
            const SizedBox(width: ClSpace.s4),
            tab(l10n.ksTabVideos, 1),
          ],
        );
      },
    );
  }
}

/// Thiệp cột mốc and Video kỷ niệm as two pages of one screen, swiped sideways (owner,
/// 2026-10-14: "swipe giữa hai tab thiệp và video"); each page scrolls as before and keeps its
/// place. Someone allowed only one of them gets that screen alone.
class KeepsakeKindsScreen extends ConsumerStatefulWidget {
  const KeepsakeKindsScreen({
    required this.video,
    this.occasion,
    this.photoIds,
    super.key,
  });

  /// Opens on Video kỷ niệm (else Thiệp cột mốc).
  final bool video;
  final Occasion? occasion;
  final List<String>? photoIds;

  @override
  ConsumerState<KeepsakeKindsScreen> createState() => _KindsState();
}

class _KindsState extends ConsumerState<KeepsakeKindsScreen> {
  late final _pages = PageController(initialPage: widget.video ? 1 : 0);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = memoryCtx(context, ref);
    final access = ref.watch(selectedKeepsakeAccessProvider);
    final both =
        c != null &&
        c.isParent &&
        c.dob != null &&
        access.cards &&
        access.videos;
    if (!both) {
      return widget.video
          ? MemoryStoryTemplatesScreen(
              occasion: widget.occasion,
              photoIds: widget.photoIds,
            )
          : MilestoneCardScreen(
              occasion: widget.occasion,
              photoIds: widget.photoIds,
            );
    }
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClBackButton(
                    semanticLabel: l10n.a11yBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  KeepsakeKindTabs(pages: _pages),
                  const SizedBox(height: ClSpace.s4),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                children: [
                  _KeepAlive(
                    child: MilestoneCardScreen(
                      occasion: widget.occasion,
                      photoIds: widget.photoIds,
                      embedded: true,
                    ),
                  ),
                  _KeepAlive(
                    child: MemoryStoryTemplatesScreen(
                      occasion: widget.occasion,
                      photoIds: widget.photoIds,
                      embedded: true,
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

/// Keeps a page's state (the dịp, the format, the scroll) while the other one is in view.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
