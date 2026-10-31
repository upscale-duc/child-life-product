import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/vaccines/vaccine_screens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/vaccine_fixtures.dart';

/// Lumi L5: "bé vừa tiêm rota" opens the book's own form on that dose, filled; saved there.
/// Teddy, born 17/9/2026; "now" is 8/10 15:05.
void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  test('only the book or a dose page, each value in its shape', () {
    expect(
      vaccineRoute('/care/vaccines?log=dtp_2&on=2026-10-31&place=service'),
      '/care/vaccines?log=dtp_2&on=2026-10-31&place=service',
    );
    expect(
      vaccineRoute(
        '/care/vaccines?log=rota_1&on=2026-10-31&facility=VNVC+Ho%C3%A0ng+C%E1%BA%A7u',
      ),
      isNotNull,
    );
    expect(vaccineRoute('/care/vaccines'), '/care/vaccines');
    expect(
      vaccineRoute('/care/vaccines/dose/dtp_2'),
      '/care/vaccines/dose/dtp_2',
    );
    for (final bad in [
      null,
      'https://evil.example/care/vaccines?log=dtp_2&on=2026-10-31',
      '/care/vaccines?log=dtp_2',
      '/care/vaccines?on=2026-10-31',
      '/care/vaccines?log=DTP_2&on=2026-10-31',
      '/care/vaccines?log=dtp_2&on=31/10',
      '/care/vaccines?log=dtp_2&on=2026-10-31&place=home',
      '/care/vaccines?log=dtp_2&on=2026-10-31&next=/me',
      '/care/vaccines/dose/dtp_2?x=1',
      '/care/vaccines/info/dtp',
    ]) {
      expect(vaccineRoute(bad), isNull, reason: bad);
    }
  });

  testWidgets('the form opens once on the dose, with the day and place said', (
    tester,
  ) async {
    final repo = FakeVaccineRepository();
    await pumpRouted(
      tester,
      VaccineBookScreen(
        logKey: 'rota_1',
        logOn: DateTime(2026, 10, 7),
        logPlace: VaccinePlace.hospital,
        logFacility: 'Bệnh viện Nhi',
      ),
      overrides: careOverrides(
        vaccines: vxBirthDoses(),
        vaccinePlan: vxSetUp,
        vaccineRepo: repo,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ghi mũi tiêm'), findsOneWidget);
    expect(find.text('Bệnh viện Nhi'), findsOneWidget);
    await tester.ensureVisible(find.text('Lưu mũi tiêm'));
    await tester.tap(find.text('Lưu mũi tiêm'));
    await tester.pumpAndSettle();
    final s = repo.saved.single;
    expect(s.key, 'rota_1');
    expect(s.status, DoseRecordStatus.given);
    expect(s.givenOn, DateTime(2026, 10, 7));
    expect(s.place, VaccinePlace.hospital);
    // Back on the book, the form does not open again.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Ghi mũi tiêm'), findsNothing);
  });

  testWidgets('a dose already given opens its page instead', (tester) async {
    final repo = FakeVaccineRepository();
    await pumpRouted(
      tester,
      VaccineBookScreen(logKey: 'bcg_1', logOn: DateTime(2026, 10, 7)),
      overrides: careOverrides(
        vaccines: vxBirthDoses(),
        vaccinePlan: vxSetUp,
        vaccineRepo: repo,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ghi mũi tiêm'), findsNothing);
    expect(repo.saved, isEmpty);
  });
}
