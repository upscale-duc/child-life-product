import 'package:child_life/app/providers.dart';
import 'package:child_life/features/app_update/app_update_models.dart';
import 'package:child_life/features/app_update/app_update_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// The v1.0 improvement example (UP1–UP6): 1.0.3 installed, 1.2.0 in the store.
const storeUrl = 'https://apps.apple.com/app/id6700000000';

UpdateRelease sampleRelease({
  String version = '1.2.0',
  bool pages = true,
}) => UpdateRelease(
  version: AppVersion.tryParse(version)!,
  summary: const UpdateText(
    'Sơ cứu, chi tiêu chung, lịch tiêm',
    'First aid, shared spending, vaccines',
  ),
  highlights: const [
    UpdateHighlight(
      icon: UpdateIcon.alert,
      tone: UpdateTone.danger,
      title: UpdateText('Sơ cứu trẻ em', 'Child first aid'),
      body: UpdateText(
        '25 tình huống, đọc to từng bước',
        '25 situations, read aloud step by step',
      ),
    ),
    UpdateHighlight(
      icon: UpdateIcon.grid,
      tone: UpdateTone.growth,
      title: UpdateText(
        'Sổ chi tiêu chung cho bé',
        'One spending book for your baby',
      ),
      body: UpdateText(
        'Ba mẹ cùng ghi, cùng xem',
        'Both parents log and see it',
      ),
    ),
    UpdateHighlight(
      icon: UpdateIcon.heart,
      tone: UpdateTone.pump,
      title: UpdateText('Lịch tiêm chủng', 'Vaccination schedule'),
      body: UpdateText(
        'Đánh dấu mũi đã tiêm, nhắc trước ngày',
        'Mark doses, get reminded ahead',
      ),
    ),
  ],
  pages: pages
      ? const [
          UpdatePage(
            title: UpdateText(
              'Sơ cứu trẻ em, luôn trong túi bạn',
              'Child first aid, always with you',
            ),
            body: UpdateText(
              '25 tình huống thường gặp với hình minh hoạ rõ ràng. App đọc to từng bước để bạn rảnh '
                  'tay chăm con. Dùng được cả khi không có mạng.',
              '25 common situations with clear pictures. The app reads each step aloud so your '
                  'hands stay free. Works offline too.',
            ),
            where: UpdateText('Tìm trong tab Tiện ích', 'In the Utilities tab'),
          ),
          UpdatePage(
            title: UpdateText(
              'Một sổ chi tiêu chung cho bé',
              'One spending book for your baby',
            ),
            body: UpdateText(
              'Sữa, tã, tiêm chủng, giữ trẻ — ba và mẹ cùng ghi, cùng xem như nhau.',
              'Milk, nappies, vaccines, childcare — both parents log and see the same.',
            ),
            where: UpdateText('Tìm trong tab Tiện ích', 'In the Utilities tab'),
          ),
        ]
      : const [],
);

AppUpdateConfig sampleConfig({
  String? latest = '1.2.0',
  String? minimum,
  UpdateRelease? release,
  bool withRelease = true,
}) {
  final p = PlatformUpdate(
    latest: AppVersion.tryParse(latest),
    minimum: AppVersion.tryParse(minimum),
    storeUrl: Uri.parse(storeUrl),
  );
  return AppUpdateConfig(
    ios: p,
    android: p,
    release: withRelease ? (release ?? sampleRelease()) : null,
  );
}

/// [opened] collects the store links the app tried to open.
List<Override> appUpdateOverrides({
  AppUpdateConfig? config,
  String installed = '1.0.3',
  bool appStore = true,
  List<Uri>? opened,
  String? shownVersion,
}) => [
  appUpdateConfigProvider.overrideWith((ref) => Stream.value(config)),
  installedVersionProvider.overrideWith(
    (ref) async => AppVersion.tryParse(installed),
  ),
  updateFromAppStoreProvider.overrideWithValue(appStore),
  openStoreProvider.overrideWithValue((url) async => opened?.add(url)),
  appVersionProvider.overrideWith((ref) async => shownVersion ?? installed),
];
