import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/environment.dart';

/// "Mở Mail" (08): opens the mail app's inbox, not a compose screen.
Future<bool> openMailApp() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_EMAIL',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ).launch();
      return true;
    }
    return await launchUrl(
      Uri.parse('message://'),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    return false;
  }
}

/// "Điều khoản · Quyền riêng tư" (06) → the environment's legal page, in an in-app browser.
Future<void> openLegal(AppEnvironment environment, String languageCode) {
  final path = languageCode == 'vi' ? '/quyen-rieng-tu/' : '/en/privacy/';
  return launchUrl(
    Uri.parse('${environment.webOrigin}$path'),
    mode: LaunchMode.inAppBrowserView,
  );
}

/// After a denied camera / photo permission (11c, G-001): this app's page in system settings.
Future<void> openAppSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final info = await PackageInfo.fromPlatform();
    await AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:${info.packageName}',
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    return;
  }
  await launchUrl(
    Uri.parse('app-settings:'),
    mode: LaunchMode.externalApplication,
  );
}

/// "Cài đặt" on 8d: this app's notification settings (Android), or its settings page (iOS).
Future<void> openNotificationSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final info = await PackageInfo.fromPlatform();
    await AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: {'android.provider.extra.APP_PACKAGE': info.packageName},
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    return;
  }
  await openAppSettings();
}
