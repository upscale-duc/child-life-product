import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_duty.dart' show DutyAge, careDutyProvider, dutyAge;
import '../care/care_repository.dart' show careClockProvider, inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../onboarding/setup_screens.dart' show relationLabel;
import '../reminders/reminder_screens.dart' show assigneeName;
import '../rhythm/rhythm_labels.dart' show memberLabel;
import '../reminders/reminder_notifications.dart'
    show notificationsLaunchAskProvider;
import 'care_plan_log.dart';
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// Cùng Chăm Con step 2 on Hôm nay (D-135; ANALYSIS-2026-10-28 §2): the "n việc cần làm" section
/// (only the viewer's open shared tasks, never personal reminders, Q4) and the "Đến giờ rồi"
/// sheet (Figma 15) when the app opens or a task push (N1, CARE_TASK_DUE) is tapped.

/// The baby's day key ("2026-10-28") for [babyId] now.
String carePlanTodayKey(WidgetRef ref, String babyId) {
  final zone =
      ref.watch(babyProvider(babyId)).value?.timeZone.zone ??
      'Asia/Ho_Chi_Minh';
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  return carePlanDateKey(inBabyZone(zone, now));
}

/// [items] (of [date]) done by this person; one Hoàn tác for one task. The ring answers at once
/// ([carePlanPendingProvider]); a failed call says so and the task comes back. With [context],
/// each task's care log comes first (D-138, [carePlanLogFor]); a log left unsaved leaves its
/// task open, and a saved log says so itself ("Đã ghi · Bú bình 90 ml").
Future<void> markCarePlanDone(
  WidgetRef ref,
  ClToaster toaster,
  AppLocalizations l10n, {
  required String babyId,
  required String date,
  required List<CarePlanItem> items,
  BuildContext? context,
}) async {
  var logged = false;
  if (context != null) {
    final kept = <CarePlanItem>[];
    for (final i in items) {
      if (!context.mounted) return;
      if (carePlanLogType(i.task) != null) logged = true;
      if (await carePlanLogFor(context, ref, i)) kept.add(i);
    }
    items = kept;
    if (items.isEmpty) return;
  }
  final repo = ref.read(carePlanRepositoryProvider);
  final pend = ref.read(carePlanPendingProvider.notifier);
  for (final i in items) {
    pend.set(i.id, CarePlanStatus.done);
  }
  try {
    await Future.wait([
      for (final i in items)
        repo.setStatus(babyId, date, i.id, CarePlanStatus.done),
    ]);
    // The log's own "Đã ghi … · Hoàn tác" stays on screen.
    if (logged) return;
    toaster.show(
      message: items.length == 1
          ? l10n.cpDoneToast(carePlanTaskName(l10n, items.single))
          : l10n.cpDoneManyToast(items.length),
      actionLabel: l10n.undo,
      onAction: () => unawaited(() async {
        try {
          await Future.wait([
            for (final i in items)
              repo.setStatus(babyId, date, i.id, CarePlanStatus.open),
          ]);
        } on Object {
          toaster.show(message: l10n.cpSaveFailed, error: true);
        }
      }()),
    );
  } on Object {
    toaster.show(message: l10n.cpSaveFailed, error: true);
  } finally {
    for (final i in items) {
      pend.clear(i.id);
    }
  }
}

/// Today's open tasks of the viewer, with this phone's pending ticks applied.
List<CarePlanItem> _myOpen(WidgetRef ref, Membership me, String date) {
  final items =
      ref.watch(carePlanLiveItemsProvider((me.babyId, date))).value ?? const [];
  final pending = ref.watch(carePlanPendingProvider);
  return carePlanMine([
    for (final i in items)
      switch (pending[i.id]) {
        final s? => i.copyWith(status: s, doneBy: me.uid),
        null => i,
      },
  ], me.uid);
}

/// 14 "n việc cần làm": the first content block under the header. The next task of mine, with
/// "Đã làm"; nothing at all when none is open (no "Nghỉ chút nhé" card on Hôm nay, D-110).
/// [enabled] is the Tuỳ chỉnh switch (`duty` / [WidgetId.careDuty]).
class CarePlanTodaySection extends ConsumerWidget {
  const CarePlanTodaySection({required this.enabled, super.key});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (!enabled || me == null || !carePlanCanComplete(me)) {
      return const SizedBox.shrink();
    }
    final date = carePlanTodayKey(ref, me.babyId);
    final mine = _myOpen(ref, me, date);
    if (mine.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final next = mine.first;
    final name = carePlanTaskName(l10n, next);
    final cl = context.cl;
    final c = cl.colors;
    // At large text sizes "Đã làm" goes under the task instead of beside it.
    final large = MediaQuery.textScalerOf(context).scale(10) > 13;
    final done = ClButton(
      key: const Key('cpTodayDone'),
      label: l10n.cpDoneAction,
      icon: ClIcons.check,
      expand: large,
      onPressed: () => unawaited(
        markCarePlanDone(
          ref,
          ClToaster.of(context),
          l10n,
          babyId: me.babyId,
          date: date,
          items: [next],
          context: context,
        ),
      ),
    );
    return Padding(
      key: const Key('cpTodaySection'),
      padding: const EdgeInsets.only(top: ClSpace.s4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s2,
          ClSpace.s3,
          ClSpace.s4,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.cpHomeTitle(mine.length),
                      style: cl.text.headline.copyWith(color: c.ink),
                    ),
                  ),
                ),
                ClPressable(
                  key: const Key('cpTodayAll'),
                  onPressed: () => context.push(Routes.carePlan),
                  semanticLabel: l10n.cpHomeAll,
                  child: SizedBox(
                    height: ClSpace.tapMin,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          ClSpace.s3,
                          ClSpace.s1,
                          ClSpace.s2,
                          ClSpace.s1,
                        ),
                        decoration: BoxDecoration(
                          color: c.mintSoft,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.cpHomeAll,
                              style: cl.text.label.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.mintText,
                              ),
                            ),
                            ClIcon(
                              ClIcons.chevronRight,
                              size: 16,
                              color: c.mintText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 1, color: c.separator),
            const SizedBox(height: ClSpace.s3),
            ClPressable(
              key: ValueKey('cpToday_${next.id}'),
              onPressed: () => context.push(Routes.carePlan),
              semanticLabel: '${next.time} $name',
              pressedOpacity: ClPressable.surfaceOpacity,
              child: Row(
                children: [
                  CarePlanArt(next.task, size: 56),
                  const SizedBox(width: ClSpace.s3),
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
                              next.time,
                              style: cl.text.label.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: c.mintText,
                              ),
                            ),
                            const _PlanBadge(),
                          ],
                        ),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.bodyStrong.copyWith(color: c.ink),
                        ),
                      ],
                    ),
                  ),
                  if (!large) ...[const SizedBox(width: ClSpace.s2), done],
                ],
              ),
            ),
            if (large) ...[const SizedBox(height: ClSpace.s3), done],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// "Đến giờ rồi" (15)
// ---------------------------------------------------------------------------------------------

/// A task push (CARE_TASK_DUE) that was opened: show its tasks once nothing is in the way.
typedef CarePlanDueRequest = ({String babyId, String date, List<String> ids});

class CarePlanDueRequests extends Notifier<CarePlanDueRequest?> {
  @override
  CarePlanDueRequest? build() => null;

  void open(CarePlanDueRequest request) => state = request;

  void clear() => state = null;
}

final carePlanDueRequestProvider =
    NotifierProvider<CarePlanDueRequests, CarePlanDueRequest?>(
      CarePlanDueRequests.new,
    );

const _kSeen = 'carePlan.due.seen';
const _kSnooze = 'carePlan.due.snooze';
const _seenCap = 80;

/// Once per task per device; "Để sau 10 phút" lets it come back after ten minutes.
class CarePlanDueMemory {
  CarePlanDueMemory(this._prefs);

  final SharedPreferences _prefs;

  static String keyOf(String babyId, String date, String id) =>
      '$babyId/$date/$id';

  Map<String, int> get _snoozes => {
    for (final e in _prefs.getStringList(_kSnooze) ?? const <String>[])
      if (e.split('@') case [final k, final at]) k: int.tryParse(at) ?? 0,
  };

  bool due(String key, DateTime now) {
    final seen = _prefs.getStringList(_kSeen) ?? const <String>[];
    if (!seen.contains(key)) return true;
    final until = _snoozes[key];
    return until != null && now.millisecondsSinceEpoch >= until;
  }

  Future<void> shown(Iterable<String> keys) async {
    final seen = [...?_prefs.getStringList(_kSeen)];
    for (final k in keys) {
      seen
        ..remove(k)
        ..add(k);
    }
    final snoozes = _snoozes..removeWhere((k, _) => keys.contains(k));
    await _prefs.setStringList(
      _kSeen,
      seen.length > _seenCap ? seen.sublist(seen.length - _seenCap) : seen,
    );
    await _writeSnoozes(snoozes);
  }

  Future<void> snooze(Iterable<String> keys, DateTime until) async {
    final snoozes = _snoozes;
    for (final k in keys) {
      snoozes[k] = until.millisecondsSinceEpoch;
    }
    await _writeSnoozes(snoozes);
  }

  Future<void> _writeSnoozes(Map<String, int> s) => _prefs.setStringList(
    _kSnooze,
    [for (final e in s.entries) '${e.key}@${e.value}'],
  );
}

final carePlanDueMemoryProvider = Provider<CarePlanDueMemory>(
  (ref) => CarePlanDueMemory(ref.watch(sharedPreferencesProvider)),
);

/// Tasks of mine whose time has come: from 5 minutes before (the push said "5 phút nữa") to an
/// hour after. Older ones wait in the day plan; they are not chased.
List<CarePlanItem> carePlanDueNow(List<CarePlanItem> mine, DateTime wallNow) {
  final now = wallNow.hour * 60 + wallNow.minute;
  return [
    for (final i in mine)
      if (carePlanMinutes(i.time) - now <= 5 &&
          now - carePlanMinutes(i.time) <= 60)
        i,
  ];
}

enum _DueAnswer { done, later, seeDay }

/// Watches for due tasks of the viewer and shows "Đến giờ rồi" when the app opens or comes back
/// (and when a task push was tapped). Never over the first-run tour ([blocked]), the launch
/// notification prompt (D-098), a sheet or another screen: it waits and looks again.
/// Draws nothing itself.
class CarePlanDueGate extends ConsumerStatefulWidget {
  const CarePlanDueGate({
    required this.blocked,
    required this.onTabRoot,
    super.key,
  });

  final bool blocked;

  /// Hôm nay's tab shows its root page (nothing pushed in the tab).
  final bool Function() onTabRoot;

  static const delay = Duration(milliseconds: 1200);
  static const retry = Duration(seconds: 3);

  @override
  ConsumerState<CarePlanDueGate> createState() => _CarePlanDueGateState();
}

class _CarePlanDueGateState extends ConsumerState<CarePlanDueGate> {
  Timer? _wait;
  bool _showing = false;

  /// The app was opened or came back: look once (a push request looks on its own).
  bool _look = true;

  late final AppLifecycleListener _life = AppLifecycleListener(
    onResume: () {
      _look = true;
      _schedule(CarePlanDueGate.delay);
    },
  );

  @override
  void initState() {
    super.initState();
    _life;
  }

  @override
  void dispose() {
    _wait?.cancel();
    _life.dispose();
    super.dispose();
  }

  bool _allowed({required bool fromPush}) {
    if (!mounted || _showing || widget.blocked) return false;
    final state = WidgetsBinding.instance.lifecycleState;
    final route = ModalRoute.of(context);
    return (state == null || state == AppLifecycleState.resumed) &&
        !ref.read(notificationsLaunchAskProvider).isLoading &&
        (route == null || route.isCurrent) &&
        (fromPush || widget.onTabRoot());
  }

  void _schedule(Duration after) {
    if (_wait != null || _showing) return;
    _wait = Timer(after, () {
      _wait = null;
      if (mounted) unawaited(_check());
    });
  }

  Future<void> _check() async {
    final me = ref.read(selectedMembershipProvider);
    if (me == null || !carePlanCanComplete(me)) return;
    final request = ref.read(carePlanDueRequestProvider);
    final memory = ref.read(carePlanDueMemoryProvider);
    final now = ref.read(careClockProvider).value ?? DateTime.now();
    if (request != null) {
      if (request.babyId != me.babyId) return;
      final items = ref.read(
        carePlanLiveItemsProvider((request.babyId, request.date)),
      );
      if (!items.hasValue) return _schedule(CarePlanDueGate.retry);
      if (!_allowed(fromPush: true)) return _schedule(CarePlanDueGate.retry);
      ref.read(carePlanDueRequestProvider.notifier).clear();
      final open = [
        for (final i in items.value!)
          if (request.ids.contains(i.id) && i.status == CarePlanStatus.open) i,
      ];
      if (open.isEmpty) {
        final l10n = AppLocalizations.of(context);
        unawaited(context.push(Routes.carePlan));
        ClToaster.of(context).show(message: l10n.cpDueGone);
        return;
      }
      return _show(me, request.date, open, memory, now);
    }
    if (!_look) return;
    final zone =
        ref.read(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final wall = inBabyZone(zone, now);
    final date = carePlanDateKey(wall);
    final items = ref.read(carePlanLiveItemsProvider((me.babyId, date)));
    if (!items.hasValue) return _schedule(CarePlanDueGate.retry);
    final due = [
      for (final i in carePlanDueNow(carePlanMine(items.value!, me.uid), wall))
        if (memory.due(CarePlanDueMemory.keyOf(me.babyId, date, i.id), now)) i,
    ];
    if (due.isEmpty) {
      _look = false;
      return;
    }
    if (!_allowed(fromPush: false)) return _schedule(CarePlanDueGate.retry);
    _look = false;
    return _show(me, date, due, memory, now);
  }

  Future<void> _show(
    Membership me,
    String date,
    List<CarePlanItem> items,
    CarePlanDueMemory memory,
    DateTime now,
  ) async {
    final keys = [
      for (final i in items) CarePlanDueMemory.keyOf(me.babyId, date, i.id),
    ];
    _showing = true;
    await memory.shown(keys);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    final members =
        ref.read(familyMembersProvider(me.babyId)).value ?? const [];
    final by = items.length == 1 ? items.single.assignedBy : null;
    final giver = by == null || by == me.uid
        ? null
        : members.where((m) => m.uid == by).firstOrNull;
    final answer = await showClSheet<_DueAnswer>(
      context: context,
      builder: (_) => CarePlanDueSheet(
        items: items,
        askedBy: giver,
        askedByLine: giver == null
            ? null
            : l10n.cpAskedBy(
                carePlanCapitalized(assigneeName(l10n, giver, me.uid)),
                relationLabel(l10n, me.relation, me.relationCustom ?? ''),
              ),
      ),
    );
    _showing = false;
    switch (answer) {
      case _DueAnswer.done:
        if (!mounted) return;
        await markCarePlanDone(
          ref,
          toaster,
          l10n,
          babyId: me.babyId,
          date: date,
          items: items,
          context: context,
        );
      case _DueAnswer.later:
        await memory.snooze(keys, now.add(const Duration(minutes: 10)));
      case _DueAnswer.seeDay:
        unawaited(router.push(Routes.carePlan));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(selectedMembershipProvider);
    if (me != null && carePlanCanComplete(me)) {
      // Started here so the check finds them loaded.
      ref.watch(
        carePlanLiveItemsProvider((
          me.babyId,
          carePlanTodayKey(ref, me.babyId),
        )),
      );
      ref.watch(notificationsLaunchAskProvider);
      final request = ref.watch(carePlanDueRequestProvider);
      if (request != null) {
        ref.watch(carePlanLiveItemsProvider((request.babyId, request.date)));
      }
      if (_look || request != null) _schedule(CarePlanDueGate.delay);
    }
    return const SizedBox.shrink();
  }
}

/// "Phân việc": a task that comes from the family plan (Figma 14 / 15).
class _PlanBadge extends StatelessWidget {
  const _PlanBadge();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: c.mintSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.family, size: 12, color: c.mintText),
          const SizedBox(width: ClSpace.s1),
          Text(
            AppLocalizations.of(context).cpAssignedBadge,
            style: cl.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: c.mintText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 15: "Đến giờ rồi · Phân việc", the task large (picture, time, name, who asked), then
/// Đã làm beside Để sau 10′, and "Xem cả lịch hôm nay →". Several tasks due together are listed;
/// the one button marks them all.
class CarePlanDueSheet extends StatelessWidget {
  const CarePlanDueSheet({
    required this.items,
    this.askedBy,
    this.askedByLine,
    super.key,
  });

  final List<CarePlanItem> items;

  /// Who gave the one task to the viewer, and the line saying so ("Mẹ nhờ Ba nhé").
  final Membership? askedBy;
  final String? askedByLine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final one = items.length == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: c.separator,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s1,
          children: [
            Semantics(
              header: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: c.sunshine,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClIcon(ClIcons.clock, size: 12, color: c.onWarm),
                    const SizedBox(width: ClSpace.s1),
                    Text(
                      l10n.cpDueTitle,
                      style: cl.text.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.onWarm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _PlanBadge(),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        if (one)
          Row(
            children: [
              CarePlanArt(items.single.task, size: 72),
              const SizedBox(width: ClSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items.single.time,
                      style: cl.text.title.copyWith(
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      carePlanTaskName(l10n, items.single),
                      style: cl.text.headline.copyWith(color: c.ink),
                    ),
                    if (askedByLine case final line?)
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s1),
                        child: Row(
                          children: [
                            if (askedBy case final m?) ...[
                              CarePlanAvatar(m, size: 20),
                              const SizedBox(width: ClSpace.s1),
                            ],
                            Flexible(
                              child: Text(
                                line,
                                style: cl.text.caption.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          )
        else
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ClSpace.s2),
                      child: CarePlanTaskCard(
                        item: i,
                        name: carePlanTaskName(l10n, i),
                        status: null,
                        people: const SizedBox.shrink(),
                        ring: null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s6),
        Row(
          children: [
            Expanded(
              child: ClButton(
                key: const Key('cpDueDone'),
                label: one
                    ? l10n.cpDoneAction
                    : l10n.cpDueDoneAll(items.length),
                expand: true,
                wrapLabel: true,
                onPressed: () => Navigator.of(context).pop(_DueAnswer.done),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: ClButton(
                key: const Key('cpDueLater'),
                label: l10n.cpDueLaterShort,
                style: ClButtonStyle.tinted,
                expand: true,
                wrapLabel: true,
                onPressed: () => Navigator.of(context).pop(_DueAnswer.later),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s1),
        Center(
          child: ClPressable(
            key: const Key('cpDueSeeDay'),
            onPressed: () => Navigator.of(context).pop(_DueAnswer.seeDay),
            semanticLabel: l10n.cpDueSeeDay,
            child: SizedBox(
              height: ClSpace.tapMin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.cpDueSeeDay,
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
      ],
    );
  }
}

/// The Bàn giao row on Hôm nay (D-135 Q1, Q2): "Cô Lan đang trông · đến 17:00" while a helper
/// (caregiver role) is on duty, until the time of their last task today (else "· từ 08:20").
/// Ba and Mẹ are never shown as caring, and nobody on duty shows nothing: null.
String? carePlanHelperOnDuty(
  WidgetRef ref,
  AppLocalizations l10n,
  Membership me,
) {
  final duty = ref.watch(careDutyProvider(me.babyId)).value;
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final since = duty?.since;
  if (duty?.uid == null ||
      since == null ||
      duty!.coCarerUid != null ||
      duty.uid == me.uid ||
      dutyAge(since, now) == DutyAge.stale) {
    return null;
  }
  final members = ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
  final helper = members.where((m) => m.uid == duty.uid).firstOrNull;
  if (helper == null ||
      helper.role != MemberRole.caregiver ||
      !helper.isActiveAt(now)) {
    return null;
  }
  final name = carePlanCapitalized(
    memberLabel(l10n, helper, myUid: me.uid, uid: helper.uid),
  );
  final zone =
      ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
      'Asia/Ho_Chi_Minh';
  final wall = inBabyZone(zone, now);
  final items =
      ref
          .watch(carePlanLiveItemsProvider((me.babyId, carePlanDateKey(wall))))
          .value ??
      const <CarePlanItem>[];
  final last = [
    for (final i in items)
      if (!i.skipped && i.assignees.contains(helper.uid)) i.time,
  ].fold<String?>(null, (a, t) => a == null || t.compareTo(a) > 0 ? t : a);
  if (last != null && carePlanMinutes(last) >= wall.hour * 60 + wall.minute) {
    return l10n.cpHelperOnUntil(name, last);
  }
  return l10n.dutyOnNow(
    name,
    DateFormat('HH:mm').format(inBabyZone(zone, since)),
  );
}
