import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../care/care_models.dart';
import 'keepsake_card_view.dart';
import 'keepsake_catalog.dart';
import 'keepsake_occasions.dart';

/// What a card's text fields say (E-2, `docs/product/remember-2-templates.md` §1.4), worked out on
/// the phone from the baby's profile, the occasion, the photos and the parent's note. Child data
/// stays on the phone: it is drawn into the picture and never logged.

final _cardDate = DateFormat('dd.MM.yyyy');

/// "3 tháng", and the same split for big-number layouts ("3" + "tháng"). Age occasions say their
/// own age (7 ngày, 100 ngày, 3 tháng, 1 tuổi); others count from the date of birth: days under
/// two weeks, then weeks under two months, then months, then years.
({String age, String number, String unit}) keepsakeAge(
  AppLocalizations l10n,
  Occasion? occasion,
  DateTime? dob,
  DateTime date,
) {
  ({String age, String number, String unit}) days(int n) =>
      (age: l10n.ksAgeDays(n), number: '$n', unit: l10n.ksUnitDays(n));
  ({String age, String number, String unit}) weeks(int n) =>
      (age: l10n.ksAgeWeeks(n), number: '$n', unit: l10n.ksUnitWeeks(n));
  ({String age, String number, String unit}) months(int n) =>
      (age: l10n.ksAgeMonths(n), number: '$n', unit: l10n.ksUnitMonths(n));
  ({String age, String number, String unit}) years(int n) =>
      (age: l10n.ksAgeYears(n), number: '$n', unit: l10n.ksUnitYears(n));
  const none = (age: '', number: '', unit: '');

  if (occasion != null && occasion.byAge) {
    if (occasion.days != null) {
      return occasion.days! > 0 ? days(occasion.days!) : none;
    }
    final m = occasion.months!;
    return m % 12 == 0 ? years(m ~/ 12) : months(m);
  }
  if (dob == null) return none;
  final b = DateTime(dob.year, dob.month, dob.day);
  final d = DateTime(date.year, date.month, date.day).difference(b).inDays;
  if (d < 0) return none;
  if (d < 14) return days(d);
  if (d < 60) return weeks(d ~/ 7);
  final m =
      (date.year - b.year) * 12 +
      date.month -
      b.month -
      (date.day < b.day ? 1 : 0);
  return m < 12 ? months(m) : years(m ~/ 12);
}

/// "Ngày đầu", "Tuần 3", "Tháng 6" for a photo taken at [at]; "Lúc ấy" / "Bây giờ" when unknown.
String keepsakePhotoLabel(
  AppLocalizations l10n,
  DateTime? dob,
  DateTime? at,
  int slot,
) {
  final fallback = slot == 0 ? l10n.ksLabelThen : l10n.ksLabelNow;
  if (dob == null || at == null) return fallback;
  final b = DateTime(dob.year, dob.month, dob.day);
  final d = DateTime(at.year, at.month, at.day).difference(b).inDays;
  if (d < 0) return fallback;
  if (d == 0) return l10n.ksLabelFirstDay;
  if (d < 14) return l10n.ksLabelDay(d + 1);
  if (d < 60) return l10n.ksLabelWeek(d ~/ 7 + 1);
  final m =
      (at.year - b.year) * 12 + at.month - b.month - (at.day < b.day ? 1 : 0);
  return m < 12 ? l10n.ksLabelMonth(m) : l10n.ksLabelYear(m ~/ 12);
}

/// A video photo's age label ("Tháng 3"), the same wording the server uses; null before birth.
String? keepsakeVideoLabel(AppLocalizations l10n, DateTime dob, DateTime at) {
  final b = DateTime(dob.year, dob.month, dob.day);
  if (DateTime(at.year, at.month, at.day).isBefore(b)) return null;
  return keepsakePhotoLabel(l10n, dob, at, 0);
}

/// "3,2 kg · 50 cm" from the earliest growth record within a week of birth; empty without one.
String keepsakeBirthStats(
  AppLocalizations l10n,
  Locale locale,
  DateTime? dob,
  Iterable<CareRecord> growth,
) {
  if (dob == null) return '';
  final b = DateTime(dob.year, dob.month, dob.day);
  CareRecord? first;
  for (final r in growth) {
    if (r.weightKg == null && r.lengthCm == null) continue;
    final at = r.measuredOn ?? r.occurredAt;
    final gap = DateTime(at.year, at.month, at.day).difference(b).inDays;
    if (gap < 0 || gap > 7) continue;
    if (first == null || at.isBefore(first.measuredOn ?? first.occurredAt)) {
      first = r;
    }
  }
  if (first == null) return '';
  final n = NumberFormat.decimalPattern(locale.toLanguageTag())
    ..maximumFractionDigits = 1;
  final w = first.weightKg, l = first.lengthCm;
  if (w != null && l != null) {
    return l10n.ksBirthStats(n.format(w), n.format(l));
  }
  return w != null
      ? l10n.ksBirthWeight(n.format(w))
      : l10n.ksBirthLength(n.format(l!));
}

/// A template's own text with `{name}`, `{age}`, `{occasion}` and `{achievement}` filled.
String fillKeepsakeText(
  String text, {
  required String name,
  required String age,
  required String occasion,
  required String achievement,
}) => text
    .replaceAll('{name}', name)
    .replaceAll('{age}', age)
    .replaceAll('{occasion}', occasion)
    .replaceAll('{achievement}', achievement)
    .trim();

/// Everything a card template can show, for [occasion] on [date].
CardContent keepsakeCardContent({
  required AppLocalizations l10n,
  required Locale locale,
  required KeepsakeTemplate template,
  required Occasion occasion,
  required String name,
  required DateTime? dob,
  required DateTime date,
  required String note,
  required List<CardPhoto?> photos,
  Iterable<CareRecord> growth = const [],

  /// D-076 #14: a family milestone's own name in place of the occasion's (its age is then
  /// counted from the date of birth).
  String? occasionTitle,
}) {
  final age = keepsakeAge(
    l10n,
    occasionTitle == null ? occasion : null,
    dob,
    date,
  );
  final title = occasionTitle ?? occasion.title(l10n);
  String own(String key) => fillKeepsakeText(
    template.text(key)?.defaultText.of(locale) ?? '',
    name: name,
    age: age.age,
    occasion: title,
    achievement: occasionTitle == null
        ? occasion.achievement(l10n)
        : l10n.ksAchieveAny,
  );
  final slots = template.photoSlots(KeepsakeFormat.portrait);
  return CardContent(
    occasion: title,
    name: name,
    date: _cardDate.format(date),
    // The parent's note ("Lời nhắn"): quoted for `quote` layers, plain for `message` ones.
    quote: note,
    message: note,
    title: own('title'),
    headline: own('headline'),
    age: age.age,
    ageNumber: age.number,
    ageUnit: age.unit,
    birthStats: keepsakeBirthStats(l10n, locale, dob, growth),
    photos: photos,
    photoLabels: [
      for (var i = 0; i < (slots.isEmpty ? 1 : slots.last + 1); i++)
        keepsakePhotoLabel(
          l10n,
          dob,
          i < photos.length ? photos[i]?.takenAt : null,
          i,
        ),
    ],
  );
}
