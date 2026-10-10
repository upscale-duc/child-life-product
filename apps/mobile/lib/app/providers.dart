import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'environment.dart';

/// Overridden in `main` with the resolved environment; reading it un-overridden is a bug.
final environmentProvider = Provider<AppEnvironment>(
  (ref) =>
      throw StateError('environmentProvider must be overridden at startup'),
);

const functionsRegion = 'asia-southeast1';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: functionsRegion),
);
