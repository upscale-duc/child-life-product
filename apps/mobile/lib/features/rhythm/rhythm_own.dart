import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_format.dart' show durationLabel;
import '../care/history_screen.dart' show weekdayShort;
import '../family/family_repository.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_gate.dart';
import '../premium/premium_widgets.dart' show PremiumExpiredStrip;
import '../premium/premium_models.dart';
import 'rhythm_access.dart';
import 'rhythm_calc.dart';
import 'rhythm_episodes.dart';
import 'rhythm_labels.dart';
import 'activity_history_screen.dart';
import 'rhythm_models.dart';
import 'rhythm_plans.dart' show triedEntries;
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
    final noted =
        canRead &&
        (ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[]).any(
          (c) => c.date == today && c.authorUid == me.uid,
        );

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
            // Owner, 2026-10-22: once this person noted today, the button says so and edits.
            if (noted)
              ClButton(
                label: l10n.rhEditToday,
                expand: true,
                style: ClButtonStyle.secondary,
                onPressed: () => context.push(Routes.rhythmCheckIn),
              )
            else
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

/// The last seven days of check-ins at a glance (owner, 2026-10-22: "xem 1 cách trực quan"):
/// one circle per day — mint ✓ for "Như mọi ngày", sunshine with the kind's icon for a change,
/// an empty ring for a day nobody noted; a day opens what was noted, by whom.
class RecentCheckIns extends ConsumerWidget {
  const RecentCheckIns({
    required this.me,
    required this.today,
    this.end,
    super.key,
  });

  final Membership me;
  final String today;

  /// The last of the seven days (a summary week's Sunday); today by default.
  final String? end;

  static ClIcons iconOf(Observation o) => switch (o) {
    Observation.sleep => ClIcons.sleep,
    Observation.feeding => ClIcons.feed,
    Observation.soothing => ClIcons.heart,
    Observation.newSkill => ClIcons.star,
    Observation.health => ClIcons.alert,
    Observation.usual => ClIcons.check,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final checkIns =
        ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[];
    final last = end ?? today;
    final days = [for (var i = 6; i >= 0; i--) addDaysIso(last, -i)];
    final byDay = <String, List<CheckIn>>{
      for (final d in days)
        d: [
          for (final c in checkIns)
            if (c.date == d && c.observation != Observation.health) c,
        ],
    };
    String weekday(String iso) =>
        weekdayShort(locale.toLanguageTag(), DateTime.parse(iso));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final d in days)
              Builder(
                builder: (context) {
                  final list = byDay[d]!;
                  final changed = list.where((c) => c.changed).toList();
                  final isToday = d == today;
                  final (fill, ink, icon) = list.isEmpty
                      ? (null, cl.colors.inkMuted, null)
                      : changed.isEmpty
                      ? (cl.colors.mintSoft, cl.colors.mintText, ClIcons.check)
                      // Ink on the soft warm fill, also in Night care.
                      : (
                          cl.colors.sunshineSoft,
                          cl.colors.ink,
                          iconOf(changed.first.observation),
                        );
                  final label = list.isEmpty
                      ? l10n.rhDayNotNoted
                      : {
                          for (final c in list)
                            observationShort(l10n, c.observation),
                        }.join(', ');
                  return ClPressable(
                    key: Key('checkInDay:$d'),
                    onPressed: list.isEmpty
                        ? null
                        : () => _showDay(context, ref, d, list),
                    semanticLabel: '${shortDay(locale, d)}: $label',
                    child: Column(
                      children: [
                        Text(
                          isToday ? l10n.rhTodayShort : weekday(d),
                          style: cl.text.caption.copyWith(
                            color: isToday ? cl.colors.ink : cl.colors.inkMuted,
                            fontWeight: isToday ? FontWeight.w700 : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: fill,
                            shape: BoxShape.circle,
                            border: fill == null
                                ? Border.all(
                                    color: cl.colors.separator,
                                    width: 1.5,
                                  )
                                : isToday
                                ? Border.all(
                                    color: cl.colors.mintDeep,
                                    width: 2,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: icon == null
                              ? null
                              : ClIcon(icon, size: 16, color: ink),
                        ),
                        // Two people noted different things: a small dot under the day.
                        if (observationStateOf(list) == ObservationState.mixed)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: cl.colors.inkMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 9),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        // The key, in one quiet line.
        Wrap(
          spacing: ClSpace.s3,
          children: [
            for (final (fill, text) in [
              (cl.colors.mintSoft, l10n.rhObsUsual),
              (cl.colors.sunshineSoft, l10n.rhLegendChanged),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// What was noted that day, by whom.
  Future<void> _showDay(
    BuildContext context,
    WidgetRef ref,
    String day,
    List<CheckIn> list,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final members =
        ref.read(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    return showClSheet<void>(
      context: context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          ClSpace.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(
              title: day == today ? l10n.todayLabel : longDay(locale, day),
            ),
            ClCardGroup(
              color: sheet.cl.colors.surface2,
              children: [
                for (final c in list)
                  ClListRow(
                    leading: RhInitial(
                      memberLabel(
                        l10n,
                        members.where((m) => m.uid == c.authorUid).firstOrNull,
                        myUid: '',
                        uid: c.authorUid,
                      ),
                    ),
                    title: checkInParts(l10n, c).join(' · '),
                    subtitle: [
                      capitalized(
                        memberLabel(
                          l10n,
                          members
                              .where((m) => m.uid == c.authorUid)
                              .firstOrNull,
                          myUid: me.uid,
                          uid: c.authorUid,
                        ),
                      ),
                      if (c.note case final n? when n.trim().isNotEmpty)
                        l10n.rhQuoted(n.trim()),
                    ].join(' · '),
                  ),
              ],
            ),
            if (observationStateOf(list) == ObservationState.mixed) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.rhMixedNote,
                style: sheet.cl.text.caption.copyWith(
                  color: sheet.cl.colors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
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
      // The bars count what the sentence asks for: the reference days while those are short,
      // else the recent days (owner, 2026-10-22: full bars beside "chưa đủ" contradicted it).
      final need = baselineShort ? rules.baselineMinDays : rules.recentMinDays;
      final filled = math.min(
        baselineShort ? r.validBaselineDays : r.validRecentDays,
        need,
      );
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
              label: '$filled/$need',
              child: Row(
                children: [
                  for (var i = 0; i < need; i++) ...[
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
            // Owner, 2026-10-22: the count the bars show, in a few words.
            Text(
              l10n.rhSleepSparseShort(filled, need),
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

/// NL01 "Cách nhà mình đã thử": the newest tries (a plan and its answers, D-076 #10), each with
/// who and what is open, and "Xem tất cả" → "Các cách đã thử".
class TriedSection extends ConsumerWidget {
  const TriedSection({required this.me, super.key});
  final Membership me;

  static const maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final entries = triedEntries(
      ref.watch(recFeedbackProvider(me.babyId)).value ?? const <RecFeedback>[],
    );
    if (entries.isEmpty) return const SizedBox.shrink();
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
              for (final (i, e) in entries.take(maxRows).indexed) ...[
                if (i > 0) Container(height: 1, color: cl.colors.separator),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
                  child: TriedEntryCard(
                    me: me,
                    entry: e,
                    entries: entries,
                    compact: true,
                  ),
                ),
              ],
            ],
          ),
        ),
        const TriedHistoryLink(),
      ],
    );
  }
}
