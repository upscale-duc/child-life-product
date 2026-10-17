import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appearance/appearance_providers.dart';

/// Languages shipped in V1 (D-012). Vietnamese is the source language and the fallback when the
/// device says nothing; a device in any other language opens in English (D-078).
const supportedLocales = [Locale('vi'), Locale('en')];
const fallbackLocale = Locale('vi');
const otherLanguageLocale = Locale('en');

const _kLocale = 'app.locale';

/// In-app language override (D-012, Tôi → Ngôn ngữ, G-081); `null` follows the device. Kept on
/// this device like Giao diện (P-061). Service mail and pushes follow it too, since they use the
/// app's current language.
final localeOverrideProvider = NotifierProvider<LocaleOverride, Locale?>(
  LocaleOverride.new,
);

class LocaleOverride extends Notifier<Locale?> {
  @override
  Locale? build() {
    try {
      final code = ref.read(sharedPreferencesProvider).getString(_kLocale);
      return supportedLocales.where((l) => l.languageCode == code).firstOrNull;
    } on StateError {
      // No preferences (some tests): follow the device.
      return null;
    }
  }

  void set(Locale? locale) {
    state = locale;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (locale == null) {
        prefs.remove(_kLocale);
      } else {
        prefs.setString(_kLocale, locale.languageCode);
      }
    } on StateError {
      // Not persisted without preferences.
    }
  }
}

/// Picks the first device language we support; a device in other languages only gets English
/// (a French or Japanese phone is far likelier to read English than Vietnamese), and no device
/// languages at all gets Vietnamese.
Locale resolveLocale(List<Locale>? deviceLocales) {
  final device = deviceLocales ?? const <Locale>[];
  for (final d in device) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == d.languageCode) return supported;
    }
  }
  return device.isEmpty ? fallbackLocale : otherLanguageLocale;
}
