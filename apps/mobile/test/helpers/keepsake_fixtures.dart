import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';
import 'memory_fixtures.dart';

/// The seed catalog the portal starts from (generated from the contracts; test data only, the app
/// reads what staff publish — D-068 #7).
KeepsakeCatalog seedCatalog() => KeepsakeCatalog.fromJson(
  jsonDecode(File('test/helpers/keepsake_seed.json').readAsStringSync()),
);

List<Override> keepsakeOverrides({
  KeepsakeCatalog? catalog,
  bool cards = true,
  bool videos = false,
  FakeKeepsakeJobs? jobs,
  ({List<Memory> memories, List<MediaItem> media})? journal,
}) => [
  ...familyOverrides(now: DateTime(2026, 10, 13, 9)),
  ...memoryOverrides(
    keepsakes: (cards: cards, videos: videos),
    keepsakeCatalog: catalog ?? seedCatalog(),
    journal: journal,
  ),
  environmentProvider.overrideWithValue(AppEnvironment.dev),
  keepsakeAssetImageProvider.overrideWithValue(
    (asset) => const StorageImage('keepsake/peach'),
  ),
  keepsakeJobRepositoryProvider.overrideWithValue(jobs ?? FakeKeepsakeJobs()),
];

/// Video kỷ niệm jobs without Firebase: requests are recorded, jobs are whatever a test sets.
class FakeKeepsakeJobs implements KeepsakeJobRepository {
  final requests = <Map<String, Object?>>[];
  final retried = <String>[];
  final live = <String>[];
  final deleted = <String>[];

  @override
  Future<void> delete(String babyId, String jobId) async {
    deleted.add(jobId);
    _jobs.remove(jobId);
    _changes.add(null);
  }

  @override
  Future<void> attachLive({
    required String babyId,
    required String jobId,
    required String token,
    required String fcm,
  }) async => live.add('$jobId:$token');
  final _jobs = <String, KeepsakeJob>{};
  final _changes = StreamController<void>.broadcast();

  void put(KeepsakeJob job) {
    _jobs[job.id] = job;
    _changes.add(null);
  }

  @override
  Stream<KeepsakeJob?> watch(String babyId, String jobId) async* {
    yield _jobs[jobId];
    await for (final _ in _changes.stream) {
      yield _jobs[jobId];
    }
  }

  @override
  Stream<List<KeepsakeJob>> watchMine(String babyId, String uid) async* {
    yield _jobs.values.toList();
    await for (final _ in _changes.stream) {
      yield _jobs.values.toList();
    }
  }

  @override
  Future<String> request({
    required String requestId,
    required String babyId,
    required KeepsakeTemplate template,
    required List<String> mediaIds,
    required String title,
    required String message,
    Map<String, String> extra = const {},
    String locale = 'vi',
    required Audience audience,
    required Occasion? occasion,
    ({String? id})? music,
  }) async {
    requests.add({
      if (music != null) 'musicId': music.id,
      'requestId': requestId,
      'templateId': template.id,
      'mediaIds': mediaIds,
      'title': title,
      'message': message,
      if (extra.isNotEmpty) 'extra': extra,
      'locale': locale,
      'audience': audience.name,
      'occasion': occasion?.wire,
    });
    final id = 'ksj_${'0' * 31}${requests.length}';
    put(
      KeepsakeJob(
        id: id,
        babyId: babyId,
        status: KeepsakeJobStatus.queued,
        templateId: template.id,
        title: title,
        createdAt: DateTime(2026, 10, 13, 9),
        mediaIds: mediaIds,
        occasion: occasion,
      ),
    );
    return id;
  }

  @override
  Future<void> retry(String babyId, String jobId) async => retried.add(jobId);
}

KeepsakeJob videoJob({
  KeepsakeJobStatus status = KeepsakeJobStatus.rendering,
  int progress = 64,
  String? error,
  List<String> mediaIds = const [],
  String? outputMediaId,
}) => KeepsakeJob(
  id: 'ksj_${'a' * 32}',
  babyId: teddyId,
  status: status,
  templateId: 'video_first_month',
  templateName: 'Tháng đầu tiên',
  title: 'Tháng đầu tiên của Teddy',
  createdAt: DateTime(2026, 10, 13, 8),
  updatedAt: DateTime(2026, 10, 13, 8, 50),
  step: 'export',
  progress: progress,
  error: error,
  mediaIds: mediaIds,
  occasion: Occasion.m1,
  outputMediaId: outputMediaId,
  durationMs: 45000,
  mark: '1',
);

/// A saved milestone card in Kỷ niệm (Chỉ ba mẹ, tagged "Đầy tháng").
MediaItem cardItem(
  DateTime at, {
  String id = 'med_card0000000000000000000000000001',
}) => MediaItem(
  id: id,
  babyId: teddyId,
  memoryId: 'mem_card',
  type: MediaKind.photo,
  status: MediaStatus.ready,
  audience: Audience.parents,
  effectiveAudience: Audience.parents,
  captureAt: at,
  createdBy: mai.uid,
  width: 2160,
  height: 2700,
  milestone: MilestoneRef(id: 'p_one_month', name: 'Đầy tháng', date: at),
  paths: const MediaPaths(
    original: 'mock/peach',
    display: 'mock/peach',
    thumb: 'mock/peach',
  ),
  generatedKind: 'card',
);
