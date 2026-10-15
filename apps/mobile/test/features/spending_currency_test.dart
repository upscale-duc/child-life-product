import 'package:child_life/features/spending/spending_calc.dart';
import 'package:child_life/features/spending/spending_currency.dart';
import 'package:child_life/features/spending/spending_format.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/spending_fixtures.dart';

/// Chi tiêu currencies (D-075 #4): minor units, formatting by locale, totals never mixed.
void main() {
  final vi = AppLocalizationsVi();
  final en = AppLocalizationsEn();

  group('currencies', () {
    test('ISO exponents and ceilings mirror contracts; old data is VND', () {
      expect(spCurrency('VND').exponent, 0);
      expect(spCurrency('USD').exponent, 2);
      expect(spCurrency('JPY').exponent, 0);
      expect(amountMaxFor('VND'), SpendingLimits.amountMax);
      expect(amountMaxFor('USD'), 100000000);
      expect(currencyOf(null), 'VND');
      expect(currencyOf('XAF'), 'VND');
      expect(currencyOf('EUR'), 'EUR');
      expect(isSpCurrency('THB'), isTrue);
      expect(currencyForCountry('VN'), 'VND');
      expect(currencyForCountry('us'), 'USD');
      expect(currencyForCountry('FR'), 'EUR');
      expect(currencyForCountry(null), 'VND');
      expect(spCurrencies.map((c) => c.code).toSet().length, 16);
    });

    test('VND formats exactly as before', () {
      expect(money('vi', 1020000), '1.020.000 ₫');
      expect(money('en', 1020000), '1,020,000 ₫');
      expect(money('vi', 1020000, 'VND'), '1.020.000 ₫');
      expect(moneyShort(vi, 'vi', 4215000), '4,2 tr');
      expect(moneyShort(en, 'en', 4215000), '4.2M');
      expect(moneyPlain('vi', 1020000), '1.020.000');
    });

    test('other currencies: their decimals and symbol, by locale', () {
      expect(money('en', 1250, 'USD'), r'$12.50');
      // intl puts a no-break space before the symbol in Vietnamese.
      expect(money('vi', 1250, 'USD'), '12,50\u00A0\$');
      expect(money('en', 1500, 'JPY'), '¥1,500');
      expect(money('vi', 1500, 'JPY'), '1.500\u00A0¥');
      expect(money('en', 99, 'EUR'), '€0.99');
      expect(money('en', 123456, 'SGD'), r'S$1,234.56');
      expect(moneyPlain('vi', 1250, 'USD'), '12,50');
      expect(moneyPlain('en', 1250, 'USD'), '12.50');
      expect(moneyShort(en, 'en', 125000, 'USD'), r'$1,250.00');
      expect(moneyShort(en, 'en', 4200000, 'USD'), r'$42K');
      expect(moneyTick(en, 'en', 5000000, 'VND'), '5M');
      expect(moneyTick(en, 'en', 500000, 'USD'), '5K');
    });

    test('typed amounts → minor units', () {
      expect(parseMoney('1.020.000'), 1020000);
      expect(parseMoney('12,50', 'USD', 'vi'), 1250);
      expect(parseMoney('12.5', 'USD', 'en'), 1250);
      expect(parseMoney('1,234.56', 'USD', 'en'), 123456);
      expect(parseMoney('1.234,56', 'EUR', 'vi'), 123456);
      expect(parseMoney('12', 'USD', 'en'), 1200);
      expect(parseMoney('12.', 'USD', 'en'), 1200);
      expect(parseMoney('1,500', 'JPY', 'en'), 1500);
      expect(parseMoney('', 'USD', 'en'), isNull);
      // Without a locale: the last mark followed by up to two digits.
      expect(parseMoney('12.50', 'USD'), 1250);
      expect(parseMoney('1,234', 'USD'), 123400);
    });

    test('lists keep currencies apart', () {
      expect(
        moneyList('en', {'VND': 1020000, 'USD': 1250}),
        r'1,020,000 ₫ · $12.50',
      );
      expect(currencyName(vi, 'USD'), 'Đô la Mỹ');
      expect(currencyName(en, 'JPY'), 'Japanese yen');
      expect(minorPlain(1205, 'USD'), '12.05');
      expect(minorPlain(1020000, 'VND'), '1020000');
    });
  });

  group('figures never add two currencies', () {
    final today = DateTime(2026, 10, 12);
    final all = [
      spend('50', 1250, 'c_milk', DateTime(2026, 10, 10), currency: 'USD'),
      spend('51', 300, 'c_milk', DateTime(2026, 10, 3), currency: 'USD'),
      spend('52', 2000, 'c_other', DateTime(2026, 10, 3), currency: 'JPY'),
      ...mockSpending(),
    ];

    test('the month in the household currency, the others apart', () {
      final s = MonthSummary.of(all, monthOf(today), today, currency: 'VND');
      expect(s.total, 4215000);
      expect(s.items.length, 7);
      expect(s.allItems.length, 10);
      expect(s.others, {'JPY': 2000, 'USD': 1550});
      expect(s.averagePerDay, 351000);
      final usd = MonthSummary.of(all, monthOf(today), today, currency: 'USD');
      expect(usd.total, 1550);
      expect(usd.byCategory, {'c_milk': 1550});
      // To the cent, not to the thousand.
      expect(usd.averagePerDay, 129);
      expect(usd.others, {'JPY': 2000, 'VND': 4215000});
    });

    test('six months, since birth and day headers', () {
      final six = SixMonths.of(all, today, currency: 'VND');
      expect(six.total, SixMonths.of(mockSpending(), today).total);
      expect(SixMonths.of(all, today, currency: 'USD').total, 1550);
      expect(
        SinceBirth.of(all, today, DateTime(2026, 3, 1), currency: 'JPY').total,
        2000,
      );
      expect(
        totalsByCurrency(all.where((e) => e.spentOn.day == 3), first: 'VND'),
        {'JPY': 2000, 'USD': 300},
      );
      expect(otherTotals(all, 'USD').keys, ['JPY', 'VND']);
    });

    test('the budget keeps its currency; old budgets are VND', () {
      expect(Budget.empty.currencyOr('USD'), 'USD');
      final old = Budget.fromJson({
        'monthlyTotal': 8000000,
        'caps': <String, Object?>{},
        'alert80': true,
      });
      expect(old.stored, isTrue);
      expect(old.currencyOr('USD'), 'VND');
      final usd = Budget.fromJson({
        'monthlyTotal': 150000,
        'caps': {'c_milk': 40000},
        'alert80': false,
        'currency': 'USD',
      });
      expect(usd.currency, 'USD');
      expect(usd.toJson()['currency'], 'USD');
      expect(
        const Budget(monthlyTotal: 1).toJson().containsKey('currency'),
        isFalse,
      );
      expect(SpendingSettings.fromJson(null).currency, isNull);
      expect(SpendingSettings.fromJson({'currency': 'XAF'}).currency, isNull);
      expect(SpendingSettings.fromJson({'currency': 'EUR'}).currency, 'EUR');
    });
  });
}
