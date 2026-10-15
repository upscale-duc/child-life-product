import 'dart:async';

import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/content_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Thư viện chăm bé / Giai đoạn của bé fixtures, TEST ONLY: published documents in the
/// `contentArticleSchema` / `contentStageSchema` shape (Figma 4a–4f, 2a–2b copy), parsed through
/// the app's own `fromDoc`. Never shipped: real builds show only what the portal published.

Map<String, Object?> _meta({
  bool reviewed = false,
  int revision = 1,
  String publishedAt = '2026-09-20T03:00:00.000Z',
}) => {
  'status': 'published',
  'revision': revision,
  'review': reviewed
      ? {
          'reviewer': 'BS. Thu Hà',
          'credential': 'Nhi khoa',
          'reviewedOn': '2026-09-28',
        }
      : null,
  'illustrative': !reviewed,
  'reviewDueOn': '2027-09-28',
  'publishedAt': publishedAt,
  'firstPublishedAt': '2026-09-15T03:00:00.000Z',
};

Map<String, Object?> _l(String vi, String en) => {'vi': vi, 'en': en};

Map<String, Object?> articleDoc({
  required String id,
  required String topic,
  required String vi,
  required String en,
  int from = 0,
  int to = 13,
  int minutes = 4,
  bool reviewed = false,
  int revision = 1,
  String publishedAt = '2026-09-20T03:00:00.000Z',
  List<Map<String, Object?>>? bodyVi,
  List<Map<String, Object?>>? bodyEn,
  List<String> related = const [],
  List<String> keywordsVi = const [],
  String library = 'care',
}) => {
  'id': id,
  'library': library,
  'topic': topic,
  'format': 'article',
  'ageWeeks': {'from': from, 'to': to},
  'readingMinutes': minutes,
  'cover': null,
  'title': _l(vi, en),
  'summary': _l(vi, en),
  'body': {
    'vi':
        bodyVi ??
        [
          {'type': 'paragraph', 'text': '$vi: nội dung minh hoạ cho kiểm thử.'},
        ],
    'en':
        bodyEn ??
        [
          {'type': 'paragraph', 'text': '$en: illustrative test content.'},
        ],
  },
  'keywords': {'vi': keywordsVi, 'en': <String>[]},
  'relatedArticleIds': related,
  'milestoneIds': <String>[],
  'sources': <Object?>[],
  ..._meta(reviewed: reviewed, revision: revision, publishedAt: publishedAt),
};

/// 4d "Giấc ngủ của bé sơ sinh": every block type.
final newbornSleepDoc = articleDoc(
  id: 'art_newborn_sleep',
  topic: 'sleep',
  vi: 'Giấc ngủ của bé sơ sinh',
  en: 'Newborn sleep',
  minutes: 6,
  reviewed: true,
  revision: 2,
  publishedAt: '2026-10-07T03:00:00.000Z',
  keywordsVi: ['ngủ ngày'],
  related: ['art_day_night', 'art_sleep_position'],
  bodyVi: [
    {
      'type': 'paragraph',
      'text':
          'Trong những tuần đầu, bé ngủ nhiều nhưng chia thành nhiều giấc ngắn, cả ngày lẫn đêm. Đây là điều bình thường khi bé đang làm quen với nhịp sống mới.',
    },
    {'type': 'heading', 'text': 'Nhận biết bé buồn ngủ'},
    {
      'type': 'bullets',
      'items': [
        'Ngáp, dụi mắt, kéo tai',
        'Nhìn xa xăm, ít phản ứng',
        'Quấy khóc dù vừa bú no',
      ],
    },
    {
      'type': 'image',
      'image': 'sleep-room_0a1b2c3d',
      'caption': 'Phòng ngủ tối, yên tĩnh giúp bé dễ vào giấc.',
      'alt': 'Bé ngủ trong phòng tối',
    },
    {'type': 'heading', 'text': 'Tạo nhịp ngày – đêm'},
    {
      'type': 'paragraph',
      'text':
          'Ban ngày để phòng sáng tự nhiên và trò chuyện với bé khi thức. Ban đêm giữ ánh sáng dịu, cho bú nhẹ nhàng và hạn chế chơi đùa.',
    },
    {
      'type': 'callout',
      'tone': 'doctor',
      'title': 'Khi nào nên hỏi bác sĩ',
      'text':
          'Nếu bạn thấy bé khác thường hoặc bạn đang lo lắng, hãy liên hệ bác sĩ hoặc cơ sở y tế gần nhất.',
    },
    {'type': 'video', 'url': 'https://example.com/x'},
    {'type': 'html', 'html': '<script>alert(1)</script>'},
  ],
  bodyEn: [
    {
      'type': 'paragraph',
      'text':
          'In the first weeks your baby sleeps a lot, in many short stretches, day and night. That is normal while they get used to a new rhythm.',
    },
    {'type': 'heading', 'text': 'Spotting sleepy cues'},
    {
      'type': 'bullets',
      'items': [
        'Yawning, rubbing eyes, pulling ears',
        'Staring off, less responsive',
        'Fussing even after a full feed',
      ],
    },
    {
      'type': 'image',
      'image': 'sleep-room_0a1b2c3d',
      'caption': 'A dark, quiet room helps baby fall asleep.',
      'alt': 'Baby asleep in a dark room',
    },
    {'type': 'heading', 'text': 'Building a day–night rhythm'},
    {
      'type': 'paragraph',
      'text':
          'By day keep the room naturally bright and talk with your baby when awake. At night keep the light dim, feed gently and keep play low.',
    },
    {
      'type': 'callout',
      'tone': 'doctor',
      'title': 'When to ask a doctor',
      'text':
          'If your baby seems unusual or you are worried, contact a doctor or the nearest health facility.',
    },
  ],
);

final articleDocs = <Map<String, Object?>>[
  newborn,
  articleDoc(
    id: 'art_hiccups',
    topic: 'feeding',
    vi: 'Bé nấc, ọc sữa sau bú',
    en: 'Hiccups and spit-up after feeds',
    minutes: 4,
    publishedAt: '2026-10-01T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_bath',
    topic: 'daily_care',
    vi: 'Tắm cho bé tại nhà',
    en: 'Bathing your baby at home',
    minutes: 5,
    publishedAt: '2026-09-25T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_diaper_rash',
    topic: 'daily_care',
    vi: 'Hăm tã: nhận biết và chăm sóc',
    en: 'Nappy rash: spotting and caring for it',
    from: 0,
    to: 52,
    minutes: 5,
    publishedAt: '2026-10-06T03:00:00.000Z',
    keywordsVi: ['hăm tã'],
  ),
  articleDoc(
    id: 'art_fever',
    topic: 'illness',
    vi: 'Khi bé sốt: những điều ba mẹ cần biết',
    en: 'When your baby has a fever',
    from: 0,
    to: 104,
    minutes: 7,
    reviewed: true,
    publishedAt: '2026-10-05T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_pumping',
    topic: 'feeding',
    vi: 'Vắt và trữ sữa mẹ',
    en: 'Expressing and storing breast milk',
    from: 0,
    to: 52,
    minutes: 6,
    publishedAt: '2026-10-04T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_day_night',
    topic: 'sleep',
    vi: 'Phân biệt ngày và đêm cho bé',
    en: 'Helping baby tell day from night',
    minutes: 4,
    publishedAt: '2026-09-18T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_sleep_position',
    topic: 'sleep',
    vi: 'Tư thế ngủ cho bé',
    en: 'Safe sleep positions',
    from: 0,
    to: 52,
    minutes: 2,
    publishedAt: '2026-09-17T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_teething',
    topic: 'teething',
    vi: 'Dấu hiệu bé sắp mọc răng',
    en: 'Signs of teething',
    from: 17,
    to: 52,
    minutes: 3,
    publishedAt: '2026-09-10T03:00:00.000Z',
  ),
  articleDoc(
    id: 'art_puree',
    topic: 'feeding',
    vi: 'Cháo rây đầu tiên',
    en: 'First smooth porridge',
    from: 26,
    to: 40,
    library: 'solids',
  ),
];

Map<String, Object?> get newborn => newbornSleepDoc;

List<LbArticle> fixtureArticles() => [
  for (final d in articleDocs) LbArticle.fromDoc(d['id']! as String, d)!,
];

Map<String, Object?> stageDoc({
  required String id,
  required String unit,
  required int from,
  required int to,
  required String vi,
  required String en,
  List<String> doingVi = const [],
  List<String> doingEn = const [],
  List<String> tryVi = const [],
  List<String> tryEn = const [],
  List<String> articles = const [],
  List<String> audience = const ['coParent', 'caregiver', 'relative'],
  bool reviewed = false,
}) => {
  'id': id,
  'age': {'unit': unit, 'from': from, 'to': to},
  'title': _l(vi, en),
  'doing': {'vi': doingVi, 'en': doingEn},
  'tryThis': {'vi': tryVi, 'en': tryEn},
  'articleIds': articles,
  'milestoneIds': <String>[],
  'audience': audience,
  'cover': null,
  'sources': <Object?>[],
  ..._meta(reviewed: reviewed),
};

final stageDocs = <Map<String, Object?>>[
  stageDoc(
    id: 'stg_m1',
    unit: 'month',
    from: 1,
    to: 2,
    vi: 'Nụ cười đầu tiên đáp lại ba mẹ',
    en: 'A first smile back at you',
  ),
  stageDoc(
    id: 'stg_w0',
    unit: 'week',
    from: 0,
    to: 3,
    vi: 'Làm quen với thế giới mới',
    en: 'Getting to know a new world',
  ),
  stageDoc(
    id: 'stg_w3',
    unit: 'week',
    from: 3,
    to: 5,
    vi: 'Bé nhìn theo mặt người, nghe giọng quen',
    en: 'Following faces, knowing familiar voices',
    doingVi: [
      'Nhìn rõ nhất ở khoảng cách 20–30 cm',
      'Quay về phía giọng nói quen thuộc',
      'Giờ thức dài hơn một chút',
    ],
    doingEn: [
      'Sees best at 20–30 cm',
      'Turns towards familiar voices',
      'Stays awake a little longer',
    ],
    tryVi: [
      'Nói chuyện, hát nhẹ khi bé thức',
      'Cho bé nằm sấp vài phút khi có người lớn bên cạnh',
      'Để bé nhìn mặt bạn thật gần',
    ],
    tryEn: [
      'Talk and sing softly while your baby is awake',
      'A few minutes of tummy time with an adult close by',
      'Let your baby look at your face up close',
    ],
    articles: ['art_newborn_sleep', 'art_day_night'],
    reviewed: true,
  ),
  stageDoc(
    id: 'stg_m2',
    unit: 'month',
    from: 2,
    to: 3,
    vi: 'Giữ đầu vững hơn khi nằm sấp',
    en: 'Holding the head steadier in tummy time',
  ),
  stageDoc(
    id: 'stg_m3',
    unit: 'month',
    from: 3,
    to: 4,
    vi: 'Với tay, nắm đồ chơi',
    en: 'Reaching for and grasping toys',
    audience: ['coParent'],
  ),
];

List<LbStage> fixtureStages() => [
  for (final d in stageDocs) LbStage.fromDoc(d['id']! as String, d)!,
];

/// Records "Lưu" / "Bỏ lưu" / read revisions; serves the saved list.
class FakeContentStore extends ContentStore {
  FakeContentStore()
    : super(() => throw UnimplementedError(), () => throw UnimplementedError());

  final calls = <String>[];
  final savedNow = StreamController<List<LbSaved>>.broadcast();

  @override
  Future<void> save(String uid, LbArticle a) async =>
      calls.add('save ${a.id} r${a.revision}');

  @override
  Future<void> unsave(String uid, String id) async => calls.add('unsave $id');

  @override
  Future<void> markRead(String uid, String id, int revision) async =>
      calls.add('read $id r$revision');
}

List<Override> libraryOverrides({
  List<LbArticle>? articles,
  List<LbStage>? stages,
  List<LbSaved> saved = const [],
  bool fromCache = false,
  FakeContentStore? store,
}) => [
  contentStoreProvider.overrideWithValue(store ?? FakeContentStore()),
  lbArticlesProvider.overrideWith(
    (ref) => Stream.value((
      items: articles ?? fixtureArticles(),
      fromCache: fromCache,
    )),
  ),
  lbStagesProvider.overrideWith(
    (ref) =>
        Stream.value((items: stages ?? fixtureStages(), fromCache: fromCache)),
  ),
  lbSavedProvider.overrideWith((ref) => Stream.value(saved)),
  lbImageProvider.overrideWithValue((_) => null),
];
