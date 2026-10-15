import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../../app/session.dart';
import '../baby/baby_models.dart' show Membership;
import '../care/care_sheets.dart' show pickCareTime;
import '../family/family_repository.dart' show familyMembersProvider;
import '../reminders/reminder_models.dart' show canBeAssignedReminders;
import '../rhythm/rhythm_labels.dart' show memberLabel;
import 'assistant_controller.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';

/// CH06 · Sửa bản nháp (Chat/Biểu mẫu nháp): edits the draft only ("Cập nhật bản nháp", never
/// "Lưu"); the same checks as the care forms (future completed logs, units, sleep order) run
/// first, then `patchDraft` validates again (revision +1). The baby is locked: a draft never
/// moves to another child.
Future<void> showDraftEditor(
  BuildContext context, {
  required String scopeKey,
  required AssistantDraft draft,
  required String babyName,
  required String zone,
}) => showClSheet<void>(
  context: context,
  builder: (_) => switch (draft.payload) {
    ExpensePayload() => _ExpenseEditor(scopeKey: scopeKey, draft: draft),
    ReminderPayload() => _ReminderEditor(
      scopeKey: scopeKey,
      draft: draft,
      babyName: babyName,
    ),
    _ => _DraftEditor(
      scopeKey: scopeKey,
      draft: draft,
      babyName: babyName,
      zone: zone,
    ),
  },
);

/// A local date (no time) between [first] and [last] (CH11 "bắt chọn ngày", CH13 reminders).
Future<DateTime?> pickAssistantDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) {
  var picked = initial.isAfter(last)
      ? last
      : (initial.isBefore(first) ? first : initial);
  return showClSheet<DateTime>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.asPickDate),
          SizedBox(
            height: 216,
            child: _Wheel(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(
              sheet,
            ).pop(DateTime(picked.year, picked.month, picked.day)),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
      );
    },
  );
}

/// A wall-clock time "HH:mm" (24 h).
Future<String?> pickAssistantTime(BuildContext context, {String? initial}) {
  final parts = (initial ?? '').split(':');
  var picked = DateTime(
    2000,
    1,
    1,
    int.tryParse(parts.first) ?? 8,
    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
  return showClSheet<String>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.asPickTime),
          SizedBox(
            height: 216,
            child: _Wheel(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: picked,
                use24hFormat: true,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () =>
                Navigator.of(sheet).pop(DateFormat('HH:mm').format(picked)),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
      );
    },
  );
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: cl.isNightCare ? Brightness.dark : Brightness.light,
        textTheme: CupertinoTextThemeData(
          dateTimePickerTextStyle: cl.text.title2.copyWith(
            color: cl.colors.ink,
          ),
        ),
      ),
      child: child,
    );
  }
}

String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// The toast for a patch outcome (shared by the editors).
void _afterPatch(
  BuildContext context,
  ActionOutcome outcome,
  List<DraftProblem> problems,
  NavigatorState navigator,
) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  switch (outcome) {
    case ActionOutcome.ok:
      navigator.pop();
    case ActionOutcome.offline:
      toaster.show(message: l10n.asSaveOffline, error: true);
    case ActionOutcome.stale:
      navigator.pop();
      toaster.show(message: l10n.asErrStale, error: true);
    case ActionOutcome.failed when problems.isEmpty:
      toaster.show(message: l10n.asEditFailed, error: true);
    default:
      break;
  }
}

/// CH11 · Sửa khoản chi: store, total (the printed total only, never subtotal + tax), currency
/// and date; updates the draft only. Saving stays on the card ("Lưu chi tiêu").
class _ExpenseEditor extends ConsumerStatefulWidget {
  const _ExpenseEditor({required this.scopeKey, required this.draft});
  final String scopeKey;
  final AssistantDraft draft;

  @override
  ConsumerState<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends ConsumerState<_ExpenseEditor> {
  late final ExpensePayload _p = widget.draft.payload as ExpensePayload;
  late String? _currency = _p.currency;
  late String? _date = _p.date;
  late final _merchant = TextEditingController(text: _p.merchant ?? '');
  late final _total = TextEditingController(text: _initialTotal());
  var _problems = <DraftProblem>[];
  var _busy = false;

  String _initialTotal() {
    final minor = _p.totalMinor;
    if (minor == null) return '';
    final digits = currencyDigits(_p.currency);
    if (digits == 0) return '$minor';
    var unit = 1;
    for (var i = 0; i < digits; i++) {
      unit *= 10;
    }
    return (minor / unit).toStringAsFixed(digits);
  }

  @override
  void dispose() {
    _merchant.dispose();
    _total.dispose();
    super.dispose();
  }

  int? _minor() {
    final raw = _total.text.trim().replaceAll(' ', '');
    if (raw.isEmpty) return null;
    final digits = currencyDigits(_currency);
    if (digits == 0) {
      final whole = raw.replaceAll(RegExp('[^0-9]'), '');
      return whole.isEmpty || whole.length > 12 ? null : int.tryParse(whole);
    }
    final major = double.tryParse(raw.replaceAll(',', '.'));
    if (major == null) return null;
    var unit = 1;
    for (var i = 0; i < digits; i++) {
      unit *= 10;
    }
    return (major * unit).round();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final merchant = _merchant.text.trim();
    final payload = ExpensePayload(
      merchant: merchant.isEmpty ? null : merchant,
      totalMinor: _minor(),
      currency: _currency,
      date: _date,
      subtotalMinor: _p.subtotalMinor,
      taxMinor: _p.taxMinor,
      categoryId: _p.categoryId,
      babyId: _p.babyId,
      keepReceipt: _p.keepReceipt,
    );
    setState(() => _busy = true);
    final (outcome, problems) = await ref
        .read(assistantChatProvider(widget.scopeKey).notifier)
        .patch(widget.draft, payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problems = problems;
    });
    _afterPatch(context, outcome, problems, navigator);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.asEditExpense),
        _TextRow(label: l10n.asFieldStore, controller: _merchant, max: 120),
        const SizedBox(height: ClSpace.s2),
        _TextRow(
          label: l10n.asFieldTotal,
          controller: _total,
          max: 16,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          suffix: _currency ?? '',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            l10n.asTotalOnly,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.asFieldCurrency,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final code in supportedCurrencies)
              _SideChip(
                label: code,
                selected: _currency == code,
                onPressed: () => setState(() => _currency = code),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        _Field(
          label: l10n.asFieldDate,
          value: _date == null ? l10n.asNoDate : fullDate(locale, _date!),
          onTap: () async {
            final current = _date == null ? null : DateTime.tryParse(_date!);
            final picked = await pickAssistantDate(
              context,
              initial: current ?? today,
              first: today.subtract(const Duration(days: 366)),
              last: today,
            );
            if (picked != null) setState(() => _date = _iso(picked));
          },
        ),
        const SizedBox(height: ClSpace.s2),
        for (final p in _problems)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                problemLabel(l10n, p),
                style: cl.text.caption.copyWith(color: cl.colors.error),
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.asUpdateDraft,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

/// CH13 · Sửa nhắc việc: title, date and time (never a silent 09:00; "Không đặt giờ" only while
/// the server accepts date-only reminders). The baby stays the chat's.
class _ReminderEditor extends ConsumerStatefulWidget {
  const _ReminderEditor({
    required this.scopeKey,
    required this.draft,
    required this.babyName,
  });
  final String scopeKey;
  final AssistantDraft draft;
  final String babyName;

  @override
  ConsumerState<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<_ReminderEditor> {
  late final ReminderPayload _p = widget.draft.payload as ReminderPayload;
  late final _title = TextEditingController(text: _p.title);
  late String? _date = _p.date;
  late String? _time = _p.time;
  late String? _assignee = _p.assigneeUid;
  late final bool _needsTime = reminderNeedsTimeFor(widget.draft);
  var _problems = <DraftProblem>[];
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    if (_needsTime && _time == null) {
      setState(() => _problems = const [DraftProblem.missingTime]);
      return;
    }
    if (_title.text.trim().length > 80) {
      setState(() => _problems = const [DraftProblem.invalidTitle]);
      return;
    }
    final payload = ReminderPayload(
      title: _title.text.trim(),
      date: _date,
      time: _time,
      assigneeUid: _assignee,
    );
    setState(() => _busy = true);
    final (outcome, problems) = await ref
        .read(assistantChatProvider(widget.scopeKey).notifier)
        .patch(widget.draft, payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problems = problems;
    });
    _afterPatch(context, outcome, problems, navigator);
  }

  /// D-075 #5: "Giao cho" among the active Cùng nuôi / Người chăm sóc (the family's member
  /// list, never a name read from the photo), or "Không giao ai".
  List<Widget> _assignees(BuildContext context, DateTime now) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final babyId = widget.draft.scope?.babyId;
    if (babyId == null) return const [];
    final session = ref.watch(sessionProvider);
    final myUid = session is SessionSignedIn ? session.user.uid : '';
    final members = [
      for (final m
          in ref.watch(familyMembersProvider(babyId)).value ??
              const <Membership>[])
        if (canBeAssignedReminders(m, now)) m,
    ];
    if (members.isEmpty && _assignee == null) return const [];
    return [
      const SizedBox(height: ClSpace.s2),
      Text(
        l10n.reminderAssignee,
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: ClSpace.s2,
        runSpacing: ClSpace.s2,
        children: [
          _SideChip(
            label: l10n.reminderAssignNobody,
            selected: _assignee == null,
            onPressed: () => setState(() => _assignee = null),
          ),
          for (final m in members)
            _SideChip(
              label: memberLabel(l10n, m, myUid: myUid),
              selected: _assignee == m.uid,
              onPressed: () => setState(() => _assignee = m.uid),
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.asEditReminder),
        _TextRow(label: l10n.asFieldTitle, controller: _title, max: 120),
        const SizedBox(height: ClSpace.s2),
        _Field(
          label: l10n.asFieldDate,
          value: _date == null ? l10n.asNoDate : weekdayDate(locale, _date!),
          onTap: () async {
            final current = _date == null ? null : DateTime.tryParse(_date!);
            final picked = await pickAssistantDate(
              context,
              initial: current ?? today,
              first: today,
              last: today.add(const Duration(days: 366)),
            );
            if (picked != null) setState(() => _date = _iso(picked));
          },
        ),
        const SizedBox(height: ClSpace.s2),
        _Field(
          label: l10n.asFieldTime,
          value: _time ?? (_needsTime ? l10n.asNoTime : l10n.asAllDay),
          onTap: () async {
            final picked = await pickAssistantTime(context, initial: _time);
            if (picked != null) setState(() => _time = picked);
          },
        ),
        if (!_needsTime && _time != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _time = null),
              child: Text(l10n.asAllDay),
            ),
          ),
        ..._assignees(context, now),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            l10n.asReminderBaby(widget.babyName),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        for (final p in _problems)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                problemLabel(l10n, p),
                style: cl.text.caption.copyWith(color: cl.colors.error),
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.asUpdateDraft,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.label,
    required this.controller,
    required this.max,
    this.keyboard,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final int max;
  final TextInputType? keyboard;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cl.colors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          Text(label, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              inputFormatters: [LengthLimitingTextInputFormatter(max)],
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '',
              ).copyWith(semanticCounterText: label),
            ),
          ),
          if (suffix != null && suffix!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(suffix!, style: cl.text.label.copyWith(color: cl.colors.ink)),
          ],
        ],
      ),
    );
  }
}

class _DraftEditor extends ConsumerStatefulWidget {
  const _DraftEditor({
    required this.scopeKey,
    required this.draft,
    required this.babyName,
    required this.zone,
  });

  final String scopeKey;
  final AssistantDraft draft;
  final String babyName;
  final String zone;

  @override
  ConsumerState<_DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends ConsumerState<_DraftEditor> {
  late DraftPayload _payload = widget.draft.payload;
  late final _amount = TextEditingController(text: _initialNumber());
  var _problems = <DraftProblem>[];
  var _busy = false;

  String _initialNumber() => switch (_payload) {
    BottlePayload(:final amountMl?) => '${amountMl.round()}',
    BreastPayload(:final durationMin?) => '$durationMin',
    _ => '',
  };

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  DraftPayload _withNumber() {
    final n = int.tryParse(_amount.text.trim());
    return switch (_payload) {
      final BottlePayload p => BottlePayload(
        amountMl: n,
        occurredAt: p.occurredAt,
        milk: p.milk,
      ),
      final BreastPayload p => BreastPayload(
        occurredAt: p.occurredAt,
        durationMin: n,
        side: p.side,
      ),
      final p => p,
    };
  }

  Future<DateTime?> _pick(DateTime? current) async {
    final now = ref.read(assistantClockProvider)();
    final wall = inBabyZone(widget.zone, current ?? now);
    final picked = await pickCareTime(context, initial: wall);
    return picked == null ? null : fromBabyWall(widget.zone, picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final payload = _withNumber();
    setState(() => _busy = true);
    final (outcome, problems) = await ref
        .read(assistantChatProvider(widget.scopeKey).notifier)
        .patch(widget.draft, payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problems = problems;
      _payload = payload;
    });
    switch (outcome) {
      case ActionOutcome.ok:
        navigator.pop();
      case ActionOutcome.offline:
        toaster.show(message: l10n.asSaveOffline, error: true);
      case ActionOutcome.stale:
        navigator.pop();
        toaster.show(message: l10n.asErrStale, error: true);
      case ActionOutcome.failed when problems.isEmpty:
        toaster.show(message: l10n.asEditFailed, error: true);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    String when(DateTime? at) => at == null
        ? l10n.asNoTime
        : '${dayLabel(l10n, locale, at, widget.zone, now)} · ${hm(at, widget.zone)}';
    final title = switch (_payload) {
      BreastPayload() => l10n.asEditBreast,
      SleepPayload() => l10n.asEditSleep,
      _ => l10n.asEditBottle,
    };
    final fields = <Widget>[
      _Field(
        label: l10n.asFieldBaby,
        value: widget.babyName,
        trailing: ClIcon(ClIcons.lock, size: 14, color: cl.colors.inkMuted),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          l10n.asBabyLocked,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ),
      ...switch (_payload) {
        final BottlePayload p => [
          _Field(
            label: l10n.asFieldWhen,
            value: when(p.occurredAt),
            onTap: () async {
              final at = await _pick(p.occurredAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(occurredAt: at));
            },
          ),
          _NumberField(
            label: l10n.asFieldAmount,
            controller: _amount,
            suffix: 'ml',
          ),
        ],
        final BreastPayload p => [
          _Field(
            label: l10n.asFieldWhen,
            value: when(p.occurredAt),
            onTap: () async {
              final at = await _pick(p.occurredAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(occurredAt: at));
            },
          ),
          _NumberField(
            label: l10n.asFieldMinutes,
            controller: _amount,
            suffix: l10n.durationMinutes(0).replaceAll('0', '').trim(),
          ),
          const SizedBox(height: ClSpace.s2),
          Row(
            children: [
              Text(
                l10n.asFieldSide,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(width: ClSpace.s3),
              for (final (wire, label) in [
                ('left', l10n.sideLeft),
                ('right', l10n.sideRight),
                ('both', l10n.sideBoth),
              ]) ...[
                _SideChip(
                  label: label,
                  selected: p.side == wire,
                  onPressed: () =>
                      setState(() => _payload = p.copyWith(side: wire)),
                ),
                const SizedBox(width: ClSpace.s2),
              ],
            ],
          ),
        ],
        final SleepPayload p => [
          _Field(
            label: l10n.asFieldStart,
            value: when(p.startedAt),
            onTap: () async {
              final at = await _pick(p.startedAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(startedAt: at));
            },
          ),
          _Field(
            label: l10n.asFieldEnd,
            value: when(p.endedAt),
            onTap: () async {
              final at = await _pick(p.endedAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(endedAt: at));
            },
          ),
        ],
        _ => const <Widget>[],
      },
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        for (final f in fields) ...[f, const SizedBox(height: ClSpace.s2)],
        for (final p in _problems)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                problemLabel(l10n, p),
                style: cl.text.caption.copyWith(color: cl.colors.error),
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.asUpdateDraft,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

/// A Chat/Biểu mẫu nháp row: muted label left, SemiBold value right (cloud fill, radius 14).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cl.colors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          Text(label, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
    return onTap == null
        ? Semantics(
            label: '$label, $value',
            child: ExcludeSemantics(child: row),
          )
        : ClPressable(
            onPressed: onTap,
            semanticLabel: '$label, $value',
            pressedOpacity: 0.7,
            child: row,
          );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cl.colors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          Text(label, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '',
              ).copyWith(semanticCounterText: label),
            ),
          ),
          const SizedBox(width: 6),
          Text(suffix, style: cl.text.label.copyWith(color: cl.colors.ink)),
        ],
      ),
    );
  }
}

class _SideChip extends StatelessWidget {
  const _SideChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: selected ? c.mintDeep : c.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: context.cl.text.label.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? c.mintText : c.ink,
          ),
        ),
      ),
    );
  }
}
