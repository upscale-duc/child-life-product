import 'package:child_life/features/app_update/app_update_models.dart';
import 'package:child_life/features/app_update/app_update_repository.dart';
import 'package:child_life/features/app_update/app_update_screens.dart';
import 'package:child_life/features/first_aid/first_aid_screens.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_update_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/router_pump.dart';

// App updates (D-061, v1.0 improvement UP1–UP6).
AppVersion v(String s) => AppVersion.tryParse(s)!;

void main() {
  group('versions and status', () {
    test('compared part by part, not as text', () {
      expect(v('1.10.0').compareTo(v('1.9.9')), 1);
      expect(v('1.0.3') < v('1.2.0'), isTrue);
      expect(v('2.0.0') == AppVersion.tryParse('2.0.0+86'), isTrue);
      expect(AppVersion.tryParse('abc'), isNull);
    });

    test(
      'below the minimum → required; below latest → available; else nothing',
      () {
        final config = sampleConfig(latest: '1.2.0', minimum: '1.1.0');
        expect(
          updateStatusOf(config, v('1.0.3'), ios: true),
          isA<UpdateRequired>(),
        );
        expect(
          updateStatusOf(config, v('1.1.0'), ios: true),
          isA<UpdateAvailable>(),
        );
        expect(updateStatusOf(config, v('1.2.0'), ios: true), isA<UpToDate>());
        expect(updateStatusOf(config, v('1.3.0'), ios: true), isA<UpToDate>());
      },
    );

    test(
      'never blocks without a config, a version, or a store version to give',
      () {
        expect(updateStatusOf(null, v('0.1.0'), ios: true), isA<UpToDate>());
        expect(
          updateStatusOf(sampleConfig(minimum: '1.1.0'), null, ios: true),
          isA<UpToDate>(),
        );
        expect(
          updateStatusOf(
            sampleConfig(latest: null, minimum: null),
            v('0.1.0'),
            ios: true,
          ),
          isA<UpToDate>(),
        );
        final broken = AppUpdateConfig(
          ios: PlatformUpdate(latest: v('1.0.0'), minimum: v('1.1.0')),
        );
        expect(
          updateStatusOf(broken, v('0.9.0'), ios: true),
          isA<UpdateAvailable>(),
        );
      },
    );

    test('platforms are separate', () {
      final config = AppUpdateConfig(
        ios: PlatformUpdate(latest: v('1.2.0'), minimum: v('1.2.0')),
        android: PlatformUpdate(latest: v('1.2.0')),
      );
      expect(
        updateStatusOf(config, v('1.0.3'), ios: true),
        isA<UpdateRequired>(),
      );
      expect(
        updateStatusOf(config, v('1.0.3'), ios: false),
        isA<UpdateAvailable>(),
      );
    });

    test('the portal document parses; bad parts are dropped', () {
      final config = AppUpdateConfig.fromDoc({
        'version': 'au_20261012_01',
        'config': {
          'ios': {'latest': '1.2.0', 'minimum': '1.0.5', 'storeUrl': storeUrl},
          'android': {
            'latest': null,
            'minimum': null,
            'storeUrl': 'http://insecure',
          },
          'snoozeDays': 7,
          'release': {
            'version': '1.2.0',
            'summary': {'vi': 'Sơ cứu', 'en': 'First aid'},
            'highlights': [
              {
                'icon': 'alert',
                'tone': 'danger',
                'title': {'vi': 'Sơ cứu trẻ em', 'en': 'Child first aid'},
                'body': {'vi': '25 tình huống', 'en': '25 situations'},
              },
              {'icon': 'alert'},
            ],
            'pages': [
              {
                'image': 'so-cuu_0000abcd',
                'title': {'vi': 'Trang', 'en': 'Page'},
                'body': {'vi': 'Nội dung', 'en': 'Text'},
                'where': null,
              },
            ],
          },
        },
      }, (id) => Uri.parse('https://img.test/$id'))!;
      expect(config.ios.minimum, v('1.0.5'));
      expect(config.android.storeUrl, isNull);
      expect(config.snoozeDays, 7);
      expect(config.release!.highlights, hasLength(1));
      expect(
        config.release!.pages.single.imageUrl.toString(),
        'https://img.test/so-cuu_0000abcd',
      );
      expect(config.release!.summary.of('en'), 'First aid');
    });
  });

  group('UP1 · Bắt buộc cập nhật', () {
    testWidgets(
      'blocks the app; the button opens the store; "Có gì mới" opens the pages',
      (tester) async {
        final opened = <Uri>[];
        await pumpRouted(
          tester,
          const AppUpdateGate(child: Text('the app')),
          overrides: appUpdateOverrides(
            config: sampleConfig(minimum: '1.1.0'),
            opened: opened,
          ),
        );
        expect(find.text('the app'), findsNothing);
        expect(find.text('Cần cập nhật để tiếp tục'), findsOneWidget);
        expect(find.text('Dữ liệu của bé vẫn an toàn'), findsOneWidget);
        await tester.tap(find.text('Cập nhật trên App Store'));
        await tester.pumpAndSettle();
        expect(opened.single.toString(), storeUrl);
        await tester.tap(find.text('Có gì mới trong 1.2.0'));
        await tester.pumpAndSettle();
        expect(find.text('Sơ cứu trẻ em, luôn trong túi bạn'), findsOneWidget);
      },
    );

    testWidgets(
      'Sơ cứu stays reachable while blocked, and back returns to UP1',
      (tester) async {
        await pumpRouted(
          tester,
          const AppUpdateGate(child: Text('the app')),
          overrides: [
            ...familyOverrides(firstAid: seedFirstAidPack()),
            ...appUpdateOverrides(config: sampleConfig(minimum: '1.1.0')),
          ],
        );
        await tester.tap(find.byKey(const Key('upFirstAid')));
        await tester.pumpAndSettle();
        expect(find.byType(FirstAidHomeScreen), findsOneWidget);
        expect(find.text('Cần cập nhật để tiếp tục'), findsNothing);
        Navigator.of(tester.element(find.byType(FirstAidHomeScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Cần cập nhật để tiếp tục'), findsOneWidget);
      },
    );

    testWidgets('no guide on the phone, no Sơ cứu link', (tester) async {
      await pumpRouted(
        tester,
        const AppUpdateGate(child: Text('the app')),
        overrides: [
          ...familyOverrides(),
          ...appUpdateOverrides(config: sampleConfig(minimum: '1.1.0')),
        ],
      );
      expect(find.byKey(const Key('upFirstAid')), findsNothing);
    });

    testWidgets('Android names Google Play; above the minimum the app shows', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const AppUpdateGate(child: Text('the app')),
        overrides: appUpdateOverrides(
          config: sampleConfig(minimum: '1.1.0'),
          appStore: false,
        ),
      );
      expect(find.text('Cập nhật trên Google Play'), findsOneWidget);
      await pumpRouted(
        tester,
        const AppUpdateGate(child: Text('the app')),
        overrides: appUpdateOverrides(
          config: sampleConfig(minimum: '1.1.0'),
          installed: '1.1.0',
        ),
      );
      expect(find.text('the app'), findsOneWidget);
    });
  });

  group('UP2 · Có bản mới', () {
    testWidgets(
      'lists the highlights; Cập nhật opens the store, Để sau closes',
      (tester) async {
        final opened = <Uri>[];
        final release = sampleRelease();
        await pumpRouted(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showClSheet<void>(
                context: context,
                builder: (_) => UpdateSheet(
                  status: UpdateAvailable(
                    installed: v('1.0.3'),
                    latest: v('1.2.0'),
                    storeUrl: Uri.parse(storeUrl),
                  ),
                  release: release,
                ),
              ),
              child: const Text('open'),
            ),
          ),
          overrides: appUpdateOverrides(config: sampleConfig(), opened: opened),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Mới · 1.2.0'), findsOneWidget);
        expect(find.text('Child Life có bản mới'), findsOneWidget);
        expect(find.text('Sổ chi tiêu chung cho bé'), findsOneWidget);
        await tester.tap(find.byKey(const Key('upLater')));
        await tester.pumpAndSettle();
        expect(find.text('Child Life có bản mới'), findsNothing);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('upUpdate')));
        await tester.pumpAndSettle();
        expect(opened, hasLength(1));
      },
    );

    test('"Để sau" hides it for the portal\'s number of days', () {
      final until = DateTime(2026, 10, 15);
      final memory = AppUpdateMemory(snoozedUntil: {'1.2.0': until});
      expect(memory.snoozed(v('1.2.0'), DateTime(2026, 10, 14)), isTrue);
      expect(memory.snoozed(v('1.2.0'), DateTime(2026, 10, 16)), isFalse);
      expect(memory.snoozed(v('1.3.0'), DateTime(2026, 10, 14)), isFalse);
    });
  });

  group('UP5 · Đã cập nhật / UP3–UP4 · Có gì mới', () {
    testWidgets(
      'after an update the banner shows; Xem opens the pages and it goes away',
      (tester) async {
        await pumpRouted(
          tester,
          const Scaffold(body: Column(children: [WhatsNewBanner()])),
          overrides: appUpdateOverrides(
            config: sampleConfig(),
            installed: '1.2.0',
          ),
          prefs: const {'appUpdate.lastRun': '1.0.3'},
        );
        expect(find.text('Đã cập nhật 1.2.0'), findsOneWidget);
        expect(find.text('Sơ cứu, chi tiêu chung, lịch tiêm'), findsOneWidget);
        await tester.tap(find.byKey(const Key('upBanner')));
        await tester.pumpAndSettle();
        expect(find.text('Mới trong 1.2.0'), findsWidgets);
        expect(find.text('Tìm trong tab Tiện ích'), findsWidgets);
        await tester.tap(find.byKey(const Key('upNext')));
        await tester.pumpAndSettle();
        expect(find.text('Một sổ chi tiêu chung cho bé'), findsOneWidget);
        expect(find.text('Xong'), findsOneWidget);
        await tester.tap(find.byKey(const Key('upNext')));
        await tester.pumpAndSettle();
        expect(find.text('Đã cập nhật 1.2.0'), findsNothing);
      },
    );

    testWidgets(
      'a fresh install has nothing to announce; × closes it for good',
      (tester) async {
        await pumpRouted(
          tester,
          const Scaffold(body: Column(children: [WhatsNewBanner()])),
          overrides: appUpdateOverrides(
            config: sampleConfig(),
            installed: '1.2.0',
          ),
        );
        expect(find.text('Đã cập nhật 1.2.0'), findsNothing);

        final (_, container) = await pumpRouted(
          tester,
          const Scaffold(body: Column(children: [WhatsNewBanner()])),
          overrides: appUpdateOverrides(
            config: sampleConfig(),
            installed: '1.2.0',
          ),
          prefs: const {'appUpdate.lastRun': '1.0.3'},
        );
        await tester.tap(find.byKey(const Key('upBannerClose')));
        await tester.pumpAndSettle();
        expect(find.text('Đã cập nhật 1.2.0'), findsNothing);
        expect(container.read(appUpdateMemoryProvider).closed, {'1.2.0'});
      },
    );
  });

  group('UP6 · Tôi · Phiên bản', () {
    testWidgets('a newer version: subtitle, tag, and the tap opens the store', (
      tester,
    ) async {
      final opened = <Uri>[];
      await pumpRouted(
        tester,
        const Scaffold(body: ClCardGroup(children: [AppVersionRow()])),
        overrides: appUpdateOverrides(config: sampleConfig(), opened: opened),
      );
      expect(find.text('Phiên bản 1.0.3'), findsOneWidget);
      expect(find.text('Có bản mới 1.2.0'), findsOneWidget);
      await tester.tap(find.byKey(const Key('meVersion')));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
    });

    testWidgets(
      'up to date: "Đây là bản mới nhất", build and environment on dev',
      (tester) async {
        await pumpRouted(
          tester,
          const Scaffold(body: ClCardGroup(children: [AppVersionRow()])),
          overrides: appUpdateOverrides(
            config: sampleConfig(),
            installed: '1.2.0',
            shownVersion: '1.2.0 (86) · dev',
          ),
        );
        expect(find.text('Phiên bản 1.2.0 (86) · dev'), findsOneWidget);
        expect(find.text('Đây là bản mới nhất'), findsOneWidget);
        expect(find.text('Cập nhật'), findsNothing);
      },
    );
  });
}
