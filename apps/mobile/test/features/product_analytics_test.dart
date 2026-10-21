import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:child_life/features/analytics/product_analytics.dart';

void main() {
  test(
    'logout clears a preferences write that was already in flight',
    () async {
      String? saved;
      var owner = 'A';
      final writing = Completer<void>(), release = Completer<void>();
      final reporter = ProductAnalyticsReporter(
        ownerUid: 'A',
        currentOwner: () => owner,
        read: () => saved,
        write: (value) async {
          writing.complete();
          await release.future;
          saved = value;
        },
        remove: () async {
          saved = null;
        },
        send: (_) async => fail('A closed reporter must not send'),
      );
      final observed = reporter.observe('app_foreground_observed');
      await writing.future;
      owner = 'B';
      reporter.close();
      release.complete();
      await observed;
      expect(saved, isNull);
    },
  );
  test(
    'offline retries keep the same receipt and preserve the original observation time',
    () async {
      String? saved;
      var owner = 'A', online = false;
      final sent = <Map<String, Object?>>[];
      final reporter = ProductAnalyticsReporter(
        ownerUid: 'A',
        currentOwner: () => owner,
        read: () => saved,
        write: (s) async {
          saved = s;
        },
        remove: () async {
          saved = null;
        },
        clock: () => DateTime.utc(2026, 10, 21, 17, 30),
        send: (row) async {
          sent.add({...row});
          if (!online) throw StateError('offline');
        },
      );
      await reporter.observe(
        'app_foreground_observed',
        platform: 'ios',
        locale: 'vi',
      );
      expect(jsonDecode(saved!) as List, hasLength(1));
      online = true;
      await reporter.flush();
      expect(sent, hasLength(2));
      expect(sent.first['receiptId'], sent.last['receiptId']);
      expect(sent.last['occurredAt'], '2026-10-21T17:30:00.000Z');
      expect(jsonDecode(saved!) as List, isEmpty);
      owner = 'B';
      await reporter.observe('family_context_viewed', babyId: 'private-source');
      expect(sent, hasLength(2));
      reporter.close();
    },
  );

  test(
    'logout during a send cannot rewrite or replay the previous account outbox',
    () async {
      String? saved;
      var owner = 'A';
      final barrier = Completer<void>();
      var calls = 0;
      final reporter = ProductAnalyticsReporter(
        ownerUid: 'A',
        currentOwner: () => owner,
        read: () => saved,
        write: (s) async {
          saved = s;
        },
        remove: () async {
          saved = null;
        },
        send: (row) async {
          calls++;
          await barrier.future;
        },
      );
      final task = reporter.observe('app_foreground_observed');
      await Future<void>.delayed(Duration.zero);
      owner = 'B';
      reporter.close();
      barrier.complete();
      await task;
      await reporter.flush();
      expect(saved, isNull);
      expect(calls, 1);
    },
  );

  test(
    'keeps the queue bounded and records no source photo identifiers',
    () async {
      String? saved;
      final reporter = ProductAnalyticsReporter(
        ownerUid: 'A',
        currentOwner: () => 'A',
        read: () => saved,
        write: (s) async {
          saved = s;
        },
        remove: () async {
          saved = null;
        },
        send: (_) async => throw StateError('offline'),
      );
      for (var i = 0; i < 55; i++) {
        await reporter.observe(
          'photo_review_opened',
          babyId: 'authorized-domain-source',
        );
      }
      expect(jsonDecode(saved!) as List, hasLength(50));
      expect(saved, isNot(contains('photoKit')));
      expect(saved, isNot(contains('assetId')));
      reporter.close();
    },
  );
}
