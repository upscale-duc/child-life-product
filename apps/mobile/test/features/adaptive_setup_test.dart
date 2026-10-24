import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/adaptive_setup.dart';
import 'package:child_life/features/adaptive/experience_repository.dart';
import 'package:child_life/features/analytics/product_analytics.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/adaptive_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Adding a child of any age (Figma 930:11858 AX01–AX06, P-175, D-097 Q-088).

class _FakeBabyRepository implements BabyRepository {
  final created = <NewBabyInput>[];

  @override
  Future<String> createBaby(NewBabyInput input) async {
    created.add(input);
    return 'b_new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DateTime _yearsAgo(int years, [int months = 0]) {
  final now = DateTime.now();
  return DateTime(now.year - years, now.month - months, now.day);
}

List<Override> _overrides({
  required FakeExperienceRepository experience,
  _FakeBabyRepository? babies,
  bool adaptive = true,
}) => [
  setupAdaptiveProvider.overrideWithValue(adaptive),
  productAnalyticsReporterProvider.overrideWithValue(null),
  experienceRepositoryProvider.overrideWithValue(experience),
  babyRepositoryProvider.overrideWithValue(babies ?? _FakeBabyRepository()),
  sessionProvider.overrideWithValue(
    SessionSignedIn(
      user: FakeUser(uid: mai.uid),
      memberships: const [],
    ),
  ),
];

void main() {
  group('rules', () {
    test('trackers by band (D-097 Q-088); a child keeps one tracker', () {
      expect(bandTrackers(AgeBand.b0_1), SetupDraft.defaultTrackers);
      expect(bandTrackers(AgeBand.b1_3), {
        TrackerKind.sleep,
        TrackerKind.diaper,
      });
      expect(bandTrackers(AgeBand.b3_6), {TrackerKind.growth});
      expect(bandTrackers(AgeBand.b6_12), {TrackerKind.growth});
    });

    test('the step count follows the goals, not the age', () {
      expect(setupSteps(const [Goal.memories], adding: true), [
        Routes.babyProfile,
        Routes.setupGoals,
        Routes.setupPreview,
      ]);
      expect(
        setupSteps(const [Goal.trackCare], adding: false),
        contains(Routes.trackers),
      );
    });
  });

  testWidgets('AX04: a 4-year-old gets the 3–6 presets, then the preview', (
    tester,
  ) async {
    final (visits, container) = await pumpRouted(
      tester,
      const SetupGoalsScreen(),
      overrides: _overrides(experience: FakeExperienceRepository()),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Na', dateOfBirth: _yearsAgo(4, 7)));
    await tester.pumpAndSettle();
    expect(find.text('Bạn muốn Child Life giúp gì cho Na?'), findsOneWidget);
    expect(find.text('Gợi ý cho 4 tuổi'), findsNWidgets(3));
    expect(find.text('Đã chọn 3 mục'), findsOneWidget);
    await tester.tap(find.byKey(const Key('setupGoalsNext')));
    await tester.pumpAndSettle();
    expect(visits.last.location, Routes.setupPreview);
    expect(container.read(setupDraftProvider).trackers, {TrackerKind.growth});
    expect(container.read(adaptiveSetupProvider).goals, [
      Goal.memories,
      Goal.family,
      Goal.spending,
    ]);
  });

  testWidgets('AX03: a newborn with "Theo dõi bú, ngủ, tã" goes to AX05', (
    tester,
  ) async {
    final (visits, container) = await pumpRouted(
      tester,
      const SetupGoalsScreen(),
      overrides: _overrides(experience: FakeExperienceRepository()),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Teddy', dateOfBirth: _yearsAgo(0, 2)));
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý cho 2 tháng'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('setupGoalsNext')));
    await tester.pumpAndSettle();
    expect(visits.last.location, Routes.trackers);
  });

  testWidgets('"Bỏ qua" keeps the presets and is remembered as skipped', (
    tester,
  ) async {
    final (_, container) = await pumpRouted(
      tester,
      const SetupGoalsScreen(),
      overrides: _overrides(experience: FakeExperienceRepository()),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Bin', dateOfBirth: _yearsAgo(9)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    final setup = container.read(adaptiveSetupProvider);
    expect(setup.skipped, isTrue);
    expect(setup.goals, presetGoals[AgeBand.b6_12]);
  });

  testWidgets('AX06 ranks, then creates the child and keeps the arrangement', (
    tester,
  ) async {
    final experience = FakeExperienceRepository();
    final babies = _FakeBabyRepository();
    final (_, container) = await pumpRouted(
      tester,
      const SetupPreviewScreen(),
      overrides: _overrides(experience: experience, babies: babies),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(
          SetupDraft(
            nickname: 'Na',
            dateOfBirth: _yearsAgo(4, 7),
            trackers: const {TrackerKind.growth},
          ),
        );
    container
        .read(adaptiveSetupProvider.notifier)
        .update(
          const AdaptiveSetup(
            goals: [Goal.memories, Goal.family, Goal.spending],
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay của Na sẽ ưu tiên'), findsOneWidget);
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Lưu khoảnh khắc hôm nay'), lessThan(y('Chi tiêu tháng này')));
    expect(y('Chi tiêu tháng này'), lessThan(y('Nhắc nhở')));
    expect(find.text('Vì: Luôn có'), findsOneWidget);
    // Kỷ niệm 2.0 is a beta a first child may not have: not promised here.
    expect(find.text('Tạo từ kỷ niệm'), findsNothing);
    await tester.tap(find.byKey(const Key('setupPreviewGo')));
    await tester.pumpAndSettle();
    expect(babies.created.single.trackers, {TrackerKind.growth});
    expect(experience.saves.single.goalsSource, GoalsSource.chosen);
    expect(experience.saves.single.bandApplied, AgeBand.b3_6);
  });

  testWidgets('11 → AX02 card from 12 months; flag off → 12 as before', (
    tester,
  ) async {
    final (_, container) = await pumpRouted(
      tester,
      const BabyProfileScreen(),
      overrides: _overrides(experience: FakeExperienceRepository()),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Na', dateOfBirth: _yearsAgo(4, 7)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setupAgeInfo')), findsOneWidget);
    expect(
      find.text('Mọi tính năng của Child Life đều dùng được cho Na.'),
      findsOneWidget,
    );

    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Teddy', dateOfBirth: _yearsAgo(0, 2)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setupAgeInfo')), findsNothing);
    expect(find.byKey(const Key('setupAgeHint')), findsOneWidget);
  });

  testWidgets('flag off: 11 shows neither the hint nor the card', (
    tester,
  ) async {
    final (_, container) = await pumpRouted(
      tester,
      const BabyProfileScreen(),
      overrides: _overrides(
        experience: FakeExperienceRepository(),
        adaptive: false,
      ),
    );
    container
        .read(setupDraftProvider.notifier)
        .update(SetupDraft(nickname: 'Na', dateOfBirth: _yearsAgo(4, 7)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setupAgeInfo')), findsNothing);
    expect(find.byKey(const Key('setupAgeHint')), findsNothing);
  });
}
