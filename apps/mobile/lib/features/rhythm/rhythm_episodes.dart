import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../family/family_repository.dart';
import 'rhythm_access.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// NL07b (573:1199) "Nhóm thành một đợt quan sát?" and NL07's episode card (573:1109): the app
/// suggests grouping recent changed days (`suggestEpisode`, contracts `rhythm.ts`), a member
/// confirms, and the episode stays "Đang cập nhật" until someone taps "Con đã ổn hơn". Silence
/// never ends it; nothing here is a Wonder Weeks stage.

/// How far back a suggestion looks (days with updates within this window).
const episodeWindowDays = 7;

/// Who may confirm or close an episode: Cùng nuôi and Người chăm sóc, as themselves (the Rules'
/// `canLog`, `observationEpisodeSchema`). Note: `family-actions.ts` still lists NL07b under
/// `rhythm.setup` (Cùng nuôi only) in its comment.
bool canConfirmEpisode(Membership me) =>
    familyCan(me, FamilyAction.rhythmCheckin);

/// `ep_` + 32 hex from the baby and the first day: two people confirming the same grouping
/// (offline, at once) write one episode, not two.
String episodeIdFor(String babyId, String startDate) =>
    'ep_${sha256.convert(utf8.encode('$babyId|$startDate')).toString().substring(0, 32)}';

/// What NL07b would group: the changed check-ins of the last three days with updates.
@immutable
class EpisodeSuggestion {
  const EpisodeSuggestion({required this.changed, required this.lastDate});

  /// Oldest first.
  final List<CheckIn> changed;

  /// The newest day considered (remembered by "Không cần").
  final String lastDate;

  String get startDate => changed.first.date;
  int get dayCount => {for (final c in changed) c.date}.length;
}

/// NL07b's rule on the phone: no open episode, days after the last closed episode and after the
/// last "Không cần", within [episodeWindowDays], health worries left out (they go to HL01), then
/// [suggestEpisode] over the days with updates.
EpisodeSuggestion? episodeSuggestion({
  required List<CheckIn> checkIns,
  required List<ObservationEpisode> episodes,
  required String today,
  String? dismissedThrough,
}) {
  if (episodes.any((e) => e.open)) return null;
  var after = addDaysIso(today, -episodeWindowDays);
  for (final e in episodes) {
    final end = e.endDate;
    if (!e.open && end != null && end.compareTo(after) > 0) after = end;
  }
  if (dismissedThrough != null && dismissedThrough.compareTo(after) > 0) {
    after = dismissedThrough;
  }
  final byDay = <String, List<CheckIn>>{};
  for (final c in checkIns) {
    if (c.observation == Observation.health ||
        c.date.compareTo(after) <= 0 ||
        c.date.compareTo(today) > 0) {
      continue;
    }
    (byDay[c.date] ??= []).add(c);
  }
  final days = [
    for (final e in byDay.entries)
      (date: e.key, state: observationStateOf(e.value)),
  ];
  if (!suggestEpisode(days)) return null;
  final lastThree = (byDay.keys.toList()..sort()).reversed.take(3).toList()
    ..sort();
  final changed = [
    for (final d in lastThree)
      for (final c in byDay[d]!)
        if (c.changed) c,
  ];
  if (changed.isEmpty) return null;
  return EpisodeSuggestion(changed: changed, lastDate: lastThree.last);
}

/// "Không cần" per person and baby: the newest day already turned down.
final episodeDismissedProvider =
    NotifierProvider.family<EpisodeDismissedNotifier, String?, String>(
      EpisodeDismissedNotifier.new,
    );

/// Keyed by `uid|babyId`.
class EpisodeDismissedNotifier extends Notifier<String?> {
  EpisodeDismissedNotifier(this.key);
  final String key;

  String get _key => 'rhythm.episodeDismissed.$key';

  @override
  String? build() {
    try {
      return ref.read(sharedPreferencesProvider).getString(_key);
    } on Object {
      return null;
    }
  }

  void dismissThrough(String date) {
    state = date;
    try {
      ref.read(sharedPreferencesProvider).setString(_key, date).ignore();
    } on Object {
      // Best effort: at worst the suggestion comes once more.
    }
  }
}

/// The episode part of NL01's "Nhịp riêng của con": the open episode, or the NL07b suggestion.
class EpisodeBlock extends ConsumerWidget {
  const EpisodeBlock({required this.me, required this.today, super.key});
  final Membership me;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns =
        ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[];
    final episodes = ref.watch(episodesProvider(me.babyId)).value;
    if (episodes == null) return const SizedBox.shrink();
    final open = episodes.where((e) => e.open).firstOrNull;
    if (open != null) {
      return _padded(_OpenEpisode(me: me, episode: open, today: today));
    }
    if (!canConfirmEpisode(me)) return const SizedBox.shrink();
    final dismissed = ref.watch(
      episodeDismissedProvider('${me.uid}|${me.babyId}'),
    );
    final suggestion = episodeSuggestion(
      checkIns: checkIns,
      episodes: episodes,
      today: today,
      dismissedThrough: dismissed,
    );
    if (suggestion == null) return const SizedBox.shrink();
    return _padded(_Suggestion(me: me, suggestion: suggestion));
  }

  static Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s3),
    child: child,
  );
}

class _Suggestion extends ConsumerWidget {
  const _Suggestion({required this.me, required this.suggestion});
  final Membership me;
  final EpisodeSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final people = <String>[];
    final seen = <String>{};
    for (final c in suggestion.changed) {
      if (!seen.add('${c.authorUid}|${c.date}')) continue;
      final m = members.where((x) => x.uid == c.authorUid).firstOrNull;
      people.add(
        l10n.rhEpPersonDay(
          memberLabel(
            l10n,
            m,
            myUid: me.uid,
            uid: c.authorUid,
            sentenceStart: false,
          ),
          shortDay(locale, c.date),
        ),
      );
    }
    final what = {
      for (final c in suggestion.changed)
        observationShort(l10n, c.observation).toLowerCase(),
    }.join(', ');

    void create() {
      final toaster = ClToaster.of(context);
      ref
          .read(rhythmRepositoryProvider)
          .saveEpisode(
            ObservationEpisode(
              id: episodeIdFor(me.babyId, suggestion.startDate),
              babyId: me.babyId,
              startDate: suggestion.startDate,
              confirmedBy: me.uid,
              checkInIds: [
                for (final c in suggestion.changed.take(
                  ObservationEpisode.maxCheckIns,
                ))
                  c.id,
              ],
            ),
            create: true,
            onError: (_) =>
                toaster.show(message: l10n.rhSaveFailed, error: true),
          );
      toaster.show(message: l10n.rhEpCreated);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.rhEpSuggestTitle,
              style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.rhEpSuggestBody(
              suggestion.dayCount,
              joinNames(l10n, people),
              what,
            ),
            style: cl.text.label.copyWith(color: cl.colors.ink, height: 1.45),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.rhEpNotWonder,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              RhPillButton(label: l10n.rhEpCreate, onTap: create),
              RhPillButton(
                label: l10n.rhEpNoNeed,
                primary: false,
                onCard: true,
                onTap: () => ref
                    .read(
                      episodeDismissedProvider(
                        '${me.uid}|${me.babyId}',
                      ).notifier,
                    )
                    .dismissThrough(suggestion.lastDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenEpisode extends ConsumerWidget {
  const _OpenEpisode({
    required this.me,
    required this.episode,
    required this.today,
  });
  final Membership me;
  final ObservationEpisode episode;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final who = capitalized(
      memberLabel(
        l10n,
        members.where((m) => m.uid == episode.confirmedBy).firstOrNull,
        myUid: me.uid,
        uid: episode.confirmedBy,
      ),
    );
    final start = shortDay(locale, episode.startDate);

    Future<void> close() async {
      final toaster = ClToaster.of(context);
      final ok = await rhConfirm(
        context,
        title: l10n.rhEpCloseTitle,
        body: l10n.rhEpCloseBody(start),
        confirm: l10n.rhEpBetter,
        cancel: l10n.rhEpNotYet,
      );
      if (!ok) return;
      ref
          .read(rhythmRepositoryProvider)
          .saveEpisode(
            episode.close(uid: me.uid, date: today),
            onError: (_) =>
                toaster.show(message: l10n.rhSaveFailed, error: true),
          );
      toaster.show(message: l10n.rhEpClosed);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.rhEpOpenTitle(start),
                    style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  l10n.rhEpUpdating,
                  style: cl.text.caption.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.rhEpOpenBody(who, episode.checkInIds.length),
            style: cl.text.label.copyWith(color: cl.colors.ink, height: 1.45),
          ),
          if (canConfirmEpisode(me)) ...[
            const SizedBox(height: ClSpace.s3),
            RhPillButton(label: l10n.rhEpBetter, onTap: close),
          ],
        ],
      ),
    );
  }
}
