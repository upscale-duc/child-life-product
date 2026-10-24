import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// The real tab shell with Kỷ niệm on its branch and stubs on the others, under a MediaQuery
/// the test can change (the keyboard opening on another tab).
GoRouter _shellRouter(ValueNotifier<MediaQueryData> media) => GoRouter(
  initialLocation: Routes.memories,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => ValueListenableBuilder(
        valueListenable: media,
        builder: (_, data, _) => MediaQuery(
          data: data,
          child: HomeShell(shell: shell),
        ),
      ),
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
                pageBuilder: (_, s) => MaterialPage<void>(
                  key: s.pageKey,
                  child: root == Routes.memories
                      ? const MemoriesScreen()
                      : Scaffold(body: Text('tab $root')),
                ),
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  testWidgets('Kỷ niệm does no build work while another tab shows', (
    tester,
  ) async {
    final media = ValueNotifier(
      const MediaQueryData(
        size: Size(375, 812),
        disableAnimations: true,
        padding: EdgeInsets.only(bottom: 34),
      ),
    );
    addTearDown(media.dispose);
    final router = _shellRouter(media);
    final (_, container) = await pumpRouted(
      tester,
      const SizedBox(),
      overrides: [...careOverrides(), ...memoryOverrides()],
      router: router,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotosView), findsOneWidget);

    // Every build in the Kỷ niệm subtree (dirty or pushed down by a parent), below the freeze
    // and the MediaQuery it hands down.
    final builds = <Widget>[];
    debugOnRebuildDirtyWidget = (e, _) {
      if (e.widget is! MediaQuery &&
          e.findAncestorWidgetOfExactType<ClHiddenTabFreeze>() != null) {
        builds.add(e.widget);
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    router.go(Routes.care);
    await tester.pumpAndSettle();
    builds.clear();

    // What other tabs change: the minute clock, the baby, Hôm nay's records, and the bottom
    // padding when a keyboard opens.
    container
      ..invalidate(careClockProvider)
      ..invalidate(babyProvider(teddyId))
      ..invalidate(recentRecordsProvider(teddyId));
    await tester.pumpAndSettle();
    media.value = media.value.copyWith(
      padding: EdgeInsets.zero,
      viewInsets: const EdgeInsets.only(bottom: 300),
    );
    await tester.pumpAndSettle();
    expect(builds, isEmpty);
    final photos = find.byType(PhotosView, skipOffstage: false);
    expect(
      MediaQuery.paddingOf(tester.element(photos)).bottom,
      34,
      reason: 'hidden, it keeps what it last showed with',
    );

    // Shown again, it catches up.
    router.go(Routes.memories);
    await tester.pumpAndSettle();
    expect(builds.whereType<PhotosView>(), isNotEmpty);
    expect(MediaQuery.paddingOf(tester.element(photos)).bottom, 0);
  });
}
