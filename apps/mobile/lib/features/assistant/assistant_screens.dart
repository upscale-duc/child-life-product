import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_models.dart' show CareType;
import '../care/care_sheets.dart' show openCareLog, showQuickLog;
import '../premium/billing_models.dart';
import '../premium/billing_repository.dart' show videoQuotaProvider;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_repository.dart'
    show capabilitiesProvider, selectedCapabilitiesProvider;
import '../rhythm/rhythm_actions.dart' show healthLocation;
import '../rhythm/rhythm_models.dart' show HealthSign, wireList;
import '../rhythm/rhythm_repository.dart'
    show rhythmContentProvider, rhythmDialerProvider;
import '../rhythm/rhythm_widgets.dart' show rhConfirm;
import '../spending/spending_models.dart' show SpendingAccess;
import 'assistant_controller.dart';
import 'assistant_editor.dart';
import 'assistant_entry.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';
import 'assistant_widgets.dart';

/// What a Home chip or a module entry hands the chat: text that only PREFILLS the composer
/// (never sent by itself) and the module's intent hint.
class AssistantLaunch {
  const AssistantLaunch({this.prefill, this.hint});
  final String? prefill;
  final IntentHint? hint;
}

/// The chat's location for [scope] (and a conversation from CH03).
String assistantLocation(AssistantScope scope, {String? conversationId}) => Uri(
  path: Routes.assistant,
  queryParameters: {'scope': scope.key, 'conversation': ?conversationId},
).toString();

/// Opens the chat (CH02 or the open conversation); [prefill] goes into the composer only.
Future<void> openAssistant(
  BuildContext context,
  AssistantScope scope, {
  String? prefill,
  IntentHint? hint,
}) => context.push(
  assistantLocation(scope),
  extra: AssistantLaunch(prefill: prefill, hint: hint),
);

/// The paywall from the chat (CH22, the existing PR01; one plan, store price). True once the
/// household's Premium is verified. Tests may replace it.
final assistantPaywallProvider =
    Provider<
      Future<bool> Function(BuildContext context, PurchaseResume resume)
    >(
      (ref) =>
          (context, resume) =>
              openPaywall(context, entry: PaywallEntry.plan, resume: resume),
    );

/// The record kinds [me] may save through the chat (the server checks again per item).
bool canSaveKind(Membership? me, DraftKind? kind) {
  if (me == null || kind == null) return false;
  return switch (kind) {
    DraftKind.bottle ||
    DraftKind.breast ||
    DraftKind.sleep ||
    DraftKind.meal ||
    DraftKind.observation => me.role != MemberRole.relative,
    DraftKind.expense => SpendingAccess.of(me).record,
    DraftKind.reminder => me.role == MemberRole.coParent,
  };
}

Membership? _membership(WidgetRef ref, String babyId) {
  final session = ref.watch(sessionProvider);
  return session is SessionSignedIn ? session.membershipFor(babyId) : null;
}

/// "Teddy · 3 tuần" (age only where the member may see it) or "Gia đình".
String scopeLabel(
  BuildContext context,
  WidgetRef ref,
  AssistantScope scope,
  Membership? me,
) {
  final l10n = AppLocalizations.of(context);
  if (scope.household) return l10n.asScopeHousehold;
  final baby = ref.watch(babyProvider(scope.babyId)).value;
  final name = baby?.nickname ?? '';
  if (me == null || !me.canViewBabyInfo) return name;
  final profile = ref.watch(babyPrivateProfileProvider(scope.babyId)).value;
  if (profile == null) return name;
  return l10n.babySwitcherLabel(
    name,
    ageShort(l10n, profile.dateOfBirth, ref.read(assistantClockProvider)()),
  );
}

// ---------- CH02–CH08, CH20–CH28: the chat ----------

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({
    this.scopeKey,
    this.conversationId,
    this.launch,
    super.key,
  });

  final String? scopeKey;
  final String? conversationId;
  final AssistantLaunch? launch;

  @override
  ConsumerState<AssistantChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<AssistantChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  IntentHint? _hint;
  String? _openedFor;
  var _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _text.text = widget.launch?.prefill ?? '';
    _hint = widget.launch?.hint;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? _key() {
    final fromRoute = AssistantScope.fromKey(widget.scopeKey);
    if (fromRoute != null) return fromRoute.key;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn || session.active.isEmpty) return null;
    return AssistantScope.child(session.active.first.babyId).key;
  }

  AssistantChat _ctl(String key) =>
      ref.read(assistantChatProvider(key).notifier);

  void _open(String key) {
    if (_openedFor == key) return;
    _openedFor = key;
    final locale = Localizations.localeOf(context).languageCode;
    Future.microtask(
      () => _ctl(key).open(locale, conversationId: widget.conversationId),
    );
  }

  void _toast(ActionOutcome o) {
    final l10n = AppLocalizations.of(context);
    final message = switch (o) {
      ActionOutcome.offline => l10n.asSaveOffline,
      ActionOutcome.failed => l10n.asSaveError,
      ActionOutcome.stale => l10n.asErrStale,
      _ => null,
    };
    if (message != null) showClToast(context, message: message, error: true);
  }

  Future<void> _send(String key) async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    final hint = _hint;
    _hint = null;
    await _ctl(key).send(text, hint: hint);
  }

  Future<void> _upgrade(String key, {bool photo = false}) async {
    final ok = await ref.read(assistantPaywallProvider)(
      context,
      PurchaseResume(kind: ResumeKind.assistant, draftRef: key),
    );
    if (!ok || !mounted) return;
    if (photo) {
      await _ctl(key).pickPhotoAgain();
    } else {
      await _ctl(key).resumeAfterUpgrade();
    }
  }

  void _logDirectly(AssistantScope scope) =>
      scope.household ? context.push(Routes.spending) : showQuickLog(context);

  Future<void> _dial(String? number) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final ok = await ref.read(rhythmDialerProvider)(number ?? '');
    if (!ok) toaster.show(message: l10n.asDialFailed, error: true);
  }

  Future<void> _pickScope(AssistantScope current) async {
    final session = ref.read(sessionProvider);
    if (session is! SessionSignedIn) return;
    final l10n = AppLocalizations.of(context);
    final options = [
      for (final m in session.active) AssistantScope.child(m.babyId),
      AssistantScope.household(current.babyId),
    ];
    final picked = await showClSheet<AssistantScope>(
      context: context,
      builder: (sheet) => Consumer(
        builder: (sheet, ref, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.asScopeTitle),
            for (final o in options)
              ClPressable(
                onPressed: () => Navigator.of(sheet).pop(o),
                selected: o == current,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      ClIcon(
                        o.household ? ClIcons.family : ClIcons.cake,
                        size: 20,
                        color: sheet.cl.colors.mintText,
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Text(
                          scopeLabel(sheet, ref, o, _membership(ref, o.babyId)),
                          style: sheet.cl.text.body,
                        ),
                      ),
                      if (o == current)
                        ClIcon(
                          ClIcons.check,
                          size: 18,
                          color: sheet.cl.colors.mintText,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: ClSpace.s4),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    // Another scope is another chat: its drafts stay with its own baby (CH03).
    context.replace(assistantLocation(picked));
  }

  Future<void> _history(AssistantScope scope) async {
    final pick = await context.push<HistoryPick>(
      Uri(
        path: Routes.assistantHistory,
        queryParameters: {'scope': scope.key},
      ).toString(),
    );
    if (pick == null || !mounted) return;
    if (pick.scope != scope) {
      context.replace(
        assistantLocation(pick.scope, conversationId: pick.conversationId),
      );
      return;
    }
    final ctl = _ctl(scope.key);
    if (pick.conversationId == null) {
      ctl.newConversation();
    } else {
      await ctl.open(
        Localizations.localeOf(context).languageCode,
        conversationId: pick.conversationId,
      );
    }
  }

  void _scrollToEnd(int length) {
    if (length == _lastLength) return;
    _lastLength = length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final key = _key();
    if (key == null) return Scaffold(backgroundColor: cl.colors.cloud);
    _open(key);
    final chat = ref.watch(assistantChatProvider(key));
    final ctl = _ctl(key);
    final scope = chat.scope;
    final me = _membership(ref, scope.babyId);
    final viewer = me?.role == MemberRole.relative;
    final baby = ref.watch(babyProvider(scope.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(assistantClockProvider)();
    final access = ref.watch(assistantAccessProvider(scope.babyId));
    final images = access?.images ?? false;
    final usage = chat.usageView;
    final online = ref.watch(assistantOnlineProvider).value ?? true;
    final premium = usage?.premium ?? false;
    // P-161 `assistant_upsell`: off = running out only shows the reset date, no purchase prompt.
    final upsell =
        ref.watch(selectedCapabilitiesProvider)?.features.assistantUpsell ??
        false;
    final out =
        usage?.level == UsageLevel.out ||
        chat.block?.kind == ChatBlockKind.exhausted;
    final mode = viewer
        ? ComposerMode.viewer
        : out
        ? ComposerMode.out
        : ComposerMode.open;
    final hint = chat.answering != null
        ? l10n.asComposerAnswer
        : switch (mode) {
            ComposerMode.viewer => l10n.asComposerViewer,
            ComposerMode.out =>
              premium ? l10n.asComposerOutPremium : l10n.asComposerOutFree,
            ComposerMode.open =>
              images ? l10n.asComposerHint : l10n.asComposerHintText,
          };
    final babyName = baby?.nickname ?? '';
    final view = _ThreadView(
      chat: chat,
      ctl: ctl,
      me: me,
      viewer: viewer,
      zone: zone,
      now: now,
      babyName: babyName,
      premium: premium,
      upsell: upsell,
      online: online,
      onToast: _toast,
      onUpgrade: ({bool photo = false}) => _upgrade(key, photo: photo),
      onLogDirectly: () => _logDirectly(scope),
      onDial: _dial,
      onTypeInstead: () {
        ctl.removePhoto();
        _focus.requestFocus();
      },
      onTypeAnswer: (taskId) {
        ctl.typeAnswer(taskId);
        _focus.requestFocus();
      },
    );
    final children = <Widget>[
      if (chat.empty)
        _EmptyState(
          scope: scope,
          babyName: babyName,
          images: images,
          onExample: (text) {
            _text.text = text;
            _text.selection = TextSelection.collapsed(offset: text.length);
            _focus.requestFocus();
          },
          onPhoto: images && !viewer ? ctl.pickPhoto : null,
        ),
      ...view.build(context),
    ];
    _scrollToEnd(children.length + chat.threads.length);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: AsChatHeader(
                scopeLabel: scopeLabel(context, ref, scope, me),
                household: scope.household,
                onBack: () =>
                    context.canPop() ? context.pop() : context.go(Routes.today),
                onScope: () => _pickScope(scope),
                onHistory: () => _history(scope),
                onNew: ctl.newConversation,
              ),
            ),
            if (usage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: AsUsagePill(view: usage, zone: zone),
                    ),
                    const SizedBox(width: ClSpace.s2),
                    AsLink(
                      label: l10n.asDetails,
                      onPressed: () => context.push(
                        Uri(
                          path: Routes.assistantUsage,
                          queryParameters: {'baby': scope.babyId},
                        ).toString(),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClSpace.s4,
                ),
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => children[i],
              ),
            ),
            AsComposer(
              controller: _text,
              focusNode: _focus,
              mode: mode,
              hint: hint,
              sending: chat.sending,
              onSend: () => _send(key),
              onCamera: images && mode == ComposerMode.open
                  ? ctl.pickPhoto
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the thread: each task (its messages, drafts and state), then the kept input and the
/// notice that explains it.
class _ThreadView {
  _ThreadView({
    required this.chat,
    required this.ctl,
    required this.me,
    required this.viewer,
    required this.zone,
    required this.now,
    required this.babyName,
    required this.premium,
    required this.upsell,
    required this.online,
    required this.onToast,
    required this.onUpgrade,
    required this.onLogDirectly,
    required this.onDial,
    required this.onTypeInstead,
    required this.onTypeAnswer,
  });

  final ChatState chat;
  final AssistantChat ctl;
  final Membership? me;
  final bool viewer;
  final String zone;
  final DateTime now;
  final String babyName;
  final bool premium;
  final bool upsell;
  final bool online;
  final void Function(ActionOutcome) onToast;
  final Future<void> Function({bool photo}) onUpgrade;
  final VoidCallback onLogDirectly;
  final Future<void> Function(String? number) onDial;
  final VoidCallback onTypeInstead;
  final void Function(String taskId) onTypeAnswer;

  List<Widget> build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final out = <Widget>[];
    if (chat.loadFailed) {
      out.add(
        AsCard(
          tone: AsTone.errorEdge,
          body: l10n.asGenericError,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AsButton(label: l10n.asRetry, onPressed: ctl.reload),
            ),
          ],
        ),
      );
    }
    for (final (i, t) in chat.threads.indexed) {
      if (chat.resumed && i == chat.threads.length - 1) {
        out.add(_resumedBanner(context));
      }
      out.addAll(_thread(context, t));
    }
    if (chat.resumed && chat.threads.isNotEmpty) {
      out.add(AsFootnote(text: l10n.asResumedNote));
    }
    if (chat.restoring && chat.threads.every((t) => t.snapshot == null)) {
      out.add(AsBubble(text: l10n.asLoadingChat));
    }
    if (chat.kept case final kept?) {
      out.add(
        AsBubble(
          text: kept.text,
          mine: true,
          status: chat.sending ? l10n.asSending : l10n.asUnsent,
          statusIcon: chat.sending ? null : ClIcons.cloudOff,
        ),
      );
    }
    if (chat.photo case final photo?) {
      out.add(_photoTile(context, photo));
    }
    if (chat.block case final block?) {
      out.addAll(_blockCards(context, block));
    }
    return out;
  }

  Widget _resumedBanner(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppLocalizations.of(context).asResumedBanner,
              style: cl.text.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.mintText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoTile(BuildContext context, PendingPhoto photo) {
    final cl = context.cl;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s2),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: ClIcon(
                ClIcons.camera,
                size: 18,
                color: cl.colors.inkMuted,
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            Text(
              AppLocalizations.of(context).asPhotoNotSent,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(width: ClSpace.s2),
          ],
        ),
      ),
    );
  }

  /// "Hướng dẫn sức khoẻ thiết yếu vẫn mở" with its link (health is never behind credits).
  Widget _healthNote(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      width: asCardWidth,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClIcon(
                  ClIcons.heart,
                  size: 13,
                  color: cl.colors.inkMuted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.asHealthStillOpen,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
          AsLink(
            label: l10n.asOpenHealth,
            onPressed: () =>
                GoRouter.of(context).push(healthLocation(const [])),
          ),
        ],
      ),
    );
  }

  List<Widget> _blockCards(BuildContext context, ChatBlock block) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final usage = block.quote?.usage ?? chat.usage;
    final reset = usage == null ? '' : resetDate(locale, usage, zone);
    final planPremium = usage?.plan == UsagePlan.premium || premium;
    return switch (block.kind) {
      ChatBlockKind.offline => [
        AsCard(
          tone: AsTone.quiet,
          icon: ClIcons.cloudOff,
          title: l10n.asOfflineTitle,
          body: l10n.asOfflineBody,
          children: [
            if (online && chat.kept != null)
              Align(
                alignment: Alignment.centerLeft,
                child: AsButton(
                  label: l10n.asSend,
                  loading: chat.sending,
                  onPressed: ctl.sendKept,
                ),
              ),
          ],
        ),
      ],
      ChatBlockKind.failure => [
        _failureCard(context, onRetry: chat.kept == null ? null : ctl.sendKept),
      ],
      ChatBlockKind.generic => [
        AsCard(
          tone: AsTone.errorEdge,
          body: l10n.asGenericError,
          children: [
            if (chat.kept != null)
              Align(
                alignment: Alignment.centerLeft,
                child: AsButton(label: l10n.asRetry, onPressed: ctl.sendKept),
              ),
          ],
        ),
      ],
      ChatBlockKind.consent => [_ConsentCard(ctl: ctl)],
      ChatBlockKind.exhausted => _exhausted(context, planPremium, reset),
      ChatBlockKind.photoQuote => [
        AsCard(
          tone: AsTone.warn,
          title: l10n.asPhotoQuoteTitle(
            block.quote?.credits ?? creditsFor(TaskModality.image, usage),
            block.quote?.usage?.remaining ?? chat.usageView?.remaining ?? 0,
          ),
          body: planPremium
              ? l10n.asPhotoQuotePremium(reset)
              : l10n.asPhotoQuoteFree(reset),
          children: [
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (!planPremium && upsell)
                  AsButton(
                    label: l10n.asSeePremium,
                    onPressed: () => onUpgrade(photo: true),
                  ),
                AsButton(
                  label: l10n.asTypeInstead,
                  style: AsButtonStyle.outline,
                  onPressed: onTypeInstead,
                ),
              ],
            ),
          ],
        ),
      ],
      ChatBlockKind.photoSoon => [
        AsCard(
          tone: AsTone.quiet,
          body: l10n.asPhotoSoon,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AsButton(
                label: l10n.asRemovePhoto,
                style: AsButtonStyle.outline,
                onPressed: ctl.removePhoto,
              ),
            ),
          ],
        ),
      ],
      ChatBlockKind.featureOff => [_offCard(context)],
      ChatBlockKind.region => [_regionCard(context)],
      ChatBlockKind.writeDenied => [_deniedCard(context)],
      ChatBlockKind.readDenied => [
        AsCard(
          tone: AsTone.quiet,
          icon: ClIcons.lock,
          title: viewer ? l10n.asViewerTitle : null,
          body: l10n.asReadDeniedBody,
          children: const [],
        ),
      ],
      ChatBlockKind.module => [_moduleCard(context)],
      ChatBlockKind.notMember => [
        AsCard(
          tone: AsTone.quiet,
          icon: ClIcons.lock,
          body: l10n.asNotMemberBody,
          children: const [],
        ),
      ],
    };
  }

  /// CH21 (Free) / CH24 (Premium): the composer is locked for new AI work; direct logging,
  /// health and ready drafts still work.
  List<Widget> _exhausted(
    BuildContext context,
    bool planPremium,
    String reset,
  ) {
    final l10n = AppLocalizations.of(context);
    final childScope = !chat.scope.household;
    final logs = childScope && canSaveKind(me, DraftKind.bottle);
    return [
      if (planPremium)
        AsCard(
          title: l10n.asOutTitlePremium,
          body: l10n.asOutBodyPremium(reset),
          children: [
            AsButton(
              label: l10n.asSeeUsage,
              style: AsButtonStyle.secondary,
              expand: true,
              onPressed: () => GoRouter.of(context).push(
                Uri(
                  path: Routes.assistantUsage,
                  queryParameters: {'baby': chat.scope.babyId},
                ).toString(),
              ),
            ),
          ],
        )
      else
        AsCard(
          title: l10n.asOutTitleFree,
          body: l10n.asOutBodyFree,
          children: [
            if (childScope && !viewer) ...[
              AsButton(
                label: l10n.asOpenTodayLog,
                style: AsButtonStyle.secondary,
                expand: true,
                onPressed: () => GoRouter.of(context).push(Routes.history),
              ),
              const SizedBox(height: ClSpace.s2),
            ],
            if (logs) ...[
              AsButton(
                label: l10n.asChipLogFeed,
                style: AsButtonStyle.secondary,
                expand: true,
                onPressed: () => openCareLog(context, CareType.bottle),
              ),
              const SizedBox(height: ClSpace.s2),
            ],
            if (upsell)
              AsButton(
                label: l10n.asUpgradeContinue,
                expand: true,
                onPressed: chat.kept == null || chat.kept!.resumeUsed
                    ? null
                    : () => onUpgrade(),
              ),
          ],
        ),
      if (chat.hasReadyDrafts) AsFootnote(text: l10n.asReadyStillSave),
      _healthNote(context),
    ];
  }

  Widget _failureCard(BuildContext context, {VoidCallback? onRetry}) {
    final l10n = AppLocalizations.of(context);
    return AsCard(
      tone: AsTone.errorEdge,
      title: l10n.asFailTitle,
      body: l10n.asFailBody,
      children: [
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            if (onRetry != null)
              AsButton(
                label: l10n.asRetry,
                loading: chat.sending,
                onPressed: onRetry,
              ),
            if (!viewer)
              AsButton(
                label: l10n.asLogDirectly,
                style: AsButtonStyle.secondary,
                onPressed: onLogDirectly,
              ),
          ],
        ),
      ],
    );
  }

  Widget _offCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AsCard(
      tone: AsTone.quiet,
      icon: ClIcons.lock,
      title: l10n.asOffTitle,
      body: l10n.asOffBody,
      children: const [],
    );
  }

  Widget _regionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AsCard(
      tone: AsTone.quiet,
      icon: ClIcons.globe,
      title: l10n.asRegionTitle,
      body: l10n.asRegionBody,
      children: [
        AsLink(
          label: l10n.asOpenHealth,
          onPressed: () => GoRouter.of(context).push(healthLocation(const [])),
        ),
      ],
    );
  }

  Widget _deniedCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AsCard(
      tone: AsTone.quiet,
      icon: ClIcons.lock,
      title: viewer ? l10n.asViewerTitle : l10n.asWriteDeniedTitle,
      body: viewer ? l10n.asViewerBody : l10n.asWriteDeniedBody,
      children: const [],
    );
  }

  Widget _moduleCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AsCard(
      tone: AsTone.quiet,
      icon: ClIcons.grid,
      title: l10n.asModuleTitle,
      body: l10n.asModuleBody,
      children: const [],
    );
  }

  List<Widget> _thread(BuildContext context, TaskThread t) {
    final l10n = AppLocalizations.of(context);
    final s = t.snapshot;
    final out = <Widget>[];
    final messages = s?.messages ?? const <AssistantMessage>[];
    if (!messages.any((m) => m.role == MessageRole.user) &&
        t.userText != null) {
      out.add(AsBubble(text: t.userText!, mine: true));
    }
    if (s == null) return out;
    final task = s.task;
    final open = task.state == TaskState.awaitingClarification
        ? task.clarification
        : null;
    final shown = <String>{};
    var hasText = false;
    var openShown = false;
    for (final m in messages) {
      if (m.role == MessageRole.user) {
        if (m.text.isNotEmpty) out.add(AsBubble(text: m.text, mine: true));
        continue;
      }
      for (final p in m.parts) {
        switch (p) {
          case TextPart(:final text):
            hasText = true;
            out.add(AsBubble(text: text));
          case ClarificationPart(:final clarification):
            if (open != null && clarification.id == open.id) {
              openShown = true;
              out.addAll(_clarification(context, task, open));
            } else {
              out.add(
                AsBubble(
                  text: clarification.question.of(
                    Localizations.localeOf(context).languageCode,
                  ),
                ),
              );
            }
          case DraftRefPart(:final draftId):
            final d = s.drafts.where((d) => d.id == draftId).firstOrNull;
            if (d != null && shown.add(d.id)) {
              out.add(_draft(context, t, d));
            }
          case SourceSummaryPart(:final summary):
            out.add(
              AsSummaryCard(
                summary: summary,
                zone: task.timezone ?? zone,
                now: now,
                onOpenSource: () => GoRouter.of(context).push(Routes.history),
              ),
            );
          case HealthSupportPart(:final signs):
            out.add(_health(context, signs));
          case ApprovedContentPart(:final reason):
            if (reason.isNotEmpty) out.add(AsBubble(text: reason));
          case RecipeListPart(:final caveat):
            if (caveat != null) out.add(AsBubble(text: caveat));
          case UsageNoticePart():
            break;
          case ActionResultPart():
            break;
          case UnsupportedPart():
            out.add(
              AsCard(
                tone: AsTone.quiet,
                icon: ClIcons.alert,
                body: l10n.asUnsupportedPart,
                children: const [],
              ),
            );
        }
      }
    }
    if (open != null && !openShown) {
      out.addAll(_clarification(context, task, open));
    }
    final rest = [
      for (final d in s.drafts)
        if (!shown.contains(d.id)) d,
    ];
    if (rest.isNotEmpty && !hasText && shown.isEmpty) {
      out.add(AsBubble(text: l10n.asDraftsFound(s.drafts.length)));
    }
    for (final d in rest) {
      out.add(_draft(context, t, d));
    }
    if (s.drafts.isNotEmpty) out.addAll(_batch(context, t, s.drafts));
    switch (task.state) {
      case TaskState.received ||
          TaskState.uploading ||
          TaskState.queued ||
          TaskState.processing:
        out.add(AsWorking(onCancel: () => ctl.cancelTask(task.id)));
      case TaskState.failed:
        out.add(_taskFailure(context, t));
      case TaskState.blocked:
        out.addAll(
          _exhausted(
            context,
            task.plan == UsagePlan.premium || premium,
            chat.usage == null
                ? ''
                : resetDate(
                    Localizations.localeOf(context).toLanguageTag(),
                    chat.usage!,
                    zone,
                  ),
          ),
        );
      case TaskState.canceled:
        out.add(
          Text(
            l10n.asCanceled,
            style: context.cl.text.caption.copyWith(
              color: context.cl.colors.inkMuted,
            ),
          ),
        );
      case TaskState.awaitingClarification || TaskState.ready:
        break;
    }
    return out;
  }

  Widget _taskFailure(BuildContext context, TaskThread t) {
    final l10n = AppLocalizations.of(context);
    return switch (t.snapshot?.task.error) {
      AssistantReason.writeDenied => _deniedCard(context),
      AssistantReason.readDenied => AsCard(
        tone: AsTone.quiet,
        icon: ClIcons.lock,
        title: viewer ? l10n.asViewerTitle : null,
        body: l10n.asReadDeniedBody,
        children: const [],
      ),
      AssistantReason.moduleUnavailable => _moduleCard(context),
      AssistantReason.regionUnsupported => _regionCard(context),
      AssistantReason.featureDisabled => _offCard(context),
      AssistantReason.aiUnavailable || null => _failureCard(
        context,
        onRetry: t.userText == null ? null : () => ctl.retryTask(t.taskId),
      ),
      _ => AsCard(
        tone: AsTone.errorEdge,
        body: l10n.asGenericError,
        children: const [],
      ),
    };
  }

  Widget _health(BuildContext context, List<String> signs) => Consumer(
    builder: (context, ref, _) {
      final pack = ref.watch(rhythmContentProvider).value?.health;
      final country = ref
          .watch(capabilitiesProvider(chat.scope.babyId))
          .value
          ?.country;
      final number = pack?.emergencyNumberFor(country);
      return AsHealthCard(
        number: number,
        onCall: () => onDial(number),
        onOpenHealth: () => GoRouter.of(
          context,
        ).push(healthLocation(wireList(HealthSign.values, signs))),
      );
    },
  );

  List<Widget> _clarification(
    BuildContext context,
    AssistantTask task,
    Clarification c,
  ) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final expired =
        task.clarificationExpiresAt != null &&
        !now.isBefore(task.clarificationExpiresAt!);
    final answering = chat.answering == task.id;
    return [
      AsBubble(text: c.question.of(language)),
      if (expired)
        AsFootnote(text: l10n.asClarifyExpired, icon: ClIcons.clock)
      else ...[
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final choice in c.choices)
              AsChip(
                label: choice.label.of(language),
                busy: chat.choosing == '${task.id}/${choice.id}',
                selected: chat.choosing == '${task.id}/${choice.id}',
                onPressed: chat.choosing != null
                    ? null
                    : () async {
                        final o = await ctl.answerChoice(task.id, choice);
                        onToast(o);
                      },
              ),
            if (c.allowText)
              AsChip(
                label: l10n.asClarifyOwn,
                selected: answering,
                onPressed: () =>
                    answering ? ctl.stopTypingAnswer() : onTypeAnswer(task.id),
              ),
          ],
        ),
        AsFootnote(text: l10n.asClarifyFree),
      ],
    ];
  }

  Widget _draft(BuildContext context, TaskThread t, AssistantDraft d) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final canSave = canSaveKind(me, d.kind);
    final saving = chat.saving.contains(d.id);
    final pending =
        d.state == DraftState.draft || d.state == DraftState.needsReview;
    final expired = pending && d.expiredAt(now);
    final taskZone = t.snapshot?.task.timezone ?? zone;
    final problems = pending ? draftProblems(d.payload, now) : const [];
    final notes = <String>[
      if (d.state == DraftState.failed) failureLabel(l10n, d),
      if (pending && chat.stale.contains(d.id)) l10n.asErrStale,
      if (expired) l10n.asErrExpired,
      if (pending && !expired) ...[
        if (d.state == DraftState.needsReview ||
            d.uncertainFields.isNotEmpty ||
            d.missingFields.isNotEmpty)
          l10n.asNeedsReview,
        for (final p in problems) problemLabel(l10n, p),
      ],
      if (pending && !canSave) l10n.asViewerDraftNote,
    ];
    final editable =
        d.payload is BottlePayload ||
        d.payload is BreastPayload ||
        d.payload is SleepPayload;
    final actions = <AsCardAction>[
      if (pending && canSave && !expired && !saving) ...[
        if (editable)
          (
            label: l10n.asEdit,
            onPressed: () => showDraftEditor(
              context,
              scopeKey: chat.scope.key,
              draft: d,
              babyName: babyName,
              zone: taskZone,
            ),
          ),
        (
          label: l10n.asRemove,
          onPressed: () async => onToast(await ctl.discard(d)),
        ),
      ],
      if (d.state == DraftState.saved) ...[
        if (moduleLocation(d.kind) case final module?)
          (
            label: openModuleLabel(l10n, d.kind),
            onPressed: () => GoRouter.of(context).push(module),
          ),
        if (recordLocation(d) case final record?)
          (
            label: l10n.asUndo,
            onPressed: () => GoRouter.of(context).push(record),
          ),
      ],
      if (canSaveAnyway(d) && canSave && !saving) ...[
        if (moduleLocation(d.kind) case final module?)
          (
            label: l10n.asSeeLogged,
            onPressed: () => GoRouter.of(context).push(module),
          ),
        (
          label: l10n.asSaveAnyway,
          onPressed: () async {
            final ok = await rhConfirm(
              context,
              title: l10n.asSaveAnywayTitle,
              body: l10n.asSaveAnywayBody,
              confirm: l10n.asSaveSeparately,
              cancel: l10n.asCancel,
            );
            if (ok) onToast(await ctl.saveAnyway(t.taskId, d));
          },
        ),
      ],
    ];
    return AsDraftCard(
      state: saving ? DraftState.saving : d.state,
      kind: d.kind,
      title: kindLabel(l10n, d.kind),
      line: draftLine(
        l10n,
        locale,
        d.payload,
        taskZone,
        now,
        side: (s) => switch (s) {
          'left' => l10n.sideLeft,
          'right' => l10n.sideRight,
          _ => l10n.sideBoth,
        },
      ),
      module: moduleLabel(l10n, d.kind, babyName),
      selected: pending && canSave && !expired && !saving
          ? ctl.isSelected(d)
          : null,
      onSelected: (v) => ctl.toggle(d.id, v),
      notes: notes,
      noteIsError: d.state == DraftState.failed || expired,
      actions: actions,
      stateLabelOverride: expired ? l10n.asStateExpired : null,
    );
  }

  List<Widget> _batch(
    BuildContext context,
    TaskThread t,
    List<AssistantDraft> drafts,
  ) {
    final writer = drafts.any((d) => canSaveKind(me, d.kind));
    if (!writer) return const [];
    final saved = drafts.where((d) => d.state == DraftState.saved).length;
    final failed = drafts.where((d) => d.state == DraftState.failed).length;
    final pending = drafts
        .where(
          (d) =>
              (d.state == DraftState.draft ||
                  d.state == DraftState.needsReview) &&
              !d.expiredAt(now),
        )
        .length;
    final busy = drafts.any((d) => chat.saving.contains(d.id));
    return [
      if (failed > 0)
        AsPartialBar(
          saved: saved,
          failed: failed,
          retrying: busy,
          onRetry: drafts.any(retryable)
              ? () async => onToast(await ctl.retryFailed(t.taskId))
              : null,
        ),
      if (pending > 0)
        AsBatchBar(
          count: ctl.selectedDrafts(t.taskId).length,
          saving: busy,
          onSave: () async => onToast(await ctl.confirm(t.taskId)),
          onDiscardAll: () async => onToast(await ctl.discardAll(t.taskId)),
        ),
    ];
  }
}

/// CH02: nothing asked yet. Examples only prefill the composer; nothing costs until "Gửi".
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.scope,
    required this.babyName,
    required this.images,
    required this.onExample,
    required this.onPhoto,
  });

  final AssistantScope scope;
  final String babyName;
  final bool images;
  final ValueChanged<String> onExample;
  final VoidCallback? onPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget example(ClIcons icon, String label, VoidCallback? onTap) =>
        ClPressable(
          onPressed: onTap,
          semanticLabel: label,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClIcon(icon, size: 16, color: cl.colors.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    final title = scope.household
        ? l10n.asEmptyTitleHousehold
        : images
        ? l10n.asEmptyTitle(babyName)
        : l10n.asEmptyTitleText(babyName);
    return Column(
      children: [
        const SizedBox(height: ClSpace.s4),
        const AsSparkTile(size: 54, circle: true),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: cl.text.title2.copyWith(fontSize: 20, height: 1.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.asEmptyBody,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        if (scope.household)
          example(
            ClIcons.grid,
            l10n.asExampleExpense,
            () => onExample(l10n.asExampleExpenseText),
          )
        else ...[
          example(
            ClIcons.feed,
            l10n.asExampleFeed,
            () => onExample(l10n.asExampleFeedText),
          ),
          const SizedBox(height: ClSpace.s2),
          example(
            ClIcons.journal,
            l10n.asExampleFeedsToday,
            () => onExample(l10n.asChipFeedsToday),
          ),
        ],
        if (images && onPhoto != null) ...[
          const SizedBox(height: ClSpace.s2),
          example(ClIcons.camera, l10n.asExampleReceipt, onPhoto),
          const SizedBox(height: ClSpace.s2),
          example(ClIcons.journal, l10n.asExampleNote, onPhoto),
        ],
        const SizedBox(height: ClSpace.s3),
        AsFootnote(
          icon: ClIcons.lock,
          text: images ? l10n.asPrivacyNote : l10n.asPrivacyNoteText,
        ),
      ],
    );
  }
}

/// CH26: what is sent, to whom and what is kept (P-160 / D-003 only); declining keeps the app
/// usable and sends nothing.
class _ConsentCard extends StatefulWidget {
  const _ConsentCard({required this.ctl});
  final AssistantChat ctl;

  @override
  State<_ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<_ConsentCard> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget row(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ClIcon(ClIcons.check, size: 13, color: cl.colors.mintText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(
                fontSize: 13,
                height: 1.4,
                color: cl.colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
    return AsCard(
      icon: ClIcons.lock,
      title: l10n.asConsentTitle,
      children: [
        row(l10n.asConsent1),
        row(l10n.asConsent2),
        row(l10n.asConsent3),
        row(l10n.asConsent4),
        Text(
          l10n.asConsentProvider,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.asConsentPrivate,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        AsButton(
          label: l10n.asConsentAgree,
          expand: true,
          loading: _busy,
          onPressed: () async {
            final toaster = ClToaster.of(context);
            setState(() => _busy = true);
            final ok = await widget.ctl.agreeConsent();
            if (mounted) setState(() => _busy = false);
            if (!ok) toaster.show(message: l10n.asConsentFailed, error: true);
          },
        ),
        const SizedBox(height: ClSpace.s2),
        AsButton(
          label: l10n.asConsentDecline,
          style: AsButtonStyle.secondary,
          expand: true,
          onPressed: _busy
              ? null
              : () {
                  final toaster = ClToaster.of(context);
                  final navigator = Navigator.of(context);
                  widget.ctl.declineConsent();
                  if (navigator.canPop()) navigator.pop();
                  toaster.show(message: l10n.asConsentDeclined);
                },
        ),
      ],
    );
  }
}

// ---------- CH03 history ----------

/// The chat CH03 hands back: a conversation to open, or a new one ([conversationId] null).
class HistoryPick {
  const HistoryPick(this.scope, this.conversationId);
  final AssistantScope scope;
  final String? conversationId;
}

class AssistantHistoryScreen extends ConsumerStatefulWidget {
  const AssistantHistoryScreen({this.scopeKey, super.key});
  final String? scopeKey;

  @override
  ConsumerState<AssistantHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<AssistantHistoryScreen> {
  AssistantScope? _scope;
  List<AssistantConversation>? _items;
  var _failed = false;
  final _deleting = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scope != null) return;
    _scope = AssistantScope.fromKey(widget.scopeKey);
    if (_scope == null) {
      final session = ref.read(sessionProvider);
      if (session is SessionSignedIn && session.active.isNotEmpty) {
        _scope = AssistantScope.child(session.active.first.babyId);
      }
    }
    if (_scope != null) unawaited(_load());
  }

  Future<void> _load() async {
    final scope = _scope!;
    setState(() {
      _items = null;
      _failed = false;
    });
    try {
      final page = await ref
          .read(assistantRepositoryProvider)
          .conversations(
            scope.babyId,
            locale: Localizations.localeOf(context).languageCode,
          );
      if (!mounted || _scope != scope) return;
      setState(() => _items = page.items);
    } on Object {
      if (mounted && _scope == scope) setState(() => _failed = true);
    }
  }

  Future<void> _delete(AssistantConversation c) async {
    final l10n = AppLocalizations.of(context);
    final ok = await rhConfirm(
      context,
      title: l10n.asDeleteTitle,
      body: l10n.asDeleteBody,
      confirm: l10n.asDeleteConfirm,
      cancel: l10n.asCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final toaster = ClToaster.of(context);
    setState(() => _deleting.add(c.id));
    try {
      await ref
          .read(assistantRepositoryProvider)
          .deleteConversation(
            c.id,
            locale: Localizations.localeOf(context).languageCode,
          );
      // Only now, after the server confirmed it (never "đã xoá" before).
      if (!mounted) return;
      setState(() => _items = [...?_items]..removeWhere((x) => x.id == c.id));
      final scope = c.scope ?? _scope!;
      final chat = assistantChatProvider(scope.key);
      if (ref.exists(chat)) ref.read(chat.notifier).conversationDeleted(c.id);
      toaster.show(message: l10n.asDeleted);
    } on Object {
      toaster.show(message: l10n.asDeleteFailed, error: true);
    } finally {
      if (mounted) setState(() => _deleting.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = _scope;
    final session = ref.watch(sessionProvider);
    if (scope == null || session is! SessionSignedIn) {
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    final now = ref.watch(assistantClockProvider)();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scopes = [
      for (final m in session.active) AssistantScope.child(m.babyId),
      AssistantScope.household(scope.babyId),
    ];
    final items = [
      for (final c in _items ?? const <AssistantConversation>[])
        if (c.scope == null || c.scope == scope) c,
    ];
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    String bucket(AssistantConversation c) {
      final at = (c.updatedAt ?? c.createdAt ?? now).toLocal();
      final d = DateTime(at.year, at.month, at.day);
      if (d == today) return l10n.asHistoryToday;
      if (!d.isBefore(weekStart)) return l10n.asHistoryWeek;
      return l10n.asHistoryEarlier;
    }

    final groups = <String, List<AssistantConversation>>{};
    for (final c in items) {
      groups.putIfAbsent(bucket(c), () => []).add(c);
    }
    String when(AssistantConversation c) {
      final at = (c.updatedAt ?? c.createdAt ?? now).toLocal();
      final d = DateTime(at.year, at.month, at.day);
      return d == today ? _hhmm(at) : shortDate(locale, at);
    }

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClSpace.s8,
          ),
          children: [
            Row(
              children: [
                AsRoundButton(
                  icon: ClIcons.close,
                  label: l10n.a11yClose,
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                AsButton(
                  label: l10n.asNewChat,
                  icon: ClIcons.edit,
                  onPressed: () => context.pop(HistoryPick(scope, null)),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Semantics(
              header: true,
              child: Text(l10n.asHistoryTitle, style: cl.text.title),
            ),
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final s in scopes)
                  _ScopeChip(
                    scope: s,
                    selected: s == scope,
                    onPressed: () {
                      setState(() => _scope = s);
                      unawaited(_load());
                    },
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
            if (_failed)
              AsCard(
                tone: AsTone.errorEdge,
                body: l10n.asHistoryFailed,
                width: double.infinity,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AsButton(label: l10n.asRetry, onPressed: _load),
                  ),
                ],
              )
            else if (_items == null)
              const Padding(
                padding: EdgeInsets.all(ClSpace.s6),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (items.isEmpty)
              Text(
                l10n.asHistoryEmpty,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              )
            else
              for (final MapEntry(key: label, value: list)
                  in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: ClSpace.s2),
                  child: Text(
                    label,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (final c in list)
                        _HistoryRow(
                          title: c.title ?? l10n.asHistoryUntitled,
                          subtitle: when(c),
                          household: c.scope?.household ?? scope.household,
                          deleting: _deleting.contains(c.id),
                          onOpen: () =>
                              context.pop(HistoryPick(c.scope ?? scope, c.id)),
                          onDelete: () => _delete(c),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: ClSpace.s4),
              ],
            Text(
              l10n.asHistoryFootnote,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.asHistoryPrivate,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _hhmm(DateTime local) =>
    '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

class _ScopeChip extends ConsumerWidget {
  const _ScopeChip({
    required this.scope,
    required this.selected,
    required this.onPressed,
  });
  final AssistantScope scope;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cl.colors;
    final label = scope.household
        ? AppLocalizations.of(context).asScopeHousehold
        : ref.watch(babyProvider(scope.babyId)).value?.nickname ?? '';
    return ClPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.mintDeep : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Text(
          label,
          style: context.cl.text.label.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? c.onMintDeep : c.ink,
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.household,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
  });
  final String title;
  final String subtitle;
  final bool household;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: deleting ? null : onOpen,
      semanticLabel: title,
      pressedOpacity: 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: ClIcon(
                household ? ClIcons.grid : ClIcons.spark,
                size: 15,
                color: cl.colors.inkMuted,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClPressable(
              onPressed: deleting ? null : onDelete,
              semanticLabel: l10n.asDeleteChat,
              child: deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : ClIcon(ClIcons.trash, size: 18, color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- CH19 usage ----------

class AssistantUsageScreen extends ConsumerWidget {
  const AssistantUsageScreen({this.babyId, super.key});
  final String? babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final session = ref.watch(sessionProvider);
    final baby =
        babyId ??
        (session is SessionSignedIn && session.active.isNotEmpty
            ? session.active.first.babyId
            : null);
    if (baby == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final key = (baby, locale.languageCode);
    final async = ref.watch(assistantUsageProvider(key));
    final zone =
        ref.watch(babyProvider(baby)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final usage = async.value;
    final video = ref.watch(videoQuotaProvider(baby)).value;
    final tag = locale.toLanguageTag();
    final v = usage == null ? null : UsageView.of(usage);

    Widget costRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // G04: the label wraps; the value hugs and never breaks mid-word.
          Expanded(
            child: Text(
              label,
              style: cl.text.label.copyWith(color: cl.colors.ink),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Text(
            value,
            softWrap: false,
            style: cl.text.label.copyWith(
              fontWeight: FontWeight.w600,
              color: cl.colors.ink,
            ),
          ),
        ],
      ),
    );
    BoxDecoration card([double r = 16]) => BoxDecoration(
      color: cl.colors.surface,
      borderRadius: BorderRadius.circular(r),
    );

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClSpace.s8,
          ),
          children: [
            Row(
              children: [
                AsRoundButton(
                  icon: ClIcons.close,
                  label: l10n.a11yClose,
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                if (v != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: v.premium
                          ? cl.colors.mintSoft
                          : cl.colors.surface2,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Text(
                      v.premium ? l10n.asBadgePremium : l10n.asBadgeFree,
                      style: cl.text.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: v.premium
                            ? cl.colors.mintText
                            : cl.colors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Semantics(
              header: true,
              child: Text(l10n.asUsageTitle, style: cl.text.title),
            ),
            const SizedBox(height: ClSpace.s3),
            if (async.isLoading && usage == null)
              const Padding(
                padding: EdgeInsets.all(ClSpace.s6),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (v == null)
              AsCard(
                tone: AsTone.errorEdge,
                width: double.infinity,
                body: l10n.asUsageFailed,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AsButton(
                      label: l10n.asRetry,
                      onPressed: () =>
                          ref.invalidate(assistantUsageProvider(key)),
                    ),
                  ),
                ],
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(ClSpace.s4),
                decoration: card(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: l10n.asUsageA11y(
                        v.remaining,
                        v.limit,
                        resetDate(tag, v.usage, zone),
                      ),
                      child: ExcludeSemantics(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${v.remaining} ',
                                style: cl.text.numeral.copyWith(
                                  fontSize: 40,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: l10n.asUsageOf(v.limit),
                                style: cl.text.label.copyWith(
                                  fontSize: 15,
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ClSpace.s3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                      child: LinearProgressIndicator(
                        value: v.fraction,
                        minHeight: 8,
                        backgroundColor: cl.colors.surface2,
                        color: switch (v.level) {
                          UsageLevel.ok => cl.colors.mintDeep,
                          UsageLevel.near => cl.colors.sunshine,
                          UsageLevel.out => cl.colors.error,
                        },
                      ),
                    ),
                    const SizedBox(height: ClSpace.s3),
                    Text(
                      v.premium
                          ? l10n.asUsageResetPremium(
                              resetDate(tag, v.usage, zone),
                            )
                          : l10n.asUsageResetFree(
                              resetDate(tag, v.usage, zone),
                            ),
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              Text(l10n.asCostTitle, style: cl.text.bodyStrong),
              const SizedBox(height: ClSpace.s2),
              Container(
                decoration: card(),
                child: Column(
                  children: [
                    costRow(
                      l10n.asCostText,
                      l10n.asCostCredits(v.usage.textCredits),
                    ),
                    costRow(
                      l10n.asCostPhoto,
                      l10n.asCostCredits(v.usage.imageCredits),
                    ),
                    costRow(l10n.asCostFollowUp, l10n.asCostNoExtra),
                    costRow(l10n.asCostError, l10n.asCostNotCharged),
                    costRow(l10n.asCostHealth, l10n.asCostFree),
                  ],
                ),
              ),
              if (v.usage.recent.isNotEmpty) ...[
                const SizedBox(height: ClSpace.s4),
                Text(l10n.asRecentTitle, style: cl.text.bodyStrong),
                const SizedBox(height: ClSpace.s2),
                Container(
                  decoration: card(),
                  child: Column(
                    children: [
                      for (final e in v.usage.recent)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.modality == TaskModality.image
                                          ? l10n.asRecentPhoto
                                          : l10n.asRecentText,
                                      style: cl.text.label,
                                    ),
                                    Text(
                                      l10n.asRecentMeta(
                                        e.who ?? '',
                                        e.at == null
                                            ? ''
                                            : shortDate(tag, e.at!.toLocal()),
                                        e.credits,
                                      ),
                                      style: cl.text.caption.copyWith(
                                        color: cl.colors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (video != null) ...[
                const SizedBox(height: ClSpace.s4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: card(),
                  child: Row(
                    children: [
                      ClIcon(
                        ClIcons.video,
                        size: 18,
                        color: cl.colors.inkMuted,
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.asVideoQuotaTitle,
                              style: cl.text.label.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              l10n.asVideoQuotaSub(video.left, video.limit),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: ClSpace.s4),
              if (v.premium)
                AsFootnote(text: l10n.asPremiumHousehold)
              else if (ref
                      .watch(selectedCapabilitiesProvider)
                      ?.features
                      .assistantUpsell ??
                  false)
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.asPremiumTeaser,
                        style: cl.text.label.copyWith(
                          color: cl.colors.mintText,
                        ),
                      ),
                      AsLink(
                        label: l10n.asSeePremium,
                        onPressed: () =>
                            openPaywall(context, entry: PaywallEntry.plan),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- Routes ----------

/// `/assistant?scope=child:<baby>&conversation=<cv>` (the launch as `extra`), and the history
/// and usage pages above it.
List<RouteBase> assistantRoutes() => [
  _page(
    Routes.assistant,
    (_, s) => AssistantChatScreen(
      key: ValueKey(
        '${s.uri.queryParameters['scope']}|${s.uri.queryParameters['conversation']}',
      ),
      scopeKey: s.uri.queryParameters['scope'],
      conversationId: s.uri.queryParameters['conversation'],
      launch: s.extra is AssistantLaunch ? s.extra! as AssistantLaunch : null,
    ),
  ),
  _page(
    Routes.assistantHistory,
    modal: true,
    (_, s) => AssistantHistoryScreen(scopeKey: s.uri.queryParameters['scope']),
  ),
  _page(
    Routes.assistantUsage,
    modal: true,
    (_, s) => AssistantUsageScreen(babyId: s.uri.queryParameters['baby']),
  ),
];

GoRoute _page(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  bool modal = false,
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    fullscreenDialog: modal,
    name: state.path,
    restorationId: state.pageKey.value,
    child: builder(context, state),
  ),
);
