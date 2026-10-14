import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show babyToday, careClockProvider;
import '../home/home_shell.dart';
import '../keepsakes/keepsake_access.dart';
import '../keepsakes/keepsake_occasions.dart';
import '../keepsakes/milestone_card_screens.dart' show TierBadge;
import '../memories/memory_repository.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_widgets.dart';

/// Milestones are named in a few words (`validNewMilestone`: 1–60 characters).
const milestoneNameMax = 60;

/// The Thiệp cột mốc occasion a new thing reads as, when one clearly fits ("lần đầu lẫy" →
/// "Lần đầu biết lẫy"); null leaves the choice to MM10. Matched on the words parents write, in
/// Vietnamese or English.
Occasion? occasionFor(String text) {
  final t = text.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['lẫy', 'roll'])) return Occasion.rollsOver;
  if (has(['cười thành tiếng', 'laugh'])) return Occasion.laughs;
  if (has(['cười', 'smil'])) return Occasion.firstSmile;
  if (has(['bò', 'crawl'])) return Occasion.crawls;
  if (has(['ngồi', 'sit'])) return Occasion.sitsUp;
  if (has(['bước', 'biết đi', 'step', 'walk'])) return Occasion.firstSteps;
  if (has(['đứng', 'stand'])) return Occasion.stands;
  if (has(['răng', 'tooth'])) return Occasion.firstTooth;
  if (has(['ăn dặm', 'solid'])) return Occasion.firstSolids;
  if (has(['tiếng gọi', 'gọi ba', 'gọi mẹ', 'first word', 'said'])) {
    return Occasion.firstWord;
  }
  return null;
}

/// MS01 (591:6632 / 591:6898) "Lưu vào Mốc" from C02's "Con có điều mới": a Cùng nuôi confirms
/// the new thing as a family milestone (the existing Kỷ niệm milestones, linked by id; no photo
/// is copied), then "Giữ khoảnh khắc này?" offers the Thiệp cột mốc flow, with the occasion when
/// one fits. Premium templates are gated there (`ensureTemplateAllowed`), never here.
class RhythmMilestoneScreen extends ConsumerStatefulWidget {
  const RhythmMilestoneScreen({this.note, super.key});

  /// What the parent typed in C02 (data only).
  final String? note;

  @override
  ConsumerState<RhythmMilestoneScreen> createState() =>
      _RhythmMilestoneScreenState();
}

class _RhythmMilestoneScreenState extends ConsumerState<RhythmMilestoneScreen> {
  late final _name = TextEditingController(text: _initialName());
  ({String name, DateTime date})? _saved;
  var _saving = false;

  String _initialName() {
    final t = (widget.note ?? '').trim();
    return t.length > milestoneNameMax ? t.substring(0, milestoneNameMax) : t;
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(Membership me, DateTime today) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final write = ref
        .read(memoryRepositoryProvider)
        .createMilestone(me.babyId, me, name, today);
    try {
      await write.timeout(const Duration(seconds: 4));
    } on TimeoutException {
      // Offline: the write waits in Firestore's queue and lands later.
      write.ignore();
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        toaster.show(message: l10n.rhMsSaveFailed, error: true);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = (name: name, date: today);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final close = Align(
      alignment: Alignment.centerLeft,
      child: RhRoundIcon(
        icon: ClIcons.close,
        label: l10n.a11yClose,
        onPressed: () => leaveRhythm(context),
      ),
    );
    if (me == null) return OnboardingScaffold(topBar: close, content: const []);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final name = baby?.nickname ?? '';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = babyToday(baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh', now);

    // Milestones are confirmed by a Cùng nuôi (ROLE_DENIED, explained, never sold).
    if (!familyCan(me, FamilyAction.momentsCreate)) {
      return OnboardingScaffold(
        topBar: close,
        content: [
          RhInfoBox(
            icon: ClIcons.lock,
            label: l10n.rhMsRoleTitle,
            text: l10n.rhMsRoleBody,
          ),
        ],
        bottom: [
          ClButton(
            label: l10n.rhDone,
            expand: true,
            onPressed: () => leaveRhythm(context),
          ),
        ],
      );
    }

    final saved = _saved;
    if (saved == null) {
      return OnboardingScaffold(
        topBar: close,
        content: [
          Semantics(
            header: true,
            child: Text(l10n.rhMsConfirmTitle, style: cl.text.title2),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.rhMsConfirmBody(name),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          ClTextField(
            label: l10n.rhMsName,
            placeholder: l10n.rhNewSkillHint,
            controller: _name,
            standalone: true,
            maxLength: milestoneNameMax,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        bottom: [
          ClButton(
            label: l10n.rhSaveToMilestones,
            expand: true,
            loading: _saving,
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => _save(me, today),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.rhLater,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => leaveRhythm(context),
          ),
        ],
      );
    }

    final cards = ref.watch(selectedKeepsakeAccessProvider).cards;
    final occasion = occasionFor(saved.name);
    final growth = cl.care.growth;
    void createCard() => context.push(
      occasion == null
          ? Routes.milestoneCard
          : '${Routes.milestoneCard}?occasion=${occasion.wire}',
    );

    Widget tile(bool premium) => Expanded(
      child: ClPressable(
        onPressed: createCard,
        semanticLabel: premium ? l10n.rhMsPremium : l10n.rhMsBasic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 150 / 186,
              child: Container(
                padding: const EdgeInsets.all(ClSpace.s2),
                decoration: BoxDecoration(
                  color: premium ? cl.colors.peachSoft : cl.colors.mintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: TierBadge(premium: premium),
                    ),
                    Center(
                      child: ClIcon(
                        ClIcons.star,
                        size: 36,
                        // Ink on soft fills, also in Night care.
                        color: cl.colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              premium ? l10n.rhMsPremium : l10n.rhMsBasic,
              style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    return OnboardingScaffold(
      topBar: close,
      content: [
        Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClSpace.s4),
            decoration: BoxDecoration(
              color: growth.soft,
              borderRadius: BorderRadius.circular(rhCardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(ClIcons.star, size: 18, color: growth.ink),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rhMsSavedTitle,
                        style: cl.text.bodyStrong.copyWith(color: growth.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.rhMsSavedSub(
                          saved.name,
                          shortDay(locale, isoOf(saved.date)),
                          memberLabel(l10n, me, myUid: me.uid),
                        ),
                        style: cl.text.label.copyWith(color: growth.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (cards) ...[
          const SizedBox(height: ClSpace.s6),
          Semantics(
            header: true,
            child: Text(l10n.rhMsKeepTitle, style: cl.text.title2),
          ),
          const SizedBox(height: ClSpace.s3),
          RhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tile(false),
                    const SizedBox(width: ClSpace.s3),
                    tile(true),
                  ],
                ),
                const SizedBox(height: ClSpace.s3),
                Text(
                  l10n.rhMsPhotoNote,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ],
      bottom: [
        if (cards) ...[
          ClButton(
            label: l10n.rhMsCreateCard,
            expand: true,
            onPressed: createCard,
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.rhLater,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => leaveRhythm(context),
          ),
        ] else
          ClButton(
            label: l10n.rhDone,
            expand: true,
            onPressed: () => leaveRhythm(context),
          ),
      ],
    );
  }
}
