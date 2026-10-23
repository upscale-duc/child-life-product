import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart' show SafePush, SafePushContext;
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart'
    show sharedPreferencesProvider;
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/platform/external_apps.dart' show openAppSettings;
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart' show selectedBabyIdProvider;
import '../baby/baby_repository.dart';
import '../care/care_models.dart' show CareType;
import '../care/care_repository.dart' show inBabyZone;
import '../care/care_sheets.dart' show openCareLog, showQuickLog;
import '../care/timer_models.dart' show TimerType;
import '../family/family_repository.dart' show familyMembersProvider;
import '../premium/billing_models.dart';
import '../premium/billing_repository.dart' show videoQuotaProvider;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_repository.dart'
    show capabilitiesProvider, selectedCapabilitiesProvider;
import '../rhythm/rhythm_access.dart' show FamilyAction, familyCan;
import '../rhythm/rhythm_actions.dart' show activityLocation, healthLocation;
import '../rhythm/rhythm_repository.dart'
    show rhythmContentProvider, rhythmDialerProvider;
import '../rhythm/rhythm_labels.dart' show memberLabel;
import '../rhythm/rhythm_widgets.dart' show rhConfirm;
import '../spending/spending_models.dart' show SpendingAccess;
import 'assistant_amount.dart';
import 'assistant_cards.dart';
import 'assistant_controller.dart';
import 'assistant_editor.dart';
import 'assistant_entry.dart';
import 'assistant_fix.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_read_links.dart';
import 'assistant_photos.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';
import 'assistant_time.dart';
import 'assistant_timer_card.dart';
import 'assistant_voice.dart';
import 'assistant_widgets.dart';
import '../rhythm/personalization_v2_screen.dart' show showNotebookEditor;

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
    DraftKind.timer ||
    // LUMI-01: the care logs, with the same rights as a bottle feed.
    DraftKind.pump ||
    DraftKind.diaper ||
    DraftKind.growth ||
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

class _ChatState extends ConsumerState<AssistantChatScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  IntentHint? _hint;
  String? _openedFor;

  // Scrolling: the thread is a reversed list, so offset 0 is the newest message. It opens
  // there without scrolling, holds there while Lumi answers and while the keyboard opens, and
  // an older page added above never moves what is on screen. Reading further up, a new
  // message of Lumi's shows "↓ Tin mới".
  var _atBottom = true;
  var _dragging = false;
  var _unseen = false;
  var _forceBottom = false;

  /// Closer than this to the oldest loaded entry, the page before it is loaded.
  static const _olderReach = 600.0;

  // Entrances: an entry animates the first time it is built after the thread was primed.
  final _seen = <String>{};
  var _primed = false;

  VoiceSession? _voice;

  @override
  void initState() {
    super.initState();
    _text.text = widget.launch?.prefill ?? '';
    _hint = widget.launch?.hint;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voice?.dispose();
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A call or the app going to the background ends a dictation cleanly (words kept).
    if (state != AppLifecycleState.resumed) _voice?.interrupt();
  }

  @override
  void didChangeMetrics() {
    // The keyboard opening shrinks the list: keep the newest message in view.
    if (_atBottom && !_dragging) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels < _olderReach) _loadOlder();
    final at = p.pixels < 72;
    if (at == _atBottom) return;
    _atBottom = at;
    if (at && _unseen) setState(() => _unseen = false);
  }

  void _loadOlder() {
    final key = _openedFor;
    if (key == null) return;
    final chat = ref.read(assistantChatProvider(key));
    // After a failure only "Thử lại" asks again (no loop of failing calls).
    if (!chat.hasOlder || chat.loadingOlder || chat.olderFailed) return;
    unawaited(_ctl(key).loadOlder());
  }

  void _jumpToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels > 0.5) p.jumpTo(0);
  }

  /// Glides to the newest entry (jumps from far up, or with Reduce Motion).
  Future<void> _toBottom() async {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels.abs() >= 0.5) {
      if (context.reduceMotion || p.pixels > 1600 || p.pixels < 0) {
        p.jumpTo(0);
      } else {
        await p.animateTo(
          0,
          duration: ClMotion.standard,
          curve: ClCurves.quick,
        );
      }
    }
    if (!mounted) return;
    _atBottom = true;
    if (_unseen) setState(() => _unseen = false);
  }

  void _afterBuild({required bool freshLumi}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_forceBottom || (_atBottom && !_dragging)) {
        _forceBottom = false;
        unawaited(_toBottom());
      } else if (freshLumi && !_unseen) {
        setState(() => _unseen = true);
      }
      // A thread shorter than the screen (or scrolled near its top) reads the page before it.
      final p = _scroll.position;
      if (p.hasContentDimensions &&
          p.maxScrollExtent - p.pixels < _olderReach) {
        _loadOlder();
      }
    });
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

  /// A light tick where it means "it went" (none in Night care, D-048).
  void _tick() {
    if (!context.cl.isNightCare) unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _send(String key) async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _tick();
    _text.clear();
    final hint = _hint;
    _hint = null;
    // My own message: always shown, even when reading further up.
    _forceBottom = true;
    await _ctl(key).send(text, hint: hint);
  }

  void _prefill(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focus.requestFocus();
  }

  // ---------- Voice ----------

  VoiceSession _voiceFor() => _voice ??= VoiceSession(
    dictation: ref.read(assistantDictationProvider),
    text: _text,
    onEnd: _voiceEnded,
  );

  String _uid() {
    final s = ref.read(sessionProvider);
    return s is SessionSignedIn ? s.user.uid : '';
  }

  Future<void> _mic() async {
    final v = _voiceFor();
    if (v.active) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final introKey = 'assistant.voiceIntro.${_uid()}';
    if (prefs.getBool(introKey) != true) {
      final ok = await showVoiceIntro(context);
      if (!ok || !mounted) return;
      await prefs.setBool(introKey, true);
    }
    if (!mounted) return;
    // The words go into the field while the keyboard is down, so they stay in view.
    _focus.unfocus();
    _tick();
    await v.start(Localizations.localeOf(context).languageCode);
  }

  void _voiceEnded(VoiceStop stop) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    switch (stop) {
      case VoiceStop.done:
        _tick();
      case VoiceStop.canceled:
        break;
      case VoiceStop.noSpeech:
        toaster.show(message: l10n.asVoiceNoSpeech);
      case VoiceStop.denied:
        toaster.show(
          message: l10n.asVoiceDenied,
          error: true,
          actionLabel: l10n.actionOpenSettings,
          onAction: openAppSettings,
        );
      case VoiceStop.unavailable:
        toaster.show(message: l10n.asVoiceUnavailable, error: true);
      case VoiceStop.language:
        toaster.show(message: l10n.asVoiceLanguage, error: true);
      case VoiceStop.failed:
        toaster.show(message: l10n.asVoiceFailed, error: true);
    }
    setState(() {});
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

  /// CH09: "Gửi ảnh để trợ lý đọc" (camera or library), then the photo in the thread. No cost
  /// shown (D-081). Nothing is uploaded here.
  Future<void> _choosePhoto(String key, AssistantUsage? usage) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    _focus.unfocus();
    final source = await showClSheet<PhotoSource>(
      context: context,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null || !mounted) return;
    _forceBottom = true;
    final out = await _ctl(key).pickPhoto(source, hint: _hint);
    switch (out) {
      case PhotoPick.denied:
        toaster.show(
          message: source == PhotoSource.camera
              ? l10n.avatarCameraDenied
              : l10n.avatarLibraryDenied,
          actionLabel: l10n.actionOpenSettings,
          onAction: openAppSettings,
        );
      case PhotoPick.failed:
        toaster.show(message: l10n.asPhotoPickFailed, error: true);
      default:
        break;
    }
  }

  /// CH14 "Chụp lại" / CH25 "Thử lại" on a photo task.
  Future<void> _retakePhoto(
    String key,
    String taskId,
    AssistantUsage? u,
  ) async {
    if (!await _ctl(key).retryPhoto(taskId) && mounted) {
      await _choosePhoto(key, u);
    }
  }

  // D-076 nav: the chat is above the tabs; Chi tiêu, Lịch sử and reminders are tab pages, so
  // every link from here to them goes through `pushSafe`: it opens on top of the chat (its
  // overlay twin) and Back comes back to the conversation.
  void _logDirectly(AssistantScope scope) => scope.household
      ? context.pushSafe(Routes.spending)
      : showQuickLog(context);

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
    _focus.unfocus();
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
    _focus.unfocus();
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

  /// "Khác…" on a question that asks for a clock time: a picker that starts from what is
  /// already known (a said duration previews the computed other end), then the time goes as the
  /// answer (still the same task, 0 credits).
  Future<void> _answerWithTime(
    AssistantChat ctl,
    TaskThread t,
    Clarification c,
    String zone,
  ) async {
    _focus.unfocus();
    final now = ref.read(assistantClockProvider)();
    // What is known, best first: the server's own hint, a sleep draft's said length, the words.
    final drafted = [
      for (final d in t.snapshot?.drafts ?? const <AssistantDraft>[])
        if (d.payload case SleepPayload(:final durationMin?)) durationMin,
    ].firstOrNull;
    final known =
        c.knownMinutes ?? drafted ?? spokenDurationMinutes(t.userText ?? '');
    final picked = await pickClarifyTime(
      context,
      zone: zone,
      now: now,
      knownMinutes: known,
      end: isEndField(c.field),
      initial: c.knownAt,
    );
    if (picked == null || !mounted) return;
    _forceBottom = true;
    _toast(await ctl.answerText(t.taskId, picked));
  }

  List<AsSuggestion> _suggestions(
    AppLocalizations l10n,
    AssistantScope scope, {
    required bool viewer,
    required VoidCallback? onPhoto,
  }) => [
    if (scope.household) ...[
      if (!viewer)
        (
          label: l10n.asChipExpense,
          icon: ClIcons.grid,
          onPressed: () => _prefill(l10n.asPrefillExpense),
        ),
    ] else ...[
      if (!viewer) ...[
        (
          label: l10n.pv2Notes,
          icon: ClIcons.journal,
          onPressed: () {
            final me = _membership(ref, scope.babyId);
            if (me == null) return;
            final text = _text.text.trim();
            showNotebookEditor(
              context,
              ref,
              (
                babyId: scope.babyId,
                uid: me.uid,
                locale: Localizations.localeOf(context).languageCode,
              ),
              me.role == MemberRole.coParent,
              note: text.isEmpty
                  ? null
                  : {
                      'text': text.length > 200 ? text.substring(0, 200) : text,
                      'scope': 'baby',
                      'source': 'lumi',
                    },
            );
          },
        ),
        (
          label: l10n.asChipLogFeed,
          icon: ClIcons.feed,
          onPressed: () => _prefill(l10n.asPrefillFeed),
        ),
        (
          label: l10n.asChipLogSleep,
          icon: ClIcons.sleep,
          onPressed: () => _prefill(l10n.asPrefillSleep),
        ),
      ],
      (
        label: l10n.asChipFeedsShort,
        icon: ClIcons.journal,
        onPressed: () => _prefill(l10n.asChipFeedsToday),
      ),
    ],
    if (onPhoto != null)
      (label: l10n.asChipReceipt, icon: ClIcons.camera, onPressed: onPhoto),
  ];

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
    final session = ref.watch(sessionProvider);
    // L1 (P-167 #3): while my own latest task waits on a question, typing answers it.
    final answeringAbove =
        chat.answering != null ||
        chat.openQuestionFor(
              session is SessionSignedIn ? session.user.uid : null,
              now,
            ) !=
            null;
    final hint = answeringAbove
        ? l10n.asComposerAnswer
        : switch (mode) {
            ComposerMode.viewer => l10n.asComposerViewer,
            ComposerMode.out =>
              premium ? l10n.asComposerOutPremium : l10n.asComposerOutFree,
            ComposerMode.open =>
              images ? l10n.asComposerHint : l10n.asComposerHintText,
          };
    final babyName = baby?.nickname ?? '';
    final onPhoto = images && !viewer
        ? () => _choosePhoto(key, chat.usage)
        : null;
    final view = _ThreadView(
      myUid: session is SessionSignedIn ? session.user.uid : null,
      members:
          ref.watch(familyMembersProvider(scope.babyId)).value ??
          const <Membership>[],
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
      onTimeAnswer: (t, c) => _answerWithTime(ctl, t, c, zone),
      onChoosePhoto: onPhoto,
      onRetake: images && !viewer
          ? (taskId) => _retakePhoto(key, taskId, chat.usage)
          : null,
      onTypeIn: () => _focus.requestFocus(),
    );
    final entries = <_Entry>[
      if (chat.empty)
        _Entry(
          'empty',
          _Side.note,
          _EmptyState(
            scope: scope,
            babyName: babyName,
            images: images,
            onExample: _prefill,
            onPhoto: onPhoto,
          ),
        ),
      if (chat.loadingOlder || chat.olderFailed)
        _Entry('older', _Side.note, _OlderRow(chat: chat, ctl: ctl)),
      ...view.entries(context),
    ];
    // Entrances: nothing animates while a thread is being restored or right after it opened
    // (history appears at once); afterwards each new entry arrives with its own motion.
    if (chat.restoring || !_primed) {
      _primed = !chat.restoring;
      _seen.addAll(entries.map((e) => e.key));
    }
    // An older page lands above what was there: history too, so it appears at once.
    final firstSeen = entries.indexWhere(
      (e) => e.key != 'older' && _seen.contains(e.key),
    );
    if (firstSeen > 0) _seen.addAll(entries.take(firstSeen).map((e) => e.key));
    final fresh = {
      for (final e in entries)
        if (!_seen.contains(e.key)) e.key,
    };
    _seen.addAll(fresh);
    _afterBuild(
      freshLumi: entries.any(
        (e) => fresh.contains(e.key) && e.side != _Side.me,
      ),
    );
    // Newest first for the reversed list.
    final items = _layout(entries, fresh).reversed.toList();
    final index = {for (final (i, e) in items.indexed) e.key: i};
    final voiceOk = mode == ComposerMode.open && chat.answering == null;
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
                ClSpace.s2,
              ),
              child: AsChatHeader(
                // The baby's name (her age is in the scope sheet); "Gia đình" for the family.
                scopeLabel: scope.household || babyName.isEmpty
                    ? scopeLabel(context, ref, scope, me)
                    : babyName,
                household: scope.household,
                privateHint: scope.household,
                onBack: () =>
                    context.canPop() ? context.pop() : context.go(Routes.today),
                onScope: () => _pickScope(scope),
                onHistory: () => _history(scope),
                onNew: () {
                  _seen.clear();
                  _primed = false;
                  ctl.newConversation();
                },
                // D-076 #12: no credits pill here; the numbers are in CH19 and in the quote
                // shown before a task that costs any.
                onUsage: () => context.push(
                  Uri(
                    path: Routes.assistantUsage,
                    queryParameters: {'baby': scope.babyId},
                  ).toString(),
                ),
              ),
            ),
            AsSize(
              duration: context.motion(ClMotion.quick),
              curve: ClCurves.quick,
              child: online
                  ? const SizedBox(width: double.infinity)
                  : const Padding(
                      padding: EdgeInsets.fromLTRB(
                        ClSpace.s4,
                        0,
                        ClSpace.s4,
                        ClSpace.s2,
                      ),
                      child: AsOfflineBanner(),
                    ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Owner, 2026-10-22: a thread being restored is Lumi breathing in the middle,
                  // then the whole conversation at once (no header first, then a jump).
                  if (chat.restoring)
                    const Positioned.fill(child: Center(child: _LumiLoading()))
                  else
                    NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollStartNotification) {
                          _dragging = n.dragDetails != null;
                          // Dragging the thread puts the keyboard away (also when the thread
                          // is too short to scroll).
                          if (_dragging) FocusScope.of(context).unfocus();
                        } else if (n is ScrollEndNotification) {
                          _dragging = false;
                        }
                        return false;
                      },
                      child: GestureDetector(
                        // A tap on the thread (outside a control) puts the keyboard away.
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusScope.of(context).unfocus(),
                        // Reversed (the newest at offset 0) and shrink-wrapped to the top, so a
                        // short thread still reads from the top of the screen.
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ListView.builder(
                            key: const ValueKey('as.thread'),
                            controller: _scroll,
                            reverse: true,
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                              ClSpace.s4,
                              ClSpace.s2,
                              ClSpace.s4,
                              ClSpace.s4,
                            ),
                            itemCount: items.length,
                            findChildIndexCallback: (k) =>
                                k is ValueKey<String> ? index[k.value] : null,
                            itemBuilder: (_, i) => items[i].widget,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: ClSpace.s2,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: context.motion(ClMotion.quick),
                        child: _unseen
                            ? AsNewPill(onPressed: () => unawaited(_toBottom()))
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
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
                  ? () => _choosePhoto(key, chat.usage)
                  : null,
              voice: voiceOk || (_voice?.active ?? false) ? _voiceFor() : null,
              onMic: voiceOk ? _mic : null,
              suggestions: chat.empty || chat.answering != null
                  ? const []
                  : _suggestions(l10n, scope, viewer: viewer, onPhoto: onPhoto),
            ),
          ],
        ),
      ),
    );
  }

  /// Runs of the same speaker sit close; Lumi's face and name head each run of hers; my own
  /// bubble rises from the right; a new entry of Lumi's is read out once.
  List<({String key, Widget widget})> _layout(
    List<_Entry> entries,
    Set<String> fresh,
  ) {
    final out = <({String key, Widget widget})>[];
    _Side? previous;
    var stagger = 0;
    for (final (i, e) in entries.indexed) {
      final runStart =
          e.side != _Side.note && e.side != previous && e.side != _Side.typing;
      final header = e.side == _Side.lumi && previous != _Side.lumi;
      final gap = i == 0
          ? 0.0
          : (e.side == _Side.note || !runStart ? 6.0 : 16.0);
      if (e.side != _Side.note) previous = e.side;
      final animate = fresh.contains(e.key);
      Widget child = e.child;
      if (header) {
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [const AsLumiHeader(), e.child],
        );
      }
      if (animate && e.side != _Side.me && e.side != _Side.typing) {
        child = Semantics(liveRegion: true, container: true, child: child);
      }
      out.add((
        key: e.key,
        widget: Padding(
          key: ValueKey(e.key),
          padding: EdgeInsets.only(top: gap),
          child: RepaintBoundary(
            child: AsEnter(
              animate: animate,
              delay: animate ? staggerDelay(stagger++) : Duration.zero,
              fromRight: e.side == _Side.me,
              child: child,
            ),
          ),
        ),
      ));
    }
    return out;
  }
}

/// Who an entry of the thread speaks for (runs, Lumi's header, entrances).
enum _Side { me, lumi, other, note, typing }

/// One keyed entry of the thread: the key stays the same while the entry is on screen, so an
/// update re-renders it in place and only a new key animates in.
/// Lumi gently breathing while a conversation opens.
class _LumiLoading extends StatefulWidget {
  const _LumiLoading();

  @override
  State<_LumiLoading> createState() => _LumiLoadingState();
}

class _LumiLoadingState extends State<_LumiLoading>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Still in Reduce Motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).aiLoading,
    liveRegion: true,
    child: ScaleTransition(
      scale: Tween(
        begin: 0.92,
        end: 1.06,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: const LumiMascot(size: 72),
    ),
  );
}

class _Entry {
  const _Entry(this.key, this.side, this.child);
  final String key;
  final _Side side;
  final Widget child;
}

/// Builds the thread: each task (its messages, drafts and state), then the kept input and the
/// notice that explains it.
class _ThreadView {
  _ThreadView({
    required this.myUid,
    required this.members,
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
    required this.onTimeAnswer,
    required this.onChoosePhoto,
    required this.onRetake,
    required this.onTypeIn,
  });

  /// A chat can be scoped to a different baby from the Home tab (CH03).
  void _openRead(BuildContext context, String babyId, String link) {
    final route = assistantReadRoute(link);
    if (route == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(sessionProvider);
    if (session is! SessionSignedIn || session.membershipFor(babyId) == null) {
      return;
    }
    container.read(selectedBabyIdProvider.notifier).select(babyId);
    GoRouter.of(context).pushSafe(route);
  }

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

  /// "Khác…" on a question that asks for a clock time: the linked time picker.
  final void Function(TaskThread thread, Clarification c) onTimeAnswer;

  /// CH09 sheet (null: photo reading off, or a viewer).
  final VoidCallback? onChoosePhoto;
  final void Function(String taskId)? onRetake;

  /// "Nhập tay": the composer, the photo flow left as it is.
  final VoidCallback onTypeIn;

  /// Who is reading (D-075 #2: authors, author-only actions).
  final String? myUid;

  /// The baby's members (reminder assignees, D-075 #5).
  final List<Membership> members;

  /// A shared-thread reader (Cùng nuôi / Người chăm sóc) in a child chat.
  bool get _sharedReader =>
      !chat.scope.household &&
      (me?.role == MemberRole.coParent || me?.role == MemberRole.caregiver);

  /// Another member's name for a message or a saved draft; null when it is me / unknown.
  String? _other(BuildContext context, AssistantAuthor? a) =>
      a == null || a.uid == myUid
      ? null
      : authorName(AppLocalizations.of(context), a, myUid: myUid);

  /// Only one "Lumi đang soạn…" keeps the stable key (it moves without a second entrance).
  var _typingKeyUsed = false;

  _Entry _typing(
    BuildContext context,
    String id,
    String label, {
    VoidCallback? onCancel,
  }) {
    final key = _typingKeyUsed ? 'typing:$id' : 'typing';
    _typingKeyUsed = true;
    return _Entry(
      key,
      _Side.typing,
      AsTyping(label: label, onCancel: onCancel),
    );
  }

  /// [widgets] as entries `<prefix>#<i>` (a card group that stays together).
  List<_Entry> _many(String prefix, _Side side, List<Widget> widgets) => [
    for (final (i, w) in widgets.indexed)
      // An empty slot keeps the keys after it stable without taking room.
      if (!(w is SizedBox && w.width == 0 && w.height == 0 && w.child == null))
        _Entry(
          '$prefix#$i',
          w is AsFootnote || w is AsDayDivider ? _Side.note : side,
          w,
        ),
  ];

  String? _time(DateTime? at) => at == null ? null : hm(at, zone);

  /// A pause this long (or a new day) since the task before puts the time above the next one.
  static const _pause = Duration(minutes: 10);

  /// When the last task so far ended (its last message).
  DateTime? _lastAt;

  /// "Hôm nay · 14:20" above what was said at [at]: the first of the thread, after a pause, or
  /// on another day than the task before. Keyed after the task's first entry, so the line my
  /// unsent words had stays put when they become the task.
  _Entry? _when(BuildContext context, String firstKey, DateTime? at) {
    if (at == null) return null;
    final before = _lastAt;
    if (before != null && at.difference(before) < _pause) {
      final a = inBabyZone(zone, before);
      final b = inBabyZone(zone, at);
      if (a.year == b.year && a.month == b.month && a.day == b.day) return null;
    }
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return _Entry(
      '$firstKey:when',
      _Side.note,
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: AsDayDivider(
          label: l10n.asThreadWhen(
            relativeDay(l10n, locale, at, zone, now),
            hm(at, zone),
          ),
        ),
      ),
    );
  }

  static DateTime? _startOf(TaskThread t) =>
      t.snapshot?.task.createdAt ??
      t.snapshot?.messages.map((m) => m.createdAt).nonNulls.firstOrNull;

  static DateTime? _endOf(TaskThread t) {
    DateTime? last;
    for (final m in t.snapshot?.messages ?? const <AssistantMessage>[]) {
      if (m.createdAt case final at? when last == null || at.isAfter(last)) {
        last = at;
      }
    }
    return last ?? _startOf(t);
  }

  List<_Entry> entries(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _typingKeyUsed = false;
    _lastAt = null;
    final out = <_Entry>[];
    if (chat.loadFailed) {
      out.add(
        _Entry(
          'loadFailed',
          _Side.lumi,
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
        ),
      );
    }
    for (final (i, t) in chat.threads.indexed) {
      if (chat.resumed && i == chat.threads.length - 1) {
        out.add(_Entry('resumed', _Side.note, _resumedBanner(context)));
      }
      final first = t.requestId == null
          ? 't:${t.taskId}:u0'
          : 'u:${t.requestId}';
      if (_when(context, first, _startOf(t)) case final line?) out.add(line);
      out.addAll(_threadEntries(context, t));
      _lastAt = _endOf(t) ?? _lastAt;
    }
    if (chat.restoring && chat.threads.every((t) => t.snapshot == null)) {
      out.add(_typing(context, 'restore', l10n.asLoadingChat));
    }
    if (chat.kept case final kept?) {
      final block = chat.block?.kind;
      final failed =
          block == ChatBlockKind.failure || block == ChatBlockKind.generic;
      final offline = block == ChatBlockKind.offline;
      if (_when(context, 'u:${kept.requestId}', kept.at) case final line?) {
        out.add(line);
      }
      out.add(
        _Entry(
          'u:${kept.requestId}',
          _Side.me,
          AsBubble(
            text: kept.text,
            mine: true,
            time: _time(kept.at),
            sendState: chat.sending
                ? AsSendState.sending
                : (failed ? AsSendState.failed : AsSendState.unsent),
            status: chat.sending
                ? l10n.asSending
                : failed
                ? l10n.asNotSent
                : offline
                ? l10n.asUnsentOffline
                : l10n.asUnsent,
            statusIcon: chat.sending
                ? ClIcons.clock
                : (failed ? ClIcons.alert : ClIcons.cloudOff),
            action: chat.sending
                ? null
                : failed
                ? (label: l10n.asResend, onPressed: ctl.sendKept)
                : offline && online
                ? (label: l10n.asSend, onPressed: ctl.sendKept)
                : null,
          ),
        ),
      );
      // "Lumi đang soạn…" only once the words have gone: the task's own state then shows it.
    }
    if (chat.photo case final photo?) {
      out.addAll(
        _many(
          'photo:${photo.requestId}',
          _Side.me,
          _pendingPhoto(context, photo),
        ),
      );
    }
    if (chat.block case final block?) {
      out.addAll(
        _many(
          'block:${block.kind.name}',
          _Side.lumi,
          _blockCards(context, block),
        ),
      );
    }
    return out;
  }

  /// One task: my words (and photos), Lumi's parts in order, its drafts with the batch bar,
  /// then where it stands (typing, failed, used up, cancelled) and the privacy notes.
  List<_Entry> _threadEntries(BuildContext context, TaskThread t) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final s = t.snapshot;
    final out = <_Entry>[];
    final id = t.taskId;
    final firstKey = t.requestId == null ? 't:$id:u0' : 'u:${t.requestId}';
    final messages = s?.messages ?? const <AssistantMessage>[];
    final userShown = messages.any((m) => m.role == MessageRole.user);
    if (!userShown) {
      for (final a in t.photoIds) {
        out.add(
          _Entry(
            't:$id:p:$a',
            _Side.me,
            _photoBubble(context, s?.task, a, s?.attachments),
          ),
        );
      }
      if (t.userText != null) {
        out.add(
          _Entry(
            firstKey,
            _Side.me,
            AsBubble(
              text: t.userText!,
              mine: true,
              time: _time(s?.task.createdAt),
            ),
          ),
        );
      }
    }
    if (s == null) return out;
    final task = s.task;
    final open = task.state == TaskState.awaitingClarification
        ? task.clarification
        : null;
    final pending =
        chat.pendingAnswer?.taskId == id &&
            t.userMessages <= chat.pendingAnswer!.after
        ? chat.pendingAnswer
        : null;
    final shown = <String>{};
    var hasText = false;
    var openShown = false;
    var users = 0;
    for (final m in messages) {
      if (m.role == MessageRole.user) {
        for (final a in m.attachmentIds) {
          out.add(
            _Entry(
              't:$id:p:$a',
              _Side.me,
              _photoBubble(context, task, a, s.attachments),
            ),
          );
        }
        if (m.text.isNotEmpty) {
          final other = _other(context, m.author ?? task.author);
          out.add(
            _Entry(
              users == 0 ? firstKey : 't:$id:u$users',
              other == null ? _Side.me : _Side.other,
              AsBubble(
                text: m.text,
                mine: other == null,
                author: other,
                time: _time(m.createdAt),
              ),
            ),
          );
        }
        users++;
        continue;
      }
      for (final (pi, p) in m.parts.indexed) {
        final k = 't:$id:m${m.sequence}:$pi';
        switch (p) {
          case TextPart(text: final raw, :final code, :final link):
            if (task.state == TaskState.failed && isOldFailureLine(raw)) {
              break;
            }
            hasText = true;
            final text = withoutCreditNote(raw);
            final w = _notice(context, text, code, link: link);
            out.add(
              _Entry(
                k,
                _Side.lumi,
                w is AsBubble
                    ? AsBubble(text: text, time: _time(m.createdAt))
                    : w,
              ),
            );
          case ClarificationPart(:final clarification):
            out.add(
              _Entry(
                k,
                _Side.lumi,
                AsBubble(
                  text: clarification.question.of(language),
                  time: _time(m.createdAt),
                ),
              ),
            );
            if (open != null && clarification.id == open.id) {
              openShown = true;
              out.addAll(
                _many(
                  '$k:ask',
                  _Side.lumi,
                  _clarification(context, t, task, open, questionShown: true),
                ),
              );
            }
          case DraftRefPart(:final draftId):
            final d = s.drafts.where((d) => d.id == draftId).firstOrNull;
            if (d != null && shown.add(d.id)) {
              out.add(_Entry('d:${d.id}', _Side.lumi, _draft(context, t, d)));
            }
          case ReadCardPart():
            out.add(
              _Entry(
                k,
                _Side.lumi,
                AsReadCard(
                  part: p,
                  zone: task.timezone ?? zone,
                  onOpen: (link) {
                    _openRead(
                      context,
                      task.scope?.babyId ?? chat.scope.babyId,
                      link,
                    );
                  },
                ),
              ),
            );
          case SourceSummaryPart():
            out.add(
              _Entry(
                k,
                _Side.lumi,
                _SourceSummary(
                  part: p,
                  babyId: task.scope?.babyId ?? chat.scope.babyId,
                  zone: task.timezone ?? zone,
                  now: now,
                  onOpenSource: () =>
                      GoRouter.of(context).pushSafe(Routes.history),
                ),
              ),
            );
          case HealthSupportPart(:final signs, :final emergency):
            out.add(
              _Entry(k, _Side.lumi, _health(context, signs, emergency?.number)),
            );
          case ApprovedContentPart():
            out.addAll(_many(k, _Side.lumi, _guidance(context, t, p)));
          case RecipeListPart(:final items):
            if (items.isNotEmpty) {
              out.add(
                _Entry(
                  k,
                  _Side.lumi,
                  AsRecipeCard(
                    items: items,
                    excludedCount: p.excludedCount,
                    caveat: p.caveat,
                    mealLogAvailable: p.mealLogAvailable,
                    onOpen: (link) => _openRead(
                      context,
                      task.scope?.babyId ?? chat.scope.babyId,
                      link,
                    ),
                  ),
                ),
              );
            } else if (p.caveat case final caveat?) {
              out.add(_Entry(k, _Side.lumi, AsBubble(text: caveat)));
            }
          case UsageNoticePart():
            break;
          case ActionResultPart(:final items):
            // D-075 #2: another member saved from the shared thread.
            final saved = items
                .where((i) => i.status == ConfirmStatus.saved)
                .length;
            if (_other(context, m.author) case final who? when saved > 0) {
              out.add(
                _Entry(
                  k,
                  _Side.note,
                  AsDayDivider(label: l10n.asSavedBy(who, saved)),
                ),
              );
            }
          case UnsupportedPart():
            out.add(
              _Entry(
                k,
                _Side.lumi,
                AsCard(
                  tone: AsTone.quiet,
                  icon: ClIcons.alert,
                  body: l10n.asUnsupportedPart,
                  children: const [],
                ),
              ),
            );
        }
      }
    }
    if (open != null && !openShown) {
      out.addAll(
        _many('t:$id:ask', _Side.lumi, _clarification(context, t, task, open)),
      );
    }
    if (pending != null) {
      out.add(
        _Entry(
          users == 0 ? firstKey : 't:$id:u$users',
          _Side.me,
          AsBubble(
            text: pending.text,
            mine: true,
            sendState: AsSendState.sending,
          ),
        ),
      );
    }
    final rest = [
      for (final d in s.drafts)
        if (!shown.contains(d.id)) d,
    ];
    if (rest.isNotEmpty && !hasText && shown.isEmpty) {
      out.add(
        _Entry(
          't:$id:found',
          _Side.lumi,
          AsBubble(text: l10n.asDraftsFound(s.drafts.length)),
        ),
      );
    }
    for (final d in rest) {
      out.add(_Entry('d:${d.id}', _Side.lumi, _draft(context, t, d)));
    }
    if (s.drafts.isNotEmpty) {
      out.addAll(
        _many('t:$id:batch', _Side.lumi, _batch(context, t, s.drafts)),
      );
    }
    if (task.care != null) {
      out.addAll(
        _many('t:$id:fu', _Side.lumi, _followUp(context, t, task.care!)),
      );
    }
    switch (task.state) {
      case TaskState.received ||
          TaskState.uploading ||
          TaskState.queued ||
          TaskState.processing:
        out.add(
          _typing(
            context,
            id,
            t.photo ? l10n.asReadingPhoto : l10n.asThinking,
            // Cancel stays with the task's author (D-075 #2).
            onCancel: task.authoredBy(myUid)
                ? () => ctl.cancelTask(task.id)
                : null,
          ),
        );
        if (t.photo) {
          out.add(
            _Entry(
              't:$id:leave',
              _Side.note,
              AsFootnote(text: l10n.asPhotoLeaveScreen),
            ),
          );
        }
      case TaskState.failed:
        out.addAll(_many('t:$id:fail', _Side.lumi, _taskFailure(context, t)));
      case TaskState.blocked:
        out.addAll(
          _many(
            't:$id:out',
            _Side.lumi,
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
          ),
        );
      case TaskState.canceled:
        out.add(
          _Entry(
            't:$id:canceled',
            _Side.note,
            Text(
              l10n.asCanceled,
              style: context.cl.text.caption.copyWith(
                color: context.cl.colors.inkMuted,
              ),
            ),
          ),
        );
      case TaskState.awaitingClarification || TaskState.ready:
        // An answer on its way shows as my bubble "Đang gửi…"; Lumi types once it arrived.
        break;
    }
    if (t.photo && !task.state.working) {
      final forExpense =
          task.state == TaskState.awaitingClarification ||
          s.drafts.any((d) => d.kind == DraftKind.expense);
      if (_retention(context, s.attachments, forExpense) case final note?) {
        out.add(_Entry('t:$id:retention', _Side.note, note));
      }
    }
    // Rework 2026-10-15: words about money stay in my private thread, said once.
    if (task.routedForSpending && !t.photo) {
      out.add(
        _Entry(
          't:$id:routed',
          _Side.note,
          AsFootnote(icon: ClIcons.lock, text: l10n.asSpendingMoved),
        ),
      );
    }
    // D-075 #2: photos and spending never enter the baby's shared thread.
    if (t.photo && _sharedReader && task.visibility == TaskVisibility.private) {
      out.add(
        _Entry(
          't:$id:private',
          _Side.note,
          AsFootnote(icon: ClIcons.lock, text: l10n.asPrivateTask),
        ),
      );
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

  /// The chosen photo before its task exists: CH09 (quote + retention), CH10 uploading, or
  /// held (CH20 and the other notices explain why; the selection stays).
  List<Widget> _pendingPhoto(BuildContext context, PendingPhoto photo) {
    final l10n = AppLocalizations.of(context);
    final quote = photo.quote;
    return switch (photo.stage) {
      PhotoStage.quoting => [
        AsPhotoBubble(
          bytes: photo.bytes,
          dimmed: true,
          icon: ClIcons.spark,
          label: l10n.asPhotoQuoting,
        ),
      ],
      PhotoStage.ready when quote != null => [
        AsPhotoBubble(
          bytes: photo.bytes,
          icon: ClIcons.camera,
          label: l10n.asPhotoNotSent,
        ),
        AsPhotoReadyCard(
          bytes: photo.bytes,
          keep: photo.keep,
          canceled: photo.canceled,
          onKeep: ctl.setKeepPhoto,
          onSend: online ? () async => onToast(await ctl.sendPhoto()) : null,
          onRemove: ctl.removePhoto,
        ),
      ],
      PhotoStage.uploading => [
        AsPhotoBubble(
          bytes: photo.bytes,
          dimmed: true,
          icon: ClIcons.upload,
          progress: photo.progress,
          label: l10n.asUploading((photo.progress * 100).round()),
          onCancel: ctl.cancelUpload,
          cancelLabel: l10n.asCancelUpload,
        ),
      ],
      PhotoStage.starting => [
        AsPhotoBubble(
          bytes: photo.bytes,
          dimmed: true,
          icon: ClIcons.upload,
          progress: 1,
          label: l10n.asSending,
        ),
      ],
      _ => [
        AsPhotoBubble(
          bytes: photo.bytes,
          icon: ClIcons.camera,
          label: l10n.asPhotoNotSent,
        ),
      ],
    };
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
      // The banner and my bubble's own "Chưa gửi · Gửi" say it (CH25).
      ChatBlockKind.offline => const <Widget>[],
      ChatBlockKind.failure => [
        _failureCard(context, onRetry: chat.kept == null ? null : ctl.sendKept),
      ],
      ChatBlockKind.generic => [
        _failureCard(context, onRetry: chat.kept == null ? null : ctl.sendKept),
      ],
      ChatBlockKind.consent => [_ConsentCard(ctl: ctl)],
      ChatBlockKind.exhausted => _exhausted(context, planPremium, reset),
      ChatBlockKind.photoQuote => [
        AsCard(
          tone: AsTone.warn,
          title: l10n.asPhotoQuoteTitle(
            block.quote?.credits ?? creditsFor(TaskModality.image, usage),
            chat.usageView?.remaining ?? block.quote?.usage?.remaining ?? 0,
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
      ChatBlockKind.photoFailed => [
        AsCard(
          tone: AsTone.errorEdge,
          title: l10n.asFailTitle,
          body: l10n.asPhotoFailBody,
          children: [
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (chat.photo != null)
                  AsButton(
                    label: l10n.asRetry,
                    onPressed: online
                        ? () async {
                            final q = chat.photo?.quote;
                            if (q != null && q.allowed) {
                              onToast(await ctl.sendPhoto());
                            } else {
                              await ctl.pickPhotoAgain();
                            }
                          }
                        : null,
                  ),
                AsButton(
                  label: l10n.asRemovePhoto,
                  style: AsButtonStyle.secondary,
                  onPressed: ctl.removePhoto,
                ),
              ],
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
                onPressed: () => GoRouter.of(context).pushSafe(Routes.history),
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
      _healthNote(context),
    ];
  }

  /// CH25 as Lumi says it: no blame, nothing saved, nothing charged; "Thử lại" and "Ghi trực
  /// tiếp" right under it.
  Widget _failureCard(BuildContext context, {VoidCallback? onRetry}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AsBubble(text: l10n.asErrorFriendly),
        const SizedBox(height: 8),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            if (onRetry != null)
              AsChip(
                label: l10n.asRetry,
                icon: ClIcons.retry,
                busy: chat.sending,
                onPressed: onRetry,
              ),
            if (!viewer)
              AsChip(label: l10n.asLogDirectly, onPressed: onLogDirectly),
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

  /// Chat/Tệp đính kèm for one photo of a task (this phone's copy, else a placeholder).
  Widget _photoBubble(
    BuildContext context,
    AssistantTask? task,
    String attachmentId,
    List<AttachmentView>? attachments,
  ) {
    final l10n = AppLocalizations.of(context);
    final a = attachments?.where((x) => x.id == attachmentId).firstOrNull;
    final status = task == null ? PhotoStatus.reading : photoStatus(task, a);
    final bytes = ctl.photoBytes(attachmentId);
    return switch (status) {
      PhotoStatus.reading => AsPhotoBubble(
        bytes: bytes,
        dimmed: true,
        icon: ClIcons.spark,
        progress: null,
        label: l10n.asPhotoReading,
      ),
      PhotoStatus.read => AsPhotoBubble(
        bytes: bytes,
        icon: ClIcons.check,
        tone: AsPhotoTone.done,
        label: l10n.asPhotoRead,
      ),
      PhotoStatus.blurry => AsPhotoBubble(
        bytes: bytes,
        blurred: true,
        icon: ClIcons.alert,
        tone: AsPhotoTone.error,
        label: l10n.asPhotoBlurry,
      ),
      PhotoStatus.refused => AsPhotoBubble(
        bytes: bytes,
        icon: ClIcons.alert,
        tone: AsPhotoTone.error,
        label: l10n.asPhotoRefused,
      ),
      PhotoStatus.canceled => AsPhotoBubble(
        bytes: bytes,
        icon: ClIcons.close,
        label: l10n.asPhotoCanceled,
      ),
    };
  }

  /// G05: the photo's real retention, from the server's confirmed state only.
  Widget? _retention(
    BuildContext context,
    List<AttachmentView> photos,
    bool forExpense,
  ) {
    final l10n = AppLocalizations.of(context);
    final line = retentionLine(photos, forExpense: forExpense);
    if (line == null) return null;
    return AsFootnote(
      icon: ClIcons.lock,
      text: switch (line) {
        RetentionLine.keptWithExpense => l10n.asRetentionKept,
        RetentionLine.keptIfSaved => l10n.asRetentionKeptIfSaved,
        RetentionLine.deleting => l10n.asRetentionDeleting,
        RetentionLine.deleted => l10n.asRetentionDeleted,
        RetentionLine.willDelete => l10n.asRetentionWillDelete,
      },
    );
  }

  /// A server text; a coded notice gets its action (care library, health, region).
  Widget _notice(
    BuildContext context,
    String text,
    NoticeCode? code, {
    String? link,
  }) {
    final l10n = AppLocalizations.of(context);
    return switch (code) {
      null ||
      NoticeCode.careAgeUnknown ||
      NoticeCode.smallTalk ||
      NoticeCode.help ||
      NoticeCode.correctionApplied ||
      NoticeCode.sameAsPending ||
      // Lumi L7: "là sao", "xoá cái vừa ghi": what Lumi did or waits for, said plainly.
      NoticeCode.followUp ||
      NoticeCode.duplicateSuspected => AsBubble(text: text),
      // Lumi L7 (P-168 #6): a new topic closed my question; "Giữ lại" asks it again (the server
      // reads the chip's own words, so any app build or voice says the same).
      NoticeCode.questionSetAside => AsNoticeCard(
        icon: ClIcons.retry,
        text: text,
        action: viewer
            ? null
            : AsLink(
                label: l10n.asKeepQuestion,
                onPressed: () => unawaited(ctl.send(l10n.asKeepQuestion)),
              ),
      ),
      // Lumi 2026-10-16: the timer already runs — its screen is one tap away (Back = chat).
      NoticeCode.timerRunning => AsNoticeCard(
        icon: ClIcons.clock,
        text: text,
        action: switch (timerRoute(link)) {
          final route? => AsLink(
            label: l10n.asTimerOpen,
            onPressed: () => GoRouter.of(context).pushSafe(route),
          ),
          null => null,
        },
      ),
      // Rework 2026-10-15: money keeps the task in my private thread (D-075 #2).
      NoticeCode.spendingPrivate => AsNoticeCard(
        icon: ClIcons.lock,
        text: text,
      ),
      // A correction of something already saved: edit it where it lives.
      NoticeCode.previousSaved => AsNoticeCard(
        icon: ClIcons.edit,
        text: text,
        action: link == null
            ? null
            : AsLink(
                label: l10n.asEditInModule,
                onPressed: () => GoRouter.of(context).pushSafe(link),
              ),
      ),
      NoticeCode.medicineNotScheduled => AsNoticeCard(
        icon: ClIcons.bell,
        text: text,
        action: AsLink(
          label: l10n.asOpenReminders,
          onPressed: () => GoRouter.of(context).pushSafe(Routes.reminders),
        ),
      ),
      NoticeCode.careNoApprovedContent => AsNoticeCard(
        icon: ClIcons.journal,
        text: text,
        action: AsLink(
          label: l10n.asOpenCareLibrary,
          onPressed: () => _openRead(context, chat.scope.babyId, '/library'),
        ),
      ),
      NoticeCode.recipesNoneApproved => AsNoticeCard(
        icon: ClIcons.feed,
        text: text,
        action: AsLink(
          label: l10n.asOpenSolids,
          onPressed: () =>
              _openRead(context, chat.scope.babyId, '/care/solids'),
        ),
      ),
      // LUMI-13 / LUMI-05: what was not drafted (or what this build cannot show), with the
      // module where it can be added directly (Back = chat).
      NoticeCode.partNotSaved || NoticeCode.appUpdateNeeded => AsNoticeCard(
        icon: code == NoticeCode.partNotSaved ? ClIcons.ruler : ClIcons.alert,
        text: text,
        action: switch (timerRoute(link) ?? moduleRoute(link)) {
          final route? => AsLink(
            label: timerRoute(link) != null
                ? l10n.asTimerOpen
                : l10n.asOpenModule,
            onPressed: () => GoRouter.of(context).pushSafe(route),
          ),
          null => null,
        },
      ),
      NoticeCode.careFeatureDisabled ||
      NoticeCode.regionUnsupported => AsNoticeCard(
        icon: code == NoticeCode.regionUnsupported
            ? ClIcons.globe
            : ClIcons.lock,
        text: text,
        action: AsLink(
          label: l10n.asOpenHealth,
          onPressed: () => GoRouter.of(context).push(healthLocation(const [])),
        ),
      ),
    };
  }

  /// CH16: the approved guidance, "Thử tối nay" (an intention) and "Gợi ý khác".
  List<Widget> _guidance(
    BuildContext context,
    TaskThread t,
    ApprovedContentPart p,
  ) {
    final l10n = AppLocalizations.of(context);
    final content = p.content;
    if (content == null) {
      // An A2 message without the content's words: the reason only.
      return [if (p.reason.isNotEmpty) AsBubble(text: p.reason)];
    }
    final care = t.snapshot?.task.care;
    final plan = care?.plan;
    final planned = plan != null && plan.contentId == p.contentId;
    final canPlan =
        me != null &&
        familyCan(me!, FamilyAction.rhythmFeedback) &&
        (t.snapshot?.task.authoredBy(myUid) ?? true);
    final busy = chat.busy.contains('plan:${t.taskId}');
    final day = content.timeOfDay == ContentTimeOfDay.day;
    return [
      AsGuidanceCard(
        content: content,
        reason: p.reason,
        reviewed: p.reviewed,
        children: [
          if (planned)
            Row(
              children: [
                ClIcon(
                  ClIcons.check,
                  size: 14,
                  color: context.cl.colors.mintText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    day ? l10n.asPlannedToday : l10n.asPlannedTonight,
                    style: context.cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.cl.colors.mintText,
                    ),
                  ),
                ),
              ],
            )
          else if (canPlan || p.alternatives.isNotEmpty)
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (canPlan)
                  AsButton(
                    label: day ? l10n.asTryToday : l10n.asTryTonight,
                    loading: busy,
                    onPressed: () async =>
                        onToast(await ctl.planActivity(t.taskId, p)),
                  ),
                if (p.alternatives.isNotEmpty)
                  AsButton(
                    label: l10n.asAnotherIdea,
                    style: AsButtonStyle.secondary,
                    onPressed: () => GoRouter.of(
                      context,
                    ).push(activityLocation(p.alternatives.first.contentId)),
                  ),
              ],
            ),
        ],
      ),
      if (planned && care?.followUp == null && care?.feedback == null)
        AsFootnote(
          icon: ClIcons.clock,
          text: l10n.asPlanFollowUp(
            plan.feedbackOpensAt == null
                ? ''
                : dayLabel(
                    l10n,
                    Localizations.localeOf(context).toLanguageTag(),
                    plan.feedbackOpensAt!,
                    t.snapshot?.task.timezone ?? zone,
                    now,
                  ),
          ),
        ),
    ];
  }

  /// CH17: the question only once the chance to try has passed (the server says when), always
  /// with "Chưa thử"; the answer costs nothing.
  List<Widget> _followUp(
    BuildContext context,
    TaskThread t,
    AssistantCareView care,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final language = Localizations.localeOf(context).languageCode;
    final taskZone = t.snapshot?.task.timezone ?? zone;
    if (care.feedback case final f?) {
      final saved = f.outcome != FeedbackOutcome.notTried;
      return [
        AsBubble(text: outcomeLabel(l10n, f.outcome), mine: true),
        AsBubble(
          text: switch (f.outcome) {
            FeedbackOutcome.helpful => l10n.asFeedbackHelpful,
            FeedbackOutcome.unsure => l10n.asFeedbackUnsure,
            FeedbackOutcome.notSuitable => l10n.asFeedbackNotSuitable,
            FeedbackOutcome.notTried => l10n.asFeedbackNotTried,
          },
        ),
        if (saved)
          AsDraftCard(
            state: DraftState.saved,
            kind: DraftKind.observation,
            tile: (
              ClIcons.heart,
              context.cl.colors.mintSoft,
              context.cl.colors.mintText,
            ),
            title: l10n.asFeedbackTitle,
            line:
                '${outcomeLabel(l10n, f.outcome)} · ${shortDate(locale, inBabyZone(taskZone, now))}',
            module: l10n.asModuleRhythm(babyName),
            actions: [
              (
                label: l10n.asOpenRhythm,
                onPressed: () => GoRouter.of(context).push(Routes.rhythm),
              ),
            ],
          ),
      ];
    }
    final q = care.followUp;
    if (q == null) return const [];
    final busy = chat.busy.contains('fb:${t.taskId}');
    final canAnswer =
        me != null &&
        familyCan(me!, FamilyAction.rhythmFeedback) &&
        (t.snapshot?.task.authoredBy(myUid) ?? true);
    return [
      AsDayDivider(label: dayLabel(l10n, locale, now, taskZone, now)),
      AsBubble(text: q.question.of(language)),
      if (canAnswer)
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final c in q.choices)
              AsChip(
                label: c.label.of(language),
                onPressed: busy
                    ? null
                    : () async => onToast(
                        await ctl.sendFeedback(t.taskId, q, c.outcome),
                      ),
              ),
          ],
        ),
    ];
  }

  List<Widget> _taskFailure(BuildContext context, TaskThread t) {
    final l10n = AppLocalizations.of(context);
    final error = t.snapshot?.task.error;
    if (t.photo) {
      switch (error) {
        case AssistantReason.ocrUnreadable || AssistantReason.validationFailed:
          // CH14: nothing read, nothing charged; retake or type it in.
          return [
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                if (onRetake != null)
                  AsChip(
                    label: error == AssistantReason.ocrUnreadable
                        ? l10n.asRetake
                        : l10n.asOtherPhoto,
                    onPressed: () => onRetake!(t.taskId),
                  ),
                AsChip(label: l10n.asTypeInstead, onPressed: onTypeIn),
              ],
            ),
          ];
        case AssistantReason.aiUnavailable || null:
          return [
            _failureCard(
              context,
              onRetry: onRetake == null ? null : () => onRetake!(t.taskId),
            ),
          ];
        default:
          break;
      }
    }
    return [
      switch (error) {
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
      },
    ];
  }

  /// CH28: free, never behind credits; the household region's number only (from the server's
  /// part, else the same health pack), never a default hotline.
  Widget _health(BuildContext context, List<String> signs, String? emergency) =>
      Consumer(
        builder: (context, ref, _) {
          final pack = ref.watch(rhythmContentProvider).value?.health;
          final country = ref
              .watch(capabilitiesProvider(chat.scope.babyId))
              .value
              ?.country;
          final number = emergency ?? pack?.emergencyNumberFor(country);
          return AsHealthCard(
            number: number,
            onCall: () => onDial(number),
            onOpenHealth: () =>
                _openRead(context, chat.scope.babyId, Routes.firstAid),
          );
        },
      );

  List<Widget> _clarification(
    BuildContext context,
    TaskThread t,
    AssistantTask task,
    Clarification c, {
    bool questionShown = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final expired =
        task.clarificationExpiresAt != null &&
        !now.isBefore(task.clarificationExpiresAt!);
    final answering = chat.answering == task.id;
    // D-075 #2: only the task's author answers its questions.
    final asker = task.authoredBy(myUid)
        ? null
        : authorName(l10n, task.author!, myUid: myUid);
    final pending = chat.pendingAnswer?.taskId == task.id;
    final timePicker = c.allowText && isTimeField(c.field);
    return [
      if (!questionShown) AsBubble(text: c.question.of(language)),
      // The answer is on its way: my bubble and "Lumi đang soạn…" replace the chips.
      if (expired)
        AsFootnote(text: l10n.asClarifyExpired, icon: ClIcons.clock)
      else if (asker != null)
        AsFootnote(icon: ClIcons.clock, text: l10n.asWaitingFor(asker))
      else ...[
        // While the answer is on its way my bubble and "Lumi đang soạn…" stand for the chips;
        // the slots stay so nothing below moves or enters again.
        if (pending)
          const SizedBox.shrink()
        else
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
                  icon: timePicker ? ClIcons.clock : ClIcons.edit,
                  selected: answering,
                  onPressed: chat.choosing != null
                      ? null
                      : timePicker
                      ? () => onTimeAnswer(t, c)
                      : () => answering
                            ? ctl.stopTypingAnswer()
                            : onTypeAnswer(task.id),
                ),
            ],
          ),
        // CH14: text in a photo is content, never a command.
        if (c.field == 'image.intent' && !pending)
          AsFootnote(icon: ClIcons.lock, text: l10n.asPhotoTextIsData)
        else
          const SizedBox.shrink(),
        // CH15: red flags go to health guidance, free, whatever the credits.
        if (task.care?.topic == 'sleep_concern')
          AsSafetyNote(
            onOpenHealth: () =>
                GoRouter.of(context).push(healthLocation(const [])),
          ),
      ],
    ];
  }

  /// The concrete save of a draft that saves on its own card ("Lưu cữ bú").
  String _saveLabel(AppLocalizations l10n, AssistantDraft d) => switch (d.op) {
    DraftOp.update => l10n.asSaveChange,
    DraftOp.delete => l10n.asDeleteRecord,
    DraftOp.create => _createLabel(l10n, d),
  };

  String _createLabel(AppLocalizations l10n, AssistantDraft d) =>
      switch (d.kind) {
        DraftKind.bottle => l10n.asSaveBottle,
        DraftKind.breast => l10n.asSaveBreast,
        DraftKind.sleep => l10n.asSaveSleep,
        DraftKind.observation => l10n.asSaveObservation,
        DraftKind.reminder => l10n.asSaveReminder,
        DraftKind.pump => l10n.savePump,
        DraftKind.diaper => l10n.asSaveDiaper,
        DraftKind.growth => l10n.saveGrowth,
        _ => l10n.asSaveItem,
      };

  /// Lumi 2026-10-16: the inline fix of a "Cần kiểm tra" draft (open by itself, chips first).
  List<AsFixRow> _fixRows(
    BuildContext context,
    TaskThread t,
    AssistantDraft d,
    String taskZone,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Future<void> edit() => showDraftEditor(
      context,
      scopeKey: chat.scope.key,
      draft: d,
      babyName: babyName,
      zone: taskZone,
    );
    return fixRowsFor(
      l10n: l10n,
      locale: locale,
      d: d,
      zone: taskZone,
      now: now,
      act: FixActions(
        patch: (payload, confirmed) async {
          final (outcome, _) = await ctl.patch(
            d,
            payload,
            confirmed: confirmed,
          );
          if (outcome != ActionOutcome.ok) onToast(outcome);
        },
        edit: edit,
        pickTime: (initial) => pickAssistantTime(
          context,
          initial: initial == null ? null : hm(initial, taskZone),
        ),
        pickDate: (initial, {past = false}) {
          final today = DateTime(now.year, now.month, now.day);
          return pickAssistantDate(
            context,
            initial: initial ?? today,
            // A measurement (LUMI-01) is a day already gone; a reminder from yesterday on.
            first: today.subtract(Duration(days: past ? 3 * 366 : 1)),
            last: past ? today : today.add(const Duration(days: 366)),
          );
        },
      ),
    );
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
    if (d.payload is TimerPayload) return _timerDraft(context, t, d);
    final problems = pending
        ? {...draftProblems(d.payload, now), ...d.problems}.toList()
        : const <DraftProblem>[];
    if (d.payload is ExpensePayload && pending) {
      return _receipt(context, t, d, problems, expired: expired);
    }
    final active = pending && canSave && !expired && !saving;
    // Lumi 2026-10-16: what to fix, said and fixable in place (no "Sửa" tap first).
    final blocker = confirmBlocker(d, d.revision, now);
    final blocked = blocker != null || problems.isNotEmpty;
    final fixes = [
      if (active) ..._fixRows(context, t, d, taskZone),
      // A review flag that names no field of this draft (an older draft): one tap confirms it,
      // never a silent disabled save.
      if (active &&
          blocker == AssistantReason.reviewRequired &&
          reviewGaps(d, now).isEmpty)
        (
          field: 'review',
          reason: l10n.asNeedsReview,
          chips: <AsFixChip>[
            (
              label: l10n.asFixRight,
              opens: false,
              onTap: () async {
                final (outcome, _) = await ctl.patch(
                  d,
                  d.payload,
                  confirmed: {
                    ...d.uncertainFields,
                    ...d.missingFields,
                  }.toList(),
                );
                if (outcome != ActionOutcome.ok) onToast(outcome);
              },
            ),
          ],
          optional: false,
        ),
    ];
    final gaps = fixes.where((r) => !r.optional).length;
    // One draft in the task (or a note): its own concrete save, no tick, no batch bar.
    final ownSave =
        d.payload is ObservationPayload ||
        (t.snapshot?.drafts.where((x) => x.kind != DraftKind.timer).length ??
                1) <=
            1;
    final notes = <String>[
      if (d.state == DraftState.failed) failureLabel(l10n, d),
      if (pending && chat.stale.contains(d.id)) l10n.asErrStale,
      if (expired) l10n.asErrExpired,
      // The fix rows say what is missing; a problem without a row is still read out.
      if (pending && !expired && gaps == 0 && blocked)
        for (final p in problems) problemLabel(l10n, p),
      if (pending && !canSave) l10n.asViewerDraftNote,
      if (d.state == DraftState.saved)
        if (_other(context, d.confirmedBy) case final who?)
          l10n.asConfirmedBy(who),
    ];
    final editable =
        d.payload is BottlePayload ||
        d.payload is BreastPayload ||
        d.payload is SleepPayload ||
        d.payload is ReminderPayload ||
        d.payload is ExpensePayload ||
        d.payload is PumpPayload ||
        d.payload is DiaperPayload ||
        d.payload is GrowthPayload;
    final note = d.payload is ObservationPayload;
    // Lumi L7 (P-168 #2): a change to a record saved minutes ago, or its delete.
    final removes = d.op == DraftOp.delete;
    final actions = <AsCardAction>[
      if (active) ...[
        if (editable && !removes)
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
          label: removes
              ? l10n.asKeepRecord
              : note
              ? l10n.asNoThanks
              : l10n.asRemove,
          onPressed: () async => onToast(await ctl.discard(d)),
        ),
      ],
      if (d.state == DraftState.saved && !removes) ...[
        if (d.kind == DraftKind.expense) ...[
          if (recordLocation(d) case final record?)
            (
              label: l10n.asOpenSpending,
              onPressed: () => GoRouter.of(context).pushSafe(record),
            ),
        ] else if (d.kind == DraftKind.observation) ...[
          (
            label: l10n.asOpenRhythm,
            onPressed: () => GoRouter.of(context).push(Routes.rhythm),
          ),
        ] else ...[
          if (moduleLocation(d.kind) case final module?)
            (
              label: openModuleLabel(l10n, d.kind),
              onPressed: () => GoRouter.of(context).pushSafe(module),
            ),
          if (recordLocation(d) case final record?)
            (
              label: l10n.asOpenRecord,
              onPressed: () => GoRouter.of(context).pushSafe(record),
            ),
        ],
      ],
      if (canSaveAnyway(d) && canSave && !saving) ...[
        if (moduleLocation(d.kind) case final module?)
          (
            label: l10n.asSeeLogged,
            onPressed: () => GoRouter.of(context).pushSafe(module),
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
    final line = switch (d.payload) {
      ObservationPayload(:final date, when: final period) => [
        if (DateTime.tryParse(date) case final day?)
          dayLabel(
            l10n,
            locale,
            fromBabyWall(taskZone, DateTime(day.year, day.month, day.day, 12)),
            taskZone,
            now,
          ),
        sleepConcernLabel(
          l10n,
          t.snapshot?.task.care?.sleep?.kind,
          period,
        ).ifEmpty(l10n.asObservationSleep),
      ].join(' · '),
      ReminderPayload(:final date, :final time, :final assigneeUid) =>
        l10n.asRemindLine(
          [
            date == null ? l10n.asNoDate : weekdayDate(locale, date),
            // D-075 #5: a date without a time saves as an all-day reminder, unless the server
            // still asks for a time.
            time ??
                (reminderNeedsTimeFor(d) ? l10n.asNoTime : l10n.reminderAllDay),
            ?_assignee(context, assigneeUid),
          ].join(' · '),
        ),
      ExpensePayload(:final date, :final totalMinor, :final currency) => [
        if (date != null) fullDate(locale, date),
        if (totalMinor != null) moneyLabel(locale, totalMinor, currency),
      ].join(' · '),
      _ => draftLine(
        l10n,
        locale,
        d.payload,
        taskZone,
        now,
        side: (s) => sideWord(l10n, s),
      ),
    };
    final canEdit = editable && active;
    final review = gaps > 0;
    return AsDraftCard(
      onTap: canEdit
          ? () => showDraftEditor(
              context,
              scopeKey: chat.scope.key,
              draft: d,
              babyName: babyName,
              zone: taskZone,
            )
          : null,
      privateHint: d.kind == DraftKind.expense ? l10n.asOnlyYou : null,
      state: saving
          ? DraftState.saving
          : (pending && !review && d.state == DraftState.needsReview
                ? DraftState.draft
                : d.state),
      kind: d.kind,
      title: switch (d.op) {
        DraftOp.update => l10n.asDraftEditTitle(
          kindLabel(l10n, d.kind).toLowerCase(),
        ),
        DraftOp.delete => l10n.asDraftDeleteTitle(
          kindLabel(l10n, d.kind).toLowerCase(),
        ),
        DraftOp.create =>
          note && d.state == DraftState.saved
              ? kindLabel(l10n, d.kind)
              : draftTitle(l10n, d),
      },
      line: line,
      module: switch (d.kind) {
        DraftKind.reminder => l10n.asModuleRemindersOf(babyName),
        DraftKind.expense => l10n.asModuleSpending,
        _ => moduleLabel(l10n, d.kind, babyName),
      },
      selected: active && !ownSave
          ? (blocked ? false : ctl.isSelected(d))
          : null,
      onSelected: blocked ? null : (v) => ctl.toggle(d.id, v),
      notes: notes,
      noteIsError: d.state == DraftState.failed || expired,
      body: fixes.isEmpty
          ? null
          : AsFixPanel(key: ValueKey('as.fix:${d.id}'), rows: fixes),
      primary: (active || (saving && ownSave)) && ownSave
          ? (
              label: _saveLabel(l10n, d),
              onPressed: blocked || saving
                  ? null
                  : () async => onToast(await ctl.saveOne(t.taskId, d)),
            )
          : null,
      primaryLoading: saving,
      primaryNote: review ? l10n.asPickAboveToSave : null,
      actions: actions,
      stateLabelOverride: expired
          ? l10n.asStateExpired
          : d.state == DraftState.saved && d.op == DraftOp.delete
          ? l10n.asStateDeleted
          : d.state == DraftState.saved && d.op == DraftOp.update
          ? l10n.asStateUpdated
          : null,
    );
  }

  /// Lumi 2026-10-16: a timer from chat ("Con đang ngủ" → "Bắt đầu tính giờ ngủ · 01:05",
  /// "dậy rồi" → "Kết thúc giấc ngủ · 01:45"). One tap saves it through the server into the
  /// app's own timer; the card then shows the live timer and opens its screen (Back = chat).
  Widget _timerDraft(BuildContext context, TaskThread t, AssistantDraft d) {
    final l10n = AppLocalizations.of(context);
    final p = d.payload as TimerPayload;
    final canSave = canSaveKind(me, d.kind);
    final saving = chat.saving.contains(d.id);
    final pending =
        d.state == DraftState.draft || d.state == DraftState.needsReview;
    final expired = pending && d.expiredAt(now);
    final taskZone = t.snapshot?.task.timezone ?? zone;
    final active = pending && canSave && !expired && !saving;
    final type = p.isSleep ? TimerType.sleep : TimerType.breast;
    final fixes = active
        ? _fixRows(context, t, d, taskZone)
        : const <AsFixRow>[];
    final problems = pending ? draftProblems(p, now) : const <DraftProblem>[];
    final blocked =
        confirmBlocker(d, d.revision, now) != null || problems.isNotEmpty;
    final at = p.at == null ? '' : hm(p.at!, taskZone);
    final route = '${Routes.timer}/${p.timer}';
    final started = d.state == DraftState.saved && p.isStart;
    // The running timer, live: a stop names the session it ends; a saved start its own.
    final live = (pending && !p.isStart) || started
        ? AsTimerLine(
            babyId: chat.scope.babyId,
            type: type,
            zone: taskZone,
            sessionId:
                p.sessionId ??
                (d.recordId?.startsWith('r_') == true
                    ? d.recordId!.substring(2)
                    : null),
          )
        : null;
    final notes = <String>[
      if (d.state == DraftState.failed) failureLabel(l10n, d),
      if (expired) l10n.asErrExpired,
      if (pending && !canSave) l10n.asViewerDraftNote,
      if (d.state == DraftState.saved)
        if (_other(context, d.confirmedBy) case final who?)
          l10n.asConfirmedBy(who),
    ];
    return AsDraftCard(
      state: saving ? DraftState.saving : d.state,
      kind: d.kind,
      tile: switch (type) {
        TimerType.breast => (
          ClIcons.drop,
          context.cl.care.breast.soft,
          context.cl.care.breast.ink,
        ),
        _ => (
          ClIcons.sleep,
          context.cl.care.sleep.soft,
          context.cl.care.sleep.ink,
        ),
      },
      title: timerTitle(l10n, p),
      line: draftLine(
        l10n,
        Localizations.localeOf(context).toLanguageTag(),
        p,
        taskZone,
        now,
        side: (s) => sideWord(l10n, s).toLowerCase(),
      ),
      module: moduleLabel(l10n, d.kind, babyName),
      notes: notes,
      noteIsError: d.state == DraftState.failed || expired,
      body: switch ((live, fixes.isEmpty)) {
        (null, true) => null,
        (final l, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?l,
            if (l != null && fixes.isNotEmpty)
              const SizedBox(height: ClSpace.s3),
            if (fixes.isNotEmpty)
              AsFixPanel(key: ValueKey('as.fix:${d.id}'), rows: fixes),
          ],
        ),
      },
      primary: active || saving
          ? (
              label: switch ((p.isSleep, p.isStart)) {
                (true, true) => l10n.asTimerStartSleep(at),
                (false, true) => l10n.asTimerStartBreast(
                  sideWord(l10n, p.side ?? 'left').toLowerCase(),
                  at,
                ),
                (true, false) => l10n.asTimerStopSleep(at),
                (false, false) => l10n.asTimerStopBreast(at),
              },
              onPressed: blocked || saving
                  ? null
                  : () async => onToast(await ctl.saveOne(t.taskId, d)),
            )
          : null,
      primaryLoading: saving,
      primaryNote: fixes.isNotEmpty ? l10n.asPickAboveToSave : null,
      actions: [
        if (active)
          (
            label: p.isStart ? l10n.asNoThanks : l10n.asTimerKeep,
            onPressed: () async => onToast(await ctl.discard(d)),
          ),
        if (started ||
            (d.state == DraftState.failed &&
                d.error == AssistantReason.timerRunning))
          (
            label: l10n.asTimerOpen,
            onPressed: () => GoRouter.of(context).pushSafe(route),
          ),
        if (d.state == DraftState.saved && !p.isStart)
          if (recordLocation(d) case final record?)
            (
              label: l10n.asOpenLog,
              onPressed: () => GoRouter.of(context).pushSafe(record),
            ),
      ],
      stateLabelOverride: expired ? l10n.asStateExpired : null,
    );
  }

  /// "Giao cho Mẹ" from the baby's members (never a name read from a photo).
  String? _assignee(BuildContext context, String? uid) {
    if (uid == null) return null;
    final l10n = AppLocalizations.of(context);
    if (uid == myUid) return l10n.reminderAssignedToYou;
    final m = members.where((m) => m.uid == uid).firstOrNull;
    return l10n.reminderAssignedTo(
      memberLabel(l10n, m, myUid: myUid ?? '', uid: uid),
    );
  }

  /// CH11: the receipt draft. An uncertain or missing field is flagged and must be checked
  /// (the date row opens a date picker); a suspected duplicate needs "Vẫn lưu" (never merged);
  /// "Lưu chi tiêu" stays off until nothing blocks it.
  Widget _receipt(
    BuildContext context,
    TaskThread t,
    AssistantDraft d,
    List<DraftProblem> problems, {
    required bool expired,
  }) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final p = d.payload as ExpensePayload;
    final canSave = canSaveKind(me, d.kind);
    final saving = chat.saving.contains(d.id);
    final flagged = {...d.uncertainFields, ...d.missingFields};
    final duplicate = d.warnings.contains(DraftWarning.duplicateSuspected);
    final acknowledged = chat.acknowledged.contains(d.id);
    final blocked =
        confirmBlocker(d, d.revision, now) != null ||
        problems.isNotEmpty ||
        (duplicate && !acknowledged);
    final editable = canSave && !expired && !saving;
    void edit() => showDraftEditor(
      context,
      scopeKey: chat.scope.key,
      draft: d,
      babyName: babyName,
      zone: t.snapshot?.task.timezone ?? zone,
    );
    Future<void> pickDate() async {
      final today = DateTime(now.year, now.month, now.day);
      final current = p.date == null ? null : DateTime.tryParse(p.date!);
      final picked = await pickAssistantDate(
        context,
        initial: current ?? today,
        first: today.subtract(const Duration(days: 366)),
        last: today,
      );
      if (picked == null) return;
      final (outcome, _) = await ctl.patch(
        d,
        ExpensePayload(
          merchant: p.merchant,
          totalMinor: p.totalMinor,
          currency: p.currency,
          date:
              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
          subtotalMinor: p.subtotalMinor,
          taxMinor: p.taxMinor,
          categoryId: p.categoryId,
          babyId: p.babyId,
          keepReceipt: p.keepReceipt,
          note: p.note,
        ),
        confirmed: const ['date'],
      );
      onToast(outcome);
    }

    final category = expenseCategoryName(l10n, p.categoryId);
    final fields = <AsField>[
      (
        label: l10n.asFieldStore,
        value: p.merchant ?? l10n.asNotRead,
        flagged: flagged.contains('merchant'),
        onTap: editable ? edit : null,
      ),
      (
        label: l10n.asFieldDate,
        value: p.date == null ? l10n.asNoDate : fullDate(locale, p.date!),
        flagged: flagged.contains('date'),
        onTap: editable ? pickDate : null,
      ),
      (
        label: l10n.asFieldTotal,
        value: p.totalMinor == null
            ? l10n.asNotRead
            : moneyLabel(locale, p.totalMinor!, p.currency),
        flagged:
            flagged.contains('totalMinor') ||
            flagged.contains('currency') ||
            problems.contains(DraftProblem.currencyUnsupported),
        onTap: editable ? edit : null,
      ),
      if (category != null)
        (
          label: l10n.asFieldCategory,
          value: category,
          flagged: false,
          onTap: null,
        ),
      (
        label: l10n.asFieldScope,
        value: babyName.isEmpty
            ? l10n.asScopeHousehold
            : l10n.asExpenseFor(babyName),
        flagged: false,
        onTap: null,
      ),
    ];
    final notes = <String>[
      if (chat.stale.contains(d.id)) l10n.asErrStale,
      if (expired) l10n.asErrExpired,
      if (!expired) ...[
        if (flagged.contains('date')) l10n.asConfirmDate,
        for (final pr in problems)
          if (pr != DraftProblem.missingDate) problemLabel(l10n, pr),
        if (flagged.isNotEmpty && !flagged.every((f) => f == 'date'))
          l10n.asNeedsReview,
      ],
      if (!canSave) l10n.asViewerDraftNote,
    ];
    Widget card({
      Widget? ask,
      List<AsField>? shown,
      AsCardAction? save,
      List<String>? said,
    }) => AsReceiptCard(
      // A typed expense is not a receipt: its category and store (or what was bought).
      title: t.photo ? l10n.asReceiptTitle : draftTitle(l10n, d),
      ask: ask,
      stateLabel: saving
          ? l10n.asStateSaving
          : expired
          ? l10n.asStateExpired
          : stateLabel(
              l10n,
              flagged.isNotEmpty || problems.isNotEmpty
                  ? DraftState.needsReview
                  : d.state,
            ),
      review: flagged.isNotEmpty || problems.isNotEmpty,
      saving: saving,
      fields: shown ?? fields,
      footnote: p.taxMinor != null && p.totalMinor != null
          ? l10n.asTaxIncluded(moneyLabel(locale, p.totalMinor!, p.currency))
          : null,
      duplicate: duplicate
          ? (
              acknowledged: acknowledged,
              onOpen: () =>
                  GoRouter.of(context).pushSafe(Routes.spendingHistory),
              onAcknowledge: editable ? () => ctl.acknowledge(d.id) : null,
            )
          : null,
      notes: said ?? notes,
      privateHint: l10n.asOnlyYouSpending,
      primary: editable
          ? save ??
                (
                  label: l10n.asSaveExpense,
                  onPressed: blocked
                      ? null
                      : () async => onToast(await ctl.saveOne(t.taskId, d)),
                )
          : null,
      actions: [
        if (editable) ...[
          (label: l10n.asEdit, onPressed: edit),
          (
            label: l10n.asSkip,
            onPressed: () async => onToast(await ctl.discard(d)),
          ),
        ],
      ],
    );
    // LUMI-16 (owner 2026-10-16): a typed purchase without an amount — Lumi asks for it on the
    // card; "Lưu chi tiêu" enables as soon as an amount is typed (the amount and its currency go
    // in as checked, then it saves in the same tap when nothing else is left to check).
    if (!t.photo && p.totalMinor == null && editable && !expired) {
      final others = {...flagged}..removeAll(const ['totalMinor', 'currency']);
      final otherProblems = [
        for (final pr in problems)
          if (pr != DraftProblem.missingAmount &&
              pr != DraftProblem.currencyUnsupported)
            pr,
      ];
      return AsAmountAsk(
        key: ValueKey('as.amount:${d.id}'),
        currency: p.currency ?? 'VND',
        builder: (context, ask, typed) => card(
          ask: ask,
          shown: [
            for (final f in fields)
              if (f.label != l10n.asFieldTotal) f,
          ],
          said: [
            if (chat.stale.contains(d.id)) l10n.asErrStale,
            for (final pr in otherProblems) problemLabel(l10n, pr),
            if (others.isNotEmpty && !others.every((f) => f == 'date'))
              l10n.asNeedsReview,
            if (others.contains('date')) l10n.asConfirmDate,
          ],
          save: (
            label: l10n.asSaveExpense,
            onPressed:
                typed == null ||
                    others.isNotEmpty ||
                    otherProblems.isNotEmpty ||
                    (duplicate && !acknowledged)
                ? null
                : () async => onToast(
                    await ctl.fillAndSave(
                      t.taskId,
                      d,
                      ExpensePayload(
                        merchant: p.merchant,
                        totalMinor: typed.minor,
                        currency: typed.currency,
                        date: p.date,
                        subtotalMinor: p.subtotalMinor,
                        taxMinor: p.taxMinor,
                        categoryId: p.categoryId,
                        babyId: p.babyId,
                        keepReceipt: p.keepReceipt,
                        note: p.note,
                      ),
                      const ['totalMinor', 'currency'],
                    ),
                  ),
          ),
        ),
      );
    }
    return card();
  }

  List<Widget> _batch(
    BuildContext context,
    TaskThread t,
    List<AssistantDraft> drafts,
  ) {
    final writer = drafts.any((d) => canSaveKind(me, d.kind));
    if (!writer) return const [];
    // A receipt, the CH16 observation and a timer save from their own card ("Lưu chi tiêu",
    // "Lưu ghi nhận", "Bắt đầu tính giờ ngủ"); a single draft too (Lumi 2026-10-16: one tap,
    // no "Chọn mục muốn lưu"); only several drafts (CH04, CH13) get the batch bar.
    final batchable = [
      for (final d in drafts)
        if (d.kind != DraftKind.timer) d,
    ];
    final ownSave =
        batchable.length <= 1 ||
        batchable.every(
          (d) => d.kind == DraftKind.expense || d.kind == DraftKind.observation,
        );
    final toFill = batchable
        .where(
          (d) =>
              (d.state == DraftState.draft ||
                  d.state == DraftState.needsReview) &&
              !d.expiredAt(now) &&
              !chat.saving.contains(d.id) &&
              reviewGaps(d, now).isNotEmpty,
        )
        .length;
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
      if (pending > 0 && !ownSave)
        AsBatchBar(
          toFill: toFill,
          count: ctl.selectedDrafts(t.taskId).length,
          saving: busy,
          onSave: () async => onToast(await ctl.confirm(t.taskId)),
          onDiscardAll: () async => onToast(await ctl.discardAll(t.taskId)),
        ),
    ];
  }
}

/// CH02: nothing asked yet. Examples only prefill the composer; nothing costs until "Gửi".
/// CH08 with its per-feed times: the records the server listed, or else the ones its
/// `sourceIds` name, read from the care log on this phone. Times show only while they add up to
/// the summary ([summaryFeeds]).
class _SourceSummary extends ConsumerWidget {
  const _SourceSummary({
    required this.part,
    required this.babyId,
    required this.zone,
    required this.now,
    required this.onOpenSource,
  });

  final SourceSummaryPart part;
  final String babyId;
  final String zone;
  final DateTime now;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = part.sourceIds;
    final items =
        part.items ??
        (ids.isEmpty || ids.length > summarySourceLimit
            ? null
            : ref.watch(summarySourcesProvider((babyId, ids.join(',')))));
    final feeds = items == null ? null : summaryFeeds(part.summary, items);
    return AsSummaryCard(
      summary: part.summary,
      zone: zone,
      now: now,
      onOpenSource: onOpenSource,
      bottleFeeds: feeds?.bottle,
      breastFeeds: feeds?.breast,
    );
  }
}

/// Above the thread: a small spinner while the page before it loads, or why it did not with
/// "Thử lại" (nothing asks again by itself after a failure).
class _OlderRow extends StatelessWidget {
  const _OlderRow({required this.chat, required this.ctl});
  final ChatState chat;
  final AssistantChat ctl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (!chat.olderFailed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: ClSpace.s2),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          l10n.asOlderFailed,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        ClPressable(
          onPressed: () => unawaited(ctl.loadOlder()),
          semanticLabel: l10n.asRetry,
          minSize: const Size(0, 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              l10n.asRetry,
              style: cl.text.caption.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
              boxShadow: cl.shadows.card,
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
        // Lumi greets (D-076 #11): the assistant has a face, not a spark.
        const LumiMascot(size: 56),
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

/// CH09 sheet "Gửi ảnh để trợ lý đọc": camera or library (a row opens it at once), what a photo
/// costs from the household's policy, and "Huỷ" (0 credits). The exact quote follows in the
/// thread before anything is uploaded.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    Widget row(PhotoSource source, ClIcons icon, String title, String sub) =>
        ClPressable(
          onPressed: () => Navigator.of(context).pop(source),
          semanticLabel: title,
          pressedOpacity: 0.7,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.cloud,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(icon, size: 20, color: c.mintText),
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
                          color: c.ink,
                        ),
                      ),
                      Text(
                        sub,
                        style: cl.text.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                ClIcon(ClIcons.chevronRight, size: 18, color: c.inkMuted),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.asPhotoSheetTitle),
        row(
          PhotoSource.camera,
          ClIcons.camera,
          l10n.avatarCamera,
          l10n.asPhotoCameraSub,
        ),
        const SizedBox(height: ClSpace.s2),
        row(
          PhotoSource.library,
          ClIcons.memories,
          l10n.avatarLibrary,
          l10n.asPhotoLibrarySub,
        ),
        const SizedBox(height: ClSpace.s3),
        AsButton(
          label: l10n.asCancel,
          style: AsButtonStyle.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: ClSpace.s4),
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
      title: c.shared ? l10n.asDeleteSharedTitle : l10n.asDeleteTitle,
      body: c.shared ? l10n.asDeleteSharedBody : l10n.asDeleteBody,
      confirm: l10n.asDeleteConfirm,
      cancel: l10n.asCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final toaster = ClToaster.of(context);
    setState(() => _deleting.add(c.id));
    try {
      final r = await ref
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
      toaster.show(
        message: r.domainRecordsKept
            ? l10n.asDeletedRecordsKept
            : l10n.asDeleted,
      );
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
    final me = session.membershipFor(scope.babyId);
    final all = [
      for (final c in _items ?? const <AssistantConversation>[])
        if (c.scope == null || c.scope == scope) c,
    ];
    // D-075 #2: the baby's shared thread first, then my own private ones.
    final shared = all.where((c) => c.shared).firstOrNull;
    final items = [
      for (final c in all)
        if (!c.shared) c,
    ];
    final sharedReader =
        !scope.household &&
        (me?.role == MemberRole.coParent || me?.role == MemberRole.caregiver);
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
            else if (items.isEmpty && shared == null)
              Text(
                l10n.asHistoryEmpty,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              )
            else ...[
              if (shared != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: ClSpace.s2),
                  child: Text(
                    l10n.asHistoryShared,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    boxShadow: cl.shadows.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _HistoryRow(
                    title: shared.title ?? l10n.asSharedThreadTitle,
                    subtitle: l10n.asSharedThreadSub(when(shared)),
                    lastTaskId: shared.lastTaskId,
                    now: now,
                    household: false,
                    shared: true,
                    deleting: _deleting.contains(shared.id),
                    onOpen: () => context.pop(
                      HistoryPick(shared.scope ?? scope, shared.id),
                    ),
                    // The shared thread is deleted for everyone: Cùng nuôi only.
                    onDelete: me?.role == MemberRole.coParent
                        ? () => _delete(shared)
                        : null,
                  ),
                ),
                const SizedBox(height: ClSpace.s4),
              ],
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
                    boxShadow: cl.shadows.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (final c in list)
                        _HistoryRow(
                          title: c.title ?? l10n.asHistoryUntitled,
                          subtitle: when(c),
                          lastTaskId: c.lastTaskId,
                          now: now,
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
            ],
            Text(
              l10n.asHistoryFootnote,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              sharedReader ? l10n.asHistorySharedNote : l10n.asHistoryPrivate,
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

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.lastTaskId,
    required this.now,
    required this.household,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
    this.shared = false,
  });
  final String title;
  final String subtitle;

  /// The conversation's last task: its snapshot gives the row status (CH03).
  final String? lastTaskId;
  final DateTime now;
  final bool household;
  final bool shared;
  final bool deleting;
  final VoidCallback onOpen;

  /// Null hides "Xoá" (the shared thread for a caregiver).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    // CH03 "2 mục đã lưu" / "1 nháp": from the last task's snapshot only; while it loads or if
    // it can't be read, the row shows its time alone (never a guessed state).
    final id = lastTaskId;
    final snap = id == null
        ? null
        : ref
              .watch(
                assistantTaskSnapshotProvider((
                  id,
                  Localizations.localeOf(context).languageCode,
                )),
              )
              .value;
    final status = snap == null
        ? const ThreadStatus()
        : threadStatus(snap, now);
    final said = [
      if (status.needsAnswer) l10n.asHistoryNeedsAnswer,
      if (status.awaitingFeedback) l10n.asHistoryAwaitingFeedback,
      if (status.saved > 0) l10n.asHistorySaved(status.saved),
    ].join(' · ');
    final caption = cl.text.caption.copyWith(color: cl.colors.inkMuted);
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
                shared
                    ? ClIcons.family
                    : (household ? ClIcons.grid : ClIcons.spark),
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
                  // Figma "2 mục đã lưu · 09:12"; the shared thread keeps its own line.
                  if (said.isNotEmpty && shared) Text(said, style: caption),
                  Text(
                    said.isNotEmpty && !shared ? '$said · $subtitle' : subtitle,
                    style: caption,
                  ),
                ],
              ),
            ),
            if (status.pending > 0)
              Padding(
                padding: const EdgeInsets.only(left: ClSpace.s2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.sunshineSoft,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  // Ink on the soft warm fill (Night care too).
                  child: Text(
                    l10n.asHistoryDrafts(status.pending),
                    style: cl.text.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
              ),
            if (onDelete != null)
              ClPressable(
                onPressed: deleting ? null : onDelete,
                semanticLabel: l10n.asDeleteChat,
                child: deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : ClIcon(
                        ClIcons.trash,
                        size: 18,
                        color: cl.colors.inkMuted,
                      ),
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
      boxShadow: cl.shadows.card,
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
                    // D-075 #1: AI summaries take credits from this same pool.
                    costRow(
                      l10n.asCostSummary,
                      l10n.asCostCredits(aiSummaryCredits),
                    ),
                    costRow(l10n.asCostFollowUp, l10n.asCostNoExtra),
                    costRow(l10n.asCostError, l10n.asCostNotCharged),
                    costRow(l10n.asCostHealth, l10n.asCostFree),
                  ],
                ),
              ),
              // CH19 "Gần đây": only what the server listed (chat tasks and, D-075 #1, AI
              // summaries); nothing at all when it sends no list.
              if (v.usage.recent case final recent?) ...[
                const SizedBox(height: ClSpace.s4),
                Text(l10n.asRecentTitle, style: cl.text.bodyStrong),
                const SizedBox(height: ClSpace.s2),
                Container(
                  width: double.infinity,
                  decoration: card(),
                  child: recent.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            l10n.asRecentEmpty,
                            style: cl.text.label.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (final e in recent)
                              _RecentRow(entry: e, locale: tag),
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

/// One CH19 "Gần đây" line: what used (or held) credits, who, when and how many — 0-credit work
/// says why it was 0 (given back, or free), and running work says it only holds them.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry, required this.locale});
  final UsageEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final e = entry;
    final title = switch (e.source) {
      UsageSource.text => l10n.asRecentText,
      UsageSource.image => l10n.asRecentPhoto,
      UsageSource.handover => l10n.asRecentHandover,
      UsageSource.explain => l10n.asRecentExplain,
      UsageSource.moment => l10n.asRecentMoment,
      UsageSource.summary => l10n.asRecentSummary,
    };
    final value = switch (e.state) {
      TaskUsageState.reserved => l10n.asRecentHeld(e.credits),
      TaskUsageState.released => l10n.asRecentReleased,
      _ when e.charged == 0 => l10n.asRecentFree,
      _ => l10n.asCostCredits(e.charged),
    };
    final meta = [
      if (e.who case final who? when who.isNotEmpty) who,
      if (e.at case final at?) shortDate(locale, at.toLocal()),
      value,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.label),
                Text(
                  meta,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
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

/// "Trái" / "Phải" / "Cả hai" for a draft's side.
String sideWord(AppLocalizations l10n, String side) => switch (side) {
  'left' => l10n.sideLeft,
  'right' => l10n.sideRight,
  _ => l10n.sideBoth,
};

/// LUMI-13: the in-app module a notice links to (`/care/growth`, `/care`); null for anything
/// that is not a plain in-app path (never an outside link).
String? moduleRoute(String? link) {
  final readRoute = assistantReadRoute(link);
  if (readRoute != null) return readRoute;
  final uri = link == null ? null : Uri.tryParse(link);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final path = uri.path;
  if (!path.startsWith('/care') && !path.startsWith('/rhythm')) return null;
  final safe = RegExp(r'^[A-Za-z0-9_-]{1,120}$');
  return uri.pathSegments.isNotEmpty && uri.pathSegments.every(safe.hasMatch)
      ? path
      : null;
}

/// The app route of a timer notice's link (`/care/timer/{sleep|breast}`, query dropped); null
/// for anything else.
String? timerRoute(String? link) {
  final uri = link == null ? null : Uri.tryParse(link);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final m = RegExp(r'^/care/timer/(sleep|breast)$').firstMatch(uri.path);
  return m == null ? null : '${Routes.timer}/${m.group(1)}';
}
