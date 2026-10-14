import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations.dart';

/// Android notification channels (Android plan A1). The server names one on every push
/// (`androidNotification` in `firebase/functions/src/social.ts`); local reminders use
/// `reminders`. Created again when the app language changes, so their names follow it.
abstract final class AndroidChannels {
  static const reminders = 'reminders';
  static const family = 'family';
  static const spending = 'spending';

  /// 10j progress and "Đã tải xong" (BackgroundUploads.kt).
  static const uploads = 'uploads';

  /// A running sleep or breastfeeding timer on the lock screen (GlanceUi.kt TimerNotice, A5).
  static const timers = 'timers';

  /// The status-bar icon (white on transparent), `res/drawable/ic_stat_notify.xml`.
  static const icon = '@drawable/ic_stat_notify';

  static Future<void> sync(AppLocalizations l10n) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    const high = Importance.high;
    for (final (id, name, description, importance) in [
      (reminders, l10n.notifChannel, l10n.notifChannelDescription, high),
      (
        family,
        l10n.notifChannelFamily,
        l10n.notifChannelFamilyDescription,
        high,
      ),
      (
        spending,
        l10n.notifChannelSpending,
        l10n.notifChannelSpendingDescription,
        high,
      ),
      // Progress and running timers should not pop up over what the person is doing.
      (
        timers,
        l10n.notifChannelTimers,
        l10n.notifChannelTimersDescription,
        Importance.low,
      ),
      (
        uploads,
        l10n.notifChannelUploads,
        l10n.notifChannelUploadsDescription,
        Importance.defaultImportance,
      ),
    ]) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          name,
          description: description,
          importance: importance,
        ),
      );
    }
  }
}
