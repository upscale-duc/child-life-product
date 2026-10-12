import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P-137 "Hoạt động": the first time the app is opened (launch or back to the foreground) on a
/// local calendar day, this install's row `users/{uid}/devices/{deviceId}` gets
/// `lastActiveAt = serverTimestamp()`, so the portal can count active families without an
/// analytics SDK. Nothing about the child is sent; the device adds only a coarse model and the
/// OS version (never the device's name, which can hold a person's name).

/// The local calendar day of [now], `yyyy-MM-dd`.
String localDayKey(DateTime now) {
  final d = now.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Whether today's heartbeat is still to be sent: never sent, or last sent on another day.
bool heartbeatDue(String? lastSentDay, DateTime now) =>
    lastSentDay != localDayKey(now);

/// Once per local day per account and install: the day of the last heartbeat that reached
/// Firestore, kept in the app's preferences.
class HeartbeatSchedule {
  const HeartbeatSchedule(
    this._prefs, {
    required this.uid,
    required this.deviceId,
  });

  final SharedPreferences _prefs;
  final String uid;
  final String deviceId;

  String get _key => 'device.heartbeat.$uid.$deviceId';

  bool isDue(DateTime now) => heartbeatDue(_prefs.getString(_key), now);

  Future<void> markSent(DateTime now) =>
      _prefs.setString(_key, localDayKey(now));
}

/// The only `model` values the Rules accept (`validDevice`).
const deviceModels = ['iPhone', 'iPad', 'Android phone', 'Android tablet'];

/// A coarse model: iPhone / iPad from the OS-reported generic model ("iPhone", "iPad"), Android
/// phone / tablet from the screen (shortest side ≥ 600 logical px is a tablet, as in Material).
String coarseModel(
  TargetPlatform platform, {
  required double shortestSide,
  String? iosModel,
}) {
  if (platform == TargetPlatform.iOS) {
    final ipad = iosModel != null && iosModel.trim().isNotEmpty
        ? iosModel.toLowerCase().contains('ipad')
        : shortestSide >= 600;
    return ipad ? 'iPad' : 'iPhone';
  }
  return shortestSide >= 600 ? 'Android tablet' : 'Android phone';
}

/// "iOS 26.1", "Android 16": at most 40 characters (Rules).
String osVersionLabel(String system, String version) {
  final label = '${system.trim()} ${version.trim()}'.trim();
  return label.length > 40 ? label.substring(0, 40) : label;
}

@immutable
class DeviceTraits {
  const DeviceTraits({required this.osVersion, required this.model});
  final String osVersion;
  final String model;
}

/// What the heartbeat says about this device; falls back to the platform alone.
Future<DeviceTraits> readDeviceTraits() async {
  final platform = defaultTargetPlatform;
  final dispatcher = PlatformDispatcher.instance;
  final view = dispatcher.implicitView ?? dispatcher.views.firstOrNull;
  final shortest = view == null || view.devicePixelRatio <= 0
      ? 0.0
      : (view.physicalSize / view.devicePixelRatio).shortestSide;
  final ios = platform == TargetPlatform.iOS;
  try {
    final info = DeviceInfoPlugin();
    if (ios) {
      final d = await info.iosInfo;
      return DeviceTraits(
        osVersion: osVersionLabel(
          d.systemName.trim().isEmpty ? 'iOS' : d.systemName,
          d.systemVersion,
        ),
        model: coarseModel(platform, shortestSide: shortest, iosModel: d.model),
      );
    }
    final d = await info.androidInfo;
    return DeviceTraits(
      osVersion: osVersionLabel('Android', d.version.release),
      model: coarseModel(platform, shortestSide: shortest),
    );
  } on Object {
    return DeviceTraits(
      osVersion: ios ? 'iOS' : 'Android',
      model: coarseModel(platform, shortestSide: shortest),
    );
  }
}
