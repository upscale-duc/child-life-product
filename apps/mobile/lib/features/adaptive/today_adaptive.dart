import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/care_sheets.dart' show openCareLog;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_access.dart';
import '../memories/memories_screen.dart' show memoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_sheets.dart' show showAddSheet;
import '../memories/memory_widgets.dart' show MediaTile;
import '../spending/spending_calc.dart' show MonthSummary, monthOf;
import '../spending/spending_format.dart'
    show categoryName, money, spLocale, tintColors;
import '../spending/spending_sheets.dart' show showExpenseSheet;
import '../spending/spending_widgets.dart' show watchSpending;
import 'adaptive_engine.dart';
import 'reorder_group.dart';
import 'adaptive_signals.dart'
    show customizeDetails, rankSignalsProvider, reportAdaptive;
import 'experience_repository.dart';

/// Hôm nay of the Adaptive Experience (Figma 930:11858): the greeting per age band (AX10–AX13),
/// its first-run twin (AX40–AX43), the new widgets and "Tuỳ chỉnh Hôm nay" (AX14). Existing
/// sections (tiles, reminders, spending…) are drawn by `today_screen.dart` as before.

/// First run: nothing logged and no memory yet (AX40–AX43).
final todayFirstRunProvider = Provider.family<bool, String>((ref, babyId) {
  final records = ref.watch(recentRecordsProvider(babyId));
  final me = ref.watch(selectedMembershipProvider);
  final media = ref.watch(
    mediaProvider((babyId, me?.role == MemberRole.coParent)),
  );
  if (!records.hasValue || !media.hasValue) return false;
  return records.value!.isEmpty && media.value!.isEmpty;
});

/// AX10–AX13 greeting and sub-line, or AX40–AX43 "Chào {tên} 👋" on the first run.
class AdaptiveGreeting extends ConsumerWidget {
  const AdaptiveGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final name = baby?.nickname ?? '';
    final band =
        ref.watch(childBandProvider(me.babyId)) ??
        ref.watch(experienceProvider(me.babyId)).bandApplied;
    final first = ref.watch(todayFirstRunProvider(me.babyId));
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final hour = inBabyZone(
      baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
      now,
    ).hour;
    // D-108: without a nickname yet, a nameless greeting (never "Chào buổi chiều, ").
    final named = name.trim().isNotEmpty;
    final timeOfDay = hour < 12
        ? (named ? l10n.axGreetMorning(name) : l10n.axGreetMorningNoName)
        : hour < 18
        ? (named ? l10n.axGreetAfternoon(name) : l10n.axGreetAfternoonNoName)
        : (named ? l10n.axGreetEvening(name) : l10n.axGreetEveningNoName);
    // Owner, 2026-10-25: the every-day greeting has no sub-line ("Nhịp hôm nay của con, ghi
    // nhanh trong một chạm."); the first-run hello keeps its guidance.
    final (String title, String? sub) = first
        ? (
            named ? l10n.axHello(name) : timeOfDay,
            switch (band) {
              AgeBand.b0_1 => l10n.axHelloSub01,
              AgeBand.b1_3 => l10n.axHelloSub13,
              AgeBand.b3_6 => l10n.axHelloSub36,
              AgeBand.b6_12 => l10n.axHelloSub612,
            },
          )
        : (
            switch (band) {
              AgeBand.b0_1 || AgeBand.b1_3 => timeOfDay,
              AgeBand.b3_6 when named => l10n.axGreet36(name),
              AgeBand.b6_12 when named => l10n.axGreet612(name),
              _ => timeOfDay,
            },
            null,
          );
    return Padding(
      // Close under the baby header (owner, 2026-10-25).
      padding: const EdgeInsets.only(top: ClSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              key: const Key('axGreeting'),
              style: cl.text.largeTitle.copyWith(
                fontSize: 26,
                height: 1.25,
                color: cl.colors.ink,
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: ClSpace.s1),
            Text(
              sub,
              style: cl.text.body.copyWith(
                fontSize: 14,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The AX widget card: icon chip, title, subtitle, optional trailing link, then [child].
/// On tokens (D-108): radius `card`, padding s4, title bodyStrong, link label.
class AxCard extends StatelessWidget {
  const AxCard({
    required this.icon,
    required this.chip,
    required this.title,
    this.subtitle,
    this.link,
    this.onLink,
    this.child,
    this.top = ClSpace.s4,
    super.key,
  });

  final ClIcons icon;
  final Color chip;
  final String title;
  final String? subtitle;
  final String? link;
  final VoidCallback? onLink;
  final Widget? child;

  /// The gap above the card; 0 where the screen sets it (ReminderPeek on Hôm nay).
  final double top;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      margin: EdgeInsets.only(top: top),
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
                padding: const EdgeInsets.all(ClSpace.s2),
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                // Ink on the soft fills, Night care included.
                child: ClIcon(icon, size: 20, color: cl.colors.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                    ),
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
              if (link != null) ...[
                const SizedBox(width: ClSpace.s2),
                ClPressable(
                  onPressed: onLink,
                  semanticLabel: link,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        link!,
                        style: cl.text.label.copyWith(
                          color: cl.colors.mintText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (child != null) ...[const SizedBox(height: ClSpace.s4), child!],
        ],
      ),
    );
  }
}

void _addMoment(BuildContext context, WidgetRef ref) {
  final c = memoryCtx(context, ref);
  if (c != null) unawaited(showAddSheet(context, ref, c));
}

/// The child's photos and videos, newest first, that this person sees.
List<MediaItem> _media(WidgetRef ref, Membership me) =>
    ref
        .watch(mediaProvider((me.babyId, me.role == MemberRole.coParent)))
        .value ??
    const [];

class _Thumbs extends StatelessWidget {
  const _Thumbs(this.items);
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: ClSpace.s2),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: i < items.length
                ? MediaTile(
                    item: items[i],
                    radius: ClRadius.control,
                    onTap: () => context.go(Routes.memories),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.cl.colors.surface2,
                      borderRadius: BorderRadius.circular(ClRadius.control),
                    ),
                  ),
          ),
        ),
      ],
    ],
  );
}

/// AX10/AX11/AX13 "Kỷ niệm gần đây"; on the first run AX40–AX43 "Lưu khoảnh khắc đầu tiên"
/// (6–12: "Bắt đầu cuốn nhật ký của {tên}").
class AxRecentMemories extends ConsumerWidget {
  const AxRecentMemories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final band = ref.watch(experienceProvider(me.babyId)).bandApplied;
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final media = _media(ref, me);
    final canAdd = me.role == MemberRole.coParent;
    if (media.isEmpty) {
      return AxCard(
        key: const Key('axFirstMoment'),
        icon: band == AgeBand.b6_12 ? ClIcons.journal : ClIcons.camera,
        chip: cl.colors.peachSoft,
        title: switch (band) {
          AgeBand.b0_1 => l10n.axFirstMomentTitle,
          AgeBand.b6_12 => l10n.axFirstJournal(name),
          _ => l10n.axFirstMomentOf(name),
        },
        subtitle: switch (band) {
          AgeBand.b0_1 || AgeBand.b6_12 => l10n.axFirstMomentSub01,
          AgeBand.b1_3 => l10n.axFirstMomentSub,
          AgeBand.b3_6 => l10n.axFirstMomentSub36,
        },
        child: canAdd
            ? ClButton(
                label: band == AgeBand.b6_12
                    ? l10n.axWriteJournal
                    : l10n.axAddMoment,
                style: ClButtonStyle.tinted,
                expand: true,
                onPressed: () => _addMoment(context, ref),
              )
            : null,
      );
    }
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final week = media
        .where((m) => now.difference(m.captureAt).inDays < 7)
        .length;
    return AxCard(
      key: const Key('axRecentMemories'),
      icon: ClIcons.memories,
      chip: cl.colors.peachSoft,
      title: l10n.axRecentTitle,
      subtitle: l10n.axRecentSub(week),
      link: l10n.axSeeAll,
      onLink: () => context.go(Routes.memories),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Thumbs(media),
          if (canAdd && band != AgeBand.b0_1) ...[
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: band == AgeBand.b6_12
                  ? l10n.axWriteJournal
                  : l10n.axAddMoment,
              style: ClButtonStyle.tinted,
              expand: true,
              onPressed: () => _addMoment(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

/// AX12 "Lưu khoảnh khắc hôm nay": the latest photo and "Thêm khoảnh khắc" (Cùng nuôi).
class AxMomentToday extends ConsumerWidget {
  const AxMomentToday({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final media = _media(ref, me);
    if (media.isEmpty) return const AxRecentMemories();
    return AxCard(
      key: const Key('axMomentToday'),
      icon: ClIcons.camera,
      chip: cl.colors.peachSoft,
      title: l10n.axMomentTodayTitle,
      subtitle: l10n.axMomentTodaySub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: MediaTile(
              item: media.first,
              radius: ClRadius.control,
              onTap: () => context.go(Routes.memories),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l10n.axAddMoment,
            style: ClButtonStyle.tinted,
            expand: true,
            onPressed: () => _addMoment(context, ref),
          ),
        ],
      ),
    );
  }
}

/// AX12 "Tạo từ kỷ niệm của {tên}": Video kỷ niệm · Thiệp, each only with its beta (D-068).
class AxCreateFromMemories extends ConsumerWidget {
  const AxCreateFromMemories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final access = ref.watch(selectedKeepsakeAccessProvider);
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    Widget tile(String title, String sub, String route) => Expanded(
      child: ClPressable(
        onPressed: () => context.push(route),
        semanticLabel: '$title, $sub',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
              ),
              Text(
                sub,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
    return AxCard(
      key: const Key('axCreate'),
      icon: ClIcons.spark,
      chip: cl.colors.mintSoft,
      title: l10n.axCreateTitle(name),
      subtitle: l10n.axCreateSub,
      child: Row(
        children: [
          if (access.videos)
            tile(l10n.axCreateVideo, l10n.axCreateVideoSub, Routes.memoryStory),
          if (access.videos && access.cards) const SizedBox(width: ClSpace.s2),
          if (access.cards)
            tile(l10n.axCreateCard, l10n.axCreateCardSub, Routes.milestoneCard),
        ],
      ),
    );
  }
}

/// AX10/AX11/AX13 "Tăng trưởng": the last measure and "Ghi số đo".
class AxGrowth extends ConsumerWidget {
  const AxGrowth({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final last = (ref.watch(growthRecordsProvider(me.babyId)).value ?? const [])
        .firstOrNull;
    final parts = [
      if (last?.weightKg case final w?) l10n.weightKg(decimal(locale, w)),
      if (last?.lengthCm case final h?) l10n.lengthCm(decimal(locale, h)),
    ];
    return AxCard(
      key: const Key('axGrowth'),
      icon: ClIcons.ruler,
      chip: cl.care.growth.soft,
      title: l10n.axGrowthTitle,
      subtitle: last == null
          ? l10n.axGrowthNone
          : l10n.axGrowthLast(relativeAgo(l10n, last.occurredAt, now)),
      link: l10n.axGrowthLog,
      onLink: () => openCareLog(context, CareType.growth),
      child: parts.isEmpty
          ? null
          : ClPressable(
              onPressed: () => context.push(Routes.growth),
              semanticLabel: parts.join(' · '),
              child: Text(
                parts.join(' · '),
                style: cl.text.title2.copyWith(color: cl.colors.ink),
              ),
            ),
    );
  }
}

/// AX12 "Cả nhà cùng xem" / AX42 "Chỉ mình bạn trong gia đình của {tên}" with "Mời người thân".
class AxFamilyView extends ConsumerWidget {
  const AxFamilyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final members = [
      for (final m
          in ref.watch(familyMembersProvider(me.babyId)).value ??
              const <Membership>[])
        if (m.status == MembershipStatus.active) m,
    ];
    final alone = members.length <= 1;
    final avatars = [
      cl.colors.peachSoft,
      cl.colors.mintSoft,
      cl.colors.surface2,
    ];
    return AxCard(
      key: const Key('axFamily'),
      icon: ClIcons.family,
      chip: cl.colors.mintSoft,
      title: l10n.axFamilyTitle,
      subtitle: alone ? l10n.axFamilyAlone(name) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!alone) ...[
            Text(
              l10n.axFamilyBody,
              style: cl.text.label.copyWith(color: cl.colors.ink),
            ),
            const SizedBox(height: ClSpace.s3),
            SizedBox(
              height: 32,
              child: Stack(
                children: [
                  for (var i = 0; i < members.length && i < 4; i++)
                    Positioned(
                      left: i * 24.0,
                      child: ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: avatars[i % avatars.length],
                          child: Text(
                            members[i].displayName.characters.firstOrNull
                                    ?.toUpperCase() ??
                                '',
                            style: cl.text.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cl.colors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
          ],
          ClButton(
            label: l10n.axInvite,
            style: ClButtonStyle.tinted,
            expand: true,
            onPressed: () => context.push(Routes.invite),
          ),
        ],
      ),
    );
  }
}

/// "Tuỳ chỉnh Hôm nay" at the end of a populated Hôm nay (AX10–AX13, not on the first run).
class AxCustomizeLink extends ConsumerWidget {
  const AxCustomizeLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: ClPressable(
        key: const Key('axCustomize'),
        onPressed: () => context.push(AdaptiveRoutes.customize),
        semanticLabel: l10n.axCustomizeLink,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(ClIcons.sliders, size: 16, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Text(
                l10n.axCustomizeLink,
                style: cl.text.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.mintText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class AdaptiveRoutes {
  static const customize = '/customize-today';
}

List<RouteBase> adaptiveRoutes() => [
  GoRoute(
    path: AdaptiveRoutes.customize,
    pageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      fullscreenDialog: true,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: const AxCustomizeScreen(),
    ),
  ),
];

// ---------- AX14 Tuỳ chỉnh Hôm nay ----------

String goalLabel(AppLocalizations l10n, Goal g) => switch (g) {
  Goal.trackCare => l10n.axGoalTrackCare,
  Goal.memories => l10n.axGoalMemories,
  Goal.growthVaccines => l10n.axGoalGrowth,
  Goal.family => l10n.axGoalFamily,
  Goal.spending => l10n.axGoalSpending,
  Goal.reminders => l10n.axGoalReminders,
};

String goalSub(AppLocalizations l10n, Goal g) => switch (g) {
  Goal.trackCare => l10n.axGoalTrackCareSub,
  Goal.memories => l10n.axGoalMemoriesSub,
  Goal.growthVaccines => l10n.axGoalGrowthSub,
  Goal.family => l10n.axGoalFamilySub,
  Goal.spending => l10n.axGoalSpendingSub,
  Goal.reminders => l10n.axGoalRemindersSub,
};

String widgetTitle(AppLocalizations l10n, WidgetId id) => switch (id) {
  WidgetId.tiles => l10n.axWidgetTiles,
  WidgetId.forYou => l10n.rhSectionForYou,
  WidgetId.solids => l10n.sdSectionToday,
  WidgetId.reminders => l10n.axWidgetReminders,
  WidgetId.quickActions => l10n.axWidgetQuickActions,
  WidgetId.vaccine => l10n.axWidgetVaccine,
  WidgetId.spending => l10n.axWidgetSpending,
  WidgetId.rhythm => l10n.axWidgetRhythm,
  WidgetId.recentMemories => l10n.axRecentTitle,
  WidgetId.momentToday => l10n.axMomentTodayTitle,
  WidgetId.createFromMemories => l10n.axWidgetCreate,
  WidgetId.growth => l10n.axGrowthTitle,
  WidgetId.familyView => l10n.axFamilyTitle,
  WidgetId.careDuty => l10n.axWidgetCareDuty,
};

class AxCustomizeScreen extends ConsumerStatefulWidget {
  const AxCustomizeScreen({super.key});

  @override
  ConsumerState<AxCustomizeScreen> createState() => _AxCustomizeScreenState();
}

class _AxCustomizeScreenState extends ConsumerState<AxCustomizeScreen> {
  /// Changes stay here until "Xong"; the close button drops them.
  Experience? _draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final babyId = me.babyId;
    final saved = ref.watch(experienceProvider(babyId));
    final draft = _draft ?? saved;
    void update(Experience next) => setState(() => _draft = next);
    final name = ref.watch(babyProvider(babyId)).value?.nickname ?? '';
    final band = ref.watch(childBandProvider(babyId)) ?? draft.bandApplied;
    // The same signals as Hôm nay (adaptiveTodayProvider): without them this list showed one
    // order and Hôm nay, reordered by taps, another (owner, 2026-10-25: "ko theo cài đặt").
    final ranked = rankToday(
      draft,
      ref.watch(availableWidgetsProvider(babyId)),
      ref.watch(rankSignalsProvider(babyId)),
    );
    final showing = [
      for (final w in ranked)
        if (w.visible && w.id != WidgetId.careDuty) w,
    ];
    final hidden = [
      for (final w in ranked)
        if (!w.visible && w.id != WidgetId.careDuty) w,
    ];
    final parent = me.role == MemberRole.coParent;

    void setVisible(WidgetId id, bool on) => update(
      draft.copyWith(
        shown: on
            ? {...draft.shown, id}.toList()
            : [...draft.shown.where((w) => w != id)],
        hidden: on
            ? [...draft.hidden.where((w) => w != id)]
            : {...draft.hidden, id}.toList(),
      ),
    );

    Widget row(RankedWidget w, {required bool on, Widget? handle}) {
      final title = widgetTitle(l10n, w.id);
      // D-110 / D-115: title only. The ranking reason ("Theo mục tiêu …", "Gợi ý cho tuổi …",
      // "Luôn có", "Ẩn theo gợi ý tuổi …") explained the engine, not a choice the parent makes.
      return Container(
        key: ValueKey(w.id),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.only(left: 2, right: 14, top: 4, bottom: 4),
        child: Row(
          children: [
            // Pinned and hidden rows do not move; the gap keeps the titles aligned.
            handle ?? const SizedBox(width: 44),
            const SizedBox(width: ClSpace.s1),
            Expanded(
              child: Text(
                title,
                style: cl.text.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.ink,
                ),
              ),
            ),
            if (on)
              ClPressable(
                onPressed: () => update(
                  draft.copyWith(
                    pinned: draft.pinned.contains(w.id)
                        ? [...draft.pinned.where((p) => p != w.id)]
                        : [...draft.pinned, w.id],
                  ),
                ),
                semanticLabel: w.pinned
                    ? l10n.axUnpin(title)
                    : l10n.axPin(title),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: ClIcon(
                      w.pinned ? ClIcons.bookmarkFill : ClIcons.bookmark,
                      size: 16,
                      color: w.pinned ? cl.colors.ink : cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ClToggle(
              value: on,
              semanticLabel: title,
              onChanged: (v) => setVisible(w.id, v),
            ),
          ],
        ),
      );
    }

    final movable = [
      for (final w in showing)
        if (!w.pinned) w,
    ];

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClSpace.s8,
          ),
          children: [
            Row(
              children: [
                ClPressable(
                  onPressed: () => context.pop(),
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonLabel,
                  child: Container(
                    padding: const EdgeInsets.all(ClSpace.s2),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: ClIcon(
                      ClIcons.close,
                      size: 20,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
                const Spacer(),
                ClPressable(
                  key: const Key('axDone'),
                  onPressed: () {
                    if (_draft case final d?) {
                      ref
                          .read(experienceProvider(babyId).notifier)
                          .set(
                            d.copyWith(
                              pinned: d.pinned
                                  .where((w) => w != WidgetId.careDuty)
                                  .toList(),
                            ),
                          );
                      for (final detail in customizeDetails(saved, d)) {
                        reportAdaptive(
                          ref,
                          context,
                          'adaptive_customized',
                          detail,
                        );
                      }
                    }
                    context.pop();
                  },
                  semanticLabel: l10n.axDone,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        l10n.axDone,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 15,
                          color: cl.colors.mintText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.axCustomizeLink,
              style: cl.text.largeTitle.copyWith(
                fontSize: 26,
                color: cl.colors.ink,
              ),
            ),
            const SizedBox(height: ClSpace.s1),
            // D-115: what to do here (drag, pin), not how the suggestions are made.
            Text(
              l10n.axCustomizeHint,
              style: cl.text.body.copyWith(
                fontSize: 14,
                color: cl.colors.inkMuted,
              ),
            ),
            // Goals are the person's (D-097 Q-089); caregivers have no goal step (Q-092).
            if (parent) ...[
              const SizedBox(height: 20),
              _Label(l10n.axGoalsLabel),
              Wrap(
                spacing: ClSpace.s2,
                runSpacing: ClSpace.s2,
                children: [
                  for (final g in draft.goals)
                    _Chip(label: goalLabel(l10n, g), tinted: true),
                  ClPressable(
                    key: const Key('axGoalsEdit'),
                    onPressed: () async {
                      final picked = await showGoalsSheet(
                        context,
                        name: name,
                        band: band,
                        selected: draft.goals,
                        ageLabel: _ageLabel(context, ref, babyId),
                      );
                      if (picked != null) {
                        update(
                          draft.copyWith(
                            goals: picked,
                            goalsSource: GoalsSource.chosen,
                            bandApplied: band,
                          ),
                        );
                      }
                    },
                    semanticLabel: l10n.axGoalsEdit,
                    child: _Chip(
                      label: l10n.axGoalsEdit,
                      tinted: false,
                      icon: ClIcons.edit,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (ranked.where((w) => w.id == WidgetId.careDuty).firstOrNull
                case final duty?) ...[
              _Label(l10n.hhHeaderSection),
              _Group(
                child: Row(
                  children: [
                    const SizedBox(width: ClSpace.s4),
                    Expanded(
                      child: Text(l10n.axWidgetCareDuty, style: cl.text.body),
                    ),
                    ClToggle(
                      key: const Key('hhDutyVisibility'),
                      value: duty.visible,
                      semanticLabel: l10n.axWidgetCareDuty,
                      onChanged: (v) => setVisible(WidgetId.careDuty, v),
                    ),
                    const SizedBox(width: ClSpace.s4),
                  ],
                ),
              ),
              const SizedBox(height: ClSpace.s6),
            ],
            _Label(l10n.axShowing),
            // Long press anywhere on a row, or drag the handle (owner, 2026-10-24: hard to drag).
            AxReorderGroup<RankedWidget>(
              key: const Key('axShowing'),
              header: [
                for (final w in showing.where((w) => w.pinned))
                  row(w, on: true),
              ],
              items: movable,
              row: (w, i, handle) => row(w, on: true, handle: handle),
              onReorder: (from, to) {
                final ids = [for (final w in movable) w.id];
                ids.insert(to, ids.removeAt(from));
                update(
                  draft.copyWith(order: [...ids, for (final w in hidden) w.id]),
                );
              },
            ),
            if (hidden.isNotEmpty) ...[
              const SizedBox(height: 20),
              _Label(l10n.axHiddenLabel),
              _Group(
                key: const Key('axHidden'),
                child: Column(
                  children: [for (final w in hidden) row(w, on: false)],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ClPressable(
              key: const Key('axRestore'),
              onPressed: () => update(applyBand(draft, band, restore: true)),
              semanticLabel: l10n.axRestore(name),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Text(
                    l10n.axRestore(name),
                    textAlign: TextAlign.center,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "2 tháng" / "4 tuổi" for "Gợi ý cho …", from the child's date of birth when readable.
String _ageLabel(BuildContext context, WidgetRef ref, String babyId) {
  final l10n = AppLocalizations.of(context);
  final dob = ref.read(babyPrivateProfileProvider(babyId)).value?.dateOfBirth;
  if (dob == null) return '';
  return ageShort(
    l10n,
    dob,
    ref.read(careClockProvider).value ?? DateTime.now(),
  );
}

/// AX03 / AX04 "Bạn muốn Child Life giúp gì cho {tên}?" as a sheet (the AX14 "Sửa" chip and
/// Hồ sơ › bé, G-110). Presets first with "Gợi ý cho {tuổi}"; returns null when closed.
Future<List<Goal>?> showGoalsSheet(
  BuildContext context, {
  required String name,
  required AgeBand band,
  required List<Goal> selected,
  required String ageLabel,
}) => Navigator.of(context, rootNavigator: true).push<List<Goal>>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AxGoalsScreen(
      name: name,
      band: band,
      selected: selected,
      ageLabel: ageLabel,
    ),
  ),
);

class AxGoalsScreen extends StatefulWidget {
  const AxGoalsScreen({
    required this.name,
    required this.band,
    required this.selected,
    required this.ageLabel,
    this.onDone,
    this.doneLabel,
    super.key,
  });

  final String name;
  final AgeBand band;
  final List<Goal> selected;
  final String ageLabel;

  /// Onboarding (AX03/AX04) passes its own "Tiếp tục"; null pops the choice.
  final ValueChanged<List<Goal>>? onDone;
  final String? doneLabel;

  @override
  State<AxGoalsScreen> createState() => _AxGoalsScreenState();
}

class _AxGoalsScreenState extends State<AxGoalsScreen> {
  late final Set<Goal> _picked = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final preset = presetGoals[widget.band]!;
    void done() {
      final goals = [
        for (final g in Goal.values)
          if (_picked.contains(g)) g,
      ];
      if (widget.onDone != null) {
        widget.onDone!(goals);
      } else {
        Navigator.of(context).pop(goals);
      }
    }

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  ClSpace.s4,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClPressable(
                      onPressed: () => Navigator.of(context).maybePop(),
                      semanticLabel: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      child: Container(
                        padding: const EdgeInsets.all(ClSpace.s2),
                        decoration: BoxDecoration(
                          color: cl.colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ClIcon(
                          ClIcons.back,
                          size: 20,
                          color: cl.colors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Text(
                    l10n.axGoalsTitle(widget.name),
                    style: cl.text.largeTitle.copyWith(
                      fontSize: 26,
                      color: cl.colors.ink,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s1),
                  Text(
                    l10n.axGoalsSub,
                    style: cl.text.body.copyWith(
                      fontSize: 13,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  for (final g in goalOrder(widget.band)) ...[
                    AxGoalRow(
                      goal: g,
                      selected: _picked.contains(g),
                      badge: preset.contains(g) && widget.ageLabel.isNotEmpty
                          ? l10n.axGoalsSuggested(widget.ageLabel)
                          : null,
                      onTap: () => setState(
                        () => _picked.contains(g)
                            ? _picked.remove(g)
                            : _picked.add(g),
                      ),
                    ),
                    const SizedBox(height: ClSpace.s2),
                  ],
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.axGoalsChosen(_picked.length),
                    textAlign: TextAlign.center,
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s3,
                ClSpace.s4,
                ClSpace.s4,
              ),
              child: ClButton(
                key: const Key('axGoalsDone'),
                label: widget.doneLabel ?? l10n.axDone,
                expand: true,
                onPressed: done,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AxGoalRow extends StatelessWidget {
  const AxGoalRow({
    required this.goal,
    required this.selected,
    required this.onTap,
    this.badge,
    super.key,
  });

  final Goal goal;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final title = goalLabel(l10n, goal);
    return Semantics(
      checked: selected,
      child: ClPressable(
        key: ValueKey('goal_${goal.wire}'),
        onPressed: onTap,
        semanticLabel: title,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cl.colors.mintDeep : cl.colors.separator,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.sunshineSoft,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          badge!,
                          style: cl.text.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            // Ink on the soft warm fill (Night care).
                            color: cl.colors.ink,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: cl.text.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cl.colors.ink,
                      ),
                    ),
                    Text(
                      goalSub(l10n, goal),
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? cl.colors.mintDeep : null,
                  borderRadius: BorderRadius.circular(7),
                  border: selected
                      ? null
                      : Border.all(color: cl.colors.separator, width: 1.5),
                ),
                child: selected
                    ? ClIcon(
                        ClIcons.check,
                        size: 14,
                        color: cl.colors.onMintDeep,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cl.colors.inkMuted,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cl.shadows.card,
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tinted, this.icon});
  final String label;
  final bool tinted;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = tinted ? cl.colors.mintText : cl.colors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tinted ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 12, color: ink),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: cl.text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// AX12 / AX13 "Chi tiêu tháng này": the month's total, a stacked bar by category (the
/// categories' own accents) and its legend, "Thêm"; empty month: AX42 "Chi tiêu cho {tên}" with
/// "Ghi khoản chi đầu tiên". Only for who sees all spending (as today's card).
class AxSpending extends ConsumerWidget {
  const AxSpending({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null || !scope.access.viewAll) return const SizedBox.shrink();
    final locale = spLocale(context);
    final s = MonthSummary.of(
      scope.expenses,
      monthOf(scope.today),
      scope.today,
      currency: scope.currency,
    );
    void add() => showExpenseSheet(context, scope: scope);
    final name = scope.baby?.nickname ?? '';
    if (s.items.isEmpty) {
      return AxCard(
        key: const Key('axSpending'),
        icon: ClIcons.drop,
        chip: cl.colors.mintSoft,
        title: l10n.axSpendFor(name),
        subtitle: l10n.axSpendNone,
        child: scope.access.record
            ? ClButton(
                label: l10n.axSpendFirst,
                style: ClButtonStyle.tinted,
                expand: true,
                onPressed: add,
              )
            : null,
      );
    }
    final month = toBeginningOfSentenceCase(
      DateFormat.MMMM(locale).format(DateTime(s.month.year, s.month.month)),
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
    return AxCard(
      key: const Key('axSpending'),
      icon: ClIcons.drop,
      chip: cl.colors.mintSoft,
      title: l10n.axWidgetSpending,
      subtitle: l10n.axSpendSub(month, s.items.length),
      link: scope.access.record ? l10n.axSpendAdd : null,
      onLink: scope.access.record ? add : null,
      child: ClPressable(
        onPressed: () => context.push(Routes.spending),
        semanticLabel: money(locale, s.total, scope.currency),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              money(locale, s.total, scope.currency),
              style: cl.text.title2.copyWith(color: cl.colors.ink),
            ),
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
                for (final p in shown) categoryName(l10n, p.category),
                if (rest > 0) l10n.spCatOther,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
