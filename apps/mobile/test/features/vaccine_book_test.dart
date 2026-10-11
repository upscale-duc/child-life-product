import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sổ tiêm chủng (Figma VX 1 / 1b / 9, P-133): Teddy, born 17/9/2026, on 8/10/2026.
final dob = DateTime(2026, 9, 17);

VaccineDoseRecord given(
  String vaccineId,
  int dose, {
  DateTime? on,
  DoseRecordStatus status = DoseRecordStatus.given,
  DateTime? plannedOn,
}) => VaccineDoseRecord(
  key: doseKeyOf(vaccineId, dose),
  vaccineId: vaccineId,
  dose: dose,
  status: status,
  givenOn: on,
  plannedOn: plannedOn,
  createdBy: 'u_mai',
  author: const CareAuthor(name: 'Mai', relation: Relation.mother),
);

Map<String, VaccineDoseRecord> birthDoses() => {
  for (final r in [
    given('vitk', 1, on: DateTime(2026, 9, 17)),
    given('bcg', 1, on: DateTime(2026, 9, 18)),
    given('hepb', 1, on: DateTime(2026, 9, 17)),
  ])
    r.key: r,
};

void main() {
  test('planned dates are DOB + calendar months; the 31st falls back', () {
    expect(plannedDate(dob, 2), DateTime(2026, 11, 17));
    expect(plannedDate(dob, 24), DateTime(2028, 9, 17));
    expect(plannedDate(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
  });

  test('VX 1: 3 / 30, the 2-month shots are next, the rest later', () {
    final book = VaccineBook.of(
      dob: dob,
      today: DateTime(2026, 10, 8),
      plan: const VaccinePlan(),
      records: birthDoses(),
    );
    expect(book.given, 3);
    expect(book.total, 30);
    expect(book.vaccines, hasLength(14));
    final next = book.nextGroup!;
    expect(next.date, DateTime(2026, 11, 17));
    expect([for (final i in next.items) i.key], ['dtp_1', 'rota_1', 'pcv_1']);
    expect(next.items.every((i) => i.status == DoseStatus.upcoming), isTrue);
    expect(book.item('dtp_2')!.status, DoseStatus.later);
    expect(book.milestones.map((g) => g.months), [
      0,
      2,
      3,
      4,
      6,
      7,
      8,
      9,
      10,
      12,
      13,
      15,
      18,
      24,
    ]);
    expect(book.dueSoFar, isEmpty);
  });

  test('VX 9: on 22/11 the three 2-month shots are overdue', () {
    final book = VaccineBook.of(
      dob: dob,
      today: DateTime(2026, 11, 22),
      plan: const VaccinePlan(),
      records: birthDoses(),
    );
    expect(book.overdue.map((i) => i.key), ['dtp_1', 'rota_1', 'pcv_1']);
    expect(book.nextGroup!.date, DateTime(2026, 11, 17));
    // The next date to come is the 3-month milestone.
    expect(book.item('rota_2')!.status, DoseStatus.upcoming);
  });

  test(
    '5in1 adds polio; declined leaves the total; "Dời lịch" moves one dose',
    () {
      final records = {
        ...birthDoses(),
        'menbc_1': given('menbc', 1, status: DoseRecordStatus.declined),
        'rota_1': given(
          'rota',
          1,
          status: DoseRecordStatus.planned,
          plannedOn: DateTime(2026, 11, 25),
        ),
      };
      final book = VaccineBook.of(
        dob: dob,
        today: DateTime(2026, 10, 8),
        plan: const VaccinePlan(dtp: DtpChoice.fiveInOne),
        records: records,
      );
      expect(book.vaccines.map((v) => v.id), contains('polio'));
      expect(book.total, 33 - 1);
      expect(book.item('menbc_1')!.status, DoseStatus.declined);
      expect(book.item('rota_1')!.planned, DateTime(2026, 11, 25));
      expect(book.item('rota_1')!.status, DoseStatus.later);
      expect(book.nextGroup!.items.map((i) => i.key), [
        'dtp_1',
        'polio_1',
        'pcv_1',
      ]);
    },
  );

  test('VX 0 lists what is due so far; the choice closes after a dtp dose', () {
    final book = VaccineBook.of(
      dob: dob,
      today: DateTime(2027, 1, 20),
      plan: const VaccinePlan(),
      records: {'dtp_1': given('dtp', 1, on: DateTime(2026, 11, 17))},
    );
    expect(book.dueSoFar.map((i) => i.key), [
      'vitk_1',
      'bcg_1',
      'hepb_1',
      'dtp_2',
      'dtp_3',
      'rota_1',
      'rota_2',
      'rota_3',
      'pcv_1',
      'pcv_2',
      'pcv_3',
    ]);
    expect(book.dtpChoiceOpen, isFalse);
  });
}
