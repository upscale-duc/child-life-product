import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_entry.dart' show assistantAccessProvider;
import '../assistant/assistant_models.dart' show AssistantScope;
import '../assistant/assistant_screens.dart' show openAssistant;
import '../auto_save/auto_save_widgets.dart' show autoSaveAvailableProvider;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../first_aid/first_aid_repository.dart' show firstAidPackProvider;
import '../home/home_shell.dart';
import '../keepsakes/keepsake_access.dart';
import '../care/care_hub_screen.dart' show careHubSections;
import '../memories/memories_screen.dart' show memoryCtx;
import '../memories/memory_sheets.dart' show showAddSheet;
import '../spending/spending_calc.dart' show foldVietnamese;
import '../spending/spending_models.dart' show SpendingAccess;
import '../vaccines/vaccine_format.dart'
    show VaccineBookReady, vaccineBookProvider;
import 'adaptive_engine.dart';
import 'adaptive_signals.dart' show reportAdaptive;
import 'experience_repository.dart';

/// Khám phá (AX20 / AX21 / AX45, P-178): every V1 feature this person can open, the same list at
/// every age; only the top "Gợi ý cho {tên} lúc này", the subtitles and the search examples follow
/// the child's band (AX00 "Khám phá · Gợi ý cho bé"). Nothing unbuilt is listed as a feature:
/// future stages are the dashed "Cùng con lớn lên" card only (AX00 rule 2).

enum ExploreItem {
  care,
  stats,
  growth,
  vaccines,
  memories,
  keepsakes,
  autoSave,
  spending,
  reminders,
  family,
  carePlan,
  lumi,
  firstAid,
  milestones,
  allCare,
}

enum _Group { lifelong, health, familyAssistant, care, understand }

const _groupOf = <ExploreItem, _Group>{
  ExploreItem.memories: _Group.lifelong,
  ExploreItem.keepsakes: _Group.lifelong,
  ExploreItem.autoSave: _Group.lifelong,
  ExploreItem.spending: _Group.lifelong,
  ExploreItem.reminders: _Group.lifelong,
  ExploreItem.growth: _Group.health,
  ExploreItem.vaccines: _Group.health,
  ExploreItem.firstAid: _Group.health,
  ExploreItem.family: _Group.familyAssistant,
  ExploreItem.carePlan: _Group.familyAssistant,
  ExploreItem.lumi: _Group.familyAssistant,
  ExploreItem.care: _Group.care,
  ExploreItem.stats: _Group.care,
  ExploreItem.milestones: _Group.understand,
  ExploreItem.allCare: _Group.understand,
};

/// AX00 "Khám phá · Gợi ý cho bé" per band.
const exploreSuggestions = <AgeBand, List<ExploreItem>>{
  AgeBand.b0_1: [
    ExploreItem.care,
    ExploreItem.stats,
    ExploreItem.growth,
    ExploreItem.vaccines,
  ],
  AgeBand.b1_3: [
    ExploreItem.memories,
    ExploreItem.care,
    ExploreItem.vaccines,
    ExploreItem.growth,
  ],
  AgeBand.b3_6: [
    ExploreItem.memories,
    ExploreItem.keepsakes,
    ExploreItem.spending,
    ExploreItem.reminders,
  ],
  AgeBand.b6_12: [
    ExploreItem.memories,
    ExploreItem.reminders,
    ExploreItem.spending,
    ExploreItem.growth,
  ],
};

/// What [me] can open, by role, flags and data (the same gates as Chăm sóc / Tiện ích).
final exploreAvailableProvider = Provider<Set<ExploreItem>>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return const {};
  final parent = me.role == MemberRole.coParent;
  final caregiver = me.role == MemberRole.caregiver;
  final relative = me.role == MemberRole.relative;
  final careView = !relative || me.canViewToday;
  final keepsakes = ref.watch(selectedKeepsakeAccessProvider);
  final spending = SpendingAccess.of(me);
  return {
    if (careView) ...{ExploreItem.care, ExploreItem.stats},
    if (!caregiver) ExploreItem.growth,
    if (!relative) ExploreItem.vaccines,
    if (!caregiver) ExploreItem.memories,
    if (parent && (keepsakes.cards || keepsakes.videos)) ExploreItem.keepsakes,
    if (parent && ref.watch(autoSaveAvailableProvider)) ExploreItem.autoSave,
    if (spending.viewAll || spending.record) ExploreItem.spending,
    if (!relative) ExploreItem.reminders,
    ExploreItem.family,
    // Cùng Chăm Con (D-135): whoever reads care reads the plan.
    if (careView) ExploreItem.carePlan,
    if (ref.watch(assistantAccessProvider(me.babyId)) != null) ExploreItem.lumi,
    if (ref.watch(firstAidPackProvider).value != null) ExploreItem.firstAid,
    ExploreItem.milestones,
    if (careView) ExploreItem.allCare,
  };
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final band =
        ref.watch(childBandProvider(me.babyId)) ??
        ref.watch(experienceProvider(me.babyId)).bandApplied;
    final older = band.index >= AgeBand.b3_6.index;
    final available = ref.watch(exploreAvailableProvider);
    final pack = ref.watch(firstAidPackProvider).value;

    (ClIcons, Color, String, String) look(ExploreItem i) => switch (i) {
      ExploreItem.care => (
        ClIcons.feed,
        cl.care.bottle.soft,
        l10n.exCare,
        l10n.exCareSub,
      ),
      ExploreItem.stats => (
        ClIcons.grid,
        cl.care.sleep.soft,
        l10n.exStats,
        l10n.exStatsSub,
      ),
      ExploreItem.growth => (
        ClIcons.ruler,
        cl.care.growth.soft,
        l10n.axGrowthTitle,
        l10n.exGrowthSub,
      ),
      // Like the Chăm sóc tile: what the book needs (a child added later has shots to tick,
      // or overdue ones) before the reference line.
      ExploreItem.vaccines => (
        ClIcons.heart,
        cl.colors.sunshineSoft,
        l10n.axChipVaccines,
        switch (ref.watch(vaccineBookProvider(me))) {
          VaccineBookReady(:final book) when book.overdue.isNotEmpty =>
            l10n.vxTileOverdue(book.overdue.length),
          VaccineBookReady(:final book)
              when !book.plan.setupDone &&
                  me.role == MemberRole.coParent &&
                  book.dueSoFar.isNotEmpty =>
            l10n.vxTileSetup,
          _ =>
            band == AgeBand.b0_1 ? l10n.exVaccinesSub : l10n.exVaccinesSubOlder,
        },
      ),
      ExploreItem.memories => (
        ClIcons.memories,
        cl.colors.peachSoft,
        l10n.exMemories,
        l10n.exMemoriesSub,
      ),
      ExploreItem.keepsakes => (
        ClIcons.spark,
        cl.colors.peachSoft,
        l10n.exKeepsakes,
        older ? l10n.exKeepsakesSubOlder : l10n.exKeepsakesSub,
      ),
      ExploreItem.autoSave => (
        ClIcons.camera,
        cl.colors.mintSoft,
        l10n.exAutoSave,
        l10n.exAutoSaveSub(name),
      ),
      ExploreItem.spending => (
        ClIcons.drop,
        cl.colors.mintSoft,
        l10n.exSpending,
        older ? l10n.exSpendingSubOlder : l10n.exSpendingSub,
      ),
      ExploreItem.reminders => (
        ClIcons.clock,
        cl.colors.sunshineSoft,
        l10n.axWidgetReminders,
        older ? l10n.exRemindersSubOlder : l10n.exRemindersSub,
      ),
      ExploreItem.family => (
        ClIcons.family,
        cl.colors.mintSoft,
        l10n.exFamily,
        older ? l10n.exFamilySubOlder : l10n.exFamilySub,
      ),
      ExploreItem.carePlan => (
        ClIcons.calendar,
        cl.colors.sunshineSoft,
        l10n.cpTitle,
        l10n.cpExploreSub,
      ),
      ExploreItem.lumi => (
        // brandMark is a filled mark: as a line icon it drew an empty square (owner, 2026-10-24).
        ClIcons.spark,
        cl.colors.mintSoft,
        l10n.exLumi,
        older ? l10n.exLumiSubOlder(name) : l10n.exLumiSub,
      ),
      ExploreItem.firstAid => (
        ClIcons.alert,
        cl.colors.errorSoft,
        l10n.exFirstAid,
        l10n.faEntrySub(pack?.situations.length ?? 0),
      ),
      ExploreItem.milestones => (
        ClIcons.star,
        cl.care.growth.soft,
        l10n.mtTitle,
        l10n.careMilestonesSub,
      ),
      ExploreItem.allCare => (
        ClIcons.care,
        cl.colors.surface2,
        l10n.exAllCare,
        l10n.exAllCareSub,
      ),
    };

    void open(ExploreItem i) {
      switch (i) {
        case ExploreItem.care:
          context.push(Routes.care);
        case ExploreItem.stats:
          context.push(Routes.history);
        case ExploreItem.growth:
          context.push(Routes.growth);
        case ExploreItem.vaccines:
          context.push(Routes.vaccines);
        case ExploreItem.memories:
          context.go(Routes.memories);
        case ExploreItem.keepsakes:
          final access = ref.read(selectedKeepsakeAccessProvider);
          context.push(
            access.videos ? Routes.memoryStory : Routes.milestoneCard,
          );
        case ExploreItem.autoSave:
          context.push(Routes.autoSave);
        case ExploreItem.spending:
          context.push(Routes.spending);
        case ExploreItem.reminders:
          context.push(Routes.reminders);
        case ExploreItem.family:
          context.push(Routes.family);
        case ExploreItem.carePlan:
          context.push(Routes.carePlan);
        case ExploreItem.lumi:
          openAssistant(context, AssistantScope.child(me.babyId));
        case ExploreItem.firstAid:
          context.push(Routes.firstAid);
        case ExploreItem.milestones:
          context.push(Routes.milestones);
        case ExploreItem.allCare:
          context.push(Routes.care);
      }
    }

    Widget row(ExploreItem i) {
      final (icon, chip, title, sub) = look(i);
      return ClPressable(
        key: ValueKey('explore_${i.name}'),
        onPressed: () => open(i),
        semanticLabel: '$title, $sub',
        // One row style with the Chăm sóc rows now on the same screen (D-139).
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s2,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                child: ClIcon(icon, size: 18, color: cl.colors.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: cl.text.body),
                    Text(
                      sub,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ],
                ),
              ),
              if (i == ExploreItem.autoSave) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.sunshine,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.exBeta,
                    style: cl.text.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.onWarm,
                    ),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
              ],
              ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
            ],
          ),
        ),
      );
    }

    // Search: titles and subtitles, without Vietnamese marks ("tiem" finds "Tiêm chủng").
    final q = foldVietnamese(_query);
    bool matches(ExploreItem i) {
      final (_, _, title, sub) = look(i);
      return foldVietnamese('$title $sub').contains(q);
    }

    // Khám phá and Chăm sóc are one screen (owner, 2026-10-30: "gộp hai màn hình này thành 1 ở
    // tabbar", D-139): for whoever reads care, the Chăm sóc tiles (live counts) sit inline and
    // the rows they cover are not listed twice.
    final careInline = available.contains(ExploreItem.allCare);
    const covered = {
      ExploreItem.care,
      ExploreItem.stats,
      ExploreItem.growth,
      ExploreItem.vaccines,
      ExploreItem.reminders,
      ExploreItem.milestones,
      ExploreItem.allCare,
    };
    final listed = [
      for (final i in ExploreItem.values)
        if (available.contains(i) && !(careInline && covered.contains(i))) i,
    ];
    final careSections = careInline
        ? careHubSections(context, ref, me, _query)
        : const <Widget>[];
    final children = <Widget>[];
    void group(String title, List<ExploreItem> items, {Key? key}) {
      if (items.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
          child: Semantics(
            header: true,
            child: Text(title, style: cl.text.headline),
          ),
        ),
      );
      children.add(
        ClCardGroup(key: key, children: [for (final i in items) row(i)]),
      );
    }

    if (_query.isNotEmpty) {
      final found = listed.where(matches).toList();
      if (found.isEmpty && careSections.isEmpty) {
        children.add(_NoResult(query: _query, name: name));
      } else {
        children.addAll(careSections);
        if (found.isNotEmpty) {
          children
            ..add(const SizedBox(height: ClSpace.s4))
            ..add(ClCardGroup(children: [for (final i in found) row(i)]));
        }
      }
    } else {
      final suggested = [
        for (final i in exploreSuggestions[band]!)
          if (listed.contains(i)) i,
      ];
      group(
        l10n.exForChild(name),
        suggested,
        key: const Key('exploreSuggested'),
      );
      children.addAll(careSections);
      List<ExploreItem> rest(_Group g) => [
        for (final i in listed)
          if (_groupOf[i] == g && !suggested.contains(i)) i,
      ];
      group(l10n.exLifelong, rest(_Group.lifelong));
      group(l10n.exHealth, rest(_Group.health));
      group(l10n.exFamilyAssistant, rest(_Group.familyAssistant));
      group(l10n.exCareTools, rest(_Group.care));
      group(l10n.exUnderstand, rest(_Group.understand));
      children.add(_GrowingCard(name: name));
    }

    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          switch (HomeFloatingClearance.of(context)) {
            final c? => c + ClSpace.s4,
            null => ClTabDock.contentBottomPadding + ClSpace.s6,
          },
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.tabExplore,
              style: cl.text.largeTitle.copyWith(color: cl.colors.ink),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          TextField(
            key: const Key('exploreSearch'),
            controller: _search,
            textInputAction: TextInputAction.search,
            style: cl.text.body,
            decoration: InputDecoration(
              hintText: older ? l10n.exSearchOlder : l10n.exSearch01,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: ClIcon(
                  ClIcons.search,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      onPressed: _search.clear,
                      icon: ClIcon(
                        ClIcons.close,
                        size: 16,
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
          ...children,
        ],
      ),
    );
  }
}

/// "Báo tôi khi có" (AX20, AX45): kept on this phone per person; no push or e-mail is promised
/// (AX45 note). The MET-01 event follows with phase E.
final exploreInterestProvider = NotifierProvider<ExploreInterest, bool>(
  ExploreInterest.new,
);

class ExploreInterest extends Notifier<bool> {
  String? get _key {
    final me = ref.read(selectedMembershipProvider);
    return me == null ? null : 'explore.interest.${me.uid}';
  }

  @override
  bool build() {
    ref.watch(selectedMembershipProvider);
    try {
      final key = _key;
      return key != null &&
          (ref.read(sharedPreferencesProvider).getBool(key) ?? false);
    } on Object {
      return false;
    }
  }

  void register() {
    state = true;
    try {
      final key = _key;
      if (key != null) {
        ref.read(sharedPreferencesProvider).setBool(key, true).ignore();
      }
    } on Object {
      // No preferences (tests).
    }
  }
}

class _NotifyButton extends ConsumerWidget {
  const _NotifyButton({this.link = false});
  final bool link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final done = ref.watch(exploreInterestProvider);
    void tap() {
      ref.read(exploreInterestProvider.notifier).register();
      reportAdaptive(
        ref,
        context,
        'adaptive_interest',
        link ? 'search' : 'card',
      );
      showClToast(context, message: l10n.exNotifiedToast);
    }

    if (link) {
      return ClPressable(
        key: const Key('exploreNotify'),
        onPressed: done ? null : tap,
        semanticLabel: done ? l10n.exNotified : l10n.exNotify,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text(
              done ? l10n.exNotified : l10n.exNotify,
              style: cl.text.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: done ? cl.colors.inkMuted : cl.colors.mintText,
              ),
            ),
          ),
        ),
      );
    }
    return ClButton(
      key: const Key('exploreNotify'),
      label: done ? l10n.exNotified : l10n.exNotify,
      style: ClButtonStyle.secondary,
      expand: true,
      onPressed: done ? null : tap,
    );
  }
}

/// AX20 "Cùng con lớn lên · Đang phát triển · chưa có trong app" (dashed, never a feature).
class _GrowingCard extends StatelessWidget {
  const _GrowingCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: CustomPaint(
        foregroundPainter: _DashedBorder(color: cl.colors.separator),
        child: Container(
          key: const Key('exploreGrowing'),
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ClSpace.s2),
                    decoration: BoxDecoration(
                      color: cl.colors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClIcon(ClIcons.star, size: 18, color: cl.colors.ink),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.exGrowTitle,
                          style: cl.text.bodyStrong.copyWith(
                            fontSize: 16,
                            color: cl.colors.ink,
                          ),
                        ),
                        Text(
                          l10n.exGrowBadge,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              Text(
                l10n.exGrowBody(name),
                style: cl.text.caption.copyWith(
                  fontSize: 13,
                  color: cl.colors.ink,
                ),
              ),
              const SizedBox(height: ClSpace.s3),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in [
                    l10n.exBand13,
                    l10n.exBand36,
                    l10n.exBand612,
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cl.colors.surface2,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                      child: Text(
                        label,
                        style: cl.text.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cl.colors.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              const _NotifyButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(20),
        ).deflate(0.5),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// AX45: nothing matched; honest, with a route that works today (Kỷ niệm).
class _NoResult extends ConsumerWidget {
  const _NoResult({required this.query, required this.name});
  final String query;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    return Container(
      key: const Key('exploreNoResult'),
      margin: const EdgeInsets.only(top: ClSpace.s4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.exNoneTitle(query),
            textAlign: TextAlign.center,
            style: cl.text.bodyStrong.copyWith(
              fontSize: 17,
              color: cl.colors.ink,
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.exNoneBody(name),
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(
              fontSize: 13,
              color: cl.colors.inkMuted,
            ),
          ),
          if (me?.role == MemberRole.coParent) ...[
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.exSaveToMemories,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () {
                final c = memoryCtx(context, ref);
                if (c != null) showAddSheet(context, ref, c);
              },
            ),
          ],
          const _NotifyButton(link: true),
        ],
      ),
    );
  }
}
