import 'package:child_life/app/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

String? go(
  GuardState state,
  String location, {
  bool splashDone = true,
  bool lostAccess = false,
  bool addingBaby = false,
  bool returning = false,
}) => guardRoute(
  state: state,
  location: location,
  splashDone: splashDone,
  lostAccess: lostAccess,
  addingBaby: addingBaby,
  returning: returning,
);

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

  group('route guard (S3 invites and access)', () {
    const joinFlow = [
      Routes.join,
      Routes.joinScan,
      Routes.joinInvite,
      Routes.joinConfirm,
      '${Routes.joinClosed}?reason=expired',
      '${Routes.inviteLink}/AbCdEfGhIjKlMnOpQrStUvWxYz012345',
    ];

    test('invites open signed out, mid-setup and with a baby (15–17, /i)', () {
      for (final l in joinFlow) {
        for (final s in [
          GuardState.signedOut,
          GuardState.needsSetup,
          GuardState.joining,
          GuardState.ready,
        ]) {
          expect(go(s, l), isNull, reason: '$s $l');
        }
      }
    });

    test('a temporary identity without a baby stays in the join flow', () {
      expect(go(GuardState.joining, Routes.today), Routes.join);
      expect(go(GuardState.joining, Routes.who), Routes.join);
      expect(go(GuardState.joining, Routes.splash), Routes.join);
    });

    test('family screens need a baby', () {
      expect(go(GuardState.signedOut, Routes.family), Routes.welcome);
      expect(go(GuardState.needsSetup, Routes.invite), Routes.who);
      expect(go(GuardState.ready, Routes.invite), isNull);
      expect(go(GuardState.ready, Routes.saveAccountEmail), isNull);
    });

    test('lost access shows 9d first, in any signed-in state (R-025)', () {
      for (final s in [
        GuardState.ready,
        GuardState.needsSetup,
        GuardState.joining,
      ]) {
        expect(go(s, Routes.family, lostAccess: true), Routes.lostAccess);
        expect(go(s, Routes.lostAccess, lostAccess: true), isNull);
      }
      expect(go(GuardState.ready, Routes.lostAccess), Routes.splash);
    });

    test('"Thêm hồ sơ bé" reopens setup only while adding', () {
      expect(go(GuardState.ready, Routes.who), Routes.today);
      expect(go(GuardState.ready, Routes.who, addingBaby: true), isNull);
      expect(go(GuardState.ready, Routes.trackers, addingBaby: true), isNull);
    });
  });

  group('returning device (v1.0 368:837)', () {
    test('signed out, it opens R1 instead of 01 and the tour', () {
      expect(
        go(GuardState.signedOut, Routes.splash, returning: true),
        Routes.welcomeBack,
      );
      expect(
        go(GuardState.signedOut, Routes.welcome, returning: true),
        Routes.welcomeBack,
      );
      expect(
        go(GuardState.signedOut, Routes.tour, returning: true),
        Routes.welcomeBack,
      );
      expect(
        go(GuardState.signedOut, Routes.today, returning: true),
        Routes.welcomeBack,
      );
    });

    test('sign-in, email and invites stay open; ready leaves R1', () {
      expect(
        go(GuardState.signedOut, Routes.welcomeBack, returning: true),
        isNull,
      );
      expect(go(GuardState.signedOut, Routes.email, returning: true), isNull);
      expect(go(GuardState.signedOut, Routes.join, returning: true), isNull);
      expect(go(GuardState.ready, Routes.welcomeBack), Routes.today);
    });
  });

  group('opened links (invite email OneLink, 2026-10-12)', () {
    const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz012345';

    test('an invite OneLink becomes /i/{token}, before the session loads', () {
      const link =
          '/AbCd?deep_link_value=invite&deep_link_sub1=$token&pid=invite_email';
      for (final s in GuardState.values) {
        expect(go(s, link), '${Routes.inviteLink}/$token', reason: '$s');
      }
      expect(go(GuardState.loading, link, splashDone: false), isNotNull);
    });

    test('other or broken OneLinks land on the splash, then Hôm nay', () {
      expect(go(GuardState.ready, '/AbCd?deep_link_value=story'), Routes.splash);
      expect(
        go(GuardState.ready, '/AbCd?deep_link_value=invite&deep_link_sub1=x'),
        Routes.splash,
      );
      expect(oneLinkLocation('${Routes.inviteLink}/$token'), isNull);
    });

    test('links arrive with their host; the guard sees path and query', () {
      expect(
        appLocation(Uri.parse('https://dev.childlife.app/i/$token')),
        '/i/$token',
      );
      expect(
        appLocation(Uri.parse('https://childlife.onelink.me/AbCd?a=1')),
        '/AbCd?a=1',
      );
      expect(appLocation(Uri.parse('https://dev.childlife.app')), '/');
      expect(appLocation(Uri.parse('/today')), '/today');
    });
  });
}
