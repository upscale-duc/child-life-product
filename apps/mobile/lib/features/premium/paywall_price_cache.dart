import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_shell.dart' show selectedMembershipProvider;
import '../../core/appearance/appearance_providers.dart';
import 'premium_v2.dart';

/// Display prices only: never caches balances, seats, permissions or entitlements.
/// Expired/invalid prices do not unlock a purchase. The store still owns checkout.
class PaywallPriceCache {
  PaywallPriceCache(this.prefs, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final SharedPreferences prefs;
  final DateTime Function() now;
  static const maxAge = Duration(hours: 24);
  static String key(String uid, String babyId, bool vnd) =>
      'premium.prices.$uid.$babyId.${vnd ? 'vn' : 'intl'}';

  PlanPrice? read(String uid, String babyId, bool vnd) =>
      readEntry(uid, babyId, vnd)?.price;

  ({PlanPrice price, Duration remaining})? readEntry(
    String uid,
    String babyId,
    bool vnd,
  ) {
    try {
      final raw = prefs.getString(key(uid, babyId, vnd));
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map;
      final at = DateTime.fromMillisecondsSinceEpoch(data['at'] as int);
      final age = now().difference(at);
      if (age.isNegative || age >= maxAge) return null;
      final price = PlanPrice.tryParse(data);
      return price != null && price.month.isFinite && price.year.isFinite
          ? (price: price, remaining: maxAge - age)
          : null;
    } on Object {
      return null;
    }
  }

  Future<void> write(
    String uid,
    String babyId,
    bool vnd,
    PlanPrice? price,
  ) async {
    final k = key(uid, babyId, vnd);
    if (price == null || !price.month.isFinite || !price.year.isFinite) {
      await prefs.remove(k);
      return;
    }
    await prefs.setString(
      k,
      jsonEncode({
        'at': now().millisecondsSinceEpoch,
        'month': price.month,
        'year': price.year,
      }),
    );
  }
}

final paywallPriceCacheProvider = Provider<PaywallPriceCache>(
  (ref) => PaywallPriceCache(ref.watch(sharedPreferencesProvider)),
);

typedef PaywallPriceQuery = ({String babyId, bool vnd});

/// Warmed by Home before navigation; falls back only to a recent, matching price.
/// A successful response explicitly removing a price always beats the cache.
final paywallPriceProvider = Provider.autoDispose
    .family<PlanPrice?, PaywallPriceQuery>((ref, q) {
      final me = ref.watch(selectedMembershipProvider);
      if (me == null || !me.isActive || me.babyId != q.babyId) {
        return null;
      }
      final cache = ref.watch(paywallPriceCacheProvider);
      final plan = ref.watch(familyPlanV2Provider(q.babyId)).value;
      if (plan != null) {
        final price = plan.price(vnd: q.vnd);
        unawaited(
          cache.write(me.uid, q.babyId, q.vnd, price).catchError((Object _) {}),
        );
        return price;
      }
      final entry = cache.readEntry(me.uid, q.babyId, q.vnd);
      if (entry == null) return null;
      final expiry = Timer(entry.remaining, ref.invalidateSelf);
      ref.onDispose(expiry.cancel);
      return entry.price;
    });
