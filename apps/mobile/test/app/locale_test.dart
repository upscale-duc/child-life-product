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

  test('falls back to Vietnamese', () {
    expect(resolveLocale(const [Locale('ja')]), const Locale('vi'));
    expect(resolveLocale(null), const Locale('vi'));
  });
}
