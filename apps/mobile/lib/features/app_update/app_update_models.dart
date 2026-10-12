/// App updates (D-061, v1.0 improvement UP1–UP6): `publicConfig/appUpdate`, written on the portal
/// (Hệ thống › Cập nhật ứng dụng). Shapes mirror `packages/contracts/src/app-update.ts`.
library;

/// "1.2.0", compared part by part. Anything else is unparsable and never blocks.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _re = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})');

  static AppVersion? tryParse(Object? raw) {
    if (raw is! String) return null;
    final m = _re.firstMatch(raw.trim());
    if (m == null) return null;
    return AppVersion(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  @override
  int compareTo(AppVersion other) => major != other.major
      ? major.compareTo(other.major)
      : minor != other.minor
      ? minor.compareTo(other.minor)
      : patch.compareTo(other.patch);

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Vietnamese and English, both written on the portal (D-012).
class UpdateText {
  const UpdateText(this.vi, this.en);
  final String vi;
  final String en;

  String of(String languageCode) =>
      languageCode == 'en' && en.isNotEmpty ? en : vi;

  static UpdateText? parse(Object? raw) {
    if (raw is! Map) return null;
    final vi = raw['vi'];
    final en = raw['en'];
    if (vi is! String || vi.isEmpty) return null;
    return UpdateText(vi, en is String ? en : '');
  }
}

class PlatformUpdate {
  const PlatformUpdate({this.latest, this.minimum, this.storeUrl});

  final AppVersion? latest;
  final AppVersion? minimum;
  final Uri? storeUrl;

  static PlatformUpdate parse(Object? raw) {
    if (raw is! Map) return const PlatformUpdate();
    final url = raw['storeUrl'];
    final uri = url is String ? Uri.tryParse(url) : null;
    return PlatformUpdate(
      latest: AppVersion.tryParse(raw['latest']),
      minimum: AppVersion.tryParse(raw['minimum']),
      storeUrl: uri != null && uri.scheme == 'https' ? uri : null,
    );
  }
}

/// The icons and tints the portal offers for UP2 rows.
enum UpdateIcon {
  alert,
  grid,
  heart,
  cake,
  spark,
  bell,
  camera,
  sleep,
  family,
  star,
}

enum UpdateTone { danger, growth, pump, sleep, bottle, mint, sunshine }

/// A row in the UP2 sheet: "Sơ cứu trẻ em · 25 tình huống, đọc to từng bước".
class UpdateHighlight {
  const UpdateHighlight({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final UpdateIcon icon;
  final UpdateTone tone;
  final UpdateText title;
  final UpdateText body;

  static UpdateHighlight? parse(Object? raw) {
    if (raw is! Map) return null;
    final title = UpdateText.parse(raw['title']);
    final body = UpdateText.parse(raw['body']);
    if (title == null || body == null) return null;
    return UpdateHighlight(
      icon:
          UpdateIcon.values.where((i) => i.name == raw['icon']).firstOrNull ??
          UpdateIcon.spark,
      tone:
          UpdateTone.values.where((t) => t.name == raw['tone']).firstOrNull ??
          UpdateTone.mint,
      title: title,
      body: body,
    );
  }
}

/// A UP3/UP4 page.
class UpdatePage {
  const UpdatePage({
    required this.title,
    required this.body,
    this.imageUrl,
    this.where,
  });

  final Uri? imageUrl;
  final UpdateText title;
  final UpdateText body;

  /// "Tìm trong tab Tiện ích".
  final UpdateText? where;

  static UpdatePage? parse(Object? raw, Uri Function(String imageId) imageUrl) {
    if (raw is! Map) return null;
    final title = UpdateText.parse(raw['title']);
    final body = UpdateText.parse(raw['body']);
    if (title == null || body == null) return null;
    final image = raw['image'];
    return UpdatePage(
      imageUrl: image is String && image.isNotEmpty ? imageUrl(image) : null,
      title: title,
      body: body,
      where: UpdateText.parse(raw['where']),
    );
  }
}

class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.summary,
    this.highlights = const [],
    this.pages = const [],
  });

  final AppVersion version;

  /// UP5's second line.
  final UpdateText summary;
  final List<UpdateHighlight> highlights;
  final List<UpdatePage> pages;

  static UpdateRelease? parse(
    Object? raw,
    Uri Function(String imageId) imageUrl,
  ) {
    if (raw is! Map) return null;
    final version = AppVersion.tryParse(raw['version']);
    final summary = UpdateText.parse(raw['summary']);
    if (version == null || summary == null) return null;
    return UpdateRelease(
      version: version,
      summary: summary,
      highlights: [
        for (final h in (raw['highlights'] as List?) ?? const [])
          ?UpdateHighlight.parse(h),
      ],
      pages: [
        for (final p in (raw['pages'] as List?) ?? const [])
          ?UpdatePage.parse(p, imageUrl),
      ],
    );
  }
}

class AppUpdateConfig {
  const AppUpdateConfig({
    this.ios = const PlatformUpdate(),
    this.android = const PlatformUpdate(),
    this.snoozeDays = 3,
    this.release,
  });

  final PlatformUpdate ios;
  final PlatformUpdate android;
  final int snoozeDays;
  final UpdateRelease? release;

  /// `publicConfig/appUpdate` → its `config`; [imageUrl] turns a picture id into its public URL.
  static AppUpdateConfig? fromDoc(
    Map<String, Object?>? doc,
    Uri Function(String imageId) imageUrl,
  ) {
    final config = doc?['config'];
    if (config is! Map) return null;
    final snooze = config['snoozeDays'];
    return AppUpdateConfig(
      ios: PlatformUpdate.parse(config['ios']),
      android: PlatformUpdate.parse(config['android']),
      snoozeDays: snooze is num ? snooze.toInt().clamp(1, 30) : 3,
      release: UpdateRelease.parse(config['release'], imageUrl),
    );
  }

  PlatformUpdate forPlatform({required bool ios}) => ios ? this.ios : android;
}

/// What this phone should do.
sealed class AppUpdateStatus {
  const AppUpdateStatus();
}

/// Nothing to say (no config yet, up to date, or the version cannot be read).
class UpToDate extends AppUpdateStatus {
  const UpToDate();
}

/// UP2 / the UP6 tag: a newer version is in the store.
class UpdateAvailable extends AppUpdateStatus {
  const UpdateAvailable({
    required this.installed,
    required this.latest,
    this.storeUrl,
  });
  final AppVersion installed;
  final AppVersion latest;
  final Uri? storeUrl;
}

/// UP1: below the oldest version allowed; the app stops until updated.
class UpdateRequired extends AppUpdateStatus {
  const UpdateRequired({
    required this.installed,
    required this.latest,
    this.storeUrl,
  });
  final AppVersion installed;
  final AppVersion latest;
  final Uri? storeUrl;
}

AppUpdateStatus updateStatusOf(
  AppUpdateConfig? config,
  AppVersion? installed, {
  required bool ios,
}) {
  if (config == null || installed == null) return const UpToDate();
  final p = config.forPlatform(ios: ios);
  final latest = p.latest;
  if (latest == null) return const UpToDate();
  final minimum = p.minimum;
  // Only ever ask for something the store can give (the portal also enforces minimum ≤ latest).
  if (minimum != null && installed < minimum && !(latest < minimum)) {
    return UpdateRequired(
      installed: installed,
      latest: latest,
      storeUrl: p.storeUrl,
    );
  }
  if (installed < latest) {
    return UpdateAvailable(
      installed: installed,
      latest: latest,
      storeUrl: p.storeUrl,
    );
  }
  return const UpToDate();
}
