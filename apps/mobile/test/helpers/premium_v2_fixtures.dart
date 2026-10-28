import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../features/premium_test.dart' show answer;
import 'family_fixtures.dart';
import 'premium_fixtures.dart';

/// Premium v2 (Figma 958:13863, D-101) without Firebase: the household with `premium_v2` on, a
/// family plan as `getFamilyPlan` answers it and a fake API that records the seat choice.

const _gb = 1024 * 1024 * 1024;

/// A Free family (PV40B): 2 of 30 trial credits left, 2/2 exports used, 0,9 of 1 GB.
final freePlan = FamilyPlanV2(
  v2: true,
  premium: false,
  isManager: true,
  lumi: const PlanBalance(limit: 30, used: 28),
  video: const PlanBalance(limit: 2, used: 2),
  usedBytes: (0.9 * _gb).round(),
  limitBytes: _gb,
  seatsUsed: 3,
  seatsLimit: 3,
  addOns: const [
    StorageAddOn(
      id: 'storage_20',
      gb: 20,
      vn: PlanPrice(month: 39000, year: 399000),
      intl: PlanPrice(month: 1.99, year: 19.99),
    ),
    StorageAddOn(
      id: 'storage_50',
      gb: 50,
      vn: PlanPrice(month: 79000, year: 799000),
      intl: PlanPrice(month: 3.99, year: 39.99),
    ),
  ],
);

/// A Premium family (PV40): 132 / 200 credits, 3 / 4 exports, 6,2 / 10 GB; refills 24/11.
final premiumPlan = FamilyPlanV2(
  v2: true,
  premium: true,
  isManager: true,
  lumi: PlanBalance(
    limit: 200,
    used: 68,
    resetsAt: DateTime.utc(2026, 11, 24, 3),
  ),
  video: PlanBalance(
    limit: 4,
    used: 1,
    resetsAt: DateTime.utc(2026, 11, 24, 3),
  ),
  usedBytes: (6.2 * _gb).round(),
  limitBytes: 10 * _gb,
  seatsUsed: 3,
  seatsLimit: 6,
  cycleEnd: DateTime.utc(2026, 11, 24, 3),
  validUntil: DateTime.utc(2027, 10, 24, 3),
  premiumTemplates: true,
  addOns: freePlan.addOns,
);

/// After a downgrade (PV43): over storage and over seats, the manager has to choose.
final downgradedPlan = FamilyPlanV2(
  v2: true,
  premium: false,
  isManager: true,
  lumi: const PlanBalance(limit: 30, used: 30),
  video: const PlanBalance(limit: 2, used: 2),
  usedBytes: (6.2 * _gb).round(),
  limitBytes: _gb,
  seatsUsed: 5,
  seatsLimit: 3,
  overLimit: true,
);

/// [plan] as a member sees it (PV45).
FamilyPlanV2 asMember(FamilyPlanV2 plan) => FamilyPlanV2(
  v2: plan.v2,
  premium: plan.premium,
  isManager: false,
  lumi: plan.lumi,
  video: plan.video,
  usedBytes: plan.usedBytes,
  limitBytes: plan.limitBytes,
  seatsUsed: plan.seatsUsed,
  seatsLimit: plan.seatsLimit,
  cycleEnd: plan.cycleEnd,
  validUntil: plan.validUntil,
);

final usageRows = [
  UsageRow(
    id: 'op1',
    kind: 'lumi',
    task: 'lumi.summary',
    uid: 'u_minh',
    amount: -5,
    state: 'debited',
    at: DateTime.utc(2026, 10, 24, 14, 14),
  ),
  UsageRow(
    id: 'op2',
    kind: 'video',
    task: 'video.export',
    uid: 'u_mai',
    amount: -1,
    state: 'debited',
    at: DateTime.utc(2026, 10, 24, 13, 2),
  ),
  UsageRow(
    id: 'w1',
    kind: 'grant',
    task: 'lumi.cycle',
    amount: 200,
    state: 'granted',
    at: DateTime.utc(2026, 10, 24, 3),
  ),
  UsageRow(
    id: 'op3',
    kind: 'refund',
    task: 'lumi.chat',
    amount: 2,
    state: 'refunded',
    at: DateTime.utc(2026, 10, 22, 1, 31),
  ),
  UsageRow(
    id: 'op4',
    kind: 'lumi',
    task: 'lumi.chat',
    uid: 'u_lan',
    amount: -1,
    state: 'held',
    at: DateTime.utc(2026, 10, 21, 2),
  ),
];

class FakePremiumV2Api implements PremiumV2Api {
  FakePremiumV2Api(this.plan);
  FamilyPlanV2? plan;
  final kept = <List<String>>[];

  @override
  Future<FamilyPlanV2?> familyPlan(String babyId) async => plan;

  @override
  Future<({List<UsageRow> rows, bool everyone})> usageHistory(
    String babyId, {
    UsageFilter filter = UsageFilter.all,
    bool everyone = false,
  }) async => (
    rows: [
      for (final r in usageRows)
        if (everyone || r.uid == null || r.uid == 'u_mai')
          if (switch (filter) {
            UsageFilter.all => true,
            UsageFilter.lumi => r.task.startsWith('lumi') && r.kind != 'grant',
            UsageFilter.video =>
              r.task.startsWith('video') && r.kind != 'grant',
            UsageFilter.grants => r.kind == 'grant',
          })
            r,
    ],
    everyone: everyone,
  );

  @override
  Future<int> chooseWriteSeats(String babyId, List<String> keep) async {
    kept.add(keep);
    return 0;
  }
}

/// The caps answer with `premium_v2` on.
Map<String, Object?> v2Answer({
  String plan = 'free',
  bool owner = true,
  String? provider,
  String? validUntil,
}) {
  final a = answer(
    plan: plan,
    owner: owner,
    templates: plan == 'premium',
    provider: provider,
    validUntil: validUntil,
  );
  return {
    ...a,
    'features': {...(a['features']! as Map), 'premiumV2': true},
  };
}

/// Everything a Premium v2 screen reads, for one test.
List<Override> premiumV2Overrides({
  required FamilyPlanV2? plan,
  Map<String, Object?>? caps,
  Membership? me,
  List<Membership>? members,
  FakePremiumV2Api? api,
  Future<FamilyPlanV2?> Function()? loadPlan,
}) {
  final fake = api ?? FakePremiumV2Api(plan);
  return [
    selectedMembershipProvider.overrideWithValue(me ?? mai),
    babyProvider.overrideWith((ref, id) => Stream.value(teddy)),
    familyMembersProvider.overrideWith(
      (ref, id) => Stream.value(members ?? [mai, minh, lan, hoa]),
    ),
    ...premiumOverrides(household: FakeHousehold(caps ?? v2Answer())),
    premiumV2ApiProvider.overrideWithValue(fake),
    familyPlanV2Provider.overrideWith(
      (ref, id) => loadPlan?.call() ?? Future.value(fake.plan),
    ),
    usageHistoryProvider.overrideWith(
      (ref, q) =>
          fake.usageHistory(q.babyId, filter: q.filter, everyone: q.everyone),
    ),
  ];
}
