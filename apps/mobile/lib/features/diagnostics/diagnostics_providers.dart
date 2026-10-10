import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';

class PingResult {
  const PingResult({
    required this.projectId,
    required this.region,
    required this.serverTime,
  });
  final String projectId;
  final String region;
  final DateTime serverTime;
}

/// Round trip to the `ping` callable of this build's environment (S0 acceptance).
final pingProvider = FutureProvider.autoDispose<PingResult>((ref) async {
  final environment = ref.watch(environmentProvider);
  final callable = ref.watch(functionsProvider).httpsCallable('ping');
  final HttpsCallableResult<Map<String, dynamic>> result = await callable
      .call<Map<String, dynamic>>({
        'clientEnvironment': environment.name,
        'opId': const Uuid().v4(),
      });
  final data = result.data;
  return PingResult(
    projectId: data['projectId'] as String,
    region: data['region'] as String,
    serverTime: DateTime.parse(data['serverTime'] as String),
  );
});

/// Reads the public flag projection (readable before sign-in by Rules).
final publicFlagsProvider = FutureProvider.autoDispose<Map<String, bool>>((
  ref,
) async {
  final snapshot = await ref
      .watch(firestoreProvider)
      .doc('publicConfig/flags')
      .get();
  final data = snapshot.data() ?? const <String, dynamic>{};
  return {
    for (final entry in data.entries)
      if (entry.value is Map)
        entry.key: (entry.value as Map)['enabled'] == true,
  };
});
