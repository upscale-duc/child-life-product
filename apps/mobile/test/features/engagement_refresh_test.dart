import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:child_life/features/engagement/engagement_local.dart';
import 'package:child_life/features/engagement/engagement_repository.dart';

/// Doc 18 #20: every uploaded photo, resume and a 5-minute timer used to call getEngagement, so an
/// evening of saving 69 photos passed the server's 100 calls an hour. Background reasons now
/// settle into few calls; the person's own actions still reload at once.
void main() {
  group('engagementWait', () {
    test(
      'the first load, a user action and a change after a quiet spell call at once',
      () {
        expect(
          engagementWait(immediate: false, sinceLast: null),
          Duration.zero,
        );
        expect(
          engagementWait(
            immediate: true,
            sinceLast: const Duration(seconds: 2),
          ),
          Duration.zero,
        );
        expect(
          engagementWait(
            immediate: false,
            sinceLast: const Duration(minutes: 3),
          ),
          Duration.zero,
        );
      },
    );

    test(
      'a burst waits for 30 s of quiet and keeps calls at least 60 s apart',
      () {
        expect(
          engagementWait(
            immediate: false,
            sinceLast: const Duration(seconds: 5),
          ),
          const Duration(seconds: 55),
        );
        expect(
          engagementWait(
            immediate: false,
            sinceLast: const Duration(seconds: 45),
          ),
          const Duration(seconds: 30),
        );
      },
    );
  });

  group('EngagementRevision', () {
    late DateTime clock;
    setUp(() {
      clock = DateTime(2026, 10, 23, 20);
      EngagementRevision.now = () => clock;
    });
    tearDown(() => EngagementRevision.now = DateTime.now);

    // testWidgets runs on fake time: tester.pump advances the trailing timers.
    testWidgets(
      'background reasons coalesce into one trailing reload per gap',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final revision = container.read(engagementRevisionProvider.notifier);
        // Resume, resume, timer … within two minutes.
        revision.soon();
        expect(container.read(engagementRevisionProvider), 1);
        for (var i = 0; i < 5; i++) {
          clock = clock.add(const Duration(seconds: 10));
          await tester.pump(const Duration(seconds: 10));
          revision.soon();
        }
        expect(container.read(engagementRevisionProvider), 1);
        expect(revision.takeImmediate(), isFalse);
        // One reload when the gap ends, not five.
        clock = clock.add(const Duration(seconds: 70));
        await tester.pump(const Duration(seconds: 70));
        expect(container.read(engagementRevisionProvider), 2);
        await tester.pump(const Duration(minutes: 5));
        expect(container.read(engagementRevisionProvider), 2);
      },
    );

    testWidgets(
      'the person\'s action reloads at once and cancels a pending background reload',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final revision = container.read(engagementRevisionProvider.notifier);
        revision.soon();
        clock = clock.add(const Duration(seconds: 5));
        revision.soon(); // schedules a trailing reload
        revision.refresh(); // dismiss tapped
        expect(container.read(engagementRevisionProvider), 2);
        expect(revision.takeImmediate(), isTrue);
        expect(revision.takeImmediate(), isFalse, reason: 'read once');
        await tester.pump(const Duration(minutes: 3));
        expect(container.read(engagementRevisionProvider), 2);
      },
    );
  });

  test(
    'an upload of 69 photos, one every 8 s (~9 min), calls a handful of times, not 69',
    () {
      // The rule buildEngagement applies: each change restarts the wait; only the build that
      // survives its wait calls.
      var calls = 0;
      DateTime? calledAt;
      var at = DateTime(2026, 10, 23, 20, 5);
      DateTime? pendingCallAt;
      for (var photo = 0; photo < 69; photo++) {
        if (pendingCallAt != null && !pendingCallAt.isAfter(at)) {
          calls++;
          calledAt = pendingCallAt;
          pendingCallAt = null;
        }
        final wait = engagementWait(
          immediate: false,
          sinceLast: calledAt == null ? null : at.difference(calledAt),
        );
        if (wait == Duration.zero) {
          calls++;
          calledAt = at;
          pendingCallAt = null;
        } else {
          pendingCallAt = at.add(wait); // replaces any earlier waiting build
        }
        at = at.add(const Duration(seconds: 8));
      }
      if (pendingCallAt != null) calls++;
      // First photo at once, then one call per 2-minute quiet spell while the burst lasts, then one
      // after the last photo settles.
      expect(calls, inInclusiveRange(2, 7));
    },
  );
}
