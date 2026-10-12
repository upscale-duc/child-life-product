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

/// UP6 Tôi · Phiên bản (D-061): "1.0.3" on prod; "1.0.3 (86) · dev" elsewhere, so testers can
/// tell builds apart.
final appVersionProvider = FutureProvider<String>((ref) async {
  final environment = ref.watch(environmentProvider);
  final info = await PackageInfo.fromPlatform();
  return environment == AppEnvironment.prod
      ? info.version
      : '${info.version} (${info.buildNumber}) · ${environment.name}';
}, retry: (_, _) => null);

const functionsRegion = 'asia-southeast1';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: functionsRegion),
);
