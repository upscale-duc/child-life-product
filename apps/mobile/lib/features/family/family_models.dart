import 'package:flutter/foundation.dart';

import '../baby/baby_models.dart';

/// Mirrors `packages/contracts/src/family.ts` (S3): invites, previews and pending rows.

/// Invites last 7 days ("Hết hạn sau 7 ngày", R-032).
const inviteTtlDays = 7;

/// By 6-digit code (15), link token (`/i/{token}`, QR), or id for an invite mailed to me (no
/// code to type; owner, 2026-10-11).
@immutable
class InviteLookup {
  const InviteLookup.code(String this.code) : token = null, inviteId = null;
  const InviteLookup.token(String this.token) : code = null, inviteId = null;
  const InviteLookup.id(String this.inviteId) : code = null, token = null;

  final String? code;
  final String? token;
  final String? inviteId;

  Map<String, String> toJson() => code != null
      ? {'code': code!}
      : token != null
      ? {'token': token!}
      : {'inviteId': inviteId!};

  static final _code = RegExp(r'^\d{6}$');
  static final _token = RegExp(r'^[A-Za-z0-9_-]{32}$');

  /// What a QR scan or pasted text means: an invite link (`…/i/{token}`) or a 6-digit code.
  /// Only links on [allowedHosts] are trusted, so a look-alike site cannot pose as an invite.
  static InviteLookup? parse(String raw, {required Set<String> allowedHosts}) {
    final text = raw.trim();
    final digits = text.replaceAll(RegExp(r'\s'), '');
    if (_code.hasMatch(digits)) return InviteLookup.code(digits);
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != 'https' ||
        !allowedHosts.contains(uri.host)) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 2 &&
        segments.first == 'i' &&
        _token.hasMatch(segments[1])) {
      return InviteLookup.token(segments[1]);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is InviteLookup &&
      other.code == code &&
      other.token == token &&
      other.inviteId == inviteId;
  @override
  int get hashCode => Object.hash(code, token, inviteId);
}

/// An invite mailed to my own email: shown to accept or decline without the code.
@immutable
class MyInvite {
  const MyInvite({required this.inviteId, required this.preview});
  final String inviteId;
  final ValidInvite preview;

  factory MyInvite.fromJson(Map<String, Object?> json) => MyInvite(
    inviteId: json['inviteId']! as String,
    preview:
        InvitePreview.fromJson({...json, 'status': 'valid'}) as ValidInvite,
  );
}

/// What the inviter needs on 14c: code, link token, expiry.
@immutable
class InviteTicket {
  const InviteTicket({
    required this.inviteId,
    required this.code,
    required this.token,
    required this.expiresAt,
  });

  final String inviteId;
  final String code;
  final String token;
  final DateTime expiresAt;

  factory InviteTicket.fromJson(Map<String, Object?> json) => InviteTicket(
    inviteId: json['inviteId'] as String,
    code: json['code'] as String,
    token: json['token'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  String link(String webOrigin) => '$webOrigin/i/$token';
}

/// Who and what an invite is for (14b), shown again on 14c / 14d.
@immutable
class InviteDraft {
  const InviteDraft({
    required this.relation,
    required this.role,
    this.relationCustom,
    this.extraRights,
  });

  final Relation relation;
  final String? relationCustom;
  final MemberRole role;

  /// Relatives only (14b2).
  final ExtraRights? extraRights;
}

/// "Đang chờ nhận lời" row (`babies/{b}/pendingInvites/{id}`, Cùng nuôi only).
@immutable
class PendingInvite {
  const PendingInvite({
    required this.inviteId,
    required this.relation,
    required this.relationCustom,
    required this.role,
    required this.extraRights,
    required this.code,
    required this.token,
    required this.recipientEmail,
    required this.expiresAt,
  });

  final String inviteId;
  final Relation relation;
  final String? relationCustom;
  final MemberRole role;
  final ExtraRights? extraRights;
  final String code;
  final String token;
  final String? recipientEmail;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  InviteTicket get ticket => InviteTicket(
    inviteId: inviteId,
    code: code,
    token: token,
    expiresAt: expiresAt,
  );

  InviteDraft get draft => InviteDraft(
    relation: relation,
    relationCustom: relationCustom,
    role: role,
    extraRights: extraRights,
  );

  factory PendingInvite.fromJson(Map<String, Object?> json) => PendingInvite(
    inviteId: json['inviteId'] as String? ?? '',
    relation: Relation.values.asNameMap()[json['relation']] ?? Relation.other,
    relationCustom: json['relationCustom'] as String?,
    role: MemberRole.values.asNameMap()[json['role']] ?? MemberRole.relative,
    extraRights: json['extraRights'] == null
        ? null
        : ExtraRights.fromJson(json['extraRights']),
    code: json['code'] as String? ?? '',
    token: json['token'] as String? ?? '',
    recipientEmail: json['recipientEmail'] as String?,
    expiresAt:
        dateOf(json['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// 16 "Mẹ Mai mời bạn…" — the invite as the invitee sees it before joining.
@immutable
sealed class InvitePreview {
  const InvitePreview();

  factory InvitePreview.fromJson(Map<String, Object?> json) {
    switch (json['status']) {
      case 'valid':
        return ValidInvite(
          babyNickname: json['babyNickname'] as String? ?? '',
          inviterName: json['inviterName'] as String? ?? '',
          inviterRelation:
              Relation.values.asNameMap()[json['inviterRelation']] ??
              Relation.other,
          inviterRelationCustom: json['inviterRelationCustom'] as String?,
          role:
              MemberRole.values.asNameMap()[json['role']] ??
              MemberRole.relative,
          relation:
              Relation.values.asNameMap()[json['relation']] ?? Relation.other,
          relationCustom: json['relationCustom'] as String?,
          extraRights: json['extraRights'] == null
              ? null
              : ExtraRights.fromJson(json['extraRights']),
          expiresAt: DateTime.parse(json['expiresAt'] as String),
          alreadyMember: json['alreadyMember'] == true,
        );
      case 'locked':
        return LockedInvite(
          Duration(
            seconds: (json['retryAfterSeconds'] as num?)?.toInt() ?? 900,
          ),
        );
      default:
        return ClosedInvite(InviteClosedReason.fromStatus(json['status']));
    }
  }
}

class ValidInvite extends InvitePreview {
  const ValidInvite({
    required this.babyNickname,
    required this.inviterName,
    required this.inviterRelation,
    required this.inviterRelationCustom,
    required this.role,
    required this.relation,
    required this.relationCustom,
    required this.extraRights,
    required this.expiresAt,
    required this.alreadyMember,
  });

  final String babyNickname;
  final String inviterName;
  final Relation inviterRelation;
  final String? inviterRelationCustom;
  final MemberRole role;
  final Relation relation;
  final String? relationCustom;
  final ExtraRights? extraRights;
  final DateTime expiresAt;

  /// The caller already belongs to this baby (G-036).
  final bool alreadyMember;
}

/// 17 and its undrawn siblings (G-035).
enum InviteClosedReason {
  expired,
  revoked,
  used,
  notFound;

  static InviteClosedReason fromStatus(Object? status) => switch (status) {
    'expired' => expired,
    'revoked' => revoked,
    'used' => used,
    _ => notFound,
  };
}

class ClosedInvite extends InvitePreview {
  const ClosedInvite(this.reason);
  final InviteClosedReason reason;
}

/// P-021: too many wrong codes from this account or network.
class LockedInvite extends InvitePreview {
  const LockedInvite(this.retryAfter);
  final Duration retryAfter;
}
