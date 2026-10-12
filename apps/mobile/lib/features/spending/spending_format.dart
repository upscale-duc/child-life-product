import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import 'spending_models.dart';

/// Money copy (P-140): whole VND, "1.020.000 ₫" (vi) / "1,020,000 ₫" (en); short "4,2 tr" /
/// "4.2M" from a million up.

String spLocale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "1.020.000" (no symbol: suggestion chips, budget fractions).
String moneyPlain(String locale, int amount) =>
    NumberFormat('#,##0', locale).format(amount);

/// "1.020.000 ₫".
String money(String locale, int amount) => '${moneyPlain(locale, amount)} ₫';

/// "4,2 tr" / "4.2M"; under a million the full form.
String moneyShort(AppLocalizations l10n, String locale, int amount) {
  if (amount.abs() < 1000000) return money(locale, amount);
  return l10n.spMillions(
    NumberFormat('#,##0.#', locale).format((amount / 100000).round() / 10),
  );
}

/// Axis ticks: "0 tr", "5 tr" / "0", "5M".
String moneyAxis(AppLocalizations l10n, String locale, double millions) =>
    l10n.spMillions(NumberFormat('#,##0.#', locale).format(millions));

/// Digits typed in the amount field → VND (separators ignored).
int? parseMoney(String text) {
  final digits = text.replaceAll(RegExp('[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits.length > 10 ? digits.substring(0, 10) : digits);
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
      ink: c.onWarm,
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
