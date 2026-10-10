import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/baby/time_zones.dart';
import 'environment.dart';
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
