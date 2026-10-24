import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_access.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../solids/solids_today.dart' show sdOnTodayProvider;
import '../spending/spending_models.dart' show SpendingAccess;
import '../today/today_layout.dart' show allowedActions;
import 'adaptive_engine.dart';
import 'adaptive_signals.dart' show rankSignalsProvider;

/// `users/{uid}/experience/{babyId}` (P-175, D-097 Q-089): this person's arrangement of one
/// child's Hôm nay, synced across their phones. A copy stays on the phone so the first frame
/// has it offline (D-091).
class ExperienceRepository {
  ExperienceRepository(this._db, this._prefs);
  final FirebaseFirestore _db;
  final SharedPreferences _prefs;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String babyId) =>
      _db.doc('users/$uid/experience/$babyId');

  static String _key(String uid, String babyId) => 'experience.$uid.$babyId';

  /// (the stored arrangement or null, whether the answer came from the server).
  Stream<({Experience? exp, bool fromServer})> watch(
    String uid,
    String babyId,
  ) => _doc(uid, babyId).snapshots(includeMetadataChanges: true).map((s) {
    final data = s.data();
    final exp = data == null ? null : Experience.fromJson(data);
    if (exp != null) _mirror(uid, babyId, exp);
    return (exp: exp, fromServer: !s.metadata.isFromCache);
  });

  Experience? cached(String uid, String babyId) {
    try {
      final raw = _prefs.getString(_key(uid, babyId));
      if (raw == null) return null;
      return Experience.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      return null;
    }
  }

  /// The layout this phone kept before (P-061), for the one-time migration (P-177).
  ({List<String> order, List<String> hidden})? legacyLayout(String babyId) {
    try {
      final raw = _prefs.getString('today.layout.$babyId');
      if (raw == null) return null;
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      List<String> names(Object? v) => [
        for (final n in (v is List ? v : const [])) '$n',
      ];
      return (order: names(j['order']), hidden: names(j['hidden']));
    } on Object {
      return null;
    }
  }

  /// Writes never wait for the network (offline first); the local copy updates at once.
  Future<void> save(String uid, String babyId, Experience exp) {
    _mirror(uid, babyId, exp);
    return _doc(
      uid,
      babyId,
    ).set({...exp.toJson(babyId), 'updatedAt': FieldValue.serverTimestamp()});
  }

  void _mirror(String uid, String babyId, Experience exp) {
    unawaited(
      _prefs.setString(_key(uid, babyId), jsonEncode(exp.toJson(babyId))),
    );
  }
}

final experienceRepositoryProvider = Provider<ExperienceRepository>(
  (ref) => ExperienceRepository(
    ref.watch(firestoreProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Adaptive Experience is on for the selected baby's family (`adaptive_experience`).
final adaptiveOnProvider = Provider<bool>(
  (ref) =>
      ref.watch(selectedCapabilitiesProvider)?.features.adaptiveExperience ??
      false,
);

/// Whole months of the child today, in the child's time zone (AX00 rule 7); null while the date
/// of birth is unknown or not readable by this person (a caregiver without "Thông tin của bé").
final childMonthsProvider = Provider.family<int?, String>((ref, babyId) {
  final profile = ref.watch(babyPrivateProfileProvider(babyId)).value;
  if (profile == null) return null;
  final zone =
      ref.watch(babyProvider(babyId)).value?.timeZone.zone ??
      'Asia/Ho_Chi_Minh';
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  return ageInMonths(profile.dateOfBirth, babyToday(zone, now));
});

final childBandProvider = Provider.family<AgeBand?, String>((ref, babyId) {
  final months = ref.watch(childMonthsProvider(babyId));
  return months == null ? null : ageBandFor(months);
});

final _experienceStreamProvider =
    StreamProvider.family<({Experience? exp, bool fromServer}), String>((
      ref,
      babyId,
    ) {
      final me = ref.watch(selectedMembershipProvider);
      if (me == null || me.babyId != babyId) return const Stream.empty();
      return ref.watch(experienceRepositoryProvider).watch(me.uid, babyId);
    });

/// The selected person's arrangement of [babyId]'s Hôm nay; never null. Until the person has
/// one: the phone's copy, else the layout this phone kept (P-177), else the band's defaults
/// (null band → the care-first 0–1 defaults, D-097 Q-092). The first time the server confirms
/// there is none, it is written so `bandApplied` freezes (a birthday never changes Today).
final experienceProvider =
    NotifierProvider.family<ExperienceNotifier, Experience, String>(
      ExperienceNotifier.new,
    );

class ExperienceNotifier extends Notifier<Experience> {
  ExperienceNotifier(this.babyId);
  final String babyId;
  bool _seeded = false;

  @override
  Experience build() {
    final repo = ref.watch(experienceRepositoryProvider);
    final me = ref.watch(selectedMembershipProvider);
    final band = ref.watch(childBandProvider(babyId));
    final stream = ref.watch(_experienceStreamProvider(babyId)).value;
    if (stream?.exp case final Experience exp) return exp;
    final uid = me?.babyId == babyId ? me!.uid : null;
    final initial =
        (uid == null ? null : repo.cached(uid, babyId)) ??
        _fromLegacy(repo, band ?? AgeBand.b0_1) ??
        Experience.defaults(band ?? AgeBand.b0_1);
    if (uid != null &&
        stream != null &&
        stream.fromServer &&
        stream.exp == null &&
        band != null &&
        !_seeded) {
      _seeded = true;
      // Freeze the band now; never on a later birthday.
      Future.microtask(() => repo.save(uid, babyId, initial).ignore());
    }
    return initial;
  }

  Experience? _fromLegacy(ExperienceRepository repo, AgeBand band) {
    final legacy = repo.legacyLayout(babyId);
    if (legacy == null) return null;
    return migrateTodayLayout(
      band: band,
      order: legacy.order,
      hidden: legacy.hidden,
    );
  }

  void set(Experience next) {
    state = next;
    final me = ref.read(selectedMembershipProvider);
    if (me == null || me.babyId != babyId) return;
    ref.read(experienceRepositoryProvider).save(me.uid, babyId, next).ignore();
  }

  /// AX03/AX04 or "Sửa" in AX14: new goals change the defaults at once (the person's action).
  void setGoals(List<Goal> goals) => set(
    state.copyWith(
      goals: [
        for (final g in Goal.values)
          if (goals.contains(g)) g,
      ],
      goalsSource: GoalsSource.chosen,
      bandApplied: ref.read(childBandProvider(babyId)) ?? state.bandApplied,
    ),
  );

  void setVisible(WidgetId id, bool visible) => set(
    state.copyWith(
      shown: visible
          ? {...state.shown, id}.toList()
          : [...state.shown.where((w) => w != id)],
      hidden: visible
          ? [...state.hidden.where((w) => w != id)]
          : {...state.hidden, id}.toList(),
    ),
  );

  void togglePin(WidgetId id) => set(
    state.copyWith(
      pinned: state.pinned.contains(id)
          ? [...state.pinned.where((w) => w != id)]
          : [...state.pinned, id],
    ),
  );

  /// The full order after a drag (pinned ones excluded; they stay first).
  void reorder(List<WidgetId> order) => set(state.copyWith(order: order));

  /// "Khôi phục gợi ý theo tuổi của …" (AX14).
  void restore() => set(
    applyBand(
      state,
      ref.read(childBandProvider(babyId)) ?? state.bandApplied,
      restore: true,
    ),
  );
}

/// The Hôm nay widgets this person may have for [babyId] right now: released, flagged, allowed
/// by the role and backed by data (AX00 rule 4). Caregivers get care widgets only (D-097 Q-092);
/// relatives with "Chăm sóc hằng ngày" the read-only care view (D-018).
final availableWidgetsProvider = Provider.family<Set<WidgetId>, String>((
  ref,
  babyId,
) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || me.babyId != babyId) return const {};
  final trackers =
      ref.watch(babyProvider(babyId)).value?.trackers ?? const <TrackerKind>[];
  final features = ref.watch(selectedCapabilitiesProvider)?.features;
  final keepsakes = ref.watch(selectedKeepsakeAccessProvider);
  final parent = me.role == MemberRole.coParent;
  final caregiver = me.role == MemberRole.caregiver;
  final relative = me.role == MemberRole.relative;
  return {
    if (trackers.isNotEmpty) WidgetId.tiles,
    if (features?.rhythm ?? false) WidgetId.forYou,
    if (ref.watch(sdOnTodayProvider)) WidgetId.solids,
    WidgetId.rhythm,
    if (!relative) ...{
      WidgetId.reminders,
      WidgetId.vaccine,
      if (allowedActions(me).isNotEmpty) WidgetId.quickActions,
    },
    if (!caregiver && !relative) ...{
      if (SpendingAccess.of(me).viewAll) WidgetId.spending,
      WidgetId.recentMemories,
      WidgetId.growth,
    },
    if (parent) ...{
      WidgetId.momentToday,
      WidgetId.familyView,
      if (keepsakes.cards || keepsakes.videos) WidgetId.createFromMemories,
    },
  };
});

/// Hôm nay for [babyId], ranked (P-175) with this visit's usage and recency
/// (`adaptive_signals.dart`, frozen per run so nothing moves under the finger).
final adaptiveTodayProvider = Provider.family<List<RankedWidget>, String>(
  (ref, babyId) => rankToday(
    ref.watch(experienceProvider(babyId)),
    ref.watch(availableWidgetsProvider(babyId)),
    ref.watch(rankSignalsProvider(babyId)),
  ),
);
