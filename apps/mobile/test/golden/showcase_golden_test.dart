@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/showcase/showcase_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

/// Golden images of every showcase section in Light / Night care × vi / en.
/// Regenerate on macOS: flutter test --tags golden --update-goldens
void main() {
  for (final section in showcaseSections) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('${section.id} ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(375, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            clHarness(
              Builder(
                builder: (context) => ColoredBox(
                  color: context.cl.colors.cloud,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      key: const ValueKey('golden'),
                      child: ColoredBox(
                        color: context.cl.colors.cloud,
                        child: section.builder(context),
                      ),
                    ),
                  ),
                ),
              ),
              palette: palette,
              locale: locale,
              reduceMotion: true,
            ),
          );
          await tester.pumpAndSettle();
          // Real blurred shadows so goldens match devices (flutter_test disables them by default);
          // the debug flag must be restored before the test ends.
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/${section.id}_${palette.name}_${locale.languageCode}.png',
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
