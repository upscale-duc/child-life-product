import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/experience_repository.dart';
import 'package:child_life/features/adaptive/today_adaptive.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/today/header_settings.dart';
import 'package:child_life/features/today/header_appearance_screen.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  testWidgets(
    'appearance previews without saving; Apply persists and Back discards the draft',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/settings'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const HeaderAppearanceScreen(),
          ),
        ],
      );
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        router: router,
        overrides: familyOverrides(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ảnh đại diện của bé'));
      await tester.pumpAndSettle();
      expect(
        container.read(headerSettingsProvider).background,
        HeaderBackground.pattern,
      );
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(
        container.read(headerSettingsProvider).background,
        HeaderBackground.avatar,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoạ tiết theo buổi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ClBackButton).first);
      await tester.pumpAndSettle();
      expect(
        container.read(headerSettingsProvider).background,
        HeaderBackground.avatar,
      );
    },
  );

  test(
    'greeting boundaries follow the baby-local clock; birthday requires a known matching date',
    () {
      for (final (hour, moment) in [
        (0, HeaderMoment.evening),
        (4, HeaderMoment.evening),
        (5, HeaderMoment.morning),
        (10, HeaderMoment.morning),
        (11, HeaderMoment.afternoon),
        (17, HeaderMoment.afternoon),
        (18, HeaderMoment.evening),
      ]) {
        expect(headerMoment(DateTime(2026, 10, 27, hour)), moment);
      }
      expect(
        headerMoment(
          DateTime(2026, 10, 27, 8),
          birthday: DateTime(2025, 10, 27),
        ),
        HeaderMoment.birthday,
      );
      expect(
        headerMoment(
          DateTime(2026, 10, 27, 8),
          birthday: DateTime(2025, 10, 26),
        ),
        HeaderMoment.morning,
      );
    },
  );

  test(
    'appearance persists locally per account and baby; invalid data falls back safely',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer container() => ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedMembershipProvider.overrideWithValue(mai),
        ],
      );
      final first = container();
      expect(
        first.read(headerSettingsProvider).background,
        HeaderBackground.pattern,
      );
      await first
          .read(headerSettingsProvider.notifier)
          .save(
            const HeaderSettings(
              background: HeaderBackground.memory,
              mediaId: 'photo_1',
              showDuty: false,
            ),
          );
      first.dispose();
      final second = container();
      expect(second.read(headerSettingsProvider).mediaId, 'photo_1');
      expect(second.read(headerSettingsProvider).showDuty, false);
      second.dispose();
      await prefs.setString('today.header.${mai.uid}.${mai.babyId}', '{broken');
      final fallback = container();
      expect(
        fallback.read(headerSettingsProvider).background,
        HeaderBackground.pattern,
      );
      fallback.dispose();
    },
  );

  testWidgets(
    'hidden care status shortens the real header and is not rendered in the list',
    (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: [
          ...careOverrides(),
          ...adaptiveOverrides(
            band: AgeBand.b0_1,
            repo: FakeExperienceRepository(
              Experience.defaults(
                AgeBand.b0_1,
              ).copyWith(shown: [WidgetId.careDuty]),
            ),
          ),
        ],
      );
      expect(find.byType(CareDutyChip), findsOneWidget);
      final shown = tester
          .getSize(find.byKey(const Key('todayLivingHeader')))
          .height;
      container
          .read(experienceProvider(teddyId).notifier)
          .set(
            container
                .read(experienceProvider(teddyId))
                .copyWith(shown: [], hidden: [WidgetId.careDuty]),
          );
      await tester.pumpAndSettle();
      expect(find.byType(CareDutyChip), findsNothing);
      final hidden = tester
          .getSize(find.byKey(const Key('todayLivingHeader')))
          .height;
      expect(shown - hidden, 96);
    },
  );

  testWidgets(
    'care status is visibility-only in customization: no pin or drag row',
    (tester) async {
      await pumpRouted(
        tester,
        const AxCustomizeScreen(),
        overrides: [
          ...careOverrides(),
          ...adaptiveOverrides(
            band: AgeBand.b0_1,
            repo: FakeExperienceRepository(
              Experience.defaults(
                AgeBand.b0_1,
              ).copyWith(shown: [WidgetId.careDuty]),
            ),
          ),
        ],
      );
      final toggle = find.byKey(const Key('hhDutyVisibility'));
      await tester.scrollUntilVisible(
        toggle,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(toggle, findsOneWidget);
      expect(find.byKey(const ValueKey(WidgetId.careDuty)), findsNothing);
    },
  );

  testWidgets('failed duty load never reports that nobody has taken care', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const Scaffold(body: CareDutyChip(hero: true)),
      overrides: [
        ...familyOverrides(),
        careDutyProvider(
          teddyId,
        ).overrideWith((ref) => Stream<CareDuty?>.error(StateError('offline'))),
      ],
    );
    expect(find.text('Chưa ai nhận trông bé'), findsNothing);
    expect(find.textContaining('Thử lại'), findsOneWidget);
  });
}
