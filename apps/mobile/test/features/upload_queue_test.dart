import 'dart:async';
import 'dart:io';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    MediaPreparer? preparer,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    network = StreamController<NetworkKind>.broadcast();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        memoryRepositoryProvider.overrideWithValue(repo),
        uploadTransportProvider.overrideWithValue(transport),
        mediaPreparerProvider.overrideWithValue(preparer ?? FakePreparer()),
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

  test('uploaded rows keep a thumbnail until the batch is dismissed', () async {
    final preparer = FakePreparer();
    container = await start(preparer: preparer);
    final queue = container.read(uploadQueueProvider.notifier);
    await queue.enqueue(
      babyId: teddyId,
      request: request(),
      picked: [pickedPhoto('IMG_3605.HEIC'), pickedPhoto('IMG_3606.HEIC')],
    );
    await pumpEventQueue();
    final done = items();
    expect(done.map((i) => i.state), everyElement(QueueState.uploaded));
    // The copies are dropped, but each row still has its picture (and it survives a restart).
    expect(preparer.finished, done.map((i) => i.mediaId));
    expect(done.map((i) => i.thumbPath), everyElement(isNotNull));
    expect(
      done.map((i) => QueueItem.fromJson(i.toJson()).thumbPath),
      done.map((i) => i.thumbPath),
    );
    expect(preparer.discarded, isEmpty);

    await queue.dismiss(
      container.read(uploadQueueProvider).batches.single.batchId,
    );
    expect(preparer.discarded, done.map((i) => i.mediaId));
    expect(container.read(uploadQueueProvider).batches, isEmpty);
  });

  test('a new batch takes the place of the finished ones', () async {
    // "Đang tải lên" counted an earlier, finished batch with the new one: 4 chosen showed
    // "2 / 5" (owner, 2026-10-15).
    final preparer = FakePreparer();
    container = await start(preparer: preparer);
    final queue = container.read(uploadQueueProvider.notifier);
    await queue.enqueue(
      babyId: teddyId,
      request: request(),
      picked: [pickedPhoto('IMG_3600.HEIC')],
    );
    await pumpEventQueue();
    expect(items().single.state, QueueState.uploaded);
    final next = {
      ...request(),
      'batchId': newBatchId(),
      'memoryId': newMemoryId(),
    };
    await queue.enqueue(
      babyId: teddyId,
      request: next,
      picked: [pickedPhoto('IMG_3601.HEIC'), pickedPhoto('IMG_3602.HEIC')],
    );
    final batches = container.read(uploadQueueProvider).batches;
    expect(batches.map((b) => b.batchId), [next['batchId']]);
    expect(batches.single.items, hasLength(2));
  });

  test(
    'everything that may go is handed over at once (10j), videos keep the Wi-Fi rule',
    () async {
      File('/tmp/IMG_2043.MOV.jpg').writeAsBytesSync([1]);
      addTearDown(() => File('/tmp/IMG_2043.MOV.jpg').deleteSync());
      container = await start(initial: NetworkKind.cellular);
      await container
          .read(uploadQueueProvider.notifier)
          .enqueue(
            babyId: teddyId,
            request: request(),
            picked: [pickedPhoto('IMG_2041.HEIC'), pickedVideo('IMG_2043.MOV')],
          );
      await pumpEventQueue();
      final photo = items().first.mediaId;
      final video = items().last.mediaId;
      final base = 'babies/$teddyId/uploads';
      expect(
        {for (final j in transport.handedOff) j.path: (j.video, j.wifiOnly)},
        {
          '$base/$photo': (false, false),
          '$base/$video.poster': (false, true),
          '$base/$video': (true, true),
        },
      );
      // On mobile data the queue itself only sends the photo; iOS holds the video for Wi-Fi.
      expect(transport.uploaded, ['$base/$photo']);
      expect(items().last.state, QueueState.waitingWifi);
    },
  );

  test(
    'a file Storage already has counts as uploaded, not refused (10j)',
    () async {
      // It finished while the app was gone; sending it again is refused.
      transport.rejectAll = true;
      container = await start();
      final queue = container.read(uploadQueueProvider.notifier);
      await queue.enqueue(
        babyId: teddyId,
        request: request(),
        picked: [pickedPhoto('IMG_3605.HEIC'), pickedPhoto('IMG_3606.HEIC')],
      );
      await pumpEventQueue();
      // The first is ready on the server, the second never arrived.
      final first = items().first;
      expect(items().map((i) => i.state), everyElement(QueueState.failed));
      repo.statuses[first.mediaId] = 'ready';
      await queue.retry(first.mediaId);
      await pumpEventQueue();
      expect(items().first.state, QueueState.uploaded);
      expect(items().first.thumbPath, isNotNull);
      expect(items().last.state, QueueState.failed);
    },
  );

  test('"Tạm dừng" stops everything handed over', () async {
    container = await start();
    container.read(uploadQueueProvider.notifier).setPaused(true);
    expect(transport.cancelledAll, 1);
  });

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

  test(
    'A11 kill switch: the batch waits as "tạm dừng" and goes on once uploads reopen',
    () async {
      repo.refuseWith = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'uploads-paused',
        details: {'reason': 'uploads-paused'},
      );
      container = await start();
      await container
          .read(uploadQueueProvider.notifier)
          .enqueue(
            babyId: teddyId,
            request: request(),
            picked: [pickedPhoto('a.HEIC')],
          );
      await pumpEventQueue();
      final batch = container.read(uploadQueueProvider).batches.single;
      expect(batch.paused, isTrue);
      expect(batch.refused, isFalse);
      expect(items().single.state, QueueState.pendingSession);
      expect(transport.uploaded, isEmpty);

      // Uploads reopen; the next kick (here a network change) creates the session.
      repo.refuseWith = null;
      network.add(NetworkKind.cellular);
      await pumpEventQueue();
      expect(
        container.read(uploadQueueProvider).batches.single.paused,
        isFalse,
      );
      expect(items().single.state, QueueState.uploaded);
    },
  );

  test(
    'a refused session is shown as failed with "Thử lại", never silently pending',
    () async {
      repo.refuseWith = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'not-allowed',
        details: {'reason': 'not-allowed'},
      );
      container = await start();
      final queue = container.read(uploadQueueProvider.notifier);
      await queue.enqueue(
        babyId: teddyId,
        request: request(),
        picked: [pickedPhoto('a.HEIC'), pickedPhoto('b.HEIC')],
      );
      await pumpEventQueue();
      expect(
        container.read(uploadQueueProvider).batches.single.refused,
        isTrue,
      );
      expect(items().map((i) => i.state), [
        QueueState.failed,
        QueueState.failed,
      ]);

      repo.refuseWith = null;
      await queue.retry();
      await pumpEventQueue();
      expect(
        container.read(uploadQueueProvider).batches.single.blocked,
        isNull,
      );
      expect(items().map((i) => i.state), [
        QueueState.uploaded,
        QueueState.uploaded,
      ]);
    },
  );

  test(
    'a failed item can be removed; a refused batch emptied this way is dropped',
    () async {
      repo.refuseWith = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'not-allowed',
        details: {'reason': 'not-allowed'},
      );
      container = await start();
      final queue = container.read(uploadQueueProvider.notifier);
      await queue.enqueue(
        babyId: teddyId,
        request: request(),
        picked: [pickedPhoto('a.HEIC'), pickedPhoto('b.HEIC')],
      );
      await pumpEventQueue();
      final ids = items().map((i) => i.mediaId).toList();
      expect(items().map((i) => i.state), [
        QueueState.failed,
        QueueState.failed,
      ]);
      final attempts = repo.sessions.length;

      await queue.cancel(ids.first);
      expect(items().first.state, QueueState.cancelled);
      await queue.cancel(ids.last);
      repo.refuseWith = null;
      await queue.retry();
      await pumpEventQueue();
      // No session is asked for removed items, and the empty batch is gone.
      expect(repo.sessions.length, attempts);
      expect(container.read(uploadQueueProvider).batches, isEmpty);
    },
  );

  test(
    'after an app update the saved paths follow the files to the new container',
    () {
      final root = Directory.systemTemp.createTempSync('cl_queue');
      addTearDown(() => root.deleteSync(recursive: true));
      final support = '${root.path}/NEW-UUID/Library/Application Support';
      Directory('$support/uploads').createSync(recursive: true);
      File('$support/uploads/med_a.jpg').writeAsBytesSync([1]);
      File('$support/uploads/med_v.poster.jpg').writeAsBytesSync([1]);
      const old =
          '/var/mobile/Containers/Data/Application/OLD-UUID/Library/Application Support';
      final batch = rebaseQueuePaths({
        'batchId': 'bat_x',
        'items': [
          {'localPath': '$old/uploads/med_a.jpg', 'posterPath': null},
          {
            'localPath': '$old/uploads/med_v.mp4',
            'posterPath': '$old/uploads/med_v.poster.jpg',
          },
        ],
      }, support);
      final items = batch['items']! as List;
      expect((items[0] as Map)['localPath'], '$support/uploads/med_a.jpg');
      // A file that is really gone keeps its path (the upload then fails visibly).
      expect((items[1] as Map)['localPath'], '$old/uploads/med_v.mp4');
      expect(
        (items[1] as Map)['posterPath'],
        '$support/uploads/med_v.poster.jpg',
      );
    },
  );

  test(
    'a Storage refusal stays visible with its code instead of vanishing',
    () async {
      transport.rejectAll = true;
      container = await start();
      final queue = container.read(uploadQueueProvider.notifier);
      await queue.enqueue(
        babyId: teddyId,
        request: request(),
        picked: [pickedPhoto('a.HEIC')],
      );
      await pumpEventQueue();
      expect(items().single.state, QueueState.failed);
      expect(items().single.rejected, isTrue);
      expect(items().single.error, 'rejected:unauthorized');

      transport.rejectAll = false;
      await queue.retry();
      await pumpEventQueue();
      expect(items().single.state, QueueState.uploaded);
      expect(items().single.error, isNull);
    },
  );
}
