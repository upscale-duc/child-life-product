/// Where a location may be shown for a given session; pure so it is unit-tested.
library;

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const tour = '/tour';
  static const signIn = '/auth';
  static const email = '/auth/email';
  static const forgot = '/auth/forgot';
  static const exists = '/auth/exists';
  static const verify = '/auth/verify';
  static const who = '/setup/who';
  static const babyProfile = '/setup/baby';
  static const trackers = '/setup/trackers';
  static const today = '/today';
  static const appearance = '/appearance';
  static const showcase = '/showcase';
  static const diagnostics = '/diagnostics';
}

enum GuardState { loading, signedOut, needsVerifyPrompt, needsSetup, ready }

bool _under(String location, String prefix) =>
    location == prefix ||
    location.startsWith('$prefix/') ||
    location.startsWith('$prefix?');

/// Returns the location to redirect to, or null to stay.
String? guardRoute({
  required GuardState state,
  required String location,
  required bool splashDone,
}) {
  final onSplash = location == Routes.splash;
  if (state == GuardState.loading) return null;
  if (onSplash && !splashDone) return null;

  final public =
      _under(location, Routes.welcome) ||
      _under(location, Routes.tour) ||
      _under(location, Routes.signIn);
  // Dev tools stay reachable in every state; the screens themselves are dev-gated.
  final tools =
      _under(location, Routes.showcase) || _under(location, Routes.diagnostics);
  if (tools) return null;

  switch (state) {
    case GuardState.loading:
      return null;
    case GuardState.signedOut:
      return public ? null : Routes.welcome;
    case GuardState.needsVerifyPrompt:
      // Right after creating an email account (08 "Kiểm tra email").
      return location == Routes.verify ? null : Routes.verify;
    case GuardState.needsSetup:
      final allowed =
          _under(location, '/setup') ||
          _under(location, Routes.appearance) ||
          location == Routes.exists;
      return allowed ? null : Routes.who;
    case GuardState.ready:
      final onboarding = onSplash || public || _under(location, '/setup');
      return onboarding ? Routes.today : null;
  }
}
