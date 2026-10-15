import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_widgets.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_models.dart' show GateReason;
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// After saving a check-in: PS01 (590:6445, group A: one action, why, try / later), PS01F
/// (590:6481, free: age content and an optional "Tìm hiểu thêm" only on PREMIUM_REQUIRED, never
/// blocking), "Chưa có gợi ý phù hợp", or offline (ST01 594:6967: saved on the phone, the
/// suggestion comes later). The check-in is already saved whatever happens here.
class RhythmResultScreen extends ConsumerWidget {
  const RhythmResultScreen({required this.checkIn, super.key});
  final CheckIn checkIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    watchRhythmClock(ref, checkIn.babyId);
    final members =
        ref.watch(familyMembersProvider(checkIn.babyId)).value ?? const [];
    // Unknown until the first connectivity answer: no call yet.
    final online = ref.watch(onlineProvider).value;
    final key = (
      babyId: checkIn.babyId,
      checkInId: checkIn.id,
      revision: checkIn.revision,
      locale: locale.languageCode,
    );
    final answer = online == true ? ref.watch(nextActionProvider(key)) : null;
    final subtitle = [
      ...checkInParts(l10n, checkIn),
      seenBy(l10n, members, me?.uid ?? checkIn.authorUid),
    ].join(' · ');

    final Widget body;
    if (online == null) {
      body = const _Loading();
    } else if (answer == null) {
      body = _StateCard(
        icon: ClIcons.cloudOff,
        title: l10n.rhOfflineTitle,
        body: l10n.rhOfflineBody,
      );
    } else {
      body = answer.when(
        skipLoadingOnRefresh: false,
        loading: () => const _Loading(),
        error: (e, _) => e is RhythmException && e.offline
            ? _StateCard(
                icon: ClIcons.cloudOff,
                title: l10n.rhOfflineTitle,
                body: l10n.rhOfflineBody,
              )
            : _StateCard(
                icon: ClIcons.alert,
                title: l10n.rhErrorTitle,
                body: l10n.rhErrorBody,
                action: (
                  l10n.rhRetry,
                  () => ref.invalidate(nextActionProvider(key)),
                ),
              ),
        data: (a) => _Answer(checkIn: checkIn, answer: a),
      );
    }
    final done = answer?.value?.state != AnswerState.suggestion;
    return OnboardingScaffold(
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: RhRoundIcon(
          icon: ClIcons.close,
          label: l10n.a11yClose,
          onPressed: () => closeFlow(context),
        ),
      ),
      content: [
        RhSavedBanner(title: l10n.rhSavedTitle, subtitle: subtitle),
        const SizedBox(height: ClSpace.s6),
        body,
        if (done || answer?.value == null) ...[
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.rhDone,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => closeFlow(context),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          CupertinoActivityIndicator(color: cl.colors.inkMuted, radius: 9),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              AppLocalizations.of(context).rhLoadingSuggestion,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// ST01-style state card: icon chip, headline, body, optional link.
class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final ClIcons icon;
  final String title;
  final String body;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: 15, color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(title, style: cl.text.bodyStrong),
          const SizedBox(height: 2),
          Text(body, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          if (action case final a?) ...[
            const SizedBox(height: ClSpace.s1),
            RhLink(label: a.$1, onTap: a.$2),
          ],
        ],
      ),
    );
  }
}

class _Answer extends ConsumerWidget {
  const _Answer({required this.checkIn, required this.answer});
  final CheckIn checkIn;
  final NextActionAnswer answer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(rhythmContentProvider).value;
    final ageCard = _ageCard(ref, content);
    final rec = answer.recommendation;
    final activity = rec == null ? null : content?.activity(rec.contentId);
    if (answer.state == AnswerState.suggestion &&
        rec != null &&
        activity != null) {
      return _Suggestion(
        checkIn: checkIn,
        answer: answer,
        rec: rec,
        activity: activity,
      );
    }
    if (answer.state == AnswerState.freeContent) {
      return _FreeContent(ageCard: ageCard, gate: answer.gateReason);
    }
    // No suggestion (or content not on this phone yet).
    return _StateCard(
      icon: ClIcons.spark,
      title: l10n.rhNoSuggestionTitle,
      body: l10n.rhNoSuggestionBody,
      action: ageCard == null
          ? null
          : (
              l10n.rhSeeAgeContent,
              () => context.push('${Routes.rhythmAge}/${ageCard.id}'),
            ),
    );
  }

  /// The server's card for the baby's age, else the phone's own from the date of birth.
  AgeCard? _ageCard(WidgetRef ref, RhythmContent? content) {
    if (content == null) return null;
    if (answer.ageCardId case final id?) {
      if (content.ageCard(id) case final card?) return card;
    }
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || !me.canViewBabyInfo) return null;
    final dob = ref.watch(rhythmProfileProvider(me.babyId)).value?.dateOfBirth;
    if (dob == null) return null;
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    return ageCardFor(content.ageCards, ageInDays(dob, babyToday(zone, now)));
  }
}

/// PS01: "Một việc có thể thử", the activity with its reason and review label, then
/// "Thử tối nay" / "Để sau" and "Xem nhịp của con".
class _Suggestion extends ConsumerWidget {
  const _Suggestion({
    required this.checkIn,
    required this.answer,
    required this.rec,
    required this.activity,
  });
  final CheckIn checkIn;
  final NextActionAnswer answer;
  final Recommendation rec;
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = ref.watch(babyProvider(checkIn.babyId)).value;
    final evening = activity.timeOfDay == ActivityTime.evening;
    final canAct = me != null && familyCan(me, FamilyAction.rhythmFeedback);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.rhOneThing,
            style: cl.text.headline.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        RhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RhIconTile(icon: activityIcon(activity)),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title.of(locale),
                          style: cl.text.bodyStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activityMeta(l10n, activity),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              RhInfoBox(
                icon: null,
                label: l10n.rhWhyThis,
                text: whyThis(l10n, checkIn, rec, answer.sleep),
              ),
              // "Giải thích thêm" (Premium Slice 3, kind explain): the reason above stays.
              if (aiAvailable(ref.watch(selectedCapabilitiesProvider), me))
                AiExplainBlock(
                  babyId: checkIn.babyId,
                  recommendationId: rec.id,
                ),
              const SizedBox(height: ClSpace.s2),
              RhReviewNote(activity.review),
            ],
          ),
        ),
        if (canAct) ...[
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: evening ? l10n.rhTryTonight : l10n.rhTryToday,
            expand: true,
            onPressed: () {
              giveFeedbackOn(
                context,
                ref,
                me,
                kind: FeedbackKind.started,
                activity: activity,
              );
              closeFlow(
                context,
                then: activityLocation(activity.id, checkInId: checkIn.id),
              );
            },
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.rhLater,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () {
              final toaster = ClToaster.of(context);
              giveFeedbackOn(
                context,
                ref,
                me,
                kind: FeedbackKind.notToday,
                activity: activity,
              );
              closeFlow(context);
              toaster.show(message: l10n.rhPutOffToast);
            },
          ),
        ],
        if (secondaryActivities(ref.watch(rhythmContentProvider).value, answer)
            case final others when others.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          RhSecondaryIdeas(
            activities: others,
            onOpen: (a) => closeFlow(
              context,
              then: activityLocation(a.id, checkInId: checkIn.id),
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s2),
        RhLink(
          label: l10n.rhSeeRhythm(baby?.nickname ?? ''),
          onTap: () => closeFlow(context, then: Routes.rhythm),
        ),
      ],
    );
  }
}

/// PS01 "Vì sao gợi ý này": what was just noted, what was tried, what helped, what the log
/// shows (DATA_INSIGHT). Facts only, never a cause.
String whyThis(
  AppLocalizations l10n,
  CheckIn c,
  Recommendation rec,
  SleepFacts? sleep,
) {
  final parts = <String>[l10n.rhWhyJustNoted(checkInQuote(l10n, c))];
  final tried = [
    for (final t in c.tried)
      if (t != Tried.none) triedLabel(l10n, t),
  ];
  if (tried.isNotEmpty) parts.add(l10n.rhWhyTriedOther(joinNames(l10n, tried)));
  if (rec.reasonCode == ReasonCode.previousHelpful) {
    parts.add(l10n.rhWhyHelpedBefore);
  }
  if (rec.reasonCode == ReasonCode.dataInsight &&
      sleep?.status == SleepStatus.changeDetected &&
      sleep?.recent != null &&
      sleep?.baseline != null) {
    parts.add(
      l10n.rhWhyData(
        durationLabel(l10n, sleep!.recent!.round()),
        durationLabel(l10n, sleep.baseline!.round()),
      ),
    );
  }
  return parts.join(' ');
}

/// PS01F: age content (free) and, only when the household lacks group A for want of a plan, the
/// optional "Tìm hiểu thêm (tuỳ chọn)" to the household plan. Never blocks "Xong".
class _FreeContent extends StatelessWidget {
  const _FreeContent({required this.ageCard, required this.gate});
  final AgeCard? ageCard;
  final GateReason? gate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final card = ageCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (card != null) ...[
          Semantics(
            header: true,
            child: Text(
              l10n.rhMoreForAge,
              style: cl.text.headline.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          RhCard(
            onTap: () => context.push('${Routes.rhythmAge}/${card.id}'),
            semanticLabel: card.title.of(locale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RhPill(label: l10n.rhFreeAgePill, icon: ClIcons.journal),
                const SizedBox(height: ClSpace.s2),
                Text(card.title.of(locale), style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  l10n.rhReadMinutes(readMinutes(card, locale)),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
        if (gate == GateReason.premiumRequired) ...[
          const SizedBox(height: ClSpace.s3),
          RhCard(
            hairline: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClIcon(ClIcons.spark, size: 18, color: cl.colors.mintText),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.rhUpsellTitle, style: cl.text.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        l10n.rhUpsellBody,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RhLink(
                          label: l10n.rhLearnMoreOptional,
                          // PR01 entry A, only on tap (PS01F).
                          onTap: () =>
                              openPaywall(context, entry: PaywallEntry.rhythm),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Đọc 3 phút": about 180 words a minute, at least one.
int readMinutes(AgeCard card, Locale locale) {
  final text = [
    card.body.of(locale),
    ...card.tips.of(locale),
    ...card.watchFor.of(locale),
  ].join(' ');
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return (words / 180).ceil().clamp(1, 30);
}
