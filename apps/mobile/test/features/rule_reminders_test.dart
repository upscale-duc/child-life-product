import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/reminders/rule_models.dart';
import 'package:child_life/features/reminders/rule_notifications.dart';
import 'package:child_life/features/reminders/rule_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/rule_fixtures.dart';

/// v1.0 improvement · rule reminders (370:1247, D-051): 1a list, 1b–1d create, 1g due sheet, 1h
/// handled. "Now" is Thursday 8 Oct 15:05; the latest bottle was at 14:20.
class _Host extends StatelessWidget {
  const _Host(this.open);
  final void Function(BuildContext) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

/// Nhắc nhở opens on "Một lần"; "Theo quy tắc" comes second (owner, 2026-10-11).
Future<void> _rulesTab(WidgetTester tester) async {
  await tester.tap(find.text('Theo quy tắc'));
  await tester.pumpAndSettle();
}

void main() {
  group('1a Nhắc nhở · Theo quy tắc', () {
    testWidgets('rules with their next time, pause and recipients', (
      tester,
    ) async {
      final repo = FakeRuleRepository();
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(rules: [feed, sleep, diaper], ruleRepo: repo),
      );
      expect(find.text('Nhắc nhở'), findsOneWidget);
      // "Một lần" first and open; "Theo quy tắc" after it.
      expect(
        tester.getCenter(find.text('Một lần')).dx,
        lessThan(tester.getCenter(find.text('Theo quy tắc')).dx),
      );
      expect(find.text('Nhắc bú'), findsNothing);
      await _rulesTab(tester);
      expect(find.text('Nhắc bú'), findsOneWidget);
      expect(find.text('3 giờ sau lần bú gần nhất'), findsOneWidget);
      expect(find.text('Tiếp theo 17:20'), findsOneWidget);
      expect(find.text('Cố định 09:00 · 13:00 · 19:30'), findsOneWidget);
      expect(find.text('2 giờ 30 phút sau lần thay gần nhất'), findsOneWidget);
      expect(find.text('Đang tạm dừng'), findsOneWidget);
      expect(find.text('Người nhận: bạn, Minh, Cô Lan'), findsOneWidget);
      await tester.tap(find.byType(ClToggle).first);
      await tester.pumpAndSettle();
      expect(repo.toggled, [('rr_feed', false)]);
    });

    testWidgets('"Một lần" keeps the dated reminders', (tester) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(rules: [feed]),
      );
      await tester.tap(find.text('Một lần'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc bú'), findsNothing);
      expect(find.text('Thêm nhắc'), findsNothing);
    });

    testWidgets('caregivers see the rules but cannot pause or add', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(me: lan, rules: [feed]),
      );
      await _rulesTab(tester);
      expect(find.text('Nhắc bú'), findsOneWidget);
      expect(find.byType(ClToggle), findsNothing);
      expect(find.text('Thêm nhắc'), findsNothing);
      expect(
        find.text('Ba mẹ đặt nhắc; bạn nhận những nhắc được giao cho mình.'),
        findsOneWidget,
      );
    });

    testWidgets('1h: someone else logged the feed that was due', (
      tester,
    ) async {
      final handled = rule(
        'rr_feed',
        RuleType.feed,
        next: vn(8, 17, 52),
        last: RuleOccurrence(
          dueAt: vn(8, 14, 45),
          outcome: RuleOutcome.logged,
          at: vn(8, 14, 52),
          by: 'u_minh',
          author: const CareAuthor(name: 'Minh', relation: Relation.father),
        ),
      );
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(rules: [handled]),
      );
      await _rulesTab(tester);
      expect(
        find.text('Ba đã ghi lần bú lúc 14:52 · nhắc tiếp theo 17:52'),
        findsOneWidget,
      );
    });
  });

  group('1b → 1c → 1d', () {
    testWidgets('1b: the four kinds are cards of one size in two columns', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RuleEditorScreen(),
        overrides: careOverrides(
          records: mockDay(),
          ruleRepo: FakeRuleRepository(),
        ),
      );
      final cards = [
        for (final label in ['Bú', 'Ngủ', 'Thay tã', 'Hút sữa'])
          tester.getRect(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(Container),
                )
                .first,
          ),
      ];
      expect({for (final r in cards) r.size}, hasLength(1));
      expect(cards[0].left, cards[2].left);
      expect(cards[1].left, cards[3].left);
      expect(cards[0].top, cards[1].top);
      expect(cards[1].left, greaterThan(cards[0].right));
    });

    testWidgets('after the latest feed, every 2 h 30, for everyone eligible', (
      tester,
    ) async {
      final repo = FakeRuleRepository();
      await pumpRouted(
        tester,
        const RuleEditorScreen(),
        overrides: careOverrides(records: mockDay(), ruleRepo: repo),
      );
      expect(find.text('Nhắc mới'), findsOneWidget);
      expect(find.text('Sau lần ghi gần nhất'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Bước 2/3'), findsOneWidget);
      expect(find.text('3 giờ 00 phút'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Bú lúc 14:20 → nhắc lúc 17:20')),
        findsOneWidget,
      );
      await tester.tap(find.text('2 giờ 30'));
      await tester.pumpAndSettle();
      expect(find.text('2 giờ 30 phút'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Bú lúc 14:20 → nhắc lúc 16:50')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Ai sẽ nhận nhắc?'), findsOneWidget);
      expect(find.text('Mai (bạn)'), findsOneWidget);
      expect(find.text('Gia đình · chỉ xem'), findsOneWidget);
      expect(
        find.text('2 giờ 30 phút sau lần bú gần nhất · cả ngày · 3 người nhận'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Lưu nhắc'));
      await tester.tap(find.text('Lưu nhắc'));
      await tester.pumpAndSettle();
      final saved = repo.saved.single;
      expect(saved.type, RuleType.feed);
      expect(saved.intervalMinutes, 150);
      expect(saved.recipients.toSet(), {'u_mai', 'u_minh', 'u_lan'});
      expect(saved.toCall(teddyId)['times'], isEmpty);
      expect(find.text('Đã lưu nhắc bú'), findsOneWidget);
    });

    testWidgets('fixed times: labelled by time of day, removable', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RuleEditorScreen(),
        overrides: careOverrides(),
      );
      await tester.tap(find.text('Ngủ'));
      await tester.tap(find.text('Giờ cố định'));
      await tester.pump();
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc chuẩn bị ngủ'), findsOneWidget);
      expect(find.text('Giấc sáng'), findsOneWidget);
      expect(find.text('Giấc trưa'), findsOneWidget);
      expect(find.text('Giấc đêm'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
      expect(find.textContaining('GMT+7'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Xoá 13:00'));
      await tester.pumpAndSettle();
      expect(find.text('13:00'), findsNothing);
    });

    testWidgets('nobody chosen: it asks for one', (tester) async {
      final repo = FakeRuleRepository();
      await pumpRouted(
        tester,
        const RuleEditorScreen(),
        overrides: careOverrides(ruleRepo: repo),
      );
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.text('Tiếp tục'));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
      }
      for (final name in ['Mai (bạn)', 'Minh', 'Cô Lan']) {
        await tester.tap(find.text(name));
      }
      await tester.pump();
      await tester.ensureVisible(find.text('Lưu nhắc'));
      await tester.tap(find.text('Lưu nhắc'));
      await tester.pump();
      expect(find.text('Chọn ít nhất một người nhận.'), findsOneWidget);
      expect(repo.saved, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('1g Đến giờ nhắc', () {
    final due = rule('rr_feed', RuleType.feed, pending: vn(8, 14, 45));

    Future<FakeRuleRepository> open(
      WidgetTester tester, {
      bool done = true,
    }) async {
      final repo = FakeRuleRepository()..answerDone = done;
      await pumpRouted(
        tester,
        _Host((c) => showRuleDueSheet(c, babyId: teddyId, ruleId: 'rr_feed')),
        overrides: careOverrides(
          records: mockDay(),
          rules: [due],
          ruleRepo: repo,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('the last feed, log, snooze 10 · 15 · 30 and skip', (
      tester,
    ) async {
      final repo = await open(tester);
      expect(find.text('Nhắc bú · 14:45'), findsOneWidget);
      expect(find.text('Đến giờ nhắc bú bạn đã đặt'), findsOneWidget);
      expect(
        find.text('Lần bú gần nhất 14:20 (bú bình · 120 ml) · Bạn ghi'),
        findsOneWidget,
      );
      expect(find.text('Ghi lần bú'), findsOneWidget);
      await tester.tap(find.text('15 phút'));
      await tester.pumpAndSettle();
      expect(repo.answers.single.snooze, 15);
      expect(repo.answers.single.dueAt, vn(8, 14, 45));
      expect(find.textContaining('Sẽ nhắc lại lúc'), findsOneWidget);
    });

    testWidgets('skip, when someone already answered, says so', (tester) async {
      final repo = await open(tester, done: false);
      await tester.tap(find.text('Bỏ qua lần này'));
      await tester.pumpAndSettle();
      expect(repo.answers.single.snooze, isNull);
      expect(find.text('Đã có người xử lý nhắc này.'), findsOneWidget);
    });
  });

  group('1h detail', () {
    testWidgets('Gần đây: logged, snoozed, skipped', (tester) async {
      await pumpRouted(
        tester,
        const RuleDetailScreen(ruleId: 'rr_feed'),
        overrides: careOverrides(
          rules: [feed],
          occurrences: {
            'rr_feed': [
              RuleOccurrence(
                dueAt: vn(8, 14, 45),
                outcome: RuleOutcome.logged,
                at: vn(8, 14, 52),
                by: 'u_minh',
                author: const CareAuthor(
                  name: 'Minh',
                  relation: Relation.father,
                ),
              ),
              RuleOccurrence(
                dueAt: vn(8, 11, 45),
                outcome: RuleOutcome.snoozed,
                at: vn(8, 11, 46),
                by: 'u_mai',
                minutes: 15,
                author: const CareAuthor(
                  name: 'Mai',
                  relation: Relation.mother,
                ),
              ),
              RuleOccurrence(
                dueAt: vn(8, 8, 30),
                outcome: RuleOutcome.skipped,
                at: vn(8, 8, 31),
                by: 'u_mai',
              ),
            ],
          },
        ),
      );
      expect(find.text('Gần đây'), findsOneWidget);
      expect(find.text('14:45 · Đã ghi'), findsOneWidget);
      expect(find.text('11:45 · Báo lại 15 phút'), findsOneWidget);
      expect(find.text('08:30 · Bỏ qua'), findsOneWidget);
      expect(find.text('Sửa nhắc'), findsOneWidget);
    });
  });

  test('pushes are recognised by kind', () {
    expect(
      rulePushOf({
        'kind': 'reminderRule',
        'babyId': teddyId,
        'ruleId': 'rr_feed',
        'type': 'feed',
      }),
      (babyId: teddyId, ruleId: 'rr_feed', type: 'feed'),
    );
    expect(rulePushOf({'kind': 'memories'}), isNull);
  });
}
