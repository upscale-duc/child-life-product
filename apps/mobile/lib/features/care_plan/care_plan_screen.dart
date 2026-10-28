import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_swipe.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show careClockProvider, inBabyZone;
import '../care/history_screen.dart' show weekdayShort;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
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

  Future<void> _run(Future<void> Function() call) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    try {
      await call();
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
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
    final complete = carePlanCanComplete(me) && editableDay;

    final key = (babyId, date);
    final dayAsync = ref.watch(carePlanDayProvider(key));
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
      onSelect: (d) => setState(() => _date = d),
    );

    final List<Widget> body;
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
    } else if (dayAsync.value == null) {
      body = [
        _StartDay(
          babyId: babyId,
          date: date,
          today: date == today,
          canStart: manage,
          busy: _starting,
          onStart: (from) async {
            setState(() => _starting = true);
            await _run(
              () => ref
                  .read(carePlanRepositoryProvider)
                  .startDay(babyId, date, from),
            );
            if (mounted) setState(() => _starting = false);
          },
          yesterdayKey: carePlanDateKey(
            DateTime.parse(date).subtract(const Duration(days: 1)),
          ),
        ),
      ];
    } else {
      final open = items.where((i) => i.status == CarePlanStatus.open);
      final nextId = date == today ? open.firstOrNull?.id : null;
      final showHint = manage && !ref.watch(carePlanSwipeHintDoneProvider);

      Future<void> setStatus(CarePlanItem item, CarePlanStatus status) async {
        final toaster = ClToaster.of(context);
        final taskName = carePlanTaskName(l10n, item);
        final old = item.status;
        final pend = ref.read(carePlanPendingProvider.notifier)
          ..set(item.id, status);
        try {
          await ref
              .read(carePlanRepositoryProvider)
              .setStatus(babyId, date, item.id, status);
          if (status != CarePlanStatus.open) {
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

      Future<void> assign(List<CarePlanItem> target, String title) async {
        final load = <String, int>{};
        for (final i in items) {
          if (i.skipped) continue;
          for (final u in i.assignees) {
            load[u] = (load[u] ?? 0) + 1;
          }
        }
        final initial = target.length == 1
            ? target.first.assignees
            : [
                for (final u in target.first.assignees)
                  if (target.every((i) => i.assignees.contains(u))) u,
              ];
        final chosen = await showCarePlanAssign(
          context,
          title: title,
          people: people,
          initial: initial,
          load: load,
          meUid: me.uid,
          allowNobody: target.length == 1,
        );
        if (chosen == null || !mounted) return;
        await _run(
          () => ref.read(carePlanRepositoryProvider).assign(babyId, date, [
            for (final i in target) i.id,
          ], chosen),
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
        if (everyDay == null || !mounted) return;
        try {
          await ref
              .read(carePlanRepositoryProvider)
              .deleteItem(babyId, date, item.id, everyDay: everyDay);
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
        final status = item.skipped
            ? l10n.cpSkipped
            : item.done && item.doneBy != null && name(item.doneBy!).isNotEmpty
            ? l10n.cpDoneBy(name(item.doneBy!))
            : null;
        Widget c = CarePlanTaskCard(
          key: ValueKey('cp_item_${item.id}'),
          item: item,
          name: taskName,
          next: item.id == nextId,
          status: status,
          people: item.skipped
              ? const SizedBox.shrink()
              : CarePlanPeople(
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
              const SizedBox(height: ClSpace.s1),
              Align(
                alignment: Alignment.centerLeft,
                child: ClTourTip(
                  key: const Key('cp_swipe_hint'),
                  title: l10n.cpSwipeHint,
                  nextLabel: l10n.cpGotIt,
                  onNext: () =>
                      ref.read(carePlanSwipeHintDoneProvider.notifier).done(),
                ),
              ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s2),
          child: c,
        );
      }

      body = [
        if (items.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          _Summary(items: items, today: date == today),
        ],
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
                const SizedBox(height: ClSpace.s6),
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
                          }),
                        )
                      : null,
                ),
                const SizedBox(height: ClSpace.s2),
                for (final i in group) card(i),
                if (manage)
                  ClButton(
                    key: ValueKey('cp_add_${p.name}'),
                    label: l10n.cpAddTask,
                    icon: ClIcons.plus,
                    style: ClButtonStyle.plain,
                    expand: true,
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
    }

    return MePage(
      title: l10n.cpTitle,
      // N1: whoever can be given a task sets their own reminders.
      trailing: carePlanCanComplete(me)
          ? ClPressable(
              key: const Key('cp_settings'),
              semanticLabel: l10n.cpRemindTitle,
              onPressed: () => context.push(Routes.carePlanSettings),
              child: SizedBox.square(
                dimension: ClSpace.tapMin,
                child: Center(
                  child: ClIcon(ClIcons.bell, size: 22, color: cl.colors.ink),
                ),
              ),
            )
          : null,
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

/// 04 / 04b: how the day stands. Before anything is done: how many tasks and the first; once
/// something is done, a ring and what is next (Figma: no progress until someone has done one).
class _Summary extends StatelessWidget {
  const _Summary({required this.items, required this.today});

  final List<CarePlanItem> items;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final active = items.where((i) => !i.skipped).toList();
    final done = active.where((i) => i.done).length;
    final open = active.where((i) => !i.done).toList();
    final first = active.firstOrNull;
    final (String title, String? line) = open.isEmpty
        ? (l10n.cpAllDone, null)
        : done == 0
        ? (
            l10n.cpDayTasks(active.length),
            first == null
                ? null
                : l10n.cpStarts(first.time, carePlanTaskName(l10n, first)),
          )
        : (
            l10n.cpLeft(open.length),
            today
                ? l10n.cpNext(
                    open.first.time,
                    carePlanTaskName(l10n, open.first),
                  )
                : null,
          );
    return Container(
      key: const Key('cp_summary'),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: c.cardSun,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Row(
        children: [
          if (done > 0) ...[
            CarePlanProgressRing(done: done, total: active.length),
            const SizedBox(width: ClSpace.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.headline.copyWith(color: c.onCard)),
                if (line != null)
                  Text(line, style: cl.text.label.copyWith(color: c.onCard)),
              ],
            ),
          ),
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
    return Row(
      children: [
        // Name and count wrap at large text; the action keeps its size.
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ClSpace.s2,
            children: [
              ClIcon(
                carePlanPeriodIcon(period),
                size: 20,
                color: cl.colors.ink,
              ),
              Semantics(
                header: true,
                child: Text(
                  carePlanPeriodLabel(l10n, period),
                  style: cl.text.headline.copyWith(color: cl.colors.ink),
                ),
              ),
              if (count.isNotEmpty)
                Text(
                  count,
                  style: cl.text.label.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: cl.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (onAssign != null)
          ClFilterPill(
            key: ValueKey('cp_assign_${period.name}'),
            icon: ClIcons.family,
            label: l10n.cpAssignGroup,
            onTap: onAssign,
          ),
      ],
    );
  }
}

/// 04-0 "Hôm nay chưa có lịch": start from the everyday tasks, yesterday, or nothing. Someone
/// who cannot make the plan only sees that there is none yet.
class _StartDay extends ConsumerWidget {
  const _StartDay({
    required this.babyId,
    required this.date,
    required this.yesterdayKey,
    required this.today,
    required this.canStart,
    required this.busy,
    required this.onStart,
  });

  final String babyId;
  final String date;
  final String yesterdayKey;
  final bool today;
  final bool canStart;
  final bool busy;
  final ValueChanged<String> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final everyday = canStart
        ? ref.watch(carePlanEverydayCountProvider(babyId)).value ?? 0
        : 0;
    final yesterday = canStart
        ? ref
                  .watch(carePlanItemsProvider((babyId, yesterdayKey)))
                  .value
                  ?.length ??
              0
        : 0;
    final title = today ? l10n.cpEmptyToday : l10n.cpEmptyDay;
    if (!canStart) {
      return Padding(
        padding: const EdgeInsets.only(top: ClSpace.s8),
        child: ClEmptyState(
          icon: ClIcons.calendar,
          title: title,
          message: l10n.cpEmptyViewer,
        ),
      );
    }
    final options = [
      if (everyday > 0)
        ('everyday', l10n.cpStartEveryday, l10n.cpDayTasks(everyday)),
      if (yesterday > 0)
        ('yesterday', l10n.cpStartYesterday, l10n.cpDayTasks(yesterday)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s6),
        Text(title, style: cl.text.title2.copyWith(color: cl.colors.ink)),
        const SizedBox(height: ClSpace.s4),
        if (options.isNotEmpty) ...[
          ClCardGroup(
            children: [
              for (final (from, label, sub) in options)
                MeRow(
                  key: ValueKey('cp_start_$from'),
                  icon: from == 'everyday' ? ClIcons.calendar : ClIcons.retry,
                  title: label,
                  subtitle: sub,
                  onTap: busy ? null : () => onStart(from),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        ClButton(
          key: const Key('cp_start_empty'),
          label: l10n.cpStartEmpty,
          icon: ClIcons.plus,
          expand: true,
          loading: busy,
          style: options.isEmpty
              ? ClButtonStyle.primary
              : ClButtonStyle.secondary,
          onPressed: () => onStart('empty'),
        ),
      ],
    );
  }
}
