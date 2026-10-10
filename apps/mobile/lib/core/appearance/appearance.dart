import 'package:flutter/material.dart';

import '../design/cl_theme.dart';

/// "Giao diện" choice (Figma 29:1063): Sáng / Tối / Tự động.
enum ThemePreference { light, dark, auto }

/// Per-device appearance settings (P-061). Default schedule 21:00–06:00 (Figma 29:1063, 43:2067).
@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.theme = ThemePreference.auto,
    this.nightCareScheduleEnabled = true,
    this.scheduleStart = const TimeOfDay(hour: 21, minute: 0),
    this.scheduleEnd = const TimeOfDay(hour: 6, minute: 0),
  });

  final ThemePreference theme;
  final bool nightCareScheduleEnabled;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;

  AppearanceSettings copyWith({
    ThemePreference? theme,
    bool? nightCareScheduleEnabled,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
  }) => AppearanceSettings(
    theme: theme ?? this.theme,
    nightCareScheduleEnabled:
        nightCareScheduleEnabled ?? this.nightCareScheduleEnabled,
    scheduleStart: scheduleStart ?? this.scheduleStart,
    scheduleEnd: scheduleEnd ?? this.scheduleEnd,
  );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.theme == theme &&
      other.nightCareScheduleEnabled == nightCareScheduleEnabled &&
      other.scheduleStart == scheduleStart &&
      other.scheduleEnd == scheduleEnd;

  @override
  int get hashCode =>
      Object.hash(theme, nightCareScheduleEnabled, scheduleStart, scheduleEnd);
}

/// Whether [now] falls inside a daily window that may cross midnight (e.g. 21:00–06:00).
bool isWithinDailyWindow(TimeOfDay start, TimeOfDay end, DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  if (s == e) return false;
  return s < e ? minutes >= s && minutes < e : minutes >= s || minutes < e;
}

/// Night care applies when the user picked "Tối", when "Tự động" follows a dark system
/// appearance, inside the Night care schedule, or while a sleep / feed timer runs
/// ("Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ" — 29:1063). P-061, Q-027.
ClPalette resolvePalette({
  required AppearanceSettings settings,
  required Brightness platformBrightness,
  required DateTime now,
  required bool timerRunning,
}) {
  final nightCare =
      switch (settings.theme) {
        ThemePreference.dark => true,
        ThemePreference.auto => platformBrightness == Brightness.dark,
        ThemePreference.light => false,
      } ||
      (settings.nightCareScheduleEnabled &&
          isWithinDailyWindow(
            settings.scheduleStart,
            settings.scheduleEnd,
            now,
          )) ||
      timerRunning;
  return nightCare ? ClPalette.nightCare : ClPalette.light;
}
