import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../family/countries.dart';
import '../me/me_widgets.dart';
import 'billing_models.dart';
import 'family_plan_v2.dart';
import 'paywall_screen.dart';
import 'premium_models.dart';
import 'premium_repository.dart';
import 'premium_widgets.dart';
import 'purchase_controller.dart';
import 'purchase_sheets.dart';
import 'store_gateway.dart';

/// PR03 · Gói của hộ (593:6931): the household's plan, who manages it (the family owner only,
/// D-072 #1) and the household region (D-072 #3). The owner opens PR01 ("Xem Premium" /
/// "Gia hạn Premium"), manages a store subscription in the store it was bought in, and restores
/// where the store is open (D-074: not yet). Everyone else sees "Hộ đã có Premium" or who to
/// ask. Data, saved summaries and exports never depend on the plan (PR04).
class HouseholdPlanScreen extends ConsumerWidget {
  const HouseholdPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final async = ref.watch(capabilitiesProvider(me.babyId));
    final caps = async.value;
    // Premium v2 (D-101): Gói của gia đình PV40 / PV40B / PV43 / PV45.
    if (caps != null && caps.features.premiumV2) {
      return FamilyPlanV2Screen(babyId: me.babyId, caps: caps);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date(DateTime d) => DateFormat.yMMMd(locale).format(d.toLocal());

    final (badge, title, body) = switch (caps?.plan ?? HouseholdPlan.free) {
      HouseholdPlan.free => (
        l10n.pmBadgeFree,
        l10n.pmPlanFree,
        l10n.pmPlanFreeBody,
      ),
      HouseholdPlan.beta => (
        l10n.pmBadgeBeta,
        l10n.pmPlanBeta,
        l10n.pmPlanBetaBody(
          caps?.validUntil == null ? '—' : date(caps!.validUntil!),
        ),
      ),
      HouseholdPlan.premium => (
        l10n.pmBadgePremium,
        l10n.pmPlanPremium,
        [
          if (caps?.validUntil case final d?)
            caps!.autoRenew == false
                ? l10n.pmPlanEnds(date(d))
                : l10n.pmPlanRenews(date(d)),
          caps!.canManageBilling ? l10n.pmPlanShared : l10n.pmPlanHouseholdHas,
        ].join('\n'),
      ),
      HouseholdPlan.pending => (
        l10n.pmBadgePending,
        l10n.pmPlanPending,
        l10n.pmPlanPendingBody,
      ),
      HouseholdPlan.expired => (
        l10n.pmBadgeExpired,
        l10n.pmPlanExpired(
          caps?.validUntil == null ? '—' : date(caps!.validUntil!),
        ),
        l10n.pmPlanExpiredBody,
      ),
    };

    final owner = caps?.canManageBilling == true;
    final plan = caps?.plan ?? HouseholdPlan.free;
    final store = ref.watch(storeGatewayProvider);
    // Restore after a result sheet; the controller's phase drives it like on PR01.
    ref.listen(purchaseControllerProvider, (prev, next) async {
      if (prev?.phase == next.phase || next.source != 'plan') return;
      final kind = switch (next.phase) {
        PurchasePhase.restored => PurchaseSheetKind.restored,
        PurchasePhase.pending => PurchaseSheetKind.pending,
        PurchasePhase.error => switch (next.problem) {
          PurchaseProblem.notOwner => PurchaseSheetKind.notOwner,
          PurchaseProblem.alreadyBound => PurchaseSheetKind.alreadyBound,
          PurchaseProblem.nothingToRestore =>
            PurchaseSheetKind.nothingToRestore,
          PurchaseProblem.network => PurchaseSheetKind.networkError,
          PurchaseProblem.verify => PurchaseSheetKind.verifyError,
          _ => PurchaseSheetKind.storeError,
        },
        _ => null,
      };
      if (kind == null) return;
      await showPurchaseSheet(context, kind, entry: PaywallEntry.plan);
      ref.read(purchaseControllerProvider.notifier).reset();
    });
    Future<void> restore() async {
      final ok = await showPurchaseSheet(
        context,
        PurchaseSheetKind.restoreConfirm,
        entry: PaywallEntry.plan,
      );
      if (ok == PurchaseSheetAction.primary) {
        await ref
            .read(purchaseControllerProvider.notifier)
            .restore(me.babyId, source: 'plan');
      }
    }

    // The store the plan was bought in; unknown: both (PR03 draws App Store only).
    final providers = switch (caps?.billingProvider) {
      'apple' => [StoreProvider.apple],
      'google' => [StoreProvider.google],
      _ => StoreProvider.values,
    };
    final actions = <(String, VoidCallback)>[
      if (owner && plan == HouseholdPlan.premium && caps!.paidPlan)
        for (final p in providers)
          (
            p == StoreProvider.apple ? l10n.pmManageApple : l10n.pmManageGoogle,
            () => unawaited(
              launchUrl(
                store.manageUri(p),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
      if (owner &&
          (plan == HouseholdPlan.free ||
              plan == HouseholdPlan.beta ||
              plan == HouseholdPlan.pending))
        (
          l10n.pmSeePremium,
          () => unawaited(openPaywall(context, entry: PaywallEntry.plan)),
        ),
      if (owner && plan == HouseholdPlan.expired)
        (
          l10n.pmRenewPremium,
          () => unawaited(openPaywall(context, entry: PaywallEntry.plan)),
        ),
      // Only where the store can be asked (D-074: not yet).
      if (owner && store.available)
        (l10n.pmRestore, () => unawaited(restore())),
    ];

    return MePage(
      title: l10n.pmPlanTitle,
      onRefresh: () => ref.refresh(capabilitiesProvider(me.babyId).future),
      children: [
        if (async.isLoading && caps == null)
          const ClSkeleton(height: 120)
        else ...[
          _PlanCard(badge: badge, title: title, body: body, actions: actions),
          if (plan == HouseholdPlan.expired) ...[
            const SizedBox(height: ClSpace.s3),
            // PR04: history stays; renewing is the card's action.
            const PremiumExpiredStrip(canRenew: false),
          ],
          if (!owner) ...[
            const SizedBox(height: ClSpace.s3),
            MeNotice(title: l10n.pmPlanOwnerOnly),
          ],
          const SizedBox(height: ClSpace.s3),
          MeNotice(
            title: l10n.pmPlanAlwaysFree,
            body: l10n.pmPlanAlwaysFreeBody,
          ),
          const SizedBox(height: ClSpace.s3),
          ClCardGroup(
            children: [
              MeRow(
                icon: ClIcons.globe,
                title: l10n.pmRegionRow,
                subtitle: caps?.canManageBilling == true
                    ? null
                    : l10n.pmRegionOwnerOnly,
                value: caps?.country == null
                    ? l10n.pmRegionUnset
                    : countryName(l10n, caps!.country!),
                onTap: caps?.canManageBilling == true
                    ? () => showRegionSheet(
                        context,
                        babyId: me.babyId,
                        current: caps!.country,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.badge,
    required this.title,
    required this.body,
    this.actions = const [],
  });
  final String badge;
  final String title;
  final String body;

  /// The owner's buttons (PR03 pills on the current plan card).
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 4),
        border: Border.all(color: cl.colors.mintDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: cl.text.bodyStrong)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  badge,
                  style: cl.text.caption.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Text(body, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          for (final (label, onTap) in actions) ...[
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: label,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: onTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Gia đình đang sống ở đâu?" (D-072 #3, D-078): the owner picks; never inferred from locale or IP.
Future<void> showRegionSheet(
  BuildContext context, {
  required String babyId,
  required String? current,
}) async {
  final code = await showCountrySheet(context, current: current);
  if (code == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await container.read(premiumRepositoryProvider).setCountry(babyId, code);
    container.invalidate(capabilitiesProvider(babyId));
    if (context.mounted) showClToast(context, message: l10n.pmRegionSaved);
  } on Object {
    if (context.mounted) {
      showClToast(context, message: l10n.toastActionFailed, error: true);
    }
  }
}
