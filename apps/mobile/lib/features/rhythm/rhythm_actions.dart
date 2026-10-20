import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show careClockProvider;
import 'rhythm_access.dart';
import 'personalization_events.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';

/// What the screens write and where they go next. Writes never wait for the server (offline
/// works); Home's `composeHome` is asked again once the write has landed.

/// Keeps the clock and the baby (time zone) loaded on a screen that writes, so [rhythmNow] and
/// [rhythmToday] read them in callbacks.
void watchRhythmClock(WidgetRef ref, String babyId) {
  ref.watch(careClockProvider);
  ref.watch(babyProvider(babyId));
}

/// "Now" for check-ins and feedback: the care clock (tests pin it).
DateTime rhythmNow(WidgetRef ref) =>
    ref.read(careClockProvider).value ?? DateTime.now();

String _zone(WidgetRef ref, String babyId) =>
    ref.read(babyProvider(babyId)).value?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';

/// The baby-local date of today for [babyId].
String rhythmToday(WidgetRef ref, String babyId) =>
    babyTodayIso(_zone(ref, babyId), rhythmNow(ref));

/// A new check-in draft by [me] about today; its id follows the "one per author per observation
/// per day" rule.
CheckIn newCheckIn(WidgetRef ref, Membership me, Observation observation) {
  final date = rhythmToday(ref, me.babyId);
  return CheckIn(
    id: checkInIdFor(
      babyId: me.babyId,
      uid: me.uid,
      date: date,
      observation: observation,
    ),
    babyId: me.babyId,
    date: date,
    authorUid: me.uid,
    observation: observation,
  );
}

void _refreshHomeAfter(BuildContext context, RhythmRepository repo, String id) {
  final container = ProviderScope.containerOf(context, listen: false);
  container.invalidate(homeCompositionProvider);
  repo
      .committed(id)
      ?.then(
        (_) => container.invalidate(homeCompositionProvider),
        onError: (Object _) {},
      );
}

/// Saves [draft] (an edit when the same id is already stored) and returns what was written.
CheckIn saveCheckIn(BuildContext context, WidgetRef ref, CheckIn draft) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final repo = ref.read(rhythmRepositoryProvider);
  final previous = ref
      .read(checkInsProvider(draft.babyId))
      .value
      ?.where((c) => c.id == draft.id)
      .firstOrNull;
  final saved = repo.saveCheckIn(
    draft,
    previous: previous,
    onError: (_) => toaster.show(message: l10n.rhSaveFailed, error: true),
  );
  final sink = ref.read(personalizationEventSinkProvider);
  repo
      .committed(saved.id)
      ?.then(
        (_) => sink('checkinSaved', null).ignore(),
        onError: (Object _) {},
      );
  _refreshHomeAfter(context, repo, saved.id);
  return saved;
}

/// Writes one feedback row by [me] about [contentId] (AC01, AC02, H02, PS01, PS02).
RecFeedback giveFeedback(
  BuildContext context,
  WidgetRef ref, {
  required Membership me,
  required String contentId,
  required int contentVersion,
  required FeedbackKind kind,
  String? note,
}) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final repo = ref.read(rhythmRepositoryProvider);
  final trimmed = note?.trim();
  final feedback = repo.saveFeedback(
    RecFeedback(
      id: newFeedbackId(),
      babyId: me.babyId,
      authorUid: me.uid,
      contentId: contentId,
      contentVersion: contentVersion,
      kind: kind,
      date: rhythmToday(ref, me.babyId),
      note: trimmed == null || trimmed.isEmpty
          ? null
          : trimmed.substring(
              0,
              trimmed.length.clamp(0, RecFeedback.noteMaxLength),
            ),
    ),
    onError: (_) => toaster.show(message: l10n.rhSaveFailed, error: true),
  );
  final sink = ref.read(personalizationEventSinkProvider);
  repo.committed(feedback.id)?.then((_) {
    sink('feedbackSaved', kind.wire).ignore();
    if (kind == FeedbackKind.started) sink('suggestionStarted', null).ignore();
  }, onError: (Object _) {});
  _refreshHomeAfter(context, repo, feedback.id);
  return feedback;
}

/// [giveFeedback] for an [Activity].
void giveFeedbackOn(
  BuildContext context,
  WidgetRef ref,
  Membership me, {
  required FeedbackKind kind,
  required Activity activity,
  String? note,
}) => giveFeedback(
  context,
  ref,
  me: me,
  contentId: activity.id,
  contentVersion: activity.version,
  kind: kind,
  note: note,
);

/// Close / back on a Nhịp lớn lên screen; opened from a link with nothing below, goes to
/// Hôm nay.
void leaveRhythm(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(Routes.today);
  }
}

/// Leaves the check-in flow: back to where it started (Today), then [then] if given.
void closeFlow(BuildContext context, {String? then, Object? extra}) {
  final router = GoRouter.of(context);
  while (router.canPop()) {
    router.pop();
  }
  if (then != null) router.push(then, extra: extra);
}

/// After C02 / NL05b / "Như mọi ngày": save, then HL01 (any "Có"), a quiet toast ("Như mọi
/// ngày") or the result (PS01 / PS01F).
void finishCheckIn(BuildContext context, WidgetRef ref, CheckIn draft) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final saved = saveCheckIn(context, ref, draft);
  if (saved.needsHealthSupport) {
    closeFlow(context, then: healthLocation(saved.healthSigns));
  } else if (saved.observation == Observation.usual ||
      saved.observation == Observation.health) {
    // A usual day, or a health worry without any "Có": saved quietly, nothing to suggest.
    closeFlow(context);
    toaster.show(
      message: saved.observation == Observation.usual
          ? l10n.rhUsualSaved
          : l10n.rhSavedTitle,
    );
  } else {
    closeFlow(context, then: Routes.rhythmResult, extra: saved);
  }
}

/// HL01 with the signs answered "Có" (ids only, never free text).
String healthLocation(List<HealthSign> signs) => signs.isEmpty
    ? Routes.rhythmHealth
    : '${Routes.rhythmHealth}?signs=${signs.map((s) => s.wire).join(',')}';

String activityLocation(String contentId, {String? checkInId}) =>
    '${Routes.rhythmActivity}/$contentId${checkInId == null ? '' : '?ci=$checkInId'}';

String activityFeedbackLocation(String contentId) =>
    '${Routes.rhythmActivity}/$contentId/feedback';

/// Who else reads check-ins (`history.read`), for "Ba và Cô Lan sẽ thấy".
String seenBy(AppLocalizations l10n, List<Membership> members, String myUid) {
  final names = [
    for (final m in members)
      if (m.uid != myUid &&
          m.isActive &&
          familyCan(m, FamilyAction.historyRead))
        memberLabel(l10n, m, myUid: myUid),
  ];
  return names.isEmpty
      ? l10n.rhSeenByOnlyYou
      : l10n.rhSeenBy(joinNames(l10n, names));
}

/// The latest feedback on [contentId] (any author), newest first in [rows].
RecFeedback? latestFeedback(List<RecFeedback> rows, String contentId) =>
    rows.where((r) => r.contentId == contentId).firstOrNull;
