import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/family/family_labels.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/family_screen.dart';
import 'package:child_life/features/family/invite_screens.dart';
import 'package:child_life/features/family/join_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

class FakeFamilyRepository extends Fake implements FamilyRepository {
  FakeFamilyRepository({this.preview});

  InvitePreview? preview;
  final lookups = <InviteLookup>[];
  final accepted = <(InviteLookup, String, Relation, String?)>[];

  @override
  Future<InvitePreview> previewInvite(InviteLookup lookup) async {
    lookups.add(lookup);
    return preview ?? const ClosedInvite(InviteClosedReason.notFound);
  }

  final declined = <String>[];
  final revoked = <String>[];

  @override
  Future<void> declineInvite(String inviteId) async => declined.add(inviteId);

  @override
  Future<void> revokeInvite(String inviteId) async => revoked.add(inviteId);

  @override
  Future<String> acceptInvite({
    required InviteLookup lookup,
    required String displayName,
    required Relation relation,
    String? relationCustom,
  }) async {
    accepted.add((lookup, displayName, relation, relationCustom));
    throw const FamilyException(FamilyFailure.expired);
  }
}

const devHosts = {'child-life-dev-landing.web.app', 'dev.childlife.app'};
const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz012345';

void main() {
  group('invite lookups (P-020, plan §3.7)', () {
    test('6 digits, spaces allowed', () {
      expect(
        InviteLookup.parse('482 913', allowedHosts: devHosts),
        const InviteLookup.code('482913'),
      );
    });

    test('invite links only from this environment over https', () {
      expect(
        InviteLookup.parse(
          'https://child-life-dev-landing.web.app/i/$token',
          allowedHosts: devHosts,
        ),
        const InviteLookup.token(token),
      );
      for (final bad in [
        'http://child-life-dev-landing.web.app/i/$token',
        'https://evil.example/i/$token',
        'https://child-life-dev-landing.web.app/x/$token',
        'https://child-life-dev-landing.web.app/i/short',
        '48291',
        'hello',
      ]) {
        expect(
          InviteLookup.parse(bad, allowedHosts: devHosts),
          isNull,
          reason: bad,
        );
      }
    });
  });

  group('parsing server documents', () {
    test('preview states', () {
      final valid = InvitePreview.fromJson({
        'status': 'valid',
        'babyNickname': 'Teddy',
        'inviterName': 'Mai',
        'inviterRelation': 'mother',
        'inviterRelationCustom': null,
        'role': 'relative',
        'relation': 'friend',
        'relationCustom': null,
        'extraRights': {'viewBabyInfo': true, 'viewDailyCare': false},
        'expiresAt': '2026-10-15T05:00:00.000Z',
        'alreadyMember': false,
      });
      expect(valid, isA<ValidInvite>());
      valid as ValidInvite;
      expect(valid.relation, Relation.friend);
      expect(valid.extraRights, const ExtraRights(viewBabyInfo: true));
      expect(
        (InvitePreview.fromJson({'status': 'used'}) as ClosedInvite).reason,
        InviteClosedReason.used,
      );
      expect(
        (InvitePreview.fromJson({'status': 'locked', 'retryAfterSeconds': 120})
                as LockedInvite)
            .retryAfter,
        const Duration(minutes: 2),
      );
      expect(
        (InvitePreview.fromJson({'status': 'surprise'}) as ClosedInvite).reason,
        InviteClosedReason.notFound,
      );
    });

    test('membership with rights and an access end date (R-024)', () {
      final m = Membership.fromJson({
        'babyId': teddyId,
        'uid': 'u_hoa',
        'role': 'relative',
        'relation': 'grandmother',
        'displayName': 'Hoa',
        'status': 'active',
        'extraRights': {'viewBabyInfo': false, 'viewDailyCare': true},
        'accessUntil': '2026-12-31',
        'accessUntilAt': Timestamp.fromDate(DateTime.utc(2026, 12, 31, 17)),
        'joinedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 20)),
      });
      expect(m.canViewToday, isTrue);
      expect(m.canViewBabyInfo, isFalse);
      expect(m.accessUntil, DateTime(2026, 12, 31));
      expect(m.isActiveAt(DateTime.utc(2026, 12, 31, 16)), isTrue);
      expect(m.isActiveAt(DateTime.utc(2026, 12, 31, 18)), isFalse);
    });

    test('pending invite row', () {
      final p = PendingInvite.fromJson({
        'inviteId': 'i_1',
        'relation': 'grandmother',
        'relationCustom': null,
        'role': 'caregiver',
        'extraRights': null,
        'code': '482913',
        'token': token,
        'recipientEmail': 'ba.ngoai@gmail.com',
        'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 10, 15)),
      });
      expect(p.isExpiredAt(DateTime.utc(2026, 10, 14)), isFalse);
      expect(p.isExpiredAt(DateTime.utc(2026, 10, 15)), isTrue);
      expect(p.ticket.link('https://x.app'), 'https://x.app/i/$token');
    });

    test('callable reasons map to copy', () {
      FamilyFailure of(String reason, [String code = 'failed-precondition']) =>
          familyFailureOf(
            FirebaseFunctionsException(
              message: reason,
              code: code,
              details: {'reason': reason},
            ),
          );
      expect(of('email-unverified'), FamilyFailure.emailUnverified);
      expect(of('owner-only', 'permission-denied'), FamilyFailure.ownerOnly);
      expect(of('too-soon', 'resource-exhausted'), FamilyFailure.tooSoon);
      expect(of('already-member'), FamilyFailure.alreadyMember);
      expect(of('???', 'unavailable'), FamilyFailure.network);
    });
  });

  group('roles (§5, D-017, D-018)', () {
    test('who may open 14f', () {
      expect(canManage(mai, minh), isTrue, reason: 'owner manages co-parents');
      expect(canManage(minh, mai), isFalse, reason: 'owner is protected');
      expect(canManage(minh, lan), isTrue);
      expect(canManage(minh, minh), isFalse, reason: 'not yourself');
      final other = member('u_x', 'X', MemberRole.coParent, Relation.father);
      expect(canManage(minh, other), isFalse, reason: 'only the owner');
      expect(canManage(lan, hoa), isFalse, reason: 'caregivers view only');
    });

    test('14a order: you, owner, co-parents, caregivers, relatives', () {
      expect(
        sortMembers([hoa, lan, minh, mai], 'u_lan').map((m) => m.displayName),
        ['Cô Lan', 'Mai', 'Minh', 'Bà nội Hoa'],
      );
    });

    test('tabs per role; relatives with daily care get Hôm nay', () {
      expect(tabsForRole(ClRole.relative), [ClTab.memories, ClTab.utilities]);
      expect(
        tabsForRole(ClRole.relative, relativeSeesToday: true).first,
        ClTab.today,
      );
    });

    test('caregiver tiles follow 30:1259 in both languages', () {
      for (final l10n in [AppLocalizationsVi(), AppLocalizationsEn()]) {
        final tiles = rolePermissions(l10n, MemberRole.caregiver);
        expect(tiles.where((t) => !t.$2).map((t) => t.$1), [l10n.permMemories]);
      }
      final vi = AppLocalizationsVi();
      expect(
        rolePermissions(vi, MemberRole.caregiver).first.$1,
        'Ghi bú, ngủ, tã',
      );
    });
  });

  group('screens', () {
    testWidgets('14a as the owner: members, pending row, invite entry', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: FamilyScreen()),
        overrides: familyOverrides(),
      );
      expect(find.text('Gia đình'), findsOneWidget);
      expect(find.text('Những người cùng chăm Teddy'), findsOneWidget);
      expect(find.text('Mẹ · Cùng nuôi'), findsOneWidget);
      expect(find.text('Bảo mẫu · Người chăm sóc'), findsOneWidget);
      expect(find.text('Bạn'), findsOneWidget);
      expect(find.text('Đang chờ nhận lời (1)'), findsOneWidget);
      expect(find.text('ba.ngoai@gmail.com'), findsOneWidget);
      expect(find.text('Bà ngoại · hết hạn 15 thg 10'), findsOneWidget);
      expect(find.text('Gửi lại'), findsOneWidget);

      await tester.tap(find.text('Minh'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá Minh khỏi gia đình'), findsOneWidget);
      expect(find.text('Ba · tham gia 20 thg 9'), findsOneWidget);
      expect(find.text('Không giới hạn'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Đóng'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mời người cùng chăm'));
      await tester.tap(find.text('Mời người cùng chăm'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.invite);
    });

    testWidgets(
      'an invite: red dot on the switcher, a row in Chọn bé, accept with no code',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: TodayScreen()),
          overrides: familyOverrides(myInvites: [binInvite]),
        );
        expect(find.byKey(const Key('babySwitcherDot')), findsOneWidget);
        // One baby, yet the switcher opens the list: that is where the invite is.
        await tester.tap(find.byType(ClBabySwitcher));
        await tester.pumpAndSettle();
        expect(find.text('Lời mời đang chờ bạn'), findsOneWidget);
        await tester.tap(find.text('Mẹ Hà mời bạn cùng chăm bé Bin'));
        await tester.pumpAndSettle();
        expect(find.text('Lời mời cùng chăm bé'), findsOneWidget);
        expect(find.text('Cùng nuôi · Hết hạn 15 thg 10'), findsOneWidget);
        await tester.tap(find.text('Đồng ý'));
        await tester.pumpAndSettle();
        expect(visits.last.location, startsWith(Routes.joinInvite));
        final args = visits.last.extra! as JoinArgs;
        expect(args.lookup, InviteLookup.id(binInvite.inviteId));
        expect(args.preview.babyNickname, 'Bin');
      },
    );

    testWidgets('an invite can be declined from its sheet, after asking', (
      tester,
    ) async {
      final repo = FakeFamilyRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: [
          ...familyOverrides(myInvites: [binInvite]),
          familyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.tap(find.byType(ClBabySwitcher));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mẹ Hà mời bạn cùng chăm bé Bin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ chối'));
      await tester.pumpAndSettle();
      expect(find.text('Từ chối lời mời chăm bé Bin?'), findsOneWidget);
      await tester.tap(find.text('Từ chối').last);
      await tester.pumpAndSettle();
      expect(repo.declined, [binInvite.inviteId]);
    });

    testWidgets('no invite: no dot, and Gia đình has no invite section', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: FamilyScreen()),
        overrides: familyOverrides(),
      );
      expect(find.byKey(const Key('babySwitcherDot')), findsNothing);
      expect(find.text('Lời mời đang chờ bạn'), findsNothing);
    });

    testWidgets('a pending invite can be revoked from its row, after asking', (
      tester,
    ) async {
      final repo = FakeFamilyRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: FamilyScreen()),
        overrides: [
          ...familyOverrides(),
          familyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.ensureVisible(find.text('Huỷ lời mời'));
      await tester.tap(find.text('Huỷ lời mời'));
      await tester.pumpAndSettle();
      expect(find.text('Huỷ lời mời này?'), findsOneWidget);
      expect(
        find.text(
          'Mã và link đã gửi cho ba.ngoai@gmail.com sẽ không dùng được nữa.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Huỷ lời mời').last);
      await tester.pumpAndSettle();
      expect(repo.revoked, [pendingGrandma.inviteId]);
    });

    testWidgets('14a as a caregiver: view only, no pending, no invite', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: FamilyScreen()),
        overrides: familyOverrides(me: lan),
      );
      expect(find.text('Đang chờ nhận lời (1)'), findsNothing);
      expect(find.text('Mời người cùng chăm'), findsNothing);
      await tester.tap(find.text('Minh'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá Minh khỏi gia đình'), findsNothing);
    });

    testWidgets('14b needs a relation; co-parents are owner-only', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const InviteRoleScreen(),
        overrides: familyOverrides(me: minh),
      );
      final next = find.widgetWithText(Semantics, 'Tiếp · Gửi lời mời');
      expect(next, findsWidgets);
      expect(find.text('Bạn bè'), findsOneWidget);
      expect(find.text('Mẹ'), findsNothing);
      expect(
        find.text('Chỉ người tạo hồ sơ mời được Cùng nuôi'),
        findsOneWidget,
      );
      await tester.tap(find.text('Xem chi tiết quyền'));
      await tester.pumpAndSettle();
      expect(find.text('Quyền của Người chăm sóc'), findsOneWidget);
    });

    testWidgets('15: wrong code shows G-035 copy; a valid one opens 16', (
      tester,
    ) async {
      final repo = FakeFamilyRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const EnterCodeScreen(),
        overrides: [familyRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.enterText(find.byType(EditableText), '111111');
      await tester.pumpAndSettle();
      expect(find.text('Mã chưa đúng. Kiểm tra lại 6 số nhé.'), findsOneWidget);
      expect(repo.lookups.single, const InviteLookup.code('111111'));

      repo.preview = invitePreview();
      await tester.enterText(find.byType(EditableText), '482913');
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith(Routes.joinInvite));
      expect((visits.last.extra! as JoinArgs).preview.inviterName, 'Mai');
    });

    testWidgets('16 signed out: countdown, role, tiles, then 16b', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        AcceptInviteScreen(
          lookup: const InviteLookup.code('482913'),
          preview: invitePreview(),
        ),
        overrides: [
          sessionProvider.overrideWithValue(const SessionSignedOut()),
        ],
      );
      expect(find.text('Mẹ Mai mời bạn'), findsOneWidget);
      expect(find.text('Còn 68 giờ'), findsOneWidget);
      expect(find.text('Người chăm sóc'), findsOneWidget);
      expect(find.text('Xem nhắc việc'), findsOneWidget);
      await tester.tap(find.text('Tham gia'));
      await tester.pumpAndSettle();
      expect(find.text('Vào gia đình Teddy'), findsOneWidget);
      expect(find.text('Vào ngay'), findsOneWidget);
    });

    testWidgets('16a keeps the invited relation; a closed invite goes to 17', (
      tester,
    ) async {
      final repo = FakeFamilyRepository();
      final (visits, _) = await pumpRouted(
        tester,
        ConfirmJoinScreen(
          args: JoinArgs(
            lookup: const InviteLookup.code('482913'),
            preview: invitePreview(),
          ),
        ),
        overrides: [
          ...familyOverrides(me: hoa, anonymous: true),
          familyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      expect(find.text('Bạn là ai với Teddy?'), findsOneWidget);
      expect(find.text('Mai đã chọn “Bà”. Đổi nếu chưa đúng.'), findsOneWidget);
      await tester.tap(find.text('Vào xem Teddy'));
      await tester.pumpAndSettle();
      expect(repo.accepted.single.$3, Relation.grandmother);
      expect(repo.accepted.single.$2, 'Bà nội Hoa');
      expect(visits.last.location, '${Routes.joinClosed}?reason=expired');
    });

    testWidgets('17 states (G-035) in English', (tester) async {
      await pumpRouted(
        tester,
        const InviteClosedScreen(reason: InviteClosedReason.revoked),
        locale: const Locale('en'),
      );
      expect(find.text('This invite was cancelled'), findsOneWidget);
      expect(find.text('Enter another code'), findsOneWidget);
    });

    testWidgets('16c: a temporary identity sees "Chưa lưu tài khoản"', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: familyOverrides(me: lan, anonymous: true),
      );
      expect(find.text('Chưa lưu tài khoản'), findsOneWidget);
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu tài khoản'), findsOneWidget);
      expect(
        find.text('Để không mất Teddy khi đổi máy hoặc cài lại app.'),
        findsOneWidget,
      );
    });

    testWidgets('Today is read-only for a relative with daily care (D-018)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: familyOverrides(
          me: member(
            'u_hoa',
            'Hoa',
            MemberRole.relative,
            Relation.grandmother,
            extra: const ExtraRights(viewDailyCare: true),
          ),
        ),
      );
      expect(find.text('Chạm để ghi'), findsNothing);
      expect(
        find.text('Teddy'),
        findsOneWidget,
        reason: 'no DOB without Thông tin bé',
      );
    });
  });
}
