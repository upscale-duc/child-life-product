import 'dart:typed_data';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/widgets/cl_navigation.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/assistant/assistant_device.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_photos.dart';
import 'package:child_life/features/assistant/assistant_rules.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_widgets.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// Assistant app gaps after A5: CH19 "Gần đây" with AI summaries (D-075 #1), CH03 row status
/// from task snapshots, CH08 per-feed times, the phone forgetting assistant state on sign-out /
/// family switch, and the floating button never under the upload pill.

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen,
  FakeAssistantRepository repo, {
  Map<String, Object> prefs = const {},
  Map<String, CareRecord> care = const {},
}) async {
  await pumpRouted(
    tester,
    screen,
    prefs: prefs,
    overrides: assistantOverrides(repo: repo, careRecords: care),
  );
  await tester.pumpAndSettle();
}

Map<String, Object> _thread(List<String> ids) => {
  'assistant.conversation.u_mai:${teddyScope.key}': conversation1,
  'assistant.tasks.u_mai:${teddyScope.key}': ids,
};

FakeAssistantRepository _summaryRepo(Map<String, Object?> part) =>
    FakeAssistantRepository(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(),
          messages: [
            userMessage('Hôm nay con bú thế nào?'),
            assistantMessage([part]),
          ],
        ),
      },
    );

Map<String, Object?> _conversation(String id, String title, String task) => {
  'id': id,
  'ownerUid': 'u_mai',
  'shared': false,
  'familyId': 'f_1',
  'scope': {'type': 'child', 'babyId': teddyId},
  'title': title,
  'locale': 'vi',
  'createdAt': '2026-10-15T02:12:00.000Z',
  'updatedAt': '2026-10-15T02:12:00.000Z',
  'archivedAt': null,
  'lastTaskId': task,
};

/// Uploads waiting for a network: the shell's pill shows.
QueueBatch _waitingBatch() => QueueBatch(
  batchId: 'bat_${'d' * 32}',
  babyId: teddyId,
  memoryId: 'mem_${'d' * 32}',
  request: const {'audience': 'family', 'notifyFamily': true},
  createdAt: DateTime(2026, 10, 8),
  sessionCreated: true,
  items: [
    for (final n in ['IMG_1.HEIC', 'IMG_2.HEIC'])
      QueueItem(
        mediaId: 'med_${n.hashCode.toRadixString(16).padLeft(32, '0')}',
        type: MediaKind.photo,
        name: n,
        localPath: '/nope/$n',
        contentType: 'image/jpeg',
        bytes: 3400000,
        captureAt: DateTime(2026, 10, 8),
        state: QueueState.paused,
      ),
  ],
);

GoRouter _todayShell() => GoRouter(
  initialLocation: Routes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.family,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: root,
                builder: (_, _) => Scaffold(body: Text('tab $root')),
              ),
            ],
          ),
      ],
    ),
  ],
);

final _owner = NotifierProvider<_Owner, String?>(_Owner.new);

class _Owner extends Notifier<String?> {
  @override
  String? build() => 'u_mai|f_1';

  void set(String? value) => state = value;
}

void main() {
  group('CH19 recent (getAssistantUsage.recent, D-075 #1)', () {
    test('reads chat tasks and AI summaries with their reservation state', () {
      final u = AssistantUsage.fromJson(
        usageJson(
          recent: [
            {
              'kind': 'summary',
              'summaryKind': 'handover',
              'state': 'committed',
              'credits': 1,
              'at': '2026-10-15T02:00:00.000Z',
              'who': 'Ba',
            },
            {'kind': 'image', 'state': 'released', 'credits': 3},
            {'kind': 'text', 'state': 'reserved', 'credits': 1},
            {'kind': 'explain', 'credits': 1},
            // The A4 shape still reads (committed).
            {'modality': 'image', 'credits': 3, 'who': 'Mẹ'},
            {'kind': 'text'}, // no credits: dropped
          ],
        ),
      )!;
      final r = u.recent!;
      expect(r.map((e) => e.source), [
        UsageSource.handover,
        UsageSource.image,
        UsageSource.text,
        UsageSource.explain,
        UsageSource.image,
      ]);
      expect(r.map((e) => e.state), [
        TaskUsageState.committed,
        TaskUsageState.released,
        TaskUsageState.reserved,
        TaskUsageState.committed,
        TaskUsageState.committed,
      ]);
      // Only committed credits counted: a released photo held 3 but counted 0.
      expect(r.map((e) => e.charged), [1, 0, 0, 1, 3]);
      expect(r.first.who, 'Ba');
    });

    test('no list from the server is "not known", not an empty history', () {
      final none = Map.of(usageJson())..remove('recent');
      expect(AssistantUsage.fromJson(none)!.recent, isNull);
      expect(AssistantUsage.fromJson(usageJson())!.recent, isEmpty);
    });

    testWidgets('lists what used credits, honest about 0 and held credits', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const AssistantUsageScreen(babyId: teddyId),
        FakeAssistantRepository(
          usage: usageJson(
            used: 4,
            reserved: 1,
            recent: [
              {
                'kind': 'text',
                'state': 'reserved',
                'credits': 1,
                'at': '2026-10-15T07:10:00.000Z',
                'who': 'Mẹ',
              },
              {
                'kind': 'summary',
                'summaryKind': 'handover',
                'state': 'committed',
                'credits': 1,
                'at': '2026-10-15T02:30:00.000Z',
                'who': 'Ba',
              },
              {
                'kind': 'image',
                'state': 'released',
                'credits': 3,
                'at': '2026-10-14T02:00:00.000Z',
                'who': 'Ba',
              },
              {
                'kind': 'text',
                'state': 'committed',
                'credits': 0,
                'at': '2026-10-13T12:00:00.000Z',
              },
            ],
          ),
        ),
      );
      expect(find.text('Gần đây'), findsOneWidget);
      // D-075 #1: AI summaries cost from the same pool.
      expect(
        find.text('Tóm tắt bằng AI (bàn giao, giải thích)'),
        findsOneWidget,
      );
      expect(find.text('Mẹ · 15/10 · đang giữ 1 lượt'), findsOneWidget);
      expect(find.text('Tóm tắt bàn giao bằng AI'), findsOneWidget);
      expect(find.text('Ba · 15/10 · 1 lượt'), findsOneWidget);
      expect(find.text('Ba · 14/10 · 0 lượt · đã hoàn lại'), findsOneWidget);
      // No member label: the line skips it.
      expect(find.text('13/10 · 0 lượt · miễn phí'), findsOneWidget);
    });

    testWidgets('an empty list says so; no list shows no section', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const AssistantUsageScreen(babyId: teddyId),
        FakeAssistantRepository(usage: usageJson(used: 0)),
      );
      expect(find.text('Gần đây'), findsOneWidget);
      expect(find.text('Chưa dùng lượt nào trong kỳ này.'), findsOneWidget);
    });

    testWidgets('no list from the server: no "Gần đây" at all', (tester) async {
      await _pumpScreen(
        tester,
        const AssistantUsageScreen(babyId: teddyId),
        FakeAssistantRepository(
          usage: Map.of(usageJson(used: 5))..remove('recent'),
        ),
      );
      expect(find.text('Gần đây'), findsNothing);
      expect(find.text('Chưa dùng lượt nào trong kỳ này.'), findsNothing);
    });
  });

  group('CH08 per-feed times', () {
    final summary = CareSummary.fromJson(summaryPart()['summary'])!;
    SummaryItem item(String id, String kind, int h, {int? ml, int? min}) =>
        SummaryItem(
          id: id,
          kind: kind,
          at: DateTime.utc(2026, 10, 15, h),
          ml: ml,
          minutes: min,
        );

    test('lists each kind oldest first while it adds up to the summary', () {
      final f = summaryFeeds(summary, [
        item('b3', 'bottle', 6, ml: 120),
        item('b1', 'bottle', 1, ml: 150),
        item('b2', 'bottle', 4, ml: 120),
        item('n1', 'breast', 2, min: 20),
        item('n2', 'breast', 5, min: 15),
        item('b1', 'bottle', 1, ml: 150), // the same record twice counts once
      ]);
      expect(f.bottle!.map((i) => i.id), ['b1', 'b2', 'b3']);
      expect(f.breast!.map((i) => i.id), ['n1', 'n2']);
    });

    test('a record changed or gone since the answer: totals only', () {
      final f = summaryFeeds(summary, [
        item('b1', 'bottle', 1, ml: 160), // edited
        item('b2', 'bottle', 4, ml: 120),
        item('b3', 'bottle', 6, ml: 120),
        item('n1', 'breast', 2, min: 20), // n2 deleted
      ]);
      expect(f.bottle, isNull);
      expect(f.breast, isNull);
    });

    testWidgets('times come from the counted records (sourceIds)', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        _summaryRepo(summaryPart()),
        prefs: _thread([taskA]),
        care: summaryRecords(),
      );
      expect(
        find.text('08:00 150 ml · 11:10 120 ml · 13:50 120 ml'),
        findsOneWidget,
      );
      expect(find.text('09:30 20 phút · 12:40 15 phút'), findsOneWidget);
    });

    testWidgets('records that no longer add up show no times', (tester) async {
      await _pumpScreen(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        _summaryRepo(summaryPart()),
        prefs: _thread([taskA]),
        care: summaryRecords(firstBottleMl: 180),
      );
      expect(find.textContaining('08:00 150 ml'), findsNothing);
      expect(find.textContaining('08:00 180 ml'), findsNothing);
      expect(find.text('Bú bình · 3 cữ · 390 ml'), findsOneWidget);
      // Nursing still adds up.
      expect(find.text('09:30 20 phút · 12:40 15 phút'), findsOneWidget);
    });

    testWidgets('items sent by the server are used as they are', (
      tester,
    ) async {
      final part = {
        ...summaryPart(),
        'items': [
          {
            'id': 'x1',
            'kind': 'bottle',
            'at': '2026-10-15T01:00:00.000Z',
            'ml': 150,
          },
          {
            'id': 'x2',
            'kind': 'bottle',
            'at': '2026-10-15T04:10:00.000Z',
            'ml': 120,
          },
          {
            'id': 'x3',
            'kind': 'bottle',
            'at': '2026-10-15T06:50:00.000Z',
            'ml': 120,
          },
        ],
      };
      await _pumpScreen(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        _summaryRepo(part),
        prefs: _thread([taskA]),
      );
      expect(
        find.text('08:00 150 ml · 11:10 120 ml · 13:50 120 ml'),
        findsOneWidget,
      );
      // The server listed no nursing items: its totals only.
      expect(find.textContaining('20 phút ·'), findsNothing);
    });
  });

  group('CH03 row status (from the last task snapshot)', () {
    TaskSnapshot snap(
      Map<String, Object?> task, [
      List<Map<String, Object?>> drafts = const [],
    ]) => TaskSnapshot.fromJson(snapshotWith(task: task, drafts: drafts))!;

    test('saved, waiting (not expired) and discarded drafts', () {
      final s = threadStatus(
        snap(taskJson(), [
          bottleDraftJson(state: 'saved'),
          sleepDraftJson(state: 'draft'),
          bottleDraftJson(index: 2, state: 'discarded'),
          bottleDraftJson(index: 3, state: 'failed'),
        ]),
        assistantNow,
      );
      expect(s, const ThreadStatus(saved: 1, pending: 2));
      // After the 24 h TTL nothing is waiting any more.
      expect(
        threadStatus(
          snap(taskJson(), [sleepDraftJson(state: 'draft')]),
          assistantNow.add(const Duration(days: 2)),
        ).isEmpty,
        isTrue,
      );
    });

    test('an open question, a care try waiting, a canceled task', () {
      final asking = snap(
        taskJson(
          state: 'awaiting_clarification',
          clarification: clarificationJson(),
        ),
      );
      expect(threadStatus(asking, assistantNow).needsAnswer, isTrue);
      // Expired question: no longer "waiting for an answer".
      expect(
        threadStatus(
          asking,
          assistantNow.add(const Duration(hours: 1)),
        ).needsAnswer,
        isFalse,
      );
      final trying = snap(careTaskJson(care: sleepCare(followUp: true)));
      expect(threadStatus(trying, assistantNow).awaitingFeedback, isTrue);
      final answered = snap(
        careTaskJson(care: sleepCare(followUp: true, feedback: 'helpful')),
      );
      expect(threadStatus(answered, assistantNow).awaitingFeedback, isFalse);
      expect(
        threadStatus(
          snap(taskJson(state: 'canceled'), [sleepDraftJson()]),
          assistantNow,
        ).isEmpty,
        isTrue,
      );
    });

    testWidgets('rows say what was saved, what waits, what needs an answer', (
      tester,
    ) async {
      final repo =
          FakeAssistantRepository(
              tasks: {
                taskA: snapshotWith(
                  task: taskJson(),
                  drafts: [
                    bottleDraftJson(state: 'saved'),
                    sleepDraftJson(state: 'saved'),
                  ],
                ),
                taskB: snapshotWith(
                  task: taskJson(
                    id: taskB,
                    state: 'awaiting_clarification',
                    clarification: clarificationJson(),
                  ),
                  drafts: [bottleDraftJson(taskId: taskB)],
                ),
              },
            )
            ..conversationsAnswer = () => [
              _conversation(conversation1, 'Ghi bú và ngủ', taskA),
              _conversation('cv_${'2' * 32}', 'Ghi cữ tối', taskB),
              // A task the server can't give back: the time alone, nothing guessed.
              _conversation('cv_${'3' * 32}', 'Câu hỏi cũ', 'tk_${'9' * 32}'),
            ];
      await _pumpScreen(
        tester,
        AssistantHistoryScreen(scopeKey: teddyScope.key),
        repo,
      );
      expect(find.textContaining('2 mục đã lưu · '), findsOneWidget);
      expect(
        find.textContaining('Có câu hỏi đang chờ trả lời · '),
        findsOneWidget,
      );
      expect(find.text('1 nháp'), findsOneWidget);
      expect(find.textContaining('mục đã lưu'), findsOneWidget);
      // One read per conversation's last task.
      expect(repo.named('getAssistantTask'), hasLength(3));
    });
  });

  group('sign-out and family switch', () {
    late SharedPreferences prefs;
    late ProviderContainer c;
    late AssistantPhotoCache cache;

    Future<void> settle() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'assistant.kept.u_mai:child:$teddyId': '{"text":"8 giờ con bú"}',
        'assistant.tasks.u_mai:child:$teddyId': [taskA],
        'today.selectedBabyId': teddyId,
      });
      prefs = await SharedPreferences.getInstance();
      cache = AssistantPhotoCache()..put(attachment1, Uint8List(4));
      c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          assistantOwnerProvider.overrideWith((ref) => ref.watch(_owner)),
          assistantPhotoCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(c.dispose);
    });

    Iterable<String> assistantKeys() =>
        prefs.getKeys().where((k) => k.startsWith('assistant.'));

    test(
      'state from an unknown owner is not trusted; then it is kept',
      () async {
        // Watched like the app root does (an unwatched provider is paused).
        c.listen(assistantDeviceGuardProvider, (_, _) {});
        await settle();
        // Written before anyone was recorded: forgotten once.
        expect(assistantKeys(), [assistantOwnerKey]);
        expect(prefs.getString(assistantOwnerKey), 'u_mai|f_1');
        await prefs.setString('assistant.kept.u_mai:child:$teddyId', '{}');
        c.read(_owner.notifier).set('u_mai|f_1');
        await settle();
        expect(assistantKeys(), hasLength(2));
        expect(prefs.getString('today.selectedBabyId'), teddyId);
      },
    );

    test('signing out forgets inputs, threads and photos', () async {
      await prefs.setString(assistantOwnerKey, 'u_mai|f_1');
      // Watched like the app root does (an unwatched provider is paused).
      c.listen(assistantDeviceGuardProvider, (_, _) {});
      await settle();
      expect(assistantKeys(), hasLength(3)); // same owner: kept
      expect(cache[attachment1], isNotNull);
      c.read(_owner.notifier).set(null);
      await settle();
      expect(assistantKeys(), isEmpty);
      expect(cache[attachment1], isNull);
      // Unrelated preferences stay.
      expect(prefs.getString('today.selectedBabyId'), teddyId);
    });

    test('switching family forgets; loading decides nothing', () async {
      await prefs.setString(assistantOwnerKey, 'u_mai|f_1');
      // Watched like the app root does (an unwatched provider is paused).
      c.listen(assistantDeviceGuardProvider, (_, _) {});
      await settle();
      c.read(_owner.notifier).set(assistantOwnerUnknown);
      await settle();
      expect(assistantKeys(), hasLength(3));
      c.read(_owner.notifier).set('u_mai|f_2');
      await settle();
      expect(assistantKeys(), [assistantOwnerKey]);
      expect(prefs.getString(assistantOwnerKey), 'u_mai|f_2');
      expect(cache[attachment1], isNull);
    });

    testWidgets('the owner is the account and the selected baby’s family', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: familyOverrides(me: mai),
      );
      container.listen(assistantOwnerProvider, (_, _) {});
      await tester.pumpAndSettle();
      expect(container.read(assistantOwnerProvider), 'u_mai|f_1');
    });
  });

  group('Chat/Nút trợ lý and the upload pill (Hôm nay)', () {
    Future<void> pumpToday(WidgetTester tester, {required bool uploads}) =>
        pumpRouted(
          tester,
          const SizedBox(),
          router: _todayShell(),
          overrides: [
            ...careOverrides(),
            ...memoryOverrides(
              network: NetworkKind.none,
              store: MemoryQueueStore()..saved = [if (uploads) _waitingBatch()],
            ),
            assistantAccessProvider.overrideWith(
              (ref, babyId) => const AssistantAccess(),
            ),
          ],
        ).then((_) => tester.pumpAndSettle());

    testWidgets('the button rides 12 above the pill, never over it', (
      tester,
    ) async {
      await pumpToday(tester, uploads: true);
      final fab = tester.getRect(find.byType(AsFloatingButton));
      final pill = tester.getRect(find.byType(UploadPill));
      expect(pill.height, greaterThan(0));
      expect(fab.overlaps(pill), isFalse);
      expect(pill.top - fab.bottom, moreOrLessEquals(12));
      expect(fab.right, moreOrLessEquals(375 - 16));
    });

    testWidgets('without uploads it sits 12 above the "+"', (tester) async {
      await pumpToday(tester, uploads: false);
      final fab = tester.getRect(find.byType(AsFloatingButton));
      final plus = tester.getRect(find.byType(ClQuickLogButton));
      expect(plus.top - fab.bottom, moreOrLessEquals(12));
    });
  });
}
