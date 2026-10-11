import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:timezone/timezone.dart' as tz;

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../baby/time_zones.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import 'device_identity.dart';
import 'reminder_models.dart';
import 'reminder_notifications.dart';
import 'reminder_repository.dart';

// ---------- Labels ----------

/// "Mẹ" / "Cô Lan" / "Bạn" (D-024).
String reminderWho(AppLocalizations l10n, CareAuthor author, bool isMe) =>
    authorLabel(
      l10n,
      author,
      isMe: isMe,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );

/// "1 giờ" / "Đúng giờ" / "1 ngày" (D-031).
String leadLabel(AppLocalizations l10n, int minutes) => switch (minutes) {
  0 => l10n.leadOnTime,
  1440 => l10n.leadOneDay,
  _ => durationLabel(l10n, minutes),
};

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "T7, 10 thg 10 · 08:30" (8b, 8e).
String reminderWhenShort(String locale, DateTime wall) {
  final day = locale.startsWith('vi')
      ? (wall.weekday == DateTime.sunday ? 'CN' : 'T${wall.weekday + 1}')
      : DateFormat.E(locale).format(wall);
  return '$day, ${DateFormat('d MMM', locale).format(wall)} · '
      '${DateFormat('HH:mm').format(wall)}';
}

/// "Thứ Bảy, 10 thg 10 · 08:30" (8a upcoming rows).
String reminderWhenLong(String locale, DateTime wall) =>
    '${_cap(DateFormat('EEEE, d MMM', locale).format(wall))} · '
    '${DateFormat('HH:mm').format(wall)}';

/// "hôm qua 18:00" / "hôm nay 07:00" / "5 thg 10 18:00" (8a overdue rows).
String reminderWhenRelative(
  AppLocalizations l10n,
  String locale,
  DateTime wall,
  DateTime today,
) {
  final day = DateTime(wall.year, wall.month, wall.day);
  final hm = DateFormat('HH:mm').format(wall);
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => '${l10n.dayToday} $hm',
    -1 => '${l10n.dayYesterday} $hm',
    1 => '${l10n.dayTomorrow} $hm',
    _ => '${DateFormat('d MMM', locale).format(wall)} $hm',
  };
}

/// Wall-clock time in [zone] → the absolute instant.
DateTime instantInZone(String zone, DateTime wall) {
  ensureTimeZones();
  try {
    return tz.TZDateTime(
      tz.getLocation(zone),
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    ).toUtc();
  } on Object {
    return wall;
  }
}

/// Context every reminder screen needs.
typedef ReminderCtx = ({
  Membership me,
  String zone,
  String nickname,
  DateTime now,
  String locale,
});

ReminderCtx? _context(BuildContext context, WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  return (
    me: me,
    zone: baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
    nickname: baby?.nickname ?? '',
    now: ref.watch(careClockProvider).value ?? ref.read(timerClockProvider)(),
    locale: Localizations.localeOf(context).toLanguageTag(),
  );
}

// ---------- 8a / 12f list ----------

/// 8a Nhắc việc (127:13602) for Cùng nuôi; 12f (192:1327) for caregivers: view and mark done.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final all = ref.watch(remindersProvider(c.me.babyId)).value;
    final groups = groupReminders(all ?? const [], c.now);
    final parent = c.me.role == MemberRole.coParent;
    final device = ref.watch(deviceIdentityProvider).value;
    final enabled = ref.watch(notificationsEnabledProvider);
    // 8d: asked already (8c), and this device holds a notification that cannot show.
    final blocked =
        enabled == false &&
        ref.watch(notificationsAskedProvider) &&
        device != null &&
        (all ?? const []).any(
          (r) =>
              !r.done &&
              r.notifyDevice?.id == device.id &&
              r.fireAt.isAfter(c.now),
        );

    Widget group(String title, List<Reminder> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
          child: Semantics(
            header: true,
            child: Text(title, style: cl.text.headline),
          ),
        ),
        ClCardGroup(
          children: [for (final r in items) ReminderRow(reminder: r, ctx: c)],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(nickname: c.nickname),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClTabDock.contentBottomPadding + ClSpace.s6,
                ),
                children: [
                  Text(
                    c.nickname,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                  Semantics(
                    header: true,
                    child: Text(l10n.remindersTitle, style: cl.text.largeTitle),
                  ),
                  if (blocked) ...[
                    const SizedBox(height: ClSpace.s4),
                    const _NotificationsOffCard(),
                  ],
                  if (!parent) ...[
                    const SizedBox(height: ClSpace.s3),
                    _Note(
                      icon: ClIcons.clock,
                      text: l10n.remindersCaregiverNote,
                    ),
                  ],
                  if (all != null &&
                      groups.overdue.isEmpty &&
                      groups.upcoming.isEmpty &&
                      groups.done.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s6),
                      child: Column(
                        children: [
                          Text(
                            l10n.remindersEmpty,
                            style: cl.text.headline,
                            textAlign: TextAlign.center,
                          ),
                          if (parent) ...[
                            const SizedBox(height: ClSpace.s2),
                            Text(
                              l10n.remindersEmptyBody,
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (groups.overdue.isNotEmpty)
                    group(l10n.remindersOverdue, groups.overdue),
                  if (groups.upcoming.isNotEmpty)
                    group(l10n.remindersUpcoming, groups.upcoming),
                  if (groups.done.isNotEmpty)
                    group(l10n.remindersDone, groups.done),
                  const SizedBox(height: ClSpace.s4),
                  _Note(icon: ClIcons.clock, text: l10n.remindersInfo),
                  if (parent) ...[
                    const SizedBox(height: ClSpace.s4),
                    ClButton(
                      label: l10n.reminderNew,
                      icon: ClIcons.plus,
                      expand: true,
                      onPressed: () => showReminderSheet(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, 0),
      child: ClTopBar(
        onBack: () => context.pop(),
        trailing: baby == null
            ? null
            : ClBabySwitcher(
                label: baby.nickname,
                avatar: SavedBabyAvatar(baby: baby, size: 32),
              ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final ClIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ClIcon(icon, size: 16, color: cl.colors.inkMuted),
        ),
        const SizedBox(width: ClSpace.s2),
        Expanded(
          child: Text(
            text,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// 8d (127:13867): "Đã lưu nhắc việc. Chưa bật thông báo trên máy này." + "Cài đặt".
class _NotificationsOffCard extends StatelessWidget {
  const _NotificationsOffCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s2,
        ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.bell, size: 20, color: cl.colors.ink),
          const SizedBox(width: ClSpace.s3),
          Expanded(child: Text(l10n.remindersNotifOff, style: cl.text.label)),
          ClButton(
            label: l10n.remindersOpenSettings,
            style: ClButtonStyle.plain,
            onPressed: openNotificationSettings,
          ),
        ],
      ),
    );
  }
}

/// ReminderRow (126:683): Upcoming · Overdue (error ring and meta) · Done (mint check, muted,
/// no chevron). The ring marks done; on a done row it undoes (D-030).
class ReminderRow extends ConsumerWidget {
  const ReminderRow({required this.reminder, required this.ctx, super.key});

  final Reminder reminder;
  final ReminderCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = reminder;
    final status = r.statusAt(ctx.now);
    final today = babyToday(ctx.zone, ctx.now);
    final wall = inBabyZone(ctx.zone, r.dueAt);
    final who = reminderWho(l10n, r.author, r.createdBy == ctx.me.uid);
    final meta = switch (status) {
      ReminderStatus.upcoming =>
        '${reminderWhenLong(ctx.locale, wall)} · ${l10n.reminderCreatedBy(who)}',
      ReminderStatus.overdue =>
        '${l10n.reminderOverdueMeta(reminderWhenRelative(l10n, ctx.locale, wall, today))}'
            ' · ${l10n.reminderCreatedBy(who)}',
      ReminderStatus.done => l10n.reminderDoneMeta(
        reminderWho(l10n, r.doneAuthor ?? r.author, r.doneBy == ctx.me.uid),
        DateFormat(
          'd MMM',
          ctx.locale,
        ).format(inBabyZone(ctx.zone, r.doneAt ?? r.dueAt)),
      ),
    };
    final overdue = status == ReminderStatus.overdue;
    final done = status == ReminderStatus.done;
    final canUndo =
        ctx.me.role == MemberRole.coParent || r.doneBy == ctx.me.uid;
    return ClPressable(
      onPressed: () => context.push('${Routes.reminders}/${r.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s2,
          ClSpace.s2,
          ClSpace.s4,
          ClSpace.s2,
        ),
        child: Row(
          children: [
            ClPressable(
              semanticLabel: done
                  ? l10n.a11yUndoDone(r.title)
                  : l10n.a11yMarkDone(r.title),
              onPressed: done && !canUndo
                  ? null
                  : () => setReminderDone(context, ref, r, done: !done),
              child: SizedBox(
                width: ClSpace.tapMin,
                height: ClSpace.tapMin,
                child: Center(
                  child: _Check(done: done, overdue: overdue),
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: cl.text.bodyStrong.copyWith(
                      color: done ? cl.colors.inkMuted : cl.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: cl.text.caption.copyWith(
                      color: overdue ? cl.colors.error : cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!done) ...[
              const SizedBox(width: ClSpace.s2),
              ClIcon(ClIcons.chevronRight, size: 20, color: cl.colors.inkMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.overdue});
  final bool done;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? cl.colors.mintDeep : null,
        border: done
            ? null
            : Border.all(
                color: overdue ? cl.colors.error : cl.colors.inkMuted,
                width: 1.8,
              ),
      ),
      child: done
          ? ClIcon(ClIcons.check, size: 16, color: cl.colors.onMintDeep)
          : null,
    );
  }
}

/// Marks done (or undoes, D-030) without waiting for the server; toast with "Hoàn tác".
void setReminderDone(
  BuildContext context,
  WidgetRef ref,
  Reminder r, {
  required bool done,
}) {
  final me = ref.read(selectedMembershipProvider);
  if (me == null) return;
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(reminderRepositoryProvider);
  final toaster = ClToaster.of(context);
  void failed(Object _) => toaster.show(message: l10n.careSaveFailed);
  if (done) ClHaptics.success();
  repo.setDone(r, me, done: done, onError: failed);
  toaster.show(
    message: done ? l10n.reminderMarkedDone : l10n.reminderMarkedUndone,
    actionLabel: l10n.undo,
    onAction: () => repo.setDone(r, me, done: !done, onError: failed),
  );
}

// ---------- 8e detail ----------

/// 8e Chi tiết nhắc việc (127:13910).
class ReminderDetailScreen extends ConsumerWidget {
  const ReminderDetailScreen({required this.reminderId, super.key});
  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final list = ref.watch(remindersProvider(c.me.babyId)).value;
    final r = list?.where((x) => x.id == reminderId).firstOrNull;
    if (r == null) {
      // Deleted meanwhile (D-030) or not loaded yet.
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: SafeArea(child: _TopBar(nickname: c.nickname)),
      );
    }
    final parent = c.me.role == MemberRole.coParent;
    final device = ref.watch(deviceIdentityProvider).value;
    final wall = inBabyZone(c.zone, r.dueAt);
    final status = r.statusAt(c.now);
    final mine = device != null && r.notifyDevice?.id == device.id;
    // "iPhone của Mai"; on that device the row has no chevron (nothing to move).
    final notify = r.notifyDevice == null
        ? l10n.reminderNoDevice
        : l10n.reminderDeviceOf(r.notifyDevice!.label, r.notifyDevice!.owner);
    final created = [
      reminderWho(l10n, r.author, r.createdBy == c.me.uid),
      if (r.createdAt != null)
        DateFormat('d MMM', c.locale).format(inBabyZone(c.zone, r.createdAt!)),
    ].join(' · ');
    final canUndo = parent || r.doneBy == c.me.uid;

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(nickname: c.nickname),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClTabDock.contentBottomPadding + ClSpace.s6,
                ),
                children: [
                  Text(
                    l10n.reminderOverline(c.nickname),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                  Semantics(
                    header: true,
                    child: Text(r.title, style: cl.text.largeTitle),
                  ),
                  if (status == ReminderStatus.overdue)
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s1),
                      child: Text(
                        l10n.remindersOverdue,
                        style: cl.text.label.copyWith(color: cl.colors.error),
                      ),
                    ),
                  const SizedBox(height: ClSpace.s4),
                  ClCardGroup(
                    children: [
                      ClDetailRow(
                        icon: ClIcons.today,
                        label: l10n.reminderWhen,
                        value: reminderWhenShort(c.locale, wall),
                        onTap: parent && !r.done
                            ? () => showReminderSheet(context, edit: r)
                            : null,
                      ),
                      ClDetailRow(
                        icon: ClIcons.globe,
                        label: l10n.reminderTimeZone,
                        value: gmtOffsetLabel(c.zone, r.dueAt),
                      ),
                      ClDetailRow(
                        icon: ClIcons.clock,
                        label: l10n.reminderLead,
                        value: leadLabel(l10n, r.leadMinutes),
                        onTap: parent && !r.done
                            ? () => showReminderSheet(context, edit: r)
                            : null,
                      ),
                      ClDetailRow(
                        icon: ClIcons.bell,
                        label: l10n.reminderNotify,
                        value: notify,
                        onTap: mine || r.done || device == null
                            ? null
                            : () => _moveHere(context, ref, r, c.me, device),
                      ),
                      ClDetailRow(
                        icon: ClIcons.family,
                        label: l10n.reminderCreator,
                        value: created,
                      ),
                      if (r.done)
                        ClDetailRow(
                          icon: ClIcons.check,
                          label: l10n.reminderDoneRow,
                          value: [
                            reminderWho(
                              l10n,
                              r.doneAuthor ?? r.author,
                              r.doneBy == c.me.uid,
                            ),
                            DateFormat(
                              'd MMM',
                              c.locale,
                            ).format(inBabyZone(c.zone, r.doneAt ?? r.dueAt)),
                          ].join(' · '),
                        ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s4),
                  _Note(icon: ClIcons.clock, text: l10n.reminderDetailNote),
                  const SizedBox(height: ClSpace.s6),
                  if (!r.done)
                    ClButton(
                      label: l10n.reminderMarkDone,
                      icon: ClIcons.check,
                      expand: true,
                      onPressed: () {
                        setReminderDone(context, ref, r, done: true);
                        context.pop();
                      },
                    )
                  else if (canUndo)
                    ClButton(
                      label: l10n.reminderUndo,
                      style: ClButtonStyle.secondary,
                      expand: true,
                      onPressed: () =>
                          setReminderDone(context, ref, r, done: false),
                    ),
                  if (parent && !r.done)
                    ClButton(
                      label: l10n.reminderEditTitle,
                      style: ClButtonStyle.plain,
                      expand: true,
                      onPressed: () => showReminderSheet(context, edit: r),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// D-029: "Nhận thông báo trên máy này?".
  Future<void> _moveHere(
    BuildContext context,
    WidgetRef ref,
    Reminder r,
    Membership me,
    DeviceIdentity device,
  ) async {
    final l10n = AppLocalizations.of(context);
    final here = NotifyDevice(
      id: device.id,
      uid: me.uid,
      label: device.label,
      owner: me.displayName,
    );
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.moveNotifTitle),
          Text(
            l10n.moveNotifBody(l10n.reminderDeviceOf(here.label, here.owner)),
            style: sheetContext.cl.text.body.copyWith(
              color: sheetContext.cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.moveNotifAction,
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
    if (ok != true || !context.mounted) return;
    final toaster = ClToaster.of(context);
    ref
        .read(reminderRepositoryProvider)
        .moveNotifications(
          r,
          here,
          onError: (_) => toaster.show(message: l10n.careSaveFailed),
        );
    toaster.show(message: l10n.reminderMoved);
    await maybeAskForNotifications(context, ref);
  }
}

// ---------- 8b sheet ----------

/// 8b Nhắc việc mới (127:13728), also "Sửa nhắc việc" with "Xoá nhắc việc" (D-030).
Future<void> showReminderSheet(BuildContext context, {Reminder? edit}) async {
  final toaster = ClToaster.of(context);
  final l10n = AppLocalizations.of(context);
  final saved = await showClSheet<bool>(
    context: context,
    builder: (_) => ReminderSheet(edit: edit),
  );
  if (saved != true || !context.mounted) return;
  if (edit == null) {
    // 8c: the reminder is saved first, then this device asks (R-092); the toast follows so
    // it never covers the prompt's buttons.
    await _maybeAsk(context, ProviderScope.containerOf(context));
  }
  toaster.show(message: l10n.reminderSaved);
}

class ReminderSheet extends ConsumerStatefulWidget {
  const ReminderSheet({this.edit, super.key});
  final Reminder? edit;

  @override
  ConsumerState<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<ReminderSheet> {
  late final _title = TextEditingController(text: widget.edit?.title);
  late int _lead = widget.edit?.leadMinutes ?? defaultReminderLeadMinutes;
  DateTime? _due;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// New: the next whole hour at least an hour from now, in the baby's zone.
  DateTime _defaultDue(String zone, DateTime now) {
    final wall = inBabyZone(zone, now.add(const Duration(hours: 1)));
    return instantInZone(
      zone,
      DateTime(wall.year, wall.month, wall.day, wall.hour + 1),
    );
  }

  Future<void> _pickDue(String zone, DateTime now) async {
    final picked = await pickReminderTime(
      context,
      zone: zone,
      initial: _due ?? widget.edit?.dueAt ?? _defaultDue(zone, now),
      now: now,
    );
    if (picked != null) {
      setState(() {
        _due = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickLead() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<int>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderLead),
          ClCardGroup(
            color: sheetContext.cl.colors.surface2,
            children: [
              for (final m in reminderLeadMinutes)
                ClOptionRow(
                  title: leadLabel(l10n, m),
                  selected: m == _lead,
                  onTap: () => Navigator.of(sheetContext).pop(m),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _lead = picked);
  }

  Future<void> _save(ReminderCtx c) async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    final due = _due ?? widget.edit?.dueAt ?? _defaultDue(c.zone, c.now);
    final dueChanged = widget.edit == null || due != widget.edit!.dueAt;
    if (title.isEmpty) {
      setState(() => _error = l10n.reminderTitleRequired);
      return;
    }
    if (dueChanged && !due.isAfter(c.now)) {
      setState(() => _error = l10n.reminderPastTime);
      return;
    }
    final repo = ref.read(reminderRepositoryProvider);
    final toaster = ClToaster.of(context);
    void failed(Object _) => toaster.show(message: l10n.careSaveFailed);
    final before = widget.edit;
    if (before != null) {
      repo.edit(
        before,
        before.copyWith(title: title, dueAt: due, leadMinutes: _lead),
        c.me.uid,
        onError: failed,
      );
    } else {
      final device = await ref.read(deviceIdentityProvider.future);
      repo.create(
        Reminder(
          id: newReminderId(),
          babyId: c.me.babyId,
          title: title,
          dueAt: due,
          leadMinutes: _lead,
          notifyDevice: NotifyDevice(
            id: device.id,
            uid: c.me.uid,
            label: device.label,
            owner: c.me.displayName,
          ),
          createdBy: c.me.uid,
          author: CareAuthor.of(c.me),
        ),
        onError: failed,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete(Reminder r) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderDeleteTitle),
          Text(
            l10n.reminderDeleteBody,
            style: sheetContext.cl.text.body.copyWith(
              color: sheetContext.cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.reminderDelete,
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
    if (ok != true || !mounted) return;
    final toaster = ClToaster.of(context);
    ref
        .read(reminderRepositoryProvider)
        .delete(r, onError: (_) => toaster.show(message: l10n.careSaveFailed));
    toaster.show(message: l10n.reminderDeleted);
    final router = GoRouter.of(context);
    Navigator.of(context).pop(false);
    // Leave the detail of a reminder that no longer exists.
    if (router.state.uri.path.startsWith('${Routes.reminders}/')) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null) return const SizedBox.shrink();
    final due = _due ?? widget.edit?.dueAt ?? _defaultDue(c.zone, c.now);
    final edit = widget.edit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: edit == null ? l10n.reminderNew : l10n.reminderEditTitle,
          onClose: () => Navigator.of(context).pop(false),
        ),
        ClTextField(
          label: l10n.reminderWhat,
          placeholder: l10n.reminderWhatHint,
          controller: _title,
          maxLength: reminderTitleMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          color: cl.colors.surface2,
          children: [
            ClDetailRow(
              icon: ClIcons.today,
              label: l10n.reminderWhen,
              value: reminderWhenShort(c.locale, inBabyZone(c.zone, due)),
              onTap: () => _pickDue(c.zone, c.now),
            ),
            ClDetailRow(
              icon: ClIcons.clock,
              label: l10n.reminderLead,
              value: leadLabel(l10n, _lead),
              onTap: _pickLead,
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.reminderFootnote(c.nickname, gmtOffsetLabel(c.zone, due)),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: ClSpace.s2),
          Text(_error!, style: cl.text.label.copyWith(color: cl.colors.error)),
        ],
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.reminderSave,
          expand: true,
          onPressed: () => _save(c),
        ),
        if (edit != null)
          ClButton(
            label: l10n.reminderDelete,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => _delete(edit),
          ),
      ],
    );
  }
}

/// Date and time wheel in the baby's zone, never in the past (D-031), 5-minute steps.
Future<DateTime?> pickReminderTime(
  BuildContext context, {
  required String zone,
  required DateTime initial,
  required DateTime now,
}) {
  DateTime step(DateTime w) =>
      DateTime(w.year, w.month, w.day, w.hour, w.minute - w.minute % 5);
  final nowWall = inBabyZone(zone, now);
  final minWall = step(nowWall.add(const Duration(minutes: 5)));
  var picked = step(inBabyZone(zone, initial));
  if (picked.isBefore(minWall)) picked = minWall;
  return showClSheet<DateTime>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final cl = sheetContext.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderWhen),
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
                minimumDate: minWall,
                maximumDate: nowWall.add(
                  const Duration(days: reminderMaxDaysAhead - 1),
                ),
                minuteInterval: 5,
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
                Navigator.of(sheetContext).pop(instantInZone(zone, picked)),
          ),
        ],
      );
    },
  );
}

// ---------- 8c pre-prompt ----------

const _kAsked = 'reminders.notificationsAsked';

/// Whether 8c has been shown on this device; 8d's card only appears after it (R-092).
final notificationsAskedProvider = NotifierProvider<NotificationsAsked, bool>(
  NotificationsAsked.new,
);

class NotificationsAsked extends Notifier<bool> {
  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_kAsked) ?? false;

  Future<void> mark() async {
    await ref.read(sharedPreferencesProvider).setBool(_kAsked, true);
    state = true;
  }
}

/// 8c after the first save on this device, or after moving a notification here (D-029):
/// "Bật thông báo trên máy này?" → the OS prompt. Asked once; afterwards 8d's card links to
/// Settings.
Future<void> maybeAskForNotifications(BuildContext context, WidgetRef ref) =>
    _maybeAsk(context, ProviderScope.containerOf(context));

Future<void> _maybeAsk(
  BuildContext context,
  ProviderContainer container,
) async {
  final enabled = container.read(notificationsEnabledProvider.notifier);
  await enabled.refresh();
  if (container.read(notificationsEnabledProvider) == true) return;
  if (container.read(notificationsAskedProvider) || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final allow = await showClSheet<bool>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.notifPromptTitle),
        Text(
          l10n.notifPromptBody,
          style: sheetContext.cl.text.body.copyWith(
            color: sheetContext.cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.notifPromptAllow,
          icon: ClIcons.bell,
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        ClButton(
          label: l10n.actionLater,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
    ),
  );
  await container.read(notificationsAskedProvider.notifier).mark();
  if (allow == true) await enabled.request();
}

// ---------- ReminderPeek (128:665) ----------

/// On Hôm nay: the next upcoming reminder and how many are open; tap opens 8a. Hidden for
/// relatives (D-018).
class ReminderPeek extends ConsumerWidget {
  const ReminderPeek({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null || c.me.role == MemberRole.relative) {
      return const SizedBox.shrink();
    }
    final all = ref.watch(remindersProvider(c.me.babyId)).value;
    if (all == null) return const SizedBox.shrink();
    final groups = groupReminders(all, c.now);
    final open = groups.overdue.length + groups.upcoming.length;
    final next = groups.upcoming.firstOrNull ?? groups.overdue.firstOrNull;
    final parent = c.me.role == MemberRole.coParent;

    String? meta;
    var overdue = false;
    if (next != null) {
      final wall = inBabyZone(c.zone, next.dueAt);
      final today = babyToday(c.zone, c.now);
      final day = DateTime(wall.year, wall.month, wall.day);
      final hm = DateFormat('HH:mm').format(wall);
      final days = day.difference(today).inDays;
      if (next.statusAt(c.now) == ReminderStatus.overdue) {
        overdue = true;
        meta = l10n.reminderOverdueMeta(
          reminderWhenRelative(l10n, c.locale, wall, today),
        );
      } else {
        final when = switch (days) {
          0 => _cap('${l10n.dayToday} $hm'),
          1 => _cap('${l10n.dayTomorrow} $hm'),
          _ => '${_cap(DateFormat('EEEE', c.locale).format(wall))} $hm',
        };
        final left = days == 0
            ? l10n.reminderInDuration(
                durationLabel(l10n, next.dueAt.difference(c.now).inMinutes),
              )
            : l10n.reminderInDays(days);
        meta = '$when · $left';
      }
    }

    return ClPressable(
      onPressed: () => next == null && parent
          ? showReminderSheet(context)
          : context.push(Routes.reminders),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s3,
          ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ClIcon(
                  ClIcons.bell,
                  size: 20,
                  color: cl.colors.mintDeep,
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    open == 0
                        ? l10n.remindersTitle
                        : l10n.reminderPeekLabel(open),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                  Text(
                    next?.title ?? l10n.reminderPeekEmpty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.bodyStrong,
                  ),
                  if (meta != null)
                    Text(
                      meta,
                      style: cl.text.caption.copyWith(
                        color: overdue ? cl.colors.error : cl.colors.inkMuted,
                      ),
                    )
                  else if (parent)
                    Text(
                      l10n.reminderPeekAdd,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.mintText,
                      ),
                    ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 20, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
