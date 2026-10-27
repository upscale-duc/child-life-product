import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import 'app_update_models.dart';

/// `publicConfig/appUpdate` (D-061). Firestore keeps the last copy, so a phone below the minimum
/// stays blocked offline, and a phone that never saw a config is never blocked.
final appUpdateConfigProvider = StreamProvider<AppUpdateConfig?>((ref) {
  try {
    final bucket = Firebase.app().options.storageBucket ?? '';
    Uri imageUrl(String id) => Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
      '${Uri.encodeComponent('content/app-update/$id.webp')}?alt=media',
    );
    return ref
        .watch(firestoreProvider)
        .doc('publicConfig/appUpdate')
        .snapshots()
        .map((s) => AppUpdateConfig.fromDoc(s.data(), imageUrl))
        // Unreadable means "nothing to say", never "blocked".
        .handleError((Object _) {});
  } on Object {
    return Stream.value(null);
  }
}, retry: (_, _) => null);

/// The installed version ("1.0.3"), as the stores count it; null when it cannot be read.
final installedVersionProvider = FutureProvider<AppVersion?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersion.tryParse(info.version);
  } on Object {
    return null;
  }
}, retry: (_, _) => null);

/// Which store this build updates from.
final updateFromAppStoreProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS,
);

final appUpdateStatusProvider = Provider<AppUpdateStatus>(
  (ref) => updateStatusOf(
    ref.watch(appUpdateConfigProvider).value,
    ref.watch(installedVersionProvider).value,
    ios: ref.watch(updateFromAppStoreProvider),
  ),
);

/// Opens the store page ("Cập nhật trên App Store"). Throws when nothing opened it, so the
/// caller says so instead of a tap that silently does nothing (UPD-1, on the blocking UP1).
final openStoreProvider = Provider<Future<void> Function(Uri url)>(
  (ref) => (url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw StateError('store page did not open');
    }
  },
);

/// What this phone remembers about updates, in app preferences:
/// - "Để sau" on UP2 until a date, per offered version;
/// - the version that just replaced an older one (UP5 "Đã cập nhật 1.2.0"), until seen or closed.
class AppUpdateMemory {
  const AppUpdateMemory({
    this.snoozedUntil = const {},
    this.updatedTo,
    this.closed = const {},
  });

  final Map<String, DateTime> snoozedUntil;

  /// Set when this launch found a newer version than the last one; null on a fresh install.
  final AppVersion? updatedTo;

  /// Releases whose UP5 banner was opened ("Xem") or closed (×).
  final Set<String> closed;

  bool snoozed(AppVersion latest, DateTime now) =>
      snoozedUntil['$latest']?.isAfter(now) ?? false;
}

const _kSnooze = 'appUpdate.snooze.';
const _kLastRun = 'appUpdate.lastRun';
const _kUpdatedTo = 'appUpdate.updatedTo';
const _kClosed = 'appUpdate.closed';

final appUpdateMemoryProvider =
    NotifierProvider<AppUpdateMemoryNotifier, AppUpdateMemory>(
      AppUpdateMemoryNotifier.new,
    );

class AppUpdateMemoryNotifier extends Notifier<AppUpdateMemory> {
  @override
  AppUpdateMemory build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final installed = ref.watch(installedVersionProvider).value;
    var updatedTo = AppVersion.tryParse(prefs.getString(_kUpdatedTo));
    if (installed != null) {
      final lastRun = AppVersion.tryParse(prefs.getString(_kLastRun));
      // A fresh install has nothing to announce; an update does (UP5).
      if (lastRun != null && lastRun < installed) {
        updatedTo = installed;
        prefs.setString(_kUpdatedTo, '$installed');
      }
      if (lastRun != installed) prefs.setString(_kLastRun, '$installed');
    }
    return AppUpdateMemory(
      snoozedUntil: {
        for (final key in prefs.getKeys())
          if (key.startsWith(_kSnooze))
            if (prefs.getInt(key) case final ms?)
              key.substring(_kSnooze.length):
                  DateTime.fromMillisecondsSinceEpoch(ms),
      },
      updatedTo: updatedTo,
      closed: (prefs.getStringList(_kClosed) ?? const []).toSet(),
    );
  }

  /// UP2 was shown: not again for [days] ("Để sau", or a dismissed sheet).
  void snooze(AppVersion latest, int days, DateTime now) {
    final until = now.add(Duration(days: days));
    ref
        .read(sharedPreferencesProvider)
        .setInt('$_kSnooze$latest', until.millisecondsSinceEpoch);
    state = AppUpdateMemory(
      snoozedUntil: {...state.snoozedUntil, '$latest': until},
      updatedTo: state.updatedTo,
      closed: state.closed,
    );
  }

  /// UP5 opened or closed: the banner is done for this release.
  void closeBanner(AppVersion release) {
    final closed = {...state.closed, '$release'};
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_kClosed, closed.toList());
    state = AppUpdateMemory(
      snoozedUntil: state.snoozedUntil,
      updatedTo: state.updatedTo,
      closed: closed,
    );
  }
}

/// UP5 "Đã cập nhật 1.2.0": the release notes of the version this phone just updated to.
final whatsNewBannerProvider = Provider<UpdateRelease?>((ref) {
  final release = ref.watch(appUpdateConfigProvider).value?.release;
  final memory = ref.watch(appUpdateMemoryProvider);
  final installed = ref.watch(installedVersionProvider).value;
  if (release == null || installed == null || release.pages.isEmpty) {
    return null;
  }
  if (memory.updatedTo != installed || release.version != installed) {
    return null;
  }
  if (memory.closed.contains('${release.version}')) return null;
  return release;
});
