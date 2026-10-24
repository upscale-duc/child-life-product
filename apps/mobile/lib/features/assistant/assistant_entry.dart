import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reminders/reminder_notifications.dart'
    show notificationsLaunchAskProvider;
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart' show ClTourTip;
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../premium/premium_repository.dart' show capabilitiesNowProvider;
import '../spending/spending_models.dart' show SpendingAccess;
import 'assistant_models.dart';
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
  final caps = ref.watch(capabilitiesNowProvider(babyId));
  if (caps == null || !caps.features.assistant) return null;
  return AssistantAccess(images: caps.features.assistantImages);
});

/// CH01 · "Trợ lý Child Life" on Hôm nay: a composer-look entry and chips that only prefill. No
/// credits here (D-081: they live in "Chi tiết" only). Every role sees it; a viewer opens it to ask (CH27).
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
    final scope = AssistantScope.child(me.babyId);
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

/// The Lumi first-run tooltip (669:64442) was answered by this person ("Thử ngay" or "Để sau"),
/// keyed by uid: once per person on this phone, never again after either answer.
final lumiIntroSeenProvider =
    NotifierProvider.family<LumiIntroSeenNotifier, bool, String>(
      LumiIntroSeenNotifier.new,
    );

class LumiIntroSeenNotifier extends Notifier<bool> {
  LumiIntroSeenNotifier(this.uid);
  final String uid;

  static String keyFor(String uid) => 'assistant.lumiIntro.$uid';

  @override
  bool build() {
    try {
      return ref.read(sharedPreferencesProvider).getBool(keyFor(uid)) ?? false;
    } on Object {
      return false;
    }
  }

  void markSeen() {
    if (state) return;
    state = true;
    try {
      ref.read(sharedPreferencesProvider).setBool(keyFor(uid), true).ignore();
    } on Object {
      // No preferences (tests): seen for this run.
    }
  }
}

/// Chat/Nút trợ lý on Hôm nay (the tab root only): Lumi (627:62667), which opens the chat (the
/// open conversation), also when the pool is used up (history and direct logging still work
/// there). The first time the assistant is there for this person, a tooltip introduces Lumi
/// (669:64442) over a dimmed Hôm nay, the button ringed: "Thử ngay" opens the chat, "Để sau"
/// closes it; either answer is kept. It waits while anything else is on top ([canShowIntro],
/// another route, a sheet) and never shows over a modal.
class AssistantFloatingEntry extends ConsumerStatefulWidget {
  const AssistantFloatingEntry({this.canShowIntro, super.key});

  /// False while the tab has something open over it (a sheet on the tab's own navigator).
  final bool Function()? canShowIntro;

  /// How long Hôm nay settles before the tooltip, and how often it looks again while blocked.
  static const introDelay = Duration(milliseconds: 800);
  static const introRetry = Duration(seconds: 2);

  @override
  ConsumerState<AssistantFloatingEntry> createState() =>
      _AssistantFloatingEntryState();
}

class _AssistantFloatingEntryState
    extends ConsumerState<AssistantFloatingEntry> {
  final _tip = OverlayPortalController();
  final _link = LayerLink();
  Timer? _wait;

  /// A system alert (the D-098 notification prompt) makes the app inactive: the tooltip steps
  /// aside, still unseen, and comes back once the app is active again (owner, 2026-10-24: both
  /// showed at once).
  late final AppLifecycleListener _life = AppLifecycleListener(
    onInactive: () {
      if (mounted && _tip.isShowing) setState(_tip.hide);
    },
  );

  @override
  void initState() {
    super.initState();
    _life;
  }

  @override
  void dispose() {
    _wait?.cancel();
    _life.dispose();
    super.dispose();
  }

  bool _allowed(String uid) {
    if (!mounted || ref.read(lumiIntroSeenProvider(uid))) return false;
    final state = WidgetsBinding.instance.lifecycleState;
    final route = ModalRoute.of(context);
    return (state == null || state == AppLifecycleState.resumed) &&
        // D-098: the system notification prompt on the first entry goes first.
        !ref.read(notificationsLaunchAskProvider).isLoading &&
        (route == null || route.isCurrent) &&
        TickerMode.valuesOf(context).enabled &&
        (widget.canShowIntro?.call() ?? true);
  }

  /// Shows the tooltip once Hôm nay has settled and nothing is on top; looks again later.
  void _schedule(String uid, Duration after) {
    if (_wait != null || _tip.isShowing) return;
    _wait = Timer(after, () {
      _wait = null;
      if (!mounted || ref.read(lumiIntroSeenProvider(uid))) return;
      if (_allowed(uid)) {
        setState(_tip.show);
      } else {
        _schedule(uid, AssistantFloatingEntry.introRetry);
      }
    });
  }

  void _answer(String uid, {required bool open, required String babyId}) {
    ref.read(lumiIntroSeenProvider(uid).notifier).markSeen();
    setState(_tip.hide);
    if (open) openAssistant(context, AssistantScope.child(babyId));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(selectedMembershipProvider);
    final access = me == null
        ? null
        : ref.watch(assistantAccessProvider(me.babyId));
    if (me == null || access == null) {
      _wait?.cancel();
      _wait = null;
      return const SizedBox.shrink();
    }
    final seen = ref.watch(lumiIntroSeenProvider(me.uid));
    // Started here too, so the tooltip's check finds it settled (the shell also watches it).
    ref.watch(notificationsLaunchAskProvider);
    if (!seen) {
      // Something came on top while it showed: hide (still unseen) and wait for it to go.
      if (_tip.isShowing && !_allowed(me.uid)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tip.isShowing) setState(_tip.hide);
        });
      }
      _schedule(me.uid, AssistantFloatingEntry.introDelay);
    }
    void open() => openAssistant(context, AssistantScope.child(me.babyId));
    final l10n = AppLocalizations.of(context);
    final writer = me.role != MemberRole.relative;
    final body = !writer
        ? l10n.asLumiIntroBodyViewer
        : access.images && SpendingAccess.of(me).record
        ? l10n.asLumiIntroBody
        : l10n.asLumiIntroBodyText;
    return OverlayPortal(
      controller: _tip,
      overlayChildBuilder: (_) => _LumiIntro(
        link: _link,
        body: body,
        onLater: () => _answer(me.uid, open: false, babyId: me.babyId),
        onTry: () => _answer(me.uid, open: true, babyId: me.babyId),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: AsFloatingButton(onPressed: open),
      ),
    );
  }
}

/// 669:64442: Hôm nay dimmed, Lumi ringed above the scrim, the tooltip above Lumi with its
/// pointer on it ("Mới", the title, what Lumi does, "Để sau" · "Thử ngay").
class _LumiIntro extends StatelessWidget {
  const _LumiIntro({
    required this.link,
    required this.body,
    required this.onLater,
    required this.onTry,
  });

  final LayerLink link;
  final String body;
  final VoidCallback onLater;
  final VoidCallback onTry;

  static const _tipWidth = 300.0;
  static const _button = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Stack(
      key: const ValueKey('lumi.intro'),
      children: [
        // Taps on the dimmed page do nothing: one of the two answers closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: ColoredBox(color: cl.colors.scrim),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            child: AsFloatingButton(
              onPressed: onTry,
              highlight: true,
              attention: false,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -ClSpace.s3),
            child: ClTourTip(
              step: l10n.asLumiIntroEyebrow,
              title: l10n.asLumiIntroTitle,
              body: body,
              skipLabel: l10n.asLumiIntroLater,
              nextLabel: l10n.asLumiIntroTry,
              onSkip: onLater,
              onNext: onTry,
              pointerUp: false,
              // The pointer's tip on Lumi's centre (the card's right edge is Lumi's).
              pointerX: _tipWidth - _button / 2 - 10,
            ),
          ),
        ),
      ],
    );
  }
}
