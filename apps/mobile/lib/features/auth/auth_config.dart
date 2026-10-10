import '../../app/environment.dart';

/// OAuth client identifiers per environment (public identifiers, not secrets).
/// `null` = the provider is not configured in that Firebase project yet; the button stays
/// visible as designed and explains it is unavailable (authErrorNotConfigured).
class AuthProviderConfig {
  const AuthProviderConfig({
    this.googleServerClientId,
    this.googleIosClientId,
    this.appleConfigured = false,
  });

  /// "Web client" OAuth id that Firebase verifies Google ID tokens against.
  final String? googleServerClientId;

  /// iOS OAuth client id (CLIENT_ID in GoogleService-Info.plist).
  final String? googleIosClientId;

  /// Sign in with Apple needs an Apple Developer team, Services ID and key (owner item).
  final bool appleConfigured;
}

AuthProviderConfig authProviderConfigFor(
  AppEnvironment environment,
) => switch (environment) {
  // Google: filled in once the provider is enabled in the child-life-dev console.
  AppEnvironment.dev => const AuthProviderConfig(),
  AppEnvironment.prod => const AuthProviderConfig(),
};
