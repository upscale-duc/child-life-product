import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/lumi_button.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// Hôm nay's bottom edge (owner, 2026-10-15: Lumi sat on "Xem tất cả" of Nhắc việc): the shell
/// tells a tab how much the dock, its "+", Lumi and the upload pill cover, and Hôm nay's list
/// ends that far up (plus 16), so its last item is never under them.

/// What the Today stub read from the shell.
double? _seen;

GoRouter _todayShell() => GoRouter(
  initialLocation: Routes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.family,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: root,
                builder: (_, _) => Scaffold(
                  body: Builder(
                    builder: (context) {
                      _seen = HomeFloatingClearance.of(context);
                      return Text('tab $root');
                    },
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  ],
);

QueueBatch _waitingBatch() => QueueBatch(
  batchId: 'bat_${'e' * 32}',
  babyId: teddyId,
  memoryId: 'mem_${'e' * 32}',
  request: const {'audience': 'family', 'notifyFamily': true},
  createdAt: DateTime(2026, 10, 8),
  sessionCreated: true,
  items: [
    QueueItem(
      mediaId: 'med_${'1' * 32}',
      type: MediaKind.photo,
      name: 'IMG_1.HEIC',
      localPath: '/nope/IMG_1.HEIC',
      contentType: 'image/jpeg',
      bytes: 3400000,
      captureAt: DateTime(2026, 10, 8),
      state: QueueState.paused,
    ),
  ],
);

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    bool uploads = false,
    bool lumi = true,
  }) async {
    _seen = null;
    await pumpRouted(
      tester,
      const SizedBox(),
      router: _todayShell(),
      prefs: {LumiIntroSeenNotifier.keyFor(mai.uid): true},
      overrides: [
        ...careOverrides(),
        ...memoryOverrides(
          network: NetworkKind.none,
          store: MemoryQueueStore()..saved = [if (uploads) _waitingBatch()],
        ),
        if (lumi)
          assistantAccessProvider.overrideWith(
            (ref, babyId) => const AssistantAccess(),
          ),
      ],
    );
    await tester.pumpAndSettle();
  }

  double screenHeight(WidgetTester tester) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  testWidgets('the shell reports up to Lumi\'s top', (tester) async {
    await pumpShell(tester);
    final lumi = tester.getRect(find.byType(AsFloatingButton));
    expect(_seen, moreOrLessEquals(screenHeight(tester) - lumi.top));
  });

  testWidgets('with uploads waiting, up to Lumi above the pill', (
    tester,
  ) async {
    await pumpShell(tester, uploads: true);
    final lumi = tester.getRect(find.byType(AsFloatingButton));
    expect(_seen, moreOrLessEquals(screenHeight(tester) - lumi.top));
  });

  testWidgets('without Lumi, up to the "+"', (tester) async {
    await pumpShell(tester, lumi: false);
    expect(find.byType(AsFloatingButton), findsNothing);
    final plus = tester.getRect(find.byType(ClQuickLogButton));
    expect(_seen, moreOrLessEquals(screenHeight(tester) - plus.top));
  });

  testWidgets('Hôm nay ends 16 above what the shell covers', (tester) async {
    await pumpRouted(
      tester,
      HomeFloatingClearance(
        notifier: ValueNotifier(262),
        child: const Scaffold(body: TodayScreen()),
      ),
      overrides: careOverrides(),
    );
    final list = tester.widget<ListView>(
      find
          .descendant(
            of: find.byType(TodayScreen),
            matching: find.byType(ListView),
          )
          .first,
    );
    expect((list.padding! as EdgeInsets).bottom, 262 + 16);
  });

  testWidgets('outside the shell the old 140 stays', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: TodayScreen()),
      overrides: careOverrides(),
    );
    final list = tester.widget<ListView>(
      find
          .descendant(
            of: find.byType(TodayScreen),
            matching: find.byType(ListView),
          )
          .first,
    );
    expect((list.padding! as EdgeInsets).bottom, 140);
  });
}
