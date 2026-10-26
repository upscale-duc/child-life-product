// Design exploration only (Step 9A.1, 2026-10-25) — NOT production code.
//
// Two prototype renderings of Hôm nay (Adaptive) for the owner to compare:
//   TodayProtoA — "Refined current": the AX card grammar kept, its execution corrected.
//   TodayProtoB — "Adaptive Briefing": headers outside, one content pattern per module.
//
// Both read the SAME production providers, read-only, under the golden fixtures' overrides, and
// draw widgets in the order and visibility returned by `adaptiveTodayProvider` (the real
// `rankToday`). Nothing here writes to a provider. Modules this experiment does not redesign
// (care duty, Dành cho bé, ăn dặm, quick actions, vaccine, rhythm strip, handover row, stage card,
// Tuỳ chỉnh link) are the production widgets, unchanged, in both versions.
//
// Lives under test/ so it never ships; the file names avoid `_test.dart` so CI never runs it.
// See docs/design/explorations/today-adaptive-v2/README.md.
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_feedback.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/adaptive_signals.dart'
    show AxStageCard;
import 'package:child_life/features/adaptive/experience_repository.dart';
import 'package:child_life/features/adaptive/today_adaptive.dart'
    show AxCustomizeLink, todayFirstRunProvider;
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_duty.dart' show CareDutyChip;
import 'package:child_life/features/care/care_format.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/keepsakes/keepsake_access.dart';
import 'package:child_life/features/me/me_widgets.dart' show MeRow;
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/memories/memory_widgets.dart'
    show MediaTile;
import 'package:child_life/features/notifications/notification_bell.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/features/reminders/reminder_screens.dart'
    show reminderDayRelative, reminderWhenRelative;
import 'package:child_life/features/reminders/rule_repository.dart';
import 'package:child_life/features/reminders/rule_screens.dart'
    show ruleIcon, ruleTitle;
import 'package:child_life/features/solids/solids_today.dart'
    show SdTodayCard, sdOnTodayProvider;
import 'package:child_life/features/spending/spending_calc.dart'
    show MonthSummary, monthOf;
import 'package:child_life/features/spending/spending_format.dart'
    show categoryName, money, spLocale, tintColors;
import 'package:child_life/features/spending/spending_models.dart'
    show SpendingAccess;
import 'package:child_life/features/spending/spending_widgets.dart'
    show watchSpending;
import 'package:child_life/features/today/today_cards.dart'
    show TodayQuickActions, TodayVaccineCard;
import 'package:child_life/features/today/today_for_baby.dart'
    show TodayForBabySection, TodayHandoverRow;
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_screen.dart'
    show CareTile, DayRhythm;
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Strings the prototypes need that have no ARB key yet. In production they would be added with
/// a `tool/*_strings.py` script (vi template + en). Proposed, not canonical.
String _proto(BuildContext context, String id) {
  final vi = Localizations.localeOf(context).languageCode == 'vi';
  return switch (id) {
    'greetMorning' => vi ? 'Chào buổi sáng' : 'Good morning',
    'greetAfternoon' => vi ? 'Chào buổi chiều' : 'Good afternoon',
    'greetEvening' => vi ? 'Chào buổi tối' : 'Good evening',
    'loading' => vi ? 'Đang tải nhịp hôm nay' : "Loading today's rhythm",
    'addMoment' => vi ? 'Thêm' : 'Add',
    _ => id,
  };
}

/// Everything both versions read, from the same providers as TodayScreen.
class TodayData {
  TodayData._(this.ref, this.context);
  final WidgetRef ref;
  final BuildContext context;

  late final AppLocalizations l10n = AppLocalizations.of(context);
  late final Membership? me = ref.watch(selectedMembershipProvider);
  String get babyId => me!.babyId;
  late final Baby? baby = ref.watch(babyProvider(babyId)).value;
  late final String name = baby?.nickname ?? '';
  late final bool readOnly = me!.role == MemberRole.relative;
  late final bool parent = me!.role == MemberRole.coParent;
  late final AsyncValue<List<CareRecord>> recentAsync = ref.watch(
    recentRecordsProvider(babyId),
  );
  late final bool loading = !recentAsync.hasValue || baby == null;
  late final List<CareRecord> recent = recentAsync.value ?? const [];
  late final List<CareRecord> growth =
      ref.watch(growthRecordsProvider(babyId)).value ?? const [];
  late final DateTime now =
      ref.watch(careClockProvider).value ?? DateTime(2026, 10, 8, 10);
  late final String zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  late final String locale = Localizations.localeOf(context).toLanguageTag();
  late final bool online = ref.watch(onlineProvider).value ?? true;
  late final int pendingCount = recent.where((r) => r.pending).length;
  late final AgeBand band =
      ref.watch(childBandProvider(babyId)) ??
      ref.watch(experienceProvider(babyId)).bandApplied;
  late final AgeBand bandApplied = ref
      .watch(experienceProvider(babyId))
      .bandApplied;
  late final bool firstRun = ref.watch(todayFirstRunProvider(babyId));

  /// The real ranking: same provider as TodayScreen (pins, manual order, hidden, signals).
  late final List<RankedWidget> ranked = ref.watch(
    adaptiveTodayProvider(babyId),
  );
  late final List<MediaItem> media =
      ref.watch(mediaProvider((babyId, parent))).value ?? const [];

  CareTimer? running(CareType type) => switch (type) {
    CareType.sleep =>
      ref.watch(careTimerProvider((babyId, TimerType.sleep))).value,
    CareType.breast =>
      ref.watch(careTimerProvider((babyId, TimerType.breast))).value,
    CareType.pump =>
      ref.watch(careTimerProvider((babyId, TimerType.pump))).value,
    _ => null,
  };

  CareRecord? last(CareType type) => type == CareType.growth
      ? growth.firstOrNull
      : recent.where((r) => r.type == type).firstOrNull;

  /// Greeting with the same intent and keys as AdaptiveGreeting, but never "Chào …, " when the
  /// name is not known yet (TA-5 fallback).
  String greeting() {
    final hour = now.hour; // the mock clock is already in the baby's zone (Asia/Ho_Chi_Minh)
    if (name.isEmpty) {
      return _proto(
        context,
        hour < 12
            ? 'greetMorning'
            : hour < 18
            ? 'greetAfternoon'
            : 'greetEvening',
      );
    }
    if (firstRun) return l10n.axHello(name);
    return switch (band) {
      AgeBand.b0_1 || AgeBand.b1_3 =>
        hour < 12
            ? l10n.axGreetMorning(name)
            : hour < 18
            ? l10n.axGreetAfternoon(name)
            : l10n.axGreetEvening(name),
      AgeBand.b3_6 => l10n.axGreet36(name),
      AgeBand.b6_12 => l10n.axGreet612(name),
    };
  }

  String? firstRunSub() => !firstRun
      ? null
      : switch (band) {
          AgeBand.b0_1 => l10n.axHelloSub01,
          AgeBand.b1_3 => l10n.axHelloSub13,
          AgeBand.b3_6 => l10n.axHelloSub36,
          AgeBand.b6_12 => l10n.axHelloSub612,
        };

  /// Reminders exactly as ReminderPeek computes them (overdue first, then by time).
  List<ReminderItem>? reminders() {
    if (me == null || readOnly) return null;
    final all = ref.watch(remindersProvider(babyId)).value;
    if (all == null) return null;
    final rules = ref.watch(reminderRulesProvider(babyId)).value ?? const [];
    final groups = groupReminders(all, now, zone);
    final items = <ReminderItem>[
      for (final r in [...groups.overdue, ...groups.upcoming])
        ReminderItem(
          title: r.title,
          at: r.dueAt,
          overdue: r.statusAt(now, zone) == ReminderStatus.overdue,
          icon: ClIcons.bell,
          route: '${Routes.reminders}/${r.id}',
          day: r.dueDay,
        ),
      for (final r in rules)
        if (!r.enabled)
          ...[]
        else if (r.pendingDueAt case final due?)
          ReminderItem(
            title: ruleTitle(l10n, r.type),
            at: due,
            overdue: true,
            icon: ruleIcon(r.type),
            route: '${Routes.ruleDetail}/${r.id}',
            day: null,
          )
        else if (r.nextDueAt case final next?)
          ReminderItem(
            title: ruleTitle(l10n, r.type),
            at: next,
            overdue: false,
            icon: ruleIcon(r.type),
            route: '${Routes.ruleDetail}/${r.id}',
            day: null,
          ),
    ]..sort((a, b) {
        if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
        return a.at.compareTo(b.at);
      });
    return items;
  }

  /// The same "when" text as ReminderPeek (D-075 #5), shown untruncated in both prototypes.
  String when(ReminderItem r) {
    String cap(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final today = babyToday(zone, now);
    if (r.day case final allDay?) {
      final days = allDay.difference(today).inDays;
      if (r.overdue) {
        return l10n.reminderOverdueMeta(
          reminderDayRelative(l10n, locale, allDay, today),
        );
      }
      final label = switch (days) {
        0 => cap(l10n.dayToday),
        1 => cap(l10n.dayTomorrow),
        _ => cap(DateFormat('EEEE', locale).format(allDay)),
      };
      return [
        label,
        l10n.reminderAllDayLower,
        if (days > 0) l10n.reminderInDays(days),
      ].join(' · ');
    }
    final wall = inBabyZone(zone, r.at);
    if (r.overdue) {
      return l10n.reminderOverdueMeta(
        reminderWhenRelative(l10n, locale, wall, today),
      );
    }
    final day = DateTime(wall.year, wall.month, wall.day);
    final hm = DateFormat('HH:mm').format(wall);
    final days = day.difference(today).inDays;
    final label = switch (days) {
      0 => cap('${l10n.dayToday} $hm'),
      1 => cap('${l10n.dayTomorrow} $hm'),
      _ => '${cap(DateFormat('EEEE', locale).format(wall))} $hm',
    };
    final left = days == 0
        ? l10n.reminderInDuration(
            durationLabel(l10n, r.at.difference(now).inMinutes),
          )
        : l10n.reminderInDays(days);
    return '$label · $left';
  }

  static TodayData of(BuildContext context, WidgetRef ref) =>
      TodayData._(ref, context);
}

class ReminderItem {
  const ReminderItem({
    required this.title,
    required this.at,
    required this.overdue,
    required this.icon,
    required this.route,
    required this.day,
  });
  final String title;
  final DateTime at;
  final bool overdue;
  final ClIcons icon;
  final String route;
  final DateTime? day;
}

// ---------------------------------------------------------------- shared pieces

Widget _header() => const BabyHeader(
  actions: [NotificationBell(), SizedBox(width: ClSpace.s2), NightCareToggle()],
);

/// The production pending / offline banner, redrawn (it is private in today_screen.dart).
class _SyncBanner extends StatelessWidget {
  const _SyncBanner(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      margin: const EdgeInsets.only(top: ClSpace.s3),
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
    );
  }
}

Widget? _syncBanner(TodayData d) => d.pendingCount == 0
    ? null
    : _SyncBanner(
        d.online
            ? d.l10n.syncingBanner(d.pendingCount)
            : d.l10n.offlineBanner(d.pendingCount),
      );

/// The care tiles (production CareTile), laid out in content-sized rows instead of the
/// fixed-ratio grid (`childAspectRatio: 166 / 156`), which overflows at 200 % text (rendered in
/// compare_text-200_*). At 100 % the minimum height keeps today's proportion, so tiles look the
/// same; with large text they grow.
Widget _tiles(BuildContext context, WidgetRef ref, TodayData d) {
  final layout = ref.watch(todayLayoutProvider(d.babyId));
  final trackers = d.baby?.trackers ?? const <TrackerKind>[];
  final tiles = [
    for (final kind in layout.tiles(trackers))
      if (!layout.hiddenTiles.contains(kind))
        if (careTypeOf(kind) case final type?)
          CareTile(
            type: type,
            last: d.last(type),
            previousGrowth: type == CareType.growth && d.growth.length > 1
                ? d.growth[1]
                : null,
            myUid: d.me!.uid,
            now: d.now,
            readOnly: d.readOnly,
            firstLogPill: true,
            timer: d.running(type),
            onTap: () {},
          ),
  ];
  return LayoutBuilder(
    builder: (context, box) {
      final minH = (box.maxWidth - ClSpace.s3) / 2 * 156 / 166;
      return Column(
        children: [
          for (var i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: ClSpace.s3),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + 2; j++) ...[
                    if (j > i) const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: j < tiles.length
                          ? ConstrainedBox(
                              constraints: BoxConstraints(minHeight: minH),
                              child: tiles[j],
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

/// Loading: tile-shaped and row-shaped skeletons instead of "Chưa có" (TA-2).
Widget _tilesSkeleton(BuildContext context) => Semantics(
  label: _proto(context, 'loading'),
  child: GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: ClSpace.s3,
    crossAxisSpacing: ClSpace.s3,
    childAspectRatio: 166 / 156,
    children: [
      for (var i = 0; i < 4; i++)
        const ClSkeleton(height: double.infinity, radius: ClRadius.tile),
    ],
  ),
);

/// Modules this experiment keeps as production widgets (both versions).
List<Widget> _unchanged(WidgetRef ref, TodayData d, WidgetId id) =>
    switch (id) {
      WidgetId.careDuty => [const CareDutyChip()],
      WidgetId.forYou => [const TodayForBabySection()],
      WidgetId.solids => [
        if (ref.watch(sdOnTodayProvider)) ...[
          const SizedBox(height: ClSpace.s4),
          const SdTodayCard(),
        ],
      ],
      WidgetId.quickActions => [
        if (!d.readOnly) ...[
          const SizedBox(height: ClSpace.s6),
          TodayQuickActions(layout: ref.watch(todayLayoutProvider(d.babyId))),
        ],
      ],
      WidgetId.vaccine => [
        const SizedBox(height: ClSpace.s6),
        const TodayVaccineCard(),
      ],
      WidgetId.rhythm => [
        const SizedBox(height: ClSpace.s6),
        DayRhythm(
          records: d.recent,
          dayStart: babyDayBounds(d.zone, d.now).start,
          dayEnd: babyDayBounds(d.zone, d.now).end,
          now: d.now,
        ),
      ],
      _ => const [],
    };

/// Warm attention for an ordinary overdue reminder: icon + explicit text, never error red (TA-3).
Widget _whenLine(BuildContext context, TodayData d, ReminderItem r) {
  final cl = context.cl;
  final text = d.when(r);
  if (!r.overdue) {
    return Text(text, style: cl.text.label.copyWith(color: cl.colors.inkMuted));
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: ClIcon(ClIcons.alert, size: 16, color: cl.colors.pending),
      ),
      const SizedBox(width: ClSpace.s1),
      Expanded(
        child: Text(
          text,
          style: cl.text.label.copyWith(
            color: cl.colors.pending,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

Widget _reminderMark(BuildContext context, ReminderItem r) {
  final cl = context.cl;
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: r.overdue ? cl.colors.sunshineSoft : cl.colors.mintSoft,
      borderRadius: BorderRadius.circular(ClRadius.control),
    ),
    alignment: Alignment.center,
    child: ClIcon(r.icon, size: 20, color: cl.colors.ink),
  );
}

// ======================================================================= VERSION A

/// Version A — "Refined current": the AX structure (header inside one card per module) kept;
/// radius / padding / type from tokens, reminders two-line and warm, buttons demoted, skeletons.
class TodayProtoA extends ConsumerWidget {
  const TodayProtoA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = TodayData.of(context, ref);
    if (d.me == null) return const SizedBox.shrink();
    final cl = context.cl;
    final banner = _syncBanner(d);
    final sub = d.firstRunSub();
    return ClPinnedHeaderScaffold(
      header: _header(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, 140),
        children: [
          ?banner,
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s1),
            // Decision 6: Version A keeps the current greeting style exactly (largeTitle at 26,
            // a literal size off the scale — production debt, not a proposal).
            child: Semantics(
              header: true,
              child: Text(
                d.greeting(),
                style: cl.text.largeTitle.copyWith(fontSize: 26, height: 1.25),
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: ClSpace.s1),
            Text(sub, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          ],
          const AxStageCard(),
          for (final w in d.ranked)
            if (w.visible) ..._moduleA(context, ref, d, w.id),
          if (!d.readOnly) const AxCustomizeLink(),
        ],
      ),
    );
  }
}

List<Widget> _moduleA(
  BuildContext context,
  WidgetRef ref,
  TodayData d,
  WidgetId id,
) {
  final l10n = d.l10n;
  final cl = context.cl;
  switch (id) {
    case WidgetId.tiles:
      return [
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(
          // Working decision 5: "Nhịp hôm nay" for every band.
          title: d.firstRun ? l10n.axFirstLogTitle : l10n.axRhythmToday,
          linkLabel: d.firstRun ? null : l10n.axSeeHistory, // TA-8
          onLink: () => context.push(Routes.history),
        ),
        const SizedBox(height: ClSpace.s3),
        if (d.loading) _tilesSkeleton(context) else _tiles(context, ref, d),
        const TodayHandoverRow(),
      ];
    case WidgetId.reminders:
      final items = d.reminders();
      if (items == null) return const [];
      return [
        _CardA(
          icon: ClIcons.clock,
          chip: cl.colors.sunshineSoft,
          // Working decision 3: "Nhắc việc" (existing key reminderPeekTitle).
          title: l10n.reminderPeekTitle,
          subtitle: items.isEmpty ? null : l10n.axRemindersCount(items.length),
          link: items.isEmpty ? null : l10n.reminderPeekMore,
          child: items.isEmpty
              ? (d.parent
                    ? ClButton(
                        label: l10n.axRemindersFirst,
                        style: ClButtonStyle.tinted,
                        expand: true,
                        onPressed: () {},
                      )
                    : null)
              : Column(
                  children: [
                    for (final (i, r) in items.take(3).indexed) ...[
                      if (i > 0) const SizedBox(height: ClSpace.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reminderMark(context, r),
                          const SizedBox(width: ClSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: cl.text.body),
                                _whenLine(context, d, r),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ];
    case WidgetId.recentMemories || WidgetId.momentToday:
      return [_memoriesA(context, d, moment: id == WidgetId.momentToday)];
    case WidgetId.createFromMemories:
      return [_createA(context, ref, d)];
    case WidgetId.growth:
      return [_growthA(context, d)];
    case WidgetId.familyView:
      return [_familyA(context, ref, d)];
    case WidgetId.spending:
      return [_spendingA(context, ref, d)];
    default:
      return _unchanged(ref, d, id);
  }
}

/// The AX card, corrected: radius `card` (24), padding s4, title bodyStrong, link label (no
/// literal sizes). Same anatomy as AxCard.
class _CardA extends StatelessWidget {
  const _CardA({
    required this.icon,
    required this.chip,
    required this.title,
    this.subtitle,
    this.link,
    this.child,
  });
  final ClIcons icon;
  final Color chip;
  final String title;
  final String? subtitle;
  final String? link;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      margin: const EdgeInsets.only(top: ClSpace.s6),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: 20, color: cl.colors.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: cl.text.bodyStrong),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (link != null)
                ClPressable(
                  onPressed: () {},
                  semanticLabel: link,
                  child: Text(
                    link!,
                    style: cl.text.label.copyWith(color: cl.colors.mintText),
                  ),
                ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: ClSpace.s4), child!],
        ],
      ),
    );
  }
}

Widget _thumbStrip(List<MediaItem> media) => Row(
  children: [
    for (var i = 0; i < 3; i++) ...[
      if (i > 0) const SizedBox(width: ClSpace.s2),
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: i < media.length
              ? MediaTile(item: media[i], radius: ClRadius.control)
              : const SizedBox.shrink(),
        ),
      ),
    ],
  ],
);

Widget _memoriesA(BuildContext context, TodayData d, {required bool moment}) {
  final l10n = d.l10n;
  final cl = context.cl;
  if (d.media.isEmpty) {
    return _CardA(
      icon: d.band == AgeBand.b6_12 ? ClIcons.journal : ClIcons.camera,
      chip: cl.colors.peachSoft,
      title: switch (d.band) {
        AgeBand.b0_1 => l10n.axFirstMomentTitle,
        AgeBand.b6_12 => l10n.axFirstJournal(d.name),
        _ => l10n.axFirstMomentOf(d.name),
      },
      subtitle: switch (d.band) {
        AgeBand.b0_1 || AgeBand.b6_12 => l10n.axFirstMomentSub01,
        AgeBand.b1_3 => l10n.axFirstMomentSub,
        AgeBand.b3_6 => l10n.axFirstMomentSub36,
      },
      // Tinted, not filled: the screen's emphasis stays on content (D-105).
      child: d.parent
          ? ClButton(
              label: d.band == AgeBand.b6_12
                  ? l10n.axWriteJournal
                  : l10n.axAddMoment,
              style: ClButtonStyle.tinted,
              expand: true,
              onPressed: () {},
            )
          : null,
    );
  }
  final week = d.media
      .where((m) => d.now.difference(m.captureAt).inDays < 7)
      .length;
  return _CardA(
    icon: moment ? ClIcons.camera : ClIcons.memories,
    chip: cl.colors.peachSoft,
    title: moment ? l10n.axMomentTodayTitle : l10n.axRecentTitle,
    subtitle: moment ? l10n.axMomentTodaySub : l10n.axRecentSub(week),
    link: l10n.axSeeAll,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (moment)
          SizedBox(
            height: 150,
            child: MediaTile(item: d.media.first, radius: ClRadius.control),
          )
        else
          _thumbStrip(d.media),
        if (d.parent && (moment || d.band != AgeBand.b0_1)) ...[
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: d.band == AgeBand.b6_12
                ? l10n.axWriteJournal
                : l10n.axAddMoment,
            style: ClButtonStyle.tinted,
            expand: true,
            onPressed: () {},
          ),
        ],
      ],
    ),
  );
}

Widget _createTiles(BuildContext context, WidgetRef ref, TodayData d) {
  final cl = context.cl;
  final access = ref.watch(selectedKeepsakeAccessProvider);
  Widget tile(String title, String sub) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: cl.text.bodyStrong),
          Text(sub, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
        ],
      ),
    ),
  );
  return Row(
    children: [
      if (access.videos)
        tile(d.l10n.axCreateVideo, d.l10n.axCreateVideoSub),
      if (access.videos && access.cards) const SizedBox(width: ClSpace.s2),
      if (access.cards) tile(d.l10n.axCreateCard, d.l10n.axCreateCardSub),
    ],
  );
}

Widget _createA(BuildContext context, WidgetRef ref, TodayData d) => _CardA(
  icon: ClIcons.spark,
  chip: context.cl.colors.mintSoft,
  title: d.l10n.axCreateTitle(d.name),
  subtitle: d.l10n.axCreateSub,
  child: _createTiles(context, ref, d),
);

List<String> _growthParts(TodayData d) {
  final last = d.growth.firstOrNull;
  return [
    if (last?.weightKg case final w?) d.l10n.weightKg(decimal(d.locale, w)),
    if (last?.lengthCm case final h?) d.l10n.lengthCm(decimal(d.locale, h)),
  ];
}

Widget _growthA(BuildContext context, TodayData d) {
  final last = d.growth.firstOrNull;
  final parts = _growthParts(d);
  return _CardA(
    icon: ClIcons.ruler,
    chip: context.cl.care.growth.soft,
    title: d.l10n.axGrowthTitle,
    subtitle: last == null
        ? d.l10n.axGrowthNone
        : d.l10n.axGrowthLast(relativeAgo(d.l10n, last.occurredAt, d.now)),
    link: d.l10n.axGrowthLog,
    child: parts.isEmpty
        ? null
        : Text(parts.join(' · '), style: context.cl.text.title2),
  );
}

List<Membership> _members(WidgetRef ref, TodayData d) => [
  for (final m
      in ref.watch(familyMembersProvider(d.babyId)).value ??
          const <Membership>[])
    if (m.status == MembershipStatus.active) m,
];

Widget _avatars(BuildContext context, List<Membership> members) {
  final cl = context.cl;
  final fills = [cl.colors.peachSoft, cl.colors.mintSoft, cl.colors.surface2];
  final n = members.length.clamp(0, 4);
  return SizedBox(
    height: 32,
    width: n == 0 ? 0 : 32 + (n - 1) * 22,
    child: Stack(
      children: [
        for (var i = 0; i < n; i++)
          Positioned(
            left: i * 22.0,
            child: ExcludeSemantics(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: fills[i % fills.length],
                child: Text(
                  members[i].displayName.characters.firstOrNull
                          ?.toUpperCase() ??
                      '',
                  style: cl.text.label,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _familyA(BuildContext context, WidgetRef ref, TodayData d) {
  final members = _members(ref, d);
  final alone = members.length <= 1;
  return _CardA(
    icon: ClIcons.family,
    chip: context.cl.colors.mintSoft,
    title: d.l10n.axFamilyTitle,
    subtitle: alone ? d.l10n.axFamilyAlone(d.name) : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!alone) ...[
          Text(d.l10n.axFamilyBody, style: context.cl.text.label),
          const SizedBox(height: ClSpace.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: _avatars(context, members),
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        ClButton(
          label: d.l10n.axInvite,
          style: ClButtonStyle.tinted,
          expand: true,
          onPressed: () {},
        ),
      ],
    ),
  );
}

Widget _spendingBody(BuildContext context, WidgetRef ref, TodayData d) {
  final cl = context.cl;
  final scope = watchSpending(ref)!;
  final locale = spLocale(context);
  final s = MonthSummary.of(
    scope.expenses,
    monthOf(scope.today),
    scope.today,
    currency: scope.currency,
  );
  final parts = [
    for (final e
        in (s.byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))))
      (category: scope.category(e.key), amount: e.value),
  ];
  final shown = parts.take(3).toList();
  final rest = parts.skip(3).fold(0, (a, p) => a + p.amount);
  final total = s.total == 0 ? 1 : s.total;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(money(locale, s.total, scope.currency), style: cl.text.title2),
      const SizedBox(height: ClSpace.s2),
      ClipRRect(
        borderRadius: BorderRadius.circular(ClRadius.pill),
        child: SizedBox(
          height: 8,
          child: Row(
            children: [
              for (final (i, p) in shown.indexed) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: (p.amount * 1000 ~/ total).clamp(1, 1000),
                  child: ColoredBox(
                    color: tintColors(context, p.category.tint).accent,
                  ),
                ),
              ],
              if (rest > 0) ...[
                const SizedBox(width: 2),
                Expanded(
                  flex: (rest * 1000 ~/ total).clamp(1, 1000),
                  child: ColoredBox(color: cl.colors.separator),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: ClSpace.s2),
      Text(
        [
          for (final p in shown) categoryName(d.l10n, p.category),
          if (rest > 0) d.l10n.spCatOther,
        ].join(' · '),
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    ],
  );
}

({bool show, bool empty, bool canRecord, String month, int count}) _spending(
  BuildContext context,
  WidgetRef ref,
  TodayData d,
) {
  if (!SpendingAccess.of(d.me!).viewAll) {
    return (show: false, empty: true, canRecord: false, month: '', count: 0);
  }
  final scope = watchSpending(ref);
  if (scope == null || !scope.access.viewAll) {
    return (show: false, empty: true, canRecord: false, month: '', count: 0);
  }
  final s = MonthSummary.of(
    scope.expenses,
    monthOf(scope.today),
    scope.today,
    currency: scope.currency,
  );
  final month = toBeginningOfSentenceCase(
    DateFormat.MMMM(
      spLocale(context),
    ).format(DateTime(s.month.year, s.month.month)),
  );
  return (
    show: true,
    empty: s.items.isEmpty,
    canRecord: scope.access.record,
    month: month,
    count: s.items.length,
  );
}

Widget _spendingA(BuildContext context, WidgetRef ref, TodayData d) {
  final sp = _spending(context, ref, d);
  if (!sp.show) return const SizedBox.shrink();
  final cl = context.cl;
  if (sp.empty) {
    return _CardA(
      icon: ClIcons.drop,
      chip: cl.colors.mintSoft,
      title: d.l10n.axSpendFor(d.name),
      subtitle: d.l10n.axSpendNone,
      child: sp.canRecord
          ? ClButton(
              label: d.l10n.axSpendFirst,
              style: ClButtonStyle.tinted,
              expand: true,
              onPressed: () {},
            )
          : null,
    );
  }
  return _CardA(
    icon: ClIcons.drop,
    chip: cl.colors.mintSoft,
    title: d.l10n.axWidgetSpending,
    subtitle: d.l10n.axSpendSub(sp.month, sp.count),
    link: sp.canRecord ? d.l10n.axSpendAdd : null,
    child: _spendingBody(context, ref, d),
  );
}

// ======================================================================= VERSION B

/// Version B — "Adaptive Briefing": one outer grammar (heading + link outside, content in one
/// surface below), a different inner pattern per module, empty modules as one invitation row,
/// no filled buttons on the page, a lighter greeting.
class TodayProtoB extends ConsumerWidget {
  const TodayProtoB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = TodayData.of(context, ref);
    if (d.me == null) return const SizedBox.shrink();
    final cl = context.cl;
    final banner = _syncBanner(d);
    final sub = d.firstRunSub();
    return ClPinnedHeaderScaffold(
      header: _header(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, 140),
        children: [
          ?banner,
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s2),
            // Reduced from largeTitle to title2 (decision 6, explored only in B).
            child: Semantics(
              header: true,
              child: Text(d.greeting(), style: cl.text.title2),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: ClSpace.s1),
            Text(sub, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          ],
          const AxStageCard(),
          for (final w in d.ranked)
            if (w.visible) ..._moduleB(context, ref, d, w.id),
          if (!d.readOnly) const AxCustomizeLink(),
        ],
      ),
    );
  }
}

/// Heading outside, content below — the one outer grammar of Version B.
List<Widget> _section(
  BuildContext context, {
  required String title,
  String? link,
  required Widget body,
}) => [
  const SizedBox(height: ClSpace.s6),
  ClSectionHeader(title: title, linkLabel: link, onLink: link == null ? null : () {}),
  const SizedBox(height: ClSpace.s3),
  body,
];

/// A surface for non-row content (the interim card recipe: card radius, card shadow, s4).
Widget _surface(BuildContext context, Widget child) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(ClSpace.s4),
  decoration: BoxDecoration(
    color: context.cl.colors.surface,
    borderRadius: BorderRadius.circular(ClRadius.card),
    boxShadow: context.cl.shadows.card,
  ),
  child: child,
);

/// An empty module: one invitation row instead of placeholders and a button (TA-6).
Widget _invite(
  BuildContext context, {
  required ClIcons icon,
  required Color tint,
  required String title,
  String? subtitle,
}) => ClCardGroup(
  children: [
    MeRow(
      title: title,
      subtitle: subtitle,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(ClRadius.control),
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: context.cl.colors.ink),
      ),
      onTap: () {},
    ),
  ],
);

List<Widget> _moduleB(
  BuildContext context,
  WidgetRef ref,
  TodayData d,
  WidgetId id,
) {
  final l10n = d.l10n;
  final cl = context.cl;
  switch (id) {
    case WidgetId.tiles:
      return [
        ..._section(
          context,
          title: d.firstRun ? l10n.axFirstLogTitle : l10n.axRhythmToday,
          link: d.firstRun ? null : l10n.axSeeHistory,
          body: d.loading ? _tilesSkeleton(context) : _tiles(context, ref, d),
        ),
        const TodayHandoverRow(),
      ];
    case WidgetId.reminders:
      final items = d.reminders();
      if (items == null) return const [];
      if (items.isEmpty) {
        return _section(
          context,
          title: l10n.reminderPeekTitle,
          body: _invite(
            context,
            icon: ClIcons.clock,
            tint: cl.colors.mintSoft,
            title: d.parent ? l10n.axRemindersFirst : l10n.reminderPeekMore,
          ),
        );
      }
      return _section(
        context,
        title: l10n.reminderPeekLabel(items.length),
        link: l10n.reminderPeekMore,
        body: ClCardGroup(
          children: [
            for (final r in items.take(3))
              ClPressable(
                onPressed: () {},
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: '${r.title}, ${d.when(r)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s4,
                    vertical: ClSpace.s3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reminderMark(context, r),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: cl.text.body),
                            _whenLine(context, d, r),
                          ],
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s2),
                        child: ClIcon(
                          ClIcons.chevronRight,
                          size: 16,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    case WidgetId.recentMemories || WidgetId.momentToday:
      final moment = id == WidgetId.momentToday;
      if (d.media.isEmpty) {
        return _section(
          context,
          title: l10n.axRecentTitle,
          body: _invite(
            context,
            icon: d.band == AgeBand.b6_12 ? ClIcons.journal : ClIcons.camera,
            tint: cl.colors.peachSoft,
            title: switch (d.band) {
              AgeBand.b0_1 => l10n.axFirstMomentTitle,
              AgeBand.b6_12 => l10n.axFirstJournal(d.name),
              _ => l10n.axFirstMomentOf(d.name),
            },
            subtitle: switch (d.band) {
              AgeBand.b0_1 || AgeBand.b6_12 => l10n.axFirstMomentSub01,
              AgeBand.b1_3 => l10n.axFirstMomentSub,
              AgeBand.b3_6 => l10n.axFirstMomentSub36,
            },
          ),
        );
      }
      final week = d.media
          .where((m) => d.now.difference(m.captureAt).inDays < 7)
          .length;
      // Photography first: tiles lift off the page (ClTileShadow), no card around them.
      Widget addTile() => ClPressable(
        onPressed: () {},
        pressedOpacity: ClPressable.surfaceOpacity,
        semanticLabel: l10n.axAddMoment,
        child: Container(
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClIcon(ClIcons.plus, size: 24, color: cl.colors.mintText),
              const SizedBox(height: ClSpace.s1),
              Text(
                _proto(context, 'addMoment'),
                style: cl.text.label.copyWith(color: cl.colors.mintText),
              ),
            ],
          ),
        ),
      );
      final photos = d.media.take(d.parent ? 2 : 3).toList();
      return _section(
        context,
        title: moment ? l10n.axMomentTodayTitle : l10n.axRecentTitle,
        link: l10n.axSeeAll,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (moment)
              SizedBox(
                height: 180,
                child: ClTileShadow(
                  radius: ClRadius.card,
                  child: MediaTile(item: d.media.first, radius: ClRadius.card),
                ),
              )
            else
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: i < photos.length
                            ? ClTileShadow(
                                radius: ClRadius.control,
                                child: MediaTile(
                                  item: photos[i],
                                  radius: ClRadius.control,
                                ),
                              )
                            : (d.parent && i == photos.length
                                  ? addTile()
                                  : const SizedBox.shrink()),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: ClSpace.s2),
            Text(
              moment ? l10n.axMomentTodaySub : l10n.axRecentSub(week),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            if (moment && d.parent) ...[
              const SizedBox(height: ClSpace.s3),
              ClCardGroup(
                children: [
                  MeRow(icon: ClIcons.plus, title: l10n.axAddMoment, onTap: () {}),
                ],
              ),
            ],
          ],
        ),
      );
    case WidgetId.createFromMemories:
      final access = ref.watch(selectedKeepsakeAccessProvider);
      return _section(
        context,
        title: l10n.axCreateTitle(d.name),
        body: ClCardGroup(
          children: [
            if (access.videos)
              MeRow(
                icon: ClIcons.video,
                title: l10n.axCreateVideo,
                subtitle: l10n.axCreateVideoSub,
                onTap: () {},
              ),
            if (access.cards)
              MeRow(
                icon: ClIcons.star,
                title: l10n.axCreateCard,
                subtitle: l10n.axCreateCardSub,
                onTap: () {},
              ),
          ],
        ),
      );
    case WidgetId.growth:
      final last = d.growth.firstOrNull;
      final parts = _growthParts(d);
      if (last == null) {
        return _section(
          context,
          title: l10n.axGrowthTitle,
          body: _invite(
            context,
            icon: ClIcons.ruler,
            tint: cl.care.growth.soft,
            title: l10n.axGrowthLog,
            subtitle: l10n.axGrowthNone,
          ),
        );
      }
      return _section(
        context,
        title: l10n.axGrowthTitle,
        link: l10n.axGrowthLog,
        body: ClPressable(
          onPressed: () {},
          pressedOpacity: ClPressable.surfaceOpacity,
          semanticLabel: parts.join(', '),
          child: _surface(
            context,
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cl.care.growth.soft,
                    borderRadius: BorderRadius.circular(ClRadius.control),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(ClIcons.ruler, size: 20, color: cl.care.growth.ink),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parts.join(' · '), style: cl.text.title2),
                      Text(
                        l10n.axGrowthLast(
                          relativeAgo(l10n, last.occurredAt, d.now),
                        ),
                        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                      ),
                    ],
                  ),
                ),
                ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
              ],
            ),
          ),
        ),
      );
    case WidgetId.familyView:
      final members = _members(ref, d);
      final alone = members.length <= 1;
      return _section(
        context,
        title: l10n.axFamilyTitle,
        body: ClCardGroup(
          children: [
            if (!alone)
              MeRow(
                leading: _avatars(context, members),
                title: l10n.axFamilyBody,
              ),
            MeRow(
              icon: ClIcons.plus,
              title: l10n.axInvite,
              subtitle: alone ? l10n.axFamilyAlone(d.name) : null,
              onTap: () {},
            ),
          ],
        ),
      );
    case WidgetId.spending:
      final sp = _spending(context, ref, d);
      if (!sp.show) return const [];
      if (sp.empty) {
        return _section(
          context,
          title: l10n.axSpendFor(d.name),
          body: _invite(
            context,
            icon: ClIcons.drop,
            tint: cl.colors.mintSoft,
            title: sp.canRecord ? l10n.axSpendFirst : l10n.axSpendNone,
            subtitle: sp.canRecord ? l10n.axSpendNone : null,
          ),
        );
      }
      return _section(
        context,
        title: l10n.axWidgetSpending,
        link: sp.canRecord ? l10n.axSpendAdd : null,
        body: _surface(context, _spendingBody(context, ref, d)),
      );
    default:
      return _unchanged(ref, d, id);
  }
}
