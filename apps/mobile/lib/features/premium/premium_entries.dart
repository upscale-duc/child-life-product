import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/route_guard.dart';
import '../../l10n/app_localizations.dart';
import '../family/family_repository.dart';
import '../me/me_models.dart' show storagePercent;
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

Future<bool> _unknownPlan(BuildContext context, FamilyPlanV2? plan) async {
  if (plan != null) return false;
  await showPlanUnknown(context);
  return true;
}

/// "Chưa kiểm tra được gói gia đình": unknown is never a reason to sell Premium, nor silence
/// (P-2). The work in progress is kept.
Future<void> showPlanUnknown(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showPremiumSuggestion(
    context,
    title: l.premiumPlanCheckFailed,
    body: l.premiumPlanCheckFailedBody,
    primary: l.pv2GotIt,
  );
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
  if (await _unknownPlan(context, plan) || !context.mounted) return false;
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
  // P-9: the same used / limit as Gói của gia đình (the server's), not the offer's.
  final c = await showPremiumSuggestion(
    context,
    title: l10n.pv2E12Title(plan!.seatsUsed, plan.seatsLimit),
    body: l10n.pv2E12Body(plan.premiumOffer.caregiverSeats),
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

/// E07 "Premium hết credit": no paywall, the refill date (Q-098: no balance on buttons).
Future<void> showLumiCreditsUsed(
  BuildContext context,
  WidgetRef ref,
  String babyId,
) async {
  final l10n = AppLocalizations.of(context);
  final plan = await _plan(ref, babyId);
  if (!context.mounted) return;
  if (await _unknownPlan(context, plan) || !context.mounted) return;
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
  if (await _unknownPlan(context, plan) || !context.mounted) return;
  if (plan?.premium ?? false) {
    // D-127 Q7: only the manager buys storage; everyone else asks them.
    if (!plan!.isManager) {
      final name = planManagerName(ref, l10n, babyId);
      final c = await showPremiumSuggestion(
        context,
        title: l10n.pv2E09Title(
          premiumGb(context, plan.limitBytes ?? 0).replaceAll(' GB', ''),
        ),
        body: l10n.pv2E09BodyPremium,
        primary: l10n.pv2AskStorage(name),
        secondary: l10n.pv2ManageMedia,
      );
      if (!context.mounted) return;
      if (c == PremiumSuggestionChoice.primary) {
        unawaited(askManagerForStorage(context));
      } else if (c == PremiumSuggestionChoice.secondary) {
        unawaited(context.push(Routes.meStorage));
      }
      return;
    }
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

/// "20 GB hoặc 50 GB": the configured add-ons (ST-2), never a hard-coded list.
String? storageAddOnOptions(AppLocalizations l10n, FamilyPlanV2 plan) {
  final gbs = [for (final a in plan.addOns) '${a.gb} GB'];
  if (gbs.isEmpty) return null;
  return gbs.reduce((a, b) => l10n.pv2OptionOr(a, b));
}

/// The plan manager's name for "Nhờ {name}…" (D-127 Q7), else "người quản lý".
String planManagerName(WidgetRef ref, AppLocalizations l10n, String babyId) =>
    (ref.watch(familyMembersProvider(babyId)).value ?? const [])
        .where((m) => m.isOwner)
        .firstOrNull
        ?.displayName
        .trim()
        .nonEmpty ??
    l10n.pv2TheManager;

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}

/// "Nhờ {name} thêm dung lượng" (D-127 Q7): a member shares the ask; only the manager buys.
Future<void> askManagerForStorage(BuildContext context) =>
    SharePlus.instance.share(
      ShareParams(text: AppLocalizations.of(context).pv2AskStorageMessage),
    );

/// E08 / E09 on Dung lượng: the inline card under the bar (≥ 80 % or full). Free → PW04,
/// Premium → PW10 for the manager, "Nhờ {name} thêm dung lượng" for everyone else (ST-4).
/// [percent] / [full] come from Dung lượng's own numbers (one source, ST-2); [onFreeUp] adds
/// "Xoá bớt video lớn" (ST-3). Nothing while v2 is off, the plan is unknown or below 80 %.
class StoragePremiumInline extends ConsumerWidget {
  const StoragePremiumInline({
    required this.babyId,
    this.percent,
    this.full,
    this.onFreeUp,
    super.key,
  });
  final String babyId;
  final int? percent;
  final bool? full;
  final VoidCallback? onFreeUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider(babyId)).value;
    if (!(caps?.features.premiumV2 ?? false)) return const SizedBox.shrink();
    final plan = ref.watch(familyPlanV2Provider(babyId)).value;
    final limit = plan?.limitBytes;
    if (plan == null || limit == null) return const SizedBox.shrink();
    final full = this.full ?? plan.storageFull;
    final pct = percent ?? storagePercent(plan.storageCounted, limit);
    if (!full && pct < 80) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final gb = premiumGb(context, limit).replaceAll(' GB', '');
    final options = storageAddOnOptions(l10n, plan);
    final (title, body) = plan.premium
        ? (
            full ? l10n.pv2E09Title(gb) : l10n.pv2E08Title,
            full
                ? l10n.pv2E09BodyPremium
                : options == null
                ? l10n.pv2E08BodyPremiumPlain(pct, gb)
                : l10n.pv2E08BodyPremium(pct, gb, options),
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
    final member = plan.premium && !plan.isManager;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PremiumInlineCard(
        title: title,
        body: body,
        action: !plan.premium
            ? l10n.pv2SeePremium
            : member
            ? l10n.pv2AskStorage(planManagerName(ref, l10n, babyId))
            : l10n.pv2AddStorage,
        onAction: () => !plan.premium
            ? openPaywall(
                context,
                entry: PaywallEntry.plan,
                card: PremiumEntry.storage,
              )
            : member
            ? askManagerForStorage(context)
            : context.push(PlanV2Routes.addOn),
        secondary: onFreeUp == null ? null : l10n.stFreeUpVideos,
        onSecondary: onFreeUp,
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
        ? (plan?.priceVn?.month ?? 59000)
        : (plan?.priceIntl?.month ?? 5.99);
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
