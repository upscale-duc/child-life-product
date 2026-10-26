// Care workflow v2 prototypes (D-112). Isolated from production. Layout comparison only: the
// values are the ones the care fixture produces on the current hub / manual-sleep screens
// (2 reminders on, 3 shots overdue, sleep 14:05–15:05), read through the real ARB strings.
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/features/care/care_format.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/me/me_widgets.dart';
import 'package:child_life/features/onboarding/widgets/onboarding_layout.dart';
import 'package:child_life/features/utilities/utilities_screen.dart' show CareSoonBadge;
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProtoCase {
  const ProtoCase(this.build, {this.height = 812, this.sleeping = false, this.quickLog = false});
  final Widget Function() build;
  final double height;
  final bool sleeping;
  final bool quickLog;
}

final prototypeCases = <String, ProtoCase>{
  'hub_A': ProtoCase(() => const Scaffold(body: _Hub(grid: true)), height: 1500),
  'hub_B': ProtoCase(() => const Scaffold(body: _Hub(grid: false)), height: 1500),
  'manual_A': ProtoCase(() => const _Manual(summaryFirst: true)),
  'manual_B': ProtoCase(() => const _Manual(summaryFirst: false)),
};

// ── Hub ────────────────────────────────────────────────────────────────────────────────────

class _Item {
  const _Item(this.icon, this.tint, this.title, {this.status, this.attention = false, this.soon = false, this.detail});
  final ClIcons icon;
  final Color tint;
  final String title;
  final String? status;
  final bool attention;
  final bool soon;
  final String? detail; // teaser description
}

class _Hub extends StatelessWidget {
  const _Hub({required this.grid});
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    // Direction B orders the daily section by how often a parent opens each item.
    final daily = [
      _Item(ClIcons.journal, cl.care.diaper.soft, l10n.careHistory),
      _Item(ClIcons.sliders, cl.care.sleep.soft, l10n.careStats, status: l10n.careStatsSub),
      _Item(ClIcons.clock, cl.colors.mintSoft, l10n.careReminders, status: l10n.careRemindersOn(2)),
      _Item(ClIcons.heart, cl.colors.peachSoft, l10n.vxTile, status: l10n.vxTileOverdue(3), attention: true),
      _Item(ClIcons.ruler, cl.care.growth.soft, l10n.careGrowth),
      _Item(ClIcons.feed, cl.colors.sunshineSoft, l10n.careSolids, status: l10n.sdTileFrom6),
      _Item(ClIcons.feed, cl.care.bottle.soft, l10n.careNutrition, detail: l10n.careNutritionSub, soon: true),
    ];
    final develop = [
      _Item(ClIcons.star, cl.colors.peachSoft, l10n.careMilestones, status: l10n.careMilestonesSub),
      _Item(ClIcons.spark, cl.care.sleep.soft, l10n.careWonderWeek, detail: l10n.careWonderWeekSub, soon: true),
      _Item(ClIcons.cake, cl.colors.sunshineSoft, l10n.careAgeCards, detail: l10n.careAgeCardsSub, soon: true),
    ];
    final knowledge = [
      _Item(ClIcons.bookmark, cl.colors.mintSoft, l10n.careLibrary, detail: l10n.careLibrarySub, soon: true),
    ];
    final sections = [(l10n.careDaily, daily), (l10n.careDevelop, develop), (l10n.careKnowledge, knowledge)];
    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s4, ClSpace.s8),
        children: [
          Text(l10n.careTitle, style: cl.text.largeTitle),
          const SizedBox(height: ClSpace.s3),
          _Search(hint: l10n.careSearchHint),
          if (grid)
            ..._gridDirection(context, sections)
          else
            ..._listDirection(context, sections),
        ],
      ),
    );
  }

  // A — refined grid: same sections, compact status-first tiles; teasers gathered at the end.
  List<Widget> _gridDirection(BuildContext context, List<(String, List<_Item>)> sections) {
    final l10n = AppLocalizations.of(context);
    final live = [for (final (t, items) in sections) (t, [for (final i in items) if (!i.soon) i])];
    final soon = [for (final (_, items) in sections) ...items.where((i) => i.soon)];
    return [
      for (final (title, items) in live)
        if (items.isNotEmpty) ...[
          _Heading(title),
          _TileGrid(items),
        ],
      _Heading(l10n.careSoon),
      _SoonRow(soon),
    ];
  }

  // B — grouped list: each section is one card of rows, status as the row's second line,
  // overdue as a warm pill, teasers last in their section, quieter.
  List<Widget> _listDirection(BuildContext context, List<(String, List<_Item>)> sections) => [
    for (final (title, items) in sections) ...[
      _Heading(title),
      ClCardGroup(
        shadow: true,
        children: [
          for (final i in [...items.where((i) => !i.soon), ...items.where((i) => i.soon)])
            _ListRow(i),
        ],
      ),
    ],
  ];
}

class _Search extends StatelessWidget {
  const _Search({required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(children: [
        ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
        const SizedBox(width: ClSpace.s3),
        Text(hint, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
      ]),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
    child: Text(title, style: context.cl.text.headline),
  );
}

Widget _iconChip(BuildContext context, _Item i, {double size = 36}) {
  final cl = context.cl;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: i.tint, borderRadius: BorderRadius.circular(ClRadius.control)),
    alignment: Alignment.center,
    child: ClIcon(i.icon, size: 18, color: cl.colors.ink),
  );
}

Widget _status(BuildContext context, _Item i) {
  final cl = context.cl;
  if (i.status == null) return const SizedBox.shrink();
  if (!i.attention) {
    return Text(i.status!, style: cl.text.label.copyWith(color: cl.colors.inkMuted));
  }
  return Container(
    margin: const EdgeInsets.only(top: ClSpace.s1),
    padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: ClSpace.s1),
    decoration: BoxDecoration(color: cl.colors.sunshineSoft, borderRadius: BorderRadius.circular(ClRadius.pill)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      ClIcon(ClIcons.alert, size: 14, color: cl.colors.ink),
      const SizedBox(width: ClSpace.s1),
      Flexible(child: Text(i.status!, style: cl.text.caption.copyWith(color: cl.colors.ink, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _TileGrid extends StatelessWidget {
  const _TileGrid(this.items);
  final List<_Item> items;
  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    Widget tile(_Item i) => ClPressable(
      onPressed: () {},
      semanticLabel: i.title,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(color: cl.colors.surface, borderRadius: BorderRadius.circular(ClRadius.card), boxShadow: cl.shadows.card),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _iconChip(context, i, size: 32),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.title, style: cl.text.bodyStrong),
              _status(context, i),
            ]),
          ),
        ]),
      ),
    );
    final rows = <Widget>[];
    for (var k = 0; k < items.length; k += 2) {
      if (k > 0) rows.add(const SizedBox(height: ClSpace.s3));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(items[k])),
          const SizedBox(width: ClSpace.s3),
          Expanded(child: k + 1 < items.length ? tile(items[k + 1]) : const SizedBox.shrink()),
        ]),
      ));
    }
    return Column(children: rows);
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow(this.items);
  final List<_Item> items;
  @override
  Widget build(BuildContext context) => ClCardGroup(
    children: [for (final i in items) _ListRow(i)],
  );
}

class _ListRow extends StatelessWidget {
  const _ListRow(this.i);
  final _Item i;
  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Opacity(
      opacity: i.soon ? 0.75 : 1,
      child: MeRow(
        leading: _iconChip(context, i),
        title: i.title,
        subtitle: i.attention ? null : (i.status ?? (i.soon ? i.detail : null)),
        trailing: i.soon
            ? const CareSoonBadge()
            : i.attention
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                _status(context, i),
                const SizedBox(width: ClSpace.s1),
                ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
              ])
            : null,
        onTap: () {},
      ),
    );
  }
}

// ── Manual sleep ───────────────────────────────────────────────────────────────────────────

class _Manual extends StatelessWidget {
  const _Manual({required this.summaryFirst});
  final bool summaryFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final care = cl.care.sleep;
    final today = l10n.todayLabel;
    final rows = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        child: ClTimeRow(icon: ClIcons.sleep, label: l10n.startLabel, value: '$today · 14:05', onTap: () {}),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        child: ClTimeRow(icon: ClIcons.sunrise, label: l10n.sleepEnd, value: '$today · 15:05', onTap: () {}),
      ),
    ];
    final duration = durationLabel(l10n, 60);
    final timerLink = ClPressable(
      onPressed: () {},
      semanticLabel: l10n.sleepStartTimer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
        child: Row(children: [
          ClIcon(ClIcons.clock, size: 18, color: care.ink),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${l10n.sleepingNow('Teddy')} ', style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
              TextSpan(text: l10n.sleepStartTimer, style: cl.text.label.copyWith(fontWeight: FontWeight.w600, color: care.ink)),
            ])),
          ),
        ]),
      ),
    );
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () {}),
      content: summaryFirst
          ? [
              // A — refined: same order, the duration card shrinks to one compact line.
              ScreenHeading(title: l10n.manualSleepTitle),
              const SizedBox(height: ClSpace.s4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: ClSpace.s3),
                decoration: BoxDecoration(color: care.soft, borderRadius: BorderRadius.circular(ClRadius.card)),
                child: Row(children: [
                  ClIcon(ClIcons.sleep, size: 20, color: care.ink),
                  const SizedBox(width: ClSpace.s2),
                  Text(l10n.durationLabel, style: cl.text.body.copyWith(color: care.ink)),
                  const Spacer(),
                  Text(duration, style: cl.text.headline.copyWith(color: cl.colors.ink)),
                ]),
              ),
              const SizedBox(height: ClSpace.s4),
              ClCardGroup(shadow: true, children: rows),
              const SizedBox(height: ClSpace.s2),
              timerLink,
            ]
          : [
              // B — inputs first: start and end are the task; the duration is their result,
              // read as the total of the same group.
              ScreenHeading(title: l10n.manualSleepTitle),
              const SizedBox(height: ClSpace.s4),
              ClCardGroup(
                shadow: true,
                children: [
                  ...rows,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s4, ClSpace.s3),
                    child: Row(children: [
                      Text(l10n.durationLabel, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
                      const Spacer(),
                      Text(duration, style: cl.text.title.copyWith(color: cl.colors.ink)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s2),
              timerLink,
            ],
      bottom: [ClButton(label: l10n.saveSleep, expand: true, onPressed: () {})],
    );
  }
}
