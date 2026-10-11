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
  String get welcomeTitle => 'Grow up together,\nevery step of the way.';

  @override
  String get welcomeExplore => 'Start the first stage together';

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
  String get signInSubtitle => 'Sign in to start the journey with your child.';

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

  @override
  String get historyTitle => 'History';

  @override
  String monthChip(int month, String monthName) {
    return '$monthName';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterFeed => 'Feeds';

  @override
  String get filterPump => 'Pumping';

  @override
  String get filterSleep => 'Sleep';

  @override
  String get filterDiaper => 'Diapers';

  @override
  String get filterGrowth => 'Growth';

  @override
  String get periodNight => 'Night';

  @override
  String get periodMorning => 'Morning';

  @override
  String get periodNoon => 'Midday';

  @override
  String get periodAfternoon => 'Afternoon';

  @override
  String get periodEvening => 'Evening';

  @override
  String periodItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String loggedOnDay(String date) {
    return 'Logged on $date';
  }

  @override
  String get feedToday => 'Feeds today';

  @override
  String feedOnDay(String date) {
    return 'Feeds on $date';
  }

  @override
  String get lastFeed => 'Last feed';

  @override
  String get averageGap => 'Average gap';

  @override
  String get feedStatsLink => 'See feeding stats';

  @override
  String get feedStatsLinkHint =>
      'Day/night split · milk by hour · left/right breast';

  @override
  String get sleepToday => 'Sleep today';

  @override
  String sleepOnDay(String date) {
    return 'Sleep on $date';
  }

  @override
  String get totalSlept => 'Total slept';

  @override
  String get sleepCount => 'Sleeps';

  @override
  String sleepsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sleeps',
      one: '1 sleep',
    );
    return '$_temp0';
  }

  @override
  String get longestSleep => 'Longest sleep';

  @override
  String get awakeNow => 'Awake';

  @override
  String awakeSince(String duration, String time) {
    return '$duration · since $time';
  }

  @override
  String get asleepNow => 'Asleep';

  @override
  String get sleepStatsLink => 'See sleep stats';

  @override
  String get sleepStatsLinkHint =>
      'Day/night split · 7-day rhythm · longest sleep';

  @override
  String get diaperToday => 'Diapers today';

  @override
  String diaperOnDay(String date) {
    return 'Diapers on $date';
  }

  @override
  String get diaperTotal => 'Total';

  @override
  String get diaperLast => 'Latest';

  @override
  String timesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get pumpToday => 'Pumping today';

  @override
  String pumpOnDay(String date) {
    return 'Pumping on $date';
  }

  @override
  String get pumpSessions => 'Sessions';

  @override
  String get pumpVolume => 'Volume';

  @override
  String get pumpNotIntake =>
      'Pumped milk is not counted as the baby’s intake.';

  @override
  String rowBreastSide(String side) {
    return 'Breastfeed · $side';
  }

  @override
  String get sideBothFull => 'Both sides';

  @override
  String get sideLeftFull => 'Left side';

  @override
  String get sideRightFull => 'Right side';

  @override
  String rowSleep(String duration) {
    return 'Sleep $duration';
  }

  @override
  String rowSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String rowYesterdayTime(String time) {
    return '$time yesterday';
  }

  @override
  String get rowRunning => 'Running';

  @override
  String growthLatest(String when) {
    return 'Latest · $when';
  }

  @override
  String get growthWeightTab => 'Weight';

  @override
  String get growthLengthTab => 'Length';

  @override
  String growthDeltaVs(String delta, String date) {
    return '$delta vs $date';
  }

  @override
  String get growthMeasurements => 'Measurements';

  @override
  String get growthAdd => 'Add measurement';

  @override
  String get growthEmpty => 'No measurements yet.';

  @override
  String get emptyFeedWhat => 'a feed';

  @override
  String get emptyPumpWhat => 'pumping';

  @override
  String get emptySleepWhat => 'a sleep';

  @override
  String get emptyDiaperWhat => 'a diaper change';

  @override
  String get emptyAllWhat => 'anything';

  @override
  String emptyDayTitle(String what, String date) {
    return 'Nothing logged for $what on $date';
  }

  @override
  String emptyTodayTitle(String what) {
    return 'Nothing logged for $what today';
  }

  @override
  String get emptyDayBody =>
      'If you forgot at the time, you can log it now with a time on that day.';

  @override
  String backLog(String what) {
    return 'Log $what for that day';
  }

  @override
  String logNow(String what) {
    return 'Log $what';
  }

  @override
  String seeAllOnDay(String date) {
    return 'See everything on $date';
  }

  @override
  String get pickDateTitle => 'Pick a date';

  @override
  String calendarMonth(int month, int year, String monthName) {
    return '$monthName $year';
  }

  @override
  String calendarFootnote(String baby, String date) {
    return 'Dots = days with records. $baby was born on $date; earlier days can’t be picked.';
  }

  @override
  String get calendarFootnoteNoDob => 'Dots = days with records.';

  @override
  String get backToToday => 'Back to today';

  @override
  String get a11yPrevMonth => 'Previous month';

  @override
  String get a11yNextMonth => 'Next month';

  @override
  String get feedStatsTitle => 'Feeding stats';

  @override
  String get sleepStatsTitle => 'Sleep stats';

  @override
  String get windowToday => 'Today';

  @override
  String get window7 => '7 days';

  @override
  String get window30 => '30 days';

  @override
  String get perDay => 'Daily average';

  @override
  String get gapAverage => 'Average gap';

  @override
  String get sinceYesterday18 => 'Since 6 pm yesterday';

  @override
  String feedsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$_temp0';
  }

  @override
  String bottlesBreasts(int bottles, int breasts) {
    return '$bottles bottle · $breasts breast';
  }

  @override
  String get dayNightFeed => 'Day and night feeds';

  @override
  String dayNightFeedHint(int days) {
    return 'Day 06:00–18:00 · Night 18:00–06:00 · $days-day average';
  }

  @override
  String get nightAndToday => 'Last night and today';

  @override
  String get nightAndTodayHint => 'Last night 18:00–06:00 · Today from 06:00';

  @override
  String get dayLabel => 'Day';

  @override
  String get nightLabel => 'Night';

  @override
  String get todayLabel => 'Today';

  @override
  String get lastNightLabel => 'Last night';

  @override
  String mlAndFeeds(int ml, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$ml ml · $_temp0';
  }

  @override
  String lastNightInsight(int count, String gap, String from, String to) {
    return 'Last night: $count feeds, longest gap $gap ($from–$to).';
  }

  @override
  String lastNightGapInsight(String gap, String from, String to) {
    return 'Longest gap last night: $gap ($from–$to).';
  }

  @override
  String get milkByHour => 'Milk by hour';

  @override
  String milkByHourHint(int days) {
    return 'Bottle · $days-day average (ml)';
  }

  @override
  String peakCallout(int hour, int ml) {
    return '${hour}h · $ml ml';
  }

  @override
  String get mlPerHour => 'ml per hour';

  @override
  String get nightWindow => 'Night window';

  @override
  String get eachFeedToday => 'Each feed today';

  @override
  String get eachFeedHint =>
      'Each bar is a bottle (ml) · pink dots are breastfeeds';

  @override
  String get notYet => 'Not yet';

  @override
  String get nowLabel => 'Now';

  @override
  String get bottleMlLegend => 'Bottle (ml)';

  @override
  String get nightOrNotYet => 'Night / not yet';

  @override
  String get breastCard => 'Breastfeeding';

  @override
  String averageDays(int days) {
    return '$days-day average';
  }

  @override
  String get perDayShort => 'per day';

  @override
  String get perFeed => 'per feed';

  @override
  String get todayShort => 'today';

  @override
  String leftShare(int pct) {
    return 'Left $pct%';
  }

  @override
  String rightShare(int pct) {
    return 'Right $pct%';
  }

  @override
  String leftMinutes(int minutes) {
    return 'Left $minutes min';
  }

  @override
  String rightMinutes(int minutes) {
    return 'Right $minutes min';
  }

  @override
  String get nextSideLeft =>
      'Last feed ended on the right → start on the left next time.';

  @override
  String get nextSideRight =>
      'Last feed ended on the left → start on the right next time.';

  @override
  String get dayNightSleep => 'Day and night sleep';

  @override
  String dayNightSleepHint(int days) {
    return 'Night 18:00–06:00 · Day 06:00–18:00 · $days-day average';
  }

  @override
  String durationAndSleeps(String duration, String range) {
    return '$duration · $range sleeps';
  }

  @override
  String nightLongestInsight(int days, String from, String to) {
    return 'Longest night sleep grew from $from to $to over $days days.';
  }

  @override
  String nightLongestSame(String duration) {
    return 'Longest night sleep: $duration.';
  }

  @override
  String sleepRhythm(int days) {
    return '$days-day sleep rhythm';
  }

  @override
  String get sleepRhythmToday => 'Today’s sleep rhythm';

  @override
  String get sleepRhythmHint => 'Each row is a day · purple is sleep';

  @override
  String get longestEachDay => 'Longest sleep each day';

  @override
  String get longestEachDayHint => 'Hours slept in one stretch';

  @override
  String get legendSleepShort => 'Sleep';

  @override
  String get statsEmpty => 'Not enough data in this range yet.';

  @override
  String compactHM(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String compactH(int h) {
    return '${h}h';
  }

  @override
  String compactHMShort(int h, String m) {
    return '${h}h$m';
  }

  @override
  String durationAndSleep(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sleeps',
      one: '1 sleep',
    );
    return '$duration · $_temp0';
  }

  @override
  String get dayNightSleepTodayHint =>
      'Today · Night 00:00–06:00 · Day 06:00–18:00';

  @override
  String get historyCaregiverNote =>
      'You can edit your own records. Parents’ records are view-only.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersOverdue => 'Overdue';

  @override
  String get remindersUpcoming => 'Upcoming';

  @override
  String get remindersDone => 'Done';

  @override
  String get remindersInfo =>
      'The family sees reminders in the app. Notifications are set only on the device that created the reminder.';

  @override
  String get reminderNew => 'New reminder';

  @override
  String reminderCreatedBy(String who) {
    return 'by $who';
  }

  @override
  String reminderOverdueMeta(String when) {
    return 'Overdue · $when';
  }

  @override
  String reminderDoneMeta(String who, String date) {
    return '$who marked done · $date';
  }

  @override
  String get dayTomorrow => 'tomorrow';

  @override
  String get remindersEmpty => 'No reminders yet';

  @override
  String get remindersEmptyBody =>
      'Add vaccinations, check-ups or things to buy so the whole family sees them.';

  @override
  String get remindersCaregiverNote =>
      'Parents create reminders. You view them and mark them done.';

  @override
  String get remindersNotifOff =>
      'Reminder saved. Notifications are off on this device.';

  @override
  String get remindersOpenSettings => 'Settings';

  @override
  String get reminderSaved => 'Reminder saved';

  @override
  String get reminderMarkedDone => 'Marked done';

  @override
  String get reminderMarkedUndone => 'Marked not done';

  @override
  String get reminderDeleted => 'Reminder deleted';

  @override
  String get reminderMoved => 'Notifications will come to this device';

  @override
  String get reminderEditTitle => 'Edit reminder';

  @override
  String get reminderWhat => 'Thing to remember';

  @override
  String get reminderWhatHint => 'e.g. 6-in-1 vaccine';

  @override
  String get reminderWhen => 'Date & time';

  @override
  String get reminderLead => 'Remind me';

  @override
  String reminderFootnote(String name, String zone) {
    return 'In $name’s time zone ($zone). The family sees reminders in the app. Notifications are set only on the device that created the reminder.';
  }

  @override
  String get reminderSave => 'Save reminder';

  @override
  String get reminderTitleRequired => 'Enter what to remember.';

  @override
  String get reminderPastTime => 'Choose a time after now.';

  @override
  String get leadOnTime => 'At the time';

  @override
  String get leadOneDay => '1 day';

  @override
  String leadBefore(String lead) {
    return '$lead before';
  }

  @override
  String get reminderDelete => 'Delete reminder';

  @override
  String get reminderDeleteTitle => 'Delete this reminder?';

  @override
  String get reminderDeleteBody => 'No one in the family will see it any more.';

  @override
  String get notifPromptTitle => 'Turn on notifications on this device?';

  @override
  String get notifPromptBody =>
      'The family sees reminders in the app. Notifications are set only on the device that created the reminder.';

  @override
  String get notifPromptAllow => 'Turn on notifications';

  @override
  String reminderOverline(String name) {
    return 'Reminder · $name';
  }

  @override
  String get reminderTimeZone => 'Time zone';

  @override
  String get reminderNotify => 'Notification';

  @override
  String reminderDeviceOf(String device, String name) {
    return '$name’s $device';
  }

  @override
  String get reminderNoDevice => 'Not set on any device';

  @override
  String get reminderCreator => 'Created by';

  @override
  String get reminderDoneRow => 'Done';

  @override
  String get reminderDetailNote =>
      'Notifications are set only on the device that created the reminder. Mark it done once it’s done.';

  @override
  String get reminderMarkDone => 'Mark as done';

  @override
  String get reminderUndo => 'Mark as not done';

  @override
  String get moveNotifTitle => 'Get notifications on this device?';

  @override
  String moveNotifBody(String device) {
    return 'This reminder’s notification moves to $device. The device that has it now stops notifying.';
  }

  @override
  String get moveNotifAction => 'Move to this device';

  @override
  String reminderPeekLabel(int count) {
    return 'Reminders · $count';
  }

  @override
  String reminderInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String reminderInDuration(String duration) {
    return 'in $duration';
  }

  @override
  String get reminderPeekEmpty => 'No upcoming reminders';

  @override
  String get reminderPeekAdd => 'Add a reminder';

  @override
  String get reminderPeekMore => 'See more';

  @override
  String notifBody(String name, String when) {
    return '$name · $when';
  }

  @override
  String get notifChannel => 'Reminders';

  @override
  String get notifChannelDescription => 'Family reminders';

  @override
  String a11yMarkDone(String title) {
    return 'Mark done: $title';
  }

  @override
  String a11yUndoDone(String title) {
    return 'Mark not done: $title';
  }

  @override
  String get memJournal => 'Journal';

  @override
  String get memPhotos => 'Photos';

  @override
  String get memAlbums => 'Albums';

  @override
  String get memStories => 'Stories';

  @override
  String get memSoonTitle => 'Coming soon';

  @override
  String get memSoonBody => 'This part arrives in a coming update.';

  @override
  String get a11yViewOptions => 'View options';

  @override
  String get a11yAddMemory => 'Add to Memories';

  @override
  String memWeek(int week) {
    return 'Week $week';
  }

  @override
  String get memBeforeBirth => 'Before birth';

  @override
  String memPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String memVideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String memItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String memTodayAt(String time) {
    return 'Today · $time';
  }

  @override
  String memYesterdayAt(String time) {
    return 'Yesterday · $time';
  }

  @override
  String get memEmptyTitle => 'No memories yet';

  @override
  String memEmptyBody(String name) {
    return 'Tap + to add $name’s first photo, video or note.';
  }

  @override
  String memPhotosEmpty(String name) {
    return '$name’s photos and videos will show here.';
  }

  @override
  String memLanding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adding $count items…',
      one: 'Adding 1 item…',
    );
    return '$_temp0';
  }

  @override
  String get memNoMatch => 'Nothing matches these view options.';

  @override
  String get memProcessing => 'Processing';

  @override
  String upUploading(int done, int total) {
    return 'Uploading $done of $total';
  }

  @override
  String get upUploadingHint => 'Carry on — we’ll tell you when it’s done';

  @override
  String get upPaused => 'Paused · waiting for network';

  @override
  String get upPausedHint => 'Resumes by itself when online';

  @override
  String get upPausedByYou => 'Paused';

  @override
  String get upPausedByYouHint => 'Tap to resume';

  @override
  String upFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items not uploaded',
      one: '1 item not uploaded',
    );
    return '$_temp0';
  }

  @override
  String get upFailedHint => 'Tap to retry or skip';

  @override
  String upDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uploaded $count items',
      one: 'Uploaded 1 item',
    );
    return '$_temp0';
  }

  @override
  String upToldFamily(String names) {
    return 'Told $names';
  }

  @override
  String get upParentsOnly => 'Only parents can see them';

  @override
  String upWaitingWifi(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos waiting for Wi-Fi',
      one: '1 video waiting for Wi-Fi',
    );
    return '$_temp0';
  }

  @override
  String get upWaitingWifiHint => 'Videos upload by themselves on Wi-Fi';

  @override
  String upWaitingQuota(int count) {
    return 'Storage full · $count kept on this phone';
  }

  @override
  String get upWaitingQuotaHint => 'Tap to see';

  @override
  String upPreparing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preparing $count items',
      one: 'Preparing 1 item',
    );
    return '$_temp0';
  }

  @override
  String get addTitle => 'Add to Memories';

  @override
  String get addRecent => 'Taken today';

  @override
  String get addRecentHint => 'Tap to select';

  @override
  String addRecentCount(int count) {
    return '$count selected';
  }

  @override
  String addRecentAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count items',
      one: 'Add 1 item',
    );
    return '$_temp0';
  }

  @override
  String get addCamera => 'Take a photo or video';

  @override
  String get addCameraHint => 'Saves straight to Memories';

  @override
  String get addLibrary => 'Choose from Photos';

  @override
  String get addLibraryHint => 'Pick several photos and videos at once';

  @override
  String get addFiles => 'Choose from Files';

  @override
  String get addFilesHint => 'iCloud Drive, Google Drive, USB…';

  @override
  String get addNote => 'Write a note';

  @override
  String get addNoteHint => 'A memory in words — add photos later';

  @override
  String get pickRecent => 'Recent';

  @override
  String get pickVideos => 'Videos';

  @override
  String get pickAlbums => 'Albums';

  @override
  String pickSummary(int count, int photos, int videos) {
    return '$count items · $photos photos, $videos videos';
  }

  @override
  String pickMax(int count) {
    return 'Up to $count at a time';
  }

  @override
  String pickAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count items',
      one: 'Add 1 item',
    );
    return '$_temp0';
  }

  @override
  String pickLimit(int count) {
    return 'You can add up to $count at a time.';
  }

  @override
  String get pickNoAccess => 'Child Life can’t see your photo library yet.';

  @override
  String get pickLimited => 'You’re sharing some photos only.';

  @override
  String get pickChooseMore => 'Choose more';

  @override
  String get pickEmpty => 'No photos here';

  @override
  String get pickAlbumsTitle => 'Choose an album';

  @override
  String get pickConfirm => 'Add';

  @override
  String pickVideoTooLong(String limit) {
    return 'Videos longer than $limit can’t be added yet.';
  }

  @override
  String pickVideoTooBig(String size) {
    return 'Videos larger than $size can’t be added yet.';
  }

  @override
  String get pickPreparing => 'Getting your photos and videos ready…';

  @override
  String get composeCaption => 'Write a few lines… (optional)';

  @override
  String get composeNoteHint => 'Write what you want to remember…';

  @override
  String get composeDate => 'Date';

  @override
  String get composeByCapture => 'By capture date';

  @override
  String get composeMilestone => 'Milestone';

  @override
  String get composeNoMilestone => 'No milestone';

  @override
  String get composeWho => 'Who sees';

  @override
  String get audParents => 'Parents only';

  @override
  String get audParentsHint => 'Only parents can see it';

  @override
  String get audFamily => 'Family';

  @override
  String get audFamilyHint => 'The whole family sees it';

  @override
  String get composeNotify => 'Tell the family';

  @override
  String get composeNotifyHint => 'The family gets 1 notification';

  @override
  String composeUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Upload $count items',
      one: 'Upload 1 item',
    );
    return '$_temp0';
  }

  @override
  String get composeSaveNote => 'Save note';

  @override
  String get composeFootnote =>
      'Photos upload in the background — we’ll tell you when done.';

  @override
  String get composeNoteRequired => 'Write a few words for the note.';

  @override
  String get composeNoteSaved => 'Note saved';

  @override
  String composeMore(int count) {
    return '+$count';
  }

  @override
  String get dateTitle => 'Date of the memory';

  @override
  String dateByCaptureHint(String range) {
    return 'Each photo keeps its own date · $range';
  }

  @override
  String get dateOneForAll => 'One date for all';

  @override
  String get dateOneForAllHint => 'Use when the capture date is wrong';

  @override
  String dateBeforeBirth(String name) {
    return 'You can’t pick a date before $name was born.';
  }

  @override
  String get msTitle => 'Tag a milestone';

  @override
  String get msSearch => 'Search or type a new milestone…';

  @override
  String msSuggest(String age) {
    return 'Suggestions at $age';
  }

  @override
  String get msOwn => 'Our family’s milestones';

  @override
  String get msCreate => 'Create a milestone';

  @override
  String get msOnePer => 'One milestone per memory';

  @override
  String get msName => 'Milestone name';

  @override
  String get msPreview => 'Preview';

  @override
  String get msShared =>
      'New milestones are saved for the whole family to reuse.';

  @override
  String get msCreateTag => 'Create & tag';

  @override
  String get msNameRequired => 'Name the milestone.';

  @override
  String msChip(String name, String date) {
    return '$name · $date';
  }

  @override
  String get msFirstSmile => 'First smile';

  @override
  String get msFirstBath => 'First bath';

  @override
  String get msLiftsHead => 'Lifts head';

  @override
  String get msFirstOuting => 'First outing';

  @override
  String get msOneMonth => 'One month old';

  @override
  String get msMeetsGrandparents => 'Meets grandparents';

  @override
  String get msRollsOver => 'First roll-over';

  @override
  String get msLaughs => 'First laugh';

  @override
  String get msFirstSolids => 'First solids';

  @override
  String get msSitsUp => 'Sits up';

  @override
  String get msFirstTooth => 'First tooth';

  @override
  String get msCrawls => 'Crawls';

  @override
  String get msFirstWord => 'First word';

  @override
  String get msFirstSteps => 'First steps';

  @override
  String get msFirstBirthday => 'First birthday';

  @override
  String get qTitle => 'Uploading';

  @override
  String qSummary(int done, int total, String time) {
    return '$done of $total · about $time left';
  }

  @override
  String qSummaryNoEta(int done, int total) {
    return '$done of $total';
  }

  @override
  String get qPause => 'Pause';

  @override
  String get qResume => 'Resume';

  @override
  String get qNotice => 'The family will be told when it’s done';

  @override
  String qFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String qUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unreadable files',
      one: '1 unreadable file',
    );
    return '$_temp0';
  }

  @override
  String rowProgress(int percent, String sent, String total) {
    return '$percent% · $sent/$total';
  }

  @override
  String rowWaitingWifi(String size) {
    return 'Waiting for Wi-Fi · video $size';
  }

  @override
  String get rowFailed => 'Connection lost while uploading';

  @override
  String get rowUnreadable => 'File is damaged · can’t retry';

  @override
  String get rowDone => 'Uploaded';

  @override
  String get rowQueued => 'Waiting';

  @override
  String get rowPaused => 'Paused';

  @override
  String get rowWaitingQuota => 'Storage full · kept on this phone';

  @override
  String get rowCancelled => 'Cancelled';

  @override
  String get rowPreparing => 'Preparing';

  @override
  String get qWifiOnly => 'Videos over Wi-Fi only';

  @override
  String get qWifiOnlyHint => 'Photos still use mobile data';

  @override
  String qRetryAll(int count) {
    return 'Retry all ($count)';
  }

  @override
  String get qFootnote =>
      'Failed items stay on this phone · retried when back online.';

  @override
  String get qEmpty => 'Nothing is uploading.';

  @override
  String a11yCancelUpload(String name) {
    return 'Cancel $name';
  }

  @override
  String memMonth(int month, int year, String monthName) {
    return '$monthName $year';
  }

  @override
  String get memFilterMonth => 'Month';

  @override
  String get memSelect => 'Select';

  @override
  String get memSelectMonth => 'Select month';

  @override
  String memSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get a11yShareOptions => 'Share and options';

  @override
  String get a11yDeleteSelected => 'Delete selected';

  @override
  String get actWho => 'Who sees';

  @override
  String get actAlbum => 'Album';

  @override
  String get actDownload => 'Download';

  @override
  String get actSend => 'Send';

  @override
  String get actMore => 'More';

  @override
  String get actFavorite => 'Add to Favourites';

  @override
  String get actFavoriteHint => 'Collects into your Favourites album';

  @override
  String get actMilestoneHint => 'e.g. First smile';

  @override
  String get actDate => 'Change date';

  @override
  String get actDateHint => 'When the capture date is wrong';

  @override
  String get actStory => 'Make it a story';

  @override
  String actStoryHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use these $count items as a draft',
      one: 'Use this item as a draft',
    );
    return '$_temp0';
  }

  @override
  String get actCover => 'Set as album cover';

  @override
  String get actCoverHint => 'Only with 1 photo selected';

  @override
  String get actSoon => 'Coming soon';

  @override
  String whoItemsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Who sees these $count items?',
      one: 'Who sees this item?',
    );
    return '$_temp0';
  }

  @override
  String toastSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count items to Photos',
      one: 'Saved 1 item to Photos',
    );
    return '$_temp0';
  }

  @override
  String get toastSaving => 'Saving to Photos…';

  @override
  String get toastSaveFailed => 'Couldn’t save to Photos. Please try again.';

  @override
  String toastDateChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Changed the date of $count items',
      one: 'Changed the date of 1 item',
    );
    return '$_temp0';
  }

  @override
  String toastTagged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tagged $count items',
      one: 'Tagged 1 item',
    );
    return '$_temp0';
  }

  @override
  String toastParentsOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count items to Parents only',
      one: 'Moved 1 item to Parents only',
    );
    return '$_temp0';
  }

  @override
  String toastShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared $count items with the family',
      one: 'Shared 1 item with the family',
    );
    return '$_temp0';
  }

  @override
  String toastDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count items',
      one: 'Deleted 1 item',
    );
    return '$_temp0';
  }

  @override
  String get toastActionFailed =>
      'That didn’t work. Check the connection and try again.';

  @override
  String delTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items?',
      one: 'Delete 1 item?',
    );
    return '$_temp0';
  }

  @override
  String get delBody =>
      'They’ll disappear from the whole family’s Memories. The originals on your phone stay.';

  @override
  String get delRecover =>
      'You can restore them for 30 days from “Recently deleted”.';

  @override
  String get delParentsOnly => 'Only parents can delete.';

  @override
  String delN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items',
      one: 'Delete 1 item',
    );
    return '$_temp0';
  }

  @override
  String get gotoTitle => 'Go to month';

  @override
  String gotoMonthShort(int month, String monthName) {
    return '$monthName';
  }

  @override
  String gotoNote(String name, String date) {
    return '$name was born on $date · other years appear once they have photos';
  }

  @override
  String scrubberMonth(int month, int year, String monthName) {
    return '$monthName $year';
  }

  @override
  String get viewTitle => 'View options';

  @override
  String get viewGroup => 'Group by';

  @override
  String get viewDay => 'Day';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewMonth => 'Month';

  @override
  String get viewLayout => 'Layout';

  @override
  String get viewSmall => 'Small grid';

  @override
  String get viewLarge => 'Large grid';

  @override
  String get viewList => 'List';

  @override
  String get viewShow => 'Show';

  @override
  String get viewWithMilestone => 'With milestone';

  @override
  String get viewAsRelative => 'View as a relative';

  @override
  String get viewAsRelativeHint => 'Check what relatives can see';

  @override
  String get viewApply => 'Apply';

  @override
  String get viewAsRelativeBanner => 'Viewing as a relative';

  @override
  String get viewAsRelativeExit => 'Exit';

  @override
  String dayGroup(String date, String counts) {
    return '$date · $counts';
  }

  @override
  String viewerPosted(String date, String who) {
    return '$date · posted by $who';
  }

  @override
  String get viewerShare => 'Share';

  @override
  String get viewerVideoLoading => 'Loading video…';

  @override
  String get viewerVideoFailed => 'Couldn’t open the video.';

  @override
  String get a11yPlay => 'Play video';

  @override
  String get a11yPause => 'Pause video';

  @override
  String get viewerSeek => 'Video position';

  @override
  String get viewerToggleChrome => 'show or hide controls';

  @override
  String viewerThumb(int index, int count) {
    return 'Item $index of $count';
  }

  @override
  String get shareTitle => 'Share with the family?';

  @override
  String sharePrivatePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count private photos',
      one: '1 private photo',
    );
    return '$_temp0';
  }

  @override
  String sharePrivateItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count private items',
      one: '1 private item',
    );
    return '$_temp0';
  }

  @override
  String get shareWillSee => 'Will see them after sharing';

  @override
  String shareRelatives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relatives',
      one: '1 relative',
    );
    return '$_temp0';
  }

  @override
  String shareCaregivers(String names) {
    return 'Caregivers ($names) don’t see Memories.';
  }

  @override
  String get shareNotifyHint => 'Send 1 general notice, without photos';

  @override
  String shareN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share $count items',
      one: 'Share 1 item',
    );
    return '$_temp0';
  }

  @override
  String shareNPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share $count photos',
      one: 'Share 1 photo',
    );
    return '$_temp0';
  }

  @override
  String camDest(String name) {
    return 'Saving to $name’s Memories';
  }

  @override
  String get camFlash => 'Flash';

  @override
  String get camVideo => 'VIDEO';

  @override
  String get camPhoto => 'PHOTO';

  @override
  String camDone(int count) {
    return 'Done ($count)';
  }

  @override
  String get camHint => 'Keep shooting · tap Done to write & share';

  @override
  String get camUnavailable => 'This phone’s camera isn’t available.';

  @override
  String get a11yShutter => 'Take';

  @override
  String albCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get albNew => 'New album';

  @override
  String get albFavorites => 'Favourites';

  @override
  String get albFavoritesMine => 'yours only';

  @override
  String get albOnlyYou => 'Only you';

  @override
  String get albFavoritesHint => 'photos you marked';

  @override
  String get albFromMilestones => 'From the milestones you tagged';

  @override
  String get albByMilestone => 'By milestone';

  @override
  String albShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums the parents shared',
      one: '1 album the parents shared',
    );
    return '$_temp0';
  }

  @override
  String get albEmpty => 'No albums yet';

  @override
  String get albEmptyBody =>
      'Make albums to gather photos by theme, like Bath time or Little hands.';

  @override
  String albUpdated(String counts, String when) {
    return '$counts · updated $when';
  }

  @override
  String get albAddPhotos => 'Add photos';

  @override
  String get albStory => 'Make it a story';

  @override
  String albSharedBy(String who) {
    return '$who shared with the family';
  }

  @override
  String get albNoItems => 'This album has no photos yet.';

  @override
  String get albCoverEmptyMeta => 'No photos yet';

  @override
  String get albCoverAdd => 'Add photos';

  @override
  String get albWhoButton => 'Who sees this album';

  @override
  String get albRename => 'Rename album';

  @override
  String get albCover => 'Change cover';

  @override
  String get albWhoFamilyHint => 'Every relative in the family';

  @override
  String get albSelect => 'Select photos';

  @override
  String get albSelectHint => 'Remove from the album, change who sees…';

  @override
  String get albSort => 'Sort';

  @override
  String get albDownload => 'Download the whole album';

  @override
  String albDownloadHint(String counts, String size) {
    return '$counts · about $size';
  }

  @override
  String get albDelete => 'Delete album';

  @override
  String get albDeleteHint => 'Deletes the album only; photos stay in Memories';

  @override
  String get albName => 'Album name';

  @override
  String get albSuggestions => 'Suggestions';

  @override
  String get albSuggestBath => 'Bath time';

  @override
  String get albSuggestSun => 'Sunbathing';

  @override
  String get albSuggestSwim => 'First swim';

  @override
  String get albSuggestHands => 'Little hands';

  @override
  String get albSuggestSleep => 'Sleeping sweetly';

  @override
  String get albSaveName => 'Save name';

  @override
  String get albNameRequired => 'Name the album.';

  @override
  String get albCreate => 'Create album';

  @override
  String albCreated(String name) {
    return 'Created “$name”';
  }

  @override
  String get albCoverTitle => 'Choose a cover';

  @override
  String get albSetCover => 'Set as cover';

  @override
  String get albCoverSet => 'Cover changed';

  @override
  String albAppliesTo(int count) {
    return 'Applies to all $count items in the album';
  }

  @override
  String get albLaterFollow =>
      'Photos added later follow the album too. Caregivers don’t see Memories.';

  @override
  String get albNoticeHint => '1 general notice, without photos';

  @override
  String albStayShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items stay visible to the family because they are in another Family album.',
      one:
          '1 item stays visible to the family because it is in another Family album.',
    );
    return '$_temp0';
  }

  @override
  String get albAudienceSaved => 'Album audience changed';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortNewestHint => 'Recent shots first';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortOldestHint => 'From the beginning, good for looking back';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortAddedHint => 'By when photos were added';

  @override
  String get albRemove => 'Remove from album';

  @override
  String albRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count items from the album',
      one: 'Removed 1 item from the album',
    );
    return '$_temp0';
  }

  @override
  String get dlTitle => 'Download';

  @override
  String dlSummary(int count, String size) {
    return '$count items · about $size';
  }

  @override
  String dlInto(String name) {
    return 'Saves into a “$name” album in Photos';
  }

  @override
  String get dlWifi => 'Wi-Fi only';

  @override
  String get dlWifiHint => 'Large videos wait for Wi-Fi';

  @override
  String dlN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $count items',
      one: 'Download 1 item',
    );
    return '$_temp0';
  }

  @override
  String get dlFootnote =>
      'Downloads in the background — we’ll tell you when done.';

  @override
  String get dlNeedsWifi => 'Waiting for Wi-Fi to download videos.';

  @override
  String albDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String albDeleteBody(int count) {
    return '$count photos and videos stay in Photos and Journal. Only the album goes.';
  }

  @override
  String get albDeleteFamily => 'The family won’t see this album any more.';

  @override
  String get albDeleted => 'Album deleted';

  @override
  String get albPickTitle => 'Add to album';

  @override
  String get albPickNew => 'New album';

  @override
  String get albPickHint =>
      'You can pick several albums. Photos still follow the “Who sees” you chose.';

  @override
  String get albPickNone => 'None';

  @override
  String albPickMore(String first, int count) {
    return '$first +$count';
  }

  @override
  String albAdded(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to “$name”',
      one: 'Added 1 item to “$name”',
    );
    return '$_temp0';
  }

  @override
  String get albFamilySwitched =>
      'Family album: “Who sees” switched to Family.';

  @override
  String get albPickFromMemories => 'Choose from Memories';

  @override
  String get favAdded => 'Added to Favourites';

  @override
  String get favRemoved => 'Removed from Favourites';

  @override
  String get love => 'Love';

  @override
  String lovesNamed(String names) {
    return '$names loved this';
  }

  @override
  String lovesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count loves',
      one: '1 love',
    );
    return '$_temp0';
  }

  @override
  String get messageAction => 'Message';

  @override
  String get messageParents => 'Message the parents';

  @override
  String get messagePlaceholder => 'Message the parents…';

  @override
  String messageTo(String who) {
    return 'Message $who';
  }

  @override
  String get messageSend => 'Send';

  @override
  String get messageSent => 'Message sent';

  @override
  String get messageHint => 'Only the parents read it. It isn’t a chat.';

  @override
  String get messageFailed =>
      'Couldn’t send. Check the connection and try again.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesEmpty => 'No messages yet.';

  @override
  String messagesUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get messagesAboutPhoto => 'about a photo';

  @override
  String get messagesAboutMemory => 'about a memory';

  @override
  String messagesAboutAlbum(String name) {
    return 'about “$name”';
  }

  @override
  String get messagesAboutAlbumGeneric => 'about an album';

  @override
  String get messagesAboutStory => 'about a story';

  @override
  String get messagesAboutRecord => 'about a care entry';

  @override
  String messagesOnItem(int count) {
    return 'Messages ($count)';
  }

  @override
  String messageFrom(String who, String when) {
    return '$who · $when';
  }

  @override
  String get relSubtitle => 'What the parents share with the family';

  @override
  String get relEmptyTitle => 'Nothing shared yet';

  @override
  String get relEmptyBody =>
      'When the parents share photos with the family, you’ll get a notification and see them here.';

  @override
  String viewerShared(String date, String who) {
    return '$date · shared by $who';
  }

  @override
  String viewerInAlbum(String meta, String name) {
    return '$meta · album $name';
  }

  @override
  String get albOptions => 'Album options';

  @override
  String meRoleOwner(String relation, String names) {
    return '$relation · profile owner of $names';
  }

  @override
  String meRoleParent(String relation, String names) {
    return '$relation · co-parent of $names';
  }

  @override
  String meRoleCaregiver(String relation, String names) {
    return '$relation · cares for $names';
  }

  @override
  String meRoleRelative(String relation, String names) {
    return '$relation · family of $names';
  }

  @override
  String get meStorage => 'Storage';

  @override
  String meStorageOf(String used, String quota) {
    return '$used of $quota';
  }

  @override
  String get meStorageShared => 'Shared by all your babies';

  @override
  String get meBabies => 'Baby profiles';

  @override
  String get meAssigned => 'Assigned babies';

  @override
  String get meFollowing => 'Babies you follow';

  @override
  String get meNotifications => 'Notifications';

  @override
  String get meOn => 'On';

  @override
  String get meSome => 'Some';

  @override
  String get meOff => 'Off';

  @override
  String get meAccount => 'Account & sign-in';

  @override
  String get meAccountHint => 'Email, Apple, devices';

  @override
  String get meHelp => 'Help & contact';

  @override
  String get meSignOutTitle => 'Sign out on this phone?';

  @override
  String get meSignOutBody => 'Everything you saved stays in your account.';

  @override
  String meSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items waiting to upload won’t be uploaded if you sign out now.',
      one: '1 item waiting to upload won’t be uploaded if you sign out now.',
    );
    return '$_temp0';
  }

  @override
  String get meSignedOutRemote =>
      'This phone was signed out from another device.';

  @override
  String stOfQuota(String quota) {
    return 'of $quota';
  }

  @override
  String get stFootnote =>
      'Shared by all babies · photos both parents upload count here';

  @override
  String stNearTitle(int percent) {
    return 'Almost full · $percent%';
  }

  @override
  String get stNearBody =>
      'Videos take the most space. Delete some long videos or contact the Child Life team to expand.';

  @override
  String stFullTitle(String quota) {
    return 'All $quota used';
  }

  @override
  String stFullBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Photo and video uploads are paused. $count new items are kept on this phone, not lost. Care logs still save as usual.',
      one:
          'Photo and video uploads are paused. 1 new item is kept on this phone, not lost. Care logs still save as usual.',
      zero:
          'Photo and video uploads are paused. Care logs still save as usual.',
    );
    return '$_temp0';
  }

  @override
  String get stFullBodyNone =>
      'Photo and video uploads are paused. Care logs still save as usual.';

  @override
  String get stByBaby => 'By baby';

  @override
  String stCounts(int photos, int videos) {
    return '$photos photos · $videos videos';
  }

  @override
  String get stByType => 'By type';

  @override
  String get stVideo => 'Videos';

  @override
  String get stVideoHint => 'See the largest videos';

  @override
  String get stPhotos => 'Photos';

  @override
  String get stNotes => 'Stories & notes';

  @override
  String get stBin => 'Recently deleted';

  @override
  String get stBinHint => 'Counted until removed for good after 30 days';

  @override
  String get stNeedMore => 'Need more space?';

  @override
  String stNeedMoreBody(String quota) {
    return 'Each family has $quota. Contact the Child Life team to expand.';
  }

  @override
  String get stContact => 'Contact the team';

  @override
  String stRequested(int amount, String date) {
    return 'Requested +$amount GB · $date';
  }

  @override
  String get stRequestedHint => 'The Child Life team will reply by email.';

  @override
  String get stReqTitle => 'Request more space';

  @override
  String get stReqHow => 'How much more?';

  @override
  String get stReqMessage => 'Message (optional)';

  @override
  String stReqAttach(String email, String used, String quota) {
    return 'Attached: $email · using $used of $quota';
  }

  @override
  String get stReqSend => 'Send request';

  @override
  String get stReqFootnote =>
      'The Child Life team will reply by email, usually within 1–2 business days.';

  @override
  String get stReqSent => 'Request sent';

  @override
  String get needEmailAccount =>
      'Save your account with an email to send a request.';

  @override
  String get stVideosTitle => 'Largest videos';

  @override
  String get stVideosHint => 'Open a video to watch, download or delete it.';

  @override
  String get stVideosEmpty => 'No videos yet.';

  @override
  String get stLoadFailed => 'Couldn’t load storage. Pull down to try again.';

  @override
  String bpCarers(String age, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$age · $count carers',
      one: '$age · 1 carer',
    );
    return '$_temp0';
  }

  @override
  String get bpAdd => 'Add a baby';

  @override
  String get bpDeleting => 'Deleting…';

  @override
  String bpBorn(String age, String date) {
    return '$age · born $date';
  }

  @override
  String bpWeight(String when) {
    return 'Weight · $when';
  }

  @override
  String bpLength(String when) {
    return 'Length · $when';
  }

  @override
  String get bpInfo => 'Details';

  @override
  String get bpOf => 'For the baby';

  @override
  String bpFamily(String name) {
    return '$name’s family';
  }

  @override
  String get bpGrowthHint => 'Weight and length charts';

  @override
  String bpStorage(String name) {
    return '$name’s storage';
  }

  @override
  String bpStorageHint(String quota) {
    return 'Counts toward your $quota';
  }

  @override
  String bpDelete(String name) {
    return 'Delete $name’s profile';
  }

  @override
  String bpDeleteOwner(String owner) {
    return 'Only the profile owner ($owner) can do this';
  }

  @override
  String get bpSave => 'Save changes';

  @override
  String get bpPrivacy => 'Relatives only see the nickname';

  @override
  String get bpOptional => '· optional';

  @override
  String get bpSaved => 'Profile saved';

  @override
  String bpDelTitle(String name) {
    return 'Delete $name’s profile?';
  }

  @override
  String bpDelBody(String name) {
    return 'All of $name’s care logs, photos, videos and stories will be deleted for the whole family. This can’t be undone.';
  }

  @override
  String bpDelFree(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Frees $size · $count people lose access',
      one: 'Frees $size · 1 person loses access',
    );
    return '$_temp0';
  }

  @override
  String get bpDelTip => 'Download photos to your phone before deleting.';

  @override
  String bpDelType(String name) {
    return 'Type “$name” to confirm';
  }

  @override
  String get bpDelConfirm => 'Delete permanently';

  @override
  String bpDelStarted(String name) {
    return 'Deleting $name’s profile…';
  }

  @override
  String bpDelDone(String name) {
    return '$name’s profile was deleted';
  }

  @override
  String get bpDelRetrying => 'Not finished yet; retrying by itself.';

  @override
  String get bpLocked =>
      'This profile is being deleted. New entries can’t be added.';

  @override
  String get pfTitle => 'Your profile';

  @override
  String get pfName => 'Display name';

  @override
  String get pfWho => 'Who you are to each baby';

  @override
  String get pfFootnote =>
      'The family sees this name and role when you log or share.';

  @override
  String pfRelationTitle(String name) {
    return 'What are you to $name?';
  }

  @override
  String get pfSaved => 'Saved';

  @override
  String get acTitle => 'Account';

  @override
  String get acSignIn => 'Sign-in';

  @override
  String acEmailVerified(String email) {
    return '$email · verified';
  }

  @override
  String acEmailUnverified(String email) {
    return '$email · not verified';
  }

  @override
  String get acLinked => 'Linked';

  @override
  String get acUnlink => 'Unlink';

  @override
  String get acUnlinkLast => 'Keep at least one way to sign in.';

  @override
  String acUnlinked(String provider) {
    return '$provider unlinked';
  }

  @override
  String get acPassword => 'Change password';

  @override
  String acPasswordSent(String email) {
    return 'Password email sent to $email';
  }

  @override
  String get acDevices => 'Signed-in devices';

  @override
  String get acThisDevice => 'This phone';

  @override
  String acActive(String when) {
    return 'Active $when';
  }

  @override
  String acDeviceSignedOut(String name) {
    return '$name signed out';
  }

  @override
  String get acOwner => 'Profile owner';

  @override
  String get acTransfer => 'Transfer ownership';

  @override
  String acTransferHint(String names) {
    return 'To a co-parent of $names';
  }

  @override
  String acTransferBody(String names) {
    return 'They become the owner of $names: deleting profiles, passing ownership on and the family storage. They need to accept.';
  }

  @override
  String get acTransferNone => 'Nobody co-parents all the babies yet.';

  @override
  String get acTransferSend => 'Send offer';

  @override
  String acTransferPending(String name) {
    return 'Waiting for $name to accept';
  }

  @override
  String get acTransferCancel => 'Cancel offer';

  @override
  String acTransferSent(String name) {
    return 'Offer sent to $name';
  }

  @override
  String acOfferTitle(String name) {
    return '$name wants to make you the profile owner';
  }

  @override
  String acOfferBody(String names) {
    return 'You’ll own $names and look after the family storage.';
  }

  @override
  String get acOfferAccept => 'Accept';

  @override
  String get acOfferDecline => 'Decline';

  @override
  String get acOfferAccepted => 'You’re now the profile owner';

  @override
  String get acReceiverOwns => 'This person already owns other profiles.';

  @override
  String get acExport => 'Export data';

  @override
  String get acExportHint => 'Care logs, photos and videos';

  @override
  String acExportTitle(String name) {
    return 'Export $name’s data';
  }

  @override
  String get acExportCare => 'Care logs';

  @override
  String get acExportCareHint => 'CSV and JSON';

  @override
  String get acExportMedia => 'Photos and videos';

  @override
  String get acExportMediaHint => 'ZIP · profile owner only';

  @override
  String get acExportStart => 'Start export';

  @override
  String get acExportFootnote =>
      'We’ll email you when it’s ready. The download link expires after 24 hours.';

  @override
  String get acExportQueued => 'Preparing…';

  @override
  String acExportReady(String when) {
    return 'Ready · expires $when';
  }

  @override
  String get acExportExpired => 'Expired';

  @override
  String get acExportFailed => 'Export failed';

  @override
  String get acExportRunning => 'Another export is still running.';

  @override
  String get acDelete => 'Delete account';

  @override
  String acDeleteBlocked(String names) {
    return 'Transfer ownership of $names first';
  }

  @override
  String get acDeleteHint => 'Removes your name, email and devices';

  @override
  String get acDeleteTitle => 'Delete your account?';

  @override
  String get acDeleteBody =>
      'Your name, email and devices will be deleted. Logs and memories you shared stay with the family, shown as “Deleted user”. This can’t be undone.';

  @override
  String get acDeleting => 'Deleting your account…';

  @override
  String get deletedUser => 'Deleted user';

  @override
  String get ntMemories => 'New memories';

  @override
  String get ntMemoriesHint =>
      'When the parents share photos, albums or stories';

  @override
  String get ntMessages => 'Messages';

  @override
  String get ntMessagesHint => 'When someone messages the parents';

  @override
  String get ntReminders => 'Reminders';

  @override
  String get ntRemindersHint => 'On the phone chosen for each reminder';

  @override
  String get ntStorage => 'Storage';

  @override
  String get ntStorageHint => 'When nearly or completely full';

  @override
  String get ntFootnote =>
      'Notifications never include photos or the baby’s name.';

  @override
  String get hpTopic => 'Topic';

  @override
  String get hpCatMemories => 'Memories & media';

  @override
  String get hpCatFamily => 'Family & roles';

  @override
  String get hpCatInvites => 'Invites';

  @override
  String get hpCatSync => 'Sync';

  @override
  String get hpCatAccount => 'Account';

  @override
  String get hpCatStorage => 'Storage';

  @override
  String get hpCatStories => 'Stories';

  @override
  String get hpMessage => 'How can we help?';

  @override
  String get hpDiagnostics => 'Include diagnostics';

  @override
  String get hpDiagnosticsHint =>
      'App version, phone model, sync status. No photos or logs.';

  @override
  String hpFootnote(String email) {
    return 'We’ll reply to $email.';
  }

  @override
  String hpSent(String ticket) {
    return 'Sent · reference $ticket';
  }

  @override
  String get srySuggestTag => 'This week’s suggestion';

  @override
  String srySuggestSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From $count photos · edit before saving',
      one: 'From 1 photo · edit before saving',
    );
    return '$_temp0';
  }

  @override
  String get srySuggestCta => 'See the draft';

  @override
  String sryDrafts(int count) {
    return 'Drafts · $count';
  }

  @override
  String get sryShared => 'Shared';

  @override
  String sryToldBy(String who, String when) {
    return 'Told by $who · $when';
  }

  @override
  String sryWroteBy(String who, String when) {
    return 'Written by $who · last edited $when';
  }

  @override
  String get sryDraft => 'Draft';

  @override
  String get sryFromSuggestion => 'Draft from a suggestion · not saved';

  @override
  String get sryWrite => 'Write';

  @override
  String get sryEmptyTitle => 'No stories yet';

  @override
  String get sryEmptyBody =>
      'Write about a moment, or wait for the weekend suggestion from what you logged.';

  @override
  String get sryRelEmpty => 'The parents haven’t shared a story yet.';

  @override
  String get sryNewTitle => 'What will you write?';

  @override
  String get sryKindStory => 'Story';

  @override
  String get sryKindStoryHint => 'Tell a moment, with photos';

  @override
  String get sryKindLetter => 'Letter';

  @override
  String get sryKindLetterHint => 'A letter for your child to read later';

  @override
  String get srySaveDraft => 'Save draft';

  @override
  String sryAiTip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'AI drafted this from $count photos. Tap any paragraph, photo or title to edit.',
      one:
          'AI drafted this from 1 photo. Tap any paragraph, photo or title to edit.',
    );
    return '$_temp0';
  }

  @override
  String get sryTip => 'Tap any paragraph, photo or title to edit.';

  @override
  String get sryChangeCover => 'Change cover';

  @override
  String get sryAddCover => 'Add a cover';

  @override
  String get sryTitleHint => 'Title';

  @override
  String get sryParagraphHint => 'Write a few lines…';

  @override
  String sryMetaPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String sryMetaMilestone(String name) {
    return 'milestone $name';
  }

  @override
  String get sryRewrite => 'Rewrite';

  @override
  String get sryWarmer => 'Warmer';

  @override
  String get sryShorter => 'Shorter';

  @override
  String get sryUndo => 'Undo';

  @override
  String get sryAddBlock => 'Add paragraph · photos · milestone';

  @override
  String get sryAddParagraph => 'Paragraph';

  @override
  String get sryAddPhotos => 'Photos';

  @override
  String get sryAddMilestone => 'Milestone';

  @override
  String get sryAddQuote => 'Pull quote';

  @override
  String get sryArrange => 'Arrange';

  @override
  String get sryPreviewSave => 'Preview & save';

  @override
  String get sryDiscardTitle => 'Discard changes?';

  @override
  String get sryDiscardBody => 'What you just changed isn’t saved.';

  @override
  String get sryDiscard => 'Discard';

  @override
  String get sryKeepEditing => 'Keep editing';

  @override
  String get sryDraftSaved => 'Draft saved';

  @override
  String get sryDiscardDraft => 'Discard draft';

  @override
  String get sryEditParagraph => 'Edit paragraph';

  @override
  String get sryEdited => 'Edited · no longer AI text';

  @override
  String sryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get srySuggestFor => 'Suggestions for this paragraph';

  @override
  String get sryUseThis => 'Use this';

  @override
  String get sryOtherSuggestion => 'Another suggestion';

  @override
  String get sryAiUnavailable =>
      'AI isn’t available right now. You can still edit by hand.';

  @override
  String get sryAiLimit => 'You’ve used today’s suggestions.';

  @override
  String get sryAiWorking => 'Writing…';

  @override
  String get sryPhotosTitle => 'Photos in the story';

  @override
  String get sryChangePhoto => 'Change photos';

  @override
  String sryChangePhotoHint(String name) {
    return 'Pick from $name’s Memories';
  }

  @override
  String get sryAddToGroup => 'Add photos to this group';

  @override
  String get sryAddToGroupHint => 'Up to 4 photos in a group';

  @override
  String get sryCaption => 'Add a caption';

  @override
  String get sryCaptionHint => 'Shown small under the photo';

  @override
  String get sryMakeCover => 'Make it the cover';

  @override
  String get sryRemovePhotos => 'Remove from the story';

  @override
  String get sryRemovePhotosHint => 'The photos stay in Memories';

  @override
  String get sryArrangeHint =>
      'Hold ≡ and drag to reorder. Swipe left to delete a block.';

  @override
  String get sryCoverRow => 'Cover photo';

  @override
  String sryParagraphN(int n) {
    return 'Paragraph $n';
  }

  @override
  String get sryPhotoGroup => 'Photo group';

  @override
  String get sryMilestoneRow => 'Milestone';

  @override
  String get sryQuoteRow => 'Pull quote';

  @override
  String get sryPreviewLabel => 'PREVIEW';

  @override
  String get sryNeedTitle => 'Give the story a title.';

  @override
  String get sryNeedContent => 'Add at least one paragraph or photo.';

  @override
  String get srySaveTitle => 'Save story';

  @override
  String get sryPrivate => 'Private';

  @override
  String get sryFamilyRead => 'The whole family reads it';

  @override
  String get sryOneNotice => '1 general notification';

  @override
  String get sryShareAfter => 'You can share outside once it’s saved.';

  @override
  String sryPrivatePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count parents-only photos will be seen by the family in this story.',
      one: '1 parents-only photo will be seen by the family in this story.',
    );
    return '$_temp0';
  }

  @override
  String get srySavedNotified => 'Saved · the family was told';

  @override
  String get srySaved => 'Story saved';

  @override
  String get sryShare => 'Share';

  @override
  String get sryWhoReads => 'Who reads this story';

  @override
  String get sryAudienceChanged => 'Readers changed';

  @override
  String get sryDelete => 'Delete story';

  @override
  String get sryDeleteTitle => 'Delete this story?';

  @override
  String get sryDeleteBody =>
      'Nobody in the family will see it any more. The photos stay in Memories.';

  @override
  String get sryDeleted => 'Story deleted';

  @override
  String sryMetaSaved(String who, String when, String audience) {
    return 'Told by $who · $when · $audience';
  }

  @override
  String sryRelMeta(String who, String when) {
    return '$who shared with the family · $when';
  }

  @override
  String sryMilestoneOn(String name, String date) {
    return '$name · $date';
  }

  @override
  String get sryMore => 'Story options';

  @override
  String get shInFamily => 'In the family';

  @override
  String get shFamilyReading => 'The family is reading';

  @override
  String get shParentsReading => 'Only the parents are reading';

  @override
  String get shTapToChange => 'Family told · tap to change';

  @override
  String get shTapToChangeParents => 'Tap to change';

  @override
  String get shOutside => 'Outside the family';

  @override
  String get shCard => 'Photo card';

  @override
  String get shCardHint => 'Made for Facebook, Instagram, Zalo';

  @override
  String get shLink => 'Private link';

  @override
  String get shLinkHint => 'Expires · no app needed';

  @override
  String get shOutsideNote =>
      'Only parents see “Outside the family”. Real name and birth date are hidden by default.';

  @override
  String get shPrivatePhotosNote =>
      'Parents-only photos don’t appear outside the family.';

  @override
  String get cdNext => 'Next';

  @override
  String get cdMoment => '1 photo';

  @override
  String get cdThree => '3 photos';

  @override
  String get cdFour => '4 photos';

  @override
  String get cdLetter => 'Words';

  @override
  String get cdNight => 'Night';

  @override
  String get cdQuote => 'Quote';

  @override
  String get cdPhoto => 'Photo';

  @override
  String get cdCover => 'Cover photo';

  @override
  String get cdShowAge => 'Show age instead of birth date';

  @override
  String cdTo(String name) {
    return 'Dear $name,';
  }

  @override
  String cdSigned(String who, String season) {
    return '— $who, $season';
  }

  @override
  String get cdSaved => 'Card made';

  @override
  String get cdSize => 'Image 1080 × 1350';

  @override
  String get lkExpires => 'Expires after';

  @override
  String get lk24h => '24 hours';

  @override
  String get lk7d => '7 days';

  @override
  String get lk30d => '30 days';

  @override
  String get lkHideIdentity => 'Hide real name & birth date';

  @override
  String lkHideIdentityHint(String name) {
    return 'Only “$name” and the age in weeks';
  }

  @override
  String get lkDownload => 'Allow photo downloads';

  @override
  String get lkDownloadHint => 'Off: viewers can look but not save';

  @override
  String get lkPasscode => 'Ask for a 4-digit passcode';

  @override
  String get lkPasscodeHint => 'Send the passcode to the recipient separately';

  @override
  String get lkNote => 'You can see the views and revoke it at any time.';

  @override
  String get lkCopyShare => 'Copy & share';

  @override
  String get lkCopy => 'Copy';

  @override
  String get lkCopied => 'Link copied';

  @override
  String get lkPasscodeTitle => 'The link’s passcode';

  @override
  String get lkPasscodeBody =>
      'Send this passcode to the recipient separately. Child Life won’t show it again.';

  @override
  String get lkScreenshotNote => 'Viewers can still take screenshots.';

  @override
  String get soTitle => 'Shared outside';

  @override
  String soOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links open',
      one: '1 link open',
    );
    return '$_temp0';
  }

  @override
  String get soOpen => 'Open';

  @override
  String get soCards => 'Saved cards';

  @override
  String get soClosed => 'Expired';

  @override
  String soViewsLeftDays(int count, String left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views · $left left',
      one: '1 view · $left left',
    );
    return '$_temp0';
  }

  @override
  String soDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String soHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get soRevoke => 'Revoke';

  @override
  String get soRevokeTitle => 'Revoke the link?';

  @override
  String get soRevokeBody =>
      'Anyone with the link won’t be able to open it any more.';

  @override
  String get soRevoked => 'Revoked';

  @override
  String soExpiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String get soCardRow => 'Image · can’t be revoked';

  @override
  String get soEmpty => 'No stories shared outside yet.';

  @override
  String get shareExtTitle => 'Add to Memories';

  @override
  String get shareExtAdd => 'Add';

  @override
  String get shareExtBaby => 'Baby';

  @override
  String get shareExtNotifyHint =>
      'Send 1 notification when the upload finishes';

  @override
  String shareExtPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String shareExtVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String get shareExtFootnote => 'Uploads start when you open Child Life.';

  @override
  String get shareExtSignedOut =>
      'Open Child Life and sign in to add photos to Memories.';

  @override
  String get shareExtNoBaby =>
      'Only parents (Cùng nuôi) can add memories for a baby.';

  @override
  String get shareExtNothing => 'There are no photos or videos to add.';

  @override
  String get shareExtClose => 'Close';

  @override
  String get upUploadsPaused => 'Photo and video uploads are paused';

  @override
  String get upUploadsPausedHint =>
      'They\'ll continue on their own when uploads reopen.';

  @override
  String get rowUploadsPaused => 'Uploads paused';

  @override
  String get rowRejected => 'Couldn\'t upload';

  @override
  String get glanceAppName => 'Child Life';

  @override
  String get glanceYou => 'You';

  @override
  String get glanceBottle => 'Bottle';

  @override
  String get glanceBreast => 'Breastfeeding';

  @override
  String get glanceSleep => 'Sleep';

  @override
  String get glanceSleepTitle => 'Sleep';

  @override
  String get glanceDiaper => 'Diaper';

  @override
  String get glanceDiaperWet => 'Wet';

  @override
  String get glanceDiaperDirty => 'Dirty';

  @override
  String get glanceDiaperBoth => 'Both';

  @override
  String glanceAgo(String t) {
    return '$t ago';
  }

  @override
  String glanceLoggedBy(String name) {
    return '$name logged';
  }

  @override
  String glancePlusMl(String ml) {
    return '+ $ml ml';
  }

  @override
  String glanceLoggedBottle(String ml) {
    return '$ml ml';
  }

  @override
  String glanceLoggedDiaper(String kind) {
    return '$kind';
  }

  @override
  String glanceLogged(String what, String name) {
    return 'Logged $what · $name';
  }

  @override
  String glanceLoggedToast(String what) {
    return 'Logged $what';
  }

  @override
  String get glanceJustNow => 'Just now';

  @override
  String get glanceUndo => 'Undo';

  @override
  String get glanceEdit => 'Edit';

  @override
  String get glanceChangeType => 'Change type';

  @override
  String get glanceStartBreast => 'Start feeding';

  @override
  String get glanceFeeding => 'Feeding';

  @override
  String get glanceSwitchSide => 'Switch side';

  @override
  String get glanceDone => 'Done';

  @override
  String get glanceBreastSideLeft => 'Left side';

  @override
  String get glanceBreastSideRight => 'Right side';

  @override
  String glanceSinceTime(String time) {
    return 'since $time';
  }

  @override
  String glanceAwakeFor(String t) {
    return 'Awake $t';
  }

  @override
  String glanceWokeAt(String time) {
    return 'Woke at $time';
  }

  @override
  String get glanceStartSleep => 'Start sleep';

  @override
  String get glanceSleeping => 'Sleeping';

  @override
  String glanceSince(String time, String name) {
    return 'Since $time · $name';
  }

  @override
  String get glanceWake => 'Wake up';

  @override
  String get glanceJustWoke => 'Just woke up';

  @override
  String glanceSlept(String t) {
    return 'Slept $t';
  }

  @override
  String get glanceEmptyTitle => 'Nothing logged today';

  @override
  String get glanceEmptySub => 'Log the first feed';

  @override
  String get glanceQuickLog => '+ Quick log';

  @override
  String get glanceSignedOutTitle => 'Sign in to use the widget';

  @override
  String get glanceOpenApp => 'Open the app';

  @override
  String get glanceOpenChildLife => 'Open Child Life';

  @override
  String glanceSummary(String feeds, String sleep) {
    return 'Feeds $feeds · sleep $sleep today';
  }

  @override
  String glancePending(String n) {
    return 'Not synced · $n waiting';
  }

  @override
  String get glanceRecent => 'Recent';

  @override
  String glanceTotals(
    String bottles,
    String ml,
    String breasts,
    String diapers,
  ) {
    return 'Today: bottles $bottles ($ml ml) · breastfeeds $breasts · diapers $diapers';
  }

  @override
  String get glanceNoneYet => 'None yet';

  @override
  String glanceFedFor(String t, String name) {
    return 'Fed $t · $name logged';
  }

  @override
  String glanceAgoFor(String t) {
    return 'ago · $t';
  }

  @override
  String glanceAgoKind(String kind) {
    return 'ago · $kind';
  }

  @override
  String glanceAwakeShort(String t) {
    return 'awake $t';
  }

  @override
  String glanceSleptToday(String t) {
    return 'slept $t today';
  }

  @override
  String glanceLockFeeds(String feed, String diaper) {
    return 'Fed $feed · Diaper $diaper';
  }

  @override
  String glanceLockSleep(String awake, String slept) {
    return 'Awake $awake · slept $slept';
  }

  @override
  String glanceInlineFed(String name, String t) {
    return '$name fed $t ago';
  }

  @override
  String get glanceFamilySees => 'The whole family sees this';

  @override
  String glanceSleepingTitle(String name) {
    return '$name is sleeping';
  }

  @override
  String get glanceEditTime => 'Edit start time';

  @override
  String get glanceEditTimeShort => 'Edit time';

  @override
  String glanceBreastTitle(String side) {
    return 'Breastfeeding · $side';
  }

  @override
  String get glanceEndFeed => 'End';

  @override
  String get glancePaused => 'Paused';

  @override
  String glanceDurM(String m) {
    return '$m min';
  }

  @override
  String glanceDurH(String h) {
    return '$h h';
  }

  @override
  String glanceDurHm(String h, String m) {
    return '$h h $m min';
  }

  @override
  String glanceDurSM(String m) {
    return '${m}m';
  }

  @override
  String glanceDurSH(String h) {
    return '${h}h';
  }

  @override
  String glanceDurSHm(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String get glanceGalleryBottleName => 'Bottle';

  @override
  String get glanceGalleryBottleBlurb =>
      'Log the last bottle again with one tap.';

  @override
  String get glanceGalleryBreastName => 'Breastfeeding';

  @override
  String get glanceGalleryBreastBlurb => 'Start, switch sides and end a feed.';

  @override
  String get glanceGallerySleepName => 'Sleep';

  @override
  String get glanceGallerySleepBlurb =>
      'Start sleep and wake up right from the Home Screen.';

  @override
  String get glanceGalleryDiaperName => 'Diaper';

  @override
  String get glanceGalleryDiaperBlurb => 'Wet, dirty or both — one tap.';

  @override
  String get glanceGalleryQuickName => 'Quick log';

  @override
  String get glanceGalleryQuickBlurb =>
      'Bottle, breastfeeding, sleep, diaper — one tap.';

  @override
  String get glanceGalleryTodayName => 'Today';

  @override
  String get glanceGalleryTodayBlurb =>
      'Sleep, quick log and the 3 latest entries.';

  @override
  String get glanceGalleryLockName => 'Child Life';

  @override
  String get glanceGalleryLockBlurb =>
      'Feeds, diapers and sleep on the Lock Screen.';

  @override
  String get glanceGalleryLockSleepName => 'Sleep';

  @override
  String get glanceGalleryLockSleepBlurb =>
      'How long asleep, or how long awake.';

  @override
  String get glanceGalleryLockFeedName => 'Last feed';

  @override
  String get glanceGalleryLockFeedBlurb => 'Time since the last feed.';

  @override
  String glanceUploadTitle(String name) {
    return '$name’s memories';
  }

  @override
  String get glanceUploadTitlePlain => 'Memories';

  @override
  String glanceUploadProgress(String done, String total) {
    return 'Uploading $done of $total';
  }

  @override
  String get glanceUploadNotify => 'We’ll let you know when it’s done';

  @override
  String glanceUploadWaiting(String n) {
    return 'Videos waiting for Wi‑Fi: $n';
  }

  @override
  String get glanceUploadDoneOne => 'Uploaded 1 item';

  @override
  String glanceUploadDone(String n) {
    return 'Uploaded $n items';
  }

  @override
  String get glanceUploadDoneBody => 'Your photos and videos are in Memories.';

  @override
  String get glanceUploadFailedOne => '1 item couldn’t upload';

  @override
  String glanceUploadFailed(String n) {
    return '$n items couldn’t upload';
  }

  @override
  String get glanceUploadFailedBody => 'Open Child Life to try again.';

  @override
  String get glanceUploadWifiOne => '1 video is waiting for Wi‑Fi';

  @override
  String glanceUploadWifi(String n) {
    return '$n videos are waiting for Wi‑Fi';
  }

  @override
  String get glanceUploadWifiBody =>
      'Photos are still uploading. Videos will upload on Wi‑Fi.';

  @override
  String get meLanguage => 'Language';

  @override
  String get meLanguageDevice => 'Same as phone';

  @override
  String meLanguageDeviceNow(String name) {
    return 'Now $name';
  }

  @override
  String get meLanguageVi => 'Tiếng Việt';

  @override
  String get meLanguageEn => 'English';

  @override
  String get meLanguageHint =>
      'Changes the whole app, widgets and notices on this phone right away.';

  @override
  String get whoIntro =>
      'From the WHO child growth standards. Every baby grows at their own pace.';

  @override
  String get whoBoy => 'Boy';

  @override
  String get whoGirl => 'Girl';

  @override
  String get whoByWeek => 'By week';

  @override
  String get whoByMonth => 'By month';

  @override
  String get whoAge => 'Age';

  @override
  String get whoLow => 'Low';

  @override
  String get whoMedian => 'Median';

  @override
  String get whoHigh => 'High';

  @override
  String get whoBirth => 'Birth';

  @override
  String whoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String whoMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get whoUnitKg =>
      'Unit: kg. “Low” and “High” are the lower and upper edges of the normal range.';

  @override
  String get whoUnitCm =>
      'Unit: cm. “Low” and “High” are the lower and upper edges of the normal range.';

  @override
  String get whoDoctor =>
      'If your baby’s measurement is outside the normal range, talk to their doctor.';

  @override
  String get whoSource =>
      'Source: WHO Child Growth Standards · Child Life update 09/2026';

  @override
  String whoBabyAt(String name, String value, String status) {
    return '$name $value · $status';
  }

  @override
  String get whoNormal => 'Normal';

  @override
  String get whoBelow => 'Below the reference';

  @override
  String get whoAbove => 'Above the reference';

  @override
  String get whoOpen => 'See the WHO growth standards';

  @override
  String get whoBand => 'Normal range';

  @override
  String get whoMedianLine => 'WHO median';

  @override
  String get feedsPerDayTitle => 'Feeds per day';

  @override
  String feedsPerDayHint(int days) {
    return 'Bottle and breast feeds · $days days';
  }

  @override
  String feedsDayTip(
    String day,
    int bottles,
    int ml,
    int breasts,
    int minutes,
  ) {
    return '$day · $bottles bottle $ml ml · $breasts breast ${minutes}m';
  }

  @override
  String feedsAvgLine(int count) {
    return 'Avg $count';
  }

  @override
  String bottleShareLine(int pct, int ml) {
    return 'Bottle $pct% · $ml ml/day';
  }

  @override
  String breastShareLine(int pct, int minutes) {
    return 'Breast $pct% · $minutes min/day';
  }

  @override
  String get kpiFeedsPerDay => 'Avg per day';

  @override
  String get kpiBottlePerDay => 'Bottle/day';

  @override
  String get kpiBreastPerDay => 'Breast/day';

  @override
  String get sleepPerDayTitle => 'Total sleep per day';

  @override
  String get sleepPerDayHint => 'Night 18:00–06:00 · Day 06:00–18:00';

  @override
  String sleepDayTip(String day, String total, String night, String daytime) {
    return '$day · $total · night $night · day $daytime';
  }

  @override
  String sleepAvgLine(String total) {
    return 'Avg $total';
  }

  @override
  String get legendNightSleep => 'Night sleep';

  @override
  String get legendDaySleep => 'Day sleep';

  @override
  String sleepSteadyInsight(int hours, int days) {
    return 'Total sleep has stayed around $hours h a day over the last $days days.';
  }

  @override
  String sleepRangeInsight(String min, String max, int days) {
    return 'Total sleep ran from $min to $max a day over the last $days days.';
  }

  @override
  String get whoStandardsTitle => 'Growth standards';

  @override
  String whoLowerEdge(String value) {
    return 'Lower edge $value';
  }

  @override
  String whoUpperEdge(String value) {
    return 'Upper edge $value';
  }

  @override
  String whoBelowWeightNote(String name) {
    return '$name’s weight is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String whoBelowLengthNote(String name) {
    return '$name’s length is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String whoAboveWeightNote(String name) {
    return '$name’s weight is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String whoAboveLengthNote(String name) {
    return '$name’s length is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String get amountFromLast => 'Amount · filled in from last time';

  @override
  String lastBottleAt(int ml, String time) {
    return 'Last time $ml ml · $time';
  }

  @override
  String bottleSuggestFor(String age) {
    return 'Suggested for $age';
  }

  @override
  String get bottleSuggestNewborn => 'Suggested for a newborn';

  @override
  String bottleQuickPick(int ml) {
    return '$ml ml';
  }

  @override
  String get feedKindTitle => 'Feed type';

  @override
  String get feedKindAll => 'All';

  @override
  String get feedKindAllHint => 'Bottle and breast';

  @override
  String get feedKindBottleHint => 'By milk volume (ml)';

  @override
  String get feedKindBreastHint => 'By feeding time (minutes)';

  @override
  String get rangeTitle => 'Time range';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get rangeCustomHint => 'Choose from – to date';

  @override
  String rangeSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String get kpiPerFeed => 'Avg per feed';

  @override
  String get milkPerDayTitle => 'Milk per day';

  @override
  String milkPerDayHint(int days) {
    return 'Total bottle ml · $days days';
  }

  @override
  String milkDayTip(String day, int ml, int count) {
    return '$day · $ml ml · $count feeds';
  }

  @override
  String mlAvgLine(int ml) {
    return 'Avg $ml ml';
  }

  @override
  String get legendExpressedMilk => 'Expressed milk';

  @override
  String get legendFormula => 'Formula';

  @override
  String get breastPerDayTitle => 'Breastfeeding time per day';

  @override
  String get breastPerDayHint => 'Total minutes · left and right';

  @override
  String breastDayTip(String day, int minutes, int count) {
    return '$day · $minutes min · $count feeds';
  }

  @override
  String minutesAvgLine(int minutes) {
    return 'Avg $minutes min';
  }

  @override
  String get legendLeftSide => 'Left';

  @override
  String get legendRightSide => 'Right';

  @override
  String get breastByTimeNote =>
      'Breast milk is hard to measure, so the app counts breastfeeding by time.';

  @override
  String minutesAndFeeds(int minutes, int count) {
    return '$minutes min · $count feeds';
  }

  @override
  String lastNightBreastInsight(int count, int minutes, String time) {
    return 'Last night: $count breastfeeds, $minutes min ($time).';
  }

  @override
  String get tabCare => 'Care';

  @override
  String get a11yOpenMe => 'Me';

  @override
  String get careTitle => 'Care';

  @override
  String get careSearchHint => 'Search in Care…';

  @override
  String get careDaily => 'Daily care';

  @override
  String get careReminders => 'Reminders';

  @override
  String careRemindersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders on',
      one: '1 reminder on',
    );
    return '$_temp0';
  }

  @override
  String careRemindersMine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders for you',
      one: '1 reminder for you',
    );
    return '$_temp0';
  }

  @override
  String get careStats => 'Statistics';

  @override
  String get careStatsSub => 'Feeding, sleep by day';

  @override
  String get careHistory => 'History';

  @override
  String get careHistorySub => 'Every logged entry';

  @override
  String get careGrowth => 'Growth';

  @override
  String get careGrowthSub => 'Weight, length';

  @override
  String get careSoon => 'Coming soon';

  @override
  String get careSoonToast => 'This arrives in a coming update.';

  @override
  String get careWonderWeek => 'Wonder Week';

  @override
  String get careWonderWeekSub => 'Expected developmental phases';

  @override
  String get careAgeCards => 'Cards by age';

  @override
  String get careAgeCardsSub => 'Ideas for your baby’s age';

  @override
  String get careMilestones => 'Milestones';

  @override
  String get careMilestonesSub => 'Record your child’s firsts';

  @override
  String get careLibrary => 'Baby-care library';

  @override
  String get careLibrarySub => 'Expert-reviewed articles';

  @override
  String get careSolids => 'Solids';

  @override
  String get careSolidsSub => 'Solids diary & library';

  @override
  String get careStatsPick => 'See statistics';

  @override
  String get careNoResults => 'Nothing matches.';

  @override
  String get todayCustomize => 'Customise';

  @override
  String get customizeTitle => 'Customise Today';

  @override
  String get customizeIntro =>
      'Turn on, turn off and drag to arrange what shows on Today.';

  @override
  String get sectionTiles => 'Quick tracking tiles';

  @override
  String get sectionTilesSub => 'Feeding, sleep, diapers, pumping, growth';

  @override
  String get sectionReminders => 'Upcoming reminders';

  @override
  String get sectionRhythm => 'Daily rhythm';

  @override
  String get sectionRhythmSub => '24-hour chart';

  @override
  String get visibleTiles => 'Visible tracking tiles';

  @override
  String get customizeReset => 'Reset';

  @override
  String get customizeDone => 'Done';

  @override
  String get a11yDragToReorder => 'Drag to reorder';

  @override
  String get welcomeBody =>
      'Care for, understand and keep your child’s journey — starting with the first year.';

  @override
  String get journeyFeed => 'Bottle · 120 ml';

  @override
  String get journeyFeedWho => 'Mum logged · 2 min ago';

  @override
  String get journeySmile => 'First smile';

  @override
  String get journeySmileSaved => 'Saved to Memories';

  @override
  String get journeyLove => 'Grandma loved Teddy’s photo';

  @override
  String get journeyStage1 => '0–12 months';

  @override
  String get journeyStage2 => '1–3 years';

  @override
  String get journeyStage3 => '3–6 years';

  @override
  String get journeyStage4 => '6–12 years';

  @override
  String get a11yJourney =>
      'Your child’s growing-up journey, from the first year to 12';

  @override
  String get welcomeBackTitle => 'Welcome back';

  @override
  String get welcomeBackBody =>
      'Sign in to continue the journey with your child.';

  @override
  String get ruleTabRules => 'Rule-based';

  @override
  String get ruleTabOnce => 'One-time';

  @override
  String get ruleTitleFeed => 'Feeding reminder';

  @override
  String get ruleTitleSleep => 'Sleep reminder';

  @override
  String get ruleTitleDiaper => 'Diaper reminder';

  @override
  String get ruleTitlePump => 'Pumping reminder';

  @override
  String ruleAfterFeed(String duration) {
    return '$duration after the latest feed';
  }

  @override
  String ruleAfterSleep(String duration) {
    return '$duration after waking up';
  }

  @override
  String ruleAfterDiaper(String duration) {
    return '$duration after the latest change';
  }

  @override
  String ruleAfterPump(String duration) {
    return '$duration after the latest pump';
  }

  @override
  String ruleFixedLine(String times) {
    return 'Fixed $times';
  }

  @override
  String ruleNext(String when) {
    return 'Next $when';
  }

  @override
  String get rulePaused => 'Paused';

  @override
  String ruleDueNow(String time) {
    return 'Due · $time';
  }

  @override
  String ruleSnoozedUntil(String time) {
    return 'Again at $time';
  }

  @override
  String get ruleWaiting => 'Waits for the next log';

  @override
  String ruleRecipientsLine(String names) {
    return 'Recipients: $names';
  }

  @override
  String get ruleYou => 'you';

  @override
  String get ruleAdd => 'Add reminder';

  @override
  String get ruleEmpty => 'No rule-based reminders yet';

  @override
  String get ruleEmptyBody =>
      'For example: a feeding reminder 3 hours after the latest feed, for the whole family.';

  @override
  String get ruleCaregiverNote =>
      'Parents set reminders; you get the ones assigned to you.';

  @override
  String get ruleActFeed => 'a feed';

  @override
  String get ruleActSleep => 'a sleep';

  @override
  String get ruleActDiaper => 'a diaper change';

  @override
  String get ruleActPump => 'a pump';

  @override
  String ruleHandled(String who, String activity, String time, String next) {
    return '$who logged $activity at $time · next reminder $next';
  }

  @override
  String ruleHandledNoNext(String who, String activity, String time) {
    return '$who logged $activity at $time';
  }

  @override
  String get ruleNewTitle => 'New reminder';

  @override
  String get ruleEditTitle => 'Edit reminder';

  @override
  String get ruleWhat => 'What should we remind you about?';

  @override
  String get ruleTypeFeed => 'Feeding';

  @override
  String get ruleTypeSleep => 'Sleep';

  @override
  String get ruleTypeDiaper => 'Diaper change';

  @override
  String get ruleTypePump => 'Pumping';

  @override
  String get ruleHow => 'How to remind';

  @override
  String get ruleModeAfter => 'After the latest log';

  @override
  String get ruleModeAfterHint => 'E.g. 3 hours after the latest feed';

  @override
  String get ruleModeFixed => 'Fixed times';

  @override
  String get ruleModeFixedHint => 'E.g. 09:00, 13:00, 19:30 every day';

  @override
  String get ruleContinue => 'Continue';

  @override
  String ruleStep(int step) {
    return 'Step $step of 3';
  }

  @override
  String get ruleEvery => 'Remind every';

  @override
  String get ruleCountedFeed =>
      'counted from the latest feed (bottle or breast)';

  @override
  String get ruleCountedSleep => 'counted from when your baby wakes up';

  @override
  String get ruleCountedDiaper => 'counted from the latest diaper change';

  @override
  String get ruleCountedPump => 'counted from the latest pump';

  @override
  String get ruleExample => 'Example today';

  @override
  String get ruleExFeed => 'Fed';

  @override
  String get ruleExSleep => 'Woke';

  @override
  String get ruleExDiaper => 'Changed';

  @override
  String get ruleExPump => 'Pumped';

  @override
  String ruleExampleLine(String act, String from, String to) {
    return '$act at $from → reminder at $to';
  }

  @override
  String get ruleExampleNone =>
      'Nothing logged yet: it starts after the first log.';

  @override
  String ruleExampleShift(String activity) {
    return 'Log $activity and the reminder moves with it.';
  }

  @override
  String get ruleQuiet => 'No reminders at night';

  @override
  String get ruleQuietRange => '22:00 – 06:00';

  @override
  String get ruleDays => 'Days';

  @override
  String get ruleEveryDay => 'Every day';

  @override
  String get ruleTimesTitle => 'Times each day';

  @override
  String get ruleSlotMorningNap => 'Morning nap';

  @override
  String get ruleSlotMiddayNap => 'Midday nap';

  @override
  String get ruleSlotAfternoonNap => 'Afternoon nap';

  @override
  String get ruleSlotNightSleep => 'Night sleep';

  @override
  String get ruleSlotMorning => 'Morning';

  @override
  String get ruleSlotMidday => 'Midday';

  @override
  String get ruleSlotAfternoon => 'Afternoon';

  @override
  String get ruleSlotEvening => 'Evening';

  @override
  String get ruleAddTime => 'Add time';

  @override
  String ruleRemoveTime(String time) {
    return 'Remove $time';
  }

  @override
  String get ruleTimeExists => 'That time is already on the list.';

  @override
  String get ruleWeek => 'Days of the week';

  @override
  String ruleZoneNote(String zone) {
    return 'Reminders follow your baby’s time ($zone). When you travel, they stay on the time where your baby lives.';
  }

  @override
  String get ruleWho => 'Who gets the reminder?';

  @override
  String get ruleRoleParent => 'Parent';

  @override
  String get ruleRoleCaregiver => 'Caregiver';

  @override
  String get ruleRoleViewOnly => 'Family · view only';

  @override
  String get ruleWhoNote =>
      'Only parents and caregivers can get reminders. Whoever logs the activity first turns it off for everyone.';

  @override
  String get ruleAllDay => 'all day';

  @override
  String get ruleNotAtNight => 'not at night';

  @override
  String ruleRecipients(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipients',
      one: '1 recipient',
    );
    return '$_temp0';
  }

  @override
  String get ruleSave => 'Save reminder';

  @override
  String get ruleNeedRecipient => 'Choose at least one person.';

  @override
  String get ruleSavedFeed => 'Feeding reminder saved';

  @override
  String get ruleSavedSleep => 'Sleep reminder saved';

  @override
  String get ruleSavedDiaper => 'Diaper reminder saved';

  @override
  String get ruleSavedPump => 'Pumping reminder saved';

  @override
  String get ruleSaveFailed =>
      'Couldn’t save. Check your connection and try again.';

  @override
  String get ruleDueFeed => 'Time for the feeding reminder you set';

  @override
  String get ruleDueSleep => 'Time for the sleep reminder you set';

  @override
  String get ruleDueDiaper => 'Time for the diaper reminder you set';

  @override
  String get ruleDuePump => 'Time for the pumping reminder you set';

  @override
  String get ruleLastFeed => 'Last feed';

  @override
  String get ruleLastSleep => 'Woke at';

  @override
  String get ruleLastDiaper => 'Last change';

  @override
  String get ruleLastPump => 'Last pump';

  @override
  String get ruleLogFeed => 'Log a feed';

  @override
  String get ruleLogSleep => 'Log sleep';

  @override
  String get ruleLogDiaper => 'Log a change';

  @override
  String get ruleLogPump => 'Log pumping';

  @override
  String get ruleSnoozeIn => 'Remind again in';

  @override
  String get ruleSkip => 'Skip this time';

  @override
  String get ruleAlreadyHandled => 'Someone already took care of this.';

  @override
  String ruleSnoozedToast(String time) {
    return 'We’ll remind you again at $time';
  }

  @override
  String get ruleSkippedToast => 'Skipped this time';

  @override
  String get ruleRecent => 'Recent';

  @override
  String get ruleRecentEmpty => 'Nothing has rung yet.';

  @override
  String ruleOutLogged(String time) {
    return '$time · Logged';
  }

  @override
  String ruleOutSnoozed(String time, int minutes) {
    return '$time · Snoozed $minutes min';
  }

  @override
  String ruleOutSkipped(String time) {
    return '$time · Skipped';
  }

  @override
  String ruleOutMissed(String time) {
    return '$time · Nobody answered';
  }

  @override
  String ruleOutLoggedBy(String who, String what) {
    return '$who logged $what';
  }

  @override
  String get ruleEdit => 'Edit reminder';

  @override
  String get ruleDelete => 'Delete reminder';

  @override
  String ruleDeleteTitle(String title) {
    return 'Delete $title?';
  }

  @override
  String get ruleDeleteBody => 'Everyone stops getting it.';

  @override
  String get ruleDeleteConfirm => 'Delete';

  @override
  String get ruleDeleted => 'Reminder deleted';

  @override
  String get reminderPeekTitle => 'Reminders';

  @override
  String get photoByTitle => 'View photos by';

  @override
  String get photoByWeek => 'Week of age';

  @override
  String get photoByWeekSub => 'Week 1, week 2… suits the first year';

  @override
  String get photoByAgeMonth => 'Month of age';

  @override
  String get photoByAgeMonthSub => '1 month, 2 months…';

  @override
  String get photoByMonth => 'Calendar month';

  @override
  String get photoByMonthSub => 'October, September…';

  @override
  String get photoPillWeek => 'By week of age';

  @override
  String get photoPillAgeMonth => 'By month of age';

  @override
  String get photoPillMonth => 'By month';

  @override
  String get photoShowTitle => 'Show';

  @override
  String get photoShowAll => 'Photos & videos';

  @override
  String get photoShowPhotos => 'Photos only';

  @override
  String get photoShowVideos => 'Videos only';

  @override
  String get photoShowFavorites => 'Favourites';

  @override
  String get photoGotoWeek => 'Go to week';

  @override
  String get photoGotoAgeMonth => 'Go to month of age';

  @override
  String photoAgeMonth(int month) {
    return 'Month $month';
  }

  @override
  String photoScrubWeek(int week) {
    return 'Week $week';
  }

  @override
  String photoScrubAgeMonth(int month) {
    return 'Month $month';
  }

  @override
  String get photoSelectSection => 'Select all';

  @override
  String get glanceGalleryCameraName => 'Baby camera';

  @override
  String get glanceGalleryCameraBlurb =>
      'Open the camera for a photo or a video, then save it to Memories.';

  @override
  String get glanceGalleryLibraryName => 'Add from Photos';

  @override
  String get glanceGalleryLibraryBlurb =>
      'Pick photos and videos on this phone to save to Memories.';

  @override
  String get glanceMemCamera => 'Take a photo or video';

  @override
  String get glanceMemLibrary => 'Add from Photos';

  @override
  String glanceMemFor(String name) {
    return 'To $name’s memories';
  }
}
