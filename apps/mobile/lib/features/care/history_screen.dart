import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
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
import 'care_repository.dart';
import 'care_screens.dart';
import 'care_sheets.dart';
import 'timer_models.dart';

/// Filter chips (single-select): Tất cả · Bú · Hút sữa · Ngủ · Tã · Tăng trưởng (20–20d).
enum HistoryFilter { all, feed, pump, sleep, diaper, growth }

bool _matchesType(HistoryFilter f, CareType type) => switch (f) {
  HistoryFilter.all => true,
  // "Bú" = bottle + breast; pumping has its own chip (104:8724).
  HistoryFilter.feed => type == CareType.bottle || type == CareType.breast,
  HistoryFilter.pump => type == CareType.pump,
  HistoryFilter.sleep => type == CareType.sleep,
  HistoryFilter.diaper => type == CareType.diaper,
  HistoryFilter.growth => type == CareType.growth,
};

bool _matches(HistoryFilter f, CareRecord r) => _matchesType(f, r.type);

String _filterLabel(AppLocalizations l10n, HistoryFilter f) => switch (f) {
  HistoryFilter.all => l10n.filterAll,
  HistoryFilter.feed => l10n.filterFeed,
  HistoryFilter.pump => l10n.filterPump,
  HistoryFilter.sleep => l10n.filterSleep,
  HistoryFilter.diaper => l10n.filterDiaper,
  HistoryFilter.growth => l10n.filterGrowth,
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
    final dob = me.canViewBabyInfo
        ? ref.watch(babyPrivateProfileProvider(babyId)).value?.dateOfBirth
        : null;
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
    final matching = [
      for (final r in records)
        if (_matches(_filter, r)) r,
    ];
    final entries = timelineOf(matching, zone, bounds.start, bounds.end);
    final timers = [
      for (final type in TimerType.values)
        if (isToday && _matchesType(_filter, type.careType))
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
      if (_filter != HistoryFilter.growth) ...[
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
            for (final (i, f) in HistoryFilter.values.indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s2),
              ClFilterChip(
                key: _filter == f ? _selectedChip : null,
                label: _filterLabel(l10n, f),
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s4),
    ];

    if (_filter == HistoryFilter.growth) {
      children.add(
        _GrowthPanel(
          records: growth,
          myUid: me.uid,
          dob: dob,
          readOnly: readOnly,
        ),
      );
    } else if (entries.isEmpty && timers.isEmpty) {
      children.add(
        _EmptyDay(
          filter: _filter,
          isToday: isToday,
          dateLabel: dateLabel,
          readOnly: readOnly,
          onLog: () => _backLog(context, day, isToday, zone),
          onSeeAll: () => setState(() => _filter = HistoryFilter.all),
        ),
      );
    } else {
      children
        ..add(
          _SummaryCard(
            filter: _filter,
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
            timers: timers.whereType<CareTimer>().toList(),
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
      case HistoryFilter.growth:
        return const SizedBox.shrink();
    }
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
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.entries,
    required this.timers,
    required this.zone,
    required this.myUid,
    required this.now,
  });

  final List<TimelineEntry> entries;
  final List<CareTimer> timers;
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
    for (final e in entries) {
      final row = _TimelineRow(entry: e, zone: zone, myUid: myUid);
      if (groups.isNotEmpty && groups.last.$1 == e.period) {
        groups.last.$2.add(row);
      } else {
        groups.add((e.period, [row]));
      }
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClSpace.s2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.surface2,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          l10n.periodItems(rows.length),
                          style: cl.text.caption,
                        ),
                      ),
                    ],
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
    final who = loggedBy(l10n, r, myUid);
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
        '${l10n.rowSpan(entry.startedBefore ? l10n.rowYesterdayTime(hm.format(start)) : hm.format(start), hm.format(inBabyZone(zone, r.endedAt!)))} · $who',
      ),
      CareType.breast => (
        l10n.rowBreastSide(side(r.side)),
        [
          if (r.durationMin != null) durationLabel(l10n, r.durationMin!),
          who,
        ].join(' · '),
      ),
      CareType.pump => (
        recordSummary(l10n, locale, r),
        [
          side(r.side),
          if (r.durationMin != null) durationLabel(l10n, r.durationMin!),
          who,
        ].join(' · '),
      ),
      CareType.growth => (
        recordSummary(l10n, locale, r),
        [
          if (r.lengthCm != null) l10n.lengthCm(decimal(locale, r.lengthCm!)),
          who,
        ].join(' · '),
      ),
      _ => (recordSummary(l10n, locale, r), who),
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
      HistoryFilter.feed => l10n.emptyFeedWhat,
      HistoryFilter.pump => l10n.emptyPumpWhat,
      HistoryFilter.sleep => l10n.emptySleepWhat,
      HistoryFilter.diaper => l10n.emptyDiaperWhat,
      _ => l10n.emptyAllWhat,
    };
    final art = switch (filter) {
      HistoryFilter.feed => ClIllustration.miniBottle,
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
  });

  final List<CareRecord> records;
  final String myUid;
  final DateTime? dob;
  final bool readOnly;

  @override
  ConsumerState<_GrowthPanel> createState() => _GrowthPanelState();
}

class _GrowthPanelState extends ConsumerState<_GrowthPanel> {
  bool _length = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final care = cl.care.growth;
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
    final today = DateUtils.dateOnly(
      ref.watch(careClockProvider).value ?? DateTime.now(),
    );
    String when(DateTime d) =>
        DateUtils.isSameDay(d, today) ? l10n.dayToday : shortDate(context, d);
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
      ].join(' · ');
    }

    final points = [
      for (final r in all.reversed)
        if ((_length ? r.lengthCm : r.weightKg) != null)
          (r.measuredOn ?? r.occurredAt, _length ? r.lengthCm! : r.weightKg!),
    ];
    final primary = _length
        ? l10n.lengthCm(decimal(locale, latest.lengthCm ?? 0))
        : l10n.weightKg(decimal(locale, latest.weightKg ?? 0));
    final secondary = _length
        ? l10n.weightKg(decimal(locale, latest.weightKg ?? 0))
        : (latest.lengthCm == null
              ? null
              : l10n.lengthCm(decimal(locale, latest.lengthCm!)));
    final delta = previous == null
        ? null
        : l10n.growthDeltaVs(
            [
              _length && latest.lengthCm != null && previous.lengthCm != null
                  ? signed(latest.lengthCm! - previous.lengthCm!, 'cm')
                  : signed(
                      (latest.weightKg ?? 0) - (previous.weightKg ?? 0),
                      'kg',
                    ),
            ].join(),
            shortDate(context, previous.measuredOn ?? previous.occurredAt),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.growthLatest(
                        when(latest.measuredOn ?? latest.occurredAt),
                      ),
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                  _MiniToggle(
                    options: [l10n.growthWeightTab, l10n.growthLengthTab],
                    selected: _length ? 1 : 0,
                    onChanged: (i) => setState(() => _length = i == 1),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    primary,
                    style: cl.text.title.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (secondary != null)
                    Text(
                      ' · $secondary',
                      style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                    ),
                ],
              ),
              if (delta != null) ...[
                const SizedBox(height: ClSpace.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: ClSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: care.soft,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    delta,
                    style: cl.text.caption.copyWith(color: care.ink),
                  ),
                ),
              ],
              const SizedBox(height: ClSpace.s3),
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
                      unit: _length ? 'cm' : 'kg',
                      dateLabel: (d) => shortDate(context, d),
                    ),
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

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, o) in options.indexed)
            ClPressable(
              onPressed: () => onChanged(i),
              selected: i == selected,
              semanticLabel: o,
              minSize: const Size(44, 32),
              child: AnimatedContainer(
                duration: context.motion(ClMotion.quick),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s3,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? cl.colors.surface : null,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                  boxShadow: i == selected ? cl.shadows.card : null,
                ),
                child: Text(
                  o,
                  style: cl.text.caption.copyWith(
                    fontWeight: i == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == selected ? cl.colors.ink : cl.colors.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
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
