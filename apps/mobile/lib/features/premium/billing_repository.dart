import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'billing_models.dart';
import 'premium_repository.dart';
import 'store_gateway.dart';

/// The billing and quota callables (plan §5.2–5.3; contracts `billing.ts`, `quota.ts`). Each
/// refusal comes back as a [PremiumException] with its reason (`NOT_MEMBER`, `ROLE_DENIED`…).
abstract interface class BillingApi {
  /// `config/billing` products as published for the paywall (none = nothing to sell, P-152).
  Future<List<BillingProductIds>> productIds();

  /// `startPurchase` (owner only, D-072 #1): the intent the store purchase is bound to.
  Future<PurchaseIntent> startPurchase({
    required String babyId,
    required ProductPeriod period,
    required StoreProvider provider,
    required PaywallEntry entry,
    required PurchaseResume? resume,
  });

  /// `verifyPurchase`: what the store reported; the server asks the provider itself.
  Future<PurchaseAnswer> verifyPurchase({
    required String intentId,
    required StorePurchase purchase,
  });

  /// `restorePurchase`: never moves a subscription from another household.
  Future<PurchaseAnswer> restorePurchase({
    required String babyId,
    required StoreProvider provider,
    required List<StorePurchase> purchases,
  });

  /// `getVideoQuota` (MO04).
  Future<VideoQuota?> videoQuota(String babyId);
}

class FirebaseBillingApi implements BillingApi {
  FirebaseBillingApi(this._functions, this._db);
  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return r.data is Map
          ? Map<String, dynamic>.from(r.data! as Map)
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw PremiumException(
        details is Map && details['reason'] is String
            ? details['reason'] as String
            : e.code,
      );
    }
  }

  // Needs a Rules `get` on publicConfig/billing and the server's projection of config/billing;
  // until then (D-074, P-152) there is nothing to read and nothing is sold.
  @override
  Future<List<BillingProductIds>> productIds() async {
    try {
      final d = await _db.doc('publicConfig/billing').get();
      return BillingProductIds.listFromJson(d.data());
    } on Object {
      return const [];
    }
  }

  @override
  Future<PurchaseIntent> startPurchase({
    required String babyId,
    required ProductPeriod period,
    required StoreProvider provider,
    required PaywallEntry entry,
    required PurchaseResume? resume,
  }) async {
    final intent = PurchaseIntent.fromJson(
      await _call('startPurchase', {
        'babyId': babyId,
        'productKey': period.name,
        'provider': provider.name,
        'entryPoint': entry.name,
        // The chat's resume stays on this phone (not in the server's resume schema).
        'resume': resume?.kind == ResumeKind.assistant
            ? null
            : resume?.toJson(),
      }),
    );
    if (intent == null) throw const PremiumException('bad-answer');
    return intent;
  }

  @override
  Future<PurchaseAnswer> verifyPurchase({
    required String intentId,
    required StorePurchase purchase,
  }) async {
    final answer = PurchaseAnswer.fromJson(
      await _call('verifyPurchase', {
        'provider': purchase.provider.name,
        'intentId': intentId,
        if (purchase.provider == StoreProvider.apple)
          'transactionId': purchase.transactionId
        else ...{
          'productId': purchase.productId,
          'purchaseToken': purchase.purchaseToken,
        },
      }),
    );
    if (answer == null) throw const PremiumException('bad-answer');
    return answer;
  }

  @override
  Future<PurchaseAnswer> restorePurchase({
    required String babyId,
    required StoreProvider provider,
    required List<StorePurchase> purchases,
  }) async {
    final answer = PurchaseAnswer.fromJson(
      await _call('restorePurchase', {
        'provider': provider.name,
        'babyId': babyId,
        if (provider == StoreProvider.apple)
          'transactionIds': [
            for (final p in purchases.take(20)) ?p.transactionId,
          ]
        else
          'purchases': [
            for (final p in purchases.take(20))
              {'productId': p.productId, 'purchaseToken': p.purchaseToken},
          ],
      }),
    );
    if (answer == null) throw const PremiumException('bad-answer');
    return answer;
  }

  @override
  Future<VideoQuota?> videoQuota(String babyId) async =>
      VideoQuota.fromJson(await _call('getVideoQuota', {'babyId': babyId}));
}

final billingApiProvider = Provider<BillingApi>(
  (ref) => FirebaseBillingApi(
    ref.watch(functionsProvider),
    ref.watch(firestoreProvider),
  ),
  retry: (_, _) => null,
);

/// What the store sells here: the configured ids priced by the storefront. Empty while the store
/// gateway is not open (D-074), `config/billing` has no products (P-152) or the store is away.
final storeProductsProvider = FutureProvider.autoDispose<List<StoreProduct>>((
  ref,
) async {
  final store = ref.watch(storeGatewayProvider);
  final provider = store.provider;
  if (!store.available || provider == null) return const [];
  final ids = await ref.watch(billingApiProvider).productIds();
  final byPeriod = {for (final p in ids) p.period: ?p.idFor(provider)};
  if (byPeriod.isEmpty) return const [];
  final products = await store.products(byPeriod);
  return [...products]..sort((a, b) => a.period.index - b.period.index);
}, retry: (_, _) => null);

/// MO04: the household's video exports this period; null when unknown (offline, no ledger yet).
final videoQuotaProvider = FutureProvider.autoDispose
    .family<VideoQuota?, String>((ref, babyId) async {
      // No Firebase (widget tests): nothing to show, like capabilitiesProvider.
      if (Firebase.apps.isEmpty) return null;
      try {
        return await ref.watch(billingApiProvider).videoQuota(babyId);
      } on Object {
        return null;
      }
    }, retry: (_, _) => null);
