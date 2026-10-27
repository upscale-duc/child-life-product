import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import 'billing_models.dart';
import 'billing_repository.dart';
import 'premium_models.dart';
import 'premium_repository.dart';
import 'store_gateway.dart';

/// PR02 · Mua/Trạng thái (592:6781): where a purchase or a restore stands.
enum PurchasePhase {
  idle,

  /// `startPurchase`, then the store's own sheet.
  buying,

  /// The server is checking what the store reported.
  verifying,

  /// Not granted (yet): the store or the server is waiting. No access, selection kept.
  pending,

  /// Verified and `getCapabilities` shows Premium.
  success,
  restoring,

  /// A restore re-linked a subscription to this household.
  restored,
  error,
}

enum PurchaseProblem {
  /// The store refused or failed (card declined, store away).
  store,

  /// The phone could not reach Child Life; the store's transaction is kept to verify again.
  network,

  /// The server could not confirm the transaction with the store.
  verify,

  /// Only the family owner buys and restores (D-072 #1).
  notOwner,

  /// The subscription belongs to another household; never moved (plan §5.2).
  alreadyBound,

  /// Restore found no valid subscription on this store account.
  nothingToRestore,
}

@immutable
class PurchaseFlow {
  const PurchaseFlow({
    this.phase = PurchasePhase.idle,
    this.problem,
    this.resume,
    this.restore = false,
    this.source,
    this.awaiting = false,
  });

  final PurchasePhase phase;

  /// The store has not settled a purchase this phone started (Pending, P-6): kept after the
  /// sheet is answered, so the buy CTA stays off until it succeeds, fails or is cancelled.
  final bool awaiting;
  final PurchaseProblem? problem;
  final PurchaseResume? resume;

  /// The phase belongs to a restore, not a new purchase.
  final bool restore;

  /// The screen that started it (`paywall`, `plan`): only that one shows the result sheets.
  final String? source;

  bool get busy =>
      phase == PurchasePhase.buying ||
      phase == PurchasePhase.verifying ||
      phase == PurchasePhase.restoring;
}

/// Buys and restores through the [StoreGateway] and the billing callables (plan §5.2).
///
/// The store's "purchased" is never access: the transaction goes to `verifyPurchase`, the
/// store transaction is completed only once the server answered for it (a pending one is kept
/// so the store delivers it again), and access is read back from `getCapabilities`.
class PurchaseController extends Notifier<PurchaseFlow> {
  static const _intentKey = 'premium.intent';

  StreamSubscription<StorePurchase>? _sub;
  String? _babyId;
  PurchaseIntent? _intent;

  /// The store transaction waiting for a server answer (verified again on "Kiểm tra lại").
  StorePurchase? _waiting;

  @override
  PurchaseFlow build() {
    final store = ref.watch(storeGatewayProvider);
    _sub = store.purchases.listen(_onStore);
    ref.onDispose(() => _sub?.cancel());
    // A purchase started before the app was closed: its intent, so the store's late delivery
    // can still be verified, and where to come back to.
    final saved = _readIntent();
    _intent = saved?.$1;
    _babyId = saved?.$2;
    return PurchaseFlow(resume: saved?.$3);
  }

  BillingApi get _api => ref.read(billingApiProvider);
  StoreGateway get _store => ref.read(storeGatewayProvider);

  (PurchaseIntent, String, PurchaseResume?)? _readIntent() {
    final raw = ref.read(sharedPreferencesProvider).getString(_intentKey);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw);
      final intent = PurchaseIntent.fromJson(j);
      if (intent == null || j is! Map || j['babyId'] is! String) return null;
      return (
        intent,
        j['babyId'] as String,
        PurchaseResume.fromJson(j['resume']),
      );
    } on FormatException {
      return null;
    }
  }

  void _saveIntent(PurchaseIntent i, String babyId, PurchaseResume? resume) =>
      ref
          .read(sharedPreferencesProvider)
          .setString(
            _intentKey,
            jsonEncode({
              'intentId': i.intentId,
              'accountToken': i.accountToken,
              'productId': i.productId,
              'babyId': babyId,
              'resume': resume?.toJson(),
            }),
          );

  void _clearIntent() {
    _intent = null;
    _waiting = null;
    ref.read(sharedPreferencesProvider).remove(_intentKey);
  }

  void _set(PurchasePhase phase, {PurchaseProblem? problem, bool? restore}) =>
      state = PurchaseFlow(
        phase: phase,
        problem: problem,
        resume: state.resume,
        restore: restore ?? state.restore,
        source: state.source,
        awaiting: switch (phase) {
          PurchasePhase.pending => true,
          PurchasePhase.buying ||
          PurchasePhase.verifying ||
          PurchasePhase.restoring => state.awaiting,
          _ => false,
        },
      );

  /// PR01 "Tiếp tục với Premium" (owner only; the server refuses anyone else).
  Future<void> buy({
    required String babyId,
    required StoreProduct product,
    required PaywallEntry entry,
    required PurchaseResume? resume,
  }) async {
    final provider = _store.provider;
    if (state.busy || state.awaiting || provider == null) return;
    _babyId = babyId;
    state = PurchaseFlow(
      phase: PurchasePhase.buying,
      resume: resume,
      source: 'paywall',
    );
    final PurchaseIntent intent;
    try {
      intent = await _api.startPurchase(
        babyId: babyId,
        period: product.period,
        provider: provider,
        entry: entry,
        resume: resume,
      );
    } on PremiumException catch (e) {
      _set(
        PurchasePhase.error,
        problem: e.gate == GateReason.roleDenied
            ? PurchaseProblem.notOwner
            : PurchaseProblem.network,
      );
      return;
    } on Object {
      _set(PurchasePhase.error, problem: PurchaseProblem.network);
      return;
    }
    _intent = intent;
    _saveIntent(intent, babyId, resume);
    try {
      await _store.buy(product, accountToken: intent.accountToken);
    } on Object {
      _set(PurchasePhase.error, problem: PurchaseProblem.store);
    }
    // The outcome arrives on the store's purchase stream.
  }

  void _onStore(StorePurchase p) {
    switch (p.status) {
      case StorePurchaseStatus.canceled:
        // The parent closed the store sheet: back to the paywall, selection kept.
        // A declined Ask to Buy also ends the wait.
        if (state.phase == PurchasePhase.buying || state.awaiting) {
          _set(PurchasePhase.idle);
        }
      case StorePurchaseStatus.error:
        _set(PurchasePhase.error, problem: PurchaseProblem.store);
      case StorePurchaseStatus.pending:
        // Ask to Buy, a slow card: nothing to verify yet, nothing granted.
        _set(PurchasePhase.pending);
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        unawaited(_verify(p));
    }
  }

  Future<void> _verify(StorePurchase p) async {
    final intent = _intent;
    // Renewals and purchases this phone did not start are the server's business
    // (notifications, reconciler); restore handles the rest.
    if (intent == null) return;
    _waiting = p;
    _set(PurchasePhase.verifying);
    final PurchaseAnswer answer;
    try {
      answer = await _api.verifyPurchase(
        intentId: intent.intentId,
        purchase: p,
      );
    } on PremiumException catch (e) {
      _set(
        PurchasePhase.error,
        problem: e.gate == GateReason.roleDenied
            ? PurchaseProblem.notOwner
            : PurchaseProblem.verify,
      );
      return;
    } on Object {
      _set(PurchasePhase.error, problem: PurchaseProblem.network);
      return;
    }
    switch (answer.outcome) {
      case PurchaseOutcome.active:
        await _complete(p);
        await _conclude(PurchasePhase.success);
      case PurchaseOutcome.pending:
        // Kept unfinished: the store delivers it again when it settles.
        _set(PurchasePhase.pending);
      case PurchaseOutcome.alreadyBound:
        await _complete(p);
        _clearIntent();
        _set(PurchasePhase.error, problem: PurchaseProblem.alreadyBound);
      case PurchaseOutcome.notOwner:
        _set(PurchasePhase.error, problem: PurchaseProblem.notOwner);
      case PurchaseOutcome.expired:
        await _complete(p);
        _clearIntent();
        _set(PurchasePhase.error, problem: PurchaseProblem.verify);
      case PurchaseOutcome.notFound:
        _set(PurchasePhase.error, problem: PurchaseProblem.verify);
    }
  }

  Future<void> _complete(StorePurchase p) async {
    try {
      await _store.complete(p);
    } on Object {
      // The store delivers it again; the server's answer is already recorded.
    }
  }

  /// Access is what `getCapabilities` says after the server's answer, never the store's.
  Future<void> _conclude(PurchasePhase done) async {
    final babyId = _babyId;
    Capabilities? caps;
    if (babyId != null) {
      ref.invalidate(capabilitiesProvider(babyId));
      // Held while it loads: the provider is auto-dispose.
      final hold = ref.listen(capabilitiesProvider(babyId), (_, _) {});
      try {
        caps = await ref.read(capabilitiesProvider(babyId).future);
      } on Object {
        caps = null;
      } finally {
        hold.close();
      }
    }
    if (caps?.plan == HouseholdPlan.premium) {
      _clearIntent();
      _set(done);
    } else {
      // Granted on the server but not visible yet: "Kiểm tra lại".
      _set(PurchasePhase.pending);
    }
  }

  /// PR02 Pending "Kiểm tra lại" and Error "Thử lại" after a server problem: the same store
  /// transaction again, or just the household's capabilities.
  Future<void> checkAgain() async {
    if (state.busy) return;
    final p = _waiting;
    if (p != null && _intent != null) {
      await _verify(p);
    } else {
      _set(PurchasePhase.verifying);
      await _conclude(
        state.restore ? PurchasePhase.restored : PurchasePhase.success,
      );
    }
  }

  /// The store transaction can be sent to the server again (vs. buying again).
  bool get canCheckAgain => _waiting != null && _intent != null;

  /// PR01 / PR03 "Khôi phục", after the confirm sheet (owner only).
  Future<void> restore(String babyId, {String source = 'paywall'}) async {
    final provider = _store.provider;
    if (state.busy || provider == null) return;
    _babyId = babyId;
    state = PurchaseFlow(
      phase: PurchasePhase.restoring,
      resume: state.resume,
      restore: true,
      source: source,
    );
    final List<StorePurchase> owned;
    try {
      owned = await _store.restore();
    } on Object {
      _set(PurchasePhase.error, problem: PurchaseProblem.store);
      return;
    }
    if (owned.isEmpty) {
      _set(PurchasePhase.error, problem: PurchaseProblem.nothingToRestore);
      return;
    }
    final PurchaseAnswer answer;
    try {
      answer = await _api.restorePurchase(
        babyId: babyId,
        provider: provider,
        purchases: owned,
      );
    } on PremiumException catch (e) {
      _set(
        PurchasePhase.error,
        problem: e.gate == GateReason.roleDenied
            ? PurchaseProblem.notOwner
            : PurchaseProblem.verify,
      );
      return;
    } on Object {
      _set(PurchasePhase.error, problem: PurchaseProblem.network);
      return;
    }
    switch (answer.outcome) {
      case PurchaseOutcome.active:
        for (final p in owned) {
          await _complete(p);
        }
        await _conclude(PurchasePhase.restored);
      case PurchaseOutcome.pending:
        _set(PurchasePhase.pending);
      case PurchaseOutcome.alreadyBound:
        _set(PurchasePhase.error, problem: PurchaseProblem.alreadyBound);
      case PurchaseOutcome.notOwner:
        _set(PurchasePhase.error, problem: PurchaseProblem.notOwner);
      case PurchaseOutcome.expired:
      case PurchaseOutcome.notFound:
        _set(PurchasePhase.error, problem: PurchaseProblem.nothingToRestore);
    }
  }

  /// The sheet was answered: back to idle (the resume record stays until used).
  void acknowledge() => state = PurchaseFlow(
    resume: state.resume,
    awaiting: state.awaiting,
    source: state.awaiting ? state.source : null,
  );

  /// Done with the resume record (resumed or abandoned).
  void reset() {
    if (state.phase == PurchasePhase.success ||
        state.phase == PurchasePhase.restored) {
      _clearIntent();
    }
    state = const PurchaseFlow();
  }
}

final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseFlow>(PurchaseController.new);
