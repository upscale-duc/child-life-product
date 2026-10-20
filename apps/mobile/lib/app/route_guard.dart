/// Where a location may be shown for a given session; pure so it is unit-tested.
library;

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const tour = '/tour';
  static const signIn = '/auth';
  static const email = '/auth/email';

  /// 07b "Kiểm tra email của bạn" after "Gửi link đăng nhập" (D-064).
  static const emailLinkSent = '/auth/email/sent';

  /// The email sign-in link itself (`https://dev.childlife.app/auth/link/?mode=signIn…`, D-064).
  static const emailLink = '/auth/link';
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

  /// Sổ tiêm chủng (VX 0 – VX 9a): the book, setup, a milestone, a dose, a vaccine.
  static const vaccines = '/care/vaccines';
  static const vaccineSetup = '/care/vaccines/setup';
  static const vaccineAge = '/care/vaccines/age';
  static const vaccineDose = '/care/vaccines/dose';
  static const vaccineInfo = '/care/vaccines/info';

  /// Chi tiêu (v1.1 8a–8o): the month, history, an expense, budget, recurring, statistics.
  /// Sơ cứu trẻ em (v1.1 7a–7i, TH01–TH24): the index, search, saved, a situation
  /// (`/care/first-aid/s/<id>?v=<variant>`).
  static const firstAid = '/utilities/first-aid';
  static const firstAidSearch = '/utilities/first-aid/search';
  static const firstAidSaved = '/utilities/first-aid/saved';
  static const firstAidSituation = '/utilities/first-aid/s';

  /// Mốc phát triển (v1.1 3a–3g, D-076 #6): the list, a milestone (`/<referenceId>` or a custom
  /// record's `/ms_…`) and "Tạo mốc riêng".
  static const milestones = '/utilities/milestones';
  static const milestoneOwn = '/utilities/milestones/own';

  static const spending = '/utilities/spending';
  static const spendingHistory = '/utilities/spending/history';
  static const spendingExpense = '/utilities/spending/expense';
  static const spendingBudget = '/utilities/spending/budget';
  static const spendingRecurring = '/utilities/spending/recurring';
  static const spendingStats = '/utilities/spending/stats';
  static const spendingCategories = '/utilities/spending/categories';

  /// Nhập chi tiêu (D-060): sources, `/{id}/review`, `/{id}` (the result).
  static const spendingImport = '/utilities/spending/import';
  static const messages = '/messages';
  static const memories = '/memories';

  /// Tự lưu kỷ niệm (D-066): home (or the AS02 intro until set up), `/setup` (AS03 – AS05),
  /// `/review` (AS07) and `/review/confirm` (AS10), `/settings` (AS19), `/samples/{babyId}`.
  static const autoSave = '/memories/auto-save';
  static const autoSaveSetup = '/memories/auto-save/setup';
  static const autoSaveReview = '/memories/auto-save/review';
  static const autoSaveConfirm = '/memories/auto-save/review/confirm';
  static const autoSaveSettings = '/memories/auto-save/settings';
  static const autoSaveSamples = '/memories/auto-save/samples';

  /// Thiệp cột mốc (D-068): MM10 (`?occasion=m1`), `/edit` (MM11) and `/done` (MM12) with the
  /// draft or result as `extra`.
  static const milestoneCard = '/memories/card';
  static const milestoneCardEdit = '/memories/card/edit';

  /// A template before it is used (owner, 2026-10-14).
  static const milestoneCardPreview = '/memories/card/preview';
  static const milestoneCardDone = '/memories/card/done';

  /// Video kỷ niệm (D-068): templates (`?occasion=m1`), `/photos` (MM06) and `/finish` (MM07)
  /// with the draft as `extra`, `/job/{jobId}?baby=…` (MM08 / MM09 / MM14).
  static const memoryStory = '/memories/video';
  static const memoryStoryPhotos = '/memories/video/photos';
  static const memoryStoryFinish = '/memories/video/finish';
  static const memoryStoryJob = '/memories/video/job';

  /// Nhịp lớn lên (Slice 2, plan §7.1), full screen above the tabs: the overview (`/rhythm`,
  /// NL01 / NL01b), check-in C01 → `/more?o=` C02 → `/health` NL05b, the result (PS01 /
  /// PS01F, check-in as `extra`), HL01 (`?signs=`), an activity `/{id}` (AC01, `?ci=`) and
  /// `/{id}/feedback` (AC02), an age card `/{id}`, "Lưu vào Mốc" (MS01, the note as `extra`),
  /// the setup NL02a–c (`/setup`), the due date alone (NL02b, `?estimate=1`), the reminders
  /// alone (NL02c), the reference calendar NL03 and a stage `/calendar/{id}` (NL04), and the
  /// person's preferences: "Cá nhân hoá" (`/personalize`), EN01, EN02 and the feedback history.
  static const rhythm = '/rhythm';
  static const rhythmSetup = '/rhythm/setup';
  static const rhythmDueDate = '/rhythm/due-date';
  static const rhythmReminders = '/rhythm/reminders';
  static const rhythmCalendar = '/rhythm/calendar';
  static const rhythmPersonalize = '/rhythm/personalize';
  static const personalDay = '/rhythm/day';
  static const rhythmInterests = '/rhythm/interests';
  static const rhythmDigest = '/rhythm/digest';
  static const rhythmFeedbackHistory = '/rhythm/feedback-history';

  /// "Các cách đã thử" (D-076 #10): the family's plans and answers, answerable later.
  static const rhythmTried = '/rhythm/tried';

  static const rhythmCheckIn = '/rhythm/checkin';
  static const rhythmCheckInMore = '/rhythm/checkin/more';
  static const rhythmCheckInHealth = '/rhythm/checkin/health';
  static const rhythmResult = '/rhythm/result';
  static const rhythmHealth = '/rhythm/health';
  static const rhythmActivity = '/rhythm/activity';
  static const rhythmAge = '/rhythm/age';
  static const rhythmMilestone = '/rhythm/milestone';

  /// EN09 "Tóm tắt tuần" (from NL01, Hôm nay and the Sunday notification).
  static const rhythmWeek = '/rhythm/week';

  /// Child Life Assistant (docs/assistant/architecture.md, slice A4): the chat
  /// (`?scope=child:<baby>|household:<baby>&conversation=<cv>`), CH03 history (`?scope=`) and
  /// CH19 usage (`?baby=`), full screen above the tabs.
  static const assistant = '/assistant';
  static const assistantHistory = '/assistant/history';
  static const assistantUsage = '/assistant/usage';

  /// Premium Slice 3 (plan §5.5): SU01 "Bàn giao cho người chăm tiếp" and the person's AI consent.
  static const rhythmHandover = '/rhythm/handover';
  static const rhythmAiConsent = '/rhythm/ai-consent';

  /// Tiện ích tab (v1.0 improvement 450:6597): Sơ cứu, Chi tiêu, Gia đình.
  static const utilities = '/utilities';
  static const family = '/utilities/family';
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

  /// EN06 Hộp thông báo (D-076 #2), from the Hôm nay bell; pushed, without the dock.
  static const notifications = '/notifications';

  /// PR03 · Gói của hộ and the household region (Premium & Cá nhân hoá, D-072).
  static const mePlan = '/me/plan';

  /// PR01 · Quyền lợi & paywall above the tabs (`?entry=rhythm|templates|plan`, resume record in
  /// the query: `&kind=card&template=…&draft=…`).
  static const premium = '/premium';
  static const meHelp = '/me/help';

  /// FB2 Góp ý and FB3 Đã gửi (D-065).
  static const meFeedback = '/me/feedback';
  static const meFeedbackSent = '/me/feedback/sent';
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

/// The in-app location of an opened link. Universal Links and App Links reach the router with
/// their host (`https://dev.childlife.app/i/…`); the guard works on the path and query.
String appLocation(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.hasQuery ? '$path?${uri.query}' : path;
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
