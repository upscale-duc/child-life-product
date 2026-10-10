import 'package:child_life/app/session.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// S3 fixtures: the Figma family of Teddy (Mai, Minh, Cô Lan, Bà nội Hoa) and Bà ngoại's
/// pending invite. Times are relative to now so countdowns and ages render the same every day.
class FakeUser extends Fake implements User {
  FakeUser({this.uid = 'u_mai', this.isAnonymous = false});

  @override
  final String uid;
  @override
  final bool isAnonymous;
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => const [];
  @override
  String? get displayName => null;
}

const teddyId = 'b_00000000000000000001';

final teddy = Baby(
  id: teddyId,
  familyId: 'f_1',
  ownerUid: 'u_mai',
  nickname: 'Teddy',
  avatar: const PresetAvatar(1),
  trackers: const [
    TrackerKind.bottle,
    TrackerKind.breast,
    TrackerKind.sleep,
    TrackerKind.diaper,
  ],
  timeZone: const TimeZoneSetting(zone: 'Asia/Ho_Chi_Minh', auto: true),
);

/// "Teddy · 3 tuần".
BabyPrivateProfile teddyProfile() => BabyPrivateProfile(
  dateOfBirth: DateTime.now().subtract(const Duration(days: 22)),
  gender: Gender.boy,
);

Membership member(
  String uid,
  String name,
  MemberRole role,
  Relation relation, {
  bool owner = false,
  String? custom,
  ExtraRights extra = ExtraRights.none,
  DateTime? accessUntil,
}) => Membership(
  babyId: teddyId,
  uid: uid,
  role: role,
  relation: relation,
  relationCustom: custom,
  displayName: name,
  status: MembershipStatus.active,
  isOwner: owner,
  extraRights: extra,
  accessUntil: accessUntil,
  joinedAt: DateTime(2026, 9, 20),
);

final mai = member(
  'u_mai',
  'Mai',
  MemberRole.coParent,
  Relation.mother,
  owner: true,
);
final minh = member('u_minh', 'Minh', MemberRole.coParent, Relation.father);
final lan = member(
  'u_lan',
  'Cô Lan',
  MemberRole.caregiver,
  Relation.nanny,
  accessUntil: DateTime(2026, 12, 31),
);
final hoa = member(
  'u_hoa',
  'Bà nội Hoa',
  MemberRole.relative,
  Relation.grandmother,
  extra: const ExtraRights(viewBabyInfo: true),
);

final pendingGrandma = PendingInvite(
  inviteId: 'i_00000000000000000001',
  relation: Relation.other,
  relationCustom: 'Bà ngoại',
  role: MemberRole.caregiver,
  extraRights: null,
  code: '482913',
  token: 'AbCdEfGhIjKlMnOpQrStUvWxYz012345',
  recipientEmail: 'ba.ngoai@gmail.com',
  expiresAt: DateTime(2030, 10, 15, 12),
);

InviteTicket ticket() => InviteTicket(
  inviteId: 'i_00000000000000000002',
  code: '482913',
  token: 'AbCdEfGhIjKlMnOpQrStUvWxYz012345',
  expiresAt: DateTime.now().add(const Duration(days: 7, minutes: -1)),
);

ValidInvite invitePreview({
  MemberRole role = MemberRole.caregiver,
  Relation relation = Relation.grandmother,
}) => ValidInvite(
  babyNickname: 'Teddy',
  inviterName: 'Mai',
  inviterRelation: Relation.mother,
  inviterRelationCustom: null,
  role: role,
  relation: relation,
  relationCustom: null,
  extraRights: null,
  expiresAt: DateTime.now().add(const Duration(hours: 68, minutes: 30)),
  alreadyMember: false,
);

/// Signed in as [me] with Teddy selected; the family list and pending invites are fixed.
List<Override> familyOverrides({
  Membership? me,
  bool anonymous = false,
  List<Membership>? members,
  List<PendingInvite>? pending,
}) {
  final self = me ?? mai;
  return [
    sessionProvider.overrideWithValue(
      SessionSignedIn(
        user: FakeUser(uid: self.uid, isAnonymous: anonymous),
        memberships: [self],
      ),
    ),
    babyProvider.overrideWith((ref, id) => Stream.value(teddy)),
    babyPrivateProfileProvider.overrideWith(
      (ref, id) => Stream.value(teddyProfile()),
    ),
    familyMembersProvider.overrideWith(
      (ref, id) => Stream.value(members ?? [mai, minh, lan, hoa]),
    ),
    pendingInvitesProvider.overrideWith(
      (ref, id) => Stream.value(pending ?? [pendingGrandma]),
    ),
  ];
}
