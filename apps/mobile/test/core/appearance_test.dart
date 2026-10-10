import 'package:child_life/core/appearance/appearance.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int h, int m) => DateTime(2026, 10, 8, h, m);

void main() {
  group('isWithinDailyWindow', () {
    const start = TimeOfDay(hour: 21, minute: 0);
    const end = TimeOfDay(hour: 6, minute: 0);
    test('handles windows that cross midnight', () {
      expect(isWithinDailyWindow(start, end, at(20, 59)), isFalse);
      expect(isWithinDailyWindow(start, end, at(21, 0)), isTrue);
      expect(isWithinDailyWindow(start, end, at(2, 30)), isTrue);
      expect(isWithinDailyWindow(start, end, at(5, 59)), isTrue);
      expect(isWithinDailyWindow(start, end, at(6, 0)), isFalse);
    });
    test('handles same-day windows and empty windows', () {
      const a = TimeOfDay(hour: 13, minute: 0);
      const b = TimeOfDay(hour: 15, minute: 0);
      expect(isWithinDailyWindow(a, b, at(14, 0)), isTrue);
      expect(isWithinDailyWindow(a, b, at(15, 0)), isFalse);
      expect(isWithinDailyWindow(a, a, at(13, 0)), isFalse);
    });
  });

  group('resolvePalette', () {
    ClPalette resolve({
      ThemePreference theme = ThemePreference.light,
      bool schedule = false,
      Brightness brightness = Brightness.light,
      DateTime? now,
      bool timer = false,
    }) => resolvePalette(
      settings: AppearanceSettings(
        theme: theme,
        nightCareScheduleEnabled: schedule,
      ),
      platformBrightness: brightness,
      now: now ?? at(12, 0),
      timerRunning: timer,
    );

    test(
      'Sáng stays light during the day',
      () => expect(resolve(), ClPalette.light),
    );
    test(
      'Tối is Night care',
      () => expect(resolve(theme: ThemePreference.dark), ClPalette.nightCare),
    );
    test('Tự động follows the system', () {
      expect(
        resolve(theme: ThemePreference.auto, brightness: Brightness.dark),
        ClPalette.nightCare,
      );
      expect(resolve(theme: ThemePreference.auto), ClPalette.light);
    });
    test('the schedule turns Night care on inside the window only', () {
      expect(resolve(schedule: true, now: at(22, 0)), ClPalette.nightCare);
      expect(resolve(schedule: true, now: at(10, 0)), ClPalette.light);
    });
    test('a running timer forces Night care outside the schedule', () {
      expect(resolve(timer: true), ClPalette.nightCare);
    });
  });
}
