import 'package:child_life/app/session.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/reminders/device_identity.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/reminders/rule_models.dart';
import 'package:child_life/features/reminders/rule_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'reminder_fixtures.dart';

/// S3 fixtures: the Figma family of Teddy (Mai, Minh, Cô Lan, Bà nội Hoa) and Bà ngoại's
/// pending invite. Times are relative to now so countdowns and ages render the same every day.
class FakeUser extends Fake implements User {
  FakeUser({
    this.uid = 'u_mai',
    this.isAnonymous = false,
    this.email,
    this.providers = const [],
  });

  @override
  final String uid;
  @override
  final bool isAnonymous;
  @override
  final String? email;

  /// Provider ids ("password", "apple.com") for 13n.
  final List<String> providers;
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => [
    for (final p in providers) _FakeUserInfo(p),
  ];
  @override
  String? get displayName => null;
}

class _FakeUserInfo extends Fake implements UserInfo {
  _FakeUserInfo(this.providerId);
  @override
  final String providerId;
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
BabyPrivateProfile teddyProfile() =>
    BabyPrivateProfile(dateOfBirth: DateTime(2026, 9, 17), gender: Gender.boy);

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
  List<CareRecord> records = const [],
  List<CareRecord> growth = const [],
  bool online = true,
  DateTime? now,
  Map<TimerType, CareTimer> timers = const {},
  List<SleepConflict> conflicts = const [],
  List<Reminder> reminders = const [],
  ReminderRepository? reminderRepo,
  List<ReminderRule> rules = const [],
  RuleRepository? ruleRepo,
  Map<String, List<RuleOccurrence>> occurrences = const {},
  ReminderNotifications? notifications,
  String deviceId = testDeviceId,
  NotificationPrefs prefs = const NotificationPrefs(),
  AccountDoc account = const AccountDoc(),
  String? email,
  List<String> providers = const [],
}) {
  final self = me ?? mai;
  return [
    // S11 account documents (no Firebase in widget tests).
    notificationPrefsProvider.overrideWith((ref, uid) => Stream.value(prefs)),
    accountDocProvider.overrideWith((ref, uid) => Stream.value(account)),
    sessionProvider.overrideWithValue(
      SessionSignedIn(
        user: FakeUser(
          uid: self.uid,
          isAnonymous: anonymous,
          email: email,
          providers: providers,
        ),
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
    recentRecordsProvider.overrideWith((ref, id) => Stream.value(records)),
    growthRecordsProvider.overrideWith((ref, id) => Stream.value(growth)),
    onlineProvider.overrideWith((ref) => Stream.value(online)),
    careClockProvider.overrideWith(
      (ref) => Stream.value(now ?? DateTime.now()),
    ),
    careTimerProvider.overrideWith((ref, key) => Stream.value(timers[key.$2])),
    openConflictsProvider.overrideWith((ref, id) => Stream.value(conflicts)),
    timerClockProvider.overrideWithValue(() => now ?? DateTime.now()),
    timerTicksProvider.overrideWithValue(false),
    remindersProvider.overrideWith((ref, id) => Stream.value(reminders)),
    reminderRepositoryProvider.overrideWithValue(
      reminderRepo ?? FakeReminderRepository(),
    ),
    // v1.0 rule reminders (D-051).
    reminderRulesProvider.overrideWith((ref, id) => Stream.value(rules)),
    ruleOccurrencesProvider.overrideWith(
      (ref, key) => Stream.value(occurrences[key.$2] ?? const []),
    ),
    ruleRepositoryProvider.overrideWithValue(ruleRepo ?? FakeRuleRepository()),
    reminderNotificationsProvider.overrideWithValue(
      notifications ?? FakeReminderNotifications(),
    ),
    deviceIdentityProvider.overrideWith(
      (ref) async => DeviceIdentity(id: deviceId, label: 'iPhone'),
    ),
  ];
}

/// Records what the rule screens ask the Functions for.
class FakeRuleRepository implements RuleRepository {
  final saved = <RuleDraft>[];
  final toggled = <(String, bool)>[];
  final deleted = <String>[];
  final answers = <({String ruleId, DateTime dueAt, int? snooze})>[];

  /// What `answer` reports (false = someone already handled it).
  bool answerDone = true;

  @override
  Future<DateTime?> save(String babyId, RuleDraft draft) async {
    saved.add(draft);
    return null;
  }

  @override
  Future<void> setEnabled(String babyId, String ruleId, bool enabled) async {
    toggled.add((ruleId, enabled));
  }

  @override
  Future<void> delete(String babyId, String ruleId) async =>
      deleted.add(ruleId);

  @override
  Future<bool> answer(
    String babyId,
    String ruleId,
    DateTime dueAt, {
    int? snoozeMinutes,
  }) async {
    answers.add((ruleId: ruleId, dueAt: dueAt, snooze: snoozeMinutes));
    return answerDone;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
