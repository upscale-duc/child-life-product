import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../feedback/review_prompt.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show trackerArt;
import '../solids/solids_sheet.dart' show openMealSheet;
import '../solids/solids_today.dart' show SdQuickLogTile, sdQuickLogProvider;
import 'bottle_suggestions.dart';
import 'care_format.dart';
import 'care_models.dart';
import 'care_repository.dart';
import 'timer_models.dart';
import 'timer_screens.dart';

/// Care colours of a type (tokens `care/<type>/soft|ink|accent`).
ClCareColor careColor(BuildContext context, CareType type) {
  final care = context.cl.care;
  return switch (type) {
    CareType.bottle => care.bottle,
    CareType.breast => care.breast,
    CareType.pump => care.pump,
    CareType.sleep => care.sleep,
    CareType.diaper => care.diaper,
    CareType.growth => care.growth,
  };
}

ClIllustration careArt(CareType type) => switch (type) {
  CareType.bottle => trackerArt(TrackerKind.bottle),
  CareType.breast => trackerArt(TrackerKind.breast),
  CareType.pump => trackerArt(TrackerKind.pump),
  CareType.sleep => trackerArt(TrackerKind.sleep),
  CareType.diaper => trackerArt(TrackerKind.diaper),
  CareType.growth => trackerArt(TrackerKind.growth),
};

/// The last save, so Today's tile can glow and show ✓ (Motion 270:22 step 4, 24 annotation).
final lastSavedProvider = NotifierProvider<LastSaved, (CareType, int)?>(
  LastSaved.new,
);

class LastSaved extends Notifier<(CareType, int)?> {
  @override
  (CareType, int)? build() => null;

  void mark(CareType type) => state = (type, (state?.$2 ?? 0) + 1);
}

/// Opens the log for [type] (19a / tiles): sheets for feeds, pumping and diapers, the full
/// screen 28 for growth. Sleep arrives with timers (S5). [edit] prefills "Sửa" (21).
Future<void> openCareLog(
  BuildContext context,
  CareType type, {
  CareRecord? edit,
  DateTime? at,
}) {
  switch (type) {
    case CareType.growth:
      return context.push(Routes.growth, extra: edit);
    case CareType.sleep:
      // 26: a past sleep, or "Sửa" on a sleep record.
      return context.push(Routes.manualSleep, extra: edit ?? at);
    case CareType.bottle || CareType.breast:
      return showClSheet<void>(
        context: context,
        builder: (_) => FeedSheet(initialType: type, edit: edit, at: at),
      );
    case CareType.pump:
      return showClSheet<void>(
        context: context,
        builder: (_) => PumpSheet(edit: edit, at: at),
      );
    case CareType.diaper:
      return showClSheet<void>(
        context: context,
        builder: (_) => DiaperSheet(edit: edit, at: at),
      );
  }
}

/// Saves [record] (new or edited) without waiting for the server, then: success haptic, the
/// tile glow and "Đã ghi · Bú bình 120 ml · Hoàn tác" (Motion 270:22).
void commitRecord(
  BuildContext context,
  WidgetRef ref,
  CareRecord record, {
  required bool isEdit,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final repo = ref.read(careRepositoryProvider);
  final me = ref.read(selectedMembershipProvider);
  if (me == null) return;
  // Toasts outlive the sheet (and a write that fails later).
  final toaster = ClToaster.of(context);
  void Function(Object) failed(CareWrite write) => (e) {
    // FB5: no rating prompt after an error (D-065).
    ReviewSession.afterError = true;
    toaster.show(
      message: careWriteFailed(l10n, locale, write, e, record),
      error: true,
    );
  };

  if (isEdit) {
    repo.edit(record, me.uid, onError: failed(CareWrite.edit));
  } else {
    repo.create(record, onError: failed(CareWrite.create));
    // FB5: logs count towards "≥ 10 logs" and a full week of logs is a happy moment.
    unawaited(ref.read(reviewPrompterProvider).logged(DateTime.now()));
  }
  ClHaptics.success();
  ref.read(lastSavedProvider.notifier).mark(record.type);
  Navigator.of(context).maybePop();
  if (isEdit) {
    toaster.show(message: l10n.editedToast);
  } else {
    toaster.show(
      message: l10n.savedToast(recordSummary(l10n, locale, record)),
      actionLabel: l10n.undo,
      onAction: () =>
          repo.softDelete(record, me.uid, onError: failed(CareWrite.delete)),
    );
  }
}

/// 19a Ghi nhanh (50:3572): six coloured tiles, one tap opens the matching log.
Future<void> showQuickLog(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final host = context;
    Widget tile(CareType type, String label) => Expanded(
      child: _QuickTile(
        type: type,
        label: label,
        onTap: () {
          Navigator.of(sheetContext).pop();
          if (type == CareType.sleep) {
            // D-025: "Ngủ" starts the timer at once (or opens the running one).
            openOrStartTimer(host, TimerType.sleep);
          } else {
            openCareLog(host, type);
          }
        },
        // "nhấn giữ để nhập thủ công" (19a).
        onLongPress: type == CareType.sleep
            ? () {
                Navigator.of(sheetContext).pop();
                host.push(Routes.manualSleep);
              }
            : null,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClSheetHeader(title: l10n.quickLogTitle),
        // Three per row; two at large text sizes so labels break between words, not inside them.
        for (final (i, row) in _rowsOf(
          [
            tile(CareType.bottle, l10n.trackerBottle),
            tile(CareType.breast, l10n.trackerBreast),
            tile(CareType.sleep, l10n.quickSleep),
            tile(CareType.diaper, l10n.trackerDiaper),
            tile(CareType.growth, l10n.trackerGrowth),
            tile(CareType.pump, l10n.trackerPump),
          ],
          MediaQuery.textScalerOf(sheetContext).scale(10) > 13 ? 2 : 3,
        ).indexed) ...[
          if (i > 0) const SizedBox(height: ClSpace.s3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (j, t) in row.indexed) ...[
                  if (j > 0) const SizedBox(width: ClSpace.s3),
                  t,
                ],
              ],
            ),
          ),
        ],
        // Ăn dặm (P-164 #1): while tracking is on, for who logs.
        Consumer(
          builder: (_, ref, _) => ref.watch(sdQuickLogProvider)
              ? Padding(
                  padding: const EdgeInsets.only(top: ClSpace.s3),
                  child: SdQuickLogTile(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(openMealSheet(host));
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  },
);

List<List<T>> _rowsOf<T>(List<T> items, int perRow) => [
  for (var i = 0; i < items.length; i += perRow)
    items.sublist(i, (i + perRow).clamp(0, items.length)),
];

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.type,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final CareType type;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final care = careColor(context, type);
    return ClPressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: label,
      child: Container(
        // 120 at default text; taller (never clipped) when the label grows.
        constraints: const BoxConstraints(minHeight: 120),
        width: double.infinity,
        decoration: BoxDecoration(
          color: care.soft,
          borderRadius: BorderRadius.circular(ClRadius.tile),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s2,
          vertical: ClSpace.s1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 52, height: 52, child: ClArt(careArt(type))),
            const SizedBox(height: ClSpace.s2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: cl.text.headline.copyWith(color: care.ink, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet frame for 22 / 23 / 23a / 24: header in the care ink, content, primary above the
/// keyboard ("nút Lưu luôn nằm trên bàn phím", 46:3141).
class CareSheetFrame extends StatelessWidget {
  const CareSheetFrame({
    required this.title,
    required this.titleColor,
    required this.children,
    required this.primary,
    super.key,
  });

  final String title;
  final Color titleColor;
  final List<Widget> children;
  final Widget primary;

  @override
  Widget build(BuildContext context) {
    // The sheet itself keeps clear of the keyboard and the home indicator (cl_sheet.dart).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title, titleColor: titleColor),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        primary,
      ],
    );
  }
}

/// Editable AmountField (45:403): numeral-xl, unit after the number, mint focus ring. The
/// system number pad replaces the Figma keypad mock ("system keypad in production").
class AmountInput extends StatefulWidget {
  const AmountInput({
    required this.controller,
    required this.unit,
    this.decimal = false,
    this.autofocus = false,
    this.semanticLabel,
    this.height = 88,
    super.key,
  });

  final TextEditingController controller;
  final String unit;
  final bool decimal;
  final bool autofocus;
  final String? semanticLabel;
  final double height;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final focused = _focus.hasFocus;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: focused ? cl.colors.mintSoft : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.card),
          // Resting: the shared 1 px input stroke; focused: the 2 px mint ring (the numeral is
          // centred, so the extra pixel does not move it).
          border: Border.all(
            color: focused ? cl.colors.mintDeep : clInputStroke(cl),
            width: focused ? 2 : 1,
          ),
        ),
        // Half-width fields (28) scale the numeral down rather than overflow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: Semantics(
                  label: widget.semanticLabel,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.decimal,
                    ),
                    inputFormatters: [
                      widget.decimal
                          ? FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            )
                          : FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    cursorColor: cl.colors.mintDeep,
                    style: cl.text.numeralXl.copyWith(color: cl.colors.ink),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: cl.text.numeralXl.copyWith(
                        color: cl.colors.inkMuted.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Text(
                widget.unit,
                style: cl.text.headline.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Bây giờ · 15:05", "Hôm nay · 14:20", "Hôm qua · 21:42", "1 thg 10 · 08:00".
String timeChipLabel(
  BuildContext context,
  DateTime at, {
  required bool isNow,
  DateTime? now,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final hm = DateFormat.Hm(locale).format(at);
  if (isNow) return l10n.timeNow(hm);
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(at);
  if (day == today) return l10n.timeToday(hm);
  if (day == today.subtract(const Duration(days: 1))) {
    return l10n.timeYesterday(hm);
  }
  return '${DateFormat('d MMM', locale).format(at)} · $hm';
}

/// TimeRow wheel: date + time, never in the future (G-021).
Future<DateTime?> pickCareTime(
  BuildContext context, {
  required DateTime initial,
  DateTime? earliest,
}) {
  final now = DateTime.now();
  var picked = initial.isAfter(now) ? now : initial;
  return showClSheet<DateTime>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final cl = sheetContext.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.timePickerTitle),
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: cl.isNightCare ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: cl.text.title2.copyWith(
                    color: cl.colors.ink,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                initialDateTime: picked,
                maximumDate: now,
                minimumDate: earliest ?? now.subtract(const Duration(days: 60)),
                use24hFormat: true,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(picked),
          ),
        ],
      );
    },
  );
}

/// Duration wheel in minutes (23a "Thời lượng · 15 phút").
Future<int?> pickDuration(BuildContext context, {required int initial}) {
  var picked = initial.clamp(1, CareLimits.durationMin.max);
  return showClSheet<int>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final cl = sheetContext.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.durationPickerTitle),
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: picked - 1,
              ),
              onSelectedItemChanged: (i) => picked = i + 1,
              children: [
                for (var m = 1; m <= CareLimits.durationMin.max; m++)
                  Center(
                    child: Text(
                      durationLabel(l10n, m),
                      style: cl.text.title2.copyWith(color: cl.colors.ink),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(picked),
          ),
        ],
      );
    },
  );
}

/// Label above a field ("Lượng sữa · tùy chọn").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
    child: Text(
      text,
      style: context.cl.text.label.copyWith(color: context.cl.colors.inkMuted),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: ClSpace.s2),
          child: Semantics(
            liveRegion: true,
            child: Text(
              text!,
              style: context.cl.text.label.copyWith(
                color: context.cl.colors.error,
              ),
            ),
          ),
        );
}

/// Mixin for the sheets' shared state: id (stable for retries), time, membership, memory.
mixin _CareSheetState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final String recordId = newRecordId();
  DateTime? _time;
  bool _timeTouched = false;

  DateTime get time => _time ?? DateTime.now();

  void initTime(DateTime? editTime) {
    if (editTime != null) {
      _time = editTime;
      _timeTouched = true;
    }
  }

  Widget timeRow(String label) => ClTimeRow(
    label: label,
    value: timeChipLabel(
      context,
      _timeTouched ? time : (ref.watch(careClockProvider).value ?? time),
      isNow: !_timeTouched,
      now: ref.watch(careClockProvider).value,
    ),
    onTap: () async {
      final picked = await pickCareTime(context, initial: time);
      if (picked != null && mounted) {
        setState(() {
          _time = picked;
          _timeTouched = true;
        });
      }
    },
  );

  Membership? get me => ref.read(selectedMembershipProvider);
  CareMemory get memory => ref.read(careMemoryProvider);
}

int? _intOrNull(TextEditingController c) => int.tryParse(c.text.trim());

String? _rangeError(
  AppLocalizations l10n,
  int? value,
  ({int min, int max}) range,
  String unit,
) => value != null && (value < range.min || value > range.max)
    ? l10n.amountRange('${range.min}', '${range.max}', unit)
    : null;

/// 22 / 23 Ghi cữ bú: Bú bình | Bú mẹ, remembering the last type and milk (46:3141, 46:3234).
class FeedSheet extends ConsumerStatefulWidget {
  const FeedSheet({required this.initialType, this.edit, this.at, super.key});
  final CareType initialType;
  final CareRecord? edit;

  /// "Ghi bù" (20e): a time on an earlier day.
  final DateTime? at;

  @override
  ConsumerState<FeedSheet> createState() => _FeedSheetState();
}

class _FeedSheetState extends ConsumerState<FeedSheet>
    with _CareSheetState<FeedSheet> {
  late CareType _type;
  late MilkType _milk;

  /// Chosen by the user (or the edited record); otherwise the suggestion is live.
  Side? _side;
  final _amount = TextEditingController();
  final _minutes = TextEditingController();
  String? _error;

  /// v1.0 improvement 22: the last bottle of this baby, prefilled into a new log.
  CareRecord? _lastBottle;
  var _built = false;
  bool get _prefilled =>
      widget.edit == null &&
      _lastBottle?.amountMl != null &&
      _amount.text == '${_lastBottle!.amountMl}';

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    final babyId = me?.babyId ?? '';
    initTime(edit?.occurredAt ?? widget.at);
    _type = edit?.type ?? widget.initialType;
    _milk =
        edit?.milk ??
        memory.get(babyId, 'milk', MilkType.values) ??
        MilkType.breastMilk;
    _side = edit?.side;
    if (edit?.amountMl != null) _amount.text = '${edit!.amountMl}';
    if (edit?.durationMin != null) _minutes.text = '${edit!.durationMin}';
    if (edit == null) {
      // "nhớ lần trước" (346:47151): start from the last bottle's amount, once the records
      // are in, unless something was typed already.
      ref.listenManual(recentRecordsProvider(babyId), (_, next) {
        final last = next.value
            ?.where((r) => r.type == CareType.bottle)
            .firstOrNull;
        if (last == null || _lastBottle != null || !mounted) return;
        // Already loaded, this runs inside initState: no setState until built.
        _lastBottle = last;
        if (last.amountMl != null && _amount.text.isEmpty) {
          _amount.text = '${last.amountMl}';
        }
        if (_built) setState(() {});
      }, fireImmediately: true);
    }
    _amount.addListener(() => setState(() => _error = null));
    _minutes.addListener(() => setState(() => _error = null));
  }

  /// "nhớ bên lần trước, gợi ý bên còn lại" (46:3234): the other side of the last feed.
  Side get _effectiveSide {
    if (_side != null) return _side!;
    final babyId = me?.babyId ?? '';
    final recent = ref.watch(recentRecordsProvider(babyId)).value ?? const [];
    final last = recent.where((r) => r.type == CareType.breast).firstOrNull;
    return switch (last?.side) {
      Side.left => Side.right,
      Side.right => Side.left,
      _ => Side.both,
    };
  }

  @override
  void dispose() {
    _amount.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final me = this.me;
    if (me == null) return;
    final bottle = _type == CareType.bottle;
    final amount = bottle ? _intOrNull(_amount) : null;
    final minutes = bottle ? null : _intOrNull(_minutes);
    final error = bottle
        ? _rangeError(l10n, amount, CareLimits.bottleMl, 'ml')
        : _rangeError(l10n, minutes, CareLimits.durationMin, l10n.unitMinutes);
    if (error != null) return setState(() => _error = error);
    memory
      ..set(me.babyId, 'feedType', _type)
      ..set(me.babyId, 'milk', _milk);
    final start = CareRecord.spanStart(_type, time, minutes, DateTime.now());
    final edit = widget.edit;
    final record = edit != null
        ? edit.copyWith(
            occurredAt: start,
            amountMl: amount,
            clearAmount: amount == null,
            milk: _milk,
            side: _side,
            durationMin: minutes,
            clearDuration: minutes == null,
          )
        : CareRecord.create(
            id: recordId,
            babyId: me.babyId,
            type: _type,
            occurredAt: start,
            me: me,
            amountMl: amount,
            milk: bottle ? _milk : null,
            side: bottle ? null : _effectiveSide,
            durationMin: minutes,
          );
    commitRecord(context, ref, record, isEdit: edit != null);
  }

  @override
  Widget build(BuildContext context) {
    _built = true;
    final l10n = AppLocalizations.of(context);
    final bottle = _type == CareType.bottle;
    final care = careColor(context, _type);
    return CareSheetFrame(
      title: l10n.feedSheetTitle,
      titleColor: care.ink,
      primary: ClButton(label: l10n.saveFeed, expand: true, onPressed: _save),
      children: [
        // The type cannot change on an edit (Rules keep `type` immutable).
        if (widget.edit == null)
          ClSegmented<CareType>(
            options: const [CareType.bottle, CareType.breast],
            selected: _type,
            labelOf: (t) =>
                t == CareType.bottle ? l10n.trackerBottle : l10n.trackerBreast,
            onChanged: (t) => setState(() {
              _type = t;
              _error = null;
            }),
          ),
        if (bottle) ...[
          FieldLabel(_prefilled ? l10n.amountFromLast : l10n.amountOptional),
          AmountInput(
            controller: _amount,
            unit: 'ml',
            autofocus: widget.edit == null,
            semanticLabel: l10n.amountOptional,
          ),
          _ErrorText(_error),
          if (widget.edit == null) ...[
            const SizedBox(height: ClSpace.s3),
            _QuickPicks(
              last: _lastBottle,
              selected: _intOrNull(_amount),
              onPick: (ml) => _amount.text = '$ml',
            ),
          ],
          const SizedBox(height: ClSpace.s4),
          Row(
            children: [
              Text(l10n.milkTypeLabel, style: context.cl.text.label),
              const SizedBox(width: ClSpace.s3),
              // "Row scrolls horizontally; last chip may peek" (FilterChip 45:347).
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (i, milk) in MilkType.values.indexed) ...[
                        if (i > 0) const SizedBox(width: ClSpace.s2),
                        ClFilterChip(
                          label: milkLabel(l10n, milk),
                          selected: _milk == milk,
                          onTap: () => setState(() => _milk = milk),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          timeRow(l10n.timeLabel),
        ] else ...[
          FieldLabel(l10n.sideLabel),
          ClSegmented<Side>(
            options: Side.values,
            selected: _effectiveSide,
            labelOf: (s) => sideLabel(l10n, s),
            onChanged: (s) => setState(() => _side = s),
          ),
          FieldLabel(l10n.durationOptional),
          AmountInput(
            controller: _minutes,
            unit: l10n.unitMinutes,
            semanticLabel: l10n.durationOptional,
          ),
          _ErrorText(_error),
          const SizedBox(height: ClSpace.s2),
          timeRow(l10n.startLabel),
          if (widget.edit == null)
            ClButton(
              label: l10n.timerInstead,
              style: ClButtonStyle.plain,
              icon: ClIcons.clock,
              expand: true,
              onPressed: () {
                openOrStartTimer(
                  context,
                  TimerType.breast,
                  side: _effectiveSide == Side.right ? Side.right : Side.left,
                );
                Navigator.of(context).removeRoute(ModalRoute.of(context)!);
              },
            ),
        ],
      ],
    );
  }
}

/// 23a Ghi hút sữa (106:11118): side, amount (required), duration wheel, start time. Pumped
/// milk is never baby intake (R-054). Per-side amounts (G-062) and the timer (S5) come later.
class PumpSheet extends ConsumerStatefulWidget {
  const PumpSheet({this.edit, this.timer, this.at, super.key});
  final CareRecord? edit;
  final DateTime? at;

  /// "Xong · nhập lượng sữa" (23c): the stopped pump timer this save ends.
  final CareTimer? timer;

  @override
  ConsumerState<PumpSheet> createState() => _PumpSheetState();
}

class _PumpSheetState extends ConsumerState<PumpSheet>
    with _CareSheetState<PumpSheet> {
  late Side _side;
  int? _minutes;
  final _amount = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    final timer = widget.timer;
    initTime(edit?.occurredAt ?? timer?.startedAt ?? widget.at);
    if (timer != null) {
      final record = timer.toRecord(DateTime.now());
      _minutes = record.durationMin;
    }
    _side =
        timer?.toRecord(DateTime.now()).side ??
        edit?.side ??
        memory.get(me?.babyId ?? '', 'pumpSide', Side.values) ??
        Side.both;
    _minutes ??= edit?.durationMin;
    if (edit?.amountMl != null) _amount.text = '${edit!.amountMl}';
    _amount.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final me = this.me;
    if (me == null) return;
    final amount = _intOrNull(_amount);
    final error = amount == null
        ? l10n.amountRange(
            '${CareLimits.pumpMl.min}',
            '${CareLimits.pumpMl.max}',
            'ml',
          )
        : _rangeError(l10n, amount, CareLimits.pumpMl, 'ml');
    if (error != null) return setState(() => _error = error);
    memory.set(me.babyId, 'pumpSide', _side);
    final timer = widget.timer;
    if (timer != null) {
      final record = timer
          .toRecord(
            DateTime.now(),
            pumpAmountMl: amount,
            by: (uid: me.uid, author: CareAuthor.of(me)),
          )
          .copyWith(
            side: _side,
            durationMin: _minutes,
            occurredAt: CareRecord.spanStart(
              CareType.pump,
              time,
              _minutes,
              DateTime.now(),
            ),
          );
      final toaster = ClToaster.of(context);
      final l10n = AppLocalizations.of(context);
      ref
          .read(careRepositoryProvider)
          .endTimer(
            timer,
            record,
            onError: (e) => toaster.show(
              message: careWriteFailed(
                l10n,
                Localizations.localeOf(context).toLanguageTag(),
                CareWrite.create,
                e,
                record,
              ),
              error: true,
            ),
          );
      ClHaptics.success();
      ref.read(lastSavedProvider.notifier).mark(CareType.pump);
      Navigator.of(context).pop();
      if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
      toaster.show(
        message: l10n.savedToast(
          recordSummary(
            l10n,
            Localizations.localeOf(context).toLanguageTag(),
            record,
          ),
        ),
      );
      return;
    }
    final edit = widget.edit;
    final start = CareRecord.spanStart(
      CareType.pump,
      time,
      _minutes,
      DateTime.now(),
    );
    final record = edit != null
        ? edit.copyWith(
            occurredAt: start,
            side: _side,
            amountMl: amount,
            durationMin: _minutes,
            clearDuration: _minutes == null,
          )
        : CareRecord.create(
            id: recordId,
            babyId: me.babyId,
            type: CareType.pump,
            occurredAt: start,
            me: me,
            side: _side,
            amountMl: amount,
            durationMin: _minutes,
          );
    commitRecord(context, ref, record, isEdit: edit != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CareSheetFrame(
      title: l10n.pumpTitle,
      titleColor: careColor(context, CareType.pump).ink,
      primary: ClButton(label: l10n.savePump, expand: true, onPressed: _save),
      children: [
        FieldLabel(l10n.sideLabel),
        ClSegmented<Side>(
          options: Side.values,
          selected: _side,
          labelOf: (s) => sideLabel(l10n, s),
          onChanged: (s) => setState(() => _side = s),
        ),
        FieldLabel(l10n.amountLabel),
        AmountInput(
          controller: _amount,
          unit: 'ml',
          autofocus: widget.edit == null,
          semanticLabel: l10n.amountLabel,
        ),
        _ErrorText(_error),
        const SizedBox(height: ClSpace.s2),
        ClTimeRow(
          label: l10n.durationLabel,
          value: _minutes == null
              ? l10n.durationNone
              : durationLabel(l10n, _minutes!),
          onTap: () async {
            final picked = await pickDuration(context, initial: _minutes ?? 15);
            if (picked != null && mounted) setState(() => _minutes = picked);
          },
        ),
        timeRow(l10n.startLabel),
        if (widget.edit == null && widget.timer == null)
          ClButton(
            label: l10n.timerInstead,
            style: ClButtonStyle.plain,
            icon: ClIcons.clock,
            expand: true,
            onPressed: () {
              openOrStartTimer(context, TimerType.pump, side: _side);
              Navigator.of(context).removeRoute(ModalRoute.of(context)!);
            },
          ),
      ],
    );
  }
}

/// 24 Thay tã (46:3308): two taps — choose → Lưu; defaults to the last kind.
class DiaperSheet extends ConsumerStatefulWidget {
  const DiaperSheet({this.edit, this.at, super.key});
  final CareRecord? edit;
  final DateTime? at;

  @override
  ConsumerState<DiaperSheet> createState() => _DiaperSheetState();
}

class _DiaperSheetState extends ConsumerState<DiaperSheet>
    with _CareSheetState<DiaperSheet> {
  late DiaperKind _kind;

  @override
  void initState() {
    super.initState();
    initTime(widget.edit?.occurredAt ?? widget.at);
    _kind =
        widget.edit?.diaper ??
        memory.get(me?.babyId ?? '', 'diaper', DiaperKind.values) ??
        DiaperKind.wet;
  }

  void _save() {
    final me = this.me;
    if (me == null) return;
    memory.set(me.babyId, 'diaper', _kind);
    final edit = widget.edit;
    final record = edit != null
        ? edit.copyWith(occurredAt: time, diaper: _kind)
        : CareRecord.create(
            id: recordId,
            babyId: me.babyId,
            type: CareType.diaper,
            occurredAt: time,
            me: me,
            diaper: _kind,
          );
    commitRecord(context, ref, record, isEdit: edit != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ClIllustration art(DiaperKind k) => switch (k) {
      DiaperKind.wet => ClIllustration.miniDrop,
      DiaperKind.dirty => ClIllustration.miniDiaper,
      DiaperKind.both => ClIllustration.miniWetDirty,
    };
    return CareSheetFrame(
      title: l10n.diaperTitle,
      titleColor: careColor(context, CareType.diaper).ink,
      primary: ClButton(label: l10n.saveDiaper, expand: true, onPressed: _save),
      children: [
        Row(
          children: [
            for (final (i, kind) in DiaperKind.values.indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s3),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => FittedBox(
                    child: ClChoiceTile(
                      label: diaperChoice(l10n, kind),
                      art: ClArt(art(kind)),
                      selected: _kind == kind,
                      onTap: () => setState(() => _kind = kind),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        timeRow(l10n.timeLabel),
      ],
    );
  }
}

/// 22 "gợi ý nhanh" (346:47151): four amounts for the baby's age (reference data, P-138), and
/// what was given last time.
class _QuickPicks extends ConsumerWidget {
  const _QuickPicks({
    required this.last,
    required this.selected,
    required this.onPick,
  });

  final CareRecord? last;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final dob = me == null || !me.canViewBabyInfo
        ? null
        : ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth;
    final today = DateUtils.dateOnly(
      ref.watch(careClockProvider).value ?? DateTime.now(),
    );
    final age = dob == null
        ? null
        : today.difference(DateUtils.dateOnly(dob)).inDays;
    // P-138: the approved C02 table when one is published, else the bundled P-126 copy. The
    // last amount stays first (prefilled above); 22 draws no ± adjuster, so stepMl is unused.
    final picks = bottleSuggestions(age, ref.watch(bottleTableProvider));
    final zone =
        (me == null ? null : ref.watch(babyProvider(me.babyId)).value)
            ?.timeZone
            .zone ??
        'Asia/Ho_Chi_Minh';
    final caption = cl.text.caption.copyWith(
      color: cl.colors.inkMuted,
      fontWeight: FontWeight.w500,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (i, ml) in picks.indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s2),
              Expanded(
                child: ClPressable(
                  onPressed: () => onPick(ml),
                  selected: selected == ml,
                  semanticLabel: l10n.bottleQuickPick(ml),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected == ml
                          ? cl.colors.mintDeep
                          : cl.colors.surface2,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$ml',
                            style: cl.text.bodyStrong.copyWith(fontSize: 15),
                          ),
                          TextSpan(
                            text: ' ml',
                            style: cl.text.caption.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: selected == ml
                            ? cl.colors.onMintDeep
                            : cl.colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (last?.amountMl != null)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClIcon(ClIcons.clock, size: 14, color: cl.colors.inkMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.lastBottleAt(
                          last!.amountMl!,
                          DateFormat(
                            'HH:mm',
                          ).format(inBabyZone(zone, last!.occurredAt)),
                        ),
                        style: caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (age != null) ...[
              const SizedBox(width: ClSpace.s2),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClIcon(ClIcons.cake, size: 14, color: cl.colors.inkMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        age < 7
                            ? l10n.bottleSuggestNewborn
                            : l10n.bottleSuggestFor(
                                age < 13 * 7
                                    ? l10n.whoWeeks(age ~/ 7)
                                    : l10n.whoMonths((age / 30.4375).floor()),
                              ),
                        style: caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
