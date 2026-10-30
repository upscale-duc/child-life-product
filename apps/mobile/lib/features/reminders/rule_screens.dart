import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
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
import '../care/care_sheets.dart' show openCareLog;
import '../family/family_labels.dart' show initialOf;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart' show MeRow;
import 'reminder_notifications.dart' show notificationsEnabledProvider;
import 'reminder_screens.dart'
    show NotificationsOffCard, maybeAskForNotifications, reminderWho;
import 'rule_models.dart';
import 'rule_repository.dart';

// ---------- Labels ----------

String ruleTitle(AppLocalizations l10n, RuleType t) => switch (t) {
  RuleType.feed => l10n.ruleTitleFeed,
  RuleType.sleep => l10n.ruleTitleSleep,
  RuleType.diaper => l10n.ruleTitleDiaper,
  RuleType.pump => l10n.ruleTitlePump,
};

String _typeLabel(AppLocalizations l10n, RuleType t) => switch (t) {
  RuleType.feed => l10n.ruleTypeFeed,
  RuleType.sleep => l10n.ruleTypeSleep,
  RuleType.diaper => l10n.ruleTypeDiaper,
  RuleType.pump => l10n.ruleTypePump,
};

String _activity(AppLocalizations l10n, RuleType t) => switch (t) {
  RuleType.feed => l10n.ruleActFeed,
  RuleType.sleep => l10n.ruleActSleep,
  RuleType.diaper => l10n.ruleActDiaper,
  RuleType.pump => l10n.ruleActPump,
};

String ruleLogLabel(AppLocalizations l10n, RuleType t) => switch (t) {
  RuleType.feed => l10n.ruleLogFeed,
  RuleType.sleep => l10n.ruleLogSleep,
  RuleType.diaper => l10n.ruleLogDiaper,
  RuleType.pump => l10n.ruleLogPump,
};

String _dueLabel(AppLocalizations l10n, RuleType t) => switch (t) {
  RuleType.feed => l10n.ruleDueFeed,
  RuleType.sleep => l10n.ruleDueSleep,
  RuleType.diaper => l10n.ruleDueDiaper,
  RuleType.pump => l10n.ruleDuePump,
};

/// The activity's icon and soft tint, as on the rule cards (Hôm nay's reminders use them too).
ClIcons ruleIcon(RuleType t) => _icon(t);
Color ruleTint(ClTheme cl, RuleType t) => _tint(cl, t);

ClIcons _icon(RuleType t) => switch (t) {
  RuleType.feed => ClIcons.feed,
  RuleType.sleep => ClIcons.sleep,
  RuleType.diaper => ClIcons.diaper,
  RuleType.pump => ClIcons.drop,
};

Color _tint(ClTheme cl, RuleType t) => switch (t) {
  RuleType.feed => cl.care.bottle.soft,
  RuleType.sleep => cl.care.sleep.soft,
  RuleType.diaper => cl.care.diaper.soft,
  RuleType.pump => cl.care.pump.soft,
};

/// "T2" … "CN" / "Mon" … "Sun" (ISO weekday).
String weekdayShort(String locale, int isoDay) {
  if (locale.startsWith('vi')) return isoDay == 7 ? 'CN' : 'T${isoDay + 1}';
  // 5 Oct 2026 is a Monday.
  return DateFormat.E(locale).format(DateTime(2026, 10, 4 + isoDay));
}

String _days(AppLocalizations l10n, String locale, List<int> days) =>
    days.length == 7
    ? l10n.ruleEveryDay
    : ([...days]..sort()).map((d) => weekdayShort(locale, d)).join(', ');

/// 1a line: "3 giờ sau lần bú gần nhất" / "Cố định 09:00 · 13:00 · 19:30" (+ days).
String ruleLine(AppLocalizations l10n, String locale, ReminderRule r) {
  final base = switch (r.mode) {
    RuleMode.afterLast => () {
      final d = durationLabel(l10n, r.intervalMinutes ?? 0);
      return switch (r.type) {
        RuleType.feed => l10n.ruleAfterFeed(d),
        RuleType.sleep => l10n.ruleAfterSleep(d),
        RuleType.diaper => l10n.ruleAfterDiaper(d),
        RuleType.pump => l10n.ruleAfterPump(d),
      };
    }(),
    RuleMode.fixed => l10n.ruleFixedLine(r.times.join(' · ')),
  };
  return r.everyDay ? base : '$base · ${_days(l10n, locale, r.days)}';
}

/// "14:45", "mai 09:00", "T6 09:00" in the baby's zone.
String _when(
  AppLocalizations l10n,
  String locale,
  String zone,
  DateTime at,
  DateTime now,
) {
  final wall = inBabyZone(zone, at);
  final hm = DateFormat('HH:mm').format(wall);
  final today = babyToday(zone, now);
  final day = DateTime(wall.year, wall.month, wall.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return hm;
  if (diff == 1) return '${l10n.dayTomorrow} $hm';
  return '${weekdayShort(locale, wall.weekday)} $hm';
}

String _hm(String zone, DateTime at) =>
    DateFormat('HH:mm').format(inBabyZone(zone, at));

/// What every rule screen needs.
typedef RuleCtx = ({Membership me, String zone, String locale, DateTime now});

RuleCtx? _ctx(BuildContext context, WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  return (
    me: me,
    zone: baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
    locale: Localizations.localeOf(context).toLanguageTag(),
    now: ref.watch(careClockProvider).value ?? DateTime.now(),
  );
}

// ---------- 1a "Theo quy tắc" ----------

/// The "Theo quy tắc" half of Nhắc nhở (370:2365): rules with their next time and a pause
/// toggle, who receives them, the 1h banner when someone else handled one, and "Thêm nhắc".
class RuleRemindersList extends ConsumerWidget {
  const RuleRemindersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _ctx(context, ref);
    if (c == null) return const SizedBox.shrink();
    final parent = c.me.role == MemberRole.coParent;
    final rules = ref.watch(reminderRulesProvider(c.me.babyId)).value;
    final members =
        ref.watch(familyMembersProvider(c.me.babyId)).value ?? const [];
    final handled = _recentHandled(rules ?? const [], c);
    // NT-5: a rule that sends to this person cannot show on this phone while the system has
    // its notifications off; said here as on "Một lần" (8d).
    final silenced =
        ref.watch(notificationsEnabledProvider) == false &&
        (rules ?? const []).any(
          (r) => r.enabled && r.recipients.contains(c.me.uid),
        );

    final recipients = <String>{
      for (final r in rules ?? const []) ...r.recipients,
    };
    final names = [
      if (recipients.contains(c.me.uid)) l10n.ruleYou,
      for (final m in members)
        if (m.uid != c.me.uid && recipients.contains(m.uid)) m.displayName,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (silenced) ...[
          NotificationsOffCard(
            key: const Key('rule-notif-off'),
            message: l10n.ruleNotifOff,
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        if (handled != null) ...[
          _HandledBanner(rule: handled, ctx: c),
          const SizedBox(height: ClSpace.s3),
        ],
        if (!parent) ...[
          _NoteRow(icon: ClIcons.clock, text: l10n.ruleCaregiverNote),
          const SizedBox(height: ClSpace.s3),
        ],
        if (rules != null && rules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
            child: Column(
              children: [
                Text(
                  l10n.ruleEmpty,
                  style: cl.text.headline,
                  textAlign: TextAlign.center,
                ),
                if (parent) ...[
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.ruleEmptyBody,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        if (rules != null && rules.isNotEmpty) ...[
          ClCardGroup(
            children: [
              for (final r in rules)
                RuleRow(rule: r, ctx: c, canToggle: parent),
            ],
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.ruleRecipientsLine(names.join(', ')),
              style: cl.text.label.copyWith(
                fontSize: 13,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
        ],
        if (parent) ...[
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.ruleAdd,
            expand: true,
            onPressed: () => context.push(Routes.ruleNew),
          ),
        ],
      ],
    );
  }

  /// 1h: a rule someone else answered by logging in the last 3 hours.
  static ReminderRule? _recentHandled(List<ReminderRule> rules, RuleCtx c) {
    ReminderRule? best;
    for (final r in rules) {
      final o = r.lastOutcome;
      if (o == null || o.outcome != RuleOutcome.logged || o.by == c.me.uid) {
        continue;
      }
      if (c.now.difference(o.at) > const Duration(hours: 3)) continue;
      if (best == null || o.at.isAfter(best.lastOutcome!.at)) best = r;
    }
    return best;
  }
}

class _HandledBanner extends ConsumerWidget {
  const _HandledBanner({required this.rule, required this.ctx});
  final ReminderRule rule;
  final RuleCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final o = rule.lastOutcome!;
    final who = o.author == null
        ? ''
        : reminderWho(l10n, o.author!, o.by == ctx.me.uid);
    final record = o.recordId == null
        ? null
        : ref.watch(careRecordProvider((rule.babyId, o.recordId!))).value;
    final at = record?.occurredAt ?? o.at;
    final next = rule.nextDueAt;
    final text = next == null
        ? l10n.ruleHandledNoNext(
            who,
            _activity(l10n, rule.type),
            _hm(ctx.zone, at),
          )
        : l10n.ruleHandled(
            who,
            _activity(l10n, rule.type),
            _hm(ctx.zone, at),
            _when(l10n, ctx.locale, ctx.zone, next, ctx.now),
          );
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.check, size: 18, color: cl.colors.mintText),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.mintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});
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

/// 1a row: tinted icon · title · rule line · status pill · toggle (parents).
class RuleRow extends ConsumerStatefulWidget {
  const RuleRow({
    required this.rule,
    required this.ctx,
    required this.canToggle,
    this.onTap,
    super.key,
  });

  final ReminderRule rule;
  final RuleCtx ctx;
  final bool canToggle;
  final VoidCallback? onTap;

  @override
  ConsumerState<RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends ConsumerState<RuleRow> {
  /// The toggle answers at once; the server confirms (or the toast says it did not).
  bool? _optimistic;

  @override
  void didUpdateWidget(RuleRow old) {
    super.didUpdateWidget(old);
    if (old.rule.enabled != widget.rule.enabled) _optimistic = null;
  }

  Future<void> _toggle(bool on) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _optimistic = on);
    try {
      await ref
          .read(ruleRepositoryProvider)
          .setEnabled(widget.rule.babyId, widget.rule.id, on);
    } on Object {
      if (mounted) setState(() => _optimistic = null);
      toaster.show(message: l10n.ruleSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = widget.rule;
    final c = widget.ctx;
    final enabled = _optimistic ?? r.enabled;
    final title = ruleTitle(l10n, r.type);
    return ClPressable(
      onPressed:
          widget.onTap ?? () => context.push('${Routes.ruleDetail}/${r.id}'),
      semanticLabel: '$title. ${ruleLine(l10n, c.locale, r)}',
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
                color: _tint(cl, r.type),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: ClIcon(_icon(r.type), size: 20, color: cl.colors.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 15)),
                  Text(
                    ruleLine(l10n, c.locale, r),
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RuleStatusPill(rule: r, ctx: c, enabled: enabled),
                ],
              ),
            ),
            if (widget.canToggle)
              ClToggle(
                value: enabled,
                semanticLabel: title,
                onChanged: (on) => unawaited(_toggle(on)),
              ),
          ],
        ),
      ),
    );
  }
}

class RuleStatusPill extends StatelessWidget {
  const RuleStatusPill({
    required this.rule,
    required this.ctx,
    required this.enabled,
    super.key,
  });

  final ReminderRule rule;
  final RuleCtx ctx;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = rule;
    final (label, active) = switch (r) {
      _ when !enabled => (l10n.rulePaused, false),
      ReminderRule(pendingDueAt: final due?) => (
        l10n.ruleDueNow(_hm(ctx.zone, due)),
        true,
      ),
      ReminderRule(snoozedUntil: final s?) when s.isAfter(ctx.now) => (
        l10n.ruleSnoozedUntil(_hm(ctx.zone, s)),
        true,
      ),
      ReminderRule(nextDueAt: final n?) => (
        l10n.ruleNext(_when(l10n, ctx.locale, ctx.zone, n, ctx.now)),
        true,
      ),
      _ => (l10n.ruleWaiting, false),
    };
    final fg = active ? cl.colors.mintText : cl.colors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClIcon(ClIcons.clock, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: cl.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 1h detail ----------

/// One rule: its row, the 1h banner, "Gần đây" (Đã ghi · Báo lại · Bỏ qua) and, for Cùng nuôi,
/// "Sửa nhắc" / "Xoá nhắc" (not drawn in Figma).
class RuleDetailScreen extends ConsumerWidget {
  const RuleDetailScreen({required this.ruleId, super.key});
  final String ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _ctx(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final rule =
        (ref.watch(reminderRulesProvider(c.me.babyId)).value ?? const [])
            .where((r) => r.id == ruleId)
            .firstOrNull;
    final parent = c.me.role == MemberRole.coParent;
    final history =
        ref.watch(ruleOccurrencesProvider((c.me.babyId, ruleId))).value ??
        const [];
    final handled = rule == null
        ? null
        : RuleRemindersList._recentHandled([rule], c);
    return _RulePage(
      children: rule == null
          ? const []
          : [
              Semantics(
                header: true,
                child: Text(
                  ruleTitle(l10n, rule.type),
                  style: cl.text.largeTitle,
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              if (handled != null) ...[
                _HandledBanner(rule: handled, ctx: c),
                const SizedBox(height: ClSpace.s3),
              ],
              ClCardGroup(
                children: [
                  RuleRow(
                    rule: rule,
                    ctx: c,
                    canToggle: parent,
                    onTap: parent
                        ? () => context.push(
                            '${Routes.ruleDetail}/${rule.id}/edit',
                          )
                        : () {},
                  ),
                ],
              ),
              if (rule.pendingDueAt != null) ...[
                const SizedBox(height: ClSpace.s3),
                ClButton(
                  label: ruleLogLabel(l10n, rule.type),
                  style: ClButtonStyle.secondary,
                  expand: true,
                  onPressed: () => showRuleDueSheet(
                    context,
                    babyId: rule.babyId,
                    ruleId: rule.id,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(
                  top: ClSpace.s6,
                  bottom: ClSpace.s2,
                ),
                child: Semantics(
                  header: true,
                  child: Text(l10n.ruleRecent, style: cl.text.headline),
                ),
              ),
              if (history.isEmpty)
                Text(
                  l10n.ruleRecentEmpty,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                )
              else
                ClCardGroup(
                  children: [
                    for (final o in history)
                      _OccurrenceRow(occurrence: o, rule: rule, ctx: c),
                  ],
                ),
              if (parent) ...[
                const SizedBox(height: ClSpace.s6),
                ClButton(
                  label: l10n.ruleEdit,
                  style: ClButtonStyle.secondary,
                  icon: ClIcons.edit,
                  expand: true,
                  onPressed: () =>
                      context.push('${Routes.ruleDetail}/${rule.id}/edit'),
                ),
                ClButton(
                  label: l10n.ruleDelete,
                  style: ClButtonStyle.plain,
                  expand: true,
                  onPressed: () => unawaited(_delete(context, ref, rule)),
                ),
              ],
            ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ReminderRule r,
  ) async {
    final l10n = AppLocalizations.of(context);
    final title = ruleTitle(l10n, r.type);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.ruleDeleteTitle(title.toLowerCase())),
          Text(
            l10n.ruleDeleteBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.ruleDeleteConfirm,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    try {
      await withClProgress(
        context,
        () => ref.read(ruleRepositoryProvider).delete(r.babyId, r.id),
      );
      toaster.show(message: l10n.ruleDeleted);
      if (router.canPop()) router.pop();
    } on Object {
      toaster.show(message: l10n.ruleSaveFailed);
    }
  }
}

class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({
    required this.occurrence,
    required this.rule,
    required this.ctx,
  });

  final RuleOccurrence occurrence;
  final ReminderRule rule;
  final RuleCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final o = occurrence;
    final time = _hm(ctx.zone, o.dueAt);
    final who = o.author == null
        ? ''
        : reminderWho(l10n, o.author!, o.by == ctx.me.uid);
    final record = o.recordId == null
        ? null
        : ref.watch(careRecordProvider((rule.babyId, o.recordId!))).value;
    final (icon, title, subtitle, muted) = switch (o.outcome) {
      RuleOutcome.logged => (
        ClIcons.check,
        l10n.ruleOutLogged(time),
        record == null
            ? who
            : l10n.ruleOutLoggedBy(
                who,
                recordSummary(l10n, ctx.locale, record).toLowerCase(),
              ),
        false,
      ),
      RuleOutcome.snoozed => (
        ClIcons.clock,
        l10n.ruleOutSnoozed(time, o.minutes ?? 15),
        who,
        false,
      ),
      RuleOutcome.skipped => (
        ClIcons.close,
        l10n.ruleOutSkipped(time),
        who,
        true,
      ),
      RuleOutcome.missed => (ClIcons.alert, l10n.ruleOutMissed(time), '', true),
    };
    final fg = muted ? cl.colors.inkMuted : cl.colors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          ClIcon(
            icon,
            size: 18,
            color: muted ? cl.colors.inkMuted : cl.colors.mintText,
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: cl.text.bodyStrong.copyWith(fontSize: 15, color: fg),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pushed page every rule screen uses: back · baby chip, then content.
class _RulePage extends ConsumerWidget {
  const _RulePage({required this.children, this.close = false});

  final List<Widget> children;
  final bool close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: close ? null : () => context.pop(),
                // 1b opens with a close button instead of back.
                brand: close
                    ? _CircleIcon(
                        icon: ClIcons.close,
                        semanticLabel: l10n.a11yClose,
                        onPressed: () => context.pop(),
                      )
                    : null,
                trailing: baby == null
                    ? null
                    : ClBabySwitcher(
                        label: baby.nickname,
                        avatar: SavedBabyAvatar(baby: baby, size: 32),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s6,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 1b → 1c / 1c2 → 1d ----------

/// "Thêm nhắc" and "Sửa nhắc": type and how (1b), timing (1c after the last log, 1c2 fixed
/// times), then recipients and a summary (1d) → "Lưu nhắc" → 1a with a toast and the
/// notification ask (1e, via the 8c pre-prompt since iOS cannot change the alert's body).
class RuleEditorScreen extends ConsumerStatefulWidget {
  const RuleEditorScreen({
    this.ruleId,
    this.initialIntervalMinutes,
    this.initialType,
    this.initialTimes,
    this.initialDays,
    super.key,
  });
  final int? initialIntervalMinutes;

  /// Lumi L5 ("nhắc thay tã lúc 8h, 12h hằng ngày"): the kind, fixed times and days said; the
  /// person still picks who is reminded and saves.
  final RuleType? initialType;
  final List<String>? initialTimes;
  final List<int>? initialDays;

  /// Null for a new rule.
  final String? ruleId;

  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  RuleDraft? _draft;
  int _step = 0;
  bool _saving = false;

  /// The draft to start from, once what it needs has loaded (the rule being edited; the
  /// family, whose eligible members are all ticked to begin with in 1d).
  RuleDraft? _initial(RuleCtx c, List<Membership>? members) {
    if (widget.ruleId != null) {
      final rule =
          (ref.read(reminderRulesProvider(c.me.babyId)).value ?? const [])
              .where((r) => r.id == widget.ruleId)
              .firstOrNull;
      return rule == null ? null : RuleDraft.of(rule);
    }
    if (members == null) return null;
    final times = widget.initialTimes ?? const <String>[];
    final days = widget.initialDays ?? const <int>[];
    // Filled from somewhere else (Nhịp riêng, Lumi): only this person is ticked to begin with.
    final prefilled =
        widget.initialIntervalMinutes != null ||
        widget.initialType != null ||
        times.isNotEmpty;
    return RuleDraft(
      id: newRuleId(),
      type: widget.initialType ?? RuleType.feed,
      mode: times.isNotEmpty ? RuleMode.fixed : RuleMode.afterLast,
      times: times.isNotEmpty
          ? times.take(RuleLimits.timesMax).toList()
          : const ['09:00', '13:00', '19:30'],
      days: days.isNotEmpty ? days : RuleLimits.allDays,
      intervalMinutes:
          widget.initialIntervalMinutes != null &&
              widget.initialIntervalMinutes! >= RuleLimits.intervalMin &&
              widget.initialIntervalMinutes! <= RuleLimits.intervalMax &&
              widget.initialIntervalMinutes! % RuleLimits.intervalStep == 0
          ? widget.initialIntervalMinutes!
          : 180,
      recipients: [
        for (final m in members)
          if (_canReceive(m) && (!prefilled || m.uid == c.me.uid)) m.uid,
      ],
    );
  }

  static bool _canReceive(Membership m) =>
      m.isActive &&
      (m.role == MemberRole.coParent || m.role == MemberRole.caregiver);

  /// Builds on the draft as it is when the tap lands (quick taps build on each other).
  void _update(RuleDraft Function(RuleDraft) change) =>
      setState(() => _draft = change(_draft!));

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _save(RuleCtx c) async {
    final l10n = AppLocalizations.of(context);
    final d = _draft!;
    if (d.recipients.isEmpty) {
      showClToast(context, message: l10n.ruleNeedRecipient);
      return;
    }
    setState(() => _saving = true);
    final toaster = ClToaster.of(context);
    try {
      await ref.read(ruleRepositoryProvider).save(c.me.babyId, d);
      if (!mounted) return;
      ClHaptics.success();
      toaster.show(
        message: switch (d.type) {
          RuleType.feed => l10n.ruleSavedFeed,
          RuleType.sleep => l10n.ruleSavedSleep,
          RuleType.diaper => l10n.ruleSavedDiaper,
          RuleType.pump => l10n.ruleSavedPump,
        },
      );
      final router = GoRouter.of(context);
      // Back to the list (an edit goes back to its detail).
      if (router.canPop()) {
        router.pop();
      } else {
        setState(() => _saving = false);
      }
      // 1e: the notification ask after the first save on this device.
      final root = router.routerDelegate.navigatorKey.currentContext;
      if (root != null && root.mounted) {
        await maybeAskForNotifications(root, ref);
      }
    } on Object {
      if (mounted) setState(() => _saving = false);
      toaster.show(message: l10n.ruleSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = _ctx(context, ref);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final loaded = ref.watch(familyMembersProvider(c.me.babyId)).value;
    ref.watch(reminderRulesProvider(c.me.babyId));
    final members = loaded ?? const <Membership>[];
    final draft = _draft ??= _initial(c, loaded);
    if (draft == null) return const _RulePage(children: []);
    final editing = widget.ruleId != null;

    final (List<Widget> body, Widget primary) = switch (_step) {
      0 => (
        _typeStep(l10n, cl, draft, editing),
        ClButton(
          label: l10n.ruleContinue,
          expand: true,
          onPressed: () => setState(() => _step = 1),
        ),
      ),
      1 => (
        draft.mode == RuleMode.afterLast
            ? _intervalStep(l10n, cl, c, draft)
            : _fixedStep(l10n, cl, c, draft),
        ClButton(
          label: l10n.ruleContinue,
          expand: true,
          onPressed: draft.mode == RuleMode.fixed && draft.times.isEmpty
              ? null
              : () => setState(() => _step = 2),
        ),
      ),
      _ => (
        _whoStep(l10n, cl, c, draft, members),
        ClButton(
          label: l10n.ruleSave,
          expand: true,
          loading: _saving,
          onPressed: _saving ? null : () => unawaited(_save(c)),
        ),
      ),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _RulePage(
        close: _step == 0,
        children: [
          ...body,
          const SizedBox(height: ClSpace.s6),
          primary,
        ],
      ),
    );
  }

  // 1b
  List<Widget> _typeStep(
    AppLocalizations l10n,
    ClTheme cl,
    RuleDraft d,
    bool editing,
  ) => [
    Semantics(
      header: true,
      child: Text(
        editing ? l10n.ruleEditTitle : l10n.ruleNewTitle,
        style: cl.text.largeTitle,
      ),
    ),
    const SizedBox(height: ClSpace.s2),
    Text(
      l10n.ruleWhat,
      style: cl.text.body.copyWith(color: cl.colors.inkMuted),
    ),
    const SizedBox(height: ClSpace.s4),
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: ClSpace.s3,
      crossAxisSpacing: ClSpace.s3,
      childAspectRatio: 165 / 96,
      children: [
        for (final t in RuleType.values)
          _OptionCard(
            icon: _icon(t),
            tint: _tint(cl, t),
            label: _typeLabel(l10n, t),
            selected: d.type == t,
            // The type of a saved rule stays (its history is about that activity).
            onTap: editing && d.type != t
                ? null
                : () => _update((d) => d.copyWith(type: t)),
          ),
      ],
    ),
    const SizedBox(height: ClSpace.s6),
    Text(l10n.ruleHow, style: cl.text.headline),
    const SizedBox(height: ClSpace.s3),
    for (final (mode, title, hint) in [
      (RuleMode.afterLast, l10n.ruleModeAfter, l10n.ruleModeAfterHint),
      (RuleMode.fixed, l10n.ruleModeFixed, l10n.ruleModeFixedHint),
    ]) ...[
      _RadioRow(
        title: title,
        hint: hint,
        selected: d.mode == mode,
        onTap: () => _update((d) => d.copyWith(mode: mode)),
      ),
      const SizedBox(height: ClSpace.s2),
    ],
  ];

  // 1c
  List<Widget> _intervalStep(
    AppLocalizations l10n,
    ClTheme cl,
    RuleCtx c,
    RuleDraft d,
  ) {
    final records =
        ref.watch(recentRecordsProvider(c.me.babyId)).value ?? const [];
    final last = records
        .where((r) => d.type.careTypes.contains(r.type) && !r.deleted)
        .firstOrNull;
    final anchor = last == null
        ? null
        : d.type == RuleType.sleep
        ? last.endedAt
        : last.occurredAt;
    final act = switch (d.type) {
      RuleType.feed => l10n.ruleExFeed,
      RuleType.sleep => l10n.ruleExSleep,
      RuleType.diaper => l10n.ruleExDiaper,
      RuleType.pump => l10n.ruleExPump,
    };
    void interval(int m) => _update(
      (d) => d.copyWith(
        intervalMinutes: m.clamp(
          RuleLimits.intervalMin,
          RuleLimits.intervalMax,
        ),
      ),
    );
    return [
      Text(
        l10n.ruleStep(2),
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      Semantics(
        header: true,
        child: Text(ruleTitle(l10n, d.type), style: cl.text.largeTitle),
      ),
      const SizedBox(height: ClSpace.s4),
      _Card(
        children: [
          Text(
            l10n.ruleEvery,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              _StepButton(
                label: '−',
                semanticLabel: durationLabel(
                  l10n,
                  d.intervalMinutes - RuleLimits.intervalStep,
                ),
                onTap: d.intervalMinutes <= RuleLimits.intervalMin
                    ? null
                    : () =>
                          interval(d.intervalMinutes - RuleLimits.intervalStep),
              ),
              Expanded(
                child: Text(
                  _hoursMinutes(l10n, d.intervalMinutes),
                  textAlign: TextAlign.center,
                  style: cl.text.title.copyWith(fontSize: 28),
                ),
              ),
              _StepButton(
                label: '+',
                semanticLabel: durationLabel(
                  l10n,
                  d.intervalMinutes + RuleLimits.intervalStep,
                ),
                onTap: d.intervalMinutes >= RuleLimits.intervalMax
                    ? null
                    : () =>
                          interval(d.intervalMinutes + RuleLimits.intervalStep),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              for (final (i, m) in RuleLimits.presets.indexed) ...[
                if (i > 0) const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: _Chip(
                    label: _presetLabel(l10n, m),
                    selected: d.intervalMinutes == m,
                    onTap: () => interval(m),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Text(switch (d.type) {
            RuleType.feed => l10n.ruleCountedFeed,
            RuleType.sleep => l10n.ruleCountedSleep,
            RuleType.diaper => l10n.ruleCountedDiaper,
            RuleType.pump => l10n.ruleCountedPump,
          }, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
        ],
      ),
      const SizedBox(height: ClSpace.s3),
      Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ruleExample,
              style: cl.text.caption.copyWith(color: cl.colors.mintText),
            ),
            const SizedBox(height: 2),
            _ArrowText(
              anchor == null
                  ? l10n.ruleExampleNone
                  : l10n.ruleExampleLine(
                      act,
                      _hm(c.zone, anchor),
                      _hm(
                        c.zone,
                        anchor.add(Duration(minutes: d.intervalMinutes)),
                      ),
                    ),
              style: cl.text.bodyStrong.copyWith(color: cl.colors.mintText),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.ruleExampleShift(_activity(l10n, d.type)),
              style: cl.text.caption.copyWith(color: cl.colors.mintText),
            ),
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s3),
      ClCardGroup(
        children: [
          ClPressable(
            onPressed: () =>
                _update((d) => d.copyWith(quietNight: !d.quietNight)),
            semanticLabel: l10n.ruleQuiet,
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
                        Text(l10n.ruleQuiet, style: cl.text.body),
                        Text(
                          l10n.ruleQuietRange,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClToggle(
                    value: d.quietNight,
                    semanticLabel: l10n.ruleQuiet,
                    onChanged: (on) =>
                        _update((d) => d.copyWith(quietNight: on)),
                  ),
                ],
              ),
            ),
          ),
          MeRow(
            title: l10n.ruleDays,
            value: _days(l10n, c.locale, d.days),
            onTap: () => unawaited(_pickDays(d)),
          ),
        ],
      ),
    ];
  }

  Future<void> _pickDays(RuleDraft d) async {
    final picked = await showClSheet<List<int>>(
      context: context,
      builder: (sheet) => _DaysSheet(initial: d.days),
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      _update((d) => d.copyWith(days: picked));
    }
  }

  // 1c2
  List<Widget> _fixedStep(
    AppLocalizations l10n,
    ClTheme cl,
    RuleCtx c,
    RuleDraft d,
  ) {
    final times = [...d.times]..sort();
    return [
      Text(
        l10n.ruleStep(2),
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      Semantics(
        header: true,
        child: Text(ruleTitle(l10n, d.type), style: cl.text.largeTitle),
      ),
      const SizedBox(height: ClSpace.s4),
      _Card(
        children: [
          Text(
            l10n.ruleTimesTitle,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          for (final t in times) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(ClSpace.s4, 4, 4, 4),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(t, style: cl.text.title2.copyWith(fontSize: 20)),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Text(
                      _slotLabel(l10n, d.type, minuteOfClock(t)),
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                  _CircleIcon(
                    icon: ClIcons.close,
                    small: true,
                    semanticLabel: l10n.ruleRemoveTime(t),
                    onPressed: () => _update(
                      (d) => d.copyWith(times: [...d.times]..remove(t)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          if (d.times.length < RuleLimits.timesMax)
            ClPressable(
              onPressed: () => unawaited(_addTime(d)),
              semanticLabel: l10n.ruleAddTime,
              child: CustomPaint(
                painter: _DashedBorder(color: cl.colors.controlBorder),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText),
                      const SizedBox(width: ClSpace.s2),
                      Text(
                        l10n.ruleAddTime,
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cl.colors.mintText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
      Text(l10n.ruleWeek, style: cl.text.headline),
      const SizedBox(height: ClSpace.s3),
      _DayPills(
        selected: d.days,
        onChanged: (days) => _update((d) => d.copyWith(days: days)),
      ),
      const SizedBox(height: ClSpace.s4),
      Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClIcon(ClIcons.globe, size: 16, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                l10n.ruleZoneNote(gmtOffsetLabel(c.zone, c.now)),
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _addTime(RuleDraft d) async {
    final l10n = AppLocalizations.of(context);
    final picked = await _pickClock(context, initial: 9 * 60);
    if (picked == null || !mounted) return;
    final t = clockOf(picked);
    if (_draft!.times.contains(t)) {
      showClToast(context, message: l10n.ruleTimeExists);
      return;
    }
    _update((d) => d.copyWith(times: [..._draft!.times, t]));
  }

  // 1d
  List<Widget> _whoStep(
    AppLocalizations l10n,
    ClTheme cl,
    RuleCtx c,
    RuleDraft d,
    List<Membership> members,
  ) {
    final listed = [
      ...members.where((m) => m.uid == c.me.uid),
      ...members.where((m) => m.uid != c.me.uid && m.isActive),
    ];
    final summary = [
      ruleLine(
        l10n,
        c.locale,
        ReminderRule(
          id: d.id,
          babyId: c.me.babyId,
          type: d.type,
          mode: d.mode,
          intervalMinutes: d.intervalMinutes,
          times: [...d.times]..sort(),
          days: d.days,
          quietNight: d.quietNight,
          recipients: d.recipients,
          enabled: true,
        ),
      ),
      if (d.mode == RuleMode.afterLast)
        d.quietNight ? l10n.ruleNotAtNight : l10n.ruleAllDay,
      l10n.ruleRecipients(d.recipients.length),
    ].join(' · ');
    return [
      Text(
        l10n.ruleStep(3),
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      Semantics(
        header: true,
        child: Text(l10n.ruleWho, style: cl.text.largeTitle),
      ),
      const SizedBox(height: ClSpace.s4),
      ClCardGroup(
        children: [
          for (final m in listed)
            _RecipientRow(
              member: m,
              me: m.uid == c.me.uid,
              enabled: _canReceive(m),
              checked: d.recipients.contains(m.uid),
              onChanged: (on) => _update(
                (d) => d.copyWith(
                  recipients: on
                      ? [...d.recipients, m.uid]
                      : ([...d.recipients]..remove(m.uid)),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s3),
      Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClIcon(ClIcons.family, size: 16, color: cl.colors.mintText),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                l10n.ruleWhoNote,
                style: cl.text.caption.copyWith(color: cl.colors.mintText),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s3),
      Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ruleTitle(l10n, d.type), style: cl.text.bodyStrong),
            const SizedBox(height: 2),
            Text(
              summary,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    ];
  }
}

String _hoursMinutes(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l10n.durationMinutes(m);
  return l10n
      .durationHoursMinutes(h, m)
      .replaceFirst(RegExp(r'\b0\b(?=\D*$)'), '00');
}

/// "2 giờ" · "2 giờ 30" (1c presets).
String _presetLabel(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? l10n.durationHours(h) : '${l10n.durationHours(h)} $m';
}

/// "Giấc sáng / trưa / chiều / đêm" for sleep, "Buổi …" otherwise (labels follow the time).
String _slotLabel(AppLocalizations l10n, RuleType type, int minute) {
  final sleep = type == RuleType.sleep;
  if (minute < 11 * 60 && minute >= 4 * 60) {
    return sleep ? l10n.ruleSlotMorningNap : l10n.ruleSlotMorning;
  }
  if (minute >= 11 * 60 && minute < 14 * 60) {
    return sleep ? l10n.ruleSlotMiddayNap : l10n.ruleSlotMidday;
  }
  if (minute >= 14 * 60 && minute < 18 * 60) {
    return sleep ? l10n.ruleSlotAfternoonNap : l10n.ruleSlotAfternoon;
  }
  return sleep ? l10n.ruleSlotNightSleep : l10n.ruleSlotEvening;
}

Future<int?> _pickClock(BuildContext context, {required int initial}) {
  var picked = initial;
  return showClSheet<int>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.ruleAddTime),
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
                  initial ~/ 60,
                  initial % 60,
                ),
                onDateTimeChanged: (d) => picked = d.hour * 60 + d.minute,
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

class _DaysSheet extends StatefulWidget {
  const _DaysSheet({required this.initial});
  final List<int> initial;

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  late List<int> _days = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.ruleDays),
        _DayPills(selected: _days, onChanged: (d) => setState(() => _days = d)),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: _days.isEmpty
              ? null
              : () => Navigator.of(context).pop(_days..sort()),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// 1c2 "T2 … CN": at least one day stays on.
class _DayPills extends StatelessWidget {
  const _DayPills({required this.selected, required this.onChanged});
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        for (final d in RuleLimits.allDays) ...[
          if (d > 1) const SizedBox(width: 6),
          Expanded(
            child: ClPressable(
              selected: selected.contains(d),
              semanticLabel: weekdayShort(locale, d),
              onPressed: () {
                final on = selected.contains(d);
                if (on && selected.length == 1) return;
                onChanged(on ? ([...selected]..remove(d)) : [...selected, d]);
              },
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(d)
                      ? cl.colors.mintDeep
                      : cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  weekdayShort(locale, d),
                  style: cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected.contains(d)
                        ? cl.colors.onMintDeep
                        : cl.colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ClIcons icon;
  final Color tint;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Opacity(
      opacity: onTap == null && !selected ? 0.4 : 1,
      child: ClPressable(
        onPressed: onTap,
        selected: selected,
        semanticLabel: label,
        // Fills its grid cell, so every card is the same size (the pressable loosens the
        // cell's constraints; the card used to shrink to its label and sit centred).
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: selected ? cl.colors.mintSoft : cl.colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cl.colors.mintDeep : cl.colors.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(label, style: cl.text.bodyStrong),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: ClIcon(
                    ClIcons.check,
                    size: 18,
                    color: cl.colors.mintDeep,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: '$title. $hint',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cl.colors.mintSoft : cl.colors.separator,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? cl.colors.mintDeep
                      : cl.colors.controlBorder,
                  width: selected ? 7 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 15)),
                  Text(
                    hint,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: semanticLabel,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: cl.text.title2.copyWith(color: cl.colors.ink),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintDeep : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? cl.colors.onMintDeep : cl.colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({
    required this.member,
    required this.me,
    required this.enabled,
    required this.checked,
    required this.onChanged,
  });

  final Membership member;
  final bool me;
  final bool enabled;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final role = switch (member.role) {
      MemberRole.coParent => l10n.ruleRoleParent,
      MemberRole.caregiver => l10n.ruleRoleCaregiver,
      MemberRole.relative => l10n.ruleRoleViewOnly,
    };
    final avatar = switch (member.role) {
      _ when !enabled => cl.colors.surface2,
      MemberRole.coParent => me ? cl.colors.peachSoft : cl.care.sleep.soft,
      _ => cl.care.diaper.soft,
    };
    final name = me
        ? l10n.careYouSuffix(member.displayName)
        : member.displayName;
    return ClPressable(
      onPressed: enabled ? () => onChanged(!checked) : null,
      selected: checked,
      semanticLabel: '$name, $role',
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
              decoration: BoxDecoration(color: avatar, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                initialOf(member.displayName),
                style: cl.text.bodyStrong.copyWith(
                  color: enabled ? cl.colors.ink : cl.colors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      color: enabled ? cl.colors.ink : cl.colors.inkMuted,
                    ),
                  ),
                  Text(
                    role,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked && enabled ? cl.colors.mintDeep : null,
                borderRadius: BorderRadius.circular(7),
                border: checked && enabled
                    ? null
                    : Border.all(color: cl.colors.controlBorder, width: 1.5),
              ),
              alignment: Alignment.center,
              child: checked && enabled
                  ? ClIcon(ClIcons.check, size: 14, color: cl.colors.onMintDeep)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bú lúc 11:45 → nhắc lúc 14:45": the font has no arrow glyph, so it is drawn.
class _ArrowText extends StatelessWidget {
  const _ArrowText(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('→');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ClIcon(ClIcons.arrowRight, size: 16, color: style.color),
              ),
            TextSpan(text: part),
          ],
        ],
      ),
      semanticsLabel: text,
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.small = false,
  });

  final ClIcons icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        child: Center(
          child: Container(
            width: small ? 32 : ClSpace.tapMin,
            height: small ? 32 : ClSpace.tapMin,
            decoration: BoxDecoration(
              color: small ? null : c.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: small ? 16 : 20, color: c.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(14),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

// ---------- 1g due sheet ----------

/// 1g "Đến giờ nhắc" (370:2860): the last log of the activity, "Ghi …", snooze 10 · 15 · 30
/// phút and "Bỏ qua lần này". Opened from the notification or when it rings in the app.
Future<void> showRuleDueSheet(
  BuildContext context, {
  required String babyId,
  required String ruleId,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _DueSheet(babyId: babyId, ruleId: ruleId),
);

class _DueSheet extends ConsumerStatefulWidget {
  const _DueSheet({required this.babyId, required this.ruleId});
  final String babyId;
  final String ruleId;

  @override
  ConsumerState<_DueSheet> createState() => _DueSheetState();
}

class _DueSheetState extends ConsumerState<_DueSheet> {
  bool _busy = false;

  Future<void> _answer(ReminderRule r, DateTime due, {int? snooze}) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final zone =
        ref.read(babyProvider(widget.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    setState(() => _busy = true);
    try {
      final done = await withClProgress(
        context,
        () => ref
            .read(ruleRepositoryProvider)
            .answer(r.babyId, r.id, due, snoozeMinutes: snooze),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      toaster.show(
        message: !done
            ? l10n.ruleAlreadyHandled
            : snooze == null
            ? l10n.ruleSkippedToast
            : l10n.ruleSnoozedToast(
                _hm(zone, DateTime.now().add(Duration(minutes: snooze))),
              ),
      );
    } on Object {
      if (mounted) setState(() => _busy = false);
      toaster.show(message: l10n.ruleSaveFailed);
    }
  }

  void _log(ReminderRule r, CareRecord? last) {
    final nav = Navigator.of(context);
    final host = nav.context;
    nav.pop();
    // Bú logs what was given last (bottle or breast); the others have one sheet.
    final type = switch (r.type) {
      RuleType.feed =>
        last?.type == CareType.breast ? CareType.breast : CareType.bottle,
      RuleType.sleep => CareType.sleep,
      RuleType.diaper => CareType.diaper,
      RuleType.pump => CareType.pump,
    };
    if (host.mounted) openCareLog(host, type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final rule =
        (ref.watch(reminderRulesProvider(widget.babyId)).value ?? const [])
            .where((r) => r.id == widget.ruleId)
            .firstOrNull;
    if (rule == null || me == null) {
      return const SizedBox(height: 120);
    }
    final zone =
        ref.watch(babyProvider(widget.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final due = rule.pendingDueAt;
    final records =
        ref.watch(recentRecordsProvider(widget.babyId)).value ?? const [];
    final last = records
        .where((r) => rule.type.careTypes.contains(r.type) && !r.deleted)
        .firstOrNull;
    final label = switch (rule.type) {
      RuleType.feed => l10n.ruleLastFeed,
      RuleType.sleep => l10n.ruleLastSleep,
      RuleType.diaper => l10n.ruleLastDiaper,
      RuleType.pump => l10n.ruleLastPump,
    };
    final lastAt = last == null
        ? null
        : rule.type == RuleType.sleep
        ? last.endedAt
        : last.occurredAt;
    final lastLine = last == null || lastAt == null
        ? null
        : '$label ${_hm(zone, lastAt)} '
              '(${recordSummary(l10n, locale, last).toLowerCase()}) · '
              '${l10n.careLoggedBy(reminderWho(l10n, last.author, last.createdBy == me.uid))}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _tint(cl, rule.type),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: ClIcon(_icon(rule.type), size: 22, color: cl.colors.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due == null
                        ? ruleTitle(l10n, rule.type)
                        : '${ruleTitle(l10n, rule.type)} · ${_hm(zone, due)}',
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                  Text(
                    due == null
                        ? l10n.ruleAlreadyHandled
                        : _dueLabel(l10n, rule.type),
                    style: cl.text.headline.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (lastLine != null) ...[
          const SizedBox(height: ClSpace.s3),
          Container(
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.clock, size: 16, color: cl.colors.inkMuted),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Text(
                    lastLine,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        if (me.role != MemberRole.relative)
          ClButton(
            label: ruleLogLabel(l10n, rule.type),
            expand: true,
            onPressed: _busy ? null : () => _log(rule, last),
          ),
        if (due != null) ...[
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.ruleSnoozeIn,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s2),
          Row(
            children: [
              for (final (i, m) in RuleLimits.snooze.indexed) ...[
                if (i > 0) const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: _Chip(
                    label: durationLabel(l10n, m),
                    selected: false,
                    onTap: _busy
                        ? () {}
                        : () => unawaited(_answer(rule, due, snooze: m)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.ruleSkip,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: _busy ? null : () => unawaited(_answer(rule, due)),
          ),
        ],
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}
