import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show babyToday, careClockProvider;
import '../home/home_shell.dart';
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_models.dart' show Interest;
import '../today/today_for_baby.dart';
import 'milestone_models.dart';
import 'milestone_repository.dart';
import 'milestone_screens.dart';
import 'milestone_widgets.dart' show rangeLabel;

/// Hôm nay · "Dành cho bé hôm nay" small cards from Mốc phát triển (D-076 #4 / #6), fed to
/// `milestoneForBabyCardsProvider` in `today/today_for_baby.dart`: up to two reference
/// milestones whose window holds today and that the family has not recorded ("Mốc có thể thấy ·
/// tham khảo 1–3 tháng"). Needs the date of birth (`canViewBabyInfo`); a Cùng nuôi is asked to
/// record it, others to read how to recognise it. Never "late": past windows never show here.
final mtForBabyCardsProvider = Provider.family<List<ForBabyCard>, ForBabyQuery>((
  ref,
  q,
) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || me.babyId != q.babyId || !me.canViewBabyInfo) {
    return const [];
  }
  final dob = ref
      .watch(babyPrivateProfileProvider(me.babyId))
      .value
      ?.dateOfBirth;
  final reference = ref.watch(referenceMilestonesProvider).value;
  if (dob == null || reference == null || reference.isEmpty) return const [];
  final parent = familyCan(me, FamilyAction.momentsCreate);
  final records = parent
      ? ref.watch(milestoneRecordsProvider(me.babyId)).value
      : const <MilestoneRecord>[];
  // Records not loaded yet: nothing rather than a card for something already recorded.
  if (records == null) return const [];
  final zone =
      ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
      'Asia/Ho_Chi_Minh';
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final board = MilestoneBoard(
    reference: reference,
    records: records,
    dob: dob,
    today: babyToday(zone, now),
  );
  final l10n = lookupAppLocalizations(Locale(q.languageCode));
  return [
    for (final m in board.forToday.take(2))
      ForBabyCard(
        id: 'milestone:${m.id}',
        priority: 4,
        kicker: l10n.mtTodayKicker(rangeLabel(l10n, m.ageRange)),
        title: m.title.of(q.languageCode),
        action: parent ? l10n.mtTodayAction : l10n.mtTodayActionViewer,
        icon: switch (m.group) {
          MilestoneGroup.communication => ClIcons.heart,
          MilestoneGroup.motor => ClIcons.ruler,
          MilestoneGroup.cognitive => ClIcons.spark,
          MilestoneGroup.socialEmotional => ClIcons.family,
        },
        tone: switch (m.group) {
          MilestoneGroup.communication => ForBabyTone.peach,
          MilestoneGroup.motor => ForBabyTone.growth,
          MilestoneGroup.cognitive => ForBabyTone.sleep,
          MilestoneGroup.socialEmotional => ForBabyTone.mint,
        },
        interest: Interest.milestones,
        onOpen: (context) => context.push(milestoneLocation(m.id)),
      ),
  ];
});
