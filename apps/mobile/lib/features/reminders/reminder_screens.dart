import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/navigation.dart' show OverlayTwin;
import '../../app/route_guard.dart';
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
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/today_adaptive.dart' show AxCard;
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../baby/time_zones.dart' show gmtOffsetLabel;
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import 'device_identity.dart';
import 'reminder_models.dart';
import 'reminder_notifications.dart';
import 'reminder_repository.dart';
import 'reminder_titles.dart';
import 'rule_repository.dart' show reminderRulesProvider;
import 'rule_screens.dart'
    show RuleRemindersList, ruleIcon, ruleTint, ruleTitle, showRuleDueSheet;

// ---------- Labels ----------

/// "Mẹ" / "Cô Lan" / "Bạn" (D-024).
String reminderWho(AppLocalizations l10n, CareAuthor author, bool isMe) =>
    authorLabel(
      l10n,
      author,
      isMe: isMe,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );

/// "1 giờ" / "Đúng giờ" / "1 ngày" (D-031); "Đúng ngày" for an all-day reminder (D-075 #5).
String leadLabel(AppLocalizations l10n, int minutes, {bool allDay = false}) =>
    switch (minutes) {
      0 => allDay ? l10n.leadOnDay : l10n.leadOnTime,
      1440 => l10n.leadOneDay,
      _ => durationLabel(l10n, minutes),
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "T7, 10 thg 10" (8b, 8e).
String reminderDayShort(String locale, DateTime wall) {
  final day = locale.startsWith('vi')
      ? (wall.weekday == DateTime.sunday ? 'CN' : 'T${wall.weekday + 1}')
      : DateFormat.E(locale).format(wall);
  return '$day, ${DateFormat('d MMM', locale).format(wall)}';
}

/// "T7, 10 thg 10 · 08:30" (8b, 8e).
String reminderWhenShort(String locale, DateTime wall) =>
    '${reminderDayShort(locale, wall)} · ${DateFormat('HH:mm').format(wall)}';

/// "Thứ Bảy, 10 thg 10 · 08:30" (8a upcoming rows).
String reminderWhenLong(String locale, DateTime wall) =>
    '${_cap(DateFormat('EEEE, d MMM', locale).format(wall))} · '
    '${DateFormat('HH:mm').format(wall)}';

// ---- D-075 #5: all day and assignee labels ----

/// "08:00" from minutes after midnight.
String reminderClock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// The date row of [r]: "T7, 10 thg 10 · Cả ngày" or "T7, 10 thg 10 · 08:30".
String reminderWhenOf(AppLocalizations l10n, ReminderCtx c, Reminder r) {
  final day = r.dueDay;
  return day != null
      ? '${reminderDayShort(c.locale, day)} · ${l10n.reminderAllDay}'
      : reminderWhenShort(c.locale, inBabyZone(c.zone, r.dueAt));
}

/// The member assigned to [r], if still one who may receive reminders.
Membership? reminderAssignee(WidgetRef ref, Reminder r, DateTime now) {
  final uid = r.assigneeUid;
  if (uid == null) return null;
  final members = ref.watch(familyMembersProvider(r.babyId)).value;
  return members
      ?.where((m) => m.uid == uid && canBeAssignedReminders(m, now))
      .firstOrNull;
}

/// "Mẹ" / "Cô Lan" / "Bạn" for an assignee.
String assigneeName(AppLocalizations l10n, Membership m, String meUid) =>
    reminderWho(l10n, CareAuthor.of(m), m.uid == meUid);

/// "Giao cho bạn" (highlighted, mint) for the assignee; "Giao cho Cô Lan" (muted) for others.
class ReminderAssigneeTag extends StatelessWidget {
  const ReminderAssigneeTag({
    required this.assignee,
    required this.meUid,
    super.key,
  });

  final Membership assignee;
  final String meUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (assignee.uid != meUid) {
      return Text(
        l10n.reminderAssignedTo(assigneeName(l10n, assignee, meUid)),
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.family, size: 14, color: cl.colors.mintText),
          const SizedBox(width: ClSpace.s1),
          Text(
            l10n.reminderAssignedToYou,
            style: cl.text.caption.copyWith(
              color: cl.colors.mintText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
// ---- end D-075 #5 ----

/// "hôm qua" / "hôm nay" / "5 thg 10" (all-day overdue rows, D-075 #5).
String reminderDayRelative(
  AppLocalizations l10n,
  String locale,
  DateTime day,
  DateTime today,
) => switch (DateTime(day.year, day.month, day.day).difference(today).inDays) {
  0 => l10n.dayToday,
  -1 => l10n.dayYesterday,
  1 => l10n.dayTomorrow,
  _ => DateFormat('d MMM', locale).format(day),
};

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

/// Which half of Nhắc nhở shows: "Một lần" first, then "Theo quy tắc" (owner, 2026-10-11;
/// v1.0 1a had the rules first).
enum ReminderTab { once, rules }

final reminderTabProvider = NotifierProvider<ReminderTabState, ReminderTab>(
  ReminderTabState.new,
);

class ReminderTabState extends Notifier<ReminderTab> {
  @override
  ReminderTab build() => ReminderTab.once;

  void set(ReminderTab tab) => state = tab;
}

/// Nhắc nhở (v1.0 370:2365): "Theo quy tắc" (rule reminders, 1a) and "Một lần" — 8a Nhắc
/// việc (127:13602) for Cùng nuôi; 12f (192:1327) for caregivers: view and mark done.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(reminderTabProvider);
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final all = ref.watch(remindersProvider(c.me.babyId)).value;
    final groups = groupReminders(all ?? const [], c.now, c.zone);
    final parent = c.me.role == MemberRole.coParent;
    final device = ref.watch(deviceIdentityProvider).value;
    final enabled = ref.watch(notificationsEnabledProvider);
    final allDayMinutes = ref.watch(reminderAllDayTimeProvider);
    // 8d: asked already (8c), and this device holds a notification that cannot show (put here,
    // or assigned to me, D-075 #5).
    final blocked =
        enabled == false &&
        ref.watch(notificationsAskedProvider) &&
        device != null &&
        (all ?? const []).any(
          (r) =>
              !r.done &&
              r.ringsOn(deviceId: device.id, uid: c.me.uid) &&
              r.fireAt(c.zone, allDayMinutes: allDayMinutes).isAfter(c.now),
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
                  const SizedBox(height: ClSpace.s3),
                  ClSegmented<ReminderTab>(
                    options: ReminderTab.values,
                    selected: tab,
                    labelOf: (t) => switch (t) {
                      ReminderTab.rules => l10n.ruleTabRules,
                      ReminderTab.once => l10n.ruleTabOnce,
                    },
                    onChanged: ref.read(reminderTabProvider.notifier).set,
                  ),
                  const SizedBox(height: ClSpace.s4),
                  if (tab == ReminderTab.rules)
                    const RuleRemindersList()
                  else ...[
                    if (blocked) ...[
                      const SizedBox(height: ClSpace.s4),
                      NotificationsOffCard(message: l10n.remindersNotifOff),
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
                    // D-119: said once, on the sheet that creates the reminder (reminderFootnote).
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

/// 8d (127:13867): "Đã lưu nhắc việc. Chưa bật thông báo trên máy này." + "Cài đặt"; the
/// same card on "Theo quy tắc" with its own line (NT-5).
class NotificationsOffCard extends ConsumerWidget {
  const NotificationsOffCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final asked = ref.watch(notificationsAskedProvider);
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
          Expanded(child: Text(message, style: cl.text.label)),
          // Never asked on this install: the system prompt can still show; afterwards only
          // Settings can (NT-3).
          ClButton(
            label: asked ? l10n.remindersOpenSettings : l10n.ntTurnOn,
            style: ClButtonStyle.plain,
            onPressed: () => unawaited(
              ref.read(notificationsEnabledProvider.notifier).turnOn(),
            ),
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
    final status = r.statusAt(ctx.now, ctx.zone);
    final today = babyToday(ctx.zone, ctx.now);
    final wall = inBabyZone(ctx.zone, r.dueAt);
    final who = reminderWho(l10n, r.author, r.createdBy == ctx.me.uid);
    // D-075 #5: "Thứ Bảy, 10 thg 10 · Cả ngày" / "Quá hạn · hôm qua · cả ngày".
    final day = r.dueDay;
    final upcomingWhen = day != null
        ? '${_cap(DateFormat('EEEE, d MMM', ctx.locale).format(day))} · '
              '${l10n.reminderAllDay}'
        : reminderWhenLong(ctx.locale, wall);
    final overdueWhen = day != null
        ? '${reminderDayRelative(l10n, ctx.locale, day, today)} · '
              '${l10n.reminderAllDayLower}'
        : reminderWhenRelative(l10n, ctx.locale, wall, today);
    final assignee = reminderAssignee(ref, r, ctx.now);
    final meta = switch (status) {
      ReminderStatus.upcoming =>
        '$upcomingWhen · ${l10n.reminderCreatedBy(who)}',
      ReminderStatus.overdue =>
        '${l10n.reminderOverdueMeta(overdueWhen)}'
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
                    reminderTitle(l10n, r.title),
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
                  if (assignee != null && !done) ...[
                    const SizedBox(height: ClSpace.s1),
                    ReminderAssigneeTag(assignee: assignee, meUid: ctx.me.uid),
                  ],
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
  void failed(Object _) =>
      toaster.show(message: l10n.careSaveFailed, error: true);
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
    final status = r.statusAt(c.now, c.zone);
    final mine = device != null && r.notifyDevice?.id == device.id;
    final assignee = reminderAssignee(ref, r, c.now);
    final allDayMinutes = ref.watch(reminderAllDayTimeProvider);
    // "iPhone của Mai"; on that device the row has no chevron (nothing to move). D-075 #5: the
    // assignee's own devices ring too ("Các máy của Cô Lan").
    final notify = [
      if (r.notifyDevice case final d?) l10n.reminderDeviceOf(d.label, d.owner),
      if (assignee != null && assignee.uid != r.notifyDevice?.uid)
        assignee.uid == c.me.uid
            ? l10n.reminderNotifyMine
            : l10n.reminderNotifyAssignee(
                assigneeName(l10n, assignee, c.me.uid),
              ),
    ].join(' · ');
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
                    child: Text(
                      reminderTitle(l10n, r.title),
                      style: cl.text.largeTitle,
                    ),
                  ),
                  if (status == ReminderStatus.overdue)
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s1),
                      child: Text(
                        l10n.remindersOverdue,
                        style: cl.text.label.copyWith(color: cl.colors.error),
                      ),
                    ),
                  if (assignee != null && assignee.uid == c.me.uid && !r.done)
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s2),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ReminderAssigneeTag(
                          assignee: assignee,
                          meUid: c.me.uid,
                        ),
                      ),
                    ),
                  const SizedBox(height: ClSpace.s4),
                  ClCardGroup(
                    children: [
                      ClDetailRow(
                        icon: ClIcons.today,
                        label: r.allDay ? l10n.reminderDay : l10n.reminderWhen,
                        value: reminderWhenOf(l10n, c, r),
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
                        value: leadLabel(l10n, r.leadMinutes, allDay: r.allDay),
                        onTap: parent && !r.done
                            ? () => showReminderSheet(context, edit: r)
                            : null,
                      ),
                      // D-075 #5: the person's own all-day time, always shown.
                      if (r.allDay)
                        ClDetailRow(
                          icon: ClIcons.sunrise,
                          label: l10n.reminderAllDayAt,
                          value: reminderClock(allDayMinutes),
                          onTap: r.done
                              ? null
                              : () => pickReminderAllDayTime(context, ref),
                        ),
                      ClDetailRow(
                        icon: ClIcons.family,
                        label: l10n.reminderAssignee,
                        value: assignee == null
                            ? l10n.reminderAssignNone
                            : assigneeName(l10n, assignee, c.me.uid),
                        valueIsAccent:
                            assignee != null && assignee.uid == c.me.uid,
                        onTap: parent && !r.done
                            ? () => showReminderSheet(context, edit: r)
                            : null,
                      ),
                      ClDetailRow(
                        icon: ClIcons.bell,
                        label: l10n.reminderNotify,
                        value: notify.isEmpty ? l10n.reminderNoDevice : notify,
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
                  // D-119: the "Thông báo" row already names the device; only the assignee's
                  // case needs a note.
                  if (assignee != null) ...[
                    const SizedBox(height: ClSpace.s4),
                    _Note(
                      icon: ClIcons.clock,
                      text: l10n.reminderDetailNoteAssigned,
                    ),
                  ],
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
          onError: (_) =>
              toaster.show(message: l10n.careSaveFailed, error: true),
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
    // it never covers the prompt's buttons. Refused: it says so, with "Cài đặt" (NT-3).
    if (await _maybeAsk(context, ProviderScope.containerOf(context))) {
      showNotificationsRefused(toaster, l10n, message: l10n.remindersNotifOff);
      return;
    }
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

  // ---- D-075 #5: all day and assignee ----
  late bool _allDay = widget.edit?.allDay ?? false;

  /// The all-day date (a calendar day in the baby's zone).
  late DateTime? _day = widget.edit?.dueDay;
  late String? _assignee = widget.edit?.assigneeUid;
  // ---- end D-075 #5 ----

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // An app-written title is edited in the reader's language (reminder_titles.dart).
    if (widget.edit case final r? when _title.text == r.title) {
      _title.text = reminderTitle(AppLocalizations.of(context), r.title);
    }
  }

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

  DateTime _timedDue(ReminderCtx c) {
    final edit = widget.edit;
    return _due ??
        (edit != null && !edit.allDay ? edit.dueAt : null) ??
        _defaultDue(c.zone, c.now);
  }

  DateTime _allDayDay(ReminderCtx c) {
    if (_day case final d?) return d;
    final wall = inBabyZone(c.zone, _timedDue(c));
    return DateTime(wall.year, wall.month, wall.day);
  }

  Future<void> _pickDue(ReminderCtx c) async {
    if (_allDay) {
      final picked = await pickReminderDay(
        context,
        initial: _allDayDay(c),
        today: babyToday(c.zone, c.now),
      );
      if (picked != null) {
        setState(() {
          _day = picked;
          _error = null;
        });
      }
      return;
    }
    final picked = await pickReminderTime(
      context,
      zone: c.zone,
      initial: _timedDue(c),
      now: c.now,
    );
    if (picked != null) {
      setState(() {
        _due = picked;
        _error = null;
      });
    }
  }

  void _setAllDay(ReminderCtx c, bool on) {
    setState(() {
      if (on) {
        _day = _allDayDay(c);
        if (!reminderAllDayLeadMinutes.contains(_lead)) {
          _lead = defaultReminderAllDayLeadMinutes;
        }
      } else if (_day case final d?) {
        // Back to a time: the same day at the time it had (or the default time).
        final t = inBabyZone(c.zone, _timedDue(c));
        _due = instantInZone(
          c.zone,
          DateTime(d.year, d.month, d.day, t.hour, t.minute),
        );
      }
      _allDay = on;
      _error = null;
    });
  }

  Future<void> _pickLead() async {
    final l10n = AppLocalizations.of(context);
    final options = _allDay ? reminderAllDayLeadMinutes : reminderLeadMinutes;
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
              for (final m in options)
                ClOptionRow(
                  title: leadLabel(l10n, m, allDay: _allDay),
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

  /// D-075 #5: "Giao cho" — an active Cùng nuôi or Người chăm sóc, or nobody.
  Future<void> _pickAssignee(ReminderCtx c, List<Membership> eligible) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<String>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderAssignee),
          ClCardGroup(
            color: sheetContext.cl.colors.surface2,
            children: [
              ClOptionRow(
                title: l10n.reminderAssignNobody,
                selected: _assignee == null,
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
              for (final m in eligible)
                ClOptionRow(
                  title: assigneeName(l10n, m, c.me.uid),
                  subtitle: m.uid == c.me.uid ? m.displayName : null,
                  selected: _assignee == m.uid,
                  onTap: () => Navigator.of(sheetContext).pop(m.uid),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.reminderAssignPickerNote,
            style: sheetContext.cl.text.caption.copyWith(
              color: sheetContext.cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _assignee = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _save(ReminderCtx c) async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    final before = widget.edit;
    final day = _allDay ? _allDayDay(c) : null;
    final due = day != null ? allDayDueAt(c.zone, day) : _timedDue(c);
    final dueChanged =
        before == null ||
        due != before.dueAt ||
        _allDay != before.allDay ||
        (day != null && isoDay(day) != before.dueDate);
    if (title.isEmpty) {
      setState(() => _error = l10n.reminderTitleRequired);
      return;
    }
    if (dueChanged) {
      if (day != null && day.isBefore(babyToday(c.zone, c.now))) {
        setState(() => _error = l10n.reminderPastDay);
        return;
      }
      if (day == null && !due.isAfter(c.now)) {
        setState(() => _error = l10n.reminderPastTime);
        return;
      }
    }
    final repo = ref.read(reminderRepositoryProvider);
    final toaster = ClToaster.of(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    if (before != null) {
      repo.edit(
        before,
        before.copyWith(
          title: title,
          dueAt: due,
          leadMinutes: _lead,
          allDay: _allDay,
          dueDate: day == null ? null : isoDay(day),
          assigneeUid: _assignee,
        ),
        c.me.uid,
        onError: failed,
      );
    } else {
      final device = await ref.read(deviceIdentityProvider.future);
      // D-075 #5: a job for someone else rings on their devices, not on this one (8e "Thông
      // báo → máy này" still takes a copy, D-029).
      final forSomeoneElse = _assignee != null && _assignee != c.me.uid;
      repo.create(
        Reminder(
          id: newReminderId(),
          babyId: c.me.babyId,
          title: title,
          dueAt: due,
          leadMinutes: _lead,
          notifyDevice: forSomeoneElse
              ? null
              : NotifyDevice(
                  id: device.id,
                  uid: c.me.uid,
                  label: device.label,
                  owner: c.me.displayName,
                ),
          createdBy: c.me.uid,
          author: CareAuthor.of(c.me),
          allDay: _allDay,
          dueDate: day == null ? null : isoDay(day),
          assigneeUid: _assignee,
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
        .delete(
          r,
          onError: (_) =>
              toaster.show(message: l10n.careSaveFailed, error: true),
        );
    toaster.show(message: l10n.reminderDeleted);
    final router = GoRouter.of(context);
    Navigator.of(context).pop(false);
    // Leave the detail of a reminder that no longer exists (D-076 nav: or its overlay twin).
    if (OverlayTwin.original(
      router.state.uri.path,
    ).startsWith('${Routes.reminders}/')) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _context(context, ref);
    if (c == null) return const SizedBox.shrink();
    final edit = widget.edit;
    final day = _allDay ? _allDayDay(c) : null;
    final due = day != null ? allDayDueAt(c.zone, day) : _timedDue(c);
    final allDayMinutes = ref.watch(reminderAllDayTimeProvider);
    // D-075 #5: who may be assigned (the current assignee stays listed while still eligible).
    final eligible =
        [
          for (final m
              in ref.watch(familyMembersProvider(c.me.babyId)).value ??
                  const <Membership>[])
            if (canBeAssignedReminders(m, c.now)) m,
        ]..sort(
          (a, b) => (a.uid == c.me.uid ? 0 : 1) - (b.uid == c.me.uid ? 0 : 1),
        );
    final assignee = eligible.where((m) => m.uid == _assignee).firstOrNull;
    final forSomeoneElse = assignee != null && assignee.uid != c.me.uid;
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
            _ToggleDetailRow(
              icon: ClIcons.sunrise,
              label: l10n.reminderAllDay,
              value: _allDay,
              onChanged: (on) => _setAllDay(c, on),
            ),
            ClDetailRow(
              icon: ClIcons.today,
              label: _allDay ? l10n.reminderDay : l10n.reminderWhen,
              value: day != null
                  ? reminderDayShort(c.locale, day)
                  : reminderWhenShort(c.locale, inBabyZone(c.zone, due)),
              onTap: () => _pickDue(c),
            ),
            if (_allDay)
              ClDetailRow(
                icon: ClIcons.bell,
                label: l10n.reminderAllDayAt,
                value: reminderClock(allDayMinutes),
                onTap: () => pickReminderAllDayTime(context, ref),
              ),
            ClDetailRow(
              icon: ClIcons.clock,
              label: l10n.reminderLead,
              value: leadLabel(l10n, _lead, allDay: _allDay),
              onTap: _pickLead,
            ),
            ClDetailRow(
              icon: ClIcons.family,
              label: l10n.reminderAssignee,
              value: assignee == null
                  ? l10n.reminderAssignNone
                  : assigneeName(l10n, assignee, c.me.uid),
              onTap: () => _pickAssignee(c, eligible),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          forSomeoneElse
              ? l10n.reminderFootnoteAssigned(
                  c.nickname,
                  gmtOffsetLabel(c.zone, due),
                  assigneeName(l10n, assignee, c.me.uid),
                )
              : l10n.reminderFootnote(c.nickname, gmtOffsetLabel(c.zone, due)),
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

/// A [ClDetailRow]-like row with a switch ("Cả ngày", D-075 #5).
class _ToggleDetailRow extends StatelessWidget {
  const _ToggleDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final ClIcons icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s2,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 18, color: cl.colors.mintText),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(child: Text(label, style: cl.text.body)),
            const SizedBox(width: ClSpace.s3),
            // The row's text labels the switch (one merged node).
            ClToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderWhen),
          _Wheel(
            initial: picked,
            minimum: minWall,
            maximum: nowWall.add(
              const Duration(days: reminderMaxDaysAhead - 1),
            ),
            mode: CupertinoDatePickerMode.dateAndTime,
            onChanged: (d) => picked = d,
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

// ---- D-075 #5: all-day date and the person's all-day time ----

/// Date wheel for an all-day reminder: today (baby's zone) or later, within a year.
Future<DateTime?> pickReminderDay(
  BuildContext context, {
  required DateTime initial,
  required DateTime today,
}) {
  var picked = initial.isBefore(today) ? today : initial;
  return showClSheet<DateTime>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderDay),
          _Wheel(
            initial: picked,
            minimum: today,
            maximum: today.add(const Duration(days: reminderMaxDaysAhead - 1)),
            mode: CupertinoDatePickerMode.date,
            onChanged: (d) => picked = DateTime(d.year, d.month, d.day),
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

/// "Giờ nhắc việc cả ngày": this person's time for every all-day reminder ringing on this
/// device, in the baby's zone (default 08:00; never a silent hard-coded time).
Future<void> pickReminderAllDayTime(BuildContext context, WidgetRef ref) async {
  final current = ref.read(reminderAllDayTimeProvider);
  final me = ref.read(selectedMembershipProvider);
  final nickname = me == null
      ? ''
      : ref.read(babyProvider(me.babyId)).value?.nickname ?? '';
  var picked = DateTime(2000, 1, 1, current ~/ 60, current % 60);
  final ok = await showClSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final cl = sheetContext.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.reminderAllDayTimeTitle),
          _Wheel(
            initial: picked,
            mode: CupertinoDatePickerMode.time,
            onChanged: (d) => picked = d,
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.reminderAllDayTimeNote(nickname),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      );
    },
  );
  if (ok == true) {
    await ref
        .read(reminderAllDayTimeProvider.notifier)
        .set(picked.hour * 60 + picked.minute);
  }
}

/// The Cupertino wheel in the app's palette (Light / Night care), 24 h, 5-minute steps.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.initial,
    required this.mode,
    required this.onChanged,
    this.minimum,
    this.maximum,
  });

  final DateTime initial;
  final DateTime? minimum;
  final DateTime? maximum;
  final CupertinoDatePickerMode mode;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return SizedBox(
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
          mode: mode,
          initialDateTime: initial,
          minimumDate: minimum,
          maximumDate: maximum,
          minuteInterval: 5,
          use24hFormat: true,
          onDateTimeChanged: onChanged,
        ),
      ),
    );
  }
}
// ---- end D-075 #5 ----

// ---------- 8c pre-prompt ----------

/// 8c after the first save on this device, or after moving a notification here (D-029):
/// "Bật thông báo trên máy này?" → the OS prompt. Not when this install already asked, here,
/// at launch or on EN03 (NT-3); afterwards 8d's card links to Settings. A refusal at the
/// system prompt says so with "Cài đặt"; true when it was refused.
Future<bool> maybeAskForNotifications(
  BuildContext context,
  WidgetRef ref,
) async {
  final refused = await _maybeAsk(context, ProviderScope.containerOf(context));
  if (refused && context.mounted) {
    showNotificationsRefused(
      ClToaster.of(context),
      AppLocalizations.of(context),
    );
  }
  return refused;
}

/// The toast after a refusal at the system prompt: only system settings can turn them on now.
void showNotificationsRefused(
  ClToaster toaster,
  AppLocalizations l10n, {
  String? message,
}) => toaster.show(
  message: message ?? l10n.hnNotifDenied,
  actionLabel: l10n.remindersOpenSettings,
  onAction: () => unawaited(openNotificationSettings()),
);

/// 8c itself; true when the person said "Bật" and the system prompt then refused.
Future<bool> _maybeAsk(
  BuildContext context,
  ProviderContainer container,
) async {
  final enabled = container.read(notificationsEnabledProvider.notifier);
  await enabled.refresh();
  if (container.read(notificationsEnabledProvider) == true) return false;
  if (container.read(notificationsAskedProvider) || !context.mounted) {
    return false;
  }
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
  return allow == true && !await enabled.request();
}

// ---------- ReminderPeek (128:665) ----------

/// On Hôm nay: "Nhắc việc · N" with "Xem tất cả", then the next reminders (up to [shown]) as
/// rows, dated ones and rules' next times together, overdue first; a row opens its reminder
/// (a rule that rang opens its "Ghi …" sheet). Owner, 2026-10-11. Hidden for relatives (D-018).
class ReminderPeek extends ConsumerWidget {
  const ReminderPeek({this.ax = false, super.key});

  /// Adaptive Hôm nay (AX10–AX13): one card, header inside ("Nhắc nhở · N sắp tới · Tất cả"),
  /// the next two as title + time rows; empty: "Tạo nhắc nhở đầu tiên" (AX40).
  final bool ax;

  /// Rows on Hôm nay; the rest are behind "Xem tất cả".
  static const shown = 3;

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
    final rules =
        ref.watch(reminderRulesProvider(c.me.babyId)).value ?? const [];
    final groups = groupReminders(all, c.now, c.zone);
    final babyId = c.me.babyId;
    final items =
        <
            ({
              String title,
              DateTime at,
              bool overdue,
              ClIcons icon,
              Color tint,
              VoidCallback open,
              DateTime? day,
            })
          >[
            for (final r in [...groups.overdue, ...groups.upcoming])
              (
                title: reminderTitle(l10n, r.title),
                at: r.dueAt,
                overdue: r.statusAt(c.now, c.zone) == ReminderStatus.overdue,
                icon: ClIcons.bell,
                tint: cl.colors.mintSoft,
                open: () => context.push('${Routes.reminders}/${r.id}'),
                // D-075 #5: an all-day reminder shows its day, no time.
                day: r.dueDay,
              ),
            for (final r in rules)
              if (!r.enabled)
                ...[]
              // Rang and not yet answered (1g): first, like an overdue reminder, and opens the
              // same sheet as the notification.
              else if (r.pendingDueAt case final due?)
                (
                  title: ruleTitle(l10n, r.type),
                  at: due,
                  overdue: true,
                  icon: ruleIcon(r.type),
                  tint: ruleTint(cl, r.type),
                  open: () => unawaited(
                    showRuleDueSheet(context, babyId: babyId, ruleId: r.id),
                  ),
                  day: null,
                )
              else if (r.nextDueAt case final next?)
                (
                  title: ruleTitle(l10n, r.type),
                  at: next,
                  overdue: false,
                  icon: ruleIcon(r.type),
                  tint: ruleTint(cl, r.type),
                  open: () => context.push('${Routes.ruleDetail}/${r.id}'),
                  day: null,
                ),
          ]
          ..sort((a, b) {
            if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
            return a.at.compareTo(b.at);
          });
    final parent = c.me.role == MemberRole.coParent;
    final today = babyToday(c.zone, c.now);

    String when(DateTime at, bool overdue, DateTime? allDay) {
      // D-075 #5: "Hôm nay · Cả ngày" / "Thứ Bảy · Cả ngày · còn 2 ngày" / "Quá hạn · hôm qua".
      if (allDay != null) {
        final days = allDay.difference(today).inDays;
        if (overdue) {
          return l10n.reminderOverdueMeta(
            reminderDayRelative(l10n, c.locale, allDay, today),
          );
        }
        final label = switch (days) {
          0 => _cap(l10n.dayToday),
          1 => _cap(l10n.dayTomorrow),
          _ => _cap(DateFormat('EEEE', c.locale).format(allDay)),
        };
        return [
          label,
          l10n.reminderAllDayLower,
          if (days > 0) l10n.reminderInDays(days),
        ].join(' · ');
      }
      final wall = inBabyZone(c.zone, at);
      if (overdue) {
        return l10n.reminderOverdueMeta(
          reminderWhenRelative(l10n, c.locale, wall, today),
        );
      }
      final day = DateTime(wall.year, wall.month, wall.day);
      final hm = DateFormat('HH:mm').format(wall);
      final days = day.difference(today).inDays;
      final label = switch (days) {
        0 => _cap('${l10n.dayToday} $hm'),
        1 => _cap('${l10n.dayTomorrow} $hm'),
        _ => '${_cap(DateFormat('EEEE', c.locale).format(wall))} $hm',
      };
      final left = days == 0
          ? l10n.reminderInDuration(
              durationLabel(l10n, at.difference(c.now).inMinutes),
            )
          : l10n.reminderInDays(days);
      return '$label · $left';
    }

    // D-108: an ordinary overdue reminder is warm attention (alert + "Quá hạn …" in `pending`
    // on `sunshineSoft`, ink icon), never `error` red; the words carry it, not the colour alone.
    Widget mark(ClIcons icon, Color tint, {bool overdue = false}) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: overdue ? cl.colors.sunshineSoft : tint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClIcon(
        overdue ? ClIcons.alert : icon,
        size: 20,
        color: cl.colors.ink,
      ),
    );

    if (ax) {
      // D-108: the "Nhắc việc" card, title then status · time on two lines, never cut, up to
      // [shown] rows; a row opens its reminder.
      return AxCard(
        key: const Key('axReminders'),
        top: 0,
        icon: ClIcons.clock,
        chip: cl.colors.sunshineSoft,
        title: l10n.reminderPeekTitle,
        subtitle: items.isEmpty ? null : l10n.axRemindersCount(items.length),
        link: items.isEmpty ? null : l10n.reminderPeekMore,
        onLink: () => context.push(Routes.reminders),
        child: items.isEmpty
            ? ClButton(
                label: parent ? l10n.axRemindersFirst : l10n.reminderPeekMore,
                style: ClButtonStyle.tinted,
                expand: true,
                onPressed: () => parent
                    ? showReminderSheet(context)
                    : context.push(Routes.reminders),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (n, i) in items.take(shown).indexed) ...[
                    if (n > 0) const SizedBox(height: ClSpace.s2),
                    ClPressable(
                      onPressed: i.open,
                      semanticLabel:
                          '${i.title}, ${when(i.at, i.overdue, i.day)}',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: i.overdue
                                    ? cl.colors.sunshineSoft
                                    : cl.colors.mintSoft,
                                borderRadius: BorderRadius.circular(
                                  ClRadius.control,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: ClIcon(
                                i.icon,
                                size: 20,
                                color: cl.colors.ink,
                              ),
                            ),
                            const SizedBox(width: ClSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.title,
                                    style: cl.text.body.copyWith(
                                      color: cl.colors.ink,
                                    ),
                                  ),
                                  if (i.overdue)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: ClIcon(
                                            ClIcons.alert,
                                            size: 16,
                                            color: cl.colors.pending,
                                          ),
                                        ),
                                        const SizedBox(width: ClSpace.s1),
                                        Expanded(
                                          child: Text(
                                            when(i.at, i.overdue, i.day),
                                            style: cl.text.label.copyWith(
                                              color: cl.colors.pending,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      when(i.at, i.overdue, i.day),
                                      style: cl.text.label.copyWith(
                                        color: cl.colors.inkMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(
          title: items.isEmpty
              ? l10n.reminderPeekTitle
              : l10n.reminderPeekLabel(items.length),
          linkLabel: items.isEmpty ? null : l10n.reminderPeekMore,
          onLink: () => context.push(Routes.reminders),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          shadow: true,
          children: [
            if (items.isEmpty)
              ClListRow(
                leading: mark(ClIcons.bell, cl.colors.mintSoft),
                title: l10n.reminderPeekEmpty,
                subtitle: parent ? l10n.reminderPeekAdd : null,
                subtitleColor: cl.colors.mintText,
                onTap: () => parent
                    ? showReminderSheet(context)
                    : context.push(Routes.reminders),
              )
            else
              for (final i in items.take(shown))
                ClListRow(
                  leading: mark(i.icon, i.tint, overdue: i.overdue),
                  title: i.title,
                  subtitle: when(i.at, i.overdue, i.day),
                  subtitleColor: i.overdue ? cl.colors.pending : null,
                  onTap: i.open,
                ),
          ],
        ),
      ],
    );
  }
}
