import 'dart:async';

import 'package:child_life/features/care/care_format.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/care/stats_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/router_pump.dart';

/// D-127 flow and error states for care (audit 2026-10-26 §2.6): unknown is never shown as
/// empty (SY-1, SY-2), a refused write names the record (SY-4), "Hôm nay" of feed stats says
/// it starts at 18:00 (SY-5).
final l10n = lookupAppLocalizations(const Locale('vi'));

void main() {
  group('SY-1 · Hôm nay', () {
    testWidgets('loading: skeletons, never "Chưa có"', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(
          recordsStream: () => StreamController<List<CareRecord>>().stream,
          growth: mockGrowth(),
        ),
      );
      expect(find.text(l10n.todayTileEmpty), findsNothing);
      expect(find.text(l10n.todaySummaryEmpty), findsNothing);
      expect(find.bySemanticsLabel(l10n.axTilesLoading), findsWidgets);
    });

    testWidgets(
      'failed: says so with a retry; tiles still log, show no "Chưa có"',
      (tester) async {
        var attempts = 0;
        await pumpRouted(
          tester,
          const Scaffold(body: TodayScreen()),
          overrides: careOverrides(
            recordsStream: () {
              attempts++;
              return attempts == 1
                  ? Stream<List<CareRecord>>.error(StateError('denied'))
                  : Stream.value(mockDay());
            },
            growth: mockGrowth(),
          ),
        );
        expect(find.text(l10n.careLoadFailed), findsOneWidget);
        expect(find.text(l10n.todayLoadFailedBody), findsOneWidget);
        expect(find.text(l10n.todayTileEmpty), findsNothing);
        expect(find.text(l10n.todaySummaryEmpty), findsNothing);
        await tester.tap(find.text(l10n.rhRetry));
        await tester.pumpAndSettle();
        expect(find.text(l10n.careLoadFailed), findsNothing);
        expect(attempts, 2);
      },
    );
  });

  group('SY-2 · Lịch sử, Thống kê', () {
    testWidgets(
      'History: a failed query is an error with retry, not a skeleton',
      (tester) async {
        await pumpRouted(
          tester,
          const HistoryScreen(),
          overrides: careOverrides(rangeFails: true),
        );
        expect(find.text(l10n.careLoadFailed), findsOneWidget);
        expect(find.text(l10n.rhRetry), findsOneWidget);
      },
    );

    testWidgets('Stats: a failed query is an error with retry', (tester) async {
      await pumpRouted(
        tester,
        const FeedStatsScreen(),
        overrides: careOverrides(rangeFails: true),
      );
      expect(find.text(l10n.careLoadFailed), findsOneWidget);
    });
  });

  testWidgets('SY-5: feed stats "Hôm nay" says it counts from 18:00', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const FeedStatsScreen(),
      overrides: careOverrides(),
      prefs: const {'stats.feed.window': 'today'},
    );
    expect(find.text(l10n.statsTodayFrom18), findsOneWidget);
    expect(find.text(l10n.sinceYesterday18), findsNothing);
  });

  test(
    'SY-4: a refused write names the record; the access line only when denied',
    () {
      final r = mockDay().first;
      final what = recordSummary(l10n, 'vi', r);
      final message = careWriteFailed(
        l10n,
        'vi',
        CareWrite.delete,
        Exception(),
        r,
      );
      expect(message, startsWith(l10n.careFailedDelete(what, '')));
      expect(message, isNot(contains('quyền')));
      final denied = careWriteFailed(
        l10n,
        'vi',
        CareWrite.create,
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        r,
      );
      expect(denied, contains(what));
      expect(denied, endsWith('Có thể quyền của bạn đã thay đổi.'));
      expect(
        careWriteFailed(l10n, 'vi', CareWrite.timer, Exception()),
        l10n.careFailedTimer,
      );
    },
  );
}
