import 'package:flutter/foundation.dart';

/// Chi tiêu currencies (D-075 #4; plan `docs/product/spending-currency-plan.md`). Mirrors
/// `currencyInfo` in `packages/contracts/src/spending.ts` and Rules `currencyMax()`.
///
/// An amount is an integer in the currency's MINOR units with its ISO 4217 exponent (VND 0 →
/// đồng, USD 2 → cents, JPY 0 → yen). A document without `currency` is VND, so everything
/// written before D-075 #4 reads unchanged. Totals never add two currencies together.
@immutable
class SpCurrency {
  const SpCurrency(this.code, this.exponent, this.max, this.symbol);

  /// ISO 4217.
  final String code;

  /// Digits after the decimal mark (0 for VND, JPY, KRW).
  final int exponent;

  /// The largest amount in minor units an expense, cap or recurring item may hold.
  final int max;

  /// Short sign shown with amounts; the dollars are told apart (US$ is "$").
  final String symbol;

  /// 1 major unit in minor units (100 for USD, 1 for VND).
  int get unit => _pow10(exponent);
}

int _pow10(int e) {
  var v = 1;
  for (var i = 0; i < e; i++) {
    v *= 10;
  }
  return v;
}

/// What a document without `currency` is in.
const legacyCurrency = 'VND';

/// The currencies an expense can be kept in, in the picker's order.
const spCurrencies = <SpCurrency>[
  SpCurrency('VND', 0, 1000000000, '₫'),
  SpCurrency('USD', 2, 100000000, r'$'),
  SpCurrency('EUR', 2, 100000000, '€'),
  SpCurrency('GBP', 2, 100000000, '£'),
  SpCurrency('AUD', 2, 200000000, r'A$'),
  SpCurrency('CAD', 2, 200000000, r'C$'),
  SpCurrency('NZD', 2, 200000000, r'NZ$'),
  SpCurrency('SGD', 2, 200000000, r'S$'),
  SpCurrency('JPY', 0, 200000000, '¥'),
  SpCurrency('KRW', 0, 2000000000, '₩'),
  SpCurrency('TWD', 2, 5000000000, r'NT$'),
  SpCurrency('THB', 2, 5000000000, '฿'),
  SpCurrency('HKD', 2, 1000000000, r'HK$'),
  SpCurrency('CNY', 2, 1000000000, 'CN¥'),
  SpCurrency('CHF', 2, 100000000, 'CHF'),
  SpCurrency('MYR', 2, 500000000, 'RM'),
];

final _byCode = {for (final c in spCurrencies) c.code: c};

bool isSpCurrency(Object? code) => code is String && _byCode.containsKey(code);

/// A stored value's currency: absent or unknown (old data) → VND.
String currencyOf(Object? code) =>
    isSpCurrency(code) ? code! as String : legacyCurrency;

SpCurrency spCurrency(String code) => _byCode[code] ?? _byCode[legacyCurrency]!;

int amountMaxFor(String code) => spCurrency(code).max;

const _countryCurrency = {
  'VN': 'VND',
  'US': 'USD',
  'GB': 'GBP',
  'AU': 'AUD',
  'CA': 'CAD',
  'NZ': 'NZD',
  'SG': 'SGD',
  'JP': 'JPY',
  'KR': 'KRW',
  'TW': 'TWD',
  'TH': 'THB',
  'HK': 'HKD',
  'CN': 'CNY',
  'CH': 'CHF',
  'MY': 'MYR',
  'AT': 'EUR',
  'BE': 'EUR',
  'CY': 'EUR',
  'DE': 'EUR',
  'EE': 'EUR',
  'ES': 'EUR',
  'FI': 'EUR',
  'FR': 'EUR',
  'GR': 'EUR',
  'HR': 'EUR',
  'IE': 'EUR',
  'IT': 'EUR',
  'LT': 'EUR',
  'LU': 'EUR',
  'LV': 'EUR',
  'MT': 'EUR',
  'NL': 'EUR',
  'PT': 'EUR',
  'SI': 'EUR',
  'SK': 'EUR',
};

/// The household's default before anyone picks one: its country's currency, else VND.
String currencyForCountry(String? country) =>
    _countryCurrency[country?.toUpperCase()] ?? legacyCurrency;

/// Sums per currency, the [first] currency first, then the others by code. Never mixes them.
Map<String, int> sumByCurrency(
  Iterable<({String currency, int amount})> items, {
  String? first,
}) {
  final sums = <String, int>{};
  for (final i in items) {
    sums[i.currency] = (sums[i.currency] ?? 0) + i.amount;
  }
  final keys = sums.keys.toList()
    ..sort((a, b) {
      if (a == first) return -1;
      if (b == first) return 1;
      return a.compareTo(b);
    });
  return {for (final k in keys) k: sums[k]!};
}
