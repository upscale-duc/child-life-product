import 'package:flutter/foundation.dart';

/// Child Life Premium & Cá nhân hoá (plan `docs/product/premium-personalization-plan.md`), the
/// app's view of `getCapabilities` (contracts `entitlements.ts`). The server decides every action
/// again; this only chooses what to draw. A cached answer never unlocks anything on the server.
enum Capability {
  moduleBasic('module.basic'),
  personalizationBasic('personalization.basic'),
  wonderReference('wonder.reference'),
  rhythmCheckin('rhythm.checkin'),
  healthGuidance('health.guidance'),
  momentsBasic('moments.basic'),
  historyRead('history.read'),
  personalizationCrossModule('personalization.cross_module'),
  rhythmAdvanced('rhythm.advanced'),
  aiAssistance('ai.assistance'),
  templatesPremium('templates.premium'),
  renderVideo('render.video');

  const Capability(this.wire);
  final String wire;
}

/// Reason codes (brief p.8). Only [premiumRequired] may lead to the paywall; the others explain
/// a role, a region, a paused feature, consent or quota (ST01 / ST02).
enum GateReason {
  notMember('NOT_MEMBER'),
  roleDenied('ROLE_DENIED'),
  featureDisabled('FEATURE_DISABLED'),
  regionUnavailable('REGION_UNAVAILABLE'),
  premiumRequired('PREMIUM_REQUIRED'),
  consentRequired('CONSENT_REQUIRED'),
  quotaExceeded('QUOTA_EXCEEDED');

  const GateReason(this.wire);
  final String wire;

  static GateReason? fromWire(Object? v) =>
      values.where((r) => r.wire == v).firstOrNull;
}

/// PR03's plan label for the household.
enum HouseholdPlan { free, beta, premium, pending, expired }

@immutable
class CapabilityState {
  const CapabilityState({required this.allowed, this.reason});
  final bool allowed;
  final GateReason? reason;
}

@immutable
class Capabilities {
  const Capabilities({
    required this.familyId,
    required this.plan,
    required this.states,
    this.validUntil,
    this.autoRenew,
    this.isBillingOwner = false,
    this.canManageBilling = false,
    this.country,
    this.entitlementVersion = 0,
    this.features = const PremiumFeatures(),
  });

  final String familyId;
  final HouseholdPlan plan;
  final DateTime? validUntil;
  final bool? autoRenew;
  final bool isBillingOwner;

  /// The family owner (D-072 #1).
  final bool canManageBilling;

  /// ISO 3166 code of the household's country, null until the owner picks it (D-072 #3).
  final String? country;
  final int entitlementVersion;
  final Map<Capability, CapabilityState> states;
  final PremiumFeatures features;

  bool allows(Capability c) => states[c]?.allowed ?? false;
  GateReason? reasonFor(Capability c) =>
      allows(c) ? null : (states[c]?.reason ?? GateReason.premiumRequired);

  static Capabilities? fromJson(Object? json) {
    if (json is! Map || json['familyId'] is! String) return null;
    final raw = json['capabilities'] is Map
        ? json['capabilities'] as Map
        : const {};
    final f = json['features'] is Map ? json['features'] as Map : const {};
    return Capabilities(
      familyId: json['familyId'] as String,
      plan:
          HouseholdPlan.values.asNameMap()[json['plan']] ?? HouseholdPlan.free,
      validUntil: DateTime.tryParse('${json['validUntil']}'),
      autoRenew: json['autoRenew'] as bool?,
      isBillingOwner: json['isBillingOwner'] == true,
      canManageBilling: json['canManageBilling'] == true,
      country: json['country'] as String?,
      entitlementVersion: (json['entitlementVersion'] as num?)?.toInt() ?? 0,
      states: {
        for (final c in Capability.values)
          if (raw[c.wire] case final Map s)
            c: CapabilityState(
              allowed: s['allowed'] == true,
              reason: GateReason.fromWire(s['reason']),
            ),
      },
      features: PremiumFeatures(
        rhythm: f['rhythm'] == true,
        personalization: f['personalization'] == true,
        aiAssist: f['aiAssist'] == true,
        billing: f['billing'] == true,
      ),
    );
  }

  /// The shape [fromJson] reads, for the offline copy on the phone.
  Map<String, Object?> toJson() => {
    'familyId': familyId,
    'plan': plan.name,
    'validUntil': validUntil?.toUtc().toIso8601String(),
    'autoRenew': autoRenew,
    'isBillingOwner': isBillingOwner,
    'canManageBilling': canManageBilling,
    'country': country,
    'entitlementVersion': entitlementVersion,
    'capabilities': {
      for (final e in states.entries)
        e.key.wire: {
          'allowed': e.value.allowed,
          'reason': e.value.reason?.wire,
        },
    },
    'features': {
      'rhythm': features.rhythm,
      'personalization': features.personalization,
      'aiAssist': features.aiAssist,
      'billing': features.billing,
    },
  };
}

/// Rollout flags on for this family; everything ships dark.
@immutable
class PremiumFeatures {
  const PremiumFeatures({
    this.rhythm = false,
    this.personalization = false,
    this.aiAssist = false,
    this.billing = false,
  });
  final bool rhythm;
  final bool personalization;
  final bool aiAssist;
  final bool billing;

  bool get any => rhythm || personalization || aiAssist || billing;
}

/// Countries offered in the region picker (D-072 #3): the beta markets under discussion (Q-069).
/// Region availability itself comes from the server (`config/entitlements`).
const pickerCountries = [
  'VN',
  'US',
  'GB',
  'AU',
  'CA',
  'SG',
  'NZ',
  'DE',
  'FR',
  'JP',
  'KR',
  'TW',
];
