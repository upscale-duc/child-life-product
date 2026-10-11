import 'package:child_life/app/environment.dart';
import 'package:child_life/app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

FirebaseOptions? _android(AppEnvironment e) =>
    firebaseOptionsFor(e, platform: TargetPlatform.android);
FirebaseOptions? _ios(AppEnvironment e) =>
    firebaseOptionsFor(e, platform: TargetPlatform.iOS);

void main() {
  test(
    'dev build with its platform id resolves to child-life-dev on both platforms',
    () {
      for (final (platform, id, options) in [
        (TargetPlatform.android, 'app.childlife.dev', _android),
        (TargetPlatform.iOS, 'dev.hsba.app', _ios),
      ]) {
        final resolved = resolveEnvironment(
          flavor: 'dev',
          packageName: id,
          platform: platform,
          optionsFor: options,
        );
        expect(resolved.environment, AppEnvironment.dev);
        expect(resolved.firebaseOptions.projectId, 'child-life-dev');
      }
    },
  );

  test('each platform only accepts its own dev id (D-045)', () {
    expect(
      () => resolveEnvironment(
        flavor: 'dev',
        packageName: 'app.childlife.dev',
        platform: TargetPlatform.iOS,
        optionsFor: _ios,
      ),
      throwsA(isA<EnvironmentConfigError>()),
    );
    expect(
      () => resolveEnvironment(
        flavor: 'dev',
        packageName: 'dev.hsba.app',
        platform: TargetPlatform.android,
        optionsFor: _android,
      ),
      throwsA(isA<EnvironmentConfigError>()),
    );
    // iOS options registered for another bundle are refused.
    expect(
      () => resolveEnvironment(
        flavor: 'dev',
        packageName: 'dev.hsba.app',
        platform: TargetPlatform.iOS,
        optionsFor: (_) => FirebaseOptions(
          apiKey: 'k',
          appId: '1:1:ios:1',
          messagingSenderId: '1',
          projectId: 'child-life-dev',
          iosBundleId: 'app.childlife.dev',
        ),
      ),
      throwsA(
        isA<EnvironmentConfigError>().having(
          (e) => e.message,
          'message',
          contains('options are for'),
        ),
      ),
    );
  });

  test('missing or unknown flavor is rejected', () {
    expect(
      () => resolveEnvironment(
        flavor: null,
        packageName: 'app.childlife.dev',
        platform: TargetPlatform.android,
        optionsFor: _android,
      ),
      throwsA(isA<EnvironmentConfigError>()),
    );
    expect(
      () => resolveEnvironment(
        flavor: 'staging',
        packageName: 'app.childlife.dev',
        platform: TargetPlatform.android,
        optionsFor: _android,
      ),
      throwsA(isA<EnvironmentConfigError>()),
    );
  });

  test('prod is refused until child-life-prod is configured', () {
    expect(
      () => resolveEnvironment(
        flavor: 'prod',
        packageName: 'app.childlife',
        platform: TargetPlatform.android,
        optionsFor: _ios,
      ),
      throwsA(
        isA<EnvironmentConfigError>().having(
          (e) => e.message,
          'message',
          contains('not configured'),
        ),
      ),
    );
  });

  test('mixed configuration is rejected', () {
    // dev flavor installed under the prod app id
    expect(
      () => resolveEnvironment(
        flavor: 'dev',
        packageName: 'app.childlife',
        platform: TargetPlatform.android,
        optionsFor: _android,
      ),
      throwsA(
        isA<EnvironmentConfigError>().having(
          (e) => e.message,
          'message',
          contains('installed as'),
        ),
      ),
    );
    // prod flavor wired to dev Firebase options
    expect(
      () => resolveEnvironment(
        flavor: 'prod',
        packageName: 'app.childlife',
        platform: TargetPlatform.android,
        optionsFor: (_) => _android(AppEnvironment.dev),
      ),
      throwsA(
        isA<EnvironmentConfigError>().having(
          (e) => e.message,
          'message',
          contains('points at'),
        ),
      ),
    );
  });
}
