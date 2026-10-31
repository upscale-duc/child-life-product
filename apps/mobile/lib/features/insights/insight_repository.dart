import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../rhythm/rhythm_access.dart';
import 'insight_models.dart';

/// `babies/{b}/insights/current`, live (the Firestore cache keeps the last one offline).
final insightStateProvider = StreamProvider.family<InsightState?, String>(
  (ref, babyId) => ref
      .watch(firestoreProvider)
      .doc('babies/$babyId/insights/current')
      .snapshots()
      .map((d) => InsightState.fromJson(d.data())),
);

/// D-151: this person's answers for one baby (`users/{uid}/insightPrefs/{babyId}`).
class InsightPrefs {
  const InsightPrefs({this.muted = const {}, this.votes = const {}});

  /// Kinds this person asked not to see again.
  final Set<InsightKind> muted;

  /// `{kind}_{lastNight}` → true (Có ích) / false (Chưa có ích).
  final Map<String, bool> votes;

  static String voteKey(Insight i) => '${i.kind.wire}_${isoDay(i.recentTo)}';

  bool? voteFor(Insight i) => votes[voteKey(i)];

  static InsightPrefs fromJson(Map<String, dynamic>? json) => InsightPrefs(
    muted: {
      for (final w in json?['muted'] as List? ?? const [])
        ?InsightKind.fromWire(w),
    },
    votes: {
      for (final MapEntry(:key, :value)
          in (json?['votes'] as Map? ?? const {}).entries)
        if (key is String && value is bool) key: value,
    },
  );
}

class InsightPrefsRepository {
  InsightPrefsRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String babyId) =>
      _db.doc('users/$uid/insightPrefs/$babyId');

  Stream<InsightPrefs> watch(String uid, String babyId) =>
      _doc(uid, babyId).snapshots().map((d) => InsightPrefs.fromJson(d.data()));

  Future<void> _save(String uid, String babyId, InsightPrefs p) =>
      _doc(uid, babyId).set({
        'babyId': babyId,
        'muted': [for (final k in p.muted) k.wire],
        // Only the latest 40 answers, newest last (Rules allow 60).
        'votes': Map.fromEntries(
          p.votes.entries.skip(math.max(0, p.votes.length - 40)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> vote(
    String uid,
    String babyId,
    InsightPrefs current,
    Insight insight,
    bool helpful,
  ) => _save(
    uid,
    babyId,
    InsightPrefs(
      muted: current.muted,
      votes: {...current.votes, InsightPrefs.voteKey(insight): helpful},
    ),
  );

  Future<void> setMuted(
    String uid,
    String babyId,
    InsightPrefs current,
    InsightKind kind,
    bool muted,
  ) => _save(
    uid,
    babyId,
    InsightPrefs(
      muted: muted
          ? {...current.muted, kind}
          : ({...current.muted}..remove(kind)),
      votes: current.votes,
    ),
  );
}

final insightPrefsRepositoryProvider = Provider<InsightPrefsRepository>(
  (ref) => InsightPrefsRepository(ref.watch(firestoreProvider)),
);

final insightPrefsProvider =
    StreamProvider.family<InsightPrefs, (String, String)>(
      (ref, key) =>
          ref.watch(insightPrefsRepositoryProvider).watch(key.$1, key.$2),
    );

enum InsightAccess {
  /// Parents and caregivers of a Premium household (D-150).
  full,

  /// A Free household's reader: the Premium invite (D-147, D-151 #9).
  invite,

  /// Relatives (D-151 #6), anyone without care reading, a plan not known yet (D-125).
  none,
}

InsightAccess insightAccess(Membership? me, Capabilities? caps) {
  if (me == null ||
      me.role == MemberRole.relative ||
      !familyCan(me, FamilyAction.historyRead) ||
      caps == null) {
    return InsightAccess.none;
  }
  if (caps.allows(Capability.rhythmAdvanced)) return InsightAccess.full;
  return caps.reasonFor(Capability.rhythmAdvanced) == GateReason.premiumRequired
      ? InsightAccess.invite
      : InsightAccess.none;
}

final insightAccessProvider = Provider<InsightAccess>(
  (ref) => insightAccess(
    ref.watch(selectedMembershipProvider),
    ref.watch(selectedCapabilitiesProvider),
  ),
);

/// What the surfaces draw for the selected baby.
class InsightView {
  const InsightView({
    required this.state,
    required this.stale,
    required this.today,
    required this.babyName,
    this.prefs = const InsightPrefs(),
  });

  final InsightState state;

  /// A record of the window changed since the computation: figures hidden (D-151).
  final bool stale;

  /// Baby-local `yyyy-MM-dd` of now.
  final String today;
  final String babyName;

  /// This person's answers: hidden kinds never show anywhere (D-151).
  final InsightPrefs prefs;

  /// The insight Hôm nay shows today, if any.
  Insight? get todayItem {
    if (stale || state.todayOn != today) return null;
    final kind = state.today;
    return kind == null || prefs.muted.contains(kind) ? null : state.item(kind);
  }

  /// The kind the Free invite names today, if any.
  InsightKind? get todayTeaser =>
      !stale && state.teaserOn == today ? state.teaser : null;

  List<Insight> get items => stale
      ? const []
      : [
          for (final i in state.items)
            if (!prefs.muted.contains(i.kind)) i,
        ];

  Insight? item(InsightKind kind) =>
      items.where((i) => i.kind == kind).firstOrNull;
}

/// Null while loading or with nothing computed yet (no document).
final insightViewProvider = Provider<InsightView?>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final state = ref.watch(insightStateProvider(me.babyId)).value;
  if (state == null) return null;
  final records = ref.watch(recentRecordsProvider(me.babyId)).value ?? const [];
  final baby = ref.watch(babyProvider(me.babyId)).value;
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  final now = ref.watch(careClockProvider).value ?? DateTime.now();
  return InsightView(
    state: state,
    stale: state.staleFor(records),
    today: isoDay(inBabyZone(zone, now)),
    babyName: baby?.nickname ?? '',
    prefs:
        ref.watch(insightPrefsProvider((me.uid, me.babyId))).value ??
        const InsightPrefs(),
  );
});
