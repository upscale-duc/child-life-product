import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Mirrors `packages/contracts/src/baby.ts` (S2). Firestore documents are parsed defensively:
/// unknown values fall back instead of crashing an older app build.

/// "Theo dõi gì?" (R-010), in Figma order.
enum TrackerKind { bottle, breast, sleep, diaper, pump, growth }

/// "Giới tính · không bắt buộc" (R-009).
enum Gender { girl, boy, unspecified }

/// Relation labels (R-020), mirroring `relations` in packages/contracts/src/family.ts.
enum Relation {
  mother,
  father,
  grandmother,
  grandfather,
  nanny,
  relative,
  friend,
  other,
}

/// "Bạn là" chips on 10a and 16a (no "Bạn bè").
const selfRelations = [
  Relation.mother,
  Relation.father,
  Relation.grandmother,
  Relation.grandfather,
  Relation.nanny,
  Relation.relative,
  Relation.other,
];

/// "Người được mời là" chips on 14b ("Mẹ" absent, "Bạn bè" added).
const inviteRelations = [
  Relation.father,
  Relation.grandmother,
  Relation.grandfather,
  Relation.nanny,
  Relation.relative,
  Relation.friend,
  Relation.other,
];

enum MemberRole { coParent, caregiver, relative }

enum MembershipStatus { active, removed, expired, left, merged }

/// 14b2: what a relative may see beyond shared memories (D-019: both off by default).
@immutable
class ExtraRights {
  const ExtraRights({this.viewBabyInfo = false, this.viewDailyCare = false});

  /// "Thông tin bé · Ngày sinh, cân nặng".
  final bool viewBabyInfo;

  /// "Chăm sóc hằng ngày · Bú, ngủ, tã · chỉ xem" (read-only Today, D-018).
  final bool viewDailyCare;

  static const none = ExtraRights();

  factory ExtraRights.fromJson(Object? json) => json is Map
      ? ExtraRights(
          viewBabyInfo: json['viewBabyInfo'] == true,
          viewDailyCare: json['viewDailyCare'] == true,
        )
      : none;

  Map<String, bool> toJson() => {
    'viewBabyInfo': viewBabyInfo,
    'viewDailyCare': viewDailyCare,
  };

  ExtraRights copyWith({bool? viewBabyInfo, bool? viewDailyCare}) =>
      ExtraRights(
        viewBabyInfo: viewBabyInfo ?? this.viewBabyInfo,
        viewDailyCare: viewDailyCare ?? this.viewDailyCare,
      );

  @override
  bool operator ==(Object other) =>
      other is ExtraRights &&
      other.viewBabyInfo == viewBabyInfo &&
      other.viewDailyCare == viewDailyCare;
  @override
  int get hashCode => Object.hash(viewBabyInfo, viewDailyCare);
}

/// Each account creates at most 3 baby profiles (R-043).
const maxOwnedBabies = 3;
const nicknameMaxLength = 30;
const displayNameMaxLength = 40;
const relationCustomMaxLength = 24;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

/// Avatar: one of 4 illustrated presets (11c) or a family-private photo.
@immutable
sealed class BabyAvatar {
  const BabyAvatar();

  factory BabyAvatar.fromJson(Object? json) {
    if (json is Map && json['kind'] == 'photo' && json['version'] is int) {
      return PhotoAvatar(json['version'] as int);
    }
    final preset = json is Map ? json['preset'] : null;
    return PresetAvatar(
      preset is int && preset >= 1 && preset <= 4 ? preset : 1,
    );
  }
}

class PresetAvatar extends BabyAvatar {
  const PresetAvatar(this.preset);
  final int preset;

  @override
  bool operator ==(Object other) =>
      other is PresetAvatar && other.preset == preset;
  @override
  int get hashCode => preset.hashCode;
}

class PhotoAvatar extends BabyAvatar {
  const PhotoAvatar(this.version);
  final int version;

  @override
  bool operator ==(Object other) =>
      other is PhotoAvatar && other.version == version;
  @override
  int get hashCode => version.hashCode;
}

/// IANA zone (P-014) and whether it follows the device ("Tự động theo máy").
@immutable
class TimeZoneSetting {
  const TimeZoneSetting({required this.zone, required this.auto});
  final String zone;
  final bool auto;

  Map<String, Object> toJson() => {
    'mode': auto ? 'auto' : 'manual',
    'zone': zone,
  };

  factory TimeZoneSetting.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return TimeZoneSetting(
      zone: map['zone'] is String ? map['zone'] as String : 'Asia/Ho_Chi_Minh',
      auto: map['mode'] != 'manual',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimeZoneSetting && other.zone == zone && other.auto == auto;
  @override
  int get hashCode => Object.hash(zone, auto);
}

/// Member-visible profile (`babies/{id}`).
@immutable
class Baby {
  const Baby({
    required this.id,
    required this.familyId,
    required this.ownerUid,
    required this.nickname,
    required this.avatar,
    required this.trackers,
    required this.timeZone,
  });

  final String id;
  final String familyId;
  final String ownerUid;
  final String nickname;
  final BabyAvatar avatar;
  final List<TrackerKind> trackers;
  final TimeZoneSetting timeZone;

  factory Baby.fromJson(String id, Map<String, Object?> json) => Baby(
    id: id,
    familyId: json['familyId'] as String? ?? '',
    ownerUid: json['ownerUid'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    avatar: BabyAvatar.fromJson(json['avatar']),
    trackers: [
      for (final t in (json['trackers'] as List?) ?? const [])
        ?TrackerKind.values.where((k) => k.name == t).firstOrNull,
    ],
    timeZone: TimeZoneSetting.fromJson(json['timeZone']),
  );
}

/// Restricted profile (`babies/{id}/restricted/profile`): Cùng nuôi and relatives with
/// viewBabyInfo only (business map §5).
@immutable
class BabyPrivateProfile {
  const BabyPrivateProfile({required this.dateOfBirth, required this.gender});
  final DateTime dateOfBirth;
  final Gender gender;

  factory BabyPrivateProfile.fromJson(Map<String, Object?> json) =>
      BabyPrivateProfile(
        dateOfBirth:
            DateTime.tryParse(json['dateOfBirth'] as String? ?? '') ??
            DateTime(2000),
        gender: _enumByName(Gender.values, json['gender'], Gender.unspecified),
      );
}

/// A membership on one baby (`babies/{id}/members/{uid}`): the caller's own ("my babies") or
/// another member on the Family tab (14a).
@immutable
class Membership {
  const Membership({
    required this.babyId,
    required this.role,
    required this.relation,
    required this.relationCustom,
    required this.displayName,
    required this.status,
    required this.isOwner,
    this.uid = '',
    this.extraRights = ExtraRights.none,
    this.accessUntil,
    this.accessUntilAt,
    this.joinedAt,
  });

  final String babyId;
  final String uid;
  final MemberRole role;
  final Relation relation;
  final String? relationCustom;
  final String displayName;
  final MembershipStatus status;
  final bool isOwner;
  final ExtraRights extraRights;

  /// "Thời hạn" (R-024): last day of access in the baby's calendar, and the instant it ends.
  final DateTime? accessUntil;
  final DateTime? accessUntilAt;
  final DateTime? joinedAt;

  /// Active and not past its access end date (Rules deny at once, before the hourly job).
  bool isActiveAt(DateTime now) =>
      status == MembershipStatus.active &&
      (accessUntilAt == null || accessUntilAt!.isAfter(now));

  bool get isActive => isActiveAt(DateTime.now());

  /// Relatives see Today read-only when granted "Chăm sóc hằng ngày" (D-018).
  bool get canViewToday =>
      role != MemberRole.relative || extraRights.viewDailyCare;

  /// DOB and gender: Cùng nuôi, or relatives granted "Thông tin bé" (Rules, §5).
  bool get canViewBabyInfo =>
      role == MemberRole.coParent ||
      (role == MemberRole.relative && extraRights.viewBabyInfo);

  factory Membership.fromJson(Map<String, Object?> json) => Membership(
    babyId: json['babyId'] as String? ?? '',
    uid: json['uid'] as String? ?? '',
    role: _enumByName(MemberRole.values, json['role'], MemberRole.relative),
    relation: _enumByName(Relation.values, json['relation'], Relation.other),
    relationCustom: json['relationCustom'] as String?,
    displayName: json['displayName'] as String? ?? '',
    status: _enumByName(
      MembershipStatus.values,
      json['status'],
      MembershipStatus.removed,
    ),
    isOwner: json['isOwner'] == true,
    extraRights: ExtraRights.fromJson(json['extraRights']),
    accessUntil: DateTime.tryParse(json['accessUntil'] as String? ?? ''),
    accessUntilAt: dateOf(json['accessUntilAt']),
    joinedAt: dateOf(json['joinedAt']),
  );
}

/// Firestore Timestamp, DateTime or ISO string → DateTime.
DateTime? dateOf(Object? value) => switch (value) {
  Timestamp() => value.toDate(),
  DateTime() => value,
  String() => DateTime.tryParse(value),
  _ => null,
};

/// Everything collected by 10a → 11 → 12 before `createBabyProfile`.
@immutable
class NewBabyInput {
  const NewBabyInput({
    required this.requestId,
    required this.nickname,
    required this.dateOfBirth,
    required this.gender,
    required this.timeZone,
    required this.avatarPreset,
    required this.trackers,
    required this.displayName,
    required this.relation,
    this.relationCustom,
  });

  final String requestId;
  final String nickname;
  final DateTime dateOfBirth;
  final Gender gender;
  final TimeZoneSetting timeZone;
  final int avatarPreset;
  final Set<TrackerKind> trackers;
  final String displayName;
  final Relation relation;
  final String? relationCustom;

  Map<String, Object> toJson() => {
    'requestId': requestId,
    'nickname': nickname.trim(),
    'dateOfBirth': isoDate(dateOfBirth),
    'gender': gender.name,
    'timeZone': timeZone.toJson(),
    'avatarPreset': avatarPreset,
    // Keep Figma order so Today tiles are stable.
    'trackers': [
      for (final t in TrackerKind.values)
        if (trackers.contains(t)) t.name,
    ],
    'self': {
      'displayName': displayName.trim(),
      'relation': relation.name,
      if (relation == Relation.other)
        'relationCustom': (relationCustom ?? '').trim(),
    },
  };
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
