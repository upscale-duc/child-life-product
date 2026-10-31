import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_entry.dart' show assistantAccessProvider;
import '../assistant/assistant_models.dart' show AssistantScope, IntentHint;
import '../assistant/assistant_screens.dart' show openAssistant;
import '../baby/baby_repository.dart';
import '../care/care_calc.dart' show careNightFromHour, careNightToHour;
import '../care/care_format.dart' show careTypeLabel, durationLabel;
import '../care/care_models.dart' show CareType;
import '../care/care_repository.dart';
import '../care/history_screen.dart' show HistoryFilter;
import '../care/visit_report.dart' show perDay, visitWeeks;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../premium/premium_v2.dart' show PremiumEntry;
import '../rhythm/rhythm_calc.dart' show defaultRhythmRules;
import '../rhythm/rhythm_labels.dart' show shortDay;
import '../rhythm/rhythm_repository.dart' show babyTodayIso;
import '../rhythm/rhythm_week.dart' show weekFacts;
import '../rhythm/week_screen.dart' show WeekSummaryEntry;
import 'insight_models.dart';
import 'insight_repository.dart';
import 'insight_widgets.dart';

/// AI02 / AI04 "Hiểu con" (Figma 1104:1883; D-150 Premium, D-151): what changed in the nights
/// lately with its basis, the per-activity averages of the last 7 complete days, the week's
/// summary. The figures are the server's (insight_models.dart); a Free household's reader sees
/// the Premium invite (D-147).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final access = ref.watch(insightAccessProvider);
    final me = ref.watch(selectedMembershipProvider);
    if (access != InsightAccess.full || me == null) {
      return MePage(
        title: l10n.hcTitle,
        children: [
          if (access == InsightAccess.invite)
            MeNotice(
              key: const Key('insightsInvite'),
              icon: ClIcons.spark,
              title: l10n.pmInPremium,
              body: l10n.hcSparseBody,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClButton(
                  label: l10n.pv2SeePremium,
                  style: ClButtonStyle.tinted,
                  onPressed: () => unawaited(
                    openPaywall(
                      context,
                      entry: PaywallEntry.rhythm,
                      card: PremiumEntry.rhythm,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final async = ref.watch(insightStateProvider(me.babyId));
    final view = ref.watch(insightViewProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final hm = DateFormat.Hm(locale);

    final children = <Widget>[
      if (view != null)
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s4),
          child: Text(
            l10n.hcUpdated(hm.format(inBabyZone(zone, view.state.computedAt))),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      if (async.isLoading && view == null) ...[
        const ClSkeleton(height: 220, radius: ClRadius.card),
        const SizedBox(height: ClSpace.s4),
      ] else if (view != null && view.stale)
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s4),
          child: MeNotice(
            key: const Key('insightsStale'),
            icon: ClIcons.clock,
            title: l10n.hcUpdating,
            body: l10n.hcUpdatingBody,
          ),
        )
      else if (view == null || !view.state.enoughNights)
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s4),
          child: InsightSparseCard(
            validNights: view?.state.validNights ?? 0,
            neededNights: view?.state.neededNights ?? 5,
            babyName: view?.babyName ?? '',
          ),
        )
      else if (view.items.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s4),
          child: MeNotice(
            key: const Key('insightsNothing'),
            title: l10n.hcNothing,
          ),
        )
      else ...[
        ClSectionHeader(title: l10n.hcNotable),
        const SizedBox(height: ClSpace.s2),
        InsightHero(insight: view.items.first),
        if (view.items.length > 1) ...[
          const SizedBox(height: ClSpace.s3),
          ClCardGroup(
            children: [
              for (final i in view.items.skip(1))
                MeRow(
                  icon: insightIcon(i.kind),
                  iconTint: insightTone(cl, i.kind).soft,
                  title: insightTitle(l10n, i.kind, i.up),
                  subtitle: insightSummary(l10n, locale, i),
                  onTap: () => openInsight(context, i.kind),
                ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s6),
      ],
      const _ByActivity(),
      if (ref.watch(selectedCapabilitiesProvider)?.features.rhythm ??
          false) ...[
        const SizedBox(height: ClSpace.s4),
        WeekSummaryEntry(me: me),
      ],
      const SizedBox(height: ClSpace.s6),
      Text(
        l10n.hcDisclaimer,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    ];
    return MePage(title: l10n.hcTitle, children: children);
  }
}

/// The lead insight: title, the recent average large with its change, the summary, the chart.
class InsightHero extends StatelessWidget {
  const InsightHero({required this.insight, super.key});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = insightTitle(l10n, insight.kind, insight.up);
    return ClPressable(
      key: const Key('insightHero'),
      onPressed: () => openInsight(context, insight.kind),
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconChip(kind: insight.kind),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                  ),
                ),
                ClIcon(
                  ClIcons.chevronRight,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            _BigValue(insight: insight),
            const SizedBox(height: ClSpace.s1),
            Text(
              l10n.hcAvgRecent(
                insight.validNights,
                insightAmount(
                  l10n,
                  locale,
                  insight.kind,
                  insight.baselineValue,
                ),
              ),
              style: cl.text.caption.copyWith(
                color: cl.colors.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            InsightChart(insight: insight, height: 64),
            const SizedBox(height: ClSpace.s2),
            InsightLegend(insight: insight),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.kind});
  final InsightKind kind;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s2),
      decoration: BoxDecoration(
        color: insightTone(cl, kind).soft,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: ClIcon(insightIcon(kind), size: 20, color: cl.colors.ink),
    );
  }
}

/// "2 giờ 52 phút  +31 phút".
class _BigValue extends StatelessWidget {
  const _BigValue({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          insightAmount(l10n, locale, insight.kind, insight.value),
          style: cl.text.title2.copyWith(
            color: cl.colors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        InsightDeltaChip(insight: insight),
      ],
    );
  }
}

/// AI04: not enough logged nights yet. Progress and what to do, no comparison.
class InsightSparseCard extends StatelessWidget {
  const InsightSparseCard({
    required this.validNights,
    required this.neededNights,
    required this.babyName,
    super.key,
  });

  final int validNights;
  final int neededNights;
  final String babyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final filled = math.min(validNights, neededNights);
    return Container(
      key: const Key('insightsSparse'),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.hcSparseTitle(babyName),
            style: cl.text.headline.copyWith(color: cl.colors.ink),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.hcSparseBody,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          Row(
            children: [
              ClIcon(ClIcons.sleep, size: 18, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.hcSparseProgress(filled, neededNights),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Semantics(
            label: l10n.hcSparseProgress(filled, neededNights),
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < neededNights; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < filled
                            ? cl.care.sleep.accent
                            : cl.colors.separator,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Theo từng việc": per-day averages over the last 7 complete days, the visit report's own
/// arithmetic (`weekFacts`): sleep on valid days only, bottle ml apart from breast minutes.
class _ByActivity extends ConsumerWidget {
  const _ByActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider)!;
    final records = ref.watch(recentRecordsProvider(me.babyId)).value;
    if (records == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final f = weekFacts(
      zone: zone,
      week: visitWeeks(babyTodayIso(zone, now)).recent,
      now: now,
      records: records,
      rules: defaultRhythmRules,
    );
    final sleep = switch (f.averageSleepMinutes) {
      final m? => l10n.hcSleepPerDay(durationLabel(l10n, m)),
      null => l10n.vrSleepSparse,
    };
    // Missing is never zero: a week without a record says so.
    final feeds = f.feeds == 0
        ? l10n.hcNoLogs7
        : [
            l10n.hcFeedsPerDay(perDay(locale, f.feeds)),
            if (f.bottleMl > 0)
              l10n.hcBottlePerDay(
                perDay(locale, f.bottleMl).split(RegExp('[.,]')).first,
              ),
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.hcByActivity),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.sleep,
              iconTint: cl.care.sleep.soft,
              title: l10n.hcSleep,
              subtitle: sleep,
              onTap: () => unawaited(context.push('/care/stats/sleep')),
            ),
            MeRow(
              icon: ClIcons.feed,
              iconTint: cl.care.bottle.soft,
              title: l10n.hcFeeds,
              subtitle: feeds,
              onTap: () => unawaited(context.push('/care/stats/feed')),
            ),
            MeRow(
              icon: ClIcons.diaper,
              iconTint: cl.care.diaper.soft,
              title: careTypeLabel(l10n, CareType.diaper),
              subtitle: f.diapers == 0
                  ? l10n.hcNoLogs7
                  : l10n.hcDiapersPerDay(perDay(locale, f.diapers)),
              onTap: () => unawaited(
                context.push(
                  '${Routes.history}?filter=${HistoryFilter.diaper.name}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// AI03: one insight with everything it stands on.
class InsightDetailScreen extends ConsumerWidget {
  const InsightDetailScreen({required this.kind, super.key});

  final InsightKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final view = ref.watch(insightViewProvider);
    final full = ref.watch(insightAccessProvider) == InsightAccess.full;
    final me = ref.watch(selectedMembershipProvider);
    final insight = full ? view?.item(kind) : null;
    if (insight == null || view!.stale) {
      return MePage(
        title: l10n.hcTitle,
        children: [
          if (view?.stale ?? false)
            MeNotice(
              key: const Key('insightStale'),
              icon: ClIcons.clock,
              title: l10n.hcUpdating,
              body: l10n.hcUpdatingBody,
            )
          else
            MeNotice(title: l10n.hcNothing),
        ],
      );
    }
    String day(DateTime d) => shortDay(locale, isoDay(d));
    final range = l10n.rhDateRange(
      day(insight.recentFrom),
      day(insight.recentTo),
    );
    final leftOut = insight.leftOut;
    final hour = NumberFormat('00');
    final measure = switch (kind) {
      InsightKind.nightLongest => l10n.hcMeasureLongest,
      InsightKind.nightTotal => l10n.hcMeasureTotal,
      InsightKind.nightFeeds => l10n.hcMeasureFeeds,
    };
    return MePage(
      title: insightTitle(l10n, kind, insight.up),
      children: [
        Text(
          l10n.hcKicker(kind.isSleep ? l10n.hcSleep : l10n.hcFeeds, range),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BigValue(insight: insight),
              const SizedBox(height: ClSpace.s1),
              Text(
                l10n.hcAvgRecent(
                  insight.validNights,
                  insightAmount(l10n, tag, kind, insight.baselineValue),
                ),
                style: cl.text.caption.copyWith(
                  color: cl.colors.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              InsightChart(insight: insight, height: 96),
              const SizedBox(height: ClSpace.s2),
              InsightLegend(insight: insight),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(title: l10n.hcBasis),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.check,
              title: l10n.hcNightsLogged(
                insight.validNights,
                insight.totalNights,
              ),
              subtitle: leftOut.isEmpty
                  ? null
                  : l10n.hcLeftOut(leftOut.map(day).join(', ')),
            ),
            MeRow(
              icon: ClIcons.clock,
              title: l10n.hcNightWindow(
                '${hour.format(careNightFromHour)}:00',
                '${hour.format(careNightToHour)}:00',
              ),
              subtitle: measure,
            ),
            MeRow(
              icon: ClIcons.chart,
              title: l10n.hcComparedWith(insight.totalNights),
              subtitle: l10n.rhDateRange(
                day(insight.baselineFrom),
                day(insight.baselineTo),
              ),
            ),
            if (insight.authors.isNotEmpty)
              MeRow(
                icon: ClIcons.family,
                title: l10n.hcLoggedBy(insight.authors.join(', ')),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          key: const Key('insightStats'),
          label: kind.isSleep ? l10n.hcSeeSleepStats : l10n.hcSeeFeedStats,
          expand: true,
          wrapLabel: true,
          onPressed: () => unawaited(
            context.push(
              kind.isSleep ? '/care/stats/sleep' : '/care/stats/feed',
            ),
          ),
        ),
        // D-151 #7: Lumi explains it from this evidence (the rule path, 0 credits).
        if (me != null &&
            ref.watch(assistantAccessProvider(me.babyId)) != null) ...[
          const SizedBox(height: ClSpace.s3),
          ClButton(
            key: const Key('insightAskLumi'),
            label: l10n.hcAskLumi,
            style: ClButtonStyle.tinted,
            icon: ClIcons.spark,
            expand: true,
            wrapLabel: true,
            onPressed: () => unawaited(
              openAssistant(
                context,
                AssistantScope.child(me.babyId),
                prefill: kind.isSleep
                    ? l10n.hcAskLumiSleep
                    : l10n.hcAskLumiFeeds,
                hint: IntentHint.question,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.hcAskLumiNote,
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        if (me != null) ...[
          const SizedBox(height: ClSpace.s6),
          _Feedback(insight: insight, uid: me.uid, babyId: me.babyId),
        ],
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.hcDisclaimer,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// D-151: "Thông tin này có ích không?" per person; "Không hiện loại thông tin này nữa" hides the
/// kind for this person everywhere (undo in the toast).
class _Feedback extends ConsumerWidget {
  const _Feedback({
    required this.insight,
    required this.uid,
    required this.babyId,
  });

  final Insight insight;
  final String uid;
  final String babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final prefs =
        ref.watch(insightPrefsProvider((uid, babyId))).value ??
        const InsightPrefs();
    InsightPrefsRepository repo() => ref.read(insightPrefsRepositoryProvider);
    final vote = prefs.voteFor(insight);
    Widget choice(bool helpful, String label) => Expanded(
      child: ClButton(
        key: Key(helpful ? 'insightHelpful' : 'insightNotHelpful'),
        label: label,
        style: vote == helpful ? ClButtonStyle.tinted : ClButtonStyle.secondary,
        icon: vote == helpful ? ClIcons.check : null,
        expand: true,
        wrapLabel: true,
        onPressed: () {
          unawaited(repo().vote(uid, babyId, prefs, insight, helpful));
          showClToast(context, message: l10n.hcThanks);
        },
      ),
    );
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.hcFeedbackTitle,
            style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              choice(true, l10n.hcHelpful),
              const SizedBox(width: ClSpace.s2),
              choice(false, l10n.hcNotHelpful),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              key: const Key('insightMute'),
              label: l10n.hcMute,
              style: ClButtonStyle.plain,
              wrapLabel: true,
              onPressed: () {
                final kind = insight.kind;
                unawaited(repo().setMuted(uid, babyId, prefs, kind, true));
                final router = GoRouter.of(context);
                showClToast(
                  context,
                  message: l10n.hcMuted,
                  actionLabel: l10n.undo,
                  onAction: () => unawaited(
                    ref
                        .read(insightPrefsRepositoryProvider)
                        .setMuted(uid, babyId, prefs, kind, false),
                  ),
                );
                if (router.canPop()) router.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
