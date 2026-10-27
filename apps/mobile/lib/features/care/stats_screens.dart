import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart' show ClSkeleton;
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import 'care_calc.dart';
import 'care_format.dart';
import 'care_models.dart';
import 'care_repository.dart';
import 'care_screens.dart' show CareLoadFailed;
import 'history_screen.dart' show CareDaysTimeline, weekdayShort;
import 'stacked_days_chart.dart';
import '../solids/solids_calc.dart';
import '../solids/solids_format.dart' show sdShortDate;
import '../solids/solids_state.dart';

/// "Hôm nay · 7 ngày · 30 ngày" — remembered per screen ("Remembers the last choice").
final _windowProvider = NotifierProvider.family<_Window, StatsWindow, String>(
  _Window.new,
);

class _Window extends Notifier<StatsWindow> {
  _Window(this.screen);
  final String screen;

  @override
  StatsWindow build() =>
      StatsWindow.values.asNameMap()[ref
          .read(sharedPreferencesProvider)
          .getString('stats.$screen.window')] ??
      StatsWindow.week;

  void set(StatsWindow w) {
    ref
        .read(sharedPreferencesProvider)
        .setString('stats.$screen.window', w.name);
    state = w;
  }
}

/// 20g "Loại bú" (v1.0 improvement 391:3185), remembered like the window.
final _feedKindProvider = NotifierProvider<_FeedKindNotifier, FeedKind>(
  _FeedKindNotifier.new,
);

class _FeedKindNotifier extends Notifier<FeedKind> {
  @override
  FeedKind build() =>
      FeedKind.values.asNameMap()[ref
          .read(sharedPreferencesProvider)
          .getString('stats.feed.kind')] ??
      FeedKind.all;

  void set(FeedKind k) {
    ref.read(sharedPreferencesProvider).setString('stats.feed.kind', k.name);
    state = k;
  }
}

/// 20g "Tuỳ chọn" (391:3373): a custom range for this visit; null = the window above.
final _feedCustomProvider = NotifierProvider<_FeedCustom, CustomRange?>(
  _FeedCustom.new,
);

class _FeedCustom extends Notifier<CustomRange?> {
  @override
  CustomRange? build() => null;

  // ignore: use_setters_to_change_properties
  void set(CustomRange? r) => state = r;
}

/// "2g 50p" — the compact form the stats screens use (20g, 20h).
String compactDuration(AppLocalizations l10n, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return l10n.durationMinutes(m);
  return m == 0 ? l10n.compactH(h) : l10n.compactHM(h, m);
}

String _windowLabel(AppLocalizations l10n, StatsWindow w) => switch (w) {
  StatsWindow.today => l10n.windowToday,
  StatsWindow.week => l10n.window7,
  StatsWindow.month => l10n.window30,
};

/// Common frame: back, baby, title, the window segmented and the cards.
class _StatsFrame extends ConsumerWidget {
  const _StatsFrame({
    required this.title,
    required this.screen,
    required this.builder,
    this.controls,
    this.custom,
  });

  final String title;
  final String screen;

  /// Replaces the window segmented (20g's type and range pills).
  final Widget Function(BuildContext context, String zone, DateTime now)?
  controls;

  /// A custom range reaching further back than 30 days.
  final CustomRange? custom;
  final List<Widget> Function(
    BuildContext context,
    StatsWindow window,
    List<CareRecord> records,
    String zone,
    DateTime now,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now =
        ref.watch(careClockProvider).value ?? ref.read(timerClockProvider)();
    final window = ref.watch(_windowProvider(screen));
    final today = babyDayBounds(zone, now);
    // 30 days plus the evening before (Hôm nay starts at 18:00 yesterday), or the custom range.
    final start = custom == null
        ? today.start
        : windowDays(zone, custom!.end, custom!.days).first.start;
    final from = DateTime.fromMillisecondsSinceEpoch(
      start.millisecondsSinceEpoch -
          Duration(days: custom == null ? 31 : 1).inMilliseconds,
      isUtc: true,
    );
    final recordsAsync = ref.watch(
      rangeRecordsProvider((me.babyId, from, today.end)),
    );
    final records = recordsAsync.value ?? const <CareRecord>[];
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: () => context.pop(),
                trailing: baby == null
                    ? null
                    : ClBabySwitcher(
                        label: baby.nickname,
                        avatar: SavedBabyAvatar(baby: baby, size: 32),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClTabDock.contentBottomPadding + ClSpace.s6,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: cl.text.largeTitle),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  if (controls != null)
                    controls!(context, zone, now)
                  else
                    ClSegmented<StatsWindow>(
                      options: StatsWindow.values,
                      selected: window,
                      labelOf: (w) => _windowLabel(l10n, w),
                      onChanged: (w) =>
                          ref.read(_windowProvider(screen).notifier).set(w),
                    ),
                  const SizedBox(height: ClSpace.s4),
                  // Zeros before the first value would read as "nothing logged".
                  if (recordsAsync.hasValue)
                    ...builder(context, window, records, zone, now)
                  // SY-2: a failed query says so, never an endless skeleton.
                  else if (recordsAsync.hasError)
                    CareLoadFailed(
                      onRetry: () => ref.invalidate(
                        rangeRecordsProvider((me.babyId, from, today.end)),
                      ),
                    )
                  else
                    const _StatsSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The stats while their records load: three tiles and a chart card, shaped like the result.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: AppLocalizations.of(context).careLoadingRecords,
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: ClSkeleton(height: 64, radius: ClRadius.control)),
              SizedBox(width: ClSpace.s2),
              Expanded(child: ClSkeleton(height: 64, radius: ClRadius.control)),
              SizedBox(width: ClSpace.s2),
              Expanded(child: ClSkeleton(height: 64, radius: ClRadius.control)),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClSpace.s4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.card),
              boxShadow: cl.shadows.card,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClSkeleton(width: 140, height: 18),
                SizedBox(height: ClSpace.s2),
                ClSkeleton(width: 180, height: 12),
                SizedBox(height: ClSpace.s4),
                ClSkeleton(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis(this.items);
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        for (final (i, (value, label)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.control),
                boxShadow: cl.shadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: cl.text.headline.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      margin: const EdgeInsets.only(top: ClSpace.s4),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: cl.text.headline)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          const SizedBox(height: ClSpace.s3),
          ...children,
        ],
      ),
    );
  }
}

/// Two-part ratio bar with legend (day / night, left / right).
class _Ratio extends StatelessWidget {
  const _Ratio({required this.parts});

  /// (colour, label, percent, detail)
  final List<(Color, String, int, String)> parts;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final total = parts.fold(0, (s, p) => s + p.$3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, p) in parts.indexed) ...[
                  if (i > 0) Container(width: 2, color: cl.colors.surface),
                  Expanded(
                    flex: math.max(1, total == 0 ? 1 : p.$3),
                    child: ColoredBox(
                      color: total == 0 ? cl.colors.surface2 : p.$1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            for (final p in parts)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.$1,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${p.$2} ',
                                  style: cl.text.label,
                                ),
                                TextSpan(
                                  text: '${p.$3}%',
                                  style: cl.text.bodyStrong,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            p.$4,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight(this.text, {this.color, this.ink});
  final String text;
  final Color? color;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: ClSpace.s3),
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontSize: 13,
          color: ink ?? cl.colors.ink,
        ),
      ),
    );
  }
}

int _pct(int part, int total) => total == 0 ? 0 : (part * 100 / total).round();

/// 20g / 20g2 Thống kê bú (109:10562, 110:10949); 30 ngày per D-028.
class FeedStatsScreen extends ConsumerWidget {
  const FeedStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = ref.watch(_feedKindProvider);
    final custom = ref.watch(_feedCustomProvider);
    return _StatsFrame(
      title: l10n.feedStatsTitle,
      screen: 'feed',
      custom: custom,
      controls: (context, zone, now) =>
          _FeedControls(kind: kind, custom: custom, zone: zone, now: now),
      builder: (context, savedWindow, records, zone, now) {
        final cl = context.cl;
        final care = cl.care;
        final hm = DateFormat('HH:mm');
        final window = custom == null ? savedWindow : StatsWindow.month;
        final s = feedStats(
          records,
          zone,
          now,
          window,
          kind: kind,
          custom: custom,
        );
        final days = custom?.days ?? daysOf(window);
        final gap = s.averageGap == null
            ? '—'
            : compactDuration(l10n, s.averageGap!);
        final today = window == StatsWindow.today;
        final totalMl = s.dayMl + s.nightMl;
        final nightGap = s.lastNightGap;
        final peak = s.peakHour;
        final leftPct = _pct(s.leftMinutes, s.leftMinutes + s.rightMinutes);
        final breastPerDay = s.days.isEmpty
            ? 0
            : (s.days.fold(0, (t, d) => t + d.breastMinutes) / s.days.length)
                  .round();
        return [
          // v1.0 improvement 20g: cữ / ml bú bình / phút bú mẹ per day.
          // SY-5: every number of "Hôm nay" here counts from 18:00 yesterday (the night's
          // feeds), unlike Hôm nay's midnight day; one line says so for all three tiles.
          if (today) ...[
            Text(
              l10n.statsTodayFrom18,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            _Kpis([
              (l10n.amountMl(s.bottleMl), l10n.trackerBottle),
              (
                l10n.feedsCount(s.feeds),
                l10n.bottlesBreasts(s.bottleFeeds, s.breastFeeds),
              ),
              (gap, l10n.gapAverage),
            ]),
          ] else
            _Kpis(switch (kind) {
              FeedKind.all => [
                (l10n.feedsCount(s.feeds), l10n.kpiFeedsPerDay),
                (l10n.amountMl(s.bottleMl), l10n.kpiBottlePerDay),
                (l10n.durationMinutes(breastPerDay), l10n.kpiBreastPerDay),
              ],
              FeedKind.bottle => [
                (l10n.amountMl(s.bottleMl), l10n.kpiFeedsPerDay),
                (l10n.feedsCount(s.bottleFeeds), l10n.kpiFeedsPerDay),
                (
                  l10n.amountMl(
                    s.bottleFeeds == 0
                        ? 0
                        : (s.bottleMl / s.bottleFeeds).round(),
                  ),
                  l10n.kpiPerFeed,
                ),
              ],
              FeedKind.breast => [
                (l10n.durationMinutes(breastPerDay), l10n.kpiFeedsPerDay),
                (l10n.feedsCount(s.breastFeeds), l10n.kpiFeedsPerDay),
                (l10n.durationMinutes(s.breastMinutesPerFeed), l10n.kpiPerFeed),
              ],
            }),
          if (!today && s.days.isNotEmpty) ...[
            switch (kind) {
              FeedKind.all => _FeedsPerDayCard(
                stats: s,
                days: days,
                breastPerDay: breastPerDay,
                zone: zone,
              ),
              FeedKind.bottle => _MilkPerDayCard(
                stats: s,
                days: days,
                zone: zone,
              ),
              FeedKind.breast => _BreastPerDayCard(
                stats: s,
                days: days,
                breastPerDay: breastPerDay,
                zone: zone,
              ),
            },
          ],
          _Card(
            title: today ? l10n.nightAndToday : l10n.dayNightFeed,
            subtitle: today
                ? l10n.nightAndTodayHint
                : l10n.dayNightFeedHint(days),
            children: [
              if (kind == FeedKind.breast)
                // 346:590: breastfeeding is counted by time.
                _Ratio(
                  parts: [
                    (
                      cl.colors.sunshine,
                      today ? l10n.todayLabel : l10n.dayLabel,
                      _pct(s.dayMinutes, s.dayMinutes + s.nightMinutes),
                      l10n.minutesAndFeeds(s.dayMinutes, s.dayFeeds),
                    ),
                    (
                      care.sleep.accent,
                      today ? l10n.lastNightLabel : l10n.nightLabel,
                      s.dayMinutes + s.nightMinutes == 0
                          ? 0
                          : 100 -
                                _pct(
                                  s.dayMinutes,
                                  s.dayMinutes + s.nightMinutes,
                                ),
                      l10n.minutesAndFeeds(s.nightMinutes, s.nightFeeds),
                    ),
                  ],
                )
              else
                _Ratio(
                  parts: [
                    (
                      cl.colors.sunshine,
                      today ? l10n.todayLabel : l10n.dayLabel,
                      _pct(s.dayMl, totalMl),
                      l10n.mlAndFeeds(s.dayMl, s.dayFeeds),
                    ),
                    (
                      care.sleep.accent,
                      today ? l10n.lastNightLabel : l10n.nightLabel,
                      totalMl == 0 ? 0 : 100 - _pct(s.dayMl, totalMl),
                      l10n.mlAndFeeds(s.nightMl, s.nightFeeds),
                    ),
                  ],
                ),
              if (kind == FeedKind.breast && s.lastNightBreasts > 0)
                _Insight(
                  l10n.lastNightBreastInsight(
                    s.lastNightBreasts,
                    s.lastNightBreastMinutes,
                    s.lastNightBreasts == 1
                        ? hm.format(inBabyZone(zone, s.lastNightBreastFrom!))
                        : '${hm.format(inBabyZone(zone, s.lastNightBreastFrom!))}–'
                              '${hm.format(inBabyZone(zone, s.lastNightBreastTo!))}',
                  ),
                )
              else if (kind != FeedKind.breast && nightGap != null)
                _Insight(
                  today
                      ? l10n.lastNightGapInsight(
                          durationLabel(l10n, nightGap.length.inMinutes),
                          hm.format(inBabyZone(zone, nightGap.from)),
                          hm.format(inBabyZone(zone, nightGap.to)),
                        )
                      : l10n.lastNightInsight(
                          s.lastNightFeeds,
                          durationLabel(l10n, nightGap.length.inMinutes),
                          hm.format(inBabyZone(zone, nightGap.from)),
                          hm.format(inBabyZone(zone, nightGap.to)),
                        ),
                ),
            ],
          ),
          if (today)
            _Card(
              title: l10n.eachFeedToday,
              subtitle: l10n.eachFeedHint,
              children: [
                SizedBox(
                  height: 170,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _FeedsTodayPainter(
                      feeds: s.todayFeeds,
                      zone: zone,
                      now: now,
                      bar: care.bottle.accent,
                      dot: care.breast.accent,
                      shade: cl.colors.surface2,
                      ink: cl.colors.ink,
                      label: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                      notYet: l10n.notYet,
                      unit: l10n.unitMinutes,
                    ),
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                _Legend([
                  (care.bottle.accent, l10n.bottleMlLegend),
                  (care.breast.accent, l10n.breastCard),
                  (cl.colors.surface2, l10n.nightOrNotYet),
                ]),
              ],
            )
          else if (kind == FeedKind.bottle)
            // 346:354: the hourly card lives on the Bú bình view.
            _Card(
              title: l10n.milkByHour,
              subtitle: l10n.milkByHourHint(days),
              children: [
                SizedBox(
                  height: 170,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HourlyPainter(
                      values: s.hourlyMl,
                      peak: peak,
                      bar: care.bottle.accent,
                      peakBar: care.bottle.ink,
                      shade: cl.colors.surface2,
                      grid: cl.colors.separator,
                      label: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                      callout: peak == null
                          ? null
                          : l10n.peakCallout(peak, s.hourlyMl[peak].round()),
                      calloutStyle: cl.text.caption.copyWith(
                        color: cl.colors.surface,
                        fontWeight: FontWeight.w600,
                      ),
                      calloutFill: cl.colors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                _Legend([
                  (care.bottle.accent, l10n.mlPerHour),
                  (cl.colors.surface2, l10n.nightWindow),
                ]),
              ],
            ),
          if (kind != FeedKind.bottle)
            _Card(
              title: l10n.breastCard,
              subtitle: today ? l10n.windowToday : l10n.averageDays(days),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Big(
                        today
                            ? l10n.feedsCount(s.breastFeeds)
                            : l10n.feedsCount(s.breastPerDay.round()),
                        today ? l10n.todayShort : l10n.perDayShort,
                      ),
                    ),
                    Expanded(
                      child: _Big(
                        today
                            ? durationLabel(
                                l10n,
                                s.leftMinutes + s.rightMinutes,
                              )
                            : l10n.durationMinutes(s.breastMinutesPerFeed),
                        today ? l10n.sideBothFull.toLowerCase() : l10n.perFeed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s3),
                _Ratio(
                  parts: [
                    (
                      care.breast.accent,
                      today
                          ? l10n.leftMinutes(s.leftMinutes)
                          : l10n.leftShare(leftPct),
                      leftPct,
                      '',
                    ),
                    (
                      care.breast.ink,
                      today
                          ? l10n.rightMinutes(s.rightMinutes)
                          : l10n.rightShare(100 - leftPct),
                      s.leftMinutes + s.rightMinutes == 0 ? 0 : 100 - leftPct,
                      '',
                    ),
                  ],
                ),
                if (s.nextSide != null)
                  _Insight(
                    s.nextSide == Side.left
                        ? l10n.nextSideLeft
                        : l10n.nextSideRight,
                    color: care.breast.soft,
                    ink: care.breast.ink,
                  ),
              ],
            ),
          // D-085 #3: solid meals while tracking is on, as information only.
          _SolidsStatsCard(
            window: window,
            custom: custom,
            zone: zone,
            now: now,
          ),
          // "Từng ngày" last (owner, 2026-10-22).
          if (!today && s.days.isNotEmpty)
            CareDaysTimeline(
              days: [
                for (final d in s.days)
                  (start: d.start, end: d.start.add(const Duration(hours: 24))),
              ],
              records: records,
              zone: zone,
              now: now,
              types: switch (kind) {
                FeedKind.all => const {CareType.bottle, CareType.breast},
                FeedKind.bottle => const {CareType.bottle},
                FeedKind.breast => const {CareType.breast},
              },
            ),
        ];
      },
    );
  }
}

/// "Bữa ăn dặm" (D-085 #3; plan §3 #4): meals per day over the chosen range and new foods per
/// week, from `babies/{b}/meals`, while solids tracking is on. Counts only, never a target
/// (P-164 #17).
class _SolidsStatsCard extends ConsumerWidget {
  const _SolidsStatsCard({
    required this.window,
    required this.custom,
    required this.zone,
    required this.now,
  });

  final StatsWindow window;
  final CustomRange? custom;
  final String zone;
  final DateTime now;

  /// Weeks listed at most (the latest).
  static const _maxWeeks = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sd = ref.watch(sdStateProvider);
    if (sd == null || !sd.tracking || !sd.me.sdReads) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final bottle = cl.care.bottle;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = window == StatsWindow.today && custom == null;
    final days = custom?.days ?? daysOf(window);
    final anchor = custom?.end ?? now;
    final range = windowDays(zone, anchor, days);
    final live = [
      for (final m in sd.meals)
        if (!m.deleted) m,
    ];
    final perDay = [
      for (final d in range)
        live
            .where(
              (m) =>
                  !m.occurredAt.isBefore(d.start) &&
                  m.occurredAt.isBefore(d.end),
            )
            .length,
    ];
    final total = perDay.fold(0, (a, b) => a + b);
    // New foods per week (Monday first), from the range's first week to the anchor's week.
    final firstDays = [
      for (final t in sdTriedFoods(live, sd.foods)) sdDayOf(zone, t.firstAt),
    ];
    final lastWeek = sdWeekStart(sdDayOf(zone, anchor));
    final firstWeek = sdWeekStart(sdDayOf(zone, range.first.start));
    final weeks = <DateTime>[
      for (
        var w = lastWeek;
        !w.isBefore(firstWeek);
        w = DateTime(w.year, w.month, w.day - 7)
      )
        w,
    ].take(_maxWeeks).toList();
    int newIn(DateTime week) {
      final end = DateTime(week.year, week.month, week.day + 7);
      return firstDays
          .where((d) => !d.isBefore(week) && d.isBefore(end))
          .length;
    }

    final perWeek = [for (final w in weeks) newIn(w)];
    final maxWeek = perWeek.fold(0, math.max);
    final labels = [
      for (final d in range) _dayLabel(locale, zone, d.start, days),
    ];
    final avg = days == 0 ? 0.0 : total / days;
    final avgLabel = avg == avg.roundToDouble()
        ? '${avg.round()}'
        : decimal(locale, (avg * 10).round() / 10);

    return _Card(
      title: l10n.sdStatsTitle,
      subtitle: today ? l10n.sdStatsTodayHint : l10n.sdStatsHint(days),
      children: [
        Row(
          key: const Key('sdStatsKpis'),
          children: [
            Expanded(
              child: _Big(
                today ? l10n.sdMealsCount(perDay.last) : avgLabel,
                today ? l10n.sdStatsMealsToday : l10n.sdStatsPerDay,
              ),
            ),
            Expanded(
              child: _Big(
                l10n.sdFoodsCount(perWeek.isEmpty ? 0 : perWeek.first),
                l10n.sdStatsNewThisWeek,
              ),
            ),
          ],
        ),
        if (!today && days > 1) ...[
          const SizedBox(height: ClSpace.s3),
          StackedDaysChart(
            key: const Key('sdStatsChart'),
            bottoms: [for (final n in perDay) n.toDouble()],
            tops: [for (final _ in perDay) 0],
            labels: labels,
            bottomColor: bottle.accent,
            topColor: bottle.accent,
            average: avg,
            averageLabel: l10n.sdStatsAvg(avgLabel),
            tickLabel: (v) => '${v.round()}',
            tipOf: (i) => l10n.sdStatsDayTip(labels[i], perDay[i]),
          ),
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.sdStatsNewPerWeek,
            style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ClSpace.s2),
          for (final (i, w) in weeks.indexed)
            Padding(
              key: Key('sdStatsWeek_$i'),
              padding: const EdgeInsets.only(bottom: ClSpace.s2),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      l10n.sdStatsWeekOf(sdShortDate(locale, w)),
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 8,
                          width: maxWeek == 0
                              ? 4
                              : math.max(4, c.maxWidth * perWeek[i] / maxWeek),
                          decoration: BoxDecoration(
                            color: perWeek[i] == 0
                                ? cl.colors.surface2
                                : bottle.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  Text(
                    l10n.sdFoodsCount(perWeek[i]),
                    style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
        _Insight(l10n.sdStatsNote),
      ],
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.value, this.caption);
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: cl.text.headline.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          caption,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.items);
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Wrap(
      spacing: ClSpace.s3,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
      ],
    );
  }
}

void _paintText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  bool centre = false,
  bool right = false,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = centre ? at.dx - tp.width / 2 : (right ? at.dx - tp.width : at.dx);
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

/// 0h–24h axis labels at the bottom of a chart area.
void _paintHourAxis(
  Canvas canvas,
  Size size,
  double left,
  double width,
  TextStyle style,
) {
  for (final h in const [0, 6, 12, 18, 24]) {
    _paintText(
      canvas,
      '${h}h',
      style,
      Offset(left + width * h / 24, size.height - 8),
      centre: h != 0 && h != 24,
      right: h == 24,
    );
  }
}

/// "Lượng sữa theo giờ": 24 bars, night shading, darker peak bar with a callout.
class _HourlyPainter extends CustomPainter {
  _HourlyPainter({
    required this.values,
    required this.peak,
    required this.bar,
    required this.peakBar,
    required this.shade,
    required this.grid,
    required this.label,
    required this.callout,
    required this.calloutStyle,
    required this.calloutFill,
  });

  final List<double> values;
  final int? peak;
  final Color bar;
  final Color peakBar;
  final Color shade;
  final Color grid;
  final TextStyle label;
  final String? callout;
  final TextStyle calloutStyle;
  final Color calloutFill;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, bottom = 18.0, top = 26.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    final max = values.fold(0.0, math.max);
    final step = max <= 0 ? 20.0 : (max / 3 / 10).ceil() * 10.0;
    final top3 = step * 3;
    double x(int hour) => left + w * hour / 24;
    final shadePaint = Paint()..color = shade;
    canvas
      ..drawRect(Rect.fromLTRB(x(0), top - 8, x(6), top + h), shadePaint)
      ..drawRect(Rect.fromLTRB(x(18), top - 8, x(24), top + h), shadePaint);
    for (var i = 0; i <= 3; i++) {
      final y = top + h - h * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width, y),
        Paint()..color = grid,
      );
      _paintText(
        canvas,
        '${(step * i).round()}',
        label,
        Offset(left - 6, y),
        right: true,
      );
    }
    final barWidth = w / 24 * 0.62;
    for (var hour = 0; hour < 24; hour++) {
      final v = values[hour];
      if (v <= 0) continue;
      final bh = h * (v / top3).clamp(0, 1);
      final cx = x(hour) + w / 48;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barWidth / 2, top + h - bh, barWidth, bh),
          const Radius.circular(3),
        ),
        Paint()..color = hour == peak ? peakBar : bar,
      );
      if (hour == peak && callout != null) {
        final tp = TextPainter(
          text: TextSpan(text: callout, style: calloutStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final bx = (cx - tp.width / 2 - 6).clamp(
          0.0,
          size.width - tp.width - 12,
        );
        final box = Rect.fromLTWH(
          bx,
          top + h - bh - tp.height - 12,
          tp.width + 12,
          tp.height + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(6)),
          Paint()..color = calloutFill,
        );
        tp.paint(canvas, Offset(box.left + 6, box.top + 3));
      }
    }
    _paintHourAxis(canvas, size, left, w, label);
  }

  @override
  bool shouldRepaint(_HourlyPainter old) =>
      old.values != values || old.bar != bar;
}

/// "Từng cữ hôm nay": bottle bars with ml, breastfeeds as pink dots, night and "Chưa tới".
class _FeedsTodayPainter extends CustomPainter {
  _FeedsTodayPainter({
    required this.feeds,
    required this.zone,
    required this.now,
    required this.bar,
    required this.dot,
    required this.shade,
    required this.ink,
    required this.label,
    required this.notYet,
    required this.unit,
  });

  final List<CareRecord> feeds;
  final String zone;
  final DateTime now;
  final Color bar;
  final Color dot;
  final Color shade;
  final Color ink;
  final TextStyle label;
  final String notYet;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, bottom = 18.0, top = 16.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    double hours(DateTime t) {
      final local = inBabyZone(zone, t);
      return local.hour + local.minute / 60;
    }

    double x(double hour) => left + w * hour / 24;
    final shadePaint = Paint()..color = shade;
    canvas.drawRect(Rect.fromLTRB(x(0), top, x(6), top + h), shadePaint);
    final nowH = hours(now);
    canvas.drawRect(
      Rect.fromLTRB(x(nowH), top, x(24), top + h),
      Paint()..color = shade.withValues(alpha: 0.6),
    );
    _paintText(
      canvas,
      notYet,
      label,
      Offset(x((nowH + 24) / 2), top + 10),
      centre: true,
    );
    const maxMl = 150.0;
    for (var i = 0; i <= 3; i++) {
      final y = top + h - h * i / 3;
      _paintText(
        canvas,
        '${(maxMl * i / 3).round()}',
        label,
        Offset(left - 6, y),
        right: true,
      );
    }
    for (final r in feeds) {
      final cx = x(hours(r.occurredAt));
      if (r.type == CareType.bottle) {
        final ml = (r.amountMl ?? 0).toDouble();
        final bh = h * (ml / maxMl).clamp(0.05, 1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 5, top + h - bh, 10, bh),
            const Radius.circular(3),
          ),
          Paint()..color = bar,
        );
        _paintText(
          canvas,
          '${ml.round()}',
          label,
          Offset(cx, top + h - bh - 8),
          centre: true,
        );
      } else {
        canvas.drawCircle(Offset(cx, top + h - 6), 6, Paint()..color = dot);
        _paintText(
          canvas,
          '${r.durationMin ?? 0}$unit',
          label,
          Offset(cx, top + h - 20),
          centre: true,
        );
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(x(nowH) - 1, top, 2, h),
      Paint()..color = ink,
    );
    _paintHourAxis(canvas, size, left, w, label);
  }

  @override
  bool shouldRepaint(_FeedsTodayPainter old) =>
      old.feeds != feeds || old.now != now;
}

/// 20h Thống kê ngủ (111:10994); Hôm nay and 30 ngày per D-028.
class SleepStatsScreen extends ConsumerWidget {
  const SleepStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _StatsFrame(
      title: l10n.sleepStatsTitle,
      screen: 'sleep',
      builder: (context, window, records, zone, now) {
        final cl = context.cl;
        final care = cl.care;
        final locale = Localizations.localeOf(context).toLanguageTag();
        final s = sleepStats(records, zone, now, window);
        final days = daysOf(window);
        final total = s.nightPerDay + s.dayPerDay;
        final nightPct = total == Duration.zero
            ? 0
            : (s.nightPerDay.inMinutes * 100 / total.inMinutes).round();
        String hm(Duration d) =>
            l10n.rhythmSleepValue(d.inHours, d.inMinutes % 60);
        String detail(Duration d, (int, int) r) => r.$1 == r.$2
            ? l10n.durationAndSleep(hm(d), r.$1)
            : l10n.durationAndSleeps(hm(d), '${r.$1}–${r.$2}');
        final today = window == StatsWindow.today;
        final grew = s.firstNightLongest != s.lastNightLongest && days > 1;
        return [
          _Kpis([
            (
              compactDuration(l10n, s.perDay),
              today ? l10n.windowToday : l10n.perDay,
            ),
            (
              l10n.sleepsValue(s.sleepsPerDay.round()),
              today ? l10n.windowToday : l10n.perDay,
            ),
            (compactDuration(l10n, s.longest), l10n.longestSleep),
          ]),
          if (!today && s.rows.isNotEmpty) ...[
            _SleepPerDayCard(stats: s, days: days, zone: zone),
          ],
          _Card(
            title: l10n.dayNightSleep,
            subtitle: today
                ? l10n.dayNightSleepTodayHint
                : l10n.dayNightSleepHint(days),
            children: [
              _Ratio(
                parts: [
                  (
                    care.sleep.accent,
                    l10n.nightLabel,
                    nightPct,
                    detail(s.nightPerDay, s.nightCounts),
                  ),
                  (
                    cl.colors.sunshine,
                    l10n.dayLabel,
                    total == Duration.zero ? 0 : 100 - nightPct,
                    detail(s.dayPerDay, s.dayCounts),
                  ),
                ],
              ),
              if (s.lastNightLongest > Duration.zero)
                _Insight(
                  grew
                      ? l10n.nightLongestInsight(
                          days,
                          durationLabel(l10n, s.firstNightLongest.inMinutes),
                          durationLabel(l10n, s.lastNightLongest.inMinutes),
                        )
                      : l10n.nightLongestSame(
                          durationLabel(l10n, s.lastNightLongest.inMinutes),
                        ),
                ),
            ],
          ),
          _Card(
            title: window == StatsWindow.today
                ? l10n.sleepRhythmToday
                : l10n.sleepRhythm(days),
            subtitle: l10n.sleepRhythmHint,
            children: [
              SizedBox(
                height: 30.0 + s.rows.length * (days > 7 ? 10 : 22),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RhythmPainter(
                    rows: s.rows,
                    labels: [
                      for (final r in s.rows)
                        () {
                          final d = inBabyZone(zone, r.start);
                          return '${weekdayShort(locale, d)} ${d.day}';
                        }(),
                    ],
                    nowHour: () {
                      final local = inBabyZone(zone, now);
                      return local.hour + local.minute / 60;
                    }(),
                    bar: care.sleep.accent,
                    shade: cl.colors.surface2,
                    ink: cl.colors.ink,
                    label: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                    bold: cl.text.caption.copyWith(
                      color: cl.colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s2),
              _Legend([
                (care.sleep.accent, l10n.legendSleepShort),
                (cl.colors.surface2, l10n.nightWindow),
              ]),
            ],
          ),
          _Card(
            title: l10n.longestEachDay,
            subtitle: l10n.longestEachDayHint,
            children: [
              SizedBox(
                height: 150,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LongestPainter(
                    rows: s.rows,
                    labels: [
                      for (final r in s.rows)
                        weekdayShort(locale, inBabyZone(zone, r.start)),
                    ],
                    bar: care.sleep.accent,
                    last: care.sleep.ink,
                    grid: cl.colors.separator,
                    label: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                    bold: cl.text.caption.copyWith(
                      color: cl.colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    format: (d) => l10n.compactHMShort(
                      d.inHours,
                      (d.inMinutes % 60).toString().padLeft(2, '0'),
                    ),
                    hours: (h) => l10n.compactH(h),
                  ),
                ),
              ),
            ],
          ),
          if (!today && s.rows.isNotEmpty)
            CareDaysTimeline(
              days: [
                for (final r in s.rows)
                  (start: r.start, end: r.start.add(const Duration(hours: 24))),
              ],
              records: records,
              zone: zone,
              now: now,
              types: const {CareType.sleep},
            ),
        ];
      },
    );
  }
}

/// "Nhịp ngủ": one row per day, sleep bars 0–24h split at midnight, night shading, now marker
/// and "Chưa tới" on today's row.
class _RhythmPainter extends CustomPainter {
  _RhythmPainter({
    required this.rows,
    required this.labels,
    required this.nowHour,
    required this.bar,
    required this.shade,
    required this.ink,
    required this.label,
    required this.bold,
  });

  final List<SleepDayRow> rows;
  final List<String> labels;
  final double nowHour;
  final Color bar;
  final Color shade;
  final Color ink;
  final TextStyle label;
  final TextStyle bold;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, bottom = 18.0;
    final w = size.width - left;
    final rowH = (size.height - bottom) / math.max(1, rows.length);
    double x(double hour) => left + w * hour / 24;
    final shadePaint = Paint()..color = shade;
    canvas
      ..drawRect(Rect.fromLTRB(x(0), 0, x(6), size.height - bottom), shadePaint)
      ..drawRect(
        Rect.fromLTRB(x(18), 0, x(24), size.height - bottom),
        shadePaint,
      );
    final barH = math.max(4.0, rowH * 0.6);
    for (final (i, row) in rows.indexed) {
      final cy = rowH * i + rowH / 2;
      final today = i == rows.length - 1;
      if (rowH >= 14 || i % 5 == 0 || today) {
        _paintText(canvas, labels[i], today ? bold : label, Offset(0, cy));
      }
      if (today) {
        canvas
          ..drawRect(
            Rect.fromLTRB(x(nowHour), cy - barH / 2, x(24), cy + barH / 2),
            Paint()..color = shade,
          )
          ..drawRect(
            Rect.fromLTWH(x(nowHour) - 1, cy - rowH / 2, 2, rowH),
            Paint()..color = ink,
          );
      }
      for (final b in row.bars) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              x(b.fromHour),
              cy - barH / 2,
              math.max(x(b.toHour), x(b.fromHour) + 3),
              cy + barH / 2,
            ),
            Radius.circular(barH / 3),
          ),
          Paint()..color = bar,
        );
      }
    }
    _paintHourAxis(canvas, size, left, w, label);
  }

  @override
  bool shouldRepaint(_RhythmPainter old) =>
      old.rows != rows || old.nowHour != nowHour;
}

/// "Giấc dài nhất mỗi ngày": bars in hours, today darker; first and last labelled.
class _LongestPainter extends CustomPainter {
  _LongestPainter({
    required this.rows,
    required this.labels,
    required this.bar,
    required this.last,
    required this.grid,
    required this.label,
    required this.bold,
    required this.format,
    required this.hours,
  });

  final List<SleepDayRow> rows;
  final List<String> labels;
  final Color bar;
  final Color last;
  final Color grid;
  final TextStyle label;
  final TextStyle bold;
  final String Function(Duration) format;
  final String Function(int) hours;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, bottom = 20.0, top = 18.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    final maxH = math.max(
      8,
      (rows
                      .fold(
                        Duration.zero,
                        (m, r) => r.longest > m ? r.longest : m,
                      )
                      .inMinutes /
                  60 /
                  4)
              .ceil() *
          4,
    );
    for (var i = 0; i <= 2; i++) {
      final v = maxH * i ~/ 2;
      final y = top + h - h * i / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width, y),
        Paint()..color = grid,
      );
      _paintText(canvas, hours(v), label, Offset(left - 6, y), right: true);
    }
    final slot = w / math.max(1, rows.length);
    final barW = math.min(28.0, slot * 0.6);
    for (final (i, r) in rows.indexed) {
      final cx = left + slot * i + slot / 2;
      final bh = h * (r.longest.inMinutes / 60 / maxH).clamp(0, 1);
      final isLast = i == rows.length - 1;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW / 2, top + h - bh, barW, bh),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = isLast ? last : bar,
      );
      if ((i == 0 || isLast) && r.longest > Duration.zero) {
        _paintText(
          canvas,
          format(r.longest),
          isLast ? bold : label,
          Offset(cx, top + h - bh - 8),
          centre: true,
        );
      }
      if (rows.length <= 7 || i % 5 == 0 || isLast) {
        _paintText(
          canvas,
          labels[i],
          isLast ? bold : label,
          Offset(cx, size.height - 8),
          centre: true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LongestPainter old) => old.rows != rows;
}

String _dayLabel(String locale, String zone, DateTime start, int days) {
  final d = inBabyZone(zone, start);
  return days > 7 ? '${d.day}' : weekdayShort(locale, d);
}

/// 20g "Bú mỗi ngày" (v1.0 improvement): bottle and breast feeds stacked per day, the window's
/// average, and the share of each kind.
class _FeedsPerDayCard extends StatelessWidget {
  const _FeedsPerDayCard({
    required this.stats,
    required this.days,
    required this.breastPerDay,
    required this.zone,
  });

  final FeedStats stats;
  final int days;
  final int breastPerDay;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bars = stats.days;
    final bottles = bars.fold(0, (t, d) => t + d.bottles);
    final all = bars.fold(0, (t, d) => t + d.feeds);
    final bottlePct = _pct(bottles, all);
    final labels = [
      for (final d in bars) _dayLabel(locale, zone, d.start, days),
    ];
    return _Card(
      title: l10n.feedsPerDayTitle,
      subtitle: l10n.feedsPerDayHint(days),
      children: [
        StackedDaysChart(
          bottoms: [for (final d in bars) d.bottles.toDouble()],
          tops: [for (final d in bars) d.breasts.toDouble()],
          labels: labels,
          bottomColor: care.bottle.accent,
          topColor: care.breast.accent,
          average: stats.feeds.toDouble(),
          averageLabel: l10n.feedsAvgLine(stats.feeds),
          tickLabel: (v) => '${v.round()}',
          tipOf: (i) => l10n.feedsDayTip(
            labels[i],
            bars[i].bottles,
            bars[i].bottleMl,
            bars[i].breasts,
            bars[i].breastMinutes,
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        _Legend([
          (care.bottle.accent, l10n.trackerBottle),
          (care.breast.accent, l10n.trackerBreast),
        ]),
        const SizedBox(height: ClSpace.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: math.max(1, all == 0 ? 1 : bottlePct),
                  child: ColoredBox(
                    color: all == 0 ? cl.colors.surface2 : care.bottle.accent,
                  ),
                ),
                Container(width: 2, color: cl.colors.surface),
                Expanded(
                  flex: math.max(1, all == 0 ? 1 : 100 - bottlePct),
                  child: ColoredBox(
                    color: all == 0 ? cl.colors.surface2 : care.breast.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.bottleShareLine(bottlePct, stats.bottleMl),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        Text(
          l10n.breastShareLine(all == 0 ? 0 : 100 - bottlePct, breastPerDay),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// 20h "Tổng giờ ngủ mỗi ngày" (v1.0 improvement): night and day sleep stacked per day, the
/// window's average, and whether it held steady.
class _SleepPerDayCard extends StatelessWidget {
  const _SleepPerDayCard({
    required this.stats,
    required this.days,
    required this.zone,
  });

  final SleepStats stats;
  final int days;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = stats.rows;
    final labels = [
      for (final r in rows) _dayLabel(locale, zone, r.start, days),
    ];
    String c(Duration d) => compactDuration(l10n, d);
    final totals = [for (final r in rows) r.night + r.day];
    final logged = totals.where((t) => t > Duration.zero).toList();
    final min = logged.isEmpty
        ? Duration.zero
        : logged.reduce((a, b) => a < b ? a : b);
    final max = logged.isEmpty
        ? Duration.zero
        : logged.reduce((a, b) => a > b ? a : b);
    return _Card(
      title: l10n.sleepPerDayTitle,
      subtitle: l10n.sleepPerDayHint,
      children: [
        StackedDaysChart(
          bottoms: [for (final r in rows) r.night.inMinutes / 60],
          tops: [for (final r in rows) r.day.inMinutes / 60],
          labels: labels,
          bottomColor: care.sleep.accent,
          topColor: cl.colors.sunshine,
          average: stats.perDay.inMinutes / 60,
          averageLabel: l10n.sleepAvgLine(c(stats.perDay)),
          step: 6,
          tickLabel: (v) => l10n.compactH(v.round()),
          tipOf: (i) => l10n.sleepDayTip(
            labels[i],
            c(rows[i].night + rows[i].day),
            c(rows[i].night),
            c(rows[i].day),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        _Legend([
          (care.sleep.accent, l10n.legendNightSleep),
          (cl.colors.sunshine, l10n.legendDaySleep),
        ]),
        if (logged.length > 1)
          _Insight(
            max - min <= const Duration(hours: 2)
                ? l10n.sleepSteadyInsight(
                    (stats.perDay.inMinutes / 60).round(),
                    days,
                  )
                : l10n.sleepRangeInsight(c(min), c(max), days),
          ),
      ],
    );
  }
}

String _span(DateTime from, DateTime to) =>
    '${from.day}/${from.month} – ${to.day}/${to.month}';

/// 20g type and range pills (v1.0 improvement 346:64): "Tất cả ▾" · "7 ngày ▾".
class _FeedControls extends ConsumerWidget {
  const _FeedControls({
    required this.kind,
    required this.custom,
    required this.zone,
    required this.now,
  });

  final FeedKind kind;
  final CustomRange? custom;
  final String zone;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(_windowProvider('feed'));
    String range() {
      final c = custom;
      if (c == null) return _windowLabel(l10n, window);
      final days = windowDays(zone, c.end, c.days);
      return _span(
        inBabyZone(zone, days.first.start),
        inBabyZone(zone, days.last.start),
      );
    }

    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        _DropPill(
          icon: ClIcons.feed,
          label: switch (kind) {
            FeedKind.all => l10n.feedKindAll,
            FeedKind.bottle => l10n.trackerBottle,
            FeedKind.breast => l10n.trackerBreast,
          },
          onTap: () => _showKindSheet(context),
        ),
        _DropPill(
          icon: ClIcons.clock,
          label: range(),
          onTap: () => _showRangeSheet(context, zone, now),
        ),
      ],
    );
  }
}

class _DropPill extends StatelessWidget {
  const _DropPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final ClIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(color: cl.colors.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 16, color: cl.colors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            ClIcon(ClIcons.chevronDown, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// SH Thống kê bú · Loại (391:3185).
Future<void> _showKindSheet(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (sheet) => Consumer(
    builder: (context, ref, _) {
      final l10n = AppLocalizations.of(context);
      final kind = ref.watch(_feedKindProvider);
      void pick(FeedKind k) {
        ref.read(_feedKindProvider.notifier).set(k);
        Navigator.of(sheet).pop();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.feedKindTitle),
          ClCardGroup(
            children: [
              for (final (k, title, hint) in [
                (FeedKind.all, l10n.feedKindAll, l10n.feedKindAllHint),
                (FeedKind.bottle, l10n.trackerBottle, l10n.feedKindBottleHint),
                (FeedKind.breast, l10n.trackerBreast, l10n.feedKindBreastHint),
              ])
                ClOptionRow(
                  title: title,
                  subtitle: hint,
                  selected: kind == k,
                  onTap: () => pick(k),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ],
      );
    },
  ),
);

/// SH Thống kê bú · Thời gian (391:3373): Hôm nay · 7 ngày · 30 ngày · Tuỳ chọn.
Future<void> _showRangeSheet(BuildContext context, String zone, DateTime now) =>
    showClSheet<void>(
      context: context,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context);
          final window = ref.watch(_windowProvider('feed'));
          final custom = ref.watch(_feedCustomProvider);
          String caption(int days) {
            final d = windowDays(zone, now, days);
            return _span(
              inBabyZone(zone, d.first.start),
              inBabyZone(zone, d.last.start),
            );
          }

          void pick(StatsWindow w) {
            ref.read(_feedCustomProvider.notifier).set(null);
            ref.read(_windowProvider('feed').notifier).set(w);
            Navigator.of(sheet).pop();
          }

          Future<void> pickCustom() async {
            final today = inBabyZone(zone, now);
            final last = DateTime(today.year, today.month, today.day);
            final picked = await showDateRangePicker(
              context: context,
              firstDate: last.subtract(const Duration(days: 730)),
              lastDate: last,
              initialDateRange: DateTimeRange(
                start: last.subtract(const Duration(days: 6)),
                end: last,
              ),
            );
            if (picked == null || !sheet.mounted) return;
            final days = picked.end.difference(picked.start).inDays + 1;
            // Noon of the last day, in the baby's zone, anchors the window.
            final end = now.subtract(
              Duration(days: last.difference(picked.end).inDays),
            );
            ref.read(_feedCustomProvider.notifier).set((
              end: end,
              days: days.clamp(1, 730),
            ));
            if (sheet.mounted) Navigator.of(sheet).pop();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l10n.rangeTitle),
              ClCardGroup(
                children: [
                  ClOptionRow(
                    title: l10n.windowToday,
                    selected: custom == null && window == StatsWindow.today,
                    onTap: () => pick(StatsWindow.today),
                  ),
                  ClOptionRow(
                    title: l10n.window7,
                    subtitle: caption(7),
                    selected: custom == null && window == StatsWindow.week,
                    onTap: () => pick(StatsWindow.week),
                  ),
                  ClOptionRow(
                    title: l10n.window30,
                    subtitle: caption(30),
                    selected: custom == null && window == StatsWindow.month,
                    onTap: () => pick(StatsWindow.month),
                  ),
                  ClOptionRow(
                    title: l10n.rangeCustom,
                    subtitle: l10n.rangeCustomHint,
                    selected: custom != null,
                    onTap: pickCustom,
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s4),
            ],
          );
        },
      ),
    );

/// 20g · Bú bình (346:354) "Lượng sữa mỗi ngày": expressed milk and formula ml per day.
class _MilkPerDayCard extends StatelessWidget {
  const _MilkPerDayCard({
    required this.stats,
    required this.days,
    required this.zone,
  });

  final FeedStats stats;
  final int days;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bars = stats.days;
    final labels = [
      for (final d in bars) _dayLabel(locale, zone, d.start, days),
    ];
    return _Card(
      title: l10n.milkPerDayTitle,
      subtitle: l10n.milkPerDayHint(days),
      children: [
        StackedDaysChart(
          bottoms: [for (final d in bars) d.breastMilkMl.toDouble()],
          tops: [for (final d in bars) d.formulaMl.toDouble()],
          labels: labels,
          bottomColor: care.pump.accent,
          topColor: care.bottle.accent,
          average: stats.bottleMl.toDouble(),
          averageLabel: l10n.mlAvgLine(stats.bottleMl),
          tickLabel: (v) => '${v.round()}',
          tipOf: (i) =>
              l10n.milkDayTip(labels[i], bars[i].bottleMl, bars[i].bottles),
        ),
        const SizedBox(height: ClSpace.s2),
        _Legend([
          (care.pump.accent, l10n.legendExpressedMilk),
          (care.bottle.accent, l10n.legendFormula),
        ]),
      ],
    );
  }
}

/// 20g · Bú mẹ (346:590) "Thời gian bú mẹ mỗi ngày": left and right minutes per day.
class _BreastPerDayCard extends StatelessWidget {
  const _BreastPerDayCard({
    required this.stats,
    required this.days,
    required this.breastPerDay,
    required this.zone,
  });

  final FeedStats stats;
  final int days;
  final int breastPerDay;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bars = stats.days;
    final labels = [
      for (final d in bars) _dayLabel(locale, zone, d.start, days),
    ];
    return _Card(
      title: l10n.breastPerDayTitle,
      subtitle: l10n.breastPerDayHint,
      children: [
        StackedDaysChart(
          bottoms: [for (final d in bars) d.leftMinutes.toDouble()],
          tops: [for (final d in bars) d.rightMinutes.toDouble()],
          labels: labels,
          bottomColor: care.breast.accent,
          topColor: care.breast.ink,
          average: breastPerDay.toDouble(),
          averageLabel: l10n.minutesAvgLine(breastPerDay),
          tickLabel: (v) => '${v.round()}′',
          tipOf: (i) => l10n.breastDayTip(
            labels[i],
            bars[i].breastMinutes,
            bars[i].breasts,
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        _Legend([
          (care.breast.accent, l10n.legendLeftSide),
          (care.breast.ink, l10n.legendRightSide),
        ]),
        _Insight(l10n.breastByTimeNote),
      ],
    );
  }
}
