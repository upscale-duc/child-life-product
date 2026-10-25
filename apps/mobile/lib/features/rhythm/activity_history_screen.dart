import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart' show babyProvider;
import '../family/family_repository.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_plans.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// One try: the activity, who planned it and when, each answer (who, when, what, the note), and
/// what can still be done with it.
class TriedEntryCard extends ConsumerWidget {
  const TriedEntryCard({
    required this.me,
    required this.entry,
    required this.entries,
    this.compact = false,
    super.key,
  });

  final Membership me;
  final TriedEntry entry;

  /// All entries (an older plan of an activity planned again since is closed, not answerable).
  final List<TriedEntry> entries;

  /// A row inside NL01's "Cách nhà mình đã thử" (no actions, no notes).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final content = ref.watch(rhythmContentProvider).value;
    final activity = content?.activity(entry.contentId);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = rhythmNow(ref);
    final today = babyTodayIso(zone, now);
    final setAside = ref.watch(plansSetAsideProvider(setAsideKey(me)));
    final canAct = familyCan(me, FamilyAction.rhythmFeedback);
    final time = activity?.timeOfDay ?? ActivityTime.any;
    String who(String uid, {bool start = true}) {
      final label = memberLabel(
        l10n,
        members.where((m) => m.uid == uid).firstOrNull,
        myUid: me.uid,
        uid: uid,
        sentenceStart: start,
      );
      return start ? capitalized(label) : label;
    }

    final started = entry.plan;
    // Only the newest plan of an activity is still open; an older one was overtaken.
    final newest = entries
        .where((e) => e.contentId == entry.contentId && e.plan != null)
        .firstOrNull;
    final open =
        started != null &&
        entry.answers.isEmpty &&
        identical(newest, entry) &&
        !setAside.contains(started.id);
    final plan = open
        ? planFrom(started, zone: zone, timeOfDay: time, now: now)
        : null;

    final (String pill, bool mint) = switch (entry.answers.lastOrNull) {
      final a? => (
        feedbackKindLabel(l10n, a.kind),
        a.kind == FeedbackKind.helpful,
      ),
      // Past its chance it asks for the result (the buttons below say so).
      null when plan != null => (l10n.rhPlannedPill, !plan.due),
      null => (l10n.rhNotTried, false),
    };
    final title = activity?.title.of(locale) ?? l10n.rhUnknownActivity;

    final lines = <Widget>[
      if (started != null)
        Text(
          l10n.rhPlannedBy(
            who(started.authorUid),
            planDayLabel(l10n, locale, started.date, time),
          ),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      for (final a in entry.answers) ...[
        Text(
          '${l10n.rhWhoDay(who(a.authorUid), shortDay(locale, a.date))} · ${feedbackKindLabel(l10n, a.kind)}',
          style: cl.text.caption.copyWith(color: cl.colors.ink),
        ),
        if (!compact && a.note != null)
          Text(
            l10n.rhQuoted(a.note!),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
      ],
      if (!compact && plan != null && !plan.due)
        Text(
          planAskNote(l10n, plan, zone: zone, today: today),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
    ];

    final head = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          RhIconTile(icon: activityIcon(activity), size: 36),
          const SizedBox(width: ClSpace.s3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: cl.text.label.copyWith(
                  color: cl.colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // On the card the status sits under the title, which keeps its width.
              if (!compact) ...[
                const SizedBox(height: ClSpace.s1),
                RhPill(label: pill, mint: mint),
                const SizedBox(height: ClSpace.s1),
              ] else
                const SizedBox(height: 2),
              ...lines,
            ],
          ),
        ),
        if (compact) ...[
          const SizedBox(width: ClSpace.s2),
          RhPill(label: pill, mint: mint),
        ],
      ],
    );

    final openActivity = activity == null
        ? null
        : () => context.push(activityLocation(activity.id));
    if (compact) {
      return openActivity == null
          ? MergeSemantics(child: head)
          : ClPressable(
              onPressed: openActivity,
              pressedOpacity: ClPressable.surfaceOpacity,
              semanticLabel: '$title, $pill',
              child: head,
            );
    }
    final actions = <Widget>[
      if (canAct && plan != null && activity != null) ...[
        if (plan.due) ...[
          RhPillButton(
            label: l10n.rhTellHow,
            onTap: () => context.push(activityFeedbackLocation(activity.id)),
          ),
          RhPillButton(
            label: l10n.rhDidNotTry,
            primary: false,
            onTap: () => withdrawPlan(context, ref, me, plan, notTried: true),
          ),
        ] else if (plan.mine(me.uid))
          RhPillButton(
            label: l10n.rhCancelPlan,
            primary: false,
            onTap: () => withdrawPlan(context, ref, me, plan, notTried: false),
          ),
      ],
    ];
    return RhCard(
      onTap: openActivity,
      semanticLabel: '$title, $pill',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Xem tất cả" → "Các cách đã thử" (NL01, EN09).
class TriedHistoryLink extends StatelessWidget {
  const TriedHistoryLink({super.key});

  @override
  Widget build(BuildContext context) => RhLink(
    label: AppLocalizations.of(context).rhSeeAllTried,
    start: true,
    onTap: () => context.push(Routes.rhythmTried),
  );
}
