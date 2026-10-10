import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      .map((QuerySnapshot<Map<String, dynamic>> s) {
        if (s.docs.isEmpty && s.metadata.isFromCache) return null;
        return [for (final d in s.docs) Membership.fromJson(d.data())];
      });
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
