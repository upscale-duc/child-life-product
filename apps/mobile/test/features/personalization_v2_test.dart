import 'package:child_life/features/nutrition/nutrition_state.dart';
import 'package:child_life/features/rhythm/personalization_sources.dart';
import 'package:child_life/features/rhythm/personalization_v2_repository.dart';
import 'package:child_life/features/rhythm/personalization_v2_screen.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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

/// The work cards Home would show Mai, in the small-card carousel and as the primary card.
class _WorkCards extends ConsumerWidget {
  const _WorkCards();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref
        .watch(
          personalizedSourceCardsProvider((
            babyId: teddyId,
            uid: mai.uid,
            languageCode: 'vi',
          )),
        )
        .where((c) => c.id.startsWith('work:'))
        .toList();
    return Scaffold(
      body: ListView(
        children: [
          Text('cards: ${cards.map((c) => c.id).join(',')}'),
          if (cards.isNotEmpty) ...[
            ForBabyCarousel(cards: cards),
            PersonalDayHome(primary: cards.first),
          ],
        ],
      ),
    );
  }
}

void main() {
  final l = lookupAppLocalizations(const Locale('vi'));
  // rhythmNow is 2026-10-08 10:00 in Hà Nội; the snapshot expires at the next midnight.
  Map<String, Object?> work(String id, String dueAt, String? assignee) => {
    'id': id,
    'title': 'Việc $id',
    'dueAt': dueAt,
    'assigneeUid': assignee,
    'state': 'unclaimed',
    'actorUid': null,
    'revision': 0,
    'canAct': true,
  };
  // The other Home modules' cards are not under test here.
  List<Override> homeOverrides({
    required PersonalDay day,
    PersonalizationRepository? api,
  }) => [
    ...rhythmOverrides(
      repo: FakeRhythmRepository(),
      personalDay: day,
      personalization: api,
    ),
    nuDataProvider.overrideWithValue(null),
  ];
  final works = [
    work('rm_old', '2026-09-20T03:00:00Z', null),
    work('rm_late', '2026-10-07T02:00:00Z', null),
    work('rm_other', '2026-10-08T02:00:00Z', 'u_minh'),
    work('rm_mine', '2026-10-08T05:00:00Z', mai.uid),
    work('rm_tomorrow', '2026-10-09T02:00:00Z', null),
  ];
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
      await tester.pumpAndSettle();
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
  testWidgets(
    'Home work card: mine or unassigned, due today or overdue < 24 h, and snoozable (audit P2 #4)',
    (tester) async {
      final api = FakePersonalization();
      await pumpRouted(
        tester,
        const _WorkCards(),
        overrides: homeOverrides(day: snapshot({'work': works}), api: api),
      );
      expect(find.text('cards: work:rm_mine'), findsOneWidget);
      // The small card's × (no ♥ on a work card) offers only "until tonight".
      expect(find.byTooltip(l.pv2Save), findsNothing);
      await tester.tap(find.bySemanticsLabel(l.hnCardOptions).first);
      await tester.pumpAndSettle();
      expect(find.text(l.pv2Snooze), findsNothing);
      await tester.tap(find.text(l.pv2WorkSnooze));
      await tester.pumpAndSettle();
      expect(api.actions.single, {
        'kind': 'respond',
        'contentId': 'work:rm_mine',
        'value': 'snooze',
      });
      // The same × on the primary card of "Hôm nay của nhà mình".
      await tester.tap(find.byTooltip(l.pv2Controls));
      await tester.pumpAndSettle();
      expect(find.text(l.pv2WorkSnooze), findsOneWidget);
    },
  );
  testWidgets('a snoozed work card stays away until tonight (audit P2 #4)', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const _WorkCards(),
      overrides: homeOverrides(
        day: snapshot({
          'work': works,
          'responses': {
            'work:rm_mine': {
              'value': 'snooze',
              'until': '2026-10-08T17:00:00Z',
            },
          },
        }),
      ),
    );
    expect(find.text('cards: '), findsOneWidget);
  });
  testWidgets(
    'the reason line is the pick\'s own; dropped choices are gone (audit P2 #7)',
    (tester) async {
      final activity = rhythmContent().activities.first;
      await pumpRouted(
        tester,
        const PersonalizationDayScreen(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          personalDay: snapshot({
            'activityIds': [activity.id],
            'reason': 'AGE_CONTENT',
          }),
          personalization: FakePersonalization(),
        ),
      );
      expect(find.text('Người khác chăm'), findsNothing);
      expect(find.text('Bàn giao dễ hơn'), findsNothing);
      expect(find.text(l.pv2Routine), findsNothing);
      expect(find.text(l.pv2Play), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.pv2OpenActivity), 200);
      expect(find.text(l.pv2BecauseAge), findsOneWidget);
      expect(find.text(l.pv2BecauseInterest), findsNothing);
      expect(reasonLabel(l, 'PREVIOUS_HELPFUL'), l.pv2BecauseHelpful);
      expect(reasonLabel(l, 'WEEKLY_FOCUS'), l.pv2BecauseFocus);
      expect(reasonLabel(l, 'INTEREST'), l.pv2BecauseInterest);
      expect(reasonDim('WEEKLY_FOCUS'), 'WEEKLY_FOCUS');
      expect(reasonDim(null), 'AGE_CONTENT');
    },
  );
}
