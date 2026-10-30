import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/explore_screen.dart';
import 'package:child_life/features/adaptive/today_adaptive.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/me/me_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/hn_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// NavBar v2 · Adaptive (917:3012, P-178): tabs by role, Lumi at the end outside the tab bar
/// (owner, 2026-10-24), Khám phá (AX20 / AX21 / AX45), Hồ sơ (AX34).
void main() {
  setUpAll(ensureTimeZones);

  group('tabs', () {
    test('v2 by role (AX00, AX32 note)', () {
      expect(tabsForRoleV2(ClRole.parent), [
        ClTab.today,
        ClTab.memories,
        ClTab.explore,
        ClTab.profile,
      ]);
      expect(tabsForRoleV2(ClRole.caregiver), [
        ClTab.today,
        ClTab.explore,
        ClTab.profile,
      ]);
      expect(tabsForRoleV2(ClRole.relative), [ClTab.memories, ClTab.profile]);
      // D-018: daily care keeps a relative's read-only Hôm nay.
      expect(
        tabsForRoleV2(ClRole.relative, relativeSeesToday: true),
        contains(ClTab.today),
      );
    });

    test(
      'Chăm sóc and Tiện ích light Khám phá with v2, themselves without',
      () {
        expect(dockTabOf(ClTab.care, v2: true), ClTab.explore);
        expect(dockTabOf(ClTab.utilities, v2: true), ClTab.explore);
        expect(dockTabOf(ClTab.care, v2: false), ClTab.care);
        expect(dockTabOf(ClTab.memories, v2: true), ClTab.memories);
      },
    );

    test('the shell keeps every v1 branch, so their paths still open', () {
      expect(shellTabs.take(4), [
        ClTab.today,
        ClTab.memories,
        ClTab.care,
        ClTab.utilities,
      ]);
      expect(shellTabs, containsAll([ClTab.explore, ClTab.profile]));
    });
  });

  testWidgets('Lumi sits at the end of the dock, outside the tab bar', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ClTabDock(
            role: ClRole.parent,
            tabs: tabsForRoleV2(ClRole.parent),
            active: ClTab.explore,
            onSelect: (_) {},
            trailing: const SizedBox(key: Key('lumi'), width: 64, height: 64),
          ),
        ),
      ),
    );
    final bar = tester.getRect(find.byType(ClNavBar));
    final lumi = tester.getRect(find.byKey(const Key('lumi')));
    expect(lumi.left, greaterThan(bar.right));
    expect(lumi.center.dy, closeTo(bar.center.dy, 1));
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });

  group('Khám phá', () {
    Future<void> pump(WidgetTester tester, AgeBand band) => pumpRouted(
      tester,
      const Scaffold(body: ExploreScreen()),
      overrides: [
        ...hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
        ...adaptiveOverrides(
          band: band,
          repo: FakeExperienceRepository(Experience.defaults(band)),
        ),
      ],
    );

    testWidgets('0–1: care first in "Gợi ý cho Teddy lúc này" (AX20)', (
      tester,
    ) async {
      await pump(tester, AgeBand.b0_1);
      // D-139: Khám phá holds Chăm sóc; at 0–1 its daily care comes first (every suggestion is
      // one of its rows, so no separate "Gợi ý" group repeats them).
      expect(find.text('Gợi ý cho Teddy lúc này'), findsNothing);
      expect(find.text('Chăm hằng ngày'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Lịch sử')).dy,
        lessThan(tester.getTopLeft(find.text('Tiêm chủng')).dy),
      );
      expect(
        find.text('Tìm tính năng, ví dụ: tiêm, chi tiêu, sơ cứu'),
        findsOneWidget,
      );
    });

    testWidgets(
      '3–6: memories first; baby tools move down, never away (AX21)',
      (tester) async {
        await pump(tester, AgeBand.b3_6);
        double y(String k) => tester.getTopLeft(find.byKey(ValueKey(k))).dy;
        expect(y('explore_memories'), lessThan(y('explore_spending')));
        // The Chăm sóc rows follow, inline (D-139).
        await tester.scrollUntilVisible(
          find.text('Tiêm chủng'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Tiêm chủng'), findsOneWidget);
        expect(find.text('Giữ trẻ & học, quần áo…'), findsOneWidget);
      },
    );

    testWidgets('search ignores marks; nothing found is honest (AX45)', (
      tester,
    ) async {
      await pump(tester, AgeBand.b3_6);
      await tester.enterText(find.byKey(const Key('exploreSearch')), 'tiem');
      await tester.pumpAndSettle();
      expect(find.text('Tiêm chủng'), findsOneWidget);
      expect(find.byKey(const ValueKey('explore_spending')), findsNothing);

      await tester.enterText(find.byKey(const Key('exploreSearch')), 'học tập');
      await tester.pumpAndSettle();
      expect(find.text('Chưa có tính năng “học tập”'), findsOneWidget);
      expect(find.text('Lưu vào Kỷ niệm'), findsOneWidget);
      await tester.tap(find.byKey(const Key('exploreNotify')));
      await tester.pumpAndSettle();
      expect(find.text('Đã ghi nhận'), findsOneWidget);
    });

    testWidgets('"Cùng con lớn lên" is a card, never a feature row', (
      tester,
    ) async {
      await pump(tester, AgeBand.b0_1);
      await tester.scrollUntilVisible(
        find.byKey(const Key('exploreGrowing')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đang phát triển · chưa có trong app'), findsOneWidget);
    });
  });

  testWidgets('Hồ sơ: no back, "Các bé" opens that child\'s Tuỳ chỉnh (AX34)', (
    tester,
  ) async {
    final (visits, container) = await pumpRouted(
      tester,
      const MeScreen(asTab: true),
      overrides: [
        ...familyOverrides(email: 'mai@gmail.com', providers: ['password']),
        ...memoryOverrides(),
        ...meOverrides(),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ'), findsWidgets);
    expect(find.bySemanticsLabel('Quay lại'), findsNothing);
    expect(find.text('Các bé'), findsOneWidget);
    // Every Tôi row stays (D-097 Q-090).
    await tester.scrollUntilVisible(
      find.text('Đăng xuất'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đăng xuất'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profileChild_$teddyId')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('profileChild_$teddyId')));
    await tester.pumpAndSettle();
    expect(visits.last.location, AdaptiveRoutes.customize);
    expect(container.read(selectedBabyIdProvider), teddyId);
    expect(Routes.profile, '/profile');
  });
}
