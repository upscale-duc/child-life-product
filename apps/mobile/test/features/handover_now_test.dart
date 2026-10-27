import 'dart:async';

import 'package:child_life/features/ai/handover_now.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart' show CheckIn;
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  final l = AppLocalizationsVi();

  testWidgets(
    'Bàn giao reads the diary as it is now: last feed and diaper with their clock, the emergency number',
    (tester) async {
      await pumpRouted(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                HandoverNow(me: mai),
                HandoverSafety(me: mai),
              ],
            ),
          ),
        ),
        overrides: [
          ...careOverrides(),
          checkInsProvider.overrideWith((ref, id) => Stream.value(const [])),
          recFeedbackProvider.overrideWith((ref, id) => Stream.value(const [])),
          rhythmContentProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      for (final heading in [l.hoUpcoming]) {
        expect(find.text(heading), findsOneWidget);
      }
      // The mock day: a 120 ml bottle at 14:20 and a wet diaper at 13:40 (Hồ Chí Minh).
      expect(find.text(l.hoLastFeed), findsOneWidget);
      expect(find.textContaining('14:20 · bình 120 ml'), findsOneWidget);
      expect(find.textContaining('13:40'), findsOneWidget);
      expect(find.text(l.hoNextFeedTitle), findsOneWidget);
      expect(find.text(l.hoNoHealth), findsOneWidget);
      expect(find.text(l.hoCall('115')), findsOneWidget);
      expect(find.text(l.hoFirstAid), findsOneWidget);
      // No helpful idea yet: no empty "Cách giúp bé".
      expect(find.text(l.hoHelps), findsNothing);
    },
  );

  Future<void> pumpLive(
    WidgetTester tester, {
    Stream<List<CareRecord>> Function()? records,
    Stream<List<CheckIn>> Function()? checkIns,
  }) => pumpRouted(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HandoverNow(me: mai),
            HandoverSafety(me: mai),
          ],
        ),
      ),
    ),
    overrides: [
      ...careOverrides(recordsStream: records),
      checkInsProvider.overrideWith(
        (ref, id) => checkIns?.call() ?? Stream.value(const []),
      ),
      recFeedbackProvider.overrideWith((ref, id) => Stream.value(const [])),
      rhythmContentProvider.overrideWith((ref) => Stream.value(null)),
    ],
  );

  testWidgets(
    'AI-10: while loading, a skeleton; never "Đang thức" or the all-clear',
    (tester) async {
      await pumpLive(
        tester,
        records: () => StreamController<List<CareRecord>>().stream,
        checkIns: () => StreamController<List<CheckIn>>().stream,
      );
      expect(find.bySemanticsLabel(l.hoLoading), findsOneWidget);
      expect(find.text(l.hoAwake), findsNothing);
      expect(find.text(l.hoNoneYet), findsNothing);
      expect(find.text(l.hoNothingUpcoming), findsNothing);
      expect(find.text(l.hoNoHealth), findsNothing);
      // The emergency buttons are always there.
      expect(find.text(l.hoCall('115')), findsOneWidget);
    },
  );

  testWidgets('AI-10: a failed load says so, with a retry, never "nothing"', (
    tester,
  ) async {
    await pumpLive(
      tester,
      records: () => Stream.error(StateError('denied')),
      checkIns: () => Stream.error(StateError('denied')),
    );
    expect(find.text(l.careLoadFailed), findsOneWidget);
    expect(find.text(l.hoHealthFailed), findsOneWidget);
    expect(find.text(l.hoAwake), findsNothing);
    expect(find.text(l.hoNoHealth), findsNothing);
  });

  testWidgets('B11: no "Hôm nay 0 lần" before the first diaper of the day', (
    tester,
  ) async {
    await pumpLive(tester);
    expect(find.textContaining(l.hoDiapersToday(0)), findsNothing);
  });
}
