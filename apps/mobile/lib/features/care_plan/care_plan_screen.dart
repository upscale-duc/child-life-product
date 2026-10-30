import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/environment.dart';
import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_status.dart';
import '../../core/widgets/cl_swipe.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart'
    show careClockProvider, dayMarksProvider, inBabyZone;
import '../care/history_screen.dart' show weekdayShort;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import 'care_plan_log.dart';
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_sheets.dart';
import 'care_plan_widgets.dart';

const _kSwipeHintDone = 'carePlan.swipeHint.done';

/// The one-time "Vuốt sang trái để sửa hoặc xoá" hint, once per device.
final carePlanSwipeHintDoneProvider =
    NotifierProvider<CarePlanSwipeHintDone, bool>(CarePlanSwipeHintDone.new);

class CarePlanSwipeHintDone extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_kSwipeHintDone) ?? false;

  void done() {
    ref.read(sharedPreferencesProvider).setBool(_kSwipeHintDone, true);
    state = true;
  }
}

/// Cùng Chăm Con (D-135; Figma 04 / 04b / 04-0): the family's shared plan for one day. Cùng nuôi
/// add, edit, assign and skip; whoever cares (Cùng nuôi, Người chăm sóc) ticks a task done, and
/// the task records who did it. Sáng / Chiều / Tối group tasks by time, they are not shifts.
/// Ticking a task is not a care record (logging stays in Care).
///
/// A drafted day (D-136: "Theo nhịp của bé", a reference template, the morning draft) is shown to
/// the plan managers with "Dùng lịch này" and "Đổi cách khác" on top; everyone else sees no plan
/// until it is used.
class CarePlanScreen extends ConsumerStatefulWidget {
  const CarePlanScreen({this.date, super.key});

  /// "2026-10-28"; today (the baby's day) when null.
  final String? date;

  @override
  ConsumerState<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends ConsumerState<CarePlanScreen> {
  String? _date;
  bool _starting = false;

  /// 01: every way to start the day ("Đổi cách khác" on 04-0 or on a draft).
  bool _choosing = false;

  Future<void> _start(String babyId, String date, String from) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _starting = true);
    try {
      await ref.read(carePlanRepositoryProvider).startDay(babyId, date, from);
      if (mounted) setState(() => _choosing = false);
    } on FirebaseFunctionsException catch (e) {
      final reason = (e.details as Map?)?['reason'] ?? e.message;
      toaster.show(
        message: reason == 'not-enough-data'
            ? l10n.cpRhythmNotReady
            : l10n.cpSaveFailed,
        error: true,
      );
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final babyId = me.babyId;
    final zone =
        ref.watch(babyProvider(babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final todayWall = DateUtils.dateOnly(inBabyZone(zone, now));
    final today = carePlanDateKey(todayWall);
    final date = _date ?? widget.date ?? today;
    final yesterday = carePlanDateKey(
      todayWall.subtract(const Duration(days: 1)),
    );
    final editableDay = date.compareTo(yesterday) >= 0;
    final manage = carePlanCanManage(me) && editableDay;

    final key = (babyId, date);
    final dayAsync = ref.watch(carePlanDayProvider(key));
    final draft = dayAsync.value?.draft ?? false;
    // A draft is ticked once it is in use.
    final complete = carePlanCanComplete(me) && editableDay && !draft;
    final itemsAsync = ref.watch(carePlanItemsProvider(key));
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];
    final people = [
      for (final m in members)
        if (carePlanAssignable(m, now)) m,
    ];
    final pending = ref.watch(carePlanPendingProvider);
    final items = [
      for (final i in itemsAsync.value ?? const <CarePlanItem>[])
        switch (pending[i.id]) {
          final s? when s != i.status => i.copyWith(status: s, doneBy: me.uid),
          _ => i,
        },
    ];
    String name(String uid) =>
        carePlanPersonName(l10n, members, uid, me.uid) ?? '';

    final strip = _DayStrip(
      today: todayWall,
      selected: date,
      onSelect: (d) => setState(() {
        _date = d;
        _choosing = false;
      }),
    );
    final yesterdayKey = carePlanDateKey(
      DateTime.parse(date).subtract(const Duration(days: 1)),
    );
    final hasDay = dayAsync.value != null;
    if (manage && _choosing && (!hasDay || draft)) {
      return _ChooseWay(
        babyId: babyId,
        date: date,
        yesterdayKey: yesterdayKey,
        busy: _starting,
        current: draft ? dayAsync.value?.source : null,
        onBack: () => setState(() => _choosing = false),
        onStart: (from) => unawaited(_start(babyId, date, from)),
      );
    }
    final startDay = _StartDay(
      babyId: babyId,
      date: date,
      today: date == today,
      canStart: manage,
      busy: _starting,
      onStart: (from) => unawaited(_start(babyId, date, from)),
      onChoose: () => setState(() => _choosing = true),
      yesterdayKey: yesterdayKey,
    );

    final List<Widget> body;
    // 02: a draft is its own page for the plan managers (Figma 1388:21646).
    Widget? draftPage;
    if (dayAsync.hasError || itemsAsync.hasError) {
      body = [
        const SizedBox(height: ClSpace.s6),
        MeNotice(
          tone: MeTone.error,
          icon: ClIcons.cloudOff,
          title: l10n.cpLoadFailed,
        ),
      ];
    } else if (!dayAsync.hasValue || !itemsAsync.hasValue) {
      body = const [
        SizedBox(height: ClSpace.s4),
        ClSkeleton(height: 96),
        SizedBox(height: ClSpace.s4),
        ClSkeleton(height: 72),
        SizedBox(height: ClSpace.s2),
        ClSkeleton(height: 72),
      ];
    } else if (dayAsync.value == null || (draft && !manage)) {
      // Nobody but the plan managers sees a draft (D-136).
      body = [startDay];
    } else {
      final open = items.where((i) => i.status == CarePlanStatus.open);
      final nextId = date == today && !draft ? open.firstOrNull?.id : null;
      final showHint = manage && !ref.watch(carePlanSwipeHintDoneProvider);

      Future<void> setStatus(CarePlanItem item, CarePlanStatus status) async {
        final toaster = ClToaster.of(context);
        final taskName = carePlanTaskName(l10n, item);
        final old = item.status;
        // D-138: a task that is a care log writes it first; unsaved, the task stays open.
        if (status == CarePlanStatus.done && old == CarePlanStatus.open) {
          if (!await carePlanLogFor(context, ref, item) || !mounted) return;
        }
        final logged =
            status == CarePlanStatus.done && carePlanLogType(item.task) != null;
        final pend = ref.read(carePlanPendingProvider.notifier)
          ..set(item.id, status);
        try {
          await ref
              .read(carePlanRepositoryProvider)
              .setStatus(babyId, date, item.id, status);
          // A saved log has its own "Đã ghi … · Hoàn tác" on screen.
          if (status != CarePlanStatus.open && !logged) {
            toaster.show(
              message: status == CarePlanStatus.done
                  ? l10n.cpDoneToast(taskName)
                  : l10n.cpSkipToast(taskName),
              actionLabel: l10n.undo,
              onAction: () =>
                  unawaited(setStatus(item.copyWith(status: status), old)),
            );
          }
        } on Object {
          toaster.show(message: l10n.cpSaveFailed, error: true);
        } finally {
          pend.clear(item.id);
        }
      }

      final load = <String, int>{};
      for (final i in items) {
        if (i.skipped) continue;
        for (final u in i.assignees) {
          load[u] = (load[u] ?? 0) + 1;
        }
      }

      Future<void> assign(
        List<CarePlanItem> target,
        String title, {
        CarePlanPeriod? period,
      }) async {
        final initial = target.length == 1
            ? target.first.assignees
            : [
                for (final u in target.first.assignees)
                  if (target.every((i) => i.assignees.contains(u))) u,
              ];
        final toaster = ClToaster.of(context);
        await showCarePlanAssign(
          context,
          title: title,
          people: people,
          initial: initial,
          load: load,
          meUid: me.uid,
          allowNobody: target.length == 1,
          group: period != null,
          leading: period != null
              ? carePlanPeriodBadge(context, period)
              : CarePlanArt(target.first.task, size: 40),
          subtitle: period != null
              ? l10n.cpAssignSpan(
                  target.length,
                  target.first.time,
                  target.last.time,
                )
              : '${target.first.time} · ${carePlanTaskName(l10n, target.first)}',
          // The sheet waits on the server with its button loading (owner, 2026-10-30).
          onSave: (chosen) async {
            try {
              await ref.read(carePlanRepositoryProvider).assign(babyId, date, [
                for (final i in target) i.id,
              ], chosen);
              return true;
            } on Object {
              toaster.show(message: l10n.cpSaveFailed, error: true);
              return false;
            }
          },
        );
      }

      Future<void> delete(CarePlanItem item) async {
        final taskName = carePlanTaskName(l10n, item);
        final toaster = ClToaster.of(context);
        final everyDay = await confirmCarePlanDelete(
          context,
          name: taskName,
          everyDay: item.everyDay,
        );
        if (everyDay == null || !context.mounted) return;
        try {
          await withClProgress(
            context,
            () => ref
                .read(carePlanRepositoryProvider)
                .deleteItem(babyId, date, item.id, everyDay: everyDay),
          );
          toaster.show(message: l10n.cpDeletedToast(taskName));
        } on Object {
          toaster.show(message: l10n.cpSaveFailed, error: true);
        }
      }

      void edit(CarePlanItem item) => unawaited(
        showCarePlanEditor(
          context,
          babyId: babyId,
          date: date,
          people: people,
          meUid: me.uid,
          item: item,
          load: load,
          onSkip: () => unawaited(
            setStatus(
              item,
              item.skipped ? CarePlanStatus.open : CarePlanStatus.skipped,
            ),
          ),
          onDelete: () => unawaited(delete(item)),
        ),
      );

      var hintShown = false;
      Widget card(CarePlanItem item) {
        final taskName = carePlanTaskName(l10n, item);
        final names = [
          for (final u in item.assignees)
            ?carePlanPersonName(l10n, members, u, me.uid),
        ];
        final faces = [
          for (final u in item.assignees)
            ?members.where((m) => m.uid == u).firstOrNull,
        ];
        // Who did it shows as thanks on the day card (04b), not on every row.
        final status = item.skipped ? l10n.cpSkipped : null;
        Widget c = CarePlanTaskCard(
          key: ValueKey('cp_item_${item.id}'),
          item: item,
          name: taskName,
          next: item.id == nextId,
          status: status,
          people: item.skipped
              ? const SizedBox.shrink()
              : CarePlanPeople(
                  people: faces,
                  names: names,
                  onTap: manage
                      ? () => unawaited(assign([item], l10n.cpAssignWhoTask))
                      : null,
                ),
          ring: complete && !item.skipped
              ? CarePlanRing(
                  key: ValueKey('cp_ring_${item.id}'),
                  done: item.done,
                  semanticLabel: item.done
                      ? l10n.cpMarkOpen(taskName)
                      : l10n.cpMarkDone(taskName),
                  onPressed: () => unawaited(
                    setStatus(
                      item,
                      item.done ? CarePlanStatus.open : CarePlanStatus.done,
                    ),
                  ),
                )
              : null,
          onTap: manage ? () => edit(item) : null,
          semanticLabel: '${item.time} $taskName',
          timeLeading: draft,
        );
        if (manage) {
          c = ClSwipeActions(
            actions: [
              ClSwipeAction(
                label: l10n.actionEdit,
                icon: ClIcons.edit,
                onPressed: () => edit(item),
              ),
              ClSwipeAction(
                label: l10n.cpDelete,
                icon: ClIcons.trash,
                destructive: true,
                onPressed: () => unawaited(delete(item)),
              ),
            ],
            child: c,
          );
        }
        if (showHint && !hintShown) {
          hintShown = true;
          c = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              c,
              const SizedBox(height: ClSpace.s2),
              _SwipeHint(
                onDone: () =>
                    ref.read(carePlanSwipeHintDoneProvider.notifier).done(),
              ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s2),
          child: c,
        );
      }

      Future<void> use() async {
        final toaster = ClToaster.of(context);
        setState(() => _starting = true);
        try {
          await ref.read(carePlanRepositoryProvider).publishDay(babyId, date);
          toaster.show(message: l10n.cpDraftUsed);
        } on Object {
          toaster.show(message: l10n.cpSaveFailed, error: true);
        } finally {
          if (mounted) setState(() => _starting = false);
        }
      }

      final groups = [
        for (final p in CarePlanPeriod.values)
          if (manage || items.any((i) => i.period == p))
            ...() {
              final group = [
                for (final i in items)
                  if (i.period == p) i,
              ];
              final done = group.where((i) => i.done).length;
              final active = group.where((i) => !i.skipped).toList();
              return [
                const SizedBox(height: ClSpace.s4),
                _GroupHeader(
                  period: p,
                  count: group.isEmpty
                      ? ''
                      : done > 0
                      ? '$done/${active.length}'
                      : l10n.cpDayTasks(active.length),
                  onAssign: manage && active.isNotEmpty
                      ? () => unawaited(
                          assign(active, switch (p) {
                            CarePlanPeriod.morning => l10n.cpAssignWhoMorning,
                            CarePlanPeriod.afternoon =>
                              l10n.cpAssignWhoAfternoon,
                            CarePlanPeriod.evening => l10n.cpAssignWhoEvening,
                          }, period: p),
                        )
                      : null,
                ),
                const SizedBox(height: ClSpace.s2),
                for (final i in group) card(i),
                if (manage)
                  CarePlanAddButton(
                    key: ValueKey('cp_add_${p.name}'),
                    label: l10n.cpAddTask,
                    onPressed: () => unawaited(
                      showCarePlanEditor(
                        context,
                        babyId: babyId,
                        date: date,
                        people: people,
                        meUid: me.uid,
                        period: p,
                      ),
                    ),
                  ),
              ];
            }(),
      ];
      if (draft) {
        final source = dayAsync.value!.source;
        final ways = _Ways(ref, babyId, date, yesterdayKey);
        draftPage = PopScope(
          key: const Key('cp_draft'),
          canPop: true,
          child: CarePlanPage(
            title: date == today ? l10n.cpTodayPlan : l10n.cpTitle,
            bottom: ClButton(
              key: const Key('cp_draft_use'),
              label: l10n.cpDraftUse,
              expand: true,
              loading: _starting,
              onPressed: use,
            ),
            children: [
              _DraftHeader(
                title: l10n.cpDraftHeading(ways.babyName),
                from: source == 'rhythm'
                    ? l10n.cpDraftFromRhythm
                    : l10n.cpDraftFrom(ways.label(l10n, source)),
                onChange: _starting
                    ? null
                    : () => setState(() => _choosing = true),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: ClSpace.s4),
                _DayTimeline(items: items),
              ],
              ...groups,
              const SizedBox(height: ClSpace.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClIcon(ClIcons.heart, size: 14, color: cl.colors.inkMuted),
                  const SizedBox(width: ClSpace.s1),
                  Flexible(
                    child: Text(
                      l10n.cpDraftNote,
                      textAlign: TextAlign.center,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      body = [
        if (items.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          _Summary(
            items: items,
            today: date == today,
            people: [
              for (final m in members)
                if (name(m.uid).isNotEmpty) (m, name(m.uid)),
            ],
          ),
        ],
        ...groups,
      ];
    }

    if (draftPage != null) return draftPage;
    return CarePlanPage(
      title: l10n.cpTitle,
      actions: [
        // 11 Cùng nhau chăm (D-138).
        CarePlanIconButton(
          key: const Key('cp_report'),
          icon: ClIcons.chart,
          semanticLabel: l10n.cpReportOpen,
          onPressed: () => context.push(Routes.carePlanReport),
        ),
        // N1: whoever can be given a task sets their own reminders.
        if (carePlanCanComplete(me))
          CarePlanIconButton(
            key: const Key('cp_settings'),
            icon: ClIcons.sliders,
            semanticLabel: l10n.cpRemindTitle,
            onPressed: () => context.push(Routes.carePlanSettings),
          ),
      ],
      children: [strip, ...body],
    );
  }
}

/// The last seven days, today on the right (like Lịch sử). Older days are read-only.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  final DateTime today;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 6; i >= 0; i--)
            () {
              final d = DateTime(today.year, today.month, today.day - i);
              final k = carePlanDateKey(d);
              return ClDayPill(
                key: ValueKey('cp_day_$k'),
                weekday: weekdayShort(locale, d),
                day: '${d.day}',
                selected: k == selected,
                onTap: () => onSelect(k),
              );
            }(),
        ],
      ),
    );
  }
}

/// 04 / 04b: how the day stands, on the sun card. Before anything is done: how many tasks, the
/// first one and who has how many. Once something is done: a ring, a cheer and thanks to the
/// people who did them (only those; nobody is ranked).
class _Summary extends StatelessWidget {
  const _Summary({
    required this.items,
    required this.today,
    required this.people,
  });

  final List<CarePlanItem> items;
  final bool today;

  /// Who is who, with their display name ("Ba", "Bạn").
  final List<(Membership, String)> people;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final active = items.where((i) => !i.skipped).toList();
    final done = active.where((i) => i.done).length;
    final open = active.length - done;
    final first = active.firstOrNull;

    final counts = <String, int>{};
    for (final i in active) {
      if (done > 0) {
        if (i.done && i.doneBy != null) {
          counts[i.doneBy!] = (counts[i.doneBy!] ?? 0) + 1;
        }
      } else {
        for (final u in i.assignees) {
          counts[u] = (counts[u] ?? 0) + 1;
        }
      }
    }
    final chips = [
      for (final (m, name) in people)
        if ((counts[m.uid] ?? 0) > 0)
          (m, carePlanCapitalized(name), counts[m.uid]!),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    final art = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: c.mint, shape: BoxShape.circle),
      child: ClipOval(
        child: const ClArt(ClIllustration.babyFace, width: 48, height: 48),
      ),
    );
    final Widget top;
    if (done == 0) {
      top = Row(
        children: [
          art,
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  today
                      ? l10n.cpTodayCount(active.length)
                      : l10n.cpDayTasks(active.length),
                  style: cl.text.headline.copyWith(color: c.onCard),
                ),
                if (first != null)
                  Text(
                    l10n.cpFirstTask(first.time, carePlanTaskName(l10n, first)),
                    style: cl.text.label.copyWith(color: c.onCard),
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      top = Row(
        children: [
          CarePlanProgressRing(done: done, total: active.length),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              open == 0 ? l10n.cpAllDone : l10n.cpLeftCheer(open),
              style: cl.text.headline.copyWith(color: c.onCard),
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          art,
        ],
      );
    }
    return Container(
      key: const Key('cp_summary'),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: c.cardSun,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          top,
          if (chips.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final (m, name, n) in chips)
                  _PersonPill(
                    member: m,
                    label: done > 0
                        ? l10n.cpPersonDone(name, n)
                        : l10n.cpPersonCount(name, n),
                    heart: done > 0,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Ba · 4" / "Cô Lan xong 2 ♡" on the day card: a white pill with the person's face.
class _PersonPill extends StatelessWidget {
  const _PersonPill({
    required this.member,
    required this.label,
    required this.heart,
  });

  final Membership member;
  final String label;
  final bool heart;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s1,
        ClSpace.s1,
        ClSpace.s3,
        ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarePlanAvatar(member, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: cl.text.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ),
          if (heart) ...[
            const SizedBox(width: ClSpace.s1),
            ClIcon(ClIcons.heart, size: 12, color: c.peach),
          ],
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.period,
    required this.count,
    required this.onAssign,
  });

  final CarePlanPeriod period;
  final String count;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final tint = switch (period) {
      CarePlanPeriod.morning => c.sunshineSoft,
      CarePlanPeriod.afternoon => c.mintSoft,
      CarePlanPeriod.evening => cl.care.sleep.soft,
    };
    return Row(
      children: [
        // Name and count wrap at large text; the action keeps its size.
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ClSpace.s2,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: ClIcon(
                  carePlanPeriodIcon(period),
                  size: 18,
                  color: c.ink,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  carePlanPeriodLabel(l10n, period),
                  style: cl.text.headline.copyWith(color: c.ink),
                ),
              ),
              if (count.isNotEmpty)
                Text(
                  count,
                  style: cl.text.caption.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: c.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (onAssign != null)
          ClPressable(
            key: ValueKey('cp_assign_${period.name}'),
            onPressed: onAssign,
            semanticLabel: l10n.cpAssignGroup,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(ClRadius.pill),
                border: Border.all(color: c.controlBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(ClIcons.family, size: 16, color: c.ink),
                  const SizedBox(width: ClSpace.s1),
                  Text(
                    l10n.cpAssignGroup,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A small pill on a way to plan: "Đã chọn", "Gợi ý", "Hợp tuổi".
class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.sun = false, this.check = false});

  final String label;
  final bool sun;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final ink = sun ? c.onWarm : c.mintText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: sun ? c.sunshine : c.mintSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (check) ...[
            ClIcon(ClIcons.check, size: 12, color: ink),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: cl.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The ways this family can start [date] (D-136): its own rhythm once 7 of 7 days are logged,
/// the everyday tasks, yesterday's, the reference templates (dev only, EASY under 6 months), or
/// nothing.
class _Ways {
  _Ways(WidgetRef ref, String babyId, String date, String yesterdayKey) {
    everyday = ref.watch(carePlanEverydayCountProvider(babyId)).value ?? 0;
    yesterday =
        ref
            .watch(carePlanItemsProvider((babyId, yesterdayKey)))
            .value
            ?.length ??
        0;
    // D-136 #2: each of the 7 days before has a feed and a sleep.
    final first = carePlanDateKey(
      DateTime.parse(date).subtract(const Duration(days: carePlanRhythmDays)),
    );
    final marks =
        ref.watch(dayMarksProvider((babyId, first, yesterdayKey))).value ??
        const {};
    rhythm =
        marks.values.where((m) => m.feeds && m.sleep).length >=
        carePlanRhythmDays;
    templates = ref.watch(environmentProvider) == AppEnvironment.dev;
    dob = ref.watch(babyPrivateProfileProvider(babyId)).value?.dateOfBirth;
    // D-136 #4: EASY only for a baby under 6 months.
    ageMonths = dob == null
        ? null
        : carePlanAgeMonths(dob!, DateTime.parse(date));
    babyName = ref.watch(babyProvider(babyId)).value?.nickname ?? '';
    method = ref.watch(carePlanFamilySettingsProvider(babyId)).value?.method;
  }

  late final int everyday;
  late final int yesterday;
  late final bool rhythm;
  late final bool templates;
  late final DateTime? dob;
  late final int? ageMonths;
  late final String babyName;

  /// The way the family chose before (saved by the server, D-136).
  late final String? method;

  bool available(String from) => switch (from) {
    'rhythm' => rhythm,
    'everyday' => everyday > 0,
    'yesterday' => yesterday > 0,
    'empty' => true,
    _ => templates && carePlanTemplateOffered(from, ageMonths),
  };

  String label(AppLocalizations l10n, String from) => switch (from) {
    'rhythm' => l10n.cpStartRhythmOf(babyName),
    'everyday' => l10n.cpStartEveryday,
    'yesterday' => l10n.cpStartYesterday,
    'basic' => l10n.cpByAge,
    'easy35' => l10n.cpStartEasy35,
    'easy4' => l10n.cpStartEasy4,
    _ => l10n.cpSelfMade,
  };

  ClIcons icon(String from) => switch (from) {
    'rhythm' => ClIcons.spark,
    'everyday' => ClIcons.calendar,
    'yesterday' => ClIcons.retry,
    'basic' => ClIcons.cake,
    'empty' => ClIcons.edit,
    _ => ClIcons.sleep,
  };
}

/// One way to plan, as a radio row in a card group.
class _WayRow extends StatelessWidget {
  const _WayRow({
    required this.from,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconTint,
    this.badge,
  });

  final String from;
  final String title;
  final String? subtitle;
  final ClIcons? icon;
  final Color? iconTint;
  final Widget? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      key: ValueKey('cp_way_$from'),
      onPressed: onTap,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      selected: selected,
      pressedOpacity: ClPressable.surfaceOpacity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s3,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconTint ?? c.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(icon!, size: 20, color: c.ink),
                ),
                const SizedBox(width: ClSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: ClSpace.s2,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: cl.text.bodyStrong.copyWith(color: c.ink),
                        ),
                        ?badge,
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: cl.text.caption.copyWith(color: c.inkMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              ClRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// 04-0 "Hôm nay chưa có lịch": the way the family chose before and "Giống hôm qua" as one-tap
/// choices, "Đổi cách khác" for every way (01), and "Tạo lịch hôm nay". Someone who cannot make
/// the plan only sees that there is none yet. A family that has never chosen goes straight to 01.
class _StartDay extends ConsumerStatefulWidget {
  const _StartDay({
    required this.babyId,
    required this.date,
    required this.yesterdayKey,
    required this.today,
    required this.canStart,
    required this.busy,
    required this.onStart,
    required this.onChoose,
  });

  final String babyId;
  final String date;
  final String yesterdayKey;
  final bool today;
  final bool canStart;
  final bool busy;
  final ValueChanged<String> onStart;
  final VoidCallback onChoose;

  @override
  ConsumerState<_StartDay> createState() => _StartDayState();
}

class _StartDayState extends ConsumerState<_StartDay> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final title = widget.today ? l10n.cpEmptyToday : l10n.cpEmptyDay;
    if (!widget.canStart) {
      return Padding(
        padding: const EdgeInsets.only(top: ClSpace.s8),
        child: ClEmptyState(
          icon: ClIcons.calendar,
          title: title,
          message: l10n.cpEmptyViewer,
        ),
      );
    }
    final ways = _Ways(ref, widget.babyId, widget.date, widget.yesterdayKey);
    final chosen =
        ways.method != null &&
            ways.method != 'yesterday' &&
            ways.available(ways.method!)
        ? ways.method
        : null;
    final options = [?chosen, if (ways.yesterday > 0) 'yesterday'];
    final picked = options.contains(_picked) ? _picked : options.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s8),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: c.mint, shape: BoxShape.circle),
            child: const ClipOval(
              child: ClArt(ClIllustration.babyFace, width: 96, height: 96),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: cl.text.title2.copyWith(color: c.ink),
        ),
        const SizedBox(height: ClSpace.s1),
        Text(
          l10n.cpStartSub,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        if (options.isNotEmpty) ...[
          ClCardGroup(
            children: [
              for (final from in options)
                _WayRow(
                  from: from,
                  title: ways.label(l10n, from),
                  subtitle: from == 'yesterday'
                      ? l10n.cpDayTasks(ways.yesterday)
                      : l10n.cpChosenSub,
                  icon: ways.icon(from),
                  iconTint: from == 'yesterday' ? c.mintSoft : c.sunshineSoft,
                  badge: from == chosen ? _Badge(l10n.cpChosen) : null,
                  selected: from == picked,
                  onTap: () => setState(() => _picked = from),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        Center(
          child: ClPressable(
            key: const Key('cp_choose_way'),
            onPressed: widget.busy ? null : widget.onChoose,
            semanticLabel: l10n.cpDraftChange,
            child: SizedBox(
              height: ClSpace.tapMin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.cpDraftChange,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.mintText,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s1),
                  ClIcon(ClIcons.arrowRight, size: 16, color: c.mintText),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          key: const Key('cp_start'),
          label: widget.today ? l10n.cpCreateToday : l10n.cpCreateDay,
          expand: true,
          loading: widget.busy,
          onPressed: () =>
              picked == null ? widget.onChoose() : widget.onStart(picked),
        ),
      ],
    );
  }
}

/// 01 "Lên lịch cho Teddy": every way to start the day as one choice. "Theo nhịp" leads when the
/// last 7 days are logged; the EASY templates come next (dev only, under 6 months, the one that
/// fits the age marked); then by age, the family's everyday tasks, yesterday's, and "Tự tạo".
/// Drafted ways say "Xem trước lịch" (D-136: a draft is used only after "Dùng lịch này"). With
/// [current] it replaces a draft: that way is left out, and back keeps the draft.
class _ChooseWay extends ConsumerStatefulWidget {
  const _ChooseWay({
    required this.babyId,
    required this.date,
    required this.yesterdayKey,
    required this.busy,
    required this.onStart,
    required this.onBack,
    this.current,
  });

  final String babyId;
  final String date;
  final String yesterdayKey;
  final bool busy;
  final ValueChanged<String> onStart;
  final VoidCallback onBack;
  final String? current;

  @override
  ConsumerState<_ChooseWay> createState() => _ChooseWayState();
}

class _ChooseWayState extends ConsumerState<_ChooseWay> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final ways = _Ways(ref, widget.babyId, widget.date, widget.yesterdayKey);
    bool offered(String from) => from != widget.current && ways.available(from);
    final age = ways.dob == null
        ? null
        : ageShort(l10n, ways.dob!, DateTime.parse(widget.date));
    final months = ways.ageMonths;
    final easy = [
      for (final (from, sub, fits) in [
        ('easy35', l10n.cpEasy35Sub, months != null && months < 4),
        ('easy4', l10n.cpEasy4Sub, months != null && months >= 4),
      ])
        if (offered(from)) (from, sub, fits),
    ];
    final other = [
      if (offered('basic'))
        ('basic', age == null ? null : l10n.cpByAgeSub(age), c.sunshineSoft),
      if (offered('everyday'))
        ('everyday', l10n.cpDayTasks(ways.everyday), c.mintSoft),
      if (offered('yesterday'))
        ('yesterday', l10n.cpDayTasks(ways.yesterday), c.mintSoft),
      if (offered('empty')) ('empty', l10n.cpSelfMadeSub, c.mintSoft),
    ];
    final all = [
      if (offered('rhythm')) 'rhythm',
      for (final e in easy) e.$1,
      for (final o in other) o.$1,
    ];
    final picked = all.contains(_picked) ? _picked! : all.first;
    void pick(String from) => setState(() => _picked = from);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: CarePlanPage(
        title: l10n.cpChooseTitle(ways.babyName),
        bottom: ClButton(
          key: const Key('cp_way_go'),
          label: picked == 'rhythm' || carePlanTemplateMethods.contains(picked)
              ? l10n.cpPreview
              : l10n.cpCreateDay,
          expand: true,
          loading: widget.busy,
          onPressed: () => widget.onStart(picked),
        ),
        children: [
          const SizedBox(height: ClSpace.s2),
          if (offered('rhythm'))
            _RhythmCard(
              title: l10n.cpStartRhythmOf(ways.babyName),
              selected: picked == 'rhythm',
              onTap: () => pick('rhythm'),
            ),
          if (easy.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cpEasySection,
                    style: cl.text.headline.copyWith(color: c.ink),
                  ),
                ),
                if (age != null)
                  ClChip(label: '${ways.babyName} $age', icon: ClIcons.cake),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            ClCardGroup(
              children: [
                for (final (from, sub, fits) in easy)
                  _WayRow(
                    from: from,
                    title: ways.label(l10n, from),
                    subtitle: sub,
                    badge: fits ? _Badge(l10n.cpFitsAge, check: true) : null,
                    selected: picked == from,
                    onTap: () => pick(from),
                  ),
              ],
            ),
          ],
          const SizedBox(height: ClSpace.s6),
          Text(
            l10n.cpOtherSection,
            style: cl.text.headline.copyWith(color: c.ink),
          ),
          const SizedBox(height: ClSpace.s2),
          ClCardGroup(
            children: [
              for (final (from, sub, tint) in other)
                _WayRow(
                  from: from,
                  title: ways.label(l10n, from),
                  subtitle: sub,
                  icon: ways.icon(from),
                  iconTint: tint,
                  selected: picked == from,
                  onTap: () => pick(from),
                ),
            ],
          ),
          if (ways.templates && (easy.isNotEmpty || offered('basic')))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s1,
                ClSpace.s2,
                ClSpace.s1,
                0,
              ),
              child: Text(
                l10n.cpTemplatesNote,
                style: cl.text.caption.copyWith(color: c.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// 01's lead choice: the family's own rhythm, on its own card with the baby's face.
class _RhythmCard extends StatelessWidget {
  const _RhythmCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      key: const ValueKey('cp_way_rhythm'),
      onPressed: onTap,
      selected: selected,
      semanticLabel: '$title, ${l10n.cpRhythmFrom}',
      pressedOpacity: ClPressable.surfaceOpacity,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          border: Border.all(
            color: selected ? c.mintDeep : c.surface,
            width: 1.5,
          ),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.mint, shape: BoxShape.circle),
              child: const ClipOval(
                child: ClArt(ClIllustration.babyFace, width: 44, height: 44),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ClSpace.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: cl.text.headline.copyWith(color: c.ink),
                      ),
                      _Badge(l10n.cpSuggestBadge, sun: true),
                    ],
                  ),
                  Text(
                    l10n.cpRhythmFrom,
                    style: cl.text.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            ClRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// 02's top: the baby's face, "Gợi ý cho Teddy", where it came from and "Đổi cách".
class _DraftHeader extends StatelessWidget {
  const _DraftHeader({
    required this.title,
    required this.from,
    required this.onChange,
  });

  final String title;
  final String from;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.mint, shape: BoxShape.circle),
            child: const ClipOval(
              child: ClArt(ClIllustration.babyFace, width: 48, height: 48),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.title2.copyWith(color: c.ink)),
                Wrap(
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClIcon(ClIcons.spark, size: 14, color: c.inkMuted),
                        const SizedBox(width: ClSpace.s1),
                        Flexible(
                          child: Text(
                            from,
                            style: cl.text.caption.copyWith(color: c.inkMuted),
                          ),
                        ),
                      ],
                    ),
                    ClPressable(
                      key: const Key('cp_draft_change'),
                      onPressed: onChange,
                      semanticLabel: l10n.cpDraftChange,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClSpace.s2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.mintSoft,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          l10n.cpChangeShort,
                          style: cl.text.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.mintText,
                          ),
                        ),
                      ),
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

/// 02's day strip: 06:00 to midnight, the three parts of the day tinted, feeds as dots and
/// sleeps as bars (about 1.5 h each, the plan has no end times).
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.items});

  final List<CarePlanItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    double? at(String hhmm) {
      final p = hhmm.split(':');
      final m = (int.tryParse(p.first) ?? 0) * 60 + (int.tryParse(p.last) ?? 0);
      return m < 6 * 60 ? null : (m - 6 * 60) / (18 * 60);
    }

    final feeds = [
      for (final i in items)
        if (!i.skipped &&
            {
              CarePlanTask.bottle,
              CarePlanTask.breast,
              CarePlanTask.solids,
            }.contains(i.task))
          ?at(i.time),
    ];
    final sleeps = [
      for (final i in items)
        if (!i.skipped && i.task == CarePlanTask.sleep) ?at(i.time),
    ];
    return Semantics(
      label: l10n.cpTimelineA11y(feeds.length, sleeps.length),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s4,
            ClSpace.s4,
            ClSpace.s3,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TimelinePainter(
                    feeds: feeds,
                    sleeps: sleeps,
                    bands: [c.sunshineSoft, c.mintSoft, cl.care.sleep.soft],
                    feed: cl.care.bottle.accent,
                    sleep: cl.care.sleep.accent,
                    ring: c.surface,
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s2),
              SizedBox(
                height: 20,
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final h in const [6, 10, 14, 18, 22])
                        Positioned(
                          left: (box.maxWidth * (h - 6) / 18 - 12).clamp(
                            0,
                            box.maxWidth - 24,
                          ),
                          width: 24,
                          child: Text(
                            '${h}h',
                            textAlign: h == 6
                                ? TextAlign.left
                                : TextAlign.center,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: cl.text.caption.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: c.inkMuted,
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
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.feeds,
    required this.sleeps,
    required this.bands,
    required this.feed,
    required this.sleep,
    required this.ring,
  });

  final List<double> feeds;
  final List<double> sleeps;
  final List<Color> bands;
  final Color feed;
  final Color sleep;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Radius.circular(h / 2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
    // 06–12, 12–18, 18–24 of an 18-hour strip.
    final cuts = [0.0, 6 / 18, 12 / 18, 1.0];
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTRB(cuts[i] * w, 0, cuts[i + 1] * w, h),
        Paint()..color = bands[i],
      );
    }
    canvas.restore();
    final bar = h * 0.55;
    for (final s in sleeps) {
      final left = s * w;
      final right = math.min(w, left + w * 1.5 / 18);
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          (h - bar) / 2,
          right,
          (h + bar) / 2,
          Radius.circular(bar / 2),
        ),
        Paint()..color = sleep,
      );
    }
    for (final f in feeds) {
      final o = Offset(f * w, h / 2);
      canvas.drawCircle(o, 7, Paint()..color = ring);
      canvas.drawCircle(o, 5, Paint()..color = feed);
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.feeds != feeds || old.sleeps != sleeps || old.bands != bands;
}

/// The one-time "Vuốt sang trái để sửa hoặc xoá" hint (Figma 02): a dark one-line tip under the
/// first task with "Đã hiểu".
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      key: const Key('cp_swipe_hint'),
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s3,
        ClSpace.s1,
        ClSpace.s1,
        ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.cpSwipeHint,
              style: cl.text.label.copyWith(color: c.surface),
            ),
          ),
          ClPressable(
            onPressed: onDone,
            semanticLabel: l10n.cpGotIt,
            child: SizedBox(
              height: ClSpace.tapMin,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: ClSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.cpGotIt,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
