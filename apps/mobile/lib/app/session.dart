import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appearance/appearance_providers.dart';
import '../features/auth/auth_repository.dart';
import '../features/baby/baby_models.dart';
import 'providers.dart';

/// Who is using the app right now; drives routing (R-007, R-012) and the selected baby.
sealed class Session {
  const Session();
}

class SessionLoading extends Session {
  const SessionLoading();
}

class SessionSignedOut extends Session {
  const SessionSignedOut();
}

class SessionSignedIn extends Session {
  const SessionSignedIn({required this.user, required this.memberships});

  final User user;
  final List<Membership> memberships;

  List<Membership> get active => [
    for (final m in memberships)
      if (m.isActive) m,
  ];
  bool get hasBaby => active.isNotEmpty;

  /// "Vào ngay" (16b, R-030): a temporary identity until "Lưu tài khoản" (16d).
  bool get isAnonymous => user.isAnonymous;

  Membership? membershipFor(String babyId) =>
      active.where((m) => m.babyId == babyId).firstOrNull;

  /// Email accounts that have not opened the verification link (P-008: may continue).
  bool get emailUnverified =>
      !user.emailVerified &&
      user.providerData.any((p) => p.providerId == 'password');
}

/// "My babies": memberships of the signed-in account. An empty answer from the local cache is
/// not trusted (a fresh install offline would otherwise look like a brand-new parent).
final membershipsProvider = StreamProvider.family<List<Membership>?, String>((
  ref,
  uid,
) {
  return ref
      .watch(firestoreProvider)
      .collectionGroup('members')
      .where('uid', isEqualTo: uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.isEmpty && s.metadata.isFromCache
            ? null
            : [for (final d in s.docs) d.data()],
      )
      // Metadata-only snapshots (fromCache, pending writes) repeat the same data. Session and
      // Membership have no value equality, so passing them on rebuilds every session watcher.
      .distinct(sameFirestoreData)
      .map(
        (docs) => docs == null
            ? null
            : [for (final d in docs) Membership.fromJson(d)],
      );
});

final sessionProvider = Provider<Session>((ref) {
  final auth = ref.watch(authUserProvider);
  final user = auth.value;
  if (auth.isLoading && user == null) return const SessionLoading();
  if (user == null) return const SessionSignedOut();
  final memberships = ref.watch(membershipsProvider(user.uid));
  final list = memberships.value;
  if (list == null) {
    // Permission or network errors after a timeout fall back to "no babies yet" rather than
    // keeping the user on the splash forever.
    return memberships.hasError
        ? SessionSignedIn(user: user, memberships: const [])
        : const SessionLoading();
  }
  return SessionSignedIn(user: user, memberships: list);
});

/// This device has signed in to a real account before (v1.0 368:837, P-128): signed out, it
/// opens R1 "Chào mừng trở lại" instead of 01 and the tour. Kept in app preferences, so a
/// reinstall shows onboarding again.
final signedInBeforeProvider = NotifierProvider<SignedInBefore, bool>(
  SignedInBefore.new,
);

class SignedInBefore extends Notifier<bool> {
  static const key = 'device.signedInBefore';

  @override
  bool build() {
    try {
      return ref.read(sharedPreferencesProvider).getBool(key) ?? false;
    } on Object {
      return false;
    }
  }

  void mark() {
    if (state) return;
    state = true;
    try {
      ref.read(sharedPreferencesProvider).setBool(key, true);
    } on Object {
      // No preferences (tests).
    }
  }
}

/// The in-app splash (00) shows for at most ~1 s while the session resolves (R-006).
final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

class SplashDone extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    _timer = Timer(const Duration(milliseconds: 900), () => state = true);
    ref.onDispose(() => _timer?.cancel());
    return false;
  }
}

/// Users who chose "Để sau" on 08 for this account (P-008); kept for the app session.
final verifyDeferredProvider = NotifierProvider<VerifyDeferred, Set<String>>(
  VerifyDeferred.new,
);

class VerifyDeferred extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void defer(String uid) => state = {...state, uid};
}

/// Babies this device has shown for each account, so a membership that later ends (removed,
/// expired, R-025) is noticed — on the next launch too — and 9d is shown once.
final knownBabiesProvider = NotifierProvider<KnownBabies, Set<String>>(
  KnownBabies.new,
);

class KnownBabies extends Notifier<Set<String>> {
  String? _key;

  @override
  Set<String> build() {
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) {
      _key = null;
      return const {};
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final key = _key = 'family.knownBabies.${session.user.uid}';
    final saved = prefs.getStringList(key)?.toSet() ?? <String>{};
    final merged = {...saved, for (final m in session.active) m.babyId};
    if (merged.length != saved.length) {
      prefs.setStringList(key, merged.toList());
    }
    return merged;
  }

  /// "Về trang chính" on 9d: the lost baby is acknowledged and forgotten on this device.
  void forget(String babyId) {
    final key = _key;
    if (key == null) return;
    state = {...state}..remove(babyId);
    ref.read(sharedPreferencesProvider).setStringList(key, state.toList());
  }
}

/// The baby whose access ended while this device knew it (9d), if any. "Left" and "merged"
/// memberships are the user's own doing and do not show 9d.
final lostAccessBabyIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return null;
  final known = ref.watch(knownBabiesProvider);
  final now = DateTime.now();
  for (final m in session.memberships) {
    final ended =
        m.status == MembershipStatus.removed ||
        m.status == MembershipStatus.expired ||
        (m.status == MembershipStatus.active && !m.isActiveAt(now));
    if (ended &&
        known.contains(m.babyId) &&
        session.membershipFor(m.babyId) == null) {
      return m.babyId;
    }
  }
  return null;
});

/// While a temporary identity is being saved into an existing account (16d → P-007), the new
/// account briefly has no babies; routing waits instead of opening setup.
final accountMergeInProgressProvider =
    NotifierProvider<AccountMergeInProgress, bool>(AccountMergeInProgress.new);

class AccountMergeInProgress extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// "Thêm hồ sơ bé" (9x) reopens setup (10a → 11 → 12) for an account that has a baby.
final addingBabyProvider = NotifierProvider<AddingBaby, bool>(AddingBaby.new);

class AddingBaby extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Waits (≤ [timeout]) until "my babies" includes [babyId] — after createBabyProfile or
/// acceptFamilyInvite, before routing to Today (otherwise the guard would bounce back). False
/// when it has not arrived yet (FJ-4): the caller says so instead of routing on.
Future<bool> waitForMembership(
  ProviderContainer container,
  String babyId, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  bool arrived() {
    final session = container.read(sessionProvider);
    return session is SessionSignedIn && session.membershipFor(babyId) != null;
  }

  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (arrived()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  return arrived();
}

/// Deep equality for Firestore document data (maps, lists, Timestamps).
@visibleForTesting
bool sameFirestoreData(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.entries.every(
          (e) => b.containsKey(e.key) && sameFirestoreData(e.value, b[e.key]),
        );
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!sameFirestoreData(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
