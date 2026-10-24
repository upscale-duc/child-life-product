import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show babyToday;
import '../home/home_shell.dart';
import '../keepsakes/keepsake_access.dart';
import '../onboarding/setup_draft.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../today/today_personalize.dart'
    show notificationsAfterOnboardingProvider, personalizeAfterSetupProvider;
import 'adaptive_engine.dart';
import 'adaptive_signals.dart' show reportAdaptive;
import 'experience_repository.dart';
import 'today_adaptive.dart';

/// Adding a child of any age (Figma 930:11858 AX01–AX06, D-097): after 11 the person picks what
/// Child Life should help with (AX03/AX04), picks trackers only with "Theo dõi bú, ngủ, tã"
/// (AX05 = 12), and sees the ranked Hôm nay before the child is created (AX06). Off: 10a → 11 →
/// 12 as before.

/// The flow is on: adding a child to a family with `adaptive_experience`; a first child (no
/// family yet, so no per-family rollout) only once the flag is on for everyone.
final setupAdaptiveProvider = Provider<bool>((ref) {
  if (ref.watch(addingBabyProvider)) return ref.watch(adaptiveOnProvider);
  return ref.watch(_publicAdaptiveProvider).value ?? false;
});

final _publicAdaptiveProvider = FutureProvider.autoDispose<bool>((ref) async {
  // No Firebase app (widget tests): off, without touching Firestore.
  if (Firebase.apps.isEmpty) return false;
  try {
    final snap = await ref
        .watch(firestoreProvider)
        .doc('publicConfig/flags')
        .get();
    final f = snap.data()?['adaptive_experience'];
    return f is Map && f['enabled'] == true && f['scope'] == 'all';
  } on Object {
    return false;
  }
});

/// The answers of AX03/AX04 and AX06, next to [setupDraftProvider].
@immutable
class AdaptiveSetup {
  const AdaptiveSetup({
    this.goals,
    this.skipped = false,
    this.order = const [],
    this.trackersSeeded = false,
  });

  /// null until the goal step: the band's presets.
  final List<Goal>? goals;
  final bool skipped;

  /// AX06 after a drag; empty = ranked.
  final List<WidgetId> order;

  /// AX05 opened once with the band's trackers; later visits keep the person's picks.
  final bool trackersSeeded;

  AdaptiveSetup copyWith({
    List<Goal>? goals,
    bool? skipped,
    List<WidgetId>? order,
    bool? trackersSeeded,
  }) => AdaptiveSetup(
    goals: goals ?? this.goals,
    skipped: skipped ?? this.skipped,
    order: order ?? this.order,
    trackersSeeded: trackersSeeded ?? this.trackersSeeded,
  );
}

final adaptiveSetupProvider =
    NotifierProvider<AdaptiveSetupController, AdaptiveSetup>(
      AdaptiveSetupController.new,
    );

class AdaptiveSetupController extends Notifier<AdaptiveSetup> {
  /// A new draft (setup restarted, "Thêm hồ sơ bé") starts with nothing chosen.
  @override
  AdaptiveSetup build() {
    ref.watch(setupDraftProvider.select((d) => d.requestId));
    return const AdaptiveSetup();
  }

  // ignore: use_setters_to_change_properties
  void update(AdaptiveSetup next) => state = next;

  void reset() => state = const AdaptiveSetup();
}

/// The draft child's whole months today, in the zone picked on 11 (AX00 rule 7).
int setupMonths(SetupDraft draft) => ageInMonths(
  draft.dateOfBirth,
  babyToday(draft.timeZone?.zone ?? 'Asia/Ho_Chi_Minh', DateTime.now()),
);

AgeBand setupBand(SetupDraft draft) => ageBandFor(setupMonths(draft));

/// D-097 Q-088: trackers by band when "Theo dõi bú, ngủ, tã" is not picked (or AX05's start).
/// From 3 years the child keeps Tăng trưởng only: a baby needs one tracker (createBabyRequest),
/// and the 3–6 / 6–12 Todays show growth, never the quick log, by default.
Set<TrackerKind> bandTrackers(AgeBand band) => switch (band) {
  AgeBand.b0_1 => SetupDraft.defaultTrackers,
  AgeBand.b1_3 => const {TrackerKind.sleep, TrackerKind.diaper},
  AgeBand.b3_6 || AgeBand.b6_12 => const {TrackerKind.growth},
};

/// Steps of the adaptive flow: 10a (first child only), 11, goals, [12], preview. The count
/// follows the goals, not the age (AX01 "1/4" vs AX02 "1/3").
List<String> setupSteps(List<Goal> goals, {required bool adding}) => [
  if (!adding) Routes.who,
  Routes.babyProfile,
  Routes.setupGoals,
  if (goals.contains(Goal.trackCare)) Routes.trackers,
  Routes.setupPreview,
];

double setupProgress(WidgetRef ref, String step) {
  final draft = ref.watch(setupDraftProvider);
  final goals =
      ref.watch(adaptiveSetupProvider).goals ?? presetGoals[setupBand(draft)]!;
  final steps = setupSteps(goals, adding: ref.watch(addingBabyProvider));
  final at = steps.indexOf(step);
  return at < 0 ? 0.9 : (at + 1) / (steps.length + 0.25);
}

/// After 11: the goal step (adaptive) or 12 as before.
void continueAfterBabyProfile(BuildContext context, WidgetRef ref) {
  context.push(
    ref.read(setupAdaptiveProvider) ? Routes.setupGoals : Routes.trackers,
  );
}

/// AX03 / AX04 inside the setup chrome.
class SetupGoalsScreen extends ConsumerStatefulWidget {
  const SetupGoalsScreen({super.key});

  @override
  ConsumerState<SetupGoalsScreen> createState() => _SetupGoalsScreenState();
}

class _SetupGoalsScreenState extends ConsumerState<SetupGoalsScreen> {
  Set<Goal>? _picked;

  void _go({required bool skip}) {
    final draft = ref.read(setupDraftProvider);
    final band = setupBand(draft);
    final setup = ref.read(adaptiveSetupProvider);
    final goals = skip
        ? presetGoals[band]!
        : [
            for (final g in Goal.values)
              if ((_picked ?? presetGoals[band]!.toSet()).contains(g)) g,
          ];
    ref
        .read(adaptiveSetupProvider.notifier)
        .update(setup.copyWith(goals: goals, skipped: skip, order: const []));
    if (goals.contains(Goal.trackCare)) {
      if (!setup.trackersSeeded) {
        ref
            .read(setupDraftProvider.notifier)
            .update(draft.copyWith(trackers: bandTrackers(band)));
        ref
            .read(adaptiveSetupProvider.notifier)
            .update(
              ref.read(adaptiveSetupProvider).copyWith(trackersSeeded: true),
            );
      }
      context.push(Routes.trackers);
    } else {
      ref
          .read(setupDraftProvider.notifier)
          .update(draft.copyWith(trackers: bandTrackers(band)));
      context.push(Routes.setupPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final draft = ref.watch(setupDraftProvider);
    final band = setupBand(draft);
    final picked =
        _picked ??
        (ref.watch(adaptiveSetupProvider).goals ?? presetGoals[band]!).toSet();
    final name = draft.nickname.trim();
    final age = ageShortLabel(l10n, draft);
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.pop(),
        onSkip: () => _go(skip: true),
        progress: setupProgress(ref, Routes.setupGoals),
      ),
      content: [
        ScreenHeading(
          title: l10n.axGoalsTitle(name),
          subtitle: l10n.axGoalsSub,
        ),
        const SizedBox(height: ClSpace.s6),
        for (final g in goalOrder(band)) ...[
          AxGoalRow(
            goal: g,
            selected: picked.contains(g),
            badge: presetGoals[band]!.contains(g)
                ? l10n.axGoalsSuggested(age)
                : null,
            onTap: () => setState(
              () => _picked = picked.contains(g)
                  ? ({...picked}..remove(g))
                  : {...picked, g},
            ),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.axGoalsChosen(picked.length),
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cl.colors.mintText,
          ),
        ),
      ],
      bottom: [
        ClButton(
          key: const Key('setupGoalsNext'),
          label: l10n.actionNext,
          expand: true,
          onPressed: () => _go(skip: false),
        ),
      ],
    );
  }
}

/// "2 tháng" / "4 tuổi" for the draft child (AX03/AX04 badge, "Gợi ý cho {tuổi}").
String ageShortLabel(AppLocalizations l10n, SetupDraft draft) {
  final m = setupMonths(draft);
  return m < 24 ? l10n.ageShortMonths(m) : l10n.ageShortYears(m ~/ 12);
}

/// What a Cùng nuôi can have on the new child's Hôm nay (the creator is always one). Kỷ niệm 2.0
/// only when this family's beta is known to be on (adding a child); a first child never sees a
/// widget it may not get (AX00 rule 2).
Set<WidgetId> setupAvailable(WidgetRef ref, SetupDraft draft) {
  final keepsakes = ref.read(addingBabyProvider)
      ? ref.watch(selectedKeepsakeAccessProvider)
      : (cards: false, videos: false);
  return {
    if (draft.trackers.isNotEmpty) WidgetId.tiles,
    WidgetId.reminders,
    WidgetId.spending,
    WidgetId.recentMemories,
    WidgetId.momentToday,
    WidgetId.growth,
    WidgetId.familyView,
    WidgetId.vaccine,
    if (keepsakes.cards || keepsakes.videos) WidgetId.createFromMemories,
  };
}

/// AX06 "Hôm nay của {tên} sẽ ưu tiên": the ranked widgets with their reason, dragged to taste;
/// "Vào Hôm nay của {tên}" creates the child and keeps the arrangement (P-175).
class SetupPreviewScreen extends ConsumerStatefulWidget {
  const SetupPreviewScreen({super.key});

  @override
  ConsumerState<SetupPreviewScreen> createState() => _SetupPreviewScreenState();
}

class _SetupPreviewScreenState extends ConsumerState<SetupPreviewScreen> {
  bool _busy = false;

  Experience _experience() {
    final draft = ref.read(setupDraftProvider);
    final band = setupBand(draft);
    final setup = ref.read(adaptiveSetupProvider);
    return Experience(
      goals: setup.goals ?? presetGoals[band]!,
      goalsSource: setup.skipped || setup.goals == null
          ? GoalsSource.skipped
          : GoalsSource.chosen,
      bandApplied: band,
      order: setup.order,
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final exp = _experience();
    await createSetupBaby(
      context,
      ref,
      afterCreate: (container, babyId) {
        if (mounted) {
          reportAdaptive(
            ref,
            context,
            'adaptive_goals_set',
            exp.goalsSource == GoalsSource.chosen ? 'chosen' : 'skipped',
            babyId: babyId,
          );
        }
        final session = container.read(sessionProvider);
        if (session is SessionSignedIn) {
          container
              .read(experienceRepositoryProvider)
              .save(session.user.uid, babyId, exp)
              .ignore();
        }
        container.read(adaptiveSetupProvider.notifier).reset();
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final draft = ref.watch(setupDraftProvider);
    ref.watch(adaptiveSetupProvider);
    final name = draft.nickname.trim();
    final exp = _experience();
    final shown = [
      for (final w in rankToday(exp, setupAvailable(ref, draft)))
        if (w.visible) w,
    ];
    String because(RankedWidget w) => switch (w.reason) {
      ReasonGoal(:final goal) => goalLabel(l10n, goal),
      _ => l10n.axBecauseAlways,
    };

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.pop(),
        progress: setupProgress(ref, Routes.setupPreview),
      ),
      content: [
        ScreenHeading(
          title: l10n.axPreviewTitle(name),
          subtitle: l10n.axPreviewSub(name),
        ),
        const SizedBox(height: ClSpace.s6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: cl.shadows.card,
          ),
          child: ReorderableListView(
            key: const Key('setupPreview'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) {
              final ids = [for (final w in shown) w.id];
              ids.insert(to, ids.removeAt(from));
              ref
                  .read(adaptiveSetupProvider.notifier)
                  .update(ref.read(adaptiveSetupProvider).copyWith(order: ids));
            },
            children: [
              for (final (i, w) in shown.indexed)
                Padding(
                  key: ValueKey(w.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.mintSoft,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: cl.text.bodyStrong.copyWith(
                            fontSize: 14,
                            color: cl.colors.mintText,
                          ),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widgetTitle(l10n, w.id),
                              style: cl.text.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cl.colors.ink,
                              ),
                            ),
                            Text(
                              l10n.axPreviewBecause(because(w)),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: ClIcon(
                              ClIcons.grid,
                              size: 16,
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.sliders, size: 16, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.axPreviewHint,
                  style: cl.text.caption.copyWith(
                    fontSize: 13,
                    color: cl.colors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        ClButton(
          key: const Key('setupPreviewGo'),
          label: l10n.axPreviewGo(name),
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _create,
        ),
      ],
    );
  }
}

/// AX02's card under the date of birth from 12 months: every feature works for this child, and
/// what Hôm nay will lead with (AX00 rule 1).
class SetupAgeInfoCard extends ConsumerWidget {
  const SetupAgeInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final draft = ref.watch(setupDraftProvider);
    if (setupMonths(draft) < 12) return const SizedBox.shrink();
    final name = draft.nickname.trim().isEmpty
        ? l10n.babyNicknamePlaceholder
        : draft.nickname.trim();
    // "luôn có trong Khám phá" only once Khám phá exists (P-178); until then the tabs as they are.
    final explore =
        ref.watch(selectedCapabilitiesProvider)?.features.adaptiveNav ?? false;
    return Container(
      key: const Key('setupAgeInfo'),
      margin: const EdgeInsets.only(top: ClSpace.s4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.axInfoTitle(name),
            style: cl.text.bodyStrong.copyWith(
              fontSize: 14,
              color: cl.colors.ink,
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.axInfoSub(name),
            style: cl.text.caption.copyWith(
              fontSize: 13,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in [
                l10n.axChipMemories,
                l10n.axChipVideo,
                l10n.axChipSpending,
                l10n.axWidgetReminders,
                l10n.axGrowthTitle,
                l10n.axChipVaccines,
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    label,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            explore ? l10n.axInfoFoot : l10n.axInfoFootTabs,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// `createBabyProfile` with the draft (12 "Xong", AX06 "Vào Hôm nay của …"): the photo, the
/// EN01–EN03 follow-ups, then the new child opens. [afterCreate] runs right after it exists,
/// before the router moves on.
Future<void> createSetupBaby(
  BuildContext context,
  WidgetRef ref, {
  void Function(ProviderContainer container, String babyId)? afterCreate,
}) async {
  final l10n = AppLocalizations.of(context);
  final draft = ref.read(setupDraftProvider);
  final repo = ref.read(babyRepositoryProvider);
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    final babyId = await repo.createBaby(draft.toInput());
    afterCreate?.call(container, babyId);
    // D-076 #1: Hôm nay opens EN01–EN03 for this baby (lib/features/today/today_personalize.dart).
    container.read(personalizeAfterSetupProvider.notifier).request(babyId);
    container
        .read(notificationsAfterOnboardingProvider.notifier)
        .request(babyId);
    final photo = draft.avatarPhoto;
    if (photo != null) {
      try {
        await repo.setAvatarPhoto(babyId, photo);
      } on Object {
        if (context.mounted) {
          showClToast(context, message: l10n.avatarUploadFailed);
        }
      }
    }
    container.read(setupDraftProvider.notifier).reset();
    if (container.read(addingBabyProvider)) {
      // "Thêm hồ sơ bé": open the new baby once the membership has arrived.
      await waitForMembership(container, babyId);
      container.read(selectedBabyIdProvider.notifier).select(babyId);
      container.read(addingBabyProvider.notifier).set(false);
      if (context.mounted) context.go(Routes.today);
    }
    // A first baby: the session now has a baby and the router opens Today.
  } on BabyException catch (e) {
    if (!context.mounted) return;
    showClToast(
      context,
      message: switch (e.failure) {
        BabyFailure.babyLimit => l10n.createBabyLimit,
        BabyFailure.dobInFuture => l10n.createBabyDobFuture,
        _ => l10n.createBabyFailed,
      },
    );
  } on Object {
    if (context.mounted) showClToast(context, message: l10n.createBabyFailed);
  }
}
