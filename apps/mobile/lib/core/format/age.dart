import '../../l10n/app_localizations.dart';

/// Age of a baby on [today] (both local calendar dates). Units step up as the baby grows:
/// days under 2 weeks, weeks under 13 weeks, months under 2 years, then years.
/// Figma shows "Teddy được 3 tuần tuổi" (38:1498) and "Teddy · 3 tuần" (29:904).
enum AgeUnit { newborn, days, weeks, months, years }

({AgeUnit unit, int count}) babyAge(DateTime dateOfBirth, DateTime today) {
  final dob = DateTime.utc(
    dateOfBirth.year,
    dateOfBirth.month,
    dateOfBirth.day,
  );
  final day = DateTime.utc(today.year, today.month, today.day);
  final days = day.difference(dob).inDays;
  if (days <= 0) return (unit: AgeUnit.newborn, count: 0);
  if (days < 14) return (unit: AgeUnit.days, count: days);
  if (days < 91) return (unit: AgeUnit.weeks, count: days ~/ 7);
  var months = (day.year - dob.year) * 12 + day.month - dob.month;
  final lastDay = DateTime.utc(day.year, day.month + 1, 0).day;
  if (day.day < (dob.day < lastDay ? dob.day : lastDay)) months -= 1;
  if (months < 24) {
    return (unit: AgeUnit.months, count: months < 3 ? 3 : months);
  }
  return (unit: AgeUnit.years, count: months ~/ 12);
}

/// "3 tuần tuổi" / "3 weeks old".
String ageLong(AppLocalizations l10n, DateTime dateOfBirth, DateTime today) {
  final age = babyAge(dateOfBirth, today);
  return switch (age.unit) {
    AgeUnit.newborn => l10n.ageNewborn,
    AgeUnit.days => l10n.ageDays(age.count),
    AgeUnit.weeks => l10n.ageWeeks(age.count),
    AgeUnit.months => l10n.ageMonths(age.count),
    AgeUnit.years => l10n.ageYears(age.count),
  };
}

/// "3 tuần" / "3 weeks" for the baby switcher.
String ageShort(AppLocalizations l10n, DateTime dateOfBirth, DateTime today) {
  final age = babyAge(dateOfBirth, today);
  return switch (age.unit) {
    AgeUnit.newborn => l10n.ageShortNewborn,
    AgeUnit.days => l10n.ageShortDays(age.count),
    AgeUnit.weeks => l10n.ageShortWeeks(age.count),
    AgeUnit.months => l10n.ageShortMonths(age.count),
    AgeUnit.years => l10n.ageShortYears(age.count),
  };
}
