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
  String get inviteCodeComingSoon =>
      'Joining with an invite code arrives in the next build.';

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
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
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
}
