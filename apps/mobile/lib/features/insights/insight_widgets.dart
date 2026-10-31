import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/cl_rows.dart';
import '../me/me_widgets.dart' show MeRow;
import '../adaptive/today_adaptive.dart' show AxCard;
import '../care/care_format.dart' show durationLabel;
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_v2.dart' show PremiumEntry;
import 'insight_models.dart';
import 'insight_repository.dart';

/// Hiểu con building blocks (Figma 1104:1883 AI01–AI05; D-150, D-151): the wording of an
/// insight, the two-week comparison chart, the Hôm nay card with its Free invite, and the line
/// Thống kê shows. Every number comes from the server's computation (insight_models.dart).

String insightTitle(AppLocalizations l10n, InsightKind kind, bool up) =>
    switch (kind) {
      InsightKind.nightLongest => up ? l10n.hcLongestUp : l10n.hcLongestDown,
      InsightKind.nightTotal => up ? l10n.hcTotalUp : l10n.hcTotalDown,
      InsightKind.nightFeeds => up ? l10n.hcFeedsUp : l10n.hcFeedsDown,
    };

/// A value of [kind] as people read it: "2 giờ 52 phút", "2 cữ", "1,4 cữ".
String insightAmount(
  AppLocalizations l10n,
  String locale,
  InsightKind kind,
  num value,
) {
  if (kind.isSleep) return durationLabel(l10n, value.round());
  final v = value.abs();
  return v == 1
      ? l10n.hcFeedOne
      : l10n.hcFeedMany(NumberFormat('#0.#', locale).format(v));
}

/// "TB 2 giờ 52 phút · tuần trước 2 giờ 21 phút".
String insightSummary(AppLocalizations l10n, String locale, Insight i) =>
    l10n.hcVsBefore(
      insightAmount(l10n, locale, i.kind, i.value),
      insightAmount(l10n, locale, i.kind, i.baselineValue),
    );

ClCareColor insightTone(ClTheme cl, InsightKind kind) =>
    kind.isSleep ? cl.care.sleep : cl.care.bottle;

ClIcons insightIcon(InsightKind kind) =>
    kind.isSleep ? ClIcons.sleep : ClIcons.feed;

void openInsight(BuildContext context, InsightKind kind) =>
    unawaited(context.push('${Routes.insights}/${kind.wire}'));

/// "+31 phút" in the care tone; read aloud as "dài hơn 31 phút" style words.
class InsightDeltaChip extends StatelessWidget {
  const InsightDeltaChip({required this.insight, super.key});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = insightAmount(l10n, locale, insight.kind, insight.delta);
    final tone = insightTone(cl, insight.kind);
    return Semantics(
      label: insight.up ? l10n.hcMore(amount) : l10n.hcLess(amount),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s2,
          vertical: ClSpace.s1,
        ),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Text(
          '${insight.up ? '+' : '−'}$amount',
          style: cl.text.label.copyWith(color: cl.colors.ink),
        ),
      ),
    );
  }
}

/// The two weeks side by side (AI01–AI03): the nights before in the soft tone, the recent ones
/// in the accent, each week's average as a dashed line; a night not counted is an outlined gap
/// (never a zero bar). Read aloud as one sentence.
class InsightChart extends StatelessWidget {
  const InsightChart({
    required this.insight,
    this.height = 64,
    this.averages = true,
    super.key,
  });

  final Insight insight;
  final double height;
  final bool averages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tone = insightTone(cl, insight.kind);
    final points = insight.points;
    final split = points.length - insight.totalNights;
    final top = math
        .max(
          points.fold<num>(0, (m, p) => math.max(m, p.value ?? 0)),
          math.max(insight.value, insight.baselineValue),
        )
        .toDouble();
    return Semantics(
      label: l10n.hcChartA11y(
        insightAmount(l10n, locale, insight.kind, insight.value),
        insightAmount(l10n, locale, insight.kind, insight.baselineValue),
        insight.validNights,
        insight.totalNights,
      ),
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: _ChartPainter(
            values: [for (final p in points) p.value?.toDouble()],
            split: split,
            top: top <= 0 ? 1 : top * 1.08,
            before: insight.baselineValue.toDouble(),
            recent: insight.value.toDouble(),
            averages: averages,
            soft: tone.soft,
            strong: tone.accent,
            line: cl.colors.inkMuted,
            gap: cl.colors.separator,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.split,
    required this.top,
    required this.before,
    required this.recent,
    required this.averages,
    required this.soft,
    required this.strong,
    required this.line,
    required this.gap,
  });

  final List<double?> values;
  final int split;
  final double top;
  final double before;
  final double recent;
  final bool averages;
  final Color soft, strong, line, gap;

  static const _space = 4.0;
  static const _weekGap = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final barW = (size.width - _space * (n - 2) - _weekGap) / n;
    if (barW <= 1) return;
    double x(int i) =>
        i * (barW + _space) + (i >= split ? _weekGap - _space : 0);
    final radius = Radius.circular(math.min(4, barW / 2));
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) {
        // A night not counted: an outlined stub at the base.
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x(i) + 1, size.height - 9, barW - 2, 8),
          radius,
        );
        canvas.drawRRect(
          r,
          Paint()
            ..color = gap
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        continue;
      }
      final h = math.max(4, size.height * v / top).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x(i), size.height - h, barW, h),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = i >= split ? strong : soft,
      );
    }
    if (!averages) return;
    void dashed(double from, double to, double value) {
      final y = size.height - size.height * value / top;
      final p = Paint()
        ..color = line
        ..strokeWidth = 1.2;
      for (var dx = from; dx < to; dx += 6) {
        canvas.drawLine(Offset(dx, y), Offset(math.min(dx + 3, to), y), p);
      }
    }

    dashed(0, x(split) - _weekGap + _space, before);
    dashed(x(split), size.width, recent);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values ||
      old.top != top ||
      old.soft != soft ||
      old.strong != strong ||
      old.line != line;
}

/// "▪ Tuần trước ▪ Gần đây … 6/7 đêm có ghi": colour never carries the series alone.
class InsightLegend extends StatelessWidget {
  const InsightLegend({required this.insight, super.key});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tone = insightTone(cl, insight.kind);
    final style = cl.text.caption.copyWith(color: cl.colors.inkMuted);
    Widget key(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: ClSpace.s1),
        Text(label, style: style),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: ClSpace.s3,
        runSpacing: ClSpace.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          key(tone.soft, l10n.hcLegendBefore),
          key(tone.accent, l10n.hcLegendRecent),
          Text(
            l10n.hcNightsLogged(insight.validNights, insight.totalNights),
            style: style,
          ),
        ],
      ),
    );
  }
}

/// AI01: the one insight Hôm nay shows today (D-151 #4), or, for a Free household, the invite
/// that names the kind without figures (D-151 #9). Nothing otherwise: no "nothing new" card.
class InsightTodayCard extends ConsumerWidget {
  const InsightTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(insightAccessProvider);
    if (access == InsightAccess.none) return const SizedBox.shrink();
    final view = ref.watch(insightViewProvider);
    if (view == null) return const SizedBox.shrink();
    if (access == InsightAccess.invite) {
      final kind = view.todayTeaser;
      return kind == null
          ? const SizedBox.shrink()
          : InsightInvite(kind: kind, babyName: view.babyName);
    }
    final item = view.todayItem;
    return item == null
        ? const SizedBox.shrink()
        : InsightTodayView(insight: item);
  }
}

class InsightTodayView extends StatelessWidget {
  const InsightTodayView({required this.insight, super.key});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = insightTitle(l10n, insight.kind, insight.up);
    final summary = insightSummary(l10n, locale, insight);
    final basis = l10n.hcBasedOn(insight.validNights, insight.totalNights);
    // D-151 #4: folded in Night care (logging comes first at 3 a.m.): no chart.
    final folded = cl.isNightCare;
    return Semantics(
      button: true,
      label: '${l10n.hcNotable}. $title. $summary. $basis',
      hint: l10n.hcOpen,
      excludeSemantics: true,
      child: ClPressable(
        key: const Key('insightToday'),
        onPressed: () => openInsight(context, insight.kind),
        child: AxCard(
          icon: insightIcon(insight.kind),
          chip: insightTone(cl, insight.kind).soft,
          title: title,
          subtitle: l10n.hcNotable,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                style: cl.text.body.copyWith(
                  color: cl.colors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!folded) ...[
                const SizedBox(height: ClSpace.s3),
                InsightChart(insight: insight, height: 40, averages: false),
              ],
              const SizedBox(height: ClSpace.s2),
              Text(
                basis,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// D-147 / D-151 #9: what changed, named by kind only, and the way to Premium.
class InsightInvite extends StatelessWidget {
  const InsightInvite({required this.kind, required this.babyName, super.key});

  final InsightKind kind;
  final String babyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return AxCard(
      key: const Key('insightInvite'),
      icon: insightIcon(kind),
      chip: insightTone(cl, kind).soft,
      title: l10n.hcNotable,
      subtitle: l10n.pmInPremium,
      link: l10n.pv2SeePremium,
      onLink: () => unawaited(
        openPaywall(
          context,
          entry: PaywallEntry.rhythm,
          card: PremiumEntry.rhythm,
        ),
      ),
      child: Text(
        kind.isSleep
            ? l10n.hcTeaserSleep(babyName)
            : l10n.hcTeaserFeeds(babyName),
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
    );
  }
}

/// AI05: the insight of this statistic, in context, opening its detail. Premium only (D-150);
/// nothing while stale or when there is none.
class InsightStatsLine extends ConsumerWidget {
  const InsightStatsLine({required this.sleep, super.key});

  /// Sleep statistics (S1, S2) or feeding (F3).
  final bool sleep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(insightAccessProvider) != InsightAccess.full) {
      return const SizedBox.shrink();
    }
    final items = ref.watch(insightViewProvider)?.items ?? const <Insight>[];
    final item = items.where((i) => i.kind.isSleep == sleep).firstOrNull;
    if (item == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tone = insightTone(cl, item.kind);
    final title = insightTitle(l10n, item.kind, item.up);
    final summary = insightSummary(l10n, locale, item);
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: ClPressable(
        key: const Key('insightStatsLine'),
        onPressed: () => openInsight(context, item.kind),
        semanticLabel: '$title. $summary',
        child: Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: tone.soft,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.spark, size: 18, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                    ),
                    Text(
                      summary,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI06 "Điều đáng chú ý nhất" in Tổng kết tuần: the top insight whose recent nights end in this
/// summary week [weekStart]–[weekEnd] (`yyyy-MM-dd`). Premium only; nothing otherwise.
class WeekInsightBlock extends ConsumerWidget {
  const WeekInsightBlock({
    required this.weekStart,
    required this.weekEnd,
    super.key,
  });

  final String weekStart;
  final String weekEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(insightAccessProvider) != InsightAccess.full) {
      return const SizedBox.shrink();
    }
    final items = ref.watch(insightViewProvider)?.items ?? const <Insight>[];
    final top = items.where((i) {
      final to = isoDay(i.recentTo);
      return to.compareTo(weekStart) >= 0 && to.compareTo(weekEnd) <= 0;
    }).firstOrNull;
    if (top == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      key: const Key('weekInsight'),
      padding: const EdgeInsets.only(bottom: ClSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSectionHeader(title: l10n.hcWeekNotable),
          const SizedBox(height: ClSpace.s3),
          ClCardGroup(
            children: [
              MeRow(
                icon: insightIcon(top.kind),
                iconTint: insightTone(cl, top.kind).soft,
                title: insightTitle(l10n, top.kind, top.up),
                subtitle: insightSummary(l10n, locale, top),
                onTap: () => openInsight(context, top.kind),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
