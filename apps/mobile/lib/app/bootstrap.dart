import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/baby/time_zones.dart';
import '../features/feedback/review_prompt.dart';
import 'environment.dart';
import 'providers.dart';
import 'firebase_options.dart';

/// Resolves the environment and starts Firebase + error reporting.
/// Never attaches user, family or child data to telemetry (engineering brief §05).
Future<ResolvedEnvironment> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Video playback in the Memories viewer (10f).
  MediaKit.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final resolved = resolveEnvironment(
    flavor: appFlavor,
    packageName: info.packageName,
    platform: defaultTargetPlatform,
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
  // FB5: no rating prompt after a crash or an error (D-065).
  ReviewSession.afterError = await crashlytics.didCrashOnPreviousExecution();
  FlutterError.onError = (details) {
    ReviewSession.afterError = true;
    crashlytics.recordFlutterFatalError(details);
  };
  // Dev builds show what broke instead of the grey release error box, so testers can send a
  // screenshot (no child data in an exception message; prod keeps the default).
  if (resolved.environment == AppEnvironment.dev) {
    ErrorWidget.builder = (details) => DevErrorBox(details);
  }
  PlatformDispatcher.instance.onError = (error, stack) {
    ReviewSession.afterError = true;
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
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

/// What a dev build shows in place of a widget that failed to build.
class DevErrorBox extends StatelessWidget {
  const DevErrorBox(this.details, {super.key});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final text = [
      details.exceptionAsString(),
      ...?details.stack
          ?.toString()
          .split('\n')
          .where((l) => l.contains('package:child_life'))
          .take(8),
    ].join('\n');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF3A1F1F),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onLongPress: () => Clipboard.setData(ClipboardData(text: text)),
              child: Text(
                'Lỗi (bản dev · giữ để sao chép)\n\n$text',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFFFFE4E4),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
