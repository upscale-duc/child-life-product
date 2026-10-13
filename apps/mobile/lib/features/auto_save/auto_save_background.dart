import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/appearance_providers.dart';
import 'auto_save_controller.dart';

/// Tự lưu's background check when the app is closed (AR03): iOS starts a headless engine on this
/// entry point (AutoSaveBackground in ios/Runner/AutoSave.swift). There is no UI, no Firebase and
/// no session here; the controller reads the state kept on this phone, tells the phone it is
/// ready, and answers its `backgroundCheck` with the notification text, if any.
@pragma('vm:entry-point')
Future<void> autoSaveBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      autoSaveHeadlessProvider.overrideWithValue(true),
    ],
  );
  // Kept alive until the phone destroys the engine.
  container.listen(autoSaveProvider, (_, _) {});
}
