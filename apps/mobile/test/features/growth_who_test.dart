import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/growth_standards_screen.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// v1.0 improvement · growth: 20i WHO table and the WHO comparison on 20d (Teddy is a boy born
/// 17 Sep; "now" is 8 Oct; his latest weight is 3.9 kg at two weeks).
void main() {
  group('20i Tiêu chuẩn tăng trưởng', () {
    testWidgets('boys by week, with Teddy\'s row marked', (tester) async {
      await pumpRouted(
        tester,
        const GrowthStandardsScreen(),
        overrides: careOverrides(growth: mockGrowth()),
      );
      expect(find.text('Tiêu chuẩn tăng trưởng'), findsOneWidget);
      // WHO 3rd / 50th / 97th percentiles at birth (boys).
      expect(find.text('Mới sinh'), findsOneWidget);
      expect(find.text('2,5'), findsWidgets);
      expect(find.text('3,3'), findsWidgets);
      expect(find.text('4,3'), findsWidgets);
      expect(find.text('Teddy 3,9 kg · Bình thường'), findsOneWidget);
    });

    testWidgets('girls hide Teddy; months and length switch the table', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const GrowthStandardsScreen(),
        overrides: careOverrides(growth: mockGrowth()),
      );
      await tester.tap(find.text('Bé gái'));
      await tester.pumpAndSettle();
      expect(find.text('Teddy 3,9 kg · Bình thường'), findsNothing);
      expect(find.text('3,2'), findsWidgets); // girls' median at birth

      await tester.tap(find.text('Bé trai'));
      await tester.tap(find.text('Chiều dài'));
      await tester.pumpAndSettle();
      expect(find.text('Teddy 53 cm · Bình thường'), findsOneWidget);
      expect(find.text('49,9'), findsWidgets); // boys' length median at birth

      await tester.tap(find.text('Theo tháng'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('12 tháng'), 300);
      expect(
        find.text('75,7'),
        findsOneWidget,
      ); // boys' length median at 1 year
    });
  });

  group('20d Tăng trưởng · WHO', () {
    testWidgets('within the band: Bình thường and the way to 20i', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.growth),
        overrides: careOverrides(growth: mockGrowth()),
      );
      expect(find.text('Bình thường'), findsOneWidget);
      expect(find.text('2 tuần tuổi', findRichText: true), findsNothing);
      expect(find.textContaining('2 tuần tuổi'), findsOneWidget);
      await tester.tap(find.text('Xem tiêu chuẩn tăng trưởng WHO'));
      await tester.pumpAndSettle();
      expect(find.byType(GrowthStandardsScreen), findsOneWidget);
    });

    testWidgets('below the band (347:935): pill, lower edge and a note', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HistoryScreen(filter: HistoryFilter.growth),
        overrides: careOverrides(
          growth: [
            rec(
              CareType.growth,
              vn(1, 12, 0),
              mai,
              weightKg: 2.6,
              measuredOn: DateTime(2026, 10, 1),
            ),
          ],
        ),
      );
      expect(find.text('Dưới mức tham chiếu'), findsOneWidget);
      expect(find.text('Ngưỡng dưới 2,8 kg'), findsOneWidget);
      expect(
        find.textContaining('Cân nặng của Teddy đang thấp hơn'),
        findsOneWidget,
      );
    });
  });
}
