import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/vaccines/vaccine_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/vaccine_fixtures.dart';

/// Sổ tiêm chủng (Figma VX 0 – VX 9a, P-133). Teddy, born 17/9/2026; "now" is 8/10 15:05.
void main() {
  group('VX 1 Tiêm chủng', () {
    testWidgets('the next shot, the counter and the matrix', (tester) async {
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          vaccines: vxBirthDoses(),
          vaccinePlan: vxSetUp,
        ),
      );
      expect(find.text('Tiêm chủng'), findsOneWidget);
      expect(find.text('Mũi tiếp theo · 17/11 · còn 40 ngày'), findsOneWidget);
      expect(find.text('6in1 · Rota · Phế cầu (mũi 1)'), findsOneWidget);
      expect(find.text('Đã tiêm 3 / 30 mũi'), findsOneWidget);
      expect(find.text('6in1 hoặc 5in1'), findsOneWidget);
      expect(find.text('18/9'), findsOneWidget); // BCG given
      expect(find.text('Theo vắc xin'), findsOneWidget);
    });

    testWidgets(
      'VX 5: tick Rota 1 today, at the clinic; the toast names dose 2',
      (tester) async {
        final repo = FakeVaccineRepository();
        await pumpRouted(
          tester,
          const VaccineBookScreen(),
          overrides: careOverrides(
            vaccines: vxBirthDoses(),
            vaccinePlan: vxSetUp,
            vaccineRepo: repo,
          ),
        );
        await tester.tap(
          find.bySemanticsLabel(RegExp('^Mũi 1, Sắp tới, 17/11')).at(1),
        );
        await tester.pumpAndSettle();
        expect(find.text('Đã tiêm Rota · mũi 1'), findsOneWidget);
        expect(find.text('Tiêm ngày nào?'), findsOneWidget);
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        final s = repo.saved.single;
        expect(s.key, 'rota_1');
        expect(s.status, DoseRecordStatus.given);
        expect(s.place, VaccinePlace.service);
        expect(
          find.text('Đã lưu Rota mũi 1 · mũi 2 dự kiến 17/12'),
          findsOneWidget,
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets('VX 9 / 9a: an overdue dose can be declined with a reason', (
      tester,
    ) async {
      final repo = FakeVaccineRepository();
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          vaccines: {
            ...vxBirthDoses(),
            'rota_1': vxRec(
              'rota',
              1,
              status: DoseRecordStatus.planned,
              plannedOn: DateTime(2026, 10, 3),
            ),
          },
          vaccinePlan: vxSetUp,
          vaccineRepo: repo,
        ),
      );
      expect(find.textContaining('1 mũi đã quá ngày dự kiến'), findsOneWidget);
      expect(find.text('Quá hạn 5 ngày · dự kiến 3/10'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Mũi 1, Quá hạn')));
      await tester.pumpAndSettle();
      expect(find.text('Dự kiến 3/10 · đã quá 5 ngày'), findsOneWidget);
      await tester.tap(find.text('Không tiêm mũi này'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Theo bác sĩ');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.status, DoseRecordStatus.declined);
      expect(repo.saved.single.reason, 'Theo bác sĩ');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('VX 1b: by month of age, the 2-month block first to come', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          vaccines: vxBirthDoses(),
          vaccinePlan: vxSetUp,
        ),
        prefs: const {'vaccines.view': 'byAge'},
      );
      expect(find.text('Theo tháng tuổi'), findsOneWidget);
      expect(find.text('Sơ sinh'), findsOneWidget);
      expect(find.text('17/11/2026'), findsOneWidget);
      expect(find.text('Rota · 1'), findsOneWidget);
      expect(find.text('Đã tiêm'), findsNWidgets(3));
    });

    testWidgets('caregivers count from the plan’s date; without it, a note', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          me: lan,
          vaccines: vxBirthDoses(),
          vaccinePlan: vxSetUp,
        ),
      );
      expect(
        find.text('Cần ngày sinh của Teddy để lập lịch tiêm.'),
        findsOneWidget,
      );
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          me: lan,
          vaccines: vxBirthDoses(),
          vaccinePlan: VaccinePlan(
            setupDone: true,
            exists: true,
            scheduleFrom: DateTime(2026, 9, 17),
          ),
        ),
      );
      expect(find.text('Đã tiêm 3 / 30 mũi'), findsOneWidget);
    });

    testWidgets('relatives only look', (tester) async {
      await pumpRouted(
        tester,
        const VaccineBookScreen(),
        overrides: careOverrides(
          me: hoa,
          vaccines: vxBirthDoses(),
          vaccinePlan: VaccinePlan(
            setupDone: true,
            exists: true,
            scheduleFrom: DateTime(2026, 9, 17),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Mũi 1, Sắp tới')).first);
      await tester.pump();
      expect(find.text('Bạn chỉ xem được sổ tiêm.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('VX 0 · 2 · 6 · 7', () {
    testWidgets('VX 0: the birth doses ticked; "Lưu 3 mũi đã tiêm"', (
      tester,
    ) async {
      final repo = FakeVaccineRepository();
      await pumpRouted(
        tester,
        const VaccineSetupScreen(),
        overrides: careOverrides(vaccineRepo: repo),
      );
      expect(find.text('Teddy đã tiêm những mũi nào?'), findsOneWidget);
      expect(find.text('Trong 24 giờ đầu'), findsOneWidget);
      await tester.tap(find.text('Lưu 3 mũi đã tiêm'));
      await tester.pumpAndSettle();
      expect(repo.setups.single, ['vitk_1', 'bcg_1', 'hepb_1']);
      expect(repo.plans.last.setupDone, isTrue);
      expect(repo.plans.last.scheduleFrom, DateTime(2026, 9, 17));
    });

    testWidgets('VX 2: choose 5in1; the other shots with "Ghi"', (
      tester,
    ) async {
      final repo = FakeVaccineRepository();
      await pumpRouted(
        tester,
        const VaccineMilestoneScreen(months: 2),
        overrides: careOverrides(
          vaccines: vxBirthDoses(),
          vaccinePlan: vxSetUp,
          vaccineRepo: repo,
        ),
      );
      expect(find.text('Dự kiến 17/11/2026 · còn 40 ngày'), findsOneWidget);
      expect(find.text('2 tháng tuổi'), findsOneWidget);
      expect(find.text('Chọn một trong hai'), findsOneWidget);
      expect(find.text('Rota · mũi 1'), findsOneWidget);
      expect(find.text('Uống · Dịch vụ'), findsOneWidget);
      expect(find.text('Ghi'), findsNWidgets(2));
      await tester.tap(find.text('5in1 + Bại liệt · Trạm y tế'));
      await tester.pumpAndSettle();
      expect(repo.plans.last.dtp, DtpChoice.fiveInOne);
    });

    testWidgets('VX 6: a given dose, who logged it, and delete', (
      tester,
    ) async {
      final repo = FakeVaccineRepository();
      await pumpRouted(
        tester,
        const VaccineDoseScreen(doseKey: 'dtp_1'),
        overrides: careOverrides(
          vaccines: {
            ...vxBirthDoses(),
            'dtp_1': vxRec(
              'dtp',
              1,
              on: DateTime(2026, 10, 6),
              by: 'u_minh',
              reaction: 'Sốt nhẹ buổi tối',
            ),
          },
          vaccinePlan: vxSetUp.copyWith(dtp: DtpChoice.sixInOne),
          vaccineRepo: repo,
        ),
      );
      expect(find.text('6in1 · mũi 1'), findsOneWidget);
      expect(find.text('Thứ Ba, 6/10/2026'), findsOneWidget);
      expect(find.text('Dịch vụ'), findsOneWidget);
      expect(find.text('Ba'), findsOneWidget);
      expect(find.text('Sốt nhẹ buổi tối'), findsOneWidget);
      expect(find.text('Mũi 2 dự kiến 17/12 · đã bật nhắc'), findsOneWidget);
      await tester.tap(find.text('Xoá mũi tiêm này'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['dtp_1']);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('VX 7: Rota — 3 liều, 4 weeks apart, Dịch vụ', (tester) async {
      await pumpRouted(
        tester,
        const VaccineInfoScreen(vaccineId: 'rota'),
        overrides: careOverrides(
          vaccines: vxBirthDoses(),
          vaccinePlan: vxSetUp,
        ),
      );
      expect(find.text('Rota'), findsOneWidget);
      expect(find.text('3 liều'), findsOneWidget);
      expect(find.text('Tối thiểu 4 tuần giữa các mũi'), findsOneWidget);
      expect(find.text('Các mũi của Teddy'), findsOneWidget);
      expect(find.text('Dự kiến 17/1/2027'), findsOneWidget);
    });
  });

  testWidgets('the Chăm sóc tile says the next shot', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: CareHubScreen()),
      overrides: careOverrides(vaccines: vxBirthDoses(), vaccinePlan: vxSetUp),
    );
    expect(find.text('Tiêm chủng'), findsOneWidget);
    expect(find.text('Mũi tiếp theo 17/11'), findsOneWidget);
  });
}
