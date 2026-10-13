import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'auto_save_engine.dart';

/// Tự lưu kỷ niệm keeps everything on this phone (D-066 #5, P-147): settings, the consent record,
/// the numbers that stand for each baby's sample faces, the ledger of library items already
/// handled, and pending suggestions. No photo is copied. The file lives in Application Support,
/// is excluded from iCloud backup and goes away with the app.

/// Version of the consent copy the parent agreed to (P-147). Bump it when the copy changes.
const autoSaveConsentVersion = 1;

/// What happened to a library item for one baby (P-150).
enum LedgerState {
  /// Queued for upload to Kỷ niệm (by Tự lưu or by hand).
  uploaded('up'),

  /// Left unticked or "Bỏ qua lần này": not suggested again.
  skipped('skip'),

  /// "Không phải ảnh của bé".
  rejected('no'),

  /// Saved to the library from Child Life ("Tải về"): never suggested back.
  fromApp('app');

  const LedgerState(this.code);
  final String code;

  static LedgerState? of(String? code) =>
      values.where((v) => v.code == code).firstOrNull;
}

/// A sample face: where it came from (a Kỷ niệm media id or a library id) and its print.
@immutable
class SampleFace {
  const SampleFace({
    required this.ref,
    required this.print,
    this.approved = false,
    this.addedAt,
  });

  /// `m:<mediaId>` (Kỷ niệm) or `a:<localIdentifier>` (library).
  final String ref;
  final Float32List print;

  /// Added because the parent approved a suggestion, not picked in AS04.
  final bool approved;
  final DateTime? addedAt;

  Map<String, Object?> toJson() => {
    'ref': ref,
    'print': _b64(print),
    if (approved) 'approved': true,
    if (addedAt != null) 'at': addedAt!.millisecondsSinceEpoch,
  };

  static SampleFace fromJson(Map<String, Object?> j) => SampleFace(
    ref: j['ref']! as String,
    print: _floats(j['print']! as String),
    approved: j['approved'] == true,
    addedAt: j['at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((j['at']! as num).toInt()),
  );
}

/// One baby turned on for Tự lưu on this phone.
@immutable
class AutoSaveBaby {
  const AutoSaveBaby({this.samples = const [], this.negatives = const []});
  final List<SampleFace> samples;
  final List<Float32List> negatives;

  /// Picked in AS04 (the ones a parent sees and manages in AS19).
  List<SampleFace> get picked => [
    for (final s in samples)
      if (!s.approved) s,
  ];

  BabyFaces get faces => BabyFaces(
    samples: [for (final s in samples) s.print],
    negatives: negatives,
  );

  AutoSaveBaby copyWith({
    List<SampleFace>? samples,
    List<Float32List>? negatives,
  }) => AutoSaveBaby(
    samples: samples ?? this.samples,
    negatives: negatives ?? this.negatives,
  );

  Map<String, Object?> toJson() => {
    'samples': [for (final s in samples) s.toJson()],
    'negatives': [for (final n in negatives) _b64(n)],
  };

  static AutoSaveBaby fromJson(Map<String, Object?> j) => AutoSaveBaby(
    samples: [
      for (final s in (j['samples'] as List?) ?? const [])
        SampleFace.fromJson((s as Map).cast<String, Object?>()),
    ],
    negatives: [
      for (final n in (j['negatives'] as List?) ?? const [])
        _floats(n as String),
    ],
  );
}

/// Everything Tự lưu remembers on this phone.
@immutable
class AutoSaveState {
  const AutoSaveState({
    this.enabled = false,
    this.consentVersion,
    this.consentAt,
    this.babies = const {},
    this.photos = true,
    this.videos = true,
    this.notify = true,
    this.token,
    this.lastScanAt,
    this.lastScanCount = 0,
    this.ledger = const {},
    this.seen = const {},
    this.pending = const [],
    this.savedByMonth = const {},
    this.offAt,
    this.scanFrom,
    this.names = const {},
    this.notifiedAt,
    this.bannerHidden = const {},
  });

  /// Master switch (AS19).
  final bool enabled;
  final int? consentVersion;
  final DateTime? consentAt;
  final Map<String, AutoSaveBaby> babies;

  /// "Tìm trong · Ảnh / Video" (AS19).
  final bool photos;
  final bool videos;

  /// "Báo khi có ảnh mới" (AS19, AR03).
  final bool notify;

  /// PhotoKit persistent change token: where the next check starts.
  final Uint8List? token;
  final DateTime? lastScanAt;

  /// Files looked at in the last check (AS12 "1.380 tệp mới", AS16 "46 tệp mới từ lần trước").
  final int lastScanCount;

  /// localIdentifier → babyId (`*` for every baby) → state.
  final Map<String, Map<String, LedgerState>> ledger;

  /// Items already described, with their capture time (kept 90 days).
  final Map<String, DateTime> seen;

  /// Suggestions waiting for review (AS07); grouped again each time they are shown.
  final List<Candidate> pending;

  /// "Đã lưu từ Tự lưu · 42 mục trong tháng 10" (AS12), counted on this phone: `yyyy-MM` → n.
  final Map<String, int> savedByMonth;

  /// When Tự lưu was turned off; face data is deleted 30 days later (P-147).
  final DateTime? offAt;

  /// Set when the next check must look back by date instead of following the change history:
  /// the first check after setup (30 days, or since birth) and after a baby's samples change.
  final DateTime? scanFrom;

  /// Babies' nicknames, for the notification a background check writes without Firestore.
  final Map<String, String> names;

  /// When the last "Có N ảnh mới" notification was (or will be) shown: at most one a day (AR03).
  final DateTime? notifiedAt;

  /// Suggestions the Hôm nay banner was put off for with "Để sau" (AR02): it comes back only for
  /// new ones.
  final Set<String> bannerHidden;

  bool get consented => consentVersion == autoSaveConsentVersion;

  /// Whether this item is done for this baby (or for every baby).
  bool handled(String assetId, [String? babyId]) {
    final row = ledger[assetId];
    if (row == null) return false;
    return babyId == null || row.containsKey('*') || row.containsKey(babyId);
  }

  AutoSaveState copyWith({
    bool? enabled,
    int? consentVersion,
    DateTime? consentAt,
    bool clearConsent = false,
    Map<String, AutoSaveBaby>? babies,
    bool? photos,
    bool? videos,
    bool? notify,
    Uint8List? token,
    bool clearToken = false,
    DateTime? lastScanAt,
    int? lastScanCount,
    Map<String, Map<String, LedgerState>>? ledger,
    Map<String, DateTime>? seen,
    List<Candidate>? pending,
    Map<String, int>? savedByMonth,
    DateTime? offAt,
    bool clearOffAt = false,
    DateTime? scanFrom,
    bool clearScanFrom = false,
    Map<String, String>? names,
    DateTime? notifiedAt,
    Set<String>? bannerHidden,
  }) => AutoSaveState(
    enabled: enabled ?? this.enabled,
    consentVersion: clearConsent ? null : consentVersion ?? this.consentVersion,
    consentAt: clearConsent ? null : consentAt ?? this.consentAt,
    babies: babies ?? this.babies,
    photos: photos ?? this.photos,
    videos: videos ?? this.videos,
    notify: notify ?? this.notify,
    token: clearToken ? null : token ?? this.token,
    lastScanAt: lastScanAt ?? this.lastScanAt,
    lastScanCount: lastScanCount ?? this.lastScanCount,
    ledger: ledger ?? this.ledger,
    seen: seen ?? this.seen,
    pending: pending ?? this.pending,
    savedByMonth: savedByMonth ?? this.savedByMonth,
    offAt: clearOffAt ? null : offAt ?? this.offAt,
    scanFrom: clearScanFrom ? null : scanFrom ?? this.scanFrom,
    names: names ?? this.names,
    notifiedAt: notifiedAt ?? this.notifiedAt,
    bannerHidden: bannerHidden ?? this.bannerHidden,
  );

  /// "Xoá ảnh mẫu và dữ liệu gợi ý" (AS19) or withdrawing the consent: every face number,
  /// suggestion and the consent go; the ledger of uploads and downloads stays so nothing is
  /// suggested twice.
  AutoSaveState wipeFaces() => AutoSaveState(
    photos: photos,
    videos: videos,
    notify: notify,
    ledger: {
      for (final e in ledger.entries)
        if (e.value.values.any(
          (s) => s == LedgerState.uploaded || s == LedgerState.fromApp,
        ))
          e.key: {
            for (final s in e.value.entries)
              if (s.value == LedgerState.uploaded ||
                  s.value == LedgerState.fromApp)
                s.key: s.value,
          },
    },
    savedByMonth: savedByMonth,
  );

  Map<String, Object?> toJson() => {
    'v': 1,
    'enabled': enabled,
    'consentVersion': consentVersion,
    'consentAt': consentAt?.millisecondsSinceEpoch,
    'babies': {for (final e in babies.entries) e.key: e.value.toJson()},
    'photos': photos,
    'videos': videos,
    'notify': notify,
    'token': token == null ? null : base64Encode(token!),
    'lastScanAt': lastScanAt?.millisecondsSinceEpoch,
    'lastScanCount': lastScanCount,
    'ledger': {
      for (final e in ledger.entries)
        e.key: {for (final s in e.value.entries) s.key: s.value.code},
    },
    'seen': {
      for (final e in seen.entries) e.key: e.value.millisecondsSinceEpoch,
    },
    'pending': [for (final c in pending) _candidateJson(c)],
    'savedByMonth': savedByMonth,
    'offAt': offAt?.millisecondsSinceEpoch,
    'scanFrom': scanFrom?.millisecondsSinceEpoch,
    'names': names,
    'notifiedAt': notifiedAt?.millisecondsSinceEpoch,
    'bannerHidden': bannerHidden.toList(),
  };

  static AutoSaveState fromJson(Map<String, Object?> j) {
    DateTime? time(Object? v) => v == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
    Map<String, Object?> map(Object? v) =>
        (v as Map?)?.cast<String, Object?>() ?? const {};
    return AutoSaveState(
      enabled: j['enabled'] == true,
      consentVersion: (j['consentVersion'] as num?)?.toInt(),
      consentAt: time(j['consentAt']),
      babies: {
        for (final e in map(j['babies']).entries)
          e.key: AutoSaveBaby.fromJson(map(e.value)),
      },
      photos: j['photos'] != false,
      videos: j['videos'] != false,
      notify: j['notify'] != false,
      token: j['token'] == null ? null : base64Decode(j['token']! as String),
      lastScanAt: time(j['lastScanAt']),
      lastScanCount: (j['lastScanCount'] as num?)?.toInt() ?? 0,
      ledger: {
        for (final e in map(j['ledger']).entries)
          e.key: {
            for (final s in map(e.value).entries)
              s.key: ?LedgerState.of(s.value as String?),
          },
      },
      seen: {for (final e in map(j['seen']).entries) e.key: time(e.value)!},
      pending: [
        for (final c in (j['pending'] as List?) ?? const [])
          ?_candidateFromJson(map(c)),
      ],
      savedByMonth: {
        for (final e in map(j['savedByMonth']).entries)
          e.key: (e.value! as num).toInt(),
      },
      offAt: time(j['offAt']),
      scanFrom: time(j['scanFrom']),
      names: map(j['names']).cast<String, String>(),
      notifiedAt: time(j['notifiedAt']),
      bannerHidden: {
        for (final id in (j['bannerHidden'] as List?) ?? const []) id as String,
      },
    );
  }
}

Map<String, Object?> _candidateJson(Candidate c) {
  final a = c.asset;
  return {
    'id': a.id,
    'captureAt': a.captureAt.millisecondsSinceEpoch,
    'video': a.video,
    'durationMs': a.durationMs,
    'width': a.width,
    'height': a.height,
    'favorite': a.favorite,
    'burst': a.burst,
    'burstPick': a.burstPick,
    'aesthetics': a.aesthetics,
    if (a.print != null) 'print': _b64(a.print!),
    // What ranking needs, plus the matched face's print: approving it makes it a sample.
    'faces': [
      for (final (i, f) in a.faces.indexed)
        {
          'size': f.size,
          'quality': f.quality,
          if (i == c.match.face && f.print != null) 'print': _b64(f.print!),
        },
    ],
    'baby': c.match.babyId,
    'distance': c.match.distance,
    'face': c.match.face,
  };
}

Candidate? _candidateFromJson(Map<String, Object?> j) {
  final asset = AssetInfo.fromMap({
    ...j,
    'print': j['print'] == null ? null : _floats(j['print']! as String),
    'faces': [
      for (final f in (j['faces'] as List?) ?? const [])
        {
          ...(f as Map).cast<String, Object?>(),
          'print': f['print'] == null ? null : _floats(f['print']! as String),
        },
    ],
  });
  final baby = j['baby'] as String?;
  if (asset == null || baby == null) return null;
  return Candidate(
    asset: asset,
    match: FaceMatch(
      babyId: baby,
      distance: (j['distance'] as num?)?.toDouble() ?? 1,
      face: (j['face'] as num?)?.toInt() ?? 0,
    ),
  );
}

String _b64(Float32List f) =>
    base64Encode(f.buffer.asUint8List(f.offsetInBytes, f.lengthInBytes));

Float32List _floats(String s) {
  final bytes = base64Decode(s);
  return Float32List.view(
    Uint8List.fromList(bytes).buffer,
    0,
    bytes.length ~/ 4,
  );
}

/// Reads and writes the state file. Writes are serialised and atomic (temp file + rename).
class AutoSaveStore {
  AutoSaveStore({Future<Directory> Function()? dir, this.onCreated})
    : _dir = dir ?? _defaultDir;

  final Future<Directory> Function() _dir;

  /// Called once with the folder when it is first created (to exclude it from backup).
  final Future<void> Function(String path)? onCreated;
  Future<void> _last = Future.value();

  static Future<Directory> _defaultDir() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/auto_save');

  Future<File> _file() async {
    final dir = await _dir();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
      await onCreated?.call(dir.path);
    }
    return File('${dir.path}/state.json');
  }

  Future<AutoSaveState> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return const AutoSaveState();
      return AutoSaveState.fromJson(
        (jsonDecode(await f.readAsString()) as Map).cast<String, Object?>(),
      );
    } on Object {
      // A damaged file starts Tự lưu over rather than breaking Kỷ niệm.
      return const AutoSaveState();
    }
  }

  Future<void> save(AutoSaveState s) {
    final next = _last.then((_) async {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(s.toJson()), flush: true);
      await tmp.rename(f.path);
    });
    _last = next.catchError((_) {});
    return next;
  }

  /// Removes the whole folder (account sign-out, or tests).
  Future<void> clear() async {
    await _last;
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}
