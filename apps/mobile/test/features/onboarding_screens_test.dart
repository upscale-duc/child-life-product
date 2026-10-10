import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/appearance/appearance_screen.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:child_life/features/onboarding/welcome_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [screen] at '/' with stub pages for every other route; returns the visited paths.
Future<(List<String>, ProviderContainer)> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
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
  testWidgets('01 Chào mừng: three entries, in both languages', (tester) async {
    final (visited, _) = await pumpScreen(tester, const WelcomeScreen());
    expect(find.text('Cùng chăm con,\ngiữ trọn tuổi thơ'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(visited, [Routes.signIn]);
  });

  testWidgets('01 in English', (tester) async {
    await pumpScreen(tester, const WelcomeScreen(), locale: const Locale('en'));
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Invite code'), findsOneWidget);
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
