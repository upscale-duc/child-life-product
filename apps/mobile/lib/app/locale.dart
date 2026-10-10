import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages shipped in V1 (D-012). Vietnamese is the source language and the fallback.
const supportedLocales = [Locale('vi'), Locale('en')];
const fallbackLocale = Locale('vi');

/// In-app language override; `null` follows the device. Persisted per account in a later slice
/// (Me → language row, design gap G-081).
final localeOverrideProvider = NotifierProvider<LocaleOverride, Locale?>(
  LocaleOverride.new,
);

class LocaleOverride extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;
}

/// Picks the first device language we support, otherwise Vietnamese.
Locale resolveLocale(List<Locale>? deviceLocales) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == device.languageCode) return supported;
    }
  }
  return fallbackLocale;
}
