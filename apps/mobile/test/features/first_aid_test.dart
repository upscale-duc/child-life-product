import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/first_aid/first_aid_models.dart';
import 'package:child_life/features/first_aid/first_aid_modes.dart';
import 'package:child_life/features/first_aid/first_aid_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/router_pump.dart';

/// Sơ cứu trẻ em (Figma v1.1 7a–7i, TH01–TH24; D-058) with the real seed pack.
void main() {
  final pack = seedFirstAidPack();

  group('the pack', () {
    test('25 situations in 4 groups, every picture named', () {
      expect(pack.situations, hasLength(25));
      expect(pack.categories.map((c) => c.id), [
        'urgent',
        'wounds',
        'creatures',
        'health',
      ]);
      expect(pack.images.length, greaterThan(50));
      expect(pack.cprSituation?.id, 'cpr');
    });

    test(
      'newborn pages move down for an older baby; age variants pick the band',
      () {
        List<String> urgent(int m) => pack
            .ordered(m)
            .where((s) => s.category == 'urgent')
            .map((s) => s.id)
            .toList();
        expect(
          urgent(1).indexOf('apnoea'),
          lessThan(urgent(1).indexOf('traffic')),
        );
        expect(urgent(7).last, 'apnoea');
        final choking = pack.situation('choking')!;
        expect(choking.defaultVariant(7).id, 'under-1');
        expect(choking.defaultVariant(14).id, 'from-1');
        expect(choking.defaultVariant(null).id, 'under-1');
      },
    );

    test('search ignores diacritics and reads synonyms and the body', () {
      final hits = faSearch(pack, 'co giat do sot');
      expect(hits.first.situation.id, 'seizure');
      expect(faSearch(pack, 'bỏng').first.situation.id, 'scald');
      expect(
        faSearch(pack, 'nhiệt kế').map((h) => h.situation.id),
        contains('temperature'),
      );
      expect(faSearch(pack, '   '), isEmpty);
    });
  });

  testWidgets(
    '7a: Chăm sóc shows the red entry only once a guide is on the device',
    (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(),
      );
      expect(find.byKey(const Key('faEntry')), findsNothing);
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: careOverrides(firstAid: pack),
      );
      expect(find.text('Sơ cứu trẻ em'), findsOneWidget);
      expect(
        find.text('25 tình huống · dùng khi không có mạng'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('faEntry')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/first-aid');
    },
  );

  testWidgets('7b: emergency card, groups, sorted for the baby', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      const FirstAidHomeScreen(),
      overrides: careOverrides(firstAid: pack),
    );
    expect(find.text('Sơ cứu'), findsOneWidget);
    expect(find.text('Bé không thở, tím tái hoặc bất tỉnh?'), findsOneWidget);
    expect(find.text('Gọi 115'), findsOneWidget);
    expect(find.text('Hồi sức tim phổi (CPR)'), findsOneWidget);
    expect(find.textContaining('Sắp xếp theo tuổi Teddy'), findsOneWidget);
    // A category chip filters to its group.
    await tester.ensureVisible(find.text('Sức khoẻ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sức khoẻ').first);
    await tester.pumpAndSettle();
    expect(find.text('Hồi sức tim phổi (CPR)'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Vàng da sơ sinh'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vàng da sơ sinh'), findsOneWidget);
    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('faStartCpr')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('faStartCpr')));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/care/first-aid/cpr?v=under-1');
  });

  testWidgets(
    '7c: typed without accents, the matching passage under each result',
    (tester) async {
      await pumpRouted(
        tester,
        const FirstAidSearchScreen(),
        overrides: careOverrides(firstAid: pack),
      );
      expect(find.text('Tìm nhanh'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('faQuery')), 'chay mau cam');
      await tester.pumpAndSettle();
      expect(find.text('Chảy máu cam'), findsOneWidget);
      expect(find.textContaining('tình huống'), findsWidgets);
    },
  );

  testWidgets(
    '7d / 7e: choking opens on the baby’s age; the switch changes the steps',
    (tester) async {
      await pumpRouted(
        tester,
        const FirstAidSituationScreen(situationId: 'choking'),
        overrides: careOverrides(firstAid: pack),
      );
      expect(find.text('Hóc dị vật'), findsOneWidget);
      expect(find.text('Khẩn cấp'), findsOneWidget);
      expect(find.text('Dùng được khi không có mạng'), findsOneWidget);
      expect(find.text('Vỗ lưng 5 lần'), findsOneWidget);
      expect(find.text('Gọi 115'), findsNWidgets(2));
      await tester.tap(find.text('Từ 1 tuổi'));
      await tester.pumpAndSettle();
      expect(find.text('Đứng sau lưng bé'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Không được làm'), 300);
      expect(find.text('Không được làm'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.'),
        300,
      );
      expect(
        find.text('Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('faStepMode')), findsOneWidget);
    },
  );

  testWidgets('TH04: the seizure timer starts and stops', (tester) async {
    await pumpRouted(
      tester,
      const FirstAidSituationScreen(situationId: 'seizure'),
      overrides: careOverrides(firstAid: pack),
    );
    await tester.scrollUntilVisible(find.text('Bấm giờ cơn giật'), 300);
    expect(find.text('00:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faTimer')));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faTimer')));
    await tester.pump();
    expect(find.text('Bấm lại'), findsOneWidget);
  });

  testWidgets('7f: step mode keeps the screen on and counts taps', (
    tester,
  ) async {
    final device = FakeFirstAidDevice();
    await pumpRouted(
      tester,
      const FirstAidStepScreen(situationId: 'choking', variantId: 'under-1'),
      overrides: careOverrides(firstAid: pack, firstAidDevice: device),
    );
    expect(find.text('Hóc dị vật · dưới 1 tuổi · Bước 1/3'), findsOneWidget);
    expect(find.text('Chạm để đếm'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faCounter')));
    await tester.tap(find.byKey(const Key('faCounter')));
    await tester.pump();
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faNext')));
    await tester.pumpAndSettle();
    expect(find.text('Ấn ngực 5 lần'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
    expect(device.awake, [true]);
  });

  testWidgets('7i: CPR counts 30 on the beat, then 2 breaths start cycle 2', (
    tester,
  ) async {
    final device = FakeFirstAidDevice();
    await pumpRouted(
      tester,
      const FirstAidCprScreen(variantId: 'under-1'),
      overrides: careOverrides(firstAid: pack, firstAidDevice: device),
    );
    expect(find.textContaining('Bước 1/4 · Chu kỳ 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('faNext')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Ép ngực 30 lần'), findsOneWidget);
    expect(find.text('110 nhịp/phút'), findsOneWidget);
    expect(find.text('Tiếp: thổi ngạt 2 lần'), findsOneWidget);
    for (var i = 0; i < 31; i++) {
      await tester.pump(const Duration(milliseconds: 546));
    }
    await tester.pump();
    expect(device.beats, 30);
    expect(find.byKey(const Key('faBreathsDone')), findsOneWidget);
    await tester.tap(find.byKey(const Key('faBreathsDone')));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Bước 3/4 · Chu kỳ 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faPause')));
    await tester.pump();
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('7h: the call sheet reads out the baby and dials 115', (
    tester,
  ) async {
    final device = FakeFirstAidDevice();
    await pumpRouted(
      tester,
      const FirstAidHomeScreen(),
      overrides: careOverrides(firstAid: pack, firstAidDevice: device),
    );
    await tester.tap(find.text('Gọi 115'));
    await tester.pumpAndSettle();
    expect(find.text('Gọi cấp cứu 115'), findsOneWidget);
    expect(find.textContaining('Teddy'), findsWidgets);
    expect(find.text('Nói rõ với tổng đài'), findsOneWidget);
    expect(find.text('Số điện thoại để gọi lại'), findsOneWidget);
    await tester.tap(find.text('Gọi 115').last);
    await tester.pumpAndSettle();
    expect(device.dialled, ['115']);
  });

  test('a malformed pack is refused whole', () {
    expect(FirstAidPack.fromDoc(null), isNull);
    expect(
      FirstAidPack.fromDoc({
        'version': 'x',
        'pack': {'situations': 3},
      }),
      isNull,
    );
  });
}
