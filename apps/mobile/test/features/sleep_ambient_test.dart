import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/sleep_ambient.dart';
import 'package:child_life/features/care/timer_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart' show findTabular;

/// Motion spec P10 272:368 + Ambient rules 272:425 on the running sleep ring.
void main() {
  Future<void> pumpRing(
    WidgetTester tester, {
    ClPalette palette = ClPalette.light,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [timerTicksProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: buildClTheme(palette),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => SleepRing(
                      elapsed: const Duration(
                        hours: 1,
                        minutes: 27,
                        seconds: 6,
                      ),
                      label: 'Đang ngủ',
                      since: 'Từ 21:42',
                      color: context.cl.care.sleep.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The ticker starts on this frame: time 0 of the breath.
    await tester.pump();
  }

  double moonScale(WidgetTester tester) => tester
      .widget<ScaleTransition>(find.byKey(const ValueKey('sleep-moon')))
      .scale
      .value;

  double haloOpacity(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(find.byKey(const ValueKey('sleep-halo')))
                  .painter!
              as SleepHaloPainter)
          .opacity;

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets(
    'the moon and halo breathe on a 4 s cycle (0 s → 2 s peak → 4 s)',
    (tester) async {
      await pumpRing(tester);
      expect(moonScale(tester), closeTo(1.0, 1e-6));
      expect(haloOpacity(tester), closeTo(0.35, 1e-6));

      await tester.pump(const Duration(seconds: 1));
      expect(moonScale(tester), closeTo(1.02, 1e-3), reason: 'halfway up');

      await tester.pump(const Duration(seconds: 1));
      expect(moonScale(tester), closeTo(1.04, 1e-3), reason: 'peak at 2 s');
      expect(haloOpacity(tester), closeTo(0.55, 1e-3));

      await tester.pump(const Duration(seconds: 2));
      expect(moonScale(tester), closeTo(1.0, 1e-3), reason: 'back at 4 s');
      expect(haloOpacity(tester), closeTo(0.35, 1e-3));
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'it loops');
      await unmount(tester);
    },
  );

  testWidgets('Reduce Motion: static, only the counter remains', (
    tester,
  ) async {
    await pumpRing(tester, reduceMotion: true);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(moonScale(tester), 1.0);
    expect(haloOpacity(tester), SleepBreath.haloOpacityRest);
    expect(findTabular('01:27:06'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'Night care: same slow 4 s breath, no bounce or flash, and no haptic while running',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpRing(tester, palette: ClPalette.nightCare);

      var peakScale = 0.0;
      var peakAt = Duration.zero;
      for (var ms = 100; ms <= 4000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        final scale = moonScale(tester);
        final opacity = haloOpacity(tester);
        expect(scale, inInclusiveRange(1.0, SleepBreath.moonScalePeak + 1e-9));
        expect(
          opacity,
          inInclusiveRange(
            SleepBreath.haloOpacityRest - 1e-9,
            SleepBreath.haloOpacityPeak + 1e-9,
          ),
        );
        if (scale > peakScale) {
          peakScale = scale;
          peakAt = Duration(milliseconds: ms);
        }
      }
      expect(
        peakAt,
        const Duration(seconds: 2),
        reason: 'not shortened at night',
      );
      expect(peakScale, closeTo(SleepBreath.moonScalePeak, 1e-3));
      expect(calls.where((m) => m.startsWith('HapticFeedback')), isEmpty);
      await unmount(tester);
    },
  );

  testWidgets('pauses in the background and resumes when visible again', (
    tester,
  ) async {
    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(moonScale(tester), greaterThan(1.0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(moonScale(tester), 1.0);
    expect(haloOpacity(tester), SleepBreath.haloOpacityRest);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(moonScale(tester), closeTo(1.04, 1e-3));
    await unmount(tester);
  });
}
