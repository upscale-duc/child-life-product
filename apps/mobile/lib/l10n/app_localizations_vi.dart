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
  String get a11yWorking => 'Đang xử lý';

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
  String get welcomeTitle => 'Cùng con lớn lên,\nđồng hành từng bước.';

  @override
  String get welcomeExplore => 'Bắt đầu chặng đầu cùng con';

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
  String get signInSubtitle => 'Đăng nhập để bắt đầu hành trình cùng con.';

  @override
  String get signInApple => 'Tiếp tục với Apple';

  @override
  String get signInAppleElsewhere => 'Đã đăng ký bằng Apple trên iPhone?';

  @override
  String get signInAppleElsewhereAction =>
      'Nhận link đăng nhập qua email Apple';

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
  String get babyCountry => 'Quốc gia';

  @override
  String get babyCountryUnset => 'Chọn';

  @override
  String get babyCountryRequired =>
      'Chọn nơi gia đình đang sống để Sơ cứu gọi đúng số cấp cứu.';

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

  @override
  String get sleepChooserTitle => 'Ghi giấc ngủ';

  @override
  String sleepChooserPrompt(String baby) {
    return '$baby đang ngủ hay đã ngủ xong rồi?';
  }

  @override
  String get sleepStartTimer => 'Bắt đầu hẹn giờ';

  @override
  String sleepStartTimerHint(String baby) {
    return '$baby vừa ngủ. Đồng hồ chạy, cả nhà cùng thấy';
  }

  @override
  String get sleepManual => 'Nhập giấc đã ngủ';

  @override
  String get sleepManualHint => 'Quên bấm giờ? Chọn giờ bắt đầu và kết thúc';

  @override
  String get sleepChooserFootnote =>
      'Đổi cách bất cứ lúc nào: từ đồng hồ có thể sửa giờ bắt đầu, từ nhập tay có thể chuyển sang hẹn giờ.';

  @override
  String get timerFamilySees => 'Cả nhà đang thấy';

  @override
  String get timerOnlyHere => 'Chỉ trên máy này';

  @override
  String get sleepNotSynced => 'Giấc ngủ này chưa được đồng bộ';

  @override
  String get timerNotSynced => 'Cữ này chưa được đồng bộ';

  @override
  String sleepTimerTitle(String baby) {
    return 'Bé $baby đang ngủ';
  }

  @override
  String timerStartedBy(String who, String time) {
    return '$who bắt đầu lúc $time';
  }

  @override
  String get sleepRingLabel => 'Đang ngủ';

  @override
  String sinceTime(String time) {
    return 'Từ $time';
  }

  @override
  String get endSleep => 'Kết thúc giấc ngủ';

  @override
  String get editStart => 'Sửa giờ bắt đầu';

  @override
  String get cancelNoSave => 'Hủy, không lưu';

  @override
  String get cancelConfirmTitle => 'Hủy và không lưu?';

  @override
  String get cancelConfirmBody => 'Thời gian đã chạy sẽ không được ghi.';

  @override
  String get keepTiming => 'Tiếp tục bấm giờ';

  @override
  String breastTimerTitle(String baby) {
    return '$baby đang bú mẹ';
  }

  @override
  String get totalTime => 'Tổng thời gian';

  @override
  String get sideLeftCaps => 'TRÁI';

  @override
  String get sideRightCaps => 'PHẢI';

  @override
  String get feedingNow => 'Đang bú';

  @override
  String get tapToSwitch => 'Chạm để đổi bên';

  @override
  String get lastEndedLeft => 'Lần trước kết thúc bên trái';

  @override
  String get lastEndedRight => 'Lần trước kết thúc bên phải';

  @override
  String get endFeed => 'Kết thúc cữ bú';

  @override
  String get pauseTimer => 'Tạm dừng';

  @override
  String get resumeTimer => 'Tiếp tục';

  @override
  String get pausedLabel => 'Tạm dừng';

  @override
  String pumpTimerTitle(String who) {
    return '$who đang hút sữa';
  }

  @override
  String pumpStartedFor(String time, String baby) {
    return 'Bắt đầu lúc $time · cho $baby';
  }

  @override
  String get pumpingNow => 'Đang hút';

  @override
  String get pumpStopped => 'Đã dừng';

  @override
  String get tapToStart => 'Chạm để chạy';

  @override
  String get doublePumpHint => 'Hút đôi · chạm 1 bên để dừng riêng';

  @override
  String get pumpDone => 'Xong · nhập lượng sữa';

  @override
  String get timerInstead => 'Bấm giờ thay vì nhập';

  @override
  String timerJoined(String who) {
    return '$who đã bắt đầu đồng hồ này trước. Bạn đang xem cùng.';
  }

  @override
  String wokeAt(String time) {
    return 'Dậy lúc $time';
  }

  @override
  String runningSince(String time, String who) {
    return 'Từ $time · $who';
  }

  @override
  String get manualSleepTitle => 'Nhập giấc ngủ';

  @override
  String get overnight => 'Qua đêm';

  @override
  String get sleepEnd => 'Kết thúc';

  @override
  String overnightNote(String offset) {
    return 'Giấc qua đêm được chia vào tổng của từng ngày theo múi giờ của bé ($offset).';
  }

  @override
  String sleepingNow(String baby) {
    return '$baby đang ngủ?';
  }

  @override
  String get saveSleep => 'Lưu giấc ngủ';

  @override
  String get sleepEndBeforeStart => 'Giờ kết thúc phải sau giờ bắt đầu.';

  @override
  String get sleepTooLong => 'Một giấc dài tối đa 24 giờ.';

  @override
  String get overlapTitle => 'Có hai giấc ngủ trùng nhau';

  @override
  String get overlapBody => 'Chọn bản đúng. App không tự gộp hay ghi đè.';

  @override
  String get backOnline => 'Đã có mạng lại';

  @override
  String get keepSelected => 'Giữ bản đã chọn';

  @override
  String get editMine => 'Sửa tay từ bản của tôi';

  @override
  String get overlapBanner => 'Có hai giấc ngủ trùng nhau · chọn bản đúng';

  @override
  String get overlapKept =>
      'Đã giữ bản đã chọn. Bản kia vào “Đã xoá gần đây” 30 ngày.';

  @override
  String get overlapNotAllowed => 'Bản kia do ba mẹ ghi. Nhờ ba mẹ chọn nhé.';

  @override
  String tourStep(int n) {
    return 'Bước $n/3';
  }

  @override
  String get tour1Title => 'Ghi cữ bú đầu tiên';

  @override
  String get tour1Body =>
      'Chạm thẻ Bú bình để ghi. Các thẻ khác cũng ghi y như vậy.';

  @override
  String tour2Title(String baby) {
    return 'Theo dõi $baby lớn lên';
  }

  @override
  String get tour2Body =>
      'Nhập cân nặng, chiều dài lúc sinh. Mỗi lần đo sau, app tự so với lần trước.';

  @override
  String get tour3Title => 'Ghi nhanh từ mọi nơi';

  @override
  String get tour3Body =>
      'Nút + luôn ở đây, ở mọi tab. Chạm để chọn việc cần ghi.';

  @override
  String get tourStart => 'Bắt đầu';

  @override
  String get historyTitle => 'Lịch sử';

  @override
  String monthChip(int month, String monthName) {
    return 'Tháng $month';
  }

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterFeed => 'Bú';

  @override
  String get filterPump => 'Hút sữa';

  @override
  String get filterSleep => 'Ngủ';

  @override
  String get filterDiaper => 'Tã';

  @override
  String get filterGrowth => 'Tăng trưởng';

  @override
  String get periodNight => 'Đêm';

  @override
  String get periodMorning => 'Sáng';

  @override
  String get periodNoon => 'Trưa';

  @override
  String get periodAfternoon => 'Chiều';

  @override
  String get periodEvening => 'Tối';

  @override
  String periodItems(int count) {
    return '$count mục';
  }

  @override
  String loggedOnDay(String date) {
    return 'Đã ghi ngày $date';
  }

  @override
  String get feedToday => 'Bú hôm nay';

  @override
  String feedOnDay(String date) {
    return 'Bú ngày $date';
  }

  @override
  String get lastFeed => 'Cữ gần nhất';

  @override
  String get averageGap => 'Cách nhau trung bình';

  @override
  String get feedStatsLink => 'Xem thống kê bú';

  @override
  String get feedStatsLinkHint =>
      'Tỉ lệ ngày/đêm · lượng sữa theo giờ · bú mẹ trái/phải';

  @override
  String get sleepToday => 'Ngủ hôm nay';

  @override
  String sleepOnDay(String date) {
    return 'Ngủ ngày $date';
  }

  @override
  String get totalSlept => 'Tổng đã ngủ';

  @override
  String get sleepCount => 'Số giấc';

  @override
  String sleepsValue(int count) {
    return '$count giấc';
  }

  @override
  String get longestSleep => 'Giấc dài nhất';

  @override
  String get awakeNow => 'Đang thức';

  @override
  String awakeSince(String duration, String time) {
    return '$duration · từ $time';
  }

  @override
  String get asleepNow => 'Đang ngủ';

  @override
  String get sleepStatsLink => 'Xem thống kê ngủ';

  @override
  String get sleepStatsLinkHint =>
      'Tỉ lệ ngày/đêm · nhịp ngủ 7 ngày · giấc dài nhất';

  @override
  String get diaperToday => 'Tã hôm nay';

  @override
  String diaperOnDay(String date) {
    return 'Tã ngày $date';
  }

  @override
  String get diaperTotal => 'Tổng';

  @override
  String get diaperLast => 'Gần nhất';

  @override
  String timesValue(int count) {
    return '$count lần';
  }

  @override
  String get pumpToday => 'Hút sữa hôm nay';

  @override
  String pumpOnDay(String date) {
    return 'Hút sữa ngày $date';
  }

  @override
  String get pumpSessions => 'Số lần';

  @override
  String get pumpVolume => 'Lượng sữa';

  @override
  String get pumpNotIntake => 'Sữa hút ra không tính vào lượng bé bú.';

  @override
  String rowBreastSide(String side) {
    return 'Bú mẹ · $side';
  }

  @override
  String get sideBothFull => 'Cả hai bên';

  @override
  String get sideLeftFull => 'Bên trái';

  @override
  String get sideRightFull => 'Bên phải';

  @override
  String rowSleep(String duration) {
    return 'Ngủ $duration';
  }

  @override
  String rowSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String rowYesterdayTime(String time) {
    return '$time hôm qua';
  }

  @override
  String get rowRunning => 'Đang chạy';

  @override
  String growthLatest(String when) {
    return 'Gần nhất · $when';
  }

  @override
  String get growthWeightTab => 'Cân nặng';

  @override
  String get growthLengthTab => 'Chiều dài';

  @override
  String growthDeltaVs(String delta, String date) {
    return '$delta so với $date';
  }

  @override
  String get growthMeasurements => 'Các lần đo';

  @override
  String get growthAdd => 'Thêm số đo';

  @override
  String get growthEmpty => 'Chưa có lần đo nào.';

  @override
  String get emptyFeedWhat => 'cữ bú';

  @override
  String get emptyPumpWhat => 'hút sữa';

  @override
  String get emptySleepWhat => 'giấc ngủ';

  @override
  String get emptyDiaperWhat => 'thay tã';

  @override
  String get emptyAllWhat => 'ghi chép nào';

  @override
  String emptyDayTitle(String what, String date) {
    return 'Chưa ghi $what ngày $date';
  }

  @override
  String emptyTodayTitle(String what) {
    return 'Chưa ghi $what hôm nay';
  }

  @override
  String get emptyDayBody =>
      'Nếu quên ghi lúc đó, bạn có thể ghi bù với giờ của ngày này.';

  @override
  String backLog(String what) {
    return 'Ghi bù $what';
  }

  @override
  String logNow(String what) {
    return 'Ghi $what';
  }

  @override
  String seeAllOnDay(String date) {
    return 'Xem tất cả ghi chép ngày $date';
  }

  @override
  String get pickDateTitle => 'Chọn ngày';

  @override
  String calendarMonth(int month, int year, String monthName) {
    return 'Tháng $month, $year';
  }

  @override
  String calendarFootnote(String baby, String date) {
    return 'Chấm màu = ngày có ghi chép. $baby sinh ngày $date, không chọn được ngày trước đó.';
  }

  @override
  String get calendarFootnoteNoDob => 'Chấm màu = ngày có ghi chép.';

  @override
  String get backToToday => 'Về hôm nay';

  @override
  String get a11yPrevMonth => 'Tháng trước';

  @override
  String get a11yNextMonth => 'Tháng sau';

  @override
  String get feedStatsTitle => 'Thống kê bú';

  @override
  String get sleepStatsTitle => 'Thống kê ngủ';

  @override
  String get windowToday => 'Hôm nay';

  @override
  String get window7 => '7 ngày';

  @override
  String get window30 => '30 ngày';

  @override
  String get perDay => 'TB mỗi ngày';

  @override
  String get gapAverage => 'Cách nhau TB';

  @override
  String get sinceYesterday18 => 'Từ 18h hôm qua';

  @override
  String feedsCount(int count) {
    return '$count cữ';
  }

  @override
  String bottlesBreasts(int bottles, int breasts) {
    return '$bottles bình · $breasts mẹ';
  }

  @override
  String get dayNightFeed => 'Bú ngày và đêm';

  @override
  String dayNightFeedHint(int days) {
    return 'Ngày 06:00–18:00 · Đêm 18:00–06:00 · TB $days ngày';
  }

  @override
  String get nightAndToday => 'Đêm qua và hôm nay';

  @override
  String get nightAndTodayHint => 'Đêm qua 18:00–06:00 · Hôm nay từ 06:00';

  @override
  String get dayLabel => 'Ngày';

  @override
  String get nightLabel => 'Đêm';

  @override
  String get todayLabel => 'Hôm nay';

  @override
  String get lastNightLabel => 'Đêm qua';

  @override
  String mlAndFeeds(int ml, int count) {
    return '$ml ml · $count cữ';
  }

  @override
  String lastNightInsight(int count, String gap, String from, String to) {
    return 'Đêm qua bú $count cữ, khoảng nghỉ dài nhất $gap ($from–$to).';
  }

  @override
  String lastNightGapInsight(String gap, String from, String to) {
    return 'Khoảng nghỉ dài nhất đêm qua: $gap ($from–$to).';
  }

  @override
  String get milkByHour => 'Lượng sữa theo giờ';

  @override
  String milkByHourHint(int days) {
    return 'Bú bình · trung bình $days ngày (ml)';
  }

  @override
  String peakCallout(int hour, int ml) {
    return '${hour}h · $ml ml';
  }

  @override
  String get mlPerHour => 'ml mỗi giờ';

  @override
  String get nightWindow => 'Khung đêm';

  @override
  String get eachFeedToday => 'Từng cữ hôm nay';

  @override
  String get eachFeedHint =>
      'Mỗi cột là một cữ bú bình (ml) · chấm hồng là bú mẹ';

  @override
  String get notYet => 'Chưa tới';

  @override
  String get nowLabel => 'Bây giờ';

  @override
  String get bottleMlLegend => 'Bú bình (ml)';

  @override
  String get nightOrNotYet => 'Đêm / chưa tới';

  @override
  String get breastCard => 'Bú mẹ';

  @override
  String averageDays(int days) {
    return 'TB $days ngày';
  }

  @override
  String get perDayShort => 'mỗi ngày';

  @override
  String get perFeed => 'mỗi cữ';

  @override
  String get todayShort => 'hôm nay';

  @override
  String leftShare(int pct) {
    return 'Bên trái $pct%';
  }

  @override
  String rightShare(int pct) {
    return 'Bên phải $pct%';
  }

  @override
  String leftMinutes(int minutes) {
    return 'Trái $minutes phút';
  }

  @override
  String rightMinutes(int minutes) {
    return 'Phải $minutes phút';
  }

  @override
  String get nextSideLeft =>
      'Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái.';

  @override
  String get nextSideRight =>
      'Lần trước kết thúc bên trái → lần tới nên bắt đầu bên phải.';

  @override
  String get dayNightSleep => 'Ngủ ngày và đêm';

  @override
  String dayNightSleepHint(int days) {
    return 'Đêm 18:00–06:00 · Ngày 06:00–18:00 · TB $days ngày';
  }

  @override
  String durationAndSleeps(String duration, String range) {
    return '$duration · $range giấc';
  }

  @override
  String nightLongestInsight(int days, String from, String to) {
    return 'Giấc đêm dài nhất tăng từ $from lên $to trong $days ngày.';
  }

  @override
  String nightLongestSame(String duration) {
    return 'Giấc đêm dài nhất: $duration.';
  }

  @override
  String sleepRhythm(int days) {
    return 'Nhịp ngủ $days ngày';
  }

  @override
  String get sleepRhythmToday => 'Nhịp ngủ hôm nay';

  @override
  String get sleepRhythmHint => 'Mỗi hàng là một ngày · thanh tím là lúc ngủ';

  @override
  String get longestEachDay => 'Giấc dài nhất mỗi ngày';

  @override
  String get longestEachDayHint => 'Giờ ngủ liền một mạch';

  @override
  String get legendSleepShort => 'Ngủ';

  @override
  String get statsEmpty => 'Chưa đủ dữ liệu trong khoảng này.';

  @override
  String compactHM(int h, int m) {
    return '${h}g ${m}p';
  }

  @override
  String compactH(int h) {
    return '${h}g';
  }

  @override
  String compactHMShort(int h, String m) {
    return '${h}g$m';
  }

  @override
  String durationAndSleep(String duration, int count) {
    return '$duration · $count giấc';
  }

  @override
  String get dayNightSleepTodayHint =>
      'Hôm nay · Đêm 00:00–06:00 · Ngày 06:00–18:00';

  @override
  String get historyCaregiverNote =>
      'Bạn sửa được bản ghi của mình. Bản ghi của ba mẹ chỉ xem.';

  @override
  String get remindersTitle => 'Nhắc nhở';

  @override
  String get remindersOverdue => 'Quá hạn';

  @override
  String get remindersUpcoming => 'Sắp tới';

  @override
  String get remindersDone => 'Đã xong';

  @override
  String get remindersInfo =>
      'Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.';

  @override
  String get reminderNew => 'Nhắc việc mới';

  @override
  String reminderCreatedBy(String who) {
    return '$who tạo';
  }

  @override
  String reminderOverdueMeta(String when) {
    return 'Quá hạn · $when';
  }

  @override
  String reminderDoneMeta(String who, String date) {
    return '$who đánh dấu xong · $date';
  }

  @override
  String get dayTomorrow => 'ngày mai';

  @override
  String get remindersEmpty => 'Chưa có nhắc việc';

  @override
  String get remindersEmptyBody =>
      'Ghi lịch tiêm, tái khám hay việc cần mua để cả nhà cùng thấy.';

  @override
  String get remindersCaregiverNote =>
      'Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong.';

  @override
  String get remindersNotifOff =>
      'Đã lưu nhắc việc. Chưa bật thông báo trên máy này.';

  @override
  String get remindersOpenSettings => 'Cài đặt';

  @override
  String get reminderSaved => 'Đã lưu nhắc việc';

  @override
  String get reminderMarkedDone => 'Đã đánh dấu xong';

  @override
  String get reminderMarkedUndone => 'Đã đánh dấu chưa xong';

  @override
  String get reminderDeleted => 'Đã xoá nhắc việc';

  @override
  String get reminderMoved => 'Thông báo sẽ đến trên máy này';

  @override
  String get reminderEditTitle => 'Sửa nhắc việc';

  @override
  String get reminderWhat => 'Việc cần nhớ';

  @override
  String get reminderWhatHint => 'Ví dụ: Tiêm 6 trong 1';

  @override
  String get reminderWhen => 'Ngày giờ';

  @override
  String get reminderLead => 'Báo trước';

  @override
  String reminderFootnote(String name, String zone) {
    return 'Theo giờ của $name ($zone). Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.';
  }

  @override
  String get reminderSave => 'Lưu nhắc việc';

  @override
  String get reminderTitleRequired => 'Nhập việc cần nhớ.';

  @override
  String get reminderPastTime => 'Chọn thời điểm sau bây giờ.';

  @override
  String get leadOnTime => 'Đúng giờ';

  @override
  String get leadOneDay => '1 ngày';

  @override
  String leadBefore(String lead) {
    return '$lead trước';
  }

  @override
  String get reminderDelete => 'Xoá nhắc việc';

  @override
  String get reminderDeleteTitle => 'Xoá nhắc việc này?';

  @override
  String get reminderDeleteBody => 'Cả nhà sẽ không thấy nhắc việc này nữa.';

  @override
  String get notifPromptTitle => 'Bật thông báo trên máy này?';

  @override
  String get notifPromptBody =>
      'Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.';

  @override
  String get notifPromptAllow => 'Bật thông báo';

  @override
  String reminderOverline(String name) {
    return 'Nhắc việc · $name';
  }

  @override
  String get reminderTimeZone => 'Múi giờ';

  @override
  String get reminderNotify => 'Thông báo';

  @override
  String reminderDeviceOf(String device, String name) {
    return '$device của $name';
  }

  @override
  String get reminderNoDevice => 'Chưa đặt trên máy nào';

  @override
  String get reminderCreator => 'Người tạo';

  @override
  String get reminderDoneRow => 'Đã xong';

  @override
  String get reminderDetailNote =>
      'Thông báo chỉ được đặt trên máy tạo nhắc việc. Đánh dấu xong khi đã làm.';

  @override
  String get reminderMarkDone => 'Đánh dấu đã xong';

  @override
  String get reminderUndo => 'Đánh dấu chưa xong';

  @override
  String get reminderAllDay => 'Cả ngày';

  @override
  String get reminderAllDayLower => 'cả ngày';

  @override
  String get reminderDay => 'Ngày';

  @override
  String get reminderAllDayAt => 'Giờ báo';

  @override
  String get reminderAllDayTimeTitle => 'Giờ nhắc việc cả ngày';

  @override
  String reminderAllDayTimeNote(String name) {
    return 'Áp dụng cho mọi nhắc việc cả ngày báo trên máy này, theo giờ của $name.';
  }

  @override
  String get leadOnDay => 'Đúng ngày';

  @override
  String get reminderAssignee => 'Giao cho';

  @override
  String get reminderAssignNone => 'Chưa giao';

  @override
  String get reminderAssignNobody => 'Không giao ai';

  @override
  String get reminderAssignPickerNote =>
      'Người được giao nhận thông báo trên máy của họ khi mở app. Chỉ Cùng nuôi và người chăm sóc được giao.';

  @override
  String get reminderAssignedToYou => 'Giao cho bạn';

  @override
  String reminderAssignedTo(String name) {
    return 'Giao cho $name';
  }

  @override
  String get reminderNotifyMine => 'Các máy của bạn';

  @override
  String reminderNotifyAssignee(String name) {
    return 'Các máy của $name';
  }

  @override
  String reminderFootnoteAssigned(String name, String zone, String who) {
    return 'Theo giờ của $name ($zone). Gia đình thấy nhắc việc trong app. $who nhận thông báo trên máy của mình khi mở app.';
  }

  @override
  String get reminderDetailNoteAssigned =>
      'Người được giao nhận thông báo trên máy của mình khi mở app. Đánh dấu xong khi đã làm.';

  @override
  String get reminderPastDay => 'Chọn hôm nay hoặc một ngày sau.';

  @override
  String get moveNotifTitle => 'Nhận thông báo trên máy này?';

  @override
  String moveNotifBody(String device) {
    return 'Thông báo của nhắc việc này sẽ chuyển sang $device. Máy đang giữ thông báo sẽ không báo nữa.';
  }

  @override
  String get moveNotifAction => 'Chuyển sang máy này';

  @override
  String reminderPeekLabel(int count) {
    return 'Nhắc việc · $count';
  }

  @override
  String reminderInDays(int count) {
    return 'còn $count ngày';
  }

  @override
  String reminderInDuration(String duration) {
    return 'còn $duration';
  }

  @override
  String get reminderPeekEmpty => 'Chưa có nhắc việc sắp tới';

  @override
  String get reminderPeekAdd => 'Tạo nhắc việc';

  @override
  String get reminderPeekMore => 'Xem tất cả';

  @override
  String notifBody(String name, String when) {
    return '$name · $when';
  }

  @override
  String get notifChannel => 'Nhắc việc';

  @override
  String get notifChannelDescription => 'Nhắc việc của gia đình';

  @override
  String get notifChannelFamily => 'Gia đình & kỷ niệm';

  @override
  String get notifChannelFamilyDescription =>
      'Ảnh mới, lời nhắn và tin từ gia đình';

  @override
  String get notifChannelSpending => 'Chi tiêu';

  @override
  String get notifChannelSpendingDescription =>
      'Khoản chi định kỳ và ngân sách tháng';

  @override
  String get notifSnooze15 => 'Báo lại sau 15 phút';

  @override
  String get notifVxView => 'Xem lịch tiêm';

  @override
  String get notifVxSnooze => 'Nhắc lại sáng mai';

  @override
  String get notifChannelTimers => 'Bộ đếm giờ';

  @override
  String get notifChannelTimersDescription => 'Giấc ngủ và cữ bú đang chạy';

  @override
  String get notifChannelUploads => 'Tải lên';

  @override
  String get notifChannelUploadsDescription =>
      'Tiến độ tải ảnh, video và báo khi xong';

  @override
  String a11yMarkDone(String title) {
    return 'Đánh dấu xong: $title';
  }

  @override
  String a11yUndoDone(String title) {
    return 'Bỏ đánh dấu xong: $title';
  }

  @override
  String get memJournal => 'Nhật ký';

  @override
  String get memPhotos => 'Ảnh';

  @override
  String get memAlbums => 'Album';

  @override
  String get memStories => 'Câu chuyện';

  @override
  String get memSoonTitle => 'Sắp có';

  @override
  String get memSoonBody => 'Phần này có trong bản cập nhật tới.';

  @override
  String get a11yViewOptions => 'Cách xem';

  @override
  String get a11yAddMemory => 'Thêm vào Kỷ niệm';

  @override
  String memWeek(int week) {
    return 'Tuần thứ $week';
  }

  @override
  String get memBeforeBirth => 'Trước ngày chào đời';

  @override
  String memPhotoCount(int count) {
    return '$count ảnh';
  }

  @override
  String memVideoCount(int count) {
    return '$count video';
  }

  @override
  String memItemCount(int count) {
    return '$count mục';
  }

  @override
  String memTodayAt(String time) {
    return 'Hôm nay · $time';
  }

  @override
  String memYesterdayAt(String time) {
    return 'Hôm qua · $time';
  }

  @override
  String get memEmptyTitle => 'Chưa có kỷ niệm nào';

  @override
  String memEmptyBody(String name) {
    return 'Chạm + để thêm ảnh, video hoặc ghi chú đầu tiên của $name.';
  }

  @override
  String memPhotosEmpty(String name) {
    return 'Ảnh và video của $name sẽ hiện ở đây.';
  }

  @override
  String memLanding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang thêm $count mục…',
    );
    return '$_temp0';
  }

  @override
  String get memNoMatch => 'Không có mục nào khớp cách xem này.';

  @override
  String get memProcessing => 'Đang xử lý';

  @override
  String upUploading(int done, int total) {
    return 'Đang tải $done/$total mục';
  }

  @override
  String get upUploadingHint => 'Cứ làm việc khác, xong sẽ báo bạn';

  @override
  String get upPaused => 'Tạm dừng · chờ mạng';

  @override
  String get upPausedHint => 'Tự tải tiếp khi có mạng';

  @override
  String get upPausedByYou => 'Đã tạm dừng';

  @override
  String get upPausedByYouHint => 'Chạm để tiếp tục';

  @override
  String upFailed(int count) {
    return '$count mục chưa tải được';
  }

  @override
  String get upFailedHint => 'Chạm để thử lại hoặc bỏ qua';

  @override
  String upDone(int count) {
    return 'Đã tải xong $count mục';
  }

  @override
  String upToldFamily(String names) {
    return 'Đã báo cho $names';
  }

  @override
  String get upParentsOnly => 'Chỉ ba mẹ xem được';

  @override
  String upWaitingWifi(int count) {
    return '$count video chờ Wi-Fi';
  }

  @override
  String get upWaitingWifiHint => 'Video tự tải khi có Wi-Fi';

  @override
  String upWaitingQuota(int count) {
    return 'Hết dung lượng · $count mục giữ trên máy';
  }

  @override
  String get upWaitingQuotaHint => 'Chạm để xem';

  @override
  String upPreparing(int count) {
    return 'Đang chuẩn bị $count mục';
  }

  @override
  String get addTitle => 'Thêm vào Kỷ niệm';

  @override
  String get addRecent => 'Ảnh mới chụp hôm nay';

  @override
  String get addRecentHint => 'Chạm để chọn';

  @override
  String addRecentCount(int count) {
    return 'Đã chọn $count';
  }

  @override
  String addRecentAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count mục',
    );
    return '$_temp0';
  }

  @override
  String get addCamera => 'Chụp ảnh hoặc quay video';

  @override
  String get addCameraPhoto => 'Chụp ảnh';

  @override
  String get addCameraVideo => 'Quay video';

  @override
  String get addCameraHint => 'Lưu thẳng vào Kỷ niệm';

  @override
  String get addLibrary => 'Chọn từ Thư viện ảnh';

  @override
  String get addLibraryHint => 'Chọn nhiều ảnh, video một lần';

  @override
  String get addFiles => 'Chọn từ Tệp';

  @override
  String get addFilesHint => 'iCloud Drive, Google Drive, USB…';

  @override
  String get addNote => 'Viết ghi chú';

  @override
  String get addNoteHint => 'Kỷ niệm chỉ có chữ, thêm ảnh sau';

  @override
  String get pickRecent => 'Gần đây';

  @override
  String get pickVideos => 'Video';

  @override
  String get pickAlbums => 'Album';

  @override
  String pickSummary(int count, int photos, int videos) {
    return '$count mục · $photos ảnh, $videos video';
  }

  @override
  String pickMax(int count) {
    return 'Tối đa $count mục/lần';
  }

  @override
  String pickAdd(int count) {
    return 'Thêm $count mục';
  }

  @override
  String pickLimit(int count) {
    return 'Mỗi lần thêm tối đa $count mục.';
  }

  @override
  String get pickNoAccess => 'Child Life chưa được xem thư viện ảnh.';

  @override
  String get pickLimited => 'Bạn đang cho xem một số ảnh.';

  @override
  String get pickChooseMore => 'Chọn thêm';

  @override
  String get pickEmpty => 'Chưa có ảnh nào ở đây';

  @override
  String get pickAlbumsTitle => 'Chọn album';

  @override
  String get pickConfirm => 'Thêm';

  @override
  String pickVideoTooLong(String limit) {
    return 'Chưa thêm được video dài hơn $limit.';
  }

  @override
  String pickVideoTooBig(String size) {
    return 'Chưa thêm được video lớn hơn $size.';
  }

  @override
  String get pickPreparing => 'Đang chuẩn bị ảnh và video…';

  @override
  String get composeCaption => 'Viết vài dòng… (không bắt buộc)';

  @override
  String get composeNoteHint => 'Viết điều bạn muốn nhớ…';

  @override
  String get composeDate => 'Ngày';

  @override
  String get composeByCapture => 'Theo ngày chụp';

  @override
  String get composeMilestone => 'Mốc';

  @override
  String get composeNoMilestone => 'Không gắn mốc';

  @override
  String get composeWho => 'Ai thấy';

  @override
  String get audParents => 'Chỉ ba mẹ';

  @override
  String get audParentsHint => 'Chỉ ba mẹ xem được';

  @override
  String get audFamily => 'Gia đình';

  @override
  String get audFamilyHint => 'Cả nhà cùng xem';

  @override
  String get composeNotify => 'Báo cho gia đình';

  @override
  String get composeNotifyHint => 'Gia đình nhận 1 thông báo';

  @override
  String composeUpload(int count) {
    return 'Tải lên $count mục';
  }

  @override
  String get composeSaveNote => 'Lưu ghi chú';

  @override
  String get composeFootnote => 'Ảnh tải ở nền — xong sẽ báo bạn.';

  @override
  String get composeNoteRequired => 'Viết vài chữ cho ghi chú.';

  @override
  String get composeNoteSaved => 'Đã lưu ghi chú';

  @override
  String composeMore(int count) {
    return '+$count';
  }

  @override
  String get dateTitle => 'Ngày của kỷ niệm';

  @override
  String dateByCaptureHint(String range) {
    return 'Mỗi ảnh giữ ngày riêng · $range';
  }

  @override
  String get dateOneForAll => 'Một ngày cho tất cả';

  @override
  String get dateOneForAllHint => 'Dùng khi ngày chụp bị sai';

  @override
  String dateBeforeBirth(String name) {
    return 'Không chọn được ngày trước khi $name chào đời.';
  }

  @override
  String get msTitle => 'Gắn mốc';

  @override
  String get msSearch => 'Tìm hoặc gõ mốc mới…';

  @override
  String msSuggest(String age) {
    return 'Gợi ý cho bé $age';
  }

  @override
  String get msOwn => 'Mốc nhà mình đã tạo';

  @override
  String get msCreate => 'Tạo mốc mới';

  @override
  String get msOnePer => 'Mỗi kỷ niệm 1 mốc';

  @override
  String get msName => 'Tên mốc';

  @override
  String get msPreview => 'Xem trước';

  @override
  String get msShared => 'Mốc mới được lưu cho cả nhà dùng lại lần sau.';

  @override
  String get msCreateTag => 'Tạo & gắn mốc';

  @override
  String get msNameRequired => 'Đặt tên cho mốc.';

  @override
  String msChip(String name, String date) {
    return '$name · $date';
  }

  @override
  String get msFirstSmile => 'Lần đầu cười';

  @override
  String get msFirstBath => 'Lần đầu tắm';

  @override
  String get msLiftsHead => 'Ngẩng đầu';

  @override
  String get msFirstOuting => 'Lần đầu đi dạo';

  @override
  String get msOneMonth => 'Đầy tháng';

  @override
  String get msMeetsGrandparents => 'Lần đầu gặp ông bà';

  @override
  String get msRollsOver => 'Lần đầu lật người';

  @override
  String get msLaughs => 'Cười thành tiếng';

  @override
  String get msFirstSolids => 'Lần đầu ăn dặm';

  @override
  String get msSitsUp => 'Tự ngồi';

  @override
  String get msFirstTooth => 'Chiếc răng đầu tiên';

  @override
  String get msCrawls => 'Biết bò';

  @override
  String get msFirstWord => 'Tiếng nói đầu tiên';

  @override
  String get msFirstSteps => 'Bước đi đầu tiên';

  @override
  String get msFirstBirthday => 'Thôi nôi';

  @override
  String get qTitle => 'Đang tải lên';

  @override
  String qSummary(int done, int total, String time) {
    return '$done/$total mục · còn khoảng $time';
  }

  @override
  String qSummaryNoEta(int done, int total) {
    return '$done/$total mục';
  }

  @override
  String get qPause => 'Tạm dừng';

  @override
  String get qResume => 'Tiếp tục';

  @override
  String get qNotice => 'Gia đình sẽ được báo khi tải xong';

  @override
  String qFailed(int count) {
    return '$count mục lỗi';
  }

  @override
  String qUnreadable(int count) {
    return '$count tệp không đọc được';
  }

  @override
  String rowProgress(int percent, String sent, String total) {
    return '$percent% · $sent/$total';
  }

  @override
  String rowWaitingWifi(String size) {
    return 'Chờ Wi-Fi · video $size';
  }

  @override
  String get rowFailed => 'Mất kết nối khi đang tải';

  @override
  String get rowUnreadable => 'Tệp bị lỗi · không thử lại được';

  @override
  String get rowDone => 'Đã tải lên';

  @override
  String get rowQueued => 'Đang chờ';

  @override
  String get rowPaused => 'Tạm dừng';

  @override
  String get rowWaitingQuota => 'Hết dung lượng · giữ trên máy';

  @override
  String get rowCancelled => 'Đã huỷ';

  @override
  String get rowPreparing => 'Đang chuẩn bị';

  @override
  String get qWifiOnly => 'Video chỉ tải qua Wi-Fi';

  @override
  String get qWifiOnlyHint => 'Ảnh vẫn tải bằng dữ liệu di động';

  @override
  String qRetryAll(int count) {
    return 'Thử lại tất cả ($count)';
  }

  @override
  String get qFootnote => 'Mục lỗi được giữ trên máy · tự thử lại khi có mạng.';

  @override
  String get qEmpty => 'Không còn gì đang tải.';

  @override
  String a11yCancelUpload(String name) {
    return 'Huỷ tải $name';
  }

  @override
  String memMonth(int month, int year, String monthName) {
    return 'Tháng $month, $year';
  }

  @override
  String get memFilterMonth => 'Tháng';

  @override
  String get memSelect => 'Chọn';

  @override
  String get memSelectMonth => 'Chọn cả tháng';

  @override
  String memSelected(int count) {
    return '$count mục đã chọn';
  }

  @override
  String get a11yShareOptions => 'Chia sẻ và tuỳ chọn';

  @override
  String get a11yDeleteSelected => 'Xoá mục đã chọn';

  @override
  String get actWho => 'Ai thấy';

  @override
  String get actAlbum => 'Album';

  @override
  String get actDownload => 'Tải về';

  @override
  String get actSend => 'Gửi đi';

  @override
  String get actMore => 'Thêm';

  @override
  String get actFavorite => 'Thêm vào Yêu thích';

  @override
  String get actFavoriteHint => 'Gom vào album Yêu thích của bạn';

  @override
  String get actMilestoneHint => 'Ví dụ: Lần đầu cười';

  @override
  String get actDate => 'Đổi ngày';

  @override
  String get actDateHint => 'Khi ngày chụp bị sai';

  @override
  String get actMakeCard => 'Tạo thiệp cột mốc';

  @override
  String get actMakeCardHint => 'Dùng tối đa 4 ảnh đã chọn';

  @override
  String get actMakeVideo => 'Tạo video kỷ niệm';

  @override
  String get actMakeVideoHint => 'Ảnh đã chọn vào sẵn các cảnh';

  @override
  String get actStory => 'Kể thành câu chuyện';

  @override
  String actStoryHint(int count) {
    return 'Dùng $count mục này làm bản nháp';
  }

  @override
  String get actCover => 'Đặt làm ảnh bìa album';

  @override
  String get actCoverHint => 'Chỉ dùng khi chọn 1 ảnh';

  @override
  String get actSoon => 'Sắp có';

  @override
  String whoItemsTitle(int count) {
    return 'Ai thấy $count mục này?';
  }

  @override
  String toastSaved(int count) {
    return 'Đã lưu $count mục vào Ảnh';
  }

  @override
  String get toastSaving => 'Đang lưu vào Ảnh…';

  @override
  String get toastSaveFailed => 'Chưa lưu được vào Ảnh. Thử lại nhé.';

  @override
  String toastDateChanged(int count) {
    return 'Đã đổi ngày $count mục';
  }

  @override
  String toastTagged(int count) {
    return 'Đã gắn mốc cho $count mục';
  }

  @override
  String toastParentsOnly(int count) {
    return 'Đã chuyển $count mục sang Chỉ ba mẹ';
  }

  @override
  String toastShared(int count) {
    return 'Đã chia sẻ $count mục với gia đình';
  }

  @override
  String toastDeleted(int count) {
    return 'Đã xoá $count mục';
  }

  @override
  String get toastActionFailed => 'Chưa làm được. Kiểm tra mạng và thử lại.';

  @override
  String delTitle(int count) {
    return 'Xoá $count mục?';
  }

  @override
  String get delBody =>
      'Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình. Ảnh gốc trên máy bạn vẫn còn.';

  @override
  String get delRecover => 'Khôi phục được trong 30 ngày ở “Đã xoá gần đây”.';

  @override
  String get delParentsOnly => 'Chỉ ba mẹ mới xoá được.';

  @override
  String delN(int count) {
    return 'Xoá $count mục';
  }

  @override
  String get gotoTitle => 'Đi tới tháng';

  @override
  String gotoMonthShort(int month, String monthName) {
    return 'Th $month';
  }

  @override
  String gotoNote(String name, String date) {
    return '$name sinh ngày $date · năm khác sẽ hiện khi có ảnh';
  }

  @override
  String scrubberMonth(int month, int year, String monthName) {
    return 'Th $month, $year';
  }

  @override
  String get viewTitle => 'Cách xem';

  @override
  String get viewGroup => 'Nhóm theo';

  @override
  String get viewDay => 'Ngày';

  @override
  String get viewWeek => 'Tuần';

  @override
  String get viewMonth => 'Tháng';

  @override
  String get viewLayout => 'Kiểu xem';

  @override
  String get viewSmall => 'Lưới nhỏ';

  @override
  String get viewLarge => 'Lưới lớn';

  @override
  String get viewList => 'Danh sách';

  @override
  String get viewShow => 'Hiện';

  @override
  String get viewWithMilestone => 'Có mốc';

  @override
  String get viewAsRelative => 'Xem như người thân';

  @override
  String get viewAsRelativeHint => 'Kiểm tra người thân đang thấy những gì';

  @override
  String get viewApply => 'Áp dụng';

  @override
  String get viewAsRelativeBanner => 'Đang xem như người thân';

  @override
  String get viewAsRelativeExit => 'Thoát';

  @override
  String dayGroup(String date, String counts) {
    return '$date · $counts';
  }

  @override
  String viewerPosted(String date, String who) {
    return '$date · $who đăng';
  }

  @override
  String get viewerShare => 'Chia sẻ';

  @override
  String get viewerVideoLoading => 'Đang tải video…';

  @override
  String get viewerVideoFailed => 'Chưa mở được video.';

  @override
  String get a11yPlay => 'Phát video';

  @override
  String get a11yPause => 'Tạm dừng video';

  @override
  String get viewerSeek => 'Vị trí video';

  @override
  String get viewerToggleChrome => 'hiện hoặc ẩn điều khiển';

  @override
  String viewerThumb(int index, int count) {
    return 'Mục $index trên $count';
  }

  @override
  String get shareTitle => 'Chia sẻ với gia đình?';

  @override
  String sharePrivatePhotos(int count) {
    return '$count ảnh riêng tư';
  }

  @override
  String sharePrivateItems(int count) {
    return '$count mục riêng tư';
  }

  @override
  String get shareWillSee => 'Sẽ thấy sau khi chia sẻ';

  @override
  String shareRelatives(int count) {
    return '$count người thân';
  }

  @override
  String shareCaregivers(String names) {
    return 'Người chăm ($names) không thấy Kỷ niệm.';
  }

  @override
  String get shareNotifyHint => 'Gửi 1 thông báo chung, không kèm ảnh';

  @override
  String shareN(int count) {
    return 'Chia sẻ $count mục';
  }

  @override
  String shareNPhotos(int count) {
    return 'Chia sẻ $count ảnh';
  }

  @override
  String camDest(String name) {
    return 'Lưu vào Kỷ niệm của $name';
  }

  @override
  String get camFlash => 'Flash';

  @override
  String get camVideo => 'VIDEO';

  @override
  String get camPhoto => 'ẢNH';

  @override
  String camDone(int count) {
    return 'Xong ($count)';
  }

  @override
  String get camHint => 'Chụp liên tục · bấm Xong để soạn & chia sẻ';

  @override
  String get camUnavailable => 'Máy này chưa mở được camera.';

  @override
  String get a11yShutter => 'Chụp';

  @override
  String albCount(int count) {
    return '$count album';
  }

  @override
  String get albNew => 'Album mới';

  @override
  String get albFavorites => 'Yêu thích';

  @override
  String get albFavoritesMine => 'của riêng bạn';

  @override
  String get albOnlyYou => 'Chỉ mình bạn';

  @override
  String get albFavoritesHint => 'ảnh bạn đã đánh dấu';

  @override
  String get albFromMilestones => 'Gom từ mốc bạn đã gắn';

  @override
  String get albByMilestone => 'Gom theo mốc';

  @override
  String albShared(int count) {
    return '$count album ba mẹ chia sẻ';
  }

  @override
  String get albEmpty => 'Chưa có album nào';

  @override
  String get albEmptyBody =>
      'Tạo album để gom ảnh theo chủ đề, như Giờ tắm hay Bàn tay nhỏ.';

  @override
  String albUpdated(String counts, String when) {
    return '$counts · cập nhật $when';
  }

  @override
  String get albAddPhotos => 'Thêm ảnh';

  @override
  String get albStory => 'Kể thành chuyện';

  @override
  String albSharedBy(String who) {
    return '$who chia sẻ với gia đình';
  }

  @override
  String get albNoItems => 'Album này chưa có ảnh nào.';

  @override
  String get albCoverEmptyMeta => 'Chưa có ảnh';

  @override
  String get albCoverAdd => 'Thêm ảnh';

  @override
  String get albWhoButton => 'Ai thấy album này';

  @override
  String get albRename => 'Đổi tên album';

  @override
  String get albCover => 'Đổi ảnh bìa';

  @override
  String get albWhoFamilyHint => 'Mọi người thân trong gia đình';

  @override
  String get albSelect => 'Chọn ảnh';

  @override
  String get albSelectHint => 'Bỏ khỏi album, đổi ai thấy…';

  @override
  String get albSort => 'Sắp xếp';

  @override
  String get albDownload => 'Tải cả album về máy';

  @override
  String albDownloadHint(String counts, String size) {
    return '$counts · khoảng $size';
  }

  @override
  String get albDelete => 'Xoá album';

  @override
  String get albDeleteHint => 'Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm';

  @override
  String get albName => 'Tên album';

  @override
  String get albSuggestions => 'Gợi ý';

  @override
  String get albSuggestBath => 'Giờ tắm';

  @override
  String get albSuggestSun => 'Tắm nắng';

  @override
  String get albSuggestSwim => 'Lần đầu đi bơi';

  @override
  String get albSuggestHands => 'Bàn tay nhỏ';

  @override
  String get albSuggestSleep => 'Ngủ ngoan';

  @override
  String get albSaveName => 'Lưu tên';

  @override
  String get albNameRequired => 'Đặt tên cho album.';

  @override
  String get albCreate => 'Tạo album';

  @override
  String albCreated(String name) {
    return 'Đã tạo album “$name”';
  }

  @override
  String get albCoverTitle => 'Chọn ảnh bìa';

  @override
  String get albSetCover => 'Đặt làm ảnh bìa';

  @override
  String get albCoverSet => 'Đã đổi ảnh bìa';

  @override
  String albAppliesTo(int count) {
    return 'Áp dụng cho cả $count mục trong album';
  }

  @override
  String get albLaterFollow =>
      'Ảnh thêm sau này cũng theo quyền của album. Người chăm không thấy Kỷ niệm.';

  @override
  String get albNoticeHint => '1 thông báo chung, không kèm ảnh';

  @override
  String albStayShared(int count) {
    return '$count mục vẫn được gia đình thấy vì còn nằm trong album Gia đình khác.';
  }

  @override
  String get albAudienceSaved => 'Đã đổi ai thấy album';

  @override
  String get sortNewest => 'Mới nhất';

  @override
  String get sortNewestHint => 'Ảnh chụp gần đây ở trên';

  @override
  String get sortOldest => 'Cũ nhất';

  @override
  String get sortOldestHint => 'Kể lại từ đầu, hợp để xem lại';

  @override
  String get sortAdded => 'Mới thêm vào album';

  @override
  String get sortAddedHint => 'Theo lúc bạn thêm ảnh';

  @override
  String get albRemove => 'Bỏ khỏi album';

  @override
  String albRemoved(int count) {
    return 'Đã bỏ $count mục khỏi album';
  }

  @override
  String get dlTitle => 'Tải về máy';

  @override
  String dlSummary(int count, String size) {
    return '$count mục · khoảng $size';
  }

  @override
  String dlInto(String name) {
    return 'Lưu vào album “$name” trong app Ảnh';
  }

  @override
  String get dlWifi => 'Chỉ tải qua Wi-Fi';

  @override
  String get dlWifiHint => 'Video lớn sẽ đợi Wi-Fi';

  @override
  String dlN(int count) {
    return 'Tải $count mục';
  }

  @override
  String get dlFootnote => 'Tải ở nền — xong sẽ báo bạn.';

  @override
  String get dlNeedsWifi => 'Đang chờ Wi-Fi để tải video.';

  @override
  String albDeleteTitle(String name) {
    return 'Xoá album “$name”?';
  }

  @override
  String albDeleteBody(int count) {
    return '$count ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.';
  }

  @override
  String get albDeleteFamily => 'Gia đình sẽ không thấy album này nữa.';

  @override
  String get albDeleted => 'Đã xoá album';

  @override
  String get albPickTitle => 'Thêm vào album';

  @override
  String get albPickNew => 'Tạo album mới';

  @override
  String get albPickHint =>
      'Có thể chọn nhiều album. Ảnh vẫn theo quyền “Ai thấy” bạn đã chọn.';

  @override
  String get albPickNone => 'Chưa chọn';

  @override
  String albPickMore(String first, int count) {
    return '$first +$count';
  }

  @override
  String albAdded(int count, String name) {
    return 'Đã thêm $count mục vào “$name”';
  }

  @override
  String get albFamilySwitched =>
      'Album Gia đình: “Ai thấy” chuyển sang Gia đình.';

  @override
  String get albPickFromMemories => 'Chọn từ Kỷ niệm';

  @override
  String get favAdded => 'Đã thêm vào Yêu thích';

  @override
  String get favRemoved => 'Đã bỏ khỏi Yêu thích';

  @override
  String get love => 'Thương';

  @override
  String lovesNamed(String names) {
    return '$names thương';
  }

  @override
  String lovesCount(int count) {
    return '$count lượt thương';
  }

  @override
  String get messageAction => 'Nhắn';

  @override
  String get messageParents => 'Nhắn ba mẹ';

  @override
  String get messagePlaceholder => 'Nhắn ba mẹ…';

  @override
  String messageTo(String who) {
    return 'Nhắn $who';
  }

  @override
  String get messageSend => 'Gửi';

  @override
  String get messageSent => 'Đã gửi lời nhắn';

  @override
  String get messageHint => 'Chỉ ba mẹ đọc được. Đây không phải trò chuyện.';

  @override
  String get messageFailed => 'Chưa gửi được. Kiểm tra mạng và thử lại.';

  @override
  String get messagesTitle => 'Lời nhắn';

  @override
  String get messagesEmpty => 'Chưa có lời nhắn nào.';

  @override
  String messagesUnread(int count) {
    return '$count chưa đọc';
  }

  @override
  String get messagesAboutPhoto => 'về một ảnh';

  @override
  String get messagesAboutMemory => 'về một kỷ niệm';

  @override
  String messagesAboutAlbum(String name) {
    return 'về album “$name”';
  }

  @override
  String get messagesAboutAlbumGeneric => 'về một album';

  @override
  String get messagesAboutStory => 'về một câu chuyện';

  @override
  String get messagesAboutRecord => 'về một ghi chép chăm sóc';

  @override
  String messagesOnItem(int count) {
    return 'Lời nhắn ($count)';
  }

  @override
  String messageFrom(String who, String when) {
    return '$who · $when';
  }

  @override
  String get relSubtitle => 'Những gì ba mẹ chia sẻ với gia đình';

  @override
  String get relEmptyTitle => 'Chưa có kỷ niệm nào được chia sẻ';

  @override
  String get relEmptyBody =>
      'Khi ba mẹ chia sẻ ảnh với gia đình, bạn sẽ nhận một thông báo và thấy ở đây.';

  @override
  String viewerShared(String date, String who) {
    return '$date · $who chia sẻ';
  }

  @override
  String viewerInAlbum(String meta, String name) {
    return '$meta · album $name';
  }

  @override
  String get albOptions => 'Tuỳ chọn album';

  @override
  String meRoleOwner(String relation, String names) {
    return '$relation · chủ hồ sơ của $names';
  }

  @override
  String meRoleParent(String relation, String names) {
    return '$relation · cùng nuôi $names';
  }

  @override
  String meRoleCaregiver(String relation, String names) {
    return '$relation · chăm $names';
  }

  @override
  String meRoleRelative(String relation, String names) {
    return '$relation · người thân của $names';
  }

  @override
  String get meStorage => 'Dung lượng';

  @override
  String meStorageOf(String used, String quota) {
    return '$used / $quota';
  }

  @override
  String get meStorageShared => 'Dùng chung cho tất cả các bé của bạn';

  @override
  String get meBabies => 'Hồ sơ các bé';

  @override
  String get meAssigned => 'Bé được giao';

  @override
  String get meFollowing => 'Các bé bạn theo dõi';

  @override
  String get meNotifications => 'Thông báo';

  @override
  String get meOn => 'Bật';

  @override
  String get meSome => 'Một số';

  @override
  String get meOff => 'Tắt';

  @override
  String get meAccount => 'Tài khoản & đăng nhập';

  @override
  String get meAccountHint => 'Email, Apple, đổi máy';

  @override
  String get meHelp => 'Trợ giúp & liên hệ';

  @override
  String get meSignOutTitle => 'Đăng xuất khỏi máy này?';

  @override
  String get meSignOutBody =>
      'Mọi ghi chép và kỷ niệm đã lưu trên tài khoản của bạn.';

  @override
  String meSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count mục đang chờ tải lên sẽ không được tải nếu bạn đăng xuất bây giờ.',
      one:
          '1 mục đang chờ tải lên sẽ không được tải nếu bạn đăng xuất bây giờ.',
    );
    return '$_temp0';
  }

  @override
  String get meSignedOutRemote =>
      'Máy này đã được đăng xuất từ một thiết bị khác.';

  @override
  String stOfQuota(String quota) {
    return '/ $quota';
  }

  @override
  String get stFootnote =>
      'Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây';

  @override
  String stNearTitle(int percent) {
    return 'Sắp đầy · $percent%';
  }

  @override
  String get stNearBody =>
      'Video chiếm nhiều chỗ nhất. Xoá bớt video dài hoặc liên hệ quản trị để mở rộng.';

  @override
  String stFullTitle(String quota) {
    return 'Đã dùng hết $quota';
  }

  @override
  String stFullBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tạm dừng tải ảnh, video. $count mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường.',
      one:
          'Tạm dừng tải ảnh, video. 1 mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường.',
    );
    return '$_temp0';
  }

  @override
  String get stFullBodyNone =>
      'Tạm dừng tải ảnh, video. Ghi chép chăm sóc vẫn lưu bình thường.';

  @override
  String get stByBaby => 'Theo bé';

  @override
  String stCounts(int photos, int videos) {
    return '$photos ảnh · $videos video';
  }

  @override
  String get stByType => 'Theo loại';

  @override
  String get stVideo => 'Video';

  @override
  String get stVideoHint => 'Xem video lớn nhất';

  @override
  String get stPhotos => 'Ảnh';

  @override
  String get stNotes => 'Câu chuyện & ghi chú';

  @override
  String get stBin => 'Đã xoá gần đây';

  @override
  String get stBinHint => 'Còn tính đến khi xoá hẳn sau 30 ngày';

  @override
  String get stNeedMore => 'Cần thêm dung lượng?';

  @override
  String stNeedMoreBody(String quota) {
    return 'Mỗi gia đình có $quota. Liên hệ quản trị Child Life để mở rộng.';
  }

  @override
  String get stContact => 'Liên hệ quản trị';

  @override
  String stRequested(int amount, String date) {
    return 'Đã gửi yêu cầu +$amount GB · $date';
  }

  @override
  String get stRequestedHint => 'Quản trị Child Life sẽ trả lời qua email.';

  @override
  String get stReqTitle => 'Xin thêm dung lượng';

  @override
  String get stReqHow => 'Cần thêm bao nhiêu?';

  @override
  String get stReqMessage => 'Lời nhắn (không bắt buộc)';

  @override
  String stReqAttach(String email, String used, String quota) {
    return 'Gửi kèm: $email · đang dùng $used / $quota';
  }

  @override
  String get stReqSend => 'Gửi yêu cầu';

  @override
  String get stReqFootnote =>
      'Quản trị Child Life sẽ trả lời qua email, thường trong 1–2 ngày làm việc.';

  @override
  String get stReqSent => 'Đã gửi yêu cầu';

  @override
  String get needEmailAccount => 'Lưu tài khoản bằng email để gửi yêu cầu.';

  @override
  String get stVideosTitle => 'Video lớn nhất';

  @override
  String get stVideosHint => 'Mở video để xem, tải về hoặc xoá.';

  @override
  String get stVideosEmpty => 'Chưa có video nào.';

  @override
  String get stLoadFailed => 'Không tải được dung lượng. Kéo xuống để thử lại.';

  @override
  String bpCarers(String age, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$age · $count người cùng chăm',
      one: '$age · 1 người cùng chăm',
    );
    return '$_temp0';
  }

  @override
  String get bpAdd => 'Thêm bé';

  @override
  String get bpDeleting => 'Đang xoá…';

  @override
  String bpBorn(String age, String date) {
    return '$age · sinh ngày $date';
  }

  @override
  String bpWeight(String when) {
    return 'Cân nặng · $when';
  }

  @override
  String bpLength(String when) {
    return 'Chiều cao · $when';
  }

  @override
  String get bpInfo => 'Thông tin';

  @override
  String get bpOf => 'Của bé';

  @override
  String bpFamily(String name) {
    return 'Gia đình của $name';
  }

  @override
  String get bpGrowthHint => 'Biểu đồ cân nặng, chiều cao';

  @override
  String bpStorage(String name) {
    return 'Dung lượng của $name';
  }

  @override
  String bpStorageHint(String quota) {
    return 'Tính vào $quota của bạn';
  }

  @override
  String bpDelete(String name) {
    return 'Xoá hồ sơ $name';
  }

  @override
  String bpDeleteOwner(String owner) {
    return 'Chỉ chủ hồ sơ ($owner) làm được';
  }

  @override
  String get bpSave => 'Lưu thay đổi';

  @override
  String get bpPrivacy => 'Người thân chỉ thấy tên thân mật';

  @override
  String get bpOptional => '· không bắt buộc';

  @override
  String get bpSaved => 'Đã lưu hồ sơ';

  @override
  String bpDelTitle(String name) {
    return 'Xoá hồ sơ $name?';
  }

  @override
  String bpDelBody(String name) {
    return 'Mọi ghi chép chăm sóc, ảnh, video và câu chuyện của $name sẽ bị xoá với cả gia đình. Không khôi phục được.';
  }

  @override
  String bpDelFree(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giải phóng $size · $count người mất quyền xem',
      one: 'Giải phóng $size · 1 người mất quyền xem',
    );
    return '$_temp0';
  }

  @override
  String get bpDelTip => 'Nên tải ảnh về máy trước khi xoá.';

  @override
  String bpDelType(String name) {
    return 'Gõ “$name” để xác nhận';
  }

  @override
  String get bpDelConfirm => 'Xoá vĩnh viễn';

  @override
  String bpDelStarted(String name) {
    return 'Đang xoá hồ sơ $name…';
  }

  @override
  String bpDelDone(String name) {
    return 'Đã xoá hồ sơ $name';
  }

  @override
  String get bpDelRetrying => 'Chưa xoá xong, đang tự thử lại.';

  @override
  String get bpLocked =>
      'Hồ sơ này đang được xoá. Không thể thêm ghi chép mới.';

  @override
  String get pfTitle => 'Hồ sơ của bạn';

  @override
  String get pfName => 'Tên hiển thị';

  @override
  String get pfWho => 'Bạn là ai với bé';

  @override
  String get pfFootnote =>
      'Gia đình thấy tên và vai trò này khi bạn ghi chép hay chia sẻ.';

  @override
  String pfRelationTitle(String name) {
    return 'Bạn là gì của $name?';
  }

  @override
  String get pfSaved => 'Đã lưu';

  @override
  String get acTitle => 'Tài khoản';

  @override
  String get acSignIn => 'Đăng nhập';

  @override
  String acEmailVerified(String email) {
    return '$email · đã xác minh';
  }

  @override
  String acEmailUnverified(String email) {
    return '$email · chưa xác minh';
  }

  @override
  String get acLinked => 'Đã liên kết';

  @override
  String get acUnlink => 'Gỡ';

  @override
  String get acUnlinkLast => 'Cần giữ ít nhất một cách đăng nhập.';

  @override
  String acUnlinked(String provider) {
    return 'Đã gỡ $provider';
  }

  @override
  String get acPassword => 'Đổi mật khẩu';

  @override
  String acPasswordSent(String email) {
    return 'Đã gửi email đổi mật khẩu tới $email';
  }

  @override
  String get acDevices => 'Thiết bị đang đăng nhập';

  @override
  String get acThisDevice => 'Máy này';

  @override
  String acActive(String when) {
    return 'Hoạt động $when';
  }

  @override
  String acDeviceSignedOut(String name) {
    return 'Đã đăng xuất $name';
  }

  @override
  String get acOwner => 'Chủ hồ sơ';

  @override
  String get acTransfer => 'Chuyển chủ hồ sơ';

  @override
  String acTransferHint(String names) {
    return 'Cho một người Cùng nuôi của $names';
  }

  @override
  String acTransferBody(String names) {
    return 'Người nhận trở thành chủ hồ sơ của $names: xoá hồ sơ, chuyển tiếp và dung lượng gia đình. Họ cần đồng ý.';
  }

  @override
  String get acTransferNone => 'Chưa có ai Cùng nuôi tất cả các bé.';

  @override
  String get acTransferSend => 'Gửi đề nghị';

  @override
  String acTransferPending(String name) {
    return 'Đang chờ $name đồng ý';
  }

  @override
  String get acTransferCancel => 'Huỷ đề nghị';

  @override
  String acTransferSent(String name) {
    return 'Đã gửi đề nghị cho $name';
  }

  @override
  String acOfferTitle(String name) {
    return '$name muốn chuyển quyền chủ hồ sơ cho bạn';
  }

  @override
  String acOfferBody(String names) {
    return 'Bạn sẽ là chủ hồ sơ của $names và quản lý dung lượng gia đình.';
  }

  @override
  String get acOfferAccept => 'Nhận';

  @override
  String get acOfferDecline => 'Từ chối';

  @override
  String get acOfferAccepted => 'Bạn đã là chủ hồ sơ';

  @override
  String get acReceiverOwns => 'Người này đang là chủ hồ sơ khác.';

  @override
  String get acStaffTransferTitle =>
      'Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ';

  @override
  String acStaffTransferBody(String to, String time) {
    return 'Cho $to. Bạn đồng ý trong 48 giờ (đến $time); nếu không, đề nghị tự huỷ. Đồng ý thì $to sẽ nhận lời mời làm chủ hồ sơ như bình thường.';
  }

  @override
  String acStaffTransferBodyTicket(String to, String ticket, String time) {
    return 'Cho $to · mã $ticket. Bạn đồng ý trong 48 giờ (đến $time); nếu không, đề nghị tự huỷ. Đồng ý thì $to sẽ nhận lời mời làm chủ hồ sơ như bình thường.';
  }

  @override
  String get acStaffTransferAgree => 'Đồng ý';

  @override
  String get acStaffTransferDecline => 'Không đồng ý';

  @override
  String get acStaffTransferConfirmTitle => 'Đồng ý chuyển quyền chủ hồ sơ?';

  @override
  String acStaffTransferConfirmBody(String to) {
    return '$to sẽ nhận lời mời làm chủ hồ sơ. Quyền chỉ chuyển khi họ nhận lời; trước đó bạn vẫn có thể huỷ đề nghị ở mục Chủ hồ sơ.';
  }

  @override
  String acStaffTransferAgreed(String to) {
    return 'Đã đồng ý · $to sẽ nhận lời mời';
  }

  @override
  String get acStaffTransferDeclined => 'Đã từ chối đề nghị chuyển quyền';

  @override
  String get acStaffTransferGone =>
      'Đề nghị này đã hết hạn hoặc đã được trả lời.';

  @override
  String get acExport => 'Xuất dữ liệu';

  @override
  String get acExportHint => 'Ghi chép chăm sóc, ảnh và video';

  @override
  String acExportTitle(String name) {
    return 'Xuất dữ liệu của $name';
  }

  @override
  String get acExportCare => 'Ghi chép chăm sóc';

  @override
  String get acExportCareHint => 'CSV và JSON';

  @override
  String get acExportMedia => 'Ảnh và video';

  @override
  String get acExportMediaHint => 'ZIP · chỉ chủ hồ sơ';

  @override
  String get acExportStart => 'Bắt đầu xuất';

  @override
  String get acExportFootnote =>
      'Chúng tôi gửi email khi tệp sẵn sàng. Liên kết tải hết hạn sau 24 giờ.';

  @override
  String get acExportQueued => 'Đang chuẩn bị…';

  @override
  String acExportReady(String when) {
    return 'Sẵn sàng · hết hạn $when';
  }

  @override
  String get acExportExpired => 'Đã hết hạn';

  @override
  String get acExportFailed => 'Không xuất được';

  @override
  String get acExportRunning => 'Một tệp xuất khác đang chạy.';

  @override
  String get acDelete => 'Xoá tài khoản';

  @override
  String acDeleteBlocked(String names) {
    return 'Cần chuyển chủ hồ sơ của $names trước';
  }

  @override
  String get acDeleteHint => 'Xoá tên, email và thiết bị của bạn';

  @override
  String get acDeleteTitle => 'Xoá tài khoản?';

  @override
  String get acDeleteBody =>
      'Tên, email và thiết bị của bạn sẽ bị xoá. Ghi chép và kỷ niệm bạn đã chia sẻ ở lại với gia đình, ghi là “Người dùng đã xoá”. Không khôi phục được.';

  @override
  String get acDeleting => 'Đang xoá tài khoản…';

  @override
  String get deletedUser => 'Người dùng đã xoá';

  @override
  String get ntMemories => 'Kỷ niệm mới';

  @override
  String get ntMemoriesHint => 'Khi ba mẹ chia sẻ ảnh, album, câu chuyện';

  @override
  String get ntMessages => 'Lời nhắn';

  @override
  String get ntMessagesHint => 'Khi có người nhắn ba mẹ';

  @override
  String get ntReminders => 'Nhắc việc';

  @override
  String get ntRemindersHint => 'Trên máy được chọn cho từng nhắc việc';

  @override
  String get ntStorage => 'Dung lượng';

  @override
  String get ntStorageHint => 'Khi gần đầy hoặc đã đầy';

  @override
  String get ntFootnote => 'Thông báo không bao giờ kèm ảnh hay tên bé.';

  @override
  String get hpTopic => 'Chủ đề';

  @override
  String get hpCatMemories => 'Kỷ niệm & media';

  @override
  String get hpCatFamily => 'Gia đình & vai trò';

  @override
  String get hpCatInvites => 'Lời mời';

  @override
  String get hpCatSync => 'Đồng bộ';

  @override
  String get hpCatAccount => 'Tài khoản';

  @override
  String get hpCatStorage => 'Dung lượng';

  @override
  String get hpCatStories => 'Câu chuyện';

  @override
  String get hpMessage => 'Bạn cần giúp gì?';

  @override
  String get hpDiagnostics => 'Gửi kèm thông tin chẩn đoán';

  @override
  String get hpDiagnosticsHint =>
      'Phiên bản app, loại máy, tình trạng đồng bộ. Không kèm ảnh hay ghi chép.';

  @override
  String hpFootnote(String email) {
    return 'Chúng tôi trả lời qua email $email.';
  }

  @override
  String hpSent(String ticket) {
    return 'Đã gửi · mã $ticket';
  }

  @override
  String get srySuggestTag => 'Gợi ý tuần này';

  @override
  String srySuggestSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Từ $count ảnh · bạn sửa trước khi lưu',
      one: 'Từ 1 ảnh · bạn sửa trước khi lưu',
    );
    return '$_temp0';
  }

  @override
  String get srySuggestCta => 'Xem bản nháp';

  @override
  String sryDrafts(int count) {
    return 'Bản nháp · $count';
  }

  @override
  String get sryShared => 'Đã chia sẻ';

  @override
  String sryToldBy(String who, String when) {
    return '$who kể · $when';
  }

  @override
  String sryWroteBy(String who, String when) {
    return '$who viết · sửa lần cuối $when';
  }

  @override
  String get sryDraft => 'Bản nháp';

  @override
  String get sryFromSuggestion => 'Nháp từ gợi ý · chưa lưu';

  @override
  String get sryWrite => 'Viết';

  @override
  String get sryEmptyTitle => 'Chưa có câu chuyện nào';

  @override
  String get sryEmptyBody =>
      'Viết lại một khoảnh khắc, hoặc chờ gợi ý cuối tuần từ những gì bạn đã ghi.';

  @override
  String get sryRelEmpty => 'Ba mẹ chưa chia sẻ câu chuyện nào.';

  @override
  String get sryNewTitle => 'Viết gì?';

  @override
  String get sryKindStory => 'Câu chuyện';

  @override
  String get sryKindStoryHint => 'Kể một khoảnh khắc, có ảnh';

  @override
  String get sryKindLetter => 'Thư';

  @override
  String get sryKindLetterHint => 'Viết thư cho con đọc sau này';

  @override
  String get srySaveDraft => 'Lưu nháp';

  @override
  String sryAiTip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'AI viết nháp từ $count ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.',
      one:
          'AI viết nháp từ 1 ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.',
    );
    return '$_temp0';
  }

  @override
  String get sryTip => 'Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.';

  @override
  String get sryChangeCover => 'Đổi ảnh bìa';

  @override
  String get sryAddCover => 'Thêm ảnh bìa';

  @override
  String get sryTitleHint => 'Tiêu đề';

  @override
  String get sryParagraphHint => 'Viết vài dòng…';

  @override
  String sryMetaPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
      one: '1 ảnh',
    );
    return '$_temp0';
  }

  @override
  String sryMetaMilestone(String name) {
    return 'mốc $name';
  }

  @override
  String get sryRewrite => 'Viết lại';

  @override
  String get sryWarmer => 'Ấm hơn';

  @override
  String get sryShorter => 'Ngắn hơn';

  @override
  String get sryUndo => 'Hoàn tác';

  @override
  String get sryAddBlock => 'Thêm đoạn · ảnh · mốc';

  @override
  String get sryAddParagraph => 'Đoạn văn';

  @override
  String get sryAddPhotos => 'Ảnh';

  @override
  String get sryAddMilestone => 'Mốc';

  @override
  String get sryAddQuote => 'Câu trích';

  @override
  String get sryArrange => 'Sắp xếp';

  @override
  String get sryPreviewSave => 'Xem trước & lưu';

  @override
  String get sryDiscardTitle => 'Bỏ thay đổi?';

  @override
  String get sryDiscardBody => 'Những gì bạn vừa sửa chưa được lưu.';

  @override
  String get sryDiscard => 'Bỏ thay đổi';

  @override
  String get sryKeepEditing => 'Sửa tiếp';

  @override
  String get sryDraftSaved => 'Đã lưu nháp';

  @override
  String get sryDiscardDraft => 'Bỏ bản nháp';

  @override
  String get sryEditParagraph => 'Sửa đoạn';

  @override
  String get sryEdited => 'Đã sửa · không còn là văn AI';

  @override
  String sryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count từ',
      one: '1 từ',
    );
    return '$_temp0';
  }

  @override
  String get srySuggestFor => 'Gợi ý cho đoạn này';

  @override
  String get sryUseThis => 'Dùng câu này';

  @override
  String get sryOtherSuggestion => 'Gợi ý khác';

  @override
  String get sryAiUnavailable => 'AI chưa sẵn sàng. Bạn vẫn sửa tay được.';

  @override
  String get sryAiLimit => 'Hôm nay đã dùng hết lượt gợi ý.';

  @override
  String get sryAiWorking => 'Đang viết…';

  @override
  String get sryPhotosTitle => 'Ảnh trong câu chuyện';

  @override
  String get sryChangePhoto => 'Đổi ảnh';

  @override
  String sryChangePhotoHint(String name) {
    return 'Chọn từ Kỷ niệm của $name';
  }

  @override
  String get sryAddToGroup => 'Thêm ảnh vào nhóm này';

  @override
  String get sryAddToGroupHint => 'Tối đa 4 ảnh một nhóm';

  @override
  String get sryCaption => 'Thêm chú thích';

  @override
  String get sryCaptionHint => 'Hiện nhỏ dưới ảnh';

  @override
  String get sryMakeCover => 'Đặt làm ảnh bìa';

  @override
  String get sryRemovePhotos => 'Bỏ khỏi câu chuyện';

  @override
  String get sryRemovePhotosHint => 'Ảnh vẫn còn trong Kỷ niệm';

  @override
  String get sryArrangeHint =>
      'Giữ ≡ và kéo để đổi thứ tự. Vuốt trái để xoá khối.';

  @override
  String get sryCoverRow => 'Ảnh bìa';

  @override
  String sryParagraphN(int n) {
    return 'Đoạn $n';
  }

  @override
  String get sryPhotoGroup => 'Nhóm ảnh';

  @override
  String get sryMilestoneRow => 'Mốc';

  @override
  String get sryQuoteRow => 'Câu trích';

  @override
  String get sryPreviewLabel => 'XEM TRƯỚC';

  @override
  String get sryNeedTitle => 'Đặt tiêu đề cho câu chuyện.';

  @override
  String get sryNeedContent => 'Thêm ít nhất một đoạn hoặc một ảnh.';

  @override
  String get srySaveTitle => 'Lưu câu chuyện';

  @override
  String get sryPrivate => 'Riêng tư';

  @override
  String get sryFamilyRead => 'Cả nhà cùng đọc';

  @override
  String get sryOneNotice => '1 thông báo chung';

  @override
  String get sryShareAfter => 'Lưu xong mới chia sẻ ra ngoài được.';

  @override
  String sryPrivatePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.',
      one: '1 ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.',
    );
    return '$_temp0';
  }

  @override
  String get srySavedNotified => 'Đã lưu · đã báo cho gia đình';

  @override
  String get srySaved => 'Đã lưu câu chuyện';

  @override
  String get sryShare => 'Chia sẻ';

  @override
  String get sryWhoReads => 'Ai đọc câu chuyện này';

  @override
  String get sryAudienceChanged => 'Đã đổi ai đọc';

  @override
  String get sryDelete => 'Xoá câu chuyện';

  @override
  String get sryDeleteTitle => 'Xoá câu chuyện này?';

  @override
  String get sryDeleteBody =>
      'Cả nhà sẽ không đọc được nữa. Ảnh vẫn còn trong Kỷ niệm.';

  @override
  String get sryDeleted => 'Đã xoá câu chuyện';

  @override
  String sryMetaSaved(String who, String when, String audience) {
    return '$who kể · $when · $audience';
  }

  @override
  String sryRelMeta(String who, String when) {
    return '$who chia sẻ với gia đình · $when';
  }

  @override
  String sryMilestoneOn(String name, String date) {
    return '$name · $date';
  }

  @override
  String get sryMore => 'Tuỳ chọn câu chuyện';

  @override
  String get shInFamily => 'Trong gia đình';

  @override
  String get shFamilyReading => 'Gia đình đang đọc';

  @override
  String get shParentsReading => 'Chỉ ba mẹ đang đọc';

  @override
  String get shTapToChange => 'Đã báo cả nhà · chạm để đổi';

  @override
  String get shTapToChangeParents => 'Chạm để đổi';

  @override
  String get shOutside => 'Ra ngoài';

  @override
  String get shCard => 'Thiệp ảnh';

  @override
  String get shCardHint => 'Đẹp để đăng Facebook, Instagram, Zalo';

  @override
  String get shLink => 'Liên kết xem riêng';

  @override
  String get shLinkHint => 'Có hạn · không cần cài app';

  @override
  String get shOutsideNote =>
      'Chỉ ba mẹ thấy mục “Ra ngoài”. Mặc định ẩn tên thật và ngày sinh.';

  @override
  String get shPrivatePhotosNote =>
      'Ảnh Chỉ ba mẹ không hiện khi chia sẻ ra ngoài.';

  @override
  String get cdNext => 'Tiếp';

  @override
  String get cdMoment => '1 ảnh';

  @override
  String get cdThree => '3 ảnh';

  @override
  String get cdFour => '4 ảnh';

  @override
  String get cdLetter => 'Chữ';

  @override
  String get cdNight => 'Tối';

  @override
  String get cdQuote => 'Câu trích';

  @override
  String get cdPhoto => 'Ảnh';

  @override
  String get cdCover => 'Ảnh bìa';

  @override
  String get cdShowAge => 'Hiện tuổi thay ngày sinh';

  @override
  String cdTo(String name) {
    return 'Gửi $name,';
  }

  @override
  String cdSigned(String who, String season) {
    return '— $who, $season';
  }

  @override
  String get cdSaved => 'Đã tạo thiệp';

  @override
  String get cdSize => 'Ảnh 1080 × 1350';

  @override
  String get lkExpires => 'Hết hạn sau';

  @override
  String get lk24h => '24 giờ';

  @override
  String get lk7d => '7 ngày';

  @override
  String get lk30d => '30 ngày';

  @override
  String get lkHideIdentity => 'Ẩn tên thật & ngày sinh';

  @override
  String lkHideIdentityHint(String name) {
    return 'Chỉ hiện “$name” và số tuần tuổi';
  }

  @override
  String get lkDownload => 'Cho tải ảnh về';

  @override
  String get lkDownloadHint => 'Tắt: người xem chỉ xem, không lưu';

  @override
  String get lkPasscode => 'Hỏi mật mã 4 số';

  @override
  String get lkPasscodeHint => 'Gửi mật mã riêng cho người nhận';

  @override
  String get lkNote => 'Bạn thấy được số lượt xem và thu hồi bất cứ lúc nào.';

  @override
  String get lkCopyShare => 'Sao chép & chia sẻ';

  @override
  String get lkCopy => 'Sao chép';

  @override
  String get lkCopied => 'Đã sao chép liên kết';

  @override
  String get lkPasscodeTitle => 'Mật mã của liên kết';

  @override
  String get lkPasscodeBody =>
      'Gửi riêng mật mã này cho người nhận. Child Life không hiện lại mật mã.';

  @override
  String get lkScreenshotNote => 'Người xem vẫn có thể chụp màn hình.';

  @override
  String get soTitle => 'Đã chia sẻ ra ngoài';

  @override
  String soOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count liên kết đang mở',
      one: '1 liên kết đang mở',
    );
    return '$_temp0';
  }

  @override
  String get soOpen => 'Đang mở';

  @override
  String get soCards => 'Thiệp ảnh đã lưu';

  @override
  String get soClosed => 'Đã hết hạn';

  @override
  String soViewsLeftDays(int count, String left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt xem · còn $left',
      one: '1 lượt xem · còn $left',
    );
    return '$_temp0';
  }

  @override
  String soDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
      one: '1 ngày',
    );
    return '$_temp0';
  }

  @override
  String soHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ',
      one: '1 giờ',
    );
    return '$_temp0';
  }

  @override
  String get soRevoke => 'Thu hồi';

  @override
  String get soRevokeTitle => 'Thu hồi liên kết?';

  @override
  String get soRevokeBody => 'Người có liên kết sẽ không xem được nữa.';

  @override
  String get soRevoked => 'Đã thu hồi';

  @override
  String soExpiredOn(String date) {
    return 'Hết hạn $date';
  }

  @override
  String get soCardRow => 'Ảnh · không thu hồi được';

  @override
  String get soEmpty => 'Chưa chia sẻ câu chuyện nào ra ngoài.';

  @override
  String get shareExtTitle => 'Thêm vào Kỷ niệm';

  @override
  String get shareExtAdd => 'Thêm';

  @override
  String get shareExtBaby => 'Bé';

  @override
  String get shareExtNotifyHint => 'Gửi 1 thông báo khi tải xong';

  @override
  String shareExtPhotos(int count) {
    return '$count ảnh';
  }

  @override
  String shareExtVideos(int count) {
    return '$count video';
  }

  @override
  String get shareExtFootnote => 'Ảnh sẽ tải lên khi bạn mở Child Life.';

  @override
  String get shareExtSignedOut =>
      'Mở Child Life và đăng nhập để thêm ảnh vào Kỷ niệm.';

  @override
  String get shareExtNoBaby =>
      'Chỉ ba mẹ (Cùng nuôi) thêm được kỷ niệm cho bé.';

  @override
  String get shareExtNothing => 'Không có ảnh hay video nào để thêm.';

  @override
  String get shareExtClose => 'Đóng';

  @override
  String get upUploadsPaused => 'Tải ảnh, video đang tạm dừng';

  @override
  String get upUploadsPausedHint => 'Ảnh, video sẽ tự tải tiếp khi mở lại.';

  @override
  String get rowUploadsPaused => 'Đang tạm dừng tải lên';

  @override
  String get rowRejected => 'Chưa tải lên được';

  @override
  String get glanceAppName => 'Child Life';

  @override
  String get glanceYou => 'Bạn';

  @override
  String get glanceBottle => 'Bú bình';

  @override
  String get glanceBreast => 'Bú mẹ';

  @override
  String get glanceSleep => 'Ngủ';

  @override
  String get glanceSleepTitle => 'Giấc ngủ';

  @override
  String get glanceDiaper => 'Thay tã';

  @override
  String get glanceDiaperWet => 'Ướt';

  @override
  String get glanceDiaperDirty => 'Bẩn';

  @override
  String get glanceDiaperBoth => 'Cả hai';

  @override
  String glanceAgo(String t) {
    return '$t trước';
  }

  @override
  String glanceLoggedBy(String name) {
    return '$name ghi';
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
    return 'Đã ghi $what · $name';
  }

  @override
  String glanceLoggedToast(String what) {
    return 'Đã ghi $what';
  }

  @override
  String get glanceJustNow => 'Vừa xong';

  @override
  String get glanceUndo => 'Hoàn tác';

  @override
  String get glanceEdit => 'Sửa';

  @override
  String get glanceChangeType => 'Đổi loại';

  @override
  String get glanceStartBreast => 'Bắt đầu bú';

  @override
  String get glanceFeeding => 'Đang bú';

  @override
  String get glanceSwitchSide => 'Đổi bên';

  @override
  String get glanceDone => 'Xong';

  @override
  String get glanceBreastSideLeft => 'Bên trái';

  @override
  String get glanceBreastSideRight => 'Bên phải';

  @override
  String glanceSinceTime(String time) {
    return 'từ $time';
  }

  @override
  String glanceAwakeFor(String t) {
    return 'Đã thức $t';
  }

  @override
  String glanceWokeAt(String time) {
    return 'Dậy lúc $time';
  }

  @override
  String get glanceStartSleep => 'Bắt đầu ngủ';

  @override
  String get glanceSleeping => 'Đang ngủ';

  @override
  String glanceSince(String time, String name) {
    return 'Từ $time · $name';
  }

  @override
  String get glanceWake => 'Thức dậy';

  @override
  String get glanceJustWoke => 'Vừa thức dậy';

  @override
  String glanceSlept(String t) {
    return 'Ngủ $t';
  }

  @override
  String get glanceEmptyTitle => 'Hôm nay chưa ghi';

  @override
  String get glanceEmptySub => 'Ghi cữ đầu tiên nhé';

  @override
  String get glanceQuickLog => '+ Ghi nhanh';

  @override
  String get glanceSignedOutTitle => 'Đăng nhập để dùng widget';

  @override
  String get glanceOpenApp => 'Mở app';

  @override
  String get glanceOpenChildLife => 'Mở Child Life';

  @override
  String glanceSummary(String feeds, String sleep) {
    return '$feeds cữ · ngủ $sleep hôm nay';
  }

  @override
  String glancePending(String n) {
    return 'Chưa đồng bộ · $n bản ghi chờ';
  }

  @override
  String get glanceRecent => 'Gần đây';

  @override
  String glanceTotals(
    String bottles,
    String ml,
    String breasts,
    String diapers,
  ) {
    return 'Hôm nay: $bottles cữ bình $ml ml · $breasts lần bú mẹ · $diapers tã';
  }

  @override
  String get glanceNoneYet => 'Chưa có';

  @override
  String glanceFedFor(String t, String name) {
    return 'Bú $t · $name ghi';
  }

  @override
  String glanceAgoFor(String t) {
    return 'trước · $t';
  }

  @override
  String glanceAgoKind(String kind) {
    return 'trước · $kind';
  }

  @override
  String glanceAwakeShort(String t) {
    return 'thức $t';
  }

  @override
  String glanceSleptToday(String t) {
    return 'ngủ $t hôm nay';
  }

  @override
  String glanceLockFeeds(String feed, String diaper) {
    return 'Bú $feed · Tã $diaper';
  }

  @override
  String glanceLockSleep(String awake, String slept) {
    return 'Thức $awake · ngủ $slept';
  }

  @override
  String glanceInlineFed(String name, String t) {
    return '$name bú $t trước';
  }

  @override
  String get glanceFamilySees => 'Cả nhà đang thấy';

  @override
  String glanceSleepingTitle(String name) {
    return '$name đang ngủ';
  }

  @override
  String get glanceEditTime => 'Sửa giờ bắt đầu';

  @override
  String get glanceEditTimeShort => 'Sửa giờ';

  @override
  String glanceBreastTitle(String side) {
    return 'Bú mẹ · $side';
  }

  @override
  String get glanceEndFeed => 'Kết thúc';

  @override
  String get glancePaused => 'Tạm dừng';

  @override
  String glanceDurM(String m) {
    return '$m phút';
  }

  @override
  String glanceDurH(String h) {
    return '$h giờ';
  }

  @override
  String glanceDurHm(String h, String m) {
    return '$h giờ $m phút';
  }

  @override
  String glanceDurSM(String m) {
    return '${m}p';
  }

  @override
  String glanceDurSH(String h) {
    return '${h}g';
  }

  @override
  String glanceDurSHm(String h, String m) {
    return '${h}g ${m}p';
  }

  @override
  String get glanceGalleryBottleName => 'Bú bình';

  @override
  String get glanceGalleryBottleBlurb =>
      'Ghi lại cữ bình vừa rồi chỉ với một chạm.';

  @override
  String get glanceGalleryBreastName => 'Bú mẹ';

  @override
  String get glanceGalleryBreastBlurb => 'Bắt đầu, đổi bên và kết thúc cữ bú.';

  @override
  String get glanceGallerySleepName => 'Giấc ngủ';

  @override
  String get glanceGallerySleepBlurb =>
      'Bắt đầu ngủ và thức dậy ngay trên màn hình chính.';

  @override
  String get glanceGalleryDiaperName => 'Thay tã';

  @override
  String get glanceGalleryDiaperBlurb => 'Ướt, bẩn hay cả hai — một chạm.';

  @override
  String get glanceGalleryQuickName => 'Ghi nhanh';

  @override
  String get glanceGalleryQuickBlurb =>
      'Bú bình, bú mẹ, ngủ, thay tã — một chạm.';

  @override
  String get glanceGalleryTodayName => 'Hôm nay';

  @override
  String get glanceGalleryTodayBlurb =>
      'Giấc ngủ, ghi nhanh và 3 lần ghi gần nhất.';

  @override
  String get glanceGalleryLockName => 'Child Life';

  @override
  String get glanceGalleryLockBlurb =>
      'Lần bú, tã và giấc ngủ trên màn hình khoá.';

  @override
  String get glanceGalleryLockSleepName => 'Giấc ngủ';

  @override
  String get glanceGalleryLockSleepBlurb =>
      'Đang ngủ bao lâu, hoặc đã thức bao lâu.';

  @override
  String get glanceGalleryLockFeedName => 'Lần bú';

  @override
  String get glanceGalleryLockFeedBlurb => 'Bao lâu từ lần bú gần nhất.';

  @override
  String glanceUploadTitle(String name) {
    return 'Kỷ niệm của $name';
  }

  @override
  String get glanceUploadTitlePlain => 'Kỷ niệm';

  @override
  String glanceUploadProgress(String done, String total) {
    return 'Đang tải $done/$total mục';
  }

  @override
  String get glanceUploadNotify => 'Xong sẽ báo bạn';

  @override
  String glanceUploadWaiting(String n) {
    return '$n video chờ Wi‑Fi';
  }

  @override
  String get glanceUploadDoneOne => 'Đã tải xong 1 mục';

  @override
  String glanceUploadDone(String n) {
    return 'Đã tải xong $n mục';
  }

  @override
  String get glanceUploadDoneBody => 'Ảnh và video đã có trong Kỷ niệm.';

  @override
  String get glanceUploadFailedOne => '1 mục chưa tải lên được';

  @override
  String glanceUploadFailed(String n) {
    return '$n mục chưa tải lên được';
  }

  @override
  String get glanceUploadFailedBody => 'Mở Child Life để thử lại.';

  @override
  String get glanceUploadWifiOne => '1 video đang chờ Wi‑Fi';

  @override
  String glanceUploadWifi(String n) {
    return '$n video đang chờ Wi‑Fi';
  }

  @override
  String get glanceUploadWifiBody =>
      'Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi.';

  @override
  String get meLanguage => 'Ngôn ngữ';

  @override
  String get meLanguageDevice => 'Theo máy';

  @override
  String meLanguageDeviceNow(String name) {
    return 'Đang dùng $name';
  }

  @override
  String get meLanguageVi => 'Tiếng Việt';

  @override
  String get meLanguageEn => 'English';

  @override
  String get meLanguageHint =>
      'Đổi ngay cho cả app, widget và thông báo trên máy này.';

  @override
  String get whoIntro =>
      'Theo bảng chuẩn tăng trưởng trẻ em của WHO. Mỗi bé lớn theo nhịp riêng.';

  @override
  String get whoBoy => 'Bé trai';

  @override
  String get whoGirl => 'Bé gái';

  @override
  String get whoByWeek => 'Theo tuần';

  @override
  String get whoByMonth => 'Theo tháng';

  @override
  String get whoAge => 'Tuổi';

  @override
  String get whoLow => 'Thấp';

  @override
  String get whoMedian => 'Trung vị';

  @override
  String get whoHigh => 'Cao';

  @override
  String get whoBirth => 'Mới sinh';

  @override
  String whoWeeks(int count) {
    return '$count tuần';
  }

  @override
  String whoMonths(int count) {
    return '$count tháng';
  }

  @override
  String get whoUnitKg =>
      'Đơn vị: kg. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.';

  @override
  String get whoUnitCm =>
      'Đơn vị: cm. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.';

  @override
  String get whoDoctor =>
      'Nếu số đo của bé nằm ngoài khoảng bình thường, hãy trao đổi với bác sĩ của bé.';

  @override
  String get whoSource =>
      'Nguồn: WHO Child Growth Standards · Child Life cập nhật 09/2026';

  @override
  String whoBabyAt(String name, String value, String status) {
    return '$name $value · $status';
  }

  @override
  String get whoNormal => 'Bình thường';

  @override
  String get whoBelow => 'Dưới mức tham chiếu';

  @override
  String get whoAbove => 'Trên mức tham chiếu';

  @override
  String get whoOpen => 'Xem tiêu chuẩn tăng trưởng WHO';

  @override
  String get whoBand => 'Khoảng bình thường';

  @override
  String get whoMedianLine => 'Trung vị WHO';

  @override
  String get feedsPerDayTitle => 'Bú mỗi ngày';

  @override
  String feedsPerDayHint(int days) {
    return 'Số cữ bú bình và bú mẹ · $days ngày';
  }

  @override
  String feedsDayTip(
    String day,
    int bottles,
    int ml,
    int breasts,
    int minutes,
  ) {
    return '$day · $bottles bình $ml ml · $breasts mẹ ${minutes}p';
  }

  @override
  String feedsAvgLine(int count) {
    return 'TB $count cữ';
  }

  @override
  String bottleShareLine(int pct, int ml) {
    return 'Bú bình $pct% · $ml ml/ngày';
  }

  @override
  String breastShareLine(int pct, int minutes) {
    return 'Bú mẹ $pct% · $minutes phút/ngày';
  }

  @override
  String get kpiFeedsPerDay => 'TB mỗi ngày';

  @override
  String get kpiBottlePerDay => 'Bú bình/ngày';

  @override
  String get kpiBreastPerDay => 'Bú mẹ/ngày';

  @override
  String get sleepPerDayTitle => 'Tổng giờ ngủ mỗi ngày';

  @override
  String get sleepPerDayHint => 'Đêm 18:00–06:00 · Ngày 06:00–18:00';

  @override
  String sleepDayTip(String day, String total, String night, String daytime) {
    return '$day · $total · đêm $night · ngày $daytime';
  }

  @override
  String sleepAvgLine(String total) {
    return 'TB $total';
  }

  @override
  String get legendNightSleep => 'Ngủ đêm';

  @override
  String get legendDaySleep => 'Ngủ ngày';

  @override
  String sleepSteadyInsight(int hours, int days) {
    return 'Tổng giờ ngủ ổn định quanh $hours giờ/ngày trong $days ngày qua.';
  }

  @override
  String sleepRangeInsight(String min, String max, int days) {
    return 'Tổng giờ ngủ từ $min đến $max mỗi ngày trong $days ngày qua.';
  }

  @override
  String get whoStandardsTitle => 'Tiêu chuẩn tăng trưởng';

  @override
  String whoLowerEdge(String value) {
    return 'Ngưỡng dưới $value';
  }

  @override
  String whoUpperEdge(String value) {
    return 'Ngưỡng trên $value';
  }

  @override
  String whoBelowWeightNote(String name) {
    return 'Cân nặng của $name đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String whoBelowLengthNote(String name) {
    return 'Chiều dài của $name đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String whoAboveWeightNote(String name) {
    return 'Cân nặng của $name đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String whoAboveLengthNote(String name) {
    return 'Chiều dài của $name đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String get amountFromLast => 'Lượng sữa · đã điền theo lần trước';

  @override
  String lastBottleAt(int ml, String time) {
    return 'Lần trước $ml ml · $time';
  }

  @override
  String bottleSuggestFor(String age) {
    return 'Gợi ý cho bé $age';
  }

  @override
  String get bottleSuggestNewborn => 'Gợi ý cho bé sơ sinh';

  @override
  String bottleQuickPick(int ml) {
    return '$ml ml';
  }

  @override
  String get feedKindTitle => 'Loại bú';

  @override
  String get feedKindAll => 'Tất cả';

  @override
  String get feedKindAllHint => 'Bú bình và bú mẹ';

  @override
  String get feedKindBottleHint => 'Theo lượng sữa (ml)';

  @override
  String get feedKindBreastHint => 'Theo thời gian bú (phút)';

  @override
  String get rangeTitle => 'Khoảng thời gian';

  @override
  String get rangeCustom => 'Tuỳ chọn';

  @override
  String get rangeCustomHint => 'Chọn từ ngày – đến ngày';

  @override
  String rangeSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String get kpiPerFeed => 'TB mỗi cữ';

  @override
  String get milkPerDayTitle => 'Lượng sữa mỗi ngày';

  @override
  String milkPerDayHint(int days) {
    return 'Tổng ml bú bình · $days ngày';
  }

  @override
  String milkDayTip(String day, int ml, int count) {
    return '$day · $ml ml · $count cữ';
  }

  @override
  String mlAvgLine(int ml) {
    return 'TB $ml ml';
  }

  @override
  String get legendExpressedMilk => 'Sữa mẹ vắt';

  @override
  String get legendFormula => 'Sữa công thức';

  @override
  String get breastPerDayTitle => 'Thời gian bú mẹ mỗi ngày';

  @override
  String get breastPerDayHint => 'Tổng phút · bên trái và bên phải';

  @override
  String breastDayTip(String day, int minutes, int count) {
    return '$day · $minutes phút · $count cữ';
  }

  @override
  String minutesAvgLine(int minutes) {
    return 'TB $minutes phút';
  }

  @override
  String get legendLeftSide => 'Bên trái';

  @override
  String get legendRightSide => 'Bên phải';

  @override
  String get breastByTimeNote =>
      'Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú.';

  @override
  String minutesAndFeeds(int minutes, int count) {
    return '$minutes phút · $count cữ';
  }

  @override
  String lastNightBreastInsight(int count, int minutes, String time) {
    return 'Đêm qua bú mẹ $count cữ, $minutes phút ($time).';
  }

  @override
  String get tabCare => 'Chăm sóc';

  @override
  String get a11yOpenMe => 'Tôi';

  @override
  String get careTitle => 'Chăm sóc';

  @override
  String get careSearchHint => 'Tìm trong Chăm sóc…';

  @override
  String get careDaily => 'Chăm hằng ngày';

  @override
  String get careReminders => 'Nhắc nhở';

  @override
  String careRemindersOn(int count) {
    return '$count nhắc đang bật';
  }

  @override
  String careRemindersMine(int count) {
    return '$count nhắc giao cho bạn';
  }

  @override
  String get careStats => 'Thống kê';

  @override
  String get careStatsSub => 'Bú, ngủ theo ngày';

  @override
  String get careHistory => 'Lịch sử';

  @override
  String get careHistorySub => 'Mọi lần đã ghi';

  @override
  String get careGrowth => 'Tăng trưởng';

  @override
  String get careGrowthSub => 'Cân nặng, chiều dài';

  @override
  String get careSoon => 'Sớm ra mắt';

  @override
  String get careSoonToast => 'Phần này sẽ có trong bản cập nhật tới.';

  @override
  String get careWonderWeek => 'Wonder Weeks';

  @override
  String get careWonderWeekSub => 'Giai đoạn phát triển dự kiến';

  @override
  String get careAgeCards => 'Giai đoạn của bé';

  @override
  String get careAgeCardsSub => 'Gợi ý cho từng tuần, từng tháng';

  @override
  String get careMilestones => 'Mốc phát triển';

  @override
  String get careMilestonesSub => 'Ghi lại lần đầu của con';

  @override
  String get careLibrary => 'Thư viện chăm bé';

  @override
  String get careLibrarySub => 'Bài viết chăm bé theo tuổi';

  @override
  String get careSolids => 'Ăn dặm';

  @override
  String get careSolidsSub => 'Nhật ký & thư viện ăn dặm';

  @override
  String get careStatsPick => 'Xem thống kê';

  @override
  String get careNoResults => 'Không có mục nào khớp.';

  @override
  String get todayCustomize => 'Tuỳ chỉnh';

  @override
  String get customizeTitle => 'Tuỳ chỉnh Hôm nay';

  @override
  String get customizeIntro =>
      'Bật phần nào thì chọn luôn nội dung ngay bên dưới. Kéo tay nắm bên trái, hoặc nhấn giữ một dòng, để đổi thứ tự.';

  @override
  String get sectionTiles => 'Ô theo dõi nhanh';

  @override
  String get sectionTilesSub => 'Bú, ngủ, tã, hút sữa, tăng trưởng';

  @override
  String get sectionReminders => 'Nhắc việc sắp tới';

  @override
  String get sectionRhythm => 'Nhịp trong ngày';

  @override
  String get sectionRhythmSub => 'Biểu đồ 24 giờ';

  @override
  String get visibleTiles => 'Ô theo dõi hiển thị';

  @override
  String get customizeReset => 'Về mặc định';

  @override
  String get customizeDone => 'Xong';

  @override
  String get a11yDragToReorder => 'Kéo để sắp xếp';

  @override
  String get welcomeBody =>
      'Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời.';

  @override
  String get journeyFeed => 'Bú bình · 120 ml';

  @override
  String get journeyFeedWho => 'Mẹ ghi · 2 phút trước';

  @override
  String get journeySmile => 'Lần đầu con cười';

  @override
  String get journeySmileSaved => 'Đã lưu vào Kỷ niệm';

  @override
  String get journeyLove => 'Bà nội thương ảnh của Teddy';

  @override
  String get journeyStage1 => '0–12 tháng';

  @override
  String get journeyStage2 => '1–3 tuổi';

  @override
  String get journeyStage3 => '3–6 tuổi';

  @override
  String get journeyStage4 => '6–12 tuổi';

  @override
  String get a11yJourney =>
      'Hành trình lớn lên của con, từ năm đầu đời đến 12 tuổi';

  @override
  String get welcomeBackTitle => 'Chào mừng trở lại';

  @override
  String get welcomeBackBody => 'Đăng nhập để tiếp tục hành trình cùng con.';

  @override
  String get ruleTabRules => 'Theo quy tắc';

  @override
  String get ruleTabOnce => 'Một lần';

  @override
  String get ruleTitleFeed => 'Nhắc bú';

  @override
  String get ruleTitleSleep => 'Nhắc chuẩn bị ngủ';

  @override
  String get ruleTitleDiaper => 'Nhắc thay tã';

  @override
  String get ruleTitlePump => 'Nhắc hút sữa';

  @override
  String ruleAfterFeed(String duration) {
    return '$duration sau lần bú gần nhất';
  }

  @override
  String ruleAfterSleep(String duration) {
    return '$duration sau khi bé dậy';
  }

  @override
  String ruleAfterDiaper(String duration) {
    return '$duration sau lần thay gần nhất';
  }

  @override
  String ruleAfterPump(String duration) {
    return '$duration sau lần hút sữa gần nhất';
  }

  @override
  String ruleFixedLine(String times) {
    return 'Cố định $times';
  }

  @override
  String ruleNext(String when) {
    return 'Tiếp theo $when';
  }

  @override
  String get rulePaused => 'Đang tạm dừng';

  @override
  String ruleDueNow(String time) {
    return 'Đến giờ · $time';
  }

  @override
  String ruleSnoozedUntil(String time) {
    return 'Báo lại lúc $time';
  }

  @override
  String get ruleWaiting => 'Chờ lần ghi tiếp theo';

  @override
  String ruleRecipientsLine(String names) {
    return 'Người nhận: $names';
  }

  @override
  String get ruleYou => 'bạn';

  @override
  String get ruleAdd => 'Thêm nhắc';

  @override
  String get ruleEmpty => 'Chưa có nhắc theo quy tắc';

  @override
  String get ruleEmptyBody =>
      'Ví dụ: nhắc bú 3 giờ sau lần bú gần nhất, cho cả nhà.';

  @override
  String get ruleCaregiverNote =>
      'Ba mẹ đặt nhắc; bạn nhận những nhắc được giao cho mình.';

  @override
  String get ruleActFeed => 'lần bú';

  @override
  String get ruleActSleep => 'giấc ngủ';

  @override
  String get ruleActDiaper => 'lần thay tã';

  @override
  String get ruleActPump => 'lần hút sữa';

  @override
  String ruleHandled(String who, String activity, String time, String next) {
    return '$who đã ghi $activity lúc $time · nhắc tiếp theo $next';
  }

  @override
  String ruleHandledNoNext(String who, String activity, String time) {
    return '$who đã ghi $activity lúc $time';
  }

  @override
  String get ruleNewTitle => 'Nhắc mới';

  @override
  String get ruleEditTitle => 'Sửa nhắc';

  @override
  String get ruleWhat => 'Bạn muốn nhắc việc gì?';

  @override
  String get ruleTypeFeed => 'Bú';

  @override
  String get ruleTypeSleep => 'Ngủ';

  @override
  String get ruleTypeDiaper => 'Thay tã';

  @override
  String get ruleTypePump => 'Hút sữa';

  @override
  String get ruleHow => 'Cách nhắc';

  @override
  String get ruleModeAfter => 'Sau lần ghi gần nhất';

  @override
  String get ruleModeAfterHint => 'Ví dụ: 3 giờ sau lần bú gần nhất';

  @override
  String get ruleModeFixed => 'Giờ cố định';

  @override
  String get ruleModeFixedHint => 'Ví dụ: 09:00, 13:00, 19:30 mỗi ngày';

  @override
  String get ruleContinue => 'Tiếp tục';

  @override
  String ruleStep(int step) {
    return 'Bước $step/3';
  }

  @override
  String get ruleEvery => 'Nhắc sau mỗi';

  @override
  String get ruleCountedFeed => 'tính từ lần bú gần nhất (bú bình hoặc bú mẹ)';

  @override
  String get ruleCountedSleep => 'tính từ lúc bé thức dậy';

  @override
  String get ruleCountedDiaper => 'tính từ lần thay tã gần nhất';

  @override
  String get ruleCountedPump => 'tính từ lần hút sữa gần nhất';

  @override
  String get ruleExample => 'Ví dụ hôm nay';

  @override
  String get ruleExFeed => 'Bú';

  @override
  String get ruleExSleep => 'Dậy';

  @override
  String get ruleExDiaper => 'Thay tã';

  @override
  String get ruleExPump => 'Hút sữa';

  @override
  String ruleExampleLine(String act, String from, String to) {
    return '$act lúc $from → nhắc lúc $to';
  }

  @override
  String get ruleExampleNone =>
      'Chưa có lần ghi nào: nhắc bắt đầu sau lần ghi đầu tiên.';

  @override
  String ruleExampleShift(String activity) {
    return 'Ghi $activity mới thì giờ nhắc tự lùi theo.';
  }

  @override
  String get ruleQuiet => 'Không nhắc ban đêm';

  @override
  String get ruleQuietRange => '22:00 – 06:00';

  @override
  String get ruleDays => 'Ngày áp dụng';

  @override
  String get ruleEveryDay => 'Mỗi ngày';

  @override
  String get ruleTimesTitle => 'Giờ nhắc mỗi ngày';

  @override
  String get ruleSlotMorningNap => 'Giấc sáng';

  @override
  String get ruleSlotMiddayNap => 'Giấc trưa';

  @override
  String get ruleSlotAfternoonNap => 'Giấc chiều';

  @override
  String get ruleSlotNightSleep => 'Giấc đêm';

  @override
  String get ruleSlotMorning => 'Buổi sáng';

  @override
  String get ruleSlotMidday => 'Buổi trưa';

  @override
  String get ruleSlotAfternoon => 'Buổi chiều';

  @override
  String get ruleSlotEvening => 'Buổi tối';

  @override
  String get ruleAddTime => 'Thêm giờ';

  @override
  String ruleRemoveTime(String time) {
    return 'Xoá $time';
  }

  @override
  String get ruleTimeExists => 'Giờ này đã có trong danh sách.';

  @override
  String get ruleWeek => 'Ngày trong tuần';

  @override
  String ruleZoneNote(String zone) {
    return 'Nhắc theo giờ của bé ($zone). Khi đi xa, giờ nhắc vẫn giữ theo nơi bé ở.';
  }

  @override
  String get ruleWho => 'Ai sẽ nhận nhắc?';

  @override
  String get ruleRoleParent => 'Bố mẹ';

  @override
  String get ruleRoleCaregiver => 'Người chăm';

  @override
  String get ruleRoleViewOnly => 'Gia đình · chỉ xem';

  @override
  String get ruleWhoNote =>
      'Chỉ bố mẹ và người chăm nhận được nhắc. Ai ghi hoạt động trước, nhắc sẽ tự tắt với mọi người.';

  @override
  String get ruleAllDay => 'cả ngày';

  @override
  String get ruleNotAtNight => 'trừ ban đêm';

  @override
  String ruleRecipients(int count) {
    return '$count người nhận';
  }

  @override
  String get ruleSave => 'Lưu nhắc';

  @override
  String get ruleNeedRecipient => 'Chọn ít nhất một người nhận.';

  @override
  String get ruleSavedFeed => 'Đã lưu nhắc bú';

  @override
  String get ruleSavedSleep => 'Đã lưu nhắc chuẩn bị ngủ';

  @override
  String get ruleSavedDiaper => 'Đã lưu nhắc thay tã';

  @override
  String get ruleSavedPump => 'Đã lưu nhắc hút sữa';

  @override
  String get ruleSaveFailed => 'Chưa lưu được. Kiểm tra mạng rồi thử lại.';

  @override
  String get ruleDueFeed => 'Đến giờ nhắc bú bạn đã đặt';

  @override
  String get ruleDueSleep => 'Đến giờ nhắc chuẩn bị ngủ bạn đã đặt';

  @override
  String get ruleDueDiaper => 'Đến giờ nhắc thay tã bạn đã đặt';

  @override
  String get ruleDuePump => 'Đến giờ nhắc hút sữa bạn đã đặt';

  @override
  String get ruleLastFeed => 'Lần bú gần nhất';

  @override
  String get ruleLastSleep => 'Bé dậy lúc';

  @override
  String get ruleLastDiaper => 'Lần thay gần nhất';

  @override
  String get ruleLastPump => 'Lần hút sữa gần nhất';

  @override
  String get ruleLogFeed => 'Ghi lần bú';

  @override
  String get ruleLogSleep => 'Ghi giấc ngủ';

  @override
  String get ruleLogDiaper => 'Ghi thay tã';

  @override
  String get ruleLogPump => 'Ghi hút sữa';

  @override
  String get ruleSnoozeIn => 'Báo lại sau';

  @override
  String get ruleSkip => 'Bỏ qua lần này';

  @override
  String get ruleAlreadyHandled => 'Đã có người xử lý nhắc này.';

  @override
  String ruleSnoozedToast(String time) {
    return 'Sẽ nhắc lại lúc $time';
  }

  @override
  String get ruleSkippedToast => 'Đã bỏ qua lần này';

  @override
  String get ruleRecent => 'Gần đây';

  @override
  String get ruleRecentEmpty => 'Chưa có lần nhắc nào.';

  @override
  String ruleOutLogged(String time) {
    return '$time · Đã ghi';
  }

  @override
  String ruleOutSnoozed(String time, int minutes) {
    return '$time · Báo lại $minutes phút';
  }

  @override
  String ruleOutSkipped(String time) {
    return '$time · Bỏ qua';
  }

  @override
  String ruleOutMissed(String time) {
    return '$time · Chưa ai xử lý';
  }

  @override
  String ruleOutLoggedBy(String who, String what) {
    return '$who ghi $what';
  }

  @override
  String get ruleEdit => 'Sửa nhắc';

  @override
  String get ruleDelete => 'Xoá nhắc';

  @override
  String ruleDeleteTitle(String title) {
    return 'Xoá $title?';
  }

  @override
  String get ruleDeleteBody => 'Mọi người nhận sẽ thôi được nhắc.';

  @override
  String get ruleDeleteConfirm => 'Xoá';

  @override
  String get ruleDeleted => 'Đã xoá nhắc';

  @override
  String get reminderPeekTitle => 'Nhắc việc';

  @override
  String get photoByTitle => 'Xem ảnh theo';

  @override
  String get photoByWeek => 'Tuần tuổi';

  @override
  String get photoByWeekSub => 'Tuần 1, tuần 2… hợp với năm đầu đời';

  @override
  String get photoByAgeMonth => 'Tháng tuổi';

  @override
  String get photoByAgeMonthSub => '1 tháng, 2 tháng…';

  @override
  String get photoByMonth => 'Tháng trong năm';

  @override
  String get photoByMonthSub => 'Tháng 10, tháng 9…';

  @override
  String get photoPillWeek => 'Theo tuần tuổi';

  @override
  String get photoPillAgeMonth => 'Theo tháng tuổi';

  @override
  String get photoPillMonth => 'Theo tháng';

  @override
  String get photoShowTitle => 'Hiển thị';

  @override
  String get photoShowAll => 'Ảnh & video';

  @override
  String get photoShowPhotos => 'Chỉ ảnh';

  @override
  String get photoShowVideos => 'Chỉ video';

  @override
  String get photoShowFavorites => 'Đã yêu thích';

  @override
  String get photoGotoWeek => 'Đi tới tuần';

  @override
  String get photoGotoAgeMonth => 'Đi tới tháng tuổi';

  @override
  String photoAgeMonth(int month) {
    return 'Tháng thứ $month';
  }

  @override
  String photoScrubWeek(int week) {
    return 'Tuần $week';
  }

  @override
  String photoScrubAgeMonth(int month) {
    return 'Tháng $month';
  }

  @override
  String get photoSelectSection => 'Chọn tất cả';

  @override
  String get glanceGalleryCameraName => 'Chụp ảnh bé';

  @override
  String get glanceGalleryCameraBlurb =>
      'Mở camera để chụp ảnh hoặc quay video, rồi lưu vào Kỷ niệm.';

  @override
  String get glanceGalleryLibraryName => 'Thêm từ Ảnh';

  @override
  String get glanceGalleryLibraryBlurb =>
      'Chọn ảnh, video trong máy để lưu vào Kỷ niệm.';

  @override
  String get glanceMemCamera => 'Chụp ảnh, quay video';

  @override
  String get glanceMemLibrary => 'Thêm từ Ảnh';

  @override
  String glanceMemFor(String name) {
    return 'Vào Kỷ niệm của $name';
  }

  @override
  String get vxTile => 'Tiêm chủng';

  @override
  String vxTileNext(String date) {
    return 'Mũi tiếp theo $date';
  }

  @override
  String vxTileOverdue(int count) {
    return '$count mũi quá hạn';
  }

  @override
  String get vxTileAllDone => 'Đã tiêm đủ theo lịch';

  @override
  String get vxTileSetup => 'Ghi các mũi đã tiêm';

  @override
  String get vxTitle => 'Tiêm chủng';

  @override
  String vxNextLine(String date, String left) {
    return 'Mũi tiếp theo · $date · $left';
  }

  @override
  String vxDaysLeft(int count) {
    return 'còn $count ngày';
  }

  @override
  String get vxDueToday => 'hôm nay';

  @override
  String vxOverdueLine(int count, String date) {
    return 'Quá hạn $count ngày · dự kiến $date';
  }

  @override
  String vxDoseSuffix(int n) {
    return '(mũi $n)';
  }

  @override
  String vxDoseOf(String name, int n) {
    return '$name mũi $n';
  }

  @override
  String get vxViewByVaccine => 'Theo vắc xin';

  @override
  String get vxViewByAge => 'Theo tháng tuổi';

  @override
  String vxCount(int given, int total) {
    return 'Đã tiêm $given / $total mũi';
  }

  @override
  String get vxLegendGiven => 'Đã tiêm';

  @override
  String get vxLegendUpcoming => 'Sắp tới';

  @override
  String get vxLegendOverdue => 'Quá hạn';

  @override
  String get vxLegendLater => 'Chưa tới';

  @override
  String get vxLegendDeclined => 'Không tiêm';

  @override
  String vxMonthsShort(int months) {
    return '$months th';
  }

  @override
  String get vxBirth => 'Sơ sinh';

  @override
  String vxMonths(int months) {
    return '$months tháng';
  }

  @override
  String vxMonthsOld(int months) {
    return '$months tháng tuổi';
  }

  @override
  String get vxMilestoneBirth => 'Mốc sơ sinh';

  @override
  String vxMilestone(int months) {
    return 'Mốc $months tháng tuổi';
  }

  @override
  String vxMilestoneShort(int months) {
    return 'Mốc $months tháng';
  }

  @override
  String vxHintMonths(String list) {
    return '$list tháng';
  }

  @override
  String get vxHintYearly => 'hằng năm';

  @override
  String get vxBannerMatrix =>
      'Chạm vào một mũi để ghi đã tiêm hoặc xem chi tiết. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ.';

  @override
  String get vxBannerTimeline =>
      'Tích vào ô khi bé đã tiêm — app sẽ hỏi ngày và nơi tiêm. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ.';

  @override
  String vxOverdueCard(int count) {
    return '$count mũi đã quá ngày dự kiến. Nếu bé đã tiêm, hãy tích để cập nhật; nếu chưa, đặt lại lịch với cơ sở tiêm.';
  }

  @override
  String vxNoDob(String name) {
    return 'Cần ngày sinh của $name để lập lịch tiêm.';
  }

  @override
  String get vxNoDobBody => 'Ba mẹ thêm ngày sinh trong hồ sơ bé.';

  @override
  String get vxViewTitle => 'Xem lịch tiêm theo';

  @override
  String get vxViewByVaccineSub =>
      'Mỗi loại một dòng, thấy ngay mũi nào còn thiếu';

  @override
  String get vxViewByAgeSub => 'Từng mốc tuổi tiêm gì, tích khi đã tiêm';

  @override
  String get vxNoDate => 'Chưa ghi ngày';

  @override
  String vxSetupTitle(String name) {
    return '$name đã tiêm những mũi nào?';
  }

  @override
  String get vxSetupBody =>
      'Tích các mũi bé đã tiêm từ lúc sinh. Không nhớ ngày cũng không sao — bạn có thể bổ sung sau.';

  @override
  String get vxSetupAtHospital => 'Sơ sinh · thường tiêm tại bệnh viện';

  @override
  String get vxSetupFirstDay => 'Trong 24 giờ đầu';

  @override
  String vxSetupDue(String age, String date) {
    return '$age · dự kiến $date';
  }

  @override
  String vxSetupSave(int count) {
    return 'Lưu $count mũi đã tiêm';
  }

  @override
  String get vxSetupContinue => 'Tiếp tục';

  @override
  String get vxSetupSkip => 'Bỏ qua, làm sau';

  @override
  String vxPlannedLeft(String date, String left) {
    return 'Dự kiến $date · $left';
  }

  @override
  String vxPlannedOverdue(String date, int count) {
    return 'Dự kiến $date · đã quá $count ngày';
  }

  @override
  String get vxChooseOne => 'Chọn một trong hai';

  @override
  String get vx6in1Title => '6in1 · Dịch vụ';

  @override
  String get vx6in1Body =>
      'Bạch hầu, ho gà, uốn ván, bại liệt, Hib, viêm gan B — một mũi';

  @override
  String get vxPaid => 'Có phí';

  @override
  String get vx5in1Title => '5in1 + Bại liệt · Trạm y tế';

  @override
  String get vx5in1Body => 'Tiêm chủng mở rộng, uống/tiêm thêm bại liệt';

  @override
  String get vxFree => 'Miễn phí';

  @override
  String get vxShots => 'Các mũi';

  @override
  String get vxOtherShots => 'Các mũi khác';

  @override
  String get vxLog => 'Ghi';

  @override
  String get vxRouteOral => 'Uống';

  @override
  String get vxRouteInjection => 'Tiêm';

  @override
  String get vxProgEpi => 'Tiêm chủng mở rộng';

  @override
  String get vxProgService => 'Dịch vụ';

  @override
  String get vxProgHospital => 'Bệnh viện';

  @override
  String get vxProgChoice => '6in1 dịch vụ hoặc 5in1 miễn phí';

  @override
  String get vxRemind => 'Nhắc trước 3 ngày';

  @override
  String get vxRemindNobody => 'Chưa chọn người nhận';

  @override
  String get vxRecipientsTitle => 'Ai nhận nhắc lịch tiêm?';

  @override
  String get vxAppointment => 'Đặt lịch hẹn';

  @override
  String get vxAppointmentNone => 'Chưa đặt ngày hẹn';

  @override
  String vxAppointmentOn(String date) {
    return 'Hẹn $date';
  }

  @override
  String get vxAskDoctor =>
      'Hỏi bác sĩ hoặc nhân viên y tế để chọn loại vắc xin phù hợp với bé.';

  @override
  String vxGivenOn(String date) {
    return 'Đã tiêm $date';
  }

  @override
  String get vxRecordTitle => 'Ghi mũi tiêm';

  @override
  String get vxEditTitle => 'Sửa mũi tiêm';

  @override
  String get vxDate => 'Ngày tiêm';

  @override
  String get vxTime => 'Giờ';

  @override
  String get vxTimeNone => 'Không rõ';

  @override
  String get vxPlace => 'Nơi tiêm';

  @override
  String get vxPlaceHospital => 'Bệnh viện';

  @override
  String get vxPlaceService => 'Dịch vụ';

  @override
  String get vxPlaceStation => 'Trạm y tế';

  @override
  String get vxFacility => 'Tên cơ sở (không bắt buộc)';

  @override
  String get vxFacilityHint => 'VD: Trung tâm tiêm chủng gần nhà';

  @override
  String get vxReaction => 'Phản ứng sau tiêm (không bắt buộc)';

  @override
  String get vxReactionHint => 'Sốt nhẹ, quấy hơn…';

  @override
  String get vxSave => 'Lưu mũi tiêm';

  @override
  String vxSaved(String dose) {
    return 'Đã lưu $dose';
  }

  @override
  String vxSavedNext(String dose, int n, String date) {
    return 'Đã lưu $dose · mũi $n dự kiến $date';
  }

  @override
  String get vxSaveFailed => 'Chưa lưu được. Thử lại nhé.';

  @override
  String vxQuickTitle(String dose) {
    return 'Đã tiêm $dose';
  }

  @override
  String get vxWhichDay => 'Tiêm ngày nào?';

  @override
  String get vxDayToday => 'Hôm nay';

  @override
  String get vxDayYesterday => 'Hôm qua';

  @override
  String get vxPickDay => 'Chọn ngày';

  @override
  String get vxWhere => 'Tiêm ở đâu?';

  @override
  String get vxQuickSave => 'Lưu';

  @override
  String get vxMoreDetails => 'Thêm chi tiết (phản ứng, ảnh sổ tiêm)';

  @override
  String get vxRecordedBy => 'Người ghi';

  @override
  String get vxReactionShort => 'Phản ứng';

  @override
  String vxNextDose(int n, String date) {
    return 'Mũi $n dự kiến $date';
  }

  @override
  String get vxReminderOn => 'đã bật nhắc';

  @override
  String get vxReminderOff => 'chưa bật nhắc';

  @override
  String get vxDelete => 'Xoá mũi tiêm này';

  @override
  String vxDeleteTitle(String dose) {
    return 'Xoá $dose?';
  }

  @override
  String get vxDeleteBody => 'Mũi này sẽ trở lại chưa tiêm.';

  @override
  String get vxDeleteConfirm => 'Xoá';

  @override
  String vxDeleted(String dose) {
    return 'Đã xoá $dose';
  }

  @override
  String get vxReason => 'Lý do';

  @override
  String get vxUndoDecline => 'Bỏ đánh dấu không tiêm';

  @override
  String get vxUndoReschedule => 'Huỷ lịch hẹn';

  @override
  String get vxAddDate => 'Thêm ngày tiêm';

  @override
  String vxDoseCount(int count) {
    return '$count mũi';
  }

  @override
  String vxDoseCountOral(int count) {
    return '$count liều';
  }

  @override
  String get vxDoses => 'Số mũi';

  @override
  String get vxDosesOral => 'Số liều';

  @override
  String get vxTiming => 'Thời điểm';

  @override
  String vxTimingValue(String list) {
    return '$list tháng tuổi';
  }

  @override
  String get vxInterval => 'Khoảng cách';

  @override
  String vxIntervalValue(int weeks) {
    return 'Tối thiểu $weeks tuần giữa các mũi';
  }

  @override
  String get vxRoute => 'Cách dùng';

  @override
  String vxBabyDoses(String name) {
    return 'Các mũi của $name';
  }

  @override
  String vxDoseN(int n) {
    return 'Mũi $n';
  }

  @override
  String vxPlannedOn(String date) {
    return 'Dự kiến $date';
  }

  @override
  String get vxInfoBanner =>
      'Thông tin tham khảo. Hỏi bác sĩ nếu bạn còn băn khoăn.';

  @override
  String get vxAlreadyGiven => 'Bé đã tiêm rồi';

  @override
  String get vxAlreadyGivenSub => 'Ghi ngày và nơi tiêm';

  @override
  String get vxReschedule => 'Dời lịch';

  @override
  String get vxRescheduleSub => 'Chọn ngày hẹn mới, app nhắc lại trước 1 ngày';

  @override
  String get vxDecline => 'Không tiêm mũi này';

  @override
  String get vxDeclineSub => 'Theo tư vấn của bác sĩ · có thể ghi lý do';

  @override
  String get vxCatchUp =>
      'Hỏi cơ sở tiêm chủng hoặc bác sĩ để được hướng dẫn lịch tiêm bù phù hợp.';

  @override
  String vxDeclineTitle(String dose) {
    return 'Không tiêm $dose';
  }

  @override
  String get vxDeclineReasonHint => 'Lý do (không bắt buộc)';

  @override
  String vxDeclined(String dose) {
    return 'Đã ghi không tiêm $dose';
  }

  @override
  String vxRescheduled(String dose, String date) {
    return 'Đã dời $dose sang $date';
  }

  @override
  String get vxPickDateTitle => 'Chọn ngày';

  @override
  String get vxViewOnly => 'Bạn chỉ xem được sổ tiêm.';

  @override
  String get vxTileBook => 'Sổ tiêm chủng của bé';

  @override
  String get vxPhotoTake => 'Chụp sổ tiêm / phiếu tiêm';

  @override
  String get vxPhotoBook => 'Chụp sổ tiêm chủng để lưu lại';

  @override
  String get vxPhoto => 'Ảnh sổ tiêm';

  @override
  String get vxBookPhotos => 'Ảnh sổ tiêm chủng';

  @override
  String get vxPhotoAdd => 'Thêm ảnh sổ tiêm';

  @override
  String get vxPhotoUploading => 'Đang tải ảnh lên…';

  @override
  String get vxPhotoFailed => 'Chưa tải được ảnh. Thử lại nhé.';

  @override
  String get vxPhotoRemove => 'Bỏ ảnh';

  @override
  String get vxPhotoDelete => 'Xoá ảnh';

  @override
  String get vxPhotoDeleted => 'Đã xoá ảnh';

  @override
  String get vxPhotoPrivate =>
      'Chỉ người chăm bé trong gia đình xem được. Không hiện trong Kỷ niệm.';

  @override
  String get joinFromProfile => 'Nhập mã mời';

  @override
  String get joinFromProfileHint =>
      'Được mời chăm một bé khác? Nhập mã 6 số trong lời mời.';

  @override
  String get myInvitesTitle => 'Lời mời cho bạn';

  @override
  String myInviteLine(String inviter, String baby) {
    return '$inviter mời bạn cùng chăm bé $baby';
  }

  @override
  String myInviteMeta(String role, String date) {
    return '$role · Hết hạn $date';
  }

  @override
  String get myInviteAccept => 'Đồng ý';

  @override
  String get myInviteDecline => 'Từ chối';

  @override
  String myInviteDeclineTitle(String baby) {
    return 'Từ chối lời mời chăm bé $baby?';
  }

  @override
  String myInviteDeclineBody(String inviter) {
    return '$inviter sẽ biết lời mời không còn chờ nữa. Mã và link mời sẽ hết hiệu lực.';
  }

  @override
  String myInviteDeclined(String baby) {
    return 'Đã từ chối lời mời chăm bé $baby';
  }

  @override
  String get signInHaveCode => 'Tôi có mã mời';

  @override
  String get familyRevokeTitle => 'Huỷ lời mời này?';

  @override
  String familyRevokeBody(String who) {
    return 'Mã và link đã gửi cho $who sẽ không dùng được nữa.';
  }

  @override
  String get myInvitesPending => 'Lời mời đang chờ bạn';

  @override
  String get myInviteSheetTitle => 'Lời mời cùng chăm bé';

  @override
  String myInviteSheetHint(String baby) {
    return 'Đồng ý xong, $baby sẽ có trong danh sách bé của bạn.';
  }

  @override
  String get spTitle => 'Chi tiêu';

  @override
  String spTileMonth(String amount) {
    return '$amount tháng này';
  }

  @override
  String get spTileEmpty => 'Chưa ghi tháng này';

  @override
  String get spTileRecord => 'Ghi khoản đã chi';

  @override
  String spMillions(String value) {
    return '$value tr';
  }

  @override
  String get spCurrencyName => 'đồng';

  @override
  String get spCurrency => 'Tiền tệ';

  @override
  String get spCurrencyTitle => 'Chọn tiền tệ';

  @override
  String spCurrencyPick(String code) {
    return 'Đổi tiền tệ, đang là $code';
  }

  @override
  String get spCurrencyMain => 'Tiền tệ chính';

  @override
  String get spCurrencyMainSub =>
      'Mặc định khi thêm khoản chi; tổng, thống kê và ngân sách tính theo tiền tệ này. Khoản chi bằng tiền tệ khác được ghi riêng, không quy đổi.';

  @override
  String get spCurrencyMainSaved => 'Đã đổi tiền tệ chính';

  @override
  String spAlsoSpent(String amounts) {
    return 'Ngoài ra: $amounts';
  }

  @override
  String spOtherCurrenciesNote(String amounts) {
    return 'Không cộng vào tổng (tiền tệ khác): $amounts';
  }

  @override
  String spBudgetCurrencyNote(String code) {
    return 'Ngân sách tính các khoản chi bằng $code.';
  }

  @override
  String spBudgetOldCurrency(String old, String code) {
    return 'Ngân sách đang lưu theo $old. Đặt lại số tiền rồi lưu để tính theo $code.';
  }

  @override
  String get spCurVND => 'Đồng Việt Nam';

  @override
  String get spCurUSD => 'Đô la Mỹ';

  @override
  String get spCurEUR => 'Euro';

  @override
  String get spCurGBP => 'Bảng Anh';

  @override
  String get spCurAUD => 'Đô la Úc';

  @override
  String get spCurCAD => 'Đô la Canada';

  @override
  String get spCurNZD => 'Đô la New Zealand';

  @override
  String get spCurSGD => 'Đô la Singapore';

  @override
  String get spCurJPY => 'Yên Nhật';

  @override
  String get spCurKRW => 'Won Hàn Quốc';

  @override
  String get spCurTWD => 'Đô la Đài Loan';

  @override
  String get spCurTHB => 'Baht Thái';

  @override
  String get spCurHKD => 'Đô la Hồng Kông';

  @override
  String get spCurCNY => 'Nhân dân tệ';

  @override
  String get spCurCHF => 'Franc Thuỵ Sĩ';

  @override
  String get spCurMYR => 'Ringgit Malaysia';

  @override
  String get spCatChildcare => 'Giữ trẻ & học';

  @override
  String get spCatMilk => 'Sữa & ăn dặm';

  @override
  String get spCatDiaper => 'Tã & vệ sinh';

  @override
  String get spCatHealth => 'Y tế & tiêm chủng';

  @override
  String get spCatClothes => 'Quần áo';

  @override
  String get spCatOther => 'Khác';

  @override
  String get spToday => 'Hôm nay';

  @override
  String get spYesterday => 'Hôm qua';

  @override
  String spDayToday(String date) {
    return 'Hôm nay · $date';
  }

  @override
  String spDayYesterday(String date) {
    return 'Hôm qua · $date';
  }

  @override
  String spDateToday(String date) {
    return 'Hôm nay, $date';
  }

  @override
  String spDateYesterday(String date) {
    return 'Hôm qua, $date';
  }

  @override
  String get spPayerOther => 'Khác';

  @override
  String spPaidBy(String payer) {
    return '$payer trả';
  }

  @override
  String spPays(String payer) {
    return '$payer trả';
  }

  @override
  String get spFromVaccines => 'từ Tiêm chủng';

  @override
  String get spFromRecurring => 'định kỳ';

  @override
  String get spFromRecurringFull => 'Khoản định kỳ';

  @override
  String spScheduleMonthly(int day) {
    return 'Ngày $day hằng tháng';
  }

  @override
  String spScheduleMonthlyTwo(int a, int b) {
    return 'Ngày $a và $b hằng tháng';
  }

  @override
  String spScheduleWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mỗi $n tuần',
      one: 'Mỗi tuần',
    );
    return '$_temp0';
  }

  @override
  String spScheduleYearly(String date) {
    return 'Ngày $date hằng năm';
  }

  @override
  String get spPending => 'Chờ đồng bộ';

  @override
  String get spHasReceipt => 'Có hoá đơn';

  @override
  String get spNoAccess =>
      'Chi tiêu của bé chỉ cha mẹ xem. Nhờ Cùng nuôi cấp quyền trong Gia đình nếu bạn cần ghi.';

  @override
  String spFirstTitle(String name) {
    return 'Ghi lại chi tiêu cho $name';
  }

  @override
  String get spFirstBody =>
      'Biết mỗi tháng tốn bao nhiêu cho sữa, tã, tiêm chủng, giữ trẻ. Chỉ cha mẹ thấy, có thể chia sẻ cho người khác.';

  @override
  String get spFirstBodyRecorder =>
      'Ghi các khoản bạn đã chi cho bé. Bạn chỉ thấy những khoản do mình ghi.';

  @override
  String get spFirstPoint1 => 'Ghi nhanh trong vài giây';

  @override
  String get spFirstPoint2 => 'Thống kê theo tháng, danh mục, người trả';

  @override
  String get spFirstPoint3 => 'Ngân sách và khoản định kỳ';

  @override
  String get spFirstAdd => 'Thêm khoản chi đầu tiên';

  @override
  String get spFirstBudget => 'Đặt ngân sách';

  @override
  String get spAdd => 'Thêm khoản chi';

  @override
  String get spOwnOnlyNote =>
      'Bạn chỉ thấy các khoản do mình ghi, không thấy tổng hay khoản của người khác.';

  @override
  String get spMine => 'Khoản bạn đã ghi';

  @override
  String get spPrevMonth => 'Tháng trước';

  @override
  String get spNextMonth => 'Tháng sau';

  @override
  String spMonthLabel(int month, int year) {
    return 'Tháng $month · $year';
  }

  @override
  String spMonthShort(int month, int year) {
    return 'Tháng $month';
  }

  @override
  String spUpTo(String date) {
    return 'Đến $date';
  }

  @override
  String spSpentOn(String name) {
    return 'Đã chi cho $name';
  }

  @override
  String get spStats => 'Thống kê';

  @override
  String get spBudget => 'Ngân sách';

  @override
  String get spRecurring => 'Định kỳ';

  @override
  String get spByCategory => 'Theo danh mục';

  @override
  String get spSeeStats => 'Xem thống kê';

  @override
  String get spMonthEmpty => 'Chưa có khoản chi nào trong tháng này.';

  @override
  String spItems(int n) {
    return '$n khoản';
  }

  @override
  String spIncludesShots(int n) {
    return 'Gồm $n mũi tiêm';
  }

  @override
  String get spRecent => 'Gần đây';

  @override
  String get spSeeAll => 'Xem tất cả';

  @override
  String get spParentsOnly =>
      'Chỉ cha mẹ thấy chi tiêu. Có thể cấp quyền cho người khác trong Gia đình.';

  @override
  String get spSharedWithYou => 'Cha mẹ đã chia sẻ chi tiêu của bé với bạn.';

  @override
  String spBudgetShare(String share, String total) {
    return '$share ngân sách $total';
  }

  @override
  String spLeft(String amount) {
    return 'Còn $amount';
  }

  @override
  String spOverBy(String amount) {
    return 'Vượt $amount';
  }

  @override
  String get spAvgPerDay => 'Trung bình/ngày';

  @override
  String get spSame => 'Bằng';

  @override
  String spLower(String share) {
    return 'Thấp hơn $share';
  }

  @override
  String spHigher(String share) {
    return 'Cao hơn $share';
  }

  @override
  String spComparedWith(int month) {
    return 'So với tháng $month';
  }

  @override
  String get spAllTitle => 'Tất cả khoản chi';

  @override
  String get spSearch => 'Tìm khoản chi…';

  @override
  String get spAllMonths => 'Mọi tháng';

  @override
  String get spFilterMonth => 'Chọn tháng';

  @override
  String get spAllCategories => 'Tất cả danh mục';

  @override
  String get spAnyone => 'Ai cũng được';

  @override
  String get spNothingYet => 'Chưa có khoản chi nào.';

  @override
  String get spNoMatch => 'Không có khoản chi nào khớp.';

  @override
  String get spGone => 'Khoản chi này không còn.';

  @override
  String get spCategory => 'Danh mục';

  @override
  String get spDate => 'Ngày';

  @override
  String get spPayer => 'Ai trả';

  @override
  String get spRecordedBy => 'Ghi bởi';

  @override
  String get spSource => 'Nguồn';

  @override
  String get spLink => 'Liên kết';

  @override
  String spLinkVaccine(String dose) {
    return 'Lịch tiêm chủng · $dose';
  }

  @override
  String get spReceiptTitle => 'Hoá đơn';

  @override
  String get spReceiptOpen => 'Chạm để xem ảnh lớn';

  @override
  String get spDelete => 'Xoá khoản chi';

  @override
  String get spDeleted => 'Đã xoá khoản chi';

  @override
  String get spAddTitle => 'Thêm khoản chi';

  @override
  String get spEditTitle => 'Sửa khoản chi';

  @override
  String get spAmount => 'Số tiền';

  @override
  String spLastTime(String amount) {
    return 'Lần trước $amount';
  }

  @override
  String get spEditCategories => 'Sửa danh mục';

  @override
  String get spAddCategoryChip => 'Danh mục';

  @override
  String get spNote => 'Nội dung';

  @override
  String get spNoteHint => 'Ví dụ: Sữa công thức ×2';

  @override
  String get spReceipt => 'Ảnh hoá đơn';

  @override
  String get spReceiptAttached => 'Đã đính kèm · chạm để xem';

  @override
  String get spReceiptRemove => 'Bỏ ảnh hoá đơn';

  @override
  String get spReceiptAdd => 'Thêm ảnh hoá đơn';

  @override
  String get spReceiptPrivate => 'Chỉ người xem được chi tiêu thấy ảnh này.';

  @override
  String get spRepeatMonthly => 'Lặp lại hằng tháng';

  @override
  String spRepeatMonthlyOn(int day) {
    return 'Tự thêm ngày $day mỗi tháng';
  }

  @override
  String get spSave => 'Lưu khoản chi';

  @override
  String get spSaved => 'Đã lưu khoản chi';

  @override
  String get spUpdated => 'Đã cập nhật khoản chi';

  @override
  String get spAmountMissing => 'Nhập số tiền';

  @override
  String get spSaveFailed => 'Chưa lưu được. Thử lại sau.';

  @override
  String get spVaccineTitle => 'Ghi chi phí mũi tiêm?';

  @override
  String get spVaccineBody =>
      'Lưu vào Chi tiêu, danh mục Y tế & tiêm chủng. Có thể bỏ qua.';

  @override
  String get spVaccineSave => 'Lưu vào Chi tiêu';

  @override
  String get spVaccineSaved => 'Đã lưu chi phí mũi tiêm';

  @override
  String get spSkip => 'Bỏ qua';

  @override
  String get spCategories => 'Danh mục';

  @override
  String get spCategoriesIntro =>
      'Kéo để sắp xếp. Danh mục dùng chung cho mọi bé trong gia đình.';

  @override
  String get spCategoriesInUse => 'Đang dùng';

  @override
  String get spCategoriesHidden => 'Đã ẩn';

  @override
  String get spCategoryLocked => 'Mặc định · không xoá được';

  @override
  String spCategoryCustom(int n) {
    return 'Tự tạo · $n khoản';
  }

  @override
  String spCategoryHiddenSub(int n) {
    return 'Ẩn khỏi danh sách chọn · vẫn giữ $n khoản cũ';
  }

  @override
  String get spShowAgain => 'Hiện lại';

  @override
  String get spDragHandle => 'Kéo để sắp xếp';

  @override
  String get spAddCategory => 'Thêm danh mục';

  @override
  String get spNewCategory => 'Danh mục mới';

  @override
  String get spEditCategory => 'Sửa danh mục';

  @override
  String get spCategoryName => 'Tên danh mục';

  @override
  String get spCategoryNamePlaceholder => 'Ví dụ: Bơi & vận động';

  @override
  String get spCategoryNameHelp => 'Tối đa 24 ký tự';

  @override
  String get spCategoryNameMissing => 'Nhập tên danh mục';

  @override
  String get spCategoryNameTaken => 'Đã có danh mục tên này';

  @override
  String get spCategoryIcon => 'Biểu tượng';

  @override
  String get spCategoryColor => 'Màu';

  @override
  String spColorN(int n) {
    return 'Màu $n';
  }

  @override
  String get spSaveCategory => 'Lưu danh mục';

  @override
  String get spHideCategory => 'Ẩn danh mục';

  @override
  String get spCategoryHiddenToast => 'Đã ẩn danh mục';

  @override
  String get spDeleteCategory => 'Xoá danh mục';

  @override
  String spDeleteCategoryTitle(String name) {
    return 'Xoá “$name”?';
  }

  @override
  String spDeleteCategoryBody(int n, String amount) {
    return 'Danh mục này có $n khoản chi ($amount). Chọn nơi chuyển các khoản này:';
  }

  @override
  String get spDeleteCategoryEmpty =>
      'Danh mục này chưa có khoản chi nào của bé. Khoản của bé khác (nếu có) sẽ được chuyển sang:';

  @override
  String get spMoveToOther => 'Chuyển sang “Khác”';

  @override
  String get spMoveToOtherSub => 'Giữ nguyên tổng chi tiêu';

  @override
  String get spMoveToAnother => 'Chuyển sang danh mục khác';

  @override
  String get spChooseCategory => 'Chọn danh mục';

  @override
  String get spHideInstead =>
      'Muốn giữ số liệu cũ mà không thấy danh mục khi ghi? Hãy chọn Ẩn thay vì Xoá.';

  @override
  String spDeleteAndMove(int n) {
    return 'Xoá và chuyển $n khoản';
  }

  @override
  String get spHideCategoryInstead => 'Ẩn danh mục thay vì xoá';

  @override
  String get spCategoryDeleted => 'Đã xoá danh mục';

  @override
  String get spNeedsNetwork => 'Cần kết nối mạng để xoá danh mục.';

  @override
  String get spBudgetTitle => 'Ngân sách tháng';

  @override
  String get spBudgetIntro =>
      'Đặt mức dự kiến để dễ theo dõi. Có thể bỏ trống danh mục.';

  @override
  String get spBudgetPerMonth => 'Ngân sách mỗi tháng';

  @override
  String spBudgetUsed(int month, String share) {
    return 'Tháng $month: đã dùng $share';
  }

  @override
  String get spNoCap => 'Chưa đặt mức';

  @override
  String get spClearCap => 'Bỏ mức này';

  @override
  String spUsedShare(String share) {
    return '$share đã dùng';
  }

  @override
  String spNearCap(String amount) {
    return 'Gần chạm mức · còn $amount';
  }

  @override
  String spOverCap(String amount) {
    return 'Vượt mức $amount';
  }

  @override
  String get spAlert80 => 'Nhắc khi dùng 80% ngân sách';

  @override
  String get spAlert80Sub => 'Gửi cho cha mẹ';

  @override
  String get spSaveBudget => 'Lưu ngân sách';

  @override
  String get spBudgetSaved => 'Đã lưu ngân sách';

  @override
  String get spRecurringTitle => 'Khoản định kỳ';

  @override
  String get spRecurringIntro =>
      'Tự thêm vào chi tiêu đúng ngày. Cha mẹ nhận thông báo và có thể sửa số tiền sau đó.';

  @override
  String get spRecurringEmpty =>
      'Chưa có khoản định kỳ. Thêm tiền giữ trẻ, sữa hay bảo hiểm để khỏi phải ghi lại mỗi lần.';

  @override
  String spRecurringNext(String date, String title, String amount) {
    return 'Ngày $date: $title $amount sẽ được thêm. Bạn có thể sửa số tiền sau khi thêm.';
  }

  @override
  String get spAddRecurring => 'Thêm khoản định kỳ';

  @override
  String get spEditRecurring => 'Sửa khoản định kỳ';

  @override
  String get spRecurringName => 'Tên khoản';

  @override
  String get spRecurringNameHint => 'Ví dụ: Cô giữ trẻ';

  @override
  String get spRecurringTitleMissing => 'Nhập tên khoản';

  @override
  String get spSchedule => 'Lặp lại';

  @override
  String get spKindMonthly => 'Hằng tháng';

  @override
  String get spKindWeeks => 'Theo tuần';

  @override
  String get spKindYearly => 'Hằng năm';

  @override
  String get spScheduleDays => 'Ngày trong tháng';

  @override
  String get spScheduleDaysHelp =>
      'Chọn 1 hoặc 2 ngày. Tháng ngắn hơn sẽ dùng ngày cuối tháng.';

  @override
  String get spStartOn => 'Bắt đầu từ';

  @override
  String get spScheduleOn => 'Ngày';

  @override
  String get spRecurringOn => 'Đang bật';

  @override
  String get spRecurringHelp =>
      'Khoản được thêm tự động vào ngày đến hạn, theo giờ của bé.';

  @override
  String get spDeleteRecurring => 'Xoá khoản định kỳ';

  @override
  String get spRecurringSaved => 'Đã lưu khoản định kỳ';

  @override
  String get spRecurringDeleted => 'Đã xoá khoản định kỳ';

  @override
  String get spLess => 'Bớt';

  @override
  String get spMore => 'Thêm';

  @override
  String get spStatsTitle => 'Thống kê chi tiêu';

  @override
  String get spWindowMonth => 'Tháng';

  @override
  String get spWindowSix => '6 tháng';

  @override
  String get spWindowBirth => 'Từ khi sinh';

  @override
  String get spMonthTotal => 'Tổng tháng này';

  @override
  String get spCount => 'Khoản chi';

  @override
  String get spSixTotal => 'Tổng 6 tháng';

  @override
  String get spAvgPerMonth => 'TB mỗi tháng';

  @override
  String spHighest(int month) {
    return 'Cao nhất · T$month';
  }

  @override
  String get spByMonth => 'Theo tháng';

  @override
  String spCountedTo(int month, String date) {
    return 'T$month đang tính đến $date';
  }

  @override
  String spMonthTick(int month) {
    return 'T$month';
  }

  @override
  String spAvgLine(String amount) {
    return 'TB $amount';
  }

  @override
  String spTip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get spOthersFolded => 'Khác';

  @override
  String spSinceBirth(String name, int months) {
    return 'Từ khi $name chào đời · $months tháng';
  }

  @override
  String get spSinceFirst => 'Từ khoản chi đầu tiên';

  @override
  String spSinceBirthSub(String amount, int n) {
    return 'Trung bình $amount mỗi tháng tuổi · $n khoản chi';
  }

  @override
  String get spByAge => 'Theo tháng tuổi';

  @override
  String get spFirstMonth => 'Tháng đầu';

  @override
  String spAgeMonth(int n) {
    return 'Tháng tuổi $n';
  }

  @override
  String get spLargest => 'Khoản lớn nhất';

  @override
  String get spExport => 'Xuất file chi tiêu (CSV)';

  @override
  String spExportFile(String date) {
    return 'chi-tieu-$date';
  }

  @override
  String get spExportFailed => 'Chưa xuất được file. Thử lại sau.';

  @override
  String get spOwnFamilyOnly =>
      'Số liệu chỉ để gia đình tự theo dõi, không so sánh với gia đình khác.';

  @override
  String get rightRecordSpending => 'Ghi khoản đã chi';

  @override
  String get rightRecordSpendingHint => 'Chỉ thấy khoản do mình ghi';

  @override
  String get rightViewSpending => 'Xem toàn bộ chi tiêu';

  @override
  String get rightViewSpendingHint => 'Tổng, thống kê, mọi khoản chi';

  @override
  String get rightSpendingNote =>
      'Chi tiêu mặc định chỉ cha mẹ thấy. Người được bật “Ghi khoản đã chi” sẽ không thấy tổng hay khoản của người khác.';

  @override
  String spSinceBirthYoung(String name) {
    return 'Từ khi $name chào đời';
  }

  @override
  String get sectionQuickActions => 'Tạo nhanh';

  @override
  String get sectionQuickActionsSub => 'Nhắc nhở, chi tiêu, mũi tiêm, kỷ niệm';

  @override
  String get sectionVaccine => 'Mũi tiêm sắp tới';

  @override
  String get sectionVaccineSub => 'Từ sổ tiêm chủng của bé';

  @override
  String get sectionSpending => 'Chi tiêu tháng này';

  @override
  String get sectionSpendingSub => 'Tổng tháng so với ngân sách';

  @override
  String get quickReminder => 'Nhắc nhở';

  @override
  String get quickExpense => 'Chi tiêu';

  @override
  String get quickVaccine => 'Mũi tiêm';

  @override
  String get quickMemory => 'Kỷ niệm';

  @override
  String get quickReminderHint => 'Tạo nhắc việc mới';

  @override
  String get quickExpenseHint => 'Ghi khoản đã chi';

  @override
  String get quickVaccineHint => 'Mở sổ tiêm chủng';

  @override
  String get quickMemoryHint => 'Ảnh, video, nhật ký';

  @override
  String todayVaccineShots(int n) {
    return '$n mũi · chạm để xem';
  }

  @override
  String get todayVaccineOpen => 'Mở sổ tiêm chủng';

  @override
  String get todaySpendingNoBudget => 'Chưa đặt ngân sách tháng';

  @override
  String acExportEmailed(String when) {
    return 'Đã gửi link tải qua email · hết hạn $when';
  }

  @override
  String get faEntryTitle => 'Sơ cứu trẻ em';

  @override
  String faEntrySub(int count) {
    return '$count tình huống · dùng khi không có mạng';
  }

  @override
  String get faTitle => 'Sơ cứu';

  @override
  String get faSubtitle =>
      'Bình tĩnh, làm theo từng bước. Dùng được cả khi không có mạng.';

  @override
  String get faEmergencyQuestion => 'Bé không thở, tím tái hoặc bất tỉnh?';

  @override
  String faCall(String number) {
    return 'Gọi $number';
  }

  @override
  String faCallLocal(String number, String country) {
    return 'Gọi $number · $country';
  }

  @override
  String vxAbroadNotice(String country) {
    return 'Lịch này theo chương trình tiêm chủng của Việt Nam. Ở $country, hãy theo lịch của bác sĩ hoặc cơ sở y tế nơi bạn sống; nhắc lịch chỉ báo những mũi bạn đã đặt ngày.';
  }

  @override
  String get faStartCpr => 'Bắt đầu hồi sức tim phổi (CPR)';

  @override
  String get faSearchHint => 'Hóc, sốt, bỏng, khó thở…';

  @override
  String get faAll => 'Tất cả';

  @override
  String faSortedFor(String name, String age) {
    return 'Sắp xếp theo tuổi $name · $age';
  }

  @override
  String get faSaved => 'Đã lưu';

  @override
  String get faSavedEmpty =>
      'Chưa lưu tình huống nào. Bấm dấu trang trên một tình huống để lưu lại đây.';

  @override
  String get faSave => 'Lưu tình huống';

  @override
  String get faUnsave => 'Bỏ lưu';

  @override
  String get faSavedToast => 'Đã lưu vào Sơ cứu · Đã lưu';

  @override
  String get faUnsavedToast => 'Đã bỏ lưu';

  @override
  String faResults(int count) {
    return '$count tình huống';
  }

  @override
  String get faQuickSearch => 'Tìm nhanh';

  @override
  String faNoResults(String number) {
    return 'Không tìm thấy tình huống phù hợp. Bé gặp nguy hiểm: gọi $number.';
  }

  @override
  String get faOffline => 'Dùng được khi không có mạng';

  @override
  String get faMonitoring => 'Theo dõi';

  @override
  String get faFollowSteps => 'Làm theo các bước';

  @override
  String get faDisclaimer =>
      'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.';

  @override
  String faReviewed(String reviewer, String month) {
    return 'Được $reviewer rà soát tháng $month.';
  }

  @override
  String get faSeizureTimer => 'Bấm giờ cơn giật';

  @override
  String get faTimerStart => 'Bắt đầu';

  @override
  String get faTimerStop => 'Dừng';

  @override
  String get faTimerReset => 'Bấm lại';

  @override
  String faCallFailed(String number) {
    return 'Không mở được trình gọi điện. Hãy bấm số $number trên điện thoại.';
  }

  @override
  String faWeightKg(String kg) {
    return '$kg kg';
  }

  @override
  String get faNotFound => 'Không tìm thấy hướng dẫn này. Mở lại Sơ cứu.';

  @override
  String get faReadAloud => 'Đọc to hướng dẫn';

  @override
  String get faReadAloudShort => 'Đọc to';

  @override
  String get faStopReading => 'Dừng đọc';

  @override
  String faCountTimes(int count) {
    return '× $count lần';
  }

  @override
  String faCalling(String number, String time) {
    return 'Đang gọi $number · $time';
  }

  @override
  String get faTellOperator => 'Nói với tổng đài';

  @override
  String get faTellBaby => 'Bé';

  @override
  String get faTellCondition => 'Tình trạng';

  @override
  String get faMetronomeTitle => 'Nhịp ép đang phát · tự động';

  @override
  String get faMetronomePaused => 'Nhịp ép tạm dừng trong lúc đọc';

  @override
  String faMetronomeBody(int count, int breaths) {
    return 'Bật loa, đặt điện thoại cạnh bé. Ép theo tiếng bíp. Sau mỗi $count lần, app đọc “thổi ngạt $breaths lần”.';
  }

  @override
  String faSayBreaths(int count) {
    return 'Thổi ngạt $count lần';
  }

  @override
  String faSpeakStep(int n, String title, String body) {
    return 'Bước $n. $title. $body';
  }

  @override
  String get tabUtilities => 'Tiện ích';

  @override
  String get utTitle => 'Tiện ích';

  @override
  String utSpendingMonth(String amount) {
    return 'Tháng này $amount';
  }

  @override
  String get utMySpending => 'Khoản tôi đã chi';

  @override
  String get utMySpendingSub => 'Bạn được phép ghi khoản chi';

  @override
  String get utMembers => 'Thành viên & chia sẻ';

  @override
  String utMembersCount(int count) {
    return '$count người';
  }

  @override
  String utMembersPending(int count) {
    return '$count lời mời đang chờ';
  }

  @override
  String get utMembersView => 'Xem thành viên gia đình';

  @override
  String get utInvite => 'Mời người thân';

  @override
  String get utInviteSub => 'Ông bà, người chăm cùng theo dõi bé';

  @override
  String get inviteLinkJoining => 'Đang nhận lời mời…';

  @override
  String inviteLinkJoined(String baby) {
    return 'Bạn đã cùng chăm $baby. Đổi tên trong Gia đình.';
  }

  @override
  String get inviteLinkDefaultName => 'Người thân';

  @override
  String meVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get upRequiredTitle => 'Cần cập nhật để tiếp tục';

  @override
  String get upRequiredBody =>
      'Phiên bản này đã cũ và không còn đồng bộ an toàn với cả nhà. Cập nhật mất khoảng 1 phút.';

  @override
  String get upSafeTitle => 'Dữ liệu của bé vẫn an toàn';

  @override
  String get upSafeBody => 'Ảnh, nhật ký và lịch sử chăm sóc được giữ nguyên';

  @override
  String upPendingTitle(int count) {
    return '$count lần ghi chưa đồng bộ';
  }

  @override
  String get upPendingBody => 'Sẽ tự gửi lên ngay sau khi cập nhật';

  @override
  String get upOpenAppStore => 'Cập nhật trên App Store';

  @override
  String get upOpenPlay => 'Cập nhật trên Google Play';

  @override
  String upWhatsNewIn(String version) {
    return 'Có gì mới trong $version';
  }

  @override
  String upNewTag(String version) {
    return 'Mới · $version';
  }

  @override
  String get upNewTitle => 'Child Life có bản mới';

  @override
  String get upUpdate => 'Cập nhật';

  @override
  String get upLater => 'Để sau';

  @override
  String upPageTag(String version) {
    return 'Mới trong $version';
  }

  @override
  String get upSkip => 'Bỏ qua';

  @override
  String get upNext => 'Tiếp';

  @override
  String get upPagesDone => 'Xong';

  @override
  String upPageOf(int page, int count) {
    return 'Trang $page trên $count';
  }

  @override
  String upBannerTitle(String version) {
    return 'Đã cập nhật $version';
  }

  @override
  String get upBannerSee => 'Xem';

  @override
  String get upBannerClose => 'Đóng thông báo cập nhật';

  @override
  String upNewVersion(String version) {
    return 'Có bản mới $version';
  }

  @override
  String get upLatestVersion => 'Đây là bản mới nhất';

  @override
  String get upNoStore => 'Chưa mở được trang cập nhật. Thử lại sau nhé.';

  @override
  String get spFirstImport => 'Nhập từ app khác hoặc Excel';

  @override
  String get spFromImport => 'nhập từ tệp';

  @override
  String get spFromAssistant => 'từ Trợ lý';

  @override
  String get spFromImportFull => 'Nhập chi tiêu · xem lần nhập';

  @override
  String get imTitle => 'Nhập chi tiêu';

  @override
  String imIntro(String name) {
    return 'Mang chi tiêu từ app khác, bảng tính hoặc sổ tay vào Chi tiêu của $name. Bạn xem trước rồi mới nhập.';
  }

  @override
  String get imParentsOnly => 'Chỉ Cùng nuôi được nhập chi tiêu.';

  @override
  String get imSourceFile => 'Tệp CSV hoặc Excel';

  @override
  String get imSourceFileHint =>
      'Money Lover, MISA, Google Sheets, Excel… tự nhận cột';

  @override
  String get imSourceText => 'Dán văn bản';

  @override
  String get imSourceTextHint =>
      'Ghi chú, tin nhắn, danh sách — AI tách thành từng khoản';

  @override
  String get imSourcePhotos => 'Ảnh chụp sổ chi tiêu';

  @override
  String get imSourcePhotosHint => 'Tối đa 5 ảnh — AI đọc từng dòng';

  @override
  String get imPrivacy =>
      'Văn bản và ảnh được gửi tới dịch vụ AI chỉ để đọc, không lưu lại; tên bé không được gửi. Tệp tải lên tự xoá sau 7 ngày.';

  @override
  String get imRecent => 'Các lần nhập';

  @override
  String get imBusyReading => 'Đang đọc dữ liệu…';

  @override
  String get imBusyAi => 'AI đang đọc, có thể mất nửa phút…';

  @override
  String get imPasteHint =>
      'Mỗi khoản một dòng, ví dụ: “12/10 sữa công thức 1.020.000 mẹ trả”.';

  @override
  String get imPastePlaceholder => 'Dán nội dung ở đây';

  @override
  String get imRead => 'Đọc nội dung';

  @override
  String get imReviewTitle => 'Xem trước';

  @override
  String imDuplicates(int n) {
    return '$n khoản trùng';
  }

  @override
  String imIncome(int n) {
    return '$n khoản thu';
  }

  @override
  String imErrors(int n) {
    return '$n dòng lỗi';
  }

  @override
  String get imColumns => 'Cột trong tệp';

  @override
  String get imColumnNone => 'Không có';

  @override
  String get imDateOrder => 'Ngày viết theo kiểu';

  @override
  String get imDateDmy => 'Ngày/Tháng/Năm';

  @override
  String get imDateMdy => 'Tháng/Ngày/Năm';

  @override
  String get imRowsAre => 'Khoản chi là các dòng';

  @override
  String get imRowsNegative => 'Số âm';

  @override
  String get imRowsPositive => 'Số dương';

  @override
  String get imRowsAll => 'Tất cả';

  @override
  String get imSkipDuplicates => 'Bỏ qua khoản đã có';

  @override
  String get imSkipDuplicatesHint => 'Cùng ngày, số tiền và nội dung';

  @override
  String imSourceRows(String name, int n) {
    return '$name · $n khoản';
  }

  @override
  String imNewCategory(String name) {
    return 'Tạo mới “$name”';
  }

  @override
  String imConfirm(int n) {
    return 'Nhập $n khoản';
  }

  @override
  String get imNothingToImport => 'Không có khoản nào để nhập';

  @override
  String get imIssueNoDate => 'Thiếu ngày';

  @override
  String get imIssueBadDate => 'Không đọc được ngày';

  @override
  String get imIssueFutureDate => 'Ngày trong tương lai';

  @override
  String get imIssueNoAmount => 'Thiếu số tiền';

  @override
  String get imIssueBadAmount => 'Số tiền không hợp lệ';

  @override
  String get imIssueTooLarge => 'Số tiền quá lớn';

  @override
  String get imIssueCurrency => 'Không phải tiền Việt';

  @override
  String get imIssueIncome => 'Khoản thu, bỏ qua';

  @override
  String get imIssueDuplicate => 'Đã có, bỏ qua';

  @override
  String get imFailAiUnavailable =>
      'AI chưa sẵn sàng. Hãy dùng tệp CSV hoặc Excel.';

  @override
  String get imFailAi =>
      'AI chưa đọc được nội dung này. Thử ảnh rõ hơn hoặc dán văn bản.';

  @override
  String get imFailEmpty => 'Không tìm thấy khoản chi nào trong dữ liệu.';

  @override
  String get imFailTooBig => 'Tệp quá lớn (tối đa 10 MB, 5.000 dòng).';

  @override
  String get imFailOffline => 'Cần kết nối mạng để nhập.';

  @override
  String get imFailGeneric => 'Chưa nhập được. Thử lại sau.';

  @override
  String get imReadOldExcel =>
      'Tệp .xls cũ chưa đọc được. Hãy lưu thành .xlsx hoặc CSV rồi thử lại.';

  @override
  String get imReadUnsupported => 'Chọn tệp CSV hoặc Excel (.xlsx).';

  @override
  String get imReadBroken => 'Không mở được tệp này.';

  @override
  String get imStatusAnalyzing => 'Đang đọc';

  @override
  String get imStatusReady => 'Chờ bạn xem trước';

  @override
  String get imStatusImporting => 'Đang nhập';

  @override
  String imStatusDone(int n) {
    return 'Đã nhập $n khoản';
  }

  @override
  String get imStatusFailed => 'Chưa nhập được';

  @override
  String get imStatusUndone => 'Đã hoàn tác';

  @override
  String get imContinueReview => 'Tiếp tục xem trước';

  @override
  String get imImporting => 'Đang nhập chi tiêu…';

  @override
  String imProgress(int done, int total) {
    return '$done / $total khoản';
  }

  @override
  String get imCanClose =>
      'Bạn có thể đóng app. Child Life sẽ gửi email và thông báo khi xong.';

  @override
  String imDone(int n) {
    return 'Đã nhập $n khoản';
  }

  @override
  String imSkipped(String details) {
    return 'Bỏ qua: $details.';
  }

  @override
  String get imEmailSent => 'Kết quả cũng đã được gửi qua email.';

  @override
  String get imSeeSpending => 'Xem chi tiêu';

  @override
  String get imIssues => 'Dòng không nhập';

  @override
  String imRow(int n) {
    return 'Dòng $n';
  }

  @override
  String get imFailedTitle => 'Chưa nhập được chi tiêu';

  @override
  String get imTryAgain => 'Thử lại';

  @override
  String get imUndoneTitle => 'Đã hoàn tác lần nhập này';

  @override
  String get imUndoTitle => 'Hoàn tác lần nhập?';

  @override
  String imUndoBody(int n) {
    return '$n khoản đã nhập sẽ bị xoá khỏi Chi tiêu, kể cả khoản đã sửa sau đó.';
  }

  @override
  String imUndoConfirm(int n) {
    return 'Xoá $n khoản';
  }

  @override
  String imUndone(int n) {
    return 'Đã xoá $n khoản đã nhập';
  }

  @override
  String imInto(String name) {
    return 'Vào: $name';
  }

  @override
  String get upFirstAid => 'Sơ cứu';

  @override
  String get watchTileBottle => 'Bú bình';

  @override
  String get watchTileBreast => 'Bú mẹ';

  @override
  String get watchTileSleep => 'Ngủ';

  @override
  String get watchTileDiaper => 'Tã';

  @override
  String get watchTilePump => 'Hút sữa';

  @override
  String get watchTileReminder => 'Nhắc';

  @override
  String get watchSinceFeed => 'từ cữ trước';

  @override
  String get watchSinceLast => 'từ lần trước';

  @override
  String get watchSleeping => 'đang ngủ';

  @override
  String get watchAwake => 'đã thức';

  @override
  String get watchFeedReminder => 'nhắc bú';

  @override
  String get watchNoneYet => 'chưa ghi';

  @override
  String watchAgo(String t) {
    return '$t trước';
  }

  @override
  String get watchChooseBabyRow => 'Chọn bé';

  @override
  String get watchCrownHint => 'ml · xoay núm để chỉnh';

  @override
  String get watchSave => 'Lưu';

  @override
  String get watchBreastStartHint => 'Bắt đầu bên nào?';

  @override
  String get watchSideLeft => 'Trái';

  @override
  String get watchSideRight => 'Phải';

  @override
  String get watchSuggested => 'gợi ý';

  @override
  String watchBreastTotalLeft(String t) {
    return 'Tổng $t · đang bú bên trái';
  }

  @override
  String watchBreastTotalRight(String t) {
    return 'Tổng $t · đang bú bên phải';
  }

  @override
  String get watchSwitchSide => 'Đổi bên';

  @override
  String get watchStop => 'Dừng';

  @override
  String watchSleepSince(String time) {
    return 'từ $time';
  }

  @override
  String get watchWokeUp => 'Bé đã dậy';

  @override
  String get watchDiaperTitle => 'Thay tã';

  @override
  String get watchDiaperWet => 'Ướt';

  @override
  String get watchDiaperDirty => 'Bẩn';

  @override
  String get watchDiaperBoth => 'Cả hai';

  @override
  String get watchLoggedWet => 'Đã ghi tã ướt';

  @override
  String get watchLoggedDirty => 'Đã ghi tã bẩn';

  @override
  String get watchLoggedBoth => 'Đã ghi tã ướt và bẩn';

  @override
  String watchLoggedBottle(String ml) {
    return 'Đã ghi bú bình $ml ml';
  }

  @override
  String get watchLoggedBreast => 'Đã ghi cữ bú mẹ';

  @override
  String get watchLoggedSleep => 'Đã ghi giấc ngủ';

  @override
  String watchLoggedBy(String time, String name) {
    return '$time · $name ghi';
  }

  @override
  String get watchUndo => 'Hoàn tác';

  @override
  String get watchFailed => 'Chưa lưu được. Thử lại sau.';

  @override
  String get watchChooseBaby => 'Chọn bé';

  @override
  String get watchOneBabyNote => 'Đổi sang bé khác trên iPhone.';

  @override
  String get watchOffline => 'Đã lưu trên đồng hồ. Sẽ gửi lên khi có mạng.';

  @override
  String watchPending(String n) {
    return '$n lần ghi chờ gửi';
  }

  @override
  String get watchLinkTitle => 'Kết nối iPhone';

  @override
  String get watchLinkBody =>
      'Mở Child Life trên iPhone và đăng nhập, đồng hồ sẽ tự kết nối.';

  @override
  String get watchCannotLog => 'Bạn chưa có bé nào để ghi trên đồng hồ.';

  @override
  String get watchDemo => 'Xem thử';

  @override
  String imTotal(String amount) {
    return 'Tổng $amount';
  }

  @override
  String imDays(String from, String to) {
    return 'Từ $from đến $to';
  }

  @override
  String get imReadingAuto => 'Đã tự nhận các cột';

  @override
  String imReadingPreset(String name) {
    return 'Tệp $name';
  }

  @override
  String get imReadingNegative => 'số âm là khoản chi';

  @override
  String get imReadingPositive => 'số dương là khoản chi';

  @override
  String get imReadingAllSigns => 'lấy cả số âm và số dương';

  @override
  String get imReadingDmy => 'ngày/tháng/năm';

  @override
  String get imReadingMdy => 'tháng/ngày/năm';

  @override
  String get imAdjust => 'Chỉnh';

  @override
  String get imAdjustTitle => 'Cách đọc tệp';

  @override
  String imSkippedRows(int n) {
    return 'Bỏ qua $n dòng';
  }

  @override
  String get imSkippedExplain =>
      'Các dòng này không được nhập. Sửa trong tệp rồi nhập lại nếu cần.';

  @override
  String imSkippedMore(int n) {
    return 'Và $n dòng khác';
  }

  @override
  String get imCategoriesTitle => 'Xếp vào danh mục';

  @override
  String imCategoryFor(String name) {
    return 'Xếp “$name” vào';
  }

  @override
  String get imSamples => 'Một vài khoản sẽ nhập';

  @override
  String imReadyLabel(int n) {
    return 'khoản chi sẵn sàng nhập';
  }

  @override
  String imCategoriesNewHint(int n) {
    return '$n mục chưa có trong Chi tiêu sẽ được tạo thành danh mục mới. Chạm để đổi.';
  }

  @override
  String get imBadgeNew => 'Mới';

  @override
  String imSeeAll(int n) {
    return 'Xem tất cả $n';
  }

  @override
  String imAllTitle(int n) {
    return '$n khoản sẽ nhập';
  }

  @override
  String imPageOf(int page, int pages) {
    return 'Trang $page/$pages';
  }

  @override
  String get imPagePrev => 'Trang trước';

  @override
  String get imPageNext => 'Trang sau';

  @override
  String get imUndoAction => 'Hoàn tác lần nhập';

  @override
  String imUndoUntil(String time, String date, int days) {
    return 'Có thể hoàn tác đến $time ngày $date (còn $days ngày)';
  }

  @override
  String get emailSignInTitle => 'Đăng nhập';

  @override
  String get emailLinkSend => 'Gửi link đăng nhập';

  @override
  String get linkSentTitle => 'Kiểm tra email của bạn';

  @override
  String linkSentBody(String email) {
    return 'Đã gửi link đăng nhập đến $email. Mở link trên điện thoại này trong 15 phút để vào app.';
  }

  @override
  String get linkSentSpam =>
      'Không thấy email? Xem thư mục Quảng cáo hoặc Spam.';

  @override
  String get linkSentOpenMail => 'Mở ứng dụng Mail';

  @override
  String linkSentResendIn(String time) {
    return 'Gửi lại sau $time';
  }

  @override
  String get linkSentResend => 'Gửi lại';

  @override
  String get linkSentResent => 'Đã gửi lại link.';

  @override
  String get linkSentChangeEmail => 'Đổi email';

  @override
  String get linkOpenSigningIn => 'Đang đăng nhập…';

  @override
  String get linkConfirmTitle => 'Xác nhận email';

  @override
  String get linkConfirmBody =>
      'Nhập email đã nhận link để đăng nhập trên máy này.';

  @override
  String get linkExpiredTitle => 'Link đã hết hạn';

  @override
  String get linkExpiredBody =>
      'Link đăng nhập dùng được một lần, trong 15 phút. Gửi link mới để vào app.';

  @override
  String get linkExpiredButton => 'Gửi link mới';

  @override
  String get meFeedback => 'Góp ý cho Child Life';

  @override
  String get meFeedbackHint => 'Báo lỗi, đề xuất tính năng';

  @override
  String get meRateAppStore => 'Đánh giá trên App Store';

  @override
  String get meRatePlay => 'Đánh giá trên Google Play';

  @override
  String get meRateUnavailable => 'Child Life chưa có trên cửa hàng ứng dụng.';

  @override
  String get fbTitle => 'Góp ý';

  @override
  String get fbIntro =>
      'Đội ngũ Child Life đọc từng góp ý. Cảm ơn bạn đã giúp app tốt hơn cho các gia đình.';

  @override
  String get fbTypeIdea => 'Ý tưởng';

  @override
  String get fbTypeBug => 'Báo lỗi';

  @override
  String get fbTypeOther => 'Khác';

  @override
  String get fbMessageLabel => 'Bạn muốn chia sẻ điều gì?';

  @override
  String get fbScreenshot => 'Ảnh chụp màn hình';

  @override
  String get fbScreenshotRemove => 'Bỏ ảnh';

  @override
  String get fbDevice => 'Gửi kèm thông tin thiết bị';

  @override
  String get fbDeviceHint =>
      'Phiên bản app, hệ điều hành · không gồm ảnh hay dữ liệu của bé';

  @override
  String get fbReply => 'Cho phép liên hệ lại';

  @override
  String get fbReplyNoEmail => 'Cần tài khoản có email';

  @override
  String get fbSend => 'Gửi góp ý';

  @override
  String get fbSendFailed => 'Chưa gửi được góp ý. Thử lại nhé.';

  @override
  String get fbSentTitle => 'Đã nhận góp ý của bạn';

  @override
  String get fbSentBody =>
      'Nếu cần thêm thông tin, đội ngũ sẽ trả lời qua email trong 2 ngày làm việc. Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ.';

  @override
  String get fbSentBodyNoReply =>
      'Đội ngũ sẽ đọc góp ý của bạn. Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ.';

  @override
  String get fbDone => 'Xong';

  @override
  String get fbShotTitle => 'Có gì chưa ổn ở màn này?';

  @override
  String get fbShotBody => 'Gửi kèm ảnh vừa chụp để báo lỗi';

  @override
  String get hpSentTitle => 'Đã gửi';

  @override
  String get hpStatusNew => 'Đã nhận';

  @override
  String get hpStatusClaimed => 'Đang xem';

  @override
  String get hpStatusWaiting => 'Đã trả lời';

  @override
  String get hpStatusClosed => 'Đã xong';

  @override
  String hpFeedbackLabel(String type) {
    return 'Góp ý · $type';
  }

  @override
  String get signInRegister => 'Đăng ký';

  @override
  String get autoSaveTitle => 'Tự lưu kỷ niệm';

  @override
  String get autoSaveBeta => 'Beta miễn phí';

  @override
  String autoSaveEntryHint(String name) {
    return 'Gợi ý ảnh, video có $name từ thư viện máy';
  }

  @override
  String autoSaveEntryPending(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh mới chờ duyệt · kiểm tra lúc $time',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReviewShort => 'Duyệt';

  @override
  String get autoSaveIntroLead =>
      'Đỡ công lục thư viện. Child Life tìm ảnh và video có thể có con, bạn xem lại rồi mới tải lên.';

  @override
  String get autoSaveStep1 => 'Chọn bé và vài ảnh rõ mặt';

  @override
  String get autoSaveStep1Hint => 'Giúp app gợi ý đúng hơn';

  @override
  String get autoSaveStep2 => 'App tìm trong ảnh mới';

  @override
  String get autoSaveStep2Hint => 'Chỉ những ảnh bạn cho phép xem';

  @override
  String get autoSaveStep3 => 'Bạn duyệt rồi mới tải';

  @override
  String get autoSaveStep3Hint => 'Không tự tải, không tự chia sẻ';

  @override
  String autoSaveIntroFootnote(String usage) {
    return 'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Ảnh được kiểm tra ngay trên máy, không gửi đi. Bản beta miễn phí; tệp đã tải vẫn tính vào dung lượng của gia đình ($usage).';
  }

  @override
  String get autoSaveIntroFootnoteNoUsage =>
      'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Ảnh được kiểm tra ngay trên máy, không gửi đi. Bản beta miễn phí; tệp đã tải vẫn tính vào dung lượng của gia đình.';

  @override
  String get autoSaveStart => 'Bắt đầu thiết lập';

  @override
  String get autoSavePickBabyTitle => 'Gợi ý ảnh của bé nào?';

  @override
  String get autoSavePickBabySub =>
      'Bước 1/3 · Có thể thêm bé khác sau trong Cài đặt.';

  @override
  String autoSaveYouAre(String relation) {
    return 'Bạn là $relation';
  }

  @override
  String get autoSaveLockedCaregiver =>
      'bạn là Người chăm sóc nên không bật được tính năng này';

  @override
  String get autoSaveLockedRelative =>
      'bạn là Người thân nên không bật được tính năng này';

  @override
  String get autoSaveNext => 'Tiếp';

  @override
  String autoSaveSamplesTitle(String name) {
    return 'Chọn vài ảnh rõ mặt $name';
  }

  @override
  String get autoSaveSamplesSub =>
      'Bước 2/3 · 3–5 ảnh nhìn rõ mặt, đủ sáng. Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.';

  @override
  String autoSaveSamplesCount(int count) {
    return '$count/5 ảnh mẫu · chọn từ Kỷ niệm đã có';
  }

  @override
  String get autoSaveSamplesFromLibrary => 'Hoặc chọn từ thư viện máy';

  @override
  String autoSaveSamplesNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiếp · $count ảnh mẫu',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSamplesNeed => 'Chọn ít nhất 3 ảnh mẫu.';

  @override
  String get autoSaveSampleNoFace =>
      'Ảnh này chưa thấy rõ mặt. Chọn ảnh khác nhé.';

  @override
  String autoSaveSamplesEmpty(String name) {
    return 'Kỷ niệm chưa có ảnh của $name. Chọn từ thư viện máy nhé.';
  }

  @override
  String get autoSaveConsentTitle => 'Trước khi bắt đầu';

  @override
  String get autoSaveConsentSub =>
      'Bước 3/3 · Đổi được bất cứ lúc nào trong Cài đặt Tự lưu.';

  @override
  String autoSaveFaceTitle(String name) {
    return 'Nhận ra $name ngay trên máy này';
  }

  @override
  String autoSaveFaceBody(String name) {
    return 'Child Life so khuôn mặt trong ảnh mới với ảnh mẫu của $name để gợi ý. Mọi việc diễn ra trên điện thoại của bạn.';
  }

  @override
  String autoSaveFaceNoPhotos(String name) {
    return 'Không lưu ảnh nào của $name: ảnh mẫu vẫn nằm trong Kỷ niệm hoặc thư viện của bạn.';
  }

  @override
  String get autoSaveFaceNumbers =>
      'Chỉ ghi nhớ một dãy số về khuôn mặt, nằm trên máy này, không gửi lên Child Life.';

  @override
  String get autoSaveFaceNoOne =>
      'Child Life không xem được, không dùng cho quảng cáo. Bạn xoá được bất cứ lúc nào.';

  @override
  String autoSaveFaceAgree(String name) {
    return 'Tôi đồng ý để Child Life nhận ra $name trên máy này';
  }

  @override
  String get autoSaveAgreeFirst =>
      'Đánh dấu đồng ý ở thẻ đầu tiên để tiếp tục.';

  @override
  String get autoSaveWhatKept => 'Child Life lưu gì?';

  @override
  String get autoSaveLibraryTitle => 'Cho Child Life xem thư viện ảnh';

  @override
  String autoSaveLibraryBody(String name) {
    return 'Để tìm ảnh, video mới có thể có $name. App không xoá hay sửa gì trong thư viện.';
  }

  @override
  String get autoSaveLibraryHint =>
      'Bấm tiếp, điện thoại sẽ hỏi quyền. Bạn có thể cho xem tất cả hoặc chỉ ảnh được chọn.';

  @override
  String get autoSaveUploadTitle => 'Chỉ tải lên mục bạn duyệt';

  @override
  String get autoSaveUploadBody =>
      'Ảnh, video bạn bấm duyệt được tải lên Kỷ niệm như khi bạn tự thêm, và vẫn tải tiếp khi bạn khoá máy.';

  @override
  String get autoSaveAllow => 'Cho phép xem ảnh';

  @override
  String get autoSaveLater => 'Để sau · thêm ảnh thủ công';

  @override
  String get autoSaveKeptHere => 'Trên máy này';

  @override
  String get autoSaveKeptHereBody =>
      'Dãy số về khuôn mặt từ ảnh mẫu và ảnh bạn đã duyệt; danh sách ảnh đã kiểm tra hoặc đã bỏ qua; cài đặt Tự lưu. Không nằm trong bản sao lưu iCloud. Gỡ app là xoá hết.';

  @override
  String get autoSaveKeptNever => 'Không bao giờ';

  @override
  String get autoSaveKeptNeverBody =>
      'Giữ bản sao ảnh mẫu hay ảnh trong thư viện; gửi dữ liệu khuôn mặt lên máy chủ Child Life hay cho bên khác; dùng cho quảng cáo.';

  @override
  String get autoSaveKeptUp => 'Tải lên Child Life';

  @override
  String get autoSaveKeptUpBody =>
      'Chỉ ảnh, video bạn bấm duyệt, với quyền \"Ai thấy\" bạn chọn (mặc định Chỉ ba mẹ).';

  @override
  String get autoSaveKeptFooter =>
      'Xoá trong Cài đặt Tự lưu › Xoá ảnh mẫu và dữ liệu gợi ý. Tắt Tự lưu thì dữ liệu trên máy tự xoá sau 30 ngày.';

  @override
  String get autoSaveChecking => 'Đang kiểm tra ảnh mới';

  @override
  String autoSaveCheckingFirst(String checked, String total) {
    return '$checked / $total tệp · chưa tải gì lên';
  }

  @override
  String autoSaveCheckingProgress(String checked, String total) {
    return '$checked / $total tệp · tiến độ kiểm tra';
  }

  @override
  String get autoSaveCheckingPause =>
      'Có thể tạm dừng khi bạn rời app; lần mở sau sẽ kiểm tra tiếp.';

  @override
  String get autoSaveCheckingSeparate =>
      'Tách riêng với tiến độ tải lên bên dưới.';

  @override
  String autoSaveFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã tìm thấy $count gợi ý',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveFoundHint => 'Bạn có thể xem ngay, kiểm tra vẫn tiếp tục.';

  @override
  String autoSaveSeeFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Xem $count gợi ý',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveKinds => 'Ảnh và video';

  @override
  String get autoSaveKindsBoth => 'Kiểm tra cả hai · chỉ ảnh bạn cho phép xem';

  @override
  String autoSaveLastCheck(String time) {
    return 'Lần kiểm tra gần nhất: $time';
  }

  @override
  String autoSaveNewFiles(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp mới · $names',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveCheckNow => 'Kiểm tra ảnh mới';

  @override
  String get autoSaveWhen =>
      'App kiểm tra khi bạn mở và khi điện thoại cho phép chạy nền; thời điểm không cố định.';

  @override
  String autoSavePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gợi ý chờ duyệt',
    );
    return '$_temp0';
  }

  @override
  String autoSavePendingMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gợi ý chờ duyệt · đang tìm thêm',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReview => 'Duyệt gợi ý';

  @override
  String get autoSaveUploadingRow => 'Đang tải lên';

  @override
  String autoSaveUploadingValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSavedRow => 'Đã lưu từ Tự lưu';

  @override
  String autoSaveSavedValue(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục trong $month',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveManual => 'Thêm ảnh thủ công';

  @override
  String get autoSaveManualHint => 'Chọn từ thư viện như trước';

  @override
  String get autoSaveLimitedTitle => 'Đang xem những ảnh bạn đã chọn';

  @override
  String get autoSaveLimitedBody => 'Child Life chỉ gợi ý trong những ảnh này';

  @override
  String get autoSavePickMore => 'Chọn thêm ảnh';

  @override
  String get autoSaveAllowAll => 'Cho xem tất cả trong Cài đặt điện thoại';

  @override
  String get autoSaveDeniedTitle => 'Child Life chưa được xem ảnh';

  @override
  String get autoSaveDeniedBody =>
      'Tự lưu đang tạm dừng. Kỷ niệm đã lưu không bị ảnh hưởng.';

  @override
  String get autoSaveOpenSettings => 'Mở Cài đặt điện thoại';

  @override
  String autoSaveNoSamplesTitle(String name) {
    return '$name chưa có ảnh mẫu';
  }

  @override
  String autoSaveNoSamplesBody(String name) {
    return 'Thêm 3–5 ảnh rõ mặt để bắt đầu gợi ý ảnh của $name';
  }

  @override
  String get autoSaveAddSamples => 'Thêm ảnh mẫu';

  @override
  String autoSaveNothingTitle(String names) {
    return 'Chưa có ảnh mới có thể có $names';
  }

  @override
  String autoSaveNothingBody(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kiểm tra lúc $time · $count tệp mới từ lần trước',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveOffTitle => 'Tự lưu đang tắt';

  @override
  String get autoSaveOffBody =>
      'Bật lại trong Cài đặt Tự lưu để tìm ảnh mới. Kỷ niệm đã lưu không bị ảnh hưởng.';

  @override
  String get autoSaveNotYet => 'Chưa kiểm tra lần nào';

  @override
  String autoSaveReviewTitle(String name) {
    return 'Có thể có $name';
  }

  @override
  String autoSaveReviewSub(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count gợi ý · kiểm tra lúc $time. Bỏ chọn những mục không muốn lưu.',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveGroupedHint =>
      'Ảnh giống nhau được gom lại, app chọn sẵn ảnh rõ nhất.';

  @override
  String autoSaveFilterAll(int count) {
    return 'Tất cả · $count';
  }

  @override
  String autoSaveFilterPhotos(int count) {
    return 'Ảnh · $count';
  }

  @override
  String autoSaveFilterVideos(int count) {
    return 'Video · $count';
  }

  @override
  String autoSaveDayToday(String date) {
    return 'Hôm nay · $date';
  }

  @override
  String autoSaveDayYesterday(String date) {
    return 'Hôm qua · $date';
  }

  @override
  String autoSaveDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveAlready => 'Đã có';

  @override
  String get autoSaveInCloud => 'Trên iCloud';

  @override
  String get autoSaveLegend =>
      '\"Đã có\": tệp trùng với Kỷ niệm, sẽ không tải lại. \"Trên iCloud\": tệp gốc chưa có trong máy, sẽ lấy về khi có mạng.';

  @override
  String autoSaveGroupTitle(int count, int chosen) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh giống nhau · đã chọn $chosen',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveGroupAll => 'Chọn cả nhóm';

  @override
  String get autoSaveGroupCollapse => 'Thu gọn';

  @override
  String get autoSaveBest => 'Rõ nhất';

  @override
  String autoSaveChosen(int count, int photos, int videos) {
    return 'Đã chọn $count · $photos ảnh, $videos video';
  }

  @override
  String autoSaveMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã gộp $count ảnh giống nhau · không xoá gì trong máy',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveDeselectAll => 'Bỏ chọn tất cả';

  @override
  String get autoSaveSelectAll => 'Chọn tất cả';

  @override
  String autoSaveRoundRest(int rest, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      rest,
      locale: localeName,
      other: 'Mỗi lần tải tối đa $cap mục · $rest gợi ý còn lại chờ lần sau',
    );
    return '$_temp0';
  }

  @override
  String autoSaveRoundFull(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'Mỗi lần tải tối đa $cap mục',
    );
    return '$_temp0';
  }

  @override
  String autoSaveContinue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiếp tục với $count mục',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveReviewEmpty => 'Không còn gợi ý nào chờ duyệt.';

  @override
  String autoSaveViewerPos(int index, int total, String time) {
    return '$index / $total · $time';
  }

  @override
  String get autoSaveFor => 'Gợi ý cho';

  @override
  String get autoSaveChange => 'Đổi';

  @override
  String get autoSaveNotBaby => 'Không phải ảnh của bé';

  @override
  String get autoSaveSelected => 'Đã chọn';

  @override
  String get autoSaveSelect => 'Chọn';

  @override
  String get autoSaveRejected => 'Đã bỏ khỏi gợi ý';

  @override
  String get autoSaveUndo => 'Hoàn tác';

  @override
  String get autoSaveWhose => 'Ảnh này của ai?';

  @override
  String get autoSaveSuggestedNow => 'Đang được gợi ý';

  @override
  String get autoSaveNotBabyHint =>
      'Bỏ khỏi gợi ý · giúp lần sau gợi ý tốt hơn';

  @override
  String get autoSaveDone => 'Xong';

  @override
  String get autoSaveConfirmTitle => 'Kiểm tra trước khi tải';

  @override
  String get autoSaveSource => 'Nguồn';

  @override
  String autoSaveSourceValue(int count, int photos, int videos) {
    return 'Thư viện ảnh trên máy · $count mục ($photos ảnh, $videos video)';
  }

  @override
  String get autoSaveBabyRow => 'Bé';

  @override
  String get autoSaveSaveTo => 'Lưu vào';

  @override
  String get autoSaveSaveToValue => 'Nhật ký, theo ngày chụp · Album: không';

  @override
  String get autoSaveWho => 'Ai thấy';

  @override
  String get autoSaveParentsOnly => 'Chỉ ba mẹ';

  @override
  String get autoSaveParentsOnlyHint => 'Mặc định cho Tự lưu';

  @override
  String get autoSaveFamily => 'Gia đình';

  @override
  String get autoSaveFamilyHint => 'Cả nhà cùng xem';

  @override
  String get autoSaveNotify => 'Báo cho gia đình';

  @override
  String get autoSaveNotifyOff => 'Tắt · không gửi thông báo';

  @override
  String get autoSaveNotifyOn => '1 thông báo chung, không kèm ảnh';

  @override
  String get autoSaveStorageAfter => 'Dung lượng sau khi tải';

  @override
  String autoSaveUploadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tải lên $count mục',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveConfirmFootnote =>
      'Ảnh gốc vẫn ở trong máy. Tải xong mới hiện \"Đã lưu\".';

  @override
  String autoSaveNoRoom(int count, String need, String left, int fit) {
    return 'Không đủ dung lượng: $count mục cần $need, gia đình còn $left. Bạn có thể tải trước $fit mục vừa đủ, phần còn lại vẫn giữ trên máy.';
  }

  @override
  String autoSaveUploadFit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tải trước $count mục vừa đủ',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveNoRoomFootnote =>
      'Mục chưa tải vẫn ở trong máy và trong danh sách gợi ý.';

  @override
  String get autoSaveSeeStorage => 'Xem dung lượng';

  @override
  String autoSavePreparing(int done, int total) {
    return 'Đang chuẩn bị $done/$total…';
  }

  @override
  String autoSaveQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang tải $count mục lên Kỷ niệm',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSettingsTitle => 'Cài đặt Tự lưu';

  @override
  String get autoSaveOnBeta => 'Đang bật · Beta miễn phí';

  @override
  String get autoSaveOffValue => 'Đang tắt';

  @override
  String get autoSaveLookIn => 'Tìm trong';

  @override
  String get autoSavePhotos => 'Ảnh';

  @override
  String get autoSaveVideos => 'Video';

  @override
  String get autoSaveVideosHint => 'Video lớn tốn nhiều dung lượng';

  @override
  String get autoSaveWifi => 'Video chỉ tải qua Wi-Fi';

  @override
  String get autoSaveWifiHint => 'Áp dụng cho mọi video tải lên';

  @override
  String get autoSaveNotifyNew => 'Báo khi có ảnh mới';

  @override
  String get autoSaveNotifyNewHint =>
      'Tối đa 1 lần/ngày · không báo trong giờ yên lặng';

  @override
  String get autoSaveBabies => 'Bé & ảnh mẫu';

  @override
  String autoSaveSamplesOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh mẫu · đang gợi ý',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSamplesNone => 'Chưa có ảnh mẫu · tạm tắt';

  @override
  String get autoSaveAddBaby => 'Thêm bé';

  @override
  String get autoSaveLastStatus => 'Trạng thái gần nhất';

  @override
  String get autoSaveCheckRow => 'Kiểm tra';

  @override
  String autoSaveCheckValue(String time, int files, int found) {
    return '$time · $files tệp · $found gợi ý';
  }

  @override
  String get autoSavePermission => 'Quyền xem ảnh';

  @override
  String get autoSaveAccessFull => 'Toàn bộ thư viện';

  @override
  String get autoSaveAccessLimited => 'Ảnh được chọn';

  @override
  String get autoSaveAccessDenied => 'Chưa cho phép';

  @override
  String get autoSaveOnDevice => 'Dữ liệu nhận diện chỉ nằm trên máy này.';

  @override
  String get autoSaveOffNote =>
      'Tắt Tự lưu không xoá kỷ niệm đã lưu. App chỉ ngừng tìm và gợi ý ảnh mới.';

  @override
  String get autoSaveWipe => 'Xoá ảnh mẫu và dữ liệu gợi ý';

  @override
  String get autoSaveWipeBody =>
      'Các dãy số về khuôn mặt, gợi ý đang chờ và sự đồng ý trên máy này sẽ bị xoá. Kỷ niệm đã lưu không bị ảnh hưởng. Muốn dùng lại, bạn thiết lập từ đầu.';

  @override
  String get autoSaveWipeAction => 'Xoá';

  @override
  String get autoSaveWiped => 'Đã xoá dữ liệu Tự lưu trên máy này';

  @override
  String autoSaveSamplesOf(String name) {
    return 'Ảnh mẫu của $name';
  }

  @override
  String get autoSaveSave => 'Lưu';

  @override
  String autoSaveRemoveBaby(String name) {
    return 'Bỏ $name khỏi Tự lưu';
  }

  @override
  String autoSaveAnd(String a, String b) {
    return '$a và $b';
  }

  @override
  String get autoSaveSamplesHint =>
      '3–5 ảnh nhìn rõ mặt, đủ sáng. Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.';

  @override
  String get emailLinkNeedsEmail => 'Nhập email để nhận link đăng nhập.';

  @override
  String autoSavePushTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Có $count ảnh mới có thể có $name',
    );
    return '$_temp0';
  }

  @override
  String get autoSavePushBody =>
      'Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.';

  @override
  String get autoSaveYourBaby => 'bé';

  @override
  String autoSaveBannerTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh mới có thể có $name',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveBannerBody => 'Từ thư viện máy · chưa tải lên';

  @override
  String get autoSaveBannerOpen => 'Xem & chọn ảnh';

  @override
  String get autoSaveBannerLater => 'Để sau';

  @override
  String get autoSaveTabDot => 'Có ảnh mới chờ duyệt';

  @override
  String get autoSaveDiagTitle => 'Chẩn đoán (bản dev)';

  @override
  String autoSaveDiagHow(String how, int count) {
    return 'Lần kiểm tra gần nhất: $how · $count tệp';
  }

  @override
  String get autoSaveDiagHistory => 'ảnh mới thêm vào thư viện';

  @override
  String get autoSaveDiagByDate => 'theo ngày';

  @override
  String get autoSaveDiagNone => 'Chưa kiểm tra lần nào từ lúc mở app.';

  @override
  String autoSaveDiagMatch(String d, String t) {
    return 'Gợi ý · $d ≤ $t';
  }

  @override
  String autoSaveDiagFar(String d, String t) {
    return 'Không giống bé · $d > $t';
  }

  @override
  String get autoSaveDiagNegative => 'Giống ảnh đã bấm “Không phải ảnh của bé”';

  @override
  String get autoSaveDiagNoFace => 'Không thấy khuôn mặt';

  @override
  String get autoSaveDiagSmall => 'Khuôn mặt quá nhỏ';

  @override
  String get autoSaveDiagUtility => 'Giống giấy tờ hoặc ảnh chụp màn hình';

  @override
  String get autoSaveDiagUnreadable => 'Không đọc được ảnh';

  @override
  String get autoSaveDiagHandled => 'Đã tải lên hoặc đã bỏ qua trước đó';

  @override
  String get autoSaveDiagRescan => 'Kiểm tra lại 30 ngày gần nhất';

  @override
  String get ksCardTitle => 'Thiệp cột mốc';

  @override
  String get ksChooseOccasion => 'Chọn dịp';

  @override
  String get ksSuggested => 'Gợi ý';

  @override
  String get ksOccD7 => '7 ngày';

  @override
  String get ksOccM1 => '1 tháng';

  @override
  String get ksOccD100 => '100 ngày';

  @override
  String get ksOccFirstSmile => 'Lần đầu cười';

  @override
  String get ksOccRollsOver => 'Lần đầu biết lẫy';

  @override
  String get ksOccCrawls => 'Biết bò';

  @override
  String get ksOccFirstSteps => 'Bước đi đầu tiên';

  @override
  String get ksOccY1 => 'Sinh nhật 1 tuổi';

  @override
  String get ksTitleY1 => '1 tuổi';

  @override
  String get ksQuoteD7 => 'Bảy ngày đầu bên con';

  @override
  String get ksQuoteM1 => 'Một tháng yêu thương';

  @override
  String get ksQuoteD100 => 'Trăm ngày hạnh phúc';

  @override
  String get ksQuoteFirstSmile => 'Nụ cười đầu tiên của con';

  @override
  String get ksQuoteRollsOver => 'Con biết lẫy rồi!';

  @override
  String get ksQuoteCrawls => 'Bò khắp nhà thôi!';

  @override
  String get ksQuoteFirstSteps => 'Những bước chân đầu tiên';

  @override
  String get ksQuoteY1 => 'Một năm yêu thương';

  @override
  String get ksFormatPortrait => 'Dọc 4:5';

  @override
  String get ksFormatSquare => 'Vuông';

  @override
  String get ksFormatStory => 'Story 9:16';

  @override
  String get ksPremium => 'Cao cấp';

  @override
  String get ksNoTemplates => 'Chưa có mẫu thiệp';

  @override
  String get ksNoTemplatesBody => 'Mẫu mới sẽ có sớm. Bạn quay lại sau nhé.';

  @override
  String get ksLoadFailed => 'Chưa tải được mẫu thiệp';

  @override
  String get ksUnavailableTitle => 'Chưa mở cho gia đình bạn';

  @override
  String get ksUnavailableBody =>
      'Thiệp cột mốc đang thử nghiệm và sẽ sớm có cho mọi gia đình.';

  @override
  String get ksPreview => 'Xem trước';

  @override
  String get ksPhotoHint => 'Chạm ảnh để đổi · kéo để căn';

  @override
  String get ksChoosePhoto => 'Chọn ảnh';

  @override
  String get ksToolPhoto => 'Ảnh';

  @override
  String get ksToolLayout => 'Bố cục';

  @override
  String get ksToolMessage => 'Lời nhắn';

  @override
  String get ksToolColor => 'Màu';

  @override
  String get ksFromDevice => 'Thư viện máy';

  @override
  String get ksMessageLabel => 'Lời nhắn trên thiệp';

  @override
  String get ksSaveCard => 'Lưu thiệp';

  @override
  String get ksSaveFailed => 'Chưa lưu được thiệp. Thử lại nhé.';

  @override
  String get ksCardReady => 'Thiệp đã sẵn sàng!';

  @override
  String get ksSavedParents => 'Đã lưu vào Kỷ niệm · Chỉ ba mẹ';

  @override
  String get ksExport => 'Xuất ảnh';

  @override
  String get ksSaveDevice => 'Lưu vào máy';

  @override
  String get ksShare => 'Chia sẻ';

  @override
  String get ksSavedToDevice => 'Đã lưu vào máy';

  @override
  String get ksEditAgain => 'Sửa thiệp';

  @override
  String ksPrefilled(String name) {
    return 'Tên, tuổi và ngày được điền sẵn từ hồ sơ của $name';
  }

  @override
  String ksCreateFrom(String name) {
    return 'Tạo từ kỷ niệm của $name';
  }

  @override
  String get ksSeeTemplates => 'Xem mẫu';

  @override
  String get ksNew => 'Mới';

  @override
  String get ksCardTileHint => 'Ảnh PNG để chia sẻ';

  @override
  String get ksCardTileHintShort => 'Ảnh để chia sẻ';

  @override
  String get ksCreateGroup => 'SÁNG TẠO & TỰ ĐỘNG';

  @override
  String get ksCardBadge => 'Thiệp';

  @override
  String get ksStoriesSection => 'Câu chuyện của gia đình';

  @override
  String ksCardCount(int n) {
    return '$n thiệp';
  }

  @override
  String ksNudgeSoon(String name, String occasion) {
    return '$name sắp tròn $occasion! Cùng tạo một kỷ niệm thật đẹp nhé.';
  }

  @override
  String ksNudgeToday(String name, String occasion) {
    return 'Hôm nay $name tròn $occasion! Cùng tạo một kỷ niệm thật đẹp nhé.';
  }

  @override
  String ksNudgeJust(String name, String occasion) {
    return '$name vừa tròn $occasion! Lưu lại bằng một tấm thiệp nhé.';
  }

  @override
  String ksNudgeFirst(String name, String occasion) {
    return '$occasion của $name! Làm một tấm thiệp kỷ niệm nhé.';
  }

  @override
  String ksThisWeekday(String weekday, String day) {
    return '$weekday này · $day';
  }

  @override
  String get ksToday => 'Hôm nay';

  @override
  String get ksTomorrow => 'Ngày mai';

  @override
  String get ksMakeCard => 'Tạo thiệp';

  @override
  String get ksLater => 'Để sau';

  @override
  String ksNudgeTodayTitle(String name, String occasion) {
    return 'Hôm nay $name tròn $occasion 🎂';
  }

  @override
  String get ksNudgeTodayBody => 'Làm một tấm thiệp kỷ niệm thật xinh nhé.';

  @override
  String ksNudgeBackAgeTitle(String name, String occasion) {
    return 'Nhìn lại ngày $name tròn $occasion';
  }

  @override
  String ksNudgeBackFirstTitle(String name, String occasion) {
    return 'Nhìn lại: $occasion của $name';
  }

  @override
  String ksNudgeBackBody(int n) {
    return 'Có $n ảnh từ dịp này trong Kỷ niệm. Làm một tấm thiệp nhé?';
  }

  @override
  String get ksVideoTitle => 'Video kỷ niệm';

  @override
  String get ksVideoTileHint => 'Ảnh + chữ + nhạc';

  @override
  String ksVideoNeeds(int min, int max) {
    return 'Cần $min–$max ảnh';
  }

  @override
  String get ksUnavailableBodyVideo =>
      'Video kỷ niệm đang thử nghiệm và sẽ sớm có cho mọi gia đình.';

  @override
  String get ksFromMemories => 'Từ Kỷ niệm';

  @override
  String get ksVideoPhotosTitle => 'Chọn ảnh cho video';

  @override
  String ksVideoScenesFilled(int n, int total) {
    return '$n/$total cảnh đã có ảnh';
  }

  @override
  String ksVideoMinimum(int n) {
    return 'Tối thiểu $n';
  }

  @override
  String ksVideoScene(int n, String hint) {
    return 'Cảnh $n: $hint';
  }

  @override
  String ksVideoSceneN(int n) {
    return 'Cảnh $n';
  }

  @override
  String get ksVideoSceneOptionalTag => 'Tuỳ chọn';

  @override
  String ksVideoForScene(int n, String hint) {
    return 'Gợi ý cho cảnh $n · $hint';
  }

  @override
  String ksVideoSceneWindow(String from, String to) {
    return 'Ảnh chụp từ $from đến $to';
  }

  @override
  String get ksVideoSceneAny => 'Ảnh nào cũng hợp, ảnh mới nhất trước';

  @override
  String get ksVideoSceneEmpty =>
      'Chưa có ảnh nào trong khoảng này. Chọn trong Ảnh khác bên dưới hoặc thêm từ thư viện máy.';

  @override
  String get ksVideoSceneEmptyOptional =>
      'Chưa có ảnh nào trong khoảng này. Cảnh này tuỳ chọn, có thể để trống.';

  @override
  String get ksVideoOtherPhotos => 'Ảnh khác';

  @override
  String ksVideoClearScene(int n) {
    return 'Bỏ ảnh ở cảnh $n';
  }

  @override
  String ksVideoPicked(int n) {
    return 'Đã chọn $n ảnh';
  }

  @override
  String ksVideoCanAdd(int n) {
    return 'Có thể thêm $n';
  }

  @override
  String ksVideoNeedMore(int n) {
    return 'Cần thêm $n';
  }

  @override
  String ksVideoNotEnough(String name, int have, int need) {
    return 'Kỷ niệm của $name hiện chỉ có $have ảnh phù hợp. Mẫu này cần ít nhất $need ảnh.';
  }

  @override
  String get ksVideoMoreFromDevice => 'Chọn thêm từ thư viện máy';

  @override
  String get ksVideoMoreFromDeviceHint => 'Chỉ ảnh bạn chọn mới được dùng';

  @override
  String get ksVideoShorter => 'Đổi sang mẫu ngắn hơn';

  @override
  String ksVideoShorterHint(String name, int n) {
    return '“$name” · cần $n ảnh';
  }

  @override
  String ksVideoImporting(int n) {
    return 'Đang thêm $n ảnh vào Kỷ niệm (Chỉ ba mẹ). Ảnh sẽ được chọn khi tải xong.';
  }

  @override
  String get ksVideoFinishTitle => 'Hoàn thiện video';

  @override
  String get ksVideoPrefilled => 'Điền sẵn từ hồ sơ của bé';

  @override
  String get ksVideoBaby => 'Bé';

  @override
  String get ksVideoDay => 'Ngày mốc';

  @override
  String get ksVideoFieldTitle => 'Tiêu đề';

  @override
  String get ksVideoFieldMessage => 'Lời nhắn cuối video';

  @override
  String ksVideoOrder(int n) {
    return '$n ảnh · thứ tự xuất hiện';
  }

  @override
  String get ksVideoReorderHint => 'Giữ và kéo để đổi';

  @override
  String get ksVideoAddPhotos => 'Thêm ảnh';

  @override
  String get ksVideoMusic => 'Nhạc nền';

  @override
  String get ksVideoMusicTemplate => 'Nhạc của mẫu';

  @override
  String get ksVideoMusicNone => 'Chưa có nhạc cho mẫu này';

  @override
  String get ksVideoWho => 'Ai xem được';

  @override
  String get ksVideoWhoParents => 'Chỉ ba mẹ · lưu vào Kỷ niệm';

  @override
  String get ksVideoWhoFamily => 'Gia đình · lưu vào Kỷ niệm';

  @override
  String get ksAudienceParents => 'Chỉ ba mẹ';

  @override
  String get ksAudienceFamily => 'Gia đình';

  @override
  String get ksVideoCreate => 'Tạo video';

  @override
  String get ksVideoTakes => 'Mất khoảng 1–2 phút · bạn có thể rời màn hình';

  @override
  String get ksVideoErrBusy =>
      'Đang có một video được tạo cho bé. Đợi xong rồi tạo tiếp nhé.';

  @override
  String get ksVideoErrDaily =>
      'Hôm nay gia đình đã tạo nhiều video. Mai thử lại nhé.';

  @override
  String get ksVideoErrQuota =>
      'Dung lượng gia đình sắp đầy. Giải phóng bớt rồi tạo video nhé.';

  @override
  String get ksVideoErrPhoto =>
      'Có ảnh vừa bị xoá hoặc chưa tải xong. Chọn lại ảnh nhé.';

  @override
  String get ksVideoErrTemplate =>
      'Mẫu này vừa được cập nhật. Chọn lại mẫu nhé.';

  @override
  String ksVideoMaking(String name) {
    return 'Đang tạo video cho $name…';
  }

  @override
  String get ksVideoMakingBody =>
      'Thường mất 1–2 phút. Bạn có thể rời màn hình này, Child Life sẽ báo khi video sẵn sàng.';

  @override
  String ksVideoStepArrange(int n) {
    return 'Sắp xếp $n ảnh theo mẫu';
  }

  @override
  String get ksVideoStepCompose => 'Thêm chữ, lời nhắn và nhạc';

  @override
  String get ksVideoStepExport => 'Xuất video 9:16';

  @override
  String get ksVideoBackToMemories => 'Về Kỷ niệm';

  @override
  String get ksLiveQueued => 'Đang chờ tạo video';

  @override
  String get ksLiveArrange => 'Đang sắp xếp ảnh';

  @override
  String get ksLiveCompose => 'Đang ghép chữ và nhạc';

  @override
  String get ksLiveExport => 'Đang xuất video';

  @override
  String get ksLiveReadySub => 'Chạm để xem, lưu và chia sẻ';

  @override
  String get ksLiveFailedSub => 'Chạm để thử lại';

  @override
  String ksVideoActive(int percent) {
    return 'Đang tạo video · $percent%';
  }

  @override
  String get ksVideoActiveQueued => 'Đang chờ tạo video';

  @override
  String get ksVideoReadyToast => 'Video kỷ niệm đã sẵn sàng';

  @override
  String get ksVideoFailedToast => 'Chưa tạo được video kỷ niệm';

  @override
  String get ksVideoOpenJob => 'Xem';

  @override
  String get ksVideoDeleteDraft => 'Xoá bản nháp';

  @override
  String get ksVideoDeleteDraftTitle => 'Xoá bản nháp video này?';

  @override
  String get ksVideoDeleteDraftBody =>
      'Ảnh của bé vẫn ở trong Kỷ niệm, chỉ bản nháp video bị xoá.';

  @override
  String get ksVideoDraftDeleted => 'Đã xoá bản nháp';

  @override
  String get ksTabCards => 'Thiệp';

  @override
  String get ksTabVideos => 'Video';

  @override
  String get ksVideoReady => 'Video đã sẵn sàng!';

  @override
  String get ksVideoSaved => 'Đã lưu vào Kỷ niệm';

  @override
  String get ksVideoFiling => 'Đang lưu vào Kỷ niệm…';

  @override
  String ksVideoWeek(int n) {
    return 'Tuần $n';
  }

  @override
  String get ksVideoWatch => 'Xem video';

  @override
  String get ksVideoOpen => 'Xem trong Kỷ niệm';

  @override
  String ksVideoAlsoCard(String occasion) {
    return 'Tạo thêm thiệp “$occasion”';
  }

  @override
  String get ksVideoAlsoCardHint => 'Dùng lại ảnh vừa chọn';

  @override
  String get ksVideoFailed => 'Chưa tạo được video';

  @override
  String get ksVideoFailedNetwork =>
      'Kết nối bị gián đoạn khi xuất video. Ảnh, chữ và lời nhắn bạn đã chọn vẫn được giữ nguyên.';

  @override
  String get ksVideoFailedBusy =>
      'Máy chủ đang bận nên chưa tạo xong. Ảnh, chữ và lời nhắn bạn đã chọn vẫn được giữ nguyên.';

  @override
  String get ksVideoFailedPhoto =>
      'Có ảnh đã bị xoá khỏi Kỷ niệm. Chỉnh lại lựa chọn để tạo video.';

  @override
  String get ksVideoEditChoices => 'Chỉnh lại lựa chọn';

  @override
  String get ksVideoDraftNote =>
      'Bản nháp được lưu trong Câu chuyện · Bản nháp';

  @override
  String get ksMakeVideo => 'Tạo video';

  @override
  String ksMakeVideoFor(String occasion) {
    return 'Tạo video $occasion';
  }

  @override
  String get ksVideoDraftTile => 'Bản nháp';

  @override
  String get ksVideoContinue => 'Làm tiếp';

  @override
  String ksVideoInProgress(int p) {
    return 'Đang tạo · $p%';
  }

  @override
  String get ksBannerView => 'Xem';

  @override
  String ksVideoCount(int n) {
    return '$n video';
  }

  @override
  String get careDevelop => 'Hiểu con & phát triển';

  @override
  String get careKnowledge => 'Kiến thức chăm bé';

  @override
  String get utTools => 'Công cụ';

  @override
  String get ksPreviewSample => 'Xem mẫu';

  @override
  String get ksPreviewNote =>
      'Bản xem trước chạy ngay trên máy. Video thật được xuất 1080×1920 sau khi bấm “Tạo video”.';

  @override
  String get ksPreviewFailed =>
      'Chưa mở được bản xem trước. Kiểm tra mạng rồi thử lại nhé.';

  @override
  String get ksMusicNone => 'Không dùng nhạc';

  @override
  String get ksMusicDefault => 'Mặc định của mẫu';

  @override
  String get ksMusicStop => 'Dừng nghe thử';

  @override
  String get ksMusicNote =>
      'Nhạc có bản quyền do Child Life chọn. Bạn có thể đổi bài bất cứ lúc nào trước khi tạo video.';

  @override
  String get ksPreviewVideoNote =>
      'Video mẫu dùng ảnh minh hoạ. Video của bé sẽ dùng ảnh và lời bạn chọn.';

  @override
  String ksMusicListen(String title) {
    return 'Nghe thử $title';
  }

  @override
  String get ksOccBirth => 'Chào đời';

  @override
  String get ksOccLaughs => 'Tiếng cười đầu tiên';

  @override
  String get ksOccSitsUp => 'Biết ngồi';

  @override
  String get ksOccStands => 'Đứng vững';

  @override
  String get ksOccFirstTooth => 'Chiếc răng đầu tiên';

  @override
  String get ksOccFirstSolids => 'Bữa ăn dặm đầu tiên';

  @override
  String get ksOccFirstWord => 'Tiếng gọi đầu tiên';

  @override
  String get ksAchieveRollsOver => 'Con biết lẫy rồi!';

  @override
  String get ksAchieveSitsUp => 'Con ngồi vững rồi!';

  @override
  String get ksAchieveCrawls => 'Con biết bò rồi!';

  @override
  String get ksAchieveStands => 'Con đứng được rồi!';

  @override
  String get ksAchieveFirstSteps => 'Con đi được rồi!';

  @override
  String get ksAchieveAny => 'Nhìn con làm được nè!';

  @override
  String get ksQuoteBirth => 'Chào con đến với thế giới';

  @override
  String get ksQuoteLaughs => 'Cười giòn tan cả nhà';

  @override
  String get ksQuoteSitsUp => 'Con ngồi vững rồi!';

  @override
  String get ksQuoteStands => 'Con đứng được rồi!';

  @override
  String get ksQuoteFirstTooth => 'Chiếc răng xinh đầu tiên';

  @override
  String get ksQuoteFirstSolids => 'Măm măm ngon quá!';

  @override
  String get ksQuoteFirstWord => 'Con đã gọi ba mẹ!';

  @override
  String get ksLabelFirstDay => 'Ngày đầu';

  @override
  String get ksLabelThen => 'Lúc ấy';

  @override
  String get ksLabelNow => 'Bây giờ';

  @override
  String ksOccMonth(int n) {
    return '$n tháng';
  }

  @override
  String ksQuoteMonth(int n) {
    return 'Tròn $n tháng yêu thương';
  }

  @override
  String ksAgeDays(int n) {
    return '$n ngày';
  }

  @override
  String ksAgeWeeks(int n) {
    return '$n tuần';
  }

  @override
  String ksAgeMonths(int n) {
    return '$n tháng';
  }

  @override
  String ksAgeYears(int n) {
    return '$n tuổi';
  }

  @override
  String ksUnitDays(int n) {
    return 'ngày';
  }

  @override
  String ksUnitWeeks(int n) {
    return 'tuần';
  }

  @override
  String ksUnitMonths(int n) {
    return 'tháng';
  }

  @override
  String ksUnitYears(int n) {
    return 'tuổi';
  }

  @override
  String ksLabelDay(int n) {
    return 'Ngày $n';
  }

  @override
  String ksLabelWeek(int n) {
    return 'Tuần $n';
  }

  @override
  String ksLabelMonth(int n) {
    return 'Tháng $n';
  }

  @override
  String ksLabelYear(int n) {
    return '$n tuổi';
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
  String get ksVideoFieldHeadline => 'Tiêu đề lớn';

  @override
  String get ksVideoFieldLines => 'Lời cho từng ảnh (mỗi dòng một câu)';

  @override
  String get ksVideoFieldLetter => 'Lá thư gửi con';

  @override
  String get ksVideoFieldClosing => 'Lời kết';

  @override
  String get ksUseTemplate => 'Dùng mẫu này';

  @override
  String get ksInfoPhotos => 'Ảnh cần';

  @override
  String get ksInfoFormat => 'Khổ';

  @override
  String get ksInfoOccasion => 'Dịp';

  @override
  String get ksInfoDuration => 'Thời lượng';

  @override
  String get ksInfoPalettes => 'Bảng màu';

  @override
  String get ksAnyOccasion => 'Mọi dịp';

  @override
  String ksPhotosCount(int count) {
    return '$count ảnh';
  }

  @override
  String ksPhotosRange(int min, int max) {
    return '$min–$max ảnh';
  }

  @override
  String ksPalettesCount(int count) {
    return '$count bảng màu';
  }

  @override
  String get pmBadgePremium => 'Premium';

  @override
  String get pmBadgeBeta => 'Beta';

  @override
  String get pmBadgeFree => 'Cơ bản';

  @override
  String get pmBadgePending => 'Đang xác minh';

  @override
  String get pmBadgeExpired => 'Hết hạn';

  @override
  String get pmPlanTitle => 'Gói của hộ';

  @override
  String get pmPlanFree => 'Đang dùng gói cơ bản';

  @override
  String get pmPlanFreeBody =>
      'Ghi chép, lịch tham khảo, mẫu cơ bản, hướng dẫn sức khoẻ.';

  @override
  String get pmPlanBeta => 'Beta cá nhân hoá đang mở';

  @override
  String pmPlanBetaBody(String date) {
    return 'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI miễn phí đến $date. Không gồm mẫu Premium. Không tự trừ tiền khi beta kết thúc.';
  }

  @override
  String get pmPlanPremium => 'Child Life Premium';

  @override
  String pmPlanRenews(String date) {
    return 'Gia hạn tự động $date';
  }

  @override
  String pmPlanEnds(String date) {
    return 'Dùng đến $date · đã tắt gia hạn';
  }

  @override
  String get pmPlanShared =>
      'Cả nhà thấy “Hộ đã có Premium”. Chỉ chủ hộ quản lý gói.';

  @override
  String get pmPlanHouseholdHas => 'Hộ đã có Premium';

  @override
  String get pmPlanPending => 'Đang xác minh giao dịch';

  @override
  String get pmPlanPendingBody =>
      'Chưa mở quyền mới; dữ liệu và lựa chọn vẫn giữ.';

  @override
  String pmPlanExpired(String date) {
    return 'Premium đã hết hạn $date';
  }

  @override
  String get pmPlanExpiredBody =>
      'Vẫn xem dữ liệu, tóm tắt đã lưu, kỷ niệm và file đã xuất. Tạo mới nội dung Premium cần gia hạn.';

  @override
  String get pmPlanBuySoon =>
      'Mua và quản lý gói ngay trong app sẽ có ở bản sau.';

  @override
  String get pmPlanOwnerOnly =>
      'Chỉ chủ hộ mua và quản lý gói. Nhờ chủ hộ nếu cả nhà cần Premium.';

  @override
  String get pmPlanAlwaysFree => 'Gói nào cũng có';

  @override
  String get pmPlanAlwaysFreeBody =>
      'Ghi chép, lịch sử, nhắc việc, lịch tham khảo, hướng dẫn sức khoẻ và mọi thứ đã lưu.';

  @override
  String get pmRegionRow => 'Khu vực của hộ';

  @override
  String get pmRegionUnset => 'Chưa chọn';

  @override
  String get pmRegionTitle => 'Gia đình đang sống ở đâu?';

  @override
  String get pmRegionBody =>
      'Dùng để chọn số cấp cứu, lịch tiêm và nội dung sức khoẻ phù hợp với nơi bạn sống. Child Life không đoán từ ngôn ngữ hay vị trí.';

  @override
  String get pmRegionOwnerOnly => 'Chủ hộ chọn khu vực của hộ.';

  @override
  String get pmRegionSaved => 'Đã lưu khu vực';

  @override
  String get meRegionRow => 'Nơi gia đình sống';

  @override
  String get pmCountryVN => 'Việt Nam';

  @override
  String get pmCountryUS => 'Hoa Kỳ';

  @override
  String get pmCountryGB => 'Vương quốc Anh';

  @override
  String get pmCountryAU => 'Úc';

  @override
  String get pmCountryCA => 'Canada';

  @override
  String get pmCountrySG => 'Singapore';

  @override
  String get pmCountryNZ => 'New Zealand';

  @override
  String get pmCountryDE => 'Đức';

  @override
  String get pmCountryFR => 'Pháp';

  @override
  String get pmCountryJP => 'Nhật Bản';

  @override
  String get pmCountryKR => 'Hàn Quốc';

  @override
  String get pmCountryTW => 'Đài Loan';

  @override
  String get pmCountryMY => 'Malaysia';

  @override
  String get pmCountryTH => 'Thái Lan';

  @override
  String get pmCountryHK => 'Hồng Kông';

  @override
  String get pmCountryCN => 'Trung Quốc';

  @override
  String get pmCountryIE => 'Ireland';

  @override
  String get pmCountryNL => 'Hà Lan';

  @override
  String get pmCountryBE => 'Bỉ';

  @override
  String get pmCountryES => 'Tây Ban Nha';

  @override
  String get pmCountryCH => 'Thuỵ Sĩ';

  @override
  String get pmCountryAT => 'Áo';

  @override
  String get pmCountryCZ => 'Séc';

  @override
  String get pmCountryPL => 'Ba Lan';

  @override
  String get pmCountrySE => 'Thuỵ Điển';

  @override
  String get pmCountryNO => 'Na Uy';

  @override
  String get pmCountryDK => 'Đan Mạch';

  @override
  String get pmCountryFI => 'Phần Lan';

  @override
  String get pmCountryAE => 'Các Tiểu vương quốc Ả Rập Thống nhất';

  @override
  String get pmCountryQA => 'Qatar';

  @override
  String get pmUnlockPremium => 'Mở với Premium';

  @override
  String get pmUseFreeTemplate => 'Dùng mẫu cơ bản';

  @override
  String get pmCardNoQuota => 'Thẻ Premium không trừ lượt xuất video';

  @override
  String get pmTemplatePremiumBody =>
      'Mẫu này dành cho gia đình có Child Life Premium.';

  @override
  String get pmTemplateBetaNote =>
      'Gói beta hiện tại của nhà mình chưa gồm mẫu Premium.';

  @override
  String get pmGateRoleTitle => 'Cần quyền của ba mẹ';

  @override
  String get pmGateRoleBody =>
      'Premium không đổi vai trò. Tạo thẻ, tạo tóm tắt AI hoặc sửa ghi nhận cần quyền của ba mẹ.';

  @override
  String get pmGateRegionTitle => 'Hỗ trợ phù hợp chưa mở ở khu vực này';

  @override
  String get pmGateRegionBody =>
      'Chưa có nội dung sức khoẻ được duyệt cho khu vực của hộ. Ghi chép, lịch tham khảo, Kỷ niệm và mẫu cơ bản vẫn dùng bình thường.';

  @override
  String get pmGateRegionAction => 'Đổi khu vực trong hồ sơ hộ';

  @override
  String get pmGateDisabledTitle => 'Tính năng đang tạm tắt';

  @override
  String get pmGateDisabledBody =>
      'Ghi chép, nội dung cơ bản và hướng dẫn sức khoẻ vẫn dùng bình thường.';

  @override
  String get pmGateQuotaTitle => 'Đã hết lượt trong kỳ này';

  @override
  String get pmGateQuotaBody => 'Bạn vẫn xem mẫu và tạo thẻ ảnh.';

  @override
  String get pmGateConsentTitle => 'Cần bạn đồng ý dùng AI';

  @override
  String get pmGateConsentBody =>
      'Bản tóm tắt theo mẫu vẫn dùng được khi chưa bật AI.';

  @override
  String get pmGateNotMemberTitle => 'Bạn không còn trong gia đình này';

  @override
  String get pmGateOk => 'Đã hiểu';

  @override
  String get rhSectionForYou => 'Dành cho bé hôm nay';

  @override
  String get rhSectionForYouSub => 'Gợi ý, tuần tuổi và lịch tham khảo';

  @override
  String get rhReviewPending => 'Nội dung minh hoạ · chờ chuyên môn duyệt';

  @override
  String rhReviewedBy(String reviewer, String credential) {
    return 'Đã duyệt bởi $reviewer · $credential';
  }

  @override
  String rhJoinTwo(String a, String b) {
    return '$a và $b';
  }

  @override
  String rhQuoted(String text) {
    return '“$text”';
  }

  @override
  String get rhWhoYou => 'bạn';

  @override
  String rhDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get rhDone => 'Xong';

  @override
  String get rhContinue => 'Tiếp tục';

  @override
  String get rhRetry => 'Thử lại';

  @override
  String get rhSources => 'Nguồn tham khảo';

  @override
  String get rhObsSleep => 'Khó vào giấc / hay thức';

  @override
  String get rhObsFeeding => 'Bú / ăn khác thường';

  @override
  String get rhObsSoothing => 'Cần được dỗ nhiều hơn';

  @override
  String get rhObsNewSkill => 'Con có điều mới';

  @override
  String get rhObsUsual => 'Như mọi ngày';

  @override
  String get rhObsHealth => 'Mình lo về sức khoẻ của con';

  @override
  String get rhObsShortSleep => 'Khó vào giấc';

  @override
  String get rhObsShortFeeding => 'Bú / ăn khác thường';

  @override
  String get rhObsShortSoothing => 'Cần dỗ nhiều hơn';

  @override
  String get rhObsShortNewSkill => 'Điều mới';

  @override
  String get rhObsShortUsual => 'Như mọi ngày';

  @override
  String get rhObsShortHealth => 'Lo về sức khoẻ';

  @override
  String rhWhatSleep(String baby) {
    return 'con khó vào giấc';
  }

  @override
  String rhWhatFeeding(String baby) {
    return 'con bú / ăn khác thường';
  }

  @override
  String rhWhatSoothing(String baby) {
    return 'con cần được dỗ nhiều hơn';
  }

  @override
  String rhWhatNewSkill(String baby) {
    return 'con có điều mới';
  }

  @override
  String rhWhatOther(String baby) {
    return 'điều con cần';
  }

  @override
  String get rhWhenToday => 'hôm nay';

  @override
  String get rhWhenLastNight => 'tối qua';

  @override
  String get rhWhenYesterday => 'hôm qua';

  @override
  String rhWhenOn(String date) {
    return 'ngày $date';
  }

  @override
  String rhReasonNoted(String when, String who, String what) {
    return 'Vì $when $who ghi nhận $what.';
  }

  @override
  String rhReasonHelpful(String who) {
    return 'Lần trước $who đánh giá cách này “Có ích”.';
  }

  @override
  String rhReasonData(String baby) {
    return 'Vì giấc ngủ mấy ngày gần đây khác với thường ngày của con (từ nhật ký).';
  }

  @override
  String rhReasonAge(String baby) {
    return 'Vì phù hợp với tuổi của con.';
  }

  @override
  String get rhReasonInterest => 'Vì bạn quan tâm đến chủ đề này.';

  @override
  String rhReasonFallback(String baby) {
    return 'Vì nhà mình vừa ghi nhận điều con cần.';
  }

  @override
  String rhAgeHeading(String baby) {
    return 'Tuần này của $baby';
  }

  @override
  String get rhAgeFree => 'Nội dung theo tuổi';

  @override
  String get rhCalendarPill => 'LỊCH THAM KHẢO';

  @override
  String rhStageName(int n) {
    return 'Giai đoạn $n (Wonder Weeks)';
  }

  @override
  String rhStageExpected(String stage, String range) {
    return '$stage dự kiến $range';
  }

  @override
  String rhStageNow(String stage, String range) {
    return '$stage · $range · tham khảo';
  }

  @override
  String get rhSupportTitle => 'Hỗ trợ phù hợp với con';

  @override
  String get rhSupportBody =>
      'Gợi ý một việc dựa trên điều nhà mình ghi nhận, nhớ cách đã có ích, bản bàn giao cho người chăm tiếp theo.';

  @override
  String get rhLearnMore => 'Tìm hiểu thêm';

  @override
  String get rhKickerToday => 'VIỆC CÓ THỂ THỬ HÔM NAY';

  @override
  String get rhKickerTonight => 'VIỆC CÓ THỂ THỬ TỐI NAY';

  @override
  String get rhTryToday => 'Thử hôm nay';

  @override
  String get rhTryTonight => 'Thử tối nay';

  @override
  String get rhTryAgainToday => 'Thử lại hôm nay';

  @override
  String get rhTryAgainTonight => 'Thử lại tối nay';

  @override
  String get rhNotToday => 'Không phải hôm nay';

  @override
  String get rhSomethingElse => 'Gợi ý khác';

  @override
  String get rhBasedOnFeedback => 'Dựa trên phản hồi của bạn';

  @override
  String rhFeedbackUsedEvening(
    String date,
    String who,
    String kind,
    String title,
  ) {
    return 'Tối $date $who chọn “$kind” cho “$title”';
  }

  @override
  String rhFeedbackUsedDay(String date, String who, String kind, String title) {
    return 'Ngày $date $who chọn “$kind” cho “$title”';
  }

  @override
  String get rhChangedTitle => 'Đã thay đổi';

  @override
  String get rhChangePrefersHelpful =>
      'Ưu tiên cách đã có ích thay vì gợi ý mới';

  @override
  String get rhChangeExcluded =>
      'Không gợi ý lại cách đã được chọn “Không phù hợp”';

  @override
  String get rhChangeCooling =>
      'Tạm nghỉ vài ngày cách đã chọn “Không phải hôm nay”';

  @override
  String get rhCheckInEntry => 'Hôm nay con có gì khác?';

  @override
  String get rhStartedLabel => 'Đang thử';

  @override
  String get rhHealthCardTitle => 'Hôm nay có dấu hiệu cần chú ý';

  @override
  String get rhHealthCardBody =>
      'Gợi ý theo lịch tạm dừng. Xem hướng dẫn và cách gọi hỗ trợ.';

  @override
  String get rhHealthCardAction => 'Xem hướng dẫn sức khoẻ';

  @override
  String get rhPutOffToast => 'Đã để sau. Gợi ý này nghỉ vài ngày.';

  @override
  String get rhCheckInTitle => 'Hôm nay con có gì khác?';

  @override
  String get rhCheckInSubtitle =>
      'Chọn một điều bạn để ý. Không cần trả lời hết.';

  @override
  String get rhUsualSaved => 'Đã lưu: hôm nay như mọi ngày';

  @override
  String get rhMoreTitle => 'Thêm một chút để gợi ý đúng hơn';

  @override
  String get rhSkipQuestions => 'Bỏ qua câu hỏi';

  @override
  String get rhQWhen => 'Khi nào?';

  @override
  String get rhWhenNightSleep => 'Giấc đêm';

  @override
  String get rhWhenDaySleep => 'Giấc ngày';

  @override
  String get rhWhenNight => 'Ban đêm';

  @override
  String get rhWhenDay => 'Ban ngày';

  @override
  String get rhWhenBoth => 'Cả hai';

  @override
  String get rhQSince => 'Từ bao giờ?';

  @override
  String get rhSinceToday => 'Hôm nay';

  @override
  String get rhSince23 => '2–3 ngày';

  @override
  String get rhSinceLonger => 'Lâu hơn';

  @override
  String get rhQTried => 'Đã thử gì chưa? (tuỳ chọn)';

  @override
  String get rhTriedRocking => 'Bế ru';

  @override
  String get rhTriedWhiteNoise => 'Tiếng ồn trắng';

  @override
  String get rhTriedFeeding => 'Cho bú';

  @override
  String get rhTriedSkin => 'Áp da';

  @override
  String get rhTriedSwaddle => 'Quấn chũn';

  @override
  String get rhTriedNone => 'Chưa';

  @override
  String get rhSumNightSleep => 'giấc đêm';

  @override
  String get rhSumDaySleep => 'giấc ngày';

  @override
  String get rhSumNight => 'ban đêm';

  @override
  String get rhSumDay => 'ban ngày';

  @override
  String get rhSumBoth => 'cả ngày lẫn đêm';

  @override
  String get rhSumToday => 'hôm nay';

  @override
  String get rhSumLonger => 'lâu hơn';

  @override
  String rhFromLogSleep(String duration, String who) {
    return 'Từ nhật ký: giấc đêm qua được ghi $duration ($who ghi). Bạn không cần nhập lại.';
  }

  @override
  String rhFromLogFeeds(int count) {
    return 'Từ nhật ký: hôm nay đã ghi $count cữ bú. Bạn không cần nhập lại.';
  }

  @override
  String get rhNewSkillLabel => 'Con làm được gì mới?';

  @override
  String get rhNewSkillHint => 'Ví dụ: lần đầu lẫy';

  @override
  String get rhSaveToMilestones => 'Lưu vào Mốc';

  @override
  String get rhSaveNote => 'Lưu ghi nhận';

  @override
  String get rhAlwaysFree => 'Cả nhà cùng thấy ghi nhận này';

  @override
  String get rhHealthQHeading => 'Ghi nhận hôm nay';

  @override
  String get rhHealthQTitle => 'Trước khi tiếp tục';

  @override
  String rhHealthQAsk(String baby) {
    return '$baby có dấu hiệu nào sau đây không?';
  }

  @override
  String get rhHealthQHelper =>
      'Nếu có, Child Life sẽ dừng gợi ý theo lịch và chỉ cho bạn hướng dẫn đã được chuyên môn duyệt.';

  @override
  String get rhHealthUnsureHint => 'Không chắc thì cứ hỏi bác sĩ của bé.';

  @override
  String get rhAnswerYes => 'Có';

  @override
  String get rhAnswerNo => 'Không';

  @override
  String get rhAnswerUnsure => 'Không chắc';

  @override
  String get rhSignFeverYoung => 'Sốt (bé dưới 3 tháng)';

  @override
  String get rhSignBreathing => 'Khó thở, thở rút lõm';

  @override
  String get rhSignLethargic => 'Lừ đừ, khó đánh thức';

  @override
  String get rhSignPoorFeeding => 'Bú rất ít hoặc bỏ bú';

  @override
  String get rhSignInconsolable => 'Khóc không dỗ được';

  @override
  String get rhSignLostSkill => 'Mất kỹ năng đã có';

  @override
  String get rhSignDehydration => 'Ít tã ướt, môi khô';

  @override
  String get rhSignSeizure => 'Co giật';

  @override
  String get rhHlTitle => 'Nên liên hệ hỗ trợ y tế';

  @override
  String get rhHlBody =>
      'Bạn đánh dấu một dấu hiệu cần chú ý trong ghi nhận. Child Life dừng gợi ý theo lịch và không hiển thị nội dung trả phí ở đây.';

  @override
  String get rhHlNoted => 'Bạn đã ghi';

  @override
  String rhHlCallEmergency(String number) {
    return 'Gọi số khẩn cấp $number';
  }

  @override
  String get rhHlCallDoctor => 'Gọi bác sĩ của bé';

  @override
  String get rhHlHelper =>
      'Số khẩn cấp lấy theo quốc gia cư trú của hộ. Khu vực chưa có số trong danh sách thì chỉ hiện nút gọi bác sĩ.';

  @override
  String get rhHlNoRegion =>
      'Chưa có số khẩn cấp được duyệt cho khu vực của hộ. Nếu con có dấu hiệu nguy hiểm, hãy gọi cấp cứu nơi bạn sống.';

  @override
  String get rhHlWhileWaiting => 'Trong lúc chờ';

  @override
  String get rhHlDisclaimer =>
      'Child Life không chẩn đoán và không kết luận “an toàn”.';

  @override
  String get rhHlAlwaysFree => 'Không paywall, không mời nâng cấp';

  @override
  String get rhHlDialFailed => 'Không mở được ứng dụng Điện thoại.';

  @override
  String get rhSavedTitle => 'Đã lưu ghi nhận';

  @override
  String rhSeenBy(String names) {
    return '$names sẽ thấy';
  }

  @override
  String get rhSeenByOnlyYou => 'Chỉ bạn thấy';

  @override
  String get rhOneThing => 'Một việc có thể thử';

  @override
  String rhDurationFit(String duration, String range) {
    return '$duration · phù hợp $range';
  }

  @override
  String rhMonthsRange(int from, int to) {
    return '$from–$to tháng';
  }

  @override
  String get rhWhyThis => 'Vì sao gợi ý này';

  @override
  String rhWhyJustNoted(String summary) {
    return 'Bạn vừa ghi $summary.';
  }

  @override
  String rhWhyTriedOther(String tried) {
    return '$tried đã thử rồi nên gợi ý một cách khác.';
  }

  @override
  String get rhWhyHelpedBefore => 'Cách này từng được đánh giá “Có ích”.';

  @override
  String rhWhyData(String recent, String baseline) {
    return 'Từ nhật ký: tổng ngủ được ghi gần đây khoảng $recent mỗi ngày, mức thường của con $baseline.';
  }

  @override
  String get rhLater => 'Để sau';

  @override
  String rhSeeRhythm(String baby) {
    return 'Xem nhịp của con';
  }

  @override
  String get rhMoreForAge => 'Đọc thêm theo tuổi';

  @override
  String get rhFreeAgePill => 'Theo tuổi';

  @override
  String rhReadMinutes(int n) {
    return 'Đọc $n phút';
  }

  @override
  String get rhUpsellTitle => 'Muốn một gợi ý theo đúng tình huống?';

  @override
  String get rhUpsellBody =>
      'Hỗ trợ phù hợp với con chọn một việc từ ghi nhận của nhà mình và nhớ cách đã có ích.';

  @override
  String get rhLearnMoreOptional => 'Tìm hiểu thêm (tuỳ chọn)';

  @override
  String get rhNoSuggestionTitle => 'Chưa có gợi ý phù hợp';

  @override
  String get rhNoSuggestionBody =>
      'Ghi nhận đã lưu. Khi có nội dung hợp với con, gợi ý sẽ hiện ở Hôm nay.';

  @override
  String get rhSeeAgeContent => 'Xem nội dung theo tuổi';

  @override
  String get rhOfflineTitle => 'Ghi nhận vẫn lưu trên máy';

  @override
  String get rhOfflineBody =>
      'Sẽ đồng bộ khi có mạng. Gợi ý mới cần kết nối và sẽ hiện ở Hôm nay sau.';

  @override
  String get rhErrorTitle => 'Chưa lấy được gợi ý';

  @override
  String get rhErrorBody => 'Ghi nhận đã lưu. Thử lại sau một lát.';

  @override
  String get rhLoadingSuggestion => 'Đang chọn một việc có thể thử…';

  @override
  String get rhNotTried => 'Chưa thử';

  @override
  String rhTriedOn(String date) {
    return 'Đã thử · $date';
  }

  @override
  String rhSuggestionEyebrow(String duration) {
    return 'Gợi ý · $duration';
  }

  @override
  String rhBecauseNoted(String summary, String who, String date) {
    return 'Vì: $summary ($who ghi $date)';
  }

  @override
  String get rhHow => 'Cách làm';

  @override
  String get rhWhyItMayHelp => 'Vì sao có thể giúp';

  @override
  String get rhSafety => 'Lưu ý an toàn';

  @override
  String get rhIllTry => 'Mình sẽ thử';

  @override
  String get rhNotRight => 'Không phù hợp với con';

  @override
  String get rhAnotherIdea => 'Gợi ý khác';

  @override
  String get rhTellHow => 'Kể lại kết quả';

  @override
  String get rhStartedToast =>
      'Chúc cả nhà thuận lợi! Thử xong thì kể lại nhé.';

  @override
  String get rhNotRightToast =>
      'Đã ghi nhận. Sẽ không gợi ý lại cách này cho con.';

  @override
  String get rhActivityMissing => 'Gợi ý này không còn nữa';

  @override
  String get rhHowLastNight => 'Tối qua thế nào?';

  @override
  String get rhHowDidItGo => 'Lần thử thế nào?';

  @override
  String get rhHelpful => 'Có ích';

  @override
  String get rhUnsure => 'Chưa rõ';

  @override
  String get rhNotAFit => 'Không phù hợp';

  @override
  String get rhNoteHint => 'Ghi chú (tuỳ chọn)';

  @override
  String get rhFeedbackInfo =>
      'Phản hồi này được dùng để chọn gợi ý lần sau. “Có ích” không có nghĩa là cách này gây ra thay đổi.';

  @override
  String get rhSaveFeedback => 'Lưu phản hồi';

  @override
  String get rhFeedbackSaved => 'Đã lưu phản hồi';

  @override
  String get rhAgeTips => 'Điều có thể làm';

  @override
  String get rhAgeWatch => 'Khi nào nên hỏi bác sĩ';

  @override
  String get rhAgeEach =>
      'Mỗi bé mỗi khác. Đây là điều nhiều gia đình thấy ở tuổi này, không phải lịch bắt buộc.';

  @override
  String get rhSaveFailed =>
      'Chưa lưu được ghi nhận. Có thể quyền của bạn đã thay đổi.';

  @override
  String get rhTitle => 'Nhịp lớn lên';

  @override
  String rhBabyAge(String baby, String age) {
    return '$baby · $age';
  }

  @override
  String get rhCalendarUnsetPill => 'LỊCH THAM KHẢO · chưa thiết lập';

  @override
  String get rhCalendarUnsetTitle => 'Thêm ngày dự sinh để xem lịch tham khảo';

  @override
  String rhCalendarUnsetBody(String baby) {
    return 'Không có ngày dự sinh, bạn vẫn check-in và xem nội dung theo tuổi thực của $baby.';
  }

  @override
  String get rhAddDueDate => 'Thêm ngày dự sinh';

  @override
  String get rhDontRemember => 'Không nhớ';

  @override
  String get rhCalendarUnsetOthers =>
      'Ba mẹ (Cùng nuôi) có thể thêm ngày dự sinh để mở lịch tham khảo.';

  @override
  String get rhCalendarNoAccess =>
      'Lịch tham khảo tính từ ngày dự sinh, thuộc thông tin bé mà bạn chưa có quyền xem.';

  @override
  String get rhCalendarNoModel => 'Lịch tham khảo chưa được phát hành.';

  @override
  String get rhSeeCalendar => 'Xem lịch';

  @override
  String rhStageComingN(int n) {
    return 'Sắp đến giai đoạn $n (Wonder Weeks)';
  }

  @override
  String rhStageInN(int n) {
    return 'Đang trong giai đoạn $n (Wonder Weeks)';
  }

  @override
  String rhStageExpectedLine(String range, int days) {
    return 'Dự kiến $range · còn $days ngày đến giai đoạn';
  }

  @override
  String rhStageNowLine(String range) {
    return 'Dự kiến $range · trong khoảng tham khảo';
  }

  @override
  String get rhStagesDone => 'Đã qua các giai đoạn trong lịch tham khảo';

  @override
  String get rhCalendarDisclaimer =>
      'Đây là khoảng thời gian dự kiến theo lịch tham khảo. Lịch có thể không trùng với trải nghiệm của con.';

  @override
  String rhByDueDate(String date) {
    return 'Theo ngày dự sinh $date';
  }

  @override
  String rhByDueDateEstimated(String date) {
    return 'Theo ngày dự sinh ước tính $date';
  }

  @override
  String get rhOwnPill => 'NHỊP RIÊNG CỦA CON';

  @override
  String get rhOwnSparsePill => 'NHỊP RIÊNG CỦA CON · chưa đủ dữ liệu';

  @override
  String get rhOwnTitle => 'Điều nhà mình ghi nhận';

  @override
  String get rhOwnEmpty =>
      'Chưa có ghi nhận nào gần đây. Bạn vẫn có thể ghi nhận hôm nay.';

  @override
  String get rhOwnNoAccess =>
      'Ghi nhận của gia đình chỉ hiện với người được xem chăm sóc hằng ngày.';

  @override
  String get rhMixedDay => 'Ghi khác nhau';

  @override
  String get rhMixedNote =>
      'Hai người ghi khác nhau trong cùng ngày được giữ nguyên cả hai.';

  @override
  String rhWhoDay(String who, String date) {
    return '$who · $date';
  }

  @override
  String get rhRecordToday => 'Ghi nhận hôm nay';

  @override
  String rhSleepHeading(int days) {
    return 'Tổng ngủ được ghi · $days ngày';
  }

  @override
  String get rhSleepSparseTitle => 'Nhà mình chưa có đủ nhật ký để so sánh.';

  @override
  String rhSleepSparseBody(int valid, int need, int more) {
    return '$valid/$need ngày ghi đủ giấc ngủ · cần thêm $more ngày để so sánh. Không ghi không có nghĩa là bé ngủ ít.';
  }

  @override
  String rhSleepSparseRecent(int need, int days) {
    return 'Cần ít nhất $need trong $days ngày gần nhất được ghi đủ để so sánh. Không ghi không có nghĩa là bé ngủ ít.';
  }

  @override
  String rhSleepLower(String delta) {
    return 'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi thấp hơn khoảng $delta so với trước.';
  }

  @override
  String rhSleepHigher(String delta) {
    return 'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi cao hơn khoảng $delta so với trước.';
  }

  @override
  String get rhSleepSame =>
      'Trong các ngày ghi đủ gần đây, tổng ngủ được ghi gần với mức thường của con.';

  @override
  String rhSleepBasis(int recent, String range, int baseline) {
    return 'Căn cứ: $recent ngày gần nhất ($range) so với $baseline ngày ghi đủ trước đó. Không phải chẩn đoán.';
  }

  @override
  String rhSleepUsual(String value) {
    return 'mức thường $value';
  }

  @override
  String get rhSleepMissingLegend => 'ngày ghi thiếu, không tính';

  @override
  String get rhSleepGateTitle => 'So sánh giấc ngủ từ nhật ký';

  @override
  String get rhSleepGatePremium =>
      'So sánh với mức thường của con thuộc Hỗ trợ phù hợp. Ghi nhận, lịch tham khảo và hướng dẫn sức khoẻ vẫn dùng bình thường.';

  @override
  String get rhSleepGateOther =>
      'Phần so sánh giấc ngủ chưa mở cho bạn. Ghi nhận và lịch tham khảo vẫn dùng được.';

  @override
  String get rhWhy => 'Vì sao?';

  @override
  String get rhTriedHeading => 'Cách nhà mình đã thử';

  @override
  String get rhFooterFacts =>
      'Thông tin là ghi nhận của gia đình, không phải chẩn đoán.';

  @override
  String get rhOutOfAge =>
      'Nhịp lớn lên đang hỗ trợ bé 0–12 tháng. Với bé lớn hơn, dữ liệu đã ghi vẫn xem được; nội dung mới chưa hỗ trợ.';

  @override
  String get rhOfflineNote =>
      'Ngoại tuyến: đang hiện dữ liệu đã lưu trên máy · ghi nhận sẽ được gửi khi có mạng.';

  @override
  String get rhRegionOwnerBody =>
      'Chọn khu vực để Child Life dùng đúng nội dung và số khẩn cấp. Lịch tham khảo và ghi nhận vẫn dùng được.';

  @override
  String get rhRegionPick => 'Chọn khu vực';

  @override
  String get rhRegionWaiting =>
      'Đang chờ chủ hộ chọn khu vực. Ghi nhận, lịch tham khảo và nội dung cơ bản vẫn dùng được.';

  @override
  String get rhSetupIntro =>
      'Tham khảo điều có thể đến, hiểu điều con đang trải qua.';

  @override
  String get rhLayerCalendarTitle => 'Lịch tham khảo';

  @override
  String get rhLayerCalendarBody =>
      'Khoảng thời gian dự kiến theo mô hình Wonder Weeks, tính từ ngày dự sinh. Mỗi bé mỗi khác — lịch chỉ để tham khảo.';

  @override
  String get rhLayerCalendarBasis =>
      'Căn cứ: ngày dự sinh + mô hình tham khảo đã phát hành';

  @override
  String get rhLayerOwnTitle => 'Nhịp riêng của con';

  @override
  String get rhLayerOwnBody =>
      'Những gì cả nhà ghi nhận: giấc ngủ, nhu cầu được dỗ, điều mới. Child Life tóm tắt thay đổi và cách nhà mình đã thử.';

  @override
  String get rhLayerOwnBasis => 'Căn cứ: check-in và nhật ký chăm sóc';

  @override
  String get rhSetupDisclaimer =>
      'Child Life không dự đoán chắc chắn ngày quấy hay chẩn đoán nguyên nhân.';

  @override
  String get rhStart => 'Bắt đầu';

  @override
  String rhDueTitle(String baby) {
    return 'Ngày dự sinh của $baby';
  }

  @override
  String rhDueBody(String baby, String dob) {
    return 'Lịch tham khảo tính từ ngày dự sinh, không phải ngày sinh. Bé sinh ngày $dob.';
  }

  @override
  String get rhDueBodyNoDob =>
      'Lịch tham khảo tính từ ngày dự sinh, không phải ngày sinh.';

  @override
  String get rhDueField => 'Ngày dự sinh';

  @override
  String get rhDuePick => 'Chọn ngày';

  @override
  String get rhEstimateTitle => 'Không nhớ ngày dự sinh?';

  @override
  String get rhEstimateBody => 'Ước tính từ tuổi thai khi sinh:';

  @override
  String rhWeeks(int n) {
    return '$n tuần';
  }

  @override
  String rhPlusDays(int n) {
    return '+ $n ngày';
  }

  @override
  String rhEstimateResult(String date) {
    return 'Dự sinh ước tính: $date · gắn nhãn “ước tính”';
  }

  @override
  String get rhEstimateAdvice =>
      'Bé sinh rất non hoặc có nhu cầu đặc biệt: hỏi bác sĩ trước khi dùng lịch.';

  @override
  String get rhEstimateNeedsDob => 'Cần ngày sinh của bé để ước tính.';

  @override
  String get rhDueOutOfRange =>
      'Ngày dự sinh cần trong khoảng 4 tuần trước đến 18 tuần sau ngày sinh.';

  @override
  String get rhSkipOwnOnly => 'Bỏ qua — chỉ dùng nhịp riêng của con';

  @override
  String get rhDueHelper =>
      'Sửa lại lúc nào cũng được · lịch và nhắc sẽ tính lại';

  @override
  String get rhDueSaved => 'Đã lưu ngày dự sinh';

  @override
  String get rhDueRemove => 'Xoá ngày dự sinh';

  @override
  String get rhDueRemoved => 'Đã xoá ngày dự sinh';

  @override
  String get rhDueSaveFailed =>
      'Chưa lưu được ngày dự sinh. Kiểm tra kết nối rồi thử lại.';

  @override
  String get rhDueSetupOnly => 'Chỉ ba mẹ (Cùng nuôi) đặt được ngày dự sinh.';

  @override
  String get rhEstimatedTag => 'ước tính';

  @override
  String get rhWeeksPickerTitle => 'Tuổi thai khi sinh';

  @override
  String get rhDaysPickerTitle => 'Thêm số ngày';

  @override
  String get rhRemindTitle => 'Nhắc bạn khi nào?';

  @override
  String get rhRemindBody =>
      'Tất cả đều tuỳ chọn. Tối đa 1 thông báo Nhịp lớn lên mỗi ngày.';

  @override
  String get rhRemindStage => 'Trước giai đoạn tham khảo';

  @override
  String get rhRemindStageSub => '3 ngày trước · tối đa 1 lần mỗi giai đoạn';

  @override
  String get rhRemindEvening => 'Check-in buổi tối';

  @override
  String get rhRemindEveningSub => '20:30 · bỏ qua nếu đã ghi trong ngày';

  @override
  String get rhQuietHours => 'Giờ yên lặng';

  @override
  String rhQuietRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get rhQuietOff => 'Tắt';

  @override
  String get rhQuietSub => 'Không gửi gợi ý, chỉ nhắc việc bạn đặt';

  @override
  String get rhQuietTo => 'đến';

  @override
  String get rhRemindDevice =>
      'Nhắc được lưu trên máy này; giờ yên lặng theo tài khoản của bạn.';

  @override
  String get rhNoLeapRisk => 'Không có thông báo kiểu “nguy cơ leap cao”.';

  @override
  String rhCalendarBasis(String model, String date) {
    return 'Mô hình $model · theo ngày dự sinh $date';
  }

  @override
  String rhCalendarBasisEstimated(String model, String date) {
    return 'Mô hình $model · theo ngày dự sinh ước tính $date';
  }

  @override
  String get rhChange => 'Đổi';

  @override
  String rhTodayBefore(String date, int n) {
    return 'Hôm nay · $date · trước giai đoạn $n';
  }

  @override
  String rhTodayIn(String date, int n) {
    return 'Hôm nay · $date · trong giai đoạn $n';
  }

  @override
  String rhTodayPlain(String date) {
    return 'Hôm nay · $date';
  }

  @override
  String rhStageUpcoming(int days) {
    return 'Sắp tới · còn $days ngày';
  }

  @override
  String get rhStageCurrent => 'Đang trong khoảng dự kiến';

  @override
  String get rhStagePast => 'Đã qua';

  @override
  String rhStagesOverlap(int a, int b) {
    return 'Giai đoạn $a và $b chồng nhau · cả hai đều chỉ là tham khảo';
  }

  @override
  String rhStageShort(int n) {
    return 'Giai đoạn $n';
  }

  @override
  String rhCalendarFooter(String version) {
    return 'Lịch là mô hình tham khảo, chưa được chứng minh chính xác cho từng bé. Mô hình $version.';
  }

  @override
  String rhNotPartner(String label) {
    return '$label được dùng làm tham khảo, không phải đối tác.';
  }

  @override
  String rhStageDetailExpected(String range, String baby) {
    return 'Dự kiến $range · có thể không trùng với trải nghiệm của $baby';
  }

  @override
  String get rhSignsTitle => 'Dấu hiệu có thể gặp';

  @override
  String get rhSignsNormal =>
      'Một số bé không có thay đổi rõ — điều đó bình thường';

  @override
  String get rhSkillsTitle => 'Kỹ năng tham khảo theo tuổi';

  @override
  String get rhSkillsNote =>
      'Kỹ năng không bắt buộc khớp với giai đoạn này. Theo dõi kỹ năng theo tuổi không thay cho sàng lọc chuyên môn.';

  @override
  String get rhActivitiesTitle => 'Hoạt động phù hợp';

  @override
  String get rhSourcesReview => 'Nguồn & duyệt';

  @override
  String rhModelVersion(String version) {
    return 'Mô hình $version';
  }

  @override
  String get rhSameAsUsual => 'Con vẫn như mọi ngày';

  @override
  String get rhStageMissing => 'Giai đoạn này không còn trong lịch tham khảo.';

  @override
  String get rhMsConfirmTitle => 'Lưu điều mới thành mốc?';

  @override
  String rhMsConfirmBody(String baby) {
    return 'Mốc được lưu vào Kỷ niệm của $baby để gắn ảnh và làm thẻ mốc. Ảnh không bị sao chép.';
  }

  @override
  String get rhMsName => 'Tên mốc';

  @override
  String get rhMsSavedTitle => 'Đã lưu điều mới';

  @override
  String rhMsSavedSub(String name, String date, String who) {
    return '$name · $date · $who xác nhận';
  }

  @override
  String get rhMsKeepTitle => 'Giữ khoảnh khắc này?';

  @override
  String get rhMsBasic => 'Thẻ mốc cơ bản';

  @override
  String get rhMsPremium => 'Thẻ mốc Premium';

  @override
  String get rhMsCreateCard => 'Tạo thẻ mốc';

  @override
  String get rhMsPhotoNote => 'Chọn ảnh từ Kỷ niệm khi tạo thẻ.';

  @override
  String get rhMsRoleTitle => 'Chỉ ba mẹ lưu được mốc';

  @override
  String get rhMsRoleBody =>
      'Bạn vẫn ghi được điều mới trong ghi nhận; ba mẹ (Cùng nuôi) xác nhận mốc.';

  @override
  String get rhMsSaveFailed => 'Chưa lưu được mốc. Thử lại sau.';

  @override
  String get rhPersonalize => 'Cá nhân hoá';

  @override
  String get rhPersonalizeSub => 'Điều bạn quan tâm, giờ nhận gợi ý, phản hồi';

  @override
  String get rhPersonalizeNote =>
      'Các lựa chọn này của riêng bạn, không đổi cài đặt của người khác trong nhà.';

  @override
  String get rhInterestsRow => 'Điều bạn quan tâm';

  @override
  String get rhDigestRow => 'Giờ nhận gợi ý';

  @override
  String get rhRemindRow => 'Nhắc Nhịp lớn lên';

  @override
  String get rhHistoryRow => 'Lịch sử phản hồi';

  @override
  String get rhInterestsNone => 'Chưa chọn';

  @override
  String rhInterestsTitle(String baby) {
    return 'Bạn muốn đồng hành cùng $baby ở những gì?';
  }

  @override
  String get rhInterestsBody =>
      'Hôm nay và gợi ý sẽ ưu tiên những mục này. Đổi lại lúc nào cũng được.';

  @override
  String get rhInterestsToday =>
      'Đây là điều bạn quan tâm lâu dài. Điều con cần hôm nay thì ghi ở “Hôm nay con có gì khác?”.';

  @override
  String get rhIntSleep => 'Giấc ngủ';

  @override
  String get rhIntSleepSub => 'Nhịp ngủ, nhịp lớn lên';

  @override
  String get rhIntFeeding => 'Bú & sữa';

  @override
  String get rhIntFeedingSub => 'Lượng sữa theo tuổi';

  @override
  String get rhIntMilestones => 'Mốc phát triển';

  @override
  String get rhIntMilestonesSub => 'Gợi ý mốc theo tuần tuổi';

  @override
  String get rhIntVaccines => 'Tiêm chủng';

  @override
  String get rhIntVaccinesSub => 'Nhắc trước lịch tiêm';

  @override
  String get rhIntNutrition => 'Dinh dưỡng';

  @override
  String get rhIntNutritionSub => 'Vi chất, vitamin theo tháng';

  @override
  String get rhIntMoments => 'Kỷ niệm';

  @override
  String get rhIntMomentsSub => 'Gợi ý ghi lại khoảnh khắc';

  @override
  String get rhFewerTitle => 'Đang ít gợi ý hơn về';

  @override
  String get rhFewerUndo => 'Bỏ';

  @override
  String rhSaveCount(int count) {
    return 'Lưu · $count mục';
  }

  @override
  String get rhSkip => 'Bỏ qua';

  @override
  String get rhPrefsSaved => 'Đã lưu lựa chọn của bạn';

  @override
  String get rhDigestTitle => 'Khi nào bạn tiện đọc gợi ý?';

  @override
  String get rhDigestBody =>
      'Child Life gom gợi ý trong ngày vào một lần, đúng giờ bạn chọn. Nhắc việc bạn tự đặt (bú, tiêm…) vẫn đến đúng giờ.';

  @override
  String get rhDigestMorning => 'Buổi sáng';

  @override
  String get rhDigestNoon => 'Giờ nghỉ trưa';

  @override
  String get rhDigestEvening => 'Buổi tối';

  @override
  String get rhDigestNone => 'Không gom gợi ý';

  @override
  String get rhEditHistoryLink => 'Bạn có thể chỉnh hoặc xoá lịch sử phản hồi';

  @override
  String get rhHistoryTitle => 'Lịch sử phản hồi';

  @override
  String rhHistoryBody(int days) {
    return 'Phản hồi của bạn trong $days ngày gần đây. Xoá một phản hồi thì gợi ý lần sau không dựa vào nó nữa.';
  }

  @override
  String get rhHistoryEmpty => 'Bạn chưa có phản hồi nào gần đây.';

  @override
  String get rhDelete => 'Xoá';

  @override
  String get rhDeleteFeedbackTitle => 'Xoá phản hồi này?';

  @override
  String get rhDeleteFeedbackBody =>
      'Gợi ý lần sau sẽ không dựa vào phản hồi này nữa.';

  @override
  String get rhFeedbackDeleted => 'Đã xoá phản hồi';

  @override
  String get rhResetInterests => 'Đặt lại điều bạn quan tâm';

  @override
  String get rhResetInterestsBody =>
      'Bỏ chọn mọi chủ đề và các mục “Ít gợi ý kiểu này hơn”.';

  @override
  String get rhResetDone => 'Đã đặt lại điều bạn quan tâm';

  @override
  String get rhUnknownActivity => 'Gợi ý không còn trong nội dung';

  @override
  String get rhFewerLikeThis => 'Ít gợi ý kiểu này hơn';

  @override
  String rhFewerToast(String topic) {
    return 'Đã ghi nhận. Bạn sẽ thấy ít gợi ý về $topic hơn.';
  }

  @override
  String get rhOtherIdeas => 'Cách khác có thể thử';

  @override
  String get aiHandoverTitle => 'Bàn giao cho người chăm tiếp';

  @override
  String get aiHandoverEntrySub => 'Tóm tắt 3 phần từ ghi nhận của cả nhà';

  @override
  String aiHandoverEntryLatest(String date) {
    return 'Bản mới nhất · $date';
  }

  @override
  String aiHandoverFrom(String range, int count, String names) {
    return '$range · từ $count ghi nhận của $names';
  }

  @override
  String aiHandoverFromCount(String range, int count) {
    return '$range · từ $count ghi nhận';
  }

  @override
  String aiGeneratedAt(String when) {
    return 'Tạo lúc $when';
  }

  @override
  String get aiSectionNoticed => 'Điều đã thấy';

  @override
  String get aiSectionHelped => 'Cách từng có ích';

  @override
  String get aiSectionNext => 'Việc có thể chọn tiếp';

  @override
  String get aiSectionNote => 'Lưu ý';

  @override
  String get aiWordedByAi =>
      'Diễn đạt bởi AI từ ghi nhận đã lưu · số liệu lấy từ nhật ký';

  @override
  String get aiWordedShort => 'Diễn đạt bởi AI từ ghi nhận đã lưu';

  @override
  String get aiTemplateLine => 'Đây là tóm tắt từ những ghi nhận đã lưu.';

  @override
  String get aiReport => 'Chưa đúng? Báo lại';

  @override
  String aiSendTo(String name) {
    return 'Gửi cho $name';
  }

  @override
  String get aiShare => 'Gửi bản bàn giao';

  @override
  String get aiShareAiLine => '(Diễn đạt bởi AI từ ghi nhận đã lưu)';

  @override
  String get aiShareTemplateLine => '(Tóm tắt theo mẫu từ ghi nhận đã lưu)';

  @override
  String get aiLoading => 'Đang tổng hợp ghi nhận…';

  @override
  String get aiNoSections =>
      'Chưa có đủ ghi nhận để bàn giao. Ghi nhận hôm nay để bắt đầu.';

  @override
  String aiChipCheckIn(String who, String date) {
    return 'Ghi nhận của $who · $date';
  }

  @override
  String aiChipCheckInMine(String date) {
    return 'Ghi nhận của bạn · $date';
  }

  @override
  String aiChipFeedback(String who, String date) {
    return 'Phản hồi của $who · $date';
  }

  @override
  String aiChipFeedbackMine(String date) {
    return 'Phản hồi của bạn · $date';
  }

  @override
  String aiChipMilestone(String date) {
    return 'Điều mới · $date';
  }

  @override
  String get aiChipSleep => 'Nhật ký giấc ngủ';

  @override
  String aiRecordWho(String who, String date) {
    return '$who · $date';
  }

  @override
  String get aiRecordCheckIn => 'Ghi nhận';

  @override
  String get aiRecordFeedback => 'Phản hồi';

  @override
  String get aiRecordMilestone => 'Điều mới';

  @override
  String get aiRecordOpenActivity => 'Xem hoạt động';

  @override
  String get aiRecordGone =>
      'Ghi nhận này không còn trên máy hoặc đã được xoá.';

  @override
  String get aiStateTemplateTitle => 'Đang hiển thị bản theo mẫu';

  @override
  String get aiStateConsentEyebrow => 'AI CHƯA BẬT';

  @override
  String get aiStateConsentBody =>
      'Bản này dùng mẫu cố định, vẫn đủ 3 phần. Nếu bạn đồng ý, AI chỉ diễn đạt lại những ghi nhận đã lưu.';

  @override
  String get aiStateConsentAction => 'Xem và đồng ý dùng AI';

  @override
  String get aiStateOffEyebrow => 'AI ĐANG TẮT';

  @override
  String get aiStateWithdrawnBody =>
      'Bạn đã tắt AI. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần: điều đã thấy, cách từng có ích, việc có thể chọn tiếp.';

  @override
  String get aiStateWithdrawnAction => 'Bật AI trong Cài đặt';

  @override
  String get aiStateDisabledBody =>
      'Tóm tắt bằng AI đang tạm dừng. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần.';

  @override
  String get aiStateErrorEyebrow => 'AI CHƯA PHẢN HỒI';

  @override
  String get aiStateErrorBody =>
      'Không trừ lượt AI khi lỗi. Ghi nhận và hướng dẫn sức khoẻ không bị ảnh hưởng.';

  @override
  String get aiStateQuotaEyebrow => 'ĐÃ DÙNG HẾT LƯỢT AI';

  @override
  String aiStateQuotaDay(int used, int limit, String when) {
    return 'Đã dùng $used/$limit lượt AI hôm nay cho bé. Lượt mới từ $when. Bạn vẫn xem được bản theo mẫu.';
  }

  @override
  String aiStateQuotaMonth(int used, int limit, String when) {
    return 'Nhà mình đã dùng $used/$limit lượt AI kỳ này (chung cho tóm tắt và trợ lý). Lượt mới từ $when. Bạn vẫn xem được bản theo mẫu.';
  }

  @override
  String get aiStateQuotaPlain =>
      'Nhà mình đã dùng hết lượt AI trong kỳ này. Bạn vẫn xem được bản theo mẫu.';

  @override
  String get aiStateTemplateEyebrow => 'BẢN THEO MẪU';

  @override
  String get aiStatePremiumBody =>
      'Tóm tắt bằng AI nằm trong Child Life Premium. Bạn vẫn xem được bản theo mẫu.';

  @override
  String get aiStateOtherBody =>
      'AI chưa dùng được cho nhà mình lúc này. Bản theo mẫu vẫn đủ 3 phần.';

  @override
  String get aiStateStaleTitle => 'Có ghi nhận mới';

  @override
  String get aiStateStaleBody =>
      'Bản này được tạo trước những ghi nhận mới nhất.';

  @override
  String get aiStateStaleRead =>
      'Bản này được tạo trước những ghi nhận mới nhất. Ba mẹ có thể tạo lại.';

  @override
  String get aiStateStaleAction => 'Tạo lại';

  @override
  String get aiStateOfflineEyebrow => 'NGOẠI TUYẾN';

  @override
  String get aiStateOfflineTitle => 'Đang xem bản đã lưu';

  @override
  String get aiStateOfflineBody =>
      'Bản mới và AI cần kết nối. Ghi nhận vẫn lưu trên máy và sẽ đồng bộ khi có mạng.';

  @override
  String get aiStateOfflineEmptyTitle => 'Chưa có bản bàn giao trên máy';

  @override
  String get aiStateFailedTitle => 'Chưa tạo được bản bàn giao';

  @override
  String get aiStateFailedBody =>
      'Ghi nhận của nhà mình vẫn giữ nguyên. Không trừ lượt AI khi lỗi.';

  @override
  String get aiReadEmptyTitle => 'Chưa có bản bàn giao';

  @override
  String get aiReadEmptyBody =>
      'Khi ba mẹ tạo bản bàn giao, bản mới nhất sẽ hiện ở đây.';

  @override
  String get aiHealthBody =>
      'Hôm nay có dấu hiệu sức khoẻ được ghi nhận, nên bàn giao không dùng AI. Hãy xem hướng dẫn sức khoẻ trước.';

  @override
  String get aiReportTitle => 'Điều gì chưa đúng?';

  @override
  String get aiReportBody => 'Chọn một lý do. Không cần viết thêm về bé.';

  @override
  String get aiProblemWrongFact => 'Không khớp với điều nhà mình ghi';

  @override
  String get aiProblemWrongPerson => 'Nhầm người ghi';

  @override
  String get aiProblemUnsafe => 'Lời khuyên không an toàn';

  @override
  String get aiProblemLanguage => 'Diễn đạt khó hiểu';

  @override
  String get aiProblemOther => 'Lý do khác';

  @override
  String get aiReportSend => 'Gửi báo lại';

  @override
  String get aiReportThanks => 'Cảm ơn bạn. Bản tóm tắt này sẽ được xem lại.';

  @override
  String get aiReportFailed => 'Chưa gửi được. Kiểm tra kết nối và thử lại.';

  @override
  String get aiConsentTitle => 'Tóm tắt bằng AI';

  @override
  String get aiConsentIntro =>
      'Khi bạn đồng ý, Child Life có thể nhờ một dịch vụ AI bên ngoài diễn đạt lại những ghi nhận đã lưu thành bản bàn giao và lời giải thích. AI không thêm điều mới; mọi số liệu vẫn lấy từ nhật ký.';

  @override
  String get aiConsentSentTitle => 'Được gửi đi';

  @override
  String get aiConsentSent1 =>
      'Những ghi nhận dạng chữ đã lưu: điều đã thấy, cách đã thử, phản hồi, điều mới';

  @override
  String get aiConsentSent2 => 'Tên gọi ở nhà của bé và ngày của từng ghi nhận';

  @override
  String get aiConsentNeverTitle => 'Không bao giờ gửi';

  @override
  String get aiConsentNever1 => 'Ảnh và video';

  @override
  String get aiConsentNever2 => 'Họ tên đầy đủ và ngày sinh của bé';

  @override
  String get aiConsentNever3 => 'Ghi nhận về dấu hiệu sức khoẻ';

  @override
  String get aiConsentWhereTitle => 'Ai xử lý, lưu ở đâu';

  @override
  String get aiConsentWhere1 =>
      'Một dịch vụ AI bên ngoài diễn đạt lại; máy chủ Child Life gửi yêu cầu, điện thoại không gửi trực tiếp.';

  @override
  String get aiConsentWhere2 =>
      'Nhà cung cấp AI không được lưu giữ dữ liệu này.';

  @override
  String get aiConsentWhere3 =>
      'Bản tóm tắt được lưu trong nhà mình. Thu hồi đồng ý sẽ xoá phần chữ do AI viết; bản theo mẫu vẫn dùng được.';

  @override
  String get aiConsentShareNotes =>
      'Cho phép ghi chú của tôi được dùng khi người khác trong nhà tạo tóm tắt';

  @override
  String get aiConsentShareNotesSub =>
      'Nếu tắt, ghi chú bạn tự viết không được gửi khi người khác tạo tóm tắt.';

  @override
  String get aiConsentPersonal =>
      'Đồng ý này là của riêng bạn; gói của hộ không thay cho nó. Bạn đổi ý lúc nào cũng được.';

  @override
  String aiConsentVersion(String version) {
    return 'Phiên bản đồng ý: $version';
  }

  @override
  String get aiConsentAgree => 'Đồng ý dùng AI';

  @override
  String aiConsentGranted(String date) {
    return 'Bạn đã đồng ý ngày $date';
  }

  @override
  String get aiConsentOutdated =>
      'Nội dung đồng ý đã cập nhật. Hãy xem lại để tiếp tục dùng AI.';

  @override
  String get aiConsentWithdraw => 'Thu hồi đồng ý';

  @override
  String get aiWithdrawTitle => 'Thu hồi đồng ý?';

  @override
  String get aiWithdrawBody =>
      'AI sẽ không được dùng cho tóm tắt bạn tạo nữa. Phần chữ do AI viết sẽ bị xoá; bản theo mẫu vẫn dùng được.';

  @override
  String get aiWithdrawConfirm => 'Thu hồi';

  @override
  String get aiConsentSaved => 'Đã lưu lựa chọn của bạn';

  @override
  String get aiWithdrawn => 'Đã thu hồi đồng ý';

  @override
  String get aiConsentFailed => 'Chưa lưu được. Kiểm tra kết nối và thử lại.';

  @override
  String get aiConsentOn => 'Đang bật';

  @override
  String get aiConsentOff => 'Đang tắt';

  @override
  String get aiExplainMore => 'Giải thích thêm';

  @override
  String get aiExplainLoading => 'Đang chuẩn bị lời giải thích…';

  @override
  String get aiExplainFailed =>
      'Chưa giải thích thêm được lúc này. Lý do ở trên vẫn đầy đủ.';

  @override
  String get aiExplainConsent => 'Cần bạn đồng ý dùng AI để giải thích thêm.';

  @override
  String get aiExplainQuota =>
      'Đã dùng hết lượt AI trong kỳ này. Lý do ở trên vẫn đầy đủ.';

  @override
  String get aiExplainUnavailable =>
      'Giải thích thêm chưa dùng được cho nhà mình lúc này.';

  @override
  String get rhEpSuggestTitle => 'Nhóm thành một đợt quan sát?';

  @override
  String rhEpSuggestBody(int count, String people, String what) {
    return '$count ngày gần đây có ghi nhận thay đổi: $people thấy $what.';
  }

  @override
  String rhEpPersonDay(String who, String date) {
    return '$who ($date)';
  }

  @override
  String get rhEpNotWonder =>
      'Đây chỉ là cách nhà mình theo dõi, không phải xác nhận một giai đoạn Wonder Weeks.';

  @override
  String get rhEpCreate => 'Tạo đợt quan sát';

  @override
  String get rhEpNoNeed => 'Không cần';

  @override
  String rhEpOpenTitle(String start) {
    return 'Đợt quan sát $start – nay';
  }

  @override
  String get rhEpUpdating => 'Đang cập nhật';

  @override
  String rhEpOpenBody(String who, int count) {
    return '$who xác nhận nhóm $count ghi nhận thành một đợt. Đợt kết thúc khi cả nhà xác nhận “con đã ổn hơn”.';
  }

  @override
  String get rhEpBetter => 'Con đã ổn hơn';

  @override
  String get rhEpCloseTitle => 'Kết thúc đợt quan sát?';

  @override
  String rhEpCloseBody(String start) {
    return 'Đợt sẽ được lưu từ $start đến hôm nay. Child Life không tự kết thúc đợt khi không có ghi nhận.';
  }

  @override
  String get rhEpNotYet => 'Chưa';

  @override
  String get rhEpCreated => 'Đã tạo đợt quan sát';

  @override
  String get rhEpClosed => 'Đã kết thúc đợt quan sát';

  @override
  String get rhEveningBody =>
      'Ghi lại một điều trong vài giây, nếu có. Không có gì khác cũng không sao.';

  @override
  String get pmPaywallSubtitle =>
      'Một gói cho cả hộ. Mở cả hai nhóm quyền lợi.';

  @override
  String get pmPaywallHere => 'Bạn đang xem';

  @override
  String get pmGroupATitle => 'A · Cá nhân hoá & Nhịp lớn lên nâng cao';

  @override
  String get pmGroupA1 => 'Một việc phù hợp mỗi ngày từ ghi nhận của nhà mình';

  @override
  String get pmGroupA2 => 'Nhớ cách đã có ích, bàn giao cho người chăm';

  @override
  String get pmGroupA3 => 'Tóm tắt AI có căn cứ (có hạn mức)';

  @override
  String get pmGroupBTitle => 'B · Mẫu thẻ & video Premium';

  @override
  String get pmGroupB1 => 'Toàn bộ thư viện mẫu Premium';

  @override
  String get pmGroupB2 => 'Thêm lượt xuất video mỗi kỳ';

  @override
  String get pmPaywallFreeBody =>
      'Ghi chép, lịch sử, nhắc việc, lịch tham khảo (Wonder Weeks), mẫu cơ bản, hướng dẫn sức khoẻ thiết yếu. Hết gói vẫn xem dữ liệu, kỷ niệm và file đã xuất.';

  @override
  String get pmPeriodMonthly => 'Theo tháng';

  @override
  String get pmPeriodYearly => 'Theo năm';

  @override
  String pmRenewMonthly(String price) {
    return '$price mỗi tháng, tự động gia hạn đến khi bạn huỷ.';
  }

  @override
  String pmRenewYearly(String price) {
    return '$price mỗi năm, tự động gia hạn đến khi bạn huỷ.';
  }

  @override
  String pmRenewTerms(String store) {
    return 'Thanh toán qua tài khoản $store khi bạn xác nhận. Gói tự gia hạn trừ khi bạn tắt ít nhất 24 giờ trước khi kỳ hiện tại kết thúc; quản lý và huỷ trong cài đặt $store.';
  }

  @override
  String get pmStoreApple => 'App Store';

  @override
  String get pmStoreGoogle => 'Google Play';

  @override
  String get pmContinuePremium => 'Tiếp tục với Premium';

  @override
  String get pmStoreLegal =>
      'Giá, kỳ hạn và gia hạn hiển thị theo cửa hàng · huỷ trong cài đặt cửa hàng';

  @override
  String get pmTerms => 'Điều khoản sử dụng';

  @override
  String get pmPrivacy => 'Quyền riêng tư';

  @override
  String get pmRestore => 'Khôi phục';

  @override
  String get pmBuyClosedTitle => 'Mua trong app sắp có';

  @override
  String get pmBuyClosedBody =>
      'Child Life Premium chưa bán trong app. Mọi thứ khác vẫn dùng bình thường; Child Life sẽ báo khi mở.';

  @override
  String get pmAskOwnerTitle => 'Nhờ chủ hộ nâng cấp';

  @override
  String get pmAskOwnerBody =>
      'Chỉ chủ hộ mua và quản lý gói. Khi hộ có Premium, cả nhà cùng dùng.';

  @override
  String get pmHouseholdHasBody =>
      'Premium đang mở cho cả nhà. Chỉ chủ hộ quản lý gói.';

  @override
  String get pmPendingTitle => 'Đang chờ xác nhận thanh toán';

  @override
  String get pmPendingBody =>
      'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Lựa chọn mẫu và ảnh của bạn vẫn được giữ.';

  @override
  String get pmPendingBodyPlain =>
      'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Bạn có thể đóng và kiểm tra lại sau.';

  @override
  String get pmCheckAgain => 'Kiểm tra lại';

  @override
  String get pmClose => 'Đóng';

  @override
  String get pmSuccessTitle => 'Hộ đã có Premium';

  @override
  String pmSuccessTemplate(String name) {
    return 'Tiếp tục đúng mẫu “$name” với ảnh bạn đã chọn.';
  }

  @override
  String get pmSuccessRhythm =>
      'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI đã mở cho cả nhà.';

  @override
  String get pmContinueCard => 'Tiếp tục tạo thẻ';

  @override
  String get pmContinueVideo => 'Tiếp tục tạo video';

  @override
  String get pmBackToRhythm => 'Về Nhịp lớn lên';

  @override
  String get pmDone => 'Xong';

  @override
  String get pmErrorTitle => 'Chưa mua được';

  @override
  String get pmErrorBody =>
      'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại hoặc dùng mẫu cơ bản.';

  @override
  String get pmErrorBodyPlain =>
      'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại sau nhé.';

  @override
  String get pmErrorVerifyBody =>
      'Child Life chưa xác minh được giao dịch với cửa hàng. Premium chưa được mở. Nếu cửa hàng đã trừ tiền, bấm Thử lại hoặc Khôi phục.';

  @override
  String get pmErrorNetworkBody =>
      'Chưa kết nối được Child Life. Giao dịch của cửa hàng vẫn được giữ để kiểm tra lại.';

  @override
  String get pmTryAgain => 'Thử lại';

  @override
  String get pmNotOwnerTitle => 'Chỉ chủ hộ mua và khôi phục gói';

  @override
  String get pmNotOwnerBody =>
      'Nhờ chủ hộ mở Gói của hộ để nâng cấp hoặc khôi phục.';

  @override
  String get pmRestoreTitle => 'Khôi phục giao dịch';

  @override
  String get pmRestoreBody =>
      'Child Life kiểm tra giao dịch thuộc tài khoản này và gắn lại cho hộ của bạn. Không chuyển gói từ hộ khác.';

  @override
  String get pmCancel => 'Huỷ';

  @override
  String get pmRestoredTitle => 'Đã khôi phục Premium';

  @override
  String get pmRestoredBody =>
      'Gói của bạn đã gắn lại với hộ này. Cả nhà thấy “Hộ đã có Premium”.';

  @override
  String get pmRestoreNoneTitle => 'Không có giao dịch để khôi phục';

  @override
  String get pmRestoreNoneBody =>
      'Tài khoản cửa hàng này chưa có gói Child Life Premium còn hiệu lực.';

  @override
  String get pmRestoreBoundTitle => 'Gói đang dùng cho hộ khác';

  @override
  String get pmRestoreBoundBody =>
      'Giao dịch này đã gắn với một hộ khác. Child Life không chuyển gói giữa các hộ; liên hệ hỗ trợ nếu cần.';

  @override
  String get pmTemplateKeepsPhotos => 'Ảnh bạn đã chọn sẽ được giữ sau khi mua';

  @override
  String get pmResumedBanner => 'Đã mở Premium · tiếp tục chỗ bạn đang làm';

  @override
  String get pmManageApple => 'Quản lý trong App Store';

  @override
  String get pmManageGoogle => 'Quản lý trong Google Play';

  @override
  String get pmSeePremium => 'Xem Premium';

  @override
  String get pmRenewPremium => 'Gia hạn Premium';

  @override
  String get pmExpiredStrip =>
      'Premium đã hết hạn. Mọi ghi nhận, phản hồi và bản tóm tắt đã lưu vẫn ở đây.';

  @override
  String get pmQuotaTitle => 'Lượt xuất video kỳ này';

  @override
  String pmQuotaDetail(int used, int reserved, String date) {
    return '$used đã dùng · $reserved đang giữ chỗ · làm mới $date';
  }

  @override
  String pmQuotaDetailNoDate(int used, int reserved) {
    return '$used đã dùng · $reserved đang giữ chỗ';
  }

  @override
  String get pmQuotaCards => 'Thẻ ảnh không tính lượt.';

  @override
  String get pmQuotaOutTitle => 'Đã hết lượt xuất video kỳ này';

  @override
  String pmQuotaOutBody(String date) {
    return 'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau, làm mới $date.';
  }

  @override
  String get pmQuotaOutBodyNoDate =>
      'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau.';

  @override
  String get pmQuotaMakeCard => 'Tạo thẻ ảnh';

  @override
  String pmQuotaPremiumNote(int limit) {
    return 'Premium có $limit lượt xuất video mỗi kỳ.';
  }

  @override
  String get pmQuotaReserved => 'Giữ 1 lượt · bạn có thể rời màn hình';

  @override
  String get pmQuotaReleased =>
      'Đã hoàn lượt giữ chỗ · Thử lại không trừ thêm lượt';

  @override
  String get rhWeekTitle => 'Tóm tắt tuần';

  @override
  String rhWeekOf(int n, String baby) {
    return 'Tuần thứ $n của $baby';
  }

  @override
  String get rhWeekInProgress => 'Tuần đang diễn ra · số liệu đến lúc này';

  @override
  String get rhWeekShare => 'Gửi cho…';

  @override
  String get rhWeekRecordedTitle => 'Đã ghi trong tuần';

  @override
  String get rhWeekRecordedSub => 'Từ nhật ký của cả nhà';

  @override
  String get rhWeekFeeds => 'Bú';

  @override
  String rhWeekFeedCount(int count) {
    return '$count cữ';
  }

  @override
  String rhWeekBottle(String ml) {
    return 'Bú bình $ml ml';
  }

  @override
  String rhWeekBreast(String time) {
    return 'Bú mẹ $time';
  }

  @override
  String get rhWeekNone => 'Chưa ghi';

  @override
  String get rhWeekSleep => 'Ngủ';

  @override
  String get rhWeekSleepAvg => 'trung bình ngày ghi đủ';

  @override
  String rhWeekCoverage(int valid, int days) {
    return '$valid/$days ngày ghi đủ';
  }

  @override
  String get rhWeekSleepSparse => 'Chưa đủ dữ liệu';

  @override
  String rhWeekSleepNeed(int need) {
    return 'cần ít nhất $need ngày';
  }

  @override
  String get rhWeekDiapers => 'Thay tã';

  @override
  String rhWeekDiaperCount(int count) {
    return '$count lần';
  }

  @override
  String rhWeekDiaperKinds(int wet, int dirty) {
    return 'Ướt $wet · Bẩn $dirty';
  }

  @override
  String get rhWeekGrowth => 'Tăng trưởng';

  @override
  String rhWeekGrowthSince(String delta, String date) {
    return '$delta so với $date';
  }

  @override
  String rhWeekGrowthOn(String date) {
    return 'đo ngày $date';
  }

  @override
  String get rhWeekMemories => 'Kỷ niệm';

  @override
  String rhWeekPhotos(int count) {
    return '$count ảnh';
  }

  @override
  String rhWeekVideos(int count) {
    return '$count video';
  }

  @override
  String rhWeekNotes(int count) {
    return '$count ghi chú';
  }

  @override
  String get rhWeekCoverageNote =>
      'Ngủ trung bình chỉ tính những ngày được ghi đủ, tự đếm theo nhật ký. Ngày thiếu ghi không bị tính là 0.';

  @override
  String get rhWeekFamilyTitle => 'Cả nhà đã cùng chăm';

  @override
  String rhWeekFamilyCount(String who, int count) {
    return '$who $count lần';
  }

  @override
  String get rhWeekFamilyEmpty => 'Tuần này chưa có ghi chép nào.';

  @override
  String get rhWeekFamilyNote => 'Số lần ghi trong nhật ký, không xếp hạng.';

  @override
  String get rhWeekNextTitle => 'Tuần tới';

  @override
  String get rhWeekNextEmpty =>
      'Chưa có nhắc việc hay mũi tiêm nào đặt cho tuần tới.';

  @override
  String rhWeekReference(String range) {
    return '$range · tham khảo';
  }

  @override
  String get rhWeekNoScore => 'Không chấm điểm, không so sánh với bé khác.';

  @override
  String get rhWeekInsightTitle => 'Nhìn lại tuần qua';

  @override
  String get rhWeekInsightSub =>
      'Từ ghi nhận và nhật ký của nhà mình · không phải chẩn đoán';

  @override
  String get rhWeekNotesTitle => 'Ghi nhận trong tuần';

  @override
  String rhWeekChangedDays(int count) {
    return '$count ngày có ghi nhận thay đổi';
  }

  @override
  String rhWeekObsDays(String what, int count) {
    return '$what · $count ngày';
  }

  @override
  String rhWeekUsualDays(int count) {
    return '$count ngày như mọi ngày';
  }

  @override
  String rhWeekMixedDays(int count) {
    return '$count ngày mỗi người thấy khác nhau · giữ cả hai ghi nhận';
  }

  @override
  String get rhWeekNoNotes => 'Tuần này chưa có ghi nhận nào.';

  @override
  String get rhWeekTriedTitle => 'Đã thử trong tuần';

  @override
  String get rhWeekNoTried =>
      'Tuần này nhà mình chưa đánh dấu cách nào đã thử.';

  @override
  String get rhWeekNextIdea => 'Một ý tưởng cho tuần tới';

  @override
  String get rhWeekGatePremium =>
      'Phần nhìn lại (giấc ngủ so với mức thường của con, ghi nhận và cách đã thử) thuộc Hỗ trợ phù hợp.';

  @override
  String get rhWeekGateOther =>
      'Phần nhìn lại chưa mở cho bạn. Số liệu đã ghi ở trên vẫn dùng được.';

  @override
  String get rhWeekNoAccess =>
      'Tóm tắt tuần chỉ hiện với người được xem chăm sóc hằng ngày.';

  @override
  String get rhWeekShareFrom => 'Đã ghi trong tuần (nhật ký Child Life):';

  @override
  String rhWeekShareLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String rhWeekShareSleep(String time) {
    return 'trung bình $time mỗi ngày ghi đủ';
  }

  @override
  String get rhWeekOpen => 'Xem lại tuần';

  @override
  String get rhWeekRemindSub => 'Chủ nhật 20:30 · trước giờ yên lặng';

  @override
  String get rhWeekNotifBody => 'Xem lại những gì cả nhà đã ghi trong tuần.';

  @override
  String get asEntryTitle => 'Trợ lý Child Life';

  @override
  String asEntryLeft(int remaining, int limit) {
    return 'Còn $remaining/$limit lượt';
  }

  @override
  String asEntryOut(String date) {
    return 'Hết lượt · làm mới $date';
  }

  @override
  String get asComposerHint => 'Hỏi, ghi nhanh hoặc gửi ảnh…';

  @override
  String get asComposerHintText => 'Hỏi hoặc ghi nhanh…';

  @override
  String get asComposerViewer => 'Hỏi về nhật ký của bé…';

  @override
  String get asComposerOutFree => 'Đã hết lượt AI tháng này';

  @override
  String get asComposerOutPremium => 'Hết lượt AI · vẫn ghi trực tiếp được';

  @override
  String get asComposerAnswer => 'Trả lời câu hỏi…';

  @override
  String get asSend => 'Gửi';

  @override
  String get asAddPhoto => 'Ảnh';

  @override
  String get asChipLogFeed => 'Ghi cữ bú';

  @override
  String get asPrefillFeed => 'Con bú bình lúc ';

  @override
  String get asChipFeedsToday => 'Hôm nay con bú thế nào?';

  @override
  String get asChipReceipt => 'Chụp hoá đơn';

  @override
  String get asFabLabel => 'Mở Lumi';

  @override
  String get asModuleExpenseTitle => 'Chụp hoá đơn hoặc nhắn để ghi';

  @override
  String get asModuleExpenseTextOnly => 'Nhắn để ghi khoản chi';

  @override
  String get asModuleSub =>
      'Trợ lý đọc và tạo bản nháp · bạn kiểm tra trước khi lưu';

  @override
  String get asScopeHousehold => 'Gia đình';

  @override
  String get asScopeTitle => 'Trò chuyện với';

  @override
  String get asHistory => 'Lịch sử';

  @override
  String get asNewChat => 'Hội thoại mới';

  @override
  String asUsageA11y(int remaining, int limit, String date) {
    return 'Lượt hỗ trợ AI của hộ: còn $remaining trên $limit, làm mới $date';
  }

  @override
  String get asBadgeFree => 'Cơ bản';

  @override
  String get asBadgePremium => 'Premium';

  @override
  String asEmptyTitle(String name) {
    return 'Hỏi, ghi nhanh hoặc gửi ảnh cho $name';
  }

  @override
  String asEmptyTitleText(String name) {
    return 'Hỏi hoặc ghi nhanh cho $name';
  }

  @override
  String get asEmptyTitleHousehold => 'Hỏi hoặc ghi nhanh cho cả nhà';

  @override
  String get asEmptyBody =>
      'Trợ lý hiểu và tạo bản nháp. Bạn kiểm tra trước khi lưu vào đúng chỗ.';

  @override
  String get asExampleFeed => '“8 giờ con bú bình 120 ml”';

  @override
  String get asExampleFeedText => '8 giờ con bú bình 120 ml';

  @override
  String get asExampleFeedsToday => '“Hôm nay con bú thế nào?”';

  @override
  String get asExampleExpense => '“Mua bỉm 310.000 đồng hôm qua”';

  @override
  String get asExampleExpenseText => 'Mua bỉm 310.000 đồng hôm qua';

  @override
  String get asExampleReceipt => 'Chụp hoá đơn → ghi chi tiêu';

  @override
  String get asExampleNote => 'Chụp bảng note → nhắc việc';

  @override
  String get asPrivacyNote =>
      'Tin nhắn và ảnh bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu. Ảnh gốc giữ hay xoá theo lựa chọn của bạn.';

  @override
  String get asPrivacyNoteText =>
      'Tin nhắn bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu.';

  @override
  String get asThinking => 'Lumi đang soạn…';

  @override
  String get asCancelTask => 'Huỷ';

  @override
  String get asCanceled => 'Đã huỷ. Không trừ lượt.';

  @override
  String get asUnsent => 'Chưa gửi';

  @override
  String get asSending => 'Đang gửi…';

  @override
  String asDraftsFound(int count) {
    return 'Mình thấy $count việc. Kiểm tra rồi chọn mục muốn lưu nhé.';
  }

  @override
  String get asUnsupportedPart =>
      'Nội dung này cần bản app mới hơn để hiển thị. Không có gì được lưu.';

  @override
  String get asLoadingChat => 'Đang mở cuộc trò chuyện…';

  @override
  String get asStateDraft => 'Nháp';

  @override
  String get asStateReview => 'Cần kiểm tra';

  @override
  String get asStateSaving => 'Đang lưu';

  @override
  String get asStateSaved => 'Đã lưu';

  @override
  String get asStateFailed => 'Chưa lưu';

  @override
  String get asStateDiscarded => 'Đã bỏ';

  @override
  String get asStateExpired => 'Hết hạn';

  @override
  String get asKindBottle => 'Cữ bú bình';

  @override
  String get asKindBreast => 'Cữ bú mẹ';

  @override
  String get asKindSleep => 'Giấc ngủ';

  @override
  String get asKindExpense => 'Khoản chi';

  @override
  String get asKindReminder => 'Nhắc việc';

  @override
  String get asKindObservation => 'Ghi nhận';

  @override
  String get asKindMeal => 'Bữa ăn';

  @override
  String get asKindUnknown => 'Mục chưa hỗ trợ';

  @override
  String asModuleCare(String name) {
    return '$name · Nhật ký chăm sóc';
  }

  @override
  String get asModuleSpending => 'Gia đình · Chi tiêu';

  @override
  String get asModuleReminders => 'Gia đình · Nhắc việc';

  @override
  String asModuleRhythm(String name) {
    return '$name · Nhịp lớn lên';
  }

  @override
  String asModuleMeal(String name) {
    return '$name · Ăn dặm';
  }

  @override
  String asDayToday(String date) {
    return 'Hôm nay $date';
  }

  @override
  String asDayYesterday(String date) {
    return 'Hôm qua $date';
  }

  @override
  String asAmountMl(String ml) {
    return '$ml ml';
  }

  @override
  String get asNoAmount => 'chưa có lượng';

  @override
  String get asNoTime => 'chưa có giờ';

  @override
  String get asNoDate => 'chưa có ngày';

  @override
  String get asEdit => 'Sửa';

  @override
  String get asRemove => 'Bỏ mục này';

  @override
  String get asOpenLog => 'Mở nhật ký';

  @override
  String get asUndo => 'Hoàn tác';

  @override
  String get asOpenSpending => 'Mở Chi tiêu';

  @override
  String get asOpenReminders => 'Mở nhắc việc';

  @override
  String get asOpenRhythm => 'Xem nhịp của con';

  @override
  String get asSeeLogged => 'Xem bản đã ghi';

  @override
  String get asSaveAnyway => 'Vẫn lưu riêng';

  @override
  String get asViewerDraftNote => 'Chỉ xem · không lưu qua chat';

  @override
  String get asProblemMissingAmount => 'Thêm lượng (ml) trước khi lưu.';

  @override
  String get asProblemInvalidAmount => 'Lượng chưa hợp lệ.';

  @override
  String get asProblemMissingTime => 'Thêm giờ trước khi lưu.';

  @override
  String get asProblemFutureTime =>
      'Giờ này ở tương lai — chỉ ghi việc đã xảy ra.';

  @override
  String get asProblemInvalidTime => 'Giờ kết thúc phải sau giờ bắt đầu.';

  @override
  String get asProblemMissingDate => 'Chọn ngày trước khi lưu.';

  @override
  String get asProblemCurrency => 'Chi tiêu chưa hỗ trợ đơn vị tiền này.';

  @override
  String get asProblemMissingTitle => 'Thêm tên việc trước khi lưu.';

  @override
  String get asNeedsReview => 'Kiểm tra lại mục này rồi lưu.';

  @override
  String get asErrConflict => 'Trùng với một bản đã ghi. Chưa lưu.';

  @override
  String get asErrDuplicate => 'Có vẻ mục này đã được ghi. Chưa lưu.';

  @override
  String get asErrWriteDenied => 'Vai trò của bạn chưa được lưu mục này.';

  @override
  String get asErrExpired => 'Bản nháp đã hết hạn. Nhắn lại để tạo bản mới.';

  @override
  String get asErrStale => 'Bản nháp vừa thay đổi. Xem lại rồi lưu.';

  @override
  String get asErrSaveFailed => 'Chưa lưu được. Thử lại không trừ lượt.';

  @override
  String get asErrScope => 'Bé đang chọn đã đổi. Mở lại đúng bé để lưu.';

  @override
  String get asErrModule => 'Mục này chưa có nơi lưu trong app.';

  @override
  String asSaveSelected(int count) {
    return 'Lưu $count mục đã chọn';
  }

  @override
  String get asChooseToSave => 'Chọn mục muốn lưu';

  @override
  String get asDiscardAll => 'Bỏ tất cả';

  @override
  String asPartial(int saved, int total, int failed) {
    return '$saved/$total mục đã lưu · $failed mục chưa lưu';
  }

  @override
  String get asRetryFailed => 'Thử lại mục lỗi';

  @override
  String get asRetryFree => 'Thử lại không trừ lượt.';

  @override
  String get asSaveOffline =>
      'Đang ngoại tuyến · chưa lưu gì. Có mạng rồi lưu lại.';

  @override
  String get asSaveError => 'Chưa lưu được. Bản nháp vẫn giữ nguyên.';

  @override
  String get asSaveAnywayTitle => 'Vẫn lưu riêng?';

  @override
  String get asSaveAnywayBody =>
      'Mục này trùng với một bản đã ghi. Lưu riêng sẽ có hai bản; bạn sửa hoặc xoá trong nhật ký được.';

  @override
  String get asSaveSeparately => 'Lưu riêng';

  @override
  String get asCancel => 'Huỷ';

  @override
  String get asClarifyFree =>
      'Câu hỏi làm rõ thuộc cùng tác vụ, không trừ thêm lượt.';

  @override
  String get asClarifyOwn => 'Khác…';

  @override
  String get asClarifyExpired => 'Câu hỏi đã hết hạn. Nhắn lại để hỏi tiếp.';

  @override
  String get asEditBottle => 'Sửa cữ bú bình';

  @override
  String get asEditBreast => 'Sửa cữ bú mẹ';

  @override
  String get asEditSleep => 'Sửa giấc ngủ';

  @override
  String get asFieldBaby => 'Bé';

  @override
  String get asFieldWhen => 'Thời gian';

  @override
  String get asFieldAmount => 'Lượng (ml)';

  @override
  String get asFieldStart => 'Bắt đầu';

  @override
  String get asFieldEnd => 'Kết thúc';

  @override
  String get asFieldMinutes => 'Số phút';

  @override
  String get asFieldSide => 'Bên';

  @override
  String get asBabyLocked =>
      'Bé giữ theo cuộc trò chuyện; không chuyển bản nháp sang bé khác.';

  @override
  String get asUpdateDraft => 'Cập nhật bản nháp';

  @override
  String get asEditFailed => 'Chưa cập nhật được bản nháp. Thử lại.';

  @override
  String asSummaryMeta(String day, String time) {
    return '$day · đến $time';
  }

  @override
  String asSummaryBottle(int count, String ml) {
    return 'Bú bình · $count cữ · $ml ml';
  }

  @override
  String asSummaryBreast(int count, int minutes) {
    return 'Bú mẹ · $count lần · $minutes phút';
  }

  @override
  String get asSummaryBreastNote => 'Tính theo phút, không quy đổi ra ml';

  @override
  String asSummarySleep(int count, String duration) {
    return 'Giấc ngủ · $count giấc · $duration';
  }

  @override
  String get asSummaryNone => 'Chưa có ghi nhận nào trong khoảng này.';

  @override
  String get asSummaryPartial =>
      'Tính trên các cữ đã ghi — có thể chưa đầy đủ.';

  @override
  String get asSummaryComplete => 'Tính trên các cữ đã ghi trong ngày.';

  @override
  String get asOpenSourceLog => 'Mở nhật ký nguồn';

  @override
  String get asNoRecordCreated => 'Câu hỏi không tạo cữ bú mới';

  @override
  String get asUsageTitle => 'Lượt hỗ trợ AI';

  @override
  String asUsageOf(int limit) {
    return '/ $limit lượt còn lại';
  }

  @override
  String asUsageResetFree(String date) {
    return 'Làm mới $date theo múi giờ của hộ · dùng chung cho cả hộ';
  }

  @override
  String asUsageResetPremium(String date) {
    return 'Làm mới $date theo kỳ Premium · dùng chung cho cả hộ';
  }

  @override
  String get asCostTitle => 'Mỗi việc dùng khoảng';

  @override
  String get asCostText => 'Câu hỏi, ghi nhanh bằng chữ';

  @override
  String get asCostPhoto => 'Đọc 1 ảnh (hoá đơn, note)';

  @override
  String get asCostFollowUp => 'Hỏi lại, sửa, xác nhận cùng tác vụ';

  @override
  String get asCostError => 'Lỗi hệ thống, ảnh không đọc được';

  @override
  String get asCostHealth => 'Hướng dẫn sức khoẻ thiết yếu';

  @override
  String asCostCredits(int count) {
    return '$count lượt';
  }

  @override
  String get asCostNoExtra => 'Không thêm';

  @override
  String get asCostNotCharged => 'Không trừ';

  @override
  String get asCostFree => 'Không trừ lượt';

  @override
  String get asRecentTitle => 'Gần đây';

  @override
  String get asRecentText => 'Câu hỏi hoặc ghi nhanh';

  @override
  String get asRecentPhoto => 'Đọc ảnh';

  @override
  String get asVideoQuotaTitle => 'Xuất video kỷ niệm';

  @override
  String asVideoQuotaSub(int left, int limit) {
    return 'Quota riêng, không dùng lượt hỗ trợ AI · còn $left/$limit';
  }

  @override
  String get asPremiumTeaser =>
      'Premium có nhiều lượt hơn, cùng cá nhân hoá chủ động và mẫu thẻ/video Premium.';

  @override
  String get asSeePremium => 'Xem Premium';

  @override
  String get asPremiumHousehold =>
      'Hộ đang dùng Premium. Không có gói chat riêng.';

  @override
  String get asUsageFailed => 'Chưa tải được mức dùng.';

  @override
  String get asRetry => 'Thử lại';

  @override
  String get asPhotoNotSent => 'Ảnh · chưa gửi';

  @override
  String asPhotoQuoteTitle(int credits, int remaining) {
    return 'Đọc ảnh này cần $credits lượt, bạn còn $remaining.';
  }

  @override
  String asPhotoQuoteFree(String date) {
    return 'Bạn có thể nhập tay, đợi làm mới $date, hoặc nâng cấp để tiếp tục ngay. Ảnh chưa được gửi đi.';
  }

  @override
  String asPhotoQuotePremium(String date) {
    return 'Bạn có thể nhập tay hoặc đợi làm mới $date. Ảnh chưa được gửi đi.';
  }

  @override
  String get asTypeInstead => 'Nhập tay';

  @override
  String get asRemovePhoto => 'Bỏ ảnh';

  @override
  String get asOutTitleFree => 'Bạn đã dùng hết lượt hỗ trợ AI tháng này.';

  @override
  String get asOutBodyFree =>
      'Câu hỏi của bạn được giữ lại. Bạn vẫn ghi trực tiếp và xem nhật ký như thường.';

  @override
  String get asOpenTodayLog => 'Mở nhật ký hôm nay';

  @override
  String get asUpgradeContinue => 'Nâng cấp & tiếp tục câu hỏi';

  @override
  String get asHealthStillOpen =>
      'Hướng dẫn sức khoẻ thiết yếu vẫn mở, không cần lượt.';

  @override
  String get asOpenHealth => 'Mở Hướng dẫn sức khoẻ';

  @override
  String get asOutTitlePremium => 'Hộ đã dùng hết lượt hỗ trợ AI kỳ này.';

  @override
  String asOutBodyPremium(String date) {
    return 'Làm mới $date. Bạn vẫn ghi trực tiếp, xem nhật ký, dùng mẫu Premium và quota xuất video riêng.';
  }

  @override
  String get asSeeUsage => 'Xem chi tiết mức dùng';

  @override
  String get asReadyStillSave =>
      'Bản nháp đã sẵn sàng vẫn lưu được, không cần lượt.';

  @override
  String get asResumedBanner => 'Hộ đã có Premium · tiếp tục câu hỏi đang chờ';

  @override
  String get asResumedNote =>
      'Câu hỏi được tính 1 lần sau khi có câu trả lời, không tính lúc hết lượt.';

  @override
  String get asContinueQuestion => 'Tiếp tục câu hỏi';

  @override
  String get asFailTitle => 'Trợ lý chưa phản hồi được';

  @override
  String get asFailBody =>
      'Chưa có gì được lưu. Lượt này không bị trừ; thử lại cũng không trừ hai lần.';

  @override
  String get asLogDirectly => 'Ghi trực tiếp';

  @override
  String get asOfflineTitle => 'Đang ngoại tuyến';

  @override
  String get asOfflineBody =>
      'Tin nhắn được giữ lại, chưa gửi. Khi có mạng, bấm Gửi để gửi. Ghi trực tiếp trong các module vẫn lưu trên máy.';

  @override
  String get asGenericError => 'Có lỗi xảy ra. Chưa có gì được lưu.';

  @override
  String get asConsentTitle => 'Trước khi dùng trợ lý';

  @override
  String get asConsent1 =>
      'Tin nhắn và ảnh bạn gửi được AI xử lý để hiểu và tạo bản nháp.';

  @override
  String get asConsent2 =>
      'Chỉ gửi ảnh bạn chọn. Ảnh gốc giữ hay xoá theo lựa chọn của bạn; app chỉ báo đã xoá khi việc xoá được xác nhận.';

  @override
  String get asConsent3 =>
      'Chỉ dùng tên gọi của bé; không gửi tên đầy đủ hay ngày sinh chính xác.';

  @override
  String get asConsent4 =>
      'Không tự lưu. Bạn kiểm tra trước khi ghi vào nhật ký.';

  @override
  String get asConsentProvider =>
      'Một dịch vụ AI bên ngoài xử lý qua máy chủ Child Life, điện thoại không gửi trực tiếp; nhà cung cấp không được lưu giữ dữ liệu này.';

  @override
  String get asConsentPrivate =>
      'Với Ba, Mẹ và người chăm sóc, câu hỏi về bé nằm trong cuộc trò chuyện chung của bé. Ảnh, chi tiêu và mọi câu hỏi khác chỉ bạn thấy. Bạn đổi ý lúc nào cũng được.';

  @override
  String get asConsentAgree => 'Đồng ý và bắt đầu';

  @override
  String get asConsentDecline => 'Không dùng trợ lý';

  @override
  String get asConsentDeclined =>
      'Đã không dùng trợ lý. Ghi trực tiếp vẫn dùng như bình thường.';

  @override
  String get asConsentFailed =>
      'Chưa lưu được lựa chọn. Kiểm tra kết nối và thử lại.';

  @override
  String get asViewerTitle => 'Bạn đang có quyền xem';

  @override
  String get asViewerBody =>
      'Người chỉ có quyền xem không ghi được qua chat. Bạn vẫn hỏi và xem tổng hợp được.';

  @override
  String get asWriteDeniedTitle => 'Chưa lưu được qua chat';

  @override
  String get asWriteDeniedBody =>
      'Vai trò của bạn chưa được ghi mục này. Bạn vẫn hỏi và xem tổng hợp được.';

  @override
  String get asReadDeniedBody => 'Vai trò của bạn chưa được xem dữ liệu này.';

  @override
  String get asModuleTitle => 'Chưa có nơi lưu việc này';

  @override
  String get asModuleBody =>
      'App chưa có module cho loại việc này nên không tạo bản ghi. Bạn có thể nhắn lại thành nhắc việc có ngày giờ để có bản nháp kiểm tra.';

  @override
  String get asRegionTitle => 'Khu vực chưa hỗ trợ';

  @override
  String get asRegionBody =>
      'Gợi ý chăm sóc qua chat chưa mở ở khu vực của hộ. Ghi nhanh và hỏi dữ liệu vẫn dùng được.';

  @override
  String get asOffTitle => 'Trợ lý đang tạm nghỉ';

  @override
  String get asOffBody => 'Lịch sử và ghi trực tiếp vẫn dùng được.';

  @override
  String get asNotMemberBody => 'Bạn không còn trong gia đình của bé này.';

  @override
  String get asHealthTitle => 'Hãy liên hệ hỗ trợ y tế ngay';

  @override
  String get asHealthBody =>
      'Trợ lý không phải dịch vụ cấp cứu và không đánh giá được tình trạng của bé.';

  @override
  String asHealthCall(String number) {
    return 'Gọi $number';
  }

  @override
  String get asHealthCallDoctor => 'Gọi bác sĩ của bé';

  @override
  String get asHealthFree => 'Không trừ lượt';

  @override
  String get asDialFailed => 'Chưa mở được ứng dụng gọi điện.';

  @override
  String get asHistoryTitle => 'Hội thoại';

  @override
  String get asHistoryToday => 'HÔM NAY';

  @override
  String get asHistoryWeek => 'TUẦN NÀY';

  @override
  String get asHistoryEarlier => 'TRƯỚC ĐÓ';

  @override
  String get asHistoryUntitled => 'Cuộc trò chuyện';

  @override
  String get asHistoryFootnote =>
      'Mỗi bé có lịch sử riêng. Đổi bé không chuyển bản nháp đang chờ sang bé khác.';

  @override
  String get asHistoryPrivate =>
      'Chỉ bạn xem được các cuộc trò chuyện của mình. Bản ghi đã lưu vẫn chia sẻ theo vai trò.';

  @override
  String get asHistoryEmpty => 'Chưa có cuộc trò chuyện nào.';

  @override
  String get asHistoryFailed => 'Chưa tải được lịch sử.';

  @override
  String get asDeleteChat => 'Xoá cuộc trò chuyện';

  @override
  String get asDeleteTitle => 'Xoá cuộc trò chuyện?';

  @override
  String get asDeleteBody =>
      'Tin nhắn và bản nháp chưa lưu trong cuộc trò chuyện này sẽ bị xoá. Những gì đã lưu vào nhật ký, Chi tiêu hay nhắc việc vẫn giữ nguyên.';

  @override
  String get asDeleteConfirm => 'Xoá';

  @override
  String get asDeleted => 'Đã xoá cuộc trò chuyện';

  @override
  String get asDeleteFailed => 'Chưa xoá được. Thử lại sau.';

  @override
  String get asPhotoSheetTitle => 'Gửi ảnh để trợ lý đọc';

  @override
  String get asPhotoCameraSub => 'Hoá đơn, bảng note';

  @override
  String get asPhotoLibrarySub => 'Chỉ ảnh bạn chọn được gửi';

  @override
  String asPhotoQuoteExact(int credits) {
    return 'Đọc 1 ảnh dùng $credits lượt hỗ trợ AI';
  }

  @override
  String asPhotoSheetBody(int remaining) {
    return 'Còn $remaining lượt. Bạn thấy đúng số lượt trước khi gửi; ảnh không đọc được thì không trừ.';
  }

  @override
  String get asPhotoSheetBodyUnknown =>
      'Bạn thấy đúng số lượt trước khi gửi; ảnh không đọc được thì không trừ.';

  @override
  String get asPhotoChosenTitle => 'Ảnh đã chọn · chưa gửi';

  @override
  String get asPhotoOnlyThis => 'Chỉ ảnh này được gửi để đọc.';

  @override
  String asPhotoQuoteBody(int remaining) {
    return 'Còn $remaining lượt. Hỏi lại, sửa và xác nhận trong cùng tác vụ không trừ thêm. Ảnh không đọc được thì không trừ.';
  }

  @override
  String get asKeepReceipt => 'Giữ ảnh hoá đơn cùng khoản chi';

  @override
  String get asKeepReceiptOn =>
      'Khi bạn lưu khoản chi, ảnh được giữ cùng khoản chi. Không lưu thì ảnh được xoá.';

  @override
  String get asKeepReceiptOff =>
      'Ảnh được xoá sau khi đọc. App chỉ báo đã xoá khi việc xoá được xác nhận.';

  @override
  String get asPhotoTextIsData =>
      'Chữ trong ảnh là nội dung để đọc, không phải lệnh cho app.';

  @override
  String get asSendPhoto => 'Gửi ảnh';

  @override
  String get asPhotoQuoting => 'Đang tính lượt…';

  @override
  String get asPhotoPickFailed =>
      'Chưa mở được ảnh. Thử lại hoặc chọn ảnh khác.';

  @override
  String asUploading(int percent) {
    return 'Đang tải lên · $percent%';
  }

  @override
  String get asCancelUpload => 'Huỷ';

  @override
  String get asUploadFree => 'Huỷ khi đang tải lên không trừ lượt.';

  @override
  String get asUploadCanceled =>
      'Đã huỷ tải lên · không trừ lượt. Ảnh vẫn được chọn.';

  @override
  String get asPhotoReading => 'Đang đọc ảnh…';

  @override
  String get asPhotoRead => 'Đã đọc';

  @override
  String get asPhotoBlurry => 'Ảnh hơi mờ';

  @override
  String get asPhotoRefused => 'Không đọc được tệp này';

  @override
  String get asPhotoCanceled => 'Đã huỷ';

  @override
  String get asPhotoLeaveScreen =>
      'Bạn có thể rời màn hình; kết quả vẫn ở đây khi bạn quay lại. Lỗi hệ thống không trừ lượt.';

  @override
  String get asPhotoFailBody =>
      'Ảnh chưa được đọc, chưa có gì được lưu và không trừ lượt. Ảnh vẫn được chọn.';

  @override
  String get asReceiptTitle => 'Chi tiêu từ hoá đơn';

  @override
  String get asFieldStore => 'Cửa hàng';

  @override
  String get asFieldDate => 'Ngày';

  @override
  String get asFieldTotal => 'Tổng tiền';

  @override
  String get asFieldCategory => 'Danh mục gợi ý';

  @override
  String get asFieldScope => 'Phạm vi';

  @override
  String get asFieldCurrency => 'Đơn vị tiền';

  @override
  String get asFieldTitle => 'Việc';

  @override
  String get asFieldTime => 'Giờ';

  @override
  String asFieldCheckA11y(String label, String value) {
    return '$label: $value, cần kiểm tra';
  }

  @override
  String get asNotRead => 'chưa đọc được';

  @override
  String asExpenseFor(String name) {
    return 'Gia đình · cho $name';
  }

  @override
  String asTaxIncluded(String total) {
    return 'Chỉ ghi tổng tiền $total (đã gồm thuế), không cộng thêm tạm tính hay thuế.';
  }

  @override
  String get asConfirmDate =>
      'Ngày chưa chắc: chạm vào ngày để chọn hoặc xác nhận trước khi lưu.';

  @override
  String get asDuplicateBody =>
      'Có thể trùng với một khoản đã ghi trong gia đình. Mình không tự gộp.';

  @override
  String get asDuplicateAcknowledged => 'Bạn chọn vẫn lưu riêng · không gộp.';

  @override
  String get asOpenDuplicate => 'Mở khoản chi trùng';

  @override
  String get asSaveAnywayShort => 'Vẫn lưu';

  @override
  String get asSaveExpense => 'Lưu chi tiêu';

  @override
  String get asSkip => 'Bỏ qua';

  @override
  String get asEditExpense => 'Sửa khoản chi';

  @override
  String get asTotalOnly =>
      'Chỉ tổng tiền in trên hoá đơn; không cộng tạm tính và thuế.';

  @override
  String get asPickDate => 'Chọn ngày';

  @override
  String get asPickTime => 'Chọn giờ';

  @override
  String get asRetentionKept =>
      'Ảnh hoá đơn được giữ cùng khoản chi trong Chi tiêu.';

  @override
  String get asRetentionKeptIfSaved =>
      'Ảnh được giữ cùng khoản chi khi bạn lưu; nếu không lưu, ảnh sẽ được xoá.';

  @override
  String get asRetentionDeleting =>
      'Đang xoá ảnh gốc. App chỉ báo đã xoá khi việc xoá được xác nhận.';

  @override
  String get asRetentionDeleted => 'Ảnh gốc đã được xoá.';

  @override
  String get asRetentionWillDelete =>
      'Ảnh gốc sẽ được xoá sau khi đọc; app báo khi xoá xong.';

  @override
  String asRemindLine(String when) {
    return 'Nhắc: $when';
  }

  @override
  String asModuleRemindersOf(String name) {
    return '$name · Nhắc việc';
  }

  @override
  String get asCheckReminder => 'Chọn ngày giờ';

  @override
  String get asEditReminder => 'Sửa nhắc việc';

  @override
  String get asAllDay => 'Không đặt giờ';

  @override
  String asReminderBaby(String name) {
    return 'Nhắc việc lưu cho $name; không chuyển sang bé khác.';
  }

  @override
  String get asProblemInvalidTitle => 'Tên việc dài quá (tối đa 80 ký tự).';

  @override
  String get asProblemPastTime => 'Giờ nhắc đã qua — chọn một giờ sắp tới.';

  @override
  String get asRetake => 'Chụp lại';

  @override
  String get asOtherPhoto => 'Chọn ảnh khác';

  @override
  String get asUnreadableFree => 'Lần đọc này không trừ lượt.';

  @override
  String get asSleepSafety =>
      'Nếu con sốt, khó thở, li bì hoặc bỏ bú — mở Hướng dẫn sức khoẻ.';

  @override
  String get asSleepFalling => 'khó vào giấc';

  @override
  String get asSleepWaking => 'hay thức giấc';

  @override
  String get asSleepBoth => 'khó vào giấc và hay thức giấc';

  @override
  String get asWhenNight => 'giấc đêm';

  @override
  String get asWhenDay => 'giấc ngày';

  @override
  String get asWhenBoth => 'cả ngày và đêm';

  @override
  String get asFromCareLibrary => 'Từ Thư viện chăm bé';

  @override
  String asFromCareLibraryMinutes(int minutes) {
    return 'Từ Thư viện chăm bé · $minutes phút';
  }

  @override
  String get asContentUnreviewed =>
      'Nội dung minh hoạ · chờ chuyên môn duyệt. Không khẳng định nguyên nhân.';

  @override
  String get asContentReviewed =>
      'Nội dung đã được chuyên môn duyệt. Không khẳng định nguyên nhân.';

  @override
  String get asTryTonight => 'Thử tối nay';

  @override
  String get asTryToday => 'Thử hôm nay';

  @override
  String get asAnotherIdea => 'Gợi ý khác';

  @override
  String get asPlannedTonight => 'Bạn định thử tối nay';

  @override
  String get asPlannedToday => 'Bạn định thử hôm nay';

  @override
  String asPlanFollowUp(String day) {
    return 'Mình sẽ hỏi lại từ $day, sau khi bạn có dịp thử.';
  }

  @override
  String get asObservationTitle => 'Ghi nhận (tuỳ chọn)';

  @override
  String get asObservationSleep => 'giấc ngủ';

  @override
  String get asSaveObservation => 'Lưu ghi nhận';

  @override
  String get asNoThanks => 'Không cần';

  @override
  String get asOpenCareLibrary => 'Mở Thư viện chăm bé';

  @override
  String get asOutcomeHelpful => 'Có ích';

  @override
  String get asOutcomeUnsure => 'Chưa rõ';

  @override
  String get asOutcomeNotSuitable => 'Không phù hợp';

  @override
  String get asOutcomeNotTried => 'Chưa thử';

  @override
  String get asFeedbackHelpful =>
      'Đã ghi phản hồi. Lần sau mình sẽ ưu tiên cách này. “Có ích” không có nghĩa cách này là nguyên nhân thay đổi.';

  @override
  String get asFeedbackUnsure =>
      'Đã ghi phản hồi. Mình sẽ cân nhắc khi gợi ý lần sau.';

  @override
  String get asFeedbackNotSuitable =>
      'Đã ghi phản hồi. Lần sau mình sẽ không gợi ý cách này.';

  @override
  String get asFeedbackNotTried =>
      'Không sao. Khi nào thử, bạn có thể ghi lại trong Nhịp lớn lên.';

  @override
  String get asFeedbackTitle => 'Phản hồi hoạt động';

  @override
  String get asFeedbackFree => 'Phản hồi không trừ lượt hỗ trợ AI.';

  @override
  String get asRecipesFrom => 'Gợi ý từ Thư viện công thức';

  @override
  String asRecipeMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String asRecipesExcluded(int count) {
    return 'Đã loại $count món có nguyên liệu con từng có phản ứng (phản ứng đã ghi, không phải chẩn đoán dị ứng).';
  }

  @override
  String get asRecipesCaveat =>
      'Món chưa có ghi nhận phản ứng không có nghĩa là con đã dung nạp tốt.';

  @override
  String get asLogMeal => 'Ghi bữa ăn';

  @override
  String get asLogMealUnavailable =>
      'Chưa có nhật ký bữa ăn trong app nên chưa ghi được từ đây.';

  @override
  String get asProblemInvalidAssignee =>
      'Người được giao không còn trong gia đình. Chọn lại người phụ trách.';

  @override
  String asSavedBy(String name, int count) {
    return '$name đã lưu $count mục';
  }

  @override
  String asConfirmedBy(String name) {
    return '$name đã lưu';
  }

  @override
  String asWaitingFor(String name) {
    return 'Chờ $name trả lời câu hỏi này.';
  }

  @override
  String get asPrivateTask =>
      'Chỉ bạn thấy: ảnh và chi tiêu không vào cuộc trò chuyện chung của bé.';

  @override
  String get asHistoryShared => 'CUỘC TRÒ CHUYỆN CHUNG';

  @override
  String get asSharedThreadTitle => 'Trò chuyện chung về bé';

  @override
  String asSharedThreadSub(String when) {
    return 'Ba, Mẹ và người chăm sóc cùng xem · $when';
  }

  @override
  String get asHistorySharedNote =>
      'Câu hỏi về bé nằm trong cuộc trò chuyện chung của Ba, Mẹ và người chăm sóc. Ảnh, chi tiêu và các cuộc trò chuyện cũ chỉ bạn xem được.';

  @override
  String get asDeleteSharedTitle => 'Xoá cuộc trò chuyện chung?';

  @override
  String get asDeleteSharedBody =>
      'Cuộc trò chuyện chung sẽ bị xoá cho mọi người, kể cả bản nháp chưa lưu. Những gì đã lưu vào nhật ký, Nhịp lớn lên hay nhắc việc vẫn giữ nguyên.';

  @override
  String get asDeletedRecordsKept =>
      'Đã xoá cuộc trò chuyện. Bản ghi đã lưu vẫn giữ nguyên.';

  @override
  String get asCostSummary => 'Tóm tắt bằng AI (bàn giao, giải thích)';

  @override
  String get asRecentHandover => 'Tóm tắt bàn giao bằng AI';

  @override
  String get asRecentExplain => 'Giải thích gợi ý bằng AI';

  @override
  String get asRecentMoment => 'Tóm tắt khoảnh khắc bằng AI';

  @override
  String get asRecentSummary => 'Tóm tắt bằng AI';

  @override
  String asRecentHeld(int credits) {
    return 'đang giữ $credits lượt';
  }

  @override
  String get asRecentReleased => '0 lượt · đã hoàn lại';

  @override
  String get asRecentFree => '0 lượt · không tính';

  @override
  String get asRecentEmpty => 'Chưa dùng lượt nào trong kỳ này.';

  @override
  String asHistorySaved(int count) {
    return '$count mục đã lưu';
  }

  @override
  String get asHistoryNeedsAnswer => 'Có câu hỏi đang chờ trả lời';

  @override
  String get asHistoryAwaitingFeedback => 'Đang chờ phản hồi sau khi thử';

  @override
  String asHistoryDrafts(int count) {
    return '$count nháp';
  }

  @override
  String asSummaryFeedMl(String time, String ml) {
    return '$time $ml ml';
  }

  @override
  String asSummaryFeedMinutes(String time, int minutes) {
    return '$time $minutes phút';
  }

  @override
  String get lbTitle => 'Thư viện chăm bé';

  @override
  String get lbSaved => 'Đã lưu';

  @override
  String get lbSearchHint => 'Tìm: ngủ ngày, nấc, hăm tã…';

  @override
  String get lbTopicFeeding => 'Bú & sữa';

  @override
  String get lbTopicSleep => 'Giấc ngủ';

  @override
  String get lbTopicTeething => 'Mọc răng';

  @override
  String get lbTopicIllness => 'Sốt & ốm vặt';

  @override
  String get lbTopicDailyCare => 'Chăm hằng ngày';

  @override
  String get lbTopicDevelopment => 'Phát triển';

  @override
  String lbForBaby(String name, String age) {
    return 'Hợp với $name · $age';
  }

  @override
  String get lbSeeMore => 'Xem thêm';

  @override
  String get lbRecent => 'Mới cập nhật';

  @override
  String lbMinutes(int count) {
    return '$count phút đọc';
  }

  @override
  String lbMinutesShort(int count) {
    return '$count phút';
  }

  @override
  String lbRangeWeeks(int from, int to) {
    return '$from–$to tuần';
  }

  @override
  String lbRangeMonths(int from, int to) {
    return '$from–$to tháng';
  }

  @override
  String lbRangeYears(int from, int to) {
    return '$from–$to tuổi';
  }

  @override
  String lbStageWeek(int count) {
    return '$count tuần';
  }

  @override
  String lbStageMonth(int count) {
    return '$count tháng';
  }

  @override
  String lbReviewedBy(String reviewer, String credential, String month) {
    return 'Được $reviewer · $credential rà soát $month';
  }

  @override
  String get lbIllustrative => 'Nội dung minh hoạ · chờ chuyên môn duyệt';

  @override
  String get lbIllustrativeShort => 'Minh hoạ · chờ duyệt';

  @override
  String get lbOfflineLibrary =>
      'Không có kết nối. Thư viện đang hiện bản đã lưu trên máy.';

  @override
  String get lbOfflineStages =>
      'Không có kết nối. Giai đoạn của bé đang hiện bản đã lưu trên máy.';

  @override
  String get lbEmptyTitle => 'Thư viện đang được chuẩn bị';

  @override
  String get lbEmptyBody => 'Bài viết sẽ hiện ở đây ngay khi được xuất bản.';

  @override
  String get lbEmptyOfflineTitle => 'Chưa có bản lưu trên máy';

  @override
  String get lbEmptyOfflineBody =>
      'Kết nối mạng một lần để tải nội dung, sau đó đọc được cả khi không có mạng.';

  @override
  String lbResults(int count) {
    return '$count bài viết';
  }

  @override
  String get lbFilters => 'Bộ lọc';

  @override
  String lbFiltersCount(int count) {
    return 'Bộ lọc · $count';
  }

  @override
  String lbRemoveFilter(String label) {
    return 'Bỏ lọc $label';
  }

  @override
  String get lbClearSearch => 'Xoá tìm kiếm';

  @override
  String get lbSortTitle => 'Sắp xếp';

  @override
  String get lbSortRelevant => 'Liên quan nhất';

  @override
  String get lbSortNewest => 'Mới cập nhật';

  @override
  String get lbSortShortest => 'Đọc nhanh nhất';

  @override
  String get lbNoResults => 'Không tìm thấy bài phù hợp';

  @override
  String get lbNoResultsHint => 'Thử từ khoá khác hoặc bỏ bớt bộ lọc.';

  @override
  String get lbFilterTopic => 'Chủ đề';

  @override
  String get lbFilterAge => 'Độ tuổi';

  @override
  String get lbFilterTime => 'Thời gian đọc';

  @override
  String get lbTimeShort => 'Dưới 3 phút';

  @override
  String get lbTimeMedium => '3–6 phút';

  @override
  String get lbTimeLong => 'Trên 6 phút';

  @override
  String get lbReset => 'Đặt lại';

  @override
  String lbShowN(int count) {
    return 'Xem $count bài';
  }

  @override
  String get lbSave => 'Lưu';

  @override
  String get lbUnsave => 'Bỏ lưu';

  @override
  String get lbSavedToast => 'Đã lưu · xem trong Thư viện › Đã lưu';

  @override
  String get lbView => 'Xem';

  @override
  String get lbUnsavedToast => 'Đã bỏ lưu';

  @override
  String get lbUndo => 'Hoàn tác';

  @override
  String get lbSaveFailed => 'Chưa lưu được. Thử lại nhé.';

  @override
  String get lbTextSize => 'Cỡ chữ';

  @override
  String get lbRelated => 'Bài viết liên quan';

  @override
  String get lbSources => 'Nguồn tham khảo';

  @override
  String get lbOpenFirstAid => 'Dấu hiệu nguy hiểm? Mở Sơ cứu trẻ em';

  @override
  String get lbArticleFootnote =>
      'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Mỗi bé phát triển theo nhịp riêng.';

  @override
  String get lbArticleMissing => 'Bài viết này không còn trong thư viện';

  @override
  String get lbArticleMissingBody =>
      'Bài có thể đã được gỡ để cập nhật. Mở lại Thư viện chăm bé.';

  @override
  String lbSavedToday(String topic) {
    return '$topic · lưu hôm nay';
  }

  @override
  String lbSavedOn(String topic, String date) {
    return '$topic · lưu $date';
  }

  @override
  String get lbSavedEmptyTitle => 'Chưa lưu bài nào';

  @override
  String get lbSavedEmptyBody => 'Bấm Lưu khi đọc một bài để giữ lại đây.';

  @override
  String lbUpdated(String title) {
    return 'Bài “$title” vừa được cập nhật. Mở để xem bản mới.';
  }

  @override
  String get lbStagesTitle => 'Giai đoạn của bé';

  @override
  String get lbStagesIntro =>
      'Gợi ý ngắn cho từng giai đoạn. Mỗi bé phát triển theo nhịp riêng.';

  @override
  String get lbHere => 'Bé đang ở đây';

  @override
  String get lbDoing => 'Bé đang thế nào';

  @override
  String get lbTry => 'Ba mẹ có thể thử';

  @override
  String get lbMilestones => 'Mốc thường gặp';

  @override
  String get lbWeekCardSub => 'Gợi ý cho tuần này trong Nhịp lớn lên';

  @override
  String get lbStageFootnote => 'Mỗi bé phát triển theo nhịp riêng.';

  @override
  String get lbStageMissing => 'Giai đoạn này không còn trong ứng dụng';

  @override
  String get lbStageMissingBody =>
      'Mở lại Giai đoạn của bé để xem các giai đoạn hiện có.';

  @override
  String get lbStagesEmptyTitle => 'Nội dung theo giai đoạn đang được chuẩn bị';

  @override
  String get lbStagesEmptyBody =>
      'Gợi ý cho từng giai đoạn sẽ hiện ở đây ngay khi được xuất bản.';

  @override
  String get lbNoDobTitle => 'Thêm ngày sinh của bé';

  @override
  String get lbNoDobBody =>
      'Để Child Life gợi ý đúng theo tuổi, nhắc Wonder Week và mốc phát triển.';

  @override
  String get lbNoDobAction => 'Thêm ngày sinh';

  @override
  String get lbNoDobViewerTitle => 'Chưa biết bé đang ở giai đoạn nào';

  @override
  String lbNoDobViewer(String name) {
    return 'Bạn chưa được xem ngày sinh của $name, nên app chưa đánh dấu giai đoạn hiện tại. Bạn vẫn đọc được mọi giai đoạn.';
  }

  @override
  String get asLumiIntroEyebrow => 'Mới';

  @override
  String get asLumiIntroTitle => 'Gặp Lumi, trợ lý của nhà bạn';

  @override
  String get asLumiIntroBody =>
      'Chạm để ghi cữ bú bằng một dòng, hỏi về ghi nhận của bé hoặc gửi ảnh hoá đơn. Lumi soạn nháp, bạn xem lại rồi lưu.';

  @override
  String get asLumiIntroBodyText =>
      'Chạm để ghi cữ bú bằng một dòng hoặc hỏi về ghi nhận của bé. Lumi soạn nháp, bạn xem lại rồi lưu.';

  @override
  String get asLumiIntroBodyViewer => 'Chạm để hỏi Lumi về ghi nhận của bé.';

  @override
  String get asLumiIntroLater => 'Để sau';

  @override
  String get asLumiIntroTry => 'Thử ngay';

  @override
  String get asUsageButton => 'Mức dùng';

  @override
  String get rhPlannedTonight => 'Đã lên kế hoạch · tối nay';

  @override
  String get rhPlannedToday => 'Đã lên kế hoạch · hôm nay';

  @override
  String rhPlannedOn(String date) {
    return 'Đã lên kế hoạch · $date';
  }

  @override
  String rhEveningDate(String date) {
    return 'tối $date';
  }

  @override
  String rhPlannedBy(String who, String when) {
    return '$who lên kế hoạch · $when';
  }

  @override
  String get rhPlanAskMorning => 'Sáng mai có thể kể lại kết quả.';

  @override
  String get rhPlanAskEvening => 'Từ 18:00 hôm nay có thể kể lại kết quả.';

  @override
  String get rhKickerFollowUp => 'CẢ NHÀ ĐÃ CÓ DỊP THỬ CHƯA?';

  @override
  String get rhCancelPlan => 'Bỏ kế hoạch';

  @override
  String get rhPlanCanceled => 'Đã bỏ kế hoạch';

  @override
  String get rhDidNotTry => 'Chưa thử';

  @override
  String get rhDidNotTryToast => 'Không sao, lúc khác thử cũng được.';

  @override
  String get rhTriedHistoryTitle => 'Các cách đã thử';

  @override
  String rhTriedHistoryBody(int days) {
    return 'Gợi ý cả nhà đã lên kế hoạch hoặc trả lời trong $days ngày qua, ai làm và thấy thế nào.';
  }

  @override
  String get rhTriedHistoryEmpty =>
      'Chưa có cách nào được lên kế hoạch hay thử.';

  @override
  String get rhSeeAllTried => 'Xem tất cả';

  @override
  String rhWeekMakeVideo(int n) {
    return 'Tạo video tuần thứ $n';
  }

  @override
  String get rhWeekMakeVideoPlain => 'Tạo video của tuần';

  @override
  String rhWeekVideoPhotos(int count) {
    return '$count ảnh trong tuần được chọn sẵn';
  }

  @override
  String hnStepOf(int step, int count) {
    return 'Bước $step trên $count';
  }

  @override
  String hnContinueCount(int count) {
    return 'Tiếp tục · $count mục';
  }

  @override
  String get hnNotifTitle => 'Để Child Life nhắc bạn đúng lúc';

  @override
  String get hnNotifBody =>
      'Chỉ những gì bạn vừa chọn và nhắc việc bạn tự đặt. Không quảng cáo.';

  @override
  String get hnNotifExamples => 'Bạn có thể nhận những loại sau';

  @override
  String get hnNotifExampleTag => 'Ví dụ';

  @override
  String get hnNotifVaccine => 'Nhắc lịch tiêm';

  @override
  String get hnNotifVaccineWhen => 'Trước lịch tiêm';

  @override
  String get hnNotifVaccineSample => '“Mai có lịch tiêm 6 trong 1 lúc 08:30.”';

  @override
  String get hnNotifRhythm => 'Nhịp lớn lên';

  @override
  String get hnNotifRhythmWhen => 'Trước 3 ngày';

  @override
  String get hnNotifRhythmSample =>
      '“Theo lịch tham khảo, con sắp đến giai đoạn 1.”';

  @override
  String get hnNotifWeek => 'Tóm tắt tuần';

  @override
  String get hnNotifWeekWhen => 'Chủ nhật 20:30';

  @override
  String get hnNotifWeekSample => '“Một tuần của con đã sẵn sàng để xem lại.”';

  @override
  String get hnNotifAllow => 'Bật thông báo';

  @override
  String get hnNotifSettingsHint => 'Tắt hoặc chỉnh lại trong Tôi › Thông báo';

  @override
  String get hnNotifDenied =>
      'Thông báo chưa bật. Bạn có thể bật trong Cài đặt của máy.';

  @override
  String get hnNotifBodyAlone =>
      'Lịch tiêm, nhắc việc bạn tự đặt và những ngày đáng nhớ của con. Không quảng cáo.';

  @override
  String get hnNotifMilestone => 'Ngày đáng nhớ';

  @override
  String get hnNotifMilestoneWhen => '09:00 đúng ngày';

  @override
  String hnNotifMilestoneSample(String name) {
    return '“Hôm nay $name tròn 1 tháng.”';
  }

  @override
  String get hnInviteTitle => 'Hôm nay theo cách của nhà bạn';

  @override
  String get hnInviteBody => 'Chọn điều bạn quan tâm · 30 giây';

  @override
  String get hnInviteStart => 'Bắt đầu';

  @override
  String get hnInviteClose => 'Ẩn lời mời cá nhân hoá';

  @override
  String get hnInviteHidden =>
      'Đã ẩn. Bạn vẫn chỉnh được trong Tôi › Cá nhân hoá.';

  @override
  String get hnForBabyBecause => 'Theo điều bạn quan tâm';

  @override
  String get hnForBabyNoInterests => 'Chưa chọn điều bạn quan tâm';

  @override
  String get hnForBabyChange => 'Đổi';

  @override
  String get hnForBabyPick => 'Chọn';

  @override
  String get hnRhythmPill => 'Nhịp lớn lên · Beta';

  @override
  String hnRhythmExpected(String range) {
    return 'Theo lịch tham khảo, dự kiến $range.';
  }

  @override
  String hnRhythmSoothing(int days) {
    return 'Cả nhà ghi nhận con cần được dỗ nhiều hơn $days ngày qua.';
  }

  @override
  String hnCardPage(int page, int count) {
    return 'Thẻ $page trên $count';
  }

  @override
  String get hnCardOptions => 'Tuỳ chọn cho thẻ này';

  @override
  String get mtTitle => 'Mốc phát triển';

  @override
  String mtSummary(String name, int count) {
    return '$name đã có $count mốc';
  }

  @override
  String mtSummaryNone(String name) {
    return '$name chưa có mốc nào';
  }

  @override
  String get mtLead =>
      'Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng.';

  @override
  String get mtLeadViewer =>
      'Các mốc tham khảo theo tuổi. Mỗi bé có nhịp riêng.';

  @override
  String get mtFilterAll => 'Tất cả';

  @override
  String get mtGroupMotor => 'Vận động';

  @override
  String get mtGroupCommunication => 'Giao tiếp';

  @override
  String get mtGroupCognitive => 'Nhận thức';

  @override
  String get mtGroupSocial => 'Cảm xúc – xã hội';

  @override
  String get mtOwn => 'Mốc riêng';

  @override
  String get mtSeen => 'Đã quan sát';

  @override
  String get mtFollowingSection => 'Đang theo dõi';

  @override
  String get mtAround => 'Gợi ý quanh tuổi của bé';

  @override
  String get mtReferenceSection => 'Mốc tham khảo';

  @override
  String get mtOthers => 'Các mốc khác';

  @override
  String mtShowAll(int count) {
    return 'Xem tất cả mốc ($count)';
  }

  @override
  String get mtShowLess => 'Thu gọn';

  @override
  String mtRangeMonths(int from, int to) {
    return 'tham khảo $from–$to tháng';
  }

  @override
  String mtRangeWeeks(int from, int to) {
    return 'tham khảo $from–$to tuần';
  }

  @override
  String mtRangeChipMonths(int from, int to) {
    return 'Tham khảo $from–$to tháng';
  }

  @override
  String mtRangeChipWeeks(int from, int to) {
    return 'Tham khảo $from–$to tuần';
  }

  @override
  String get mtUpcoming => 'Sắp tới';

  @override
  String get mtNotRecorded => 'Chưa ghi';

  @override
  String get mtFollowingTag => 'Đang theo dõi';

  @override
  String get mtCreateOwn => 'Tạo mốc riêng';

  @override
  String get mtIllustrative => 'Nội dung minh hoạ · chờ chuyên môn duyệt';

  @override
  String mtReviewed(String reviewer) {
    return 'Nội dung được $reviewer rà soát';
  }

  @override
  String get mtEmptyTitle => 'Chưa có mốc tham khảo';

  @override
  String get mtEmptyBody =>
      'Nội dung đang được chuẩn bị. Bạn vẫn có thể tạo mốc riêng của bé.';

  @override
  String get mtEmptyBodyViewer => 'Nội dung đang được chuẩn bị.';

  @override
  String get mtNoDob => 'Thêm ngày sinh của bé để xem gợi ý theo tuổi.';

  @override
  String get mtEntrySub => 'Ghi lại những điều bé làm được';

  @override
  String mtEntryCount(int count) {
    return '$count mốc đã ghi';
  }

  @override
  String get mtHowTo => 'Cách nhận biết';

  @override
  String get mtReassure =>
      'Khoảng tuổi chỉ để tham khảo. Mỗi bé có nhịp riêng — nếu bạn băn khoăn, hãy hỏi bác sĩ của bé.';

  @override
  String get mtTalkToDoctor => 'Khi nào nên hỏi bác sĩ';

  @override
  String get mtHealthLink => 'Xem hướng dẫn sức khoẻ';

  @override
  String get mtMarkSeen => 'Đánh dấu đã quan sát';

  @override
  String get mtFollow => 'Lưu để theo dõi';

  @override
  String get mtUnfollow => 'Bỏ theo dõi';

  @override
  String get mtFollowed => 'Đã lưu để theo dõi';

  @override
  String get mtUnfollowed => 'Đã bỏ theo dõi';

  @override
  String get mtSources => 'Nguồn tham khảo';

  @override
  String get mtParentsRecord => 'Ba mẹ của bé ghi lại các mốc trong mục này.';

  @override
  String get mtNotFound => 'Không tìm thấy mốc này.';

  @override
  String get mtDateDid => 'Ngày bé làm được';

  @override
  String get mtNote => 'Ghi chú';

  @override
  String get mtNoteHint => 'Bé làm được lúc nào, ở đâu, với ai…';

  @override
  String get mtPhotosOptional => 'Ảnh (không bắt buộc)';

  @override
  String get mtAddPhotos => 'Thêm ảnh';

  @override
  String get mtRemovePhoto => 'Bỏ ảnh này';

  @override
  String get mtSave => 'Lưu mốc';

  @override
  String get mtPickDate => 'Chọn ngày';

  @override
  String get mtSaved => 'Đã lưu mốc';

  @override
  String get mtSaveFailed => 'Chưa lưu được. Thử lại nhé.';

  @override
  String mtMeta(String date, String name, String age, String who) {
    return '$date · lúc $name $age · $who ghi';
  }

  @override
  String mtMetaNoAge(String date, String who) {
    return '$date · $who ghi';
  }

  @override
  String get mtKeepTitle => 'Giữ khoảnh khắc này trong Kỷ niệm?';

  @override
  String mtKeepBody(String name) {
    return 'Tạo kỷ niệm với ảnh và ghi chú này, gắn mốc “$name”.';
  }

  @override
  String mtKeepBodyNote(String name) {
    return 'Tạo kỷ niệm gắn mốc “$name” — thêm ảnh nếu bạn muốn.';
  }

  @override
  String get mtCreateMemory => 'Tạo kỷ niệm';

  @override
  String get mtCreateCard => 'Tạo thẻ mốc';

  @override
  String get mtInMemories => 'Đã lưu trong Kỷ niệm';

  @override
  String mtSeenByFamily(int count) {
    return 'Cả gia đình xem được · $count ảnh';
  }

  @override
  String mtSeenByParents(int count) {
    return 'Chỉ ba mẹ xem được · $count ảnh';
  }

  @override
  String get mtSeenByFamilyNote => 'Cả gia đình xem được · ghi chú';

  @override
  String get mtSeenByParentsNote => 'Chỉ ba mẹ xem được · ghi chú';

  @override
  String get mtUploading => 'Đang tải lên Kỷ niệm…';

  @override
  String get mtMore => 'Thêm thao tác';

  @override
  String get mtEdit => 'Sửa ghi nhận';

  @override
  String get mtDelete => 'Xoá ghi nhận';

  @override
  String get mtDeleteTitle => 'Xoá ghi nhận mốc này?';

  @override
  String get mtDeleteBody =>
      'Ngày và ghi chú sẽ bị xoá. Kỷ niệm đã tạo vẫn ở trong Kỷ niệm.';

  @override
  String get mtDeleted => 'Đã xoá ghi nhận';

  @override
  String get mtNewMemory => 'Kỷ niệm mới';

  @override
  String get mtCaption => 'Chú thích';

  @override
  String get mtCaptionHint => 'Vài dòng về khoảnh khắc này';

  @override
  String mtTag(String name) {
    return 'Mốc · $name';
  }

  @override
  String get mtWhoSees => 'Ai được xem';

  @override
  String get mtSaveMemory => 'Lưu kỷ niệm';

  @override
  String get mtMemoryCreated => 'Đã tạo kỷ niệm';

  @override
  String get mtCaptionRequired => 'Thêm chú thích hoặc ảnh để lưu kỷ niệm.';

  @override
  String get mtOwnLead =>
      'Những lần đầu tiên chỉ nhà mình có — ghi lại theo cách của bạn.';

  @override
  String get mtName => 'Tên mốc';

  @override
  String get mtNameHint => 'Ví dụ: Lần đầu về quê';

  @override
  String mtCount(int count, int max) {
    return '$count/$max ký tự';
  }

  @override
  String get mtDate => 'Ngày';

  @override
  String get mtAlsoMemory => 'Tạo kỷ niệm cùng lúc';

  @override
  String get mtAlsoMemorySub => 'Lưu ảnh và ghi chú vào Kỷ niệm';

  @override
  String get mtEditTitle => 'Sửa mốc';

  @override
  String lbTodayStageKicker(String range) {
    return 'Giai đoạn của bé · $range';
  }

  @override
  String get lbTodayStageAction => 'Xem giai đoạn';

  @override
  String get lbTodayRead => 'Đọc bài';

  @override
  String get ntBell => 'Thông báo';

  @override
  String ntBellUnread(int count) {
    return 'Thông báo, $count chưa đọc';
  }

  @override
  String get ntInboxTitle => 'Thông báo';

  @override
  String get ntMarkAllRead => 'Đánh dấu đã đọc';

  @override
  String get ntOpenSettings => 'Cài đặt thông báo';

  @override
  String get ntFilterAll => 'Tất cả';

  @override
  String get ntFilterReminders => 'Nhắc việc';

  @override
  String get ntFilterBaby => 'Cho bé';

  @override
  String get ntFilterFamily => 'Gia đình';

  @override
  String get ntSectionToday => 'HÔM NAY';

  @override
  String get ntSectionWeek => 'TUẦN NÀY';

  @override
  String get ntSectionEarlier => 'TRƯỚC ĐÓ';

  @override
  String get ntUnread => 'Chưa đọc';

  @override
  String get ntEmptyTitle => 'Chưa có thông báo nào';

  @override
  String get ntEmptyBody =>
      'Nhắc việc, lịch tiêm và tin của gia đình sẽ hiện ở đây.';

  @override
  String get ntEmptyFiltered => 'Chưa có thông báo nào trong mục này.';

  @override
  String get ntLoadFailed => 'Chưa tải được thông báo. Thử lại sau nhé.';

  @override
  String get ntKept => 'Thông báo được giữ 90 ngày. Vuốt sang trái để ẩn.';

  @override
  String get ntHide => 'Ẩn';

  @override
  String get ntGone => 'Mục này không còn mở được.';

  @override
  String get ntMaster => 'Thông báo của Child Life';

  @override
  String get ntMasterOn => 'Đang bật trong cài đặt hệ thống';

  @override
  String get ntMasterOff => 'Đang tắt trong cài đặt hệ thống';

  @override
  String get ntGroupReminders => 'NHẮC VIỆC BẠN ĐẶT';

  @override
  String get ntGroupRemindersHint =>
      'Luôn đến đúng giờ, kể cả trong giờ yên lặng';

  @override
  String get ntCare => 'Bú, ngủ, thay tã';

  @override
  String get ntCareHint => 'Nhắc theo quy tắc và nhắc một lần';

  @override
  String get ntVaccines => 'Tiêm chủng';

  @override
  String get ntVaccinesHint => 'Trước 3 ngày và tối hôm trước lúc 19:00';

  @override
  String get ntSpending => 'Chi tiêu';

  @override
  String get ntSpendingHint => 'Khoản định kỳ, 80% ngân sách, kết quả nhập';

  @override
  String get ntGroupBaby => 'GỢI Ý CHO BÉ';

  @override
  String get ntGroupBabyHint => 'Gom lại, tối đa 2 thông báo mỗi ngày';

  @override
  String get ntRhythm => 'Nhịp lớn lên';

  @override
  String get ntRhythmHint =>
      'Trước mỗi giai đoạn 3 ngày · check-in tối đa 1/ngày';

  @override
  String get ntStages => 'Giai đoạn của bé';

  @override
  String get ntStagesHint => 'Khi bé sang tuần / tháng mới';

  @override
  String get ntMilestones => 'Mốc phát triển';

  @override
  String get ntMilestonesHint => 'Khi đến khoảng tuổi thường gặp';

  @override
  String get ntArticles => 'Bài viết gợi ý';

  @override
  String get ntArticlesHint => 'Tối đa 1 bài mỗi tuần';

  @override
  String get ntWeekly => 'Tóm tắt tuần';

  @override
  String get ntWeeklyHint => 'Chủ nhật 20:30';

  @override
  String get ntGroupFamily => 'KỶ NIỆM & GIA ĐÌNH';

  @override
  String get ntPhotos => 'Ảnh mới có thể có bé';

  @override
  String get ntPhotosHint => 'Tự lưu kỷ niệm · tối đa 1 lần/ngày';

  @override
  String get ntKeepsakes => 'Gợi ý tạo video, thiệp';

  @override
  String get ntKeepsakesHint => 'Vào ngày tròn tháng, 100 ngày';

  @override
  String get ntFamilyActivity => 'Hoạt động của gia đình';

  @override
  String get ntFamilyActivityHint => 'Thích, xem kỷ niệm';

  @override
  String get ntGroupTiming => 'THỜI GIAN';

  @override
  String get ntDigest => 'Giờ nhận gợi ý';

  @override
  String ntDigestDaily(String time) {
    return '$time mỗi ngày';
  }

  @override
  String get ntQuiet => 'Giờ yên lặng';

  @override
  String ntQuietRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get ntSaveFailed => 'Chưa lưu được. Thử lại nhé.';

  @override
  String get rhPlannedPill => 'Đã lên kế hoạch';

  @override
  String mtTodayKicker(String range) {
    return 'Mốc có thể thấy · $range';
  }

  @override
  String get mtTodayAction => 'Ghi nhận khi bé làm được';

  @override
  String get mtTodayActionViewer => 'Xem cách nhận biết';

  @override
  String get mtEntrySubViewer => 'Mốc tham khảo theo tuổi của bé';

  @override
  String get hnWhyLink => 'Vì sao gợi ý này?';

  @override
  String get hnWhyTitle => 'Vì sao gợi ý này';

  @override
  String get hnWhyFeedbackShort => 'Đã điều chỉnh theo phản hồi của nhà mình.';

  @override
  String get hnWhyHow =>
      'Gợi ý dựa trên điều nhà mình ghi nhận, tuổi của bé và điều bạn quan tâm. Đây không phải chẩn đoán.';

  @override
  String get hnWatchThisWeek => 'Để ý tuần này';

  @override
  String hnWeekKicker(int n, String age) {
    return 'Tuần thứ $n · $age';
  }

  @override
  String hnWeekKickerOnly(int n) {
    return 'Tuần thứ $n';
  }

  @override
  String hnMonthKicker(int n, String age) {
    return 'Tháng thứ $n · $age';
  }

  @override
  String hnMonthKickerOnly(int n) {
    return 'Tháng thứ $n';
  }

  @override
  String get hnWeekOpen => 'Xem tuần này';

  @override
  String hnWeekOpenIdeas(int count) {
    return 'Xem $count gợi ý cho tuần này';
  }

  @override
  String hnWeekRhythmSub(String range) {
    return 'Wonder Weeks · dự kiến $range';
  }

  @override
  String get hnWeekSummaryLast => 'Tóm tắt tuần trước';

  @override
  String get hnWeekSummaryThis => 'Tóm tắt tuần này';

  @override
  String hnRhythmComingDays(int n, int days) {
    return 'Còn $days ngày đến giai đoạn $n';
  }

  @override
  String hnRhythmNow(int n) {
    return 'Đang trong giai đoạn $n';
  }

  @override
  String get asLumiName => 'Lumi';

  @override
  String get asYou => 'Bạn';

  @override
  String get asOnlyYou => 'Chỉ bạn thấy';

  @override
  String get asOnlyYouSpending =>
      'Chỉ bạn thấy · chi tiêu không vào cuộc trò chuyện chung của bé';

  @override
  String get asCopy => 'Sao chép';

  @override
  String get asCopied => 'Đã sao chép';

  @override
  String get asShowTime => 'Xem giờ gửi';

  @override
  String get asNewMessages => 'Tin mới';

  @override
  String get asOfflineBanner =>
      'Đang ngoại tuyến. Tin nhắn được giữ lại và chỉ gửi khi bạn bấm Gửi. Ghi trực tiếp vẫn dùng được.';

  @override
  String get asNotSent => 'Chưa gửi được';

  @override
  String get asUnsentOffline => 'Chưa gửi · đang ngoại tuyến';

  @override
  String get asResend => 'Gửi lại';

  @override
  String get asErrorFriendly =>
      'Mình chưa trả lời được lúc này. Chưa có gì được lưu và không trừ lượt nào — bạn thử lại nhé, hoặc ghi trực tiếp.';

  @override
  String get asReadingPhoto => 'Lumi đang đọc ảnh…';

  @override
  String get asChipLogSleep => 'Ghi giấc ngủ';

  @override
  String get asPrefillSleep => 'Con ngủ từ ';

  @override
  String get asChipExpense => 'Ghi khoản chi';

  @override
  String get asPrefillExpense => 'Mua ';

  @override
  String get asWhenToday => 'Hôm nay';

  @override
  String get asWhenYesterday => 'Hôm qua';

  @override
  String get asWhenTomorrow => 'Ngày mai';

  @override
  String asTimeOnDay(String time, String day) {
    return '$time $day';
  }

  @override
  String asThreadWhen(String day, String time) {
    return '$day · $time';
  }

  @override
  String get asOlderFailed => 'Chưa tải được tin nhắn cũ hơn.';

  @override
  String asSpanLine(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String get asSpanInvalid => 'giờ dậy trước giờ ngủ';

  @override
  String asSpanKnown(String duration) {
    return 'Theo thời lượng bạn nói: $duration';
  }

  @override
  String get asPickSleepTitle => 'Bé ngủ lúc mấy giờ?';

  @override
  String get asPickWakeTitle => 'Bé dậy lúc mấy giờ?';

  @override
  String asAnswerWith(String time) {
    return 'Trả lời: $time';
  }

  @override
  String get asFieldSleepStart => 'Ngủ lúc';

  @override
  String get asFieldSleepEnd => 'Dậy lúc';

  @override
  String get asFieldDuration => 'Thời lượng';

  @override
  String get asShorter => 'Ngắn hơn 15 phút';

  @override
  String get asLonger => 'Dài hơn 15 phút';

  @override
  String get asLessMl => 'Bớt 10 ml';

  @override
  String get asMoreMl => 'Thêm 10 ml';

  @override
  String get asLessMinutes => 'Bớt 5 phút';

  @override
  String get asMoreMinutes => 'Thêm 5 phút';

  @override
  String asBabyLockedLine(String name) {
    return 'Ghi cho $name · không đổi sang bé khác được';
  }

  @override
  String get asPickOtherDay => 'Ngày khác';

  @override
  String get asVoiceStart => 'Nói với Lumi';

  @override
  String get asVoiceStop => 'Dừng nghe';

  @override
  String get asVoiceCancel => 'Bỏ lời vừa nói';

  @override
  String get asVoiceListening => 'Đang nghe…';

  @override
  String get asVoiceSwipe => 'Đang nghe… vuốt sang trái để huỷ';

  @override
  String get asVoiceIntroTitle => 'Nói với Lumi thay vì gõ';

  @override
  String get asVoiceIntroWords =>
      'Chạm mic rồi nói. Chữ hiện ngay trong ô nhập; bạn sửa được và chỉ gửi khi bấm Gửi.';

  @override
  String get asVoiceIntroServerIos =>
      'iPhone chuyển giọng nói thành chữ ngay trên máy khi có thể. Khi máy chưa làm được (ví dụ chưa có tiếng Việt ngoại tuyến), dịch vụ nhận dạng của Apple có thể xử lý âm thanh trên máy chủ của Apple.';

  @override
  String get asVoiceIntroServerAndroid =>
      'Điện thoại chuyển giọng nói thành chữ ngay trên máy khi có thể. Khi chưa làm được, dịch vụ nhận dạng giọng nói của máy (thường của Google) có thể xử lý âm thanh trên máy chủ của họ.';

  @override
  String get asVoiceIntroNothingKept =>
      'Child Life không ghi âm, không lưu và không gửi âm thanh. Chỉ phần chữ bạn bấm Gửi mới tới Lumi.';

  @override
  String get asVoiceIntroFree => 'Nói thay vì gõ không tốn lượt AI.';

  @override
  String get asVoiceIntroAllow => 'Bật micro';

  @override
  String get asVoiceIntroLater => 'Để sau';

  @override
  String get asVoiceDenied =>
      'Chưa có quyền dùng micro hoặc nhận dạng giọng nói. Bật trong Cài đặt để nói với Lumi.';

  @override
  String get asVoiceUnavailable =>
      'Máy này chưa nhận dạng giọng nói được. Bạn gõ chữ nhé.';

  @override
  String get asVoiceLanguage =>
      'Máy chưa nhận dạng được giọng nói tiếng Việt. Thêm ngôn ngữ trong Cài đặt của máy, hoặc gõ chữ nhé.';

  @override
  String get asVoiceNoSpeech =>
      'Mình chưa nghe thấy gì. Thử nói gần máy hơn nhé.';

  @override
  String get asVoiceFailed =>
      'Nhận dạng giọng nói bị gián đoạn. Phần chữ đã có vẫn ở trong ô nhập.';

  @override
  String get asChipFeedsShort => 'Cữ bú hôm nay';

  @override
  String get asEditInModule => 'Sửa trong nhật ký';

  @override
  String get asSpendingMoved =>
      'Chỉ bạn thấy: tin nhắn có chi tiêu được giữ trong cuộc trò chuyện riêng của bạn.';

  @override
  String get asSaveBottle => 'Lưu cữ bú bình';

  @override
  String get asSaveBreast => 'Lưu cữ bú';

  @override
  String get asSaveSleep => 'Lưu giấc ngủ';

  @override
  String get asSaveReminder => 'Lưu nhắc việc';

  @override
  String get asSaveItem => 'Lưu';

  @override
  String asSaveItems(int count) {
    return 'Lưu $count mục';
  }

  @override
  String asStillToFill(int count) {
    return 'Còn $count mục cần bổ sung ở trên';
  }

  @override
  String get asKindTimer => 'Đồng hồ';

  @override
  String get asTimerTitleStartSleep => 'Tính giờ ngủ';

  @override
  String get asTimerTitleStartBreast => 'Tính giờ bú mẹ';

  @override
  String get asTimerTitleStopSleep => 'Kết thúc giấc ngủ';

  @override
  String get asTimerTitleStopBreast => 'Kết thúc cữ bú';

  @override
  String asTimerStartSleep(String time) {
    return 'Bắt đầu tính giờ ngủ · $time';
  }

  @override
  String asTimerStartBreast(String side, String time) {
    return 'Bắt đầu tính giờ bú · $side · $time';
  }

  @override
  String asTimerStopSleep(String time) {
    return 'Kết thúc giấc ngủ · $time';
  }

  @override
  String asTimerStopBreast(String time) {
    return 'Kết thúc cữ bú · $time';
  }

  @override
  String get asTimerKeep => 'Để tiếp tục';

  @override
  String asTimerFrom(String time) {
    return 'Từ $time';
  }

  @override
  String asTimerSideFirst(String side) {
    return 'bên $side trước';
  }

  @override
  String asTimerSleeping(String elapsed) {
    return 'Đang ngủ · $elapsed';
  }

  @override
  String asTimerFeeding(String elapsed) {
    return 'Đang bú · $elapsed';
  }

  @override
  String get asTimerOpen => 'Mở đồng hồ';

  @override
  String get asTimerEnded => 'Đồng hồ đã kết thúc';

  @override
  String asTimerRunningSince(String time) {
    return 'Đang tính giờ từ $time';
  }

  @override
  String get asErrTimerRunning => 'Đồng hồ này đã được bắt đầu trên máy khác.';

  @override
  String get asErrTimerChanged =>
      'Đồng hồ đã kết thúc hoặc thay đổi trên máy khác.';

  @override
  String get asGapFeedTime => 'Chưa có giờ bé bú';

  @override
  String get asGapSleepStart => 'Chưa có giờ bé bắt đầu ngủ';

  @override
  String get asGapSleepEnd => 'Chưa có giờ bé dậy';

  @override
  String asGapTimeUnsure(String time) {
    return 'Giờ $time có đúng không?';
  }

  @override
  String asGapTimeFuture(String time) {
    return '$time chưa tới. Chọn lại giờ nhé.';
  }

  @override
  String get asGapSleepOrder => 'Giờ dậy phải sau giờ bắt đầu ngủ';

  @override
  String get asGapAmount => 'Chưa có lượng sữa (ml)';

  @override
  String asGapAmountUnsure(String ml) {
    return 'Lượng $ml ml có đúng không?';
  }

  @override
  String get asGapAmountRange => 'Lượng sữa cần từ 1 đến 500 ml';

  @override
  String get asGapMilk => 'Chưa rõ sữa mẹ hay sữa công thức';

  @override
  String get asGapSide => 'Chưa rõ bé bú bên nào';

  @override
  String asGapDurationUnsure(String duration) {
    return 'Thời lượng $duration có đúng không?';
  }

  @override
  String get asGapDurationRange => 'Cữ bú không dài quá 180 phút';

  @override
  String get asGapWhen => 'Giấc ban ngày hay ban đêm? (không bắt buộc)';

  @override
  String asGapDateUnsure(String date) {
    return 'Ngày $date có đúng không?';
  }

  @override
  String get asGapReminderDate => 'Chưa có ngày nhắc';

  @override
  String get asGapReminderPast => 'Thời điểm nhắc đã qua. Chọn ngày khác nhé.';

  @override
  String get asGapTitle => 'Tên việc dài quá (tối đa 80 ký tự)';

  @override
  String get asGapAssignee => 'Người được giao không còn trong nhà';

  @override
  String get asGapTimerOld =>
      'Đồng hồ không tính từ lâu vậy được. Chọn giờ gần hơn.';

  @override
  String asGapTimerEnd(String time) {
    return 'Giờ kết thúc phải sau $time';
  }

  @override
  String get asGapExpenseAmount => 'Chưa có số tiền';

  @override
  String get asGapExpenseAmountUnsure => 'Số tiền có đúng không?';

  @override
  String get asGapExpenseCurrency => 'Chưa rõ đơn vị tiền';

  @override
  String get asGapExpenseCategory => 'Danh mục có đúng không?';

  @override
  String get asGapExpenseMerchant => 'Tên cửa hàng có đúng không?';

  @override
  String get asFixRight => 'Đúng rồi';

  @override
  String asFixJustNow(String time) {
    return 'Vừa xong ($time)';
  }

  @override
  String asFixAgo30(String time) {
    return '30 phút trước ($time)';
  }

  @override
  String asFixAgo60(String time) {
    return '1 tiếng trước ($time)';
  }

  @override
  String asFixWokeNow(String time) {
    return 'Vừa dậy ($time)';
  }

  @override
  String asFixSlept(int hours, String time) {
    return 'Ngủ $hours tiếng (từ $time)';
  }

  @override
  String get asFixPickTime => 'Chọn giờ';

  @override
  String get asFixPickDate => 'Chọn ngày';

  @override
  String get asFixToday => 'Hôm nay';

  @override
  String get asFixYesterday => 'Hôm qua';

  @override
  String get asFixTomorrow => 'Ngày mai';

  @override
  String asFixMl(String ml) {
    return '$ml ml';
  }

  @override
  String get asFixDayTime => 'Ban ngày';

  @override
  String get asFixNightTime => 'Ban đêm';

  @override
  String get asFixNoAssignee => 'Không giao';

  @override
  String get asFixed => 'Đã bổ sung, sẵn sàng lưu';

  @override
  String get asPickAboveToSave => 'Chọn ở trên là lưu được ngay.';

  @override
  String get asGapWhenAsk => 'Giấc ban ngày hay ban đêm?';

  @override
  String get asGapNote => 'Ghi chú có đúng không?';

  @override
  String get asFixDropNote => 'Bỏ ghi chú';

  @override
  String get asGapObservation => 'Loại ghi nhận có đúng không?';

  @override
  String get asKindGrowth => 'Cân đo';

  @override
  String asMeasuredOnLine(String date) {
    return 'Ngày đo $date';
  }

  @override
  String get asPumpSideLeft => 'Bên trái';

  @override
  String get asPumpSideRight => 'Bên phải';

  @override
  String get asPumpSideBoth => 'Cả hai bên';

  @override
  String get asOpenModule => 'Mở mục';

  @override
  String get asSaveDiaper => 'Lưu thay tã';

  @override
  String get asGapPumpTime => 'Chưa có giờ hút sữa';

  @override
  String get asGapDiaperTime => 'Chưa có giờ thay tã';

  @override
  String asGapSleepStartUnsure(String time) {
    return 'Giờ ngủ $time có đúng không?';
  }

  @override
  String asGapSleepEndUnsure(String time) {
    return 'Giờ dậy $time có đúng không?';
  }

  @override
  String asFixTomorrowAt(String time) {
    return 'Ngày mai $time';
  }

  @override
  String get asGapPumpAmount => 'Chưa có lượng sữa hút (ml)';

  @override
  String get asGapPumpAmountRange => 'Lượng sữa hút cần từ 1 đến 1000 ml';

  @override
  String get asGapPumpSide => 'Chưa rõ hút bên nào';

  @override
  String get asGapPumpDuration => 'Hút bao lâu?';

  @override
  String get asGapPumpDurationRange => 'Mỗi lần hút không quá 240 phút';

  @override
  String get asGapDiaper => 'Tã ướt, bẩn hay cả hai?';

  @override
  String get asGapWeight => 'Chưa có cân nặng (kg)';

  @override
  String asGapWeightUnsure(String kg) {
    return 'Cân nặng $kg kg có đúng không?';
  }

  @override
  String get asFixEnterWeight => 'Nhập cân nặng';

  @override
  String get asGapLength => 'Chưa có chiều dài (cm)';

  @override
  String asGapLengthUnsure(String cm) {
    return 'Chiều dài $cm cm có đúng không?';
  }

  @override
  String get asFixEnterLength => 'Nhập chiều dài';

  @override
  String get asFixDropLength => 'Bỏ chiều dài';

  @override
  String get asGapMeasuredOn => 'Chưa có ngày đo';

  @override
  String get asGapMeasuredOnFuture => 'Ngày đo chưa tới. Chọn lại ngày nhé.';

  @override
  String asGapMeasuredOnUnsure(String date) {
    return 'Ngày đo $date có đúng không?';
  }

  @override
  String get asEditPump => 'Sửa hút sữa';

  @override
  String get asEditDiaper => 'Sửa thay tã';

  @override
  String get asEditGrowth => 'Sửa cân đo';

  @override
  String get asFieldWeight => 'Cân nặng';

  @override
  String get asFieldLength => 'Chiều dài · tùy chọn';

  @override
  String get asFieldMeasuredOn => 'Ngày đo';

  @override
  String get asFieldDiaper => 'Loại tã';

  @override
  String get growthHeadOptional => 'Vòng đầu · tùy chọn';

  @override
  String get growthHeadRange => 'Vòng đầu từ 20 đến 60 cm.';

  @override
  String headCm(String v) {
    return 'vòng đầu $v cm';
  }

  @override
  String get growthHeadTab => 'Vòng đầu';

  @override
  String get detailHead => 'Vòng đầu';

  @override
  String bpHead(String when) {
    return 'Vòng đầu · $when';
  }

  @override
  String whoBelowHeadNote(String name) {
    return 'Vòng đầu của $name đang nhỏ hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String whoAboveHeadNote(String name) {
    return 'Vòng đầu của $name đang lớn hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.';
  }

  @override
  String get asFieldHead => 'Vòng đầu · tùy chọn';

  @override
  String get asGapHead => 'Chưa có vòng đầu (cm)';

  @override
  String asGapHeadUnsure(String cm) {
    return 'Vòng đầu $cm cm có đúng không?';
  }

  @override
  String get asFixEnterHead => 'Nhập vòng đầu';

  @override
  String get asFixDropHead => 'Bỏ vòng đầu';

  @override
  String get asAskAmount => 'Hết bao nhiêu tiền?';

  @override
  String get growthMeasureNone =>
      'Chưa có số đo này. Thêm khi đo cho bé lần tới.';
}
