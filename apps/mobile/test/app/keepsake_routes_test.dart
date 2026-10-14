import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/router.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// Video kỷ niệm on the app's real router (owner, 2026-10-14: "Null check operator used on a
/// null value" at router.dart:330): go_router rebuilds pushed pages without their `extra` when it
/// refreshes, and "Chọn ảnh" read its draft from it.
void main() {
  testWidgets('Chọn ảnh keeps its draft when the router refreshes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        ...careOverrides(),
        ...memoryOverrides(
          keepsakes: (cards: true, videos: true),
          keepsakeCatalog: seedCatalog(),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        environmentProvider.overrideWithValue(AppEnvironment.dev),
      ],
    );
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildClTheme(ClPalette.light),
          locale: const Locale('vi'),
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
    );
    await tester.pump(const Duration(seconds: 1));
    router.go(Routes.memories);
    await tester.pumpAndSettle();
    unawaited(
      router.push(
        '${Routes.memoryStory}/photos',
        extra: VideoDraft(
          babyId: teddyId,
          template: seedCatalog().videos.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MemoryStoryPhotosScreen), findsOneWidget);

    // Anything the router listens to makes it refresh, e.g. "Bỏ qua" on 08.
    final session = container.read(sessionProvider);
    container
        .read(verifyDeferredProvider.notifier)
        .defer((session as SessionSignedIn).user.uid);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(MemoryStoryPhotosScreen), findsOneWidget);

    // Let the app's timers end with it.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(minutes: 1));
  });
}
