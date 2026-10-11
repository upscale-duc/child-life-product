import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'environment.dart';

/// Firebase client options per environment and platform. These are public identifiers, not
/// secrets; API keys are restricted per app in Google Cloud. Prod is `null` until
/// `child-life-prod` exists, so prod builds stop at startup instead of using dev.
FirebaseOptions? firebaseOptionsFor(
  AppEnvironment environment, {
  TargetPlatform? platform,
}) {
  final target = platform ?? defaultTargetPlatform;
  switch (environment) {
    case AppEnvironment.dev:
      return switch (target) {
        TargetPlatform.android => const FirebaseOptions(
          apiKey: 'AIzaSyAzN6FIWRO_Hf_ssmuotUyea0bygE6FWXk',
          appId: '1:759703503909:android:4462edb2fcd2ebbfca6bcc',
          messagingSenderId: '759703503909',
          projectId: 'child-life-dev',
          storageBucket: 'child-life-dev.firebasestorage.app',
        ),
        TargetPlatform.iOS => const FirebaseOptions(
          apiKey: 'AIzaSyCPSQwcdn5Vz0uGmcbxs-fXCsBgs_0SW0g',
          appId: '1:759703503909:ios:01eb224b87e45474ca6bcc',
          messagingSenderId: '759703503909',
          projectId: 'child-life-dev',
          storageBucket: 'child-life-dev.firebasestorage.app',
          iosBundleId: 'dev.hsba.app',
        ),
        _ => null,
      };
    case AppEnvironment.prod:
      return null;
  }
}
