import 'dart:typed_data';

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/solids/solids_history.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// Meal photos (owner: allowed, D-085 #2): one per meal in 5c (camera or library), uploaded to
/// `babies/{babyId}/meals/{file}.jpg` through the book-photo store (a fake here), shown in 5b,
/// 5d and meal detail. Cùng nuôi delete the old object on replace or remove; caregivers only
/// clear `photoPath` (Storage Rules).

const _old = 'babies/$teddyId/meals/oldphoto00000000.jpg';

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// A store whose uploads fail (offline for too long, Rules refused).
class _FailingPhotos extends FakeVaccinePhotoStore {
  @override
  Future<String> upload(
    String babyId,
    Uint8List jpeg, {
    String folder = 'vaccines',
  }) async => throw Exception('upload failed');
}

/// A store whose picks are over the Storage Rules' 4 MB.
class _HugePhotos extends FakeVaccinePhotoStore {
  @override
  Future<Uint8List?> pick(ImageSource source) async =>
      Uint8List(4 * 1024 * 1024 + 1);
}

SdMeal _withPhoto({required bool byLan}) => SdMeal(
  id: 'm_${'a' * 32}',
  babyId: teddyId,
  occurredAt: vnOn(10, 8, 12, 0),
  slot: SdSlot.noon,
  dish: 'Cháo bí đỏ có ảnh',
  foodIds: const ['fd_rice', 'fd_pumpkin'],
  photoPath: _old,
  createdBy: (byLan ? lan : mai).uid,
  author: CareAuthor.of(byLan ? lan : mai),
  createdAt: vnOn(10, 8, 12, 1),
  clientCreatedAt: vnOn(10, 8, 12, 1),
);

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  testWidgets('a parent adds a photo in 5c; 5b and 5d show it', (tester) async {
    final photos = FakeVaccinePhotoStore();
    final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
    await pumpRouted(
      tester,
      const SolidsScreen(),
      overrides: solidsOverrides(store: store, photos: photos),
    );
    await tester.tap(find.byKey(const Key('sdLogMeal')));
    await tester.pumpAndSettle();
    await _tap(tester, 'sdPhotoAdd');
    expect(find.text('Thêm ảnh bữa ăn'), findsWidgets);
    expect(
      find.text('Chỉ những người chăm bé trong gia đình xem được ảnh này.'),
      findsOneWidget,
    );
    await _tap(tester, 'sdPhotoCamera');
    expect(photos.uploaded.single, startsWith('babies/$teddyId/meals/'));
    expect(sdMealPhotoPath(photos.uploaded.single), isTrue);
    expect(find.byKey(const Key('sdPhotoThumb')), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('sdDish')),
        matching: find.byType(EditableText),
      ),
      'Cháo bí đỏ',
    );
    await _tap(tester, 'sdSaveMeal');
    final saved = store.meals.last;
    expect(saved.photoPath, photos.uploaded.single);
    expect(saved.toCreateJson()['photoPath'], photos.uploaded.single);
    expect(photos.removed, isEmpty);
    expect(find.byKey(Key('sdThumb_${saved.id}')), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await pumpRouted(
      tester,
      const MealHistoryScreen(),
      overrides: solidsOverrides(store: store, photos: photos),
    );
    expect(find.byKey(Key('sdThumb_${saved.id}')), findsOneWidget);
  });

  testWidgets('a parent replaces the photo: the old object is deleted', (
    tester,
  ) async {
    final photos = FakeVaccinePhotoStore();
    final m = _withPhoto(byLan: false);
    final store = FakeSolidsStore(
      meals: [...naMeals(), m],
      settings: naSettings(),
    );
    await pumpRouted(
      tester,
      MealDetailScreen(mealId: m.id),
      overrides: solidsOverrides(store: store, photos: photos),
    );
    expect(find.byKey(const Key('sdMealPhoto')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sdEditMeal')));
    await tester.pumpAndSettle();
    await _tap(tester, 'sdPhotoReplace');
    await _tap(tester, 'sdPhotoLibrary');
    final fresh = photos.uploaded.single;
    await _tap(tester, 'sdSaveMeal');
    expect(store.meals.last.photoPath, fresh);
    expect(photos.removed, [_old]);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a parent removes the photo: cleared and deleted', (
    tester,
  ) async {
    final photos = FakeVaccinePhotoStore();
    final m = _withPhoto(byLan: false);
    final store = FakeSolidsStore(
      meals: [...naMeals(), m],
      settings: naSettings(),
    );
    await pumpRouted(
      tester,
      MealDetailScreen(mealId: m.id),
      overrides: solidsOverrides(store: store, photos: photos),
    );
    await tester.tap(find.byKey(const Key('sdEditMeal')));
    await tester.pumpAndSettle();
    await _tap(tester, 'sdPhotoRemove');
    expect(find.byKey(const Key('sdPhotoAdd')), findsOneWidget);
    // Nothing is deleted before the meal is saved.
    expect(photos.removed, isEmpty);
    await _tap(tester, 'sdSaveMeal');
    expect(store.meals.last.photoPath, isNull);
    expect(store.meals.last.toEditJson(mai.uid)['photoPath'], isNull);
    expect(photos.removed, [_old]);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a caregiver replaces their photo: only the path changes', (
    tester,
  ) async {
    final photos = FakeVaccinePhotoStore();
    final m = _withPhoto(byLan: true);
    final store = FakeSolidsStore(
      meals: [...naMeals(), m],
      settings: naSettings(),
    );
    await pumpRouted(
      tester,
      MealDetailScreen(mealId: m.id),
      overrides: solidsOverrides(me: lan, store: store, photos: photos),
    );
    await tester.tap(find.byKey(const Key('sdEditMeal')));
    await tester.pumpAndSettle();
    await _tap(tester, 'sdPhotoReplace');
    await _tap(tester, 'sdPhotoCamera');
    // Replaced again before saving: still nothing deleted (Storage Rules: Cùng nuôi only).
    await _tap(tester, 'sdPhotoReplace');
    await _tap(tester, 'sdPhotoCamera');
    await _tap(tester, 'sdSaveMeal');
    expect(store.meals.last.photoPath, photos.uploaded.last);
    expect(photos.removed, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a parent closes the sheet without saving: the upload goes', (
    tester,
  ) async {
    final photos = FakeVaccinePhotoStore();
    final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
    await pumpRouted(
      tester,
      const SolidsScreen(),
      overrides: solidsOverrides(store: store, photos: photos),
    );
    await tester.tap(find.byKey(const Key('sdLogMeal')));
    await tester.pumpAndSettle();
    await _tap(tester, 'sdPhotoAdd');
    await _tap(tester, 'sdPhotoCamera');
    Navigator.of(tester.element(find.byType(MealSheet))).pop();
    await tester.pumpAndSettle();
    expect(store.calls, isEmpty);
    expect(photos.uploaded, hasLength(1));
    expect(photos.removed, photos.uploaded);
  });

  testWidgets('offline: no photo, the meal still saves', (tester) async {
    final photos = FakeVaccinePhotoStore();
    final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
    await pumpRouted(
      tester,
      const SolidsScreen(),
      overrides: solidsOverrides(store: store, photos: photos, online: false),
    );
    await tester.tap(find.byKey(const Key('sdLogMeal')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sdPhotoOffline')));
    expect(
      find.text(
        'Cần có mạng để thêm ảnh. Bữa ăn vẫn lưu được khi không có mạng.',
      ),
      findsOneWidget,
    );
    await _tap(tester, 'sdPhotoAdd');
    expect(find.byKey(const Key('sdPhotoCamera')), findsNothing);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('sdDish')),
        matching: find.byType(EditableText),
      ),
      'Cháo bí đỏ',
    );
    await _tap(tester, 'sdSaveMeal');
    expect(store.meals.last.photoPath, isNull);
    expect(store.meals.last.pending, isTrue);
    expect(photos.uploaded, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  for (final (name, photos) in [
    ('a failed upload', _FailingPhotos()),
    ('a photo over 4 MB', _HugePhotos()),
  ]) {
    testWidgets('$name: a toast, and the meal saves without it', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store, photos: photos),
      );
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      await _tap(tester, 'sdPhotoAdd');
      await _tap(tester, 'sdPhotoCamera');
      expect(
        find.text(
          'Chưa tải được ảnh. Bữa ăn vẫn lưu được; thử thêm ảnh lại sau nhé.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sdPhotoThumb')), findsNothing);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('sdDish')),
          matching: find.byType(EditableText),
        ),
        'Cháo bí đỏ',
      );
      await _tap(tester, 'sdSaveMeal');
      expect(store.meals.last.photoPath, isNull);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  }

  testWidgets('Night care, English: the field and the detail photo', (
    tester,
  ) async {
    final m = _withPhoto(byLan: false);
    final store = FakeSolidsStore(
      meals: [...naMeals(), m],
      settings: naSettings(),
    );
    await pumpRouted(
      tester,
      MealDetailScreen(mealId: m.id),
      locale: const Locale('en'),
      palette: ClPalette.nightCare,
      overrides: solidsOverrides(store: store),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sdMealPhoto')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sdEditMeal')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sdPhotoReplace')));
    expect(find.text('Meal photo'), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove photo'), findsOneWidget);
  });

  testWidgets('openMealSheet keeps a prefilled meal without a photo', (
    tester,
  ) async {
    final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => openMealSheet(
              context,
              prefill: const SdMealPrefill(foodIds: ['fd_rice']),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: solidsOverrides(store: store),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sdPhotoAdd')), findsOneWidget);
    await _tap(tester, 'sdSaveMeal');
    expect(store.meals.last.photoPath, isNull);
    expect(store.meals.last.foodIds, ['fd_rice']);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
