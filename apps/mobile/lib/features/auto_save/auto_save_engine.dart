import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Tự lưu kỷ niệm (D-066): the decisions, with no I/O so they are tested without a phone.
/// Which baby a photo may show (P-149), which photos are near-copies of each other and which one
/// of them is best (P-146). The phone side (ios/Runner/AutoSave.swift) only describes photos.

/// One face Vision found, with a print of the face alone.
@immutable
class FaceInfo {
  const FaceInfo({required this.size, this.print, this.quality});

  /// Longest side of the face box as a share of the image (0 – 1).
  final double size;
  final Float32List? print;

  /// Vision Face Capture Quality (0 – 1); only comparable between photos of one moment.
  final double? quality;

  static FaceInfo fromMap(Map<Object?, Object?> m) => FaceInfo(
    size: (m['size'] as num?)?.toDouble() ?? 0,
    print: m['print'] as Float32List?,
    quality: (m['quality'] as num?)?.toDouble(),
  );
}

/// What the phone said about one library item.
@immutable
class AssetInfo {
  const AssetInfo({
    required this.id,
    required this.captureAt,
    this.video = false,
    this.durationMs = 0,
    this.width = 0,
    this.height = 0,
    this.favorite = false,
    this.burst,
    this.burstPick = false,
    this.utility = false,
    this.aesthetics,
    this.print,
    this.faces = const [],
    this.unreadable = false,
  });

  final String id;
  final DateTime captureAt;
  final bool video;
  final int durationMs;
  final int width;
  final int height;
  final bool favorite;
  final String? burst;
  final bool burstPick;

  /// Receipts, documents, screenshots of things (Aesthetics `isUtility`, iOS 18+).
  final bool utility;

  /// Aesthetics `overallScore` (−1 – 1, iOS 18+).
  final double? aesthetics;

  /// Print of the whole image, for grouping.
  final Float32List? print;
  final List<FaceInfo> faces;
  final bool unreadable;

  /// Null for items the library no longer has.
  static AssetInfo? fromMap(Map<Object?, Object?> m) {
    if (m['missing'] == true) return null;
    return AssetInfo(
      id: m['id']! as String,
      captureAt: DateTime.fromMillisecondsSinceEpoch(
        (m['captureAt'] as num?)?.toInt() ?? 0,
      ),
      video: m['video'] == true,
      durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
      width: (m['width'] as num?)?.toInt() ?? 0,
      height: (m['height'] as num?)?.toInt() ?? 0,
      favorite: m['favorite'] == true,
      burst: m['burst'] as String?,
      burstPick: m['burstPick'] == true,
      utility: m['utility'] == true,
      aesthetics: (m['aesthetics'] as num?)?.toDouble(),
      print: m['print'] as Float32List?,
      faces: [
        for (final f in (m['faces'] as List?) ?? const [])
          FaceInfo.fromMap(f as Map<Object?, Object?>),
      ],
      unreadable: m['unreadable'] == true,
    );
  }

  /// Rough size once uploaded, for "~ 186 MB" and the space check (AS07, AS10, AS18). Photos are
  /// re-encoded as JPEG (P-033); videos keep their bytes.
  int get estimatedBytes {
    final pixels = math.max(width * height, 1);
    if (!video) return (math.min(pixels, 12000000) * 0.3).round();
    final perSecond = math.min(pixels / (1920 * 1080) * 1300000, 6000000);
    return (durationMs / 1000 * perSecond).round();
  }
}

/// Knobs that are guesses until the beta measures them; kept together so they can move to
/// `config/limits` later (P-146, P-149).
@immutable
class AutoSaveTuning {
  const AutoSaveTuning({
    this.minFaceSize = 0.06,
    this.spreadFactor = 1.6,
    this.minMatch = 0.08,
    this.maxMatch = 0.45,
    this.momentGap = const Duration(minutes: 3),
    this.groupGap = const Duration(seconds: 90),
    this.groupMax = 0.15,
    this.secondBestMinGroup = 6,
    this.secondBestCloseness = 0.1,
  });

  /// Faces smaller than this share of the image are ignored.
  final double minFaceSize;

  /// A face counts as the baby when it is within the samples' own spread times this…
  final double spreadFactor;

  /// …kept between these cosine distances.
  final double minMatch;
  final double maxMatch;

  /// A longer pause starts a new moment.
  final Duration momentGap;

  /// Two photos further apart than this are never one group.
  final Duration groupGap;

  /// Whole-image cosine distance under which two photos are near-copies.
  final double groupMax;

  /// A group this large pre-selects a second photo when it scores close to the best.
  final int secondBestMinGroup;
  final double secondBestCloseness;
}

/// Cosine distance (0 = same direction, 2 = opposite) between two prints of the same revision.
double printDistance(Float32List a, Float32List b) {
  if (a.length != b.length || a.isEmpty) return 2;
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 2;
  return 1 - dot / math.sqrt(na * nb);
}

/// One baby's sample faces and the faces a parent said were not them.
@immutable
class BabyFaces {
  const BabyFaces({required this.samples, this.negatives = const []});
  final List<Float32List> samples;
  final List<Float32List> negatives;

  /// The furthest two samples are from each other: v1 prints have no fixed scale, so the
  /// threshold follows the baby's own samples.
  double get spread {
    var most = 0.0;
    for (var i = 0; i < samples.length; i++) {
      for (var j = i + 1; j < samples.length; j++) {
        most = math.max(most, printDistance(samples[i], samples[j]));
      }
    }
    return most;
  }
}

@immutable
class FaceMatch {
  const FaceMatch({
    required this.babyId,
    required this.distance,
    required this.face,
  });
  final String babyId;

  /// Closest sample, lower is more likely.
  final double distance;

  /// Index into [AssetInfo.faces].
  final int face;
}

/// The one baby this photo most likely shows, or null (D-066 #7: one baby per photo in v1).
/// Loose on purpose: parents review every suggestion (D-066 #8).
FaceMatch? matchBaby(
  AssetInfo asset,
  Map<String, BabyFaces> babies, {
  AutoSaveTuning tuning = const AutoSaveTuning(),
}) {
  FaceMatch? best;
  for (final entry in babies.entries) {
    final faces = entry.value;
    if (faces.samples.isEmpty) continue;
    final threshold = (faces.spread * tuning.spreadFactor).clamp(
      tuning.minMatch,
      tuning.maxMatch,
    );
    for (var i = 0; i < asset.faces.length; i++) {
      final face = asset.faces[i];
      final p = face.print;
      if (p == null || face.size < tuning.minFaceSize) continue;
      final d = faces.samples.map((s) => printDistance(p, s)).reduce(math.min);
      if (d > threshold) continue;
      // Closer to a face the parent rejected than to any sample: someone else.
      if (faces.negatives.any((n) => printDistance(p, n) < d)) continue;
      if (best == null || d < best.distance) {
        best = FaceMatch(babyId: entry.key, distance: d, face: i);
      }
    }
  }
  return best;
}

/// A photo or video worth suggesting, with the baby it may show.
@immutable
class Candidate {
  const Candidate({required this.asset, required this.match});
  final AssetInfo asset;
  final FaceMatch match;
}

/// One tile in AS07: the photos of one near-copy group, best first (P-146).
@immutable
class SuggestionGroup {
  const SuggestionGroup({required this.items, required this.preselected});

  /// Best first.
  final List<Candidate> items;

  /// Ids ticked on arrival: the best, sometimes the runner-up.
  final Set<String> preselected;

  Candidate get best => items.first;
  DateTime get captureAt => best.asset.captureAt;
}

/// Splits suggestions into moments, joins near-copies (same burst, or close prints within
/// [AutoSaveTuning.groupGap]) and ranks each group. Videos stay on their own. Newest first.
List<SuggestionGroup> groupAndRank(
  List<Candidate> candidates, {
  AutoSaveTuning tuning = const AutoSaveTuning(),
}) {
  final sorted = [...candidates]
    ..sort((a, b) => a.asset.captureAt.compareTo(b.asset.captureAt));
  final groups = <List<Candidate>>[];
  var moment = <Candidate>[];
  void closeMoment() {
    if (moment.isNotEmpty) groups.addAll(_nearCopies(moment, tuning));
    moment = [];
  }

  for (final c in sorted) {
    if (moment.isNotEmpty &&
        c.asset.captureAt.difference(moment.last.asset.captureAt) >
            tuning.momentGap) {
      closeMoment();
    }
    moment.add(c);
  }
  closeMoment();
  final out = [for (final g in groups) _rank(g, tuning)]
    ..sort((a, b) => b.captureAt.compareTo(a.captureAt));
  return out;
}

List<List<Candidate>> _nearCopies(List<Candidate> moment, AutoSaveTuning t) {
  final parent = List<int>.generate(moment.length, (i) => i);
  int find(int i) => parent[i] == i ? i : parent[i] = find(parent[i]);
  void join(int a, int b) => parent[find(a)] = find(b);
  for (var i = 0; i < moment.length; i++) {
    final a = moment[i].asset;
    if (a.video) continue;
    for (var j = i + 1; j < moment.length; j++) {
      final b = moment[j].asset;
      if (b.video) continue;
      if (b.captureAt.difference(a.captureAt) > t.groupGap) break;
      final sameBurst = a.burst != null && a.burst == b.burst;
      final close =
          a.print != null &&
          b.print != null &&
          printDistance(a.print!, b.print!) <= t.groupMax;
      if (sameBurst || close) join(i, j);
    }
  }
  final byRoot = <int, List<Candidate>>{};
  for (var i = 0; i < moment.length; i++) {
    (byRoot[find(i)] ??= []).add(moment[i]);
  }
  return byRoot.values.toList();
}

/// Scores only mean something inside one group (Apple: compare Capture Quality between photos of
/// the same subject), so every signal is rescaled to 0 – 1 within the group.
SuggestionGroup _rank(List<Candidate> group, AutoSaveTuning t) {
  if (group.length == 1) {
    return SuggestionGroup(items: group, preselected: {group.first.asset.id});
  }
  double? quality(Candidate c) => c.asset.faces[c.match.face].quality;
  double size(Candidate c) => c.asset.faces[c.match.face].size;
  List<double> scaled(List<double?> xs) {
    final known = xs.whereType<double>();
    if (known.isEmpty) return List.filled(xs.length, 0.5);
    final lo = known.reduce(math.min), hi = known.reduce(math.max);
    return [
      for (final x in xs) x == null || hi == lo ? 0.5 : (x - lo) / (hi - lo),
    ];
  }

  final q = scaled([for (final c in group) quality(c)]);
  final s = scaled([for (final c in group) size(c)]);
  final a = scaled([for (final c in group) c.asset.aesthetics]);
  final scores = <Candidate, double>{
    for (var i = 0; i < group.length; i++)
      group[i]:
          q[i] * 0.5 +
          s[i] * 0.2 +
          a[i] * 0.2 +
          // A heart in Photos or the photo picked from a burst is the parent's own choice and
          // outweighs anything Vision says.
          (group[i].asset.favorite || group[i].asset.burstPick ? 1 : 0),
  };
  final ranked = [...group]
    ..sort((x, y) {
      final byScore = scores[y]!.compareTo(scores[x]!);
      return byScore != 0
          ? byScore
          : x.asset.captureAt.compareTo(y.asset.captureAt);
    });
  final pre = {ranked.first.asset.id};
  if (ranked.length >= t.secondBestMinGroup &&
      scores[ranked[0]]! - scores[ranked[1]]! <= t.secondBestCloseness) {
    pre.add(ranked[1].asset.id);
  }
  return SuggestionGroup(items: ranked, preselected: pre);
}
