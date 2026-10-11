import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import 'vaccine_format.dart';
import 'vaccine_models.dart';
import 'vaccine_photos.dart';
import 'vaccine_repository.dart';

// ---------- Shared bits ----------

/// The design's grey tip banner with a heart (VX 1, 1b, 2, 3, 7, 9a).
class VxBanner extends StatelessWidget {
  const VxBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(ClIcons.heart, size: 16, color: cl.colors.inkMuted),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              text,
              style: cl.text.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cl.colors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recording is for Cùng nuôi and Người chăm sóc (P-133).
bool vxCanLog(Membership me) => me.role != MemberRole.relative;

/// Cùng nuôi change anything; Người chăm sóc what they recorded (as D-022).
bool vxCanEdit(Membership me, DoseItem item) =>
    me.role == MemberRole.coParent ||
    (me.role == MemberRole.caregiver && item.record?.createdBy == me.uid);

/// "Đã lưu 6in1 mũi 1 · mũi 2 dự kiến 17/12" (VX 4).
void vxSavedToast(
  ClToaster toaster,
  AppLocalizations l10n,
  String locale,
  VaccineBook book,
  DoseItem item,
) {
  final title = vxDoseShort(l10n, locale, item, book.plan);
  final next = book.item(doseKeyOf(item.def.id, item.dose + 1));
  toaster.show(
    message: next != null && !next.done
        ? l10n.vxSavedNext(title, next.dose, vxDay(next.planned))
        : l10n.vxSaved(title),
  );
}

Future<DateTime?> pickVxDate(
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
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.vxPickDateTitle),
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
        ],
      );
    },
  );
}

Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
  var picked = initial;
  return showClSheet<TimeOfDay>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.vxTime),
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
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: 5,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  initial.hour,
                  initial.minute - initial.minute % 5,
                ),
                onDateTimeChanged: (d) =>
                    picked = TimeOfDay(hour: d.hour, minute: d.minute),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(picked),
          ),
        ],
      );
    },
  );
}

String _clock(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseClock(String? s) {
  if (s == null) return null;
  final p = s.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
}

/// The dose's header in sheets: icon chip, "6in1 · mũi 1", "Mốc 2 tháng tuổi".
class _DoseHeader extends StatelessWidget {
  const _DoseHeader({
    required this.title,
    required this.subtitle,
    this.icon = ClIcons.heart,
  });

  final String title;
  final String subtitle;
  final ClIcons icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: ClIcon(icon, size: 20, color: cl.colors.mintText),
        ),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 16)),
              Text(
                subtitle,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacePicker extends StatelessWidget {
  const _PlacePicker({required this.value, required this.onChanged});
  final VaccinePlace value;
  final ValueChanged<VaccinePlace> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClSegmented<VaccinePlace>(
      options: VaccinePlace.values,
      selected: value,
      labelOf: (p) => vxPlaceLabel(l10n, p),
      onChanged: onChanged,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3, bottom: ClSpace.s2),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontWeight: FontWeight.w600,
          color: cl.colors.inkMuted,
        ),
      ),
    );
  }
}

// ---------- VX 1a ----------

Future<void> showVaccineViewSheet(
  BuildContext context,
  WidgetRef ref,
) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final cl = sheet.cl;
    final view = ref.read(vaccineViewProvider);
    Widget row(VaccineView v, String title, String sub) => ClPressable(
      onPressed: () {
        ref.read(vaccineViewProvider.notifier).set(v);
        Navigator.of(sheet).pop();
      },
      selected: view == v,
      semanticLabel: '$title. $sub',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Radio(on: view == v),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 15)),
                  Text(
                    sub,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.vxViewTitle),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              row(
                VaccineView.byVaccine,
                l10n.vxViewByVaccine,
                l10n.vxViewByVaccineSub,
              ),
              row(VaccineView.byAge, l10n.vxViewByAge, l10n.vxViewByAgeSub),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  },
);

class _Radio extends StatelessWidget {
  const _Radio({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? c.mintDeep : c.controlBorder,
          width: on ? 7 : 1.5,
        ),
      ),
    );
  }
}

// ---------- VX 5 Tích nhanh ----------

/// "Đã tiêm Rota · mũi 1": which day (Hôm nay · Hôm qua · Chọn ngày) and where, then "Lưu" or
/// "Thêm chi tiết" for the full form (VX 3).
Future<void> showQuickDoseSheet(
  BuildContext context, {
  required Membership me,
  required VaccineBook book,
  required DoseItem item,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _QuickSheet(me: me, book: book, item: item),
);

class _QuickSheet extends ConsumerStatefulWidget {
  const _QuickSheet({required this.me, required this.book, required this.item});
  final Membership me;
  final VaccineBook book;
  final DoseItem item;

  @override
  ConsumerState<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends ConsumerState<_QuickSheet> {
  late DateTime _day = widget.book.today;
  var _picked = false;
  VaccinePlace _place = VaccinePlace.service;

  Future<void> _pickDay() async {
    final d = await pickVxDate(
      context,
      initial: _day,
      first: DateTime(widget.book.today.year - 6),
      last: widget.book.today,
    );
    if (d != null && mounted) {
      setState(() {
        _day = d;
        _picked = true;
      });
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final locale = vxLocale(context);
    final toaster = ClToaster.of(context);
    ref
        .read(vaccineRepositoryProvider)
        .save(
          babyId: widget.me.babyId,
          me: widget.me,
          item: widget.item,
          status: DoseRecordStatus.given,
          givenOn: _day,
          place: _place,
          onError: (_) => toaster.show(message: l10n.vxSaveFailed),
        );
    ClHaptics.success();
    Navigator.of(context).pop();
    vxSavedToast(toaster, l10n, locale, widget.book, widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    final today = widget.book.today;
    final yesterday = today.subtract(const Duration(days: 1));
    Widget chip(String label, bool on, VoidCallback onTap, {ClIcons? icon}) =>
        ClPressable(
          onPressed: onTap,
          selected: on,
          semanticLabel: label,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
            decoration: BoxDecoration(
              color: on ? cl.colors.mintDeep : cl.colors.surface2,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  ClIcon(
                    icon,
                    size: 16,
                    color: on ? cl.colors.onMintDeep : cl.colors.ink,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: on ? cl.colors.onMintDeep : cl.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s3),
        _DoseHeader(
          icon: ClIcons.check,
          title: l10n.vxQuickTitle(
            vxDoseTitle(l10n, locale, widget.item, widget.book.plan),
          ),
          subtitle: vxMilestone(l10n, widget.item.months),
        ),
        _Label(l10n.vxWhichDay),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            chip(
              l10n.vxDayToday,
              !_picked && _day == today,
              () => setState(() {
                _day = today;
                _picked = false;
              }),
            ),
            chip(
              l10n.vxDayYesterday,
              !_picked && _day == yesterday,
              () => setState(() {
                _day = yesterday;
                _picked = false;
              }),
            ),
            chip(
              _picked ? vxDate(_day) : l10n.vxPickDay,
              _picked,
              () => unawaited(_pickDay()),
              icon: ClIcons.cake,
            ),
          ],
        ),
        _Label(l10n.vxWhere),
        _PlacePicker(
          value: _place,
          onChanged: (p) => setState(() => _place = p),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(label: l10n.vxQuickSave, expand: true, onPressed: _save),
        ClButton(
          label: l10n.vxMoreDetails,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () {
            final nav = Navigator.of(context);
            final host = nav.context;
            nav.pop();
            unawaited(
              showDoseFormSheet(
                host,
                me: widget.me,
                book: widget.book,
                item: widget.item,
                day: _day,
                place: _place,
              ),
            );
          },
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- VX 3 Ghi mũi tiêm ----------

/// The full form: date, time, place, clinic, reaction and a photo of the book / slip.
/// With a record it edits it.
Future<void> showDoseFormSheet(
  BuildContext context, {
  required Membership me,
  required VaccineBook book,
  required DoseItem item,
  DateTime? day,
  VaccinePlace? place,
}) => showClSheet<void>(
  context: context,
  builder: (_) =>
      _FormSheet(me: me, book: book, item: item, day: day, place: place),
);

class _FormSheet extends ConsumerStatefulWidget {
  const _FormSheet({
    required this.me,
    required this.book,
    required this.item,
    this.day,
    this.place,
  });

  final Membership me;
  final VaccineBook book;
  final DoseItem item;
  final DateTime? day;
  final VaccinePlace? place;

  @override
  ConsumerState<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends ConsumerState<_FormSheet> {
  VaccineDoseRecord? get _given =>
      widget.item.record?.status == DoseRecordStatus.given
      ? widget.item.record
      : null;

  late DateTime _day =
      widget.day ??
      _given?.givenOn ??
      (widget.item.planned.isAfter(widget.book.today)
          ? widget.book.today
          : widget.item.planned);
  late TimeOfDay? _time = _parseClock(_given?.givenTime);
  late VaccinePlace _place =
      widget.place ?? _given?.place ?? VaccinePlace.service;
  late final _facility = TextEditingController(text: _given?.facility);
  late final _reaction = TextEditingController(text: _given?.reaction);
  late String? _photo = _given?.photoPath;
  bool _uploading = false;

  Future<void> _addPhoto() async {
    final path = await addVxPhoto(
      context,
      ref,
      widget.me.babyId,
      onBusy: (busy) {
        if (mounted) setState(() => _uploading = busy);
      },
    );
    if (path != null && mounted) setState(() => _photo = path);
  }

  void _removePhoto() {
    final path = _photo;
    setState(() => _photo = null);
    // A photo uploaded in this form and dropped before saving is not kept.
    if (path != null && path != _given?.photoPath) {
      unawaited(ref.read(vaccinePhotoStoreProvider).remove(path));
    }
  }

  @override
  void dispose() {
    _facility.dispose();
    _reaction.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final locale = vxLocale(context);
    final toaster = ClToaster.of(context);
    ref
        .read(vaccineRepositoryProvider)
        .save(
          babyId: widget.me.babyId,
          me: widget.me,
          item: widget.item,
          status: DoseRecordStatus.given,
          givenOn: _day,
          givenTime: _time == null ? null : _clock(_time!),
          place: _place,
          facility: _facility.text,
          reaction: _reaction.text,
          photoPath: _photo,
          clearPhoto: _photo == null,
          onError: (_) => toaster.show(message: l10n.vxSaveFailed),
        );
    ClHaptics.success();
    Navigator.of(context).pop();
    vxSavedToast(toaster, l10n, locale, widget.book, widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    Widget field(
      String label,
      ClIcons icon,
      String value,
      VoidCallback onTap,
    ) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          ClPressable(
            onPressed: onTap,
            semanticLabel: '$label: $value',
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cl.colors.controlBorder),
              ),
              child: Row(
                children: [
                  ClIcon(icon, size: 18, color: cl.colors.inkMuted),
                  const SizedBox(width: ClSpace.s2),
                  Text(value, style: cl.text.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: _given == null ? l10n.vxRecordTitle : l10n.vxEditTitle,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DoseHeader(
                  title: vxDoseTitle(
                    l10n,
                    locale,
                    widget.item,
                    widget.book.plan,
                  ),
                  subtitle: vxMilestone(l10n, widget.item.months),
                ),
                Row(
                  children: [
                    field(l10n.vxDate, ClIcons.cake, vxDate(_day), () async {
                      final d = await pickVxDate(
                        context,
                        initial: _day,
                        first: DateTime(widget.book.today.year - 6),
                        last: widget.book.today,
                      );
                      if (d != null && mounted) setState(() => _day = d);
                    }),
                    const SizedBox(width: ClSpace.s3),
                    field(
                      l10n.vxTime,
                      ClIcons.clock,
                      _time == null ? l10n.vxTimeNone : _clock(_time!),
                      () async {
                        final t = await _pickTime(
                          context,
                          _time ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (t != null && mounted) setState(() => _time = t);
                      },
                    ),
                  ],
                ),
                _Label(l10n.vxPlace),
                _PlacePicker(
                  value: _place,
                  onChanged: (p) => setState(() => _place = p),
                ),
                _Label(l10n.vxFacility),
                ClTextField(
                  controller: _facility,
                  placeholder: l10n.vxFacilityHint,
                  standalone: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                ),
                _Label(l10n.vxReaction),
                ClTextField(
                  controller: _reaction,
                  placeholder: l10n.vxReactionHint,
                  standalone: true,
                  maxLength: 300,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: ClSpace.s3),
                if (_photo case final path?)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: VxPhotoThumb(
                      key: const Key('vxFormPhoto'),
                      path: path,
                      onPressed: () => showVxPhotoViewer(context, [path]),
                      onRemove: _removePhoto,
                    ),
                  )
                else
                  VxPhotoButton(
                    label: l10n.vxPhotoTake,
                    busy: _uploading,
                    onPressed: () => unawaited(_addPhoto()),
                  ),
                const SizedBox(height: ClSpace.s4),
              ],
            ),
          ),
        ),
        ClButton(
          label: l10n.vxSave,
          expand: true,
          onPressed: _uploading ? null : _save,
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- VX 9a Xử lý mũi quá hạn ----------

Future<void> showOverdueSheet(
  BuildContext context, {
  required Membership me,
  required VaccineBook book,
  required DoseItem item,
}) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final cl = sheet.cl;
    final locale = vxLocale(sheet);
    final late = book.today.difference(item.planned).inDays;
    void then(Future<void> Function(BuildContext host) next) {
      final nav = Navigator.of(sheet);
      final host = nav.context;
      nav.pop();
      unawaited(next(host));
    }

    Widget row(
      ClIcons icon,
      Color tint,
      String title,
      String sub,
      VoidCallback onTap,
    ) => ClPressable(
      onPressed: onTap,
      semanticLabel: '$title. $sub',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 18, color: cl.colors.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 15)),
                  Text(
                    sub,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: vxDoseTitle(l10n, locale, item, book.plan)),
        Text(
          l10n.vxPlannedOverdue(vxDay(item.planned), late),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              row(
                ClIcons.check,
                cl.colors.mintSoft,
                l10n.vxAlreadyGiven,
                l10n.vxAlreadyGivenSub,
                () => then(
                  (host) =>
                      showQuickDoseSheet(host, me: me, book: book, item: item),
                ),
              ),
              row(
                ClIcons.clock,
                cl.colors.sunshineSoft,
                l10n.vxReschedule,
                l10n.vxRescheduleSub,
                () => then(
                  (host) =>
                      rescheduleDose(host, me: me, book: book, item: item),
                ),
              ),
              row(
                ClIcons.close,
                cl.colors.surface2,
                l10n.vxDecline,
                l10n.vxDeclineSub,
                () => then(
                  (host) =>
                      showDeclineSheet(host, me: me, book: book, item: item),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        VxBanner(l10n.vxCatchUp),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  },
);

/// "Dời lịch": a new planned date from today on; the reminder follows it (P-133).
Future<void> rescheduleDose(
  BuildContext context, {
  required Membership me,
  required VaccineBook book,
  required DoseItem item,
}) async {
  final l10n = AppLocalizations.of(context);
  final locale = vxLocale(context);
  final toaster = ClToaster.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final d = await pickVxDate(
    context,
    initial: book.today.add(const Duration(days: 1)),
    first: book.today,
    last: DateTime(book.today.year + 3),
  );
  if (d == null) return;
  container
      .read(vaccineRepositoryProvider)
      .save(
        babyId: me.babyId,
        me: me,
        item: item,
        status: DoseRecordStatus.planned,
        plannedOn: d,
        onError: (_) => toaster.show(message: l10n.vxSaveFailed),
      );
  toaster.show(
    message: l10n.vxRescheduled(
      vxDoseShort(l10n, locale, item, book.plan),
      vxDay(d),
    ),
  );
}

/// "Không tiêm mũi này": an optional reason, then the dose leaves the total.
Future<void> showDeclineSheet(
  BuildContext context, {
  required Membership me,
  required VaccineBook book,
  required DoseItem item,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _DeclineSheet(me: me, book: book, item: item),
);

class _DeclineSheet extends ConsumerStatefulWidget {
  const _DeclineSheet({
    required this.me,
    required this.book,
    required this.item,
  });
  final Membership me;
  final VaccineBook book;
  final DoseItem item;

  @override
  ConsumerState<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends ConsumerState<_DeclineSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = vxLocale(context);
    final title = vxDoseShort(l10n, locale, widget.item, widget.book.plan);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.vxDeclineTitle(title)),
        ClTextField(
          controller: _reason,
          placeholder: l10n.vxDeclineReasonHint,
          standalone: true,
          maxLength: 200,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: ClSpace.s3),
        VxBanner(l10n.vxCatchUp),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.vxQuickSave,
          expand: true,
          onPressed: () {
            final toaster = ClToaster.of(context);
            ref
                .read(vaccineRepositoryProvider)
                .save(
                  babyId: widget.me.babyId,
                  me: widget.me,
                  item: widget.item,
                  status: DoseRecordStatus.declined,
                  declineReason: _reason.text,
                  onError: (_) => toaster.show(message: l10n.vxSaveFailed),
                );
            Navigator.of(context).pop();
            toaster.show(message: l10n.vxDeclined(title));
          },
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- Recipients (VX 2 "Bạn, Ba Tuấn") ----------

/// Who gets the vaccination reminders: Cùng nuôi and Người chăm sóc (as D-051).
Future<void> showVaccineRecipientsSheet(
  BuildContext context, {
  required Membership me,
  required VaccinePlan plan,
  required List<Membership> members,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _RecipientsSheet(me: me, plan: plan, members: members),
);

class _RecipientsSheet extends ConsumerStatefulWidget {
  const _RecipientsSheet({
    required this.me,
    required this.plan,
    required this.members,
  });

  final Membership me;
  final VaccinePlan plan;
  final List<Membership> members;

  @override
  ConsumerState<_RecipientsSheet> createState() => _RecipientsSheetState();
}

class _RecipientsSheetState extends ConsumerState<_RecipientsSheet> {
  late final _chosen = {...vxRecipients(widget.plan, widget.members)};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final eligible = widget.members.where(vxCanReceive).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.vxRecipientsTitle),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final m in eligible)
                ClPressable(
                  onPressed: () => setState(
                    () => _chosen.contains(m.uid)
                        ? _chosen.remove(m.uid)
                        : _chosen.add(m.uid),
                  ),
                  selected: _chosen.contains(m.uid),
                  semanticLabel: m.displayName,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.uid == widget.me.uid
                                ? l10n.careYouSuffix(m.displayName)
                                : m.displayName,
                            style: cl.text.bodyStrong.copyWith(fontSize: 15),
                          ),
                        ),
                        ClIcon(
                          _chosen.contains(m.uid)
                              ? ClIcons.check
                              : ClIcons.plus,
                          size: 18,
                          color: _chosen.contains(m.uid)
                              ? cl.colors.mintText
                              : cl.colors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: () {
            final toaster = ClToaster.of(context);
            ref
                .read(vaccineRepositoryProvider)
                .savePlan(
                  widget.me.babyId,
                  widget.me,
                  widget.plan.copyWith(recipients: _chosen.toList()),
                  onError: (_) => toaster.show(message: l10n.vxSaveFailed),
                );
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

bool vxCanReceive(Membership m) =>
    m.isActive &&
    (m.role == MemberRole.coParent || m.role == MemberRole.caregiver);

/// The plan's recipients, or everyone who can receive until Cùng nuôi choose.
List<String> vxRecipients(VaccinePlan plan, List<Membership> members) =>
    plan.exists && plan.recipients.isNotEmpty
    ? plan.recipients
    : [
        for (final m in members)
          if (vxCanReceive(m)) m.uid,
      ];
