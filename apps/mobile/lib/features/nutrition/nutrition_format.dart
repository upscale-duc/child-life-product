import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show decimal;
import '../care/who_growth.dart';
import 'nutrition_calc.dart';
import 'nutrition_models.dart';

/// Labels, looks and the doctor's summary of Dinh dưỡng (D-083). Every string comes from the ARB
/// files (D-012).

/// "6–8 tháng", "0–1 tháng", "24–36 tháng" (`nutritionAgeLabel`).
String nuAgeLabel(AppLocalizations l10n, NuAge a) {
  final l = a.label;
  return l10n.nuMonthsRange(l.from, l.to);
}

/// "600–900" (or "600" when both ends are the same).
String nuRangeText(String locale, NuRange r) {
  final f = NumberFormat.decimalPattern(locale);
  return r.min == r.max
      ? f.format(r.min)
      : '${f.format(r.min)}–${f.format(r.max)}';
}

/// "720" with the locale's grouping ("1.000" in Vietnamese).
String nuMl(String locale, int ml) =>
    NumberFormat.decimalPattern(locale).format(ml);

/// "05/10" / "05/10/2026".
String nuDayMonth(DateTime d) => DateFormat('dd/MM').format(d);
String nuDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

/// A round's days: "1–2/12" (vi), "Dec 1–2" (en); with the year: "1–2/12/2026", "Dec 1–2, 2026".
String nuRoundDays(
  String locale,
  DateTime from,
  DateTime to, {
  bool year = false,
}) {
  final same = from.day == to.day;
  if (locale.startsWith('vi')) {
    final days = same ? '${from.day}' : '${from.day}–${to.day}';
    return '$days/${from.month}${year ? '/${from.year}' : ''}';
  }
  final month = DateFormat.MMM(locale).format(from);
  final days = same ? '${from.day}' : '${from.day}–${to.day}';
  return '$month $days${year ? ', ${from.year}' : ''}';
}

/// "Đợt tháng 6" / "June round".
String nuRoundTitle(AppLocalizations l10n, String locale, DateTime from) =>
    l10n.nuRoundTitle(
      locale.startsWith('vi')
          ? '${from.month}'
          : DateFormat.MMMM(locale).format(from),
    );

String nuSlotLabel(AppLocalizations l10n, NuSlot s) => switch (s) {
  NuSlot.morning => l10n.nuSlotMorning,
  NuSlot.noon => l10n.nuSlotNoon,
  NuSlot.afternoon => l10n.nuSlotAfternoon,
  NuSlot.evening => l10n.nuSlotEvening,
  NuSlot.night => l10n.nuSlotNight,
};

ClIcons nuSampleIcon(NuSampleKind k) => switch (k) {
  NuSampleKind.milk => ClIcons.feed,
  NuSampleKind.solids => ClIcons.spark,
  NuSampleKind.snack => ClIcons.star,
  NuSampleKind.sleep => ClIcons.sleep,
};

/// "Trong khoảng chuẩn" · "Thấp hơn khoảng chuẩn" · "Cao hơn khoảng chuẩn" (P-163 #6).
String nuBandLabel(AppLocalizations l10n, GrowthBand b) => switch (b) {
  GrowthBand.normal => l10n.nuTagIn,
  GrowthBand.below => l10n.nuTagBelow,
  GrowthBand.above => l10n.nuTagAbove,
};

/// The chip of a nutrient row and the 9d head: tint, ink on it and icon, per `nutrientKeys`
/// (9b: iron pump-soft + drop, zinc diaper-soft + star, vitamin D bottle-soft + sunrise, vitamin A
/// breast-soft + heart). Care tints carry their own ink in Light and Night care; the warm
/// sunshine fill takes `colors.ink`.
typedef NuLook = ({Color soft, Color ink, ClIcons icon});

NuLook nuNutrientLook(BuildContext context, NuNutrientKey key) {
  final cl = context.cl;
  final care = cl.care;
  return switch (key) {
    NuNutrientKey.iron => (
      soft: care.pump.soft,
      ink: care.pump.ink,
      icon: ClIcons.drop,
    ),
    NuNutrientKey.zinc => (
      soft: care.diaper.soft,
      ink: care.diaper.ink,
      icon: ClIcons.star,
    ),
    NuNutrientKey.vitaminD => (
      soft: care.bottle.soft,
      ink: care.bottle.ink,
      icon: ClIcons.sunrise,
    ),
    NuNutrientKey.vitaminA => (
      soft: care.breast.soft,
      ink: care.breast.ink,
      icon: ClIcons.heart,
    ),
    NuNutrientKey.calcium => (
      soft: care.sleep.soft,
      ink: care.sleep.ink,
      icon: ClIcons.feed,
    ),
    NuNutrientKey.dha => (
      soft: cl.colors.mintSoft,
      ink: cl.colors.mintText,
      icon: ClIcons.eye,
    ),
    NuNutrientKey.iodine => (
      soft: cl.colors.sunshineSoft,
      ink: cl.colors.ink,
      icon: ClIcons.sunset,
    ),
    NuNutrientKey.fibre => (
      soft: care.growth.soft,
      ink: care.growth.ink,
      icon: ClIcons.spark,
    ),
    NuNutrientKey.other => (
      soft: cl.colors.surface2,
      ink: cl.colors.inkMuted,
      icon: ClIcons.spark,
    ),
  };
}

/// "Teddy trung bình 720 ml/ngày (7 ngày qua) · 4–5 cữ, 180–240 ml mỗi cữ. Bú mẹ: …" (9b).
String nuMilkLine(
  AppLocalizations l10n,
  String locale, {
  required String name,
  required int? average,
  required NuMilk? milk,
  required String breastNote,

  /// False on a stage opened from 9f: no personal average (P-163 #14).
  bool personal = true,
}) {
  final parts = <String>[
    if (personal)
      average == null
          ? l10n.nuMilkNotEnough
          : l10n.nuMilkAverage(name, nuMl(locale, average)),
    if (milk?.feedsPerDay != null && milk?.perFeedMl != null)
      l10n.nuMilkFeeds(
        nuRangeText(locale, milk!.feedsPerDay!),
        nuRangeText(locale, milk.perFeedMl!),
      )
    else if (milk?.feedsPerDay != null)
      l10n.nuMilkFeedsOnly(nuRangeText(locale, milk!.feedsPerDay!))
    else if (milk?.perFeedMl != null)
      l10n.nuMilkPerFeedOnly(nuRangeText(locale, milk!.perFeedMl!))
    // 12–36 months: milk is a drink, only a daily amount (print only what exists).
    else if (milk?.perDayMl != null)
      l10n.nuMilkPerDayOnly(nuRangeText(locale, milk!.perDayMl!)),
  ];
  final line = parts.join(' · ');
  final breast = breastNote.isEmpty ? '' : l10n.nuMilkBreast(breastNote);
  if (line.isEmpty) return breast;
  return breast.isEmpty ? '$line.' : '$line. $breast';
}

/// "Xuất báo cáo cho bác sĩ" (P-163 #7): a plain-text summary with the baby's age (no name), the
/// last 4 measurements with their WHO position, the 7-day bottle average and the rule's banner
/// (its `{name}` read as "bé"). Built on the device; nothing is sent anywhere by the app.
String nuDoctorReport(
  AppLocalizations l10n, {
  required String locale,
  required DateTime? dob,
  required DateTime today,
  required bool? boy,
  required List<NuMeasure> weights,
  required List<NuMeasure> lengths,
  required int? milkAverage,
  required String banner,
}) {
  final days = <DateTime>{
    for (final m in weights) m.on,
    for (final m in lengths) m.on,
  }.toList()..sort((a, b) => b.compareTo(a));
  String measure(NuMeasure? m, String Function(String) unit) {
    if (m == null) return '';
    final value = unit(decimal(locale, m.value));
    return m.band == null
        ? value
        : '$value (${nuBandLabel(l10n, m.band!).toLowerCase()})';
  }

  final lines = <String>[
    l10n.nuReportTitle,
    if (dob != null) l10n.nuReportAge(ageLong(l10n, dob, today)),
    if (boy != null) l10n.nuReportSex(boy ? l10n.nuBoy : l10n.nuGirl),
    '',
    l10n.nuReportMeasures,
    for (final day in days.take(4))
      [
        '• ${nuDate(day)}',
        measure(
          weights.where((m) => m.on == day).firstOrNull,
          (v) => l10n.weightKg(v),
        ),
        measure(
          lengths.where((m) => m.on == day).firstOrNull,
          (v) => l10n.lengthCm(v),
        ),
      ].where((s) => s.isNotEmpty).join(' · '),
    '',
    milkAverage == null
        ? l10n.nuReportMilkNone
        : l10n.nuReportMilk(nuMl(locale, milkAverage)),
    if (banner.isNotEmpty) ...['', l10n.nuReportNote(banner)],
    '',
    l10n.nuReportFooter(nuDate(today)),
  ];
  return lines.join('\n');
}
