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
    'dev build with dev id resolves to child-life-dev on both platforms',
    () {
      for (final options in [_android, _ios]) {
        final resolved = resolveEnvironment(
          flavor: 'dev',
          packageName: 'app.childlife.dev',
          optionsFor: options,
        );
        expect(resolved.environment, AppEnvironment.dev);
        expect(resolved.firebaseOptions.projectId, 'child-life-dev');
      }
    },
  );

  test('missing or unknown flavor is rejected', () {
    expect(
      () => resolveEnvironment(
        flavor: null,
        packageName: 'app.childlife.dev',
        optionsFor: _android,
      ),
      throwsA(isA<EnvironmentConfigError>()),
    );
    expect(
      () => resolveEnvironment(
        flavor: 'staging',
        packageName: 'app.childlife.dev',
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
