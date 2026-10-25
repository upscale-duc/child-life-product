import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../l10n/app_localizations.dart';
import 'billing_models.dart';
import 'family_plan_v2.dart';
import 'paywall_screen.dart';
import 'premium_models.dart';
import 'premium_repository.dart';
import 'premium_style.dart';
import 'premium_v2.dart';

/// Premium v2 entry points (PV00C, Figma 991:15657 / 991:15658): the suggestion each one shows
/// and where it goes. Every one keeps the user's work ("vẫn được giữ") and has a way out; a
/// family that already has Premium is told when it refills, never sold more (E03, E07, E12).

Future<FamilyPlanV2?> _plan(WidgetRef ref, String babyId) async {
  try {
    return await ref.read(familyPlanV2Provider(babyId).future);
  } on Object {
    return null;
  }
}

String _date(BuildContext context, DateTime? d) => d == null
    ? '—'
    : DateFormat(
        'dd/MM',
        Localizations.localeOf(context).toLanguageTag(),
      ).format(d.toLocal());

/// E12 "Hết chỗ người chăm sóc" → PW05. True when the user chose "Mời làm người thân".
Future<bool> showSeatsFullSuggestion(
  BuildContext context,
  WidgetRef ref,
  String babyId,
) async {
  final l10n = AppLocalizations.of(context);
  final plan = await _plan(ref, babyId);
  if (!context.mounted) return false;
  if (plan?.premium ?? false) {
    final c = await showPremiumSuggestion(
      context,
      title: l10n.pv2E12FullTitle(plan!.seatsLimit),
      body: l10n.pv2E12FullBody,
      primary: l10n.pv2E12Secondary,
      secondary: l10n.pv2GotIt,
    );
    return c == PremiumSuggestionChoice.primary;
  }
  final free = plan?.free ?? PlanOffer.free;
  final premium = plan?.premiumOffer ?? PlanOffer.premium;
  final c = await showPremiumSuggestion(
    context,
    title: l10n.pv2E12Title(
      plan?.seatsUsed ?? free.caregiverSeats,
      free.caregiverSeats,
    ),
    body: l10n.pv2E12Body(premium.caregiverSeats),
    secondary: l10n.pv2E12Secondary,
  );
  if (c == PremiumSuggestionChoice.primary && context.mounted) {
    await openPaywall(
      context,
      entry: PaywallEntry.plan,
      card: PremiumEntry.caregivers,
    );
    return false;
  }
  return c == PremiumSuggestionChoice.secondary;
}

/// E03 "Hết lượt tạo video" (Free → PW01; Premium: the refill date). True when the paywall
/// came back with Premium.
Future<bool> showVideoExportsUsed(
  BuildContext context,
  WidgetRef ref,
  String babyId,
) async {
  final l10n = AppLocalizations.of(context);
  final plan = await _plan(ref, babyId);
  if (!context.mounted) return false;
  if (plan?.premium ?? false) {
    await showPremiumSuggestion(
      context,
      title: l10n.pv2E03PremiumTitle(plan!.video.limit),
      body: l10n.pv2E03PremiumBody(_date(context, plan.video.resetsAt)),
      primary: l10n.pv2GotIt,
    );
    return false;
  }
  final c = await showPremiumSuggestion(
    context,
    title: l10n.pv2E03Title((plan?.free ?? PlanOffer.free).videoExports),
    body: l10n.pv2E03Body(
      (plan?.premiumOffer ?? PlanOffer.premium).videoExports,
    ),
    secondary: l10n.pv2E03Secondary,
  );
  if (c != PremiumSuggestionChoice.primary || !context.mounted) return false;
  return openPaywall(
    context,
    entry: PaywallEntry.templates,
    card: PremiumEntry.video,
  );
}

/// E07 "Premium hết credit": no paywall, the refill date (Q-098: no balance on buttons).
Future<void> showLumiCreditsUsed(
  BuildContext context,
  WidgetRef ref,
  String babyId,
) async {
  final l10n = AppLocalizations.of(context);
  final plan = await _plan(ref, babyId);
  if (!context.mounted) return;
  final c = await showPremiumSuggestion(
    context,
    title: l10n.pv2E07Title(plan?.lumi.limit ?? PlanOffer.premium.lumiCredits),
    body: l10n.pv2E07Body(_date(context, plan?.lumi.resetsAt)),
    primary: l10n.pv2GotIt,
    secondary: l10n.pv2E07Secondary,
  );
  if (c == PremiumSuggestionChoice.secondary && context.mounted) {
    unawaited(context.push(Routes.mePlan));
  }
}

/// E10 / E11 "Hết dung lượng" (Free → PW04; Premium → PW10).
Future<void> showStorageFullSuggestion(
  BuildContext context,
  WidgetRef ref,
  String babyId, {
  bool autoSave = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final plan = await _plan(ref, babyId);
  if (!context.mounted) return;
  if (plan?.premium ?? false) {
    unawaited(context.push(PlanV2Routes.addOn));
    return;
  }
  final free = premiumGb(context, (plan?.free ?? PlanOffer.free).storageBytes);
  final premium = premiumGb(
    context,
    (plan?.premiumOffer ?? PlanOffer.premium).storageBytes,
  ).replaceAll(' GB', '');
  final freeNumber = free.replaceAll(' GB', '');
  final c = await showPremiumSuggestion(
    context,
    title: autoSave ? l10n.pv2E11Title : l10n.pv2E10Title(freeNumber),
    body: autoSave
        ? l10n.pv2E11Body(freeNumber, premium)
        : l10n.pv2E10Body(premium),
    secondary: l10n.pv2ManageMedia,
  );
  if (!context.mounted) return;
  switch (c) {
    case PremiumSuggestionChoice.primary:
      unawaited(
        openPaywall(
          context,
          entry: PaywallEntry.plan,
          card: PremiumEntry.storage,
        ),
      );
    case PremiumSuggestionChoice.secondary:
      unawaited(context.push(Routes.meStorage));
    case PremiumSuggestionChoice.dismissed:
      break;
  }
}

/// E08 / E09 on Dung lượng: the inline card under the bar (≥ 80 % or full). Free → PW04,
/// Premium → PW10. Nothing while v2 is off or below 80 %.
class StoragePremiumInline extends ConsumerWidget {
  const StoragePremiumInline({required this.babyId, super.key});
  final String babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider(babyId)).value;
    if (!(caps?.features.premiumV2 ?? false)) return const SizedBox.shrink();
    final plan = ref.watch(familyPlanV2Provider(babyId)).value;
    if (plan == null || plan.storageRatio < 0.8) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final full = plan.usedBytes >= plan.limitBytes;
    final gb = premiumGb(context, plan.limitBytes).replaceAll(' GB', '');
    final (title, body) = plan.premium
        ? (
            full ? l10n.pv2E09Title(gb) : l10n.pv2E08Title,
            full
                ? l10n.pv2E09BodyPremium
                : l10n.pv2E08BodyPremium((plan.storageRatio * 100).round(), gb),
          )
        : (
            full ? l10n.pv2E09Title(gb) : l10n.pv2StorageInlineFreeTitle,
            l10n.pv2StorageInlineFreeBody(
              premiumGb(
                context,
                plan.premiumOffer.storageBytes,
              ).replaceAll(' GB', ''),
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PremiumInlineCard(
        title: title,
        body: body,
        action: plan.premium ? l10n.pv2AddStorage : l10n.pv2SeePremium,
        onAction: () => plan.premium
            ? context.push(PlanV2Routes.addOn)
            : openPaywall(
                context,
                entry: PaywallEntry.plan,
                card: PremiumEntry.storage,
              ),
      ),
    );
  }
}

/// E13 on Tôi: the inline card for a Free family's manager → PW06 (opened on purpose).
class MePremiumInline extends ConsumerWidget {
  const MePremiumInline({required this.babyId, this.top = 0, super.key});
  final String babyId;

  /// Space above, only when the card shows.
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider(babyId)).value;
    if (!(caps?.features.premiumV2 ?? false) ||
        caps!.plan == HouseholdPlan.premium ||
        !caps.canManageBilling) {
      return const SizedBox.shrink();
    }
    final plan = ref.watch(familyPlanV2Provider(babyId)).value;
    final l10n = AppLocalizations.of(context);
    final offer = plan?.premiumOffer ?? PlanOffer.premium;
    final vnd = caps.country == null || caps.country == 'VN';
    final price = vnd
        ? (plan?.priceVn.month ?? 59000)
        : (plan?.priceIntl.month ?? 5.99);
    final card = PremiumInlineCard(
      title: l10n.pv2E13Title,
      body: l10n.pv2E13Body(
        offer.videoExports,
        offer.lumiCredits,
        premiumGb(context, offer.storageBytes).replaceAll(' GB', ''),
        premiumPrice(context, price, vnd: vnd),
      ),
      action: l10n.pv2SeePremium,
      onAction: () => openPaywall(
        context,
        entry: PaywallEntry.plan,
        card: PremiumEntry.explore,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: card,
    );
  }
}
