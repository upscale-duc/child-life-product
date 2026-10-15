import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's store (StoreKit 2 / Play Billing) behind one interface (plan §5.2, D-072 #6).
///
/// D-074 (owner, 2026-10-15: "Thanh toán thật với apple google làm sau"): real Apple / Google
/// payment is a later slice, so the app ships [UnavailableStoreGateway] and the paywall reads
/// "chưa mở". A later slice adds an adapter over the official `in_app_purchase` plugin that
/// implements this interface; nothing else in the app changes. Tests use a fake.
///
/// The store's word is never access: the app sends what the store reported to the server
/// (`verifyPurchase` / `restorePurchase`) and draws access only from `getCapabilities`.
enum StoreProvider {
  apple,
  google;

  /// The store of the phone the app runs on; null where there is none (web, desktop, tests).
  static StoreProvider? get current => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => StoreProvider.apple,
    TargetPlatform.android => StoreProvider.google,
    _ => null,
  };

  static StoreProvider? fromWire(Object? v) =>
      values.where((p) => p.name == v).firstOrNull;
}

/// The billing period of a product (`config/billing` products, contracts `billing.ts`).
enum ProductPeriod { monthly, yearly }

/// One subscription as the storefront shows it. Price, currency, period and renewal copy come
/// from the store only, never from our config (brief p.4, PR01 "Giá/kỳ/renewal từ storefront").
@immutable
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.period,
    required this.price,
    this.introOffer,
  });

  /// The store's product id.
  final String id;
  final ProductPeriod period;

  /// Formatted by the store in the account's currency, e.g. "49.000 ₫".
  final String price;

  /// The store's own description of a free trial or intro price, when there is one.
  final String? introOffer;
}

enum StorePurchaseStatus { pending, purchased, restored, error, canceled }

/// What the store reported for one transaction.
@immutable
class StorePurchase {
  const StorePurchase({
    required this.provider,
    required this.productId,
    required this.status,
    this.transactionId,
    this.purchaseToken,
    this.accountToken,
    this.errorCode,
    this.handle,
  });

  final StoreProvider provider;
  final String productId;
  final StorePurchaseStatus status;

  /// Apple: the StoreKit 2 transaction id (the server fetches the signed transaction).
  final String? transactionId;

  /// Google: the purchase token.
  final String? purchaseToken;

  /// Apple `appAccountToken` / Google `obfuscatedAccountId` echoed back, when the store has it:
  /// the purchase intent it was bought for.
  final String? accountToken;
  final String? errorCode;

  /// The adapter's own object, handed back to [StoreGateway.complete].
  final Object? handle;
}

abstract interface class StoreGateway {
  /// The store can sell on this phone now (billing set up, store reachable).
  bool get available;

  /// The store this phone buys from; null when [available] is false.
  StoreProvider? get provider;

  /// Storefront details for [ids] (product id per period, from `publicConfig/billing`);
  /// products the store does not know are left out.
  Future<List<StoreProduct>> products(Map<ProductPeriod, String> ids);

  /// Opens the store's purchase sheet for [product], bound to [accountToken] (the purchase
  /// intent from `startPurchase`: Apple `appAccountToken`, Google `obfuscatedAccountId`). The
  /// outcome arrives on [purchases], possibly much later (Ask to Buy, slow cards).
  Future<void> buy(StoreProduct product, {required String accountToken});

  /// Every transaction update, including ones finishing after an app restart.
  Stream<StorePurchase> get purchases;

  /// Finishes (Apple) / closes (Google) a transaction. Called only after the server answered
  /// for it; a pending one is kept so the store delivers it again.
  Future<void> complete(StorePurchase purchase);

  /// The subscriptions this store account owns, for `restorePurchase` (PR01 / PR03 "Khôi phục").
  Future<List<StorePurchase>> restore();

  /// The store's own subscription management page (PR03 "Quản lý trong App Store").
  Uri manageUri(StoreProvider provider);
}

/// The store pages where a subscriber manages or cancels (PR03); Apple's opens Settings.
Uri storeManageUri(StoreProvider provider) => switch (provider) {
  StoreProvider.apple => Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  ),
  StoreProvider.google => Uri.parse(
    'https://play.google.com/store/account/subscriptions',
  ),
};

/// D-074: no store SDK in the app yet. Nothing can be bought or restored; the paywall says so.
class UnavailableStoreGateway implements StoreGateway {
  const UnavailableStoreGateway();

  @override
  bool get available => false;

  @override
  StoreProvider? get provider => null;

  @override
  Future<List<StoreProduct>> products(Map<ProductPeriod, String> ids) async =>
      const [];

  @override
  Future<void> buy(StoreProduct product, {required String accountToken}) =>
      Future.error(StateError('In-app purchase is not available yet'));

  @override
  Stream<StorePurchase> get purchases => const Stream.empty();

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<List<StorePurchase>> restore() async => const [];

  @override
  Uri manageUri(StoreProvider provider) => storeManageUri(provider);
}

final storeGatewayProvider = Provider<StoreGateway>(
  (ref) => const UnavailableStoreGateway(),
);
