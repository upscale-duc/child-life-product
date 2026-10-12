import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'environment.dart';

/// Overridden in `main` with the resolved environment; reading it un-overridden is a bug.
final environmentProvider = Provider<AppEnvironment>(
  (ref) =>
      throw StateError('environmentProvider must be overridden at startup'),
);

/// "1.0.0 (12) · dev" for the bottom of Tôi (owner, 2026-10-12): which build this is. Prod
/// shows no environment.
final appVersionProvider = FutureProvider<String>((ref) async {
  final environment = ref.watch(environmentProvider);
  final info = await PackageInfo.fromPlatform();
  final build = '${info.version} (${info.buildNumber})';
  return environment == AppEnvironment.prod
      ? build
      : '$build · ${environment.name}';
});

const functionsRegion = 'asia-southeast1';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: functionsRegion),
);
