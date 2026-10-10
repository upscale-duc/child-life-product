import 'package:child_life/app/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

String? go(GuardState state, String location, {bool splashDone = true}) =>
    guardRoute(state: state, location: location, splashDone: splashDone);

void main() {
  group('route guard (S2 flow 1–4)', () {
    test('splash waits for the session and the ≤1 s animation', () {
      expect(go(GuardState.loading, Routes.splash), isNull);
      expect(
        go(GuardState.signedOut, Routes.splash, splashDone: false),
        isNull,
      );
      expect(go(GuardState.signedOut, Routes.splash), Routes.welcome);
      expect(go(GuardState.ready, Routes.splash), Routes.today);
      expect(go(GuardState.needsSetup, Routes.splash), Routes.who);
    });

    test('signed-out users stay on welcome, tour and auth screens only', () {
      for (final l in [
        Routes.welcome,
        Routes.tour,
        Routes.signIn,
        Routes.email,
        '${Routes.forgot}?email=a@b.c',
        Routes.exists,
      ]) {
        expect(go(GuardState.signedOut, l), isNull, reason: l);
      }
      expect(go(GuardState.signedOut, Routes.today), Routes.welcome);
      expect(go(GuardState.signedOut, Routes.who), Routes.welcome);
      expect(go(GuardState.signedOut, Routes.appearance), Routes.welcome);
    });

    test('a new email account sees "Kiểm tra email" first (08)', () {
      expect(go(GuardState.needsVerifyPrompt, Routes.email), Routes.verify);
      expect(go(GuardState.needsVerifyPrompt, Routes.verify), isNull);
    });

    test('accounts without a baby go through setup (10a → 11 → 12)', () {
      expect(go(GuardState.needsSetup, Routes.signIn), Routes.who);
      expect(go(GuardState.needsSetup, Routes.verify), Routes.who);
      expect(go(GuardState.needsSetup, Routes.today), Routes.who);
      for (final l in [
        Routes.who,
        Routes.babyProfile,
        Routes.trackers,
        Routes.appearance,
      ]) {
        expect(go(GuardState.needsSetup, l), isNull, reason: l);
      }
    });

    test(
      'accounts with a baby land on Today and never see onboarding again',
      () {
        for (final l in [
          Routes.welcome,
          Routes.tour,
          Routes.signIn,
          Routes.verify,
          Routes.who,
          Routes.trackers,
        ]) {
          expect(go(GuardState.ready, l), Routes.today, reason: l);
        }
        expect(go(GuardState.ready, Routes.today), isNull);
        expect(go(GuardState.ready, Routes.appearance), isNull);
      },
    );

    test('dev tools are reachable in every state', () {
      for (final s in GuardState.values) {
        expect(go(s, Routes.showcase), isNull);
      }
    });
  });
}
