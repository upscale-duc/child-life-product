import 'dart:math' as math;

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
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_format.dart' show durationLabel;
import '../family/family_repository.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_gate.dart';
import '../premium/premium_widgets.dart' show PremiumExpiredStrip;
import '../premium/premium_models.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_episodes.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// NL01's "NHỊP RIÊNG CỦA CON" layer (mint), drawn from what the family logged: the recent
/// check-ins with their authors (a day where two people noted different things keeps both, X03),
/// and with `rhythm.advanced` the sleep comparison of NL07 computed on this phone (B01–B06 over
/// automatic valid days, D-073 #1). Without it the gate is explained by its reason; nothing fake
/// is blurred behind it. Facts, never a diagnosis.
class OwnRhythmCard extends ConsumerWidget {
  const OwnRhythmCard({
    required this.me,
    required this.caps,
    required this.zone,
    required this.today,
    super.key,
  });

  final Membership me;
  final Capabilities? caps;
  final String zone;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final canRead = familyCan(me, FamilyAction.historyRead);
    final canCheckIn = familyCan(me, FamilyAction.rhythmCheckin);
    final advanced = caps?.allows(Capability.rhythmAdvanced) ?? false;
    final summary = canRead && advanced
        ? ref.watch(
            sleepSummaryProvider((babyId: me.babyId, zone: zone, today: today)),
          )
        : null;
    final sparse = summary?.result.status == SleepStatus.insufficientData;

    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RhLayerPill(
            label: sparse ? l10n.rhOwnSparsePill : l10n.rhOwnPill,
            calendar: false,
          ),
          const SizedBox(height: ClSpace.s2),
          Semantics(
            header: true,
            child: Text(l10n.rhOwnTitle, style: cl.text.headline),
          ),
          const SizedBox(height: ClSpace.s3),
          if (!canRead)
            Text(
              l10n.rhOwnNoAccess,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            )
          else ...[
            // PR04: the plan ended, history stays (593:6990).
            if (caps?.plan == HouseholdPlan.expired) ...[
              PremiumExpiredStrip(canRenew: caps!.canManageBilling),
              const SizedBox(height: ClSpace.s3),
            ],
            RecentCheckIns(me: me, today: today),
            // NL07b: the open observation episode, or the suggestion to group recent days.
            EpisodeBlock(me: me, today: today),
            const SizedBox(height: ClSpace.s3),
            if (advanced)
              summary == null
                  ? const ClSkeleton(height: 96)
                  : SleepFactsBlock(summary: summary, today: today)
            else
              _SleepGate(
                reason:
                    caps?.reasonFor(Capability.rhythmAdvanced) ??
                    GateReason.premiumRequired,
              ),
          ],
          if (canCheckIn) ...[
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.rhRecordToday,
              expand: true,
              onPressed: () => context.push(Routes.rhythmCheckIn),
            ),
          ],
        ],
      ),
    );
  }
}

/// The last week's check-ins, newest day first, with who noted them; a mixed day says so.
class RecentCheckIns extends ConsumerWidget {
  const RecentCheckIns({
    required this.me,
    required this.today,
    this.days = 3,
    super.key,
  });

  final Membership me;
  final String today;

  /// How many days with notes to show.
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final checkIns =
        ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[];
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final since = addDaysIso(today, -6);
    final byDay = <String, List<CheckIn>>{};
    for (final c in checkIns) {
      // Health worries are routed to HL01, not summed up here.
      if (c.date.compareTo(since) < 0 || c.observation == Observation.health) {
        continue;
      }
      (byDay[c.date] ??= []).add(c);
    }
    final dates = (byDay.keys.toList()..sort((a, b) => b.compareTo(a)))
        .take(days)
        .toList();
    if (dates.isEmpty) {
      return Text(
        l10n.rhOwnEmpty,
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      );
    }
    var anyMixed = false;
    final rows = <Widget>[];
    for (final date in dates) {
      final day = byDay[date]!;
      final mixed = observationStateOf(day) == ObservationState.mixed;
      anyMixed |= mixed;
      for (final (i, c) in day.indexed) {
        final m = members.where((x) => x.uid == c.authorUid).firstOrNull;
        final who = capitalized(
          memberLabel(l10n, m, myUid: me.uid, uid: c.authorUid),
        );
        // The avatar shows the family label (Mẹ, Ba, Cô Lan), also for me.
        final initial = memberLabel(l10n, m, myUid: '', uid: c.authorUid);
        final when = c.date == today
            ? l10n.rhSinceToday
            : shortDay(locale, c.date);
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: Row(
              children: [
                RhInitial(initial),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkInParts(l10n, c).join(' · '),
                        style: cl.text.label.copyWith(
                          color: cl.colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.rhWhoDay(who, when),
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mixed && i == 0) RhPill(label: l10n.rhMixedDay),
              ],
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows,
        if (anyMixed)
          Text(
            l10n.rhMixedNote,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
      ],
    );
  }
}

/// Rounds a difference to 10 minutes for "khoảng 2 giờ".
int _roughMinutes(double minutes) =>
    math.max(10, (minutes.abs() / 10).round() * 10);

/// NL07 "Tổng ngủ được ghi": the chart of the last days (invalid days as stubs, the recent
/// window darker, the usual level as a line), the fact sentence and its basis; or NL01b's
/// honest "not enough data" with the automatic count of valid days.
class SleepFactsBlock extends StatelessWidget {
  const SleepFactsBlock({
    required this.summary,
    required this.today,
    super.key,
  });

  final SleepSummary summary;
  final String today;

  static const chartDays = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final r = summary.result;
    if (r.status == SleepStatus.insufficientData) {
      const rules = defaultRhythmRules;
      final baselineShort = r.validBaselineDays < rules.baselineMinDays;
      final filled = math.min(r.validBaselineDays, rules.baselineMinDays);
      return Container(
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
              l10n.rhSleepSparseTitle,
              style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: ClSpace.s2),
            Semantics(
              label: '$filled/${rules.baselineMinDays}',
              child: Row(
                children: [
                  for (var i = 0; i < rules.baselineMinDays; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < filled
                              ? cl.colors.mintDeep
                              : cl.colors.separator,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              baselineShort
                  ? l10n.rhSleepSparseBody(
                      r.validBaselineDays,
                      rules.baselineMinDays,
                      rules.baselineMinDays - r.validBaselineDays,
                    )
                  : l10n.rhSleepSparseRecent(
                      rules.recentMinDays,
                      rules.recentDays,
                    ),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      );
    }

    final days = summary.days.sublist(
      math.max(0, summary.days.length - chartDays),
    );
    final recent = summary.recentDates.toSet();
    final baseline = r.baseline!;
    final top = math.max(
      baseline * 1.25,
      days.fold<int>(0, (m, d) => d.valid ? math.max(m, d.sleepMinutes) : m) *
          1.05,
    );
    const chartHeight = 96.0;
    final delta = r.delta!;
    final fact = r.status == SleepStatus.noChange
        ? l10n.rhSleepSame
        : delta < 0
        ? l10n.rhSleepLower(durationLabel(l10n, _roughMinutes(delta)))
        : l10n.rhSleepHigher(durationLabel(l10n, _roughMinutes(delta)));
    final usual = durationLabel(l10n, _roughMinutes(baseline));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.sleep, size: 16, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.rhSleepHeading(days.length),
                  style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          ExcludeSemantics(
            child: SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, d) in days.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: d.valid
                                ? math.max(
                                    4,
                                    chartHeight * d.sleepMinutes / top,
                                  )
                                : 6,
                            decoration: BoxDecoration(
                              color: !d.valid
                                  ? cl.colors.separator
                                  : recent.contains(d.date)
                                  ? cl.colors.mintDeep
                                  : cl.colors.mintDeep.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: chartHeight * baseline / top,
                    child: Container(height: 1.5, color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Wrap(
            spacing: ClSpace.s3,
            runSpacing: 4,
            children: [
              _Legend(
                swatch: Container(
                  width: 14,
                  height: 2,
                  color: cl.colors.inkMuted,
                ),
                label: l10n.rhSleepUsual(usual),
              ),
              _Legend(
                swatch: Container(
                  width: 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cl.colors.separator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                label: l10n.rhSleepMissingLegend,
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Text(fact, style: cl.text.label.copyWith(color: cl.colors.ink)),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.rhSleepBasis(
              r.validRecentDays,
              l10n.rhDateRange(
                shortDay(locale, summary.recentDates.first),
                shortDay(locale, summary.recentDates.last),
              ),
              r.validBaselineDays,
            ),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});
  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
      ],
    );
  }
}

/// Without `rhythm.advanced`: why, by its reason. Only PREMIUM_REQUIRED leads to the plan;
/// every other reason is explained ([showGateSheet]), never sold.
class _SleepGate extends StatelessWidget {
  const _SleepGate({required this.reason});
  final GateReason reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final premium = reason == GateReason.premiumRequired;
    return RhInfoBox(
      icon: ClIcons.sleep,
      label: l10n.rhSleepGateTitle,
      text: premium ? l10n.rhSleepGatePremium : l10n.rhSleepGateOther,
      child: Align(
        alignment: Alignment.centerLeft,
        child: RhLink(
          label: premium ? l10n.rhLearnMore : l10n.rhWhy,
          onTap: () => premium
              ? openPaywall(context, entry: PaywallEntry.rhythm)
              : showGateSheet(context, reason),
        ),
      ),
    );
  }
}

/// "Cách nhà mình đã thử": the latest answer per activity (put-offs left out), newest first.
class TriedSection extends ConsumerWidget {
  const TriedSection({required this.me, super.key});
  final Membership me;

  static const maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final feedback =
        ref.watch(recFeedbackProvider(me.babyId)).value ??
        const <RecFeedback>[];
    final content = ref.watch(rhythmContentProvider).value;
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final seen = <String>{};
    final rows = <RecFeedback>[
      for (final f in feedback)
        if (f.kind != FeedbackKind.notToday && seen.add(f.contentId)) f,
    ].take(maxRows).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.rhTriedHeading),
        const SizedBox(height: ClSpace.s2),
        RhCard(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s2,
          ),
          child: Column(
            children: [
              for (final (i, f) in rows.indexed) ...[
                if (i > 0) Container(height: 1, color: cl.colors.separator),
                _TriedRow(
                  feedback: f,
                  title:
                      content?.activity(f.contentId)?.title.of(locale) ??
                      l10n.rhUnknownActivity,
                  who: capitalized(
                    memberLabel(
                      l10n,
                      members.where((m) => m.uid == f.authorUid).firstOrNull,
                      myUid: me.uid,
                      uid: f.authorUid,
                    ),
                  ),
                  onTap: content?.activity(f.contentId) == null
                      ? null
                      : () => context.push(activityLocation(f.contentId)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TriedRow extends StatelessWidget {
  const _TriedRow({
    required this.feedback,
    required this.title,
    required this.who,
    this.onTap,
  });

  final RecFeedback feedback;
  final String title;
  final String who;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final kind = feedback.kind == FeedbackKind.started
        ? l10n.rhStartedLabel
        : feedbackKindLabel(l10n, feedback.kind);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: cl.text.label.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.rhWhoDay(who, shortDay(locale, feedback.date)),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          RhPill(label: kind, mint: feedback.kind == FeedbackKind.helpful),
        ],
      ),
    );
    return onTap == null
        ? MergeSemantics(child: row)
        : ClPressable(
            onPressed: onTap,
            pressedOpacity: ClPressable.surfaceOpacity,
            semanticLabel: '$title, $who, $kind',
            child: row,
          );
  }
}
