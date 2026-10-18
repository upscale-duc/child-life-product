import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../care/care_repository.dart' show inBabyZone;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../reminders/reminder_models.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/reminder_screens.dart'
    show assigneeName, maybeAskForNotifications;
import '../vaccines/vaccine_sheets.dart' show pickVxDate;
import 'nutrition_calc.dart';
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_reminders.dart';
import 'nutrition_repository.dart';
import 'nutrition_routes.dart';
import 'nutrition_share.dart';
import 'nutrition_state.dart';
import 'nutrition_widgets.dart';

/// 9g Lịch uống vitamin A (Figma `441:4100`, P-163 #12–#13): the eligibility line, then this
/// year's and next year's campaign rounds with their state for the baby. A Cùng nuôi taps a round
/// to record it as taken (with the date) or undo it, and sets a reminder for the next one: a
/// one-time reminder that rings at 08:00 the day before, for one member (default me), with an
/// .ics file to add to the phone calendar. Everyone else reads.
class VitaminScreen extends ConsumerWidget {
  const VitaminScreen({required this.nutrientId, super.key});
  final String nutrientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final c = ref.watch(nuContentProvider);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final n = c.nutrients[nutrientId];
    final campaign = n?.campaign;
    if (n == null || campaign == null) {
      return NuPage(
        children: [
          if (!ref.watch(nuNutrientsProvider).isLoading)
            NuEmpty(title: l10n.nuStageMissing, body: l10n.nuStageMissingBody),
        ],
      );
    }
    final b = c.baby;
    final dob = b.dob;
    final taken = ref.watch(nuVitaminTakenProvider(b.babyId)).value ?? const {};
    final rounds = dob == null
        ? const <NuVitaminRound>[]
        : nuCampaignRounds(campaign, dob, b.today, taken);
    final place = nuText(campaign.place, locale, b.name);
    final name = nuText(n.name, locale, b.name);
    final ages = nuAgeLabel(l10n, campaign.age);
    final tooYoung = c.months != null && c.months! < campaign.age.from;
    final first = nuFirstEligible(rounds);
    final next = rounds.where((r) => r.state == NuRoundState.next).firstOrNull;
    final years = {for (final r in rounds) r.from.year}.toList()..sort();

    // "Đặt nhắc" for the next round (Cùng nuôi), or "Đã đặt nhắc · {date}" once it is set.
    final time = next == null
        ? null
        : nuVitaminReminderTime(
            next.from,
            b.now,
            (wall) => instantInZone(b.zone, wall),
          );
    final reminderTitle = next == null
        ? null
        : l10n.nuVitaReminderTitle(name, nuRoundDays(tag, next.from, next.to));
    final open = reminderTitle == null
        ? null
        : nuOpenReminder(
            ref.watch(remindersProvider(b.babyId)).value ?? const [],
            reminderTitle,
            b.now,
            b.zone,
          );

    return NuPage(
      children: [
        NuTitle(name),
        const SizedBox(height: ClSpace.s2),
        Text(
          place.isEmpty
              ? l10n.nuVitaIntroNoPlace(ages)
              : l10n.nuVitaIntro(ages, place),
          style: cl.text.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        if (dob == null)
          NuNoDobCard(baby: b)
        else ...[
          if (tooYoung)
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s3),
              child: NuBanner(
                key: const Key('nuVitaTooYoung'),
                warm: false,
                text: [
                  l10n.nuVitaFrom(b.name, campaign.age.from),
                  if (first != null)
                    l10n.nuVitaFirst(
                      nuRoundDays(tag, first.from, first.to, year: true),
                    ),
                ].join(' '),
              ),
            ),
          for (final year in years) ...[
            if (years.length > 1)
              Padding(
                padding: const EdgeInsets.only(
                  top: ClSpace.s2,
                  bottom: ClSpace.s2,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    '$year',
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            NuGroup(
              children: [
                for (final r in rounds.where((r) => r.from.year == year))
                  _RoundRow(
                    key: Key('nuRound_${r.key}'),
                    round: r,
                    place: place,
                    onTap: () => _onRound(context, ref, b, r, dob),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          if (b.coParent && next != null && time != null) ...[
            const SizedBox(height: ClSpace.s4),
            open == null
                ? ClButton(
                    key: const Key('nuVitaRemind'),
                    label: l10n.nuVitaRemind,
                    icon: ClIcons.bell,
                    expand: true,
                    onPressed: () => _reminderSheet(
                      context,
                      ref,
                      b: b,
                      nutrient: n,
                      round: next,
                      title: reminderTitle!,
                      place: place,
                    ),
                  )
                : ClButton(
                    key: const Key('nuVitaReminded'),
                    label: l10n.nuReminded(
                      nuDayMonth(inBabyZone(b.zone, open.fireAt(b.zone))),
                    ),
                    style: ClButtonStyle.tinted,
                    icon: ClIcons.check,
                    expand: true,
                    onPressed: null,
                  ),
          ],
        ],
        // The nutrient's own article (9d), when it has one to read.
        if (n.why != null || n.foods.isNotEmpty || n.byAge.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          NuGroup(
            children: [
              ClPressable(
                key: const Key('nuVitaArticle'),
                onPressed: () => context.push(NuRoutes.nutrient(n.id)),
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: l10n.nuAbout(name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      NuIconChip(
                        icon: ClIcons.journal,
                        fill: cl.colors.surface2,
                        ink: cl.colors.ink,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.nuAbout(name),
                          style: cl.text.bodyStrong.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ClIcon(
                        ClIcons.chevronRight,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        NuFootnote(item: n, extra: l10n.nuVitaLocalNote),
      ],
    );
  }

  /// A tap on a round: Cùng nuôi record or undo it (a round not yet begun cannot be taken);
  /// others are told they only read.
  Future<void> _onRound(
    BuildContext context,
    WidgetRef ref,
    NuBaby b,
    NuVitaminRound r,
    DateTime dob,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!b.coParent) {
      showClToast(context, message: l10n.nuVitaReadOnly);
      return;
    }
    if (r.state != NuRoundState.taken && r.from.isAfter(b.today)) {
      showClToast(context, message: l10n.nuVitaFuture);
      return;
    }
    final toaster = ClToaster.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final result = await showClSheet<({bool mark, DateTime? on})>(
      context: context,
      builder: (_) => _MarkSheet(round: r, dob: dob, today: b.today),
    );
    if (result == null) return;
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    ref
        .read(nutritionStoreProvider)
        .setVitaminTaken(
          b.babyId,
          r.key,
          result.mark ? nuIsoDay(result.on!) : null,
          b.uid,
          onError: failed,
        );
    toaster.show(
      message: result.mark
          ? l10n.nuVitaMarked(nuRoundTitle(l10n, locale, r.from))
          : l10n.nuVitaUnmarked,
    );
  }

  Future<void> _reminderSheet(
    BuildContext context,
    WidgetRef ref, {
    required NuBaby b,
    required NuNutrient nutrient,
    required NuVitaminRound round,
    required String title,
    required String place,
  }) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final toaster = ClToaster.of(context);
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final picked = await showClSheet<({String assignee, bool calendar})>(
      context: context,
      builder: (_) => _ReminderSheet(
        baby: b,
        me: me,
        round: round,
        nutrientName: nuText(nutrient.name, locale, b.name),
      ),
    );
    if (picked == null || !context.mounted) return;
    final time = nuVitaminReminderTime(
      round.from,
      b.now,
      (wall) => instantInZone(b.zone, wall),
    );
    if (time == null) return;
    await nuCreateReminder(
      ref,
      me: me,
      zone: b.zone,
      title: title,
      dueAt: instantInZone(b.zone, time.dueWall),
      lead: time.lead,
      assigneeUid: picked.assignee,
      onError: (_) => toaster.show(message: l10n.careSaveFailed, error: true),
    );
    if (!context.mounted) return;
    if (picked.calendar) {
      final name = nuText(nutrient.name, locale, b.name);
      try {
        await ref.read(nuShareProvider)(
          file: (
            name: '${nutrient.id}-${round.key}.ics',
            content: nuVitaminIcs(
              uid: '${nutrient.id}-${round.key}@childlife.app',
              from: round.from,
              to: round.to,
              summary: l10n.nuVitaIcsSummary(name),
              location: place,
              description: l10n.nuVitaLocalNote,
              now: DateTime.now(),
            ),
            mimeType: 'text/calendar',
          ),
          subject: l10n.nuVitaIcsSummary(name),
          origin: nuShareOrigin(context),
        );
      } on Object {
        toaster.show(message: l10n.nuShareFailed, error: true);
      }
      if (!context.mounted) return;
    }
    // A reminder that rings on this device: it may ask for notifications (8c).
    if (picked.assignee == me.uid) await maybeAskForNotifications(context, ref);
    toaster.show(message: l10n.nuVitaSetToast(nuDayMonth(time.wallFire)));
  }
}

/// A round: state mark · "Đợt tháng 6" · days and state · "Sắp tới".
class _RoundRow extends StatelessWidget {
  const _RoundRow({
    required this.round,
    required this.place,
    required this.onTap,
    super.key,
  });
  final NuVitaminRound round;
  final String place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final r = round;
    final days = l10n.nuRoundDaysLine(
      nuRoundDays(tag, r.from, r.to, year: r.state != NuRoundState.taken),
    );
    final state = switch (r.state) {
      NuRoundState.taken => l10n.nuRoundTaken(
        r.takenOn == null ? '' : nuDate(r.takenOn!),
      ),
      NuRoundState.next => place,
      NuRoundState.past => l10n.nuRoundPast,
      NuRoundState.tooYoung => l10n.nuRoundTooYoung,
      NuRoundState.tooOld => l10n.nuRoundTooOld,
      NuRoundState.later => '',
    };
    final sub = [days, if (state.isNotEmpty) state].join(' · ');
    final title = nuRoundTitle(l10n, tag, r.from);
    final Widget mark = switch (r.state) {
      NuRoundState.taken => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: cl.colors.mintDeep,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(ClIcons.check, size: 16, color: cl.colors.onMintDeep),
      ),
      // Ink on soft warm fills, also in Night care.
      NuRoundState.next => NuIconChip(
        icon: ClIcons.clock,
        fill: cl.colors.sunshineSoft,
        ink: cl.colors.ink,
      ),
      NuRoundState.tooYoung || NuRoundState.tooOld => NuIconChip(
        icon: ClIcons.cake,
        fill: cl.colors.surface2,
        ink: cl.colors.inkMuted,
      ),
      _ => NuIconChip(
        icon: ClIcons.clock,
        fill: cl.colors.surface2,
        ink: cl.colors.inkMuted,
      ),
    };
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [
        title,
        sub,
        if (r.state == NuRoundState.next) l10n.nuRoundNext,
      ].join('. '),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            mark,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: r.state == NuRoundState.past
                          ? cl.colors.inkMuted
                          : cl.colors.ink,
                    ),
                  ),
                  Text(
                    sub,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (r.state == NuRoundState.next) ...[
              const SizedBox(width: 8),
              NuTag(
                l10n.nuRoundNext,
                fill: cl.colors.sunshineSoft,
                ink: cl.colors.ink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Đánh dấu đã uống" with the date (default: the round's first day, never after today), or
/// "Bỏ đánh dấu" for a round already recorded.
class _MarkSheet extends StatefulWidget {
  const _MarkSheet({
    required this.round,
    required this.dob,
    required this.today,
  });
  final NuVitaminRound round;
  final DateTime dob;
  final DateTime today;

  @override
  State<_MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<_MarkSheet> {
  late DateTime _on = widget.round.from.isAfter(widget.today)
      ? widget.today
      : widget.round.from;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final r = widget.round;
    final taken = r.state == NuRoundState.taken;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: nuRoundTitle(l10n, tag, r.from)),
        Text(
          taken
              ? l10n.nuRoundTaken(r.takenOn == null ? '' : nuDate(r.takenOn!))
              : l10n.nuRoundDaysLine(
                  nuRoundDays(tag, r.from, r.to, year: true),
                ),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        if (taken)
          ClButton(
            key: const Key('nuVitaUnmark'),
            label: l10n.nuVitaUnmark,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(context).pop((mark: false, on: null)),
          )
        else ...[
          ClCardGroup(
            color: cl.colors.surface2,
            children: [
              ClPressable(
                key: const Key('nuVitaDate'),
                onPressed: () async {
                  final picked = await pickVxDate(
                    context,
                    initial: _on,
                    first: widget.dob,
                    last: widget.today,
                  );
                  if (picked != null) setState(() => _on = picked);
                },
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: '${l10n.nuVitaDate}: ${nuDate(_on)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s4,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      ClIcon(ClIcons.today, size: 18, color: cl.colors.ink),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Text(l10n.nuVitaDate, style: cl.text.body),
                      ),
                      Text(
                        nuDate(_on),
                        style: cl.text.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ClIcon(
                        ClIcons.chevronRight,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            key: const Key('nuVitaMark'),
            label: l10n.nuVitaMark,
            expand: true,
            onPressed: () => Navigator.of(context).pop((mark: true, on: _on)),
          ),
        ],
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

/// "Nhắc uống …" (9g sheet): when it rings, who gets it (one member, default me) and "Thêm vào
/// lịch điện thoại" (an .ics file shared after saving).
class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({
    required this.baby,
    required this.me,
    required this.round,
    required this.nutrientName,
  });
  final NuBaby baby;
  final Membership me;
  final NuVitaminRound round;
  final String nutrientName;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late String _assignee = widget.me.uid;
  bool _calendar = true;

  Future<void> _pickRecipient(List<Membership> eligible) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<String>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.nuVitaRecipient),
          ClCardGroup(
            color: sheet.cl.colors.surface2,
            children: [
              for (final m in eligible)
                ClOptionRow(
                  title: assigneeName(l10n, m, widget.me.uid),
                  subtitle: m.uid == widget.me.uid ? m.displayName : null,
                  selected: _assignee == m.uid,
                  onTap: () => Navigator.of(sheet).pop(m.uid),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
        ],
      ),
    );
    if (picked != null) setState(() => _assignee = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final b = widget.baby;
    final time = nuVitaminReminderTime(
      widget.round.from,
      b.now,
      (wall) => instantInZone(b.zone, wall),
    );
    final eligible =
        [
          for (final m
              in ref.watch(familyMembersProvider(b.babyId)).value ??
                  const <Membership>[])
            if (canBeAssignedReminders(m, b.now)) m,
        ]..sort(
          (a, c) =>
              (a.uid == widget.me.uid ? 0 : 1) -
              (c.uid == widget.me.uid ? 0 : 1),
        );
    if (eligible.every((m) => m.uid != widget.me.uid)) {
      eligible.insert(0, widget.me);
    }
    final who = eligible.where((m) => m.uid == _assignee).firstOrNull;
    final row = cl.text.body.copyWith(fontWeight: FontWeight.w500);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.nuVitaSheetTitle(widget.nutrientName)),
        if (time != null)
          Text(
            time.lead == 1440
                ? l10n.nuVitaSheetBody(nuDayMonth(time.wallFire))
                : l10n.nuVitaSheetBodySameDay(nuDayMonth(time.wallFire)),
            style: cl.text.body.copyWith(
              fontSize: 14,
              color: cl.colors.inkMuted,
            ),
          ),
        const SizedBox(height: ClSpace.s4),
        ClCardGroup(
          color: cl.colors.surface2,
          children: [
            ClPressable(
              key: const Key('nuVitaRecipient'),
              onPressed: () => _pickRecipient(eligible),
              pressedOpacity: ClPressable.surfaceOpacity,
              semanticLabel: [
                l10n.nuVitaRecipient,
                if (who != null) assigneeName(l10n, who, widget.me.uid),
              ].join(': '),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s4,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ClIcon(ClIcons.family, size: 18, color: cl.colors.ink),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.nuVitaRecipient, style: row),
                          if (who != null)
                            Text(
                              assigneeName(l10n, who, widget.me.uid),
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ClIcon(
                      ClIcons.chevronRight,
                      size: 16,
                      color: cl.colors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s4,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClIcon(ClIcons.today, size: 18, color: cl.colors.ink),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(child: Text(l10n.nuVitaCalendar, style: row)),
                    ClToggle(
                      key: const Key('nuVitaCalendar'),
                      value: _calendar,
                      semanticLabel: l10n.nuVitaCalendar,
                      onChanged: (v) => setState(() => _calendar = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          key: const Key('nuVitaSetReminder'),
          label: l10n.nuVitaRemind,
          expand: true,
          onPressed: time == null
              ? null
              : () => Navigator.of(
                  context,
                ).pop((assignee: _assignee, calendar: _calendar)),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}
