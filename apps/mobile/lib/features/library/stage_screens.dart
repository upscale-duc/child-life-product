import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart' show SafePushContext;
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../premium/premium_repository.dart';
import '../rhythm/rhythm_calc.dart' show ageCardFor, cardAgeDays;
import '../rhythm/rhythm_repository.dart'
    show rhythmContentProvider, rhythmProfileProvider;
import '../care/care_repository.dart' show onlineProvider;
import 'content_calc.dart';
import 'content_models.dart';
import 'content_repository.dart';
import 'library_routes.dart';
import 'library_widgets.dart';
import '../milestones/milestone_repository.dart'
    show referenceMilestonesProvider;

/// Giai đoạn của bé (Figma v1.1 2a list, 2b detail, 2c missing date of birth; D-076 #5 renamed
/// "Thẻ theo tuổi", which the app never says). Stages are editorial (`contentStages`), shown to
/// the roles in their audience; the current one follows the selected baby's date of birth.
///
/// "Tuần này của {bé}" (Nhịp lớn lên H01, D-072 #5 / Q-067) is the week card on Hôm nay; this is
/// the whole age catalogue to read back and ahead. They link to each other instead of repeating:
/// the current stage's detail opens that week card when Nhịp lớn lên has one.

/// The stages this member may see, ordered by age.
List<LbStage> lbVisibleStages(LbFeed<LbStage>? feed, LbBaby? baby) =>
    lbSortStages([
      for (final s in feed?.items ?? const <LbStage>[])
        if (baby == null || s.audience.contains(baby.role)) s,
    ]);

// ---------- 2c Thiếu ngày sinh ----------

/// "Thêm ngày sinh của bé" (2c). A Cùng nuôi opens the profile; anyone else, who may not see
/// the date of birth, is told why no stage is marked (and can still read every stage).
class LbMissingDobCard extends StatelessWidget {
  const LbMissingDobCard({required this.baby, super.key});
  final LbBaby baby;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return LbCard(
      key: const Key('lbNoDob'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cl.colors.sunshineSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                // Ink on soft warm fills, also in Night care.
                child: ClIcon(ClIcons.cake, size: 18, color: cl.colors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baby.canAddDob
                          ? l10n.lbNoDobTitle
                          : l10n.lbNoDobViewerTitle,
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      baby.canAddDob
                          ? l10n.lbNoDobBody
                          : l10n.lbNoDobViewer(baby.name),
                      style: cl.text.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (baby.canAddDob) ...[
            const SizedBox(height: 12),
            ClButton(
              key: const Key('lbAddDob'),
              label: l10n.lbNoDobAction,
              style: ClButtonStyle.tinted,
              expand: true,
              onPressed: () =>
                  context.push('${Routes.babyEdit}/${baby.babyId}'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 2a Giai đoạn của bé ----------

class StagesScreen extends ConsumerStatefulWidget {
  const StagesScreen({super.key});

  @override
  ConsumerState<StagesScreen> createState() => _StagesScreenState();
}

class _StagesScreenState extends ConsumerState<StagesScreen> {
  final _current = GlobalKey();
  bool _scrolled = false;

  void _scrollToCurrent() {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _current.currentContext;
      if (ctx != null && ctx.mounted) {
        // Only when it is below the fold: the title stays when the row is already visible.
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final feed = ref.watch(lbStagesProvider);
    final baby = ref.watch(lbBabyProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final stages = lbVisibleStages(feed.value, baby);
    final dob = baby?.dob;
    final current = dob == null ? null : lbStageFor(stages, dob, baby!.today);
    if (current != null) _scrollToCurrent();

    return LbPage(
      children: [
        LbTitle(l10n.lbStagesTitle),
        const SizedBox(height: 6),
        Text(
          l10n.lbStagesIntro,
          style: cl.text.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: cl.colors.inkMuted,
          ),
        ),
        LbOfflineNote(l10n.lbOfflineStages, top: ClSpace.s3),
        if (baby != null && dob == null) ...[
          const SizedBox(height: 14),
          LbMissingDobCard(baby: baby),
        ],
        const SizedBox(height: 14),
        if (feed.isLoading && stages.isEmpty)
          const SizedBox(height: 120)
        else if (stages.isEmpty)
          LbEmpty(
            icon: online ? ClIcons.cake : ClIcons.cloudOff,
            title: online ? l10n.lbStagesEmptyTitle : l10n.lbEmptyOfflineTitle,
            body: online ? l10n.lbStagesEmptyBody : l10n.lbEmptyOfflineBody,
          )
        else
          for (final (i, s) in stages.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _StageRow(
              key: s == current ? _current : Key('lbStage_${s.id}'),
              stage: s,
              time: dob == null
                  ? LbStageTime.future
                  : lbStageTime(s, current, dob, baby!.today),
            ),
          ],
      ],
    );
  }
}

/// 2a row: picture 52 · range (+ "Bé đang ở đây") · title · chevron. The current stage is
/// sunshine-soft with a sunshine border; past stages are muted (still open).
class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.time, super.key});
  final LbStage stage;
  final LbStageTime time;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final current = time == LbStageTime.current;
    final range = lbStageLabel(l10n, stage.age);
    final title = stage.title.of(context);
    return ClPressable(
      onPressed: () => context.push(LbRoutes.stage(stage.id)),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [range, if (current) l10n.lbHere, title].join('. '),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: current ? cl.colors.sunshineSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: current
              ? Border.all(color: cl.colors.sunshine, width: 1.5)
              : Border.all(color: cl.colors.separator),
        ),
        child: Row(
          children: [
            LbPicture(
              image: stage.cover?.id,
              width: 52,
              height: 52,
              radius: 14,
              topic: LbTopic.development,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        range,
                        style: cl.text.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          // Ink on soft warm fills, also in Night care.
                          color: current ? cl.colors.ink : cl.colors.inkMuted,
                        ),
                      ),
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cl.colors.surface,
                            borderRadius: BorderRadius.circular(ClRadius.pill),
                          ),
                          child: Text(
                            l10n.lbHere,
                            style: cl.text.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cl.colors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: time == LbStageTime.past
                          ? cl.colors.inkMuted
                          : cl.colors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClIcon(
              ClIcons.chevronRight,
              size: 16,
              color: current ? cl.colors.ink : cl.colors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 2b Chi tiết giai đoạn ----------

/// A route to a reference milestone (`contentMilestones/{id}`), from Mốc phát triển (D-076 #6):
/// its title in the app's language and its page (3b / 3d). Unpublished ids are left out; until
/// the published list has loaded the "Mốc thường gặp" section stays hidden.
final lbMilestoneLinkProvider = Provider<LbMilestoneLink?>((ref) {
  final published = ref.watch(referenceMilestonesProvider).value;
  if (published == null) return null;
  final byId = {for (final m in published) m.id: m};
  return (context, id) {
    final m = byId[id];
    if (m == null) return null;
    return (
      title: m.title.of(Localizations.localeOf(context).languageCode),
      route: '${Routes.milestones}/${m.id}',
    );
  };
});

/// Title and route of a milestone, or null when it is not available.
typedef LbMilestoneLink =
    ({String title, String route})? Function(BuildContext context, String id);

class StageDetailScreen extends ConsumerWidget {
  const StageDetailScreen({required this.stageId, super.key});
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final feed = ref.watch(lbStagesProvider);
    final baby = ref.watch(lbBabyProvider);
    final stages = lbVisibleStages(feed.value, baby);
    final stage = stages.where((s) => s.id == stageId).firstOrNull;
    if (stage == null) {
      return LbPage(
        children: [
          if (!feed.isLoading)
            LbEmpty(
              icon: ClIcons.cake,
              title: l10n.lbStageMissing,
              body: l10n.lbStageMissingBody,
            ),
        ],
      );
    }
    final dob = baby?.dob;
    final current = dob == null ? null : lbStageFor(stages, dob, baby!.today);
    final isCurrent = current?.id == stage.id;
    final ageLabel = lbAgeLabel(l10n, baby);
    final articles = ref.watch(lbArticlesProvider).value?.items ?? const [];
    final related = [
      for (final id in stage.articleIds)
        ?articles.where((a) => a.id == id).firstOrNull,
    ];
    final milestoneLink = ref.watch(lbMilestoneLinkProvider);
    final milestones = milestoneLink == null
        ? const <({String title, String route})>[]
        : [for (final id in stage.milestoneIds) ?milestoneLink(context, id)];

    // "Tuần này của {bé}" (Nhịp lớn lên) for the current stage, when that feature is on.
    String? weekCard;
    if (isCurrent &&
        (ref.watch(selectedCapabilitiesProvider)?.features.rhythm ?? false)) {
      final content = ref.watch(rhythmContentProvider).value;
      weekCard = content == null
          ? null
          : ageCardFor(
              content.ageCards,
              cardAgeDays(
                dob!,
                ref
                    .watch(rhythmProfileProvider(baby!.babyId))
                    .value
                    ?.dueDate
                    ?.date,
                baby.today,
              ),
            )?.id;
    }

    final doing = stage.doing.pick(locale);
    final tryThis = stage.tryThis.pick(locale);

    return LbPage(
      children: [
        if (stage.cover != null) ...[
          LbPicture(
            image: stage.cover!.id,
            alt: stage.cover!.alt?.of(context),
            width: double.infinity,
            height: 180,
            radius: 24,
            topic: LbTopic.development,
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LbChip(
              lbStageLabel(l10n, stage.age),
              fill: cl.colors.sunshineSoft,
              // Ink on soft warm fills, also in Night care.
              ink: cl.colors.ink,
            ),
            if (isCurrent && ageLabel != null)
              LbChip('${baby!.name} · $ageLabel'),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(
            stage.title.of(context),
            style: cl.text.largeTitle.copyWith(fontSize: 26, height: 1.25),
          ),
        ),
        if (doing.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          LbCard(
            key: const Key('lbDoing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(l10n.lbDoing),
                const SizedBox(height: 10),
                LbPoints(
                  items: doing,
                  icon: ClIcons.eye,
                  color: cl.care.sleep.ink,
                ),
              ],
            ),
          ),
        ],
        if (tryThis.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          LbCard(
            key: const Key('lbTry'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(l10n.lbTry),
                const SizedBox(height: 10),
                LbPoints(
                  items: tryThis,
                  icon: ClIcons.heart,
                  color: cl.care.sleep.ink,
                ),
              ],
            ),
          ),
        ],
        if (weekCard != null) ...[
          const SizedBox(height: ClSpace.s4),
          ClPressable(
            key: const Key('lbWeekCard'),
            onPressed: () => context.push('${Routes.rhythmAge}/$weekCard'),
            pressedOpacity: ClPressable.surfaceOpacity,
            semanticLabel: l10n.rhAgeHeading(baby!.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClIcon(ClIcons.today, size: 18, color: cl.colors.mintText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rhAgeHeading(baby.name),
                          style: cl.text.bodyStrong.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cl.colors.mintText,
                          ),
                        ),
                        Text(
                          l10n.lbWeekCardSub,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.mintText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClIcon(
                    ClIcons.chevronRight,
                    size: 16,
                    color: cl.colors.mintText,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (milestones.isNotEmpty) ...[
          LbSection(l10n.lbMilestones),
          LbGroup(
            children: [
              for (final m in milestones)
                ClPressable(
                  // D-076 nav: 2b is above the tabs; a milestone is a Tiện ích page.
                  onPressed: () => context.pushSafe(m.route),
                  pressedOpacity: ClPressable.surfaceOpacity,
                  semanticLabel: m.title,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cl.colors.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClIcon(
                            ClIcons.star,
                            size: 16,
                            color: cl.colors.mintText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.title,
                            style: cl.text.bodyStrong.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ClIcon(
                          ClIcons.chevronRight,
                          size: 16,
                          color: cl.colors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (related.isNotEmpty) ...[
          LbSection(l10n.lbRelated),
          LbGroup(
            children: [
              for (final a in related)
                LbArticleRow(
                  key: Key('lbStageArticle_${a.id}'),
                  article: a,
                  thumb: 56,
                  meta: lbMeta(l10n, a),
                  onTap: () => context.push(LbRoutes.articleOf(a.id)),
                ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          [
            if (stage.review != null && !stage.illustrative)
              lbReviewLabel(l10n, stage.review!),
            l10n.lbStageFootnote,
            // D-082: a footnote, not a badge, until an expert signs the stage.
            if (stage.illustrative) l10n.lbIllustrative,
          ].join(' · '),
          style: cl.text.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: cl.colors.inkMuted,
          ),
        ),
        if (stage.sources.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.lbSources}: ${stage.sources.map((s) => s.label).join(' · ')}',
            style: cl.text.caption.copyWith(
              fontSize: 11,
              color: cl.colors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: context.cl.text.headline.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
