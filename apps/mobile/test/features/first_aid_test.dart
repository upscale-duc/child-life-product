import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/utilities/utilities_screen.dart';
import 'package:child_life/features/first_aid/first_aid_models.dart';
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
    test('35 situations in 4 groups, every picture named', () {
      expect(pack.situations, hasLength(35));
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
    'Tiện ích lists Sơ cứu once a guide is on the device (450:6597)',
    (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: UtilitiesScreen()),
        overrides: careOverrides(),
      );
      expect(find.byKey(const Key('utFirstAid')), findsNothing);
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: UtilitiesScreen()),
        overrides: careOverrides(firstAid: pack),
      );
      expect(find.text('Sơ cứu trẻ em'), findsOneWidget);
      expect(
        find.text('35 tình huống · dùng khi không có mạng'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('utFirstAid')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/utilities/first-aid');
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
    // Revision 2: CPR is the TH01 page itself (the beat starts on its own).
    expect(visits.last.location, '/utilities/first-aid/s/cpr?v=under-1');
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
      expect(find.text('× 5 lần'), findsNWidgets(2));
      expect(find.text('Gọi 115'), findsNWidgets(2));
      expect(find.byKey(const Key('faReadAloud')), findsOneWidget);
      await tester.tap(find.text('Từ 1 tuổi'));
      await tester.pumpAndSettle();
      // From 1 year: back blows and abdominal thrusts (AHA / ERC 2025).
      expect(find.text('Ép bụng 5 lần'), findsOneWidget);
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

  testWidgets(
    '7h: "Gọi 115" dials at once; back in the app the bar counts the call',
    (tester) async {
      final device = FakeFirstAidDevice();
      await pumpRouted(
        tester,
        const FirstAidSituationScreen(situationId: 'choking'),
        overrides: careOverrides(firstAid: pack, firstAidDevice: device),
      );
      expect(find.byKey(const Key('faTellOperator')), findsNothing);
      await tester.tap(find.text('Gọi 115').last);
      await tester.pump();
      expect(device.dialled, ['115']);
      expect(find.text('Đang gọi 115 · 00:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      // The top pill gives way; the card to read out to the operator appears.
      expect(find.text('Gọi 115'), findsNothing);
      expect(find.text('Nói với tổng đài'), findsOneWidget);
      expect(
        find.text('Bé đột ngột không thở, không ho, không khóc được'),
        findsNWidgets(2),
      );
    },
  );

  testWidgets('"Đọc to hướng dẫn" reads the head, each step and the callouts', (
    tester,
  ) async {
    final device = FakeFirstAidDevice();
    await pumpRouted(
      tester,
      const FirstAidSituationScreen(situationId: 'nosebleed'),
      overrides: careOverrides(firstAid: pack, firstAidDevice: device),
    );
    expect(find.text('Gọi 115'), findsNothing);
    expect(find.text('Đọc to hướng dẫn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('faReadAloud')));
    await tester.pumpAndSettle();
    final page = pack.situation('nosebleed')!.variants.first;
    expect(device.spoken.first, startsWith('Chảy máu cam.'));
    expect(device.spoken[1], startsWith('Bước 1.'));
    expect(
      device.spoken,
      hasLength(1 + page.steps.length + page.callouts.length),
    );
    expect(device.awake, [true, false]);
    expect(find.text('Đọc to hướng dẫn'), findsOneWidget);
  });

  testWidgets(
    'TH01: the beat plays by itself; after 30 the app says the breaths',
    (tester) async {
      final device = FakeFirstAidDevice();
      await pumpRouted(
        tester,
        const FirstAidSituationScreen(situationId: 'cpr', variantId: 'under-1'),
        overrides: careOverrides(firstAid: pack, firstAidDevice: device),
      );
      expect(find.text('Nhịp ép đang phát · tự động'), findsOneWidget);
      expect(find.text('110'), findsOneWidget);
      expect(find.text('× 30 lần'), findsOneWidget);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 546));
      }
      expect(device.beats, 30);
      expect(device.spoken, ['Thổi ngạt 2 lần']);
      // The beat waits for the breaths, then carries on.
      await tester.pump(const Duration(seconds: 2));
      expect(device.beats, 30);
      await tester.pump(const Duration(seconds: 3));
      expect(device.beats, greaterThan(30));
      expect(device.awake.first, isTrue);
      // Leaving the page stops it.
      await pumpRouted(tester, const SizedBox(), overrides: careOverrides());
      expect(device.awake.last, isFalse);
    },
  );

  test(
    'the text names no country: {emergency} and {poison} come from the pack',
    () {
      expect(
        FirstAidPack.fillTokens({
          'a': ['Gọi {emergency} ngay', 'Call {poison} now'],
          'n': 3,
        }, '911'),
        {
          'a': ['Gọi 911 ngay', 'Call 911 now'],
          'n': 3,
        },
      );
      expect(
        FirstAidPack.fillTokens(
          'Call {poison}',
          '911',
          poison: '1-800-222-1222',
        ),
        'Call 1-800-222-1222',
      );
      final file = File('../../content/first-aid/pack.seed.json');
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final step =
          (((raw['situations']! as List).first as Map)['variants']! as List)
                  .first
              as Map;
      ((step['steps']! as List).first as Map)['body'] = {
        'vi': 'Gọi {emergency} ngay.',
        'en': 'Call {emergency} now.',
      };
      final pack = FirstAidPack.fromDoc({
        'version': 'fa_20261016_01',
        'pack': raw,
      })!;
      final body = pack.situations.first.variants.first.steps.first.body;
      expect([body.vi, body.en], ['Gọi 115 ngay.', 'Call 115 now.']);
    },
  );

  test('the guide calls the family\'s country number (D-078)', () {
    final pack = seedFirstAidPack();
    String banner(FirstAidPack p) =>
        p.situations.first.variants.first.banner!.en;
    expect(pack.emergencyNumber, '115');
    expect(banner(pack), contains('115'));
    expect(banner(pack), isNot(contains('{emergency}')));

    final us = pack.forCountry('US');
    expect(us.emergencyNumber, '911');
    expect(us.localCountry, 'US');
    expect(banner(us), contains('911'));
    expect(banner(us), isNot(contains('115')));

    final vn = us.forCountry('VN');
    expect(
      [vn.emergencyNumber, vn.country, vn.localCountry],
      ['115', 'VN', null],
    );
    // A country without a known number, or none: the pack's own number.
    for (final other in [pack.forCountry('BR'), us.forCountry(null)]) {
      expect([other.emergencyNumber, other.country], ['115', null]);
    }
    expect(identical(pack.forCountry(null), pack), isTrue);
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
