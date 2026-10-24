import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/analytics/product_analytics.dart';
import 'package:child_life/features/adaptive/experience_repository.dart';
import 'package:child_life/features/home/home_shell.dart'
    show adaptiveNavProvider;
import 'package:child_life/features/keepsakes/keepsake_access.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Adaptive Experience (P-175): the person's arrangement in memory, every write recorded.
class FakeExperienceRepository implements ExperienceRepository {
  FakeExperienceRepository([this.stored]);
  Experience? stored;
  final saves = <Experience>[];

  @override
  Stream<({Experience? exp, bool fromServer})> watch(
    String uid,
    String babyId,
  ) => Stream.value((exp: stored, fromServer: true));

  @override
  Experience? cached(String uid, String babyId) => null;

  @override
  ({List<String> order, List<String> hidden})? legacyLayout(String babyId) =>
      null;

  @override
  Future<void> save(String uid, String babyId, Experience exp) async {
    stored = exp;
    saves.add(exp);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The flag on, the child in [band], [repo] as the arrangement, [media] in Kỷ niệm, Kỷ niệm 2.0
/// betas on.
List<Override> adaptiveOverrides({
  required AgeBand band,
  required FakeExperienceRepository repo,
  List<MediaItem> media = const [],
  bool adaptive = true,
  bool nav = false,

  /// The child's whole months (AX33); null = from the fixture's date of birth.
  int? months,
}) => [
  adaptiveOnProvider.overrideWithValue(adaptive),
  // No Functions in widget tests: the MET-01 outbox is off.
  productAnalyticsReporterProvider.overrideWithValue(null),
  if (months != null) childMonthsProvider.overrideWith((ref, id) => months),
  adaptiveNavProvider.overrideWithValue(nav),
  childBandProvider.overrideWith((ref, id) => band),
  experienceRepositoryProvider.overrideWithValue(repo),
  mediaProvider.overrideWith((ref, key) => Stream.value(media)),
  selectedKeepsakeAccessProvider.overrideWithValue((cards: true, videos: true)),
];
