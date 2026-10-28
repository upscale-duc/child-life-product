@Tags(['golden'])
library;

import 'dart:async';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  const cases = [
    'mine',
    'other',
    'nobody',
    'parents',
    // D-135 Q1: a helper takes a shift; "Ba và Mẹ cùng trông" is retired.
    'take_pending',
    'end_pending',
    'large_parents',
    'loading',
    'error',
  ];
  for (final name in cases) {
    for (final palette in ClPalette.values) {
      for (final lang in ['vi', 'en']) {
        testWidgets('$name ${palette.name} $lang', (tester) async {
          final pending = Completer<void>();
          final controller = name == 'loading'
              ? StreamController<CareDuty?>()
              : null;
          if (controller != null) addTearDown(controller.close);

          final parents = [
            'parents',
            'large_parents',
            'end_pending',
          ].contains(name);
          final duty = ['mine', 'together_pending'].contains(name)
              ? CareDuty(uid: mai.uid, since: DateTime.utc(2026, 10, 8, 3))
              : parents
              ? CareDuty(
                  uid: minh.uid,
                  coCarerUid: mai.uid,
                  since: DateTime.utc(2026, 10, 8, 2),
                )
              : name == 'other'
              ? CareDuty(uid: lan.uid, since: DateTime.utc(2026, 10, 8, 2))
              : null;
          await pumpRouted(
            tester,
            Scaffold(
              body: name == 'loading' || name == 'error'
                  ? Consumer(
                      builder: (context, ref, _) => TextButton(
                        onPressed: () => showCareDutySheet(context, ref, mai),
                        child: const Text('open'),
                      ),
                    )
                  : const CareDutyChip(hero: true),
            ),
            palette: palette,
            textScaler: name == 'large_parents'
                ? const TextScaler.linear(2)
                : null,
            locale: Locale(lang),
            overrides: [
              ...familyOverrides(
                me: name == 'take_pending' ? lan : null,
                now: DateTime.utc(2026, 10, 8, 3),
                duty: duty,
              ),
              careDutyWriterProvider.overrideWithValue(
                (_, {required take}) => pending.future,
              ),
              careDutyTogetherWriterProvider.overrideWithValue(
                (_, _) => pending.future,
              ),
              if (name == 'loading')
                careDutyProvider(
                  teddyId,
                ).overrideWith((_) => controller!.stream),
              if (name == 'error')
                careDutyProvider(
                  teddyId,
                ).overrideWith((_) => Stream.error(StateError('offline'))),
            ],
          );
          await tester.tap(
            name == 'loading' || name == 'error'
                ? find.text('open')
                : find.byKey(const Key('careDutyChip')),
          );
          await tester.pumpAndSettle();
          if (name.endsWith('_pending')) {
            final key = name == 'take_pending'
                ? 'careDutyTake'
                : name == 'end_pending'
                ? 'careDutyEnd'
                : 'careDutyTogether';
            await tester.tap(find.byKey(Key(key)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/cd/${name}_${palette.name}_$lang.png'),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          pending.complete();
          await tester.pump();
        });
      }
    }
  }
}
