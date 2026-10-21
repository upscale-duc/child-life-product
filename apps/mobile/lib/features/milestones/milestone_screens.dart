import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../care/care_format.dart' show authorLabel;
import '../care/care_models.dart' show CareAuthor;
import '../family/family_labels.dart' show relationLabel;
import '../keepsakes/keepsake_access.dart';
import '../memories/media_viewer.dart' show openViewer;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart' show MediaTile;
import '../memories/upload_queue.dart' show PickedMedia;
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import 'milestone_card_link.dart';
import 'milestone_models.dart';
import 'milestone_repository.dart';
import 'milestone_sheets.dart';
import 'milestone_widgets.dart';
import 'picked_preview.dart';

/// Mốc phát triển (Figma v1.1 3a–3g; D-076 #6). Reference milestones come from the portal
/// (`contentMilestones`); the baby's records are a Cùng nuôi's (`moments.create`), and others
/// browse the guide only. The app never judges early or late: outside its window a milestone is
/// "Chưa ghi", never "chậm", and every age is "tham khảo" ("Mỗi bé có nhịp riêng").

String milestoneLocation(String id) => '${Routes.milestones}/$id';

/// Where a record opens: the reference milestone's page, or the custom record's.
String recordLocation(MilestoneRecord r) =>
    milestoneLocation(r.referenceId ?? r.id);

enum _Filter { all, motor, communication, cognitive, social, own }

extension on _Filter {
  MilestoneGroup? get group => switch (this) {
    _Filter.motor => MilestoneGroup.motor,
    _Filter.communication => MilestoneGroup.communication,
    _Filter.cognitive => MilestoneGroup.cognitive,
    _Filter.social => MilestoneGroup.socialEmotional,
    _ => null,
  };
}

/// Everything 3a shows, worked out once: records joined with the reference set.
class MilestoneBoard {
  MilestoneBoard({
    required this.reference,
    required this.records,
    required this.dob,
    required this.today,
  });

  final List<ReferenceMilestone> reference;
  final List<MilestoneRecord> records;
  final DateTime? dob;
  final DateTime today;

  late final Map<String, ReferenceMilestone> byId = {
    for (final m in reference) m.id: m,
  };
  late final Map<String, MilestoneRecord> recordById = {
    for (final r in records) r.id: r,
  };

  MilestoneGroup? groupOf(MilestoneRecord r) =>
      r.referenceId == null ? null : byId[r.referenceId]?.group;

  /// "Đã quan sát", newest first.
  late final List<MilestoneRecord> seen = [
    for (final r in records)
      if (r.observed) r,
  ]..sort((a, b) => b.date!.compareTo(a.date!));

  late final List<MilestoneRecord> following = [
    for (final r in records)
      if (r.status == RecordStatus.following) r,
  ];

  MilestoneState stateOf(ReferenceMilestone m) => milestoneState(
    recordById[m.recordId],
    dob == null ? null : m.ageRange.windowFor(dob!),
    today,
  );

  /// "Gợi ý quanh tuổi của bé": around now first, then coming up.
  late final List<ReferenceMilestone> around = [
    for (final m in reference)
      if (stateOf(m) == MilestoneState.now) m,
    for (final m in reference)
      if (stateOf(m) == MilestoneState.upcoming) m,
  ];

  /// Not recorded, not around now ("Chưa ghi", earlier or later: never "late").
  late final List<ReferenceMilestone> others = [
    for (final m in reference)
      if (stateOf(m) == MilestoneState.notRecorded) m,
  ];

  /// Shown first today (Home "Dành cho bé hôm nay"): around now, not recorded.
  List<ReferenceMilestone> get forToday => [
    for (final m in reference)
      if (stateOf(m) == MilestoneState.now) m,
  ];
}

// ---------- 3a Mốc phát triển ----------

class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> {
  var _filter = _Filter.all;
  var _showAll = false;

  String _filterLabel(AppLocalizations l10n, _Filter f) => switch (f) {
    _Filter.all => l10n.mtFilterAll,
    _Filter.own => l10n.mtOwn,
    _ => groupLabel(l10n, f.group),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final ctx = mtCtx(context, ref);
    if (ctx == null) return const MtPage(children: []);
    final referenceAsync = ref.watch(referenceMilestonesProvider);
    final records = ctx.canRecord
        ? ref.watch(milestoneRecordsProvider(ctx.babyId)).value ??
              const <MilestoneRecord>[]
        : const <MilestoneRecord>[];
    final board = MilestoneBoard(
      reference: referenceAsync.value ?? const [],
      records: records,
      dob: ctx.dob,
      today: ctx.today,
    );

    bool keepRef(ReferenceMilestone m) =>
        _filter == _Filter.all || m.group == _filter.group;
    bool keepRecord(MilestoneRecord r) => switch (_filter) {
      _Filter.all => true,
      _Filter.own => r.kind == RecordKind.custom,
      _ => board.groupOf(r) == _filter.group,
    };

    Widget refRow(ReferenceMilestone m, {Widget? trailing}) => MtRow(
      key: ValueKey('mt_${m.id}'),
      group: m.group,
      title: m.title.of(ctx.lang),
      subtitle:
          '${groupLabel(l10n, m.group)} · ${rangeLabel(l10n, m.ageRange)}',
      trailing: trailing,
      onTap: () => context.push(milestoneLocation(m.id)),
    );

    Widget recordRow(MilestoneRecord r) {
      final m = r.referenceId == null ? null : board.byId[r.referenceId];
      return MtRow(
        key: ValueKey('mt_${r.id}'),
        group: board.groupOf(r),
        title: m?.title.of(ctx.lang) ?? r.name,
        subtitle: r.kind == RecordKind.custom
            ? l10n.mtOwn
            : groupLabel(l10n, board.groupOf(r)),
        trailing: r.observed
            ? MtBadge(label: badgeDay(ctx.lang, r.date!), check: true)
            : MtBadge(label: l10n.mtFollowingTag),
        onTap: () => context.push(recordLocation(r)),
      );
    }

    final seen = board.seen.where(keepRecord).toList();
    final following = board.following.where(keepRecord).toList();
    final ownOnly = _filter == _Filter.own;
    final around = ownOnly
        ? const <ReferenceMilestone>[]
        : board.around.where(keepRef).toList();
    final others = ownOnly
        ? const <ReferenceMilestone>[]
        : board.others.where(keepRef).toList();
    final nothingPublished = referenceAsync.hasValue && board.reference.isEmpty;
    final shown = [...around, ...others];

    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cl.colors.peachSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (ctx.c.baby != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 56,
                height: 56,
                child: SavedBabyAvatar(baby: ctx.c.baby!, size: 56),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ctx.canRecord)
                  Text(
                    board.seen.isEmpty
                        ? l10n.mtSummaryNone(ctx.nickname)
                        : l10n.mtSummary(ctx.nickname, board.seen.length),
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cl.colors.ink,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  ctx.canRecord ? l10n.mtLead : l10n.mtLeadViewer,
                  // Ink on soft warm fills, also in Night care.
                  style: cl.text.label.copyWith(
                    color: cl.colors.ink,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return MtPage(
      children: [
        MtTitle(l10n.mtTitle),
        const SizedBox(height: ClSpace.s3),
        summary,
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _Filter.values)
                if (f != _Filter.own || ctx.canRecord)
                  Padding(
                    padding: const EdgeInsets.only(right: ClSpace.s2),
                    child: _FilterChip(
                      label: _filterLabel(l10n, f),
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
            ],
          ),
        ),
        if (referenceAsync.isLoading && !referenceAsync.hasValue) ...[
          const SizedBox(height: ClSpace.s4),
          for (var i = 0; i < 3; i++) ...[
            const ClSkeleton(height: 56),
            const SizedBox(height: ClSpace.s2),
          ],
        ] else if (referenceAsync.hasError && !referenceAsync.hasValue)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s6),
            child: ClEmptyState(
              icon: ClIcons.alert,
              title: l10n.mtEmptyTitle,
              message: l10n.toastActionFailed,
              actionLabel: l10n.actionRetry,
              onAction: () => ref.invalidate(referenceMilestonesProvider),
            ),
          ),
        if (seen.isNotEmpty) ...[
          MtSection(l10n.mtSeen),
          MtGroupCard(children: [for (final r in seen) recordRow(r)]),
        ],
        if (following.isNotEmpty) ...[
          MtSection(l10n.mtFollowingSection),
          MtGroupCard(children: [for (final r in following) recordRow(r)]),
        ],
        if (nothingPublished && seen.isEmpty && following.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s6),
            child: ClEmptyState(
              icon: ClIcons.star,
              title: l10n.mtEmptyTitle,
              message: ctx.canRecord
                  ? l10n.mtEmptyBody
                  : l10n.mtEmptyBodyViewer,
            ),
          ),
        if (ctx.dob == null && shown.isNotEmpty) ...[
          // The age is not known to this member (or not set): the whole guide by age.
          MtSection(l10n.mtReferenceSection),
          if (ctx.canRecord)
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s2),
              child: Text(
                l10n.mtNoDob,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          MtGroupCard(children: [for (final m in shown) refRow(m)]),
        ] else ...[
          if (around.isNotEmpty) ...[
            MtSection(l10n.mtAround),
            MtGroupCard(
              children: [
                for (final m in around)
                  refRow(
                    m,
                    trailing: board.stateOf(m) == MilestoneState.upcoming
                        ? MtBadge(label: l10n.mtUpcoming)
                        : null,
                  ),
              ],
            ),
          ],
          if (others.isNotEmpty) ...[
            if (_showAll) ...[
              MtSection(l10n.mtOthers),
              MtGroupCard(
                children: [
                  for (final m in others)
                    refRow(m, trailing: MtBadge(label: l10n.mtNotRecorded)),
                ],
              ),
            ],
            const SizedBox(height: ClSpace.s2),
            Center(
              child: ClButton(
                label: _showAll
                    ? l10n.mtShowLess
                    : l10n.mtShowAll(others.length),
                style: ClButtonStyle.plain,
                onPressed: () => setState(() => _showAll = !_showAll),
              ),
            ),
          ],
        ],
        if (ctx.canRecord) ...[
          const SizedBox(height: ClSpace.s4),
          MtDashedButton(
            label: l10n.mtCreateOwn,
            onPressed: () => context.push(Routes.milestoneOwn),
          ),
        ] else if (shown.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.mtParentsRecord,
            textAlign: TextAlign.center,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        if (board.reference.isNotEmpty)
          MtContentNote(
            illustrative: board.reference.any((m) => m.illustrative),
            reviewer: board.reference.first.reviewer,
          ),
      ],
    );
  }
}

/// 3a's filter chip: ink when selected (white text in Light, dark in Night care), else white
/// with a hairline.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cl.colors.ink : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: selected ? null : Border.all(color: cl.colors.separator),
        ),
        child: Text(
          label,
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? cl.colors.surface : cl.colors.ink,
          ),
        ),
      ),
    );
  }
}

// ---------- 3b / 3d / 3f ----------

/// A reference milestone (by its id) or a custom record (`ms_…`): 3b until it is observed,
/// then 3d (saved) / 3f (linked to a memory).
class MilestoneDetailScreen extends ConsumerWidget {
  const MilestoneDetailScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = mtCtx(context, ref);
    if (ctx == null) return const MtPage(children: []);
    final custom = id.startsWith('ms_');
    final referenceAsync = ref.watch(referenceMilestonesProvider);
    final recordsAsync = ctx.canRecord
        ? ref.watch(milestoneRecordsProvider(ctx.babyId))
        : const AsyncValue<List<MilestoneRecord>>.data([]);
    final reference = custom
        ? null
        : referenceAsync.value?.where((m) => m.id == id).firstOrNull;
    final recordId = custom ? id : 'p_$id';
    final record = recordsAsync.value
        ?.where((r) => r.id == recordId)
        .firstOrNull;
    if (record != null && record.observed) {
      return _SavedView(ctx: ctx, record: record, reference: reference);
    }
    if (reference != null) {
      return _ReferenceView(ctx: ctx, m: reference, record: record);
    }
    final loading =
        (!custom && !referenceAsync.hasValue) ||
        (ctx.canRecord && !recordsAsync.hasValue);
    return MtPage(
      children: [
        if (loading)
          const ClSkeleton(height: 170, radius: 24)
        else
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s8),
            child: ClEmptyState(
              icon: ClIcons.star,
              title: l10n.mtNotFound,
              message: '',
            ),
          ),
      ],
    );
  }
}

/// The 3b hero: the portal's picture only. Without one there is no hero: the group's art alone
/// filled the space with nothing to read (the group chip keeps its icon). The art stays as the
/// fallback when a supplied picture fails to load.
class _Hero extends ConsumerWidget {
  const _Hero(this.m, this.lang, this.image);
  final ReferenceMilestone m;
  final String lang;
  final String image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = groupStyle(context, m.group);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 343 / 170,
          child: Semantics(
            image: true,
            label: m.illustrationAlt?.of(lang),
            child: Image(
              image: ref.watch(milestoneImageProvider)(image),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ExcludeSemantics(
                child: Container(
                  color: style.fill,
                  alignment: Alignment.center,
                  child: ClIcon(
                    style.icon,
                    size: 56,
                    color: context.cl.colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled 3b card body: the portal paragraph as short points, so it scans on a phone.
class _Points extends StatelessWidget {
  const _Points(this.text, {required this.style, required this.dot});
  final String text;
  final TextStyle style;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final chunks = readingChunks(text);
    if (chunks.length < 2) return Text(text, style: style);
    final lineHeight = (style.fontSize ?? 16) * (style.height ?? 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, t) in chunks.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: (lineHeight - 6) / 2,
                  left: 2,
                  right: 10,
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: Text(t, style: style)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReferenceView extends ConsumerStatefulWidget {
  const _ReferenceView({required this.ctx, required this.m, this.record});
  final MtCtx ctx;
  final ReferenceMilestone m;

  /// Followed ("Lưu để theo dõi"), never observed here.
  final MilestoneRecord? record;

  @override
  ConsumerState<_ReferenceView> createState() => _ReferenceViewState();
}

class _ReferenceViewState extends ConsumerState<_ReferenceView> {
  var _busy = false;

  Future<void> _toggleFollow() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final repo = ref.read(milestoneRepositoryProvider);
    final c = widget.ctx;
    final following = widget.record != null;
    setState(() => _busy = true);
    final ok = await milestoneWrite(
      following
          ? repo.remove(c.babyId, widget.m.recordId)
          : repo.follow(c.c.me, widget.m, name: widget.m.title.of(c.lang)),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    toaster.show(
      message: !ok
          ? l10n.mtSaveFailed
          : (following ? l10n.mtUnfollowed : l10n.mtFollowed),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = widget.ctx;
    final m = widget.m;
    final style = groupStyle(context, m.group);
    final rhythm =
        ref.watch(selectedCapabilitiesProvider)?.features.rhythm ?? false;
    return MtPage(
      children: [
        if (m.illustration case final image?) _Hero(m, c.lang, image),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            MtChip(
              label: groupLabel(l10n, m.group),
              fill: style.fill,
              icon: style.icon,
            ),
            MtChip(
              label: rangeChipLabel(l10n, m.ageRange),
              fill: cl.colors.surface2,
            ),
            if (widget.record != null)
              MtChip(
                label: l10n.mtFollowingTag,
                fill: cl.colors.mintSoft,
                color: cl.colors.mintText,
                icon: ClIcons.bookmark,
              ),
          ],
        ),
        const SizedBox(height: 14),
        MtTitle(m.title.of(c.lang)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mtHowTo,
                style: cl.text.bodyStrong.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _Points(
                m.howToRecognise.of(c.lang),
                style: cl.text.body,
                dot: cl.colors.mintText,
              ),
            ],
          ),
        ),
        if (m.talkToDoctor != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: cl.colors.sunshineSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ink on soft warm fills, also in Night care.
                Row(
                  children: [
                    ClIcon(ClIcons.alert, size: 18, color: cl.colors.ink),
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.mtTalkToDoctor,
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  m.talkToDoctor!.of(c.lang),
                  style: cl.text.body.copyWith(color: cl.colors.ink),
                ),
              ],
            ),
          ),
          if (rhythm)
            Align(
              alignment: Alignment.centerLeft,
              child: ClButton(
                label: l10n.mtHealthLink,
                style: ClButtonStyle.plain,
                onPressed: () => context.push(Routes.rhythmHealth),
              ),
            ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClIcon(ClIcons.heart, size: 16, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.mtReassure,
                  style: cl.text.label.copyWith(
                    color: cl.colors.inkMuted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        if (c.canRecord) ...[
          ClButton(
            label: l10n.mtMarkSeen,
            expand: true,
            onPressed: () => showRecordSheet(
              context,
              ctx: c,
              reference: m,
              record: widget.record,
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: widget.record == null ? l10n.mtFollow : l10n.mtUnfollow,
            expand: true,
            style: ClButtonStyle.plain,
            loading: _busy,
            onPressed: _toggleFollow,
          ),
        ] else
          Text(
            l10n.mtParentsRecord,
            textAlign: TextAlign.center,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        if (m.sources.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.mtSources,
            style: cl.text.caption.copyWith(
              color: cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final s in m.sources)
            Text(
              s.label,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
        ],
        MtContentNote(illustrative: m.illustrative, reviewer: m.reviewer),
      ],
    );
  }
}

/// 3d (saved) and 3f (linked to Kỷ niệm).
class _SavedView extends ConsumerWidget {
  const _SavedView({required this.ctx, required this.record, this.reference});
  final MtCtx ctx;
  final MilestoneRecord record;
  final ReferenceMilestone? reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = record;
    final group = reference?.group;
    final style = groupStyle(context, group);
    final key = (ctx.babyId, true);
    final media =
        ref.watch(completeMediaProvider(key)).value ?? const <MediaItem>[];
    final memories =
        ref.watch(completeMemoriesProvider(key)).value ?? const <Memory>[];
    final recent = ref.watch(recentMilestoneMemoriesProvider);
    final pending =
        ref.watch(pendingMilestonePhotosProvider)[r.id] ??
        const <PickedMedia>[];

    // Memories made from or tagged with this record (linked by id; nothing copied).
    bool linked(String memoryId, MilestoneRef? tag) =>
        r.memoryIds.contains(memoryId) || tag?.id == r.id;
    final linkedMemories = [
      for (final m in memories)
        if (!m.deleted && linked(m.id, m.milestone)) m,
    ];
    final photos = [
      for (final m in media)
        if (!m.deleted &&
            m.isReady &&
            m.generatedKind == null &&
            linked(m.memoryId, m.milestone))
          m,
    ];
    final arriving = [
      for (final id in r.memoryIds)
        if (recent.contains(id) && !memories.any((m) => m.id == id)) id,
    ];

    final dob = ctx.dob;
    final who = authorLabel(
      l10n,
      r.author,
      isMe: r.createdBy == ctx.c.me.uid,
      relationLabel: (rel, custom) => relationLabel(l10n, rel, custom),
    );
    final day = longDay(ctx.lang, r.date!);
    final meta = dob == null || r.date!.isBefore(dob)
        ? l10n.mtMetaNoAge(day, who)
        : l10n.mtMeta(day, ctx.nickname, ageShort(l10n, dob, r.date!), who);
    final cards = ref.watch(selectedKeepsakeAccessProvider).cards;
    final title = reference?.title.of(ctx.lang) ?? r.name;

    Widget photoTile(Widget child, VoidCallback? onTap) => Expanded(
      child: AspectRatio(
        aspectRatio: 167 / 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: onTap == null
              ? child
              : GestureDetector(onTap: onTap, child: child),
        ),
      ),
    );
    final tiles = <Widget>[
      for (final (i, m) in photos.take(2).indexed)
        photoTile(
          MediaTile(item: m, radius: 18),
          () => openViewer(context, items: photos, start: i),
        ),
      // Kept on this phone until "Tạo kỷ niệm": open the phone's copy (a photo zooms, a video
      // plays).
      for (final (i, p) in pending.take(2 - photos.take(2).length).indexed)
        photoTile(
          MtPickedImage(p, notInMemories: true),
          () => openPickedPreview(context, items: pending, start: i),
        ),
    ];

    Widget memoryRow(Memory m) {
      final items = [
        for (final i in photos)
          if (i.memoryId == m.id) i,
      ];
      final family = m.audience == Audience.family;
      final sub = items.isEmpty
          ? (family ? l10n.mtSeenByFamilyNote : l10n.mtSeenByParentsNote)
          : (family
                ? l10n.mtSeenByFamily(items.length)
                : l10n.mtSeenByParents(items.length));
      return _LinkRow(
        thumb: items.isEmpty ? null : MediaTile(item: items.first, radius: 12),
        title: l10n.mtInMemories,
        subtitle: sub,
        onTap: items.isEmpty
            ? () => context.go(Routes.memories)
            : () => openViewer(context, items: items, start: 0, memory: m),
      );
    }

    return MtPage(
      children: [
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            MtChip(
              label: l10n.mtSeen,
              fill: cl.colors.mintSoft,
              color: cl.colors.mintText,
              icon: ClIcons.check,
            ),
            MtChip(label: groupLabel(l10n, group), fill: style.fill),
          ],
        ),
        const SizedBox(height: 14),
        MtTitle(title),
        const SizedBox(height: 6),
        Text(
          meta,
          style: cl.text.body.copyWith(fontSize: 14, color: cl.colors.inkMuted),
        ),
        if (tiles.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, t) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: 9),
                t,
              ],
              if (tiles.length == 1) ...[
                const SizedBox(width: 9),
                const Spacer(),
              ],
            ],
          ),
        ],
        if (r.note != null) ...[
          const SizedBox(height: 14),
          Text(
            r.note!,
            style: cl.text.body.copyWith(fontSize: 15, height: 1.55),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        if (linkedMemories.isNotEmpty || arriving.isNotEmpty) ...[
          for (final m in linkedMemories) ...[
            memoryRow(m),
            const SizedBox(height: ClSpace.s2),
          ],
          for (final _ in arriving) ...[
            _LinkRow(
              title: l10n.mtInMemories,
              subtitle: l10n.mtUploading,
              onTap: null,
            ),
            const SizedBox(height: ClSpace.s2),
          ],
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cl.colors.peachSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ink on soft warm fills, also in Night care.
                Text(
                  l10n.mtKeepTitle,
                  style: cl.text.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cl.colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pending.isEmpty
                      ? l10n.mtKeepBodyNote(r.name)
                      : l10n.mtKeepBody(r.name),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
                const SizedBox(height: ClSpace.s3),
                ClButton(
                  label: l10n.mtCreateMemory,
                  expand: true,
                  onPressed: () =>
                      showMilestoneMemorySheet(context, ctx: ctx, record: r),
                ),
              ],
            ),
          ),
        if (cards && r.ref != null) ...[
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.mtCreateCard,
            icon: ClIcons.star,
            expand: true,
            style: ClButtonStyle.plain,
            // D-076 #14: the card library with this milestone preselected.
            onPressed: () => openMilestoneCard(
              context,
              ref,
              milestone: r.ref!,
              premium: null,
              navigate: (location, extra) =>
                  context.push(location, extra: extra),
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClButton(
              label: l10n.mtEdit,
              style: ClButtonStyle.plain,
              onPressed: () => showRecordSheet(
                context,
                ctx: ctx,
                reference: reference,
                record: r,
              ),
            ),
            ClButton(
              label: l10n.mtDelete,
              style: ClButtonStyle.plain,
              onPressed: () => _remove(context, ref),
            ),
          ],
        ),
        if (reference != null)
          MtContentNote(
            illustrative: reference!.illustrative,
            reviewer: reference!.reviewer,
          ),
      ],
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    if (!await confirmRemoveRecord(context) || !context.mounted) return;
    final router = GoRouter.of(context);
    final ok = await milestoneWrite(
      ref.read(milestoneRepositoryProvider).remove(ctx.babyId, record.id),
    );
    ref.read(pendingMilestonePhotosProvider.notifier).clear(record.id);
    toaster.show(message: ok ? l10n.mtDeleted : l10n.mtSaveFailed, error: !ok);
    // A custom record has no page without it; a reference one goes back to 3b.
    if (ok && record.kind == RecordKind.custom && router.canPop()) {
      router.pop();
    }
  }
}

/// 3f: "Đã lưu trong Kỷ niệm · Cả gia đình xem được · 2 ảnh".
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.thumb,
  });
  final Widget? thumb;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child:
                thumb ??
                Container(
                  decoration: BoxDecoration(
                    color: cl.colors.peachSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    ClIcons.memories,
                    size: 20,
                    color: cl.colors.ink,
                  ),
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          if (onTap != null)
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
        ],
      ),
    );
    return onTap == null
        ? Semantics(
            label: '$title. $subtitle',
            child: ExcludeSemantics(child: row),
          )
        : ClPressable(
            onPressed: onTap,
            semanticLabel: '$title. $subtitle',
            child: row,
          );
  }
}

// ---------- 3g Tạo mốc riêng ----------

class OwnMilestoneScreen extends ConsumerStatefulWidget {
  const OwnMilestoneScreen({super.key});

  @override
  ConsumerState<OwnMilestoneScreen> createState() => _OwnState();
}

class _OwnState extends ConsumerState<OwnMilestoneScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  DateTime? _date;
  var _photos = <PickedMedia>[];
  var _alsoMemory = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(MtCtx c) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final date = _date ?? c.today;
    setState(() => _busy = true);
    final repo = ref.read(milestoneRepositoryProvider);
    String? id;
    try {
      id = await repo
          .createCustom(c.c.me, name: name, date: date, note: _note.text)
          .timeout(const Duration(seconds: 4));
    } on Object {
      id = null;
    }
    if (!mounted) return;
    if (id == null) {
      setState(() => _busy = false);
      toaster.show(message: l10n.mtSaveFailed, error: true);
      return;
    }
    if (_alsoMemory) {
      final ref0 = MilestoneRef(id: id, name: name, date: date);
      final note = _note.text.trim();
      final memoryId = await createMilestoneMemory(
        ref,
        babyId: c.babyId,
        milestone: ref0,
        caption: note.isEmpty ? name : note,
        audience: Audience.family, // D-001 (3g has no audience choice)
        photos: _photos,
      );
      ref.read(recentMilestoneMemoriesProvider.notifier).add(memoryId);
      unawaited(
        milestoneWrite(
          repo.linkMemory(
            c.c.me,
            MilestoneRecord(
              id: id,
              kind: RecordKind.custom,
              name: name,
              status: RecordStatus.observed,
              date: date,
              note: note.isEmpty ? null : note,
              author: CareAuthor.of(c.c.me),
              createdBy: c.c.me.uid,
              source: RecordSource.milestones,
            ),
            memoryId,
          ),
        ),
      );
    } else if (_photos.isNotEmpty) {
      ref.read(pendingMilestonePhotosProvider.notifier).set(id, _photos);
    }
    if (!mounted) return;
    toaster.show(message: _alsoMemory ? l10n.mtMemoryCreated : l10n.mtSaved);
    unawaited(router.pushReplacement(milestoneLocation(id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = mtCtx(context, ref);
    if (c == null || !c.canRecord) {
      return const MtPage(close: true, children: []);
    }
    final date = _date ?? c.today;
    return MtPage(
      close: true,
      bottom: ClButton(
        label: l10n.mtSave,
        expand: true,
        loading: _busy,
        onPressed: _name.text.trim().isEmpty ? null : () => _save(c),
      ),
      children: [
        MtTitle(l10n.mtOwn),
        const SizedBox(height: 6),
        Text(
          l10n.mtOwnLead,
          style: cl.text.body.copyWith(
            fontSize: 14,
            color: cl.colors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClTextField(
          label: l10n.mtName,
          placeholder: l10n.mtNameHint,
          controller: _name,
          standalone: true,
          maxLength: MilestoneLimits.nameMax,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.mtCount(_name.text.length, MilestoneLimits.nameMax),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        MtDateField(
          label: l10n.mtDate,
          value: longDay(c.lang, date),
          onTap: () async {
            final today = c.today;
            final picked = await pickMilestoneDay(
              context,
              initial: date,
              first: c.dob ?? DateTime(today.year - 3, today.month, today.day),
              last: today,
            );
            if (picked != null && mounted) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: ClSpace.s3),
        ClTextField(
          label: l10n.mtNote,
          placeholder: l10n.mtNoteHint,
          controller: _note,
          standalone: true,
          maxLines: 4,
          maxLength: MilestoneLimits.noteMax,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: ClSpace.s3),
        MtPhotoStrip(
          photos: _photos,
          onAdd: () async {
            final more = await pickMilestonePhotos(context, ref);
            if (more.isNotEmpty && mounted) {
              setState(() => _photos = [..._photos, ...more]);
            }
          },
          onRemove: (i) => setState(() => _photos = [..._photos]..removeAt(i)),
        ),
        const SizedBox(height: ClSpace.s3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mtAlsoMemory,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.mtAlsoMemorySub,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClToggle(
                  value: _alsoMemory,
                  onChanged: (v) => setState(() => _alsoMemory = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
