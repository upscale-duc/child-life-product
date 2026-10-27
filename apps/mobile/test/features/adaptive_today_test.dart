import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_feedback.dart' show ClSkeleton;
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/today_adaptive.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/family_fixtures.dart' show teddy;
import '../helpers/hn_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/spending_fixtures.dart';

/// Adaptive Experience Hôm nay (Figma 930:11858, P-175, D-097): greeting by age band, ranked
/// widgets, first run, "Tuỳ chỉnh Hôm nay" (AX14).

const _today = Scaffold(body: TodayScreen());

List<Override> _overrides({
  required AgeBand band,
  required FakeExperienceRepository repo,
  List<MediaItem> media = const [],
  bool adaptive = true,
  List<Expense> expenses = const [],
}) => [
  ...hnOverrides(
    repo: StampingRhythmRepository(preferences: personalized()),
    expenses: expenses,
  ),
  ...adaptiveOverrides(
    band: band,
    repo: repo,
    media: media,
    adaptive: adaptive,
  ),
];

double _y(WidgetTester tester, Key key) =>
    tester.getTopLeft(find.byKey(key)).dy;

/// The page's own list (the photo strip and the reorderable list scroll too).
Future<void> _scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);

void main() {
  final photo = mediaItem('mem_1', DateTime(2026, 10, 7));

  testWidgets('3–6 tuổi: AX12 greeting and order, no quick log', (
    tester,
  ) async {
    final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b3_6));
    await pumpRouted(
      tester,
      _today,
      overrides: _overrides(band: AgeBand.b3_6, repo: repo, media: [photo]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chào ngày mới cùng Teddy'), findsOneWidget);
    expect(find.byKey(const Key('axMomentToday')), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('axFamily')));
    expect(
      _y(tester, const Key('axCreate')),
      lessThan(_y(tester, const Key('axFamily'))),
    );
    await _scrollTo(tester, find.byKey(const Key('axCustomize')));
    expect(find.byKey(const Key('axCustomize')), findsOneWidget);
    // The band's default hides the tiles ("Ẩn theo gợi ý tuổi"), nothing is locked.
    expect(find.text('Bú bình'), findsNothing);
  });

  testWidgets(
    '0–1 tuổi, first run: AX40 greeting and "Lưu khoảnh khắc đầu tiên"',
    (tester) async {
      final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b0_1));
      await pumpRouted(
        tester,
        _today,
        overrides: _overrides(band: AgeBand.b0_1, repo: repo),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chào ngày mới cùng Teddy'), findsOneWidget);
      await _scrollTo(tester, find.byKey(const Key('axFirstMoment')));
      expect(find.text('Lưu khoảnh khắc đầu tiên'), findsOneWidget);
      // "Tuỳ chỉnh Hôm nay" on the first run too (owner, 2026-10-24: some children had none).
      await _scrollTo(tester, find.byKey(const Key('axCustomize')));
      expect(find.byKey(const Key('axCustomize')), findsOneWidget);
    },
  );

  testWidgets('AX12 Chi tiêu tháng này: total, month · count, the categories', (
    tester,
  ) async {
    final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b3_6));
    await pumpRouted(
      tester,
      _today,
      overrides: _overrides(
        band: AgeBand.b3_6,
        repo: repo,
        media: [photo],
        expenses: [
          spend('1', 1000000, 'c_childcare', DateTime(2026, 10, 2)),
          spend('2', 500000, 'c_childcare', DateTime(2026, 10, 5)),
          spend('3', 950000, 'c_clothes', DateTime(2026, 10, 6)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('axSpending')));
    final card = find.byKey(const Key('axSpending'));
    expect(
      find.descendant(of: card, matching: find.text('Tháng 10 · 3 khoản')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('2.450.000')),
      findsOneWidget,
    );
  });

  testWidgets(
    'flag off: Living Header keeps legacy customization and widget preferences',
    (tester) async {
      final repo = FakeExperienceRepository();
      await pumpRouted(
        tester,
        _today,
        overrides: _overrides(band: AgeBand.b3_6, repo: repo, adaptive: false),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('axGreeting')), findsOneWidget);
      expect(find.text('Tuỳ chỉnh'), findsOneWidget);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'a person with no arrangement gets one saved (bandApplied frozen)',
    (tester) async {
      final repo = FakeExperienceRepository();
      await pumpRouted(
        tester,
        _today,
        overrides: _overrides(band: AgeBand.b1_3, repo: repo, media: [photo]),
      );
      await tester.pumpAndSettle();
      expect(repo.saves, hasLength(1));
      expect(repo.saves.single.bandApplied, AgeBand.b1_3);
      expect(repo.saves.single.goals, presetGoals[AgeBand.b1_3]);
    },
  );

  group('AX14 Tuỳ chỉnh Hôm nay', () {
    Future<FakeExperienceRepository> open(WidgetTester tester) async {
      final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b3_6));
      await pumpRouted(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.push(AdaptiveRoutes.customize),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: _overrides(band: AgeBand.b3_6, repo: repo, media: [photo]),
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push(AdaptiveRoutes.customize),
                  child: const Text('open'),
                ),
              ),
            ),
            ...adaptiveRoutes(),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    // D-115: rows are titles only; the ranking reasons are gone.
    testWidgets('shows the goals, the instruction and the hidden rows', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Tuỳ chỉnh Hôm nay'), findsOneWidget);
      expect(find.text('Lưu giữ kỷ niệm'), findsOneWidget);
      expect(
        find.text('Kéo để đổi thứ tự. Ghim để luôn ở đầu.'),
        findsOneWidget,
      );
      expect(find.textContaining('Theo mục tiêu'), findsNothing);
      await _scrollTo(tester, find.byKey(const Key('axHidden')));
      expect(find.textContaining('Ẩn theo gợi ý tuổi'), findsNothing);
    });

    testWidgets('pin and hide are kept only on "Xong"', (tester) async {
      final repo = await open(tester);
      await tester.tap(find.bySemanticsLabel('Ghim Nhắc nhở'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bỏ ghim Nhắc nhở'), findsOneWidget);
      expect(repo.saves, isEmpty);
      await tester.tap(find.byKey(const Key('axDone')));
      await tester.pumpAndSettle();
      expect(repo.stored!.pinned, [WidgetId.reminders]);
    });

    testWidgets('a long press anywhere on a row reorders (owner, 2026-10-24)', (
      tester,
    ) async {
      final repo = await open(tester);
      final first = find.text('Lưu khoảnh khắc hôm nay');
      final third = find.text('Chi tiêu tháng này');
      final dy = tester.getCenter(third).dy - tester.getCenter(first).dy;
      final gesture = await tester.startGesture(tester.getCenter(first));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, (dy + 30) / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('axDone')));
      await tester.pumpAndSettle();
      final order = repo.stored!.order;
      expect(order.indexOf(WidgetId.momentToday), greaterThan(0));
      expect(
        order.indexOf(WidgetId.spending),
        lessThan(order.indexOf(WidgetId.momentToday)),
      );
    });

    testWidgets('"Sửa" edits the goals; an added goal shows its widget', (
      tester,
    ) async {
      final repo = await open(tester);
      await tester.tap(find.byKey(const Key('axGoalsEdit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn muốn Child Life giúp gì cho Teddy?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('goal_growth_vaccines')));
      await tester.tap(find.byKey(const Key('axGoalsDone')));
      await tester.pumpAndSettle();
      expect(find.text('Tăng trưởng & tiêm chủng'), findsOneWidget);
      await tester.tap(find.byKey(const Key('axDone')));
      await tester.pumpAndSettle();
      expect(repo.stored!.goals, contains(Goal.growthVaccines));
      expect(repo.stored!.goalsSource, GoalsSource.chosen);
    });
  });

  group('D-108 Version A', () {
    testWidgets('loading: care tiles are skeletons, never "Chưa có"', (
      tester,
    ) async {
      final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b0_1));
      await pumpRouted(
        tester,
        // The day's records never arrive.
        ProviderScope(
          overrides: [
            recentRecordsProvider.overrideWith(
              (ref, id) => const Stream<List<CareRecord>>.empty(),
            ),
          ],
          child: _today,
        ),
        overrides: _overrides(band: AgeBand.b0_1, repo: repo, media: [photo]),
      );
      // The skeleton shimmers, so no pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ClSkeleton), findsNWidgets(4));
      expect(find.text('Bú bình'), findsNothing);
      expect(find.text('Chưa có'), findsNothing);
    });

    testWidgets('no nickname yet: a nameless greeting', (tester) async {
      final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b3_6));
      final nameless = Baby(
        id: teddy.id,
        familyId: teddy.familyId,
        ownerUid: teddy.ownerUid,
        nickname: '',
        avatar: teddy.avatar,
        trackers: teddy.trackers,
        timeZone: teddy.timeZone,
      );
      await pumpRouted(
        tester,
        ProviderScope(
          overrides: [
            babyProvider.overrideWith((ref, id) => Stream.value(nameless)),
          ],
          child: _today,
        ),
        overrides: _overrides(band: AgeBand.b3_6, repo: repo, media: [photo]),
      );
      await tester.pumpAndSettle();
      final greeting = tester.widget<Text>(find.byKey(const Key('axGreeting')));
      // The fixtures' clock is 10:00 in the baby's zone.
      expect(greeting.data, 'Chào ngày mới');
    });

    testWidgets('Nhắc việc, empty: the existing keys, a tinted first step', (
      tester,
    ) async {
      final repo = FakeExperienceRepository(Experience.defaults(AgeBand.b0_1));
      await pumpRouted(
        tester,
        _today,
        overrides: _overrides(band: AgeBand.b0_1, repo: repo, media: [photo]),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.byKey(const Key('axReminders')));
      final card = find.byKey(const Key('axReminders'));
      expect(
        find.descendant(of: card, matching: find.text('Nhắc việc')),
        findsOneWidget,
      );
      // Nothing behind "Xem tất cả" yet; the rows themselves are in the AX goldens.
      expect(
        find.descendant(of: card, matching: find.text('Xem tất cả')),
        findsNothing,
      );
      final first = tester.widget<ClButton>(
        find.descendant(of: card, matching: find.byType(ClButton)),
      );
      expect(first.label, 'Tạo nhắc nhở đầu tiên');
      expect(first.style, ClButtonStyle.tinted);
    });
  });
}
