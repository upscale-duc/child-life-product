import 'package:flutter/foundation.dart';

import '../../app/environment.dart';

/// OAuth client identifiers per environment (public identifiers, not secrets).
/// `null` = the provider is not configured in that Firebase project yet; the button stays
/// visible as designed and explains it is unavailable (authErrorNotConfigured).
class AuthProviderConfig {
  const AuthProviderConfig({
    this.googleServerClientId,
    this.googleIosClientId,
    this.appleIos = false,
    this.appleAndroid = false,
  });

  /// "Web client" OAuth id that Firebase verifies Google ID tokens against.
  final String? googleServerClientId;

  /// iOS OAuth client id (CLIENT_ID in GoogleService-Info.plist).
  final String? googleIosClientId;

  /// Sign in with Apple. iOS uses the native flow: the App ID's capability plus the Apple
  /// provider in Firebase (bundle id as client id). Android uses the web flow, which also needs a
  /// Services ID and a key (owner item).
  final bool appleIos;
  final bool appleAndroid;

  bool appleOn(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? appleIos : appleAndroid;
}

AuthProviderConfig authProviderConfigFor(
  AppEnvironment environment,
) => switch (environment) {
  // Google: filled in once the provider is enabled in the child-life-dev console.
  // Apple on iOS: dev.hsba.app has the capability and apple.com is enabled (D-045).
  AppEnvironment.dev => const AuthProviderConfig(appleIos: true),
  AppEnvironment.prod => const AuthProviderConfig(),
};
