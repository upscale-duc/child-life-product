import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../baby/time_zones.dart';
import '../home/home_shell.dart';
import 'setup_draft.dart';
import 'setup_sheets.dart';
import 'widgets/onboarding_layout.dart';

/// Setup progress across 10a → 11 → 12 (Figma's own values conflict, Q in extract 01 §2).
const _progressWho = 1 / 3;
const _progressBaby = 2 / 3;
const _progressTrackers = 0.9;

String relationLabel(
  AppLocalizations l10n,
  Relation relation, [
  String custom = '',
]) => switch (relation) {
  Relation.mother => l10n.relationMother,
  Relation.father => l10n.relationFather,
  Relation.grandmother => l10n.relationGrandmother,
  Relation.grandfather => l10n.relationGrandfather,
  Relation.nanny => l10n.relationNanny,
  Relation.relative => l10n.relationRelative,
  Relation.friend => l10n.relationFriend,
  Relation.other => custom.trim().isEmpty ? l10n.relationOther : custom.trim(),
};

/// 10a Bạn là ai với bé (115:11756): display name + relation (R-008).
class WhoAreYouScreen extends ConsumerStatefulWidget {
  const WhoAreYouScreen({super.key});

  @override
  ConsumerState<WhoAreYouScreen> createState() => _WhoAreYouScreenState();
}

class _WhoAreYouScreenState extends ConsumerState<WhoAreYouScreen> {
  late final TextEditingController _name;
  late final TextEditingController _custom;

  @override
  void initState() {
    super.initState();
    var draft = ref.read(setupDraftProvider);
    if (draft.displayName.isEmpty) {
      // Apple / Google may already know the name; the user can edit it.
      final providerName = ref.read(providerDisplayNameProvider)?.trim() ?? '';
      if (providerName.isNotEmpty) {
        draft = draft.copyWith(displayName: providerName.split(' ').last);
        ref.read(setupDraftProvider.notifier).update(draft);
      }
    }
    _name = TextEditingController(text: draft.displayName)..addListener(_sync);
    _custom = TextEditingController(text: draft.relationCustom)
      ..addListener(_sync);
  }

  void _sync() {
    final draft = ref.read(setupDraftProvider);
    ref
        .read(setupDraftProvider.notifier)
        .update(
          draft.copyWith(displayName: _name.text, relationCustom: _custom.text),
        );
  }

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final draft = ref.watch(setupDraftProvider);
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: context.canPop()
            ? () => context.pop()
            : () => ref.read(authRepositoryProvider).signOut(),
        progress: _progressWho,
      ),
      content: [
        ScreenHeading(
          title: l10n.whoTitle,
          subtitle: l10n.whoSubtitle(
            relationLabel(l10n, draft.relation, draft.relationCustom),
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClTextField(
          label: l10n.whoNameLabel,
          placeholder: l10n.whoNamePlaceholder,
          controller: _name,
          standalone: true,
          textCapitalization: TextCapitalization.words,
          maxLength: displayNameMaxLength,
          autofillHints: const [AutofillHints.givenName],
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.whoYouAre,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final relation in selfRelations)
              ClRelationChip(
                label: relation == Relation.other
                    ? l10n.relationOther
                    : relationLabel(l10n, relation),
                selected: draft.relation == relation,
                onTap: () => ref
                    .read(setupDraftProvider.notifier)
                    .update(draft.copyWith(relation: relation)),
              ),
          ],
        ),
        _MaybeAnimatedSize(
          child: draft.relation == Relation.other
              ? Padding(
                  padding: const EdgeInsets.only(top: ClSpace.s4),
                  child: ClTextField(
                    label: l10n.whoCustomLabel,
                    placeholder: l10n.whoCustomPlaceholder,
                    controller: _custom,
                    standalone: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: relationCustomMaxLength,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.actionNext,
          expand: true,
          onPressed: draft.whoComplete
              ? () => context.push(Routes.babyProfile)
              : null,
        ),
      ],
    );
  }
}

/// 11 Hồ sơ bé (29:721) with sheets 11a / 11b / 11c.
class BabyProfileScreen extends ConsumerStatefulWidget {
  const BabyProfileScreen({super.key});

  @override
  ConsumerState<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends ConsumerState<BabyProfileScreen> {
  late final TextEditingController _nickname;
  final _nicknameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nickname =
        TextEditingController(text: ref.read(setupDraftProvider).nickname)
          ..addListener(() {
            final draft = ref.read(setupDraftProvider);
            ref
                .read(setupDraftProvider.notifier)
                .update(draft.copyWith(nickname: _nickname.text));
          });
    unawaited(_initTimeZone());
  }

  /// "Tự động theo máy" is the default (P-014): the device's IANA zone.
  Future<void> _initTimeZone() async {
    if (ref.read(setupDraftProvider).timeZone != null) return;
    final zone = await deviceTimeZone();
    if (!mounted) return;
    final draft = ref.read(setupDraftProvider);
    if (draft.timeZone == null) {
      ref
          .read(setupDraftProvider.notifier)
          .update(
            draft.copyWith(timeZone: TimeZoneSetting(zone: zone, auto: true)),
          );
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  void _next() {
    if (_nickname.text.trim().isEmpty) {
      _nicknameFocus.requestFocus();
      showClToast(
        context,
        message: AppLocalizations.of(context).babyNicknameRequired,
      );
      return;
    }
    context.push(Routes.trackers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop(), progress: _progressBaby),
      content: babyFormFields(
        context,
        ref,
        nickname: _nickname,
        focus: _nicknameFocus,
      ),
      bottom: [
        ClButton(label: l10n.actionNext, expand: true, onPressed: _next),
      ],
    );
  }
}

/// 12 Chọn theo dõi (29:795): "Xong · N mục" creates the baby (createBabyProfile).
class TrackersScreen extends ConsumerStatefulWidget {
  const TrackersScreen({super.key});

  @override
  ConsumerState<TrackersScreen> createState() => _TrackersScreenState();
}

class _TrackersScreenState extends ConsumerState<TrackersScreen> {
  bool _busy = false;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(setupDraftProvider);
    final repo = ref.read(babyRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      final babyId = await repo.createBaby(draft.toInput());
      final photo = draft.avatarPhoto;
      if (photo != null) {
        try {
          await repo.setAvatarPhoto(babyId, photo);
        } on Object {
          if (mounted) showClToast(context, message: l10n.avatarUploadFailed);
        }
      }
      ref.read(setupDraftProvider.notifier).reset();
      if (ref.read(addingBabyProvider)) {
        // "Thêm hồ sơ bé": open the new baby once the membership has arrived.
        await waitForMembership(container, babyId);
        container.read(selectedBabyIdProvider.notifier).select(babyId);
        container.read(addingBabyProvider.notifier).set(false);
        if (mounted) context.go(Routes.today);
      }
      // A first baby: the session now has a baby and the router opens Today.
    } on BabyException catch (e) {
      if (!mounted) return;
      showClToast(
        context,
        message: switch (e.failure) {
          BabyFailure.babyLimit => l10n.createBabyLimit,
          BabyFailure.dobInFuture => l10n.createBabyDobFuture,
          _ => l10n.createBabyFailed,
        },
      );
    } on Object {
      if (mounted) showClToast(context, message: l10n.createBabyFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(setupDraftProvider);
    void toggle(TrackerKind kind) {
      final next = {...draft.trackers};
      next.contains(kind) ? next.remove(kind) : next.add(kind);
      ref
          .read(setupDraftProvider.notifier)
          .update(draft.copyWith(trackers: next));
    }

    Widget tile(TrackerKind kind) => Expanded(
      child: ClSelectTile(
        label: trackerLabel(l10n, kind),
        art: ClArt(trackerArt(kind)),
        selected: draft.trackers.contains(kind),
        onTap: () => toggle(kind),
        width: double.infinity,
      ),
    );

    Widget row(TrackerKind kind) => _TrackerRow(
      label: trackerLabel(l10n, kind),
      art: trackerArt(kind),
      selected: draft.trackers.contains(kind),
      onTap: () => toggle(kind),
    );

    final count = draft.trackers.length;
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.pop(),
        progress: _progressTrackers,
      ),
      content: [
        ScreenHeading(
          title: l10n.trackersTitle,
          subtitle: l10n.trackersSubtitle,
        ),
        const SizedBox(height: ClSpace.s6),
        Row(
          children: [
            tile(TrackerKind.bottle),
            const SizedBox(width: ClSpace.s3),
            tile(TrackerKind.breast),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            tile(TrackerKind.sleep),
            const SizedBox(width: ClSpace.s3),
            tile(TrackerKind.diaper),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        row(TrackerKind.pump),
        const SizedBox(height: ClSpace.s3),
        row(TrackerKind.growth),
      ],
      bottom: [
        ClButton(
          label: count == 0 ? l10n.trackersPickOne : l10n.trackersDone(count),
          expand: true,
          onPressed: count == 0 || _busy ? null : _create,
        ),
      ],
    );
  }
}

String trackerLabel(AppLocalizations l10n, TrackerKind kind) => switch (kind) {
  TrackerKind.bottle => l10n.trackerBottle,
  TrackerKind.breast => l10n.trackerBreast,
  TrackerKind.sleep => l10n.trackerSleep,
  TrackerKind.diaper => l10n.trackerDiaper,
  TrackerKind.pump => l10n.trackerPump,
  TrackerKind.growth => l10n.trackerGrowth,
};

ClIllustration trackerArt(TrackerKind kind) => switch (kind) {
  TrackerKind.bottle => ClIllustration.miniBottle,
  TrackerKind.breast => ClIllustration.miniDrop,
  TrackerKind.sleep => ClIllustration.miniMoon,
  TrackerKind.diaper => ClIllustration.miniDiaper,
  TrackerKind.pump => ClIllustration.miniPump,
  TrackerKind.growth => ClIllustration.miniRuler,
};

/// Live age for 11a ("Teddy được 3 tuần tuổi").
String dobHint(AppLocalizations l10n, String nickname, DateTime dob) =>
    l10n.dobAgeHint(
      nickname.trim().isEmpty ? l10n.babyNicknamePlaceholder : nickname.trim(),
      ageLong(l10n, dob, DateTime.now()),
    );

/// AnimatedSize, or an instant change with Reduce Motion (a zero duration is not allowed).
class _MaybeAnimatedSize extends StatelessWidget {
  const _MaybeAnimatedSize({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => context.reduceMotion
      ? child
      : AnimatedSize(
          duration: ClMotion.standard,
          curve: ClCurves.quick,
          alignment: Alignment.topCenter,
          child: child,
        );
}

/// Full-width tracker row on 12 (Hút sữa, Tăng trưởng): art, label and a radio-style check.
/// Same selected treatment as SelectTile (25:399): mint-soft fill and 2 px mint-deep border.
class _TrackerRow extends StatelessWidget {
  const _TrackerRow({
    required this.label,
    required this.art,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ClIllustration art;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      checked: selected,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: context.motion(ClMotion.quick),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          decoration: BoxDecoration(
            color: selected ? cl.colors.mintSoft : cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.tile),
            border: Border.all(
              color: selected ? cl.colors.mintDeep : Colors.transparent,
              width: 2,
            ),
            boxShadow: selected ? null : cl.shadows.card,
          ),
          child: Row(
            children: [
              SizedBox(width: 48, height: 48, child: ClArt(art)),
              const SizedBox(width: ClSpace.s4),
              Expanded(child: Text(label, style: cl.text.headline)),
              ClRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// The baby form of 11 (photo, nickname, DOB, zone, gender, privacy note), shared by 13k
/// "Sửa hồ sơ bé · dùng lại form tạo". Reads and writes [setupDraftProvider].
List<Widget> babyFormFields(
  BuildContext context,
  WidgetRef ref, {
  required TextEditingController nickname,
  required FocusNode focus,
}) {
  final l10n = AppLocalizations.of(context);
  final cl = context.cl;
  final draft = ref.watch(setupDraftProvider);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final zone = draft.timeZone;
  return [
    Center(
      child: ClPressable(
        semanticLabel: l10n.a11yChangeBabyPhoto,
        onPressed: () => showAvatarSheet(context),
        child: SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: context.motion(ClMotion.quick),
                child: draft.avatarPhoto != null
                    ? BabyAvatarImage.photo(
                        draft.avatarPhoto!,
                        size: 148,
                        key: ValueKey(draft.avatarPhoto),
                      )
                    : BabyAvatarImage.preset(
                        draft.avatarPreset,
                        size: 148,
                        key: ValueKey(draft.avatarPreset),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cl.colors.mintDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: cl.colors.cloud, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    ClIcons.camera,
                    size: 20,
                    color: cl.colors.onMintDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: ClSpace.s4),
    Text(
      l10n.babyNicknameLabel,
      textAlign: TextAlign.center,
      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
    ),
    // Large inline nickname ("Teddy", 29:721).
    Stack(
      alignment: Alignment.center,
      children: [
        if (draft.nickname.isEmpty)
          IgnorePointer(
            child: ExcludeSemantics(
              child: Text(
                l10n.babyNicknamePlaceholder,
                style: cl.text.largeTitle.copyWith(
                  color: cl.colors.inkMuted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        Semantics(
          label: l10n.babyNicknameLabel,
          textField: true,
          child: EditableText(
            controller: nickname,
            focusNode: focus,
            textAlign: TextAlign.center,
            style: cl.text.largeTitle.copyWith(color: cl.colors.ink),
            cursorColor: cl.colors.mintDeep,
            backgroundCursorColor: cl.colors.separator,
            textCapitalization: TextCapitalization.words,
            maxLines: 1,
            inputFormatters: [
              LengthLimitingTextInputFormatter(nicknameMaxLength),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: ClSpace.s4),
    ClCardGroup(
      shadow: true,
      children: [
        ClDetailRow(
          icon: ClIcons.cake,
          label: l10n.babyDob,
          value:
              (locale.startsWith('vi')
                      ? DateFormat.yMMMMd(locale)
                      : DateFormat.yMMMd(locale))
                  .format(draft.dateOfBirth),
          onTap: () => showDobSheet(context),
        ),
        ClDetailRow(
          icon: ClIcons.globe,
          label: l10n.babyTimeZone,
          value: zone == null ? '…' : gmtOffsetLabel(zone.zone, DateTime.now()),
          onTap: () => showTimeZoneSheet(context),
        ),
      ],
    ),
    const SizedBox(height: ClSpace.s6),
    Text.rich(
      TextSpan(
        text: l10n.babyGender,
        children: [
          TextSpan(
            text: ' · ${l10n.babyOptional}',
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
      style: cl.text.caption.copyWith(color: cl.colors.ink),
    ),
    const SizedBox(height: ClSpace.s2),
    ClSegmented<Gender>(
      options: Gender.values,
      selected: draft.gender,
      labelOf: (g) => switch (g) {
        Gender.girl => l10n.genderGirl,
        Gender.boy => l10n.genderBoy,
        Gender.unspecified => l10n.genderUnspecified,
      },
      onChanged: (g) => ref
          .read(setupDraftProvider.notifier)
          .update(draft.copyWith(gender: g)),
    ),
    const SizedBox(height: ClSpace.s4),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClIcon(ClIcons.lock, size: 14, color: cl.colors.inkMuted),
        const SizedBox(width: ClSpace.s1),
        Flexible(
          child: Text(
            l10n.babyPrivacyNote,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    ),
  ];
}
