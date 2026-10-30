import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/experience_repository.dart' show childBandProvider;
import '../assistant/assistant_editor.dart' show pickAssistantTime;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import '../reminders/reminder_screens.dart' show assigneeName;
import '../rhythm/rhythm_widgets.dart' show rhConfirm;
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// 05 Giao việc (Figma 1381:22083): who does a whole part of the day ([group]) or one task. One
/// person by default; "Nhiều người" picks several for one task, and for a part of the day closes
/// the sheet so each task is given on its own. Returns the chosen uids, or null when closed. Only
/// one task may be left with nobody ([allowNobody]): a whole part is never cleared by one tap.
Future<List<String>?> showCarePlanAssign(
  BuildContext context, {
  required String title,
  required List<Membership> people,
  required List<String> initial,
  required Map<String, int> load,
  required String meUid,
  bool allowNobody = true,
  Widget? leading,
  String? subtitle,
  bool group = false,
  Future<bool> Function(List<String> chosen)? onSave,
}) => showClSheet<List<String>>(
  context: context,
  builder: (_) => _AssignSheet(
    title: title,
    people: people,
    initial: initial,
    load: load,
    meUid: meUid,
    allowNobody: allowNobody,
    leading: leading,
    subtitle: subtitle,
    group: group,
    onSave: onSave,
  ),
);

/// A Cùng Chăm Con sheet's top: grabber, a picture, the title with a line under it, and ✕.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.leading, this.subtitle});

  final String title;
  final Widget? leading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
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
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: ClSpace.s3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: cl.text.headline.copyWith(color: c.ink),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: cl.text.label.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            ClPressable(
              onPressed: () => Navigator.of(context).maybePop(),
              semanticLabel: AppLocalizations.of(context).a11yClose,
              child: SizedBox.square(
                dimension: ClSpace.tapMin,
                child: Center(
                  child: ClIcon(ClIcons.close, size: 22, color: c.ink),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
    );
  }
}

/// A part of the day's picture for a sheet header: its icon on a tinted circle.
Widget carePlanPeriodBadge(
  BuildContext context,
  CarePlanPeriod p, {
  double size = 40,
}) {
  final cl = context.cl;
  final c = cl.colors;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: switch (p) {
        CarePlanPeriod.morning => c.sunshineSoft,
        CarePlanPeriod.afternoon => c.mintSoft,
        CarePlanPeriod.evening => cl.care.sleep.soft,
      },
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: ClIcon(carePlanPeriodIcon(p), size: size * 0.5, color: c.ink),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({
    required this.title,
    required this.people,
    required this.initial,
    required this.load,
    required this.meUid,
    required this.allowNobody,
    required this.group,
    this.leading,
    this.subtitle,
    this.onSave,
  });

  final String title;
  final List<Membership> people;
  final List<String> initial;
  final Map<String, int> load;
  final String meUid;
  final bool allowNobody;
  final bool group;
  final Widget? leading;
  final String? subtitle;

  /// Saves the choice while the sheet stays open with its button loading; the sheet closes
  /// once it returns true (a failure says so and keeps the choice).
  final Future<bool> Function(List<String> chosen)? onSave;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late final _chosen = <String>{
    for (final u in widget.initial)
      if (widget.people.any((m) => m.uid == u)) u,
  };
  late bool _many = !widget.group && _chosen.length > 1;
  bool _saving = false;

  Future<void> _confirm() async {
    final chosen = [
      for (final m in widget.people)
        if (_chosen.contains(m.uid)) m.uid,
    ];
    final save = widget.onSave;
    if (save == null) return Navigator.of(context).pop(chosen);
    setState(() => _saving = true);
    final ok = await save(chosen);
    if (!mounted) return;
    if (ok) return Navigator.of(context).pop(chosen);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final names = [
      for (final m in widget.people)
        if (_chosen.contains(m.uid)) assigneeName(l10n, m, widget.meUid),
    ];

    Widget card({
      required Key key,
      required Widget leading,
      required String title,
      required String subtitle,
      required bool selected,
      required Widget trailing,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: ClPressable(
        key: key,
        onPressed: onTap,
        selected: selected,
        semanticLabel: '$title, $subtitle',
        pressedOpacity: ClPressable.surfaceOpacity,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s3,
            ClSpace.s3,
            ClSpace.s4,
            ClSpace.s3,
          ),
          decoration: BoxDecoration(
            color: selected ? c.mintSoft : c.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            border: Border.all(
              color: selected ? c.mintDeep : c.separator,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.bodyStrong.copyWith(color: c.ink),
                    ),
                    Text(
                      subtitle,
                      style: cl.text.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              trailing,
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: widget.title,
          leading: widget.leading,
          subtitle: widget.subtitle,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in widget.people)
                  card(
                    key: ValueKey('cp_assign_${m.uid}'),
                    leading: CarePlanAvatar(m, size: 48),
                    title: carePlanCapitalized(
                      assigneeName(l10n, m, widget.meUid),
                    ),
                    subtitle: l10n.cpMemberLine(
                      relationLabel(l10n, m.relation, m.relationCustom ?? ''),
                      l10n.cpMemberLoad(widget.load[m.uid] ?? 0),
                    ),
                    selected: _chosen.contains(m.uid),
                    trailing: ClRadio(selected: _chosen.contains(m.uid)),
                    onTap: () => setState(() {
                      if (_many) {
                        if (!_chosen.remove(m.uid)) _chosen.add(m.uid);
                      } else if (_chosen.length == 1 &&
                          _chosen.contains(m.uid)) {
                        _chosen.clear();
                      } else {
                        _chosen
                          ..clear()
                          ..add(m.uid);
                      }
                    }),
                  ),
                if (widget.people.length > 1)
                  card(
                    key: const Key('cp_assign_many'),
                    leading: SizedBox(
                      width: 48,
                      child: CarePlanFaces(widget.people, size: 32),
                    ),
                    title: l10n.cpManyPeople,
                    subtitle: widget.group
                        ? l10n.cpManyPeopleGroup
                        : l10n.cpManyPeopleTask,
                    selected: _many,
                    trailing: ClIcon(
                      widget.group ? ClIcons.chevronRight : ClIcons.chevronDown,
                      size: 18,
                      color: c.inkMuted,
                    ),
                    onTap: () {
                      // A part of the day: each task gets its own people on the plan.
                      if (widget.group) {
                        Navigator.of(context).pop();
                        return;
                      }
                      setState(() => _many = !_many);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          key: const Key('cp_assign_confirm'),
          label: names.isNotEmpty
              ? l10n.cpAssignTo(carePlanNames(l10n, names))
              : widget.allowNobody
              ? l10n.cpAssignNobody
              : l10n.cpAssignGroup,
          expand: true,
          loading: _saving,
          onPressed: names.isEmpty && !widget.allowNobody
              ? null
              : () => unawaited(_confirm()),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// 06 Thêm việc (Figma 1381:22208) and 06b Sửa / xoá việc (1360:23266). Adding: search, the tasks
/// usual at this age as tiles, the rest by group as chips, "+ Tạo việc riêng", the time, who and
/// whether it repeats. Editing: the task's picture and name on top, then time, who, repeat, a
/// gentle "Bỏ qua hôm nay cũng được", and Lưu beside Xoá. Saves through the plan Functions and
/// closes when the server has it; a failure keeps the sheet open with a toast. [onSkip] and
/// [onDelete]: the sheet closes first, the screen does the rest.
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
  Map<String, int> load = const {},
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
    load: load,
  ),
);

class _EditorSheet extends ConsumerStatefulWidget {
  const _EditorSheet({
    required this.babyId,
    required this.date,
    required this.people,
    required this.meUid,
    required this.load,
    this.item,
    this.period,
    this.onSkip,
    this.onDelete,
  });

  final String babyId;
  final String date;
  final List<Membership> people;
  final String meUid;
  final Map<String, int> load;
  final CarePlanItem? item;
  final CarePlanPeriod? period;
  final VoidCallback? onSkip;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_EditorSheet> createState() => _EditorSheetState();
}

/// 06's groups, after the tiles for the child's age.
const _foodTasks = [
  CarePlanTask.bottle,
  CarePlanTask.breast,
  CarePlanTask.pump,
  CarePlanTask.solids,
  CarePlanTask.water,
];
const _playTasks = [CarePlanTask.tummy, CarePlanTask.read, CarePlanTask.walk];
const _careTasks = [
  CarePlanTask.sleep,
  CarePlanTask.diaper,
  CarePlanTask.bath,
  CarePlanTask.vitamin,
  CarePlanTask.medicine,
  CarePlanTask.temperature,
  CarePlanTask.teeth,
  CarePlanTask.potty,
];

class _EditorSheetState extends ConsumerState<_EditorSheet> {
  late CarePlanTask? _task = widget.item?.task;
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  final _query = TextEditingController();
  late String _time =
      widget.item?.time ??
      (widget.period ?? CarePlanPeriod.morning).defaultTime;
  late final _who = <String>{...?widget.item?.assignees};
  late bool _everyDay = widget.item?.everyDay ?? false;

  /// D-138: the planned ml of a bottle or pumping; the log opens with it.
  late int? _ml = widget.item?.amountMl;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _query.dispose();
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
            amountMl: carePlanAmountTasks.contains(_task) ? _ml : null,
          );
      nav.pop();
    } on Object {
      if (mounted) setState(() => _saving = false);
      toaster.show(message: l10n.cpSaveFailed, error: true);
    }
  }

  Future<void> _pickTime() async {
    final t = await pickAssistantTime(context, initial: _time);
    if (t != null && mounted) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) =>
      widget.item == null ? _add(context) : _edit(context);

  Widget _label(String text, {ClIcons? icon}) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
      child: Row(
        children: [
          if (icon != null) ...[
            ClIcon(icon, size: 14, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s1),
          ],
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  /// "Giờ  [18:30] [☾ Tối]": the time pill opens the picker; the part of the day follows it.
  Widget _timeRow() {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final p = CarePlanPeriod.ofTime(_time);
    return Row(
      children: [
        ClIcon(ClIcons.clock, size: 22, color: c.ink),
        const SizedBox(width: ClSpace.s2),
        Expanded(
          child: Text(
            l10n.cpTime,
            style: cl.text.bodyStrong.copyWith(color: c.ink),
          ),
        ),
        _Pill(
          key: const Key('cp_editor_time'),
          label: _time,
          onTap: _pickTime,
          semanticLabel: '${l10n.cpTime} $_time',
        ),
        const SizedBox(width: ClSpace.s2),
        _Pill(
          label: carePlanPeriodLabel(l10n, p),
          icon: carePlanPeriodIcon(p),
          tint: switch (p) {
            CarePlanPeriod.morning => c.sunshineSoft,
            CarePlanPeriod.afternoon => c.mintSoft,
            CarePlanPeriod.evening => cl.care.sleep.soft,
          },
        ),
      ],
    );
  }

  /// "Lượng": none (the log asks) or a planned ml, as chips.
  Widget _amountChips() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final ml in <int?>[null, ...carePlanMlPresets, ?_customMl])
          ClRelationChip(
            key: ValueKey('cp_ml_${ml ?? 0}'),
            label: ml == null ? l10n.cpNoAmount : l10n.cpMl(ml),
            selected: _ml == ml,
            onTap: () => setState(() => _ml = ml),
          ),
      ],
    );
  }

  /// A planned ml from before that is not a preset stays choosable.
  int? get _customMl {
    final ml = widget.item?.amountMl;
    return ml == null || carePlanMlPresets.contains(ml) ? null : ml;
  }

  Widget _applyChips() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final every in [false, true])
          ClRelationChip(
            key: ValueKey('cp_apply_$every'),
            label: every ? l10n.cpEveryDay : l10n.cpTodayOnly,
            selected: _everyDay == every,
            onTap: () => setState(() => _everyDay = every),
          ),
      ],
    );
  }

  Widget _add(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final suggested = carePlanSuggested(
      ref.watch(childBandProvider(widget.babyId)),
    ).take(4).toList();
    final dob = ref
        .watch(babyPrivateProfileProvider(widget.babyId))
        .value
        ?.dateOfBirth;
    final age = dob == null
        ? null
        : ageShort(l10n, dob, DateTime.parse(widget.date));
    final q = _query.text.trim().toLowerCase();
    bool matches(CarePlanTask t) =>
        q.isEmpty || carePlanTaskLabel(l10n, t).toLowerCase().contains(q);
    final groups = [
      (l10n.cpCatFood, _foodTasks),
      (l10n.cpCatPlay, _playTasks),
      (l10n.cpCatCare, _careTasks),
    ];

    Widget chips(List<CarePlanTask> tasks) => Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final t in tasks)
          ClRelationChip(
            key: ValueKey('cp_task_${t.name}'),
            label: carePlanTaskLabel(l10n, t),
            selected: _task == t,
            onTap: () => setState(() => _task = t),
          ),
      ],
    );

    final found = [
      for (final t in CarePlanTask.values)
        if (t != CarePlanTask.custom && matches(t)) t,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: l10n.cpAddTask),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBox(
                  controller: _query,
                  placeholder: l10n.cpSearchTask,
                  onChanged: () => setState(() {}),
                ),
                if (q.isEmpty) ...[
                  _label(
                    age == null ? l10n.cpSuggested : l10n.cpSuggestedFor(age),
                    icon: ClIcons.spark,
                  ),
                  Row(
                    children: [
                      for (final (i, t) in suggested.indexed) ...[
                        if (i > 0) const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: _TaskTile(
                            task: t,
                            label: carePlanTaskLabel(l10n, t),
                            selected: _task == t,
                            onTap: () => setState(() => _task = t),
                          ),
                        ),
                      ],
                      for (var i = suggested.length; i < 4; i++) ...[
                        const SizedBox(width: ClSpace.s2),
                        const Expanded(child: SizedBox()),
                      ],
                    ],
                  ),
                  for (final (name, tasks) in groups)
                    if (tasks.where((t) => !suggested.contains(t)).toList()
                        case final rest when rest.isNotEmpty) ...[
                      _label(name),
                      chips(rest),
                    ],
                ] else ...[
                  const SizedBox(height: ClSpace.s3),
                  if (found.isEmpty)
                    Text(
                      l10n.cpNoTaskFound,
                      style: cl.text.label.copyWith(color: c.inkMuted),
                    )
                  else
                    chips(found),
                ],
                const SizedBox(height: ClSpace.s3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _DashedChip(
                    key: const ValueKey('cp_task_custom'),
                    label: l10n.cpCreateOwn,
                    selected: _task == CarePlanTask.custom,
                    onTap: () => setState(() => _task = CarePlanTask.custom),
                  ),
                ),
                if (_task == CarePlanTask.custom) ...[
                  const SizedBox(height: ClSpace.s3),
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
                Container(height: 1, color: c.separator),
                const SizedBox(height: ClSpace.s3),
                _timeRow(),
                if (carePlanAmountTasks.contains(_task)) ...[
                  _label(l10n.cpAmount),
                  _amountChips(),
                ],
                _label(l10n.cpWho),
                Wrap(
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s2,
                  children: [
                    for (final m in widget.people)
                      _PersonChip(
                        key: ValueKey('cp_who_${m.uid}'),
                        member: m,
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
                _label(l10n.cpApply),
                _applyChips(),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('cp_editor_save'),
          label: l10n.cpAddToPlan,
          expand: true,
          loading: _saving,
          onPressed: _valid ? _save : null,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }

  Widget _edit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final item = widget.item!;
    final who = [
      for (final m in widget.people)
        if (_who.contains(m.uid)) m,
    ];
    final whoNames = [for (final m in who) assigneeName(l10n, m, widget.meUid)];

    Widget row(
      ClIcons icon,
      String label,
      Widget trailing, {
      VoidCallback? onTap,
      Key? key,
    }) {
      final r = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 18, color: c.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                label,
                style: cl.text.bodyStrong.copyWith(color: c.ink),
              ),
            ),
            trailing,
          ],
        ),
      );
      if (onTap == null) return r;
      return ClPressable(
        key: key,
        onPressed: onTap,
        semanticLabel: label,
        child: r,
      );
    }

    final separator = Container(height: 1, color: c.separator);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: carePlanTaskName(l10n, item),
          subtitle: carePlanCapitalized(
            l10n.cpShiftOf(
              carePlanPeriodLabel(
                l10n,
                CarePlanPeriod.ofTime(_time),
              ).toLowerCase(),
            ),
          ),
          leading: CarePlanArt(item.task),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.task == CarePlanTask.custom) ...[
                  ClTextField(
                    key: const Key('cp_custom_name'),
                    label: l10n.cpCustomName,
                    placeholder: l10n.cpCustomHint,
                    controller: _title,
                    standalone: true,
                    maxLength: 60,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ClSpace.s3),
                ],
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s1,
                    ClSpace.s3,
                    ClSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(ClRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      row(
                        ClIcons.clock,
                        l10n.cpTime,
                        _Pill(
                          label: _time,
                          onTap: _pickTime,
                          semanticLabel: '${l10n.cpTime} $_time',
                          light: true,
                        ),
                        key: const Key('cp_editor_time'),
                      ),
                      separator,
                      row(
                        ClIcons.family,
                        l10n.cpDoer,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (who.isEmpty)
                              Text(
                                l10n.cpAssignShort,
                                style: cl.text.label.copyWith(
                                  color: c.mintText,
                                ),
                              )
                            else
                              _Pill(
                                label: carePlanCapitalized(
                                  carePlanNames(l10n, whoNames),
                                ),
                                leading: CarePlanFaces(who),
                                light: true,
                              ),
                            const SizedBox(width: ClSpace.s2),
                            ClIcon(ClIcons.chevronDown, size: 18, color: c.ink),
                          ],
                        ),
                        key: const Key('cp_editor_who'),
                        onTap: () async {
                          final chosen = await showCarePlanAssign(
                            context,
                            title: l10n.cpAssignWhoTask,
                            people: widget.people,
                            initial: _who.toList(),
                            load: widget.load,
                            meUid: widget.meUid,
                            leading: CarePlanArt(item.task, size: 40),
                          );
                          if (chosen != null && mounted) {
                            setState(
                              () => _who
                                ..clear()
                                ..addAll(chosen),
                            );
                          }
                        },
                      ),
                      if (carePlanAmountTasks.contains(item.task)) ...[
                        separator,
                        row(ClIcons.feed, l10n.cpAmount, const SizedBox()),
                        _amountChips(),
                        const SizedBox(height: ClSpace.s3),
                      ],
                      separator,
                      row(ClIcons.retry, l10n.cpApply, const SizedBox()),
                      _applyChips(),
                    ],
                  ),
                ),
                if (widget.onSkip case final skip?) ...[
                  const SizedBox(height: ClSpace.s4),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      ClSpace.s4,
                      ClSpace.s1,
                      ClSpace.s2,
                      ClSpace.s1,
                    ),
                    decoration: BoxDecoration(
                      color: c.sunshineSoft,
                      borderRadius: BorderRadius.circular(ClRadius.card),
                    ),
                    child: Row(
                      children: [
                        ClIcon(ClIcons.clock, size: 18, color: c.ink),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Text(
                            item.skipped ? l10n.cpSkipped : l10n.cpSkipOk,
                            style: cl.text.label.copyWith(color: c.ink),
                          ),
                        ),
                        _Pill(
                          key: const Key('cp_editor_skip'),
                          label: item.skipped
                              ? l10n.cpUnskipShort
                              : l10n.cpSkipShort,
                          light: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            skip();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ClButton(
                key: const Key('cp_editor_save'),
                label: l10n.actionSave,
                expand: true,
                loading: _saving,
                onPressed: _valid ? _save : null,
              ),
            ),
            if (widget.onDelete case final delete?) ...[
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: _DeleteButton(
                  label: l10n.cpDeleteShort,
                  onTap: () {
                    Navigator.of(context).pop();
                    delete();
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// "🔍 Tìm việc, vd: uống thuốc".
class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(ClRadius.control + 2),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.search, size: 18, color: c.inkMuted),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: TextField(
              key: const Key('cp_task_search'),
              controller: controller,
              onChanged: (_) => onChanged(),
              style: cl.text.body.copyWith(color: c.ink),
              cursorColor: c.mintDeep,
              decoration: InputDecoration.collapsed(
                hintText: placeholder,
                hintStyle: cl.text.body.copyWith(color: c.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded value pill ("18:30", "☾ Tối", "Ba ⌄"); tappable when [onTap] is set.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.icon,
    this.leading,
    this.tint,
    this.onTap,
    this.semanticLabel,
    this.light = false,
    super.key,
  });

  final String label;
  final ClIcons? icon;
  final Widget? leading;
  final Color? tint;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// On a grey group: a white pill.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: EdgeInsets.symmetric(
        horizontal: leading == null ? ClSpace.s3 : ClSpace.s2,
        vertical: ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: tint ?? (light ? c.surface : c.surface2),
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 16, color: c.ink),
            const SizedBox(width: ClSpace.s1),
          ],
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: cl.text.label.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: c.ink,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: semanticLabel ?? label,
      child: SizedBox(
        height: ClSpace.tapMin,
        child: Center(child: pill),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      key: const Key('cp_editor_delete'),
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Text(label, style: cl.text.bodyStrong.copyWith(color: c.danger)),
      ),
    );
  }
}

/// "Ba" with Ba's face, in "Ai làm".
class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.member,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Membership member;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s1,
          ClSpace.s1,
          ClSpace.s3,
          ClSpace.s1,
        ),
        decoration: BoxDecoration(
          color: selected ? c.mintDeep : c.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarePlanAvatar(member, size: 28),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? c.onMintDeep : c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "+ Tạo việc riêng": a dashed chip; solid mint once chosen.
class _DashedChip extends StatelessWidget {
  const _DashedChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s3,
        vertical: ClSpace.s2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(
            ClIcons.plus,
            size: 14,
            color: selected ? c.onMintDeep : c.mintText,
          ),
          const SizedBox(width: ClSpace.s1),
          Text(
            label,
            style: cl.text.label.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? c.onMintDeep : c.mintText,
            ),
          ),
        ],
      ),
    );
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: selected
          ? Container(
              decoration: BoxDecoration(
                color: c.mintDeep,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: content,
            )
          : CustomPaint(
              painter: CarePlanDashedBorder(
                color: c.inkMuted,
                radius: ClRadius.pill,
              ),
              child: content,
            ),
    );
  }
}

/// One of the four age tiles in 06: its picture over its name; the chosen one has a mint edge.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: ClSpace.s3,
          horizontal: ClSpace.s1,
        ),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface2,
          borderRadius: BorderRadius.circular(ClRadius.card),
          border: Border.all(
            color: selected ? c.mintDeep : c.surface2,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarePlanArt(task, size: 40),
            const SizedBox(height: ClSpace.s2),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? c.mintText : c.ink,
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
