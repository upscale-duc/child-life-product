import 'dart:async';

/// FAM-01: synchronous authority for device-only child data. Server rules remain
/// authoritative for network reads. A changed session invalidates in-flight results.
class LocalPrivacy {
  String? owner;
  Set<String> babies = const {};
  Set<String> parents = const {};
  Map<String, DateTime> expires = const {};
  Map<String, String> policies = const {};
  int generation = 0;
  Future<void> Function()? cleanup;

  void bind(
    String? uid,
    Set<String> allowed, {
    Set<String> coParents = const {},
    Map<String, DateTime> until = const {},
    Map<String, String> permissions = const {},
  }) {
    if (owner != uid ||
        !babies.containsAll(allowed) ||
        !allowed.containsAll(babies) ||
        !parents.containsAll(coParents) ||
        !coParents.containsAll(parents) ||
        !_same(expires, until) ||
        !_same(policies, permissions)) {
      generation++;
    }
    owner = uid;
    babies = Set.unmodifiable(allowed);
    parents = Set.unmodifiable(coParents);
    expires = Map.unmodifiable(until);
    policies = Map.unmodifiable(permissions);
  }

  bool _same<T>(Map<String, T> a, Map<String, T> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  int authorize(String uid, String path) {
    final parts = path.split('/');
    if (owner != uid ||
        parts.length < 3 ||
        parts.first != 'babies' ||
        !babies.contains(parts[1]) ||
        (expires[parts[1]] != null &&
            !expires[parts[1]]!.isAfter(DateTime.now()))) {
      throw StateError('local-access-denied');
    }
    return generation;
  }

  void check(int epoch) {
    if (epoch != generation || owner == null) {
      throw StateError('local-session-changed');
    }
  }

  Future<void> signOut() async {
    bind(null, const {});
    await cleanup?.call();
  }
}

final localPrivacy = LocalPrivacy();
