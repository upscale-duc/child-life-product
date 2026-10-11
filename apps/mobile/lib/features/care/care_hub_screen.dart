import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../me/me_widgets.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/rule_repository.dart';
import '../vaccines/vaccine_format.dart';
import 'care_repository.dart';
import 'history_screen.dart' show HistoryFilter;

/// Chăm sóc tab (v1.0 improvement 370:1971; caregiver 370:2174): search, daily care (Nhắc nhở ·
/// Tiêm chủng · Thống kê · Lịch sử · Tăng trưởng) and the coming-soon teasers. Caregivers see no Tăng trưởng
/// tile. No "Cài đặt" section (owner, 2026-10-11): Tuỳ chỉnh lives on Hôm nay, Thông báo in Tôi.
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
    // 370:2174: a caregiver sees the reminders assigned to them.
    final remindersLine = caregiver
        ? l10n.careRemindersMine(
            rules.where((r) => r.recipients.contains(me.uid)).length +
                upcoming.where((r) => r.notifyDevice?.uid == me.uid).length,
          )
        : l10n.careRemindersOn(rules.length + upcoming.length);

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
    ].where((t) => _matches(t.title, t.subtitle)).toList();

    void soon() => showClToast(context, message: l10n.careSoonToast);
    final teasers = [
      for (final (title, subtitle) in [
        (l10n.careWonderWeek, l10n.careWonderWeekSub),
        (l10n.careAgeCards, l10n.careAgeCardsSub),
        (l10n.careMilestones, l10n.careMilestonesSub),
        (l10n.careLibrary, l10n.careLibrarySub),
        (l10n.careSolids, l10n.careSolidsSub),
      ])
        _Tile(
          icon: ClIcons.spark,
          tint: cl.colors.surface,
          title: title,
          subtitle: subtitle,
          soon: true,
          onTap: soon,
        ),
    ].where((t) => _matches(t.title, t.subtitle)).toList();

    final nothing = daily.isEmpty && teasers.isEmpty;
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
          if (teasers.isNotEmpty) ...[_Section(l10n.careSoon), _Grid(teasers)],
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
    final fade = soon ? 0.6 : 1.0;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: soon ? '$title. ${l10n.careSoon}' : '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: soon ? cl.colors.surface2 : cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: soon ? null : cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: soon ? 0.5 : 1,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: ClIcon(icon, size: 20, color: cl.colors.ink),
                  ),
                ),
                const Spacer(),
                if (soon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClSpace.s2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      l10n.careSoon,
                      style: cl.text.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Opacity(
              opacity: fade,
              child: Text(title, style: cl.text.bodyStrong),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: fade,
              child: Text(
                subtitle,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
