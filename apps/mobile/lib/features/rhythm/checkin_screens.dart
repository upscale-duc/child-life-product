import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../family/family_labels.dart' show relationLabel;
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// C01 (589:6451): start from one observation, never a default answer. "Như mọi ngày" saves
/// quietly; "Mình lo về sức khoẻ của con" asks the health questions (NL05b) and never shows a
/// paywall. Logging is free in every plan state.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  Observation? _picked;

  static const _choices = [
    Observation.sleep,
    Observation.feeding,
    Observation.soothing,
    Observation.newSkill,
    Observation.usual,
  ];

  void _continue() {
    final me = ref.read(selectedMembershipProvider);
    final o = _picked;
    if (me == null || o == null) return;
    if (o == Observation.usual) {
      finishCheckIn(context, ref, newCheckIn(ref, me, o));
    } else {
      context.push('${Routes.rhythmCheckInMore}?o=${o.wire}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    _watchCheckIns(ref);
    return OnboardingScaffold(
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: RhRoundIcon(
          icon: ClIcons.close,
          label: l10n.a11yClose,
          onPressed: () => leaveRhythm(context),
        ),
      ),
      content: [
        Semantics(
          header: true,
          child: Text(
            l10n.rhCheckInTitle,
            style: cl.text.title2.copyWith(fontSize: 26, color: cl.colors.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.rhCheckInSubtitle,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        for (final o in _choices) ...[
          RhOptionRow(
            label: observationLabel(l10n, o),
            icon: observationIcon(o),
            selected: _picked == o,
            onTap: () => setState(() => _picked = o),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        // The health escape: a link, not a choice (589:6488).
        RhOptionRow(
          label: l10n.rhObsHealth,
          icon: ClIcons.alert,
          selected: false,
          onTap: () => context.push(Routes.rhythmCheckInHealth),
          trailing: ClIcon(
            ClIcons.chevronRight,
            size: 16,
            color: cl.colors.inkMuted,
          ),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.rhContinue,
          expand: true,
          onPressed: _picked == null ? null : _continue,
        ),
      ],
    );
  }
}

/// C02 (589:6492): a few questions that change with the observation, all optional ("Bỏ qua câu
/// hỏi"); facts already in the care log are shown, never asked again. Sleep: when / since /
/// tried (as drawn); feeding: when / since; soothing: when / since / tried; something new: a
/// short text and "Lưu vào Mốc" (MS01, the next step).
class CheckInMoreScreen extends ConsumerStatefulWidget {
  const CheckInMoreScreen({required this.observation, super.key});
  final Observation observation;

  @override
  ConsumerState<CheckInMoreScreen> createState() => _CheckInMoreScreenState();
}

class _CheckInMoreScreenState extends ConsumerState<CheckInMoreScreen> {
  CheckInWhen? _when;
  CheckInSince? _since;
  final _tried = <Tried>{};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<Tried> get _triedChoices => switch (widget.observation) {
    Observation.sleep => const [Tried.rocking, Tried.whiteNoise, Tried.none],
    Observation.soothing => const [
      Tried.rocking,
      Tried.whiteNoise,
      Tried.skinToSkin,
      Tried.swaddle,
      Tried.feeding,
      Tried.none,
    ],
    _ => const [],
  };

  bool get _asksWhen =>
      widget.observation == Observation.sleep ||
      widget.observation == Observation.feeding ||
      widget.observation == Observation.soothing;

  void _toggleTried(Tried t) => setState(() {
    if (_tried.contains(t)) {
      _tried.remove(t);
    } else if (t == Tried.none) {
      // "Chưa" excludes the others.
      _tried
        ..clear()
        ..add(t);
    } else {
      _tried
        ..remove(Tried.none)
        ..add(t);
    }
  });

  void _save({bool skip = false}) {
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final note = _note.text.trim();
    var draft = newCheckIn(ref, me, widget.observation);
    if (!skip) {
      draft = draft.copyWith(
        when: () => _when,
        since: () => _since,
        tried: [
          for (final t in Tried.values)
            if (_tried.contains(t)) t,
        ],
        note: () => note.isEmpty
            ? null
            : note.substring(0, note.length.clamp(0, CheckIn.noteMaxLength)),
      );
    }
    finishCheckIn(context, ref, draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final o = widget.observation;
    final fromLog = _fromLog(context);
    _watchCheckIns(ref);
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
            label: l10n.rhSkipQuestions,
            muted: true,
            onTap: () => _save(skip: true),
          ),
        ],
      ),
      content: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s3,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            children: [
              ClIcon(observationIcon(o), size: 14, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  observationLabel(l10n, o),
                  style: cl.text.caption.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Semantics(
          header: true,
          child: Text(
            l10n.rhMoreTitle,
            style: cl.text.title2.copyWith(fontSize: 22, color: cl.colors.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        if (_asksWhen) ...[
          RhQuestionCard(
            title: l10n.rhQWhen,
            children: [
              for (final w in CheckInWhen.values)
                RhChip(
                  label: whenLabel(l10n, o, w),
                  selected: _when == w,
                  onTap: () => setState(() => _when = _when == w ? null : w),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          RhQuestionCard(
            title: l10n.rhQSince,
            children: [
              for (final s in CheckInSince.values)
                RhChip(
                  label: sinceLabel(l10n, s),
                  selected: _since == s,
                  onTap: () => setState(() => _since = _since == s ? null : s),
                ),
            ],
          ),
        ],
        if (_triedChoices.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          RhQuestionCard(
            title: l10n.rhQTried,
            children: [
              for (final t in _triedChoices)
                RhChip(
                  label: triedLabel(l10n, t),
                  selected: _tried.contains(t),
                  onTap: () => _toggleTried(t),
                ),
            ],
          ),
        ],
        if (o == Observation.newSkill) ...[
          ClTextField(
            label: l10n.rhNewSkillLabel,
            placeholder: l10n.rhNewSkillHint,
            controller: _note,
            standalone: true,
            maxLines: 4,
            maxLength: CheckIn.noteMaxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          // MS01: milestones are confirmed by a Cùng nuôi; the text travels as data only.
          if (ref.watch(selectedMembershipProvider) case final me?
              when familyCan(me, FamilyAction.momentsCreate)) ...[
            const SizedBox(height: ClSpace.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: RhLink(
                label: l10n.rhSaveToMilestones,
                onTap: () =>
                    context.push(Routes.rhythmMilestone, extra: _note.text),
              ),
            ),
          ],
        ],
        if (fromLog != null) ...[
          const SizedBox(height: ClSpace.s3),
          RhInfoBox(text: fromLog, icon: observationIcon(o)),
        ],
      ],
      bottom: [
        ClButton(label: l10n.rhSaveNote, expand: true, onPressed: _save),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.rhAlwaysFree,
          textAlign: TextAlign.center,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }

  /// "Từ nhật ký: …" (C02 annotation: reuse Care facts, never ask again).
  String? _fromLog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || !me.canViewToday) return null;
    final records =
        ref.watch(recentRecordsProvider(me.babyId)).value ?? const [];
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final day = babyDayBounds(zone, now);
    switch (widget.observation) {
      case Observation.sleep:
        // Last night: 18:00 yesterday to 10:00 today, in the baby's zone.
        final from = day.start.subtract(const Duration(hours: 6));
        final to = day.start.add(const Duration(hours: 10));
        var total = Duration.zero;
        CareRecord? longest;
        var longestPart = Duration.zero;
        for (final r in records) {
          if (r.deleted || r.type != CareType.sleep || r.endedAt == null) {
            continue;
          }
          final a = r.occurredAt.isAfter(from) ? r.occurredAt : from;
          final b = r.endedAt!.isBefore(to) ? r.endedAt! : to;
          if (!b.isAfter(a)) continue;
          final part = b.difference(a);
          total += part;
          if (part > longestPart) {
            longestPart = part;
            longest = r;
          }
        }
        if (longest == null) return null;
        final who = authorLabel(
          l10n,
          longest.author,
          isMe: longest.createdBy == me.uid,
          relationLabel: (rel, c) => relationLabel(l10n, rel, c),
        );
        return l10n.rhFromLogSleep(durationLabel(l10n, total.inMinutes), who);
      case Observation.feeding:
        final feeds = records
            .where(
              (r) =>
                  !r.deleted &&
                  (r.type == CareType.bottle || r.type == CareType.breast) &&
                  !r.occurredAt.isBefore(day.start) &&
                  r.occurredAt.isBefore(day.end),
            )
            .length;
        return feeds == 0 ? null : l10n.rhFromLogFeeds(feeds);
      default:
        return null;
    }
  }
}

/// Today's check-ins stay loaded while the flow is open, so saving the same observation again
/// edits it (revision + 1) instead of starting over.
void _watchCheckIns(WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return;
  ref.watch(checkInsProvider(me.babyId));
  watchRhythmClock(ref, me.babyId);
}

enum _Answer { yes, no, unsure }

/// NL05b (572:1161): the health questions, one answer per sign (Có / Không / Không chắc), no
/// default. Any "Có" saves the check-in with those signs and opens HL01 at once; signs follow
/// the baby's age when the member may read it (fever only under 3 months), else all are asked.
class HealthQuestionsScreen extends ConsumerStatefulWidget {
  const HealthQuestionsScreen({super.key});

  @override
  ConsumerState<HealthQuestionsScreen> createState() =>
      _HealthQuestionsScreenState();
}

class _HealthQuestionsScreenState extends ConsumerState<HealthQuestionsScreen> {
  final _answers = <HealthSign, _Answer>{};

  void _continue() {
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final yes = [
      for (final s in HealthSign.values)
        if (_answers[s] == _Answer.yes) s,
    ];
    finishCheckIn(
      context,
      ref,
      newCheckIn(ref, me, Observation.health).copyWith(healthSigns: yes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final dob = me != null && me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value?.dateOfBirth
        : null;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final ageDays = dob == null
        ? null
        : ageInDays(
            dob,
            babyToday(baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh', now),
          );
    final pack = ref.watch(rhythmContentProvider).value?.health;
    _watchCheckIns(ref);
    final signs = signsFor(pack, ageDays);
    final unsure = _answers.values.contains(_Answer.unsure);
    return OnboardingScaffold(
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: RhRoundIcon(
          icon: ClIcons.close,
          label: l10n.a11yClose,
          onPressed: () => leaveRhythm(context),
        ),
      ),
      content: [
        Semantics(
          header: true,
          child: Text(
            l10n.rhHealthQHeading,
            style: cl.text.title2.copyWith(fontSize: 26, color: cl.colors.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.sunshineSoft,
            borderRadius: BorderRadius.circular(rhCardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ink on soft warm fills, also in Night care.
                  ClIcon(ClIcons.alert, size: 18, color: cl.colors.ink),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.rhHealthQTitle,
                      style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.rhHealthQAsk(baby?.nickname ?? ''),
                style: cl.text.label.copyWith(color: cl.colors.ink),
              ),
              for (final s in signs) ...[
                const SizedBox(height: ClSpace.s4),
                Text(
                  signText(l10n, locale, s),
                  style: cl.text.body.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, a) in _Answer.values.indexed) ...[
                        if (i > 0) const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: RhChip(
                            expand: true,
                            label: switch (a) {
                              _Answer.yes => l10n.rhAnswerYes,
                              _Answer.no => l10n.rhAnswerNo,
                              _Answer.unsure => l10n.rhAnswerUnsure,
                            },
                            selected: _answers[s.sign] == a,
                            onTap: () => setState(() => _answers[s.sign] = a),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.rhHealthQHelper,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        if (unsure) ...[
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.rhHealthUnsureHint,
            style: cl.text.label.copyWith(
              color: cl.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
      bottom: [
        ClButton(label: l10n.rhContinue, expand: true, onPressed: _continue),
      ],
    );
  }
}
