@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/auth/auth_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/family_screen.dart';
import 'package:child_life/features/family/invite_screens.dart';
import 'package:child_life/features/family/join_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';

/// S3 screens and sheets in Light / Night care × vi / en at 375 × 812 (Figma frame size).
/// Regenerate on macOS: flutter test --tags golden --update-goldens

InviteSendArgs _sendArgs({String? email}) => InviteSendArgs(
  babyId: teddyId,
  draft: const InviteDraft(
    relation: Relation.grandmother,
    role: MemberRole.caregiver,
  ),
  ticket: ticket(),
  inviterName: 'Mai',
  babyNickname: 'Teddy',
  email: email,
);

const _na = 'b_00000000000000000002';
const _bin = 'b_00000000000000000003';

/// Mai: Mẹ of Teddy and Na, Người chăm sóc of Bin (125:13223).
List<Override> _threeBabies() {
  Membership on(
    String babyId,
    MemberRole role,
    Relation relation,
    bool owner,
  ) => Membership(
    babyId: babyId,
    uid: 'u_mai',
    role: role,
    relation: relation,
    relationCustom: null,
    displayName: 'Mai',
    status: MembershipStatus.active,
    isOwner: owner,
  );
  final babies = {
    teddyId: teddy,
    _na: Baby(
      id: _na,
      familyId: 'f_1',
      ownerUid: 'u_mai',
      nickname: 'Na',
      avatar: const PresetAvatar(2),
      trackers: const [TrackerKind.bottle],
      timeZone: teddy.timeZone,
    ),
    _bin: Baby(
      id: _bin,
      familyId: 'f_2',
      ownerUid: 'u_other',
      nickname: 'Bin',
      avatar: const PresetAvatar(3),
      trackers: const [TrackerKind.bottle],
      timeZone: teddy.timeZone,
    ),
  };
  return [
    familyMembersProvider.overrideWith(
      (ref, id) => Stream.value([mai, minh, lan, hoa]),
    ),
    pendingInvitesProvider.overrideWith((ref, id) => Stream.value(const [])),
    sessionProvider.overrideWithValue(
      SessionSignedIn(
        user: FakeUser(),
        memberships: [
          on(teddyId, MemberRole.coParent, Relation.mother, true),
          on(_na, MemberRole.coParent, Relation.mother, true),
          on(_bin, MemberRole.caregiver, Relation.nanny, false),
        ],
      ),
    ),
    babyProvider.overrideWith((ref, id) => Stream.value(babies[id])),
    babyPrivateProfileProvider.overrideWith(
      (ref, id) => Stream.value(
        BabyPrivateProfile(
          dateOfBirth: DateTime.now().subtract(
            Duration(days: id == teddyId ? 22 : 430),
          ),
          gender: Gender.girl,
        ),
      ),
    ),
  ];
}

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// The family fixture on the day these goldens were drawn: the baby chip reads Teddy's age
/// (born 17 Sep) from the clock, and on the real date "3 tuần" became "4 tuần".
List<Override> _family({
  Membership? me,
  bool anonymous = false,
  List<MyInvite> myInvites = const [],
}) => familyOverrides(
  me: me,
  anonymous: anonymous,
  myInvites: myInvites,
  now: DateTime(2026, 10, 8, 10),
);

final _cases = <String, _Case>{
  '14a_family': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: _family,
    act: null,
  ),
  // An invite mailed to me: red dot on the switcher, a row in Chọn bé (owner, 2026-10-11).
  '9x_baby_picker_invited': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: () => _family(myInvites: [binInvite]),
    act: (t) async {
      await t.tap(find.byType(ClBabySwitcher));
      await t.pumpAndSettle();
    },
  ),
  '9x_invite_sheet': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: () => _family(myInvites: [binInvite]),
    act: (t) async {
      await t.tap(find.byType(ClBabySwitcher));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('myInvite-${binInvite.inviteId}')));
      await t.pumpAndSettle();
    },
  ),
  '14f_member': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: _family,
    act: (t) => _tap(t, 'Cô Lan'),
  ),
  '14b_invite_role': (
    build: () => const InviteRoleScreen(),
    overrides: _family,
    act: null,
  ),
  '14b2_relative_rights': (
    build: () => const InviteRoleScreen(),
    overrides: _family,
    act: (t) async {
      final l10n = await _l10n(t);
      await _tap(t, l10n.roleRelative);
      await _tap(t, l10n.inviteSeeDetails);
    },
  ),
  '14c_invite_send': (
    build: () => InviteSendScreen(args: _sendArgs()),
    overrides: _family,
    act: null,
  ),
  '14c2_cant_scan': (
    build: () => InviteSendScreen(args: _sendArgs()),
    overrides: _family,
    act: (t) async {
      final l10n = await _l10n(t);
      await _tap(t, l10n.inviteCantScan(l10n.relationGrandmother));
    },
  ),
  '14d_sent': (
    build: () => InviteSentScreen(args: _sendArgs(email: 'ba.ngoai@gmail.com')),
    overrides: _family,
    act: null,
  ),
  '15_enter_code': (
    build: () => const EnterCodeScreen(),
    overrides: () => const [],
    act: null,
  ),
  '16_accept': (
    build: () => AcceptInviteScreen(
      lookup: const InviteLookup.code('482913'),
      preview: invitePreview(),
    ),
    overrides: () => [
      sessionProvider.overrideWithValue(const SessionSignedOut()),
    ],
    act: null,
  ),
  '16b_how_join': (
    build: () => AcceptInviteScreen(
      lookup: const InviteLookup.code('482913'),
      preview: invitePreview(),
    ),
    overrides: () => [
      sessionProvider.overrideWithValue(const SessionSignedOut()),
    ],
    act: (t) async => _tap(t, (await _l10n(t)).joinJoin),
  ),
  '16a_confirm': (
    build: () => ConfirmJoinScreen(
      args: JoinArgs(
        lookup: const InviteLookup.code('482913'),
        preview: invitePreview(),
      ),
    ),
    overrides: () => [
      sessionProvider.overrideWithValue(const SessionSignedOut()),
    ],
    act: null,
  ),
  '16d_save_account': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: () => _family(me: lan, anonymous: true),
    act: (t) async => _tap(t, (await _l10n(t)).unsavedBannerAction),
  ),
  '17_expired': (
    build: () => const InviteClosedScreen(reason: InviteClosedReason.expired),
    overrides: () => const [],
    act: null,
  ),
  '9d_lost_access': (
    build: () => const LostAccessScreen(),
    overrides: () => const [],
    act: null,
  ),
  '9x_baby_picker': (
    build: () => const Scaffold(body: FamilyScreen()),
    overrides: _threeBabies,
    act: (t) async {
      await t.tap(find.textContaining('Teddy ·').first);
      await t.pumpAndSettle();
    },
  ),
};

Future<AppLocalizations> _l10n(WidgetTester tester) async =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
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
          await tester.pumpAndSettle();
          await c.act?.call(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/s3/${name}_${palette.name}_${locale.languageCode}.png',
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
