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

  /// Primary continue button (15).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get actionContinue;

  /// Cancels a confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get actionCancel;

  /// Generic failure of a family action (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Chưa làm được. Thử lại nhé.'**
  String get familyErrorGeneric;

  /// Relation chip on 14b (116:11916).
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get relationFriend;

  /// Role name (14b).
  ///
  /// In vi, this message translates to:
  /// **'Cùng nuôi'**
  String get roleCoParent;

  /// Role name (14b).
  ///
  /// In vi, this message translates to:
  /// **'Người chăm sóc'**
  String get roleCaregiver;

  /// Role name (14b).
  ///
  /// In vi, this message translates to:
  /// **'Người thân'**
  String get roleRelative;

  /// Member row detail on 14a ("Mẹ · Cùng nuôi").
  ///
  /// In vi, this message translates to:
  /// **'{relation} · {role}'**
  String memberDetail(String relation, String role);

  /// Baby switcher sheet title (125:13223).
  ///
  /// In vi, this message translates to:
  /// **'Chọn bé'**
  String get babyPickerTitle;

  /// Your relation (parents) or role (others) on a baby row.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là {label}'**
  String babyPickerYouAre(String label);

  /// Baby row detail: age · "Bạn là Mẹ".
  ///
  /// In vi, this message translates to:
  /// **'{age} · {youAre}'**
  String babyPickerRowDetail(String age, String youAre);

  /// Add row in the baby switcher.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hồ sơ bé'**
  String get babyPickerAdd;

  /// Profiles you created out of the limit (R-043).
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max}'**
  String babyPickerCount(int count, int max);

  /// Footnote under the baby list.
  ///
  /// In vi, this message translates to:
  /// **'Bạn tạo được tối đa {max} hồ sơ bé.'**
  String babyPickerLimit(int max);

  /// Toast after switching baby (125:13338).
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang {name}'**
  String babySwitched(String name);

  /// Memories tab placeholder until S5.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm sẽ có ở bản tiếp theo.'**
  String get memoriesComingSoon;

  /// Relative with "Chăm sóc hằng ngày" taps a tile (D-018).
  ///
  /// In vi, this message translates to:
  /// **'Bạn được xem chăm sóc hằng ngày, không ghi.'**
  String get todayViewOnly;

  /// Banner for a temporary identity (123:12623).
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu tài khoản'**
  String get unsavedBannerTitle;

  /// Banner action → 16d.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get unsavedBannerAction;

  /// 16d sheet title (123:12712).
  ///
  /// In vi, this message translates to:
  /// **'Lưu tài khoản'**
  String get saveAccountTitle;

  /// 16d body.
  ///
  /// In vi, this message translates to:
  /// **'Để không mất {baby} khi đổi máy hoặc cài lại app.'**
  String saveAccountBody(String baby);

  /// Toast after linking a temporary identity.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu tài khoản'**
  String get saveAccountDone;

  /// Toast after saving into an existing account (P-007).
  ///
  /// In vi, this message translates to:
  /// **'Đã gộp vào tài khoản của bạn'**
  String get saveAccountMerged;

  /// 16d "Dùng email" screen subtitle (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới, hoặc đăng nhập tài khoản đã có để gộp vào đó.'**
  String get saveEmailSubtitle;

  /// Email belongs to an existing account (Q-023).
  ///
  /// In vi, this message translates to:
  /// **'Email này đã có tài khoản. Đăng nhập để gộp vào đó.'**
  String get saveEmailExists;

  /// Confirm sign-out of a temporary identity.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khi chưa lưu?'**
  String get signOutAnonTitle;

  /// Confirm sign-out body.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản tạm sẽ mất, và bạn cần lời mời mới để vào lại.'**
  String get signOutAnonBody;

  /// Confirm sign-out button.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn đăng xuất'**
  String get signOutAnonConfirm;

  /// Family tab subtitle (116:11226).
  ///
  /// In vi, this message translates to:
  /// **'Những người cùng chăm {baby}'**
  String familySubtitle(String baby);

  /// Badge on your own row.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get familyYou;

  /// Pending invites header.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ nhận lời ({count})'**
  String familyPending(int count);

  /// Pending row detail ("Bà ngoại · hết hạn 15 thg 10").
  ///
  /// In vi, this message translates to:
  /// **'{relation} · hết hạn {date}'**
  String familyPendingDetail(String relation, String date);

  /// Pending row of an expired invite.
  ///
  /// In vi, this message translates to:
  /// **'{relation} · đã hết hạn'**
  String familyPendingExpired(String relation);

  /// Pending row title when no email was sent.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời cho {relation}'**
  String familyPendingNoEmail(String relation);

  /// Pending row chip.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get familyResend;

  /// Toast after resending an invite email.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lại cho {email}'**
  String familyResent(String email);

  /// Family primary and 14b title.
  ///
  /// In vi, this message translates to:
  /// **'Mời người cùng chăm'**
  String get familyInvite;

  /// Footnote under the invite button (118:12056).
  ///
  /// In vi, this message translates to:
  /// **'Người được mời chỉ thấy những gì bạn cho phép. Bạn có thể đổi quyền hoặc xoá bất cứ lúc nào.'**
  String get familyFootnote;

  /// Members list failed to load.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được danh sách. Kiểm tra mạng nhé.'**
  String get familyLoadFailed;

  /// 14b subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn người đó là ai và được làm gì.'**
  String get inviteSubtitle;

  /// 14b relation label.
  ///
  /// In vi, this message translates to:
  /// **'Người được mời là'**
  String get inviteRelationLabel;

  /// 14b / 14f role label.
  ///
  /// In vi, this message translates to:
  /// **'Quyền'**
  String get inviteRoleLabel;

  /// Custom relation field for "Khác…".
  ///
  /// In vi, this message translates to:
  /// **'Là ai với bé'**
  String get inviteCustomLabel;

  /// 14b role subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Toàn quyền, như ba mẹ'**
  String get roleCoParentHint;

  /// 14b role subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi & xem chăm sóc'**
  String get roleCaregiverHint;

  /// 14b role subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem kỷ niệm, chọn thêm quyền xem'**
  String get roleRelativeHint;

  /// Disabled co-parent option (D-017).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người tạo hồ sơ mời được Cùng nuôi'**
  String get roleCoParentOwnerOnly;

  /// 14b link → 14b2.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết quyền'**
  String get inviteSeeDetails;

  /// 14b primary.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp · Gửi lời mời'**
  String get inviteNext;

  /// 14b2 sheet title (121:11672).
  ///
  /// In vi, this message translates to:
  /// **'Quyền của Người thân'**
  String get relativeRightsTitle;

  /// 14b2 fixed banner.
  ///
  /// In vi, this message translates to:
  /// **'Luôn có: xem kỷ niệm, thả tim'**
  String get relativeRightsAlways;

  /// 14b2 toggles label.
  ///
  /// In vi, this message translates to:
  /// **'Cho xem thêm'**
  String get relativeRightsMore;

  /// Extra right: DOB and weight.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin bé'**
  String get rightBabyInfo;

  /// Extra right subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh, cân nặng'**
  String get rightBabyInfoHint;

  /// Extra right: read-only Today (D-018).
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc hằng ngày'**
  String get rightDailyCare;

  /// Extra right subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bú, ngủ, tã · chỉ xem'**
  String get rightDailyCareHint;

  /// Access details sheet for co-parent / caregiver (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Quyền của {role}'**
  String roleDetailsTitle(String role);

  /// Permission tile (30:1259).
  ///
  /// In vi, this message translates to:
  /// **'Ghi bú, ngủ, tã'**
  String get permLogCare;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch'**
  String get permViewSchedule;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhắc việc'**
  String get permViewReminders;

  /// Permission tile (locked for caregivers).
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get permMemories;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Xem kỷ niệm'**
  String get permViewMemories;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Thả tim'**
  String get permLove;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Mời người khác'**
  String get permInvite;

  /// Permission tile.
  ///
  /// In vi, this message translates to:
  /// **'Thêm kỷ niệm'**
  String get permAddMemories;

  /// Permission tile for relatives.
  ///
  /// In vi, this message translates to:
  /// **'Xem bú, ngủ, tã'**
  String get permDailyCare;

  /// 14c title (117:11435).
  ///
  /// In vi, this message translates to:
  /// **'Gửi lời mời cho {relation}'**
  String inviteSendTitle(String relation);

  /// 14c QR subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{relation} mở camera điện thoại và quét mã.'**
  String inviteSendSubtitle(String relation);

  /// 14c Link tab subtitle (G-054).
  ///
  /// In vi, this message translates to:
  /// **'Gửi link này cho {relation} qua tin nhắn.'**
  String inviteSendLinkSubtitle(String relation);

  /// 14c Email tab subtitle (G-054).
  ///
  /// In vi, this message translates to:
  /// **'Child Life gửi lời mời tới email của {relation}.'**
  String inviteSendEmailSubtitle(String relation);

  /// Summary banner link → 14b.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get inviteSummaryChange;

  /// 14c segment.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR'**
  String get inviteChannelQr;

  /// 14c segment.
  ///
  /// In vi, this message translates to:
  /// **'Link'**
  String get inviteChannelLink;

  /// 14c segment.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get inviteChannelEmail;

  /// Under the QR.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc nhập mã'**
  String get inviteOrCode;

  /// Invite expiry under the code.
  ///
  /// In vi, this message translates to:
  /// **'{days, plural, other{Hết hạn sau {days} ngày}}'**
  String inviteExpiresInDays(int days);

  /// Invite expiry under the code (< 1 day).
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn hôm nay'**
  String get inviteExpiresToday;

  /// 14c primary → share sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ lời mời'**
  String get inviteShare;

  /// Text shared with the invite link.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} mời bạn cùng chăm {baby} trên Child Life.\nMở link: {link}\nHoặc nhập mã trong app: {code}'**
  String inviteShareText(String inviter, String baby, String link, String code);

  /// Share sheet subject.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời cùng chăm {baby}'**
  String inviteShareSubject(String baby);

  /// 14c link → 14c2.
  ///
  /// In vi, this message translates to:
  /// **'{relation} không quét được?'**
  String inviteCantScan(String relation);

  /// 14c Link tab action.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link'**
  String get inviteCopyLink;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép link'**
  String get inviteLinkCopied;

  /// 14c Email tab field.
  ///
  /// In vi, this message translates to:
  /// **'Email của {relation}'**
  String inviteEmailLabel(String relation);

  /// 14c Email tab primary.
  ///
  /// In vi, this message translates to:
  /// **'Gửi email'**
  String get inviteEmailSend;

  /// 14c2 sheet title (121:12549).
  ///
  /// In vi, this message translates to:
  /// **'{relation} không vào được?'**
  String cantScanTitle(String relation);

  /// 14c2 step 1 (button label matches Welcome).
  ///
  /// In vi, this message translates to:
  /// **'Mở app Child Life, chọn “Mã mời”'**
  String get cantScanStep1;

  /// 14c2 step 2.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã {code}'**
  String cantScanStep2(String code);

  /// 14c2 step 3.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn lỗi? Tạo mã mới bên dưới'**
  String get cantScanStep3;

  /// 14c2 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã mới'**
  String get cantScanNewCode;

  /// 14c2 plain.
  ///
  /// In vi, this message translates to:
  /// **'Gửi qua email thay thế'**
  String get cantScanByEmail;

  /// Toast after regenerating (P-020).
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo mã mới. Mã cũ không dùng được nữa.'**
  String get inviteNewCodeDone;

  /// Cancels a pending invite (G-033).
  ///
  /// In vi, this message translates to:
  /// **'Huỷ lời mời'**
  String get inviteRevoke;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ lời mời'**
  String get inviteRevoked;

  /// 14d title (117:12007).
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email cho {relation}'**
  String inviteSentTitle(String relation);

  /// 14d plain link (G-055).
  ///
  /// In vi, this message translates to:
  /// **'{relation} không nhận được?'**
  String inviteNotReceived(String relation);

  /// G-055 sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được email?'**
  String get notReceivedTitle;

  /// G-055 tip.
  ///
  /// In vi, this message translates to:
  /// **'Xem trong mục Thư rác hoặc Quảng cáo.'**
  String get notReceivedTip1;

  /// G-055 tip.
  ///
  /// In vi, this message translates to:
  /// **'Email có thể đến sau vài phút.'**
  String get notReceivedTip2;

  /// G-055 tip.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc chia sẻ link qua tin nhắn.'**
  String get notReceivedTip3;

  /// G-055 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại email'**
  String get notReceivedResend;

  /// Invites need a verified email (D-015).
  ///
  /// In vi, this message translates to:
  /// **'Xác minh email của bạn trước khi mời người khác.'**
  String get inviteErrorUnverified;

  /// D-017.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người tạo hồ sơ mới quản lý được Cùng nuôi.'**
  String get inviteErrorOwnerOnly;

  /// Email resend too soon.
  ///
  /// In vi, this message translates to:
  /// **'Vừa gửi xong. Đợi một phút rồi gửi lại nhé.'**
  String get inviteErrorTooSoon;

  /// Email cap per invite.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời này đã gửi đủ 5 email. Hãy chia sẻ link thay thế.'**
  String get inviteErrorTooMany;

  /// Unsubscribed recipient.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ này đã huỷ nhận email từ Child Life.'**
  String get inviteErrorSuppressed;

  /// Invite accepted, cancelled or expired meanwhile.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời này không còn dùng được.'**
  String get inviteErrorClosed;

  /// 14f meta (record count arrives with care logs, S4).
  ///
  /// In vi, this message translates to:
  /// **'{relation} · tham gia {date}'**
  String memberMeta(String relation, String date);

  /// 14f role subtitle (118:12056).
  ///
  /// In vi, this message translates to:
  /// **'Toàn quyền như ba mẹ'**
  String get roleCoParentHintFull;

  /// 14f role subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi & xem chăm sóc, không mời người'**
  String get roleCaregiverHintFull;

  /// 14f role subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xem kỷ niệm được chia sẻ'**
  String get roleRelativeHintFull;

  /// 14f detail row (R-024).
  ///
  /// In vi, this message translates to:
  /// **'Thời hạn'**
  String get memberAccessUntil;

  /// 14f value.
  ///
  /// In vi, this message translates to:
  /// **'Đến {date}'**
  String memberAccessUntilValue(String date);

  /// 14f value without an end date.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get memberAccessNoLimit;

  /// Access date sheet hint.
  ///
  /// In vi, this message translates to:
  /// **'{name} xem được đến hết ngày này.'**
  String memberAccessHint(String name);

  /// Access date sheet plain.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ giới hạn'**
  String get memberAccessClear;

  /// 14f detail row.
  ///
  /// In vi, this message translates to:
  /// **'Là ai với bé'**
  String get memberRelation;

  /// 14f destructive.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {name} khỏi gia đình'**
  String memberRemove(String name);

  /// 14f caption (R-023).
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi của {name} vẫn được giữ.'**
  String memberRecordsKept(String name);

  /// Removal confirmation (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Xoá {name}?'**
  String memberRemoveConfirmTitle(String name);

  /// Removal confirmation body.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ không xem được {baby} nữa. Bản ghi của {name} vẫn được giữ.'**
  String memberRemoveConfirmBody(String name, String baby);

  /// Removal confirmation button.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get memberRemoveConfirm;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {name}'**
  String memberRemoved(String name);

  /// Toast after a 14f change.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật'**
  String get memberUpdated;

  /// 15 title (30:1222).
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời'**
  String get joinCodeTitle;

  /// 15 subtitle.
  ///
  /// In vi, this message translates to:
  /// **'6 số trong lời mời, hoặc quét mã QR.'**
  String get joinCodeSubtitle;

  /// 15 plain with camera icon.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get joinScan;

  /// Unknown code (G-035).
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng. Kiểm tra lại 6 số nhé.'**
  String get joinCodeWrong;

  /// Lockout (P-021).
  ///
  /// In vi, this message translates to:
  /// **'Nhập sai nhiều lần. Thử lại sau {minutes} phút.'**
  String joinLocked(int minutes);

  /// Code field label.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời 6 số'**
  String get a11yInviteCode;

  /// Scanner hint.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã QR trong lời mời vào khung.'**
  String get scanHint;

  /// Scanned a foreign QR.
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã mời Child Life.'**
  String get scanNotInvite;

  /// Camera permission denied.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép camera trong Cài đặt để quét mã.'**
  String get scanCameraDenied;

  /// 16 countdown chip.
  ///
  /// In vi, this message translates to:
  /// **'{hours, plural, other{Còn {hours} giờ}}'**
  String joinCountdownHours(int hours);

  /// 16 title ("Mẹ Mai mời bạn").
  ///
  /// In vi, this message translates to:
  /// **'{inviter} mời bạn'**
  String joinInviterTitle(String inviter);

  /// 16 line before the role chip.
  ///
  /// In vi, this message translates to:
  /// **'cùng chăm bé {baby} với vai trò'**
  String joinRoleLine(String baby);

  /// 16 primary → 16b.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get joinJoin;

  /// 16 plain (Q-024: just exits).
  ///
  /// In vi, this message translates to:
  /// **'Không phải tôi'**
  String get joinNotMe;

  /// G-036.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở trong gia đình {baby}.'**
  String joinAlreadyMember(String baby);

  /// 16b sheet title (123:12571).
  ///
  /// In vi, this message translates to:
  /// **'Vào gia đình {baby}'**
  String joinHowTitle(String baby);

  /// 16b body.
  ///
  /// In vi, this message translates to:
  /// **'Không cần tạo tài khoản. Có thể lưu lại sau.'**
  String get joinHowBody;

  /// 16b primary (temporary identity).
  ///
  /// In vi, this message translates to:
  /// **'Vào ngay'**
  String get joinNow;

  /// 16b divider.
  ///
  /// In vi, this message translates to:
  /// **'hoặc lưu tài khoản ngay'**
  String get joinOrSave;

  /// 16a title (118:12227).
  ///
  /// In vi, this message translates to:
  /// **'Bạn là ai với {baby}?'**
  String joinConfirmTitle(String baby);

  /// 16a subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} đã chọn “{relation}”. Đổi nếu chưa đúng.'**
  String joinConfirmSubtitle(String inviter, String relation);

  /// 16a primary.
  ///
  /// In vi, this message translates to:
  /// **'Vào xem {baby}'**
  String joinConfirmGo(String baby);

  /// 17 title (30:1346).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã hết hạn'**
  String get joinExpiredTitle;

  /// 17 body.
  ///
  /// In vi, this message translates to:
  /// **'Nhờ người mời gửi link mới nhé.'**
  String get joinExpiredBody;

  /// Revoked invite (G-035).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã bị huỷ'**
  String get joinRevokedTitle;

  /// Revoked invite body.
  ///
  /// In vi, this message translates to:
  /// **'Nhờ người mời gửi lời mời mới nhé.'**
  String get joinRevokedBody;

  /// Used invite (G-035).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã được dùng'**
  String get joinUsedTitle;

  /// Used invite body.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi lời mời chỉ dùng được một lần. Nhờ người mời gửi lời mời mới nhé.'**
  String get joinUsedBody;

  /// Unknown link (G-035).
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lời mời'**
  String get joinNotFoundTitle;

  /// Unknown link body.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại link, hoặc nhập mã 6 số.'**
  String get joinNotFoundBody;

  /// 17 primary.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã khác'**
  String get joinOtherCode;

  /// 17 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Về trang đầu'**
  String get joinBackToStart;

  /// 9d title (127:15135).
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn quyền xem hồ sơ này'**
  String get lostAccessTitle;

  /// 9d body.
  ///
  /// In vi, this message translates to:
  /// **'Quyền của bạn đã thay đổi. Nội dung trên máy này đã được ẩn.'**
  String get lostAccessBody;

  /// 9d primary.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chính'**
  String get lostAccessHome;

  /// 9d secondary → share sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xin lời mời mới'**
  String get lostAccessRequest;

  /// Message shared from 9d.
  ///
  /// In vi, this message translates to:
  /// **'Mình không còn xem được hồ sơ của bé trên Child Life. Bạn gửi mình lời mời mới nhé?'**
  String get lostAccessShareText;
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
