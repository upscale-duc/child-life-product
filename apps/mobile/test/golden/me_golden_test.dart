@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/me/account_screen.dart';
import 'package:child_life/features/me/baby_profile_screens.dart';
import 'package:child_life/features/me/help_screen.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_screen.dart';
import 'package:child_life/features/me/notifications_screen.dart';
import 'package:child_life/features/me/profile_screen.dart';
import 'package:child_life/features/me/storage_screens.dart';
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

/// S11 Me, storage, baby profiles, your profile, account and the engineering-supplied gaps in
/// Light / Night care × vi / en at 375 × 812. Regenerate on macOS:
/// flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

final _growth = [
  CareRecord(
    id: 'g1',
    babyId: teddyId,
    type: CareType.growth,
    occurredAt: DateTime(2026, 10, 8, 8),
    weightKg: 4.3,
    lengthCm: 54.5,
    author: CareAuthor.of(mai),
    createdBy: mai.uid,
  ),
];

List<Override> _base({
  Membership? me,
  FamilyStorage? storage,
  AccountDoc account = const AccountDoc(),
  List<ExportJob> exports = const [],
  NotificationPrefs prefs = const NotificationPrefs(),
}) => [
  ...familyOverrides(
    me: me,
    growth: _growth,
    now: DateTime(2026, 10, 8, 10),
    email: '${(me ?? mai).displayName.split(' ').last.toLowerCase()}@gmail.com',
    providers: const ['password', 'apple.com'],
    account: account,
    prefs: prefs,
  ),
  ...memoryOverrides(),
  ...meOverrides(storage: storage, exports: exports),
];

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(Scaffold).first));

Widget _me() => const MeScreen();

final _cases = <String, _Case>{
  '13a_me_parent': (build: _me, overrides: _base, act: null),
  '13a_offer': (
    build: _me,
    overrides: () => _base(
      me: minh,
      account: const AccountDoc(
        offer: OwnershipOffer(
          familyId: 'f_1',
          fromName: 'Mai',
          babyIds: [teddyId],
        ),
      ),
    ),
    act: null,
  ),
  '13g_me_caregiver': (build: _me, overrides: () => _base(me: lan), act: null),
  '13h_me_relative': (build: _me, overrides: () => _base(me: hoa), act: null),
  '13b_storage': (
    build: () => const StorageScreen(),
    overrides: _base,
    act: null,
  ),
  '13c_storage_near': (
    build: () => const StorageScreen(),
    overrides: () => _base(storage: mockStorage(teddyGb: 6.1, naGb: 2.1)),
    act: null,
  ),
  '13d_storage_full': (
    build: () => const StorageScreen(),
    overrides: () => _base(storage: mockStorage(teddyGb: 7.4, naGb: 2.6)),
    act: null,
  ),
  '13e_request': (
    build: () => const StorageScreen(),
    overrides: () => _base(storage: mockStorage(teddyGb: 7.4, naGb: 2.6)),
    act: (t) async {
      await t.scrollUntilVisible(find.text(_l10n(t).stContact), 300);
      await t.pumpAndSettle();
      await t.tap(find.text(_l10n(t).stContact));
    },
  ),
  '13i_babies': (
    build: () => const BabyProfilesScreen(),
    overrides: _base,
    act: null,
  ),
  '13j_baby': (
    build: () => const BabyProfileViewScreen(babyId: teddyId),
    overrides: _base,
    act: null,
  ),
  '13k_edit': (
    build: () => const BabyEditScreen(babyId: teddyId),
    overrides: _base,
    act: null,
  ),
  '13l_delete': (
    build: () => const BabyProfileViewScreen(babyId: teddyId),
    overrides: _base,
    act: (t) async {
      final card = find.text(_l10n(t).bpDelete('Teddy'));
      await t.scrollUntilVisible(card, 300);
      await t.tap(card);
    },
  ),
  '13m_profile': (
    build: () => const ProfileScreen(),
    overrides: _base,
    act: null,
  ),
  '13n_account': (
    build: () => const AccountScreen(),
    overrides: () => _base(exports: mockExports),
    act: null,
  ),
  '13n_account_member': (
    build: () => const AccountScreen(),
    overrides: () => _base(me: minh),
    act: null,
  ),
  'notifications': (
    build: () => const NotificationsScreen(),
    overrides: () => _base(prefs: const NotificationPrefs(messages: false)),
    act: null,
  ),
  'help': (build: () => const HelpScreen(), overrides: _base, act: null),
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
          await tester.pumpAndSettle();
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/s11/${name}_${palette.name}_${locale.languageCode}.png',
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
