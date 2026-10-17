import 'package:child_life/app/locale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the first supported device language', () {
    expect(
      resolveLocale(const [Locale('en', 'US'), Locale('vi')]),
      const Locale('en'),
    );
    expect(
      resolveLocale(const [Locale('fr'), Locale('vi', 'VN')]),
      const Locale('vi'),
    );
  });

  test('other device languages open in English (D-078)', () {
    expect(resolveLocale(const [Locale('ja')]), const Locale('en'));
    expect(
      resolveLocale(const [Locale('fr', 'FR'), Locale('de')]),
      const Locale('en'),
    );
  });

  test('no device language at all falls back to Vietnamese', () {
    expect(resolveLocale(null), const Locale('vi'));
    expect(resolveLocale(const []), const Locale('vi'));
  });
}
