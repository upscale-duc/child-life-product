import 'package:child_life/app/providers.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/me/account_screen.dart';
import 'package:child_life/features/me/baby_profile_screens.dart';
import 'package:child_life/features/me/help_screen.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_screen.dart';
import 'package:child_life/features/me/notifications_screen.dart';
import 'package:child_life/features/me/storage_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/my_invites.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

const _gb = 1024 * 1024 * 1024;

List<Override> _overrides({
  Membership? me,
  List<MyInvite> myInvites = const [],
  FakeMeRepository? repo,
  FamilyStorage? storage,
  AccountDoc account = const AccountDoc(),
  List<String> providers = const ['password'],
}) => [
  ...familyOverrides(
    me: me,
    email: 'mai@gmail.com',
    providers: providers,
    account: account,
    myInvites: myInvites,
  ),
  ...memoryOverrides(),
  ...meOverrides(repo: repo, storage: storage),
];

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  group('model', () {
    test('"Sắp đầy" from 80 %, full at 100 % (13c, 13d)', () {
      expect(storageStateOf(7 * _gb, 10 * _gb), StorageState.ok);
      expect(storageStateOf(8 * _gb, 10 * _gb), StorageState.nearFull);
      expect(storageStateOf(10 * _gb, 10 * _gb), StorageState.full);
      expect(storageStateOf(1, 0), StorageState.full);
    });

    test('sizes read like the design ("3,2 GB", "0,8 GB", "40 MB")', () {
      expect(formatBytes((3.2 * _gb).round(), 'vi'), '3,2 GB');
      expect(formatBytes((0.8 * _gb).round(), 'vi'), '0,8 GB');
      expect(formatBytes(10 * _gb, 'en'), '10 GB');
      expect(formatBytes(40 * 1024 * 1024, 'vi'), '40 MB');
    });
  });

  group('13a / 13g / 13h Tôi', () {
    testWidgets(
      'parents see storage; caregivers and relatives do not (R-123)',
      (tester) async {
        await pumpRouted(tester, const MeScreen(), overrides: _overrides());
        expect(find.text('Dung lượng'), findsOneWidget);
        expect(find.text('Hồ sơ các bé'), findsOneWidget);
        expect(find.textContaining('Mẹ · chủ hồ sơ của Teddy'), findsOneWidget);

        await pumpRouted(
          tester,
          const MeScreen(),
          overrides: _overrides(me: lan),
        );
        expect(find.text('Dung lượng'), findsNothing);
        expect(find.text('Bé được giao'), findsOneWidget);

        await pumpRouted(
          tester,
          const MeScreen(),
          overrides: _overrides(me: hoa),
        );
        expect(find.text('Dung lượng'), findsNothing);
        expect(find.text('Các bé bạn theo dõi'), findsOneWidget);
        expect(find.text('Lời nhắn'), findsNothing);
      },
    );

    testWidgets('the app version sits under Đăng xuất (owner, 2026-10-12)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const MeScreen(),
        overrides: [
          ..._overrides(),
          appVersionProvider.overrideWith((ref) async => '1.0.0 (7) · dev'),
        ],
      );
      await tester.scrollUntilVisible(find.byKey(const Key('meVersion')), 200);
      expect(find.text('Phiên bản 1.0.0 (7) · dev'), findsOneWidget);
    });

    testWidgets('"Đăng xuất" asks first', (tester) async {
      await pumpRouted(tester, const MeScreen(), overrides: _overrides());
      await tester.scrollUntilVisible(find.text('Đăng xuất'), 200);
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi máy này?'), findsOneWidget);
    });

    testWidgets('an ownership offer is answered from the Me tab (Q-016)', (
      tester,
    ) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const MeScreen(),
        overrides: _overrides(
          me: minh,
          repo: repo,
          account: const AccountDoc(
            offer: OwnershipOffer(
              familyId: 'f_1',
              fromName: 'Mai',
              babyIds: [teddyId],
            ),
          ),
        ),
      );
      expect(
        find.text('Mai muốn chuyển quyền chủ hồ sơ cho bạn'),
        findsOneWidget,
      );
      await tester.tap(find.text('Nhận'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'answerOwnership');
      expect(repo.calls.single.$2, {'answer': 'accept'});
    });
  });

  group('13b–13e Dung lượng', () {
    testWidgets('full: banner, primary contact, request +20 GB (D-010)', (
      tester,
    ) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const StorageScreen(),
        overrides: _overrides(
          repo: repo,
          storage: mockStorage(teddyGb: 7.4, naGb: 2.6),
        ),
      );
      expect(find.text('Đã dùng hết 10 GB'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Liên hệ quản trị'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liên hệ quản trị'));
      await tester.pumpAndSettle();
      expect(find.text('Khác'), findsNothing);
      await tester.tap(find.text('+20 GB'));
      await tester.pump();
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'requestStorage');
      expect(repo.calls.single.$2['amountGb'], 20);
      expect(find.text('Đã gửi yêu cầu'), findsOneWidget);
    });

    testWidgets('nearly full warns at 82 %', (tester) async {
      await pumpRouted(
        tester,
        const StorageScreen(),
        overrides: _overrides(storage: mockStorage(teddyGb: 6.1, naGb: 2.1)),
      );
      expect(find.textContaining('Sắp đầy · 82%'), findsOneWidget);
    });
  });

  group('13l Xoá hồ sơ bé', () {
    testWidgets('only the typed nickname enables "Xoá vĩnh viễn" (R-045)', (
      tester,
    ) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const BabyProfileViewScreen(babyId: teddyId),
        overrides: _overrides(repo: repo),
      );
      final card = find.text('Xoá hồ sơ Teddy');
      await tester.scrollUntilVisible(card, 300);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá vĩnh viễn'));
      await tester.pump();
      expect(repo.calls, isEmpty);
      await tester.enterText(find.byType(EditableText), 'teddy');
      await tester.pump();
      await tester.tap(find.text('Xoá vĩnh viễn'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'deleteBaby');
      expect(repo.calls.single.$2, {'babyId': teddyId, 'typed': 'teddy'});
    });

    testWidgets('a co-parent who is not the owner cannot start it', (
      tester,
    ) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const BabyProfileViewScreen(babyId: teddyId),
        overrides: _overrides(me: minh, repo: repo),
      );
      final card = find.text('Xoá hồ sơ Teddy');
      await tester.scrollUntilVisible(card, 300);
      await tester.pumpAndSettle();
      expect(find.text('Chỉ chủ hồ sơ (Mai) làm được'), findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('Xoá vĩnh viễn'), findsNothing);
    });
  });

  group('13n, G-056, G-057', () {
    testWidgets('the last sign-in method cannot be unlinked', (tester) async {
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(providers: const ['apple.com']),
      );
      await tester.tap(find.text('Gỡ'));
      await tester.pumpAndSettle();
      expect(find.text('Cần giữ ít nhất một cách đăng nhập.'), findsOneWidget);
    });

    testWidgets('another device signs out from here', (tester) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(repo: repo),
      );
      expect(find.text('Máy này'), findsOneWidget);
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'signOutDevice');
      expect(repo.calls.single.$2, {'deviceId': 'd_${'b' * 32}'});
    });

    testWidgets('owners must transfer before deleting the account (R-046)', (
      tester,
    ) async {
      await pumpRouted(tester, const AccountScreen(), overrides: _overrides());
      await tester.scrollUntilVisible(find.text('Xoá tài khoản'), 300);
      expect(find.text('Cần chuyển chủ hồ sơ của Teddy trước'), findsOneWidget);
    });

    testWidgets('a notification kind turns off', (tester) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const NotificationsScreen(),
        overrides: _overrides(repo: repo),
      );
      await tester.tap(find.byType(ClToggle).first);
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'savePrefs');
      expect(repo.calls.single.$2['memories'], isFalse);
    });

    testWidgets('Hồ sơ các bé lists an invite mailed to me, with a red dot', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const BabyProfilesScreen(),
        overrides: _overrides(myInvites: [binInvite]),
      );
      expect(find.text('Lời mời đang chờ bạn'), findsOneWidget);
      expect(find.text('Mẹ Hà mời bạn cùng chăm bé Bin'), findsOneWidget);
      expect(find.byType(ClRedDot), findsOneWidget);
      await tester.tap(find.text('Mẹ Hà mời bạn cùng chăm bé Bin'));
      await tester.pumpAndSettle();
      expect(find.text('Lời mời cùng chăm bé'), findsOneWidget);
    });

    testWidgets('help needs a topic and a message', (tester) async {
      final repo = FakeMeRepository();
      await pumpRouted(
        tester,
        const HelpScreen(),
        overrides: _overrides(repo: repo),
      );
      await tester.tap(find.text('Gửi'));
      await tester.pump();
      expect(repo.calls, isEmpty);
      await tester.tap(find.text('Dung lượng'));
      await tester.enterText(find.byType(EditableText), 'Không tải được video');
      await tester.pump();
      await tester.tap(find.byType(ClToggle).first);
      await tester.pump();
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'sendHelp');
      expect(repo.calls.single.$2, {
        'category': 'storage',
        'message': 'Không tải được video',
      });
    });
  });

  testWidgets('Hồ sơ bé: "Nhập mã mời" opens 15 for every role', (
    tester,
  ) async {
    for (final who in [mai, lan, hoa]) {
      final (visits, _) = await pumpRouted(
        tester,
        const BabyProfilesScreen(),
        overrides: _overrides(me: who),
      );
      await tester.scrollUntilVisible(find.text('Nhập mã mời'), 200);
      expect(
        find.text('Được mời chăm một bé khác? Nhập mã 6 số trong lời mời.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('profileJoin')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/join');
    }
  });
}
