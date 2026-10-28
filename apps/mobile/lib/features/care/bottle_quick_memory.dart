import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import 'bottle_suggestions.dart';
import 'care_models.dart';

bool _valid(int ml) =>
    ml >= CareLimits.bottleMl.min && ml <= CareLimits.bottleMl.max;

/// Two shortcuts, never a feeding recommendation: most recent distinct inputs,
/// then the approved age table. The free-entry sheet remains available as Other.
List<int> homeBottlePicks({
  required int? ageDays,
  required Iterable<int> remembered,
  required Iterable<int> recent,
  BottleTable table = BottleTable.bundled,
}) => <int>{
  ...remembered.where(_valid),
  ...recent.where(_valid),
  ...bottleSuggestions(ageDays, table),
}.take(2).toList(growable: false);

final bottleQuickMemoryProvider =
    NotifierProvider<BottleQuickMemory, List<int>>(BottleQuickMemory.new);

/// Only two numbers, scoped to this person and child on this device. Account/
/// access changes purge these keys in LocalPrivacyGuard like other local care data.
class BottleQuickMemory extends Notifier<List<int>> {
  static String keyFor(String uid, String babyId) =>
      'care.quickAmounts.$uid.$babyId';

  @override
  List<int> build() {
    final me = ref.watch(selectedMembershipProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    if (me == null) return const [];
    return (prefs.getStringList(keyFor(me.uid, me.babyId)) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .where(_valid)
        .toSet()
        .take(2)
        .toList();
  }

  void remember(int amount) {
    final me = ref.read(selectedMembershipProvider);
    if (me == null || !_valid(amount)) return;
    state = <int>{amount, ...state}.take(2).toList(growable: false);
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setStringList(
            keyFor(me.uid, me.babyId),
            state.map((n) => '$n').toList(),
          )
          .catchError((Object _) => false),
    );
  }
}
