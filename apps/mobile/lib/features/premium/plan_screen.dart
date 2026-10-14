import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import 'premium_models.dart';
import 'premium_repository.dart';

/// PR03 · Gói của hộ (593:6931): the household's plan, who manages it (the family owner only,
/// D-072 #1) and the household region (D-072 #3). Buying and restoring come with in-app purchase
/// (Slice 4); until then the owner is told so. Data, saved summaries and exports never depend on
/// the plan (PR04).
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

    return MePage(
      title: l10n.pmPlanTitle,
      onRefresh: () => ref.refresh(capabilitiesProvider(me.babyId).future),
      children: [
        if (async.isLoading && caps == null)
          const ClSkeleton(height: 120)
        else ...[
          _PlanCard(badge: badge, title: title, body: body),
          const SizedBox(height: ClSpace.s3),
          MeNotice(
            title: caps?.canManageBilling == true
                ? l10n.pmPlanBuySoon
                : l10n.pmPlanOwnerOnly,
          ),
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
  });
  final String badge;
  final String title;
  final String body;

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
        ],
      ),
    );
  }
}

String countryName(AppLocalizations l10n, String code) => switch (code) {
  'VN' => l10n.pmCountryVN,
  'US' => l10n.pmCountryUS,
  'GB' => l10n.pmCountryGB,
  'AU' => l10n.pmCountryAU,
  'CA' => l10n.pmCountryCA,
  'SG' => l10n.pmCountrySG,
  'NZ' => l10n.pmCountryNZ,
  'DE' => l10n.pmCountryDE,
  'FR' => l10n.pmCountryFR,
  'JP' => l10n.pmCountryJP,
  'KR' => l10n.pmCountryKR,
  'TW' => l10n.pmCountryTW,
  _ => code,
};

/// "Gia đình đang sống ở đâu?" (D-072 #3): the owner picks; never inferred from locale or IP.
Future<void> showRegionSheet(
  BuildContext context, {
  required String babyId,
  required String? current,
}) => showClSheet<void>(
  context: context,
  builder: (sheet) => Consumer(
    builder: (inner, ref, _) {
      final l10n = AppLocalizations.of(inner);
      final cl = inner.cl;
      Future<void> pick(String code) async {
        Navigator.of(sheet).pop();
        try {
          await ref.read(premiumRepositoryProvider).setCountry(babyId, code);
          ref.invalidate(capabilitiesProvider(babyId));
          // The sheet is gone: toast on the plan screen underneath.
          if (context.mounted) {
            showClToast(context, message: l10n.pmRegionSaved);
          }
        } on Object {
          if (context.mounted) {
            showClToast(context, message: l10n.toastActionFailed, error: true);
          }
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.pmRegionTitle),
          Text(
            l10n.pmRegionBody,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          Flexible(
            child: SingleChildScrollView(
              child: ClCardGroup(
                children: [
                  for (final code in pickerCountries)
                    ClOptionRow(
                      title: countryName(l10n, code),
                      selected: current == code,
                      onTap: () => pick(code),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
        ],
      );
    },
  ),
);
