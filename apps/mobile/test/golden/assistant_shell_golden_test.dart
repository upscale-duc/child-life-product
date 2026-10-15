@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// Hôm nay in the real tab shell (stub tab content): Chat/Nút trợ lý as Lumi (627:62667, its
/// still ring: goldens run with animations off) 12 above the "+", and 12 above the upload pill
/// when uploads are waiting, never over it; and Lumi's first-run tooltip (669:64442, D-076 #11).
/// Light / Night care × vi / en, with a home indicator inset. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_shell_golden_test.dart

QueueBatch _waitingBatch() => QueueBatch(
  batchId: 'bat_${'d' * 32}',
  babyId: teddyId,
  memoryId: 'mem_${'d' * 32}',
  request: const {'audience': 'family', 'notifyFamily': true},
  createdAt: DateTime(2026, 10, 8),
  sessionCreated: true,
  items: [
    for (final n in ['IMG_3d01.HEIC', 'IMG_3d02.HEIC'])
      QueueItem(
        mediaId: 'med_${n.hashCode.toRadixString(16).padLeft(32, '0')}',
        type: MediaKind.photo,
        name: n,
        localPath: '/nope/$n',
        contentType: 'image/jpeg',
        bytes: 3400000,
        captureAt: DateTime(2026, 10, 8),
        state: QueueState.paused,
      ),
  ],
);

GoRouter _router() => GoRouter(
  initialLocation: Routes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.family,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: root,
                builder: (context, _) => const Scaffold(body: SizedBox()),
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  for (final (name, uploads, intro) in const [
    ('today_fab', false, false),
    ('today_fab_pill', true, false),
    ('today_lumi_intro', false, true),
  ]) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({
            // The tooltip shows once per person; only its own golden shows it.
            if (!intro) LumiIntroSeenNotifier.keyFor(mai.uid): true,
          });
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                ...careOverrides(),
                ...memoryOverrides(
                  network: NetworkKind.none,
                  store: MemoryQueueStore()
                    ..saved = [if (uploads) _waitingBatch()],
                ),
                assistantAccessProvider.overrideWith(
                  (ref, babyId) => const AssistantAccess(),
                ),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp.router(
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
                    routerConfig: _router(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (intro) {
            await tester.pump(AssistantFloatingEntry.introDelay);
            await tester.pumpAndSettle();
          }
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/as/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
