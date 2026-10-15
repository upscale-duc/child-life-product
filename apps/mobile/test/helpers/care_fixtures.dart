import 'package:child_life/core/design/tabular_text.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/rule_models.dart';
import 'package:child_life/features/reminders/rule_repository.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/first_aid/first_aid_models.dart';
import 'package:child_life/features/first_aid/first_aid_modes.dart';
import 'package:child_life/features/first_aid/first_aid_repository.dart';
import 'package:child_life/features/vaccines/vaccine_photos.dart';
import 'package:child_life/features/vaccines/vaccine_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';
import 'reminder_fixtures.dart';

/// The 19 Hôm nay mock: Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh (GMT+7).
final careNow = DateTime.utc(2026, 10, 8, 8, 5).toLocal();
DateTime vn(int day, int hour, int minute) =>
    DateTime.utc(2026, 10, day, hour - 7, minute).toLocal();

var _seq = 0;
CareRecord rec(
  CareType type,
  DateTime at,
  Membership by, {
  DateTime? endedAt,
  int? amountMl,
  MilkType? milk,
  Side? side,
  int? durationMin,
  DiaperKind? diaper,
  double? weightKg,
  double? lengthCm,
  double? headCm,
  DateTime? measuredOn,
  Side? endSide,
  int? leftMin,
  int? rightMin,
  bool pending = false,
}) => CareRecord(
  id: 'r_${(++_seq).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  type: type,
  occurredAt: at,
  endedAt: endedAt,
  createdBy: by.uid,
  author: CareAuthor.of(by),
  amountMl: amountMl,
  milk: milk,
  side: side,
  durationMin: durationMin,
  diaper: diaper,
  weightKg: weightKg,
  headCm: headCm,
  lengthCm: lengthCm,
  measuredOn: measuredOn,
  endSide: endSide,
  leftMin: leftMin,
  rightMin: rightMin,
  createdAt: pending ? null : at.add(const Duration(minutes: 2)),
  clientCreatedAt: at.add(const Duration(minutes: 2)),
  pending: pending,
);

/// Today's records, newest first, as on 19 / 9a (bottle and diaper pending when [offline]).
List<CareRecord> mockDay({bool offline = false}) => [
  rec(
    CareType.bottle,
    vn(8, 14, 20),
    mai,
    amountMl: 120,
    milk: MilkType.breastMilk,
    pending: offline,
  ),
  rec(
    CareType.diaper,
    vn(8, 13, 40),
    lan,
    diaper: DiaperKind.wet,
    pending: offline,
  ),
  rec(
    CareType.breast,
    vn(8, 11, 30),
    mai,
    endedAt: vn(8, 11, 45),
    side: Side.both,
    durationMin: 15,
  ),
  rec(
    CareType.pump,
    vn(8, 10, 15),
    mai,
    side: Side.both,
    amountMl: 90,
    durationMin: 15,
  ),
  rec(CareType.diaper, vn(8, 9, 10), mai, diaper: DiaperKind.both),
  rec(
    CareType.bottle,
    vn(8, 8, 0),
    minh,
    amountMl: 120,
    milk: MilkType.formula,
  ),
];

/// A reconciled week ending at [careNow] (2 – 8 Oct): a night sleep from 22:00 that grows from
/// 3 h 30 to 6 h 30, a nap 11:45 – 13:05, bottles at 00:20 / 04:00 / 08:00 / 14:20 / 21:00, a
/// breastfeed at 11:30 ended on the right and diapers — the 20 – 20h stats mock.
List<CareRecord> mockWeek() {
  final list = <CareRecord>[];
  for (var d = 2; d <= 8; d++) {
    final i = d - 2;
    final nightStart = vn(d - 1, 22, 0);
    list
      ..add(
        rec(
          CareType.sleep,
          nightStart,
          i.isEven ? mai : minh,
          endedAt: nightStart.add(Duration(minutes: 210 + 30 * i)),
        ),
      )
      ..add(rec(CareType.sleep, vn(d, 11, 45), lan, endedAt: vn(d, 13, 5)));
    for (final (h, m, ml) in [
      (0, 20, 90),
      (4, 0, 90),
      (8, 0, 120),
      (14, 20, 120),
    ]) {
      list.add(
        rec(
          CareType.bottle,
          vn(d, h, m),
          h < 6 ? minh : mai,
          amountMl: ml,
          milk: h < 6 ? MilkType.formula : MilkType.breastMilk,
        ),
      );
    }
    if (d < 8) {
      list.add(
        rec(
          CareType.bottle,
          vn(d, 21, 0),
          mai,
          amountMl: 120,
          milk: MilkType.formula,
        ),
      );
    }
    list
      ..add(
        rec(
          CareType.breast,
          vn(d, 11, 30),
          mai,
          endedAt: vn(d, 11, 45),
          side: Side.both,
          durationMin: 15,
          endSide: Side.right,
          leftMin: 8,
          rightMin: 7,
        ),
      )
      ..add(rec(CareType.diaper, vn(d, 9, 10), mai, diaper: DiaperKind.both))
      ..add(rec(CareType.diaper, vn(d, 13, 40), lan, diaper: DiaperKind.wet));
  }
  list.add(
    rec(
      CareType.pump,
      vn(8, 10, 15),
      mai,
      side: Side.both,
      amountMl: 90,
      durationMin: 15,
    ),
  );
  list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return list;
}

/// 28's previous measurements: 1 Oct and at birth (17 Sep).
/// Owner 2026-10-16: the same two measurements with a head circumference.
List<CareRecord> mockGrowthWithHead() => [
  rec(
    CareType.growth,
    vn(1, 12, 0),
    mai,
    weightKg: 3.9,
    lengthCm: 53,
    headCm: 37.2,
    measuredOn: DateTime(2026, 10, 1),
  ),
  rec(
    CareType.growth,
    DateTime.utc(2026, 9, 17, 5).toLocal(),
    minh,
    weightKg: 3.2,
    lengthCm: 50,
    headCm: 35.1,
    measuredOn: DateTime(2026, 9, 17),
  ),
];

List<CareRecord> mockGrowth() => [
  rec(
    CareType.growth,
    vn(1, 12, 0),
    mai,
    weightKg: 3.9,
    lengthCm: 53,
    measuredOn: DateTime(2026, 10, 1),
  ),
  rec(
    CareType.growth,
    DateTime.utc(2026, 9, 17, 5).toLocal(),
    minh,
    weightKg: 3.2,
    lengthCm: 50,
    measuredOn: DateTime(2026, 9, 17),
  ),
];

/// What the sheets and screens asked the repository to do.
class FakeCareRepository extends Fake implements CareRepository {
  final created = <CareRecord>[];
  final edited = <CareRecord>[];
  final deleted = <CareRecord>[];
  final restored = <CareRecord>[];

  @override
  void create(CareRecord record, {void Function(Object error)? onError}) =>
      created.add(record);

  @override
  void edit(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => edited.add(record);

  @override
  void softDelete(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => deleted.add(record);

  @override
  void restore(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => restored.add(record);

  @override
  Future<bool> retryNow() async => true;

  final started = <CareTimer>[];
  final updated = <CareTimer>[];
  final cancelled = <CareTimer>[];
  final ended = <(CareTimer, CareRecord)>[];
  final resolved = <(String, String)>[];

  @override
  void startTimer(CareTimer timer, {void Function(Object error)? onError}) =>
      started.add(timer);

  @override
  void updateTimer(
    CareTimer timer,
    String uid, {
    void Function(Object error)? onError,
  }) => updated.add(timer);

  @override
  void cancelTimer(CareTimer timer, {void Function(Object error)? onError}) =>
      cancelled.add(timer);

  @override
  void endTimer(
    CareTimer timer,
    CareRecord record, {
    void Function(Object error)? onError,
  }) => ended.add((timer, record));

  @override
  Future<void> resolveConflict({
    required String babyId,
    required String conflictId,
    required String keepRecordId,
  }) async => resolved.add((conflictId, keepRecordId));
}

/// Family overrides plus care data at the mock's fixed time.
List<Override> careOverrides({
  Membership? me,
  List<CareRecord>? records,
  List<CareRecord>? growth,
  bool online = true,
  FakeCareRepository? repo,
  Map<String, CareRecord>? byId,
  Map<TimerType, CareTimer> timers = const {},
  List<SleepConflict> conflicts = const [],
  List<CareRecord>? range,
  List<Reminder>? reminders,
  ReminderNotifications? notifications,
  List<ReminderRule> rules = const [],
  RuleRepository? ruleRepo,
  Map<String, List<RuleOccurrence>> occurrences = const {},
  Map<String, VaccineDoseRecord> vaccines = const {},
  VaccinePlan vaccinePlan = const VaccinePlan(),
  VaccineRepository? vaccineRepo,
  VaccinePhotoStore? vaccinePhotos,
  FirstAidPack? firstAid,
  List<String> firstAidSaved = const [],
  FirstAidDevice? firstAidDevice,
  FirstAidStore? firstAidStore,
}) => [
  ...familyOverrides(
    me: me,
    records: records ?? mockDay(),
    growth: growth ?? const [],
    online: online,
    now: careNow,
    timers: timers,
    conflicts: conflicts,
    reminders: reminders ?? mockReminders(),
    notifications: notifications,
    rules: rules,
    ruleRepo: ruleRepo,
    occurrences: occurrences,
    vaccines: vaccines,
    vaccinePlan: vaccinePlan,
    vaccineRepo: vaccineRepo,
    vaccinePhotos: vaccinePhotos,
    firstAid: firstAid,
    firstAidSaved: firstAidSaved,
    firstAidDevice: firstAidDevice,
    firstAidStore: firstAidStore,
  ),
  careRepositoryProvider.overrideWithValue(repo ?? FakeCareRepository()),
  careRecordProvider.overrideWith((ref, key) => Stream.value(byId?[key.$2])),
  // History and stats (S6) read ranges; serve them from [range] (default: the mock week).
  rangeRecordsProvider.overrideWith(
    (ref, key) => Stream.value([
      for (final r in range ?? mockWeek())
        if (!r.occurredAt.isBefore(key.$2) && r.occurredAt.isBefore(key.$3)) r,
    ]),
  ),
  dayMarksProvider.overrideWith((ref, key) {
    final marks = <String, DayMarks>{};
    for (final r in range ?? mockWeek()) {
      final l = r.occurredAt.toUtc().add(const Duration(hours: 7));
      final date =
          '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
      if (date.compareTo(key.$2) < 0 || date.compareTo(key.$3) > 0) continue;
      final m = marks[date];
      final feed = r.type == CareType.bottle || r.type == CareType.breast;
      marks[date] = DayMarks(
        feeds: (m?.feeds ?? false) || feed,
        sleep: (m?.sleep ?? false) || r.type == CareType.sleep,
        diapers: (m?.diapers ?? false) || r.type == CareType.diaper,
        other:
            (m?.other ?? false) ||
            r.type == CareType.pump ||
            r.type == CareType.growth,
      );
    }
    return Stream.value(marks);
  }),
];

/// Tabular numerals are laid out digit by digit; find them by their text.
Finder findTabular(String text) => find.byWidgetPredicate(
  (w) => w is ClTabularText && w.text == text,
  description: 'ClTabularText "$text"',
);
