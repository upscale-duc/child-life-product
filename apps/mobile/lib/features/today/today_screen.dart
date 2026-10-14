import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../auto_save/auto_save_today.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/care_screens.dart';
import '../care/care_sheets.dart';
import '../care/timer_models.dart';
import '../care/timer_screens.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../reminders/reminder_screens.dart' show ReminderPeek;
import '../rhythm/rhythm_home.dart' show ForYouSection;
import '../app_update/app_update_screens.dart' show WhatsNewBanner;
import '../home/today_tour.dart';
import '../spending/spending_models.dart' show SpendingAccess;
import 'today_cards.dart';
import 'today_layout.dart';

/// 19 Hôm nay (46:2266) and its first-run state 18 (29:904): one tile per tracker — tap logs
/// that type, the lines show the last entry (how long ago · detail · who) — then "Đã ghi hôm
/// nay" (DayRhythm 48:409). Offline / pending entries show 9a's banner and "Chờ đồng bộ".
/// Relatives with "Chăm sóc hằng ngày" see it read-only (D-018). Sleep arrives in S5,
/// reminders (ReminderPeek, R-094) in S7, the first-run tour (18a–18c) with S5.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final membership = ref.watch(selectedMembershipProvider);
    if (membership == null) return ColoredBox(color: cl.colors.cloud);
    final babyId = membership.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final trackers = baby?.trackers ?? const <TrackerKind>[];
    final readOnly = membership.role == MemberRole.relative;
    // v1.0 improvement 370:1525: the sections and tiles this device shows, in its order.
    final layout = ref.watch(todayLayoutProvider(babyId));
    final recent = ref.watch(recentRecordsProvider(babyId)).value ?? const [];
    final growth = ref.watch(growthRecordsProvider(babyId)).value ?? const [];
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final day = babyDayBounds(zone, now);
    final pendingCount = recent.where((r) => r.pending).length;
    final online = ref.watch(onlineProvider).value ?? true;

    CareTimer? running(CareType type) => switch (type) {
      CareType.sleep =>
        ref.watch(careTimerProvider((babyId, TimerType.sleep))).value,
      CareType.breast =>
        ref.watch(careTimerProvider((babyId, TimerType.breast))).value,
      CareType.pump =>
        ref.watch(careTimerProvider((babyId, TimerType.pump))).value,
      _ => null,
    };
    final conflicts =
        ref.watch(openConflictsProvider(babyId)).value ?? const [];
    final myConflict = conflicts
        .where((c) => c.laterAuthor == membership.uid)
        .firstOrNull;

    void tap(CareType type) {
      final timer = running(type);
      if (timer != null) {
        // A running timer opens itself, for everyone who sees care (R-070).
        context.push('${Routes.timer}/${timer.type.name}');
      } else if (readOnly) {
        showClToast(context, message: l10n.todayViewOnly);
      } else if (type == CareType.sleep) {
        // D-025: the Giấc ngủ tile asks "đang ngủ hay đã ngủ xong" (25a).
        showSleepChooser(context, ref);
      } else {
        openCareLog(context, type);
      }
    }

    CareRecord? last(CareType type) => type == CareType.growth
        ? growth.firstOrNull
        : recent.where((r) => r.type == type).firstOrNull;

    // The baby header stays pinned while the day scrolls under it.
    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, 140),
        children: [
          if (myConflict != null) ...[
            const SizedBox(height: ClSpace.s3),
            _SyncBanner(
              label: l10n.overlapBanner,
              onTap: () => context.push('${Routes.overlap}/${myConflict.id}'),
            ),
          ],
          if (pendingCount > 0) ...[
            const SizedBox(height: ClSpace.s3),
            _SyncBanner(
              label: online
                  ? l10n.syncingBanner(pendingCount)
                  : l10n.offlineBanner(pendingCount),
              onTap: () => showPendingSheet(context),
            ),
          ],
          const SizedBox(height: ClSpace.s4),
          Text(
            toBeginningOfSentenceCase(
              DateFormat('EEEE, d MMMM', locale).format(now),
            ),
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.todayTitle,
                    style: cl.text.largeTitle.copyWith(color: cl.colors.ink),
                  ),
                ),
              ),
              if (!readOnly) const _CustomizePill(),
            ],
          ),
          // D-061 UP5: "Đã cập nhật 1.2.0" after an update, until seen or closed.
          const WhatsNewBanner(),
          // AR02: new library photos that may show the baby (Tự lưu, D-066).
          const AutoSaveTodayBanner(),
          for (final section in layout.order)
            if (layout.shows(section))
              ...switch (section) {
                // Nhịp lớn lên (H01 / H02): draws nothing unless the `rhythm` flag is on.
                TodaySection.forYou => [const ForYouSection()],
                TodaySection.tiles => [
                  const SizedBox(height: ClSpace.s4),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    // Without it the grid pads itself by the home indicator, so the gap below
                    // the tiles was ~34 pt taller than between the other sections (owner,
                    // 2026-10-14).
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: ClSpace.s3,
                    crossAxisSpacing: ClSpace.s3,
                    childAspectRatio: 166 / 156,
                    children: [
                      for (final kind in layout.tiles(trackers))
                        if (!layout.hiddenTiles.contains(kind))
                          if (careTypeOf(kind) case final type?)
                            KeyedSubtree(
                              key: switch (type) {
                                CareType.bottle => TourTargets.bottle,
                                CareType.growth => TourTargets.growth,
                                _ => null,
                              },
                              child: CareTile(
                                type: type,
                                last: last(type),
                                previousGrowth:
                                    type == CareType.growth && growth.length > 1
                                    ? growth[1]
                                    : null,
                                myUid: membership.uid,
                                now: now,
                                readOnly: readOnly,
                                timer: running(type),
                                onTap: () => tap(type),
                                onLongPress: last(type) == null
                                    ? null
                                    : () => context.push(
                                        '${Routes.record}/${last(type)!.id}',
                                      ),
                              ),
                            ),
                    ],
                  ),
                ],
                // ReminderPeek (128:665, R-094); not for relatives (D-018).
                TodaySection.reminders => [
                  if (!readOnly) ...[
                    // A section like "Hôm nay" below: its own header, the same gap.
                    const SizedBox(height: ClSpace.s6),
                    const ReminderPeek(),
                  ],
                ],
                // Opt-in parts (owner, 2026-10-12); each checks the viewer's rights.
                TodaySection.quickActions => [
                  if (!readOnly) ...[
                    const SizedBox(height: ClSpace.s6),
                    TodayQuickActions(layout: layout),
                  ],
                ],
                TodaySection.vaccine => [
                  const SizedBox(height: ClSpace.s6),
                  const TodayVaccineCard(),
                ],
                TodaySection.spending => [
                  if (SpendingAccess.of(membership).viewAll) ...[
                    const SizedBox(height: ClSpace.s6),
                    const TodaySpendingCard(),
                  ],
                ],
                TodaySection.rhythm => [
                  const SizedBox(height: ClSpace.s6),
                  ClSectionHeader(
                    title: l10n.todayTitle,
                    linkLabel: l10n.todayHistory,
                    onLink: () => context.push(Routes.history),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  DayRhythm(
                    records: recent,
                    dayStart: day.start,
                    dayEnd: day.end,
                    now: now,
                  ),
                ],
              },
        ],
      ),
    );
  }
}

/// 370:1265 "Tuỳ chỉnh": surface pill, separator border, sliders 14 + SemiBold 13.
class _CustomizePill extends StatelessWidget {
  const _CustomizePill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: () => showTodayCustomizeSheet(context),
      semanticLabel: l10n.customizeTitle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.pill),
              border: Border.all(color: cl.colors.separator),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClIcon(ClIcons.sliders, size: 14, color: cl.colors.ink),
                const SizedBox(width: 6),
                Text(
                  l10n.todayCustomize,
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cl.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 9a banner: sunshine-soft, cloud-off, chevron → 9b.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.sunshineSoft,
          borderRadius: BorderRadius.circular(ClRadius.control),
        ),
        child: Row(
          children: [
            ClIcon(ClIcons.cloudOff, size: 18, color: cl.colors.ink),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                label,
                style: cl.text.label.copyWith(color: cl.colors.ink),
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.ink),
          ],
        ),
      ),
    );
  }
}

/// CareTile (54:530): care-tinted card with type, value, "⏱ when" and "👤 who"; "Chưa có /
/// Chạm để ghi" when empty. After a save it glows and shows ✓ (Motion 270:22, 24), except in
/// Night care (no glow).
class CareTile extends ConsumerStatefulWidget {
  const CareTile({
    required this.type,
    required this.last,
    this.timer,
    required this.myUid,
    required this.now,
    required this.onTap,
    this.previousGrowth,
    this.readOnly = false,
    this.onLongPress,
    super.key,
  });

  final CareType type;
  final CareRecord? last;

  /// A running timer of this type: "Tone=Active" with live elapsed time (54:530).
  final CareTimer? timer;
  final CareRecord? previousGrowth;
  final String myUid;
  final DateTime now;
  final bool readOnly;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  ConsumerState<CareTile> createState() => _CareTileState();
}

class _CareTileState extends ConsumerState<CareTile>
    with SingleTickerProviderStateMixin {
  static final _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.04,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
  ]);

  late final _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lastSavedProvider, (_, saved) {
      if (saved?.$1 == widget.type && !context.reduceMotion) {
        _glow.forward(from: 0);
      }
    });
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final care = careColor(context, widget.type);
    final label = careTypeLabel(l10n, widget.type);
    final r = widget.last;
    final timer = widget.timer;
    final hm = DateFormat.Hm(locale);
    var lines = r == null ? null : _lines(l10n, locale, r);
    var value = r == null ? l10n.todayTileEmpty : recordValue(l10n, locale, r);
    if (timer != null) {
      // Tone=Active: live elapsed time and who started it.
      lines = [
        l10n.runningSince(
          hm.format(timer.startedAt),
          authorLabel(
            l10n,
            timer.author,
            isMe: timer.startedBy == widget.myUid,
            relationLabel: (rel, c) => relationLabel(l10n, rel, c),
          ),
        ),
      ];
      value = clockLabel(
        timer.totalAt(widget.now),
        hours: timer.type == TimerType.sleep,
      );
    } else if (r != null && r.type == CareType.sleep && r.endedAt != null) {
      // "Đã thức 2 giờ · Dậy lúc 13:05 · Ba ghi" (46:2266).
      final awake = widget.now.difference(r.endedAt!).inMinutes;
      value = l10n.awakeFor(durationLabel(l10n, awake < 0 ? 0 : awake));
      lines = [
        l10n.wokeAt(hm.format(r.endedAt!)),
        r.pending ? l10n.carePending : loggedBy(l10n, r, widget.myUid),
      ];
    }
    final semantics = r == null && timer == null
        ? (widget.readOnly
              ? '$label, ${l10n.todayTileEmpty}'
              : '$label, ${l10n.todayTileEmpty}. ${l10n.todayTileTapToLog}')
        : '$label, $value, ${lines!.join(', ')}';

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: care.soft,
        borderRadius: BorderRadius.circular(ClRadius.tile),
        border: timer != null
            ? Border.all(color: care.accent, width: 2)
            : Border.all(color: cl.colors.cardEdge),
        boxShadow: cl.shadows.tile,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -12,
            child: ClArt(careArt(widget.type), width: 76, height: 76),
          ),
          Padding(
            padding: const EdgeInsets.all(ClSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: cl.text.label.copyWith(color: care.ink)),
                const SizedBox(height: ClSpace.s1),
                if (timer != null)
                  _LiveClock(
                    timer: timer,
                    style: cl.text.title2.copyWith(color: cl.colors.ink),
                  )
                else
                  // "Đã thức 2 giờ 36 phút" wraps rather than ending in "…" (owner, 2026-10-11).
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.title2.copyWith(color: cl.colors.ink),
                  ),
                const SizedBox(height: ClSpace.s1),
                if (lines == null) ...[
                  const Spacer(),
                  if (!widget.readOnly)
                    Text(
                      l10n.todayTileTapToLog,
                      style: cl.text.label.copyWith(color: care.ink),
                    ),
                ] else
                  // Large text never overflows the tile: extra lines are clipped.
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, line) in lines.indexed)
                            Padding(
                              padding: const EdgeInsets.only(right: ClSpace.s2),
                              child: Text(
                                line,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: cl.text.label.copyWith(
                                  color:
                                      i == lines.length - 1 &&
                                          (r?.pending ?? false)
                                      ? cl.colors.pending
                                      : cl.colors.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return ClPressable(
      onPressed: widget.onTap,
      onLongPress: widget.onLongPress,
      semanticLabel: semantics,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final t = _glow.value;
          final on = t > 0 && t < 1 && !cl.isNightCare;
          // Light bounce (24 annotation) and a 3 px mint border that fades out.
          final scale = _bounce.transform(t);
          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                child!,
                if (on)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ClRadius.tile),
                          border: Border.all(
                            color: cl.colors.mintDeep.withValues(alpha: 1 - t),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_glow.isAnimating)
                  Positioned(
                    top: ClSpace.s3,
                    right: ClSpace.s3,
                    child: Opacity(
                      opacity: (1 - t).clamp(0, 1),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cl.colors.mintDeep,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: ClIcon(
                          ClIcons.check,
                          size: 14,
                          color: cl.colors.onMintDeep,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: SizedBox.expand(child: card),
      ),
    );
  }

  /// "45 phút trước" / "Kết thúc 3 giờ 35 phút trước" / "54,5 cm" + "+0,4 kg · hôm nay",
  /// then "Mẹ ghi" or, while pending, "Chờ đồng bộ" (9a).
  List<String> _lines(AppLocalizations l10n, String locale, CareRecord r) {
    final who = r.pending ? l10n.carePending : loggedBy(l10n, r, widget.myUid);
    switch (r.type) {
      case CareType.growth:
        final prev = widget.previousGrowth;
        final measured = r.measuredOn ?? r.occurredAt;
        final today = DateUtils.dateOnly(widget.now);
        final whenLabel = DateUtils.isSameDay(measured, today)
            ? l10n.dayToday
            : DateUtils.isSameDay(
                measured,
                today.subtract(const Duration(days: 1)),
              )
            ? l10n.dayYesterday
            : shortDate(context, measured);
        return [
          if (r.lengthCm != null) l10n.lengthCm(decimal(locale, r.lengthCm!)),
          if (prev?.weightKg != null && r.weightKg != null)
            l10n.growthDeltaToday(
              '${r.weightKg! >= prev!.weightKg! ? '+' : '−'}${decimal(locale, (r.weightKg! - prev.weightKg!).abs())} kg',
              whenLabel,
            )
          else
            whenLabel,
          if (r.pending) who,
        ];
      case CareType.breast when r.endedAt != null:
        return [l10n.endedAgo(relativeAgo(l10n, r.endedAt!, widget.now)), who];
      default:
        return [relativeAgo(l10n, r.finishedAt, widget.now), who];
    }
  }
}

/// Elapsed time of a running timer, refreshed every second on this tile only.
class _LiveClock extends ConsumerStatefulWidget {
  const _LiveClock({required this.timer, required this.style});
  final CareTimer timer;
  final TextStyle style;

  @override
  ConsumerState<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends ConsumerState<_LiveClock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (ref.read(timerTicksProvider)) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClTabularText(
    clockLabel(
      widget.timer.totalAt(ref.read(timerClockProvider)()),
      hours: widget.timer.type == TimerType.sleep,
    ),
    style: widget.style,
  );
}

/// DayRhythm "Đã ghi hôm nay" (48:409): totals (pending included, 9a) and a 24 h strip in care
/// colours with a "now" line. Running sleep and pumping are not counted.
class DayRhythm extends StatelessWidget {
  const DayRhythm({
    required this.records,
    required this.dayStart,
    required this.dayEnd,
    required this.now,
    this.title,
    this.stripOnly = false,
    super.key,
  });

  final List<CareRecord> records;
  final DateTime dayStart;
  final DateTime dayEnd;
  final DateTime now;

  /// "Đã ghi ngày 5 thg 10" for a past day; "Đã ghi hôm nay" by default.
  final String? title;

  /// Only the 24 h strip and legend, inside another card (20a–20c).
  final bool stripOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final totals = DayTotals.of(records, dayStart, dayEnd);
    final card = BoxDecoration(
      color: cl.colors.surface,
      borderRadius: BorderRadius.circular(ClRadius.card),
      boxShadow: cl.shadows.card,
    );
    if (totals.isEmpty && !stripOnly) {
      return Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.todaySummaryEmpty, style: cl.text.bodyStrong),
            const SizedBox(height: ClSpace.s1),
            Text(
              l10n.todaySummaryEmptyBody,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      );
    }
    final care = cl.care;
    Widget stat(ClCareColor color, String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.only(left: ClSpace.s2),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color.accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: cl.text.caption.copyWith(color: color.ink)),
            Text(value, style: cl.text.headline),
          ],
        ),
      ),
    );
    final present = {
      for (final r in records)
        if (!r.deleted) r.type,
    };
    final legend = [
      (CareType.sleep, care.sleep.accent, l10n.legendSleep),
      (CareType.bottle, care.bottle.accent, l10n.trackerBottle),
      (CareType.breast, care.breast.accent, l10n.trackerBreast),
      (CareType.diaper, care.diaper.accent, l10n.legendDiaper),
    ].where((e) => !stripOnly || present.contains(e.$1));
    final strip = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 28,
            child: CustomPaint(
              size: Size.infinite,
              painter: _StripPainter(
                records: records,
                dayStart: dayStart,
                dayEnd: dayEnd,
                now: now,
                track: cl.colors.surface2,
                nowColor: cl.colors.ink,
                colors: {
                  CareType.sleep: care.sleep.accent,
                  CareType.bottle: care.bottle.accent,
                  CareType.breast: care.breast.accent,
                  CareType.diaper: care.diaper.accent,
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s1),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in const ['0h', '6h', '12h', '18h', '24h'])
                Text(
                  h,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s3,
          children: [
            for (final (_, color, label) in legend)
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
        ),
      ],
    );
    if (stripOnly) return strip;
    final sleepH = totals.sleepMinutes ~/ 60;
    final sleepM = totals.sleepMinutes % 60;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? l10n.dayRhythmTitle,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              stat(
                care.bottle,
                l10n.trackerBottle,
                l10n.rhythmFeeds(totals.bottleCount, totals.bottleMl),
              ),
              const SizedBox(width: ClSpace.s3),
              stat(
                care.breast,
                l10n.trackerBreast,
                l10n.rhythmBreast(totals.breastCount, totals.breastMinutes),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              stat(
                care.sleep,
                l10n.rhythmSleepLabel,
                totals.sleepMinutes == 0
                    ? '—'
                    : l10n.rhythmSleepValue(sleepH, sleepM),
              ),
              const SizedBox(width: ClSpace.s3),
              stat(
                care.diaper,
                l10n.trackerDiaper,
                l10n.rhythmDiapers(totals.diaperCount),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
          strip,
        ],
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.records,
    required this.dayStart,
    required this.dayEnd,
    required this.now,
    required this.track,
    required this.nowColor,
    required this.colors,
  });

  final List<CareRecord> records;
  final DateTime dayStart;
  final DateTime dayEnd;
  final DateTime now;
  final Color track;
  final Color nowColor;
  final Map<CareType, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final span = dayEnd.difference(dayStart).inSeconds.toDouble();
    double x(DateTime t) =>
        (t.difference(dayStart).inSeconds / span).clamp(0.0, 1.0) * size.width;
    final radius = const Radius.circular(6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    for (final r in records) {
      final color = colors[r.type];
      if (color == null || r.deleted) continue;
      final end = r.endedAt;
      if (end != null && end.isBefore(dayStart)) continue;
      if (!r.occurredAt.isBefore(dayEnd)) continue;
      final paint = Paint()..color = color;
      if (end != null &&
          (r.type == CareType.sleep || r.type == CareType.breast)) {
        final left = x(r.occurredAt);
        final right = x(end);
        canvas.drawRRect(
          RRect.fromLTRBR(
            left,
            2,
            (right - left) < 3 ? left + 3 : right,
            size.height - 2,
            radius,
          ),
          paint,
        );
      } else if (!r.occurredAt.isBefore(dayStart)) {
        final cx = x(r.occurredAt);
        canvas.drawRRect(
          RRect.fromLTRBR(
            cx - 1.5,
            6,
            cx + 1.5,
            size.height - 6,
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
    if (now.isAfter(dayStart) && now.isBefore(dayEnd)) {
      final nx = x(now);
      canvas.drawRect(
        Rect.fromLTWH(nx - 1, 0, 2, size.height),
        Paint()..color = nowColor,
      );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.records != records || old.now != now || old.track != track;
}
