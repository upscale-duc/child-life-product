import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/invite_link_join.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// One-tap invite links (owner, 2026-10-12): the email's OneLink or `/i/{token}` joins without
// questions and lands on Hôm nay.
const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz012345';
const lookup = InviteLookup.token(token);

class _Auth extends Fake implements AuthRepository {
  _Auth(this.live);
  final ValueNotifier<Session> live;
  var anonymousSignIns = 0;
  Session? signedInFrom;

  @override
  Future<void> signInAnonymously() async {
    anonymousSignIns++;
    signedInFrom = live.value;
    live.value = SessionSignedIn(
      user: FakeUser(uid: 'u_new', isAnonymous: true),
      memberships: const [],
    );
  }
}

class _Repo extends Fake implements FamilyRepository {
  _Repo(this.live, this.preview, {this.failFirst = false});
  final ValueNotifier<Session> live;
  final InvitePreview preview;
  bool failFirst;
  final accepted = <(String, Relation)>[];

  @override
  Future<InvitePreview> previewInvite(InviteLookup lookup) async {
    if (failFirst) {
      failFirst = false;
      throw const FamilyException(FamilyFailure.network);
    }
    return preview;
  }

  @override
  Future<String> acceptInvite({
    required InviteLookup lookup,
    required String displayName,
    required Relation relation,
    String? relationCustom,
  }) async {
    accepted.add((displayName, relation));
    final now = live.value as SessionSignedIn;
    live.value = SessionSignedIn(
      user: now.user,
      memberships: [
        member(now.user.uid, displayName, MemberRole.caregiver, relation),
      ],
    );
    return teddyId;
  }
}

List<Override> _overrides(
  ValueNotifier<Session> live,
  _Repo repo,
  _Auth auth,
) => [
  sessionProvider.overrideWith((ref) {
    void changed() => ref.invalidateSelf();
    live.addListener(changed);
    ref.onDispose(() => live.removeListener(changed));
    return live.value;
  }),
  familyRepositoryProvider.overrideWithValue(repo),
  authRepositoryProvider.overrideWithValue(auth),
];

void main() {
  setUp(openedInviteTokens.clear);

  testWidgets(
    'no account: waits for the saved one, then "Vào ngay" as Người thân',
    (tester) async {
      final live = ValueNotifier<Session>(const SessionLoading());
      final repo = _Repo(live, invitePreview());
      final auth = _Auth(live);
      // A cold start: the saved session is still loading when the screen opens.
      Future<void>.delayed(
        const Duration(seconds: 1),
        () => live.value = const SessionSignedOut(),
      );
      final (visits, container) = await pumpRouted(
        tester,
        const InviteLinkScreen(lookup: lookup),
        overrides: _overrides(live, repo, auth),
      );
      expect(openedInviteTokens, {token});
      expect(auth.signedInFrom, isA<SessionSignedOut>());
      expect(auth.anonymousSignIns, 1);
      expect(repo.accepted.single, ('Người thân', Relation.grandmother));
      expect(container.read(selectedBabyIdProvider), teddyId);
      expect(visits.last.location, Routes.today);
      expect(
        find.text('Bạn đã cùng chăm Teddy. Đổi tên trong Gia đình.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a signed-in account keeps its name; already in the family → Hôm nay',
    (tester) async {
      final live = ValueNotifier<Session>(
        SessionSignedIn(
          user: FakeUser(uid: 'u_lan'),
          memberships: [lan],
        ),
      );
      final repo = _Repo(live, invitePreview());
      final auth = _Auth(live);
      final (visits, _) = await pumpRouted(
        tester,
        const InviteLinkScreen(lookup: lookup),
        overrides: _overrides(live, repo, auth),
      );
      await tester.pumpAndSettle();
      expect(auth.anonymousSignIns, 0);
      expect(repo.accepted.single.$1, 'Cô Lan');
      expect(visits.last.location, Routes.today);

      final again = _Repo(
        live,
        ValidInvite(
          babyNickname: 'Teddy',
          inviterName: 'Mai',
          inviterRelation: Relation.mother,
          inviterRelationCustom: null,
          role: MemberRole.caregiver,
          relation: Relation.nanny,
          relationCustom: null,
          extraRights: null,
          expiresAt: DateTime.now().add(const Duration(days: 2)),
          alreadyMember: true,
        ),
      );
      final (visits2, _) = await pumpRouted(
        tester,
        const InviteLinkScreen(lookup: lookup),
        overrides: _overrides(live, again, auth),
      );
      await tester.pumpAndSettle();
      expect(again.accepted, isEmpty);
      expect(visits2.last.location, Routes.today);
    },
  );

  testWidgets('a closed invite says why (17)', (tester) async {
    final live = ValueNotifier<Session>(const SessionSignedOut());
    final repo = _Repo(live, const ClosedInvite(InviteClosedReason.expired));
    final (visits, _) = await pumpRouted(
      tester,
      const InviteLinkScreen(lookup: lookup),
      overrides: _overrides(live, repo, _Auth(live)),
    );
    await tester.pumpAndSettle();
    expect(repo.accepted, isEmpty);
    expect(visits.last.location, '${Routes.joinClosed}?reason=expired');
  });

  testWidgets('offline: the usual 16 Nhận lời mời screen to retry by hand', (
    tester,
  ) async {
    final live = ValueNotifier<Session>(const SessionSignedOut());
    final repo = _Repo(live, invitePreview(), failFirst: true);
    await pumpRouted(
      tester,
      const InviteLinkScreen(lookup: lookup),
      overrides: _overrides(live, repo, _Auth(live)),
    );
    await tester.pumpAndSettle();
    expect(repo.accepted, isEmpty);
    expect(find.text('Mẹ Mai mời bạn'), findsOneWidget);
  });
}
