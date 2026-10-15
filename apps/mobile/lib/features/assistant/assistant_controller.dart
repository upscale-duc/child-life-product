import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/session.dart';
import '../care/care_repository.dart' show onlineProvider;
import 'assistant_models.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';

/// One task in the thread: what the person typed and the server's snapshot (null until fetched).
@immutable
class TaskThread {
  const TaskThread({required this.taskId, this.snapshot, this.text});
  final String taskId;
  final TaskSnapshot? snapshot;

  /// What was typed on this phone, shown until the server's own message arrives.
  final String? text;

  /// The user's words: the server message, else what was typed here.
  String? get userText {
    final m = snapshot?.messages
        .where((m) => m.role == MessageRole.user && m.text.isNotEmpty)
        .firstOrNull;
    return m?.text ?? text;
  }

  TaskThread withSnapshot(TaskSnapshot s) =>
      TaskThread(taskId: taskId, snapshot: s, text: text);
}

/// Why the composer's last input is not a task (a call-level state; task failures are drawn
/// from the task snapshot itself).
enum ChatBlockKind {
  /// CH25 offline: kept, sent only on a tap.
  offline,

  /// CH25 failure: nothing saved, nothing charged; "Thử lại".
  failure,

  /// CH26: no assistant consent yet; nothing sent to the provider.
  consent,

  /// CH21 / CH24: the household pool is used up (the plan says which).
  exhausted,

  /// CH20: the photo's quote is more than what is left; nothing uploaded.
  photoQuote,

  /// The quote allows the photo but this build cannot upload it yet (slice A5).
  photoSoon,

  /// Kill switch (FEATURE_DISABLED).
  featureOff,

  /// CH27 region.
  region,

  /// CH27 viewer / role.
  writeDenied,
  readDenied,

  /// CH27 module unavailable.
  module,
  notMember,
  generic,
}

@immutable
class ChatBlock {
  const ChatBlock(this.kind, {this.quote});
  final ChatBlockKind kind;

  /// The refusing quote (CH20 numbers).
  final AssistantQuote? quote;
}

/// A photo picked on this phone and not sent (CH20): only its local reference.
@immutable
class PendingPhoto {
  const PendingPhoto({required this.name, this.path});
  final String name;
  final String? path;
}

/// What a person's action came to, for the toast the screen shows.
enum ActionOutcome { ok, partial, offline, stale, failed, nothing }

@immutable
class ChatState {
  const ChatState({
    required this.scope,
    this.conversationId,
    this.threads = const [],
    this.kept,
    this.block,
    this.usage,
    this.restoring = false,
    this.loadFailed = false,
    this.sending = false,
    this.resumed = false,
    this.selection = const {},
    this.saving = const {},
    this.stale = const {},
    this.answering,
    this.choosing,
    this.photo,
  });

  final AssistantScope scope;
  final String? conversationId;
  final List<TaskThread> threads;

  /// The input not turned into a task (kept on this phone).
  final KeptInput? kept;
  final ChatBlock? block;
  final AssistantUsage? usage;
  final bool restoring;
  final bool loadFailed;
  final bool sending;

  /// CH23: the kept question was resumed after a verified purchase.
  final bool resumed;

  /// The person's own ticks; unticked drafts fall back to [defaultSelected].
  final Map<String, bool> selection;

  /// Drafts whose confirm is in flight ("Đang lưu").
  final Set<String> saving;

  /// Drafts a confirm found changed since they were seen (DRAFT_STALE): review again.
  final Set<String> stale;

  /// The task whose question is answered by typing ("Tự nhập").
  final String? answering;

  /// The clarification choice being sent (`taskId/choiceId`).
  final String? choosing;
  final PendingPhoto? photo;

  bool get empty =>
      threads.isEmpty &&
      kept == null &&
      photo == null &&
      block == null &&
      !restoring &&
      !loadFailed;

  UsageView? get usageView => usage == null ? null : UsageView.of(usage!);

  /// Drafts still waiting for a decision somewhere in the thread (CH21: still saveable).
  bool get hasReadyDrafts => threads.any(
    (t) => (t.snapshot?.drafts ?? const []).any(
      (d) => d.state == DraftState.draft || d.state == DraftState.needsReview,
    ),
  );

  TaskThread? thread(String taskId) =>
      threads.where((t) => t.taskId == taskId).firstOrNull;

  ChatState copyWith({
    String? conversationId,
    bool clearConversation = false,
    List<TaskThread>? threads,
    KeptInput? kept,
    bool clearKept = false,
    ChatBlock? block,
    bool clearBlock = false,
    AssistantUsage? usage,
    bool? restoring,
    bool? loadFailed,
    bool? sending,
    bool? resumed,
    Map<String, bool>? selection,
    Set<String>? saving,
    Set<String>? stale,
    String? answering,
    bool clearAnswering = false,
    String? choosing,
    bool clearChoosing = false,
    PendingPhoto? photo,
    bool clearPhoto = false,
  }) => ChatState(
    scope: scope,
    conversationId: clearConversation
        ? null
        : (conversationId ?? this.conversationId),
    threads: threads ?? this.threads,
    kept: clearKept ? null : (kept ?? this.kept),
    block: clearBlock ? null : (block ?? this.block),
    usage: usage ?? this.usage,
    restoring: restoring ?? this.restoring,
    loadFailed: loadFailed ?? this.loadFailed,
    sending: sending ?? this.sending,
    resumed: resumed ?? this.resumed,
    selection: selection ?? this.selection,
    saving: saving ?? this.saving,
    stale: stale ?? this.stale,
    answering: clearAnswering ? null : (answering ?? this.answering),
    choosing: clearChoosing ? null : (choosing ?? this.choosing),
    photo: clearPhoto ? null : (photo ?? this.photo),
  );
}

/// A draft is ticked by default only when nothing in it needs the person first (a "Cần kiểm
/// tra" item is never pre-checked).
bool defaultSelected(AssistantDraft d, DateTime now) =>
    d.state == DraftState.draft &&
    d.uncertainFields.isEmpty &&
    d.missingFields.isEmpty &&
    !d.expiredAt(now) &&
    d.payload is! UnknownPayload &&
    draftProblems(d.payload, now).isEmpty;

/// Connectivity as the chat sees it (tests drive it); back online triggers a snapshot refresh.
final assistantOnlineProvider = Provider<AsyncValue<bool>>(
  (ref) => ref.watch(onlineProvider),
);

/// Picks one photo from the library (slice A5 uploads it; A4 only quotes). Tests replace it.
final assistantPhotoPickerProvider = Provider<Future<PendingPhoto?> Function()>(
  (ref) => () async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    return x == null ? null : PendingPhoto(name: x.name, path: x.path);
  },
);

/// The chat of one scope (`child:<babyId>` / `household:<babyId>`): conversation, input, the
/// tasks it started and their drafts. One instance per scope, so switching baby never carries a
/// pending draft across (CH03); it closes its listeners when the chat closes.
final assistantChatProvider = NotifierProvider.autoDispose
    .family<AssistantChat, ChatState, String>(AssistantChat.new);

class AssistantChat extends Notifier<ChatState> {
  AssistantChat(this.scopeKey);

  final String scopeKey;
  final _subs = <String, StreamSubscription<TaskLive>>{};
  final _cursors = <String, EventCursor>{};
  final _refreshing = <String>{};
  String _locale = 'vi';
  var _opened = false;

  // Read once in build: a call that outlives the chat (closed mid-request) still finishes
  // without touching a disposed ref, and its state is dropped.
  late AssistantRepository _repo;
  late AssistantLocalStore _store;
  late DateTime Function() _clock;
  late String Function() _ids;
  ChatState? _last;

  /// `<uid>:<scope key>`: where this person's kept input and open thread live on the phone.
  late String _local;

  DateTime _now() => _clock();
  String _newId() => _ids();
  bool get _online =>
      ref.mounted && (ref.read(assistantOnlineProvider).value ?? true);

  @override
  ChatState get state => ref.mounted ? super.state : (_last ?? super.state);

  @override
  set state(ChatState value) {
    _last = value;
    if (ref.mounted) super.state = value;
  }

  @override
  ChatState build() {
    final scope =
        AssistantScope.fromKey(scopeKey) ?? const AssistantScope.child('');
    _repo = ref.read(assistantRepositoryProvider);
    _store = ref.read(assistantLocalStoreProvider);
    _clock = ref.read(assistantClockProvider);
    _ids = ref.read(assistantIdsProvider);
    ref.onDispose(_closeAll);
    ref.listen(assistantOnlineProvider, (prev, next) {
      if (prev?.value == false && next.value == true) unawaited(_reconnect());
    });
    // Kept listened so the consent is known (and not paused) when the person sends.
    final session = ref.read(sessionProvider);
    if (session is SessionSignedIn) {
      ref.listen(assistantConsentProvider(session.user.uid), (_, _) {});
    }
    // Per person on this phone too: chats are private to their owner (P-158).
    _local = session is SessionSignedIn
        ? '${session.user.uid}:$scopeKey'
        : scopeKey;
    final kept = _store.kept(_local);
    final taskIds = _store.taskIds(_local);
    return ChatState(
      scope: scope,
      conversationId: _store.conversation(_local),
      threads: [for (final id in taskIds) TaskThread(taskId: id)],
      kept: kept,
      restoring: taskIds.isNotEmpty,
      block: switch (kept?.reason) {
        null => null,
        KeptReason.offline => const ChatBlock(ChatBlockKind.offline),
        KeptReason.failed => const ChatBlock(ChatBlockKind.failure),
        KeptReason.blocked => const ChatBlock(ChatBlockKind.exhausted),
        KeptReason.consent => const ChatBlock(ChatBlockKind.consent),
        KeptReason.photo => null,
      },
    );
  }

  void _closeAll() {
    for (final s in _subs.values) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  /// The screen opened: restore the open conversation (or [conversationId] from CH03) from the
  /// server's snapshots and read the household pool. Opening costs nothing.
  Future<void> open(String locale, {String? conversationId}) async {
    _locale = locale;
    if (_opened && conversationId == null) return;
    _opened = true;
    unawaited(refreshUsage());
    if (conversationId != null && conversationId != state.conversationId) {
      await _loadConversation(conversationId);
    } else if (state.threads.isNotEmpty) {
      await _restore();
    }
  }

  void _persistThread() => _store.setConversation(
    _local,
    state.conversationId,
    [for (final t in state.threads) t.taskId],
  );

  Future<void> _restore() async {
    state = state.copyWith(restoring: true, loadFailed: false);
    var failed = false;
    for (final t in [...state.threads]) {
      try {
        final s = await _repo.task(t.taskId, locale: _locale);
        if (s != null) _putSnapshot(s);
        _watch(t.taskId);
      } on AssistantException catch (e) {
        // A task I may no longer read (left the family, deleted) leaves the thread.
        if (e.reason == AssistantReason.notMember ||
            e.code == 'not-found' ||
            e.code == 'permission-denied') {
          _dropThread(t.taskId);
        } else {
          failed = true;
        }
      } on Object {
        failed = true;
      }
    }
    state = state.copyWith(restoring: false, loadFailed: failed);
  }

  /// "Thử lại" on a thread that could not be loaded.
  Future<void> reload() => _restore();

  Future<void> _loadConversation(String conversationId) async {
    _closeAll();
    state = state.copyWith(
      conversationId: conversationId,
      threads: const [],
      restoring: true,
      loadFailed: false,
      clearBlock: true,
    );
    try {
      final page = await _repo.messages(
        state.scope.babyId,
        conversationId,
        locale: _locale,
      );
      final ordered = [...page.items]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final ids = <String>[];
      for (final m in ordered) {
        if (m.taskId case final id? when !ids.contains(id)) ids.add(id);
      }
      final last = ids.length > 10 ? ids.sublist(ids.length - 10) : ids;
      state = state.copyWith(
        threads: [for (final id in last) TaskThread(taskId: id)],
      );
      _persistThread();
      await _restore();
    } on Object {
      state = state.copyWith(restoring: false, loadFailed: true);
    }
  }

  /// "Mới": a new conversation in the same scope; the kept input stays.
  void newConversation() {
    _closeAll();
    state = state.copyWith(
      clearConversation: true,
      threads: const [],
      clearBlock: true,
      resumed: false,
      selection: const {},
      stale: const {},
      clearAnswering: true,
      loadFailed: false,
      restoring: false,
    );
    _persistThread();
  }

  Future<void> refreshUsage() async {
    try {
      final u = await _repo.usage(state.scope.babyId, locale: _locale);
      if (u != null) state = state.copyWith(usage: u);
    } on Object {
      // Unknown usage shows no number (never a static one).
    }
  }

  void _setUsage(AssistantUsage? u) {
    if (u != null) state = state.copyWith(usage: u);
  }

  // ---------- Threads and live updates ----------

  void _putSnapshot(TaskSnapshot s) {
    final id = s.task.id;
    final threads = [
      for (final t in state.threads)
        if (t.taskId == id)
          t.withSnapshot(t.snapshot == null ? s : mergeSnapshot(t.snapshot!, s))
        else
          t,
    ];
    state = state.copyWith(threads: threads);
    final cursor = _cursors.putIfAbsent(id, EventCursor.new);
    cursor.accept(s.events);
  }

  void _dropThread(String taskId) {
    unawaited(_subs.remove(taskId)?.cancel());
    state = state.copyWith(
      threads: [
        for (final t in state.threads)
          if (t.taskId != taskId) t,
      ],
    );
    _persistThread();
  }

  void _addThread(TaskSnapshot s, String text) {
    final conversation = s.task.conversationId ?? state.conversationId;
    state = state.copyWith(
      conversationId: conversation,
      threads: [
        ...state.threads.where((t) => t.taskId != s.task.id),
        TaskThread(taskId: s.task.id, snapshot: s, text: text),
      ],
    );
    _cursors.putIfAbsent(s.task.id, EventCursor.new).accept(s.events);
    _persistThread();
    _watch(s.task.id);
  }

  void _watch(String taskId) {
    if (_subs.containsKey(taskId)) return;
    _subs[taskId] = _repo
        .watchTask(taskId)
        .listen((live) => onLive(taskId, live), onError: (Object _) {});
  }

  /// One live update from Firestore (public for tests of the reconnect rules).
  @visibleForTesting
  void onLive(String taskId, TaskLive live) {
    final thread = state.thread(taskId);
    if (thread == null) return;
    switch (live) {
      case TaskDocLive(:final task):
        final s = thread.snapshot;
        _putSnapshot(
          s == null ? TaskSnapshot(task: task) : s.copyWith(task: task),
        );
      case TaskDraftsLive(:final drafts):
        final s = thread.snapshot;
        if (s == null) return;
        _putSnapshot(s.copyWith(drafts: drafts));
      case TaskEventsLive(:final events):
        final fresh = _cursors
            .putIfAbsent(taskId, EventCursor.new)
            .accept(events);
        var refresh = false;
        for (final e in fresh) {
          switch (e.type) {
            case TaskEventType.usageUpdated:
              final u = AssistantUsage.fromJson(e.payload['usage']);
              u == null ? unawaited(refreshUsage()) : _setUsage(u);
            case TaskEventType.draftsReady ||
                TaskEventType.answerReady ||
                TaskEventType.clarificationRequired ||
                TaskEventType.itemSaved ||
                TaskEventType.itemFailed ||
                TaskEventType.taskFailed:
              refresh = true;
            default:
              break;
          }
        }
        if (refresh) unawaited(_refresh(taskId));
    }
  }

  Future<void> _refresh(String taskId) async {
    if (!_refreshing.add(taskId)) return;
    try {
      final s = await _repo.task(taskId, locale: _locale);
      if (s != null && state.thread(taskId) != null) _putSnapshot(s);
    } on Object {
      // The listener keeps the last state; the next reconnect asks again.
    } finally {
      _refreshing.remove(taskId);
    }
  }

  /// Back online: the snapshot is the authority (brief p.11); kept input waits for a tap.
  Future<void> _reconnect() async {
    unawaited(refreshUsage());
    for (final t in [...state.threads]) {
      final s = t.snapshot;
      final open =
          s == null ||
          !s.task.state.terminal ||
          s.drafts.any((d) => !d.state.settled);
      if (open) await _refresh(t.taskId);
    }
    if (state.block?.kind == ChatBlockKind.offline && state.kept == null) {
      state = state.copyWith(clearBlock: true);
    }
  }

  // ---------- Sending ----------

  Future<bool> _consented() async {
    if (!ref.mounted) return false;
    final session = ref.read(sessionProvider);
    if (session is! SessionSignedIn) return false;
    final provider = assistantConsentProvider(session.user.uid);
    final now = ref.read(provider).value;
    if (now != null && now.known) return now.granted;
    try {
      final c = await ref
          .read(provider.future)
          .timeout(const Duration(seconds: 5));
      return c.granted;
    } on Object {
      return false;
    }
  }

  void _keep(KeptInput? input) {
    _store.keep(_local, input);
    state = input == null
        ? state.copyWith(clearKept: true)
        : state.copyWith(kept: input);
  }

  ChatBlock _blockFor(AssistantReason? r, {bool offline = false}) {
    if (offline) return const ChatBlock(ChatBlockKind.offline);
    return ChatBlock(switch (r) {
      AssistantReason.usageExhausted => ChatBlockKind.exhausted,
      AssistantReason.consentRequired => ChatBlockKind.consent,
      AssistantReason.featureDisabled => ChatBlockKind.featureOff,
      AssistantReason.regionUnsupported => ChatBlockKind.region,
      AssistantReason.writeDenied => ChatBlockKind.writeDenied,
      AssistantReason.readDenied => ChatBlockKind.readDenied,
      AssistantReason.moduleUnavailable => ChatBlockKind.module,
      AssistantReason.notMember ||
      AssistantReason.authRequired => ChatBlockKind.notMember,
      AssistantReason.aiUnavailable || null => ChatBlockKind.failure,
      _ => ChatBlockKind.generic,
    });
  }

  /// Send what the person typed (an explicit tap). Suggestions only prefill; nothing here runs
  /// by itself. The input is kept on the phone until a task exists for it.
  Future<void> send(String raw, {IntentHint? hint}) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;
    if (state.answering case final taskId?) {
      await answerText(taskId, text);
      return;
    }
    final key = taskInputKey(
      conversationId: state.conversationId,
      scope: state.scope,
      modality: TaskModality.text,
      text: text,
    );
    var kept = state.kept;
    // The same words again keep their request id (an idempotent retry, or the resume of a
    // blocked start); new words are a new task.
    if (kept == null || kept.text != text) {
      kept = KeptInput(
        text: text,
        requestId: _newId(),
        inputKey: key,
        reason: KeptReason.offline,
        at: _now(),
        conversationId: state.conversationId,
      );
    }
    _keep(kept);
    state = state.copyWith(resumed: false);
    await _dispatch(kept, hint);
  }

  /// "Gửi" on the kept input (back online, after a failure).
  Future<void> sendKept() async {
    final kept = state.kept;
    if (kept == null || state.sending) return;
    await _dispatch(kept, null);
  }

  Future<void> _dispatch(
    KeptInput kept,
    IntentHint? hint, {
    bool resumed = false,
    int attempt = 0,
  }) async {
    if (!_online) {
      _keep(kept.copyWith(reason: KeptReason.offline));
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.offline));
      return;
    }
    if (!await _consented()) {
      _keep(kept.copyWith(reason: KeptReason.consent));
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.consent));
      return;
    }
    state = state.copyWith(sending: true, clearBlock: true);
    final conversationId = kept.started
        ? kept.conversationId
        : state.conversationId;
    try {
      final quote = await _repo.quote(
        scope: state.scope,
        conversationId: conversationId,
        modality: TaskModality.text,
        locale: _locale,
        intentHint: hint,
      );
      _setUsage(quote.usage);
      // Out of credits or the model off: the start still goes (nothing is reserved). The server
      // answers health signs at once for free (CH28 never behind credits) and keeps any other
      // question as a blocked task to resume after an upgrade or the reset (api.md "Start").
      if (!quote.allowed &&
          quote.reason != AssistantReason.usageExhausted &&
          quote.reason != AssistantReason.aiUnavailable) {
        _keep(kept.copyWith(reason: KeptReason.blocked));
        state = state.copyWith(block: _blockFor(quote.reason));
        return;
      }
      final a = await _repo.start(
        requestId: kept.requestId,
        scope: state.scope,
        conversationId: conversationId,
        quoteId: quote.quoteId,
        text: kept.text,
        locale: _locale,
      );
      _setUsage(a.usage);
      final snapshot = a.snapshot;
      if (a.status == ResponseStatus.blocked ||
          snapshot == null ||
          snapshot.task.state == TaskState.blocked) {
        // The conversation the server opened for it holds the next messages too.
        if (snapshot?.task.conversationId case final c?
            when state.conversationId == null) {
          state = state.copyWith(conversationId: c);
          _persistThread();
        }
        _keep(
          KeptInput(
            text: kept.text,
            requestId: kept.requestId,
            inputKey: kept.inputKey,
            reason: KeptReason.blocked,
            at: kept.at,
            resumeUsed: kept.resumeUsed,
            started: true,
            conversationId: conversationId,
          ),
        );
        state = state.copyWith(
          block: _blockFor(
            a.reason ?? snapshot?.task.error ?? AssistantReason.usageExhausted,
          ),
        );
        return;
      }
      _addThread(snapshot, kept.text);
      _keep(null);
      if (resumed) state = state.copyWith(resumed: true);
    } on AssistantException catch (e) {
      if (attempt == 0 &&
          (e.reason == AssistantReason.quoteExpired ||
              e.reason == AssistantReason.quoteMismatch ||
              e.reason == AssistantReason.idempotencyConflict)) {
        // A fresh quote (and, on a key clash, a fresh request id) once; never a silent charge.
        final next = e.reason == AssistantReason.idempotencyConflict
            ? kept.copyWith(requestId: _newId(), started: false)
            : kept;
        state = state.copyWith(sending: false);
        await _dispatch(next, hint, resumed: resumed, attempt: 1);
        return;
      }
      _keep(
        kept.copyWith(
          reason: e.offline ? KeptReason.offline : KeptReason.failed,
        ),
      );
      state = state.copyWith(block: _blockFor(e.reason, offline: e.offline));
    } on Object {
      _keep(kept.copyWith(reason: KeptReason.failed));
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.failure));
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  /// CH25 "Thử lại" on a task that failed (AI_UNAVAILABLE): its credits were released, so a new
  /// task for the same words never charges twice.
  Future<void> retryTask(String taskId) async {
    final thread = state.thread(taskId);
    final text = thread?.userText;
    if (thread == null || text == null || state.sending) return;
    _dropThread(taskId);
    final kept = KeptInput(
      text: text,
      requestId: _newId(),
      inputKey: taskInputKey(
        conversationId: state.conversationId,
        scope: state.scope,
        modality: TaskModality.text,
        text: text,
      ),
      reason: KeptReason.failed,
      at: _now(),
    );
    _keep(kept);
    await _dispatch(kept, null);
  }

  /// CH23: after a verified purchase the kept question runs once in the paid pool.
  Future<void> resumeAfterUpgrade() async {
    final kept = state.kept;
    if (kept == null || kept.resumeUsed) return;
    // The same request id and input with a fresh quote: the server runs that blocked task once,
    // in the paid pool (api.md "Start" step 6); a never-started input simply starts.
    final next = kept.copyWith(resumeUsed: true);
    _keep(next);
    await refreshUsage();
    await _dispatch(next, null, resumed: true);
  }

  /// "Nhập tay" / dismissing a notice.
  void dismissBlock() => state = state.copyWith(clearBlock: true);

  /// "Không dùng trợ lý": nothing was sent; the kept text stays on this phone.
  void declineConsent() => state = state.copyWith(clearBlock: true);

  /// "Đồng ý và bắt đầu": the server records consent, then the kept input (or photo) goes on.
  Future<bool> agreeConsent() async {
    try {
      await _repo.setConsent(agree: true, locale: _locale);
    } on Object {
      return false;
    }
    state = state.copyWith(clearBlock: true);
    if (state.photo != null) {
      unawaited(_quotePhoto());
    } else if (state.kept case final kept?) {
      unawaited(_dispatch(kept, null));
    }
    return true;
  }

  // ---------- Photo (quote only in A4) ----------

  Future<void> pickPhoto() async {
    final photo = await ref.read(assistantPhotoPickerProvider)();
    if (photo == null || !ref.mounted) return;
    state = state.copyWith(photo: photo);
    await _quotePhoto();
  }

  Future<void> _quotePhoto() async {
    if (!_online) {
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.offline));
      return;
    }
    if (!await _consented()) {
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.consent));
      return;
    }
    try {
      final q = await _repo.quote(
        scope: state.scope,
        conversationId: state.conversationId,
        modality: TaskModality.image,
        attachmentCount: 1,
        locale: _locale,
      );
      _setUsage(q.usage);
      state = state.copyWith(
        block: q.allowed
            ? const ChatBlock(ChatBlockKind.photoSoon)
            : (q.reason == AssistantReason.usageExhausted
                  ? ChatBlock(ChatBlockKind.photoQuote, quote: q)
                  : _blockFor(q.reason)),
      );
    } on AssistantException catch (e) {
      state = state.copyWith(block: _blockFor(e.reason, offline: e.offline));
    } on Object {
      state = state.copyWith(block: const ChatBlock(ChatBlockKind.failure));
    }
  }

  /// After an upgrade from CH20: the same photo is quoted again in the paid pool.
  Future<void> pickPhotoAgain() async {
    if (state.photo != null) await _quotePhoto();
  }

  /// CH03 deleted the open conversation (confirmed by the server): start a new one.
  void conversationDeleted(String conversationId) {
    if (state.conversationId == conversationId) newConversation();
  }

  /// "Bỏ ảnh" / "Nhập tay": the photo was never uploaded.
  void removePhoto() =>
      state = state.copyWith(clearPhoto: true, clearBlock: true);

  // ---------- Clarification (CH05) ----------

  void typeAnswer(String taskId) => state = state.copyWith(answering: taskId);

  void stopTypingAnswer() => state = state.copyWith(clearAnswering: true);

  Future<ActionOutcome> answerChoice(String taskId, ClarificationChoice c) =>
      _clarify(taskId, choiceId: c.id);

  Future<ActionOutcome> answerText(String taskId, String text) =>
      _clarify(taskId, text: text.trim());

  Future<ActionOutcome> _clarify(
    String taskId, {
    String? choiceId,
    String? text,
  }) async {
    final task = state.thread(taskId)?.snapshot?.task;
    final c = task?.clarification;
    if (task == null ||
        c == null ||
        task.state != TaskState.awaitingClarification) {
      return ActionOutcome.nothing;
    }
    if (!_online) return ActionOutcome.offline;
    state = state.copyWith(choosing: '$taskId/${choiceId ?? ''}');
    try {
      final s = await _repo.clarify(
        taskId: taskId,
        expectedVersion: task.version,
        clarificationId: c.id,
        choiceId: choiceId,
        text: text,
        locale: _locale,
      );
      if (s != null) _putSnapshot(s);
      state = state.copyWith(clearAnswering: true);
      return ActionOutcome.ok;
    } on AssistantException catch (e) {
      if (e.offline) return ActionOutcome.offline;
      unawaited(_refresh(taskId));
      return e.reason == AssistantReason.invalidState
          ? ActionOutcome.stale
          : ActionOutcome.failed;
    } finally {
      state = state.copyWith(clearChoosing: true);
    }
  }

  // ---------- Drafts (CH04, CH06, CH07) ----------

  bool isSelected(AssistantDraft d) =>
      state.selection[d.id] ?? defaultSelected(d, _now());

  void toggle(String draftId, bool value) =>
      state = state.copyWith(selection: {...state.selection, draftId: value});

  /// The drafts of [taskId] the batch would save now.
  List<AssistantDraft> selectedDrafts(String taskId) {
    final now = _now();
    return [
      for (final d in state.thread(taskId)?.snapshot?.drafts ?? const [])
        if (isSelected(d) &&
            !state.saving.contains(d.id) &&
            (d.state == DraftState.draft) &&
            confirmBlocker(d, d.revision, now) == null &&
            d.payload is! UnknownPayload)
          d,
    ];
  }

  /// "Lưu N mục đã chọn" (or the failed items again, or one conflict with its acknowledgement).
  /// Saved only when the server says so, per item.
  Future<ActionOutcome> confirm(
    String taskId, {
    List<AssistantDraft>? drafts,
    Map<String, List<DraftWarning>> acknowledge = const {},
  }) async {
    final chosen = drafts ?? selectedDrafts(taskId);
    if (chosen.isEmpty) return ActionOutcome.nothing;
    if (!_online) return ActionOutcome.offline;
    final ids = {for (final d in chosen) d.id};
    state = state.copyWith(
      saving: {...state.saving, ...ids},
      stale: {...state.stale}..removeAll(ids),
    );
    try {
      final r = await _repo.confirm(
        taskId: taskId,
        scope: state.scope,
        selected: [
          for (final d in chosen)
            ConfirmSelection(d.id, d.revision, acknowledge[d.id] ?? const []),
        ],
        requestId: _newId(),
        locale: _locale,
      );
      final thread = state.thread(taskId);
      if (thread?.snapshot case final s?) {
        _putSnapshot(s.copyWith(drafts: applyConfirm(s.drafts, r.items)));
      }
      final stale = {
        for (final i in r.items)
          if (i.errorCode == AssistantReason.draftStale.wire) i.draftId,
      };
      if (stale.isNotEmpty) {
        state = state.copyWith(
          stale: {...state.stale, ...stale},
          selection: {...state.selection, for (final id in stale) id: false},
        );
        unawaited(_refresh(taskId));
      }
      return r.partial ? ActionOutcome.partial : ActionOutcome.ok;
    } on AssistantException catch (e) {
      if (e.offline) return ActionOutcome.offline;
      if (e.reason == AssistantReason.draftStale ||
          e.reason == AssistantReason.scopeChanged ||
          e.reason == AssistantReason.draftSaved) {
        // Changed since it was seen: the person checks it again before saving.
        state = state.copyWith(
          stale: {...state.stale, ...ids},
          selection: {...state.selection, for (final id in ids) id: false},
        );
        unawaited(_refresh(taskId));
        return ActionOutcome.stale;
      }
      return ActionOutcome.failed;
    } on Object {
      return ActionOutcome.failed;
    } finally {
      state = state.copyWith(saving: {...state.saving}..removeAll(ids));
    }
  }

  /// CH07 "Thử lại mục lỗi": only the failed items a retry can fix; saved ones are never sent
  /// again (no second record).
  Future<ActionOutcome> retryFailed(String taskId) => confirm(
    taskId,
    drafts: [
      for (final d in state.thread(taskId)?.snapshot?.drafts ?? const [])
        if (retryable(d)) d,
    ],
  );

  /// "Vẫn lưu riêng" after an explicit confirm in the UI.
  Future<ActionOutcome> saveAnyway(String taskId, AssistantDraft d) => confirm(
    taskId,
    drafts: [d],
    acknowledge: {
      d.id: d.warnings.isEmpty
          ? [
              d.error == AssistantReason.duplicateSuspected
                  ? DraftWarning.duplicateSuspected
                  : DraftWarning.overlap,
            ]
          : d.warnings,
    },
  );

  Future<ActionOutcome> discard(AssistantDraft d) async {
    if (!_online) return ActionOutcome.offline;
    try {
      final next = await _repo.discard(
        draftId: d.id,
        expectedRevision: d.revision,
        locale: _locale,
      );
      _replaceDraft(next ?? d.copyWith(state: DraftState.discarded));
      return ActionOutcome.ok;
    } on AssistantException catch (e) {
      if (e.offline) return ActionOutcome.offline;
      unawaited(_refresh(d.taskId));
      return ActionOutcome.failed;
    }
  }

  /// "Bỏ tất cả": every draft still waiting (saved ones stay saved).
  Future<ActionOutcome> discardAll(String taskId) async {
    var out = ActionOutcome.nothing;
    for (final d in state.thread(taskId)?.snapshot?.drafts ?? const []) {
      if (d.state.settled || d.state == DraftState.saving) continue;
      out = await discard(d);
      if (out == ActionOutcome.offline) break;
    }
    return out;
  }

  void _replaceDraft(AssistantDraft d) {
    final thread = state.threads
        .where((t) => t.snapshot?.drafts.any((x) => x.id == d.id) ?? false)
        .firstOrNull;
    final s = thread?.snapshot;
    if (s == null) return;
    _putSnapshot(s.copyWith(drafts: mergeDrafts(s.drafts, [d])));
  }

  /// CH06 "Cập nhật bản nháp": the same checks as the form first, then `patchDraft` (revision
  /// +1). Updates the draft only; nothing is saved.
  Future<(ActionOutcome, List<DraftProblem>)> patch(
    AssistantDraft d,
    DraftPayload payload,
  ) async {
    final problems = draftProblems(payload, _now());
    if (problems.isNotEmpty) return (ActionOutcome.failed, problems);
    if (!_online) return (ActionOutcome.offline, const <DraftProblem>[]);
    try {
      final next = await _repo.patchDraft(
        draftId: d.id,
        expectedRevision: d.revision,
        payload: payload,
        confirmedFields: {...d.uncertainFields, ...d.missingFields}.toList(),
        locale: _locale,
      );
      if (next != null) {
        _replaceDraft(next);
        // Checked by the person just now: selected again, no longer stale.
        state = state.copyWith(
          selection: {...state.selection}..remove(d.id),
          stale: {...state.stale}..remove(d.id),
        );
      } else {
        unawaited(_refresh(d.taskId));
      }
      return (ActionOutcome.ok, const <DraftProblem>[]);
    } on AssistantException catch (e) {
      if (e.offline) return (ActionOutcome.offline, const <DraftProblem>[]);
      unawaited(_refresh(d.taskId));
      return (
        e.reason == AssistantReason.draftStale
            ? ActionOutcome.stale
            : ActionOutcome.failed,
        const <DraftProblem>[],
      );
    }
  }

  /// "Huỷ" while the task is still being prepared (released if nothing useful came out).
  Future<void> cancelTask(String taskId) async {
    try {
      final t = await _repo.cancel(taskId: taskId, locale: _locale);
      final s = state.thread(taskId)?.snapshot;
      if (t != null && s != null) _putSnapshot(s.copyWith(task: t));
    } on Object {
      unawaited(_refresh(taskId));
    }
  }
}
