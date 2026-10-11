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
  String get remindersTitle => 'Nhắc việc';

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
  String notifBody(String name, String when) {
    return '$name · $when';
  }

  @override
  String get notifChannel => 'Nhắc việc';

  @override
  String get notifChannelDescription => 'Nhắc việc của gia đình';

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
  String get addRecentHint => 'Chạm để thêm nhanh';

  @override
  String get addCamera => 'Chụp ảnh hoặc quay video';

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
}
