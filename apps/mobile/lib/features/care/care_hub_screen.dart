import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart' show SafePushContext;
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import '../library/content_repository.dart';
import '../library/library_routes.dart';
import '../me/me_widgets.dart';
import '../nutrition/nutrition_routes.dart';
import '../nutrition/nutrition_format.dart' show nuAgeLabel;
import '../nutrition/nutrition_state.dart';
import '../premium/premium_repository.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/rule_repository.dart';
import '../solids/solids_format.dart' show sdTileLine;
import '../solids/solids_routes.dart';
import '../solids/solids_state.dart';
import '../utilities/utilities_screen.dart' show CareSoonBadge;
import '../vaccines/vaccine_format.dart';
import 'care_repository.dart';
import 'history_screen.dart' show HistoryFilter;

/// Chăm sóc tab (v1.0 improvement 450:6424; caregiver 370:2174), grouped as the owner asked
/// (2026-10-14, D-069): "Chăm hằng ngày" (Nhắc nhở · Tiêm chủng · Thống kê · Lịch sử · Tăng
/// trưởng · Dinh dưỡng, D-083 · Ăn dặm, D-085), "Hiểu con & phát triển" (Wonder Weeks · Giai đoạn
/// của bé · Mốc phát triển) and "Kiến thức chăm bé" (Thư viện chăm bé). "Ăn dặm" is a live tile
/// again (P-164 #1; the P-163 #11 teaser is gone): 5a before tracking, 5b after. Sơ cứu and Chi
/// tiêu are in Tiện ích. Caregivers see no Tăng trưởng tile. No "Cài đặt" section (owner, 2026-10-11): Tuỳ chỉnh lives on Hôm nay, Thông báo in Tôi.
class CareHubScreen extends ConsumerStatefulWidget {
  const CareHubScreen({super.key});

  @override
  ConsumerState<CareHubScreen> createState() => _CareHubScreenState();
}

class _CareHubScreenState extends ConsumerState<CareHubScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String title, String subtitle) =>
      _query.isEmpty ||
      title.toLowerCase().contains(_query) ||
      subtitle.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final caregiver = me.role == MemberRole.caregiver;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final reminders = ref.watch(remindersProvider(me.babyId)).value ?? const [];
    final upcoming = reminders.where((r) => !r.done && r.dueAt.isAfter(now));
    // Rule reminders that are on (v1.0 1a) plus the one-time ones still ahead.
    final rules =
        (ref.watch(reminderRulesProvider(me.babyId)).value ?? const []).where(
          (r) => r.enabled,
        );
    // 370:2174: a caregiver sees the reminders assigned to them: on their device, or (D-075 #5)
    // assigned to them.
    final remindersLine = caregiver
        ? l10n.careRemindersMine(
            rules.where((r) => r.recipients.contains(me.uid)).length +
                upcoming
                    .where(
                      (r) =>
                          r.notifyDevice?.uid == me.uid ||
                          r.assigneeUid == me.uid,
                    )
                    .length,
          )
        : l10n.careRemindersOn(rules.length + upcoming.length);

    void soon() => showClToast(context, message: l10n.careSoonToast);
    // Dinh dưỡng (9a, D-083): live once a published stage covers the baby's age, "Cần ngày sinh
    // của bé" without a date of birth, a "Sớm ra mắt" teaser otherwise (P-163 #11).
    final nutrition = ref.watch(nuTileProvider);
    final daily = [
      _Tile(
        icon: ClIcons.clock,
        tint: cl.colors.mintSoft,
        title: l10n.careReminders,
        subtitle: remindersLine,
        onTap: () => context.push(Routes.reminders),
      ),
      // Sổ tiêm chủng (394:4451, caregivers too 394:4461): the next shot, or what needs doing.
      _Tile(
        icon: ClIcons.heart,
        tint: cl.colors.peachSoft,
        title: l10n.vxTile,
        subtitle: switch (ref.watch(vaccineBookProvider(me))) {
          VaccineBookReady(:final book) when book.overdue.isNotEmpty =>
            l10n.vxTileOverdue(book.overdue.length),
          VaccineBookReady(:final book)
              when !book.plan.setupDone &&
                  me.role == MemberRole.coParent &&
                  book.dueSoFar.isNotEmpty =>
            l10n.vxTileSetup,
          VaccineBookReady(:final book) => switch (book.nextGroup) {
            final g? => l10n.vxTileNext(vxDay(g.date)),
            null => l10n.vxTileAllDone,
          },
          _ => l10n.vxTileBook,
        },
        onTap: () => context.push(Routes.vaccines),
      ),
      _Tile(
        icon: ClIcons.sliders,
        tint: cl.care.sleep.soft,
        title: l10n.careStats,
        subtitle: l10n.careStatsSub,
        onTap: () => _showStatsPicker(context),
      ),
      _Tile(
        icon: ClIcons.journal,
        tint: cl.care.diaper.soft,
        title: l10n.careHistory,
        subtitle: l10n.careHistorySub,
        onTap: () => context.push(Routes.history),
      ),
      if (!caregiver)
        _Tile(
          icon: ClIcons.ruler,
          tint: cl.care.growth.soft,
          title: l10n.careGrowth,
          subtitle: l10n.careGrowthSub,
          onTap: () => context.push(
            '${Routes.history}?filter=${HistoryFilter.growth.name}',
          ),
        ),
      _Tile(
        key: const Key('careNutrition'),
        icon: ClIcons.feed,
        tint: cl.care.bottle.soft,
        title: l10n.careNutrition,
        subtitle: switch (nutrition) {
          NuTileLive(:final stage) => l10n.careNutritionStage(
            nuAgeLabel(l10n, stage.age),
          ),
          NuTileNoDob() => l10n.careNutritionNoDob,
          NuTileTeaser() => l10n.careNutritionSub,
        },
        soon: nutrition is NuTileTeaser,
        onTap: nutrition is NuTileTeaser
            ? soon
            : () => context.push(NuRoutes.home),
      ),
      // Ăn dặm (D-085, plan §5): "Từ 6 tháng" · "Sắp đến lúc ăn dặm" · "Bắt đầu theo dõi" ·
      // "Hôm nay · N bữa"; the age as Dinh dưỡng reads it (caregivers: the vaccine plan, P-133).
      _Tile(
        key: const Key('careSolids'),
        icon: ClIcons.feed,
        tint: cl.colors.sunshineSoft,
        title: l10n.careSolids,
        subtitle: sdTileLine(
          l10n,
          ref.watch(sdStateProvider),
          ref.watch(sdTodayProvider),
        ),
        onTap: () => context.push(SdRoutes.home),
      ),
    ].where((t) => _matches(t.title, t.subtitle)).toList();

    // 450:6424: drawn like the live tiles, each with its own chip; only the badge marks them.
    List<_Tile> teasers(List<(ClIcons, Color, String, String)> items) => [
      for (final (icon, tint, title, subtitle) in items)
        if (_matches(title, subtitle))
          _Tile(
            icon: icon,
            tint: tint,
            title: title,
            subtitle: subtitle,
            soon: true,
            onTap: soon,
          ),
    ];
    // Nhịp lớn lên (plan §7.1): the "Wonder Weeks" tile opens NL01 once the family's `rhythm`
    // flag is on; until then it stays a teaser.
    final rhythm =
        ref.watch(selectedCapabilitiesProvider)?.features.rhythm ?? false;
    // Giai đoạn của bé and Thư viện chăm bé (D-076 #5, #7) open once something is published for
    // this member; until then they stay teasers.
    final stagesLive = (ref.watch(lbStagesProvider).value?.items ?? const [])
        .any((s) => s.audience.contains(me.role));
    final libraryLive = (ref.watch(lbArticlesProvider).value?.items ?? const [])
        .isNotEmpty;
    final develop = [
      if (rhythm && _matches(l10n.careWonderWeek, l10n.careWonderWeekSub))
        _Tile(
          icon: ClIcons.spark,
          tint: cl.care.sleep.soft,
          title: l10n.careWonderWeek,
          subtitle: l10n.careWonderWeekSub,
          onTap: () => context.push(Routes.rhythm),
        ),
      if (stagesLive && _matches(l10n.careAgeCards, l10n.careAgeCardsSub))
        _Tile(
          key: const Key('careStages'),
          icon: ClIcons.cake,
          tint: cl.colors.sunshineSoft,
          title: l10n.careAgeCards,
          subtitle: l10n.careAgeCardsSub,
          onTap: () => context.push(LbRoutes.stages),
        ),
      // D-076 nav: Mốc phát triển (D-076 #6) is always live: the family's own milestones work
      // without any published guide. It is a Tiện ích page, opened with `pushSafe`.
      if (_matches(l10n.careMilestones, l10n.careMilestonesSub))
        _Tile(
          key: const Key('careMilestones'),
          icon: ClIcons.star,
          tint: cl.colors.peachSoft,
          title: l10n.careMilestones,
          subtitle: l10n.careMilestonesSub,
          onTap: () => context.pushSafe(Routes.milestones),
        ),
      ...teasers([
        if (!rhythm)
          (
            ClIcons.spark,
            cl.care.sleep.soft,
            l10n.careWonderWeek,
            l10n.careWonderWeekSub,
          ),
        if (!stagesLive)
          (
            ClIcons.cake,
            cl.colors.sunshineSoft,
            l10n.careAgeCards,
            l10n.careAgeCardsSub,
          ),
      ]),
    ];
    final knowledge = [
      if (libraryLive && _matches(l10n.careLibrary, l10n.careLibrarySub))
        _Tile(
          key: const Key('careLibrary'),
          icon: ClIcons.bookmark,
          tint: cl.colors.mintSoft,
          title: l10n.careLibrary,
          subtitle: l10n.careLibrarySub,
          onTap: () => context.push(LbRoutes.library),
        ),
      ...teasers([
        if (!libraryLive)
          (
            ClIcons.bookmark,
            cl.colors.mintSoft,
            l10n.careLibrary,
            l10n.careLibrarySub,
          ),
      ]),
    ];

    final nothing = daily.isEmpty && develop.isEmpty && knowledge.isEmpty;
    // Like Hôm nay: the baby header stays, with no collapsed title over it (it overlapped).
    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          ClTabDock.contentBottomPadding + ClSpace.s6,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.careTitle, style: cl.text.largeTitle),
          ),
          const SizedBox(height: ClSpace.s3),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            style: cl.text.body,
            decoration: InputDecoration(
              hintText: l10n.careSearchHint,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: ClIcon(
                  ClIcons.search,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ),
              filled: true,
              fillColor: cl.colors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cl.colors.controlBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cl.colors.controlBorder),
              ),
            ),
          ),
          if (nothing) ...[
            const SizedBox(height: ClSpace.s6),
            Text(
              l10n.careNoResults,
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          if (daily.isNotEmpty) ...[_Section(l10n.careDaily), _Grid(daily)],
          if (develop.isNotEmpty) ...[
            _Section(l10n.careDevelop),
            _Grid(develop),
          ],
          if (knowledge.isNotEmpty) ...[
            _Section(l10n.careKnowledge),
            _Grid(knowledge),
          ],
        ],
      ),
    );
  }
}

/// "Thống kê" lands on a choice of feeding or sleep statistics (where it lands is not designed).
Future<void> _showStatsPicker(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    void go(String route) {
      Navigator.of(sheet).pop();
      context.push(route);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.careStatsPick),
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.feed,
              title: l10n.feedStatsTitle,
              onTap: () => go(Routes.feedStats),
            ),
            MeRow(
              icon: ClIcons.sleep,
              title: l10n.sleepStatsTitle,
              onTap: () => go(Routes.sleepStats),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  },
);

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
    child: Semantics(
      header: true,
      child: Text(title, style: context.cl.text.headline),
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid(this.tiles);
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: ClSpace.s3));
    }
    return Column(children: rows);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
    super.key,
  });

  final ClIcons icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: soon ? '$title. ${l10n.careSoon}' : '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClIcon(icon, size: 18, color: cl.colors.ink),
                ),
                const Spacer(),
                if (soon) const CareSoonBadge(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: cl.text.caption.copyWith(
                color: cl.colors.inkMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
