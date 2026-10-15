import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart' show Membership;
import '../care/care_format.dart' show decimal, durationLabel, parseDecimal;
import '../care/care_repository.dart' show inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import '../reminders/reminder_models.dart' show canBeAssignedReminders;
import '../rhythm/rhythm_labels.dart' show memberLabel;
import '../spending/spending_currency.dart' show isSpCurrency, legacyCurrency;
import '../spending/spending_format.dart'
    show categoryName, moneyPlain, parseMoney;
import '../spending/spending_models.dart' show builtInCategories;
import '../spending/spending_sheets.dart' show SpAmountInput, pickSpCurrency;
import 'assistant_controller.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';
import 'assistant_time.dart';
import 'assistant_widgets.dart' show AsSize;

/// CH06 · Sửa bản nháp (Chat/Biểu mẫu nháp), reworked 2026-10-15: edits the draft only ("Cập
/// nhật bản nháp", never "Lưu"); the same checks as the care forms (future completed logs,
/// units, sleep order) run first, then `patchDraft` validates again (revision +1). The baby is
/// locked: a draft never moves to another child. Times are picked inline on a wheel (no sheet
/// on a sheet); a sleep's start, end and duration stay linked ("21:00 → 06:00 · 9 giờ"); amounts
/// have steppers and quick picks; an expense uses Chi tiêu's own amount field and currency.
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
    PumpPayload() || DiaperPayload() || GrowthPayload() => _CareLogEditor(
      scopeKey: scopeKey,
      draft: draft,
      babyName: babyName,
      zone: zone,
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

/// CH05 "Khác…" on a question that asks for a clock time: a wheel that starts from what is
/// known and, when a duration was said ("ngủ 9 tiếng"), previews the other end live
/// ("21:00 hôm qua → 06:00 · 9 giờ"). Returns "HH:mm" for the answer; null when closed.
Future<String?> pickClarifyTime(
  BuildContext context, {
  required String zone,
  required DateTime now,
  int? knownMinutes,
  bool end = false,
  DateTime? initial,
}) => showClSheet<String>(
  context: context,
  builder: (_) => _ClarifyTimeSheet(
    zone: zone,
    now: now,
    knownMinutes: knownMinutes,
    end: end,
    initial: initial,
  ),
);

class _ClarifyTimeSheet extends StatefulWidget {
  const _ClarifyTimeSheet({
    required this.zone,
    required this.now,
    required this.knownMinutes,
    required this.end,
    required this.initial,
  });
  final String zone;
  final DateTime now;
  final int? knownMinutes;
  final bool end;
  final DateTime? initial;

  @override
  State<_ClarifyTimeSheet> createState() => _ClarifyTimeSheetState();
}

class _ClarifyTimeSheetState extends State<_ClarifyTimeSheet> {
  late DateTime _wall = _initialWall();

  DateTime _initialWall() {
    final known = widget.knownMinutes;
    final at =
        widget.initial ??
        (known != null && !widget.end
            ? widget.now.subtract(Duration(minutes: known))
            : widget.now);
    final w = inBabyZone(widget.zone, at);
    return DateTime(2000, 1, 1, w.hour, w.minute - w.minute % 5);
  }

  /// The span the picked time makes with the known duration (null: no duration known).
  LinkedSpan? _span() {
    final known = widget.knownMinutes;
    if (known == null) return null;
    if (widget.end) {
      var e = nearestWall(
        widget.zone,
        _wall.hour,
        _wall.minute,
        near: widget.now,
      );
      if (e.isAfter(widget.now)) e = e.subtract(const Duration(days: 1));
      return LinkedSpan(e.subtract(Duration(minutes: known)), e);
    }
    return pickStart(
      LinkedSpan.endingAt(widget.now, known),
      widget.zone,
      _wall.hour,
      _wall.minute,
      now: widget.now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final span = _span();
    final time = hhmm(_wall.hour, _wall.minute);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: widget.knownMinutes == null
              ? l10n.asPickTime
              : (widget.end ? l10n.asPickWakeTitle : l10n.asPickSleepTitle),
        ),
        if (span != null)
          _SpanSummary(
            line: spanLine(l10n, locale, span, widget.zone, widget.now),
            note: l10n.asSpanKnown(durationLabel(l10n, widget.knownMinutes!)),
          ),
        SizedBox(
          height: 180,
          child: _Wheel(
            child: CupertinoDatePicker(
              key: const ValueKey('as.clarifyWheel'),
              mode: CupertinoDatePickerMode.time,
              initialDateTime: _wall,
              use24hFormat: true,
              onDateTimeChanged: (d) => setState(
                () => _wall = DateTime(2000, 1, 1, d.hour, d.minute),
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.asAnswerWith(time),
          expand: true,
          onPressed: () => Navigator.of(context).pop(time),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
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

/// The editors' frame: header, the fields (scrolling when the keyboard or large text needs
/// it), the problems read out, and "Cập nhật bản nháp" in the thumb zone.
class _EditorFrame extends StatelessWidget {
  const _EditorFrame({
    required this.title,
    required this.children,
    required this.problems,
    required this.busy,
    required this.onSubmit,
    this.problemText,
  });
  final String title;
  final List<Widget> children;
  final List<DraftProblem> problems;
  final bool busy;
  final VoidCallback onSubmit;

  /// The words of a problem when the generic ones do not fit (a weight is not "Lượng").
  final String Function(DraftProblem)? problemText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        Flexible(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in children) ...[
                  c,
                  const SizedBox(height: ClSpace.s2),
                ],
              ],
            ),
          ),
        ),
        AsSize(
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in problems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ClIcon(
                            ClIcons.alert,
                            size: 13,
                            color: cl.colors.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            problemText?.call(p) ?? problemLabel(l10n, p),
                            style: cl.text.caption.copyWith(
                              color: cl.colors.error,
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
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.asUpdateDraft,
          expand: true,
          loading: busy,
          onPressed: onSubmit,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// "21:00 → 06:00 · 9 giờ" in large type, with a note under it.
class _SpanSummary extends StatelessWidget {
  const _SpanSummary({required this.line, this.note});
  final String line;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      margin: const EdgeInsets.only(bottom: ClSpace.s2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cl.care.sleep.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              line,
              key: const ValueKey('as.spanLine'),
              style: cl.text.title2.copyWith(
                fontSize: 18,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: cl.care.sleep.ink,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: cl.text.caption.copyWith(color: cl.care.sleep.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// A time row: label, the time large, its day under it; selected while its wheel is open.
class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.day,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final String time;
  final String day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: '$label, $time, $day',
      pressedOpacity: 0.7,
      child: AnimatedContainer(
        width: double.infinity,
        duration: context.motion(ClMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.cloud,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.mintDeep : c.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: cl.text.caption.copyWith(
                color: selected ? c.mintText : c.inkMuted,
              ),
            ),
            Text(
              time,
              style: cl.text.title2.copyWith(
                fontSize: 22,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: c.ink,
              ),
            ),
            Text(day, style: cl.text.caption.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// An inline 24 h wheel for the baby's wall clock ([wall]'s hour and minute).
class _ClockWheel extends StatelessWidget {
  const _ClockWheel({required this.wall, required this.onChanged, super.key});
  final DateTime wall;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: _Wheel(
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: DateTime(2000, 1, 1, wall.hour, wall.minute),
        use24hFormat: true,
        onDateTimeChanged: (d) => onChanged(d.hour, d.minute),
      ),
    ),
  );
}

/// [−] value [+] with quick picks under it (ml, minutes, a sleep's length).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.minusLabel,
    this.plusLabel,
    this.quick = const [],
  });
  final String label;
  final Widget value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String? minusLabel;
  final String? plusLabel;
  final List<({String label, bool selected, VoidCallback onPressed})> quick;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    Widget round(String glyph, String a11y, VoidCallback? onTap) => Opacity(
      opacity: onTap == null ? ClMotion.disabledOpacity : 1,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: a11y,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: ExcludeSemantics(
            child: Text(
              glyph,
              style: cl.text.title2.copyWith(color: c.ink, height: 1),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.controlBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: cl.text.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: 4),
          Row(
            children: [
              round('−', minusLabel ?? '−', onMinus),
              Expanded(child: Center(child: value)),
              round('+', plusLabel ?? '+', onPlus),
            ],
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s2),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final q in quick)
                  _SideChip(
                    label: q.label,
                    selected: q.selected,
                    onPressed: q.onPressed,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// CH11 · Sửa khoản chi: Chi tiêu's own amount field (grouping as typed, its currency picker),
/// store, category and date; updates the draft only. Saving stays on the card ("Lưu chi tiêu").
/// Private to the person (spending never enters the shared thread).
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
  late String? _category = _p.categoryId;
  late final _merchant = TextEditingController(text: _p.merchant ?? '');
  late final _total = TextEditingController();
  var _problems = <DraftProblem>[];
  var _busy = false;

  String get _code => _currency != null && isSpCurrency(_currency)
      ? _currency!
      : legacyCurrency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_total.text.isEmpty && _p.totalMinor != null) {
      _total.text = moneyPlain(
        Localizations.localeOf(context).toLanguageTag(),
        _p.totalMinor!,
        _code,
      );
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final merchant = _merchant.text.trim();
    final payload = ExpensePayload(
      merchant: merchant.isEmpty ? null : merchant,
      totalMinor: parseMoney(
        _total.text,
        _code,
        Localizations.localeOf(context).toLanguageTag(),
      ),
      currency: _currency,
      date: _date,
      subtotalMinor: _p.subtotalMinor,
      taxMinor: _p.taxMinor,
      categoryId: _category,
      babyId: _p.babyId,
      keepReceipt: _p.keepReceipt,
      note: _p.note,
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
    final yesterday = today.subtract(const Duration(days: 1));
    final picked = _date == null ? null : DateTime.tryParse(_date!);
    Future<void> pickDate() async {
      final d = await pickAssistantDate(
        context,
        initial: picked ?? today,
        first: today.subtract(const Duration(days: 366)),
        last: today,
      );
      if (d != null) setState(() => _date = _iso(d));
    }

    return _EditorFrame(
      title: l10n.asEditExpense,
      problems: _problems,
      busy: _busy,
      onSubmit: _submit,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.cloud,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cl.colors.controlBorder),
          ),
          child: Column(
            children: [
              Text(
                l10n.asFieldTotal,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(height: 4),
              SpAmountInput(
                controller: _total,
                large: false,
                currency: _code,
                onCurrency: () async {
                  final c = await pickSpCurrency(context, _code);
                  if (c == null || !mounted) return;
                  setState(() {
                    _currency = c;
                    _total.clear();
                  });
                },
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.asTotalOnly,
                  textAlign: TextAlign.center,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
        _TextRow(label: l10n.asFieldStore, controller: _merchant, max: 120),
        _Label(l10n.asFieldCategory),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final c in builtInCategories)
              _SideChip(
                label: categoryName(l10n, c),
                icon: c.icon,
                selected: _category == c.id,
                onPressed: () => setState(() => _category = c.id),
              ),
          ],
        ),
        _Label(l10n.asFieldDate),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            _SideChip(
              label: l10n.asWhenToday,
              selected: picked == today,
              onPressed: () => setState(() => _date = _iso(today)),
            ),
            _SideChip(
              label: l10n.asWhenYesterday,
              selected: picked == yesterday,
              onPressed: () => setState(() => _date = _iso(yesterday)),
            ),
            _SideChip(
              label: picked != null && picked != today && picked != yesterday
                  ? fullDate(locale, _date!)
                  : l10n.asPickOtherDay,
              icon: ClIcons.today,
              selected:
                  picked != null && picked != today && picked != yesterday,
              onPressed: pickDate,
            ),
          ],
        ),
        Row(
          children: [
            ClIcon(ClIcons.lock, size: 12, color: cl.colors.inkMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                l10n.asOnlyYouSpending,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// CH13 · Sửa nhắc việc: title, the day (Hôm nay / Ngày mai / another), "Cả ngày" or a time on
/// an inline wheel (never a silent 09:00; all-day only while the server accepts date-only
/// reminders), and "Giao cho". The baby stays the chat's.
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
  var _wheel = false;
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
      _Label(l10n.reminderAssignee),
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
    final tomorrow = today.add(const Duration(days: 1));
    final picked = _date == null ? null : DateTime.tryParse(_date!);
    final other = picked != null && picked != today && picked != tomorrow;
    final parts = (_time ?? '').split(':');
    final wall = DateTime(
      2000,
      1,
      1,
      int.tryParse(parts.first) ?? now.hour,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    return _EditorFrame(
      title: l10n.asEditReminder,
      problems: _problems,
      busy: _busy,
      onSubmit: _submit,
      children: [
        _TextRow(label: l10n.asFieldTitle, controller: _title, max: 120),
        _Label(l10n.asFieldDate),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            _SideChip(
              label: l10n.asWhenToday,
              selected: picked == today,
              onPressed: () => setState(() => _date = _iso(today)),
            ),
            _SideChip(
              label: l10n.asWhenTomorrow,
              selected: picked == tomorrow,
              onPressed: () => setState(() => _date = _iso(tomorrow)),
            ),
            _SideChip(
              label: other
                  ? weekdayDate(locale, _date!)
                  : (picked == null ? l10n.asNoDate : l10n.asPickOtherDay),
              icon: ClIcons.today,
              selected: other,
              onPressed: () async {
                final d = await pickAssistantDate(
                  context,
                  initial: picked ?? today,
                  first: today,
                  last: today.add(const Duration(days: 366)),
                );
                if (d != null) setState(() => _date = _iso(d));
              },
            ),
          ],
        ),
        _Label(l10n.asFieldTime),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            if (!_needsTime)
              _SideChip(
                label: l10n.asAllDay,
                selected: _time == null,
                onPressed: () => setState(() {
                  _time = null;
                  _wheel = false;
                }),
              ),
            _SideChip(
              label: _time ?? l10n.asNoTime,
              icon: ClIcons.clock,
              selected: _time != null || _wheel,
              onPressed: () => setState(() {
                _wheel = !_wheel || _time == null;
                _time ??= hhmm(wall.hour, wall.minute);
              }),
            ),
          ],
        ),
        AsSize(
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
          child: _wheel
              ? _ClockWheel(
                  key: const ValueKey('as.reminderWheel'),
                  wall: wall,
                  onChanged: (h, m) => setState(() => _time = hhmm(h, m)),
                )
              : const SizedBox(width: double.infinity),
        ),
        ..._assignees(context, now),
        Text(
          l10n.asReminderBaby(widget.babyName),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: context.cl.text.label.copyWith(color: context.cl.colors.inkMuted),
    ),
  );
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.label,
    required this.controller,
    required this.max,
  });
  final String label;
  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              inputFormatters: [LengthLimitingTextInputFormatter(max)],
              textAlign: TextAlign.end,
              textCapitalization: TextCapitalization.sentences,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '',
              ).copyWith(semanticCounterText: label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottle, nursing and sleep.
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

/// Which wheel is open.
enum _Wheeling { none, at, start, end }

class _DraftEditorState extends ConsumerState<_DraftEditor> {
  late DraftPayload _payload = widget.draft.payload;
  late final _amount = TextEditingController(text: _initialNumber());
  var _problems = <DraftProblem>[];
  var _busy = false;
  var _wheel = _Wheeling.none;

  /// Bumped when a time moves from elsewhere (a stepper), so an open wheel shows it.
  var _wheelVersion = 0;

  /// The sleep being edited, linked (start, end, duration).
  LinkedSpan? _span;

  DateTime get _now => ref.read(assistantClockProvider)();

  @override
  void initState() {
    super.initState();
    if (_payload case SleepPayload(
      :final startedAt,
      :final endedAt,
      :final durationMin,
    )) {
      // A said length ("ngủ 9 tiếng") fills the missing end: woke up now, or start + length.
      final now = ref.read(assistantClockProvider)();
      final length = Duration(minutes: durationMin ?? 60);
      final end =
          endedAt ??
          startedAt?.add(length) ??
          now.subtract(Duration(minutes: now.minute % 5));
      final start = startedAt ?? end.subtract(length);
      _span = LinkedSpan(start, end);
    }
  }

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

  int? get _number => int.tryParse(_amount.text.trim());

  void _setNumber(int n) {
    _amount.text = '$n';
    setState(() {});
  }

  DraftPayload _withNumber() {
    final n = _number;
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
      SleepPayload() => SleepPayload(
        startedAt: _span?.start,
        endedAt: _span?.end,
      ),
      final p => p,
    };
  }

  /// A completed log's time: the wall time nearest the current one, never after now.
  DateTime _pickAt(DateTime? current, int h, int m) {
    var at = nearestWall(widget.zone, h, m, near: current ?? _now);
    if (at.isAfter(_now)) at = at.subtract(const Duration(days: 1));
    return at;
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

  void _toggle(_Wheeling w) =>
      setState(() => _wheel = _wheel == w ? _Wheeling.none : w);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    String day(DateTime at) => relativeDay(l10n, locale, at, widget.zone, now);
    final title = switch (_payload) {
      BreastPayload() => l10n.asEditBreast,
      SleepPayload() => l10n.asEditSleep,
      _ => l10n.asEditBottle,
    };
    final baby = Row(
      children: [
        ClIcon(ClIcons.lock, size: 12, color: cl.colors.inkMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            l10n.asBabyLockedLine(widget.babyName),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    );
    Widget whenTile(DateTime? at, void Function(DateTime) set) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TimeTile(
          key: const ValueKey('as.edit.at'),
          label: l10n.asFieldWhen,
          time: at == null ? '--:--' : hm(at, widget.zone),
          day: at == null ? l10n.asNoTime : day(at),
          selected: _wheel == _Wheeling.at,
          onTap: () => _toggle(_Wheeling.at),
        ),
        AsSize(
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
          child: _wheel == _Wheeling.at
              ? _ClockWheel(
                  key: ValueKey('as.wheel.at.$_wheelVersion'),
                  wall: inBabyZone(widget.zone, at ?? now),
                  onChanged: (h, m) => setState(() => set(_pickAt(at, h, m))),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
    final fields = <Widget>[
      ...switch (_payload) {
        final BottlePayload p => [
          whenTile(p.occurredAt, (at) => _payload = p.copyWith(occurredAt: at)),
          _Stepper(
            label: l10n.asFieldAmount,
            minusLabel: l10n.asLessMl,
            plusLabel: l10n.asMoreMl,
            onMinus: (_number ?? 0) > 10
                ? () => _setNumber((_number! - 10).clamp(10, bottleMaxMl))
                : null,
            onPlus: (_number ?? 0) < bottleMaxMl
                ? () => _setNumber(((_number ?? 0) + 10).clamp(10, bottleMaxMl))
                : null,
            value: _NumberField(
              controller: _amount,
              suffix: 'ml',
              label: l10n.asFieldAmount,
            ),
            quick: [
              for (final ml in const [60, 90, 120, 150, 180])
                (
                  label: '$ml ml',
                  selected: _number == ml,
                  onPressed: () => _setNumber(ml),
                ),
            ],
          ),
        ],
        final BreastPayload p => [
          whenTile(p.occurredAt, (at) => _payload = p.copyWith(occurredAt: at)),
          _Stepper(
            label: l10n.asFieldMinutes,
            minusLabel: l10n.asLessMinutes,
            plusLabel: l10n.asMoreMinutes,
            onMinus: (_number ?? 0) > 1
                ? () => _setNumber((_number! - 5).clamp(1, breastMaxMinutes))
                : null,
            onPlus: (_number ?? 0) < breastMaxMinutes
                ? () => _setNumber(
                    ((_number ?? 0) + 5).clamp(1, breastMaxMinutes),
                  )
                : null,
            value: _NumberField(
              controller: _amount,
              suffix: l10n.durationMinutes(0).replaceAll('0', '').trim(),
              label: l10n.asFieldMinutes,
            ),
            quick: [
              for (final m in const [5, 10, 15, 20, 30])
                (
                  label: l10n.durationMinutes(m),
                  selected: _number == m,
                  onPressed: () => _setNumber(m),
                ),
            ],
          ),
          _Label(l10n.asFieldSide),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final (wire, label) in [
                ('left', l10n.sideLeft),
                ('right', l10n.sideRight),
                ('both', l10n.sideBoth),
              ])
                _SideChip(
                  label: label,
                  selected: p.side == wire,
                  onPressed: () =>
                      setState(() => _payload = p.copyWith(side: wire)),
                ),
            ],
          ),
        ],
        SleepPayload() => _sleep(context, now, day),
        _ => const <Widget>[],
      },
      baby,
    ];
    return _EditorFrame(
      title: title,
      problems: _problems,
      busy: _busy,
      onSubmit: _submit,
      children: fields,
    );
  }

  /// The linked sleep: summary, start and end tiles (each opens its wheel), and the length
  /// stepper; a new start keeps the length, a new length or end moves the end.
  List<Widget> _sleep(
    BuildContext context,
    DateTime now,
    String Function(DateTime) day,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final span = _span!;
    void set(LinkedSpan next, {bool fromWheel = true}) => setState(() {
      _span = next;
      if (!fromWheel) _wheelVersion++;
    });
    final minutes = span.minutes;
    return [
      _SpanSummary(line: spanLine(l10n, locale, span, widget.zone, now)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TimeTile(
              key: const ValueKey('as.edit.start'),
              label: l10n.asFieldSleepStart,
              time: hm(span.start, widget.zone),
              day: day(span.start),
              selected: _wheel == _Wheeling.start,
              onTap: () => _toggle(_Wheeling.start),
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: _TimeTile(
              key: const ValueKey('as.edit.end'),
              label: l10n.asFieldSleepEnd,
              time: hm(span.end, widget.zone),
              day: day(span.end),
              selected: _wheel == _Wheeling.end,
              onTap: () => _toggle(_Wheeling.end),
            ),
          ),
        ],
      ),
      AsSize(
        duration: context.motion(ClMotion.quick),
        curve: ClCurves.quick,
        child: switch (_wheel) {
          _Wheeling.start => _ClockWheel(
            key: ValueKey('as.wheel.start.$_wheelVersion'),
            wall: inBabyZone(widget.zone, span.start),
            onChanged: (h, m) =>
                set(pickStart(_span!, widget.zone, h, m, now: now)),
          ),
          _Wheeling.end => _ClockWheel(
            key: ValueKey('as.wheel.end.$_wheelVersion'),
            wall: inBabyZone(widget.zone, span.end),
            onChanged: (h, m) => set(pickEnd(_span!, widget.zone, h, m)),
          ),
          _ => const SizedBox(width: double.infinity),
        },
      ),
      _Stepper(
        label: l10n.asFieldDuration,
        minusLabel: l10n.asShorter,
        plusLabel: l10n.asLonger,
        onMinus: minutes > 15
            ? () => set(span.withMinutes(minutes - 15), fromWheel: false)
            : null,
        onPlus: minutes < maxSpanMinutes
            ? () => set(span.withMinutes(minutes + 15), fromWheel: false)
            : null,
        value: Text(
          minutes > 0 ? durationLabel(l10n, minutes) : l10n.asSpanInvalid,
          key: const ValueKey('as.edit.duration'),
          style: context.cl.text.title2.copyWith(
            fontSize: 20,
            color: context.cl.colors.ink,
          ),
        ),
        quick: [
          for (final m in const [30, 60, 90, 120, 180])
            (
              label: durationLabel(l10n, m),
              selected: minutes == m,
              onPressed: () => set(span.withMinutes(m), fromWheel: false),
            ),
        ],
      ),
    ];
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.suffix,
    required this.label,
  });
  final TextEditingController controller;
  final String suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final style = cl.text.title2.copyWith(
      fontSize: 22,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cl.colors.ink,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        IntrinsicWidth(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            textAlign: TextAlign.center,
            style: style,
            cursorColor: cl.colors.mintDeep,
            decoration: InputDecoration.collapsed(
              hintText: '0',
              hintStyle: style.copyWith(color: cl.colors.inkMuted),
            ).copyWith(semanticCounterText: label),
          ),
        ),
        const SizedBox(width: 4),
        Text(suffix, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
      ],
    );
  }
}

class _SideChip extends StatelessWidget {
  const _SideChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: selected ? c.mintDeep : c.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ClIcon(
                icon!,
                size: 14,
                color: selected ? c.mintText : c.inkMuted,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: context.cl.text.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? c.mintText : c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LUMI-01: a pump, a diaper change or a measurement from chat, with the care forms' own fields
/// and ranges (PumpSheet: amount 1…1000 ml, side, length 1…240 min, start; DiaperSheet: the
/// three tiles and the time; GrowthScreen: weight 0,3…40 kg, optional length 20…150 cm, the
/// measuring date). Updates the draft only; saving stays on the card.
class _CareLogEditor extends ConsumerStatefulWidget {
  const _CareLogEditor({
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
  ConsumerState<_CareLogEditor> createState() => _CareLogEditorState();
}

class _CareLogEditorState extends ConsumerState<_CareLogEditor> {
  late DraftPayload _payload = widget.draft.payload;

  /// A pump's ml, a measurement's kg.
  final _first = TextEditingController();

  /// A pump's minutes, a measurement's cm.
  final _second = TextEditingController();
  var _filled = false;
  var _problems = <DraftProblem>[];
  var _busy = false;
  var _wheel = _Wheeling.none;

  DateTime get _now => ref.read(assistantClockProvider)();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    // Decimals as the app's language writes them ("5,2" / "5.2"); either separator parses.
    final locale = Localizations.localeOf(context).toLanguageTag();
    switch (_payload) {
      case PumpPayload(:final amountMl, :final durationMin):
        _first.text = amountMl == null ? '' : '${amountMl.round()}';
        _second.text = durationMin == null ? '' : '$durationMin';
      case GrowthPayload(:final weightKg, :final lengthCm):
        _first.text = weightKg == null
            ? ''
            : decimal(locale, weightKg.toDouble());
        _second.text = lengthCm == null
            ? ''
            : decimal(locale, lengthCm.toDouble());
      default:
        break;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  void _setInt(TextEditingController c, int n) {
    c.text = '$n';
    setState(() {});
  }

  /// One decimal, as the growth form keeps it; text that is not a number reads as out of range.
  num? _decimal(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final v = parseDecimal(c.text);
    return v == null ? 0 : (v * 10).round() / 10;
  }

  DraftPayload _built() => switch (_payload) {
    final PumpPayload p => PumpPayload(
      amountMl: _int(_first),
      occurredAt: p.occurredAt,
      side: p.side,
      durationMin: _int(_second),
      linkedDerived: p.linkedDerived,
    ),
    final GrowthPayload p => GrowthPayload(
      weightKg: _decimal(_first),
      lengthCm: _decimal(_second),
      measuredOn: p.measuredOn,
    ),
    final p => p,
  };

  /// A completed log's time: the wall time nearest the current one, never after now.
  DateTime _pickAt(DateTime? current, int h, int m) {
    var at = nearestWall(widget.zone, h, m, near: current ?? _now);
    if (at.isAfter(_now)) at = at.subtract(const Duration(days: 1));
    return at;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final payload = _built();
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

  /// The care forms' own words for what is out of range.
  String? _problemText(AppLocalizations l10n, DraftProblem p) {
    final built = _built();
    final fields = problemFields(built, p);
    return switch ((built, p)) {
      (PumpPayload(), DraftProblem.invalidAmount) =>
        fields.contains('amountMl')
            ? l10n.asGapPumpAmountRange
            : l10n.asGapPumpDurationRange,
      (GrowthPayload(), DraftProblem.missingAmount) =>
        l10n.growthWeightRequired,
      (GrowthPayload(), DraftProblem.invalidAmount) =>
        fields.contains('weightKg')
            ? l10n.growthWeightRequired
            : l10n.growthLengthRange,
      (GrowthPayload(), DraftProblem.missingDate) => l10n.asGapMeasuredOn,
      (GrowthPayload(), DraftProblem.futureTime) => l10n.asGapMeasuredOnFuture,
      _ => null,
    };
  }

  void _toggle(_Wheeling w) =>
      setState(() => _wheel = _wheel == w ? _Wheeling.none : w);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    String day(DateTime at) => relativeDay(l10n, locale, at, widget.zone, now);
    Widget timeTile(String label, DateTime? at, void Function(DateTime) set) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TimeTile(
              key: const ValueKey('as.edit.at'),
              label: label,
              time: at == null ? '--:--' : hm(at, widget.zone),
              day: at == null ? l10n.asNoTime : day(at),
              selected: _wheel == _Wheeling.at,
              onTap: () => _toggle(_Wheeling.at),
            ),
            AsSize(
              duration: context.motion(ClMotion.quick),
              curve: ClCurves.quick,
              child: _wheel == _Wheeling.at
                  ? _ClockWheel(
                      key: const ValueKey('as.wheel.at'),
                      wall: inBabyZone(widget.zone, at ?? now),
                      onChanged: (h, m) =>
                          setState(() => set(_pickAt(at, h, m))),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
    final baby = Row(
      children: [
        ClIcon(ClIcons.lock, size: 12, color: cl.colors.inkMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            l10n.asBabyLockedLine(widget.babyName),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    );
    final (title, fields) = switch (_payload) {
      final PumpPayload p => (
        l10n.asEditPump,
        <Widget>[
          _Stepper(
            label: l10n.asFieldAmount,
            minusLabel: l10n.asLessMl,
            plusLabel: l10n.asMoreMl,
            onMinus: (_int(_first) ?? 0) > 10
                ? () =>
                      _setInt(_first, (_int(_first)! - 10).clamp(10, pumpMaxMl))
                : null,
            onPlus: (_int(_first) ?? 0) < pumpMaxMl
                ? () => _setInt(
                    _first,
                    ((_int(_first) ?? 0) + 10).clamp(10, pumpMaxMl),
                  )
                : null,
            value: _NumberField(
              controller: _first,
              suffix: 'ml',
              label: l10n.asFieldAmount,
            ),
            quick: [
              for (final ml in const [60, 90, 120, 150, 200])
                (
                  label: '$ml ml',
                  selected: _int(_first) == ml,
                  onPressed: () => _setInt(_first, ml),
                ),
            ],
          ),
          _Label(l10n.asFieldSide),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final (wire, label) in [
                ('left', l10n.sideLeft),
                ('right', l10n.sideRight),
                ('both', l10n.sideBoth),
              ])
                _SideChip(
                  label: label,
                  selected: p.side == wire,
                  onPressed: () =>
                      setState(() => _payload = p.copyWith(side: wire)),
                ),
            ],
          ),
          _Stepper(
            label: l10n.asFieldMinutes,
            minusLabel: l10n.asLessMinutes,
            plusLabel: l10n.asMoreMinutes,
            onMinus: (_int(_second) ?? 0) > 1
                ? () => _setInt(
                    _second,
                    (_int(_second)! - 5).clamp(1, careMaxMinutes),
                  )
                : null,
            onPlus: (_int(_second) ?? 0) < careMaxMinutes
                ? () => _setInt(
                    _second,
                    ((_int(_second) ?? 0) + 5).clamp(1, careMaxMinutes),
                  )
                : null,
            value: _NumberField(
              controller: _second,
              suffix: l10n.durationMinutes(0).replaceAll('0', '').trim(),
              label: l10n.asFieldMinutes,
            ),
            quick: [
              for (final m in const [10, 15, 20, 30])
                (
                  label: l10n.durationMinutes(m),
                  selected: _int(_second) == m,
                  onPressed: () => _setInt(_second, m),
                ),
            ],
          ),
          timeTile(
            l10n.asFieldStart,
            p.occurredAt,
            (at) =>
                _payload = (_payload as PumpPayload).copyWith(occurredAt: at),
          ),
        ],
      ),
      final DiaperPayload p => (
        l10n.asEditDiaper,
        <Widget>[
          _Label(l10n.asFieldDiaper),
          Row(
            children: [
              for (final (i, (kind, art)) in const [
                ('wet', ClIllustration.miniDrop),
                ('dirty', ClIllustration.miniDiaper),
                ('both', ClIllustration.miniWetDirty),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: FittedBox(
                    child: ClChoiceTile(
                      key: ValueKey('as.edit.diaper.$kind'),
                      label: diaperWord(l10n, kind)!,
                      art: ClArt(art),
                      selected: p.diaper == kind,
                      onTap: () =>
                          setState(() => _payload = p.copyWith(diaper: kind)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          timeTile(
            l10n.asFieldWhen,
            p.occurredAt,
            (at) =>
                _payload = (_payload as DiaperPayload).copyWith(occurredAt: at),
          ),
        ],
      ),
      final GrowthPayload p => (
        l10n.asEditGrowth,
        <Widget>[
          _DecimalRow(
            key: const ValueKey('as.edit.weight'),
            label: l10n.asFieldWeight,
            controller: _first,
            unit: 'kg',
          ),
          _DecimalRow(
            key: const ValueKey('as.edit.length'),
            label: l10n.asFieldLength,
            controller: _second,
            unit: 'cm',
          ),
          ..._measuredOn(context, p, now),
        ],
      ),
      _ => (l10n.asEdit, const <Widget>[]),
    };
    return _EditorFrame(
      title: title,
      problems: _problems,
      problemText: (pr) => _problemText(l10n, pr) ?? problemLabel(l10n, pr),
      busy: _busy,
      onSubmit: _submit,
      children: [...fields, baby],
    );
  }

  /// "Ngày đo": a day already gone (up to three years back), on an inline date wheel.
  List<Widget> _measuredOn(
    BuildContext context,
    GrowthPayload p,
    DateTime now,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final wall = inBabyZone(widget.zone, now);
    final today = DateTime(wall.year, wall.month, wall.day);
    final first = today.subtract(const Duration(days: 3 * 366));
    final picked = p.measuredOn == null
        ? null
        : DateTime.tryParse(p.measuredOn!);
    final initial = picked == null || picked.isAfter(today)
        ? today
        : (picked.isBefore(first) ? first : picked);
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return [
      _TimeTile(
        key: const ValueKey('as.edit.measuredOn'),
        label: l10n.asFieldMeasuredOn,
        time: picked == null ? '--/--' : fullDate(locale, p.measuredOn!),
        day: picked == null
            ? l10n.asNoDate
            : picked == today
            ? l10n.asFixToday
            : weekdayDate(locale, p.measuredOn!),
        selected: _wheel == _Wheeling.start,
        onTap: () => _toggle(_Wheeling.start),
      ),
      AsSize(
        duration: context.motion(ClMotion.quick),
        curve: ClCurves.quick,
        child: _wheel == _Wheeling.start
            ? SizedBox(
                height: 160,
                child: _Wheel(
                  child: CupertinoDatePicker(
                    key: const ValueKey('as.wheel.measuredOn'),
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initial,
                    minimumDate: first,
                    maximumDate: today,
                    onDateTimeChanged: (d) => setState(
                      () => _payload = (_payload as GrowthPayload).copyWith(
                        measuredOn: iso(d),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ];
  }
}

/// A decimal number with its unit ("5,2 kg"), typed with either separator (the growth form).
class _DecimalRow extends StatelessWidget {
  const _DecimalRow({
    required this.label,
    required this.controller,
    required this.unit,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final style = cl.text.title2.copyWith(
      fontSize: 22,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: c.ink,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.controlBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: cl.text.label.copyWith(color: c.inkMuted),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          IntrinsicWidth(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(5),
              ],
              textAlign: TextAlign.end,
              style: style,
              cursorColor: c.mintDeep,
              decoration: InputDecoration.collapsed(
                hintText: '0',
                hintStyle: style.copyWith(color: c.inkMuted),
              ).copyWith(semanticCounterText: label),
            ),
          ),
          const SizedBox(width: 4),
          Text(unit, style: cl.text.label.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}
