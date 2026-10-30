import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/care/timer_screens.dart';
import 'package:child_life/features/home/today_tour.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Ba's sleep timer from 21:42 the night before; Mẹ's breastfeed from 15:02.
CareTimer sleepTimer({bool pending = false}) => CareTimer(
  babyId: teddyId,
  type: TimerType.sleep,
  sessionId: 'a' * 32,
  startedAt: careNow.subtract(
    const Duration(hours: 1, minutes: 27, seconds: 6),
  ),
  startedBy: minh.uid,
  author: CareAuthor.of(minh),
  pending: pending,
);

CareTimer breastTimer() => CareTimer(
  babyId: teddyId,
  type: TimerType.breast,
  sessionId: 'b' * 32,
  startedAt: careNow.subtract(const Duration(minutes: 12)),
  startedBy: mai.uid,
  author: CareAuthor.of(mai),
  left: const TimerSide(accumulatedMs: 8 * 60000 + 12000),
  right: TimerSide(
    accumulatedMs: 0,
    runningSince: careNow.subtract(const Duration(minutes: 3, seconds: 40)),
  ),
);

CareTimer pumpTimer() => CareTimer(
  babyId: teddyId,
  type: TimerType.pump,
  sessionId: 'c' * 32,
  startedAt: careNow.subtract(const Duration(minutes: 12, seconds: 30)),
  startedBy: mai.uid,
  author: CareAuthor.of(mai),
  left: TimerSide(
    runningSince: careNow.subtract(const Duration(minutes: 12, seconds: 30)),
  ),
  right: TimerSide(
    runningSince: careNow.subtract(const Duration(minutes: 12, seconds: 30)),
  ),
);

void main() {
  group('timer arithmetic (R-072)', () {
    final t0 = DateTime(2026, 10, 8, 15);
    DateTime at(int s) => t0.add(Duration(seconds: s));

    test(
      'breastfeeding: one side at a time, total = sum, record carries sides',
      () {
        var t = CareTimer.start(type: TimerType.breast, me: mai, now: t0);
        expect(t.activeSide, Side.left);
        t = t.switchTo(Side.right, at(8 * 60));
        expect(
          t.sideOf(Side.left).elapsedAt(at(10 * 60)),
          const Duration(minutes: 8),
        );
        expect(t.totalAt(at(12 * 60)), const Duration(minutes: 12));
        t = t.pauseAt(at(12 * 60));
        expect(
          t.totalAt(at(20 * 60)),
          const Duration(minutes: 12),
          reason: 'paused',
        );
        t = t.resumeAt(at(20 * 60));
        expect(t.activeSide, Side.right);
        final r = t.toRecord(at(21 * 60));
        expect(r.id, 'r_${t.sessionId}');
        expect(r.side, Side.both);
        expect(r.durationMin, 13);
        expect(r.leftMin, 8);
        expect(r.rightMin, 5);
        expect(r.endSide, Side.right);
        expect(r.dataJson(), containsPair('endSide', 'right'));
      },
    );

    test('double pumping: total is the wall clock, sides stop separately', () {
      var t = CareTimer.start(
        type: TimerType.pump,
        me: mai,
        now: t0,
        side: Side.both,
      );
      expect(
        t.sideOf(Side.left).running && t.sideOf(Side.right).running,
        isTrue,
      );
      t = t.toggle(Side.left, at(10 * 60));
      expect(t.totalAt(at(15 * 60)), const Duration(minutes: 15));
      expect(
        t.sideOf(Side.left).elapsedAt(at(15 * 60)),
        const Duration(minutes: 10),
      );
    });

    test('a sleep record spans start → end', () {
      final t = CareTimer.start(type: TimerType.sleep, me: minh, now: t0);
      final r = t.toRecord(at(3600));
      expect(r.type, CareType.sleep);
      expect(r.endedAt, at(3600));
      expect(r.dataJson(), isEmpty);
    });

    test(
      'a shared timer is written by whoever ends it; a sleep stops at 24 h',
      () {
        final t = CareTimer.start(type: TimerType.sleep, me: minh, now: t0);
        final r = t.toRecord(
          at(30 * 3600),
          by: (uid: mai.uid, author: CareAuthor.of(mai)),
        );
        expect(r.createdBy, mai.uid);
        expect(r.author.name, CareAuthor.of(mai).name);
        expect(r.endedAt, t0.add(const Duration(hours: 24)));
      },
    );

    test('the document matches the Rules shape', () {
      final t = CareTimer.start(type: TimerType.breast, me: mai, now: t0);
      expect(t.toJson('u_mai').keys.toSet(), {
        'type',
        'babyId',
        'sessionId',
        'startedAt',
        'startedBy',
        'author',
        'sides',
        'paused',
        'pausedSides',
        'updatedAt',
        'updatedBy',
      });
      expect(t.sessionId, matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(t.toUpdateJson('u_mai').keys.toSet(), {
        'startedAt',
        'sides',
        'paused',
        'pausedSides',
        'updatedAt',
        'updatedBy',
      });
    });
  });

  group('screens', () {
    testWidgets(
      '25: the family sees Ba\'s sleep; ending writes exactly one record',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          const TimerScreen(type: TimerType.sleep),
          overrides: careOverrides(
            repo: repo,
            timers: {TimerType.sleep: sleepTimer()},
          ),
        );
        expect(find.text('Bé Teddy đang ngủ'), findsOneWidget);
        expect(find.text('Cả nhà đang thấy'), findsOneWidget);
        expect(findTabular('01:27:06'), findsOneWidget);
        await tester.tap(find.text('Kết thúc giấc ngủ'));
        await tester.pumpAndSettle();
        final (timer, record) = repo.ended.single;
        expect(record.id, 'r_${'a' * 32}');
        expect(record.endedAt, careNow);
        expect(timer.type, TimerType.sleep);
      },
    );

    testWidgets('L6 "Dậy rồi": the sleep ends when the button was tapped', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      final tapped = careNow.subtract(const Duration(minutes: 4));
      final (visits, _) = await pumpRouted(
        tester,
        TimerScreen(
          type: TimerType.sleep,
          wakeSession: 'a' * 32,
          endAt: tapped,
        ),
        overrides: careOverrides(
          repo: repo,
          timers: {TimerType.sleep: sleepTimer()},
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.ended.single.$2.endedAt, tapped);
      expect(visits.single.location, '/today');
    });

    testWidgets('L6: a button for an earlier sleep only shows the timer', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        TimerScreen(
          type: TimerType.sleep,
          wakeSession: 'f' * 32,
          endAt: careNow,
        ),
        overrides: careOverrides(
          repo: repo,
          timers: {TimerType.sleep: sleepTimer()},
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.ended, isEmpty);
      expect(find.text('Kết thúc giấc ngủ'), findsOneWidget);
    });

    testWidgets('L6 "Dậy lúc…": the wake time first, then the sleep ends', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        TimerScreen(
          type: TimerType.sleep,
          wakeSession: 'a' * 32,
          pickEnd: true,
        ),
        overrides: careOverrides(
          repo: repo,
          timers: {TimerType.sleep: sleepTimer()},
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.ended, isEmpty);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(repo.ended.single.$2.endedAt, careNow);
    });

    testWidgets(
      'widget "Ngủ" on a cold start: the chooser\'s "Bấm giờ" opens the timer',
      (tester) async {
        // GlanceSync opens the chooser from the root navigator's own context, which has no
        // Overlay above it: taking a toaster there used to throw, and nothing happened.
        final repo = FakeCareRepository();
        late WidgetRef widgetRef;
        final (visits, _) = await pumpRouted(
          tester,
          Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
          overrides: careOverrides(repo: repo),
        );
        final navigator = GoRouter.of(
          tester.element(find.byType(Scaffold)),
        ).routerDelegate.navigatorKey.currentContext!;
        unawaited(showSleepChooser(navigator, widgetRef));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bắt đầu hẹn giờ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(repo.started, hasLength(1));
        expect(visits.last.location, '/care/timer/sleep');
      },
    );

    testWidgets(
      'opened alone from the Live Activity: back and end land on Hôm nay',
      (tester) async {
        // pumpRouted shows the screen as the only page, as a deep link leaves it.
        final repo = FakeCareRepository();
        final (visits, _) = await pumpRouted(
          tester,
          const TimerScreen(type: TimerType.sleep),
          overrides: careOverrides(
            repo: repo,
            timers: {TimerType.sleep: sleepTimer()},
          ),
        );
        await tester.tap(find.bySemanticsLabel('Quay lại'));
        await tester.pumpAndSettle();
        expect(visits.single.location, '/today');
      },
    );

    testWidgets(
      'ending a sleep opened alone from the Live Activity leaves for Hôm nay',
      (tester) async {
        final repo = FakeCareRepository();
        final (visits, _) = await pumpRouted(
          tester,
          const TimerScreen(type: TimerType.sleep),
          overrides: careOverrides(
            repo: repo,
            timers: {TimerType.sleep: sleepTimer()},
          ),
        );
        await tester.tap(find.text('Kết thúc giấc ngủ'));
        await tester.pumpAndSettle();
        expect(repo.ended, hasLength(1));
        expect(visits.single.location, '/today');
      },
    );

    testWidgets(
      'a widget tap after the timer ended elsewhere leaves for Hôm nay',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const TimerScreen(type: TimerType.sleep),
          overrides: careOverrides(repo: FakeCareRepository()),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(visits, isEmpty);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(visits.single.location, '/today');
      },
    );

    testWidgets(
      '9c: a timer not yet on the server says so; cancel asks first',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          const TimerScreen(type: TimerType.sleep),
          overrides: careOverrides(
            repo: repo,
            timers: {TimerType.sleep: sleepTimer(pending: true)},
          ),
        );
        expect(find.text('Chỉ trên máy này'), findsOneWidget);
        expect(find.text('Giấc ngủ này chưa được đồng bộ'), findsOneWidget);
        await tester.tap(find.text('Hủy, không lưu'));
        await tester.pumpAndSettle();
        expect(find.text('Hủy và không lưu?'), findsOneWidget);
        await tester.tap(find.text('Hủy, không lưu').last);
        await tester.pumpAndSettle();
        expect(repo.cancelled, hasLength(1));
      },
    );

    testWidgets('23b: tapping the other side switches; total is the sum', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        const TimerScreen(type: TimerType.breast),
        overrides: careOverrides(
          repo: repo,
          timers: {TimerType.breast: breastTimer()},
        ),
      );
      expect(findTabular('11:52'), findsOneWidget);
      expect(find.text('Đang bú'), findsOneWidget);
      await tester.tap(findTabular('08:12'));
      await tester.pump();
      expect(repo.updated.single.activeSide, Side.left);
    });

    testWidgets(
      '19: a running sleep makes its tile live; a finished one says how long awake',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: TodayScreen()),
          overrides: careOverrides(timers: {TimerType.sleep: sleepTimer()}),
        );
        expect(findTabular('01:27:06'), findsOneWidget);
        await tester.tap(findTabular('01:27:06'));
        await tester.pumpAndSettle();
        expect(visits.last.location, '/care/timer/sleep');
      },
    );

    testWidgets('19: after a nap the tile reads "Đã thức … · Dậy lúc …"', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(
          records: [
            rec(CareType.sleep, vn(8, 11, 45), minh, endedAt: vn(8, 13, 5)),
            ...mockDay(),
          ],
        ),
      );
      expect(find.text('Đã thức 2 giờ'), findsOneWidget);
      expect(find.text('Dậy lúc 13:05'), findsOneWidget);
    });

    testWidgets('19: a long "Đã thức …" wraps instead of ending in "…"', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(
          records: [
            rec(CareType.sleep, vn(8, 11, 0), minh, endedAt: vn(8, 12, 29)),
            ...mockDay(),
          ],
        ),
      );
      final value = find.textContaining('Đã thức');
      expect(value, findsOneWidget);
      final text = tester.widget<Text>(value);
      expect(text.data, contains('phút'));
      // Home cards grow with their content; all elapsed time remains readable.
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('26: the end must follow the start; a valid sleep saves', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        const ManualSleepScreen(),
        overrides: careOverrides(repo: repo),
      );
      expect(find.text('1 giờ'), findsOneWidget);
      await tester.tap(find.text('Lưu giấc ngủ'));
      await tester.pumpAndSettle();
      expect(repo.created.single.type, CareType.sleep);
      expect(
        repo.created.single.endedAt!.difference(repo.created.single.occurredAt),
        const Duration(hours: 1),
      );
    });

    testWidgets('27: the primary waits for a choice, then keeps it', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      final dads = rec(
        CareType.sleep,
        vn(7, 21, 40),
        minh,
        endedAt: vn(7, 23, 6),
      );
      final mine = rec(
        CareType.sleep,
        vn(7, 21, 42),
        mai,
        endedAt: vn(7, 23, 10),
        pending: true,
      );
      final conflict = SleepConflict(
        id: '${dads.id}__${mine.id}',
        recordIds: [dads.id, mine.id],
        laterAuthor: mai.uid,
      );
      await pumpRouted(
        tester,
        OverlapScreen(conflictId: conflict.id),
        overrides: careOverrides(
          repo: repo,
          conflicts: [conflict],
          byId: {dads.id: dads, mine.id: mine},
        ),
      );
      expect(find.text('Có hai giấc ngủ trùng nhau'), findsOneWidget);
      expect(findTabular('21:40 – 23:06'), findsOneWidget);
      expect(find.text('Chỉ trên máy này'), findsOneWidget);
      expect(find.text('Sửa tay từ bản của tôi'), findsOneWidget);
      await tester.tap(find.text('Giữ bản đã chọn'));
      await tester.pump();
      expect(repo.resolved, isEmpty);
      await tester.tap(findTabular('21:40 – 23:06'));
      await tester.pump();
      await tester.tap(find.text('Giữ bản đã chọn'));
      await tester.pumpAndSettle();
      expect(repo.resolved.single, (conflict.id, dads.id));
    });

    testWidgets('18–18c: three steps, then done', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 16,
                top: 200,
                width: 166,
                height: 150,
                child: SizedBox(key: TourTargets.bottle),
              ),
              Positioned(
                left: 193,
                top: 520,
                width: 166,
                height: 150,
                child: SizedBox(key: TourTargets.growth),
              ),
              Positioned(
                right: 16,
                bottom: 40,
                width: 68,
                height: 68,
                child: SizedBox(key: TourTargets.quickLog),
              ),
              const Positioned.fill(child: TodayTour(babyNickname: 'Teddy')),
            ],
          ),
        ),
        overrides: careOverrides(),
      );
      expect(find.text('Bước 1/3'), findsOneWidget);
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Theo dõi Teddy lớn lên'), findsOneWidget);
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi nhanh từ mọi nơi'), findsOneWidget);
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(container.read(todayTourDoneProvider), isTrue);
    });

    test('pump timer fixture is double pumping', () {
      expect(
        pumpTimer().totalAt(careNow),
        const Duration(minutes: 12, seconds: 30),
      );
    });
  });
}
