import 'dart:async';

import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/store_gateway.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Premium Slice 4 without a store or Firebase: a fake store gateway (the app ships the
/// unavailable one, D-074), fake billing callables and a household whose capabilities a test
/// can change (as the server would after a verified purchase).

const yearly = StoreProduct(
  id: 'app.childlife.premium.yearly',
  period: ProductPeriod.yearly,
  price: '499.000 ₫',
);
const monthly = StoreProduct(
  id: 'app.childlife.premium.monthly',
  period: ProductPeriod.monthly,
  price: '59.000 ₫',
);

class FakeStore implements StoreGateway {
  FakeStore({
    this.available = true,
    this.provider = StoreProvider.apple,
    this.items = const [monthly, yearly],
  });

  @override
  final bool available;
  @override
  final StoreProvider? provider;
  final List<StoreProduct> items;
  final _updates = StreamController<StorePurchase>.broadcast();
  final bought = <({String productId, String accountToken})>[];
  final completed = <StorePurchase>[];
  var owned = <StorePurchase>[];

  /// The store's answer to a purchase (Apple transaction).
  StorePurchase purchase(
    StorePurchaseStatus status, {
    String productId = 'app.childlife.premium.yearly',
  }) => StorePurchase(
    provider: provider ?? StoreProvider.apple,
    productId: productId,
    status: status,
    transactionId: '2000000999',
    purchaseToken: 'gp-token',
    accountToken: bought.lastOrNull?.accountToken,
  );

  void emit(StorePurchase p) => _updates.add(p);

  @override
  Future<List<StoreProduct>> products(Map<ProductPeriod, String> ids) async => [
    for (final p in items)
      if (ids[p.period] == p.id) p,
  ];

  @override
  Future<void> buy(
    StoreProduct product, {
    required String accountToken,
  }) async => bought.add((productId: product.id, accountToken: accountToken));

  @override
  Stream<StorePurchase> get purchases => _updates.stream;

  @override
  Future<void> complete(StorePurchase purchase) async =>
      completed.add(purchase);

  @override
  Future<List<StorePurchase>> restore() async => owned;

  @override
  Uri manageUri(StoreProvider provider) => storeManageUri(provider);
}

/// What the household looks like to `getCapabilities`; a test (or a verify) changes it.
class FakeHousehold {
  FakeHousehold(this.json);
  Map<String, Object?> json;
}

class FakeBilling implements BillingApi {
  FakeBilling({this.onActive});

  /// Called when the server grants (verify / restore answered `active`).
  final void Function()? onActive;
  List<BillingProductIds> ids = const [
    BillingProductIds(
      period: ProductPeriod.monthly,
      apple: 'app.childlife.premium.monthly',
      google: 'premium-monthly',
    ),
    BillingProductIds(
      period: ProductPeriod.yearly,
      apple: 'app.childlife.premium.yearly',
      google: 'premium-yearly',
    ),
  ];
  final starts = <Map<String, Object?>>[];
  final verifies = <({String intentId, StorePurchase purchase})>[];
  final restores = <List<StorePurchase>>[];

  /// Answers in order; the last one repeats.
  List<Object> verifyAnswers = [PurchaseOutcome.active];
  Object restoreAnswer = PurchaseOutcome.active;
  Object? startError;
  VideoQuota? quota;

  static const intentId = '1b4e28ba-2fa1-41d2-883f-0016d3cca427';

  @override
  Future<List<BillingProductIds>> productIds() async => ids;

  @override
  Future<PurchaseIntent> startPurchase({
    required String babyId,
    required ProductPeriod period,
    required StoreProvider provider,
    required PaywallEntry entry,
    required PurchaseResume? resume,
  }) async {
    starts.add({
      'babyId': babyId,
      'productKey': period.name,
      'provider': provider.name,
      'entryPoint': entry.name,
      'resume': resume?.toJson(),
    });
    if (startError case final e?) throw e;
    return PurchaseIntent(
      intentId: intentId,
      accountToken: intentId,
      productId: 'app.childlife.premium.${period.name}',
    );
  }

  PurchaseAnswer _answer(Object a) {
    if (a is! PurchaseOutcome) throw a;
    if (a == PurchaseOutcome.active) onActive?.call();
    return PurchaseAnswer(outcome: a);
  }

  @override
  Future<PurchaseAnswer> verifyPurchase({
    required String intentId,
    required StorePurchase purchase,
  }) async {
    verifies.add((intentId: intentId, purchase: purchase));
    final a = verifyAnswers.length >= verifies.length
        ? verifyAnswers[verifies.length - 1]
        : verifyAnswers.last;
    return _answer(a);
  }

  @override
  Future<PurchaseAnswer> restorePurchase({
    required String babyId,
    required StoreProvider provider,
    required List<StorePurchase> purchases,
  }) async {
    restores.add(purchases);
    return _answer(restoreAnswer);
  }

  @override
  Future<VideoQuota?> videoQuota(String babyId) async => quota;
}

/// Store, billing and the household's capabilities for one test.
List<Override> premiumOverrides({
  required FakeHousehold household,
  StoreGateway? store,
  BillingApi? billing,
}) => [
  capabilitiesProvider.overrideWith(
    (ref, babyId) async => Capabilities.fromJson(household.json),
  ),
  storeGatewayProvider.overrideWithValue(
    store ?? const UnavailableStoreGateway(),
  ),
  billingApiProvider.overrideWithValue(billing ?? FakeBilling()),
];
