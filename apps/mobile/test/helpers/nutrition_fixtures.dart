import 'package:child_life/features/nutrition/nutrition_models.dart';
import 'package:child_life/features/nutrition/nutrition_repository.dart';
import 'package:child_life/features/nutrition/nutrition_share.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Dinh dưỡng fixtures, TEST ONLY: published documents in the `contentNutritionStageSchema` /
/// `contentNutrientSchema` / `contentNutritionRuleSchema` shape (Figma 9b–9g copy), parsed through
/// the app's own `fromDoc`. Never shipped: real builds show only what the portal published.

Map<String, Object?> _l(String vi, String en) => {'vi': vi, 'en': en};

Map<String, Object?> _meta({bool reviewed = false}) => {
  'status': 'published',
  'revision': 1,
  'review': reviewed
      ? {
          'reviewer': 'BS. Thu Hà',
          'credential': 'Nhi khoa',
          'reviewedOn': '2026-09-28',
        }
      : null,
  'illustrative': !reviewed,
  'reviewDueOn': '2027-09-28',
  'publishedAt': '2026-10-01T03:00:00.000Z',
  'firstPublishedAt': '2026-10-01T03:00:00.000Z',
};

Map<String, Object?> stageDoc({
  required String id,
  required int from,
  required int to,
  String title = 'Bắt đầu ăn dặm',
  String titleEn = 'Starting solids',
  Map<String, Object?>? milk = const {
    'perFeedMl': {'min': 180, 'max': 240},
    'feedsPerDay': {'min': 4, 'max': 5},
    'perDayMl': {'min': 600, 'max': 900},
    'breastfeedingNote': {'vi': 'cho bú theo nhu cầu', 'en': 'feed on demand'},
  },
  List<String> nutrientIds = const ['nut_iron', 'nut_vitamin_a'],
  bool reviewed = false,
}) => {
  'id': id,
  'ageMonths': {'from': from, 'to': to},
  'title': _l(title, titleEn),
  'summary': _l(
    'Sữa vẫn là nguồn dinh dưỡng chính. Thêm 2–3 bữa ăn dặm mỗi ngày.',
    'Milk is still the main food. Add 2–3 solid meals a day.',
  ),
  'milk': milk,
  'solids': {
    'meals': _l('2–3 bữa', '2–3 meals'),
    'texture': _l('Bột loãng → cháo rây', 'Thin purée → mash'),
  },
  'sampleDay': [
    {
      'slot': 'morning',
      'kind': 'milk',
      'text': _l('Sữa · 180–240 ml', 'Milk · 180–240 ml'),
    },
    {
      'slot': 'noon',
      'kind': 'solids',
      'text': _l('Ăn dặm · bột/cháo rây', 'Solids · purée'),
    },
    {
      'slot': 'night',
      'kind': 'sleep',
      'text': _l('Sữa theo nhu cầu', 'Milk on demand'),
    },
    // Unknown slot: dropped on its own.
    {'slot': 'brunch', 'kind': 'milk', 'text': _l('x', 'x')},
  ],
  'nutrientIds': nutrientIds,
  'tips': [
    {
      'title': _l('Mỗi ngày một món giàu sắt', 'One iron-rich dish a day'),
      'body': _l(
        'Thịt bò, gan gà, lòng đỏ trứng cho {name}.',
        'Beef, liver, egg yolk for {name}.',
      ),
    },
  ],
  'sources': [
    {'label': 'WHO 2023', 'url': 'https://www.who.int/'},
  ],
  ..._meta(reviewed: reviewed),
};

Map<String, Object?> ironDoc() => {
  'id': 'nut_iron',
  'key': 'iron',
  'name': _l('Sắt', 'Iron'),
  'subtitle': _l(
    'Dự trữ từ lúc sinh giảm dần · thịt, trứng, gan',
    'Birth stores run down · meat, egg, liver',
  ),
  'focus': {
    'ageMonths': {'from': 6, 'to': 24},
    'label': _l('Quan trọng từ 6 tháng', 'Important from 6 months'),
    'note': _l('', ''),
  },
  'why': _l(
    'Sắt giúp tạo máu và phát triển não bộ.',
    'Iron helps make blood and grow the brain.',
  ),
  'foods': [_l('Thịt bò', 'Beef'), _l('Gan gà', 'Chicken liver')],
  'tip': _l('Ăn kèm rau quả giàu vitamin C.', 'Eat with vitamin C-rich fruit.'),
  'byAge': [
    {
      'ageMonths': {'from': 0, 'to': 4},
      'label': _l('0–4 tháng', '0–4 months'),
      'text': _l('Bé đủ sắt dự trữ', 'Enough stores'),
    },
    {
      'ageMonths': {'from': 6, 'to': 24},
      'label': _l('6–23 tháng', '6–23 months'),
      'text': _l(
        'Mỗi ngày có thịt, cá hoặc trứng',
        'Meat, fish or egg every day',
      ),
    },
  ],
  'warning': _l(
    'Sắt dạng thuốc chỉ dùng theo chỉ định của bác sĩ.',
    'Iron medicine only on prescription.',
  ),
  'campaign': null,
  'sources': [
    {'label': 'WHO 2023', 'url': 'https://www.who.int/'},
  ],
  ..._meta(),
};

Map<String, Object?> vitaminADoc() => {
  'id': 'nut_vitamin_a',
  'key': 'vitaminA',
  'name': _l('Vitamin A', 'Vitamin A'),
  'subtitle': _l('Uống bổ sung tại trạm y tế', 'Given at the health station'),
  'focus': {
    'ageMonths': {'from': 6, 'to': 37},
    'label': _l('Từ 6 tháng', 'From 6 months'),
    'note': _l('', ''),
  },
  'why': _l(
    'Vitamin A giúp mắt sáng và tăng sức đề kháng.',
    'Vitamin A helps eyes and immunity.',
  ),
  'foods': <Object?>[],
  'tip': null,
  'byAge': <Object?>[],
  'warning': _l(
    'Chỉ uống theo đợt của trạm y tế.',
    'Only at the station rounds.',
  ),
  'campaign': {
    'rounds': [
      {'month': 12, 'fromDay': 1, 'toDay': 2},
      {'month': 6, 'fromDay': 1, 'toDay': 2},
    ],
    'ageMonths': {'from': 6, 'to': 37},
    'place': _l('trạm y tế phường, xã', 'the ward health station'),
  },
  'sources': <Object?>[],
  ..._meta(),
};

Map<String, Object?> ruleDoc({
  String id = 'nru_weight_low',
  String metric = 'weight',
  String condition = 'belowRange',
  int from = 0,
  int to = 37,
  int? days,
  int? remindAfterDays = 14,
  bool export = true,
  String banner =
      '2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. Đây không phải chẩn đoán.',
}) => {
  'id': id,
  'metric': metric,
  'condition': condition,
  'days': days,
  'ageMonths': {'from': from, 'to': to},
  'banner': _l(banner, 'Not a diagnosis: {name} is below the range.'),
  'tips': [
    {
      'title': _l('Duy trì sữa đều đặn', 'Keep milk regular'),
      'body': _l('Không giảm cữ sữa khi bắt đầu ăn dặm', "Don't cut feeds"),
    },
  ],
  'remindAfterDays': remindAfterDays,
  'export': export,
  ..._meta(),
};

List<NuStage> stagesOf(List<Map<String, Object?>> docs) => [
  for (final d in docs) ?NuStage.fromDoc(d['id']! as String, d),
];

List<NuNutrient> nutrientsOf(List<Map<String, Object?>> docs) => [
  for (final d in docs) ?NuNutrient.fromDoc(d['id']! as String, d),
];

List<NuRule> rulesOf(List<Map<String, Object?>> docs) => [
  for (final d in docs) ?NuRule.fromDoc(d['id']! as String, d),
];

/// Records the vitamin A writes.
class FakeNutritionStore extends Fake implements NutritionStore {
  final calls = <(String key, String? takenOn, String uid)>[];

  @override
  void setVitaminTaken(
    String babyId,
    String key,
    String? takenOn,
    String uid, {
    void Function(Object error)? onError,
  }) => calls.add((key, takenOn, uid));
}

/// Records what went to the share sheet.
class ShareLog {
  final calls = <({String? text, String? subject, NuShareFile? file})>[];

  NuShare get share =>
      ({String? text, String? subject, NuShareFile? file, Rect? origin}) async {
        calls.add((text: text, subject: subject, file: file));
      };
}

List<Override> nutritionOverrides({
  List<NuStage>? stages,
  List<NuNutrient>? nutrients,
  List<NuRule> rules = const [],
  Map<String, String> taken = const {},
  FakeNutritionStore? store,
  ShareLog? share,
}) => [
  nutritionStoreProvider.overrideWithValue(store ?? FakeNutritionStore()),
  nuStagesProvider.overrideWith(
    (ref) => Stream.value((
      items:
          stages ??
          stagesOf([
            stageDoc(id: 'nst_first', from: 0, to: 1, title: 'Những ngày đầu'),
            stageDoc(id: 'nst_solids', from: 6, to: 9),
          ]),
      fromCache: false,
    )),
  ),
  nuNutrientsProvider.overrideWith(
    (ref) => Stream.value((
      items: nutrients ?? nutrientsOf([ironDoc(), vitaminADoc()]),
      fromCache: false,
    )),
  ),
  nuRulesProvider.overrideWith(
    (ref) => Stream.value((items: rules, fromCache: false)),
  ),
  nuVitaminTakenProvider.overrideWith((ref, id) => Stream.value(taken)),
  nuShareProvider.overrideWithValue((share ?? ShareLog()).share),
];
