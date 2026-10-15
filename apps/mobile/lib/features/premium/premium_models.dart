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
  const CapabilityState({required this.allowed, this.reason, this.via});
  final bool allowed;
  final GateReason? reason;

  /// What gives it: `paid`, `beta`, `promo` or `free`.
  final String? via;
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
    this.billingProvider,
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

  /// The store the paid plan was bought in (`apple` / `google`), when the server says so: PR03
  /// links to that store's subscription management only.
  final String? billingProvider;

  /// The Premium plan comes from a store subscription (not a staff promo): there is something
  /// to manage in the store. Unknown counts as paid.
  bool get paidPlan {
    final via = states[Capability.templatesPremium]?.via;
    return via == null || via == 'paid';
  }

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
              via: s['via'] as String?,
            ),
      },
      features: PremiumFeatures(
        rhythm: f['rhythm'] == true,
        personalization: f['personalization'] == true,
        aiAssist: f['aiAssist'] == true,
        billing: f['billing'] == true,
        assistant: f['assistant'] == true,
        assistantImages: f['assistantImages'] == true,
      ),
      billingProvider: json['provider'] is String
          ? json['provider'] as String
          : null,
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
          'via': e.value.via,
        },
    },
    'features': {
      'rhythm': features.rhythm,
      'personalization': features.personalization,
      'aiAssist': features.aiAssist,
      'billing': features.billing,
      'assistant': features.assistant,
      'assistantImages': features.assistantImages,
    },
    'provider': billingProvider,
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
    this.assistant = false,
    this.assistantImages = false,
  });
  final bool rhythm;
  final bool personalization;
  final bool aiAssist;
  final bool billing;

  /// Child Life Assistant chat (P-161 `assistant` flag); read when the server sends it.
  final bool assistant;

  /// Photo reading in the chat (`assistant_images`).
  final bool assistantImages;

  bool get any => rhythm || personalization || aiAssist || billing || assistant;
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
