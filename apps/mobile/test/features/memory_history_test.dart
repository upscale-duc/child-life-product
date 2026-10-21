import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/memories/memory_models.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/family_fixtures.dart';

class HistoryRepo extends FakeMemoryRepository {
  final pages = <StreamController<HistorySlice<MediaItem>>>[];
  final cursors = <(DateTime, String)>[];
  @override
  Stream<HistorySlice<MediaItem>> olderMedia(
    MemoryKey key,
    (DateTime, String) cursor,
  ) {
    cursors.add(cursor);
    final page = StreamController<HistorySlice<MediaItem>>.broadcast();
    pages.add(page);
    return page.stream;
  }
}

void main() {
  test(
    'history continues past the recent window, deduplicates overlaps, observes deletion and retries errors',
    () async {
      final repo = HistoryRepo();
      final day = DateTime.utc(2026, 10, 21);
      final recent = List.generate(
        200,
        (i) => mediaItem('m', day.subtract(Duration(days: i))),
      );
      final old = mediaItem('old', DateTime.utc(2020));
      final c = ProviderContainer(
        overrides: [
          memoryRepositoryProvider.overrideWithValue(repo),
          mediaProvider.overrideWith((ref, key) => Stream.value(recent)),
          memoriesProvider.overrideWith((ref, key) => Stream.value([])),
        ],
      );
      addTearDown(c.dispose);
      const key = (teddyId, true);
      c.listen(completeMediaProvider(key), (_, _) {});
      await pumpEventQueue();
      final load = c.read(historyTailProvider.notifier).loadMore(key);
      expect(c.read(historyTailProvider)[key]!.loading, true);
      expect(repo.cursors.single, (recent.last.captureAt, recent.last.id));
      repo.pages.single.add(
        HistorySlice([recent.last, old], (old.captureAt, old.id), true),
      );
      await load;
      expect(c.read(completeMediaProvider(key)).value, hasLength(201));
      repo.pages.single.add(
        HistorySlice([recent.last], (old.captureAt, old.id), true),
      );
      await pumpEventQueue();
      expect(c.read(completeMediaProvider(key)).value, hasLength(200));
      final fail = c.read(historyTailProvider.notifier).loadMore(key);
      repo.pages.last.addError(StateError('offline'));
      await fail;
      expect(c.read(historyTailProvider)[key]!.error, true);
      final retry = c.read(historyTailProvider.notifier).loadMore(key);
      expect(repo.cursors.last, (
        old.captureAt,
        old.id,
      ), reason: 'a failed page keeps the previous cursor');
      repo.pages.last.add(const HistorySlice([], null, false));
      await retry;
      expect(c.read(historyTailProvider)[key]!.mediaEnd, true);
      c.invalidate(historyTailProvider);
      await pumpEventQueue();
      expect(c.read(completeMediaProvider(key)).value, hasLength(200));
      for (final p in repo.pages) {
        await p.close();
      }
    },
  );
}
