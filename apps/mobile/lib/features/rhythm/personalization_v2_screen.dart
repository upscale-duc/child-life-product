import 'dart:async';
import '../engagement/engagement_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import 'rhythm_access.dart';
import '../me/me_widgets.dart';
import 'personalization_events.dart';
import 'personalization_v2_repository.dart';
import 'rhythm_repository.dart';
import 'rhythm_models.dart';
import 'rhythm_widgets.dart';
import 'personal_day_pages.dart';
import 'personal_day_widgets.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../today/today_for_baby.dart' show ForBabyCard;

PersonalDayKey? personalKey(BuildContext context, WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  return me == null || !familyCan(me, FamilyAction.historyRead)
      ? null
      : (
          babyId: me.babyId,
          uid: me.uid,
          locale: Localizations.localeOf(context).languageCode,
        );
}

/// P-172 (audit 2026-10-21 P2 #7): only choices that change what is shown ("Người khác chăm"
/// and the handover / routine focuses changed nothing and were dropped).
const dayContexts = ['usual', 'few_minutes', 'busy'];

String contextLabel(AppLocalizations l, String value) => switch (value) {
  'few_minutes' => l.pv2FewMinutes,
  'busy' => l.pv2Busy,
  _ => l.pv2Usual,
};

/// P-172 (audit 2026-10-21 P2 #7): the server's own reason for today's pick (`reasonCodes`, or
/// WEEKLY_FOCUS when the play focus picked it). Every pick fits the baby's age, so that is the
/// fallback.
String reasonLabel(AppLocalizations l, Object? reason) => switch (reason) {
  'SELF_REPORTED_NEED' => l.pv2BecauseNeed,
  'WEEKLY_FOCUS' => l.pv2BecauseFocus,
  'PREVIOUS_HELPFUL' => l.pv2BecauseHelpful,
  'INTEREST' => l.pv2BecauseInterest,
  _ => l.pv2BecauseAge,
};

/// The same reason as an impression dimension (`appEventDims.nextActionShown`).
String reasonDim(Object? reason) => switch (reason) {
  final String r
      when const [
        'SELF_REPORTED_NEED',
        'WEEKLY_FOCUS',
        'PREVIOUS_HELPFUL',
        'INTEREST',
      ].contains(r) =>
    r,
  _ => 'AGE_CONTENT',
};

String responseLabel(AppLocalizations l, String value) => switch (value) {
  'save' => l.pv2Save,
  'unsave' => l.pv2Unsave,
  'hide' => l.pv2Hide,
  'snooze' => l.pv2Snooze,
  'dislike' => l.pv2Dislike,
  'known' => l.pv2Known,
  'exclude' => l.pv2Exclude,
  'restore' => l.pv2Restore,
  'intend' => l.pv2Intend,
  'tried' => l.pv2Tried,
  'helpful' => l.pv2Helpful,
  _ => l.pv2Unsure,
};

/// Saves [action] and says what changed in a toast, with "Hoàn tác" when the change can be taken
/// back (P-172, owner 2026-10-22: every action is acknowledged where the person is looking).
Future<bool> mutateDay(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  Map<String, Object?> action,
) async {
  final l = AppLocalizations.of(context);
  final before = ref.read(personalDayProvider(key)).value;
  try {
    // Owner, 2026-10-22: every action that calls the server shows that it is working.
    await withClProgress(context, () => updatePersonalDay(ref, key, action));
    if (context.mounted) {
      final undo = undoOf(action, before);
      showClToast(
        context,
        message: actionToast(l, action),
        actionLabel: undo == null ? null : l.pv2Undo,
        onAction: undo == null
            ? null
            : () {
                if (context.mounted) mutateDay(context, ref, key, undo);
              },
      );
    }
    return true;
  } catch (error) {
    if (ref.context.mounted) ref.invalidate(personalDayProvider(key));
    final conflict =
        error is FirebaseFunctionsException &&
        error.code == 'failed-precondition';
    if (context.mounted) {
      showClToast(
        context,
        message: conflict ? l.pv2Conflict : l.pv2Unavailable,
        error: true,
      );
    }
    return false;
  }
}

/// A sheet of options, each a plain row; returns the chosen value.
Future<String?> _optionSheet(
  BuildContext context,
  String title,
  List<(String, String)> options,
) => showClSheet<String>(
  context: context,
  builder: (sheet) => Padding(
    padding: const EdgeInsets.fromLTRB(
      ClSpace.s4,
      ClSpace.s3,
      ClSpace.s4,
      ClSpace.s6,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        ClCardGroup(
          color: sheet.cl.colors.surface2,
          children: [
            for (final (value, label) in options)
              ClListRow(
                title: label,
                onTap: () => Navigator.of(sheet).pop(value),
              ),
          ],
        ),
      ],
    ),
  ),
);

/// Common per-viewer controls for cards from any module. Baby exclusions require a co-parent.
/// Saving is the ♥ on the card; "Khôi phục" only shows while the card is put away.
Future<void> dayCardControls(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  String contentId, {
  bool parent = false,
}) async {
  final l = AppLocalizations.of(context);
  final now = ref.read(careClockProvider).value ?? DateTime.now();
  final away =
      ref.read(personalDayProvider(key)).value?.suppressed(contentId, now) ??
      false;
  final choice = await _optionSheet(context, l.pv2Controls, [
    for (final value in [
      if (!away) ...['snooze', 'hide', 'dislike', 'known'],
      if (!away && parent && contentId.startsWith('act_')) 'exclude',
      if (away) 'restore',
    ])
      (value, responseLabel(l, value)),
  ]);
  if (choice != null && context.mounted) {
    final ok = await mutateDay(context, ref, key, {
      'kind': 'respond',
      'contentId': contentId,
      'value': choice,
    });
    if (ok) personalEvent(ref, 'feedCardAnswered', choice);
  }
}

/// P-172 (audit 2026-10-21 P2 #4): the × on a Home work card puts it off for this person until
/// tonight; the reminder itself stays in Nhắc việc and on the handover screen.
Future<void> snoozeWorkCard(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  String cardId,
) async {
  final l = AppLocalizations.of(context);
  final choice = await _optionSheet(context, l.pv2Controls, [
    ('snooze', l.pv2WorkSnooze),
  ]);
  if (choice != null && context.mounted) {
    final ok = await mutateDay(context, ref, key, {
      'kind': 'respond',
      'contentId': cardId,
      'value': 'snooze',
    });
    if (ok) personalEvent(ref, 'feedCardAnswered', 'snooze');
  }
}

/// "Gợi ý hôm nay cho bé" on Home, first in "Dành cho bé hôm nay": the one idea, its next step
/// and what the person already did with it, then what they tried today and today's time.
class PersonalDayHome extends ConsumerWidget {
  const PersonalDayHome({this.primary, super.key});
  final ForBabyCard? primary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = personalKey(context, ref);
    if (key == null) return const SizedBox.shrink();
    final day = ref.watch(personalDayHomeProvider(key));
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    if (day == null || !day.current(now)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final content = ref.watch(rhythmContentProvider).value;
    final card = primary;
    final activity = card != null && card.id.startsWith('act_')
        ? content?.activity(card.id)
        : null;
    final status = card == null
        ? const <PersonalStatus>[]
        : responseStatus(l, day, card.id, locale, now);
    final canRespond = day.writable && card != null && !card.essential;
    final steps = activity != null && day.writable
        ? nextSteps(day, activity.id)
        : const <String>[];
    final stepFirst = steps.isNotEmpty && !steps.contains('intend');
    final tried = [
      for (final id in actedToday(day))
        if (id != card?.id && onDay(day, dayMap(day.responses[id])['triedAt']))
          id,
    ].take(2);
    final kicker = activity != null || card == null
        ? l.pv2HomeKicker
        : card.kicker.toUpperCase();

    return RhCard(
      key: const Key('personalDayHome'),
      outline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.heart, size: 14, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kicker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.caption.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              PersonalTextAction(
                key: const Key('personalDayMore'),
                label: l.pv2More,
                chevron: true,
                onTap: () => context.push(Routes.personalDay),
              ),
            ],
          ),
          if (card != null) ...[
            const SizedBox(height: ClSpace.s1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PersonalImpression(
                    identity:
                        '${key.uid}:${key.babyId}:${day.data['today']}:${card.id}',
                    reason: card.id.startsWith('act_')
                        ? reasonDim(day.data['reason'])
                        : switch (card.priority) {
                            0 => 'health',
                            1 => 'reminder',
                            2 => 'module',
                            3 => 'rhythm',
                            4 => 'milestone',
                            5 => 'moments',
                            _ => 'AGE_CONTENT',
                          },
                    child: Semantics(
                      header: true,
                      child: Text(
                        card.title,
                        style: cl.text.headline.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (canRespond)
                  PersonalSaveButton(dayKey: key, day: day, contentId: card.id),
                // P-172 (audit 2026-10-21 P2 #4): an essential card with its own × (a work
                // card) can still be put off; it has no save.
                if (day.writable && (canRespond || card.onDismiss != null))
                  PersonalMoreButton(
                    onPressed: () => switch (card.onDismiss) {
                      final dismiss? => dismiss(context, ref),
                      null => dayCardControls(
                        context,
                        ref,
                        key,
                        card.id,
                        parent: day.parent,
                      ),
                    },
                  ),
              ],
            ),
            if (activity != null) ...[
              const SizedBox(height: ClSpace.s1),
              Text(
                '${activity.durationMin} ${l.pv2Minutes} · ${activity.id == day.activityIds.firstOrNull ? reasonLabel(l, day.data['reason']) : l.pv2BecauseAge}',
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ],
            if (status.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s2),
              PersonalStatusChips(status),
            ],
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: pillOrder(stepFirst, [
                // Owner, 2026-10-22: once the person has planned (or tried), their next step
                // takes the primary style, so the change shows without reading the status.
                RhPillButton(
                  label: card.action,
                  primary: !stepFirst,
                  onTap: () => card.onOpen(context),
                ),
                if (steps.firstOrNull case final step?)
                  RhPillButton(
                    key: Key('personalDayStep:$step'),
                    label: step == 'helpful'
                        ? l.pv2HowWasIt
                        : responseLabel(l, step),
                    primary: stepFirst,
                    onTap: () async {
                      if (step == 'helpful') {
                        await askOutcome(context, ref, key, activity!.id);
                        return;
                      }
                      final ok = await mutateDay(context, ref, key, {
                        'kind': 'respond',
                        'contentId': activity!.id,
                        'value': step,
                      });
                      if (ok) {
                        personalEvent(ref, 'personalizationOutcome', step);
                      }
                    },
                  ),
              ]),
            ),
          ] else ...[
            const SizedBox(height: ClSpace.s2),
            Text(
              l.pv2NoIdeas,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          // What was tried today stays on the card, each with its chips and, until answered,
          // "Thấy sao?" as its own button (owner, 2026-10-22: no text squeezed beside it).
          if (tried.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s4),
            Container(height: 1, color: cl.colors.separator),
            const SizedBox(height: ClSpace.s3),
            Text(
              l.pv2DoneToday,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            for (final id in tried)
              Padding(
                padding: const EdgeInsets.only(top: ClSpace.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content?.activity(id)?.title.of(locale) ??
                                l.pv2Saved,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.label.copyWith(
                              color: cl.colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          PersonalStatusChips(
                            responseStatus(l, day, id, locale, now),
                          ),
                        ],
                      ),
                    ),
                    if (day.writable &&
                        nextSteps(day, id).firstOrNull == 'helpful') ...[
                      const SizedBox(width: ClSpace.s2),
                      RhPillButton(
                        label: l.pv2HowWasIt,
                        primary: false,
                        onTap: () => askOutcome(context, ref, key, id),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          if (day.writable) ...[
            const SizedBox(height: ClSpace.s3),
            Container(height: 1, color: cl.colors.separator),
            ClPressable(
              key: const Key('personalDayContext'),
              onPressed: () => chooseDayContext(context, ref, key, day),
              semanticLabel:
                  '${l.pv2TimeToday}: ${contextLabel(l, day.context)}',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
                child: Row(
                  children: [
                    ClIcon(ClIcons.clock, size: 16, color: cl.colors.inkMuted),
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: Text(
                        l.pv2TimeToday,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ),
                    Text(
                      contextLabel(l, day.context),
                      style: cl.text.label.copyWith(
                        color: cl.colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    ClIcon(
                      ClIcons.chevronRight,
                      size: 14,
                      color: cl.colors.inkMuted,
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
}

/// The Home card's place while today's snapshot loads: its kicker and grey lines of the same
/// height, so nothing jumps when it arrives.
class PersonalDayHomePlaceholder extends StatelessWidget {
  const PersonalDayHomePlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
    );
    return Semantics(
      label: l.pv2Loading,
      child: RhCard(
        key: const Key('personalDayHomePlaceholder'),
        outline: true,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClIcon(ClIcons.heart, size: 14, color: cl.colors.mintText),
                  const SizedBox(width: 6),
                  Text(
                    l.pv2HomeKicker,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              bar(220, 18),
              const SizedBox(height: ClSpace.s2),
              bar(160, 14),
              const SizedBox(height: ClSpace.s4),
              bar(120, ClSpace.tapMin),
              const SizedBox(height: ClSpace.s3),
              bar(double.infinity, 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// The open button first, unless the person's next step leads (then it moves to the end).
List<Widget> pillOrder(bool stepFirst, List<Widget> pills) =>
    stepFirst && pills.length > 1 ? [...pills.skip(1), pills.first] : pills;

/// B2 extends the existing Sunday summary; it never introduces another weekly notification.
/// Owner, 2026-10-22: read at a glance — the week's two numbers large, the age note short, the
/// next idea as a row, the signs to see a doctor folded behind one row.
class PersonalWeekBlock extends ConsumerWidget {
  const PersonalWeekBlock({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = personalKey(context, ref);
    if (key == null) return const SizedBox.shrink();
    final day = ref.watch(personalDayProvider(key)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    if (day == null || !day.current(now)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final content = ref.watch(rhythmContentProvider).value;
    final age = content?.ageCards
        .where((a) => a.id == day.data['ageCardId'])
        .firstOrNull;
    final weekly = dayMap(day.data['weekly']);
    final next = day.health
        ? null
        : day.activityIds.firstOrNull == null
        ? null
        : content?.activity(day.activityIds.first);
    final watchFor = age == null ? const <String>[] : age.watchFor.of(locale);
    Widget stat(int n, String label, Color fill, Color ink) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(ClRadius.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClTabularText(
              '$n',
              style: cl.text.title2.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: cl.text.caption.copyWith(color: ink)),
          ],
        ),
      ),
    );
    return RhCard(
      key: const Key('personalWeek'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.pv2Weekly, style: cl.text.headline),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              stat(
                (weekly['tried'] as num? ?? 0).toInt(),
                l.pv2WeekTriedShort,
                cl.colors.mintSoft,
                cl.colors.mintText,
              ),
              const SizedBox(width: ClSpace.s2),
              stat(
                (weekly['helpful'] as num? ?? 0).toInt(),
                l.pv2WeekHelpfulShort,
                cl.colors.mintDeep,
                cl.colors.onMintDeep,
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l.pv2WeekHint,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
          if (age != null) ...[
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.pv2AgeNow,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstSentenceOf(age.body.of(locale)),
                    style: cl.text.label.copyWith(color: cl.colors.ink),
                  ),
                ],
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: ClSpace.s2),
            MeRow(
              icon: ClIcons.spark,
              title: next.title.of(locale),
              subtitle: l.pv2NextIdea,
              onTap: () => context.push('${Routes.rhythmActivity}/${next.id}'),
            ),
          ],
          if (watchFor.isNotEmpty)
            MeRow(
              key: const Key('personalWeekWatch'),
              icon: ClIcons.alert,
              iconTint: cl.colors.peachSoft,
              title: l.pv2WatchFor,
              subtitle: l.pv2WatchForCount(watchFor.length),
              onTap: () => showClSheet<void>(
                context: context,
                builder: (sheet) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s3,
                    ClSpace.s4,
                    ClSpace.s6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClSheetHeader(title: l.pv2WatchFor),
                      RhBullets(watchFor),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l.pv2Open,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => context.push(Routes.personalDay),
          ),
        ],
      ),
    );
  }
}

/// The first sentence of an age card's text.
String firstSentenceOf(String text) {
  final t = text.trim();
  final end = RegExp(r'[.!?…](?=\s)').firstMatch(t);
  return end == null ? t : t.substring(0, end.end);
}

/// "Hôm nay của nhà mình": today's ideas first, then what the person did today, then the
/// settings for today; handover, rhythm, notebook and history are pages of their own.
class PersonalizationDayScreen extends StatelessWidget {
  const PersonalizationDayScreen({super.key});
  @override
  Widget build(BuildContext context) => PersonalDayPage(
    title: (l) => l.pv2Title,
    onShown: (ref, key, day) =>
        engagementContentViewed(ref, key.babyId, 'personal_day', key.babyId),
    builder: _dayChildren,
  );
}

List<Widget> _dayChildren(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  PersonalDay day,
  PersonalDayWrite write,
  bool busy,
) {
  final l = AppLocalizations.of(context);
  final cl = context.cl;
  final locale = Localizations.localeOf(context);
  final content = ref.watch(rhythmContentProvider).value;
  final ideas = [
    if (!day.health && day.data['contentVersion'] == content?.version)
      for (final id in day.activityIds)
        if (content?.activity(id) case final a?
            when a.status == ContentStatus.published)
          a,
  ];
  final shown = {for (final a in ideas) a.id};
  final done = actedToday(day).where((id) => !shown.contains(id)).toList();
  final weekly = dayMap(day.data['weekly']);
  final firstPattern = day.patterns.firstOrNull;
  final caption = cl.text.caption.copyWith(color: cl.colors.inkMuted);
  return [
    if (day.health)
      ClButton(
        label: l.rhHealthCardAction,
        expand: true,
        onPressed: () => context.push(Routes.rhythmHealth),
      )
    else ...[
      PersonalHeading(
        l.pv2Next,
        sub: day.context == 'usual'
            ? null
            : '${contextLabel(l, day.context)}: ${contextHint(l, day.context)}',
      ),
      for (final (i, activity) in ideas.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: ClSpace.s3),
          child: PersonalImpression(
            identity:
                '${key.uid}:${key.babyId}:${day.data['today']}:${activity.id}',
            reason: reasonDim(day.data['reason']),
            child: _IdeaCard(
              dayKey: key,
              day: day,
              activity: activity,
              first: i == 0,
              write: write,
            ),
          ),
        ),
      if (ideas.isEmpty) ...[
        Text(
          l.pv2NoIdeas,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        if (day.data['ageCardId'] != null)
          RhLink(
            label: l.rhWeekTitle,
            start: true,
            onTap: () =>
                context.push('${Routes.rhythmAge}/${day.data['ageCardId']}'),
          ),
      ],
      Text(l.pv2NoAnswer, style: caption),
    ],
    PersonalHeading(l.pv2DoneToday),
    if (done.isEmpty)
      Text(l.pv2DoneTodayEmpty, style: caption)
    else
      ClCardGroup(
        children: [
          for (final id in done.take(8))
            _DoneRow(dayKey: key, day: day, id: id, write: write),
        ],
      ),
    if (day.writable) ...[
      PersonalHeading(l.pv2Adjust),
      Text(l.pv2Context, style: cl.text.bodyStrong),
      const SizedBox(height: ClSpace.s2),
      DayContextOptions(
        selected: day.context,
        onSelect: busy
            ? null
            : (value) => write({'kind': 'context', 'value': value}),
      ),
      const SizedBox(height: ClSpace.s1),
      Text(l.pv2Temporary, style: caption),
      const SizedBox(height: ClSpace.s3),
      ClCardGroup(
        children: [
          MeRow(
            title: l.pv2FocusToggle,
            subtitle: l.pv2FocusHint,
            trailing: ClToggle(
              key: const Key('personalDayFocus'),
              semanticLabel: l.pv2FocusToggle,
              value: day.data['focus'] == 'play',
              onChanged: busy
                  ? null
                  : (on) =>
                        write({'kind': 'focus', 'value': on ? 'play' : null}),
            ),
          ),
        ],
      ),
    ],
    const SizedBox(height: ClSpace.s6),
    ClCardGroup(
      children: [
        MeRow(
          key: const Key('personalDayHandover'),
          icon: ClIcons.family,
          title: l.pv2Work,
          subtitle: day.work.isNotEmpty
              ? l.pv2WorkCount(day.work.length)
              : day.data['acknowledgedAt'] != null &&
                    day.data['handoverChanged'] != true
              ? '${l.pv2AcknowledgedShort} · ${dayStamp(day, day.data['acknowledgedAt'], locale)}'
              : l.pv2NoWork,
          onTap: () => context.push(Routes.personalDayHandover),
        ),
        MeRow(
          key: const Key('personalDayPatterns'),
          icon: ClIcons.clock,
          title: l.pv2Patterns,
          subtitle: day.data['unusual'] == true
              ? l.pv2PatternsPaused
              : firstPattern == null
              ? l.pv2PatternsNone
              : '${patternLabel(l, firstPattern)}: ${firstPattern['lowMinutes']}–${firstPattern['highMinutes']} ${l.pv2Minutes}',
          onTap: () => context.push(Routes.personalDayPatterns),
        ),
        MeRow(
          key: const Key('personalDayNotes'),
          icon: ClIcons.journal,
          title: l.pv2Notes,
          subtitle: l.pv2NotesCount(day.notes.length),
          onTap: () => context.push(Routes.personalDayNotes),
        ),
        MeRow(
          key: const Key('personalDayHistory'),
          icon: ClIcons.heart,
          title: l.pv2History,
          subtitle: l.pv2WeekLine(
            (weekly['tried'] as num? ?? 0).toInt(),
            (weekly['helpful'] as num? ?? 0).toInt(),
          ),
          onTap: () => context.push(Routes.personalDayHistory),
        ),
      ],
    ),
  ];
}

String patternLabel(AppLocalizations l, Map<String, dynamic> pattern) =>
    pattern['kind'] == 'feed_interval' ? l.pv2FeedPattern : l.pv2SleepPattern;

/// One idea on the screen: what it is, why, what the person already did, the next step.
class _IdeaCard extends ConsumerWidget {
  const _IdeaCard({
    required this.dayKey,
    required this.day,
    required this.activity,
    required this.first,
    required this.write,
  });
  final PersonalDayKey dayKey;
  final PersonalDay day;
  final Activity activity;
  final bool first;
  final PersonalDayWrite write;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final id = activity.id;
    final status = responseStatus(l, day, id, locale, now);
    final steps = day.writable ? nextSteps(day, id) : const <String>[];
    // A plan made (or an attempt): the next step is the primary button (owner, 2026-10-22).
    final stepFirst = steps.isNotEmpty && !steps.contains('intend');
    return RhCard(
      key: Key('personalIdea:$id'),
      outline: first,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${activity.durationMin} ${l.pv2Minutes}',
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              if (day.writable) ...[
                PersonalSaveButton(dayKey: dayKey, day: day, contentId: id),
                PersonalMoreButton(
                  onPressed: () => dayCardControls(
                    context,
                    ref,
                    dayKey,
                    id,
                    parent: day.parent,
                  ),
                ),
              ],
            ],
          ),
          Semantics(
            header: true,
            child: Text(
              activity.title.of(locale),
              style: cl.text.headline.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (first) ...[
            const SizedBox(height: ClSpace.s1),
            Text(
              reasonLabel(l, day.data['reason']),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          if (status.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s2),
            PersonalStatusChips(status),
          ],
          const SizedBox(height: ClSpace.s3),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: pillOrder(stepFirst, [
              RhPillButton(
                label: l.pv2OpenActivity,
                primary: !stepFirst,
                onTap: () => context.push('${Routes.rhythmActivity}/$id'),
              ),
              for (final step in steps)
                RhPillButton(
                  key: Key('personalStep:$id:$step'),
                  label: responseLabel(l, step),
                  primary: stepFirst && step == steps.first,
                  onTap: () async {
                    final ok = await write({
                      'kind': 'respond',
                      'contentId': id,
                      'value': step,
                    });
                    if (ok) {
                      personalEvent(ref, 'personalizationOutcome', step);
                    }
                  },
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// A row of "Hôm nay bạn đã": the idea, what was done, and the one follow-up it still needs.
class _DoneRow extends ConsumerWidget {
  const _DoneRow({
    required this.dayKey,
    required this.day,
    required this.id,
    required this.write,
  });
  final PersonalDayKey dayKey;
  final PersonalDay day;
  final String id;
  final PersonalDayWrite write;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final activity = ref.watch(rhythmContentProvider).value?.activity(id);
    final value = dayMap(day.responses[id])['value'];
    final away = day.suppressed(id, now);
    return PersonalIdeaRow(
      key: Key('personalDone:$id'),
      title: activity?.title.of(locale) ?? l.pv2Saved,
      status: responseStatus(l, day, id, locale, now),
      onTap: activity == null
          ? null
          : () => context.push('${Routes.rhythmActivity}/$id'),
      trailing: !day.writable
          ? null
          : nextSteps(day, id).firstOrNull == 'helpful'
          ? PersonalTextAction(
              label: l.pv2HowWasIt,
              onTap: () => askOutcome(context, ref, dayKey, id),
            )
          : away && !['tried', 'helpful', 'exclude'].contains(value)
          ? PersonalTextAction(
              label: l.pv2Restore,
              onTap: () => write({
                'kind': 'respond',
                'contentId': id,
                'value': 'restore',
              }),
            )
          : null,
    );
  }
}

Future<void> showNotebookEditor(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  bool parent, {
  Map<String, dynamic>? note,
}) async {
  final action = await showModalBottomSheet<Map<String, Object?>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NotebookEditor(
      parent: parent,
      note: note,
      activities: ref.read(rhythmContentProvider).value?.activities ?? const [],
    ),
  );
  if (action != null && context.mounted) {
    await mutateDay(context, ref, key, action);
  }
}

class _NotebookEditor extends StatefulWidget {
  const _NotebookEditor({
    required this.parent,
    this.note,
    this.activities = const [],
  });
  final List<Activity> activities;
  final bool parent;
  final Map<String, dynamic>? note;
  @override
  State<_NotebookEditor> createState() => _NotebookEditorState();
}

class _NotebookEditorState extends State<_NotebookEditor> {
  late final _text = TextEditingController(
    text: widget.note?['text'] as String? ?? '',
  );
  late String _category = widget.note?['category'] as String? ?? 'other';
  late bool _shared = widget.note?['scope'] != 'person';
  int? _days = 7;
  late String? _avoidActivityId = widget.note?['avoidActivityId'] as String?;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    // One rhythm for the whole sheet (owner, 2026-10-22): a caption over every group and the
    // same gap between groups; choices are the app's pill chips.
    Widget group(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: ClSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: cl.text.label.copyWith(
              color: cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          child,
        ],
      ),
    );
    Widget chips<T>(
      List<(T, String)> options,
      T selected,
      ValueChanged<T> on,
    ) => Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final (value, label) in options)
          ClFilterChip(
            label: label,
            selected: selected == value,
            onTap: () => on(value),
          ),
      ],
    );
    final avoidLocked = !widget.parent && _category == 'avoid';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          MediaQuery.viewInsetsOf(context).bottom + ClSpace.s4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l.pv2Notes),
              ClTextField(
                label: l.pv2NoteText,
                controller: _text,
                maxLength: 200,
                maxLines: 4,
                standalone: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              group(
                l.pv2Category,
                chips(
                  [
                    ('sleep', l.pv2Sleep),
                    ('soothing', l.pv2Soothing),
                    ('feeding', l.pv2Feeding),
                    ('avoid', l.pv2Avoid),
                    ('routine', l.pv2Routine),
                    ('carer', l.pv2Carer),
                    ('other', l.pv2Other),
                  ],
                  _category,
                  (value) => setState(() {
                    _category = value;
                    if (!widget.parent && _category == 'avoid') _shared = false;
                  }),
                ),
              ),
              if (_category == 'avoid' && _shared && widget.parent)
                group(
                  l.pv2AvoidActivity,
                  DropdownButtonFormField<String>(
                    initialValue:
                        widget.activities.any((a) => a.id == _avoidActivityId)
                        ? _avoidActivityId
                        : null,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(l.pv2NoFocus),
                      ),
                      for (final a in widget.activities.where(
                        (a) => a.status == ContentStatus.published,
                      ))
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            a.title.of(Localizations.localeOf(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _avoidActivityId = value),
                  ),
                ),
              group(
                l.pv2Expiry,
                chips<int?>(
                  [
                    (1, l.pv2OneDay),
                    (7, l.pv2SevenDays),
                    (30, l.pv2ThirtyDays),
                    (null, l.pv2NoExpiry),
                  ],
                  _days,
                  (value) => setState(() => _days = value),
                ),
              ),
              const SizedBox(height: ClSpace.s6),
              ClCardGroup(
                color: cl.colors.surface2,
                children: [
                  MeRow(
                    title: l.pv2Shared,
                    trailing: ClToggle(
                      semanticLabel: l.pv2Shared,
                      value: _shared,
                      onChanged: avoidLocked
                          ? null
                          : (value) => setState(() => _shared = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s6),
              ClButton(
                label: l.pv2ConfirmNote,
                expand: true,
                onPressed:
                    _text.text.trim().isEmpty ||
                        !widget.parent && _shared && _category == 'avoid'
                    ? null
                    : () => Navigator.of(context).pop({
                        'kind': 'note',
                        'id':
                            widget.note?['id'] ??
                            'nb_${const Uuid().v4().replaceAll('-', '')}',
                        'revision': widget.note?['revision'] ?? 0,
                        'text': _text.text.trim(),
                        'category': _category,
                        'scope': _shared ? 'baby' : 'person',
                        'days': _days,
                        'avoidActivityId': _category == 'avoid' && _shared
                            ? _avoidActivityId
                            : null,
                        'source': widget.note?['source'] ?? 'app',
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
