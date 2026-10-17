import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../home/home_shell.dart';
import 'premium_models.dart';

class PremiumException implements Exception {
  const PremiumException(this.reason);

  /// A [GateReason] wire code, or a request problem such as `bad-request`.
  final String reason;
  GateReason? get gate => GateReason.fromWire(reason);
}

/// `getCapabilities` and `setFamilySettings` (plan §5.1). The last answer per baby is kept on the
/// phone so the plan screen draws offline; it only ever shapes the UI.
class PremiumRepository {
  PremiumRepository(this._functions, this._prefs);

  final FirebaseFunctions _functions;
  final SharedPreferences _prefs;

  static String _key(String babyId) => 'premium.capabilities.$babyId';

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return r.data is Map
          ? Map<String, dynamic>.from(r.data! as Map)
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map && details['reason'] is String
          ? details['reason'] as String
          : e.message ?? e.code;
      throw PremiumException(reason);
    }
  }

  Capabilities? cached(String babyId) {
    final raw = _prefs.getString(_key(babyId));
    if (raw == null) return null;
    try {
      return Capabilities.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<Capabilities?> fetch(String babyId) async {
    try {
      final caps = Capabilities.fromJson(
        await _call('getCapabilities', {'babyId': babyId}),
      );
      if (caps != null) {
        unawaited(_prefs.setString(_key(babyId), jsonEncode(caps.toJson())));
      }
      return caps;
    } on PremiumException catch (e) {
      // Left the family: forget what this phone knew (brief p.8 "Offline").
      if (e.reason == 'not-a-member') {
        unawaited(_prefs.remove(_key(babyId)));
        return null;
      }
      return cached(babyId);
    } on Object {
      // Offline or failing: "chưa xác minh" from the last answer, never a forced purchase.
      return cached(babyId);
    }
  }

  /// The owner sets the household's country (D-072 #3); refused for anyone else.
  Future<void> setCountry(String babyId, String country) =>
      _call('setFamilySettings', {'babyId': babyId, 'country': country});
}

// No retries: without Firebase (tests) these fail for good, and a retry timer would outlive them.
final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => PremiumRepository(
    ref.watch(functionsProvider),
    ref.watch(sharedPreferencesProvider),
  ),
  retry: (_, _) => null,
);

/// What one of my babies' household may do; null when I am not a member any more.
final capabilitiesProvider = FutureProvider.autoDispose
    .family<Capabilities?, String>((ref, babyId) async {
      // No Firebase (widget tests, a broken install): nothing to show. Touching
      // functionsProvider then would fail and leave Riverpod retry timers behind.
      if (Firebase.apps.isEmpty) return null;
      try {
        return await ref.watch(premiumRepositoryProvider).fetch(babyId);
      } on Object {
        // Anything else failing: nothing to show; the server decides every action anyway.
        return null;
      }
    }, retry: (_, _) => null);

/// [babyId]'s capabilities now, from a callback (not a build): held while they load, since an
/// auto-dispose provider nobody watches would be dropped.
Future<Capabilities?> readCapabilities(WidgetRef ref, String babyId) async {
  final hold = ref.listenManual(capabilitiesProvider(babyId).future, (_, _) {});
  try {
    return await hold.read();
  } on Object {
    return null;
  } finally {
    hold.close();
  }
}

/// The selected baby's household.
final selectedCapabilitiesProvider = Provider<Capabilities?>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  return ref.watch(capabilitiesProvider(me.babyId)).value;
});

/// Where the selected baby's family lives (D-078): the latest answer, else the one kept on this
/// phone, so Sơ cứu has it at once and offline. Null when never set.
final selectedFamilyCountryProvider = Provider<String?>((ref) {
  // Never an error: Sơ cứu reads this, and without a country it simply calls the pack's number.
  try {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return null;
    final fresh = ref.watch(capabilitiesProvider(me.babyId));
    if (fresh.hasValue) return fresh.value?.country;
    if (Firebase.apps.isEmpty) return null;
    return ref.watch(premiumRepositoryProvider).cached(me.babyId)?.country;
  } on Object {
    return null;
  }
});
