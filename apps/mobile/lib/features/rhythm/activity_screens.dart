import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_widgets.dart';
import '../baby/baby_repository.dart' show babyProvider;
import '../care/care_format.dart' show durationLabel;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import 'preferences_screens.dart' show fewerLikeThis;
import 'personalization_v2_screen.dart' show askTryReminder;
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_plans.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// AC01 (590:6515): an activity not tried yet — steps, why it may help, safety, the review label,
/// "Mình sẽ thử" (started), "Không phù hợp với con" (not_suitable: never suggested again for
/// this baby) and "Gợi ý khác" (not_today: a cooldown). "Mình sẽ thử" is a plan (D-076 #10): it
/// waits ("Đã lên kế hoạch · tối nay", "Bỏ kế hoạch" for its author) and offers AC02 only once
/// there was a chance to try, with "Chưa thử" next to it. Members who may only read (relatives
/// with "Chăm sóc hằng ngày") see it without the actions.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({required this.contentId, this.checkInId, super.key});
  final String contentId;

  /// The check-in the suggestion rests on ("Vì: … (Ba ghi 07/10)").
  final String? checkInId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final content = ref.watch(rhythmContentProvider);
    final activity = content.value?.activity(contentId);
    if (me != null) watchRhythmClock(ref, me.babyId);
    final canRead = me != null && familyCan(me, FamilyAction.historyRead);
    final canAct = me != null && familyCan(me, FamilyAction.rhythmFeedback);
    final feedback = canRead
        ? ref.watch(recFeedbackProvider(me.babyId)).value ??
              const <RecFeedback>[]
        : const <RecFeedback>[];
    final last = latestFeedback(feedback, contentId);
    final zone =
        (me == null ? null : ref.watch(babyProvider(me.babyId)).value)
            ?.timeZone
            .zone ??
        'Asia/Ho_Chi_Minh';
    final now = rhythmNow(ref);
    final today = babyTodayIso(zone, now);
    final plan = me == null || activity == null
        ? null
        : openPlan(
            feedback,
            contentId,
            zone: zone,
            timeOfDay: activity.timeOfDay,
            now: now,
            setAside: ref.watch(plansSetAsideProvider(setAsideKey(me))),
          );
    final answered =
        last != null &&
        (last.kind == FeedbackKind.helpful || last.kind == FeedbackKind.unsure);
    final checkIn = canRead && checkInId != null
        ? ref
              .watch(checkInsProvider(me.babyId))
              .value
              ?.where((c) => c.id == checkInId)
              .firstOrNull
        : null;
    final members = me == null
        ? const []
        : ref.watch(familyMembersProvider(me.babyId)).value ?? const [];

    final topBar = Row(
      children: [
        RhRoundIcon(
          icon: ClIcons.close,
          label: l10n.a11yClose,
          onPressed: () => leaveRhythm(context),
        ),
        const Spacer(),
        // A plan shows once, in its card below (owner, 2026-10-25: no status said twice).
        if (activity != null && plan == null)
          if (answered)
            RhPill(
              label: l10n.rhTriedOn(shortDay(locale, last.date)),
              icon: ClIcons.check,
              mint: true,
            ),
      ],
    );
    if (activity == null) {
      return OnboardingScaffold(
        topBar: topBar,
        content: [
          if (!content.isLoading)
            RhCard(
              child: Text(l10n.rhActivityMissing, style: cl.text.bodyStrong),
            ),
        ],
      );
    }

    void feedbackAndLeave(FeedbackKind kind, String message) {
      final toaster = ClToaster.of(context);
      giveFeedbackOn(context, ref, me!, kind: kind, activity: activity);
      leaveRhythm(context);
      toaster.show(message: message);
    }

    final fewer = me == null
        ? const <Interest>[]
        : ref.watch(userPreferencesProvider(me.uid)).value?.fewer ??
              const <Interest>[];
    final fewerTopics = [
      for (final t in topicsOf(activity))
        if (!fewer.contains(t)) t,
    ];
    final explainFor = aiAvailable(ref.watch(selectedCapabilitiesProvider), me)
        ? ref
              .watch(recommendationsProvider(me!.babyId))
              .value
              ?.where((r) => r.contentId == contentId && r.active)
              .firstOrNull
        : null;
    final steps = activity.steps.of(locale);
    final safety = activity.safety?.of(locale);
    final author = checkIn == null
        ? null
        : members.where((m) => m.uid == checkIn.authorUid).firstOrNull;
    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.peachSoft,
            borderRadius: BorderRadius.circular(rhCardRadius),
          ),
          // Ink on soft warm fills, also in Night care.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.rhSuggestionEyebrow(
                  durationLabel(l10n, activity.durationMin),
                ),
                style: cl.text.caption.copyWith(
                  color: cl.colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ClSpace.s1),
              Semantics(
                header: true,
                child: Text(
                  activity.title.of(locale),
                  style: cl.text.title2.copyWith(
                    fontSize: 22,
                    color: cl.colors.ink,
                  ),
                ),
              ),
              if (checkIn != null) ...[
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.rhBecauseNoted(
                    checkInQuote(l10n, checkIn),
                    memberLabel(
                      l10n,
                      author,
                      myUid: me!.uid,
                      uid: checkIn.authorUid,
                    ),
                    shortDay(locale, checkIn.date),
                  ),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ],
            ],
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: ClSpace.s3),
          RhCard(
            child: PlanStatus(
              me: me!,
              plan: plan,
              timeOfDay: activity.timeOfDay,
              today: today,
              zone: zone,
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        if (steps.isNotEmpty) ...[
          RhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RhCardHeading(l10n.rhHow),
                const SizedBox(height: ClSpace.s3),
                RhSteps(steps),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        RhInfoBox(
          icon: null,
          label: l10n.rhWhyItMayHelp,
          text: activity.summary.of(locale),
        ),
        // "Giải thích thêm" (Premium Slice 3, kind explain) of the household's suggestion of it.
        if (explainFor case final rec?)
          AiExplainBlock(babyId: me!.babyId, recommendationId: rec.id),
        if (safety != null) ...[
          const SizedBox(height: ClSpace.s3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.sunshineSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClIcon(ClIcons.alert, size: 16, color: cl.colors.ink),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rhSafety,
                        style: cl.text.label.copyWith(
                          color: cl.colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safety,
                        style: cl.text.label.copyWith(color: cl.colors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        RhReviewNote(activity.review),
        if (activity.sources.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s1),
          Text(
            '${l10n.rhSources}: ${activity.sources.map((s) => s.label).join(' · ')}',
            style: cl.text.caption.copyWith(
              color: cl.colors.inkMuted,
              fontSize: 11,
            ),
          ),
        ],
        // EN05: turns this kind of idea down for this person at once; free forever.
        if (me != null && fewerTopics.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: RhLink(
              label: l10n.rhFewerLikeThis,
              muted: true,
              start: true,
              onTap: () => fewerLikeThis(context, ref, me, activity),
            ),
          ),
      ],
      bottom: canAct && plan != null
          ? [
              // The same three answers as the Home card (owner, 2026-10-25).
              if (plan.due) ...[
                Text(
                  activity.timeOfDay == ActivityTime.evening &&
                          plan.started.date.compareTo(today) < 0
                      ? l10n.rhHowLastNight
                      : l10n.rhHowDidItGo,
                  style: cl.text.bodyStrong,
                ),
                const SizedBox(height: ClSpace.s2),
                RhOutcomeChoices(
                  onPick: (kind) =>
                      feedbackAndLeave(kind, l10n.rhFeedbackSaved),
                ),
                RhLink(
                  label: l10n.rhDidNotTry,
                  muted: true,
                  onTap: () =>
                      withdrawPlan(context, ref, me, plan, notTried: true),
                ),
              ] else if (plan.mine(me.uid))
                ClButton(
                  label: l10n.rhCancelPlan,
                  style: ClButtonStyle.secondary,
                  expand: true,
                  onPressed: () =>
                      withdrawPlan(context, ref, me, plan, notTried: false),
                ),
            ]
          : canAct
          ? [
              ClButton(
                // Owner, 2026-10-25: "Mình sẽ thử" on an idea already tried read oddly.
                label: answered ? l10n.rhTryAgain : l10n.rhIllTry,
                expand: true,
                onPressed: () async {
                  giveFeedbackOn(
                    context,
                    ref,
                    me,
                    kind: FeedbackKind.started,
                    activity: activity,
                  );
                  // P-179: when should this phone remind (its own toast says what was set).
                  await askTryReminder(context, ref, me.babyId, contentId);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: RhLink(
                      label: l10n.rhNotRight,
                      muted: true,
                      onTap: () => feedbackAndLeave(
                        FeedbackKind.notSuitable,
                        l10n.rhNotRightToast,
                      ),
                    ),
                  ),
                  Text(
                    '  ·  ',
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                  Flexible(
                    child: RhLink(
                      label: l10n.rhAnotherIdea,
                      onTap: () => feedbackAndLeave(
                        FeedbackKind.notToday,
                        l10n.rhPutOffToast,
                      ),
                    ),
                  ),
                ],
              ),
            ]
          : null,
    );
  }
}

/// AC02 (590:6558): after trying — "Có ích / Chưa rõ / Không phù hợp" and an optional note.
/// The answer only shapes the next suggestion; "Có ích" never claims the activity caused it.
/// A plan still waiting for its chance (D-076 #10) shows when it will be asked instead, and a due
/// plan offers "Chưa thử" too.
class ActivityFeedbackScreen extends ConsumerStatefulWidget {
  const ActivityFeedbackScreen({required this.contentId, super.key});
  final String contentId;

  @override
  ConsumerState<ActivityFeedbackScreen> createState() =>
      _ActivityFeedbackScreenState();
}

class _ActivityFeedbackScreenState
    extends ConsumerState<ActivityFeedbackScreen> {
  FeedbackKind? _kind;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final activity = ref
        .watch(rhythmContentProvider)
        .value
        ?.activity(widget.contentId);
    final feedback = me == null
        ? const <RecFeedback>[]
        : ref.watch(recFeedbackProvider(me.babyId)).value ??
              const <RecFeedback>[];
    final startedOn = feedback
        .where(
          (r) =>
              r.contentId == widget.contentId && r.kind == FeedbackKind.started,
        )
        .firstOrNull
        ?.date;
    if (me != null) watchRhythmClock(ref, me.babyId);
    final today = me == null ? null : rhythmToday(ref, me.babyId);
    final zone =
        (me == null ? null : ref.watch(babyProvider(me.babyId)).value)
            ?.timeZone
            .zone ??
        'Asia/Ho_Chi_Minh';
    final plan = me == null || activity == null
        ? null
        : openPlan(
            feedback,
            widget.contentId,
            zone: zone,
            timeOfDay: activity.timeOfDay,
            now: rhythmNow(ref),
            setAside: ref.watch(plansSetAsideProvider(setAsideKey(me))),
          );
    final waiting = plan != null && !plan.due;
    final lastNight =
        activity?.timeOfDay == ActivityTime.evening &&
        startedOn != null &&
        today != null &&
        startedOn.compareTo(today) < 0;
    final canAct = me != null && familyCan(me, FamilyAction.rhythmFeedback);

    void save() {
      final kind = _kind;
      if (kind == null || activity == null || me == null) return;
      final toaster = ClToaster.of(context);
      giveFeedbackOn(
        context,
        ref,
        me,
        kind: kind,
        activity: activity,
        note: _note.text,
      );
      closeFlow(context);
      toaster.show(message: l10n.rhFeedbackSaved);
    }

    return OnboardingScaffold(
      topBar: Row(
        children: [
          RhRoundIcon(
            icon: ClIcons.close,
            label: l10n.a11yClose,
            onPressed: () => leaveRhythm(context),
          ),
          const Spacer(),
          if (plan != null && activity != null)
            RhPill(
              label: planStatusLabel(
                l10n,
                locale,
                plan,
                activity.timeOfDay,
                today: today ?? plan.started.date,
              ),
              icon: ClIcons.check,
              mint: true,
            )
          else if (startedOn != null)
            RhPill(
              label: l10n.rhTriedOn(shortDay(locale, startedOn)),
              icon: ClIcons.check,
              mint: true,
            ),
        ],
      ),
      content: [
        if (activity == null)
          RhCard(child: Text(l10n.rhActivityMissing, style: cl.text.bodyStrong))
        else ...[
          Semantics(
            header: true,
            child: Text(
              activity.title.of(locale),
              style: cl.text.headline.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          if (waiting)
            RhCard(
              child: PlanStatus(
                me: me!,
                plan: plan,
                timeOfDay: activity.timeOfDay,
                today: today ?? plan.started.date,
                zone: zone,
              ),
            )
          else
            RhCard(
              outline: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastNight ? l10n.rhHowLastNight : l10n.rhHowDidItGo,
                    style: cl.text.bodyStrong,
                  ),
                  const SizedBox(height: ClSpace.s3),
                  RhOutcomeChoices(
                    selected: _kind,
                    onPick: (k) => setState(() => _kind = k),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  ClTextField(
                    placeholder: l10n.rhNoteHint,
                    controller: _note,
                    maxLines: 3,
                    maxLength: RecFeedback.noteMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: ClSpace.s3),
                  RhInfoBox(icon: ClIcons.sliders, text: l10n.rhFeedbackInfo),
                ],
              ),
            ),
        ],
      ],
      bottom: canAct && activity != null
          ? [
              if (waiting) ...[
                if (plan.mine(me.uid))
                  ClButton(
                    label: l10n.rhCancelPlan,
                    style: ClButtonStyle.secondary,
                    expand: true,
                    onPressed: () {
                      withdrawPlan(context, ref, me, plan, notTried: false);
                      leaveRhythm(context);
                    },
                  ),
              ] else ...[
                ClButton(
                  label: l10n.rhSaveFeedback,
                  expand: true,
                  onPressed: _kind == null ? null : save,
                ),
                if (plan != null) ...[
                  const SizedBox(height: ClSpace.s2),
                  ClButton(
                    label: l10n.rhDidNotTry,
                    style: ClButtonStyle.secondary,
                    expand: true,
                    onPressed: () {
                      withdrawPlan(context, ref, me, plan, notTried: true);
                      leaveRhythm(context);
                    },
                  ),
                ],
              ],
            ]
          : null,
    );
  }
}
