import 'package:child_life/core/design/tabular_text.dart';
import 'dart:async';

import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final take in [true, false]) {
    testWidgets(
      'loading prevents duplicate ${take ? 'take' : 'end'} and closes only after success',
      (tester) async {
        final pending = Completer<void>();
        var calls = 0;
        await pumpRouted(
          tester,
          const Scaffold(body: CareDutyChip()),
          overrides: [
            ...familyOverrides(
              now: DateTime.utc(2026, 10, 8, 3),
              duty: take
                  ? null
                  : CareDuty(uid: mai.uid, since: DateTime.utc(2026, 10, 8, 2)),
            ),
            careDutyWriterProvider.overrideWithValue((babyId, {required take}) {
              calls++;
              return pending.future;
            }),
          ],
        );
        await tester.tap(find.byKey(const Key('careDutyChip')));
        await tester.pumpAndSettle();
        final key = Key(take ? 'careDutyTake' : 'careDutyEnd');
        final press = tester.widget<ClButton>(find.byKey(key)).onPressed!;
        press();
        press();
        await tester.pump();
        expect(calls, 1);
        expect(tester.widget<ClButton>(find.byKey(key)).loading, isTrue);
        expect(find.byType(ClSheetHeader), findsOneWidget);
        pending.complete();
        await tester.pumpAndSettle();
        expect(find.byType(ClSheetHeader), findsNothing);
      },
    );
  }

  testWidgets(
    'both parent UIDs are recognized and the remaining parent is not ended by the UI',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await pumpRouted(
        tester,
        const Scaffold(body: CareDutyChip(hero: true)),
        overrides: [
          ...familyOverrides(
            now: DateTime.utc(2026, 10, 8, 3),
            duty: CareDuty(
              uid: minh.uid,
              coCarerUid: mai.uid,
              since: DateTime.utc(2026, 10, 8, 2),
            ),
          ),
          careDutyWriterProvider.overrideWithValue((babyId, {required take}) {
            expect(take, isFalse);
            calls++;
            return pending.future;
          }),
        ],
      );
      expect(find.text('Ba và Mẹ đang cùng trông bé'), findsOneWidget);
      await tester.tap(find.byKey(const Key('careDutyChip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('careDutyTake')), findsNothing);
      expect(find.byKey(const Key('careDutyTogether')), findsNothing);
      expect(
        find.textContaining('người còn lại vẫn đang trông bé'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('careDutyEnd')));
      await tester.pump();
      expect(calls, 1);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a failed together request releases loading and can be retried; dismissal is safe',
    (tester) async {
      final first = Completer<void>();
      final retry = Completer<void>();
      var calls = 0;
      await pumpRouted(
        tester,
        const Scaffold(body: CareDutyChip()),
        overrides: [
          ...familyOverrides(),
          careDutyTogetherWriterProvider.overrideWithValue((babyId, partner) {
            expect(partner, minh.uid);
            calls++;
            return calls == 1 ? first.future : retry.future;
          }),
        ],
      );
      await tester.tap(find.byKey(const Key('careDutyChip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('careDutyTogether')));
      await tester.pump();
      expect(
        tester
            .widget<ClButton>(find.byKey(const Key('careDutyTogether')))
            .loading,
        isTrue,
      );
      first.completeError(StateError('network'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ClButton>(find.byKey(const Key('careDutyTogether')))
            .loading,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('careDutyTogether')));
      await tester.pump();
      expect(calls, 2);
      Navigator.of(tester.element(find.byType(ClSheetHeader))).pop();
      await tester.pumpAndSettle();
      retry.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CareDutyChip), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('together is not offered without a verified opposite parent', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const Scaffold(body: CareDutyChip()),
      overrides: familyOverrides(members: [mai, lan]),
    );
    await tester.tap(find.byKey(const Key('careDutyChip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('careDutyTogether')), findsNothing);
  });

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
          careDutyWriterProvider.overrideWithValue((
            babyId, {
            required take,
          }) async {
            writes.add(take);
          }),
        ],
      );
      expect(find.text(l.dutyOnNow('Cô Lan', '08:20')), findsOneWidget);
      await tester.tap(find.byKey(const Key('careDutyChip')));
      await tester.pumpAndSettle();
      // Who is on, who was before, and the one action Mai can take.
      expect(
        find.byWidgetPredicate(
          (w) => w is ClTabularText && w.text == l.dutyStateUntil('08:20'),
        ),
        findsOneWidget,
      );
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
        careDutyWriterProvider.overrideWithValue((
          babyId, {
          required take,
        }) async {
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

  testWidgets(
    'a family with one carer sees no chip; nobody on duty invites to take it',
    (tester) async {
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
    },
  );
}
