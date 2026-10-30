import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/adaptive_engine.dart' show Goal;
import '../adaptive/experience_repository.dart'
    show adaptiveOnProvider, experienceProvider;
import '../adaptive/today_adaptive.dart' show editChildGoals, goalLabel;
import '../ai/ai_repository.dart' show aiSettingsProvider;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_setup.dart' show QuietHoursCard;
import 'rhythm_widgets.dart';

/// EN01 / EN02 / EN05 and the feedback history: per person, free forever, never a household
/// fact (`users/{uid}/settings/personalization`, `userPreferencesSchema`). Writes never wait for
/// the server.

void _savePrefs(
  BuildContext context,
  WidgetRef ref,
  String uid,
  UserPreferences prefs,
) {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  ref
      .read(rhythmRepositoryProvider)
      .savePreferences(
        uid,
        prefs,
        onError: (_) => toaster.show(message: l10n.rhSaveFailed, error: true),
      );
}

/// EN05 "Ít gợi ý kiểu này hơn" on an activity: its topics join `fewer` at once (no plan, no
/// confirmation); EN01 shows them with "Bỏ" to take it back.
void fewerLikeThis(
  BuildContext context,
  WidgetRef ref,
  Membership me,
  Activity activity,
) {
  final topics = topicsOf(activity);
  if (topics.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  final current =
      ref.read(userPreferencesProvider(me.uid)).value ??
      UserPreferences.defaults;
  _savePrefs(
    context,
    ref,
    me.uid,
    current.copyWith(fewer: {...current.fewer, ...topics}.toList()),
  );
  showClToast(
    context,
    message: l10n.rhFewerToast(
      topics.map((t) => interestLabel(l10n, t).toLowerCase()).join(', '),
    ),
  );
}

/// "Cá nhân hoá" (from Tôi, only with the family's `rhythm` flag): the person's own choices.
class PersonalizeScreen extends ConsumerWidget {
  const PersonalizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) {
      return MePage(title: l10n.rhPersonalize, children: const []);
    }
    final prefs =
        ref.watch(userPreferencesProvider(me.uid)).value ??
        UserPreferences.defaults;
    final adaptive = ref.watch(adaptiveOnProvider);
    final goals = adaptive
        ? ref.watch(experienceProvider(me.babyId)).goals
        : const <Goal>[];
    final canFeedback = familyCan(me, FamilyAction.rhythmFeedback);
    // A1: my own AI consent (per person), with the `ai_assist` rollout. Someone who consented
    // can always come back to withdraw it, even after the rollout is switched off.
    final granted =
        ref.watch(aiSettingsProvider(me.uid)).value?.granted ?? false;
    final ai =
        granted ||
        (ref.watch(selectedCapabilitiesProvider)?.features.aiAssist ?? false);
    final aiOn = granted;
    return MePage(
      title: l10n.rhPersonalize,
      children: [
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.journal,
              title: l10n.pv2Title,
              subtitle: l10n.pv2Open,
              onTap: () => context.push(Routes.personalDay),
            ),
            // D-143 (4): with Adaptive Experience this child's goals replace EN01; they are a
            // parent's (Q-092), so a caregiver has no row here.
            if (!adaptive)
              MeRow(
                icon: ClIcons.sliders,
                title: l10n.rhInterestsRow,
                subtitle: prefs.interests.isEmpty
                    ? l10n.rhInterestsNone
                    : prefs.interests
                          .map((i) => interestLabel(l10n, i))
                          .join(', '),
                onTap: () => context.push(Routes.rhythmInterests),
              )
            else if (me.role == MemberRole.coParent)
              MeRow(
                icon: ClIcons.sliders,
                title: l10n.axGoalsLabel,
                subtitle: goals.isEmpty
                    ? l10n.rhInterestsNone
                    : goals.map((g) => goalLabel(l10n, g)).join(', '),
                onTap: () => editChildGoals(context, ref, me.babyId),
              ),
            MeRow(
              icon: ClIcons.clock,
              title: l10n.rhDigestRow,
              value: prefs.digestTime ?? l10n.rhQuietOff,
              onTap: () => context.push(Routes.rhythmDigest),
            ),
            MeRow(
              icon: ClIcons.bell,
              title: l10n.rhRemindRow,
              subtitle: '${l10n.rhQuietHours}: ${quietLabel(l10n, prefs)}',
              onTap: () => context.push(Routes.rhythmReminders),
            ),
            if (canFeedback)
              MeRow(
                icon: ClIcons.journal,
                title: l10n.rhHistoryRow,
                onTap: () => context.push(Routes.rhythmFeedbackHistory),
              ),
            if (ai)
              MeRow(
                icon: ClIcons.spark,
                title: l10n.aiConsentTitle,
                value: aiOn ? l10n.aiConsentOn : l10n.aiConsentOff,
                onTap: () => context.push(Routes.rhythmAiConsent),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        RhNote(l10n.rhPersonalizeNote),
      ],
    );
  }
}

/// EN01 (559:2288) "điều bạn quan tâm": enduring interests (not today's need, which is a
/// check-in), plus the topics turned down with EN05, each with "Bỏ". Skippable.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  Set<Interest>? _selected;
  List<Interest>? _fewer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const OnboardingScaffold(content: []);
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final async = ref.watch(userPreferencesProvider(me.uid));
    final stored = async.value;
    // The person's saved choices once they arrive; edits stay local until "Lưu".
    if (_selected == null && !async.isLoading) {
      _selected = {...?stored?.interests};
      _fewer = [...?stored?.fewer];
    }
    final selected = _selected ?? <Interest>{};
    final fewer = _fewer ?? <Interest>[];

    final tints = <Interest, (Color, ClIcons)>{
      Interest.sleep: (cl.care.sleep.soft, ClIcons.sleep),
      Interest.feeding: (cl.care.bottle.soft, ClIcons.feed),
      Interest.milestones: (cl.care.growth.soft, ClIcons.star),
      Interest.vaccines: (cl.colors.mintSoft, ClIcons.check),
      Interest.nutrition: (cl.colors.peachSoft, ClIcons.drop),
      Interest.moments: (cl.colors.sunshineSoft, ClIcons.memories),
    };

    Widget option(Interest i) {
      final on = selected.contains(i);
      final (tint, icon) = tints[i]!;
      return Expanded(
        child: ClPressable(
          selected: on,
          semanticLabel: interestLabel(l10n, i),
          onPressed: () =>
              setState(() => on ? selected.remove(i) : selected.add(i)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? cl.colors.mintDeep : cl.colors.separator,
                width: on ? 2 : 1,
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
                        color: on ? cl.colors.mintDeep : null,
                        border: on
                            ? null
                            : Border.all(
                                color: cl.colors.controlBorder,
                                width: 1.5,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: on
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
                Text(interestLabel(l10n, i), style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  interestSub(l10n, i),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final all = Interest.values;
    return OnboardingScaffold(
      topBar: Row(
        children: [
          RhRoundIcon(
            icon: ClIcons.back,
            label: l10n.a11yBack,
            onPressed: () => leaveRhythm(context),
          ),
          const Spacer(),
          RhLink(
            label: l10n.rhSkip,
            muted: true,
            onTap: () => leaveRhythm(context),
          ),
        ],
      ),
      content: [
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
        if (fewer.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.rhFewerTitle,
            style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ClSpace.s2),
          ClCardGroup(
            children: [
              for (final i in fewer)
                MeRow(
                  icon: ClIcons.sliders,
                  title: interestLabel(l10n, i),
                  trailing: MeRowAction(
                    label: l10n.rhFewerUndo,
                    onPressed: () =>
                        setState(() => _fewer = [...fewer]..remove(i)),
                  ),
                ),
            ],
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: l10n.rhSaveCount(selected.length),
          expand: true,
          onPressed: () {
            final toaster = ClToaster.of(context);
            _savePrefs(
              context,
              ref,
              me.uid,
              (stored ?? UserPreferences.defaults).copyWith(
                interests: [
                  for (final i in Interest.values)
                    if (selected.contains(i)) i,
                ],
                fewer: fewer,
              ),
            );
            leaveRhythm(context);
            toaster.show(message: l10n.rhPrefsSaved);
          },
        ),
      ],
    );
  }
}

/// EN02 (559:2383) "Khi nào bạn tiện đọc gợi ý?": one daily round-up at 08:00 / 12:30 / 20:30 (or
/// none) and quiet hours for suggestions. Reminders the person set always ring.
class DigestScreen extends ConsumerStatefulWidget {
  const DigestScreen({super.key});

  @override
  ConsumerState<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends ConsumerState<DigestScreen> {
  UserPreferences? _draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const OnboardingScaffold(content: []);
    final stored = ref.watch(userPreferencesProvider(me.uid)).value;
    final draft = _draft ?? stored ?? UserPreferences.defaults;

    Widget option(String title, String? time, ClIcons icon) {
      final on = draft.digestTime == time;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        child: ClPressable(
          semanticLabel: time == null ? title : '$title, $time',
          onPressed: () =>
              setState(() => _draft = draft.copyWith(digestTime: () => time)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s4,
              vertical: ClSpace.s2,
            ),
            decoration: BoxDecoration(
              color: on ? cl.colors.mintSoft : cl.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? cl.colors.mintDeep : cl.colors.separator,
                width: on ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                ClIcon(
                  icon,
                  size: 20,
                  color: on ? cl.colors.mintText : cl.colors.ink,
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    title,
                    style: cl.text.body.copyWith(
                      color: on ? cl.colors.mintText : cl.colors.ink,
                      fontWeight: on ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (time != null) ...[
                  Text(
                    time,
                    style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                  const SizedBox(width: ClSpace.s3),
                ],
                ClRadio(selected: on),
              ],
            ),
          ),
        ),
      );
    }

    return OnboardingScaffold(
      topBar: Row(
        children: [
          RhRoundIcon(
            icon: ClIcons.back,
            label: l10n.a11yBack,
            onPressed: () => leaveRhythm(context),
          ),
          const Spacer(),
          RhLink(
            label: l10n.rhSkip,
            muted: true,
            onTap: () => leaveRhythm(context),
          ),
        ],
      ),
      content: [
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
        const SizedBox(height: ClSpace.s2),
        option(l10n.rhDigestNoon, '12:30', ClIcons.today),
        const SizedBox(height: ClSpace.s2),
        option(l10n.rhDigestEvening, '20:30', ClIcons.sunset),
        const SizedBox(height: ClSpace.s2),
        option(l10n.rhDigestNone, null, ClIcons.close),
        const SizedBox(height: ClSpace.s4),
        QuietHoursCard(
          preferences: draft,
          onChanged: (p) => setState(() => _draft = p),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.actionSave,
          expand: true,
          onPressed: () {
            final toaster = ClToaster.of(context);
            _savePrefs(context, ref, me.uid, draft);
            leaveRhythm(context);
            toaster.show(message: l10n.rhPrefsSaved);
          },
        ),
      ],
    );
  }
}

/// PS02 footer "Bạn có thể chỉnh hoặc xoá lịch sử phản hồi": this person's own answers (the
/// Rules let only the author delete one) and a reset of their interests.
class FeedbackHistoryScreen extends ConsumerWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) {
      return MePage(title: l10n.rhHistoryTitle, children: const []);
    }
    final canRead = familyCan(me, FamilyAction.historyRead);
    final mine = canRead
        ? [
            for (final f
                in ref.watch(recFeedbackProvider(me.babyId)).value ??
                    const <RecFeedback>[])
              if (f.authorUid == me.uid) f,
          ]
        : const <RecFeedback>[];
    final content = ref.watch(rhythmContentProvider).value;

    Future<void> delete(RecFeedback f) async {
      final toaster = ClToaster.of(context);
      final ok = await rhConfirm(
        context,
        title: l10n.rhDeleteFeedbackTitle,
        body: l10n.rhDeleteFeedbackBody,
        confirm: l10n.rhDelete,
        cancel: l10n.actionCancel,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      ref
          .read(rhythmRepositoryProvider)
          .deleteFeedback(
            me.babyId,
            f.id,
            onError: (_) =>
                toaster.show(message: l10n.rhSaveFailed, error: true),
          );
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(homeCompositionProvider);
      toaster.show(message: l10n.rhFeedbackDeleted);
    }

    Future<void> reset() async {
      final toaster = ClToaster.of(context);
      final ok = await rhConfirm(
        context,
        title: l10n.rhResetInterests,
        body: l10n.rhResetInterestsBody,
        confirm: l10n.rhResetInterests,
        cancel: l10n.actionCancel,
      );
      if (!ok || !context.mounted) return;
      final current =
          ref.read(userPreferencesProvider(me.uid)).value ??
          UserPreferences.defaults;
      _savePrefs(
        context,
        ref,
        me.uid,
        current.copyWith(interests: const [], fewer: const []),
      );
      toaster.show(message: l10n.rhResetDone);
    }

    return MePage(
      title: l10n.rhHistoryTitle,
      children: [
        Text(
          l10n.rhHistoryBody(feedbackWindowDays),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        if (mine.isEmpty)
          MeNotice(title: l10n.rhHistoryEmpty)
        else
          ClCardGroup(
            children: [
              for (final f in mine)
                MeRow(
                  title:
                      content?.activity(f.contentId)?.title.of(locale) ??
                      l10n.rhUnknownActivity,
                  subtitle: [
                    '${shortDay(locale, f.date)} · ${f.kind == FeedbackKind.started ? l10n.rhPlannedPill : feedbackKindLabel(l10n, f.kind)}',
                    if (f.note case final n?) l10n.rhQuoted(n),
                  ].join('\n'),
                  trailing: MeRowAction(
                    label: l10n.rhDelete,
                    destructive: true,
                    onPressed: () => delete(f),
                  ),
                ),
            ],
          ),
        const SizedBox(height: ClSpace.s4),
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.retry,
              title: l10n.rhResetInterests,
              subtitle: l10n.rhResetInterestsBody,
              onTap: reset,
            ),
          ],
        ),
      ],
    );
  }
}
