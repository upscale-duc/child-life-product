import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final bool loaded;
  final AutoSaveState state;
  final LibraryAccess access;

  /// Null when no check is running.
  final ScanProgress? scan;

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
  AppLifecycleListener? _lifecycle;

  static const _batch = 24;
  static const _maxApprovedSamples = 40;
  static const _maxNegatives = 50;

  AutoSaveNative get _native => ref.read(autoSaveNativeProvider);
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
    final old = now.subtract(const Duration(days: 90));
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
    state = AutoSaveView(loaded: true, state: _s, access: _access, scan: _scan);
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
      final from = _s.scanFrom;
      final changes = await _native.changes(
        token: from == null ? _s.token : null,
        since:
            from ??
            _s.lastScanAt?.subtract(const Duration(days: 1)) ??
            now.subtract(const Duration(days: 30)),
        photos: _s.photos,
        videos: _s.videos,
      );
      final waiting = {for (final c in _s.pending) c.asset.id};
      final todo = [
        for (final id in changes.ids)
          if (!_s.seen.containsKey(id) &&
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
          seen[a.id] = a.captureAt;
          if (a.unreadable || a.utility) continue;
          final m = matchBaby(a, babies, tuning: tuning);
          if (m == null || _s.handled(a.id, m.babyId)) continue;
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
      if (!_stop) {
        _s = _s.copyWith(
          token: changes.token,
          lastScanAt: now,
          lastScanCount: todo.length,
          clearScanFrom: true,
          names: _names(),
        );
        await _save();
        unawaited(_native.schedule());
      }
    }
  }

  // ---------- Review (AS07 – AS10) ----------

  /// Queues the chosen suggestions (one memory per baby, split by the per-add limit, R-102) and
  /// marks the others of this review as seen so they are not suggested again. Approved faces
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
    for (final entry in byBaby.entries) {
      for (var i = 0; i < entry.value.length; i += perAdd) {
        final part = entry.value.sublist(
          i,
          math.min(i + perAdd, entry.value.length),
        );
        final picked = <PickedMedia>[];
        final resolve = ref.read(libraryResolverProvider);
        for (final c in part) {
          PickedMedia? p;
          try {
            p = await resolve(c.asset.id);
          } on Object {
            p = null;
          }
          if (p == null) {
            missing.add(c.asset.id);
          } else {
            picked.add(p);
          }
          onPrepared?.call(++prepared, chosen.length);
        }
        if (picked.isEmpty) continue;
        await queue.enqueue(
          babyId: entry.key,
          request: {
            'babyId': entry.key,
            'memoryId': newMemoryId(),
            'batchId': newBatchId(),
            'caption': null,
            'audience': audience.name,
            'notifyFamily': audience == Audience.family && notifyFamily,
            'dateMode': 'capture',
            'date': null,
            'milestone': null,
            'albumIds': const <String>[],
          },
          picked: picked,
        );
        queued += picked.length;
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
