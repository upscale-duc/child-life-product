import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../app/local_owner.dart';
import 'auto_save_controller.dart';
import '../engagement/engagement_background.dart';

/// Tự lưu's background check when the app is closed (AR03): iOS starts a headless engine on this
/// entry point. Legacy scans retain the bounded local lease. ENG-01 may renew it only through
/// live authenticated authorization before any biometric store is opened; only metadata syncs.
@pragma('vm:entry-point')
Future<void> autoSaveBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final owner = prefs.getString('privacy.owner');
  if (owner == null) return;
  final engagement = await prepareEngagementBackground(prefs, owner);
  final until = prefs.getInt('privacy.backgroundUntil') ?? 0;
  if (engagement?.mayScan == false ||
      until <= DateTime.now().millisecondsSinceEpoch) {
    return;
  }
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      autoSaveHeadlessProvider.overrideWithValue(true),
      localOwnerProvider.overrideWithValue(owner),
      if (engagement?.sync case final sync?)
        autoSaveEngagementSyncProvider.overrideWithValue(sync),
    ],
  );
  // Kept alive until the phone destroys the engine.
  container.listen(autoSaveProvider, (_, _) {});
}
