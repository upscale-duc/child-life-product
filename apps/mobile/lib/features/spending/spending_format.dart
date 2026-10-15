import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import 'spending_calc.dart' show MonthSummary;
import 'spending_currency.dart';
import 'spending_models.dart';

/// Money copy (P-140): VND as before, "1.020.000 ₫" (vi) / "1,020,000 ₫" (en); short "4,2 tr" /
/// "4.2M" from a million up. Other currencies (D-075 #4) with intl, in their own decimals and a
/// symbol that tells the dollars apart: "12,50 $" / "$12.50", "1.500 ¥" / "¥1,500".

String spLocale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "1.020.000" / "12,50" (no symbol: the amount field, suggestion chips, budget fractions).
String moneyPlain(
  String locale,
  int amount, [
  String currency = legacyCurrency,
]) {
  final c = spCurrency(currency);
  if (c.exponent == 0) return NumberFormat('#,##0', locale).format(amount);
  return NumberFormat(
    '#,##0.${'0' * c.exponent}',
    locale,
  ).format(amount / c.unit);
}

/// "1.020.000 ₫"; "12,50 $" (vi) / "$12.50" (en).
String money(String locale, int amount, [String currency = legacyCurrency]) {
  final c = spCurrency(currency);
  if (c.code == legacyCurrency) return '${moneyPlain(locale, amount)} ₫';
  return NumberFormat.currency(
    locale: locale,
    name: c.code,
    symbol: c.symbol,
    decimalDigits: c.exponent,
  ).format(amount / c.unit);
}

/// "4,2 tr" / "4.2M"; under a million the full form. Another currency: compact from 10 000.
String moneyShort(
  AppLocalizations l10n,
  String locale,
  int amount, [
  String currency = legacyCurrency,
]) {
  final c = spCurrency(currency);
  if (c.code != legacyCurrency) {
    final major = amount / c.unit;
    if (major.abs() < 10000) return money(locale, amount, currency);
    return NumberFormat.compactCurrency(
      locale: locale,
      name: c.code,
      symbol: c.symbol,
    ).format(major);
  }
  if (amount.abs() < 1000000) return money(locale, amount);
  return l10n.spMillions(
    NumberFormat('#,##0.#', locale).format((amount / 100000).round() / 10),
  );
}

/// Axis ticks: "0 tr", "5 tr" / "0", "5M".
String moneyAxis(AppLocalizations l10n, String locale, double millions) =>
    l10n.spMillions(NumberFormat('#,##0.#', locale).format(millions));

/// A chart tick for [value] minor units: VND in millions (as before), others compact.
String moneyTick(
  AppLocalizations l10n,
  String locale,
  double value,
  String currency,
) {
  final c = spCurrency(currency);
  if (c.code == legacyCurrency) return moneyAxis(l10n, locale, value / 1000000);
  return NumberFormat.compact(locale: locale).format(value / c.unit);
}

/// "12,50 $ · 3.000 ¥": totals kept apart by currency (D-075 #4), [first] first.
String moneyList(String locale, Map<String, int> sums) =>
    [for (final e in sums.entries) money(locale, e.value, e.key)].join(' · ');

/// The amount field's text split at its decimal mark: the locale's grouping separators are
/// dropped first, then the first `.` or `,` left is the mark (the decimal keypad types the
/// locale's own). Without a locale, the last mark followed by at most [exponent] digits.
({String whole, String? frac}) splitMoney(
  String text,
  int exponent, [
  String? locale,
]) {
  var t = text.replaceAll(RegExp('[^0-9.,]'), '');
  if (locale != null) {
    t = t.replaceAll(NumberFormat.decimalPattern(locale).symbols.GROUP_SEP, '');
    final i = t.indexOf(RegExp('[.,]'));
    if (i < 0) return (whole: t, frac: null);
    return (
      whole: t.substring(0, i),
      frac: t.substring(i + 1).replaceAll(RegExp('[.,]'), ''),
    );
  }
  final m = RegExp('^(.*?)[.,]([0-9]{0,$exponent})\$').firstMatch(t);
  if (m == null) return (whole: t.replaceAll(RegExp('[.,]'), ''), frac: null);
  return (whole: m.group(1)!.replaceAll(RegExp('[.,]'), ''), frac: m.group(2));
}

/// "1.020.000 ₫ · 12,50 $": a month in [currency], then its other currencies apart (tiles).
String monthMoney(String locale, MonthSummary s, String currency) => moneyList(
  locale,
  {if (s.total != 0 || s.others.isEmpty) currency: s.total, ...s.others},
);

/// What was typed in the amount field → minor units of [currency]. VND (and JPY, KRW): digits
/// only, separators ignored. A currency with cents: "12,5" (vi) / "12.50" (en) → 1250.
int? parseMoney(
  String text, [
  String currency = legacyCurrency,
  String? locale,
]) {
  final c = spCurrency(currency);
  if (c.exponent == 0) {
    final digits = text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits.length > 10 ? digits.substring(0, 10) : digits);
  }
  final split = splitMoney(text, c.exponent, locale);
  final frac = split.frac ?? '';
  if (split.whole.isEmpty && frac.isEmpty) return null;
  final w = split.whole.length > 10
      ? split.whole.substring(0, 10)
      : split.whole;
  final cents = frac.length > c.exponent
      ? frac.substring(0, c.exponent)
      : frac.padRight(c.exponent, '0');
  return (int.tryParse(w) ?? 0) * c.unit + int.parse(cents);
}

/// "53%".
String percent(double share) => '${(share * 100).round()}%';

/// A category's name: its own, or the built-in's translation.
String categoryName(AppLocalizations l10n, SpendingCategory c) =>
    c.name ??
    switch (c.kind) {
      BuiltInCategory.childcare => l10n.spCatChildcare,
      BuiltInCategory.milk => l10n.spCatMilk,
      BuiltInCategory.diaper => l10n.spCatDiaper,
      BuiltInCategory.health => l10n.spCatHealth,
      BuiltInCategory.clothes => l10n.spCatClothes,
      BuiltInCategory.other || null => l10n.spCatOther,
    };

/// soft = chip background · ink = icon / text on soft · accent = bars and charts.
({Color soft, Color ink, Color accent}) tintColors(
  BuildContext context,
  CategoryTint tint,
) {
  final cl = context.cl;
  final care = cl.care;
  final c = cl.colors;
  return switch (tint) {
    CategoryTint.growth => (
      soft: care.growth.soft,
      ink: care.growth.ink,
      accent: care.growth.accent,
    ),
    CategoryTint.bottle => (
      soft: care.bottle.soft,
      ink: care.bottle.ink,
      accent: care.bottle.accent,
    ),
    CategoryTint.diaper => (
      soft: care.diaper.soft,
      ink: care.diaper.ink,
      accent: care.diaper.accent,
    ),
    CategoryTint.pump => (
      soft: care.pump.soft,
      ink: care.pump.ink,
      accent: care.pump.accent,
    ),
    CategoryTint.breast => (
      soft: care.breast.soft,
      ink: care.breast.ink,
      accent: care.breast.accent,
    ),
    CategoryTint.sleep => (
      soft: care.sleep.soft,
      ink: care.sleep.ink,
      accent: care.sleep.accent,
    ),
    CategoryTint.sunshine => (
      soft: c.sunshineSoft,
      ink: c.ink,
      accent: c.sunshine,
    ),
    CategoryTint.mint => (soft: c.mintSoft, ink: c.mintText, accent: c.mint),
  };
}

/// "Hôm nay · 12/10", "Hôm qua · 11/10", then "09/10" (8f day headers).
String spDayHeader(AppLocalizations l10n, DateTime day, DateTime today) {
  final dm = DateFormat('dd/MM').format(day);
  final diff = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (diff == 0) return l10n.spDayToday(dm);
  if (diff == 1) return l10n.spDayYesterday(dm);
  return day.year == today.year ? dm : DateFormat('dd/MM/yyyy').format(day);
}

/// "Hôm nay", "Hôm qua", "09/10" (8b row sublines).
String spDayShort(AppLocalizations l10n, DateTime day, DateTime today) {
  final diff = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (diff == 0) return l10n.spToday;
  if (diff == 1) return l10n.spYesterday;
  return DateFormat(
    day.year == today.year ? 'dd/MM' : 'dd/MM/yyyy',
  ).format(day);
}

/// "Mẹ", "Bà ngoại", "Cô Lan": the payer's label like an author's; null → "Khác".
String payerLabel(AppLocalizations l10n, Payer? payer) => payer == null
    ? l10n.spPayerOther
    : authorLabel(
        l10n,
        payer.author,
        isMe: false,
        relationLabel: (r, c) => relationLabel(l10n, r, c),
      );

/// The subline of an expense row: "Mẹ trả · từ Tiêm chủng", "Bố trả · định kỳ".
String expenseSubline(AppLocalizations l10n, Expense e, {String? lead}) {
  final source = switch (e.source) {
    ExpenseSource.vaccine => l10n.spFromVaccines,
    ExpenseSource.recurring => l10n.spFromRecurring,
    ExpenseSource.import => l10n.spFromImport,
    ExpenseSource.assistant => l10n.spFromAssistant,
    ExpenseSource.manual => null,
  };
  return [
    ?lead,
    if (e.payer != null) l10n.spPaidBy(payerLabel(l10n, e.payer)),
    ?source,
  ].join(' · ');
}

/// 8i: "Ngày 1 và 16 hằng tháng", "Mỗi 2 tuần", "Ngày 5/3 hằng năm".
String scheduleLabel(AppLocalizations l10n, RecurringSchedule s) => switch (s) {
  Monthly(:final days) when days.length > 1 => l10n.spScheduleMonthlyTwo(
    days[0],
    days[1],
  ),
  Monthly(:final days) => l10n.spScheduleMonthly(days.isEmpty ? 1 : days.first),
  EveryWeeks(:final every) => l10n.spScheduleWeeks(every),
  Yearly(:final month, :final day) => l10n.spScheduleYearly('$day/$month'),
};

/// Spacing used by every spending screen.
const spGap = ClSpace.s4;

/// "Đồng Việt Nam", "Đô la Mỹ" (D-075 #4 picker).
String currencyName(AppLocalizations l10n, String code) => switch (code) {
  'VND' => l10n.spCurVND,
  'USD' => l10n.spCurUSD,
  'EUR' => l10n.spCurEUR,
  'GBP' => l10n.spCurGBP,
  'AUD' => l10n.spCurAUD,
  'CAD' => l10n.spCurCAD,
  'NZD' => l10n.spCurNZD,
  'SGD' => l10n.spCurSGD,
  'JPY' => l10n.spCurJPY,
  'KRW' => l10n.spCurKRW,
  'TWD' => l10n.spCurTWD,
  'THB' => l10n.spCurTHB,
  'HKD' => l10n.spCurHKD,
  'CNY' => l10n.spCurCNY,
  'CHF' => l10n.spCurCHF,
  'MYR' => l10n.spCurMYR,
  _ => code,
};
