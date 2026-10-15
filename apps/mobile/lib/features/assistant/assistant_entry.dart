import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart' show babyProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../premium/premium_repository.dart' show capabilitiesProvider;
import '../spending/spending_models.dart' show SpendingAccess;
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';
import 'assistant_screens.dart';
import 'assistant_widgets.dart';

/// The assistant's entry points (CH01 Home, CH01b module) and its rollout. Everything ships dark:
/// the chat shows only where `getCapabilities.features.assistant` is on for the family (P-161
/// `assistant` flag); photo reading only with `features.assistantImages`.
@immutable
class AssistantAccess {
  const AssistantAccess({this.images = false});

  /// `assistant_images`: the camera in the composer and the photo chips.
  final bool images;
}

/// The family's rollout for [babyId], from the capabilities snapshot; null = no assistant.
final assistantAccessProvider = Provider.family<AssistantAccess?, String>((
  ref,
  babyId,
) {
  final caps = ref.watch(capabilitiesProvider(babyId)).value;
  if (caps == null || !caps.features.assistant) return null;
  return AssistantAccess(images: caps.features.assistantImages);
});

/// CH01 · "Trợ lý Child Life" on Hôm nay: a composer-look entry, the household's credits from the
/// server, and chips that only prefill. Every role sees it; a viewer opens it to ask (CH27).
class AssistantTodayCard extends ConsumerWidget {
  const AssistantTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final access = ref.watch(assistantAccessProvider(me.babyId));
    if (access == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final language = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final usage = ref
        .watch(assistantUsageProvider((me.babyId, language)))
        .value;
    final view = usage == null ? null : UsageView.of(usage);
    final scope = AssistantScope.child(me.babyId);
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final writer = me.role != MemberRole.relative;
    void open({String? prefill}) =>
        openAssistant(context, scope, prefill: prefill);

    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AsSparkTile(),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.asEntryTitle,
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cl.colors.ink,
                      ),
                    ),
                  ),
                ),
                if (view != null)
                  Text(
                    view.level == UsageLevel.out
                        ? l10n.asEntryOut(resetDate(locale, view.usage, zone))
                        : l10n.asEntryLeft(view.remaining, view.limit),
                    style: cl.text.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: view.level == UsageLevel.out
                          ? cl.colors.error
                          : cl.colors.inkMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            ClPressable(
              onPressed: () => open(),
              semanticLabel: l10n.asEntryTitle,
              pressedOpacity: 0.7,
              child: Container(
                padding: const EdgeInsets.all(ClSpace.s2),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cl.colors.controlBorder),
                ),
                child: Row(
                  children: [
                    if (access.images && writer) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cl.colors.surface2,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: ClIcon(
                          ClIcons.camera,
                          size: 18,
                          color: cl.colors.ink,
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                    ] else
                      const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: Text(
                        writer
                            ? (access.images
                                  ? l10n.asComposerHint
                                  : l10n.asComposerHintText)
                            : l10n.asComposerViewer,
                        maxLines: 2,
                        style: cl.text.label.copyWith(
                          fontSize: 15,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cl.colors.surface2,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: ClIcon(
                        ClIcons.arrowRight,
                        size: 18,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (writer)
                  AsChip(
                    label: l10n.asChipLogFeed,
                    onPressed: () => open(prefill: l10n.asPrefillFeed),
                  ),
                AsChip(
                  label: l10n.asChipFeedsToday,
                  onPressed: () => open(prefill: l10n.asChipFeedsToday),
                ),
                // A receipt belongs to the household (CH01b context "Chi tiêu · Gia đình").
                if (access.images && SpendingAccess.of(me).record)
                  AsChip(
                    label: l10n.asChipReceipt,
                    onPressed: () => openAssistant(
                      context,
                      AssistantScope.household(me.babyId),
                      hint: IntentHint.expense,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CH01b · the module entry ("Chụp hoá đơn hoặc nhắn để ghi" in Chi tiêu): opens the chat in the
/// household scope with the module's intent hint; the manual form stays next to it.
class AssistantModuleEntry extends ConsumerWidget {
  const AssistantModuleEntry({
    required this.babyId,
    this.hint = IntentHint.expense,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String babyId;
  final IntentHint hint;

  /// Around the entry only when it shows (the module's layout is unchanged while the flag is off).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(assistantAccessProvider(babyId));
    if (access == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final title = access.images
        ? l10n.asModuleExpenseTitle
        : l10n.asModuleExpenseTextOnly;
    return Padding(
      padding: padding,
      child: ClPressable(
        onPressed: () => openAssistant(
          context,
          AssistantScope.household(babyId),
          hint: hint,
        ),
        semanticLabel: title,
        pressedOpacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: ClIcon(
                  access.images ? ClIcons.camera : ClIcons.spark,
                  size: 18,
                  color: cl.colors.mintText,
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cl.colors.mintText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.asModuleSub,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.mintText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat/Nút trợ lý on Hôm nay (the tab root only): opens the chat (the open conversation), also
/// when the pool is used up (history and direct logging still work there).
class AssistantFloatingEntry extends ConsumerWidget {
  const AssistantFloatingEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || ref.watch(assistantAccessProvider(me.babyId)) == null) {
      return const SizedBox.shrink();
    }
    return AsFloatingButton(
      onPressed: () => openAssistant(context, AssistantScope.child(me.babyId)),
    );
  }
}
