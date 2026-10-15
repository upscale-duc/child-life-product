import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/navigation.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_status.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../memories/album_models.dart' show MessageContext;
import '../memories/social_widgets.dart' show showMessageComposer;
import 'care_format.dart';
import 'care_models.dart';
import 'care_repository.dart';
import 'care_sheets.dart';

/// Whether [me] may edit or delete [record] (Q-012 → D-022; Rules `canEditRecord`).
bool canEditRecord(Membership me, CareRecord record) =>
    me.role == MemberRole.coParent ||
    (me.role == MemberRole.caregiver && record.createdBy == me.uid);

String _relation(AppLocalizations l10n, Relation r, String custom) =>
    relationLabel(l10n, r, custom);

/// "Mẹ ghi" / "Cô Lan ghi" / "Bạn ghi".
String loggedBy(AppLocalizations l10n, CareRecord r, String myUid) =>
    l10n.careLoggedBy(
      authorLabel(
        l10n,
        r.author,
        isMe: r.createdBy == myUid,
        relationLabel: (rel, c) => _relation(l10n, rel, c),
      ),
    );

/// 28 Tăng trưởng (47:3210): date, weight (required), length (optional), the change since
/// the last measurement — "không bách phân vị, không đánh giá" — and previous measurements.
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({this.edit, super.key});
  final CareRecord? edit;

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen> {
  late final String _id = widget.edit?.id ?? newRecordId();
  late DateTime _date = DateUtils.dateOnly(
    widget.edit?.measuredOn ?? ref.read(timerClockProvider)(),
  );
  final _weight = TextEditingController();
  final _length = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag();
    final edit = widget.edit;
    if (edit?.weightKg != null) _weight.text = decimal(locale, edit!.weightKg!);
    if (edit?.lengthCm != null) _length.text = decimal(locale, edit!.lengthCm!);
    _weight.addListener(() => setState(() => _error = null));
    _length.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _weight.dispose();
    _length.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final weight = parseDecimal(_weight.text);
    final length = _length.text.trim().isEmpty
        ? null
        : parseDecimal(_length.text);
    if (weight == null ||
        weight < CareLimits.weightKg.min ||
        weight > CareLimits.weightKg.max) {
      return setState(() => _error = l10n.growthWeightRequired);
    }
    if (_length.text.trim().isNotEmpty &&
        (length == null ||
            length < CareLimits.lengthCm.min ||
            length > CareLimits.lengthCm.max)) {
      return setState(() => _error = l10n.growthLengthRange);
    }
    // One decimal, as the field shows ("4,3 kg").
    final w = (weight * 10).round() / 10;
    final l = length == null ? null : (length * 10).round() / 10;
    final today = DateUtils.dateOnly(ref.read(timerClockProvider)());
    final at = _date == today
        ? DateTime.now()
        : DateTime(_date.year, _date.month, _date.day, 12);
    final edit = widget.edit;
    final record = edit != null
        ? edit.copyWith(
            occurredAt: at,
            weightKg: w,
            lengthCm: l,
            clearLength: l == null,
            measuredOn: _date,
          )
        : CareRecord.create(
            id: _id,
            babyId: me.babyId,
            type: CareType.growth,
            occurredAt: at,
            me: me,
            weightKg: w,
            lengthCm: l,
            measuredOn: _date,
          );
    commitRecord(context, ref, record, isEdit: edit != null);
  }

  Future<void> _pickDate(DateTime? dob) async {
    final today = DateUtils.dateOnly(DateTime.now());
    var picked = _date;
    final result = await showClSheet<DateTime>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final cl = sheetContext.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.growthDate),
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: cl.isNightCare
                      ? Brightness.dark
                      : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: cl.text.title2.copyWith(
                      color: cl.colors.ink,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: picked,
                  maximumDate: today,
                  minimumDate:
                      dob ?? today.subtract(const Duration(days: 365 * 3)),
                  dateOrder:
                      Localizations.localeOf(sheetContext).languageCode == 'vi'
                      ? DatePickerDateOrder.dmy
                      : null,
                  onDateTimeChanged: (d) => picked = DateUtils.dateOnly(d),
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
    if (result != null && mounted) setState(() => _date = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final dob = me.canViewBabyInfo
        ? ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
        : null;
    final all = ref.watch(growthRecordsProvider(me.babyId)).value ?? const [];
    final previous = [
      for (final r in all)
        if (r.id != _id) r,
    ];
    // The measurement before the one being entered, by measurement date.
    final before = previous
        .where((r) => !(r.measuredOn ?? r.occurredAt).isAfter(_date))
        .firstOrNull;
    final weight = parseDecimal(_weight.text);
    final length = parseDecimal(_length.text);
    String? delta;
    if (before != null && weight != null) {
      String signed(double v, String unit) =>
          '${v >= 0 ? '+' : '−'}${decimal(locale, v.abs())} $unit';
      final parts = [
        signed(weight - (before.weightKg ?? 0), 'kg'),
        if (length != null && before.lengthCm != null)
          signed(length - before.lengthCm!, 'cm'),
      ];
      delta = l10n.growthDeltaSince(
        parts.join(' · '),
        shortDate(context, before.measuredOn ?? before.occurredAt),
      );
    }
    final today = DateUtils.dateOnly(
      ref.watch(careClockProvider).value ?? DateTime.now(),
    );
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.pop(),
        trailing: baby == null
            ? null
            : ClBabySwitcher(
                label: dob == null
                    ? baby.nickname
                    : l10n.babySwitcherLabel(
                        baby.nickname,
                        ageShort(l10n, dob, today),
                      ),
                avatar: SavedBabyAvatar(baby: baby, size: 32),
              ),
      ),
      content: [
        ScreenHeading(title: l10n.growthTitle),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClTimeRow(
                icon: ClIcons.ruler,
                label: l10n.growthDate,
                value: _date == today
                    ? l10n.todayTitle
                    : DateFormat('d MMM y', locale).format(_date),
                onTap: () => _pickDate(dob),
              ),
              const SizedBox(height: ClSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FieldLabel(l10n.growthWeight),
                        AmountInput(
                          controller: _weight,
                          unit: 'kg',
                          decimal: true,
                          autofocus: widget.edit == null,
                          semanticLabel: l10n.growthWeight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FieldLabel(l10n.growthLengthOptional),
                        AmountInput(
                          controller: _length,
                          unit: 'cm',
                          decimal: true,
                          semanticLabel: l10n.growthLengthOptional,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: ClSpace.s2),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: cl.text.label.copyWith(color: cl.colors.error),
                  ),
                ),
              ] else if (delta != null) ...[
                const SizedBox(height: ClSpace.s3),
                Text(
                  delta,
                  style: cl.text.label.copyWith(color: cl.care.growth.ink),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(
          title: l10n.growthPrevious,
          linkLabel: l10n.growthSeeAll,
          // D-076 nav: 28 is above the tabs; Lịch sử is a Chăm sóc page.
          onLink: () => context.pushSafe('${Routes.history}?filter=growth'),
        ),
        const SizedBox(height: ClSpace.s2),
        if (previous.isEmpty)
          Text(
            l10n.growthNoPrevious,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          )
        else
          ClCardGroup(
            shadow: true,
            children: [
              for (final r in previous.take(5))
                LogRow(
                  record: r,
                  title: [
                    l10n.weightKg(decimal(locale, r.weightKg ?? 0)),
                    if (r.lengthCm != null)
                      l10n.lengthCm(decimal(locale, r.lengthCm!)),
                  ].join(' · '),
                  subtitle: [
                    shortDate(context, r.measuredOn ?? r.occurredAt),
                    if (dob != null &&
                        r.measuredOn != null &&
                        DateUtils.isSameDay(r.measuredOn, dob))
                      l10n.growthAtBirth,
                    loggedBy(l10n, r, me.uid),
                  ].join(' · '),
                ),
            ],
          ),
      ],
      bottom: [
        ClButton(label: l10n.saveGrowth, expand: true, onPressed: _save),
      ],
    );
  }
}

/// LogRow (45:373): care icon, "what · detail", "time · who"; pending shows "Chờ" (icon +
/// words). Tap → 21.
class LogRow extends StatelessWidget {
  const LogRow({
    required this.record,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final CareRecord record;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final care = careColor(context, record.type);
    return ClPressable(
      onPressed: () => context.push('${Routes.record}/${record.id}'),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: record.pending
          ? '$title, $subtitle, ${l10n.carePending}'
          : '$title, $subtitle',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: care.soft,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: ClArt(careArt(record.type)),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: cl.text.bodyStrong),
                    Text(
                      subtitle,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (record.pending) ...[
                PendingChip(label: l10n.pendingChip),
                const SizedBox(width: ClSpace.s2),
              ],
              ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Chờ" chip (9b): cloud-off + word on sunshine-soft, never colour alone.
class PendingChip extends StatelessWidget {
  const PendingChip({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: c.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.cloudOff, size: 14, color: c.pending),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.cl.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: c.pending,
            ),
          ),
        ],
      ),
    );
  }
}

/// 21 Chi tiết bản ghi (46:2649) and 12e (192:32463, view only): what, when, who, when it was
/// logged and its sync state. Edit / delete only with the right (D-022); delete asks, then
/// "Đã xóa · Hoàn tác" for 5 s.
class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({required this.recordId, super.key});
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    final record = me == null
        ? null
        : ref.watch(careRecordProvider((me.babyId, recordId))).value;
    if (me == null || record == null || record.deleted) {
      return OnboardingScaffold(
        topBar: ClTopBar(onBack: () => context.popOrToday()),
        content: [
          const SizedBox(height: ClSpace.s8),
          Center(
            child: Text(
              l10n.recordGone,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      );
    }
    final care = careColor(context, record.type);
    final editable = canEditRecord(me, record);
    final hm = DateFormat.Hm(locale);
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    String when(DateTime at) {
      final today = DateUtils.dateOnly(now);
      final day = DateUtils.dateOnly(at);
      if (day == today) return l10n.timeToday(hm.format(at));
      if (day == today.subtract(const Duration(days: 1))) {
        return l10n.timeYesterday(hm.format(at));
      }
      return '${DateFormat('d MMM', locale).format(at)} · ${hm.format(at)}';
    }

    final subtitle = switch (record.type) {
      CareType.bottle => milkLabel(l10n, record.milk ?? MilkType.formula),
      CareType.breast ||
      CareType.pump => sideLabel(l10n, record.side ?? Side.both),
      _ => null,
    };
    final author = authorLabel(
      l10n,
      record.author,
      isMe: false,
      relationLabel: (r, c) => _relation(l10n, r, c),
    );

    Widget row(String label, Widget value) => Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          value,
        ],
      ),
    );
    Widget text(String v) => Text(v, style: cl.text.bodyStrong);

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.popOrToday(),
        trailing: editable
            ? ClButton(
                label: l10n.actionEdit,
                style: ClButtonStyle.tinted,
                icon: ClIcons.edit,
                onPressed: () =>
                    openCareLog(context, record.type, edit: record),
              )
            : null,
      ),
      content: [
        Container(
          padding: const EdgeInsets.all(ClSpace.s6),
          decoration: BoxDecoration(
            color: care.soft,
            borderRadius: BorderRadius.circular(ClRadius.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [careTypeLabel(l10n, record.type), ?subtitle].join(' · '),
                      style: cl.text.label.copyWith(color: care.ink),
                    ),
                    Text(
                      recordValue(l10n, locale, record),
                      style: cl.text.numeralXl.copyWith(color: cl.colors.ink),
                    ),
                    Text(
                      when(record.occurredAt).replaceFirst(' · ', ', '),
                      style: cl.text.body.copyWith(color: care.ink),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: ClArt(careArt(record.type)),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, w) in [
                row(l10n.detailTime, text(when(record.occurredAt))),
                if (record.type == CareType.breast ||
                    record.type == CareType.pump)
                  if (record.durationMin != null)
                    row(
                      l10n.detailDuration,
                      text(durationLabel(l10n, record.durationMin!)),
                    ),
                if (record.type == CareType.growth && record.lengthCm != null)
                  row(
                    l10n.detailLength,
                    text(l10n.lengthCm(decimal(locale, record.lengthCm!))),
                  ),
                row(
                  l10n.detailBy,
                  text(
                    authorFull(
                      l10n,
                      record.author,
                      isMe: record.createdBy == me.uid,
                      relationLabel: (r, c) => _relation(l10n, r, c),
                    ),
                  ),
                ),
                row(l10n.detailLoggedAt, text(hm.format(record.loggedAt))),
                row(
                  l10n.detailSync,
                  ClSyncStatus(
                    state: record.pending
                        ? ClSyncState.pending
                        : ClSyncState.synced,
                    label: record.pending ? l10n.carePending : l10n.retrySynced,
                  ),
                ),
              ].indexed) ...[
                if (i > 0) Container(height: 1, color: cl.colors.separator),
                w,
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        if (record.pending)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: Text(
              l10n.syncPendingLong,
              style: cl.text.label.copyWith(color: cl.colors.pending),
            ),
          ),
        if (editable)
          Text(
            l10n.detailFooter,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.viewOnlyNote(author),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
      ],
      bottom: [
        if (editable)
          ClButton(
            label: l10n.deleteRecord,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => _confirmDelete(context, ref, record, me),
          )
        else if (me.role != MemberRole.relative)
          ClButton(
            label: l10n.messageAuthor(author),
            style: ClButtonStyle.secondary,
            expand: true,
            // "Nhắn Mẹ" (D-034): one-way to the parents, about this record.
            onPressed: () => showMessageComposer(
              context,
              kind: MessageContext.record,
              contextId: record.id,
              title: l10n.messageTo(author),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CareRecord record,
    Membership me,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showClSheet<bool>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.deleteConfirmTitle),
          Text(
            l10n.deleteConfirmBody,
            style: sheetContext.cl.text.body.copyWith(
              color: sheetContext.cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.deleteRecord,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(careRepositoryProvider);
    final toaster = ClToaster.of(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);

    repo.softDelete(record, me.uid, onError: failed);
    context.popOrToday();
    toaster.show(
      message: l10n.deletedToast,
      actionLabel: l10n.undo,
      visibleFor: const Duration(seconds: 5),
      onAction: () => repo.restore(record, me.uid, onError: failed),
    );
  }
}

/// 9b Chờ đồng bộ (127:14970): what is only on this device, and "Thử lại ngay".
Future<void> showPendingSheet(BuildContext context) =>
    showClSheet<void>(context: context, builder: (_) => const _PendingSheet());

class _PendingSheet extends ConsumerStatefulWidget {
  const _PendingSheet();

  @override
  ConsumerState<_PendingSheet> createState() => _PendingSheetState();
}

class _PendingSheetState extends ConsumerState<_PendingSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    final pending = me == null
        ? const <CareRecord>[]
        : [
            for (final r
                in ref.watch(recentRecordsProvider(me.babyId)).value ??
                    const [])
              if (r.pending) r,
          ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.pendingTitle),
        for (final r in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s3),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    DateFormat.Hm(locale).format(r.occurredAt),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: careColor(context, r.type).soft,
                    shape: BoxShape.circle,
                  ),
                  child: ClArt(careArt(r.type)),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recordSummary(l10n, locale, r),
                        style: cl.text.bodyStrong,
                      ),
                      Text(
                        l10n.pendingOnlyHere,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                PendingChip(label: l10n.pendingChip),
              ],
            ),
          ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.pendingFootnote,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.retryNow,
          style: ClButtonStyle.secondary,
          expand: true,
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final ok = await ref.read(careRepositoryProvider).retryNow();
                  if (!mounted) return;
                  setState(() => _busy = false);
                  if (ok) {
                    // The toast lives in the root overlay, so it outlasts the sheet.
                    showClToast(this.context, message: l10n.retrySynced);
                    Navigator.of(this.context).pop();
                  } else {
                    showClToast(this.context, message: l10n.retryStill);
                  }
                },
        ),
      ],
    );
  }
}
