import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart' show ClSkeleton, showClToast;
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart' show babyProvider;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'personal_day_pages.dart' show PersonalHeading;
import 'personal_day_widgets.dart';
import 'personalization_v2_repository.dart';
import 'personalization_v2_screen.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart' show localDateIn;
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_plans.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// Where an idea stands for this family, newest event first (D-102: one history).
enum TriedState { due, planned, helpful, unsure, notAFit, saved, hidden }

/// One idea once (owner, 2026-10-24/25), from Nhịp lớn lên's family answers and plans and from
/// this person's "Gợi ý hôm nay cho bé" responses, whichever is newer.
@immutable
class TriedItem {
  const TriedItem({
    required this.contentId,
    required this.state,
    required this.at,
    this.uid,
    this.date,
    this.note,
    this.plan,
    this.fromDay = false,
    this.tried = false,
  });

  final String contentId;
  final TriedState state;

  /// For ordering: the newest event behind [state].
  final DateTime at;
  final String? uid;

  /// The baby-local day of that event (`yyyy-MM-dd`).
  final String? date;
  final String? note;

  /// Nhịp lớn lên's open plan (its result is asked once [ActivityPlan.due]).
  final ActivityPlan? plan;

  /// From the personal day snapshot (answered through `askOutcome`, restored there).
  final bool fromDay;

  /// Tried, not answered yet ("Bạn · 08/10 · Đã thử").
  final bool tried;

  bool get answered =>
      state == TriedState.helpful ||
      state == TriedState.unsure ||
      state == TriedState.notAFit;
}

/// Merges both sources: one row per idea, newest first.
List<TriedItem> triedItems({
  required List<RecFeedback> feedback,
  required PersonalDay? day,
  required String myUid,
  required String zone,
  required DateTime now,
  required Set<String> setAside,
  required ActivityTime Function(String contentId) timeOf,
}) {
  final byId = <String, TriedItem>{};
  void keep(TriedItem item) {
    final had = byId[item.contentId];
    if (had == null || item.at.isAfter(had.at)) byId[item.contentId] = item;
  }

  DateTime when(RecFeedback r) =>
      r.createdAt ?? DateTime.tryParse(r.date) ?? DateTime(2000);
  // triedEntries is newest first: the first entry of an idea is its current one.
  final seen = <String>{};
  for (final e in triedEntries(feedback)) {
    if (!seen.add(e.contentId)) continue;
    final answer = e.answers.lastOrNull;
    if (answer != null) {
      keep(
        TriedItem(
          contentId: e.contentId,
          state: switch (answer.kind) {
            FeedbackKind.helpful => TriedState.helpful,
            FeedbackKind.unsure => TriedState.unsure,
            _ => TriedState.notAFit,
          },
          at: when(answer),
          uid: answer.authorUid,
          date: answer.date,
          note: answer.note,
        ),
      );
      continue;
    }
    final started = e.plan;
    if (started == null || setAside.contains(started.id)) continue;
    final plan = planFrom(
      started,
      zone: zone,
      timeOfDay: timeOf(e.contentId),
      now: now,
    );
    keep(
      TriedItem(
        contentId: e.contentId,
        state: plan.due ? TriedState.due : TriedState.planned,
        at: when(started),
        uid: started.authorUid,
        date: started.date,
        plan: plan,
      ),
    );
  }

  if (day != null) {
    for (final entry in day.responses.entries) {
      final id = entry.key;
      if (id.startsWith('work:')) continue;
      final r = dayMap(entry.value);
      DateTime? at(String field) => DateTime.tryParse('${r[field] ?? ''}');
      final tried = at('triedAt');
      final intended = at('intendedAt');
      final last = at('outcomeAt') ?? tried ?? intended ?? at('at');
      if (last == null) continue;
      final state = tried != null
          ? switch (r['outcome'] ?? r['value']) {
              'helpful' => TriedState.helpful,
              'unsure' => TriedState.unsure,
              'dislike' => TriedState.notAFit,
              _ => TriedState.due,
            }
          : intended != null
          ? TriedState.planned
          : day.suppressed(id, now)
          ? TriedState.hidden
          : r['saved'] == true
          ? TriedState.saved
          : null;
      if (state == null) continue;
      keep(
        TriedItem(
          contentId: id,
          state: state,
          at: last,
          uid: myUid,
          date: localDateIn(zone, last),
          fromDay: true,
          tried: tried != null && state == TriedState.due,
        ),
      );
    }
  }
  return byId.values.toList()..sort((a, b) => b.at.compareTo(a.at));
}

/// "Cách nhà mình đã thử" (D-102, owner 2026-10-25): the one history of ideas — three numbers,
/// a filter, then each idea once with how it went (icon, who, when, the note) and the one thing
/// it still asks for ("Con thế nào?", or "Khôi phục" for a hidden idea). Replaces "Các cách đã
/// thử" and "Đã lưu, đã thử và đã ẩn". Reading needs `history.read`; answering `rhythm.feedback`.
class TriedScreen extends ConsumerStatefulWidget {
  const TriedScreen({super.key});

  @override
  ConsumerState<TriedScreen> createState() => _TriedScreenState();
}

enum _Filter { all, helpful, planned, saved, hidden }

class _TriedScreenState extends ConsumerState<TriedScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final topBar = Align(
      alignment: Alignment.centerLeft,
      child: RhRoundIcon(
        icon: ClIcons.back,
        label: l10n.a11yBack,
        onPressed: () => leaveRhythm(context),
      ),
    );
    final heading = [
      Semantics(
        header: true,
        child: Text(l10n.rhTriedHistoryTitle, style: cl.text.title),
      ),
      const SizedBox(height: ClSpace.s1),
      Text(
        l10n.rhTriedHistoryBody(feedbackWindowDays),
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s4),
    ];
    if (me == null || !familyCan(me, FamilyAction.historyRead)) {
      return OnboardingScaffold(
        topBar: topBar,
        content: [
          ...heading,
          RhInfoBox(icon: ClIcons.lock, text: l10n.rhTriedHistoryEmpty),
        ],
      );
    }
    watchRhythmClock(ref, me.babyId);
    final feedback = ref.watch(recFeedbackProvider(me.babyId));
    final key = personalKey(context, ref);
    final day = key == null ? null : ref.watch(personalDayProvider(key)).value;
    final content = ref.watch(rhythmContentProvider).value;
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final items = triedItems(
      feedback: feedback.value ?? const <RecFeedback>[],
      day: day,
      myUid: me.uid,
      zone: zone,
      now: rhythmNow(ref),
      setAside: ref.watch(plansSetAsideProvider(setAsideKey(me))),
      timeOf: (id) => content?.activity(id)?.timeOfDay ?? ActivityTime.any,
    );
    bool inFilter(TriedItem i, _Filter f) => switch (f) {
      _Filter.all => i.state != TriedState.hidden,
      _Filter.helpful => i.state == TriedState.helpful,
      _Filter.planned =>
        (i.state == TriedState.planned || i.state == TriedState.due) &&
            !i.tried,
      _Filter.saved => i.state == TriedState.saved,
      _Filter.hidden => i.state == TriedState.hidden,
    };
    final counts = {
      for (final f in _Filter.values)
        f: items.where((i) => inFilter(i, f)).length,
    };
    final filter = counts[_filter] == 0 ? _Filter.all : _filter;
    final shown = items.where((i) => inFilter(i, filter)).toList();
    final exclusions = day != null && day.parent
        ? dayRows(day.data['sharedExclusions'])
        : const <Map<String, dynamic>>[];
    String title(String id) =>
        content?.activity(id)?.title.of(locale) ?? l10n.rhUnknownActivity;

    return OnboardingScaffold(
      topBar: topBar,
      content: [
        ...heading,
        if (feedback.isLoading && !feedback.hasValue)
          const ClSkeleton(height: 160, radius: 16)
        else if (items.isEmpty)
          RhInfoBox(icon: ClIcons.heart, text: l10n.rhTriedHistoryEmpty)
        else ...[
          // Three numbers as tiles, not a sentence (owner, 2026-10-24).
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: items.where((i) => i.answered || i.tried).length,
                  label: l10n.rhTriedStatTried,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: _Stat(
                  value: counts[_Filter.helpful]!,
                  label: l10n.rhTriedStatHelpful,
                  highlight: true,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: _Stat(
                  value: counts[_Filter.planned]!,
                  label: l10n.rhTriedStatPlanned,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final f in _Filter.values)
                if (f == _Filter.all || counts[f]! > 0)
                  RhChip(
                    key: ValueKey('tried.filter.${f.name}'),
                    label: switch (f) {
                      _Filter.all => l10n.rhTriedAll,
                      _Filter.helpful => l10n.rhHelpful,
                      _Filter.planned => l10n.rhPlannedPill,
                      _Filter.saved => l10n.pv2StatusSaved,
                      _Filter.hidden => l10n.pv2StatusHidden,
                    },
                    selected: filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          RhCard(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Column(
              children: [
                for (final (i, item) in shown.indexed) ...[
                  if (i > 0) Container(height: 1, color: cl.colors.separator),
                  _TriedRow(me: me, item: item, dayKey: key),
                ],
              ],
            ),
          ),
        ],
        if (exclusions.isNotEmpty && key != null) ...[
          const SizedBox(height: ClSpace.s4),
          PersonalHeading(l10n.pv2Exclude),
          RhCard(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Column(
              children: [
                for (final exclusion in exclusions)
                  _RowShell(
                    leading: const _StateIcon(TriedState.hidden),
                    title: title('${exclusion['id']}'),
                    trailing: PersonalTextAction(
                      label: l10n.pv2Restore,
                      onTap: () => mutateDay(context, ref, key, {
                        'kind': 'respond',
                        'contentId': exclusion['id'],
                        'value': 'restore',
                        'scope': 'baby',
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.rhTriedNote,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// One idea: its state icon, title, "Mẹ · 07/10 · Có ích" (or the plan), the note, and the one
/// action it still asks for.
class _TriedRow extends ConsumerWidget {
  const _TriedRow({required this.me, required this.item, this.dayKey});

  final Membership me;
  final TriedItem item;
  final PersonalDayKey? dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final activity = ref
        .watch(rhythmContentProvider)
        .value
        ?.activity(item.contentId);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final canAct = familyCan(me, FamilyAction.rhythmFeedback);
    final who = capitalized(
      memberLabel(
        l10n,
        members.where((m) => m.uid == item.uid).firstOrNull,
        myUid: me.uid,
        uid: item.uid ?? me.uid,
      ),
    );
    // A plan says "tối 07/10"; an answer just its day (it is often given the morning after).
    final day = item.date == null
        ? ''
        : item.answered
        ? shortDay(locale, item.date!)
        : planDayLabel(
            l10n,
            locale,
            item.date!,
            activity?.timeOfDay ?? ActivityTime.any,
          );
    final sub = switch (item.state) {
      TriedState.helpful || TriedState.unsure || TriedState.notAFit =>
        '${l10n.rhWhoDay(who, day)} · ${feedbackKindLabel(l10n, switch (item.state) {
          TriedState.helpful => FeedbackKind.helpful,
          TriedState.unsure => FeedbackKind.unsure,
          _ => FeedbackKind.notSuitable,
        })}',
      TriedState.due when item.tried =>
        '${l10n.rhWhoDay(who, day)} · ${l10n.pv2TriedBefore}',
      TriedState.due || TriedState.planned => l10n.rhPlannedBy(who, day),
      TriedState.saved => l10n.pv2StatusSaved,
      TriedState.hidden => l10n.pv2StatusHidden,
    };
    final asks =
        canAct &&
        (item.state == TriedState.due ||
            (item.fromDay && item.state == TriedState.planned));
    Widget? trailing;
    if (asks && (item.fromDay ? dayKey != null : activity != null)) {
      // A text action, so the title keeps its width (golden 2026-10-25).
      trailing = PersonalTextAction(
        key: ValueKey('tried.ask.${item.contentId}'),
        label: l10n.rhTellHow,
        onTap: () => item.fromDay
            ? askOutcome(context, ref, dayKey!, item.contentId)
            : _askRhOutcome(context, ref, me, activity!, item.plan!),
      );
    } else if (item.fromDay &&
        item.state == TriedState.hidden &&
        dayKey != null) {
      trailing = PersonalTextAction(
        label: l10n.pv2Restore,
        onTap: () => mutateDay(context, ref, dayKey!, {
          'kind': 'respond',
          'contentId': item.contentId,
          'value': 'restore',
        }),
      );
    }
    final title = activity?.title.of(locale) ?? l10n.rhUnknownActivity;
    return _RowShell(
      key: ValueKey('tried.row.${item.contentId}'),
      leading: _StateIcon(item.state, tried: item.tried),
      title: title,
      sub: sub,
      note: item.note == null ? null : l10n.rhQuoted(item.note!),
      trailing: trailing,
      onTap: activity == null
          ? null
          : () => context.push(activityLocation(activity.id)),
    );
  }
}

/// "Con thế nào?" for a Nhịp lớn lên plan: the three answers, or "Chưa thử được".
Future<void> _askRhOutcome(
  BuildContext context,
  WidgetRef ref,
  Membership me,
  Activity activity,
  ActivityPlan plan,
) async {
  final l10n = AppLocalizations.of(context);
  final kind = await showClSheet<FeedbackKind?>(
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
          ClSheetHeader(title: l10n.rhHowDidItGo),
          RhOutcomeChoices(onPick: (k) => Navigator.of(sheet).pop(k)),
          const SizedBox(height: ClSpace.s2),
          RhLink(
            label: l10n.rhDidNotTry,
            muted: true,
            onTap: () => Navigator.of(sheet).pop(FeedbackKind.notToday),
          ),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return;
  if (kind == FeedbackKind.notToday) {
    withdrawPlan(context, ref, me, plan, notTried: true);
    return;
  }
  giveFeedbackOn(context, ref, me, kind: kind, activity: activity);
  showClToast(context, message: l10n.rhFeedbackSaved);
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.leading,
    required this.title,
    this.sub,
    this.note,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? sub;
  final String? note;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
      child: Row(
        children: [
          leading,
          const SizedBox(width: ClSpace.s3),
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
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
                if (note != null)
                  Text(
                    note!,
                    style: cl.text.caption.copyWith(color: cl.colors.ink),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: ClSpace.s2),
            trailing!,
          ],
        ],
      ),
    );
    return onTap == null
        ? MergeSemantics(child: row)
        : ClPressable(
            onPressed: onTap,
            pressedOpacity: ClPressable.surfaceOpacity,
            semanticLabel: [title, ?sub].join(', '),
            child: row,
          );
  }
}

/// The state as a small round icon: ♥ Có ích (mint), ⏱ Chưa rõ, × Không hợp, 🔔 Sẽ thử (warm),
/// bookmark Đã lưu, eye Đã ẩn. Never colour alone: the line under the title says it too.
class _StateIcon extends StatelessWidget {
  const _StateIcon(this.state, {this.tried = false});
  final TriedState state;
  final bool tried;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final (icon, fill, ink) = switch (state) {
      _ when tried => (ClIcons.check, c.surface2, c.inkMuted),
      TriedState.helpful => (ClIcons.heart, c.mintSoft, c.mintText),
      TriedState.unsure => (ClIcons.clock, c.surface2, c.inkMuted),
      TriedState.notAFit => (ClIcons.close, c.surface2, c.inkMuted),
      TriedState.due ||
      TriedState.planned => (ClIcons.bell, c.sunshineSoft, c.ink),
      TriedState.saved => (ClIcons.bookmark, c.surface2, c.inkMuted),
      TriedState.hidden => (ClIcons.eye, c.surface2, c.inkMuted),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ClIcon(icon, size: 16, color: ink),
    );
  }
}

/// One number ("3 · có ích"); helpful on the mint fill.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: highlight ? cl.colors.mintSoft : cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: cl.text.title.copyWith(
                  color: highlight ? cl.colors.mintText : cl.colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: cl.text.caption.copyWith(
                  color: highlight ? cl.colors.mintText : cl.colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
