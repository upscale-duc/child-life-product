import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/router.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';

/// 15 → 16 → 16b → 16a on the app's real router (owner, 2026-10-12: after a code the app went
/// back to "Nhập mã mời" — the screens had lost their pushed arguments).

class _Auth extends Fake implements AuthRepository {
  _Auth(this.live);
  final ValueNotifier<Session> live;

  @override
  User? get currentUser => switch (live.value) {
    SessionSignedIn(:final user) => user,
    _ => null,
  };

  @override
  Future<void> signInAnonymously() async {
    live.value = const SessionLoading();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    live.value = SessionSignedIn(
      user: FakeUser(uid: 'u_new', isAnonymous: true),
      memberships: const [],
    );
  }
}

class _Repo extends Fake implements FamilyRepository {
  _Repo(this.live);
  final ValueNotifier<Session> live;
  var previews = 0;
  final accepted = <String>[];

  @override
  Future<InvitePreview> previewInvite(InviteLookup lookup) async {
    previews++;
    return invitePreview();
  }

  @override
  Future<String> acceptInvite({
    required InviteLookup lookup,
    required String displayName,
    required Relation relation,
    String? relationCustom,
  }) async {
    accepted.add(displayName);
    final now = live.value as SessionSignedIn;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    live.value = SessionSignedIn(
      user: now.user,
      memberships: [
        member(now.user.uid, displayName, MemberRole.caregiver, relation),
      ],
    );
    return teddyId;
  }
}

bool _isSession(Object o) {
  try {
    return identical((o as dynamic).origin, sessionProvider);
  } on Object {
    return false;
  }
}

Future<(GoRouter, _Repo, ValueNotifier<Session>)> _app(
  WidgetTester tester,
  Session start, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final live = ValueNotifier<Session>(start);
  final repo = _Repo(live);
  final container = ProviderContainer(
    overrides: [
      ...careOverrides().where((o) => !_isSession(o)),
      sharedPreferencesProvider.overrideWithValue(preferences),
      environmentProvider.overrideWithValue(AppEnvironment.dev),
      sessionProvider.overrideWith((ref) {
        void changed() => ref.invalidateSelf();
        live.addListener(changed);
        ref.onDispose(() => live.removeListener(changed));
        return live.value;
      }),
      familyRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(_Auth(live)),
    ],
  );
  _containers.add(container);
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
  await tester.pumpAndSettle();
  return (router, repo, live);
}

String _where(GoRouter router) => router
    .routerDelegate
    .currentConfiguration
    .matches
    .map((m) => m.matchedLocation)
    .join(' > ');

final _containers = <ProviderContainer>[];

/// Lets toasts and timers run out, then disposes the app (and its providers' timers).
Future<void> _close(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpWidget(const SizedBox());
  for (final c in _containers) {
    c.dispose();
  }
  _containers.clear();
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('a code, "Vào ngay", a name: Hôm nay', (tester) async {
    final (router, repo, _) = await _app(tester, const SessionSignedOut());
    router.go(Routes.join);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '482913');
    await tester.pumpAndSettle();
    expect(_where(router), '/join > /join/invite');
    await tester.tap(find.text('Tham gia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vào ngay'));
    await tester.pumpAndSettle();
    expect(_where(router), '/join > /join/invite > /join/confirm');
    await tester.enterText(find.byType(EditableText).first, 'Bà nội Hoa');
    await tester.pump();
    await tester.ensureVisible(find.text('Vào xem Teddy'));
    await tester.tap(find.text('Vào xem Teddy'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repo.accepted, ['Bà nội Hoa']);
    expect(_where(router), '/today');
    await _close(tester);
  });

  testWidgets('from R1 (a device signed in before): "Vào ngay" stays on 16a', (
    tester,
  ) async {
    final (router, repo, _) = await _app(
      tester,
      const SessionSignedOut(),
      prefs: const {'device.signedInBefore': true},
    );
    expect(_where(router), Routes.welcomeBack);
    await tester.ensureVisible(find.text('Tôi có mã mời'));
    await tester.tap(find.text('Tôi có mã mời'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '482913');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tham gia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vào ngay'));
    await tester.pumpAndSettle();
    expect(_where(router), '/join > /join/invite > /join/confirm');
    expect(find.text('Bạn là ai với Teddy?'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('16 and 16a rebuilt without their arguments keep the invite', (
    tester,
  ) async {
    final (router, repo, _) = await _app(
      tester,
      SessionSignedIn(
        user: FakeUser(uid: 'u_mai'),
        memberships: [mai],
      ),
    );
    // No extra: as when the arguments were lost.
    router.push('${Routes.joinInvite}?code=135790');
    await tester.pumpAndSettle();
    expect(_where(router), '/today > /join/invite');
    expect(repo.previews, 1);
    expect(find.text('Tham gia'), findsOneWidget);
    router.push('${Routes.joinConfirm}?code=135790');
    await tester.pumpAndSettle();
    expect(_where(router), '/today > /join/invite > /join/confirm');
    expect(find.text('Bạn là ai với Teddy?'), findsOneWidget);
    // Nothing to go on: 15.
    router.push(Routes.joinConfirm);
    await tester.pumpAndSettle();
    expect(_where(router), endsWith('/join'));
    await _close(tester);
  });
}
