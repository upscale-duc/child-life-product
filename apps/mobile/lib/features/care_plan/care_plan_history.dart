import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show careClockProvider, inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// How far back 20 Lịch sử thay đổi reads.
const _historyDays = 30;

/// 20 Lịch sử thay đổi (Figma 1360:23617): who changed the plan and when, grouped Hôm nay, Hôm
/// qua, then by date. Ticks (done / undone) are not changes to the plan and stay out. The latest
/// add or time change of a task still on an editable day has "Hoàn tác" for plan managers.
class CarePlanHistoryScreen extends ConsumerStatefulWidget {
  const CarePlanHistoryScreen({super.key});

  @override
  ConsumerState<CarePlanHistoryScreen> createState() =>
      _CarePlanHistoryScreenState();
}

class _CarePlanHistoryScreenState extends ConsumerState<CarePlanHistoryScreen> {
  /// Fixed when the screen opens, so the query does not change every minute.
  late final DateTime _since = DateTime.now().subtract(
    const Duration(days: _historyDays),
  );
  final _undoing = <String>{};

  Future<void> _undo(Membership me, CarePlanChange c, CarePlanItem item) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final repo = ref.read(carePlanRepositoryProvider);
    setState(() => _undoing.add(c.id));
    try {
      if (c.action == 'add') {
        await repo.deleteItem(
          me.babyId,
          c.date,
          item.id,
          everyDay: c.scope == 'everyDay',
        );
      } else {
        await repo.saveItem(
          me.babyId,
          c.date,
          itemId: item.id,
          task: item.task,
          title: item.title,
          time: c.oldTime!,
          assignees: item.assignees,
          everyDay: item.everyDay,
          amountMl: item.amountMl,
        );
      }
      toaster.show(message: l10n.cpHistUndone);
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _undoing.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: c.cloud);
    final babyId = me.babyId;
    final zone =
        ref.watch(babyProvider(babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final todayWall = DateUtils.dateOnly(inBabyZone(zone, now));
    final today = carePlanDateKey(todayWall);
    final yesterday = carePlanDateKey(
      todayWall.subtract(const Duration(days: 1)),
    );
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];
    final async = ref.watch(carePlanHistoryProvider((babyId, _since)));
    final manage = carePlanCanManage(me);

    // Tasks of the editable days, for Hoàn tác.
    final items = {
      for (final d in [today, yesterday])
        for (final i
            in ref.watch(carePlanItemsProvider((babyId, d))).value ??
                const <CarePlanItem>[])
          (d, i.id): i,
    };
    final changes = [
      for (final ch in async.value ?? const <CarePlanChange>[])
        if (!{'done', 'undone'}.contains(ch.action)) ch,
    ];
    // Only the latest change of a task can be undone.
    final latest = <String>{};
    final seen = <String>{};
    for (final ch in changes) {
      for (final id in ch.itemIds) {
        if (seen.add('${ch.date}/$id')) latest.add('${ch.id}/$id');
      }
    }

    String who(String uid) => uid == 'system'
        ? 'Child Life'
        : carePlanCapitalized(
            carePlanPersonName(l10n, members, uid, me.uid) ??
                l10n.cpHistSomeone,
          );

    final groups = <(String, List<CarePlanChange>)>[];
    for (final ch in changes) {
      final local = inBabyZone(zone, ch.at);
      final key = carePlanDateKey(DateUtils.dateOnly(local));
      final label = key == today
          ? l10n.cpHistToday
          : key == yesterday
          ? l10n.cpHistYesterday
          : DateFormat.MMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(local);
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add(ch);
    }

    final List<Widget> body;
    if (async.hasError && !async.hasValue) {
      body = [
        MeNotice(
          tone: MeTone.error,
          icon: ClIcons.cloudOff,
          title: l10n.cpLoadFailed,
          onTap: () =>
              ref.invalidate(carePlanHistoryProvider((babyId, _since))),
        ),
      ];
    } else if (!async.hasValue) {
      body = const [ClSkeleton(height: 3 * 72, radius: ClRadius.card)];
    } else if (changes.isEmpty) {
      body = [
        Padding(
          padding: const EdgeInsets.only(top: ClSpace.s8),
          child: ClEmptyState(
            icon: ClIcons.journal,
            title: l10n.cpHistEmpty,
            message: l10n.cpHistEmptyBody,
          ),
        ),
      ];
    } else {
      body = [
        for (final (label, list) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, ClSpace.s4, 0, ClSpace.s2),
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: cl.text.label.copyWith(color: c.inkMuted),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(ClRadius.card),
              boxShadow: cl.shadows.card,
            ),
            child: Column(
              children: [
                for (final (i, ch) in list.indexed) ...[
                  if (i > 0) Container(height: 1, color: c.separator),
                  () {
                    final id = ch.itemIds.length == 1
                        ? ch.itemIds.single
                        : null;
                    final item = id == null ? null : items[(ch.date, id)];
                    final canUndo =
                        manage &&
                        item != null &&
                        latest.contains('${ch.id}/$id') &&
                        (ch.action == 'add' ||
                            (ch.action == 'edit' &&
                                ch.oldTime != null &&
                                item.time == ch.time));
                    return _ChangeRow(
                      key: ValueKey('cpHist_${ch.id}'),
                      change: ch,
                      member: members.where((m) => m.uid == ch.by).firstOrNull,
                      text: _describe(l10n, ch, who),
                      time: DateFormat.Hm().format(inBabyZone(zone, ch.at)),
                      busy: _undoing.contains(ch.id),
                      onUndo: canUndo
                          ? () => unawaited(_undo(me, ch, item))
                          : null,
                    );
                  }(),
                ],
              ],
            ),
          ),
        ],
      ];
    }
    return CarePlanPage(title: l10n.cpHistTitle, children: body);
  }
}

/// The change in words: "Bú bình 13:00 → 13:30", "Thêm “Đọc sách” 20:00 · mọi ngày".
String _describe(
  AppLocalizations l10n,
  CarePlanChange c,
  String Function(String uid) who,
) {
  final task = c.task == null
      ? ''
      : c.task == CarePlanTask.custom && (c.title ?? '').isNotEmpty
      ? c.title!
      : carePlanTaskLabel(l10n, c.task!);
  final time = c.time ?? '';
  final every = c.scope == 'everyDay';
  return switch (c.action) {
    'edit' when c.oldTime != null => l10n.cpHistMoved(task, c.oldTime!, time),
    'edit' => l10n.cpHistEdited(task, time),
    'add' =>
      every
          ? '${l10n.cpHistAdded(task, time)} · ${l10n.cpHistEveryDay}'
          : l10n.cpHistAdded(task, time),
    'delete' =>
      '${l10n.cpHistDeleted(task, time)} · '
          '${every ? l10n.cpHistEveryDay : l10n.cpHistThatDay}',
    'assign' when (c.assignees ?? const []).isEmpty => l10n.cpHistUnassigned(
      task,
    ),
    'assign' => () {
      final names = carePlanNames(l10n, [for (final u in c.assignees!) who(u)]);
      return c.itemIds.length == 1 && task.isNotEmpty
          ? l10n.cpHistAssigned(task, names)
          : l10n.cpHistAssignedMany(c.itemIds.length, names);
    }(),
    'skip' => l10n.cpHistSkipped(task, time),
    'start' when c.by == 'system' => l10n.cpHistAutoDraft,
    'start' => l10n.cpHistStarted(_wayName(l10n, c.from)),
    'publish' => l10n.cpHistPublished,
    _ => c.action,
  };
}

String _wayName(AppLocalizations l10n, String? from) => switch (from) {
  'rhythm' => l10n.cpDraftFromRhythm,
  'everyday' => l10n.cpStartEveryday,
  'yesterday' => l10n.cpStartYesterday,
  'basic' => l10n.cpByAge,
  'easy35' => l10n.cpStartEasy35,
  'easy4' => l10n.cpStartEasy4,
  _ => l10n.cpSelfMade,
};

/// One change: the person's face with what they did as a small badge, the words, the time, and
/// "Hoàn tác" where it can be undone.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.change,
    required this.member,
    required this.text,
    required this.time,
    required this.busy,
    required this.onUndo,
    super.key,
  });

  final CarePlanChange change;
  final Membership? member;
  final String text;
  final String time;
  final bool busy;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final badge = switch (change.action) {
      'add' => ClIcons.plus,
      'delete' => ClIcons.close,
      'assign' => ClIcons.family,
      'skip' => ClIcons.arrowRight,
      'start' || 'publish' => ClIcons.check,
      _ => ClIcons.edit,
    };
    final face = member != null
        ? CarePlanAvatar(member!, size: 40)
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(
              change.by == 'system' ? ClIcons.brandMark : ClIcons.profile,
              size: 20,
              color: c.mintText,
            ),
          );
    return Semantics(
      label: '$text, $time',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  children: [
                    face,
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: ClIcon(badge, size: 12, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "13:00 → 13:30": the arrow is an icon (the app font has no →).
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final (i, part)
                              in text.split(' → ').indexed) ...[
                            if (i > 0)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ClSpace.s1,
                                  ),
                                  child: ClIcon(
                                    ClIcons.arrowRight,
                                    size: 14,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                            TextSpan(text: part),
                          ],
                        ],
                      ),
                      style: cl.text.body.copyWith(color: c.ink),
                    ),
                    Text(
                      time,
                      style: cl.text.caption.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onUndo != null)
              ClPressable(
                key: ValueKey('cpHistUndo_${change.id}'),
                onPressed: busy ? null : onUndo,
                semanticLabel: l10n.cpHistUndo,
                child: SizedBox(
                  height: ClSpace.tapMin,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClIcon(ClIcons.retry, size: 14, color: c.mintText),
                      const SizedBox(width: 2),
                      Text(
                        l10n.cpHistUndo,
                        style: cl.text.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.mintText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
