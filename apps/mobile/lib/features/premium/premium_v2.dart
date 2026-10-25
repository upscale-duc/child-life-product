import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Premium v2 (Figma 958:13863, D-101) on the phone: the family's plan with its limits and
/// balances (`getFamilyPlan`), the usage history (`familyUsageHistory`, PV41) and the seat picker
/// (`chooseFamilyWriteSeats`, PV44). Balances are for the plan screens only, never on buttons or
/// in Lumi's header (D-081, Q-098). In-app purchase comes later: nothing here charges anyone.

/// The six cards of the paywall carousel (Component · Premium · Thẻ tính năng) and the entry
/// card that opens it first (PV00C).
enum PremiumCard {
  video,
  card,
  lumi,
  rhythm,
  storage,
  caregivers;

  static PremiumCard? fromWire(Object? v) =>
      values.where((e) => e.name == v).firstOrNull;
}

/// What the paywall says it is for. Two kinds (owner, 2026-10-25; Note · PW01 / PW06):
/// [explore] is the user choosing to look at Premium (Tôi, Gói của gia đình › Xem các gói):
/// the general headline, no reason line, the Video card first, no "Bạn đang cần". Every other
/// value is an entry point that needs Premium: its own headline, the small line saying what is
/// kept, its card first and the tag on its row. [rhythm] (Nhịp lớn lên) is not drawn in Figma;
/// its copy is engineering's.
enum PremiumEntry {
  video,
  card,
  lumi,
  rhythm,
  storage,
  caregivers,
  explore;

  static PremiumEntry fromWire(Object? v) =>
      values.where((e) => e.name == v).firstOrNull ?? PremiumEntry.explore;

  PremiumCard get firstCard => switch (this) {
    PremiumEntry.video || PremiumEntry.explore => PremiumCard.video,
    PremiumEntry.card => PremiumCard.card,
    PremiumEntry.lumi => PremiumCard.lumi,
    PremiumEntry.rhythm => PremiumCard.rhythm,
    PremiumEntry.storage => PremiumCard.storage,
    PremiumEntry.caregivers => PremiumCard.caregivers,
  };
}

@immutable
class PlanBalance {
  const PlanBalance({
    required this.limit,
    required this.used,
    this.reserved = 0,
    this.resetsAt,
  });

  factory PlanBalance.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    return PlanBalance(
      limit: (m['limit'] as num?)?.toInt() ?? 0,
      used: (m['used'] as num?)?.toInt() ?? 0,
      reserved: (m['reserved'] as num?)?.toInt() ?? 0,
      resetsAt: DateTime.tryParse('${m['resetsAt']}'),
    );
  }

  final int limit;
  final int used;
  final int reserved;

  /// When it refills (a Premium cycle); null for a Free one-time allowance.
  final DateTime? resetsAt;

  int get left => (limit - used - reserved).clamp(0, limit);
  double get usedRatio =>
      limit <= 0 ? 1 : ((used + reserved) / limit).clamp(0, 1);
}

@immutable
class PlanPrice {
  const PlanPrice({required this.month, required this.year});
  factory PlanPrice.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    return PlanPrice(
      month: (m['month'] as num?) ?? 0,
      year: (m['year'] as num?) ?? 0,
    );
  }
  final num month;
  final num year;
}

@immutable
class StorageAddOn {
  const StorageAddOn({
    required this.id,
    required this.gb,
    required this.vn,
    required this.intl,
  });
  final String id;
  final int gb;
  final PlanPrice vn;
  final PlanPrice intl;
}

/// One plan as configured (the paywall comparison, PV42).
@immutable
class PlanOffer {
  const PlanOffer({
    required this.lumiCredits,
    required this.videoExports,
    required this.storageBytes,
    required this.caregiverSeats,
  });

  factory PlanOffer.fromJson(Object? raw, PlanOffer fallback) {
    if (raw is! Map) return fallback;
    return PlanOffer(
      lumiCredits:
          (raw['lumiCredits'] as num?)?.toInt() ?? fallback.lumiCredits,
      videoExports:
          (raw['videoExports'] as num?)?.toInt() ?? fallback.videoExports,
      storageBytes:
          (raw['storageBytes'] as num?)?.toInt() ?? fallback.storageBytes,
      caregiverSeats:
          (raw['caregiverSeats'] as num?)?.toInt() ?? fallback.caregiverSeats,
    );
  }

  final int lumiCredits;
  final int videoExports;
  final int storageBytes;
  final int caregiverSeats;

  static const _gb = 1024 * 1024 * 1024;

  /// PV00 "entitlements 2.0-launch", while the answer is not here yet.
  static const free = PlanOffer(
    lumiCredits: 30,
    videoExports: 2,
    storageBytes: _gb,
    caregiverSeats: 3,
  );
  static const premium = PlanOffer(
    lumiCredits: 200,
    videoExports: 4,
    storageBytes: 10 * _gb,
    caregiverSeats: 6,
  );
}

/// `getFamilyPlan` (PV40 / PV40B / PV45).
@immutable
class FamilyPlanV2 {
  const FamilyPlanV2({
    required this.v2,
    required this.premium,
    required this.isManager,
    required this.lumi,
    required this.video,
    required this.usedBytes,
    required this.limitBytes,
    required this.seatsUsed,
    required this.seatsLimit,
    this.addOnGb = 0,
    this.cycleEnd,
    this.validUntil,
    this.suspended = const [],
    this.overLimit = false,
    this.premiumTemplates = false,
    this.priceVn = const PlanPrice(month: 59000, year: 599000),
    this.priceIntl = const PlanPrice(month: 5.99, year: 49.99),
    this.addOns = const [],
    this.free = PlanOffer.free,
    this.premiumOffer = PlanOffer.premium,
  });

  factory FamilyPlanV2.fromJson(Map<String, dynamic> j) {
    final storage = j['storage'] is Map ? j['storage'] as Map : const {};
    final seats = j['seats'] is Map ? j['seats'] as Map : const {};
    final cycle = j['cycle'] is Map ? j['cycle'] as Map : null;
    final prices = j['prices'] is Map ? j['prices'] as Map : const {};
    final offer = j['offer'] is Map ? j['offer'] as Map : const {};
    return FamilyPlanV2(
      v2: j['v2'] == true,
      premium: j['plan'] == 'premium',
      isManager: j['isManager'] == true,
      lumi: PlanBalance.fromJson(j['lumi']),
      video: PlanBalance.fromJson(j['video']),
      usedBytes: (storage['usedBytes'] as num?)?.toInt() ?? 0,
      limitBytes: (storage['limitBytes'] as num?)?.toInt() ?? 0,
      addOnGb: (storage['addOnGb'] as num?)?.toInt() ?? 0,
      seatsUsed: (seats['used'] as num?)?.toInt() ?? 0,
      seatsLimit: (seats['limit'] as num?)?.toInt() ?? 0,
      suspended: [
        for (final s in (seats['suspended'] as List?) ?? const [])
          if (s is String) s,
      ],
      overLimit: seats['overLimit'] == true,
      cycleEnd: cycle == null ? null : DateTime.tryParse('${cycle['end']}'),
      validUntil: DateTime.tryParse('${j['validUntil']}'),
      premiumTemplates: j['premiumTemplates'] == true,
      free: PlanOffer.fromJson(offer['free'], PlanOffer.free),
      premiumOffer: PlanOffer.fromJson(offer['premium'], PlanOffer.premium),
      priceVn: PlanPrice.fromJson(prices['vn']),
      priceIntl: PlanPrice.fromJson(prices['intl']),
      addOns: [
        for (final a in (j['storageAddOns'] as List?) ?? const [])
          if (a is Map)
            StorageAddOn(
              id: '${a['id']}',
              gb: (a['gb'] as num?)?.toInt() ?? 0,
              vn: PlanPrice.fromJson((a['price'] as Map?)?['vn']),
              intl: PlanPrice.fromJson((a['price'] as Map?)?['intl']),
            ),
      ],
    );
  }

  final bool v2;
  final bool premium;
  final bool isManager;
  final PlanBalance lumi;
  final PlanBalance video;
  final int usedBytes;
  final int limitBytes;
  final int addOnGb;
  final int seatsUsed;
  final int seatsLimit;

  /// Writers left out after a downgrade (PV44): view-only, never removed.
  final List<String> suspended;

  /// More writers than seats (after a downgrade): the manager has a choice to make (PV43).
  final bool overLimit;
  final DateTime? cycleEnd;
  final DateTime? validUntil;
  final bool premiumTemplates;
  final PlanPrice priceVn;
  final PlanPrice priceIntl;
  final List<StorageAddOn> addOns;
  final PlanOffer free;
  final PlanOffer premiumOffer;

  bool get storageOver => limitBytes > 0 && usedBytes > limitBytes;
  double get storageRatio =>
      limitBytes <= 0 ? 1 : (usedBytes / limitBytes).clamp(0, 1);
}

/// One line of "Lịch sử sử dụng" (PV41): person · task · amount, never content.
@immutable
class UsageRow {
  const UsageRow({
    required this.id,
    required this.kind,
    required this.task,
    required this.amount,
    required this.state,
    required this.at,
    this.uid,
  });

  factory UsageRow.fromJson(Map j) => UsageRow(
    id: '${j['id']}',
    kind: '${j['kind']}',
    task: '${j['task']}',
    uid: j['uid'] as String?,
    amount: (j['amount'] as num?)?.toInt() ?? 0,
    state: '${j['state']}',
    at:
        DateTime.tryParse('${j['at']}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final String id;

  /// lumi | video | grant | refund
  final String kind;

  /// lumi.chat | lumi.summary | lumi.photo | video.export | lumi.trial | lumi.cycle | video.trial
  /// | video.cycle | lumi.grant | video.grant
  final String task;
  final String? uid;
  final int amount;

  /// held | debited | granted | refunded
  final String state;
  final DateTime at;

  bool get isVideo => task.startsWith('video');
}

enum UsageFilter { all, lumi, video, grants }

class PremiumV2Exception implements Exception {
  const PremiumV2Exception(this.reason);
  final String reason;
}

abstract class PremiumV2Api {
  Future<FamilyPlanV2?> familyPlan(String babyId);
  Future<({List<UsageRow> rows, bool everyone})> usageHistory(
    String babyId, {
    UsageFilter filter = UsageFilter.all,
    bool everyone = false,
  });
  Future<int> chooseWriteSeats(String babyId, List<String> keep);
}

class FunctionsPremiumV2Api implements PremiumV2Api {
  FunctionsPremiumV2Api(this._functions);
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return r.data is Map
          ? Map<String, dynamic>.from(r.data! as Map)
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw PremiumV2Exception(
        details is Map && details['reason'] is String
            ? details['reason'] as String
            : e.code,
      );
    }
  }

  @override
  Future<FamilyPlanV2?> familyPlan(String babyId) async =>
      FamilyPlanV2.fromJson(await _call('getFamilyPlan', {'babyId': babyId}));

  @override
  Future<({List<UsageRow> rows, bool everyone})> usageHistory(
    String babyId, {
    UsageFilter filter = UsageFilter.all,
    bool everyone = false,
  }) async {
    final j = await _call('familyUsageHistory', {
      'babyId': babyId,
      'kind': filter.name,
      'everyone': everyone,
    });
    return (
      rows: [
        for (final r in (j['rows'] as List?) ?? const [])
          if (r is Map) UsageRow.fromJson(r),
      ],
      everyone: j['everyone'] == true,
    );
  }

  @override
  Future<int> chooseWriteSeats(String babyId, List<String> keep) async {
    final j = await _call('chooseFamilyWriteSeats', {
      'babyId': babyId,
      'keep': keep,
    });
    return (j['suspended'] as num?)?.toInt() ?? 0;
  }
}

final premiumV2ApiProvider = Provider<PremiumV2Api>(
  (ref) => FunctionsPremiumV2Api(ref.watch(functionsProvider)),
  retry: (_, _) => null,
);

/// The family's plan for one of my babies; null without Firebase (tests) or on failure.
final familyPlanV2Provider = FutureProvider.autoDispose
    .family<FamilyPlanV2?, String>((ref, babyId) async {
      if (Firebase.apps.isEmpty) return null;
      try {
        return await ref.watch(premiumV2ApiProvider).familyPlan(babyId);
      } on Object {
        return null;
      }
    }, retry: (_, _) => null);

typedef UsageQuery = ({String babyId, UsageFilter filter, bool everyone});

final usageHistoryProvider = FutureProvider.autoDispose
    .family<({List<UsageRow> rows, bool everyone}), UsageQuery>(
      (ref, q) => ref
          .watch(premiumV2ApiProvider)
          .usageHistory(q.babyId, filter: q.filter, everyone: q.everyone),
      retry: (_, _) => null,
    );
