import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/experience_repository.dart';
import '../adaptive/adaptive_engine.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_duty.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'header_settings.dart';
import 'living_header.dart';

class HeaderAppearanceScreen extends ConsumerStatefulWidget {
  const HeaderAppearanceScreen({super.key});
  @override
  ConsumerState<HeaderAppearanceScreen> createState() =>
      _HeaderAppearanceState();
}

class _HeaderAppearanceState extends ConsumerState<HeaderAppearanceScreen> {
  HeaderSettings? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l = AppLocalizations.of(context);
    final HeaderSettings draft = _draft ?? ref.watch(headerSettingsProvider);
    final me = ref.watch(selectedMembershipProvider);
    final adaptive = ref.watch(adaptiveOnProvider);
    final showDuty =
        me != null &&
        ref.watch(careDutyChipVisibleProvider) &&
        (adaptive
            ? ref
                  .watch(adaptiveTodayProvider(me.babyId))
                  .any((w) => w.id == WidgetId.careDuty && w.visible)
            : draft.showDuty &&
                  careDutyByAge(ref.watch(childBandProvider(me.babyId))));
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop()),
      content: [
        Text(l.hhSettings, style: cl.text.title),
        const SizedBox(height: ClSpace.s6),
        ClipRRect(
          borderRadius: BorderRadius.circular(ClRadius.card),
          child: ColoredBox(
            color: cl.colors.surface2,
            child: SizedBox(
              height: showDuty ? 252 : 176,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 375,
                  height: showDuty ? 320 : 224,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: MediaQuery.withNoTextScaling(
                        child: TodayLivingHeader(
                          showDuty: showDuty,
                          settings: draft,
                          preview: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClCardGroup(
          children: [
            ClOptionRow(
              title: l.hhPattern,
              selected: draft.background == HeaderBackground.pattern,
              onTap: () => setState(
                () => _draft = draft.copyWith(
                  background: HeaderBackground.pattern,
                ),
              ),
            ),
            ClOptionRow(
              title: l.hhAvatar,
              subtitle:
                  me != null &&
                      ref.watch(babyProvider(me.babyId)).value?.avatar
                          is PhotoAvatar
                  ? null
                  : l.hhAvatarMissing,
              selected: draft.background == HeaderBackground.avatar,
              onTap: () => setState(
                () => _draft = draft.copyWith(
                  background: HeaderBackground.avatar,
                ),
              ),
            ),
            MeRow(
              title: l.hhChooseMemory,
              value: draft.background == HeaderBackground.memory
                  ? l.hhSelected
                  : null,
              onTap: () async {
                final id = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => HeaderMemoryPicker(selected: draft.mediaId),
                  ),
                );
                if (id != null && mounted) {
                  setState(
                    () => _draft = draft.copyWith(
                      background: HeaderBackground.memory,
                      mediaId: id,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        if (!ref.watch(adaptiveOnProvider)) ...[
          const SizedBox(height: ClSpace.s4),
          ClCardGroup(
            children: [
              MeRow(
                title: l.axWidgetCareDuty,
                trailing: ClToggle(
                  value: draft.showDuty,
                  semanticLabel: l.axWidgetCareDuty,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(showDuty: v)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          l.hhDeviceOnly,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
      bottom: [
        ClButton(
          label: l.hhApply,
          expand: true,
          loading: _saving,
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(headerSettingsProvider.notifier).save(draft);
                    if (context.mounted) context.pop();
                  } catch (_) {
                    if (context.mounted) {
                      showClToast(context, message: l.hhSaveFailed);
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
        ),
      ],
    );
  }
}

class HeaderMemoryPicker extends ConsumerWidget {
  const HeaderMemoryPicker({this.selected, super.key});
  final String? selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final state = ref.watch(
      mediaProvider((me.babyId, me.role == MemberRole.coParent)),
    );
    final photos =
        state.value
            ?.where(
              (m) =>
                  m.isReady &&
                  !m.deleted &&
                  !m.isVideo &&
                  m.generatedKind == null,
            )
            .toList() ??
        [];
    return MePage(
      title: l.hhChooseMemory,
      children: [
        if (!state.hasValue)
          state.hasError
              ? ClButton(
                  label: l.actionRetry,
                  onPressed: () => ref.invalidate(
                    mediaProvider((me.babyId, me.role == MemberRole.coParent)),
                  ),
                )
              : const ClSkeleton(height: 200)
        else if (photos.isEmpty)
          Text(l.hhPhotoEmpty, style: context.cl.text.body)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: ClSpace.s2,
              mainAxisSpacing: ClSpace.s2,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) => MediaTile(
              item: photos[i],
              selecting: true,
              selected: photos[i].id == selected,
              onTap: () => Navigator.of(context).pop(photos[i].id),
            ),
          ),
      ],
    );
  }
}
