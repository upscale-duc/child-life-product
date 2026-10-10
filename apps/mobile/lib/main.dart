import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/environment.dart';
import 'app/providers.dart';
import 'core/appearance/appearance_providers.dart';

Future<void> main() async {
  final ResolvedEnvironment resolved;
  try {
    resolved = await bootstrap();
  } on EnvironmentConfigError catch (error) {
    // Mixed or missing configuration: never start Firebase, show the reason instead.
    runApp(ConfigErrorApp(message: error.message));
    return;
  }
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        environmentProvider.overrideWithValue(resolved.environment),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const ChildLifeApp(),
    ),
  );
}
