// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Child Life';

  @override
  String get configErrorTitle => 'Cấu hình môi trường không hợp lệ.';

  @override
  String get diagnosticsEnvironment => 'Môi trường';

  @override
  String get diagnosticsServer => 'Kết nối máy chủ';

  @override
  String diagnosticsConnected(String projectId, String region) {
    return 'Đã kết nối $projectId ($region)';
  }

  @override
  String get diagnosticsChecking => 'Đang kiểm tra…';

  @override
  String diagnosticsUnreachable(String error) {
    return 'Không kết nối được: $error';
  }

  @override
  String get diagnosticsRetry => 'Kiểm tra lại';

  @override
  String get diagnosticsFlags => 'Cấu hình tính năng';

  @override
  String get diagnosticsFlagsEmpty => 'Chưa có cấu hình';

  @override
  String diagnosticsFlagsCount(int enabled, int total) {
    return '$enabled/$total đang bật';
  }

  @override
  String get diagnosticsLoading => 'Đang tải…';

  @override
  String diagnosticsUnreadable(String error) {
    return 'Không đọc được: $error';
  }

  @override
  String get diagnosticsTestCrash => 'Gửi lỗi thử tới Crashlytics';

  @override
  String get diagnosticsDevOnly => 'Chỉ có ở bản dev';

  @override
  String get a11yBack => 'Quay lại';

  @override
  String get a11yClose => 'Đóng';

  @override
  String get a11yNext => 'Tiếp tục';

  @override
  String get a11yQuickLog => 'Ghi nhanh';

  @override
  String get a11yNightCareToggle => 'Night care';

  @override
  String get tabToday => 'Hôm nay';

  @override
  String get tabMemories => 'Kỷ niệm';

  @override
  String get tabFamily => 'Gia đình';

  @override
  String get tabMe => 'Tôi';

  @override
  String get actionSkip => 'Bỏ qua';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get actionNext => 'Tiếp';

  @override
  String get actionDone => 'Xong';

  @override
  String get actionLater => 'Để sau';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get actionOpenSettings => 'Mở Cài đặt';

  @override
  String get splashTagline => 'Cùng chăm con. Giữ tuổi thơ.';

  @override
  String get welcomeTitle => 'Cùng chăm con,\ngiữ trọn tuổi thơ';

  @override
  String get welcomeExplore => 'Khám phá';

  @override
  String get welcomeSignIn => 'Đăng nhập';

  @override
  String get welcomeInviteCode => 'Mã mời';

  @override
  String get welcomeChipMilestone => 'Mốc mới';

  @override
  String get a11yToggleAppearance => 'Đổi giao diện sáng / tối';

  @override
  String get tourCareTitle => 'Ghi bú, ngủ, tã\nchỉ bằng một tay';

  @override
  String get tourCareBody => 'Tối đa 3 chạm là lưu xong.';

  @override
  String get tourCareChipBottle => 'Bú bình · 120 ml';

  @override
  String get tourCareChipDiaper => 'Thay tã · Ướt';

  @override
  String get tourCareChipSleep => 'Ngủ · 1 giờ 20';

  @override
  String get tourCareTaps => 'chạm';

  @override
  String get tourShareTitle => 'Nhận ca, không cần hỏi';

  @override
  String get tourShareBody =>
      'Lần ghi gần nhất được đồng bộ cho cả nhà: ai ghi, ghi gì, lúc nào.';

  @override
  String get tourShareSynced => 'Đã đồng bộ';

  @override
  String get tourShareAsleep => 'Đang ngủ';

  @override
  String get tourShareChipMom => 'Bú bình · 80 ml · Mẹ ghi';

  @override
  String get tourShareChipDad => 'Thay tã · Ướt · Ba ghi';

  @override
  String get tourShareInitialMom => 'M';

  @override
  String get tourShareInitialDad => 'B';

  @override
  String get tourStoryTitle => 'Khoảnh khắc\nthành chuyện';

  @override
  String get tourStoryBody =>
      'Một ảnh thành thẻ kỷ niệm ngay. Cuối tuần có nhật ký của bé.';

  @override
  String get tourStoryChipCard => 'Thẻ kỷ niệm tức thì';

  @override
  String get tourStoryChipJournal => 'Nhật ký tuần 8';

  @override
  String get tourPrivateTitle => 'Đúng người,\nđúng quyền';

  @override
  String get tourPrivateBody =>
      'Bà được xem ảnh, cô trông trẻ được ghi cữ bú. Bạn quyết định ai thấy gì.';

  @override
  String get tourPrivateChipAccess => 'Bạn chọn quyền';

  @override
  String get tourPrivateChipInvite => 'Mời người thân';

  @override
  String get tourPrivateInitials => 'M|B|Bà|L';

  @override
  String get tourCreateProfile => 'Tạo hồ sơ bé';

  @override
  String get signInTitle => 'Chào bạn';

  @override
  String get signInSubtitle => 'Đăng nhập để bắt đầu.';

  @override
  String get signInApple => 'Tiếp tục với Apple';

  @override
  String get signInGoogle => 'Tiếp tục với Google';

  @override
  String get signInEmail => 'Dùng email';

  @override
  String get signInLegal => 'Điều khoản · Quyền riêng tư';

  @override
  String get signInHeroLetters => 'B|é';

  @override
  String get emailTitle => 'Email';

  @override
  String get emailNewAccount => 'Tài khoản mới';

  @override
  String get emailSignInTab => 'Đăng nhập';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailPlaceholder => 'ten@email.com';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get passwordPlaceholder => '8+ ký tự';

  @override
  String get emailCreateAccount => 'Tạo tài khoản';

  @override
  String get emailSignInButton => 'Đăng nhập';

  @override
  String get emailUsedWithProvider => 'Email đã dùng với Apple/Google?';

  @override
  String get emailForgot => 'Quên mật khẩu?';

  @override
  String get authErrorInvalidEmail => 'Email chưa đúng, bạn kiểm tra lại nhé.';

  @override
  String get authErrorWeakPassword => 'Mật khẩu cần ít nhất 8 ký tự.';

  @override
  String get authErrorWrongCredentials => 'Email hoặc mật khẩu chưa đúng.';

  @override
  String get authErrorTooManyRequests =>
      'Bạn thử hơi nhiều lần. Đợi một lát rồi thử lại nhé.';

  @override
  String get authErrorNetwork => 'Không có mạng. Kiểm tra kết nối rồi thử lại.';

  @override
  String get authErrorNotConfigured =>
      'Cách đăng nhập này chưa sẵn sàng trên bản thử nghiệm.';

  @override
  String get authErrorDisabled =>
      'Tài khoản này đang bị khoá. Liên hệ Child Life để được giúp.';

  @override
  String get authErrorGeneric => 'Có lỗi xảy ra. Thử lại nhé.';

  @override
  String get authErrorLinkFailed =>
      'Đã đăng nhập nhưng chưa liên kết được email. Thử lại trong phần Tài khoản.';

  @override
  String get verifyTitle => 'Kiểm tra email';

  @override
  String get verifyBody => 'Mình đã gửi link xác minh tới';

  @override
  String get verifyOpenMail => 'Mở Mail';

  @override
  String get verifyResend => 'Gửi lại email';

  @override
  String verifyResendIn(int seconds) {
    return 'Gửi lại sau $seconds giây';
  }

  @override
  String get verifyResent => 'Đã gửi lại. Nhớ xem cả mục Thư rác nhé.';

  @override
  String get verifyDone => 'Email đã được xác minh';

  @override
  String get verifyNoMailApp => 'Không mở được ứng dụng Mail trên máy này.';

  @override
  String get verifyLaterHint =>
      'Bạn có thể tiếp tục. Cần xác minh trước khi mời người thân.';

  @override
  String get forgotTitle => 'Quên mật khẩu';

  @override
  String get forgotBody => 'Nhập email, mình gửi link đặt lại.';

  @override
  String get forgotSend => 'Gửi link';

  @override
  String get forgotSent =>
      'Nếu email này có tài khoản, link đặt lại đã được gửi tới hộp thư.';

  @override
  String get existsTitle => 'Email đã có tài khoản';

  @override
  String get existsBody => 'Đăng nhập bằng Apple hoặc Google, rồi liên kết.';

  @override
  String get existsProvider => 'Apple · Google';

  @override
  String get existsUseOtherEmail => 'Dùng email khác';

  @override
  String get existsLinked => 'Đã liên kết email với tài khoản của bạn.';

  @override
  String get whoTitle => 'Bạn là ai với bé?';

  @override
  String whoSubtitle(String label) {
    return 'Cả nhà sẽ thấy “$label ghi” trên từng bản ghi.';
  }

  @override
  String get whoNameLabel => 'Tên của bạn';

  @override
  String get whoNamePlaceholder => 'Ví dụ: Mai';

  @override
  String get whoYouAre => 'Bạn là';

  @override
  String get whoCustomLabel => 'Bạn là ai với bé';

  @override
  String get whoCustomPlaceholder => 'Ví dụ: Dì';

  @override
  String get relationMother => 'Mẹ';

  @override
  String get relationFather => 'Ba';

  @override
  String get relationGrandmother => 'Bà';

  @override
  String get relationGrandfather => 'Ông';

  @override
  String get relationNanny => 'Bảo mẫu';

  @override
  String get relationRelative => 'Họ hàng';

  @override
  String get relationOther => 'Khác…';

  @override
  String get babyNicknameLabel => 'Tên thân mật';

  @override
  String get babyNicknamePlaceholder => 'Tên bé';

  @override
  String get babyDob => 'Ngày sinh';

  @override
  String get babyTimeZone => 'Múi giờ';

  @override
  String get babyGender => 'Giới tính';

  @override
  String get babyOptional => 'không bắt buộc';

  @override
  String get genderGirl => 'Bé gái';

  @override
  String get genderBoy => 'Bé trai';

  @override
  String get genderUnspecified => 'Không nêu';

  @override
  String get babyPrivacyNote => 'Người thân chỉ thấy tên thân mật';

  @override
  String get a11yChangeBabyPhoto => 'Đổi ảnh đại diện';

  @override
  String get babyNicknameRequired => 'Đặt tên thân mật cho bé nhé.';

  @override
  String dobAgeHint(String name, String age) {
    return '$name được $age';
  }

  @override
  String get ageNewborn => 'mới chào đời';

  @override
  String ageDays(int count) {
    return '$count ngày tuổi';
  }

  @override
  String ageWeeks(int count) {
    return '$count tuần tuổi';
  }

  @override
  String ageMonths(int count) {
    return '$count tháng tuổi';
  }

  @override
  String ageYears(int count) {
    return '$count tuổi';
  }

  @override
  String ageShortDays(int count) {
    return '$count ngày';
  }

  @override
  String ageShortWeeks(int count) {
    return '$count tuần';
  }

  @override
  String ageShortMonths(int count) {
    return '$count tháng';
  }

  @override
  String ageShortYears(int count) {
    return '$count tuổi';
  }

  @override
  String get tzSearch => 'Tìm thành phố hoặc quốc gia';

  @override
  String get tzAuto => 'Tự động theo máy';

  @override
  String tzAutoUsing(String offset, String place) {
    return 'Đang dùng $offset · $place';
  }

  @override
  String get tzNoResults => 'Không tìm thấy múi giờ phù hợp.';

  @override
  String get avatarTitle => 'Ảnh đại diện';

  @override
  String get avatarCamera => 'Chụp ảnh';

  @override
  String get avatarLibrary => 'Chọn từ thư viện';

  @override
  String get avatarOrIllustration => 'Hoặc chọn hình minh họa';

  @override
  String get avatarPrivacy => 'Chỉ người trong gia đình xem được ảnh này.';

  @override
  String avatarPreset(int number) {
    return 'Hình minh họa $number';
  }

  @override
  String get avatarCameraDenied =>
      'Child Life chưa được dùng camera. Bạn có thể cho phép trong Cài đặt.';

  @override
  String get avatarLibraryDenied =>
      'Child Life chưa được xem ảnh. Bạn có thể cho phép trong Cài đặt.';

  @override
  String get avatarUploadFailed =>
      'Chưa lưu được ảnh đại diện. Hồ sơ vẫn dùng hình minh họa, bạn thử lại sau nhé.';

  @override
  String get trackersTitle => 'Theo dõi gì?';

  @override
  String get trackersSubtitle => 'Đổi lại lúc nào cũng được.';

  @override
  String get trackerBottle => 'Bú bình';

  @override
  String get trackerBreast => 'Bú mẹ';

  @override
  String get trackerSleep => 'Giấc ngủ';

  @override
  String get trackerDiaper => 'Thay tã';

  @override
  String get trackerPump => 'Hút sữa';

  @override
  String get trackerGrowth => 'Tăng trưởng';

  @override
  String trackersDone(int count) {
    return 'Xong · $count mục';
  }

  @override
  String get trackersPickOne => 'Chọn ít nhất một mục';

  @override
  String get createBabyLimit => 'Mỗi tài khoản tạo được tối đa 3 hồ sơ bé.';

  @override
  String get createBabyFailed =>
      'Chưa tạo được hồ sơ bé. Kiểm tra mạng rồi thử lại nhé.';

  @override
  String get createBabyDobFuture => 'Ngày sinh không thể ở tương lai.';

  @override
  String get appearanceTitle => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeAuto => 'Tự động';

  @override
  String get nightCareTitle => 'Night care';

  @override
  String nightCareScheduled(String start, String end) {
    return 'Theo lịch $start – $end';
  }

  @override
  String get nightCareOff => 'Đang tắt lịch';

  @override
  String get nightCareSchedule => 'Lịch Night care';

  @override
  String get nightCareOn => 'Bật lúc';

  @override
  String get nightCareOffAt => 'Tắt lúc';

  @override
  String get nightCareHint =>
      'Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ.';

  @override
  String get appearanceAppliesNow => 'Áp dụng ngay cho cả app';

  @override
  String nightCareSegmentOn(String time) {
    return 'Bật lúc · $time';
  }

  @override
  String nightCareSegmentOff(String time) {
    return 'Tắt lúc · $time';
  }

  @override
  String get pickerHour => 'Giờ';

  @override
  String get pickerMinute => 'Phút';

  @override
  String nightCareDuration(String duration, String end) {
    return 'Night care trong $duration, đến $end sáng';
  }

  @override
  String durationHours(int n) {
    return '$n giờ';
  }

  @override
  String durationHoursMinutes(int h, int m) {
    return '$h giờ $m phút';
  }

  @override
  String get todayTitle => 'Hôm nay';

  @override
  String get todayTileEmpty => 'Chưa có';

  @override
  String get todayTileTapToLog => 'Chạm để ghi';

  @override
  String get todaySummaryEmpty => 'Chưa có ghi chép hôm nay.';

  @override
  String get todaySummaryEmptyBody =>
      'Ghi khi gia đình cần nhé. Tổng trong ngày sẽ hiện ở đây.';

  @override
  String get todayLoggingSoon => 'Ghi chép chăm sóc sẽ có ở bản tiếp theo.';

  @override
  String babySwitcherLabel(String name, String age) {
    return '$name · $age';
  }

  @override
  String get meAppearance => 'Giao diện';

  @override
  String get meSignOut => 'Đăng xuất';

  @override
  String get ageShortNewborn => 'mới sinh';

  @override
  String get actionContinue => 'Tiếp tục';

  @override
  String get actionCancel => 'Huỷ';

  @override
  String get familyErrorGeneric => 'Chưa làm được. Thử lại nhé.';

  @override
  String get relationFriend => 'Bạn bè';

  @override
  String get roleCoParent => 'Cùng nuôi';

  @override
  String get roleCaregiver => 'Người chăm sóc';

  @override
  String get roleRelative => 'Người thân';

  @override
  String memberDetail(String relation, String role) {
    return '$relation · $role';
  }

  @override
  String get babyPickerTitle => 'Chọn bé';

  @override
  String babyPickerYouAre(String label) {
    return 'Bạn là $label';
  }

  @override
  String babyPickerRowDetail(String age, String youAre) {
    return '$age · $youAre';
  }

  @override
  String get babyPickerAdd => 'Thêm hồ sơ bé';

  @override
  String babyPickerCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String babyPickerLimit(int max) {
    return 'Bạn tạo được tối đa $max hồ sơ bé.';
  }

  @override
  String babySwitched(String name) {
    return 'Đã chuyển sang $name';
  }

  @override
  String get memoriesComingSoon => 'Kỷ niệm sẽ có ở bản tiếp theo.';

  @override
  String get todayViewOnly => 'Bạn được xem chăm sóc hằng ngày, không ghi.';

  @override
  String get unsavedBannerTitle => 'Chưa lưu tài khoản';

  @override
  String get unsavedBannerAction => 'Lưu';

  @override
  String get saveAccountTitle => 'Lưu tài khoản';

  @override
  String saveAccountBody(String baby) {
    return 'Để không mất $baby khi đổi máy hoặc cài lại app.';
  }

  @override
  String get saveAccountDone => 'Đã lưu tài khoản';

  @override
  String get saveAccountMerged => 'Đã gộp vào tài khoản của bạn';

  @override
  String get saveEmailSubtitle =>
      'Tạo tài khoản mới, hoặc đăng nhập tài khoản đã có để gộp vào đó.';

  @override
  String get saveEmailExists =>
      'Email này đã có tài khoản. Đăng nhập để gộp vào đó.';

  @override
  String get signOutAnonTitle => 'Đăng xuất khi chưa lưu?';

  @override
  String get signOutAnonBody =>
      'Tài khoản tạm sẽ mất, và bạn cần lời mời mới để vào lại.';

  @override
  String get signOutAnonConfirm => 'Vẫn đăng xuất';

  @override
  String familySubtitle(String baby) {
    return 'Những người cùng chăm $baby';
  }

  @override
  String get familyYou => 'Bạn';

  @override
  String familyPending(int count) {
    return 'Đang chờ nhận lời ($count)';
  }

  @override
  String familyPendingDetail(String relation, String date) {
    return '$relation · hết hạn $date';
  }

  @override
  String familyPendingExpired(String relation) {
    return '$relation · đã hết hạn';
  }

  @override
  String familyPendingNoEmail(String relation) {
    return 'Lời mời cho $relation';
  }

  @override
  String get familyResend => 'Gửi lại';

  @override
  String familyResent(String email) {
    return 'Đã gửi lại cho $email';
  }

  @override
  String get familyInvite => 'Mời người cùng chăm';

  @override
  String get familyFootnote =>
      'Người được mời chỉ thấy những gì bạn cho phép. Bạn có thể đổi quyền hoặc xoá bất cứ lúc nào.';

  @override
  String get familyLoadFailed => 'Chưa tải được danh sách. Kiểm tra mạng nhé.';

  @override
  String get inviteSubtitle => 'Chọn người đó là ai và được làm gì.';

  @override
  String get inviteRelationLabel => 'Người được mời là';

  @override
  String get inviteRoleLabel => 'Quyền';

  @override
  String get inviteCustomLabel => 'Là ai với bé';

  @override
  String get roleCoParentHint => 'Toàn quyền, như ba mẹ';

  @override
  String get roleCaregiverHint => 'Ghi & xem chăm sóc';

  @override
  String get roleRelativeHint => 'Xem kỷ niệm, chọn thêm quyền xem';

  @override
  String get roleCoParentOwnerOnly => 'Chỉ người tạo hồ sơ mời được Cùng nuôi';

  @override
  String get inviteSeeDetails => 'Xem chi tiết quyền';

  @override
  String get inviteNext => 'Tiếp · Gửi lời mời';

  @override
  String get relativeRightsTitle => 'Quyền của Người thân';

  @override
  String get relativeRightsAlways => 'Luôn có: xem kỷ niệm, thả tim';

  @override
  String get relativeRightsMore => 'Cho xem thêm';

  @override
  String get rightBabyInfo => 'Thông tin bé';

  @override
  String get rightBabyInfoHint => 'Ngày sinh, cân nặng';

  @override
  String get rightDailyCare => 'Chăm sóc hằng ngày';

  @override
  String get rightDailyCareHint => 'Bú, ngủ, tã · chỉ xem';

  @override
  String roleDetailsTitle(String role) {
    return 'Quyền của $role';
  }

  @override
  String get permLogCare => 'Ghi bú, ngủ, tã';

  @override
  String get permViewSchedule => 'Xem lịch';

  @override
  String get permViewReminders => 'Xem nhắc việc';

  @override
  String get permMemories => 'Kỷ niệm';

  @override
  String get permViewMemories => 'Xem kỷ niệm';

  @override
  String get permLove => 'Thả tim';

  @override
  String get permInvite => 'Mời người khác';

  @override
  String get permAddMemories => 'Thêm kỷ niệm';

  @override
  String get permDailyCare => 'Xem bú, ngủ, tã';

  @override
  String inviteSendTitle(String relation) {
    return 'Gửi lời mời cho $relation';
  }

  @override
  String inviteSendSubtitle(String relation) {
    return '$relation mở camera điện thoại và quét mã.';
  }

  @override
  String inviteSendLinkSubtitle(String relation) {
    return 'Gửi link này cho $relation qua tin nhắn.';
  }

  @override
  String inviteSendEmailSubtitle(String relation) {
    return 'Child Life gửi lời mời tới email của $relation.';
  }

  @override
  String get inviteSummaryChange => 'Đổi';

  @override
  String get inviteChannelQr => 'Mã QR';

  @override
  String get inviteChannelLink => 'Link';

  @override
  String get inviteChannelEmail => 'Email';

  @override
  String get inviteOrCode => 'Hoặc nhập mã';

  @override
  String inviteExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Hết hạn sau $days ngày',
    );
    return '$_temp0';
  }

  @override
  String get inviteExpiresToday => 'Hết hạn hôm nay';

  @override
  String get inviteShare => 'Chia sẻ lời mời';

  @override
  String inviteShareText(
    String inviter,
    String baby,
    String link,
    String code,
  ) {
    return '$inviter mời bạn cùng chăm $baby trên Child Life.\nMở link: $link\nHoặc nhập mã trong app: $code';
  }

  @override
  String inviteShareSubject(String baby) {
    return 'Lời mời cùng chăm $baby';
  }

  @override
  String inviteCantScan(String relation) {
    return '$relation không quét được?';
  }

  @override
  String get inviteCopyLink => 'Sao chép link';

  @override
  String get inviteLinkCopied => 'Đã sao chép link';

  @override
  String inviteEmailLabel(String relation) {
    return 'Email của $relation';
  }

  @override
  String get inviteEmailSend => 'Gửi email';

  @override
  String cantScanTitle(String relation) {
    return '$relation không vào được?';
  }

  @override
  String get cantScanStep1 => 'Mở app Child Life, chọn “Mã mời”';

  @override
  String cantScanStep2(String code) {
    return 'Nhập mã $code';
  }

  @override
  String get cantScanStep3 => 'Vẫn lỗi? Tạo mã mới bên dưới';

  @override
  String get cantScanNewCode => 'Tạo mã mới';

  @override
  String get cantScanByEmail => 'Gửi qua email thay thế';

  @override
  String get inviteNewCodeDone => 'Đã tạo mã mới. Mã cũ không dùng được nữa.';

  @override
  String get inviteRevoke => 'Huỷ lời mời';

  @override
  String get inviteRevoked => 'Đã huỷ lời mời';

  @override
  String inviteSentTitle(String relation) {
    return 'Đã gửi email cho $relation';
  }

  @override
  String inviteNotReceived(String relation) {
    return '$relation không nhận được?';
  }

  @override
  String get notReceivedTitle => 'Chưa nhận được email?';

  @override
  String get notReceivedTip1 => 'Xem trong mục Thư rác hoặc Quảng cáo.';

  @override
  String get notReceivedTip2 => 'Email có thể đến sau vài phút.';

  @override
  String get notReceivedTip3 => 'Hoặc chia sẻ link qua tin nhắn.';

  @override
  String get notReceivedResend => 'Gửi lại email';

  @override
  String get inviteErrorUnverified =>
      'Xác minh email của bạn trước khi mời người khác.';

  @override
  String get inviteErrorOwnerOnly =>
      'Chỉ người tạo hồ sơ mới quản lý được Cùng nuôi.';

  @override
  String get inviteErrorTooSoon =>
      'Vừa gửi xong. Đợi một phút rồi gửi lại nhé.';

  @override
  String get inviteErrorTooMany =>
      'Lời mời này đã gửi đủ 5 email. Hãy chia sẻ link thay thế.';

  @override
  String get inviteErrorSuppressed =>
      'Địa chỉ này đã huỷ nhận email từ Child Life.';

  @override
  String get inviteErrorClosed => 'Lời mời này không còn dùng được.';

  @override
  String memberMeta(String relation, String date) {
    return '$relation · tham gia $date';
  }

  @override
  String get roleCoParentHintFull => 'Toàn quyền như ba mẹ';

  @override
  String get roleCaregiverHintFull => 'Ghi & xem chăm sóc, không mời người';

  @override
  String get roleRelativeHintFull => 'Chỉ xem kỷ niệm được chia sẻ';

  @override
  String get memberAccessUntil => 'Thời hạn';

  @override
  String memberAccessUntilValue(String date) {
    return 'Đến $date';
  }

  @override
  String get memberAccessNoLimit => 'Không giới hạn';

  @override
  String memberAccessHint(String name) {
    return '$name xem được đến hết ngày này.';
  }

  @override
  String get memberAccessClear => 'Bỏ giới hạn';

  @override
  String get memberRelation => 'Là ai với bé';

  @override
  String memberRemove(String name) {
    return 'Xoá $name khỏi gia đình';
  }

  @override
  String memberRecordsKept(String name) {
    return 'Bản ghi của $name vẫn được giữ.';
  }

  @override
  String memberRemoveConfirmTitle(String name) {
    return 'Xoá $name?';
  }

  @override
  String memberRemoveConfirmBody(String name, String baby) {
    return '$name sẽ không xem được $baby nữa. Bản ghi của $name vẫn được giữ.';
  }

  @override
  String get memberRemoveConfirm => 'Xoá';

  @override
  String memberRemoved(String name) {
    return 'Đã xoá $name';
  }

  @override
  String get memberUpdated => 'Đã cập nhật';

  @override
  String get joinCodeTitle => 'Nhập mã mời';

  @override
  String get joinCodeSubtitle => '6 số trong lời mời, hoặc quét mã QR.';

  @override
  String get joinScan => 'Quét mã QR';

  @override
  String get joinCodeWrong => 'Mã chưa đúng. Kiểm tra lại 6 số nhé.';

  @override
  String joinLocked(int minutes) {
    return 'Nhập sai nhiều lần. Thử lại sau $minutes phút.';
  }

  @override
  String get a11yInviteCode => 'Mã mời 6 số';

  @override
  String get scanHint => 'Đưa mã QR trong lời mời vào khung.';

  @override
  String get scanNotInvite => 'Đây không phải mã mời Child Life.';

  @override
  String get scanCameraDenied => 'Cho phép camera trong Cài đặt để quét mã.';

  @override
  String joinCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Còn $hours giờ',
    );
    return '$_temp0';
  }

  @override
  String joinInviterTitle(String inviter) {
    return '$inviter mời bạn';
  }

  @override
  String joinRoleLine(String baby) {
    return 'cùng chăm bé $baby với vai trò';
  }

  @override
  String get joinJoin => 'Tham gia';

  @override
  String get joinNotMe => 'Không phải tôi';

  @override
  String joinAlreadyMember(String baby) {
    return 'Bạn đã ở trong gia đình $baby.';
  }

  @override
  String joinHowTitle(String baby) {
    return 'Vào gia đình $baby';
  }

  @override
  String get joinHowBody => 'Không cần tạo tài khoản. Có thể lưu lại sau.';

  @override
  String get joinNow => 'Vào ngay';

  @override
  String get joinOrSave => 'hoặc lưu tài khoản ngay';

  @override
  String joinConfirmTitle(String baby) {
    return 'Bạn là ai với $baby?';
  }

  @override
  String joinConfirmSubtitle(String inviter, String relation) {
    return '$inviter đã chọn “$relation”. Đổi nếu chưa đúng.';
  }

  @override
  String joinConfirmGo(String baby) {
    return 'Vào xem $baby';
  }

  @override
  String get joinExpiredTitle => 'Lời mời đã hết hạn';

  @override
  String get joinExpiredBody => 'Nhờ người mời gửi link mới nhé.';

  @override
  String get joinRevokedTitle => 'Lời mời đã bị huỷ';

  @override
  String get joinRevokedBody => 'Nhờ người mời gửi lời mời mới nhé.';

  @override
  String get joinUsedTitle => 'Lời mời đã được dùng';

  @override
  String get joinUsedBody =>
      'Mỗi lời mời chỉ dùng được một lần. Nhờ người mời gửi lời mời mới nhé.';

  @override
  String get joinNotFoundTitle => 'Không tìm thấy lời mời';

  @override
  String get joinNotFoundBody => 'Kiểm tra lại link, hoặc nhập mã 6 số.';

  @override
  String get joinOtherCode => 'Nhập mã khác';

  @override
  String get joinBackToStart => 'Về trang đầu';

  @override
  String get lostAccessTitle => 'Bạn không còn quyền xem hồ sơ này';

  @override
  String get lostAccessBody =>
      'Quyền của bạn đã thay đổi. Nội dung trên máy này đã được ẩn.';

  @override
  String get lostAccessHome => 'Về trang chính';

  @override
  String get lostAccessRequest => 'Xin lời mời mới';

  @override
  String get lostAccessShareText =>
      'Mình không còn xem được hồ sơ của bé trên Child Life. Bạn gửi mình lời mời mới nhé?';

  @override
  String get agoJustNow => 'Vừa xong';

  @override
  String agoMinutes(int n) {
    return '$n phút trước';
  }

  @override
  String agoHours(int n) {
    return '$n giờ trước';
  }

  @override
  String agoHoursMinutes(int h, int m) {
    return '$h giờ $m phút trước';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ngày trước',
    );
    return '$_temp0';
  }

  @override
  String endedAgo(String ago) {
    return 'Kết thúc $ago';
  }

  @override
  String durationMinutes(int n) {
    return '$n phút';
  }

  @override
  String rhythmSleepValue(int h, int m) {
    return '$h giờ $m';
  }

  @override
  String get careYou => 'Bạn';

  @override
  String careYouSuffix(String name) {
    return '$name (bạn)';
  }

  @override
  String careLoggedBy(String who) {
    return '$who ghi';
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
  String get milkBreast => 'Sữa mẹ';

  @override
  String get milkFormula => 'Sữa công thức';

  @override
  String get sideLeft => 'Trái';

  @override
  String get sideRight => 'Phải';

  @override
  String get sideBoth => 'Cả hai';

  @override
  String get diaperWet => 'Ướt';

  @override
  String get diaperDirty => 'Bẩn';

  @override
  String get diaperWetValue => 'Tã ướt';

  @override
  String get diaperDirtyValue => 'Tã bẩn';

  @override
  String get diaperBothValue => 'Ướt và bẩn';

  @override
  String get carePending => 'Chờ đồng bộ';

  @override
  String get dayRhythmTitle => 'Đã ghi hôm nay';

  @override
  String rhythmFeeds(int count, int ml) {
    return '$count cữ · $ml ml';
  }

  @override
  String rhythmBreast(int count, int minutes) {
    return '$count cữ · $minutes phút';
  }

  @override
  String get rhythmSleepLabel => 'Ngủ (đã xong)';

  @override
  String rhythmDiapers(int count) {
    return '$count lần';
  }

  @override
  String get legendSleep => 'Ngủ';

  @override
  String get legendDiaper => 'Tã';

  @override
  String get todayHistory => 'Lịch sử';

  @override
  String get historySoon => 'Lịch sử chi tiết sẽ có ở bản tiếp theo.';

  @override
  String get sleepSoon => 'Ghi giấc ngủ và hẹn giờ sẽ có ở bản tiếp theo.';

  @override
  String awakeFor(String duration) {
    return 'Đã thức $duration';
  }

  @override
  String growthDeltaToday(String delta, String when) {
    return '$delta · $when';
  }

  @override
  String get dayToday => 'hôm nay';

  @override
  String get dayYesterday => 'hôm qua';

  @override
  String offlineBanner(int count) {
    return 'Đang offline · $count bản ghi chờ đồng bộ';
  }

  @override
  String syncingBanner(int count) {
    return '$count bản ghi chờ đồng bộ';
  }

  @override
  String get pendingTitle => 'Chờ đồng bộ';

  @override
  String get pendingChip => 'Chờ';

  @override
  String get pendingOnlyHere => 'Chỉ lưu trên máy này';

  @override
  String get pendingFootnote =>
      'Tự gửi khi có mạng. Người cùng chăm chưa thấy các bản ghi này.';

  @override
  String get retryNow => 'Thử lại ngay';

  @override
  String get retrySynced => 'Đã đồng bộ';

  @override
  String get retryStill => 'Vẫn chưa gửi được. App sẽ tự gửi khi có mạng.';

  @override
  String get syncPendingLong => 'Đã lưu trên máy này. Đang chờ đồng bộ.';

  @override
  String get quickLogTitle => 'Ghi nhanh';

  @override
  String get quickSleep => 'Ngủ';

  @override
  String get feedSheetTitle => 'Ghi cữ bú';

  @override
  String get amountOptional => 'Lượng sữa · tùy chọn';

  @override
  String get amountLabel => 'Lượng sữa';

  @override
  String get milkTypeLabel => 'Loại sữa';

  @override
  String get timeLabel => 'Thời gian';

  @override
  String get startLabel => 'Bắt đầu';

  @override
  String get sideLabel => 'Bên';

  @override
  String get durationOptional => 'Thời lượng · tùy chọn';

  @override
  String get durationLabel => 'Thời lượng';

  @override
  String get durationNone => 'Chưa nhập';

  @override
  String get saveFeed => 'Lưu cữ bú';

  @override
  String get pumpTitle => 'Ghi hút sữa';

  @override
  String get savePump => 'Lưu hút sữa';

  @override
  String get diaperTitle => 'Thay tã';

  @override
  String get actionSave => 'Lưu';

  @override
  String timeNow(String time) {
    return 'Bây giờ · $time';
  }

  @override
  String timeToday(String time) {
    return 'Hôm nay · $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Hôm qua · $time';
  }

  @override
  String get timePickerTitle => 'Chọn thời gian';

  @override
  String get durationPickerTitle => 'Chọn thời lượng';

  @override
  String savedToast(String what) {
    return 'Đã ghi · $what';
  }

  @override
  String get editedToast => 'Đã lưu thay đổi';

  @override
  String get undo => 'Hoàn tác';

  @override
  String amountRange(String min, String max, String unit) {
    return 'Nhập từ $min đến $max $unit.';
  }

  @override
  String get careSaveFailed =>
      'Chưa lưu được bản ghi. Có thể quyền của bạn đã thay đổi.';

  @override
  String get growthTitle => 'Tăng trưởng';

  @override
  String get growthDate => 'Ngày đo';

  @override
  String get growthWeight => 'Cân nặng';

  @override
  String get growthLengthOptional => 'Chiều dài · tùy chọn';

  @override
  String growthDeltaSince(String delta, String date) {
    return '$delta so với lần đo $date';
  }

  @override
  String get growthPrevious => 'Các lần đo trước';

  @override
  String get growthSeeAll => 'Xem tất cả';

  @override
  String get growthNoPrevious => 'Đây là lần đo đầu tiên.';

  @override
  String get growthAtBirth => 'Lúc sinh';

  @override
  String get saveGrowth => 'Lưu số đo';

  @override
  String get growthWeightRequired => 'Nhập cân nặng từ 0,3 đến 40 kg.';

  @override
  String get growthLengthRange => 'Chiều dài từ 20 đến 150 cm.';

  @override
  String get detailTime => 'Thời gian';

  @override
  String get detailBy => 'Người ghi';

  @override
  String get detailLoggedAt => 'Ghi lúc';

  @override
  String get detailSync => 'Đồng bộ';

  @override
  String get detailAmount => 'Lượng';

  @override
  String get detailMilk => 'Loại sữa';

  @override
  String get detailSide => 'Bên';

  @override
  String get detailDuration => 'Thời lượng';

  @override
  String get detailLength => 'Chiều dài';

  @override
  String get actionEdit => 'Sửa';

  @override
  String get deleteRecord => 'Xóa bản ghi';

  @override
  String get detailFooter =>
      'Mọi người trong gia đình thấy bản ghi này. Người ghi và Cùng nuôi được sửa.';

  @override
  String get deleteConfirmTitle => 'Xóa bản ghi này?';

  @override
  String get deleteConfirmBody =>
      'Bản ghi được giữ 30 ngày trong “Đã xoá gần đây”.';

  @override
  String get deletedToast => 'Đã xóa';

  @override
  String viewOnlyNote(String who) {
    return 'Bản ghi của $who · chỉ xem. Nếu sai, nhắn $who để sửa.';
  }

  @override
  String messageAuthor(String who) {
    return 'Nhắn $who';
  }

  @override
  String get messagesSoon => 'Nhắn tin trong app sẽ có ở bản tiếp theo.';

  @override
  String get recordGone => 'Bản ghi này không còn nữa.';

  @override
  String get unitMinutes => 'phút';

  @override
  String memberMetaCount(String relation, String date, int count) {
    return '$relation · tham gia $date · đã ghi $count lần';
  }
}
