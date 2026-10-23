import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_plans.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';
import 'rhythm_week.dart';

/// A teaser for "Tuần này của {bé}" from another module (Giai đoạn của bé, D-076 #7): the card's
/// one or two lines, how many ideas the destination holds, and where it goes. [id] is the small
/// card it stands for in the Home carousel, which leaves that card out (no duplicates).
typedef WeekTeaser = ({
  String id,
  String text,
  int ideas,
  void Function(BuildContext context) onOpen,
});

/// Hôm nay · "Dành cho bé hôm nay" ([TodaySection.forYou]), only when the family's `rhythm` flag
/// is on. Two parts, one job each (owner, 2026-10-15; brief p.11 for what shows and when):
///
/// 1. **Dành cho bé hôm nay** — what to do today: health first (it pauses suggestions), then ONE
///    compact suggestion (group A, H02 589:6368 / PS02 591:6495; why it came is behind "Vì sao
///    gợi ý này?"), the small cards of other modules ([more], "Để ý tuần này"), "Hôm nay con có
///    gì khác?" (who may check in) and, last, "Hỗ trợ phù hợp với con" (H01 589:6281: only when
///    group A is missing for want of a plan).
/// 2. **Tuần này của {bé}** — one card: "Tuần thứ N · N−1 tuần tuổi" with a teaser from real
///    content ([weekTeaser], else the free age card, Q-067), then compact rows for the reference
///    calendar (never on a health day) and the week summary (EN09, who reads care).
///
/// Numbering everywhere: "Tuần thứ N" is the week of life (completed weeks + 1), "N tuần tuổi"
/// counts completed weeks only.
class ForYouSection extends ConsumerWidget {
  const ForYouSection({
    this.header,
    this.more = const [],
    this.weekTeaser,
    this.enablePrimary = true,
    super.key,
  });

  // ---- D-076 #4 (Hôm nay "Dành cho bé hôm nay", lib/features/today/today_for_baby.dart) ----
  /// Drawn above the first part, only when it has at least one card.
  final Widget? header;

  /// Cards other modules add after the suggestion (Home's small-card carousel).
  final List<Widget> more;

  /// Replaces the age card's teaser in "Tuần này của {bé}" (the current stage).
  final WeekTeaser? weekTeaser;
  final bool enablePrimary;
  // ---- end D-076 #4 ----

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    final caps = ref.watch(selectedCapabilitiesProvider);
    if (me == null || caps == null || !caps.features.rhythm) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final babyId = me.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final name = baby?.nickname ?? '';
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final todayDate = babyToday(zone, now);
    final today = isoOf(todayDate);

    final canRead = familyCan(me, FamilyAction.historyRead);
    final canCheckIn = familyCan(me, FamilyAction.rhythmCheckin);
    final groupA = caps.allows(Capability.personalizationCrossModule);
    final content = ref.watch(rhythmContentProvider).value;
    final reference = ref.watch(rhythmReferenceProvider).value;
    final profile = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(babyId)).value
        : null;
    final dob = profile?.dateOfBirth;
    final checkIns = canRead
        ? ref.watch(checkInsProvider(babyId)).value ?? const <CheckIn>[]
        : const <CheckIn>[];
    final feedback = canRead
        ? ref.watch(recFeedbackProvider(babyId)).value ?? const <RecFeedback>[]
        : const <RecFeedback>[];
    // The server composes group A; without it, it is asked only for the age card of a member
    // who may not read the date of birth (caregivers).
    final home = canRead && (groupA || !me.canViewBabyInfo)
        ? ref
              .watch(homeCompositionProvider((babyId, locale.languageCode)))
              .value
        : null;

    final health = checkIns
        .where((c) => c.date == today && c.needsHealthSupport)
        .firstOrNull;

    // The suggestion, unless just put off / ruled out on this phone (the server catches up).
    final rec = groupA ? home?.recommendation : null;
    final activity = rec == null ? null : content?.activity(rec.contentId);
    final last = rec == null ? null : latestFeedback(feedback, rec.contentId);
    final afterRec =
        last != null &&
        (last.createdAt == null ||
            rec!.generatedAt == null ||
            last.createdAt!.isAfter(rec.generatedAt!));
    final putOff =
        afterRec &&
        (last.kind == FeedbackKind.notSuitable ||
            (last.kind == FeedbackKind.notToday && last.date == today));
    final showPrimary =
        enablePrimary &&
        health == null &&
        rec != null &&
        rec.active &&
        activity != null &&
        activity.status == ContentStatus.published &&
        activity.version == rec.contentVersion &&
        rec.generatedAt != null &&
        isoOf(inBabyZone(zone, rec.generatedAt!)) == today &&
        (rec.expiresAt == null || rec.expiresAt!.isAfter(now)) &&
        checkIns.any(
          (c) =>
              c.id == rec.checkInId &&
              c.date == today &&
              c.observation != Observation.usual &&
              c.revision == (rec.sourceRevision ?? 1),
        ) &&
        !putOff;

    final ageCard = content == null
        ? null
        : dob != null
        ? ageCardFor(content.ageCards, ageInDays(dob, todayDate))
        : home?.ageCardId == null
        ? null
        : content.ageCard(home!.ageCardId!);

    // ---- Tuần này của {bé}: the teaser (a stage, else the age card) and its rows ----
    final teaser =
        weekTeaser ??
        (ageCard == null
            ? null
            : (
                id: 'age:${ageCard.id}',
                text: firstSentence(ageCard.body.of(locale)),
                ideas: ageCard.tips.of(locale).length,
                onOpen: (BuildContext c) =>
                    c.push('${Routes.rhythmAge}/${ageCard.id}'),
              ));
    final rows = <WeekRow>[];
    final due = profile?.dueDate?.date;
    if (health == null && reference != null && due != null) {
      final stages = currentStages(due, today, reference.stages);
      if (stages.current.firstOrNull ?? stages.next case final focus?) {
        final soothing = canRead ? soothingDays(checkIns, today) : 0;
        rows.add((
          key: const Key('forBabyRhythm'),
          icon: ClIcons.sleep,
          tone: WeekRowTone.rhythm,
          title: stages.current.isNotEmpty
              ? l10n.hnRhythmNow(focus.number)
              : l10n.hnRhythmComingDays(
                  focus.number,
                  DateTime.parse(
                    windowOf(due, focus).start,
                  ).difference(DateTime.parse(today)).inDays,
                ),
          sub: [
            l10n.hnWeekRhythmSub(dayRange(l10n, locale, windowOf(due, focus))),
            if (soothing > 0) l10n.hnRhythmSoothing(soothing),
          ].join('\n'),
          onOpen: (c) => c.push(Routes.rhythm),
        ));
      }
    }
    // EN09 once a whole week of the baby's life has passed (who reads care). Dates only: the
    // Mon–Sun week does not line up with the week of life the card above counts.
    final week = summaryWeekFor(today);
    if (canRead && weekHasPassed(dob, week)) {
      rows.add((
        key: const Key('forBabyWeekSummary'),
        icon: ClIcons.journal,
        tone: WeekRowTone.mint,
        title: week.inProgress
            ? l10n.hnWeekSummaryThis
            : l10n.hnWeekSummaryLast,
        sub: l10n.rhDateRange(
          shortDay(locale, week.start),
          shortDay(locale, week.end),
        ),
        onOpen: (c) => c.push(Routes.rhythmWeek),
      ));
    }

    final showSupport =
        !groupA &&
        caps.reasonFor(Capability.personalizationCrossModule) ==
            GateReason.premiumRequired;

    final todayCards = <Widget>[
      if (health != null) RhHealthCard(signs: health.healthSigns),
      if (showPrimary)
        _PrimaryCard(
          me: me,
          rec: rec,
          activity: activity,
          lastFeedback: home?.lastFeedback,
          checkIns: checkIns,
          feedback: feedback,
          started:
              rec.state == RecState.started ||
              (afterRec && last.kind == FeedbackKind.started),
          today: today,
          zone: zone,
          now: now,
          babyName: name,
          secondary: secondaryActivities(content, home!),
        ),
      ...more, // D-076 #4
      if (canCheckIn)
        _CheckInEntry(
          // Owner, 2026-10-22: after answering, the row says what was noted today.
          done:
              checkIns
                  .where((c) => c.date == today && c.authorUid == me.uid)
                  .firstOrNull ??
              checkIns.where((c) => c.date == today).firstOrNull,
          who: (uid) => memberLabel(
            l10n,
            (ref.watch(familyMembersProvider(babyId)).value ?? const [])
                .where((m) => m.uid == uid)
                .firstOrNull,
            myUid: me.uid,
            uid: uid,
          ),
        ),
      if (showSupport) const _SupportCard(),
    ];
    final weekCard = teaser == null && rows.isEmpty
        ? null
        : WeekCard(
            kicker: weekKicker(l10n, dob: dob, today: todayDate, card: ageCard),
            teaser: teaser,
            rows: rows,
          );
    if (todayCards.isEmpty && weekCard == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todayCards.isNotEmpty) ...[
            if (header case final h?) ...[
              h,
              const SizedBox(height: ClSpace.s3),
            ],
            for (final (i, c) in todayCards.indexed) ...[
              if (i > 0) const SizedBox(height: ClSpace.s3),
              c,
            ],
          ],
          if (weekCard != null) ...[
            // A section of its own: the gap between Hôm nay's sections.
            if (todayCards.isNotEmpty) const SizedBox(height: ClSpace.s6),
            ClSectionHeader(title: l10n.rhAgeHeading(name)),
            const SizedBox(height: ClSpace.s3),
            weekCard,
          ],
        ],
      ),
    );
  }
}

/// Days among the last three (today included) on which someone noted "cần được dỗ nhiều hơn".
int soothingDays(List<CheckIn> checkIns, String today) {
  final from = addDaysIso(today, -2);
  return {
    for (final c in checkIns)
      if (c.observation == Observation.soothing &&
          c.date.compareTo(from) >= 0 &&
          c.date.compareTo(today) <= 0)
        c.date,
  }.length;
}

/// The first sentence of [text] (the teaser of an age card's body).
String firstSentence(String text) {
  final t = text.trim();
  final end = RegExp(r'[.!?…](?=\s)').firstMatch(t);
  return end == null ? t : t.substring(0, end.end);
}

/// Completed calendar months on [today] (a month is complete on the same day of the month).
int completedMonths(DateTime dob, DateTime today) {
  var months = (today.year - dob.year) * 12 + today.month - dob.month;
  if (today.day < dob.day) months -= 1;
  return months < 0 ? 0 : months;
}

/// "Tuần thứ 5 · 4 tuần tuổi": the week of life (completed weeks + 1) and the age as the header
/// chip says it; from 13 weeks (when the age turns to months, as the content does) "Tháng thứ 5 ·
/// 4 tháng tuổi". Without the date of birth (caregivers) the number comes from the age card's
/// range ("Tuần thứ 4" for days 21–27). Null when nothing is known.
String? weekKicker(
  AppLocalizations l10n, {
  required DateTime? dob,
  required DateTime today,
  AgeCard? card,
}) {
  if (dob != null) {
    final days = ageInDays(dob, today);
    if (days < 0) return null;
    // Owner, 2026-10-22: the age alone ("5 tuần 3 ngày tuổi"); "Tuần thứ 6 · 5 tuần tuổi"
    // read as two different numbers for the same thing.
    return ageLong(l10n, dob, today);
  }
  if (card == null) return null;
  final r = card.ageDays;
  if (r.to - r.from <= 7) return l10n.hnWeekKickerOnly(r.from ~/ 7 + 1);
  return l10n.hnMonthKickerOnly((r.from / 30.4375).round() + 1);
}

/// Today's check-ins flagged a health sign: first, before anything else, and free (Home, NL01).
class RhHealthCard extends StatelessWidget {
  const RhHealthCard({required this.signs, super.key});
  final List<HealthSign> signs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return RhCard(
      color: cl.colors.dangerSoft,
      onTap: () => context.push(healthLocation(signs)),
      semanticLabel: l10n.rhHealthCardTitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(ClIcons.alert, size: 20, color: cl.colors.danger),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.rhHealthCardTitle, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  l10n.rhHealthCardBody,
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.rhHealthCardAction,
                  style: cl.text.label.copyWith(
                    color: cl.colors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// H02 "VIỆC CÓ THỂ THỬ HÔM NAY", compact (owner, 2026-10-15): kicker, title, one line of why
/// (PS02: "Đã điều chỉnh theo phản hồi của nhà mình"), "Vì sao gợi ý này?" (the full reasons,
/// PS02's "Dựa trên phản hồi của bạn" and "Đã thay đổi", and the edit-history link, in a sheet),
/// the plan state (D-076 #10) or the two actions, then the review footnote (D-073 #2).
class _PrimaryCard extends ConsumerWidget {
  const _PrimaryCard({
    required this.me,
    required this.rec,
    required this.activity,
    required this.lastFeedback,
    required this.checkIns,
    required this.feedback,
    required this.started,
    required this.today,
    required this.zone,
    required this.now,
    required this.babyName,
    this.secondary = const [],
  });

  final Membership me;
  final Recommendation rec;
  final Activity activity;
  final FeedbackRef? lastFeedback;
  final List<CheckIn> checkIns;
  final List<RecFeedback> feedback;

  /// The family planned it since this suggestion came (D-076 #10: a plan, not "đã thử").
  final bool started;
  final String today;
  final String zone;
  final DateTime now;
  final String babyName;

  /// ≤2 other activities from `composeHome` (drawn small under the primary).
  final List<Activity> secondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final content = ref.watch(rhythmContentProvider).value;
    Membership? member(String uid) =>
        members.where((m) => m.uid == uid).firstOrNull;
    final evening = activity.timeOfDay == ActivityTime.evening;
    final ps02 = rec.changes.isNotEmpty;
    final canAct = familyCan(me, FamilyAction.rhythmFeedback);
    final checkIn = rec.checkInId == null
        ? null
        : checkIns.where((c) => c.id == rec.checkInId).firstOrNull;

    // "Vì tối qua Ba ghi nhận con khó vào giấc. Lần trước Mẹ đánh giá cách này “Có ích”."
    final reasons = <String>[
      if (rec.reasonCode == ReasonCode.dataInsight) l10n.rhReasonData(babyName),
      if (checkIn != null)
        l10n.rhReasonNoted(
          checkInWhen(l10n, locale, checkIn, today),
          memberLabel(
            l10n,
            member(checkIn.authorUid),
            myUid: me.uid,
            uid: checkIn.authorUid,
            sentenceStart: false,
          ),
          observationWhat(l10n, checkIn.observation, babyName),
        )
      else if (rec.reasonCode == ReasonCode.ageContent)
        l10n.rhReasonAge(babyName)
      else if (rec.reasonCode == ReasonCode.interest)
        l10n.rhReasonInterest
      else if (rec.reasonCode != ReasonCode.dataInsight)
        l10n.rhReasonFallback(babyName),
      if (lastFeedback case final fb?
          when fb.kind == FeedbackKind.helpful && fb.contentId == rec.contentId)
        l10n.rhReasonHelpful(
          memberLabel(
            l10n,
            member(fb.authorUid),
            myUid: me.uid,
            uid: fb.authorUid,
            // Mid-sentence in Vietnamese ("Lần trước Mẹ…"), first in English ("Mum rated…").
            sentenceStart: locale.languageCode == 'en',
          ),
        ),
    ];

    String? usedText;
    if (ps02 && lastFeedback != null) {
      final fb = lastFeedback!;
      final row = feedback.where((r) => r.id == fb.id).firstOrNull;
      final rated = content?.activity(fb.contentId);
      final who = memberLabel(
        l10n,
        member(fb.authorUid),
        myUid: me.uid,
        uid: fb.authorUid,
        sentenceStart: false,
      );
      final title = rated?.title.of(locale) ?? activity.title.of(locale);
      final kind = feedbackKindLabel(l10n, fb.kind);
      final base = rated?.timeOfDay == ActivityTime.evening
          ? l10n.rhFeedbackUsedEvening(
              shortDay(locale, fb.date),
              who,
              kind,
              title,
            )
          : l10n.rhFeedbackUsedDay(shortDay(locale, fb.date), who, kind, title);
      final note = row?.note;
      usedText = note == null ? '$base.' : '$base — ${l10n.rhQuoted(note)}.';
    }
    final why = ps02 ? l10n.hnWhyFeedbackShort : reasons.first;

    // D-076 #10: after "Thử tối nay" the card waits ("Đã lên kế hoạch · tối nay"); the result
    // is asked only once there was a chance to try (CH17 timing), "Chưa thử" always next to it.
    final plan = started
        ? openPlan(
            feedback,
            activity.id,
            zone: zone,
            timeOfDay: activity.timeOfDay,
            now: now,
            setAside: ref.watch(plansSetAsideProvider(setAsideKey(me))),
          )
        : null;

    final again = rec.changes.contains(RecChange.prefersHelpful);
    final tryLabel = again
        ? (evening ? l10n.rhTryAgainTonight : l10n.rhTryAgainToday)
        : (evening ? l10n.rhTryTonight : l10n.rhTryToday);

    void open() =>
        context.push(activityLocation(activity.id, checkInId: rec.checkInId));

    void explain() => showClSheet<void>(
      context: context,
      builder: (_) => _WhySheet(
        reasons: ps02 ? const [] : reasons,
        usedText: usedText,
        changes: [for (final c in rec.changes) changeLabel(l10n, c)],
        // PS02 footer: the person's own answers can be changed or deleted.
        onEditHistory: ps02 && canAct
            ? () => context.push(Routes.rhythmFeedbackHistory)
            : null,
      ),
    );

    return RhCard(
      key: const Key('forBabySuggestion'),
      outline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.heart, size: 14, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  plan?.due ?? false
                      ? l10n.rhKickerFollowUp
                      : (evening ? l10n.rhKickerTonight : l10n.rhKickerToday),
                  style: cl.text.caption.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Semantics(
            header: true,
            child: Text(
              activity.title.of(locale),
              style: cl.text.headline.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            why,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          ClPressable(
            key: const Key('forBabyWhy'),
            onPressed: explain,
            semanticLabel: l10n.hnWhyLink,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.hnWhyLink,
                    style: cl.text.label.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  ClIcon(
                    ClIcons.chevronRight,
                    size: 14,
                    color: cl.colors.mintText,
                  ),
                ],
              ),
            ),
          ),
          if (plan != null) ...[
            const SizedBox(height: ClSpace.s1),
            PlanStatus(
              me: me,
              plan: plan,
              timeOfDay: activity.timeOfDay,
              today: today,
              zone: zone,
            ),
          ],
          if (canAct && plan != null) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (plan.due) ...[
                  RhPillButton(
                    label: l10n.rhTellHow,
                    onTap: () =>
                        context.push(activityFeedbackLocation(activity.id)),
                  ),
                  RhPillButton(
                    label: l10n.rhDidNotTry,
                    primary: false,
                    onTap: () =>
                        withdrawPlan(context, ref, me, plan, notTried: true),
                  ),
                ] else if (plan.mine(me.uid))
                  RhPillButton(
                    label: l10n.rhCancelPlan,
                    primary: false,
                    onTap: () =>
                        withdrawPlan(context, ref, me, plan, notTried: false),
                  ),
                RhPillButton(label: l10n.rhHow, primary: false, onTap: open),
              ],
            ),
          ] else if (canAct) ...[
            const SizedBox(height: ClSpace.s2),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                RhPillButton(
                  label: tryLabel,
                  onTap: () {
                    giveFeedbackOn(
                      context,
                      ref,
                      me,
                      kind: FeedbackKind.started,
                      activity: activity,
                    );
                    open();
                  },
                ),
                RhPillButton(
                  label: ps02 ? l10n.rhSomethingElse : l10n.rhNotToday,
                  primary: false,
                  onTap: () {
                    giveFeedbackOn(
                      context,
                      ref,
                      me,
                      kind: FeedbackKind.notToday,
                      activity: activity,
                    );
                    showClToast(context, message: l10n.rhPutOffToast);
                  },
                ),
              ],
            ),
          ] else
            RhLink(label: l10n.rhHow, start: true, onTap: open),
          const SizedBox(height: ClSpace.s3),
          RhReviewNote(activity.review),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Container(height: 1, color: cl.colors.separator),
            const SizedBox(height: ClSpace.s3),
            RhSecondaryIdeas(
              activities: secondary,
              onOpen: (a) => context.push(
                activityLocation(a.id, checkInId: rec.checkInId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Vì sao gợi ý này?": every reason (H02), or PS02's "Dựa trên phản hồi của bạn" and "Đã thay
/// đổi" with the edit-history link, then how suggestions are made.
class _WhySheet extends StatelessWidget {
  const _WhySheet({
    required this.reasons,
    required this.usedText,
    required this.changes,
    this.onEditHistory,
  });

  final List<String> reasons;
  final String? usedText;
  final List<String> changes;
  final VoidCallback? onEditHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      key: const Key('forBabyWhySheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.hnWhyTitle),
        if (reasons.isNotEmpty) RhInfoBox(text: reasons.join(' ')),
        if (usedText case final used?) ...[
          RhInfoBox(
            tone: RhInfoTone.mint,
            icon: ClIcons.check,
            label: l10n.rhBasedOnFeedback,
            text: used,
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        if (changes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rhChangedTitle,
                  style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                ),
                RhBullets(changes, color: cl.colors.inkMuted),
              ],
            ),
          ),
        if (onEditHistory case final edit?)
          Align(
            alignment: Alignment.centerLeft,
            child: RhLink(
              label: l10n.rhEditHistoryLink,
              muted: true,
              start: true,
              onTap: () {
                Navigator.of(context).pop();
                edit();
              },
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.hnWhyHow,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// "Hôm nay con có gì khác?" → C01 (Cùng nuôi, Người chăm sóc): a slim row.
class _CheckInEntry extends StatelessWidget {
  const _CheckInEntry({required this.done, required this.who});

  /// Today's check-in (this person's first), null before anyone answered.
  final CheckIn? done;
  final String Function(String uid) who;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = done;
    return RhCard(
      key: const Key('forBabyCheckIn'),
      padding: EdgeInsets.zero,
      child: _RowContent(
        icon: d == null ? ClIcons.edit : ClIcons.check,
        tone: WeekRowTone.mint,
        title: d == null
            ? l10n.rhCheckInEntry
            : l10n.hnCheckInDone(observationLabel(l10n, d.observation)),
        sub: d == null ? null : l10n.hnCheckInDoneSub(who(d.authorUid)),
        onTap: () => context.push(Routes.rhythmCheckIn),
      ),
    );
  }
}

/// The tint of a row's icon tile: lavender only for Nhịp lớn lên (the reference calendar).
enum WeekRowTone { mint, rhythm }

/// One compact row of the "Tuần này" card: what it is, one or two lines, where it goes.
typedef WeekRow = ({
  Key key,
  ClIcons icon,
  WeekRowTone tone,
  String title,
  String sub,
  void Function(BuildContext context) onOpen,
});

/// "Tuần này của {bé}" (owner, 2026-10-15): ONE card. Its top opens the week's content: the
/// kicker "Tuần thứ 5 · 4 tuần tuổi", a teaser from the content itself and "Xem 3 gợi ý cho
/// tuần này →"; under it, compact rows (Nhịp lớn lên, Tóm tắt tuần trước).
class WeekCard extends StatelessWidget {
  const WeekCard({
    required this.kicker,
    required this.teaser,
    required this.rows,
    super.key,
  });

  final String? kicker;
  final WeekTeaser? teaser;
  final List<WeekRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final t = teaser;
    final action = t == null
        ? null
        : t.ideas > 0
        ? l10n.hnWeekOpenIdeas(t.ideas)
        : l10n.hnWeekOpen;
    final parts = <Widget>[
      if (t != null)
        ClPressable(
          key: const Key('forBabyWeek'),
          onPressed: () => t.onOpen(context),
          pressedOpacity: ClPressable.surfaceOpacity,
          semanticLabel: [?kicker, t.text, ?action].join('. '),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s4,
              ClSpace.s4,
              ClSpace.s3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker case final k?) ...[
                  Row(
                    children: [
                      ClIcon(ClIcons.cake, size: 14, color: cl.colors.mintText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          k,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.mintText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s2),
                ],
                Text(
                  t.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.bodyStrong,
                ),
                const SizedBox(height: ClSpace.s2),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 28),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          action!,
                          style: cl.text.label.copyWith(
                            color: cl.colors.mintText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ClIcon(
                        ClIcons.arrowRight,
                        size: 14,
                        color: cl.colors.mintText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      for (final r in rows)
        _RowContent(
          key: r.key,
          icon: r.icon,
          tone: r.tone,
          title: r.title,
          sub: r.sub,
          dense: true,
          onTap: () => r.onOpen(context),
        ),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(rhCardRadius),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in parts.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                child: Container(height: 1, color: cl.colors.separator),
              ),
            p,
          ],
        ],
      ),
    );
  }
}

/// Icon tile, title, optional lines and a chevron; the whole row opens [onTap].
class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.icon,
    required this.tone,
    required this.title,
    required this.onTap,
    this.sub,
    this.dense = false,
    super.key,
  });

  final ClIcons icon;
  final WeekRowTone tone;
  final String title;
  final String? sub;
  final VoidCallback onTap;

  /// A row under the week card's teaser: one step quieter than the teaser.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (fill, ink) = switch (tone) {
      WeekRowTone.mint => (cl.colors.mintSoft, cl.colors.mintText),
      WeekRowTone.rhythm => (cl.care.sleep.soft, cl.care.sleep.ink),
    };
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [title, ?sub].join('. '),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 18, color: ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: dense
                        ? cl.text.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          )
                        : cl.text.bodyStrong,
                  ),
                  if (sub case final s?)
                    Text(
                      s,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// H01 "Hỗ trợ phù hợp với con · Tìm hiểu thêm": quiet (hairline, no shadow), only when the
/// household lacks group A for want of a plan; opens the household plan (PR03).
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return RhCard(
      hairline: true,
      // PR01 from Nhịp lớn lên (entry A).
      onTap: () => openPaywall(context, entry: PaywallEntry.rhythm),
      semanticLabel: '${l10n.rhSupportTitle}. ${l10n.rhLearnMore}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(ClIcons.spark, size: 18, color: cl.colors.mintText),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.rhSupportTitle, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  l10n.rhSupportBody,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.rhLearnMore,
                  style: cl.text.label.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
