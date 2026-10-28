import '../adaptive/adaptive_engine.dart' show AgeBand;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/design/tabular_text.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_labels.dart' show memberLabel;
import 'care_format.dart' show durationLabel;
import 'care_repository.dart';

/// P-181 "Ai đang trông bé" (owner, 2026-10-25, mockup approved): who is caring for the baby
/// now, one carer or Ba and Mẹ together (owner 27/10/2026), shared with the family.
/// ended with "Kết thúc ca của tôi", or by receiving a handover. Written by the server only.
@immutable
class CareDuty {
  const CareDuty({
    this.uid,
    this.coCarerUid,
    this.since,
    this.previousUid,
    this.previousCoCarerUid,
    this.previousUntil,
  });
  final String? uid;
  final String? coCarerUid;
  final DateTime? since;
  final String? previousUid;
  final String? previousCoCarerUid;
  final DateTime? previousUntil;

  bool includes(String memberUid) =>
      uid == memberUid || coCarerUid == memberUid;

  static DateTime? _at(Object? v) => v is Timestamp ? v.toDate() : null;

  factory CareDuty.fromMap(Map<String, dynamic> m) => CareDuty(
    uid: m['uid'] as String?,
    coCarerUid: m['coCarerUid'] as String?,
    since: _at(m['since']),
    previousUid: m['previousUid'] as String?,
    previousCoCarerUid: m['previousCoCarerUid'] as String?,
    previousUntil: _at(m['previousUntil']),
  );
}

/// Who is on duty for [babyId] (null: nobody yet). Members who read care only.
final careDutyProvider = StreamProvider.family<CareDuty?, String>(
  (ref, babyId) => ref
      .watch(firestoreProvider)
      .doc('babies/$babyId/careDuty/current')
      .snapshots()
      .map((d) => d.exists ? CareDuty.fromMap(d.data()!) : null),
);

/// "Tôi trông bé" ([take]) or "Kết thúc ca của tôi"; the stream shows the change.
final careDutyWriterProvider =
    Provider<Future<void> Function(String babyId, {required bool take})>(
      (ref) =>
          (babyId, {required take}) => ref
              .read(functionsProvider)
              .httpsCallable('setCareDuty')
              .call<Object?>({
                'babyId': babyId,
                'action': take ? 'take' : 'end',
              }),
    );

final careDutyTogetherWriterProvider =
    Provider<Future<void> Function(String, String)>(
      (ref) => (babyId, coCarerUid) async {
        await ref
            .read(functionsProvider)
            .httpsCallable('setCareDuty')
            .call<Object?>({
              'babyId': babyId,
              'action': 'together',
              'coCarerUid': coCarerUid,
            });
      },
    );

String _dutyName(
  AppLocalizations l,
  CareDuty duty,
  List<Membership> members,
  String myUid,
) => duty.coCarerUid != null
    ? l.dutyParents
    : duty.uid == myUid
    ? l.familyYou
    : memberLabel(
        l,
        members.where((m) => m.uid == duty.uid).firstOrNull,
        myUid: myUid,
        uid: duty.uid,
      );

/// Without Adaptive Experience (no Tuỳ chỉnh switch): the same age rule as its band defaults,
/// on up to 6 years (and while the age is unknown).
bool careDutyByAge(AgeBand? band) => band != AgeBand.b6_12;

/// How long ago [since] is, for a chip: 12 h or more reads "from yesterday" and muted; 24 h or
/// more is not shown as current at all.
enum DutyAge { fresh, old, stale }

DutyAge dutyAge(DateTime since, DateTime now) {
  final h = now.difference(since).inHours;
  return h >= 24 ? DutyAge.stale : (h >= 12 ? DutyAge.old : DutyAge.fresh);
}

String _hhmm(String zone, DateTime t) =>
    DateFormat('HH:mm').format(inBabyZone(zone, t));

/// One visibility decision for the chip and its parent header, so hidden content leaves no gap.
final careDutyChipVisibleProvider = Provider<bool>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || !familyCan(me, FamilyAction.historyRead)) return false;
  final members = ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
  if (members
          .where((m) => m.isActive && familyCan(m, FamilyAction.rhythmFeedback))
          .length <
      2) {
    return false;
  }
  final state = ref.watch(careDutyProvider(me.babyId));
  if (!state.hasValue) return true;
  final duty = state.value;
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final current =
      duty?.uid != null &&
      duty?.since != null &&
      dutyAge(duty!.since!, now) != DutyAge.stale;
  return current || familyCan(me, FamilyAction.rhythmFeedback);
});

/// The Hôm nay chip under the title: "Bà Lan đang trông · từ 08:20". Nobody (or 24 h old):
/// "Chưa ai nhận trông bé" for a carer to take. Hidden from those who do not read care.
class CareDutyChip extends ConsumerWidget {
  const CareDutyChip({this.hero = false, super.key});
  final bool hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || !ref.watch(careDutyChipVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final state = ref.watch(careDutyProvider(me.babyId));
    if (!state.hasValue) {
      return Padding(
        padding: EdgeInsets.only(top: hero ? 0 : ClSpace.s3),
        child: state.hasError
            ? ClPressable(
                semanticLabel: l.hhDutyRetry,
                onPressed: () => ref.invalidate(careDutyProvider(me.babyId)),
                child: Text(
                  l.hhDutyRetry,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              )
            : const ClSkeleton(
                height: ClSpace.tapMin,
                width: 238,
                radius: ClRadius.pill,
              ),
      );
    }
    final duty = state.value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final on = duty?.uid != null && duty?.since != null
        ? dutyAge(duty!.since!, now)
        : DutyAge.stale;
    final canTake = familyCan(me, FamilyAction.rhythmFeedback);
    // Only a family with two people who care for the baby needs to know who is on now; a
    // single carer would see noise (senior-ui-ux §3).
    final carers = members
        .where((m) => m.isActive && familyCan(m, FamilyAction.rhythmFeedback))
        .length;
    if (carers < 2) return const SizedBox.shrink();
    if (on == DutyAge.stale && !canTake) return const SizedBox.shrink();
    final name = on == DutyAge.stale
        ? null
        : _dutyName(l, duty!, members, me.uid);
    final together = duty?.coCarerUid != null;
    final myself = !together && duty?.uid == me.uid;
    final currentLabel = together
        ? l.dutyTogetherNow
        : myself
        ? l.dutyYouNow
        : l.hhDutyNow(name ?? '');
    final text = together && on != DutyAge.stale
        ? l.dutyTogetherSince(_hhmm(zone, duty!.since!))
        : myself && on != DutyAge.stale
        ? l.dutyYouSince(_hhmm(zone, duty!.since!))
        : switch (on) {
            DutyAge.fresh => l.dutyOnNow(name!, _hhmm(zone, duty!.since!)),
            DutyAge.old => l.dutyOnSinceYesterday(name!),
            DutyAge.stale => l.dutyNobody,
          };
    return Padding(
      padding: EdgeInsets.only(top: hero ? 0 : ClSpace.s3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClPressable(
          key: const Key('careDutyChip'),
          onPressed: () => showCareDutySheet(context, ref, me),
          semanticLabel: hero && name != null ? '$currentLabel. $text' : text,
          child: Container(
            constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
            padding: const EdgeInsets.fromLTRB(6, 4, ClSpace.s3, 4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cl.colors.separator),
              boxShadow: hero ? cl.shadows.chip : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(
                  name: together ? null : name,
                  muted: on != DutyAge.fresh,
                ),
                const SizedBox(width: ClSpace.s2),
                Flexible(
                  child: hero && name != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              on == DutyAge.fresh || together
                                  ? l.hhDutySince(_hhmm(zone, duty!.since!))
                                  : l.dutyOnSinceYesterday(name),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                            Text(
                              currentLabel,
                              style: cl.text.bodyStrong.copyWith(
                                color: cl.colors.ink,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.label.copyWith(
                            color: on == DutyAge.fresh
                                ? cl.colors.ink
                                : cl.colors.inkMuted,
                          ),
                        ),
                ),
                const SizedBox(width: ClSpace.s1),
                ClIcon(
                  ClIcons.chevronRight,
                  size: 14,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Ai đang trông Teddy?": who is on duty and since when, who was before, and the one action
/// this person can take (take it, or end their own), then a link to Bàn giao.
Future<void> showCareDutySheet(
  BuildContext context,
  WidgetRef ref,
  Membership me,
) {
  return showClSheet<void>(
    context: context,
    builder: (sheet) => _DutySheet(me: me),
  );
}

class _DutySheet extends ConsumerStatefulWidget {
  const _DutySheet({required this.me});
  final Membership me;

  @override
  ConsumerState<_DutySheet> createState() => _DutySheetState();
}

enum _DutyAction { take, together, end }

class _DutySheetState extends ConsumerState<_DutySheet> {
  _DutyAction? _pending;
  CareDuty? _dutyAtSubmit;
  Membership get me => widget.me;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final state = ref.watch(careDutyProvider(me.babyId));
    final duty = _pending != null ? _dutyAtSubmit : state.value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final current =
        duty?.uid != null &&
            duty?.since != null &&
            dutyAge(duty!.since!, now) != DutyAge.stale
        ? duty
        : null;
    final mine = current?.includes(me.uid) == true;
    // D-135 Q1: only a helper takes or ends a shift; Ba and Mẹ care equally and never do.
    final canTake = me.role == MemberRole.caregiver;
    final opposite = switch (me.relation) {
      Relation.mother => Relation.father,
      Relation.father => Relation.mother,
      _ => null,
    };
    final parents = members
        .where(
          (m) =>
              m.uid != me.uid &&
              m.relation == opposite &&
              opposite != null &&
              m.isActive &&
              familyCan(m, FamilyAction.rhythmFeedback),
        )
        .toList();
    // Do not guess a partner if there are multiple matching memberships.
    final coCarer = parents.length == 1 ? parents.single : null;
    final ready = state.hasValue;
    final busy = _pending != null;
    // D-135 Q1 retired "Ba và Mẹ cùng trông" (parents hold no duty); kept for a pending call.
    final showTogether = _pending == _DutyAction.together && coCarer != null;
    String name(String uid) => memberLabel(
      l,
      members.where((m) => m.uid == uid).firstOrNull,
      myUid: me.uid,
      uid: uid,
    );
    Widget row(
      String who,
      String detail, {
      String? duration,
      bool active = false,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: who, muted: !active),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(who, style: active ? cl.text.headline : cl.text.bodyStrong),
              const SizedBox(height: ClSpace.s1),
              Wrap(
                spacing: ClSpace.s2,
                runSpacing: ClSpace.s1,
                children: [
                  ClTabularText(
                    detail,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                  if (duration != null)
                    ClTabularText(
                      duration,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l.dutySheetTitle(baby?.nickname ?? '')),
        if (!ready) ...[
          if (state.hasError) ...[
            Text(l.dutyLoadFailed, style: cl.text.body),
            ClButton(
              wrapLabel: true,
              label: l.actionRetry,
              style: ClButtonStyle.plain,
              onPressed: () => ref.invalidate(careDutyProvider(me.babyId)),
            ),
          ] else
            const ClSkeleton(height: ClSpace.tapMin),
        ] else ...[
          if (current != null)
            row(
              _dutyName(l, current, members, me.uid),
              l.dutyStartedAt(_hhmm(zone, current.since!)),
              duration: now.difference(current.since!).inMinutes < 1
                  ? l.dutyJustStarted
                  : durationLabel(l, now.difference(current.since!).inMinutes),
              active: true,
            )
          else
            Text(
              l.dutyNobodyBody,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          if (duty?.previousUid case final prev?
              when duty?.previousUntil != null &&
                  (duty?.previousCoCarerUid != null ||
                      current?.includes(prev) != true)) ...[
            const SizedBox(height: ClSpace.s4),
            Text(
              l.dutyPrevious,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            row(
              duty?.previousCoCarerUid != null ? l.dutyParents : name(prev),
              l.dutyStateUntil(_hhmm(zone, duty!.previousUntil!)),
            ),
          ],
          const SizedBox(height: ClSpace.s6),
          if (canTake && !mine)
            ClButton(
              wrapLabel: true,
              key: const Key('careDutyTake'),
              label: l.dutyTake,
              expand: true,
              loading: _pending == _DutyAction.take,
              onPressed: busy ? null : () => _write(_DutyAction.take),
            ),
          if (showTogether) ...[
            if (!mine) const SizedBox(height: ClSpace.s2),
            ClButton(
              wrapLabel: true,
              key: const Key('careDutyTogether'),
              label: l.dutyTogether,
              expand: true,
              style: mine ? ClButtonStyle.primary : ClButtonStyle.secondary,
              loading: _pending == _DutyAction.together,
              onPressed: busy
                  ? null
                  : () => _write(_DutyAction.together, coCarerUid: coCarer.uid),
            ),
          ],
          if (mine) ...[
            if (showTogether) const SizedBox(height: ClSpace.s2),
            ClButton(
              wrapLabel: true,
              key: const Key('careDutyEnd'),
              label: l.dutyEnd,
              expand: true,
              style: ClButtonStyle.secondary,
              loading: _pending == _DutyAction.end,
              onPressed: busy ? null : () => _write(_DutyAction.end),
            ),
            if (current?.coCarerUid != null) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l.dutyOwnPart,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ],
        ],
        const SizedBox(height: ClSpace.s2),
        ClButton(
          wrapLabel: true,
          label: l.dutyOpenHandover,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: busy
              ? null
              : () {
                  Navigator.of(context).pop();
                  context.push(Routes.rhythmHandover);
                },
        ),
      ],
    );
  }

  Future<void> _write(_DutyAction action, {String? coCarerUid}) async {
    if (_pending != null) return;
    final l = AppLocalizations.of(context);
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    final toaster = ClToaster.of(context);
    setState(() {
      _dutyAtSubmit = ref.read(careDutyProvider(me.babyId)).value;
      _pending = action;
    });
    try {
      if (action == _DutyAction.together) {
        await ref.read(careDutyTogetherWriterProvider)(me.babyId, coCarerUid!);
      } else {
        await ref.read(careDutyWriterProvider)(
          me.babyId,
          take: action == _DutyAction.take,
        );
      }
      if (!mounted || route?.isCurrent != true) return;
      navigator.pop();
      toaster.show(
        message: switch (action) {
          _DutyAction.take => l.dutyTakenToast,
          _DutyAction.together => l.dutyTogetherToast,
          _DutyAction.end => l.dutyEndedToast,
        },
      );
    } on Object {
      if (mounted && route?.isCurrent == true) {
        toaster.show(message: l.dutyFailed, error: true);
      }
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }
}

/// The Bàn giao line on top: "Đang trông · Mẹ · từ 06:40 · 3 giờ" (or nobody yet); tapping it
/// opens the same sheet.
class CareDutyLine extends ConsumerWidget {
  const CareDutyLine({required this.me, super.key});
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final duty = ref.watch(careDutyProvider(me.babyId)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final on =
        duty?.uid != null &&
        duty?.since != null &&
        dutyAge(duty!.since!, now) != DutyAge.stale;
    final name = on ? _dutyName(l, duty, members, me.uid) : null;
    return ClPressable(
      key: const Key('careDutyLine'),
      onPressed: () => showCareDutySheet(context, ref, me),
      semanticLabel: l.dutyLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          border: Border.all(color: cl.colors.separator),
        ),
        child: Row(
          children: [
            _Avatar(name: name, muted: !on),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.dutyLabel,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                  Text(
                    on
                        ? l.dutyLine(
                            name!,
                            _hhmm(zone, duty.since!),
                            durationLabel(
                              l,
                              now.difference(duty.since!).inMinutes,
                            ),
                          )
                        : l.dutyNobody,
                    style: on
                        ? cl.text.bodyStrong
                        : cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.muted = false});
  final String? name;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final initial = name == null || name!.isEmpty
        ? null
        : name!.characters.first.toUpperCase();
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted ? cl.colors.surface2 : cl.colors.mintSoft,
        shape: BoxShape.circle,
      ),
      child: initial == null
          ? ClIcon(ClIcons.family, size: 14, color: cl.colors.inkMuted)
          : Text(
              initial,
              style: cl.text.caption.copyWith(
                color: muted ? cl.colors.inkMuted : cl.colors.mintText,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
