import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/join_screens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// FJ-1 / FJ-2 / FJ-5: an invite that cannot be read is not a closed one; a full family is said
// to the joiner in the joiner's words.

const _lookup = InviteLookup.code('482913');

class _Repo extends Fake implements FamilyRepository {
  _Repo(this.answers);

  /// One answer per preview call: an [InvitePreview] or a [FamilyException] to throw.
  final List<Object> answers;
  var accepts = 0;
  FamilyFailure? acceptFails;

  @override
  Future<InvitePreview> previewInvite(InviteLookup lookup) async {
    final answer = answers.length > 1 ? answers.removeAt(0) : answers.single;
    if (answer is FamilyException) throw answer;
    return answer as InvitePreview;
  }

  @override
  Future<String> acceptInvite({
    required InviteLookup lookup,
    required String displayName,
    required Relation relation,
    String? relationCustom,
  }) async {
    accepts++;
    throw FamilyException(acceptFails!);
  }
}

void main() {
  final signedOut = sessionProvider.overrideWithValue(const SessionSignedOut());

  testWidgets(
    'offline: "Chưa mở được lời mời" with Thử lại, never "Không tìm thấy"',
    (tester) async {
      final repo = _Repo([
        const FamilyException(FamilyFailure.network),
        invitePreview(),
      ]);
      final (visits, _) = await pumpRouted(
        tester,
        const AcceptInviteScreen(lookup: _lookup),
        overrides: [
          signedOut,
          familyRepositoryProvider.overrideWithValue(repo),
          onlineProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa mở được lời mời'), findsOneWidget);
      expect(
        find.text('Không có mạng. Lời mời vẫn còn, kết nối rồi thử lại nhé.'),
        findsOneWidget,
      );
      expect(visits, isEmpty);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Mẹ Mai mời bạn'), findsOneWidget);
    },
  );

  testWidgets('a lockout says when to try again (FJ-5)', (tester) async {
    await pumpRouted(
      tester,
      const AcceptInviteScreen(lookup: _lookup),
      overrides: [
        signedOut,
        familyRepositoryProvider.overrideWithValue(
          _Repo([const LockedInvite(Duration(minutes: 12))]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nhập sai nhiều lần. Thử lại sau 12 phút.'),
      findsOneWidget,
    );
  });

  testWidgets('a full family is said before "Tham gia" (D-127 Q3)', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      AcceptInviteScreen(
        lookup: _lookup,
        preview: invitePreview(seatsFull: true),
      ),
      overrides: [signedOut],
    );
    await tester.pumpAndSettle();
    expect(find.text('Gia đình đã hết chỗ người ghi'), findsOneWidget);
    expect(find.text('Tham gia'), findsNothing);
  });

  testWidgets(
    'full on accept → the joiner\'s own closed reason, no loop (FJ-2)',
    (tester) async {
      final repo = _Repo([invitePreview()])
        ..acceptFails = FamilyFailure.seatsFull;
      final (visits, _) = await pumpRouted(
        tester,
        ConfirmJoinScreen(
          args: JoinArgs(lookup: _lookup, preview: invitePreview()),
        ),
        overrides: [
          sessionProvider.overrideWithValue(
            SessionSignedIn(
              user: FakeUser(uid: 'u_new', isAnonymous: true),
              memberships: const [],
            ),
          ),
          familyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.enterText(find.byType(EditableText).first, 'Hoa');
      await tester.pump();
      await tester.tap(find.text('Vào xem Teddy'));
      await tester.pumpAndSettle();
      expect(repo.accepts, 1);
      expect(visits.last.location, '${Routes.joinClosed}?reason=full');
    },
  );

  testWidgets('under an hour, the countdown counts minutes (FJ-5)', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      AcceptInviteScreen(
        lookup: _lookup,
        preview: invitePreview(
          expiresIn: const Duration(minutes: 40, seconds: 30),
        ),
      ),
      overrides: [signedOut],
    );
    await tester.pumpAndSettle();
    expect(find.text('Còn 40 phút'), findsOneWidget);
  });
}
