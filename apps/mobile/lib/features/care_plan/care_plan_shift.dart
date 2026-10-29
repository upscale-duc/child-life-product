import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_duty.dart';
import '../care/care_models.dart' show CareType;
import '../care/care_sheets.dart' show openCareLog;
import '../care/timer_screens.dart' show showSleepChooser;
import '../care/care_repository.dart' show careClockProvider, inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_today.dart';
import 'care_plan_widgets.dart';

/// Cùng Chăm Con step 3 (D-135; ANALYSIS-2026-10-28 §3, §4): a helper's day on shift. Their
/// shift spans the tasks given to them today (Q2); "đang trông" is their own duty, which they
/// start here and which ends when a parent receives their handover (Q1).

/// Today's tasks of [me] (skipped ones left out), in time order; with this phone's pending ticks.
List<CarePlanItem> carePlanMyDay(WidgetRef ref, Membership me) {
  final date = carePlanTodayKey(ref, me.babyId);
  final pending = ref.watch(carePlanPendingProvider);
  return [
    for (final i
        in ref.watch(carePlanLiveItemsProvider((me.babyId, date))).value ??
            const <CarePlanItem>[])
      if (i.assignees.contains(me.uid) && !i.skipped)
        switch (pending[i.id]) {
          final s? => i.copyWith(status: s, doneBy: me.uid),
          null => i,
        },
  ];
}

/// A helper with tasks today gets the shift layout of Hôm nay (16).
bool carePlanOnShiftDay(WidgetRef ref, Membership me) =>
    me.role == MemberRole.caregiver && carePlanMyDay(ref, me).isNotEmpty;

/// When [me]'s own duty started, while it is current (P-181; a day old is no longer current).
DateTime? carePlanShiftSince(WidgetRef ref, Membership me) {
  final duty = ref.watch(careDutyProvider(me.babyId)).value;
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final since = duty?.since;
  if (duty?.uid != me.uid || since == null) return null;
  return dutyAge(since, now) == DutyAge.stale ? null : since;
}

/// The ring on [item]: done, or open again ("Hoàn tác" by a second tap).
Future<void> carePlanToggle(
  BuildContext context,
  WidgetRef ref,
  ClToaster toaster,
  AppLocalizations l10n,
  Membership me,
  CarePlanItem item,
) async {
  final date = carePlanTodayKey(ref, me.babyId);
  if (!item.done) {
    return markCarePlanDone(
      ref,
      toaster,
      l10n,
      babyId: me.babyId,
      date: date,
      items: [item],
      context: context,
    );
  }
  final pend = ref.read(carePlanPendingProvider.notifier)
    ..set(item.id, CarePlanStatus.open);
  try {
    await ref
        .read(carePlanRepositoryProvider)
        .setStatus(me.babyId, date, item.id, CarePlanStatus.open);
  } on Object {
    toaster.show(message: l10n.cpSaveFailed, error: true);
  } finally {
    pend.clear(item.id);
  }
}

/// 16: the shift at a glance. The ring of my tasks done, the span of my day ("07:00 – 17:00"),
/// what is left, and my duty: "Bắt đầu ca", or since when I have been caring.
class CarePlanShiftCard extends ConsumerStatefulWidget {
  const CarePlanShiftCard({required this.me, super.key});

  final Membership me;

  @override
  ConsumerState<CarePlanShiftCard> createState() => _CarePlanShiftCardState();
}

class _CarePlanShiftCardState extends ConsumerState<CarePlanShiftCard> {
  bool _starting = false;

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _starting = true);
    try {
      await ref.read(careDutyWriterProvider)(widget.me.babyId, take: true);
    } on Object {
      toaster.show(message: l10n.dutyFailed, error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = widget.me;
    final day = carePlanMyDay(ref, me);
    if (day.isEmpty) return const SizedBox.shrink();
    final done = day.where((i) => i.done).length;
    final left = day.length - done;
    final since = carePlanShiftSince(ref, me);
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final span = day.first.time == day.last.time
        ? day.first.time
        : '${day.first.time} – ${day.last.time}';
    return Container(
      key: const Key('cpShiftCard'),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.cardMint,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CarePlanProgressRing(done: done, total: day.length),
              const SizedBox(width: ClSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      span,
                      style: cl.text.title.copyWith(
                        color: cl.colors.onCard,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      left == 0 ? l10n.cpShiftAllDone : l10n.cpShiftLeft(left),
                      style: cl.text.label.copyWith(color: cl.colors.onCard),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          if (since != null)
            ClPressable(
              key: const Key('cpShiftOn'),
              semanticLabel: l10n.cpShiftOnSince(
                DateFormat('HH:mm').format(inBabyZone(zone, since)),
              ),
              onPressed: () => showCareDutySheet(context, ref, me),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cl.colors.onCard,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.cpShiftOnSince(
                          DateFormat('HH:mm').format(inBabyZone(zone, since)),
                        ),
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.onCard,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ClButton(
              key: const Key('cpShiftStart'),
              label: l10n.cpShiftStart,
              style: ClButtonStyle.primary,
              expand: true,
              loading: _starting,
              onPressed: _starting ? null : _start,
            ),
        ],
      ),
    );
  }
}

/// 16 "Việc của tôi": every task of mine today with its ring; the next open one is edged.
class CarePlanMyTasks extends ConsumerWidget {
  const CarePlanMyTasks({required this.me, super.key});

  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = carePlanMyDay(ref, me);
    if (day.isEmpty) return const SizedBox.shrink();
    final nextId = day.where((i) => !i.done).firstOrNull?.id;
    return Column(
      key: const Key('cpMyTasks'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.cpMyTasks,
                  style: context.cl.text.headline.copyWith(
                    color: context.cl.colors.ink,
                  ),
                ),
              ),
            ),
            if (day.where((i) => !i.done).length case final open when open > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.cl.colors.mintSoft,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$open',
                  style: context.cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.cl.colors.mintText,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        for (final i in day)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: CarePlanTaskCard(
              key: ValueKey('cpMine_${i.id}'),
              item: i,
              name: carePlanTaskName(l10n, i),
              next: i.id == nextId,
              status: null,
              people: const SizedBox.shrink(),
              ring: CarePlanRing(
                key: ValueKey('cpMineRing_${i.id}'),
                done: i.done,
                semanticLabel: i.done
                    ? l10n.cpMarkOpen(carePlanTaskName(l10n, i))
                    : l10n.cpMarkDone(carePlanTaskName(l10n, i)),
                onPressed: () => unawaited(
                  carePlanToggle(
                    context,
                    ref,
                    ClToaster.of(context),
                    l10n,
                    me,
                    i,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// "Ghi chú cho bố mẹ": kept on this phone for the day, then the handover's "Lời nhắn" (§3.2).
// ---------------------------------------------------------------------------------------------

/// Tags for what the diary cannot say (no "Đi ngoài": the diaper log has it, D-110).
enum CarePlanNoteTag { ateWell, fussy, sleptWell, smiles }

String carePlanNoteTagLabel(AppLocalizations l10n, CarePlanNoteTag t) =>
    switch (t) {
      CarePlanNoteTag.ateWell => l10n.cpNoteAteWell,
      CarePlanNoteTag.fussy => l10n.cpNoteFussy,
      CarePlanNoteTag.sleptWell => l10n.cpNoteSleptWell,
      CarePlanNoteTag.smiles => l10n.cpNoteSmiles,
    };

@immutable
class CarePlanShiftNote {
  const CarePlanShiftNote({this.tags = const {}, this.text = ''});

  final Set<CarePlanNoteTag> tags;
  final String text;

  bool get isEmpty => tags.isEmpty && text.trim().isEmpty;

  /// "Ăn ngon · Ngủ sâu. Khăn sạch ở ngăn trên" (at most 300 characters, like a send's note).
  String message(AppLocalizations l10n) {
    final parts = [
      if (tags.isNotEmpty)
        [
          for (final t in CarePlanNoteTag.values)
            if (tags.contains(t)) carePlanNoteTagLabel(l10n, t),
        ].join(' · '),
      if (text.trim().isNotEmpty) text.trim(),
    ];
    final m = parts.join('. ');
    return m.length > 300 ? m.substring(0, 300) : m;
  }

  Map<String, Object> toJson() => {
    'tags': [for (final t in tags) t.name],
    'text': text,
  };

  static CarePlanShiftNote fromJson(Object? j) {
    if (j is! Map) return const CarePlanShiftNote();
    final names = CarePlanNoteTag.values.asNameMap();
    return CarePlanShiftNote(
      tags: {for (final n in (j['tags'] as List?) ?? const []) ?names['$n']},
      text: j['text'] is String ? j['text'] as String : '',
    );
  }
}

typedef CarePlanNoteKey = (String babyId, String date);

/// This phone's notes for the shift of one day; they never leave it until the handover is sent.
class CarePlanShiftNotes extends Notifier<CarePlanShiftNote> {
  CarePlanShiftNotes(this.arg);
  final CarePlanNoteKey arg;

  String get _key => 'carePlan.shiftNote.${arg.$1}.${arg.$2}';

  @override
  CarePlanShiftNote build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const CarePlanShiftNote();
    try {
      return CarePlanShiftNote.fromJson(jsonDecode(raw));
    } on FormatException {
      return const CarePlanShiftNote();
    }
  }

  void set(CarePlanShiftNote next) {
    state = next;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(next.toJson())),
    );
  }

  void toggle(CarePlanNoteTag t) => set(
    CarePlanShiftNote(
      tags: state.tags.contains(t)
          ? ({...state.tags}..remove(t))
          : {...state.tags, t},
      text: state.text,
    ),
  );
}

final carePlanShiftNotesProvider =
    NotifierProvider.family<
      CarePlanShiftNotes,
      CarePlanShiftNote,
      CarePlanNoteKey
    >(CarePlanShiftNotes.new);

/// 16 "Ghi chú cho bố mẹ": a few tags and "Viết thêm…".
class CarePlanShiftNotesCard extends ConsumerStatefulWidget {
  const CarePlanShiftNotesCard({required this.me, super.key});

  final Membership me;

  @override
  ConsumerState<CarePlanShiftNotesCard> createState() =>
      _CarePlanShiftNotesCardState();
}

class _CarePlanShiftNotesCardState
    extends ConsumerState<CarePlanShiftNotesCard> {
  TextEditingController? _text;

  @override
  void dispose() {
    _text?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final key = (widget.me.babyId, carePlanTodayKey(ref, widget.me.babyId));
    final note = ref.watch(carePlanShiftNotesProvider(key));
    final notifier = ref.read(carePlanShiftNotesProvider(key).notifier);
    _text ??= TextEditingController(text: note.text);
    final c = cl.colors;
    return Container(
      key: const Key('cpShiftNotes'),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.cpNotesTitle,
              style: cl.text.label.copyWith(color: c.inkMuted),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final t in CarePlanNoteTag.values)
                ClRelationChip(
                  key: ValueKey('cpNoteTag_${t.name}'),
                  label: carePlanNoteTagLabel(l10n, t),
                  selected: note.tags.contains(t),
                  onTap: () => notifier.toggle(t),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          ClTextField(
            key: const Key('cpNoteText'),
            controller: _text,
            placeholder: l10n.cpNoteMore,
            maxLength: 200,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (v) =>
                notifier.set(CarePlanShiftNote(tags: note.tags, text: v)),
          ),
        ],
      ),
    );
  }
}

/// 16 "ghi 1 chạm": Bú bình, Ngủ, Thay tã as three picture tiles; each opens its log.
class CarePlanQuickLog extends ConsumerWidget {
  const CarePlanQuickLog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final tiles = [
      (
        CarePlanTask.bottle,
        l10n.cpTaskBottle,
        () => openCareLog(context, CareType.bottle),
      ),
      (
        CarePlanTask.sleep,
        l10n.cpTaskSleep,
        () => showSleepChooser(context, ref),
      ),
      (
        CarePlanTask.diaper,
        l10n.cpTaskDiaper,
        () => openCareLog(context, CareType.diaper),
      ),
    ];
    return Row(
      key: const Key('cpQuickLog'),
      children: [
        for (final (i, (task, label, open)) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: ClSpace.s2),
          Expanded(
            child: ClPressable(
              key: ValueKey('cpQuick_${task.name}'),
              onPressed: () => unawaited(open()),
              semanticLabel: label,
              pressedOpacity: ClPressable.surfaceOpacity,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: ClSpace.s3,
                  horizontal: ClSpace.s1,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(ClRadius.card),
                  boxShadow: cl.shadows.card,
                ),
                child: Column(
                  children: [
                    CarePlanArt(task, size: 56),
                    const SizedBox(height: ClSpace.s2),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: cl.text.label.copyWith(color: c.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 16's greeting: the helper's face, "Chào Cô Lan", and the bell and Night care beside it.
class CarePlanShiftHello extends StatelessWidget {
  const CarePlanShiftHello({
    required this.me,
    required this.title,
    required this.actions,
    super.key,
  });

  final Membership me;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        CarePlanAvatar(me, size: 56),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: cl.text.title2.copyWith(color: cl.colors.ink),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Bàn giao (17): "Việc còn lại hôm nay" and who receives a helper's handover.
// ---------------------------------------------------------------------------------------------

/// 17 "Việc còn lại hôm nay": the day's open tasks, who does them, and the ring for those who
/// may tick (a parent receiving can finish one right there).
class CarePlanRemaining extends ConsumerWidget {
  const CarePlanRemaining({required this.me, super.key});

  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final date = carePlanTodayKey(ref, me.babyId);
    final pending = ref.watch(carePlanPendingProvider);
    final open = [
      for (final i
          in ref.watch(carePlanLiveItemsProvider((me.babyId, date))).value ??
              const <CarePlanItem>[])
        if (pending[i.id] == null && i.status == CarePlanStatus.open) i,
    ];
    if (open.isEmpty) return const SizedBox.shrink();
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final complete = carePlanCanComplete(me);
    return Column(
      key: const Key('cpRemaining'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s4),
        ClSectionHeader(title: l10n.cpRemainingTitle),
        const SizedBox(height: ClSpace.s2),
        for (final i in open)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: CarePlanTaskCard(
              key: ValueKey('cpLeft_${i.id}'),
              item: i,
              name: carePlanTaskName(l10n, i),
              status: null,
              // Nobody on it: nothing to say here ("+ Giao" is the plan's, for managers).
              people: i.assignees.isEmpty
                  ? const SizedBox.shrink()
                  : CarePlanPeople(
                      people: [
                        for (final u in i.assignees)
                          ?members.where((m) => m.uid == u).firstOrNull,
                      ],
                      names: [
                        for (final u in i.assignees)
                          ?carePlanPersonName(l10n, members, u, me.uid),
                      ],
                      onTap: null,
                    ),
              ring: complete
                  ? CarePlanRing(
                      done: false,
                      semanticLabel: l10n.cpMarkDone(carePlanTaskName(l10n, i)),
                      onPressed: () => unawaited(
                        markCarePlanDone(
                          ref,
                          ClToaster.of(context),
                          l10n,
                          babyId: me.babyId,
                          date: date,
                          items: [i],
                          context: context,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

/// "Ba và Mẹ": the active Cùng nuôi a helper's handover goes to.
String carePlanParentsNames(
  AppLocalizations l10n,
  List<Membership> members,
  Membership me,
  DateTime now,
) => carePlanNames(l10n, [
  for (final m in members)
    if (m.role == MemberRole.coParent && m.isActiveAt(now))
      ?carePlanPersonName(l10n, members, m.uid, me.uid),
]);
