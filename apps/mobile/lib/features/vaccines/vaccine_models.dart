import 'package:cloud_firestore/cloud_firestore.dart';

import '../care/care_models.dart';
import 'vaccine_schedule.g.dart';

/// Sổ tiêm chủng (Figma VX 0 – VX 9a, P-133). Mirrors `packages/contracts/src/vaccines.ts`; the
/// schedule itself is generated into `vaccine_schedule.g.dart`.

typedef VxText = ({String vi, String en});

extension VxTextOf on VxText {
  String of(String locale) => locale.startsWith('en') ? en : vi;
}

/// Tiêm chủng mở rộng (free), Dịch vụ (paid), at the maternity hospital, or the 6in1 / 5in1 choice.
enum VaccineProgramme { epi, service, hospital, choice }

enum VaccineRoute { injection, oral }

class VaccineDef {
  const VaccineDef({
    required this.id,
    required this.name,
    required this.short,
    required this.months,
    required this.programme,
    required this.route,
    required this.about,
    this.minIntervalWeeks,
    this.yearly = false,
    this.only5in1 = false,
    this.dtpSeries = false,
  });

  final String id;
  final VxText name;
  final VxText short;
  final List<int> months;
  final VaccineProgramme programme;
  final VaccineRoute route;
  final VxText about;
  final int? minIntervalWeeks;
  final bool yearly;
  final bool only5in1;
  final bool dtpSeries;

  int get doses => months.length;
}

/// A routine schedule outside Việt Nam (D-084): the country's own, named on the book.
class CountryVaccineSchedule {
  const CountryVaccineSchedule({
    required this.country,
    required this.programmeName,
    required this.checkedOn,
    required this.sources,
    required this.defs,
  });

  final String country;
  final VxText programmeName;

  /// YYYY-MM-DD: when the official pages were read.
  final String checkedOn;
  final List<({String label, String url})> sources;
  final List<VaccineDef> defs;
}

/// The schedule of a family in [country] when the app has it; null = Việt Nam's.
CountryVaccineSchedule? countryScheduleOf(String? country) =>
    country == null || country == 'VN'
    ? null
    : countryVaccineSchedules[country];

VaccineDef? vaccineById(
  String id, [
  List<VaccineDef> schedule = vaccineSchedule,
]) => schedule.where((v) => v.id == id).firstOrNull;

/// VX 2 "Chọn một trong hai".
enum DtpChoice { sixInOne, fiveInOne }

extension DtpChoiceWire on DtpChoice {
  String get wire => this == DtpChoice.sixInOne ? '6in1' : '5in1';
}

DtpChoice? dtpChoiceOf(Object? wire) => switch (wire) {
  '6in1' => DtpChoice.sixInOne,
  '5in1' => DtpChoice.fiveInOne,
  _ => null,
};

/// VX 3 / VX 5 "Nơi tiêm".
enum VaccinePlace { hospital, service, station }

/// `babies/{babyId}/vaccines/{doseKey}`.
enum DoseRecordStatus { given, declined, planned }

String doseKeyOf(String vaccineId, int dose) => '${vaccineId}_$dose';

/// "YYYY-MM-DD" ↔ a calendar date (no time, no zone).
DateTime? parseDay(Object? v) {
  if (v is! String) return null;
  final p = v.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

String dayWire(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class VaccineDoseRecord {
  const VaccineDoseRecord({
    required this.key,
    required this.vaccineId,
    required this.dose,
    required this.status,
    required this.createdBy,
    required this.author,
    this.givenOn,
    this.givenTime,
    this.place,
    this.facility,
    this.reaction,
    this.declineReason,
    this.plannedOn,
    this.photoPath,
    this.pending = false,
  });

  final String key;
  final String vaccineId;
  final int dose;
  final DoseRecordStatus status;
  final DateTime? givenOn;

  /// "09:30".
  final String? givenTime;
  final VaccinePlace? place;
  final String? facility;
  final String? reaction;
  final String? declineReason;

  /// "Dời lịch": the new planned date.
  final DateTime? plannedOn;
  final String? photoPath;
  final String createdBy;
  final CareAuthor author;

  /// Written on this device, not yet on the server.
  final bool pending;

  static VaccineDoseRecord? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final j = d.data();
    if (j == null) return null;
    final status = DoseRecordStatus.values.asNameMap()[j['status']];
    final dose = (j['dose'] as num?)?.toInt();
    final vaccineId = j['vaccineId'] as String?;
    if (status == null || dose == null || vaccineId == null) return null;
    return VaccineDoseRecord(
      key: d.id,
      vaccineId: vaccineId,
      dose: dose,
      status: status,
      givenOn: parseDay(j['givenOn']),
      givenTime: j['givenTime'] as String?,
      place: VaccinePlace.values.asNameMap()[j['place']],
      facility: j['facility'] as String?,
      reaction: j['reaction'] as String?,
      declineReason: j['declineReason'] as String?,
      plannedOn: parseDay(j['plannedOn']),
      photoPath: j['photoPath'] as String?,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      pending: d.metadata.hasPendingWrites,
    );
  }
}

/// `babies/{babyId}/vaccinePlan/main`.
class VaccinePlan {
  const VaccinePlan({
    this.dtp,
    this.setupDone = false,
    this.scheduleFrom,
    this.remind = true,
    this.recipients = const [],
    this.bookPhotos = const [],
    this.exists = false,
  });

  final DtpChoice? dtp;
  final bool setupDone;

  /// The date of birth, kept by Cùng nuôi for caregivers (P-133).
  final DateTime? scheduleFrom;
  final bool remind;
  final List<String> recipients;
  final List<String> bookPhotos;

  /// False until Cùng nuôi first save it (setup, choice, reminders).
  final bool exists;

  factory VaccinePlan.fromJson(Map<String, dynamic>? j) => j == null
      ? const VaccinePlan()
      : VaccinePlan(
          dtp: dtpChoiceOf(j['dtp']),
          setupDone: j['setupDone'] == true,
          scheduleFrom: parseDay(j['scheduleFrom']),
          remind: j['remind'] != false,
          recipients: [for (final r in (j['recipients'] as List? ?? [])) '$r'],
          bookPhotos: [for (final p in (j['bookPhotos'] as List? ?? [])) '$p'],
          exists: true,
        );

  VaccinePlan copyWith({
    DtpChoice? dtp,
    bool? setupDone,
    DateTime? scheduleFrom,
    bool? remind,
    List<String>? recipients,
    List<String>? bookPhotos,
  }) => VaccinePlan(
    dtp: dtp ?? this.dtp,
    setupDone: setupDone ?? this.setupDone,
    scheduleFrom: scheduleFrom ?? this.scheduleFrom,
    remind: remind ?? this.remind,
    recipients: recipients ?? this.recipients,
    bookPhotos: bookPhotos ?? this.bookPhotos,
    exists: true,
  );
}

/// The four dots of VX 1 plus the declined one of VX 9a.
enum DoseStatus { given, declined, overdue, upcoming, later }

/// DOB + [months] calendar months; a day the month lacks falls back to its last day.
DateTime plannedDate(DateTime dob, int months) {
  final total = dob.month - 1 + months;
  final year = dob.year + total ~/ 12;
  final month = total % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, dob.day > last ? last : dob.day);
}

class DoseItem {
  const DoseItem({
    required this.def,
    required this.dose,
    required this.months,
    required this.planned,
    required this.status,
    this.record,
  });

  final VaccineDef def;

  /// 1-based.
  final int dose;

  /// Month of age of the milestone (0 = at birth).
  final int months;

  /// When it is planned: the milestone, or the "Dời lịch" date.
  final DateTime planned;
  final DoseStatus status;
  final VaccineDoseRecord? record;

  String get key => doseKeyOf(def.id, dose);
  bool get isLast => dose == def.doses;
  bool get done => status == DoseStatus.given || status == DoseStatus.declined;
}

/// One age block of "Theo tháng tuổi" (VX 1b) and a milestone page (VX 2).
class DoseGroup {
  const DoseGroup({
    required this.months,
    required this.date,
    required this.items,
  });
  final int months;
  final DateTime date;
  final List<DoseItem> items;
}

/// The book for a baby on [today]: every dose of the plan's schedule with its status.
class VaccineBook {
  VaccineBook._(this.items, this.today, this.plan, this.schedule, this.country);

  factory VaccineBook.of({
    required DateTime dob,
    required DateTime today,
    required VaccinePlan plan,
    required Map<String, VaccineDoseRecord> records,
    List<VaccineDef> schedule = vaccineSchedule,
    String? country,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final raw =
        <
          ({
            VaccineDef def,
            int dose,
            int months,
            DateTime planned,
            VaccineDoseRecord? record,
          })
        >[];
    for (final def in schedule) {
      if (def.only5in1 && plan.dtp != DtpChoice.fiveInOne) continue;
      for (var i = 0; i < def.months.length; i++) {
        final record = records[doseKeyOf(def.id, i + 1)];
        final planned = record?.status == DoseRecordStatus.planned
            ? (record!.plannedOn ?? plannedDate(dob, def.months[i]))
            : plannedDate(dob, def.months[i]);
        raw.add((
          def: def,
          dose: i + 1,
          months: def.months[i],
          planned: planned,
          record: record,
        ));
      }
    }
    // "Sắp tới": the doses of the next date to come that is still open (VX 1).
    DateTime? next;
    for (final r in raw) {
      final s = r.record?.status;
      if (s == DoseRecordStatus.given || s == DoseRecordStatus.declined) {
        continue;
      }
      if (r.planned.isBefore(day)) continue;
      if (next == null || r.planned.isBefore(next)) next = r.planned;
    }
    final items = [
      for (final r in raw)
        DoseItem(
          def: r.def,
          dose: r.dose,
          months: r.months,
          planned: r.planned,
          record: r.record,
          status: switch (r.record?.status) {
            DoseRecordStatus.given => DoseStatus.given,
            DoseRecordStatus.declined => DoseStatus.declined,
            _ when r.planned.isBefore(day) => DoseStatus.overdue,
            _ when r.planned == next => DoseStatus.upcoming,
            _ => DoseStatus.later,
          },
        ),
    ];
    return VaccineBook._(items, day, plan, schedule, country);
  }

  final List<DoseItem> items;
  final DateTime today;
  final VaccinePlan plan;

  /// The schedule the book was built from (published reference data or the bundled one).
  final List<VaccineDef> schedule;

  /// The country whose own schedule this is (D-084); null = Việt Nam's.
  final String? country;

  /// "Đã tiêm N / 30 mũi": declined doses leave the total.
  int get given => items.where((i) => i.status == DoseStatus.given).length;
  int get total => items.where((i) => i.status != DoseStatus.declined).length;

  List<DoseItem> get overdue =>
      items.where((i) => i.status == DoseStatus.overdue).toList();

  List<DoseItem> rowOf(String vaccineId) =>
      items.where((i) => i.def.id == vaccineId).toList();

  /// The vaccines shown, in schedule order.
  List<VaccineDef> get vaccines => [
    for (final def in schedule)
      if (!def.only5in1 || plan.dtp == DtpChoice.fiveInOne) def,
  ];

  /// The "Next" card: the earliest overdue date if any, else the next date to come.
  DoseGroup? get nextGroup {
    final open = items.where(
      (i) => i.status == DoseStatus.overdue || i.status == DoseStatus.upcoming,
    );
    if (open.isEmpty) return null;
    final date = open
        .map((i) => i.planned)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final group = [
      for (final i in open)
        if (i.planned == date) i,
    ];
    return DoseGroup(months: group.first.months, date: date, items: group);
  }

  /// Age blocks for "Theo tháng tuổi" and the milestone pages.
  List<DoseGroup> get milestones {
    final byMonth = <int, List<DoseItem>>{};
    for (final i in items) {
      byMonth.putIfAbsent(i.months, () => []).add(i);
    }
    final months = byMonth.keys.toList()..sort();
    return [
      for (final m in months)
        DoseGroup(
          months: m,
          date: byMonth[m]!
              .map((i) => i.planned)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          items: byMonth[m]!,
        ),
    ];
  }

  DoseGroup? milestone(int months) =>
      milestones.where((g) => g.months == months).firstOrNull;

  DoseItem? item(String key) => items.where((i) => i.key == key).firstOrNull;

  /// Doses due by today that are not recorded (VX 0 lists them).
  List<DoseItem> get dueSoFar => [
    for (final i in items)
      if (i.record == null && !i.planned.isAfter(today)) i,
  ];

  /// The 6in1 / 5in1 choice is open until the series' first dose is recorded.
  bool get dtpChoiceOpen => !items.any(
    (i) => i.def.dtpSeries && i.record?.status == DoseRecordStatus.given,
  );
}
