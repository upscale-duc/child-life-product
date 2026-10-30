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
  String get existsBody =>
      'Đăng nhập bằng cách bạn đã dùng trước đây, hoặc nhận link đăng nhập qua email.';

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
  String get saveAccountMergedArriving =>
      'Đã gộp vào tài khoản của bạn. Gia đình đang tải, chờ chút nhé.';

  @override
  String get saveAccountMergedSignIn =>
      'Đã gộp vào tài khoản của bạn. Đăng nhập lại để mở.';

  @override
  String get existsOtherMethod =>
      'Email của tài khoản này đã đăng ký theo cách khác. Thử gửi link đăng nhập.';

  @override
  String signOutUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count bản ghi chưa gửi lên.',
      zero: 'Còn thay đổi chưa gửi lên.',
    );
    return '$_temp0 Đăng xuất bây giờ thì chúng chỉ được gửi khi bạn đăng nhập lại trên máy này.';
  }

  @override
  String signOutAnonUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản ghi chưa gửi lên cũng sẽ mất.',
      zero: 'Thay đổi chưa gửi lên cũng sẽ mất.',
    );
    return '$_temp0';
  }

  @override
  String get unsentSendNow => 'Thử gửi ngay';

  @override
  String get unsentStillPending =>
      'Vẫn chưa gửi được. Kiểm tra mạng rồi thử lại.';

  @override
  String get meSignOutAnyway => 'Vẫn đăng xuất';

  @override
  String acDeleteUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản ghi chưa gửi lên sẽ mất khi xoá tài khoản.',
      zero: 'Thay đổi chưa gửi lên sẽ mất khi xoá tài khoản.',
    );
    return '$_temp0';
  }

  @override
  String get acDeleteAnyway => 'Vẫn xoá tài khoản';

  @override
  String get acDeleteOwnsBabies =>
      'Cần chuyển chủ hồ sơ bé trước khi xoá tài khoản.';

  @override
  String get profileSaveFailed => 'Chưa lưu được hồ sơ. Thử lại nhé.';

  @override
  String get bpLoadFailed => 'Chưa tải được hồ sơ của bé.';

  @override
  String get joinLoadFailedTitle => 'Chưa mở được lời mời';

  @override
  String get joinLoadFailedOffline =>
      'Không có mạng. Lời mời vẫn còn, kết nối rồi thử lại nhé.';

  @override
  String get joinLoadFailedBody => 'Có lỗi khi mở lời mời. Thử lại nhé.';

  @override
  String get joinFullTitle => 'Gia đình đã hết chỗ người ghi';

  @override
  String get joinFullBody =>
      'Nhờ người mời bạn mở thêm chỗ, hoặc mời bạn làm người thân để cùng xem album.';

  @override
  String pv2SeatsHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lời mời đang giữ chỗ',
    );
    return '$_temp0';
  }

  @override
  String get inviteSeatsHeldHint =>
      'Lời mời chưa nhận cũng giữ chỗ. Huỷ lời mời không cần nữa trong Gia đình để mở chỗ.';

  @override
  String joinArriving(String baby) {
    return 'Đã vào gia đình $baby. Đang tải, chờ chút nhé…';
  }

  @override
  String joinCountdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Còn $minutes phút',
    );
    return '$_temp0';
  }

  @override
  String get familyLoadFailedGeneric => 'Chưa tải được danh sách.';

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
    return '$count cữ · $ml ml';
  }

  @override
  String rhythmBreast(int count, int minutes) {
    return '$count cữ · $minutes phút';
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
      'Để nhắc việc kêu đúng giờ, kể cả khi đang đóng app.';

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
  String get albJustShared => 'Khoảnh khắc vừa chia sẻ';

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
  String get stLoadFailed => 'Ảnh, video vẫn an toàn. Thử lại khi có kết nối.';

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
  String get ntFootnote => 'Thông báo không bao giờ kèm ảnh của bé.';

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
    return '$day · $ml ml · $count cữ';
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
    return '$day · $minutes phút · $count cữ';
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
    return '$minutes phút · $count cữ';
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
  String get careGrowth => 'Tăng trưởng';

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
  String get vxProgNational => 'Chương trình quốc gia';

  @override
  String get vxProgRecommended => 'Khuyến nghị, có thể tự chi trả';

  @override
  String vxCountryNotice(String programme, String date) {
    return 'Theo $programme, cập nhật $date. Lịch của bé có thể khác tuỳ bác sĩ hoặc vùng nơi bạn sống.';
  }

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
    return '$count ảnh, video chưa tải lên';
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
  String get fbIntro => 'Đội ngũ Child Life đọc từng góp ý.';

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
      'Child Life tìm ảnh và video có thể có con. Bạn xem lại rồi mới tải lên.';

  @override
  String get autoSaveStep1 => 'Chọn bé và vài ảnh rõ mặt';

  @override
  String get autoSaveStep2 => 'App tìm trong ảnh mới';

  @override
  String get autoSaveStep2Hint =>
      'Ngay trên máy, chỉ những ảnh bạn cho phép xem, không gửi đi';

  @override
  String get autoSaveStep3 => 'Bạn duyệt rồi mới tải';

  @override
  String get autoSaveStep3Hint => 'Không tự chia sẻ';

  @override
  String autoSaveIntroFootnote(String usage) {
    return 'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Tệp đã tải tính vào dung lượng của gia đình (đã dùng $usage).';
  }

  @override
  String get autoSaveIntroFootnoteNoUsage =>
      'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Tệp đã tải tính vào dung lượng của gia đình.';

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
  String autoSaveWeek(int n, int count) {
    return 'Tuần $n · $count';
  }

  @override
  String autoSaveWeekBefore(int count) {
    return 'Trước sinh · $count';
  }

  @override
  String autoSaveWeekDone(int n) {
    return 'Tuần $n · xong';
  }

  @override
  String autoSaveFilterAll(int count) {
    return 'Ảnh & video · $count';
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
  String get autoSaveAlready => 'Đã có';

  @override
  String get autoSaveInCloud => 'Trên iCloud';

  @override
  String get autoSaveLegend =>
      '“Trên iCloud”: tệp gốc chưa có trong máy, sẽ lấy về khi có mạng.';

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
  String get autoSaveBest => 'Rõ nhất';

  @override
  String autoSaveChosen(int count, int photos, int videos) {
    return 'Đã chọn $count · $photos ảnh, $videos video';
  }

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
  String get autoSaveReviewDoneTitle => 'Ảnh mới đã được xử lý rồi';

  @override
  String get autoSaveReviewDoneBody =>
      'Những ảnh này đã được lưu hoặc bỏ qua. Khi điện thoại có ảnh mới có thể có bé, Child Life sẽ gợi ý tiếp.';

  @override
  String get autoSaveReviewOpenMemories => 'Xem Kỷ niệm';

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
  String get autoSaveOnBeta => 'Đang bật';

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
  String get ksPremium => 'Premium';

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
  String get ksCardTileHint => 'Ảnh để chia sẻ';

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
  String get pmPlanTitle => 'Gói của gia đình';

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
  String get rhReviewPending =>
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ';

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
  String get rhTryToday => 'Mình sẽ thử';

  @override
  String get rhTryTonight => 'Mình sẽ thử';

  @override
  String get rhTryAgainToday => 'Thử lại lần nữa';

  @override
  String get rhTryAgainTonight => 'Thử lại lần nữa';

  @override
  String get rhNotToday => 'Để hôm khác';

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
  String get rhTryAgain => 'Thử lại lần nữa';

  @override
  String get rhIllTry => 'Mình sẽ thử';

  @override
  String get rhNotRight => 'Không phù hợp với con';

  @override
  String get rhAnotherIdea => 'Để hôm khác';

  @override
  String get rhTellHow => 'Con thế nào?';

  @override
  String get rhStartedToast =>
      'Chúc cả nhà thuận lợi! Thử xong thì kể lại nhé.';

  @override
  String get rhNotRightToast =>
      'Đã ghi nhận. Sẽ không gợi ý lại cách này cho con.';

  @override
  String get rhActivityMissing => 'Gợi ý này không còn nữa';

  @override
  String get rhHowLastNight => 'Tối qua con thế nào?';

  @override
  String get rhHowDidItGo => 'Thử rồi, con thế nào?';

  @override
  String get rhHelpful => 'Có ích';

  @override
  String get rhUnsure => 'Chưa rõ';

  @override
  String get rhNotAFit => 'Không hợp';

  @override
  String get rhNoteHint => 'Ghi chú (tuỳ chọn)';

  @override
  String get rhFeedbackInfo =>
      'Dùng để chọn gợi ý lần sau, không phải kết luận cách này có tác dụng.';

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
    return 'Dự kiến $range · còn $days ngày';
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
    return 'Gần đây ít hơn khoảng $delta so với trước.';
  }

  @override
  String rhSleepHigher(String delta) {
    return 'Gần đây nhiều hơn khoảng $delta so với trước.';
  }

  @override
  String get rhSleepSame => 'Gần đây gần với mức thường của con.';

  @override
  String rhSleepBasis(int recent, String range, int baseline) {
    return '$recent ngày gần nhất ($range) so với $baseline ngày ghi đủ trước đó.';
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
  String get aiHandoverTitle => 'Bàn giao';

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
  String get aiRefreshing => 'Đang cập nhật theo ghi nhận mới…';

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
      'Ghi nhận và hướng dẫn sức khoẻ không bị ảnh hưởng.';

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
  String get aiStateFailedBody => 'Ghi nhận của nhà mình vẫn giữ nguyên.';

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
  String get rhEpSuggestTitle => 'Mấy ngày này con khác?';

  @override
  String rhEpSuggestBody(int count, String people, String what) {
    return '$count ngày gần đây cả nhà thấy con $what.';
  }

  @override
  String rhEpPersonDay(String who, String date) {
    return '$who ($date)';
  }

  @override
  String get rhEpNotWonder => 'Không phải xác nhận một giai đoạn Wonder Weeks.';

  @override
  String get rhEpCreate => 'Theo dõi';

  @override
  String get rhEpNoNeed => 'Không cần';

  @override
  String rhEpOpenTitle(String start) {
    return 'Mấy ngày con khác · $start – nay';
  }

  @override
  String get rhEpUpdating => 'Đang cập nhật';

  @override
  String rhEpOpenBody(String who, int count) {
    return '$who gom $count ghi nhận lại để theo dõi. Khép lại khi cả nhà thấy “con đã ổn hơn”.';
  }

  @override
  String get rhEpBetter => 'Con đã ổn hơn';

  @override
  String get rhEpCloseTitle => 'Khép lại mấy ngày này?';

  @override
  String rhEpCloseBody(String start) {
    return 'Đợt sẽ được lưu từ $start đến hôm nay. Child Life không tự kết thúc đợt khi không có ghi nhận.';
  }

  @override
  String get rhEpNotYet => 'Chưa';

  @override
  String get rhEpCreated => 'Đã bắt đầu theo dõi';

  @override
  String get rhEpClosed => 'Đã khép lại';

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
      'Nhờ chủ hộ mở Gói của gia đình để nâng cấp hoặc khôi phục.';

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
  String get rhWeekShare => 'Chia sẻ';

  @override
  String get rhWeekRecordedTitle => 'Đã ghi trong tuần';

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
  @override
  String asComposerAnswering(String question) {
    return 'Đang trả lời: $question';
  }

  @override
  String get asComposerDropQuestion => 'Bỏ câu hỏi này';

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
  String get asCanceled => 'Đã huỷ.';

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
  String get asOpenRecord => 'Mở bản ghi';

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
  String get asErrSaveFailed => 'Chưa lưu được. Bạn thử lại nhé.';

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
      'Premium có thêm credit Lumi, gợi ý cá nhân và mẫu thiệp, video cao cấp.';

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
  String get asUpgradeContinue => 'Xem Premium để hỏi tiếp';

  @override
  String get asHealthStillOpen => 'Hướng dẫn sức khoẻ thiết yếu vẫn mở.';

  @override
  String get asOpenHealth => 'Mở Hướng dẫn sức khoẻ';

  @override
  String get asOutTitlePremium => 'Hộ đã dùng hết lượt hỗ trợ AI kỳ này.';

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
  String get asUploadCanceled => 'Đã huỷ tải lên. Ảnh vẫn được chọn.';

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
      'Bạn có thể rời màn hình; kết quả vẫn ở đây khi bạn quay lại.';

  @override
  String get asPhotoFailBody =>
      'Ảnh chưa được đọc và chưa có gì được lưu. Ảnh vẫn được chọn.';

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
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · tham khảo, không thay thế bác sĩ. Không khẳng định nguyên nhân.';

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
  String get lbIllustrative =>
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ';

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
  String get lbStagesIntro => 'Mỗi bé phát triển theo nhịp riêng.';

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
  String get rhPlannedTonight => 'Sẽ thử · tối nay';

  @override
  String get rhPlannedToday => 'Sẽ thử · hôm nay';

  @override
  String rhPlannedOn(String date) {
    return 'Sẽ thử · $date';
  }

  @override
  String rhEveningDate(String date) {
    return 'tối $date';
  }

  @override
  String rhPlannedBy(String who, String when) {
    return '$who sẽ thử · $when';
  }

  @override
  String get rhPlanAskMorning => 'Sáng mai hỏi lại con thế nào.';

  @override
  String get rhPlanAskEvening => 'Từ 18:00 hỏi lại con thế nào.';

  @override
  String get rhKickerFollowUp => 'THỬ RỒI, CON THẾ NÀO?';

  @override
  String get rhCancelPlan => 'Thôi, không thử';

  @override
  String get rhPlanCanceled => 'Đã bỏ lượt thử này';

  @override
  String get rhDidNotTry => 'Chưa thử được';

  @override
  String get rhDidNotTryToast => 'Không sao, lúc khác thử cũng được.';

  @override
  String get rhTriedHistoryTitle => 'Cách nhà mình đã thử';

  @override
  String rhTriedHistoryBody(int days) {
    return '$days ngày qua · cả nhà';
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
  String get mtLead => 'Mỗi bé có nhịp riêng.';

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
  String get mtSeen => 'Bé đã làm được';

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
  String get mtIllustrative =>
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ';

  @override
  String get mtNotInMemoriesTile => 'Chưa vào Kỷ niệm';

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
  String get mtMarkSeen => 'Bé đã làm được';

  @override
  String get mtFollow => 'Theo dõi mốc này';

  @override
  String get mtUnfollow => 'Bỏ theo dõi';

  @override
  String get mtFollowed => 'Đang theo dõi';

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
  String get mtPhotosOptional => 'Ảnh, video (không bắt buộc)';

  @override
  String get mtAddPhotos => 'Thêm ảnh, video';

  @override
  String get mtRemovePhoto => 'Bỏ mục này';

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
  String get ntFilterMemories => 'Kỷ niệm';

  @override
  String get ntFilterFamily => 'Gia đình';

  @override
  String get ntFilterCare => 'Chăm sóc';

  @override
  String get ntFilterOther => 'Khác';

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
  String get ntLoadFailed => 'Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get ntLoadFailedTitle => 'Chưa tải được thông báo';

  @override
  String get ntLoading => 'Đang tải thông báo';

  @override
  String get ntLoadMore => 'Xem thông báo cũ hơn';

  @override
  String get ntKept => 'Thông báo được giữ 90 ngày. Vuốt sang trái để ẩn.';

  @override
  String get ntHide => 'Ẩn';

  @override
  String get ntGone => 'Mục này không còn mở được.';

  @override
  String get ntOpenedNearest =>
      'Không mở được đúng mục này, đã mở trang gần nhất.';

  @override
  String get ntMaster => 'Thông báo của Child Life';

  @override
  String get ntMasterOn => 'Đang bật trong cài đặt hệ thống';

  @override
  String get ntMasterOff => 'Đang tắt trong cài đặt hệ thống';

  @override
  String get ntOffTitle => 'Thông báo đang tắt';

  @override
  String get ntOffBody =>
      'Bạn sẽ không nhận nhắc bú, ngủ, tiêm chủng hay tin từ gia đình. Chạm để bật lại trong Cài đặt.';

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
  String get ntGroupBabyHint => 'Tối đa 2 thông báo mỗi ngày';

  @override
  String get ntRhythm => 'Nhịp lớn lên';

  @override
  String get ntRhythmHint => '3 ngày trước mỗi giai đoạn mới';

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
  String get ntPhotosHint => 'Từ Tự lưu kỷ niệm, tối đa 1 lần mỗi ngày';

  @override
  String get ntKeepsakes => 'Gợi ý tạo video, thiệp';

  @override
  String get ntKeepsakesHint => 'Vào ngày tròn tháng, 100 ngày';

  @override
  String get ntFamilyActivity => 'Hoạt động của gia đình';

  @override
  String get ntFamilyActivityHint => 'Khi có người thích hoặc xem kỷ niệm';

  @override
  String get ntFamilyMembers => 'Thành viên gia đình';

  @override
  String get ntFamilyMembersHint =>
      'Khi có người tham gia hoặc từ chối lời mời';

  @override
  String get ntBabyName => 'Hiện tên bé trong thông báo';

  @override
  String get ntBabyNameHint => 'Tắt thì thông báo chỉ ghi “bé”.';

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
  String get ntSettingsLoadFailed => 'Chưa tải được cài đặt thông báo';

  @override
  String get ntGroupLoadFailed => 'Chưa tải được. Chạm để thử lại.';

  @override
  String get ntTurnOn => 'Bật';

  @override
  String get ruleNotifOff =>
      'Máy này đang tắt thông báo nên nhắc theo quy tắc sẽ không hiện.';

  @override
  String get meNotifOffDevice => 'Tắt trong máy';

  @override
  String get meRateOpenFailed =>
      'Chưa mở được cửa hàng ứng dụng. Thử lại sau nhé.';

  @override
  String get rhPlannedPill => 'Sẽ thử';

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
      'Mình chưa trả lời được lúc này. Chưa có gì được lưu — bạn thử lại nhé, hoặc ghi trực tiếp.';

  @override
  String get asActOffline =>
      'Đang ngoại tuyến · chưa gửi được. Có mạng rồi thử lại.';

  @override
  String get asActFailed => 'Chưa gửi được. Bạn thử lại nhé.';

  @override
  String get asActChecking => 'Mạng chậm · đang kiểm tra lại…';

  @override
  String get asAnswerStale => 'Câu hỏi vừa thay đổi. Xem lại ở trên nhé.';

  @override
  String get asAnswerOffline =>
      'Đang ngoại tuyến · câu trả lời chưa gửi, vẫn ở ô nhập.';

  @override
  String get asAnswerFailed =>
      'Chưa gửi được câu trả lời. Chữ vẫn ở ô nhập, bạn thử lại nhé.';

  @override
  String get asChecking => 'Đang kiểm tra…';

  @override
  String get asEditKept => 'Sửa lại';

  @override
  String get asErrorNoRetry =>
      'Mình chưa làm được việc này. Chưa có gì được lưu — bạn ghi trực tiếp nhé.';

  @override
  String get asStillWorking => 'Lumi vẫn đang xử lý…';

  @override
  String get asTaskSlowBody =>
      'Lumi đang lâu hơn thường lệ. Chưa có gì được lưu từ câu này.';

  @override
  String get asCheckAgain => 'Kiểm tra lại';

  @override
  String asOutResetOn(String date) {
    return 'Lượt mới có từ $date.';
  }

  @override
  String get asOutResetNext => 'Lượt mới có vào kỳ tới.';

  @override
  String get asBlockedOld => 'Chưa trả lời · lúc đó đã hết lượt';

  @override
  String get asAskAgain => 'Hỏi lại';

  @override
  String asPhotoQuoteTitleOver(int credits) {
    return 'Đọc ảnh này cần $credits lượt, nhiều hơn số lượt còn lại.';
  }

  @override
  String get asPhotoQuoteWait =>
      'Bạn có thể nhập tay hoặc đợi lượt mới. Ảnh chưa được gửi đi.';

  @override
  String get asPhotoQuoteWaitUpgrade =>
      'Bạn có thể nhập tay, đợi lượt mới hoặc nâng cấp để tiếp tục ngay. Ảnh chưa được gửi đi.';

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
  String get asKeepQuestion => 'Giữ lại';

  @override
  String asDraftEditTitle(String kind) {
    return 'Sửa $kind';
  }

  @override
  String asDraftDeleteTitle(String kind) {
    return 'Xoá $kind';
  }

  @override
  String get asSaveChange => 'Lưu thay đổi';

  @override
  String get asDeleteRecord => 'Xoá khỏi nhật ký';

  @override
  String get asKeepRecord => 'Không xoá';

  @override
  String get asStateDeleted => 'Đã xoá';

  @override
  String get asStateUpdated => 'Đã cập nhật';

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

  @override
  String get careNutrition => 'Dinh dưỡng';

  @override
  String get careNutritionSub => 'Theo từng giai đoạn tuổi';

  @override
  String careNutritionStage(String range) {
    return 'Giai đoạn $range';
  }

  @override
  String get careNutritionNoDob => 'Cần ngày sinh của bé';

  @override
  String get nuTitle => 'Dinh dưỡng';

  @override
  String nuMonthsRange(int from, int to) {
    return '$from–$to tháng';
  }

  @override
  String get nuCurrent => 'Hiện tại';

  @override
  String get nuOffline =>
      'Không có kết nối. Dinh dưỡng đang hiện bản đã lưu trên máy.';

  @override
  String get nuEmptyTitle => 'Nội dung dinh dưỡng đang được chuẩn bị';

  @override
  String get nuEmptyBody =>
      'Gợi ý theo giai đoạn tuổi sẽ hiện ở đây ngay khi được xuất bản.';

  @override
  String get nuNoDobViewerTitle => 'Chưa biết bé đang ở giai đoạn nào';

  @override
  String nuNoDobBody(String name) {
    return 'Dinh dưỡng theo giai đoạn cần biết tuổi của $name.';
  }

  @override
  String nuNoDobViewer(String name) {
    return 'Bạn chưa được xem ngày sinh của $name, nên app chưa biết bé đang ở giai đoạn nào.';
  }

  @override
  String get nuStageMissing => 'Nội dung này không còn';

  @override
  String get nuStageMissingBody =>
      'Có thể nội dung đã được cập nhật. Quay lại để xem bản mới nhất.';

  @override
  String get nuFooter =>
      'Không thay thế tư vấn của bác sĩ. Thuốc, vi chất dạng uống: theo chỉ định bác sĩ.';

  @override
  String get nuFooterDose => 'Thuốc, vi chất dạng uống: theo chỉ định bác sĩ.';

  @override
  String get nuShareFailed => 'Chưa mở được bảng chia sẻ. Thử lại sau.';

  @override
  String nuStageAge(String age, String range) {
    return '$age · giai đoạn $range';
  }

  @override
  String get nuStagePast => 'Bé đã qua các giai đoạn trong app.';

  @override
  String get nuSeeStages => 'Xem các giai đoạn';

  @override
  String get nuSeeSuggestions => 'Xem gợi ý';

  @override
  String get nuMilkTitle => 'Sữa mỗi ngày';

  @override
  String get nuMilkSub => 'Tham khảo cho bé bú bình';

  @override
  String nuMilkAverage(String name, String ml) {
    return '$name trung bình $ml ml/ngày (7 ngày qua)';
  }

  @override
  String get nuMilkNotEnough =>
      'Chưa đủ cữ bú bình 7 ngày qua để tính trung bình';

  @override
  String nuMilkFeeds(String feeds, String perFeed) {
    return '$feeds cữ, $perFeed ml mỗi cữ';
  }

  @override
  String nuMilkFeedsOnly(String feeds) {
    return '$feeds cữ mỗi ngày';
  }

  @override
  String nuMilkPerFeedOnly(String perFeed) {
    return '$perFeed ml mỗi cữ';
  }

  @override
  String nuMilkBreast(String note) {
    return 'Bú mẹ: $note';
  }

  @override
  String nuMilkBandLabel(String range) {
    return 'Khoảng tham khảo $range ml mỗi ngày';
  }

  @override
  String nuMilkMarkerLabel(String ml) {
    return 'Trung bình $ml ml mỗi ngày';
  }

  @override
  String get nuGrowthTitle => 'Tăng trưởng so với chuẩn WHO';

  @override
  String nuGrowthLast(String date) {
    return 'Lần đo gần nhất $date';
  }

  @override
  String get nuGrowthNone => 'Chưa có lần đo';

  @override
  String get nuWeight => 'Cân nặng';

  @override
  String get nuLength => 'Chiều dài';

  @override
  String get nuTagIn => 'Trong khoảng chuẩn';

  @override
  String get nuTagBelow => 'Thấp hơn khoảng chuẩn';

  @override
  String get nuTagAbove => 'Cao hơn khoảng chuẩn';

  @override
  String get nuNutrientsTitle => 'Cần chú ý ở giai đoạn này';

  @override
  String get nuSampleTitle => 'Một ngày tham khảo';

  @override
  String get nuSlotMorning => 'Sáng';

  @override
  String get nuSlotNoon => 'Trưa';

  @override
  String get nuSlotAfternoon => 'Chiều';

  @override
  String get nuSlotEvening => 'Tối';

  @override
  String get nuSlotNight => 'Đêm';

  @override
  String nuTipsTitle(String name) {
    return 'Gợi ý cho $name';
  }

  @override
  String get nuMilkPageTitle => 'Lượng sữa';

  @override
  String get nuMilkPageIntro =>
      'Tham khảo cho bé bú bình. Mỗi bé mỗi khác: cho bé bú theo dấu hiệu đói, no.';

  @override
  String get nuChartTitle => '14 ngày qua';

  @override
  String nuChartBand(String range) {
    return 'Vùng màu: khoảng tham khảo $range ml';
  }

  @override
  String get nuChartNoBand =>
      'Giai đoạn này không có khoảng tham khảo theo ngày';

  @override
  String nuChartTooltip(String date, String ml) {
    return '$date · $ml ml';
  }

  @override
  String get nuChartEmpty => 'Chưa có cữ bú bình nào trong 14 ngày qua.';

  @override
  String get nuByStageTitle => 'Theo giai đoạn';

  @override
  String nuPerFeed(String range) {
    return '$range ml/cữ';
  }

  @override
  String nuPerDay(String range) {
    return '$range ml/ngày';
  }

  @override
  String nuFeeds(String range) {
    return '$range cữ';
  }

  @override
  String get nuMilkTalkDoctor =>
      'Bé thường xuyên bú nhiều hoặc ít hơn khoảng này: trao đổi với bác sĩ nhi.';

  @override
  String get nuWhy => 'Vì sao cần';

  @override
  String get nuFoodsTitle => 'Thực phẩm gợi ý cho bé';

  @override
  String get nuTip => 'Mẹo';

  @override
  String get nuCampaignTitle => 'Lịch uống tại trạm y tế';

  @override
  String nuNextRound(String days) {
    return 'Đợt tới: $days';
  }

  @override
  String nuGrowthWeightTitle(String name) {
    return 'Cân nặng của $name';
  }

  @override
  String nuGrowthLengthTitle(String name) {
    return 'Chiều dài của $name';
  }

  @override
  String get nuWhoBoy => 'Theo chuẩn WHO · bé trai';

  @override
  String get nuWhoGirl => 'Theo chuẩn WHO · bé gái';

  @override
  String get nuLegendBand => 'Khoảng chuẩn';

  @override
  String get nuWhileWaiting => 'Gợi ý trong lúc chờ khám';

  @override
  String nuRemindDays(int days) {
    return 'Nhắc đo lại sau $days ngày';
  }

  @override
  String nuRemindWeeks(int weeks) {
    return 'Nhắc đo lại sau $weeks tuần';
  }

  @override
  String nuReminded(String date) {
    return 'Đã đặt nhắc · $date';
  }

  @override
  String nuRemindToast(String date) {
    return 'Đã đặt nhắc đo lại ngày $date';
  }

  @override
  String get nuRemeasureWeight => 'Đo lại cân nặng cho bé';

  @override
  String get nuRemeasureLength => 'Đo lại chiều dài cho bé';

  @override
  String get nuExport => 'Xuất báo cáo cho bác sĩ';

  @override
  String get nuGrowthFooter =>
      'Gợi ý chung theo quy tắc của chuyên gia, không thay thế chẩn đoán.';

  @override
  String get nuGrowthNoneTitle => 'Không có gợi ý lúc này';

  @override
  String nuGrowthNoSignal(String name) {
    return 'Các lần đo gần nhất của $name không cần gợi ý nào lúc này.';
  }

  @override
  String get nuBoy => 'bé trai';

  @override
  String get nuGirl => 'bé gái';

  @override
  String get nuReportTitle => 'Tóm tắt tăng trưởng · Child Life';

  @override
  String get nuReportSubject => 'Tóm tắt tăng trưởng';

  @override
  String nuReportAge(String age) {
    return 'Tuổi: $age';
  }

  @override
  String nuReportSex(String sex) {
    return 'Giới tính: $sex';
  }

  @override
  String get nuReportMeasures =>
      'Các lần đo gần nhất (so với chuẩn WHO, P3–P97):';

  @override
  String nuReportMilk(String ml) {
    return 'Sữa bú bình trung bình 7 ngày qua: $ml ml/ngày';
  }

  @override
  String get nuReportMilkNone => 'Sữa bú bình: chưa đủ số liệu 7 ngày qua';

  @override
  String nuReportNote(String banner) {
    return 'Ghi chú từ app: $banner';
  }

  @override
  String nuReportFooter(String date) {
    return 'Số liệu do gia đình ghi trong Child Life, tính đến $date. Không phải chẩn đoán.';
  }

  @override
  String get nuReportBaby => 'bé';

  @override
  String get nuStagesTitle => 'Các giai đoạn';

  @override
  String nuVitaIntro(String ages, String place) {
    return 'Trẻ $ages được uống miễn phí tại $place, theo các đợt dưới đây.';
  }

  @override
  String nuVitaIntroNoPlace(String ages) {
    return 'Trẻ $ages được uống miễn phí theo các đợt dưới đây.';
  }

  @override
  String nuVitaFrom(String name, int months) {
    return '$name sẽ được uống từ $months tháng tuổi.';
  }

  @override
  String nuVitaFirst(String days) {
    return 'Đợt đầu tiên: $days.';
  }

  @override
  String nuRoundTitle(String month) {
    return 'Đợt tháng $month';
  }

  @override
  String nuRoundDaysLine(String days) {
    return 'Ngày $days';
  }

  @override
  String nuRoundTaken(String date) {
    return 'Đã uống $date';
  }

  @override
  String get nuRoundNext => 'Sắp tới';

  @override
  String get nuRoundPast => 'Đã qua, chưa ghi nhận';

  @override
  String get nuRoundTooYoung => 'Chưa tới tuổi';

  @override
  String get nuRoundTooOld => 'Đã qua độ tuổi';

  @override
  String get nuVitaReadOnly => 'Chỉ Cùng nuôi ghi được đợt đã uống.';

  @override
  String get nuVitaFuture => 'Đợt này chưa tới.';

  @override
  String get nuVitaDate => 'Ngày uống';

  @override
  String get nuVitaMark => 'Đánh dấu đã uống';

  @override
  String get nuVitaUnmark => 'Bỏ đánh dấu';

  @override
  String nuVitaMarked(String round) {
    return 'Đã ghi $round';
  }

  @override
  String get nuVitaUnmarked => 'Đã bỏ đánh dấu';

  @override
  String get nuVitaRemind => 'Đặt nhắc';

  @override
  String nuVitaSheetTitle(String name) {
    return 'Nhắc uống $name';
  }

  @override
  String nuVitaSheetBody(String date) {
    return 'Nhắc trước 1 ngày, lúc 8:00 sáng $date. Lịch cụ thể theo thông báo của trạm y tế địa phương.';
  }

  @override
  String nuVitaSheetBodySameDay(String date) {
    return 'Nhắc lúc 8:00 sáng $date. Lịch cụ thể theo thông báo của trạm y tế địa phương.';
  }

  @override
  String get nuVitaRecipient => 'Người nhận';

  @override
  String get nuVitaCalendar => 'Thêm vào lịch điện thoại';

  @override
  String nuVitaReminderTitle(String name, String days) {
    return 'Uống $name tại trạm y tế · $days';
  }

  @override
  String nuVitaIcsSummary(String name) {
    return 'Uống $name cho bé tại trạm y tế';
  }

  @override
  String get nuVitaLocalNote =>
      'Lịch cụ thể theo thông báo của trạm y tế địa phương.';

  @override
  String nuVitaSetToast(String date) {
    return 'Đã đặt nhắc lúc 8:00 ngày $date';
  }

  @override
  String nuAbout(String name) {
    return 'Về $name';
  }

  @override
  String nuMilkPerDayOnly(String range) {
    return 'Tham khảo $range ml mỗi ngày';
  }

  @override
  String get lbSavedCare => 'Chăm bé';

  @override
  String get lbSavedSolids => 'Ăn dặm';

  @override
  String get sdAddFood => 'Thêm';

  @override
  String sdAddFree(String name) {
    return 'Thêm “$name”';
  }

  @override
  String get sdAll => 'Tất cả';

  @override
  String get sdAmount => 'Lượng bé ăn';

  @override
  String sdAmountBowls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chén',
    );
    return '$_temp0';
  }

  @override
  String get sdAmountCustom => 'Tự nhập';

  @override
  String get sdAmountFewSpoons => 'Vài thìa';

  @override
  String get sdAmountFullBowl => '1 chén';

  @override
  String get sdAmountHalfBowl => '½ chén';

  @override
  String get sdAmountInvalid =>
      'Nhập lượng từ 0,1 đến 1000, hoặc bỏ chọn “Tự nhập”.';

  @override
  String sdAmountSpoons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thìa',
    );
    return '$_temp0';
  }

  @override
  String sdAmountValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get sdAnaphylaxis => 'Sơ cứu: Sốc phản vệ';

  @override
  String get sdAskParents => 'Nhờ ba mẹ bật theo dõi ăn dặm';

  @override
  String get sdAskParentsBody =>
      'Khi ba mẹ bật, bạn có thể ghi bữa và xem nhật ký ăn dặm của bé. Thư viện ăn dặm luôn mở cho bạn.';

  @override
  String get sdBenefitHistory => 'Lịch sử bữa ăn và danh sách món đã thử';

  @override
  String get sdBenefitLibrary => 'Thư viện ăn dặm: hướng dẫn, cách bắt đầu';

  @override
  String get sdBenefitLog => 'Ghi bữa, món, lượng chỉ vài chạm';

  @override
  String get sdClear => 'Bác sĩ đã cho ăn lại';

  @override
  String get sdClearedNote =>
      'Bác sĩ đã cho ăn lại món này. App vẫn giữ lịch sử dấu hiệu.';

  @override
  String get sdDate => 'Ngày';

  @override
  String sdDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return '$day · $_temp0';
  }

  @override
  String get sdDelete => 'Xoá bữa';

  @override
  String get sdDeleteTitle => 'Xoá bữa ăn này?';

  @override
  String get sdDeletedToast => 'Đã xoá bữa ăn';

  @override
  String get sdDiary => 'Nhật ký';

  @override
  String get sdDish => 'Món';

  @override
  String get sdDishHint => 'VD: Cháo cà rốt thịt gà';

  @override
  String get sdDoctorNote =>
      'Hỏi bác sĩ của bé khi nào nên bắt đầu ăn dặm và cách phù hợp với bé.';

  @override
  String get sdEarlyNote =>
      'Nếu bác sĩ khuyên bé bắt đầu sớm hơn, hãy làm theo bác sĩ và dùng thư viện để chuẩn bị. Nhật ký ăn dặm mở khi bé đủ 6 tháng.';

  @override
  String get sdEmptyDay => 'Chưa có bữa nào trong ngày này';

  @override
  String get sdEmptyToday => 'Chưa có bữa nào hôm nay';

  @override
  String sdFirstToday(String foods) {
    return 'Lần đầu: $foods';
  }

  @override
  String sdFirstTried(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần',
    );
    return 'Lần đầu $day · $_temp0';
  }

  @override
  String sdFirstTryChip(String food) {
    return '$food · lần đầu';
  }

  @override
  String get sdFirstTryLegend => '✦ Lần đầu bé thử';

  @override
  String sdFoodMeals(int count) {
    return 'Các bữa có món này · $count';
  }

  @override
  String get sdFoodMissing => 'Không tìm thấy món này';

  @override
  String get sdFoodMissingBody => 'Món có thể đã được bỏ khỏi các bữa ăn.';

  @override
  String get sdFoodSearch => 'Tìm món, nguyên liệu…';

  @override
  String get sdFoodSignsNote =>
      'Bé có dấu hiệu sau khi ăn món này. Tạm chưa cho lại và hỏi bác sĩ của bé; app sẽ không gợi ý món này cho đến khi ba mẹ đánh dấu “Bác sĩ đã cho ăn lại”.';

  @override
  String get sdFormatArticle => 'Bài viết';

  @override
  String get sdFormatQuickQa => 'Hỏi nhanh';

  @override
  String get sdFormatStepGuide => 'Từng bước';

  @override
  String sdFromMonths(int months) {
    return 'Thường từ $months tháng';
  }

  @override
  String sdGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get sdGroupDairy => 'Sữa và chế phẩm';

  @override
  String get sdGroupFat => 'Chất béo';

  @override
  String get sdGroupFruit => 'Trái cây';

  @override
  String get sdGroupGrain => 'Tinh bột';

  @override
  String get sdGroupLegume => 'Đậu và hạt';

  @override
  String get sdGroupOther => 'Khác';

  @override
  String get sdGroupProtein => 'Đạm động vật';

  @override
  String get sdGroupVegetable => 'Rau củ';

  @override
  String sdGuideKicker(String format) {
    return 'Hướng dẫn · $format';
  }

  @override
  String get sdGuides => 'Hướng dẫn';

  @override
  String get sdHide => 'Không gợi ý món này';

  @override
  String get sdHistoryEmpty => 'Chưa có bữa nào';

  @override
  String get sdHistoryEmptyBody =>
      'Các bữa đã ghi sẽ hiện ở đây, mới nhất ở trên.';

  @override
  String get sdHistoryTitle => 'Lịch sử bữa ăn';

  @override
  String get sdIngredients => 'Nguyên liệu';

  @override
  String sdLatest(String dish, String time) {
    return 'Gần nhất: $dish · $time';
  }

  @override
  String get sdLibraryEmpty =>
      'Các bài hướng dẫn ăn dặm sẽ hiện ở đây khi được xuất bản.';

  @override
  String get sdLibraryNoResults =>
      'Thử từ khoá khác hoặc bỏ bớt bộ lọc độ tuổi, loại bài.';

  @override
  String get sdLibrarySearch => 'Tìm món, nguyên liệu, hướng dẫn…';

  @override
  String get sdLibrarySub => 'Hướng dẫn ăn dặm theo độ tuổi';

  @override
  String get sdLibraryTitle => 'Thư viện ăn dặm';

  @override
  String get sdLogMeal => 'Ghi bữa';

  @override
  String get sdMealAfternoon => 'Bữa chiều';

  @override
  String get sdMealEvening => 'Bữa tối';

  @override
  String get sdMealMissing => 'Không tìm thấy bữa ăn';

  @override
  String get sdMealMissingBody => 'Bữa ăn có thể đã được xoá.';

  @override
  String get sdMealMorning => 'Bữa sáng';

  @override
  String get sdMealNoon => 'Bữa trưa';

  @override
  String get sdMealSnack => 'Bữa phụ';

  @override
  String get sdMealsTab => 'Bữa ăn';

  @override
  String get sdMethodBlw => 'BLW';

  @override
  String get sdMethodBlwHelp => 'Bé tự cầm thức ăn mềm, cắt thanh vừa tay.';

  @override
  String get sdMethodMixed => 'Kết hợp';

  @override
  String get sdMethodMixedHelp => 'Vừa đút thìa vừa cho bé tự cầm, tuỳ món.';

  @override
  String get sdMethodSpoon => 'Truyền thống';

  @override
  String get sdMethodSpoonHelp => 'Đút thìa, từ nghiền mịn rồi đặc dần.';

  @override
  String get sdMethodTitle => 'Cách cho ăn (không bắt buộc)';

  @override
  String get sdNeedDish => 'Thêm tên món hoặc ít nhất một nguyên liệu.';

  @override
  String get sdNoCatalogue =>
      'Danh mục món đang được cập nhật. Bạn vẫn có thể gõ tên món ở trên (tối đa 3).';

  @override
  String sdNoDobBody(String name) {
    return 'Nhật ký ăn dặm mở khi $name đủ 6 tháng. Thêm ngày sinh để app biết khi nào.';
  }

  @override
  String sdNoDobViewer(String name) {
    return 'Bạn chưa được xem ngày sinh của $name, nên app chưa biết bé đã đủ 6 tháng chưa.';
  }

  @override
  String get sdNotTried => 'Chưa thử';

  @override
  String sdNotYetSoon(String name, String age, String date) {
    return '$name $age, sắp đến lúc ăn dặm. Nhật ký mở khi bé tròn 6 tháng, ngày $date. Trong lúc chờ, xem bé đã có dấu hiệu sẵn sàng chưa.';
  }

  @override
  String get sdNotYetTitle => 'Chưa đến lúc ăn dặm';

  @override
  String sdNotYetYoung(String name, String age, String date) {
    return '$name $age. Sữa mẹ hoặc sữa công thức là đủ cho bé lúc này. Nhật ký ăn dặm mở khi bé tròn 6 tháng, ngày $date.';
  }

  @override
  String get sdNote => 'Ghi chú (không bắt buộc)';

  @override
  String get sdNoteHint => 'Thêm ghi chú…';

  @override
  String sdNutritionRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return 'Ăn dặm hôm nay · $_temp0';
  }

  @override
  String get sdOffBody =>
      'Ba mẹ có thể bật theo dõi ăn dặm trong Chăm sóc › Ăn dặm.';

  @override
  String get sdOffTitle => 'Chưa bật theo dõi ăn dặm';

  @override
  String get sdOpenDiary => 'Mở nhật ký';

  @override
  String get sdReaction => 'Bé ăn thế nào';

  @override
  String get sdReactionLiked => 'Thích';

  @override
  String get sdReactionNeutral => 'Bình thường';

  @override
  String get sdReactionNotYet => 'Chưa hợp';

  @override
  String get sdReadinessKicker => 'Dấu hiệu sẵn sàng';

  @override
  String get sdRecipes => 'Công thức';

  @override
  String sdRecipesFor(String band) {
    return 'Công thức · $band';
  }

  @override
  String get sdRemindMe => 'Nhắc tôi khi bé gần 6 tháng';

  @override
  String sdRemindSet(String date) {
    return 'Đã đặt nhắc · $date';
  }

  @override
  String sdRemindToast(String date) {
    return 'Đã đặt nhắc ngày $date';
  }

  @override
  String sdReminderTitle(String name) {
    return 'Chuẩn bị cho $name ăn dặm';
  }

  @override
  String sdRemoveFood(String food) {
    return 'Bỏ $food';
  }

  @override
  String get sdSave => 'Lưu bữa';

  @override
  String sdSavedToast(String meal) {
    return 'Đã ghi · $meal';
  }

  @override
  String get sdSectionToday => 'Ăn dặm hôm nay';

  @override
  String get sdSectionTodaySub => 'Bữa gần nhất và món mới hôm nay';

  @override
  String get sdSeeAll => 'Xem tất cả';

  @override
  String get sdSettings => 'Cài đặt';

  @override
  String get sdSheetEditTitle => 'Sửa bữa ăn';

  @override
  String get sdSheetTitle => 'Ghi bữa ăn';

  @override
  String get sdShowMore => 'Xem thêm';

  @override
  String get sdShowOnToday => 'Hiện “Ăn dặm hôm nay” trên Hôm nay';

  @override
  String get sdSignsTag => 'Có dấu hiệu';

  @override
  String get sdSlotAfternoon => 'Chiều';

  @override
  String get sdSlotEvening => 'Tối';

  @override
  String get sdSlotMorning => 'Sáng';

  @override
  String get sdSlotNoon => 'Trưa';

  @override
  String get sdSlotSnack => 'Phụ';

  @override
  String sdSlotTime(String slot, String time) {
    return '$slot · $time';
  }

  @override
  String get sdStart => 'Bắt đầu theo dõi';

  @override
  String get sdStartBody =>
      'Ghi nhanh từng bữa, xem lại những món bé đã thử và đọc hướng dẫn từ đội chuyên môn.';

  @override
  String get sdStartTitle => 'Theo dõi ăn dặm';

  @override
  String get sdStartedOn => 'Ngày bắt đầu';

  @override
  String get sdStartedOnAuto => 'Theo bữa đầu tiên';

  @override
  String sdStartedOnAutoDate(String date) {
    return 'Bữa đầu tiên · $date';
  }

  @override
  String get sdStartedOnReset => 'Dùng ngày bữa đầu tiên';

  @override
  String get sdStartedToast => 'Đã bật theo dõi ăn dặm';

  @override
  String get sdStop => 'Dừng theo dõi';

  @override
  String get sdStopBody =>
      'Các bữa đã ghi vẫn được giữ. Ba mẹ có thể bật lại bất cứ lúc nào.';

  @override
  String get sdStopTitle => 'Dừng theo dõi ăn dặm?';

  @override
  String sdSuggestionsTitle(String name) {
    return 'Gợi ý cho $name hôm nay';
  }

  @override
  String get sdSymptomBreathing => 'Khó thở, ho, khò khè';

  @override
  String get sdSymptomDiarrhea => 'Tiêu chảy';

  @override
  String get sdSymptomFussy => 'Quấy khóc bất thường';

  @override
  String get sdSymptomOther => 'Khác';

  @override
  String get sdSymptomRash => 'Nổi mẩn, mề đay';

  @override
  String get sdSymptomSwelling => 'Sưng môi, mặt';

  @override
  String get sdSymptomVomit => 'Nôn';

  @override
  String get sdSymptomsNone => 'Không có';

  @override
  String get sdSymptomsNote =>
      'Các món mới trong bữa này sẽ được đánh dấu “Có dấu hiệu sau khi ăn”. Hỏi bác sĩ của bé nếu bạn còn lo.';

  @override
  String get sdSymptomsQuestion => 'Có dấu hiệu bất thường sau khi ăn?';

  @override
  String get sdSymptomsTitle => 'Dấu hiệu sau khi ăn';

  @override
  String get sdTileFrom6 => 'Từ 6 tháng';

  @override
  String get sdTileSoon => 'Sắp đến lúc ăn dặm';

  @override
  String get sdTileStart => 'Bắt đầu theo dõi';

  @override
  String sdTileToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return 'Hôm nay · $_temp0';
  }

  @override
  String get sdTime => 'Giờ';

  @override
  String get sdToday => 'Hôm nay';

  @override
  String sdTodayCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return 'Ăn dặm hôm nay · $_temp0';
  }

  @override
  String get sdTodayLower => 'hôm nay';

  @override
  String get sdTried => 'Đã thử';

  @override
  String get sdTriedEmpty =>
      'Các món bé đã thử sẽ hiện ở đây sau bữa đầu tiên.';

  @override
  String get sdTriedEmptyTitle => 'Chưa có món nào';

  @override
  String get sdTriedFootnote =>
      'Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị dinh dưỡng.';

  @override
  String sdTriedReaction(String reaction) {
    return 'Đã thử · $reaction';
  }

  @override
  String get sdTriedTab => 'Món đã thử';

  @override
  String sdTriedTitle(int count) {
    return 'Món đã thử · $count';
  }

  @override
  String get sdUnclear => 'Bỏ đánh dấu “Bác sĩ đã cho ăn lại”';

  @override
  String get sdUnhide => 'Gợi ý lại món này';

  @override
  String get sdUnitBowl => 'chén';

  @override
  String get sdUnitSpoon => 'thìa';

  @override
  String sdUpdated(String date) {
    return 'cập nhật $date';
  }

  @override
  String sdUrgent(String number) {
    return 'Gọi $number ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi.';
  }

  @override
  String get sdViewOnly => 'Bữa này do người khác ghi: bạn chỉ xem được.';

  @override
  String get sdYesterday => 'Hôm qua';

  @override
  String get sdPhoto => 'Ảnh bữa ăn';

  @override
  String get sdPhotoAdd => 'Thêm ảnh bữa ăn';

  @override
  String get sdPhotoReplace => 'Đổi ảnh';

  @override
  String get sdPhotoRemove => 'Bỏ ảnh';

  @override
  String get sdPhotoPrivate =>
      'Chỉ những người chăm bé trong gia đình xem được ảnh này.';

  @override
  String get sdPhotoFailed =>
      'Chưa tải được ảnh. Bữa ăn vẫn lưu được; thử thêm ảnh lại sau nhé.';

  @override
  String get sdPhotoOffline =>
      'Cần có mạng để thêm ảnh. Bữa ăn vẫn lưu được khi không có mạng.';

  @override
  String get sdHistoryFilter => 'Ăn dặm';

  @override
  String get sdHistoryWhat => 'bữa ăn dặm';

  @override
  String sdHistoryOnDay(String date) {
    return 'Ăn dặm ngày $date';
  }

  @override
  String get sdHistoryMeals => 'Số bữa';

  @override
  String get sdHistoryNewFoods => 'Món mới';

  @override
  String sdMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return '$_temp0';
  }

  @override
  String sdFoodsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count món',
    );
    return '$_temp0';
  }

  @override
  String get sdHistoryLink => 'Nhật ký ăn dặm';

  @override
  String get sdHistoryLinkHint => 'Món đã thử, lịch sử bữa ăn và gợi ý cho bé';

  @override
  String get sdStatsTitle => 'Bữa ăn dặm';

  @override
  String sdStatsHint(int days) {
    return '$days ngày gần đây · chỉ để tham khảo';
  }

  @override
  String get sdStatsTodayHint => 'Hôm nay · chỉ để tham khảo';

  @override
  String sdStatsAvg(String value) {
    return 'TB $value bữa/ngày';
  }

  @override
  String sdStatsDayTip(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bữa',
    );
    return '$day: $_temp0';
  }

  @override
  String get sdStatsMealsToday => 'Bữa hôm nay';

  @override
  String get sdStatsPerDay => 'Bữa mỗi ngày (TB)';

  @override
  String get sdStatsNewThisWeek => 'Món mới tuần này';

  @override
  String get sdStatsNewPerWeek => 'Món mới mỗi tuần';

  @override
  String sdStatsWeekOf(String date) {
    return 'Tuần từ $date';
  }

  @override
  String get sdStatsNote =>
      'Đây là ghi chép của gia đình, không phải mục tiêu số bữa hay số món.';

  @override
  String sdRecipeMeta(int minutes) {
    return 'Công thức · $minutes phút';
  }

  @override
  String sdForBaby(String name) {
    return 'Dành cho $name';
  }

  @override
  String get sdRecipesNone => 'Chưa có công thức hợp bộ lọc này.';

  @override
  String sdRecipesWith(String foods) {
    return 'Công thức có $foods';
  }

  @override
  String get sdRecipesWithNone =>
      'Chưa có công thức hợp tuổi và cách cho ăn của bé có món này. Xem các công thức khác trong thư viện.';

  @override
  String get sdRecipeMissing => 'Không tìm thấy công thức';

  @override
  String get sdRecipeMissingBody =>
      'Công thức có thể đã được gỡ hoặc chưa tải về máy.';

  @override
  String get sdTextureSmooth => 'Nghiền mịn';

  @override
  String get sdTextureMashed => 'Nghiền lợn cợn';

  @override
  String get sdTextureSoftPieces => 'Cắt nhỏ, mềm';

  @override
  String get sdTextureFinger => 'Cầm tay';

  @override
  String get sdTextureFamily => 'Ăn cùng gia đình';

  @override
  String sdServings(int count) {
    return '$count phần ăn';
  }

  @override
  String sdPrepCook(int prep, int cook) {
    return 'Sơ chế $prep phút · nấu $cook phút';
  }

  @override
  String get sdSteps => 'Cách làm';

  @override
  String get sdStorage => 'Bảo quản';

  @override
  String get sdTip => 'Mẹo';

  @override
  String get sdNotTriedMark => '✦ Bé chưa thử';

  @override
  String get sdSignsMark => '⚠ Có dấu hiệu';

  @override
  String sdContains(String list) {
    return 'Có $list';
  }

  @override
  String get sdAllergenEgg => 'trứng';

  @override
  String get sdAllergenPeanut => 'đậu phộng';

  @override
  String get sdAllergenMilk => 'sữa bò';

  @override
  String get sdAllergenWheat => 'lúa mì';

  @override
  String get sdAllergenSoy => 'đậu nành';

  @override
  String get sdAllergenFish => 'cá';

  @override
  String get sdAllergenShellfish => 'tôm, cua, sò';

  @override
  String get sdAllergenSesame => 'vừng (mè)';

  @override
  String get sdAllergenTreeNut => 'các loại hạt';

  @override
  String sdAgeNotice(int from, String name, String age) {
    return 'Công thức cho bé từ $from tháng. $name mới $age: chọn công thức hợp tuổi hoặc hỏi bác sĩ của bé.';
  }

  @override
  String get sdLogRecipe => 'Ghi vào nhật ký';

  @override
  String get sdIngUnitTbsp => 'thìa canh';

  @override
  String get sdIngUnitTsp => 'thìa cà phê';

  @override
  String get sdIngUnitBowl => 'chén';

  @override
  String get sdIngUnitPiece => 'miếng';

  @override
  String sdIngBowls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chén',
    );
    return '$_temp0';
  }

  @override
  String sdIngPieces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miếng',
    );
    return '$_temp0';
  }

  @override
  String get sdSuggestLater => 'Để sau';

  @override
  String get sdSuggestHideWhich => 'Không gợi ý món nào?';

  @override
  String sdSuggestHidden(String food) {
    return 'Sẽ không gợi ý $food nữa';
  }

  @override
  String sdSuggestSnoozedFood(String food) {
    return 'Đã ẩn $food khỏi gợi ý trên máy này trong 30 ngày';
  }

  @override
  String get sdSuggestSnoozed => 'Sẽ gợi ý lại sau 3 ngày';

  @override
  String get sdActReadReactions => 'Đọc: Nhận biết phản ứng';

  @override
  String get sdActRecipes => 'Xem công thức';

  @override
  String get sdActIdeas => 'Xem gợi ý';

  @override
  String get sdActGuide => 'Đọc hướng dẫn';

  @override
  String get sdOr => 'hoặc';

  @override
  String sdIronMark(String food) {
    return '$food (giàu sắt)';
  }

  @override
  String get sdTryEgg => 'trứng chín kỹ';

  @override
  String get sdTryPeanut => 'bơ đậu phộng pha loãng (không cho cả hạt)';

  @override
  String get sdTryMilk => 'sữa chua hoặc sữa bò nấu trong món';

  @override
  String get sdTryWheat => 'lúa mì (bánh mì, mì nấu mềm)';

  @override
  String get sdTryFish => 'cá chín kỹ, gỡ hết xương';

  @override
  String get sdTrySoy => 'đậu phụ hoặc sữa đậu nành nấu trong món';

  @override
  String get sdTrySesame => 'vừng (mè) xay mịn trộn vào món';

  @override
  String get sdTryShellfish => 'tôm hoặc cua chín kỹ, băm nhỏ';

  @override
  String get sdTryTreeNut =>
      'bơ hạt (hạnh nhân, điều) pha loãng, không cho cả hạt';

  @override
  String sdS1Title(String date, String foods) {
    return 'Theo dõi sau dấu hiệu hôm $date ($foods). Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo.';
  }

  @override
  String sdS1TitlePlain(String date) {
    return 'Theo dõi sau dấu hiệu hôm $date. Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo.';
  }

  @override
  String sdS1Why(String date) {
    return 'Vì bữa hôm $date có ghi dấu hiệu sau khi ăn.';
  }

  @override
  String sdS2Title(String name, String foods) {
    return 'Món tiếp theo cho $name: $foods.';
  }

  @override
  String sdS2Why(String name, int count) {
    return 'Vì $name mới thử $count món: bắt đầu từ rau củ, tinh bột và một món giàu sắt, mỗi lần một món mới.';
  }

  @override
  String sdS3Title(String allergen) {
    return 'Đã đến lúc thử $allergen: buổi sáng, ở nhà, một lượng nhỏ.';
  }

  @override
  String sdS3Why(String name, int count, int days) {
    return 'Vì $name đã quen $count món và ăn dặm được $days ngày: các món thường gây dị ứng nên cho làm quen từng món một, cách nhau vài ngày.';
  }

  @override
  String sdS4Title(String name, String allergen) {
    return 'Cho $name ăn lại $allergen tuần này để duy trì.';
  }

  @override
  String sdS4Why(String allergen, String date) {
    return 'Vì lần gần nhất bé ăn $allergen là $date: món đã quen nên được ăn đều đặn.';
  }

  @override
  String sdS5Title(String foods) {
    return 'Hôm nay thêm một món giàu sắt: $foods.';
  }

  @override
  String sdS5Why(String name) {
    return 'Vì 2 ngày qua các bữa của $name chưa có món giàu sắt; từ 6 tháng bé cần sắt từ thức ăn mỗi ngày.';
  }

  @override
  String sdS6Title(String foods) {
    return 'Món mới tiếp theo: $foods.';
  }

  @override
  String sdS6Why(String name, String group, int count) {
    return 'Vì $name chưa thử món mới 2 ngày; nhóm $group bé mới thử $count món.';
  }

  @override
  String sdS7Title(String food, String liked, String name) {
    return 'Thử lại $food theo cách khác: nghiền mịn hơn hoặc trộn với $liked $name thích.';
  }

  @override
  String sdS7TitlePlain(String food) {
    return 'Thử lại $food theo cách khác: nghiền mịn hơn hoặc đổi cách nấu.';
  }

  @override
  String sdS7Why(String name, String food, int count) {
    return 'Vì lần gần nhất $name chưa hợp $food (đã thử $count lần). Bé có thể cần 8–15 lần mới quen một món.';
  }

  @override
  String sdS8Title(String name, String group) {
    return 'Tuần này $name chưa ăn $group nào.';
  }

  @override
  String sdS8Why(String group, String date) {
    return 'Vì lần gần nhất bé ăn $group là $date; đổi món giúp bé quen nhiều vị.';
  }

  @override
  String sdS9Title(String name, int months, String texture) {
    return '$name $months tháng: $texture.';
  }

  @override
  String sdS9Why(String name, String stage) {
    return 'Vì $name vừa sang giai đoạn $stage trong Dinh dưỡng; thức ăn thô dần theo từng giai đoạn.';
  }

  @override
  String sdIdeasTitle(String group) {
    return 'Gợi ý: $group';
  }

  @override
  String get sdIdeasHint => 'Chạm một món để ghi bữa.';

  @override
  String sdMadeCount(int count) {
    return 'Nhà mình đã làm $count lần';
  }

  @override
  String sdMadeLast(String date) {
    return 'gần nhất $date';
  }

  @override
  String sdMadeLiked(String name) {
    return '$name thích';
  }

  @override
  String sdMadeNeutral(String name) {
    return '$name ăn bình thường';
  }

  @override
  String sdMadeNotYet(String name) {
    return '$name chưa hợp';
  }

  @override
  String get sdMadeTitle => 'Các lần đã làm';

  @override
  String sdFromRecipe(String name) {
    return 'Theo công thức: $name';
  }

  @override
  String get sdSaveAsRecipe => 'Lưu thành công thức';

  @override
  String get sdFamily => 'Nhà mình';

  @override
  String get sdFamilyRecipes => 'Công thức nhà mình';

  @override
  String get sdFamilyAdd => 'Thêm công thức nhà mình';

  @override
  String get sdFamilyAddShort => 'Thêm';

  @override
  String get sdFamilyAddBody =>
      'Lưu món nhà hay nấu cho bé, lần sau ghi bữa chỉ một chạm.';

  @override
  String sdFamilyAll(int count) {
    return 'Xem tất cả · $count';
  }

  @override
  String sdFamilyIngredientsCount(int count) {
    return '$count nguyên liệu';
  }

  @override
  String sdFamilyMade(int count) {
    return 'đã làm $count lần';
  }

  @override
  String sdFamilyAddedBy(String who) {
    return '$who thêm';
  }

  @override
  String get sdFamilyEditTitle => 'Sửa công thức';

  @override
  String get sdFamilyName => 'Tên món';

  @override
  String get sdFamilyNameHint => 'VD: Cháo bí đỏ thịt bằm';

  @override
  String get sdFamilyPhoto => 'Ảnh món (không bắt buộc)';

  @override
  String get sdFamilyPhotoAdd => 'Thêm ảnh món';

  @override
  String get sdFamilyQtyHint => 'Lượng';

  @override
  String get sdFamilyUnit => 'Đơn vị';

  @override
  String get sdFamilyUnitNone => 'Không ghi';

  @override
  String get sdFamilyQtyInvalid => 'Nhập lượng từ 0,1 đến 2000, hoặc để trống.';

  @override
  String get sdFamilyIngredientsHint =>
      'Chọn trong danh mục hoặc gõ tên khác; lượng không bắt buộc.';

  @override
  String sdFamilyStepHint(int n) {
    return 'Bước $n';
  }

  @override
  String get sdFamilyAddStep => 'Thêm bước';

  @override
  String sdFamilyStepUp(int n) {
    return 'Đưa bước $n lên';
  }

  @override
  String sdFamilyStepDown(int n) {
    return 'Đưa bước $n xuống';
  }

  @override
  String sdFamilyStepRemove(int n) {
    return 'Bỏ bước $n';
  }

  @override
  String get sdFamilyNote => 'Ghi chú';

  @override
  String get sdFamilyNoteHint => 'Mẹo, cách bảo quản… (không bắt buộc)';

  @override
  String get sdFamilySave => 'Lưu công thức';

  @override
  String get sdFamilyNeedTitle => 'Thêm tên món.';

  @override
  String get sdFamilyNeedIngredient => 'Thêm ít nhất một nguyên liệu.';

  @override
  String sdFamilySavedToast(String title) {
    return 'Đã lưu công thức · $title';
  }

  @override
  String get sdFamilyDelete => 'Xoá';

  @override
  String get sdFamilyDeleteTitle => 'Xoá công thức này?';

  @override
  String get sdFamilyDeleteBody =>
      'Công thức được giữ 30 ngày trong “Đã xoá gần đây”. Các bữa đã ghi theo công thức vẫn còn.';

  @override
  String get sdFamilyDeletedToast => 'Đã xoá công thức';

  @override
  String get sdFamilyMissingBody => 'Công thức có thể đã được xoá.';

  @override
  String get sdFamilyViewOnly =>
      'Công thức này do người khác thêm: bạn chỉ xem được.';

  @override
  String get sdFamilyChips => 'Món nhà mình';

  @override
  String get sdSavedByMe => 'Bạn đã lưu';

  @override
  String get sdNudgeTitle => 'Lưu ý cho bé';

  @override
  String get sdNudgeHoney =>
      'Mật ong chỉ cho bé từ 12 tháng tuổi: trước đó có nguy cơ ngộ độc.';

  @override
  String sdNudgeTooYoung(String food, int months) {
    return '$food thường cho bé từ $months tháng.';
  }

  @override
  String sdNudgeSeasoning(String list) {
    return 'Có thêm gia vị ($list). Thức ăn của bé không cần muối, đường hay nước mắm.';
  }

  @override
  String sdNudgeChoking(String food, String note) {
    return '$food: $note';
  }

  @override
  String get sdNudgeFooter =>
      'Công thức của nhà mình: app chỉ lưu ý, không chặn.';

  @override
  String get sdNoCatalogueFree =>
      'Danh mục món đang được cập nhật. Bạn vẫn có thể gõ tên nguyên liệu ở trên.';

  @override
  String get sdCalendarTab => 'Lịch';

  @override
  String get sdCalendarPrev => 'Tháng trước';

  @override
  String get sdCalendarNext => 'Tháng sau';

  @override
  String get sdCalendarHint => 'Chạm một ngày để xem các bữa.';

  @override
  String get sdHistorySearch => 'Tìm món, nguyên liệu, công thức…';

  @override
  String sdHistorySearchCount(int count, String query) {
    return '$count bữa có “$query”';
  }

  @override
  String sdHistorySearchNone(String query) {
    return 'Chưa có bữa nào có “$query”.';
  }

  @override
  String sdFoodDays(int count) {
    return 'Những lần bé đã ăn · $count';
  }

  @override
  String get lbContents => 'Trong bài này';

  @override
  String get lbBackToTop => 'Lên đầu';

  @override
  String get lbTakeaways => 'Tóm tắt nhanh';

  @override
  String get lbMyth => 'Hiểu lầm';

  @override
  String get lbMythWhy => 'Vì sao';

  @override
  String get lbMythInstead => 'Nên làm';

  @override
  String get lbUpNext => 'Bài tiếp theo';

  @override
  String get lbUrgentFirstAid => 'Xem hướng dẫn Sơ cứu';

  @override
  String get nuVitaAbroad =>
      'Lịch uống vitamin A theo chương trình của Việt Nam; ở nơi bạn sống, hãy hỏi bác sĩ của bé.';

  @override
  String asReadSnapshot(String time) {
    return 'Dữ liệu đến $time';
  }

  @override
  String get asReadDetails => 'Xem chi tiết';

  @override
  String get asOpenSolids => 'Mở Ăn dặm';

  @override
  String get asOpenFirstAid => 'Mở Sơ cứu';

  @override
  String get pv2Title => 'Hôm nay của nhà mình';

  @override
  String get pv2Open => 'Xem chi tiết';

  @override
  String get pv2Context => 'Hôm nay bạn rảnh cỡ nào?';

  @override
  String get pv2Usual => 'Như mọi ngày';

  @override
  String get pv2FewMinutes => 'Chỉ vài phút';

  @override
  String get pv2Busy => 'Đang bận';

  @override
  String get pv2Temporary => 'Ngày mai tự trở về \"Như mọi ngày\".';

  @override
  String get pv2Focus => 'Một điều muốn ưu tiên tuần này';

  @override
  String get pv2Play => 'Có một lúc chơi cùng con';

  @override
  String get pv2Routine => 'Hiểu nhịp sinh hoạt';

  @override
  String get pv2NoFocus => 'Chưa chọn';

  @override
  String get pv2Unusual => 'Hôm nay bé không như mọi ngày';

  @override
  String get pv2UnusualHint =>
      'Ví dụ bé ốm, đi xa hay nhà có khách. Hôm nay tạm ẩn nhịp bú, ngủ thường gặp cho cả nhà; nhắc việc vẫn giữ nguyên.';

  @override
  String get pv2Next => 'Gợi ý cho hôm nay';

  @override
  String get pv2BecauseNeed => 'Theo điều gia đình vừa ghi nhận hôm nay';

  @override
  String get pv2BecauseFocus => 'Theo ưu tiên tuần này của bạn';

  @override
  String get pv2BecauseInterest => 'Theo tuổi của bé và điều bạn quan tâm';

  @override
  String get pv2BecauseAge => 'Theo tuổi của bé';

  @override
  String get pv2BecauseHelpful => 'Nhà mình từng thấy cách này có ích';

  @override
  String get pv2Minutes => 'phút';

  @override
  String get pv2OpenActivity => 'Xem cách làm';

  @override
  String get pv2Controls => 'Tuỳ chọn khác';

  @override
  String get pv2Save => 'Lưu lại';

  @override
  String get pv2Hide => 'Ẩn gợi ý này';

  @override
  String get pv2Snooze => 'Để sau 3 ngày';

  @override
  String get pv2WorkSnooze => 'Để sau · ẩn đến hết hôm nay';

  @override
  String get pv2Dislike => 'Không hợp với nhà mình';

  @override
  String get pv2Known => 'Tôi đã biết rồi';

  @override
  String get pv2Exclude => 'Không phù hợp với bé · áp dụng cho cả nhà';

  @override
  String get pv2Restore => 'Khôi phục giao dịch';

  @override
  String get pv2Intend => 'Mình sẽ thử';

  @override
  String get pv2Tried => 'Thử rồi';

  @override
  String get pv2Helpful => 'Có ích';

  @override
  String get pv2Unsure => 'Chưa rõ';

  @override
  String get pv2NoAnswer =>
      'Bạn có thể trả lời sau. Một lần thử chưa nói lên tác dụng.';

  @override
  String get pv2Patterns => 'Nhịp riêng từ nhật ký';

  @override
  String get pv2FeedPattern => 'Khoảng cách giữa các lần ghi bú';

  @override
  String get pv2SleepPattern => 'Độ dài các giấc ngày đã ghi';

  @override
  String get pv2PatternHint =>
      'Khoảng thường gặp trong nhật ký 14 ngày; không phải lịch phải theo.';

  @override
  String get pv2Insufficient =>
      'Chưa có đủ dữ liệu ổn định để hiển thị nhịp. Bạn vẫn có thể dùng các gợi ý khác.';

  @override
  String get pv2Samples => 'mẫu ghi';

  @override
  String get pv2Days => 'ngày có mẫu';

  @override
  String get pv2Updated => 'Dữ liệu gần nhất';

  @override
  String get pv2Notes => 'Sổ tay nhà mình';

  @override
  String get pv2AddNote => 'Thêm điều muốn ứng dụng nhớ';

  @override
  String get pv2NoteText => 'Điều nhà mình muốn ghi nhớ';

  @override
  String get pv2Shared => 'Chia sẻ với người được xem chăm sóc bé';

  @override
  String get pv2Personal => 'Chỉ riêng bạn';

  @override
  String get pv2Category => 'Loại ghi chú';

  @override
  String get pv2Sleep => 'Ngủ';

  @override
  String get pv2Soothing => 'Dỗ bé';

  @override
  String get pv2Feeding => 'Ăn, bú';

  @override
  String get pv2Avoid => 'Điều cần tránh';

  @override
  String get pv2Carer => 'Người chăm';

  @override
  String get pv2Other => 'Khác';

  @override
  String get pv2Expiry => 'Giữ ghi chú trong';

  @override
  String get pv2OneDay => 'Hôm nay';

  @override
  String get pv2SevenDays => '7 ngày';

  @override
  String get pv2ThirtyDays => '30 ngày';

  @override
  String get pv2NoExpiry => 'Đến khi xoá';

  @override
  String get pv2ConfirmNote => 'Xác nhận lưu ghi chú';

  @override
  String get pv2Edit => 'Sửa';

  @override
  String get pv2Delete => 'Xoá';

  @override
  String get pv2Cancel => 'Để sau';

  @override
  String get pv2NoteHint =>
      'Ứng dụng dùng ghi chú đã xác nhận để chọn gợi ý. Ghi chú tự do không phải chỉ định y tế.';

  @override
  String get pv2Work => 'Việc cần làm hôm nay';

  @override
  String get pv2WorkHint =>
      'Việc gia đình đã hẹn. Nhận việc để cả nhà biết ai đang làm.';

  @override
  String get pv2NoWork => 'Chưa có nhắc việc đang chờ.';

  @override
  String get pv2Accept => 'Tôi nhận việc này';

  @override
  String get pv2Release => 'Trả lại việc';

  @override
  String get pv2Complete => 'Đánh dấu hoàn tất';

  @override
  String get pv2Unclaimed => 'Chưa có người nhận';

  @override
  String get pv2Accepted => 'Đã có người nhận';

  @override
  String get pv2Acknowledge => 'Tôi đã nhận bàn giao';

  @override
  String get pv2Acknowledged => 'Bạn đã nhận bàn giao lúc';

  @override
  String get pv2LastRecords => 'Các lần ghi gần nhất';

  @override
  String get pv2Weekly => 'Tuần này điều gì hữu ích?';

  @override
  String get pv2WeekTried => 'hoạt động đã xác nhận thử';

  @override
  String get pv2WeekHelpful => 'hoạt động thấy có ích';

  @override
  String get pv2WeekHint =>
      'Theo phản hồi của bạn trong 7 ngày qua; không kết luận tác dụng từ số liệu trước và sau.';

  @override
  String get pv2History => 'Lịch sử sử dụng';

  @override
  String get pv2Saved => 'Đã lưu';

  @override
  String get pv2Digest => 'Gợi ý mỗi ngày trên thiết bị này';

  @override
  String get pv2DigestHint =>
      'Tự chọn bật. Mỗi ngày tối đa một gợi ý mới, trong giờ cho phép. Chọn giờ trong cài đặt cá nhân hoá.';

  @override
  String get pv2DigestTitle => 'Một việc vừa sức cho hôm nay';

  @override
  String get pv2DigestBody => 'Mở để xem gợi ý mới và việc gia đình đã đặt.';

  @override
  String get pv2Loading => 'Đang chuẩn bị gợi ý…';

  @override
  String get pv2Unavailable =>
      'Chưa tải được thông tin mới. Kết nối mạng rồi thử lại nhé.';

  @override
  String get pv2Retry => 'Thử lại';

  @override
  String get pv2Refresh => 'Cập nhật';

  @override
  String get pv2Conflict =>
      'Thông tin đã thay đổi trên thiết bị khác. Đã tải lại để bạn xem.';

  @override
  String get pv2ChangeSaved => 'Đã cập nhật lựa chọn của bạn';

  @override
  String get pv2PatternReminder => 'Đặt nhắc theo khoảng này';

  @override
  String get pv2AvoidActivity =>
      'Không gợi ý hoạt động này cho bé (không bắt buộc)';

  @override
  String get pv2HandoverChanged =>
      'Có cập nhật sau lần bạn nhận bàn giao. Vui lòng xem lại các việc và ghi chú mới.';

  @override
  String get pv2SleepRecent => 'Giấc ngủ trên các ngày ghi đủ gần đây';

  @override
  String get pv2SleepBaseline => 'Giai đoạn tham chiếu trước đó';

  @override
  String get pv2ExpiredNote => 'Đã hết hạn · không dùng để cá nhân hoá';

  @override
  String get p48Language => 'Ngôn ngữ thành phẩm';

  @override
  String get p48Details => 'Thông tin khoảnh khắc';

  @override
  String get p48Copy => 'Nội dung thành phẩm';

  @override
  String get p48Format => 'Tỷ lệ thành phẩm';

  @override
  String get p48ReducedMotion => 'Chuyển động nhẹ';

  @override
  String get p48CropHint =>
      'Chọn từng cảnh để căn ảnh. Cảnh kết có thể dùng lại ảnh bạn đã chọn.';

  @override
  String get p48Crop => 'Căn ảnh';

  @override
  String get p48Horizontal => 'Trái / phải';

  @override
  String get p48Vertical => 'Trên / dưới';

  @override
  String get p48Zoom => 'Thu phóng';

  @override
  String get p48TooLong =>
      'Có nội dung chưa vừa khung. Hãy rút ngắn trước khi xuất.';

  @override
  String get p48Invalid =>
      'Kiểm tra thông tin bắt buộc và nội dung trong ngoặc nhọn.';

  @override
  String get p48Reset => 'Dùng lại nội dung mẫu';

  @override
  String get p48MotionPreview => 'Xem chuyển động 4 giây';

  @override
  String get p48ChangePhotos => 'Đổi ảnh đã chọn';

  @override
  String get p48PreviewFailed =>
      'Chưa tải được đủ ảnh để xem trước. Hãy thử lại.';

  @override
  String get p48WholePhoto => 'Giữ trọn ảnh';

  @override
  String get p48FillFrame => 'Lấp đầy khung';

  @override
  String p48PhotoSlot(int n) {
    return 'Ảnh $n';
  }

  @override
  String get p48UseSuggestions => 'Dùng ghi chú gợi ý';

  @override
  String get p48SuggestionsHint =>
      'Chỉ dùng gợi ý nếu phù hợp với bé; bạn có thể sửa từng ghi chú.';

  @override
  String get historyLoadEarlier => 'Tải kỷ niệm cũ hơn';

  @override
  String get historyLoadFailed => 'Chưa tải được lịch sử. Thử lại';

  @override
  String get historyEnd => 'Đã xem hết lịch sử';

  @override
  String get engTitle => 'Gợi ý thông minh';

  @override
  String get engPending => 'Ảnh đang chờ chọn lưu';

  @override
  String get engMilestone => 'Làm video kỷ niệm';

  @override
  String get engWeekly => 'Nhìn lại tuần qua';

  @override
  String get engFamily => 'Cập nhật gia đình';

  @override
  String get engLumi => 'Gợi ý mỗi ngày';

  @override
  String get engOffline =>
      'Chưa kiểm tra được gợi ý. Bạn vẫn có thể tiếp tục dùng ứng dụng.';

  @override
  String get engRetry => 'Thử lại';

  @override
  String get engBackfill => 'Nhìn lại những khoảnh khắc đã có';

  @override
  String get engBackfillBody =>
      'Bạn có thể làm video cho mốc đã qua từ ảnh đã lưu.';

  @override
  String get engChooseTemplate => 'Chọn mẫu video';

  @override
  String get engOpen => 'Xem gợi ý';

  @override
  String get engLater => 'Để sau';

  @override
  String get engDismiss => 'Bỏ qua gợi ý';

  @override
  String get engExpired => 'Gợi ý này đã hết hạn hoặc không còn khả dụng.';

  @override
  String get engSettingsHint =>
      'Gợi ý đúng lúc, xem khi tiện. Không ảnh hưởng nhắc việc bạn đặt.';

  @override
  String get engConsent => 'Nhận gợi ý thông minh';

  @override
  String get engResume => 'Tiếp tục nhận gợi ý sau thời gian nghỉ';

  @override
  String get engPaused =>
      'Gợi ý chủ động đang tạm nghỉ. Bạn có thể chủ động tiếp tục sau ít nhất 14 ngày.';

  @override
  String get pv2HomeKicker => 'GỢI Ý HÔM NAY CHO BÉ';

  @override
  String get pv2More => 'Xem thêm';

  @override
  String get pv2TimeToday => 'Thời gian hôm nay';

  @override
  String get pv2UsualHint => 'Tối đa 3 gợi ý, dài ngắn tuỳ việc.';

  @override
  String get pv2FewMinutesHint => 'Chỉ gợi ý việc từ 5 phút trở xuống.';

  @override
  String get pv2BusyHint => 'Một việc ngắn duy nhất, hôm nay không nhắc gợi ý.';

  @override
  String get pv2Adjust => 'Điều chỉnh gợi ý';

  @override
  String get pv2FocusToggle => 'Tuần này ưu tiên chơi cùng con';

  @override
  String get pv2FocusHint => 'Gợi ý chơi được ưu tiên đến hết tuần này.';

  @override
  String get pv2DoneToday => 'Hôm nay bạn đã';

  @override
  String get pv2DoneTodayEmpty => 'Gợi ý bạn lưu hoặc sẽ thử hiện ở đây.';

  @override
  String get pv2NoIdeas =>
      'Hôm nay chưa có gợi ý mới phù hợp. Bạn có thể xem lại những việc đã lưu.';

  @override
  String get pv2HowWasIt => 'Con thế nào?';

  @override
  String get pv2HowWasItTitle => 'Thử rồi, con thế nào?';

  @override
  String get pv2AlreadySaved => 'Gợi ý này đã nằm trong mục Đã lưu.';

  @override
  String get pv2Undo => 'Hoàn tác';

  @override
  String get pv2StatusSaved => 'Đã lưu';

  @override
  String get pv2StatusHidden => 'Đã ẩn';

  @override
  String get pv2StatusExcluded => 'Đã loại cho cả nhà';

  @override
  String pv2StatusIntend(String when) {
    return 'Sẽ thử · $when';
  }

  @override
  String pv2StatusTried(String when) {
    return 'Đã thử · $when';
  }

  @override
  String pv2StatusSnoozed(String when) {
    return 'Để sau đến $when';
  }

  @override
  String get pv2ToastSaved =>
      'Đã lưu. Xem lại trong \"Đã lưu, đã thử và đã ẩn\".';

  @override
  String get pv2ToastIntend => 'Đã ghi. Thử xong, chạm “Con thế nào?”.';

  @override
  String get pv2ToastTried =>
      'Đã ghi bạn đã thử. Gợi ý này chuyển xuống \"Hôm nay bạn đã\".';

  @override
  String get pv2ToastOutcome => 'Cảm ơn bạn, đã ghi lại.';

  @override
  String get pv2ToastHidden => 'Đã ẩn gợi ý này.';

  @override
  String get pv2ToastSnoozed => 'Sẽ gợi ý lại sau 3 ngày.';

  @override
  String get pv2ToastWorkSnoozed =>
      'Đã ẩn đến hết hôm nay. Việc vẫn còn trong Nhắc việc.';

  @override
  String get pv2ToastExcluded => 'Đã loại gợi ý này cho cả nhà.';

  @override
  String get pv2ToastRestored => 'Đã khôi phục gợi ý.';

  @override
  String pv2ToastContext(String choice) {
    return 'Đã chọn \"$choice\". Gợi ý đã cập nhật.';
  }

  @override
  String get pv2ToastFocusOn => 'Tuần này sẽ ưu tiên gợi ý chơi cùng con.';

  @override
  String get pv2ToastFocusOff => 'Đã bỏ ưu tiên tuần này.';

  @override
  String get pv2ToastUnusualOn => 'Đã ghi hôm nay bé không như mọi ngày.';

  @override
  String get pv2ToastUnusualOff => 'Đã bật lại nhịp thường gặp.';

  @override
  String get pv2ToastAcknowledged => 'Đã ghi bạn nhận bàn giao.';

  @override
  String pv2WorkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc đang chờ',
    );
    return '$_temp0';
  }

  @override
  String pv2NotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      zero: 'Chưa có ghi chú',
    );
    return '$_temp0';
  }

  @override
  String get pv2PatternsPaused => 'Đã tạm ẩn hôm nay';

  @override
  String get pv2PatternsNone => 'Chưa đủ dữ liệu';

  @override
  String pv2WeekLine(int tried, int helpful) {
    return 'Tuần này: $tried đã thử · $helpful có ích';
  }

  @override
  String get pv2AcknowledgedShort => 'Đã nhận bàn giao';

  @override
  String get pv2HiddenNow => 'Đang ẩn';

  @override
  String get pv2SavedNow => 'Đã lưu';

  @override
  String get pv2TriedBefore => 'Đã thử';

  @override
  String get pv2Reminders => 'Nhắc việc đang chờ';

  @override
  String get pv2ChipHelpful => 'Có ích';

  @override
  String get pv2RemindAsk => 'Nhắc mình thử lúc nào?';

  @override
  String pv2RemindTonight(String time) {
    return 'Tối nay $time';
  }

  @override
  String get pv2RemindIn1h => 'Sau 1 giờ';

  @override
  String pv2RemindTomorrow(String time) {
    return 'Sáng mai $time';
  }

  @override
  String get pv2RemindNone => 'Không cần nhắc';

  @override
  String pv2RemindSet(String time) {
    return 'Sẽ nhắc bạn lúc $time';
  }

  @override
  String get pv2TryNowTitle => 'Đến giờ thử rồi';

  @override
  String get pv2TryAskTitle => 'Đã thử chưa?';

  @override
  String pv2TryAskBody(String title) {
    return '$title · Chạm để trả lời';
  }

  @override
  String get pv2ChipHelpedBefore => 'Từng có ích';

  @override
  String get pv2ChipUnsure => 'Chưa rõ';

  @override
  String get pv2Unsave => 'Bỏ lưu';

  @override
  String get pv2ToastUnsaved => 'Đã bỏ lưu.';

  @override
  String hnCheckInDone(String who) {
    return '$who đã ghi hôm nay';
  }

  @override
  String hnCheckInDoneSub(String what) {
    return 'Bé $what · Chạm để sửa';
  }

  @override
  String ageWeeksDays(int weeks, int days) {
    return '$weeks tuần $days ngày tuổi';
  }

  @override
  String ageShortWeeksDays(int weeks, int days) {
    return '$weeks tuần $days ngày';
  }

  @override
  String rhWeekOfPast(String baby) {
    return 'Tuần vừa qua của $baby';
  }

  @override
  String rhWeekOfNow(String baby) {
    return 'Tuần này của $baby';
  }

  @override
  String get rhWeekShareSheet => 'Gửi tổng kết tuần';

  @override
  String get rhWeekShareImage => 'Gửi ảnh';

  @override
  String get rhWeekShareTextOnly => 'Gửi dạng chữ';

  @override
  String get rhWeekShareFooter => 'Từ nhật ký của cả nhà · Child Life';

  @override
  String get rhEditToday => 'Sửa ghi nhận hôm nay';

  @override
  String periodDiapers(int count) {
    return '$count tã';
  }

  @override
  String get dayStripsTitle => 'Từng ngày';

  @override
  String get dayNothingLogged => 'Chưa ghi';

  @override
  String dayFeedsLine(int count) {
    return '$count cữ bú';
  }

  @override
  String dayBreastLine(int minutes) {
    return '$minutes phút bú mẹ';
  }

  @override
  String daySleepLine(int count, String duration) {
    return '$count giấc $duration';
  }

  @override
  String get careWokeUp => 'Thức dậy';

  @override
  String careAwakeFor(String duration) {
    return 'Thức $duration đến giấc sau';
  }

  @override
  String careAwakeNow(String duration) {
    return 'Đang thức · $duration';
  }

  @override
  String rhStageDaysLeft(int n) {
    return 'còn $n ngày';
  }

  @override
  String get rhStageLastDay => 'ngày cuối';

  @override
  String get rhCalendarDisclaimerShort => 'mỗi bé một khác';

  @override
  String get rhDayNotNoted => 'chưa ghi';

  @override
  String get rhTodayShort => 'Nay';

  @override
  String get rhLegendChanged => 'Có điều khác';

  @override
  String rhSleepSparseShort(int have, int need) {
    return 'Đã ghi đủ giấc ngủ $have/$need ngày · ghi thêm để so sánh';
  }

  @override
  String rhWeekObsChip(String what, int days) {
    return '$what ×$days';
  }

  @override
  String get pv2AgeNow => 'Ở tuổi này';

  @override
  String get pv2NextIdea => 'Gợi ý tiếp theo';

  @override
  String get pv2WatchFor => 'Khi nào cần đưa bé đi khám';

  @override
  String pv2WatchForCount(int count) {
    return '$count dấu hiệu cần lưu ý';
  }

  @override
  String get pv2WeekTriedShort => 'đã thử';

  @override
  String get pv2WeekHelpfulShort => 'thấy có ích';

  @override
  String get ntHandovers => 'Bàn giao';

  @override
  String get ntHandoversHint => 'Khi có người gửi bàn giao cho bạn';

  @override
  String get aiSendToFamily => 'Gửi bàn giao';

  @override
  String get aiSendToOther => 'Gửi cho người khác';

  @override
  String get aiShareOther => 'Chia sẻ qua ứng dụng khác…';

  @override
  String get aiShareShort => 'Chia sẻ';

  @override
  String aiSentTo(String name, String time) {
    return 'Đã gửi cho $name · $time';
  }

  @override
  String get aiSendNotSeen => 'Chưa mở';

  @override
  String aiSendSeen(String name, String time) {
    return '$name đã xem · $time';
  }

  @override
  String aiSendReceived(String name, String time) {
    return '$name đã nhận bàn giao · $time';
  }

  @override
  String aiSentToast(String name) {
    return 'Đã gửi cho $name. $name sẽ nhận được thông báo.';
  }

  @override
  String aiSentNoPush(String name) {
    return 'Đã gửi bàn giao cho $name trong app. Có thể chưa có thông báo trên máy; bạn có thể chia sẻ thêm.';
  }

  @override
  String get aiSendFailed => 'Chưa gửi được. Kiểm tra mạng rồi thử lại.';

  @override
  String aiSentToYou(String name, String time) {
    return '$name gửi bàn giao cho bạn · $time';
  }

  @override
  String aiYouReceived(String time) {
    return 'Bạn đã nhận bàn giao lúc $time';
  }

  @override
  String aiSentToYouShort(String name) {
    return '$name gửi bàn giao cho bạn';
  }

  @override
  String get aiNewBadge => 'Mới';

  @override
  String get sryAddTitle => 'Thêm vào câu chuyện';

  @override
  String get sryKindParagraph => 'Đoạn văn';

  @override
  String get sryKindPhotos => 'Ảnh';

  @override
  String get sryKindMilestone => 'Mốc';

  @override
  String get sryKindQuote => 'Trích dẫn';

  @override
  String axGreetMorning(String name) {
    return 'Chào buổi sáng, $name ☀️';
  }

  @override
  String axGreetAfternoon(String name) {
    return 'Chào buổi chiều, $name';
  }

  @override
  String axGreetEvening(String name) {
    return 'Chào buổi tối, $name 🌙';
  }

  @override
  String axGreet36(String name) {
    return 'Hôm nay của $name thế nào?';
  }

  @override
  String axGreet612(String name) {
    return 'Cùng lưu lại hành trình của $name';
  }

  @override
  String get axSub01 => 'Nhịp hôm nay của con, ghi nhanh trong một chạm.';

  @override
  String get axSub13 => 'Hôm nay con lại khám phá thêm điều mới.';

  @override
  String get axSub36 =>
      'Lưu lại một khoảnh khắc nhỏ — mai này sẽ thành câu chuyện lớn.';

  @override
  String get axSub612 =>
      'Những ngày đi học, những chuyến đi, những điều con tự hào.';

  @override
  String axHello(String name) {
    return 'Chào $name 👋';
  }

  @override
  String get axHelloSub01 =>
      'Bắt đầu bằng một việc nhỏ — không cần mời ai trước.';

  @override
  String get axHelloSub13 =>
      'Bắt đầu lúc nào cũng kịp — giữ lại từ hôm nay, tìm lại cả những ngày đã qua.';

  @override
  String get axHelloSub36 =>
      'Mỗi khoảnh khắc là một câu chuyện. Bắt đầu từ hôm nay nhé.';

  @override
  String get axHelloSub612 =>
      'Cùng lưu lại hành trình đi học, những chuyến đi và điều con tự hào.';

  @override
  String get axRecentTitle => 'Kỷ niệm gần đây';

  @override
  String axRecentSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tuần này · $count ảnh',
      zero: 'Chưa có ảnh tuần này',
    );
    return '$_temp0';
  }

  @override
  String get axSeeAll => 'Xem tất cả';

  @override
  String get axAddMoment => 'Thêm khoảnh khắc';

  @override
  String get axWriteJournal => 'Viết nhật ký hôm nay';

  @override
  String get axFirstMomentTitle => 'Lưu khoảnh khắc đầu tiên';

  @override
  String axFirstMomentOf(String name) {
    return 'Lưu khoảnh khắc đầu tiên của $name';
  }

  @override
  String axFirstJournal(String name) {
    return 'Bắt đầu cuốn nhật ký của $name';
  }

  @override
  String get axFirstMomentSub01 => 'Ảnh hoặc vài dòng về hôm nay';

  @override
  String get axFirstMomentSub => 'Ảnh, video hoặc nhật ký';

  @override
  String get axFirstMomentSub36 =>
      'Một bức vẽ, một buổi đi chơi, một câu nói ngộ nghĩnh';

  @override
  String get axMomentTodayTitle => 'Lưu khoảnh khắc hôm nay';

  @override
  String get axMomentTodaySub => 'Ảnh, video hoặc vài dòng nhật ký';

  @override
  String axCreateTitle(String name) {
    return 'Tạo từ kỷ niệm của $name';
  }

  @override
  String get axCreateSub => 'Video, thiệp từ ảnh bạn chọn';

  @override
  String get axCreateVideo => 'Video kỷ niệm';

  @override
  String get axCreateVideoSub => 'Từ ảnh của bạn';

  @override
  String get axCreateCard => 'Thiệp';

  @override
  String get axCreateCardSub => 'Dịp đáng nhớ';

  @override
  String get axGrowthTitle => 'Tăng trưởng';

  @override
  String axGrowthLast(String ago) {
    return 'Đo lần cuối $ago';
  }

  @override
  String get axGrowthNone => 'Chưa có số đo nào';

  @override
  String get axGrowthLog => 'Ghi số đo';

  @override
  String get axFamilyTitle => 'Cả nhà cùng xem';

  @override
  String get axFamilyBody =>
      'Ông bà xem được những kỷ niệm bạn chia sẻ với gia đình.';

  @override
  String axFamilyAlone(String name) {
    return 'Chỉ mình bạn trong gia đình của $name';
  }

  @override
  String get axInvite => 'Mời người thân';

  @override
  String get axCustomizeLink => 'Tuỳ chỉnh Hôm nay';

  @override
  String get axGoalsLabel => 'Mục tiêu của gia đình';

  @override
  String get axGoalsEdit => 'Sửa';

  @override
  String get axShowing => 'Đang hiện';

  @override
  String get axHiddenLabel => 'Đã ẩn';

  @override
  String axPin(String title) {
    return 'Ghim $title';
  }

  @override
  String axUnpin(String title) {
    return 'Bỏ ghim $title';
  }

  @override
  String axRestore(String name) {
    return 'Khôi phục gợi ý theo tuổi của $name';
  }

  @override
  String axGoalsTitle(String name) {
    return 'Bạn muốn Child Life giúp gì cho $name?';
  }

  @override
  String get axGoalsSub =>
      'Chọn tất cả những gì bạn quan tâm · đổi được bất cứ lúc nào';

  @override
  String axGoalsSuggested(String age) {
    return 'Gợi ý cho $age';
  }

  @override
  String axGoalsChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chọn $count mục',
      zero: 'Chưa chọn mục nào',
    );
    return '$_temp0';
  }

  @override
  String get axGoalTrackCare => 'Theo dõi bú, ngủ, tã';

  @override
  String get axGoalTrackCareSub => 'Ghi nhanh và xem nhịp của con';

  @override
  String get axGoalMemories => 'Lưu giữ kỷ niệm';

  @override
  String get axGoalMemoriesSub => 'Ảnh, video, nhật ký, thiệp';

  @override
  String get axGoalGrowth => 'Tăng trưởng & tiêm chủng';

  @override
  String get axGoalGrowthSub => 'Số đo, lịch tiêm';

  @override
  String get axGoalFamily => 'Cả nhà cùng chăm & cùng xem';

  @override
  String get axGoalFamilySub => 'Mời ba/mẹ, ông bà, người chăm';

  @override
  String get axGoalSpending => 'Chi tiêu cho con';

  @override
  String get axGoalSpendingSub => 'Biết tiền đã chi vào đâu';

  @override
  String get axGoalReminders => 'Nhắc nhở việc của bé';

  @override
  String get axGoalRemindersSub => 'Không quên việc quan trọng';

  @override
  String get axWidgetTiles => 'Ghi nhanh';

  @override
  String get axWidgetQuickActions => 'Tạo nhanh';

  @override
  String get axWidgetVaccine => 'Mũi tiêm sắp tới';

  @override
  String get axWidgetSpending => 'Chi tiêu tháng này';

  @override
  String get axWidgetRhythm => 'Đã ghi hôm nay';

  @override
  String get axWidgetReminders => 'Nhắc nhở';

  @override
  String get axWidgetCreate => 'Tạo từ kỷ niệm';

  @override
  String get axWidgetCreateSub => 'Video, thiệp';

  @override
  String get axDone => 'Xong';

  @override
  String axPreviewTitle(String name) {
    return 'Hôm nay của $name sẽ ưu tiên';
  }

  @override
  String axPreviewSub(String name) {
    return 'Dựa trên tuổi của $name và mục tiêu bạn chọn.';
  }

  @override
  String get axPreviewHint =>
      'Kéo để đổi thứ tự. Sửa bất cứ lúc nào trong “Tuỳ chỉnh Hôm nay”.';

  @override
  String axPreviewGo(String name) {
    return 'Vào Hôm nay của $name';
  }

  @override
  String axInfoTitle(String name) {
    return 'Mọi tính năng của Child Life đều dùng được cho $name.';
  }

  @override
  String axInfoSub(String name) {
    return 'Gợi ý cho tuổi của $name — bạn sẽ thấy trước trên Hôm nay:';
  }

  @override
  String get axChipMemories => 'Kỷ niệm & album';

  @override
  String get axChipVideo => 'Video & thiệp';

  @override
  String get axChipSpending => 'Chi tiêu';

  @override
  String get axChipVaccines => 'Tiêm chủng';

  @override
  String get axInfoFoot =>
      'Theo dõi bú, ngủ, tã, sơ cứu, Lumi… luôn có trong Khám phá khi bạn cần.';

  @override
  String get axInfoFootTabs =>
      'Theo dõi bú, ngủ, tã, sơ cứu, Lumi… luôn có trong Chăm sóc và Tiện ích khi bạn cần.';

  @override
  String axTrackersTitle(String name) {
    return 'Bạn muốn ghi những gì cho $name?';
  }

  @override
  String get axTrackersSub =>
      'Chỉ hiện những ô bạn chọn trên Hôm nay. Đổi lại sau trong hồ sơ bé.';

  @override
  String get tabExplore => 'Khám phá';

  @override
  String get tabProfile => 'Hồ sơ';

  @override
  String get exSearch01 => 'Tìm tính năng, ví dụ: tiêm, chi tiêu, sơ cứu';

  @override
  String get exSearchOlder => 'Tìm tính năng, ví dụ: chi tiêu, tiêm, kỷ niệm';

  @override
  String exForChild(String name) {
    return 'Gợi ý cho $name lúc này';
  }

  @override
  String get exLifelong => 'Dùng suốt hành trình của con';

  @override
  String get exHealth => 'Sức khoẻ & an toàn';

  @override
  String get exFamilyAssistant => 'Gia đình & trợ lý';

  @override
  String get exCareTools => 'Theo dõi chăm sóc';

  @override
  String get exUnderstand => 'Hiểu con & phát triển';

  @override
  String get exCare => 'Theo dõi bú, ngủ, tã';

  @override
  String get exCareSub => 'Ghi nhanh, hẹn giờ ngủ, hút sữa';

  @override
  String get exStats => 'Thống kê & lịch sử';

  @override
  String get exStatsSub => 'Bú, ngủ, tã theo ngày';

  @override
  String get exGrowthSub => 'Cân nặng, chiều cao';

  @override
  String get exVaccinesSub => 'Lịch mũi tiêm của con';

  @override
  String get exVaccinesSubOlder => 'Mũi nhắc theo lịch';

  @override
  String get exMemories => 'Kỷ niệm & album';

  @override
  String get exMemoriesSub => 'Ảnh, video, nhật ký';

  @override
  String get exKeepsakes => 'Video & thiệp kỷ niệm';

  @override
  String get exKeepsakesSub => 'Tạo từ ảnh bạn chọn';

  @override
  String get exKeepsakesSubOlder => 'Sinh nhật, ngày đầu đi học…';

  @override
  String get exAutoSave => 'Tự lưu kỷ niệm';

  @override
  String exAutoSaveSub(String name) {
    return 'Gợi ý ảnh có $name từ thư viện máy';
  }

  @override
  String get exBeta => 'Beta';

  @override
  String get exSpending => 'Chi tiêu cho con';

  @override
  String get exSpendingSub => 'Theo tháng, danh mục, người chi';

  @override
  String get exSpendingSubOlder => 'Giữ trẻ & học, quần áo…';

  @override
  String get exRemindersSub => 'Việc của bé, nhắc cả nhà';

  @override
  String get exRemindersSubOlder => 'Lịch học, khám, tiêm nhắc';

  @override
  String get exFamily => 'Gia đình & chia sẻ';

  @override
  String get exFamilySub => 'Thành viên, vai trò, lời mời';

  @override
  String get exFamilySubOlder => 'Ông bà xem kỷ niệm được chia sẻ';

  @override
  String get exLumi => 'Lumi';

  @override
  String get exLumiSub => 'Hỏi, ghi nhanh bằng một câu nhắn';

  @override
  String exLumiSubOlder(String name) {
    return 'Hỏi về lịch, kỷ niệm, chi tiêu của $name';
  }

  @override
  String get exFirstAid => 'Sơ cứu trẻ em';

  @override
  String get exAllCare => 'Tất cả công cụ chăm sóc';

  @override
  String get exAllCareSub => 'Dinh dưỡng, ăn dặm, Wonder Weeks, thư viện…';

  @override
  String get exGrowTitle => 'Cùng con lớn lên';

  @override
  String get exGrowBadge => 'Đang phát triển · chưa có trong app';

  @override
  String exGrowBody(String name) {
    return 'Child Life đang xây thêm cho các chặng 1–3, 3–6 và 6–12 tuổi. Mọi kỷ niệm, chi tiêu và lịch sử của $name vẫn được giữ trọn.';
  }

  @override
  String get exBand13 => '1–3 tuổi';

  @override
  String get exBand36 => '3–6 tuổi';

  @override
  String get exBand612 => '6–12 tuổi';

  @override
  String get exNotify => 'Báo tôi khi có';

  @override
  String get exNotified => 'Đã ghi nhận';

  @override
  String get exNotifiedToast =>
      'Đã ghi nhận. Child Life sẽ báo trong app khi có.';

  @override
  String exNoneTitle(String query) {
    return 'Chưa có tính năng “$query”';
  }

  @override
  String exNoneBody(String name) {
    return 'Child Life đang phát triển thêm cho từng độ tuổi. Hiện bạn có thể lưu những điều đáng nhớ của $name vào Kỷ niệm.';
  }

  @override
  String get exSaveToMemories => 'Lưu vào Kỷ niệm';

  @override
  String get pfChildren => 'Các bé';

  @override
  String pfChildRow(String age) {
    return '$age · mục tiêu & Hôm nay';
  }

  @override
  String get pfAdd => 'Thêm';

  @override
  String get pfApp => 'Ứng dụng';

  @override
  String axStageTitle1(String name) {
    return '$name tròn 1 tuổi rồi!';
  }

  @override
  String axStageTitle3(String name) {
    return '$name tròn 3 tuổi rồi!';
  }

  @override
  String axStageTitle6(String name) {
    return '$name tròn 6 tuổi rồi!';
  }

  @override
  String get axStageBody1 =>
      'Nhiều gia đình bớt ghi bú từ lúc này. Muốn Hôm nay gọn hơn không?';

  @override
  String get axStageBodyLater =>
      'Muốn Hôm nay hợp với tuổi mới của con hơn không? Lịch sử vẫn giữ nguyên.';

  @override
  String get axStageLeadMemories => 'Đưa Kỷ niệm lên đầu Hôm nay';

  @override
  String get axStageLeadMoment => 'Đưa Lưu khoảnh khắc lên đầu Hôm nay';

  @override
  String get axStageLeadJournal => 'Đưa Kỷ niệm, nhật ký lên đầu Hôm nay';

  @override
  String get axStageHideFeeds =>
      'Ẩn Bú bình khỏi Ghi nhanh · vẫn ghi được khi cần';

  @override
  String get axStageKeepSleep => 'Giữ Ngủ, Tã trong Ghi nhanh';

  @override
  String get axStageHideQuickLog =>
      'Ẩn Ghi nhanh khỏi Hôm nay · bật lại trong Tuỳ chỉnh';

  @override
  String get axStageKeepGrowth => 'Giữ Tăng trưởng trên Hôm nay';

  @override
  String get axStageApply => 'Áp dụng';

  @override
  String get axStageKeep => 'Giữ như cũ';

  @override
  String get axLumiQ01 => 'Lần bú cuối lúc mấy giờ?';

  @override
  String axLumiQ13(String name) {
    return 'Tuần này $name ngủ trưa thế nào?';
  }

  @override
  String axLumiQ36(String name) {
    return 'Tháng này đã chi cho $name bao nhiêu?';
  }

  @override
  String axLumiQ612(String name) {
    return 'Tuần tới $name có lịch gì?';
  }

  @override
  String get psTab => 'Kỷ vật';

  @override
  String get psTitle => 'In & giữ trên tay';

  @override
  String get psIntro => 'Từ những kỷ niệm của con, thành món quà cho cả nhà.';

  @override
  String get psSingle => 'Một khung';

  @override
  String get psTrio => 'Bộ 3 khung';

  @override
  String get psFive => 'Bộ 5 khung';

  @override
  String get psBook => 'Sách ảnh';

  @override
  String get psFrames => 'Khung đặt bàn';

  @override
  String get psBooks => 'Photo Book';

  @override
  String get psOrders => 'Đơn in của tôi';

  @override
  String get psPolicy => 'Giao hàng & đổi trả';

  @override
  String get psCustomize => 'Tuỳ chỉnh';

  @override
  String get psStyle => 'Phong cách';

  @override
  String get psMinimal => 'Tối giản';

  @override
  String get psPlayful => 'Đáng yêu';

  @override
  String get psTimeless => 'Cổ điển';

  @override
  String get psInSet => 'Trong bộ';

  @override
  String get psPortrait => 'Chân dung';

  @override
  String get psInfo => 'Thông tin bé';

  @override
  String get psCollage => 'Ghép 4 ảnh';

  @override
  String get psEdit => 'Sửa';

  @override
  String get psNext => 'Tiếp tục';

  @override
  String get psDone => 'Xong';

  @override
  String get psSave => 'Lưu nháp';

  @override
  String get psSaved => 'Đã lưu bản nháp';

  @override
  String get psSaving => 'Đang lưu…';

  @override
  String get psSaveFailed => 'Chưa lưu được. Thử lại trước khi rời màn hình.';

  @override
  String get psName => 'Tên trên khung';

  @override
  String get psMessage => 'Lời nhắn';

  @override
  String get psDefaultMessage => 'Cảm ơn con đã đến bên ba mẹ';

  @override
  String get psBirthDetails => 'Thông tin ngày sinh, cân nặng, chiều dài';

  @override
  String get psShowBirth => 'Hiện thông tin ngày sinh';

  @override
  String get psOccasion => 'Dịp kỷ niệm';

  @override
  String get psMonth => 'Đầy tháng';

  @override
  String get psHundred => '100 ngày';

  @override
  String get psBirthday => 'Sinh nhật';

  @override
  String get psCustom => 'Dịp riêng';

  @override
  String get psDate => 'Ngày trên bản in';

  @override
  String get psPrintTitle => 'Tiêu đề';

  @override
  String get psSafeArea =>
      'Vùng nét đứt: giữ nội dung quan trọng bên trong để tránh bị cắt.';

  @override
  String get psPhotoChange => 'Đổi ảnh';

  @override
  String get psPhotosMissing => 'Thêm ảnh để hoàn thiện bản in';

  @override
  String get psPhotosHelp =>
      'Chọn ảnh đã lưu trong Kỷ niệm. Ảnh và thông tin chỉ được dùng cho bản thiết kế này.';

  @override
  String get psNoPhotos =>
      'Chưa có ảnh phù hợp. Hãy thêm ảnh vào Kỷ niệm rồi quay lại.';

  @override
  String get psChoose => 'Chọn ảnh';

  @override
  String get psOptions => 'Chọn kích thước & khung';

  @override
  String get psSize => 'Kích thước';

  @override
  String get psWhite => 'Classic · trắng';

  @override
  String get psWood => 'Classic · gỗ sáng';

  @override
  String get psGift => 'Premium · hộp quà';

  @override
  String get psAcrylic => 'Mặt acrylic an toàn · có chân đỡ để bàn';

  @override
  String get psPreview => 'Xem thiết kế';

  @override
  String get psFlat => 'Xem bản in phẳng';

  @override
  String get psDownload => 'Tải file để in';

  @override
  String get psOrder => 'Đặt in';

  @override
  String get psConfirm => 'Đơn in của bạn';

  @override
  String get psApproved =>
      'Tôi đã kiểm tra ảnh, chữ, ngày và bố cục trên từng bản in.';

  @override
  String get psImmutable =>
      'Đơn lưu đúng bản thiết kế đã duyệt. Sửa kỷ niệm sau này không làm thay đổi đơn.';

  @override
  String get psShipping => 'Giao đến đâu?';

  @override
  String get psRecipient => 'Người nhận';

  @override
  String get psPhone => 'Số điện thoại';

  @override
  String get psAddress => 'Địa chỉ đầy đủ';

  @override
  String get psCountry => 'Quốc gia giao hàng';

  @override
  String get psCountryHelp =>
      'Hiện giao hàng tại Việt Nam. Ở quốc gia khác, bạn có thể tải file để in gần nhà.';

  @override
  String get psNeededBy => 'Cần nhận trước ngày (không bắt buộc)';

  @override
  String get psTooSoon =>
      'Có thể không kịp ngày bạn cần. Chọn ngày muộn hơn hoặc tải file để in tại tiệm gần bạn.';

  @override
  String get psGiftDelivery => 'Gửi tặng';

  @override
  String get psGiftNote => 'Thiệp nhắn tặng';

  @override
  String get psSubtotal => 'Tiền sản phẩm';

  @override
  String get psShippingFee => 'Phí giao hàng';

  @override
  String get psTotal => 'Tổng cộng';

  @override
  String get psSubmit => 'Xác nhận đặt hàng';

  @override
  String get psOrderCreated => 'Đã nhận đơn in của bạn';

  @override
  String get psConfirmed => 'Đã xác nhận';

  @override
  String get psPrinting => 'Đang in';

  @override
  String get psShipped => 'Đang giao';

  @override
  String get psDelivered => 'Đã nhận hàng';

  @override
  String get psCancelled => 'Đã huỷ';

  @override
  String get psCopy => 'Sao chép';

  @override
  String get psCopied => 'Đã sao chép';

  @override
  String get psCancelOrder => 'Huỷ đơn';

  @override
  String get psCancelConfirm =>
      'Huỷ yêu cầu đặt in này? Đơn sẽ không được chuyển sang sản xuất.';

  @override
  String get psKeep => 'Giữ đơn';

  @override
  String get psNoOrders => 'Chưa có đơn in';

  @override
  String get psNoOrdersHelp =>
      'Bắt đầu từ một bộ khung hoặc cuốn sách của con.';

  @override
  String get psTracking => 'Mã vận đơn';

  @override
  String get psQuantity => 'Số lượng';

  @override
  String get psExportTitle => 'Tải file in';

  @override
  String get psPdf => 'PDF · bleed 3 mm · khuyên dùng';

  @override
  String get psJpg => 'JPG · 300 DPI · file ZIP';

  @override
  String get psPng => 'PNG · 300 DPI · file ZIP';

  @override
  String get psCropMarks => 'Dấu cắt (crop marks)';

  @override
  String get psExportHelp =>
      'File được dựng từ ảnh gốc ở 300 DPI. In đúng kích thước, không chọn co giãn vừa trang. Màu in có thể khác màn hình.';

  @override
  String get psExportReady => 'File đã sẵn sàng';

  @override
  String get psExportReadyHelp =>
      'Lưu file về máy trong vòng một giờ. Bạn có thể tạo lại nếu liên kết hết hạn.';

  @override
  String get psOpenFile => 'Lưu / chia sẻ file';

  @override
  String get psGenerating => 'Đang dựng file in… Bạn có thể cần chờ một chút.';

  @override
  String get psLowQuality => 'Ảnh có thể mờ khi in';

  @override
  String get psLowQualityHelp =>
      'Một số ảnh có độ phân giải thấp hoặc chưa có thông tin kích thước. Đổi ảnh gốc rõ hơn hoặc chọn kích thước nhỏ.';

  @override
  String get psAcceptQuality => 'Vẫn tải file này';

  @override
  String get psUnavailable =>
      'Đặt in chưa mở. Bạn vẫn có thể thiết kế và tải file để tự in.';

  @override
  String get psError =>
      'Chưa thực hiện được. Kiểm tra kết nối rồi thử lại; bản thiết kế vẫn còn ở đây.';

  @override
  String get psPriceChanged =>
      'Giá hoặc cấu hình đã thay đổi. Hãy kiểm tra lại tổng tiền trước khi đặt.';

  @override
  String get psInvalidForm =>
      'Kiểm tra tên, số điện thoại Việt Nam và địa chỉ.';

  @override
  String get psRetry => 'Thử lại';

  @override
  String get psSamplePrice => 'Giá dự kiến · phí giao tính ở bước cuối';

  @override
  String get psSparseBook =>
      'Ít ảnh cũng thành một cuốn sách đẹp. Các trang có thể dùng lại ảnh; bạn được đổi ảnh và lời nhắn trước khi in.';

  @override
  String get psBookPages24 => '24 trang';

  @override
  String get psBookPages40 => '40 trang';

  @override
  String get psPage => 'Trang';

  @override
  String get psReview => 'Viết đánh giá';

  @override
  String get psReviewMessage => 'Cảm nhận của bạn';

  @override
  String get psReviewHelp =>
      'Chỉ người đã nhận hàng mới đánh giá được. Nội dung được duyệt trước khi công khai. Không ghi số điện thoại, địa chỉ hay thông tin riêng của bé.';

  @override
  String get psReviewSent => 'Đã gửi đánh giá để duyệt';

  @override
  String get psSendReview => 'Gửi đánh giá';

  @override
  String get psRating => 'Số sao';

  @override
  String get psNoReviews => 'Chưa có đánh giá từ người đã mua';

  @override
  String get psDetails => 'Chi tiết sản phẩm';

  @override
  String get psSpecs =>
      'Ảnh in giấy lụa · khung trắng hoặc gỗ sáng · mặt acrylic · chân đỡ để bàn. Thông số và giá chính thức sẽ được xác nhận khi mở đặt in.';

  @override
  String get psResume => 'Tiếp tục bản nháp';

  @override
  String get psNewDesign => 'Tạo thiết kế mới';

  @override
  String get psForParents => 'Chức năng này dành cho ba mẹ cùng nuôi.';

  @override
  String get psNameRequired => 'Nhập tên để tiếp tục.';

  @override
  String get psClose => 'Đóng';

  @override
  String get psBirth => 'Chào đời';

  @override
  String get psUnsaved =>
      'Bản nháp chưa lưu được. Bạn có muốn rời đi và bỏ các thay đổi chưa lưu?';

  @override
  String get psLeave => 'Rời đi';

  @override
  String get psViewOrder => 'Xem đơn';

  @override
  String get psReturn => 'Về Kỷ vật';

  @override
  String get psDeleteReview => 'Xoá đánh giá';

  @override
  String get psAllReviews => 'Tất cả';

  @override
  String get psVerifiedBuyer => 'Đã mua hàng';

  @override
  String get psVietnam => 'Việt Nam';

  @override
  String get psOtherCountry => 'Quốc gia khác';

  @override
  String get psOrderReview => 'Xác nhận đơn in';

  @override
  String get psManualOrderNote =>
      'Bạn chưa cần thanh toán khi đặt hàng. Child Life sẽ liên hệ để xác nhận sản phẩm, ngày nhận và cách thanh toán trước khi in.';

  @override
  String get psPendingConfirmation => 'Chờ xác nhận';

  @override
  String get psOrderReceivedHelp =>
      'Đã ghi nhận đơn của bạn. Child Life sẽ liên hệ để xác nhận trước khi in. Bạn có thể theo dõi trạng thái tại đây.';

  @override
  String get psEstimatedPriceNote =>
      'Đây là giá dự kiến, gồm phí giao hàng đang hiển thị. Nếu có thay đổi, Child Life sẽ thống nhất lại với bạn trước khi in.';

  @override
  String get psEstimatedTotal => 'Tổng dự kiến';

  @override
  String get psProductNotOpen =>
      'Sản phẩm này chưa mở nhận đơn. Bạn vẫn có thể thiết kế và tải file để tự in.';

  @override
  String get psCancelReason => 'Lý do huỷ';

  @override
  String get psCancelChangedMind => 'Thay đổi ý định';

  @override
  String get psCancelPrice => 'Giá sản phẩm';

  @override
  String get psCancelShipping => 'Phí giao hàng';

  @override
  String get psCancelDelivery => 'Thời gian nhận hàng';

  @override
  String get psCancelDesign => 'Thiết kế chưa phù hợp';

  @override
  String get psCancelUnreachable => 'Không liên hệ được';

  @override
  String get psCancelOther => 'Lý do khác';

  @override
  String get axSwitcherInvited => 'Bạn được mời vào';

  @override
  String get axSwitcherRelative => 'Người thân · chỉ xem kỷ niệm được chia sẻ';

  @override
  String get axSwitcherCaregiver =>
      'Người chăm bé · ghi chăm sóc, xem nhắc nhở';

  @override
  String axSwitchedTo(String name, String age) {
    return 'Đang xem $name · $age';
  }

  @override
  String get axRhythmToday => 'Nhịp hôm nay';

  @override
  String get axSeeHistory => 'Xem lịch sử';

  @override
  String get axHistoryShort => 'Lịch sử';

  @override
  String get axFirstLogTitle => 'Ghi hoạt động đầu tiên';

  @override
  String get axLogFirst => 'Ghi lần đầu';

  @override
  String axSpendSub(String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khoản',
      zero: 'chưa có khoản nào',
    );
    return '$month · $_temp0';
  }

  @override
  String get axSpendAdd => 'Thêm';

  @override
  String axSpendFor(String name) {
    return 'Chi tiêu cho $name';
  }

  @override
  String get axSpendNone => 'Chưa có khoản chi nào';

  @override
  String get axSpendFirst => 'Ghi khoản chi đầu tiên';

  @override
  String axRemindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sắp tới',
      zero: 'Chưa có nhắc nhở nào',
    );
    return '$_temp0';
  }

  @override
  String get axRemindersAll => 'Tất cả';

  @override
  String get axRemindersFirst => 'Tạo nhắc nhở đầu tiên';

  @override
  String psMadeFrom(String name) {
    return 'Tạo từ kỷ niệm của $name';
  }

  @override
  String psMadeFor(String occasion, String name) {
    return '✨ Đã thiết kế riêng cho $occasion của $name';
  }

  @override
  String psSetTitle(String occasion, String name) {
    return 'Bộ khung $occasion của $name';
  }

  @override
  String psHeroTitle(String occasion) {
    return 'Bộ 3 khung đặt bàn · $occasion';
  }

  @override
  String psBookTitle(String occasion, String name) {
    return 'Cuốn sách $occasion của $name';
  }

  @override
  String get psSelectionHelp =>
      'Chọn số khung để xem và tự tay chỉnh thiết kế của con.';

  @override
  String get psNationwide => '🇻🇳 Giao toàn quốc';

  @override
  String get psSeeAll => 'Xem tất cả';

  @override
  String get psInformationFrame => 'Khung thông tin';

  @override
  String get psFirstYear => 'Năm đầu đời';

  @override
  String psFromPrice(String price) {
    return 'từ $price';
  }

  @override
  String get psChooseProduct => 'Chọn sản phẩm';

  @override
  String get psPopular => 'Phổ biến';

  @override
  String get psSetContents => 'Chân dung · Thông tin bé · Ghép ảnh';

  @override
  String get psPortraitHelp => 'Ảnh rõ nét nhất của con';

  @override
  String get psInfoHelp => 'Tên, ngày sinh, cân nặng, lời nhắn';

  @override
  String get psCollageHelp => '4 khoảnh khắc đáng yêu';

  @override
  String psFrameNumber(String number) {
    return 'Khung $number';
  }

  @override
  String get psFrameSizeHelpSmall => 'Khung nhỏ trang trí bàn';

  @override
  String get psFrameSizeHelpMedium => 'Khung để bàn tiêu chuẩn';

  @override
  String get psFrameSizeHelpLarge => 'Nổi bật trên bàn gallery';

  @override
  String get psRecommended => 'khuyên dùng';

  @override
  String get psAcrylicTitle => 'Mặt acrylic an toàn';

  @override
  String get psAcrylicHelp => 'Không vỡ khi vận chuyển · mặc định';

  @override
  String psDeliveryEstimate(String days) {
    return 'Thời gian nhận dự kiến: khoảng $days ngày. Child Life sẽ liên hệ xác nhận trước khi in.';
  }

  @override
  String get psConfirmStep => 'Bản in';

  @override
  String get psShippingStep => 'Giao hàng';

  @override
  String get psOrderReviewStep => 'Xác nhận';

  @override
  String get psPhoneHelp => 'Child Life gọi số này để xác nhận trước khi in.';

  @override
  String get psGiftHelp => 'Không kèm hoá đơn giá · thêm thiệp chúc';

  @override
  String get psPrintLocked => 'Bản in đã khoá';

  @override
  String get psInYourSet => 'Trong bộ gồm những gì?';

  @override
  String get psProductInfo => 'Thông số';

  @override
  String get psCustomerReviews => 'Đánh giá từ người đã mua';

  @override
  String get psShippingAndPayment => 'Giao hàng & xác nhận';

  @override
  String get psNoDepositTitle => 'Không cần thanh toán trước';

  @override
  String get psNoDepositHelp =>
      'Gửi yêu cầu, Child Life sẽ liên hệ để thống nhất giá, ngày nhận và cách thanh toán.';

  @override
  String get psCustomizeFirst => 'Cá nhân hoá thiết kế';

  @override
  String get psBookHelp =>
      'Mở ra xem những ảnh ba mẹ đã lưu — rồi tự tay sắp xếp, sửa từng trang.';

  @override
  String get psBookSourceNote =>
      'Ảnh và lời nhắn lấy từ Kỷ niệm của bé — không tự thêm sự kiện chưa ghi.';

  @override
  String get psBookPageHelp => 'Chạm vào ảnh để thay · chạm vào chữ để sửa';

  @override
  String psBookPagesCount(int count) {
    return '$count trang';
  }

  @override
  String get psSuggested => 'Gợi ý';

  @override
  String get psUsePhoto => 'Dùng ảnh này';

  @override
  String psPickPhotoTitle(String number) {
    return 'Chọn ảnh cho Khung $number';
  }

  @override
  String get psPickPhotoHelp =>
      'Ưu tiên ảnh rõ nét, thấy mặt bé, đủ độ phân giải để in.';

  @override
  String get psPreviewGallery => 'Xem ảnh sản phẩm';

  @override
  String get psPolicySummary => 'Xác nhận trước khi in · không cần cọc';

  @override
  String get psDownloadShort => 'Tải file';

  @override
  String get psShippingLater => 'Phí ship tính ở bước sau';

  @override
  String get psApprovedDetail =>
      'Tôi đã kiểm tra tên, ngày và ảnh trên từng bản in. Child Life in đúng như bản xác nhận.';

  @override
  String get psHowStands => 'Khung đứng thế nào?';

  @override
  String get psStanding => 'Nghiêng 75°';

  @override
  String get psStandingHelp => 'Chân đỡ bật ra, đứng vững trên bàn';

  @override
  String get psFrameBack => 'Mặt sau';

  @override
  String get psFrameBackHelp => 'Chân đỡ + móc treo tường';

  @override
  String get psFrameSide => 'Góc nghiêng';

  @override
  String get psFrameSideHelp => 'Gọn trên kệ, tủ đầu giường';

  @override
  String get psSizeComparison => 'So với điện thoại';

  @override
  String get psComparisonHelp =>
      'Minh hoạ kích thước · điện thoại khoảng 15 cm';

  @override
  String get psFormat => 'Định dạng';

  @override
  String get hoSleep => 'Ngủ';

  @override
  String get hoFeed => 'Bú';

  @override
  String get hoDiaper => 'Tã';

  @override
  String get hoNoneYet => 'Chưa ghi gần đây';

  @override
  String hoDiapersToday(int count) {
    return 'Hôm nay $count lần';
  }

  @override
  String get hoUpcoming => 'Tiếp theo';

  @override
  String get hoNothingUpcoming => 'Hôm nay không có việc nào đã hẹn.';

  @override
  String get hoAllDay => 'Cả ngày';

  @override
  String get hoNoHealth => 'Không có dấu hiệu sức khoẻ nào trong 2 ngày qua';

  @override
  String hoHealthNoted(String date) {
    return 'Có dấu hiệu sức khoẻ · $date';
  }

  @override
  String hoCall(String number) {
    return 'Gọi $number';
  }

  @override
  String get hoFirstAid => 'Sơ cứu';

  @override
  String get hoHelps => 'Cách giúp bé';

  @override
  String get hoSummary => 'Tóm tắt mấy ngày qua';

  @override
  String hoNoteFrom(String name) {
    return 'Lời nhắn của $name';
  }

  @override
  String get hoNoteHint => 'Lời nhắn cho người nhận (không bắt buộc)';

  @override
  String get hoAsleep => 'Đang ngủ';

  @override
  String get hoAwake => 'Đang thức';

  @override
  String hoSleptAt(String time) {
    return 'ngủ lúc $time';
  }

  @override
  String hoWokeAt(String time) {
    return 'dậy lúc $time';
  }

  @override
  String hoLastNap(String duration) {
    return 'Giấc vừa rồi $duration';
  }

  @override
  String hoLastNight(String duration) {
    return 'đêm qua $duration';
  }

  @override
  String get hoLastFeed => 'Bú gần nhất';

  @override
  String get hoLastDiaper => 'Tã gần nhất';

  @override
  String hoBottleMl(String amount) {
    return 'bình $amount';
  }

  @override
  String get hoNextFeedTitle => 'Cữ bú tới';

  @override
  String hoAround(String time) {
    return 'khoảng $time';
  }

  @override
  String hoNextFeedLeft(String duration) {
    return 'còn khoảng $duration · theo các cữ hôm nay';
  }

  @override
  String get hoFeedDue => 'Đến giờ bú theo các cữ hôm nay';

  @override
  String get hoStripA11y => 'Ngủ, bú và thay tã trong 24 giờ qua';

  @override
  String hoYesterdayAt(String time) {
    return '$time hôm qua';
  }

  @override
  String get hoNowLabel => 'bây giờ';

  @override
  String hoUpdated(String name, String time) {
    return '$name · cập nhật $time từ nhật ký';
  }

  @override
  String hoVaccineNext(int count) {
    return 'Tiêm phòng · $count mũi';
  }

  @override
  String hoVaccineOverdue(int count) {
    return 'Quá hạn tiêm · $count mũi';
  }

  @override
  String get psCheckout => 'Đặt hàng';

  @override
  String get psCheckoutProof => 'Tôi đã kiểm tra tên, ngày và ảnh trên bản in';

  @override
  String get psReviewPrint => 'Xem lại bản in';

  @override
  String get psDeliverTo => 'Giao tới';

  @override
  String get psAddAddress => 'Thêm địa chỉ giao hàng';

  @override
  String get psPayment => 'Thanh toán';

  @override
  String get psCod => 'Thanh toán khi nhận hàng';

  @override
  String get psCodHelp =>
      'Kiểm tra hàng rồi trả tiền mặt hoặc chuyển khoản cho shipper';

  @override
  String get psTransfer => 'Chuyển khoản / VietQR';

  @override
  String get psTransferHelp =>
      'Không bắt buộc · Child Life sẽ liên hệ sau khi đặt';

  @override
  String get psWrap => 'Gói quà & thiệp viết tay';

  @override
  String get psCheckoutPolicy =>
      'Sản phẩm in riêng cho bé: đổi mới miễn phí khi lỗi in hoặc hư hỏng khi giao (báo trong 48 giờ). Xem chính sách giao hàng & đổi trả.';

  @override
  String get psOrderSuccess => 'Đặt hàng thành công!';

  @override
  String psOrderCode(String code) {
    return 'Mã đơn $code';
  }

  @override
  String psOrderSuccessHelp(String name) {
    return 'Đã ghi nhận bản in của $name. Child Life sẽ liên hệ xác nhận trước khi in. Bạn không cần trả trước.';
  }

  @override
  String get psOrderAccepted => 'Đã nhận đơn';

  @override
  String get psProduction => 'In & đóng khung';

  @override
  String get psDelivery => 'Giao hàng';

  @override
  String get psPayOnReceipt => 'Thanh toán khi nhận';

  @override
  String get psBackMemories => 'Về Kỷ niệm';

  @override
  String psExpectedDays(String days) {
    return 'Khoảng $days ngày';
  }

  @override
  String get psFrameLabel => 'Khung';

  @override
  String get psSetSize => 'Kích thước (cả bộ)';

  @override
  String get psBookOptions => 'Tuỳ chọn sách';

  @override
  String get psBookStyle => 'Phong cách sách';

  @override
  String get psQrVideo => 'Thêm mã QR xem video kỷ niệm';

  @override
  String get psComingSoon => 'Sắp có';

  @override
  String psBookMonth(String month) {
    return 'Tháng $month';
  }

  @override
  String get psBookBirth => 'Chào đời';

  @override
  String get psBookMessages => 'Lời nhắn';

  @override
  String psBookMonthPhotos(String month, String name) {
    return 'Ảnh tháng $month của $name';
  }

  @override
  String get psUnused => 'Chưa dùng';

  @override
  String get psUsed => 'Đã dùng';

  @override
  String get psFavorites => 'Yêu thích';

  @override
  String get psVideos => 'Video';

  @override
  String get psBookLibraryHelp =>
      'Chạm ảnh để thêm vào trang đang mở · giữ và kéo lên trang để thay ảnh';

  @override
  String get psFullscreen => 'Toàn màn hình';

  @override
  String get psLandscape => 'Ngang';

  @override
  String get psPortraitMode => 'Dọc';

  @override
  String get psEditPage => 'Sửa trang';

  @override
  String get psBookFullscreenHelp =>
      'Vuốt trái/phải để lật · chạm để ẩn thanh điều khiển';

  @override
  String get psBookImages => 'Ảnh';

  @override
  String get psBookText => 'Chữ';

  @override
  String get psBookLayout => 'Bố cục';

  @override
  String get psBookSubtitle => 'Dòng phụ';

  @override
  String get psBookTitleHint => 'Ngày lấy từ cột mốc ba mẹ đã ghi';

  @override
  String get psFrameMessageHint =>
      'Gợi ý: “100 ngày yêu thương” · “Con là món quà”';

  @override
  String get psBirthHelp => 'Lấy từ hồ sơ & lần đo đầu tiên · sửa được';

  @override
  String get psBirthDateLabel => 'NGÀY SINH';

  @override
  String get psBirthMeasureLabel => 'CÂN NẶNG · CHIỀU DÀI';

  @override
  String psBookPagesNote(String count) {
    return '$count trang · tự lưu bản nháp';
  }

  @override
  String get psContactPrint => 'Cần in theo yêu cầu riêng?';

  @override
  String get psContactPrintHelp => 'Liên hệ Child Life để được tư vấn';

  @override
  String psFrameDelivery(String from, String to) {
    return 'Đặt hôm nay, nhận khoảng $from–$to.';
  }

  @override
  String get psBookSparseMonth =>
      'Tháng này còn ít ảnh. Bạn có thể thêm ảnh hoặc tiếp tục với những kỷ niệm đã có.';

  @override
  String psOpenPage(String page, String total) {
    return 'Trang $page / $total';
  }

  @override
  String psDetailsPreview(String name) {
    return 'Xem thiết kế của $name';
  }

  @override
  String get psPdfShort => 'Tải PDF';

  @override
  String get psNoReviewsYet => 'Chưa có đánh giá từ người mua';

  @override
  String get psPendingShort => 'Chờ xác nhận';

  @override
  String get psMaterialShortWhite => 'Trắng';

  @override
  String get psMaterialShortWood => 'Gỗ sáng';

  @override
  String get psNoAdvancePayment => 'Trả khi nhận hàng';

  @override
  String dutyOnNow(String name, String time) {
    return '$name đang trông · từ $time';
  }

  @override
  String dutyOnSinceYesterday(String name) {
    return '$name trông từ hôm qua';
  }

  @override
  String get dutyNobody => 'Chưa ai nhận trông bé';

  @override
  String dutySheetTitle(String name) {
    return 'Ai đang trông $name?';
  }

  @override
  String dutyStateOn(String time, String duration) {
    return 'từ $time · $duration';
  }

  @override
  String dutyStateUntil(String time) {
    return 'đến $time';
  }

  @override
  String get dutyNobodyBody =>
      'Chưa ai nhận trông bé. Người đang chăm bé nhận để cả nhà cùng biết.';

  @override
  String get dutyTake => 'Tôi trông bé';

  @override
  String get dutyEnd => 'Kết thúc ca của tôi';

  @override
  String get dutyOpenHandover => 'Mở bàn giao';

  @override
  String get dutyTakenToast => 'Bạn đang trông bé. Cả nhà sẽ thấy.';

  @override
  String get dutyEndedToast => 'Đã kết thúc ca của bạn.';

  @override
  String get dutyFailed => 'Chưa cập nhật được. Kiểm tra mạng rồi thử lại.';

  @override
  String get dutyLabel => 'Đang trông';

  @override
  String dutyLine(String name, String time, String duration) {
    return '$name · từ $time · $duration';
  }

  @override
  String get hoTakeOver => 'Tôi nhận trông bé';

  @override
  String get psGalleryTable => 'Trên bàn';

  @override
  String get psGalleryAngle => 'Nghiêng';

  @override
  String get psPolicyIntro =>
      'Áp dụng cho khung ảnh và Photo Book in tại Việt Nam.';

  @override
  String get psPolicyCancelTitle => 'Huỷ trước khi in: miễn phí';

  @override
  String get psPolicyCancelHelp =>
      'Huỷ trong app khi đơn chưa vào xưởng in. Sản phẩm đang in hoặc đang giao không thể huỷ.';

  @override
  String get psPolicyReturnTitle => 'In lại miễn phí';

  @override
  String get psPolicyReturnHelp =>
      'Lỗi in, sai so với bản bạn đã duyệt hoặc hư hỏng khi vận chuyển: báo trong 48 giờ và gửi ảnh khi liên hệ hỗ trợ. Không đổi trả vì đổi ý với nội dung đã xác nhận.';

  @override
  String get psPolicyPrivacyTitle => 'Đóng gói & bảo vệ ảnh';

  @override
  String get psPolicyPrivacyHelp =>
      'File in chỉ dùng để thực hiện đơn của bạn. Khung được đóng gói bảo vệ khi vận chuyển.';

  @override
  String get psPolicyDeliveryHelp =>
      'Child Life xác nhận ngày giao dự kiến và tổng tiền trước khi chuyển đơn sang sản xuất.';

  @override
  String psPreviewPriceCaption(int count, String size) {
    return '$count khung $size · chưa gồm ship';
  }

  @override
  String psBookUsedPage(String page) {
    return 'Trang $page';
  }

  @override
  String psBookMonthSummary(String from, String to, String count, String used) {
    return '$from – $to · $count ảnh · $used đã dùng trong sách';
  }

  @override
  String get psAutoSave => 'Tự lưu';

  @override
  String psAutoSavedAt(String time) {
    return 'Tự lưu · $time';
  }

  @override
  String get axWidgetCareDuty => 'Việc chăm con cần làm';

  @override
  String get rhSeeHow => 'Xem cách làm';

  @override
  String get pv2Crest => 'CHILD LIFE PREMIUM';

  @override
  String get pv2SeePremium => 'Xem Premium';

  @override
  String get pv2SeePlans => 'Xem Premium';

  @override
  String get pv2GotIt => 'Đã hiểu';

  @override
  String pv2E01Title(String name) {
    return 'Mẫu “$name” thuộc Premium';
  }

  @override
  String pv2E01Body(int videos) {
    return 'Mẫu này có trong Premium, cùng khả năng xuất Full HD 1080p không giới hạn lượt. Ảnh và lời nhắn đang chọn được giữ nguyên.';
  }

  @override
  String get pv2E01Secondary => 'Dùng mẫu miễn phí';

  @override
  String pv2E02Title(String name) {
    return 'Mẫu thiệp “$name” thuộc Premium';
  }

  @override
  String get pv2E02Body =>
      'Premium mở toàn bộ mẫu thiệp & video cao cấp. Ảnh và lời nhắn bạn đã chọn sẽ được giữ.';

  @override
  String get pv2E02Secondary => 'Dùng mẫu miễn phí';

  @override
  String get pv2E04Title => 'Bản nháp này dùng mẫu cao cấp';

  @override
  String get pv2E04Body =>
      'Bản nháp vẫn còn. Nâng cấp Premium để xuất, hoặc đổi sang mẫu miễn phí.';

  @override
  String get pv2E04Secondary => 'Đổi sang mẫu miễn phí';

  @override
  String pv2E03Title(int n) {
    return 'Bạn đã dùng $n lượt xuất video trải nghiệm';
  }

  @override
  String pv2E03Body(int m) {
    return 'Premium có $m lượt xuất video mỗi tháng. Bản nháp này vẫn được giữ.';
  }

  @override
  String get pv2E03Secondary => 'Lưu bản nháp, để sau';

  @override
  String pv2E03PremiumTitle(int n) {
    return 'Đã dùng hết $n lượt video tháng này';
  }

  @override
  String pv2E03PremiumBody(String date) {
    return 'Lượt mới được cấp ngày $date. Bản nháp này vẫn được giữ.';
  }

  @override
  String pv2E07Title(int n) {
    return 'Lumi đã dùng hết $n lượt tháng này';
  }

  @override
  String pv2E07Body(String date) {
    return 'Lượt mới được cấp ngày $date. Trong lúc chờ, bạn vẫn ghi trực tiếp và xem nhật ký bình thường.';
  }

  @override
  String get pv2E07Secondary => 'Xem mức dùng của gia đình';

  @override
  String pv2E10Title(String gb) {
    return 'Hết $gb GB của gói Free';
  }

  @override
  String pv2E10Body(String premiumGb) {
    return 'Ảnh, video mới vẫn an toàn trên máy. Premium có $premiumGb GB cho cả nhà, tự tải tiếp sau khi nâng cấp.';
  }

  @override
  String get pv2ManageMedia => 'Quản lý ảnh/video';

  @override
  String get pv2E11Title => 'Tự lưu kỷ niệm đang tạm dừng';

  @override
  String pv2E11Body(String gb, String premiumGb) {
    return 'Gói Free đã dùng hết $gb GB. Premium có $premiumGb GB cho cả nhà, Tự lưu chạy tiếp ngay.';
  }

  @override
  String pv2E12Title(int used, int limit) {
    return 'Gia đình đã dùng $used/$limit chỗ người ghi';
  }

  @override
  String pv2E12Body(int premium) {
    return 'Premium có $premium chỗ người ghi. Hoặc mời làm người thân — xem album không giới hạn.';
  }

  @override
  String get pv2E12Secondary => 'Mời làm người thân';

  @override
  String pv2E12FullTitle(int limit) {
    return 'Gia đình đã dùng hết $limit chỗ người ghi';
  }

  @override
  String get pv2E12FullBody =>
      'Mời làm người thân để cùng xem album, hoặc đổi quyền một người đang ghi.';

  @override
  String get pv2E08Title => 'Nhà mình sắp hết chỗ lưu kỷ niệm';

  @override
  String pv2E08BodyPremium(int pct, String gb, String options) {
    return 'Đã dùng $pct% của $gb GB. Thêm $options, dùng chung cho cả gia đình.';
  }

  @override
  String pv2E09Title(String gb) {
    return 'Đã dùng hết $gb GB';
  }

  @override
  String get pv2E09BodyPremium =>
      'Ảnh, video mới đang chờ và sẽ tự tải tiếp sau khi thêm dung lượng. Vẫn xem, tải và xoá nội dung cũ bình thường.';

  @override
  String get pv2StorageInlineFreeTitle =>
      'Thêm chỗ cho những kỷ niệm tiếp theo';

  @override
  String pv2StorageInlineFreeBody(String premiumGb) {
    return 'Premium có $premiumGb GB cho cả nhà, ảnh mới cứ thế được lưu.';
  }

  @override
  String get pv2AddStorage => 'Thêm dung lượng';

  @override
  String get pv2E13Title => 'Child Life Premium';

  @override
  String pv2E13Body(int videos, int credits, String gb, String price) {
    return 'Mẫu cao cấp, video Full HD, thêm credit Lumi và dung lượng dùng chung cho cả nhà.';
  }

  @override
  String pv2HeadVideo(String name) {
    return 'Tạo video kỷ niệm của $name';
  }

  @override
  String pv2HeadCard(String name) {
    return 'Tạo thiệp dành riêng cho $name';
  }

  @override
  String pv2HeadLumi(String name) {
    return 'Tiếp tục hỏi Lumi về $name';
  }

  @override
  String get pv2HeadStorage => 'Thêm chỗ cho kỷ niệm tiếp theo';

  @override
  String pv2HeadCaregivers(String name) {
    return 'Thêm người cùng chăm $name';
  }

  @override
  String get pv2HeadExplore => 'Nâng cấp lên Premium';

  @override
  String pv2ReasonTemplate(String name) {
    return 'Mẫu “$name” và ảnh bạn chọn vẫn được giữ.';
  }

  @override
  String get pv2ReasonVideo => 'Bản nháp và ảnh bạn chọn vẫn được giữ.';

  @override
  String pv2ReasonLumi(int n) {
    return 'Câu hỏi của bạn đang chờ · đã dùng hết $n lượt trải nghiệm.';
  }

  @override
  String pv2ReasonStorage(String used, String limit) {
    return 'Đã dùng $used / $limit · mục mới vẫn an toàn trên máy.';
  }

  @override
  String pv2ReasonCaregivers(int used, int limit) {
    return 'Gói Free: $used / $limit chỗ người ghi.';
  }

  @override
  String get pv2ReasonMember => 'Có trong Premium — gói dùng chung của cả nhà.';

  @override
  String get pv2CardVideoEyebrow => 'THIỆP & VIDEO KỶ NIỆM';

  @override
  String get pv2CardVideoTitle => 'Kỷ niệm mang dấu ấn của con';

  @override
  String get pv2CardVideoBody => 'Chọn mẫu cao cấp, thêm ảnh, tên và lời nhắn.';

  @override
  String pv2CardVideoLimit(int n) {
    return 'Xuất video không giới hạn lượt';
  }

  @override
  String get pv2CardVideoDemo1 => 'Một tháng trước, nhà mình đón con.';

  @override
  String get pv2CardVideoDemo2 => 'Ngày đầu về nhà';

  @override
  String get pv2CardCardEyebrow => 'MẪU CAO CẤP';

  @override
  String get pv2CardCardTitle => 'Thiệp dành riêng cho con';

  @override
  String get pv2CardCardBody => 'Thêm tên, ảnh và lời nhắn theo mẫu bạn chọn.';

  @override
  String get pv2CardCardLimit => 'Toàn bộ mẫu cao cấp · Việt – Anh';

  @override
  String get pv2CardCardDemo => '100 NGÀY';

  @override
  String get pv2CardLumiEyebrow => 'LUMI MỖI THÁNG';

  @override
  String get pv2CardLumiTitle => 'Nói một câu, Lumi ghi giúp';

  @override
  String get pv2CardLumiBody =>
      'Ghi cữ bú, giấc ngủ bằng lời, hỏi lại nhật ký bất cứ lúc nào.';

  @override
  String pv2CardLumiLimit(int n) {
    return '$n credit/tháng · cả nhà dùng chung';
  }

  @override
  String get pv2CardLumiDemoQ => 'Hôm nay con bú thế nào?';

  @override
  String get pv2CardLumiDemoA => 'Đến 14:20: 3 cữ bú bình · 390 ml';

  @override
  String get pv2CardLumiDemoSource => 'Theo nhật ký đã ghi · Xem nguồn';

  @override
  String get pv2CardRhythmEyebrow => 'HIỂU NHỊP CON';

  @override
  String get pv2CardRhythmTitle => 'Biết trước cữ bú, giấc ngủ';

  @override
  String get pv2CardRhythmBody =>
      'Theo nhịp riêng của con, kèm bản tóm tắt mang đi khám.';

  @override
  String pv2CardRhythmLimit(int n) {
    return 'Có trong Premium';
  }

  @override
  String get pv2CardRhythmDemoLast => 'Tuần trước';

  @override
  String get pv2CardRhythmDemoThis => 'Tuần này';

  @override
  String get pv2CardStorageEyebrow => 'DUNG LƯỢNG';

  @override
  String get pv2CardStorageTitle => 'Thêm chỗ lưu ảnh và video';

  @override
  String get pv2CardStorageBody =>
      'Dung lượng dùng chung cho ảnh và video của cả gia đình.';

  @override
  String pv2CardStorageLimit(String gb) {
    return '$gb GB dùng chung cho cả nhà';
  }

  @override
  String get pv2CardStorageDemo => 'Đã tự lưu 12 ảnh mới hôm nay';

  @override
  String get pv2CardCaregiversEyebrow => 'CẢ NHÀ CÙNG CHĂM';

  @override
  String get pv2CardCaregiversTitle => 'Cùng ghi nhật ký chăm con';

  @override
  String get pv2CardCaregiversBody =>
      'Cùng ghi cữ bú, giấc ngủ và xem cập nhật trong nhật ký.';

  @override
  String pv2CardCaregiversLimit(int premium, int free) {
    return '$premium chỗ người ghi · Free: $free';
  }

  @override
  String get pv2CardCaregiversDemo1 => 'Mẹ · Đã ghi cữ bú 120 ml';

  @override
  String get pv2CardCaregiversDemo2 => 'Ba · Bắt đầu giấc ngủ';

  @override
  String get pv2CompareTitle => 'So sánh Free và Premium';

  @override
  String get pv2CompareBenefit => 'Quyền lợi';

  @override
  String get pv2YouNeed => 'Bạn đang cần';

  @override
  String get pv2RowLumi => 'Lumi';

  @override
  String pv2RowLumiFree(int n) {
    return '$n credit dùng thử một lần';
  }

  @override
  String pv2RowLumiPremium(int n) {
    return '$n lượt/tháng';
  }

  @override
  String get pv2RowStorage => 'Dung lượng';

  @override
  String pv2RowStoragePremium(String gb) {
    return '$gb GB · mua thêm khi cần';
  }

  @override
  String get pv2RowVideo => 'Xuất video kỷ niệm';

  @override
  String pv2RowVideoFree(int n) {
    return 'Không giới hạn · 720p';
  }

  @override
  String pv2RowVideoPremium(int n) {
    return 'Không giới hạn · Full HD 1080p';
  }

  @override
  String get pv2RowTemplates => 'Mẫu thiệp & video';

  @override
  String get pv2RowTemplatesFree => 'Mẫu cơ bản';

  @override
  String get pv2RowTemplatesPremium => 'Toàn bộ mẫu cao cấp';

  @override
  String get pv2RowCaregivers => 'Người có quyền ghi';

  @override
  String pv2RowPeople(int n) {
    return '$n người';
  }

  @override
  String get pv2RowRelatives => 'Người thân xem album';

  @override
  String get pv2Unlimited => 'Không giới hạn';

  @override
  String get pv2PromiseCancel => 'Huỷ bất cứ lúc nào';

  @override
  String get pv2PromiseNoTopUps => 'Không bán lượt lẻ';

  @override
  String get pv2PromiseYours => 'Kỷ niệm luôn là của bạn';

  @override
  String get pv2PeriodYear => 'Gói năm';

  @override
  String get pv2PeriodMonth => 'Gói tháng';

  @override
  String pv2PerMonthApprox(String price) {
    return 'Tương đương khoảng $price/tháng';
  }

  @override
  String get pv2EachMonth => 'Thanh toán hằng tháng';

  @override
  String pv2SubscribeYear(String price) {
    return 'Đăng ký gói năm · $price';
  }

  @override
  String pv2SubscribeMonth(String price) {
    return 'Đăng ký gói tháng · $price';
  }

  @override
  String pv2LegalYear(String price, String store) {
    return 'Thanh toán $price hôm nay · tự gia hạn mỗi năm · huỷ trong $store bất cứ lúc nào';
  }

  @override
  String pv2LegalMonth(String price, String store) {
    return 'Thanh toán $price hôm nay · tự gia hạn mỗi tháng · huỷ trong $store bất cứ lúc nào';
  }

  @override
  String get pv2SoonTitle => 'Sắp mở đăng ký trong app';

  @override
  String get pv2SoonBody =>
      'Gói và giá như trên. Bạn sẽ đăng ký được ngay trong Child Life.';

  @override
  String get pv2HasPremium => 'Nhà mình đã có Premium';

  @override
  String get pv2OpenFamilyPlan => 'Xem gói của gia đình';

  @override
  String pv2ManagedBy(String name) {
    return 'Gói của nhà do $name quản lý';
  }

  @override
  String pv2OnlyManager(String name) {
    return 'Chỉ $name có thể nâng cấp cho cả nhà';
  }

  @override
  String pv2AskManager(String name) {
    return 'Nhờ $name nâng cấp';
  }

  @override
  String pv2AskPrivacy(String name) {
    return '$name chỉ nhận lời nhắn ngắn, không thấy bản nháp hay câu hỏi của bạn.';
  }

  @override
  String get pv2AskMessage =>
      'Mình muốn dùng Child Life Premium cho cả nhà. Bạn nâng cấp giúp mình trong Tôi › Gói của gia đình nhé.';

  @override
  String get pv2TheManager => 'người quản lý';

  @override
  String get pv2PlanTitle => 'Gói của gia đình';

  @override
  String get pv2InUse => 'Đang dùng';

  @override
  String pv2ManagerYou(String name) {
    return 'Người quản lý: $name (bạn)';
  }

  @override
  String pv2ManagerOther(String name) {
    return 'Quản lý bởi $name';
  }

  @override
  String get pv2LimitsTitle => 'Hạn mức';

  @override
  String get pv2Lumi => 'Lumi';

  @override
  String get pv2LumiTrial => 'Lumi · trải nghiệm';

  @override
  String get pv2Video => 'Video kỷ niệm';

  @override
  String get pv2VideoTrial => 'Video · trải nghiệm';

  @override
  String get pv2Storage => 'Dung lượng';

  @override
  String pv2CreditsLeft(int left, int limit) {
    return 'còn $left / $limit lượt';
  }

  @override
  String pv2ExportsLeft(int left, int limit) {
    return 'còn $left / $limit lượt';
  }

  @override
  String pv2StorageOf(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String pv2RefillOn(String date) {
    return 'Cấp lại $date';
  }

  @override
  String get pv2TrialOnce => 'Dùng một lần, không cấp lại';

  @override
  String get pv2NextRefill => 'Bổ sung tiếp';

  @override
  String pv2NextRefillValue(String date) {
    return '$date · mỗi tháng theo ngày đăng ký';
  }

  @override
  String get pv2Renews => 'Gia hạn';

  @override
  String get pv2IfCancel => 'Nếu huỷ';

  @override
  String pv2IfCancelValue(String date) {
    return 'Premium còn tới $date; sau đó về Free. Kỷ niệm, nhật ký, video đã xuất vẫn xem và tải được.';
  }

  @override
  String pv2FreeUpsellTitle(String name) {
    return 'Mỗi tháng, thêm một câu chuyện của $name';
  }

  @override
  String get pv2FreeUpsellBody =>
      'Thêm credit Lumi hằng tháng, mẫu cao cấp, video Full HD và dung lượng chung cho cả nhà.';

  @override
  String get pv2BuyStorage => 'Mua thêm dung lượng';

  @override
  String get pv2HistoryMine => 'Lịch sử sử dụng của tôi';

  @override
  String get pv2HistorySub => 'Theo người và tác vụ';

  @override
  String get pv2ManageRenewal => 'Quản lý gia hạn';

  @override
  String pv2OpenStore(String store) {
    return 'Mở $store';
  }

  @override
  String pv2MemberNote(String name) {
    return 'Chỉ $name có thể đổi, gia hạn hoặc huỷ gói. Bạn vẫn dùng mọi quyền lợi của gói.';
  }

  @override
  String get pv2Seats => 'Người ghi';

  @override
  String pv2SeatsOf(int used, int limit) {
    return '$used / $limit chỗ';
  }

  @override
  String pv2DowngradedBanner(String date) {
    return 'Nhà mình đã về Free từ $date. Không có gì bị xoá.';
  }

  @override
  String get pv2DowngradedBannerNoDate =>
      'Nhà mình đang dùng Free. Không có gì bị xoá.';

  @override
  String pv2OverStorageTitle(String used, String limit) {
    return 'Vượt dung lượng · $used / $limit';
  }

  @override
  String pv2OverStorageBody(String limit) {
    return 'Mọi ảnh, video vẫn xem và tải về được. Tạm dừng tải ảnh mới cho tới khi dưới $limit.';
  }

  @override
  String pv2OverSeatsTitle(int used, int limit) {
    return 'Vượt chỗ người ghi · $used / $limit';
  }

  @override
  String pv2OverSeatsBody(int limit) {
    return 'Chọn $limit người giữ quyền ghi chăm sóc. Người còn lại tạm chỉ xem, không bị xoá.';
  }

  @override
  String get pv2ChoosePeople => 'Chọn người';

  @override
  String get pv2ExportData => 'Xuất dữ liệu';

  @override
  String get pv2UpgradeAgain => 'Nâng lại Premium';

  @override
  String get pv2SuspendedNote =>
      'Bạn đang tạm chỉ xem vì gói Free có ít chỗ người ghi hơn. Mọi thứ vẫn còn nguyên.';

  @override
  String get pv2FilterAll => 'Tất cả';

  @override
  String get pv2FilterLumi => 'Lumi';

  @override
  String get pv2FilterVideo => 'Video';

  @override
  String get pv2FilterGrants => 'Cấp & hoàn';

  @override
  String get pv2HistoryEmpty => 'Chưa có gì được dùng.';

  @override
  String get pv2HistoryError => 'Chưa tải được lịch sử. Thử lại khi có mạng.';

  @override
  String get pv2HistoryPrivacy =>
      'Chỉ hiện người, loại tác vụ và số lượng. Nội dung câu hỏi và trả lời không hiển thị ở đây.';

  @override
  String get pv2System => 'Hệ thống';

  @override
  String get pv2Someone => 'Thành viên';

  @override
  String get pv2TaskLumiChat => 'Lumi · Hỏi đáp';

  @override
  String get pv2TaskLumiSummary => 'Lumi · Tóm tắt hôm nay';

  @override
  String get pv2TaskLumiPhoto => 'Lumi · Đọc ảnh';

  @override
  String get pv2TaskVideoExport => 'Video · Xuất video';

  @override
  String get pv2TaskLumiTrial => 'Credit trải nghiệm';

  @override
  String get pv2TaskLumiCycle => 'Cấp credit tháng';

  @override
  String get pv2TaskVideoTrial => 'Lượt video trải nghiệm';

  @override
  String get pv2TaskVideoCycle => 'Cấp lượt video tháng';

  @override
  String get pv2TaskLumiGrant => 'Thêm credit từ hỗ trợ';

  @override
  String get pv2TaskVideoGrant => 'Thêm lượt video từ hỗ trợ';

  @override
  String get pv2TaskRefundLumi => 'Hoàn credit · lỗi';

  @override
  String get pv2TaskRefundVideo => 'Hoàn lượt video';

  @override
  String pv2AmountExports(String amount) {
    return '$amount lượt';
  }

  @override
  String get pv2Held => 'đang giữ';

  @override
  String pv2Month(String month) {
    return 'Tháng $month';
  }

  @override
  String get pv2PickTitle => 'Ai giữ quyền ghi chăm sóc?';

  @override
  String pv2PickBody(int limit) {
    return 'Gói hiện tại có $limit chỗ. Người không chọn vẫn xem được mọi thứ và quay lại khi nhà mình nâng gói.';
  }

  @override
  String pv2PickManager(String relation) {
    return '$relation · người quản lý';
  }

  @override
  String pv2PickSave(int chosen, int limit) {
    return 'Lưu · $chosen/$limit';
  }

  @override
  String get pv2PickSaved => 'Đã lưu. Người không chọn sẽ nhận thông báo nhẹ.';

  @override
  String get pv2PickFailed => 'Chưa lưu được. Thử lại nhé.';

  @override
  String pv2You(String name) {
    return '$name (bạn)';
  }

  @override
  String get pv2CancelTitle => 'Huỷ gia hạn Premium';

  @override
  String pv2CancelLead(String date) {
    return 'Premium vẫn dùng được tới hết $date.';
  }

  @override
  String get pv2CancelLeadNoDate => 'Premium vẫn dùng được tới hết kỳ đã trả.';

  @override
  String get pv2CancelAfter => 'Sau ngày đó, nhà mình về Free';

  @override
  String get pv2CancelKeep => 'Giữ nguyên';

  @override
  String get pv2CancelKeepBody => 'Kỷ niệm, nhật ký, video đã xuất, thành viên';

  @override
  String pv2CancelStorage(String used, String free) {
    return 'Dung lượng $used > $free';
  }

  @override
  String get pv2CancelStorageBody =>
      'Không xoá; tạm dừng tải ảnh mới cho tới khi dọn hoặc nâng lại';

  @override
  String pv2CancelSeats(int used, int free) {
    return '$used người ghi > $free chỗ';
  }

  @override
  String pv2CancelSeatsBody(int free) {
    return 'Không xoá ai; bạn chọn $free người giữ quyền ghi';
  }

  @override
  String get pv2CancelTemplates => 'Bản nháp dùng mẫu Premium';

  @override
  String get pv2CancelTemplatesBody =>
      'Giữ bản nháp; xuất cần Premium hoặc đổi sang mẫu miễn phí';

  @override
  String get pv2KeepPremium => 'Giữ Premium';

  @override
  String pv2ContinueCancel(String store) {
    return 'Tiếp tục huỷ trong $store';
  }

  @override
  String get pv2AddOnHead => 'Thêm chỗ cho những ngày con lớn lên.';

  @override
  String get pv2AddOnUsing => 'Đang dùng';

  @override
  String get pv2AddOnUsed => 'Đã dùng';

  @override
  String pv2AddOnOption(int gb) {
    return 'Thêm $gb GB';
  }

  @override
  String pv2AddOnTotal(int gb) {
    return 'Tổng $gb GB cho cả nhà';
  }

  @override
  String pv2PerYear(String price) {
    return '$price/năm';
  }

  @override
  String pv2OrPerMonth(String price) {
    return 'hoặc $price/tháng';
  }

  @override
  String get pv2AddOnNote =>
      'Dùng chung cho cả gia đình · gia hạn cùng kỳ với Premium · huỷ bất cứ lúc nào.';

  @override
  String get pv2AddOnSoon =>
      'Sắp có · mua thêm dung lượng mở cùng lúc với đăng ký trong app.';

  @override
  String get pv2AddOnPremiumOnly =>
      'Mua thêm dung lượng dành cho gia đình có Premium.';

  @override
  String get pv2StoreApple => 'App Store';

  @override
  String get pv2StoreGoogle => 'Google Play';

  @override
  String get rhTriedAll => 'Tất cả';

  @override
  String get rhTriedStatTried => 'đã thử';

  @override
  String get rhTriedStatHelpful => 'có ích';

  @override
  String get rhTriedStatPlanned => 'sẽ thử';

  @override
  String get rhTriedNote =>
      'Theo câu trả lời của nhà mình, không phải kết luận y khoa.';

  @override
  String get pv2PlanPremium => 'Premium';

  @override
  String get pv2PlanFree => 'Free';

  @override
  String get pv2PaySoonTitle => 'Bước thanh toán sắp mở';

  @override
  String get pv2PaySoonBody =>
      'Đăng ký qua App Store / Google Play sẽ mở khi tài khoản cửa hàng của Child Life sẵn sàng. Gói và giá như bạn vừa xem.';

  @override
  String pv2AddOnBuy(int gb, String price) {
    return 'Thêm $gb GB · $price';
  }

  @override
  String pv2DemoVideoEnd(String name) {
    return 'Một tháng bên $name.';
  }

  @override
  String get pv2DemoMuted => '♪ bật tiếng';

  @override
  String get pv2DemoCardDate => '100 NGÀY · 25.11.2026';

  @override
  String get pv2DemoCardHello => 'Chào con yêu!';

  @override
  String get pv2DemoCardDays => '100 ngày';

  @override
  String get pv2DemoCardBorn => 'NGÀY SINH';

  @override
  String get pv2DemoCardSize => 'CÂN NẶNG · CHIỀU DÀI';

  @override
  String get pv2DemoCardThanks => 'Cảm ơn con đã đến bên ba mẹ';

  @override
  String get pv2DemoStyleMinimal => 'Tối giản';

  @override
  String get pv2DemoStylePlayful => 'Đáng yêu';

  @override
  String get pv2DemoStyleClassic => 'Cổ điển';

  @override
  String get pv2DemoLumiLast => 'Cữ gần nhất 13:10 · 120 ml (Ba ghi)';

  @override
  String get pv2DemoRhythm =>
      'Tuần này (13–19/10), giấc đêm đã ghi trung bình 9 giờ 10 — dài hơn 25 phút so với tuần trước (6–12/10).';

  @override
  String get pv2DemoUploading => '3 video đang tải lên';

  @override
  String get pv2DemoMum => 'Mẹ';

  @override
  String get pv2DemoMumDid => '09:10 · Đã ghi cữ bú 120 ml';

  @override
  String get pv2DemoDad => 'Ba';

  @override
  String get pv2DemoDadDid => '10:30 · Bắt đầu giấc ngủ';

  @override
  String get pv2DemoGran => 'Bà ngoại';

  @override
  String get pv2DemoGranDid => 'Đã xem cập nhật';

  @override
  String get pv2DemoCareNote =>
      'Free cũng có nhật ký chung; Premium thêm chỗ cho người ghi.';

  @override
  String get pv2Terms => 'Điều khoản sử dụng';

  @override
  String get pv2Privacy => 'Quyền riêng tư';

  @override
  String pv2HeadRhythm(String name) {
    return 'Hiểu nhịp của $name rõ hơn mỗi tuần';
  }

  @override
  String get pv2ReasonRhythm =>
      'Nhật ký tuần này vẫn được giữ · Lumi nhìn lại khi nhà mình có Premium.';

  @override
  String pv2DemoStorageFree(String gb) {
    return 'Free · $gb';
  }

  @override
  String pv2DemoStoragePremium(String gb) {
    return 'Premium · $gb';
  }

  @override
  String get pv2DemoStorageWaiting => '12 ảnh mới đang chờ được lưu';

  @override
  String get pv2RowRhythm => 'Hiểu nhịp con';

  @override
  String get pv2RowRhythmFree => 'Theo tuổi & lịch tham khảo';

  @override
  String get pv2RowRhythmPremium => 'Gợi ý riêng & nhịp nâng cao';

  @override
  String get axGreetMorningNoName => 'Chào buổi sáng ☀️';

  @override
  String get axGreetAfternoonNoName => 'Chào buổi chiều';

  @override
  String get axGreetEveningNoName => 'Chào buổi tối 🌙';

  @override
  String get axTilesLoading => 'Đang tải nhịp hôm nay';

  @override
  String get careLoadingRecords => 'Đang tải ghi chép';

  @override
  String get saveDiaper => 'Lưu lần thay tã';

  @override
  String get pv2PlanShared => 'Cả nhà dùng chung';

  @override
  String get axCustomizeHint => 'Kéo để đổi thứ tự. Ghim để luôn ở đầu.';

  @override
  String get rhCalendarNote =>
      'Lịch là mô hình tham khảo, chưa được chứng minh chính xác cho từng bé.';

  @override
  String get engMore => 'Tuỳ chọn gợi ý';

  @override
  String ksCardMissingPhotos(int n) {
    return 'Chọn thêm $n ảnh để lưu thiệp';
  }

  @override
  String get ksAddDevicePhotos => 'Thêm ảnh từ máy';

  @override
  String get ksCardSaveAudience => 'Lưu vào Kỷ niệm · Chỉ ba mẹ';

  @override
  String get autoSaveOnBetaFree => 'Đang bật · Beta miễn phí';

  @override
  String get p48InfoTab => 'Thông tin';

  @override
  String get p48TextTab => 'Lời nhắn';

  @override
  String get p48MediaTab => 'Ảnh & nhạc';

  @override
  String get p48PhotosTab => 'Ảnh';

  @override
  String get p48MoreDetails => 'Thêm chi tiết';

  @override
  String get p48OptionalDetails => 'Tuỳ chọn · Chỉ hiện khi bạn nhập';

  @override
  String get p48Settings => 'Tuỳ chỉnh';

  @override
  String get p48ClearValue => 'Xoá giá trị';

  @override
  String get autoSaveReviewTicked =>
      'App đã chọn sẵn ảnh rõ nhất. Bỏ chọn mục không muốn lưu.';

  @override
  String get premiumSharedPlans =>
      'Cả nhà dùng chung, dù chọn gói năm hay gói tháng.';

  @override
  String get premiumChoosePlan => 'Chọn gói';

  @override
  String get premiumBenefits => 'Premium có gì?';

  @override
  String get premiumMemories => 'Thiệp & video kỷ niệm';

  @override
  String get premiumMemoriesSubtitle => 'Toàn bộ mẫu cao cấp chất lượng cao';

  @override
  String get premiumRhythm => 'Gợi ý cá nhân & nhịp nâng cao';

  @override
  String get premiumRhythmSubtitle => 'Gợi ý theo nhu cầu và nhật ký của con';

  @override
  String get premiumTodayTotal => 'Thanh toán hôm nay';

  @override
  String get premiumBackToPlans => 'Quay lại chọn gói';

  @override
  String get premiumUnlimitedVideo => 'Xuất video không giới hạn lượt';

  @override
  String get premiumVideoFree => 'Mẫu cơ bản · Video 720p';

  @override
  String get premiumVideoPaid => 'Mọi mẫu · Full HD 1080p';

  @override
  String get premiumVideoDetail =>
      'Không giới hạn lượt xuất: Free 720p, Premium Full HD 1080p.';

  @override
  String get premiumFeatureIntro => 'Tìm hiểu Premium cho tính năng này';

  @override
  String get videoQuality => 'Chất lượng video';

  @override
  String get videoQualityHd => 'HD 720p';

  @override
  String get videoQualityFullHd => 'Full HD 1080p';

  @override
  String get videoQualityHdHint => 'Tệp nhẹ hơn, dễ chia sẻ';

  @override
  String get videoQualityFullHdHint => 'Hình ảnh rõ nét hơn';

  @override
  String get videoQualityPremiumHint => 'Cần Premium · Tìm hiểu';

  @override
  String get videoExportHd => 'Xuất video HD 720p';

  @override
  String get videoExportFullHd => 'Xuất video Full HD 1080p';

  @override
  String get videoFullHdIntroTitle => 'Xuất Full HD với Premium';

  @override
  String get videoFullHdIntroBody =>
      'Premium cho phép xuất video Full HD 1080p và dùng mọi mẫu cao cấp. Free vẫn xuất HD 720p không giới hạn lượt. Video đang làm được giữ nguyên.';

  @override
  String get videoContinueHd => 'Tiếp tục với HD 720p';

  @override
  String get premiumRhythmCompareFree => 'Theo tuổi & lịch tham khảo';

  @override
  String get premiumRhythmComparePaid => 'Gợi ý riêng & nhịp nâng cao';

  @override
  String get premiumStorageSubtitle =>
      'Dung lượng dùng chung cho ảnh và video của cả nhà';

  @override
  String get premiumSeatsSubtitle => 'Cùng ghi cữ bú, giấc ngủ và xem nhật ký';

  @override
  String get premiumNeedsPremium => 'Cần Premium';

  @override
  String get premiumUseTemplate => 'Dùng mẫu Premium';

  @override
  String get videoQualityChecking => 'Đang kiểm tra gói · Thử lại';

  @override
  String get videoRenderRateLimit =>
      'Bạn vừa gửi nhiều yêu cầu tạo video. Thử lại sau một phút nhé.';

  @override
  String get premiumPaymentDetails => 'Chi tiết thanh toán';

  @override
  String get premiumTaxIncluded => 'Giá đã gồm thuế.';

  @override
  String get premiumVideoAfterCancel =>
      'Video đã xuất giữ nguyên chất lượng. Video mới xuất HD 720p, không giới hạn lượt.';

  @override
  String get autoSaveSelectAll => 'Chọn hết';

  @override
  String get autoSaveDeselectAll => 'Bỏ chọn hết';

  @override
  String get autoSaveGroupBestOnly => 'Chỉ giữ ảnh rõ nhất';

  @override
  String autoSaveSavedSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã có trong Kỷ niệm · $count',
    );
    return '$_temp0';
  }

  @override
  String get autoSaveSavedHint => 'Không chọn sẵn. Mở ra để chọn nếu app nhầm.';

  @override
  String get premiumPlanCheckFailed => 'Chưa kiểm tra được gói gia đình';

  @override
  String get premiumPlanCheckFailedBody =>
      'Thử lại khi có kết nối nhé. Nội dung bạn đang làm vẫn được giữ.';

  @override
  String get autoSaveWeekSheet => 'Tuần tuổi';

  @override
  String get autoSaveKindSheet => 'Hiện';

  @override
  String get premiumRhythmDetail =>
      'Xem nhịp bú, ngủ khi nhật ký đủ dữ liệu. Gợi ý để tham khảo, không chẩn đoán bệnh.';

  @override
  String get videoPremiumChanged =>
      'Video này cần Premium đang còn hiệu lực. Bạn có thể đổi sang mẫu cơ bản và HD 720p; bản dựng vẫn được giữ.';

  @override
  String autoSaveWeekRowTitle(int n, String range) {
    return 'Tuần $n · $range';
  }

  @override
  String get autoSaveWeekRowBefore => 'Trước sinh';

  @override
  String autoSaveWeekRowProgress(int saved, int waiting) {
    return '$saved đã có trong Kỷ niệm · $waiting chờ bạn xem';
  }

  @override
  String autoSaveWeekRowWaiting(int waiting) {
    return '$waiting chờ bạn xem';
  }

  @override
  String autoSaveWeekRowDone(int saved) {
    return 'Đã xem hết · $saved trong Kỷ niệm';
  }

  @override
  String autoSaveAllWeeks(int count) {
    return 'Tất cả các tuần · $count';
  }

  @override
  String get autoSaveAllWeeksRow => 'Tất cả các tuần';

  @override
  String get autoSaveCheckingSpace => 'Đang kiểm tra dung lượng…';

  @override
  String get autoSaveFullTitle => 'Gia đình đã hết dung lượng';

  @override
  String autoSaveFullBody(int count, String need) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count mục cần khoảng $need. Thêm dung lượng để tải lên; các mục vẫn ở trong máy.',
    );
    return '$_temp0';
  }

  @override
  String autoSaveShortTitle(int fit, int count) {
    return 'Chỉ đủ chỗ cho $fit/$count mục';
  }

  @override
  String autoSaveShortBody(String need, String left) {
    return 'Cần khoảng $need, gia đình còn $left. Ảnh được tải trước video; phần còn lại vẫn ở trong máy.';
  }

  @override
  String autoSavePrepTitle(int done, int total) {
    return 'Đang chuẩn bị $done/$total';
  }

  @override
  String get autoSavePrepWaiting => 'Chờ';

  @override
  String get autoSavePrepWorking => 'Đang chuẩn bị';

  @override
  String get autoSavePrepQueued => 'Đã vào hàng tải';

  @override
  String get autoSavePrepFailed => 'Không đọc được tệp';

  @override
  String get autoSavePrepDone => 'Xong';

  @override
  String autoSavePrepSummary(int queued, int failed) {
    return '$queued mục đã vào hàng tải · $failed không đọc được';
  }

  @override
  String get qQuotaTitle => 'Hết dung lượng gia đình';

  @override
  String qQuotaBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count mục đang chờ, vẫn ở trong máy. Thêm dung lượng để tiếp tục tải.',
    );
    return '$_temp0';
  }

  @override
  String qDropWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bỏ $count mục khỏi hàng chờ',
    );
    return '$_temp0';
  }

  @override
  String qDropUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bỏ $count tệp không đọc được',
    );
    return '$_temp0';
  }

  @override
  String get qUnreadableHint =>
      'Máy không mở được các tệp này (có thể đã bị xoá hoặc hỏng).';

  @override
  String get autoSaveAddSpacePremium => 'Thêm dung lượng với Premium';

  @override
  String get autoSaveBuySpace => 'Mua thêm dung lượng';

  @override
  String get autoSaveManageSpace => 'Quản lý dung lượng';

  @override
  String get autoSavePremiumSpaceNote =>
      'Premium có thêm dung lượng cho cả nhà.';

  @override
  String careFailedNew(String record, String time) {
    return 'Chưa lưu được: $record, $time';
  }

  @override
  String careFailedEdit(String record, String time) {
    return 'Chưa lưu thay đổi: $record, $time';
  }

  @override
  String careFailedDelete(String record, String time) {
    return 'Chưa xoá được: $record, $time';
  }

  @override
  String careFailedRestore(String record, String time) {
    return 'Chưa khôi phục được: $record, $time';
  }

  @override
  String get careFailedTimer => 'Chưa lưu được thay đổi của bộ đếm';

  @override
  String careFailedDenied(String message) {
    return '$message. Có thể quyền của bạn đã thay đổi.';
  }

  @override
  String get retryRefused =>
      'Có thay đổi không lưu được. Có thể quyền của bạn đã thay đổi.';

  @override
  String pendingOthers(int count) {
    return '$count thay đổi khác (xoá, sửa, bộ đếm) chờ gửi';
  }

  @override
  String get careLoadFailed => 'Chưa tải được nhật ký';

  @override
  String get todayLoadFailedBody =>
      'Lần ghi gần nhất chưa hiện. Bạn vẫn ghi mới được.';

  @override
  String get statsTodayFrom18 => 'Tính từ 18:00 hôm qua, gồm cả cữ đêm';

  @override
  String get hoLoading => 'Đang tải nhật ký của bé';

  @override
  String get hoRemindersFailed => 'Chưa tải được việc đã hẹn';

  @override
  String get hoHealthFailed => 'Chưa tải được dấu hiệu sức khoẻ';

  @override
  String get hoNotFoundTitle => 'Bản bàn giao này không còn';

  @override
  String get hoNotFoundBody => 'Có thể đã có bản mới hơn thay thế.';

  @override
  String get hoSeeLatest => 'Xem bản mới nhất';

  @override
  String get hoCreateNew => 'Tạo bản mới';

  @override
  String get hoCreateTitle => 'Chưa có bản tóm tắt';

  @override
  String get hoCreateBody =>
      'Tóm tắt từ ghi nhận của cả nhà mấy ngày qua. Mỗi lần tạo dùng tối đa 1 lượt AI.';

  @override
  String get hoCreateAction => 'Tạo bản tóm tắt';

  @override
  String get aiStateFailedOffline =>
      'Cần kết nối mạng để tạo. Ghi nhận của nhà mình vẫn giữ nguyên.';

  @override
  String get aiStateQuotaOut => 'Nhà mình đã dùng hết lượt AI trong kỳ này.';

  @override
  String get aiStatePremiumOnly =>
      'Tóm tắt bằng AI nằm trong Child Life Premium.';

  @override
  String get aiStateUnavailable => 'AI chưa dùng được cho nhà mình lúc này.';

  @override
  String aiStateQuotaDayNoDate(int used, int limit) {
    return 'Đã dùng $used/$limit lượt AI hôm nay cho bé. Bạn vẫn xem được bản theo mẫu.';
  }

  @override
  String aiStateQuotaMonthNoDate(int used, int limit) {
    return 'Nhà mình đã dùng $used/$limit lượt AI kỳ này (chung cho tóm tắt và trợ lý). Bạn vẫn xem được bản theo mẫu.';
  }

  @override
  String get aiSendFailedOther => 'Chưa gửi được bàn giao. Thử lại sau.';

  @override
  String get aiMomentAsk => 'Viết lời gợi ý bằng AI';

  @override
  String get aiMomentFailed => 'Chưa viết được lời gợi ý lúc này.';

  @override
  String get engWeekFailed => 'Chưa mở được bản nhìn lại tuần này';

  @override
  String get engWeekMediaFailed => 'Chưa tải được ảnh của tuần';

  @override
  String get engWeekEmpty =>
      'Ảnh và câu chuyện của tuần này không còn trong Kỷ niệm.';

  @override
  String get engOpenFailed => 'Chưa mở được gợi ý. Thử lại sau.';

  @override
  String get engActFailed => 'Chưa lưu được lựa chọn. Thử lại sau.';

  @override
  String get stLoadFailedTitle => 'Chưa tải được dung lượng';

  @override
  String get stQuotaUnknown => 'Chưa kiểm tra được dung lượng của gói';

  @override
  String stReserved(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
    );
    return 'Đang giữ chỗ $size cho $_temp0 đang tải lên';
  }

  @override
  String get stFreeUpVideos => 'Xoá bớt video lớn';

  @override
  String get stRowFailed => 'Chưa tải được';

  @override
  String pv2AskStorage(String name) {
    return 'Nhờ $name thêm dung lượng';
  }

  @override
  String get pv2AskStorageMessage =>
      'Nhà mình sắp hết dung lượng Child Life. Bạn thêm dung lượng giúp mình trong Tôi › Gói của gia đình nhé.';

  @override
  String get pv2AddOnUnknown => 'Chưa tải được các gói dung lượng';

  @override
  String pv2OptionOr(String a, String b) {
    return '$a hoặc $b';
  }

  @override
  String pv2E08BodyPremiumPlain(int pct, String gb) {
    return 'Đã dùng $pct% của $gb GB.';
  }

  @override
  String get pv2ManagerYouNoName => 'Bạn quản lý gói này';

  @override
  String get pv2FreeUpsellTitleNoName =>
      'Mỗi tháng, thêm một câu chuyện của bé';

  @override
  String get pv2PriceUnknown => 'Chưa tải được giá. Thử lại khi có kết nối.';

  @override
  String get pv2SubscribeNoPrice => 'Đăng ký Premium';

  @override
  String pv2BusyBuying(String store) {
    return 'Đang mở $store…';
  }

  @override
  String get pv2BusyVerifying => 'Đang xác nhận giao dịch…';

  @override
  String get pv2BusyRestoring => 'Đang khôi phục…';

  @override
  String get pv2BusyPending => 'Đang chờ cửa hàng xác nhận';

  @override
  String get pmStoreLoadFailed => 'Chưa kết nối được cửa hàng. Thử lại sau.';

  @override
  String get psExportQueued => 'Đang chuẩn bị dựng file in…';

  @override
  String psExportProgress(int done, int total) {
    return 'Đang dựng file in · trang $done/$total';
  }

  @override
  String get psExportLeave =>
      'Bạn có thể rời màn hình này. Quay lại đây để mở file khi xong.';

  @override
  String get psExportFailed => 'Chưa dựng được file in. Thử lại nhé.';

  @override
  String get psExportBannerReady => 'File in đã sẵn sàng · Mở';

  @override
  String psExportFiles(int pages, String format) {
    return '$pages trang · $format';
  }

  @override
  String psCountryUnsupported(String country) {
    return 'Child Life chưa giao bản in tới $country.';
  }

  @override
  String psCountryUnsupportedDigital(String country) {
    return 'Child Life chưa giao bản in tới $country. Bạn có thể tải file in để in ở nơi gần bạn.';
  }

  @override
  String get psPayByTransfer => 'Chuyển khoản sau khi Child Life xác nhận';

  @override
  String get psPayTransferRow => 'Chuyển khoản';

  @override
  String get psOrderMaybeSent =>
      'Chưa nhận được phản hồi. Có thể đơn đã được ghi nhận — xem Đơn in trước khi đặt lại.';

  @override
  String get psViewOrders => 'Xem Đơn in';

  @override
  String get psOrderNotFound => 'Không tìm thấy đơn in này';

  @override
  String get psOrderNotFoundHelp =>
      'Đơn có thể thuộc tài khoản khác hoặc chưa tải xong.';

  @override
  String get psStatusUnknown => 'Đang cập nhật trạng thái';

  @override
  String get psOrderCancelledToast => 'Đã huỷ đơn in';

  @override
  String get premiumYearSuffix => '/năm';

  @override
  String get premiumMonthSuffix => '/tháng';

  @override
  String premiumSavePercent(int n) {
    return 'Tiết kiệm $n%';
  }

  @override
  String get premiumLumiListTitle => 'Trợ lý Lumi';

  @override
  String premiumStorageListTitle(String gb) {
    return '$gb cho cả nhà';
  }

  @override
  String premiumSeatsListTitle(int n) {
    return '$n người có quyền ghi';
  }

  @override
  String premiumLegalIntro(String store) {
    return 'Tự động gia hạn. Huỷ bất cứ lúc nào trong $store. Khi đăng ký, bạn đồng ý với ';
  }

  @override
  String get premiumPaymentEquivalent => 'Tương đương mỗi tháng';

  @override
  String get premiumPaymentSaving => 'Tiết kiệm so với 12 tháng trả theo tháng';

  @override
  String get premiumPaymentTax => 'Thuế';

  @override
  String get premiumPaymentTaxValue => 'Đã gồm trong giá';

  @override
  String premiumPaymentRenewal(String price, String store) {
    return 'Tự động gia hạn $price. Muốn huỷ, hãy huỷ trong $store ít nhất 24 giờ trước ngày gia hạn.';
  }

  @override
  String get premiumMemoriesBullet1 =>
      'Thiệp: mẫu cao cấp, thêm ảnh, tên và lời nhắn.';

  @override
  String get premiumMemoriesBullet2 => 'Video: ghép ảnh cùng lời nhắn và nhạc.';

  @override
  String get premiumLumiBullet1 =>
      'Hỏi về nhật ký và xem dữ liệu Lumi dùng để trả lời.';

  @override
  String get premiumLumiBullet2 =>
      'Nhờ Lumi soạn bản ghi để bạn kiểm tra trước khi lưu.';

  @override
  String premiumLumiBullet3(int n) {
    return '$n credit/tháng dùng chung cho cả nhà, được cấp mỗi tháng.';
  }

  @override
  String get premiumRhythmBullet1 =>
      'Gợi ý theo tuổi, nhu cầu và phản hồi của bạn.';

  @override
  String get premiumRhythmBullet2 => 'Xem nhịp bú, ngủ khi nhật ký đủ dữ liệu.';

  @override
  String get premiumRhythmBullet3 => 'Hiểu con hơn mỗi ngày.';

  @override
  String premiumStorageBullet1(String gb) {
    return '$gb cho ảnh và video của cả gia đình.';
  }

  @override
  String get premiumStorageBullet2 => 'Xem mức sử dụng trong Gói của gia đình.';

  @override
  String get premiumStorageBullet3 => 'Mua thêm dung lượng: Sắp có.';

  @override
  String get premiumSeatsBullet1 => 'Cùng ghi cữ bú, giấc ngủ và xem cập nhật.';

  @override
  String get premiumSeatsBullet2 =>
      'Quyền xem và ghi theo vai trò của từng người.';

  @override
  String premiumSeatsBullet3(int n) {
    return 'Thoải mái cùng $n người chăm con';
  }

  @override
  String get premiumRhythmPager => 'Gợi ý & nhịp nâng cao';

  @override
  String get premiumSeatsPager => 'Người có quyền ghi';

  @override
  String get premiumSubscribeYearShort => 'Đăng ký gói năm';

  @override
  String get premiumSubscribeMonthShort => 'Đăng ký gói tháng';

  @override
  String premiumLumiCompareFree(int n) {
    return '$n credit dùng thử · không cấp lại';
  }

  @override
  String premiumLumiComparePaid(int n) {
    return '$n credit/tháng · cả nhà dùng chung';
  }

  @override
  String premiumSeatsCardLimit(int free, int premium) {
    return '$premium người có quyền ghi · Free: $free';
  }

  @override
  String get premiumLumiPager => 'Hỏi Lumi';

  @override
  String get premiumLumiDetailTitle => 'Hỏi Lumi mọi thứ về con';

  @override
  String get premiumRhythmDetailTitle =>
      'Gợi ý cá nhân và nhịp nâng cao của con';

  @override
  String get premiumMemoriesBullet3 =>
      'Không giới hạn lượt xuất chất lượng cao';

  @override
  String hhMorning(String name) {
    return 'Chào ngày mới cùng $name';
  }

  @override
  String get hhMorningNoName => 'Chào ngày mới';

  @override
  String hhAfternoon(String name) {
    return 'Một ngày của $name thế nào rồi?';
  }

  @override
  String get hhAfternoonNoName => 'Ngày của bé thế nào rồi?';

  @override
  String hhEvening(String name) {
    return 'Chào buổi tối, $name';
  }

  @override
  String get hhEveningNoName => 'Chào buổi tối';

  @override
  String hhBirthday(String name) {
    return 'Mừng sinh nhật $name!';
  }

  @override
  String hhDutyNow(String name) {
    return '$name đang trông bé';
  }

  @override
  String hhDutySince(String time) {
    return 'Hiện tại · từ $time';
  }

  @override
  String get hhDutyRetry => 'Chưa tải được trạng thái trông bé · Thử lại';

  @override
  String get hhSettings => 'Cài đặt giao diện';

  @override
  String get hhSettingsSubtitle => 'Hình nền đầu trang Hôm nay';

  @override
  String get hhWallpaper => 'Hình nền';

  @override
  String get hhPreview => 'Xem trước';

  @override
  String get hhPattern => 'Hoạ tiết theo buổi';

  @override
  String get hhAvatar => 'Ảnh đại diện của bé';

  @override
  String get hhChooseMemory => 'Chọn ảnh từ Kỷ niệm';

  @override
  String get hhPhotoEmpty => 'Chưa có ảnh để chọn trong Kỷ niệm.';

  @override
  String get hhDeviceOnly => 'Chỉ áp dụng trên thiết bị này cho bé đang chọn.';

  @override
  String get hhApply => 'Áp dụng';

  @override
  String get hhSaveFailed => 'Chưa lưu được giao diện. Bạn thử lại nhé.';

  @override
  String get hhHeaderSection => 'Trong đầu trang';

  @override
  String get hhDutyFixed => 'Trạng thái trông bé nằm cố định trong đầu trang.';

  @override
  String get hhAvatarMissing => 'Bé chưa có ảnh đại diện; tạm dùng hoạ tiết.';

  @override
  String get hhSelected => 'Đang chọn';

  @override
  String get dutyParents => 'Ba và Mẹ';

  @override
  String get dutyTogether => 'Ba và Mẹ cùng trông';

  @override
  String get dutyTogetherToast =>
      'Ba và Mẹ đang cùng trông bé. Cả nhà sẽ thấy.';

  @override
  String get dutyJustStarted => 'Vừa bắt đầu';

  @override
  String get dutyPrevious => 'Trước đó';

  @override
  String get dutyLoadFailed => 'Chưa tải được trạng thái trông bé.';

  @override
  String get dutyOwnPart =>
      'Kết thúc phần của bạn; người còn lại vẫn đang trông bé.';

  @override
  String dutyStartedAt(String time) {
    return 'Từ $time';
  }

  @override
  String get dutyTogetherNow => 'Ba và Mẹ đang cùng trông bé';

  @override
  String dutyTogetherSince(String time) {
    return 'Ba và Mẹ cùng trông · từ $time';
  }

  @override
  String get dutyYouNow => 'Bạn đang trông bé';

  @override
  String dutyYouSince(String time) {
    return 'Bạn đang trông · từ $time';
  }

  @override
  String get todayOtherAmount => 'Khác';

  @override
  String get todayDiaperBoth => 'Cả hai';

  @override
  String get todayStartSleep => 'Bắt đầu ngủ';

  @override
  String get todayViewSession => 'Xem phiên đang chạy';

  @override
  String get pv2LoadingPrices => 'Đang tải giá Premium…';

  @override
  String get pv2PriceLoadFailed => 'Chưa tải được giá Premium';

  @override
  String get pv2PriceLoadFailedBody => 'Kiểm tra kết nối rồi thử lại.';

  @override
  String get cpTitle => 'Cùng Chăm Con';

  @override
  String get cpExploreSub => 'Lịch chăm bé chung, giao việc cho cả nhà';

  @override
  String cpDayTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc',
    );
    return '$_temp0';
  }

  @override
  String get cpAllDone => 'Xong hết việc hôm nay';

  @override
  String cpProgressA11y(int done, int total) {
    return 'Đã làm $done trên $total việc';
  }

  @override
  String get cpMorning => 'Sáng';

  @override
  String get cpAfternoon => 'Chiều';

  @override
  String get cpEvening => 'Tối';

  @override
  String get cpAssignGroup => 'Giao cả ca';

  @override
  String get cpAddTask => 'Thêm việc';

  @override
  String get cpAssignShort => 'Giao';

  @override
  String cpMarkDone(String task) {
    return 'Đánh dấu đã làm: $task';
  }

  @override
  String cpMarkOpen(String task) {
    return 'Đã làm: $task. Chạm để bỏ đánh dấu';
  }

  @override
  String cpDoneToast(String task) {
    return 'Đã làm · $task';
  }

  @override
  String get cpSkipped => 'Bỏ qua hôm nay';

  @override
  String get cpEveryDay => 'Mọi ngày';

  @override
  String get cpTodayOnly => 'Chỉ hôm nay';

  @override
  String get cpSaveFailed => 'Chưa lưu được. Kiểm tra mạng rồi thử lại.';

  @override
  String get cpLoadFailed => 'Chưa tải được lịch. Kiểm tra mạng rồi thử lại.';

  @override
  String get cpSwipeHint => 'Vuốt sang trái để sửa hoặc xoá';

  @override
  String get cpGotIt => 'Đã hiểu';

  @override
  String get cpEmptyToday => 'Hôm nay chưa có lịch';

  @override
  String get cpEmptyDay => 'Ngày này chưa có lịch';

  @override
  String get cpEmptyViewer => 'Khi ba mẹ lên lịch, việc sẽ hiện ở đây.';

  @override
  String get cpStartEveryday => 'Dùng lịch mọi ngày';

  @override
  String get cpStartYesterday => 'Giống hôm qua';

  @override
  String get cpStartEmpty => 'Tự thêm việc';

  @override
  String get cpAssignWhoMorning => 'Giao ca sáng cho ai?';

  @override
  String get cpAssignWhoAfternoon => 'Giao ca chiều cho ai?';

  @override
  String get cpAssignWhoEvening => 'Giao ca tối cho ai?';

  @override
  String get cpAssignWhoTask => 'Ai làm việc này?';

  @override
  String cpMemberLoad(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc hôm nay',
      zero: 'Chưa có việc hôm nay',
    );
    return '$_temp0';
  }

  @override
  String cpAssignTo(String names) {
    return 'Giao cho $names';
  }

  @override
  String get cpAssignNobody => 'Để trống người làm';

  @override
  String cpNamesTwo(String first, String second) {
    return '$first và $second';
  }

  @override
  String cpNamesMore(String first, int count) {
    return '$first và $count người';
  }

  @override
  String get cpCustomName => 'Tên việc';

  @override
  String get cpCustomHint => 'VD: nhỏ mũi';

  @override
  String get cpTime => 'Giờ';

  @override
  String get cpWho => 'Ai làm';

  @override
  String get cpSkipToday => 'Bỏ qua hôm nay';

  @override
  String get cpUnskip => 'Làm lại việc này hôm nay';

  @override
  String cpSkipToast(String task) {
    return 'Đã bỏ qua · $task';
  }

  @override
  String get cpDelete => 'Xoá việc';

  @override
  String cpDeleteTitle(String task) {
    return 'Xoá $task?';
  }

  @override
  String get cpDeleteToday => 'Chỉ xoá hôm nay';

  @override
  String get cpDeleteEveryDay => 'Xoá cả những ngày sau';

  @override
  String get cpDeleteBody =>
      'Việc đã ghi trong nhật ký chăm sóc vẫn giữ nguyên.';

  @override
  String cpDeletedToast(String task) {
    return 'Đã xoá · $task';
  }

  @override
  String get cpSuggested => 'Hay dùng';

  @override
  String get cpTaskBottle => 'Bú bình';

  @override
  String get cpTaskBreast => 'Bú mẹ';

  @override
  String get cpTaskPump => 'Hút sữa';

  @override
  String get cpTaskSolids => 'Ăn dặm';

  @override
  String get cpTaskWater => 'Uống nước';

  @override
  String get cpTaskSleep => 'Ngủ';

  @override
  String get cpTaskDiaper => 'Thay tã';

  @override
  String get cpTaskBath => 'Tắm';

  @override
  String get cpTaskTummy => 'Nằm sấp';

  @override
  String get cpTaskRead => 'Đọc sách';

  @override
  String get cpTaskWalk => 'Đi dạo';

  @override
  String get cpTaskVitamin => 'Vitamin';

  @override
  String get cpTaskMedicine => 'Uống thuốc';

  @override
  String get cpTaskTemperature => 'Đo nhiệt độ';

  @override
  String get cpTaskTeeth => 'Đánh răng';

  @override
  String get cpTaskPotty => 'Ngồi bô';

  @override
  String get cpTaskCustom => 'Việc riêng';

  @override
  String cpHomeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc cần làm',
    );
    return '$_temp0';
  }

  @override
  String get cpHomeAll => 'Tất cả';

  @override
  String get cpDoneAction => 'Đã làm';

  @override
  String get cpDueTitle => 'Đến giờ rồi';

  @override
  String get cpDueLater => 'Để sau 10 phút';

  @override
  String get cpDueSeeDay => 'Xem cả lịch hôm nay';

  @override
  String cpDueDoneAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã làm cả $count việc',
    );
    return '$_temp0';
  }

  @override
  String cpDoneManyToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã làm $count việc',
    );
    return '$_temp0';
  }

  @override
  String get cpDueGone => 'Việc này đã xong hoặc đã được bỏ qua';

  @override
  String get cpRemindTitle => 'Nhắc việc chăm con';

  @override
  String get cpRemindBefore => 'Nhắc trước';

  @override
  String cpLeadMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String cpLeadValue(int minutes) {
    return 'Trước $minutes phút';
  }

  @override
  String get cpQuietHours => 'Nhắc cả trong giờ yên lặng';

  @override
  String get ntCareTasks => 'Việc chăm con';

  @override
  String cpHelperOnUntil(String name, String time) {
    return '$name đang trông · đến $time';
  }

  @override
  String cpShiftHello(String name) {
    return 'Chào $name';
  }

  @override
  String cpShiftLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count việc trong ca',
    );
    return '$_temp0';
  }

  @override
  String get cpShiftAllDone => 'Xong hết việc trong ca';

  @override
  String get cpShiftStart => 'Bắt đầu ca';

  @override
  String cpShiftOnSince(String time) {
    return 'Đang trông từ $time';
  }

  @override
  String get cpMyTasks => 'Việc của tôi';

  @override
  String get cpNotesTitle => 'Ghi chú cho bố mẹ';

  @override
  String get cpNoteAteWell => 'Ăn ngon';

  @override
  String get cpNoteFussy => 'Quấy nhẹ';

  @override
  String get cpNoteSleptWell => 'Ngủ sâu';

  @override
  String get cpNoteSmiles => 'Cười nhiều';

  @override
  String get cpNoteMore => 'Viết thêm…';

  @override
  String get cpHandoverToParents => 'Bàn giao cho bố mẹ';

  @override
  String hoToParents(String names) {
    return 'Bàn giao cho $names';
  }

  @override
  String hoShiftEnds(String time) {
    return 'Hết ca $time';
  }

  @override
  String get hoInShift => 'Trong ca';

  @override
  String hoShiftFeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cữ',
    );
    return '$_temp0';
  }

  @override
  String hoShiftDiapers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần',
    );
    return '$_temp0';
  }

  @override
  String hoShiftDirty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'đi ngoài $count',
    );
    return '$_temp0';
  }

  @override
  String get hoShiftFeedLabel => 'Bú';

  @override
  String get hoShiftSleepLabel => 'Ngủ';

  @override
  String get hoShiftDiaperLabel => 'Tã';

  @override
  String get cpRemainingTitle => 'Việc còn lại hôm nay';

  @override
  String get hoMessage => 'Lời nhắn';

  @override
  String get hoMessageAdd => 'Viết lời nhắn';

  @override
  String get hoSendToParents => 'Gửi cho bố mẹ';

  @override
  String hoSentToFamily(String name, String time) {
    return '$name gửi cho cả nhà · $time';
  }

  @override
  String get cpRhythmNotReady => 'Chưa đủ 7 ngày có ghi cả bú và ngủ';

  @override
  String get cpStartEasy35 => 'EASY 3.5';

  @override
  String get cpStartEasy4 => 'EASY 4';

  @override
  String get cpTemplatesNote =>
      'Lịch mẫu không phải lịch y tế. Bú và ngủ luôn có thể khác dự kiến.';

  @override
  String get cpDraftUse => 'Dùng lịch này';

  @override
  String get cpDraftChange => 'Đổi cách khác';

  @override
  String get cpDraftUsed => 'Đã dùng lịch hôm nay';

  @override
  String get cpAutoDraft => 'Tự tạo lịch mỗi sáng';

  @override
  String cpTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hôm nay có $count việc',
    );
    return '$_temp0';
  }

  @override
  String cpFirstTask(String time, String task) {
    return 'Việc đầu tiên $time · $task';
  }

  @override
  String cpPersonCount(String name, int count) {
    return '$name · $count';
  }

  @override
  String cpPersonDone(String name, int count) {
    return '$name xong $count';
  }

  @override
  String cpLeftCheer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count việc nữa thôi, cả nhà cố lên!',
    );
    return '$_temp0';
  }

  @override
  String get cpStartSub => 'Tạo nhanh trong 1 chạm, sửa sau cũng được';

  @override
  String cpStartRhythmOf(String name) {
    return 'Theo nhịp $name';
  }

  @override
  String get cpChosen => 'Đã chọn';

  @override
  String get cpChosenSub => 'Cách cả nhà chọn lúc đầu';

  @override
  String get cpCreateToday => 'Tạo lịch hôm nay';

  @override
  String get cpCreateDay => 'Tạo lịch';

  @override
  String cpChooseTitle(String name) {
    return 'Lên lịch cho $name';
  }

  @override
  String get cpSuggestBadge => 'Gợi ý';

  @override
  String get cpRhythmFrom => 'Từ 7 ngày ghi nhận';

  @override
  String get cpEasySection => 'Theo EASY';

  @override
  String get cpEasy35Sub => '6 tuần – 4 tháng · 3–4 giấc';

  @override
  String get cpEasy4Sub => '4 – 6 tháng · 3 giấc';

  @override
  String get cpFitsAge => 'Hợp tuổi';

  @override
  String get cpOtherSection => 'Khác';

  @override
  String get cpByAge => 'Theo tuổi';

  @override
  String cpByAgeSub(String age) {
    return 'Nếp chuẩn cho bé $age';
  }

  @override
  String get cpSelfMade => 'Tự tạo';

  @override
  String get cpSelfMadeSub => 'Tự đặt giờ và việc';

  @override
  String get cpPreview => 'Xem trước lịch';

  @override
  String get cpTodayPlan => 'Lịch hôm nay';

  @override
  String cpDraftHeading(String name) {
    return 'Gợi ý cho $name';
  }

  @override
  String get cpDraftFromRhythm => 'Theo nhịp 7 ngày qua';

  @override
  String cpDraftFrom(String way) {
    return 'Theo $way';
  }

  @override
  String get cpChangeShort => 'Đổi cách';

  @override
  String get cpDraftNote => 'Giờ chỉ là gợi ý, con vẫn dẫn nhịp';

  @override
  String cpTimelineA11y(int feeds, int sleeps) {
    return 'Ngày của bé: $feeds cữ bú, $sleeps giấc ngủ';
  }

  @override
  String cpAssignSpan(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc',
    );
    return '$_temp0 · $from – $to';
  }

  @override
  String cpMemberLine(String relation, String load) {
    return '$relation · $load';
  }

  @override
  String get cpManyPeople => 'Nhiều người';

  @override
  String get cpManyPeopleGroup => 'Chọn người cho từng việc';

  @override
  String get cpManyPeopleTask => 'Cùng làm việc này';

  @override
  String get cpAddToPlan => 'Thêm vào lịch';

  @override
  String get cpSearchTask => 'Tìm việc, vd: uống thuốc';

  @override
  String cpSuggestedFor(String age) {
    return 'Hay dùng cho bé $age';
  }

  @override
  String get cpCatFood => 'Ăn uống';

  @override
  String get cpCatPlay => 'Chơi & vận động';

  @override
  String get cpCatCare => 'Sức khoẻ & vệ sinh';

  @override
  String get cpCreateOwn => 'Tạo việc riêng';

  @override
  String get cpNoTaskFound => 'Không có việc nào khớp. Tạo việc riêng nhé.';

  @override
  String cpShiftOf(String period) {
    return 'Ca $period';
  }

  @override
  String get cpDoer => 'Người làm';

  @override
  String get cpApply => 'Áp dụng';

  @override
  String get cpSkipOk => 'Bỏ qua hôm nay cũng được';

  @override
  String get cpSkipShort => 'Bỏ qua';

  @override
  String get cpUnskipShort => 'Làm lại';

  @override
  String get cpDeleteShort => 'Xoá';

  @override
  String get cpAssignedBadge => 'Phân việc';

  @override
  String cpAskedBy(String who, String me) {
    return '$who nhờ $me nhé';
  }

  @override
  String get cpDueLaterShort => 'Để sau 10′';

  @override
  String get cpSettingsTitle => 'Cài đặt';

  @override
  String get cpRemindSection => 'Nhắc việc';

  @override
  String get cpPlanSection => 'Lịch';

  @override
  String get cpAmount => 'Lượng';

  @override
  String cpMl(int ml) {
    return '$ml ml';
  }

  @override
  String cpTaskWithMl(String task, int ml) {
    return '$task · $ml ml';
  }

  @override
  String get cpNoAmount => 'Chưa định';

  @override
  String get cpHistoryFrom => 'Việc trong lịch';

  @override
  String cpHistoryFromBy(String who) {
    return 'Việc trong lịch · $who làm';
  }

  @override
  String get cpHistTitle => 'Lịch sử thay đổi';

  @override
  String get cpHistToday => 'Hôm nay';

  @override
  String get cpHistYesterday => 'Hôm qua';

  @override
  String cpHistMoved(String task, String from, String to) {
    return '$task $from → $to';
  }

  @override
  String cpHistEdited(String task, String time) {
    return 'Sửa “$task” $time';
  }

  @override
  String cpHistAdded(String task, String time) {
    return 'Thêm “$task” $time';
  }

  @override
  String cpHistDeleted(String task, String time) {
    return 'Xoá “$task” $time';
  }

  @override
  String get cpHistEveryDay => 'mọi ngày';

  @override
  String get cpHistThatDay => 'chỉ ngày đó';

  @override
  String cpHistAssigned(String task, String who) {
    return 'Giao “$task” cho $who';
  }

  @override
  String cpHistAssignedMany(int count, String who) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giao $count việc cho $who',
    );
    return '$_temp0';
  }

  @override
  String cpHistUnassigned(String task) {
    return 'Bỏ người làm “$task”';
  }

  @override
  String cpHistSkipped(String task, String time) {
    return 'Bỏ qua “$task” $time';
  }

  @override
  String cpHistStarted(String way) {
    return 'Lên lịch $way';
  }

  @override
  String get cpHistAutoDraft => 'Tự tạo bản nháp buổi sáng';

  @override
  String get cpHistPublished => 'Dùng lịch này';

  @override
  String get cpHistUndo => 'Hoàn tác';

  @override
  String get cpHistUndone => 'Đã hoàn tác';

  @override
  String get cpHistEmpty => 'Chưa có thay đổi nào';

  @override
  String get cpHistSomeone => 'Một người đã rời nhà';

  @override
  String get cpReportTitle => 'Cùng nhau chăm';

  @override
  String get cpReportOpen => 'Xem báo cáo cùng chăm';

  @override
  String get cpRangeWeek => 'Tuần';

  @override
  String get cpRangeMonth => 'Tháng';

  @override
  String get cpRangeYear => 'Năm';

  @override
  String cpReportTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'việc',
    );
    return '$_temp0';
  }

  @override
  String get cpReportHearts => 'tim';

  @override
  String get cpReportStreak => 'ngày liền';

  @override
  String get cpReportOnTime => 'đúng nhịp';

  @override
  String get cpReportEmpty => 'Chưa có việc nào xong trong khoảng này';

  @override
  String get cpBadgesWeek => 'Huy hiệu tuần này';

  @override
  String get cpBadgeBath => 'Siêu tắm';

  @override
  String get cpBadgeNight => 'Cú đêm';

  @override
  String get cpBadgeStory => 'Kể chuyện';

  @override
  String get cpBadgeBottle => 'Bình sữa vàng';

  @override
  String get cpBadgeDiaper => 'Tã thần tốc';

  @override
  String get cpBadgeGrand => 'Ông bà siêu sao';

  @override
  String get cpBadgeOnTime => 'Đúng giờ 7 ngày';

  @override
  String get cpBadgeTeam => 'Đồng đội ăn ý';

  @override
  String get cpBadgeVitamin => 'Vitamin đều đặn';

  @override
  String cpBadgeLocked(String name) {
    return '$name, chưa đạt';
  }

  @override
  String cpBadgeBy(String name, String who) {
    return '$name, của $who';
  }

  @override
  String get cpShowFamily => 'Khoe cả nhà';

  @override
  String get cpShareTitle => 'Chia sẻ';

  @override
  String cpShareWeek(int week) {
    return 'Tuần $week';
  }

  @override
  String cpShareMonth(int month) {
    return 'Tháng $month';
  }

  @override
  String cpShareHeadline(String name) {
    return 'Tuần này cả nhà cùng chăm $name';
  }

  @override
  String cpShareHeadlineMonth(String name) {
    return 'Tháng này cả nhà cùng chăm $name';
  }

  @override
  String cpShareHeadlineYear(String name) {
    return 'Năm nay cả nhà cùng chăm $name';
  }

  @override
  String cpShareThanks(int count) {
    return '$count lời cảm ơn trong nhà tuần này';
  }

  @override
  String get cpShareStory => 'Story';

  @override
  String get cpShareCopy => 'Sao chép';

  @override
  String get cpShareMore => 'Khác';

  @override
  String get cpShareCopied => 'Đã sao chép';

  @override
  String cpShareText(String headline, int count, String people) {
    return '$headline: $count việc. $people';
  }

  @override
  String get cpShareFailed => 'Chưa chia sẻ được. Thử lại nhé.';

  @override
  String get cpHistEmptyBody => 'Ai sửa, thêm hay giao việc sẽ hiện ở đây.';

  @override
  String careAtTime(String time) {
    return 'lúc $time';
  }

  @override
  String get cpPushSnooze10 => 'Nhắc lại 10 phút';

  @override
  String get cuTitle => 'Sắp tới';

  @override
  String cuBasis(int days) {
    return 'Theo nhật ký $days ngày gần đây';
  }

  @override
  String get cuFeed => 'Cữ bú tiếp';

  @override
  String get cuSleep => 'Giấc ngủ tiếp';

  @override
  String get cuWake => 'Bé dậy';

  @override
  String cuWindow(String from, String to) {
    return 'khoảng $from–$to';
  }

  @override
  String cuAround(String time) {
    return 'khoảng $time';
  }

  @override
  String cuLastFeed(String time) {
    return 'Cữ gần nhất $time';
  }

  @override
  String cuWokeAt(String time) {
    return 'Dậy lúc $time';
  }

  @override
  String cuAsleepSince(String time) {
    return 'Ngủ từ $time';
  }

  @override
  String get wcTitle => 'Bé dậy chưa?';

  @override
  String wcBody(String duration) {
    return 'Bé đã ngủ $duration. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.';
  }

  @override
  String wcBodyFirst(String duration) {
    return 'Bé đã ngủ $duration. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé. Tắt lời hỏi này trong Hồ sơ › Thông báo.';
  }

  @override
  String get wcAwake => 'Dậy rồi';

  @override
  String get wcWokeAt => 'Dậy lúc…';

  @override
  String get wcStillAsleep => 'Vẫn ngủ';

  @override
  String get ntWakeCheck => 'Hỏi khi đếm giấc ngủ còn chạy';

  @override
  String get ntWakeCheckHint =>
      'Chỉ trên máy này, không hỏi trong giờ yên lặng';

  @override
  String get asNextFeedReminder => 'Nhắc cữ tiếp';

  @override
  String cpDidLine(String who, String task, String baby) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'bottle': 'cho $baby bú bình',
      'breast': 'cho $baby bú mẹ',
      'pump': 'hút sữa cho $baby',
      'solids': 'cho $baby ăn dặm',
      'water': 'cho $baby uống nước',
      'sleep': 'ru $baby ngủ',
      'diaper': 'thay tã cho $baby',
      'bath': 'tắm cho $baby',
      'tummy': 'cho $baby nằm sấp',
      'read': 'đọc sách cho $baby',
      'walk': 'đưa $baby đi dạo',
      'vitamin': 'cho $baby uống vitamin',
      'medicine': 'cho $baby uống thuốc',
      'temperature': 'đo nhiệt độ cho $baby',
      'teeth': 'đánh răng cho $baby',
      'potty': 'cho $baby ngồi bô',
      'other': 'xong một việc cho $baby',
    });
    return '$who vừa $_temp0';
  }

  @override
  String get cpReactThanks => 'Cảm ơn';

  @override
  String get cpReactGreat => 'Tuyệt';

  @override
  String get cpReactHeart => 'Thả tim';

  @override
  String cpThanksName(String who) {
    return 'Cảm ơn $who!';
  }

  @override
  String cpThanksProud(String who) {
    return '$who giỏi quá';
  }

  @override
  String cpThanksLove(String who) {
    return 'Thương $who';
  }

  @override
  String cpSendTo(String who) {
    return 'Gửi cho $who';
  }

  @override
  String cpSentTo(String who) {
    return 'Đã gửi cho $who';
  }

  @override
  String get cpDoneMissing => 'Việc này không còn đánh dấu xong';

  @override
  String cpHeartsFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tim từ cả nhà',
      zero: 'Chưa có tim nào',
    );
    return '$_temp0';
  }

  @override
  String get cpTeamTitle => 'Khi người khác làm xong';

  @override
  String cpHeartA11y(String who) {
    return 'Thả tim cho $who';
  }

  @override
  String get vrTitle => 'Chuẩn bị đi khám';

  @override
  String get vrTileSub => 'Tóm tắt cho bác sĩ';

  @override
  String vrCorrectedAge(String age) {
    return 'Tuổi hiệu chỉnh $age';
  }

  @override
  String vrMadeOn(String date) {
    return 'Lập ngày $date';
  }

  @override
  String get vrGrowth => 'Tăng trưởng';

  @override
  String get vrWeight => 'Cân nặng';

  @override
  String get vrLength => 'Chiều dài';

  @override
  String get vrHead => 'Vòng đầu';

  @override
  String vrMeasuredOn(String date) {
    return 'Đo ngày $date';
  }

  @override
  String get vrNoGrowth => 'Chưa có số đo nào';

  @override
  String get vrCare => 'Ăn, ngủ, thay tã · trung bình mỗi ngày';

  @override
  String vrBefore(String value) {
    return 'Tuần trước: $value';
  }

  @override
  String vrFeedsMl(String count, String ml) {
    return '$count cữ · $ml ml';
  }

  @override
  String vrFeedsMin(String count, String minutes) {
    return '$count cữ · $minutes phút';
  }

  @override
  String vrDiapers(String wet, String dirty) {
    return 'Ướt $wet · Bẩn $dirty';
  }

  @override
  String get vrSleepSparse => 'Chưa đủ ngày ghi đủ';

  @override
  String get vrVaccines => 'Tiêm chủng';

  @override
  String vrVaccinesGiven(int given, int total) {
    return 'Đã tiêm $given/$total mũi đến hạn';
  }

  @override
  String get vrVaccineNext => 'Mũi tiếp theo';

  @override
  String get vrVaccineOverdue => 'Quá hẹn';

  @override
  String get vrQuestions => 'Câu hỏi cho bác sĩ';

  @override
  String get vrQuestionHint => 'Thêm điều bạn muốn hỏi…';

  @override
  String get vrQuestionAdd => 'Thêm';

  @override
  String vrQuestionRemove(String question) {
    return 'Xoá câu hỏi “$question”';
  }

  @override
  String get vrDisclaimer =>
      'Từ nhật ký gia đình ghi trên Child Life. Không thay cho khám và tư vấn của bác sĩ.';

  @override
  String get vrShare => 'Gửi cho bác sĩ';

  @override
  String cpWidgetMine(String who) {
    return 'Việc của $who';
  }

  @override
  String cpWidgetFamily(String done, String total) {
    return 'Cả nhà $done/$total';
  }

  @override
  String cpWidgetLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count việc',
    );
    return '$_temp0';
  }

  @override
  String cpWidgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count việc',
    );
    return '$_temp0';
  }

  @override
  String get cpWidgetRest => 'Nghỉ chút nhé';

  @override
  String get cpWidgetNoPlan => 'Hôm nay chưa có lịch';

  @override
  String get glanceGalleryPlanMineName => 'Việc của tôi';

  @override
  String get glanceGalleryPlanMineBlurb =>
      'Việc sắp tới của bạn, đánh dấu xong ngay trên màn hình chính';

  @override
  String get glanceGalleryPlanFamilyName => 'Cả nhà cùng chăm';

  @override
  String get glanceGalleryPlanFamilyBlurb =>
      'Cả nhà đã xong bao nhiêu việc hôm nay';
}
