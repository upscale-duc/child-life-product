@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_widgets.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_fixtures.dart';

/// The journal entry's picture layouts (owner, 2026-10-23): one to six items, photos and videos
/// mixed, a portrait single — Light / Night care.
void main() {
  final memory = mockJournal().memories.first;
  final at = DateTime(2026, 10, 8, 9);
  const colours = ['peach', 'mint', 'sun', 'lilac', 'peach', 'mint'];
  List<dynamic> items(int n, {int video = -1}) => [
    for (var i = 0; i < n; i++)
      mediaItem(
        memory.id,
        at,
        colour: colours[i],
        video: i == video,
        durationMs: i == video ? 35000 : null,
      ),
  ];
  final cases = {
    'one_and_two': [items(1), items(2, video: 1)],
    'three_and_four': [items(3, video: 0), items(4)],
    'five_and_more': [items(5), items(6, video: 2)],
  };
  for (final MapEntry(key: name, value: sets) in cases.entries) {
    for (final palette in ClPalette.values) {
      testWidgets('$name ${palette.name}', (tester) async {
        mediaBytes = FakeMediaBytes();
        tester.view.physicalSize = const Size(375, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('golden'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildClTheme(palette),
              locale: const Locale('vi'),
              supportedLocales: const [Locale('vi'), Locale('en')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) => Scaffold(
                  backgroundColor: context.cl.colors.cloud,
                  body: ListView(
                    padding: const EdgeInsets.all(ClSpace.s4),
                    children: [
                      for (final s in sets) ...[
                        MemoryEntryCard(
                          memory: memory,
                          items: s.cast(),
                          myUid: 'u_mai',
                          dateLabel: 'Hôm nay · 9:20',
                          onOpen: (_) {},
                        ),
                        const SizedBox(height: ClSpace.s3),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/journal/${name}_${palette.name}.png'),
        );
      });
    }
  }
}
