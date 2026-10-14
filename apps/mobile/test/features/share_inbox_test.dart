import 'dart:convert';

import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/share_inbox.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bridge implements ShareBridge {
  _Bridge(this.batches);
  final List<SharedBatch> batches;
  final finished = <String>[];
  String? targets;

  @override
  Future<void> setTargets(String json) async => targets = json;

  @override
  Future<List<SharedBatch>> takeInbox() async => batches;

  @override
  Future<void> finish(String id) async => finished.add(id);
}

SharedBatch _batch(String id, String? babyId, {String audience = 'family'}) =>
    SharedBatch.fromJson({
      'id': id,
      'dir': '/group/ShareInbox/$id',
      'babyId': babyId,
      'audience': audience,
      'notifyFamily': true,
      'items': [
        {
          'file': '0.heic',
          'type': 'photo',
          'name': '0.heic',
          'captureAt': '2026-10-09T01:02:03Z',
          'width': 3024,
          'height': 4032,
        },
        {
          'file': '1.mov',
          'type': 'video',
          'name': '1.mov',
          'captureAt': '2026-10-10T05:00:00Z',
          'durationMs': 12500,
        },
      ],
    });

void main() {
  test(
    '10k on Android: a share without a baby waits for the app to ask (Q-065)',
    () async {
      final bridge = _Bridge([
        _batch('share_android', null),
        _batch('share_ios', 'b_1'),
      ]);
      final calls = <String>[];
      final queued = await importSharedBatches(
        bridge: bridge,
        parentOf: {'b_1'},
        enqueue: ({required babyId, required request, required picked}) async =>
            calls.add(babyId),
      );
      expect(queued, 2);
      expect(calls, ['b_1']);
      // Left in the inbox for offerSharedBatch, with its files as picked media.
      expect(bridge.finished, ['share_ios']);
      final android = bridge.batches.first;
      expect(android.babyId, isNull);
      expect(android.picked.map((p) => p.file.path), [
        '/group/ShareInbox/share_android/0.heic',
        '/group/ShareInbox/share_android/1.mov',
      ]);
      expect(android.picked.last.durationMs, 12500);
    },
  );

  test(
    '10k: shares for a Cùng nuôi baby join the queue like 10h, by capture date',
    () async {
      final bridge = _Bridge([_batch('share_a', 'b_1')]);
      final calls = <(String, Map<String, Object?>, List<PickedMedia>)>[];
      final queued = await importSharedBatches(
        bridge: bridge,
        parentOf: {'b_1'},
        enqueue: ({required babyId, required request, required picked}) async =>
            calls.add((babyId, request, picked)),
      );
      expect(queued, 2);
      expect(bridge.finished, ['share_a']);
      final (babyId, request, picked) = calls.single;
      expect(babyId, 'b_1');
      expect(request['audience'], 'family');
      expect(request['notifyFamily'], isTrue);
      expect(request['dateMode'], 'capture');
      expect(request['caption'], isNull);
      expect(request['albumIds'], isEmpty);
      expect(request['memoryId'], startsWith('mem_'));
      expect(request['batchId'], startsWith('bat_'));
      expect(picked.map((p) => p.file.path), [
        '/group/ShareInbox/share_a/0.heic',
        '/group/ShareInbox/share_a/1.mov',
      ]);
      expect(picked.first.type, MediaKind.photo);
      expect(picked.first.captureAt, DateTime.utc(2026, 10, 9, 1, 2, 3));
      expect(picked.last.type, MediaKind.video);
      expect(picked.last.durationMs, 12500);
    },
  );

  test(
    '"Chỉ ba mẹ" never notifies; shares the account can no longer add are dropped',
    () async {
      final bridge = _Bridge([
        _batch('share_p', 'b_1', audience: 'parents'),
        _batch('share_x', 'b_other'),
      ]);
      final requests = <Map<String, Object?>>[];
      final queued = await importSharedBatches(
        bridge: bridge,
        parentOf: {'b_1'},
        enqueue: ({required babyId, required request, required picked}) async =>
            requests.add(request),
      );
      expect(queued, 2);
      expect(requests.single['audience'], 'parents');
      expect(requests.single['notifyFamily'], isFalse);
      expect(bridge.finished, ['share_p', 'share_x']);
    },
  );

  test(
    'the extension gets Cùng nuôi babies and strings from the ARB catalogs (D-012)',
    () async {
      for (final (locale, photos, videos) in [
        ('vi', ('{n} ảnh', '{n} ảnh'), ('{n} video', '{n} video')),
        ('en', ('{n} photo', '{n} photos'), ('{n} video', '{n} videos')),
      ]) {
        final l10n = await AppLocalizations.delegate.load(Locale(locale));
        final json =
            jsonDecode(
                  shareTargetsJson(
                    signedIn: true,
                    babies: [('b_1', 'Teddy')],
                    lastBabyId: 'b_1',
                    maxItems: 30,
                    l10n: l10n,
                  ),
                )
                as Map<String, Object?>;
        expect(json['babies'], [
          {'id': 'b_1', 'nickname': 'Teddy'},
        ]);
        expect(json['maxItems'], 30);
        final copy = json['copy']! as Map<String, Object?>;
        expect(copy['photosOne'], photos.$1);
        expect(copy['photosOther'], photos.$2);
        expect(copy['videosOne'], videos.$1);
        expect(copy['videosOther'], videos.$2);
        expect(copy.values.every((v) => (v as String).isNotEmpty), isTrue);
        expect(copy['family'], locale == 'vi' ? 'Gia đình' : isNotEmpty);
      }
    },
  );
}
