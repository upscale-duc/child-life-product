import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in the Child Life theme, localizations and media settings used by tests.
Widget clHarness(
  Widget child, {
  ClPalette palette = ClPalette.light,
  Locale locale = const Locale('vi'),
  bool reduceMotion = false,
  double width = 375,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, 2000),
      disableAnimations: reduceMotion,
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(palette),
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

Future<void> pumpCl(
  WidgetTester tester,
  Widget child, {
  ClPalette palette = ClPalette.light,
  Locale locale = const Locale('vi'),
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    clHarness(
      child,
      palette: palette,
      locale: locale,
      reduceMotion: reduceMotion,
    ),
  );
  await tester.pumpAndSettle();
}
