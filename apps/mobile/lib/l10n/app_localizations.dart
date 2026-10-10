import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Product name, not translated.
  ///
  /// In vi, this message translates to:
  /// **'Child Life'**
  String get appTitle;

  /// Shown when the build's environment configuration is inconsistent.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình môi trường không hợp lệ.'**
  String get configErrorTitle;

  /// S0 diagnostics: label for dev/prod.
  ///
  /// In vi, this message translates to:
  /// **'Môi trường'**
  String get diagnosticsEnvironment;

  /// S0 diagnostics: backend round trip row.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối máy chủ'**
  String get diagnosticsServer;

  /// S0 diagnostics: successful round trip.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối {projectId} ({region})'**
  String diagnosticsConnected(String projectId, String region);

  /// S0 diagnostics: round trip in progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get diagnosticsChecking;

  /// S0 diagnostics: round trip failed.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được: {error}'**
  String diagnosticsUnreachable(String error);

  /// Tooltip for retrying the round trip.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại'**
  String get diagnosticsRetry;

  /// S0 diagnostics: feature flag row.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình tính năng'**
  String get diagnosticsFlags;

  /// No feature flag document yet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cấu hình'**
  String get diagnosticsFlagsEmpty;

  /// Number of enabled flags out of total.
  ///
  /// In vi, this message translates to:
  /// **'{enabled}/{total} đang bật'**
  String diagnosticsFlagsCount(int enabled, int total);

  /// Generic loading text.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get diagnosticsLoading;

  /// Reading the flag document failed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được: {error}'**
  String diagnosticsUnreadable(String error);

  /// Dev-only action that forces a crash.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lỗi thử tới Crashlytics'**
  String get diagnosticsTestCrash;

  /// Subtitle for dev-only actions.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ có ở bản dev'**
  String get diagnosticsDevOnly;

  /// Accessibility label of the round back button (8:37).
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get a11yBack;

  /// Accessibility label of sheet close buttons (37:293).
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get a11yClose;

  /// Accessibility label of the round next button (8:34).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get a11yNext;

  /// Accessibility label of the + quick-log button (44:363).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh'**
  String get a11yQuickLog;

  /// Accessibility label of the moon toggle; product term kept in English in Figma.
  ///
  /// In vi, this message translates to:
  /// **'Night care'**
  String get a11yNightCareToggle;

  /// Bottom tab: Today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get tabToday;

  /// Bottom tab: Memories.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get tabMemories;

  /// Bottom tab: Family.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get tabFamily;

  /// Bottom tab: Me.
  ///
  /// In vi, this message translates to:
  /// **'Tôi'**
  String get tabMe;

  /// Top bar skip action (23:195).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get actionSkip;

  /// Eye toggle on password fields (23:243).
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// Eye toggle on password fields (23:243).
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// Primary continue button on setup screens (10a, 11).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get actionNext;

  /// Sheet confirm button (11a, 11b, 11c, 13a).
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get actionDone;

  /// Defers an optional step (P-008 verify email).
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get actionLater;

  /// Retries a failed action.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get actionRetry;

  /// Opens the OS settings after a permission was denied.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get actionOpenSettings;

  /// Splash tagline (36:2233).
  ///
  /// In vi, this message translates to:
  /// **'Cùng chăm con. Giữ tuổi thơ.'**
  String get splashTagline;

  /// Welcome title (26:4).
  ///
  /// In vi, this message translates to:
  /// **'Cùng chăm con,\ngiữ trọn tuổi thơ'**
  String get welcomeTitle;

  /// Welcome primary: feature tour.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get welcomeExplore;

  /// Welcome: go to sign-in.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get welcomeSignIn;

  /// Welcome: enter an invite code (S3).
  ///
  /// In vi, this message translates to:
  /// **'Mã mời'**
  String get welcomeInviteCode;

  /// Welcome hero chip.
  ///
  /// In vi, this message translates to:
  /// **'Mốc mới'**
  String get welcomeChipMilestone;

  /// Shown until invites ship (S3).
  ///
  /// In vi, this message translates to:
  /// **'Nhận lời mời bằng mã sẽ có ở bản tiếp theo.'**
  String get inviteCodeComingSoon;

  /// Moon button on the Welcome top bar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giao diện sáng / tối'**
  String get a11yToggleAppearance;

  /// Tour 1/4 title (26:85).
  ///
  /// In vi, this message translates to:
  /// **'Ghi bú, ngủ, tã\nchỉ bằng một tay'**
  String get tourCareTitle;

  /// Tour 1/4 body.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 3 chạm là lưu xong.'**
  String get tourCareBody;

  /// Tour 1 chip.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình · 120 ml'**
  String get tourCareChipBottle;

  /// Tour 1 chip.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã · Ướt'**
  String get tourCareChipDiaper;

  /// Tour 1 chip.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ · 1 giờ 20'**
  String get tourCareChipSleep;

  /// Tour 1 badge under the number 3.
  ///
  /// In vi, this message translates to:
  /// **'chạm'**
  String get tourCareTaps;

  /// Tour 2/4 title (26:151).
  ///
  /// In vi, this message translates to:
  /// **'Nhận ca, không cần hỏi'**
  String get tourShareTitle;

  /// Tour 2/4 body.
  ///
  /// In vi, this message translates to:
  /// **'Lần ghi gần nhất được đồng bộ cho cả nhà: ai ghi, ghi gì, lúc nào.'**
  String get tourShareBody;

  /// Tour 2 chip.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ'**
  String get tourShareSynced;

  /// Tour 2 ring label.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ'**
  String get tourShareAsleep;

  /// Tour 2 chip.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình · 80 ml · Mẹ ghi'**
  String get tourShareChipMom;

  /// Tour 2 chip.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã · Ướt · Ba ghi'**
  String get tourShareChipDad;

  /// Initial of Mum in tour 2.
  ///
  /// In vi, this message translates to:
  /// **'M'**
  String get tourShareInitialMom;

  /// Initial of Dad in tour 2.
  ///
  /// In vi, this message translates to:
  /// **'B'**
  String get tourShareInitialDad;

  /// Tour 3/4 title (26:211).
  ///
  /// In vi, this message translates to:
  /// **'Khoảnh khắc\nthành chuyện'**
  String get tourStoryTitle;

  /// Tour 3/4 body.
  ///
  /// In vi, this message translates to:
  /// **'Một ảnh thành thẻ kỷ niệm ngay. Cuối tuần có nhật ký của bé.'**
  String get tourStoryBody;

  /// Tour 3 chip.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ kỷ niệm tức thì'**
  String get tourStoryChipCard;

  /// Tour 3 chip.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký tuần 8'**
  String get tourStoryChipJournal;

  /// Tour 4/4 title (26:277).
  ///
  /// In vi, this message translates to:
  /// **'Đúng người,\nđúng quyền'**
  String get tourPrivateTitle;

  /// Tour 4/4 body.
  ///
  /// In vi, this message translates to:
  /// **'Bà được xem ảnh, cô trông trẻ được ghi cữ bú. Bạn quyết định ai thấy gì.'**
  String get tourPrivateBody;

  /// Tour 4 chip.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chọn quyền'**
  String get tourPrivateChipAccess;

  /// Tour 4 chip.
  ///
  /// In vi, this message translates to:
  /// **'Mời người thân'**
  String get tourPrivateChipInvite;

  /// Tour 4 avatar initials: mother|father|grandma|nanny, separated by |.
  ///
  /// In vi, this message translates to:
  /// **'M|B|Bà|L'**
  String get tourPrivateInitials;

  /// Tour 4/4 primary.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hồ sơ bé'**
  String get tourCreateProfile;

  /// Sign-in sheet title (27:488).
  ///
  /// In vi, this message translates to:
  /// **'Chào bạn'**
  String get signInTitle;

  /// Sign-in sheet subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để bắt đầu.'**
  String get signInSubtitle;

  /// Apple button label.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Apple'**
  String get signInApple;

  /// Google button label.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get signInGoogle;

  /// Email option.
  ///
  /// In vi, this message translates to:
  /// **'Dùng email'**
  String get signInEmail;

  /// Legal link under the sign-in buttons (Q-020).
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản · Quyền riêng tư'**
  String get signInLegal;

  /// Letters on the two toy blocks of the sign-in illustration (kept as in Figma).
  ///
  /// In vi, this message translates to:
  /// **'B|é'**
  String get signInHeroLetters;

  /// Email screen title (27:538).
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailTitle;

  /// Segment: create account.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản mới'**
  String get emailNewAccount;

  /// Segment: sign in.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get emailSignInTab;

  /// Email field label.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email field placeholder.
  ///
  /// In vi, this message translates to:
  /// **'ten@email.com'**
  String get emailPlaceholder;

  /// Password field label.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordLabel;

  /// Password placeholder (R-002).
  ///
  /// In vi, this message translates to:
  /// **'8+ ký tự'**
  String get passwordPlaceholder;

  /// Primary on the new-account segment.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get emailCreateAccount;

  /// Primary on the sign-in segment (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get emailSignInButton;

  /// Plain link to screen 10.
  ///
  /// In vi, this message translates to:
  /// **'Email đã dùng với Apple/Google?'**
  String get emailUsedWithProvider;

  /// Link to screen 09 on the sign-in segment (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get emailForgot;

  /// Invalid email (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng, bạn kiểm tra lại nhé.'**
  String get authErrorInvalidEmail;

  /// Password too short (R-002).
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần ít nhất 8 ký tự.'**
  String get authErrorWeakPassword;

  /// Wrong credentials (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu chưa đúng.'**
  String get authErrorWrongCredentials;

  /// Rate limited (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Bạn thử hơi nhiều lần. Đợi một lát rồi thử lại nhé.'**
  String get authErrorTooManyRequests;

  /// Offline (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Kiểm tra kết nối rồi thử lại.'**
  String get authErrorNetwork;

  /// Provider not configured on dev (Google until enabled, Apple until a team exists).
  ///
  /// In vi, this message translates to:
  /// **'Cách đăng nhập này chưa sẵn sàng trên bản thử nghiệm.'**
  String get authErrorNotConfigured;

  /// Disabled account.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đang bị khoá. Liên hệ Child Life để được giúp.'**
  String get authErrorDisabled;

  /// Fallback error.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Thử lại nhé.'**
  String get authErrorGeneric;

  /// Linking after a collision failed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng nhập nhưng chưa liên kết được email. Thử lại trong phần Tài khoản.'**
  String get authErrorLinkFailed;

  /// Verify screen title (27:588).
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra email'**
  String get verifyTitle;

  /// Verify body before the address chip.
  ///
  /// In vi, this message translates to:
  /// **'Mình đã gửi link xác minh tới'**
  String get verifyBody;

  /// Opens the mail app.
  ///
  /// In vi, this message translates to:
  /// **'Mở Mail'**
  String get verifyOpenMail;

  /// Resends the link.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại email'**
  String get verifyResend;

  /// Resend cooldown (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại sau {seconds} giây'**
  String verifyResendIn(int seconds);

  /// Toast after resend.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lại. Nhớ xem cả mục Thư rác nhé.'**
  String get verifyResent;

  /// Toast when the link was opened.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được xác minh'**
  String get verifyDone;

  /// No mail app.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng Mail trên máy này.'**
  String get verifyNoMailApp;

  /// P-008 note under the buttons.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể tiếp tục. Cần xác minh trước khi mời người thân.'**
  String get verifyLaterHint;

  /// Screen 09 title (27:634).
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgotTitle;

  /// Screen 09 body.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email, mình gửi link đặt lại.'**
  String get forgotBody;

  /// Screen 09 primary.
  ///
  /// In vi, this message translates to:
  /// **'Gửi link'**
  String get forgotSend;

  /// Enumeration-safe success (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Nếu email này có tài khoản, link đặt lại đã được gửi tới hộp thư.'**
  String get forgotSent;

  /// Screen 10 title (27:673).
  ///
  /// In vi, this message translates to:
  /// **'Email đã có tài khoản'**
  String get existsTitle;

  /// Screen 10 body; provider is not revealed (email privacy).
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Apple hoặc Google, rồi liên kết.'**
  String get existsBody;

  /// Provider chip on the account row.
  ///
  /// In vi, this message translates to:
  /// **'Apple · Google'**
  String get existsProvider;

  /// Back to 07.
  ///
  /// In vi, this message translates to:
  /// **'Dùng email khác'**
  String get existsUseOtherEmail;

  /// Toast after linking.
  ///
  /// In vi, this message translates to:
  /// **'Đã liên kết email với tài khoản của bạn.'**
  String get existsLinked;

  /// Screen 10a title (115:11756).
  ///
  /// In vi, this message translates to:
  /// **'Bạn là ai với bé?'**
  String get whoTitle;

  /// Screen 10a subtitle; label = chosen relation.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà sẽ thấy “{label} ghi” trên từng bản ghi.'**
  String whoSubtitle(String label);

  /// Display name field.
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get whoNameLabel;

  /// Display name placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Mai'**
  String get whoNamePlaceholder;

  /// Relation chips label.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là'**
  String get whoYouAre;

  /// Free-text relation for “Khác…”.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là ai với bé'**
  String get whoCustomLabel;

  /// Custom relation placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Dì'**
  String get whoCustomPlaceholder;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Mẹ'**
  String get relationMother;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Ba'**
  String get relationFather;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Bà'**
  String get relationGrandmother;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Ông'**
  String get relationGrandfather;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mẫu'**
  String get relationNanny;

  /// Relation chip.
  ///
  /// In vi, this message translates to:
  /// **'Họ hàng'**
  String get relationRelative;

  /// Relation chip that opens free text.
  ///
  /// In vi, this message translates to:
  /// **'Khác…'**
  String get relationOther;

  /// Baby nickname label (29:721).
  ///
  /// In vi, this message translates to:
  /// **'Tên thân mật'**
  String get babyNicknameLabel;

  /// Shown while the nickname is empty.
  ///
  /// In vi, this message translates to:
  /// **'Tên bé'**
  String get babyNicknamePlaceholder;

  /// Detail row / sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get babyDob;

  /// Detail row / sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Múi giờ'**
  String get babyTimeZone;

  /// Gender label.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get babyGender;

  /// Suffix after the gender label.
  ///
  /// In vi, this message translates to:
  /// **'không bắt buộc'**
  String get babyOptional;

  /// Gender option.
  ///
  /// In vi, this message translates to:
  /// **'Bé gái'**
  String get genderGirl;

  /// Gender option.
  ///
  /// In vi, this message translates to:
  /// **'Bé trai'**
  String get genderBoy;

  /// Gender option.
  ///
  /// In vi, this message translates to:
  /// **'Không nêu'**
  String get genderUnspecified;

  /// Privacy note on 11 (R-009).
  ///
  /// In vi, this message translates to:
  /// **'Người thân chỉ thấy tên thân mật'**
  String get babyPrivacyNote;

  /// Camera badge on the avatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get a11yChangeBabyPhoto;

  /// Validation when Tiếp is tapped without a nickname.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên thân mật cho bé nhé.'**
  String get babyNicknameRequired;

  /// Live age under the date wheel (38:1498).
  ///
  /// In vi, this message translates to:
  /// **'{name} được {age}'**
  String dobAgeHint(String name, String age);

  /// Age on the day of birth.
  ///
  /// In vi, this message translates to:
  /// **'mới chào đời'**
  String get ageNewborn;

  /// Age in days (< 2 weeks).
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày tuổi'**
  String ageDays(int count);

  /// Age in weeks (< 13 weeks).
  ///
  /// In vi, this message translates to:
  /// **'{count} tuần tuổi'**
  String ageWeeks(int count);

  /// Age in months (< 2 years).
  ///
  /// In vi, this message translates to:
  /// **'{count} tháng tuổi'**
  String ageMonths(int count);

  /// Age in years.
  ///
  /// In vi, this message translates to:
  /// **'{count} tuổi'**
  String ageYears(int count);

  /// Short age for the baby switcher.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String ageShortDays(int count);

  /// Short age for the baby switcher.
  ///
  /// In vi, this message translates to:
  /// **'{count} tuần'**
  String ageShortWeeks(int count);

  /// Short age for the baby switcher.
  ///
  /// In vi, this message translates to:
  /// **'{count} tháng'**
  String ageShortMonths(int count);

  /// Short age for the baby switcher.
  ///
  /// In vi, this message translates to:
  /// **'{count} tuổi'**
  String ageShortYears(int count);

  /// Time-zone search placeholder (38:1581).
  ///
  /// In vi, this message translates to:
  /// **'Tìm thành phố hoặc quốc gia'**
  String get tzSearch;

  /// Auto time zone row.
  ///
  /// In vi, this message translates to:
  /// **'Tự động theo máy'**
  String get tzAuto;

  /// Auto time zone subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng {offset} · {place}'**
  String tzAutoUsing(String offset, String place);

  /// Empty search (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy múi giờ phù hợp.'**
  String get tzNoResults;

  /// Avatar sheet title (41:1861).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện'**
  String get avatarTitle;

  /// Camera row.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get avatarCamera;

  /// Library row.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get avatarLibrary;

  /// Preset caption.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc chọn hình minh họa'**
  String get avatarOrIllustration;

  /// Avatar privacy note.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người trong gia đình xem được ảnh này.'**
  String get avatarPrivacy;

  /// Accessibility label of a preset avatar.
  ///
  /// In vi, this message translates to:
  /// **'Hình minh họa {number}'**
  String avatarPreset(int number);

  /// Camera permission denied (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa được dùng camera. Bạn có thể cho phép trong Cài đặt.'**
  String get avatarCameraDenied;

  /// Photo permission denied (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa được xem ảnh. Bạn có thể cho phép trong Cài đặt.'**
  String get avatarLibraryDenied;

  /// Photo upload failed after the baby was created.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được ảnh đại diện. Hồ sơ vẫn dùng hình minh họa, bạn thử lại sau nhé.'**
  String get avatarUploadFailed;

  /// Screen 12 title (29:795).
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi gì?'**
  String get trackersTitle;

  /// Screen 12 subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi lại lúc nào cũng được.'**
  String get trackersSubtitle;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình'**
  String get trackerBottle;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ'**
  String get trackerBreast;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get trackerSleep;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get trackerDiaper;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa'**
  String get trackerPump;

  /// Tracker / tile.
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng'**
  String get trackerGrowth;

  /// Screen 12 primary with the selected count.
  ///
  /// In vi, this message translates to:
  /// **'Xong · {count} mục'**
  String trackersDone(int count);

  /// Disabled primary when nothing is selected.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một mục'**
  String get trackersPickOne;

  /// R-043.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tài khoản tạo được tối đa 3 hồ sơ bé.'**
  String get createBabyLimit;

  /// createBaby failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo được hồ sơ bé. Kiểm tra mạng rồi thử lại nhé.'**
  String get createBabyFailed;

  /// Server rejected DOB.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh không thể ở tương lai.'**
  String get createBabyDobFuture;

  /// Screen 13 title (29:1063).
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get appearanceTitle;

  /// Theme option.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// Theme option.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// Theme option.
  ///
  /// In vi, this message translates to:
  /// **'Tự động'**
  String get themeAuto;

  /// Product term kept in English in Figma.
  ///
  /// In vi, this message translates to:
  /// **'Night care'**
  String get nightCareTitle;

  /// Night care row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo lịch {start} – {end}'**
  String nightCareScheduled(String start, String end);

  /// Night care row subtitle when the schedule is off.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt lịch'**
  String get nightCareOff;

  /// Section header and sheet title (43:2067).
  ///
  /// In vi, this message translates to:
  /// **'Lịch Night care'**
  String get nightCareSchedule;

  /// Schedule start row.
  ///
  /// In vi, this message translates to:
  /// **'Bật lúc'**
  String get nightCareOn;

  /// Schedule end row.
  ///
  /// In vi, this message translates to:
  /// **'Tắt lúc'**
  String get nightCareOffAt;

  /// Hint under the schedule.
  ///
  /// In vi, this message translates to:
  /// **'Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ.'**
  String get nightCareHint;

  /// Footer of 13.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng ngay cho cả app'**
  String get appearanceAppliesNow;

  /// Sheet segment.
  ///
  /// In vi, this message translates to:
  /// **'Bật lúc · {time}'**
  String nightCareSegmentOn(String time);

  /// Sheet segment.
  ///
  /// In vi, this message translates to:
  /// **'Tắt lúc · {time}'**
  String nightCareSegmentOff(String time);

  /// Wheel column label.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get pickerHour;

  /// Wheel column label.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get pickerMinute;

  /// Duration hint (43:2067).
  ///
  /// In vi, this message translates to:
  /// **'Night care trong {duration}, đến {end} sáng'**
  String nightCareDuration(String duration, String end);

  /// Duration in hours.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ'**
  String durationHours(int count);

  /// Duration in hours and minutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String durationHoursMinutes(int hours, int minutes);

  /// Today title (29:904).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayTitle;

  /// Empty tile value.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get todayTileEmpty;

  /// Empty tile hint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để ghi'**
  String get todayTileTapToLog;

  /// Empty day summary card.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ghi chép hôm nay.'**
  String get todaySummaryEmpty;

  /// Empty day summary body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi khi gia đình cần nhé. Tổng trong ngày sẽ hiện ở đây.'**
  String get todaySummaryEmptyBody;

  /// Shown when tapping a tile before S4 ships.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép chăm sóc sẽ có ở bản tiếp theo.'**
  String get todayLoggingSoon;

  /// Baby switcher chip text.
  ///
  /// In vi, this message translates to:
  /// **'{name} · {age}'**
  String babySwitcherLabel(String name, String age);

  /// Temporary Me menu entry until the Me tab (S10).
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get meAppearance;

  /// Temporary Me menu entry until the Me tab (S10).
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get meSignOut;

  /// Short age on the day of birth (baby switcher).
  ///
  /// In vi, this message translates to:
  /// **'mới sinh'**
  String get ageShortNewborn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
