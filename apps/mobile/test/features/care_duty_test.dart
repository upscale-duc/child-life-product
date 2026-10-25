import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  final l = AppLocalizationsVi();
  final now = DateTime.utc(2026, 10, 8, 3); // 10:00 in Hồ Chí Minh

  testWidgets(
    'P-181: the chip says who is caring and since when; the sheet lets another carer take over',
    (tester) async {
      final writes = <bool>[];
      await pumpRouted(
        tester,
        const Scaffold(body: CareDutyChip()),
        overrides: [
          ...familyOverrides(
            now: now,
            duty: CareDuty(
              uid: 'u_lan',
              since: DateTime.utc(2026, 10, 8, 1, 20), // 08:20
              previousUid: 'u_mai',
              previousUntil: DateTime.utc(2026, 10, 8, 1, 20),
            ),
          ),
          careDutyWriterProvider.overrideWithValue((babyId, {required take}) async {
            writes.add(take);
          }),
        ],
      );
      expect(find.text(l.dutyOnNow('Cô Lan', '08:20')), findsOneWidget);
      await tester.tap(find.byKey(const Key('careDutyChip')));
      await tester.pumpAndSettle();
      // Who is on, who was before, and the one action Mai can take.
      expect(find.text(l.dutyStateUntil('08:20')), findsOneWidget);
      expect(find.byKey(const Key('careDutyEnd')), findsNothing);
      await tester.tap(find.byKey(const Key('careDutyTake')));
      await tester.pumpAndSettle();
      expect(writes, [true]);
      expect(find.text(l.dutyTakenToast), findsOneWidget);
    },
  );

  testWidgets('the one on duty ends their own shift', (tester) async {
    final writes = <bool>[];
    await pumpRouted(
      tester,
      const Scaffold(body: CareDutyChip()),
      overrides: [
        ...familyOverrides(
          now: now,
          duty: CareDuty(uid: 'u_mai', since: DateTime.utc(2026, 10, 8, 1)),
        ),
        careDutyWriterProvider.overrideWithValue((babyId, {required take}) async {
          writes.add(take);
        }),
      ],
    );
    await tester.tap(find.byKey(const Key('careDutyChip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('careDutyTake')), findsNothing);
    await tester.tap(find.byKey(const Key('careDutyEnd')));
    await tester.pumpAndSettle();
    expect(writes, [false]);
  });

  testWidgets('a family with one carer sees no chip; nobody on duty invites to take it', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const Scaffold(body: CareDutyChip()),
      overrides: familyOverrides(now: now, members: [mai]),
    );
    expect(find.byKey(const Key('careDutyChip')), findsNothing);
    await pumpRouted(
      tester,
      const Scaffold(body: CareDutyChip()),
      overrides: familyOverrides(now: now),
    );
    expect(find.text(l.dutyNobody), findsOneWidget);
  });
}
