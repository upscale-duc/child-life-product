// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Child Life';

  @override
  String get configErrorTitle => 'Invalid environment configuration.';

  @override
  String get diagnosticsEnvironment => 'Environment';

  @override
  String get diagnosticsServer => 'Server connection';

  @override
  String diagnosticsConnected(String projectId, String region) {
    return 'Connected to $projectId ($region)';
  }

  @override
  String get diagnosticsChecking => 'Checking…';

  @override
  String diagnosticsUnreachable(String error) {
    return 'Couldn\'t connect: $error';
  }

  @override
  String get diagnosticsRetry => 'Check again';

  @override
  String get diagnosticsFlags => 'Feature configuration';

  @override
  String get diagnosticsFlagsEmpty => 'No configuration yet';

  @override
  String diagnosticsFlagsCount(int enabled, int total) {
    return '$enabled/$total on';
  }

  @override
  String get diagnosticsLoading => 'Loading…';

  @override
  String diagnosticsUnreadable(String error) {
    return 'Couldn\'t read: $error';
  }

  @override
  String get diagnosticsTestCrash => 'Send a test crash to Crashlytics';

  @override
  String get diagnosticsDevOnly => 'Dev builds only';

  @override
  String get a11yBack => 'Back';

  @override
  String get a11yClose => 'Close';

  @override
  String get a11yNext => 'Continue';

  @override
  String get a11yQuickLog => 'Quick log';

  @override
  String get a11yNightCareToggle => 'Night care';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMemories => 'Memories';

  @override
  String get tabFamily => 'Family';

  @override
  String get tabMe => 'Me';

  @override
  String get actionSkip => 'Skip';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get actionNext => 'Next';

  @override
  String get actionDone => 'Done';

  @override
  String get actionLater => 'Later';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionOpenSettings => 'Open Settings';

  @override
  String get splashTagline => 'Care together. Keep childhood.';

  @override
  String get welcomeTitle => 'Care for your baby together,\nkeep every moment';

  @override
  String get welcomeExplore => 'Explore';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeInviteCode => 'Invite code';

  @override
  String get welcomeChipMilestone => 'New milestone';

  @override
  String get a11yToggleAppearance => 'Switch light / dark';

  @override
  String get tourCareTitle => 'Log feeds, sleep, diapers\nwith one hand';

  @override
  String get tourCareBody => 'Saved in 3 taps at most.';

  @override
  String get tourCareChipBottle => 'Bottle · 120 ml';

  @override
  String get tourCareChipDiaper => 'Diaper · Wet';

  @override
  String get tourCareChipSleep => 'Sleep · 1 h 20';

  @override
  String get tourCareTaps => 'taps';

  @override
  String get tourShareTitle => 'Take over, no questions';

  @override
  String get tourShareBody =>
      'The latest log is synced to the whole family: who logged what, and when.';

  @override
  String get tourShareSynced => 'Synced';

  @override
  String get tourShareAsleep => 'Asleep';

  @override
  String get tourShareChipMom => 'Bottle · 80 ml · by Mum';

  @override
  String get tourShareChipDad => 'Diaper · Wet · by Dad';

  @override
  String get tourShareInitialMom => 'M';

  @override
  String get tourShareInitialDad => 'D';

  @override
  String get tourStoryTitle => 'Moments become\nstories';

  @override
  String get tourStoryBody =>
      'A photo becomes a memory card at once. Each week ends with your baby\'s journal.';

  @override
  String get tourStoryChipCard => 'Instant memory card';

  @override
  String get tourStoryChipJournal => 'Week 8 journal';

  @override
  String get tourPrivateTitle => 'The right people,\nthe right access';

  @override
  String get tourPrivateBody =>
      'Grandma sees photos, the nanny logs feeds. You decide who sees what.';

  @override
  String get tourPrivateChipAccess => 'You choose access';

  @override
  String get tourPrivateChipInvite => 'Invite family';

  @override
  String get tourPrivateInitials => 'M|D|G|N';

  @override
  String get tourCreateProfile => 'Create baby profile';

  @override
  String get signInTitle => 'Hello';

  @override
  String get signInSubtitle => 'Sign in to get started.';

  @override
  String get signInApple => 'Continue with Apple';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInEmail => 'Use email';

  @override
  String get signInLegal => 'Terms · Privacy';

  @override
  String get signInHeroLetters => 'B|é';

  @override
  String get emailTitle => 'Email';

  @override
  String get emailNewAccount => 'New account';

  @override
  String get emailSignInTab => 'Sign in';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailPlaceholder => 'name@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordPlaceholder => '8+ characters';

  @override
  String get emailCreateAccount => 'Create account';

  @override
  String get emailSignInButton => 'Sign in';

  @override
  String get emailUsedWithProvider => 'Email already used with Apple/Google?';

  @override
  String get emailForgot => 'Forgot password?';

  @override
  String get authErrorInvalidEmail =>
      'That email doesn\'t look right — please check it.';

  @override
  String get authErrorWeakPassword => 'Use at least 8 characters.';

  @override
  String get authErrorWrongCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrorNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get authErrorNotConfigured =>
      'This sign-in option isn\'t ready in this test build yet.';

  @override
  String get authErrorDisabled =>
      'This account is disabled. Contact Child Life for help.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorLinkFailed =>
      'Signed in, but the email couldn\'t be linked. Try again from Account.';

  @override
  String get verifyTitle => 'Check your email';

  @override
  String get verifyBody => 'We sent a verification link to';

  @override
  String get verifyOpenMail => 'Open Mail';

  @override
  String get verifyResend => 'Resend email';

  @override
  String verifyResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get verifyResent => 'Sent again. Check your spam folder too.';

  @override
  String get verifyDone => 'Email verified';

  @override
  String get verifyNoMailApp => 'Couldn\'t open a mail app on this phone.';

  @override
  String get verifyLaterHint =>
      'You can continue now. You\'ll need to verify before inviting family.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotBody => 'Enter your email and we\'ll send a reset link.';

  @override
  String get forgotSend => 'Send link';

  @override
  String get forgotSent =>
      'If this email has an account, a reset link is on its way.';

  @override
  String get existsTitle => 'This email already has an account';

  @override
  String get existsBody => 'Sign in with Apple or Google, then we\'ll link it.';

  @override
  String get existsProvider => 'Apple · Google';

  @override
  String get existsUseOtherEmail => 'Use another email';

  @override
  String get existsLinked => 'Your email is now linked to your account.';

  @override
  String get whoTitle => 'Who are you to the baby?';

  @override
  String whoSubtitle(String label) {
    return 'The family will see “by $label” on every log.';
  }

  @override
  String get whoNameLabel => 'Your name';

  @override
  String get whoNamePlaceholder => 'e.g. Mai';

  @override
  String get whoYouAre => 'You are';

  @override
  String get whoCustomLabel => 'Your relation';

  @override
  String get whoCustomPlaceholder => 'e.g. Aunt';

  @override
  String get relationMother => 'Mum';

  @override
  String get relationFather => 'Dad';

  @override
  String get relationGrandmother => 'Grandma';

  @override
  String get relationGrandfather => 'Grandpa';

  @override
  String get relationNanny => 'Nanny';

  @override
  String get relationRelative => 'Relative';

  @override
  String get relationOther => 'Other…';

  @override
  String get babyNicknameLabel => 'Nickname';

  @override
  String get babyNicknamePlaceholder => 'Baby\'s name';

  @override
  String get babyDob => 'Date of birth';

  @override
  String get babyTimeZone => 'Time zone';

  @override
  String get babyGender => 'Gender';

  @override
  String get babyOptional => 'optional';

  @override
  String get genderGirl => 'Girl';

  @override
  String get genderBoy => 'Boy';

  @override
  String get genderUnspecified => 'Not specified';

  @override
  String get babyPrivacyNote => 'Relatives only see the nickname';

  @override
  String get a11yChangeBabyPhoto => 'Change profile photo';

  @override
  String get babyNicknameRequired => 'Give your baby a nickname.';

  @override
  String dobAgeHint(String name, String age) {
    return '$name is $age';
  }

  @override
  String get ageNewborn => 'a newborn';

  @override
  String ageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days old',
      one: '1 day old',
    );
    return '$_temp0';
  }

  @override
  String ageWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks old',
      one: '1 week old',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months old',
      one: '1 month old',
    );
    return '$_temp0';
  }

  @override
  String ageYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years old',
      one: '1 year old',
    );
    return '$_temp0';
  }

  @override
  String ageShortDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String ageShortWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String ageShortMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String ageShortYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get tzSearch => 'Search city or country';

  @override
  String get tzAuto => 'Use this phone\'s time zone';

  @override
  String tzAutoUsing(String offset, String place) {
    return 'Using $offset · $place';
  }

  @override
  String get tzNoResults => 'No matching time zone.';

  @override
  String get avatarTitle => 'Profile photo';

  @override
  String get avatarCamera => 'Take photo';

  @override
  String get avatarLibrary => 'Choose from library';

  @override
  String get avatarOrIllustration => 'Or choose an illustration';

  @override
  String get avatarPrivacy => 'Only your family can see this photo.';

  @override
  String avatarPreset(int number) {
    return 'Illustration $number';
  }

  @override
  String get avatarCameraDenied =>
      'Child Life can\'t use the camera. You can allow it in Settings.';

  @override
  String get avatarLibraryDenied =>
      'Child Life can\'t access photos. You can allow it in Settings.';

  @override
  String get avatarUploadFailed =>
      'The photo wasn\'t saved. The profile keeps the illustration — try again later.';

  @override
  String get trackersTitle => 'What to track?';

  @override
  String get trackersSubtitle => 'You can change this anytime.';

  @override
  String get trackerBottle => 'Bottle';

  @override
  String get trackerBreast => 'Breastfeeding';

  @override
  String get trackerSleep => 'Sleep';

  @override
  String get trackerDiaper => 'Diaper';

  @override
  String get trackerPump => 'Pumping';

  @override
  String get trackerGrowth => 'Growth';

  @override
  String trackersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count items',
      one: 'Done · 1 item',
    );
    return '$_temp0';
  }

  @override
  String get trackersPickOne => 'Pick at least one';

  @override
  String get createBabyLimit =>
      'Each account can create up to 3 baby profiles.';

  @override
  String get createBabyFailed =>
      'The profile wasn\'t created. Check your connection and try again.';

  @override
  String get createBabyDobFuture =>
      'The date of birth can\'t be in the future.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Automatic';

  @override
  String get nightCareTitle => 'Night care';

  @override
  String nightCareScheduled(String start, String end) {
    return 'Scheduled $start – $end';
  }

  @override
  String get nightCareOff => 'Schedule off';

  @override
  String get nightCareSchedule => 'Night care schedule';

  @override
  String get nightCareOn => 'Turns on';

  @override
  String get nightCareOffAt => 'Turns off';

  @override
  String get nightCareHint =>
      'Outside the schedule, Night care still turns on when you start a sleep timer.';

  @override
  String get appearanceAppliesNow => 'Applies to the whole app right away';

  @override
  String nightCareSegmentOn(String time) {
    return 'On · $time';
  }

  @override
  String nightCareSegmentOff(String time) {
    return 'Off · $time';
  }

  @override
  String get pickerHour => 'Hour';

  @override
  String get pickerMinute => 'Minute';

  @override
  String nightCareDuration(String duration, String end) {
    return 'Night care for $duration, until $end';
  }

  @override
  String durationHours(int n) {
    return '$n h';
  }

  @override
  String durationHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get todayTitle => 'Today';

  @override
  String get todayTileEmpty => 'None yet';

  @override
  String get todayTileTapToLog => 'Tap to log';

  @override
  String get todaySummaryEmpty => 'Nothing logged today yet.';

  @override
  String get todaySummaryEmptyBody =>
      'Log whenever the family needs to. Today\'s totals will appear here.';

  @override
  String get todayLoggingSoon => 'Care logging arrives in the next build.';

  @override
  String babySwitcherLabel(String name, String age) {
    return '$name · $age';
  }

  @override
  String get meAppearance => 'Appearance';

  @override
  String get meSignOut => 'Sign out';

  @override
  String get ageShortNewborn => 'newborn';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get familyErrorGeneric => 'That didn\'t work. Please try again.';

  @override
  String get relationFriend => 'Friend';

  @override
  String get roleCoParent => 'Co-parent';

  @override
  String get roleCaregiver => 'Caregiver';

  @override
  String get roleRelative => 'Family member';

  @override
  String memberDetail(String relation, String role) {
    return '$relation · $role';
  }

  @override
  String get babyPickerTitle => 'Choose baby';

  @override
  String babyPickerYouAre(String label) {
    return 'You\'re $label';
  }

  @override
  String babyPickerRowDetail(String age, String youAre) {
    return '$age · $youAre';
  }

  @override
  String get babyPickerAdd => 'Add baby profile';

  @override
  String babyPickerCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String babyPickerLimit(int max) {
    return 'You can create up to $max baby profiles.';
  }

  @override
  String babySwitched(String name) {
    return 'Switched to $name';
  }

  @override
  String get memoriesComingSoon => 'Memories arrive in a later build.';

  @override
  String get todayViewOnly => 'You can view daily care, not log it.';

  @override
  String get unsavedBannerTitle => 'Account not saved';

  @override
  String get unsavedBannerAction => 'Save';

  @override
  String get saveAccountTitle => 'Save your account';

  @override
  String saveAccountBody(String baby) {
    return 'So you don\'t lose $baby when you change phones or reinstall the app.';
  }

  @override
  String get saveAccountDone => 'Account saved';

  @override
  String get saveAccountMerged => 'Merged into your account';

  @override
  String get saveEmailSubtitle =>
      'Create a new account, or sign in to an existing one to merge into it.';

  @override
  String get saveEmailExists =>
      'This email already has an account. Sign in to merge into it.';

  @override
  String get signOutAnonTitle => 'Sign out without saving?';

  @override
  String get signOutAnonBody =>
      'Your temporary account will be lost, and you\'ll need a new invite to come back.';

  @override
  String get signOutAnonConfirm => 'Sign out anyway';

  @override
  String familySubtitle(String baby) {
    return 'People caring for $baby';
  }

  @override
  String get familyYou => 'You';

  @override
  String familyPending(int count) {
    return 'Waiting to accept ($count)';
  }

  @override
  String familyPendingDetail(String relation, String date) {
    return '$relation · expires $date';
  }

  @override
  String familyPendingExpired(String relation) {
    return '$relation · expired';
  }

  @override
  String familyPendingNoEmail(String relation) {
    return 'Invite for $relation';
  }

  @override
  String get familyResend => 'Resend';

  @override
  String familyResent(String email) {
    return 'Sent again to $email';
  }

  @override
  String get familyInvite => 'Invite someone to help';

  @override
  String get familyFootnote =>
      'People you invite only see what you allow. You can change their access or remove them at any time.';

  @override
  String get familyLoadFailed =>
      'Couldn\'t load the list. Check your connection.';

  @override
  String get inviteSubtitle => 'Choose who they are and what they can do.';

  @override
  String get inviteRelationLabel => 'They are your baby\'s';

  @override
  String get inviteRoleLabel => 'Access';

  @override
  String get inviteCustomLabel => 'Relation to the baby';

  @override
  String get roleCoParentHint => 'Full access, like a parent';

  @override
  String get roleCaregiverHint => 'Log & view care';

  @override
  String get roleRelativeHint => 'View memories, choose extra views';

  @override
  String get roleCoParentOwnerOnly =>
      'Only the profile creator can add co-parents';

  @override
  String get inviteSeeDetails => 'See access details';

  @override
  String get inviteNext => 'Next · Send invite';

  @override
  String get relativeRightsTitle => 'A family member\'s access';

  @override
  String get relativeRightsAlways => 'Always: view memories, send love';

  @override
  String get relativeRightsMore => 'Also allow';

  @override
  String get rightBabyInfo => 'Baby info';

  @override
  String get rightBabyInfoHint => 'Birthday, weight';

  @override
  String get rightDailyCare => 'Daily care';

  @override
  String get rightDailyCareHint => 'Feeds, sleep, diapers · view only';

  @override
  String roleDetailsTitle(String role) {
    return '$role access';
  }

  @override
  String get permLogCare => 'Log feeds, sleep, diapers';

  @override
  String get permViewSchedule => 'View the schedule';

  @override
  String get permViewReminders => 'View reminders';

  @override
  String get permMemories => 'Memories';

  @override
  String get permViewMemories => 'View memories';

  @override
  String get permLove => 'Send love';

  @override
  String get permInvite => 'Invite others';

  @override
  String get permAddMemories => 'Add memories';

  @override
  String get permDailyCare => 'View feeds, sleep, diapers';

  @override
  String inviteSendTitle(String relation) {
    return 'Send the invite to $relation';
  }

  @override
  String inviteSendSubtitle(String relation) {
    return '$relation opens their phone camera and scans the code.';
  }

  @override
  String inviteSendLinkSubtitle(String relation) {
    return 'Send this link to $relation in a message.';
  }

  @override
  String inviteSendEmailSubtitle(String relation) {
    return 'Child Life emails the invite to $relation.';
  }

  @override
  String get inviteSummaryChange => 'Change';

  @override
  String get inviteChannelQr => 'QR code';

  @override
  String get inviteChannelLink => 'Link';

  @override
  String get inviteChannelEmail => 'Email';

  @override
  String get inviteOrCode => 'Or enter the code';

  @override
  String inviteExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $days days',
      one: 'Expires in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get inviteExpiresToday => 'Expires today';

  @override
  String get inviteShare => 'Share invite';

  @override
  String inviteShareText(
    String inviter,
    String baby,
    String link,
    String code,
  ) {
    return '$inviter invited you to care for $baby on Child Life.\nOpen: $link\nOr enter this code in the app: $code';
  }

  @override
  String inviteShareSubject(String baby) {
    return 'Invite to care for $baby';
  }

  @override
  String inviteCantScan(String relation) {
    return '$relation can\'t scan?';
  }

  @override
  String get inviteCopyLink => 'Copy link';

  @override
  String get inviteLinkCopied => 'Link copied';

  @override
  String inviteEmailLabel(String relation) {
    return '$relation\'s email';
  }

  @override
  String get inviteEmailSend => 'Send email';

  @override
  String cantScanTitle(String relation) {
    return '$relation can\'t get in?';
  }

  @override
  String get cantScanStep1 =>
      'Open the Child Life app and choose “Invite code”';

  @override
  String cantScanStep2(String code) {
    return 'Enter the code $code';
  }

  @override
  String get cantScanStep3 => 'Still stuck? Create a new code below';

  @override
  String get cantScanNewCode => 'Create new code';

  @override
  String get cantScanByEmail => 'Send by email instead';

  @override
  String get inviteNewCodeDone =>
      'New code created. The old one no longer works.';

  @override
  String get inviteRevoke => 'Cancel invite';

  @override
  String get inviteRevoked => 'Invite cancelled';

  @override
  String inviteSentTitle(String relation) {
    return 'Email sent to $relation';
  }

  @override
  String inviteNotReceived(String relation) {
    return '$relation didn\'t get it?';
  }

  @override
  String get notReceivedTitle => 'No email yet?';

  @override
  String get notReceivedTip1 => 'Check the Spam or Promotions folder.';

  @override
  String get notReceivedTip2 => 'Email can take a few minutes.';

  @override
  String get notReceivedTip3 => 'Or share the link in a message.';

  @override
  String get notReceivedResend => 'Send again';

  @override
  String get inviteErrorUnverified =>
      'Verify your email before inviting others.';

  @override
  String get inviteErrorOwnerOnly =>
      'Only the profile creator can manage co-parents.';

  @override
  String get inviteErrorTooSoon =>
      'Just sent. Wait a minute before sending again.';

  @override
  String get inviteErrorTooMany =>
      'This invite has been emailed 5 times. Share the link instead.';

  @override
  String get inviteErrorSuppressed =>
      'This address has unsubscribed from Child Life emails.';

  @override
  String get inviteErrorClosed => 'This invite can no longer be used.';

  @override
  String memberMeta(String relation, String date) {
    return '$relation · joined $date';
  }

  @override
  String get roleCoParentHintFull => 'Full access, like a parent';

  @override
  String get roleCaregiverHintFull => 'Log & view care, can\'t invite';

  @override
  String get roleRelativeHintFull => 'Only sees shared memories';

  @override
  String get memberAccessUntil => 'Access until';

  @override
  String memberAccessUntilValue(String date) {
    return 'Until $date';
  }

  @override
  String get memberAccessNoLimit => 'No limit';

  @override
  String memberAccessHint(String name) {
    return '$name has access until the end of this day.';
  }

  @override
  String get memberAccessClear => 'Remove limit';

  @override
  String get memberRelation => 'Relation to baby';

  @override
  String memberRemove(String name) {
    return 'Remove $name from the family';
  }

  @override
  String memberRecordsKept(String name) {
    return '$name\'s logs are kept.';
  }

  @override
  String memberRemoveConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String memberRemoveConfirmBody(String name, String baby) {
    return '$name will no longer see $baby. Their logs are kept.';
  }

  @override
  String get memberRemoveConfirm => 'Remove';

  @override
  String memberRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String get memberUpdated => 'Updated';

  @override
  String get joinCodeTitle => 'Enter invite code';

  @override
  String get joinCodeSubtitle =>
      'The 6 digits in the invite, or scan the QR code.';

  @override
  String get joinScan => 'Scan QR code';

  @override
  String get joinCodeWrong => 'That code doesn\'t match. Check the 6 digits.';

  @override
  String joinLocked(int minutes) {
    return 'Too many tries. Try again in $minutes min.';
  }

  @override
  String get a11yInviteCode => '6-digit invite code';

  @override
  String get scanHint => 'Fit the invite QR code in the frame.';

  @override
  String get scanNotInvite => 'This isn\'t a Child Life invite.';

  @override
  String get scanCameraDenied => 'Allow camera access in Settings to scan.';

  @override
  String joinCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours left',
      one: '1 hour left',
    );
    return '$_temp0';
  }

  @override
  String joinInviterTitle(String inviter) {
    return '$inviter invited you';
  }

  @override
  String joinRoleLine(String baby) {
    return 'to care for $baby as';
  }

  @override
  String get joinJoin => 'Join';

  @override
  String get joinNotMe => 'Not me';

  @override
  String joinAlreadyMember(String baby) {
    return 'You\'re already in $baby\'s family.';
  }

  @override
  String joinHowTitle(String baby) {
    return 'Join $baby\'s family';
  }

  @override
  String get joinHowBody => 'No account needed. You can save it later.';

  @override
  String get joinNow => 'Join now';

  @override
  String get joinOrSave => 'or save an account now';

  @override
  String joinConfirmTitle(String baby) {
    return 'Who are you to $baby?';
  }

  @override
  String joinConfirmSubtitle(String inviter, String relation) {
    return '$inviter chose “$relation”. Change it if it isn\'t right.';
  }

  @override
  String joinConfirmGo(String baby) {
    return 'See $baby';
  }

  @override
  String get joinExpiredTitle => 'This invite has expired';

  @override
  String get joinExpiredBody =>
      'Ask the person who invited you to send a new link.';

  @override
  String get joinRevokedTitle => 'This invite was cancelled';

  @override
  String get joinRevokedBody => 'Ask the person who invited you for a new one.';

  @override
  String get joinUsedTitle => 'This invite has been used';

  @override
  String get joinUsedBody =>
      'Each invite works once. Ask the person who invited you for a new one.';

  @override
  String get joinNotFoundTitle => 'We couldn\'t find this invite';

  @override
  String get joinNotFoundBody => 'Check the link, or enter the 6-digit code.';

  @override
  String get joinOtherCode => 'Enter another code';

  @override
  String get joinBackToStart => 'Back to start';

  @override
  String get lostAccessTitle => 'You no longer have access to this profile';

  @override
  String get lostAccessBody =>
      'Your access has changed. Content on this device has been hidden.';

  @override
  String get lostAccessHome => 'Go to home';

  @override
  String get lostAccessRequest => 'Ask for a new invite';

  @override
  String get lostAccessShareText =>
      'I can\'t see our baby\'s profile on Child Life anymore. Could you send me a new invite?';

  @override
  String get agoJustNow => 'Just now';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoHoursMinutes(int h, int m) {
    return '$h h $m min ago';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String endedAgo(String ago) {
    return 'Ended $ago';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String rhythmSleepValue(int h, int m) {
    return '$h h $m';
  }

  @override
  String get careYou => 'you';

  @override
  String careYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String careLoggedBy(String who) {
    return 'by $who';
  }

  @override
  String amountMl(int n) {
    return '$n ml';
  }

  @override
  String weightKg(String v) {
    return '$v kg';
  }

  @override
  String lengthCm(String v) {
    return '$v cm';
  }

  @override
  String get milkBreast => 'Breast milk';

  @override
  String get milkFormula => 'Formula';

  @override
  String get sideLeft => 'Left';

  @override
  String get sideRight => 'Right';

  @override
  String get sideBoth => 'Both';

  @override
  String get diaperWet => 'Wet';

  @override
  String get diaperDirty => 'Dirty';

  @override
  String get diaperWetValue => 'Wet';

  @override
  String get diaperDirtyValue => 'Dirty';

  @override
  String get diaperBothValue => 'Wet and dirty';

  @override
  String get carePending => 'Waiting to sync';

  @override
  String get dayRhythmTitle => 'Logged today';

  @override
  String rhythmFeeds(int count, int ml) {
    return '$count feeds · $ml ml';
  }

  @override
  String rhythmBreast(int count, int minutes) {
    return '$count feeds · $minutes min';
  }

  @override
  String get rhythmSleepLabel => 'Sleep (finished)';

  @override
  String rhythmDiapers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String get legendSleep => 'Sleep';

  @override
  String get legendDiaper => 'Diaper';

  @override
  String get todayHistory => 'History';

  @override
  String get historySoon => 'Detailed history arrives in a later build.';

  @override
  String get sleepSoon => 'Sleep logging and timers arrive in a later build.';

  @override
  String awakeFor(String duration) {
    return 'Awake $duration';
  }

  @override
  String growthDeltaToday(String delta, String when) {
    return '$delta · $when';
  }

  @override
  String get dayToday => 'today';

  @override
  String get dayYesterday => 'yesterday';

  @override
  String offlineBanner(int count) {
    return 'Offline · $count waiting to sync';
  }

  @override
  String syncingBanner(int count) {
    return '$count waiting to sync';
  }

  @override
  String get pendingTitle => 'Waiting to sync';

  @override
  String get pendingChip => 'Waiting';

  @override
  String get pendingOnlyHere => 'Saved only on this device';

  @override
  String get pendingFootnote =>
      'Sends automatically when online. Others caring for the baby can’t see these yet.';

  @override
  String get retryNow => 'Retry now';

  @override
  String get retrySynced => 'Synced';

  @override
  String get retryStill =>
      'Not sent yet. The app sends them when you’re online.';

  @override
  String get syncPendingLong => 'Saved on this device. Waiting to sync.';

  @override
  String get quickLogTitle => 'Quick log';

  @override
  String get quickSleep => 'Sleep';

  @override
  String get feedSheetTitle => 'Log a feed';

  @override
  String get amountOptional => 'Amount · optional';

  @override
  String get amountLabel => 'Amount';

  @override
  String get milkTypeLabel => 'Milk';

  @override
  String get timeLabel => 'Time';

  @override
  String get startLabel => 'Start';

  @override
  String get sideLabel => 'Side';

  @override
  String get durationOptional => 'Duration · optional';

  @override
  String get durationLabel => 'Duration';

  @override
  String get durationNone => 'Not set';

  @override
  String get saveFeed => 'Save feed';

  @override
  String get pumpTitle => 'Log pumping';

  @override
  String get savePump => 'Save pumping';

  @override
  String get diaperTitle => 'Diaper change';

  @override
  String get actionSave => 'Save';

  @override
  String timeNow(String time) {
    return 'Now · $time';
  }

  @override
  String timeToday(String time) {
    return 'Today · $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Yesterday · $time';
  }

  @override
  String get timePickerTitle => 'Pick a time';

  @override
  String get durationPickerTitle => 'Pick a duration';

  @override
  String savedToast(String what) {
    return 'Logged · $what';
  }

  @override
  String get editedToast => 'Changes saved';

  @override
  String get undo => 'Undo';

  @override
  String amountRange(String min, String max, String unit) {
    return 'Enter $min to $max $unit.';
  }

  @override
  String get careSaveFailed =>
      'The record could not be saved. Your access may have changed.';

  @override
  String get growthTitle => 'Growth';

  @override
  String get growthDate => 'Measured on';

  @override
  String get growthWeight => 'Weight';

  @override
  String get growthLengthOptional => 'Length · optional';

  @override
  String growthDeltaSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String get growthPrevious => 'Previous measurements';

  @override
  String get growthSeeAll => 'See all';

  @override
  String get growthNoPrevious => 'This is the first measurement.';

  @override
  String get growthAtBirth => 'At birth';

  @override
  String get saveGrowth => 'Save measurement';

  @override
  String get growthWeightRequired => 'Enter a weight from 0.3 to 40 kg.';

  @override
  String get growthLengthRange => 'Length from 20 to 150 cm.';

  @override
  String get detailTime => 'Time';

  @override
  String get detailBy => 'Logged by';

  @override
  String get detailLoggedAt => 'Logged at';

  @override
  String get detailSync => 'Sync';

  @override
  String get detailAmount => 'Amount';

  @override
  String get detailMilk => 'Milk';

  @override
  String get detailSide => 'Side';

  @override
  String get detailDuration => 'Duration';

  @override
  String get detailLength => 'Length';

  @override
  String get actionEdit => 'Edit';

  @override
  String get deleteRecord => 'Delete record';

  @override
  String get detailFooter =>
      'Everyone in the family sees this record. The person who logged it and co-parents can edit it.';

  @override
  String get deleteConfirmTitle => 'Delete this record?';

  @override
  String get deleteConfirmBody => 'It stays in “Recently deleted” for 30 days.';

  @override
  String get deletedToast => 'Deleted';

  @override
  String viewOnlyNote(String who) {
    return '$who’s record · view only. If it’s wrong, message $who to fix it.';
  }

  @override
  String messageAuthor(String who) {
    return 'Message $who';
  }

  @override
  String get messagesSoon => 'In-app messages arrive in a later build.';

  @override
  String get recordGone => 'This record is no longer available.';

  @override
  String get unitMinutes => 'min';

  @override
  String memberMetaCount(String relation, String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return '$relation · joined $date · $_temp0';
  }

  @override
  String get sleepChooserTitle => 'Log sleep';

  @override
  String sleepChooserPrompt(String baby) {
    return 'Is $baby asleep now, or already awake?';
  }

  @override
  String get sleepStartTimer => 'Start timer';

  @override
  String sleepStartTimerHint(String baby) {
    return '$baby just fell asleep. The timer runs and the family sees it';
  }

  @override
  String get sleepManual => 'Enter a past sleep';

  @override
  String get sleepManualHint =>
      'Forgot the timer? Pick when it started and ended';

  @override
  String get sleepChooserFootnote =>
      'Switch any time: the timer lets you fix the start, manual entry can switch to the timer.';

  @override
  String get timerFamilySees => 'The family can see this';

  @override
  String get timerOnlyHere => 'Only on this device';

  @override
  String get sleepNotSynced => 'This sleep hasn’t synced yet';

  @override
  String get timerNotSynced => 'This hasn’t synced yet';

  @override
  String sleepTimerTitle(String baby) {
    return '$baby is sleeping';
  }

  @override
  String timerStartedBy(String who, String time) {
    return '$who started at $time';
  }

  @override
  String get sleepRingLabel => 'Asleep';

  @override
  String sinceTime(String time) {
    return 'Since $time';
  }

  @override
  String get endSleep => 'End sleep';

  @override
  String get editStart => 'Edit start time';

  @override
  String get cancelNoSave => 'Cancel, don’t save';

  @override
  String get cancelConfirmTitle => 'Cancel without saving?';

  @override
  String get cancelConfirmBody => 'The time so far won’t be logged.';

  @override
  String get keepTiming => 'Keep timing';

  @override
  String breastTimerTitle(String baby) {
    return '$baby is breastfeeding';
  }

  @override
  String get totalTime => 'Total time';

  @override
  String get sideLeftCaps => 'LEFT';

  @override
  String get sideRightCaps => 'RIGHT';

  @override
  String get feedingNow => 'Feeding';

  @override
  String get tapToSwitch => 'Tap to switch';

  @override
  String get lastEndedLeft => 'Last feed ended on the left';

  @override
  String get lastEndedRight => 'Last feed ended on the right';

  @override
  String get endFeed => 'End feed';

  @override
  String get pauseTimer => 'Pause';

  @override
  String get resumeTimer => 'Resume';

  @override
  String get pausedLabel => 'Paused';

  @override
  String pumpTimerTitle(String who) {
    return '$who is pumping';
  }

  @override
  String pumpStartedFor(String time, String baby) {
    return 'Started at $time · for $baby';
  }

  @override
  String get pumpingNow => 'Pumping';

  @override
  String get pumpStopped => 'Stopped';

  @override
  String get tapToStart => 'Tap to start';

  @override
  String get doublePumpHint => 'Double pumping · tap a side to stop it';

  @override
  String get pumpDone => 'Done · enter amount';

  @override
  String get timerInstead => 'Time it instead';

  @override
  String timerJoined(String who) {
    return '$who already started this timer. You’re following it.';
  }

  @override
  String wokeAt(String time) {
    return 'Woke at $time';
  }

  @override
  String runningSince(String time, String who) {
    return 'Since $time · $who';
  }

  @override
  String get manualSleepTitle => 'Enter sleep';

  @override
  String get overnight => 'Overnight';

  @override
  String get sleepEnd => 'End';

  @override
  String overnightNote(String offset) {
    return 'An overnight sleep counts toward each day in the baby’s time zone ($offset).';
  }

  @override
  String sleepingNow(String baby) {
    return 'Is $baby asleep now?';
  }

  @override
  String get saveSleep => 'Save sleep';

  @override
  String get sleepEndBeforeStart => 'The end must be after the start.';

  @override
  String get sleepTooLong => 'A sleep can last 24 hours at most.';

  @override
  String get overlapTitle => 'Two sleeps overlap';

  @override
  String get overlapBody =>
      'Pick the right one. The app never merges or overwrites.';

  @override
  String get backOnline => 'Back online';

  @override
  String get keepSelected => 'Keep selected';

  @override
  String get editMine => 'Edit my version';

  @override
  String get overlapBanner => 'Two sleeps overlap · pick the right one';

  @override
  String get overlapKept =>
      'Kept. The other one stays in “Recently deleted” for 30 days.';

  @override
  String get overlapNotAllowed =>
      'The other one was logged by a parent. Ask a parent to choose.';

  @override
  String tourStep(int n) {
    return 'Step $n/3';
  }

  @override
  String get tour1Title => 'Log the first feed';

  @override
  String get tour1Body =>
      'Tap the Bottle card to log. The other cards work the same way.';

  @override
  String tour2Title(String baby) {
    return 'Follow $baby growing';
  }

  @override
  String get tour2Body =>
      'Enter weight and length at birth. Each new measurement is compared with the last.';

  @override
  String get tour3Title => 'Quick log from anywhere';

  @override
  String get tour3Body =>
      'The + button is always here, on every tab. Tap it to choose what to log.';

  @override
  String get tourStart => 'Start';
}
