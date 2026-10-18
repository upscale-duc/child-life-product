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

  /// Screen reader: a save or delete is running (full-screen spinner).
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get a11yWorking;

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
  /// **'Cùng con lớn lên,\nđồng hành từng bước.'**
  String get welcomeTitle;

  /// Welcome primary: feature tour.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu chặng đầu cùng con'**
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
  /// **'Đăng nhập để bắt đầu hành trình cùng con.'**
  String get signInSubtitle;

  /// Apple button label.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Apple'**
  String get signInApple;

  /// Android sign-in (no Apple button, D-071): lead-in for people with an Apple account (Q-063)
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký bằng Apple trên iPhone?'**
  String get signInAppleElsewhere;

  /// Android sign-in: opens email sign-in, where 'Gửi link đăng nhập' sends a link to the Apple email (Q-063)
  ///
  /// In vi, this message translates to:
  /// **'Nhận link đăng nhập qua email Apple'**
  String get signInAppleElsewhereAction;

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

  /// 11 Thông tin bé: detail row for the country the family lives in (D-078).
  ///
  /// In vi, this message translates to:
  /// **'Quốc gia'**
  String get babyCountry;

  /// Value of the country row before one is picked.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get babyCountryUnset;

  /// Toast when Tiếp is tapped without a country.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nơi gia đình đang sống để Sơ cứu gọi đúng số cấp cứu.'**
  String get babyCountryRequired;

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

  /// Duration in whole hours.
  ///
  /// In vi, this message translates to:
  /// **'{n} giờ'**
  String durationHours(int n);

  /// Duration ("1 giờ 20 phút").
  ///
  /// In vi, this message translates to:
  /// **'{h} giờ {m} phút'**
  String durationHoursMinutes(int h, int m);

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

  /// Less than a minute ago.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get agoJustNow;

  /// Relative time (46:2266 "45 phút trước").
  ///
  /// In vi, this message translates to:
  /// **'{n} phút trước'**
  String agoMinutes(int n);

  /// Relative time ("2 giờ trước").
  ///
  /// In vi, this message translates to:
  /// **'{n} giờ trước'**
  String agoHours(int n);

  /// Relative time, full form (D-023).
  ///
  /// In vi, this message translates to:
  /// **'{h} giờ {m} phút trước'**
  String agoHoursMinutes(int h, int m);

  /// Relative time in days.
  ///
  /// In vi, this message translates to:
  /// **'{n, plural, other{{n} ngày trước}}'**
  String agoDays(int n);

  /// Breastfeed tile ("Kết thúc 3 giờ 35 phút trước").
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc {ago}'**
  String endedAgo(String ago);

  /// Duration ("15 phút").
  ///
  /// In vi, this message translates to:
  /// **'{n} phút'**
  String durationMinutes(int n);

  /// DayRhythm sleep total ("7 giờ 50").
  ///
  /// In vi, this message translates to:
  /// **'{h} giờ {m}'**
  String rhythmSleepValue(int h, int m);

  /// The current user in attribution ("Bạn ghi" / "by you").
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get careYou;

  /// Logged-by row on 21 ("Mẹ Mai (bạn)").
  ///
  /// In vi, this message translates to:
  /// **'{name} (bạn)'**
  String careYouSuffix(String name);

  /// Who logged it ("Mẹ ghi").
  ///
  /// In vi, this message translates to:
  /// **'{who} ghi'**
  String careLoggedBy(String who);

  /// Millilitres.
  ///
  /// In vi, this message translates to:
  /// **'{n} ml'**
  String amountMl(int n);

  /// Weight with the locale decimal ("4,3 kg").
  ///
  /// In vi, this message translates to:
  /// **'{v} kg'**
  String weightKg(String v);

  /// Length ("54,5 cm").
  ///
  /// In vi, this message translates to:
  /// **'{v} cm'**
  String lengthCm(String v);

  /// Milk type chip.
  ///
  /// In vi, this message translates to:
  /// **'Sữa mẹ'**
  String get milkBreast;

  /// Milk type chip.
  ///
  /// In vi, this message translates to:
  /// **'Sữa công thức'**
  String get milkFormula;

  /// Side segment.
  ///
  /// In vi, this message translates to:
  /// **'Trái'**
  String get sideLeft;

  /// Side segment.
  ///
  /// In vi, this message translates to:
  /// **'Phải'**
  String get sideRight;

  /// Side segment / diaper both.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai'**
  String get sideBoth;

  /// Diaper choice tile.
  ///
  /// In vi, this message translates to:
  /// **'Ướt'**
  String get diaperWet;

  /// Diaper choice tile.
  ///
  /// In vi, this message translates to:
  /// **'Bẩn'**
  String get diaperDirty;

  /// Diaper tile value ("Tã ướt").
  ///
  /// In vi, this message translates to:
  /// **'Tã ướt'**
  String get diaperWetValue;

  /// Diaper tile value.
  ///
  /// In vi, this message translates to:
  /// **'Tã bẩn'**
  String get diaperDirtyValue;

  /// Diaper tile value (both).
  ///
  /// In vi, this message translates to:
  /// **'Ướt và bẩn'**
  String get diaperBothValue;

  /// Tile line / chip while pending (9a).
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ'**
  String get carePending;

  /// DayRhythm card title (48:409).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi hôm nay'**
  String get dayRhythmTitle;

  /// Bottle total.
  ///
  /// In vi, this message translates to:
  /// **'{count} cữ · {ml} ml'**
  String rhythmFeeds(int count, int ml);

  /// Breast total.
  ///
  /// In vi, this message translates to:
  /// **'{count} cữ · {minutes} phút'**
  String rhythmBreast(int count, int minutes);

  /// Sleep total label.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ (đã xong)'**
  String get rhythmSleepLabel;

  /// Diaper total.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần'**
  String rhythmDiapers(int count);

  /// 24 h strip legend.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get legendSleep;

  /// 24 h strip legend.
  ///
  /// In vi, this message translates to:
  /// **'Tã'**
  String get legendDiaper;

  /// Section link → History (S6).
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get todayHistory;

  /// Until History ships (S6).
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chi tiết sẽ có ở bản tiếp theo.'**
  String get historySoon;

  /// Until sleep ships (S5).
  ///
  /// In vi, this message translates to:
  /// **'Ghi giấc ngủ và hẹn giờ sẽ có ở bản tiếp theo.'**
  String get sleepSoon;

  /// Sleep tile value (S5).
  ///
  /// In vi, this message translates to:
  /// **'Đã thức {duration}'**
  String awakeFor(String duration);

  /// Growth tile line ("+0,4 kg · hôm nay").
  ///
  /// In vi, this message translates to:
  /// **'{delta} · {when}'**
  String growthDeltaToday(String delta, String when);

  /// Relative day word.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get dayToday;

  /// Relative day word.
  ///
  /// In vi, this message translates to:
  /// **'hôm qua'**
  String get dayYesterday;

  /// 9a banner (127:14758).
  ///
  /// In vi, this message translates to:
  /// **'Đang offline · {count} bản ghi chờ đồng bộ'**
  String offlineBanner(int count);

  /// Pending records while online.
  ///
  /// In vi, this message translates to:
  /// **'{count} bản ghi chờ đồng bộ'**
  String syncingBanner(int count);

  /// 9b sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ'**
  String get pendingTitle;

  /// Pending chip (9b).
  ///
  /// In vi, this message translates to:
  /// **'Chờ'**
  String get pendingChip;

  /// 9b row sub-line.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lưu trên máy này'**
  String get pendingOnlyHere;

  /// 9b footnote.
  ///
  /// In vi, this message translates to:
  /// **'Tự gửi khi có mạng. Người cùng chăm chưa thấy các bản ghi này.'**
  String get pendingFootnote;

  /// 9b secondary.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại ngay'**
  String get retryNow;

  /// After a successful retry / SyncStatus synced.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ'**
  String get retrySynced;

  /// Retry did not drain the queue.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn chưa gửi được. App sẽ tự gửi khi có mạng.'**
  String get retryStill;

  /// SyncStatus pending copy (8:84).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trên máy này. Đang chờ đồng bộ.'**
  String get syncPendingLong;

  /// 19a sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh'**
  String get quickLogTitle;

  /// 19a tile.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get quickSleep;

  /// 22 / 23 sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi cữ bú'**
  String get feedSheetTitle;

  /// Bottle amount label.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa · tùy chọn'**
  String get amountOptional;

  /// Pump amount label.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa'**
  String get amountLabel;

  /// Bottle milk type label.
  ///
  /// In vi, this message translates to:
  /// **'Loại sữa'**
  String get milkTypeLabel;

  /// TimeRow label.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get timeLabel;

  /// TimeRow label for spans.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get startLabel;

  /// Side label.
  ///
  /// In vi, this message translates to:
  /// **'Bên'**
  String get sideLabel;

  /// Breast duration label.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng · tùy chọn'**
  String get durationOptional;

  /// Pump duration row.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get durationLabel;

  /// Pump duration chip without a value.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập'**
  String get durationNone;

  /// 22 / 23 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cữ bú'**
  String get saveFeed;

  /// 23a sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi hút sữa'**
  String get pumpTitle;

  /// 23a primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hút sữa'**
  String get savePump;

  /// 24 sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get diaperTitle;

  /// Generic save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get actionSave;

  /// TimeRow chip default.
  ///
  /// In vi, this message translates to:
  /// **'Bây giờ · {time}'**
  String timeNow(String time);

  /// TimeRow chip / detail.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {time}'**
  String timeToday(String time);

  /// TimeRow chip / detail.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua · {time}'**
  String timeYesterday(String time);

  /// Time wheel sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thời gian'**
  String get timePickerTitle;

  /// Duration wheel sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thời lượng'**
  String get durationPickerTitle;

  /// Toast after saving (Motion 270:22).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi · {what}'**
  String savedToast(String what);

  /// Toast after editing.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thay đổi'**
  String get editedToast;

  /// Toast action.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get undo;

  /// Out-of-range amount.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ {min} đến {max} {unit}.'**
  String amountRange(String min, String max, String unit);

  /// Write rejected by the server.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được bản ghi. Có thể quyền của bạn đã thay đổi.'**
  String get careSaveFailed;

  /// 28 title.
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng'**
  String get growthTitle;

  /// 28 date row.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đo'**
  String get growthDate;

  /// 28 weight label.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get growthWeight;

  /// 28 length label.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài · tùy chọn'**
  String get growthLengthOptional;

  /// 28 delta line.
  ///
  /// In vi, this message translates to:
  /// **'{delta} so với lần đo {date}'**
  String growthDeltaSince(String delta, String date);

  /// 28 section.
  ///
  /// In vi, this message translates to:
  /// **'Các lần đo trước'**
  String get growthPrevious;

  /// 28 link → History (S6).
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get growthSeeAll;

  /// 28 without earlier measurements.
  ///
  /// In vi, this message translates to:
  /// **'Đây là lần đo đầu tiên.'**
  String get growthNoPrevious;

  /// Birth measurement tag.
  ///
  /// In vi, this message translates to:
  /// **'Lúc sinh'**
  String get growthAtBirth;

  /// 28 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu số đo'**
  String get saveGrowth;

  /// Weight missing or out of range.
  ///
  /// In vi, this message translates to:
  /// **'Nhập cân nặng từ 0,3 đến 40 kg.'**
  String get growthWeightRequired;

  /// Length out of range.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài từ 20 đến 150 cm.'**
  String get growthLengthRange;

  /// 21 row.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get detailTime;

  /// 21 row.
  ///
  /// In vi, this message translates to:
  /// **'Người ghi'**
  String get detailBy;

  /// 21 row (creation time).
  ///
  /// In vi, this message translates to:
  /// **'Ghi lúc'**
  String get detailLoggedAt;

  /// 21 row.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ'**
  String get detailSync;

  /// 12e row.
  ///
  /// In vi, this message translates to:
  /// **'Lượng'**
  String get detailAmount;

  /// 12e row.
  ///
  /// In vi, this message translates to:
  /// **'Loại sữa'**
  String get detailMilk;

  /// Detail row.
  ///
  /// In vi, this message translates to:
  /// **'Bên'**
  String get detailSide;

  /// Detail row.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get detailDuration;

  /// Detail row.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài'**
  String get detailLength;

  /// 21 tinted button.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get actionEdit;

  /// 21 destructive.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi'**
  String get deleteRecord;

  /// 21 footer, adapted to D-022 (Figma: "Chỉ người ghi hoặc chủ sở hữu được sửa.").
  ///
  /// In vi, this message translates to:
  /// **'Mọi người trong gia đình thấy bản ghi này. Người ghi và Cùng nuôi được sửa.'**
  String get detailFooter;

  /// Delete action sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi này?'**
  String get deleteConfirmTitle;

  /// Delete action sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi được giữ 30 ngày trong “Đã xoá gần đây”.'**
  String get deleteConfirmBody;

  /// Toast "Đã xóa · Hoàn tác" (5 s).
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa'**
  String get deletedToast;

  /// 12e role note.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi của {who} · chỉ xem. Nếu sai, nhắn {who} để sửa.'**
  String viewOnlyNote(String who);

  /// 12e secondary (Q-007, messages arrive in S10).
  ///
  /// In vi, this message translates to:
  /// **'Nhắn {who}'**
  String messageAuthor(String who);

  /// Until messages ship (S10).
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin trong app sẽ có ở bản tiếp theo.'**
  String get messagesSoon;

  /// Detail of a deleted record.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi này không còn nữa.'**
  String get recordGone;

  /// Minutes unit after a duration field.
  ///
  /// In vi, this message translates to:
  /// **'phút'**
  String get unitMinutes;

  /// 14f meta (R-038, 118:12056).
  ///
  /// In vi, this message translates to:
  /// **'{relation} · tham gia {date} · đã ghi {count} lần'**
  String memberMetaCount(String relation, String date, int count);

  /// 25a sheet title (69:4213).
  ///
  /// In vi, this message translates to:
  /// **'Ghi giấc ngủ'**
  String get sleepChooserTitle;

  /// 25a prompt.
  ///
  /// In vi, this message translates to:
  /// **'{baby} đang ngủ hay đã ngủ xong rồi?'**
  String sleepChooserPrompt(String baby);

  /// 25a primary option / 26 link.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hẹn giờ'**
  String get sleepStartTimer;

  /// 25a option subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{baby} vừa ngủ. Đồng hồ chạy, cả nhà cùng thấy'**
  String sleepStartTimerHint(String baby);

  /// 25a secondary option.
  ///
  /// In vi, this message translates to:
  /// **'Nhập giấc đã ngủ'**
  String get sleepManual;

  /// 25a option subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên bấm giờ? Chọn giờ bắt đầu và kết thúc'**
  String get sleepManualHint;

  /// 25a footnote.
  ///
  /// In vi, this message translates to:
  /// **'Đổi cách bất cứ lúc nào: từ đồng hồ có thể sửa giờ bắt đầu, từ nhập tay có thể chuyển sang hẹn giờ.'**
  String get sleepChooserFootnote;

  /// Timer sync pill (R-070).
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà đang thấy'**
  String get timerFamilySees;

  /// Timer / record not synced (9c, 27).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ trên máy này'**
  String get timerOnlyHere;

  /// 9c note.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ này chưa được đồng bộ'**
  String get sleepNotSynced;

  /// Feed / pump timer offline note.
  ///
  /// In vi, this message translates to:
  /// **'Cữ này chưa được đồng bộ'**
  String get timerNotSynced;

  /// 25 title (47:3028).
  ///
  /// In vi, this message translates to:
  /// **'Bé {baby} đang ngủ'**
  String sleepTimerTitle(String baby);

  /// Timer subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{who} bắt đầu lúc {time}'**
  String timerStartedBy(String who, String time);

  /// Sleep ring label.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ'**
  String get sleepRingLabel;

  /// Sleep ring footer.
  ///
  /// In vi, this message translates to:
  /// **'Từ {time}'**
  String sinceTime(String time);

  /// 25 primary.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc giấc ngủ'**
  String get endSleep;

  /// 25 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giờ bắt đầu'**
  String get editStart;

  /// Timer plain button.
  ///
  /// In vi, this message translates to:
  /// **'Hủy, không lưu'**
  String get cancelNoSave;

  /// Timer cancel confirmation (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Hủy và không lưu?'**
  String get cancelConfirmTitle;

  /// Timer cancel confirmation body.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian đã chạy sẽ không được ghi.'**
  String get cancelConfirmBody;

  /// Timer cancel confirmation dismiss.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục bấm giờ'**
  String get keepTiming;

  /// 23b title (112:11135).
  ///
  /// In vi, this message translates to:
  /// **'{baby} đang bú mẹ'**
  String breastTimerTitle(String baby);

  /// Timer total label.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thời gian'**
  String get totalTime;

  /// Side disc label.
  ///
  /// In vi, this message translates to:
  /// **'TRÁI'**
  String get sideLeftCaps;

  /// Side disc label.
  ///
  /// In vi, this message translates to:
  /// **'PHẢI'**
  String get sideRightCaps;

  /// Active breast disc.
  ///
  /// In vi, this message translates to:
  /// **'Đang bú'**
  String get feedingNow;

  /// Inactive breast disc.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để đổi bên'**
  String get tapToSwitch;

  /// 23b hint.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước kết thúc bên trái'**
  String get lastEndedLeft;

  /// 23b hint.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước kết thúc bên phải'**
  String get lastEndedRight;

  /// 23b primary.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc cữ bú'**
  String get endFeed;

  /// Timer secondary.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pauseTimer;

  /// Timer secondary while paused.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get resumeTimer;

  /// Disc state while paused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pausedLabel;

  /// 23c title (113:11207).
  ///
  /// In vi, this message translates to:
  /// **'{who} đang hút sữa'**
  String pumpTimerTitle(String who);

  /// 23c subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu lúc {time} · cho {baby}'**
  String pumpStartedFor(String time, String baby);

  /// Running pump disc.
  ///
  /// In vi, this message translates to:
  /// **'Đang hút'**
  String get pumpingNow;

  /// Stopped pump disc.
  ///
  /// In vi, this message translates to:
  /// **'Đã dừng'**
  String get pumpStopped;

  /// Stopped pump disc hint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để chạy'**
  String get tapToStart;

  /// 23c hint.
  ///
  /// In vi, this message translates to:
  /// **'Hút đôi · chạm 1 bên để dừng riêng'**
  String get doublePumpHint;

  /// 23c primary.
  ///
  /// In vi, this message translates to:
  /// **'Xong · nhập lượng sữa'**
  String get pumpDone;

  /// 23 / 23a plain.
  ///
  /// In vi, this message translates to:
  /// **'Bấm giờ thay vì nhập'**
  String get timerInstead;

  /// A second start joined the running timer (P-011).
  ///
  /// In vi, this message translates to:
  /// **'{who} đã bắt đầu đồng hồ này trước. Bạn đang xem cùng.'**
  String timerJoined(String who);

  /// Sleep tile line.
  ///
  /// In vi, this message translates to:
  /// **'Dậy lúc {time}'**
  String wokeAt(String time);

  /// Running timer tile line.
  ///
  /// In vi, this message translates to:
  /// **'Từ {time} · {who}'**
  String runningSince(String time, String who);

  /// 26 title (47:3074).
  ///
  /// In vi, this message translates to:
  /// **'Nhập giấc ngủ'**
  String get manualSleepTitle;

  /// 26 chip.
  ///
  /// In vi, this message translates to:
  /// **'Qua đêm'**
  String get overnight;

  /// 26 end row.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get sleepEnd;

  /// 26 note.
  ///
  /// In vi, this message translates to:
  /// **'Giấc qua đêm được chia vào tổng của từng ngày theo múi giờ của bé ({offset}).'**
  String overnightNote(String offset);

  /// 26 link row.
  ///
  /// In vi, this message translates to:
  /// **'{baby} đang ngủ?'**
  String sleepingNow(String baby);

  /// 26 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giấc ngủ'**
  String get saveSleep;

  /// 26 validation (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Giờ kết thúc phải sau giờ bắt đầu.'**
  String get sleepEndBeforeStart;

  /// 26 validation (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Một giấc dài tối đa 24 giờ.'**
  String get sleepTooLong;

  /// 27 title (47:3145).
  ///
  /// In vi, this message translates to:
  /// **'Có hai giấc ngủ trùng nhau'**
  String get overlapTitle;

  /// 27 body.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bản đúng. App không tự gộp hay ghi đè.'**
  String get overlapBody;

  /// 27 sync pill.
  ///
  /// In vi, this message translates to:
  /// **'Đã có mạng lại'**
  String get backOnline;

  /// 27 primary.
  ///
  /// In vi, this message translates to:
  /// **'Giữ bản đã chọn'**
  String get keepSelected;

  /// 27 plain.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tay từ bản của tôi'**
  String get editMine;

  /// Today banner to 27 (eng-supplied).
  ///
  /// In vi, this message translates to:
  /// **'Có hai giấc ngủ trùng nhau · chọn bản đúng'**
  String get overlapBanner;

  /// Toast after 27.
  ///
  /// In vi, this message translates to:
  /// **'Đã giữ bản đã chọn. Bản kia vào “Đã xoá gần đây” 30 ngày.'**
  String get overlapKept;

  /// Caregiver cannot bin a parent’s sleep (D-022).
  ///
  /// In vi, this message translates to:
  /// **'Bản kia do ba mẹ ghi. Nhờ ba mẹ chọn nhé.'**
  String get overlapNotAllowed;

  /// Tour step.
  ///
  /// In vi, this message translates to:
  /// **'Bước {n}/3'**
  String tourStep(int n);

  /// 18 tour 1/3 (29:904).
  ///
  /// In vi, this message translates to:
  /// **'Ghi cữ bú đầu tiên'**
  String get tour1Title;

  /// 18 tour 1/3 body.
  ///
  /// In vi, this message translates to:
  /// **'Chạm thẻ Bú bình để ghi. Các thẻ khác cũng ghi y như vậy.'**
  String get tour1Body;

  /// 18b tour 2/3 (103:8099).
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi {baby} lớn lên'**
  String tour2Title(String baby);

  /// 18b body.
  ///
  /// In vi, this message translates to:
  /// **'Nhập cân nặng, chiều dài lúc sinh. Mỗi lần đo sau, app tự so với lần trước.'**
  String get tour2Body;

  /// 18c tour 3/3 (103:8275).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh từ mọi nơi'**
  String get tour3Title;

  /// 18c body.
  ///
  /// In vi, this message translates to:
  /// **'Nút + luôn ở đây, ở mọi tab. Chạm để chọn việc cần ghi.'**
  String get tour3Body;

  /// 18c last action.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get tourStart;

  /// 20 title (46:2469).
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get historyTitle;

  /// Month picker chip.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}'**
  String monthChip(int month, String monthName);

  /// Filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// Filter chip (bottle + breast).
  ///
  /// In vi, this message translates to:
  /// **'Bú'**
  String get filterFeed;

  /// Filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa'**
  String get filterPump;

  /// Filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get filterSleep;

  /// Filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Tã'**
  String get filterDiaper;

  /// Filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng'**
  String get filterGrowth;

  /// TimeSectionHeader (59:431).
  ///
  /// In vi, this message translates to:
  /// **'Đêm'**
  String get periodNight;

  /// TimeSectionHeader.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get periodMorning;

  /// TimeSectionHeader.
  ///
  /// In vi, this message translates to:
  /// **'Trưa'**
  String get periodNoon;

  /// TimeSectionHeader.
  ///
  /// In vi, this message translates to:
  /// **'Chiều'**
  String get periodAfternoon;

  /// TimeSectionHeader.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get periodEvening;

  /// Section count pill.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục'**
  String periodItems(int count);

  /// DayRhythm title for a past day (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi ngày {date}'**
  String loggedOnDay(String date);

  /// 20a card title.
  ///
  /// In vi, this message translates to:
  /// **'Bú hôm nay'**
  String get feedToday;

  /// 20a card title, past day.
  ///
  /// In vi, this message translates to:
  /// **'Bú ngày {date}'**
  String feedOnDay(String date);

  /// 20a row.
  ///
  /// In vi, this message translates to:
  /// **'Cữ gần nhất'**
  String get lastFeed;

  /// 20a row.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhau trung bình'**
  String get averageGap;

  /// 20a link card.
  ///
  /// In vi, this message translates to:
  /// **'Xem thống kê bú'**
  String get feedStatsLink;

  /// 20a link card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ ngày/đêm · lượng sữa theo giờ · bú mẹ trái/phải'**
  String get feedStatsLinkHint;

  /// 20b card title.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ hôm nay'**
  String get sleepToday;

  /// 20b card title, past day.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ ngày {date}'**
  String sleepOnDay(String date);

  /// 20b row.
  ///
  /// In vi, this message translates to:
  /// **'Tổng đã ngủ'**
  String get totalSlept;

  /// 20b row.
  ///
  /// In vi, this message translates to:
  /// **'Số giấc'**
  String get sleepCount;

  /// Sleep count.
  ///
  /// In vi, this message translates to:
  /// **'{count} giấc'**
  String sleepsValue(int count);

  /// 20b row / 20h KPI.
  ///
  /// In vi, this message translates to:
  /// **'Giấc dài nhất'**
  String get longestSleep;

  /// 20b row.
  ///
  /// In vi, this message translates to:
  /// **'Đang thức'**
  String get awakeNow;

  /// 20b value ("2 giờ · từ 13:05").
  ///
  /// In vi, this message translates to:
  /// **'{duration} · từ {time}'**
  String awakeSince(String duration, String time);

  /// 20b row while a sleep runs (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ'**
  String get asleepNow;

  /// 20b link card.
  ///
  /// In vi, this message translates to:
  /// **'Xem thống kê ngủ'**
  String get sleepStatsLink;

  /// 20b link card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ ngày/đêm · nhịp ngủ 7 ngày · giấc dài nhất'**
  String get sleepStatsLinkHint;

  /// 20c card title.
  ///
  /// In vi, this message translates to:
  /// **'Tã hôm nay'**
  String get diaperToday;

  /// 20c card title, past day.
  ///
  /// In vi, this message translates to:
  /// **'Tã ngày {date}'**
  String diaperOnDay(String date);

  /// 20c row.
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get diaperTotal;

  /// 20c row.
  ///
  /// In vi, this message translates to:
  /// **'Gần nhất'**
  String get diaperLast;

  /// Count of changes.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần'**
  String timesValue(int count);

  /// Pump card title (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa hôm nay'**
  String get pumpToday;

  /// Pump card title, past day (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa ngày {date}'**
  String pumpOnDay(String date);

  /// Pump card row.
  ///
  /// In vi, this message translates to:
  /// **'Số lần'**
  String get pumpSessions;

  /// Pump card row.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa'**
  String get pumpVolume;

  /// Pump card note (D-026).
  ///
  /// In vi, this message translates to:
  /// **'Sữa hút ra không tính vào lượng bé bú.'**
  String get pumpNotIntake;

  /// Timeline title.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ · {side}'**
  String rowBreastSide(String side);

  /// Breast / pump sides.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai bên'**
  String get sideBothFull;

  /// Breast / pump side.
  ///
  /// In vi, this message translates to:
  /// **'Bên trái'**
  String get sideLeftFull;

  /// Breast / pump side.
  ///
  /// In vi, this message translates to:
  /// **'Bên phải'**
  String get sideRightFull;

  /// Timeline title ("Ngủ 1 giờ 20 phút").
  ///
  /// In vi, this message translates to:
  /// **'Ngủ {duration}'**
  String rowSleep(String duration);

  /// Time span.
  ///
  /// In vi, this message translates to:
  /// **'{from} – {to}'**
  String rowSpan(String from, String to);

  /// Start before the day (D-027).
  ///
  /// In vi, this message translates to:
  /// **'{time} hôm qua'**
  String rowYesterdayTime(String time);

  /// Running timer row (G-067).
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get rowRunning;

  /// 20d card label.
  ///
  /// In vi, this message translates to:
  /// **'Gần nhất · {when}'**
  String growthLatest(String when);

  /// 20d toggle.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get growthWeightTab;

  /// 20d toggle.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài'**
  String get growthLengthTab;

  /// 20d delta pill.
  ///
  /// In vi, this message translates to:
  /// **'{delta} so với {date}'**
  String growthDeltaVs(String delta, String date);

  /// 20d section.
  ///
  /// In vi, this message translates to:
  /// **'Các lần đo'**
  String get growthMeasurements;

  /// 20d button.
  ///
  /// In vi, this message translates to:
  /// **'Thêm số đo'**
  String get growthAdd;

  /// 20d empty (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lần đo nào.'**
  String get growthEmpty;

  /// 20e object.
  ///
  /// In vi, this message translates to:
  /// **'cữ bú'**
  String get emptyFeedWhat;

  /// 20e object.
  ///
  /// In vi, this message translates to:
  /// **'hút sữa'**
  String get emptyPumpWhat;

  /// 20e object.
  ///
  /// In vi, this message translates to:
  /// **'giấc ngủ'**
  String get emptySleepWhat;

  /// 20e object.
  ///
  /// In vi, this message translates to:
  /// **'thay tã'**
  String get emptyDiaperWhat;

  /// 20e object (all, not drawn).
  ///
  /// In vi, this message translates to:
  /// **'ghi chép nào'**
  String get emptyAllWhat;

  /// 20e title (105:9471).
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi {what} ngày {date}'**
  String emptyDayTitle(String what, String date);

  /// 20e title for today (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi {what} hôm nay'**
  String emptyTodayTitle(String what);

  /// 20e body.
  ///
  /// In vi, this message translates to:
  /// **'Nếu quên ghi lúc đó, bạn có thể ghi bù với giờ của ngày này.'**
  String get emptyDayBody;

  /// 20e button.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bù {what}'**
  String backLog(String what);

  /// Empty today button.
  ///
  /// In vi, this message translates to:
  /// **'Ghi {what}'**
  String logNow(String what);

  /// 20e link.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả ghi chép ngày {date}'**
  String seeAllOnDay(String date);

  /// 20f sheet title (108:10271).
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get pickDateTitle;

  /// 20f month header.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}, {year}'**
  String calendarMonth(int month, int year, String monthName);

  /// 20f footnote.
  ///
  /// In vi, this message translates to:
  /// **'Chấm màu = ngày có ghi chép. {baby} sinh ngày {date}, không chọn được ngày trước đó.'**
  String calendarFootnote(String baby, String date);

  /// 20f footnote without the birth date (caregivers).
  ///
  /// In vi, this message translates to:
  /// **'Chấm màu = ngày có ghi chép.'**
  String get calendarFootnoteNoDob;

  /// 20f button.
  ///
  /// In vi, this message translates to:
  /// **'Về hôm nay'**
  String get backToToday;

  /// Calendar arrow.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get a11yPrevMonth;

  /// Calendar arrow.
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get a11yNextMonth;

  /// 20g title (109:10562).
  ///
  /// In vi, this message translates to:
  /// **'Thống kê bú'**
  String get feedStatsTitle;

  /// 20h title (111:10994).
  ///
  /// In vi, this message translates to:
  /// **'Thống kê ngủ'**
  String get sleepStatsTitle;

  /// Stats segment.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get windowToday;

  /// Stats segment.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get window7;

  /// Stats segment.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get window30;

  /// KPI label.
  ///
  /// In vi, this message translates to:
  /// **'TB mỗi ngày'**
  String get perDay;

  /// KPI label.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhau TB'**
  String get gapAverage;

  /// 20g2 KPI label.
  ///
  /// In vi, this message translates to:
  /// **'Từ 18h hôm qua'**
  String get sinceYesterday18;

  /// Feeds.
  ///
  /// In vi, this message translates to:
  /// **'{count} cữ'**
  String feedsCount(int count);

  /// 20g2 KPI label.
  ///
  /// In vi, this message translates to:
  /// **'{bottles} bình · {breasts} mẹ'**
  String bottlesBreasts(int bottles, int breasts);

  /// 20g card title.
  ///
  /// In vi, this message translates to:
  /// **'Bú ngày và đêm'**
  String get dayNightFeed;

  /// 20g card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày 06:00–18:00 · Đêm 18:00–06:00 · TB {days} ngày'**
  String dayNightFeedHint(int days);

  /// 20g2 card title.
  ///
  /// In vi, this message translates to:
  /// **'Đêm qua và hôm nay'**
  String get nightAndToday;

  /// 20g2 card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đêm qua 18:00–06:00 · Hôm nay từ 06:00'**
  String get nightAndTodayHint;

  /// Ratio legend.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get dayLabel;

  /// Ratio legend.
  ///
  /// In vi, this message translates to:
  /// **'Đêm'**
  String get nightLabel;

  /// Ratio legend (20g2).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayLabel;

  /// Ratio legend (20g2).
  ///
  /// In vi, this message translates to:
  /// **'Đêm qua'**
  String get lastNightLabel;

  /// Ratio legend detail.
  ///
  /// In vi, this message translates to:
  /// **'{ml} ml · {count} cữ'**
  String mlAndFeeds(int ml, int count);

  /// 20g insight.
  ///
  /// In vi, this message translates to:
  /// **'Đêm qua bú {count} cữ, khoảng nghỉ dài nhất {gap} ({from}–{to}).'**
  String lastNightInsight(int count, String gap, String from, String to);

  /// 20g2 insight.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng nghỉ dài nhất đêm qua: {gap} ({from}–{to}).'**
  String lastNightGapInsight(String gap, String from, String to);

  /// 20g card.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa theo giờ'**
  String get milkByHour;

  /// 20g card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình · trung bình {days} ngày (ml)'**
  String milkByHourHint(int days);

  /// 20g peak.
  ///
  /// In vi, this message translates to:
  /// **'{hour}h · {ml} ml'**
  String peakCallout(int hour, int ml);

  /// 20g legend.
  ///
  /// In vi, this message translates to:
  /// **'ml mỗi giờ'**
  String get mlPerHour;

  /// Chart legend.
  ///
  /// In vi, this message translates to:
  /// **'Khung đêm'**
  String get nightWindow;

  /// 20g2 card.
  ///
  /// In vi, this message translates to:
  /// **'Từng cữ hôm nay'**
  String get eachFeedToday;

  /// 20g2 card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi cột là một cữ bú bình (ml) · chấm hồng là bú mẹ'**
  String get eachFeedHint;

  /// Chart future area.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tới'**
  String get notYet;

  /// Chart now line.
  ///
  /// In vi, this message translates to:
  /// **'Bây giờ'**
  String get nowLabel;

  /// 20g2 legend.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình (ml)'**
  String get bottleMlLegend;

  /// 20g2 legend.
  ///
  /// In vi, this message translates to:
  /// **'Đêm / chưa tới'**
  String get nightOrNotYet;

  /// Stats card.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ'**
  String get breastCard;

  /// Card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'TB {days} ngày'**
  String averageDays(int days);

  /// KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'mỗi ngày'**
  String get perDayShort;

  /// KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'mỗi cữ'**
  String get perFeed;

  /// KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get todayShort;

  /// Side legend.
  ///
  /// In vi, this message translates to:
  /// **'Bên trái {pct}%'**
  String leftShare(int pct);

  /// Side legend.
  ///
  /// In vi, this message translates to:
  /// **'Bên phải {pct}%'**
  String rightShare(int pct);

  /// Side legend (today).
  ///
  /// In vi, this message translates to:
  /// **'Trái {minutes} phút'**
  String leftMinutes(int minutes);

  /// Side legend (today).
  ///
  /// In vi, this message translates to:
  /// **'Phải {minutes} phút'**
  String rightMinutes(int minutes);

  /// Breast hint.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái.'**
  String get nextSideLeft;

  /// Breast hint.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước kết thúc bên trái → lần tới nên bắt đầu bên phải.'**
  String get nextSideRight;

  /// 20h card.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ ngày và đêm'**
  String get dayNightSleep;

  /// 20h card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đêm 18:00–06:00 · Ngày 06:00–18:00 · TB {days} ngày'**
  String dayNightSleepHint(int days);

  /// 20h legend detail.
  ///
  /// In vi, this message translates to:
  /// **'{duration} · {range} giấc'**
  String durationAndSleeps(String duration, String range);

  /// 20h insight.
  ///
  /// In vi, this message translates to:
  /// **'Giấc đêm dài nhất tăng từ {from} lên {to} trong {days} ngày.'**
  String nightLongestInsight(int days, String from, String to);

  /// 20h insight without a trend.
  ///
  /// In vi, this message translates to:
  /// **'Giấc đêm dài nhất: {duration}.'**
  String nightLongestSame(String duration);

  /// 20h card.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp ngủ {days} ngày'**
  String sleepRhythm(int days);

  /// 20h card for Hôm nay (D-028).
  ///
  /// In vi, this message translates to:
  /// **'Nhịp ngủ hôm nay'**
  String get sleepRhythmToday;

  /// 20h card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi hàng là một ngày · thanh tím là lúc ngủ'**
  String get sleepRhythmHint;

  /// 20h card.
  ///
  /// In vi, this message translates to:
  /// **'Giấc dài nhất mỗi ngày'**
  String get longestEachDay;

  /// 20h card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giờ ngủ liền một mạch'**
  String get longestEachDayHint;

  /// Chart legend.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get legendSleepShort;

  /// Stats without records (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ dữ liệu trong khoảng này.'**
  String get statsEmpty;

  /// Compact duration in stats.
  ///
  /// In vi, this message translates to:
  /// **'{h}g {m}p'**
  String compactHM(int h, int m);

  /// Compact hours.
  ///
  /// In vi, this message translates to:
  /// **'{h}g'**
  String compactH(int h);

  /// Chart label ("6g30").
  ///
  /// In vi, this message translates to:
  /// **'{h}g{m}'**
  String compactHMShort(int h, String m);

  /// 20h legend detail, one count (Hôm nay).
  ///
  /// In vi, this message translates to:
  /// **'{duration} · {count} giấc'**
  String durationAndSleep(String duration, int count);

  /// 20h card subtitle for Hôm nay (D-028): calendar day, clipped at midnight (D-027).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · Đêm 00:00–06:00 · Ngày 06:00–18:00'**
  String get dayNightSleepTodayHint;

  /// 12d role note (192:618), caregivers (D-022).
  ///
  /// In vi, this message translates to:
  /// **'Bạn sửa được bản ghi của mình. Bản ghi của ba mẹ chỉ xem.'**
  String get historyCaregiverNote;

  /// 8a title (127:13602).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get remindersTitle;

  /// 8a group.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get remindersOverdue;

  /// 8a group.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get remindersUpcoming;

  /// 8a group.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get remindersDone;

  /// 8a info line (R-091).
  ///
  /// In vi, this message translates to:
  /// **'Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.'**
  String get remindersInfo;

  /// 8a button / 8b title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc mới'**
  String get reminderNew;

  /// ReminderRow meta ("Mẹ tạo").
  ///
  /// In vi, this message translates to:
  /// **'{who} tạo'**
  String reminderCreatedBy(String who);

  /// ReminderRow overdue meta.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn · {when}'**
  String reminderOverdueMeta(String when);

  /// ReminderRow done meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} đánh dấu xong · {date}'**
  String reminderDoneMeta(String who, String date);

  /// Relative day word.
  ///
  /// In vi, this message translates to:
  /// **'ngày mai'**
  String get dayTomorrow;

  /// Empty list (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhắc việc'**
  String get remindersEmpty;

  /// Empty list body (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Ghi lịch tiêm, tái khám hay việc cần mua để cả nhà cùng thấy.'**
  String get remindersEmptyBody;

  /// 12f role note (192:1327).
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong.'**
  String get remindersCaregiverNote;

  /// 8d notice (127:13867).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc việc. Chưa bật thông báo trên máy này.'**
  String get remindersNotifOff;

  /// 8d link.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get remindersOpenSettings;

  /// 8c toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc việc'**
  String get reminderSaved;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh dấu xong'**
  String get reminderMarkedDone;

  /// Toast (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh dấu chưa xong'**
  String get reminderMarkedUndone;

  /// Toast (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá nhắc việc'**
  String get reminderDeleted;

  /// Toast (D-029).
  ///
  /// In vi, this message translates to:
  /// **'Thông báo sẽ đến trên máy này'**
  String get reminderMoved;

  /// 8e button / edit sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhắc việc'**
  String get reminderEditTitle;

  /// 8b field.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần nhớ'**
  String get reminderWhat;

  /// 8b placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Tiêm 6 trong 1'**
  String get reminderWhatHint;

  /// 8b / 8e row.
  ///
  /// In vi, this message translates to:
  /// **'Ngày giờ'**
  String get reminderWhen;

  /// 8b / 8e row.
  ///
  /// In vi, this message translates to:
  /// **'Báo trước'**
  String get reminderLead;

  /// 8b footnote.
  ///
  /// In vi, this message translates to:
  /// **'Theo giờ của {name} ({zone}). Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.'**
  String reminderFootnote(String name, String zone);

  /// 8b button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu nhắc việc'**
  String get reminderSave;

  /// Validation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập việc cần nhớ.'**
  String get reminderTitleRequired;

  /// Validation (D-031).
  ///
  /// In vi, this message translates to:
  /// **'Chọn thời điểm sau bây giờ.'**
  String get reminderPastTime;

  /// Báo trước option (D-031).
  ///
  /// In vi, this message translates to:
  /// **'Đúng giờ'**
  String get leadOnTime;

  /// Báo trước option (D-031).
  ///
  /// In vi, this message translates to:
  /// **'1 ngày'**
  String get leadOneDay;

  /// Báo trước value in lists.
  ///
  /// In vi, this message translates to:
  /// **'{lead} trước'**
  String leadBefore(String lead);

  /// Edit sheet (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhắc việc'**
  String get reminderDelete;

  /// Confirm (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhắc việc này?'**
  String get reminderDeleteTitle;

  /// Confirm (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà sẽ không thấy nhắc việc này nữa.'**
  String get reminderDeleteBody;

  /// 8c (127:13809).
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo trên máy này?'**
  String get notifPromptTitle;

  /// 8c body.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.'**
  String get notifPromptBody;

  /// 8c primary.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get notifPromptAllow;

  /// 8e overline.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc · {name}'**
  String reminderOverline(String name);

  /// 8e row.
  ///
  /// In vi, this message translates to:
  /// **'Múi giờ'**
  String get reminderTimeZone;

  /// 8e row.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get reminderNotify;

  /// 8e value ("iPhone của Mai").
  ///
  /// In vi, this message translates to:
  /// **'{device} của {name}'**
  String reminderDeviceOf(String device, String name);

  /// 8e value, no device (D-029).
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt trên máy nào'**
  String get reminderNoDevice;

  /// 8e row.
  ///
  /// In vi, this message translates to:
  /// **'Người tạo'**
  String get reminderCreator;

  /// 8e row for a done reminder.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get reminderDoneRow;

  /// 8e note.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo chỉ được đặt trên máy tạo nhắc việc. Đánh dấu xong khi đã làm.'**
  String get reminderDetailNote;

  /// 8e primary.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã xong'**
  String get reminderMarkDone;

  /// 8e for a done reminder (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu chưa xong'**
  String get reminderUndo;

  /// D-075 #5: all-day reminder (8b toggle, 8e value, notification body).
  ///
  /// In vi, this message translates to:
  /// **'Cả ngày'**
  String get reminderAllDay;

  /// D-075 #5: ReminderRow meta for an all-day reminder.
  ///
  /// In vi, this message translates to:
  /// **'cả ngày'**
  String get reminderAllDayLower;

  /// D-075 #5: 8b / 8e date row of an all-day reminder.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get reminderDay;

  /// D-075 #5: 8b / 8e row with the person's all-day time.
  ///
  /// In vi, this message translates to:
  /// **'Giờ báo'**
  String get reminderAllDayAt;

  /// D-075 #5: time picker title.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc việc cả ngày'**
  String get reminderAllDayTimeTitle;

  /// D-075 #5: under the all-day time picker.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng cho mọi nhắc việc cả ngày báo trên máy này, theo giờ của {name}.'**
  String reminderAllDayTimeNote(String name);

  /// D-075 #5: "Báo trước" 0 for an all-day reminder.
  ///
  /// In vi, this message translates to:
  /// **'Đúng ngày'**
  String get leadOnDay;

  /// D-075 #5: 8b / 8e assignee row.
  ///
  /// In vi, this message translates to:
  /// **'Giao cho'**
  String get reminderAssignee;

  /// D-075 #5: assignee row value when unassigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa giao'**
  String get reminderAssignNone;

  /// D-075 #5: assignee picker option.
  ///
  /// In vi, this message translates to:
  /// **'Không giao ai'**
  String get reminderAssignNobody;

  /// D-075 #5: assignee picker note.
  ///
  /// In vi, this message translates to:
  /// **'Người được giao nhận thông báo trên máy của họ khi mở app. Chỉ Cùng nuôi và người chăm sóc được giao.'**
  String get reminderAssignPickerNote;

  /// D-075 #5: highlighted label for the assignee.
  ///
  /// In vi, this message translates to:
  /// **'Giao cho bạn'**
  String get reminderAssignedToYou;

  /// D-075 #5: label others see ("Giao cho Cô Lan").
  ///
  /// In vi, this message translates to:
  /// **'Giao cho {name}'**
  String reminderAssignedTo(String name);

  /// D-075 #5: 8e "Thông báo" when assigned to me.
  ///
  /// In vi, this message translates to:
  /// **'Các máy của bạn'**
  String get reminderNotifyMine;

  /// D-075 #5: 8e "Thông báo" when assigned to someone.
  ///
  /// In vi, this message translates to:
  /// **'Các máy của {name}'**
  String reminderNotifyAssignee(String name);

  /// D-075 #5: 8b footnote when assigned to someone else.
  ///
  /// In vi, this message translates to:
  /// **'Theo giờ của {name} ({zone}). Gia đình thấy nhắc việc trong app. {who} nhận thông báo trên máy của mình khi mở app.'**
  String reminderFootnoteAssigned(String name, String zone, String who);

  /// D-075 #5: 8e note for an assigned reminder.
  ///
  /// In vi, this message translates to:
  /// **'Người được giao nhận thông báo trên máy của mình khi mở app. Đánh dấu xong khi đã làm.'**
  String get reminderDetailNoteAssigned;

  /// D-075 #5: all-day date in the past.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hôm nay hoặc một ngày sau.'**
  String get reminderPastDay;

  /// D-029 sheet.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo trên máy này?'**
  String get moveNotifTitle;

  /// D-029 sheet.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo của nhắc việc này sẽ chuyển sang {device}. Máy đang giữ thông báo sẽ không báo nữa.'**
  String moveNotifBody(String device);

  /// D-029 sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang máy này'**
  String get moveNotifAction;

  /// ReminderPeek label.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc · {count}'**
  String reminderPeekLabel(int count);

  /// ReminderPeek countdown.
  ///
  /// In vi, this message translates to:
  /// **'còn {count} ngày'**
  String reminderInDays(int count);

  /// ReminderPeek countdown, same day.
  ///
  /// In vi, this message translates to:
  /// **'còn {duration}'**
  String reminderInDuration(String duration);

  /// ReminderPeek empty (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhắc việc sắp tới'**
  String get reminderPeekEmpty;

  /// ReminderPeek empty action.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhắc việc'**
  String get reminderPeekAdd;

  /// Hôm nay reminder card: opens Nhắc nhở after the first 3 (owner request 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get reminderPeekMore;

  /// Local notification body.
  ///
  /// In vi, this message translates to:
  /// **'{name} · {when}'**
  String notifBody(String name, String when);

  /// Android channel name.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc'**
  String get notifChannel;

  /// Android channel description.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc của gia đình'**
  String get notifChannelDescription;

  /// Android channel for family notices: new memories, messages, loves, videos (Android plan A1).
  ///
  /// In vi, this message translates to:
  /// **'Gia đình & kỷ niệm'**
  String get notifChannelFamily;

  /// Android channel description.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mới, lời nhắn và tin từ gia đình'**
  String get notifChannelFamilyDescription;

  /// Android channel for spending notices (recurring items, budget).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get notifChannelSpending;

  /// Android channel description.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi định kỳ và ngân sách tháng'**
  String get notifChannelSpendingDescription;

  /// Android reminder notice button (1f, A6); iOS has the same in RuleNotifications.swift.
  ///
  /// In vi, this message translates to:
  /// **'Báo lại sau 15 phút'**
  String get notifSnooze15;

  /// Android vaccine notice button (VX 8, A6).
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch tiêm'**
  String get notifVxView;

  /// Android vaccine notice button (VX 8, A6).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lại sáng mai'**
  String get notifVxSnooze;

  /// Android channel for a running sleep or breastfeeding timer (A5).
  ///
  /// In vi, this message translates to:
  /// **'Bộ đếm giờ'**
  String get notifChannelTimers;

  /// Android channel description.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ và cữ bú đang chạy'**
  String get notifChannelTimersDescription;

  /// Android channel for upload progress and the done notice (10j, A3).
  ///
  /// In vi, this message translates to:
  /// **'Tải lên'**
  String get notifChannelUploads;

  /// Android channel description.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ tải ảnh, video và báo khi xong'**
  String get notifChannelUploadsDescription;

  /// Row check.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu xong: {title}'**
  String a11yMarkDone(String title);

  /// Row check (D-030).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ đánh dấu xong: {title}'**
  String a11yUndoDone(String title);

  /// Memory tab (10a).
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký'**
  String get memJournal;

  /// Memory tab (10b).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get memPhotos;

  /// Memory tab (10d, S10).
  ///
  /// In vi, this message translates to:
  /// **'Album'**
  String get memAlbums;

  /// Memory tab (S12).
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện'**
  String get memStories;

  /// Tabs not built yet (S10, S12).
  ///
  /// In vi, this message translates to:
  /// **'Sắp có'**
  String get memSoonTitle;

  /// Tabs not built yet.
  ///
  /// In vi, this message translates to:
  /// **'Phần này có trong bản cập nhật tới.'**
  String get memSoonBody;

  /// Header sliders button.
  ///
  /// In vi, this message translates to:
  /// **'Cách xem'**
  String get a11yViewOptions;

  /// Header + button.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào Kỷ niệm'**
  String get a11yAddMemory;

  /// 10a week group (R-113).
  ///
  /// In vi, this message translates to:
  /// **'Tuần thứ {week}'**
  String memWeek(int week);

  /// Week group for earlier dates.
  ///
  /// In vi, this message translates to:
  /// **'Trước ngày chào đời'**
  String get memBeforeBirth;

  /// Count.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String memPhotoCount(int count);

  /// Count.
  ///
  /// In vi, this message translates to:
  /// **'{count} video'**
  String memVideoCount(int count);

  /// Count (10b5).
  ///
  /// In vi, this message translates to:
  /// **'{count} mục'**
  String memItemCount(int count);

  /// Entry date.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {time}'**
  String memTodayAt(String time);

  /// Entry date.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua · {time}'**
  String memYesterdayAt(String time);

  /// Empty journal (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kỷ niệm nào'**
  String get memEmptyTitle;

  /// Empty journal.
  ///
  /// In vi, this message translates to:
  /// **'Chạm + để thêm ảnh, video hoặc ghi chú đầu tiên của {name}.'**
  String memEmptyBody(String name);

  /// Empty grid.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và video của {name} sẽ hiện ở đây.'**
  String memPhotosEmpty(String name);

  /// 10b Ảnh: items uploading or being processed, not in the grid yet (owner request 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đang thêm {count} mục…}}'**
  String memLanding(int count);

  /// Filtered empty.
  ///
  /// In vi, this message translates to:
  /// **'Không có mục nào khớp cách xem này.'**
  String get memNoMatch;

  /// Tile before ready.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get memProcessing;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải {done}/{total} mục'**
  String upUploading(int done, int total);

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Cứ làm việc khác, xong sẽ báo bạn'**
  String get upUploadingHint;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng · chờ mạng'**
  String get upPaused;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Tự tải tiếp khi có mạng'**
  String get upPausedHint;

  /// UploadPill after "Tạm dừng".
  ///
  /// In vi, this message translates to:
  /// **'Đã tạm dừng'**
  String get upPausedByYou;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để tiếp tục'**
  String get upPausedByYouHint;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục chưa tải được'**
  String upFailed(int count);

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để thử lại hoặc bỏ qua'**
  String get upFailedHint;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải xong {count} mục'**
  String upDone(int count);

  /// UploadPill done.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo cho {names}'**
  String upToldFamily(String names);

  /// UploadPill done, Chỉ ba mẹ.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ xem được'**
  String get upParentsOnly;

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'{count} video chờ Wi-Fi'**
  String upWaitingWifi(int count);

  /// UploadPill.
  ///
  /// In vi, this message translates to:
  /// **'Video tự tải khi có Wi-Fi'**
  String get upWaitingWifiHint;

  /// UploadPill (R-121).
  ///
  /// In vi, this message translates to:
  /// **'Hết dung lượng · {count} mục giữ trên máy'**
  String upWaitingQuota(int count);

  /// UploadPill (R-121).
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem'**
  String get upWaitingQuotaHint;

  /// UploadPill before the session.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị {count} mục'**
  String upPreparing(int count);

  /// 10a2 / 10h title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào Kỷ niệm'**
  String get addTitle;

  /// 10a2 recent strip.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mới chụp hôm nay'**
  String get addRecent;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để chọn'**
  String get addRecentHint;

  /// 10a2 recent strip: how many are chosen.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {count}'**
  String addRecentCount(int count);

  /// 10a2 recent strip: goes on to compose with the chosen items (owner, 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Thêm {count} mục}}'**
  String addRecentAdd(int count);

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh hoặc quay video'**
  String get addCamera;

  /// 10a2 camera row on Android: the system camera takes photos here, videos on the next row (Q-066).
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get addCameraPhoto;

  /// 10a2 on Android: the system video camera, length capped by the server limit (Q-066).
  ///
  /// In vi, this message translates to:
  /// **'Quay video'**
  String get addCameraVideo;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thẳng vào Kỷ niệm'**
  String get addCameraHint;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ Thư viện ảnh'**
  String get addLibrary;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhiều ảnh, video một lần'**
  String get addLibraryHint;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ Tệp'**
  String get addFiles;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'iCloud Drive, Google Drive, USB…'**
  String get addFilesHint;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Viết ghi chú'**
  String get addNote;

  /// 10a2.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm chỉ có chữ, thêm ảnh sau'**
  String get addNoteHint;

  /// 10g chip.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get pickRecent;

  /// 10g chip.
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get pickVideos;

  /// 10g chip.
  ///
  /// In vi, this message translates to:
  /// **'Album'**
  String get pickAlbums;

  /// 10g tray.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục · {photos} ảnh, {videos} video'**
  String pickSummary(int count, int photos, int videos);

  /// 10g tray (R-102).
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {count} mục/lần'**
  String pickMax(int count);

  /// 10g primary.
  ///
  /// In vi, this message translates to:
  /// **'Thêm {count} mục'**
  String pickAdd(int count);

  /// 10g limit toast.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi lần thêm tối đa {count} mục.'**
  String pickLimit(int count);

  /// 10g denied (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa được xem thư viện ảnh.'**
  String get pickNoAccess;

  /// 10g limited access.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang cho xem một số ảnh.'**
  String get pickLimited;

  /// 10g limited access.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thêm'**
  String get pickChooseMore;

  /// 10g empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào ở đây'**
  String get pickEmpty;

  /// 10g album chip sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn album'**
  String get pickAlbumsTitle;

  /// 10g primary before anything is selected.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get pickConfirm;

  /// 10g toast: video over the configured duration (D-011).
  ///
  /// In vi, this message translates to:
  /// **'Chưa thêm được video dài hơn {limit}.'**
  String pickVideoTooLong(String limit);

  /// 10g toast: video over the configured file size (D-011).
  ///
  /// In vi, this message translates to:
  /// **'Chưa thêm được video lớn hơn {size}.'**
  String pickVideoTooBig(String size);

  /// 10g toast while picked originals are fetched (e.g. from iCloud).
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị ảnh và video…'**
  String get pickPreparing;

  /// 10h caption.
  ///
  /// In vi, this message translates to:
  /// **'Viết vài dòng… (không bắt buộc)'**
  String get composeCaption;

  /// Note compose.
  ///
  /// In vi, this message translates to:
  /// **'Viết điều bạn muốn nhớ…'**
  String get composeNoteHint;

  /// 10h row.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get composeDate;

  /// 10h value.
  ///
  /// In vi, this message translates to:
  /// **'Theo ngày chụp'**
  String get composeByCapture;

  /// 10h row.
  ///
  /// In vi, this message translates to:
  /// **'Mốc'**
  String get composeMilestone;

  /// 10h value / 10h3 clear.
  ///
  /// In vi, this message translates to:
  /// **'Không gắn mốc'**
  String get composeNoMilestone;

  /// 10h section.
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy'**
  String get composeWho;

  /// Audience.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ'**
  String get audParents;

  /// Audience card.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ xem được'**
  String get audParentsHint;

  /// Audience.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get audFamily;

  /// Audience card.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà cùng xem'**
  String get audFamilyHint;

  /// 10h toggle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cho gia đình'**
  String get composeNotify;

  /// 10h toggle.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình nhận 1 thông báo'**
  String get composeNotifyHint;

  /// 10h primary.
  ///
  /// In vi, this message translates to:
  /// **'Tải lên {count} mục'**
  String composeUpload(int count);

  /// Note primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ghi chú'**
  String get composeSaveNote;

  /// 10h footnote.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh tải ở nền — xong sẽ báo bạn.'**
  String get composeFootnote;

  /// Note validation.
  ///
  /// In vi, this message translates to:
  /// **'Viết vài chữ cho ghi chú.'**
  String get composeNoteRequired;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ghi chú'**
  String get composeNoteSaved;

  /// 10h strip overflow.
  ///
  /// In vi, this message translates to:
  /// **'+{count}'**
  String composeMore(int count);

  /// 10h2 title.
  ///
  /// In vi, this message translates to:
  /// **'Ngày của kỷ niệm'**
  String get dateTitle;

  /// 10h2.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ảnh giữ ngày riêng · {range}'**
  String dateByCaptureHint(String range);

  /// 10h2.
  ///
  /// In vi, this message translates to:
  /// **'Một ngày cho tất cả'**
  String get dateOneForAll;

  /// 10h2.
  ///
  /// In vi, this message translates to:
  /// **'Dùng khi ngày chụp bị sai'**
  String get dateOneForAllHint;

  /// 10h2 helper.
  ///
  /// In vi, this message translates to:
  /// **'Không chọn được ngày trước khi {name} chào đời.'**
  String dateBeforeBirth(String name);

  /// 10h3 title / 10b3 row.
  ///
  /// In vi, this message translates to:
  /// **'Gắn mốc'**
  String get msTitle;

  /// 10h3 search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm hoặc gõ mốc mới…'**
  String get msSearch;

  /// 10h3 section.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho bé {age}'**
  String msSuggest(String age);

  /// 10h3 section.
  ///
  /// In vi, this message translates to:
  /// **'Mốc nhà mình đã tạo'**
  String get msOwn;

  /// 10h3 / 10h4.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mốc mới'**
  String get msCreate;

  /// 10h3.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi kỷ niệm 1 mốc'**
  String get msOnePer;

  /// 10h4 field.
  ///
  /// In vi, this message translates to:
  /// **'Tên mốc'**
  String get msName;

  /// 10h4.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước'**
  String get msPreview;

  /// 10h4 helper (R-105).
  ///
  /// In vi, this message translates to:
  /// **'Mốc mới được lưu cho cả nhà dùng lại lần sau.'**
  String get msShared;

  /// 10h4 primary.
  ///
  /// In vi, this message translates to:
  /// **'Tạo & gắn mốc'**
  String get msCreateTag;

  /// 10h4 validation.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho mốc.'**
  String get msNameRequired;

  /// Milestone chip.
  ///
  /// In vi, this message translates to:
  /// **'{name} · {date}'**
  String msChip(String name, String date);

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu cười'**
  String get msFirstSmile;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu tắm'**
  String get msFirstBath;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Ngẩng đầu'**
  String get msLiftsHead;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu đi dạo'**
  String get msFirstOuting;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Đầy tháng'**
  String get msOneMonth;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu gặp ông bà'**
  String get msMeetsGrandparents;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu lật người'**
  String get msRollsOver;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Cười thành tiếng'**
  String get msLaughs;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu ăn dặm'**
  String get msFirstSolids;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Tự ngồi'**
  String get msSitsUp;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Chiếc răng đầu tiên'**
  String get msFirstTooth;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Biết bò'**
  String get msCrawls;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Tiếng nói đầu tiên'**
  String get msFirstWord;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Bước đi đầu tiên'**
  String get msFirstSteps;

  /// Preset milestone (10h3; after the first six: engineering suggestion).
  ///
  /// In vi, this message translates to:
  /// **'Thôi nôi'**
  String get msFirstBirthday;

  /// 10i title.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lên'**
  String get qTitle;

  /// 10i summary.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} mục · còn khoảng {time}'**
  String qSummary(int done, int total, String time);

  /// 10i summary.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} mục'**
  String qSummaryNoEta(int done, int total);

  /// 10i button.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get qPause;

  /// 10i button (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get qResume;

  /// 10i summary.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình sẽ được báo khi tải xong'**
  String get qNotice;

  /// 10i errors.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục lỗi'**
  String qFailed(int count);

  /// 10i errors.
  ///
  /// In vi, this message translates to:
  /// **'{count} tệp không đọc được'**
  String qUnreadable(int count);

  /// QueueRow uploading.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% · {sent}/{total}'**
  String rowProgress(int percent, String sent, String total);

  /// QueueRow.
  ///
  /// In vi, this message translates to:
  /// **'Chờ Wi-Fi · video {size}'**
  String rowWaitingWifi(String size);

  /// QueueRow.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối khi đang tải'**
  String get rowFailed;

  /// QueueRow.
  ///
  /// In vi, this message translates to:
  /// **'Tệp bị lỗi · không thử lại được'**
  String get rowUnreadable;

  /// QueueRow.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải lên'**
  String get rowDone;

  /// QueueRow (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get rowQueued;

  /// QueueRow (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get rowPaused;

  /// QueueRow (R-121).
  ///
  /// In vi, this message translates to:
  /// **'Hết dung lượng · giữ trên máy'**
  String get rowWaitingQuota;

  /// QueueRow (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ'**
  String get rowCancelled;

  /// QueueRow (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị'**
  String get rowPreparing;

  /// 10i toggle.
  ///
  /// In vi, this message translates to:
  /// **'Video chỉ tải qua Wi-Fi'**
  String get qWifiOnly;

  /// 10i toggle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vẫn tải bằng dữ liệu di động'**
  String get qWifiOnlyHint;

  /// 10i button.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại tất cả ({count})'**
  String qRetryAll(int count);

  /// 10i footnote.
  ///
  /// In vi, this message translates to:
  /// **'Mục lỗi được giữ trên máy · tự thử lại khi có mạng.'**
  String get qFootnote;

  /// 10i empty.
  ///
  /// In vi, this message translates to:
  /// **'Không còn gì đang tải.'**
  String get qEmpty;

  /// QueueRow ×.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ tải {name}'**
  String a11yCancelUpload(String name);

  /// Month header (10b).
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}, {year}'**
  String memMonth(int month, int year, String monthName);

  /// 10b chip.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get memFilterMonth;

  /// 10b chip.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get memSelect;

  /// 10b2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cả tháng'**
  String get memSelectMonth;

  /// 10b2 pill / 10b3 title.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục đã chọn'**
  String memSelected(int count);

  /// 10b2 pill.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ và tuỳ chọn'**
  String get a11yShareOptions;

  /// 10b2 pill.
  ///
  /// In vi, this message translates to:
  /// **'Xoá mục đã chọn'**
  String get a11yDeleteSelected;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy'**
  String get actWho;

  /// 10b3 (S10).
  ///
  /// In vi, this message translates to:
  /// **'Album'**
  String get actAlbum;

  /// 10b3 / 10f.
  ///
  /// In vi, this message translates to:
  /// **'Tải về'**
  String get actDownload;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đi'**
  String get actSend;

  /// 10b3 section.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get actMore;

  /// 10b3 (S10).
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào Yêu thích'**
  String get actFavorite;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Gom vào album Yêu thích của bạn'**
  String get actFavoriteHint;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Lần đầu cười'**
  String get actMilestoneHint;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngày'**
  String get actDate;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Khi ngày chụp bị sai'**
  String get actDateHint;

  /// Selection action: a card from the chosen photos.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thiệp cột mốc'**
  String get actMakeCard;

  /// Selection action hint.
  ///
  /// In vi, this message translates to:
  /// **'Dùng tối đa 4 ảnh đã chọn'**
  String get actMakeCardHint;

  /// Selection action: a video from the chosen photos.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video kỷ niệm'**
  String get actMakeVideo;

  /// Selection action hint.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đã chọn vào sẵn các cảnh'**
  String get actMakeVideoHint;

  /// 10b3 (S12).
  ///
  /// In vi, this message translates to:
  /// **'Kể thành câu chuyện'**
  String get actStory;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {count} mục này làm bản nháp'**
  String actStoryHint(int count);

  /// 10b3 (S10).
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm ảnh bìa album'**
  String get actCover;

  /// 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dùng khi chọn 1 ảnh'**
  String get actCoverHint;

  /// 10b3 rows of later slices.
  ///
  /// In vi, this message translates to:
  /// **'Sắp có'**
  String get actSoon;

  /// Audience sheet from 10b3 (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy {count} mục này?'**
  String whoItemsTitle(int count);

  /// Download toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {count} mục vào Ảnh'**
  String toastSaved(int count);

  /// Download toast.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu vào Ảnh…'**
  String get toastSaving;

  /// Download failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được vào Ảnh. Thử lại nhé.'**
  String get toastSaveFailed;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ngày {count} mục'**
  String toastDateChanged(int count);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gắn mốc cho {count} mục'**
  String toastTagged(int count);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển {count} mục sang Chỉ ba mẹ'**
  String toastParentsOnly(int count);

  /// Toast (10o).
  ///
  /// In vi, this message translates to:
  /// **'Đã chia sẻ {count} mục với gia đình'**
  String toastShared(int count);

  /// Toast (10b4) with undo.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {count} mục'**
  String toastDeleted(int count);

  /// Batch action failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa làm được. Kiểm tra mạng và thử lại.'**
  String get toastActionFailed;

  /// 10b4 title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {count} mục?'**
  String delTitle(int count);

  /// 10b4.
  ///
  /// In vi, this message translates to:
  /// **'Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình. Ảnh gốc trên máy bạn vẫn còn.'**
  String get delBody;

  /// 10b4.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục được trong 30 ngày ở “Đã xoá gần đây”.'**
  String get delRecover;

  /// 10b4.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ mới xoá được.'**
  String get delParentsOnly;

  /// 10b4 button.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {count} mục'**
  String delN(int count);

  /// 10b5 title.
  ///
  /// In vi, this message translates to:
  /// **'Đi tới tháng'**
  String get gotoTitle;

  /// 10b5 cell.
  ///
  /// In vi, this message translates to:
  /// **'Th {month}'**
  String gotoMonthShort(int month, String monthName);

  /// 10b5 footnote.
  ///
  /// In vi, this message translates to:
  /// **'{name} sinh ngày {date} · năm khác sẽ hiện khi có ảnh'**
  String gotoNote(String name, String date);

  /// Date scrubber.
  ///
  /// In vi, this message translates to:
  /// **'Th {month}, {year}'**
  String scrubberMonth(int month, int year, String monthName);

  /// 10c title.
  ///
  /// In vi, this message translates to:
  /// **'Cách xem'**
  String get viewTitle;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm theo'**
  String get viewGroup;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get viewDay;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get viewWeek;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get viewMonth;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu xem'**
  String get viewLayout;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Lưới nhỏ'**
  String get viewSmall;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Lưới lớn'**
  String get viewLarge;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách'**
  String get viewList;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Hiện'**
  String get viewShow;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Có mốc'**
  String get viewWithMilestone;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Xem như người thân'**
  String get viewAsRelative;

  /// 10c.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra người thân đang thấy những gì'**
  String get viewAsRelativeHint;

  /// 10c primary.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get viewApply;

  /// Preview banner (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đang xem như người thân'**
  String get viewAsRelativeBanner;

  /// Preview banner.
  ///
  /// In vi, this message translates to:
  /// **'Thoát'**
  String get viewAsRelativeExit;

  /// Day/month group header.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {counts}'**
  String dayGroup(String date, String counts);

  /// 10f meta.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {who} đăng'**
  String viewerPosted(String date, String who);

  /// 10f action.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get viewerShare;

  /// 10f video.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải video…'**
  String get viewerVideoLoading;

  /// 10f video.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được video.'**
  String get viewerVideoFailed;

  /// 10f video.
  ///
  /// In vi, this message translates to:
  /// **'Phát video'**
  String get a11yPlay;

  /// 10f video.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng video'**
  String get a11yPause;

  /// 10f video scrubber (accessibility).
  ///
  /// In vi, this message translates to:
  /// **'Vị trí video'**
  String get viewerSeek;

  /// 10f tap hint on the photo or video (accessibility).
  ///
  /// In vi, this message translates to:
  /// **'hiện hoặc ẩn điều khiển'**
  String get viewerToggleChrome;

  /// 10f thumbnail strip: one thumbnail (accessibility).
  ///
  /// In vi, this message translates to:
  /// **'Mục {index} trên {count}'**
  String viewerThumb(int index, int count);

  /// 10o title.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ với gia đình?'**
  String get shareTitle;

  /// 10o items.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh riêng tư'**
  String sharePrivatePhotos(int count);

  /// 10o items with videos.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục riêng tư'**
  String sharePrivateItems(int count);

  /// 10o section.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ thấy sau khi chia sẻ'**
  String get shareWillSee;

  /// 10o row.
  ///
  /// In vi, this message translates to:
  /// **'{count} người thân'**
  String shareRelatives(int count);

  /// 10o note.
  ///
  /// In vi, this message translates to:
  /// **'Người chăm ({names}) không thấy Kỷ niệm.'**
  String shareCaregivers(String names);

  /// 10o toggle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi 1 thông báo chung, không kèm ảnh'**
  String get shareNotifyHint;

  /// 10o primary.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ {count} mục'**
  String shareN(int count);

  /// 10o primary.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ {count} ảnh'**
  String shareNPhotos(int count);

  /// 10a3 chip.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Kỷ niệm của {name}'**
  String camDest(String name);

  /// 10a3.
  ///
  /// In vi, this message translates to:
  /// **'Flash'**
  String get camFlash;

  /// 10a3 mode.
  ///
  /// In vi, this message translates to:
  /// **'VIDEO'**
  String get camVideo;

  /// 10a3 mode.
  ///
  /// In vi, this message translates to:
  /// **'ẢNH'**
  String get camPhoto;

  /// 10a3.
  ///
  /// In vi, this message translates to:
  /// **'Xong ({count})'**
  String camDone(int count);

  /// 10a3.
  ///
  /// In vi, this message translates to:
  /// **'Chụp liên tục · bấm Xong để soạn & chia sẻ'**
  String get camHint;

  /// 10a3 error.
  ///
  /// In vi, this message translates to:
  /// **'Máy này chưa mở được camera.'**
  String get camUnavailable;

  /// 10a3.
  ///
  /// In vi, this message translates to:
  /// **'Chụp'**
  String get a11yShutter;

  /// 10d bar.
  ///
  /// In vi, this message translates to:
  /// **'{count} album'**
  String albCount(int count);

  /// 10d button / new-album sheet.
  ///
  /// In vi, this message translates to:
  /// **'Album mới'**
  String get albNew;

  /// Automatic album (10e2).
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích'**
  String get albFavorites;

  /// 11e card.
  ///
  /// In vi, this message translates to:
  /// **'của riêng bạn'**
  String get albFavoritesMine;

  /// 10e2 pill.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn'**
  String get albOnlyYou;

  /// 10e2 subtitle.
  ///
  /// In vi, this message translates to:
  /// **'ảnh bạn đã đánh dấu'**
  String get albFavoritesHint;

  /// 10d section.
  ///
  /// In vi, this message translates to:
  /// **'Gom từ mốc bạn đã gắn'**
  String get albFromMilestones;

  /// 11e section for relatives (gap note).
  ///
  /// In vi, this message translates to:
  /// **'Gom theo mốc'**
  String get albByMilestone;

  /// 11e subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} album ba mẹ chia sẻ'**
  String albShared(int count);

  /// 10d empty (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có album nào'**
  String get albEmpty;

  /// 10d empty.
  ///
  /// In vi, this message translates to:
  /// **'Tạo album để gom ảnh theo chủ đề, như Giờ tắm hay Bàn tay nhỏ.'**
  String get albEmptyBody;

  /// 10e hero.
  ///
  /// In vi, this message translates to:
  /// **'{counts} · cập nhật {when}'**
  String albUpdated(String counts, String when);

  /// 10e bar.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get albAddPhotos;

  /// 10e bar (S12).
  ///
  /// In vi, this message translates to:
  /// **'Kể thành chuyện'**
  String get albStory;

  /// 11f chip.
  ///
  /// In vi, this message translates to:
  /// **'{who} chia sẻ với gia đình'**
  String albSharedBy(String who);

  /// 10e empty.
  ///
  /// In vi, this message translates to:
  /// **'Album này chưa có ảnh nào.'**
  String get albNoItems;

  /// Albums tab: under an empty album's name, instead of "0 ảnh" (owner, 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get albCoverEmptyMeta;

  /// Albums tab: on an empty album's cover, for parents.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get albCoverAdd;

  /// 10e bar / 10e3 / 10e6.
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy album này'**
  String get albWhoButton;

  /// 10e3 / 10e4.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên album'**
  String get albRename;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh bìa'**
  String get albCover;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người thân trong gia đình'**
  String get albWhoFamilyHint;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get albSelect;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi album, đổi ai thấy…'**
  String get albSelectHint;

  /// 10e3 / 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp'**
  String get albSort;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Tải cả album về máy'**
  String get albDownload;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'{counts} · khoảng {size}'**
  String albDownloadHint(String counts, String size);

  /// 10e3 / 10e10.
  ///
  /// In vi, this message translates to:
  /// **'Xoá album'**
  String get albDelete;

  /// 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm'**
  String get albDeleteHint;

  /// 10e4 field.
  ///
  /// In vi, this message translates to:
  /// **'Tên album'**
  String get albName;

  /// 10e4.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get albSuggestions;

  /// 10e4 chip.
  ///
  /// In vi, this message translates to:
  /// **'Giờ tắm'**
  String get albSuggestBath;

  /// 10e4 chip.
  ///
  /// In vi, this message translates to:
  /// **'Tắm nắng'**
  String get albSuggestSun;

  /// 10e4 chip.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu đi bơi'**
  String get albSuggestSwim;

  /// New album chip.
  ///
  /// In vi, this message translates to:
  /// **'Bàn tay nhỏ'**
  String get albSuggestHands;

  /// New album chip.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ ngoan'**
  String get albSuggestSleep;

  /// 10e4.
  ///
  /// In vi, this message translates to:
  /// **'Lưu tên'**
  String get albSaveName;

  /// Validation.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho album.'**
  String get albNameRequired;

  /// New album primary (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Tạo album'**
  String get albCreate;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo album “{name}”'**
  String albCreated(String name);

  /// 10e5 title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh bìa'**
  String get albCoverTitle;

  /// 10e5 / 10b3.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm ảnh bìa'**
  String get albSetCover;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ảnh bìa'**
  String get albCoverSet;

  /// 10e6 note.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng cho cả {count} mục trong album'**
  String albAppliesTo(int count);

  /// 10e6 note.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh thêm sau này cũng theo quyền của album. Người chăm không thấy Kỷ niệm.'**
  String get albLaterFollow;

  /// 10e6 toggle.
  ///
  /// In vi, this message translates to:
  /// **'1 thông báo chung, không kèm ảnh'**
  String get albNoticeHint;

  /// Toast after Chỉ ba mẹ (D-002).
  ///
  /// In vi, this message translates to:
  /// **'{count} mục vẫn được gia đình thấy vì còn nằm trong album Gia đình khác.'**
  String albStayShared(int count);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ai thấy album'**
  String get albAudienceSaved;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất'**
  String get sortNewest;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chụp gần đây ở trên'**
  String get sortNewestHint;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Cũ nhất'**
  String get sortOldest;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại từ đầu, hợp để xem lại'**
  String get sortOldestHint;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Mới thêm vào album'**
  String get sortAdded;

  /// 10e7.
  ///
  /// In vi, this message translates to:
  /// **'Theo lúc bạn thêm ảnh'**
  String get sortAddedHint;

  /// 10e8 bar.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi album'**
  String get albRemove;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ {count} mục khỏi album'**
  String albRemoved(int count);

  /// 10e9 title.
  ///
  /// In vi, this message translates to:
  /// **'Tải về máy'**
  String get dlTitle;

  /// 10e9.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục · khoảng {size}'**
  String dlSummary(int count, String size);

  /// 10e9.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào album “{name}” trong app Ảnh'**
  String dlInto(String name);

  /// 10e9 toggle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ tải qua Wi-Fi'**
  String get dlWifi;

  /// 10e9.
  ///
  /// In vi, this message translates to:
  /// **'Video lớn sẽ đợi Wi-Fi'**
  String get dlWifiHint;

  /// 10e9 primary.
  ///
  /// In vi, this message translates to:
  /// **'Tải {count} mục'**
  String dlN(int count);

  /// 10e9.
  ///
  /// In vi, this message translates to:
  /// **'Tải ở nền — xong sẽ báo bạn.'**
  String get dlFootnote;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ Wi-Fi để tải video.'**
  String get dlNeedsWifi;

  /// 10e10 title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá album “{name}”?'**
  String albDeleteTitle(String name);

  /// 10e10.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.'**
  String albDeleteBody(int count);

  /// 10e10.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình sẽ không thấy album này nữa.'**
  String get albDeleteFamily;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá album'**
  String get albDeleted;

  /// 10h5 title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào album'**
  String get albPickTitle;

  /// 10h5 row.
  ///
  /// In vi, this message translates to:
  /// **'Tạo album mới'**
  String get albPickNew;

  /// 10h5 helper.
  ///
  /// In vi, this message translates to:
  /// **'Có thể chọn nhiều album. Ảnh vẫn theo quyền “Ai thấy” bạn đã chọn.'**
  String get albPickHint;

  /// 10h value.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get albPickNone;

  /// 10h value, several albums.
  ///
  /// In vi, this message translates to:
  /// **'{first} +{count}'**
  String albPickMore(String first, int count);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm {count} mục vào “{name}”'**
  String albAdded(int count, String name);

  /// 10h hint (D-002).
  ///
  /// In vi, this message translates to:
  /// **'Album Gia đình: “Ai thấy” chuyển sang Gia đình.'**
  String get albFamilySwitched;

  /// Add photos to album.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ Kỷ niệm'**
  String get albPickFromMemories;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào Yêu thích'**
  String get favAdded;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ khỏi Yêu thích'**
  String get favRemoved;

  /// Action.
  ///
  /// In vi, this message translates to:
  /// **'Thương'**
  String get love;

  /// Entry loves (parents).
  ///
  /// In vi, this message translates to:
  /// **'{names} thương'**
  String lovesNamed(String names);

  /// Entry loves.
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt thương'**
  String lovesCount(int count);

  /// 11g pill.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn'**
  String get messageAction;

  /// 11c action / composer title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn ba mẹ'**
  String get messageParents;

  /// 11i field.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn ba mẹ…'**
  String get messagePlaceholder;

  /// Composer title for a caregiver (12e).
  ///
  /// In vi, this message translates to:
  /// **'Nhắn {who}'**
  String messageTo(String who);

  /// Composer.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get messageSend;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời nhắn'**
  String get messageSent;

  /// Composer (D-034).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ đọc được. Đây không phải trò chuyện.'**
  String get messageHint;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được. Kiểm tra mạng và thử lại.'**
  String get messageFailed;

  /// Parents list (D-034).
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn'**
  String get messagesTitle;

  /// Parents list empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lời nhắn nào.'**
  String get messagesEmpty;

  /// Me row.
  ///
  /// In vi, this message translates to:
  /// **'{count} chưa đọc'**
  String messagesUnread(int count);

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về một ảnh'**
  String get messagesAboutPhoto;

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về một kỷ niệm'**
  String get messagesAboutMemory;

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về album “{name}”'**
  String messagesAboutAlbum(String name);

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về một album'**
  String get messagesAboutAlbumGeneric;

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về một câu chuyện'**
  String get messagesAboutStory;

  /// Context.
  ///
  /// In vi, this message translates to:
  /// **'về một ghi chép chăm sóc'**
  String get messagesAboutRecord;

  /// Viewer thread (parents).
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn ({count})'**
  String messagesOnItem(int count);

  /// Message meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} · {when}'**
  String messageFrom(String who, String when);

  /// 11c subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những gì ba mẹ chia sẻ với gia đình'**
  String get relSubtitle;

  /// 11h.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kỷ niệm nào được chia sẻ'**
  String get relEmptyTitle;

  /// 11h.
  ///
  /// In vi, this message translates to:
  /// **'Khi ba mẹ chia sẻ ảnh với gia đình, bạn sẽ nhận một thông báo và thấy ở đây.'**
  String get relEmptyBody;

  /// 11g meta.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {who} chia sẻ'**
  String viewerShared(String date, String who);

  /// 10f meta with album.
  ///
  /// In vi, this message translates to:
  /// **'{meta} · album {name}'**
  String viewerInAlbum(String meta, String name);

  /// 10e ••• button (a11y) / 10e3.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn album'**
  String get albOptions;

  /// 13a role line.
  ///
  /// In vi, this message translates to:
  /// **'{relation} · chủ hồ sơ của {names}'**
  String meRoleOwner(String relation, String names);

  /// 13a for a co-parent who is not the owner (eng).
  ///
  /// In vi, this message translates to:
  /// **'{relation} · cùng nuôi {names}'**
  String meRoleParent(String relation, String names);

  /// 13g role line.
  ///
  /// In vi, this message translates to:
  /// **'{relation} · chăm {names}'**
  String meRoleCaregiver(String relation, String names);

  /// 13h role line.
  ///
  /// In vi, this message translates to:
  /// **'{relation} · người thân của {names}'**
  String meRoleRelative(String relation, String names);

  /// 13a card / 13b title.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng'**
  String get meStorage;

  /// 13a card value.
  ///
  /// In vi, this message translates to:
  /// **'{used} / {quota}'**
  String meStorageOf(String used, String quota);

  /// 13a footnote.
  ///
  /// In vi, this message translates to:
  /// **'Dùng chung cho tất cả các bé của bạn'**
  String get meStorageShared;

  /// 13a row / 13i title.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ các bé'**
  String get meBabies;

  /// 13g row.
  ///
  /// In vi, this message translates to:
  /// **'Bé được giao'**
  String get meAssigned;

  /// 13h row.
  ///
  /// In vi, this message translates to:
  /// **'Các bé bạn theo dõi'**
  String get meFollowing;

  /// 13a row / G-056 title.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get meNotifications;

  /// Row value.
  ///
  /// In vi, this message translates to:
  /// **'Bật'**
  String get meOn;

  /// Row value when some kinds are off.
  ///
  /// In vi, this message translates to:
  /// **'Một số'**
  String get meSome;

  /// Row value.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get meOff;

  /// 13a row.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản & đăng nhập'**
  String get meAccount;

  /// 13a row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Email, Apple, đổi máy'**
  String get meAccountHint;

  /// 13a row / help title.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp & liên hệ'**
  String get meHelp;

  /// Sign-out confirmation (gap, eng).
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi máy này?'**
  String get meSignOutTitle;

  /// Sign-out confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ghi chép và kỷ niệm đã lưu trên tài khoản của bạn.'**
  String get meSignOutBody;

  /// Sign-out with a pending upload queue (gap).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 mục đang chờ tải lên sẽ không được tải nếu bạn đăng xuất bây giờ.} other{{count} mục đang chờ tải lên sẽ không được tải nếu bạn đăng xuất bây giờ.}}'**
  String meSignOutPending(int count);

  /// Toast after remote sign-out.
  ///
  /// In vi, this message translates to:
  /// **'Máy này đã được đăng xuất từ một thiết bị khác.'**
  String get meSignedOutRemote;

  /// 13b big number suffix.
  ///
  /// In vi, this message translates to:
  /// **'/ {quota}'**
  String stOfQuota(String quota);

  /// 13b helper.
  ///
  /// In vi, this message translates to:
  /// **'Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây'**
  String get stFootnote;

  /// 13c banner.
  ///
  /// In vi, this message translates to:
  /// **'Sắp đầy · {percent}%'**
  String stNearTitle(int percent);

  /// 13c banner.
  ///
  /// In vi, this message translates to:
  /// **'Video chiếm nhiều chỗ nhất. Xoá bớt video dài hoặc liên hệ quản trị để mở rộng.'**
  String get stNearBody;

  /// 13d banner.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng hết {quota}'**
  String stFullTitle(String quota);

  /// 13d banner.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{Tạm dừng tải ảnh, video. 1 mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường.} other{Tạm dừng tải ảnh, video. {count} mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường.}}'**
  String stFullBody(int count);

  /// 13d banner without held items.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng tải ảnh, video. Ghi chép chăm sóc vẫn lưu bình thường.'**
  String get stFullBodyNone;

  /// 13b section.
  ///
  /// In vi, this message translates to:
  /// **'Theo bé'**
  String get stByBaby;

  /// 13b baby row.
  ///
  /// In vi, this message translates to:
  /// **'{photos} ảnh · {videos} video'**
  String stCounts(int photos, int videos);

  /// 13b section.
  ///
  /// In vi, this message translates to:
  /// **'Theo loại'**
  String get stByType;

  /// 13b type row.
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get stVideo;

  /// 13b type row.
  ///
  /// In vi, this message translates to:
  /// **'Xem video lớn nhất'**
  String get stVideoHint;

  /// 13b type row.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get stPhotos;

  /// 13b type row.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện & ghi chú'**
  String get stNotes;

  /// 13b row (G-041).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá gần đây'**
  String get stBin;

  /// 13b row (G-041).
  ///
  /// In vi, this message translates to:
  /// **'Còn tính đến khi xoá hẳn sau 30 ngày'**
  String get stBinHint;

  /// 13b card.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm dung lượng?'**
  String get stNeedMore;

  /// 13b card.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi gia đình có {quota}. Liên hệ quản trị Child Life để mở rộng.'**
  String stNeedMoreBody(String quota);

  /// 13b button.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ quản trị'**
  String get stContact;

  /// 13b after 13e (gap).
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu +{amount} GB · {date}'**
  String stRequested(int amount, String date);

  /// 13b after 13e.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị Child Life sẽ trả lời qua email.'**
  String get stRequestedHint;

  /// 13e title.
  ///
  /// In vi, this message translates to:
  /// **'Xin thêm dung lượng'**
  String get stReqTitle;

  /// 13e label.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm bao nhiêu?'**
  String get stReqHow;

  /// 13e field.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn (không bắt buộc)'**
  String get stReqMessage;

  /// 13e info.
  ///
  /// In vi, this message translates to:
  /// **'Gửi kèm: {email} · đang dùng {used} / {quota}'**
  String stReqAttach(String email, String used, String quota);

  /// 13e button.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu'**
  String get stReqSend;

  /// 13e footnote.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị Child Life sẽ trả lời qua email, thường trong 1–2 ngày làm việc.'**
  String get stReqFootnote;

  /// 13e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu'**
  String get stReqSent;

  /// 13e / help without an email.
  ///
  /// In vi, this message translates to:
  /// **'Lưu tài khoản bằng email để gửi yêu cầu.'**
  String get needEmailAccount;

  /// G-058 title.
  ///
  /// In vi, this message translates to:
  /// **'Video lớn nhất'**
  String get stVideosTitle;

  /// G-058 hint.
  ///
  /// In vi, this message translates to:
  /// **'Mở video để xem, tải về hoặc xoá.'**
  String get stVideosHint;

  /// G-058 empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có video nào.'**
  String get stVideosEmpty;

  /// 13b error (G-001).
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dung lượng. Kéo xuống để thử lại.'**
  String get stLoadFailed;

  /// 13i row.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{{age} · 1 người cùng chăm} other{{age} · {count} người cùng chăm}}'**
  String bpCarers(String age, int count);

  /// 13i tile.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bé'**
  String get bpAdd;

  /// 13i row while purging.
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá…'**
  String get bpDeleting;

  /// 13j head.
  ///
  /// In vi, this message translates to:
  /// **'{age} · sinh ngày {date}'**
  String bpBorn(String age, String date);

  /// 13j card.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng · {when}'**
  String bpWeight(String when);

  /// 13j card.
  ///
  /// In vi, this message translates to:
  /// **'Chiều cao · {when}'**
  String bpLength(String when);

  /// 13j section.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get bpInfo;

  /// 13j section.
  ///
  /// In vi, this message translates to:
  /// **'Của bé'**
  String get bpOf;

  /// 13j row.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình của {name}'**
  String bpFamily(String name);

  /// 13j row.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ cân nặng, chiều cao'**
  String get bpGrowthHint;

  /// 13j row.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng của {name}'**
  String bpStorage(String name);

  /// 13j row.
  ///
  /// In vi, this message translates to:
  /// **'Tính vào {quota} của bạn'**
  String bpStorageHint(String quota);

  /// 13j card.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hồ sơ {name}'**
  String bpDelete(String name);

  /// 13j card.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hồ sơ ({owner}) làm được'**
  String bpDeleteOwner(String owner);

  /// 13k button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get bpSave;

  /// 13k note.
  ///
  /// In vi, this message translates to:
  /// **'Người thân chỉ thấy tên thân mật'**
  String get bpPrivacy;

  /// 13k gender label.
  ///
  /// In vi, this message translates to:
  /// **'· không bắt buộc'**
  String get bpOptional;

  /// 13k toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu hồ sơ'**
  String get bpSaved;

  /// 13l title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hồ sơ {name}?'**
  String bpDelTitle(String name);

  /// 13l body.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ghi chép chăm sóc, ảnh, video và câu chuyện của {name} sẽ bị xoá với cả gia đình. Không khôi phục được.'**
  String bpDelBody(String name);

  /// 13l info.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{Giải phóng {size} · 1 người mất quyền xem} other{Giải phóng {size} · {count} người mất quyền xem}}'**
  String bpDelFree(String size, int count);

  /// 13l info.
  ///
  /// In vi, this message translates to:
  /// **'Nên tải ảnh về máy trước khi xoá.'**
  String get bpDelTip;

  /// 13l prompt.
  ///
  /// In vi, this message translates to:
  /// **'Gõ “{name}” để xác nhận'**
  String bpDelType(String name);

  /// 13l button.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn'**
  String get bpDelConfirm;

  /// Toast after 13l.
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá hồ sơ {name}…'**
  String bpDelStarted(String name);

  /// Toast when the purge is verified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá hồ sơ {name}'**
  String bpDelDone(String name);

  /// 13i row when a step failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xoá xong, đang tự thử lại.'**
  String get bpDelRetrying;

  /// Banner for members (Q-037).
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ này đang được xoá. Không thể thêm ghi chép mới.'**
  String get bpLocked;

  /// 13m title.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ của bạn'**
  String get pfTitle;

  /// 13m field.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get pfName;

  /// 13m section.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là ai với bé'**
  String get pfWho;

  /// 13m footnote.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình thấy tên và vai trò này khi bạn ghi chép hay chia sẻ.'**
  String get pfFootnote;

  /// 13m role picker (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Bạn là gì của {name}?'**
  String pfRelationTitle(String name);

  /// 13m toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get pfSaved;

  /// 13n title.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get acTitle;

  /// 13n section.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get acSignIn;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'{email} · đã xác minh'**
  String acEmailVerified(String email);

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'{email} · chưa xác minh'**
  String acEmailUnverified(String email);

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Đã liên kết'**
  String get acLinked;

  /// 13n action.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ'**
  String get acUnlink;

  /// 13n guard.
  ///
  /// In vi, this message translates to:
  /// **'Cần giữ ít nhất một cách đăng nhập.'**
  String get acUnlinkLast;

  /// 13n toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gỡ {provider}'**
  String acUnlinked(String provider);

  /// 13n row (G-059).
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get acPassword;

  /// 13n toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email đổi mật khẩu tới {email}'**
  String acPasswordSent(String email);

  /// 13n section.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang đăng nhập'**
  String get acDevices;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Máy này'**
  String get acThisDevice;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {when}'**
  String acActive(String when);

  /// 13n toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất {name}'**
  String acDeviceSignedOut(String name);

  /// 13n section (Q-016).
  ///
  /// In vi, this message translates to:
  /// **'Chủ hồ sơ'**
  String get acOwner;

  /// 13n row (Q-016).
  ///
  /// In vi, this message translates to:
  /// **'Chuyển chủ hồ sơ'**
  String get acTransfer;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Cho một người Cùng nuôi của {names}'**
  String acTransferHint(String names);

  /// Transfer sheet.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận trở thành chủ hồ sơ của {names}: xoá hồ sơ, chuyển tiếp và dung lượng gia đình. Họ cần đồng ý.'**
  String acTransferBody(String names);

  /// Transfer sheet empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai Cùng nuôi tất cả các bé.'**
  String get acTransferNone;

  /// Transfer sheet button.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề nghị'**
  String get acTransferSend;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ {name} đồng ý'**
  String acTransferPending(String name);

  /// 13n action.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đề nghị'**
  String get acTransferCancel;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi đề nghị cho {name}'**
  String acTransferSent(String name);

  /// Offer card.
  ///
  /// In vi, this message translates to:
  /// **'{name} muốn chuyển quyền chủ hồ sơ cho bạn'**
  String acOfferTitle(String name);

  /// Offer card.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ là chủ hồ sơ của {names} và quản lý dung lượng gia đình.'**
  String acOfferBody(String names);

  /// Offer card.
  ///
  /// In vi, this message translates to:
  /// **'Nhận'**
  String get acOfferAccept;

  /// Offer card.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get acOfferDecline;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã là chủ hồ sơ'**
  String get acOfferAccepted;

  /// Transfer error.
  ///
  /// In vi, this message translates to:
  /// **'Người này đang là chủ hồ sơ khác.'**
  String get acReceiverOwns;

  /// A17 (P-136): card title when Child Life Support asks the owner to transfer ownership.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ'**
  String get acStaffTransferTitle;

  /// A17 card body without a ticket. to = masked email, time = deadline.
  ///
  /// In vi, this message translates to:
  /// **'Cho {to}. Bạn đồng ý trong 48 giờ (đến {time}); nếu không, đề nghị tự huỷ. Đồng ý thì {to} sẽ nhận lời mời làm chủ hồ sơ như bình thường.'**
  String acStaffTransferBody(String to, String time);

  /// A17 card body with the support ticket code (CL-1042).
  ///
  /// In vi, this message translates to:
  /// **'Cho {to} · mã {ticket}. Bạn đồng ý trong 48 giờ (đến {time}); nếu không, đề nghị tự huỷ. Đồng ý thì {to} sẽ nhận lời mời làm chủ hồ sơ như bình thường.'**
  String acStaffTransferBodyTicket(String to, String ticket, String time);

  /// A17 card and confirmation button.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get acStaffTransferAgree;

  /// A17 card button.
  ///
  /// In vi, this message translates to:
  /// **'Không đồng ý'**
  String get acStaffTransferDecline;

  /// A17 confirmation sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý chuyển quyền chủ hồ sơ?'**
  String get acStaffTransferConfirmTitle;

  /// A17 confirmation sheet body.
  ///
  /// In vi, this message translates to:
  /// **'{to} sẽ nhận lời mời làm chủ hồ sơ. Quyền chỉ chuyển khi họ nhận lời; trước đó bạn vẫn có thể huỷ đề nghị ở mục Chủ hồ sơ.'**
  String acStaffTransferConfirmBody(String to);

  /// Toast after agreeing.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng ý · {to} sẽ nhận lời mời'**
  String acStaffTransferAgreed(String to);

  /// Toast after declining.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối đề nghị chuyển quyền'**
  String get acStaffTransferDeclined;

  /// Toast when the request is no longer pending.
  ///
  /// In vi, this message translates to:
  /// **'Đề nghị này đã hết hạn hoặc đã được trả lời.'**
  String get acStaffTransferGone;

  /// 13n row (G-072).
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get acExport;

  /// 13n row.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép chăm sóc, ảnh và video'**
  String get acExportHint;

  /// Export sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu của {name}'**
  String acExportTitle(String name);

  /// Export option.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép chăm sóc'**
  String get acExportCare;

  /// Export option.
  ///
  /// In vi, this message translates to:
  /// **'CSV và JSON'**
  String get acExportCareHint;

  /// Export option.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và video'**
  String get acExportMedia;

  /// Export option.
  ///
  /// In vi, this message translates to:
  /// **'ZIP · chỉ chủ hồ sơ'**
  String get acExportMediaHint;

  /// Export button.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu xuất'**
  String get acExportStart;

  /// Export sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi gửi email khi tệp sẵn sàng. Liên kết tải hết hạn sau 24 giờ.'**
  String get acExportFootnote;

  /// Export row.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị…'**
  String get acExportQueued;

  /// Export row.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng · hết hạn {when}'**
  String acExportReady(String when);

  /// Export row.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn'**
  String get acExportExpired;

  /// Export row.
  ///
  /// In vi, this message translates to:
  /// **'Không xuất được'**
  String get acExportFailed;

  /// Export error.
  ///
  /// In vi, this message translates to:
  /// **'Một tệp xuất khác đang chạy.'**
  String get acExportRunning;

  /// 13n card.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get acDelete;

  /// 13n card (R-046).
  ///
  /// In vi, this message translates to:
  /// **'Cần chuyển chủ hồ sơ của {names} trước'**
  String acDeleteBlocked(String names);

  /// 13n card.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tên, email và thiết bị của bạn'**
  String get acDeleteHint;

  /// Confirmation (Q-016).
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản?'**
  String get acDeleteTitle;

  /// Confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Tên, email và thiết bị của bạn sẽ bị xoá. Ghi chép và kỷ niệm bạn đã chia sẻ ở lại với gia đình, ghi là “Người dùng đã xoá”. Không khôi phục được.'**
  String get acDeleteBody;

  /// Progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá tài khoản…'**
  String get acDeleting;

  /// Author of content from a deleted account (Q-016).
  ///
  /// In vi, this message translates to:
  /// **'Người dùng đã xoá'**
  String get deletedUser;

  /// Toggle.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm mới'**
  String get ntMemories;

  /// Toggle hint.
  ///
  /// In vi, this message translates to:
  /// **'Khi ba mẹ chia sẻ ảnh, album, câu chuyện'**
  String get ntMemoriesHint;

  /// Toggle (parents).
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn'**
  String get ntMessages;

  /// Toggle hint.
  ///
  /// In vi, this message translates to:
  /// **'Khi có người nhắn ba mẹ'**
  String get ntMessagesHint;

  /// Toggle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc'**
  String get ntReminders;

  /// Toggle hint.
  ///
  /// In vi, this message translates to:
  /// **'Trên máy được chọn cho từng nhắc việc'**
  String get ntRemindersHint;

  /// Toggle (parents).
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng'**
  String get ntStorage;

  /// Toggle hint.
  ///
  /// In vi, this message translates to:
  /// **'Khi gần đầy hoặc đã đầy'**
  String get ntStorageHint;

  /// Footnote (R-120).
  ///
  /// In vi, this message translates to:
  /// **'Thông báo không bao giờ kèm ảnh hay tên bé.'**
  String get ntFootnote;

  /// Help form.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề'**
  String get hpTopic;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm & media'**
  String get hpCatMemories;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình & vai trò'**
  String get hpCatFamily;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời'**
  String get hpCatInvites;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ'**
  String get hpCatSync;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get hpCatAccount;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng'**
  String get hpCatStorage;

  /// Help topic.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện'**
  String get hpCatStories;

  /// Help field.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần giúp gì?'**
  String get hpMessage;

  /// Help consent.
  ///
  /// In vi, this message translates to:
  /// **'Gửi kèm thông tin chẩn đoán'**
  String get hpDiagnostics;

  /// Help consent.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản app, loại máy, tình trạng đồng bộ. Không kèm ảnh hay ghi chép.'**
  String get hpDiagnosticsHint;

  /// Help footnote.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi trả lời qua email {email}.'**
  String hpFootnote(String email);

  /// Help toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi · mã {ticket}'**
  String hpSent(String ticket);

  /// 14a card tag.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý tuần này'**
  String get srySuggestTag;

  /// 14a card.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{Từ 1 ảnh · bạn sửa trước khi lưu} other{Từ {count} ảnh · bạn sửa trước khi lưu}}'**
  String srySuggestSub(int count);

  /// 14a card CTA.
  ///
  /// In vi, this message translates to:
  /// **'Xem bản nháp'**
  String get srySuggestCta;

  /// 14a filter.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp · {count}'**
  String sryDrafts(int count);

  /// 14a filter.
  ///
  /// In vi, this message translates to:
  /// **'Đã chia sẻ'**
  String get sryShared;

  /// 14a meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} kể · {when}'**
  String sryToldBy(String who, String when);

  /// 14a letter meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} viết · sửa lần cuối {when}'**
  String sryWroteBy(String who, String when);

  /// 14a badge / 14b title.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp'**
  String get sryDraft;

  /// 14a AI draft row.
  ///
  /// In vi, this message translates to:
  /// **'Nháp từ gợi ý · chưa lưu'**
  String get sryFromSuggestion;

  /// 14a FAB.
  ///
  /// In vi, this message translates to:
  /// **'Viết'**
  String get sryWrite;

  /// 14a empty (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có câu chuyện nào'**
  String get sryEmptyTitle;

  /// 14a empty.
  ///
  /// In vi, this message translates to:
  /// **'Viết lại một khoảnh khắc, hoặc chờ gợi ý cuối tuần từ những gì bạn đã ghi.'**
  String get sryEmptyBody;

  /// 11 empty.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ chưa chia sẻ câu chuyện nào.'**
  String get sryRelEmpty;

  /// New-story sheet (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Viết gì?'**
  String get sryNewTitle;

  /// New-story sheet.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện'**
  String get sryKindStory;

  /// New-story sheet.
  ///
  /// In vi, this message translates to:
  /// **'Kể một khoảnh khắc, có ảnh'**
  String get sryKindStoryHint;

  /// New-story sheet.
  ///
  /// In vi, this message translates to:
  /// **'Thư'**
  String get sryKindLetter;

  /// New-story sheet.
  ///
  /// In vi, this message translates to:
  /// **'Viết thư cho con đọc sau này'**
  String get sryKindLetterHint;

  /// 14b top bar.
  ///
  /// In vi, this message translates to:
  /// **'Lưu nháp'**
  String get srySaveDraft;

  /// 14b tip.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{AI viết nháp từ 1 ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.} other{AI viết nháp từ {count} ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.}}'**
  String sryAiTip(int count);

  /// 14b tip for a manual story.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.'**
  String get sryTip;

  /// 14b chip.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh bìa'**
  String get sryChangeCover;

  /// 14b chip without a cover.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh bìa'**
  String get sryAddCover;

  /// 14b title placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề'**
  String get sryTitleHint;

  /// Empty paragraph placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Viết vài dòng…'**
  String get sryParagraphHint;

  /// 14b meta.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 ảnh} other{{count} ảnh}}'**
  String sryMetaPhotos(int count);

  /// 14b meta.
  ///
  /// In vi, this message translates to:
  /// **'mốc {name}'**
  String sryMetaMilestone(String name);

  /// 14b toolbar / 14c AI bar.
  ///
  /// In vi, this message translates to:
  /// **'Viết lại'**
  String get sryRewrite;

  /// 14b toolbar / 14c AI bar.
  ///
  /// In vi, this message translates to:
  /// **'Ấm hơn'**
  String get sryWarmer;

  /// 14c AI bar.
  ///
  /// In vi, this message translates to:
  /// **'Ngắn hơn'**
  String get sryShorter;

  /// 14c AI bar.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get sryUndo;

  /// 14b add row.
  ///
  /// In vi, this message translates to:
  /// **'Thêm đoạn · ảnh · mốc'**
  String get sryAddBlock;

  /// Add sheet.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn văn'**
  String get sryAddParagraph;

  /// Add sheet.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get sryAddPhotos;

  /// Add sheet.
  ///
  /// In vi, this message translates to:
  /// **'Mốc'**
  String get sryAddMilestone;

  /// Add sheet.
  ///
  /// In vi, this message translates to:
  /// **'Câu trích'**
  String get sryAddQuote;

  /// 14b button / 14e title.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp'**
  String get sryArrange;

  /// 14b button.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước & lưu'**
  String get sryPreviewSave;

  /// Cancel with edits (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi?'**
  String get sryDiscardTitle;

  /// Cancel with edits.
  ///
  /// In vi, this message translates to:
  /// **'Những gì bạn vừa sửa chưa được lưu.'**
  String get sryDiscardBody;

  /// Cancel with edits.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get sryDiscard;

  /// Cancel with edits / 14f back.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tiếp'**
  String get sryKeepEditing;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nháp'**
  String get sryDraftSaved;

  /// Editor overflow (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ bản nháp'**
  String get sryDiscardDraft;

  /// 14c title.
  ///
  /// In vi, this message translates to:
  /// **'Sửa đoạn'**
  String get sryEditParagraph;

  /// 14c meta.
  ///
  /// In vi, this message translates to:
  /// **'Đã sửa · không còn là văn AI'**
  String get sryEdited;

  /// 14c meta.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 từ} other{{count} từ}}'**
  String sryWords(int count);

  /// 14c section.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho đoạn này'**
  String get srySuggestFor;

  /// 14c chip.
  ///
  /// In vi, this message translates to:
  /// **'Dùng câu này'**
  String get sryUseThis;

  /// 14c chip.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý khác'**
  String get sryOtherSuggestion;

  /// AI error (G-051).
  ///
  /// In vi, this message translates to:
  /// **'AI chưa sẵn sàng. Bạn vẫn sửa tay được.'**
  String get sryAiUnavailable;

  /// AI daily limit.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay đã dùng hết lượt gợi ý.'**
  String get sryAiLimit;

  /// AI in progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang viết…'**
  String get sryAiWorking;

  /// 14d title.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh trong câu chuyện'**
  String get sryPhotosTitle;

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh'**
  String get sryChangePhoto;

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ Kỷ niệm của {name}'**
  String sryChangePhotoHint(String name);

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh vào nhóm này'**
  String get sryAddToGroup;

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 4 ảnh một nhóm'**
  String get sryAddToGroupHint;

  /// 14d option / caption sheet.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chú thích'**
  String get sryCaption;

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Hiện nhỏ dưới ảnh'**
  String get sryCaptionHint;

  /// 14d option.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm ảnh bìa'**
  String get sryMakeCover;

  /// 14d destructive.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi câu chuyện'**
  String get sryRemovePhotos;

  /// 14d destructive.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vẫn còn trong Kỷ niệm'**
  String get sryRemovePhotosHint;

  /// 14e hint.
  ///
  /// In vi, this message translates to:
  /// **'Giữ ≡ và kéo để đổi thứ tự. Vuốt trái để xoá khối.'**
  String get sryArrangeHint;

  /// 14e row.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get sryCoverRow;

  /// 14e row.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn {n}'**
  String sryParagraphN(int n);

  /// 14e row.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm ảnh'**
  String get sryPhotoGroup;

  /// 14e row.
  ///
  /// In vi, this message translates to:
  /// **'Mốc'**
  String get sryMilestoneRow;

  /// 14e row.
  ///
  /// In vi, this message translates to:
  /// **'Câu trích'**
  String get sryQuoteRow;

  /// 14f label.
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC'**
  String get sryPreviewLabel;

  /// 14f guard.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tiêu đề cho câu chuyện.'**
  String get sryNeedTitle;

  /// 14f guard.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ít nhất một đoạn hoặc một ảnh.'**
  String get sryNeedContent;

  /// 14f sheet title / button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu câu chuyện'**
  String get srySaveTitle;

  /// 14f card.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get sryPrivate;

  /// 14f card.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà cùng đọc'**
  String get sryFamilyRead;

  /// 14f row.
  ///
  /// In vi, this message translates to:
  /// **'1 thông báo chung'**
  String get sryOneNotice;

  /// 14f footnote.
  ///
  /// In vi, this message translates to:
  /// **'Lưu xong mới chia sẻ ra ngoài được.'**
  String get sryShareAfter;

  /// 14f D-002 note.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.} other{{count} ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.}}'**
  String sryPrivatePhotos(int count);

  /// 14g toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu · đã báo cho gia đình'**
  String get srySavedNotified;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu câu chuyện'**
  String get srySaved;

  /// 14g button.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get sryShare;

  /// Share sheet (S12 part).
  ///
  /// In vi, this message translates to:
  /// **'Ai đọc câu chuyện này'**
  String get sryWhoReads;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ai đọc'**
  String get sryAudienceChanged;

  /// Reader overflow (G-050).
  ///
  /// In vi, this message translates to:
  /// **'Xoá câu chuyện'**
  String get sryDelete;

  /// G-050.
  ///
  /// In vi, this message translates to:
  /// **'Xoá câu chuyện này?'**
  String get sryDeleteTitle;

  /// G-050.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà sẽ không đọc được nữa. Ảnh vẫn còn trong Kỷ niệm.'**
  String get sryDeleteBody;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá câu chuyện'**
  String get sryDeleted;

  /// 14g meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} kể · {when} · {audience}'**
  String sryMetaSaved(String who, String when, String audience);

  /// 11i meta.
  ///
  /// In vi, this message translates to:
  /// **'{who} chia sẻ với gia đình · {when}'**
  String sryRelMeta(String who, String when);

  /// 14g chip.
  ///
  /// In vi, this message translates to:
  /// **'{name} · {date}'**
  String sryMilestoneOn(String name, String date);

  /// Reader ••• (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn câu chuyện'**
  String get sryMore;

  /// 14h section.
  ///
  /// In vi, this message translates to:
  /// **'Trong gia đình'**
  String get shInFamily;

  /// 14h row.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình đang đọc'**
  String get shFamilyReading;

  /// 14h row (parents-only story).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ đang đọc'**
  String get shParentsReading;

  /// 14h row.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo cả nhà · chạm để đổi'**
  String get shTapToChange;

  /// 14h row (parents-only).
  ///
  /// In vi, this message translates to:
  /// **'Chạm để đổi'**
  String get shTapToChangeParents;

  /// 14h section.
  ///
  /// In vi, this message translates to:
  /// **'Ra ngoài'**
  String get shOutside;

  /// 14h row / 14i title.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp ảnh'**
  String get shCard;

  /// 14h row.
  ///
  /// In vi, this message translates to:
  /// **'Đẹp để đăng Facebook, Instagram, Zalo'**
  String get shCardHint;

  /// 14h row / 14k title.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết xem riêng'**
  String get shLink;

  /// 14h row.
  ///
  /// In vi, this message translates to:
  /// **'Có hạn · không cần cài app'**
  String get shLinkHint;

  /// 14h note.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ thấy mục “Ra ngoài”. Mặc định ẩn tên thật và ngày sinh.'**
  String get shOutsideNote;

  /// 14h note (P-095).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh Chỉ ba mẹ không hiện khi chia sẻ ra ngoài.'**
  String get shPrivatePhotosNote;

  /// 14i top bar.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get cdNext;

  /// 14i template.
  ///
  /// In vi, this message translates to:
  /// **'1 ảnh'**
  String get cdMoment;

  /// 14i template.
  ///
  /// In vi, this message translates to:
  /// **'3 ảnh'**
  String get cdThree;

  /// 14i template.
  ///
  /// In vi, this message translates to:
  /// **'4 ảnh'**
  String get cdFour;

  /// 14i template.
  ///
  /// In vi, this message translates to:
  /// **'Chữ'**
  String get cdLetter;

  /// 14i template.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get cdNight;

  /// 14i option.
  ///
  /// In vi, this message translates to:
  /// **'Câu trích'**
  String get cdQuote;

  /// 14i option.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get cdPhoto;

  /// 14i option value.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get cdCover;

  /// 14i option.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tuổi thay ngày sinh'**
  String get cdShowAge;

  /// Letter card greeting.
  ///
  /// In vi, this message translates to:
  /// **'Gửi {name},'**
  String cdTo(String name);

  /// Letter card signature.
  ///
  /// In vi, this message translates to:
  /// **'— {who}, {season}'**
  String cdSigned(String who, String season);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo thiệp'**
  String get cdSaved;

  /// 14j sheet head.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh 1080 × 1350'**
  String get cdSize;

  /// 14k label.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau'**
  String get lkExpires;

  /// 14k option.
  ///
  /// In vi, this message translates to:
  /// **'24 giờ'**
  String get lk24h;

  /// 14k option.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get lk7d;

  /// 14k option.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get lk30d;

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn tên thật & ngày sinh'**
  String get lkHideIdentity;

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hiện “{name}” và số tuần tuổi'**
  String lkHideIdentityHint(String name);

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Cho tải ảnh về'**
  String get lkDownload;

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt: người xem chỉ xem, không lưu'**
  String get lkDownloadHint;

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi mật mã 4 số'**
  String get lkPasscode;

  /// 14k toggle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mật mã riêng cho người nhận'**
  String get lkPasscodeHint;

  /// 14k note.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thấy được số lượt xem và thu hồi bất cứ lúc nào.'**
  String get lkNote;

  /// 14k button.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép & chia sẻ'**
  String get lkCopyShare;

  /// 14k chip.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get lkCopy;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết'**
  String get lkCopied;

  /// Passcode reveal (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Mật mã của liên kết'**
  String get lkPasscodeTitle;

  /// Passcode reveal.
  ///
  /// In vi, this message translates to:
  /// **'Gửi riêng mật mã này cho người nhận. Child Life không hiện lại mật mã.'**
  String get lkPasscodeBody;

  /// 14k caveat (R-166).
  ///
  /// In vi, this message translates to:
  /// **'Người xem vẫn có thể chụp màn hình.'**
  String get lkScreenshotNote;

  /// 14m title / Tôi row.
  ///
  /// In vi, this message translates to:
  /// **'Đã chia sẻ ra ngoài'**
  String get soTitle;

  /// Tôi row value.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 liên kết đang mở} other{{count} liên kết đang mở}}'**
  String soOpenCount(int count);

  /// 14m section.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get soOpen;

  /// 14m section.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp ảnh đã lưu'**
  String get soCards;

  /// 14m section.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn'**
  String get soClosed;

  /// 14m row.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 lượt xem · còn {left}} other{{count} lượt xem · còn {left}}}'**
  String soViewsLeftDays(int count, String left);

  /// 14m duration.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 ngày} other{{count} ngày}}'**
  String soDays(int count);

  /// 14m duration.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{1 giờ} other{{count} giờ}}'**
  String soHours(int count);

  /// 14m chip.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get soRevoke;

  /// Confirmation (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi liên kết?'**
  String get soRevokeTitle;

  /// Confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Người có liên kết sẽ không xem được nữa.'**
  String get soRevokeBody;

  /// Row / toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi'**
  String get soRevoked;

  /// 14m row.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn {date}'**
  String soExpiredOn(String date);

  /// 14m row.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh · không thu hồi được'**
  String get soCardRow;

  /// 14m empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chia sẻ câu chuyện nào ra ngoài.'**
  String get soEmpty;

  /// 10k share extension title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào Kỷ niệm'**
  String get shareExtTitle;

  /// 10k confirm.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get shareExtAdd;

  /// 10k baby row.
  ///
  /// In vi, this message translates to:
  /// **'Bé'**
  String get shareExtBaby;

  /// 10k notify subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi 1 thông báo khi tải xong'**
  String get shareExtNotifyHint;

  /// 10k item count: photos.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String shareExtPhotos(int count);

  /// 10k item count: videos.
  ///
  /// In vi, this message translates to:
  /// **'{count} video'**
  String shareExtVideos(int count);

  /// 10k footnote (D-046: uploads start when the app opens).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh sẽ tải lên khi bạn mở Child Life.'**
  String get shareExtFootnote;

  /// 10k when signed out.
  ///
  /// In vi, this message translates to:
  /// **'Mở Child Life và đăng nhập để thêm ảnh vào Kỷ niệm.'**
  String get shareExtSignedOut;

  /// 10k when the account cannot add memories.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ (Cùng nuôi) thêm được kỷ niệm cho bé.'**
  String get shareExtNoBaby;

  /// 10k when nothing usable was shared.
  ///
  /// In vi, this message translates to:
  /// **'Không có ảnh hay video nào để thêm.'**
  String get shareExtNothing;

  /// 10k close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get shareExtClose;

  /// UploadPill when uploads are switched off (A11 kill switch).
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh, video đang tạm dừng'**
  String get upUploadsPaused;

  /// UploadPill hint while uploads are paused.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, video sẽ tự tải tiếp khi mở lại.'**
  String get upUploadsPausedHint;

  /// 10i row while uploads are switched off.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạm dừng tải lên'**
  String get rowUploadsPaused;

  /// 10i row when the server refused the upload (Thử lại).
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải lên được'**
  String get rowRejected;

  /// Widget / Live Activity copy (appName); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Child Life'**
  String get glanceAppName;

  /// Widget / Live Activity copy (you); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get glanceYou;

  /// Widget / Live Activity copy (bottle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình'**
  String get glanceBottle;

  /// Widget / Live Activity copy (breast); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ'**
  String get glanceBreast;

  /// Widget / Live Activity copy (sleep); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get glanceSleep;

  /// Widget / Live Activity copy (sleepTitle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get glanceSleepTitle;

  /// Widget / Live Activity copy (diaper); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get glanceDiaper;

  /// Widget / Live Activity copy (diaper.wet); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Ướt'**
  String get glanceDiaperWet;

  /// Widget / Live Activity copy (diaper.dirty); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bẩn'**
  String get glanceDiaperDirty;

  /// Widget / Live Activity copy (diaper.both); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai'**
  String get glanceDiaperBoth;

  /// Widget / Live Activity copy (ago); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{t} trước'**
  String glanceAgo(String t);

  /// Widget / Live Activity copy (loggedBy); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{name} ghi'**
  String glanceLoggedBy(String name);

  /// Widget / Live Activity copy (plusMl); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'+ {ml} ml'**
  String glancePlusMl(String ml);

  /// Widget / Live Activity copy (loggedBottle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{ml} ml'**
  String glanceLoggedBottle(String ml);

  /// Widget / Live Activity copy (loggedDiaper); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{kind}'**
  String glanceLoggedDiaper(String kind);

  /// Widget / Live Activity copy (logged); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi {what} · {name}'**
  String glanceLogged(String what, String name);

  /// Widget / Live Activity copy (loggedToast); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi {what}'**
  String glanceLoggedToast(String what);

  /// Widget / Live Activity copy (justNow); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get glanceJustNow;

  /// Widget / Live Activity copy (undo); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get glanceUndo;

  /// Widget / Live Activity copy (edit); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get glanceEdit;

  /// Widget / Live Activity copy (changeType); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đổi loại'**
  String get glanceChangeType;

  /// Widget / Live Activity copy (startBreast); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu bú'**
  String get glanceStartBreast;

  /// Widget / Live Activity copy (feeding); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đang bú'**
  String get glanceFeeding;

  /// Widget / Live Activity copy (switchSide); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đổi bên'**
  String get glanceSwitchSide;

  /// Widget / Live Activity copy (done); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get glanceDone;

  /// Widget / Live Activity copy (breastSide.left); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bên trái'**
  String get glanceBreastSideLeft;

  /// Widget / Live Activity copy (breastSide.right); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bên phải'**
  String get glanceBreastSideRight;

  /// Widget / Live Activity copy (sinceTime); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'từ {time}'**
  String glanceSinceTime(String time);

  /// Widget / Live Activity copy (awakeFor); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đã thức {t}'**
  String glanceAwakeFor(String t);

  /// Widget / Live Activity copy (wokeAt); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Dậy lúc {time}'**
  String glanceWokeAt(String time);

  /// Widget / Live Activity copy (startSleep); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ngủ'**
  String get glanceStartSleep;

  /// Widget / Live Activity copy (sleeping); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ'**
  String get glanceSleeping;

  /// Widget / Live Activity copy (since); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Từ {time} · {name}'**
  String glanceSince(String time, String name);

  /// Widget / Live Activity copy (wake); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Thức dậy'**
  String get glanceWake;

  /// Widget / Live Activity copy (justWoke); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Vừa thức dậy'**
  String get glanceJustWoke;

  /// Widget / Live Activity copy (slept); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ {t}'**
  String glanceSlept(String t);

  /// Widget / Live Activity copy (emptyTitle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chưa ghi'**
  String get glanceEmptyTitle;

  /// Widget / Live Activity copy (emptySub); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Ghi cữ đầu tiên nhé'**
  String get glanceEmptySub;

  /// Widget / Live Activity copy (quickLog); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'+ Ghi nhanh'**
  String get glanceQuickLog;

  /// Widget / Live Activity copy (signedOutTitle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để dùng widget'**
  String get glanceSignedOutTitle;

  /// Widget / Live Activity copy (openApp); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Mở app'**
  String get glanceOpenApp;

  /// Widget / Live Activity copy (openChildLife); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Mở Child Life'**
  String get glanceOpenChildLife;

  /// Widget / Live Activity copy (summary); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{feeds} cữ · ngủ {sleep} hôm nay'**
  String glanceSummary(String feeds, String sleep);

  /// Widget / Live Activity copy (pending); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ · {n} bản ghi chờ'**
  String glancePending(String n);

  /// Widget / Live Activity copy (recent); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get glanceRecent;

  /// Widget / Live Activity copy (totals); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay: {bottles} cữ bình {ml} ml · {breasts} lần bú mẹ · {diapers} tã'**
  String glanceTotals(
    String bottles,
    String ml,
    String breasts,
    String diapers,
  );

  /// Widget / Live Activity copy (noneYet); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get glanceNoneYet;

  /// Widget / Live Activity copy (fedFor); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bú {t} · {name} ghi'**
  String glanceFedFor(String t, String name);

  /// Widget / Live Activity copy (agoFor); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'trước · {t}'**
  String glanceAgoFor(String t);

  /// Widget / Live Activity copy (agoKind); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'trước · {kind}'**
  String glanceAgoKind(String kind);

  /// Widget / Live Activity copy (awakeShort); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'thức {t}'**
  String glanceAwakeShort(String t);

  /// Widget / Live Activity copy (sleptToday); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'ngủ {t} hôm nay'**
  String glanceSleptToday(String t);

  /// Widget / Live Activity copy (lockFeeds); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bú {feed} · Tã {diaper}'**
  String glanceLockFeeds(String feed, String diaper);

  /// Widget / Live Activity copy (lockSleep); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Thức {awake} · ngủ {slept}'**
  String glanceLockSleep(String awake, String slept);

  /// Widget / Live Activity copy (inlineFed); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{name} bú {t} trước'**
  String glanceInlineFed(String name, String t);

  /// Widget / Live Activity copy (familySees); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà đang thấy'**
  String get glanceFamilySees;

  /// Widget / Live Activity copy (sleepingTitle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{name} đang ngủ'**
  String glanceSleepingTitle(String name);

  /// Widget / Live Activity copy (editTime); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giờ bắt đầu'**
  String get glanceEditTime;

  /// Widget / Live Activity copy (editTimeShort); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giờ'**
  String get glanceEditTimeShort;

  /// Widget / Live Activity copy (breastTitle); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ · {side}'**
  String glanceBreastTitle(String side);

  /// Widget / Live Activity copy (endFeed); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get glanceEndFeed;

  /// Widget / Live Activity copy (paused); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get glancePaused;

  /// Widget / Live Activity copy (dur.m); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{m} phút'**
  String glanceDurM(String m);

  /// Widget / Live Activity copy (dur.h); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{h} giờ'**
  String glanceDurH(String h);

  /// Widget / Live Activity copy (dur.hm); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{h} giờ {m} phút'**
  String glanceDurHm(String h, String m);

  /// Widget / Live Activity copy (durS.m); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{m}p'**
  String glanceDurSM(String m);

  /// Widget / Live Activity copy (durS.h); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{h}g'**
  String glanceDurSH(String h);

  /// Widget / Live Activity copy (durS.hm); placeholders stay as templates.
  ///
  /// In vi, this message translates to:
  /// **'{h}g {m}p'**
  String glanceDurSHm(String h, String m);

  /// Widget gallery name (W1 small).
  ///
  /// In vi, this message translates to:
  /// **'Bú bình'**
  String get glanceGalleryBottleName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại cữ bình vừa rồi chỉ với một chạm.'**
  String get glanceGalleryBottleBlurb;

  /// Widget gallery name (W1 small).
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ'**
  String get glanceGalleryBreastName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu, đổi bên và kết thúc cữ bú.'**
  String get glanceGalleryBreastBlurb;

  /// Widget gallery name (W1 small).
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get glanceGallerySleepName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ngủ và thức dậy ngay trên màn hình chính.'**
  String get glanceGallerySleepBlurb;

  /// Widget gallery name (W1 small).
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get glanceGalleryDiaperName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Ướt, bẩn hay cả hai — một chạm.'**
  String get glanceGalleryDiaperBlurb;

  /// Widget gallery name (W2 medium).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh'**
  String get glanceGalleryQuickName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình, bú mẹ, ngủ, thay tã — một chạm.'**
  String get glanceGalleryQuickBlurb;

  /// Widget gallery name (W2 large).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get glanceGalleryTodayName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ, ghi nhanh và 3 lần ghi gần nhất.'**
  String get glanceGalleryTodayBlurb;

  /// Lock Screen widget name (W3).
  ///
  /// In vi, this message translates to:
  /// **'Child Life'**
  String get glanceGalleryLockName;

  /// Lock Screen widget description.
  ///
  /// In vi, this message translates to:
  /// **'Lần bú, tã và giấc ngủ trên màn hình khoá.'**
  String get glanceGalleryLockBlurb;

  /// Lock Screen widget name (W3 circular).
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get glanceGalleryLockSleepName;

  /// Lock Screen widget description.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ bao lâu, hoặc đã thức bao lâu.'**
  String get glanceGalleryLockSleepBlurb;

  /// Lock Screen widget name (W3 circular).
  ///
  /// In vi, this message translates to:
  /// **'Lần bú'**
  String get glanceGalleryLockFeedName;

  /// Lock Screen widget description.
  ///
  /// In vi, this message translates to:
  /// **'Bao lâu từ lần bú gần nhất.'**
  String get glanceGalleryLockFeedBlurb;

  /// Upload Live Activity header (10j).
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm của {name}'**
  String glanceUploadTitle(String name);

  /// Upload Live Activity header without a nickname.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get glanceUploadTitlePlain;

  /// Upload Live Activity (10j).
  ///
  /// In vi, this message translates to:
  /// **'Đang tải {done}/{total} mục'**
  String glanceUploadProgress(String done, String total);

  /// Upload Live Activity sub (10j).
  ///
  /// In vi, this message translates to:
  /// **'Xong sẽ báo bạn'**
  String get glanceUploadNotify;

  /// Upload Live Activity sub when videos wait (D-033).
  ///
  /// In vi, this message translates to:
  /// **'{n} video chờ Wi‑Fi'**
  String glanceUploadWaiting(String n);

  /// Notice when background uploads finish.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải xong 1 mục'**
  String get glanceUploadDoneOne;

  /// Notice when background uploads finish.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải xong {n} mục'**
  String glanceUploadDone(String n);

  /// Notice body (no photo, 10j).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và video đã có trong Kỷ niệm.'**
  String get glanceUploadDoneBody;

  /// Notice when background uploads fail.
  ///
  /// In vi, this message translates to:
  /// **'1 mục chưa tải lên được'**
  String get glanceUploadFailedOne;

  /// Notice when background uploads fail.
  ///
  /// In vi, this message translates to:
  /// **'{n} mục chưa tải lên được'**
  String glanceUploadFailed(String n);

  /// Notice body.
  ///
  /// In vi, this message translates to:
  /// **'Mở Child Life để thử lại.'**
  String get glanceUploadFailedBody;

  /// Notice (10j) when the app is left with a video held for Wi-Fi.
  ///
  /// In vi, this message translates to:
  /// **'1 video đang chờ Wi‑Fi'**
  String get glanceUploadWifiOne;

  /// Notice (10j).
  ///
  /// In vi, this message translates to:
  /// **'{n} video đang chờ Wi‑Fi'**
  String glanceUploadWifi(String n);

  /// Notice body (10j).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi.'**
  String get glanceUploadWifiBody;

  /// Tôi row and sheet title (G-081).
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get meLanguage;

  /// Follow the phone language.
  ///
  /// In vi, this message translates to:
  /// **'Theo máy'**
  String get meLanguageDevice;

  /// Subtitle: the language the phone gives.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng {name}'**
  String meLanguageDeviceNow(String name);

  /// Endonym, same in every language.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get meLanguageVi;

  /// Endonym, same in every language.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get meLanguageEn;

  /// Sheet footnote.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngay cho cả app, widget và thông báo trên máy này.'**
  String get meLanguageHint;

  /// 20i subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo bảng chuẩn tăng trưởng trẻ em của WHO. Mỗi bé lớn theo nhịp riêng.'**
  String get whoIntro;

  /// 20i chip.
  ///
  /// In vi, this message translates to:
  /// **'Bé trai'**
  String get whoBoy;

  /// 20i chip.
  ///
  /// In vi, this message translates to:
  /// **'Bé gái'**
  String get whoGirl;

  /// 20i chip.
  ///
  /// In vi, this message translates to:
  /// **'Theo tuần'**
  String get whoByWeek;

  /// 20i chip.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get whoByMonth;

  /// 20i column.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi'**
  String get whoAge;

  /// 20i column: 3rd percentile.
  ///
  /// In vi, this message translates to:
  /// **'Thấp'**
  String get whoLow;

  /// 20i column: median.
  ///
  /// In vi, this message translates to:
  /// **'Trung vị'**
  String get whoMedian;

  /// 20i column: 97th percentile.
  ///
  /// In vi, this message translates to:
  /// **'Cao'**
  String get whoHigh;

  /// 20i row.
  ///
  /// In vi, this message translates to:
  /// **'Mới sinh'**
  String get whoBirth;

  /// 20i row.
  ///
  /// In vi, this message translates to:
  /// **'{count} tuần'**
  String whoWeeks(int count);

  /// 20i row.
  ///
  /// In vi, this message translates to:
  /// **'{count} tháng'**
  String whoMonths(int count);

  /// 20i footnote, weight.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị: kg. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.'**
  String get whoUnitKg;

  /// 20i footnote, length.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị: cm. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.'**
  String get whoUnitCm;

  /// 20i banner.
  ///
  /// In vi, this message translates to:
  /// **'Nếu số đo của bé nằm ngoài khoảng bình thường, hãy trao đổi với bác sĩ của bé.'**
  String get whoDoctor;

  /// 20i source line.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: WHO Child Growth Standards · Child Life cập nhật 09/2026'**
  String get whoSource;

  /// 20i: the baby’s row.
  ///
  /// In vi, this message translates to:
  /// **'{name} {value} · {status}'**
  String whoBabyAt(String name, String value, String status);

  /// Within the WHO normal range (3rd–97th percentile).
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get whoNormal;

  /// Under the 3rd percentile (20d).
  ///
  /// In vi, this message translates to:
  /// **'Dưới mức tham chiếu'**
  String get whoBelow;

  /// Over the 97th percentile.
  ///
  /// In vi, this message translates to:
  /// **'Trên mức tham chiếu'**
  String get whoAbove;

  /// 20d link to 20i.
  ///
  /// In vi, this message translates to:
  /// **'Xem tiêu chuẩn tăng trưởng WHO'**
  String get whoOpen;

  /// 20d chart legend.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng bình thường'**
  String get whoBand;

  /// 20d chart legend.
  ///
  /// In vi, this message translates to:
  /// **'Trung vị WHO'**
  String get whoMedianLine;

  /// 20g card.
  ///
  /// In vi, this message translates to:
  /// **'Bú mỗi ngày'**
  String get feedsPerDayTitle;

  /// 20g card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Số cữ bú bình và bú mẹ · {days} ngày'**
  String feedsPerDayHint(int days);

  /// 20g selected-day callout.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {bottles} bình {ml} ml · {breasts} mẹ {minutes}p'**
  String feedsDayTip(String day, int bottles, int ml, int breasts, int minutes);

  /// 20g average line.
  ///
  /// In vi, this message translates to:
  /// **'TB {count} cữ'**
  String feedsAvgLine(int count);

  /// 20g share.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình {pct}% · {ml} ml/ngày'**
  String bottleShareLine(int pct, int ml);

  /// 20g share.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ {pct}% · {minutes} phút/ngày'**
  String breastShareLine(int pct, int minutes);

  /// 20g KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'TB mỗi ngày'**
  String get kpiFeedsPerDay;

  /// 20g KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình/ngày'**
  String get kpiBottlePerDay;

  /// 20g KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ/ngày'**
  String get kpiBreastPerDay;

  /// 20h card.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giờ ngủ mỗi ngày'**
  String get sleepPerDayTitle;

  /// 20h card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đêm 18:00–06:00 · Ngày 06:00–18:00'**
  String get sleepPerDayHint;

  /// 20h selected-day callout.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {total} · đêm {night} · ngày {daytime}'**
  String sleepDayTip(String day, String total, String night, String daytime);

  /// 20h average line.
  ///
  /// In vi, this message translates to:
  /// **'TB {total}'**
  String sleepAvgLine(String total);

  /// 20h legend.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ đêm'**
  String get legendNightSleep;

  /// 20h legend.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ ngày'**
  String get legendDaySleep;

  /// 20h insight when days differ by 2 h or less.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giờ ngủ ổn định quanh {hours} giờ/ngày trong {days} ngày qua.'**
  String sleepSteadyInsight(int hours, int days);

  /// 20h insight otherwise.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giờ ngủ từ {min} đến {max} mỗi ngày trong {days} ngày qua.'**
  String sleepRangeInsight(String min, String max, int days);

  /// 20i title.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chuẩn tăng trưởng'**
  String get whoStandardsTitle;

  /// 20d pill below the band.
  ///
  /// In vi, this message translates to:
  /// **'Ngưỡng dưới {value}'**
  String whoLowerEdge(String value);

  /// 20d pill above the band.
  ///
  /// In vi, this message translates to:
  /// **'Ngưỡng trên {value}'**
  String whoUpperEdge(String value);

  /// 20d note (347:935).
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng của {name} đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoBelowWeightNote(String name);

  /// 20d note.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài của {name} đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoBelowLengthNote(String name);

  /// 20d note.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng của {name} đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoAboveWeightNote(String name);

  /// 20d note.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài của {name} đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoAboveLengthNote(String name);

  /// 22 field label when prefilled.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa · đã điền theo lần trước'**
  String get amountFromLast;

  /// 22 caption.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước {ml} ml · {time}'**
  String lastBottleAt(int ml, String time);

  /// 22 caption; age like "3 tuần".
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho bé {age}'**
  String bottleSuggestFor(String age);

  /// 22 caption, first week.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho bé sơ sinh'**
  String get bottleSuggestNewborn;

  /// 22 quick-pick chip (a11y).
  ///
  /// In vi, this message translates to:
  /// **'{ml} ml'**
  String bottleQuickPick(int ml);

  /// 20g type sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Loại bú'**
  String get feedKindTitle;

  /// 20g type: all feeds.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get feedKindAll;

  /// 20g type caption.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình và bú mẹ'**
  String get feedKindAllHint;

  /// 20g type caption.
  ///
  /// In vi, this message translates to:
  /// **'Theo lượng sữa (ml)'**
  String get feedKindBottleHint;

  /// 20g type caption.
  ///
  /// In vi, this message translates to:
  /// **'Theo thời gian bú (phút)'**
  String get feedKindBreastHint;

  /// 20g range sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian'**
  String get rangeTitle;

  /// 20g range: custom.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn'**
  String get rangeCustom;

  /// 20g range caption.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ ngày – đến ngày'**
  String get rangeCustomHint;

  /// 20g range caption / pill.
  ///
  /// In vi, this message translates to:
  /// **'{from} – {to}'**
  String rangeSpan(String from, String to);

  /// 20g KPI caption.
  ///
  /// In vi, this message translates to:
  /// **'TB mỗi cữ'**
  String get kpiPerFeed;

  /// 20g Bú bình card.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa mỗi ngày'**
  String get milkPerDayTitle;

  /// 20g Bú bình card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng ml bú bình · {days} ngày'**
  String milkPerDayHint(int days);

  /// 20g Bú bình callout.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {ml} ml · {count} cữ'**
  String milkDayTip(String day, int ml, int count);

  /// 20g Bú bình average line.
  ///
  /// In vi, this message translates to:
  /// **'TB {ml} ml'**
  String mlAvgLine(int ml);

  /// 20g Bú bình legend.
  ///
  /// In vi, this message translates to:
  /// **'Sữa mẹ vắt'**
  String get legendExpressedMilk;

  /// 20g Bú bình legend.
  ///
  /// In vi, this message translates to:
  /// **'Sữa công thức'**
  String get legendFormula;

  /// 20g Bú mẹ card.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian bú mẹ mỗi ngày'**
  String get breastPerDayTitle;

  /// 20g Bú mẹ card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng phút · bên trái và bên phải'**
  String get breastPerDayHint;

  /// 20g Bú mẹ callout.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {minutes} phút · {count} cữ'**
  String breastDayTip(String day, int minutes, int count);

  /// 20g Bú mẹ average line.
  ///
  /// In vi, this message translates to:
  /// **'TB {minutes} phút'**
  String minutesAvgLine(int minutes);

  /// 20g Bú mẹ legend.
  ///
  /// In vi, this message translates to:
  /// **'Bên trái'**
  String get legendLeftSide;

  /// 20g Bú mẹ legend.
  ///
  /// In vi, this message translates to:
  /// **'Bên phải'**
  String get legendRightSide;

  /// 20g Bú mẹ banner.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú.'**
  String get breastByTimeNote;

  /// 20g Bú mẹ day/night detail.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút · {count} cữ'**
  String minutesAndFeeds(int minutes, int count);

  /// 20g Bú mẹ insight.
  ///
  /// In vi, this message translates to:
  /// **'Đêm qua bú mẹ {count} cữ, {minutes} phút ({time}).'**
  String lastNightBreastInsight(int count, int minutes, String time);

  /// NavBar v1.0.1 tab.
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc'**
  String get tabCare;

  /// Header avatar → Tôi (370:1898).
  ///
  /// In vi, this message translates to:
  /// **'Tôi'**
  String get a11yOpenMe;

  /// Care tab title (370:1971).
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc'**
  String get careTitle;

  /// Care search field.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong Chăm sóc…'**
  String get careSearchHint;

  /// Care section.
  ///
  /// In vi, this message translates to:
  /// **'Chăm hằng ngày'**
  String get careDaily;

  /// Care tile.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get careReminders;

  /// Care tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} nhắc đang bật'**
  String careRemindersOn(int count);

  /// Care tile subtitle, caregiver (370:2174).
  ///
  /// In vi, this message translates to:
  /// **'{count} nhắc giao cho bạn'**
  String careRemindersMine(int count);

  /// Care tile.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get careStats;

  /// Care tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bú, ngủ theo ngày'**
  String get careStatsSub;

  /// Care tile.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get careHistory;

  /// Care tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mọi lần đã ghi'**
  String get careHistorySub;

  /// Care tile.
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng'**
  String get careGrowth;

  /// Care tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng, chiều dài'**
  String get careGrowthSub;

  /// Care section and badge.
  ///
  /// In vi, this message translates to:
  /// **'Sớm ra mắt'**
  String get careSoon;

  /// Tap on a coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Phần này sẽ có trong bản cập nhật tới.'**
  String get careSoonToast;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Wonder Weeks'**
  String get careWonderWeek;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn phát triển dự kiến'**
  String get careWonderWeekSub;

  /// Chăm sóc tile → Giai đoạn của bé (D-076 #5; formerly "Thẻ theo tuổi").
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn của bé'**
  String get careAgeCards;

  /// Chăm sóc tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho từng tuần, từng tháng'**
  String get careAgeCardsSub;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Mốc phát triển'**
  String get careMilestones;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại lần đầu của con'**
  String get careMilestonesSub;

  /// Chăm sóc tile → Thư viện chăm bé.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện chăm bé'**
  String get careLibrary;

  /// Chăm sóc tile subtitle (no review claim until reviewed, P-141).
  ///
  /// In vi, this message translates to:
  /// **'Bài viết chăm bé theo tuổi'**
  String get careLibrarySub;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm'**
  String get careSolids;

  /// Coming-soon tile.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký & thư viện ăn dặm'**
  String get careSolidsSub;

  /// Sheet title when tapping Thống kê.
  ///
  /// In vi, this message translates to:
  /// **'Xem thống kê'**
  String get careStatsPick;

  /// Care search, no result.
  ///
  /// In vi, this message translates to:
  /// **'Không có mục nào khớp.'**
  String get careNoResults;

  /// Hôm nay pill (370:1248).
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chỉnh'**
  String get todayCustomize;

  /// Sheet title (370:1525).
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chỉnh Hôm nay'**
  String get customizeTitle;

  /// Sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Bật phần nào thì chọn luôn nội dung ngay bên dưới. Kéo tay nắm bên trái, hoặc nhấn giữ một dòng, để đổi thứ tự.'**
  String get customizeIntro;

  /// Today section.
  ///
  /// In vi, this message translates to:
  /// **'Ô theo dõi nhanh'**
  String get sectionTiles;

  /// Today section subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bú, ngủ, tã, hút sữa, tăng trưởng'**
  String get sectionTilesSub;

  /// Today section.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc sắp tới'**
  String get sectionReminders;

  /// Today section.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp trong ngày'**
  String get sectionRhythm;

  /// Today section subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ 24 giờ'**
  String get sectionRhythmSub;

  /// Customise sheet section.
  ///
  /// In vi, this message translates to:
  /// **'Ô theo dõi hiển thị'**
  String get visibleTiles;

  /// Customise sheet secondary.
  ///
  /// In vi, this message translates to:
  /// **'Về mặc định'**
  String get customizeReset;

  /// Customise sheet primary.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get customizeDone;

  /// Drag handle a11y.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để sắp xếp'**
  String get a11yDragToReorder;

  /// 01 Chào mừng body (368:998).
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời.'**
  String get welcomeBody;

  /// Journey illustration card (368:967).
  ///
  /// In vi, this message translates to:
  /// **'Bú bình · 120 ml'**
  String get journeyFeed;

  /// Journey illustration card (368:968).
  ///
  /// In vi, this message translates to:
  /// **'Mẹ ghi · 2 phút trước'**
  String get journeyFeedWho;

  /// Journey illustration card (368:974).
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu con cười'**
  String get journeySmile;

  /// Journey illustration card (368:975).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào Kỷ niệm'**
  String get journeySmileSaved;

  /// Journey illustration card (368:979).
  ///
  /// In vi, this message translates to:
  /// **'Bà nội thương ảnh của Teddy'**
  String get journeyLove;

  /// Journey stage chip.
  ///
  /// In vi, this message translates to:
  /// **'0–12 tháng'**
  String get journeyStage1;

  /// Journey stage chip.
  ///
  /// In vi, this message translates to:
  /// **'1–3 tuổi'**
  String get journeyStage2;

  /// Journey stage chip.
  ///
  /// In vi, this message translates to:
  /// **'3–6 tuổi'**
  String get journeyStage3;

  /// Journey stage chip.
  ///
  /// In vi, this message translates to:
  /// **'6–12 tuổi'**
  String get journeyStage4;

  /// Journey illustration label.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình lớn lên của con, từ năm đầu đời đến 12 tuổi'**
  String get a11yJourney;

  /// R1 sheet title (368:1274).
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get welcomeBackTitle;

  /// R1 sheet body (368:1276).
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tiếp tục hành trình cùng con.'**
  String get welcomeBackBody;

  /// 1a segment.
  ///
  /// In vi, this message translates to:
  /// **'Theo quy tắc'**
  String get ruleTabRules;

  /// 1a segment: the dated reminders.
  ///
  /// In vi, this message translates to:
  /// **'Một lần'**
  String get ruleTabOnce;

  /// Rule title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc bú'**
  String get ruleTitleFeed;

  /// Rule title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc chuẩn bị ngủ'**
  String get ruleTitleSleep;

  /// Rule title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc thay tã'**
  String get ruleTitleDiaper;

  /// Rule title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc hút sữa'**
  String get ruleTitlePump;

  /// Rule line.
  ///
  /// In vi, this message translates to:
  /// **'{duration} sau lần bú gần nhất'**
  String ruleAfterFeed(String duration);

  /// Rule line.
  ///
  /// In vi, this message translates to:
  /// **'{duration} sau khi bé dậy'**
  String ruleAfterSleep(String duration);

  /// Rule line.
  ///
  /// In vi, this message translates to:
  /// **'{duration} sau lần thay gần nhất'**
  String ruleAfterDiaper(String duration);

  /// Rule line.
  ///
  /// In vi, this message translates to:
  /// **'{duration} sau lần hút sữa gần nhất'**
  String ruleAfterPump(String duration);

  /// Rule line, fixed times.
  ///
  /// In vi, this message translates to:
  /// **'Cố định {times}'**
  String ruleFixedLine(String times);

  /// Rule status pill.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo {when}'**
  String ruleNext(String when);

  /// Rule status pill.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạm dừng'**
  String get rulePaused;

  /// Rule status pill: rang, unanswered.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ · {time}'**
  String ruleDueNow(String time);

  /// Rule status pill.
  ///
  /// In vi, this message translates to:
  /// **'Báo lại lúc {time}'**
  String ruleSnoozedUntil(String time);

  /// Rule status pill: no anchor (or asleep).
  ///
  /// In vi, this message translates to:
  /// **'Chờ lần ghi tiếp theo'**
  String get ruleWaiting;

  /// 1a line under the list.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận: {names}'**
  String ruleRecipientsLine(String names);

  /// Recipient list word for yourself.
  ///
  /// In vi, this message translates to:
  /// **'bạn'**
  String get ruleYou;

  /// 1a primary.
  ///
  /// In vi, this message translates to:
  /// **'Thêm nhắc'**
  String get ruleAdd;

  /// 1a empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhắc theo quy tắc'**
  String get ruleEmpty;

  /// 1a empty body.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: nhắc bú 3 giờ sau lần bú gần nhất, cho cả nhà.'**
  String get ruleEmptyBody;

  /// 1a note for caregivers.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ đặt nhắc; bạn nhận những nhắc được giao cho mình.'**
  String get ruleCaregiverNote;

  /// Activity noun.
  ///
  /// In vi, this message translates to:
  /// **'lần bú'**
  String get ruleActFeed;

  /// Activity noun.
  ///
  /// In vi, this message translates to:
  /// **'giấc ngủ'**
  String get ruleActSleep;

  /// Activity noun.
  ///
  /// In vi, this message translates to:
  /// **'lần thay tã'**
  String get ruleActDiaper;

  /// Activity noun.
  ///
  /// In vi, this message translates to:
  /// **'lần hút sữa'**
  String get ruleActPump;

  /// 1h banner.
  ///
  /// In vi, this message translates to:
  /// **'{who} đã ghi {activity} lúc {time} · nhắc tiếp theo {next}'**
  String ruleHandled(String who, String activity, String time, String next);

  /// 1h banner without a next time.
  ///
  /// In vi, this message translates to:
  /// **'{who} đã ghi {activity} lúc {time}'**
  String ruleHandledNoNext(String who, String activity, String time);

  /// 1b title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc mới'**
  String get ruleNewTitle;

  /// Edit title.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhắc'**
  String get ruleEditTitle;

  /// 1b question.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn nhắc việc gì?'**
  String get ruleWhat;

  /// 1b option.
  ///
  /// In vi, this message translates to:
  /// **'Bú'**
  String get ruleTypeFeed;

  /// 1b option.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get ruleTypeSleep;

  /// 1b option.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get ruleTypeDiaper;

  /// 1b option.
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa'**
  String get ruleTypePump;

  /// 1b section.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhắc'**
  String get ruleHow;

  /// 1b radio.
  ///
  /// In vi, this message translates to:
  /// **'Sau lần ghi gần nhất'**
  String get ruleModeAfter;

  /// 1b radio hint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 3 giờ sau lần bú gần nhất'**
  String get ruleModeAfterHint;

  /// 1b radio.
  ///
  /// In vi, this message translates to:
  /// **'Giờ cố định'**
  String get ruleModeFixed;

  /// 1b radio hint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 09:00, 13:00, 19:30 mỗi ngày'**
  String get ruleModeFixedHint;

  /// 1b–1c primary.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get ruleContinue;

  /// 1c / 1d step.
  ///
  /// In vi, this message translates to:
  /// **'Bước {step}/3'**
  String ruleStep(int step);

  /// 1c card label.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc sau mỗi'**
  String get ruleEvery;

  /// 1c caption.
  ///
  /// In vi, this message translates to:
  /// **'tính từ lần bú gần nhất (bú bình hoặc bú mẹ)'**
  String get ruleCountedFeed;

  /// 1c caption.
  ///
  /// In vi, this message translates to:
  /// **'tính từ lúc bé thức dậy'**
  String get ruleCountedSleep;

  /// 1c caption.
  ///
  /// In vi, this message translates to:
  /// **'tính từ lần thay tã gần nhất'**
  String get ruleCountedDiaper;

  /// 1c caption.
  ///
  /// In vi, this message translates to:
  /// **'tính từ lần hút sữa gần nhất'**
  String get ruleCountedPump;

  /// 1c preview title.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ hôm nay'**
  String get ruleExample;

  /// 1c preview verb.
  ///
  /// In vi, this message translates to:
  /// **'Bú'**
  String get ruleExFeed;

  /// 1c preview verb.
  ///
  /// In vi, this message translates to:
  /// **'Dậy'**
  String get ruleExSleep;

  /// 1c preview verb.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get ruleExDiaper;

  /// 1c preview verb.
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa'**
  String get ruleExPump;

  /// 1c preview line.
  ///
  /// In vi, this message translates to:
  /// **'{act} lúc {from} → nhắc lúc {to}'**
  String ruleExampleLine(String act, String from, String to);

  /// 1c preview without a log.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lần ghi nào: nhắc bắt đầu sau lần ghi đầu tiên.'**
  String get ruleExampleNone;

  /// 1c preview note.
  ///
  /// In vi, this message translates to:
  /// **'Ghi {activity} mới thì giờ nhắc tự lùi theo.'**
  String ruleExampleShift(String activity);

  /// 1c row.
  ///
  /// In vi, this message translates to:
  /// **'Không nhắc ban đêm'**
  String get ruleQuiet;

  /// 1c row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'22:00 – 06:00'**
  String get ruleQuietRange;

  /// 1c row and sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ngày áp dụng'**
  String get ruleDays;

  /// All seven days.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày'**
  String get ruleEveryDay;

  /// 1c2 card.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc mỗi ngày'**
  String get ruleTimesTitle;

  /// 1c2 label (sleep).
  ///
  /// In vi, this message translates to:
  /// **'Giấc sáng'**
  String get ruleSlotMorningNap;

  /// 1c2 label (sleep).
  ///
  /// In vi, this message translates to:
  /// **'Giấc trưa'**
  String get ruleSlotMiddayNap;

  /// 1c2 label (sleep).
  ///
  /// In vi, this message translates to:
  /// **'Giấc chiều'**
  String get ruleSlotAfternoonNap;

  /// 1c2 label (sleep).
  ///
  /// In vi, this message translates to:
  /// **'Giấc đêm'**
  String get ruleSlotNightSleep;

  /// 1c2 label.
  ///
  /// In vi, this message translates to:
  /// **'Buổi sáng'**
  String get ruleSlotMorning;

  /// 1c2 label.
  ///
  /// In vi, this message translates to:
  /// **'Buổi trưa'**
  String get ruleSlotMidday;

  /// 1c2 label.
  ///
  /// In vi, this message translates to:
  /// **'Buổi chiều'**
  String get ruleSlotAfternoon;

  /// 1c2 label.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tối'**
  String get ruleSlotEvening;

  /// 1c2 add row.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giờ'**
  String get ruleAddTime;

  /// 1c2 a11y.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {time}'**
  String ruleRemoveTime(String time);

  /// 1c2 duplicate.
  ///
  /// In vi, this message translates to:
  /// **'Giờ này đã có trong danh sách.'**
  String get ruleTimeExists;

  /// 1c2 section.
  ///
  /// In vi, this message translates to:
  /// **'Ngày trong tuần'**
  String get ruleWeek;

  /// 1c2 banner.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc theo giờ của bé ({zone}). Khi đi xa, giờ nhắc vẫn giữ theo nơi bé ở.'**
  String ruleZoneNote(String zone);

  /// 1d title.
  ///
  /// In vi, this message translates to:
  /// **'Ai sẽ nhận nhắc?'**
  String get ruleWho;

  /// 1d role.
  ///
  /// In vi, this message translates to:
  /// **'Bố mẹ'**
  String get ruleRoleParent;

  /// 1d role.
  ///
  /// In vi, this message translates to:
  /// **'Người chăm'**
  String get ruleRoleCaregiver;

  /// 1d role, not selectable.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · chỉ xem'**
  String get ruleRoleViewOnly;

  /// 1d banner.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bố mẹ và người chăm nhận được nhắc. Ai ghi hoạt động trước, nhắc sẽ tự tắt với mọi người.'**
  String get ruleWhoNote;

  /// 1d summary.
  ///
  /// In vi, this message translates to:
  /// **'cả ngày'**
  String get ruleAllDay;

  /// 1d summary.
  ///
  /// In vi, this message translates to:
  /// **'trừ ban đêm'**
  String get ruleNotAtNight;

  /// 1d summary.
  ///
  /// In vi, this message translates to:
  /// **'{count} người nhận'**
  String ruleRecipients(int count);

  /// 1d primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu nhắc'**
  String get ruleSave;

  /// 1d validation.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một người nhận.'**
  String get ruleNeedRecipient;

  /// 1e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc bú'**
  String get ruleSavedFeed;

  /// 1e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc chuẩn bị ngủ'**
  String get ruleSavedSleep;

  /// 1e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc thay tã'**
  String get ruleSavedDiaper;

  /// 1e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu nhắc hút sữa'**
  String get ruleSavedPump;

  /// Callable failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Kiểm tra mạng rồi thử lại.'**
  String get ruleSaveFailed;

  /// 1f / 1g.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ nhắc bú bạn đã đặt'**
  String get ruleDueFeed;

  /// 1f / 1g.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ nhắc chuẩn bị ngủ bạn đã đặt'**
  String get ruleDueSleep;

  /// 1f / 1g.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ nhắc thay tã bạn đã đặt'**
  String get ruleDueDiaper;

  /// 1f / 1g.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ nhắc hút sữa bạn đã đặt'**
  String get ruleDuePump;

  /// 1g banner label.
  ///
  /// In vi, this message translates to:
  /// **'Lần bú gần nhất'**
  String get ruleLastFeed;

  /// 1g banner label.
  ///
  /// In vi, this message translates to:
  /// **'Bé dậy lúc'**
  String get ruleLastSleep;

  /// 1g banner label.
  ///
  /// In vi, this message translates to:
  /// **'Lần thay gần nhất'**
  String get ruleLastDiaper;

  /// 1g banner label.
  ///
  /// In vi, this message translates to:
  /// **'Lần hút sữa gần nhất'**
  String get ruleLastPump;

  /// 1f / 1g primary.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lần bú'**
  String get ruleLogFeed;

  /// 1f / 1g primary.
  ///
  /// In vi, this message translates to:
  /// **'Ghi giấc ngủ'**
  String get ruleLogSleep;

  /// 1f / 1g primary.
  ///
  /// In vi, this message translates to:
  /// **'Ghi thay tã'**
  String get ruleLogDiaper;

  /// 1f / 1g primary.
  ///
  /// In vi, this message translates to:
  /// **'Ghi hút sữa'**
  String get ruleLogPump;

  /// 1g label.
  ///
  /// In vi, this message translates to:
  /// **'Báo lại sau'**
  String get ruleSnoozeIn;

  /// 1f / 1g.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua lần này'**
  String get ruleSkip;

  /// 1g when another recipient answered.
  ///
  /// In vi, this message translates to:
  /// **'Đã có người xử lý nhắc này.'**
  String get ruleAlreadyHandled;

  /// 1g snooze toast.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ nhắc lại lúc {time}'**
  String ruleSnoozedToast(String time);

  /// 1g skip toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ qua lần này'**
  String get ruleSkippedToast;

  /// 1h section.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get ruleRecent;

  /// 1h empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lần nhắc nào.'**
  String get ruleRecentEmpty;

  /// 1h row.
  ///
  /// In vi, this message translates to:
  /// **'{time} · Đã ghi'**
  String ruleOutLogged(String time);

  /// 1h row.
  ///
  /// In vi, this message translates to:
  /// **'{time} · Báo lại {minutes} phút'**
  String ruleOutSnoozed(String time, int minutes);

  /// 1h row.
  ///
  /// In vi, this message translates to:
  /// **'{time} · Bỏ qua'**
  String ruleOutSkipped(String time);

  /// 1h row.
  ///
  /// In vi, this message translates to:
  /// **'{time} · Chưa ai xử lý'**
  String ruleOutMissed(String time);

  /// 1h row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{who} ghi {what}'**
  String ruleOutLoggedBy(String who, String what);

  /// Rule detail action.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhắc'**
  String get ruleEdit;

  /// Rule detail action.
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhắc'**
  String get ruleDelete;

  /// Delete confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {title}?'**
  String ruleDeleteTitle(String title);

  /// Delete confirm body.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người nhận sẽ thôi được nhắc.'**
  String get ruleDeleteBody;

  /// Delete confirm button.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get ruleDeleteConfirm;

  /// Delete toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá nhắc'**
  String get ruleDeleted;

  /// ReminderPeek label on Hôm nay (128:665, 370:1248 "Nhắc việc · 3").
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc'**
  String get reminderPeekTitle;

  /// SH Ảnh · Xem theo (391:2761) title.
  ///
  /// In vi, this message translates to:
  /// **'Xem ảnh theo'**
  String get photoByTitle;

  /// Grouping option.
  ///
  /// In vi, this message translates to:
  /// **'Tuần tuổi'**
  String get photoByWeek;

  /// Grouping option caption.
  ///
  /// In vi, this message translates to:
  /// **'Tuần 1, tuần 2… hợp với năm đầu đời'**
  String get photoByWeekSub;

  /// Grouping option.
  ///
  /// In vi, this message translates to:
  /// **'Tháng tuổi'**
  String get photoByAgeMonth;

  /// Grouping option caption.
  ///
  /// In vi, this message translates to:
  /// **'1 tháng, 2 tháng…'**
  String get photoByAgeMonthSub;

  /// Grouping option.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trong năm'**
  String get photoByMonth;

  /// Grouping option caption.
  ///
  /// In vi, this message translates to:
  /// **'Tháng 10, tháng 9…'**
  String get photoByMonthSub;

  /// 10b grouping pill.
  ///
  /// In vi, this message translates to:
  /// **'Theo tuần tuổi'**
  String get photoPillWeek;

  /// 10b grouping pill.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng tuổi'**
  String get photoPillAgeMonth;

  /// 10b grouping pill.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get photoPillMonth;

  /// SH Ảnh · Loại (391:2888) title.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị'**
  String get photoShowTitle;

  /// Type option and pill.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh & video'**
  String get photoShowAll;

  /// Type option and pill.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh'**
  String get photoShowPhotos;

  /// Type option and pill.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ video'**
  String get photoShowVideos;

  /// Type option and pill.
  ///
  /// In vi, this message translates to:
  /// **'Đã yêu thích'**
  String get photoShowFavorites;

  /// SH Ảnh · Chọn tuần (391:3028) title.
  ///
  /// In vi, this message translates to:
  /// **'Đi tới tuần'**
  String get photoGotoWeek;

  /// Jump sheet title, month of age.
  ///
  /// In vi, this message translates to:
  /// **'Đi tới tháng tuổi'**
  String get photoGotoAgeMonth;

  /// Section title, month of age.
  ///
  /// In vi, this message translates to:
  /// **'Tháng thứ {month}'**
  String photoAgeMonth(int month);

  /// Scrubber pill.
  ///
  /// In vi, this message translates to:
  /// **'Tuần {week}'**
  String photoScrubWeek(int week);

  /// Scrubber pill, month of age.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}'**
  String photoScrubAgeMonth(int month);

  /// Select a whole week / month of age.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả'**
  String get photoSelectSection;

  /// Widget gallery name (camera shortcut).
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh bé'**
  String get glanceGalleryCameraName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Mở camera để chụp ảnh hoặc quay video, rồi lưu vào Kỷ niệm.'**
  String get glanceGalleryCameraBlurb;

  /// Widget gallery name (photo-library shortcut).
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ Ảnh'**
  String get glanceGalleryLibraryName;

  /// Widget gallery description.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh, video trong máy để lưu vào Kỷ niệm.'**
  String get glanceGalleryLibraryBlurb;

  /// Camera widget title.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh, quay video'**
  String get glanceMemCamera;

  /// Photo-library widget title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ Ảnh'**
  String get glanceMemLibrary;

  /// Widget subtitle: the baby.
  ///
  /// In vi, this message translates to:
  /// **'Vào Kỷ niệm của {name}'**
  String glanceMemFor(String name);

  /// Chăm sóc tile (394:4451).
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng'**
  String get vxTile;

  /// Tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mũi tiếp theo {date}'**
  String vxTileNext(String date);

  /// Tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} mũi quá hạn'**
  String vxTileOverdue(int count);

  /// Tile subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiêm đủ theo lịch'**
  String get vxTileAllDone;

  /// Tile subtitle before setup.
  ///
  /// In vi, this message translates to:
  /// **'Ghi các mũi đã tiêm'**
  String get vxTileSetup;

  /// VX 1 title.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng'**
  String get vxTitle;

  /// VX 1 next card.
  ///
  /// In vi, this message translates to:
  /// **'Mũi tiếp theo · {date} · {left}'**
  String vxNextLine(String date, String left);

  /// Days to go.
  ///
  /// In vi, this message translates to:
  /// **'còn {count} ngày'**
  String vxDaysLeft(int count);

  /// Due today.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get vxDueToday;

  /// VX 9 next card.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn {count} ngày · dự kiến {date}'**
  String vxOverdueLine(int count, String date);

  /// After a list of vaccines with the same dose.
  ///
  /// In vi, this message translates to:
  /// **'(mũi {n})'**
  String vxDoseSuffix(int n);

  /// One dose.
  ///
  /// In vi, this message translates to:
  /// **'{name} mũi {n}'**
  String vxDoseOf(String name, int n);

  /// View pill and option.
  ///
  /// In vi, this message translates to:
  /// **'Theo vắc xin'**
  String get vxViewByVaccine;

  /// View pill and option.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng tuổi'**
  String get vxViewByAge;

  /// Counter.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiêm {given} / {total} mũi'**
  String vxCount(int given, int total);

  /// Status.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiêm'**
  String get vxLegendGiven;

  /// Status.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get vxLegendUpcoming;

  /// Status.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get vxLegendOverdue;

  /// Status.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tới'**
  String get vxLegendLater;

  /// Status (VX 9a).
  ///
  /// In vi, this message translates to:
  /// **'Không tiêm'**
  String get vxLegendDeclined;

  /// Under a later dot.
  ///
  /// In vi, this message translates to:
  /// **'{months} th'**
  String vxMonthsShort(int months);

  /// Age 0.
  ///
  /// In vi, this message translates to:
  /// **'Sơ sinh'**
  String get vxBirth;

  /// Age block.
  ///
  /// In vi, this message translates to:
  /// **'{months} tháng'**
  String vxMonths(int months);

  /// VX 2 title.
  ///
  /// In vi, this message translates to:
  /// **'{months} tháng tuổi'**
  String vxMonthsOld(int months);

  /// Milestone label.
  ///
  /// In vi, this message translates to:
  /// **'Mốc sơ sinh'**
  String get vxMilestoneBirth;

  /// Milestone label.
  ///
  /// In vi, this message translates to:
  /// **'Mốc {months} tháng tuổi'**
  String vxMilestone(int months);

  /// Milestone chip.
  ///
  /// In vi, this message translates to:
  /// **'Mốc {months} tháng'**
  String vxMilestoneShort(int months);

  /// Matrix row hint.
  ///
  /// In vi, this message translates to:
  /// **'{list} tháng'**
  String vxHintMonths(String list);

  /// Flu hint.
  ///
  /// In vi, this message translates to:
  /// **'hằng năm'**
  String get vxHintYearly;

  /// VX 1 banner.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào một mũi để ghi đã tiêm hoặc xem chi tiết. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ.'**
  String get vxBannerMatrix;

  /// VX 1b banner.
  ///
  /// In vi, this message translates to:
  /// **'Tích vào ô khi bé đã tiêm — app sẽ hỏi ngày và nơi tiêm. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ.'**
  String get vxBannerTimeline;

  /// VX 9 card.
  ///
  /// In vi, this message translates to:
  /// **'{count} mũi đã quá ngày dự kiến. Nếu bé đã tiêm, hãy tích để cập nhật; nếu chưa, đặt lại lịch với cơ sở tiêm.'**
  String vxOverdueCard(int count);

  /// No DOB.
  ///
  /// In vi, this message translates to:
  /// **'Cần ngày sinh của {name} để lập lịch tiêm.'**
  String vxNoDob(String name);

  /// No DOB body.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ thêm ngày sinh trong hồ sơ bé.'**
  String get vxNoDobBody;

  /// VX 1a title.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch tiêm theo'**
  String get vxViewTitle;

  /// VX 1a option.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi loại một dòng, thấy ngay mũi nào còn thiếu'**
  String get vxViewByVaccineSub;

  /// VX 1a option.
  ///
  /// In vi, this message translates to:
  /// **'Từng mốc tuổi tiêm gì, tích khi đã tiêm'**
  String get vxViewByAgeSub;

  /// Given without a date.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi ngày'**
  String get vxNoDate;

  /// VX 0 title.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã tiêm những mũi nào?'**
  String vxSetupTitle(String name);

  /// VX 0 body.
  ///
  /// In vi, this message translates to:
  /// **'Tích các mũi bé đã tiêm từ lúc sinh. Không nhớ ngày cũng không sao — bạn có thể bổ sung sau.'**
  String get vxSetupBody;

  /// VX 0 row.
  ///
  /// In vi, this message translates to:
  /// **'Sơ sinh · thường tiêm tại bệnh viện'**
  String get vxSetupAtHospital;

  /// VX 0 hepatitis B row.
  ///
  /// In vi, this message translates to:
  /// **'Trong 24 giờ đầu'**
  String get vxSetupFirstDay;

  /// VX 0 row for an older baby.
  ///
  /// In vi, this message translates to:
  /// **'{age} · dự kiến {date}'**
  String vxSetupDue(String age, String date);

  /// VX 0 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu {count} mũi đã tiêm'**
  String vxSetupSave(int count);

  /// VX 0 primary with nothing ticked.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get vxSetupContinue;

  /// VX 0 plain.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua, làm sau'**
  String get vxSetupSkip;

  /// VX 2 line.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {date} · {left}'**
  String vxPlannedLeft(String date, String left);

  /// VX 2 / 9a line.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {date} · đã quá {count} ngày'**
  String vxPlannedOverdue(String date, int count);

  /// VX 2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một trong hai'**
  String get vxChooseOne;

  /// VX 2 option.
  ///
  /// In vi, this message translates to:
  /// **'6in1 · Dịch vụ'**
  String get vx6in1Title;

  /// VX 2 option.
  ///
  /// In vi, this message translates to:
  /// **'Bạch hầu, ho gà, uốn ván, bại liệt, Hib, viêm gan B — một mũi'**
  String get vx6in1Body;

  /// VX 2 pill.
  ///
  /// In vi, this message translates to:
  /// **'Có phí'**
  String get vxPaid;

  /// VX 2 option.
  ///
  /// In vi, this message translates to:
  /// **'5in1 + Bại liệt · Trạm y tế'**
  String get vx5in1Title;

  /// VX 2 option.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng mở rộng, uống/tiêm thêm bại liệt'**
  String get vx5in1Body;

  /// VX 2 pill.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get vxFree;

  /// VX 2 list.
  ///
  /// In vi, this message translates to:
  /// **'Các mũi'**
  String get vxShots;

  /// VX 2 list after the choice.
  ///
  /// In vi, this message translates to:
  /// **'Các mũi khác'**
  String get vxOtherShots;

  /// VX 2 / 7 pill.
  ///
  /// In vi, this message translates to:
  /// **'Ghi'**
  String get vxLog;

  /// Route.
  ///
  /// In vi, this message translates to:
  /// **'Uống'**
  String get vxRouteOral;

  /// Route.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm'**
  String get vxRouteInjection;

  /// Programme.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng mở rộng'**
  String get vxProgEpi;

  /// Programme.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get vxProgService;

  /// Programme.
  ///
  /// In vi, this message translates to:
  /// **'Bệnh viện'**
  String get vxProgHospital;

  /// Programme.
  ///
  /// In vi, this message translates to:
  /// **'6in1 dịch vụ hoặc 5in1 miễn phí'**
  String get vxProgChoice;

  /// Programme label for a schedule outside Việt Nam (D-084).
  ///
  /// In vi, this message translates to:
  /// **'Chương trình quốc gia'**
  String get vxProgNational;

  /// Recommended but often paid, outside Việt Nam (D-084).
  ///
  /// In vi, this message translates to:
  /// **'Khuyến nghị, có thể tự chi trả'**
  String get vxProgRecommended;

  /// Sổ tiêm chủng note when the family's country has its own schedule (D-084).
  ///
  /// In vi, this message translates to:
  /// **'Theo {programme}, cập nhật {date}. Lịch của bé có thể khác tuỳ bác sĩ hoặc vùng nơi bạn sống.'**
  String vxCountryNotice(String programme, String date);

  /// VX 2 toggle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước 3 ngày'**
  String get vxRemind;

  /// VX 2 toggle subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn người nhận'**
  String get vxRemindNobody;

  /// Recipients sheet.
  ///
  /// In vi, this message translates to:
  /// **'Ai nhận nhắc lịch tiêm?'**
  String get vxRecipientsTitle;

  /// VX 2 row.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lịch hẹn'**
  String get vxAppointment;

  /// VX 2 row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt ngày hẹn'**
  String get vxAppointmentNone;

  /// VX 2 row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn {date}'**
  String vxAppointmentOn(String date);

  /// VX 2 banner.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi bác sĩ hoặc nhân viên y tế để chọn loại vắc xin phù hợp với bé.'**
  String get vxAskDoctor;

  /// Row status.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiêm {date}'**
  String vxGivenOn(String date);

  /// VX 3 title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi mũi tiêm'**
  String get vxRecordTitle;

  /// Edit title.
  ///
  /// In vi, this message translates to:
  /// **'Sửa mũi tiêm'**
  String get vxEditTitle;

  /// Field.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tiêm'**
  String get vxDate;

  /// Field.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get vxTime;

  /// Time not set.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ'**
  String get vxTimeNone;

  /// Field.
  ///
  /// In vi, this message translates to:
  /// **'Nơi tiêm'**
  String get vxPlace;

  /// Place.
  ///
  /// In vi, this message translates to:
  /// **'Bệnh viện'**
  String get vxPlaceHospital;

  /// Place.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get vxPlaceService;

  /// Place.
  ///
  /// In vi, this message translates to:
  /// **'Trạm y tế'**
  String get vxPlaceStation;

  /// Field.
  ///
  /// In vi, this message translates to:
  /// **'Tên cơ sở (không bắt buộc)'**
  String get vxFacility;

  /// Placeholder.
  ///
  /// In vi, this message translates to:
  /// **'VD: Trung tâm tiêm chủng gần nhà'**
  String get vxFacilityHint;

  /// Field.
  ///
  /// In vi, this message translates to:
  /// **'Phản ứng sau tiêm (không bắt buộc)'**
  String get vxReaction;

  /// Placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Sốt nhẹ, quấy hơn…'**
  String get vxReactionHint;

  /// VX 3 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mũi tiêm'**
  String get vxSave;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {dose}'**
  String vxSaved(String dose);

  /// VX 4 toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {dose} · mũi {n} dự kiến {date}'**
  String vxSavedNext(String dose, int n, String date);

  /// Write failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại nhé.'**
  String get vxSaveFailed;

  /// VX 5 title.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiêm {dose}'**
  String vxQuickTitle(String dose);

  /// VX 5.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm ngày nào?'**
  String get vxWhichDay;

  /// VX 5 chip.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get vxDayToday;

  /// VX 5 chip.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get vxDayYesterday;

  /// VX 5 chip.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get vxPickDay;

  /// VX 5.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm ở đâu?'**
  String get vxWhere;

  /// VX 5 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get vxQuickSave;

  /// VX 5 plain.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi tiết (phản ứng, ảnh sổ tiêm)'**
  String get vxMoreDetails;

  /// VX 6.
  ///
  /// In vi, this message translates to:
  /// **'Người ghi'**
  String get vxRecordedBy;

  /// VX 6.
  ///
  /// In vi, this message translates to:
  /// **'Phản ứng'**
  String get vxReactionShort;

  /// VX 6 card.
  ///
  /// In vi, this message translates to:
  /// **'Mũi {n} dự kiến {date}'**
  String vxNextDose(int n, String date);

  /// VX 6 card.
  ///
  /// In vi, this message translates to:
  /// **'đã bật nhắc'**
  String get vxReminderOn;

  /// VX 6 card.
  ///
  /// In vi, this message translates to:
  /// **'chưa bật nhắc'**
  String get vxReminderOff;

  /// VX 6.
  ///
  /// In vi, this message translates to:
  /// **'Xoá mũi tiêm này'**
  String get vxDelete;

  /// Confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {dose}?'**
  String vxDeleteTitle(String dose);

  /// Confirm.
  ///
  /// In vi, this message translates to:
  /// **'Mũi này sẽ trở lại chưa tiêm.'**
  String get vxDeleteBody;

  /// Confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get vxDeleteConfirm;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {dose}'**
  String vxDeleted(String dose);

  /// Declined detail.
  ///
  /// In vi, this message translates to:
  /// **'Lý do'**
  String get vxReason;

  /// Declined detail.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ đánh dấu không tiêm'**
  String get vxUndoDecline;

  /// Rescheduled dose.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ lịch hẹn'**
  String get vxUndoReschedule;

  /// Given without a date.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày tiêm'**
  String get vxAddDate;

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'{count} mũi'**
  String vxDoseCount(int count);

  /// VX 7 oral.
  ///
  /// In vi, this message translates to:
  /// **'{count} liều'**
  String vxDoseCountOral(int count);

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Số mũi'**
  String get vxDoses;

  /// VX 7 oral.
  ///
  /// In vi, this message translates to:
  /// **'Số liều'**
  String get vxDosesOral;

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Thời điểm'**
  String get vxTiming;

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'{list} tháng tuổi'**
  String vxTimingValue(String list);

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng cách'**
  String get vxInterval;

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu {weeks} tuần giữa các mũi'**
  String vxIntervalValue(int weeks);

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Cách dùng'**
  String get vxRoute;

  /// VX 7.
  ///
  /// In vi, this message translates to:
  /// **'Các mũi của {name}'**
  String vxBabyDoses(String name);

  /// VX 7 row.
  ///
  /// In vi, this message translates to:
  /// **'Mũi {n}'**
  String vxDoseN(int n);

  /// VX 7 row.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {date}'**
  String vxPlannedOn(String date);

  /// VX 7 banner.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin tham khảo. Hỏi bác sĩ nếu bạn còn băn khoăn.'**
  String get vxInfoBanner;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã tiêm rồi'**
  String get vxAlreadyGiven;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Ghi ngày và nơi tiêm'**
  String get vxAlreadyGivenSub;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Dời lịch'**
  String get vxReschedule;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày hẹn mới, app nhắc lại trước 1 ngày'**
  String get vxRescheduleSub;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Không tiêm mũi này'**
  String get vxDecline;

  /// VX 9a.
  ///
  /// In vi, this message translates to:
  /// **'Theo tư vấn của bác sĩ · có thể ghi lý do'**
  String get vxDeclineSub;

  /// VX 9a banner.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi cơ sở tiêm chủng hoặc bác sĩ để được hướng dẫn lịch tiêm bù phù hợp.'**
  String get vxCatchUp;

  /// Decline sheet.
  ///
  /// In vi, this message translates to:
  /// **'Không tiêm {dose}'**
  String vxDeclineTitle(String dose);

  /// Decline sheet.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (không bắt buộc)'**
  String get vxDeclineReasonHint;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi không tiêm {dose}'**
  String vxDeclined(String dose);

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã dời {dose} sang {date}'**
  String vxRescheduled(String dose, String date);

  /// Date sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get vxPickDateTitle;

  /// Relative tap.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ xem được sổ tiêm.'**
  String get vxViewOnly;

  /// Tile subtitle without dates.
  ///
  /// In vi, this message translates to:
  /// **'Sổ tiêm chủng của bé'**
  String get vxTileBook;

  /// VX 3 dashed chip.
  ///
  /// In vi, this message translates to:
  /// **'Chụp sổ tiêm / phiếu tiêm'**
  String get vxPhotoTake;

  /// VX 0 dashed card.
  ///
  /// In vi, this message translates to:
  /// **'Chụp sổ tiêm chủng để lưu lại'**
  String get vxPhotoBook;

  /// VX 6 label; thumbnail semantics.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh sổ tiêm'**
  String get vxPhoto;

  /// VX 1 section with the book photos from setup.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh sổ tiêm chủng'**
  String get vxBookPhotos;

  /// Source sheet title; add tile.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh sổ tiêm'**
  String get vxPhotoAdd;

  /// Dashed chip while uploading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh lên…'**
  String get vxPhotoUploading;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được ảnh. Thử lại nhé.'**
  String get vxPhotoFailed;

  /// Corner × on a thumbnail.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get vxPhotoRemove;

  /// Viewer action (Cùng nuôi).
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh'**
  String get vxPhotoDelete;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá ảnh'**
  String get vxPhotoDeleted;

  /// Source sheet note.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người chăm bé trong gia đình xem được. Không hiện trong Kỷ niệm.'**
  String get vxPhotoPrivate;

  /// Hồ sơ bé / Chọn bé row opening 15 Nhập mã mời.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời'**
  String get joinFromProfile;

  /// Under the row.
  ///
  /// In vi, this message translates to:
  /// **'Được mời chăm một bé khác? Nhập mã 6 số trong lời mời.'**
  String get joinFromProfileHint;

  /// Family tab / setup: invites mailed to the signed-in person's email (owner, 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời cho bạn'**
  String get myInvitesTitle;

  /// An invite card: who invites and for which baby.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} mời bạn cùng chăm bé {baby}'**
  String myInviteLine(String inviter, String baby);

  /// An invite card: the role offered and the expiry date.
  ///
  /// In vi, this message translates to:
  /// **'{role} · Hết hạn {date}'**
  String myInviteMeta(String role, String date);

  /// Accepts an invite without the code (then relation and name, as 16 → 16a).
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get myInviteAccept;

  /// Declines an invite mailed to me.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get myInviteDecline;

  /// Decline confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối lời mời chăm bé {baby}?'**
  String myInviteDeclineTitle(String baby);

  /// Decline confirmation body.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} sẽ biết lời mời không còn chờ nữa. Mã và link mời sẽ hết hiệu lực.'**
  String myInviteDeclineBody(String inviter);

  /// Toast after declining.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời chăm bé {baby}'**
  String myInviteDeclined(String baby);

  /// Sign-in options: opens 15 Nhập mã mời (owner, 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'Tôi có mã mời'**
  String get signInHaveCode;

  /// Family tab: confirm before revoking a pending invite.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ lời mời này?'**
  String get familyRevokeTitle;

  /// Family tab: what revoking does.
  ///
  /// In vi, this message translates to:
  /// **'Mã và link đã gửi cho {who} sẽ không dùng được nữa.'**
  String familyRevokeBody(String who);

  /// Chọn bé / Hồ sơ các bé: invites mailed to me, each with a red dot (owner, 2026-10-11).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đang chờ bạn'**
  String get myInvitesPending;

  /// The sheet for one invite mailed to me.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời cùng chăm bé'**
  String get myInviteSheetTitle;

  /// Under Đồng ý / Từ chối.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý xong, {baby} sẽ có trong danh sách bé của bạn.'**
  String myInviteSheetHint(String baby);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get spTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{amount} tháng này'**
  String spTileMonth(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi tháng này'**
  String get spTileEmpty;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản đã chi'**
  String get spTileRecord;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{value} tr'**
  String spMillions(String value);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'đồng'**
  String get spCurrencyName;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ'**
  String get spCurrency;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Chọn tiền tệ'**
  String get spCurrencyTitle;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đổi tiền tệ, đang là {code}'**
  String spCurrencyPick(String code);

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ chính'**
  String get spCurrencyMain;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Mặc định khi thêm khoản chi; tổng, thống kê và ngân sách tính theo tiền tệ này. Khoản chi bằng tiền tệ khác được ghi riêng, không quy đổi.'**
  String get spCurrencyMainSub;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi tiền tệ chính'**
  String get spCurrencyMainSaved;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Ngoài ra: {amounts}'**
  String spAlsoSpent(String amounts);

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Không cộng vào tổng (tiền tệ khác): {amounts}'**
  String spOtherCurrenciesNote(String amounts);

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách tính các khoản chi bằng {code}.'**
  String spBudgetCurrencyNote(String code);

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách đang lưu theo {old}. Đặt lại số tiền rồi lưu để tính theo {code}.'**
  String spBudgetOldCurrency(String old, String code);

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đồng Việt Nam'**
  String get spCurVND;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Mỹ'**
  String get spCurUSD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Euro'**
  String get spCurEUR;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Bảng Anh'**
  String get spCurGBP;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Úc'**
  String get spCurAUD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Canada'**
  String get spCurCAD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la New Zealand'**
  String get spCurNZD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Singapore'**
  String get spCurSGD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Yên Nhật'**
  String get spCurJPY;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Won Hàn Quốc'**
  String get spCurKRW;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Đài Loan'**
  String get spCurTWD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Baht Thái'**
  String get spCurTHB;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Đô la Hồng Kông'**
  String get spCurHKD;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Nhân dân tệ'**
  String get spCurCNY;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Franc Thuỵ Sĩ'**
  String get spCurCHF;

  /// Chi tiêu currencies (D-075 #4).
  ///
  /// In vi, this message translates to:
  /// **'Ringgit Malaysia'**
  String get spCurMYR;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Giữ trẻ & học'**
  String get spCatChildcare;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Sữa & ăn dặm'**
  String get spCatMilk;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tã & vệ sinh'**
  String get spCatDiaper;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Y tế & tiêm chủng'**
  String get spCatHealth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Quần áo'**
  String get spCatClothes;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get spCatOther;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get spToday;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get spYesterday;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date}'**
  String spDayToday(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua · {date}'**
  String spDayYesterday(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay, {date}'**
  String spDateToday(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua, {date}'**
  String spDateYesterday(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get spPayerOther;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{payer} trả'**
  String spPaidBy(String payer);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{payer} trả'**
  String spPays(String payer);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'từ Tiêm chủng'**
  String get spFromVaccines;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'định kỳ'**
  String get spFromRecurring;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản định kỳ'**
  String get spFromRecurringFull;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day} hằng tháng'**
  String spScheduleMonthly(int day);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {a} và {b} hằng tháng'**
  String spScheduleMonthlyTwo(int a, int b);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{n, plural, =1{Mỗi tuần} other{Mỗi {n} tuần}}'**
  String spScheduleWeeks(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date} hằng năm'**
  String spScheduleYearly(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ'**
  String get spPending;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Có hoá đơn'**
  String get spHasReceipt;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu của bé chỉ cha mẹ xem. Nhờ Cùng nuôi cấp quyền trong Gia đình nếu bạn cần ghi.'**
  String get spNoAccess;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại chi tiêu cho {name}'**
  String spFirstTitle(String name);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Biết mỗi tháng tốn bao nhiêu cho sữa, tã, tiêm chủng, giữ trẻ. Chỉ cha mẹ thấy, có thể chia sẻ cho người khác.'**
  String get spFirstBody;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi các khoản bạn đã chi cho bé. Bạn chỉ thấy những khoản do mình ghi.'**
  String get spFirstBodyRecorder;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh trong vài giây'**
  String get spFirstPoint1;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thống kê theo tháng, danh mục, người trả'**
  String get spFirstPoint2;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách và khoản định kỳ'**
  String get spFirstPoint3;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản chi đầu tiên'**
  String get spFirstAdd;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đặt ngân sách'**
  String get spFirstBudget;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản chi'**
  String get spAdd;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ thấy các khoản do mình ghi, không thấy tổng hay khoản của người khác.'**
  String get spOwnOnlyNote;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản bạn đã ghi'**
  String get spMine;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get spPrevMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get spNextMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month} · {year}'**
  String spMonthLabel(int month, int year);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}'**
  String spMonthShort(int month, int year);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đến {date}'**
  String spUpTo(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã chi cho {name}'**
  String spSpentOn(String name);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get spStats;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get spBudget;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Định kỳ'**
  String get spRecurring;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Theo danh mục'**
  String get spByCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xem thống kê'**
  String get spSeeStats;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản chi nào trong tháng này.'**
  String get spMonthEmpty;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{n} khoản'**
  String spItems(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Gồm {n} mũi tiêm'**
  String spIncludesShots(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get spRecent;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get spSeeAll;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ cha mẹ thấy chi tiêu. Có thể cấp quyền cho người khác trong Gia đình.'**
  String get spParentsOnly;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Cha mẹ đã chia sẻ chi tiêu của bé với bạn.'**
  String get spSharedWithYou;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{share} ngân sách {total}'**
  String spBudgetShare(String share, String total);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount}'**
  String spLeft(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Vượt {amount}'**
  String spOverBy(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Trung bình/ngày'**
  String get spAvgPerDay;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bằng'**
  String get spSame;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thấp hơn {share}'**
  String spLower(String share);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Cao hơn {share}'**
  String spHigher(String share);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'So với tháng {month}'**
  String spComparedWith(int month);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tất cả khoản chi'**
  String get spAllTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tìm khoản chi…'**
  String get spSearch;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Mọi tháng'**
  String get spAllMonths;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng'**
  String get spFilterMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tất cả danh mục'**
  String get spAllCategories;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ai cũng được'**
  String get spAnyone;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản chi nào.'**
  String get spNothingYet;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản chi nào khớp.'**
  String get spNoMatch;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi này không còn.'**
  String get spGone;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get spCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get spDate;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ai trả'**
  String get spPayer;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi bởi'**
  String get spRecordedBy;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nguồn'**
  String get spSource;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Liên kết'**
  String get spLink;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lịch tiêm chủng · {dose}'**
  String spLinkVaccine(String dose);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hoá đơn'**
  String get spReceiptTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem ảnh lớn'**
  String get spReceiptOpen;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xoá khoản chi'**
  String get spDelete;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá khoản chi'**
  String get spDeleted;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản chi'**
  String get spAddTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản chi'**
  String get spEditTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get spAmount;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lần trước {amount}'**
  String spLastTime(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get spEditCategories;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get spAddCategoryChip;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get spNote;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Sữa công thức ×2'**
  String get spNoteHint;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hoá đơn'**
  String get spReceipt;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã đính kèm · chạm để xem'**
  String get spReceiptAttached;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh hoá đơn'**
  String get spReceiptRemove;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh hoá đơn'**
  String get spReceiptAdd;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người xem được chi tiêu thấy ảnh này.'**
  String get spReceiptPrivate;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại hằng tháng'**
  String get spRepeatMonthly;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tự thêm ngày {day} mỗi tháng'**
  String spRepeatMonthlyOn(int day);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lưu khoản chi'**
  String get spSave;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu khoản chi'**
  String get spSaved;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật khoản chi'**
  String get spUpdated;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền'**
  String get spAmountMissing;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại sau.'**
  String get spSaveFailed;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi chi phí mũi tiêm?'**
  String get spVaccineTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Chi tiêu, danh mục Y tế & tiêm chủng. Có thể bỏ qua.'**
  String get spVaccineBody;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Chi tiêu'**
  String get spVaccineSave;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu chi phí mũi tiêm'**
  String get spVaccineSaved;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get spSkip;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get spCategories;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Kéo để sắp xếp. Danh mục dùng chung cho mọi bé trong gia đình.'**
  String get spCategoriesIntro;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get spCategoriesInUse;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn'**
  String get spCategoriesHidden;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Mặc định · không xoá được'**
  String get spCategoryLocked;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tự tạo · {n} khoản'**
  String spCategoryCustom(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ẩn khỏi danh sách chọn · vẫn giữ {n} khoản cũ'**
  String spCategoryHiddenSub(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hiện lại'**
  String get spShowAgain;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Kéo để sắp xếp'**
  String get spDragHandle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục'**
  String get spAddCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục mới'**
  String get spNewCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get spEditCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get spCategoryName;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Bơi & vận động'**
  String get spCategoryNamePlaceholder;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 24 ký tự'**
  String get spCategoryNameHelp;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên danh mục'**
  String get spCategoryNameMissing;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã có danh mục tên này'**
  String get spCategoryNameTaken;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get spCategoryIcon;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get spCategoryColor;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Màu {n}'**
  String spColorN(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lưu danh mục'**
  String get spSaveCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ẩn danh mục'**
  String get spHideCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn danh mục'**
  String get spCategoryHiddenToast;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xoá danh mục'**
  String get spDeleteCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xoá “{name}”?'**
  String spDeleteCategoryTitle(String name);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục này có {n} khoản chi ({amount}). Chọn nơi chuyển các khoản này:'**
  String spDeleteCategoryBody(int n, String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Danh mục này chưa có khoản chi nào của bé. Khoản của bé khác (nếu có) sẽ được chuyển sang:'**
  String get spDeleteCategoryEmpty;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang “Khác”'**
  String get spMoveToOther;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Giữ nguyên tổng chi tiêu'**
  String get spMoveToOtherSub;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang danh mục khác'**
  String get spMoveToAnother;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục'**
  String get spChooseCategory;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Muốn giữ số liệu cũ mà không thấy danh mục khi ghi? Hãy chọn Ẩn thay vì Xoá.'**
  String get spHideInstead;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xoá và chuyển {n} khoản'**
  String spDeleteAndMove(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ẩn danh mục thay vì xoá'**
  String get spHideCategoryInstead;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá danh mục'**
  String get spCategoryDeleted;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Cần kết nối mạng để xoá danh mục.'**
  String get spNeedsNetwork;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách tháng'**
  String get spBudgetTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đặt mức dự kiến để dễ theo dõi. Có thể bỏ trống danh mục.'**
  String get spBudgetIntro;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách mỗi tháng'**
  String get spBudgetPerMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}: đã dùng {share}'**
  String spBudgetUsed(int month, String share);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt mức'**
  String get spNoCap;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ mức này'**
  String get spClearCap;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{share} đã dùng'**
  String spUsedShare(String share);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Gần chạm mức · còn {amount}'**
  String spNearCap(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Vượt mức {amount}'**
  String spOverCap(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc khi dùng 80% ngân sách'**
  String get spAlert80;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Gửi cho cha mẹ'**
  String get spAlert80Sub;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lưu ngân sách'**
  String get spSaveBudget;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ngân sách'**
  String get spBudgetSaved;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản định kỳ'**
  String get spRecurringTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tự thêm vào chi tiêu đúng ngày. Cha mẹ nhận thông báo và có thể sửa số tiền sau đó.'**
  String get spRecurringIntro;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản định kỳ. Thêm tiền giữ trẻ, sữa hay bảo hiểm để khỏi phải ghi lại mỗi lần.'**
  String get spRecurringEmpty;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date}: {title} {amount} sẽ được thêm. Bạn có thể sửa số tiền sau khi thêm.'**
  String spRecurringNext(String date, String title, String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản định kỳ'**
  String get spAddRecurring;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản định kỳ'**
  String get spEditRecurring;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tên khoản'**
  String get spRecurringName;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Cô giữ trẻ'**
  String get spRecurringNameHint;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên khoản'**
  String get spRecurringTitleMissing;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại'**
  String get spSchedule;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hằng tháng'**
  String get spKindMonthly;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Theo tuần'**
  String get spKindWeeks;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Hằng năm'**
  String get spKindYearly;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày trong tháng'**
  String get spScheduleDays;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chọn 1 hoặc 2 ngày. Tháng ngắn hơn sẽ dùng ngày cuối tháng.'**
  String get spScheduleDaysHelp;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu từ'**
  String get spStartOn;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get spScheduleOn;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get spRecurringOn;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản được thêm tự động vào ngày đến hạn, theo giờ của bé.'**
  String get spRecurringHelp;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xoá khoản định kỳ'**
  String get spDeleteRecurring;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu khoản định kỳ'**
  String get spRecurringSaved;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá khoản định kỳ'**
  String get spRecurringDeleted;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Bớt'**
  String get spLess;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get spMore;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Thống kê chi tiêu'**
  String get spStatsTitle;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get spWindowMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'6 tháng'**
  String get spWindowSix;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Từ khi sinh'**
  String get spWindowBirth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tổng tháng này'**
  String get spMonthTotal;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi'**
  String get spCount;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tổng 6 tháng'**
  String get spSixTotal;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'TB mỗi tháng'**
  String get spAvgPerMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Cao nhất · T{month}'**
  String spHighest(int month);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get spByMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'T{month} đang tính đến {date}'**
  String spCountedTo(int month, String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'T{month}'**
  String spMonthTick(int month);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'TB {amount}'**
  String spAvgLine(String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'{label} · {amount}'**
  String spTip(String label, String amount);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get spOthersFolded;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Từ khi {name} chào đời · {months} tháng'**
  String spSinceBirth(String name, int months);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Từ khoản chi đầu tiên'**
  String get spSinceFirst;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Trung bình {amount} mỗi tháng tuổi · {n} khoản chi'**
  String spSinceBirthSub(String amount, int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng tuổi'**
  String get spByAge;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng đầu'**
  String get spFirstMonth;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tháng tuổi {n}'**
  String spAgeMonth(int n);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Khoản lớn nhất'**
  String get spLargest;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xuất file chi tiêu (CSV)'**
  String get spExport;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'chi-tieu-{date}'**
  String spExportFile(String date);

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chưa xuất được file. Thử lại sau.'**
  String get spExportFailed;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Số liệu chỉ để gia đình tự theo dõi, không so sánh với gia đình khác.'**
  String get spOwnFamilyOnly;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản đã chi'**
  String get rightRecordSpending;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thấy khoản do mình ghi'**
  String get rightRecordSpendingHint;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Xem toàn bộ chi tiêu'**
  String get rightViewSpending;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Tổng, thống kê, mọi khoản chi'**
  String get rightViewSpendingHint;

  /// Chi tiêu (v1.1 8a–8o).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu mặc định chỉ cha mẹ thấy. Người được bật “Ghi khoản đã chi” sẽ không thấy tổng hay khoản của người khác.'**
  String get rightSpendingNote;

  /// Chi tiêu (v1.1 8e), under a month old.
  ///
  /// In vi, this message translates to:
  /// **'Từ khi {name} chào đời'**
  String spSinceBirthYoung(String name);

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh'**
  String get sectionQuickActions;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở, chi tiêu, mũi tiêm, kỷ niệm'**
  String get sectionQuickActionsSub;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Mũi tiêm sắp tới'**
  String get sectionVaccine;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Từ sổ tiêm chủng của bé'**
  String get sectionVaccineSub;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu tháng này'**
  String get sectionSpending;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Tổng tháng so với ngân sách'**
  String get sectionSpendingSub;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get quickReminder;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get quickExpense;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Mũi tiêm'**
  String get quickVaccine;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get quickMemory;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhắc việc mới'**
  String get quickReminderHint;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản đã chi'**
  String get quickExpenseHint;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Mở sổ tiêm chủng'**
  String get quickVaccineHint;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, video, nhật ký'**
  String get quickMemoryHint;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'{n} mũi · chạm để xem'**
  String todayVaccineShots(int n);

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Mở sổ tiêm chủng'**
  String get todayVaccineOpen;

  /// Tuỳ chỉnh Hôm nay, opt-in parts (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt ngân sách tháng'**
  String get todaySpendingNoBudget;

  /// Tài khoản → Xuất dữ liệu row once the file is ready (download only from the email).
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi link tải qua email · hết hạn {when}'**
  String acExportEmailed(String when);

  /// 7a entry banner on Chăm sóc.
  ///
  /// In vi, this message translates to:
  /// **'Sơ cứu trẻ em'**
  String get faEntryTitle;

  /// 7a banner subline.
  ///
  /// In vi, this message translates to:
  /// **'{count} tình huống · dùng khi không có mạng'**
  String faEntrySub(int count);

  /// 7b title.
  ///
  /// In vi, this message translates to:
  /// **'Sơ cứu'**
  String get faTitle;

  /// 7b subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bình tĩnh, làm theo từng bước. Dùng được cả khi không có mạng.'**
  String get faSubtitle;

  /// 7b emergency card.
  ///
  /// In vi, this message translates to:
  /// **'Bé không thở, tím tái hoặc bất tỉnh?'**
  String get faEmergencyQuestion;

  /// Red call buttons.
  ///
  /// In vi, this message translates to:
  /// **'Gọi {number}'**
  String faCall(String number);

  /// Sơ cứu call bar when the family lives outside Việt Nam: the number and the country.
  ///
  /// In vi, this message translates to:
  /// **'Gọi {number} · {country}'**
  String faCallLocal(String number, String country);

  /// Sổ tiêm chủng notice for a family living outside Việt Nam (D-078).
  ///
  /// In vi, this message translates to:
  /// **'Lịch này theo chương trình tiêm chủng của Việt Nam. Ở {country}, hãy theo lịch của bác sĩ hoặc cơ sở y tế nơi bạn sống; nhắc lịch chỉ báo những mũi bạn đã đặt ngày.'**
  String vxAbroadNotice(String country);

  /// 7b emergency card.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hồi sức tim phổi (CPR)'**
  String get faStartCpr;

  /// 7b / 7c search placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Hóc, sốt, bỏng, khó thở…'**
  String get faSearchHint;

  /// 7b filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get faAll;

  /// 7b first section subline.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo tuổi {name} · {age}'**
  String faSortedFor(String name, String age);

  /// Saved situations screen title; bookmark a11y.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get faSaved;

  /// Saved screen empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu tình huống nào. Bấm dấu trang trên một tình huống để lưu lại đây.'**
  String get faSavedEmpty;

  /// Bookmark a11y.
  ///
  /// In vi, this message translates to:
  /// **'Lưu tình huống'**
  String get faSave;

  /// Bookmark a11y when saved.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lưu'**
  String get faUnsave;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào Sơ cứu · Đã lưu'**
  String get faSavedToast;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ lưu'**
  String get faUnsavedToast;

  /// 7c result count.
  ///
  /// In vi, this message translates to:
  /// **'{count} tình huống'**
  String faResults(int count);

  /// 7c chips header.
  ///
  /// In vi, this message translates to:
  /// **'Tìm nhanh'**
  String get faQuickSearch;

  /// 7c no results.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tình huống phù hợp. Bé gặp nguy hiểm: gọi {number}.'**
  String faNoResults(String number);

  /// Detail tag.
  ///
  /// In vi, this message translates to:
  /// **'Dùng được khi không có mạng'**
  String get faOffline;

  /// Detail tag (TH21, TH24).
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi'**
  String get faMonitoring;

  /// Detail section header.
  ///
  /// In vi, this message translates to:
  /// **'Làm theo các bước'**
  String get faFollowSteps;

  /// Detail footer (no review claimed until one is recorded, P-141).
  ///
  /// In vi, this message translates to:
  /// **'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.'**
  String get faDisclaimer;

  /// Detail footer once a review is recorded.
  ///
  /// In vi, this message translates to:
  /// **'Được {reviewer} rà soát tháng {month}.'**
  String faReviewed(String reviewer, String month);

  /// TH04 timer card.
  ///
  /// In vi, this message translates to:
  /// **'Bấm giờ cơn giật'**
  String get faSeizureTimer;

  /// TH04 timer.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get faTimerStart;

  /// TH04 timer.
  ///
  /// In vi, this message translates to:
  /// **'Dừng'**
  String get faTimerStop;

  /// TH04 timer after stopping.
  ///
  /// In vi, this message translates to:
  /// **'Bấm lại'**
  String get faTimerReset;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trình gọi điện. Hãy bấm số {number} trên điện thoại.'**
  String faCallFailed(String number);

  /// 7h baby row weight.
  ///
  /// In vi, this message translates to:
  /// **'{kg} kg'**
  String faWeightKg(String kg);

  /// Unknown situation id.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hướng dẫn này. Mở lại Sơ cứu.'**
  String get faNotFound;

  /// Bottom bar (normal pages).
  ///
  /// In vi, this message translates to:
  /// **'Đọc to hướng dẫn'**
  String get faReadAloud;

  /// Speaker button a11y (emergency pages).
  ///
  /// In vi, this message translates to:
  /// **'Đọc to'**
  String get faReadAloudShort;

  /// Bottom bar while reading.
  ///
  /// In vi, this message translates to:
  /// **'Dừng đọc'**
  String get faStopReading;

  /// Static count label on a step (was tap-to-count).
  ///
  /// In vi, this message translates to:
  /// **'× {count} lần'**
  String faCountTimes(int count);

  /// Green bar after dialling (7h revision 2).
  ///
  /// In vi, this message translates to:
  /// **'Đang gọi {number} · {time}'**
  String faCalling(String number, String time);

  /// 7h card.
  ///
  /// In vi, this message translates to:
  /// **'Nói với tổng đài'**
  String get faTellOperator;

  /// 7h card row.
  ///
  /// In vi, this message translates to:
  /// **'Bé'**
  String get faTellBaby;

  /// 7h card row.
  ///
  /// In vi, this message translates to:
  /// **'Tình trạng'**
  String get faTellCondition;

  /// TH01 metronome card.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp ép đang phát · tự động'**
  String get faMetronomeTitle;

  /// TH01 metronome while the guide is read aloud.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp ép tạm dừng trong lúc đọc'**
  String get faMetronomePaused;

  /// TH01 metronome card body.
  ///
  /// In vi, this message translates to:
  /// **'Bật loa, đặt điện thoại cạnh bé. Ép theo tiếng bíp. Sau mỗi {count} lần, app đọc “thổi ngạt {breaths} lần”.'**
  String faMetronomeBody(int count, int breaths);

  /// Spoken after each set of compressions.
  ///
  /// In vi, this message translates to:
  /// **'Thổi ngạt {count} lần'**
  String faSayBreaths(int count);

  /// Spoken while reading a step aloud.
  ///
  /// In vi, this message translates to:
  /// **'Bước {n}. {title}. {body}'**
  String faSpeakStep(int n, String title, String body);

  /// Dock tab replacing Gia đình (450:6597).
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích'**
  String get tabUtilities;

  /// Tiện ích title.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích'**
  String get utTitle;

  /// Chi tiêu row (full amount).
  ///
  /// In vi, this message translates to:
  /// **'Tháng này {amount}'**
  String utSpendingMonth(String amount);

  /// Chi tiêu row for someone allowed to record (450:6873).
  ///
  /// In vi, this message translates to:
  /// **'Khoản tôi đã chi'**
  String get utMySpending;

  /// Row subline (who granted it is not stored).
  ///
  /// In vi, this message translates to:
  /// **'Bạn được phép ghi khoản chi'**
  String get utMySpendingSub;

  /// Gia đình row.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên & chia sẻ'**
  String get utMembers;

  /// Members row subline.
  ///
  /// In vi, this message translates to:
  /// **'{count} người'**
  String utMembersCount(int count);

  /// Members row subline, after the count.
  ///
  /// In vi, this message translates to:
  /// **'{count} lời mời đang chờ'**
  String utMembersPending(int count);

  /// Members row for caregivers and relatives.
  ///
  /// In vi, this message translates to:
  /// **'Xem thành viên gia đình'**
  String get utMembersView;

  /// Gia đình row (Cùng nuôi).
  ///
  /// In vi, this message translates to:
  /// **'Mời người thân'**
  String get utInvite;

  /// Invite row subline.
  ///
  /// In vi, this message translates to:
  /// **'Ông bà, người chăm cùng theo dõi bé'**
  String get utInviteSub;

  /// While an invite link joins.
  ///
  /// In vi, this message translates to:
  /// **'Đang nhận lời mời…'**
  String get inviteLinkJoining;

  /// Toast after joining from a link.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã cùng chăm {baby}. Đổi tên trong Gia đình.'**
  String inviteLinkJoined(String baby);

  /// Name given when joining from a link (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Người thân'**
  String get inviteLinkDefaultName;

  /// App version at the bottom of Tôi, e.g. "1.0.0 (12) · dev".
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}'**
  String meVersion(String version);

  /// UP1 title (469:6476).
  ///
  /// In vi, this message translates to:
  /// **'Cần cập nhật để tiếp tục'**
  String get upRequiredTitle;

  /// UP1 body (469:6477).
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản này đã cũ và không còn đồng bộ an toàn với cả nhà. Cập nhật mất khoảng 1 phút.'**
  String get upRequiredBody;

  /// UP1 reassurance row.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của bé vẫn an toàn'**
  String get upSafeTitle;

  /// UP1 reassurance row, second line.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, nhật ký và lịch sử chăm sóc được giữ nguyên'**
  String get upSafeBody;

  /// UP1: uploads still on this phone.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần ghi chưa đồng bộ'**
  String upPendingTitle(int count);

  /// UP1 pending row, second line.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ tự gửi lên ngay sau khi cập nhật'**
  String get upPendingBody;

  /// UP1 button on iOS.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật trên App Store'**
  String get upOpenAppStore;

  /// UP1 button on Android.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật trên Google Play'**
  String get upOpenPlay;

  /// UP1 link to the release pages.
  ///
  /// In vi, this message translates to:
  /// **'Có gì mới trong {version}'**
  String upWhatsNewIn(String version);

  /// UP2 tag.
  ///
  /// In vi, this message translates to:
  /// **'Mới · {version}'**
  String upNewTag(String version);

  /// UP2 title.
  ///
  /// In vi, this message translates to:
  /// **'Child Life có bản mới'**
  String get upNewTitle;

  /// UP2 button; UP6 tag.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get upUpdate;

  /// UP2 secondary action.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get upLater;

  /// UP3/UP4 tag on the picture.
  ///
  /// In vi, this message translates to:
  /// **'Mới trong {version}'**
  String upPageTag(String version);

  /// UP3/UP4 top right.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get upSkip;

  /// UP3/UP4 button.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get upNext;

  /// UP3/UP4 button on the last page.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get upPagesDone;

  /// UP3/UP4 page dots, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Trang {page} trên {count}'**
  String upPageOf(int page, int count);

  /// UP5 banner title.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật {version}'**
  String upBannerTitle(String version);

  /// UP5 banner action.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get upBannerSee;

  /// UP5 close button, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Đóng thông báo cập nhật'**
  String get upBannerClose;

  /// UP6 Tôi · Phiên bản subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Có bản mới {version}'**
  String upNewVersion(String version);

  /// UP6 subtitle when up to date.
  ///
  /// In vi, this message translates to:
  /// **'Đây là bản mới nhất'**
  String get upLatestVersion;

  /// Toast when the store link is missing or fails.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được trang cập nhật. Thử lại sau nhé.'**
  String get upNoStore;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ app khác hoặc Excel'**
  String get spFirstImport;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'nhập từ tệp'**
  String get spFromImport;

  /// Expense row subline: saved by the Assistant from a receipt (source assistant, D-075 #3/#4).
  ///
  /// In vi, this message translates to:
  /// **'từ Trợ lý'**
  String get spFromAssistant;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Nhập chi tiêu · xem lần nhập'**
  String get spFromImportFull;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Nhập chi tiêu'**
  String get imTitle;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Mang chi tiêu từ app khác, bảng tính hoặc sổ tay vào Chi tiêu của {name}. Bạn xem trước rồi mới nhập.'**
  String imIntro(String name);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Cùng nuôi được nhập chi tiêu.'**
  String get imParentsOnly;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tệp CSV hoặc Excel'**
  String get imSourceFile;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Money Lover, MISA, Google Sheets, Excel… tự nhận cột'**
  String get imSourceFileHint;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Dán văn bản'**
  String get imSourceText;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú, tin nhắn, danh sách — AI tách thành từng khoản'**
  String get imSourceTextHint;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chụp sổ chi tiêu'**
  String get imSourcePhotos;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 5 ảnh — AI đọc từng dòng'**
  String get imSourcePhotosHint;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Văn bản và ảnh được gửi tới dịch vụ AI chỉ để đọc, không lưu lại; tên bé không được gửi. Tệp tải lên tự xoá sau 7 ngày.'**
  String get imPrivacy;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Các lần nhập'**
  String get imRecent;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đang đọc dữ liệu…'**
  String get imBusyReading;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'AI đang đọc, có thể mất nửa phút…'**
  String get imBusyAi;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Mỗi khoản một dòng, ví dụ: “12/10 sữa công thức 1.020.000 mẹ trả”.'**
  String get imPasteHint;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Dán nội dung ở đây'**
  String get imPastePlaceholder;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đọc nội dung'**
  String get imRead;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Xem trước'**
  String get imReviewTitle;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} khoản trùng'**
  String imDuplicates(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} khoản thu'**
  String imIncome(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} dòng lỗi'**
  String imErrors(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Cột trong tệp'**
  String get imColumns;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không có'**
  String get imColumnNone;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Ngày viết theo kiểu'**
  String get imDateOrder;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Ngày/Tháng/Năm'**
  String get imDateDmy;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tháng/Ngày/Năm'**
  String get imDateMdy;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi là các dòng'**
  String get imRowsAre;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Số âm'**
  String get imRowsNegative;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Số dương'**
  String get imRowsPositive;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get imRowsAll;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua khoản đã có'**
  String get imSkipDuplicates;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Cùng ngày, số tiền và nội dung'**
  String get imSkipDuplicatesHint;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{name} · {n} khoản'**
  String imSourceRows(String name, int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới “{name}”'**
  String imNewCategory(String name);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Nhập {n} khoản'**
  String imConfirm(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản nào để nhập'**
  String get imNothingToImport;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Thiếu ngày'**
  String get imIssueNoDate;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được ngày'**
  String get imIssueBadDate;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Ngày trong tương lai'**
  String get imIssueFutureDate;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Thiếu số tiền'**
  String get imIssueNoAmount;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không hợp lệ'**
  String get imIssueBadAmount;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Số tiền quá lớn'**
  String get imIssueTooLarge;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không phải tiền Việt'**
  String get imIssueCurrency;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu, bỏ qua'**
  String get imIssueIncome;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã có, bỏ qua'**
  String get imIssueDuplicate;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'AI chưa sẵn sàng. Hãy dùng tệp CSV hoặc Excel.'**
  String get imFailAiUnavailable;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'AI chưa đọc được nội dung này. Thử ảnh rõ hơn hoặc dán văn bản.'**
  String get imFailAi;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy khoản chi nào trong dữ liệu.'**
  String get imFailEmpty;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tệp quá lớn (tối đa 10 MB, 5.000 dòng).'**
  String get imFailTooBig;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Cần kết nối mạng để nhập.'**
  String get imFailOffline;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập được. Thử lại sau.'**
  String get imFailGeneric;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tệp .xls cũ chưa đọc được. Hãy lưu thành .xlsx hoặc CSV rồi thử lại.'**
  String get imReadOldExcel;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp CSV hoặc Excel (.xlsx).'**
  String get imReadUnsupported;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Không mở được tệp này.'**
  String get imReadBroken;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đang đọc'**
  String get imStatusAnalyzing;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chờ bạn xem trước'**
  String get imStatusReady;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đang nhập'**
  String get imStatusImporting;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {n} khoản'**
  String imStatusDone(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập được'**
  String get imStatusFailed;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tác'**
  String get imStatusUndone;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục xem trước'**
  String get imContinueReview;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đang nhập chi tiêu…'**
  String get imImporting;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{done} / {total} khoản'**
  String imProgress(int done, int total);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể đóng app. Child Life sẽ gửi email và thông báo khi xong.'**
  String get imCanClose;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {n} khoản'**
  String imDone(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua: {details}.'**
  String imSkipped(String details);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Kết quả cũng đã được gửi qua email.'**
  String get imEmailSent;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiêu'**
  String get imSeeSpending;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Dòng không nhập'**
  String get imIssues;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Dòng {n}'**
  String imRow(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập được chi tiêu'**
  String get imFailedTitle;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get imTryAgain;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tác lần nhập này'**
  String get imUndoneTitle;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác lần nhập?'**
  String get imUndoTitle;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} khoản đã nhập sẽ bị xoá khỏi Chi tiêu, kể cả khoản đã sửa sau đó.'**
  String imUndoBody(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Xoá {n} khoản'**
  String imUndoConfirm(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {n} khoản đã nhập'**
  String imUndone(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Vào: {name}'**
  String imInto(String name);

  /// UP1: the offline Sơ cứu guide stays reachable while blocked (owner, 2026-10-12).
  ///
  /// In vi, this message translates to:
  /// **'Sơ cứu'**
  String get upFirstAid;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình'**
  String get watchTileBottle;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ'**
  String get watchTileBreast;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get watchTileSleep;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Tã'**
  String get watchTileDiaper;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Hút sữa'**
  String get watchTilePump;

  /// Watch W01 tile title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc'**
  String get watchTileReminder;

  /// Watch W01 tile caption under the time since the last feed.
  ///
  /// In vi, this message translates to:
  /// **'từ cữ trước'**
  String get watchSinceFeed;

  /// Watch W01 tile caption (diaper, pump).
  ///
  /// In vi, this message translates to:
  /// **'từ lần trước'**
  String get watchSinceLast;

  /// Watch W01 sleep tile caption while a sleep runs.
  ///
  /// In vi, this message translates to:
  /// **'đang ngủ'**
  String get watchSleeping;

  /// Watch W01 sleep tile caption after waking (engineering, not drawn).
  ///
  /// In vi, this message translates to:
  /// **'đã thức'**
  String get watchAwake;

  /// Watch W01 reminder tile caption.
  ///
  /// In vi, this message translates to:
  /// **'nhắc bú'**
  String get watchFeedReminder;

  /// Watch W01 tile caption when nothing is logged (engineering, G-093).
  ///
  /// In vi, this message translates to:
  /// **'chưa ghi'**
  String get watchNoneYet;

  /// Watch W11 night list: time since the last entry.
  ///
  /// In vi, this message translates to:
  /// **'{t} trước'**
  String watchAgo(String t);

  /// Watch W01 last row, opens W12.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bé'**
  String get watchChooseBabyRow;

  /// Watch W02 under the amount.
  ///
  /// In vi, this message translates to:
  /// **'ml · xoay núm để chỉnh'**
  String get watchCrownHint;

  /// Watch W02 / W08 primary button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get watchSave;

  /// Watch breast start screen (engineering, G-094).
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu bên nào?'**
  String get watchBreastStartHint;

  /// Watch W03 side card.
  ///
  /// In vi, this message translates to:
  /// **'Trái'**
  String get watchSideLeft;

  /// Watch W03 side card.
  ///
  /// In vi, this message translates to:
  /// **'Phải'**
  String get watchSideRight;

  /// Watch breast start: the side opposite the last feed (engineering).
  ///
  /// In vi, this message translates to:
  /// **'gợi ý'**
  String get watchSuggested;

  /// Watch W03 caption.
  ///
  /// In vi, this message translates to:
  /// **'Tổng {t} · đang bú bên trái'**
  String watchBreastTotalLeft(String t);

  /// Watch W03 caption.
  ///
  /// In vi, this message translates to:
  /// **'Tổng {t} · đang bú bên phải'**
  String watchBreastTotalRight(String t);

  /// Watch W03 button.
  ///
  /// In vi, this message translates to:
  /// **'Đổi bên'**
  String get watchSwitchSide;

  /// Watch W03 button.
  ///
  /// In vi, this message translates to:
  /// **'Dừng'**
  String get watchStop;

  /// Watch W04 under the sleep timer.
  ///
  /// In vi, this message translates to:
  /// **'từ {time}'**
  String watchSleepSince(String time);

  /// Watch W04 button.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã dậy'**
  String get watchWokeUp;

  /// Watch W05 title.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get watchDiaperTitle;

  /// Watch W05 button.
  ///
  /// In vi, this message translates to:
  /// **'Ướt'**
  String get watchDiaperWet;

  /// Watch W05 button.
  ///
  /// In vi, this message translates to:
  /// **'Bẩn'**
  String get watchDiaperDirty;

  /// Watch W05 button.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai'**
  String get watchDiaperBoth;

  /// Watch W06 title.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi tã ướt'**
  String get watchLoggedWet;

  /// Watch W06 title (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi tã bẩn'**
  String get watchLoggedDirty;

  /// Watch W06 title (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi tã ướt và bẩn'**
  String get watchLoggedBoth;

  /// Watch W06 title (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi bú bình {ml} ml'**
  String watchLoggedBottle(String ml);

  /// Watch W06 title (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi cữ bú mẹ'**
  String get watchLoggedBreast;

  /// Watch W06 title (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi giấc ngủ'**
  String get watchLoggedSleep;

  /// Watch W06 line under the title (R-022).
  ///
  /// In vi, this message translates to:
  /// **'{time} · {name} ghi'**
  String watchLoggedBy(String time, String name);

  /// Watch W06 button.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get watchUndo;

  /// Watch save refused (engineering, G-097).
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại sau.'**
  String get watchFailed;

  /// Watch W12 title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bé'**
  String get watchChooseBaby;

  /// Watch W12 note while the phone sends one baby (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đổi sang bé khác trên iPhone.'**
  String get watchOneBabyNote;

  /// Watch W13 banner.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trên đồng hồ. Sẽ gửi lên khi có mạng.'**
  String get watchOffline;

  /// Watch W13 row.
  ///
  /// In vi, this message translates to:
  /// **'{n} lần ghi chờ gửi'**
  String watchPending(String n);

  /// Watch first run, not linked yet (engineering, G-092).
  ///
  /// In vi, this message translates to:
  /// **'Kết nối iPhone'**
  String get watchLinkTitle;

  /// Watch first run body (engineering, G-092).
  ///
  /// In vi, this message translates to:
  /// **'Mở Child Life trên iPhone và đăng nhập, đồng hồ sẽ tự kết nối.'**
  String get watchLinkBody;

  /// Watch empty state for a member who cannot log (engineering, G-093).
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có bé nào để ghi trên đồng hồ.'**
  String get watchCannotLog;

  /// Watch first run, debug builds only: opens sample data.
  ///
  /// In vi, this message translates to:
  /// **'Xem thử'**
  String get watchDemo;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Tổng {amount}'**
  String imTotal(String amount);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Từ {from} đến {to}'**
  String imDays(String from, String to);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Đã tự nhận các cột'**
  String get imReadingAuto;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Tệp {name}'**
  String imReadingPreset(String name);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'số âm là khoản chi'**
  String get imReadingNegative;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'số dương là khoản chi'**
  String get imReadingPositive;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'lấy cả số âm và số dương'**
  String get imReadingAllSigns;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'ngày/tháng/năm'**
  String get imReadingDmy;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'tháng/ngày/năm'**
  String get imReadingMdy;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh'**
  String get imAdjust;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Cách đọc tệp'**
  String get imAdjustTitle;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua {n} dòng'**
  String imSkippedRows(int n);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Các dòng này không được nhập. Sửa trong tệp rồi nhập lại nếu cần.'**
  String get imSkippedExplain;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Và {n} dòng khác'**
  String imSkippedMore(int n);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Xếp vào danh mục'**
  String get imCategoriesTitle;

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Xếp “{name}” vào'**
  String imCategoryFor(String name);

  /// Nhập chi tiêu (D-060), review.
  ///
  /// In vi, this message translates to:
  /// **'Một vài khoản sẽ nhập'**
  String get imSamples;

  /// Nhập chi tiêu (D-060), under the count.
  ///
  /// In vi, this message translates to:
  /// **'khoản chi sẵn sàng nhập'**
  String imReadyLabel(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} mục chưa có trong Chi tiêu sẽ được tạo thành danh mục mới. Chạm để đổi.'**
  String imCategoriesNewHint(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get imBadgeNew;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả {n}'**
  String imSeeAll(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'{n} khoản sẽ nhập'**
  String imAllTitle(int n);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Trang {page}/{pages}'**
  String imPageOf(int page, int pages);

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Trang trước'**
  String get imPagePrev;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Trang sau'**
  String get imPageNext;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác lần nhập'**
  String get imUndoAction;

  /// Nhập chi tiêu (D-060).
  ///
  /// In vi, this message translates to:
  /// **'Có thể hoàn tác đến {time} ngày {date} (còn {days} ngày)'**
  String imUndoUntil(String time, String date, int days);

  /// 07a title (368:1144)
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get emailSignInTitle;

  /// 07a primary button (368:1153); also the link in 07c's footer
  ///
  /// In vi, this message translates to:
  /// **'Gửi link đăng nhập'**
  String get emailLinkSend;

  /// 07b title (368:1198)
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra email của bạn'**
  String get linkSentTitle;

  /// 07b body (368:1199)
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi link đăng nhập đến {email}. Mở link trên điện thoại này trong 15 phút để vào app.'**
  String linkSentBody(String email);

  /// 07b banner (368:1205)
  ///
  /// In vi, this message translates to:
  /// **'Không thấy email? Xem thư mục Quảng cáo hoặc Spam.'**
  String get linkSentSpam;

  /// 07b primary button (368:1207)
  ///
  /// In vi, this message translates to:
  /// **'Mở ứng dụng Mail'**
  String get linkSentOpenMail;

  /// 07b countdown (368:1211), time as m:ss
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại sau {time}'**
  String linkSentResendIn(String time);

  /// 07b resend once the countdown ends
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get linkSentResend;

  /// Toast after resending (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lại link.'**
  String get linkSentResent;

  /// 07b plain button (368:1216)
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get linkSentChangeEmail;

  /// Opening a sign-in link (not drawn, G-001)
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập…'**
  String get linkOpenSigningIn;

  /// Link opened without the address on this device (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận email'**
  String get linkConfirmTitle;

  /// Link opened without the address on this device (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã nhận link để đăng nhập trên máy này.'**
  String get linkConfirmBody;

  /// Expired or used sign-in link (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Link đã hết hạn'**
  String get linkExpiredTitle;

  /// Expired or used sign-in link (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Link đăng nhập dùng được một lần, trong 15 phút. Gửi link mới để vào app.'**
  String get linkExpiredBody;

  /// Expired sign-in link: back to 07a
  ///
  /// In vi, this message translates to:
  /// **'Gửi link mới'**
  String get linkExpiredButton;

  /// FB1 row (477:6398)
  ///
  /// In vi, this message translates to:
  /// **'Góp ý cho Child Life'**
  String get meFeedback;

  /// FB1 row subtitle
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi, đề xuất tính năng'**
  String get meFeedbackHint;

  /// FB1 row: opens the store page (user-initiated)
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá trên App Store'**
  String get meRateAppStore;

  /// FB1 row on Android
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá trên Google Play'**
  String get meRatePlay;

  /// FB1 rate row before the app is published (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa có trên cửa hàng ứng dụng.'**
  String get meRateUnavailable;

  /// FB2 title (477:6493)
  ///
  /// In vi, this message translates to:
  /// **'Góp ý'**
  String get fbTitle;

  /// FB2 intro
  ///
  /// In vi, this message translates to:
  /// **'Đội ngũ Child Life đọc từng góp ý. Cảm ơn bạn đã giúp app tốt hơn cho các gia đình.'**
  String get fbIntro;

  /// FB2 chip
  ///
  /// In vi, this message translates to:
  /// **'Ý tưởng'**
  String get fbTypeIdea;

  /// FB2 chip; FB4 button
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi'**
  String get fbTypeBug;

  /// FB2 chip
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get fbTypeOther;

  /// FB2 field label
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn chia sẻ điều gì?'**
  String get fbMessageLabel;

  /// FB2 attachment tile
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chụp màn hình'**
  String get fbScreenshot;

  /// FB2 attached screenshot: remove (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get fbScreenshotRemove;

  /// FB2 toggle
  ///
  /// In vi, this message translates to:
  /// **'Gửi kèm thông tin thiết bị'**
  String get fbDevice;

  /// FB2 toggle subtitle
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản app, hệ điều hành · không gồm ảnh hay dữ liệu của bé'**
  String get fbDeviceHint;

  /// FB2 toggle; subtitle is the email
  ///
  /// In vi, this message translates to:
  /// **'Cho phép liên hệ lại'**
  String get fbReply;

  /// FB2 reply toggle without an email (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Cần tài khoản có email'**
  String get fbReplyNoEmail;

  /// FB2 primary button
  ///
  /// In vi, this message translates to:
  /// **'Gửi góp ý'**
  String get fbSend;

  /// FB2 send failed (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được góp ý. Thử lại nhé.'**
  String get fbSendFailed;

  /// FB3 title (477:6549)
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận góp ý của bạn'**
  String get fbSentTitle;

  /// FB3 body
  ///
  /// In vi, this message translates to:
  /// **'Nếu cần thêm thông tin, đội ngũ sẽ trả lời qua email trong 2 ngày làm việc. Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ.'**
  String get fbSentBody;

  /// FB3 body when 'Cho phép liên hệ lại' is off (not drawn)
  ///
  /// In vi, this message translates to:
  /// **'Đội ngũ sẽ đọc góp ý của bạn. Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ.'**
  String get fbSentBodyNoReply;

  /// FB3 button
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get fbDone;

  /// FB4 toast title (477:6564)
  ///
  /// In vi, this message translates to:
  /// **'Có gì chưa ổn ở màn này?'**
  String get fbShotTitle;

  /// FB4 toast body
  ///
  /// In vi, this message translates to:
  /// **'Gửi kèm ảnh vừa chụp để báo lỗi'**
  String get fbShotBody;

  /// Trợ giúp & liên hệ: what you sent (FB3)
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get hpSentTitle;

  /// Ticket status
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get hpStatusNew;

  /// Ticket status
  ///
  /// In vi, this message translates to:
  /// **'Đang xem'**
  String get hpStatusClaimed;

  /// Ticket status
  ///
  /// In vi, this message translates to:
  /// **'Đã trả lời'**
  String get hpStatusWaiting;

  /// Ticket status
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get hpStatusClosed;

  /// A sent Góp ý in the list
  ///
  /// In vi, this message translates to:
  /// **'Góp ý · {type}'**
  String hpFeedbackLabel(String type);

  /// 06 / R1: create an account with email (owner, 2026-10-13, D-067)
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get signInRegister;

  /// Feature name (AS01–AS19, D-066)
  ///
  /// In vi, this message translates to:
  /// **'Tự lưu kỷ niệm'**
  String get autoSaveTitle;

  /// Badge next to the feature name (D-066: free beta, no end date)
  ///
  /// In vi, this message translates to:
  /// **'Beta miễn phí'**
  String get autoSaveBeta;

  /// AS01 entry card subtitle
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý ảnh, video có {name} từ thư viện máy'**
  String autoSaveEntryHint(String name);

  /// AR04 entry card with pending suggestions
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh mới chờ duyệt · kiểm tra lúc {time}}}'**
  String autoSaveEntryPending(int count, String time);

  /// AR04 entry card button
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get autoSaveReviewShort;

  /// AS02 lead
  ///
  /// In vi, this message translates to:
  /// **'Đỡ công lục thư viện. Child Life tìm ảnh và video có thể có con, bạn xem lại rồi mới tải lên.'**
  String get autoSaveIntroLead;

  /// AS02 step 1
  ///
  /// In vi, this message translates to:
  /// **'Chọn bé và vài ảnh rõ mặt'**
  String get autoSaveStep1;

  /// AS02 step 1 hint
  ///
  /// In vi, this message translates to:
  /// **'Giúp app gợi ý đúng hơn'**
  String get autoSaveStep1Hint;

  /// AS02 step 2
  ///
  /// In vi, this message translates to:
  /// **'App tìm trong ảnh mới'**
  String get autoSaveStep2;

  /// AS02 step 2 hint
  ///
  /// In vi, this message translates to:
  /// **'Chỉ những ảnh bạn cho phép xem'**
  String get autoSaveStep2Hint;

  /// AS02 step 3
  ///
  /// In vi, this message translates to:
  /// **'Bạn duyệt rồi mới tải'**
  String get autoSaveStep3;

  /// AS02 step 3 hint
  ///
  /// In vi, this message translates to:
  /// **'Không tự tải, không tự chia sẻ'**
  String get autoSaveStep3Hint;

  /// AS02 footnote with the family's live usage, e.g. '3,2 / 10 GB'; P-147 adds the on-device sentence
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Ảnh được kiểm tra ngay trên máy, không gửi đi. Bản beta miễn phí; tệp đã tải vẫn tính vào dung lượng của gia đình ({usage}).'**
  String autoSaveIntroFootnote(String usage);

  /// AS02 footnote while storage usage is unknown
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Ảnh được kiểm tra ngay trên máy, không gửi đi. Bản beta miễn phí; tệp đã tải vẫn tính vào dung lượng của gia đình.'**
  String get autoSaveIntroFootnoteNoUsage;

  /// AS02 primary button
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu thiết lập'**
  String get autoSaveStart;

  /// AS03 title
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý ảnh của bé nào?'**
  String get autoSavePickBabyTitle;

  /// AS03 subtitle
  ///
  /// In vi, this message translates to:
  /// **'Bước 1/3 · Có thể thêm bé khác sau trong Cài đặt.'**
  String get autoSavePickBabySub;

  /// AS03 row: the user's relation to the baby, after the age
  ///
  /// In vi, this message translates to:
  /// **'Bạn là {relation}'**
  String autoSaveYouAre(String relation);

  /// AS03 locked row (caregiver)
  ///
  /// In vi, this message translates to:
  /// **'bạn là Người chăm sóc nên không bật được tính năng này'**
  String get autoSaveLockedCaregiver;

  /// AS03 locked row (relative); engineering variant of the caregiver copy
  ///
  /// In vi, this message translates to:
  /// **'bạn là Người thân nên không bật được tính năng này'**
  String get autoSaveLockedRelative;

  /// AS03 primary button
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get autoSaveNext;

  /// AS04 title
  ///
  /// In vi, this message translates to:
  /// **'Chọn vài ảnh rõ mặt {name}'**
  String autoSaveSamplesTitle(String name);

  /// AS04 subtitle
  ///
  /// In vi, this message translates to:
  /// **'Bước 2/3 · 3–5 ảnh nhìn rõ mặt, đủ sáng. Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.'**
  String get autoSaveSamplesSub;

  /// AS04 caption
  ///
  /// In vi, this message translates to:
  /// **'{count}/5 ảnh mẫu · chọn từ Kỷ niệm đã có'**
  String autoSaveSamplesCount(int count);

  /// AS04 link
  ///
  /// In vi, this message translates to:
  /// **'Hoặc chọn từ thư viện máy'**
  String get autoSaveSamplesFromLibrary;

  /// AS04 primary button
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Tiếp · {count} ảnh mẫu}}'**
  String autoSaveSamplesNext(int count);

  /// AS04: fewer than 3 samples
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất 3 ảnh mẫu.'**
  String get autoSaveSamplesNeed;

  /// AS04: the chosen photo has no usable face
  ///
  /// In vi, this message translates to:
  /// **'Ảnh này chưa thấy rõ mặt. Chọn ảnh khác nhé.'**
  String get autoSaveSampleNoFace;

  /// AS04: no photos in Kỷ niệm (engineering state)
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm chưa có ảnh của {name}. Chọn từ thư viện máy nhé.'**
  String autoSaveSamplesEmpty(String name);

  /// AS05 title (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Trước khi bắt đầu'**
  String get autoSaveConsentTitle;

  /// AS05 subtitle (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Bước 3/3 · Đổi được bất cứ lúc nào trong Cài đặt Tự lưu.'**
  String get autoSaveConsentSub;

  /// AS05 face-analysis consent card title (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Nhận ra {name} ngay trên máy này'**
  String autoSaveFaceTitle(String name);

  /// AS05 face card body (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Child Life so khuôn mặt trong ảnh mới với ảnh mẫu của {name} để gợi ý. Mọi việc diễn ra trên điện thoại của bạn.'**
  String autoSaveFaceBody(String name);

  /// AS05 reassurance 1 (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Không lưu ảnh nào của {name}: ảnh mẫu vẫn nằm trong Kỷ niệm hoặc thư viện của bạn.'**
  String autoSaveFaceNoPhotos(String name);

  /// AS05 reassurance 2 (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ghi nhớ một dãy số về khuôn mặt, nằm trên máy này, không gửi lên Child Life.'**
  String get autoSaveFaceNumbers;

  /// AS05 reassurance 3 (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Child Life không xem được, không dùng cho quảng cáo. Bạn xoá được bất cứ lúc nào.'**
  String get autoSaveFaceNoOne;

  /// AS05 consent checkbox, unticked by default (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý để Child Life nhận ra {name} trên máy này'**
  String autoSaveFaceAgree(String name);

  /// AS05: CTA tapped without the consent
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đồng ý ở thẻ đầu tiên để tiếp tục.'**
  String get autoSaveAgreeFirst;

  /// AS05 link to the explanation sheet (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Child Life lưu gì?'**
  String get autoSaveWhatKept;

  /// AS05 card 2
  ///
  /// In vi, this message translates to:
  /// **'Cho Child Life xem thư viện ảnh'**
  String get autoSaveLibraryTitle;

  /// AS05 card 2 body
  ///
  /// In vi, this message translates to:
  /// **'Để tìm ảnh, video mới có thể có {name}. App không xoá hay sửa gì trong thư viện.'**
  String autoSaveLibraryBody(String name);

  /// AS05 card 2 info strip
  ///
  /// In vi, this message translates to:
  /// **'Bấm tiếp, điện thoại sẽ hỏi quyền. Bạn có thể cho xem tất cả hoặc chỉ ảnh được chọn.'**
  String get autoSaveLibraryHint;

  /// AS05 card 3 (no background switch, D-066)
  ///
  /// In vi, this message translates to:
  /// **'Chỉ tải lên mục bạn duyệt'**
  String get autoSaveUploadTitle;

  /// AS05 card 3 body (P-147, D-066 #6)
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, video bạn bấm duyệt được tải lên Kỷ niệm như khi bạn tự thêm, và vẫn tải tiếp khi bạn khoá máy.'**
  String get autoSaveUploadBody;

  /// AS05 primary button
  ///
  /// In vi, this message translates to:
  /// **'Cho phép xem ảnh'**
  String get autoSaveAllow;

  /// AS05 text link
  ///
  /// In vi, this message translates to:
  /// **'Để sau · thêm ảnh thủ công'**
  String get autoSaveLater;

  /// 'Child Life lưu gì?' sheet block 1 (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Trên máy này'**
  String get autoSaveKeptHere;

  /// 'Child Life lưu gì?' block 1 body (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Dãy số về khuôn mặt từ ảnh mẫu và ảnh bạn đã duyệt; danh sách ảnh đã kiểm tra hoặc đã bỏ qua; cài đặt Tự lưu. Không nằm trong bản sao lưu iCloud. Gỡ app là xoá hết.'**
  String get autoSaveKeptHereBody;

  /// 'Child Life lưu gì?' block 2
  ///
  /// In vi, this message translates to:
  /// **'Không bao giờ'**
  String get autoSaveKeptNever;

  /// 'Child Life lưu gì?' block 2 body
  ///
  /// In vi, this message translates to:
  /// **'Giữ bản sao ảnh mẫu hay ảnh trong thư viện; gửi dữ liệu khuôn mặt lên máy chủ Child Life hay cho bên khác; dùng cho quảng cáo.'**
  String get autoSaveKeptNeverBody;

  /// 'Child Life lưu gì?' block 3
  ///
  /// In vi, this message translates to:
  /// **'Tải lên Child Life'**
  String get autoSaveKeptUp;

  /// 'Child Life lưu gì?' block 3 body
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh, video bạn bấm duyệt, với quyền \"Ai thấy\" bạn chọn (mặc định Chỉ ba mẹ).'**
  String get autoSaveKeptUpBody;

  /// 'Child Life lưu gì?' footer (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Xoá trong Cài đặt Tự lưu › Xoá ảnh mẫu và dữ liệu gợi ý. Tắt Tự lưu thì dữ liệu trên máy tự xoá sau 30 ngày.'**
  String get autoSaveKeptFooter;

  /// AS06 / AS17 status card
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra ảnh mới'**
  String get autoSaveChecking;

  /// AS06 progress
  ///
  /// In vi, this message translates to:
  /// **'{checked} / {total} tệp · chưa tải gì lên'**
  String autoSaveCheckingFirst(String checked, String total);

  /// AS17 progress
  ///
  /// In vi, this message translates to:
  /// **'{checked} / {total} tệp · tiến độ kiểm tra'**
  String autoSaveCheckingProgress(String checked, String total);

  /// AS06 note
  ///
  /// In vi, this message translates to:
  /// **'Có thể tạm dừng khi bạn rời app; lần mở sau sẽ kiểm tra tiếp.'**
  String get autoSaveCheckingPause;

  /// AS17 note
  ///
  /// In vi, this message translates to:
  /// **'Tách riêng với tiến độ tải lên bên dưới.'**
  String get autoSaveCheckingSeparate;

  /// AS06 found card
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã tìm thấy {count} gợi ý}}'**
  String autoSaveFound(int count);

  /// AS06 found card hint
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể xem ngay, kiểm tra vẫn tiếp tục.'**
  String get autoSaveFoundHint;

  /// AS06 primary button
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Xem {count} gợi ý}}'**
  String autoSaveSeeFound(int count);

  /// AS06 row
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và video'**
  String get autoSaveKinds;

  /// AS06 row value
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra cả hai · chỉ ảnh bạn cho phép xem'**
  String get autoSaveKindsBoth;

  /// AS12 status card
  ///
  /// In vi, this message translates to:
  /// **'Lần kiểm tra gần nhất: {time}'**
  String autoSaveLastCheck(String time);

  /// AS12 status card
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} tệp mới · {names}}}'**
  String autoSaveNewFiles(int count, String names);

  /// AS12 / AS16 button
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra ảnh mới'**
  String get autoSaveCheckNow;

  /// AS12 note
  ///
  /// In vi, this message translates to:
  /// **'App kiểm tra khi bạn mở và khi điện thoại cho phép chạy nền; thời điểm không cố định.'**
  String get autoSaveWhen;

  /// AS12 suggestions card
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} gợi ý chờ duyệt}}'**
  String autoSavePending(int count);

  /// AS17 suggestions card
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} gợi ý chờ duyệt · đang tìm thêm}}'**
  String autoSavePendingMore(int count);

  /// AS12 primary button
  ///
  /// In vi, this message translates to:
  /// **'Duyệt gợi ý'**
  String get autoSaveReview;

  /// AS12 row
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lên'**
  String get autoSaveUploadingRow;

  /// AS12 uploading row value
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} mục}}'**
  String autoSaveUploadingValue(int count);

  /// AS12 row
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu từ Tự lưu'**
  String get autoSaveSavedRow;

  /// AS12 row value, counted on this phone; month like 'tháng 10' / 'October'
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} mục trong {month}}}'**
  String autoSaveSavedValue(int count, String month);

  /// AS12 row
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh thủ công'**
  String get autoSaveManual;

  /// AS12 row hint
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện như trước'**
  String get autoSaveManualHint;

  /// AS13 status (the count is not available from iOS)
  ///
  /// In vi, this message translates to:
  /// **'Đang xem những ảnh bạn đã chọn'**
  String get autoSaveLimitedTitle;

  /// AS13 status body
  ///
  /// In vi, this message translates to:
  /// **'Child Life chỉ gợi ý trong những ảnh này'**
  String get autoSaveLimitedBody;

  /// AS13 button
  ///
  /// In vi, this message translates to:
  /// **'Chọn thêm ảnh'**
  String get autoSavePickMore;

  /// AS13 link
  ///
  /// In vi, this message translates to:
  /// **'Cho xem tất cả trong Cài đặt điện thoại'**
  String get autoSaveAllowAll;

  /// AS14 status
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa được xem ảnh'**
  String get autoSaveDeniedTitle;

  /// AS14 status body
  ///
  /// In vi, this message translates to:
  /// **'Tự lưu đang tạm dừng. Kỷ niệm đã lưu không bị ảnh hưởng.'**
  String get autoSaveDeniedBody;

  /// AS14 button
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt điện thoại'**
  String get autoSaveOpenSettings;

  /// AS15 status
  ///
  /// In vi, this message translates to:
  /// **'{name} chưa có ảnh mẫu'**
  String autoSaveNoSamplesTitle(String name);

  /// AS15 status body
  ///
  /// In vi, this message translates to:
  /// **'Thêm 3–5 ảnh rõ mặt để bắt đầu gợi ý ảnh của {name}'**
  String autoSaveNoSamplesBody(String name);

  /// AS15 button
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh mẫu'**
  String get autoSaveAddSamples;

  /// AS16 status
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh mới có thể có {names}'**
  String autoSaveNothingTitle(String names);

  /// AS16 status body
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Kiểm tra lúc {time} · {count} tệp mới từ lần trước}}'**
  String autoSaveNothingBody(int count, String time);

  /// Home when switched off in AS19 (engineering state)
  ///
  /// In vi, this message translates to:
  /// **'Tự lưu đang tắt'**
  String get autoSaveOffTitle;

  /// Home when switched off (engineering state)
  ///
  /// In vi, this message translates to:
  /// **'Bật lại trong Cài đặt Tự lưu để tìm ảnh mới. Kỷ niệm đã lưu không bị ảnh hưởng.'**
  String get autoSaveOffBody;

  /// AS12 before the first check finishes
  ///
  /// In vi, this message translates to:
  /// **'Chưa kiểm tra lần nào'**
  String get autoSaveNotYet;

  /// AS07 title
  ///
  /// In vi, this message translates to:
  /// **'Có thể có {name}'**
  String autoSaveReviewTitle(String name);

  /// AS07 subtitle
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} gợi ý · kiểm tra lúc {time}. Bỏ chọn những mục không muốn lưu.}}'**
  String autoSaveReviewSub(int count, String time);

  /// AS07 grouping note (P-146, G-102)
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giống nhau được gom lại, app chọn sẵn ảnh rõ nhất.'**
  String get autoSaveGroupedHint;

  /// AS07 filter chip
  ///
  /// In vi, this message translates to:
  /// **'Tất cả · {count}'**
  String autoSaveFilterAll(int count);

  /// AS07 filter chip
  ///
  /// In vi, this message translates to:
  /// **'Ảnh · {count}'**
  String autoSaveFilterPhotos(int count);

  /// AS07 filter chip
  ///
  /// In vi, this message translates to:
  /// **'Video · {count}'**
  String autoSaveFilterVideos(int count);

  /// AS07 day header
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date}'**
  String autoSaveDayToday(String date);

  /// AS07 day header
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua · {date}'**
  String autoSaveDayYesterday(String date);

  /// AS07 day header count
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} mục}}'**
  String autoSaveDayCount(int count);

  /// AS07 tag: already in Kỷ niệm
  ///
  /// In vi, this message translates to:
  /// **'Đã có'**
  String get autoSaveAlready;

  /// AS07 tag: original not on the phone
  ///
  /// In vi, this message translates to:
  /// **'Trên iCloud'**
  String get autoSaveInCloud;

  /// AS07 footnote
  ///
  /// In vi, this message translates to:
  /// **'\"Đã có\": tệp trùng với Kỷ niệm, sẽ không tải lại. \"Trên iCloud\": tệp gốc chưa có trong máy, sẽ lấy về khi có mạng.'**
  String get autoSaveLegend;

  /// AS07 expanded group header (G-102)
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh giống nhau · đã chọn {chosen}}}'**
  String autoSaveGroupTitle(int count, int chosen);

  /// AS07 expanded group action (G-102)
  ///
  /// In vi, this message translates to:
  /// **'Chọn cả nhóm'**
  String get autoSaveGroupAll;

  /// AS07 expanded group action (G-102)
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn'**
  String get autoSaveGroupCollapse;

  /// AS07 badge on a group's best photo (G-102)
  ///
  /// In vi, this message translates to:
  /// **'Rõ nhất'**
  String get autoSaveBest;

  /// AS07 sticky summary
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {count} · {photos} ảnh, {videos} video'**
  String autoSaveChosen(int count, int photos, int videos);

  /// AS07 summary line (P-146)
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã gộp {count} ảnh giống nhau · không xoá gì trong máy}}'**
  String autoSaveMerged(int count);

  /// AS07 top bar: untick everything shown, to pick a few by hand
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn tất cả'**
  String get autoSaveDeselectAll;

  /// AS07 top bar once nothing is ticked: tick the suggested picks again (up to the limit, D-070)
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả'**
  String get autoSaveSelectAll;

  /// AS07 note when suggestions exceed one upload (D-070)
  ///
  /// In vi, this message translates to:
  /// **'{rest, plural, other{Mỗi lần tải tối đa {cap} mục · {rest} gợi ý còn lại chờ lần sau}}'**
  String autoSaveRoundRest(int rest, int cap);

  /// AS07 toast when ticking past the per-upload limit (D-070)
  ///
  /// In vi, this message translates to:
  /// **'{cap, plural, other{Mỗi lần tải tối đa {cap} mục}}'**
  String autoSaveRoundFull(int cap);

  /// AS07 primary button
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Tiếp tục với {count} mục}}'**
  String autoSaveContinue(int count);

  /// AS07 empty (engineering state)
  ///
  /// In vi, this message translates to:
  /// **'Không còn gợi ý nào chờ duyệt.'**
  String get autoSaveReviewEmpty;

  /// AS08 top bar
  ///
  /// In vi, this message translates to:
  /// **'{index} / {total} · {time}'**
  String autoSaveViewerPos(int index, int total, String time);

  /// AS08 row
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho'**
  String get autoSaveFor;

  /// AS08 row action
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get autoSaveChange;

  /// AS08 / AS09 reject
  ///
  /// In vi, this message translates to:
  /// **'Không phải ảnh của bé'**
  String get autoSaveNotBaby;

  /// AS08 primary (selected)
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get autoSaveSelected;

  /// AS08 primary (not selected)
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get autoSaveSelect;

  /// Toast after 'Không phải ảnh của bé'
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ khỏi gợi ý'**
  String get autoSaveRejected;

  /// Toast action
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get autoSaveUndo;

  /// AS09 title
  ///
  /// In vi, this message translates to:
  /// **'Ảnh này của ai?'**
  String get autoSaveWhose;

  /// AS09 current baby
  ///
  /// In vi, this message translates to:
  /// **'Đang được gợi ý'**
  String get autoSaveSuggestedNow;

  /// AS09 reject hint
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi gợi ý · giúp lần sau gợi ý tốt hơn'**
  String get autoSaveNotBabyHint;

  /// AS09 button
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get autoSaveDone;

  /// AS10 title
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra trước khi tải'**
  String get autoSaveConfirmTitle;

  /// AS10 row
  ///
  /// In vi, this message translates to:
  /// **'Nguồn'**
  String get autoSaveSource;

  /// AS10 row value
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ảnh trên máy · {count} mục ({photos} ảnh, {videos} video)'**
  String autoSaveSourceValue(int count, int photos, int videos);

  /// AS10 row
  ///
  /// In vi, this message translates to:
  /// **'Bé'**
  String get autoSaveBabyRow;

  /// AS10 row
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào'**
  String get autoSaveSaveTo;

  /// AS10 row value (the app's Nhật ký tab, D-052)
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký, theo ngày chụp · Album: không'**
  String get autoSaveSaveToValue;

  /// AS10 section
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy'**
  String get autoSaveWho;

  /// AS10 audience card
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ'**
  String get autoSaveParentsOnly;

  /// AS10 audience card hint (D-066)
  ///
  /// In vi, this message translates to:
  /// **'Mặc định cho Tự lưu'**
  String get autoSaveParentsOnlyHint;

  /// AS10 audience card
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get autoSaveFamily;

  /// AS10 audience card hint
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà cùng xem'**
  String get autoSaveFamilyHint;

  /// AS10 switch row
  ///
  /// In vi, this message translates to:
  /// **'Báo cho gia đình'**
  String get autoSaveNotify;

  /// AS10 switch row value
  ///
  /// In vi, this message translates to:
  /// **'Tắt · không gửi thông báo'**
  String get autoSaveNotifyOff;

  /// AS10 switch row value when on (R-104)
  ///
  /// In vi, this message translates to:
  /// **'1 thông báo chung, không kèm ảnh'**
  String get autoSaveNotifyOn;

  /// AS10 storage card
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng sau khi tải'**
  String get autoSaveStorageAfter;

  /// AS10 primary button
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Tải lên {count} mục}}'**
  String autoSaveUploadCount(int count);

  /// AS10 footnote
  ///
  /// In vi, this message translates to:
  /// **'Ảnh gốc vẫn ở trong máy. Tải xong mới hiện \"Đã lưu\".'**
  String get autoSaveConfirmFootnote;

  /// AS18 banner
  ///
  /// In vi, this message translates to:
  /// **'Không đủ dung lượng: {count} mục cần {need}, gia đình còn {left}. Bạn có thể tải trước {fit} mục vừa đủ, phần còn lại vẫn giữ trên máy.'**
  String autoSaveNoRoom(int count, String need, String left, int fit);

  /// AS18 primary button
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Tải trước {count} mục vừa đủ}}'**
  String autoSaveUploadFit(int count);

  /// AS18 footnote
  ///
  /// In vi, this message translates to:
  /// **'Mục chưa tải vẫn ở trong máy và trong danh sách gợi ý.'**
  String get autoSaveNoRoomFootnote;

  /// AS18 link
  ///
  /// In vi, this message translates to:
  /// **'Xem dung lượng'**
  String get autoSaveSeeStorage;

  /// AS10 while originals are read (may come from iCloud)
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị {done}/{total}…'**
  String autoSavePreparing(int done, int total);

  /// Toast after AS10
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đang tải {count} mục lên Kỷ niệm}}'**
  String autoSaveQueued(int count);

  /// AS19 title
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt Tự lưu'**
  String get autoSaveSettingsTitle;

  /// AS19 master switch subtitle
  ///
  /// In vi, this message translates to:
  /// **'Đang bật · Beta miễn phí'**
  String get autoSaveOnBeta;

  /// AS19 master switch subtitle when off
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get autoSaveOffValue;

  /// AS19 section
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong'**
  String get autoSaveLookIn;

  /// AS19 switch
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get autoSavePhotos;

  /// AS19 switch
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get autoSaveVideos;

  /// AS19 switch hint
  ///
  /// In vi, this message translates to:
  /// **'Video lớn tốn nhiều dung lượng'**
  String get autoSaveVideosHint;

  /// AS19 switch; the app-wide setting (Q-056 proposal: videos only)
  ///
  /// In vi, this message translates to:
  /// **'Video chỉ tải qua Wi-Fi'**
  String get autoSaveWifi;

  /// AS19 switch hint
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng cho mọi video tải lên'**
  String get autoSaveWifiHint;

  /// AS19 switch (AR03)
  ///
  /// In vi, this message translates to:
  /// **'Báo khi có ảnh mới'**
  String get autoSaveNotifyNew;

  /// AS19 switch hint
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 1 lần/ngày · không báo trong giờ yên lặng'**
  String get autoSaveNotifyNewHint;

  /// AS19 section
  ///
  /// In vi, this message translates to:
  /// **'Bé & ảnh mẫu'**
  String get autoSaveBabies;

  /// AS19 baby row
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh mẫu · đang gợi ý}}'**
  String autoSaveSamplesOn(int count);

  /// AS19 baby row
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh mẫu · tạm tắt'**
  String get autoSaveSamplesNone;

  /// AS19 row
  ///
  /// In vi, this message translates to:
  /// **'Thêm bé'**
  String get autoSaveAddBaby;

  /// AS19 section
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái gần nhất'**
  String get autoSaveLastStatus;

  /// AS19 row
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra'**
  String get autoSaveCheckRow;

  /// AS19 row value
  ///
  /// In vi, this message translates to:
  /// **'{time} · {files} tệp · {found} gợi ý'**
  String autoSaveCheckValue(String time, int files, int found);

  /// AS19 row
  ///
  /// In vi, this message translates to:
  /// **'Quyền xem ảnh'**
  String get autoSavePermission;

  /// AS19 row value
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ thư viện'**
  String get autoSaveAccessFull;

  /// AS19 row value
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được chọn'**
  String get autoSaveAccessLimited;

  /// AS19 row value
  ///
  /// In vi, this message translates to:
  /// **'Chưa cho phép'**
  String get autoSaveAccessDenied;

  /// AS19 note above the delete link (P-147)
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu nhận diện chỉ nằm trên máy này.'**
  String get autoSaveOnDevice;

  /// AS19 info banner
  ///
  /// In vi, this message translates to:
  /// **'Tắt Tự lưu không xoá kỷ niệm đã lưu. App chỉ ngừng tìm và gợi ý ảnh mới.'**
  String get autoSaveOffNote;

  /// AS19 destructive link
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh mẫu và dữ liệu gợi ý'**
  String get autoSaveWipe;

  /// AS19 delete confirmation body
  ///
  /// In vi, this message translates to:
  /// **'Các dãy số về khuôn mặt, gợi ý đang chờ và sự đồng ý trên máy này sẽ bị xoá. Kỷ niệm đã lưu không bị ảnh hưởng. Muốn dùng lại, bạn thiết lập từ đầu.'**
  String get autoSaveWipeBody;

  /// AS19 delete confirmation button
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get autoSaveWipeAction;

  /// Toast after delete
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá dữ liệu Tự lưu trên máy này'**
  String get autoSaveWiped;

  /// AS19 › baby samples page title
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mẫu của {name}'**
  String autoSaveSamplesOf(String name);

  /// Samples page button
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get autoSaveSave;

  /// Samples page destructive action
  ///
  /// In vi, this message translates to:
  /// **'Bỏ {name} khỏi Tự lưu'**
  String autoSaveRemoveBaby(String name);

  /// Joins two baby names
  ///
  /// In vi, this message translates to:
  /// **'{a} và {b}'**
  String autoSaveAnd(String a, String b);

  /// AS19 › baby samples page subtitle (AS04 copy without the step)
  ///
  /// In vi, this message translates to:
  /// **'3–5 ảnh nhìn rõ mặt, đủ sáng. Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.'**
  String get autoSaveSamplesHint;

  /// 07: "Gửi link đăng nhập" with no email yet (owner, 2026-10-13)
  ///
  /// In vi, this message translates to:
  /// **'Nhập email để nhận link đăng nhập.'**
  String get emailLinkNeedsEmail;

  /// AR03 notification title, at most once a day, never in quiet hours
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Có {count} ảnh mới có thể có {name}}}'**
  String autoSavePushTitle(int count, String name);

  /// AR03 notification body
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.'**
  String get autoSavePushBody;

  /// Stands for the baby when no nickname is known on this phone
  ///
  /// In vi, this message translates to:
  /// **'bé'**
  String get autoSaveYourBaby;

  /// AR02 Hôm nay banner title
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh mới có thể có {name}}}'**
  String autoSaveBannerTitle(int count, String name);

  /// AR02 banner subtitle
  ///
  /// In vi, this message translates to:
  /// **'Từ thư viện máy · chưa tải lên'**
  String get autoSaveBannerBody;

  /// AR02 primary button
  ///
  /// In vi, this message translates to:
  /// **'Xem & chọn ảnh'**
  String get autoSaveBannerOpen;

  /// AR02 secondary button: hides the banner until new suggestions
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get autoSaveBannerLater;

  /// Screen-reader label of the dot on the Kỷ niệm tab (AR02)
  ///
  /// In vi, this message translates to:
  /// **'Có ảnh mới chờ duyệt'**
  String get autoSaveTabDot;

  /// AS19 dev-only section: why each scanned item was or was not suggested
  ///
  /// In vi, this message translates to:
  /// **'Chẩn đoán (bản dev)'**
  String get autoSaveDiagTitle;

  /// Dev diagnostics: how the last check found new items
  ///
  /// In vi, this message translates to:
  /// **'Lần kiểm tra gần nhất: {how} · {count} tệp'**
  String autoSaveDiagHow(String how, int count);

  /// Dev diagnostics: found through the library's change history
  ///
  /// In vi, this message translates to:
  /// **'ảnh mới thêm vào thư viện'**
  String get autoSaveDiagHistory;

  /// Dev diagnostics: found by date
  ///
  /// In vi, this message translates to:
  /// **'theo ngày'**
  String get autoSaveDiagByDate;

  /// Dev diagnostics: nothing yet
  ///
  /// In vi, this message translates to:
  /// **'Chưa kiểm tra lần nào từ lúc mở app.'**
  String get autoSaveDiagNone;

  /// Dev diagnostics: matched; distance and threshold
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý · {d} ≤ {t}'**
  String autoSaveDiagMatch(String d, String t);

  /// Dev diagnostics: closest face too far; distance and threshold
  ///
  /// In vi, this message translates to:
  /// **'Không giống bé · {d} > {t}'**
  String autoSaveDiagFar(String d, String t);

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Giống ảnh đã bấm “Không phải ảnh của bé”'**
  String get autoSaveDiagNegative;

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Không thấy khuôn mặt'**
  String get autoSaveDiagNoFace;

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Khuôn mặt quá nhỏ'**
  String get autoSaveDiagSmall;

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Giống giấy tờ hoặc ảnh chụp màn hình'**
  String get autoSaveDiagUtility;

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được ảnh'**
  String get autoSaveDiagUnreadable;

  /// Dev diagnostics
  ///
  /// In vi, this message translates to:
  /// **'Đã tải lên hoặc đã bỏ qua trước đó'**
  String get autoSaveDiagHandled;

  /// Dev diagnostics action: forget what was looked at and check again
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại 30 ngày gần nhất'**
  String get autoSaveDiagRescan;

  /// MM10 title (D-068).
  ///
  /// In vi, this message translates to:
  /// **'Thiệp cột mốc'**
  String get ksCardTitle;

  /// MM10 section label.
  ///
  /// In vi, this message translates to:
  /// **'Chọn dịp'**
  String get ksChooseOccasion;

  /// MM10 badge on the nearest age occasion.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get ksSuggested;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get ksOccD7;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'1 tháng'**
  String get ksOccM1;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'100 ngày'**
  String get ksOccD100;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu cười'**
  String get ksOccFirstSmile;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu biết lẫy'**
  String get ksOccRollsOver;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'Biết bò'**
  String get ksOccCrawls;

  /// Occasion chip and card title.
  ///
  /// In vi, this message translates to:
  /// **'Bước đi đầu tiên'**
  String get ksOccFirstSteps;

  /// Occasion chip.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật 1 tuổi'**
  String get ksOccY1;

  /// Big words on a first-birthday card (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'1 tuổi'**
  String get ksTitleY1;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Bảy ngày đầu bên con'**
  String get ksQuoteD7;

  /// Default card message (MM11).
  ///
  /// In vi, this message translates to:
  /// **'Một tháng yêu thương'**
  String get ksQuoteM1;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Trăm ngày hạnh phúc'**
  String get ksQuoteD100;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Nụ cười đầu tiên của con'**
  String get ksQuoteFirstSmile;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Con biết lẫy rồi!'**
  String get ksQuoteRollsOver;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Bò khắp nhà thôi!'**
  String get ksQuoteCrawls;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Những bước chân đầu tiên'**
  String get ksQuoteFirstSteps;

  /// Default card message (engineering, for design review).
  ///
  /// In vi, this message translates to:
  /// **'Một năm yêu thương'**
  String get ksQuoteY1;

  /// MM10 format.
  ///
  /// In vi, this message translates to:
  /// **'Dọc 4:5'**
  String get ksFormatPortrait;

  /// MM10 format.
  ///
  /// In vi, this message translates to:
  /// **'Vuông'**
  String get ksFormatSquare;

  /// MM10 format.
  ///
  /// In vi, this message translates to:
  /// **'Story 9:16'**
  String get ksFormatStory;

  /// Template badge (MM10); free during the beta (D-068 #3).
  ///
  /// In vi, this message translates to:
  /// **'Cao cấp'**
  String get ksPremium;

  /// MM10 empty state (G-107).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mẫu thiệp'**
  String get ksNoTemplates;

  /// MM10 empty state (G-107).
  ///
  /// In vi, this message translates to:
  /// **'Mẫu mới sẽ có sớm. Bạn quay lại sau nhé.'**
  String get ksNoTemplatesBody;

  /// MM10 error state (G-107).
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được mẫu thiệp'**
  String get ksLoadFailed;

  /// Shown when the beta flag is off or the person is not a Cùng nuôi.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở cho gia đình bạn'**
  String get ksUnavailableTitle;

  /// Shown when the beta flag is off.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp cột mốc đang thử nghiệm và sẽ sớm có cho mọi gia đình.'**
  String get ksUnavailableBody;

  /// MM11 top link.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước'**
  String get ksPreview;

  /// MM11 hint on the photo.
  ///
  /// In vi, this message translates to:
  /// **'Chạm ảnh để đổi · kéo để căn'**
  String get ksPhotoHint;

  /// Empty photo slot (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get ksChoosePhoto;

  /// MM11 tool.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get ksToolPhoto;

  /// MM11 tool.
  ///
  /// In vi, this message translates to:
  /// **'Bố cục'**
  String get ksToolLayout;

  /// MM11 tool.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn'**
  String get ksToolMessage;

  /// MM11 tool.
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get ksToolColor;

  /// MM11 Ảnh panel: pick from the phone.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện máy'**
  String get ksFromDevice;

  /// MM11 Lời nhắn panel (not drawn, G-107).
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn trên thiệp'**
  String get ksMessageLabel;

  /// MM11 primary button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thiệp'**
  String get ksSaveCard;

  /// MM11 save error.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được thiệp. Thử lại nhé.'**
  String get ksSaveFailed;

  /// MM12 title.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp đã sẵn sàng!'**
  String get ksCardReady;

  /// MM12 chip.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào Kỷ niệm · Chỉ ba mẹ'**
  String get ksSavedParents;

  /// MM12 PNG / JPG.
  ///
  /// In vi, this message translates to:
  /// **'Xuất ảnh'**
  String get ksExport;

  /// MM12 action.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào máy'**
  String get ksSaveDevice;

  /// MM12 action.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get ksShare;

  /// MM12 toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào máy'**
  String get ksSavedToDevice;

  /// MM12 pencil (a11y); saves a new card.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thiệp'**
  String get ksEditAgain;

  /// MM11 note under Lưu thiệp.
  ///
  /// In vi, this message translates to:
  /// **'Tên, tuổi và ngày được điền sẵn từ hồ sơ của {name}'**
  String ksPrefilled(String name);

  /// MM01 section title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo từ kỷ niệm của {name}'**
  String ksCreateFrom(String name);

  /// MM01 link.
  ///
  /// In vi, this message translates to:
  /// **'Xem mẫu'**
  String get ksSeeTemplates;

  /// Badge on the new creation tiles (MM01, MM02).
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get ksNew;

  /// MM01 Thiệp cột mốc tile.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh PNG để chia sẻ'**
  String get ksCardTileHint;

  /// MM02 Thiệp cột mốc tile.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh để chia sẻ'**
  String get ksCardTileHintShort;

  /// MM02 group label.
  ///
  /// In vi, this message translates to:
  /// **'SÁNG TẠO & TỰ ĐỘNG'**
  String get ksCreateGroup;

  /// MM17 badge on a card in the Ảnh grid.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp'**
  String get ksCardBadge;

  /// Câu chuyện tab: title over today's stories (D-068 #2; not drawn, G-107).
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện của gia đình'**
  String get ksStoriesSection;

  /// Count of milestone cards (MM15 section, MM17 week caption).
  ///
  /// In vi, this message translates to:
  /// **'{n} thiệp'**
  String ksCardCount(int n);

  /// MM03 message before an age occasion.
  ///
  /// In vi, this message translates to:
  /// **'{name} sắp tròn {occasion}! Cùng tạo một kỷ niệm thật đẹp nhé.'**
  String ksNudgeSoon(String name, String occasion);

  /// MM03 message on the day (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay {name} tròn {occasion}! Cùng tạo một kỷ niệm thật đẹp nhé.'**
  String ksNudgeToday(String name, String occasion);

  /// MM03 message after the day (engineering).
  ///
  /// In vi, this message translates to:
  /// **'{name} vừa tròn {occasion}! Lưu lại bằng một tấm thiệp nhé.'**
  String ksNudgeJust(String name, String occasion);

  /// MM03 message after a first-time milestone is tagged (engineering).
  ///
  /// In vi, this message translates to:
  /// **'{occasion} của {name}! Làm một tấm thiệp kỷ niệm nhé.'**
  String ksNudgeFirst(String name, String occasion);

  /// MM03 date line, e.g. 'Thứ Bảy này · 14/11'.
  ///
  /// In vi, this message translates to:
  /// **'{weekday} này · {day}'**
  String ksThisWeekday(String weekday, String day);

  /// MM03 date line.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get ksToday;

  /// MM03 date line.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get ksTomorrow;

  /// MM03 button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thiệp'**
  String get ksMakeCard;

  /// MM03: hides the card for 3 days.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get ksLater;

  /// Local notification at 09:00 on an age occasion (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay {name} tròn {occasion} 🎂'**
  String ksNudgeTodayTitle(String name, String occasion);

  /// Local notification body (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Làm một tấm thiệp kỷ niệm thật xinh nhé.'**
  String get ksNudgeTodayBody;

  /// Look-back notification for a passed age occasion (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Nhìn lại ngày {name} tròn {occasion}'**
  String ksNudgeBackAgeTitle(String name, String occasion);

  /// Look-back notification for a first-time occasion (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Nhìn lại: {occasion} của {name}'**
  String ksNudgeBackFirstTitle(String name, String occasion);

  /// Look-back notification body (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Có {n} ảnh từ dịp này trong Kỷ niệm. Làm một tấm thiệp nhé?'**
  String ksNudgeBackBody(int n);

  /// MM01 / MM02 tile and the template list title.
  ///
  /// In vi, this message translates to:
  /// **'Video kỷ niệm'**
  String get ksVideoTitle;

  /// MM01 / MM02 tile.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh + chữ + nhạc'**
  String get ksVideoTileHint;

  /// Template list.
  ///
  /// In vi, this message translates to:
  /// **'Cần {min}–{max} ảnh'**
  String ksVideoNeeds(int min, int max);

  /// Shown when the beta flag is off.
  ///
  /// In vi, this message translates to:
  /// **'Video kỷ niệm đang thử nghiệm và sẽ sớm có cho mọi gia đình.'**
  String get ksUnavailableBodyVideo;

  /// MM06 segment.
  ///
  /// In vi, this message translates to:
  /// **'Từ Kỷ niệm'**
  String get ksFromMemories;

  /// MM06 title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh cho video'**
  String get ksVideoPhotosTitle;

  /// MM06 progress.
  ///
  /// In vi, this message translates to:
  /// **'{n}/{total} cảnh đã có ảnh'**
  String ksVideoScenesFilled(int n, int total);

  /// MM06 progress.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu {n}'**
  String ksVideoMinimum(int n);

  /// MM06 scene hint.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh {n}: {hint}'**
  String ksVideoScene(int n, String hint);

  /// MM06 scene card label.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh {n}'**
  String ksVideoSceneN(int n);

  /// MM06 optional scene tag.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn'**
  String get ksVideoSceneOptionalTag;

  /// MM06 header over the photos suggested for the chosen scene.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho cảnh {n} · {hint}'**
  String ksVideoForScene(int n, String hint);

  /// MM06: when the chosen scene's photo was taken.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chụp từ {from} đến {to}'**
  String ksVideoSceneWindow(String from, String to);

  /// MM06: a scene with no time window.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh nào cũng hợp, ảnh mới nhất trước'**
  String get ksVideoSceneAny;

  /// MM06: nothing suits the chosen scene.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào trong khoảng này. Chọn trong Ảnh khác bên dưới hoặc thêm từ thư viện máy.'**
  String get ksVideoSceneEmpty;

  /// MM06: nothing suits the chosen optional scene.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào trong khoảng này. Cảnh này tuỳ chọn, có thể để trống.'**
  String get ksVideoSceneEmptyOptional;

  /// MM06 section under the suggestions.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh khác'**
  String get ksVideoOtherPhotos;

  /// MM06 a11y: clear a scene.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh ở cảnh {n}'**
  String ksVideoClearScene(int n);

  /// MM06 bottom bar.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {n} ảnh'**
  String ksVideoPicked(int n);

  /// MM06 bottom bar.
  ///
  /// In vi, this message translates to:
  /// **'Có thể thêm {n}'**
  String ksVideoCanAdd(int n);

  /// MM13 bottom bar.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm {n}'**
  String ksVideoNeedMore(int n);

  /// MM13 banner.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm của {name} hiện chỉ có {have} ảnh phù hợp. Mẫu này cần ít nhất {need} ảnh.'**
  String ksVideoNotEnough(String name, int have, int need);

  /// MM13 option.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thêm từ thư viện máy'**
  String get ksVideoMoreFromDevice;

  /// MM13 option.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh bạn chọn mới được dùng'**
  String get ksVideoMoreFromDeviceHint;

  /// MM13 option.
  ///
  /// In vi, this message translates to:
  /// **'Đổi sang mẫu ngắn hơn'**
  String get ksVideoShorter;

  /// MM13 option.
  ///
  /// In vi, this message translates to:
  /// **'“{name}” · cần {n} ảnh'**
  String ksVideoShorterHint(String name, int n);

  /// MM06: photos from the phone are uploaded first (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đang thêm {n} ảnh vào Kỷ niệm (Chỉ ba mẹ). Ảnh sẽ được chọn khi tải xong.'**
  String ksVideoImporting(int n);

  /// MM07 title.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thiện video'**
  String get ksVideoFinishTitle;

  /// MM07 chip.
  ///
  /// In vi, this message translates to:
  /// **'Điền sẵn từ hồ sơ của bé'**
  String get ksVideoPrefilled;

  /// MM07 summary.
  ///
  /// In vi, this message translates to:
  /// **'Bé'**
  String get ksVideoBaby;

  /// MM07 summary.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mốc'**
  String get ksVideoDay;

  /// MM07 field.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề'**
  String get ksVideoFieldTitle;

  /// MM07 field.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn cuối video'**
  String get ksVideoFieldMessage;

  /// MM07 strip.
  ///
  /// In vi, this message translates to:
  /// **'{n} ảnh · thứ tự xuất hiện'**
  String ksVideoOrder(int n);

  /// MM07 strip.
  ///
  /// In vi, this message translates to:
  /// **'Giữ và kéo để đổi'**
  String get ksVideoReorderHint;

  /// MM07 '+' (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get ksVideoAddPhotos;

  /// MM07 row.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc nền'**
  String get ksVideoMusic;

  /// MM07 row (no picker in V1, Q-062).
  ///
  /// In vi, this message translates to:
  /// **'Nhạc của mẫu'**
  String get ksVideoMusicTemplate;

  /// MM07 row (Q-062).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhạc cho mẫu này'**
  String get ksVideoMusicNone;

  /// MM07 row.
  ///
  /// In vi, this message translates to:
  /// **'Ai xem được'**
  String get ksVideoWho;

  /// MM07 row.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ · lưu vào Kỷ niệm'**
  String get ksVideoWhoParents;

  /// MM07 row.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · lưu vào Kỷ niệm'**
  String get ksVideoWhoFamily;

  /// Audience label.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ'**
  String get ksAudienceParents;

  /// Audience label.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get ksAudienceFamily;

  /// MM07 primary.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video'**
  String get ksVideoCreate;

  /// MM07 note.
  ///
  /// In vi, this message translates to:
  /// **'Mất khoảng 1–2 phút · bạn có thể rời màn hình'**
  String get ksVideoTakes;

  /// Request refused: one at a time.
  ///
  /// In vi, this message translates to:
  /// **'Đang có một video được tạo cho bé. Đợi xong rồi tạo tiếp nhé.'**
  String get ksVideoErrBusy;

  /// Request refused: daily cap.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay gia đình đã tạo nhiều video. Mai thử lại nhé.'**
  String get ksVideoErrDaily;

  /// Request refused: quota.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng gia đình sắp đầy. Giải phóng bớt rồi tạo video nhé.'**
  String get ksVideoErrQuota;

  /// Request refused: photo unavailable.
  ///
  /// In vi, this message translates to:
  /// **'Có ảnh vừa bị xoá hoặc chưa tải xong. Chọn lại ảnh nhé.'**
  String get ksVideoErrPhoto;

  /// Request refused: template.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu này vừa được cập nhật. Chọn lại mẫu nhé.'**
  String get ksVideoErrTemplate;

  /// MM08 title.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo video cho {name}…'**
  String ksVideoMaking(String name);

  /// MM08 body.
  ///
  /// In vi, this message translates to:
  /// **'Thường mất 1–2 phút. Bạn có thể rời màn hình này, Child Life sẽ báo khi video sẵn sàng.'**
  String get ksVideoMakingBody;

  /// MM08 step.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp {n} ảnh theo mẫu'**
  String ksVideoStepArrange(int n);

  /// MM08 step.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chữ, lời nhắn và nhạc'**
  String get ksVideoStepCompose;

  /// MM08 step.
  ///
  /// In vi, this message translates to:
  /// **'Xuất video 9:16'**
  String get ksVideoStepExport;

  /// MM08 button.
  ///
  /// In vi, this message translates to:
  /// **'Về Kỷ niệm'**
  String get ksVideoBackToMemories;

  /// MM08 Live Activity: queued.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ tạo video'**
  String get ksLiveQueued;

  /// MM08 Live Activity: arrange step.
  ///
  /// In vi, this message translates to:
  /// **'Đang sắp xếp ảnh'**
  String get ksLiveArrange;

  /// MM08 Live Activity: compose step.
  ///
  /// In vi, this message translates to:
  /// **'Đang ghép chữ và nhạc'**
  String get ksLiveCompose;

  /// MM08 Live Activity: export step.
  ///
  /// In vi, this message translates to:
  /// **'Đang xuất video'**
  String get ksLiveExport;

  /// MM08 Live Activity: ready.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem, lưu và chia sẻ'**
  String get ksLiveReadySub;

  /// MM08 Live Activity: failed.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để thử lại'**
  String get ksLiveFailedSub;

  /// Kỷ niệm banner: a Video kỷ niệm being made.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo video · {percent}%'**
  String ksVideoActive(int percent);

  /// Kỷ niệm banner: queued.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ tạo video'**
  String get ksVideoActiveQueued;

  /// Toast when a video finishes while the app is open.
  ///
  /// In vi, this message translates to:
  /// **'Video kỷ niệm đã sẵn sàng'**
  String get ksVideoReadyToast;

  /// Toast when a video fails while the app is open.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo được video kỷ niệm'**
  String get ksVideoFailedToast;

  /// Toast action: open the video job.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get ksVideoOpenJob;

  /// MM14: delete a video that could not be made.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bản nháp'**
  String get ksVideoDeleteDraft;

  /// MM14 confirm title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bản nháp video này?'**
  String get ksVideoDeleteDraftTitle;

  /// MM14 confirm body.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh của bé vẫn ở trong Kỷ niệm, chỉ bản nháp video bị xoá.'**
  String get ksVideoDeleteDraftBody;

  /// Toast after deleting a video draft.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá bản nháp'**
  String get ksVideoDraftDeleted;

  /// Thiệp / Video tab: milestone cards.
  ///
  /// In vi, this message translates to:
  /// **'Thiệp'**
  String get ksTabCards;

  /// Thiệp / Video tab: memory videos.
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get ksTabVideos;

  /// MM09 title; MM17 banner.
  ///
  /// In vi, this message translates to:
  /// **'Video đã sẵn sàng!'**
  String get ksVideoReady;

  /// MM09 chip.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào Kỷ niệm'**
  String get ksVideoSaved;

  /// MM09 chip until filed.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu vào Kỷ niệm…'**
  String get ksVideoFiling;

  /// MM09 chip.
  ///
  /// In vi, this message translates to:
  /// **'Tuần {n}'**
  String ksVideoWeek(int n);

  /// MM09 cover (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Xem video'**
  String get ksVideoWatch;

  /// MM09 action.
  ///
  /// In vi, this message translates to:
  /// **'Xem trong Kỷ niệm'**
  String get ksVideoOpen;

  /// MM09 cross-sell.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thêm thiệp “{occasion}”'**
  String ksVideoAlsoCard(String occasion);

  /// MM09 cross-sell.
  ///
  /// In vi, this message translates to:
  /// **'Dùng lại ảnh vừa chọn'**
  String get ksVideoAlsoCardHint;

  /// MM14 title.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo được video'**
  String get ksVideoFailed;

  /// MM14 body.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối bị gián đoạn khi xuất video. Ảnh, chữ và lời nhắn bạn đã chọn vẫn được giữ nguyên.'**
  String get ksVideoFailedNetwork;

  /// MM14 body for timeout (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đang bận nên chưa tạo xong. Ảnh, chữ và lời nhắn bạn đã chọn vẫn được giữ nguyên.'**
  String get ksVideoFailedBusy;

  /// MM14 body for a missing photo (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Có ảnh đã bị xoá khỏi Kỷ niệm. Chỉnh lại lựa chọn để tạo video.'**
  String get ksVideoFailedPhoto;

  /// MM14 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh lại lựa chọn'**
  String get ksVideoEditChoices;

  /// MM14 note.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp được lưu trong Câu chuyện · Bản nháp'**
  String get ksVideoDraftNote;

  /// MM03 button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video'**
  String get ksMakeVideo;

  /// MM12 action.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video {occasion}'**
  String ksMakeVideoFor(String occasion);

  /// MM15 draft tile.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp'**
  String get ksVideoDraftTile;

  /// MM15 draft tile.
  ///
  /// In vi, this message translates to:
  /// **'Làm tiếp'**
  String get ksVideoContinue;

  /// MM15 tile while rendering (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo · {p}%'**
  String ksVideoInProgress(int p);

  /// MM17 banner button.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get ksBannerView;

  /// MM15 section count.
  ///
  /// In vi, this message translates to:
  /// **'{n} video'**
  String ksVideoCount(int n);

  /// Chăm sóc section (owner, 2026-10-14, D-069)
  ///
  /// In vi, this message translates to:
  /// **'Hiểu con & phát triển'**
  String get careDevelop;

  /// Chăm sóc section (owner, 2026-10-14, D-069)
  ///
  /// In vi, this message translates to:
  /// **'Kiến thức chăm bé'**
  String get careKnowledge;

  /// Tiện ích section (owner, 2026-10-14, D-069)
  ///
  /// In vi, this message translates to:
  /// **'Công cụ'**
  String get utTools;

  /// Template list: play the template with sample pictures (MM04 / MM05 not found, G-107).
  ///
  /// In vi, this message translates to:
  /// **'Xem mẫu'**
  String get ksPreviewSample;

  /// Preview screen note (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Bản xem trước chạy ngay trên máy. Video thật được xuất 1080×1920 sau khi bấm “Tạo video”.'**
  String get ksPreviewNote;

  /// Preview screen error (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được bản xem trước. Kiểm tra mạng rồi thử lại nhé.'**
  String get ksPreviewFailed;

  /// MM07 music sheet: no track.
  ///
  /// In vi, this message translates to:
  /// **'Không dùng nhạc'**
  String get ksMusicNone;

  /// MM07 music sheet: the template’s default track.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định của mẫu'**
  String get ksMusicDefault;

  /// MM07 music sheet: a11y, stop the sample.
  ///
  /// In vi, this message translates to:
  /// **'Dừng nghe thử'**
  String get ksMusicStop;

  /// MM07 music sheet footer (engineering).
  ///
  /// In vi, this message translates to:
  /// **'Nhạc có bản quyền do Child Life chọn. Bạn có thể đổi bài bất cứ lúc nào trước khi tạo video.'**
  String get ksMusicNote;

  /// Preview screen note when the template has a real preview video.
  ///
  /// In vi, this message translates to:
  /// **'Video mẫu dùng ảnh minh hoạ. Video của bé sẽ dùng ảnh và lời bạn chọn.'**
  String get ksPreviewVideoNote;

  /// MM07 music sheet: a11y, play a sample.
  ///
  /// In vi, this message translates to:
  /// **'Nghe thử {title}'**
  String ksMusicListen(String title);

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Chào đời'**
  String get ksOccBirth;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Tiếng cười đầu tiên'**
  String get ksOccLaughs;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Biết ngồi'**
  String get ksOccSitsUp;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Đứng vững'**
  String get ksOccStands;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Chiếc răng đầu tiên'**
  String get ksOccFirstTooth;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn dặm đầu tiên'**
  String get ksOccFirstSolids;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Tiếng gọi đầu tiên'**
  String get ksOccFirstWord;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con biết lẫy rồi!'**
  String get ksAchieveRollsOver;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con ngồi vững rồi!'**
  String get ksAchieveSitsUp;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con biết bò rồi!'**
  String get ksAchieveCrawls;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con đứng được rồi!'**
  String get ksAchieveStands;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con đi được rồi!'**
  String get ksAchieveFirstSteps;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Nhìn con làm được nè!'**
  String get ksAchieveAny;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Chào con đến với thế giới'**
  String get ksQuoteBirth;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Cười giòn tan cả nhà'**
  String get ksQuoteLaughs;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con ngồi vững rồi!'**
  String get ksQuoteSitsUp;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con đứng được rồi!'**
  String get ksQuoteStands;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Chiếc răng xinh đầu tiên'**
  String get ksQuoteFirstTooth;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Măm măm ngon quá!'**
  String get ksQuoteFirstSolids;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Con đã gọi ba mẹ!'**
  String get ksQuoteFirstWord;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Ngày đầu'**
  String get ksLabelFirstDay;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Lúc ấy'**
  String get ksLabelThen;

  /// Chapter 01 cards (remember-2-templates.md).
  ///
  /// In vi, this message translates to:
  /// **'Bây giờ'**
  String get ksLabelNow;

  /// MM10 chip / card: a monthly occasion.
  ///
  /// In vi, this message translates to:
  /// **'{n} tháng'**
  String ksOccMonth(int n);

  /// Default card note for a monthly occasion.
  ///
  /// In vi, this message translates to:
  /// **'Tròn {n} tháng yêu thương'**
  String ksQuoteMonth(int n);

  /// Card {age}.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày'**
  String ksAgeDays(int n);

  /// Card {age}.
  ///
  /// In vi, this message translates to:
  /// **'{n} tuần'**
  String ksAgeWeeks(int n);

  /// Card {age}.
  ///
  /// In vi, this message translates to:
  /// **'{n} tháng'**
  String ksAgeMonths(int n);

  /// Card {age}.
  ///
  /// In vi, this message translates to:
  /// **'{n} tuổi'**
  String ksAgeYears(int n);

  /// Card ageUnit (big number + unit).
  ///
  /// In vi, this message translates to:
  /// **'ngày'**
  String ksUnitDays(int n);

  /// Card ageUnit.
  ///
  /// In vi, this message translates to:
  /// **'tuần'**
  String ksUnitWeeks(int n);

  /// Card ageUnit.
  ///
  /// In vi, this message translates to:
  /// **'tháng'**
  String ksUnitMonths(int n);

  /// Card ageUnit.
  ///
  /// In vi, this message translates to:
  /// **'tuổi'**
  String ksUnitYears(int n);

  /// Card photo label (Then & Now).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {n}'**
  String ksLabelDay(int n);

  /// Card photo label.
  ///
  /// In vi, this message translates to:
  /// **'Tuần {n}'**
  String ksLabelWeek(int n);

  /// Card photo label.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {n}'**
  String ksLabelMonth(int n);

  /// Card photo label.
  ///
  /// In vi, this message translates to:
  /// **'{n} tuổi'**
  String ksLabelYear(int n);

  /// C01 birth weight and length.
  ///
  /// In vi, this message translates to:
  /// **'{weight} kg · {length} cm'**
  String ksBirthStats(String weight, String length);

  /// C01 birth weight only.
  ///
  /// In vi, this message translates to:
  /// **'{weight} kg'**
  String ksBirthWeight(String weight);

  /// C01 birth length only.
  ///
  /// In vi, this message translates to:
  /// **'{length} cm'**
  String ksBirthLength(String length);

  /// MM07: a Chapter 01 video text (E-9).
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề lớn'**
  String get ksVideoFieldHeadline;

  /// MM07: a Chapter 01 video text (E-9).
  ///
  /// In vi, this message translates to:
  /// **'Lời cho từng ảnh (mỗi dòng một câu)'**
  String get ksVideoFieldLines;

  /// MM07: a Chapter 01 video text (E-9).
  ///
  /// In vi, this message translates to:
  /// **'Lá thư gửi con'**
  String get ksVideoFieldLetter;

  /// MM07: a Chapter 01 video text (E-9).
  ///
  /// In vi, this message translates to:
  /// **'Lời kết'**
  String get ksVideoFieldClosing;

  /// Template preview: go on with it (owner, 2026-10-14)
  ///
  /// In vi, this message translates to:
  /// **'Dùng mẫu này'**
  String get ksUseTemplate;

  /// Template preview fact
  ///
  /// In vi, this message translates to:
  /// **'Ảnh cần'**
  String get ksInfoPhotos;

  /// Template preview fact
  ///
  /// In vi, this message translates to:
  /// **'Khổ'**
  String get ksInfoFormat;

  /// Template preview fact
  ///
  /// In vi, this message translates to:
  /// **'Dịp'**
  String get ksInfoOccasion;

  /// Template preview fact
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get ksInfoDuration;

  /// Template preview fact
  ///
  /// In vi, this message translates to:
  /// **'Bảng màu'**
  String get ksInfoPalettes;

  /// Video template made for every dịp
  ///
  /// In vi, this message translates to:
  /// **'Mọi dịp'**
  String get ksAnyOccasion;

  /// Template preview: exactly this many photos
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String ksPhotosCount(int count);

  /// Template preview: a range of photos
  ///
  /// In vi, this message translates to:
  /// **'{min}–{max} ảnh'**
  String ksPhotosRange(int min, int max);

  /// Template preview: colour sets to choose from
  ///
  /// In vi, this message translates to:
  /// **'{count} bảng màu'**
  String ksPalettesCount(int count);

  /// Plan badge: paid Premium (588:6290).
  ///
  /// In vi, this message translates to:
  /// **'Premium'**
  String get pmBadgePremium;

  /// Plan badge: personalisation beta (588:6290).
  ///
  /// In vi, this message translates to:
  /// **'Beta'**
  String get pmBadgeBeta;

  /// Plan badge: free (588:6290).
  ///
  /// In vi, this message translates to:
  /// **'Cơ bản'**
  String get pmBadgeFree;

  /// Plan badge: purchase being verified (588:6290).
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh'**
  String get pmBadgePending;

  /// Plan badge: Premium ended (588:6290).
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn'**
  String get pmBadgeExpired;

  /// PR03 title; also the Tôi row.
  ///
  /// In vi, this message translates to:
  /// **'Gói của hộ'**
  String get pmPlanTitle;

  /// PR03 free state title.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng gói cơ bản'**
  String get pmPlanFree;

  /// PR03 free state body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép, lịch tham khảo, mẫu cơ bản, hướng dẫn sức khoẻ.'**
  String get pmPlanFreeBody;

  /// PR03 beta state title.
  ///
  /// In vi, this message translates to:
  /// **'Beta cá nhân hoá đang mở'**
  String get pmPlanBeta;

  /// PR03 beta state body; group A named in plain words (extract 30 Q19).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI miễn phí đến {date}. Không gồm mẫu Premium. Không tự trừ tiền khi beta kết thúc.'**
  String pmPlanBetaBody(String date);

  /// PR03 Premium state title.
  ///
  /// In vi, this message translates to:
  /// **'Child Life Premium'**
  String get pmPlanPremium;

  /// PR03 Premium with auto-renew on.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn tự động {date}'**
  String pmPlanRenews(String date);

  /// PR03 Premium with auto-renew off: access stays until then (brief p.9).
  ///
  /// In vi, this message translates to:
  /// **'Dùng đến {date} · đã tắt gia hạn'**
  String pmPlanEnds(String date);

  /// PR03 Premium note (D-072 #1: owner only).
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà thấy “Hộ đã có Premium”. Chỉ chủ hộ quản lý gói.'**
  String get pmPlanShared;

  /// PR03 for members who do not manage the plan.
  ///
  /// In vi, this message translates to:
  /// **'Hộ đã có Premium'**
  String get pmPlanHouseholdHas;

  /// PR03 pending state title.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh giao dịch'**
  String get pmPlanPending;

  /// PR03 pending state body.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở quyền mới; dữ liệu và lựa chọn vẫn giữ.'**
  String get pmPlanPendingBody;

  /// PR03 expired state title.
  ///
  /// In vi, this message translates to:
  /// **'Premium đã hết hạn {date}'**
  String pmPlanExpired(String date);

  /// PR03 expired state body (PR04).
  ///
  /// In vi, this message translates to:
  /// **'Vẫn xem dữ liệu, tóm tắt đã lưu, kỷ niệm và file đã xuất. Tạo mới nội dung Premium cần gia hạn.'**
  String get pmPlanExpiredBody;

  /// PR03 owner note while in-app purchase is not built (engineering state, Slice 4).
  ///
  /// In vi, this message translates to:
  /// **'Mua và quản lý gói ngay trong app sẽ có ở bản sau.'**
  String get pmPlanBuySoon;

  /// PR03 for non-owners (D-072 #1).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hộ mua và quản lý gói. Nhờ chủ hộ nếu cả nhà cần Premium.'**
  String get pmPlanOwnerOnly;

  /// PR03 section: what never needs a plan.
  ///
  /// In vi, this message translates to:
  /// **'Gói nào cũng có'**
  String get pmPlanAlwaysFree;

  /// PR03 always-free list (PR01 592:6826).
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép, lịch sử, nhắc việc, lịch tham khảo, hướng dẫn sức khoẻ và mọi thứ đã lưu.'**
  String get pmPlanAlwaysFreeBody;

  /// PR03 row: country of residence.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực của hộ'**
  String get pmRegionRow;

  /// Region not chosen yet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get pmRegionUnset;

  /// Region sheet title (D-072 #3).
  ///
  /// In vi, this message translates to:
  /// **'Gia đình đang sống ở đâu?'**
  String get pmRegionTitle;

  /// Region sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để chọn số cấp cứu, lịch tiêm và nội dung sức khoẻ phù hợp với nơi bạn sống. Child Life không đoán từ ngôn ngữ hay vị trí.'**
  String get pmRegionBody;

  /// Region row note for non-owners.
  ///
  /// In vi, this message translates to:
  /// **'Chủ hộ chọn khu vực của hộ.'**
  String get pmRegionOwnerOnly;

  /// Toast after saving the region.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu khu vực'**
  String get pmRegionSaved;

  /// Tôi: row opening the household country sheet (D-078).
  ///
  /// In vi, this message translates to:
  /// **'Nơi gia đình sống'**
  String get meRegionRow;

  /// Country name for VN in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Việt Nam'**
  String get pmCountryVN;

  /// Country name for US in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Hoa Kỳ'**
  String get pmCountryUS;

  /// Country name for GB in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Vương quốc Anh'**
  String get pmCountryGB;

  /// Country name for AU in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Úc'**
  String get pmCountryAU;

  /// Country name for CA in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Canada'**
  String get pmCountryCA;

  /// Country name for SG in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Singapore'**
  String get pmCountrySG;

  /// Country name for NZ in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'New Zealand'**
  String get pmCountryNZ;

  /// Country name for DE in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Đức'**
  String get pmCountryDE;

  /// Country name for FR in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Pháp'**
  String get pmCountryFR;

  /// Country name for JP in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Nhật Bản'**
  String get pmCountryJP;

  /// Country name for KR in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Hàn Quốc'**
  String get pmCountryKR;

  /// Country name for TW in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Đài Loan'**
  String get pmCountryTW;

  /// Country name for MY in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Malaysia'**
  String get pmCountryMY;

  /// Country name for TH in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Thái Lan'**
  String get pmCountryTH;

  /// Country name for HK in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Hồng Kông'**
  String get pmCountryHK;

  /// Country name for CN in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Trung Quốc'**
  String get pmCountryCN;

  /// Country name for IE in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Ireland'**
  String get pmCountryIE;

  /// Country name for NL in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Hà Lan'**
  String get pmCountryNL;

  /// Country name for BE in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Bỉ'**
  String get pmCountryBE;

  /// Country name for ES in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Tây Ban Nha'**
  String get pmCountryES;

  /// Country name for CH in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Thuỵ Sĩ'**
  String get pmCountryCH;

  /// Country name for AT in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Áo'**
  String get pmCountryAT;

  /// Country name for CZ in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Séc'**
  String get pmCountryCZ;

  /// Country name for PL in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Ba Lan'**
  String get pmCountryPL;

  /// Country name for SE in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Thuỵ Điển'**
  String get pmCountrySE;

  /// Country name for NO in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Na Uy'**
  String get pmCountryNO;

  /// Country name for DK in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Đan Mạch'**
  String get pmCountryDK;

  /// Country name for FI in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Phần Lan'**
  String get pmCountryFI;

  /// Country name for AE in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Các Tiểu vương quốc Ả Rập Thống nhất'**
  String get pmCountryAE;

  /// Country name for QA in the region picker.
  ///
  /// In vi, this message translates to:
  /// **'Qatar'**
  String get pmCountryQA;

  /// MO02 primary button.
  ///
  /// In vi, this message translates to:
  /// **'Mở với Premium'**
  String get pmUnlockPremium;

  /// MO02 secondary button.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mẫu cơ bản'**
  String get pmUseFreeTemplate;

  /// MO02 footnote for cards.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ Premium không trừ lượt xuất video'**
  String get pmCardNoQuota;

  /// MO02 sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu này dành cho gia đình có Child Life Premium.'**
  String get pmTemplatePremiumBody;

  /// MO02 note for beta families (brief p.3, extract 30 Q2).
  ///
  /// In vi, this message translates to:
  /// **'Gói beta hiện tại của nhà mình chưa gồm mẫu Premium.'**
  String get pmTemplateBetaNote;

  /// ROLE_DENIED (ST02 594:7020).
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền của ba mẹ'**
  String get pmGateRoleTitle;

  /// ROLE_DENIED body (ST02).
  ///
  /// In vi, this message translates to:
  /// **'Premium không đổi vai trò. Tạo thẻ, tạo tóm tắt AI hoặc sửa ghi nhận cần quyền của ba mẹ.'**
  String get pmGateRoleBody;

  /// REGION_UNAVAILABLE (ST02).
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ phù hợp chưa mở ở khu vực này'**
  String get pmGateRegionTitle;

  /// REGION_UNAVAILABLE body (ST02).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nội dung sức khoẻ được duyệt cho khu vực của hộ. Ghi chép, lịch tham khảo, Kỷ niệm và mẫu cơ bản vẫn dùng bình thường.'**
  String get pmGateRegionBody;

  /// REGION_UNAVAILABLE action (ST02).
  ///
  /// In vi, this message translates to:
  /// **'Đổi khu vực trong hồ sơ hộ'**
  String get pmGateRegionAction;

  /// FEATURE_DISABLED.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đang tạm tắt'**
  String get pmGateDisabledTitle;

  /// FEATURE_DISABLED body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép, nội dung cơ bản và hướng dẫn sức khoẻ vẫn dùng bình thường.'**
  String get pmGateDisabledBody;

  /// QUOTA_EXCEEDED (MO04 "Khi hết lượt").
  ///
  /// In vi, this message translates to:
  /// **'Đã hết lượt trong kỳ này'**
  String get pmGateQuotaTitle;

  /// QUOTA_EXCEEDED body (MO04).
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn xem mẫu và tạo thẻ ảnh.'**
  String get pmGateQuotaBody;

  /// CONSENT_REQUIRED.
  ///
  /// In vi, this message translates to:
  /// **'Cần bạn đồng ý dùng AI'**
  String get pmGateConsentTitle;

  /// CONSENT_REQUIRED body (ST01).
  ///
  /// In vi, this message translates to:
  /// **'Bản tóm tắt theo mẫu vẫn dùng được khi chưa bật AI.'**
  String get pmGateConsentBody;

  /// NOT_MEMBER.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn trong gia đình này'**
  String get pmGateNotMemberTitle;

  /// Gate sheet close button.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get pmGateOk;

  /// Tuỳ chỉnh Hôm nay: the Nhịp lớn lên section (H01 / H02).
  ///
  /// In vi, this message translates to:
  /// **'Dành cho bé hôm nay'**
  String get rhSectionForYou;

  /// Tuỳ chỉnh Hôm nay: what the section holds.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý, tuần tuổi và lịch tham khảo'**
  String get rhSectionForYouSub;

  /// Footnote on content with review null (D-082 wording, PS01 590:6474).
  ///
  /// In vi, this message translates to:
  /// **'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ'**
  String get rhReviewPending;

  /// Footnote on reviewed content.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt bởi {reviewer} · {credential}'**
  String rhReviewedBy(String reviewer, String credential);

  /// Joins the last two names of a list ("Ba và Cô Lan").
  ///
  /// In vi, this message translates to:
  /// **'{a} và {b}'**
  String rhJoinTwo(String a, String b);

  /// Quotes a summary or note.
  ///
  /// In vi, this message translates to:
  /// **'“{text}”'**
  String rhQuoted(String text);

  /// The current user mid-sentence ("Vì hôm nay bạn ghi nhận…").
  ///
  /// In vi, this message translates to:
  /// **'bạn'**
  String get rhWhoYou;

  /// A date range ("11/10 – 18/10").
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end}'**
  String rhDateRange(String start, String end);

  /// Closes a result screen (PS01F 590:6481).
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get rhDone;

  /// C01 primary button (589:6451).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get rhContinue;

  /// Retry a failed suggestion.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get rhRetry;

  /// Heading of a content source list.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tham khảo'**
  String get rhSources;

  /// C01 option: sleep.
  ///
  /// In vi, this message translates to:
  /// **'Khó vào giấc / hay thức'**
  String get rhObsSleep;

  /// C01 option: feeding.
  ///
  /// In vi, this message translates to:
  /// **'Bú / ăn khác thường'**
  String get rhObsFeeding;

  /// C01 option: soothing.
  ///
  /// In vi, this message translates to:
  /// **'Cần được dỗ nhiều hơn'**
  String get rhObsSoothing;

  /// C01 option: a new skill.
  ///
  /// In vi, this message translates to:
  /// **'Con có điều mới'**
  String get rhObsNewSkill;

  /// C01 option: a usual day.
  ///
  /// In vi, this message translates to:
  /// **'Như mọi ngày'**
  String get rhObsUsual;

  /// C01 health row → NL05b → HL01 (free).
  ///
  /// In vi, this message translates to:
  /// **'Mình lo về sức khoẻ của con'**
  String get rhObsHealth;

  /// Saved banner summary (PS01 "Khó vào giấc · giấc đêm · 2–3 ngày").
  ///
  /// In vi, this message translates to:
  /// **'Khó vào giấc'**
  String get rhObsShortSleep;

  /// Saved banner summary: feeding.
  ///
  /// In vi, this message translates to:
  /// **'Bú / ăn khác thường'**
  String get rhObsShortFeeding;

  /// Saved banner summary: soothing.
  ///
  /// In vi, this message translates to:
  /// **'Cần dỗ nhiều hơn'**
  String get rhObsShortSoothing;

  /// Saved banner summary: new skill.
  ///
  /// In vi, this message translates to:
  /// **'Điều mới'**
  String get rhObsShortNewSkill;

  /// Saved banner summary: usual.
  ///
  /// In vi, this message translates to:
  /// **'Như mọi ngày'**
  String get rhObsShortUsual;

  /// Saved banner summary: health.
  ///
  /// In vi, this message translates to:
  /// **'Lo về sức khoẻ'**
  String get rhObsShortHealth;

  /// Reason line: what was noted (H02 "Vì tối qua Ba ghi nhận con khó vào giấc").
  ///
  /// In vi, this message translates to:
  /// **'con khó vào giấc'**
  String rhWhatSleep(String baby);

  /// Reason line: feeding.
  ///
  /// In vi, this message translates to:
  /// **'con bú / ăn khác thường'**
  String rhWhatFeeding(String baby);

  /// Reason line: soothing.
  ///
  /// In vi, this message translates to:
  /// **'con cần được dỗ nhiều hơn'**
  String rhWhatSoothing(String baby);

  /// Reason line: new skill.
  ///
  /// In vi, this message translates to:
  /// **'con có điều mới'**
  String rhWhatNewSkill(String baby);

  /// Reason line: any other observation.
  ///
  /// In vi, this message translates to:
  /// **'điều con cần'**
  String rhWhatOther(String baby);

  /// Reason line: the check-in is from today.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get rhWhenToday;

  /// Reason line: yesterday, about the night.
  ///
  /// In vi, this message translates to:
  /// **'tối qua'**
  String get rhWhenLastNight;

  /// Reason line: yesterday.
  ///
  /// In vi, this message translates to:
  /// **'hôm qua'**
  String get rhWhenYesterday;

  /// Reason line: an earlier day.
  ///
  /// In vi, this message translates to:
  /// **'ngày {date}'**
  String rhWhenOn(String date);

  /// H02 reason from a check-in (SELF_REPORTED_NEED).
  ///
  /// In vi, this message translates to:
  /// **'Vì {when} {who} ghi nhận {what}.'**
  String rhReasonNoted(String when, String who, String what);

  /// H02 reason from earlier feedback (PREVIOUS_HELPFUL).
  ///
  /// In vi, this message translates to:
  /// **'Lần trước {who} đánh giá cách này “Có ích”.'**
  String rhReasonHelpful(String who);

  /// H02 reason from logged facts (DATA_INSIGHT).
  ///
  /// In vi, this message translates to:
  /// **'Vì giấc ngủ mấy ngày gần đây khác với thường ngày của con (từ nhật ký).'**
  String rhReasonData(String baby);

  /// Reason: age content.
  ///
  /// In vi, this message translates to:
  /// **'Vì phù hợp với tuổi của con.'**
  String rhReasonAge(String baby);

  /// Reason: the person’s interests (EN01).
  ///
  /// In vi, this message translates to:
  /// **'Vì bạn quan tâm đến chủ đề này.'**
  String get rhReasonInterest;

  /// Reason when the check-in is not on this phone.
  ///
  /// In vi, this message translates to:
  /// **'Vì nhà mình vừa ghi nhận điều con cần.'**
  String rhReasonFallback(String baby);

  /// Section heading of the free age card (Q-067).
  ///
  /// In vi, this message translates to:
  /// **'Tuần này của {baby}'**
  String rhAgeHeading(String baby);

  /// H01 age card footer.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung theo tuổi'**
  String get rhAgeFree;

  /// H01 reference-calendar pill (D-072 #7).
  ///
  /// In vi, this message translates to:
  /// **'LỊCH THAM KHẢO'**
  String get rhCalendarPill;

  /// A reference stage label (D-072 #7).
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {n} (Wonder Weeks)'**
  String rhStageName(int n);

  /// H01: the next stage window.
  ///
  /// In vi, this message translates to:
  /// **'{stage} dự kiến {range}'**
  String rhStageExpected(String stage, String range);

  /// H02 strip: the current window.
  ///
  /// In vi, this message translates to:
  /// **'{stage} · {range} · tham khảo'**
  String rhStageNow(String stage, String range);

  /// H01 optional card (only with PREMIUM_REQUIRED).
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ phù hợp với con'**
  String get rhSupportTitle;

  /// H01 optional card body.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý một việc dựa trên điều nhà mình ghi nhận, nhớ cách đã có ích, bản bàn giao cho người chăm tiếp theo.'**
  String get rhSupportBody;

  /// H01 optional card link → household plan.
  ///
  /// In vi, this message translates to:
  /// **'Tìm hiểu thêm'**
  String get rhLearnMore;

  /// H02 card kicker.
  ///
  /// In vi, this message translates to:
  /// **'VIỆC CÓ THỂ THỬ HÔM NAY'**
  String get rhKickerToday;

  /// PS02 card kicker for an evening activity.
  ///
  /// In vi, this message translates to:
  /// **'VIỆC CÓ THỂ THỬ TỐI NAY'**
  String get rhKickerTonight;

  /// H02 primary (feedback started).
  ///
  /// In vi, this message translates to:
  /// **'Thử hôm nay'**
  String get rhTryToday;

  /// PS01 primary for an evening activity (feedback started).
  ///
  /// In vi, this message translates to:
  /// **'Thử tối nay'**
  String get rhTryTonight;

  /// PS02 primary when it helped before.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại hôm nay'**
  String get rhTryAgainToday;

  /// PS02 primary when it helped before (evening).
  ///
  /// In vi, this message translates to:
  /// **'Thử lại tối nay'**
  String get rhTryAgainTonight;

  /// H02 secondary (feedback not_today → cooldown).
  ///
  /// In vi, this message translates to:
  /// **'Không phải hôm nay'**
  String get rhNotToday;

  /// PS02 secondary (feedback not_today → cooldown).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý khác'**
  String get rhSomethingElse;

  /// PS02 box title.
  ///
  /// In vi, this message translates to:
  /// **'Dựa trên phản hồi của bạn'**
  String get rhBasedOnFeedback;

  /// PS02: the feedback behind the suggestion (evening activity).
  ///
  /// In vi, this message translates to:
  /// **'Tối {date} {who} chọn “{kind}” cho “{title}”'**
  String rhFeedbackUsedEvening(
    String date,
    String who,
    String kind,
    String title,
  );

  /// PS02: the feedback behind the suggestion.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date} {who} chọn “{kind}” cho “{title}”'**
  String rhFeedbackUsedDay(String date, String who, String kind, String title);

  /// PS02 "what changed" box.
  ///
  /// In vi, this message translates to:
  /// **'Đã thay đổi'**
  String get rhChangedTitle;

  /// PS02 change: prefers_helpful.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên cách đã có ích thay vì gợi ý mới'**
  String get rhChangePrefersHelpful;

  /// PS02 change: excluded_not_suitable.
  ///
  /// In vi, this message translates to:
  /// **'Không gợi ý lại cách đã được chọn “Không phù hợp”'**
  String get rhChangeExcluded;

  /// PS02 change: cooling_down.
  ///
  /// In vi, this message translates to:
  /// **'Tạm nghỉ vài ngày cách đã chọn “Không phải hôm nay”'**
  String get rhChangeCooling;

  /// H02 check-in entry row → C01.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay con có gì khác?'**
  String get rhCheckInEntry;

  /// H02 card when the activity was started.
  ///
  /// In vi, this message translates to:
  /// **'Đang thử'**
  String get rhStartedLabel;

  /// Home health card (health > everything, brief p.11).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay có dấu hiệu cần chú ý'**
  String get rhHealthCardTitle;

  /// Home health card body.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý theo lịch tạm dừng. Xem hướng dẫn và cách gọi hỗ trợ.'**
  String get rhHealthCardBody;

  /// Home health card link → HL01.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn sức khoẻ'**
  String get rhHealthCardAction;

  /// Toast after "Không phải hôm nay" / "Để sau".
  ///
  /// In vi, this message translates to:
  /// **'Đã để sau. Gợi ý này nghỉ vài ngày.'**
  String get rhPutOffToast;

  /// C01 title.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay con có gì khác?'**
  String get rhCheckInTitle;

  /// C01 subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một điều bạn để ý. Không cần trả lời hết.'**
  String get rhCheckInSubtitle;

  /// Toast after "Như mọi ngày" (saved quietly).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu: hôm nay như mọi ngày'**
  String get rhUsualSaved;

  /// C02 title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm một chút để gợi ý đúng hơn'**
  String get rhMoreTitle;

  /// C02 top-right link: save without follow-ups.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua câu hỏi'**
  String get rhSkipQuestions;

  /// C02 question.
  ///
  /// In vi, this message translates to:
  /// **'Khi nào?'**
  String get rhQWhen;

  /// C02 sleep: when = night.
  ///
  /// In vi, this message translates to:
  /// **'Giấc đêm'**
  String get rhWhenNightSleep;

  /// C02 sleep: when = day.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngày'**
  String get rhWhenDaySleep;

  /// C02 feeding / soothing: when = night.
  ///
  /// In vi, this message translates to:
  /// **'Ban đêm'**
  String get rhWhenNight;

  /// C02 feeding / soothing: when = day.
  ///
  /// In vi, this message translates to:
  /// **'Ban ngày'**
  String get rhWhenDay;

  /// C02: when = both.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai'**
  String get rhWhenBoth;

  /// C02 question.
  ///
  /// In vi, this message translates to:
  /// **'Từ bao giờ?'**
  String get rhQSince;

  /// C02 since = today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get rhSinceToday;

  /// C02 since = 2–3 days.
  ///
  /// In vi, this message translates to:
  /// **'2–3 ngày'**
  String get rhSince23;

  /// C02 since = longer.
  ///
  /// In vi, this message translates to:
  /// **'Lâu hơn'**
  String get rhSinceLonger;

  /// C02 question.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử gì chưa? (tuỳ chọn)'**
  String get rhQTried;

  /// C02 tried: rocking.
  ///
  /// In vi, this message translates to:
  /// **'Bế ru'**
  String get rhTriedRocking;

  /// C02 tried: white noise.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng ồn trắng'**
  String get rhTriedWhiteNoise;

  /// C02 tried: feeding.
  ///
  /// In vi, this message translates to:
  /// **'Cho bú'**
  String get rhTriedFeeding;

  /// C02 tried: skin to skin.
  ///
  /// In vi, this message translates to:
  /// **'Áp da'**
  String get rhTriedSkin;

  /// C02 tried: swaddle.
  ///
  /// In vi, this message translates to:
  /// **'Quấn chũn'**
  String get rhTriedSwaddle;

  /// C02 tried: nothing yet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa'**
  String get rhTriedNone;

  /// Summary: when = night (sleep).
  ///
  /// In vi, this message translates to:
  /// **'giấc đêm'**
  String get rhSumNightSleep;

  /// Summary: when = day (sleep).
  ///
  /// In vi, this message translates to:
  /// **'giấc ngày'**
  String get rhSumDaySleep;

  /// Summary: when = night.
  ///
  /// In vi, this message translates to:
  /// **'ban đêm'**
  String get rhSumNight;

  /// Summary: when = day.
  ///
  /// In vi, this message translates to:
  /// **'ban ngày'**
  String get rhSumDay;

  /// Summary: when = both.
  ///
  /// In vi, this message translates to:
  /// **'cả ngày lẫn đêm'**
  String get rhSumBoth;

  /// Summary: since today.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get rhSumToday;

  /// Summary: since longer.
  ///
  /// In vi, this message translates to:
  /// **'lâu hơn'**
  String get rhSumLonger;

  /// C02 context box (sleep): Care facts reused.
  ///
  /// In vi, this message translates to:
  /// **'Từ nhật ký: giấc đêm qua được ghi {duration} ({who} ghi). Bạn không cần nhập lại.'**
  String rhFromLogSleep(String duration, String who);

  /// C02 context box (feeding).
  ///
  /// In vi, this message translates to:
  /// **'Từ nhật ký: hôm nay đã ghi {count} cữ bú. Bạn không cần nhập lại.'**
  String rhFromLogFeeds(int count);

  /// C02 new skill: text field label.
  ///
  /// In vi, this message translates to:
  /// **'Con làm được gì mới?'**
  String get rhNewSkillLabel;

  /// C02 new skill: placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: lần đầu lẫy'**
  String get rhNewSkillHint;

  /// C02 new skill: link to milestones (MS01, next step).
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Mốc'**
  String get rhSaveToMilestones;

  /// C02 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ghi nhận'**
  String get rhSaveNote;

  /// C02 helper below the button.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà cùng thấy ghi nhận này'**
  String get rhAlwaysFree;

  /// NL05b heading.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận hôm nay'**
  String get rhHealthQHeading;

  /// NL05b card title.
  ///
  /// In vi, this message translates to:
  /// **'Trước khi tiếp tục'**
  String get rhHealthQTitle;

  /// NL05b question.
  ///
  /// In vi, this message translates to:
  /// **'{baby} có dấu hiệu nào sau đây không?'**
  String rhHealthQAsk(String baby);

  /// NL05b helper.
  ///
  /// In vi, this message translates to:
  /// **'Nếu có, Child Life sẽ dừng gợi ý theo lịch và chỉ cho bạn hướng dẫn đã được chuyên môn duyệt.'**
  String get rhHealthQHelper;

  /// NL05b hint when a sign is "Không chắc".
  ///
  /// In vi, this message translates to:
  /// **'Không chắc thì cứ hỏi bác sĩ của bé.'**
  String get rhHealthUnsureHint;

  /// NL05b answer.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get rhAnswerYes;

  /// NL05b answer.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get rhAnswerNo;

  /// NL05b answer.
  ///
  /// In vi, this message translates to:
  /// **'Không chắc'**
  String get rhAnswerUnsure;

  /// Health sign fever_young (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Sốt (bé dưới 3 tháng)'**
  String get rhSignFeverYoung;

  /// Health sign breathing (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Khó thở, thở rút lõm'**
  String get rhSignBreathing;

  /// Health sign lethargic (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Lừ đừ, khó đánh thức'**
  String get rhSignLethargic;

  /// Health sign poor_feeding (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Bú rất ít hoặc bỏ bú'**
  String get rhSignPoorFeeding;

  /// Health sign inconsolable (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Khóc không dỗ được'**
  String get rhSignInconsolable;

  /// Health sign lost_skill (NL05b).
  ///
  /// In vi, this message translates to:
  /// **'Mất kỹ năng đã có'**
  String get rhSignLostSkill;

  /// Health sign dehydration (engineering draft).
  ///
  /// In vi, this message translates to:
  /// **'Ít tã ướt, môi khô'**
  String get rhSignDehydration;

  /// Health sign seizure (engineering draft).
  ///
  /// In vi, this message translates to:
  /// **'Co giật'**
  String get rhSignSeizure;

  /// HL01 title.
  ///
  /// In vi, this message translates to:
  /// **'Nên liên hệ hỗ trợ y tế'**
  String get rhHlTitle;

  /// HL01 body.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đánh dấu một dấu hiệu cần chú ý trong ghi nhận. Child Life dừng gợi ý theo lịch và không hiển thị nội dung trả phí ở đây.'**
  String get rhHlBody;

  /// HL01: the signs answered "Có".
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ghi'**
  String get rhHlNoted;

  /// HL01 primary: the household region number from approved content.
  ///
  /// In vi, this message translates to:
  /// **'Gọi số khẩn cấp {number}'**
  String rhHlCallEmergency(String number);

  /// HL01 secondary (the only call when the region has no approved number).
  ///
  /// In vi, this message translates to:
  /// **'Gọi bác sĩ của bé'**
  String get rhHlCallDoctor;

  /// HL01 helper.
  ///
  /// In vi, this message translates to:
  /// **'Số khẩn cấp lấy theo quốc gia cư trú của hộ. Khu vực chưa có số trong danh sách thì chỉ hiện nút gọi bác sĩ.'**
  String get rhHlHelper;

  /// HL01 when the household region has no approved number (never a default hotline).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có số khẩn cấp được duyệt cho khu vực của hộ. Nếu con có dấu hiệu nguy hiểm, hãy gọi cấp cứu nơi bạn sống.'**
  String get rhHlNoRegion;

  /// HL01 while-waiting steps.
  ///
  /// In vi, this message translates to:
  /// **'Trong lúc chờ'**
  String get rhHlWhileWaiting;

  /// HL01 disclaimer when the health pack has none.
  ///
  /// In vi, this message translates to:
  /// **'Child Life không chẩn đoán và không kết luận “an toàn”.'**
  String get rhHlDisclaimer;

  /// HL01 footer.
  ///
  /// In vi, this message translates to:
  /// **'Không paywall, không mời nâng cấp'**
  String get rhHlAlwaysFree;

  /// HL01: the dialler did not open.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng Điện thoại.'**
  String get rhHlDialFailed;

  /// PS01 / PS01F saved banner.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ghi nhận'**
  String get rhSavedTitle;

  /// Saved banner: who else sees it.
  ///
  /// In vi, this message translates to:
  /// **'{names} sẽ thấy'**
  String rhSeenBy(String names);

  /// Saved banner when no one else reads check-ins.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn thấy'**
  String get rhSeenByOnlyYou;

  /// PS01 section title.
  ///
  /// In vi, this message translates to:
  /// **'Một việc có thể thử'**
  String get rhOneThing;

  /// PS01 activity meta.
  ///
  /// In vi, this message translates to:
  /// **'{duration} · phù hợp {range}'**
  String rhDurationFit(String duration, String range);

  /// Age range of an activity.
  ///
  /// In vi, this message translates to:
  /// **'{from}–{to} tháng'**
  String rhMonthsRange(int from, int to);

  /// PS01 why box label.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao gợi ý này'**
  String get rhWhyThis;

  /// PS01 why: what was just noted (quoted summary).
  ///
  /// In vi, this message translates to:
  /// **'Bạn vừa ghi {summary}.'**
  String rhWhyJustNoted(String summary);

  /// PS01 why: what was already tried.
  ///
  /// In vi, this message translates to:
  /// **'{tried} đã thử rồi nên gợi ý một cách khác.'**
  String rhWhyTriedOther(String tried);

  /// PS01 why: PREVIOUS_HELPFUL.
  ///
  /// In vi, this message translates to:
  /// **'Cách này từng được đánh giá “Có ích”.'**
  String get rhWhyHelpedBefore;

  /// PS01 why: DATA_INSIGHT (sleep baseline).
  ///
  /// In vi, this message translates to:
  /// **'Từ nhật ký: tổng ngủ được ghi gần đây khoảng {recent} mỗi ngày, mức thường của con {baseline}.'**
  String rhWhyData(String recent, String baseline);

  /// PS01 secondary (feedback not_today).
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get rhLater;

  /// PS01 link → Nhịp lớn lên.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhịp của con'**
  String rhSeeRhythm(String baby);

  /// PS01F section title.
  ///
  /// In vi, this message translates to:
  /// **'Đọc thêm theo tuổi'**
  String get rhMoreForAge;

  /// PS01F article pill.
  ///
  /// In vi, this message translates to:
  /// **'Theo tuổi'**
  String get rhFreeAgePill;

  /// PS01F article meta.
  ///
  /// In vi, this message translates to:
  /// **'Đọc {n} phút'**
  String rhReadMinutes(int n);

  /// PS01F optional card (only with PREMIUM_REQUIRED).
  ///
  /// In vi, this message translates to:
  /// **'Muốn một gợi ý theo đúng tình huống?'**
  String get rhUpsellTitle;

  /// PS01F optional card body.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ phù hợp với con chọn một việc từ ghi nhận của nhà mình và nhớ cách đã có ích.'**
  String get rhUpsellBody;

  /// PS01F optional link → household plan.
  ///
  /// In vi, this message translates to:
  /// **'Tìm hiểu thêm (tuỳ chọn)'**
  String get rhLearnMoreOptional;

  /// Result when nothing fits.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gợi ý phù hợp'**
  String get rhNoSuggestionTitle;

  /// Result when nothing fits.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận đã lưu. Khi có nội dung hợp với con, gợi ý sẽ hiện ở Hôm nay.'**
  String get rhNoSuggestionBody;

  /// Link to the age card.
  ///
  /// In vi, this message translates to:
  /// **'Xem nội dung theo tuổi'**
  String get rhSeeAgeContent;

  /// Result offline (ST01 card 4).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận vẫn lưu trên máy'**
  String get rhOfflineTitle;

  /// Result offline (ST01 card 4, adapted).
  ///
  /// In vi, this message translates to:
  /// **'Sẽ đồng bộ khi có mạng. Gợi ý mới cần kết nối và sẽ hiện ở Hôm nay sau.'**
  String get rhOfflineBody;

  /// Result when the suggestion call failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lấy được gợi ý'**
  String get rhErrorTitle;

  /// Result when the suggestion call failed.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận đã lưu. Thử lại sau một lát.'**
  String get rhErrorBody;

  /// Result while nextAction runs.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn một việc có thể thử…'**
  String get rhLoadingSuggestion;

  /// AC01 status pill.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thử'**
  String get rhNotTried;

  /// AC02 status pill.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử · {date}'**
  String rhTriedOn(String date);

  /// AC01 hero eyebrow.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý · {duration}'**
  String rhSuggestionEyebrow(String duration);

  /// AC01 reason (quoted summary, author, date).
  ///
  /// In vi, this message translates to:
  /// **'Vì: {summary} ({who} ghi {date})'**
  String rhBecauseNoted(String summary, String who, String date);

  /// AC01 steps heading.
  ///
  /// In vi, this message translates to:
  /// **'Cách làm'**
  String get rhHow;

  /// AC01 summary heading.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao có thể giúp'**
  String get rhWhyItMayHelp;

  /// AC01 safety heading.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý an toàn'**
  String get rhSafety;

  /// AC01 primary (feedback started).
  ///
  /// In vi, this message translates to:
  /// **'Mình sẽ thử'**
  String get rhIllTry;

  /// AC01 link (feedback not_suitable).
  ///
  /// In vi, this message translates to:
  /// **'Không phù hợp với con'**
  String get rhNotRight;

  /// AC01 link (feedback not_today → cooldown).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý khác'**
  String get rhAnotherIdea;

  /// AC01 after starting → AC02.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại kết quả'**
  String get rhTellHow;

  /// Toast after "Mình sẽ thử".
  ///
  /// In vi, this message translates to:
  /// **'Chúc cả nhà thuận lợi! Thử xong thì kể lại nhé.'**
  String get rhStartedToast;

  /// Toast after "Không phù hợp với con".
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận. Sẽ không gợi ý lại cách này cho con.'**
  String get rhNotRightToast;

  /// An activity id not in the published content.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý này không còn nữa'**
  String get rhActivityMissing;

  /// AC02 question for an evening activity tried yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Tối qua thế nào?'**
  String get rhHowLastNight;

  /// AC02 question otherwise.
  ///
  /// In vi, this message translates to:
  /// **'Lần thử thế nào?'**
  String get rhHowDidItGo;

  /// AC02 choice (helpful).
  ///
  /// In vi, this message translates to:
  /// **'Có ích'**
  String get rhHelpful;

  /// AC02 choice (unsure).
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ'**
  String get rhUnsure;

  /// AC02 choice (not_suitable).
  ///
  /// In vi, this message translates to:
  /// **'Không phù hợp'**
  String get rhNotAFit;

  /// AC02 note field.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (tuỳ chọn)'**
  String get rhNoteHint;

  /// AC02 info strip (no causality claims).
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi này được dùng để chọn gợi ý lần sau. “Có ích” không có nghĩa là cách này gây ra thay đổi.'**
  String get rhFeedbackInfo;

  /// AC02 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu phản hồi'**
  String get rhSaveFeedback;

  /// Toast after AC02.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu phản hồi'**
  String get rhFeedbackSaved;

  /// Age card detail: tips.
  ///
  /// In vi, this message translates to:
  /// **'Điều có thể làm'**
  String get rhAgeTips;

  /// Age card detail: watch for.
  ///
  /// In vi, this message translates to:
  /// **'Khi nào nên hỏi bác sĩ'**
  String get rhAgeWatch;

  /// Age card detail footnote (no schedule).
  ///
  /// In vi, this message translates to:
  /// **'Mỗi bé mỗi khác. Đây là điều nhiều gia đình thấy ở tuổi này, không phải lịch bắt buộc.'**
  String get rhAgeEach;

  /// A check-in or feedback write was refused.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được ghi nhận. Có thể quyền của bạn đã thay đổi.'**
  String get rhSaveFailed;

  /// NL01 title.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp lớn lên'**
  String get rhTitle;

  /// NL01 subtitle: name and actual age.
  ///
  /// In vi, this message translates to:
  /// **'{baby} · {age}'**
  String rhBabyAge(String baby, String age);

  /// NL01b pill without a due date.
  ///
  /// In vi, this message translates to:
  /// **'LỊCH THAM KHẢO · chưa thiết lập'**
  String get rhCalendarUnsetPill;

  /// NL01b calendar card title.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày dự sinh để xem lịch tham khảo'**
  String get rhCalendarUnsetTitle;

  /// NL01b calendar card body.
  ///
  /// In vi, this message translates to:
  /// **'Không có ngày dự sinh, bạn vẫn check-in và xem nội dung theo tuổi thực của {baby}.'**
  String rhCalendarUnsetBody(String baby);

  /// NL01b → NL02b.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày dự sinh'**
  String get rhAddDueDate;

  /// NL01b → NL02b estimate from gestational age.
  ///
  /// In vi, this message translates to:
  /// **'Không nhớ'**
  String get rhDontRemember;

  /// NL01b for members who may not set it (rhythm.setup).
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ (Cùng nuôi) có thể thêm ngày dự sinh để mở lịch tham khảo.'**
  String get rhCalendarUnsetOthers;

  /// NL01 for members who may not read the restricted profile.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tham khảo tính từ ngày dự sinh, thuộc thông tin bé mà bạn chưa có quyền xem.'**
  String get rhCalendarNoAccess;

  /// NL01 when no reference model is published.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tham khảo chưa được phát hành.'**
  String get rhCalendarNoModel;

  /// NL01 link → NL03.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch'**
  String get rhSeeCalendar;

  /// NL01 headline: the next stage (D-072 #7).
  ///
  /// In vi, this message translates to:
  /// **'Sắp đến giai đoạn {n} (Wonder Weeks)'**
  String rhStageComingN(int n);

  /// NL01 headline: the current stage (D-072 #7).
  ///
  /// In vi, this message translates to:
  /// **'Đang trong giai đoạn {n} (Wonder Weeks)'**
  String rhStageInN(int n);

  /// NL01: the next window and days left.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {range} · còn {days} ngày đến giai đoạn'**
  String rhStageExpectedLine(String range, int days);

  /// NL01: the current window.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {range} · trong khoảng tham khảo'**
  String rhStageNowLine(String range);

  /// NL01 when every stage is behind.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua các giai đoạn trong lịch tham khảo'**
  String get rhStagesDone;

  /// NL01 calendar disclaimer.
  ///
  /// In vi, this message translates to:
  /// **'Đây là khoảng thời gian dự kiến theo lịch tham khảo. Lịch có thể không trùng với trải nghiệm của con.'**
  String get rhCalendarDisclaimer;

  /// NL01 basis line.
  ///
  /// In vi, this message translates to:
  /// **'Theo ngày dự sinh {date}'**
  String rhByDueDate(String date);

  /// NL01 basis line when estimated (the label stays, brief p.13).
  ///
  /// In vi, this message translates to:
  /// **'Theo ngày dự sinh ước tính {date}'**
  String rhByDueDateEstimated(String date);

  /// NL01 own-rhythm pill.
  ///
  /// In vi, this message translates to:
  /// **'NHỊP RIÊNG CỦA CON'**
  String get rhOwnPill;

  /// NL01b own-rhythm pill.
  ///
  /// In vi, this message translates to:
  /// **'NHỊP RIÊNG CỦA CON · chưa đủ dữ liệu'**
  String get rhOwnSparsePill;

  /// NL01 own-rhythm card title.
  ///
  /// In vi, this message translates to:
  /// **'Điều nhà mình ghi nhận'**
  String get rhOwnTitle;

  /// NL01 without recent check-ins.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ghi nhận nào gần đây. Bạn vẫn có thể ghi nhận hôm nay.'**
  String get rhOwnEmpty;

  /// NL01 for members without history.read.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận của gia đình chỉ hiện với người được xem chăm sóc hằng ngày.'**
  String get rhOwnNoAccess;

  /// NL01 pill on a day where two people noted different things (X03).
  ///
  /// In vi, this message translates to:
  /// **'Ghi khác nhau'**
  String get rhMixedDay;

  /// NL07 footer.
  ///
  /// In vi, this message translates to:
  /// **'Hai người ghi khác nhau trong cùng ngày được giữ nguyên cả hai.'**
  String get rhMixedNote;

  /// Author and day of a note.
  ///
  /// In vi, this message translates to:
  /// **'{who} · {date}'**
  String rhWhoDay(String who, String date);

  /// NL01 / NL04 primary → C01.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận hôm nay'**
  String get rhRecordToday;

  /// NL07 chart heading.
  ///
  /// In vi, this message translates to:
  /// **'Tổng ngủ được ghi · {days} ngày'**
  String rhSleepHeading(int days);

  /// NL01b / ST01 not enough data.
  ///
  /// In vi, this message translates to:
  /// **'Nhà mình chưa có đủ nhật ký để so sánh.'**
  String get rhSleepSparseTitle;

  /// NL01b: valid baseline days, counted automatically (D-073 #1).
  ///
  /// In vi, this message translates to:
  /// **'{valid}/{need} ngày ghi đủ giấc ngủ · cần thêm {more} ngày để so sánh. Không ghi không có nghĩa là bé ngủ ít.'**
  String rhSleepSparseBody(int valid, int need, int more);

  /// NL01b: not enough recent valid days.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất {need} trong {days} ngày gần nhất được ghi đủ để so sánh. Không ghi không có nghĩa là bé ngủ ít.'**
  String rhSleepSparseRecent(int need, int days);

  /// NL07 fact (change_detected, lower).
  ///
  /// In vi, this message translates to:
  /// **'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi thấp hơn khoảng {delta} so với trước.'**
  String rhSleepLower(String delta);

  /// NL07 fact (change_detected, higher).
  ///
  /// In vi, this message translates to:
  /// **'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi cao hơn khoảng {delta} so với trước.'**
  String rhSleepHigher(String delta);

  /// NL07 fact (no_change).
  ///
  /// In vi, this message translates to:
  /// **'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi gần với mức thường của con.'**
  String get rhSleepSame;

  /// NL07 basis line.
  ///
  /// In vi, this message translates to:
  /// **'Căn cứ: {recent} ngày gần nhất ({range}) so với {baseline} ngày ghi đủ trước đó. Không phải chẩn đoán.'**
  String rhSleepBasis(int recent, String range, int baseline);

  /// NL07 chart legend: the baseline median.
  ///
  /// In vi, this message translates to:
  /// **'mức thường {value}'**
  String rhSleepUsual(String value);

  /// NL07 chart legend: an invalid day.
  ///
  /// In vi, this message translates to:
  /// **'ngày ghi thiếu, không tính'**
  String get rhSleepMissingLegend;

  /// NL01 own rhythm without rhythm.advanced.
  ///
  /// In vi, this message translates to:
  /// **'So sánh giấc ngủ từ nhật ký'**
  String get rhSleepGateTitle;

  /// NL01 gate (PREMIUM_REQUIRED): no blurred fake insight.
  ///
  /// In vi, this message translates to:
  /// **'So sánh với mức thường của con thuộc Hỗ trợ phù hợp. Ghi nhận, lịch tham khảo và hướng dẫn sức khoẻ vẫn dùng bình thường.'**
  String get rhSleepGatePremium;

  /// NL01 gate (any other reason).
  ///
  /// In vi, this message translates to:
  /// **'Phần so sánh giấc ngủ chưa mở cho bạn. Ghi nhận và lịch tham khảo vẫn dùng được.'**
  String get rhSleepGateOther;

  /// Link that explains a gate reason.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao?'**
  String get rhWhy;

  /// NL01 section from feedback.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhà mình đã thử'**
  String get rhTriedHeading;

  /// NL01 footer.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin là ghi nhận của gia đình, không phải chẩn đoán.'**
  String get rhFooterFacts;

  /// NL01b out-of-age state.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp lớn lên đang hỗ trợ bé 0–12 tháng. Với bé lớn hơn, dữ liệu đã ghi vẫn xem được; nội dung mới chưa hỗ trợ.'**
  String get rhOutOfAge;

  /// NL01b offline state.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến: đang hiện dữ liệu đã lưu trên máy · ghi nhận sẽ được gửi khi có mạng.'**
  String get rhOfflineNote;

  /// NL01 for the owner while the country is unset (D-072 #3).
  ///
  /// In vi, this message translates to:
  /// **'Chọn khu vực để Child Life dùng đúng nội dung và số khẩn cấp. Lịch tham khảo và ghi nhận vẫn dùng được.'**
  String get rhRegionOwnerBody;

  /// NL01 owner → region sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khu vực'**
  String get rhRegionPick;

  /// NL01 for other members while the country is unset (D-072 #3).
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ chủ hộ chọn khu vực. Ghi nhận, lịch tham khảo và nội dung cơ bản vẫn dùng được.'**
  String get rhRegionWaiting;

  /// NL02a intro.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo điều có thể đến, hiểu điều con đang trải qua.'**
  String get rhSetupIntro;

  /// NL02a card 1 / NL03 title.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tham khảo'**
  String get rhLayerCalendarTitle;

  /// NL02a card 1 body.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian dự kiến theo mô hình Wonder Weeks, tính từ ngày dự sinh. Mỗi bé mỗi khác — lịch chỉ để tham khảo.'**
  String get rhLayerCalendarBody;

  /// NL02a card 1 basis.
  ///
  /// In vi, this message translates to:
  /// **'Căn cứ: ngày dự sinh + mô hình tham khảo đã phát hành'**
  String get rhLayerCalendarBasis;

  /// NL02a card 2 title.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp riêng của con'**
  String get rhLayerOwnTitle;

  /// NL02a card 2 body.
  ///
  /// In vi, this message translates to:
  /// **'Những gì cả nhà ghi nhận: giấc ngủ, nhu cầu được dỗ, điều mới. Child Life tóm tắt thay đổi và cách nhà mình đã thử.'**
  String get rhLayerOwnBody;

  /// NL02a card 2 basis.
  ///
  /// In vi, this message translates to:
  /// **'Căn cứ: check-in và nhật ký chăm sóc'**
  String get rhLayerOwnBasis;

  /// NL02a disclaimer.
  ///
  /// In vi, this message translates to:
  /// **'Child Life không dự đoán chắc chắn ngày quấy hay chẩn đoán nguyên nhân.'**
  String get rhSetupDisclaimer;

  /// NL02a primary.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get rhStart;

  /// NL02b heading.
  ///
  /// In vi, this message translates to:
  /// **'Ngày dự sinh của {baby}'**
  String rhDueTitle(String baby);

  /// NL02b body.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tham khảo tính từ ngày dự sinh, không phải ngày sinh. Bé sinh ngày {dob}.'**
  String rhDueBody(String baby, String dob);

  /// NL02b body without a date of birth.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tham khảo tính từ ngày dự sinh, không phải ngày sinh.'**
  String get rhDueBodyNoDob;

  /// NL02b field label.
  ///
  /// In vi, this message translates to:
  /// **'Ngày dự sinh'**
  String get rhDueField;

  /// NL02b field placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get rhDuePick;

  /// NL02b estimate card.
  ///
  /// In vi, this message translates to:
  /// **'Không nhớ ngày dự sinh?'**
  String get rhEstimateTitle;

  /// NL02b estimate card.
  ///
  /// In vi, this message translates to:
  /// **'Ước tính từ tuổi thai khi sinh:'**
  String get rhEstimateBody;

  /// NL02b gestational weeks chip.
  ///
  /// In vi, this message translates to:
  /// **'{n} tuần'**
  String rhWeeks(int n);

  /// NL02b gestational days chip.
  ///
  /// In vi, this message translates to:
  /// **'+ {n} ngày'**
  String rhPlusDays(int n);

  /// NL02b result banner.
  ///
  /// In vi, this message translates to:
  /// **'Dự sinh ước tính: {date} · gắn nhãn “ước tính”'**
  String rhEstimateResult(String date);

  /// NL02b advice.
  ///
  /// In vi, this message translates to:
  /// **'Bé sinh rất non hoặc có nhu cầu đặc biệt: hỏi bác sĩ trước khi dùng lịch.'**
  String get rhEstimateAdvice;

  /// NL02b without a date of birth.
  ///
  /// In vi, this message translates to:
  /// **'Cần ngày sinh của bé để ước tính.'**
  String get rhEstimateNeedsDob;

  /// NL02b validation, as setDueDate checks.
  ///
  /// In vi, this message translates to:
  /// **'Ngày dự sinh cần trong khoảng 4 tuần trước đến 18 tuần sau ngày sinh.'**
  String get rhDueOutOfRange;

  /// NL02b skip link.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua — chỉ dùng nhịp riêng của con'**
  String get rhSkipOwnOnly;

  /// NL02b helper.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lại lúc nào cũng được · lịch và nhắc sẽ tính lại'**
  String get rhDueHelper;

  /// Toast after setDueDate.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ngày dự sinh'**
  String get rhDueSaved;

  /// NL02b (edit): clears it, the calendar goes back to "chưa thiết lập".
  ///
  /// In vi, this message translates to:
  /// **'Xoá ngày dự sinh'**
  String get rhDueRemove;

  /// Toast after clearing the due date.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá ngày dự sinh'**
  String get rhDueRemoved;

  /// setDueDate failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được ngày dự sinh. Kiểm tra kết nối rồi thử lại.'**
  String get rhDueSaveFailed;

  /// NL02b for members without rhythm.setup.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ (Cùng nuôi) đặt được ngày dự sinh.'**
  String get rhDueSetupOnly;

  /// Tag on an estimated due date.
  ///
  /// In vi, this message translates to:
  /// **'ước tính'**
  String get rhEstimatedTag;

  /// NL02b weeks picker.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi thai khi sinh'**
  String get rhWeeksPickerTitle;

  /// NL02b days picker.
  ///
  /// In vi, this message translates to:
  /// **'Thêm số ngày'**
  String get rhDaysPickerTitle;

  /// NL02c heading.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc bạn khi nào?'**
  String get rhRemindTitle;

  /// NL02c body.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả đều tuỳ chọn. Tối đa 1 thông báo Nhịp lớn lên mỗi ngày.'**
  String get rhRemindBody;

  /// NL02c toggle.
  ///
  /// In vi, this message translates to:
  /// **'Trước giai đoạn tham khảo'**
  String get rhRemindStage;

  /// NL02c toggle subtitle.
  ///
  /// In vi, this message translates to:
  /// **'3 ngày trước · tối đa 1 lần mỗi giai đoạn'**
  String get rhRemindStageSub;

  /// NL02c toggle.
  ///
  /// In vi, this message translates to:
  /// **'Check-in buổi tối'**
  String get rhRemindEvening;

  /// NL02c toggle subtitle.
  ///
  /// In vi, this message translates to:
  /// **'20:30 · bỏ qua nếu đã ghi trong ngày'**
  String get rhRemindEveningSub;

  /// NL02c / EN02 quiet hours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ yên lặng'**
  String get rhQuietHours;

  /// Quiet hours range.
  ///
  /// In vi, this message translates to:
  /// **'{from} – {to}'**
  String rhQuietRange(String from, String to);

  /// Quiet hours off.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get rhQuietOff;

  /// EN02 quiet hours subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi gợi ý, chỉ nhắc việc bạn đặt'**
  String get rhQuietSub;

  /// EN02 between the two quiet-hours chips.
  ///
  /// In vi, this message translates to:
  /// **'đến'**
  String get rhQuietTo;

  /// NL02c note on where the choices live.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc được lưu trên máy này; giờ yên lặng theo tài khoản của bạn.'**
  String get rhRemindDevice;

  /// NL02c note.
  ///
  /// In vi, this message translates to:
  /// **'Không có thông báo kiểu “nguy cơ leap cao”.'**
  String get rhNoLeapRisk;

  /// NL03 basis row.
  ///
  /// In vi, this message translates to:
  /// **'Mô hình {model} · theo ngày dự sinh {date}'**
  String rhCalendarBasis(String model, String date);

  /// NL03 basis row (estimated).
  ///
  /// In vi, this message translates to:
  /// **'Mô hình {model} · theo ngày dự sinh ước tính {date}'**
  String rhCalendarBasisEstimated(String model, String date);

  /// NL03 → NL02b.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get rhChange;

  /// NL03 today marker.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date} · trước giai đoạn {n}'**
  String rhTodayBefore(String date, int n);

  /// NL03 today marker.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date} · trong giai đoạn {n}'**
  String rhTodayIn(String date, int n);

  /// NL03 today marker after every stage.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date}'**
  String rhTodayPlain(String date);

  /// NL03 stage state.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới · còn {days} ngày'**
  String rhStageUpcoming(int days);

  /// NL03 stage state.
  ///
  /// In vi, this message translates to:
  /// **'Đang trong khoảng dự kiến'**
  String get rhStageCurrent;

  /// NL03 stage state.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua'**
  String get rhStagePast;

  /// NL03 overlap note.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {a} và {b} chồng nhau · cả hai đều chỉ là tham khảo'**
  String rhStagesOverlap(int a, int b);

  /// NL03 stage row title.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {n}'**
  String rhStageShort(int n);

  /// NL03 footer.
  ///
  /// In vi, this message translates to:
  /// **'Lịch là mô hình tham khảo, chưa được chứng minh chính xác cho từng bé. Mô hình {version}.'**
  String rhCalendarFooter(String version);

  /// Source block (D-072 #7).
  ///
  /// In vi, this message translates to:
  /// **'{label} được dùng làm tham khảo, không phải đối tác.'**
  String rhNotPartner(String label);

  /// NL04 header.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến {range} · có thể không trùng với trải nghiệm của {baby}'**
  String rhStageDetailExpected(String range, String baby);

  /// NL04 card.
  ///
  /// In vi, this message translates to:
  /// **'Dấu hiệu có thể gặp'**
  String get rhSignsTitle;

  /// NL04 signs footnote (possible, never certain).
  ///
  /// In vi, this message translates to:
  /// **'Một số bé không có thay đổi rõ — điều đó bình thường'**
  String get rhSignsNormal;

  /// NL04 card.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ năng tham khảo theo tuổi'**
  String get rhSkillsTitle;

  /// NL04 skills footnote.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ năng không bắt buộc khớp với giai đoạn này. Theo dõi kỹ năng theo tuổi không thay cho sàng lọc chuyên môn.'**
  String get rhSkillsNote;

  /// NL04 card.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động phù hợp'**
  String get rhActivitiesTitle;

  /// NL04 card.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn & duyệt'**
  String get rhSourcesReview;

  /// NL04 sources: the model version.
  ///
  /// In vi, this message translates to:
  /// **'Mô hình {version}'**
  String rhModelVersion(String version);

  /// NL04 secondary: saves a usual check-in.
  ///
  /// In vi, this message translates to:
  /// **'Con vẫn như mọi ngày'**
  String get rhSameAsUsual;

  /// NL04 with an unknown stage id.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn này không còn trong lịch tham khảo.'**
  String get rhStageMissing;

  /// MS01 before saving: a parent confirms.
  ///
  /// In vi, this message translates to:
  /// **'Lưu điều mới thành mốc?'**
  String get rhMsConfirmTitle;

  /// MS01 before saving.
  ///
  /// In vi, this message translates to:
  /// **'Mốc được lưu vào Kỷ niệm của {baby} để gắn ảnh và làm thẻ mốc. Ảnh không bị sao chép.'**
  String rhMsConfirmBody(String baby);

  /// MS01 name field.
  ///
  /// In vi, this message translates to:
  /// **'Tên mốc'**
  String get rhMsName;

  /// MS01 banner.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu điều mới'**
  String get rhMsSavedTitle;

  /// MS01 banner subtitle.
  ///
  /// In vi, this message translates to:
  /// **'{name} · {date} · {who} xác nhận'**
  String rhMsSavedSub(String name, String date, String who);

  /// MS01 heading.
  ///
  /// In vi, this message translates to:
  /// **'Giữ khoảnh khắc này?'**
  String get rhMsKeepTitle;

  /// MS01 tile.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ mốc cơ bản'**
  String get rhMsBasic;

  /// MS01 tile.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ mốc Premium'**
  String get rhMsPremium;

  /// MS01 primary → Thiệp cột mốc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thẻ mốc'**
  String get rhMsCreateCard;

  /// MS01 helper (photos are linked, never copied).
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ Kỷ niệm khi tạo thẻ.'**
  String get rhMsPhotoNote;

  /// MS01 for members without moments.create (ROLE_DENIED, not a paywall).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ lưu được mốc'**
  String get rhMsRoleTitle;

  /// MS01 role body.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn ghi được điều mới trong ghi nhận; ba mẹ (Cùng nuôi) xác nhận mốc.'**
  String get rhMsRoleBody;

  /// MS01 save failed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được mốc. Thử lại sau.'**
  String get rhMsSaveFailed;

  /// Tôi row and hub title.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân hoá'**
  String get rhPersonalize;

  /// Tôi row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều bạn quan tâm, giờ nhận gợi ý, phản hồi'**
  String get rhPersonalizeSub;

  /// Hub note (per person, never a household fact).
  ///
  /// In vi, this message translates to:
  /// **'Các lựa chọn này của riêng bạn, không đổi cài đặt của người khác trong nhà.'**
  String get rhPersonalizeNote;

  /// Hub row → EN01.
  ///
  /// In vi, this message translates to:
  /// **'Điều bạn quan tâm'**
  String get rhInterestsRow;

  /// Hub row → EN02.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhận gợi ý'**
  String get rhDigestRow;

  /// Hub row → NL02c.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc Nhịp lớn lên'**
  String get rhRemindRow;

  /// Hub row → feedback history.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử phản hồi'**
  String get rhHistoryRow;

  /// Hub row value without interests.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get rhInterestsNone;

  /// EN01 title.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn đồng hành cùng {baby} ở những gì?'**
  String rhInterestsTitle(String baby);

  /// EN01 body.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay và gợi ý sẽ ưu tiên những mục này. Đổi lại lúc nào cũng được.'**
  String get rhInterestsBody;

  /// EN01: enduring interests vs today’s need.
  ///
  /// In vi, this message translates to:
  /// **'Đây là điều bạn quan tâm lâu dài. Điều con cần hôm nay thì ghi ở “Hôm nay con có gì khác?”.'**
  String get rhInterestsToday;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get rhIntSleep;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp ngủ, nhịp lớn lên'**
  String get rhIntSleepSub;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Bú & sữa'**
  String get rhIntFeeding;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa theo tuổi'**
  String get rhIntFeedingSub;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Mốc phát triển'**
  String get rhIntMilestones;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý mốc theo tuần tuổi'**
  String get rhIntMilestonesSub;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng'**
  String get rhIntVaccines;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước lịch tiêm'**
  String get rhIntVaccinesSub;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Dinh dưỡng'**
  String get rhIntNutrition;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Vi chất, vitamin theo tháng'**
  String get rhIntNutritionSub;

  /// EN01 interest.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get rhIntMoments;

  /// EN01 interest subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý ghi lại khoảnh khắc'**
  String get rhIntMomentsSub;

  /// EN01: topics marked "Ít gợi ý kiểu này hơn" (EN05).
  ///
  /// In vi, this message translates to:
  /// **'Đang ít gợi ý hơn về'**
  String get rhFewerTitle;

  /// EN01: removes a topic from "fewer".
  ///
  /// In vi, this message translates to:
  /// **'Bỏ'**
  String get rhFewerUndo;

  /// EN01 primary with the selection count.
  ///
  /// In vi, this message translates to:
  /// **'Lưu · {count} mục'**
  String rhSaveCount(int count);

  /// EN01 / EN02 top-right link.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get rhSkip;

  /// Toast after EN01 / EN02 / NL02c.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu lựa chọn của bạn'**
  String get rhPrefsSaved;

  /// EN02 title.
  ///
  /// In vi, this message translates to:
  /// **'Khi nào bạn tiện đọc gợi ý?'**
  String get rhDigestTitle;

  /// EN02 body.
  ///
  /// In vi, this message translates to:
  /// **'Child Life gom gợi ý trong ngày vào một lần, đúng giờ bạn chọn. Nhắc việc bạn tự đặt (bú, tiêm…) vẫn đến đúng giờ.'**
  String get rhDigestBody;

  /// EN02 option 08:00.
  ///
  /// In vi, this message translates to:
  /// **'Buổi sáng'**
  String get rhDigestMorning;

  /// EN02 option 12:30.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nghỉ trưa'**
  String get rhDigestNoon;

  /// EN02 option 20:30.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tối'**
  String get rhDigestEvening;

  /// EN02 option: no digest.
  ///
  /// In vi, this message translates to:
  /// **'Không gom gợi ý'**
  String get rhDigestNone;

  /// PS02 footer → feedback history.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể chỉnh hoặc xoá lịch sử phản hồi'**
  String get rhEditHistoryLink;

  /// Feedback history title.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử phản hồi'**
  String get rhHistoryTitle;

  /// Feedback history body.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi của bạn trong {days} ngày gần đây. Xoá một phản hồi thì gợi ý lần sau không dựa vào nó nữa.'**
  String rhHistoryBody(int days);

  /// Feedback history empty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có phản hồi nào gần đây.'**
  String get rhHistoryEmpty;

  /// Feedback history row action.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get rhDelete;

  /// Confirm sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xoá phản hồi này?'**
  String get rhDeleteFeedbackTitle;

  /// Confirm sheet.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý lần sau sẽ không dựa vào phản hồi này nữa.'**
  String get rhDeleteFeedbackBody;

  /// Toast after deleting.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá phản hồi'**
  String get rhFeedbackDeleted;

  /// Feedback history: clears interests and "fewer".
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại điều bạn quan tâm'**
  String get rhResetInterests;

  /// Reset confirm body.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn mọi chủ đề và các mục “Ít gợi ý kiểu này hơn”.'**
  String get rhResetInterestsBody;

  /// Toast after reset.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt lại điều bạn quan tâm'**
  String get rhResetDone;

  /// Feedback history row for retired content.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý không còn trong nội dung'**
  String get rhUnknownActivity;

  /// EN05 action on an activity (free forever).
  ///
  /// In vi, this message translates to:
  /// **'Ít gợi ý kiểu này hơn'**
  String get rhFewerLikeThis;

  /// Toast after EN05.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận. Bạn sẽ thấy ít gợi ý về {topic} hơn.'**
  String rhFewerToast(String topic);

  /// PS01 / H02 secondary suggestions (≤2).
  ///
  /// In vi, this message translates to:
  /// **'Cách khác có thể thử'**
  String get rhOtherIdeas;

  /// SU01 title; also the entry on Home and NL01.
  ///
  /// In vi, this message translates to:
  /// **'Bàn giao cho người chăm tiếp'**
  String get aiHandoverTitle;

  /// Home / NL01 entry subtitle for a Cùng nuôi. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt 3 phần từ ghi nhận của cả nhà'**
  String get aiHandoverEntrySub;

  /// Home / NL01 entry subtitle for a caregiver (reads the latest stored handover). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản mới nhất · {date}'**
  String aiHandoverEntryLatest(String date);

  /// SU01 subtitle ("06/10 – 08/10 · từ 6 ghi nhận của Mẹ, Ba, Cô Lan").
  ///
  /// In vi, this message translates to:
  /// **'{range} · từ {count} ghi nhận của {names}'**
  String aiHandoverFrom(String range, int count, String names);

  /// SU01 subtitle when the authors are unknown.
  ///
  /// In vi, this message translates to:
  /// **'{range} · từ {count} ghi nhận'**
  String aiHandoverFromCount(String range, int count);

  /// SU01: when this version was made (NL10 "08/10 · 20:12"). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lúc {when}'**
  String aiGeneratedAt(String when);

  /// SU01 section 1.
  ///
  /// In vi, this message translates to:
  /// **'Điều đã thấy'**
  String get aiSectionNoticed;

  /// SU01 section 2.
  ///
  /// In vi, this message translates to:
  /// **'Cách từng có ích'**
  String get aiSectionHelped;

  /// SU01 section 3.
  ///
  /// In vi, this message translates to:
  /// **'Việc có thể chọn tiếp'**
  String get aiSectionNext;

  /// SU01 closing note section. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý'**
  String get aiSectionNote;

  /// SU01 AI label (only on AI-worded text).
  ///
  /// In vi, this message translates to:
  /// **'Diễn đạt bởi AI từ ghi nhận đã lưu · số liệu lấy từ nhật ký'**
  String get aiWordedByAi;

  /// Short AI label (explanation, milestone nudge).
  ///
  /// In vi, this message translates to:
  /// **'Diễn đạt bởi AI từ ghi nhận đã lưu'**
  String get aiWordedShort;

  /// Template label (NL10b / ST01).
  ///
  /// In vi, this message translates to:
  /// **'Đây là tóm tắt từ những ghi nhận đã lưu.'**
  String get aiTemplateLine;

  /// SU01 report button.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng? Báo lại'**
  String get aiReport;

  /// SU01 share button naming the caregiver ("Gửi cho Cô Lan").
  ///
  /// In vi, this message translates to:
  /// **'Gửi cho {name}'**
  String aiSendTo(String name);

  /// SU01 share button without a caregiver. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gửi bản bàn giao'**
  String get aiShare;

  /// Shared text footer for AI text.
  ///
  /// In vi, this message translates to:
  /// **'(Diễn đạt bởi AI từ ghi nhận đã lưu)'**
  String get aiShareAiLine;

  /// Shared text footer for the template. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'(Tóm tắt theo mẫu từ ghi nhận đã lưu)'**
  String get aiShareTemplateLine;

  /// SU01 while generating. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang tổng hợp ghi nhận…'**
  String get aiLoading;

  /// SU01 with no section. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đủ ghi nhận để bàn giao. Ghi nhận hôm nay để bắt đầu.'**
  String get aiNoSections;

  /// SU01 link to a check-in.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận của {who} · {date}'**
  String aiChipCheckIn(String who, String date);

  /// SU01 link to my own check-in.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận của bạn · {date}'**
  String aiChipCheckInMine(String date);

  /// SU01 link to feedback.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi của {who} · {date}'**
  String aiChipFeedback(String who, String date);

  /// SU01 link to my own feedback.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi của bạn · {date}'**
  String aiChipFeedbackMine(String date);

  /// SU01 link to a milestone.
  ///
  /// In vi, this message translates to:
  /// **'Điều mới · {date}'**
  String aiChipMilestone(String date);

  /// SU01 link to the sleep comparison.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký giấc ngủ'**
  String get aiChipSleep;

  /// Record sheet: author and date.
  ///
  /// In vi, this message translates to:
  /// **'{who} · {date}'**
  String aiRecordWho(String who, String date);

  /// Record sheet title for a check-in.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận'**
  String get aiRecordCheckIn;

  /// Record sheet title for feedback.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi'**
  String get aiRecordFeedback;

  /// Record sheet title for a milestone.
  ///
  /// In vi, this message translates to:
  /// **'Điều mới'**
  String get aiRecordMilestone;

  /// Record sheet action for feedback. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem hoạt động'**
  String get aiRecordOpenActivity;

  /// Record sheet when the record is not found. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận này không còn trên máy hoặc đã được xoá.'**
  String get aiRecordGone;

  /// ST01 card 3 headline; template states.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiển thị bản theo mẫu'**
  String get aiStateTemplateTitle;

  /// Consent missing: eyebrow. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'AI CHƯA BẬT'**
  String get aiStateConsentEyebrow;

  /// Consent missing: body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản này dùng mẫu cố định, vẫn đủ 3 phần. Nếu bạn đồng ý, AI chỉ diễn đạt lại những ghi nhận đã lưu.'**
  String get aiStateConsentBody;

  /// Consent missing: link to the consent screen. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem và đồng ý dùng AI'**
  String get aiStateConsentAction;

  /// ST01 card 2 eyebrow.
  ///
  /// In vi, this message translates to:
  /// **'AI ĐANG TẮT'**
  String get aiStateOffEyebrow;

  /// ST01 card 2 body (consent withdrawn).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã tắt AI. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần: điều đã thấy, cách từng có ích, việc có thể chọn tiếp.'**
  String get aiStateWithdrawnBody;

  /// ST01 card 2 link → consent screen.
  ///
  /// In vi, this message translates to:
  /// **'Bật AI trong Cài đặt'**
  String get aiStateWithdrawnAction;

  /// FEATURE_DISABLED (kill switch). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bằng AI đang tạm dừng. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần.'**
  String get aiStateDisabledBody;

  /// ST01 card 3 eyebrow.
  ///
  /// In vi, this message translates to:
  /// **'AI CHƯA PHẢN HỒI'**
  String get aiStateErrorEyebrow;

  /// ST01 card 3 body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận và hướng dẫn sức khoẻ không bị ảnh hưởng.'**
  String get aiStateErrorBody;

  /// QUOTA_EXCEEDED eyebrow. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ DÙNG HẾT LƯỢT AI'**
  String get aiStateQuotaEyebrow;

  /// QUOTA_EXCEEDED, daily window. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng {used}/{limit} lượt AI hôm nay cho bé. Lượt mới từ {when}. Bạn vẫn xem được bản theo mẫu.'**
  String aiStateQuotaDay(int used, int limit, String when);

  /// QUOTA_EXCEEDED, monthly window. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhà mình đã dùng {used}/{limit} lượt AI kỳ này (chung cho tóm tắt và trợ lý). Lượt mới từ {when}. Bạn vẫn xem được bản theo mẫu.'**
  String aiStateQuotaMonth(int used, int limit, String when);

  /// QUOTA_EXCEEDED without numbers. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhà mình đã dùng hết lượt AI trong kỳ này. Bạn vẫn xem được bản theo mẫu.'**
  String get aiStateQuotaPlain;

  /// PREMIUM_REQUIRED / other reasons eyebrow. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'BẢN THEO MẪU'**
  String get aiStateTemplateEyebrow;

  /// PREMIUM_REQUIRED body (the only state with a plan link). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bằng AI nằm trong Child Life Premium. Bạn vẫn xem được bản theo mẫu.'**
  String get aiStatePremiumBody;

  /// ROLE_DENIED / REGION_UNAVAILABLE body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'AI chưa dùng được cho nhà mình lúc này. Bản theo mẫu vẫn đủ 3 phần.'**
  String get aiStateOtherBody;

  /// Stale (dataVersion changed). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có ghi nhận mới'**
  String get aiStateStaleTitle;

  /// Stale body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản này được tạo trước những ghi nhận mới nhất.'**
  String get aiStateStaleBody;

  /// Stale body for a caregiver (reads only). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản này được tạo trước những ghi nhận mới nhất. Ba mẹ có thể tạo lại.'**
  String get aiStateStaleRead;

  /// Stale: regenerate. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lại'**
  String get aiStateStaleAction;

  /// ST01 card 4 eyebrow.
  ///
  /// In vi, this message translates to:
  /// **'NGOẠI TUYẾN'**
  String get aiStateOfflineEyebrow;

  /// Offline with a stored handover. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem bản đã lưu'**
  String get aiStateOfflineTitle;

  /// Offline body (ST01 card 4).
  ///
  /// In vi, this message translates to:
  /// **'Bản mới và AI cần kết nối. Ghi nhận vẫn lưu trên máy và sẽ đồng bộ khi có mạng.'**
  String get aiStateOfflineBody;

  /// Offline, nothing stored. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản bàn giao trên máy'**
  String get aiStateOfflineEmptyTitle;

  /// The call failed with nothing stored. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo được bản bàn giao'**
  String get aiStateFailedTitle;

  /// The call failed body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận của nhà mình vẫn giữ nguyên.'**
  String get aiStateFailedBody;

  /// Caregiver, nothing stored. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản bàn giao'**
  String get aiReadEmptyTitle;

  /// Caregiver, nothing stored. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khi ba mẹ tạo bản bàn giao, bản mới nhất sẽ hiện ở đây.'**
  String get aiReadEmptyBody;

  /// Health first: no AI text (P-151). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay có dấu hiệu sức khoẻ được ghi nhận, nên bàn giao không dùng AI. Hãy xem hướng dẫn sức khoẻ trước.'**
  String get aiHealthBody;

  /// Report sheet title. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Điều gì chưa đúng?'**
  String get aiReportTitle;

  /// Report sheet body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một lý do. Không cần viết thêm về bé.'**
  String get aiReportBody;

  /// Report reason wrong_fact. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không khớp với điều nhà mình ghi'**
  String get aiProblemWrongFact;

  /// Report reason wrong_person. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhầm người ghi'**
  String get aiProblemWrongPerson;

  /// Report reason unsafe_advice. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lời khuyên không an toàn'**
  String get aiProblemUnsafe;

  /// Report reason language. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Diễn đạt khó hiểu'**
  String get aiProblemLanguage;

  /// Report reason other. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get aiProblemOther;

  /// Report sheet primary. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo lại'**
  String get aiReportSend;

  /// Toast after a report. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn. Bản tóm tắt này sẽ được xem lại.'**
  String get aiReportThanks;

  /// Toast when a report fails. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được. Kiểm tra kết nối và thử lại.'**
  String get aiReportFailed;

  /// Consent screen title; Cá nhân hoá row. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bằng AI'**
  String get aiConsentTitle;

  /// Consent intro. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Khi bạn đồng ý, Child Life có thể nhờ một dịch vụ AI bên ngoài diễn đạt lại những ghi nhận đã lưu thành bản bàn giao và lời giải thích. AI không thêm điều mới; mọi số liệu vẫn lấy từ nhật ký.'**
  String get aiConsentIntro;

  /// Consent: what is sent. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Được gửi đi'**
  String get aiConsentSentTitle;

  /// Consent: sent item. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Những ghi nhận dạng chữ đã lưu: điều đã thấy, cách đã thử, phản hồi, điều mới'**
  String get aiConsentSent1;

  /// Consent: sent item (D-003 nickname, never the real name). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Tên gọi ở nhà của bé và ngày của từng ghi nhận'**
  String get aiConsentSent2;

  /// Consent: never sent. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Không bao giờ gửi'**
  String get aiConsentNeverTitle;

  /// Consent: never sent (D-003). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và video'**
  String get aiConsentNever1;

  /// Consent: never sent (plan §5.5). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên đầy đủ và ngày sinh của bé'**
  String get aiConsentNever2;

  /// Consent: never sent (P-151). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận về dấu hiệu sức khoẻ'**
  String get aiConsentNever3;

  /// Consent: provider and retention. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Ai xử lý, lưu ở đâu'**
  String get aiConsentWhereTitle;

  /// Consent: external provider, server-side only (D-003). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Một dịch vụ AI bên ngoài diễn đạt lại; máy chủ Child Life gửi yêu cầu, điện thoại không gửi trực tiếp.'**
  String get aiConsentWhere1;

  /// Consent: provider retention (D-003 "provider must not retain data"). Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Nhà cung cấp AI không được lưu giữ dữ liệu này.'**
  String get aiConsentWhere2;

  /// Consent: what withdrawal does. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Bản tóm tắt được lưu trong nhà mình. Thu hồi đồng ý sẽ xoá phần chữ do AI viết; bản theo mẫu vẫn dùng được.'**
  String get aiConsentWhere3;

  /// Consent toggle shareMyNotes. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép ghi chú của tôi được dùng khi người khác trong nhà tạo tóm tắt'**
  String get aiConsentShareNotes;

  /// Consent toggle subtitle. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Nếu tắt, ghi chú bạn tự viết không được gửi khi người khác tạo tóm tắt.'**
  String get aiConsentShareNotesSub;

  /// Consent: per person. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý này là của riêng bạn; gói của hộ không thay cho nó. Bạn đổi ý lúc nào cũng được.'**
  String get aiConsentPersonal;

  /// Consent: version line.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản đồng ý: {version}'**
  String aiConsentVersion(String version);

  /// Consent primary. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý dùng AI'**
  String get aiConsentAgree;

  /// Consent given line. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đồng ý ngày {date}'**
  String aiConsentGranted(String date);

  /// Consent for an older version. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung đồng ý đã cập nhật. Hãy xem lại để tiếp tục dùng AI.'**
  String get aiConsentOutdated;

  /// Consent: withdraw (NL10 "Thu hồi đồng ý").
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi đồng ý'**
  String get aiConsentWithdraw;

  /// Withdraw confirm title. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi đồng ý?'**
  String get aiWithdrawTitle;

  /// Withdraw confirm body. Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.
  ///
  /// In vi, this message translates to:
  /// **'AI sẽ không được dùng cho tóm tắt bạn tạo nữa. Phần chữ do AI viết sẽ bị xoá; bản theo mẫu vẫn dùng được.'**
  String get aiWithdrawBody;

  /// Withdraw confirm button. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get aiWithdrawConfirm;

  /// Toast after consent. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu lựa chọn của bạn'**
  String get aiConsentSaved;

  /// Toast after withdrawal. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi đồng ý'**
  String get aiWithdrawn;

  /// Toast when consent fails. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Kiểm tra kết nối và thử lại.'**
  String get aiConsentFailed;

  /// Cá nhân hoá row value. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get aiConsentOn;

  /// Cá nhân hoá row value. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get aiConsentOff;

  /// PS01 / AC01 link under "Vì sao gợi ý này". EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích thêm'**
  String get aiExplainMore;

  /// Explain loading. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị lời giải thích…'**
  String get aiExplainLoading;

  /// Explain failed. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa giải thích thêm được lúc này. Lý do ở trên vẫn đầy đủ.'**
  String get aiExplainFailed;

  /// Explain without consent. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cần bạn đồng ý dùng AI để giải thích thêm.'**
  String get aiExplainConsent;

  /// Explain over quota. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng hết lượt AI trong kỳ này. Lý do ở trên vẫn đầy đủ.'**
  String get aiExplainQuota;

  /// Explain for other gate reasons. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích thêm chưa dùng được cho nhà mình lúc này.'**
  String get aiExplainUnavailable;

  /// NL07b title.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm thành một đợt quan sát?'**
  String get rhEpSuggestTitle;

  /// NL07b body ("2 ngày gần đây có ghi nhận thay đổi: Mẹ (06/10) và Ba (07/10) thấy …").
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày gần đây có ghi nhận thay đổi: {people} thấy {what}.'**
  String rhEpSuggestBody(int count, String people, String what);

  /// NL07b: who and when.
  ///
  /// In vi, this message translates to:
  /// **'{who} ({date})'**
  String rhEpPersonDay(String who, String date);

  /// NL07b disclaimer.
  ///
  /// In vi, this message translates to:
  /// **'Đây chỉ là cách nhà mình theo dõi, không phải xác nhận một giai đoạn Wonder Weeks.'**
  String get rhEpNotWonder;

  /// NL07b primary.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đợt quan sát'**
  String get rhEpCreate;

  /// NL07b secondary.
  ///
  /// In vi, this message translates to:
  /// **'Không cần'**
  String get rhEpNoNeed;

  /// NL07 episode card title.
  ///
  /// In vi, this message translates to:
  /// **'Đợt quan sát {start} – nay'**
  String rhEpOpenTitle(String start);

  /// NL07 episode status pill.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật'**
  String get rhEpUpdating;

  /// NL07 episode card body.
  ///
  /// In vi, this message translates to:
  /// **'{who} xác nhận nhóm {count} ghi nhận thành một đợt. Đợt kết thúc khi cả nhà xác nhận “con đã ổn hơn”.'**
  String rhEpOpenBody(String who, int count);

  /// NL07: closes the episode (never automatic).
  ///
  /// In vi, this message translates to:
  /// **'Con đã ổn hơn'**
  String get rhEpBetter;

  /// Close confirm title. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc đợt quan sát?'**
  String get rhEpCloseTitle;

  /// Close confirm body. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đợt sẽ được lưu từ {start} đến hôm nay. Child Life không tự kết thúc đợt khi không có ghi nhận.'**
  String rhEpCloseBody(String start);

  /// Close confirm cancel. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa'**
  String get rhEpNotYet;

  /// Toast after NL07b. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đợt quan sát'**
  String get rhEpCreated;

  /// Toast after "Con đã ổn hơn". EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc đợt quan sát'**
  String get rhEpClosed;

  /// Evening check-in notification body (title is rhCheckInEntry). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại một điều trong vài giây, nếu có. Không có gì khác cũng không sao.'**
  String get rhEveningBody;

  /// PR01 subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Một gói cho cả hộ. Mở cả hai nhóm quyền lợi.'**
  String get pmPaywallSubtitle;

  /// PR01 pill on the benefit group the paywall was opened from (entry A or B).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang xem'**
  String get pmPaywallHere;

  /// PR01 benefit group A.
  ///
  /// In vi, this message translates to:
  /// **'A · Cá nhân hoá & Nhịp lớn lên nâng cao'**
  String get pmGroupATitle;

  /// PR01 group A benefit 1.
  ///
  /// In vi, this message translates to:
  /// **'Một việc phù hợp mỗi ngày từ ghi nhận của nhà mình'**
  String get pmGroupA1;

  /// PR01 group A benefit 2.
  ///
  /// In vi, this message translates to:
  /// **'Nhớ cách đã có ích, bàn giao cho người chăm'**
  String get pmGroupA2;

  /// PR01 group A benefit 3.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt AI có căn cứ (có hạn mức)'**
  String get pmGroupA3;

  /// PR01 benefit group B.
  ///
  /// In vi, this message translates to:
  /// **'B · Mẫu thẻ & video Premium'**
  String get pmGroupBTitle;

  /// PR01 group B benefit 1.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ thư viện mẫu Premium'**
  String get pmGroupB1;

  /// PR01 group B benefit 2 (numbers are config, not shown).
  ///
  /// In vi, this message translates to:
  /// **'Thêm lượt xuất video mỗi kỳ'**
  String get pmGroupB2;

  /// PR01 always-free box (D-072 #7 label).
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép, lịch sử, nhắc việc, lịch tham khảo (Wonder Weeks), mẫu cơ bản, hướng dẫn sức khoẻ thiết yếu. Hết gói vẫn xem dữ liệu, kỷ niệm và file đã xuất.'**
  String get pmPaywallFreeBody;

  /// PR01 plan tile: monthly.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get pmPeriodMonthly;

  /// PR01 plan tile: yearly.
  ///
  /// In vi, this message translates to:
  /// **'Theo năm'**
  String get pmPeriodYearly;

  /// PR01 renewal sentence; price from the storefront.
  ///
  /// In vi, this message translates to:
  /// **'{price} mỗi tháng, tự động gia hạn đến khi bạn huỷ.'**
  String pmRenewMonthly(String price);

  /// PR01 renewal sentence; price from the storefront.
  ///
  /// In vi, this message translates to:
  /// **'{price} mỗi năm, tự động gia hạn đến khi bạn huỷ.'**
  String pmRenewYearly(String price);

  /// PR01 auto-renewal disclosure required by the stores (not drawn in Figma).
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán qua tài khoản {store} khi bạn xác nhận. Gói tự gia hạn trừ khi bạn tắt ít nhất 24 giờ trước khi kỳ hiện tại kết thúc; quản lý và huỷ trong cài đặt {store}.'**
  String pmRenewTerms(String store);

  /// Store name.
  ///
  /// In vi, this message translates to:
  /// **'App Store'**
  String get pmStoreApple;

  /// Store name.
  ///
  /// In vi, this message translates to:
  /// **'Google Play'**
  String get pmStoreGoogle;

  /// PR01 primary button.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Premium'**
  String get pmContinuePremium;

  /// PR01 legal line under the button.
  ///
  /// In vi, this message translates to:
  /// **'Giá, kỳ hạn và gia hạn hiển thị theo cửa hàng · huỷ trong cài đặt cửa hàng'**
  String get pmStoreLegal;

  /// PR01 link to the terms (store guidelines).
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get pmTerms;

  /// PR01 link to the privacy policy (store guidelines).
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get pmPrivacy;

  /// PR01 / PR03 restore purchases.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get pmRestore;

  /// PR01 owner: purchase not open yet (D-074, premium_billing off or no products).
  ///
  /// In vi, this message translates to:
  /// **'Mua trong app sắp có'**
  String get pmBuyClosedTitle;

  /// PR01 owner: purchase not open yet.
  ///
  /// In vi, this message translates to:
  /// **'Child Life Premium chưa bán trong app. Mọi thứ khác vẫn dùng bình thường; Child Life sẽ báo khi mở.'**
  String get pmBuyClosedBody;

  /// PR01 for members who are not the owner (D-072 #1).
  ///
  /// In vi, this message translates to:
  /// **'Nhờ chủ hộ nâng cấp'**
  String get pmAskOwnerTitle;

  /// PR01 for members who are not the owner.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hộ mua và quản lý gói. Khi hộ có Premium, cả nhà cùng dùng.'**
  String get pmAskOwnerBody;

  /// PR01 when the household already has Premium.
  ///
  /// In vi, this message translates to:
  /// **'Premium đang mở cho cả nhà. Chỉ chủ hộ quản lý gói.'**
  String get pmHouseholdHasBody;

  /// PR02 Pending title.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán'**
  String get pmPendingTitle;

  /// PR02 Pending body from a template.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Lựa chọn mẫu và ảnh của bạn vẫn được giữ.'**
  String get pmPendingBody;

  /// PR02 Pending body outside a template.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Bạn có thể đóng và kiểm tra lại sau.'**
  String get pmPendingBodyPlain;

  /// PR02 Pending primary.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại'**
  String get pmCheckAgain;

  /// PR02 close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get pmClose;

  /// PR02 Success title.
  ///
  /// In vi, this message translates to:
  /// **'Hộ đã có Premium'**
  String get pmSuccessTitle;

  /// PR02 Success body from a template.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đúng mẫu “{name}” với ảnh bạn đã chọn.'**
  String pmSuccessTemplate(String name);

  /// PR02 Success body from Nhịp lớn lên or the plan.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI đã mở cho cả nhà.'**
  String get pmSuccessRhythm;

  /// PR02 Success primary for a card.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục tạo thẻ'**
  String get pmContinueCard;

  /// PR02 Success primary for a video.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục tạo video'**
  String get pmContinueVideo;

  /// PR02 Success primary from entry A (extract open question: return to Nhịp lớn lên).
  ///
  /// In vi, this message translates to:
  /// **'Về Nhịp lớn lên'**
  String get pmBackToRhythm;

  /// PR02 Success primary from the plan.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get pmDone;

  /// PR02 Error title.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mua được'**
  String get pmErrorTitle;

  /// PR02 Error body from a template.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại hoặc dùng mẫu cơ bản.'**
  String get pmErrorBody;

  /// PR02 Error body outside a template.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại sau nhé.'**
  String get pmErrorBodyPlain;

  /// PR02 Error: the server could not verify.
  ///
  /// In vi, this message translates to:
  /// **'Child Life chưa xác minh được giao dịch với cửa hàng. Premium chưa được mở. Nếu cửa hàng đã trừ tiền, bấm Thử lại hoặc Khôi phục.'**
  String get pmErrorVerifyBody;

  /// PR02 Error: network while verifying.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối được Child Life. Giao dịch của cửa hàng vẫn được giữ để kiểm tra lại.'**
  String get pmErrorNetworkBody;

  /// PR02 Error primary.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get pmTryAgain;

  /// PR02 not_owner (D-072 #1).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hộ mua và khôi phục gói'**
  String get pmNotOwnerTitle;

  /// PR02 not_owner body.
  ///
  /// In vi, this message translates to:
  /// **'Nhờ chủ hộ mở Gói của hộ để nâng cấp hoặc khôi phục.'**
  String get pmNotOwnerBody;

  /// PR02 Restore confirm title.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục giao dịch'**
  String get pmRestoreTitle;

  /// PR02 Restore confirm body.
  ///
  /// In vi, this message translates to:
  /// **'Child Life kiểm tra giao dịch thuộc tài khoản này và gắn lại cho hộ của bạn. Không chuyển gói từ hộ khác.'**
  String get pmRestoreBody;

  /// PR02 Restore confirm secondary.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get pmCancel;

  /// Restore result: re-linked (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục Premium'**
  String get pmRestoredTitle;

  /// Restore result: re-linked.
  ///
  /// In vi, this message translates to:
  /// **'Gói của bạn đã gắn lại với hộ này. Cả nhà thấy “Hộ đã có Premium”.'**
  String get pmRestoredBody;

  /// Restore result: nothing found (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch để khôi phục'**
  String get pmRestoreNoneTitle;

  /// Restore result: nothing found.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản cửa hàng này chưa có gói Child Life Premium còn hiệu lực.'**
  String get pmRestoreNoneBody;

  /// Restore result: already bound to another family (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Gói đang dùng cho hộ khác'**
  String get pmRestoreBoundTitle;

  /// Restore result: already bound.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch này đã gắn với một hộ khác. Child Life không chuyển gói giữa các hộ; liên hệ hỗ trợ nếu cần.'**
  String get pmRestoreBoundBody;

  /// MO02 note: the selection survives the purchase.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bạn đã chọn sẽ được giữ sau khi mua'**
  String get pmTemplateKeepsPhotos;

  /// MO03 banner on the template after purchase.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở Premium · tiếp tục chỗ bạn đang làm'**
  String get pmResumedBanner;

  /// PR03 owner: subscription management (Apple).
  ///
  /// In vi, this message translates to:
  /// **'Quản lý trong App Store'**
  String get pmManageApple;

  /// PR03 owner: subscription management (Google).
  ///
  /// In vi, this message translates to:
  /// **'Quản lý trong Google Play'**
  String get pmManageGoogle;

  /// PR03 / quota sheet: open PR01.
  ///
  /// In vi, this message translates to:
  /// **'Xem Premium'**
  String get pmSeePremium;

  /// PR04 renew link.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn Premium'**
  String get pmRenewPremium;

  /// PR04 strip where history stays.
  ///
  /// In vi, this message translates to:
  /// **'Premium đã hết hạn. Mọi ghi nhận, phản hồi và bản tóm tắt đã lưu vẫn ở đây.'**
  String get pmExpiredStrip;

  /// MO04 quota card title.
  ///
  /// In vi, this message translates to:
  /// **'Lượt xuất video kỳ này'**
  String get pmQuotaTitle;

  /// MO04 quota detail.
  ///
  /// In vi, this message translates to:
  /// **'{used} đã dùng · {reserved} đang giữ chỗ · làm mới {date}'**
  String pmQuotaDetail(int used, int reserved, String date);

  /// MO04 quota detail without a reset date.
  ///
  /// In vi, this message translates to:
  /// **'{used} đã dùng · {reserved} đang giữ chỗ'**
  String pmQuotaDetailNoDate(int used, int reserved);

  /// MO04 note.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ ảnh không tính lượt.'**
  String get pmQuotaCards;

  /// QUOTA_EXCEEDED sheet title (MO04 "Khi hết lượt").
  ///
  /// In vi, this message translates to:
  /// **'Đã hết lượt xuất video kỳ này'**
  String get pmQuotaOutTitle;

  /// QUOTA_EXCEEDED sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau, làm mới {date}.'**
  String pmQuotaOutBody(String date);

  /// QUOTA_EXCEEDED sheet body without a date.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau.'**
  String get pmQuotaOutBodyNoDate;

  /// QUOTA_EXCEEDED sheet: go to cards.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thẻ ảnh'**
  String get pmQuotaMakeCard;

  /// QUOTA_EXCEEDED sheet note for free families, only when Premium has more.
  ///
  /// In vi, this message translates to:
  /// **'Premium có {limit} lượt xuất video mỗi kỳ.'**
  String pmQuotaPremiumNote(int limit);

  /// MO04 queued job.
  ///
  /// In vi, this message translates to:
  /// **'Giữ 1 lượt · bạn có thể rời màn hình'**
  String get pmQuotaReserved;

  /// MO04 failed job.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn lượt giữ chỗ · Thử lại không trừ thêm lượt'**
  String get pmQuotaReleased;

  /// EN09 kicker, NL01 / Home entry, notification title and NL02c switch.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần'**
  String get rhWeekTitle;

  /// EN09 title: the week of life counted from the date of birth (days 0–6 = week 1) on the week’s Sunday.
  ///
  /// In vi, this message translates to:
  /// **'Tuần thứ {n} của {baby}'**
  String rhWeekOf(int n, String baby);

  /// EN09 note on a Sunday: the week ends tonight, today’s sleep is not counted yet.
  ///
  /// In vi, this message translates to:
  /// **'Tuần đang diễn ra · số liệu đến lúc này'**
  String get rhWeekInProgress;

  /// EN09 top pill: shares the logged figures as plain text.
  ///
  /// In vi, this message translates to:
  /// **'Gửi cho…'**
  String get rhWeekShare;

  /// EN09 free section heading.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi trong tuần'**
  String get rhWeekRecordedTitle;

  /// EN09 free section subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ nhật ký của cả nhà'**
  String get rhWeekRecordedSub;

  /// EN09 tile label.
  ///
  /// In vi, this message translates to:
  /// **'Bú'**
  String get rhWeekFeeds;

  /// EN09 feeds tile value.
  ///
  /// In vi, this message translates to:
  /// **'{count} cữ'**
  String rhWeekFeedCount(int count);

  /// EN09 feeds tile: bottle millilitres (never converted from minutes).
  ///
  /// In vi, this message translates to:
  /// **'Bú bình {ml} ml'**
  String rhWeekBottle(String ml);

  /// EN09 feeds tile: breastfeeding time (never converted to ml).
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ {time}'**
  String rhWeekBreast(String time);

  /// EN09 tile value when nothing of that kind was logged.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi'**
  String get rhWeekNone;

  /// EN09 tile label.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ'**
  String get rhWeekSleep;

  /// EN09 sleep tile: what the value is.
  ///
  /// In vi, this message translates to:
  /// **'trung bình ngày ghi đủ'**
  String get rhWeekSleepAvg;

  /// EN09 coverage label: valid days counted automatically (D-073 #1).
  ///
  /// In vi, this message translates to:
  /// **'{valid}/{days} ngày ghi đủ'**
  String rhWeekCoverage(int valid, int days);

  /// EN09 sleep tile value under the rules’ minimum of valid days.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ dữ liệu'**
  String get rhWeekSleepSparse;

  /// EN09 sleep tile: the minimum of valid days.
  ///
  /// In vi, this message translates to:
  /// **'cần ít nhất {need} ngày'**
  String rhWeekSleepNeed(int need);

  /// EN09 tile label.
  ///
  /// In vi, this message translates to:
  /// **'Thay tã'**
  String get rhWeekDiapers;

  /// EN09 diapers tile value.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần'**
  String rhWeekDiaperCount(int count);

  /// EN09 diapers tile detail (“Cả hai” counts in both).
  ///
  /// In vi, this message translates to:
  /// **'Ướt {wet} · Bẩn {dirty}'**
  String rhWeekDiaperKinds(int wet, int dirty);

  /// EN09 tile label (only when measured this week).
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng'**
  String get rhWeekGrowth;

  /// EN09 growth tile: change against the previous weighing, with its date.
  ///
  /// In vi, this message translates to:
  /// **'{delta} so với {date}'**
  String rhWeekGrowthSince(String delta, String date);

  /// EN09 growth tile without an earlier weighing.
  ///
  /// In vi, this message translates to:
  /// **'đo ngày {date}'**
  String rhWeekGrowthOn(String date);

  /// EN09 tile label (only when something was saved this week).
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get rhWeekMemories;

  /// EN09 moments tile value.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String rhWeekPhotos(int count);

  /// EN09 moments tile detail.
  ///
  /// In vi, this message translates to:
  /// **'{count} video'**
  String rhWeekVideos(int count);

  /// EN09 moments tile detail.
  ///
  /// In vi, this message translates to:
  /// **'{count} ghi chú'**
  String rhWeekNotes(int count);

  /// EN09 note under the tiles (missing is never zero).
  ///
  /// In vi, this message translates to:
  /// **'Ngủ trung bình chỉ tính những ngày được ghi đủ, tự đếm theo nhật ký. Ngày thiếu ghi không bị tính là 0.'**
  String get rhWeekCoverageNote;

  /// EN09 family card title.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà đã cùng chăm'**
  String get rhWeekFamilyTitle;

  /// EN09 family card: log entries by one person.
  ///
  /// In vi, this message translates to:
  /// **'{who} {count} lần'**
  String rhWeekFamilyCount(String who, int count);

  /// EN09 family card without entries.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này chưa có ghi chép nào.'**
  String get rhWeekFamilyEmpty;

  /// EN09 family card footnote.
  ///
  /// In vi, this message translates to:
  /// **'Số lần ghi trong nhật ký, không xếp hạng.'**
  String get rhWeekFamilyNote;

  /// EN09 heading of what is already set for the next Monday–Sunday.
  ///
  /// In vi, this message translates to:
  /// **'Tuần tới'**
  String get rhWeekNextTitle;

  /// EN09 next week without items.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhắc việc hay mũi tiêm nào đặt cho tuần tới.'**
  String get rhWeekNextEmpty;

  /// EN09 next week: a reference-calendar window (never a forecast).
  ///
  /// In vi, this message translates to:
  /// **'{range} · tham khảo'**
  String rhWeekReference(String range);

  /// EN09 footer (561:3102).
  ///
  /// In vi, this message translates to:
  /// **'Không chấm điểm, không so sánh với bé khác.'**
  String get rhWeekNoScore;

  /// EN09 group A section heading.
  ///
  /// In vi, this message translates to:
  /// **'Nhìn lại tuần qua'**
  String get rhWeekInsightTitle;

  /// EN09 group A section subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ ghi nhận và nhật ký của nhà mình · không phải chẩn đoán'**
  String get rhWeekInsightSub;

  /// EN09 group A: the week’s check-ins.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận trong tuần'**
  String get rhWeekNotesTitle;

  /// EN09 group A: days whose check-ins report a change.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày có ghi nhận thay đổi'**
  String rhWeekChangedDays(int count);

  /// EN09 group A: one reported change and on how many days.
  ///
  /// In vi, this message translates to:
  /// **'{what} · {count} ngày'**
  String rhWeekObsDays(String what, int count);

  /// EN09 group A: days noted as usual.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày như mọi ngày'**
  String rhWeekUsualDays(int count);

  /// EN09 group A: mixed days (X03).
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày mỗi người thấy khác nhau · giữ cả hai ghi nhận'**
  String rhWeekMixedDays(int count);

  /// EN09 group A without check-ins.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này chưa có ghi nhận nào.'**
  String get rhWeekNoNotes;

  /// EN09 group A: activities tried and how they went.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử trong tuần'**
  String get rhWeekTriedTitle;

  /// EN09 group A without feedback.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này nhà mình chưa đánh dấu cách nào đã thử.'**
  String get rhWeekNoTried;

  /// EN09 group A: the current suggestion (PS02).
  ///
  /// In vi, this message translates to:
  /// **'Một ý tưởng cho tuần tới'**
  String get rhWeekNextIdea;

  /// EN09 gate, PREMIUM_REQUIRED.
  ///
  /// In vi, this message translates to:
  /// **'Phần nhìn lại (giấc ngủ so với mức thường của con, ghi nhận và cách đã thử) thuộc Hỗ trợ phù hợp.'**
  String get rhWeekGatePremium;

  /// EN09 gate, any other reason.
  ///
  /// In vi, this message translates to:
  /// **'Phần nhìn lại chưa mở cho bạn. Số liệu đã ghi ở trên vẫn dùng được.'**
  String get rhWeekGateOther;

  /// EN09 for a relative without “Chăm sóc hằng ngày” (history.read).
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần chỉ hiện với người được xem chăm sóc hằng ngày.'**
  String get rhWeekNoAccess;

  /// Shared text: heading of the figures.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi trong tuần (nhật ký Child Life):'**
  String get rhWeekShareFrom;

  /// Shared text: one figure.
  ///
  /// In vi, this message translates to:
  /// **'{label}: {value}'**
  String rhWeekShareLine(String label, String value);

  /// Shared text: the sleep average.
  ///
  /// In vi, this message translates to:
  /// **'trung bình {time} mỗi ngày ghi đủ'**
  String rhWeekShareSleep(String time);

  /// NL01 / Home entry action.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại tuần'**
  String get rhWeekOpen;

  /// NL02c switch subtitle (EN07 “Chủ nhật 20:30”).
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật 20:30 · trước giờ yên lặng'**
  String get rhWeekRemindSub;

  /// Sunday notification body: no baby name, no figures (R-120).
  ///
  /// In vi, this message translates to:
  /// **'Xem lại những gì cả nhà đã ghi trong tuần.'**
  String get rhWeekNotifBody;

  /// CH01 entry card title.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý Child Life'**
  String get asEntryTitle;

  /// CH01 entry card usage (server snapshot, never static).
  ///
  /// In vi, this message translates to:
  /// **'Còn {remaining}/{limit} lượt'**
  String asEntryLeft(int remaining, int limit);

  /// CH01 entry card when the household pool is used up. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hết lượt · làm mới {date}'**
  String asEntryOut(String date);

  /// Chat/Ô nhập placeholder (Trống).
  ///
  /// In vi, this message translates to:
  /// **'Hỏi, ghi nhanh hoặc gửi ảnh…'**
  String get asComposerHint;

  /// Composer placeholder while photo reading is off (assistant_images). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi hoặc ghi nhanh…'**
  String get asComposerHintText;

  /// Chat/Ô nhập "Chỉ xem" placeholder: a viewer may ask, never log. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Hỏi về nhật ký của bé…'**
  String get asComposerViewer;

  /// CH21 composer (Hết lượt, Free).
  ///
  /// In vi, this message translates to:
  /// **'Đã hết lượt AI tháng này'**
  String get asComposerOutFree;

  /// CH24 composer (Hết lượt, Premium).
  ///
  /// In vi, this message translates to:
  /// **'Hết lượt AI · vẫn ghi trực tiếp được'**
  String get asComposerOutPremium;

  /// Composer while answering a clarification ("Tự nhập"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời câu hỏi…'**
  String get asComposerAnswer;

  /// Composer send button label (a11y) and the kept-input send action.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get asSend;

  /// Composer camera button label (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get asAddPhoto;

  /// CH01 chip and CH21 direct-log button.
  ///
  /// In vi, this message translates to:
  /// **'Ghi cữ bú'**
  String get asChipLogFeed;

  /// CH01 "Ghi cữ bú" only prefills the composer; never sends. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Con bú bình lúc '**
  String get asPrefillFeed;

  /// CH01 chip / CH02 example (prefills this question).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay con bú thế nào?'**
  String get asChipFeedsToday;

  /// CH01 chip (photo reading on only).
  ///
  /// In vi, this message translates to:
  /// **'Chụp hoá đơn'**
  String get asChipReceipt;

  /// Floating assistant button a11y label. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở Lumi'**
  String get asFabLabel;

  /// CH01b entry in Chi tiêu.
  ///
  /// In vi, this message translates to:
  /// **'Chụp hoá đơn hoặc nhắn để ghi'**
  String get asModuleExpenseTitle;

  /// CH01b entry while photo reading is off. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn để ghi khoản chi'**
  String get asModuleExpenseTextOnly;

  /// CH01b entry subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý đọc và tạo bản nháp · bạn kiểm tra trước khi lưu'**
  String get asModuleSub;

  /// Chat header scope chip for the household.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get asScopeHousehold;

  /// Scope picker sheet title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện với'**
  String get asScopeTitle;

  /// Chat header history button (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get asHistory;

  /// Chat header new button (a11y) and CH03 "Hội thoại mới".
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại mới'**
  String get asNewChat;

  /// Usage pill screen-reader label. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượt hỗ trợ AI của hộ: còn {remaining} trên {limit}, làm mới {date}'**
  String asUsageA11y(int remaining, int limit, String date);

  /// Plan badge (CH19).
  ///
  /// In vi, this message translates to:
  /// **'Cơ bản'**
  String get asBadgeFree;

  /// Plan badge (CH19).
  ///
  /// In vi, this message translates to:
  /// **'Premium'**
  String get asBadgePremium;

  /// CH02 heading (child scope).
  ///
  /// In vi, this message translates to:
  /// **'Hỏi, ghi nhanh hoặc gửi ảnh cho {name}'**
  String asEmptyTitle(String name);

  /// CH02 heading while photo reading is off. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi hoặc ghi nhanh cho {name}'**
  String asEmptyTitleText(String name);

  /// CH02 heading (household scope). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi hoặc ghi nhanh cho cả nhà'**
  String get asEmptyTitleHousehold;

  /// CH02 body.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý hiểu và tạo bản nháp. Bạn kiểm tra trước khi lưu vào đúng chỗ.'**
  String get asEmptyBody;

  /// CH02 example card (prefills [asExampleFeedText]).
  ///
  /// In vi, this message translates to:
  /// **'“8 giờ con bú bình 120 ml”'**
  String get asExampleFeed;

  /// Text the CH02 example prefills (never sent by itself).
  ///
  /// In vi, this message translates to:
  /// **'8 giờ con bú bình 120 ml'**
  String get asExampleFeedText;

  /// CH02 example card.
  ///
  /// In vi, this message translates to:
  /// **'“Hôm nay con bú thế nào?”'**
  String get asExampleFeedsToday;

  /// CH02 example card, household scope (prefills without quotes). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'“Mua bỉm 310.000 đồng hôm qua”'**
  String get asExampleExpense;

  /// Text the household example prefills. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mua bỉm 310.000 đồng hôm qua'**
  String get asExampleExpenseText;

  /// CH02 example card (photo reading on only).
  ///
  /// In vi, this message translates to:
  /// **'Chụp hoá đơn → ghi chi tiêu'**
  String get asExampleReceipt;

  /// CH02 example card (photo reading on only).
  ///
  /// In vi, this message translates to:
  /// **'Chụp bảng note → nhắc việc'**
  String get asExampleNote;

  /// CH02 notice. G05: no deletion claim before deletion is confirmed. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn và ảnh bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu. Ảnh gốc giữ hay xoá theo lựa chọn của bạn.'**
  String get asPrivacyNote;

  /// CH02 notice while photo reading is off. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu.'**
  String get asPrivacyNoteText;

  /// Typing indicator while a text task is sent, queued or processing (chat rework 2026-10-15). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lumi đang soạn…'**
  String get asThinking;

  /// Cancel a task still being prepared (no charge without a useful answer). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get asCancelTask;

  /// A canceled task. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ.'**
  String get asCanceled;

  /// Kept input bubble marker (CH21 / CH25). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi'**
  String get asUnsent;

  /// Input bubble while sending. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi…'**
  String get asSending;

  /// CH04 assistant line when the server sent drafts without text.
  ///
  /// In vi, this message translates to:
  /// **'Mình thấy {count} việc. Kiểm tra rồi chọn mục muốn lưu nhé.'**
  String asDraftsFound(int count);

  /// UnsupportedCard for an unknown part type (brief p.11). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này cần bản app mới hơn để hiển thị. Không có gì được lưu.'**
  String get asUnsupportedPart;

  /// Restoring the last conversation. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở cuộc trò chuyện…'**
  String get asLoadingChat;

  /// Draft card state Nháp.
  ///
  /// In vi, this message translates to:
  /// **'Nháp'**
  String get asStateDraft;

  /// Draft card state Cần kiểm tra.
  ///
  /// In vi, this message translates to:
  /// **'Cần kiểm tra'**
  String get asStateReview;

  /// Draft card state Đang lưu. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu'**
  String get asStateSaving;

  /// Draft card state Đã lưu.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get asStateSaved;

  /// Draft card state Lưu lỗi (CH07 label).
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu'**
  String get asStateFailed;

  /// Draft card state Đã bỏ. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ'**
  String get asStateDiscarded;

  /// Draft card past its TTL (DRAFT_EXPIRED). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn'**
  String get asStateExpired;

  /// Draft kind bottle.
  ///
  /// In vi, this message translates to:
  /// **'Cữ bú bình'**
  String get asKindBottle;

  /// Draft kind breast. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cữ bú mẹ'**
  String get asKindBreast;

  /// Draft kind sleep.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get asKindSleep;

  /// Draft kind expense. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi'**
  String get asKindExpense;

  /// Draft kind reminder. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc'**
  String get asKindReminder;

  /// Draft kind observation (CH16 "Ghi nhận").
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận'**
  String get asKindObservation;

  /// Draft kind meal. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn'**
  String get asKindMeal;

  /// Draft of a kind this app version does not know (never saveable here). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mục chưa hỗ trợ'**
  String get asKindUnknown;

  /// Draft card scope row (care).
  ///
  /// In vi, this message translates to:
  /// **'{name} · Nhật ký chăm sóc'**
  String asModuleCare(String name);

  /// Draft card scope row (expense). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · Chi tiêu'**
  String get asModuleSpending;

  /// Draft card scope row (reminder). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · Nhắc việc'**
  String get asModuleReminders;

  /// Draft card scope row (observation).
  ///
  /// In vi, this message translates to:
  /// **'{name} · Nhịp lớn lên'**
  String asModuleRhythm(String name);

  /// Draft card scope row (meal). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} · Ăn dặm'**
  String asModuleMeal(String name);

  /// Draft line day ("Hôm nay 15/10").
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay {date}'**
  String asDayToday(String date);

  /// Draft line day. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua {date}'**
  String asDayYesterday(String date);

  /// Bottle amount.
  ///
  /// In vi, this message translates to:
  /// **'{ml} ml'**
  String asAmountMl(String ml);

  /// Draft line: amount missing. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chưa có lượng'**
  String get asNoAmount;

  /// Draft line: time missing. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chưa có giờ'**
  String get asNoTime;

  /// Draft line: date missing. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chưa có ngày'**
  String get asNoDate;

  /// Draft card action.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get asEdit;

  /// Draft card action.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ mục này'**
  String get asRemove;

  /// Saved card action (care).
  ///
  /// In vi, this message translates to:
  /// **'Mở nhật ký'**
  String get asOpenLog;

  /// Saved card action: opens the record in its module, never deletes by itself (G02).
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get asUndo;

  /// Saved card action (expense).
  ///
  /// In vi, this message translates to:
  /// **'Mở Chi tiêu'**
  String get asOpenSpending;

  /// Saved card action (reminder). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhắc việc'**
  String get asOpenReminders;

  /// Saved card action (observation).
  ///
  /// In vi, this message translates to:
  /// **'Xem nhịp của con'**
  String get asOpenRhythm;

  /// Conflict card action (CH07 "Xem bản Ba ghi"; the author is not known here). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem bản đã ghi'**
  String get asSeeLogged;

  /// Conflict card action (explicit confirm first).
  ///
  /// In vi, this message translates to:
  /// **'Vẫn lưu riêng'**
  String get asSaveAnyway;

  /// Draft card for a member who may not save that kind. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xem · không lưu qua chat'**
  String get asViewerDraftNote;

  /// MISSING_AMOUNT. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lượng (ml) trước khi lưu.'**
  String get asProblemMissingAmount;

  /// INVALID_AMOUNT. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng chưa hợp lệ.'**
  String get asProblemInvalidAmount;

  /// MISSING_TIME. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giờ trước khi lưu.'**
  String get asProblemMissingTime;

  /// FUTURE_TIME (CH06 "giờ trong tương lai"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ này ở tương lai — chỉ ghi việc đã xảy ra.'**
  String get asProblemFutureTime;

  /// INVALID_TIME. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ kết thúc phải sau giờ bắt đầu.'**
  String get asProblemInvalidTime;

  /// MISSING_DATE. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày trước khi lưu.'**
  String get asProblemMissingDate;

  /// CURRENCY_UNSUPPORTED (P-157). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu chưa hỗ trợ đơn vị tiền này.'**
  String get asProblemCurrency;

  /// MISSING_TITLE. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tên việc trước khi lưu.'**
  String get asProblemMissingTitle;

  /// needs_review / uncertain fields line. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại mục này rồi lưu.'**
  String get asNeedsReview;

  /// DOMAIN_CONFLICT (CH07 "Trùng với giấc … Chưa lưu."). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trùng với một bản đã ghi. Chưa lưu.'**
  String get asErrConflict;

  /// DUPLICATE_SUSPECTED. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có vẻ mục này đã được ghi. Chưa lưu.'**
  String get asErrDuplicate;

  /// WRITE_DENIED on an item. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò của bạn chưa được lưu mục này.'**
  String get asErrWriteDenied;

  /// DRAFT_EXPIRED. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp đã hết hạn. Nhắn lại để tạo bản mới.'**
  String get asErrExpired;

  /// DRAFT_STALE. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp vừa thay đổi. Xem lại rồi lưu.'**
  String get asErrStale;

  /// A system failure on an item (retryable). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Bạn thử lại nhé.'**
  String get asErrSaveFailed;

  /// SCOPE_CHANGED. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé đang chọn đã đổi. Mở lại đúng bé để lưu.'**
  String get asErrScope;

  /// MODULE_UNAVAILABLE on an item. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mục này chưa có nơi lưu trong app.'**
  String get asErrModule;

  /// CH04 batch primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu {count} mục đã chọn'**
  String asSaveSelected(int count);

  /// Batch primary with nothing selected (disabled). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mục muốn lưu'**
  String get asChooseToSave;

  /// CH04 batch secondary.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ tất cả'**
  String get asDiscardAll;

  /// CH07 summary (counts from the server results, never a fake 2/2).
  ///
  /// In vi, this message translates to:
  /// **'{saved}/{total} mục đã lưu · {failed} mục chưa lưu'**
  String asPartial(int saved, int total, int failed);

  /// CH07 retry (system failures only).
  ///
  /// In vi, this message translates to:
  /// **'Thử lại mục lỗi'**
  String get asRetryFailed;

  /// Under the CH07 retry. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại không trừ lượt.'**
  String get asRetryFree;

  /// Confirm while offline: drafts stay drafts. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến · chưa lưu gì. Có mạng rồi lưu lại.'**
  String get asSaveOffline;

  /// Confirm call failed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Bản nháp vẫn giữ nguyên.'**
  String get asSaveError;

  /// Confirm sheet for "Vẫn lưu riêng". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn lưu riêng?'**
  String get asSaveAnywayTitle;

  /// Confirm sheet body. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mục này trùng với một bản đã ghi. Lưu riêng sẽ có hai bản; bạn sửa hoặc xoá trong nhật ký được.'**
  String get asSaveAnywayBody;

  /// Confirm sheet primary. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu riêng'**
  String get asSaveSeparately;

  /// Generic cancel in assistant sheets.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get asCancel;

  /// CH05 footnote.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi làm rõ thuộc cùng tác vụ, không trừ thêm lượt.'**
  String get asClarifyFree;

  /// CH05 chip for another answer: a time picker for a time question (prefilled from what is known), else typing in the composer (chat rework 2026-10-15). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khác…'**
  String get asClarifyOwn;

  /// Clarification past its TTL. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi đã hết hạn. Nhắn lại để hỏi tiếp.'**
  String get asClarifyExpired;

  /// CH06 sheet title (bottle).
  ///
  /// In vi, this message translates to:
  /// **'Sửa cữ bú bình'**
  String get asEditBottle;

  /// CH06 sheet title (breast). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa cữ bú mẹ'**
  String get asEditBreast;

  /// CH06 sheet title (sleep). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giấc ngủ'**
  String get asEditSleep;

  /// CH06 field (locked to the chat scope).
  ///
  /// In vi, this message translates to:
  /// **'Bé'**
  String get asFieldBaby;

  /// CH06 date + time field. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get asFieldWhen;

  /// CH06 amount field.
  ///
  /// In vi, this message translates to:
  /// **'Lượng (ml)'**
  String get asFieldAmount;

  /// CH06 sleep start. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get asFieldStart;

  /// CH06 sleep end. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get asFieldEnd;

  /// CH06 breast duration. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Số phút'**
  String get asFieldMinutes;

  /// CH06 breast side. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bên'**
  String get asFieldSide;

  /// CH06 under the locked baby field. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Bé giữ theo cuộc trò chuyện; không chuyển bản nháp sang bé khác.'**
  String get asBabyLocked;

  /// CH06 primary (updates the draft only, never saves).
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật bản nháp'**
  String get asUpdateDraft;

  /// patchDraft failed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật được bản nháp. Thử lại.'**
  String get asEditFailed;

  /// CH08 meta ("Hôm nay 15/10 · đến 14:20").
  ///
  /// In vi, this message translates to:
  /// **'{day} · đến {time}'**
  String asSummaryMeta(String day, String time);

  /// CH08 bottle row.
  ///
  /// In vi, this message translates to:
  /// **'Bú bình · {count} cữ · {ml} ml'**
  String asSummaryBottle(int count, String ml);

  /// CH08 nursing row (minutes, never ml).
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ · {count} lần · {minutes} phút'**
  String asSummaryBreast(int count, int minutes);

  /// CH08 nursing note.
  ///
  /// In vi, this message translates to:
  /// **'Tính theo phút, không quy đổi ra ml'**
  String get asSummaryBreastNote;

  /// CH08 sleep row. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ · {count} giấc · {duration}'**
  String asSummarySleep(int count, String duration);

  /// CH08 with no records. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ghi nhận nào trong khoảng này.'**
  String get asSummaryNone;

  /// CH08 coverage partial / unknown ("các cữ đã ghi"). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tính trên các cữ đã ghi — có thể chưa đầy đủ.'**
  String get asSummaryPartial;

  /// CH08 coverage complete. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tính trên các cữ đã ghi trong ngày.'**
  String get asSummaryComplete;

  /// CH08 source link.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhật ký nguồn'**
  String get asOpenSourceLog;

  /// CH08 note under the card.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi không tạo cữ bú mới'**
  String get asNoRecordCreated;

  /// CH19 title.
  ///
  /// In vi, this message translates to:
  /// **'Lượt hỗ trợ AI'**
  String get asUsageTitle;

  /// CH19 total after the big number.
  ///
  /// In vi, this message translates to:
  /// **'/ {limit} lượt còn lại'**
  String asUsageOf(int limit);

  /// CH19 reset line (Free, calendar month).
  ///
  /// In vi, this message translates to:
  /// **'Làm mới {date} theo múi giờ của hộ · dùng chung cho cả hộ'**
  String asUsageResetFree(String date);

  /// CH19 reset line (Premium). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới {date} theo kỳ Premium · dùng chung cho cả hộ'**
  String asUsageResetPremium(String date);

  /// CH19 section.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi việc dùng khoảng'**
  String get asCostTitle;

  /// CH19 cost row.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi, ghi nhanh bằng chữ'**
  String get asCostText;

  /// CH19 cost row.
  ///
  /// In vi, this message translates to:
  /// **'Đọc 1 ảnh (hoá đơn, note)'**
  String get asCostPhoto;

  /// CH19 cost row.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi lại, sửa, xác nhận cùng tác vụ'**
  String get asCostFollowUp;

  /// CH19 cost row. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi hệ thống, ảnh không đọc được'**
  String get asCostError;

  /// CH19 cost row (health is free; missing in the frame). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sức khoẻ thiết yếu'**
  String get asCostHealth;

  /// CH19 cost value (from the server policy).
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt'**
  String asCostCredits(int count);

  /// CH19 cost value (G04: never wraps mid-word).
  ///
  /// In vi, this message translates to:
  /// **'Không thêm'**
  String get asCostNoExtra;

  /// CH19 cost value.
  ///
  /// In vi, this message translates to:
  /// **'Không trừ'**
  String get asCostNotCharged;

  /// CH19 cost value (health). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không trừ lượt'**
  String get asCostFree;

  /// CH19 recent tasks section.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get asRecentTitle;

  /// CH19 recent row (text task). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi hoặc ghi nhanh'**
  String get asRecentText;

  /// CH19 recent row (photo task). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đọc ảnh'**
  String get asRecentPhoto;

  /// CH19 separate video quota row. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xuất video kỷ niệm'**
  String get asVideoQuotaTitle;

  /// CH19 video quota line. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Quota riêng, không dùng lượt hỗ trợ AI · còn {left}/{limit}'**
  String asVideoQuotaSub(int left, int limit);

  /// CH19 Premium card (Free only).
  ///
  /// In vi, this message translates to:
  /// **'Premium có nhiều lượt hơn, cùng cá nhân hoá chủ động và mẫu thẻ/video Premium.'**
  String get asPremiumTeaser;

  /// CH19 / CH20 link to the paywall.
  ///
  /// In vi, this message translates to:
  /// **'Xem Premium'**
  String get asSeePremium;

  /// CH19 for a Premium household (no upsell). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hộ đang dùng Premium. Không có gói chat riêng.'**
  String get asPremiumHousehold;

  /// CH19 load error. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được mức dùng.'**
  String get asUsageFailed;

  /// Retry (CH25, CH03, CH19).
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get asRetry;

  /// CH20 attachment label (nothing uploaded).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh · chưa gửi'**
  String get asPhotoNotSent;

  /// CH20 warning (exact quote, not an estimate).
  ///
  /// In vi, this message translates to:
  /// **'Đọc ảnh này cần {credits} lượt, bạn còn {remaining}.'**
  String asPhotoQuoteTitle(int credits, int remaining);

  /// CH20 body (Free).
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể nhập tay, đợi làm mới {date}, hoặc nâng cấp để tiếp tục ngay. Ảnh chưa được gửi đi.'**
  String asPhotoQuoteFree(String date);

  /// CH20 body (Premium: no other pack). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể nhập tay hoặc đợi làm mới {date}. Ảnh chưa được gửi đi.'**
  String asPhotoQuotePremium(String date);

  /// CH20 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tay'**
  String get asTypeInstead;

  /// Removes the pending photo (never uploaded). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get asRemovePhoto;

  /// CH21 title.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã dùng hết lượt hỗ trợ AI tháng này.'**
  String get asOutTitleFree;

  /// CH21 body.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi của bạn được giữ lại. Bạn vẫn ghi trực tiếp và xem nhật ký như thường.'**
  String get asOutBodyFree;

  /// CH21 direct action.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhật ký hôm nay'**
  String get asOpenTodayLog;

  /// CH21 primary (paywall; resumes the kept question once after a verified purchase).
  ///
  /// In vi, this message translates to:
  /// **'Nâng cấp & tiếp tục câu hỏi'**
  String get asUpgradeContinue;

  /// CH21 / CH24 note, now with a link. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sức khoẻ thiết yếu vẫn mở.'**
  String get asHealthStillOpen;

  /// Link to HL01 (CH21, CH24, CH27, CH28).
  ///
  /// In vi, this message translates to:
  /// **'Mở Hướng dẫn sức khoẻ'**
  String get asOpenHealth;

  /// CH24 title.
  ///
  /// In vi, this message translates to:
  /// **'Hộ đã dùng hết lượt hỗ trợ AI kỳ này.'**
  String get asOutTitlePremium;

  /// CH24 body.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới {date}. Bạn vẫn ghi trực tiếp, xem nhật ký, dùng mẫu Premium và quota xuất video riêng.'**
  String asOutBodyPremium(String date);

  /// CH24 button.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết mức dùng'**
  String get asSeeUsage;

  /// CH21 / CH24 when ready drafts exist (brief p.17). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp đã sẵn sàng vẫn lưu được, không cần lượt.'**
  String get asReadyStillSave;

  /// CH23 banner.
  ///
  /// In vi, this message translates to:
  /// **'Hộ đã có Premium · tiếp tục câu hỏi đang chờ'**
  String get asResumedBanner;

  /// CH23 note.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi được tính 1 lần sau khi có câu trả lời, không tính lúc hết lượt.'**
  String get asResumedNote;

  /// PR02 success button when the purchase came from the chat. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục câu hỏi'**
  String get asContinueQuestion;

  /// CH25 error card.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý chưa phản hồi được'**
  String get asFailTitle;

  /// CH25 error body.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gì được lưu. Lượt này không bị trừ; thử lại cũng không trừ hai lần.'**
  String get asFailBody;

  /// CH25 secondary (opens Ghi nhanh).
  ///
  /// In vi, this message translates to:
  /// **'Ghi trực tiếp'**
  String get asLogDirectly;

  /// CH25 offline card.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến'**
  String get asOfflineTitle;

  /// CH25 offline body: kept, never auto-sent (no charge without a tap). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn được giữ lại, chưa gửi. Khi có mạng, bấm Gửi để gửi. Ghi trực tiếp trong các module vẫn lưu trên máy.'**
  String get asOfflineBody;

  /// Any other failure. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Chưa có gì được lưu.'**
  String get asGenericError;

  /// CH26 title.
  ///
  /// In vi, this message translates to:
  /// **'Trước khi dùng trợ lý'**
  String get asConsentTitle;

  /// CH26 row 1.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn và ảnh bạn gửi được AI xử lý để hiểu và tạo bản nháp.'**
  String get asConsent1;

  /// CH26 row 2 (G05: no deletion claim before it is confirmed). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ gửi ảnh bạn chọn. Ảnh gốc giữ hay xoá theo lựa chọn của bạn; app chỉ báo đã xoá khi việc xoá được xác nhận.'**
  String get asConsent2;

  /// CH26 row 3 (D-003: nickname, never the real name). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dùng tên gọi của bé; không gửi tên đầy đủ hay ngày sinh chính xác.'**
  String get asConsent3;

  /// CH26 row 4.
  ///
  /// In vi, this message translates to:
  /// **'Không tự lưu. Bạn kiểm tra trước khi ghi vào nhật ký.'**
  String get asConsent4;

  /// CH26 provider and retention (D-003), replacing the internal "chờ chính sách được duyệt". Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Một dịch vụ AI bên ngoài xử lý qua máy chủ Child Life, điện thoại không gửi trực tiếp; nhà cung cấp không được lưu giữ dữ liệu này.'**
  String get asConsentProvider;

  /// CH26 privacy (P-158) and withdrawal. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Với Ba, Mẹ và người chăm sóc, câu hỏi về bé nằm trong cuộc trò chuyện chung của bé. Ảnh, chi tiêu và mọi câu hỏi khác chỉ bạn thấy. Bạn đổi ý lúc nào cũng được.'**
  String get asConsentPrivate;

  /// CH26 primary.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý và bắt đầu'**
  String get asConsentAgree;

  /// CH26 secondary (the app stays usable).
  ///
  /// In vi, this message translates to:
  /// **'Không dùng trợ lý'**
  String get asConsentDecline;

  /// Toast after declining. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã không dùng trợ lý. Ghi trực tiếp vẫn dùng như bình thường.'**
  String get asConsentDeclined;

  /// Consent call failed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được lựa chọn. Kiểm tra kết nối và thử lại.'**
  String get asConsentFailed;

  /// CH27 viewer card (second person: the viewer is the one chatting). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang có quyền xem'**
  String get asViewerTitle;

  /// CH27 viewer body.
  ///
  /// In vi, this message translates to:
  /// **'Người chỉ có quyền xem không ghi được qua chat. Bạn vẫn hỏi và xem tổng hợp được.'**
  String get asViewerBody;

  /// WRITE_DENIED for a member who writes other modules. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được qua chat'**
  String get asWriteDeniedTitle;

  /// WRITE_DENIED body. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò của bạn chưa được ghi mục này. Bạn vẫn hỏi và xem tổng hợp được.'**
  String get asWriteDeniedBody;

  /// READ_DENIED body. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò của bạn chưa được xem dữ liệu này.'**
  String get asReadDeniedBody;

  /// CH27 module unavailable (no direct "Lưu thành nhắc việc": every write is a draft first). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nơi lưu việc này'**
  String get asModuleTitle;

  /// CH27 module unavailable body. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'App chưa có module cho loại việc này nên không tạo bản ghi. Bạn có thể nhắn lại thành nhắc việc có ngày giờ để có bản nháp kiểm tra.'**
  String get asModuleBody;

  /// CH27 region card.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực chưa hỗ trợ'**
  String get asRegionTitle;

  /// CH27 region body.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý chăm sóc qua chat chưa mở ở khu vực của hộ. Ghi nhanh và hỏi dữ liệu vẫn dùng được.'**
  String get asRegionBody;

  /// FEATURE_DISABLED (kill switch, P-161). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý đang tạm nghỉ'**
  String get asOffTitle;

  /// FEATURE_DISABLED body. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử và ghi trực tiếp vẫn dùng được.'**
  String get asOffBody;

  /// NOT_MEMBER. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn trong gia đình của bé này.'**
  String get asNotMemberBody;

  /// CH28 title.
  ///
  /// In vi, this message translates to:
  /// **'Hãy liên hệ hỗ trợ y tế ngay'**
  String get asHealthTitle;

  /// CH28 body.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý không phải dịch vụ cấp cứu và không đánh giá được tình trạng của bé.'**
  String get asHealthBody;

  /// CH28 emergency button with the number from the health pack for the household country. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Gọi {number}'**
  String asHealthCall(String number);

  /// CH28 when the health pack has no number for the household country (never a default hotline).
  ///
  /// In vi, this message translates to:
  /// **'Gọi bác sĩ của bé'**
  String get asHealthCallDoctor;

  /// CH28 footnote (without the internal "nội dung y tế chờ duyệt theo vùng"). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Không trừ lượt'**
  String get asHealthFree;

  /// Dialer failed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được ứng dụng gọi điện.'**
  String get asDialFailed;

  /// CH03 title.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại'**
  String get asHistoryTitle;

  /// CH03 section.
  ///
  /// In vi, this message translates to:
  /// **'HÔM NAY'**
  String get asHistoryToday;

  /// CH03 section.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN NÀY'**
  String get asHistoryWeek;

  /// CH03 section. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'TRƯỚC ĐÓ'**
  String get asHistoryEarlier;

  /// CH03 row without a title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc trò chuyện'**
  String get asHistoryUntitled;

  /// CH03 footnote.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi bé có lịch sử riêng. Đổi bé không chuyển bản nháp đang chờ sang bé khác.'**
  String get asHistoryFootnote;

  /// CH03 privacy line (P-158). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn xem được các cuộc trò chuyện của mình. Bản ghi đã lưu vẫn chia sẻ theo vai trò.'**
  String get asHistoryPrivate;

  /// CH03 empty. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cuộc trò chuyện nào.'**
  String get asHistoryEmpty;

  /// CH03 load error ("tải lỗi → thử lại"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được lịch sử.'**
  String get asHistoryFailed;

  /// CH03 row action. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá cuộc trò chuyện'**
  String get asDeleteChat;

  /// CH03 confirm title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá cuộc trò chuyện?'**
  String get asDeleteTitle;

  /// CH03 confirm body (domain records stay). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn và bản nháp chưa lưu trong cuộc trò chuyện này sẽ bị xoá. Những gì đã lưu vào nhật ký, Chi tiêu hay nhắc việc vẫn giữ nguyên.'**
  String get asDeleteBody;

  /// CH03 confirm button. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get asDeleteConfirm;

  /// Toast after the server confirmed the delete. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá cuộc trò chuyện'**
  String get asDeleted;

  /// Delete failed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xoá được. Thử lại sau.'**
  String get asDeleteFailed;

  /// CH09 sheet title. Slice A5.
  ///
  /// In vi, this message translates to:
  /// **'Gửi ảnh để trợ lý đọc'**
  String get asPhotoSheetTitle;

  /// CH09 camera row subtitle. Slice A5.
  ///
  /// In vi, this message translates to:
  /// **'Hoá đơn, bảng note'**
  String get asPhotoCameraSub;

  /// CH09 library row subtitle. Slice A5.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh bạn chọn được gửi'**
  String get asPhotoLibrarySub;

  /// CH09 estimate heading with the server policy / quote number (exact, not "khoảng"). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Đọc 1 ảnh dùng {credits} lượt hỗ trợ AI'**
  String asPhotoQuoteExact(int credits);

  /// CH09 sheet body (no deletion promise before reading, G05). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Còn {remaining} lượt. Bạn thấy đúng số lượt trước khi gửi; ảnh không đọc được thì không trừ.'**
  String asPhotoSheetBody(int remaining);

  /// CH09 sheet body while usage is unknown. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thấy đúng số lượt trước khi gửi; ảnh không đọc được thì không trừ.'**
  String get asPhotoSheetBodyUnknown;

  /// CH09 card after choosing (nothing uploaded yet). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đã chọn · chưa gửi'**
  String get asPhotoChosenTitle;

  /// CH09 card: which photo is sent (annotation 618:10251). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh này được gửi để đọc.'**
  String get asPhotoOnlyThis;

  /// CH09 quote body (G05: no deletion promise here). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Còn {remaining} lượt. Hỏi lại, sửa và xác nhận trong cùng tác vụ không trừ thêm. Ảnh không đọc được thì không trừ.'**
  String asPhotoQuoteBody(int remaining);

  /// CH09 retention switch (default on, D-075 #3). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giữ ảnh hoá đơn cùng khoản chi'**
  String get asKeepReceipt;

  /// CH09 retention on (keep_with_record). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khi bạn lưu khoản chi, ảnh được giữ cùng khoản chi. Không lưu thì ảnh được xoá.'**
  String get asKeepReceiptOn;

  /// CH09 retention off (delete_after_read; G05). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được xoá sau khi đọc. App chỉ báo đã xoá khi việc xoá được xác nhận.'**
  String get asKeepReceiptOff;

  /// CH09 / CH14 notice (618:10251, 614:9037).
  ///
  /// In vi, this message translates to:
  /// **'Chữ trong ảnh là nội dung để đọc, không phải lệnh cho app.'**
  String get asPhotoTextIsData;

  /// CH09 primary ("Tiếp tục" in the frame): uploads and reads. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gửi ảnh'**
  String get asSendPhoto;

  /// Photo bubble while the quote is asked. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang tính lượt…'**
  String get asPhotoQuoting;

  /// Picker failed (not a permission). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được ảnh. Thử lại hoặc chọn ảnh khác.'**
  String get asPhotoPickFailed;

  /// CH10 attachment label.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lên · {percent}%'**
  String asUploading(int percent);

  /// CH10 cancel while uploading (0 credits; missing in the frame, annotation 618:10257). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get asCancelUpload;

  /// CH10 note while uploading. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ khi đang tải lên không trừ lượt.'**
  String get asUploadFree;

  /// After cancelling an upload. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ tải lên. Ảnh vẫn được chọn.'**
  String get asUploadCanceled;

  /// CH10 attachment label (neutral: it may not be a receipt). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Đang đọc ảnh…'**
  String get asPhotoReading;

  /// CH11 / CH13 attachment label.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc'**
  String get asPhotoRead;

  /// CH14 attachment label.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hơi mờ'**
  String get asPhotoBlurry;

  /// Attachment refused before reading (not an image). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được tệp này'**
  String get asPhotoRefused;

  /// Attachment of a cancelled task. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ'**
  String get asPhotoCanceled;

  /// CH10 note (no notification promise: none is built). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể rời màn hình; kết quả vẫn ở đây khi bạn quay lại.'**
  String get asPhotoLeaveScreen;

  /// CH25 for a photo upload / start failure. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chưa được đọc và chưa có gì được lưu. Ảnh vẫn được chọn.'**
  String get asPhotoFailBody;

  /// CH11 card title.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu từ hoá đơn'**
  String get asReceiptTitle;

  /// CH11 field.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng'**
  String get asFieldStore;

  /// CH11 field.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get asFieldDate;

  /// CH11 field.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get asFieldTotal;

  /// CH11 field.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục gợi ý'**
  String get asFieldCategory;

  /// CH11 field.
  ///
  /// In vi, this message translates to:
  /// **'Phạm vi'**
  String get asFieldScope;

  /// Expense editor field. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tiền'**
  String get asFieldCurrency;

  /// Reminder editor title field. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Việc'**
  String get asFieldTitle;

  /// Reminder editor time field. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get asFieldTime;

  /// Screen-reader label of a flagged receipt field. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{label}: {value}, cần kiểm tra'**
  String asFieldCheckA11y(String label, String value);

  /// Receipt field the reading did not find. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chưa đọc được'**
  String get asNotRead;

  /// CH11 scope value.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · cho {name}'**
  String asExpenseFor(String name);

  /// CH11 footnote.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ghi tổng tiền {total} (đã gồm thuế), không cộng thêm tạm tính hay thuế.'**
  String asTaxIncluded(String total);

  /// CH11 "Ngày không chắc → bắt chọn ngày" (618:10262). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày chưa chắc: chạm vào ngày để chọn hoặc xác nhận trước khi lưu.'**
  String get asConfirmDate;

  /// CH11 duplicate box (author/time not known to the app). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Có thể trùng với một khoản đã ghi trong gia đình. Mình không tự gộp.'**
  String get asDuplicateBody;

  /// CH11 duplicate after "Vẫn lưu". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chọn vẫn lưu riêng · không gộp.'**
  String get asDuplicateAcknowledged;

  /// CH11 duplicate action (opens Chi tiêu history). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở khoản chi trùng'**
  String get asOpenDuplicate;

  /// CH11 duplicate acknowledge (annotation "Gộp/Vẫn lưu"; never merged).
  ///
  /// In vi, this message translates to:
  /// **'Vẫn lưu'**
  String get asSaveAnywayShort;

  /// CH11 save action.
  ///
  /// In vi, this message translates to:
  /// **'Lưu chi tiêu'**
  String get asSaveExpense;

  /// CH11 discard action.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get asSkip;

  /// Expense editor title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản chi'**
  String get asEditExpense;

  /// Expense editor note (brief p.14). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ tổng tiền in trên hoá đơn; không cộng tạm tính và thuế.'**
  String get asTotalOnly;

  /// Date wheel title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get asPickDate;

  /// Time wheel title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ'**
  String get asPickTime;

  /// G05: a copy is kept with the saved expense (server confirmed). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hoá đơn được giữ cùng khoản chi trong Chi tiêu.'**
  String get asRetentionKept;

  /// G05: keep_with_record, nothing saved yet. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được giữ cùng khoản chi khi bạn lưu; nếu không lưu, ảnh sẽ được xoá.'**
  String get asRetentionKeptIfSaved;

  /// G05: deletion requested / pending, not confirmed. Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá ảnh gốc. App chỉ báo đã xoá khi việc xoá được xác nhận.'**
  String get asRetentionDeleting;

  /// G05: Storage confirmed the deletion (replaces CH12 "đã xoá sau khi đọc (theo cài đặt hiện tại)"). Deviates from the frame on purpose (business rule wins; see the A4 report).
  ///
  /// In vi, this message translates to:
  /// **'Ảnh gốc đã được xoá.'**
  String get asRetentionDeleted;

  /// G05: delete_after_read, not deleted yet. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh gốc sẽ được xoá sau khi đọc; app báo khi xoá xong.'**
  String get asRetentionWillDelete;

  /// CH13 card line ("Nhắc: Thứ Ba 20/10 · 09:00"; the real weekday, G03).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc: {when}'**
  String asRemindLine(String when);

  /// CH13 card scope row.
  ///
  /// In vi, this message translates to:
  /// **'{name} · Nhắc việc'**
  String asModuleRemindersOf(String name);

  /// CH13 action on a reminder that needs a date or time. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày giờ'**
  String get asCheckReminder;

  /// Reminder editor title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhắc việc'**
  String get asEditReminder;

  /// Reminder editor: date-only (only while the server accepts it). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không đặt giờ'**
  String get asAllDay;

  /// Reminder editor note. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc lưu cho {name}; không chuyển sang bé khác.'**
  String asReminderBaby(String name);

  /// INVALID_TITLE. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tên việc dài quá (tối đa 80 ký tự).'**
  String get asProblemInvalidTitle;

  /// PAST_TIME (D-031). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc đã qua — chọn một giờ sắp tới.'**
  String get asProblemPastTime;

  /// CH14 chip.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại'**
  String get asRetake;

  /// Chip after a refused file. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh khác'**
  String get asOtherPhoto;

  /// CH14 note (0 credits).
  ///
  /// In vi, this message translates to:
  /// **'Lần đọc này không trừ lượt.'**
  String get asUnreadableFree;

  /// CH15 safety box (now with a link).
  ///
  /// In vi, this message translates to:
  /// **'Nếu con sốt, khó thở, li bì hoặc bỏ bú — mở Hướng dẫn sức khoẻ.'**
  String get asSleepSafety;

  /// Sleep concern kind.
  ///
  /// In vi, this message translates to:
  /// **'khó vào giấc'**
  String get asSleepFalling;

  /// Sleep concern kind.
  ///
  /// In vi, this message translates to:
  /// **'hay thức giấc'**
  String get asSleepWaking;

  /// Sleep concern kind both. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'khó vào giấc và hay thức giấc'**
  String get asSleepBoth;

  /// Sleep concern time.
  ///
  /// In vi, this message translates to:
  /// **'giấc đêm'**
  String get asWhenNight;

  /// Sleep concern time.
  ///
  /// In vi, this message translates to:
  /// **'giấc ngày'**
  String get asWhenDay;

  /// Sleep concern time both. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'cả ngày và đêm'**
  String get asWhenBoth;

  /// CH16 kicker.
  ///
  /// In vi, this message translates to:
  /// **'Từ Thư viện chăm bé'**
  String get asFromCareLibrary;

  /// CH16 kicker with the content duration. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Từ Thư viện chăm bé · {minutes} phút'**
  String asFromCareLibraryMinutes(int minutes);

  /// CH16 disclaimer while reviewed is false (D-073 #2).
  ///
  /// In vi, this message translates to:
  /// **'Biên soạn theo hướng dẫn WHO, AAP, NHS · tham khảo, không thay thế bác sĩ. Không khẳng định nguyên nhân.'**
  String get asContentUnreviewed;

  /// CH16 line when the content is reviewed. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung đã được chuyên môn duyệt. Không khẳng định nguyên nhân.'**
  String get asContentReviewed;

  /// CH16 primary: an intention, not "đã thử".
  ///
  /// In vi, this message translates to:
  /// **'Thử tối nay'**
  String get asTryTonight;

  /// CH16 primary for a daytime item. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thử hôm nay'**
  String get asTryToday;

  /// CH16 secondary (opens the next approved item in the care library).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý khác'**
  String get asAnotherIdea;

  /// CH16 after "Thử tối nay" (an intention). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn định thử tối nay'**
  String get asPlannedTonight;

  /// CH16 after "Thử hôm nay". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn định thử hôm nay'**
  String get asPlannedToday;

  /// CH16 → CH17 timing note. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mình sẽ hỏi lại từ {day}, sau khi bạn có dịp thử.'**
  String asPlanFollowUp(String day);

  /// CH16 observation draft title (G01: an observation, not a reminder).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận (tuỳ chọn)'**
  String get asObservationTitle;

  /// CH16 observation line when nothing more was reported. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'giấc ngủ'**
  String get asObservationSleep;

  /// CH16 observation save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ghi nhận'**
  String get asSaveObservation;

  /// CH16 observation discard.
  ///
  /// In vi, this message translates to:
  /// **'Không cần'**
  String get asNoThanks;

  /// Link after "chưa có gợi ý đã duyệt". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở Thư viện chăm bé'**
  String get asOpenCareLibrary;

  /// CH17 outcome.
  ///
  /// In vi, this message translates to:
  /// **'Có ích'**
  String get asOutcomeHelpful;

  /// CH17 outcome.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ'**
  String get asOutcomeUnsure;

  /// CH17 outcome.
  ///
  /// In vi, this message translates to:
  /// **'Không phù hợp'**
  String get asOutcomeNotSuitable;

  /// CH17 outcome (always offered). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thử'**
  String get asOutcomeNotTried;

  /// CH17 after Có ích.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi phản hồi. Lần sau mình sẽ ưu tiên cách này. “Có ích” không có nghĩa cách này là nguyên nhân thay đổi.'**
  String get asFeedbackHelpful;

  /// CH17 after Chưa rõ. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi phản hồi. Mình sẽ cân nhắc khi gợi ý lần sau.'**
  String get asFeedbackUnsure;

  /// CH17 after Không phù hợp. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi phản hồi. Lần sau mình sẽ không gợi ý cách này.'**
  String get asFeedbackNotSuitable;

  /// CH17 after Chưa thử (nothing written to the module). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không sao. Khi nào thử, bạn có thể ghi lại trong Nhịp lớn lên.'**
  String get asFeedbackNotTried;

  /// CH17 saved card title.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi hoạt động'**
  String get asFeedbackTitle;

  /// CH17 note.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi không trừ lượt hỗ trợ AI.'**
  String get asFeedbackFree;

  /// CH18 card label. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý từ Thư viện công thức'**
  String get asRecipesFrom;

  /// CH18 recipe duration.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String asRecipeMinutes(int minutes);

  /// CH18 excluded count.
  ///
  /// In vi, this message translates to:
  /// **'Đã loại {count} món có nguyên liệu con từng có phản ứng (phản ứng đã ghi, không phải chẩn đoán dị ứng).'**
  String asRecipesExcluded(int count);

  /// CH18 caveat when the server sent none.
  ///
  /// In vi, this message translates to:
  /// **'Món chưa có ghi nhận phản ứng không có nghĩa là con đã dung nạp tốt.'**
  String get asRecipesCaveat;

  /// CH18 meal log button (disabled: no meal log yet). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bữa ăn'**
  String get asLogMeal;

  /// CH18 under the disabled "Ghi bữa ăn" (P-157). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhật ký bữa ăn trong app nên chưa ghi được từ đây.'**
  String get asLogMealUnavailable;

  /// INVALID_ASSIGNEE (D-075 #5). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Người được giao không còn trong gia đình. Chọn lại người phụ trách.'**
  String get asProblemInvalidAssignee;

  /// Shared thread: another member confirmed drafts (action_result author, D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã lưu {count} mục'**
  String asSavedBy(String name, int count);

  /// Saved draft card: who saved it when not me (draft.confirmedBy, D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã lưu'**
  String asConfirmedBy(String name);

  /// Shared thread: only the task author answers its clarification (D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chờ {name} trả lời câu hỏi này.'**
  String asWaitingFor(String name);

  /// Private photo task in a child chat of a shared-thread member (D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn thấy: ảnh và chi tiêu không vào cuộc trò chuyện chung của bé.'**
  String get asPrivateTask;

  /// CH03 section for the baby’s shared thread (D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'CUỘC TRÒ CHUYỆN CHUNG'**
  String get asHistoryShared;

  /// CH03 shared thread title. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện chung về bé'**
  String get asSharedThreadTitle;

  /// CH03 shared thread subtitle. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ba, Mẹ và người chăm sóc cùng xem · {when}'**
  String asSharedThreadSub(String when);

  /// CH03 privacy line for Cùng nuôi / Người chăm sóc (D-075 #2). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi về bé nằm trong cuộc trò chuyện chung của Ba, Mẹ và người chăm sóc. Ảnh, chi tiêu và các cuộc trò chuyện cũ chỉ bạn xem được.'**
  String get asHistorySharedNote;

  /// CH03 confirm for the shared thread (Cùng nuôi only). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá cuộc trò chuyện chung?'**
  String get asDeleteSharedTitle;

  /// CH03 confirm body for the shared thread. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc trò chuyện chung sẽ bị xoá cho mọi người, kể cả bản nháp chưa lưu. Những gì đã lưu vào nhật ký, Nhịp lớn lên hay nhắc việc vẫn giữ nguyên.'**
  String get asDeleteSharedBody;

  /// Toast after delete when the server confirms domainRecordsKept. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá cuộc trò chuyện. Bản ghi đã lưu vẫn giữ nguyên.'**
  String get asDeletedRecordsKept;

  /// CH19 cost row: an AI summary takes 1 credit from the same pool (D-075 #1); a template or cached one is free. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bằng AI (bàn giao, giải thích)'**
  String get asCostSummary;

  /// CH19 recent row: an AI handover summary (D-075 #1). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bàn giao bằng AI'**
  String get asRecentHandover;

  /// CH19 recent row: an AI explanation (D-075 #1). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích gợi ý bằng AI'**
  String get asRecentExplain;

  /// CH19 recent row: an AI moment summary (D-075 #1). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt khoảnh khắc bằng AI'**
  String get asRecentMoment;

  /// CH19 recent row: an AI summary of another kind. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt bằng AI'**
  String get asRecentSummary;

  /// CH19 recent value: credits reserved by work still running (not counted yet). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'đang giữ {credits} lượt'**
  String asRecentHeld(int credits);

  /// CH19 recent value: a reservation released (error, unreadable photo, cancel, template answer). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'0 lượt · đã hoàn lại'**
  String get asRecentReleased;

  /// CH19 recent value: work that never costs credits (health support). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'0 lượt · không tính'**
  String get asRecentFree;

  /// CH19 recent section when the server sends an empty list. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa dùng lượt nào trong kỳ này.'**
  String get asRecentEmpty;

  /// CH03 row status from the last task: drafts saved ("2 mục đã lưu · 09:12").
  ///
  /// In vi, this message translates to:
  /// **'{count} mục đã lưu'**
  String asHistorySaved(int count);

  /// CH03 row status: the last task asks a clarification still open. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có câu hỏi đang chờ trả lời'**
  String get asHistoryNeedsAnswer;

  /// CH03 row status: a care try waiting for feedback (CH17). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ phản hồi sau khi thử'**
  String get asHistoryAwaitingFeedback;

  /// CH03 pill: drafts of the last task still waiting to be saved ("1 nháp").
  ///
  /// In vi, this message translates to:
  /// **'{count} nháp'**
  String asHistoryDrafts(int count);

  /// CH08 one bottle feed in the per-feed line ("08:00 150 ml").
  ///
  /// In vi, this message translates to:
  /// **'{time} {ml} ml'**
  String asSummaryFeedMl(String time, String ml);

  /// CH08 one nursing session in the per-feed line (minutes, never ml). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{time} {minutes} phút'**
  String asSummaryFeedMinutes(String time, int minutes);

  /// 4a title; Chăm sóc tile.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện chăm bé'**
  String get lbTitle;

  /// 4a pill, 4f title, 4e save pill when saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get lbSaved;

  /// 4a / 4b search placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm: ngủ ngày, nấc, hăm tã…'**
  String get lbSearchHint;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Bú & sữa'**
  String get lbTopicFeeding;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ngủ'**
  String get lbTopicSleep;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Mọc răng'**
  String get lbTopicTeething;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Sốt & ốm vặt'**
  String get lbTopicIllness;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Chăm hằng ngày'**
  String get lbTopicDailyCare;

  /// 4a topic tile.
  ///
  /// In vi, this message translates to:
  /// **'Phát triển'**
  String get lbTopicDevelopment;

  /// 4a section: articles for the baby's age.
  ///
  /// In vi, this message translates to:
  /// **'Hợp với {name} · {age}'**
  String lbForBaby(String name, String age);

  /// 4a section link → 4b with the age band.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get lbSeeMore;

  /// 4a section.
  ///
  /// In vi, this message translates to:
  /// **'Mới cập nhật'**
  String get lbRecent;

  /// Reading time.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút đọc'**
  String lbMinutes(int count);

  /// Reading time on cards.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút'**
  String lbMinutesShort(int count);

  /// Age range in weeks.
  ///
  /// In vi, this message translates to:
  /// **'{from}–{to} tuần'**
  String lbRangeWeeks(int from, int to);

  /// Age range in months.
  ///
  /// In vi, this message translates to:
  /// **'{from}–{to} tháng'**
  String lbRangeMonths(int from, int to);

  /// Age range in years.
  ///
  /// In vi, this message translates to:
  /// **'{from}–{to} tuổi'**
  String lbRangeYears(int from, int to);

  /// 2a stage covering one week.
  ///
  /// In vi, this message translates to:
  /// **'{count} tuần'**
  String lbStageWeek(int count);

  /// 2a stage covering one month.
  ///
  /// In vi, this message translates to:
  /// **'{count} tháng'**
  String lbStageMonth(int count);

  /// 4d byline / 2b footnote once an expert signed it (no claim before, P-141).
  ///
  /// In vi, this message translates to:
  /// **'Được {reviewer} · {credential} rà soát {month}'**
  String lbReviewedBy(String reviewer, String credential, String month);

  /// Small footnote at the end of an article or stage until an expert signs it (D-082; was a badge).
  ///
  /// In vi, this message translates to:
  /// **'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ'**
  String get lbIllustrative;

  /// Offline banner (2c pattern).
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối. Thư viện đang hiện bản đã lưu trên máy.'**
  String get lbOfflineLibrary;

  /// 2c offline banner (renamed from "Thẻ theo tuổi", D-076 #5).
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối. Giai đoạn của bé đang hiện bản đã lưu trên máy.'**
  String get lbOfflineStages;

  /// Nothing published yet.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện đang được chuẩn bị'**
  String get lbEmptyTitle;

  /// Nothing published yet.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết sẽ hiện ở đây ngay khi được xuất bản.'**
  String get lbEmptyBody;

  /// Offline before the first load.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản lưu trên máy'**
  String get lbEmptyOfflineTitle;

  /// Offline before the first load.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối mạng một lần để tải nội dung, sau đó đọc được cả khi không có mạng.'**
  String get lbEmptyOfflineBody;

  /// 4b result count.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài viết'**
  String lbResults(int count);

  /// 4b pill, 4c title.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get lbFilters;

  /// 4b pill with filters on.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc · {count}'**
  String lbFiltersCount(int count);

  /// 4b removable chip (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lọc {label}'**
  String lbRemoveFilter(String label);

  /// 4b clear button (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Xoá tìm kiếm'**
  String get lbClearSearch;

  /// 4b sort sheet.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp'**
  String get lbSortTitle;

  /// 4b sort.
  ///
  /// In vi, this message translates to:
  /// **'Liên quan nhất'**
  String get lbSortRelevant;

  /// 4b sort.
  ///
  /// In vi, this message translates to:
  /// **'Mới cập nhật'**
  String get lbSortNewest;

  /// 4b sort.
  ///
  /// In vi, this message translates to:
  /// **'Đọc nhanh nhất'**
  String get lbSortShortest;

  /// 4b no results.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bài phù hợp'**
  String get lbNoResults;

  /// 4b no results.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khoá khác hoặc bỏ bớt bộ lọc.'**
  String get lbNoResultsHint;

  /// 4c group.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề'**
  String get lbFilterTopic;

  /// 4c group.
  ///
  /// In vi, this message translates to:
  /// **'Độ tuổi'**
  String get lbFilterAge;

  /// 4c group.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian đọc'**
  String get lbFilterTime;

  /// 4c chip.
  ///
  /// In vi, this message translates to:
  /// **'Dưới 3 phút'**
  String get lbTimeShort;

  /// 4c chip.
  ///
  /// In vi, this message translates to:
  /// **'3–6 phút'**
  String get lbTimeMedium;

  /// 4c chip.
  ///
  /// In vi, this message translates to:
  /// **'Trên 6 phút'**
  String get lbTimeLong;

  /// 4c secondary.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get lbReset;

  /// 4c primary (live count).
  ///
  /// In vi, this message translates to:
  /// **'Xem {count} bài'**
  String lbShowN(int count);

  /// 4d bar; row bookmark (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get lbSave;

  /// Bookmark when saved (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lưu'**
  String get lbUnsave;

  /// 4e toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu · xem trong Thư viện › Đã lưu'**
  String get lbSavedToast;

  /// 4e toast action → 4f.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get lbView;

  /// Toast after unsaving.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ lưu'**
  String get lbUnsavedToast;

  /// Unsave toast action.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get lbUndo;

  /// Save error toast.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại nhé.'**
  String get lbSaveFailed;

  /// 4d "Aa" (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Cỡ chữ'**
  String get lbTextSize;

  /// 4d / 2b section.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết liên quan'**
  String get lbRelated;

  /// 4d section, 2b footnote.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tham khảo'**
  String get lbSources;

  /// 4d "Khi nào nên hỏi bác sĩ" callout link (the guide works offline).
  ///
  /// In vi, this message translates to:
  /// **'Dấu hiệu nguy hiểm? Mở Sơ cứu trẻ em'**
  String get lbOpenFirstAid;

  /// 4d footnote.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Mỗi bé phát triển theo nhịp riêng.'**
  String get lbArticleFootnote;

  /// Unknown or withdrawn article.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết này không còn trong thư viện'**
  String get lbArticleMissing;

  /// Unknown or withdrawn article.
  ///
  /// In vi, this message translates to:
  /// **'Bài có thể đã được gỡ để cập nhật. Mở lại Thư viện chăm bé.'**
  String get lbArticleMissingBody;

  /// 4f row meta.
  ///
  /// In vi, this message translates to:
  /// **'{topic} · lưu hôm nay'**
  String lbSavedToday(String topic);

  /// 4f row meta.
  ///
  /// In vi, this message translates to:
  /// **'{topic} · lưu {date}'**
  String lbSavedOn(String topic, String date);

  /// 4f empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu bài nào'**
  String get lbSavedEmptyTitle;

  /// 4f empty.
  ///
  /// In vi, this message translates to:
  /// **'Bấm Lưu khi đọc một bài để giữ lại đây.'**
  String get lbSavedEmptyBody;

  /// 4f banner (no expert claim: it may still be illustrative).
  ///
  /// In vi, this message translates to:
  /// **'Bài “{title}” vừa được cập nhật. Mở để xem bản mới.'**
  String lbUpdated(String title);

  /// 2a title; Chăm sóc tile (D-076 #5, never "thẻ").
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn của bé'**
  String get lbStagesTitle;

  /// 2a intro (no review claim).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý ngắn cho từng giai đoạn. Mỗi bé phát triển theo nhịp riêng.'**
  String get lbStagesIntro;

  /// 2a current stage pill.
  ///
  /// In vi, this message translates to:
  /// **'Bé đang ở đây'**
  String get lbHere;

  /// 2b card.
  ///
  /// In vi, this message translates to:
  /// **'Bé đang thế nào'**
  String get lbDoing;

  /// 2b card.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ có thể thử'**
  String get lbTry;

  /// 2b section (when Mốc phát triển is available).
  ///
  /// In vi, this message translates to:
  /// **'Mốc thường gặp'**
  String get lbMilestones;

  /// 2b link to "Tuần này của {bé}" (D-072 #5).
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho tuần này trong Nhịp lớn lên'**
  String get lbWeekCardSub;

  /// 2b footnote.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi bé phát triển theo nhịp riêng.'**
  String get lbStageFootnote;

  /// Unknown or withdrawn stage.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn này không còn trong ứng dụng'**
  String get lbStageMissing;

  /// Unknown or withdrawn stage.
  ///
  /// In vi, this message translates to:
  /// **'Mở lại Giai đoạn của bé để xem các giai đoạn hiện có.'**
  String get lbStageMissingBody;

  /// 2a nothing published yet.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung theo giai đoạn đang được chuẩn bị'**
  String get lbStagesEmptyTitle;

  /// 2a nothing published yet.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho từng giai đoạn sẽ hiện ở đây ngay khi được xuất bản.'**
  String get lbStagesEmptyBody;

  /// 2c card.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày sinh của bé'**
  String get lbNoDobTitle;

  /// 2c card.
  ///
  /// In vi, this message translates to:
  /// **'Để Child Life gợi ý đúng theo tuổi, nhắc Wonder Week và mốc phát triển.'**
  String get lbNoDobBody;

  /// 2c tinted button → Sửa hồ sơ bé.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày sinh'**
  String get lbNoDobAction;

  /// 2c for a member who may not see the date of birth.
  ///
  /// In vi, this message translates to:
  /// **'Chưa biết bé đang ở giai đoạn nào'**
  String get lbNoDobViewerTitle;

  /// 2c for caregivers / relatives without "Thông tin bé".
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa được xem ngày sinh của {name}, nên app chưa đánh dấu giai đoạn hiện tại. Bạn vẫn đọc được mọi giai đoạn.'**
  String lbNoDobViewer(String name);

  /// Lumi first-run tooltip eyebrow (669:64442).
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get asLumiIntroEyebrow;

  /// Lumi first-run tooltip title (669:64442).
  ///
  /// In vi, this message translates to:
  /// **'Gặp Lumi, trợ lý của nhà bạn'**
  String get asLumiIntroTitle;

  /// Lumi first-run tooltip body (669:64442) with photo reading and Chi tiêu. VI drafted from the EN frame for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để ghi cữ bú bằng một dòng, hỏi về ghi nhận của bé hoặc gửi ảnh hoá đơn. Lumi soạn nháp, bạn xem lại rồi lưu.'**
  String get asLumiIntroBody;

  /// Lumi first-run tooltip body without photo reading or Chi tiêu (never promises a receipt photo). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để ghi cữ bú bằng một dòng hoặc hỏi về ghi nhận của bé. Lumi soạn nháp, bạn xem lại rồi lưu.'**
  String get asLumiIntroBodyText;

  /// Lumi first-run tooltip body for a member who may only read (never promises logging). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để hỏi Lumi về ghi nhận của bé.'**
  String get asLumiIntroBodyViewer;

  /// Lumi first-run tooltip: dismiss for good (669:64442).
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get asLumiIntroLater;

  /// Lumi first-run tooltip: open the chat (669:64442).
  ///
  /// In vi, this message translates to:
  /// **'Thử ngay'**
  String get asLumiIntroTry;

  /// Chat top-bar icon button (tooltip and screen-reader label) that opens CH19; replaces the "Chi tiết" link (612:7741). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mức dùng'**
  String get asUsageButton;

  /// Plan waiting state of an evening (or any-time) item, with a check, instead of "Kể lại kết quả" right away (D-076 #10). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch · tối nay'**
  String get rhPlannedTonight;

  /// Plan waiting state of a daytime item (D-076 #10). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch · hôm nay'**
  String get rhPlannedToday;

  /// Status pill of a plan from an earlier day ("tối 08/10"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch · {date}'**
  String rhPlannedOn(String date);

  /// An evening of a day ("tối 08/10"), as AC02 590:6558 "Đã thử · tối 08/10".
  ///
  /// In vi, this message translates to:
  /// **'tối {date}'**
  String rhEveningDate(String date);

  /// Who planned and for when ("Ba lên kế hoạch · tối 08/10"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{who} lên kế hoạch · {when}'**
  String rhPlannedBy(String who, String when);

  /// Plan waiting note: the result is asked from 05:00 the next morning (CH17 rule). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sáng mai có thể kể lại kết quả.'**
  String get rhPlanAskMorning;

  /// Plan waiting note for a daytime item: the result is asked from 18:00 (CH17 rule). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Từ 18:00 hôm nay có thể kể lại kết quả.'**
  String get rhPlanAskEvening;

  /// H02 kicker once the chance to try has passed (never "đã thử": the family only said they would). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'CẢ NHÀ ĐÃ CÓ DỊP THỬ CHƯA?'**
  String get rhKickerFollowUp;

  /// Secondary action of the plan waiting state: takes back my own plan (deletes my `started` row). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ kế hoạch'**
  String get rhCancelPlan;

  /// Toast after "Bỏ kế hoạch". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ kế hoạch'**
  String get rhPlanCanceled;

  /// Answer next to "Kể lại kết quả" once the chance has passed, always available (CH17 "Chưa thử"). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thử'**
  String get rhDidNotTry;

  /// Toast after "Chưa thử". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không sao, lúc khác thử cũng được.'**
  String get rhDidNotTryToast;

  /// Activity history title: plans and answers of the family (C01 / AC02). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các cách đã thử'**
  String get rhTriedHistoryTitle;

  /// Activity history intro. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cả nhà đã lên kế hoạch hoặc trả lời trong {days} ngày qua, ai làm và thấy thế nào.'**
  String rhTriedHistoryBody(int days);

  /// Activity history without rows. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cách nào được lên kế hoạch hay thử.'**
  String get rhTriedHistoryEmpty;

  /// NL01 / EN09 link to the activity history. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get rhSeeAllTried;

  /// EN09 primary button (561:3102 "Tạo video tuần 4"): N is the week of life the title shows.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video tuần thứ {n}'**
  String rhWeekMakeVideo(int n);

  /// EN09 primary button when the week of life is unknown. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tạo video của tuần'**
  String get rhWeekMakeVideoPlain;

  /// EN09 caption under "Tạo video tuần N". VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh trong tuần được chọn sẵn'**
  String rhWeekVideoPhotos(int count);

  /// EN01–EN03 step bars, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Bước {step} trên {count}'**
  String hnStepOf(int step, int count);

  /// EN01 button with the number of interests picked (559:2288).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục · {count} mục'**
  String hnContinueCount(int count);

  /// EN03 title (559:2458).
  ///
  /// In vi, this message translates to:
  /// **'Để Child Life nhắc bạn đúng lúc'**
  String get hnNotifTitle;

  /// EN03 subtitle; the Figma "tối đa 2 gợi ý mỗi ngày" is not promised until a cap exists.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ những gì bạn vừa chọn và nhắc việc bạn tự đặt. Không quảng cáo.'**
  String get hnNotifBody;

  /// EN03 example card header.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể nhận những loại sau'**
  String get hnNotifExamples;

  /// EN03 example card tag.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ'**
  String get hnNotifExampleTag;

  /// EN03 example row title.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lịch tiêm'**
  String get hnNotifVaccine;

  /// EN03 example row timing.
  ///
  /// In vi, this message translates to:
  /// **'Trước lịch tiêm'**
  String get hnNotifVaccineWhen;

  /// EN03 example notification; no baby name (R-120).
  ///
  /// In vi, this message translates to:
  /// **'“Mai có lịch tiêm 6 trong 1 lúc 08:30.”'**
  String get hnNotifVaccineSample;

  /// EN03 example row title.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp lớn lên'**
  String get hnNotifRhythm;

  /// EN03 example row timing (NL02c stage reminder).
  ///
  /// In vi, this message translates to:
  /// **'Trước 3 ngày'**
  String get hnNotifRhythmWhen;

  /// EN03 example notification; no baby name (R-120).
  ///
  /// In vi, this message translates to:
  /// **'“Theo lịch tham khảo, con sắp đến giai đoạn 1.”'**
  String get hnNotifRhythmSample;

  /// EN03 example row title (EN09).
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần'**
  String get hnNotifWeek;

  /// EN03 example row timing.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật 20:30'**
  String get hnNotifWeekWhen;

  /// EN03 example notification; no baby name (R-120).
  ///
  /// In vi, this message translates to:
  /// **'“Một tuần của con đã sẵn sàng để xem lại.”'**
  String get hnNotifWeekSample;

  /// EN03 primary button; only this asks the system.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get hnNotifAllow;

  /// EN03 caption under the buttons.
  ///
  /// In vi, this message translates to:
  /// **'Tắt hoặc chỉnh lại trong Tôi › Thông báo'**
  String get hnNotifSettingsHint;

  /// Toast when the system prompt was refused.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo chưa bật. Bạn có thể bật trong Cài đặt của máy.'**
  String get hnNotifDenied;

  /// EN03 subtitle when it is shown on its own right after onboarding (nothing was picked in EN01). Engineering copy (D-077 #1).
  ///
  /// In vi, this message translates to:
  /// **'Lịch tiêm, nhắc việc bạn tự đặt và những ngày đáng nhớ của con. Không quảng cáo.'**
  String get hnNotifBodyAlone;

  /// EN03 example row on its own after onboarding: the milestone nudges (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'Ngày đáng nhớ'**
  String get hnNotifMilestone;

  /// When the milestone nudge comes (D-068 #9).
  ///
  /// In vi, this message translates to:
  /// **'09:00 đúng ngày'**
  String get hnNotifMilestoneWhen;

  /// Sample milestone nudge with the baby's nickname.
  ///
  /// In vi, this message translates to:
  /// **'“Hôm nay {name} tròn 1 tháng.”'**
  String hnNotifMilestoneSample(String name);

  /// Home invite card title (559:57870).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay theo cách của nhà bạn'**
  String get hnInviteTitle;

  /// Home invite card subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điều bạn quan tâm · 30 giây'**
  String get hnInviteBody;

  /// Home invite card button; opens EN01.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get hnInviteStart;

  /// Home invite close button, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn lời mời cá nhân hoá'**
  String get hnInviteClose;

  /// Toast after closing the Home invite.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn. Bạn vẫn chỉnh được trong Tôi › Cá nhân hoá.'**
  String get hnInviteHidden;

  /// Line under "Dành cho bé hôm nay" when the person picked interests.
  ///
  /// In vi, this message translates to:
  /// **'Theo điều bạn quan tâm'**
  String get hnForBabyBecause;

  /// Line under "Dành cho bé hôm nay" without interests.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn điều bạn quan tâm'**
  String get hnForBabyNoInterests;

  /// Link that opens EN01 (interests).
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get hnForBabyChange;

  /// Link that opens EN01 when nothing is picked yet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get hnForBabyPick;

  /// Pill on the Home Nhịp lớn lên card.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp lớn lên · Beta'**
  String get hnRhythmPill;

  /// Home Nhịp lớn lên card body.
  ///
  /// In vi, this message translates to:
  /// **'Theo lịch tham khảo, dự kiến {range}.'**
  String hnRhythmExpected(String range);

  /// Home Nhịp lớn lên card: days with a 'needs more soothing' check-in lately.
  ///
  /// In vi, this message translates to:
  /// **'Cả nhà ghi nhận con cần được dỗ nhiều hơn {days} ngày qua.'**
  String hnRhythmSoothing(int days);

  /// Suggestion carousel dots, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ {page} trên {count}'**
  String hnCardPage(int page, int count);

  /// Suggestion card × button, for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn cho thẻ này'**
  String get hnCardOptions;

  /// 3a title; Tiện ích row; Home card kicker.
  ///
  /// In vi, this message translates to:
  /// **'Mốc phát triển'**
  String get mtTitle;

  /// 3a summary card.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã có {count} mốc'**
  String mtSummary(String name, int count);

  /// 3a summary card with no record.
  ///
  /// In vi, this message translates to:
  /// **'{name} chưa có mốc nào'**
  String mtSummaryNone(String name);

  /// 3a summary card body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng.'**
  String get mtLead;

  /// 3a summary for caregivers and relatives (they never see the records).
  ///
  /// In vi, this message translates to:
  /// **'Các mốc tham khảo theo tuổi. Mỗi bé có nhịp riêng.'**
  String get mtLeadViewer;

  /// 3a filter chip.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get mtFilterAll;

  /// Milestone group (B07).
  ///
  /// In vi, this message translates to:
  /// **'Vận động'**
  String get mtGroupMotor;

  /// Milestone group (B07).
  ///
  /// In vi, this message translates to:
  /// **'Giao tiếp'**
  String get mtGroupCommunication;

  /// Milestone group (B07).
  ///
  /// In vi, this message translates to:
  /// **'Nhận thức'**
  String get mtGroupCognitive;

  /// Milestone group (B07).
  ///
  /// In vi, this message translates to:
  /// **'Cảm xúc – xã hội'**
  String get mtGroupSocial;

  /// Own milestones: 3a chip and row subline, 3g title.
  ///
  /// In vi, this message translates to:
  /// **'Mốc riêng'**
  String get mtOwn;

  /// 3a section; 3c sheet title; 3d chip.
  ///
  /// In vi, this message translates to:
  /// **'Đã quan sát'**
  String get mtSeen;

  /// 3a section of milestones saved to follow.
  ///
  /// In vi, this message translates to:
  /// **'Đang theo dõi'**
  String get mtFollowingSection;

  /// 3a section.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý quanh tuổi của bé'**
  String get mtAround;

  /// 3a section when the baby’s age is not known to this member.
  ///
  /// In vi, this message translates to:
  /// **'Mốc tham khảo'**
  String get mtReferenceSection;

  /// 3a section shown with "Xem tất cả".
  ///
  /// In vi, this message translates to:
  /// **'Các mốc khác'**
  String get mtOthers;

  /// 3a toggle.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả mốc ({count})'**
  String mtShowAll(int count);

  /// 3a toggle.
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn'**
  String get mtShowLess;

  /// Row subline age range.
  ///
  /// In vi, this message translates to:
  /// **'tham khảo {from}–{to} tháng'**
  String mtRangeMonths(int from, int to);

  /// Row subline age range.
  ///
  /// In vi, this message translates to:
  /// **'tham khảo {from}–{to} tuần'**
  String mtRangeWeeks(int from, int to);

  /// 3b age chip.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo {from}–{to} tháng'**
  String mtRangeChipMonths(int from, int to);

  /// 3b age chip.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo {from}–{to} tuần'**
  String mtRangeChipWeeks(int from, int to);

  /// 3a tag: the age window starts soon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get mtUpcoming;

  /// 3a tag: not recorded (never "late").
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi'**
  String get mtNotRecorded;

  /// 3a tag on a followed milestone.
  ///
  /// In vi, this message translates to:
  /// **'Đang theo dõi'**
  String get mtFollowingTag;

  /// 3a dashed button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mốc riêng'**
  String get mtCreateOwn;

  /// Small footer while the reference content has no qualified review (D-082 wording).
  ///
  /// In vi, this message translates to:
  /// **'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ'**
  String get mtIllustrative;

  /// Chip on a milestone photo or video kept on this phone until "Tạo kỷ niệm"; tapping opens it.
  ///
  /// In vi, this message translates to:
  /// **'Chưa vào Kỷ niệm'**
  String get mtNotInMemoriesTile;

  /// Footer once reviewed.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung được {reviewer} rà soát'**
  String mtReviewed(String reviewer);

  /// 3a when nothing is published.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mốc tham khảo'**
  String get mtEmptyTitle;

  /// 3a when nothing is published (parents).
  ///
  /// In vi, this message translates to:
  /// **'Nội dung đang được chuẩn bị. Bạn vẫn có thể tạo mốc riêng của bé.'**
  String get mtEmptyBody;

  /// 3a when nothing is published (others).
  ///
  /// In vi, this message translates to:
  /// **'Nội dung đang được chuẩn bị.'**
  String get mtEmptyBodyViewer;

  /// 3a for a parent when the date of birth is missing.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngày sinh của bé để xem gợi ý theo tuổi.'**
  String get mtNoDob;

  /// Tiện ích row subline.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại những điều bé làm được'**
  String get mtEntrySub;

  /// Tiện ích row subline with records.
  ///
  /// In vi, this message translates to:
  /// **'{count} mốc đã ghi'**
  String mtEntryCount(int count);

  /// 3b card title.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhận biết'**
  String get mtHowTo;

  /// 3b reassurance banner.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng tuổi chỉ để tham khảo. Mỗi bé có nhịp riêng — nếu bạn băn khoăn, hãy hỏi bác sĩ của bé.'**
  String get mtReassure;

  /// 3b callout title (from the portal text).
  ///
  /// In vi, this message translates to:
  /// **'Khi nào nên hỏi bác sĩ'**
  String get mtTalkToDoctor;

  /// 3b link to the health guidance (HL01).
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn sức khoẻ'**
  String get mtHealthLink;

  /// 3b primary button.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã quan sát'**
  String get mtMarkSeen;

  /// 3b plain button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu để theo dõi'**
  String get mtFollow;

  /// 3b plain button on a followed milestone.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ theo dõi'**
  String get mtUnfollow;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu để theo dõi'**
  String get mtFollowed;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ theo dõi'**
  String get mtUnfollowed;

  /// 3b sources heading.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tham khảo'**
  String get mtSources;

  /// 3b / 3a note for caregivers and relatives.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ của bé ghi lại các mốc trong mục này.'**
  String get mtParentsRecord;

  /// Unknown id.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy mốc này.'**
  String get mtNotFound;

  /// 3c date field.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bé làm được'**
  String get mtDateDid;

  /// 3c / 3g note field.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get mtNote;

  /// Note placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Bé làm được lúc nào, ở đâu, với ai…'**
  String get mtNoteHint;

  /// 3c label.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, video (không bắt buộc)'**
  String get mtPhotosOptional;

  /// Camera slot a11y.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh, video'**
  String get mtAddPhotos;

  /// Thumbnail a11y.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ mục này'**
  String get mtRemovePhoto;

  /// 3c / 3g primary button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mốc'**
  String get mtSave;

  /// Date sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get mtPickDate;

  /// Toast after saving.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu mốc'**
  String get mtSaved;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại nhé.'**
  String get mtSaveFailed;

  /// 3d meta line.
  ///
  /// In vi, this message translates to:
  /// **'{date} · lúc {name} {age} · {who} ghi'**
  String mtMeta(String date, String name, String age, String who);

  /// 3d meta line without the age.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {who} ghi'**
  String mtMetaNoAge(String date, String who);

  /// 3d card.
  ///
  /// In vi, this message translates to:
  /// **'Giữ khoảnh khắc này trong Kỷ niệm?'**
  String get mtKeepTitle;

  /// 3d card body.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kỷ niệm với ảnh và ghi chú này, gắn mốc “{name}”.'**
  String mtKeepBody(String name);

  /// 3d card body without photos.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kỷ niệm gắn mốc “{name}” — thêm ảnh nếu bạn muốn.'**
  String mtKeepBodyNote(String name);

  /// 3d button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kỷ niệm'**
  String get mtCreateMemory;

  /// 3d / 3f link to Thiệp cột mốc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thẻ mốc'**
  String get mtCreateCard;

  /// 3f row title.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trong Kỷ niệm'**
  String get mtInMemories;

  /// 3f row subline.
  ///
  /// In vi, this message translates to:
  /// **'Cả gia đình xem được · {count} ảnh'**
  String mtSeenByFamily(int count);

  /// 3f row subline.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ xem được · {count} ảnh'**
  String mtSeenByParents(int count);

  /// 3f row subline (no photo).
  ///
  /// In vi, this message translates to:
  /// **'Cả gia đình xem được · ghi chú'**
  String get mtSeenByFamilyNote;

  /// 3f row subline (no photo).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ba mẹ xem được · ghi chú'**
  String get mtSeenByParentsNote;

  /// 3f row while the memory is on its way.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lên Kỷ niệm…'**
  String get mtUploading;

  /// 3d overflow a11y.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thao tác'**
  String get mtMore;

  /// 3d action.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ghi nhận'**
  String get mtEdit;

  /// 3d action.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ghi nhận'**
  String get mtDelete;

  /// Confirm sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ghi nhận mốc này?'**
  String get mtDeleteTitle;

  /// Confirm sheet body.
  ///
  /// In vi, this message translates to:
  /// **'Ngày và ghi chú sẽ bị xoá. Kỷ niệm đã tạo vẫn ở trong Kỷ niệm.'**
  String get mtDeleteBody;

  /// Toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá ghi nhận'**
  String get mtDeleted;

  /// 3e sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm mới'**
  String get mtNewMemory;

  /// 3e field.
  ///
  /// In vi, this message translates to:
  /// **'Chú thích'**
  String get mtCaption;

  /// 3e placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Vài dòng về khoảnh khắc này'**
  String get mtCaptionHint;

  /// 3e milestone chip.
  ///
  /// In vi, this message translates to:
  /// **'Mốc · {name}'**
  String mtTag(String name);

  /// 3e label.
  ///
  /// In vi, this message translates to:
  /// **'Ai được xem'**
  String get mtWhoSees;

  /// 3e button.
  ///
  /// In vi, this message translates to:
  /// **'Lưu kỷ niệm'**
  String get mtSaveMemory;

  /// 3f toast.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo kỷ niệm'**
  String get mtMemoryCreated;

  /// 3e validation.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chú thích hoặc ảnh để lưu kỷ niệm.'**
  String get mtCaptionRequired;

  /// 3g lead.
  ///
  /// In vi, this message translates to:
  /// **'Những lần đầu tiên chỉ nhà mình có — ghi lại theo cách của bạn.'**
  String get mtOwnLead;

  /// 3g field.
  ///
  /// In vi, this message translates to:
  /// **'Tên mốc'**
  String get mtName;

  /// 3g placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Lần đầu về quê'**
  String get mtNameHint;

  /// 3g counter.
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max} ký tự'**
  String mtCount(int count, int max);

  /// 3g date field.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get mtDate;

  /// 3g toggle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kỷ niệm cùng lúc'**
  String get mtAlsoMemory;

  /// 3g toggle subline.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh và ghi chú vào Kỷ niệm'**
  String get mtAlsoMemorySub;

  /// 3g in edit mode.
  ///
  /// In vi, this message translates to:
  /// **'Sửa mốc'**
  String get mtEditTitle;

  /// Today card kicker for the current stage.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn của bé · {range}'**
  String lbTodayStageKicker(String range);

  /// Today card action → 2b.
  ///
  /// In vi, this message translates to:
  /// **'Xem giai đoạn'**
  String get lbTodayStageAction;

  /// Today article card action → 4d.
  ///
  /// In vi, this message translates to:
  /// **'Đọc bài'**
  String get lbTodayRead;

  /// Bell button in the Hôm nay header (a11y label, 559:57622).
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get ntBell;

  /// Bell a11y label with unread notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo, {count} chưa đọc'**
  String ntBellUnread(int count);

  /// EN06 large title.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get ntInboxTitle;

  /// EN06 top-right link.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc'**
  String get ntMarkAllRead;

  /// EN06 top bar: opens EN07 (a11y label of the sliders button).
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt thông báo'**
  String get ntOpenSettings;

  /// EN06 chip.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get ntFilterAll;

  /// EN06 chip.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc'**
  String get ntFilterReminders;

  /// EN06 chip.
  ///
  /// In vi, this message translates to:
  /// **'Cho bé'**
  String get ntFilterBaby;

  /// EN06 chip.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get ntFilterFamily;

  /// EN06 section header.
  ///
  /// In vi, this message translates to:
  /// **'HÔM NAY'**
  String get ntSectionToday;

  /// EN06 section header: the last 7 days.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN NÀY'**
  String get ntSectionWeek;

  /// EN06 section header: older than 7 days (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'TRƯỚC ĐÓ'**
  String get ntSectionEarlier;

  /// EN06 unread dot (a11y).
  ///
  /// In vi, this message translates to:
  /// **'Chưa đọc'**
  String get ntUnread;

  /// EN06 empty state title (not drawn).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào'**
  String get ntEmptyTitle;

  /// EN06 empty state body.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc, lịch tiêm và tin của gia đình sẽ hiện ở đây.'**
  String get ntEmptyBody;

  /// EN06 empty state for a chip.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào trong mục này.'**
  String get ntEmptyFiltered;

  /// EN06 load error.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được thông báo. Thử lại sau nhé.'**
  String get ntLoadFailed;

  /// EN06 footnote.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo được giữ 90 ngày. Vuốt sang trái để ẩn.'**
  String get ntKept;

  /// EN06 swipe action: archive one row.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn'**
  String get ntHide;

  /// Toast: the notification points to a baby you no longer follow.
  ///
  /// In vi, this message translates to:
  /// **'Mục này không còn mở được.'**
  String get ntGone;

  /// EN07 master card title.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo của Child Life'**
  String get ntMaster;

  /// EN07 master card: OS permission granted.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật trong cài đặt hệ thống'**
  String get ntMasterOn;

  /// EN07 master card: OS permission not granted.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt trong cài đặt hệ thống'**
  String get ntMasterOff;

  /// EN07 group header.
  ///
  /// In vi, this message translates to:
  /// **'NHẮC VIỆC BẠN ĐẶT'**
  String get ntGroupReminders;

  /// EN07 group helper (reminders ring in quiet hours).
  ///
  /// In vi, this message translates to:
  /// **'Luôn đến đúng giờ, kể cả trong giờ yên lặng'**
  String get ntGroupRemindersHint;

  /// EN07 row: rule and one-off reminders.
  ///
  /// In vi, this message translates to:
  /// **'Bú, ngủ, thay tã'**
  String get ntCare;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc theo quy tắc và nhắc một lần'**
  String get ntCareHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Tiêm chủng'**
  String get ntVaccines;

  /// EN07 row helper: when vaccine reminders ring (P-133).
  ///
  /// In vi, this message translates to:
  /// **'Trước 3 ngày và tối hôm trước lúc 19:00'**
  String get ntVaccinesHint;

  /// EN07 row (engineering addition: Chi tiêu pushes).
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get ntSpending;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Khoản định kỳ, 80% ngân sách, kết quả nhập'**
  String get ntSpendingHint;

  /// EN07 group header.
  ///
  /// In vi, this message translates to:
  /// **'GỢI Ý CHO BÉ'**
  String get ntGroupBaby;

  /// EN07 group helper.
  ///
  /// In vi, this message translates to:
  /// **'Gom lại, tối đa 2 thông báo mỗi ngày'**
  String get ntGroupBabyHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp lớn lên'**
  String get ntRhythm;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Trước mỗi giai đoạn 3 ngày · check-in tối đa 1/ngày'**
  String get ntRhythmHint;

  /// EN07 row ("Thẻ theo tuổi", renamed by D-076 #5).
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn của bé'**
  String get ntStages;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Khi bé sang tuần / tháng mới'**
  String get ntStagesHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Mốc phát triển'**
  String get ntMilestones;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Khi đến khoảng tuổi thường gặp'**
  String get ntMilestonesHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết gợi ý'**
  String get ntArticles;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 1 bài mỗi tuần'**
  String get ntArticlesHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần'**
  String get ntWeekly;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật 20:30'**
  String get ntWeeklyHint;

  /// EN07 group header.
  ///
  /// In vi, this message translates to:
  /// **'KỶ NIỆM & GIA ĐÌNH'**
  String get ntGroupFamily;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mới có thể có bé'**
  String get ntPhotos;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Tự lưu kỷ niệm · tối đa 1 lần/ngày'**
  String get ntPhotosHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý tạo video, thiệp'**
  String get ntKeepsakes;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Vào ngày tròn tháng, 100 ngày'**
  String get ntKeepsakesHint;

  /// EN07 row.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động của gia đình'**
  String get ntFamilyActivity;

  /// EN07 row helper.
  ///
  /// In vi, this message translates to:
  /// **'Thích, xem kỷ niệm'**
  String get ntFamilyActivityHint;

  /// EN07 group header.
  ///
  /// In vi, this message translates to:
  /// **'THỜI GIAN'**
  String get ntGroupTiming;

  /// EN07 row: opens EN02.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhận gợi ý'**
  String get ntDigest;

  /// EN07 row value.
  ///
  /// In vi, this message translates to:
  /// **'{time} mỗi ngày'**
  String ntDigestDaily(String time);

  /// EN07 row: opens EN02.
  ///
  /// In vi, this message translates to:
  /// **'Giờ yên lặng'**
  String get ntQuiet;

  /// EN07 quiet hours value.
  ///
  /// In vi, this message translates to:
  /// **'{from} – {to}'**
  String ntQuietRange(String from, String to);

  /// EN07 toast when a switch fails to save.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại nhé.'**
  String get ntSaveFailed;

  /// Pill of a plan still waiting for its chance (NL01, EN09, activity history). VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch'**
  String get rhPlannedPill;

  /// Home small card kicker ({range} = "tham khảo 1–3 tháng").
  ///
  /// In vi, this message translates to:
  /// **'Mốc có thể thấy · {range}'**
  String mtTodayKicker(String range);

  /// Home small card action (Cùng nuôi).
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận khi bé làm được'**
  String get mtTodayAction;

  /// Home small card action (others).
  ///
  /// In vi, this message translates to:
  /// **'Xem cách nhận biết'**
  String get mtTodayActionViewer;

  /// Tiện ích row subline for caregivers and relatives (they read the guide only).
  ///
  /// In vi, this message translates to:
  /// **'Mốc tham khảo theo tuổi của bé'**
  String get mtEntrySubViewer;

  /// Small link on the Home suggestion card; opens the explanation sheet.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao gợi ý này?'**
  String get hnWhyLink;

  /// Title of the explanation sheet of the Home suggestion.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao gợi ý này'**
  String get hnWhyTitle;

  /// One-line reason on the Home suggestion when feedback changed the ranking (PS02); the details are in the sheet.
  ///
  /// In vi, this message translates to:
  /// **'Đã điều chỉnh theo phản hồi của nhà mình.'**
  String get hnWhyFeedbackShort;

  /// Footnote of the explanation sheet of the Home suggestion.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý dựa trên điều nhà mình ghi nhận, tuổi của bé và điều bạn quan tâm. Đây không phải chẩn đoán.'**
  String get hnWhyHow;

  /// Small heading above the Home carousel (milestones, reads, stage).
  ///
  /// In vi, this message translates to:
  /// **'Để ý tuần này'**
  String get hnWatchThisWeek;

  /// Home "Tuần này" card: the week of life (completed weeks + 1) and the age ("4 tuần tuổi").
  ///
  /// In vi, this message translates to:
  /// **'Tuần thứ {n} · {age}'**
  String hnWeekKicker(int n, String age);

  /// Home "Tuần này" card when the age is not readable (caregivers): the week of life of the content.
  ///
  /// In vi, this message translates to:
  /// **'Tuần thứ {n}'**
  String hnWeekKickerOnly(int n);

  /// Home "Tuần này" card from 3 months: the month of life (completed months + 1) and the age.
  ///
  /// In vi, this message translates to:
  /// **'Tháng thứ {n} · {age}'**
  String hnMonthKicker(int n, String age);

  /// Home "Tuần này" card from 3 months when the age is not readable (caregivers).
  ///
  /// In vi, this message translates to:
  /// **'Tháng thứ {n}'**
  String hnMonthKickerOnly(int n);

  /// Action of the Home "Tuần này" card.
  ///
  /// In vi, this message translates to:
  /// **'Xem tuần này'**
  String get hnWeekOpen;

  /// Action of the Home "Tuần này" card with the number of tips the content holds.
  ///
  /// In vi, this message translates to:
  /// **'Xem {count} gợi ý cho tuần này'**
  String hnWeekOpenIdeas(int count);

  /// Home "Tuần này" card, Nhịp lớn lên row: the reference window.
  ///
  /// In vi, this message translates to:
  /// **'Wonder Weeks · dự kiến {range}'**
  String hnWeekRhythmSub(String range);

  /// Home "Tuần này" card row opening EN09 (Monday to Saturday: the last completed week).
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần trước'**
  String get hnWeekSummaryLast;

  /// Home "Tuần này" card row opening EN09 on Sunday (the week ending today).
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tuần này'**
  String get hnWeekSummaryThis;

  /// Home "Tuần này" card, Nhịp lớn lên row: the next reference stage and the days until its window.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày đến giai đoạn {n}'**
  String hnRhythmComingDays(int n, int days);

  /// Home "Tuần này" card, Nhịp lớn lên row: today is inside the reference window.
  ///
  /// In vi, this message translates to:
  /// **'Đang trong giai đoạn {n}'**
  String hnRhythmNow(int n);

  /// The assistant's name in the chat header, above her messages and in screen-reader labels. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lumi'**
  String get asLumiName;

  /// Screen-reader speaker of my own bubble ("Bạn: …"). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get asYou;

  /// Privacy hint on private chats and expense drafts (spending never enters the shared thread, D-075 #2). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn thấy'**
  String get asOnlyYou;

  /// Privacy line on an expense draft and its editor (D-075 #2). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn thấy · chi tiêu không vào cuộc trò chuyện chung của bé'**
  String get asOnlyYouSpending;

  /// Screen-reader hint of a long press on a bubble. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get asCopy;

  /// Toast after a long press copied a message. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get asCopied;

  /// Screen-reader hint of a tap on a bubble (shows its time). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem giờ gửi'**
  String get asShowTime;

  /// Pill shown when Lumi answers while the person reads further up; scrolls down. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tin mới'**
  String get asNewMessages;

  /// Banner under the chat header while offline (CH25). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến. Tin nhắn được giữ lại và chỉ gửi khi bạn bấm Gửi. Ghi trực tiếp vẫn dùng được.'**
  String get asOfflineBanner;

  /// Under my bubble when sending failed (nothing charged). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được'**
  String get asNotSent;

  /// Under my bubble kept while offline (never sent by itself). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi · đang ngoại tuyến'**
  String get asUnsentOffline;

  /// Inline action under a bubble that could not be sent. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get asResend;

  /// CH25 as a Lumi bubble (no blame), followed by "Thử lại" and "Ghi trực tiếp". Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mình chưa trả lời được lúc này. Chưa có gì được lưu — bạn thử lại nhé, hoặc ghi trực tiếp.'**
  String get asErrorFriendly;

  /// Typing indicator of a photo task. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lumi đang đọc ảnh…'**
  String get asReadingPhoto;

  /// Suggestion above the composer (prefills only). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi giấc ngủ'**
  String get asChipLogSleep;

  /// Text the "Ghi giấc ngủ" suggestion prefills (never sent by itself). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Con ngủ từ '**
  String get asPrefillSleep;

  /// Suggestion above the composer in the family chat (prefills only). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản chi'**
  String get asChipExpense;

  /// Text the "Ghi khoản chi" suggestion prefills (never sent by itself). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mua '**
  String get asPrefillExpense;

  /// Day of a time in the editors and the span line. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get asWhenToday;

  /// Day of a time in the editors and the span line ("21:00 hôm qua"). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get asWhenYesterday;

  /// Reminder day chip. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get asWhenTomorrow;

  /// A time with its day inside the span line ("21:00 hôm qua"). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{time} {day}'**
  String asTimeOnDay(String time, String day);

  /// Chat: the line above a task when the thread starts, a day changes or after a pause ("Hôm nay · 14:20"). Chat UI rework 2026-10-17. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {time}'**
  String asThreadWhen(String day, String time);

  /// Chat: scrolling up could not load the earlier messages (with "Thử lại"). Chat UI rework 2026-10-17. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được tin nhắn cũ hơn.'**
  String get asOlderFailed;

  /// A sleep with linked times ("21:00 – 06:00 · 9 giờ", the en dash of the draft cards). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end} · {duration}'**
  String asSpanLine(String start, String end, String duration);

  /// Span line when the end is not after the start. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'giờ dậy trước giờ ngủ'**
  String get asSpanInvalid;

  /// Note under the preview of a time question when a duration is known. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo thời lượng bạn nói: {duration}'**
  String asSpanKnown(String duration);

  /// Time picker title for "Khác…" when the length is known (start asked). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé ngủ lúc mấy giờ?'**
  String get asPickSleepTitle;

  /// Time picker title for "Khác…" when the length is known (end asked). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé dậy lúc mấy giờ?'**
  String get asPickWakeTitle;

  /// Button of the clarification time picker (the time goes as the answer, 0 credits). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời: {time}'**
  String asAnswerWith(String time);

  /// Sleep editor start tile. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ lúc'**
  String get asFieldSleepStart;

  /// Sleep editor end tile. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dậy lúc'**
  String get asFieldSleepEnd;

  /// Sleep editor length stepper (moves the end). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get asFieldDuration;

  /// Sleep length stepper minus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngắn hơn 15 phút'**
  String get asShorter;

  /// Sleep length stepper plus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dài hơn 15 phút'**
  String get asLonger;

  /// Bottle amount stepper minus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bớt 10 ml'**
  String get asLessMl;

  /// Bottle amount stepper plus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm 10 ml'**
  String get asMoreMl;

  /// Nursing minutes stepper minus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bớt 5 phút'**
  String get asLessMinutes;

  /// Nursing minutes stepper plus (a11y). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm 5 phút'**
  String get asMoreMinutes;

  /// Editor footnote: the draft stays with the chat's baby. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi cho {name} · không đổi sang bé khác được'**
  String asBabyLockedLine(String name);

  /// Date chip that opens the date picker. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày khác'**
  String get asPickOtherDay;

  /// Mic button of the composer (a11y), shown while the field is empty. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nói với Lumi'**
  String get asVoiceStart;

  /// Stop button while dictating (a11y); the words stay in the field. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dừng nghe'**
  String get asVoiceStop;

  /// Cancel button while dictating (a11y); the field goes back as it was. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lời vừa nói'**
  String get asVoiceCancel;

  /// Composer while dictating. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang nghe…'**
  String get asVoiceListening;

  /// Composer while dictating, before the first words. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang nghe… vuốt sang trái để huỷ'**
  String get asVoiceSwipe;

  /// First-run voice explainer title (before the system permission prompts). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nói với Lumi thay vì gõ'**
  String get asVoiceIntroTitle;

  /// Voice explainer: dictation only fills the field. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chạm mic rồi nói. Chữ hiện ngay trong ô nhập; bạn sửa được và chỉ gửi khi bấm Gửi.'**
  String get asVoiceIntroWords;

  /// Voice explainer on iOS: who turns speech into words, said plainly. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'iPhone chuyển giọng nói thành chữ ngay trên máy khi có thể. Khi máy chưa làm được (ví dụ chưa có tiếng Việt ngoại tuyến), dịch vụ nhận dạng của Apple có thể xử lý âm thanh trên máy chủ của Apple.'**
  String get asVoiceIntroServerIos;

  /// Voice explainer on Android: who turns speech into words, said plainly. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại chuyển giọng nói thành chữ ngay trên máy khi có thể. Khi chưa làm được, dịch vụ nhận dạng giọng nói của máy (thường của Google) có thể xử lý âm thanh trên máy chủ của họ.'**
  String get asVoiceIntroServerAndroid;

  /// Voice explainer: nothing kept. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Child Life không ghi âm, không lưu và không gửi âm thanh. Chỉ phần chữ bạn bấm Gửi mới tới Lumi.'**
  String get asVoiceIntroNothingKept;

  /// Voice explainer: dictation is free. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nói thay vì gõ không tốn lượt AI.'**
  String get asVoiceIntroFree;

  /// Voice explainer: continue to the system permission prompts. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bật micro'**
  String get asVoiceIntroAllow;

  /// Voice explainer: close without asking. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get asVoiceIntroLater;

  /// Toast when the permission is denied (with "Mở Cài đặt"). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền dùng micro hoặc nhận dạng giọng nói. Bật trong Cài đặt để nói với Lumi.'**
  String get asVoiceDenied;

  /// Toast when no speech service is available (the mic then hides). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Máy này chưa nhận dạng giọng nói được. Bạn gõ chữ nhé.'**
  String get asVoiceUnavailable;

  /// Toast when the phone has no recogniser for the app language (the mic then hides). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Máy chưa nhận dạng được giọng nói tiếng Việt. Thêm ngôn ngữ trong Cài đặt của máy, hoặc gõ chữ nhé.'**
  String get asVoiceLanguage;

  /// Toast when a dictation ended without words. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mình chưa nghe thấy gì. Thử nói gần máy hơn nhé.'**
  String get asVoiceNoSpeech;

  /// Toast when the recogniser failed mid-way. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhận dạng giọng nói bị gián đoạn. Phần chữ đã có vẫn ở trong ô nhập.'**
  String get asVoiceFailed;

  /// Suggestion above the composer; prefills "Hôm nay con bú thế nào?". Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cữ bú hôm nay'**
  String get asChipFeedsShort;

  /// Link of a PREVIOUS_SAVED notice: the saved record opens in its module. Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa trong nhật ký'**
  String get asEditInModule;

  /// Footnote on a task moved out of the shared thread because it mentions money (task.routing spending). Chat rework 2026-10-15. VI and EN are engineering drafts (no frame draws this state) for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn thấy: tin nhắn có chi tiêu được giữ trong cuộc trò chuyện riêng của bạn.'**
  String get asSpendingMoved;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cữ bú bình'**
  String get asSaveBottle;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cữ bú'**
  String get asSaveBreast;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giấc ngủ'**
  String get asSaveSleep;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu nhắc việc'**
  String get asSaveReminder;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get asSaveItem;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu {count} mục'**
  String asSaveItems(int count);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} mục cần bổ sung ở trên'**
  String asStillToFill(int count);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get asKindTimer;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tính giờ ngủ'**
  String get asTimerTitleStartSleep;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tính giờ bú mẹ'**
  String get asTimerTitleStartBreast;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc giấc ngủ'**
  String get asTimerTitleStopSleep;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc cữ bú'**
  String get asTimerTitleStopBreast;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu tính giờ ngủ · {time}'**
  String asTimerStartSleep(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu tính giờ bú · {side} · {time}'**
  String asTimerStartBreast(String side, String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc giấc ngủ · {time}'**
  String asTimerStopSleep(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc cữ bú · {time}'**
  String asTimerStopBreast(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Để tiếp tục'**
  String get asTimerKeep;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Từ {time}'**
  String asTimerFrom(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bên {side} trước'**
  String asTimerSideFirst(String side);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngủ · {elapsed}'**
  String asTimerSleeping(String elapsed);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang bú · {elapsed}'**
  String asTimerFeeding(String elapsed);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở đồng hồ'**
  String get asTimerOpen;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ đã kết thúc'**
  String get asTimerEnded;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đang tính giờ từ {time}'**
  String asTimerRunningSince(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ này đã được bắt đầu trên máy khác.'**
  String get asErrTimerRunning;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ đã kết thúc hoặc thay đổi trên máy khác.'**
  String get asErrTimerChanged;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ bé bú'**
  String get asGapFeedTime;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ bé bắt đầu ngủ'**
  String get asGapSleepStart;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ bé dậy'**
  String get asGapSleepEnd;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ {time} có đúng không?'**
  String asGapTimeUnsure(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{time} chưa tới. Chọn lại giờ nhé.'**
  String asGapTimeFuture(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ dậy phải sau giờ bắt đầu ngủ'**
  String get asGapSleepOrder;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượng sữa (ml)'**
  String get asGapAmount;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng {ml} ml có đúng không?'**
  String asGapAmountUnsure(String ml);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa cần từ 1 đến 500 ml'**
  String get asGapAmountRange;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ sữa mẹ hay sữa công thức'**
  String get asGapMilk;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ bé bú bên nào'**
  String get asGapSide;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng {duration} có đúng không?'**
  String asGapDurationUnsure(String duration);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cữ bú không dài quá 180 phút'**
  String get asGapDurationRange;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ban ngày hay ban đêm? (không bắt buộc)'**
  String get asGapWhen;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date} có đúng không?'**
  String asGapDateUnsure(String date);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngày nhắc'**
  String get asGapReminderDate;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thời điểm nhắc đã qua. Chọn ngày khác nhé.'**
  String get asGapReminderPast;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tên việc dài quá (tối đa 80 ký tự)'**
  String get asGapTitle;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Người được giao không còn trong nhà'**
  String get asGapAssignee;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ không tính từ lâu vậy được. Chọn giờ gần hơn.'**
  String get asGapTimerOld;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ kết thúc phải sau {time}'**
  String asGapTimerEnd(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có số tiền'**
  String get asGapExpenseAmount;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền có đúng không?'**
  String get asGapExpenseAmountUnsure;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ đơn vị tiền'**
  String get asGapExpenseCurrency;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục có đúng không?'**
  String get asGapExpenseCategory;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tên cửa hàng có đúng không?'**
  String get asGapExpenseMerchant;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đúng rồi'**
  String get asFixRight;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong ({time})'**
  String asFixJustNow(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'30 phút trước ({time})'**
  String asFixAgo30(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'1 tiếng trước ({time})'**
  String asFixAgo60(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vừa dậy ({time})'**
  String asFixWokeNow(String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ {hours} tiếng (từ {time})'**
  String asFixSlept(int hours, String time);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ'**
  String get asFixPickTime;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get asFixPickDate;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get asFixToday;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get asFixYesterday;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get asFixTomorrow;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{ml} ml'**
  String asFixMl(String ml);

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ban ngày'**
  String get asFixDayTime;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ban đêm'**
  String get asFixNightTime;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không giao'**
  String get asFixNoAssignee;

  /// Lumi 2026-10-16 (timers, inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã bổ sung, sẵn sàng lưu'**
  String get asFixed;

  /// Lumi 2026-10-16: under a review card's disabled save, why. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ở trên là lưu được ngay.'**
  String get asPickAboveToSave;

  /// Lumi 2026-10-16 (inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giấc ban ngày hay ban đêm?'**
  String get asGapWhenAsk;

  /// Lumi 2026-10-16 (inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú có đúng không?'**
  String get asGapNote;

  /// Lumi 2026-10-16 (inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ghi chú'**
  String get asFixDropNote;

  /// Lumi 2026-10-16 (inline review fixes). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Loại ghi nhận có đúng không?'**
  String get asGapObservation;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cân đo'**
  String get asKindGrowth;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đo {date}'**
  String asMeasuredOnLine(String date);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bên trái'**
  String get asPumpSideLeft;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bên phải'**
  String get asPumpSideRight;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cả hai bên'**
  String get asPumpSideBoth;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở mục'**
  String get asOpenModule;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay tã'**
  String get asSaveDiaper;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ hút sữa'**
  String get asGapPumpTime;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giờ thay tã'**
  String get asGapDiaperTime;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ ngủ {time} có đúng không?'**
  String asGapSleepStartUnsure(String time);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ dậy {time} có đúng không?'**
  String asGapSleepEndUnsure(String time);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai {time}'**
  String asFixTomorrowAt(String time);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượng sữa hút (ml)'**
  String get asGapPumpAmount;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa hút cần từ 1 đến 1000 ml'**
  String get asGapPumpAmountRange;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ hút bên nào'**
  String get asGapPumpSide;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hút bao lâu?'**
  String get asGapPumpDuration;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi lần hút không quá 240 phút'**
  String get asGapPumpDurationRange;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tã ướt, bẩn hay cả hai?'**
  String get asGapDiaper;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cân nặng (kg)'**
  String get asGapWeight;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng {kg} kg có đúng không?'**
  String asGapWeightUnsure(String kg);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhập cân nặng'**
  String get asFixEnterWeight;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chiều dài (cm)'**
  String get asGapLength;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài {cm} cm có đúng không?'**
  String asGapLengthUnsure(String cm);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhập chiều dài'**
  String get asFixEnterLength;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chiều dài'**
  String get asFixDropLength;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngày đo'**
  String get asGapMeasuredOn;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đo chưa tới. Chọn lại ngày nhé.'**
  String get asGapMeasuredOnFuture;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đo {date} có đúng không?'**
  String asGapMeasuredOnUnsure(String date);

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hút sữa'**
  String get asEditPump;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thay tã'**
  String get asEditDiaper;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa cân đo'**
  String get asEditGrowth;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get asFieldWeight;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài · tùy chọn'**
  String get asFieldLength;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đo'**
  String get asFieldMeasuredOn;

  /// Lumi fixes 2026-10-16 (LUMI-01 pump / diaper / growth from chat, LUMI-07, LUMI-09, LUMI-11, LUMI-13). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Loại tã'**
  String get asFieldDiaper;

  /// 28 head circumference label. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu · tùy chọn'**
  String get growthHeadOptional;

  /// Head circumference out of range. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu từ 20 đến 60 cm.'**
  String get growthHeadRange;

  /// Head circumference in a measurement line ("vòng đầu 39 cm"). Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'vòng đầu {v} cm'**
  String headCm(String v);

  /// 20d / 20i toggle. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu'**
  String get growthHeadTab;

  /// 21 record detail row. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu'**
  String get detailHead;

  /// 13 baby profile tile. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu · {when}'**
  String bpHead(String when);

  /// 20d note. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu của {name} đang nhỏ hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoBelowHeadNote(String name);

  /// 20d note. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu của {name} đang lớn hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.'**
  String whoAboveHeadNote(String name);

  /// Lumi growth editor field. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu · tùy chọn'**
  String get asFieldHead;

  /// Lumi inline fix: head circumference missing. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vòng đầu (cm)'**
  String get asGapHead;

  /// Lumi inline fix: head circumference to check. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vòng đầu {cm} cm có đúng không?'**
  String asGapHeadUnsure(String cm);

  /// Lumi inline fix chip: opens the editor. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhập vòng đầu'**
  String get asFixEnterHead;

  /// Lumi inline fix chip: keep the measurement without it. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ vòng đầu'**
  String get asFixDropHead;

  /// Lumi on a typed purchase without an amount, above the amount field. LUMI-16, owner decision 2026-10-16 (a purchase without an amount). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hết bao nhiêu tiền?'**
  String get asAskAmount;

  /// 20d: the selected measure (e.g. head circumference) has no value yet. Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có số đo này. Thêm khi đo cho bé lần tới.'**
  String get growthMeasureNone;

  /// 9a Chăm sóc tile title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dinh dưỡng'**
  String get careNutrition;

  /// 9a tile subline while it is a teaser (nothing published for the baby's age). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo từng giai đoạn tuổi'**
  String get careNutritionSub;

  /// 9a tile subline: the current stage, e.g. "Giai đoạn 6–8 tháng". D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {range}'**
  String careNutritionStage(String range);

  /// 9a tile subline without a date of birth. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cần ngày sinh của bé'**
  String get careNutritionNoDob;

  /// 9b title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dinh dưỡng'**
  String get nuTitle;

  /// A stage's age range in completed months, e.g. 6–8 tháng. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{from}–{to} tháng'**
  String nuMonthsRange(int from, int to);

  /// Tag on the current stage / by-age row. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get nuCurrent;

  /// Offline banner on 9b / 9f. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối. Dinh dưỡng đang hiện bản đã lưu trên máy.'**
  String get nuOffline;

  /// 9b / 9f when nothing is published for the baby's age. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung dinh dưỡng đang được chuẩn bị'**
  String get nuEmptyTitle;

  /// 9b / 9f empty state. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý theo giai đoạn tuổi sẽ hiện ở đây ngay khi được xuất bản.'**
  String get nuEmptyBody;

  /// 9b no-DOB card for a member who may not see the date of birth. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa biết bé đang ở giai đoạn nào'**
  String get nuNoDobViewerTitle;

  /// 9b no-DOB card (Cùng nuôi), above "Thêm ngày sinh". D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dinh dưỡng theo giai đoạn cần biết tuổi của {name}.'**
  String nuNoDobBody(String name);

  /// 9b no-DOB card for caregivers / relatives. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa được xem ngày sinh của {name}, nên app chưa biết bé đang ở giai đoạn nào.'**
  String nuNoDobViewer(String name);

  /// A stage or nutrient that was withdrawn. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này không còn'**
  String get nuStageMissing;

  /// Withdrawn item body. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có thể nội dung đã được cập nhật. Quay lại để xem bản mới nhất.'**
  String get nuStageMissingBody;

  /// 9b footer after the guidance / reviewer line. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không thay thế tư vấn của bác sĩ. Thuốc, vi chất dạng uống: theo chỉ định bác sĩ.'**
  String get nuFooter;

  /// 9b footer after the D-082 guidance footnote, which already says it is not a substitute for a doctor. D-083 Dinh dưỡng theo giai đoạn. EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc, vi chất dạng uống: theo chỉ định bác sĩ.'**
  String get nuFooterDose;

  /// Share sheet failed (9e report, 9g calendar file). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được bảng chia sẻ. Thử lại sau.'**
  String get nuShareFailed;

  /// 9b stage card label, e.g. "7 tháng · giai đoạn 6–8 tháng". D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{age} · giai đoạn {range}'**
  String nuStageAge(String age, String range);

  /// 9b stage card past the last stage (P-163 #9). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã qua các giai đoạn trong app.'**
  String get nuStagePast;

  /// 9b link to 9f. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem các giai đoạn'**
  String get nuSeeStages;

  /// 9b growth banner action → 9e. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem gợi ý'**
  String get nuSeeSuggestions;

  /// 9b milk card title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sữa mỗi ngày'**
  String get nuMilkTitle;

  /// 9b milk card subline. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo cho bé bú bình'**
  String get nuMilkSub;

  /// 9b milk card: the 7-day bottle average. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} trung bình {ml} ml/ngày (7 ngày qua)'**
  String nuMilkAverage(String name, String ml);

  /// 9b milk card with fewer than 3 days of bottle amounts (P-163 #4). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ cữ bú bình 7 ngày qua để tính trung bình'**
  String get nuMilkNotEnough;

  /// 9b milk card: feeds and per-feed amount. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{feeds} cữ, {perFeed} ml mỗi cữ'**
  String nuMilkFeeds(String feeds, String perFeed);

  /// 9b milk card: feeds only. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{feeds} cữ mỗi ngày'**
  String nuMilkFeedsOnly(String feeds);

  /// 9b milk card: per-feed amount only. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{perFeed} ml mỗi cữ'**
  String nuMilkPerFeedOnly(String perFeed);

  /// 9b / 9c breastfeeding note from the stage. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bú mẹ: {note}'**
  String nuMilkBreast(String note);

  /// Accessibility label of the milk band. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng tham khảo {range} ml mỗi ngày'**
  String nuMilkBandLabel(String range);

  /// Accessibility label of the milk band marker. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình {ml} ml mỗi ngày'**
  String nuMilkMarkerLabel(String ml);

  /// 9b growth card title (Cùng nuôi). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tăng trưởng so với chuẩn WHO'**
  String get nuGrowthTitle;

  /// 9b growth card subline. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lần đo gần nhất {date}'**
  String nuGrowthLast(String date);

  /// 9b growth card without a measurement. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lần đo'**
  String get nuGrowthNone;

  /// 9b growth tile. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get nuWeight;

  /// 9b growth tile. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài'**
  String get nuLength;

  /// WHO position tag: P3–P97. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trong khoảng chuẩn'**
  String get nuTagIn;

  /// WHO position tag: under P3 (never a diagnosis). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thấp hơn khoảng chuẩn'**
  String get nuTagBelow;

  /// WHO position tag: over P97 (never a diagnosis). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cao hơn khoảng chuẩn'**
  String get nuTagAbove;

  /// 9b micronutrients section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cần chú ý ở giai đoạn này'**
  String get nuNutrientsTitle;

  /// 9b sample day section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Một ngày tham khảo'**
  String get nuSampleTitle;

  /// Sample day slot. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get nuSlotMorning;

  /// Sample day slot. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trưa'**
  String get nuSlotNoon;

  /// Sample day slot. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều'**
  String get nuSlotAfternoon;

  /// Sample day slot. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get nuSlotEvening;

  /// Sample day slot. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đêm'**
  String get nuSlotNight;

  /// 9b tips section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho {name}'**
  String nuTipsTitle(String name);

  /// 9c title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng sữa'**
  String get nuMilkPageTitle;

  /// 9c intro. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo cho bé bú bình. Mỗi bé mỗi khác: cho bé bú theo dấu hiệu đói, no.'**
  String get nuMilkPageIntro;

  /// 9c chart title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'14 ngày qua'**
  String get nuChartTitle;

  /// 9c chart subline. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vùng màu: khoảng tham khảo {range} ml'**
  String nuChartBand(String range);

  /// 9c chart subline without a daily band. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn này không có khoảng tham khảo theo ngày'**
  String get nuChartNoBand;

  /// 9c bar tooltip. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {ml} ml'**
  String nuChartTooltip(String date, String ml);

  /// 9c chart without data. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cữ bú bình nào trong 14 ngày qua.'**
  String get nuChartEmpty;

  /// 9c / 9d section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo giai đoạn'**
  String get nuByStageTitle;

  /// 9c stage row amount per feed. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{range} ml/cữ'**
  String nuPerFeed(String range);

  /// 9c stage row amount per day. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{range} ml/ngày'**
  String nuPerDay(String range);

  /// 9c stage row feeds. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{range} cữ'**
  String nuFeeds(String range);

  /// 9c banner. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé thường xuyên bú nhiều hoặc ít hơn khoảng này: trao đổi với bác sĩ nhi.'**
  String get nuMilkTalkDoctor;

  /// 9d card title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao cần'**
  String get nuWhy;

  /// 9d foods section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thực phẩm gợi ý cho bé'**
  String get nuFoodsTitle;

  /// 9d tip card title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo'**
  String get nuTip;

  /// 9d campaign card → 9g. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lịch uống tại trạm y tế'**
  String get nuCampaignTitle;

  /// 9d campaign card subline. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đợt tới: {days}'**
  String nuNextRound(String days);

  /// 9e title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng của {name}'**
  String nuGrowthWeightTitle(String name);

  /// 9e title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài của {name}'**
  String nuGrowthLengthTitle(String name);

  /// 9e chart header. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo chuẩn WHO · bé trai'**
  String get nuWhoBoy;

  /// 9e chart header. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo chuẩn WHO · bé gái'**
  String get nuWhoGirl;

  /// 9e chart legend: P3–P97. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng chuẩn'**
  String get nuLegendBand;

  /// 9e tips section. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý trong lúc chờ khám'**
  String get nuWhileWaiting;

  /// 9e primary button. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc đo lại sau {days} ngày'**
  String nuRemindDays(int days);

  /// 9e primary button (whole weeks). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc đo lại sau {weeks} tuần'**
  String nuRemindWeeks(int weeks);

  /// 9e / 9g once the reminder is open. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt nhắc · {date}'**
  String nuReminded(String date);

  /// 9e toast. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt nhắc đo lại ngày {date}'**
  String nuRemindToast(String date);

  /// 9e reminder title (Nhắc nhở; no baby name). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đo lại cân nặng cho bé'**
  String get nuRemeasureWeight;

  /// 9e reminder title (Nhắc nhở; no baby name). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đo lại chiều dài cho bé'**
  String get nuRemeasureLength;

  /// 9e secondary button. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo cho bác sĩ'**
  String get nuExport;

  /// 9e footer. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý chung theo quy tắc của chuyên gia, không thay thế chẩn đoán.'**
  String get nuGrowthFooter;

  /// 9e for a rule that no longer applies / a caregiver. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không có gợi ý lúc này'**
  String get nuGrowthNoneTitle;

  /// 9e when the rule no longer fires. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các lần đo gần nhất của {name} không cần gợi ý nào lúc này.'**
  String nuGrowthNoSignal(String name);

  /// Doctor's summary: sex. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bé trai'**
  String get nuBoy;

  /// Doctor's summary: sex. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bé gái'**
  String get nuGirl;

  /// Doctor's summary, first line. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tăng trưởng · Child Life'**
  String get nuReportTitle;

  /// Doctor's summary share subject. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt tăng trưởng'**
  String get nuReportSubject;

  /// Doctor's summary: the baby's age (no name). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi: {age}'**
  String nuReportAge(String age);

  /// Doctor's summary. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính: {sex}'**
  String nuReportSex(String sex);

  /// Doctor's summary. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các lần đo gần nhất (so với chuẩn WHO, P3–P97):'**
  String get nuReportMeasures;

  /// Doctor's summary. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sữa bú bình trung bình 7 ngày qua: {ml} ml/ngày'**
  String nuReportMilk(String ml);

  /// Doctor's summary. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sữa bú bình: chưa đủ số liệu 7 ngày qua'**
  String get nuReportMilkNone;

  /// Doctor's summary: the rule's banner. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú từ app: {banner}'**
  String nuReportNote(String banner);

  /// Doctor's summary, last line. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Số liệu do gia đình ghi trong Child Life, tính đến {date}. Không phải chẩn đoán.'**
  String nuReportFooter(String date);

  /// Doctor's summary: replaces the baby's name in the rule's banner. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bé'**
  String get nuReportBaby;

  /// 9f title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các giai đoạn'**
  String get nuStagesTitle;

  /// 9g intro. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trẻ {ages} được uống miễn phí tại {place}, theo các đợt dưới đây.'**
  String nuVitaIntro(String ages, String place);

  /// 9g intro without a place. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trẻ {ages} được uống miễn phí theo các đợt dưới đây.'**
  String nuVitaIntroNoPlace(String ages);

  /// 9g before the eligible age. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ được uống từ {months} tháng tuổi.'**
  String nuVitaFrom(String name, int months);

  /// 9g before the eligible age. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đợt đầu tiên: {days}.'**
  String nuVitaFirst(String days);

  /// 9g round title (month number in vi, month name in en). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đợt tháng {month}'**
  String nuRoundTitle(String month);

  /// 9g round subline: its days. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {days}'**
  String nuRoundDaysLine(String days);

  /// 9g round taken. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống {date}'**
  String nuRoundTaken(String date);

  /// 9g next round tag. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get nuRoundNext;

  /// 9g past round not recorded (neutral, never red). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua, chưa ghi nhận'**
  String get nuRoundPast;

  /// 9g round before the eligible age. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tới tuổi'**
  String get nuRoundTooYoung;

  /// 9g round past the eligible age. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua độ tuổi'**
  String get nuRoundTooOld;

  /// 9g toast for others tapping a round. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Cùng nuôi ghi được đợt đã uống.'**
  String get nuVitaReadOnly;

  /// 9g toast for a round not begun. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đợt này chưa tới.'**
  String get nuVitaFuture;

  /// 9g mark sheet row. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày uống'**
  String get nuVitaDate;

  /// 9g mark sheet button. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã uống'**
  String get nuVitaMark;

  /// 9g mark sheet button for a taken round. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ đánh dấu'**
  String get nuVitaUnmark;

  /// 9g toast after marking. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi {round}'**
  String nuVitaMarked(String round);

  /// 9g toast after undo. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ đánh dấu'**
  String get nuVitaUnmarked;

  /// 9g button and sheet primary. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đặt nhắc'**
  String get nuVitaRemind;

  /// 9g reminder sheet title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc uống {name}'**
  String nuVitaSheetTitle(String name);

  /// 9g reminder sheet body. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước 1 ngày, lúc 8:00 sáng {date}. Lịch cụ thể theo thông báo của trạm y tế địa phương.'**
  String nuVitaSheetBody(String date);

  /// 9g reminder sheet once the day before has passed. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lúc 8:00 sáng {date}. Lịch cụ thể theo thông báo của trạm y tế địa phương.'**
  String nuVitaSheetBodySameDay(String date);

  /// 9g reminder sheet row: one member, default me. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get nuVitaRecipient;

  /// 9g reminder sheet toggle (.ics share). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào lịch điện thoại'**
  String get nuVitaCalendar;

  /// 9g reminder title in Nhắc nhở (no baby name). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Uống {name} tại trạm y tế · {days}'**
  String nuVitaReminderTitle(String name, String days);

  /// 9g calendar event title. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Uống {name} cho bé tại trạm y tế'**
  String nuVitaIcsSummary(String name);

  /// 9g footer and calendar note. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lịch cụ thể theo thông báo của trạm y tế địa phương.'**
  String get nuVitaLocalNote;

  /// 9g toast. D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt nhắc lúc 8:00 ngày {date}'**
  String nuVitaSetToast(String date);

  /// 9g link to the nutrient article (9d). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Về {name}'**
  String nuAbout(String name);

  /// 9b milk card when the stage gives only a daily amount (12–36 months: milk is a drink). D-083 Dinh dưỡng theo giai đoạn (plan docs/product/nutrition-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tham khảo {range} ml mỗi ngày'**
  String nuMilkPerDayOnly(String range);

  /// 4f Đã lưu segment: the care library. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chăm bé'**
  String get lbSavedCare;

  /// 4f Đã lưu segment: the solids library. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm'**
  String get lbSavedSolids;

  /// 5c chip opening the ingredient picker. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get sdAddFood;

  /// 5c picker row adding a free-text food (group Khác). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm “{name}”'**
  String sdAddFree(String name);

  /// 5e group chip for every food. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get sdAll;

  /// 5c field label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lượng bé ăn'**
  String get sdAmount;

  /// A typed whole number of bowls. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} chén}}'**
  String sdAmountBowls(int count);

  /// 5c amount: type a number and a unit. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhập'**
  String get sdAmountCustom;

  /// 5c amount preset. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vài thìa'**
  String get sdAmountFewSpoons;

  /// 5c amount preset. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'1 chén'**
  String get sdAmountFullBowl;

  /// 5c amount preset. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'½ chén'**
  String get sdAmountHalfBowl;

  /// 5c error for a typed amount out of range. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lượng từ 0,1 đến 1000, hoặc bỏ chọn “Tự nhập”.'**
  String get sdAmountInvalid;

  /// A typed whole number of spoons. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} thìa}}'**
  String sdAmountSpoons(int count);

  /// A typed amount with its unit ("1,5 chén", "120 ml"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{value} {unit}'**
  String sdAmountValue(String value, String unit);

  /// 5c urgent card link to the Sơ cứu anaphylaxis page (TH05). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sơ cứu: Sốc phản vệ'**
  String get sdAnaphylaxis;

  /// 5a for caregivers: only Cùng nuôi turn it on (P-164 #13). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhờ ba mẹ bật theo dõi ăn dặm'**
  String get sdAskParents;

  /// 5a for caregivers. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khi ba mẹ bật, bạn có thể ghi bữa và xem nhật ký ăn dặm của bé. Thư viện ăn dặm luôn mở cho bạn.'**
  String get sdAskParentsBody;

  /// 5a benefit row. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử bữa ăn và danh sách món đã thử'**
  String get sdBenefitHistory;

  /// 5a benefit row (recipes arrive later). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ăn dặm: hướng dẫn, cách bắt đầu'**
  String get sdBenefitLibrary;

  /// 5a benefit row. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bữa, món, lượng chỉ vài chạm'**
  String get sdBenefitLog;

  /// Food detail (Cùng nuôi): a food with signs may be suggested again. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bác sĩ đã cho ăn lại'**
  String get sdClear;

  /// Food detail banner once cleared. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bác sĩ đã cho ăn lại món này. App vẫn giữ lịch sử dấu hiệu.'**
  String get sdClearedNote;

  /// 5c date field (up to 7 days back). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get sdDate;

  /// 5b day header ("Hôm nay · 2 bữa"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {count, plural, other{{count} bữa}}'**
  String sdDayMeals(String day, int count);

  /// Meal detail action (soft delete with undo, 30-day bin). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bữa'**
  String get sdDelete;

  /// Meal delete confirmation title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bữa ăn này?'**
  String get sdDeleteTitle;

  /// Toast after deleting a meal (with Hoàn tác). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá bữa ăn'**
  String get sdDeletedToast;

  /// 5b segment. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký'**
  String get sdDiary;

  /// 5c field label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món'**
  String get sdDish;

  /// 5c dish placeholder. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'VD: Cháo cà rốt thịt gà'**
  String get sdDishHint;

  /// 5a banner. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi bác sĩ của bé khi nào nên bắt đầu ăn dặm và cách phù hợp với bé.'**
  String get sdDoctorNote;

  /// Chưa đến lúc page note (P-164 #2). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bác sĩ khuyên bé bắt đầu sớm hơn, hãy làm theo bác sĩ và dùng thư viện để chuẩn bị. Nhật ký ăn dặm mở khi bé đủ 6 tháng.'**
  String get sdEarlyNote;

  /// 5b empty past day. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bữa nào trong ngày này'**
  String get sdEmptyDay;

  /// 5b empty day, 5h card without a meal. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bữa nào hôm nay'**
  String get sdEmptyToday;

  /// 5h chip with today's first tries. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu: {foods}'**
  String sdFirstToday(String foods);

  /// 5e row line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu {day} · {count, plural, other{{count} lần}}'**
  String sdFirstTried(String day, int count);

  /// First-try ingredient chip (5c, meal detail) and its spoken label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{food} · lần đầu'**
  String sdFirstTryChip(String food);

  /// 5b legend under the meal cards. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'✦ Lần đầu bé thử'**
  String get sdFirstTryLegend;

  /// Food detail section. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các bữa có món này · {count}'**
  String sdFoodMeals(int count);

  /// Food detail when nothing matches. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy món này'**
  String get sdFoodMissing;

  /// Food detail when nothing matches. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món có thể đã được bỏ khỏi các bữa ăn.'**
  String get sdFoodMissingBody;

  /// 5c ingredient picker search. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tìm món, nguyên liệu…'**
  String get sdFoodSearch;

  /// Food detail banner (P-164 #6; never 'dị ứng' as a fact). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé có dấu hiệu sau khi ăn món này. Tạm chưa cho lại và hỏi bác sĩ của bé; app sẽ không gợi ý món này cho đến khi ba mẹ đánh dấu “Bác sĩ đã cho ăn lại”.'**
  String get sdFoodSignsNote;

  /// 5f format filter. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết'**
  String get sdFormatArticle;

  /// 5f format filter. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi nhanh'**
  String get sdFormatQuickQa;

  /// 5f format filter. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Từng bước'**
  String get sdFormatStepGuide;

  /// 5c picker: a food above the baby's age. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thường từ {months} tháng'**
  String sdFromMonths(int months);

  /// 5e group chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{group} · {count}'**
  String sdGroupCount(String group, int count);

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sữa và chế phẩm'**
  String get sdGroupDairy;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chất béo'**
  String get sdGroupFat;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trái cây'**
  String get sdGroupFruit;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tinh bột'**
  String get sdGroupGrain;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đậu và hạt'**
  String get sdGroupLegume;

  /// Food group of free-text foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get sdGroupOther;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đạm động vật'**
  String get sdGroupProtein;

  /// Food group. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Rau củ'**
  String get sdGroupVegetable;

  /// 5f featured card eyebrow. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn · {format}'**
  String sdGuideKicker(String format);

  /// 5f section. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn'**
  String get sdGuides;

  /// Food detail (Cùng nuôi): adds it to settings.hidden. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không gợi ý món này'**
  String get sdHide;

  /// 5d empty. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bữa nào'**
  String get sdHistoryEmpty;

  /// 5d empty. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các bữa đã ghi sẽ hiện ở đây, mới nhất ở trên.'**
  String get sdHistoryEmptyBody;

  /// 5d title and the 5b link. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử bữa ăn'**
  String get sdHistoryTitle;

  /// 5c field label and the picker title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nguyên liệu'**
  String get sdIngredients;

  /// 5h card line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gần nhất: {dish} · {time}'**
  String sdLatest(String dish, String time);

  /// 5f with nothing published. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các bài hướng dẫn ăn dặm sẽ hiện ở đây khi được xuất bản.'**
  String get sdLibraryEmpty;

  /// 5f without results. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khoá khác hoặc bỏ bớt bộ lọc độ tuổi, loại bài.'**
  String get sdLibraryNoResults;

  /// 5f search placeholder. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tìm món, nguyên liệu, hướng dẫn…'**
  String get sdLibrarySearch;

  /// Row opening 5f from 5a. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn ăn dặm theo độ tuổi'**
  String get sdLibrarySub;

  /// 5f title and the 5b segment. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ăn dặm'**
  String get sdLibraryTitle;

  /// 5b FAB, 5h button. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bữa'**
  String get sdLogMeal;

  /// 5b card slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa chiều'**
  String get sdMealAfternoon;

  /// 5b card slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa tối'**
  String get sdMealEvening;

  /// Meal detail of a deleted meal. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bữa ăn'**
  String get sdMealMissing;

  /// Meal detail of a deleted meal. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn có thể đã được xoá.'**
  String get sdMealMissingBody;

  /// 5b card slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa sáng'**
  String get sdMealMorning;

  /// 5b card slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa trưa'**
  String get sdMealNoon;

  /// 5b card slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa phụ'**
  String get sdMealSnack;

  /// 5d segment. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn'**
  String get sdMealsTab;

  /// 5a feeding style. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'BLW'**
  String get sdMethodBlw;

  /// 5a feeding style help line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé tự cầm thức ăn mềm, cắt thanh vừa tay.'**
  String get sdMethodBlwHelp;

  /// 5a feeding style (default). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Kết hợp'**
  String get sdMethodMixed;

  /// 5a feeding style help line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vừa đút thìa vừa cho bé tự cầm, tuỳ món.'**
  String get sdMethodMixedHelp;

  /// 5a feeding style. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Truyền thống'**
  String get sdMethodSpoon;

  /// 5a feeding style help line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đút thìa, từ nghiền mịn rồi đặc dần.'**
  String get sdMethodSpoonHelp;

  /// 5a and settings label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cách cho ăn (không bắt buộc)'**
  String get sdMethodTitle;

  /// 5c error. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tên món hoặc ít nhất một nguyên liệu.'**
  String get sdNeedDish;

  /// 5c picker before foods are published. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục món đang được cập nhật. Bạn vẫn có thể gõ tên món ở trên (tối đa 3).'**
  String get sdNoCatalogue;

  /// 5a without a date of birth (Cùng nuôi). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký ăn dặm mở khi {name} đủ 6 tháng. Thêm ngày sinh để app biết khi nào.'**
  String sdNoDobBody(String name);

  /// 5a without a date of birth (others). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa được xem ngày sinh của {name}, nên app chưa biết bé đã đủ 6 tháng chưa.'**
  String sdNoDobViewer(String name);

  /// 5c picker and food detail. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thử'**
  String get sdNotTried;

  /// Chưa đến lúc page, 4–5 months (P-164 #2). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} {age}, sắp đến lúc ăn dặm. Nhật ký mở khi bé tròn 6 tháng, ngày {date}. Trong lúc chờ, xem bé đã có dấu hiệu sẵn sàng chưa.'**
  String sdNotYetSoon(String name, String age, String date);

  /// Chưa đến lúc page title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đến lúc ăn dặm'**
  String get sdNotYetTitle;

  /// Chưa đến lúc page, under 4 months. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} {age}. Sữa mẹ hoặc sữa công thức là đủ cho bé lúc này. Nhật ký ăn dặm mở khi bé tròn 6 tháng, ngày {date}.'**
  String sdNotYetYoung(String name, String age, String date);

  /// 5c field label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (không bắt buộc)'**
  String get sdNote;

  /// 5c note placeholder. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ghi chú…'**
  String get sdNoteHint;

  /// Dinh dưỡng 9b row while tracking is on (P-164 #1). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm hôm nay · {count, plural, other{{count} bữa}}'**
  String sdNutritionRow(int count);

  /// Diary pages while tracking is off. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ba mẹ có thể bật theo dõi ăn dặm trong Chăm sóc › Ăn dặm.'**
  String get sdOffBody;

  /// Diary pages while tracking is off. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa bật theo dõi ăn dặm'**
  String get sdOffTitle;

  /// Dinh dưỡng 9b row link. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhật ký'**
  String get sdOpenDiary;

  /// 5c field label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bé ăn thế nào'**
  String get sdReaction;

  /// Reaction. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get sdReactionLiked;

  /// Reaction. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get sdReactionNeutral;

  /// Reaction (neutral, never a warning, P-164 #17). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hợp'**
  String get sdReactionNotYet;

  /// Chưa đến lúc page: the readiness guide row. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dấu hiệu sẵn sàng'**
  String get sdReadinessKicker;

  /// 5f recipes section (phase C). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức'**
  String get sdRecipes;

  /// 5f recipes section for an age band (phase C). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức · {band}'**
  String sdRecipesFor(String band);

  /// Chưa đến lúc page: a one-time reminder at 5 months 2 weeks. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc tôi khi bé gần 6 tháng'**
  String get sdRemindMe;

  /// Chưa đến lúc page once the reminder is set. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt nhắc · {date}'**
  String sdRemindSet(String date);

  /// Toast after setting the 6-month reminder. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt nhắc ngày {date}'**
  String sdRemindToast(String date);

  /// Reminder title in Nhắc nhở. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} gần 6 tháng: xem cách bắt đầu ăn dặm'**
  String sdReminderTitle(String name);

  /// Spoken label of a removable ingredient chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ {food}'**
  String sdRemoveFood(String food);

  /// 5c primary button. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Lưu bữa'**
  String get sdSave;

  /// Toast after logging a meal (with Hoàn tác). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi · {meal}'**
  String sdSavedToast(String meal);

  /// Tuỳ chỉnh Hôm nay row for the 5h card. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm hôm nay'**
  String get sdSectionToday;

  /// Tuỳ chỉnh Hôm nay row subtitle. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa gần nhất và món mới hôm nay'**
  String get sdSectionTodaySub;

  /// 5b link to 5e. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get sdSeeAll;

  /// 5b settings pill and sheet title (Cùng nuôi). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get sdSettings;

  /// 5c title when editing. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sửa bữa ăn'**
  String get sdSheetEditTitle;

  /// 5c title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bữa ăn'**
  String get sdSheetTitle;

  /// 5d: more days. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get sdShowMore;

  /// 5a and settings toggle. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hiện “Ăn dặm hôm nay” trên Hôm nay'**
  String get sdShowOnToday;

  /// Tag on a meal or food with signs after eating (never 'dị ứng'). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có dấu hiệu'**
  String get sdSignsTag;

  /// 5c slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chiều'**
  String get sdSlotAfternoon;

  /// 5c slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get sdSlotEvening;

  /// 5c slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get sdSlotMorning;

  /// 5c slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Trưa'**
  String get sdSlotNoon;

  /// 5c slot. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Phụ'**
  String get sdSlotSnack;

  /// 5b card head ("Bữa sáng · 08:10"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{slot} · {time}'**
  String sdSlotTime(String slot, String time);

  /// 5a primary (Cùng nuôi). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu theo dõi'**
  String get sdStart;

  /// 5a subtitle. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh từng bữa, xem lại những món bé đã thử và đọc hướng dẫn từ đội chuyên môn.'**
  String get sdStartBody;

  /// 5a title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi ăn dặm'**
  String get sdStartTitle;

  /// Settings: when tracking started. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get sdStartedOn;

  /// Settings: no start date set and no meal yet. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo bữa đầu tiên'**
  String get sdStartedOnAuto;

  /// Settings: the first meal's date. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa đầu tiên · {date}'**
  String sdStartedOnAutoDate(String date);

  /// Settings: clear the start date. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dùng ngày bữa đầu tiên'**
  String get sdStartedOnReset;

  /// Toast after 5a. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật theo dõi ăn dặm'**
  String get sdStartedToast;

  /// Settings action. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dừng theo dõi'**
  String get sdStop;

  /// Stop tracking confirmation. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các bữa đã ghi vẫn được giữ. Ba mẹ có thể bật lại bất cứ lúc nào.'**
  String get sdStopBody;

  /// Stop tracking confirmation title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dừng theo dõi ăn dặm?'**
  String get sdStopTitle;

  /// 5b suggestions section (phase D). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cho {name} hôm nay'**
  String sdSuggestionsTitle(String name);

  /// Symptom chip (urgent: shows the 115 card). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khó thở, ho, khò khè'**
  String get sdSymptomBreathing;

  /// Symptom chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chảy'**
  String get sdSymptomDiarrhea;

  /// Symptom chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Quấy khóc bất thường'**
  String get sdSymptomFussy;

  /// Symptom chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get sdSymptomOther;

  /// Symptom chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nổi mẩn, mề đay'**
  String get sdSymptomRash;

  /// Symptom chip (urgent: shows the 115 card). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sưng môi, mặt'**
  String get sdSymptomSwelling;

  /// Symptom chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nôn'**
  String get sdSymptomVomit;

  /// Meal detail: no signs recorded. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không có'**
  String get sdSymptomsNone;

  /// 5c and meal detail when signs are recorded (P-164 #6). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các món mới trong bữa này sẽ được đánh dấu “Có dấu hiệu sau khi ăn”. Hỏi bác sĩ của bé nếu bạn còn lo.'**
  String get sdSymptomsNote;

  /// 5c field label (P-164 #6). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có dấu hiệu bất thường sau khi ăn?'**
  String get sdSymptomsQuestion;

  /// Meal and food detail label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dấu hiệu sau khi ăn'**
  String get sdSymptomsTitle;

  /// Care tile under 4 months. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Từ 6 tháng'**
  String get sdTileFrom6;

  /// Care tile at 4–5 months. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sắp đến lúc ăn dặm'**
  String get sdTileSoon;

  /// Care tile from 6 months, tracking off. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu theo dõi'**
  String get sdTileStart;

  /// Care tile while tracking is on. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {count, plural, other{{count} bữa}}'**
  String sdTileToday(int count);

  /// 5c time field. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get sdTime;

  /// Day label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get sdToday;

  /// 5h card head. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm hôm nay · {count, plural, other{{count} bữa}}'**
  String sdTodayCard(int count);

  /// Day label inside a sentence (5e "Lần đầu hôm nay"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get sdTodayLower;

  /// 5c picker: a food tried before. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử'**
  String get sdTried;

  /// 5b / 5e without foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Các món bé đã thử sẽ hiện ở đây sau bữa đầu tiên.'**
  String get sdTriedEmpty;

  /// 5e without foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có món nào'**
  String get sdTriedEmptyTitle;

  /// 5e footnote (P-164 #17). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị dinh dưỡng.'**
  String get sdTriedFootnote;

  /// 5c picker: tried, with the latest reaction. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử · {reaction}'**
  String sdTriedReaction(String reaction);

  /// 5d / 5e segment. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món đã thử'**
  String get sdTriedTab;

  /// 5b section. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món đã thử · {count}'**
  String sdTriedTitle(int count);

  /// Food detail (Cùng nuôi). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ đánh dấu “Bác sĩ đã cho ăn lại”'**
  String get sdUnclear;

  /// Food detail (Cùng nuôi): removes it from settings.hidden. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý lại món này'**
  String get sdUnhide;

  /// Typed amount unit. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chén'**
  String get sdUnitBowl;

  /// Typed amount unit. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'thìa'**
  String get sdUnitSpoon;

  /// 5f featured card meta. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'cập nhật {date}'**
  String sdUpdated(String date);

  /// 5c red card for swelling or breathing, before saving (P-164 #6). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gọi {number} ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi.'**
  String sdUrgent(String number);

  /// Meal detail for who cannot edit it (P-164 #13). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa này do người khác ghi: bạn chỉ xem được.'**
  String get sdViewOnly;

  /// Day label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get sdYesterday;

  /// 5c photo field label and meal detail row. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bữa ăn'**
  String get sdPhoto;

  /// 5c dashed photo button and the source sheet title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh bữa ăn'**
  String get sdPhotoAdd;

  /// 5c: replace the meal photo. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh'**
  String get sdPhotoReplace;

  /// 5c: remove the meal photo (the corner ×). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get sdPhotoRemove;

  /// Photo source sheet privacy line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ những người chăm bé trong gia đình xem được ảnh này.'**
  String get sdPhotoPrivate;

  /// Toast when a meal photo fails to pick, compress or upload. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được ảnh. Bữa ăn vẫn lưu được; thử thêm ảnh lại sau nhé.'**
  String get sdPhotoFailed;

  /// 5c photo field while offline (the meal saves, the photo needs the network). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cần có mạng để thêm ảnh. Bữa ăn vẫn lưu được khi không có mạng.'**
  String get sdPhotoOffline;

  /// Lịch sử filter chip for solid meals (while tracking is on). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm'**
  String get sdHistoryFilter;

  /// Lịch sử empty day, inserted into emptyTodayTitle / logNow / backLog. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bữa ăn dặm'**
  String get sdHistoryWhat;

  /// Lịch sử solids summary title for a past day. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn dặm ngày {date}'**
  String sdHistoryOnDay(String date);

  /// Lịch sử solids summary row label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Số bữa'**
  String get sdHistoryMeals;

  /// Lịch sử solids summary row label: foods tried for the first time that day. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món mới'**
  String get sdHistoryNewFoods;

  /// A number of solid meals. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} bữa}}'**
  String sdMealsCount(int count);

  /// A number of foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} món}}'**
  String sdFoodsCount(int count);

  /// Lịch sử solids link card title (opens 5b). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký ăn dặm'**
  String get sdHistoryLink;

  /// Lịch sử solids link card subtitle. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món đã thử, lịch sử bữa ăn và gợi ý cho bé'**
  String get sdHistoryLinkHint;

  /// Thống kê card title (while tracking is on). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn dặm'**
  String get sdStatsTitle;

  /// Thống kê solids card subtitle. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày gần đây · chỉ để tham khảo'**
  String sdStatsHint(int days);

  /// Thống kê solids card subtitle on the Hôm nay window. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · chỉ để tham khảo'**
  String get sdStatsTodayHint;

  /// Thống kê solids chart average line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'TB {value} bữa/ngày'**
  String sdStatsAvg(String value);

  /// Thống kê solids chart callout for a day. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{day}: {count, plural, other{{count} bữa}}'**
  String sdStatsDayTip(String day, int count);

  /// Thống kê solids KPI label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa hôm nay'**
  String get sdStatsMealsToday;

  /// Thống kê solids KPI label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bữa mỗi ngày (TB)'**
  String get sdStatsPerDay;

  /// Thống kê solids KPI label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món mới tuần này'**
  String get sdStatsNewThisWeek;

  /// Thống kê solids: heading of the per-week rows. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món mới mỗi tuần'**
  String get sdStatsNewPerWeek;

  /// Thống kê solids per-week row label. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tuần từ {date}'**
  String sdStatsWeekOf(String date);

  /// Thống kê solids footnote (information only, P-164 #17). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đây là ghi chép của gia đình, không phải mục tiêu số bữa hay số món.'**
  String get sdStatsNote;

  /// 5f recipe row meta (total minutes). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức · {minutes} phút'**
  String sdRecipeMeta(int minutes);

  /// 5f section of recipes ranked for the baby (plan §7). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho {name}'**
  String sdForBaby(String name);

  /// 5f recipes with filters that match nothing. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có công thức hợp bộ lọc này.'**
  String get sdRecipesNone;

  /// Recipe list opened from a suggestion ("Xem công thức"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức có {foods}'**
  String sdRecipesWith(String foods);

  /// Recipe list from a suggestion with no match. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có công thức hợp tuổi và cách cho ăn của bé có món này. Xem các công thức khác trong thư viện.'**
  String get sdRecipesWithNone;

  /// 5g when the recipe is not published (or not on the device yet). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy công thức'**
  String get sdRecipeMissing;

  /// 5g missing recipe body. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức có thể đã được gỡ hoặc chưa tải về máy.'**
  String get sdRecipeMissingBody;

  /// Recipe texture chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nghiền mịn'**
  String get sdTextureSmooth;

  /// Recipe texture chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Nghiền lợn cợn'**
  String get sdTextureMashed;

  /// Recipe texture chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cắt nhỏ, mềm'**
  String get sdTextureSoftPieces;

  /// Recipe texture chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cầm tay'**
  String get sdTextureFinger;

  /// Recipe texture chip. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ăn cùng gia đình'**
  String get sdTextureFamily;

  /// 5g servings. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count} phần ăn'**
  String sdServings(int count);

  /// 5g preparation and cooking minutes. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sơ chế {prep} phút · nấu {cook} phút'**
  String sdPrepCook(int prep, int cook);

  /// 5g steps heading. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cách làm'**
  String get sdSteps;

  /// 5g storage heading. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Bảo quản'**
  String get sdStorage;

  /// 5g tip heading. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo'**
  String get sdTip;

  /// 5g ingredient: a catalogue food the baby has not had (tracking on). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'✦ Bé chưa thử'**
  String get sdNotTriedMark;

  /// 5g ingredient: a food with recorded symptoms (never "dị ứng" as a fact, P-164 #6). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'⚠ Có dấu hiệu'**
  String get sdSignsMark;

  /// 5g allergen line from recipeAllergens ("Có trứng"). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Có {list}'**
  String sdContains(String list);

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'trứng'**
  String get sdAllergenEgg;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'đậu phộng'**
  String get sdAllergenPeanut;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'sữa bò'**
  String get sdAllergenMilk;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'lúa mì'**
  String get sdAllergenWheat;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'đậu nành'**
  String get sdAllergenSoy;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'cá'**
  String get sdAllergenFish;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'tôm, cua, sò'**
  String get sdAllergenShellfish;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'vừng (mè)'**
  String get sdAllergenSesame;

  /// Common allergen name (lower case, in sentences). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'các loại hạt'**
  String get sdAllergenTreeNut;

  /// 5g notice when the recipe starts above the baby's age. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Công thức cho bé từ {from} tháng. {name} mới {age}: chọn công thức hợp tuổi hoặc hỏi bác sĩ của bé.'**
  String sdAgeNotice(int from, String name, String age);

  /// 5g primary button: opens 5c with the dish, its foods and the recipe. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Ghi vào nhật ký'**
  String get sdLogRecipe;

  /// Recipe unit. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'thìa canh'**
  String get sdIngUnitTbsp;

  /// Recipe unit. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'thìa cà phê'**
  String get sdIngUnitTsp;

  /// Recipe unit (with a decimal quantity). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'chén'**
  String get sdIngUnitBowl;

  /// Recipe unit (with a decimal quantity). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'miếng'**
  String get sdIngUnitPiece;

  /// Recipe quantity in bowls. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} chén}}'**
  String sdIngBowls(int count);

  /// Recipe quantity in pieces. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} miếng}}'**
  String sdIngPieces(int count);

  /// Suggestion card: snooze it for 3 days on this device. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get sdSuggestLater;

  /// Sheet title when a card suggests several foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Không gợi ý món nào?'**
  String get sdSuggestHideWhich;

  /// Toast after a parent hides a food (settings.hidden). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ không gợi ý {food} nữa'**
  String sdSuggestHidden(String food);

  /// Toast after a caregiver hides a food (device snooze; settings are Cùng nuôi's). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn {food} khỏi gợi ý trên máy này trong 30 ngày'**
  String sdSuggestSnoozedFood(String food);

  /// Toast after "Để sau". D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ gợi ý lại sau 3 ngày'**
  String get sdSuggestSnoozed;

  /// S1 action. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đọc: Nhận biết phản ứng'**
  String get sdActReadReactions;

  /// S3 / S5 action. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem công thức'**
  String get sdActRecipes;

  /// S8 action. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Xem gợi ý'**
  String get sdActIdeas;

  /// S9 action. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đọc hướng dẫn'**
  String get sdActGuide;

  /// Joins the last of several suggested foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get sdOr;

  /// A suggested iron-rich food. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{food} (giàu sắt)'**
  String sdIronMark(String food);

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'trứng chín kỹ'**
  String get sdTryEgg;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bơ đậu phộng pha loãng (không cho cả hạt)'**
  String get sdTryPeanut;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'sữa chua hoặc sữa bò nấu trong món'**
  String get sdTryMilk;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'lúa mì (bánh mì, mì nấu mềm)'**
  String get sdTryWheat;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'cá chín kỹ, gỡ hết xương'**
  String get sdTryFish;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'đậu phụ hoặc sữa đậu nành nấu trong món'**
  String get sdTrySoy;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'vừng (mè) xay mịn trộn vào món'**
  String get sdTrySesame;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'tôm hoặc cua chín kỹ, băm nhỏ'**
  String get sdTryShellfish;

  /// S3: how to offer the allergen. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'bơ hạt (hạnh nhân, điều) pha loãng, không cho cả hạt'**
  String get sdTryTreeNut;

  /// S1 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi sau dấu hiệu hôm {date} ({foods}). Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo.'**
  String sdS1Title(String date, String foods);

  /// S1 card title without foods. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi sau dấu hiệu hôm {date}. Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo.'**
  String sdS1TitlePlain(String date);

  /// S1 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì bữa hôm {date} có ghi dấu hiệu sau khi ăn.'**
  String sdS1Why(String date);

  /// S2 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món tiếp theo cho {name}: {foods}.'**
  String sdS2Title(String name, String foods);

  /// S2 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì {name} mới thử {count} món: bắt đầu từ rau củ, tinh bột và một món giàu sắt, mỗi lần một món mới.'**
  String sdS2Why(String name, int count);

  /// S3 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Đã đến lúc thử {allergen}: buổi sáng, ở nhà, một lượng nhỏ.'**
  String sdS3Title(String allergen);

  /// S3 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì {name} đã quen {count} món và ăn dặm được {days} ngày: các món thường gây dị ứng nên cho làm quen từng món một, cách nhau vài ngày.'**
  String sdS3Why(String name, int count, int days);

  /// S4 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Cho {name} ăn lại {allergen} tuần này để duy trì.'**
  String sdS4Title(String name, String allergen);

  /// S4 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì lần gần nhất bé ăn {allergen} là {date}: món đã quen nên được ăn đều đặn.'**
  String sdS4Why(String allergen, String date);

  /// S5 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay thêm một món giàu sắt: {foods}.'**
  String sdS5Title(String foods);

  /// S5 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì 2 ngày qua các bữa của {name} chưa có món giàu sắt; từ 6 tháng bé cần sắt từ thức ăn mỗi ngày.'**
  String sdS5Why(String name);

  /// S6 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Món mới tiếp theo: {foods}.'**
  String sdS6Title(String foods);

  /// S6 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì {name} chưa thử món mới 2 ngày; nhóm {group} bé mới thử {count} món.'**
  String sdS6Why(String name, String group, int count);

  /// S7 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại {food} theo cách khác: nghiền mịn hơn hoặc trộn với {liked} {name} thích.'**
  String sdS7Title(String food, String liked, String name);

  /// S7 card title without a liked food. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại {food} theo cách khác: nghiền mịn hơn hoặc đổi cách nấu.'**
  String sdS7TitlePlain(String food);

  /// S7 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì lần gần nhất {name} chưa hợp {food} (đã thử {count} lần). Bé có thể cần 8–15 lần mới quen một món.'**
  String sdS7Why(String name, String food, int count);

  /// S8 card title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này {name} chưa ăn {group} nào.'**
  String sdS8Title(String name, String group);

  /// S8 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì lần gần nhất bé ăn {group} là {date}; đổi món giúp bé quen nhiều vị.'**
  String sdS8Why(String group, String date);

  /// S9 card title (texture from the Dinh dưỡng stage). D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'{name} {months} tháng: {texture}.'**
  String sdS9Title(String name, int months, String texture);

  /// S9 "vì sao" line. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Vì {name} vừa sang giai đoạn {stage} trong Dinh dưỡng; thức ăn thô dần theo từng giai đoạn.'**
  String sdS9Why(String name, String stage);

  /// S8 "Xem gợi ý" sheet title. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý: {group}'**
  String sdIdeasTitle(String group);

  /// S8 ideas sheet hint. D-085 Ăn dặm (plan docs/product/solids-plan.md). EN is an engineering draft for owner review.
  ///
  /// In vi, this message translates to:
  /// **'Chạm một món để ghi bữa.'**
  String get sdIdeasHint;
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
