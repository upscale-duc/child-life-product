import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_resume.dart';
import '../me/me_widgets.dart';
import '../baby/baby_repository.dart';
import '../family/family_repository.dart';
import 'billing_models.dart';
import 'billing_repository.dart';
import 'family_plan_v2.dart';
import 'paywall_v2.dart';
import 'premium_models.dart';
import 'premium_style.dart';
import 'premium_v2.dart';
import 'premium_repository.dart';
import 'purchase_controller.dart';
import 'purchase_sheets.dart';
import 'store_gateway.dart';

/// PR01 · Quyền lợi & paywall (592:6826 / 592:6950). One SKU for the household, two entry
/// points: `rhythm` (A, Nhịp lớn lên) puts group A first, `templates` (B, a Premium template)
/// group B; the capabilities are the same. Price, period and renewal come from the storefront.
/// Only the family owner sees the buy area (D-072 #1); others see "Hộ đã có Premium" or
/// "Nhờ chủ hộ nâng cấp". Without an open store (D-074, `premium_billing` off, no products) the
/// page still explains the plan and says purchase is not open yet; there is no dead button.
/// Terms / Privacy and the auto-renewal sentence are added for the store guidelines (not drawn).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    required this.entry,
    this.resume,
    this.awaited = false,
    this.v2Entry,
    this.subject,
    super.key,
  });

  final PaywallEntry entry;
  final PurchaseResume? resume;

  /// Premium v2 (D-101): which card opened the paywall (PW01–PW06); null maps [entry].
  final PremiumEntry? v2Entry;

  /// The template the reason line names (E01 / E02), when there is one.
  final String? subject;

  /// A flow is waiting for the result (`openPaywall`) and continues itself after a purchase.
  final bool awaited;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallState();
}

/// The location of PR01 for [entry]; the resume record rides in the query. [card] / [subject]:
/// the Premium v2 entry card and the template its reason line names.
String paywallLocation(
  PaywallEntry entry, [
  PurchaseResume? resume,
  PremiumEntry? card,
  String? subject,
]) => Uri(
  path: Routes.premium,
  queryParameters: {
    'entry': entry.name,
    if (card != null) 'card': card.name,
    if (subject != null && subject.isNotEmpty) 'subject': subject,
    ...?resume?.toQuery(),
  },
).toString();

/// Opens PR01; true when the household has Premium afterwards (verified, read back from
/// `getCapabilities`). Entry A lands in Nhịp lớn lên after a purchase.
Future<bool> openPaywall(
  BuildContext context, {
  required PaywallEntry entry,
  PurchaseResume? resume,
  PremiumEntry? card,
  String? subject,
}) async {
  final router = GoRouter.of(context);
  final done =
      await router.push<Object?>(
        paywallLocation(entry, resume, card, subject),
        extra: const PaywallHandoff(),
      ) ==
      true;
  if (done && entry == PaywallEntry.rhythm) landInRhythm(router);
  return done;
}

/// Marks a paywall someone waits for (the template flow continues itself).
class PaywallHandoff {
  const PaywallHandoff();
}

class _PaywallState extends ConsumerState<PaywallScreen> {
  var _period = ProductPeriod.yearly;

  /// Captured once: go_router may rebuild the page without its `extra`.
  late final bool _awaited = widget.awaited;
  var _sheetOpen = false;

  PurchaseController get _controller =>
      ref.read(purchaseControllerProvider.notifier);

  StoreProduct? _selected(List<StoreProduct> products) =>
      products.where((p) => p.period == _period).firstOrNull ??
      products.firstOrNull;

  Future<void> _buy(String babyId, StoreProduct product) => _controller.buy(
    babyId: babyId,
    product: product,
    entry: widget.entry,
    resume: widget.resume,
  );

  Future<void> _restore(String babyId) async {
    final ok = await showPurchaseSheet(
      context,
      PurchaseSheetKind.restoreConfirm,
      entry: widget.entry,
    );
    if (ok == PurchaseSheetAction.primary) await _controller.restore(babyId);
  }

  void _finish() {
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context);
    final resume = widget.resume;
    _controller.reset();
    if (_awaited) {
      context.pop(true);
      return;
    }
    context.pop();
    if (resume != null) {
      unawaited(resumeAfterPurchase(router, container, resume));
    }
  }

  Future<void> _onPhase(
    PurchaseFlow flow,
    String babyId,
    List<StoreProduct> products,
  ) async {
    final kind = switch (flow.phase) {
      PurchasePhase.pending => PurchaseSheetKind.pending,
      PurchasePhase.success => PurchaseSheetKind.success,
      PurchasePhase.restored => PurchaseSheetKind.restored,
      PurchasePhase.error => switch (flow.problem) {
        PurchaseProblem.notOwner => PurchaseSheetKind.notOwner,
        PurchaseProblem.alreadyBound => PurchaseSheetKind.alreadyBound,
        PurchaseProblem.nothingToRestore => PurchaseSheetKind.nothingToRestore,
        PurchaseProblem.verify => PurchaseSheetKind.verifyError,
        PurchaseProblem.network => PurchaseSheetKind.networkError,
        _ => PurchaseSheetKind.storeError,
      },
      _ => null,
    };
    if (kind == null || _sheetOpen) return;
    _sheetOpen = true;
    final action = await showPurchaseSheet(
      context,
      kind,
      entry: widget.entry,
      resume: widget.resume,
      templateName: _templateName(),
    );
    _sheetOpen = false;
    if (!mounted) return;
    // P-6: the purchase moved on while the sheet was open (a success arriving under Pending):
    // show where it is now instead of answering a state that is gone.
    final latest = ref.read(purchaseControllerProvider);
    if (latest.phase != flow.phase || latest.problem != flow.problem) {
      unawaited(_onPhase(latest, babyId, products));
      return;
    }
    switch (kind) {
      case PurchaseSheetKind.success || PurchaseSheetKind.restored:
        _finish();
      case PurchaseSheetKind.pending:
        action == PurchaseSheetAction.primary
            ? unawaited(_controller.checkAgain())
            : _controller.acknowledge();
      case PurchaseSheetKind.storeError ||
          PurchaseSheetKind.networkError ||
          PurchaseSheetKind.verifyError:
        if (action == PurchaseSheetAction.primary) {
          if (_controller.canCheckAgain) {
            unawaited(_controller.checkAgain());
          } else if (_selected(products) case final p?) {
            _controller.acknowledge();
            unawaited(_buy(babyId, p));
          } else {
            _controller.acknowledge();
          }
        } else {
          _controller.acknowledge();
          // "Dùng mẫu miễn phí": back to the template flow, nothing bought.
          if (action == PurchaseSheetAction.secondary &&
              widget.entry == PaywallEntry.templates) {
            context.pop(false);
          }
        }
      default:
        _controller.acknowledge();
    }
  }

  /// The v2 entry: the card asked for, else what the legacy entry stands for.
  PremiumEntry get _v2Entry =>
      widget.v2Entry ??
      switch (widget.entry) {
        // Nhịp lớn lên asks for Premium: an entry point, not the user browsing.
        PaywallEntry.templates => PremiumEntry.video,
        PaywallEntry.rhythm => PremiumEntry.rhythm,
        PaywallEntry.plan => PremiumEntry.explore,
      };

  /// PW01–PW08 (Premium v2, D-101): same purchase flow, new page.
  Widget _v2(
    AppLocalizations l10n,
    String babyId,
    Capabilities caps,
    bool open,
    bool owner,
    bool premium,
    List<StoreProduct> products,
    PurchaseFlow flow,
    bool storeFailed,
  ) {
    final entry = _v2Entry;
    final plan = ref.watch(familyPlanV2Provider(babyId)).value;
    final baby = ref.watch(babyProvider(babyId)).value;
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];
    final manager = members.where((m) => m.isOwner).firstOrNull?.displayName;
    // The manager always sees the plans and the CTA (owner, 2026-10-25); until the store is
    // open the CTA says the payment step is coming, never a dead button.
    final footer = premium
        ? PaywallFooter.premium
        : !owner
        ? PaywallFooter.member
        : PaywallFooter.buy;
    final store = ref.watch(storeGatewayProvider);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return PaywallV2View(
      entry: entry,
      footer: footer,
      plan: plan,
      babyName: baby?.nickname ?? '',
      vnd: caps.country == null || caps.country == 'VN',
      storeName:
          (store.provider ??
                  (defaultTargetPlatform == TargetPlatform.android
                      ? StoreProvider.google
                      : StoreProvider.apple)) ==
              StoreProvider.google
          ? l10n.pv2StoreGoogle
          : l10n.pv2StoreApple,
      managerName: manager,
      // P-4 / P-6: progress while buying or verifying, and no second purchase while the store
      // has not settled the first.
      busy: flow.busy || flow.awaiting,
      busyLine: _busyLine(l10n, flow, store),
      onRetryPrice: () => ref.invalidate(familyPlanV2Provider(babyId)),
      onClose: () => context.pop(false),
      onRestore: owner && !premium
          ? () {
              if (storeFailed) {
                ref.invalidate(storeProductsProvider);
                showClToast(
                  context,
                  message: l10n.pmStoreLoadFailed,
                  error: true,
                );
                return;
              }
              if (store.available) {
                _restore(babyId);
              } else {
                showPaymentSoon(context);
              }
            }
          : null,
      onBuy: footer == PaywallFooter.buy
          ? (yearly) {
              // P-7: a store that could not be read is a failure with a retry, not "sắp mở".
              if (storeFailed) {
                ref.invalidate(storeProductsProvider);
                showClToast(
                  context,
                  message: l10n.pmStoreLoadFailed,
                  error: true,
                );
                return;
              }
              if (!open) {
                unawaited(showPaymentSoon(context));
                return;
              }
              final p =
                  products
                      .where(
                        (p) =>
                            p.period ==
                            (yearly
                                ? ProductPeriod.yearly
                                : ProductPeriod.monthly),
                      )
                      .firstOrNull ??
                  products.firstOrNull;
              if (p != null) unawaited(_buy(babyId, p));
            }
          : null,
      onTerms: () => unawaited(_openLegal(vi ? '/dieu-khoan/' : '/en/terms/')),
      onPrivacy: () =>
          unawaited(_openLegal(vi ? '/quyen-rieng-tu/' : '/en/privacy/')),
      onAskManager: () => unawaited(
        SharePlus.instance.share(ShareParams(text: l10n.pv2AskMessage)),
      ),
      onOpenPlan: () {
        context.pop(false);
        unawaited(GoRouter.of(context).push(Routes.mePlan));
      },
    );
  }

  String? _busyLine(
    AppLocalizations l10n,
    PurchaseFlow flow,
    StoreGateway store,
  ) => switch (flow.phase) {
    PurchasePhase.buying => l10n.pv2BusyBuying(
      store.provider == StoreProvider.google
          ? l10n.pv2StoreGoogle
          : l10n.pv2StoreApple,
    ),
    PurchasePhase.verifying => l10n.pv2BusyVerifying,
    PurchasePhase.restoring => l10n.pv2BusyRestoring,
    _ => flow.awaiting ? l10n.pv2BusyPending : null,
  };

  Future<void> _openLegal(String path) => launchUrl(
    Uri.parse('${ref.read(environmentProvider).webOrigin}$path'),
    mode: LaunchMode.inAppBrowserView,
  );

  /// The template's name for PR02 Success, from the draft kept for this purchase.
  String? _templateName() {
    final r = widget.resume;
    if (r == null ||
        r.kind == ResumeKind.rhythm ||
        r.kind == ResumeKind.assistant) {
      return null;
    }
    return resumeTemplateName(ref, r, Localizations.localeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final capsAsync = ref.watch(capabilitiesProvider(me.babyId));
    // P-1: this phone's last answer while the fresh one loads; a paying household never sees
    // the Free or member paywall because a read is slow or failed.
    final caps = ref.watch(capabilitiesNowProvider(me.babyId));
    final flow = ref.watch(purchaseControllerProvider);
    final store = ref.watch(storeGatewayProvider);
    final productsAsync = ref.watch(storeProductsProvider);
    final products = productsAsync.value ?? const <StoreProduct>[];
    ref.listen(purchaseControllerProvider, (prev, next) {
      if (prev?.phase != next.phase && next.source != 'plan') {
        unawaited(_onPhase(next, me.babyId, products));
      }
    });

    final owner = caps?.canManageBilling ?? false;
    final premium = caps?.plan == HouseholdPlan.premium;
    final region =
        caps?.reasonFor(Capability.rhythmAdvanced) ==
        GateReason.regionUnavailable;
    final open =
        owner &&
        !premium &&
        !region &&
        (caps?.features.billing ?? false) &&
        store.available &&
        products.isNotEmpty;
    final provider = store.provider;
    final product = _selected(products);

    final storeFailed =
        productsAsync.hasError &&
        store.available &&
        (caps?.features.billing ?? false);
    if (caps == null) {
      return _PlanUnknown(
        loading: capsAsync.isLoading,
        onClose: () => context.pop(false),
        onRetry: () => ref.invalidate(capabilitiesProvider(me.babyId)),
      );
    }
    if (caps.features.premiumV2) {
      return _v2(
        l10n,
        me.babyId,
        caps,
        open,
        owner,
        premium,
        products,
        flow,
        storeFailed,
      );
    }

    final groupA = _BenefitCard(
      title: l10n.pmGroupATitle,
      items: [l10n.pmGroupA1, l10n.pmGroupA2, l10n.pmGroupA3],
      here: widget.entry == PaywallEntry.rhythm,
    );
    final groupB = _BenefitCard(
      title: l10n.pmGroupBTitle,
      items: [l10n.pmGroupB1, l10n.pmGroupB2],
      here: widget.entry == PaywallEntry.templates,
    );

    Widget buyArea() {
      if (premium) {
        return MeNotice(
          icon: ClIcons.star,
          title: l10n.pmSuccessTitle,
          body: l10n.pmHouseholdHasBody,
        );
      }
      if (!owner) {
        return MeNotice(
          icon: ClIcons.family,
          title: l10n.pmAskOwnerTitle,
          body: l10n.pmAskOwnerBody,
        );
      }
      if (region) {
        return MeNotice(
          tone: MeTone.warn,
          icon: ClIcons.globe,
          title: l10n.pmGateRegionTitle,
          body: l10n.pmGateRegionBody,
        );
      }
      if (productsAsync.isLoading && store.available && caps.features.billing) {
        return const ClSkeleton(height: 96);
      }
      if (storeFailed) {
        return MeNotice(
          tone: MeTone.warn,
          icon: ClIcons.cloudOff,
          title: l10n.pmStoreLoadFailed,
          child: ClButton(
            label: l10n.actionRetry,
            style: ClButtonStyle.outline,
            expand: true,
            onPressed: () => ref.invalidate(storeProductsProvider),
          ),
        );
      }
      if (!open || product == null || provider == null) {
        return MeNotice(
          icon: ClIcons.clock,
          title: l10n.pmBuyClosedTitle,
          body: l10n.pmBuyClosedBody,
        );
      }
      final storeName = provider == StoreProvider.apple
          ? l10n.pmStoreApple
          : l10n.pmStoreGoogle;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (i, p) in products.indexed) ...[
                if (i > 0) const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: _PlanTile(
                    label: p.period == ProductPeriod.monthly
                        ? l10n.pmPeriodMonthly
                        : l10n.pmPeriodYearly,
                    price: p.price,
                    note: p.introOffer,
                    selected: p.period == product.period,
                    onTap: flow.busy
                        ? null
                        : () => setState(() => _period = p.period),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Text(
            [
              product.period == ProductPeriod.monthly
                  ? l10n.pmRenewMonthly(product.price)
                  : l10n.pmRenewYearly(product.price),
              l10n.pmRenewTerms(storeName),
            ].join(' '),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Row(
                children: [
                  _RoundIcon(
                    icon: ClIcons.close,
                    label: l10n.a11yClose,
                    onTap: () => context.pop(false),
                  ),
                  const Spacer(),
                  // Restore only where the store can be asked (owner, store open).
                  if (owner && !premium && store.available)
                    ClPressable(
                      onPressed: flow.busy ? null : () => _restore(me.babyId),
                      semanticLabel: l10n.pmRestore,
                      child: Padding(
                        padding: const EdgeInsets.all(ClSpace.s2),
                        child: Text(
                          l10n.pmRestore,
                          style: cl.text.label.copyWith(
                            color: cl.colors.mintText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  open ? ClSpace.s6 : bottom + ClSpace.s6,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.pmPlanPremium, style: cl.text.largeTitle),
                  ),
                  const SizedBox(height: ClSpace.s1),
                  Text(
                    l10n.pmPaywallSubtitle,
                    style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  ...switch (widget.entry) {
                    PaywallEntry.templates => [groupB, groupA],
                    _ => [groupA, groupB],
                  }.expand((c) => [c, const SizedBox(height: ClSpace.s3)]),
                  _FreeBox(
                    title: l10n.pmPlanAlwaysFree,
                    body: l10n.pmPaywallFreeBody,
                  ),
                  const SizedBox(height: ClSpace.s4),
                  buyArea(),
                  const SizedBox(height: ClSpace.s4),
                  _LegalLinks(),
                ],
              ),
            ),
            if (open && product != null)
              Container(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  bottom + ClSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.cloud,
                  border: Border(top: BorderSide(color: cl.colors.separator)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClButton(
                      label: l10n.pmContinuePremium,
                      expand: true,
                      loading: flow.busy || flow.awaiting,
                      onPressed: flow.busy || flow.awaiting
                          ? null
                          : () => _buy(me.babyId, product),
                    ),
                    if (_busyLine(l10n, flow, store) case final line?) ...[
                      const SizedBox(height: ClSpace.s2),
                      Text(
                        line,
                        textAlign: TextAlign.center,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: ClSpace.s2),
                    Text(
                      l10n.pmStoreLegal,
                      textAlign: TextAlign.center,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// P-1: the plan is not known yet (loading: a neutral skeleton) or could not be read (a retry).
/// Neither the light legacy page nor the dark v2 page is guessed.
class _PlanUnknown extends StatelessWidget {
  const _PlanUnknown({
    required this.loading,
    required this.onClose,
    required this.onRetry,
  });
  final bool loading;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _RoundIcon(
                  icon: ClIcons.close,
                  label: l10n.a11yClose,
                  onTap: onClose,
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              if (loading) ...[
                const ClSkeleton(width: 220, height: 32),
                const SizedBox(height: ClSpace.s3),
                const ClSkeleton(height: 120),
                const SizedBox(height: ClSpace.s3),
                const ClSkeleton(height: 120),
              ] else
                MeNotice(
                  tone: MeTone.warn,
                  icon: ClIcons.cloudOff,
                  title: l10n.premiumPlanCheckFailed,
                  body: l10n.premiumPlanCheckFailedBody,
                  child: ClButton(
                    label: l10n.actionRetry,
                    style: ClButtonStyle.outline,
                    expand: true,
                    onPressed: onRetry,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: c.ink),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.title,
    required this.items,
    required this.here,
  });
  final String title;
  final List<String> items;

  /// The group the paywall was opened from: outlined, with "Bạn đang xem".
  final bool here;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 4),
        border: Border.all(
          color: here ? cl.colors.mintDeep : cl.colors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: cl.text.bodyStrong)),
              if (here) ...[
                const SizedBox(width: ClSpace.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.pmPaywallHere,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: ClSpace.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ClIcon(
                      ClIcons.check,
                      size: 16,
                      color: cl.colors.mintText,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      item,
                      style: cl.text.label.copyWith(color: cl.colors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FreeBox extends StatelessWidget {
  const _FreeBox({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.card - 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: cl.text.bodyStrong),
          const SizedBox(height: 2),
          Text(body, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.note,
  });
  final String label;
  final String price;
  final String? note;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      selected: selected,
      button: true,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: '$label, $price',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cl.colors.mintDeep : cl.colors.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: cl.text.label.copyWith(color: cl.colors.ink)),
              const SizedBox(height: 2),
              Text(price, style: cl.text.bodyStrong),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  style: cl.text.caption.copyWith(color: cl.colors.mintText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Terms of Use and Privacy Policy on the environment's site (`apps/landing`), in an in-app
/// browser (store guidelines for subscriptions).
class _LegalLinks extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    Future<void> open(String path) => launchUrl(
      Uri.parse('${ref.read(environmentProvider).webOrigin}$path'),
      mode: LaunchMode.inAppBrowserView,
    );
    Widget link(String label, String path) => ClPressable(
      onPressed: () => unawaited(open(path)),
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
        child: Text(
          label,
          style: cl.text.caption.copyWith(
            color: cl.colors.mintText,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: cl.colors.mintText,
          ),
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link(l10n.pmTerms, vi ? '/dieu-khoan/' : '/en/terms/'),
        Text(
          '  ·  ',
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        link(l10n.pmPrivacy, vi ? '/quyen-rieng-tu/' : '/en/privacy/'),
      ],
    );
  }
}

/// PR01 above the tabs, sliding up with a close button.
List<RouteBase> premiumRoutes() => [
  GoRoute(
    path: Routes.premium,
    pageBuilder: (context, state) => MaterialPage<Object?>(
      key: state.pageKey,
      fullscreenDialog: true,
      name: state.name ?? state.path,
      arguments: state.uri.queryParameters,
      restorationId: state.pageKey.value,
      child: PaywallScreen(
        entry: PaywallEntry.fromWire(state.uri.queryParameters['entry']),
        resume: PurchaseResume.fromQuery(state.uri.queryParameters),
        awaited: state.extra is PaywallHandoff,
        v2Entry: PremiumEntry.fromWire(state.uri.queryParameters['card']),
        subject: state.uri.queryParameters['subject'],
      ),
    ),
  ),
  // Premium v2 (D-101): PV41 history, PV42 cancel, PW10 extra storage.
  ...planV2Routes(),
];
