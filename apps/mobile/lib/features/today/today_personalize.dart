import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/experience_repository.dart' show adaptiveOnProvider;
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import '../reminders/reminder_notifications.dart'
    show notificationsAskedProvider, notificationsEnabledProvider;
import '../reminders/reminder_screens.dart' show showNotificationsRefused;
import '../rhythm/rhythm_labels.dart';
import '../rhythm/rhythm_models.dart';
import '../rhythm/rhythm_repository.dart';
import '../rhythm/rhythm_setup.dart' show QuietHoursCard;
import '../rhythm/rhythm_widgets.dart';

/// Cá nhân hoá on Hôm nay (D-076 #1): EN01 "điều bạn quan tâm" (559:2288) → EN02 "giờ nhận gợi
/// ý" (559:2383) → EN03 "Bật thông báo" (559:2458), right after a baby profile is created, and
/// the Home invite (559:57870) for whoever skipped it or never saw it (people who joined by
/// invite). Choices are the person's own (`users/{uid}/settings/personalization`,
/// `userPreferencesSchema`, `preferences.own`: every role), written through the Nhịp lớn lên
/// repository. Offered only with the family's `rhythm` rollout: that is what reads the choices
/// (the same gate as "Cá nhân hoá" in Tôi).
///
/// After onboarding on this phone (a baby created, or an invite accepted) the person is always
/// asked for notifications (D-077 #1): EN03 inside the flow above, else EN03 on its own
/// when this phone does not show them yet and has not asked before.

abstract final class TodayRoutes {
  /// EN01–EN03, full screen above the tabs.
  static const personalize = '/personalize';

  /// EN03 on its own, after onboarding.
  static const notifications = '/personalize?only=notifications';
}

List<RouteBase> todayRoutes() => [
  GoRoute(
    path: TodayRoutes.personalize,
    pageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      fullscreenDialog: true,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: PersonalizeFlowScreen(
        notificationsOnly: state.uri.queryParameters['only'] == 'notifications',
      ),
    ),
  ),
];

/// Whether the family's rollout offers personalisation at all.
bool personalizationOffered(Capabilities? caps) =>
    caps?.features.rhythm ?? false;

/// The person has made their choices at least once (EN01 / EN02 here or in Tôi, EN05 "Ít gợi ý
/// kiểu này hơn"): the repository stamps `updatedAt` on every write.
bool hasPersonalized(UserPreferences p) => p.updatedAt != null;

/// The baby just created on this phone (12 "Xong"), until Hôm nay opened EN01 for it or found
/// it should not. In memory only: a restart does not replay it; the Home invite takes over.
final personalizeAfterSetupProvider =
    NotifierProvider<PersonalizeAfterSetup, String?>(PersonalizeAfterSetup.new);

class PersonalizeAfterSetup extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String babyId) => state = babyId;
  void clear() => state = null;
}

/// The baby whose onboarding just ended on this phone (12 "Xong" or 15 "Tham gia"), until Hôm
/// nay has asked for notifications. In memory only, like [personalizeAfterSetupProvider].
final notificationsAfterOnboardingProvider =
    NotifierProvider<NotificationsAfterOnboarding, String?>(
      NotificationsAfterOnboarding.new,
    );

class NotificationsAfterOnboarding extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String babyId) => state = babyId;
  void clear() => state = null;
}

/// EN03 on its own once onboarding is over, unless the flow just showed it, this phone already
/// shows notifications, or it asked before (the system asks only once; 8d then links to
/// Settings).
Future<void> askNotificationsAfterOnboarding(
  ProviderContainer container,
  GoRouter router, {
  bool sawPrompt = false,
}) async {
  if (sawPrompt) return;
  final enabled = container.read(notificationsEnabledProvider.notifier);
  await enabled.refresh();
  if (container.read(notificationsEnabledProvider) ?? false) return;
  if (container.read(notificationsAskedProvider)) return;
  await router.push<bool>(TodayRoutes.notifications);
}

/// × on the Home invite: hidden for this person on this phone (keyed by uid, so another
/// account on the same phone still sees it).
final personalizeInviteHiddenProvider =
    NotifierProvider.family<PersonalizeInviteHidden, bool, String>(
      PersonalizeInviteHidden.new,
    );

class PersonalizeInviteHidden extends Notifier<bool> {
  PersonalizeInviteHidden(this.uid);
  final String uid;

  String get _key => 'today.personalizeInvite.hidden.$uid';

  @override
  bool build() {
    try {
      return ref.read(sharedPreferencesProvider).getBool(_key) ?? false;
    } on Object {
      return false;
    }
  }

  void hide() {
    state = true;
    try {
      ref.read(sharedPreferencesProvider).setBool(_key, true);
    } on Object {
      // No preferences (tests): hidden for this run.
    }
  }
}

/// Opens EN01 once Hôm nay shows the baby created on this phone, when the rollout offers it and
/// the person has not made their choices yet (a second baby does not ask again: the choices
/// are per person); then, or instead, EN03 on its own after onboarding
/// ([askNotificationsAfterOnboarding]). Draws nothing.
class PersonalizeAfterSetupGate extends ConsumerWidget {
  const PersonalizeAfterSetupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(personalizeAfterSetupProvider);
    final notify = ref.watch(notificationsAfterOnboardingProvider);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    if (pending != me.babyId) {
      // Joined by invite (or EN01 not due): only the notifications.
      if (notify == me.babyId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ref.read(notificationsAfterOnboardingProvider) != notify) return;
          ref.read(notificationsAfterOnboardingProvider.notifier).clear();
          if (context.mounted) {
            unawaited(
              askNotificationsAfterOnboarding(
                ProviderScope.containerOf(context, listen: false),
                GoRouter.of(context),
              ),
            );
          }
        });
      }
      return const SizedBox.shrink();
    }
    final caps = ref.watch(capabilitiesProvider(me.babyId));
    if (!caps.hasValue && !caps.hasError) return const SizedBox.shrink();
    final offered = personalizationOffered(caps.value);
    final prefs = offered ? ref.watch(userPreferencesProvider(me.uid)) : null;
    if (prefs != null && !prefs.hasValue && !prefs.hasError) {
      return const SizedBox.shrink();
    }
    final open =
        offered && !hasPersonalized(prefs?.value ?? UserPreferences.defaults);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(personalizeAfterSetupProvider.notifier);
      if (ref.read(personalizeAfterSetupProvider) != pending) return;
      notifier.clear();
      final ask = ref.read(notificationsAfterOnboardingProvider) == pending;
      if (ask) ref.read(notificationsAfterOnboardingProvider.notifier).clear();
      if (!context.mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final router = GoRouter.of(context);
      // The flow answers whether it showed EN03.
      final sawPrompt = open
          ? await router.push<bool>(TodayRoutes.personalize) ?? false
          : false;
      if (ask) {
        await askNotificationsAfterOnboarding(
          container,
          router,
          sawPrompt: sawPrompt,
        );
      }
    });
    return const SizedBox.shrink();
  }
}

/// 559:57870 "Hôm nay theo cách của nhà bạn": mint-soft card under the title for someone who
/// has not made their choices; "Bắt đầu" opens EN01, × hides it for this person.
class PersonalizeInviteCard extends ConsumerWidget {
  const PersonalizeInviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    // D-143 (4): the goals asked in setup replace "Hôm nay theo cách của nhà bạn".
    if (me == null ||
        ref.watch(adaptiveOnProvider) ||
        !personalizationOffered(ref.watch(selectedCapabilitiesProvider)) ||
        ref.watch(personalizeAfterSetupProvider) == me.babyId ||
        ref.watch(personalizeInviteHiddenProvider(me.uid))) {
      return const SizedBox.shrink();
    }
    final prefs = ref.watch(userPreferencesProvider(me.uid)).value;
    if (prefs == null || hasPersonalized(prefs)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Container(
        key: const Key('personalizeInvite'),
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s4,
          ClSpace.s1,
          ClSpace.s4,
        ),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(rhCardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    ClIcons.sliders,
                    size: 18,
                    color: cl.colors.ink,
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.hnInviteTitle,
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.hnInviteBody,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClPressable(
                  onPressed: () {
                    ref
                        .read(personalizeInviteHiddenProvider(me.uid).notifier)
                        .hide();
                    showClToast(context, message: l10n.hnInviteHidden);
                  },
                  semanticLabel: l10n.hnInviteClose,
                  child: SizedBox(
                    width: ClSpace.tapMin,
                    height: ClSpace.tapMin,
                    child: Center(
                      child: ClIcon(
                        ClIcons.close,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            RhPillButton(
              label: l10n.hnInviteStart,
              onTap: () => context.push(TodayRoutes.personalize),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN01 → EN02 → EN03. "Tiếp tục" saves that step at once (writes never wait for the server);
/// "Bỏ qua" ends the flow keeping what was saved. EN03 is skipped when this phone already shows
/// notifications; only "Bật thông báo" asks the system (the pre-permission pattern).
class PersonalizeFlowScreen extends ConsumerStatefulWidget {
  const PersonalizeFlowScreen({this.notificationsOnly = false, super.key});

  /// EN03 on its own, after onboarding ([askNotificationsAfterOnboarding]).
  final bool notificationsOnly;

  @override
  ConsumerState<PersonalizeFlowScreen> createState() =>
      _PersonalizeFlowScreenState();
}

class _PersonalizeFlowScreenState extends ConsumerState<PersonalizeFlowScreen> {
  static const _steps = 3;

  /// D-143 (4): with Adaptive Experience the child's goals replace EN01, so the flow starts at
  /// EN02 (giờ gợi ý).
  late final int _first = ref.read(adaptiveOnProvider) ? 1 : 0;
  late int _step = widget.notificationsOnly ? 2 : _first;
  Set<Interest>? _interests;
  UserPreferences? _draft;
  bool _busy = false;

  /// What this flow last wrote, so EN02 builds on EN01 before the listener catches up.
  UserPreferences? _written;

  UserPreferences _stored(String uid) =>
      _written ??
      ref.read(userPreferencesProvider(uid)).value ??
      UserPreferences.defaults;

  void _save(String uid, UserPreferences prefs) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    _written = prefs;
    ref
        .read(rhythmRepositoryProvider)
        .savePreferences(
          uid,
          prefs,
          onError: (_) => toaster.show(message: l10n.rhSaveFailed, error: true),
        );
  }

  void _leave() {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    if (router.canPop()) {
      // Whether EN03 was shown, for [askNotificationsAfterOnboarding].
      router.pop(_step == 2);
    } else {
      router.go(Routes.today);
    }
    if (_written != null) toaster.show(message: l10n.rhPrefsSaved);
  }

  Future<void> _afterDigest() async {
    final enabled = ref.read(notificationsEnabledProvider.notifier);
    setState(() => _busy = true);
    await enabled.refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    // Already on, or the system prompt was shown before (at launch or from 8c): the OS would
    // not ask again, so "Bật thông báo" could do nothing (NT-3).
    if ((ref.read(notificationsEnabledProvider) ?? false) ||
        ref.read(notificationsAskedProvider)) {
      _leave();
    } else {
      setState(() => _step = 2);
    }
  }

  Future<void> _allowNotifications() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    final on = await ref.read(notificationsEnabledProvider.notifier).request();
    if (!mounted) return;
    setState(() => _busy = false);
    _leave();
    // Refused: only system settings can turn them on now (NT-3).
    if (!on) showNotificationsRefused(toaster, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const OnboardingScaffold(content: []);
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final async = ref.watch(userPreferencesProvider(me.uid));
    final stored = async.value;
    if (_interests == null && !async.isLoading) {
      _interests = {...?stored?.interests};
    }
    final interests = _interests ?? <Interest>{};
    // EN02 starts on the person's own time, else the evening round-up drawn in Figma.
    final draft =
        _draft ??
        (stored ?? UserPreferences.defaults).copyWith(
          digestTime: () => stored?.digestTime ?? '20:30',
        );

    final topBar = widget.notificationsOnly
        ? null
        : Row(
            children: [
              _StepBars(step: _step - _first, count: _steps - _first),
              const Spacer(),
              RhLink(label: l10n.rhSkip, muted: true, onTap: _leave),
            ],
          );

    final (content, bottom) = switch (_step) {
      0 => (
        _interestsStep(context, name, interests),
        [
          ClButton(
            label: interests.isEmpty
                ? l10n.actionContinue
                : l10n.hnContinueCount(interests.length),
            expand: true,
            onPressed: () {
              _save(
                me.uid,
                _stored(me.uid).copyWith(
                  interests: [
                    for (final i in Interest.values)
                      if (interests.contains(i)) i,
                  ],
                ),
              );
              setState(() => _step = 1);
            },
          ),
        ],
      ),
      1 => (
        _digestStep(context, draft),
        [
          ClButton(
            label: l10n.actionContinue,
            expand: true,
            loading: _busy,
            onPressed: _busy
                ? null
                : () {
                    _save(
                      me.uid,
                      _stored(me.uid).copyWith(
                        digestTime: () => draft.digestTime,
                        quietHours: () =>
                            draft.quietFrom == null || draft.quietTo == null
                            ? null
                            : (draft.quietFrom!, draft.quietTo!),
                      ),
                    );
                    _afterDigest();
                  },
          ),
        ],
      ),
      _ => (
        _notificationsStep(context, name),
        [
          ClButton(
            label: l10n.hnNotifAllow,
            icon: ClIcons.bell,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _allowNotifications,
          ),
          ClButton(
            label: l10n.actionLater,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: _busy ? null : _leave,
          ),
          Text(
            l10n.hnNotifSettingsHint,
            textAlign: TextAlign.center,
            style: context.cl.text.caption.copyWith(
              color: context.cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    };

    return PopScope(
      // Back goes to the previous step; from EN01 (or EN03 on its own) it leaves.
      canPop: _step == _first || widget.notificationsOnly,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > _first) setState(() => _step--);
      },
      child: OnboardingScaffold(
        topBar: topBar,
        content: content,
        bottom: bottom,
      ),
    );
  }

  List<Widget> _interestsStep(
    BuildContext context,
    String name,
    Set<Interest> selected,
  ) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    const all = Interest.values;
    Widget option(Interest i) => Expanded(
      child: InterestTile(
        interest: i,
        selected: selected.contains(i),
        onTap: () => setState(
          () => selected.contains(i) ? selected.remove(i) : selected.add(i),
        ),
      ),
    );
    return [
      Semantics(
        header: true,
        child: Text(l10n.rhInterestsTitle(name), style: cl.text.title2),
      ),
      const SizedBox(height: ClSpace.s2),
      Text(
        l10n.rhInterestsBody,
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s4),
      for (var r = 0; r < all.length; r += 2) ...[
        if (r > 0) const SizedBox(height: ClSpace.s3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              option(all[r]),
              const SizedBox(width: ClSpace.s3),
              if (r + 1 < all.length) option(all[r + 1]) else const Spacer(),
            ],
          ),
        ),
      ],
      const SizedBox(height: ClSpace.s3),
      RhInfoBox(icon: ClIcons.today, text: l10n.rhInterestsToday),
    ];
  }

  List<Widget> _digestStep(BuildContext context, UserPreferences draft) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget option(String title, String? time, ClIcons icon) {
      final on = draft.digestTime == time;
      return Padding(
        padding: const EdgeInsets.only(bottom: ClSpace.s2),
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: on,
          child: RhOptionRow(
            label: time == null ? title : '$title · $time',
            icon: icon,
            selected: on,
            onTap: () =>
                setState(() => _draft = draft.copyWith(digestTime: () => time)),
            trailing: ClRadio(selected: on),
          ),
        ),
      );
    }

    return [
      Semantics(
        header: true,
        child: Text(l10n.rhDigestTitle, style: cl.text.title2),
      ),
      const SizedBox(height: ClSpace.s2),
      Text(
        l10n.rhDigestBody,
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s4),
      option(l10n.rhDigestMorning, '08:00', ClIcons.sunrise),
      option(l10n.rhDigestNoon, '12:30', ClIcons.today),
      option(l10n.rhDigestEvening, '20:30', ClIcons.sunset),
      option(l10n.rhDigestNone, null, ClIcons.close),
      const SizedBox(height: ClSpace.s2),
      QuietHoursCard(
        preferences: draft,
        onChanged: (p) => setState(() => _draft = p),
      ),
    ];
  }

  List<Widget> _notificationsStep(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final alone = widget.notificationsOnly;
    // On its own nothing was picked: the examples are what every family gets, plus Nhịp lớn lên
    // with its rollout.
    final rhythm =
        !alone ||
        personalizationOffered(ref.watch(selectedCapabilitiesProvider));
    Widget row(
      ClIcons icon,
      Color tint,
      String title,
      String when,
      String sample,
    ) => Padding(
      padding: const EdgeInsets.all(ClSpace.s3),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              // Ink on soft fills, also in Night care.
              child: ClIcon(icon, size: 16, color: cl.colors.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(title, style: cl.text.bodyStrong)),
                      const SizedBox(width: ClSpace.s2),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          when,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sample,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final divider = Container(height: 1, color: cl.colors.separator);
    return [
      Semantics(
        header: true,
        child: Text(l10n.hnNotifTitle, style: cl.text.title2),
      ),
      const SizedBox(height: ClSpace.s2),
      Text(
        alone ? l10n.hnNotifBodyAlone : l10n.hnNotifBody,
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s4),
      Container(
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(rhCardRadius),
          border: Border.all(color: cl.colors.separator),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s3,
                ClSpace.s3,
                ClSpace.s3,
                ClSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.hnNotifExamples,
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClSpace.s2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.surface2,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      l10n.hnNotifExampleTag,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            divider,
            row(
              ClIcons.check,
              cl.colors.mintSoft,
              l10n.hnNotifVaccine,
              l10n.hnNotifVaccineWhen,
              l10n.hnNotifVaccineSample,
            ),
            if (alone) ...[
              divider,
              row(
                ClIcons.cake,
                cl.colors.sunshineSoft,
                l10n.hnNotifMilestone,
                l10n.hnNotifMilestoneWhen,
                l10n.hnNotifMilestoneSample(name),
              ),
            ],
            if (rhythm) ...[
              divider,
              row(
                ClIcons.clock,
                cl.care.sleep.soft,
                l10n.hnNotifRhythm,
                l10n.hnNotifRhythmWhen,
                l10n.hnNotifRhythmSample,
              ),
              divider,
              row(
                ClIcons.journal,
                cl.colors.peachSoft,
                l10n.hnNotifWeek,
                l10n.hnNotifWeekWhen,
                l10n.hnNotifWeekSample,
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

/// EN01 step bars: done and current in mint-deep, the current one long.
class _StepBars extends StatelessWidget {
  const _StepBars({required this.step, required this.count});
  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: AppLocalizations.of(context).hnStepOf(step + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Container(
                width: i == step ? 26 : 10,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? cl.colors.mintDeep
                      : cl.colors.controlBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One EN01 option card (559:2288): tinted icon, check ring, name and what it brings.
class InterestTile extends StatelessWidget {
  const InterestTile({
    required this.interest,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final (tint, icon) = switch (interest) {
      Interest.sleep => (cl.care.sleep.soft, ClIcons.sleep),
      Interest.feeding => (cl.care.bottle.soft, ClIcons.feed),
      Interest.milestones => (cl.care.growth.soft, ClIcons.star),
      Interest.vaccines => (cl.colors.mintSoft, ClIcons.check),
      Interest.nutrition => (cl.colors.peachSoft, ClIcons.drop),
      Interest.moments => (cl.colors.sunshineSoft, ClIcons.memories),
    };
    return ClPressable(
      selected: selected,
      semanticLabel: interestLabel(l10n, interest),
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cl.colors.mintDeep : cl.colors.separator,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  // Ink on soft fills, also in Night care.
                  child: ClIcon(icon, size: 18, color: cl.colors.ink),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? cl.colors.mintDeep : null,
                    border: selected
                        ? null
                        : Border.all(
                            color: cl.colors.controlBorder,
                            width: 1.5,
                          ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? ClIcon(
                          ClIcons.check,
                          size: 14,
                          color: cl.colors.onMintDeep,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            Text(interestLabel(l10n, interest), style: cl.text.bodyStrong),
            const SizedBox(height: 2),
            Text(
              interestSub(l10n, interest),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
