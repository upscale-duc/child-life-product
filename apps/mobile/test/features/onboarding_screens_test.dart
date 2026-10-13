import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/appearance/appearance_screen.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/auth/auth_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/family/family_models.dart';
import 'package:child_life/features/family/my_invites.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:child_life/features/onboarding/welcome_screens.dart';
import 'package:child_life/features/onboarding/widgets/journey_hero.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/core/widgets/cl_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';

/// Pumps [screen] at '/' with stub pages for every other route; returns the visited paths.
Future<(List<String>, ProviderContainer)> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
  List<MyInvite> myInvites = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final visited = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/:a/:b',
        builder: (_, s) {
          visited.add(s.uri.path);
          return const Scaffold(body: Text('stub'));
        },
      ),
      GoRoute(
        path: '/:a',
        builder: (_, s) {
          visited.add(s.uri.path);
          return const Scaffold(body: Text('stub'));
        },
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      // Invites mailed to me (owner, 2026-10-11); no Functions in widget tests.
      myInvitesProvider.overrideWith((ref) async => myInvites),
      sharedPreferencesProvider.overrideWithValue(prefs),
      providerDisplayNameProvider.overrideWithValue(null),
      minuteClockProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: buildClTheme(ClPalette.light),
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
  );
  await tester.pumpAndSettle();
  return (visited, container);
}

void main() {
  testWidgets(
    '00 Splash takes the launch screen\'s colours, not the app palette',
    (tester) async {
      // Phone in Dark Mode, app set to "Sáng": the native launch screen is dark.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      Color? background() => tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(SplashScreen),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
      Future<void> pump(ClPalette app) => tester.pumpWidget(
        MaterialApp(
          theme: buildClTheme(app),
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SplashScreen(),
        ),
      );
      Brightness? icons() => tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
          )
          .value
          .statusBarIconBrightness;
      await pump(ClPalette.light);
      expect(background(), nightCareColors.cloud);
      // The status bar reads on the splash, not on the app palette.
      expect(icons(), Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await pump(ClPalette.nightCare);
      await tester.pump();
      expect(background(), lightColors.cloud);
      expect(icons(), Brightness.dark);
    },
  );

  testWidgets(
    '00 Splash is the launch screen itself: only the 150 pt mark, centred',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildClTheme(ClPalette.light),
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SplashScreen(),
        ),
      );
      final screen = tester.getRect(find.byType(SplashScreen));
      final mark = tester.getRect(find.byType(ClLogo));
      expect(mark.size, const Size.square(SplashScreen.markSize));
      expect(mark.center, screen.center);
      // No wordmark, tagline or glow: anything more reads as a second splash.
      expect(find.byType(Text), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('01 Chào mừng: three entries, in both languages', (tester) async {
    final (visited, _) = await pumpScreen(tester, const WelcomeScreen());
    // v1.0 (368:843): the growth journey and its new copy.
    expect(
      find.text('Cùng con lớn lên,\nđồng hành từng bước.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời.',
      ),
      findsOneWidget,
    );
    expect(find.byType(JourneyHero), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Hành trình lớn lên của con')),
      findsOneWidget,
    );
    expect(find.text('Bắt đầu chặng đầu cùng con'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(visited, [Routes.signIn]);
  });

  testWidgets('01 in English', (tester) async {
    await pumpScreen(tester, const WelcomeScreen(), locale: const Locale('en'));
    expect(find.text('Start the first stage together'), findsOneWidget);
    expect(find.text('Invite code'), findsOneWidget);
  });

  testWidgets('06 and R1 Chào mừng trở lại: same sheet, R1 has no Back', (
    tester,
  ) async {
    await pumpScreen(tester, const SignInScreen());
    expect(find.text('Chào bạn'), findsOneWidget);
    expect(
      find.text('Đăng nhập để bắt đầu hành trình cùng con.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Quay lại'), findsOneWidget);

    await pumpScreen(tester, const SignInScreen(returning: true));
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(
      find.text('Đăng nhập để tiếp tục hành trình cùng con.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Quay lại'), findsNothing);
    // Email: "Đăng nhập" and "Đăng ký" (owner, 2026-10-13, D-067).
    expect(find.text('Dùng email'), findsNothing);
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('06: "Tôi có mã mời" opens 15 Nhập mã mời', (tester) async {
    final (visited, _) = await pumpScreen(tester, const SignInScreen());
    await tester.ensureVisible(find.text('Tôi có mã mời'));
    await tester.tap(find.text('Tôi có mã mời'));
    await tester.pumpAndSettle();
    expect(visited.last, Routes.join);
  });

  testWidgets('10a: an invite mailed to me shows before starting a baby', (
    tester,
  ) async {
    await pumpScreen(tester, const WhoAreYouScreen(), myInvites: [binInvite]);
    expect(find.text('Lời mời cho bạn'), findsOneWidget);
    expect(find.text('Mẹ Hà mời bạn cùng chăm bé Bin'), findsOneWidget);
    expect(find.text('Đồng ý'), findsOneWidget);
  });

  testWidgets('moon toggles Light ↔ Night care at once', (tester) async {
    final (_, container) = await pumpScreen(tester, const WelcomeScreen());
    // Keep the palette alive so it follows the pinned 10:00 clock (not the real evening).
    container.listen(paletteProvider, (_, _) {});
    await tester.pump();
    final before = container.read(paletteProvider);
    await tester.tap(find.bySemanticsLabel('Đổi giao diện sáng / tối'));
    await tester.pumpAndSettle();
    expect(container.read(paletteProvider), isNot(before));
  });

  testWidgets(
    '02–05 tour: Next pages through, the last page offers "Tạo hồ sơ bé"',
    (tester) async {
      final (visited, _) = await pumpScreen(tester, const TourScreen());
      expect(find.text('Ghi bú, ngủ, tã\nchỉ bằng một tay'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.bySemanticsLabel('Tiếp tục'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Đúng người,\nđúng quyền'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsNothing);
      await tester.tap(find.text('Tạo hồ sơ bé'));
      await tester.pumpAndSettle();
      expect(visited, [Routes.signIn]);
    },
  );

  testWidgets('10a: Tiếp needs a name; "Khác…" asks for the relation', (
    tester,
  ) async {
    final (visited, container) = await pumpScreen(
      tester,
      const WhoAreYouScreen(),
    );
    expect(
      find.text('Cả nhà sẽ thấy “Mẹ ghi” trên từng bản ghi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(visited, isEmpty);

    await tester.enterText(find.byType(EditableText).first, 'Mai');
    await tester.tap(find.text('Khác…'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn là ai với bé'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(visited, isEmpty, reason: 'custom relation still empty');

    await tester.enterText(find.byType(EditableText).last, 'Dì');
    await tester.pumpAndSettle();
    expect(
      find.text('Cả nhà sẽ thấy “Dì ghi” trên từng bản ghi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(visited, [Routes.babyProfile]);
    final draft = container.read(setupDraftProvider);
    expect(
      (draft.displayName, draft.relation, draft.relationCustom),
      ('Mai', Relation.other, 'Dì'),
    );
  });

  testWidgets(
    '12: counter follows the selection; none selected disables Xong',
    (tester) async {
      final (_, container) = await pumpScreen(tester, const TrackersScreen());
      expect(find.text('Xong · 4 mục'), findsOneWidget);
      await tester.tap(find.text('Tăng trưởng'));
      await tester.pumpAndSettle();
      expect(find.text('Xong · 5 mục'), findsOneWidget);
      for (final label in [
        'Bú bình',
        'Bú mẹ',
        'Giấc ngủ',
        'Thay tã',
        'Tăng trưởng',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(find.text('Chọn ít nhất một mục'), findsOneWidget);
      expect(container.read(setupDraftProvider).trackers, isEmpty);
    },
  );

  testWidgets('12 in English uses plurals', (tester) async {
    await pumpScreen(
      tester,
      const TrackersScreen(),
      locale: const Locale('en'),
    );
    expect(find.text('Done · 4 items'), findsOneWidget);
  });

  testWidgets('13: theme choice and schedule apply immediately', (
    tester,
  ) async {
    final (_, container) = await pumpScreen(tester, const AppearanceScreen());
    expect(find.text('Theo lịch 21:00 – 06:00'), findsOneWidget);
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(
      container.read(appearanceSettingsProvider).theme,
      ThemePreference.dark,
    );
    expect(container.read(paletteProvider), ClPalette.nightCare);
  });

  test('13a duration crosses midnight', () {
    expect(
      windowMinutes(
        const TimeOfDay(hour: 21, minute: 0),
        const TimeOfDay(hour: 6, minute: 0),
      ),
      9 * 60,
    );
    expect(
      windowMinutes(
        const TimeOfDay(hour: 22, minute: 30),
        const TimeOfDay(hour: 5, minute: 0),
      ),
      6 * 60 + 30,
    );
  });
}
