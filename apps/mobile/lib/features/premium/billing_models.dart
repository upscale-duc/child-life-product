import 'package:flutter/foundation.dart';

import 'store_gateway.dart';

/// The app's view of the billing callables (contracts `billing.ts`, `quota.ts`; plan §5.2–5.3).

/// Where PR01 was opened from: `rhythm` (entry A, Nhịp lớn lên), `templates` (entry B, a
/// Premium template) or `plan` (PR03). Same product and capabilities; only the emphasis differs.
enum PaywallEntry {
  rhythm,
  templates,
  plan;

  static PaywallEntry fromWire(Object? v) =>
      values.where((e) => e.name == v).firstOrNull ?? PaywallEntry.plan;
}

/// `assistant`: the chat's kept question (CH21 → CH23); its ref is the chat scope and it stays
/// on this phone (the server's `purchaseResumeSchema` knows only card / video / rhythm).
enum ResumeKind { card, video, rhythm, assistant }

/// Where to come back after a purchase (MO03 "tiếp tục đúng mẫu & ảnh", M17): the template and
/// an opaque key of the draft kept on this phone. Selected photos never leave the phone.
@immutable
class PurchaseResume {
  const PurchaseResume({required this.kind, this.templateId, this.draftRef});

  final ResumeKind kind;
  final String? templateId;
  final String? draftRef;

  static const rhythm = PurchaseResume(kind: ResumeKind.rhythm);

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'templateId': templateId,
    'draftRef': draftRef,
  };

  static PurchaseResume? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = ResumeKind.values.asNameMap()[json['kind']];
    if (kind == null) return null;
    return PurchaseResume(
      kind: kind,
      templateId: json['templateId'] as String?,
      draftRef: json['draftRef'] as String?,
    );
  }

  /// The same record in a location (`?kind=&template=&draft=`), so the paywall keeps it when
  /// go_router rebuilds pages without `extra`.
  Map<String, String> toQuery() => {
    'kind': kind.name,
    'template': ?templateId,
    'draft': ?draftRef,
  };

  static PurchaseResume? fromQuery(Map<String, String> q) => fromJson({
    'kind': q['kind'],
    'templateId': q['template'],
    'draftRef': q['draft'],
  });

  @override
  bool operator ==(Object other) =>
      other is PurchaseResume &&
      other.kind == kind &&
      other.templateId == templateId &&
      other.draftRef == draftRef;

  @override
  int get hashCode => Object.hash(kind, templateId, draftRef);
}

/// `config/billing` products as published for the paywall: the store product id per period.
@immutable
class BillingProductIds {
  const BillingProductIds({required this.period, this.apple, this.google});
  final ProductPeriod period;
  final String? apple;
  final String? google;

  String? idFor(StoreProvider p) => switch (p) {
    StoreProvider.apple => apple,
    StoreProvider.google => google,
  };

  static List<BillingProductIds> listFromJson(Object? json) {
    final products = json is Map ? json['products'] : null;
    if (products is! List) return const [];
    return [
      for (final p in products)
        if (p is Map)
          if (ProductPeriod.values.asNameMap()[p['key']] case final period?)
            BillingProductIds(
              period: period,
              apple: p['apple'] as String?,
              google: p['google'] as String?,
            ),
    ];
  }
}

/// `startPurchase`: the owner's purchase intent.
@immutable
class PurchaseIntent {
  const PurchaseIntent({
    required this.intentId,
    required this.accountToken,
    required this.productId,
  });
  final String intentId;

  /// Apple `appAccountToken` (a UUID) / Google `obfuscatedAccountId`.
  final String accountToken;
  final String productId;

  static PurchaseIntent? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['intentId'], token = json['accountToken'];
    if (id is! String || token is! String) return null;
    return PurchaseIntent(
      intentId: id,
      accountToken: token,
      productId: json['productId'] as String? ?? '',
    );
  }
}

/// `PurchaseAnswer.outcome` (contracts `billing.ts`).
enum PurchaseOutcome {
  active,
  pending,
  expired,
  alreadyBound,
  notOwner,
  notFound;

  static PurchaseOutcome? fromWire(Object? v) => switch (v) {
    'active' => active,
    'pending' => pending,
    'expired' => expired,
    'already_bound' => alreadyBound,
    'not_owner' => notOwner,
    'not_found' => notFound,
    _ => null,
  };
}

@immutable
class PurchaseAnswer {
  const PurchaseAnswer({required this.outcome, this.validUntil, this.resume});
  final PurchaseOutcome outcome;
  final DateTime? validUntil;
  final PurchaseResume? resume;

  static PurchaseAnswer? fromJson(Object? json) {
    if (json is! Map) return null;
    final outcome = PurchaseOutcome.fromWire(json['outcome']);
    if (outcome == null) return null;
    return PurchaseAnswer(
      outcome: outcome,
      validUntil: DateTime.tryParse('${json['validUntil']}'),
      resume: PurchaseResume.fromJson(json['resume']),
    );
  }
}

/// MO04: the household's video export window (`QuotaSnapshot`, brief p.10). The server keeps
/// `used + reserved ≤ limit`; a failed export releases its reservation.
@immutable
class VideoQuota {
  const VideoQuota({
    required this.limit,
    required this.used,
    required this.reserved,
    this.resetsAt,
    this.premiumLimit,
  });

  final int limit;
  final int used;
  final int reserved;

  /// Exclusive end of the window.
  final DateTime? resetsAt;

  /// The Premium budget for the same kind of window, when the server says it (free families
  /// only): "Xem Premium" is offered only when it is larger than [limit].
  final int? premiumLimit;

  /// Used or held right now (MO04 "3 / 5").
  int get taken => used + reserved;
  int get left => (limit - taken).clamp(0, limit);
  bool get exhausted => taken >= limit;

  /// Reads `getVideoQuota`'s answer: the snapshot itself or `{quota: snapshot, …}`.
  static VideoQuota? fromJson(Object? json) {
    if (json is! Map) return null;
    final q = json['quota'] is Map ? json['quota'] as Map : json;
    final limit = q['limit'], used = q['used'], reserved = q['reserved'];
    if (limit is! num || used is! num || reserved is! num) return null;
    final premium = json['premiumLimit'] ?? q['premiumLimit'];
    return VideoQuota(
      limit: limit.toInt(),
      used: used.toInt(),
      reserved: reserved.toInt(),
      resetsAt: DateTime.tryParse('${q['resetsAt']}'),
      premiumLimit: premium is num ? premium.toInt() : null,
    );
  }
}
