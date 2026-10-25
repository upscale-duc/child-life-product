import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import 'family_models.dart';

/// Server reasons from the family callables (firebase/functions/src/family.ts → FamilyError).
enum FamilyFailure {
  accountRequired,
  emailUnverified,
  ownerOnly,
  ownerProtected,
  notAllowed,
  alreadyMember,
  expired,
  revoked,
  used,
  notFound,
  locked,
  tooManyEmails,
  tooSoon,
  suppressed,
  dateInPast,

  /// D-101 Q-097: no writer seat left (E12 → PW05).
  seatsFull,
  network,
  other,
}

class FamilyException implements Exception {
  const FamilyException(this.failure);
  final FamilyFailure failure;

  @override
  String toString() => 'FamilyException($failure)';
}

FamilyFailure familyFailureOf(FirebaseFunctionsException e) {
  final details = e.details;
  final reason = details is Map ? details['reason'] : e.message;
  return switch (reason) {
    'account-required' => FamilyFailure.accountRequired,
    'email-unverified' => FamilyFailure.emailUnverified,
    'owner-only' => FamilyFailure.ownerOnly,
    'owner-protected' => FamilyFailure.ownerProtected,
    'not-a-member' || 'not-co-parent' || 'self' => FamilyFailure.notAllowed,
    'already-member' => FamilyFailure.alreadyMember,
    'expired' => FamilyFailure.expired,
    'revoked' || 'invite-closed' => FamilyFailure.revoked,
    'used' => FamilyFailure.used,
    'not-found' || 'baby-not-found' => FamilyFailure.notFound,
    'locked' => FamilyFailure.locked,
    'too-many-emails' => FamilyFailure.tooManyEmails,
    'too-soon' => FamilyFailure.tooSoon,
    'suppressed' => FamilyFailure.suppressed,
    'date-in-past' => FamilyFailure.dateInPast,
    'seats-full' => FamilyFailure.seatsFull,
    _ => switch (e.code) {
      'unavailable' || 'deadline-exceeded' => FamilyFailure.network,
      _ => FamilyFailure.other,
    },
  };
}

/// Family tab, invites and joining (S3). Every write goes through a callable; the client only
/// reads members and pending invites (Rules: active members / Cùng nuôi).
class FamilyRepository {
  FamilyRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>?>(data);
      return result.data ?? const {};
    } on FirebaseFunctionsException catch (e) {
      throw FamilyException(familyFailureOf(e));
    }
  }

  /// "Những người cùng chăm Teddy" (14a): active members of one baby.
  Stream<List<Membership>> watchMembers(String babyId) => _db
      .collection('babies/$babyId/members')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((s) {
        final now = DateTime.now();
        return [
          for (final d in s.docs)
            if (Membership.fromJson(d.data()) case final m
                when m.isActiveAt(now))
              m,
        ];
      });

  /// "Đang chờ nhận lời" (14a), Cùng nuôi only.
  Stream<List<PendingInvite>> watchPendingInvites(String babyId) => _db
      .collection('babies/$babyId/pendingInvites')
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) PendingInvite.fromJson(d.data())]
              ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)),
      );

  Future<InviteTicket> createInvite({
    required String requestId,
    required String babyId,
    required InviteDraft draft,
  }) async {
    final data = await _call('createFamilyInvite', {
      'requestId': requestId,
      'babyId': babyId,
      'relation': draft.relation.name,
      if (draft.relation == Relation.other)
        'relationCustom': (draft.relationCustom ?? '').trim(),
      'role': draft.role.name,
      if (draft.role == MemberRole.relative)
        'extraRights': (draft.extraRights ?? ExtraRights.none).toJson(),
    });
    return InviteTicket.fromJson(data);
  }

  /// "Tạo mã mới" (14c2): the old code and link stop working (P-020).
  Future<InviteTicket> regenerateInvite(String inviteId) async =>
      InviteTicket.fromJson(
        await _call('regenerateFamilyInvite', {'inviteId': inviteId}),
      );

  /// Cancels a pending invite (G-033).
  Future<void> revokeInvite(String inviteId) =>
      _call('revokeFamilyInvite', {'inviteId': inviteId});

  /// 14c Email tab, "Gửi lại" (R-034); delivered by AWS SES (D-020).
  Future<void> sendInviteEmail({
    required String inviteId,
    required String email,
    required String locale,
  }) => _call('emailFamilyInvite', {
    'inviteId': inviteId,
    'email': email.trim(),
    'locale': locale == 'en' ? 'en' : 'vi',
  });

  Future<InvitePreview> previewInvite(InviteLookup lookup) async =>
      InvitePreview.fromJson(
        await _call('previewFamilyInvite', lookup.toJson()),
      );

  /// Live invites mailed to my verified email, for babies I am not in.
  Future<List<MyInvite>> listMyInvites() async {
    final data = await _call('listMyFamilyInvites', const {});
    return [
      for (final i in (data['invites'] as List? ?? const []))
        MyInvite.fromJson((i as Map).cast<String, Object?>()),
    ];
  }

  /// "Từ chối": the invite closes; its code and link stop working.
  Future<void> declineInvite(String inviteId) =>
      _call('declineFamilyInvite', {'inviteId': inviteId});

  /// 16a "Vào xem Teddy". Returns the baby joined.
  Future<String> acceptInvite({
    required InviteLookup lookup,
    required String displayName,
    required Relation relation,
    String? relationCustom,
  }) async {
    final data = await _call('acceptFamilyInvite', {
      ...lookup.toJson(),
      'displayName': displayName.trim(),
      'relation': relation.name,
      if (relation == Relation.other)
        'relationCustom': (relationCustom ?? '').trim(),
    });
    return data['babyId'] as String;
  }

  /// 14f: role (and a relative's extra rights) apply immediately.
  Future<void> updateRole({
    required String babyId,
    required String uid,
    required MemberRole role,
    ExtraRights? extraRights,
  }) => _call('updateFamilyMember', {
    'babyId': babyId,
    'uid': uid,
    'role': role.name,
    // A caregiver keeps only the spending rights (D-055); Cùng nuôi have everything.
    if (role != MemberRole.coParent && extraRights != null)
      'extraRights':
          (role == MemberRole.caregiver
                  ? extraRights.copyWith(
                      viewBabyInfo: false,
                      viewDailyCare: false,
                    )
                  : extraRights)
              .toJson(),
  });

  Future<void> updateRelation({
    required String babyId,
    required String uid,
    required Relation relation,
    String? relationCustom,
  }) => _call('updateFamilyMember', {
    'babyId': babyId,
    'uid': uid,
    'relation': relation.name,
    'relationCustom': relation == Relation.other
        ? (relationCustom ?? '').trim()
        : null,
  });

  /// "Thời hạn": last day of access (baby's calendar), or null for no limit (R-024).
  Future<void> setAccessUntil({
    required String babyId,
    required String uid,
    required DateTime? lastDay,
  }) => _call('updateFamilyMember', {
    'babyId': babyId,
    'uid': uid,
    'accessUntil': lastDay == null ? null : isoDate(lastDay),
  });

  /// "Xoá Cô Lan khỏi gia đình" — records are kept (R-023).
  Future<void> removeMember({required String babyId, required String uid}) =>
      _call('removeFamilyMember', {'babyId': babyId, 'uid': uid});

  /// P-007: moves a temporary identity's memberships into the signed-in account.
  Future<void> claimAnonymous(String anonymousIdToken) =>
      _call('claimAnonymousIdentity', {'anonymousIdToken': anonymousIdToken});
}

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final familyMembersProvider = StreamProvider.family<List<Membership>, String>(
  (ref, babyId) => ref.watch(familyRepositoryProvider).watchMembers(babyId),
);

final pendingInvitesProvider =
    StreamProvider.family<List<PendingInvite>, String>(
      (ref, babyId) =>
          ref.watch(familyRepositoryProvider).watchPendingInvites(babyId),
    );
