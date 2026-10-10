import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/baby/time_zones.dart';
import 'environment.dart';
import 'providers.dart';
import 'firebase_options.dart';

/// Resolves the environment and starts Firebase + error reporting.
/// Never attaches user, family or child data to telemetry (engineering brief §05).
Future<ResolvedEnvironment> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final resolved = resolveEnvironment(
    flavor: appFlavor,
    packageName: info.packageName,
    optionsFor: firebaseOptionsFor,
  );

  await Firebase.initializeApp(options: resolved.firebaseOptions);
  await _useEmulatorsIfRequested(resolved.environment);

  final crashlytics = FirebaseCrashlytics.instance;
  // Dev always reports (to prove the pipeline); prod reports from release builds only.
  await crashlytics.setCrashlyticsCollectionEnabled(
    resolved.environment == AppEnvironment.dev || kReleaseMode,
  );
  await crashlytics.setCustomKey('environment', resolved.environment.name);
  await crashlytics.setCustomKey(
    'appVersion',
    '${info.version}+${info.buildNumber}',
  );
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashlytics.recordError(error, stack, fatal: true));
    return true;
  };

  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  ensureTimeZones();
  return resolved;
}

/// `--dart-define=CL_EMULATORS=true` points a dev build at the local Firebase emulators
/// (`firebase emulators:start --project child-life-dev`) for end-to-end tests without touching
/// the dev project. Prod builds refuse it.
const _useEmulators = bool.fromEnvironment('CL_EMULATORS');

Future<void> _useEmulatorsIfRequested(AppEnvironment environment) async {
  if (!_useEmulators) return;
  if (environment != AppEnvironment.dev) {
    throw EnvironmentConfigError(
      'Emulators can only be used with the dev flavor',
    );
  }
  // The Android emulator reaches the host machine at 10.0.2.2.
  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(
    region: functionsRegion,
  ).useFunctionsEmulator(host, 5001);
}
