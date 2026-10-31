import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../ai/handover_screen.dart' show HandoverEntry;
import '../care/bottle_suggestions.dart';
import '../care/bottle_quick_memory.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tabular_text.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
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
import '../care_plan/care_plan_shift.dart';
import '../care_plan/care_plan_today.dart' show CarePlanTodaySection;
import '../care/care_screens.dart';
import '../care/care_sheets.dart';
import '../care/timer_models.dart';
import '../care/timer_screens.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../notifications/notification_bell.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../insights/insight_widgets.dart' show InsightTodayCard;
import '../rhythm/coming_up_card.dart' show ComingUpCard;
import '../rhythm/rhythm_labels.dart' show capitalized, memberLabel;
import '../reminders/reminder_screens.dart' show ReminderPeek;
import '../app_update/app_update_screens.dart' show WhatsNewBanner;
import '../home/today_tour.dart';
import '../solids/solids_today.dart' show SdTodayCard, sdOnTodayProvider;
import '../spending/spending_models.dart' show SpendingAccess;
import '../adaptive/adaptive_engine.dart' show RankedWidget, WidgetId;
import '../adaptive/experience_repository.dart';
import '../adaptive/adaptive_signals.dart';
import '../adaptive/today_adaptive.dart';
import 'today_cards.dart';
import 'today_for_baby.dart';
import 'today_layout.dart';
import 'today_personalize.dart';
import 'living_header.dart';
import 'header_settings.dart';
import '../me/me_widgets.dart' show MeRow;

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
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final trackers = baby?.trackers ?? const <TrackerKind>[];
    final readOnly = membership.role == MemberRole.relative;
    // v1.0 improvement 370:1525: the sections and tiles this device shows, in its order.
    final layout = ref.watch(todayLayoutProvider(babyId));
    final firstRun =
        ref.watch(adaptiveOnProvider) &&
        ref.watch(todayFirstRunProvider(babyId));
    final recentAsync = ref.watch(recentRecordsProvider(babyId));
    final recent = recentAsync.value ?? const [];
    // SY-1 (D-127): until the records arrive the day is unknown, never "Chưa có"; a failed load
    // says so instead of reading as an empty day (a parent would log the same feed twice).
    final recentFailed = !recentAsync.hasValue && recentAsync.hasError;
    final growthAsync = ref.watch(growthRecordsProvider(babyId));
    final growth = growthAsync.value ?? const [];
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final day = babyDayBounds(zone, now);
    // SY-3: deletes, undos, old edits and timers count too (the outbox), not only the records
    // Today's query still marks as pending (those survive a restart).
    final pendingCount = math.max(
      recent.where((r) => r.pending).length,
      ref.watch(careOutboxProvider),
    );
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

    var tilesLead = false;
    // D-135 (16): a helper's shift day ends with "Bàn giao cho bố mẹ" instead of the row.
    var shiftHome = false;
    // The first adaptive widget sits closer to the greeting (owner, 2026-10-25).
    List<Widget> sectionParts(TodaySection section) => [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (section) {
          // "Dành cho bé hôm nay" (D-076 #4, 559:57583): nothing unless the `rhythm` flag is on.
          TodaySection.forYou => [const TodayForBabySection()],
          TodaySection.tiles => [
            // AX10 / AX11 / AX40: the quick log has its own header in the adaptive Hôm nay.
            ...[
              SizedBox(height: tilesLead ? 0 : ClSpace.s4),
              // D-108: "Nhịp hôm nay · Xem lịch sử" for every band; no history yet on the first run.
              ClSectionHeader(
                title: firstRun ? l10n.axFirstLogTitle : l10n.axRhythmToday,
                linkLabel: firstRun ? null : l10n.axSeeHistory,
                onLink: () => context.push(Routes.history),
              ),
              const SizedBox(height: ClSpace.s2),
            ],
            // D-108 / SY-1: until the records load, tile-shaped skeletons, never "Chưa có".
            if (recentFailed) ...[
              CareLoadFailed(
                body: l10n.todayLoadFailedBody,
                onRetry: () => ref.invalidate(recentRecordsProvider(babyId)),
              ),
              const SizedBox(height: ClSpace.s2),
            ],
            if (!recentAsync.hasValue && !recentFailed)
              _TilesSkeleton(
                count: layout
                    .tiles(trackers)
                    .where((kind) => !layout.hiddenTiles.contains(kind))
                    .length,
              )
            else
              // D-108: rows sized by their content (at least the old 166:156 tile), so the tiles grow
              // with large text instead of overflowing a fixed-ratio grid.
              _TileRows(
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
                            quickActions: true,
                            last: last(type),
                            unknown: type == CareType.growth
                                ? !growthAsync.hasValue
                                : recentFailed,
                            previousGrowth:
                                type == CareType.growth && growth.length > 1
                                ? growth[1]
                                : null,
                            myUid: membership.uid,
                            now: now,
                            readOnly: readOnly,
                            firstLogPill: ref.watch(adaptiveOnProvider),
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
            // Sprint wow W1 (owner, 2026-10-30): what usually comes next, from this baby's
            // own log, right under the tiles that log it. Draws nothing without a range.
            if (recentAsync.hasValue) const ComingUpCard(),
            // A care tool, with the tiles rather than among the suggestions (owner,
            // 2026-10-15).
            if (!shiftHome) const TodayHandoverRow(),
          ],
          // ReminderPeek (128:665, R-094); not for relatives (D-018).
          TodaySection.reminders => [
            if (!readOnly) ...[
              // A section like "Hôm nay" below: its own header, the same gap.
              const SizedBox(height: ClSpace.s4),
              // AX10–AX13: one card with its header inside, in the adaptive Hôm nay.
              ReminderPeek(ax: ref.watch(adaptiveOnProvider)),
            ],
          ],
          // Opt-in parts (owner, 2026-10-12); each checks the viewer's rights.
          TodaySection.quickActions => [
            if (!readOnly) ...[
              const SizedBox(height: ClSpace.s4),
              TodayQuickActions(layout: layout),
            ],
          ],
          TodaySection.vaccine => [
            const SizedBox(height: ClSpace.s4),
            const TodayVaccineCard(),
          ],
          TodaySection.spending => [
            if (SpendingAccess.of(membership).viewAll)
              if (ref.watch(adaptiveOnProvider))
                // AX12 / AX13 / AX42: total, stacked bar by category, "Thêm".
                const AxSpending()
              else ...[
                const SizedBox(height: ClSpace.s4),
                const TodaySpendingCard(),
              ],
          ],
          // 5h "Ăn dặm hôm nay" (D-085): only while tracking is on with "Hiện trên Hôm
          // nay" on (the card draws nothing otherwise).
          TodaySection.solids => [
            if (ref.watch(sdOnTodayProvider)) ...[
              const SizedBox(height: ClSpace.s4),
              const SdTodayCard(),
            ],
          ],
          // SY-1: no "Chưa có ghi chép hôm nay" while loading; nothing on a failed load (the
          // notice above the tiles says so).
          TodaySection.rhythm => [
            if (!recentFailed) ...[
              const SizedBox(height: ClSpace.s4),
              ClSectionHeader(
                title: l10n.todayTitle,
                linkLabel: l10n.todayHistory,
                onLink: () => context.push(Routes.history),
              ),
              const SizedBox(height: ClSpace.s2),
              if (recentAsync.hasValue)
                DayRhythm(
                  records: recent,
                  dayStart: day.start,
                  dayEnd: day.end,
                  now: now,
                )
              else
                Semantics(
                  label: l10n.axTilesLoading,
                  child: const ClSkeleton(height: 132, radius: ClRadius.card),
                ),
            ],
          ],
        },
      ),
    ];

    // Sync state stays on top in every layout (SY-3).
    final statusBanners = <Widget>[
      if (myConflict != null) ...[
        const SizedBox(height: ClSpace.s3),
        _SyncBanner(
          label: l10n.overlapBanner,
          onTap: () => context.push('${Routes.overlap}/${myConflict.id}'),
        ),
      ],
      // Owner, 2026-10-22: a save that syncs in a moment no longer flashes this banner in
      // and out (the whole screen jumped); online it shows only if sending takes a while.
      _AfterDelay(
        show: pendingCount > 0,
        immediately: !online,
        child: Padding(
          padding: const EdgeInsets.only(top: ClSpace.s3),
          child: _SyncBanner(
            label: online
                ? l10n.syncingBanner(pendingCount)
                : l10n.offlineBanner(pendingCount),
            onTap: () => showPendingSheet(context),
          ),
        ),
      ),
    ];
    final bottomPadding = EdgeInsets.only(
      bottom: switch (HomeFloatingClearance.of(context)) {
        final c? => c + ClSpace.s4,
        null => 140,
      },
    );

    // D-135 (16, ANALYSIS §4): a helper with tasks today sees their shift, not the parents' Hôm
    // nay: a short greeting, the shift card, the quick log, their tasks, notes for the parents
    // and "Bàn giao cho bố mẹ". Everything else stays reachable from Khám phá.
    if (carePlanOnShiftDay(ref, membership)) {
      shiftHome = true;
      final caps = ref.watch(selectedCapabilitiesProvider);
      final language = Localizations.localeOf(context).languageCode;
      final handover =
          caps != null &&
          caps.features.rhythm &&
          HandoverEntry.visibleFor(ref, membership, caps, language);
      return ColoredBox(
        color: cl.colors.cloud,
        child: ListView(
          padding: bottomPadding,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                MediaQuery.paddingOf(context).top + ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: CarePlanShiftHello(
                me: membership,
                title: l10n.cpShiftHello(
                  capitalized(memberLabel(l10n, membership, myUid: '')),
                ),
                actions: const [
                  NotificationBell(),
                  SizedBox(width: ClSpace.s2),
                  NightCareToggle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...statusBanners,
                  const SizedBox(height: ClSpace.s4),
                  CarePlanShiftCard(me: membership),
                  const SizedBox(height: ClSpace.s4),
                  const CarePlanQuickLog(),
                  const SizedBox(height: ClSpace.s6),
                  CarePlanMyTasks(me: membership),
                  const SizedBox(height: ClSpace.s4),
                  CarePlanShiftNotesCard(me: membership),
                  if (handover) ...[
                    const SizedBox(height: ClSpace.s6),
                    ClButton(
                      key: const Key('cpHandoverToParents'),
                      label: l10n.cpHandoverToParents,
                      style: ClButtonStyle.secondary,
                      expand: true,
                      onPressed: () => context.push(Routes.rhythmHandover),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Adaptive Experience (Figma 930:11858, P-175): greeting by age band, ranked widgets,
    // "Tuỳ chỉnh Hôm nay" (AX14). Off: the layout this device kept (370:1525).
    final adaptive = ref.watch(adaptiveOnProvider);
    final ranked = adaptive
        ? ref.watch(adaptiveTodayProvider(babyId))
        : const <RankedWidget>[];
    tilesLead = adaptive
        ? ranked
                  .where((w) => w.visible && w.id != WidgetId.careDuty)
                  .firstOrNull
                  ?.id ==
              WidgetId.tiles
        : layout.order.where(layout.shows).firstOrNull == TodaySection.tiles;

    // D-135: the old "Ai đang trông bé" switch (`duty` / careDuty, visibility only) now shows
    // "n việc cần làm"; the chip left the header (Q1).
    final tasksEnabled = adaptive
        ? ranked.any((w) => w.id == WidgetId.careDuty && w.visible)
        : ref.watch(headerSettingsProvider).showDuty;
    return ColoredBox(
      color: cl.colors.cloud,
      child: ListView(
        padding: bottomPadding,
        children: [
          const TodayLivingHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...statusBanners,
                // D-061 UP5: "Đã cập nhật 1.2.0" after an update, until seen or closed.
                const WhatsNewBanner(),
                // AR02: new library photos that may show the baby (Tự lưu, D-066), first under
                // the header (owner, 2026-10-30: "đưa gợi ý xem và chọn ảnh lên đầu tiên").
                const AutoSaveTodayBanner(top: ClSpace.s4),
                // D-135 (14): the viewer's shared Cùng Chăm Con tasks, first under the header;
                // personal reminders stay in Nhắc việc below (Q4).
                CarePlanTodaySection(enabled: tasksEnabled),

                // D-076 #13: no assistant card here; the Lumi button (home_shell.dart) opens the chat.
                // D-076 #1: "Hôm nay theo cách của nhà bạn" (559:57870) for who has not personalised,
                // and EN01 right after this phone created the baby.
                const PersonalizeInviteCard(),
                const PersonalizeAfterSetupGate(),
                if (adaptive) ...[
                  // Adaptive Experience (P-175): the ranked widgets of this child's band and goals.
                  // AX33: once at 12, 36 and 72 months; it only suggests.
                  const AxStageCard(),
                  for (final w in ranked)
                    if (w.visible && w.id != WidgetId.careDuty)
                      AdaptiveTapTracker(
                        id: w.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: switch (w.id) {
                            WidgetId.recentMemories => [
                              const AxRecentMemories(),
                            ],
                            WidgetId.momentToday => [const AxMomentToday()],
                            WidgetId.createFromMemories => [
                              const AxCreateFromMemories(),
                            ],
                            WidgetId.growth => [const AxGrowth()],
                            WidgetId.familyView => [const AxFamilyView()],
                            WidgetId.insight => [const InsightTodayCard()],
                            // Drawn first, as "n việc cần làm" (D-135).
                            WidgetId.careDuty => const <Widget>[],
                            _ => sectionParts(
                              TodaySection.values.byName(w.id.wire),
                            ),
                          },
                        ),
                      ),
                  // On the first run too: without it some children had no way to Tuỳ chỉnh (owner,
                  // 2026-10-24), as AX40's empty Today has no other entry.
                  if (!readOnly) const AxCustomizeLink(),
                ] else
                  for (final section in layout.order)
                    if (layout.shows(section)) ...sectionParts(section),
                if (!adaptive && !readOnly)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CustomizePill(),
                  ),
                const SizedBox(height: ClSpace.s4),
                ClCardGroup(
                  children: [
                    MeRow(
                      title: l10n.hhSettings,
                      subtitle: l10n.hhSettingsSubtitle,
                      icon: ClIcons.edit,
                      onTap: () => context.push(Routes.todayAppearance),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
/// Shows [child] once [show] has stayed true for [delay] (or at once when [immediately]);
/// hides it as soon as [show] turns false.
class _AfterDelay extends StatefulWidget {
  const _AfterDelay({
    required this.show,
    required this.immediately,
    required this.child,
  });
  final bool show;
  final bool immediately;
  final Widget child;
  static const delay = Duration(seconds: 5);

  @override
  State<_AfterDelay> createState() => _AfterDelayState();
}

class _AfterDelayState extends State<_AfterDelay> {
  Timer? _timer;
  bool _due = false;

  void _sync() {
    if (!widget.show) {
      _timer?.cancel();
      _timer = null;
      _due = false;
    } else if (!_due && _timer == null) {
      _timer = Timer(_AfterDelay.delay, () {
        if (mounted) setState(() => _due = true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_AfterDelay old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.show && (widget.immediately || _due)
      ? widget.child
      : const SizedBox.shrink();
}

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
    this.firstLogPill = false,
    this.unknown = false,
    this.quickActions = false,
    super.key,
  });

  final CareType type;
  final bool quickActions;
  final CareRecord? last;

  /// SY-1: the diary did not load, so the last entry is unknown: "—", never "Chưa có".
  final bool unknown;

  /// AX40: an empty tile shows the "Ghi lần đầu" pill instead of "Chạm để ghi".
  final bool firstLogPill;

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
  CareRecord? _quickRecord;
  DateTime? _lastQuickTap;

  @override
  void didUpdateWidget(CareTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type ||
        widget.myUid != oldWidget.myUid ||
        (widget.last != oldWidget.last &&
            widget.last != null &&
            (_quickRecord == null ||
                !widget.last!.occurredAt.isBefore(_quickRecord!.occurredAt)))) {
      _quickRecord = null;
      if (widget.type != oldWidget.type || widget.myUid != oldWidget.myUid) {
        _lastQuickTap = null;
      }
    }
  }

  void _logDirect({int? amount, DiaperKind? diaper}) {
    final me = ref.read(selectedMembershipProvider);
    if (widget.readOnly ||
        me == null ||
        me.uid != widget.myUid ||
        me.role == MemberRole.relative ||
        !me.isActive) {
      return;
    }
    if (widget.timer != null) return widget.onTap();
    final tappedAt = DateTime.now();
    // A second physical tap in the same second is a duplicate, not a second feed.
    // No network spinner: Firestore queues locally even without connectivity.
    if (_lastQuickTap != null &&
        tappedAt.difference(_lastQuickTap!) < const Duration(seconds: 1)) {
      return;
    }
    _lastQuickTap = tappedAt;
    final memory = ref.read(careMemoryProvider);
    final lastMilk =
        (ref.read(recentRecordsProvider(me.babyId)).value ??
                const <CareRecord>[])
            .where((r) => r.type == CareType.bottle && r.createdBy == me.uid)
            .firstOrNull
            ?.milk;
    final record = CareRecord.create(
      id: newRecordId(),
      babyId: me.babyId,
      type: widget.type,
      occurredAt: ref.read(timerClockProvider)(),
      me: me,
      amountMl: amount,
      diaper: diaper,
      milk: widget.type == CareType.bottle
          ? memory.get(me.babyId, 'milk', MilkType.values) ??
                lastMilk ??
                MilkType.breastMilk
          : null,
    );
    if (diaper != null) memory.set(me.babyId, 'diaper', diaper);
    setState(() => _quickRecord = record);
    void clear() {
      if (mounted && _quickRecord?.id == record.id) {
        setState(() {
          _quickRecord = null;
          _lastQuickTap = null;
        });
      }
    }

    commitRecord(
      context,
      ref,
      record,
      isEdit: false,
      closeSheet: false,
      onFailure: clear,
      onUndo: clear,
    );
  }

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
    ref.listen(selectedMembershipProvider, (previous, next) {
      if (previous?.uid != next?.uid || previous?.babyId != next?.babyId) {
        setState(() {
          _quickRecord = null;
          _lastQuickTap = null;
        });
      }
    });
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
    final r = _quickRecord ?? widget.last;
    final timer = widget.timer;
    final hm = DateFormat.Hm(locale);
    var lines = r == null ? null : _lines(l10n, locale, r);
    final unknown = widget.unknown && r == null;
    var value = unknown
        ? '—'
        : r == null
        ? l10n.todayTileEmpty
        : recordValue(l10n, locale, r);
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
        if (r.pending) l10n.carePending,
      ];
    }
    final semantics = unknown && timer == null
        ? (widget.readOnly ? label : '$label. ${l10n.todayTileTapToLog}')
        : r == null && timer == null
        ? (widget.readOnly
              ? '$label, ${l10n.todayTileEmpty}'
              : '$label, ${l10n.todayTileEmpty}. ${l10n.todayTileTapToLog}')
        : '$label, $value, ${lines!.join(', ')}';

    final card = widget.quickActions
        ? _quickCard(context, care, label, value, lines)
        : Container(
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
                      Text(
                        label,
                        style: cl.text.label.copyWith(color: care.ink),
                      ),
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
                        if (!widget.readOnly && widget.firstLogPill && !unknown)
                          Container(
                            key: const Key('tileFirstLog'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: cl.colors.surface,
                              borderRadius: BorderRadius.circular(
                                ClRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClIcon(ClIcons.plus, size: 12, color: care.ink),
                                const SizedBox(width: 4),
                                // Wraps at 200 % text instead of running past the tile (D-108).
                                Flexible(
                                  child: Text(
                                    l10n.axLogFirst,
                                    style: cl.text.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: care.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!widget.readOnly)
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
                                    padding: const EdgeInsets.only(
                                      right: ClSpace.s2,
                                    ),
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

  Widget _quickCard(
    BuildContext context,
    ClCareColor care,
    String label,
    String value,
    List<String>? lines,
  ) {
    final cl = context.cl;
    final l = AppLocalizations.of(context);
    final timer = widget.timer;
    final me = ref.watch(selectedMembershipProvider);
    final canLog =
        !widget.readOnly && me != null && me.role != MemberRole.relative;
    final dob = me != null && me.canViewBabyInfo
        ? ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
        : null;
    final zone = me == null
        ? 'Asia/Ho_Chi_Minh'
        : ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
              'Asia/Ho_Chi_Minh';
    final ageDays = dob == null
        ? null
        : babyToday(
            zone,
            widget.now,
          ).difference(DateUtils.dateOnly(dob)).inDays;
    final amounts = widget.type != CareType.bottle || !canLog
        ? const <int>[]
        : homeBottlePicks(
            ageDays: ageDays,
            remembered: ref.watch(bottleQuickMemoryProvider),
            recent:
                (ref.watch(recentRecordsProvider(me.babyId)).value ??
                        const <CareRecord>[])
                    .where(
                      (r) =>
                          r.type == CareType.bottle &&
                          r.createdBy == me.uid &&
                          r.amountMl != null,
                    )
                    .map((r) => r.amountMl!),
            table: ref.watch(bottleTableProvider),
          );
    final actions = <(String, VoidCallback)>[
      if (timer != null)
        (l.todayViewSession, widget.onTap)
      else if (canLog)
        ...switch (widget.type) {
          CareType.bottle => [
            for (final amount in amounts)
              (l.amountMl(amount), () => _logDirect(amount: amount)),
            (l.todayOtherAmount, widget.onTap),
          ],
          CareType.breast => [
            (
              l.sideLeftFull,
              () =>
                  openOrStartTimer(context, TimerType.breast, side: Side.left),
            ),
            (
              l.sideRightFull,
              () =>
                  openOrStartTimer(context, TimerType.breast, side: Side.right),
            ),
          ],
          CareType.diaper => [
            (l.diaperWet, () => _logDirect(diaper: DiaperKind.wet)),
            (l.diaperDirty, () => _logDirect(diaper: DiaperKind.dirty)),
            (l.todayDiaperBoth, () => _logDirect(diaper: DiaperKind.both)),
          ],
          CareType.sleep => [
            (
              l.todayStartSleep,
              () => openOrStartTimer(context, TimerType.sleep),
            ),
          ],
          CareType.pump => [(l.pumpTitle, widget.onTap)],
          CareType.growth => [(l.growthAdd, widget.onTap)],
        },
    ];
    Widget action((String, VoidCallback) a) => ClPressable(
      key: Key('care-${widget.type.name}-${a.$1}'),
      onPressed: a.$2,
      semanticLabel: '$label. ${a.$1}',
      child: Container(
        constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: ClSpace.s2,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Text(
          a.$1,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(color: care.ink),
        ),
      ),
    );
    final largeValue =
        widget.type == CareType.pump || widget.type == CareType.growth;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: care.soft,
        borderRadius: BorderRadius.circular(ClRadius.tile),
        border: Border.all(
          color: timer == null ? cl.colors.cardEdge : care.accent,
        ),
        // Keep the app's existing Light tile elevation; Night care remains flat.
        boxShadow: cl.shadows.tile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: ClSpace.s8 + ClSpace.s1,
                height: ClSpace.s8 + ClSpace.s1,
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClArt(
                  careArt(widget.type),
                  width: ClSpace.s6 + ClSpace.s1,
                  height: ClSpace.s6 + ClSpace.s1,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(child: Text(label, style: cl.text.bodyStrong)),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          if (timer != null)
            _LiveClock(timer: timer, style: cl.text.bodyStrong)
          else if (largeValue && widget.last != null)
            Wrap(
              children: [
                for (final word in value.split(" "))
                  ClTabularText("$word ", style: cl.text.title2),
              ],
            )
          else
            Text(
              value,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          if (lines != null)
            Wrap(
              spacing: ClSpace.s1,
              children: [
                for (final line in lines) ...[
                  Text(
                    line,
                    style: cl.text.caption.copyWith(
                      color:
                          (_quickRecord ?? widget.last)?.pending == true &&
                              line == l.carePending
                          ? cl.colors.pending
                          : cl.colors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          const Spacer(),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s2),
            Builder(
              builder: (context) {
                final available =
                    (MediaQuery.sizeOf(context).width -
                            ClSpace.s4 * 2 -
                            ClSpace.s3) /
                        2 -
                    ClSpace.s3 * 2;
                // Preserve full action labels and 44 pt targets at Dynamic Type.
                if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    available <
                        actions.length * ClSpace.tapMin +
                            (actions.length - 1) * ClSpace.s1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, a) in actions.indexed) ...[
                        if (i > 0) const SizedBox(height: ClSpace.s1),
                        action(a),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: ClSpace.s1),
                      Expanded(child: action(a)),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// "45 phút trước" / "Kết thúc 3 giờ 35 phút trước" / "54,5 cm" + "+0,4 kg · hôm nay", then,
  /// while pending, "Chờ đồng bộ" (9a). Who logged it is not on the tile (owner, 2026-10-30:
  /// "mấy cái card bỏ text là ai ghi đi"); it stays on the record and in Lịch sử.
  List<String> _lines(AppLocalizations l10n, String locale, CareRecord r) {
    final pending = [if (r.pending) l10n.carePending];
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
          if (r.headCm != null) l10n.headCm(decimal(locale, r.headCm!)),
          if (prev?.weightKg != null && r.weightKg != null)
            l10n.growthDeltaToday(
              '${r.weightKg! >= prev!.weightKg! ? '+' : '−'}${decimal(locale, (r.weightKg! - prev.weightKg!).abs())} kg',
              whenLabel,
            )
          else
            whenLabel,
          ...pending,
        ];
      case CareType.breast when r.endedAt != null:
        return [
          l10n.endedAgo(relativeAgo(l10n, r.endedAt!, widget.now)),
          ...pending,
        ];
      // The last bottle also says when, by the clock (owner, 2026-10-30).
      case CareType.bottle:
        return [
          relativeAgo(l10n, r.finishedAt, widget.now),
          l10n.careAtTime(DateFormat.Hm(locale).format(r.finishedAt)),
          ...pending,
        ];
      default:
        return [relativeAgo(l10n, r.finishedAt, widget.now), ...pending];
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

/// The care tiles two per row, each row as tall as its tallest tile and at least the old
/// 166:156 proportion (D-108), so 100 % text looks as before and 200 % text grows the row.
class _TileRows extends StatelessWidget {
  const _TileRows({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 1 : 2;
      const minHeight = ClSpace.buttonHeight * 2 + ClSpace.tapMin;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i += columns) ...[
            if (i > 0) const SizedBox(height: ClSpace.s3),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + columns; j++) ...[
                    if (j > i) const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: j < children.length
                          ? ConstrainedBox(
                              constraints: BoxConstraints(minHeight: minHeight),
                              child: children[j],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// Loading care tiles: four tile-shaped skeletons at the tile proportion (D-108).
class _TilesSkeleton extends StatelessWidget {
  const _TilesSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).axTilesLoading,
    child: LayoutBuilder(
      builder: (context, box) {
        const height = ClSpace.buttonHeight * 2 + ClSpace.tapMin;
        Widget row() => Row(
          children: [
            Expanded(
              child: ClSkeleton(height: height, radius: ClRadius.tile),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: ClSkeleton(height: height, radius: ClRadius.tile),
            ),
          ],
        );
        return Column(
          children: [
            for (var i = 0; i < count; i += 2) ...[
              if (i > 0) const SizedBox(height: ClSpace.s3),
              row(),
            ],
          ],
        );
      },
    ),
  );
}
