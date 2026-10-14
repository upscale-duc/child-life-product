import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// Hôm nay · "Dành cho bé hôm nay" ([TodaySection.forYou]), only when the family's `rhythm` flag
/// is on. Order (brief p.11): health → the current-need suggestion (group A, H02 589:6368 /
/// PS02 591:6495) → "Hôm nay con có gì khác?" (who may check in) → "Tuần này của {bé}" (free,
/// Q-067) → the reference calendar (free, never first) → "Hỗ trợ phù hợp với con" (H01
/// 589:6281: only when group A is missing for want of a plan). Health hides the suggestion and
/// the calendar ("Child Life dừng gợi ý theo lịch").
class ForYouSection extends ConsumerWidget {
  const ForYouSection({super.key});

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
        health == null &&
        rec != null &&
        rec.active &&
        activity != null &&
        !putOff;

    final ageCard = content == null
        ? null
        : dob != null
        ? ageCardFor(content.ageCards, ageInDays(dob, todayDate))
        : home?.ageCardId == null
        ? null
        : content.ageCard(home!.ageCardId!);

    String? stageLine;
    final due = profile?.dueDate?.date;
    if (health == null && reference != null && due != null) {
      final stages = currentStages(due, today, reference.stages);
      if (stages.current.isNotEmpty) {
        stageLine = [
          for (final s in stages.current)
            l10n.rhStageNow(
              l10n.rhStageName(s.number),
              dayRange(l10n, locale, windowOf(due, s)),
            ),
        ].join('\n');
      } else if (stages.next case final s?) {
        stageLine = l10n.rhStageExpected(
          l10n.rhStageName(s.number),
          dayRange(l10n, locale, windowOf(due, s)),
        );
      }
    }
    final showSupport =
        !groupA &&
        caps.reasonFor(Capability.personalizationCrossModule) ==
            GateReason.premiumRequired;

    final children = <Widget>[
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
          babyName: name,
          secondary: secondaryActivities(content, home!),
        ),
      if (canCheckIn) const _CheckInEntry(),
      if (ageCard != null) ...[
        const SizedBox(height: ClSpace.s3),
        ClSectionHeader(title: l10n.rhAgeHeading(name)),
        _AgeCardTile(
          card: ageCard,
          ageLabel: dob == null ? null : ageLong(l10n, dob, todayDate),
        ),
      ],
      if (stageLine != null)
        _CalendarCard(line: stageLine, compact: showPrimary),
      if (showSupport) const _SupportCard(),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0 && c is! SizedBox && children[i - 1] is! SizedBox)
              const SizedBox(height: ClSpace.s3),
            c,
          ],
        ],
      ),
    );
  }
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

/// H02 "VIỆC CÓ THỂ THỬ HÔM NAY" with "Vì …", or PS02 "Dựa trên phản hồi của bạn" + "Đã thay
/// đổi" when the ranking changed because of feedback.
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
    required this.babyName,
    this.secondary = const [],
  });

  final Membership me;
  final Recommendation rec;
  final Activity activity;
  final FeedbackRef? lastFeedback;
  final List<CheckIn> checkIns;
  final List<RecFeedback> feedback;
  final bool started;
  final String today;
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

    final again = rec.changes.contains(RecChange.prefersHelpful);
    final tryLabel = again
        ? (evening ? l10n.rhTryAgainTonight : l10n.rhTryAgainToday)
        : (evening ? l10n.rhTryTonight : l10n.rhTryToday);

    void open() =>
        context.push(activityLocation(activity.id, checkInId: rec.checkInId));

    return RhCard(
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
                  started
                      ? l10n.rhStartedLabel.toUpperCase()
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
          const SizedBox(height: ClSpace.s3),
          if (ps02) ...[
            if (usedText != null) ...[
              RhInfoBox(
                tone: RhInfoTone.mint,
                icon: ClIcons.check,
                label: l10n.rhBasedOnFeedback,
                text: usedText,
              ),
              const SizedBox(height: ClSpace.s2),
            ],
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
                    l10n.rhChangedTitle,
                    style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                  ),
                  RhBullets([
                    for (final c in rec.changes) changeLabel(l10n, c),
                  ], color: cl.colors.inkMuted),
                ],
              ),
            ),
            // PS02 footer: the person's own answers can be changed or deleted.
            if (canAct)
              Align(
                alignment: Alignment.centerLeft,
                child: RhLink(
                  label: l10n.rhEditHistoryLink,
                  muted: true,
                  start: true,
                  onTap: () => context.push(Routes.rhythmFeedbackHistory),
                ),
              ),
          ] else
            RhInfoBox(text: reasons.join(' ')),
          const SizedBox(height: ClSpace.s2),
          RhReviewNote(activity.review),
          if (canAct) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (started)
                  RhPillButton(
                    label: l10n.rhTellHow,
                    onTap: () =>
                        context.push(activityFeedbackLocation(activity.id)),
                  )
                else
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
          ] else ...[
            const SizedBox(height: ClSpace.s1),
            RhLink(label: l10n.rhHow, onTap: open),
          ],
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

/// "Hôm nay con có gì khác?" → C01 (Cùng nuôi, Người chăm sóc).
class _CheckInEntry extends StatelessWidget {
  const _CheckInEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return RhCard(
      onTap: () => context.push(Routes.rhythmCheckIn),
      semanticLabel: l10n.rhCheckInEntry,
      child: Row(
        children: [
          Expanded(child: Text(l10n.rhCheckInEntry, style: cl.text.bodyStrong)),
          ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
        ],
      ),
    );
  }
}

/// H01 age card: "3 tuần tuổi" pill, the card title, "Nội dung theo tuổi · luôn miễn phí".
class _AgeCardTile extends StatelessWidget {
  const _AgeCardTile({required this.card, this.ageLabel});
  final AgeCard card;
  final String? ageLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    return RhCard(
      onTap: () => context.push('${Routes.rhythmAge}/${card.id}'),
      semanticLabel: card.title.of(locale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ageLabel != null) ...[
            RhPill(label: ageLabel!, icon: ClIcons.cake),
            const SizedBox(height: ClSpace.s2),
          ],
          Text(card.title.of(locale), style: cl.text.bodyStrong),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.rhAgeFree,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// "LỊCH THAM KHẢO · Giai đoạn 1 (Wonder Weeks) dự kiến 11/10 – 18/10" (H01), or the one-line
/// strip under a suggestion (H02). Opens Nhịp lớn lên.
class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.line, required this.compact});
  final String line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final sleep = cl.care.sleep;
    return RhCard(
      color: sleep.soft,
      padding: EdgeInsets.all(compact ? ClSpace.s3 : ClSpace.s4),
      onTap: () => context.push(Routes.rhythm),
      semanticLabel: '${l10n.rhCalendarPill}. $line',
      child: compact
          ? Row(
              children: [
                ClIcon(ClIcons.clock, size: 16, color: sleep.ink),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Text(
                    line,
                    style: cl.text.label.copyWith(color: sleep.ink),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClIcon(ClIcons.clock, size: 12, color: sleep.ink),
                      const SizedBox(width: 4),
                      Text(
                        l10n.rhCalendarPill,
                        style: cl.text.caption.copyWith(
                          color: sleep.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  line,
                  style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                ),
              ],
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
      onTap: () => context.push(Routes.mePlan),
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
