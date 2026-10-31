import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/assistant_screens.dart'
    show AssistantLaunch;
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/insights/insight_models.dart';
import 'package:child_life/features/insights/insight_repository.dart';
import 'package:child_life/features/insights/insight_screens.dart';
import 'package:child_life/features/insights/insight_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/insight_fixtures.dart';
import '../helpers/router_pump.dart';

/// Hiểu con P2 (D-150 Premium, D-151): the app reads the server's insights and never shows a
/// figure to a Free household, a relative, or after the window's records changed.
void main() {
  setUpAll(ensureTimeZones);

  group('model', () {
    test('reads the server document', () {
      final s = InsightState.fromJson(insightDoc())!;
      expect(s.premium, isTrue);
      expect(s.items.map((i) => i.kind), [
        InsightKind.nightLongest,
        InsightKind.nightFeeds,
      ]);
      final i = s.items.first;
      expect(i.up, isTrue);
      expect(i.value, 172);
      expect(i.validNights, 6);
      expect(i.points, hasLength(14));
      expect(i.leftOut, [DateTime(2026, 10, 3)]);
      expect(i.authors, ['Mai', 'Minh']);
      expect(s.today, InsightKind.nightLongest);
      expect(s.enoughNights, isTrue);
    });

    test('a broken or missing document is nothing', () {
      expect(InsightState.fromJson(null), isNull);
      expect(InsightState.fromJson({'premium': true}), isNull);
    });

    test('stale once a record of the window is saved after the computation', () {
      final s = InsightState.fromJson(insightDoc())!;
      final night = rec(
        CareType.sleep,
        vnAt(10, 5, 21),
        mai,
        endedAt: vnAt(10, 6, 2),
      );
      expect(s.staleFor([night]), isFalse);
      expect(
        s.staleFor([
          rec(
            CareType.bottle,
            vnAt(10, 5, 23),
            mai,
          ).copyWithSaved(vnAt(10, 8, 7)),
        ]),
        isTrue,
      );
      // Saving this morning's feed (after the window) does not touch the figures.
      expect(
        s.staleFor([
          rec(
            CareType.bottle,
            vnAt(10, 8, 7),
            mai,
          ).copyWithSaved(vnAt(10, 8, 7)),
        ]),
        isFalse,
      );
    });

    test('who gets it: Premium readers, Free invited, never relatives', () {
      expect(insightAccess(mai, insightCaps()), InsightAccess.full);
      expect(insightAccess(lan, insightCaps()), InsightAccess.full);
      expect(
        insightAccess(mai, insightCaps(premium: false)),
        InsightAccess.invite,
      );
      expect(insightAccess(hoa, insightCaps()), InsightAccess.none);
      expect(insightAccess(mai, null), InsightAccess.none);
    });
  });

  group('Hôm nay card', () {
    Future<void> pump(WidgetTester tester, List<Override> extra) => pumpRouted(
      tester,
      const Scaffold(body: InsightTodayCard()),
      overrides: [...careOverrides(), ...extra],
    ).then((_) => tester.pumpAndSettle());

    testWidgets('Premium: today\'s insight, opening its detail', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: InsightTodayCard()),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Khoảng ngủ đêm dài nhất đang dài hơn'), findsOneWidget);
      expect(
        find.text('TB 2 giờ 52 phút · tuần trước 2 giờ 21 phút'),
        findsOneWidget,
      );
      expect(find.text('Dựa trên 6/7 đêm có ghi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('insightToday')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/insights/night_longest');
    });

    testWidgets('a pick from another day draws nothing', (tester) async {
      await pump(
        tester,
        insightOverrides(doc: insightDoc(todayOn: '2026-10-07')),
      );
      expect(find.byKey(const Key('insightToday')), findsNothing);
    });

    testWidgets('Free: the kind only, no figures, and the way to Premium', (
      tester,
    ) async {
      await pump(
        tester,
        insightOverrides(
          premium: false,
          doc: insightDoc(premium: false, teaser: 'night_longest'),
        ),
      );
      expect(find.byKey(const Key('insightInvite')), findsOneWidget);
      expect(find.textContaining('giấc ngủ đêm của Teddy'), findsOneWidget);
      expect(find.textContaining('phút'), findsNothing);
    });

    testWidgets('a relative sees nothing', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: InsightTodayCard()),
        overrides: [
          ...careOverrides(me: hoa),
          ...insightOverrides(doc: insightDoc()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightToday')), findsNothing);
    });
  });

  group('screens', () {
    testWidgets('Hiểu con lists the insights, then by activity', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const InsightsScreen(),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightHero')), findsOneWidget);
      expect(find.text('Đêm gần đây bú ít cữ hơn'), findsOneWidget);
      expect(find.text('TB 2 cữ · tuần trước 3 cữ'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Theo từng việc'), 300);
      expect(find.text('Theo từng việc'), findsOneWidget);
    });

    testWidgets('not enough nights: progress, no comparison', (tester) async {
      await pumpRouted(
        tester,
        const InsightsScreen(),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(
            doc: insightDoc(items: const [], validNights: 2, today: null),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightsSparse')), findsOneWidget);
      expect(find.text('2/5 đêm có ghi đủ'), findsOneWidget);
      expect(find.byKey(const Key('insightHero')), findsNothing);
    });

    testWidgets('a record changed: figures hidden while recomputing', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const InsightsScreen(),
        overrides: [
          ...careOverrides(
            records: [
              rec(
                CareType.bottle,
                vnAt(10, 6, 23),
                mai,
              ).copyWithSaved(vnAt(10, 8, 7)),
            ],
          ),
          ...insightOverrides(doc: insightDoc()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightsStale')), findsOneWidget);
      expect(find.byKey(const Key('insightHero')), findsNothing);
    });

    testWidgets('Free: the invite only', (tester) async {
      await pumpRouted(
        tester,
        const InsightsScreen(),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(premium: false, doc: insightDoc(premium: false)),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightsInvite')), findsOneWidget);
      expect(find.byKey(const Key('insightHero')), findsNothing);
    });

    testWidgets('detail: the basis, then the statistics', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const InsightDetailScreen(kind: InsightKind.nightLongest),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('6/7 đêm có ghi'), findsWidgets);
      expect(find.textContaining('chưa ghi đủ nên không tính'), findsOneWidget);
      expect(find.text('Đêm từ 18:00 đến 06:00'), findsOneWidget);
      expect(find.text('Ghi bởi Mai, Minh'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('insightStats')),
        300,
      );
      await tester.tap(find.byKey(const Key('insightStats')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/stats/sleep');
    });
  });

  testWidgets('Thống kê giấc ngủ shows its insight (Premium) and opens it', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      const SleepStatsScreen(),
      overrides: [
        ...careOverrides(),
        ...insightOverrides(doc: insightDoc()),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('insightStatsLine')));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/care/insights/night_longest');
  });
  group('P3: feedback, hidden kinds, Lumi, the week', () {
    testWidgets('a hidden kind shows nowhere (Hôm nay, Hiểu con)', (
      tester,
    ) async {
      const muted = InsightPrefs(muted: {InsightKind.nightLongest});
      await pumpRouted(
        tester,
        const Scaffold(body: InsightTodayCard()),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc(), prefs: muted),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('insightToday')), findsNothing);
      await pumpRouted(
        tester,
        const InsightsScreen(),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc(), prefs: muted),
        ],
      );
      await tester.pumpAndSettle();
      // The night-feeds insight leads now.
      expect(find.text('Đêm gần đây bú ít cữ hơn'), findsOneWidget);
      expect(find.text('Khoảng ngủ đêm dài nhất đang dài hơn'), findsNothing);
    });

    testWidgets('Có ích and "không hiện nữa" are this person\'s', (
      tester,
    ) async {
      final repo = _FakePrefs();
      await pumpRouted(
        tester,
        const InsightDetailScreen(kind: InsightKind.nightLongest),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
          insightPrefsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('insightHelpful')),
        300,
      );
      await tester.tap(find.byKey(const Key('insightHelpful')));
      await tester.pump();
      expect(repo.calls.single, 'vote u_mai night_longest_2026-10-07 true');
      await tester.tap(find.byKey(const Key('insightMute')));
      await tester.pump();
      expect(repo.calls.last, 'mute u_mai night_longest true');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Hỏi Lumi opens the chat with the 0-credit question', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const InsightDetailScreen(kind: InsightKind.nightLongest),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
          assistantAccessProvider.overrideWith(
            (ref, babyId) => const AssistantAccess(),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('insightAskLumi')),
        300,
      );
      expect(find.text('Câu hỏi này không tốn lượt hỗ trợ AI'), findsOneWidget);
      await tester.tap(find.byKey(const Key('insightAskLumi')));
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith('/assistant'));
      expect(
        (visits.last.extra! as AssistantLaunch).prefill,
        'Điều đáng chú ý về giấc ngủ đêm được tính thế nào?',
      );
    });

    testWidgets('Tổng kết tuần shows the top insight of its week only', (
      tester,
    ) async {
      Future<void> pumpWeek(String start, String end) => pumpRouted(
        tester,
        Scaffold(
          body: WeekInsightBlock(weekStart: start, weekEnd: end),
        ),
        overrides: [
          ...careOverrides(),
          ...insightOverrides(doc: insightDoc()),
        ],
      ).then((_) => tester.pumpAndSettle());
      await pumpWeek('2026-10-05', '2026-10-11');
      expect(find.text('Điều đáng chú ý nhất'), findsOneWidget);
      expect(find.text('Khoảng ngủ đêm dài nhất đang dài hơn'), findsOneWidget);
      await pumpWeek('2026-09-28', '2026-10-04');
      expect(find.byKey(const Key('weekInsight')), findsNothing);
    });
  });
}

class _FakePrefs implements InsightPrefsRepository {
  final calls = <String>[];

  @override
  Future<void> vote(
    String uid,
    String babyId,
    InsightPrefs current,
    Insight insight,
    bool helpful,
  ) async => calls.add('vote $uid ${InsightPrefs.voteKey(insight)} $helpful');

  @override
  Future<void> setMuted(
    String uid,
    String babyId,
    InsightPrefs current,
    InsightKind kind,
    bool muted,
  ) async => calls.add('mute $uid ${kind.wire} $muted');

  @override
  Stream<InsightPrefs> watch(String uid, String babyId) =>
      Stream.value(const InsightPrefs());
}

extension on CareRecord {
  /// The same record as the server returns it after a save at [at].
  CareRecord copyWithSaved(DateTime at) => CareRecord(
    id: id,
    babyId: babyId,
    type: type,
    occurredAt: occurredAt,
    endedAt: endedAt,
    createdBy: createdBy,
    author: author,
    amountMl: amountMl,
    createdAt: createdAt,
    updatedAt: at,
  );
}
