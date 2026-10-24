import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/features/library/library_today.dart'
    show lbWeekTeaserProvider;
import 'package:child_life/features/rhythm/rhythm_home.dart' show WeekTeaser;
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';
import 'memory_fixtures.dart';
import 'reminder_fixtures.dart';
import 'rhythm_fixtures.dart';

/// Hôm nay · cá nhân hoá (D-076 #1, #4, #8) fixtures: Teddy's family on Thứ Năm 8/10/2026 with
/// the rhythm rollout, as in rhythm_fixtures; synthetic data only.

/// Stamps `updatedAt` like the real repository, so "has personalised" can be seen.
class StampingRhythmRepository extends FakeRhythmRepository {
  StampingRhythmRepository({
    super.preferences,
    super.checkIns,
    super.home,
    super.profile,
  });

  @override
  void savePreferences(
    String uid,
    UserPreferences preferences, {
    void Function(Object error)? onError,
  }) => super.savePreferences(
    uid,
    UserPreferences.fromJson({
      ...preferences.toJson(),
      'updatedAt': '2026-10-08T03:00:00.000Z',
    }),
    onError: onError,
  );
}

/// Choices already made (in Tôi or a previous flow).
UserPreferences personalized({
  List<Interest> interests = const [Interest.sleep, Interest.milestones],
}) => UserPreferences.fromJson({
  'interests': [for (final i in interests) i.wire],
  'digestTime': '20:30',
  'quietHours': {'from': '22:00', 'to': '06:00'},
  'fewer': <String>[],
  'updatedAt': '2026-10-01T03:00:00.000Z',
});

/// Teddy's family seen by [me] with the rhythm rollout ([rhythm]) and this phone's
/// notifications ([notifications], on by default).
List<Override> hnOverrides({
  required FakeRhythmRepository repo,
  Membership? me,
  bool rhythm = true,
  bool groupA = false,
  ReminderNotifications? notifications,
  Map<String, Object?>? caps,

  /// The carousel's sources (Thư viện chăm bé / Giai đoạn, Mốc phát triển); none by default.
  List<ForBabyCard> articles = const [],
  List<ForBabyCard> milestones = const [],

  /// The current stage's teaser for "Tuần này của {bé}" (Giai đoạn của bé); none by default.
  WeekTeaser? weekTeaser,

  /// Chi tiêu (the adaptive Hôm nay's spending card); none by default.
  List<Expense> expenses = const [],
}) => [
  articleForBabyCardsProvider.overrideWith((ref, q) => articles),
  milestoneForBabyCardsProvider.overrideWith((ref, q) => milestones),
  lbWeekTeaserProvider.overrideWith((ref, q) => weekTeaser),
  ...familyOverrides(
    me: me ?? mai,
    now: rhythmNow,
    notifications: notifications ?? FakeReminderNotifications(),
    expenses: expenses,
  ),
  rhythmRepositoryProvider.overrideWithValue(repo),
  ...personalizationTestOverrides(),
  rhythmSleepRecordsProvider.overrideWith((ref, key) => Stream.value(const [])),
  memoryRepositoryProvider.overrideWithValue(FakeMemoryRepository()),
  capabilitiesProvider.overrideWith(
    (ref, babyId) async => Capabilities.fromJson(
      caps ??
          rhythmCaps(
            rhythm: rhythm,
            groupA: groupA,
            plan: groupA ? 'beta' : 'free',
          ),
    ),
  ),
];

/// What Mốc phát triển and Thư viện chăm bé will put in the carousel (559:57583's two cards).
List<ForBabyCard> sampleForBabyCards({List<String>? opened}) => [
  ForBabyCard(
    id: 'article:art_startle',
    kicker: 'Đọc 2 phút',
    title: 'Vì sao bé hay giật mình khi ngủ?',
    action: 'Đọc bài',
    icon: ClIcons.journal,
    interest: Interest.sleep,
    onOpen: (_) => opened?.add('article'),
  ),
  ForBabyCard(
    id: 'milestone:ms_head_up',
    kicker: 'Mốc có thể thấy · tuần 3–6',
    title: 'Bé ngẩng đầu khi nằm sấp',
    action: 'Ghi nhận khi bé làm được',
    tone: ForBabyTone.growth,
    interest: Interest.milestones,
    onOpen: (_) => opened?.add('milestone'),
    onDismiss: (_, _) => opened?.add('dismiss'),
  ),
];

/// Giai đoạn của bé's current stage as the "Tuần này" teaser, and its small card (which the
/// carousel then leaves out).
WeekTeaser sampleStageTeaser({List<String>? opened}) => (
  id: 'stage:stg_3_4w',
  text: 'Bé bắt đầu nhìn theo mặt người khi được bế gần',
  ideas: 3,
  onOpen: (_) => opened?.add('stage'),
);

ForBabyCard sampleStageCard() => ForBabyCard(
  id: 'stage:stg_3_4w',
  kicker: 'Giai đoạn của bé · 3–4 tuần',
  title: 'Tuần 3–4: nhìn, nghe và được ôm',
  action: 'Xem giai đoạn',
  icon: ClIcons.cake,
  tone: ForBabyTone.sunshine,
  interest: Interest.milestones,
  onOpen: (_) {},
);
