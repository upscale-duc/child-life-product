@Tags(['golden'])
library;

import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/auth/auth_screens.dart';
import 'package:child_life/features/auth/sign_out_sheet.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/family_screen.dart';
import 'package:child_life/features/family/invite_link_join.dart';
import 'package:child_life/features/family/join_screens.dart';
import 'package:child_life/features/me/baby_profile_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// Account and family error states from the 2026-10-26 flow audit (§2.7 FJ, §2.8 AU) in
/// Light / Night care × vi / en at 375 × 812. Regenerate on macOS:
/// flutter test test/golden/account_family_states_golden_test.dart --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

const _lookup = InviteLookup.code('482913');

/// FJ-1: the preview cannot be read (offline), then would succeed.
class _OfflineRepo extends Fake implements FamilyRepository {
  @override
  Future<InvitePreview> previewInvite(InviteLookup lookup) async =>
      throw const FamilyException(FamilyFailure.network);
}

/// AU-2: screen 10 after "Tạo tài khoản" with an email that has an account.
class _ExistsAuth extends Fake implements AuthRepository {
  @override
  String? pendingEmail = 'mai.nguyen@gmail.com';

  @override
  void clearPendingLink() {}
}

/// A screen with the sheet open over it, as after the tap that opens it.
Widget _sheet(Widget Function(BuildContext host) sheet) => Scaffold(
  body: Builder(
    builder: (host) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showClSheet<void>(context: host, builder: (_) => sheet(host)),
      );
      return const SizedBox.expand();
    },
  ),
);

List<Override> _family({bool anonymous = false}) => [
  ...familyOverrides(anonymous: anonymous, now: DateTime(2026, 10, 8, 10)),
  ...memoryOverrides(),
  ...meOverrides(),
];

List<Override> _signedOut() => [
  sessionProvider.overrideWithValue(const SessionSignedOut()),
];

final _cases = <String, _Case>{
  // FJ-1: offline is not "Không tìm thấy lời mời".
  'fj1_invite_offline': (
    build: () => const AcceptInviteScreen(lookup: _lookup),
    overrides: () => [
      ..._signedOut(),
      familyRepositoryProvider.overrideWithValue(_OfflineRepo()),
      onlineProvider.overrideWith((ref) => Stream.value(false)),
    ],
    act: null,
  ),
  // FJ-2 / D-127 Q3: the joiner's own reason when no writer seat is left.
  'fj2_join_full': (
    build: () => AcceptInviteScreen(
      lookup: _lookup,
      preview: invitePreview(seatsFull: true),
    ),
    overrides: _signedOut,
    act: null,
  ),
  // FJ-4: joined; the membership has not reached the phone yet.
  'fj4_join_arriving': (
    build: () => Builder(
      builder: (c) => JoiningProgress(
        message: AppLocalizations.of(c).joinArriving('Teddy'),
      ),
    ),
    overrides: _signedOut,
    act: null,
  ),
  // FJ-5: the member list failed while online: no blame on the network, "Thử lại".
  'fj5_members_error': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: () => [
      ...familyOverrides(
        now: DateTime(2026, 10, 8, 10),
        membersStream: () => Stream.error(StateError('denied')),
      ),
    ],
    act: null,
  ),
  // AU-2: every way in, including a sign-in link to the email.
  'au2_exists': (
    build: () => const AccountExistsScreen(),
    overrides: () => [
      ..._signedOut(),
      authRepositoryProvider.overrideWithValue(_ExistsAuth()),
    ],
    act: null,
  ),
  // AU-3: changes still on the phone are named before signing out.
  'au3_sign_out_unsent': (
    build: () => _sheet(
      (host) =>
          SignOutSheet(anonymous: false, unsent: 3, uploads: 0, host: host),
    ),
    overrides: _family,
    act: null,
  ),
  'au3_sign_out_anon_unsent': (
    build: () => _sheet(
      (host) =>
          SignOutSheet(anonymous: true, unsent: 2, uploads: 0, host: host),
    ),
    overrides: () => _family(anonymous: true),
    act: null,
  ),
  // AU-5: the edit form waits for the saved profile; Save is off until then.
  'au5_baby_edit_loading': (
    build: () => const BabyEditScreen(babyId: teddyId),
    overrides: () => [
      ...familyOverrides(
        now: DateTime(2026, 10, 8, 10),
        profileStream: () => StreamController<BabyPrivateProfile?>().stream,
      ),
      ...memoryOverrides(),
      ...meOverrides(),
    ],
    act: null,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          mediaBytes = FakeMediaBytes();
          SharedPreferences.setMockInitialValues(const {});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                // Figma draws iOS, with Sign in with Apple (D-071).
                appleSignInShownProvider.overrideWithValue(true),
                ...c.overrides(),
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
                    routerConfig: router,
                  ),
                ),
              ),
            ),
          );
          // Spinners never settle: pump a fixed time instead.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await c.act?.call(tester);
          await tester.pump(const Duration(milliseconds: 600));
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/au/${name}_${palette.name}_${locale.languageCode}.png',
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
