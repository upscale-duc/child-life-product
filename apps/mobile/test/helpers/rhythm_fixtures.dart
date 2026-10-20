import 'dart:async';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/features/rhythm/personalization_v2_repository.dart';
import 'package:child_life/features/rhythm/personalization_digest.dart';
import 'package:child_life/features/rhythm/personalization_events.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'care_fixtures.dart';
import 'family_fixtures.dart';
import 'memory_fixtures.dart';

/// Nhịp lớn lên fixtures (synthetic, labelled like the dev seed: every item `review: null`).
/// "Today" is Thứ Năm 8/10/2026 as on the Figma Home frames; Teddy was born 17/09 (3 weeks)
/// with a due date of 21/09, so stage 1 of the technical fixture model (21–30 days after the
/// due date) is 12/10 – 21/10. Mock dates from the frames are not copied (extract 30 Q10).

/// 10:00 in Hồ Chí Minh, whatever the test machine's zone.
final rhythmNow = DateTime.utc(2026, 10, 8, 3);
const rhythmToday = '2026-10-08';

Map<String, Object?> _l(String vi, String en) => {'vi': vi, 'en': en};
Map<String, Object?> _ll(List<String> vi, List<String> en) => {
  'vi': vi,
  'en': en,
};

Map<String, Object?> rhythmContentJson() => {
  'version': 'rc_20261015_01',
  'publishedAt': '2026-10-15T00:00:00.000Z',
  'activities': [
    {
      'id': 'act_wind_down',
      'version': 1,
      'status': 'published',
      'title': _l(
        'Giảm kích thích 30 phút trước giấc đêm',
        'Wind down 30 minutes before night sleep',
      ),
      'summary': _l(
        'Một nếp yên tĩnh lặp lại mỗi tối giúp nhiều bé chuyển sang giấc đêm dễ hơn.',
        'A calm routine repeated each evening helps many babies move into night sleep.',
      ),
      'steps': _ll(
        [
          'Giảm đèn và tiếng ồn',
          'Tắm hoặc lau người ấm',
          'Cho bú yên tĩnh',
          'Đặt bé xuống khi buồn ngủ',
        ],
        [
          'Dim lights and noise',
          'Warm bath or wipe-down',
          'Quiet feed',
          'Put down when drowsy',
        ],
      ),
      'safety': _l(
        'Không để gối, chăn dày hay thú bông trong nôi. Luôn đặt bé nằm ngửa khi ngủ.',
        'No pillows, heavy blankets or soft toys in the cot. Always put your baby down on their back.',
      ),
      'durationMin': 15,
      'ageDays': {'from': 0, 'to': 90},
      'needs': ['sleep', 'soothing'],
      'interests': ['sleep'],
      'timeOfDay': 'evening',
      'locales': ['vi', 'en'],
      'regions': <String>[],
      'sources': [
        {'label': 'AAP · Safe sleep', 'url': 'https://www.aap.org/'},
      ],
      'review': null,
    },
    {
      'id': 'act_evening_repeat',
      'version': 1,
      'status': 'published',
      'title': _l(
        'Lặp lại nếp thư giãn trước giấc đêm',
        'Repeat the evening wind-down',
      ),
      'summary': _l(
        'Giữ cùng một nếp mỗi tối để bé quen dần.',
        'Keep the same routine each evening so it becomes familiar.',
      ),
      'steps': _ll(
        ['Bắt đầu cùng giờ mỗi tối', 'Giữ thứ tự các bước như lần trước'],
        [
          'Start at the same time each evening',
          'Keep the steps in the same order',
        ],
      ),
      'safety': null,
      'durationMin': 15,
      'ageDays': {'from': 0, 'to': 180},
      'needs': ['sleep'],
      'interests': ['sleep'],
      'timeOfDay': 'evening',
      'locales': ['vi', 'en'],
      'regions': <String>[],
      'sources': <Object>[],
      'review': null,
    },
    {
      'id': 'act_skin_to_skin',
      'version': 2,
      'status': 'published',
      'title': _l(
        'Bế áp da trong phòng ánh sáng dịu, 10 phút',
        'Skin-to-skin in a dim room, 10 minutes',
      ),
      'summary': _l(
        'Áp da giúp nhiều bé dịu lại.',
        'Skin-to-skin helps many babies calm down.',
      ),
      'steps': _ll(
        ['Giảm đèn', 'Bế bé áp ngực'],
        ['Dim the lights', 'Hold your baby on your chest'],
      ),
      'safety': null,
      'durationMin': 10,
      'ageDays': {'from': 0, 'to': 120},
      'needs': ['soothing', 'sleep'],
      'interests': <String>[],
      'timeOfDay': 'any',
      'locales': ['vi', 'en'],
      'regions': <String>[],
      'sources': <Object>[],
      'review': {
        'reviewer': 'BS. Test',
        'credential': 'Nhi khoa',
        'reviewedOn': '2026-10-01',
      },
    },
  ],
  'ageCards': [
    {
      'id': 'age_week_3',
      'version': 1,
      'status': 'published',
      'ageDays': {'from': 21, 'to': 27},
      'title': _l(
        'Bé nhìn theo mặt người và nghe giọng quen',
        'Your baby follows faces and familiar voices',
      ),
      'body': _l(
        'Nhiều bé ở tuần này nhìn theo khuôn mặt ở gần và quay về phía giọng nói quen.',
        'Many babies this week follow a nearby face and turn towards familiar voices.',
      ),
      'tips': _ll(
        [
          'Trò chuyện gần mặt bé, khoảng 20–30 cm',
          'Cho bé nằm sấp vài phút khi thức, có người lớn trông',
        ],
        [
          'Talk close to your baby’s face, about 20–30 cm',
          'A few minutes of tummy time while awake and watched',
        ],
      ),
      'watchFor': _ll(
        ['Bé không giật mình với tiếng động lớn'],
        ['Your baby doesn’t startle at loud sounds'],
      ),
      'interests': ['milestones'],
      'sources': [
        {'label': 'CDC · Milestones', 'url': 'https://www.cdc.gov/'},
      ],
      'review': null,
    },
    {
      'id': 'age_month_0',
      'version': 1,
      'status': 'published',
      'ageDays': {'from': 0, 'to': 90},
      'title': _l(
        'Giấc ngủ của bé 0–3 tháng: điều thường gặp',
        'Sleep at 0–3 months: what’s common',
      ),
      'body': _l(
        'Bé mới sinh ngủ nhiều giấc ngắn.',
        'Newborns sleep in many short stretches.',
      ),
      'review': null,
    },
    {
      'id': 'age_week_4',
      'version': 1,
      'status': 'draft',
      'ageDays': {'from': 21, 'to': 27},
      'title': _l('Bản nháp', 'Draft'),
      'body': _l('Bản nháp', 'Draft'),
      'review': null,
    },
  ],
  'health': {
    'signs': [
      {
        'id': 'fever_young',
        'label': _l('Sốt (bé dưới 3 tháng)', 'Fever (baby under 3 months)'),
        'maxAgeDays': 90,
      },
      {
        'id': 'breathing',
        'label': _l('Khó thở, thở rút lõm', 'Hard breathing, chest pulling in'),
        'maxAgeDays': null,
      },
      {
        'id': 'lethargic',
        'label': _l('Lừ đừ, khó đánh thức', 'Floppy or hard to wake'),
        'maxAgeDays': null,
      },
      {
        'id': 'poor_feeding',
        'label': _l(
          'Bú rất ít hoặc bỏ bú',
          'Feeding very little or refusing feeds',
        ),
        'maxAgeDays': null,
      },
      {
        'id': 'inconsolable',
        'label': _l('Khóc không dỗ được', 'Crying that can’t be soothed'),
        'maxAgeDays': null,
      },
      {
        'id': 'lost_skill',
        'label': _l('Mất kỹ năng đã có', 'Lost a skill they had'),
        'maxAgeDays': null,
      },
      {
        'id': 'not_in_the_app',
        'label': _l('Không có trong app', 'Not in the app'),
        'maxAgeDays': null,
      },
    ],
    'whileWaiting': _ll(
      [
        'Giữ bé ở nơi thoáng, theo dõi nhịp thở',
        'Ghi lại giờ bắt đầu và dấu hiệu bạn thấy',
      ],
      [
        'Keep your baby somewhere airy and watch the breathing',
        'Note when it started and what you saw',
      ],
    ),
    'disclaimer': _l(
      'Child Life không chẩn đoán và không kết luận “an toàn”.',
      'Child Life doesn’t diagnose and never concludes “safe”.',
    ),
    'regions': [
      {'country': 'VN', 'emergencyNumber': '115'},
    ],
    'sources': <Object>[],
    'review': null,
  },
};

RhythmContent rhythmContent() => RhythmContent.fromJson(rhythmContentJson())!;

Map<String, Object?> referenceModelJson() => {
  'version': 'ref_20261015_01',
  'label': 'Wonder Weeks',
  'review': null,
  'publishedAt': null,
  'sources': <Object>[],
  'stages': [
    for (final (n, from, to) in const [(1, 21, 30), (2, 29, 39), (3, 60, 70)])
      {
        'id': 'stage_$n',
        'number': n,
        'startOffsetDays': from,
        'endOffsetDays': to,
        'name': _l('Giai đoạn $n', 'Stage $n'),
        'signs': n == 1
            ? _ll(
                [
                  'Có thể cần được bế, dỗ nhiều hơn',
                  'Giấc ngủ và cữ bú có thể xáo trộn vài hôm',
                ],
                [
                  'May want more holding and soothing',
                  'Sleep and feeds may be unsettled for a few days',
                ],
              )
            : _ll(<String>[], <String>[]),
        'skills': n == 1
            ? _ll(
                ['Nhìn theo khuôn mặt, phản ứng với âm thanh'],
                ['Follows faces, reacts to sounds'],
              )
            : _ll(<String>[], <String>[]),
        'activityIds': n == 1
            ? ['act_skin_to_skin', 'act_missing']
            : <String>[],
        'notice': null,
      },
  ],
};

ReferenceModel referenceModel() =>
    ReferenceModel.fromJson(referenceModelJson())!;

/// Teddy: born 17/09, due 21/09 (estimated from 39w3d).
RhythmProfile teddyRhythmProfile({bool dueDate = true}) => RhythmProfile(
  dateOfBirth: DateTime(2026, 9, 17),
  dueDate: dueDate
      ? const DueDate(
          date: '2026-09-21',
          estimated: true,
          gestationWeeks: 39,
          gestationDays: 3,
        )
      : null,
);

/// Mẹ noted last night: hard to settle, night sleep, 2–3 days, rocking tried.
CheckIn sleepCheckIn({String uid = 'u_mai', String date = '2026-10-07'}) =>
    CheckIn(
      id: checkInIdFor(
        babyId: teddyId,
        uid: uid,
        date: date,
        observation: Observation.sleep,
      ),
      babyId: teddyId,
      date: date,
      authorUid: uid,
      observation: Observation.sleep,
      when: CheckInWhen.night,
      since: CheckInSince.days2to3,
      tried: const [Tried.rocking],
    );

Map<String, Object?> recommendationJson({
  String contentId = 'act_wind_down',
  String reason = 'SELF_REPORTED_NEED',
  List<String> changes = const [],
  List<String>? supporting,
  String state = 'suggested',
}) => {
  'id': 'rec_${'a' * 32}',
  'contentId': contentId,
  'contentVersion': 1,
  'reasonCode': reason,
  'supportingIds': supporting ?? [sleepCheckIn(date: rhythmToday).id],
  'requiredCapability': 'personalization.cross_module',
  'state': state,
  'changes': changes,
  'cooldownUntil': null,
  'generatedAt': '2026-10-08T01:00:00.000Z',
};

Map<String, Object?> nextActionJson({String reason = 'DATA_INSIGHT'}) => {
  'state': 'suggestion',
  'recommendation': recommendationJson(reason: reason),
  'secondary': [
    {'contentId': 'act_skin_to_skin', 'contentVersion': 2},
  ],
  'ageCardId': 'age_week_3',
  'gate': null,
  'sleep': {
    'status': 'change_detected',
    'baseline': 840,
    'recent': 690,
    'validDays': 7,
  },
};

/// H02: the suggestion from Mẹ's check-in.
HomeComposition h02Home() => HomeComposition.fromJson({
  'state': 'suggestion',
  'recommendation': recommendationJson(),
  'secondary': <Object>[],
  'ageCardId': 'age_week_3',
  'gate': null,
  'sleep': null,
  'lastFeedback': null,
});

/// Mẹ's "Có ích" on the wind-down (7/10), with a note.
RecFeedback helpfulFeedback() => RecFeedback(
  id: 'fb_${'b' * 32}',
  babyId: teddyId,
  authorUid: 'u_mai',
  contentId: 'act_wind_down',
  contentVersion: 1,
  kind: FeedbackKind.helpful,
  date: '2026-10-07',
  note: 'Con vào giấc nhanh hơn sau khi tắm',
  createdAt: DateTime.utc(2026, 10, 7, 14),
);

Map<String, Object?> ps02Json() => {
  'state': 'suggestion',
  'recommendation': recommendationJson(
    contentId: 'act_evening_repeat',
    reason: 'PREVIOUS_HELPFUL',
    changes: ['prefers_helpful'],
    supporting: [
      sleepCheckIn(date: rhythmToday).id,
      helpfulFeedback().id,
    ],
  ),
  'secondary': <Object>[],
  'ageCardId': 'age_week_3',
  'gate': null,
  'sleep': null,
  'lastFeedback': {
    'id': helpfulFeedback().id,
    'contentId': 'act_wind_down',
    'kind': 'helpful',
    'date': '2026-10-07',
    'authorUid': 'u_mai',
  },
};

HomeComposition ps02Home() => HomeComposition.fromJson(ps02Json());

/// A `getCapabilities` answer with the rhythm flag on; [groupA] = personalization.cross_module.
Map<String, Object?> rhythmCaps({
  String plan = 'free',
  bool groupA = false,
  String reason = 'PREMIUM_REQUIRED',
  String? country = 'VN',
  bool rhythm = true,
}) => {
  'familyId': 'f_1',
  'plan': plan,
  'canManageBilling': true,
  'country': country,
  'capabilities': {
    'rhythm.checkin': {'allowed': true, 'reason': null},
    'health.guidance': {'allowed': true, 'reason': null},
    'wonder.reference': {'allowed': true, 'reason': null},
    'personalization.cross_module': {
      'allowed': groupA,
      'reason': groupA ? null : reason,
    },
    'rhythm.advanced': {'allowed': groupA, 'reason': groupA ? null : reason},
  },
  'features': {
    'rhythm': rhythm,
    'personalization': true,
    'aiAssist': false,
    'billing': false,
  },
};

/// A value that streams its current state and every change (like a Firestore listener).
class _Live<T> {
  _Live(this.value);
  T value;
  final _changes = StreamController<T>.broadcast();

  Stream<T> get stream async* {
    yield value;
    yield* _changes.stream;
  }

  void set(T v) {
    value = v;
    _changes.add(v);
  }
}

/// Records what the Nhịp lớn lên screens write and answers the callables from fixtures.
class FakeRhythmRepository implements RhythmRepository {
  FakeRhythmRepository({
    RhythmContent? content,
    ReferenceModel? reference,
    RhythmProfile? profile,
    List<CheckIn> checkIns = const [],
    List<RecFeedback> feedback = const [],
    this.home,
    this.answer,
    this.answerError,
    UserPreferences preferences = UserPreferences.defaults,
    List<ObservationEpisode> episodes = const [],
    this.recommendations = const [],
  }) : _preferences = _Live(preferences),
       _episodes = _Live([...episodes]),
       content = content ?? rhythmContent(),
       reference = reference ?? referenceModel(),
       profile = profile ?? teddyRhythmProfile(),
       _checkIns = _Live([...checkIns]),
       _feedback = _Live(newestFirst(feedback));

  RhythmContent? content;
  ReferenceModel? reference;
  RhythmProfile profile;
  HomeComposition? home;
  NextActionAnswer? answer;
  Object? answerError;

  final _Live<List<CheckIn>> _checkIns;
  final _Live<List<RecFeedback>> _feedback;
  final _Live<UserPreferences> _preferences;
  final _Live<List<ObservationEpisode>> _episodes;
  final savedEpisodes = <ObservationEpisode>[];
  List<Recommendation> recommendations;
  final savedCheckIns = <CheckIn>[];
  final savedFeedback = <RecFeedback>[];
  final savedPreferences = <UserPreferences>[];
  final deletedFeedback = <String>[];
  Object? dueDateError;

  UserPreferences get preferences => _preferences.value;
  final nextActionCalls = <String>[];
  final dueDates = <DueDate?>[];
  int composeCalls = 0;

  List<CheckIn> get checkIns => _checkIns.value;

  @override
  Stream<RhythmContent?> watchContent() => Stream.value(content);

  @override
  Stream<ReferenceModel?> watchReference() => Stream.value(reference);

  @override
  Stream<RhythmProfile> watchProfile(String babyId) => Stream.value(profile);

  @override
  Stream<List<CheckIn>> watchCheckIns(String babyId, String since) =>
      _checkIns.stream;

  @override
  Stream<List<RecFeedback>> watchFeedback(String babyId, String since) =>
      _feedback.stream;

  @override
  CheckIn saveCheckIn(
    CheckIn checkIn, {
    CheckIn? previous,
    void Function(Object error)? onError,
  }) {
    final saved = previous == null
        ? checkIn
        : checkIn.copyWith(revision: previous.revision + 1);
    savedCheckIns.add(saved);
    _checkIns.set([
      saved,
      for (final c in _checkIns.value)
        if (c.id != saved.id) c,
    ]);
    return saved;
  }

  @override
  RecFeedback saveFeedback(
    RecFeedback feedback, {
    void Function(Object error)? onError,
  }) {
    savedFeedback.add(feedback);
    _feedback.set(newestFirst([feedback, ..._feedback.value]));
    return feedback;
  }

  @override
  Future<void>? committed(String id) => null;

  @override
  Future<NextActionAnswer> nextAction({
    required String babyId,
    required String checkInId,
    required String locale,
  }) async {
    nextActionCalls.add(checkInId);
    if (answerError case final e?) throw e;
    return answer ?? NextActionAnswer.fromJson({'state': 'no_suggestion'});
  }

  @override
  Future<HomeComposition?> composeHome(
    String babyId,
    String locale, {
    String viewerUid = '',
  }) async {
    composeCalls++;
    return home;
  }

  @override
  HomeComposition? cachedHome(
    String babyId,
    String locale, {
    String viewerUid = '',
  }) => home;

  @override
  Future<void> setDueDate(String babyId, DueDate? dueDate) async {
    if (dueDateError case final e?) throw e;
    dueDates.add(dueDate);
    profile = RhythmProfile(dateOfBirth: profile.dateOfBirth, dueDate: dueDate);
  }

  @override
  Stream<UserPreferences> watchPreferences(String uid) => _preferences.stream;

  @override
  void savePreferences(
    String uid,
    UserPreferences preferences, {
    void Function(Object error)? onError,
  }) {
    savedPreferences.add(preferences);
    _preferences.set(preferences);
  }

  @override
  void deleteFeedback(
    String babyId,
    String id, {
    void Function(Object error)? onError,
  }) {
    deletedFeedback.add(id);
    _feedback.set([
      for (final f in _feedback.value)
        if (f.id != id) f,
    ]);
  }

  List<ObservationEpisode> get episodes => _episodes.value;

  @override
  Stream<List<ObservationEpisode>> watchEpisodes(String babyId) =>
      _episodes.stream;

  @override
  ObservationEpisode saveEpisode(
    ObservationEpisode episode, {
    bool create = false,
    void Function(Object error)? onError,
  }) {
    savedEpisodes.add(episode);
    _episodes.set([
      episode,
      for (final e in _episodes.value)
        if (e.id != episode.id) e,
    ]);
    return episode;
  }

  @override
  Stream<List<Recommendation>> watchRecommendations(String babyId) =>
      Stream.value(recommendations);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The family of Teddy seen by [me], the rhythm flag on, a fake repository and a fixed clock.
List<Override> rhythmOverrides({
  required FakeRhythmRepository repo,
  Membership? me,
  Map<String, Object?>? caps,
  List<String>? dialled,
  bool online = true,
  List<CareRecord> records = const [],

  /// The care log the sleep comparison reads (NL01 / NL07).
  List<CareRecord> sleepRecords = const [],
  MemoryRepository? memories,
  List<CareRecord> growth = const [],
  List<Reminder> reminders = const [],
  PersonalDay? personalDay,
  PersonalizationRepository? personalization,
  DateTime? now,

  /// Running care timers (Lumi 2026-10-16: the chat's timer cards read them).
  Map<TimerType, CareTimer> timers = const {},
}) => [
  ...familyOverrides(
    me: me ?? mai,
    now: now ?? rhythmNow,
    online: online,
    records: records,
    growth: growth,
    reminders: reminders,
    timers: timers,
  ),
  rhythmRepositoryProvider.overrideWithValue(repo),
  ...personalizationTestOverrides(
    day: personalDay,
    repository: personalization,
  ),
  rhythmSleepRecordsProvider.overrideWith(
    (ref, key) => Stream.value(sleepRecords),
  ),
  memoryRepositoryProvider.overrideWithValue(
    memories ?? FakeMemoryRepository(),
  ),
  capabilitiesProvider.overrideWith(
    (ref, babyId) async => Capabilities.fromJson(caps ?? rhythmCaps()),
  ),
  rhythmDialerProvider.overrideWithValue((number) async {
    dialled?.add(number);
    return true;
  }),
];

/// Last night's sleep logged by Ba: 20:10 → 04:00 (7 h 50).
List<CareRecord> lastNightSleep() => [
  rec(CareType.sleep, vn(7, 20, 10), minh, endedAt: vn(8, 4, 0)),
];

/// Recent check-ins for NL01: Mẹ and Ba noted different things on 7/10 (a mixed day), Cô Lan
/// today, Mẹ on 6/10.
List<CheckIn> recentCheckIns() {
  CheckIn ci(String uid, String date, Observation o) => CheckIn(
    id: checkInIdFor(babyId: teddyId, uid: uid, date: date, observation: o),
    babyId: teddyId,
    date: date,
    authorUid: uid,
    observation: o,
  );
  return [
    ci('u_lan', rhythmToday, Observation.soothing),
    sleepCheckIn(uid: 'u_minh'),
    ci('u_mai', '2026-10-07', Observation.usual),
    ci('u_mai', '2026-10-06', Observation.soothing),
  ];
}

/// Ba's "Chưa rõ" on skin-to-skin (5/10), next to Mẹ's "Có ích" on the wind-down.
List<RecFeedback> familyFeedback() => [
  helpfulFeedback(),
  RecFeedback(
    id: 'fb_${'c' * 32}',
    babyId: teddyId,
    authorUid: 'u_minh',
    contentId: 'act_skin_to_skin',
    contentVersion: 2,
    kind: FeedbackKind.unsure,
    date: '2026-10-05',
    createdAt: DateTime.utc(2026, 10, 5, 13),
  ),
];

/// A care log of the [days] days before [rhythmToday]: two sleeps and five bottles a day,
/// [usualHours] of sleep (the last three days [recentHours]); on [sparseDay] days back only the
/// sleeps are logged (a day with long gaps: not counted, never zero).
List<CareRecord> sleepLog({
  int days = 17,
  int usualHours = 13,
  int recentHours = 11,
  int? sparseDay = 6,
}) {
  final out = <CareRecord>[];
  for (var d = days; d >= 1; d--) {
    final p = addDaysIso(rhythmToday, -d).split('-').map(int.parse).toList();
    DateTime at(int h, [int m = 0]) => DateTime.utc(p[0], p[1], p[2], h - 7, m);
    final hours = d <= 3 ? recentHours : usualHours;
    final night = hours ~/ 2;
    out.addAll([
      rec(CareType.sleep, at(0), mai, endedAt: at(night)),
      if (d != sparseDay)
        for (final h in [7, 10, 13, 16, 19]) rec(CareType.bottle, at(h), mai),
      rec(CareType.sleep, at(24 - (hours - night)), mai, endedAt: at(23, 59)),
    ]);
  }
  return out;
}

List<Override> personalizationTestOverrides({
  PersonalDay? day,
  PersonalizationRepository? repository,
}) => [
  personalDayProvider.overrideWith(
    (ref, key) async =>
        day ??
        PersonalDay({
          'asOf': '1970-01-01T00:00:00Z',
          'expiresAt': '1970-01-02T00:00:00Z',
        }),
  ),
  personalDigestPlanProvider.overrideWith((ref) async => null),
  personalizationEventSinkProvider.overrideWithValue((event, dim) async {}),
  if (repository != null)
    personalizationRepositoryProvider.overrideWithValue(repository),
];
