import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import 'route_guard.dart';

// AppsFlyer OneLink for the invite email's "Nhận lời mời" (owner, 2026-10-12): someone without
// the app goes to the store, and the first open after installing joins on its own (deferred deep
// linking); with the app installed the OS opens it straight away and the router reads the link
// (oneLinkLocation). Keys come from `--dart-define-from-file=config/appsflyer.<flavor>.json`,
// which is gitignored; a build without them never starts the SDK, and invite links still open
// through Universal Links / App Links. No advertising identifiers, no tracking prompt, and no
// account or child data is ever given to AppsFlyer.
const _devKey = String.fromEnvironment('AF_DEV_KEY');
const _appleAppId = String.fromEnvironment('AF_APPLE_APP_ID');

/// The invite token a resolved OneLink carries, or null for any other link.
String? inviteTokenOf(DeepLinkResult result) {
  final link = result.deepLink;
  if (result.status != DeepLinkStatus.found || link == null) return null;
  if (link.deepLinkValue != 'invite') return null;
  final token = link.getStringValue('deep_link_sub1') ?? '';
  return isInviteToken(token) ? token : null;
}

/// Starts AppsFlyer once per launch; [onInvite] gets each invite token it resolves.
Future<void> startOneLink({
  required void Function(String token) onInvite,
}) async {
  if (_devKey.isEmpty || kIsWeb) return;
  final sdk = AppsFlyerSdk.instance;
  try {
    // Before init: Android decides once per install whether to ask for the deferred link.
    await sdk.registerDeepLinkListener(
      onDeepLinking: (result) {
        final token = inviteTokenOf(result);
        if (token != null) onInvite(token);
      },
    );
    await sdk.init(devKey: _devKey, appId: _appleAppId);
    await sdk.setDisableAdvertisingIdentifiers(true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await sdk.setDisableCollectASA(true);
    }
    await sdk.start();
  } on Object {
    // Optional: the OS still opens invite links, and the code works by hand.
  }
}
