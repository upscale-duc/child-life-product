import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/environment.dart';
import 'app/providers.dart';
import 'core/appearance/appearance_providers.dart';
import 'features/today/header_photo_cache.dart';

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
  // Decode the previously selected wallpaper locally before the first app frame.
  // Missing/purged cache falls back to the ordinary authorized image loader.
  HeaderPhotoCache headerPhotos;
  try {
    headerPhotos = await HeaderPhotoCache.open(
      preferences,
      uid: FirebaseAuth.instance.currentUser?.uid,
    );
  } on Object {
    headerPhotos = HeaderPhotoCache();
  }
  runApp(
    ProviderScope(
      overrides: [
        environmentProvider.overrideWithValue(resolved.environment),
        sharedPreferencesProvider.overrideWithValue(preferences),
        headerPhotoCacheProvider.overrideWithValue(headerPhotos),
      ],
      child: const ChildLifeApp(),
    ),
  );
}
