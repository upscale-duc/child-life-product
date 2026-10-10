import 'package:child_life/app/providers.dart';
import 'package:child_life/app/environment.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A route visit recorded by the stub pages: path (with query) and `extra`.
typedef Visit = ({String location, Object? extra});

/// Pumps [screen] at '/' with stub pages for every other route (up to three segments) on a
/// 375 × 812 phone; returns the visits and the provider container.
Future<(List<Visit>, ProviderContainer)> pumpRouted(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('vi'),
  ClPalette palette = ClPalette.light,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final visits = <Visit>[];
  Widget stub(GoRouterState s) {
    visits.add((location: s.uri.toString(), extra: s.extra));
    return const Scaffold(body: Text('stub'));
  }

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/:a/:b/:c', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a/:b', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a', builder: (_, s) => stub(s)),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      environmentProvider.overrideWithValue(AppEnvironment.dev),
      providerDisplayNameProvider.overrideWithValue(null),
      minuteClockProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: buildClTheme(palette),
          locale: locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (visits, container);
}
