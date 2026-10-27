import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../keepsakes/keepsake_catalog.dart';
import '../rhythm/personalization_events.dart';
import 'billing_models.dart';
import 'paywall_screen.dart';
import 'premium_models.dart';
import 'premium_style.dart';
import 'premium_v2.dart';
import 'premium_entries.dart' show showPlanUnknown;
import 'premium_repository.dart';
import 'purchase_resume.dart';

/// Explains a refused action by its reason (brief p.8, ST01 / ST02). Never a paywall: only
/// [GateReason.premiumRequired] offers Premium (PR01, opened from [entry]). Health and logging
/// never reach here (brief p.13).
Future<void> showGateSheet(
  BuildContext context,
  GateReason reason, {
  PaywallEntry entry = PaywallEntry.rhythm,
}) {
  final sink = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(personalizationEventSinkProvider);
  unawaited(sink('capabilityGateSeen', reason.wire).catchError((Object _) {}));
  final l10n = AppLocalizations.of(context);
  final (title, body, action) = switch (reason) {
    GateReason.roleDenied => (l10n.pmGateRoleTitle, l10n.pmGateRoleBody, null),
    GateReason.regionUnavailable => (
      l10n.pmGateRegionTitle,
      l10n.pmGateRegionBody,
      (l10n.pmGateRegionAction, Routes.mePlan),
    ),
    GateReason.featureDisabled => (
      l10n.pmGateDisabledTitle,
      l10n.pmGateDisabledBody,
      null,
    ),
    GateReason.quotaExceeded => (
      l10n.pmGateQuotaTitle,
      l10n.pmGateQuotaBody,
      null,
    ),
    GateReason.consentRequired => (
      l10n.pmGateConsentTitle,
      l10n.pmGateConsentBody,
      null,
    ),
    GateReason.notMember => (l10n.pmGateNotMemberTitle, null, null),
    GateReason.premiumRequired => (
      l10n.pmPlanTitle,
      l10n.pmTemplatePremiumBody,
      (l10n.pmUnlockPremium, paywallLocation(entry)),
    ),
  };
  return showClSheet<void>(
    context: context,
    builder: (sheet) => _GateBody(
      title: title,
      body: body,
      primary: action == null
          ? null
          : (
              action.$1,
              () {
                Navigator.of(sheet).pop();
                context.push(action.$2);
              },
            ),
      secondary: (l10n.pmGateOk, () => Navigator.of(sheet).pop()),
    ),
  );
}

/// What MO02 decided. [unlocked]: PR01 came back with the household on Premium.
enum PremiumTemplateChoice { unlock, unlocked, useFree, dismissed }

/// MO02 (592:6782): a Cao cấp template in `subscribers` mode without `templates.premium`.
/// "Mở với Premium" opens PR01 from the templates (entry B) with the draft kept by [keep]
/// (MO03: same template and photos after the purchase); "Dùng mẫu miễn phí" goes back to the
/// library. Beta families are told the beta does not include Premium templates (brief p.3).
Future<PremiumTemplateChoice> showPremiumTemplateSheet(
  BuildContext context, {
  required String templateName,
  required Capabilities? caps,
  PurchaseResume Function()? keep,
  KeepsakeKind kind = KeepsakeKind.video,
  int videosPerMonth = 4,
}) async {
  final l10n = AppLocalizations.of(context);
  // Premium v2 (D-101): Gợi ý Premium · Sheet, E01 (video) / E02 (thiệp) → PW01 / PW02.
  if (caps?.features.premiumV2 ?? false) {
    final card = kind == KeepsakeKind.card;
    final v2 = await showPremiumSuggestion(
      context,
      title: card
          ? l10n.pv2E02Title(templateName)
          : l10n.pv2E01Title(templateName),
      body: card ? l10n.pv2E02Body : l10n.pv2E01Body(videosPerMonth),
      secondary: card ? l10n.pv2E02Secondary : l10n.pv2E01Secondary,
    );
    if (v2 == PremiumSuggestionChoice.primary && context.mounted) {
      final done = await openPaywall(
        context,
        entry: PaywallEntry.templates,
        resume: keep?.call(),
        card: card ? PremiumEntry.card : PremiumEntry.video,
        subject: templateName,
      );
      return done
          ? PremiumTemplateChoice.unlocked
          : PremiumTemplateChoice.dismissed;
    }
    return v2 == PremiumSuggestionChoice.secondary
        ? PremiumTemplateChoice.useFree
        : PremiumTemplateChoice.dismissed;
  }
  final choice = await showClSheet<PremiumTemplateChoice>(
    context: context,
    builder: (sheet) => _GateBody(
      badge: l10n.pmBadgePremium,
      title: templateName,
      body: [
        l10n.pmTemplatePremiumBody,
        if (caps?.plan == HouseholdPlan.beta) l10n.pmTemplateBetaNote,
        if (keep != null) l10n.pmTemplateKeepsPhotos,
      ].join('\n'),
      primary: (
        l10n.pmUnlockPremium,
        () => Navigator.of(sheet).pop(PremiumTemplateChoice.unlock),
      ),
      secondary: (
        l10n.pmUseFreeTemplate,
        () => Navigator.of(sheet).pop(PremiumTemplateChoice.useFree),
      ),
    ),
  );
  if (choice == PremiumTemplateChoice.unlock && context.mounted) {
    final done = await openPaywall(
      context,
      entry: PaywallEntry.templates,
      resume: keep?.call(),
    );
    if (done) return PremiumTemplateChoice.unlocked;
  }
  return choice ?? PremiumTemplateChoice.dismissed;
}

/// Whether [t] may be used now. In `subscribers` mode a Cao cấp template needs the household's
/// `templates.premium`; otherwise MO02 is shown and false returned, unless the parent buys
/// Premium from there: then true, and the next screen shows MO03's "tiếp tục" banner. [keep]
/// keeps the draft for the purchase (MO03 / M17). The server refuses it too
/// (`PREMIUM_REQUIRED`), so a stale answer here can only cost a retry, never unlock anything.
Future<bool> ensureTemplateAllowed(
  BuildContext context,
  WidgetRef ref, {
  required KeepsakeTemplate template,
  required KeepsakeCatalog? catalog,
  required String babyId,
  PurchaseResume Function()? keep,
}) async {
  if (!template.premium) return true;
  final caps = await ref.read(capabilitiesProvider(babyId).future);
  // P-2: with no answer and nothing kept on this phone, say so; never offer "Mở với Premium"
  // to a family that may already pay.
  if (caps == null && catalog?.premiumAccess == PremiumAccess.subscribers) {
    if (context.mounted) await showPlanUnknown(context);
    return false;
  }
  if (!(caps?.features.premiumV2 ?? false) &&
      catalog?.premiumAccess != PremiumAccess.subscribers) {
    return true;
  }
  if (caps?.features.premiumV2 ?? false) {
    final plan = await ref.read(familyPlanV2Provider(babyId).future);
    // Unknown is never a reason to sell Premium, nor a tap that does nothing (P-2).
    if (plan == null) {
      if (context.mounted) await showPlanUnknown(context);
      return false;
    }
    if (plan.premium) {
      if (caps?.allows(Capability.templatesPremium) ?? false) return true;
      if (!context.mounted) return false;
      final reason = caps?.reasonFor(Capability.templatesPremium);
      await showGateSheet(
        context,
        reason == null || reason == GateReason.premiumRequired
            ? GateReason.featureDisabled
            : reason,
        entry: PaywallEntry.templates,
      );
      return false;
    }
  } else if (caps?.allows(Capability.templatesPremium) ?? false) {
    return true;
  }
  if (!context.mounted) return false;
  final reason = caps?.reasonFor(Capability.templatesPremium);
  if (reason != null && reason != GateReason.premiumRequired) {
    await showGateSheet(context, reason, entry: PaywallEntry.templates);
    return false;
  }
  final choice = await showPremiumTemplateSheet(
    context,
    templateName: template.name.of(Localizations.localeOf(context)),
    caps: caps,
    keep: keep,
    kind: template.kind,
    videosPerMonth:
        ref
            .read(familyPlanV2Provider(babyId))
            .value
            ?.premiumOffer
            .videoExports ??
        PlanOffer.premium.videoExports,
  );
  if (choice != PremiumTemplateChoice.unlocked) return false;
  // Access is what getCapabilities says now (the paywall already read it back).
  if (!context.mounted) return false;
  final now = await readCapabilities(ref, babyId);
  if (!(now?.allows(Capability.templatesPremium) ?? false)) return false;
  ref.read(justResumedProvider.notifier).set(template.id);
  return true;
}

class _GateBody extends StatelessWidget {
  const _GateBody({
    required this.title,
    required this.secondary,
    this.body,
    this.primary,
    this.badge,
  });
  final String title;
  final String? body;
  final String? badge;
  final (String, VoidCallback)? primary;
  final (String, VoidCallback) secondary;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        if (badge != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cl.colors.sunshineSoft,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              // Ink on soft warm fills, also in Night care.
              child: Text(
                badge!,
                style: cl.text.caption.copyWith(
                  color: cl.colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        if (body != null) ...[
          Text(body!, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(height: ClSpace.s4),
        ],
        if (primary case final p?) ...[
          ClButton(label: p.$1, expand: true, onPressed: p.$2),
          const SizedBox(height: ClSpace.s2),
        ],
        ClButton(
          label: secondary.$1,
          expand: true,
          style: primary == null
              ? ClButtonStyle.primary
              : ClButtonStyle.secondary,
          onPressed: secondary.$2,
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}
