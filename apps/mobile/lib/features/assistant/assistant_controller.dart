import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../baby/baby_models.dart' show MemberRole;
import '../care/care_repository.dart' show onlineProvider;
import 'assistant_models.dart';
import 'assistant_photos.dart';
import 'assistant_repository.dart';
import 'assistant_rules.dart';

/// One task in the thread: what the person typed and the server's snapshot (null until fetched).
@immutable
class TaskThread {
  const TaskThread({
    required this.taskId,
    this.snapshot,
    this.text,
    this.photoIds = const [],
  });
  final String taskId;
  final TaskSnapshot? snapshot;

  /// What was typed on this phone, shown until the server's own message arrives.
  final String? text;

  /// The photos sent from this phone for the task (shown until the server's message arrives).
  final List<String> photoIds;

  /// The task's photos: the user message's attachments, else what this phone sent.
  List<String> get attachmentIds {
    final m = snapshot?.messages
        .where((m) => m.role == MessageRole.user && m.attachmentIds.isNotEmpty)
        .firstOrNull;
    return m?.attachmentIds ?? photoIds;
  }

  bool get photo =>
      attachmentIds.isNotEmpty || snapshot?.task.modality == TaskModality.image;

  /// The user's words: the server message, else what was typed here.
  String? get userText {
    final m = snapshot?.messages
        .where((m) => m.role == MessageRole.user && m.text.isNotEmpty)
        .firstOrNull;
    return m?.text ?? text;
  }

  TaskThread withSnapshot(TaskSnapshot s) =>
      TaskThread(taskId: taskId, snapshot: s, text: text, photoIds: photoIds);
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

  /// CH25 for a photo: the upload or the start failed; nothing charged, the photo is kept.
  photoFailed,

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

/// Where the chosen photo stands on this phone (CH09 → CH10), before the task exists.
enum PhotoStage {
  /// The exact quote is being asked for.
  quoting,

  /// CH09: quoted and allowed; waiting for "Gửi ảnh".
  ready,

  /// Not sent (CH20 over the balance, consent, offline, a failure): the selection is kept.
  held,

  /// CH10 "Đang tải lên": cancellable, 0 credits.
  uploading,

  /// Uploaded; `startTask` in flight.
  starting,
}

/// A photo picked on this phone and not sent yet: its bytes (memory only), the exact quote,
/// the retention the person chose (D-075 #3 default: keep with the expense) and the upload.
@immutable
class PendingPhoto {
  const PendingPhoto({
    required this.name,
    this.path,
    this.bytes,
    this.mime = 'image/jpeg',
    this.sha256 = '',
    this.stage = PhotoStage.quoting,
    this.quote,
    this.keep = true,
    this.progress = 0,
    this.requestId = '',
    this.attachmentId,
    this.canceled = false,
    this.hint,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
  final String mime;
  final String sha256;
  final PhotoStage stage;

  /// The allowing quote (CH09 shows its exact credits).
  final AssistantQuote? quote;

  /// "Giữ ảnh hoá đơn cùng khoản chi" (default on, D-075 #3).
  final bool keep;

  /// Upload progress 0–1.
  final double progress;

  /// The `startTask` idempotency key of this photo (kept for a resume of a blocked start).
  final String requestId;

  /// Set once uploaded: a retry or resume starts with the same photo, never a second upload.
  final String? attachmentId;

  /// The last upload was cancelled ("Đã huỷ tải lên · không trừ lượt").
  final bool canceled;
  final IntentHint? hint;

  bool get busy =>
      stage == PhotoStage.uploading || stage == PhotoStage.starting;

  PendingPhoto copyWith({
    PhotoStage? stage,
    AssistantQuote? quote,
    bool clearQuote = false,
    bool? keep,
    double? progress,
    String? attachmentId,
    bool? canceled,
  }) => PendingPhoto(
    name: name,
    path: path,
    bytes: bytes,
    mime: mime,
    sha256: sha256,
    stage: stage ?? this.stage,
    quote: clearQuote ? null : (quote ?? this.quote),
    keep: keep ?? this.keep,
    progress: progress ?? this.progress,
    requestId: requestId,
    attachmentId: attachmentId ?? this.attachmentId,
    canceled: canceled ?? this.canceled,
    hint: hint,
  );
}

/// How picking a photo went (the screen says why when it did not open).
enum PhotoPick { ok, canceled, denied, failed, busy }

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
    this.acknowledged = const {},
    this.busy = const {},
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

  /// Drafts whose duplicate warning the person answered "Vẫn lưu" (sent as `acknowledge`).
  final Set<String> acknowledged;

  /// Care calls in flight (`plan:<task>`, `fb:<task>`).
  final Set<String> busy;

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
    Set<String>? acknowledged,
    Set<String>? busy,
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
    acknowledged: acknowledged ?? this.acknowledged,
    busy: busy ?? this.busy,
  );
}

/// A draft is ticked by default only when nothing in it needs the person first (a "Cần kiểm
/// tra" item is never pre-checked).
bool defaultSelected(AssistantDraft d, DateTime now) =>
    d.state == DraftState.draft &&
    d.uncertainFields.isEmpty &&
    d.missingFields.isEmpty &&
    d.problems.isEmpty &&
    !d.expiredAt(now) &&
    d.payload is! UnknownPayload &&
    draftProblems(d.payload, now).isEmpty;

/// Connectivity as the chat sees it (tests drive it); back online triggers a snapshot refresh.
final assistantOnlineProvider = Provider<AsyncValue<bool>>(
  (ref) => ref.watch(onlineProvider),
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
  late PhotoPicker _picker;
  late AssistantUploader _uploader;
  late AssistantPhotoCache _photos;
  AssistantUpload? _upload;
  ChatState? _last;

  /// `<uid>:<scope key>`: where this person's kept input and open thread live on the phone.
  late String _local;

  /// D-075 #2: a Cùng nuôi / Người chăm sóc in a child chat reads the baby's shared thread.
  var _sharedRole = false;

  String get _sharedId => sharedConversationIdFor(state.scope.babyId);

  /// The conversation for work that stays private (photos, expenses): never the shared thread
  /// (the server refuses it), so the caller's own private one or a new one.
  String? get _privateConversation =>
      state.conversationId == _sharedId ? null : state.conversationId;

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
    _picker = ref.read(assistantPhotoPickerProvider);
    _uploader = ref.read(assistantUploaderProvider);
    _photos = ref.read(assistantPhotoCacheProvider);
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
    final role = session is SessionSignedIn
        ? session.membershipFor(scope.babyId)?.role
        : null;
    _sharedRole =
        !scope.household &&
        (role == MemberRole.coParent || role == MemberRole.caregiver);
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
    } else if (_sharedRole) {
      // D-075 #2: the baby's shared thread brings the other members' tasks too; my own private
      // tasks (photos) stay in the list. A thread that does not exist yet is just empty.
      await _loadConversation(_sharedId, quiet: true, keepLocal: true);
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

  Future<void> _loadConversation(
    String conversationId, {
    bool quiet = false,
    bool keepLocal = false,
  }) async {
    final local = keepLocal
        ? [for (final t in state.threads) t.taskId]
        : const <String>[];
    if (!keepLocal) _closeAll();
    state = state.copyWith(
      conversationId: quiet && state.conversationId == null
          ? null
          : conversationId,
      threads: keepLocal ? state.threads : const [],
      restoring: !quiet || local.isNotEmpty,
      loadFailed: false,
      clearBlock: !keepLocal,
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
      final known = {for (final t in state.threads) t.taskId: t};
      if (ordered.isNotEmpty) {
        state = state.copyWith(conversationId: conversationId);
      }
      state = state.copyWith(
        threads: [
          for (final id in last) known[id] ?? TaskThread(taskId: id),
          for (final id in local)
            if (!last.contains(id)) known[id] ?? TaskThread(taskId: id),
        ],
      );
      _persistThread();
      if (state.threads.isEmpty) {
        state = state.copyWith(restoring: false);
      } else {
        await _restore();
      }
    } on Object {
      if (quiet) {
        state = state.copyWith(restoring: false);
        if (local.isNotEmpty) await _restore();
      } else {
        state = state.copyWith(restoring: false, loadFailed: true);
      }
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

  void _addThread(
    TaskSnapshot s,
    String? text, {
    List<String> photoIds = const [],
  }) {
    final conversation = s.task.conversationId ?? state.conversationId;
    state = state.copyWith(
      conversationId: conversation,
      threads: [
        ...state.threads.where((t) => t.taskId != s.task.id),
        TaskThread(
          taskId: s.task.id,
          snapshot: s,
          text: text,
          photoIds: photoIds,
        ),
      ],
    );
    _cursors.putIfAbsent(s.task.id, EventCursor.new).accept(s.events);
    _persistThread();
    _watch(s.task.id);
  }

  void _watch(String taskId) {
    // A call that outlived the chat (the person left during an upload) only persists the task.
    if (!ref.mounted || _subs.containsKey(taskId)) return;
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
      // A photo held while offline gets its exact quote now; it is still sent only on a tap.
      if (state.photo?.stage == PhotoStage.held) unawaited(_quotePhoto());
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
    // An expense question stays private (D-075 #2: spending never enters the shared thread).
    final conversationId = kept.started
        ? kept.conversationId
        : (hint == IntentHint.expense
              ? _privateConversation
              : state.conversationId);
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
    if (state.photo != null && !state.photo!.busy) {
      unawaited(_quotePhoto());
    } else if (state.kept case final kept?) {
      unawaited(_dispatch(kept, null));
    }
    return true;
  }

  // ---------- Photo (CH09–CH14) ----------

  /// CH09: picks one photo ([source]), then asks for the exact quote. Nothing is uploaded yet.
  Future<PhotoPick> pickPhoto(PhotoSource source, {IntentHint? hint}) async {
    if (state.photo?.busy ?? false) return PhotoPick.busy;
    final PickedPhoto? picked;
    try {
      picked = await _picker(source);
    } on PhotoPickError catch (e) {
      return e.denied ? PhotoPick.denied : PhotoPick.failed;
    } on Object {
      return PhotoPick.failed;
    }
    if (picked == null) return PhotoPick.canceled;
    _usePhoto(
      PendingPhoto(
        name: picked.name,
        bytes: picked.bytes,
        mime: picked.mime,
        sha256: picked.sha256,
        requestId: _newId(),
        hint: hint,
      ),
    );
    await _quotePhoto();
    return PhotoPick.ok;
  }

  void _usePhoto(PendingPhoto photo) => state = state.copyWith(
    photo: photo,
    clearBlock: true,
    clearAnswering: true,
  );

  void _holdPhoto(ChatBlock block) {
    final photo = state.photo;
    state = state.copyWith(
      photo: photo?.copyWith(stage: PhotoStage.held),
      block: block,
    );
  }

  Future<void> _quotePhoto() async {
    final photo = state.photo;
    if (photo == null || photo.busy) return;
    if (!_online) return _holdPhoto(const ChatBlock(ChatBlockKind.offline));
    if (!await _consented()) {
      return _holdPhoto(const ChatBlock(ChatBlockKind.consent));
    }
    state = state.copyWith(
      photo: photo.copyWith(stage: PhotoStage.quoting, clearQuote: true),
      clearBlock: true,
    );
    try {
      final q = await _repo.quote(
        scope: state.scope,
        conversationId: _privateConversation,
        modality: TaskModality.image,
        attachmentCount: 1,
        intentHint: photo.hint,
        locale: _locale,
      );
      _setUsage(q.usage);
      final current = state.photo;
      if (current == null) return;
      if (q.allowed) {
        state = state.copyWith(
          photo: current.copyWith(stage: PhotoStage.ready, quote: q),
          clearBlock: true,
        );
      } else {
        _holdPhoto(
          q.reason == AssistantReason.usageExhausted
              ? ChatBlock(ChatBlockKind.photoQuote, quote: q)
              : _blockFor(q.reason),
        );
      }
    } on AssistantException catch (e) {
      _holdPhoto(_blockFor(e.reason, offline: e.offline));
    } on Object {
      _holdPhoto(const ChatBlock(ChatBlockKind.photoFailed));
    }
  }

  /// After an upgrade from CH20, back online or "Thử lại": the same photo is quoted again.
  Future<void> pickPhotoAgain() async {
    if (state.photo != null) await _quotePhoto();
  }

  /// "Giữ ảnh hoá đơn cùng khoản chi" (D-075 #3, on by default).
  void setKeepPhoto(bool keep) {
    final photo = state.photo;
    if (photo == null || photo.busy) return;
    state = state.copyWith(photo: photo.copyWith(keep: keep));
  }

  /// CH09 "Gửi ảnh" → CH10: the owned upload target (refused → nothing uploaded), one upload,
  /// then `startTask` with the photo. Charged only by the server, on a useful reading.
  Future<ActionOutcome> sendPhoto() async {
    final photo = state.photo;
    final bytes = photo?.bytes;
    var quote = photo?.quote;
    if (photo == null ||
        bytes == null ||
        photo.busy ||
        quote == null ||
        !quote.allowed) {
      return ActionOutcome.nothing;
    }
    if (!_online) {
      _holdPhoto(const ChatBlock(ChatBlockKind.offline));
      return ActionOutcome.offline;
    }
    var attachmentId = photo.attachmentId;
    state = state.copyWith(
      photo: photo.copyWith(
        stage: attachmentId == null
            ? PhotoStage.uploading
            : PhotoStage.starting,
        progress: 0,
        canceled: false,
      ),
      clearBlock: true,
    );
    try {
      if (attachmentId == null) {
        AssistantUploadTarget? target;
        for (var attempt = 0; target == null; attempt++) {
          try {
            target = await _repo.createUpload(
              quoteId: quote!.quoteId,
              mime: photo.mime,
              bytes: bytes.length,
              sha256: photo.sha256,
              retention: retentionFor(keep: photo.keep),
              requestId: _newId(),
              locale: _locale,
            );
          } on AssistantException catch (e) {
            if (attempt > 0 || !_staleQuote(e.reason)) rethrow;
            quote = await _requote(photo);
            if (quote == null) return ActionOutcome.nothing;
          }
        }
        if (state.photo?.stage != PhotoStage.uploading) {
          return ActionOutcome.nothing;
        }
        final upload = _uploader.start(target.uploadPath, bytes, target.mime);
        _upload = upload;
        final progress = upload.progress.listen((v) {
          final current = state.photo;
          if (current != null && current.stage == PhotoStage.uploading) {
            state = state.copyWith(photo: current.copyWith(progress: v));
          }
        }, onError: (Object _) {});
        try {
          await upload.done;
        } finally {
          unawaited(progress.cancel());
          _upload = null;
        }
        attachmentId = target.attachmentId;
        _photos.put(attachmentId, bytes);
        state = state.copyWith(
          photo: state.photo?.copyWith(
            stage: PhotoStage.starting,
            progress: 1,
            attachmentId: attachmentId,
            quote: quote,
          ),
        );
      }
      return await _startPhoto(photo, quote!, attachmentId);
    } on UploadCanceled {
      // Nothing started: nothing charged; the photo stays chosen.
      final current = state.photo;
      if (current != null) {
        state = state.copyWith(
          photo: current.copyWith(stage: PhotoStage.ready, canceled: true),
        );
      }
      return ActionOutcome.nothing;
    } on AssistantException catch (e) {
      // The pool may have moved since the quote: the card shows the household's balance now.
      if (e.reason == AssistantReason.usageExhausted) unawaited(refreshUsage());
      _holdPhoto(switch (e.reason) {
        AssistantReason.usageExhausted => ChatBlock(
          ChatBlockKind.photoQuote,
          quote: quote,
        ),
        null => ChatBlock(
          e.offline ? ChatBlockKind.offline : ChatBlockKind.photoFailed,
        ),
        AssistantReason.aiUnavailable => const ChatBlock(
          ChatBlockKind.photoFailed,
        ),
        _ => _blockFor(e.reason),
      });
      return e.offline ? ActionOutcome.offline : ActionOutcome.failed;
    } on Object {
      _holdPhoto(const ChatBlock(ChatBlockKind.photoFailed));
      return ActionOutcome.failed;
    }
  }

  bool _staleQuote(AssistantReason? r) =>
      r == AssistantReason.quoteExpired || r == AssistantReason.quoteMismatch;

  /// A fresh image quote for [photo] (an expired one is never reused); null when refused.
  Future<AssistantQuote?> _requote(PendingPhoto photo) async {
    final q = await _repo.quote(
      scope: state.scope,
      conversationId: _privateConversation,
      modality: TaskModality.image,
      attachmentCount: 1,
      intentHint: photo.hint,
      locale: _locale,
    );
    _setUsage(q.usage);
    if (q.allowed) return q;
    _holdPhoto(
      q.reason == AssistantReason.usageExhausted
          ? ChatBlock(ChatBlockKind.photoQuote, quote: q)
          : _blockFor(q.reason),
    );
    return null;
  }

  Future<ActionOutcome> _startPhoto(
    PendingPhoto photo,
    AssistantQuote quote,
    String attachmentId,
  ) async {
    var q = quote;
    for (var attempt = 0; ; attempt++) {
      try {
        final a = await _repo.start(
          requestId: photo.requestId,
          scope: state.scope,
          // Photo tasks are private (a photo may be a receipt, D-075 #2).
          conversationId: _privateConversation,
          quoteId: q.quoteId,
          text: null,
          attachmentIds: [attachmentId],
          locale: _locale,
        );
        _setUsage(a.usage);
        final snapshot = a.snapshot;
        if (a.status == ResponseStatus.blocked ||
            snapshot == null ||
            snapshot.task.state == TaskState.blocked) {
          // Kept with its uploaded photo: a resume starts the same task once (no new upload).
          if (snapshot?.task.conversationId case final c?
              when state.conversationId == null) {
            state = state.copyWith(conversationId: c);
            _persistThread();
          }
          final reason = a.reason ?? snapshot?.task.error;
          _holdPhoto(switch (reason) {
            null || AssistantReason.usageExhausted => ChatBlock(
              ChatBlockKind.photoQuote,
              quote: q,
            ),
            AssistantReason.aiUnavailable => const ChatBlock(
              ChatBlockKind.photoFailed,
            ),
            _ => _blockFor(reason),
          });
          return ActionOutcome.nothing;
        }
        _addThread(snapshot, null, photoIds: [attachmentId]);
        state = state.copyWith(clearPhoto: true, clearBlock: true);
        return ActionOutcome.ok;
      } on AssistantException catch (e) {
        if (attempt > 0 || !_staleQuote(e.reason)) rethrow;
        final fresh = await _requote(photo);
        if (fresh == null) return ActionOutcome.nothing;
        q = fresh;
      }
    }
  }

  /// CH10 "Huỷ" while uploading: the upload stops, nothing starts, 0 credits.
  Future<void> cancelUpload() async {
    await _upload?.cancel();
  }

  /// CH14 "Chụp lại" / CH25 "Thử lại" on a photo task: the same photo again when this phone
  /// still has it (a new quote, a new upload); false → the screen opens the picker.
  Future<bool> retryPhoto(String taskId) async {
    final ids = state.thread(taskId)?.attachmentIds ?? const <String>[];
    final bytes = ids.isEmpty ? null : _photos[ids.first];
    if (bytes == null || (state.photo?.busy ?? false)) return false;
    _usePhoto(
      PendingPhoto(
        name: 'photo.jpg',
        bytes: bytes,
        sha256: PickedPhoto(name: '', bytes: bytes).sha256,
        requestId: _newId(),
      ),
    );
    await _quotePhoto();
    return true;
  }

  /// The local thumbnail of a photo sent from this phone (null → a placeholder).
  Uint8List? photoBytes(String attachmentId) => _photos[attachmentId];

  /// CH03 deleted the open conversation (confirmed by the server): start a new one.
  void conversationDeleted(String conversationId) {
    if (state.conversationId == conversationId) newConversation();
  }

  /// "Bỏ ảnh" / "Nhập tay": the photo is dropped (an upload in flight stops; never started).
  void removePhoto() {
    if (state.photo?.stage == PhotoStage.starting) return;
    unawaited(_upload?.cancel());
    state = state.copyWith(clearPhoto: true, clearBlock: true);
  }

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
    DraftPayload payload, {

    /// The fields the person just checked (CH11 date row: `date` only); default every
    /// uncertain or missing field (the whole form was in front of them).
    List<String>? confirmed,
  }) async {
    final problems = draftProblems(payload, _now());
    if (problems.isNotEmpty) return (ActionOutcome.failed, problems);
    if (!_online) return (ActionOutcome.offline, const <DraftProblem>[]);
    try {
      final next = await _repo.patchDraft(
        draftId: d.id,
        expectedRevision: d.revision,
        payload: payload,
        confirmedFields:
            confirmed ?? {...d.uncertainFields, ...d.missingFields}.toList(),
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

  /// CH11 "Vẫn lưu" on a suspected duplicate: saved separately, never merged.
  void acknowledge(String draftId) =>
      state = state.copyWith(acknowledged: {...state.acknowledged, draftId});

  /// One card's own save ("Lưu chi tiêu", "Lưu ghi nhận"); a duplicate the person answered
  /// "Vẫn lưu" goes with its acknowledgement.
  Future<ActionOutcome> saveOne(String taskId, AssistantDraft d) => confirm(
    taskId,
    drafts: [d],
    acknowledge: {
      if (state.acknowledged.contains(d.id))
        d.id: [
          for (final w in d.warnings)
            if (w == DraftWarning.duplicateSuspected) w,
        ],
    },
  );

  Future<ActionOutcome> _careCall(
    String key,
    String taskId,
    Future<void> Function() call,
  ) async {
    if (state.busy.contains(key)) return ActionOutcome.nothing;
    if (!_online) return ActionOutcome.offline;
    state = state.copyWith(busy: {...state.busy, key});
    try {
      await call();
      return ActionOutcome.ok;
    } on AssistantException catch (e) {
      if (e.offline) return ActionOutcome.offline;
      unawaited(_refresh(taskId));
      return e.reason == AssistantReason.invalidState ||
              e.reason == AssistantReason.domainConflict
          ? ActionOutcome.stale
          : ActionOutcome.failed;
    } on Object {
      return ActionOutcome.failed;
    } finally {
      state = state.copyWith(busy: {...state.busy}..remove(key));
    }
  }

  void _putCare(
    String taskId,
    AssistantCareView Function(AssistantCareView) f,
  ) {
    final s = state.thread(taskId)?.snapshot;
    final care = s?.task.care;
    if (s == null || care == null) return;
    _putSnapshot(s.copyWith(task: s.task.copyWith(care: f(care))));
  }

  /// CH16 "Thử tối nay": an intention (`planAssistantActivity`), never "đã thử"; 0 credits.
  Future<ActionOutcome> planActivity(String taskId, ApprovedContentPart c) =>
      _careCall('plan:$taskId', taskId, () async {
        final plan = await _repo.plan(
          taskId: taskId,
          contentId: c.contentId,
          contentVersion: c.contentVersion,
          requestId: _newId(),
          locale: _locale,
        );
        if (plan != null) _putCare(taskId, (care) => care.copyWith(plan: plan));
        unawaited(_refresh(taskId));
      });

  /// CH17: the answer after the chance to try ("Chưa thử" included); 0 credits, no model.
  Future<ActionOutcome> sendFeedback(
    String taskId,
    CareFollowUp f,
    FeedbackOutcome outcome,
  ) => _careCall('fb:$taskId', taskId, () async {
    await _repo.feedback(
      taskId: taskId,
      contentId: f.contentId,
      contentVersion: f.contentVersion,
      outcome: outcome,
      locale: _locale,
    );
    _putCare(
      taskId,
      (care) => care.copyWith(
        clearFollowUp: true,
        feedback: (
          contentId: f.contentId,
          contentVersion: f.contentVersion,
          outcome: outcome,
        ),
      ),
    );
    unawaited(_refresh(taskId));
  });

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
