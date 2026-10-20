import 'package:child_life/features/rhythm/personalization_v2_repository.dart';
import 'package:child_life/features/rhythm/personalization_v2_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

class FakePersonalization implements PersonalizationRepository {
  final actions = <Map<String, Object?>>[];
  @override
  Future<void> update(String babyId, Map<String, Object?> action) async {
    actions.add(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PersonalDay snapshot([Map<String, Object?> extra = const {}]) => PersonalDay({
  'asOf': '2026-10-08T03:00:00Z',
  'expiresAt': '2026-10-08T17:00:00Z',
  'today': '2026-10-08',
  'zone': 'Asia/Ho_Chi_Minh',
  'writable': true,
  'parent': true,
  'contentVersion': rhythmContent().version,
  'context': 'usual',
  'activityIds': [],
  'notes': [],
  'work': [],
  'patterns': [],
  'responses': {},
  ...extra,
});
void main() {
  final l = lookupAppLocalizations(const Locale('vi'));
  test(
    'cached snapshots expire exactly and saves do not suppress an action',
    () {
      final day = snapshot({
        'responses': {
          'act_a': {'value': 'save', 'saved': true, 'until': null},
          'act_b': {'value': 'snooze', 'until': '2026-10-08T03:00:00Z'},
        },
      });
      expect(day.current(rhythmNow), isTrue);
      expect(day.current(DateTime.utc(2026, 10, 8, 17)), isFalse);
      expect(day.suppressed('act_a', rhythmNow), isFalse);
      expect(day.suppressed('act_b', rhythmNow), isFalse);
    },
  );
  testWidgets(
    'capacity updates only this viewer; no diary pattern is invented',
    (tester) async {
      final api = FakePersonalization();
      await pumpRouted(
        tester,
        const PersonalizationDayScreen(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          personalDay: snapshot(),
          personalization: api,
        ),
      );
      await tester.tap(find.text(l.pv2Busy));
      await tester.pumpAndSettle();
      expect(api.actions.single, {'kind': 'context', 'value': 'busy'});
      await tester.scrollUntilVisible(find.text(l.pv2Insufficient), 350);
      expect(find.text(l.pv2Insufficient), findsOneWidget);
      expect(find.textContaining('120–'), findsNothing);
    },
  );
  testWidgets(
    'helpful outcome remains available after a tried card leaves the feed',
    (tester) async {
      final api = FakePersonalization();
      final activity = rhythmContent().activities.first;
      await pumpRouted(
        tester,
        const PersonalizationDayScreen(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          personalDay: snapshot({
            'responses': {
              activity.id: {
                'value': 'tried',
                'triedAt': '2026-10-08T02:00:00Z',
                'until': '2026-10-08T17:00:00Z',
              },
            },
          }),
          personalization: api,
        ),
      );
      await tester.scrollUntilVisible(find.text(l.pv2History), 350);
      await tester.ensureVisible(find.byType(PopupMenuButton<String>));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.pv2Helpful));
      await tester.pumpAndSettle();
      expect(api.actions.single, {
        'kind': 'respond',
        'contentId': activity.id,
        'value': 'helpful',
      });
    },
  );
  testWidgets(
    'a caregiver cannot see a control that excludes an activity for the whole baby',
    (tester) async {
      final activity = rhythmContent().activities.first;
      final day = snapshot({
        'parent': false,
        'activityIds': [activity.id],
      });
      await pumpRouted(
        tester,
        const PersonalizationDayScreen(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          me: lan,
          personalDay: day,
          personalization: FakePersonalization(),
        ),
      );
      await tester.scrollUntilVisible(find.text(l.pv2Controls), 200);
      await tester.ensureVisible(find.text(l.pv2Controls));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.pv2Controls));
      await tester.pumpAndSettle();
      expect(find.text(l.pv2Save), findsOneWidget);
      expect(find.text(l.pv2Exclude), findsNothing);
      expect(find.text(l.pv2Snooze), findsOneWidget);
    },
  );
}
