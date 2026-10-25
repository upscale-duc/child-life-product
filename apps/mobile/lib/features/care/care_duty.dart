import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
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
/// now, one person per baby, the same on every phone of the family. Taken with "Tôi trông bé",
/// ended with "Kết thúc ca của tôi", or by receiving a handover. Written by the server only.
@immutable
class CareDuty {
  const CareDuty({this.uid, this.since, this.previousUid, this.previousUntil});
  final String? uid;
  final DateTime? since;
  final String? previousUid;
  final DateTime? previousUntil;

  static DateTime? _at(Object? v) => v is Timestamp ? v.toDate() : null;

  factory CareDuty.fromMap(Map<String, dynamic> m) => CareDuty(
    uid: m['uid'] as String?,
    since: _at(m['since']),
    previousUid: m['previousUid'] as String?,
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

/// How long ago [since] is, for a chip: 12 h or more reads "from yesterday" and muted; 24 h or
/// more is not shown as current at all.
enum DutyAge { fresh, old, stale }

DutyAge dutyAge(DateTime since, DateTime now) {
  final h = now.difference(since).inHours;
  return h >= 24 ? DutyAge.stale : (h >= 12 ? DutyAge.old : DutyAge.fresh);
}

String _hhmm(String zone, DateTime t) =>
    DateFormat('HH:mm').format(inBabyZone(zone, t));

/// The Hôm nay chip under the title: "Bà Lan đang trông · từ 08:20". Nobody (or 24 h old):
/// "Chưa ai nhận trông bé" for a carer to take. Hidden from those who do not read care.
class CareDutyChip extends ConsumerWidget {
  const CareDutyChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || !familyCan(me, FamilyAction.historyRead)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final duty = ref.watch(careDutyProvider(me.babyId)).value;
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
        : memberLabel(
            l,
            members.where((m) => m.uid == duty!.uid).firstOrNull,
            myUid: me.uid,
            uid: duty!.uid!,
          );
    final text = switch (on) {
      DutyAge.fresh => l.dutyOnNow(name!, _hhmm(zone, duty!.since!)),
      DutyAge.old => l.dutyOnSinceYesterday(name!),
      DutyAge.stale => l.dutyNobody,
    };
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClPressable(
          key: const Key('careDutyChip'),
          onPressed: () => showCareDutySheet(context, ref, me),
          semanticLabel: text,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.fromLTRB(6, 4, ClSpace.s3, 4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cl.colors.separator),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(name: name, muted: on != DutyAge.fresh),
                const SizedBox(width: ClSpace.s2),
                Flexible(
                  child: Text(
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

class _DutySheet extends ConsumerWidget {
  const _DutySheet({required this.me});
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final duty = ref.watch(careDutyProvider(me.babyId)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    String name(String uid) => memberLabel(
      l,
      members.where((m) => m.uid == uid).firstOrNull,
      myUid: me.uid,
      uid: uid,
    );
    final current =
        duty?.uid != null &&
            duty?.since != null &&
            dutyAge(duty!.since!, now) != DutyAge.stale
        ? duty
        : null;
    final mine = current?.uid == me.uid;
    final canTake = familyCan(me, FamilyAction.rhythmFeedback);
    Widget row(String who, String state, {bool on = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
      child: Row(
        children: [
          _Avatar(name: who, muted: !on),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(who, style: on ? cl.text.bodyStrong : cl.text.body),
          ),
          Text(
            state,
            style: cl.text.label.copyWith(
              color: on ? cl.colors.mintText : cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    );
    return Padding(
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
          ClSheetHeader(title: l.dutySheetTitle(baby?.nickname ?? '')),
          if (current != null)
            row(
              name(current.uid!),
              l.dutyStateOn(
                _hhmm(zone, current.since!),
                durationLabel(l, now.difference(current.since!).inMinutes),
              ),
              on: true,
            )
          else
            Text(
              l.dutyNobodyBody,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          if (duty?.previousUid case final prev?
              when prev != current?.uid && duty?.previousUntil != null)
            row(
              name(prev),
              l.dutyStateUntil(_hhmm(zone, duty!.previousUntil!)),
            ),
          const SizedBox(height: ClSpace.s4),
          if (canTake && !mine)
            ClButton(
              key: const Key('careDutyTake'),
              label: l.dutyTake,
              expand: true,
              onPressed: () => _write(context, ref, take: true),
            ),
          if (mine)
            ClButton(
              key: const Key('careDutyEnd'),
              label: l.dutyEnd,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () => _write(context, ref, take: false),
            ),
          const SizedBox(height: ClSpace.s2),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.rhythmHandover);
              },
              child: Text(l.dutyOpenHandover),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _write(
    BuildContext context,
    WidgetRef ref, {
    required bool take,
  }) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final toaster = ClToaster.of(context);
    try {
      await ref.read(careDutyWriterProvider)(me.babyId, take: take);
      navigator.pop();
      toaster.show(message: take ? l.dutyTakenToast : l.dutyEndedToast);
    } on Object {
      toaster.show(message: l.dutyFailed, error: true);
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
    final name = on
        ? memberLabel(
            l,
            members.where((m) => m.uid == duty.uid).firstOrNull,
            myUid: me.uid,
            uid: duty.uid!,
          )
        : null;
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
