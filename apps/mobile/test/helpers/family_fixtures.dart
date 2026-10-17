import 'dart:typed_data';

import 'package:child_life/app/session.dart';
import 'package:child_life/features/keepsakes/keepsake_nudges.dart';
import 'package:child_life/features/milestones/milestone_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/my_invites.dart';
import 'package:child_life/features/reminders/device_identity.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/notifications/notification_repository.dart';
import 'package:child_life/features/reminders/rule_models.dart';
import 'package:child_life/features/reminders/rule_repository.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/features/spending/spending_repository.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/first_aid/first_aid_models.dart';
import 'package:child_life/features/first_aid/first_aid_modes.dart';
import 'package:child_life/features/first_aid/first_aid_repository.dart';
import 'package:child_life/features/vaccines/vaccine_photos.dart';
import 'package:child_life/features/vaccines/vaccine_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'first_aid_fixtures.dart';
import 'milestone_fixtures.dart';
import 'notification_fixtures.dart';
import 'reminder_fixtures.dart';
import 'spending_fixtures.dart';

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

/// Mailed to me by Mẹ Hà for bé Bin: answered from Gia đình / Hôm nay (owner, 2026-10-11).
final binInvite = MyInvite(
  inviteId: 'i_00000000000000000009',
  preview: ValidInvite(
    babyNickname: 'Bin',
    inviterName: 'Hà',
    inviterRelation: Relation.mother,
    inviterRelationCustom: null,
    role: MemberRole.coParent,
    relation: Relation.mother,
    relationCustom: null,
    extraRights: null,
    expiresAt: DateTime.utc(2026, 10, 15, 5),
    alreadyMember: false,
  ),
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
  Map<String, VaccineDoseRecord> vaccines = const {},
  VaccinePlan vaccinePlan = const VaccinePlan(),
  VaccineRepository? vaccineRepo,
  VaccinePhotoStore? vaccinePhotos,
  FirstAidPack? firstAid,
  List<String> firstAidSaved = const [],
  FirstAidDevice? firstAidDevice,
  FirstAidStore? firstAidStore,
  ReminderNotifications? notifications,
  String deviceId = testDeviceId,
  NotificationPrefs prefs = const NotificationPrefs(),
  AccountDoc account = const AccountDoc(),
  String? email,
  List<String> providers = const [],
  List<MyInvite> myInvites = const [],
  List<Expense> expenses = const [],
  List<SpendingCategory> categories = const [],
  Budget budget = Budget.empty,
  List<RecurringExpense> recurring = const [],
  SpendingRepository? spendingRepo,

  /// Chi tiêu currencies (D-075 #4): the household's pick; null = not set (VND here).
  String? spendingCurrency,

  /// Kỷ niệm 2.0 milestone nudges (D-068 #9) among this device's notifications; off unless a
  /// test is about them.
  bool nudges = false,

  /// Mốc phát triển (D-076 #6): the seed and no records unless a test gives its own.
  MilestoneRepository? milestones,

  /// Hộp thông báo / EN07 (D-076 #2): empty, defaults, unless a test gives its own.
  NotificationRepository? notificationRepo,
}) {
  final self = me ?? mai;
  return [
    milestoneRepositoryProvider.overrideWithValue(
      milestones ?? FakeMilestoneRepository(),
    ),
    if (!nudges) ...[
      nudgeBabiesProvider.overrideWith((ref) => const []),
      nudgePlanReadyProvider.overrideWith((ref) => true),
    ],
    // S11 account documents (no Firebase in widget tests).
    notificationPrefsProvider.overrideWith((ref, uid) => Stream.value(prefs)),
    notificationRepositoryProvider.overrideWithValue(
      notificationRepo ?? FakeNotificationRepository(),
    ),
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
    myInvitesProvider.overrideWith((ref) async => myInvites),
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
    // Sổ tiêm chủng (P-133).
    vaccineDosesProvider.overrideWith((ref, id) => Stream.value(vaccines)),
    vaccinePlanProvider.overrideWith((ref, id) => Stream.value(vaccinePlan)),
    vaccineRepositoryProvider.overrideWithValue(
      vaccineRepo ?? FakeVaccineRepository(),
    ),
    vaccinePhotoStoreProvider.overrideWithValue(
      vaccinePhotos ?? FakeVaccinePhotoStore(),
    ),
    // Sơ cứu (D-058): no guide unless a test passes one.
    firstAidStoreProvider.overrideWithValue(
      firstAidStore ?? FakeFirstAidStore(),
    ),
    firstAidSourceProvider.overrideWith((ref) => Stream.value(firstAid)),
    firstAidSavedProvider.overrideWith((ref) => Stream.value(firstAidSaved)),
    firstAidImageProvider.overrideWithValue(fakeFirstAidImage),
    firstAidDeviceProvider.overrideWithValue(
      firstAidDevice ?? FakeFirstAidDevice(),
    ),
    // Chi tiêu (v1.1): rights filtering is the repository's job, so tests pass what one may read.
    expensesProvider.overrideWith((ref, key) => Stream.value(expenses)),
    spendingCategoriesProvider.overrideWith(
      (ref, id) => Stream.value(mergeCategories(categories)),
    ),
    budgetProvider.overrideWith((ref, id) => Stream.value(budget)),
    recurringExpensesProvider.overrideWith(
      (ref, id) => Stream.value(recurring),
    ),
    spendingRepositoryProvider.overrideWithValue(
      spendingRepo ?? FakeSpendingRepository(),
    ),
    spendingSettingsProvider.overrideWith(
      (ref, id) => Stream.value(SpendingSettings(currency: spendingCurrency)),
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

/// Photos of the book without a camera or Storage: every pick is a tiny JPEG-named PNG.
class FakeVaccinePhotoStore implements VaccinePhotoStore {
  final uploaded = <String>[];
  final removed = <String>[];
  bool cancel = false;

  @override
  Future<Uint8List?> pick(ImageSource source) async =>
      cancel ? null : Uint8List.fromList(const [0xff, 0xd8, 0xff]);

  @override
  Future<String> upload(
    String babyId,
    Uint8List jpeg, {
    String folder = 'vaccines',
  }) async {
    final path =
        'babies/$babyId/$folder/photo${uploaded.length + 1}0000000000.jpg';
    uploaded.add(path);
    return path;
  }

  @override
  Future<void> remove(String path) async => removed.add(path);
}

/// Records what the vaccination screens write.
class FakeVaccineRepository implements VaccineRepository {
  final saved =
      <
        ({
          String key,
          DoseRecordStatus status,
          DateTime? givenOn,
          VaccinePlace? place,
          DateTime? plannedOn,
          String? reason,
          String? photoPath,
          bool clearPhoto,
        })
      >[];
  final deleted = <String>[];
  final plans = <VaccinePlan>[];
  final setups = <List<String>>[];

  @override
  void save({
    required String babyId,
    required Membership me,
    required DoseItem item,
    required DoseRecordStatus status,
    DateTime? givenOn,
    String? givenTime,
    VaccinePlace? place,
    String? facility,
    String? reaction,
    String? declineReason,
    DateTime? plannedOn,
    String? photoPath,
    bool clearPhoto = false,
    void Function(Object error)? onError,
  }) => saved.add((
    key: item.key,
    status: status,
    givenOn: givenOn,
    place: place,
    plannedOn: plannedOn,
    reason: declineReason,
    photoPath: photoPath,
    clearPhoto: clearPhoto,
  ));

  @override
  void saveSetup({
    required String babyId,
    required Membership me,
    required List<DoseItem> items,
    required VaccinePlan plan,
    void Function(Object error)? onError,
  }) {
    setups.add([for (final i in items) i.key]);
    plans.add(plan.copyWith(setupDone: true));
  }

  @override
  void delete(
    String babyId,
    DoseItem item, {
    void Function(Object error)? onError,
  }) => deleted.add(item.key);

  @override
  void savePlan(
    String babyId,
    Membership me,
    VaccinePlan plan, {
    void Function(Object error)? onError,
  }) => plans.add(plan);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
