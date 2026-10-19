import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/environment.dart';
import '../../app/locale.dart';
import '../../app/providers.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../baby/baby_models.dart';
import '../memories/media_picker.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/upload_queue.dart';
import 'auto_save_engine.dart';
import 'auto_save_native.dart';
import 'auto_save_store.dart';

/// Tự lưu kỷ niệm (D-066): scans new library items on this phone, suggests the ones that may
/// show a baby, and queues what the parent approves. Checks run when the app opens and stop
/// when it leaves (AR01); background checks and the push come in M2.

final autoSaveNativeProvider = Provider<AutoSaveNative>(
  (ref) => AutoSaveNative(),
);

final autoSaveStoreProvider = Provider<AutoSaveStore>((ref) {
  final native = ref.watch(autoSaveNativeProvider);
  return AutoSaveStore(onCreated: native.excludeFromBackup);
});

/// Reads a library original for upload (it may come down from iCloud first); replaced in tests.
final libraryResolverProvider =
    Provider<Future<PickedMedia?> Function(String id)>(
      (ref) => pickedFromLibrary,
    );

/// Sends one beta counter (P-148) through `recordAppEvent`; replaced in tests.
final autoSaveEventSinkProvider =
    Provider<Future<void> Function(String event, int n)>(
      (ref) =>
          (event, n) => ref
              .read(functionsProvider)
              .httpsCallable('recordAppEvent')
              .call<Object?>({'event': event, 'n': n}),
    );

/// Knobs for matching and grouping; guesses until the beta measures them (P-146, P-149).
final autoSaveTuningProvider = Provider<AutoSaveTuning>(
  (ref) => const AutoSaveTuning(),
);

/// "640 / 1.380 tệp" (AS06, AS17).
@immutable
class ScanProgress {
  const ScanProgress(this.checked, this.total);
  final int checked;
  final int total;
  double get value => total == 0 ? 0 : checked / total;
}

@immutable
class AutoSaveView {
  const AutoSaveView({
    this.loaded = false,
    this.state = const AutoSaveState(),
    this.access = LibraryAccess.notDetermined,
    this.scan,
    this.trace = const [],
    this.fromHistory,
  });

  final bool loaded;
  final AutoSaveState state;
  final LibraryAccess access;

  /// Null when no check is running.
  final ScanProgress? scan;

  /// The last checks' items, newest first (dev diagnostics).
  final List<AutoSaveTrace> trace;

  /// How the last check found new items: the library's change history (true) or by date.
  final bool? fromHistory;

  /// Set up and switched on (the consent is part of setup).
  bool get active => state.enabled && state.consented;

  bool get canRead =>
      access == LibraryAccess.full || access == LibraryAccess.limited;

  /// Pending suggestions as AS07 tiles; for one baby when [babyId] is given.
  List<SuggestionGroup> groups([String? babyId]) => groupAndRank([
    for (final c in state.pending)
      if (babyId == null || c.match.babyId == babyId) c,
  ]);

  /// "42 mục trong tháng 10" (AS12), counted on this phone.
  int savedIn(DateTime month) => state.savedByMonth[autoSaveMonth(month)] ?? 0;

  int pendingFor([String? babyId]) => babyId == null
      ? state.pending.length
      : state.pending.where((c) => c.match.babyId == babyId).length;
}

/// One library item looked at in a check and what became of it (AS19 dev diagnostics). Kept in
/// memory only, never saved or sent.
@immutable
class AutoSaveTrace {
  const AutoSaveTrace({
    required this.assetId,
    required this.reason,
    this.video = false,
    this.distance,
    this.threshold,
    this.captureAt,
    this.faces = const [],
    this.frames,
    this.name,
  });
  final String assetId;
  final String? name;
  final bool video;
  final DateTime? captureAt;

  /// Face sizes found (share of the image), largest first.
  final List<double> faces;

  /// Videos: frames read (0: poster frame only).
  final int? frames;

  /// A [MatchReason] name, or `utility`, `unreadable`, `handled`.
  final String reason;
  final double? distance;
  final double? threshold;
}

/// What "Bỏ qua lần này" and "Không phải ảnh của bé" undo ("Hoàn tác", AR08).
@immutable
class AutoSaveUndo {
  const AutoSaveUndo(this._before);
  final AutoSaveState _before;
}

/// True in the engine iOS starts only for a background check (auto_save_background.dart).
final autoSaveHeadlessProvider = Provider<bool>((ref) => false);

/// The "Có 8 ảnh mới có thể có Teddy" notification (AR03).
@immutable
class AutoSaveNote {
  const AutoSaveNote({
    required this.title,
    required this.body,
    required this.at,
  });
  final String title;
  final String body;

  /// When to show it: now, or 07:00 when found during the night.
  final DateTime at;
}

/// Quiet hours, the same as reminders' "Không nhắc ban đêm" (22:00 – 06:00).
bool isQuietHour(DateTime t) => t.hour >= 22 || t.hour < 6;

/// Whether new suggestions earn a notification: on in AS19, at most one a day, never in quiet
/// hours (a find at night is told at 07:00).
AutoSaveNote? autoSaveNote({
  required AutoSaveState state,
  required List<Candidate> fresh,
  required DateTime now,
  required AppLocalizations l10n,
}) {
  if (fresh.isEmpty || !state.notify || !state.enabled) return null;
  var at = now;
  if (isQuietHour(now)) {
    final day = now.hour >= 22 ? now.add(const Duration(days: 1)) : now;
    at = DateTime(day.year, day.month, day.day, 7);
  }
  final last = state.notifiedAt;
  if (last != null &&
      last.year == at.year &&
      last.month == at.month &&
      last.day == at.day) {
    return null;
  }
  final babies = {for (final c in fresh) c.match.babyId};
  final names = [
    for (final id in babies)
      if (state.names[id] case final n? when n.isNotEmpty) n,
  ];
  final who = names.isEmpty
      ? l10n.autoSaveYourBaby
      : names.length == 1
      ? names.single
      : l10n.autoSaveAnd(
          names.sublist(0, names.length - 1).join(', '),
          names.last,
        );
  return AutoSaveNote(
    title: l10n.autoSavePushTitle(fresh.length, who),
    body: l10n.autoSavePushBody,
    at: at,
  );
}

final autoSaveProvider = NotifierProvider<AutoSaveController, AutoSaveView>(
  AutoSaveController.new,
);

class AutoSaveController extends Notifier<AutoSaveView> {
  var _s = const AutoSaveState();
  var _access = LibraryAccess.notDetermined;
  ScanProgress? _scan;
  Future<void>? _loading;
  Future<void>? _running;
  var _stop = false;
  final _trace = <AutoSaveTrace>[];
  bool? _fromHistory;
  AppLifecycleListener? _lifecycle;

  static const _batch = 24;

  /// How far back each check looks (by date taken or date added).
  static const _window = Duration(days: 30);
  static const _maxApprovedSamples = 40;
  static const _maxNegatives = 50;

  /// The server's `memoryLimits.batchPartsMax`; a longer run starts a new batch.
  static const _maxBatchParts = 1000;

  AutoSaveNative get _native => ref.read(autoSaveNativeProvider);

  /// Dev builds keep a diagnostics file of the last check (never in production builds).
  bool get _devTrace {
    try {
      return ref.read(environmentProvider) == AppEnvironment.dev;
    } on Object {
      return false;
    }
  }

  AutoSaveStore get _store => ref.read(autoSaveStoreProvider);

  @override
  AutoSaveView build() {
    final headless = ref.read(autoSaveHeadlessProvider);
    if (_native.supported) {
      if (!headless) {
        // AR01: check quietly whenever the app comes back; stop when it leaves.
        _lifecycle = AppLifecycleListener(
          onResume: () => unawaited(scan()),
          onHide: stop,
        );
        ref.onDispose(() => _lifecycle?.dispose());
      }
      // AR03: iOS may ask for a check while the app is in the background or closed.
      _native.listen(onCheck: backgroundCheck, onStop: stop);
      unawaited(_native.backgroundReady(headless: headless));
    }
    if (!headless) unawaited(_load().then((_) => scan()).then((_) => _flush()));
    return const AutoSaveView();
  }

  Future<void> ready() => _load();

  Future<void> _load() => _loading ??= () async {
    var s = await _store.load();
    final now = DateTime.now();
    // P-147: face data goes 30 days after Tự lưu was turned off.
    if (!s.enabled &&
        s.offAt != null &&
        now.difference(s.offAt!) > const Duration(days: 30)) {
      s = s.wipeFaces();
      await _store.save(s);
    }
    final old = now.subtract(_window + const Duration(days: 15));
    _s = s.copyWith(
      seen: {
        for (final e in s.seen.entries)
          if (e.value.isAfter(old)) e.key: e.value,
      },
    );
    _access = await _native.access();
    _publish();
  }();

  void _publish() {
    if (!ref.mounted) return;
    state = AutoSaveView(
      loaded: true,
      state: _s,
      access: _access,
      scan: _scan,
      trace: List.unmodifiable(_trace),
      fromHistory: _fromHistory,
    );
  }

  Future<void> _save() async {
    _publish();
    try {
      await _store.save(_s);
    } on Object {
      // The next change writes again; nothing the parent can do about it.
    }
  }

  /// Babies this account may turn Tự lưu on for: Cùng nuôi only (AS03). Null in a background
  /// check, which has no session: the babies set up on this phone are used as they are.
  Set<String>? _parentOf() {
    if (ref.read(autoSaveHeadlessProvider)) return null;
    final session = ref.read(sessionProvider);
    if (session is! SessionSignedIn) return const {};
    return {
      for (final m in session.active)
        if (m.role == MemberRole.coParent) m.babyId,
    };
  }

  // ---------- Permission ----------

  Future<LibraryAccess> refreshAccess() async {
    _access = await _native.access();
    _publish();
    return _access;
  }

  Future<LibraryAccess> requestAccess() async {
    _access = await _native.requestAccess();
    _publish();
    return _access;
  }

  Future<void> pickMore() async {
    await _native.pickMore();
    await scan();
  }

  // ---------- Samples (AS04, AS15, AS19) ----------

  /// The largest face of a photo as a sample, or null when no face is clear enough.
  SampleFace? _sampleOf(AssetInfo? info, String source) {
    if (info == null || info.unreadable) return null;
    final minSize = ref.read(autoSaveTuningProvider).minFaceSize;
    final faces = [
      for (final f in info.faces)
        if (f.print != null && f.size >= minSize) f,
    ]..sort((a, b) => b.size.compareTo(a.size));
    if (faces.isEmpty) return null;
    return SampleFace(
      ref: source,
      print: faces.first.print!,
      addedAt: DateTime.now(),
    );
  }

  /// A Kỷ niệm photo already in the app's media cache.
  Future<SampleFace?> sampleFromFile(String mediaId, String path) async {
    try {
      return _sampleOf(await _native.analyzeFile(path), 'm:$mediaId');
    } on Object {
      return null;
    }
  }

  /// A photo from the device library.
  Future<SampleFace?> sampleFromLibrary(String assetId) async {
    try {
      final info = await _native.analyze([assetId]);
      return _sampleOf(info.firstOrNull, 'a:$assetId');
    } on Object {
      return null;
    }
  }

  /// Finishes setup (AS05): consent recorded, babies and their samples saved, the first check
  /// looks back to [scanFrom] (30 days, or since birth).
  Future<void> setUp({
    required Map<String, List<SampleFace>> samples,
    required DateTime scanFrom,
  }) async {
    await _load();
    _s = _s.copyWith(
      enabled: true,
      consentVersion: autoSaveConsentVersion,
      consentAt: DateTime.now(),
      clearOffAt: true,
      babies: {
        ..._s.babies,
        for (final e in samples.entries)
          e.key: (_s.babies[e.key] ?? const AutoSaveBaby()).copyWith(
            samples: e.value,
          ),
      },
      scanFrom: scanFrom,
    );
    _s = _s.copyWith(names: _names());
    await _save();
    unawaited(scan());
  }

  /// Replaces the samples a parent picked for a baby (approved ones stay) and looks back again.
  Future<void> setSamples(
    String babyId,
    List<SampleFace> picked,
    DateTime scanFrom,
  ) async {
    await _load();
    final baby = _s.babies[babyId] ?? const AutoSaveBaby();
    _s = _s.copyWith(
      babies: {
        ..._s.babies,
        babyId: baby.copyWith(
          samples: [
            ...picked,
            for (final s in baby.samples)
              if (s.approved) s,
          ],
        ),
      },
      seen: const {},
      scanFrom: scanFrom,
    );
    await _save();
    unawaited(scan());
  }

  /// AS19 "Thêm bé" without samples yet (AS15 "chưa có ảnh mẫu · tạm tắt").
  Future<void> addBaby(String babyId) async {
    await _load();
    if (_s.babies.containsKey(babyId)) return;
    _s = _s.copyWith(babies: {..._s.babies, babyId: const AutoSaveBaby()});
    await _save();
  }

  Future<void> removeBaby(String babyId) async {
    await _load();
    _s = _s.copyWith(
      babies: {..._s.babies}..remove(babyId),
      pending: [
        for (final c in _s.pending)
          if (c.match.babyId != babyId) c,
      ],
    );
    await _save();
  }

  // ---------- Settings (AS19) ----------

  Future<void> setEnabled(bool on) async {
    await _load();
    if (on && !_s.consented) return;
    _s = _s.copyWith(
      enabled: on,
      offAt: on ? null : DateTime.now(),
      clearOffAt: on,
    );
    if (!on) {
      stop();
      _count('autoSaveTurnedOff');
    }
    await _save();
    if (on) {
      unawaited(scan());
    } else {
      unawaited(_native.unschedule());
    }
  }

  Future<void> setKinds({bool? photos, bool? videos}) async {
    await _load();
    _s = _s.copyWith(photos: photos, videos: videos);
    await _save();
  }

  Future<void> setNotify(bool on) async {
    await _load();
    _s = _s.copyWith(notify: on);
    await _save();
  }

  /// "Xoá ảnh mẫu và dữ liệu gợi ý": face numbers, suggestions and the consent go at once.
  Future<void> wipe() async {
    await _load();
    stop();
    _s = _s.wipeFaces();
    _count('autoSaveWiped');
    await _save();
    unawaited(_native.unschedule());
    unawaited(_flush());
  }

  // ---------- Background check (AR03) ----------

  /// Nicknames for the notification text, kept up to date while the app runs.
  Map<String, String> _names() {
    if (ref.read(autoSaveHeadlessProvider)) return _s.names;
    return {
      ..._s.names,
      for (final id in _s.babies.keys)
        id: ?ref.read(babyProvider(id)).value?.nickname,
    };
  }

  Locale _locale() {
    try {
      final chosen = ref.read(localeOverrideProvider);
      if (chosen != null) return chosen;
    } on Object {
      // No preferences in this engine: follow the phone.
    }
    return resolveLocale(WidgetsBinding.instance.platformDispatcher.locales);
  }

  /// A check iOS asked for: new suggestions may earn one notification (AR03).
  Future<Map<String, Object?>?> backgroundCheck() async {
    await _load();
    final before = {for (final c in _s.pending) c.asset.id};
    _count('autoSaveBackgroundCheck');
    await scan();
    final fresh = [
      for (final c in _s.pending)
        if (!before.contains(c.asset.id)) c,
    ];
    final now = DateTime.now();
    final note = autoSaveNote(
      state: _s,
      fresh: fresh,
      now: now,
      l10n: lookupAppLocalizations(_locale()),
    );
    if (note == null) {
      await _save();
      return null;
    }
    _s = _s.copyWith(notifiedAt: note.at);
    _count('autoSaveNotified');
    await _save();
    return {
      'title': note.title,
      'body': note.body,
      if (note.at.isAfter(now)) 'at': note.at.millisecondsSinceEpoch,
    };
  }

  /// The `auto_save` rollout answer for a baby (P-148). Turned on: check now; off everywhere
  /// (the kill switch): no more background checks.
  Future<void> rememberAllowed(String babyId, bool on) async {
    await _load();
    if (_s.allowed[babyId] == on) return;
    _s = _s.copyWith(allowed: {..._s.allowed, babyId: on});
    await _save();
    if (on) {
      unawaited(scan());
    } else if (!_s.allowed.values.any((v) => v)) {
      stop();
      unawaited(_native.unschedule());
    }
  }

  /// AR02 "Để sau": the banner waits for new suggestions.
  Future<void> hideBanner() async {
    await _load();
    _s = _s.copyWith(bannerHidden: {for (final c in _s.pending) c.asset.id});
    await _save();
  }

  // ---------- Checking ----------

  void stop() => _stop = true;

  bool get _canScan =>
      _native.supported &&
      _s.enabled &&
      _s.consented &&
      (_s.photos || _s.videos) &&
      _s.babies.values.any((b) => b.samples.isNotEmpty);

  /// One check: new library items are described in small batches, matched against each baby's
  /// samples and added to the pending suggestions. Stops when the app leaves and carries on
  /// next time (already described items are skipped).
  /// While a check runs, asking again waits for it (the app opening and "Kiểm tra ảnh mới" can
  /// ask at the same time).
  Future<void> scan() =>
      _running ??= _scanOnce().whenComplete(() => _running = null);

  Future<void> _scanOnce() async {
    _stop = false;
    try {
      await _load();
      if (!_canScan) return;
      _access = await _native.access();
      if (_access != LibraryAccess.full && _access != LibraryAccess.limited) {
        return;
      }
      final parentOf = _parentOf();
      final babies = {
        for (final e in _s.babies.entries)
          if (e.value.samples.isNotEmpty &&
              _s.allowed[e.key] == true &&
              (parentOf == null || parentOf.contains(e.key)))
            e.key: e.value.faces,
      };
      if (babies.isEmpty) return;
      await _check(babies);
    } on Object {
      // The library could not be read this time; the next open tries again.
    } finally {
      _scan = null;
      _publish();
    }
  }

  Future<void> _check(Map<String, BabyFaces> babies) async {
    final tuning = ref.read(autoSaveTuningProvider);
    final now = DateTime.now();
    {
      // Every check lists what was taken or added in the last 30 days (or since setup's start)
      // and leaves out what it already looked at. iOS's change history reported nothing new
      // for videos and photos saved from Zalo on the owner's phone (2026-10-14), so it is not
      // used: listing ids by date is cheap, and an item saved today with an old date taken
      // still counts by its modification date.
      final window = now.subtract(_window);
      final from = _s.scanFrom;
      final changes = await _native.changes(
        since: from != null && from.isBefore(window) ? from : window,
        photos: _s.photos,
        videos: _s.videos,
      );
      // Checked with an older pass: everything listed is looked at once more.
      final recheck = _s.videoPass < autoSaveVideoPass
          ? changes.ids.toSet()
          : const <String>{};
      _fromHistory = changes.fromHistory;
      final waiting = {for (final c in _s.pending) c.asset.id};
      final listed = {...changes.ids, ...recheck};
      final skipped = {
        'seen': listed
            .where((id) => _s.seen.containsKey(id) && !recheck.contains(id))
            .length,
        'handled': listed.where(_s.handled).length,
        'waiting': listed.where(waiting.contains).length,
      };
      final todo = [
        for (final id in {...changes.ids, ...recheck})
          if ((!_s.seen.containsKey(id) || recheck.contains(id)) &&
              !_s.handled(id) &&
              !waiting.contains(id))
            id,
      ];
      _scan = ScanProgress(0, todo.length);
      _publish();
      var checked = 0;
      for (var i = 0; i < todo.length; i += _batch) {
        if (_stop || !ref.mounted) break;
        final ids = todo.sublist(i, math.min(i + _batch, todo.length));
        final infos = await _native.analyze(ids);
        final seen = {..._s.seen};
        final pending = [..._s.pending];
        for (final a in infos) {
          // When it was looked at: kept a little longer than the window.
          seen[a.id] = now;
          if (a.unreadable) {
            _note(a, 'unreadable');
            continue;
          }
          final why = explainMatch(a, babies, tuning: tuning);
          // "Utility" (documents, screenshots of things) only explains a miss: a photo with a
          // face like the baby is suggested anyway, parents review it (D-066 #8).
          if (a.utility && why.reason != MatchReason.match) {
            _note(a, 'utility', why);
            continue;
          }
          final m = why.reason == MatchReason.match
              ? matchBaby(a, babies, tuning: tuning)
              : null;
          if (m == null || _s.handled(a.id, m.babyId)) {
            _note(a, m == null ? why.reason.name : 'handled', why);
            continue;
          }
          _note(a, 'match', why);
          pending.add(Candidate(asset: a, match: m));
          _count('autoSaveSuggested');
        }
        for (final id in ids) {
          seen.putIfAbsent(id, () => now);
        }
        checked += ids.length;
        _s = _s.copyWith(seen: seen, pending: pending);
        _scan = ScanProgress(checked, todo.length);
        await _save();
      }
      if (_devTrace) {
        unawaited(
          _store.saveTrace({
            'at': now.toIso8601String(),
            'fromHistory': changes.fromHistory,
            'inserted': changes.inserted,
            'listed': changes.ids.length,
            'listedVideos': changes.videos,
            'recheckVideos': recheck.length,
            'todo': todo.length,
            'skipped': skipped,
            'stopped': _stop,
            'thresholds': {
              for (final e in babies.entries) e.key: e.value.threshold(tuning),
            },
            'items': [
              for (final t in _trace.take(checked))
                {
                  'id': t.assetId,
                  'name': t.name,
                  'video': t.video,
                  'captureAt': t.captureAt?.toIso8601String(),
                  'reason': t.reason,
                  'distance': t.distance,
                  'threshold': t.threshold,
                  'faces': t.faces,
                  'frames': t.frames,
                },
            ],
          }),
        );
      }
      if (!_stop) {
        _s = _s.copyWith(
          token: changes.token,
          lastScanAt: now,
          lastScanCount: todo.length,
          clearScanFrom: true,
          names: _names(),
          videoPass: autoSaveVideoPass,
        );
        await _save();
        unawaited(_native.schedule());
      }
    }
  }

  /// Dev diagnostics "Kiểm tra lại 30 ngày gần nhất": forgets what was looked at and checks the
  /// last 30 days again (suggestions already waiting, uploads and skips are kept).
  Future<void> rescan() async {
    await _load();
    // A check already running (the app just came back) finishes first; asking during it used to
    // be swallowed by it.
    final running = _running;
    if (running != null) {
      stop();
      await running;
    }
    _s = _s.copyWith(
      seen: const {},
      scanFrom: DateTime.now().subtract(_window),
    );
    _trace.clear();
    await _save();
    await scan();
    if (_devTrace) await _inspect();
  }

  /// Dev diagnostics (`inspect.json`): the newest library items with file names, what the
  /// filter makes of them, whether a check looked at them, and what matching says now.
  Future<void> _inspect() async {
    try {
      final recent = await _native.inspectRecent();
      final waiting = {for (final c in _s.pending) c.asset.id};
      final ids = [
        for (final r in recent)
          if (r['passes'] == true && !waiting.contains(r['id']))
            r['id']! as String,
      ];
      final infos = {for (final a in await _native.analyze(ids)) a.id: a};
      final tuning = ref.read(autoSaveTuningProvider);
      final babies = {
        for (final e in _s.babies.entries)
          if (e.value.samples.isNotEmpty) e.key: e.value.faces,
      };
      await _store.saveTrace({
        'at': DateTime.now().toIso8601String(),
        'items': [
          for (final r in recent)
            {
              ...r,
              'seen': _s.seen.containsKey(r['id']),
              'waiting': waiting.contains(r['id']),
              'ledger': _s.ledger[r['id']]?.map((k, v) => MapEntry(k, v.code)),
              if (infos[r['id']] case final a?) ...{
                'faces': [for (final f in a.faces) f.size],
                'frames': a.frames,
                'utility': a.utility,
                'unreadable': a.unreadable,
                if (explainMatch(a, babies, tuning: tuning) case final why)
                  'match': {
                    'reason': why.reason.name,
                    'distance': why.distance,
                    'threshold': why.threshold,
                  },
              },
            },
        ],
      }, name: 'inspect.json');
    } on Object {
      // Diagnostics only.
    }
  }

  void _note(AssetInfo a, String reason, [MatchTrace? why]) {
    _trace.insert(
      0,
      AutoSaveTrace(
        assetId: a.id,
        video: a.video,
        reason: reason,
        distance: why?.distance,
        threshold: why?.threshold,
        captureAt: a.captureAt,
        faces: [for (final f in a.faces) f.size],
        frames: a.frames,
        name: a.name,
      ),
    );
    if (_trace.length > 500) _trace.removeRange(500, _trace.length);
  }

  // ---------- Review (AS07 – AS10) ----------

  /// Queues the chosen suggestions (one batch per baby, as memories split by the per-add limit,
  /// R-102; one family notice per batch, D-070) and marks the others of this review as seen so
  /// they are not suggested again. Approved faces
  /// become extra samples (P-149). Returns how many items were queued.
  Future<int> approve({
    required List<Candidate> chosen,
    required List<Candidate> reviewed,
    required Audience audience,
    required bool notifyFamily,
    void Function(int done, int total)? onPrepared,
  }) async {
    await _load();
    final perAdd = ref.read(publicLimitsProvider).value?.mediaItemsPerAdd ?? 30;
    final queue = ref.read(uploadQueueProvider.notifier);
    final byBaby = <String, List<Candidate>>{};
    for (final c in [
      ...chosen,
    ]..sort((a, b) => a.asset.captureAt.compareTo(b.asset.captureAt))) {
      (byBaby[c.match.babyId] ??= []).add(c);
    }
    var queued = 0, prepared = 0;
    final missing = <String>{};
    final resolve = ref.read(libraryResolverProvider);
    for (final entry in byBaby.entries) {
      // D-070: one batch per baby, sent as memories of up to `perAdd` items that share its id;
      // the last part says how many there are, so the family hears once, about all of them.
      var batchId = newBatchId();
      var parts = 0;
      var buffer = <PickedMedia>[];
      // The queue counts what is still to come, so the pill reads "x/69" from the first part;
      // enqueue takes off each part as it joins, a missing item is taken off here.
      queue.setPreparing(entry.key, entry.value.length);
      Future<void> send({required bool last}) async {
        parts++;
        final closes = last || parts == _maxBatchParts;
        await queue.enqueue(
          // The slow part is here (every photo re-encoded, every video remuxed and given a
          // poster), so "Đang chuẩn bị 3/19" counts prepared files, not resolved ones.
          onPrepared: (_, _) => onPrepared?.call(++prepared, chosen.length),
          babyId: entry.key,
          request: {
            'babyId': entry.key,
            'memoryId': newMemoryId(),
            'batchId': batchId,
            'batchParts': closes ? parts : null,
            'caption': null,
            'audience': audience.name,
            'notifyFamily': audience == Audience.family && notifyFamily,
            'dateMode': 'capture',
            'date': null,
            'milestone': null,
            'albumIds': const <String>[],
          },
          picked: buffer,
        );
        queued += buffer.length;
        buffer = [];
        if (closes) {
          batchId = newBatchId();
          parts = 0;
        }
      }

      try {
        for (final c in entry.value) {
          PickedMedia? p;
          try {
            p = await resolve(c.asset.id);
          } on Object {
            p = null;
          }
          if (p == null) {
            missing.add(c.asset.id);
            queue.addPreparing(entry.key, -1);
            onPrepared?.call(++prepared, chosen.length);
            continue;
          }
          // A full part goes once another item follows it, so the last one is always known.
          if (buffer.length == perAdd) await send(last: false);
          buffer.add(p);
        }
        if (buffer.isNotEmpty) await send(last: true);
      } finally {
        queue.setPreparing(entry.key, 0);
      }
    }
    final chosenIds = {for (final c in chosen) c.asset.id};
    final reviewedIds = {for (final c in reviewed) c.asset.id};
    final ledger = _copyLedger();
    for (final c in reviewed) {
      if (!chosenIds.contains(c.asset.id)) {
        (ledger[c.asset.id] ??= {})[c.match.babyId] = LedgerState.skipped;
      }
    }
    final babies = {..._s.babies};
    for (final c in chosen) {
      if (missing.contains(c.asset.id)) continue;
      final print = c.asset.faces.elementAtOrNull(c.match.face)?.print;
      final baby = babies[c.match.babyId];
      if (print == null || baby == null) continue;
      final approved =
          [
            for (final s in baby.samples)
              if (s.approved) s,
            SampleFace(
              ref: 'a:${c.asset.id}',
              print: print,
              approved: true,
              addedAt: c.asset.captureAt,
            ),
          ]..sort(
            (a, b) =>
                (b.addedAt ?? DateTime(0)).compareTo(a.addedAt ?? DateTime(0)),
          );
      babies[c.match.babyId] = baby.copyWith(
        samples: [...baby.picked, ...approved.take(_maxApprovedSamples)],
      );
    }
    final month = _month(DateTime.now());
    _s = _s.copyWith(
      ledger: ledger,
      babies: babies,
      pending: [
        for (final c in _s.pending)
          if (!reviewedIds.contains(c.asset.id) || missing.contains(c.asset.id))
            c,
      ],
      savedByMonth: {
        ..._s.savedByMonth,
        month: (_s.savedByMonth[month] ?? 0) + queued,
      },
    );
    _count('autoSaveApproved', queued);
    _count('autoSaveUnticked', reviewed.length - chosen.length);
    await _save();
    unawaited(_flush());
    return queued;
  }

  /// AR08 "Bỏ qua lần này": the whole batch is never suggested again; [undo] brings it back.
  Future<AutoSaveUndo> skip(List<Candidate> items) async {
    await _load();
    final before = _s;
    final ids = {for (final c in items) c.asset.id};
    final ledger = _copyLedger();
    for (final c in items) {
      (ledger[c.asset.id] ??= {})[c.match.babyId] = LedgerState.skipped;
    }
    _s = _s.copyWith(
      ledger: ledger,
      pending: [
        for (final c in _s.pending)
          if (!ids.contains(c.asset.id)) c,
      ],
    );
    _count('autoSaveSkipped', items.length);
    await _save();
    return AutoSaveUndo(before);
  }

  /// AS08 / AS09 "Không phải ảnh của bé": out of the suggestions, and its face becomes an
  /// example of someone else for this baby.
  Future<AutoSaveUndo> reject(Candidate c) async {
    await _load();
    final before = _s;
    final ledger = _copyLedger();
    (ledger[c.asset.id] ??= {})[c.match.babyId] = LedgerState.rejected;
    final print = c.asset.faces.elementAtOrNull(c.match.face)?.print;
    final baby = _s.babies[c.match.babyId];
    _s = _s.copyWith(
      ledger: ledger,
      pending: [
        for (final p in _s.pending)
          if (p.asset.id != c.asset.id) p,
      ],
      babies: print == null || baby == null
          ? null
          : {
              ..._s.babies,
              c.match.babyId: baby.copyWith(
                negatives: [print, ...baby.negatives.take(_maxNegatives - 1)],
              ),
            },
    );
    _count('autoSaveRejected');
    await _save();
    return AutoSaveUndo(before);
  }

  Future<void> undo(AutoSaveUndo u) async {
    _s = u._before;
    await _save();
  }

  /// AS09: the photo is for another baby (one baby per photo, D-066 #7).
  Future<void> reassign(String assetId, String babyId) async {
    await _load();
    _s = _s.copyWith(
      pending: [
        for (final c in _s.pending)
          c.asset.id == assetId
              ? Candidate(
                  asset: c.asset,
                  match: FaceMatch(
                    babyId: babyId,
                    distance: c.match.distance,
                    face: c.match.face,
                  ),
                )
              : c,
      ],
    );
    await _save();
  }

  // ---------- Ledger (P-150) ----------

  /// Items queued for upload, by Tự lưu or by hand.
  Future<void> recordUploaded(List<String> assetIds, String babyId) =>
      _record(assetIds, babyId, LedgerState.uploaded);

  /// Items saved to the library from Child Life.
  Future<void> recordFromApp(String assetId) =>
      _record([assetId], '*', LedgerState.fromApp);

  Future<void> _record(List<String> ids, String babyId, LedgerState st) async {
    try {
      // The ledger only serves Tự lưu, which exists on iOS (D-066 #3).
      if (!_native.supported) return;
      await _load();
      if (st == LedgerState.uploaded && _s.enabled) {
        // A photo a check had looked at, never suggested, then added by hand: a miss (P-148).
        final waiting = {for (final c in _s.pending) c.asset.id};
        _count(
          'autoSaveMissed',
          [
            for (final id in ids)
              if (_s.seen.containsKey(id) &&
                  !waiting.contains(id) &&
                  !_s.handled(id))
                id,
          ].length,
        );
      }
      final ledger = _copyLedger();
      for (final id in ids) {
        (ledger[id] ??= {})[babyId] = st;
      }
      final done = ids.toSet();
      _s = _s.copyWith(
        ledger: ledger,
        pending: [
          for (final c in _s.pending)
            if (!done.contains(c.asset.id) ||
                (babyId != '*' && c.match.babyId != babyId))
              c,
        ],
      );
      await _save();
    } on Object {
      // Never block an upload or a download over the ledger.
    }
  }

  // ---------- Beta counters (P-148) ----------

  /// Counts [n] of [event] for the next send; saved with the state.
  void _count(String event, [int n = 1]) {
    if (n <= 0) return;
    _s = _s.copyWith(
      unsent: {..._s.unsent, event: (_s.unsent[event] ?? 0) + n},
    );
  }

  /// Counts an event from a screen (setup steps, photo access) and sends what waits.
  Future<void> track(String event, [int n = 1]) async {
    await _load();
    _count(event, n);
    await _save();
    unawaited(_flush());
  }

  /// Sends waiting counters; whatever fails waits for the next time. Not from a background
  /// check, which has no Firebase.
  Future<void> _flush() async {
    if (ref.read(autoSaveHeadlessProvider) || !ref.mounted) return;
    final send = ref.read(autoSaveEventSinkProvider);
    for (final e in {..._s.unsent}.entries) {
      try {
        await send(e.key, e.value.clamp(1, 1000));
      } on Object {
        continue;
      }
      final left = (_s.unsent[e.key] ?? 0) - e.value;
      _s = _s.copyWith(
        unsent: {..._s.unsent}..update(e.key, (_) => left, ifAbsent: () => 0),
      );
      if (left <= 0) _s = _s.copyWith(unsent: {..._s.unsent}..remove(e.key));
    }
    await _save();
  }

  Map<String, Map<String, LedgerState>> _copyLedger() => {
    for (final e in _s.ledger.entries) e.key: {...e.value},
  };

  static String _month(DateTime d) => autoSaveMonth(d);
}

String autoSaveMonth(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';
