import 'dart:convert';

import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:child_life/features/rhythm/rhythm_episodes.dart';
import 'package:child_life/features/rhythm/rhythm_local.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_overview.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// Nhịp lớn lên leftovers: NL07b observation episodes (suggest → confirm → "Con đã ổn hơn",
/// never auto-closed) and the NL02c evening check-in prompt (20:30, skipped once I noted
/// something today, quiet hours respected, no baby name).
final l10n = lookupAppLocalizations(const Locale('vi'));

final _seen = <String, Object>{
  'rhythm.setupSeen.u_mai.$teddyId': true,
  'rhythm.setupSeen.u_minh.$teddyId': true,
  'rhythm.setupSeen.u_lan.$teddyId': true,
};

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _toastGone(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}

CheckIn _ci(
  String uid,
  String date,
  Observation o, {
  List<HealthSign>? signs,
}) => CheckIn(
  id: checkInIdFor(babyId: teddyId, uid: uid, date: date, observation: o),
  babyId: teddyId,
  date: date,
  authorUid: uid,
  observation: o,
  healthSigns: signs ?? const [],
);

ObservationEpisode _open(String start) => ObservationEpisode(
  id: episodeIdFor(teddyId, start),
  babyId: teddyId,
  startDate: start,
  confirmedBy: 'u_mai',
  checkInIds: [recentCheckIns().last.id],
);

void main() {
  group('NL07b · suggestion (Dart side of suggestEpisode)', () {
    test('mirrors contracts: two changed days of the last three', () {
      expect(
        suggestEpisode([
          (date: '2026-10-06', state: ObservationState.reportedChange),
          (date: '2026-10-07', state: ObservationState.normal),
          (date: '2026-10-08', state: ObservationState.mixed),
        ]),
        isTrue,
      );
      expect(
        suggestEpisode([
          (date: '2026-10-08', state: ObservationState.reportedChange),
        ]),
        isFalse,
      );
    });

    test('groups the changed notes of the last three days with updates', () {
      final s = episodeSuggestion(
        checkIns: recentCheckIns(),
        episodes: const [],
        today: rhythmToday,
      )!;
      expect(s.startDate, '2026-10-06');
      expect(s.lastDate, rhythmToday);
      expect(s.dayCount, 3);
      // Mẹ's "Như mọi ngày" on 7/10 is not grouped in.
      expect(s.changed.map((c) => c.authorUid), ['u_mai', 'u_minh', 'u_lan']);
    });

    test('never with an open episode; not again before newer days', () {
      final checkIns = recentCheckIns();
      expect(
        episodeSuggestion(
          checkIns: checkIns,
          episodes: [_open('2026-10-06')],
          today: rhythmToday,
        ),
        isNull,
      );
      // Closed today ("Con đã ổn hơn"): those days stay closed.
      expect(
        episodeSuggestion(
          checkIns: checkIns,
          episodes: [
            _open('2026-10-06').close(uid: 'u_mai', date: rhythmToday),
          ],
          today: rhythmToday,
        ),
        isNull,
      );
      // "Không cần" up to today.
      expect(
        episodeSuggestion(
          checkIns: checkIns,
          episodes: const [],
          today: rhythmToday,
          dismissedThrough: rhythmToday,
        ),
        isNull,
      );
      // Two new changed days after the dismissal bring it back.
      expect(
        episodeSuggestion(
          checkIns: [
            ...checkIns,
            _ci('u_mai', '2026-10-09', Observation.sleep),
            _ci('u_minh', '2026-10-10', Observation.feeding),
          ],
          episodes: const [],
          today: '2026-10-10',
          dismissedThrough: rhythmToday,
        )?.startDate,
        '2026-10-09',
      );
    });

    test('health worries and old days are left out', () {
      expect(
        episodeSuggestion(
          checkIns: [
            _ci(
              'u_mai',
              '2026-10-07',
              Observation.health,
              signs: [HealthSign.breathing],
            ),
            _ci('u_mai', '2026-10-08', Observation.sleep),
          ],
          episodes: const [],
          today: rhythmToday,
        ),
        isNull,
      );
      expect(
        episodeSuggestion(
          checkIns: [
            _ci('u_mai', '2026-09-20', Observation.sleep),
            _ci('u_mai', '2026-09-21', Observation.sleep),
          ],
          episodes: const [],
          today: rhythmToday,
        ),
        isNull,
      );
    });

    test('episode ids are stable per baby and first day; tolerant parsing', () {
      expect(
        episodeIdFor(teddyId, '2026-10-06'),
        matches(r'^ep_[a-f0-9]{32}$'),
      );
      expect(
        episodeIdFor(teddyId, '2026-10-06'),
        episodeIdFor(teddyId, '2026-10-06'),
      );
      final e = _open('2026-10-06');
      final back = ObservationEpisode.fromJson({
        ...e.toJson(),
        'checkInIds': [...e.checkInIds, 'not-an-id'],
      })!;
      expect(back.open, isTrue);
      expect(back.checkInIds, e.checkInIds);
      expect(
        ObservationEpisode.fromJson({...e.toJson(), 'status': 'x'}),
        isNull,
      );
      final closed = e.close(uid: 'u_minh', date: rhythmToday);
      expect(closed.toJson()['status'], 'closed');
      expect(closed.toJson()['endDate'], rhythmToday);
      expect(closed.toJson()['closedBy'], 'u_minh');
    });
  });

  group('NL07b · on NL01', () {
    testWidgets('suggest → create → open episode → "Con đã ổn hơn"', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(checkIns: recentCheckIns());
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhEpSuggestTitle), findsOneWidget);
      expect(find.text(l10n.rhEpNotWonder), findsOneWidget);
      // D-102: the days show as dots above; the sentence says what, not who and when.
      expect(find.textContaining('3 ngày gần đây cả nhà thấy con'), findsOneWidget);
      await _tap(tester, find.text(l10n.rhEpCreate));
      final created = repo.savedEpisodes.single;
      expect(created.startDate, '2026-10-06');
      expect(created.confirmedBy, 'u_mai');
      expect(created.open, isTrue);
      expect(created.checkInIds, hasLength(3));
      await _toastGone(tester);
      expect(find.text(l10n.rhEpSuggestTitle), findsNothing);
      expect(find.text(l10n.rhEpOpenTitle('06/10')), findsOneWidget);
      expect(find.text(l10n.rhEpUpdating), findsOneWidget);
      expect(find.text(l10n.rhEpOpenBody('Bạn', 3)), findsOneWidget);

      await _tap(tester, find.text(l10n.rhEpBetter));
      expect(find.text(l10n.rhEpCloseTitle), findsOneWidget);
      // The sheet's confirm (the second "Con đã ổn hơn").
      await _tap(tester, find.text(l10n.rhEpBetter).last);
      final closed = repo.savedEpisodes.last;
      expect(closed.open, isFalse);
      expect(closed.endDate, rhythmToday);
      expect(closed.closedBy, 'u_mai');
      await _toastGone(tester);
      expect(find.text(l10n.rhEpOpenTitle('06/10')), findsNothing);
      // Those days are closed: no new suggestion.
      expect(find.text(l10n.rhEpSuggestTitle), findsNothing);
    });

    testWidgets('"Không cần" hides it and is remembered', (tester) async {
      final repo = FakeRhythmRepository(checkIns: recentCheckIns());
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhEpNoNeed));
      expect(find.text(l10n.rhEpSuggestTitle), findsNothing);
      expect(repo.savedEpisodes, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('rhythm.episodeDismissed.u_mai|$teddyId'),
        rhythmToday,
      );
    });

    testWidgets('an open episode stays open whatever the silence', (
      tester,
    ) async {
      // No check-in for days: still "Đang cập nhật".
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(episodes: [_open('2026-09-20')]),
        ),
      );
      expect(find.text(l10n.rhEpOpenTitle('20/09')), findsOneWidget);
      expect(find.text(l10n.rhEpUpdating), findsOneWidget);
    });

    testWidgets('a caregiver may confirm; a relative only reads', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          me: lan,
          repo: FakeRhythmRepository(checkIns: recentCheckIns()),
        ),
      );
      expect(find.text(l10n.rhEpCreate), findsOneWidget);
    });

    testWidgets('a relative with daily care sees the episode, no buttons', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          me: member(
            'u_hoa',
            'Bà nội Hoa',
            hoa.role,
            hoa.relation,
            extra: const ExtraRights(viewBabyInfo: true, viewDailyCare: true),
          ),
          repo: FakeRhythmRepository(
            checkIns: recentCheckIns(),
            episodes: [_open('2026-10-06')],
          ),
        ),
      );
      expect(find.text(l10n.rhEpOpenTitle('06/10')), findsOneWidget);
      expect(find.text(l10n.rhEpBetter), findsNothing);
    });
  });

  group('NL02c · evening check-in prompt', () {
    final morning = DateTime(2026, 10, 8, 10);

    test('the next evenings at 20:30; off means nothing', () {
      expect(
        eveningCheckInPlan(enabled: false, now: morning, checkedInToday: false),
        isEmpty,
      );
      expect(
        eveningCheckInPlan(
          enabled: true,
          now: morning,
          checkedInToday: false,
          quietFrom: '22:00',
          quietTo: '06:00',
        ),
        [
          DateTime(2026, 10, 8, 20, 30),
          DateTime(2026, 10, 9, 20, 30),
          DateTime(2026, 10, 10, 20, 30),
        ],
      );
    });

    test('skipped today once I noted something; never in the past', () {
      expect(
        eveningCheckInPlan(
          enabled: true,
          now: morning,
          checkedInToday: true,
        ).first,
        DateTime(2026, 10, 9, 20, 30),
      );
      expect(
        eveningCheckInPlan(
          enabled: true,
          now: DateTime(2026, 10, 8, 21),
          checkedInToday: false,
        ).first,
        DateTime(2026, 10, 9, 20, 30),
      );
    });

    test('quiet hours: moved before them, or dropped', () {
      expect(
        eveningCheckInPlan(
          enabled: true,
          now: morning,
          checkedInToday: false,
          quietFrom: '20:00',
          quietTo: '06:30',
        ).first,
        DateTime(2026, 10, 8, 19, 30),
      );
      expect(
        eveningCheckInPlan(
          enabled: true,
          now: morning,
          checkedInToday: false,
          quietFrom: '12:00',
          quietTo: '23:00',
        ),
        isEmpty,
      );
    });

    test('one local notification: no baby name, own id range, opens C01', () {
      final n = rhythmEveningNotification(l10n, (
        babyId: teddyId,
        fireAt: DateTime(2026, 10, 8, 20, 30),
      ));
      expect(n.title, l10n.rhCheckInEntry);
      expect(n.body, l10n.rhEveningBody);
      expect('${n.title} ${n.body}', isNot(contains('Teddy')));
      expect(n.id & (1 << 29), isNonZero);
      expect(n.id & (1 << 28), isNonZero);
      expect(n.id & (1 << 30), isZero);
      final other = rhythmEveningNotification(l10n, (
        babyId: teddyId,
        fireAt: DateTime(2026, 10, 9, 20, 30),
      ));
      expect(other.id, isNot(n.id));
      expect(rhythmCheckInOfPayload(n.payload), teddyId);
      expect(rhythmOfPayload(n.payload), isNull);
      expect(
        rhythmCheckInOfPayload(jsonEncode({'k': 'rhythm', 'b': 'x'})),
        isNull,
      );
      expect(rhythmCheckInOfPayload('not json'), isNull);
      expect(Routes.rhythmCheckIn, '/rhythm/checkin');
    });

    testWidgets('the plan for this phone: my switch, my check-ins today', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(checkIns: recentCheckIns());
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        prefs: {
          'rhythm.reminders.u_mai': jsonEncode({
            'stage': true,
            'evening': true,
          }),
        },
        overrides: rhythmOverrides(repo: repo),
      );
      final sub = container.listen(rhythmEveningPlanProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      // Mai has no note today (Cô Lan has): today's 20:30 is kept.
      var plan = container.read(rhythmEveningPlanProvider);
      expect(plan.first.babyId, teddyId);
      expect(plan.first.fireAt.day, 8);
      // Mai notes something today: the plan starts tomorrow.
      repo.saveCheckIn(_ci('u_mai', rhythmToday, Observation.sleep));
      await tester.pumpAndSettle();
      plan = container.read(rhythmEveningPlanProvider);
      expect(plan.first.fireAt.day, 9);
      expect(container.read(checkInsProvider(teddyId)).value, isNotEmpty);
    });
  });
}
