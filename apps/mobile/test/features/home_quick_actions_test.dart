import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/care/bottle_quick_memory.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

class _RejectingCareRepository extends FakeCareRepository {
  @override
  void create(CareRecord record, {void Function(Object)? onError}) {
    super.create(record, onError: onError);
    scheduleMicrotask(() => onError?.call(StateError('rejected')));
  }
}

void main() {
  Widget tile(CareType type, {bool readOnly = false, CareTimer? timer}) =>
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 193,
            height: 220,
            child: CareTile(
              type: type,
              quickActions: true,
              last: null,
              myUid: mai.uid,
              now: careNow,
              readOnly: readOnly,
              timer: timer,
              onTap: () {},
            ),
          ),
        ),
      );

  for (final amount in [60, 90]) {
    testWidgets(
      'bottle $amount logs immediately, stays on Home and supports Undo',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          tile(CareType.bottle),
          overrides: careOverrides(repo: repo, records: []),
        );
        await tester.tap(find.byKey(Key('care-bottle-$amount ml')));
        await tester.pumpAndSettle();
        expect(find.byType(FeedSheet), findsNothing);
        expect(repo.created.single.amountMl, amount);
        expect(repo.created.single.pending, isTrue);
        expect(find.byType(CareTile), findsOneWidget);
        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();
        expect(repo.deleted.single.id, repo.created.single.id);
      },
    );
  }
  for (final side in [Side.left, Side.right]) {
    testWidgets('breast $side starts a timer immediately', (tester) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        tile(CareType.breast),
        overrides: careOverrides(repo: repo),
      );
      await tester.tap(
        find.byKey(
          Key('care-breast-${side == Side.left ? 'Bên trái' : 'Bên phải'}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FeedSheet), findsNothing);
      expect(repo.created, isEmpty);
      expect(repo.started.single.type, TimerType.breast);
      expect(repo.started.single.activeSide, side);
    });
  }
  for (final kind in DiaperKind.values) {
    testWidgets('diaper $kind logs immediately without a sheet', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        tile(CareType.diaper),
        overrides: careOverrides(repo: repo),
      );
      final label = switch (kind) {
        DiaperKind.wet => 'Ướt',
        DiaperKind.dirty => 'Bẩn',
        DiaperKind.both => 'Cả hai',
      };
      await tester.tap(find.byKey(Key('care-diaper-$label')));
      await tester.pumpAndSettle();
      expect(find.byType(DiaperSheet), findsNothing);
      expect(repo.created.single.diaper, kind);
      expect(find.byType(CareTile), findsOneWidget);
    });
  }
  test(
    'two age-based defaults, then recent distinct inputs without duplicates',
    () {
      expect(homeBottlePicks(ageDays: 2, remembered: [], recent: []), [30, 45]);
      expect(homeBottlePicks(ageDays: 35, remembered: [], recent: []), [
        90,
        120,
      ]);
      expect(
        homeBottlePicks(ageDays: 35, remembered: [105], recent: [105, 80, 105]),
        [105, 80],
      );
      expect(homeBottlePicks(ageDays: 35, remembered: [-1, 900], recent: []), [
        90,
        120,
      ]);
      expect(homeBottlePicks(ageDays: null, remembered: [], recent: []), [
        60,
        90,
      ]);
    },
  );
  testWidgets(
    'custom amount is remembered on Save, survives restart and appears as direct action',
    (tester) async {
      final repo = FakeCareRepository();
      final (_, container) = await pumpRouted(
        tester,
        Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => openCareLog(context, CareType.bottle),
                  child: const Text('open'),
                ),
              ),
              SizedBox(width: 193, height: 220, child: tile(CareType.bottle)),
            ],
          ),
        ),
        overrides: careOverrides(repo: repo),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '105');
      await tester.tap(find.text('Lưu cữ bú'));
      await tester.pumpAndSettle();
      expect(container.read(bottleQuickMemoryProvider), [105]);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getStringList(BottleQuickMemory.keyFor(mai.uid, teddyId)),
        ['105'],
      );
      container.invalidate(bottleQuickMemoryProvider);
      expect(container.read(bottleQuickMemoryProvider), [105]);
      await tester.tap(find.byKey(const Key('care-bottle-105 ml')));
      await tester.pumpAndSettle();
      expect(repo.created, hasLength(2));
      expect(repo.created.last.amountMl, 105);
      expect(find.byType(FeedSheet), findsNothing);
    },
  );
  testWidgets('inline save never pops a pushed Home route', (tester) async {
    final repo = FakeCareRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/home'),
              child: const Text('open home'),
            ),
          ),
        ),
        GoRoute(path: '/home', builder: (_, _) => tile(CareType.diaper)),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouted(
      tester,
      const SizedBox(),
      router: router,
      overrides: careOverrides(repo: repo),
    );
    await tester.tap(find.text('open home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('care-diaper-Ướt')));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    expect(find.byType(CareTile), findsOneWidget);
    expect(find.text('open home'), findsNothing);
    expect(repo.created, hasLength(1));
  });
  testWidgets(
    'failed write removes optimistic value and allows immediate retry',
    (tester) async {
      final repo = _RejectingCareRepository();
      await pumpRouted(
        tester,
        tile(CareType.diaper),
        overrides: careOverrides(repo: repo),
      );
      final action = find.byKey(const Key('care-diaper-Ướt'));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Chờ đồng bộ'), findsNothing);
      expect(find.textContaining('Chưa lưu được'), findsWidgets);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(repo.created, hasLength(2));
    },
  );
  testWidgets('rapid duplicate taps create only one diaper record', (
    tester,
  ) async {
    final repo = FakeCareRepository();
    await pumpRouted(
      tester,
      tile(CareType.diaper),
      overrides: careOverrides(repo: repo),
    );
    final action = find.byKey(const Key('care-diaper-Ướt'));
    await tester.tap(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(repo.created, hasLength(1));
  });
  testWidgets('offline direct log remains queued and can be undone', (
    tester,
  ) async {
    final repo = FakeCareRepository();
    await pumpRouted(
      tester,
      tile(CareType.diaper),
      overrides: careOverrides(repo: repo, online: false),
    );
    await tester.tap(find.byKey(const Key('care-diaper-Cả hai')));
    await tester.pumpAndSettle();
    expect(repo.created.single.pending, isTrue);
    expect(find.text('Chờ đồng bộ'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(repo.deleted.single.id, repo.created.single.id);
  });
  testWidgets('read-only care cards expose no write presets', (tester) async {
    await pumpRouted(
      tester,
      tile(CareType.bottle, readOnly: true),
      overrides: careOverrides(me: hoa),
    );
    expect(find.byKey(const Key('care-bottle-60 ml')), findsNothing);
    expect(find.byType(FeedSheet), findsNothing);
  });
  testWidgets(
    'running breast timer replaces side presets with current session',
    (tester) async {
      var opens = 0;
      final timer = CareTimer.start(
        type: TimerType.breast,
        me: mai,
        now: careNow,
      );
      await pumpRouted(
        tester,
        Scaffold(
          body: SizedBox(
            width: 193,
            height: 220,
            child: CareTile(
              type: CareType.breast,
              quickActions: true,
              last: null,
              myUid: mai.uid,
              now: careNow,
              timer: timer,
              onTap: () => opens++,
            ),
          ),
        ),
        overrides: careOverrides(),
      );
      expect(find.byKey(const Key('care-breast-Bên trái')), findsNothing);
      await tester.tap(
        find.byKey(const Key('care-breast-Xem phiên đang chạy')),
      );
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(find.byType(FeedSheet), findsNothing);
    },
  );
  testWidgets('start sleep uses existing timer flow', (tester) async {
    final repo = FakeCareRepository();
    final (visits, _) = await pumpRouted(
      tester,
      tile(CareType.sleep),
      overrides: careOverrides(repo: repo),
    );
    await tester.tap(find.byKey(const Key('care-sleep-Bắt đầu ngủ')));
    await tester.pumpAndSettle();
    expect(repo.started.single.type, TimerType.sleep);
    expect(visits.last.location, '${Routes.timer}/sleep');
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'greeting is capped at three lines with reachable duty, scale=$scale',
      (tester) async {
        await pumpRouted(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: LivingHeaderView(
                moment: HeaderMoment.afternoon,
                title:
                    'Một ngày của\nbé Minh Khôi\nthế nào rồi?\nMột dòng thừa',
                top: const SizedBox(height: 44),
                duty: const SizedBox(
                  key: Key('duty'),
                  height: 44,
                  child: Text('Ba và Mẹ đang trông'),
                ),
              ),
            ),
          ),
          textScaler: TextScaler.linear(scale),
        );
        final title = find.byKey(const Key('axGreeting'));
        expect(tester.widget<Text>(title).maxLines, 3);
        expect(
          tester.getTopLeft(find.byKey(const Key('duty'))).dy -
              tester.getBottomLeft(title).dy,
          12,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
