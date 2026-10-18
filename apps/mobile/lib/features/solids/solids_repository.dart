import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../library/content_repository.dart' show LbFeed;
import 'solids_models.dart';

/// Ăn dặm data (D-085): the published food catalogue, and per baby the settings and the meals.
///
/// Meals are written like care records (`care_repository.dart`): straight to Firestore, which
/// queues them on the device while offline and across restarts; nothing waits for the server, so
/// the diary updates at once from the local cache ("Chờ đồng bộ" while pending). Deletes are soft
/// (the 30-day bin, P-164 #4); clients never hard-delete a meal.
class SolidsStore {
  SolidsStore(this._db);

  final FirebaseFirestore Function() _db;

  static const foods = 'contentFoods';
  static const recipes = 'contentRecipes';

  /// Every meal of a baby fits one listener for years (≈ 3 a day); newest first.
  static const mealLimit = 3000;

  Stream<LbFeed<SdFood>> watchFoods() => _db()
      .collection(foods)
      // The Rules allow lists only with this filter (as for the other content kinds).
      .where('status', isEqualTo: 'published')
      .snapshots(includeMetadataChanges: true)
      .map(
        (q) => (
          items: [for (final d in q.docs) ?SdFood.fromDoc(d.id, d.data())],
          fromCache: q.metadata.isFromCache,
        ),
      );

  /// Published recipes (5f, 5g); Firestore keeps its offline copy once read (P-164 #18).
  Stream<LbFeed<SdRecipe>> watchRecipes() => _db()
      .collection(recipes)
      .where('status', isEqualTo: 'published')
      .snapshots(includeMetadataChanges: true)
      .map(
        (q) => (
          items: [for (final d in q.docs) ?SdRecipe.fromDoc(d.id, d.data())],
          fromCache: q.metadata.isFromCache,
        ),
      );

  DocumentReference<Map<String, dynamic>> _settings(String babyId) =>
      _db().doc('babies/$babyId/solids/settings');

  /// Null until a Cùng nuôi turns tracking on (5a).
  Stream<SdSettings?> watchSettings(String babyId) =>
      _settings(babyId).snapshots().map((d) => SdSettings.fromJson(d.data()));

  /// The whole document each time (strict shape); active Cùng nuôi only (Rules).
  void saveSettings(
    String babyId,
    SdSettings settings,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _settings(
      babyId,
    ).set(settings.toJson(uid)).catchError((Object e) => onError?.call(e));
  }

  CollectionReference<Map<String, dynamic>> _meals(String babyId) =>
      _db().collection('babies/$babyId/meals');

  /// Live meals, newest first, with pending flags. Ordered on `occurredAt` alone (no composite
  /// index); soft-deleted meals (kept 30 days) are dropped here.
  Stream<List<SdMeal>> watchMeals(String babyId) => _meals(babyId)
      .orderBy('occurredAt', descending: true)
      .limit(mealLimit)
      .snapshots(includeMetadataChanges: true)
      .map(
        (q) => [
          for (final d in q.docs)
            if (SdMeal.fromSnapshot(d) case final m? when !m.deleted) m,
        ],
      );

  void create(SdMeal meal, {void Function(Object error)? onError}) {
    _meals(meal.babyId)
        .doc(meal.id)
        .set(meal.toCreateJson())
        .catchError((Object e) => onError?.call(e));
  }

  void edit(SdMeal meal, String uid, {void Function(Object error)? onError}) {
    _meals(meal.babyId)
        .doc(meal.id)
        .update(meal.toEditJson(uid))
        .catchError((Object e) => onError?.call(e));
  }

  /// "Xoá": into the 30-day bin.
  void softDelete(
    SdMeal meal,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _meals(meal.babyId)
        .doc(meal.id)
        .update({
          'deleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        })
        .catchError((Object e) => onError?.call(e));
  }

  /// "Hoàn tác".
  void restore(
    SdMeal meal,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _meals(meal.babyId)
        .doc(meal.id)
        .update({
          'deleted': false,
          'deletedAt': null,
          'deletedBy': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        })
        .catchError((Object e) => onError?.call(e));
  }
}

final solidsStoreProvider = Provider<SolidsStore>(
  (ref) => SolidsStore(() => ref.read(firestoreProvider)),
);

/// Signed in, with Firebase set up (Chăm sóc and Hôm nay only peek at Ăn dặm: without Firebase,
/// e.g. in widget tests, nothing is tracked and nothing is published).
bool _canRead(Ref ref) =>
    ref.watch(sessionProvider) is SessionSignedIn && Firebase.apps.isNotEmpty;

/// The published catalogue (empty until phase C publishes foods; logging still works with free
/// names).
final sdFoodsProvider = StreamProvider<LbFeed<SdFood>>((ref) {
  if (!_canRead(ref)) {
    return Stream.value((items: const <SdFood>[], fromCache: false));
  }
  return ref.watch(solidsStoreProvider).watchFoods();
});

/// The published recipes (5f, 5g, "Dành cho {bé}"); empty until the portal publishes some.
final sdRecipesProvider = StreamProvider<LbFeed<SdRecipe>>((ref) {
  if (!_canRead(ref)) {
    return Stream.value((items: const <SdRecipe>[], fromCache: false));
  }
  return ref.watch(solidsStoreProvider).watchRecipes();
});

/// A baby's settings (null: never turned on). Members who read care read it.
final sdSettingsProvider = StreamProvider.family<SdSettings?, String>((
  ref,
  babyId,
) {
  if (!_canRead(ref)) return Stream.value(null);
  return ref.watch(solidsStoreProvider).watchSettings(babyId);
});

/// A baby's live meals, newest first.
final sdMealsProvider = StreamProvider.family<List<SdMeal>, String>((
  ref,
  babyId,
) {
  if (!_canRead(ref)) return Stream.value(const []);
  return ref.watch(solidsStoreProvider).watchMeals(babyId);
});
