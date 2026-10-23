import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../today/today_screen.dart' show DayRhythm;
import 'care_calc.dart';
import 'care_format.dart';
import 'care_models.dart';
import '../../core/widgets/cl_segmented.dart';
import 'growth_chart.dart';
import 'growth_reference.dart';
import 'growth_standards_screen.dart';
import 'who_growth.dart';
import 'care_repository.dart';
import 'care_screens.dart';
import 'stats_screens.dart' show compactDuration;
import 'care_sheets.dart';
import 'timer_models.dart';
import '../solids/solids_calc.dart';
import '../solids/solids_format.dart';
import '../solids/solids_models.dart';
import '../solids/solids_routes.dart';
import '../solids/solids_sheet.dart' show openMealSheet;
import '../solids/solids_state.dart';
import '../solids/solids_widgets.dart' show SdTag;

/// Filter chips (single-select): Tất cả · Bú · Hút sữa · Ngủ · Tã · Tăng trưởng (20–20d), and
/// "Ăn dặm" while solids tracking is on (D-085 #3: meal rows from `babies/{b}/meals`; "Tất cả"
/// shows them too).
enum HistoryFilter { all, feed, pump, sleep, diaper, growth, solids }

bool _matchesType(HistoryFilter f, CareType type) => switch (f) {
  HistoryFilter.all => true,
  // "Bú" = bottle + breast; pumping has its own chip (104:8724).
  HistoryFilter.feed => type == CareType.bottle || type == CareType.breast,
  HistoryFilter.pump => type == CareType.pump,
  HistoryFilter.sleep => type == CareType.sleep,
  HistoryFilter.diaper => type == CareType.diaper,
  HistoryFilter.growth => type == CareType.growth,
  // Meals are not care records (plan §3 #4): they come from the meals collection.
  HistoryFilter.solids => false,
};

bool _matches(HistoryFilter f, CareRecord r) => _matchesType(f, r.type);

String _filterLabel(AppLocalizations l10n, HistoryFilter f) => switch (f) {
  HistoryFilter.all => l10n.filterAll,
  HistoryFilter.feed => l10n.filterFeed,
  HistoryFilter.pump => l10n.filterPump,
  HistoryFilter.sleep => l10n.filterSleep,
  HistoryFilter.diaper => l10n.filterDiaper,
  HistoryFilter.growth => l10n.filterGrowth,
  HistoryFilter.solids => l10n.sdHistoryFilter,
};

/// "T2 … T7, CN" (vi) / "Mon" (en).
String weekdayShort(String locale, DateTime d) => locale.startsWith('vi')
    ? (d.weekday == DateTime.sunday ? 'CN' : 'T${d.weekday + 1}')
    : DateFormat.E(locale).format(d);

/// 20 Lịch sử (46:2469) and its filters 20a–20d, empty day 20e and date picker 20f. History
/// lives under the Hôm nay tab. All days are the baby's calendar days.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({this.filter = HistoryFilter.all, super.key});
  final HistoryFilter filter;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late HistoryFilter _filter = widget.filter;
  DateTime? _day;
  final _selectedChip = GlobalKey();
  final _chips = ScrollController();

  @override
  void initState() {
    super.initState();
    // Opened on a filter (e.g. growth "Xem tất cả"): bring its chip into view.
    if (widget.filter != HistoryFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chip = _selectedChip.currentContext?.findRenderObject();
        if (chip is! RenderBox || !_chips.hasClients) return;
        final row = _chips.position.context.notificationContext
            ?.findRenderObject();
        if (row is! RenderBox) return;
        final x = chip.localToGlobal(Offset.zero, ancestor: row).dx;
        _chips.jumpTo(
          (_chips.offset + x - (row.size.width - chip.size.width) / 2).clamp(
            0,
            _chips.position.maxScrollExtent,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _chips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final babyId = me.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now =
        ref.watch(careClockProvider).value ?? ref.read(timerClockProvider)();
    final today = babyToday(zone, now);
    final day = _day ?? today;
    final isToday = day == today;
    final profile = me.canViewBabyInfo
        ? ref.watch(babyPrivateProfileProvider(babyId)).value
        : null;
    final dob = profile?.dateOfBirth;
    final bounds = babyDateBounds(zone, day);
    // A sleep from the night before still belongs to the day (D-027).
    final records =
        ref
            .watch(
              rangeRecordsProvider((
                babyId,
                bounds.start.subtract(const Duration(days: 1)),
                bounds.end,
              )),
            )
            .value ??
        const <CareRecord>[];
    final growth = ref.watch(growthRecordsProvider(babyId)).value ?? const [];
    // D-085 #3: meals join the timeline while tracking is on, for members who read the diary.
    final sd = ref.watch(sdStateProvider);
    final solidsOn =
        sd != null && sd.tracking && sd.me.sdReads && sd.baby.babyId == babyId;
    final filter = _filter == HistoryFilter.solids && !solidsOn
        ? HistoryFilter.all
        : _filter;
    final meals =
        solidsOn &&
            (filter == HistoryFilter.all || filter == HistoryFilter.solids)
        ? sdMealsOn(sd.meals, zone, day)
        : const <SdMeal>[];
    final matching = [
      for (final r in records)
        if (_matches(filter, r)) r,
    ];
    final entries = timelineOf(matching, zone, bounds.start, bounds.end);
    final timers = [
      for (final type in TimerType.values)
        if (isToday && _matchesType(filter, type.careType))
          ?ref.watch(careTimerProvider((babyId, type))).value,
    ];
    final readOnly = me.role == MemberRole.relative;

    final dateLabel = shortDate(context, day);
    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.historyTitle, style: cl.text.largeTitle),
            ),
          ),
          _MonthChip(
            label: locale.startsWith('vi')
                ? l10n.monthChip(day.month, '')
                : l10n.monthChip(0, DateFormat.MMMM(locale).format(day)),
            onTap: () async {
              final picked = await showHistoryDatePicker(
                context,
                selected: day,
                today: today,
                dob: dob,
                babyId: babyId,
                nickname: baby?.nickname ?? '',
              );
              if (picked != null && mounted) setState(() => _day = picked);
            },
          ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
      // 12d: a caregiver edits only their own records (D-022).
      if (me.role == MemberRole.caregiver) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                l10n.historyCaregiverNote,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
      if (filter != HistoryFilter.growth) ...[
        _DayStrip(
          today: today,
          selected: day,
          earliest: dob,
          locale: locale,
          onSelect: (d) => setState(() => _day = d),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
      SingleChildScrollView(
        controller: _chips,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, f) in [
              for (final f in HistoryFilter.values)
                if (f != HistoryFilter.solids || solidsOn) f,
            ].indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s2),
              ClFilterChip(
                key: filter == f
                    ? _selectedChip
                    : (f == HistoryFilter.solids
                          ? const Key('historySolids')
                          : null),
                label: _filterLabel(l10n, f),
                selected: filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s4),
    ];

    if (filter == HistoryFilter.growth) {
      children.add(
        _GrowthPanel(
          records: growth,
          myUid: me.uid,
          dob: dob,
          gender: profile?.gender,
          nickname: baby?.nickname ?? '',
          readOnly: readOnly,
        ),
      );
    } else if (entries.isEmpty && timers.isEmpty && meals.isEmpty) {
      children.add(
        _EmptyDay(
          filter: filter,
          isToday: isToday,
          dateLabel: dateLabel,
          readOnly:
              readOnly || (filter == HistoryFilter.solids && !sd!.me.sdLogs),
          onLog: () => filter == HistoryFilter.solids
              ? openMealSheet(context, day: isToday ? null : day)
              : _backLog(context, day, isToday, zone),
          onSeeAll: () => setState(() => _filter = HistoryFilter.all),
        ),
      );
    } else if (filter == HistoryFilter.solids) {
      children
        ..add(
          _SolidsSummary(
            meals: meals,
            all: sd!.meals,
            isToday: isToday,
            dateLabel: dateLabel,
          ),
        )
        ..add(const SizedBox(height: ClSpace.s4))
        ..add(
          _Timeline(
            entries: const [],
            timers: const [],
            meals: meals,
            zone: zone,
            myUid: me.uid,
            now: now,
          ),
        );
    } else {
      children
        ..add(
          _SummaryCard(
            filter: filter,
            records: records,
            bounds: bounds,
            now: now,
            isToday: isToday,
            dateLabel: dateLabel,
            sleepRunning: ref
                .watch(careTimerProvider((babyId, TimerType.sleep)))
                .value,
          ),
        )
        ..add(const SizedBox(height: ClSpace.s4))
        ..add(
          _Timeline(
            entries: entries,
            dayEnd: bounds.end,
            timers: timers.whereType<CareTimer>().toList(),
            meals: meals,
            zone: zone,
            myUid: me.uid,
            now: now,
          ),
        );
    }

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
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Ghi bù": the log for the filter, at the current time of day on the chosen date.
  /// The current time of day is taken in the baby's zone, like the day itself.
  void _backLog(BuildContext context, DateTime day, bool isToday, String zone) {
    final now = inBabyZone(zone, ref.read(timerClockProvider)());
    final start = babyDateBounds(zone, day).start;
    final at = isToday
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            start.millisecondsSinceEpoch,
          ).add(Duration(hours: now.hour, minutes: now.minute));
    final type = switch (_filter) {
      HistoryFilter.feed => CareType.bottle,
      HistoryFilter.pump => CareType.pump,
      HistoryFilter.sleep => CareType.sleep,
      HistoryFilter.diaper => CareType.diaper,
      _ => null,
    };
    if (type == null) {
      showQuickLog(context);
    } else {
      openCareLog(context, type, at: at);
    }
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, required this.onTap});
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
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: ClSpace.s1),
            ClIcon(ClIcons.chevronDown, size: 16, color: cl.colors.ink),
          ],
        ),
      ),
    );
  }
}

/// Rolling 7 days ending today; swipe for earlier weeks (DayPill 45:342). Never before birth.
class _DayStrip extends StatefulWidget {
  const _DayStrip({
    required this.today,
    required this.selected,
    required this.earliest,
    required this.locale,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selected;
  final DateTime? earliest;
  final String locale;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  late final PageController _pages = PageController(
    initialPage: _pageOf(widget.selected),
  );

  int _pageOf(DateTime d) => widget.today.difference(d).inDays ~/ 7;

  @override
  void didUpdateWidget(_DayStrip old) {
    super.didUpdateWidget(old);
    final page = _pageOf(widget.selected);
    if (_pages.hasClients && _pages.page?.round() != page) {
      _pages.jumpToPage(page);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earliest = widget.earliest == null
        ? null
        : DateUtils.dateOnly(widget.earliest!);
    final weeks = earliest == null
        ? 53
        : math.max(1, widget.today.difference(earliest).inDays ~/ 7 + 1);
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _pages,
        reverse: true,
        itemCount: weeks,
        itemBuilder: (context, page) {
          final end = widget.today.subtract(Duration(days: page * 7));
          return LayoutBuilder(
            builder: (context, c) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 6; i >= 0; i--)
                  () {
                    final d = DateTime(end.year, end.month, end.day - i);
                    final hidden = earliest != null && d.isBefore(earliest);
                    return Opacity(
                      opacity: hidden ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: hidden,
                        child: ClDayPill(
                          weekday: weekdayShort(widget.locale, d),
                          day: '${d.day}',
                          selected: d == widget.selected,
                          onTap: () => widget.onSelect(d),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Summary per filter: DayRhythm for Tất cả, "Bú / Ngủ / Tã hôm nay" (20a–20c), pumping
/// (not drawn). Past days read "… ngày 5 thg 10"; "now" values only show for today.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.filter,
    required this.records,
    required this.bounds,
    required this.now,
    required this.isToday,
    required this.dateLabel,
    required this.sleepRunning,
  });

  final HistoryFilter filter;
  final List<CareRecord> records;
  final ({DateTime start, DateTime end}) bounds;
  final DateTime now;
  final bool isToday;
  final String dateLabel;
  final CareTimer? sleepRunning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hm = DateFormat.Hm(locale);
    String ago(DateTime? t) => t == null ? '—' : relativeAgo(l10n, t, now);
    String hmDuration(Duration d) => d == Duration.zero
        ? '—'
        : l10n.rhythmSleepValue(d.inHours, d.inMinutes % 60);

    final strip = DayRhythm(
      records: [
        for (final r in records)
          if (_matches(filter, r)) r,
      ],
      dayStart: bounds.start,
      dayEnd: bounds.end,
      now: now,
      title: isToday ? null : l10n.loggedOnDay(dateLabel),
      stripOnly: filter != HistoryFilter.all,
    );
    switch (filter) {
      case HistoryFilter.all:
        return strip;
      case HistoryFilter.feed:
        final f = feedDay(records, bounds.start, bounds.end);
        return Column(
          children: [
            _StatCard(
              title: isToday ? l10n.feedToday : l10n.feedOnDay(dateLabel),
              rows: [
                (
                  care.bottle.accent,
                  l10n.trackerBottle,
                  l10n.rhythmFeeds(f.bottleCount, f.bottleMl),
                ),
                (
                  care.breast.accent,
                  l10n.trackerBreast,
                  l10n.rhythmBreast(f.breastCount, f.breastMinutes),
                ),
                if (isToday)
                  (cl.colors.controlBorder, l10n.lastFeed, ago(f.lastFeedAt)),
                (
                  cl.colors.controlBorder,
                  l10n.averageGap,
                  f.averageGap == null
                      ? '—'
                      : durationLabel(l10n, f.averageGap!.inMinutes),
                ),
              ],
              footer: strip,
            ),
            const SizedBox(height: ClSpace.s3),
            _LinkCard(
              color: care.bottle,
              title: l10n.feedStatsLink,
              subtitle: l10n.feedStatsLinkHint,
              onTap: () => context.push(Routes.feedStats),
            ),
          ],
        );
      case HistoryFilter.sleep:
        final s = sleepDay(records, bounds.start, bounds.end);
        final running = isToday ? sleepRunning : null;
        return Column(
          children: [
            _StatCard(
              title: isToday ? l10n.sleepToday : l10n.sleepOnDay(dateLabel),
              rows: [
                (care.sleep.accent, l10n.totalSlept, hmDuration(s.total)),
                (care.sleep.accent, l10n.sleepCount, l10n.sleepsValue(s.count)),
                (care.sleep.accent, l10n.longestSleep, hmDuration(s.longest)),
                if (running != null)
                  (
                    cl.colors.controlBorder,
                    l10n.asleepNow,
                    l10n.sinceTime(hm.format(running.startedAt)),
                  )
                else if (isToday && s.lastWokeAt != null)
                  (
                    cl.colors.controlBorder,
                    l10n.awakeNow,
                    l10n.awakeSince(
                      durationLabel(
                        l10n,
                        now.difference(s.lastWokeAt!).inMinutes,
                      ),
                      hm.format(s.lastWokeAt!),
                    ),
                  ),
              ],
              footer: strip,
            ),
            const SizedBox(height: ClSpace.s3),
            _LinkCard(
              color: care.sleep,
              title: l10n.sleepStatsLink,
              subtitle: l10n.sleepStatsLinkHint,
              onTap: () => context.push(Routes.sleepStats),
            ),
          ],
        );
      case HistoryFilter.diaper:
        final d = diaperDay(records, bounds.start, bounds.end);
        return _StatCard(
          title: isToday ? l10n.diaperToday : l10n.diaperOnDay(dateLabel),
          rows: [
            (care.diaper.accent, l10n.diaperTotal, l10n.timesValue(d.total)),
            if (isToday)
              (cl.colors.controlBorder, l10n.diaperLast, ago(d.lastAt)),
            (care.diaper.accent, l10n.diaperWet, l10n.timesValue(d.wet)),
            (care.diaper.accent, l10n.diaperDirty, l10n.timesValue(d.dirty)),
          ],
          footer: strip,
        );
      case HistoryFilter.pump:
        final p = pumpDay(records, bounds.start, bounds.end);
        return _StatCard(
          title: isToday ? l10n.pumpToday : l10n.pumpOnDay(dateLabel),
          rows: [
            (care.pump.accent, l10n.pumpSessions, l10n.timesValue(p.count)),
            (care.pump.accent, l10n.pumpVolume, l10n.amountMl(p.ml)),
          ],
          note: l10n.pumpNotIntake,
        );
      case HistoryFilter.growth || HistoryFilter.solids:
        return const SizedBox.shrink();
    }
  }
}

/// "Ăn dặm hôm nay" (D-085 #3): meals and foods tried for the first time that day, and the way
/// to the diary. Information only.
class _SolidsSummary extends StatelessWidget {
  const _SolidsSummary({
    required this.meals,
    required this.all,
    required this.isToday,
    required this.dateLabel,
  });

  final List<SdMeal> meals;
  final List<SdMeal> all;
  final bool isToday;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottle = context.cl.care.bottle;
    final firsts = {for (final m in meals) ...sdFirstTryIds(m, all)};
    return Column(
      children: [
        _StatCard(
          title: isToday ? l10n.sdSectionToday : l10n.sdHistoryOnDay(dateLabel),
          rows: [
            (
              bottle.accent,
              l10n.sdHistoryMeals,
              l10n.sdMealsCount(meals.length),
            ),
            (
              bottle.accent,
              l10n.sdHistoryNewFoods,
              l10n.sdFoodsCount(firsts.length),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        _LinkCard(
          color: bottle,
          title: l10n.sdHistoryLink,
          subtitle: l10n.sdHistoryLinkHint,
          onTap: () => context.push(SdRoutes.home),
        ),
      ],
    );
  }
}

/// Two-column stat card with coloured keys (20a–20c), an optional strip below.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.rows,
    this.footer,
    this.note,
  });

  final String title;
  final List<(Color, String, String)> rows;
  final Widget? footer;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(height: ClSpace.s3),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: ClSpace.s3,
              runSpacing: ClSpace.s3,
              children: [
                for (final (color, label, value) in rows)
                  SizedBox(
                    width: (c.maxWidth - ClSpace.s3) / 2,
                    child: Container(
                      padding: const EdgeInsets.only(left: ClSpace.s2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: color, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                          Text(value, style: cl.text.headline),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: ClSpace.s3),
            Text(
              note!,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: ClSpace.s3), footer!],
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ClCareColor color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: color.soft,
          borderRadius: BorderRadius.circular(ClRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(ClIcons.clock, size: 18, color: color.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(color: color.ink),
                  ),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 18, color: color.ink),
          ],
        ),
      ),
    );
  }
}

/// TimeSectionHeader (59:431) + TimelineItem (48:407) rows, newest first.
/// The rows of a day, newest first: records, meals and wake-ups merged by time (a span from the
/// night before sits at the day's start), each with its period. [laterSleeps] are sleep starts
/// outside [entries] (the next day's) for the time awake after the day's last sleep.
List<(DateTime, int, CarePeriod, Widget)> _timelineItems({
  required List<TimelineEntry> entries,
  required List<CareTimer> timers,
  required List<SdMeal> meals,
  required String zone,
  required String myUid,
  required DateTime now,
  DateTime? dayEnd,
  Iterable<DateTime> laterSleeps = const [],
}) {
  final items = <(DateTime, int, CarePeriod, Widget)>[];
  for (final e in entries) {
    items.add((
      e.startedBefore ? DateTime.utc(1970) : e.record.occurredAt,
      1,
      e.period,
      _TimelineRow(entry: e, zone: zone, myUid: myUid),
    ));
  }
  for (final meal in meals) {
    items.add((
      meal.occurredAt,
      1,
      periodOfHour(inBabyZone(zone, meal.occurredAt).hour),
      _MealTimelineRow(meal: meal, zone: zone, myUid: myUid),
    ));
  }
  // Owner, 2026-10-22: when the baby woke up is a moment of its own, with how long they were
  // awake until the next sleep (or "đang thức" for the latest one today).
  final sleeps = [
    for (final e in entries)
      if (e.record.type == CareType.sleep && e.record.endedAt != null) e.record,
  ];
  final running = timers
      .where((t) => t.type == TimerType.sleep)
      .map((t) => t.startedAt);
  final starts = [
    ...sleeps.map((r) => r.occurredAt),
    ...running,
    ...laterSleeps,
  ]..sort();
  final today = dayEnd == null || dayEnd.isAfter(now);
  for (final r in sleeps) {
    final end = r.endedAt!;
    if (end.isAfter(now) || (dayEnd != null && !end.isBefore(dayEnd))) {
      continue;
    }
    final next = starts.where((t) => !t.isBefore(end)).firstOrNull;
    items.add((
      end,
      0,
      periodOfHour(inBabyZone(zone, end).hour),
      _WakeRow(
        record: r,
        zone: zone,
        awakeMinutes: next != null
            ? next.difference(end).inMinutes
            : today
            ? now.difference(end).inMinutes
            : null,
        ongoing: next == null && today,
      ),
    ));
  }
  // Newest first; at the same minute the wake-up sits under what followed it.
  items.sort((a, b) {
    final byTime = b.$1.compareTo(a.$1);
    return byTime != 0 ? byTime : b.$2.compareTo(a.$2);
  });
  return items;
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.entries,
    required this.timers,
    required this.zone,
    required this.myUid,
    required this.now,
    this.dayEnd,
    this.meals = const [],
  });

  /// The end of the shown day: a wake-up after it belongs to the next day.
  final DateTime? dayEnd;

  final List<TimelineEntry> entries;
  final List<CareTimer> timers;

  /// Solid meals of the day (D-085 #3), merged by time with the records.
  final List<SdMeal> meals;
  final String zone;
  final String myUid;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final groups = <(CarePeriod, List<Widget>)>[];
    for (final t in timers) {
      final period = periodOfHour(inBabyZone(zone, now).hour);
      final row = _RunningRow(timer: t, myUid: myUid);
      if (groups.isNotEmpty && groups.last.$1 == period) {
        groups.last.$2.add(row);
      } else {
        groups.add((period, [row]));
      }
    }
    void place(CarePeriod period, Widget row) {
      if (groups.isNotEmpty && groups.last.$1 == period) {
        groups.last.$2.add(row);
      } else {
        groups.add((period, [row]));
      }
    }

    final stats = <CarePeriod, _PeriodStats>{};
    for (final e in entries) {
      (stats[e.period] ??= _PeriodStats()).add(e.record);
    }
    final items = _timelineItems(
      entries: entries,
      timers: timers,
      meals: meals,
      zone: zone,
      myUid: myUid,
      now: now,
      dayEnd: dayEnd,
    );
    for (final (_, _, period, row) in items) {
      place(period, row);
    }
    String name(CarePeriod p) => switch (p) {
      CarePeriod.lateNight || CarePeriod.night => l10n.periodNight,
      CarePeriod.evening => l10n.periodEvening,
      CarePeriod.afternoon => l10n.periodAfternoon,
      CarePeriod.noon => l10n.periodNoon,
      CarePeriod.morning => l10n.periodMorning,
    };
    String range(CarePeriod p) => switch (p) {
      CarePeriod.lateNight || CarePeriod.night => '22:00 – 05:00',
      CarePeriod.evening => '18:00 – 22:00',
      CarePeriod.afternoon => '13:00 – 18:00',
      CarePeriod.noon => '11:00 – 13:00',
      CarePeriod.morning => '05:00 – 11:00',
    };
    ClIcons icon(CarePeriod p) => switch (p) {
      CarePeriod.lateNight || CarePeriod.night => ClIcons.sleep,
      CarePeriod.evening || CarePeriod.afternoon => ClIcons.sunset,
      CarePeriod.noon => ClIcons.today,
      CarePeriod.morning => ClIcons.sunrise,
    };
    return Column(
      children: [
        for (final (period, rows) in groups) ...[
          Container(
            margin: const EdgeInsets.only(bottom: ClSpace.s3),
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s3,
              ClSpace.s3,
              ClSpace.s3,
              ClSpace.s2,
            ),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cl.colors.mintDeep,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: ClIcon(
                          icon(period),
                          size: 16,
                          color: cl.colors.onMintDeep,
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Text(name(period), style: cl.text.headline),
                      const SizedBox(width: ClSpace.s2),
                      Text(
                        range(period),
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // The period in words instead of "8 mục" (owner, 2026-10-22).
                if (stats[period] case final st? when !st.empty)
                  Padding(
                    padding: const EdgeInsets.only(left: 28 + ClSpace.s2),
                    child: Text(
                      _summaryLine(l10n, st),
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                const SizedBox(height: ClSpace.s2),
                for (final (i, row) in rows.indexed)
                  _Rail(last: i == rows.length - 1, child: row),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Wraps a row; the rail line under the marker stops on the last item.
class _Rail extends StatelessWidget {
  const _Rail({required this.last, required this.child});
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (!last)
        Positioned(
          left: 48 + 20 - 1,
          top: 44,
          bottom: 0,
          child: Container(width: 2, color: context.cl.colors.separator),
        ),
      child,
    ],
  );
}

class _Marker extends StatelessWidget {
  const _Marker(this.type);
  final CareType type;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: careColor(context, type).soft,
      shape: BoxShape.circle,
    ),
    child: ClArt(careArt(type)),
  );
}

/// What a period holds, for its header chips.
class _PeriodStats {
  int feeds = 0, ml = 0, sleepMinutes = 0, diapers = 0;
  int bottles = 0, breasts = 0, breastMinutes = 0, sleeps = 0;
  bool get empty => feeds == 0 && sleepMinutes == 0 && diapers == 0;

  void add(CareRecord r) {
    switch (r.type) {
      case CareType.bottle:
        feeds++;
        bottles++;
        ml += r.amountMl ?? 0;
      case CareType.breast:
        feeds++;
        breasts++;
        breastMinutes +=
            r.durationMin ??
            (r.endedAt?.difference(r.occurredAt).inMinutes ?? 0);
      case CareType.sleep when r.endedAt != null:
        sleeps++;
        sleepMinutes += r.endedAt!.difference(r.occurredAt).inMinutes;
      case CareType.diaper:
        diapers++;
      default:
    }
  }
}

/// "5 cữ bú · 420 ml · 15 phút bú mẹ · 2 giấc 5g 50p · 2 tã": a period or a day in words.
String _summaryLine(AppLocalizations l10n, _PeriodStats st) => [
  if (st.feeds > 0)
    [
      l10n.dayFeedsLine(st.feeds),
      if (st.ml > 0) l10n.amountMl(st.ml),
    ].join(' · '),
  if (st.breastMinutes > 0) l10n.dayBreastLine(st.breastMinutes),
  if (st.sleepMinutes > 0)
    l10n.daySleepLine(
      st.sleeps,
      compactDuration(l10n, Duration(minutes: st.sleepMinutes)),
    ),
  if (st.diapers > 0) l10n.periodDiapers(st.diapers),
].join(' · ');

/// "Thức dậy · Thức 1 giờ 9 phút" where a sleep ended; opens that sleep.
class _WakeRow extends StatelessWidget {
  const _WakeRow({
    required this.record,
    required this.zone,
    required this.awakeMinutes,
    required this.ongoing,
  });
  final CareRecord record;
  final String zone;
  final int? awakeMinutes;
  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final hm = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final at = hm.format(inBabyZone(zone, record.endedAt!));
    final awake = awakeMinutes;
    final value = awake == null
        ? l10n.careWokeUp
        : ongoing
        ? l10n.careAwakeNow(durationLabel(l10n, awake))
        : l10n.careAwakeFor(durationLabel(l10n, awake));
    return ClPressable(
      key: Key('wake:${record.id}'),
      onPressed: () => context.push('${Routes.record}/${record.id}'),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$at, ${l10n.careWokeUp}, $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClTabularText(
                    at,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cl.colors.sunshineSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                // Ink on the soft warm fill, also in Night care.
                child: ClIcon(ClIcons.sunrise, size: 20, color: cl.colors.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.careWokeUp, style: cl.text.bodyStrong),
                      Text(
                        value,
                        style: cl.text.caption.copyWith(
                          color: ongoing
                              ? cl.colors.mintText
                              : cl.colors.inkMuted,
                          fontWeight: ongoing ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.zone,
    required this.myUid,
  });
  final TimelineEntry entry;
  final String zone;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hm = DateFormat.Hm(locale);
    final r = entry.record;
    // Owner, 2026-10-22: "Bạn ghi" on every row was noise; another person's name stays.
    final who = r.createdBy == myUid ? null : loggedBy(l10n, r, myUid);
    final care = careColor(context, r.type);
    String side(Side? s) => switch (s) {
      Side.left => l10n.sideLeftFull,
      Side.right => l10n.sideRightFull,
      _ => l10n.sideBothFull,
    };
    final span =
        (r.type == CareType.sleep || r.type == CareType.breast) &&
        r.endedAt != null;
    final start = inBabyZone(zone, r.occurredAt);
    final (title, detail) = switch (r.type) {
      CareType.sleep => (
        l10n.rowSleep(
          durationLabel(l10n, r.endedAt!.difference(r.occurredAt).inMinutes),
        ),
        [
          l10n.rowSpan(
            entry.startedBefore
                ? l10n.rowYesterdayTime(hm.format(start))
                : hm.format(start),
            hm.format(inBabyZone(zone, r.endedAt!)),
          ),
          ?who,
        ].join(' · '),
      ),
      CareType.breast => (
        l10n.rowBreastSide(side(r.side)),
        [
          if (r.durationMin != null) durationLabel(l10n, r.durationMin!),
          ?who,
        ].join(' · '),
      ),
      CareType.pump => (
        recordSummary(l10n, locale, r),
        [
          side(r.side),
          if (r.durationMin != null) durationLabel(l10n, r.durationMin!),
          ?who,
        ].join(' · '),
      ),
      CareType.growth => (
        recordSummary(l10n, locale, r),
        [
          if (r.lengthCm != null) l10n.lengthCm(decimal(locale, r.lengthCm!)),
          if (r.headCm != null) l10n.headCm(decimal(locale, r.headCm!)),
          ?who,
        ].join(' · '),
      ),
      _ => (recordSummary(l10n, locale, r), who ?? ''),
    };
    final minutes = (r.endedAt ?? r.occurredAt)
        .difference(r.occurredAt)
        .inMinutes;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: cl.text.bodyStrong)),
            if (r.pending) PendingChip(label: l10n.pendingChip),
          ],
        ),
        if (detail.isNotEmpty)
          Text(
            detail,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        if (span) ...[
          const SizedBox(height: ClSpace.s1),
          // Duration bar, proportional up to 8 h.
          FractionallySizedBox(
            widthFactor: (0.15 + 0.85 * (minutes / 480)).clamp(0.15, 1.0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: care.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
    return ClPressable(
      onPressed: () => context.push('${Routes.record}/${r.id}'),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel:
          '${hm.format(start)}, $title, $detail${r.pending ? ', ${l10n.carePending}' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClTabularText(
                    hm.format(start),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
              _Marker(r.type),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: span
                    ? Container(
                        padding: const EdgeInsets.all(ClSpace.s3),
                        decoration: BoxDecoration(
                          color: care.soft,
                          borderRadius: BorderRadius.circular(ClRadius.control),
                        ),
                        child: body,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: body,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A solid meal in the timeline (D-085 #3): its time, the feeding marker, the dish, "Ăn dặm ·
/// ½ chén · Thích · Mẹ ghi", "Có dấu hiệu"; opens meal detail.
class _MealTimelineRow extends ConsumerWidget {
  const _MealTimelineRow({
    required this.meal,
    required this.zone,
    required this.myUid,
  });
  final SdMeal meal;
  final String zone;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final hm = DateFormat.Hm(tag);
    final bottle = cl.care.bottle;
    final foods = ref.watch(sdStateProvider)?.foods ?? const <String, SdFood>{};
    final title = sdMealTitle(meal, foods, locale);
    final detail = [
      l10n.careSolids,
      if (sdMealLine(l10n, tag, meal) case final line when line.isNotEmpty)
        line,
      sdLoggedBy(l10n, meal, myUid),
    ].join(' · ');
    final time = hm.format(inBabyZone(zone, meal.occurredAt));
    return ClPressable(
      key: Key('historyMeal_${meal.id}'),
      onPressed: () => context.push(SdRoutes.meal(meal.id)),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [
        '$time, $title, $detail',
        if (meal.hasSymptoms) l10n.sdSignsTag,
        if (meal.pending) l10n.carePending,
      ].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClTabularText(
                    time,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bottle.soft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClIcon(ClIcons.feed, size: 20, color: bottle.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: cl.text.bodyStrong,
                            ),
                          ),
                          if (meal.pending)
                            PendingChip(label: l10n.pendingChip),
                        ],
                      ),
                      Text(
                        detail,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      if (meal.hasSymptoms) ...[
                        const SizedBox(height: ClSpace.s1),
                        SdTag.signs(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A running timer in today's timeline (G-067).
class _RunningRow extends ConsumerWidget {
  const _RunningRow({required this.timer, required this.myUid});
  final CareTimer timer;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hm = DateFormat.Hm(locale);
    final care = careColor(context, timer.type.careType);
    final who = authorLabel(
      l10n,
      timer.author,
      isMe: timer.startedBy == myUid,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );
    return ClPressable(
      onPressed: () => context.push('${Routes.timer}/${timer.type.name}'),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel:
          '${careTypeLabel(l10n, timer.type.careType)}, ${l10n.rowRunning}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClTabularText(
                    hm.format(timer.startedAt),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
              _Marker(timer.type.careType),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(ClSpace.s3),
                  decoration: BoxDecoration(
                    color: care.soft,
                    borderRadius: BorderRadius.circular(ClRadius.control),
                    border: Border.all(color: care.accent, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${careTypeLabel(l10n, timer.type.careType)} · ${l10n.rowRunning}',
                        style: cl.text.bodyStrong,
                      ),
                      Text(
                        l10n.runningSince(hm.format(timer.startedAt), who),
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 20e (105:9471): nothing for this filter on this day, with "Ghi bù" and "Xem tất cả".
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({
    required this.filter,
    required this.isToday,
    required this.dateLabel,
    required this.readOnly,
    required this.onLog,
    required this.onSeeAll,
  });

  final HistoryFilter filter;
  final bool isToday;
  final String dateLabel;
  final bool readOnly;
  final VoidCallback onLog;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final what = switch (filter) {
      HistoryFilter.solids => l10n.sdHistoryWhat,
      HistoryFilter.feed => l10n.emptyFeedWhat,
      HistoryFilter.pump => l10n.emptyPumpWhat,
      HistoryFilter.sleep => l10n.emptySleepWhat,
      HistoryFilter.diaper => l10n.emptyDiaperWhat,
      _ => l10n.emptyAllWhat,
    };
    final art = switch (filter) {
      HistoryFilter.feed || HistoryFilter.solids => ClIllustration.miniBottle,
      HistoryFilter.pump => ClIllustration.miniPump,
      HistoryFilter.sleep => ClIllustration.miniMoon,
      HistoryFilter.diaper => ClIllustration.miniDiaper,
      _ => ClIllustration.miniRuler,
    };
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClSpace.s6),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            children: [
              ClArt(art, width: 72, height: 72),
              const SizedBox(height: ClSpace.s3),
              Text(
                isToday
                    ? l10n.emptyTodayTitle(what)
                    : l10n.emptyDayTitle(what, dateLabel),
                textAlign: TextAlign.center,
                style: cl.text.headline,
              ),
              const SizedBox(height: ClSpace.s1),
              Text(
                l10n.emptyDayBody,
                textAlign: TextAlign.center,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              if (!readOnly) ...[
                const SizedBox(height: ClSpace.s4),
                ClButton(
                  label: isToday ? l10n.logNow(what) : l10n.backLog(what),
                  style: ClButtonStyle.tinted,
                  icon: ClIcons.plus,
                  expand: true,
                  onPressed: onLog,
                ),
              ],
            ],
          ),
        ),
        if (filter != HistoryFilter.all) ...[
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.seeAllOnDay(dateLabel),
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: onSeeAll,
          ),
        ],
      ],
    );
  }
}

/// 20d (105:9063): latest measurement, weight / length toggle, change since the previous one,
/// a time-proportional line (no percentiles, R-056) and every measurement.
class _GrowthPanel extends ConsumerStatefulWidget {
  const _GrowthPanel({
    required this.records,
    required this.myUid,
    required this.dob,
    required this.readOnly,
    this.gender,
    this.nickname = '',
  });

  final List<CareRecord> records;
  final String myUid;
  final DateTime? dob;
  final bool readOnly;

  /// For the WHO comparison (v1.0 improvement 20d); without it the plain line chart shows.
  final Gender? gender;
  final String nickname;

  @override
  ConsumerState<_GrowthPanel> createState() => _GrowthPanelState();
}

class _GrowthPanelState extends ConsumerState<_GrowthPanel> {
  /// Cân nặng / Chiều dài / Vòng đầu (owner 2026-10-16).
  GrowthMeasure _measure = GrowthMeasure.weight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final care = cl.care.growth;
    final reference = ref.watch(growthReferenceProvider);
    final all = [...widget.records]
      ..sort(
        (a, b) => (b.measuredOn ?? b.occurredAt).compareTo(
          a.measuredOn ?? a.occurredAt,
        ),
      );
    if (all.isEmpty) {
      return Column(
        children: [
          Text(
            l10n.growthEmpty,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.growthAdd,
              style: ClButtonStyle.tinted,
              icon: ClIcons.plus,
              expand: true,
              onPressed: () => context.push(Routes.growth),
            ),
          ],
        ],
      );
    }
    final latest = all.first;
    final previous = all.length > 1 ? all[1] : null;
    String signed(double v, String unit) =>
        '${v >= 0 ? '+' : '−'}${decimal(locale, v.abs())} $unit';
    String? deltaOf(CareRecord r, CareRecord? prev) {
      if (prev == null || r.weightKg == null || prev.weightKg == null) {
        return null;
      }
      return [
        signed(r.weightKg! - prev.weightKg!, 'kg'),
        if (r.lengthCm != null && prev.lengthCm != null)
          signed(r.lengthCm! - prev.lengthCm!, 'cm'),
        if (r.headCm != null && prev.headCm != null)
          l10n.headCm(signed(r.headCm! - prev.headCm!, '').trim()),
      ].join(' · ');
    }

    final m = _measure;
    String valueLabel(double v) => m == GrowthMeasure.weight
        ? l10n.weightKg(decimal(locale, v))
        : l10n.lengthCm(decimal(locale, v));
    final points = [
      for (final r in all.reversed)
        if (r.measure(m) != null) (r.measuredOn ?? r.occurredAt, r.measure(m)!),
    ];
    final primary = latest.measure(m) == null
        ? '—'
        : valueLabel(latest.measure(m)!);
    final secondary = m != GrowthMeasure.weight
        ? l10n.weightKg(decimal(locale, latest.weightKg ?? 0))
        : (latest.lengthCm == null
              ? null
              : l10n.lengthCm(decimal(locale, latest.lengthCm!)));
    final delta = previous == null || latest.measure(m) == null
        ? null
        : l10n.growthDeltaVs(
            [
              m != GrowthMeasure.weight &&
                      latest.measure(m) != null &&
                      previous.measure(m) != null
                  ? signed(latest.measure(m)! - previous.measure(m)!, 'cm')
                  : signed(
                      (latest.weightKg ?? 0) - (previous.weightKg ?? 0),
                      'kg',
                    ),
            ].join(),
            shortDate(context, previous.measuredOn ?? previous.occurredAt),
          );

    // v1.0 improvement 20d: the latest value with the baby's age, its place against the WHO
    // normal band (347:935 when outside it), the WHO chart and the way to 20i.
    final measure = m;
    final boy = switch (widget.gender) {
      Gender.boy => true,
      Gender.girl => false,
      _ => null,
    };
    final dob = widget.dob == null ? null : DateUtils.dateOnly(widget.dob!);
    int? ageOn(CareRecord r) => dob == null
        ? null
        : DateUtils.dateOnly(
            r.measuredOn ?? r.occurredAt,
          ).difference(dob).inDays;
    final shown = all.where((r) => r.measure(m) != null).toList();
    final current = shown.firstOrNull;
    final currentValue = current?.measure(m);
    final currentAge = current == null ? null : ageOn(current);
    final band = boy == null || currentAge == null || currentValue == null
        ? null
        : reference.band(
            measure,
            boy: boy,
            ageDays: currentAge,
            value: currentValue,
          );
    final range = boy == null || currentAge == null
        ? null
        : reference.range(measure, boy: boy, ageDays: currentAge);
    String ageText(int days) => days < 14
        ? l10n.ageDays(days)
        : days < 13 * 7
        ? l10n.ageWeeks(days ~/ 7)
        : l10n.ageMonths((days / 30.4375).floor());
    final unit = m == GrowthMeasure.weight ? 'kg' : 'cm';
    final whoPoints = [
      for (final r in shown.reversed)
        if (ageOn(r) != null && ageOn(r)! >= 0) (ageOn(r)!, r.measure(m)!),
    ];
    final outside = band != null && band != GrowthBand.normal;
    Widget pill(String text, Color bg, Color ink, {ClIcons? icon}) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s3,
        vertical: ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon, size: 13, color: ink),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: cl.text.caption.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClSegmented<GrowthMeasure>(
                options: GrowthMeasure.values,
                selected: m,
                labelOf: (x) => growthMeasureTab(l10n, x),
                onChanged: (x) => setState(() => _measure = x),
              ),
              const SizedBox(height: ClSpace.s3),
              if (shown.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentValue == null ? primary : valueLabel(currentValue),
                      style: cl.text.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        currentAge != null && currentAge >= 0
                            ? ' · ${ageText(currentAge)}'
                            : (secondary == null ? '' : ' · $secondary'),
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: ClSpace.s2),
              Wrap(
                spacing: ClSpace.s2,
                runSpacing: ClSpace.s2,
                children: [
                  if (band == GrowthBand.normal)
                    pill(
                      l10n.whoNormal,
                      cl.colors.mintSoft,
                      cl.colors.mintText,
                      icon: ClIcons.check,
                    )
                  else if (band != null)
                    pill(
                      band == GrowthBand.below ? l10n.whoBelow : l10n.whoAbove,
                      cl.colors.sunshineSoft,
                      cl.colors.ink,
                      icon: ClIcons.alert,
                    ),
                  if (outside && range != null)
                    pill(
                      band == GrowthBand.below
                          ? l10n.whoLowerEdge(
                              '${decimal(locale, range.low)} $unit',
                            )
                          : l10n.whoUpperEdge(
                              '${decimal(locale, range.high)} $unit',
                            ),
                      cl.colors.surface2,
                      cl.colors.ink,
                    )
                  else if (delta != null)
                    pill(delta, cl.colors.peachSoft, cl.colors.ink),
                ],
              ),
              if (outside) ...[
                const SizedBox(height: ClSpace.s3),
                Container(
                  padding: const EdgeInsets.all(ClSpace.s3),
                  decoration: BoxDecoration(
                    color: cl.colors.sunshineSoft,
                    borderRadius: BorderRadius.circular(ClRadius.control),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClIcon(ClIcons.heart, size: 16, color: cl.colors.ink),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(switch ((band, m)) {
                          (GrowthBand.below, GrowthMeasure.weight) =>
                            l10n.whoBelowWeightNote(widget.nickname),
                          (GrowthBand.below, GrowthMeasure.length) =>
                            l10n.whoBelowLengthNote(widget.nickname),
                          (GrowthBand.below, GrowthMeasure.head) =>
                            l10n.whoBelowHeadNote(widget.nickname),
                          (_, GrowthMeasure.weight) => l10n.whoAboveWeightNote(
                            widget.nickname,
                          ),
                          (_, GrowthMeasure.length) => l10n.whoAboveLengthNote(
                            widget.nickname,
                          ),
                          (_, GrowthMeasure.head) => l10n.whoAboveHeadNote(
                            widget.nickname,
                          ),
                        }, style: cl.text.label.copyWith(color: cl.colors.ink)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: ClSpace.s3),
              // Nothing measured of this kind yet (a head circumference before 2026-10-16).
              if (shown.isEmpty)
                Text(
                  l10n.growthMeasureNone,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                )
              else if (boy != null && whoPoints.isNotEmpty) ...[
                ExcludeSemantics(
                  child: WhoGrowthChart(
                    measure: measure,
                    boy: boy,
                    points: whoPoints,
                    unit: unit,
                    reference: reference,
                    axisLabel: (a) => a.value == 0
                        ? l10n.whoBirth
                        : a.weeks
                        ? l10n.whoWeeks(a.value)
                        : l10n.whoMonths(a.value),
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s3,
                  children: [
                    for (final (color, label) in [
                      (cl.colors.mintSoft, l10n.whoBand),
                      (cl.colors.mintDeep, l10n.whoMedianLine),
                      (cl.colors.peach, widget.nickname),
                    ])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ] else
                ExcludeSemantics(
                  child: SizedBox(
                    height: 150,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _GrowthLinePainter(
                        points: points,
                        line: care.accent,
                        grid: cl.colors.separator,
                        label: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                        surface: cl.colors.surface,
                        unit: unit,
                        dateLabel: (d) => shortDate(context, d),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: ClSpace.s3),
              ClPressable(
                onPressed: () =>
                    GrowthStandardsScreen.open(context, measure: m),
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: l10n.whoOpen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: ClSpace.s3,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(ClRadius.control),
                  ),
                  child: Row(
                    children: [
                      ClIcon(
                        ClIcons.ruler,
                        size: 18,
                        color: cl.colors.mintText,
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(
                          l10n.whoOpen,
                          style: cl.text.label.copyWith(
                            color: cl.colors.mintText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ClIcon(
                        ClIcons.chevronRight,
                        size: 18,
                        color: cl.colors.mintText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(title: l10n.growthMeasurements),
        const SizedBox(height: ClSpace.s2),
        for (final (i, r) in all.indexed)
          _Rail(
            last: i == all.length - 1,
            child: ClPressable(
              onPressed: () => context.push('${Routes.record}/${r.id}'),
              pressedOpacity: ClPressable.surfaceOpacity,
              semanticLabel: recordSummary(l10n, locale, r),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortDate(context, r.measuredOn ?? r.occurredAt),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const _Marker(CareType.growth),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                l10n.weightKg(decimal(locale, r.weightKg ?? 0)),
                                if (r.lengthCm != null)
                                  l10n.lengthCm(decimal(locale, r.lengthCm!)),
                                if (r.headCm != null)
                                  l10n.headCm(decimal(locale, r.headCm!)),
                              ].join(' · '),
                              style: cl.text.bodyStrong,
                            ),
                            Text(
                              [
                                if (i == all.length - 1 &&
                                    widget.dob != null &&
                                    DateUtils.isSameDay(
                                      r.measuredOn,
                                      widget.dob,
                                    ))
                                  l10n.growthAtBirth
                                else
                                  ?deltaOf(
                                    r,
                                    i + 1 < all.length ? all[i + 1] : null,
                                  ),
                                loggedBy(l10n, r, widget.myUid),
                              ].join(' · '),
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
              ),
            ),
          ),
        if (!widget.readOnly) ...[
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.growthAdd,
            style: ClButtonStyle.tinted,
            icon: ClIcons.plus,
            expand: true,
            onPressed: () => context.push(Routes.growth),
          ),
        ],
      ],
    );
  }
}

class _GrowthLinePainter extends CustomPainter {
  _GrowthLinePainter({
    required this.points,
    required this.line,
    required this.grid,
    required this.label,
    required this.surface,
    required this.unit,
    required this.dateLabel,
  });

  final List<(DateTime, double)> points;
  final Color line;
  final Color grid;
  final TextStyle label;
  final Color surface;
  final String unit;
  final String Function(DateTime) dateLabel;

  void _text(
    Canvas c,
    String s,
    Offset at, {
    bool right = false,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: label),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right
        ? at.dx - tp.width
        : (center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 36.0, bottom = 22.0, top = 8.0, right = 8.0;
    final values = points.map((p) => p.$2);
    var lo = values.reduce(math.min).floorToDouble();
    var hi = values.reduce(math.max).ceilToDouble();
    if (hi - lo < 2) {
      hi = lo + 2;
    }
    final step = ((hi - lo) / 2).ceilToDouble();
    lo = hi - step * 2;
    final h = size.height - bottom - top;
    final w = size.width - left - right;
    double y(double v) => top + h * (1 - (v - lo) / (hi - lo));
    final first = points.first.$1;
    final span = math.max(1, points.last.$1.difference(first).inDays);
    double x(DateTime d) =>
        left +
        w * (points.length == 1 ? 0.5 : d.difference(first).inDays / span);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var v = lo; v <= hi + 0.01; v += step) {
      canvas.drawLine(
        Offset(left, y(v)),
        Offset(size.width - right, y(v)),
        gridPaint,
      );
      _text(canvas, '${v.round()} $unit', Offset(0, y(v)));
    }
    final path = Path();
    for (final (i, p) in points.indexed) {
      final o = Offset(x(p.$1), y(p.$2));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final (i, p) in points.indexed) {
      final o = Offset(x(p.$1), y(p.$2));
      final lastPoint = i == points.length - 1;
      canvas
        ..drawCircle(o, 6, Paint()..color = lastPoint ? line : surface)
        ..drawCircle(
          o,
          6,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      _text(
        canvas,
        dateLabel(p.$1),
        Offset(o.dx, size.height - bottom / 2),
        right: lastPoint && points.length > 1,
        center: !lastPoint && i != 0,
      );
    }
  }

  @override
  bool shouldRepaint(_GrowthLinePainter old) =>
      old.points != points || old.line != line;
}

/// 20f Chọn ngày (108:10271): month grid starting Monday, dots on days with records, nothing
/// before birth or after today, "Về hôm nay".
Future<DateTime?> showHistoryDatePicker(
  BuildContext context, {
  required DateTime selected,
  required DateTime today,
  required DateTime? dob,
  required String babyId,
  required String nickname,
}) => showClSheet<DateTime>(
  context: context,
  builder: (_) => _DatePickerSheet(
    selected: selected,
    today: today,
    dob: dob == null ? null : DateUtils.dateOnly(dob),
    babyId: babyId,
    nickname: nickname,
  ),
);

class _DatePickerSheet extends ConsumerStatefulWidget {
  const _DatePickerSheet({
    required this.selected,
    required this.today,
    required this.dob,
    required this.babyId,
    required this.nickname,
  });

  final DateTime selected;
  final DateTime today;
  final DateTime? dob;
  final String babyId;
  final String nickname;

  @override
  ConsumerState<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends ConsumerState<_DatePickerSheet> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = DateTime(_month.year, _month.month);
    final daysIn = DateUtils.getDaysInMonth(_month.year, _month.month);
    final marks =
        ref
            .watch(
              dayMarksProvider((
                widget.babyId,
                isoDate(first),
                isoDate(DateTime(_month.year, _month.month, daysIn)),
              )),
            )
            .value ??
        const <String, DayMarks>{};
    final canNext = DateTime(
      _month.year,
      _month.month + 1,
    ).isBefore(DateTime(widget.today.year, widget.today.month + 1));
    final canPrev =
        widget.dob == null ||
        DateTime(
          _month.year,
          _month.month,
        ).isAfter(DateTime(widget.dob!.year, widget.dob!.month));
    final lead = first.weekday - 1; // Monday first
    final weekdays = [
      for (var i = 0; i < 7; i++)
        weekdayShort(locale, DateTime(2026, 10, 5 + i)),
    ];
    final monthTitle = locale.startsWith('vi')
        ? l10n.calendarMonth(_month.month, _month.year, '')
        : l10n.calendarMonth(
            0,
            _month.year,
            DateFormat.MMMM(locale).format(_month),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.pickDateTitle),
        Row(
          children: [
            Opacity(
              opacity: canPrev ? 1 : 0.35,
              child: ClPressable(
                onPressed: canPrev
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      )
                    : null,
                semanticLabel: l10n.a11yPrevMonth,
                child: ClIcon(ClIcons.back, color: cl.colors.ink),
              ),
            ),
            Expanded(
              child: Text(
                monthTitle,
                textAlign: TextAlign.center,
                style: cl.text.headline,
              ),
            ),
            Opacity(
              opacity: canNext ? 1 : 0.35,
              child: ClPressable(
                onPressed: canNext
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      )
                    : null,
                semanticLabel: l10n.a11yNextMonth,
                child: ClIcon(ClIcons.chevronRight, color: cl.colors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysIn; d++)
              () {
                final date = DateTime(_month.year, _month.month, d);
                final future = date.isAfter(widget.today);
                final beforeBirth =
                    widget.dob != null && date.isBefore(widget.dob!);
                final enabled = !future && !beforeBirth;
                final selected = date == widget.selected;
                final mark = marks[isoDate(date)];
                return Opacity(
                  opacity: enabled ? 1 : 0.35,
                  child: ClPressable(
                    onPressed: enabled
                        ? () => Navigator.of(context).pop(date)
                        : null,
                    selected: selected,
                    semanticLabel: DateFormat.yMMMMd(locale).format(date),
                    minSize: const Size(40, 40),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected ? cl.colors.mintDeep : null,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$d',
                            style: cl.text.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? cl.colors.onMintDeep
                                  : cl.colors.ink,
                            ),
                          ),
                          if (mark != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final (on, color) in [
                                  (mark.feeds, cl.care.bottle.accent),
                                  (mark.sleep, cl.care.sleep.accent),
                                  (mark.diapers, cl.care.diaper.accent),
                                  (
                                    mark.other &&
                                        !mark.feeds &&
                                        !mark.sleep &&
                                        !mark.diapers,
                                    cl.colors.inkMuted,
                                  ),
                                ])
                                  if (on)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }(),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          widget.dob == null
              ? l10n.calendarFootnoteNoDob
              : l10n.calendarFootnote(
                  widget.nickname,
                  DateFormat(
                    locale.startsWith('vi') ? "d 'tháng' M" : 'd MMMM',
                    locale,
                  ).format(widget.dob!),
                ),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.backToToday,
          style: ClButtonStyle.tinted,
          expand: true,
          onPressed: () => Navigator.of(context).pop(widget.today),
        ),
      ],
    );
  }
}

/// The Thống kê timeline (owner, 2026-10-22): the chosen range day by day, newest first, each
/// day headed by its totals (how many, how many ml, how many minutes), then the same rows as
/// Lịch sử. The latest [expanded] days are open, older ones open on tap.
class CareDaysTimeline extends ConsumerStatefulWidget {
  const CareDaysTimeline({
    required this.days,
    required this.records,
    required this.zone,
    required this.now,
    required this.types,
    this.expanded = 3,
    super.key,
  });

  /// Each day's bounds, oldest first (as the charts).
  final List<({DateTime start, DateTime end})> days;
  final List<CareRecord> records;
  final String zone;
  final DateTime now;
  final Set<CareType> types;
  final int expanded;

  @override
  ConsumerState<CareDaysTimeline> createState() => _CareDaysTimelineState();
}

class _CareDaysTimelineState extends ConsumerState<CareDaysTimeline> {
  final _toggled = <DateTime>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final myUid = ref.watch(selectedMembershipProvider)?.uid ?? '';
    final zone = widget.zone;
    final now = widget.now;
    final matching = [
      for (final r in widget.records)
        if (widget.types.contains(r.type) && !r.deleted) r,
    ];
    final sleepStarts = [
      for (final r in matching)
        if (r.type == CareType.sleep) r.occurredAt,
    ];
    final cards = <Widget>[];
    for (final (i, day) in widget.days.reversed.indexed) {
      if (day.start.isAfter(now)) continue;
      final entries = timelineOf(matching, zone, day.start, day.end);
      final stats = _PeriodStats();
      for (final e in entries) {
        if (e.startedBefore) continue;
        stats.add(e.record);
        // A sleep running past midnight counts only its part of this day.
        final end = e.record.endedAt;
        if (e.record.type == CareType.sleep &&
            end != null &&
            end.isAfter(day.end)) {
          stats.sleepMinutes -= end.difference(day.end).inMinutes;
        }
      }
      // A sleep from the night before counts for the day it runs into, as the strip shows it.
      for (final e in entries) {
        if (e.startedBefore && e.record.type == CareType.sleep) {
          stats.sleeps++;
          stats.sleepMinutes += e.record.endedAt!
              .difference(day.start)
              .inMinutes;
        }
      }
      final open = (i < widget.expanded) != _toggled.contains(day.start);
      final d = inBabyZone(zone, day.start);
      final isToday = day.end.isAfter(now);
      final label = [
        if (isToday) l10n.todayLabel,
        '${weekdayShort(locale, d)} ${d.day}/${d.month}',
      ].join(' · ');
      final rows = open
          ? [
              for (final (_, _, _, row) in _timelineItems(
                entries: entries,
                timers: const [],
                meals: const [],
                zone: zone,
                myUid: myUid,
                now: now,
                dayEnd: day.end,
                laterSleeps: sleepStarts.where((t) => !t.isBefore(day.end)),
              ))
                row,
            ]
          : const <Widget>[];
      cards.add(
        Container(
          key: Key('statsDay:${d.year}-${d.month}-${d.day}'),
          margin: const EdgeInsets.only(bottom: ClSpace.s3),
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s3,
            ClSpace.s3,
            ClSpace.s3,
            ClSpace.s2,
          ),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClPressable(
                onPressed: entries.isEmpty
                    ? null
                    : () => setState(() {
                        if (!_toggled.remove(day.start)) {
                          _toggled.add(day.start);
                        }
                      }),
                semanticLabel: label,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(label, style: cl.text.headline),
                          ),
                        ),
                        if (entries.isNotEmpty)
                          ClIcon(
                            open ? ClIcons.chevronDown : ClIcons.chevronRight,
                            size: 18,
                            color: cl.colors.inkMuted,
                          ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s2),
                    if (stats.empty)
                      Text(
                        l10n.dayNothingLogged,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      )
                    else
                      Text(
                        _summaryLine(l10n, stats),
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: ClSpace.s2),
                for (final (j, row) in rows.indexed)
                  _Rail(last: j == rows.length - 1, child: row),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: ClSpace.s1, bottom: ClSpace.s3),
          child: Text(l10n.dayStripsTitle, style: cl.text.title2),
        ),
        ...cards,
      ],
    );
  }
}
