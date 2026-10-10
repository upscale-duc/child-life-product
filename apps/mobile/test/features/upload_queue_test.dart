import 'dart:async';
import 'dart:io';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// The device queue (10i, UploadPill, §6.5): sessions, Wi-Fi rule (D-033), offline, failures,
/// quota (R-121), cancel and restart after a kill (ADR-004).
void main() {
  late FakeMemoryRepository repo;
  late FakeTransport transport;
  late MemoryQueueStore store;
  late StreamController<NetworkKind> network;
  late ProviderContainer container;

  Future<ProviderContainer> start({
    NetworkKind initial = NetworkKind.wifi,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    network = StreamController<NetworkKind>.broadcast();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        memoryRepositoryProvider.overrideWithValue(repo),
        uploadTransportProvider.overrideWithValue(transport),
        mediaPreparerProvider.overrideWithValue(FakePreparer()),
        queueStoreProvider.overrideWithValue(store),
        networkKindProvider.overrideWith((ref) async* {
          yield initial;
          yield* network.stream;
        }),
      ],
    );
    c.listen(uploadQueueProvider, (_, _) {});
    c.listen(networkKindProvider, (_, _) {});
    await pumpEventQueue();
    return c;
  }

  setUp(() {
    repo = FakeMemoryRepository();
    transport = FakeTransport();
    store = MemoryQueueStore();
  });

  tearDown(() async {
    container.dispose();
    await network.close();
  });

  Map<String, Object?> request() => {
    'babyId': teddyId,
    'memoryId': newMemoryId(),
    'batchId': newBatchId(),
    'caption': null,
    'audience': 'family',
    'notifyFamily': true,
    'dateMode': 'capture',
    'date': null,
    'milestone': null,
  };

  List<QueueItem> items() => [
    for (final b in container.read(uploadQueueProvider).batches) ...b.items,
  ];

  test(
    'a batch gets its session, then every item uploads (poster first)',
    () async {
      File('/tmp/IMG_2043.MOV.jpg').writeAsBytesSync([1]);
      addTearDown(() => File('/tmp/IMG_2043.MOV.jpg').deleteSync());
      container = await start();
      await container
          .read(uploadQueueProvider.notifier)
          .enqueue(
            babyId: teddyId,
            request: request(),
            picked: [pickedPhoto('IMG_2041.HEIC'), pickedVideo('IMG_2043.MOV')],
          );
      await pumpEventQueue();
      expect(repo.sessions.single['items'], hasLength(2));
      expect(items().map((i) => i.state), everyElement(QueueState.uploaded));
      final video = items().last.mediaId;
      expect(transport.uploaded, [
        'babies/$teddyId/uploads/${items().first.mediaId}',
        'babies/$teddyId/uploads/$video.poster',
        'babies/$teddyId/uploads/$video',
      ]);
      expect(
        store.saved.single.items.every((i) => i.state == QueueState.uploaded),
        isTrue,
      );
    },
  );

  test(
    'on mobile data a video waits for Wi-Fi and says so (D-033); photos go',
    () async {
      container = await start(initial: NetworkKind.cellular);
      await container
          .read(uploadQueueProvider.notifier)
          .enqueue(
            babyId: teddyId,
            request: request(),
            picked: [pickedPhoto('a.HEIC'), pickedVideo('b.MOV')],
          );
      await pumpEventQueue();
      expect(items().map((i) => i.state), [
        QueueState.uploaded,
        QueueState.waitingWifi,
      ]);
      expect(repo.waitingWifi, [items().last.mediaId]);
      network.add(NetworkKind.wifi);
      await pumpEventQueue();
      expect(items().last.state, QueueState.uploaded);
    },
  );

  test('turning the Wi-Fi rule off lets the video go on mobile data', () async {
    container = await start(initial: NetworkKind.cellular);
    await container
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: teddyId,
          request: request(),
          picked: [pickedVideo('b.MOV')],
        );
    await pumpEventQueue();
    container.read(videoWifiOnlyProvider.notifier).set(false);
    await container.read(uploadQueueProvider.notifier).retry();
    await pumpEventQueue();
    expect(items().single.state, QueueState.uploaded);
  });

  test('composed offline: kept, then sent once back online', () async {
    container = await start(initial: NetworkKind.none);
    await container
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: teddyId,
          request: request(),
          picked: [pickedPhoto('a.HEIC')],
        );
    await pumpEventQueue();
    expect(repo.sessions, isEmpty);
    expect(items().single.state, QueueState.pendingSession);
    network.add(NetworkKind.wifi);
    await pumpEventQueue();
    expect(repo.sessions, hasLength(1));
    expect(items().single.state, QueueState.uploaded);
  });

  test('a dropped connection fails the item; "Thử lại" uploads it', () async {
    container = await start();
    transport.failTimes = 1;
    await container
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: teddyId,
          request: request(),
          picked: [pickedPhoto('IMG_2044.HEIC')],
        );
    await pumpEventQueue();
    expect(items().single.state, QueueState.failed);
    await container.read(uploadQueueProvider.notifier).retry();
    await pumpEventQueue();
    expect(items().single.state, QueueState.uploaded);
  });

  test('over the quota an item stays on the device (R-121)', () async {
    container = await start();
    repo.reserveOnly = 1;
    await container
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: teddyId,
          request: request(),
          picked: [pickedPhoto('a.HEIC'), pickedPhoto('b.HEIC')],
        );
    await pumpEventQueue();
    expect(items().map((i) => i.state), [
      QueueState.uploaded,
      QueueState.waitingQuota,
    ]);
  });

  test('cancelling gives the reservation back', () async {
    container = await start(initial: NetworkKind.cellular);
    await container
        .read(uploadQueueProvider.notifier)
        .enqueue(
          babyId: teddyId,
          request: request(),
          picked: [pickedVideo('b.MOV')],
        );
    await pumpEventQueue();
    final id = items().single.mediaId;
    await container.read(uploadQueueProvider.notifier).cancel(id);
    expect(items().single.state, QueueState.cancelled);
    expect(repo.cancelled, [id]);
  });

  test(
    'a note needs no upload: its batch goes once the memory exists',
    () async {
      container = await start();
      await container
          .read(uploadQueueProvider.notifier)
          .enqueue(
            babyId: teddyId,
            request: {...request(), 'caption': 'Đêm qua con ngủ một mạch.'},
            picked: const [],
          );
      await pumpEventQueue();
      expect(repo.sessions.single['caption'], 'Đêm qua con ngủ một mạch.');
      expect(container.read(uploadQueueProvider).batches, isEmpty);
    },
  );

  test(
    'after a kill, unfinished items start again on the next launch',
    () async {
      final batch = QueueBatch(
        batchId: newBatchId(),
        babyId: teddyId,
        memoryId: newMemoryId(),
        request: request(),
        createdAt: DateTime(2026, 10, 8),
        sessionCreated: true,
        items: [
          QueueItem(
            mediaId: newMediaId(),
            type: MediaKind.photo,
            name: 'a.HEIC',
            localPath: '/tmp/a.jpg',
            contentType: 'image/jpeg',
            bytes: 100,
            captureAt: DateTime(2026, 10, 8),
            state: QueueState.uploading,
          ),
        ],
      );
      store.saved = [QueueBatch.fromJson(batch.toJson())];
      expect(store.saved.single.items.single.state, QueueState.queued);
      container = await start();
      await pumpEventQueue();
      expect(items().single.state, QueueState.uploaded);
      expect(File('/tmp/a.jpg').path, isNotEmpty);
    },
  );
}
