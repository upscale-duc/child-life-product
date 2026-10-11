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

  /// Chăm sóc tab (v1.0 improvement 370:1971): 20 Lịch sử, 20g / 20h, reminders; the dock stays.
  static const care = '/care';
  static const history = '/care/history';
  static const feedStats = '/care/stats/feed';
  static const sleepStats = '/care/stats/sleep';
  static const reminders = '/care/reminders';

  /// Rule reminders (v1.0 1a–1h): `/new`, `/{id}`, `/{id}/edit`.
  static const ruleDetail = '/care/reminders/rules';
  static const ruleNew = '/care/reminders/rules/new';
  static const messages = '/messages';
  static const memories = '/memories';
  static const family = '/family';
  static const invite = '/family/invite';
  static const inviteSend = '/family/invite/send';
  static const inviteSent = '/family/invite/sent';

  /// 28 Tăng trưởng and 21 Chi tiết bản ghi (`/care/record/{id}`).
  static const growth = '/care/growth';
  static const record = '/care/record';

  /// 25 / 23b / 23c (`/care/timer/{sleep|breast|pump}`), 26, 27 (`/care/overlap/{id}`).
  static const timer = '/care/timer';
  static const manualSleep = '/care/sleep';
  static const overlap = '/care/overlap';

  /// 15 Nhập mã mời → 16 → 16a; 17 for closed invites.
  static const join = '/join';
  static const joinScan = '/join/scan';
  static const joinInvite = '/join/invite';
  static const joinConfirm = '/join/confirm';
  static const joinClosed = '/join/closed';

  /// Invite link opened from a QR, email or message (App Links): `/i/{token}`.
  static const inviteLink = '/i';

  /// 16d "Dùng email" for a temporary identity.
  static const saveAccountEmail = '/account/save-email';

  /// 9d Mất quyền truy cập.
  static const lostAccess = '/lost-access';
  static const appearance = '/appearance';

  /// S11 tab "Tôi" (13a–13n) and its pages, inside the shell so the dock stays.
  /// R1 "Chào mừng trở lại" (368:1266): a signed-out device that has signed in before.
  static const welcomeBack = '/welcome-back';
  static const me = '/me';
  static const meStorage = '/me/storage';
  static const meVideos = '/me/storage/videos';
  static const meBabies = '/me/babies';
  static const meProfile = '/me/profile';
  static const meAccount = '/me/account';
  static const meNotifications = '/me/notifications';
  static const meHelp = '/me/help';
  static const meShared = '/me/shared';

  /// S12 stories: reader `/story/{id}`, editor `/story/{id}/edit` (full screen).
  static const story = '/story';

  /// 13k "Sửa hồ sơ bé": full screen, no dock.
  static const babyEdit = '/baby-edit';

  /// A baby's profile above the tabs, from the header chip.
  static const baby = '/baby';
  static const showcase = '/showcase';
  static const diagnostics = '/diagnostics';
}

enum GuardState {
  loading,
  signedOut,
  needsVerifyPrompt,
  needsSetup,

  /// A temporary ("Vào ngay") identity that has not joined a baby yet (16b → 16a).
  joining,
  ready,
}

bool _under(String location, String prefix) =>
    location == prefix ||
    location.startsWith('$prefix/') ||
    location.startsWith('$prefix?');

/// Returns the location to redirect to, or null to stay.
///
/// [lostAccess]: a baby this device showed is no longer accessible (R-025) → 9d first.
/// [addingBaby]: "Thêm hồ sơ bé" from the baby switcher reopens setup for a ready account.
/// [returning]: this device has signed in before → R1 instead of 01 and the tour (368:837).
String? guardRoute({
  required GuardState state,
  required String location,
  required bool splashDone,
  bool lostAccess = false,
  bool addingBaby = false,
  bool returning = false,
}) {
  final onSplash = location == Routes.splash;
  if (state == GuardState.loading) return null;
  if (onSplash && !splashDone) return null;

  // Dev tools stay reachable in every state; the screens themselves are dev-gated.
  final tools =
      _under(location, Routes.showcase) || _under(location, Routes.diagnostics);
  if (tools) return null;

  // Invite redemption works signed out, mid-setup, as a temporary identity and for families
  // that already have a baby (a second invite).
  final joining =
      _under(location, Routes.join) || _under(location, Routes.inviteLink);

  if (lostAccess && state != GuardState.signedOut) {
    return location == Routes.lostAccess ? null : Routes.lostAccess;
  }
  if (location == Routes.lostAccess) return Routes.splash;

  final onboarding =
      _under(location, Routes.welcome) || _under(location, Routes.tour);
  final public =
      onboarding ||
      _under(location, Routes.welcomeBack) ||
      _under(location, Routes.signIn);

  switch (state) {
    case GuardState.loading:
      return null;
    case GuardState.signedOut:
      if (joining) return null;
      if (returning) {
        return public && !onboarding ? null : Routes.welcomeBack;
      }
      return public ? null : Routes.welcome;
    case GuardState.needsVerifyPrompt:
      // Right after creating an email account (08 "Kiểm tra email").
      return location == Routes.verify ? null : Routes.verify;
    case GuardState.needsSetup:
      final allowed =
          _under(location, '/setup') ||
          _under(location, Routes.appearance) ||
          location == Routes.exists ||
          joining;
      return allowed ? null : Routes.who;
    case GuardState.joining:
      return joining ? null : Routes.join;
    case GuardState.ready:
      if (joining || _under(location, Routes.saveAccountEmail)) return null;
      if (addingBaby && _under(location, '/setup')) return null;
      final starting = onSplash || public || _under(location, '/setup');
      return starting ? Routes.today : null;
  }
}
