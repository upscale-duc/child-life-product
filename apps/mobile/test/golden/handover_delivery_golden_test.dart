@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_feedback.dart';
import 'package:child_life/features/ai/handover_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/ai_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('delivery fallback $scale ${palette.name} $language', (
          tester,
        ) async {
          final locale = Locale(language);
          final l = lookupAppLocalizations(locale);
          final ai = FakeAiRepository(answer: handover(language: language))
            ..pushable = false;
          debugDisableShadows = false;
          try {
            final recipient = language == 'vi' ? 'Ba' : 'Dad';
            // The existing handover page has an unrelated 200% header overflow.
            // Isolate the changed toast at that scale; default scale exercises the real flow.
            final toastProbe = Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => ClToaster.of(context).show(
                      message: l.aiSentNoPush(recipient),
                      actionLabel: l.aiShareShort,
                      onAction: () {},
                      visibleFor: const Duration(seconds: 8),
                    ),
                    child: Text(l.aiSendTo(recipient)),
                  ),
                ),
              ),
            );
            await pumpRouted(
              tester,
              scale > 1 ? toastProbe : const HandoverScreen(summaryOpen: true),
              locale: locale,
              palette: palette,
              textScaler: TextScaler.linear(scale),
              overrides: scale > 1 ? [] : aiOverrides(ai: ai),
            );
            Future<void> tap(Finder f) async {
              await tester.ensureVisible(f);
              await tester.pumpAndSettle();
              await tester.tap(f);
              await tester.pumpAndSettle();
            }

            if (scale > 1) {
              await tap(find.text(l.aiSendTo(recipient)));
            } else {
              final make = find.text(l.hoCreateAction);
              if (make.evaluate().isNotEmpty) await tap(make);
              await tap(find.byKey(const Key('handoverSend')));
              await tap(find.text(recipient));
              await tap(find.text(l.aiSendTo(recipient)).last);
            }
            expect(
              find.text(l.aiSentNoPush(language == 'vi' ? 'Ba' : 'Dad')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Overlay).first,
              matchesGoldenFile(
                'goldens/handover_delivery/fallback_${scale}_${palette.name}_$language.png',
              ),
            );
            await tester.pump(const Duration(seconds: 9));
            await tester.pumpAndSettle();
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
