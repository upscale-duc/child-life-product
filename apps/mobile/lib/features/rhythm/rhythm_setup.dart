import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_gate.dart';
import '../premium/premium_models.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_local.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

enum RhythmSetupStep { intro, dueDate, reminders }

/// NL02a (570:1070) → NL02b (570:1108) → NL02c (570:1153), shown once to a Cùng nuôi on the
/// first open of Nhịp lớn lên; NL02b and NL02c also open alone ([single]) from NL01 / NL03
/// ("Thêm ngày dự sinh", "Không nhớ", "Đổi") and from "Cá nhân hoá".
///
/// The due date goes through `setDueDate` (Cùng nuôi, `rhythm.setup`), validated like the
/// server: 4 weeks before to 18 weeks after birth; an estimate from the gestational age keeps
/// its "ước tính" label (brief p.13). Reminder switches stay on this phone ([RhythmReminders]);
/// quiet hours are the person's preferences (`userPreferencesSchema`).
class RhythmSetupScreen extends ConsumerStatefulWidget {
  const RhythmSetupScreen({
    this.start = RhythmSetupStep.intro,
    this.single = false,
    this.estimate = false,
    super.key,
  });

  final RhythmSetupStep start;

  /// One step on its own: its primary button finishes and leaves.
  final bool single;

  /// NL01b "Không nhớ": open the estimate from the gestational age.
  final bool estimate;

  @override
  ConsumerState<RhythmSetupScreen> createState() => _RhythmSetupScreenState();
}

class _RhythmSetupScreenState extends ConsumerState<RhythmSetupScreen> {
  late var _step = widget.start;

  // NL02b.
  var _dueReady = false;
  String? _date;
  var _estimated = false;
  late var _useEstimate = widget.estimate;
  var _weeks = 39;
  var _days = 0;
  var _saving = false;

  // NL02c.
  RhythmReminders? _reminders;
  UserPreferences? _prefs;

  void _finish(Membership me) {
    if (!widget.single) markRhythmSetupSeen(ref, me.uid, me.babyId);
    leaveRhythm(context);
  }

  void _back(Membership me) {
    if (widget.single || _step == RhythmSetupStep.intro) {
      _finish(me);
      return;
    }
    setState(() => _step = RhythmSetupStep.values[_step.index - 1]);
  }

  void _next(Membership me) {
    if (widget.single || _step == RhythmSetupStep.reminders) {
      _finish(me);
      return;
    }
    setState(() => _step = RhythmSetupStep.values[_step.index + 1]);
  }

  String? _chosen(String? dob) => _useEstimate
      ? (dob == null ? null : estimateDueDate(dob, _weeks, _days))
      : _date;

  Future<void> _saveDue(Membership me, String? dob, DueDate? current) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final date = _chosen(dob);
    if (date == null) return;
    final due = DueDate(
      date: date,
      estimated: _useEstimate,
      gestationWeeks: _useEstimate ? _weeks : null,
      gestationDays: _useEstimate ? _days : null,
    );
    if (due == current) {
      _next(me);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(rhythmRepositoryProvider).setDueDate(me.babyId, due);
      if (!mounted) return;
      toaster.show(message: l10n.rhDueSaved);
      _next(me);
    } on RhythmException catch (e) {
      if (!mounted) return;
      final gate = e.gate;
      if (gate != null && gate != GateReason.premiumRequired) {
        await showGateSheet(context, gate);
      } else {
        toaster.show(message: l10n.rhDueSaveFailed, error: true);
      }
    } on Object {
      if (mounted) toaster.show(message: l10n.rhDueSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeDue(Membership me) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(rhythmRepositoryProvider).setDueDate(me.babyId, null);
      if (!mounted) return;
      toaster.show(message: l10n.rhDueRemoved);
      leaveRhythm(context);
    } on Object {
      if (mounted) toaster.show(message: l10n.rhDueSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _saveReminders(Membership me) {
    final reminders = _reminders;
    if (reminders != null) {
      ref.read(rhythmRemindersProvider(me.uid).notifier).set(reminders);
    }
    final prefs = _prefs;
    final stored = ref.read(userPreferencesProvider(me.uid)).value;
    if (prefs != null &&
        (prefs.quietFrom != stored?.quietFrom ||
            prefs.quietTo != stored?.quietTo)) {
      final l10n = AppLocalizations.of(context);
      final toaster = ClToaster.of(context);
      ref
          .read(rhythmRepositoryProvider)
          .savePreferences(
            me.uid,
            (stored ?? UserPreferences.defaults).copyWith(
              quietHours: () => prefs.quietFrom == null
                  ? null
                  : (prefs.quietFrom!, prefs.quietTo!),
            ),
            onError: (_) =>
                toaster.show(message: l10n.rhSaveFailed, error: true),
          );
    }
    if (widget.single) {
      ClToaster.of(
        context,
      ).show(message: AppLocalizations.of(context).rhPrefsSaved);
    }
    _next(me);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const OnboardingScaffold(content: []);
    final close = RhRoundIcon(
      icon: _step == RhythmSetupStep.intro || widget.single
          ? ClIcons.close
          : ClIcons.back,
      label: _step == RhythmSetupStep.intro || widget.single
          ? l10n.a11yClose
          : l10n.a11yBack,
      onPressed: () => _back(me),
    );
    final topBar = Align(alignment: Alignment.centerLeft, child: close);
    return switch (_step) {
      RhythmSetupStep.intro => _intro(me, topBar),
      RhythmSetupStep.dueDate => _dueDate(me, topBar),
      RhythmSetupStep.reminders => _remindersStep(me, topBar),
    };
  }

  // ---------- NL02a ----------

  Widget _intro(Membership me, Widget topBar) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget layer({
      required bool calendar,
      required String pill,
      required String title,
      required String body,
      required String basis,
    }) => RhCard(
      color: calendar ? cl.care.sleep.soft : cl.colors.mintSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RhLayerPill(label: pill, calendar: calendar),
          const SizedBox(height: ClSpace.s2),
          Text(title, style: cl.text.headline.copyWith(color: cl.colors.ink)),
          const SizedBox(height: ClSpace.s1),
          Text(body, style: cl.text.label.copyWith(color: cl.colors.ink)),
          const SizedBox(height: ClSpace.s2),
          Text(
            basis,
            style: cl.text.caption.copyWith(
              color: cl.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Semantics(
          header: true,
          child: Text(l10n.rhTitle, style: cl.text.title),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(l10n.rhSetupIntro, style: cl.text.body),
        const SizedBox(height: ClSpace.s4),
        layer(
          calendar: true,
          pill: l10n.rhCalendarPill,
          title: l10n.rhLayerCalendarTitle,
          body: l10n.rhLayerCalendarBody,
          basis: l10n.rhLayerCalendarBasis,
        ),
        const SizedBox(height: ClSpace.s3),
        layer(
          calendar: false,
          pill: l10n.rhOwnPill,
          title: l10n.rhLayerOwnTitle,
          body: l10n.rhLayerOwnBody,
          basis: l10n.rhLayerOwnBasis,
        ),
        const SizedBox(height: ClSpace.s4),
        RhNote(l10n.rhSetupDisclaimer, icon: ClIcons.alert),
      ],
      bottom: [
        ClButton(label: l10n.rhStart, expand: true, onPressed: () => _next(me)),
      ],
    );
  }

  // ---------- NL02b ----------

  Widget _dueDate(Membership me, Widget topBar) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final canSetup = familyCan(me, FamilyAction.rhythmSetup);
    final profileAsync = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId))
        : null;
    final profile = profileAsync?.value;
    final current = profile?.dueDate;
    if (!_dueReady && profile != null) {
      _dueReady = true;
      if (current != null) {
        _date = current.date;
        _estimated = current.estimated;
        _weeks = current.gestationWeeks ?? _weeks;
        _days = current.gestationDays ?? _days;
        _useEstimate = widget.estimate || current.estimated;
      }
    }
    final dob = profile?.dateOfBirth == null
        ? null
        : isoOf(profile!.dateOfBirth!);
    final chosen = _chosen(dob);
    final valid =
        chosen != null &&
        (dob == null || dueDateAllowed(dob, chosen)) &&
        (!_useEstimate || gestationValid(_weeks, _days));

    if (!canSetup) {
      return OnboardingScaffold(
        topBar: topBar,
        content: [RhInfoBox(icon: ClIcons.lock, text: l10n.rhDueSetupOnly)],
      );
    }

    Future<void> pickDate() async {
      final base = profile?.dateOfBirth ?? DateTime.now();
      final first = base.add(const Duration(days: dueDateMinOffsetDays));
      final last = base.add(const Duration(days: dueDateMaxOffsetDays));
      var initial = _date == null ? base : DateTime.parse(_date!);
      if (initial.isBefore(first)) initial = first;
      if (initial.isAfter(last)) initial = last;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: dob == null ? DateTime(2000) : first,
        lastDate: dob == null ? DateTime(2100) : last,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _date = isoOf(picked);
        _estimated = false;
        _useEstimate = false;
      });
    }

    Future<void> pickNumber(String title, List<int> values, bool weeks) async {
      final picked = await showClSheet<int>(
        context: context,
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: title),
            Flexible(
              child: SingleChildScrollView(
                child: ClCardGroup(
                  children: [
                    for (final v in values)
                      ClOptionRow(
                        title: weeks ? l10n.rhWeeks(v) : l10n.rhPlusDays(v),
                        selected: v == (weeks ? _weeks : _days),
                        onTap: () => Navigator.of(sheet).pop(v),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s4),
          ],
        ),
      );
      if (picked == null || !mounted) return;
      setState(() {
        if (weeks) {
          _weeks = picked;
        } else {
          _days = picked;
        }
        _useEstimate = true;
      });
    }

    final estimate = dob == null ? null : estimateDueDate(dob, _weeks, _days);
    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Semantics(
          header: true,
          child: Text(l10n.rhDueTitle(name), style: cl.text.title2),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          dob == null
              ? l10n.rhDueBodyNoDob
              : l10n.rhDueBody(name, longDay(locale, dob)),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.rhDueField,
          style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ClSpace.s2),
        ClPressable(
          onPressed: pickDate,
          semanticLabel:
              '${l10n.rhDueField}, ${_date == null || _useEstimate ? l10n.rhDuePick : longDay(locale, _date!)}',
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.control),
              border: Border.all(
                color: !_useEstimate && _date != null
                    ? cl.colors.mintDeep
                    : cl.colors.controlBorder,
                width: !_useEstimate && _date != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.cake, size: 18, color: cl.colors.inkMuted),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    _date == null || _useEstimate
                        ? l10n.rhDuePick
                        : [
                            longDay(locale, _date!),
                            if (_estimated) '(${l10n.rhEstimatedTag})',
                          ].join(' '),
                    style: cl.text.body.copyWith(
                      color: _date == null || _useEstimate
                          ? cl.colors.inkMuted
                          : cl.colors.ink,
                    ),
                  ),
                ),
                ClIcon(
                  ClIcons.chevronDown,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        RhCard(
          hairline: !_useEstimate,
          outline: _useEstimate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.rhEstimateTitle, style: cl.text.bodyStrong),
              const SizedBox(height: ClSpace.s1),
              Text(
                dob == null ? l10n.rhEstimateNeedsDob : l10n.rhEstimateBody,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              if (dob != null) ...[
                const SizedBox(height: ClSpace.s3),
                Wrap(
                  spacing: ClSpace.s2,
                  runSpacing: ClSpace.s2,
                  children: [
                    RhChip(
                      label: l10n.rhWeeks(_weeks),
                      selected: _useEstimate,
                      onTap: () => pickNumber(l10n.rhWeeksPickerTitle, [
                        for (var w = 22; w <= 44; w++) w,
                      ], true),
                    ),
                    RhChip(
                      label: l10n.rhPlusDays(_days),
                      selected: _useEstimate,
                      onTap: () => pickNumber(l10n.rhDaysPickerTitle, [
                        for (var d = 0; d <= 6; d++) d,
                      ], false),
                    ),
                  ],
                ),
                if (_useEstimate && estimate != null) ...[
                  const SizedBox(height: ClSpace.s3),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(ClSpace.s3),
                    decoration: BoxDecoration(
                      color: cl.colors.sunshineSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // Ink on soft warm fills, also in Night care.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClIcon(ClIcons.alert, size: 16, color: cl.colors.ink),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Text(
                            l10n.rhEstimateResult(longDay(locale, estimate)),
                            style: cl.text.label.copyWith(color: cl.colors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.rhEstimateAdvice,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ],
          ),
        ),
        if (chosen != null && !valid) ...[
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.rhDueOutOfRange,
            style: cl.text.label.copyWith(color: cl.colors.error),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: widget.single && current != null
              ? RhLink(
                  label: l10n.rhDueRemove,
                  muted: true,
                  start: true,
                  onTap: () => _removeDue(me),
                )
              : RhLink(
                  label: l10n.rhSkipOwnOnly,
                  start: true,
                  onTap: () => _next(me),
                ),
        ),
      ],
      bottom: [
        ClButton(
          label: widget.single ? l10n.actionSave : l10n.rhContinue,
          expand: true,
          loading: _saving,
          onPressed: valid ? () => _saveDue(me, dob, current) : null,
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.rhDueHelper,
          textAlign: TextAlign.center,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }

  // ---------- NL02c ----------

  Widget _remindersStep(Membership me, Widget topBar) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final RhythmReminders reminders =
        _reminders ?? ref.read(rhythmRemindersProvider(me.uid));
    final stored = ref.watch(userPreferencesProvider(me.uid)).value;
    final prefs = _prefs ?? stored ?? UserPreferences.defaults;
    final canCheckIn = familyCan(me, FamilyAction.rhythmCheckin);
    final canSetup = familyCan(me, FamilyAction.rhythmSetup);
    final canRead = familyCan(me, FamilyAction.historyRead);

    Widget toggle(
      String title,
      String sub,
      bool value,
      ValueChanged<bool> on,
    ) => MergeSemantics(
      // The whole row flips the switch.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => on(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s3,
          ),
          child: Row(
            children: [
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
              const SizedBox(width: ClSpace.s2),
              ClToggle(value: value, onChanged: on, semanticLabel: title),
            ],
          ),
        ),
      ),
    );

    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Semantics(
          header: true,
          child: Text(l10n.rhRemindTitle, style: cl.text.title2),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.rhRemindBody,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        if (canSetup || canCheckIn || canRead) ...[
          ClCardGroup(
            children: [
              if (canSetup)
                toggle(
                  l10n.rhRemindStage,
                  l10n.rhRemindStageSub,
                  reminders.stage,
                  (v) =>
                      setState(() => _reminders = reminders.copyWith(stage: v)),
                ),
              if (canCheckIn)
                toggle(
                  l10n.rhRemindEvening,
                  l10n.rhRemindEveningSub,
                  reminders.evening,
                  (v) => setState(
                    () => _reminders = reminders.copyWith(evening: v),
                  ),
                ),
              // EN07 "Tóm tắt tuần · Chủ nhật 20:30" → EN09.
              if (canRead)
                toggle(
                  l10n.rhWeekTitle,
                  l10n.rhWeekRemindSub,
                  reminders.weekly,
                  (v) => setState(
                    () => _reminders = reminders.copyWith(weekly: v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        QuietHoursCard(
          preferences: prefs,
          onChanged: (p) => setState(() => _prefs = p),
        ),
        const SizedBox(height: ClSpace.s3),
        RhNote(l10n.rhRemindDevice, icon: ClIcons.bell),
        const SizedBox(height: ClSpace.s2),
        RhNote(l10n.rhNoLeapRisk),
      ],
      bottom: [
        ClButton(
          label: l10n.rhDone,
          expand: true,
          onPressed: () => _saveReminders(me),
        ),
      ],
    );
  }
}

/// EN02 / NL02c "Giờ yên lặng": on or off, from and to (suggestions only; reminders the person
/// set always ring).
class QuietHoursCard extends StatelessWidget {
  const QuietHoursCard({
    required this.preferences,
    required this.onChanged,
    super.key,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onChanged;

  static TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':').map(int.parse).toList();
    return TimeOfDay(hour: p[0], minute: p[1]);
  }

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final on = preferences.quietFrom != null && preferences.quietTo != null;
    final from = preferences.quietFrom ?? '22:00';
    final to = preferences.quietTo ?? '06:00';

    Future<void> pick(bool start) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _parse(start ? from : to),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked == null) return;
      final v = _format(picked);
      onChanged(
        preferences.copyWith(quietHours: () => start ? (v, to) : (from, v)),
      );
    }

    Widget chip(String label, bool start) => RhChip(
      label: label,
      selected: on,
      onTap: on ? () => pick(start) : () {},
    );

    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(
                preferences.copyWith(quietHours: () => on ? null : (from, to)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.rhQuietHours, style: cl.text.bodyStrong),
                        Text(
                          l10n.rhQuietSub,
                          style: cl.text.label.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClToggle(
                    value: on,
                    semanticLabel: l10n.rhQuietHours,
                    onChanged: (v) => onChanged(
                      preferences.copyWith(
                        quietHours: () => v ? (from, to) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (on) ...[
            const SizedBox(height: ClSpace.s3),
            Row(
              children: [
                chip(from, true),
                const SizedBox(width: ClSpace.s2),
                Text(
                  l10n.rhQuietTo,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(width: ClSpace.s2),
                chip(to, false),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
