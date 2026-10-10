import 'package:firebase_core/firebase_core.dart';

/// Deployment environment of this build. Emulators are a test target, not an environment.
enum AppEnvironment {
  dev(
    bundleId: 'app.childlife.dev',
    firebaseProjectId: 'child-life-dev',
    siteHost: 'dev.childlife.app',
    // Firebase default domain until dev.childlife.app DNS is connected (plan §3.7).
    webOrigin: 'https://child-life-dev-landing.web.app',
  ),
  prod(
    bundleId: 'app.childlife',
    firebaseProjectId: 'child-life-prod',
    siteHost: 'childlife.app',
    webOrigin: 'https://childlife.app',
  );

  const AppEnvironment({
    required this.bundleId,
    required this.firebaseProjectId,
    required this.siteHost,
    required this.webOrigin,
  });

  final String bundleId;
  final String firebaseProjectId;

  /// Only links and auth redirects from this host are accepted (implementation plan §3.7).
  final String siteHost;

  /// Public website of this environment (legal pages, later invite landing).
  final String webOrigin;
}

class EnvironmentConfigError implements Exception {
  EnvironmentConfigError(this.message);
  final String message;

  @override
  String toString() => 'EnvironmentConfigError: $message';
}

/// Resolved, internally consistent configuration for this build.
class ResolvedEnvironment {
  const ResolvedEnvironment(this.environment, this.firebaseOptions);
  final AppEnvironment environment;
  final FirebaseOptions firebaseOptions;
}

/// Refuses mixed or missing configuration (engineering brief §03):
/// unknown flavor, no Firebase options for the flavor, options pointing at another
/// project, or an installed app id that belongs to the other environment.
ResolvedEnvironment resolveEnvironment({
  required String? flavor,
  required String packageName,
  required FirebaseOptions? Function(AppEnvironment) optionsFor,
}) {
  final environment = AppEnvironment.values
      .where((e) => e.name == flavor)
      .firstOrNull;
  if (environment == null) {
    throw EnvironmentConfigError(
      'Unknown or missing flavor "$flavor" — build with --flavor dev|prod',
    );
  }
  final options = optionsFor(environment);
  if (options == null) {
    throw EnvironmentConfigError(
      'Firebase is not configured for ${environment.name}',
    );
  }
  if (options.projectId != environment.firebaseProjectId) {
    throw EnvironmentConfigError(
      '${environment.name} build points at Firebase project ${options.projectId}',
    );
  }
  if (packageName != environment.bundleId) {
    throw EnvironmentConfigError(
      '${environment.name} build is installed as $packageName (expected ${environment.bundleId})',
    );
  }
  return ResolvedEnvironment(environment, options);
}
