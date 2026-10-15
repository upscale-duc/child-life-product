import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/time_zones.dart' show ensureTimeZones;
import '../family/family_repository.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';

/// D-076 #10: "Thử tối nay" / "Thử hôm nay" / "Mình sẽ thử" is a plan (feedback kind `started`,
/// an intention, never "đã thử"). It waits ("Đã lên kế hoạch · tối nay", "Bỏ kế hoạch") until
/// there was a chance to try, then asks for the result with "Chưa thử" next to it. The timing is
/// the assistant's CH17 rule (`feedbackOpensAt` in firebase/functions/src/assistant-care.ts), so a
/// plan made in the chat and one made here open at the same moment.

/// [hour]:00 on [date] in [zone].
DateTime localInstantIn(String zone, String date, int hour) {
  final p = date.split('-').map(int.parse).toList();
  ensureTimeZones();
  try {
    return tz.TZDateTime(tz.getLocation(zone), p[0], p[1], p[2], hour).toUtc();
  } on Object {
    return DateTime.utc(p[0], p[1], p[2], hour);
  }
}

/// When a plan made on [plannedFor] (baby-local) at [plannedAt] may be asked about: an evening
/// or any-time item the next local morning at 05:00; a daytime item the same day at 18:00 when
/// planned before then, else the next morning (server `feedbackOpensAt`).
DateTime planFeedbackOpensAt({
  required String zone,
  required String plannedFor,
  required ActivityTime timeOfDay,
  required DateTime plannedAt,
}) {
  final nextMorning = localInstantIn(zone, addDaysIso(plannedFor, 1), 5);
  if (timeOfDay != ActivityTime.day) return nextMorning;
  final evening = localInstantIn(zone, plannedFor, 18);
  return plannedAt.isBefore(evening) ? evening : nextMorning;
}

/// An open plan: the newest row about an activity is a `started` not set aside on this phone.
@immutable
class ActivityPlan {
  const ActivityPlan({
    required this.started,
    required this.opensAt,
    required this.due,
  });

  final RecFeedback started;

  /// From when the result is asked.
  final DateTime opensAt;

  /// The chance to try has passed: "Kể lại kết quả" and "Chưa thử".
  final bool due;

  bool mine(String uid) => started.authorUid == uid;
}

ActivityPlan planFrom(
  RecFeedback started, {
  required String zone,
  required ActivityTime timeOfDay,
  required DateTime now,
}) {
  // A row still on its way has no server time: made now when it is about today, else (an
  // offline plan of an earlier day) taken as made at noon that day.
  final plannedAt =
      started.createdAt ??
      (started.date == localDateIn(zone, now)
          ? now
          : localInstantIn(zone, started.date, 12));
  final opensAt = planFeedbackOpensAt(
    zone: zone,
    plannedFor: started.date,
    timeOfDay: timeOfDay,
    plannedAt: plannedAt,
  );
  return ActivityPlan(
    started: started,
    opensAt: opensAt,
    due: !now.isBefore(opensAt),
  );
}

/// The open plan on [contentId] in [rows] (newest first), or null; [setAside]: plans this person
/// answered "Chưa thử" on this phone (someone else's, which only its author may delete).
ActivityPlan? openPlan(
  List<RecFeedback> rows,
  String contentId, {
  required String zone,
  required ActivityTime timeOfDay,
  required DateTime now,
  Set<String> setAside = const {},
}) {
  final last = rows.where((r) => r.contentId == contentId).firstOrNull;
  if (last == null ||
      last.kind != FeedbackKind.started ||
      setAside.contains(last.id)) {
    return null;
  }
  return planFrom(last, zone: zone, timeOfDay: timeOfDay, now: now);
}

// ---------- "Chưa thử" on someone else's plan (this phone, this person) ----------

/// Keyed by `uid|babyId`: ids of `started` rows this person answered "Chưa thử" to.
final plansSetAsideProvider =
    NotifierProvider.family<PlansSetAsideNotifier, Set<String>, String>(
      PlansSetAsideNotifier.new,
    );

class PlansSetAsideNotifier extends Notifier<Set<String>> {
  PlansSetAsideNotifier(this.key);
  final String key;

  String get _key => 'rhythm.plansSetAside.$key';

  @override
  Set<String> build() {
    try {
      return {...?ref.read(sharedPreferencesProvider).getStringList(_key)};
    } on Object {
      return const {};
    }
  }

  void add(String id) {
    // The newest 50 are plenty: older plans are out of the 60-day window anyway.
    final next = [...state, id];
    state = {...next.skip(next.length > 50 ? next.length - 50 : 0)};
    try {
      ref
          .read(sharedPreferencesProvider)
          .setStringList(_key, state.toList())
          .ignore();
    } on Object {
      // No preferences (tests): set aside for this run.
    }
  }
}

String setAsideKey(Membership me) => '${me.uid}|${me.babyId}';

/// "Bỏ kế hoạch" (my plan, before the chance) or "Chưa thử" ([notTried], any time after): my
/// own plan is taken back (its row deleted; the Rules let only the author do it), so the idea can
/// be planned again; someone else's is only set aside for me on this phone.
void withdrawPlan(
  BuildContext context,
  WidgetRef ref,
  Membership me,
  ActivityPlan plan, {
  required bool notTried,
}) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  if (plan.mine(me.uid)) {
    final repo = ref.read(rhythmRepositoryProvider);
    repo.deleteFeedback(
      me.babyId,
      plan.started.id,
      onError: (_) => toaster.show(message: l10n.rhSaveFailed, error: true),
    );
    final container = ProviderScope.containerOf(context, listen: false);
    container.invalidate(homeCompositionProvider);
    repo
        .committed(plan.started.id)
        ?.then(
          (_) => container.invalidate(homeCompositionProvider),
          onError: (Object _) {},
        );
  } else {
    ref
        .read(plansSetAsideProvider(setAsideKey(me)).notifier)
        .add(plan.started.id);
  }
  toaster.show(message: notTried ? l10n.rhDidNotTryToast : l10n.rhPlanCanceled);
}

// ---------- Labels ----------

/// "tối 08/10" for an evening item, "08/10" otherwise.
String planDayLabel(
  AppLocalizations l10n,
  Locale locale,
  String date,
  ActivityTime timeOfDay,
) {
  final day = shortDay(locale, date);
  return timeOfDay == ActivityTime.evening ? l10n.rhEveningDate(day) : day;
}

/// "Đã lên kế hoạch · tối nay" / "· hôm nay" for a plan of [today], else "· tối 08/10".
String planStatusLabel(
  AppLocalizations l10n,
  Locale locale,
  ActivityPlan plan,
  ActivityTime timeOfDay, {
  required String today,
}) {
  if (plan.started.date == today) {
    return timeOfDay == ActivityTime.evening
        ? l10n.rhPlannedTonight
        : l10n.rhPlannedToday;
  }
  return l10n.rhPlannedOn(
    planDayLabel(l10n, locale, plan.started.date, timeOfDay),
  );
}

/// The waiting note: "Từ 18:00 hôm nay…" when the question opens today, else "Sáng mai…".
String planAskNote(
  AppLocalizations l10n,
  ActivityPlan plan, {
  required String zone,
  required String today,
}) => localDateIn(zone, plan.opensAt) == today
    ? l10n.rhPlanAskEvening
    : l10n.rhPlanAskMorning;

/// The plan's status for H02, AC01 and AC02: a check, "Đã lên kế hoạch · tối nay", who planned it
/// (when it was someone else) and, while waiting, when the result is asked.
class PlanStatus extends ConsumerWidget {
  const PlanStatus({
    required this.me,
    required this.plan,
    required this.timeOfDay,
    required this.today,
    required this.zone,
    super.key,
  });

  final Membership me;
  final ActivityPlan plan;
  final ActivityTime timeOfDay;
  final String today;
  final String zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final status = planStatusLabel(l10n, locale, plan, timeOfDay, today: today);
    final by = plan.mine(me.uid)
        ? null
        : l10n.rhPlannedBy(
            capitalized(
              memberLabel(
                l10n,
                members
                    .where((m) => m.uid == plan.started.authorUid)
                    .firstOrNull,
                myUid: me.uid,
                uid: plan.started.authorUid,
              ),
            ),
            planDayLabel(l10n, locale, plan.started.date, timeOfDay),
          );
    return MergeSemantics(
      child: Row(
        key: const ValueKey('rh.planStatus'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: cl.text.label.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (by != null)
                  Text(
                    by,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                if (!plan.due)
                  Text(
                    planAskNote(l10n, plan, zone: zone, today: today),
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

// ---------- History ("Các cách đã thử") ----------

/// One try: a plan and the answers given after it (by anyone), or an answer without a plan.
@immutable
class TriedEntry {
  const TriedEntry({
    required this.contentId,
    this.plan,
    this.answers = const [],
  });

  final String contentId;

  /// The `started` row ("Thử tối nay"), when there was one.
  final RecFeedback? plan;

  /// Có ích / Chưa rõ / Không phù hợp, oldest first.
  final List<RecFeedback> answers;

  RecFeedback get latest => answers.isEmpty ? plan! : answers.last;

  TriedEntry withAnswer(RecFeedback a) =>
      TriedEntry(contentId: contentId, plan: plan, answers: [...answers, a]);
}

/// The family's tries from [rows] (any order), newest first: each `started` opens one, the
/// answers after it join it until the next plan of the same activity; an answer with no plan
/// before it is its own entry. "Không phải hôm nay" / "Gợi ý khác" are not tries.
List<TriedEntry> triedEntries(List<RecFeedback> rows) {
  final oldestFirst = newestFirst(rows).reversed;
  final entries = <TriedEntry>[];
  final open = <String, int>{}; // contentId → index of its plan's entry
  for (final r in oldestFirst) {
    switch (r.kind) {
      case FeedbackKind.notToday:
        continue;
      case FeedbackKind.started:
        open[r.contentId] = entries.length;
        entries.add(TriedEntry(contentId: r.contentId, plan: r));
      case FeedbackKind.helpful ||
          FeedbackKind.unsure ||
          FeedbackKind.notSuitable:
        final i = open[r.contentId];
        if (i != null) {
          entries[i] = entries[i].withAnswer(r);
        } else {
          entries.add(TriedEntry(contentId: r.contentId, answers: [r]));
        }
    }
  }
  int order(TriedEntry a, TriedEntry b) {
    final x = a.latest, y = b.latest;
    final d = y.date.compareTo(x.date);
    if (d != 0) return d;
    return (y.createdAt ?? DateTime(9999)).compareTo(
      x.createdAt ?? DateTime(9999),
    );
  }

  return entries..sort(order);
}
