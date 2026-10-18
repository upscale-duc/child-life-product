import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../premium/premium_repository.dart';
import 'vaccine_models.dart';
import 'vaccine_reference.dart';
import 'vaccine_repository.dart';

/// VX 1a "Xem lịch tiêm theo": kept on this device.
enum VaccineView { byVaccine, byAge }

final vaccineViewProvider = NotifierProvider<VaccineViewState, VaccineView>(
  VaccineViewState.new,
);

class VaccineViewState extends Notifier<VaccineView> {
  static const _key = 'vaccines.view';

  @override
  VaccineView build() {
    try {
      return VaccineView.values.asNameMap()[ref
              .read(sharedPreferencesProvider)
              .getString(_key)] ??
          VaccineView.byVaccine;
    } on Object {
      return VaccineView.byVaccine;
    }
  }

  void set(VaccineView v) {
    state = v;
    try {
      ref.read(sharedPreferencesProvider).setString(_key, v.name);
    } on Object {
      // No preferences (tests).
    }
  }
}

/// What the book screens need: the book, or why there is none yet.
sealed class VaccineBookState {
  const VaccineBookState();
}

class VaccineBookLoading extends VaccineBookState {
  const VaccineBookLoading();
}

/// No date of birth to count from (a caregiver before Cùng nuôi opened the book, P-133).
class VaccineBookNoDob extends VaccineBookState {
  const VaccineBookNoDob();
}

class VaccineBookReady extends VaccineBookState {
  const VaccineBookReady(this.book, this.dob);
  final VaccineBook book;
  final DateTime dob;
}

/// The book of the selected baby for today in the baby's zone (R-061).
final vaccineBookProvider = Provider.family<VaccineBookState, Membership>((
  ref,
  me,
) {
  final records = ref.watch(vaccineDosesProvider(me.babyId)).value;
  final plan = ref.watch(vaccinePlanProvider(me.babyId)).value;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  final profile = me.canViewBabyInfo
      ? ref.watch(babyPrivateProfileProvider(me.babyId))
      : null;
  if (records == null || plan == null) return const VaccineBookLoading();
  if (profile != null && !profile.hasValue) return const VaccineBookLoading();
  final dob = profile?.value?.dateOfBirth ?? plan.scheduleFrom;
  if (dob == null) return const VaccineBookNoDob();
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  final day = DateTime(dob.year, dob.month, dob.day);
  // D-084: a family abroad gets its country's schedule when the app has one.
  final local = countryScheduleOf(ref.watch(selectedFamilyCountryProvider));
  return VaccineBookReady(
    VaccineBook.of(
      dob: day,
      today: babyToday(zone, now),
      plan: plan,
      records: records,
      schedule: local?.defs ?? ref.watch(vaccineScheduleProvider).defs,
      country: local?.country,
    ),
    day,
  );
});

// ---------- Labels ----------

String vxLocale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "17/11".
String vxDay(DateTime d) => '${d.day}/${d.month}';

/// "17/11/2026".
String vxDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// "Thứ Ba, 17/11/2026" / "Tuesday, 17/11/2026".
String vxLongDate(String locale, DateTime d) {
  final w = DateFormat.EEEE(locale).format(d);
  return '${w[0].toUpperCase()}${w.substring(1)}, ${vxDate(d)}';
}

/// "Sơ sinh" / "2 tháng".
String vxAge(AppLocalizations l10n, int months) =>
    months == 0 ? l10n.vxBirth : l10n.vxMonths(months);

/// "Mốc sơ sinh" / "Mốc 2 tháng tuổi".
String vxMilestone(AppLocalizations l10n, int months) =>
    months == 0 ? l10n.vxMilestoneBirth : l10n.vxMilestone(months);

/// The series' name for this plan: "6in1 hoặc 5in1" until chosen, then "6in1" or "5in1".
String vxName(
  String locale,
  VaccineDef def,
  VaccinePlan plan, {
  bool short = false,
}) {
  if (def.dtpSeries) {
    return switch (plan.dtp) {
      DtpChoice.sixInOne => locale.startsWith('en') ? '6-in-1' : '6in1',
      DtpChoice.fiveInOne => locale.startsWith('en') ? '5-in-1' : '5in1',
      null => short ? def.short.of(locale) : def.name.of(locale),
    };
  }
  return (short ? def.short : def.name).of(locale);
}

/// "6in1 · mũi 1" / "6-in-1 · dose 1".
String vxDoseTitle(
  AppLocalizations l10n,
  String locale,
  DoseItem item,
  VaccinePlan plan,
) =>
    '${vxName(locale, item.def, plan, short: true)} · '
    '${l10n.vxDoseN(item.dose).toLowerCase()}';

/// "6in1 mũi 1" in toasts.
String vxDoseShort(
  AppLocalizations l10n,
  String locale,
  DoseItem item,
  VaccinePlan plan,
) => l10n.vxDoseOf(vxName(locale, item.def, plan, short: true), item.dose);

/// "6in1 · Rota · Phế cầu (mũi 1)", or "6in1 mũi 2 · Rota mũi 2" when the doses differ.
String vxGroupLine(
  AppLocalizations l10n,
  String locale,
  List<DoseItem> items,
  VaccinePlan plan,
) {
  final doses = items.map((i) => i.dose).toSet();
  if (doses.length == 1) {
    return '${items.map((i) => vxName(locale, i.def, plan, short: true)).join(' · ')} '
        '${l10n.vxDoseSuffix(doses.single)}';
  }
  return items.map((i) => vxDoseShort(l10n, locale, i, plan)).join(' · ');
}

/// "còn 40 ngày" / "hôm nay".
String vxLeft(AppLocalizations l10n, DateTime today, DateTime date) {
  final days = date.difference(today).inDays;
  return days <= 0 ? l10n.vxDueToday : l10n.vxDaysLeft(days);
}

/// Matrix row hint: "2 · 3 · 4 · 18 tháng", "Sơ sinh", "6 · 7 tháng · hằng năm".
String vxHint(AppLocalizations l10n, VaccineDef def) {
  if (def.months.every((m) => m == 0)) return l10n.vxBirth;
  final base = l10n.vxHintMonths(def.months.join(' · '));
  return def.yearly ? '$base · ${l10n.vxHintYearly}' : base;
}

String vxPlaceLabel(AppLocalizations l10n, VaccinePlace p) => switch (p) {
  VaccinePlace.hospital => l10n.vxPlaceHospital,
  VaccinePlace.service => l10n.vxPlaceService,
  VaccinePlace.station => l10n.vxPlaceStation,
};

/// [national]: a schedule outside Việt Nam (D-084), where "Tiêm chủng mở rộng" and "Dịch vụ" read
/// as the national programme and as recommended but often paid.
String vxProgrammeLabel(
  AppLocalizations l10n,
  VaccineDef def, {
  bool national = false,
}) => switch (def.programme) {
  VaccineProgramme.epi => national ? l10n.vxProgNational : l10n.vxProgEpi,
  VaccineProgramme.service =>
    national ? l10n.vxProgRecommended : l10n.vxProgService,
  VaccineProgramme.hospital => l10n.vxProgHospital,
  VaccineProgramme.choice => l10n.vxProgChoice,
};

String vxRouteLabel(AppLocalizations l10n, VaccineDef def) =>
    def.route == VaccineRoute.oral ? l10n.vxRouteOral : l10n.vxRouteInjection;
