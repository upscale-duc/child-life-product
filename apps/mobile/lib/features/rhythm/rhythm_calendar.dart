import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart' show careClockProvider;
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// The reference layer of Nhịp lớn lên (indigo, `care-sleep`): a published, versioned model
/// counted from the due date, free in every plan (D-072 #7: "Giai đoạn N (Wonder Weeks)", a
/// reference, never a partner). Windows are possibilities; nothing is inferred from them.

/// NL01 / NL01b "LỊCH THAM KHẢO" card.
class ReferenceCalendarCard extends ConsumerWidget {
  const ReferenceCalendarCard({
    required this.me,
    required this.today,
    required this.babyName,
    super.key,
  });

  final Membership me;
  final String today;
  final String babyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final sleep = cl.care.sleep;
    final reference = ref.watch(rhythmReferenceProvider);
    final model = reference.value;
    final profile = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId))
        : null;
    final due = profile?.value?.dueDate;
    final canSetup = familyCan(me, FamilyAction.rhythmSetup);

    Widget card({
      required List<Widget> children,
      bool unset = false,
      VoidCallback? onTap,
      String? semantics,
    }) => RhCard(
      color: sleep.soft,
      onTap: onTap,
      semanticLabel: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RhLayerPill(
                    label: unset
                        ? l10n.rhCalendarUnsetPill
                        : l10n.rhCalendarPill,
                  ),
                ),
              ),
              if (!unset && due != null && model != null) ...[
                const SizedBox(width: ClSpace.s2),
                ClPressable(
                  semanticLabel: l10n.rhSeeCalendar,
                  onPressed: () => context.push(Routes.rhythmCalendar),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: ClSpace.tapMin,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        l10n.rhSeeCalendar,
                        style: cl.text.label.copyWith(
                          color: sleep.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          ...children,
        ],
      ),
    );

    Text body(String text) =>
        Text(text, style: cl.text.label.copyWith(color: cl.colors.ink));

    if (reference.isLoading || (profile?.isLoading ?? false)) {
      return const ClSkeleton(height: 120);
    }
    if (model == null) return card(children: [body(l10n.rhCalendarNoModel)]);
    if (!me.canViewBabyInfo) {
      return card(children: [body(l10n.rhCalendarNoAccess)]);
    }
    if (due == null) {
      return card(
        unset: true,
        children: [
          Text(
            l10n.rhCalendarUnsetTitle,
            style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
          ),
          const SizedBox(height: ClSpace.s1),
          body(l10n.rhCalendarUnsetBody(babyName)),
          const SizedBox(height: ClSpace.s3),
          if (canSetup)
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                RhPillButton(
                  label: l10n.rhAddDueDate,
                  onTap: () => context.push(Routes.rhythmDueDate),
                ),
                RhPillButton(
                  label: l10n.rhDontRemember,
                  primary: false,
                  onCard: true,
                  onTap: () =>
                      context.push('${Routes.rhythmDueDate}?estimate=1'),
                ),
              ],
            )
          else
            Text(
              l10n.rhCalendarUnsetOthers,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
        ],
      );
    }

    final stages = currentStages(due.date, today, model.stages);
    final focus = stages.current.firstOrNull ?? stages.next;
    final lines = <Widget>[];
    // Owner, 2026-10-22: where the baby is in the window, as a bar with its two dates and the
    // days left, instead of sentences.
    Widget window(StageWindow w) {
      final total = daysBetweenIso(w.start, w.end) + 1;
      final day = (daysBetweenIso(w.start, today) + 1).clamp(1, total);
      final left = total - day;
      return ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: day / total,
                minHeight: 8,
                color: sleep.ink,
                backgroundColor: cl.colors.surface,
              ),
            ),
            const SizedBox(height: ClSpace.s1),
            Row(
              children: [
                Text(
                  shortDay(locale, w.start),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                Expanded(
                  child: Text(
                    left == 0
                        ? l10n.rhStageLastDay
                        : l10n.rhStageDaysLeft(left),
                    textAlign: TextAlign.center,
                    style: cl.text.caption.copyWith(
                      color: sleep.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  shortDay(locale, w.end),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (stages.current.isNotEmpty) {
      for (final s in stages.current) {
        lines.addAll([
          Text(
            l10n.rhStageInN(s.number),
            style: cl.text.headline.copyWith(color: cl.colors.ink),
          ),
          const SizedBox(height: ClSpace.s3),
          window(windowOf(due.date, s)),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
    } else if (stages.next case final s?) {
      lines.addAll([
        Text(
          l10n.rhStageComingN(s.number),
          style: cl.text.headline.copyWith(color: cl.colors.ink),
        ),
        const SizedBox(height: 2),
        body(
          l10n.rhStageExpectedLine(
            stageRange(l10n, locale, due.date, s),
            daysBetweenIso(today, windowOf(due.date, s).start),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
      ]);
    } else {
      lines.addAll([
        Text(
          l10n.rhStagesDone,
          style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
        ),
        const SizedBox(height: ClSpace.s2),
      ]);
    }
    final sorted = [...model.stages]
      ..sort((a, b) => a.startOffsetDays.compareTo(b.startOffsetDays));
    return card(
      onTap: focus == null
          ? () => context.push(Routes.rhythmCalendar)
          : () => context.push('${Routes.rhythmCalendar}/${focus.id}'),
      semantics: focus == null
          ? l10n.rhStagesDone
          : (stages.current.isNotEmpty
                ? l10n.rhStageInN(focus.number)
                : l10n.rhStageComingN(focus.number)),
      children: [
        ...lines,
        if (stages.current.isEmpty) ...[
          // One bar per stage; the one coming next is filled.
          ExcludeSemantics(
            child: Row(
              children: [
                for (final (i, s) in sorted.take(10).indexed) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: s.id == focus?.id
                            ? sleep.ink
                            : cl.colors.surface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        // The basis and the reminder that it is a reference, in one quiet line.
        Text(
          [
            due.estimated
                ? l10n.rhByDueDateEstimated(shortDay(locale, due.date))
                : l10n.rhByDueDate(shortDay(locale, due.date)),
            l10n.rhCalendarDisclaimerShort,
          ].join(' · '),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// Today in the baby's zone (the care clock, tests pin it) and the profile of the selected baby.
({Membership? me, String today, String name, RhythmProfile? profile}) _context(
  WidgetRef ref,
) {
  final me = ref.watch(selectedMembershipProvider);
  final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  return (
    me: me,
    today: babyTodayIso(zone, now),
    name: baby?.nickname ?? '',
    profile: me != null && me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value
        : null,
  );
}

Widget _backBar(BuildContext context) => Align(
  alignment: Alignment.centerLeft,
  child: RhRoundIcon(
    icon: ClIcons.back,
    label: AppLocalizations.of(context).a11yBack,
    onPressed: () => leaveRhythm(context),
  ),
);

/// NL03 (571:1054) "Lịch tham khảo": every stage of the published model as a dated window from
/// the due date, today's place among them, overlaps said out loud, the model version and its
/// review label. "Đổi" edits the due date (Cùng nuôi).
class ReferenceCalendarScreen extends ConsumerWidget {
  const ReferenceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final c = _context(ref);
    final model = ref.watch(rhythmReferenceProvider).value;
    final due = c.profile?.dueDate;
    final canSetup = c.me != null && familyCan(c.me!, FamilyAction.rhythmSetup);
    final sleep = cl.care.sleep;

    final content = <Widget>[
      Semantics(
        header: true,
        child: Text(l10n.rhLayerCalendarTitle, style: cl.text.title2),
      ),
      const SizedBox(height: ClSpace.s2),
    ];
    if (model == null || due == null) {
      content.add(
        RhCard(
          color: sleep.soft,
          child: Text(
            model == null ? l10n.rhCalendarNoModel : l10n.rhCalendarUnsetTitle,
            style: cl.text.label.copyWith(color: cl.colors.ink),
          ),
        ),
      );
      if (model != null && canSetup) {
        content.addAll([
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l10n.rhAddDueDate,
            expand: true,
            onPressed: () => context.push(Routes.rhythmDueDate),
          ),
        ]);
      }
      return OnboardingScaffold(topBar: _backBar(context), content: content);
    }

    final sorted = [...model.stages]
      ..sort((a, b) => a.startOffsetDays.compareTo(b.startOffsetDays));
    final stages = currentStages(due.date, c.today, sorted);
    final focus = stages.current.firstOrNull ?? stages.next;
    final todayLine = stages.current.isNotEmpty
        ? l10n.rhTodayIn(shortDay(locale, c.today), stages.current.first.number)
        : stages.next != null
        ? l10n.rhTodayBefore(shortDay(locale, c.today), stages.next!.number)
        : l10n.rhTodayPlain(shortDay(locale, c.today));
    final label = model.label.isEmpty ? 'Wonder Weeks' : model.label;

    content.addAll([
      Row(
        children: [
          Expanded(
            child: Text(
              due.estimated
                  ? l10n.rhCalendarBasisEstimated(
                      label,
                      shortDay(locale, due.date),
                    )
                  : l10n.rhCalendarBasis(label, shortDay(locale, due.date)),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          if (canSetup)
            RhLink(
              label: l10n.rhChange,
              onTap: () => context.push(Routes.rhythmDueDate),
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s2),
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cl.colors.mintDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              todayLine,
              style: cl.text.label.copyWith(
                color: cl.colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: ClSpace.s3),
    ]);

    for (final (i, s) in sorted.indexed) {
      final state = stageState(due.date, c.today, s);
      final next = i + 1 < sorted.length ? sorted[i + 1] : null;
      final overlaps =
          next != null &&
          next.startOffsetDays <= s.endOffsetDays &&
          next.endOffsetDays >= s.startOffsetDays;
      final highlighted = s.id == focus?.id;
      final status = switch (state) {
        CalendarState.upcoming => l10n.rhStageUpcoming(
          daysBetweenIso(c.today, windowOf(due.date, s).start),
        ),
        CalendarState.inReferenceWindow => l10n.rhStageCurrent,
        _ => l10n.rhStagePast,
      };
      content.add(
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: ClSpace.s3),
                decoration: BoxDecoration(
                  color: highlighted ? sleep.ink : cl.colors.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${s.number}',
                  style: cl.text.caption.copyWith(
                    color: highlighted ? sleep.soft : cl.colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: RhCard(
                  color: highlighted ? sleep.soft : null,
                  hairline: !highlighted,
                  padding: const EdgeInsets.all(ClSpace.s3),
                  onTap: () => context.push('${Routes.rhythmCalendar}/${s.id}'),
                  semanticLabel:
                      '${l10n.rhStageName(s.number)}. ${stageRange(l10n, locale, due.date, s)}. $status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.rhStageShort(s.number),
                              style: cl.text.bodyStrong.copyWith(
                                color: cl.colors.ink,
                              ),
                            ),
                          ),
                          Text(
                            stageRange(l10n, locale, due.date, s),
                            style: cl.text.label.copyWith(color: cl.colors.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: cl.text.caption.copyWith(
                          color: highlighted ? sleep.ink : cl.colors.inkMuted,
                          fontWeight: highlighted ? FontWeight.w600 : null,
                        ),
                      ),
                      if (overlaps) ...[
                        const SizedBox(height: ClSpace.s1),
                        Text(
                          l10n.rhStagesOverlap(s.number, next.number),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    content.addAll([
      const SizedBox(height: ClSpace.s2),
      Text(
        l10n.rhCalendarNote,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s1),
      RhReviewNote(model.review),
      const SizedBox(height: ClSpace.s1),
      Text(
        l10n.rhNotPartner(label),
        style: cl.text.caption.copyWith(
          color: cl.colors.inkMuted,
          fontSize: 11,
        ),
      ),
    ]);
    return OnboardingScaffold(topBar: _backBar(context), content: content);
  }
}

/// NL04 (571:1158): one stage — the expected window ("có thể không trùng với trải nghiệm của
/// Teddy"), signs as possibilities, skills by age (not tied to the window), linked activities
/// (→ AC01), sources and the review label. "Ghi nhận hôm nay" opens C01; "Con vẫn như mọi
/// ngày" saves a usual check-in quietly.
class StageDetailScreen extends ConsumerWidget {
  const StageDetailScreen({required this.stageId, super.key});
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final c = _context(ref);
    final me = c.me;
    if (me != null) watchRhythmClock(ref, me.babyId);
    final model = ref.watch(rhythmReferenceProvider).value;
    final content = ref.watch(rhythmContentProvider).value;
    final stage = model?.stages.where((s) => s.id == stageId).firstOrNull;
    final due = c.profile?.dueDate;
    final sleep = cl.care.sleep;
    if (stage == null) {
      return OnboardingScaffold(
        topBar: _backBar(context),
        content: [
          if (model != null)
            RhCard(child: Text(l10n.rhStageMissing, style: cl.text.bodyStrong)),
        ],
      );
    }
    final signs = stage.signs.of(locale);
    final skills = stage.skills.of(locale);
    final activities = [
      for (final id in stage.activityIds)
        if (content?.activity(id) case final a?
            when a.status == ContentStatus.published)
          a,
    ];
    final canCheckIn = me != null && familyCan(me, FamilyAction.rhythmCheckin);

    Widget section(
      String title,
      ClIcons icon,
      List<String> items,
      String? foot,
    ) => RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RhCardHeading(title),
          const SizedBox(height: ClSpace.s2),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: ClSpace.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ClIcon(icon, size: 14, color: cl.colors.mintText),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(child: Text(item, style: cl.text.label)),
                ],
              ),
            ),
          if (foot != null) ...[
            const SizedBox(height: ClSpace.s2),
            Text(
              foot,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ],
      ),
    );

    return OnboardingScaffold(
      topBar: _backBar(context),
      content: [
        RhCard(
          color: sleep.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RhLayerPill(label: l10n.rhCalendarPill),
              const SizedBox(height: ClSpace.s2),
              Semantics(
                header: true,
                child: Text(
                  l10n.rhStageName(stage.number),
                  style: cl.text.title2.copyWith(
                    fontSize: 22,
                    color: cl.colors.ink,
                  ),
                ),
              ),
              if (stage.name.of(locale).isNotEmpty &&
                  stage.name.of(locale) != l10n.rhStageShort(stage.number)) ...[
                const SizedBox(height: 2),
                Text(
                  stage.name.of(locale),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ],
              if (due != null) ...[
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.rhStageDetailExpected(
                    stageRange(l10n, locale, due.date, stage),
                    c.name,
                  ),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ],
            ],
          ),
        ),
        if (stage.noticeBody != null) ...[
          const SizedBox(height: ClSpace.s3),
          RhInfoBox(
            icon: ClIcons.bell,
            label: stage.noticeTitle?.of(locale),
            text: stage.noticeBody!.of(locale),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        section(l10n.rhSignsTitle, ClIcons.eye, [...signs], l10n.rhSignsNormal),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          section(l10n.rhSkillsTitle, ClIcons.star, skills, l10n.rhSkillsNote),
        ],
        if (activities.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          RhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RhCardHeading(l10n.rhActivitiesTitle),
                for (final a in activities)
                  ClPressable(
                    onPressed: () => context.push(activityLocation(a.id)),
                    pressedOpacity: ClPressable.surfaceOpacity,
                    semanticLabel: a.title.of(locale),
                    child: Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s3),
                      child: Row(
                        children: [
                          RhIconTile(icon: activityIcon(a), size: 36),
                          const SizedBox(width: ClSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title.of(locale),
                                  style: cl.text.label.copyWith(
                                    color: cl.colors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  durationLabel(l10n, a.durationMin),
                                  style: cl.text.caption.copyWith(
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                              ],
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
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.rhSourcesReview,
                style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: ClSpace.s1),
              RhReviewNote(model!.review),
              // D-116: the model version is for staff (portal), not parents.
              if (model.sources.isNotEmpty)
                Text(
                  [for (final s in model.sources) s.label].join(' · '),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              Text(
                l10n.rhNotPartner(
                  model.label.isEmpty ? 'Wonder Weeks' : model.label,
                ),
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
      bottom: canCheckIn
          ? [
              ClButton(
                label: l10n.rhRecordToday,
                expand: true,
                onPressed: () => context.push(Routes.rhythmCheckIn),
              ),
              const SizedBox(height: ClSpace.s2),
              ClButton(
                label: l10n.rhSameAsUsual,
                expand: true,
                style: ClButtonStyle.secondary,
                onPressed: () {
                  final toaster = ClToaster.of(context);
                  saveCheckIn(
                    context,
                    ref,
                    newCheckIn(ref, me, Observation.usual),
                  );
                  toaster.show(message: l10n.rhUsualSaved);
                  leaveRhythm(context);
                },
              ),
            ]
          : null,
    );
  }
}
