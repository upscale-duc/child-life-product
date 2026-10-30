import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/cl_theme.dart';
import 'appearance.dart';

/// Overridden at startup with the loaded preferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden at startup',
  ),
);

const _kTheme = 'appearance.theme';
const _kSchedule = 'appearance.nightCare.enabled';
const _kStart = 'appearance.nightCare.start';
const _kEnd = 'appearance.nightCare.end';

/// The stored settings, also read outside the app (L6's background notification handler).
AppearanceSettings appearanceSettingsOf(SharedPreferences prefs) {
  const defaults = AppearanceSettings();
  TimeOfDay? read(String key) {
    final minutes = prefs.getInt(key);
    return minutes == null
        ? null
        : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  return AppearanceSettings(
    theme:
        ThemePreference.values.asNameMap()[prefs.getString(_kTheme)] ??
        defaults.theme,
    nightCareScheduleEnabled:
        prefs.getBool(_kSchedule) ?? defaults.nightCareScheduleEnabled,
    scheduleStart: read(_kStart) ?? defaults.scheduleStart,
    scheduleEnd: read(_kEnd) ?? defaults.scheduleEnd,
  );
}

final appearanceSettingsProvider =
    NotifierProvider<AppearanceController, AppearanceSettings>(
      AppearanceController.new,
    );

/// Appearance is stored per device (P-061); changes apply immediately ("Áp dụng ngay cho cả app").
class AppearanceController extends Notifier<AppearanceSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppearanceSettings build() => appearanceSettingsOf(_prefs);

  Future<void> update(AppearanceSettings next) async {
    state = next;
    await Future.wait([
      _prefs.setString(_kTheme, next.theme.name),
      _prefs.setBool(_kSchedule, next.nightCareScheduleEnabled),
      _prefs.setInt(
        _kStart,
        next.scheduleStart.hour * 60 + next.scheduleStart.minute,
      ),
      _prefs.setInt(
        _kEnd,
        next.scheduleEnd.hour * 60 + next.scheduleEnd.minute,
      ),
    ]);
  }
}

/// Set by the timer features (S5) while a sleep / feed timer runs on this device.
final nightCareTimerRunningProvider = NotifierProvider<TimerRunning, bool>(
  TimerRunning.new,
);

class TimerRunning extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool running) => state = running;
}

/// Wall clock that ticks at each minute boundary — no per-second rebuilds (brief §04).
final minuteClockProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  Timer? timer;
  void schedule() {
    final now = DateTime.now();
    controller.add(now);
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    timer = Timer(next.difference(now), schedule);
  }

  schedule();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Platform brightness, updated by the app root from MediaQuery.
final platformBrightnessProvider =
    NotifierProvider<PlatformBrightness, Brightness>(PlatformBrightness.new);

class PlatformBrightness extends Notifier<Brightness> {
  @override
  Brightness build() =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  // ignore: use_setters_to_change_properties
  void set(Brightness value) => state = value;
}

final paletteProvider = Provider<ClPalette>((ref) {
  return resolvePalette(
    settings: ref.watch(appearanceSettingsProvider),
    platformBrightness: ref.watch(platformBrightnessProvider),
    now: ref.watch(minuteClockProvider).value ?? DateTime.now(),
    timerRunning: ref.watch(nightCareTimerRunningProvider),
  );
});
