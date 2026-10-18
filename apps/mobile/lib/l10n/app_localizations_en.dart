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
  String get a11yWorking => 'Working on it';

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
  String get signInAppleElsewhere => 'Signed up with Apple on an iPhone?';

  @override
  String get signInAppleElsewhereAction =>
      'Get a sign-in link at your Apple email';

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
  String get babyCountry => 'Country';

  @override
  String get babyCountryUnset => 'Choose';

  @override
  String get babyCountryRequired =>
      'Choose where your family lives so First aid calls the right emergency number.';

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
  String get reminderAllDay => 'All day';

  @override
  String get reminderAllDayLower => 'all day';

  @override
  String get reminderDay => 'Date';

  @override
  String get reminderAllDayAt => 'Notify at';

  @override
  String get reminderAllDayTimeTitle => 'All-day reminder time';

  @override
  String reminderAllDayTimeNote(String name) {
    return 'Applies to every all-day reminder on this device, in $name’s time.';
  }

  @override
  String get leadOnDay => 'On the day';

  @override
  String get reminderAssignee => 'Assigned to';

  @override
  String get reminderAssignNone => 'No one';

  @override
  String get reminderAssignNobody => 'Don’t assign';

  @override
  String get reminderAssignPickerNote =>
      'The assignee gets the notification on their own phone once they open the app. Only co-parents and caregivers can be assigned.';

  @override
  String get reminderAssignedToYou => 'Assigned to you';

  @override
  String reminderAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get reminderNotifyMine => 'Your devices';

  @override
  String reminderNotifyAssignee(String name) {
    return '$name’s devices';
  }

  @override
  String reminderFootnoteAssigned(String name, String zone, String who) {
    return 'In $name’s time ($zone). The family sees reminders in the app. $who gets the notification on their own phone once they open the app.';
  }

  @override
  String get reminderDetailNoteAssigned =>
      'The assignee is notified on their own phone once they open the app. Mark it done when it’s done.';

  @override
  String get reminderPastDay => 'Pick today or a later day.';

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
  String get reminderPeekMore => 'See all';

  @override
  String notifBody(String name, String when) {
    return '$name · $when';
  }

  @override
  String get notifChannel => 'Reminders';

  @override
  String get notifChannelDescription => 'Family reminders';

  @override
  String get notifChannelFamily => 'Family & memories';

  @override
  String get notifChannelFamilyDescription =>
      'New photos, messages and news from the family';

  @override
  String get notifChannelSpending => 'Spending';

  @override
  String get notifChannelSpendingDescription =>
      'Recurring expenses and the monthly budget';

  @override
  String get notifSnooze15 => 'Remind me in 15 minutes';

  @override
  String get notifVxView => 'View the schedule';

  @override
  String get notifVxSnooze => 'Remind me in the morning';

  @override
  String get notifChannelTimers => 'Timers';

  @override
  String get notifChannelTimersDescription => 'Sleep and feeds in progress';

  @override
  String get notifChannelUploads => 'Uploads';

  @override
  String get notifChannelUploadsDescription =>
      'Photo and video upload progress, and when it is done';

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
  String get addCameraPhoto => 'Take a photo';

  @override
  String get addCameraVideo => 'Record a video';

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
  String get actMakeCard => 'Make a milestone card';

  @override
  String get actMakeCardHint => 'Uses up to 4 of the chosen photos';

  @override
  String get actMakeVideo => 'Make a memory video';

  @override
  String get actMakeVideoHint => 'The chosen photos fill the scenes';

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
  String get acStaffTransferTitle =>
      'Child Life Support suggests transferring profile ownership';

  @override
  String acStaffTransferBody(String to, String time) {
    return 'To $to. Agree within 48 hours (by $time); otherwise the request cancels itself. If you agree, $to gets the usual invitation to become the profile owner.';
  }

  @override
  String acStaffTransferBodyTicket(String to, String ticket, String time) {
    return 'To $to · ticket $ticket. Agree within 48 hours (by $time); otherwise the request cancels itself. If you agree, $to gets the usual invitation to become the profile owner.';
  }

  @override
  String get acStaffTransferAgree => 'Agree';

  @override
  String get acStaffTransferDecline => 'Decline';

  @override
  String get acStaffTransferConfirmTitle => 'Agree to transfer ownership?';

  @override
  String acStaffTransferConfirmBody(String to) {
    return '$to will get the invitation to become the profile owner. Nothing changes until they accept; until then you can cancel the offer under Profile owner.';
  }

  @override
  String acStaffTransferAgreed(String to) {
    return 'Agreed · $to will get the invitation';
  }

  @override
  String get acStaffTransferDeclined => 'Transfer request declined';

  @override
  String get acStaffTransferGone =>
      'This request has expired or was already answered.';

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
  String get careWonderWeek => 'Wonder Weeks';

  @override
  String get careWonderWeekSub => 'Expected developmental phases';

  @override
  String get careAgeCards => 'Your baby’s stages';

  @override
  String get careAgeCardsSub => 'Ideas week by week, month by month';

  @override
  String get careMilestones => 'Milestones';

  @override
  String get careMilestonesSub => 'Record your child’s firsts';

  @override
  String get careLibrary => 'Baby-care library';

  @override
  String get careLibrarySub => 'Baby-care articles by age';

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
      'Turn a part on and pick what it shows right below it. Drag the handle on the left, or press and hold a row, to reorder.';

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
  String get customizeReset => 'Reset to default';

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

  @override
  String get vxTile => 'Vaccinations';

  @override
  String vxTileNext(String date) {
    return 'Next shot $date';
  }

  @override
  String vxTileOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shots overdue',
      one: '1 shot overdue',
    );
    return '$_temp0';
  }

  @override
  String get vxTileAllDone => 'All shots done';

  @override
  String get vxTileSetup => 'Log the shots given';

  @override
  String get vxTitle => 'Vaccinations';

  @override
  String vxNextLine(String date, String left) {
    return 'Next shot · $date · $left';
  }

  @override
  String vxDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get vxDueToday => 'today';

  @override
  String vxOverdueLine(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Overdue by $count days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0 · planned $date';
  }

  @override
  String vxDoseSuffix(int n) {
    return '(dose $n)';
  }

  @override
  String vxDoseOf(String name, int n) {
    return '$name dose $n';
  }

  @override
  String get vxViewByVaccine => 'By vaccine';

  @override
  String get vxViewByAge => 'By month of age';

  @override
  String vxCount(int given, int total) {
    return '$given / $total shots given';
  }

  @override
  String get vxLegendGiven => 'Given';

  @override
  String get vxLegendUpcoming => 'Upcoming';

  @override
  String get vxLegendOverdue => 'Overdue';

  @override
  String get vxLegendLater => 'Not yet';

  @override
  String get vxLegendDeclined => 'Not given';

  @override
  String vxMonthsShort(int months) {
    return '$months mo';
  }

  @override
  String get vxBirth => 'Newborn';

  @override
  String vxMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String vxMonthsOld(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months old',
      one: '1 month old',
    );
    return '$_temp0';
  }

  @override
  String get vxMilestoneBirth => 'Newborn';

  @override
  String vxMilestone(int months) {
    return '$months-month milestone';
  }

  @override
  String vxMilestoneShort(int months) {
    return '$months-month';
  }

  @override
  String vxHintMonths(String list) {
    return '$list months';
  }

  @override
  String get vxHintYearly => 'yearly';

  @override
  String get vxBannerMatrix =>
      'Tap a shot to log it or see details. A reference schedule; it may change on the doctor’s advice.';

  @override
  String get vxBannerTimeline =>
      'Tick a box once the shot is given — the app asks the date and place. A reference schedule; it may change on the doctor’s advice.';

  @override
  String vxOverdueCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shots are',
      one: '1 shot is',
    );
    return '$_temp0 past the planned date. If given, tick to update; if not, rebook with the clinic.';
  }

  @override
  String vxNoDob(String name) {
    return '$name’s date of birth is needed for the schedule.';
  }

  @override
  String get vxNoDobBody => 'Parents add it in the baby profile.';

  @override
  String get vxViewTitle => 'View the schedule by';

  @override
  String get vxViewByVaccineSub =>
      'One line per vaccine; see what is missing at a glance';

  @override
  String get vxViewByAgeSub => 'What each age needs; tick when given';

  @override
  String get vxNoDate => 'No date';

  @override
  String vxSetupTitle(String name) {
    return 'Which shots has $name had?';
  }

  @override
  String get vxSetupBody =>
      'Tick the shots given since birth. No need to remember the dates — you can add them later.';

  @override
  String get vxSetupAtHospital => 'Newborn · usually at the hospital';

  @override
  String get vxSetupFirstDay => 'Within the first 24 hours';

  @override
  String vxSetupDue(String age, String date) {
    return '$age · planned $date';
  }

  @override
  String vxSetupSave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count shots',
      one: 'Save 1 shot',
    );
    return '$_temp0';
  }

  @override
  String get vxSetupContinue => 'Continue';

  @override
  String get vxSetupSkip => 'Skip for now';

  @override
  String vxPlannedLeft(String date, String left) {
    return 'Planned $date · $left';
  }

  @override
  String vxPlannedOverdue(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Planned $date · $_temp0 overdue';
  }

  @override
  String get vxChooseOne => 'Choose one';

  @override
  String get vx6in1Title => '6-in-1 · Private clinic';

  @override
  String get vx6in1Body =>
      'Diphtheria, whooping cough, tetanus, polio, Hib, hepatitis B — one shot';

  @override
  String get vxPaid => 'Paid';

  @override
  String get vx5in1Title => '5-in-1 + Polio · Health station';

  @override
  String get vx5in1Body => 'Free programme; polio given separately';

  @override
  String get vxFree => 'Free';

  @override
  String get vxShots => 'Shots';

  @override
  String get vxOtherShots => 'Other shots';

  @override
  String get vxLog => 'Log';

  @override
  String get vxRouteOral => 'Oral';

  @override
  String get vxRouteInjection => 'Injection';

  @override
  String get vxProgEpi => 'Free programme';

  @override
  String get vxProgService => 'Private clinic';

  @override
  String get vxProgHospital => 'Hospital';

  @override
  String get vxProgChoice => '6-in-1 private or 5-in-1 free';

  @override
  String get vxProgNational => 'National programme';

  @override
  String get vxProgRecommended => 'Recommended, may be paid';

  @override
  String vxCountryNotice(String programme, String date) {
    return 'Follows the $programme, checked $date. Your child\'s plan may differ by doctor or region.';
  }

  @override
  String get vxRemind => 'Remind 3 days before';

  @override
  String get vxRemindNobody => 'Nobody chosen';

  @override
  String get vxRecipientsTitle => 'Who gets the reminders?';

  @override
  String get vxAppointment => 'Set an appointment';

  @override
  String get vxAppointmentNone => 'No date set';

  @override
  String vxAppointmentOn(String date) {
    return 'Booked for $date';
  }

  @override
  String get vxAskDoctor =>
      'Ask a doctor or health worker which vaccine suits your baby.';

  @override
  String vxGivenOn(String date) {
    return 'Given $date';
  }

  @override
  String get vxRecordTitle => 'Log a shot';

  @override
  String get vxEditTitle => 'Edit the shot';

  @override
  String get vxDate => 'Date';

  @override
  String get vxTime => 'Time';

  @override
  String get vxTimeNone => 'Not set';

  @override
  String get vxPlace => 'Where';

  @override
  String get vxPlaceHospital => 'Hospital';

  @override
  String get vxPlaceService => 'Private clinic';

  @override
  String get vxPlaceStation => 'Health station';

  @override
  String get vxFacility => 'Clinic name (optional)';

  @override
  String get vxFacilityHint => 'e.g. The vaccination centre near home';

  @override
  String get vxReaction => 'Reaction after the shot (optional)';

  @override
  String get vxReactionHint => 'Mild fever, fussier…';

  @override
  String get vxSave => 'Save the shot';

  @override
  String vxSaved(String dose) {
    return 'Saved $dose';
  }

  @override
  String vxSavedNext(String dose, int n, String date) {
    return 'Saved $dose · dose $n planned $date';
  }

  @override
  String get vxSaveFailed => 'Couldn’t save. Please try again.';

  @override
  String vxQuickTitle(String dose) {
    return '$dose given';
  }

  @override
  String get vxWhichDay => 'Which day?';

  @override
  String get vxDayToday => 'Today';

  @override
  String get vxDayYesterday => 'Yesterday';

  @override
  String get vxPickDay => 'Pick a date';

  @override
  String get vxWhere => 'Where?';

  @override
  String get vxQuickSave => 'Save';

  @override
  String get vxMoreDetails => 'Add details (reaction, photo of the book)';

  @override
  String get vxRecordedBy => 'Logged by';

  @override
  String get vxReactionShort => 'Reaction';

  @override
  String vxNextDose(int n, String date) {
    return 'Dose $n planned $date';
  }

  @override
  String get vxReminderOn => 'reminder on';

  @override
  String get vxReminderOff => 'reminder off';

  @override
  String get vxDelete => 'Delete this shot';

  @override
  String vxDeleteTitle(String dose) {
    return 'Delete $dose?';
  }

  @override
  String get vxDeleteBody => 'The shot goes back to not given.';

  @override
  String get vxDeleteConfirm => 'Delete';

  @override
  String vxDeleted(String dose) {
    return 'Deleted $dose';
  }

  @override
  String get vxReason => 'Reason';

  @override
  String get vxUndoDecline => 'Undo “not given”';

  @override
  String get vxUndoReschedule => 'Cancel the appointment';

  @override
  String get vxAddDate => 'Add the date';

  @override
  String vxDoseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses',
      one: '1 dose',
    );
    return '$_temp0';
  }

  @override
  String vxDoseCountOral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses',
      one: '1 dose',
    );
    return '$_temp0';
  }

  @override
  String get vxDoses => 'Doses';

  @override
  String get vxDosesOral => 'Doses';

  @override
  String get vxTiming => 'Timing';

  @override
  String vxTimingValue(String list) {
    return '$list months old';
  }

  @override
  String get vxInterval => 'Interval';

  @override
  String vxIntervalValue(int weeks) {
    return 'At least $weeks weeks between doses';
  }

  @override
  String get vxRoute => 'How it’s given';

  @override
  String vxBabyDoses(String name) {
    return '$name’s doses';
  }

  @override
  String vxDoseN(int n) {
    return 'Dose $n';
  }

  @override
  String vxPlannedOn(String date) {
    return 'Planned $date';
  }

  @override
  String get vxInfoBanner =>
      'Reference information. Ask a doctor if you have any doubts.';

  @override
  String get vxAlreadyGiven => 'Already given';

  @override
  String get vxAlreadyGivenSub => 'Log the date and place';

  @override
  String get vxReschedule => 'Reschedule';

  @override
  String get vxRescheduleSub =>
      'Pick a new date; we’ll remind you the day before';

  @override
  String get vxDecline => 'Not giving this shot';

  @override
  String get vxDeclineSub =>
      'On the doctor’s advice · add a reason if you like';

  @override
  String get vxCatchUp =>
      'Ask the clinic or a doctor about a suitable catch-up schedule.';

  @override
  String vxDeclineTitle(String dose) {
    return 'Not giving $dose';
  }

  @override
  String get vxDeclineReasonHint => 'Reason (optional)';

  @override
  String vxDeclined(String dose) {
    return 'Marked $dose as not given';
  }

  @override
  String vxRescheduled(String dose, String date) {
    return 'Moved $dose to $date';
  }

  @override
  String get vxPickDateTitle => 'Pick a date';

  @override
  String get vxViewOnly => 'You can view the book only.';

  @override
  String get vxTileBook => 'The baby’s vaccination book';

  @override
  String get vxPhotoTake => 'Photograph the book / slip';

  @override
  String get vxPhotoBook => 'Photograph the book to keep it';

  @override
  String get vxPhoto => 'Photo of the book';

  @override
  String get vxBookPhotos => 'Photos of the vaccination book';

  @override
  String get vxPhotoAdd => 'Add a photo of the book';

  @override
  String get vxPhotoUploading => 'Uploading the photo…';

  @override
  String get vxPhotoFailed => 'Couldn’t upload the photo. Please try again.';

  @override
  String get vxPhotoRemove => 'Remove the photo';

  @override
  String get vxPhotoDelete => 'Delete the photo';

  @override
  String get vxPhotoDeleted => 'Photo deleted';

  @override
  String get vxPhotoPrivate =>
      'Only the family’s carers can see it. Never shown in Memories.';

  @override
  String get joinFromProfile => 'Enter an invite code';

  @override
  String get joinFromProfileHint =>
      'Invited to care for another baby? Enter the 6-digit code from the invite.';

  @override
  String get myInvitesTitle => 'Invites for you';

  @override
  String myInviteLine(String inviter, String baby) {
    return '$inviter invited you to care for $baby';
  }

  @override
  String myInviteMeta(String role, String date) {
    return '$role · Expires $date';
  }

  @override
  String get myInviteAccept => 'Accept';

  @override
  String get myInviteDecline => 'Decline';

  @override
  String myInviteDeclineTitle(String baby) {
    return 'Decline the invite for $baby?';
  }

  @override
  String myInviteDeclineBody(String inviter) {
    return '$inviter will see the invite is no longer waiting. The code and link will stop working.';
  }

  @override
  String myInviteDeclined(String baby) {
    return 'Declined the invite for $baby';
  }

  @override
  String get signInHaveCode => 'I have an invite code';

  @override
  String get familyRevokeTitle => 'Revoke this invite?';

  @override
  String familyRevokeBody(String who) {
    return 'The code and link sent to $who will stop working.';
  }

  @override
  String get myInvitesPending => 'Invites waiting for you';

  @override
  String get myInviteSheetTitle => 'Invite to care for a baby';

  @override
  String myInviteSheetHint(String baby) {
    return 'Once you accept, $baby joins your list of babies.';
  }

  @override
  String get spTitle => 'Spending';

  @override
  String spTileMonth(String amount) {
    return '$amount this month';
  }

  @override
  String get spTileEmpty => 'Nothing this month';

  @override
  String get spTileRecord => 'Record expenses';

  @override
  String spMillions(String value) {
    return '${value}M';
  }

  @override
  String get spCurrencyName => 'dong';

  @override
  String get spCurrency => 'Currency';

  @override
  String get spCurrencyTitle => 'Choose a currency';

  @override
  String spCurrencyPick(String code) {
    return 'Change currency, now $code';
  }

  @override
  String get spCurrencyMain => 'Main currency';

  @override
  String get spCurrencyMainSub =>
      'The default for new expenses; totals, statistics and the budget count this currency. Expenses in other currencies are shown apart, never converted.';

  @override
  String get spCurrencyMainSaved => 'Main currency changed';

  @override
  String spAlsoSpent(String amounts) {
    return 'Also: $amounts';
  }

  @override
  String spOtherCurrenciesNote(String amounts) {
    return 'Not added to the total (other currencies): $amounts';
  }

  @override
  String spBudgetCurrencyNote(String code) {
    return 'The budget counts expenses in $code.';
  }

  @override
  String spBudgetOldCurrency(String old, String code) {
    return 'The budget is kept in $old. Set the amounts again and save to count $code.';
  }

  @override
  String get spCurVND => 'Vietnamese dong';

  @override
  String get spCurUSD => 'US dollar';

  @override
  String get spCurEUR => 'Euro';

  @override
  String get spCurGBP => 'British pound';

  @override
  String get spCurAUD => 'Australian dollar';

  @override
  String get spCurCAD => 'Canadian dollar';

  @override
  String get spCurNZD => 'New Zealand dollar';

  @override
  String get spCurSGD => 'Singapore dollar';

  @override
  String get spCurJPY => 'Japanese yen';

  @override
  String get spCurKRW => 'South Korean won';

  @override
  String get spCurTWD => 'New Taiwan dollar';

  @override
  String get spCurTHB => 'Thai baht';

  @override
  String get spCurHKD => 'Hong Kong dollar';

  @override
  String get spCurCNY => 'Chinese yuan';

  @override
  String get spCurCHF => 'Swiss franc';

  @override
  String get spCurMYR => 'Malaysian ringgit';

  @override
  String get spCatChildcare => 'Childcare & learning';

  @override
  String get spCatMilk => 'Milk & solids';

  @override
  String get spCatDiaper => 'Diapers & hygiene';

  @override
  String get spCatHealth => 'Health & vaccines';

  @override
  String get spCatClothes => 'Clothes';

  @override
  String get spCatOther => 'Other';

  @override
  String get spToday => 'Today';

  @override
  String get spYesterday => 'Yesterday';

  @override
  String spDayToday(String date) {
    return 'Today · $date';
  }

  @override
  String spDayYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String spDateToday(String date) {
    return 'Today, $date';
  }

  @override
  String spDateYesterday(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get spPayerOther => 'Other';

  @override
  String spPaidBy(String payer) {
    return '$payer paid';
  }

  @override
  String spPays(String payer) {
    return '$payer pays';
  }

  @override
  String get spFromVaccines => 'from Vaccinations';

  @override
  String get spFromRecurring => 'recurring';

  @override
  String get spFromRecurringFull => 'Recurring item';

  @override
  String spScheduleMonthly(int day) {
    return 'Day $day of every month';
  }

  @override
  String spScheduleMonthlyTwo(int a, int b) {
    return 'Days $a and $b of every month';
  }

  @override
  String spScheduleWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String spScheduleYearly(String date) {
    return '$date every year';
  }

  @override
  String get spPending => 'Waiting to sync';

  @override
  String get spHasReceipt => 'Has receipt';

  @override
  String get spNoAccess =>
      'The baby\'s spending is for parents only. Ask a co-parent to give you access in Family if you need to record.';

  @override
  String spFirstTitle(String name) {
    return 'Record spending for $name';
  }

  @override
  String get spFirstBody =>
      'Know how much each month goes on milk, diapers, vaccinations and childcare. Only parents see it; you can share it with others.';

  @override
  String get spFirstBodyRecorder =>
      'Record what you have spent on the baby. You only see the items you recorded.';

  @override
  String get spFirstPoint1 => 'Record in a few seconds';

  @override
  String get spFirstPoint2 => 'Statistics by month, category and payer';

  @override
  String get spFirstPoint3 => 'Budget and recurring items';

  @override
  String get spFirstAdd => 'Add the first expense';

  @override
  String get spFirstBudget => 'Set a budget';

  @override
  String get spAdd => 'Add expense';

  @override
  String get spOwnOnlyNote =>
      'You only see the items you recorded, not totals or other people\'s items.';

  @override
  String get spMine => 'Items you recorded';

  @override
  String get spPrevMonth => 'Previous month';

  @override
  String get spNextMonth => 'Next month';

  @override
  String spMonthLabel(int month, int year) {
    return '$month/$year';
  }

  @override
  String spMonthShort(int month, int year) {
    return 'Month $month';
  }

  @override
  String spUpTo(String date) {
    return 'Up to $date';
  }

  @override
  String spSpentOn(String name) {
    return 'Spent on $name';
  }

  @override
  String get spStats => 'Statistics';

  @override
  String get spBudget => 'Budget';

  @override
  String get spRecurring => 'Recurring';

  @override
  String get spByCategory => 'By category';

  @override
  String get spSeeStats => 'See statistics';

  @override
  String get spMonthEmpty => 'No expenses this month yet.';

  @override
  String spItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String spIncludesShots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Includes $n shots',
      one: 'Includes 1 shot',
    );
    return '$_temp0';
  }

  @override
  String get spRecent => 'Recent';

  @override
  String get spSeeAll => 'See all';

  @override
  String get spParentsOnly =>
      'Only parents see spending. You can give others access in Family.';

  @override
  String get spSharedWithYou =>
      'The parents have shared the baby\'s spending with you.';

  @override
  String spBudgetShare(String share, String total) {
    return '$share of the $total budget';
  }

  @override
  String spLeft(String amount) {
    return '$amount left';
  }

  @override
  String spOverBy(String amount) {
    return '$amount over';
  }

  @override
  String get spAvgPerDay => 'Average/day';

  @override
  String get spSame => 'Same';

  @override
  String spLower(String share) {
    return '$share lower';
  }

  @override
  String spHigher(String share) {
    return '$share higher';
  }

  @override
  String spComparedWith(int month) {
    return 'Compared with month $month';
  }

  @override
  String get spAllTitle => 'All expenses';

  @override
  String get spSearch => 'Search expenses…';

  @override
  String get spAllMonths => 'All months';

  @override
  String get spFilterMonth => 'Choose a month';

  @override
  String get spAllCategories => 'All categories';

  @override
  String get spAnyone => 'Anyone';

  @override
  String get spNothingYet => 'No expenses yet.';

  @override
  String get spNoMatch => 'No expenses match.';

  @override
  String get spGone => 'This expense is no longer here.';

  @override
  String get spCategory => 'Category';

  @override
  String get spDate => 'Date';

  @override
  String get spPayer => 'Who paid';

  @override
  String get spRecordedBy => 'Recorded by';

  @override
  String get spSource => 'Source';

  @override
  String get spLink => 'Link';

  @override
  String spLinkVaccine(String dose) {
    return 'Vaccinations · $dose';
  }

  @override
  String get spReceiptTitle => 'Receipt';

  @override
  String get spReceiptOpen => 'Tap to see it large';

  @override
  String get spDelete => 'Delete expense';

  @override
  String get spDeleted => 'Expense deleted';

  @override
  String get spAddTitle => 'Add expense';

  @override
  String get spEditTitle => 'Edit expense';

  @override
  String get spAmount => 'Amount';

  @override
  String spLastTime(String amount) {
    return 'Last time $amount';
  }

  @override
  String get spEditCategories => 'Edit categories';

  @override
  String get spAddCategoryChip => 'Category';

  @override
  String get spNote => 'Description';

  @override
  String get spNoteHint => 'E.g. Formula ×2';

  @override
  String get spReceipt => 'Receipt photo';

  @override
  String get spReceiptAttached => 'Attached · tap to see';

  @override
  String get spReceiptRemove => 'Remove the receipt';

  @override
  String get spReceiptAdd => 'Add a receipt photo';

  @override
  String get spReceiptPrivate =>
      'Only people who can see spending see this photo.';

  @override
  String get spRepeatMonthly => 'Repeat monthly';

  @override
  String spRepeatMonthlyOn(int day) {
    return 'Added on day $day every month';
  }

  @override
  String get spSave => 'Save expense';

  @override
  String get spSaved => 'Expense saved';

  @override
  String get spUpdated => 'Expense updated';

  @override
  String get spAmountMissing => 'Enter an amount';

  @override
  String get spSaveFailed => 'Couldn\'t save. Try again later.';

  @override
  String get spVaccineTitle => 'Record the cost of the shot?';

  @override
  String get spVaccineBody =>
      'Saved to Spending under Health & vaccines. You can skip this.';

  @override
  String get spVaccineSave => 'Save to Spending';

  @override
  String get spVaccineSaved => 'Shot cost saved';

  @override
  String get spSkip => 'Skip';

  @override
  String get spCategories => 'Categories';

  @override
  String get spCategoriesIntro =>
      'Drag to reorder. Categories are shared by every baby in the family.';

  @override
  String get spCategoriesInUse => 'In use';

  @override
  String get spCategoriesHidden => 'Hidden';

  @override
  String get spCategoryLocked => 'Default · can\'t be deleted';

  @override
  String spCategoryCustom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Custom · $n items',
      one: 'Custom · 1 item',
    );
    return '$_temp0';
  }

  @override
  String spCategoryHiddenSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hidden from the picker · keeps $n old items',
      one: 'Hidden from the picker · keeps 1 old item',
    );
    return '$_temp0';
  }

  @override
  String get spShowAgain => 'Show again';

  @override
  String get spDragHandle => 'Drag to reorder';

  @override
  String get spAddCategory => 'Add category';

  @override
  String get spNewCategory => 'New category';

  @override
  String get spEditCategory => 'Edit category';

  @override
  String get spCategoryName => 'Category name';

  @override
  String get spCategoryNamePlaceholder => 'E.g. Swimming & activities';

  @override
  String get spCategoryNameHelp => 'Up to 24 characters';

  @override
  String get spCategoryNameMissing => 'Enter a category name';

  @override
  String get spCategoryNameTaken => 'A category with this name already exists';

  @override
  String get spCategoryIcon => 'Icon';

  @override
  String get spCategoryColor => 'Colour';

  @override
  String spColorN(int n) {
    return 'Colour $n';
  }

  @override
  String get spSaveCategory => 'Save category';

  @override
  String get spHideCategory => 'Hide category';

  @override
  String get spCategoryHiddenToast => 'Category hidden';

  @override
  String get spDeleteCategory => 'Delete category';

  @override
  String spDeleteCategoryTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String spDeleteCategoryBody(int n, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'This category has $n expenses ($amount). Choose where to move them:',
      one: 'This category has 1 expense ($amount). Choose where to move it:',
    );
    return '$_temp0';
  }

  @override
  String get spDeleteCategoryEmpty =>
      'This category has no expenses for this baby. Any other baby\'s items move to:';

  @override
  String get spMoveToOther => 'Move to “Other”';

  @override
  String get spMoveToOtherSub => 'Totals stay the same';

  @override
  String get spMoveToAnother => 'Move to another category';

  @override
  String get spChooseCategory => 'Choose a category';

  @override
  String get spHideInstead =>
      'Want to keep old figures without seeing the category when recording? Choose Hide instead of Delete.';

  @override
  String spDeleteAndMove(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Delete and move $n items',
      one: 'Delete and move 1 item',
    );
    return '$_temp0';
  }

  @override
  String get spHideCategoryInstead => 'Hide the category instead';

  @override
  String get spCategoryDeleted => 'Category deleted';

  @override
  String get spNeedsNetwork => 'Deleting a category needs a connection.';

  @override
  String get spBudgetTitle => 'Monthly budget';

  @override
  String get spBudgetIntro =>
      'Set an expected amount to keep track. Categories can stay empty.';

  @override
  String get spBudgetPerMonth => 'Budget per month';

  @override
  String spBudgetUsed(int month, String share) {
    return 'Month $month: $share used';
  }

  @override
  String get spNoCap => 'No limit set';

  @override
  String get spClearCap => 'Remove this limit';

  @override
  String spUsedShare(String share) {
    return '$share used';
  }

  @override
  String spNearCap(String amount) {
    return 'Nearly at the limit · $amount left';
  }

  @override
  String spOverCap(String amount) {
    return '$amount over the limit';
  }

  @override
  String get spAlert80 => 'Remind me at 80% of the budget';

  @override
  String get spAlert80Sub => 'Sent to parents';

  @override
  String get spSaveBudget => 'Save budget';

  @override
  String get spBudgetSaved => 'Budget saved';

  @override
  String get spRecurringTitle => 'Recurring items';

  @override
  String get spRecurringIntro =>
      'Added to spending on the day. Parents get a notification and can change the amount afterwards.';

  @override
  String get spRecurringEmpty =>
      'No recurring items yet. Add childcare, formula or insurance so you don\'t have to record them each time.';

  @override
  String spRecurringNext(String date, String title, String amount) {
    return 'On $date: $title $amount will be added. You can change the amount afterwards.';
  }

  @override
  String get spAddRecurring => 'Add recurring item';

  @override
  String get spEditRecurring => 'Edit recurring item';

  @override
  String get spRecurringName => 'Name';

  @override
  String get spRecurringNameHint => 'E.g. Nanny';

  @override
  String get spRecurringTitleMissing => 'Enter a name';

  @override
  String get spSchedule => 'Repeats';

  @override
  String get spKindMonthly => 'Monthly';

  @override
  String get spKindWeeks => 'Weekly';

  @override
  String get spKindYearly => 'Yearly';

  @override
  String get spScheduleDays => 'Days of the month';

  @override
  String get spScheduleDaysHelp =>
      'Choose 1 or 2 days. Shorter months use their last day.';

  @override
  String get spStartOn => 'Starting';

  @override
  String get spScheduleOn => 'Date';

  @override
  String get spRecurringOn => 'On';

  @override
  String get spRecurringHelp =>
      'Items are added automatically on the due day, in the baby\'s time zone.';

  @override
  String get spDeleteRecurring => 'Delete recurring item';

  @override
  String get spRecurringSaved => 'Recurring item saved';

  @override
  String get spRecurringDeleted => 'Recurring item deleted';

  @override
  String get spLess => 'Less';

  @override
  String get spMore => 'More';

  @override
  String get spStatsTitle => 'Spending statistics';

  @override
  String get spWindowMonth => 'Month';

  @override
  String get spWindowSix => '6 months';

  @override
  String get spWindowBirth => 'Since birth';

  @override
  String get spMonthTotal => 'This month';

  @override
  String get spCount => 'Expenses';

  @override
  String get spSixTotal => '6-month total';

  @override
  String get spAvgPerMonth => 'Average per month';

  @override
  String spHighest(int month) {
    return 'Highest · M$month';
  }

  @override
  String get spByMonth => 'By month';

  @override
  String spCountedTo(int month, String date) {
    return 'M$month counted up to $date';
  }

  @override
  String spMonthTick(int month) {
    return 'M$month';
  }

  @override
  String spAvgLine(String amount) {
    return 'Avg $amount';
  }

  @override
  String spTip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get spOthersFolded => 'Other';

  @override
  String spSinceBirth(String name, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return 'Since $name was born · $_temp0';
  }

  @override
  String get spSinceFirst => 'Since the first expense';

  @override
  String spSinceBirthSub(String amount, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Average $amount per month of age · $n expenses',
      one: 'Average $amount per month of age · 1 expense',
    );
    return '$_temp0';
  }

  @override
  String get spByAge => 'By month of age';

  @override
  String get spFirstMonth => 'First month';

  @override
  String spAgeMonth(int n) {
    return 'Month $n of age';
  }

  @override
  String get spLargest => 'Largest items';

  @override
  String get spExport => 'Export spending (CSV)';

  @override
  String spExportFile(String date) {
    return 'spending-$date';
  }

  @override
  String get spExportFailed => 'Couldn\'t export the file. Try again later.';

  @override
  String get spOwnFamilyOnly =>
      'Figures are for your family\'s own tracking, never compared with other families.';

  @override
  String get rightRecordSpending => 'Record expenses';

  @override
  String get rightRecordSpendingHint => 'Only sees the items they recorded';

  @override
  String get rightViewSpending => 'See all spending';

  @override
  String get rightViewSpendingHint => 'Totals, statistics, every expense';

  @override
  String get rightSpendingNote =>
      'Spending is for parents by default. Someone with “Record expenses” on won\'t see totals or other people\'s items.';

  @override
  String spSinceBirthYoung(String name) {
    return 'Since $name was born';
  }

  @override
  String get sectionQuickActions => 'Quick add';

  @override
  String get sectionQuickActionsSub => 'Reminders, spending, shots, memories';

  @override
  String get sectionVaccine => 'Upcoming shots';

  @override
  String get sectionVaccineSub => 'From the baby\'s vaccination book';

  @override
  String get sectionSpending => 'Spending this month';

  @override
  String get sectionSpendingSub => 'The month\'s total against the budget';

  @override
  String get quickReminder => 'Reminder';

  @override
  String get quickExpense => 'Expense';

  @override
  String get quickVaccine => 'Shot';

  @override
  String get quickMemory => 'Memory';

  @override
  String get quickReminderHint => 'Create a reminder';

  @override
  String get quickExpenseHint => 'Record an expense';

  @override
  String get quickVaccineHint => 'Open the vaccination book';

  @override
  String get quickMemoryHint => 'Photos, videos, notes';

  @override
  String todayVaccineShots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shots · tap to see',
      one: '1 shot · tap to see',
    );
    return '$_temp0';
  }

  @override
  String get todayVaccineOpen => 'Open the vaccination book';

  @override
  String get todaySpendingNoBudget => 'No monthly budget set';

  @override
  String acExportEmailed(String when) {
    return 'Download link emailed · expires $when';
  }

  @override
  String get faEntryTitle => 'Child first aid';

  @override
  String faEntrySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count situations · works offline',
      one: '1 situation · works offline',
    );
    return '$_temp0';
  }

  @override
  String get faTitle => 'First aid';

  @override
  String get faSubtitle =>
      'Stay calm and follow the steps. Works even without a connection.';

  @override
  String get faEmergencyQuestion =>
      'Baby not breathing, turning blue or unconscious?';

  @override
  String faCall(String number) {
    return 'Call $number';
  }

  @override
  String faCallLocal(String number, String country) {
    return 'Call $number · $country';
  }

  @override
  String vxAbroadNotice(String country) {
    return 'This schedule follows Việt Nam\'s programme. In $country, follow the schedule from your doctor or local clinic; reminders only cover doses you\'ve set a date for.';
  }

  @override
  String get faStartCpr => 'Start CPR';

  @override
  String get faSearchHint => 'Choking, fever, burns, breathing…';

  @override
  String get faAll => 'All';

  @override
  String faSortedFor(String name, String age) {
    return 'Sorted for $name · $age';
  }

  @override
  String get faSaved => 'Saved';

  @override
  String get faSavedEmpty =>
      'Nothing saved yet. Tap the bookmark on a situation to keep it here.';

  @override
  String get faSave => 'Save this situation';

  @override
  String get faUnsave => 'Remove from saved';

  @override
  String get faSavedToast => 'Saved to First aid · Saved';

  @override
  String get faUnsavedToast => 'Removed from saved';

  @override
  String faResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count situations',
      one: '1 situation',
    );
    return '$_temp0';
  }

  @override
  String get faQuickSearch => 'Quick search';

  @override
  String faNoResults(String number) {
    return 'No matching situation. If your baby is in danger, call $number.';
  }

  @override
  String get faOffline => 'Works offline';

  @override
  String get faMonitoring => 'Monitoring';

  @override
  String get faFollowSteps => 'Follow the steps';

  @override
  String get faDisclaimer =>
      'For reference only. It does not replace a doctor’s diagnosis.';

  @override
  String faReviewed(String reviewer, String month) {
    return 'Reviewed by $reviewer, $month.';
  }

  @override
  String get faSeizureTimer => 'Time the seizure';

  @override
  String get faTimerStart => 'Start';

  @override
  String get faTimerStop => 'Stop';

  @override
  String get faTimerReset => 'Reset';

  @override
  String faCallFailed(String number) {
    return 'Couldn’t open the phone app. Dial $number on your phone.';
  }

  @override
  String faWeightKg(String kg) {
    return '$kg kg';
  }

  @override
  String get faNotFound => 'This guide wasn’t found. Open First aid again.';

  @override
  String get faReadAloud => 'Read the guide aloud';

  @override
  String get faReadAloudShort => 'Read aloud';

  @override
  String get faStopReading => 'Stop reading';

  @override
  String faCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '× $count times',
      one: '× 1 time',
    );
    return '$_temp0';
  }

  @override
  String faCalling(String number, String time) {
    return 'Calling $number · $time';
  }

  @override
  String get faTellOperator => 'Tell the operator';

  @override
  String get faTellBaby => 'Baby';

  @override
  String get faTellCondition => 'Condition';

  @override
  String get faMetronomeTitle => 'Compression beat playing · automatic';

  @override
  String get faMetronomePaused => 'Beat paused while reading';

  @override
  String faMetronomeBody(int count, int breaths) {
    return 'Turn the speaker on and put the phone beside your baby. Press with each beep. After every $count, the app says “$breaths rescue breaths”.';
  }

  @override
  String faSayBreaths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Give $count rescue breaths',
      one: 'Give 1 rescue breath',
    );
    return '$_temp0';
  }

  @override
  String faSpeakStep(int n, String title, String body) {
    return 'Step $n. $title. $body';
  }

  @override
  String get tabUtilities => 'Utilities';

  @override
  String get utTitle => 'Utilities';

  @override
  String utSpendingMonth(String amount) {
    return 'This month $amount';
  }

  @override
  String get utMySpending => 'What I paid';

  @override
  String get utMySpendingSub => 'You may record what you paid';

  @override
  String get utMembers => 'Members & sharing';

  @override
  String utMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String utMembersPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites pending',
      one: '1 invite pending',
    );
    return '$_temp0';
  }

  @override
  String get utMembersView => 'See family members';

  @override
  String get utInvite => 'Invite family';

  @override
  String get utInviteSub =>
      'Grandparents and caregivers follow the baby with you';

  @override
  String get inviteLinkJoining => 'Accepting the invite…';

  @override
  String inviteLinkJoined(String baby) {
    return 'You now care for $baby. Change your name in Family.';
  }

  @override
  String get inviteLinkDefaultName => 'Family member';

  @override
  String meVersion(String version) {
    return 'Version $version';
  }

  @override
  String get upRequiredTitle => 'Update to keep going';

  @override
  String get upRequiredBody =>
      'This version is too old to sync safely with your family. Updating takes about a minute.';

  @override
  String get upSafeTitle => 'Your baby\'s data is safe';

  @override
  String get upSafeBody => 'Photos, journal and care history stay as they are';

  @override
  String upPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 not synced yet';
  }

  @override
  String get upPendingBody => 'They go up right after you update';

  @override
  String get upOpenAppStore => 'Update on the App Store';

  @override
  String get upOpenPlay => 'Update on Google Play';

  @override
  String upWhatsNewIn(String version) {
    return 'What\'s new in $version';
  }

  @override
  String upNewTag(String version) {
    return 'New · $version';
  }

  @override
  String get upNewTitle => 'A new Child Life is here';

  @override
  String get upUpdate => 'Update';

  @override
  String get upLater => 'Later';

  @override
  String upPageTag(String version) {
    return 'New in $version';
  }

  @override
  String get upSkip => 'Skip';

  @override
  String get upNext => 'Next';

  @override
  String get upPagesDone => 'Done';

  @override
  String upPageOf(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String upBannerTitle(String version) {
    return 'Updated to $version';
  }

  @override
  String get upBannerSee => 'See';

  @override
  String get upBannerClose => 'Close the update note';

  @override
  String upNewVersion(String version) {
    return '$version is available';
  }

  @override
  String get upLatestVersion => 'You have the latest version';

  @override
  String get upNoStore => 'Couldn\'t open the update page. Try again later.';

  @override
  String get spFirstImport => 'Import from another app or Excel';

  @override
  String get spFromImport => 'imported';

  @override
  String get spFromAssistant => 'from the Assistant';

  @override
  String get spFromImportFull => 'Imported · see the import';

  @override
  String get imTitle => 'Import spending';

  @override
  String imIntro(String name) {
    return 'Bring spending from another app, a spreadsheet or a notebook into $name\'s Spending. You review it before anything is added.';
  }

  @override
  String get imParentsOnly => 'Only co-parents can import spending.';

  @override
  String get imSourceFile => 'CSV or Excel file';

  @override
  String get imSourceFileHint =>
      'Money Lover, MISA, Google Sheets, Excel… columns found for you';

  @override
  String get imSourceText => 'Paste text';

  @override
  String get imSourceTextHint =>
      'Notes, messages, lists — AI splits them into items';

  @override
  String get imSourcePhotos => 'Photos of a spending notebook';

  @override
  String get imSourcePhotosHint => 'Up to 5 photos — AI reads each line';

  @override
  String get imPrivacy =>
      'Text and photos go to an AI service only to be read, not kept; the baby\'s name is never sent. Uploads are deleted after 7 days.';

  @override
  String get imRecent => 'Imports';

  @override
  String get imBusyReading => 'Reading…';

  @override
  String get imBusyAi => 'The AI is reading; this can take half a minute…';

  @override
  String get imPasteHint =>
      'One item per line, e.g. “12/10 formula 1,020,000 mum paid”.';

  @override
  String get imPastePlaceholder => 'Paste here';

  @override
  String get imRead => 'Read it';

  @override
  String get imReviewTitle => 'Review';

  @override
  String imDuplicates(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n duplicates',
      one: '1 duplicate',
    );
    return '$_temp0';
  }

  @override
  String imIncome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n income rows',
      one: '1 income row',
    );
    return '$_temp0';
  }

  @override
  String imErrors(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rows with problems',
      one: '1 row with a problem',
    );
    return '$_temp0';
  }

  @override
  String get imColumns => 'Columns in the file';

  @override
  String get imColumnNone => 'None';

  @override
  String get imDateOrder => 'Dates are written as';

  @override
  String get imDateDmy => 'Day/Month/Year';

  @override
  String get imDateMdy => 'Month/Day/Year';

  @override
  String get imRowsAre => 'Spending is the rows with';

  @override
  String get imRowsNegative => 'Negative';

  @override
  String get imRowsPositive => 'Positive';

  @override
  String get imRowsAll => 'All';

  @override
  String get imSkipDuplicates => 'Skip items already recorded';

  @override
  String get imSkipDuplicatesHint => 'Same day, amount and description';

  @override
  String imSourceRows(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$name · $_temp0';
  }

  @override
  String imNewCategory(String name) {
    return 'New “$name”';
  }

  @override
  String imConfirm(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Import $n items',
      one: 'Import 1 item',
    );
    return '$_temp0';
  }

  @override
  String get imNothingToImport => 'Nothing to import';

  @override
  String get imIssueNoDate => 'No date';

  @override
  String get imIssueBadDate => 'Date not readable';

  @override
  String get imIssueFutureDate => 'Date in the future';

  @override
  String get imIssueNoAmount => 'No amount';

  @override
  String get imIssueBadAmount => 'Amount not valid';

  @override
  String get imIssueTooLarge => 'Amount too large';

  @override
  String get imIssueCurrency => 'Not in Vietnamese đồng';

  @override
  String get imIssueIncome => 'Income, skipped';

  @override
  String get imIssueDuplicate => 'Already recorded, skipped';

  @override
  String get imFailAiUnavailable =>
      'The AI isn\'t available yet. Use a CSV or Excel file.';

  @override
  String get imFailAi =>
      'The AI couldn\'t read this. Try a clearer photo or paste text.';

  @override
  String get imFailEmpty => 'No spending found in this.';

  @override
  String get imFailTooBig =>
      'The file is too large (10 MB, 5,000 rows at most).';

  @override
  String get imFailOffline => 'Importing needs a connection.';

  @override
  String get imFailGeneric => 'Couldn\'t import. Try again later.';

  @override
  String get imReadOldExcel =>
      'Old .xls files can\'t be read. Save it as .xlsx or CSV and try again.';

  @override
  String get imReadUnsupported => 'Choose a CSV or Excel (.xlsx) file.';

  @override
  String get imReadBroken => 'This file can\'t be opened.';

  @override
  String get imStatusAnalyzing => 'Reading';

  @override
  String get imStatusReady => 'Waiting for your review';

  @override
  String get imStatusImporting => 'Importing';

  @override
  String imStatusDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items imported',
      one: '1 item imported',
    );
    return '$_temp0';
  }

  @override
  String get imStatusFailed => 'Not imported';

  @override
  String get imStatusUndone => 'Undone';

  @override
  String get imContinueReview => 'Continue the review';

  @override
  String get imImporting => 'Importing spending…';

  @override
  String imProgress(int done, int total) {
    return '$done / $total items';
  }

  @override
  String get imCanClose =>
      'You can close the app. Child Life will email you and notify you when it\'s done.';

  @override
  String imDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items imported',
      one: '1 item imported',
    );
    return '$_temp0';
  }

  @override
  String imSkipped(String details) {
    return 'Skipped: $details.';
  }

  @override
  String get imEmailSent => 'The result was also sent by email.';

  @override
  String get imSeeSpending => 'See spending';

  @override
  String get imIssues => 'Rows not imported';

  @override
  String imRow(int n) {
    return 'Row $n';
  }

  @override
  String get imFailedTitle => 'Spending wasn\'t imported';

  @override
  String get imTryAgain => 'Try again';

  @override
  String get imUndoneTitle => 'This import was undone';

  @override
  String get imUndoTitle => 'Undo this import?';

  @override
  String imUndoBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'The $n imported items will be removed from Spending, even those edited since.',
      one:
          'The imported item will be removed from Spending, even if it was edited since.',
    );
    return '$_temp0';
  }

  @override
  String imUndoConfirm(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Remove $n items',
      one: 'Remove 1 item',
    );
    return '$_temp0';
  }

  @override
  String imUndone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Removed $n imported items',
      one: 'Removed 1 imported item',
    );
    return '$_temp0';
  }

  @override
  String imInto(String name) {
    return 'Into: $name';
  }

  @override
  String get upFirstAid => 'First aid';

  @override
  String get watchTileBottle => 'Bottle';

  @override
  String get watchTileBreast => 'Breast';

  @override
  String get watchTileSleep => 'Sleep';

  @override
  String get watchTileDiaper => 'Diaper';

  @override
  String get watchTilePump => 'Pumping';

  @override
  String get watchTileReminder => 'Reminder';

  @override
  String get watchSinceFeed => 'since last feed';

  @override
  String get watchSinceLast => 'since last time';

  @override
  String get watchSleeping => 'asleep';

  @override
  String get watchAwake => 'awake';

  @override
  String get watchFeedReminder => 'feed reminder';

  @override
  String get watchNoneYet => 'none yet';

  @override
  String watchAgo(String t) {
    return '$t ago';
  }

  @override
  String get watchChooseBabyRow => 'Choose baby';

  @override
  String get watchCrownHint => 'ml · turn the crown to adjust';

  @override
  String get watchSave => 'Save';

  @override
  String get watchBreastStartHint => 'Which side first?';

  @override
  String get watchSideLeft => 'Left';

  @override
  String get watchSideRight => 'Right';

  @override
  String get watchSuggested => 'suggested';

  @override
  String watchBreastTotalLeft(String t) {
    return 'Total $t · on the left';
  }

  @override
  String watchBreastTotalRight(String t) {
    return 'Total $t · on the right';
  }

  @override
  String get watchSwitchSide => 'Switch side';

  @override
  String get watchStop => 'Stop';

  @override
  String watchSleepSince(String time) {
    return 'since $time';
  }

  @override
  String get watchWokeUp => 'Baby woke up';

  @override
  String get watchDiaperTitle => 'Diaper change';

  @override
  String get watchDiaperWet => 'Wet';

  @override
  String get watchDiaperDirty => 'Dirty';

  @override
  String get watchDiaperBoth => 'Both';

  @override
  String get watchLoggedWet => 'Wet diaper logged';

  @override
  String get watchLoggedDirty => 'Dirty diaper logged';

  @override
  String get watchLoggedBoth => 'Wet and dirty diaper logged';

  @override
  String watchLoggedBottle(String ml) {
    return '$ml ml bottle logged';
  }

  @override
  String get watchLoggedBreast => 'Breastfeed logged';

  @override
  String get watchLoggedSleep => 'Sleep logged';

  @override
  String watchLoggedBy(String time, String name) {
    return '$time · logged by $name';
  }

  @override
  String get watchUndo => 'Undo';

  @override
  String get watchFailed => 'Couldn\'t save. Try again later.';

  @override
  String get watchChooseBaby => 'Choose baby';

  @override
  String get watchOneBabyNote => 'Switch to another baby on the iPhone.';

  @override
  String get watchOffline =>
      'Saved on the watch. It will be sent once you\'re online.';

  @override
  String watchPending(String n) {
    return '$n entries waiting to send';
  }

  @override
  String get watchLinkTitle => 'Connect your iPhone';

  @override
  String get watchLinkBody =>
      'Open Child Life on your iPhone and sign in; the watch connects by itself.';

  @override
  String get watchCannotLog => 'There\'s no baby you can log for on the watch.';

  @override
  String get watchDemo => 'Try it out';

  @override
  String imTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String imDays(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get imReadingAuto => 'Columns found automatically';

  @override
  String imReadingPreset(String name) {
    return '$name file';
  }

  @override
  String get imReadingNegative => 'negative amounts are spending';

  @override
  String get imReadingPositive => 'positive amounts are spending';

  @override
  String get imReadingAllSigns => 'both negative and positive amounts';

  @override
  String get imReadingDmy => 'day/month/year';

  @override
  String get imReadingMdy => 'month/day/year';

  @override
  String get imAdjust => 'Adjust';

  @override
  String get imAdjustTitle => 'How the file is read';

  @override
  String imSkippedRows(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rows left out',
      one: '1 row left out',
    );
    return '$_temp0';
  }

  @override
  String get imSkippedExplain =>
      'These rows won\'t be imported. Fix them in the file and import again if needed.';

  @override
  String imSkippedMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'And $n more rows',
      one: 'And 1 more row',
    );
    return '$_temp0';
  }

  @override
  String get imCategoriesTitle => 'Put into categories';

  @override
  String imCategoryFor(String name) {
    return 'Put “$name” into';
  }

  @override
  String get imSamples => 'Some of what will be imported';

  @override
  String imReadyLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'expenses ready to import',
      one: 'expense ready to import',
    );
    return '$_temp0';
  }

  @override
  String imCategoriesNewHint(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n names aren\'t in Spending yet and become new categories. Tap to change.',
      one:
          '1 name isn\'t in Spending yet and becomes a new category. Tap to change.',
    );
    return '$_temp0';
  }

  @override
  String get imBadgeNew => 'New';

  @override
  String imSeeAll(int n) {
    return 'See all $n';
  }

  @override
  String imAllTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items to import',
      one: '1 item to import',
    );
    return '$_temp0';
  }

  @override
  String imPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get imPagePrev => 'Previous page';

  @override
  String get imPageNext => 'Next page';

  @override
  String get imUndoAction => 'Undo this import';

  @override
  String imUndoUntil(String time, String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'less than a day left',
    );
    return 'You can undo until $time on $date ($_temp0)';
  }

  @override
  String get emailSignInTitle => 'Sign in';

  @override
  String get emailLinkSend => 'Send sign-in link';

  @override
  String get linkSentTitle => 'Check your email';

  @override
  String linkSentBody(String email) {
    return 'We sent a sign-in link to $email. Open it on this phone within 15 minutes to get in.';
  }

  @override
  String get linkSentSpam =>
      'Can\'t find it? Check your Promotions or Spam folder.';

  @override
  String get linkSentOpenMail => 'Open Mail';

  @override
  String linkSentResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get linkSentResend => 'Resend';

  @override
  String get linkSentResent => 'Link sent again.';

  @override
  String get linkSentChangeEmail => 'Change email';

  @override
  String get linkOpenSigningIn => 'Signing you in…';

  @override
  String get linkConfirmTitle => 'Confirm your email';

  @override
  String get linkConfirmBody =>
      'Enter the email that got the link to sign in on this device.';

  @override
  String get linkExpiredTitle => 'This link has expired';

  @override
  String get linkExpiredBody =>
      'A sign-in link works once, within 15 minutes. Send a new one to get in.';

  @override
  String get linkExpiredButton => 'Send a new link';

  @override
  String get meFeedback => 'Send feedback';

  @override
  String get meFeedbackHint => 'Report a bug, suggest a feature';

  @override
  String get meRateAppStore => 'Rate on the App Store';

  @override
  String get meRatePlay => 'Rate on Google Play';

  @override
  String get meRateUnavailable => 'Child Life isn\'t in the store yet.';

  @override
  String get fbTitle => 'Feedback';

  @override
  String get fbIntro =>
      'The Child Life team reads every message. Thank you for helping make the app better for families.';

  @override
  String get fbTypeIdea => 'Idea';

  @override
  String get fbTypeBug => 'Bug';

  @override
  String get fbTypeOther => 'Other';

  @override
  String get fbMessageLabel => 'What would you like to share?';

  @override
  String get fbScreenshot => 'Screenshot';

  @override
  String get fbScreenshotRemove => 'Remove screenshot';

  @override
  String get fbDevice => 'Include device info';

  @override
  String get fbDeviceHint => 'App and system version · no photos or baby data';

  @override
  String get fbReply => 'Allow us to reply';

  @override
  String get fbReplyNoEmail => 'Needs an account with an email';

  @override
  String get fbSend => 'Send feedback';

  @override
  String get fbSendFailed => 'Couldn\'t send your feedback. Try again.';

  @override
  String get fbSentTitle => 'Thanks, we got your feedback';

  @override
  String get fbSentBody =>
      'If we need more details, the team will email you within 2 working days. You can find it again in Me › Help & contact.';

  @override
  String get fbSentBodyNoReply =>
      'The team will read your feedback. You can find it again in Me › Help & contact.';

  @override
  String get fbDone => 'Done';

  @override
  String get fbShotTitle => 'Something wrong on this screen?';

  @override
  String get fbShotBody => 'Report it with the screenshot you just took';

  @override
  String get hpSentTitle => 'Sent';

  @override
  String get hpStatusNew => 'Received';

  @override
  String get hpStatusClaimed => 'In review';

  @override
  String get hpStatusWaiting => 'Answered';

  @override
  String get hpStatusClosed => 'Closed';

  @override
  String hpFeedbackLabel(String type) {
    return 'Feedback · $type';
  }

  @override
  String get signInRegister => 'Sign up';

  @override
  String get autoSaveTitle => 'Auto-save memories';

  @override
  String get autoSaveBeta => 'Free beta';

  @override
  String autoSaveEntryHint(String name) {
    return 'Suggests photos and videos of $name from your library';
  }

  @override
  String autoSaveEntryPending(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new photos to review · checked at $time',
      one: '1 new photo to review · checked at $time',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReviewShort => 'Review';

  @override
  String get autoSaveIntroLead =>
      'No more digging through your library. Child Life finds photos and videos that may show your baby, and you check them before anything is uploaded.';

  @override
  String get autoSaveStep1 => 'Pick your baby and a few clear photos';

  @override
  String get autoSaveStep1Hint => 'Helps the app suggest better';

  @override
  String get autoSaveStep2 => 'The app looks through new photos';

  @override
  String get autoSaveStep2Hint => 'Only the photos you let it see';

  @override
  String get autoSaveStep3 => 'You approve before anything uploads';

  @override
  String get autoSaveStep3Hint => 'Nothing uploads or shares on its own';

  @override
  String autoSaveIntroFootnote(String usage) {
    return 'Suggestions can miss photos or get them wrong, especially dark, tilted or crowded ones. Photos are checked on this phone and never sent anywhere. The beta is free; uploaded files still count towards your family\'s storage ($usage).';
  }

  @override
  String get autoSaveIntroFootnoteNoUsage =>
      'Suggestions can miss photos or get them wrong, especially dark, tilted or crowded ones. Photos are checked on this phone and never sent anywhere. The beta is free; uploaded files still count towards your family\'s storage.';

  @override
  String get autoSaveStart => 'Set up';

  @override
  String get autoSavePickBabyTitle => 'Which baby should we look for?';

  @override
  String get autoSavePickBabySub =>
      'Step 1 of 3 · You can add another baby later in Settings.';

  @override
  String autoSaveYouAre(String relation) {
    return 'You are $relation';
  }

  @override
  String get autoSaveLockedCaregiver =>
      'you\'re a caregiver, so you can\'t turn this on';

  @override
  String get autoSaveLockedRelative =>
      'you\'re a relative, so you can\'t turn this on';

  @override
  String get autoSaveNext => 'Next';

  @override
  String autoSaveSamplesTitle(String name) {
    return 'Pick a few clear photos of $name';
  }

  @override
  String get autoSaveSamplesSub =>
      'Step 2 of 3 · 3–5 well-lit photos where the face is clear. Samples are only used for suggestions and don\'t appear in Memories.';

  @override
  String autoSaveSamplesCount(int count) {
    return '$count/5 samples · from your Memories';
  }

  @override
  String get autoSaveSamplesFromLibrary => 'Or choose from your library';

  @override
  String autoSaveSamplesNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next · $count samples',
      one: 'Next · 1 sample',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSamplesNeed => 'Pick at least 3 samples.';

  @override
  String get autoSaveSampleNoFace =>
      'No clear face in this photo. Try another one.';

  @override
  String autoSaveSamplesEmpty(String name) {
    return 'Memories has no photos of $name yet. Choose from your library.';
  }

  @override
  String get autoSaveConsentTitle => 'Before you start';

  @override
  String get autoSaveConsentSub =>
      'Step 3 of 3 · You can change this any time in Auto-save settings.';

  @override
  String autoSaveFaceTitle(String name) {
    return 'Recognise $name on this phone only';
  }

  @override
  String autoSaveFaceBody(String name) {
    return 'Child Life compares faces in new photos with $name\'s samples to make suggestions. It all happens on your phone.';
  }

  @override
  String autoSaveFaceNoPhotos(String name) {
    return 'No photos of $name are kept: your samples stay in Memories or your library.';
  }

  @override
  String get autoSaveFaceNumbers =>
      'Only a list of numbers about the face is remembered, on this phone, never sent to Child Life.';

  @override
  String get autoSaveFaceNoOne =>
      'Child Life can\'t see it and never uses it for ads. Delete it any time.';

  @override
  String autoSaveFaceAgree(String name) {
    return 'I agree to let Child Life recognise $name on this phone';
  }

  @override
  String get autoSaveAgreeFirst =>
      'Tick the agreement in the first card to continue.';

  @override
  String get autoSaveWhatKept => 'What does Child Life keep?';

  @override
  String get autoSaveLibraryTitle => 'Let Child Life see your photo library';

  @override
  String autoSaveLibraryBody(String name) {
    return 'To find new photos and videos that may show $name. The app never deletes or changes anything in your library.';
  }

  @override
  String get autoSaveLibraryHint =>
      'Next, your phone asks for permission. You can allow all photos or only the ones you choose.';

  @override
  String get autoSaveUploadTitle => 'Only what you approve is uploaded';

  @override
  String get autoSaveUploadBody =>
      'Photos and videos you approve are uploaded to Memories just like when you add them yourself, and keep uploading when your phone is locked.';

  @override
  String get autoSaveAllow => 'Allow photo access';

  @override
  String get autoSaveLater => 'Later · add photos yourself';

  @override
  String get autoSaveKeptHere => 'On this phone';

  @override
  String get autoSaveKeptHereBody =>
      'Numbers about the face from your samples and the photos you approved; which photos were checked or skipped; your Auto-save settings. Not in your iCloud backup. Removing the app removes it all.';

  @override
  String get autoSaveKeptNever => 'Never';

  @override
  String get autoSaveKeptNeverBody =>
      'Keep copies of your samples or library photos; send face data to Child Life\'s servers or anyone else; use it for ads.';

  @override
  String get autoSaveKeptUp => 'Uploaded to Child Life';

  @override
  String get autoSaveKeptUpBody =>
      'Only the photos and videos you approve, with the \"Who can see\" you choose (Parents only by default).';

  @override
  String get autoSaveKeptFooter =>
      'Delete it in Auto-save settings › Delete samples and suggestion data. If you turn Auto-save off, the data on this phone is deleted after 30 days.';

  @override
  String get autoSaveChecking => 'Checking new photos';

  @override
  String autoSaveCheckingFirst(String checked, String total) {
    return '$checked / $total files · nothing uploaded yet';
  }

  @override
  String autoSaveCheckingProgress(String checked, String total) {
    return '$checked / $total files · checking progress';
  }

  @override
  String get autoSaveCheckingPause =>
      'It may pause when you leave the app and carries on next time.';

  @override
  String get autoSaveCheckingSeparate =>
      'Separate from the upload progress below.';

  @override
  String autoSaveFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count suggestions',
      one: 'Found 1 suggestion',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveFoundHint => 'You can look now; checking carries on.';

  @override
  String autoSaveSeeFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See $count suggestions',
      one: 'See 1 suggestion',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveKinds => 'Photos and videos';

  @override
  String get autoSaveKindsBoth => 'Checks both · only what you allow';

  @override
  String autoSaveLastCheck(String time) {
    return 'Last checked: $time';
  }

  @override
  String autoSaveNewFiles(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new files · $names',
      one: '1 new file · $names',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveCheckNow => 'Check new photos';

  @override
  String get autoSaveWhen =>
      'The app checks when you open it and when your phone allows it in the background; there\'s no fixed time.';

  @override
  String autoSavePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions to review',
      one: '1 suggestion to review',
    );
    return '$_temp0';
  }

  @override
  String autoSavePendingMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions to review · finding more',
      one: '1 suggestion to review · finding more',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReview => 'Review suggestions';

  @override
  String get autoSaveUploadingRow => 'Uploading';

  @override
  String autoSaveUploadingValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSavedRow => 'Saved by Auto-save';

  @override
  String autoSaveSavedValue(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in $month',
      one: '1 item in $month',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveManual => 'Add photos yourself';

  @override
  String get autoSaveManualHint => 'Choose from your library as before';

  @override
  String get autoSaveLimitedTitle => 'Looking at the photos you chose';

  @override
  String get autoSaveLimitedBody =>
      'Child Life only suggests from these photos';

  @override
  String get autoSavePickMore => 'Choose more photos';

  @override
  String get autoSaveAllowAll => 'Allow all photos in your phone\'s Settings';

  @override
  String get autoSaveDeniedTitle => 'Child Life can\'t see your photos';

  @override
  String get autoSaveDeniedBody =>
      'Auto-save is paused. Saved memories aren\'t affected.';

  @override
  String get autoSaveOpenSettings => 'Open phone Settings';

  @override
  String autoSaveNoSamplesTitle(String name) {
    return '$name has no samples yet';
  }

  @override
  String autoSaveNoSamplesBody(String name) {
    return 'Add 3–5 clear photos to start suggesting photos of $name';
  }

  @override
  String get autoSaveAddSamples => 'Add samples';

  @override
  String autoSaveNothingTitle(String names) {
    return 'No new photos that may show $names';
  }

  @override
  String autoSaveNothingBody(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Checked at $time · $count new files since last time',
      one: 'Checked at $time · 1 new file since last time',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveOffTitle => 'Auto-save is off';

  @override
  String get autoSaveOffBody =>
      'Turn it back on in Auto-save settings to look for new photos. Saved memories aren\'t affected.';

  @override
  String get autoSaveNotYet => 'Not checked yet';

  @override
  String autoSaveReviewTitle(String name) {
    return 'May show $name';
  }

  @override
  String autoSaveReviewSub(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count suggestions · checked at $time. Untick anything you don\'t want to save.',
      one:
          '1 suggestion · checked at $time. Untick anything you don\'t want to save.',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveGroupedHint =>
      'Similar photos are grouped; the clearest one is already ticked.';

  @override
  String autoSaveFilterAll(int count) {
    return 'All · $count';
  }

  @override
  String autoSaveFilterPhotos(int count) {
    return 'Photos · $count';
  }

  @override
  String autoSaveFilterVideos(int count) {
    return 'Videos · $count';
  }

  @override
  String autoSaveDayToday(String date) {
    return 'Today · $date';
  }

  @override
  String autoSaveDayYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String autoSaveDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveAlready => 'Saved';

  @override
  String get autoSaveInCloud => 'In iCloud';

  @override
  String get autoSaveLegend =>
      '\"Saved\": already in Memories, won\'t be uploaded again. \"In iCloud\": the original isn\'t on this phone yet and is fetched when online.';

  @override
  String autoSaveGroupTitle(int count, int chosen) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count similar photos · $chosen ticked',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveGroupAll => 'Tick all';

  @override
  String get autoSaveGroupCollapse => 'Collapse';

  @override
  String get autoSaveBest => 'Clearest';

  @override
  String autoSaveChosen(int count, int photos, int videos) {
    return '$count ticked · $photos photos, $videos videos';
  }

  @override
  String autoSaveMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count similar photos grouped · nothing deleted on your phone',
      one: '1 similar photo grouped · nothing deleted on your phone',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveDeselectAll => 'Deselect all';

  @override
  String get autoSaveSelectAll => 'Select all';

  @override
  String autoSaveRoundRest(int rest, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      rest,
      locale: localeName,
      other:
          'Up to $cap items per upload · $rest more suggestions wait for next time',
      one:
          'Up to $cap items per upload · 1 more suggestion waits for next time',
    );
    return '$_temp0';
  }

  @override
  String autoSaveRoundFull(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'Up to $cap items per upload',
    );
    return '$_temp0';
  }

  @override
  String autoSaveContinue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Continue with $count items',
      one: 'Continue with 1 item',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReviewEmpty => 'No suggestions left to review.';

  @override
  String autoSaveViewerPos(int index, int total, String time) {
    return '$index / $total · $time';
  }

  @override
  String get autoSaveFor => 'Suggested for';

  @override
  String get autoSaveChange => 'Change';

  @override
  String get autoSaveNotBaby => 'Not my baby';

  @override
  String get autoSaveSelected => 'Ticked';

  @override
  String get autoSaveSelect => 'Tick';

  @override
  String get autoSaveRejected => 'Removed from suggestions';

  @override
  String get autoSaveUndo => 'Undo';

  @override
  String get autoSaveWhose => 'Who is in this photo?';

  @override
  String get autoSaveSuggestedNow => 'Suggested now';

  @override
  String get autoSaveNotBabyHint => 'Removes it · helps future suggestions';

  @override
  String get autoSaveDone => 'Done';

  @override
  String get autoSaveConfirmTitle => 'Check before uploading';

  @override
  String get autoSaveSource => 'Source';

  @override
  String autoSaveSourceValue(int count, int photos, int videos) {
    return 'Photo library on this phone · $count items ($photos photos, $videos videos)';
  }

  @override
  String get autoSaveBabyRow => 'Baby';

  @override
  String get autoSaveSaveTo => 'Save to';

  @override
  String get autoSaveSaveToValue => 'Journal, by date taken · Album: none';

  @override
  String get autoSaveWho => 'Who can see';

  @override
  String get autoSaveParentsOnly => 'Parents only';

  @override
  String get autoSaveParentsOnlyHint => 'Auto-save default';

  @override
  String get autoSaveFamily => 'Family';

  @override
  String get autoSaveFamilyHint => 'The whole family sees it';

  @override
  String get autoSaveNotify => 'Tell the family';

  @override
  String get autoSaveNotifyOff => 'Off · no notification';

  @override
  String get autoSaveNotifyOn => 'One notification, no photos';

  @override
  String get autoSaveStorageAfter => 'Storage after upload';

  @override
  String autoSaveUploadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Upload $count items',
      one: 'Upload 1 item',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveConfirmFootnote =>
      'Originals stay on your phone. \"Saved\" appears once the upload finishes.';

  @override
  String autoSaveNoRoom(int count, String need, String left, int fit) {
    return 'Not enough space: $count items need $need and your family has $left left. You can upload $fit items that fit now; the rest stay on your phone.';
  }

  @override
  String autoSaveUploadFit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Upload the $count items that fit',
      one: 'Upload the 1 item that fits',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveNoRoomFootnote =>
      'Items not uploaded stay on your phone and in your suggestions.';

  @override
  String get autoSaveSeeStorage => 'See storage';

  @override
  String autoSavePreparing(int done, int total) {
    return 'Preparing $done/$total…';
  }

  @override
  String autoSaveQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uploading $count items to Memories',
      one: 'Uploading 1 item to Memories',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSettingsTitle => 'Auto-save settings';

  @override
  String get autoSaveOnBeta => 'On · Free beta';

  @override
  String get autoSaveOffValue => 'Off';

  @override
  String get autoSaveLookIn => 'Look in';

  @override
  String get autoSavePhotos => 'Photos';

  @override
  String get autoSaveVideos => 'Videos';

  @override
  String get autoSaveVideosHint => 'Large videos use a lot of space';

  @override
  String get autoSaveWifi => 'Upload videos on Wi-Fi only';

  @override
  String get autoSaveWifiHint => 'Applies to every video upload';

  @override
  String get autoSaveNotifyNew => 'Tell me about new photos';

  @override
  String get autoSaveNotifyNewHint =>
      'At most once a day · never in quiet hours';

  @override
  String get autoSaveBabies => 'Babies and samples';

  @override
  String autoSaveSamplesOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples · suggesting',
      one: '1 sample · suggesting',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSamplesNone => 'No samples · paused';

  @override
  String get autoSaveAddBaby => 'Add a baby';

  @override
  String get autoSaveLastStatus => 'Latest status';

  @override
  String get autoSaveCheckRow => 'Check';

  @override
  String autoSaveCheckValue(String time, int files, int found) {
    return '$time · $files files · $found suggestions';
  }

  @override
  String get autoSavePermission => 'Photo access';

  @override
  String get autoSaveAccessFull => 'All photos';

  @override
  String get autoSaveAccessLimited => 'Selected photos';

  @override
  String get autoSaveAccessDenied => 'Not allowed';

  @override
  String get autoSaveOnDevice => 'Recognition data stays on this phone.';

  @override
  String get autoSaveOffNote =>
      'Turning Auto-save off doesn\'t delete saved memories. The app just stops looking for new photos.';

  @override
  String get autoSaveWipe => 'Delete samples and suggestion data';

  @override
  String get autoSaveWipeBody =>
      'The face numbers, waiting suggestions and your agreement on this phone are deleted. Saved memories aren\'t affected. To use it again, you set it up from the start.';

  @override
  String get autoSaveWipeAction => 'Delete';

  @override
  String get autoSaveWiped => 'Auto-save data deleted from this phone';

  @override
  String autoSaveSamplesOf(String name) {
    return '$name\'s samples';
  }

  @override
  String get autoSaveSave => 'Save';

  @override
  String autoSaveRemoveBaby(String name) {
    return 'Remove $name from Auto-save';
  }

  @override
  String autoSaveAnd(String a, String b) {
    return '$a and $b';
  }

  @override
  String get autoSaveSamplesHint =>
      '3–5 well-lit photos where the face is clear. Samples are only used for suggestions and don\'t appear in Memories.';

  @override
  String get emailLinkNeedsEmail => 'Enter your email to get a sign-in link.';

  @override
  String autoSavePushTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new photos may show $name',
      one: '1 new photo may show $name',
    );
    return '$_temp0';
  }

  @override
  String get autoSavePushBody =>
      'Tap to see them and choose what to save to Memories.';

  @override
  String get autoSaveYourBaby => 'your baby';

  @override
  String autoSaveBannerTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new photos may show $name',
      one: '1 new photo may show $name',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveBannerBody => 'From your photo library · not uploaded yet';

  @override
  String get autoSaveBannerOpen => 'See and choose';

  @override
  String get autoSaveBannerLater => 'Later';

  @override
  String get autoSaveTabDot => 'New photos to review';

  @override
  String get autoSaveDiagTitle => 'Diagnostics (dev build)';

  @override
  String autoSaveDiagHow(String how, int count) {
    return 'Last check: $how · $count files';
  }

  @override
  String get autoSaveDiagHistory => 'items added to the library';

  @override
  String get autoSaveDiagByDate => 'by date';

  @override
  String get autoSaveDiagNone => 'No check since the app opened.';

  @override
  String autoSaveDiagMatch(String d, String t) {
    return 'Suggested · $d ≤ $t';
  }

  @override
  String autoSaveDiagFar(String d, String t) {
    return 'Not like the baby · $d > $t';
  }

  @override
  String get autoSaveDiagNegative => 'Like a photo marked “Not my baby”';

  @override
  String get autoSaveDiagNoFace => 'No face found';

  @override
  String get autoSaveDiagSmall => 'Face too small';

  @override
  String get autoSaveDiagUtility => 'Looks like a document or screenshot';

  @override
  String get autoSaveDiagUnreadable => 'Could not read it';

  @override
  String get autoSaveDiagHandled => 'Already uploaded or skipped';

  @override
  String get autoSaveDiagRescan => 'Check the last 30 days again';

  @override
  String get ksCardTitle => 'Milestone cards';

  @override
  String get ksChooseOccasion => 'Choose the occasion';

  @override
  String get ksSuggested => 'Suggested';

  @override
  String get ksOccD7 => '7 days';

  @override
  String get ksOccM1 => '1 month';

  @override
  String get ksOccD100 => '100 days';

  @override
  String get ksOccFirstSmile => 'First smile';

  @override
  String get ksOccRollsOver => 'First roll';

  @override
  String get ksOccCrawls => 'Crawling';

  @override
  String get ksOccFirstSteps => 'First steps';

  @override
  String get ksOccY1 => 'First birthday';

  @override
  String get ksTitleY1 => '1 year';

  @override
  String get ksQuoteD7 => 'Our first seven days';

  @override
  String get ksQuoteM1 => 'A month of love';

  @override
  String get ksQuoteD100 => 'A hundred happy days';

  @override
  String get ksQuoteFirstSmile => 'Your very first smile';

  @override
  String get ksQuoteRollsOver => 'Look who rolled over!';

  @override
  String get ksQuoteCrawls => 'Off to explore!';

  @override
  String get ksQuoteFirstSteps => 'Your first steps';

  @override
  String get ksQuoteY1 => 'A year of love';

  @override
  String get ksFormatPortrait => 'Portrait 4:5';

  @override
  String get ksFormatSquare => 'Square';

  @override
  String get ksFormatStory => 'Story 9:16';

  @override
  String get ksPremium => 'Premium';

  @override
  String get ksNoTemplates => 'No card templates yet';

  @override
  String get ksNoTemplatesBody =>
      'New templates are coming soon. Check back later.';

  @override
  String get ksLoadFailed => 'Couldn’t load the templates';

  @override
  String get ksUnavailableTitle => 'Not available for your family yet';

  @override
  String get ksUnavailableBody =>
      'Milestone cards are in beta and coming to every family soon.';

  @override
  String get ksPreview => 'Preview';

  @override
  String get ksPhotoHint => 'Tap to change · drag to position';

  @override
  String get ksChoosePhoto => 'Choose a photo';

  @override
  String get ksToolPhoto => 'Photo';

  @override
  String get ksToolLayout => 'Layout';

  @override
  String get ksToolMessage => 'Message';

  @override
  String get ksToolColor => 'Colour';

  @override
  String get ksFromDevice => 'Phone library';

  @override
  String get ksMessageLabel => 'Message on the card';

  @override
  String get ksSaveCard => 'Save card';

  @override
  String get ksSaveFailed => 'Couldn’t save the card. Please try again.';

  @override
  String get ksCardReady => 'Your card is ready!';

  @override
  String get ksSavedParents => 'Saved to Memories · Parents only';

  @override
  String get ksExport => 'Export as';

  @override
  String get ksSaveDevice => 'Save to phone';

  @override
  String get ksShare => 'Share';

  @override
  String get ksSavedToDevice => 'Saved to your phone';

  @override
  String get ksEditAgain => 'Edit card';

  @override
  String ksPrefilled(String name) {
    return 'Name, age and date are filled in from $name’s profile';
  }

  @override
  String ksCreateFrom(String name) {
    return 'Make something from $name’s memories';
  }

  @override
  String get ksSeeTemplates => 'See templates';

  @override
  String get ksNew => 'New';

  @override
  String get ksCardTileHint => 'A PNG picture to share';

  @override
  String get ksCardTileHintShort => 'A picture to share';

  @override
  String get ksCreateGroup => 'CREATE & AUTOMATE';

  @override
  String get ksCardBadge => 'Card';

  @override
  String get ksStoriesSection => 'Family stories';

  @override
  String ksCardCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String ksNudgeSoon(String name, String occasion) {
    return '$name turns $occasion soon! Let’s make something lovely.';
  }

  @override
  String ksNudgeToday(String name, String occasion) {
    return '$name is $occasion today! Let’s make something lovely.';
  }

  @override
  String ksNudgeJust(String name, String occasion) {
    return '$name just turned $occasion! Keep it with a card.';
  }

  @override
  String ksNudgeFirst(String name, String occasion) {
    return '$name’s $occasion! Make a card to remember it.';
  }

  @override
  String ksThisWeekday(String weekday, String day) {
    return 'This $weekday · $day';
  }

  @override
  String get ksToday => 'Today';

  @override
  String get ksTomorrow => 'Tomorrow';

  @override
  String get ksMakeCard => 'Make a card';

  @override
  String get ksLater => 'Later';

  @override
  String ksNudgeTodayTitle(String name, String occasion) {
    return '$name is $occasion today 🎂';
  }

  @override
  String get ksNudgeTodayBody => 'Make a lovely card to remember it.';

  @override
  String ksNudgeBackAgeTitle(String name, String occasion) {
    return 'Look back: $name at $occasion';
  }

  @override
  String ksNudgeBackFirstTitle(String name, String occasion) {
    return 'Look back: $name’s $occasion';
  }

  @override
  String ksNudgeBackBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos from it are in Memories. Make a card?',
      one: '1 photo from it is in Memories. Make a card?',
    );
    return '$_temp0';
  }

  @override
  String get ksVideoTitle => 'Memory video';

  @override
  String get ksVideoTileHint => 'Photos + words + music';

  @override
  String ksVideoNeeds(int min, int max) {
    return 'Needs $min–$max photos';
  }

  @override
  String get ksUnavailableBodyVideo =>
      'Memory videos are in beta and coming to every family soon.';

  @override
  String get ksFromMemories => 'From Memories';

  @override
  String get ksVideoPhotosTitle => 'Choose photos for the video';

  @override
  String ksVideoScenesFilled(int n, int total) {
    return '$n/$total scenes have a photo';
  }

  @override
  String ksVideoMinimum(int n) {
    return 'At least $n';
  }

  @override
  String ksVideoScene(int n, String hint) {
    return 'Scene $n: $hint';
  }

  @override
  String ksVideoSceneN(int n) {
    return 'Scene $n';
  }

  @override
  String get ksVideoSceneOptionalTag => 'Optional';

  @override
  String ksVideoForScene(int n, String hint) {
    return 'For scene $n · $hint';
  }

  @override
  String ksVideoSceneWindow(String from, String to) {
    return 'Photos taken $from – $to';
  }

  @override
  String get ksVideoSceneAny => 'Any photo fits; newest first';

  @override
  String get ksVideoSceneEmpty =>
      'No photos from this time yet. Pick one from Other photos below or add one from your phone.';

  @override
  String get ksVideoSceneEmptyOptional =>
      'No photos from this time yet. This scene is optional, so you can leave it empty.';

  @override
  String get ksVideoOtherPhotos => 'Other photos';

  @override
  String ksVideoClearScene(int n) {
    return 'Remove the photo from scene $n';
  }

  @override
  String ksVideoPicked(int n) {
    return '$n photos chosen';
  }

  @override
  String ksVideoCanAdd(int n) {
    return '$n more allowed';
  }

  @override
  String ksVideoNeedMore(int n) {
    return '$n more needed';
  }

  @override
  String ksVideoNotEnough(String name, int have, int need) {
    return '$name’s Memories have only $have suitable photos. This template needs at least $need.';
  }

  @override
  String get ksVideoMoreFromDevice => 'Add more from the phone';

  @override
  String get ksVideoMoreFromDeviceHint => 'Only the photos you pick are used';

  @override
  String get ksVideoShorter => 'Switch to a shorter template';

  @override
  String ksVideoShorterHint(String name, int n) {
    return '“$name” · needs $n photos';
  }

  @override
  String ksVideoImporting(int n) {
    return 'Adding $n photos to Memories (parents only). They are picked once uploaded.';
  }

  @override
  String get ksVideoFinishTitle => 'Finish the video';

  @override
  String get ksVideoPrefilled => 'Filled in from the baby’s profile';

  @override
  String get ksVideoBaby => 'Baby';

  @override
  String get ksVideoDay => 'Day';

  @override
  String get ksVideoFieldTitle => 'Title';

  @override
  String get ksVideoFieldMessage => 'Closing message';

  @override
  String ksVideoOrder(int n) {
    return '$n photos · in order';
  }

  @override
  String get ksVideoReorderHint => 'Hold and drag to reorder';

  @override
  String get ksVideoAddPhotos => 'Add photos';

  @override
  String get ksVideoMusic => 'Music';

  @override
  String get ksVideoMusicTemplate => 'The template’s music';

  @override
  String get ksVideoMusicNone => 'No music for this template yet';

  @override
  String get ksVideoWho => 'Who can see';

  @override
  String get ksVideoWhoParents => 'Parents only · saved to Memories';

  @override
  String get ksVideoWhoFamily => 'Family · saved to Memories';

  @override
  String get ksAudienceParents => 'Parents only';

  @override
  String get ksAudienceFamily => 'Family';

  @override
  String get ksVideoCreate => 'Make the video';

  @override
  String get ksVideoTakes => 'About 1–2 minutes · you can leave this screen';

  @override
  String get ksVideoErrBusy =>
      'A video is already being made for your baby. Try again when it’s done.';

  @override
  String get ksVideoErrDaily =>
      'Your family has made many videos today. Try again tomorrow.';

  @override
  String get ksVideoErrQuota =>
      'Your family’s storage is almost full. Free some up first.';

  @override
  String get ksVideoErrPhoto =>
      'A photo was removed or is still uploading. Choose again.';

  @override
  String get ksVideoErrTemplate =>
      'This template has just changed. Choose it again.';

  @override
  String ksVideoMaking(String name) {
    return 'Making $name’s video…';
  }

  @override
  String get ksVideoMakingBody =>
      'Usually 1–2 minutes. You can leave this screen; Child Life will tell you when it’s ready.';

  @override
  String ksVideoStepArrange(int n) {
    return 'Arranging $n photos';
  }

  @override
  String get ksVideoStepCompose => 'Adding words, message and music';

  @override
  String get ksVideoStepExport => 'Exporting the 9:16 video';

  @override
  String get ksVideoBackToMemories => 'Back to Memories';

  @override
  String get ksLiveQueued => 'Waiting to make your video';

  @override
  String get ksLiveArrange => 'Arranging the photos';

  @override
  String get ksLiveCompose => 'Adding words and music';

  @override
  String get ksLiveExport => 'Exporting the video';

  @override
  String get ksLiveReadySub => 'Tap to watch, save and share';

  @override
  String get ksLiveFailedSub => 'Tap to try again';

  @override
  String ksVideoActive(int percent) {
    return 'Making your video · $percent%';
  }

  @override
  String get ksVideoActiveQueued => 'Waiting to make your video';

  @override
  String get ksVideoReadyToast => 'Your memory video is ready';

  @override
  String get ksVideoFailedToast => 'Your memory video couldn’t be made';

  @override
  String get ksVideoOpenJob => 'View';

  @override
  String get ksVideoDeleteDraft => 'Delete draft';

  @override
  String get ksVideoDeleteDraftTitle => 'Delete this video draft?';

  @override
  String get ksVideoDeleteDraftBody =>
      'Your baby’s photos stay in Memories; only this video draft is deleted.';

  @override
  String get ksVideoDraftDeleted => 'Draft deleted';

  @override
  String get ksTabCards => 'Cards';

  @override
  String get ksTabVideos => 'Videos';

  @override
  String get ksVideoReady => 'Your video is ready!';

  @override
  String get ksVideoSaved => 'Saved to Memories';

  @override
  String get ksVideoFiling => 'Saving to Memories…';

  @override
  String ksVideoWeek(int n) {
    return 'Week $n';
  }

  @override
  String get ksVideoWatch => 'Watch the video';

  @override
  String get ksVideoOpen => 'See in Memories';

  @override
  String ksVideoAlsoCard(String occasion) {
    return 'Also make a “$occasion” card';
  }

  @override
  String get ksVideoAlsoCardHint => 'Reuse these photos';

  @override
  String get ksVideoFailed => 'Couldn’t make the video';

  @override
  String get ksVideoFailedNetwork =>
      'The connection dropped while exporting. Your photos, words and message are kept.';

  @override
  String get ksVideoFailedBusy =>
      'Our server was busy and couldn’t finish. Your photos, words and message are kept.';

  @override
  String get ksVideoFailedPhoto =>
      'A photo was removed from Memories. Edit your choices to make the video.';

  @override
  String get ksVideoEditChoices => 'Edit choices';

  @override
  String get ksVideoDraftNote => 'The draft is kept in Stories · Drafts';

  @override
  String get ksMakeVideo => 'Make a video';

  @override
  String ksMakeVideoFor(String occasion) {
    return 'Make a $occasion video';
  }

  @override
  String get ksVideoDraftTile => 'Draft';

  @override
  String get ksVideoContinue => 'Continue';

  @override
  String ksVideoInProgress(int p) {
    return 'Making · $p%';
  }

  @override
  String get ksBannerView => 'View';

  @override
  String ksVideoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String get careDevelop => 'Understanding your baby';

  @override
  String get careKnowledge => 'Baby-care know-how';

  @override
  String get utTools => 'Tools';

  @override
  String get ksPreviewSample => 'Play the template';

  @override
  String get ksPreviewNote =>
      'This preview plays on your phone. The real video is made at 1080×1920 after “Make the video”.';

  @override
  String get ksPreviewFailed =>
      'Couldn’t open the preview. Check your connection and try again.';

  @override
  String get ksMusicNone => 'No music';

  @override
  String get ksMusicDefault => 'Template default';

  @override
  String get ksMusicStop => 'Stop listening';

  @override
  String get ksMusicNote =>
      'Licensed music chosen by Child Life. You can change the track any time before creating the video.';

  @override
  String get ksPreviewVideoNote =>
      'This sample uses illustration photos. Your video uses the photos and words you choose.';

  @override
  String ksMusicListen(String title) {
    return 'Listen to $title';
  }

  @override
  String get ksOccBirth => 'Birth';

  @override
  String get ksOccLaughs => 'First laugh';

  @override
  String get ksOccSitsUp => 'Sits up';

  @override
  String get ksOccStands => 'Stands up';

  @override
  String get ksOccFirstTooth => 'First tooth';

  @override
  String get ksOccFirstSolids => 'First meal';

  @override
  String get ksOccFirstWord => 'First word';

  @override
  String get ksAchieveRollsOver => 'I rolled over!';

  @override
  String get ksAchieveSitsUp => 'I can sit up!';

  @override
  String get ksAchieveCrawls => 'I can crawl!';

  @override
  String get ksAchieveStands => 'I can stand!';

  @override
  String get ksAchieveFirstSteps => 'I took my first steps!';

  @override
  String get ksAchieveAny => 'Look what I can do!';

  @override
  String get ksQuoteBirth => 'Welcome to the world';

  @override
  String get ksQuoteLaughs => 'Giggles all day';

  @override
  String get ksQuoteSitsUp => 'Sitting tall!';

  @override
  String get ksQuoteStands => 'Standing strong!';

  @override
  String get ksQuoteFirstTooth => 'A tiny new smile';

  @override
  String get ksQuoteFirstSolids => 'Yum, first bites!';

  @override
  String get ksQuoteFirstWord => 'You said our names!';

  @override
  String get ksLabelFirstDay => 'Day 1';

  @override
  String get ksLabelThen => 'Then';

  @override
  String get ksLabelNow => 'Now';

  @override
  String ksOccMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String ksQuoteMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: 'One month',
    );
    return '$_temp0 of love';
  }

  @override
  String ksAgeDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String ksAgeWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String ksAgeMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String ksAgeYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String ksUnitDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String ksUnitWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String ksUnitMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String ksUnitYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String ksLabelDay(int n) {
    return 'Day $n';
  }

  @override
  String ksLabelWeek(int n) {
    return 'Week $n';
  }

  @override
  String ksLabelMonth(int n) {
    return 'Month $n';
  }

  @override
  String ksLabelYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Year $n',
      one: 'Year 1',
    );
    return '$_temp0';
  }

  @override
  String ksBirthStats(String weight, String length) {
    return '$weight kg · $length cm';
  }

  @override
  String ksBirthWeight(String weight) {
    return '$weight kg';
  }

  @override
  String ksBirthLength(String length) {
    return '$length cm';
  }

  @override
  String get ksVideoFieldHeadline => 'Headline';

  @override
  String get ksVideoFieldLines => 'A line for each photo (one per line)';

  @override
  String get ksVideoFieldLetter => 'Letter to your baby';

  @override
  String get ksVideoFieldClosing => 'Closing line';

  @override
  String get ksUseTemplate => 'Use this template';

  @override
  String get ksInfoPhotos => 'Photos';

  @override
  String get ksInfoFormat => 'Format';

  @override
  String get ksInfoOccasion => 'Occasion';

  @override
  String get ksInfoDuration => 'Length';

  @override
  String get ksInfoPalettes => 'Colours';

  @override
  String get ksAnyOccasion => 'Any occasion';

  @override
  String ksPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String ksPhotosRange(int min, int max) {
    return '$min–$max photos';
  }

  @override
  String ksPalettesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colour sets',
      one: '1 colour set',
    );
    return '$_temp0';
  }

  @override
  String get pmBadgePremium => 'Premium';

  @override
  String get pmBadgeBeta => 'Beta';

  @override
  String get pmBadgeFree => 'Basic';

  @override
  String get pmBadgePending => 'Verifying';

  @override
  String get pmBadgeExpired => 'Expired';

  @override
  String get pmPlanTitle => 'Household plan';

  @override
  String get pmPlanFree => 'On the Basic plan';

  @override
  String get pmPlanFreeBody =>
      'Logging, reference calendar, basic templates, health guidance.';

  @override
  String get pmPlanBeta => 'Personalisation beta active';

  @override
  String pmPlanBetaBody(String date) {
    return 'Need-based suggestions, your baby\'s own rhythm and AI summaries are free until $date. Premium templates aren\'t included. No automatic charge when the beta ends.';
  }

  @override
  String get pmPlanPremium => 'Child Life Premium';

  @override
  String pmPlanRenews(String date) {
    return 'Renews $date';
  }

  @override
  String pmPlanEnds(String date) {
    return 'Active until $date · renewal off';
  }

  @override
  String get pmPlanShared =>
      'Everyone in the family sees “Household has Premium”. Only the family owner manages it.';

  @override
  String get pmPlanHouseholdHas => 'Household has Premium';

  @override
  String get pmPlanPending => 'Verifying purchase';

  @override
  String get pmPlanPendingBody =>
      'No new access yet; your data and selections are kept.';

  @override
  String pmPlanExpired(String date) {
    return 'Premium ended $date';
  }

  @override
  String get pmPlanExpiredBody =>
      'You keep data, saved summaries, moments and exports. Creating new Premium content needs renewal.';

  @override
  String get pmPlanBuySoon =>
      'Buying and managing the plan in the app comes in a later version.';

  @override
  String get pmPlanOwnerOnly =>
      'Only the family owner buys and manages the plan. Ask them if the family needs Premium.';

  @override
  String get pmPlanAlwaysFree => 'In every plan';

  @override
  String get pmPlanAlwaysFreeBody =>
      'Logging, history, reminders, reference calendar, health guidance and everything saved.';

  @override
  String get pmRegionRow => 'Household region';

  @override
  String get pmRegionUnset => 'Not set';

  @override
  String get pmRegionTitle => 'Where does your family live?';

  @override
  String get pmRegionBody =>
      'Used to pick the emergency number, vaccination schedule and health content for where you live. Child Life never guesses it from language or location.';

  @override
  String get pmRegionOwnerOnly => 'The family owner sets the household region.';

  @override
  String get pmRegionSaved => 'Region saved';

  @override
  String get meRegionRow => 'Where your family lives';

  @override
  String get pmCountryVN => 'Vietnam';

  @override
  String get pmCountryUS => 'United States';

  @override
  String get pmCountryGB => 'United Kingdom';

  @override
  String get pmCountryAU => 'Australia';

  @override
  String get pmCountryCA => 'Canada';

  @override
  String get pmCountrySG => 'Singapore';

  @override
  String get pmCountryNZ => 'New Zealand';

  @override
  String get pmCountryDE => 'Germany';

  @override
  String get pmCountryFR => 'France';

  @override
  String get pmCountryJP => 'Japan';

  @override
  String get pmCountryKR => 'South Korea';

  @override
  String get pmCountryTW => 'Taiwan';

  @override
  String get pmCountryMY => 'Malaysia';

  @override
  String get pmCountryTH => 'Thailand';

  @override
  String get pmCountryHK => 'Hong Kong';

  @override
  String get pmCountryCN => 'China';

  @override
  String get pmCountryIE => 'Ireland';

  @override
  String get pmCountryNL => 'Netherlands';

  @override
  String get pmCountryBE => 'Belgium';

  @override
  String get pmCountryES => 'Spain';

  @override
  String get pmCountryCH => 'Switzerland';

  @override
  String get pmCountryAT => 'Austria';

  @override
  String get pmCountryCZ => 'Czechia';

  @override
  String get pmCountryPL => 'Poland';

  @override
  String get pmCountrySE => 'Sweden';

  @override
  String get pmCountryNO => 'Norway';

  @override
  String get pmCountryDK => 'Denmark';

  @override
  String get pmCountryFI => 'Finland';

  @override
  String get pmCountryAE => 'United Arab Emirates';

  @override
  String get pmCountryQA => 'Qatar';

  @override
  String get pmUnlockPremium => 'Unlock with Premium';

  @override
  String get pmUseFreeTemplate => 'Use a basic template';

  @override
  String get pmCardNoQuota => 'Premium cards don’t use video export quota';

  @override
  String get pmTemplatePremiumBody =>
      'This template is for families with Child Life Premium.';

  @override
  String get pmTemplateBetaNote =>
      'Your current beta doesn’t include Premium templates.';

  @override
  String get pmGateRoleTitle => 'Needs a parent role';

  @override
  String get pmGateRoleBody =>
      'Premium doesn’t change roles. Creating cards, AI summaries or editing notes needs a parent role.';

  @override
  String get pmGateRegionTitle =>
      'Personalised support isn’t available in your region yet';

  @override
  String get pmGateRegionBody =>
      'Health content for your region isn’t approved yet. Logging, reference calendar, Moments and basic templates work as usual.';

  @override
  String get pmGateRegionAction => 'Change region in household profile';

  @override
  String get pmGateDisabledTitle => 'This feature is paused';

  @override
  String get pmGateDisabledBody =>
      'Logging, basic content and health guidance keep working.';

  @override
  String get pmGateQuotaTitle => 'No exports left this period';

  @override
  String get pmGateQuotaBody =>
      'You can still browse templates and make photo cards.';

  @override
  String get pmGateConsentTitle => 'AI needs your consent';

  @override
  String get pmGateConsentBody =>
      'The template summary still works without AI.';

  @override
  String get pmGateNotMemberTitle => 'You’re no longer in this family';

  @override
  String get pmGateOk => 'Got it';

  @override
  String get rhSectionForYou => 'For your baby today';

  @override
  String get rhSectionForYouSub =>
      'Suggestions, age content and reference calendar';

  @override
  String get rhReviewPending =>
      'Written from WHO, AAP and NHS guidance · For reference, not a substitute for a doctor';

  @override
  String rhReviewedBy(String reviewer, String credential) {
    return 'Reviewed by $reviewer · $credential';
  }

  @override
  String rhJoinTwo(String a, String b) {
    return '$a and $b';
  }

  @override
  String rhQuoted(String text) {
    return '“$text”';
  }

  @override
  String get rhWhoYou => 'you';

  @override
  String rhDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get rhDone => 'Done';

  @override
  String get rhContinue => 'Continue';

  @override
  String get rhRetry => 'Try again';

  @override
  String get rhSources => 'Sources';

  @override
  String get rhObsSleep => 'Hard to settle / waking more';

  @override
  String get rhObsFeeding => 'Feeding seems different';

  @override
  String get rhObsSoothing => 'Needs more soothing';

  @override
  String get rhObsNewSkill => 'Something new';

  @override
  String get rhObsUsual => 'Same as usual';

  @override
  String get rhObsHealth => 'I’m worried about health';

  @override
  String get rhObsShortSleep => 'Hard to settle';

  @override
  String get rhObsShortFeeding => 'Feeding different';

  @override
  String get rhObsShortSoothing => 'Needs more soothing';

  @override
  String get rhObsShortNewSkill => 'Something new';

  @override
  String get rhObsShortUsual => 'Same as usual';

  @override
  String get rhObsShortHealth => 'Health worry';

  @override
  String rhWhatSleep(String baby) {
    return '$baby struggled to settle';
  }

  @override
  String rhWhatFeeding(String baby) {
    return '$baby was feeding differently';
  }

  @override
  String rhWhatSoothing(String baby) {
    return '$baby needed more soothing';
  }

  @override
  String rhWhatNewSkill(String baby) {
    return '$baby did something new';
  }

  @override
  String rhWhatOther(String baby) {
    return 'what $baby needs';
  }

  @override
  String get rhWhenToday => 'today';

  @override
  String get rhWhenLastNight => 'last night';

  @override
  String get rhWhenYesterday => 'yesterday';

  @override
  String rhWhenOn(String date) {
    return 'on $date';
  }

  @override
  String rhReasonNoted(String when, String who, String what) {
    return 'Because $who noted $when that $what.';
  }

  @override
  String rhReasonHelpful(String who) {
    return '$who rated this “Helpful” last time.';
  }

  @override
  String rhReasonData(String baby) {
    return 'Because the log shows $baby’s sleep has been different from usual lately.';
  }

  @override
  String rhReasonAge(String baby) {
    return 'Because it fits $baby’s age.';
  }

  @override
  String get rhReasonInterest => 'Because you follow this topic.';

  @override
  String rhReasonFallback(String baby) {
    return 'Because your family noted what $baby needs.';
  }

  @override
  String rhAgeHeading(String baby) {
    return '$baby’s week';
  }

  @override
  String get rhAgeFree => 'Age-based content';

  @override
  String get rhCalendarPill => 'REFERENCE CALENDAR';

  @override
  String rhStageName(int n) {
    return 'Wonder Weeks stage $n';
  }

  @override
  String rhStageExpected(String stage, String range) {
    return '$stage expected $range';
  }

  @override
  String rhStageNow(String stage, String range) {
    return '$stage · $range · reference';
  }

  @override
  String get rhSupportTitle => 'Support that fits your baby';

  @override
  String get rhSupportBody =>
      'One next step based on what your family logs, remembers what helped, and a handover for the next carer.';

  @override
  String get rhLearnMore => 'Learn more';

  @override
  String get rhKickerToday => 'ONE THING TO TRY TODAY';

  @override
  String get rhKickerTonight => 'ONE THING FOR TONIGHT';

  @override
  String get rhTryToday => 'Try today';

  @override
  String get rhTryTonight => 'Try tonight';

  @override
  String get rhTryAgainToday => 'Do it again today';

  @override
  String get rhTryAgainTonight => 'Do it again tonight';

  @override
  String get rhNotToday => 'Not today';

  @override
  String get rhSomethingElse => 'Something else';

  @override
  String get rhBasedOnFeedback => 'Based on your feedback';

  @override
  String rhFeedbackUsedEvening(
    String date,
    String who,
    String kind,
    String title,
  ) {
    return 'On $date $who marked “$title” as $kind';
  }

  @override
  String rhFeedbackUsedDay(String date, String who, String kind, String title) {
    return 'On $date $who marked “$title” as $kind';
  }

  @override
  String get rhChangedTitle => 'What changed';

  @override
  String get rhChangePrefersHelpful =>
      'Prioritises what helped over a new idea';

  @override
  String get rhChangeExcluded =>
      'Ideas marked “Not a fit” aren’t suggested again';

  @override
  String get rhChangeCooling => 'Ideas put off rest for a few days';

  @override
  String get rhCheckInEntry => 'Anything different today?';

  @override
  String get rhStartedLabel => 'Trying';

  @override
  String get rhHealthCardTitle => 'A sign that needs attention was noted today';

  @override
  String get rhHealthCardBody =>
      'Calendar suggestions are paused. See guidance and how to get help.';

  @override
  String get rhHealthCardAction => 'See health guidance';

  @override
  String get rhPutOffToast => 'Put off. This idea rests for a few days.';

  @override
  String get rhCheckInTitle => 'What’s different today?';

  @override
  String get rhCheckInSubtitle =>
      'Pick one thing you noticed. No need to answer everything.';

  @override
  String get rhUsualSaved => 'Saved: a usual day';

  @override
  String get rhMoreTitle => 'A little more so the suggestion fits';

  @override
  String get rhSkipQuestions => 'Skip questions';

  @override
  String get rhQWhen => 'When?';

  @override
  String get rhWhenNightSleep => 'Night sleep';

  @override
  String get rhWhenDaySleep => 'Naps';

  @override
  String get rhWhenNight => 'At night';

  @override
  String get rhWhenDay => 'In the day';

  @override
  String get rhWhenBoth => 'Both';

  @override
  String get rhQSince => 'Since when?';

  @override
  String get rhSinceToday => 'Today';

  @override
  String get rhSince23 => '2–3 days';

  @override
  String get rhSinceLonger => 'Longer';

  @override
  String get rhQTried => 'Tried anything? (optional)';

  @override
  String get rhTriedRocking => 'Rocking';

  @override
  String get rhTriedWhiteNoise => 'White noise';

  @override
  String get rhTriedFeeding => 'Feeding';

  @override
  String get rhTriedSkin => 'Skin-to-skin';

  @override
  String get rhTriedSwaddle => 'Swaddling';

  @override
  String get rhTriedNone => 'Not yet';

  @override
  String get rhSumNightSleep => 'night';

  @override
  String get rhSumDaySleep => 'naps';

  @override
  String get rhSumNight => 'at night';

  @override
  String get rhSumDay => 'in the day';

  @override
  String get rhSumBoth => 'day and night';

  @override
  String get rhSumToday => 'today';

  @override
  String get rhSumLonger => 'longer';

  @override
  String rhFromLogSleep(String duration, String who) {
    return 'From the log: last night’s sleep was logged as $duration ($who). No need to re-enter.';
  }

  @override
  String rhFromLogFeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return 'From the log: $_temp0 logged today. No need to re-enter.';
  }

  @override
  String get rhNewSkillLabel => 'What’s new?';

  @override
  String get rhNewSkillHint => 'e.g. rolled over for the first time';

  @override
  String get rhSaveToMilestones => 'Save to Milestones';

  @override
  String get rhSaveNote => 'Save note';

  @override
  String get rhAlwaysFree => 'Shared with your family';

  @override
  String get rhHealthQHeading => 'Today’s note';

  @override
  String get rhHealthQTitle => 'Before you continue';

  @override
  String rhHealthQAsk(String baby) {
    return 'Does $baby have any of these signs?';
  }

  @override
  String get rhHealthQHelper =>
      'If so, Child Life pauses calendar suggestions and shows only guidance for getting help.';

  @override
  String get rhHealthUnsureHint =>
      'If you’re not sure, ask your baby’s doctor.';

  @override
  String get rhAnswerYes => 'Yes';

  @override
  String get rhAnswerNo => 'No';

  @override
  String get rhAnswerUnsure => 'Not sure';

  @override
  String get rhSignFeverYoung => 'Fever (baby under 3 months)';

  @override
  String get rhSignBreathing => 'Hard breathing, chest pulling in';

  @override
  String get rhSignLethargic => 'Floppy or hard to wake';

  @override
  String get rhSignPoorFeeding => 'Feeding very little or refusing feeds';

  @override
  String get rhSignInconsolable => 'Crying that can’t be soothed';

  @override
  String get rhSignLostSkill => 'Lost a skill they had';

  @override
  String get rhSignDehydration => 'Few wet nappies, dry lips';

  @override
  String get rhSignSeizure => 'Seizure (fit)';

  @override
  String get rhHlTitle => 'Consider contacting medical help';

  @override
  String get rhHlBody =>
      'You flagged a sign that needs attention. Child Life pauses calendar suggestions and shows no paid content here.';

  @override
  String get rhHlNoted => 'You noted';

  @override
  String rhHlCallEmergency(String number) {
    return 'Call emergency $number';
  }

  @override
  String get rhHlCallDoctor => 'Call your baby’s doctor';

  @override
  String get rhHlHelper =>
      'The emergency number follows the household’s country of residence. Where none is listed, only the doctor button shows.';

  @override
  String get rhHlNoRegion =>
      'There’s no approved emergency number for your household’s region yet. If your baby shows danger signs, call your local emergency services.';

  @override
  String get rhHlWhileWaiting => 'While you wait';

  @override
  String get rhHlDisclaimer =>
      'Child Life doesn’t diagnose and never concludes “safe”.';

  @override
  String get rhHlAlwaysFree => 'No paywall, no upsell';

  @override
  String get rhHlDialFailed => 'Couldn’t open the Phone app.';

  @override
  String get rhSavedTitle => 'Note saved';

  @override
  String rhSeenBy(String names) {
    return '$names will see it';
  }

  @override
  String get rhSeenByOnlyYou => 'Only you can see it';

  @override
  String get rhOneThing => 'One thing you could try';

  @override
  String rhDurationFit(String duration, String range) {
    return '$duration · fits $range';
  }

  @override
  String rhMonthsRange(int from, int to) {
    return '$from–$to months';
  }

  @override
  String get rhWhyThis => 'Why this';

  @override
  String rhWhyJustNoted(String summary) {
    return 'You just noted $summary.';
  }

  @override
  String rhWhyTriedOther(String tried) {
    return '$tried was already tried, so this is a different approach.';
  }

  @override
  String get rhWhyHelpedBefore => 'This was rated “Helpful” before.';

  @override
  String rhWhyData(String recent, String baseline) {
    return 'From the log: total sleep logged lately is about $recent a day; the usual is $baseline.';
  }

  @override
  String get rhLater => 'Later';

  @override
  String rhSeeRhythm(String baby) {
    return 'See $baby’s rhythm';
  }

  @override
  String get rhMoreForAge => 'More for this age';

  @override
  String get rhFreeAgePill => 'Age-based';

  @override
  String rhReadMinutes(int n) {
    return '$n-min read';
  }

  @override
  String get rhUpsellTitle => 'Want a suggestion for this exact situation?';

  @override
  String get rhUpsellBody =>
      'Support that fits your baby picks one step from your family’s notes and remembers what helped.';

  @override
  String get rhLearnMoreOptional => 'Learn more (optional)';

  @override
  String get rhNoSuggestionTitle => 'No suitable suggestion yet';

  @override
  String get rhNoSuggestionBody =>
      'Your note is saved. When something fits, it shows on Today.';

  @override
  String get rhSeeAgeContent => 'See age-based content';

  @override
  String get rhOfflineTitle => 'Notes still save on this device';

  @override
  String get rhOfflineBody =>
      'They’ll sync when online. New suggestions need a connection and will show on Today later.';

  @override
  String get rhErrorTitle => 'Couldn’t get a suggestion yet';

  @override
  String get rhErrorBody => 'Your note is saved. Try again in a moment.';

  @override
  String get rhLoadingSuggestion => 'Finding one thing to try…';

  @override
  String get rhNotTried => 'Not tried yet';

  @override
  String rhTriedOn(String date) {
    return 'Tried · $date';
  }

  @override
  String rhSuggestionEyebrow(String duration) {
    return 'Suggestion · $duration';
  }

  @override
  String rhBecauseNoted(String summary, String who, String date) {
    return 'Because: $summary ($who, $date)';
  }

  @override
  String get rhHow => 'How';

  @override
  String get rhWhyItMayHelp => 'Why it may help';

  @override
  String get rhSafety => 'Safety';

  @override
  String get rhIllTry => 'I’ll try this';

  @override
  String get rhNotRight => 'Not right for my baby';

  @override
  String get rhAnotherIdea => 'Another idea';

  @override
  String get rhTellHow => 'Tell us how it went';

  @override
  String get rhStartedToast => 'Good luck! Tell us how it went afterwards.';

  @override
  String get rhNotRightToast =>
      'Noted. This won’t be suggested for your baby again.';

  @override
  String get rhActivityMissing => 'This suggestion is no longer available';

  @override
  String get rhHowLastNight => 'How did last night go?';

  @override
  String get rhHowDidItGo => 'How did it go?';

  @override
  String get rhHelpful => 'Helpful';

  @override
  String get rhUnsure => 'Not sure';

  @override
  String get rhNotAFit => 'Not a fit';

  @override
  String get rhNoteHint => 'Note (optional)';

  @override
  String get rhFeedbackInfo =>
      'This feedback shapes your next suggestion. “Helpful” doesn’t mean this caused the change.';

  @override
  String get rhSaveFeedback => 'Save feedback';

  @override
  String get rhFeedbackSaved => 'Feedback saved';

  @override
  String get rhAgeTips => 'Things to try';

  @override
  String get rhAgeWatch => 'When to ask a doctor';

  @override
  String get rhAgeEach =>
      'Every baby is different. This is what many families notice at this age, not a schedule.';

  @override
  String get rhSaveFailed =>
      'Couldn’t save the note. Your access may have changed.';

  @override
  String get rhTitle => 'Growing rhythm';

  @override
  String rhBabyAge(String baby, String age) {
    return '$baby · $age';
  }

  @override
  String get rhCalendarUnsetPill => 'REFERENCE CALENDAR · not set up';

  @override
  String get rhCalendarUnsetTitle =>
      'Add the due date to see the reference calendar';

  @override
  String rhCalendarUnsetBody(String baby) {
    return 'Without a due date you can still check in and see content for $baby’s actual age.';
  }

  @override
  String get rhAddDueDate => 'Add due date';

  @override
  String get rhDontRemember => 'Don’t remember';

  @override
  String get rhCalendarUnsetOthers =>
      'A co-parent can add the due date to open the reference calendar.';

  @override
  String get rhCalendarNoAccess =>
      'The reference calendar counts from the due date, part of the baby’s details you can’t see.';

  @override
  String get rhCalendarNoModel => 'The reference calendar isn’t published yet.';

  @override
  String get rhSeeCalendar => 'See calendar';

  @override
  String rhStageComingN(int n) {
    return 'Wonder Weeks stage $n coming up';
  }

  @override
  String rhStageInN(int n) {
    return 'Within Wonder Weeks stage $n';
  }

  @override
  String rhStageExpectedLine(String range, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Expected $range · $_temp0 to go';
  }

  @override
  String rhStageNowLine(String range) {
    return 'Expected $range · within the reference window';
  }

  @override
  String get rhStagesDone => 'All stages of the reference calendar have passed';

  @override
  String get rhCalendarDisclaimer =>
      'This is an expected window from the reference calendar. It may not match your baby’s experience.';

  @override
  String rhByDueDate(String date) {
    return 'From the due date $date';
  }

  @override
  String rhByDueDateEstimated(String date) {
    return 'From the estimated due date $date';
  }

  @override
  String get rhOwnPill => 'YOUR BABY’S OWN RHYTHM';

  @override
  String get rhOwnSparsePill => 'OWN RHYTHM · not enough data';

  @override
  String get rhOwnTitle => 'What your family noticed';

  @override
  String get rhOwnEmpty => 'No recent notes yet. You can still add one today.';

  @override
  String get rhOwnNoAccess =>
      'Family notes show only to members who can see daily care.';

  @override
  String get rhMixedDay => 'Different notes';

  @override
  String get rhMixedNote =>
      'When two people note different things on the same day, both are kept.';

  @override
  String rhWhoDay(String who, String date) {
    return '$who · $date';
  }

  @override
  String get rhRecordToday => 'Add today’s note';

  @override
  String rhSleepHeading(int days) {
    return 'Logged total sleep · $days days';
  }

  @override
  String get rhSleepSparseTitle => 'Not enough logs to compare yet.';

  @override
  String rhSleepSparseBody(int valid, int need, int more) {
    return '$valid/$need days with complete sleep logs · $more more needed to compare. Missing logs don’t mean less sleep.';
  }

  @override
  String rhSleepSparseRecent(int need, int days) {
    return 'At least $need of the last $days days need complete logs to compare. Missing logs don’t mean less sleep.';
  }

  @override
  String rhSleepLower(String delta) {
    return 'On recent complete days, logged total sleep is about $delta lower than before.';
  }

  @override
  String rhSleepHigher(String delta) {
    return 'On recent complete days, logged total sleep is about $delta higher than before.';
  }

  @override
  String get rhSleepSame =>
      'On recent complete days, logged total sleep is close to your baby’s usual.';

  @override
  String rhSleepBasis(int recent, String range, int baseline) {
    return 'Basis: the last $recent days ($range) vs the $baseline complete days before. Not a diagnosis.';
  }

  @override
  String rhSleepUsual(String value) {
    return 'usual $value';
  }

  @override
  String get rhSleepMissingLegend => 'incomplete day, not counted';

  @override
  String get rhSleepGateTitle => 'Sleep comparison from your log';

  @override
  String get rhSleepGatePremium =>
      'Comparing with your baby’s usual is part of personalised support. Notes, the reference calendar and health guidance keep working.';

  @override
  String get rhSleepGateOther =>
      'The sleep comparison isn’t open to you. Notes and the reference calendar still work.';

  @override
  String get rhWhy => 'Why?';

  @override
  String get rhTriedHeading => 'What your family has tried';

  @override
  String get rhFooterFacts =>
      'This is what your family noted, not a diagnosis.';

  @override
  String get rhOutOfAge =>
      'Growing rhythm supports babies 0–12 months. For older babies, recorded data stays viewable; new content isn’t supported yet.';

  @override
  String get rhOfflineNote =>
      'Offline: showing what’s saved on this phone · notes will sync when you’re back online.';

  @override
  String get rhRegionOwnerBody =>
      'Choose your region so Child Life uses the right content and emergency number. The reference calendar and notes still work.';

  @override
  String get rhRegionPick => 'Choose region';

  @override
  String get rhRegionWaiting =>
      'Waiting for the family owner to choose a region. Notes, the reference calendar and basic content still work.';

  @override
  String get rhSetupIntro =>
      'Look ahead to what may come, understand what your baby is going through.';

  @override
  String get rhLayerCalendarTitle => 'Reference calendar';

  @override
  String get rhLayerCalendarBody =>
      'Expected windows from the Wonder Weeks model, counted from the due date. Every baby is different — the calendar is only a reference.';

  @override
  String get rhLayerCalendarBasis =>
      'Basis: the due date + the published reference model';

  @override
  String get rhLayerOwnTitle => 'Your baby’s own rhythm';

  @override
  String get rhLayerOwnBody =>
      'What the whole family notes: sleep, soothing, new things. Child Life sums up changes and what you’ve tried.';

  @override
  String get rhLayerOwnBasis => 'Basis: check-ins and the care log';

  @override
  String get rhSetupDisclaimer =>
      'Child Life doesn’t predict fussy days with certainty or diagnose causes.';

  @override
  String get rhStart => 'Start';

  @override
  String rhDueTitle(String baby) {
    return '$baby’s due date';
  }

  @override
  String rhDueBody(String baby, String dob) {
    return 'The reference calendar counts from the due date, not the birth date. $baby was born on $dob.';
  }

  @override
  String get rhDueBodyNoDob =>
      'The reference calendar counts from the due date, not the birth date.';

  @override
  String get rhDueField => 'Due date';

  @override
  String get rhDuePick => 'Pick a date';

  @override
  String get rhEstimateTitle => 'Don’t remember the due date?';

  @override
  String get rhEstimateBody => 'Estimate from the gestational age at birth:';

  @override
  String rhWeeks(int n) {
    return '$n weeks';
  }

  @override
  String rhPlusDays(int n) {
    return '+ $n days';
  }

  @override
  String rhEstimateResult(String date) {
    return 'Estimated due date: $date · labelled “estimated”';
  }

  @override
  String get rhEstimateAdvice =>
      'Very premature or special needs: ask a doctor before using the calendar.';

  @override
  String get rhEstimateNeedsDob =>
      'The baby’s date of birth is needed to estimate.';

  @override
  String get rhDueOutOfRange =>
      'The due date must be between 4 weeks before and 18 weeks after birth.';

  @override
  String get rhSkipOwnOnly => 'Skip — use only your baby’s own rhythm';

  @override
  String get rhDueHelper =>
      'You can change it any time · the calendar and reminders recalculate';

  @override
  String get rhDueSaved => 'Due date saved';

  @override
  String get rhDueRemove => 'Remove due date';

  @override
  String get rhDueRemoved => 'Due date removed';

  @override
  String get rhDueSaveFailed =>
      'Couldn’t save the due date. Check your connection and try again.';

  @override
  String get rhDueSetupOnly => 'Only a co-parent can set the due date.';

  @override
  String get rhEstimatedTag => 'estimated';

  @override
  String get rhWeeksPickerTitle => 'Gestational age at birth';

  @override
  String get rhDaysPickerTitle => 'Extra days';

  @override
  String get rhRemindTitle => 'When should we remind you?';

  @override
  String get rhRemindBody =>
      'All optional. At most 1 growing-rhythm notification a day.';

  @override
  String get rhRemindStage => 'Before a reference stage';

  @override
  String get rhRemindStageSub => '3 days before · at most once per stage';

  @override
  String get rhRemindEvening => 'Evening check-in';

  @override
  String get rhRemindEveningSub =>
      '20:30 · skipped if you already noted something that day';

  @override
  String get rhQuietHours => 'Quiet hours';

  @override
  String rhQuietRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get rhQuietOff => 'Off';

  @override
  String get rhQuietSub => 'No suggestions, only reminders you set';

  @override
  String get rhQuietTo => 'to';

  @override
  String get rhRemindDevice =>
      'Reminders are saved on this phone; quiet hours follow your account.';

  @override
  String get rhNoLeapRisk => 'No “high leap risk” style notifications.';

  @override
  String rhCalendarBasis(String model, String date) {
    return '$model model · from the due date $date';
  }

  @override
  String rhCalendarBasisEstimated(String model, String date) {
    return '$model model · from the estimated due date $date';
  }

  @override
  String get rhChange => 'Change';

  @override
  String rhTodayBefore(String date, int n) {
    return 'Today · $date · before stage $n';
  }

  @override
  String rhTodayIn(String date, int n) {
    return 'Today · $date · within stage $n';
  }

  @override
  String rhTodayPlain(String date) {
    return 'Today · $date';
  }

  @override
  String rhStageUpcoming(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Upcoming · $_temp0 left';
  }

  @override
  String get rhStageCurrent => 'Within the expected window';

  @override
  String get rhStagePast => 'Passed';

  @override
  String rhStagesOverlap(int a, int b) {
    return 'Stages $a and $b overlap · both are only a reference';
  }

  @override
  String rhStageShort(int n) {
    return 'Stage $n';
  }

  @override
  String rhCalendarFooter(String version) {
    return 'The calendar is a reference model, not proven accurate for each baby. Model $version.';
  }

  @override
  String rhNotPartner(String label) {
    return '$label is used as a reference, not a partner.';
  }

  @override
  String rhStageDetailExpected(String range, String baby) {
    return 'Expected $range · may not match $baby’s experience';
  }

  @override
  String get rhSignsTitle => 'Signs you might see';

  @override
  String get rhSignsNormal =>
      'Some babies show no clear change — that’s normal';

  @override
  String get rhSkillsTitle => 'Skills by age, for reference';

  @override
  String get rhSkillsNote =>
      'Skills don’t have to line up with this stage. Following skills by age isn’t a professional screening.';

  @override
  String get rhActivitiesTitle => 'Activities that fit';

  @override
  String get rhSourcesReview => 'Sources & review';

  @override
  String rhModelVersion(String version) {
    return 'Model $version';
  }

  @override
  String get rhSameAsUsual => 'Same as usual today';

  @override
  String get rhStageMissing =>
      'This stage is no longer in the reference calendar.';

  @override
  String get rhMsConfirmTitle => 'Save this as a milestone?';

  @override
  String rhMsConfirmBody(String baby) {
    return 'The milestone goes to $baby’s Moments, ready for photos and a milestone card. No photo is copied.';
  }

  @override
  String get rhMsName => 'Milestone';

  @override
  String get rhMsSavedTitle => 'New milestone saved';

  @override
  String rhMsSavedSub(String name, String date, String who) {
    return '$name · $date · confirmed by $who';
  }

  @override
  String get rhMsKeepTitle => 'Keep this moment?';

  @override
  String get rhMsBasic => 'Basic milestone card';

  @override
  String get rhMsPremium => 'Premium milestone card';

  @override
  String get rhMsCreateCard => 'Create milestone card';

  @override
  String get rhMsPhotoNote =>
      'Pick photos from Moments when you make the card.';

  @override
  String get rhMsRoleTitle => 'Only co-parents can save milestones';

  @override
  String get rhMsRoleBody =>
      'You can still note something new; a co-parent confirms milestones.';

  @override
  String get rhMsSaveFailed => 'Couldn’t save the milestone. Try again later.';

  @override
  String get rhPersonalize => 'Personalisation';

  @override
  String get rhPersonalizeSub => 'Interests, suggestion time, feedback';

  @override
  String get rhPersonalizeNote =>
      'These choices are yours alone; they don’t change anyone else’s.';

  @override
  String get rhInterestsRow => 'Your interests';

  @override
  String get rhDigestRow => 'Suggestion time';

  @override
  String get rhRemindRow => 'Growing-rhythm reminders';

  @override
  String get rhHistoryRow => 'Feedback history';

  @override
  String get rhInterestsNone => 'None yet';

  @override
  String rhInterestsTitle(String baby) {
    return 'What would you like to follow with $baby?';
  }

  @override
  String get rhInterestsBody =>
      'Today and suggestions will put these first. Change them any time.';

  @override
  String get rhInterestsToday =>
      'These are lasting interests. What your baby needs today goes in “Anything different today?”.';

  @override
  String get rhIntSleep => 'Sleep';

  @override
  String get rhIntSleepSub => 'Sleep and growing rhythm';

  @override
  String get rhIntFeeding => 'Feeding & milk';

  @override
  String get rhIntFeedingSub => 'Milk by age';

  @override
  String get rhIntMilestones => 'Milestones';

  @override
  String get rhIntMilestonesSub => 'Milestones by week of age';

  @override
  String get rhIntVaccines => 'Vaccines';

  @override
  String get rhIntVaccinesSub => 'Reminders before vaccine dates';

  @override
  String get rhIntNutrition => 'Nutrition';

  @override
  String get rhIntNutritionSub => 'Micronutrients and vitamins by month';

  @override
  String get rhIntMoments => 'Moments';

  @override
  String get rhIntMomentsSub => 'Prompts to capture moments';

  @override
  String get rhFewerTitle => 'Showing fewer ideas about';

  @override
  String get rhFewerUndo => 'Undo';

  @override
  String rhSaveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return 'Save · $_temp0';
  }

  @override
  String get rhSkip => 'Skip';

  @override
  String get rhPrefsSaved => 'Your choices are saved';

  @override
  String get rhDigestTitle => 'When is a good time to read suggestions?';

  @override
  String get rhDigestBody =>
      'Child Life gathers the day’s suggestions into one, at the time you choose. Reminders you set (feeds, vaccines…) still arrive on time.';

  @override
  String get rhDigestMorning => 'Morning';

  @override
  String get rhDigestNoon => 'Lunch break';

  @override
  String get rhDigestEvening => 'Evening';

  @override
  String get rhDigestNone => 'No daily round-up';

  @override
  String get rhEditHistoryLink =>
      'You can change or delete your feedback history';

  @override
  String get rhHistoryTitle => 'Feedback history';

  @override
  String rhHistoryBody(int days) {
    return 'Your feedback from the last $days days. Delete one and later suggestions no longer use it.';
  }

  @override
  String get rhHistoryEmpty => 'You haven’t given any feedback lately.';

  @override
  String get rhDelete => 'Delete';

  @override
  String get rhDeleteFeedbackTitle => 'Delete this feedback?';

  @override
  String get rhDeleteFeedbackBody =>
      'Later suggestions won’t use this feedback any more.';

  @override
  String get rhFeedbackDeleted => 'Feedback deleted';

  @override
  String get rhResetInterests => 'Reset your interests';

  @override
  String get rhResetInterestsBody =>
      'Clears every topic and every “Fewer ideas like this”.';

  @override
  String get rhResetDone => 'Your interests were reset';

  @override
  String get rhUnknownActivity => 'An idea that’s no longer published';

  @override
  String get rhFewerLikeThis => 'Fewer ideas like this';

  @override
  String rhFewerToast(String topic) {
    return 'Got it. You’ll see fewer ideas about $topic.';
  }

  @override
  String get rhOtherIdeas => 'Other things to try';

  @override
  String get aiHandoverTitle => 'Handover for the next carer';

  @override
  String get aiHandoverEntrySub =>
      'A three-part summary from the family’s notes';

  @override
  String aiHandoverEntryLatest(String date) {
    return 'Latest · $date';
  }

  @override
  String aiHandoverFrom(String range, int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$range · from $_temp0 by $names';
  }

  @override
  String aiHandoverFromCount(String range, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$range · from $_temp0';
  }

  @override
  String aiGeneratedAt(String when) {
    return 'Made $when';
  }

  @override
  String get aiSectionNoticed => 'What was noticed';

  @override
  String get aiSectionHelped => 'What helped';

  @override
  String get aiSectionNext => 'What you could do next';

  @override
  String get aiSectionNote => 'Note';

  @override
  String get aiWordedByAi =>
      'Worded by AI from saved notes · numbers come from the log';

  @override
  String get aiWordedShort => 'Worded by AI from saved notes';

  @override
  String get aiTemplateLine => 'This summary is built from your saved notes.';

  @override
  String get aiReport => 'Not right? Tell us';

  @override
  String aiSendTo(String name) {
    return 'Send to $name';
  }

  @override
  String get aiShare => 'Share handover';

  @override
  String get aiShareAiLine => '(Worded by AI from saved notes)';

  @override
  String get aiShareTemplateLine => '(Template summary from saved notes)';

  @override
  String get aiLoading => 'Putting the notes together…';

  @override
  String get aiNoSections =>
      'Not enough notes for a handover yet. Add today’s note to start.';

  @override
  String aiChipCheckIn(String who, String date) {
    return '$who’s note · $date';
  }

  @override
  String aiChipCheckInMine(String date) {
    return 'Your note · $date';
  }

  @override
  String aiChipFeedback(String who, String date) {
    return '$who’s feedback · $date';
  }

  @override
  String aiChipFeedbackMine(String date) {
    return 'Your feedback · $date';
  }

  @override
  String aiChipMilestone(String date) {
    return 'Something new · $date';
  }

  @override
  String get aiChipSleep => 'Sleep log';

  @override
  String aiRecordWho(String who, String date) {
    return '$who · $date';
  }

  @override
  String get aiRecordCheckIn => 'Note';

  @override
  String get aiRecordFeedback => 'Feedback';

  @override
  String get aiRecordMilestone => 'Something new';

  @override
  String get aiRecordOpenActivity => 'Open the activity';

  @override
  String get aiRecordGone =>
      'This note is no longer on this phone or was deleted.';

  @override
  String get aiStateTemplateTitle => 'Showing the template version';

  @override
  String get aiStateConsentEyebrow => 'AI NOT ON';

  @override
  String get aiStateConsentBody =>
      'This uses a fixed template with the same three parts. If you agree, AI only rewords the saved notes.';

  @override
  String get aiStateConsentAction => 'Review and allow AI';

  @override
  String get aiStateOffEyebrow => 'AI IS OFF';

  @override
  String get aiStateWithdrawnBody =>
      'You turned AI off. The handover uses a fixed template with the same three parts.';

  @override
  String get aiStateWithdrawnAction => 'Turn on AI in Settings';

  @override
  String get aiStateDisabledBody =>
      'AI summaries are paused. The handover uses a fixed template with the same three parts.';

  @override
  String get aiStateErrorEyebrow => 'AI DIDN’T RESPOND';

  @override
  String get aiStateErrorBody => 'Logging and health guidance are unaffected.';

  @override
  String get aiStateQuotaEyebrow => 'AI LIMIT REACHED';

  @override
  String aiStateQuotaDay(int used, int limit, String when) {
    return 'Used $used of $limit AI summaries today for this baby. More from $when. You can still use the template version.';
  }

  @override
  String aiStateQuotaMonth(int used, int limit, String when) {
    return 'Your household used $used of $limit AI credits this period (shared by summaries and the assistant). More from $when. You can still use the template version.';
  }

  @override
  String get aiStateQuotaPlain =>
      'Your household has used this period’s AI credits. You can still use the template version.';

  @override
  String get aiStateTemplateEyebrow => 'TEMPLATE VERSION';

  @override
  String get aiStatePremiumBody =>
      'AI summaries are part of Child Life Premium. You can still use the template version.';

  @override
  String get aiStateOtherBody =>
      'AI isn’t available for your household right now. The template has the same three parts.';

  @override
  String get aiStateStaleTitle => 'New notes since this';

  @override
  String get aiStateStaleBody => 'This was made before the latest notes.';

  @override
  String get aiStateStaleRead =>
      'This was made before the latest notes. A parent can make it again.';

  @override
  String get aiStateStaleAction => 'Make it again';

  @override
  String get aiStateOfflineEyebrow => 'OFFLINE';

  @override
  String get aiStateOfflineTitle => 'Showing the saved version';

  @override
  String get aiStateOfflineBody =>
      'A new version and AI need a connection. Notes still save on this device and sync when online.';

  @override
  String get aiStateOfflineEmptyTitle => 'No handover on this phone yet';

  @override
  String get aiStateFailedTitle => 'Couldn’t make the handover';

  @override
  String get aiStateFailedBody => 'Your family’s notes are unchanged.';

  @override
  String get aiReadEmptyTitle => 'No handover yet';

  @override
  String get aiReadEmptyBody =>
      'When a parent makes a handover, the latest one shows here.';

  @override
  String get aiHealthBody =>
      'A health sign was noted today, so the handover doesn’t use AI. See the health guidance first.';

  @override
  String get aiReportTitle => 'What’s not right?';

  @override
  String get aiReportBody =>
      'Pick one reason. No need to write anything about your baby.';

  @override
  String get aiProblemWrongFact => 'Doesn’t match what we noted';

  @override
  String get aiProblemWrongPerson => 'Wrong person';

  @override
  String get aiProblemUnsafe => 'Unsafe advice';

  @override
  String get aiProblemLanguage => 'Hard to understand';

  @override
  String get aiProblemOther => 'Something else';

  @override
  String get aiReportSend => 'Send';

  @override
  String get aiReportThanks => 'Thank you. This summary will be reviewed.';

  @override
  String get aiReportFailed =>
      'Couldn’t send. Check the connection and try again.';

  @override
  String get aiConsentTitle => 'AI summaries';

  @override
  String get aiConsentIntro =>
      'If you agree, Child Life may ask an external AI service to reword saved notes into a handover or an explanation. AI adds nothing new; every number still comes from the log.';

  @override
  String get aiConsentSentTitle => 'What is sent';

  @override
  String get aiConsentSent1 =>
      'Saved text notes: what was noticed, what was tried, feedback, new things';

  @override
  String get aiConsentSent2 => 'Your baby’s nickname and the date of each note';

  @override
  String get aiConsentNeverTitle => 'Never sent';

  @override
  String get aiConsentNever1 => 'Photos and videos';

  @override
  String get aiConsentNever2 => 'Your baby’s full name and date of birth';

  @override
  String get aiConsentNever3 => 'Notes about health signs';

  @override
  String get aiConsentWhereTitle => 'Who handles it, where it’s kept';

  @override
  String get aiConsentWhere1 =>
      'An external AI service does the wording; Child Life’s server sends the request, never your phone.';

  @override
  String get aiConsentWhere2 => 'The AI provider must not keep this data.';

  @override
  String get aiConsentWhere3 =>
      'Summaries are kept in your family. Withdrawing consent deletes the AI-written text; the template keeps working.';

  @override
  String get aiConsentShareNotes =>
      'Let my notes be used when someone else in the family makes a summary';

  @override
  String get aiConsentShareNotesSub =>
      'If off, notes you write aren’t sent when someone else makes a summary.';

  @override
  String get aiConsentPersonal =>
      'This consent is yours alone; the household plan doesn’t replace it. You can change your mind any time.';

  @override
  String aiConsentVersion(String version) {
    return 'Consent version: $version';
  }

  @override
  String get aiConsentAgree => 'Allow AI';

  @override
  String aiConsentGranted(String date) {
    return 'You agreed on $date';
  }

  @override
  String get aiConsentOutdated =>
      'The consent text changed. Review it to keep using AI.';

  @override
  String get aiConsentWithdraw => 'Withdraw consent';

  @override
  String get aiWithdrawTitle => 'Withdraw consent?';

  @override
  String get aiWithdrawBody =>
      'AI won’t be used for summaries you make. AI-written text will be deleted; the template keeps working.';

  @override
  String get aiWithdrawConfirm => 'Withdraw';

  @override
  String get aiConsentSaved => 'Your choice is saved';

  @override
  String get aiWithdrawn => 'Consent withdrawn';

  @override
  String get aiConsentFailed =>
      'Couldn’t save. Check the connection and try again.';

  @override
  String get aiConsentOn => 'On';

  @override
  String get aiConsentOff => 'Off';

  @override
  String get aiExplainMore => 'Explain more';

  @override
  String get aiExplainLoading => 'Preparing an explanation…';

  @override
  String get aiExplainFailed =>
      'Couldn’t explain more right now. The reason above still stands.';

  @override
  String get aiExplainConsent => 'AI needs your consent to explain more.';

  @override
  String get aiExplainQuota =>
      'This period’s AI credits are used up. The reason above still stands.';

  @override
  String get aiExplainUnavailable =>
      'Explaining more isn’t available for your household right now.';

  @override
  String get rhEpSuggestTitle => 'Group into one observation period?';

  @override
  String rhEpSuggestBody(int count, String people, String what) {
    return '$count recent days had changes noted by $people: $what.';
  }

  @override
  String rhEpPersonDay(String who, String date) {
    return '$who ($date)';
  }

  @override
  String get rhEpNotWonder =>
      'This is just how your family keeps track, not confirmation of a Wonder Weeks stage.';

  @override
  String get rhEpCreate => 'Create observation period';

  @override
  String get rhEpNoNeed => 'No need';

  @override
  String rhEpOpenTitle(String start) {
    return 'Observation period $start – now';
  }

  @override
  String get rhEpUpdating => 'Updating';

  @override
  String rhEpOpenBody(String who, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$who grouped $_temp0 into one period. It ends only when your family taps “Better now”.';
  }

  @override
  String get rhEpBetter => 'Better now';

  @override
  String get rhEpCloseTitle => 'End this observation period?';

  @override
  String rhEpCloseBody(String start) {
    return 'It will be kept from $start to today. Child Life never ends a period on its own.';
  }

  @override
  String get rhEpNotYet => 'Not yet';

  @override
  String get rhEpCreated => 'Observation period created';

  @override
  String get rhEpClosed => 'Observation period ended';

  @override
  String get rhEveningBody =>
      'Note one thing in a few seconds, if there is one. Nothing different is fine too.';

  @override
  String get pmPaywallSubtitle =>
      'One plan for the whole household. Unlocks both benefit groups.';

  @override
  String get pmPaywallHere => 'You’re here';

  @override
  String get pmGroupATitle => 'A · Personalisation & advanced rhythm';

  @override
  String get pmGroupA1 => 'One step a day from your family’s notes';

  @override
  String get pmGroupA2 => 'Remembers what helped, handover for carers';

  @override
  String get pmGroupA3 => 'Grounded AI summaries (with limits)';

  @override
  String get pmGroupBTitle => 'B · Premium card & video templates';

  @override
  String get pmGroupB1 => 'The full Premium template library';

  @override
  String get pmGroupB2 => 'More video exports each period';

  @override
  String get pmPaywallFreeBody =>
      'Logging, history, reminders, reference calendar (Wonder Weeks), basic templates, essential health guidance. After Premium ends you keep your data, moments and exported files.';

  @override
  String get pmPeriodMonthly => 'Monthly';

  @override
  String get pmPeriodYearly => 'Yearly';

  @override
  String pmRenewMonthly(String price) {
    return '$price per month, renews automatically until you cancel.';
  }

  @override
  String pmRenewYearly(String price) {
    return '$price per year, renews automatically until you cancel.';
  }

  @override
  String pmRenewTerms(String store) {
    return 'Payment is charged to your $store account when you confirm. The plan renews unless you turn it off at least 24 hours before the current period ends; manage or cancel in $store settings.';
  }

  @override
  String get pmStoreApple => 'App Store';

  @override
  String get pmStoreGoogle => 'Google Play';

  @override
  String get pmContinuePremium => 'Continue with Premium';

  @override
  String get pmStoreLegal =>
      'Price, period and renewal shown by the store · cancel in store settings';

  @override
  String get pmTerms => 'Terms of Use';

  @override
  String get pmPrivacy => 'Privacy Policy';

  @override
  String get pmRestore => 'Restore';

  @override
  String get pmBuyClosedTitle => 'In-app purchase is coming soon';

  @override
  String get pmBuyClosedBody =>
      'Child Life Premium isn’t sold in the app yet. Everything else keeps working; we’ll let you know when it opens.';

  @override
  String get pmAskOwnerTitle => 'Ask the family owner to upgrade';

  @override
  String get pmAskOwnerBody =>
      'Only the family owner buys and manages the plan. Once the household has Premium, everyone uses it.';

  @override
  String get pmHouseholdHasBody =>
      'Premium is on for the whole family. Only the family owner manages it.';

  @override
  String get pmPendingTitle => 'Waiting for payment confirmation';

  @override
  String get pmPendingBody =>
      'The store hasn’t confirmed yet. Premium isn’t active. Your template and photo selection are kept.';

  @override
  String get pmPendingBodyPlain =>
      'The store hasn’t confirmed yet. Premium isn’t active. You can close this and check again later.';

  @override
  String get pmCheckAgain => 'Check again';

  @override
  String get pmClose => 'Close';

  @override
  String get pmSuccessTitle => 'Your household has Premium';

  @override
  String pmSuccessTemplate(String name) {
    return 'Continuing with “$name” and the photos you chose.';
  }

  @override
  String get pmSuccessRhythm =>
      'Need-based suggestions, your baby’s own rhythm and AI summaries are on for the whole family.';

  @override
  String get pmContinueCard => 'Continue creating';

  @override
  String get pmContinueVideo => 'Continue your video';

  @override
  String get pmBackToRhythm => 'Back to Growing rhythm';

  @override
  String get pmDone => 'Done';

  @override
  String get pmErrorTitle => 'Purchase didn’t complete';

  @override
  String get pmErrorBody =>
      'You aren’t charged unless the store confirms. Try again or use a basic template.';

  @override
  String get pmErrorBodyPlain =>
      'You aren’t charged unless the store confirms. Please try again.';

  @override
  String get pmErrorVerifyBody =>
      'We couldn’t confirm the purchase with the store yet. Premium isn’t active. If you were charged, tap Try again or Restore.';

  @override
  String get pmErrorNetworkBody =>
      'Couldn’t reach Child Life. The store’s transaction is kept so it can be checked again.';

  @override
  String get pmTryAgain => 'Try again';

  @override
  String get pmNotOwnerTitle => 'Only the family owner can buy or restore';

  @override
  String get pmNotOwnerBody =>
      'Ask the family owner to open Household plan to upgrade or restore.';

  @override
  String get pmRestoreTitle => 'Restore purchase';

  @override
  String get pmRestoreBody =>
      'We check purchases on this account and re-link them to your household. Plans aren’t moved from other households.';

  @override
  String get pmCancel => 'Cancel';

  @override
  String get pmRestoredTitle => 'Premium restored';

  @override
  String get pmRestoredBody =>
      'Your plan is linked to this household again. Everyone sees “Household has Premium”.';

  @override
  String get pmRestoreNoneTitle => 'Nothing to restore';

  @override
  String get pmRestoreNoneBody =>
      'This store account has no active Child Life Premium plan.';

  @override
  String get pmRestoreBoundTitle => 'This plan belongs to another household';

  @override
  String get pmRestoreBoundBody =>
      'This purchase is linked to another household. Plans aren’t moved between households; contact support if you need help.';

  @override
  String get pmTemplateKeepsPhotos =>
      'Your selected photos are kept after purchase';

  @override
  String get pmResumedBanner =>
      'Premium unlocked · picking up where you left off';

  @override
  String get pmManageApple => 'Manage in App Store';

  @override
  String get pmManageGoogle => 'Manage in Google Play';

  @override
  String get pmSeePremium => 'See Premium';

  @override
  String get pmRenewPremium => 'Renew Premium';

  @override
  String get pmExpiredStrip =>
      'Premium has ended. All notes, feedback and saved summaries are still here.';

  @override
  String get pmQuotaTitle => 'Video exports this period';

  @override
  String pmQuotaDetail(int used, int reserved, String date) {
    return '$used used · $reserved reserved · resets $date';
  }

  @override
  String pmQuotaDetailNoDate(int used, int reserved) {
    return '$used used · $reserved reserved';
  }

  @override
  String get pmQuotaCards => 'Cards don’t count.';

  @override
  String get pmQuotaOutTitle => 'No video exports left this period';

  @override
  String pmQuotaOutBody(String date) {
    return 'You can still browse templates and make cards. New videos wait for the next period, starting $date.';
  }

  @override
  String get pmQuotaOutBodyNoDate =>
      'You can still browse templates and make cards. New videos wait for the next period.';

  @override
  String get pmQuotaMakeCard => 'Make a card';

  @override
  String pmQuotaPremiumNote(int limit) {
    return 'Premium includes $limit video exports each period.';
  }

  @override
  String get pmQuotaReserved => '1 export reserved · you can leave this screen';

  @override
  String get pmQuotaReleased =>
      'Reservation released · retry doesn’t use another export';

  @override
  String get rhWeekTitle => 'Weekly summary';

  @override
  String rhWeekOf(int n, String baby) {
    return '$baby’s week $n';
  }

  @override
  String get rhWeekInProgress => 'Week in progress · figures so far';

  @override
  String get rhWeekShare => 'Send to…';

  @override
  String get rhWeekRecordedTitle => 'Logged this week';

  @override
  String get rhWeekRecordedSub => 'From the family’s log';

  @override
  String get rhWeekFeeds => 'Feeds';

  @override
  String rhWeekFeedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$_temp0';
  }

  @override
  String rhWeekBottle(String ml) {
    return 'Bottle $ml ml';
  }

  @override
  String rhWeekBreast(String time) {
    return 'Breast $time';
  }

  @override
  String get rhWeekNone => 'None logged';

  @override
  String get rhWeekSleep => 'Sleep';

  @override
  String get rhWeekSleepAvg => 'average per fully logged day';

  @override
  String rhWeekCoverage(int valid, int days) {
    return '$valid/$days fully logged days';
  }

  @override
  String get rhWeekSleepSparse => 'Not enough data';

  @override
  String rhWeekSleepNeed(int need) {
    return 'needs at least $need days';
  }

  @override
  String get rhWeekDiapers => 'Diapers';

  @override
  String rhWeekDiaperCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String rhWeekDiaperKinds(int wet, int dirty) {
    return 'Wet $wet · Dirty $dirty';
  }

  @override
  String get rhWeekGrowth => 'Growth';

  @override
  String rhWeekGrowthSince(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String rhWeekGrowthOn(String date) {
    return 'measured $date';
  }

  @override
  String get rhWeekMemories => 'Moments';

  @override
  String rhWeekPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String rhWeekVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String rhWeekNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get rhWeekCoverageNote =>
      'Average sleep counts only fully logged days, counted automatically from the log. A day with gaps is never counted as zero.';

  @override
  String get rhWeekFamilyTitle => 'Caring together';

  @override
  String rhWeekFamilyCount(String who, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$who $_temp0';
  }

  @override
  String get rhWeekFamilyEmpty => 'Nothing was logged this week.';

  @override
  String get rhWeekFamilyNote => 'Entries in the log, not a ranking.';

  @override
  String get rhWeekNextTitle => 'Next week';

  @override
  String get rhWeekNextEmpty => 'No reminders or vaccines set for next week.';

  @override
  String rhWeekReference(String range) {
    return '$range · reference';
  }

  @override
  String get rhWeekNoScore => 'No scores, no comparison with other babies.';

  @override
  String get rhWeekInsightTitle => 'Looking back on the week';

  @override
  String get rhWeekInsightSub =>
      'From your family’s notes and log · not a diagnosis';

  @override
  String get rhWeekNotesTitle => 'Notes this week';

  @override
  String rhWeekChangedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days with a change noted',
      one: '1 day with a change noted',
    );
    return '$_temp0';
  }

  @override
  String rhWeekObsDays(String what, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$what · $_temp0';
  }

  @override
  String rhWeekUsualDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usual days',
      one: '1 usual day',
    );
    return '$_temp0';
  }

  @override
  String rhWeekMixedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0 where people saw it differently · both notes kept';
  }

  @override
  String get rhWeekNoNotes => 'No notes this week.';

  @override
  String get rhWeekTriedTitle => 'Tried this week';

  @override
  String get rhWeekNoTried => 'Nothing was marked as tried this week.';

  @override
  String get rhWeekNextIdea => 'One idea for next week';

  @override
  String get rhWeekGatePremium =>
      'The look-back (sleep against your baby’s usual level, notes and what you tried) is part of Support that fits your baby.';

  @override
  String get rhWeekGateOther =>
      'The look-back isn’t open to you yet. The figures above still work.';

  @override
  String get rhWeekNoAccess =>
      'The weekly summary is only shown to people who can see daily care.';

  @override
  String get rhWeekShareFrom => 'Logged this week (Child Life log):';

  @override
  String rhWeekShareLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String rhWeekShareSleep(String time) {
    return 'average $time per fully logged day';
  }

  @override
  String get rhWeekOpen => 'Look back at the week';

  @override
  String get rhWeekRemindSub => 'Sunday 20:30 · before quiet hours';

  @override
  String get rhWeekNotifBody => 'See what the family logged this week.';

  @override
  String get asEntryTitle => 'Child Life assistant';

  @override
  String asEntryLeft(int remaining, int limit) {
    return '$remaining/$limit left';
  }

  @override
  String asEntryOut(String date) {
    return 'All used · resets $date';
  }

  @override
  String get asComposerHint => 'Ask, log or send a photo…';

  @override
  String get asComposerHintText => 'Ask or log…';

  @override
  String get asComposerViewer => 'Ask about the logs…';

  @override
  String get asComposerOutFree => 'AI help used up this month';

  @override
  String get asComposerOutPremium =>
      'Out of AI help · direct logging still works';

  @override
  String get asComposerAnswer => 'Type your answer…';

  @override
  String get asSend => 'Send';

  @override
  String get asAddPhoto => 'Photo';

  @override
  String get asChipLogFeed => 'Log a feed';

  @override
  String get asPrefillFeed => 'Bottle feed at ';

  @override
  String get asChipFeedsToday => 'How did feeds go today?';

  @override
  String get asChipReceipt => 'Scan a receipt';

  @override
  String get asFabLabel => 'Open Lumi';

  @override
  String get asModuleExpenseTitle => 'Snap a receipt or type to log';

  @override
  String get asModuleExpenseTextOnly => 'Type to log an expense';

  @override
  String get asModuleSub => 'The assistant drafts it · you check before saving';

  @override
  String get asScopeHousehold => 'Family';

  @override
  String get asScopeTitle => 'Chat about';

  @override
  String get asHistory => 'History';

  @override
  String get asNewChat => 'New chat';

  @override
  String asUsageA11y(int remaining, int limit, String date) {
    return 'Household AI help: $remaining of $limit left, resets $date';
  }

  @override
  String get asBadgeFree => 'Basic';

  @override
  String get asBadgePremium => 'Premium';

  @override
  String asEmptyTitle(String name) {
    return 'Ask, log or send a photo for $name';
  }

  @override
  String asEmptyTitleText(String name) {
    return 'Ask or log for $name';
  }

  @override
  String get asEmptyTitleHousehold => 'Ask or log for the family';

  @override
  String get asEmptyBody =>
      'The assistant understands and drafts. You check before it’s saved in the right place.';

  @override
  String get asExampleFeed => '“Bottle 120 ml at 8am”';

  @override
  String get asExampleFeedText => 'Bottle 120 ml at 8am';

  @override
  String get asExampleFeedsToday => '“How did feeds go today?”';

  @override
  String get asExampleExpense => '“Diapers 310,000 dong yesterday”';

  @override
  String get asExampleExpenseText => 'Diapers 310,000 dong yesterday';

  @override
  String get asExampleReceipt => 'Snap a receipt → log an expense';

  @override
  String get asExampleNote => 'Snap a note → reminders';

  @override
  String get asPrivacyNote =>
      'Messages and photos you send are processed by AI to make drafts. Nothing saves automatically. You choose whether original photos are kept.';

  @override
  String get asPrivacyNoteText =>
      'Messages you send are processed by AI to make drafts. Nothing saves automatically.';

  @override
  String get asThinking => 'Lumi is typing…';

  @override
  String get asCancelTask => 'Cancel';

  @override
  String get asCanceled => 'Canceled.';

  @override
  String get asUnsent => 'Not sent';

  @override
  String get asSending => 'Sending…';

  @override
  String asDraftsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I found $count things',
      one: 'I found 1 thing',
    );
    return '$_temp0. Check them and choose what to save.';
  }

  @override
  String get asUnsupportedPart =>
      'This needs a newer app version to show. Nothing was saved.';

  @override
  String get asLoadingChat => 'Opening the chat…';

  @override
  String get asStateDraft => 'Draft';

  @override
  String get asStateReview => 'Check';

  @override
  String get asStateSaving => 'Saving';

  @override
  String get asStateSaved => 'Saved';

  @override
  String get asStateFailed => 'Not saved';

  @override
  String get asStateDiscarded => 'Removed';

  @override
  String get asStateExpired => 'Expired';

  @override
  String get asKindBottle => 'Bottle feed';

  @override
  String get asKindBreast => 'Breastfeed';

  @override
  String get asKindSleep => 'Sleep';

  @override
  String get asKindExpense => 'Expense';

  @override
  String get asKindReminder => 'Reminder';

  @override
  String get asKindObservation => 'Note';

  @override
  String get asKindMeal => 'Meal';

  @override
  String get asKindUnknown => 'Unsupported item';

  @override
  String asModuleCare(String name) {
    return '$name · Care log';
  }

  @override
  String get asModuleSpending => 'Family · Expenses';

  @override
  String get asModuleReminders => 'Family · Reminders';

  @override
  String asModuleRhythm(String name) {
    return '$name · Growing rhythm';
  }

  @override
  String asModuleMeal(String name) {
    return '$name · Solids';
  }

  @override
  String asDayToday(String date) {
    return 'Today $date';
  }

  @override
  String asDayYesterday(String date) {
    return 'Yesterday $date';
  }

  @override
  String asAmountMl(String ml) {
    return '$ml ml';
  }

  @override
  String get asNoAmount => 'no amount yet';

  @override
  String get asNoTime => 'no time yet';

  @override
  String get asNoDate => 'no date yet';

  @override
  String get asEdit => 'Edit';

  @override
  String get asRemove => 'Remove';

  @override
  String get asOpenLog => 'Open log';

  @override
  String get asUndo => 'Undo';

  @override
  String get asOpenSpending => 'Open Expenses';

  @override
  String get asOpenReminders => 'Open reminders';

  @override
  String get asOpenRhythm => 'See the rhythm';

  @override
  String get asSeeLogged => 'See the logged one';

  @override
  String get asSaveAnyway => 'Save anyway';

  @override
  String get asViewerDraftNote => 'View only · can’t save from chat';

  @override
  String get asProblemMissingAmount => 'Add the amount (ml) before saving.';

  @override
  String get asProblemInvalidAmount => 'That amount isn’t valid.';

  @override
  String get asProblemMissingTime => 'Add the time before saving.';

  @override
  String get asProblemFutureTime =>
      'That time is in the future — only log what happened.';

  @override
  String get asProblemInvalidTime => 'The end must be after the start.';

  @override
  String get asProblemMissingDate => 'Pick the date before saving.';

  @override
  String get asProblemCurrency => 'Expenses don’t support this currency yet.';

  @override
  String get asProblemMissingTitle => 'Add a title before saving.';

  @override
  String get asNeedsReview => 'Check this item before saving.';

  @override
  String get asErrConflict => 'Overlaps something already logged. Not saved.';

  @override
  String get asErrDuplicate => 'This looks already logged. Not saved.';

  @override
  String get asErrWriteDenied => 'Your role can’t save this item.';

  @override
  String get asErrExpired => 'This draft expired. Send it again for a new one.';

  @override
  String get asErrStale => 'This draft just changed. Check it, then save.';

  @override
  String get asErrSaveFailed => 'Couldn’t save. Please try again.';

  @override
  String get asErrScope =>
      'The selected baby changed. Open the right baby to save.';

  @override
  String get asErrModule => 'The app has nowhere to save this yet.';

  @override
  String asSaveSelected(int count) {
    return 'Save $count selected';
  }

  @override
  String get asChooseToSave => 'Choose what to save';

  @override
  String get asDiscardAll => 'Discard all';

  @override
  String asPartial(int saved, int total, int failed) {
    return '$saved of $total saved · $failed not saved';
  }

  @override
  String get asRetryFailed => 'Retry failed item';

  @override
  String get asRetryFree => 'Retrying doesn’t use AI help.';

  @override
  String get asSaveOffline =>
      'Offline · nothing saved. Save again when you’re online.';

  @override
  String get asSaveError => 'Couldn’t save. Your drafts are kept.';

  @override
  String get asSaveAnywayTitle => 'Save anyway?';

  @override
  String get asSaveAnywayBody =>
      'This overlaps something already logged. Saving separately keeps both; you can edit or delete in the log.';

  @override
  String get asSaveSeparately => 'Save separately';

  @override
  String get asCancel => 'Cancel';

  @override
  String get asClarifyFree =>
      'Clarifying questions are part of the same task and don’t use extra help.';

  @override
  String get asClarifyOwn => 'Other…';

  @override
  String get asClarifyExpired =>
      'This question expired. Send it again to continue.';

  @override
  String get asEditBottle => 'Edit bottle feed';

  @override
  String get asEditBreast => 'Edit breastfeed';

  @override
  String get asEditSleep => 'Edit sleep';

  @override
  String get asFieldBaby => 'Baby';

  @override
  String get asFieldWhen => 'Time';

  @override
  String get asFieldAmount => 'Amount (ml)';

  @override
  String get asFieldStart => 'Start';

  @override
  String get asFieldEnd => 'End';

  @override
  String get asFieldMinutes => 'Minutes';

  @override
  String get asFieldSide => 'Side';

  @override
  String get asBabyLocked =>
      'The baby stays as in this chat; drafts never move to another baby.';

  @override
  String get asUpdateDraft => 'Update draft';

  @override
  String get asEditFailed => 'Couldn’t update the draft. Try again.';

  @override
  String asSummaryMeta(String day, String time) {
    return '$day · to $time';
  }

  @override
  String asSummaryBottle(int count, String ml) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return 'Bottle · $_temp0 · $ml ml';
  }

  @override
  String asSummaryBreast(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return 'Breastfeeding · $_temp0 · $minutes min';
  }

  @override
  String get asSummaryBreastNote => 'Shown in minutes, not converted to ml';

  @override
  String asSummarySleep(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sleeps',
      one: '1 sleep',
    );
    return 'Sleep · $_temp0 · $duration';
  }

  @override
  String get asSummaryNone => 'Nothing logged in this period.';

  @override
  String get asSummaryPartial =>
      'Based on the feeds logged — may be incomplete.';

  @override
  String get asSummaryComplete => 'Based on the day’s logged feeds.';

  @override
  String get asOpenSourceLog => 'Open source log';

  @override
  String get asNoRecordCreated => 'Questions never create new entries';

  @override
  String get asUsageTitle => 'AI help';

  @override
  String asUsageOf(int limit) {
    return '/ $limit left';
  }

  @override
  String asUsageResetFree(String date) {
    return 'Resets $date in household time · shared by the household';
  }

  @override
  String asUsageResetPremium(String date) {
    return 'Resets $date with the Premium period · shared by the household';
  }

  @override
  String get asCostTitle => 'Roughly per task';

  @override
  String get asCostText => 'Questions, quick text logs';

  @override
  String get asCostPhoto => 'Read 1 photo (receipt, note)';

  @override
  String get asCostFollowUp => 'Follow-ups, edits, confirm';

  @override
  String get asCostError => 'System error, unreadable photo';

  @override
  String get asCostHealth => 'Essential health guidance';

  @override
  String asCostCredits(int count) {
    return '$count';
  }

  @override
  String get asCostNoExtra => 'No extra';

  @override
  String get asCostNotCharged => 'Not charged';

  @override
  String get asCostFree => 'No credits used';

  @override
  String get asRecentTitle => 'Recent';

  @override
  String get asRecentText => 'Question or quick log';

  @override
  String get asRecentPhoto => 'Read photo';

  @override
  String get asVideoQuotaTitle => 'Keepsake video exports';

  @override
  String asVideoQuotaSub(int left, int limit) {
    return 'Separate quota, not AI help · $left/$limit left';
  }

  @override
  String get asPremiumTeaser =>
      'Premium has more help, plus proactive personalisation and Premium card/video templates.';

  @override
  String get asSeePremium => 'See Premium';

  @override
  String get asPremiumHousehold =>
      'Your household has Premium. There’s no separate chat plan.';

  @override
  String get asUsageFailed => 'Couldn’t load usage.';

  @override
  String get asRetry => 'Try again';

  @override
  String get asPhotoNotSent => 'Photo · not sent';

  @override
  String asPhotoQuoteTitle(int credits, int remaining) {
    return 'Reading this photo needs $credits, you have $remaining.';
  }

  @override
  String asPhotoQuoteFree(String date) {
    return 'You can type it in, wait for $date, or upgrade to continue now. The photo hasn’t been sent.';
  }

  @override
  String asPhotoQuotePremium(String date) {
    return 'You can type it in or wait for $date. The photo hasn’t been sent.';
  }

  @override
  String get asTypeInstead => 'Type it in';

  @override
  String get asRemovePhoto => 'Remove photo';

  @override
  String get asOutTitleFree => 'You’ve used all AI help this month.';

  @override
  String get asOutBodyFree =>
      'Your question is kept. You can still log directly and view logs as usual.';

  @override
  String get asOpenTodayLog => 'Open today’s log';

  @override
  String get asUpgradeContinue => 'Upgrade & continue';

  @override
  String get asHealthStillOpen => 'Essential health guidance stays open.';

  @override
  String get asOpenHealth => 'Open Health guidance';

  @override
  String get asOutTitlePremium =>
      'Your household has used all AI help this period.';

  @override
  String asOutBodyPremium(String date) {
    return 'Resets $date. You can still log directly, view logs, use Premium templates and your separate video quota.';
  }

  @override
  String get asSeeUsage => 'See usage details';

  @override
  String get asReadyStillSave =>
      'Drafts that are ready can still be saved, no AI help needed.';

  @override
  String get asResumedBanner =>
      'Household has Premium · continuing your question';

  @override
  String get asResumedNote =>
      'The question counts once when answered, not when you were out.';

  @override
  String get asContinueQuestion => 'Continue my question';

  @override
  String get asFailTitle => 'The assistant couldn’t respond';

  @override
  String get asFailBody =>
      'Nothing was saved. This didn’t use AI help, and retrying won’t charge twice.';

  @override
  String get asLogDirectly => 'Log directly';

  @override
  String get asOfflineTitle => 'Offline';

  @override
  String get asOfflineBody =>
      'Your message is kept, not sent. When you’re back online, tap Send. Direct logging in modules still saves on device.';

  @override
  String get asGenericError => 'Something went wrong. Nothing was saved.';

  @override
  String get asConsentTitle => 'Before you use the assistant';

  @override
  String get asConsent1 =>
      'Messages and photos you send are processed by AI to understand and draft.';

  @override
  String get asConsent2 =>
      'Only photos you choose are sent. You choose whether originals are kept; the app says a photo was deleted only once that’s confirmed.';

  @override
  String get asConsent3 =>
      'Only your baby’s nickname is used; never the full name or exact birth date.';

  @override
  String get asConsent4 =>
      'Nothing saves automatically. You check before anything is logged.';

  @override
  String get asConsentProvider =>
      'An external AI service handles it through Child Life’s server, never directly from your phone; the provider must not keep this data.';

  @override
  String get asConsentPrivate =>
      'For parents and caregivers, questions about the baby go in the baby’s shared chat. Photos, expenses and every other question are only yours. You can change your mind any time.';

  @override
  String get asConsentAgree => 'Agree and start';

  @override
  String get asConsentDecline => 'Don’t use the assistant';

  @override
  String get asConsentDeclined =>
      'Assistant not used. Direct logging works as usual.';

  @override
  String get asConsentFailed =>
      'Couldn’t save your choice. Check the connection and try again.';

  @override
  String get asViewerTitle => 'You have view access';

  @override
  String get asViewerBody =>
      'View-only members can’t log through chat. You can still ask and see summaries.';

  @override
  String get asWriteDeniedTitle => 'Can’t save from chat';

  @override
  String get asWriteDeniedBody =>
      'Your role can’t log this. You can still ask and see summaries.';

  @override
  String get asReadDeniedBody => 'Your role can’t see this data.';

  @override
  String get asModuleTitle => 'Nowhere to save this yet';

  @override
  String get asModuleBody =>
      'The app has no module for this, so nothing was created. You can ask for a reminder with a date and time instead and check the draft.';

  @override
  String get asRegionTitle => 'Region not supported';

  @override
  String get asRegionBody =>
      'Care suggestions via chat aren’t available in your region yet. Quick logging and data questions still work.';

  @override
  String get asOffTitle => 'The assistant is paused';

  @override
  String get asOffBody => 'History and direct logging still work.';

  @override
  String get asNotMemberBody => 'You’re no longer in this baby’s family.';

  @override
  String get asHealthTitle => 'Contact medical help now';

  @override
  String get asHealthBody =>
      'The assistant isn’t an emergency service and can’t assess your baby.';

  @override
  String asHealthCall(String number) {
    return 'Call $number';
  }

  @override
  String get asHealthCallDoctor => 'Call your baby’s doctor';

  @override
  String get asHealthFree => 'No AI help used';

  @override
  String get asDialFailed => 'Couldn’t open the phone app.';

  @override
  String get asHistoryTitle => 'Conversations';

  @override
  String get asHistoryToday => 'TODAY';

  @override
  String get asHistoryWeek => 'THIS WEEK';

  @override
  String get asHistoryEarlier => 'EARLIER';

  @override
  String get asHistoryUntitled => 'Chat';

  @override
  String get asHistoryFootnote =>
      'Each baby has its own history. Switching baby never moves pending drafts.';

  @override
  String get asHistoryPrivate =>
      'Only you can see your chats. Saved records stay shared by role.';

  @override
  String get asHistoryEmpty => 'No chats yet.';

  @override
  String get asHistoryFailed => 'Couldn’t load the history.';

  @override
  String get asDeleteChat => 'Delete chat';

  @override
  String get asDeleteTitle => 'Delete this chat?';

  @override
  String get asDeleteBody =>
      'Its messages and unsaved drafts will be deleted. Anything already saved to the log, Expenses or Reminders stays.';

  @override
  String get asDeleteConfirm => 'Delete';

  @override
  String get asDeleted => 'Chat deleted';

  @override
  String get asDeleteFailed => 'Couldn’t delete. Try again later.';

  @override
  String get asPhotoSheetTitle => 'Send a photo to read';

  @override
  String get asPhotoCameraSub => 'Receipt, note board';

  @override
  String get asPhotoLibrarySub => 'Only the photo you pick is sent';

  @override
  String asPhotoQuoteExact(int credits) {
    return 'Reading 1 photo uses $credits of your AI help';
  }

  @override
  String asPhotoSheetBody(int remaining) {
    return '$remaining left. You see the exact cost before sending; an unreadable photo isn’t charged.';
  }

  @override
  String get asPhotoSheetBodyUnknown =>
      'You see the exact cost before sending; an unreadable photo isn’t charged.';

  @override
  String get asPhotoChosenTitle => 'Photo chosen · not sent';

  @override
  String get asPhotoOnlyThis => 'Only this photo is sent to be read.';

  @override
  String asPhotoQuoteBody(int remaining) {
    return '$remaining left. Follow-ups, edits and confirming in the same task don’t use more. An unreadable photo isn’t charged.';
  }

  @override
  String get asKeepReceipt => 'Keep the receipt with the expense';

  @override
  String get asKeepReceiptOn =>
      'When you save the expense, the photo stays with it. If you don’t save, the photo is deleted.';

  @override
  String get asKeepReceiptOff =>
      'The photo is deleted after reading. The app says it’s deleted only once that’s confirmed.';

  @override
  String get asPhotoTextIsData =>
      'Text in photos is content to read, never a command to the app.';

  @override
  String get asSendPhoto => 'Send photo';

  @override
  String get asPhotoQuoting => 'Checking the cost…';

  @override
  String get asPhotoPickFailed =>
      'Couldn’t open the photo. Try again or pick another.';

  @override
  String asUploading(int percent) {
    return 'Uploading · $percent%';
  }

  @override
  String get asCancelUpload => 'Cancel';

  @override
  String get asUploadFree => 'Cancelling while uploading uses no AI help.';

  @override
  String get asUploadCanceled => 'Upload cancelled. The photo is still chosen.';

  @override
  String get asPhotoReading => 'Reading the photo…';

  @override
  String get asPhotoRead => 'Read ✓';

  @override
  String get asPhotoBlurry => 'Blurry photo';

  @override
  String get asPhotoRefused => 'This file can’t be read';

  @override
  String get asPhotoCanceled => 'Cancelled';

  @override
  String get asPhotoLeaveScreen =>
      'You can leave this screen; the result stays here when you come back.';

  @override
  String get asPhotoFailBody =>
      'The photo wasn’t read and nothing was saved. The photo is still chosen.';

  @override
  String get asReceiptTitle => 'Expense from receipt';

  @override
  String get asFieldStore => 'Store';

  @override
  String get asFieldDate => 'Date';

  @override
  String get asFieldTotal => 'Total';

  @override
  String get asFieldCategory => 'Suggested category';

  @override
  String get asFieldScope => 'Scope';

  @override
  String get asFieldCurrency => 'Currency';

  @override
  String get asFieldTitle => 'To-do';

  @override
  String get asFieldTime => 'Time';

  @override
  String asFieldCheckA11y(String label, String value) {
    return '$label: $value, needs checking';
  }

  @override
  String get asNotRead => 'not read';

  @override
  String asExpenseFor(String name) {
    return 'Family · for $name';
  }

  @override
  String asTaxIncluded(String total) {
    return 'Only the total $total (tax included) is logged; subtotal and tax aren’t added again.';
  }

  @override
  String get asConfirmDate =>
      'The date isn’t certain: tap it to pick or confirm before saving.';

  @override
  String get asDuplicateBody =>
      'This may duplicate an expense your family logged. Nothing is merged automatically.';

  @override
  String get asDuplicateAcknowledged =>
      'You chose to save it separately · nothing merged.';

  @override
  String get asOpenDuplicate => 'Open the logged one';

  @override
  String get asSaveAnywayShort => 'Save anyway';

  @override
  String get asSaveExpense => 'Save expense';

  @override
  String get asSkip => 'Skip';

  @override
  String get asEditExpense => 'Edit expense';

  @override
  String get asTotalOnly =>
      'The printed total only; subtotal and tax aren’t added.';

  @override
  String get asPickDate => 'Pick a date';

  @override
  String get asPickTime => 'Pick a time';

  @override
  String get asRetentionKept =>
      'The receipt photo is kept with the expense in Expenses.';

  @override
  String get asRetentionKeptIfSaved =>
      'The photo stays with the expense when you save it; otherwise it’s deleted.';

  @override
  String get asRetentionDeleting =>
      'Deleting the original photo. The app says it’s deleted only once that’s confirmed.';

  @override
  String get asRetentionDeleted => 'The original photo was deleted.';

  @override
  String get asRetentionWillDelete =>
      'The original photo will be deleted after reading; the app says when it’s done.';

  @override
  String asRemindLine(String when) {
    return 'Remind: $when';
  }

  @override
  String asModuleRemindersOf(String name) {
    return '$name · Reminders';
  }

  @override
  String get asCheckReminder => 'Pick date & time';

  @override
  String get asEditReminder => 'Edit reminder';

  @override
  String get asAllDay => 'No time';

  @override
  String asReminderBaby(String name) {
    return 'Saved for $name; never moved to another baby.';
  }

  @override
  String get asProblemInvalidTitle =>
      'The title is too long (80 characters max).';

  @override
  String get asProblemPastTime =>
      'That time has passed — pick an upcoming one.';

  @override
  String get asRetake => 'Retake';

  @override
  String get asOtherPhoto => 'Pick another photo';

  @override
  String get asUnreadableFree => 'This attempt used no AI help.';

  @override
  String get asSleepSafety =>
      'If baby has a fever, trouble breathing, is very drowsy or refuses feeds — open Health guidance.';

  @override
  String get asSleepFalling => 'hard to fall asleep';

  @override
  String get asSleepWaking => 'waking often';

  @override
  String get asSleepBoth => 'hard to fall asleep and waking often';

  @override
  String get asWhenNight => 'night';

  @override
  String get asWhenDay => 'naps';

  @override
  String get asWhenBoth => 'day and night';

  @override
  String get asFromCareLibrary => 'From the Care library';

  @override
  String asFromCareLibraryMinutes(int minutes) {
    return 'From the Care library · $minutes min';
  }

  @override
  String get asContentUnreviewed =>
      'Written from WHO, AAP and NHS guidance · for reference, not a substitute for a doctor. Doesn’t claim a cause.';

  @override
  String get asContentReviewed =>
      'Expert-reviewed content. Doesn’t claim a cause.';

  @override
  String get asTryTonight => 'Try tonight';

  @override
  String get asTryToday => 'Try today';

  @override
  String get asAnotherIdea => 'Another idea';

  @override
  String get asPlannedTonight => 'You plan to try it tonight';

  @override
  String get asPlannedToday => 'You plan to try it today';

  @override
  String asPlanFollowUp(String day) {
    return 'I’ll ask again from $day, after you’ve had a chance to try.';
  }

  @override
  String get asObservationTitle => 'Note (optional)';

  @override
  String get asObservationSleep => 'sleep';

  @override
  String get asSaveObservation => 'Save note';

  @override
  String get asNoThanks => 'No thanks';

  @override
  String get asOpenCareLibrary => 'Open the Care library';

  @override
  String get asOutcomeHelpful => 'Helpful';

  @override
  String get asOutcomeUnsure => 'Not sure';

  @override
  String get asOutcomeNotSuitable => 'Not a fit';

  @override
  String get asOutcomeNotTried => 'Didn’t try';

  @override
  String get asFeedbackHelpful =>
      'Feedback saved. I’ll prioritise this next time. “Helpful” doesn’t mean it caused the change.';

  @override
  String get asFeedbackUnsure =>
      'Feedback saved. I’ll take it into account next time.';

  @override
  String get asFeedbackNotSuitable =>
      'Feedback saved. I won’t suggest this again.';

  @override
  String get asFeedbackNotTried =>
      'No problem. When you try it, you can note it in Growing rhythm.';

  @override
  String get asFeedbackTitle => 'Activity feedback';

  @override
  String get asFeedbackFree => 'Feedback doesn’t use AI help.';

  @override
  String get asRecipesFrom => 'From the Recipe library';

  @override
  String asRecipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String asRecipesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dishes',
      one: '1 dish',
    );
    return '$_temp0 with an ingredient your baby had a recorded reaction to left out (a recorded reaction, not an allergy diagnosis).';
  }

  @override
  String get asRecipesCaveat =>
      'No recorded reaction doesn’t mean a food is well tolerated.';

  @override
  String get asLogMeal => 'Log meal';

  @override
  String get asLogMealUnavailable =>
      'There’s no meal log in the app yet, so meals can’t be logged here.';

  @override
  String get asProblemInvalidAssignee =>
      'The assignee is no longer in the family. Pick someone else.';

  @override
  String asSavedBy(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$name saved $_temp0';
  }

  @override
  String asConfirmedBy(String name) {
    return 'Saved by $name';
  }

  @override
  String asWaitingFor(String name) {
    return 'Waiting for $name to answer.';
  }

  @override
  String get asPrivateTask =>
      'Only you see this: photos and expenses stay out of the baby’s shared chat.';

  @override
  String get asHistoryShared => 'SHARED CHAT';

  @override
  String get asSharedThreadTitle => 'Shared chat about the baby';

  @override
  String asSharedThreadSub(String when) {
    return 'Parents and caregivers see it · $when';
  }

  @override
  String get asHistorySharedNote =>
      'Questions about the baby are in the shared chat of parents and caregivers. Photos, expenses and older chats are only yours.';

  @override
  String get asDeleteSharedTitle => 'Delete the shared chat?';

  @override
  String get asDeleteSharedBody =>
      'The shared chat is deleted for everyone, including unsaved drafts. Anything saved to the log, Growing rhythm or Reminders stays.';

  @override
  String get asDeletedRecordsKept => 'Chat deleted. Saved records stay.';

  @override
  String get asCostSummary => 'AI summaries (handover, explanation)';

  @override
  String get asRecentHandover => 'AI handover summary';

  @override
  String get asRecentExplain => 'AI explanation of a suggestion';

  @override
  String get asRecentMoment => 'AI moment summary';

  @override
  String get asRecentSummary => 'AI summary';

  @override
  String asRecentHeld(int credits) {
    return '$credits held';
  }

  @override
  String get asRecentReleased => '0 · given back';

  @override
  String get asRecentFree => '0 · not counted';

  @override
  String get asRecentEmpty => 'No AI help used this period yet.';

  @override
  String asHistorySaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items saved',
      one: '1 item saved',
    );
    return '$_temp0';
  }

  @override
  String get asHistoryNeedsAnswer => 'A question is waiting for an answer';

  @override
  String get asHistoryAwaitingFeedback => 'Waiting for feedback after trying';

  @override
  String asHistoryDrafts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts',
      one: '1 draft',
    );
    return '$_temp0';
  }

  @override
  String asSummaryFeedMl(String time, String ml) {
    return '$time $ml ml';
  }

  @override
  String asSummaryFeedMinutes(String time, int minutes) {
    return '$time $minutes min';
  }

  @override
  String get lbTitle => 'Baby-care library';

  @override
  String get lbSaved => 'Saved';

  @override
  String get lbSearchHint => 'Search: naps, hiccups, nappy rash…';

  @override
  String get lbTopicFeeding => 'Feeding & milk';

  @override
  String get lbTopicSleep => 'Sleep';

  @override
  String get lbTopicTeething => 'Teething';

  @override
  String get lbTopicIllness => 'Fever & minor illness';

  @override
  String get lbTopicDailyCare => 'Daily care';

  @override
  String get lbTopicDevelopment => 'Development';

  @override
  String lbForBaby(String name, String age) {
    return 'For $name · $age';
  }

  @override
  String get lbSeeMore => 'See more';

  @override
  String get lbRecent => 'Recently updated';

  @override
  String lbMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min read',
      one: '1 min read',
    );
    return '$_temp0';
  }

  @override
  String lbMinutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String lbRangeWeeks(int from, int to) {
    return '$from–$to weeks';
  }

  @override
  String lbRangeMonths(int from, int to) {
    return '$from–$to months';
  }

  @override
  String lbRangeYears(int from, int to) {
    return '$from–$to years';
  }

  @override
  String lbStageWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Week $count',
      one: 'Week 1',
    );
    return '$_temp0';
  }

  @override
  String lbStageMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String lbReviewedBy(String reviewer, String credential, String month) {
    return 'Reviewed by $reviewer · $credential, $month';
  }

  @override
  String get lbIllustrative =>
      'Written from WHO, AAP and NHS guidance · For reference, not a substitute for a doctor';

  @override
  String get lbOfflineLibrary =>
      'No connection. The library is showing the copy saved on this phone.';

  @override
  String get lbOfflineStages =>
      'No connection. Your baby’s stages are showing the copy saved on this phone.';

  @override
  String get lbEmptyTitle => 'The library is on its way';

  @override
  String get lbEmptyBody =>
      'Articles will appear here as soon as they are published.';

  @override
  String get lbEmptyOfflineTitle => 'Nothing saved on this phone yet';

  @override
  String get lbEmptyOfflineBody =>
      'Connect once to download the content; after that it reads offline too.';

  @override
  String lbResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get lbFilters => 'Filters';

  @override
  String lbFiltersCount(int count) {
    return 'Filters · $count';
  }

  @override
  String lbRemoveFilter(String label) {
    return 'Remove filter $label';
  }

  @override
  String get lbClearSearch => 'Clear search';

  @override
  String get lbSortTitle => 'Sort by';

  @override
  String get lbSortRelevant => 'Most relevant';

  @override
  String get lbSortNewest => 'Recently updated';

  @override
  String get lbSortShortest => 'Quickest read';

  @override
  String get lbNoResults => 'No matching articles';

  @override
  String get lbNoResultsHint => 'Try other words or fewer filters.';

  @override
  String get lbFilterTopic => 'Topic';

  @override
  String get lbFilterAge => 'Age';

  @override
  String get lbFilterTime => 'Reading time';

  @override
  String get lbTimeShort => 'Under 3 min';

  @override
  String get lbTimeMedium => '3–6 min';

  @override
  String get lbTimeLong => 'Over 6 min';

  @override
  String get lbReset => 'Reset';

  @override
  String lbShowN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See $count articles',
      one: 'See 1 article',
    );
    return '$_temp0';
  }

  @override
  String get lbSave => 'Save';

  @override
  String get lbUnsave => 'Remove from saved';

  @override
  String get lbSavedToast => 'Saved · find it in Library › Saved';

  @override
  String get lbView => 'View';

  @override
  String get lbUnsavedToast => 'Removed from saved';

  @override
  String get lbUndo => 'Undo';

  @override
  String get lbSaveFailed => 'Couldn’t save. Please try again.';

  @override
  String get lbTextSize => 'Text size';

  @override
  String get lbRelated => 'Related articles';

  @override
  String get lbSources => 'Sources';

  @override
  String get lbOpenFirstAid => 'Danger signs? Open child first aid';

  @override
  String get lbArticleFootnote =>
      'For reference only; it does not replace a doctor’s diagnosis. Every baby grows at their own pace.';

  @override
  String get lbArticleMissing => 'This article is no longer in the library';

  @override
  String get lbArticleMissingBody =>
      'It may have been taken down for an update. Open the library again.';

  @override
  String lbSavedToday(String topic) {
    return '$topic · saved today';
  }

  @override
  String lbSavedOn(String topic, String date) {
    return '$topic · saved $date';
  }

  @override
  String get lbSavedEmptyTitle => 'Nothing saved yet';

  @override
  String get lbSavedEmptyBody =>
      'Tap Save while reading an article to keep it here.';

  @override
  String lbUpdated(String title) {
    return '“$title” has been updated. Open it to see the new version.';
  }

  @override
  String get lbStagesTitle => 'Your baby’s stages';

  @override
  String get lbStagesIntro =>
      'Short ideas for each stage. Every baby grows at their own pace.';

  @override
  String get lbHere => 'Baby is here';

  @override
  String get lbDoing => 'How your baby is doing';

  @override
  String get lbTry => 'Things to try together';

  @override
  String get lbMilestones => 'Common milestones';

  @override
  String get lbWeekCardSub => 'This week’s ideas in Growing rhythm';

  @override
  String get lbStageFootnote => 'Every baby develops at their own pace.';

  @override
  String get lbStageMissing => 'This stage is no longer available';

  @override
  String get lbStageMissingBody =>
      'Open Your baby’s stages again to see what is available.';

  @override
  String get lbStagesEmptyTitle => 'Stage content is on its way';

  @override
  String get lbStagesEmptyBody =>
      'Ideas for each stage will appear here as soon as they are published.';

  @override
  String get lbNoDobTitle => 'Add your baby’s date of birth';

  @override
  String get lbNoDobBody =>
      'So Child Life can suggest what fits their age and remind you of Wonder Weeks and milestones.';

  @override
  String get lbNoDobAction => 'Add date of birth';

  @override
  String get lbNoDobViewerTitle => 'Your baby’s stage isn’t known here';

  @override
  String lbNoDobViewer(String name) {
    return 'You can’t see $name’s date of birth, so the current stage isn’t marked. You can still read every stage.';
  }

  @override
  String get asLumiIntroEyebrow => 'New';

  @override
  String get asLumiIntroTitle => 'Meet Lumi, your family’s helper';

  @override
  String get asLumiIntroBody =>
      'Tap to log a feed in one line, ask about your baby’s records or send a receipt photo. Lumi drafts, you review and save.';

  @override
  String get asLumiIntroBodyText =>
      'Tap to log a feed in one line or ask about your baby’s records. Lumi drafts, you review and save.';

  @override
  String get asLumiIntroBodyViewer =>
      'Tap to ask Lumi about your baby’s records.';

  @override
  String get asLumiIntroLater => 'Later';

  @override
  String get asLumiIntroTry => 'Try it';

  @override
  String get asUsageButton => 'Usage';

  @override
  String get rhPlannedTonight => 'Planned · tonight';

  @override
  String get rhPlannedToday => 'Planned · today';

  @override
  String rhPlannedOn(String date) {
    return 'Planned · $date';
  }

  @override
  String rhEveningDate(String date) {
    return '$date evening';
  }

  @override
  String rhPlannedBy(String who, String when) {
    return '$who planned it · $when';
  }

  @override
  String get rhPlanAskMorning => 'You can tell how it went tomorrow morning.';

  @override
  String get rhPlanAskEvening => 'You can tell how it went from 6 pm today.';

  @override
  String get rhKickerFollowUp => 'DID YOU GET A CHANCE TO TRY IT?';

  @override
  String get rhCancelPlan => 'Cancel plan';

  @override
  String get rhPlanCanceled => 'Plan cancelled';

  @override
  String get rhDidNotTry => 'Didn’t try';

  @override
  String get rhDidNotTryToast => 'No problem, you can try another time.';

  @override
  String get rhTriedHistoryTitle => 'What we’ve tried';

  @override
  String rhTriedHistoryBody(int days) {
    return 'Suggestions the family planned or answered in the last $days days, who did and how it went.';
  }

  @override
  String get rhTriedHistoryEmpty => 'Nothing planned or tried yet.';

  @override
  String get rhSeeAllTried => 'See all';

  @override
  String rhWeekMakeVideo(int n) {
    return 'Make a week $n video';
  }

  @override
  String get rhWeekMakeVideoPlain => 'Make a video of the week';

  @override
  String rhWeekVideoPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos from the week are picked',
      one: '1 photo from the week is picked',
    );
    return '$_temp0';
  }

  @override
  String hnStepOf(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String hnContinueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'Continue · $count $_temp0';
  }

  @override
  String get hnNotifTitle => 'Let Child Life remind you at the right time';

  @override
  String get hnNotifBody =>
      'Only what you just picked and the reminders you set. No ads.';

  @override
  String get hnNotifExamples => 'You may get these';

  @override
  String get hnNotifExampleTag => 'Example';

  @override
  String get hnNotifVaccine => 'Vaccine reminders';

  @override
  String get hnNotifVaccineWhen => 'Before the visit';

  @override
  String get hnNotifVaccineSample => '“6-in-1 vaccine tomorrow at 08:30.”';

  @override
  String get hnNotifRhythm => 'Growing rhythm';

  @override
  String get hnNotifRhythmWhen => '3 days before';

  @override
  String get hnNotifRhythmSample =>
      '“By the reference calendar, stage 1 is coming up.”';

  @override
  String get hnNotifWeek => 'Weekly summary';

  @override
  String get hnNotifWeekWhen => 'Sunday 20:30';

  @override
  String get hnNotifWeekSample =>
      '“Your little one’s week is ready to look back on.”';

  @override
  String get hnNotifAllow => 'Turn on notifications';

  @override
  String get hnNotifSettingsHint => 'Turn off or adjust in Me › Notifications';

  @override
  String get hnNotifDenied =>
      'Notifications are still off. You can turn them on in your phone\'s Settings.';

  @override
  String get hnNotifBodyAlone =>
      'Vaccine dates, the reminders you set and your little one\'s special days. No ads.';

  @override
  String get hnNotifMilestone => 'Special days';

  @override
  String get hnNotifMilestoneWhen => '09:00 on the day';

  @override
  String hnNotifMilestoneSample(String name) {
    return '“$name is 1 month old today.”';
  }

  @override
  String get hnInviteTitle => 'Today, your family\'s way';

  @override
  String get hnInviteBody => 'Pick what matters to you · 30 seconds';

  @override
  String get hnInviteStart => 'Start';

  @override
  String get hnInviteClose => 'Hide the personalisation invite';

  @override
  String get hnInviteHidden =>
      'Hidden. You can still adjust this in Me › Personalisation.';

  @override
  String get hnForBabyBecause => 'Based on what you care about';

  @override
  String get hnForBabyNoInterests => 'No interests picked yet';

  @override
  String get hnForBabyChange => 'Change';

  @override
  String get hnForBabyPick => 'Pick';

  @override
  String get hnRhythmPill => 'Growing rhythm · Beta';

  @override
  String hnRhythmExpected(String range) {
    return 'By the reference calendar, expected $range.';
  }

  @override
  String hnRhythmSoothing(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'day',
    );
    return 'The family noted more soothing over the past $_temp0.';
  }

  @override
  String hnCardPage(int page, int count) {
    return 'Card $page of $count';
  }

  @override
  String get hnCardOptions => 'Options for this card';

  @override
  String get mtTitle => 'Milestones';

  @override
  String mtSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count milestones',
      one: '1 milestone',
    );
    return '$name has $_temp0';
  }

  @override
  String mtSummaryNone(String name) {
    return 'No milestones for $name yet';
  }

  @override
  String get mtLead =>
      'Record it when you see your baby do it. Every baby has their own pace.';

  @override
  String get mtLeadViewer =>
      'Reference milestones by age. Every baby has their own pace.';

  @override
  String get mtFilterAll => 'All';

  @override
  String get mtGroupMotor => 'Movement';

  @override
  String get mtGroupCommunication => 'Communication';

  @override
  String get mtGroupCognitive => 'Thinking & learning';

  @override
  String get mtGroupSocial => 'Social & emotional';

  @override
  String get mtOwn => 'Our own';

  @override
  String get mtSeen => 'Observed';

  @override
  String get mtFollowingSection => 'Following';

  @override
  String get mtAround => 'Around your baby’s age';

  @override
  String get mtReferenceSection => 'Reference milestones';

  @override
  String get mtOthers => 'Other milestones';

  @override
  String mtShowAll(int count) {
    return 'See all milestones ($count)';
  }

  @override
  String get mtShowLess => 'Show less';

  @override
  String mtRangeMonths(int from, int to) {
    return 'typically $from–$to months';
  }

  @override
  String mtRangeWeeks(int from, int to) {
    return 'typically $from–$to weeks';
  }

  @override
  String mtRangeChipMonths(int from, int to) {
    return 'Typically $from–$to months';
  }

  @override
  String mtRangeChipWeeks(int from, int to) {
    return 'Typically $from–$to weeks';
  }

  @override
  String get mtUpcoming => 'Coming up';

  @override
  String get mtNotRecorded => 'Not recorded';

  @override
  String get mtFollowingTag => 'Following';

  @override
  String get mtCreateOwn => 'Create your own milestone';

  @override
  String get mtIllustrative =>
      'Written from WHO, AAP and NHS guidance · For reference, not a substitute for a doctor';

  @override
  String get mtNotInMemoriesTile => 'Not in Memories yet';

  @override
  String mtReviewed(String reviewer) {
    return 'Reviewed by $reviewer';
  }

  @override
  String get mtEmptyTitle => 'No reference milestones yet';

  @override
  String get mtEmptyBody =>
      'The guide is being prepared. You can still create your own milestones.';

  @override
  String get mtEmptyBodyViewer => 'The guide is being prepared.';

  @override
  String get mtNoDob =>
      'Add your baby’s date of birth to see suggestions for their age.';

  @override
  String get mtEntrySub => 'Record what your baby can do';

  @override
  String mtEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count milestones recorded',
      one: '1 milestone recorded',
    );
    return '$_temp0';
  }

  @override
  String get mtHowTo => 'How to recognise it';

  @override
  String get mtReassure =>
      'Age ranges are for reference only. Every baby has their own pace — if you are unsure, ask your baby’s doctor.';

  @override
  String get mtTalkToDoctor => 'When to ask the doctor';

  @override
  String get mtHealthLink => 'See health guidance';

  @override
  String get mtMarkSeen => 'Mark as observed';

  @override
  String get mtFollow => 'Save to follow';

  @override
  String get mtUnfollow => 'Stop following';

  @override
  String get mtFollowed => 'Saved to follow';

  @override
  String get mtUnfollowed => 'No longer following';

  @override
  String get mtSources => 'Sources';

  @override
  String get mtParentsRecord => 'Baby’s parents record milestones here.';

  @override
  String get mtNotFound => 'This milestone wasn’t found.';

  @override
  String get mtDateDid => 'The day your baby did it';

  @override
  String get mtNote => 'Note';

  @override
  String get mtNoteHint => 'When, where, with whom…';

  @override
  String get mtPhotosOptional => 'Photos and videos (optional)';

  @override
  String get mtAddPhotos => 'Add photos or videos';

  @override
  String get mtRemovePhoto => 'Remove this item';

  @override
  String get mtSave => 'Save milestone';

  @override
  String get mtPickDate => 'Choose a day';

  @override
  String get mtSaved => 'Milestone saved';

  @override
  String get mtSaveFailed => 'Couldn’t save. Please try again.';

  @override
  String mtMeta(String date, String name, String age, String who) {
    return '$date · $name was $age · recorded by $who';
  }

  @override
  String mtMetaNoAge(String date, String who) {
    return '$date · recorded by $who';
  }

  @override
  String get mtKeepTitle => 'Keep this moment in Memories?';

  @override
  String mtKeepBody(String name) {
    return 'Create a memory with these photos and this note, tagged “$name”.';
  }

  @override
  String mtKeepBodyNote(String name) {
    return 'Create a memory tagged “$name” — add photos if you like.';
  }

  @override
  String get mtCreateMemory => 'Create memory';

  @override
  String get mtCreateCard => 'Make a milestone card';

  @override
  String get mtInMemories => 'Saved in Memories';

  @override
  String mtSeenByFamily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'The whole family can see it · $_temp0';
  }

  @override
  String mtSeenByParents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'Parents only · $_temp0';
  }

  @override
  String get mtSeenByFamilyNote => 'The whole family can see it · note';

  @override
  String get mtSeenByParentsNote => 'Parents only · note';

  @override
  String get mtUploading => 'Uploading to Memories…';

  @override
  String get mtMore => 'More actions';

  @override
  String get mtEdit => 'Edit';

  @override
  String get mtDelete => 'Remove this record';

  @override
  String get mtDeleteTitle => 'Remove this milestone record?';

  @override
  String get mtDeleteBody =>
      'The day and the note are removed. Memories you made stay in Memories.';

  @override
  String get mtDeleted => 'Record removed';

  @override
  String get mtNewMemory => 'New memory';

  @override
  String get mtCaption => 'Caption';

  @override
  String get mtCaptionHint => 'A few words about this moment';

  @override
  String mtTag(String name) {
    return 'Milestone · $name';
  }

  @override
  String get mtWhoSees => 'Who can see';

  @override
  String get mtSaveMemory => 'Save memory';

  @override
  String get mtMemoryCreated => 'Memory created';

  @override
  String get mtCaptionRequired =>
      'Add a caption or a photo to save the memory.';

  @override
  String get mtOwnLead => 'Firsts only your family has — record them your way.';

  @override
  String get mtName => 'Milestone name';

  @override
  String get mtNameHint => 'e.g. First trip to see the grandparents';

  @override
  String mtCount(int count, int max) {
    return '$count/$max characters';
  }

  @override
  String get mtDate => 'Day';

  @override
  String get mtAlsoMemory => 'Also create a memory';

  @override
  String get mtAlsoMemorySub => 'Save the photos and note to Memories';

  @override
  String get mtEditTitle => 'Edit milestone';

  @override
  String lbTodayStageKicker(String range) {
    return 'Your baby’s stage · $range';
  }

  @override
  String get lbTodayStageAction => 'See this stage';

  @override
  String get lbTodayRead => 'Read';

  @override
  String get ntBell => 'Notifications';

  @override
  String ntBellUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get ntInboxTitle => 'Notifications';

  @override
  String get ntMarkAllRead => 'Mark all read';

  @override
  String get ntOpenSettings => 'Notification settings';

  @override
  String get ntFilterAll => 'All';

  @override
  String get ntFilterReminders => 'Reminders';

  @override
  String get ntFilterBaby => 'For baby';

  @override
  String get ntFilterFamily => 'Family';

  @override
  String get ntSectionToday => 'TODAY';

  @override
  String get ntSectionWeek => 'THIS WEEK';

  @override
  String get ntSectionEarlier => 'EARLIER';

  @override
  String get ntUnread => 'Unread';

  @override
  String get ntEmptyTitle => 'No notifications yet';

  @override
  String get ntEmptyBody =>
      'Reminders, vaccinations and family news will show up here.';

  @override
  String get ntEmptyFiltered => 'Nothing in this category yet.';

  @override
  String get ntLoadFailed => 'Couldn’t load notifications. Try again later.';

  @override
  String get ntKept =>
      'Notifications are kept for 90 days. Swipe left to hide one.';

  @override
  String get ntHide => 'Hide';

  @override
  String get ntGone => 'This can’t be opened any more.';

  @override
  String get ntMaster => 'Child Life notifications';

  @override
  String get ntMasterOn => 'On in system settings';

  @override
  String get ntMasterOff => 'Off in system settings';

  @override
  String get ntGroupReminders => 'REMINDERS YOU SET';

  @override
  String get ntGroupRemindersHint => 'Always on time, even in quiet hours';

  @override
  String get ntCare => 'Feeding, sleep, diapers';

  @override
  String get ntCareHint => 'Rule and one-off reminders';

  @override
  String get ntVaccines => 'Vaccinations';

  @override
  String get ntVaccinesHint => '3 days before and the evening before at 19:00';

  @override
  String get ntSpending => 'Spending';

  @override
  String get ntSpendingHint => 'Recurring items, 80% of budget, import results';

  @override
  String get ntGroupBaby => 'SUGGESTIONS FOR BABY';

  @override
  String get ntGroupBabyHint => 'Bundled, at most 2 a day';

  @override
  String get ntRhythm => 'Growth rhythm';

  @override
  String get ntRhythmHint =>
      '3 days before each phase · check-in at most once a day';

  @override
  String get ntStages => 'Baby’s stages';

  @override
  String get ntStagesHint => 'When baby starts a new week / month';

  @override
  String get ntMilestones => 'Milestones';

  @override
  String get ntMilestonesHint => 'When the usual age comes';

  @override
  String get ntArticles => 'Suggested articles';

  @override
  String get ntArticlesHint => 'At most 1 a week';

  @override
  String get ntWeekly => 'Weekly summary';

  @override
  String get ntWeeklyHint => 'Sunday 20:30';

  @override
  String get ntGroupFamily => 'MEMORIES & FAMILY';

  @override
  String get ntPhotos => 'New photos that may include baby';

  @override
  String get ntPhotosHint => 'Auto-save · at most once a day';

  @override
  String get ntKeepsakes => 'Video and card ideas';

  @override
  String get ntKeepsakesHint => 'On month birthdays and at 100 days';

  @override
  String get ntFamilyActivity => 'Family activity';

  @override
  String get ntFamilyActivityHint => 'Likes, memory views';

  @override
  String get ntGroupTiming => 'TIMING';

  @override
  String get ntDigest => 'Suggestion time';

  @override
  String ntDigestDaily(String time) {
    return '$time daily';
  }

  @override
  String get ntQuiet => 'Quiet hours';

  @override
  String ntQuietRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get ntSaveFailed => 'Couldn’t save. Please try again.';

  @override
  String get rhPlannedPill => 'Planned';

  @override
  String mtTodayKicker(String range) {
    return 'A milestone you may see · $range';
  }

  @override
  String get mtTodayAction => 'Record it when you see it';

  @override
  String get mtTodayActionViewer => 'How to recognise it';

  @override
  String get mtEntrySubViewer => 'Reference milestones for your baby’s age';

  @override
  String get hnWhyLink => 'Why this suggestion?';

  @override
  String get hnWhyTitle => 'Why this suggestion';

  @override
  String get hnWhyFeedbackShort => 'Adjusted to your family’s feedback.';

  @override
  String get hnWhyHow =>
      'Suggestions come from what your family noted, your baby’s age and what you care about. This is not a diagnosis.';

  @override
  String get hnWatchThisWeek => 'Worth a look this week';

  @override
  String hnWeekKicker(int n, String age) {
    return 'Week $n · $age';
  }

  @override
  String hnWeekKickerOnly(int n) {
    return 'Week $n';
  }

  @override
  String hnMonthKicker(int n, String age) {
    return 'Month $n · $age';
  }

  @override
  String hnMonthKickerOnly(int n) {
    return 'Month $n';
  }

  @override
  String get hnWeekOpen => 'See this week';

  @override
  String hnWeekOpenIdeas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See $count ideas for this week',
      one: 'See 1 idea for this week',
    );
    return '$_temp0';
  }

  @override
  String hnWeekRhythmSub(String range) {
    return 'Wonder Weeks · expected $range';
  }

  @override
  String get hnWeekSummaryLast => 'Last week’s summary';

  @override
  String get hnWeekSummaryThis => 'This week’s summary';

  @override
  String hnRhythmComingDays(int n, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Stage $n in $days days',
      one: 'Stage $n in 1 day',
    );
    return '$_temp0';
  }

  @override
  String hnRhythmNow(int n) {
    return 'In stage $n';
  }

  @override
  String get asLumiName => 'Lumi';

  @override
  String get asYou => 'You';

  @override
  String get asOnlyYou => 'Only you';

  @override
  String get asOnlyYouSpending =>
      'Only you · spending never goes into the baby’s shared chat';

  @override
  String get asCopy => 'Copy';

  @override
  String get asCopied => 'Copied';

  @override
  String get asShowTime => 'Show the time';

  @override
  String get asNewMessages => 'New messages';

  @override
  String get asOfflineBanner =>
      'You’re offline. Messages are kept and sent only when you tap Send. Direct logging still works.';

  @override
  String get asNotSent => 'Couldn’t send';

  @override
  String get asUnsentOffline => 'Not sent · offline';

  @override
  String get asResend => 'Send again';

  @override
  String get asErrorFriendly =>
      'I couldn’t answer just now. Nothing was saved — try again, or log it directly.';

  @override
  String get asReadingPhoto => 'Lumi is reading the photo…';

  @override
  String get asChipLogSleep => 'Log a sleep';

  @override
  String get asPrefillSleep => 'Slept from ';

  @override
  String get asChipExpense => 'Log an expense';

  @override
  String get asPrefillExpense => 'Bought ';

  @override
  String get asWhenToday => 'Today';

  @override
  String get asWhenYesterday => 'Yesterday';

  @override
  String get asWhenTomorrow => 'Tomorrow';

  @override
  String asTimeOnDay(String time, String day) {
    return '$time $day';
  }

  @override
  String asThreadWhen(String day, String time) {
    return '$day · $time';
  }

  @override
  String get asOlderFailed => 'Couldn\'t load earlier messages.';

  @override
  String asSpanLine(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String get asSpanInvalid => 'ends before it starts';

  @override
  String asSpanKnown(String duration) {
    return 'From the length you said: $duration';
  }

  @override
  String get asPickSleepTitle => 'When did the sleep start?';

  @override
  String get asPickWakeTitle => 'When did baby wake up?';

  @override
  String asAnswerWith(String time) {
    return 'Answer: $time';
  }

  @override
  String get asFieldSleepStart => 'Fell asleep';

  @override
  String get asFieldSleepEnd => 'Woke up';

  @override
  String get asFieldDuration => 'Length';

  @override
  String get asShorter => '15 minutes shorter';

  @override
  String get asLonger => '15 minutes longer';

  @override
  String get asLessMl => '10 ml less';

  @override
  String get asMoreMl => '10 ml more';

  @override
  String get asLessMinutes => '5 minutes less';

  @override
  String get asMoreMinutes => '5 minutes more';

  @override
  String asBabyLockedLine(String name) {
    return 'For $name · can’t move to another baby';
  }

  @override
  String get asPickOtherDay => 'Another day';

  @override
  String get asVoiceStart => 'Talk to Lumi';

  @override
  String get asVoiceStop => 'Stop listening';

  @override
  String get asVoiceCancel => 'Discard what was said';

  @override
  String get asVoiceListening => 'Listening…';

  @override
  String get asVoiceSwipe => 'Listening… swipe left to cancel';

  @override
  String get asVoiceIntroTitle => 'Talk to Lumi instead of typing';

  @override
  String get asVoiceIntroWords =>
      'Tap the mic and speak. The words appear in the message box; you can fix them, and they’re sent only when you tap Send.';

  @override
  String get asVoiceIntroServerIos =>
      'Your iPhone turns speech into words on the device when it can. When it can’t (for example without offline support for the language), Apple’s speech recognition may process the audio on Apple’s servers.';

  @override
  String get asVoiceIntroServerAndroid =>
      'Your phone turns speech into words on the device when it can. When it can’t, the phone’s speech service (usually Google’s) may process the audio on its servers.';

  @override
  String get asVoiceIntroNothingKept =>
      'Child Life doesn’t record, keep or send any audio. Only the words you send reach Lumi.';

  @override
  String get asVoiceIntroFree => 'Speaking instead of typing uses no AI help.';

  @override
  String get asVoiceIntroAllow => 'Turn on the mic';

  @override
  String get asVoiceIntroLater => 'Not now';

  @override
  String get asVoiceDenied =>
      'No access to the mic or speech recognition. Turn it on in Settings to talk to Lumi.';

  @override
  String get asVoiceUnavailable =>
      'This phone can’t recognise speech right now. Please type instead.';

  @override
  String get asVoiceLanguage =>
      'This phone can’t recognise English speech yet. Add the language in the phone’s settings, or type instead.';

  @override
  String get asVoiceNoSpeech =>
      'I didn’t hear anything. Try speaking closer to the phone.';

  @override
  String get asVoiceFailed =>
      'Speech recognition stopped. Any words so far stay in the box.';

  @override
  String get asChipFeedsShort => 'Today’s feeds';

  @override
  String get asEditInModule => 'Edit in the log';

  @override
  String get asSpendingMoved =>
      'Only you: a message about spending stays in your private chat.';

  @override
  String get asSaveBottle => 'Save bottle feed';

  @override
  String get asSaveBreast => 'Save feed';

  @override
  String get asSaveSleep => 'Save sleep';

  @override
  String get asSaveReminder => 'Save reminder';

  @override
  String get asSaveItem => 'Save';

  @override
  String asSaveItems(int count) {
    return 'Save $count items';
  }

  @override
  String asStillToFill(int count) {
    return '$count item(s) above still need a detail';
  }

  @override
  String get asKindTimer => 'Timer';

  @override
  String get asTimerTitleStartSleep => 'Sleep timer';

  @override
  String get asTimerTitleStartBreast => 'Breastfeeding timer';

  @override
  String get asTimerTitleStopSleep => 'End the sleep';

  @override
  String get asTimerTitleStopBreast => 'End the feed';

  @override
  String asTimerStartSleep(String time) {
    return 'Start sleep timer · $time';
  }

  @override
  String asTimerStartBreast(String side, String time) {
    return 'Start feed timer · $side · $time';
  }

  @override
  String asTimerStopSleep(String time) {
    return 'End sleep · $time';
  }

  @override
  String asTimerStopBreast(String time) {
    return 'End feed · $time';
  }

  @override
  String get asTimerKeep => 'Keep running';

  @override
  String asTimerFrom(String time) {
    return 'From $time';
  }

  @override
  String asTimerSideFirst(String side) {
    return '$side side first';
  }

  @override
  String asTimerSleeping(String elapsed) {
    return 'Asleep · $elapsed';
  }

  @override
  String asTimerFeeding(String elapsed) {
    return 'Feeding · $elapsed';
  }

  @override
  String get asTimerOpen => 'Open timer';

  @override
  String get asTimerEnded => 'The timer has ended';

  @override
  String asTimerRunningSince(String time) {
    return 'Running since $time';
  }

  @override
  String get asErrTimerRunning =>
      'This timer was already started on another phone.';

  @override
  String get asErrTimerChanged =>
      'The timer ended or changed on another phone.';

  @override
  String get asGapFeedTime => 'No feed time yet';

  @override
  String get asGapSleepStart => 'No time the sleep started';

  @override
  String get asGapSleepEnd => 'No wake-up time yet';

  @override
  String asGapTimeUnsure(String time) {
    return 'Is $time right?';
  }

  @override
  String asGapTimeFuture(String time) {
    return '$time hasn’t happened yet. Pick the time again.';
  }

  @override
  String get asGapSleepOrder => 'The wake-up must be after the sleep started';

  @override
  String get asGapAmount => 'No amount yet (ml)';

  @override
  String asGapAmountUnsure(String ml) {
    return 'Is $ml ml right?';
  }

  @override
  String get asGapAmountRange => 'The amount must be 1–500 ml';

  @override
  String get asGapMilk => 'Breast milk or formula?';

  @override
  String get asGapSide => 'Which side?';

  @override
  String asGapDurationUnsure(String duration) {
    return 'Is $duration right?';
  }

  @override
  String get asGapDurationRange => 'A feed can’t be longer than 180 minutes';

  @override
  String get asGapWhen => 'Day or night sleep? (optional)';

  @override
  String asGapDateUnsure(String date) {
    return 'Is $date right?';
  }

  @override
  String get asGapReminderDate => 'No reminder date yet';

  @override
  String get asGapReminderPast => 'That time has passed. Pick another day.';

  @override
  String get asGapTitle => 'The title is too long (80 characters max)';

  @override
  String get asGapAssignee => 'The assignee is no longer in the family';

  @override
  String get asGapTimerOld =>
      'A timer can’t start that long ago. Pick a later time.';

  @override
  String asGapTimerEnd(String time) {
    return 'The end must be after $time';
  }

  @override
  String get asGapExpenseAmount => 'No amount yet';

  @override
  String get asGapExpenseAmountUnsure => 'Is the amount right?';

  @override
  String get asGapExpenseCurrency => 'Which currency?';

  @override
  String get asGapExpenseCategory => 'Is the category right?';

  @override
  String get asGapExpenseMerchant => 'Is the shop right?';

  @override
  String get asFixRight => 'That’s right';

  @override
  String asFixJustNow(String time) {
    return 'Just now ($time)';
  }

  @override
  String asFixAgo30(String time) {
    return '30 min ago ($time)';
  }

  @override
  String asFixAgo60(String time) {
    return '1 hour ago ($time)';
  }

  @override
  String asFixWokeNow(String time) {
    return 'Just woke ($time)';
  }

  @override
  String asFixSlept(int hours, String time) {
    return '$hours h (from $time)';
  }

  @override
  String get asFixPickTime => 'Pick a time';

  @override
  String get asFixPickDate => 'Pick a date';

  @override
  String get asFixToday => 'Today';

  @override
  String get asFixYesterday => 'Yesterday';

  @override
  String get asFixTomorrow => 'Tomorrow';

  @override
  String asFixMl(String ml) {
    return '$ml ml';
  }

  @override
  String get asFixDayTime => 'Daytime';

  @override
  String get asFixNightTime => 'Night';

  @override
  String get asFixNoAssignee => 'Nobody';

  @override
  String get asFixed => 'All set, ready to save';

  @override
  String get asPickAboveToSave => 'Pick above and it’s ready to save.';

  @override
  String get asGapWhenAsk => 'Day or night sleep?';

  @override
  String get asGapNote => 'Is the note right?';

  @override
  String get asFixDropNote => 'Remove the note';

  @override
  String get asGapObservation => 'Is the kind of note right?';

  @override
  String get asKindGrowth => 'Measurement';

  @override
  String asMeasuredOnLine(String date) {
    return 'Measured $date';
  }

  @override
  String get asPumpSideLeft => 'Left side';

  @override
  String get asPumpSideRight => 'Right side';

  @override
  String get asPumpSideBoth => 'Both sides';

  @override
  String get asOpenModule => 'Open';

  @override
  String get asSaveDiaper => 'Save diaper change';

  @override
  String get asGapPumpTime => 'No pumping time yet';

  @override
  String get asGapDiaperTime => 'No diaper change time yet';

  @override
  String asGapSleepStartUnsure(String time) {
    return 'Fell asleep at $time — is that right?';
  }

  @override
  String asGapSleepEndUnsure(String time) {
    return 'Woke up at $time — is that right?';
  }

  @override
  String asFixTomorrowAt(String time) {
    return 'Tomorrow $time';
  }

  @override
  String get asGapPumpAmount => 'No pumped amount yet (ml)';

  @override
  String get asGapPumpAmountRange => 'The pumped amount must be 1–1000 ml';

  @override
  String get asGapPumpSide => 'Which side was pumped?';

  @override
  String get asGapPumpDuration => 'How long did pumping take?';

  @override
  String get asGapPumpDurationRange =>
      'Pumping can’t be longer than 240 minutes';

  @override
  String get asGapDiaper => 'Wet, dirty or both?';

  @override
  String get asGapWeight => 'No weight yet (kg)';

  @override
  String asGapWeightUnsure(String kg) {
    return 'Is the weight of $kg kg right?';
  }

  @override
  String get asFixEnterWeight => 'Enter the weight';

  @override
  String get asGapLength => 'No length yet (cm)';

  @override
  String asGapLengthUnsure(String cm) {
    return 'Is the length of $cm cm right?';
  }

  @override
  String get asFixEnterLength => 'Enter the length';

  @override
  String get asFixDropLength => 'Leave out the length';

  @override
  String get asGapMeasuredOn => 'No measuring date yet';

  @override
  String get asGapMeasuredOnFuture =>
      'That day hasn’t come yet. Pick the measuring date again.';

  @override
  String asGapMeasuredOnUnsure(String date) {
    return 'Measured on $date — is that right?';
  }

  @override
  String get asEditPump => 'Edit pumping';

  @override
  String get asEditDiaper => 'Edit diaper change';

  @override
  String get asEditGrowth => 'Edit measurement';

  @override
  String get asFieldWeight => 'Weight';

  @override
  String get asFieldLength => 'Length · optional';

  @override
  String get asFieldMeasuredOn => 'Measuring date';

  @override
  String get asFieldDiaper => 'Diaper';

  @override
  String get growthHeadOptional => 'Head circumference · optional';

  @override
  String get growthHeadRange => 'Head circumference from 20 to 60 cm.';

  @override
  String headCm(String v) {
    return 'head $v cm';
  }

  @override
  String get growthHeadTab => 'Head';

  @override
  String get detailHead => 'Head circumference';

  @override
  String bpHead(String when) {
    return 'Head · $when';
  }

  @override
  String whoBelowHeadNote(String name) {
    return '$name’s head circumference is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String whoAboveHeadNote(String name) {
    return '$name’s head circumference is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.';
  }

  @override
  String get asFieldHead => 'Head circumference · optional';

  @override
  String get asGapHead => 'No head circumference yet (cm)';

  @override
  String asGapHeadUnsure(String cm) {
    return 'Is the head circumference $cm cm right?';
  }

  @override
  String get asFixEnterHead => 'Enter head circumference';

  @override
  String get asFixDropHead => 'Remove head circumference';

  @override
  String get asAskAmount => 'How much did it cost?';

  @override
  String get growthMeasureNone =>
      'Nothing measured yet. Add it at the next measurement.';
}
