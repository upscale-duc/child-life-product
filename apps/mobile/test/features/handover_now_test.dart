import 'package:child_life/features/ai/handover_now.dart';
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
}
