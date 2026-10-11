import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/reminders/reminder_screens.dart'
    show ReminderPeek;
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// v1.0 improvement · NavBar v1.0.1: the Chăm sóc tab (370:1971 / 370:2174), "Tôi" from the
/// header avatar (370:1898) and "Tuỳ chỉnh Hôm nay" (370:1525).
void main() {
  group('Chăm sóc', () {
    testWidgets('parent: daily care, teasers and settings', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      expect(find.text('Chăm sóc'), findsWidgets);
      for (final t in ['Nhắc nhở', 'Thống kê', 'Lịch sử', 'Tăng trưởng']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.history);
    });

    testWidgets('Tăng trưởng opens History on growth', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Tăng trưởng'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.history}?filter=growth');
    });

    testWidgets('Thống kê asks which statistics', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(find.text('Xem thống kê'), findsOneWidget);
      await tester.tap(find.text('Thống kê bú'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.feedStats);
    });

    testWidgets('coming-soon tiles only say so', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.ensureVisible(find.text('Wonder Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wonder Week'));
      await tester.pump();
      expect(
        find.text('Phần này sẽ có trong bản cập nhật tới.'),
        findsOneWidget,
      );
      expect(visits, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('caregiver: no Tăng trưởng (370:2174)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(me: lan),
      );
      expect(find.text('Nhắc nhở'), findsOneWidget);
      expect(find.text('Tăng trưởng'), findsNothing);
    });

    testWidgets('search filters tiles and rows', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      await tester.enterText(find.byType(TextField), 'lịch');
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử'), findsOneWidget);
      expect(find.text('Nhắc nhở'), findsNothing);
      expect(find.text('Wonder Week'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Không có mục nào khớp.'), findsOneWidget);
    });
  });

  group('Tôi from the avatar', () {
    testWidgets('the header avatar opens Tôi', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.me);
    });
  });

  group('Tuỳ chỉnh Hôm nay', () {
    test('a saved layout survives unknown names and gains new sections', () {
      final layout = TodayLayout.fromJson({
        'order': ['rhythm', 'gone', 'tiles'],
        'hidden': ['reminders'],
        'hiddenTiles': ['pump', 'nope'],
      });
      expect(layout.order, [
        TodaySection.rhythm,
        TodaySection.tiles,
        TodaySection.reminders,
      ]);
      expect(layout.shows(TodaySection.reminders), isFalse);
      expect(layout.hiddenTiles, {TrackerKind.pump});
      expect(TodayLayout.fromJson(layout.toJson()).toJson(), layout.toJson());
    });

    testWidgets('hide a section and a tile; Xong keeps it, Đặt lại undoes', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      expect(find.byType(CareTile), findsNWidgets(4));
      expect(find.byType(ReminderPeek), findsOneWidget);

      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      expect(find.text('Tuỳ chỉnh Hôm nay'), findsOneWidget);
      expect(find.text('Ô theo dõi nhanh'), findsOneWidget);
      expect(find.text('Nhịp trong ngày'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Nhắc việc sắp tới'),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(ClToggle),
        ),
      );
      // The sheet's chip (the day's legend below also says Bú bình).
      final bottleChip = find
          .descendant(of: find.byType(Wrap), matching: find.text('Bú bình'))
          .last;
      await tester.ensureVisible(bottleChip);
      await tester.tap(bottleChip);
      // Nothing changes until Xong.
      await tester.pump();
      expect(find.byType(ReminderPeek), findsOneWidget);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPeek), findsNothing);
      expect(find.byType(CareTile), findsNWidgets(3));
      expect(container.read(todayLayoutProvider(teddyId)).hiddenTiles, {
        TrackerKind.bottle,
      });

      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại'));
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPeek), findsOneWidget);
      expect(find.byType(CareTile), findsNWidgets(4));
    });

    testWidgets('the saved order is per baby and read back', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
        prefs: {
          'today.layout.$teddyId':
              '{"order":["rhythm","reminders","tiles"],"hidden":[],"hiddenTiles":[]}',
        },
      );
      final rhythm = tester.getTopLeft(find.byType(DayRhythm)).dy;
      final peek = tester.getTopLeft(find.byType(ReminderPeek)).dy;
      expect(rhythm, lessThan(peek));
    });

    testWidgets('relatives see no Tuỳ chỉnh (read-only Today)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(me: hoa),
      );
      expect(find.text('Tuỳ chỉnh'), findsNothing);
    });
  });
}
