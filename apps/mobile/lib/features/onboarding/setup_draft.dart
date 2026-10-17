import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';

/// Answers collected on 10a → 11 → 12 before one `createBabyProfile` call. Kept in memory: if the
/// app is killed mid-setup the user starts again at 10a (nothing was created yet).
@immutable
class SetupDraft {
  SetupDraft({
    this.displayName = '',
    this.relation = Relation.mother,
    this.relationCustom = '',
    this.nickname = '',
    DateTime? dateOfBirth,
    this.gender = Gender.unspecified,
    this.timeZone,
    this.country,
    this.avatarPreset = 1,
    this.avatarPhoto,
    this.trackers = defaultTrackers,
    String? requestId,
  }) : dateOfBirth = dateOfBirth ?? _today(),
       requestId = requestId ?? const Uuid().v4();

  /// Bú bình, Bú mẹ, Giấc ngủ, Thay tã on; Hút sữa, Tăng trưởng off (29:795).
  static const defaultTrackers = {
    TrackerKind.bottle,
    TrackerKind.breast,
    TrackerKind.sleep,
    TrackerKind.diaper,
  };

  final String displayName;
  final Relation relation;
  final String relationCustom;
  final String nickname;

  /// Default = today (DateWheel 37:301).
  final DateTime dateOfBirth;
  final Gender gender;

  /// null until the device zone has been read.
  final TimeZoneSetting? timeZone;

  /// Where the family lives (D-078), null until picked or preselected from the zone.
  final String? country;
  final int avatarPreset;

  /// JPEG chosen on 11c; uploaded right after the baby exists.
  final Uint8List? avatarPhoto;
  final Set<TrackerKind> trackers;

  /// Stable across retries so a lost response never creates a second baby.
  final String requestId;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get whoComplete =>
      displayName.trim().isNotEmpty &&
      (relation != Relation.other || relationCustom.trim().isNotEmpty);

  SetupDraft copyWith({
    String? displayName,
    Relation? relation,
    String? relationCustom,
    String? nickname,
    DateTime? dateOfBirth,
    Gender? gender,
    TimeZoneSetting? timeZone,
    String? country,
    int? avatarPreset,
    Uint8List? avatarPhoto,
    bool clearPhoto = false,
    Set<TrackerKind>? trackers,
  }) => SetupDraft(
    displayName: displayName ?? this.displayName,
    relation: relation ?? this.relation,
    relationCustom: relationCustom ?? this.relationCustom,
    nickname: nickname ?? this.nickname,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    timeZone: timeZone ?? this.timeZone,
    country: country ?? this.country,
    avatarPreset: avatarPreset ?? this.avatarPreset,
    avatarPhoto: clearPhoto ? null : avatarPhoto ?? this.avatarPhoto,
    trackers: trackers ?? this.trackers,
    requestId: requestId,
  );

  NewBabyInput toInput() => NewBabyInput(
    requestId: requestId,
    nickname: nickname,
    dateOfBirth: dateOfBirth,
    gender: gender,
    timeZone:
        timeZone ?? const TimeZoneSetting(zone: 'Asia/Ho_Chi_Minh', auto: true),
    country: country,
    avatarPreset: avatarPreset,
    trackers: trackers,
    displayName: displayName,
    relation: relation,
    relationCustom: relation == Relation.other ? relationCustom : null,
  );
}

final setupDraftProvider = NotifierProvider<SetupDraftController, SetupDraft>(
  SetupDraftController.new,
);

class SetupDraftController extends Notifier<SetupDraft> {
  @override
  SetupDraft build() => SetupDraft();

  // ignore: use_setters_to_change_properties
  void update(SetupDraft next) => state = next;

  void reset() => state = SetupDraft();
}
