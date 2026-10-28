import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/experience_repository.dart' show childBandProvider;
import '../assistant/assistant_editor.dart' show pickAssistantTime;
import '../baby/baby_models.dart';
import '../reminders/reminder_screens.dart' show assigneeName;
import '../rhythm/rhythm_widgets.dart' show rhConfirm;
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// 05 Giao việc: who does [itemIds] (one task, or a whole group). Several people make one shared
/// task ("Ba và Mẹ cùng làm"). Returns the chosen uids, or null when closed. Only one task may be
/// left with nobody ([allowNobody]): "Giao cả buổi" never clears a whole group by one tap.
Future<List<String>?> showCarePlanAssign(
  BuildContext context, {
  required String title,
  required List<Membership> people,
  required List<String> initial,
  required Map<String, int> load,
  required String meUid,
  bool allowNobody = true,
}) => showClSheet<List<String>>(
  context: context,
  builder: (_) => _AssignSheet(
    title: title,
    people: people,
    initial: initial,
    load: load,
    meUid: meUid,
    allowNobody: allowNobody,
  ),
);

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({
    required this.title,
    required this.people,
    required this.initial,
    required this.load,
    required this.meUid,
    required this.allowNobody,
  });

  final String title;
  final List<Membership> people;
  final List<String> initial;
  final Map<String, int> load;
  final String meUid;
  final bool allowNobody;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late final _chosen = <String>{
    for (final u in widget.initial)
      if (widget.people.any((m) => m.uid == u)) u,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = [
      for (final m in widget.people)
        if (_chosen.contains(m.uid)) assigneeName(l10n, m, widget.meUid),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: widget.title),
        Flexible(
          child: SingleChildScrollView(
            child: ClCardGroup(
              shadow: false,
              color: context.cl.colors.surface2,
              children: [
                for (final m in widget.people)
                  ClOptionRow(
                    key: ValueKey('cp_assign_${m.uid}'),
                    title: carePlanCapitalized(
                      assigneeName(l10n, m, widget.meUid),
                    ),
                    subtitle: l10n.cpMemberLoad(widget.load[m.uid] ?? 0),
                    selected: _chosen.contains(m.uid),
                    onTap: () => setState(() {
                      if (!_chosen.remove(m.uid)) _chosen.add(m.uid);
                    }),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('cp_assign_confirm'),
          label: names.isNotEmpty
              ? l10n.cpAssignTo(carePlanNames(l10n, names))
              : widget.allowNobody
              ? l10n.cpAssignNobody
              : l10n.cpAssignGroup,
          expand: true,
          onPressed: names.isEmpty && !widget.allowNobody
              ? null
              : () => Navigator.of(context).pop([
                  for (final m in widget.people)
                    if (_chosen.contains(m.uid)) m.uid,
                ]),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// 06 Thêm việc / 06b Sửa việc. Saves through the plan Functions and closes when the server has
/// it; a failure keeps the sheet open with a toast. Editing also offers "Bỏ qua hôm nay" and
/// "Xoá việc" ([onSkip], [onDelete]: the sheet closes first, the screen does the rest).
Future<void> showCarePlanEditor(
  BuildContext context, {
  required String babyId,
  required String date,
  required List<Membership> people,
  required String meUid,
  CarePlanItem? item,
  CarePlanPeriod? period,
  VoidCallback? onSkip,
  VoidCallback? onDelete,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _EditorSheet(
    babyId: babyId,
    date: date,
    people: people,
    meUid: meUid,
    item: item,
    period: period,
    onSkip: onSkip,
    onDelete: onDelete,
  ),
);

class _EditorSheet extends ConsumerStatefulWidget {
  const _EditorSheet({
    required this.babyId,
    required this.date,
    required this.people,
    required this.meUid,
    this.item,
    this.period,
    this.onSkip,
    this.onDelete,
  });

  final String babyId;
  final String date;
  final List<Membership> people;
  final String meUid;
  final CarePlanItem? item;
  final CarePlanPeriod? period;
  final VoidCallback? onSkip;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends ConsumerState<_EditorSheet> {
  late CarePlanTask? _task = widget.item?.task;
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late String _time =
      widget.item?.time ??
      (widget.period ?? CarePlanPeriod.morning).defaultTime;
  late final _who = <String>{...?widget.item?.assignees};
  late bool _everyDay = widget.item?.everyDay ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid =>
      _task != null &&
      (_task != CarePlanTask.custom || _title.text.trim().isNotEmpty);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(carePlanRepositoryProvider)
          .saveItem(
            widget.babyId,
            widget.date,
            itemId: widget.item?.id ?? newCarePlanItemId(),
            task: _task!,
            title: _title.text.trim(),
            time: _time,
            assignees: [
              for (final m in widget.people)
                if (_who.contains(m.uid)) m.uid,
            ],
            everyDay: _everyDay,
          );
      nav.pop();
    } on Object {
      if (mounted) setState(() => _saving = false);
      toaster.show(message: l10n.cpSaveFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final editing = widget.item != null;
    final suggested = carePlanSuggested(
      ref.watch(childBandProvider(widget.babyId)),
    );
    final rest = [
      for (final t in CarePlanTask.values)
        if (!suggested.contains(t)) t,
    ];

    Widget picker(List<CarePlanTask> tasks) => Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final t in tasks)
          _TaskChoice(
            task: t,
            label: carePlanTaskLabel(l10n, t),
            selected: _task == t,
            onTap: () => setState(() => _task = t),
          ),
      ],
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontWeight: FontWeight.w600,
          color: cl.colors.inkMuted,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: editing ? l10n.cpEditTask : l10n.cpAddTask),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label(l10n.cpSuggested),
                picker(suggested),
                label(l10n.cpMoreTasks),
                picker(rest),
                if (_task == CarePlanTask.custom) ...[
                  const SizedBox(height: ClSpace.s4),
                  ClTextField(
                    key: const Key('cp_custom_name'),
                    label: l10n.cpCustomName,
                    placeholder: l10n.cpCustomHint,
                    controller: _title,
                    standalone: true,
                    maxLength: 60,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: ClSpace.s4),
                ClCardGroup(
                  shadow: false,
                  color: cl.colors.surface2,
                  children: [
                    ClTimeRow(
                      label: l10n.cpTime,
                      value: _time,
                      onTap: () async {
                        final t = await pickAssistantTime(
                          context,
                          initial: _time,
                        );
                        if (t != null && mounted) setState(() => _time = t);
                      },
                    ),
                  ],
                ),
                label(l10n.cpWho),
                Wrap(
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s2,
                  children: [
                    for (final m in widget.people)
                      ClRelationChip(
                        key: ValueKey('cp_who_${m.uid}'),
                        label: carePlanCapitalized(
                          assigneeName(l10n, m, widget.meUid),
                        ),
                        selected: _who.contains(m.uid),
                        onTap: () => setState(() {
                          if (!_who.remove(m.uid)) _who.add(m.uid);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
                ClSegmented<bool>(
                  options: const [false, true],
                  selected: _everyDay,
                  onChanged: (v) => setState(() => _everyDay = v),
                  labelOf: (v) => v ? l10n.cpEveryDay : l10n.cpTodayOnly,
                ),
                if (editing) ...[
                  if (widget.onSkip case final skip?) ...[
                    const SizedBox(height: ClSpace.s4),
                    ClButton(
                      key: const Key('cp_editor_skip'),
                      label: widget.item!.skipped
                          ? l10n.cpUnskip
                          : l10n.cpSkipToday,
                      style: ClButtonStyle.secondary,
                      expand: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        skip();
                      },
                    ),
                  ],
                  if (widget.onDelete case final delete?) ...[
                    const SizedBox(height: ClSpace.s2),
                    ClButton(
                      key: const Key('cp_editor_delete'),
                      label: l10n.cpDelete,
                      style: ClButtonStyle.destructive,
                      expand: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        delete();
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('cp_editor_save'),
          label: editing ? l10n.actionSave : l10n.cpAddTask,
          expand: true,
          loading: _saving,
          onPressed: _valid ? _save : null,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// One task in the 06 picker: its picture over its name; the chosen one has a mint edge.
class _TaskChoice extends StatelessWidget {
  const _TaskChoice({
    required this.task,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CarePlanTask task;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      key: ValueKey('cp_task_${task.name}'),
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(ClRadius.control + 4),
          border: Border.all(
            color: selected ? c.mintDeep : c.separator,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarePlanArt(task, size: 40),
            const SizedBox(height: ClSpace.s1),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete confirm: an everyday task asks whether to keep it for the days to come. Returns the
/// scope (`true` = every day), or null when cancelled.
Future<bool?> confirmCarePlanDelete(
  BuildContext context, {
  required String name,
  required bool everyDay,
}) async {
  final l10n = AppLocalizations.of(context);
  if (!everyDay) {
    final ok = await rhConfirm(
      context,
      title: l10n.cpDeleteTitle(name),
      body: l10n.cpDeleteBody,
      confirm: l10n.cpDelete,
      cancel: l10n.actionCancel,
      destructive: true,
    );
    return ok ? false : null;
  }
  return showClSheet<bool>(
    context: context,
    builder: (sheet) {
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.cpDeleteTitle(name)),
          Text(
            l10n.cpDeleteBody,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            key: const Key('cp_delete_today'),
            label: l10n.cpDeleteToday,
            expand: true,
            style: ClButtonStyle.destructive,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            key: const Key('cp_delete_everyday'),
            label: l10n.cpDeleteEveryDay,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.actionCancel,
            expand: true,
            style: ClButtonStyle.plain,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
      );
    },
  );
}
