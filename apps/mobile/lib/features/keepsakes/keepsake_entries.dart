import '../engagement/engagement_repository.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart' show ClTileShadow;
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';
import '../memories/media_viewer.dart';
import '../memories/memories_screen.dart' show MemoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import 'keepsake_access.dart';
import 'keepsake_card_view.dart';
import 'keepsake_catalog.dart';
import 'keepsake_jobs.dart';
import 'keepsake_live.dart';
import 'keepsake_nudges.dart';
import 'keepsake_occasions.dart';

/// Where Kỷ niệm 2.0 is reached from inside Kỷ niệm (D-068; Figma MM01 `528:9260`, MM02
/// `537:9720`, MM15 `532:9453`). Video kỷ niệm joins these entries with its flow (plan C3); until
/// then only Thiệp cột mốc shows. Nothing shows for people who may not create (R-119) or families
/// outside the beta (D-068 #3).

/// MM01 "Tạo từ kỷ niệm của Teddy" on the Ảnh tab, under the Tự lưu entry.
class KeepsakeCreateSection extends ConsumerWidget {
  const KeepsakeCreateSection({required this.ctx, super.key});
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(selectedKeepsakeAccessProvider);
    if (!ctx.parentView || (!access.cards && !access.videos)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    // MM03 takes the place of "Tạo từ kỷ niệm" while an occasion is near (D-068 #9).
    ref.watch(nudgeRevisionProvider);
    final store = ref.watch(nudgeStoreProvider);
    final dob = ctx.dob;
    ref.watch(engagementRevisionProvider);
    final newCampaign = ref.watch(engagementProvider).value?['suggestions'];
    final handed =
        newCampaign is List &&
        newCampaign.any(
          (s) => s is Map && s['kind'] == 'ENG-02' && s['context'] == 'current',
        );
    final nudge =
        dob == null ||
            handed ||
            !ref.watch(completeMediaProvider((ctx.babyId, true))).hasValue
        ? null
        : inAppNudge(
            NudgeBaby(
              babyId: ctx.babyId,
              name: ctx.nickname,
              dob: dob,
              media:
                  ref.watch(completeMediaProvider((ctx.babyId, true))).value ??
                  const [],
            ),
            ctx.now,
            dismissed: store.dismissed(),
            snoozed: store.snoozed(),
          );
    if (nudge != null) {
      return MilestoneNudgeCard(
        ctx: ctx,
        occasion: nudge.occasion,
        date: nudge.date,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ksCreateFrom(ctx.nickname),
                  style: cl.text.bodyStrong,
                ),
              ),
              ClPressable(
                onPressed: () => context.push(
                  access.cards ? Routes.milestoneCard : Routes.memoryStory,
                ),
                semanticLabel: l10n.ksSeeTemplates,
                child: Text(
                  l10n.ksSeeTemplates,
                  style: cl.text.label.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              if (access.videos)
                Expanded(
                  child: KeepsakeCreateTile(
                    title: l10n.ksVideoTitle,
                    hint: l10n.ksVideoTileHint,
                    preview: _VideoFan(ctx: ctx),
                    onTap: () => context.push(Routes.memoryStory),
                  ),
                ),
              if (access.videos && access.cards)
                const SizedBox(width: ClSpace.s3),
              if (access.cards)
                Expanded(
                  child: KeepsakeCreateTile(
                    title: l10n.ksCardTitle,
                    hint: l10n.ksCardTileHint,
                    preview: const _CardFan(),
                    onTap: () => context.push(Routes.milestoneCard),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A "Video kỷ niệm" / "Thiệp cột mốc" tile with its preview and the "Mới" badge (MM01, MM02).
class KeepsakeCreateTile extends StatelessWidget {
  const KeepsakeCreateTile({
    required this.title,
    required this.hint,
    required this.preview,
    required this.onTap,
    this.previewHeight = 96,
    super.key,
  });
  final String title;
  final String hint;
  final Widget preview;
  final double previewHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          boxShadow: cl.shadows.card,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: previewHeight,
              child: Center(child: preview),
            ),
            const SizedBox(height: ClSpace.s2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.bodyStrong,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.ksNew,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two published cards, fanned like MM01's preview; nothing until the catalog is there.
class _CardFan extends ConsumerWidget {
  const _CardFan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cards = ref.watch(keepsakeCatalogProvider).value?.cards ?? const [];
    final shown = [
      for (final t in cards.take(2))
        if (t.layouts.containsKey(KeepsakeFormat.portrait)) t,
    ];
    if (shown.isEmpty) {
      return ClIcon(ClIcons.star, size: 32, color: context.cl.colors.mintText);
    }
    const w = 68.0;
    return SizedBox(
      width: w * 1.8,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (i, t) in shown.indexed)
            Positioned(
              left: i * w * 0.75,
              top: i == 0 ? 8 : 0,
              child: Transform.rotate(
                angle: i == 0 ? -0.08 : 0.04,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: KeepsakeCardView(
                    template: t,
                    format: KeepsakeFormat.portrait,
                    width: w,
                    content: CardContent(
                      occasion: i == 0 ? l10n.ksOccD7 : l10n.ksOccM1,
                      name: '',
                      date: '',
                      quote: '',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Câu chuyện tab (D-068 #2): MM15's quick-create row and "Thiệp cột mốc" first, then the
/// title over today's stories, which follow unchanged.
class KeepsakeStorySections extends ConsumerWidget {
  const KeepsakeStorySections({required this.ctx, super.key});
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final access = ref.watch(selectedKeepsakeAccessProvider);
    final canCreate = ctx.parentView && (access.cards || access.videos);
    final media =
        ref.watch(completeMediaProvider((ctx.babyId, ctx.isParent))).value ??
        const [];
    final cards = [
      for (final m in media)
        if (m.generatedKind == 'card' &&
            m.isReady &&
            !m.deleted &&
            (ctx.parentView || m.effectiveAudience == Audience.family))
          m,
    ];
    final videos = [
      for (final m in media)
        if (m.generatedKind == 'video' &&
            m.isReady &&
            !m.deleted &&
            (ctx.parentView || m.effectiveAudience == Audience.family))
          m,
    ];
    // MM15: drafts (failed renders, kept with their inputs) and renders in progress.
    final jobs = ctx.parentView && access.videos
        ? [
            for (final j
                in ref.watch(myKeepsakeJobsProvider(ctx.babyId)).value ??
                    const <KeepsakeJob>[])
              if (j.status != KeepsakeJobStatus.completed) j,
          ]
        : const <KeepsakeJob>[];
    if (!canCreate && cards.isEmpty && videos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCreate) ...[
          Row(
            children: [
              if (access.videos)
                Expanded(
                  child: _QuickCreate(
                    icon: ClIcons.camera,
                    label: l10n.ksVideoTitle,
                    onTap: () => context.push(Routes.memoryStory),
                  ),
                ),
              if (access.videos && access.cards)
                const SizedBox(width: ClSpace.s2),
              if (access.cards)
                Expanded(
                  child: _QuickCreate(
                    icon: ClIcons.star,
                    label: l10n.ksCardTitle,
                    onTap: () => context.push(Routes.milestoneCard),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        if (videos.isNotEmpty || jobs.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.ksVideoTitle,
            trailing: l10n.ksVideoCount(videos.length),
          ),
          const SizedBox(height: ClSpace.s3),
          SizedBox(
            height: 200 + 20,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: ClTileShadow.stripPadding,
              children: [
                for (final (i, v) in videos.indexed) ...[
                  if (i > 0) const SizedBox(width: ClSpace.s2),
                  SizedBox(
                    width: 112,
                    child: ClTileShadow(
                      child: MediaTile(
                        item: v,
                        radius: 12,
                        onTap: () =>
                            openViewer(context, items: videos, start: i),
                      ),
                    ),
                  ),
                ],
                for (final j in jobs) ...[
                  const SizedBox(width: ClSpace.s2),
                  _JobTile(job: j),
                ],
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        if (cards.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.ksCardTitle,
            trailing: l10n.ksCardCount(cards.length),
          ),
          const SizedBox(height: ClSpace.s3),
          SizedBox(
            height: 140 + 20,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: ClTileShadow.stripPadding,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: ClSpace.s2),
              itemBuilder: (context, i) => SizedBox(
                width: 112,
                child: ClTileShadow(
                  child: MediaTile(
                    item: cards[i],
                    radius: 12,
                    onTap: () => openViewer(context, items: cards, start: i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        _SectionHeader(title: l10n.ksStoriesSection),
        const SizedBox(height: ClSpace.s3),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: cl.text.headline.copyWith(fontSize: 18)),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
      ],
    );
  }
}

class _QuickCreate extends StatelessWidget {
  const _QuickCreate({
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
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          boxShadow: cl.shadows.card,
          borderRadius: BorderRadius.circular(ClRadius.control + 4),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cl.colors.mintDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 16, color: cl.colors.onMintDeep),
            ),
            const SizedBox(width: ClSpace.s3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cl.text.bodyStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MM03 "Gợi ý theo cột mốc" (`528:9864`): "Thứ Bảy này · 14/11 · Teddy sắp tròn 1 tháng!",
/// Tạo thiệp, Để sau (3 days) and × (never again for this occasion, its notifications too).
/// "Tạo video" joins with Video kỷ niệm (plan C3).
class MilestoneNudgeCard extends ConsumerWidget {
  const MilestoneNudgeCard({
    required this.ctx,
    required this.occasion,
    required this.date,
    super.key,
  });
  final MemoryCtx ctx;
  final Occasion occasion;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final today = DateTime(ctx.now.year, ctx.now.month, ctx.now.day);
    final gap = date.difference(today).inDays;
    final day = DateFormat('d/M').format(date);
    final when = switch (gap) {
      0 => '${l10n.ksToday} · $day',
      1 => '${l10n.ksTomorrow} · $day',
      > 1 && < 7 => l10n.ksThisWeekday(
        toBeginningOfSentenceCase(DateFormat('EEEE', ctx.locale).format(date)),
        day,
      ),
      _ => day,
    };
    final words = occasion.title(l10n);
    final message = !occasion.byAge
        ? l10n.ksNudgeFirst(ctx.nickname, occasion.label(l10n))
        : gap > 0
        ? l10n.ksNudgeSoon(ctx.nickname, words)
        : gap == 0
        ? l10n.ksNudgeToday(ctx.nickname, words)
        : l10n.ksNudgeJust(ctx.nickname, words);
    final key = nudgeKey(ctx.babyId, occasion);
    final access = ref.watch(selectedKeepsakeAccessProvider);
    final card = ref.watch(keepsakeCatalogProvider).value?.cards.firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
          border: Border.all(color: cl.colors.mint, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card != null &&
                    card.layouts.containsKey(KeepsakeFormat.portrait))
                  Padding(
                    padding: const EdgeInsets.only(right: ClSpace.s3),
                    child: Transform.rotate(
                      angle: 0.05,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: KeepsakeCardView(
                          template: card,
                          format: KeepsakeFormat.portrait,
                          width: 56,
                          content: CardContent(
                            occasion: words,
                            name: ctx.nickname,
                            date: '',
                            quote: '',
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClIcon(
                            occasion.icon,
                            size: 13,
                            color: cl.colors.mintText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              when,
                              style: cl.text.caption.copyWith(
                                color: cl.colors.mintText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(message, style: cl.text.bodyStrong),
                    ],
                  ),
                ),
                ClPressable(
                  onPressed: () async {
                    await ref.read(nudgeStoreProvider).dismiss(key);
                    ref.read(nudgeRevisionProvider.notifier).bump();
                  },
                  semanticLabel: l10n.a11yClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClIcon(
                      ClIcons.close,
                      size: 18,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Row(
              children: [
                if (access.videos) ...[
                  _NudgePill(
                    icon: ClIcons.camera,
                    label: l10n.ksMakeVideo,
                    filled: true,
                    onTap: () => context.push(
                      '${Routes.memoryStory}?occasion=${occasion.wire}',
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                ],
                if (access.cards)
                  _NudgePill(
                    icon: ClIcons.star,
                    label: l10n.ksMakeCard,
                    filled: !access.videos,
                    onTap: () => context.push(
                      '${Routes.milestoneCard}?occasion=${occasion.wire}',
                    ),
                  ),
                const Spacer(),
                ClPressable(
                  onPressed: () async {
                    await ref
                        .read(nudgeStoreProvider)
                        .snooze(key, today.add(const Duration(days: 3)));
                    ref.read(nudgeRevisionProvider.notifier).bump();
                  },
                  semanticLabel: l10n.ksLater,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.ksLater,
                      style: cl.text.label.copyWith(
                        color: cl.colors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgePill extends StatelessWidget {
  const _NudgePill({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final ClIcons icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = filled ? cl.colors.onMintDeep : cl.colors.mintText;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: filled ? cl.colors.mintDeep : null,
          border: filled ? null : Border.all(color: cl.colors.mint, width: 1.5),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 15, color: ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(
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

/// Three 9:16 covers fanned like MM01's video preview, from the baby's newest photos.
class _VideoFan extends ConsumerWidget {
  const _VideoFan({required this.ctx});
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final photos = [
      for (final m
          in ref.watch(completeMediaProvider((ctx.babyId, true))).value ??
              const <MediaItem>[])
        if (m.isReady &&
            !m.isVideo &&
            !m.deleted &&
            m.generatedKind == null &&
            m.thumbPath != null)
          m,
    ].take(3).toList();
    if (photos.isEmpty) {
      return ClIcon(ClIcons.camera, size: 32, color: cl.colors.mintText);
    }
    const w = 52.0;
    return SizedBox(
      width: w * 2.6,
      height: 96,
      child: Stack(
        children: [
          for (final (i, m) in photos.indexed)
            Positioned(
              left: i * w * 0.8,
              top: i == 1 ? 0 : 6,
              child: Transform.rotate(
                angle: (i - 1) * 0.07,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image(
                    image: StorageImage(m.thumbPath!),
                    width: w,
                    height: w * 16 / 9,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// MM15: a render in progress, or a draft (a failed render, kept with its inputs).
class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});
  final KeepsakeJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final failed = job.status == KeepsakeJobStatus.failed;
    return ClPressable(
      onPressed: () =>
          context.push('${Routes.memoryStoryJob}/${job.id}?baby=${job.babyId}'),
      semanticLabel: failed ? l10n.ksVideoDraftTile : job.title,
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(ClSpace.s2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cl.colors.controlBorder, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (failed)
              ClIcon(ClIcons.edit, size: 20, color: cl.colors.inkMuted)
            else
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  value: job.progress <= 0 ? null : job.progress / 100,
                  color: cl.colors.mint,
                ),
              ),
            const SizedBox(height: ClSpace.s2),
            Text(
              failed
                  ? l10n.ksVideoDraftTile
                  : l10n.ksVideoInProgress(job.progress),
              textAlign: TextAlign.center,
              style: cl.text.label.copyWith(
                color: cl.colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              job.templateName ?? job.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            if (failed) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.ksVideoContinue,
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

/// MM17: "Video đã sẵn sàng" floating above the dock when one of this person's videos finished
/// in the last 30 minutes and has not been opened from here; while one is being made, "Đang tạo
/// video · 45%" (on every Kỷ niệm tab), so it can be reopened after leaving MM08. It also keeps
/// the iPhone Live Activity in step while the app is open.
class KeepsakeReadyBanner extends ConsumerWidget {
  const KeepsakeReadyBanner({required this.ctx, super.key});
  final MemoryCtx ctx;

  static const seenKey = 'keepsakes.bannerSeen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(selectedKeepsakeAccessProvider);
    if (!ctx.parentView || !access.videos) return const SizedBox.shrink();
    ref.watch(nudgeRevisionProvider);
    final SharedPreferences prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } on Object {
      return const SizedBox.shrink();
    }
    ref.listen(myKeepsakeJobsProvider(ctx.babyId), (before, after) {
      final was = {
        for (final j in before?.value ?? const <KeepsakeJob>[]) j.id: j,
      };
      for (final j in after.value ?? const <KeepsakeJob>[]) {
        final w = was[j.id];
        if (w == null && !j.active) continue;
        if (w != null &&
            w.status == j.status &&
            w.step == j.step &&
            w.progress == j.progress) {
          continue;
        }
        unawaited(ref.read(keepsakeLiveProvider).update(j));
      }
    });
    final seen = {...?prefs.getStringList(seenKey)};
    final jobs =
        ref.watch(myKeepsakeJobsProvider(ctx.babyId)).value ??
        const <KeepsakeJob>[];
    final job = jobs
        .where(
          (j) =>
              j.status == KeepsakeJobStatus.completed &&
              !seen.contains(j.id) &&
              (j.updatedAt ?? j.createdAt).isAfter(
                ctx.now.subtract(const Duration(minutes: 30)),
              ),
        )
        .firstOrNull;
    if (job == null) {
      final making = jobs.where((j) => j.active).firstOrNull;
      return making == null
          ? const SizedBox.shrink()
          : _MakingBanner(job: making);
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final media =
        ref.watch(completeMediaProvider((ctx.babyId, true))).value ??
        const <MediaItem>[];
    final thumb = media
        .where((m) => m.id == job.outputMediaId)
        .firstOrNull
        ?.thumbPath;
    Future<void> open() async {
      await markKeepsakeVideoSeen(ref, job.id);
      if (context.mounted) {
        unawaited(
          context.push('${Routes.memoryStoryJob}/${job.id}?baby=${job.babyId}'),
        );
      }
    }

    final s = ((job.durationMs ?? 0) / 1000).round();
    return ClPressable(
      onPressed: open,
      semanticLabel: l10n.ksVideoReady,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 64,
                child: thumb == null
                    ? ColoredBox(color: cl.colors.surface2)
                    : Image(image: StorageImage(thumb), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.ksVideoReady.replaceAll('!', ''),
                    style: cl.text.bodyStrong,
                  ),
                  Text(
                    '“${job.title}” · ${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cl.colors.mintDeep,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Text(
                l10n.ksBannerView,
                style: cl.text.label.copyWith(
                  color: cl.colors.onMintDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Not now: the banner goes (the video stays in Kỷ niệm).
            ClPressable(
              onPressed: () => unawaited(markKeepsakeVideoSeen(ref, job.id)),
              semanticLabel: l10n.a11yClose,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ClIcon(
                  ClIcons.close,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MM17's banner is done with [jobId]: opened from it or anywhere else (push, Live Activity,
/// Câu chuyện), or closed.
Future<void> markKeepsakeVideoSeen(WidgetRef ref, String jobId) async {
  final SharedPreferences prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } on Object {
    return;
  }
  final seen = prefs.getStringList(KeepsakeReadyBanner.seenKey) ?? const [];
  if (seen.contains(jobId)) return;
  await prefs.setStringList(
    KeepsakeReadyBanner.seenKey,
    [...seen, jobId].take(50).toList(),
  );
  ref.read(nudgeRevisionProvider.notifier).bump();
}

/// "Đang tạo video · 45%": opens MM08 for the job.
class _MakingBanner extends StatelessWidget {
  const _MakingBanner({required this.job});
  final KeepsakeJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final queued = job.status == KeepsakeJobStatus.queued;
    final line = queued
        ? l10n.ksVideoActiveQueued
        : l10n.ksVideoActive(job.progress);
    return ClPressable(
      onPressed: () =>
          context.push('${Routes.memoryStoryJob}/${job.id}?baby=${job.babyId}'),
      semanticLabel: line,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: queued ? null : job.progress / 100,
                strokeWidth: 3,
                color: cl.colors.mint,
                backgroundColor: cl.colors.surface2,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(line, style: cl.text.bodyStrong),
                  if (job.templateName != null)
                    Text(
                      job.templateName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
