import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/growth_reference.dart';
import '../care/who_growth.dart';
import '../home/home_shell.dart';
import '../vaccines/vaccine_repository.dart' show vaccinePlanProvider;
import 'nutrition_calc.dart';
import 'nutrition_models.dart';
import 'nutrition_repository.dart';

/// The selected baby as Dinh dưỡng uses it. [dob] is null when it is unknown to this member;
/// caregivers read the date of birth Cùng nuôi keep for them on the vaccine plan (P-133). [boy] is
/// null when the sex is not known (no WHO position then).
typedef NuBaby = ({
  String babyId,
  String uid,
  String name,
  DateTime? dob,
  bool? boy,
  DateTime now,
  DateTime today,
  String zone,
  MemberRole role,
});

extension NuBabyRoles on NuBaby {
  /// Cùng nuôi: growth card, banner, 9e, vitamin A "Đã uống" and "Đặt nhắc" (P-163 #8).
  bool get coParent => role == MemberRole.coParent;
}

final nuBabyProvider = Provider<NuBaby?>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  final profile = me.canViewBabyInfo
      ? ref.watch(babyPrivateProfileProvider(me.babyId)).value
      : null;
  // BabyPrivateProfile falls back to 2000-01-01 for an unreadable date: treat it as missing.
  final own = profile == null || profile.dateOfBirth.year < 2005
      ? null
      : profile.dateOfBirth;
  final dob =
      own ??
      (me.role == MemberRole.caregiver
          ? ref.watch(vaccinePlanProvider(me.babyId)).value?.scheduleFrom
          : null);
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  return (
    babyId: me.babyId,
    uid: me.uid,
    name: baby?.nickname ?? '',
    dob: dob == null ? null : DateTime(dob.year, dob.month, dob.day),
    boy: switch (profile?.gender) {
      Gender.boy => true,
      Gender.girl => false,
      _ => null,
    },
    now: now,
    today: babyToday(zone, now),
    zone: zone,
    role: me.role,
  );
});

/// Published content for the selected baby: stages in order, the current one, nutrients by id
/// and the rules.
typedef NuContent = ({
  NuBaby baby,
  List<NuStage> stages,
  Map<String, NuNutrient> nutrients,
  List<NuRule> rules,

  /// Completed months, when the date of birth is known.
  int? months,
  NuStage? stage,

  /// Past the last stage (P-163 #9).
  bool past,
  bool loading,
});

final nuContentProvider = Provider<NuContent?>((ref) {
  final baby = ref.watch(nuBabyProvider);
  if (baby == null) return null;
  final stagesFeed = ref.watch(nuStagesProvider);
  final stages = nuSortStages(stagesFeed.value?.items ?? const []);
  final nutrients = {
    for (final n
        in ref.watch(nuNutrientsProvider).value?.items ?? <NuNutrient>[])
      n.id: n,
  };
  final rules = ref.watch(nuRulesProvider).value?.items ?? const <NuRule>[];
  final dob = baby.dob;
  final months = dob == null ? null : nuMonthsOld(dob, baby.today);
  final hit = months == null ? null : nuStageFor(stages, months);
  return (
    baby: baby,
    stages: stages,
    nutrients: nutrients,
    rules: rules,
    months: months,
    stage: hit?.stage,
    past: hit?.past ?? false,
    loading: stagesFeed.isLoading && stages.isEmpty,
  );
});

/// The 9a tile: live once a published stage covers the baby's age (D-076 like Giai đoạn của bé,
/// no flag); "Cần ngày sinh của bé" without a date of birth; a teaser otherwise (P-163 #11).
sealed class NuTile {
  const NuTile();
}

class NuTileTeaser extends NuTile {
  const NuTileTeaser();
}

class NuTileNoDob extends NuTile {
  const NuTileNoDob();
}

class NuTileLive extends NuTile {
  const NuTileLive(this.stage);
  final NuStage stage;
}

final nuTileProvider = Provider<NuTile>((ref) {
  final c = ref.watch(nuContentProvider);
  if (c == null || c.stages.isEmpty) return const NuTileTeaser();
  if (c.baby.dob == null) return const NuTileNoDob();
  final stage = c.stage;
  return stage == null ? const NuTileTeaser() : NuTileLive(stage);
});

/// The baby's own data for 9b / 9c / 9e: bottle totals of the last 14 local days, the 7-day
/// average, the growth measurements against WHO and what the rules match (evaluated on the
/// device, P-163).
typedef NuData = ({
  List<int> daily,
  int? average,
  List<NuMeasure> weights,
  List<NuMeasure> lengths,
  List<CareRecord> growth,
  DateTime? lastMeasured,
  NuSignals signals,
});

final nuDataProvider = Provider<NuData?>((ref) {
  final c = ref.watch(nuContentProvider);
  if (c == null) return null;
  final b = c.baby;
  final first = babyDateBounds(
    b.zone,
    DateTime(b.today.year, b.today.month, b.today.day - 13),
  ).start;
  final end = babyDateBounds(b.zone, b.today).end;
  final records =
      ref.watch(rangeRecordsProvider((b.babyId, first, end))).value ??
      const <CareRecord>[];
  final daily = nuDailyBottleMl(records, b.zone, b.today);
  final average = nuMilkAverage(daily);
  // Growth is Cùng nuôi's (caregivers have no growth tile, P-163 #8).
  final growth = b.coParent
      ? ref.watch(growthRecordsProvider(b.babyId)).value ?? const <CareRecord>[]
      : const <CareRecord>[];
  final reference = ref.watch(growthReferenceProvider);
  final weights = nuMeasures(
    growth,
    GrowthMeasure.weight,
    dob: b.dob,
    boy: b.boy,
    reference: reference,
  );
  final lengths = nuMeasures(
    growth,
    GrowthMeasure.length,
    dob: b.dob,
    boy: b.boy,
    reference: reference,
  );
  final latest = [?weights.firstOrNull?.on, ?lengths.firstOrNull?.on]..sort();
  final dob = b.dob;
  final months = c.months;
  final signals = dob == null || months == null
      ? nuNoSignals
      : nuEvaluate(
          rules: c.rules,
          months: months,
          dob: dob,
          today: b.today,
          weights: weights,
          lengths: lengths,
          milkAverage: average,
          milkBand: c.stage?.milk?.perDayMl,
          lastMeasured: latest.lastOrNull,
        );
  return (
    daily: daily,
    average: average,
    weights: weights,
    lengths: lengths,
    growth: growth,
    lastMeasured: latest.lastOrNull,
    signals: (
      // Caregivers see no growth banner, card or 9e (P-163 #8).
      growth: b.coParent ? signals.growth : const <NuRule>[],
      milk: signals.milk,
      noMeasurement: b.coParent ? signals.noMeasurement : null,
    ),
  );
});
