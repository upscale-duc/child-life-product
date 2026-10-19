import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../library/content_models.dart' show lbDefaultEmergency;
import '../library/content_repository.dart'
    show LbFeed, contentEmergencyNumberProvider;
import 'nutrition_models.dart';

/// Reads the published nutrition content (D-083) and the per-baby vitamin A record. Firestore
/// keeps its own offline copy of every document read, so a family that opened Dinh dưỡng once
/// still sees it offline; the vitamin A write is queued on the device like every other write
/// (nothing waits for the server).
class NutritionStore {
  NutritionStore(this._db);

  final FirebaseFirestore Function() _db;

  static const stages = 'contentNutritionStages';
  static const nutrients = 'contentNutrients';
  static const rules = 'contentNutritionRules';

  Stream<LbFeed<T>> _published<T>(
    String collection,
    T? Function(String id, Map<String, Object?> data) parse,
  ) => _db()
      .collection(collection)
      // The Rules allow lists only with this filter (as for `contentStages`).
      .where('status', isEqualTo: 'published')
      .snapshots(includeMetadataChanges: true)
      .map(
        (q) => (
          items: [for (final d in q.docs) ?parse(d.id, d.data())],
          fromCache: q.metadata.isFromCache,
        ),
      );

  /// The published content with [emergency] in place of every `{emergency}` (D-087).
  Stream<LbFeed<NuStage>> watchStages({
    String emergency = lbDefaultEmergency,
  }) => _published(
    stages,
    (id, d) => NuStage.fromDoc(id, d, emergency: emergency),
  );

  Stream<LbFeed<NuNutrient>> watchNutrients({
    String emergency = lbDefaultEmergency,
  }) => _published(
    nutrients,
    (id, d) => NuNutrient.fromDoc(id, d, emergency: emergency),
  );

  Stream<LbFeed<NuRule>> watchRules({String emergency = lbDefaultEmergency}) =>
      _published(rules, (id, d) => NuRule.fromDoc(id, d, emergency: emergency));

  DocumentReference<Map<String, dynamic>> _vitaminA(String babyId) =>
      _db().doc('babies/$babyId/nutrition/vitaminA');

  /// `taken` of `babies/{babyId}/nutrition/vitaminA` (`{"2026-06": "2026-06-01"}`).
  Stream<Map<String, String>> watchVitaminA(String babyId) => _vitaminA(
    babyId,
  ).snapshots().map((d) => nuParseTaken(d.data()?['taken']));

  /// "Đánh dấu đã uống" ([takenOn] `YYYY-MM-DD`) or "Bỏ đánh dấu" (null) for the round [key];
  /// active Cùng nuôi only (Rules). Merged, so two parents marking different rounds at once both
  /// stay.
  void setVitaminTaken(
    String babyId,
    String key,
    String? takenOn,
    String uid, {
    void Function(Object error)? onError,
  }) {
    _vitaminA(babyId)
        .set({
          'taken': {key: takenOn ?? FieldValue.delete()},
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        }, SetOptions(merge: true))
        .catchError((Object e) => onError?.call(e));
  }
}

final nutritionStoreProvider = Provider<NutritionStore>(
  (ref) => NutritionStore(() => ref.read(firestoreProvider)),
);

/// Signed in, with Firebase set up (Chăm sóc only peeks at the content: without Firebase, e.g. in
/// widget tests, nothing is published).
bool _canRead(Ref ref) =>
    ref.watch(sessionProvider) is SessionSignedIn && Firebase.apps.isNotEmpty;

LbFeed<T> _none<T>() => (items: <T>[], fromCache: false);

final nuStagesProvider = StreamProvider<LbFeed<NuStage>>((ref) {
  if (!_canRead(ref)) return Stream.value(_none());
  return ref
      .watch(nutritionStoreProvider)
      .watchStages(emergency: ref.watch(contentEmergencyNumberProvider));
});

final nuNutrientsProvider = StreamProvider<LbFeed<NuNutrient>>((ref) {
  if (!_canRead(ref)) return Stream.value(_none());
  return ref
      .watch(nutritionStoreProvider)
      .watchNutrients(emergency: ref.watch(contentEmergencyNumberProvider));
});

final nuRulesProvider = StreamProvider<LbFeed<NuRule>>((ref) {
  if (!_canRead(ref)) return Stream.value(_none());
  return ref
      .watch(nutritionStoreProvider)
      .watchRules(emergency: ref.watch(contentEmergencyNumberProvider));
});

/// The vitamin A rounds a baby took (members of the baby read it).
final nuVitaminTakenProvider =
    StreamProvider.family<Map<String, String>, String>((ref, babyId) {
      if (!_canRead(ref)) return Stream.value(const {});
      return ref.watch(nutritionStoreProvider).watchVitaminA(babyId);
    });
