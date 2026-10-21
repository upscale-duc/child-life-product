import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:child_life/features/engagement/engagement_local.dart';
import 'package:child_life/features/engagement/engagement_launch.dart';

void main() {
  test(
    'cold launch retains only a validated opaque token until login or expiry',
    () {
      final queue = EngagementLaunchQueue(), now = DateTime.utc(2026, 10, 21);
      final id = 'a' * 64;
      queue.put('/private/baby/name', now: now);
      expect(queue.take(now: now), isNull);
      queue.put(id, now: now);
      expect(queue.take(now: now.add(const Duration(minutes: 9))), id);
      expect(queue.take(now: now), isNull);
      queue.put(id, now: now);
      expect(queue.take(now: now.add(const Duration(minutes: 11))), isNull);
    },
  );
  setUp(() => SharedPreferences.setMockInitialValues({'privacy.owner': 'A'}));
  test(
    'review episode survives restart and permission loss without transmitting library ids',
    () async {
      final prefs = await SharedPreferences.getInstance(),
          a = EngagementLocal(prefs, 'A');
      final first = await a.pending('baby', pending: true, available: true);
      final restart = await EngagementLocal(
        prefs,
        'A',
      ).pending('baby', pending: true, available: true);
      final denied = await a.pending('baby', pending: true, available: false);
      expect(restart?['episode'], first?['episode']);
      expect(denied?['episode'], first?['episode']);
      expect(denied?['state'], 'unavailable');
      expect(first?.keys.toSet(), {'episode', 'state', 'approvedBatches'});
    },
  );
  test(
    'only a resolved review followed by fresh discoveries creates another episode',
    () async {
      final a = EngagementLocal(await SharedPreferences.getInstance(), 'A');
      final old = await a.pending('baby', pending: true, available: true);
      await a.approved('baby', 'approved_cloud_batch');
      final resolved = await a.pending('baby', pending: false, available: true);
      expect(resolved?['episode'], old?['episode']);
      expect(resolved?['approvedBatches'], ['approved_cloud_batch']);
      final fresh = await a.pending('baby', pending: true, available: true);
      expect(fresh?['episode'], isNot(old?['episode']));
      expect(fresh?['approvedBatches'], isEmpty);
    },
  );
  test(
    'another UID cannot inherit source episodes, batches or legacy handoff choices',
    () async {
      final prefs = await SharedPreferences.getInstance(),
          a = EngagementLocal(prefs, 'A'),
          b = EngagementLocal(prefs, 'B');
      final first = await a.pending('baby', pending: true, available: true);
      await a.approved('baby', 'batch');
      await a.handoff('milestone', 'baby');
      await prefs.setString('privacy.owner', 'B');
      final second = await b.pending('baby', pending: true, available: true);
      expect(second?['episode'], isNot(first?['episode']));
      expect(second?['approvedBatches'], isEmpty);
      expect(b.ownsLegacy('milestone', 'baby'), false);
      expect(a.ownsLegacy('milestone', 'baby'), true);
    },
  );
  test('approved batch associations are bounded', () async {
    final a = EngagementLocal(await SharedPreferences.getInstance(), 'A');
    await a.pending('baby', pending: true, available: true);
    for (var n = 0; n < 30; n++) {
      await a.approved('baby', 'batch_$n');
    }
    final data = await a.pending('baby', pending: false, available: true);
    expect(data?['approvedBatches'], hasLength(20));
    expect((data?['approvedBatches'] as List).last, 'batch_29');
  });
  test('stale account work cannot write new local engagement state', () async {
    final prefs = await SharedPreferences.getInstance(),
        a = EngagementLocal(prefs, 'A');
    await prefs.setString('privacy.owner', 'B');
    expect(await a.pending('baby', pending: true, available: true), isNull);
    await a.handoff('pending', 'baby');
    expect(prefs.getKeys().where((k) => k.startsWith('engagement.')), isEmpty);
  });
  test(
    'a handoff is per baby and is released when the server stops owning the lane',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('privacy.owner', 'A');
      final a = EngagementLocal(prefs, 'A');
      await a.handoff('milestone', 'x');
      await a.acknowledge('milestone', 'x');
      expect(a.ownsLegacy('milestone', 'x'), true);
      // Another family's baby keeps its legacy nudges (rollout is per family).
      expect(a.ownsLegacy('milestone', 'y'), false);
      expect(await a.release('milestone', 'x'), true);
      expect(a.ownsLegacy('milestone', 'x'), false);
      expect(prefs.getBool('engagement.handoff.A.x.milestone'), isNull);
      expect(await a.release('milestone', 'x'), false);
    },
  );
}
