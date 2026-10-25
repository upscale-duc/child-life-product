import 'dart:io';
import 'dart:typed_data';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/print_studio/print_models.dart';
import 'package:child_life/features/print_studio/print_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'family_fixtures.dart';
import 'memory_fixtures.dart';

final printMedia = List.generate(
  7,
  (i) => MediaItem(
    id: 'print_$i',
    babyId: teddyId,
    memoryId: 'memory_$i',
    type: MediaKind.photo,
    status: MediaStatus.ready,
    audience: Audience.parents,
    effectiveAudience: Audience.parents,
    captureAt: DateTime(2026, 9, 17 + i),
    createdBy: 'u_mai',
    width: 3000,
    height: 4000,
    paths: MediaPaths(
      original: 'fixtures/photo-${i % 5}.png',
      display: 'fixtures/photo-${i % 5}.png',
      thumb: 'fixtures/photo-${i % 5}.png',
    ),
    milestone: i == 1
        ? MilestoneRef(
            id: 'first_smile',
            name: 'Nụ cười đầu tiên',
            date: DateTime(2026, 9, 28),
          )
        : null,
  ),
);
final printCatalog = PrintCatalog({
  'version': 1,
  'physicalEnabled': true,
  'digitalEnabled': true,
  'supportedCountries': ['VN'],
  'prices': {
    'single:10x15': 99000,
    'single:13x18': 129000,
    'single:15x21': 159000,
    'trio:10x15': 279000,
    'trio:13x18': 349000,
    'trio:15x21': 429000,
    'five:10x15': 449000,
    'five:13x18': 549000,
    'five:15x21': 649000,
    'book:15x15:24': 299000,
    'book:20x20:24': 499000,
    'book:20x20:40': 649000,
  },
  'giftSurcharge': 60000,
  'giftWrapFee': 30000,
  'shippingFee': 30000,
  'freeShippingFrom': 500000,
  'leadDays': 7,
  'pricesEstimated': true,
  'policy': {'vi': 'Thanh toán khi nhận hàng.', 'en': 'Pay on delivery.'},
});
final printAddress = {
  'recipient': 'Mai Nguyễn',
  'phone': '0905123456',
  'address': '12 Lê Duẩn, Hải Châu, Đà Nẵng',
  'country': 'VN',
  'neededBy': null,
  'gift': false,
  'giftMessage': '',
};

class PrintFixtureBytes extends FakeMediaBytes {
  @override
  Future<Uint8List> read(String path) async => path.startsWith('fixtures/')
      ? File('test/fixtures/print/${path.split('/').last}').readAsBytesSync()
      : super.read(path);
}

List<Override> printOverrides({
  PrintAction? action,
  bool savedAddress = true,
  List<MediaItem>? media,
  bool physical = true,
}) => [
  ...familyOverrides(
    now: DateTime(2026, 10, 25),
    profile: BabyPrivateProfile(
      dateOfBirth: DateTime(2026, 8, 17),
      gender: Gender.boy,
    ),
  ),
  ...memoryOverrides(
    journal: (memories: const <Memory>[], media: media ?? printMedia),
  ),
  printCatalogProvider.overrideWith(
    (ref) async =>
        PrintCatalog({...printCatalog.json, 'physicalEnabled': physical}),
  ),
  printDraftProvider.overrideWith((ref, baby) => Stream.value(null)),
  printOrdersProvider.overrideWith(
    (ref, baby) => Stream.value(
      savedAddress
          ? [
              {'id': 'old', 'address': printAddress},
            ]
          : [],
    ),
  ),
  printReviewsProvider.overrideWith((ref) => Stream.value([])),
  printActionProvider.overrideWithValue(
    action ?? (name, data) async => {'id': 'CL26110832'},
  ),
];
