import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_settings.dart';
import 'package:child_life/features/care_plan/care_plan_today.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con step 2 (D-135): Hôm nay "n việc cần làm", "Đến giờ rồi" (15), the person's
// reminder settings (13 / N1) and the helper on duty in the Bàn giao row (Q1). At 09:05 on
// 28/10 Ba (Minh) has Vitamin 09:00, Tắm 18:30, Đọc sách 20:00 and "Ru con ngủ" 20:30.
final l = lookupAppLocalizations(const Locale('vi'));

Future<(FakeCarePlanRepository, ProviderContainer)> _pump(
  WidgetTester tester,
  Widget child, {
  List<CarePlanItem>? plan,
  dynamic me,
  Map<String, Object> prefs = const {},
  CarePlanPrefs carePrefs = const CarePlanPrefs(),
  CareDuty? duty,
  DateTime? now,
  TextScaler? textScaler,
  Locale locale = const Locale('vi'),
  bool draft = false,
}) async {
  final repo = FakeCarePlanRepository();
  final (_, container) = await pumpRouted(
    tester,
    child,
    viewport: const Size(375, 900),
    prefs: prefs,
    textScaler: textScaler,
    locale: locale,
    overrides: [
      ...familyOverrides(
        me: me ?? minh,
        now: now ?? carePlanNow,
        duty: duty,
        carePlan: false,
      ),
      ...carePlanOverrides(
        days: {carePlanToday: plan ?? planFresh()},
        repo: repo,
        prefs: carePrefs,
        drafts: {if (draft) carePlanToday},
      ),
    ],
  );
  await tester.pumpAndSettle();
  return (repo, container);
}

Widget _gate({bool blocked = false, bool tabRoot = true}) => Scaffold(
  body: Stack(
    children: [
      Positioned(
        left: 0,
        top: 0,
        child: CarePlanDueGate(blocked: blocked, onTabRoot: () => tabRoot),
      ),
    ],
  ),
);

Future<void> _waitGate(WidgetTester tester) async {
  await tester.pump(CarePlanDueGate.delay + const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

void main() {
  group('Hôm nay "n việc cần làm" (14)', () {
    testWidgets('only my open tasks: the count, the next one, Đã làm', (
      tester,
    ) async {
      final plan = planFresh();
      final (repo, _) = await _pump(
        tester,
        const Scaffold(body: CarePlanTodaySection(enabled: true)),
        plan: plan,
      );
      expect(find.text(l.cpHomeTitle(4)), findsOneWidget);
      expect(find.text(l.cpTaskVitamin), findsOneWidget);
      // Mẹ's 07:00 and Cô Lan's tasks are not Ba's.
      expect(find.text('07:00'), findsNothing);
      await tester.tap(find.byKey(const Key('cpTodayDone')));
      await tester.pumpAndSettle();
      final vitamin = plan.firstWhere((i) => i.time == '09:00');
      expect(repo.calls.single.$2, {'itemId': vitamin.id, 'status': 'done'});
      expect(find.text(l.cpDoneToast(l.cpTaskVitamin)), findsOneWidget);
    });

    testWidgets('hidden when the switch is off, or nothing of mine is open', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(body: CarePlanTodaySection(enabled: false)),
      );
      expect(find.byKey(const Key('cpTodaySection')), findsNothing);
      await _pump(
        tester,
        const Scaffold(body: CarePlanTodaySection(enabled: true)),
        plan: [
          for (final i in planFresh())
            if (i.assignees.contains(minh.uid))
              i.copyWith(status: CarePlanStatus.done, doneBy: minh.uid)
            else
              i,
        ],
      );
      expect(find.byKey(const Key('cpTodaySection')), findsNothing);
    });

    testWidgets('a draft day is nobody\'s to-do yet (D-136)', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: CarePlanTodaySection(enabled: true)),
        draft: true,
      );
      expect(find.byKey(const Key('cpTodaySection')), findsNothing);
    });

    testWidgets('a relative is never given tasks: nothing', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: CarePlanTodaySection(enabled: true)),
        me: hoa,
      );
      expect(find.byKey(const Key('cpTodaySection')), findsNothing);
    });
  });

  group('"Đến giờ rồi" (15)', () {
    test('due from 5 minutes before to an hour after', () {
      final plan = carePlanMine(planFresh(), minh.uid);
      expect(
        carePlanDueNow(plan, DateTime(2026, 10, 28, 8, 54)).map((i) => i.time),
        isEmpty,
      );
      expect(
        carePlanDueNow(plan, DateTime(2026, 10, 28, 8, 55)).map((i) => i.time),
        ['09:00'],
      );
      expect(
        carePlanDueNow(plan, DateTime(2026, 10, 28, 10, 0)).map((i) => i.time),
        ['09:00'],
      );
      expect(
        carePlanDueNow(plan, DateTime(2026, 10, 28, 10, 1)).map((i) => i.time),
        isEmpty,
      );
    });

    testWidgets('on open: my due task; Đã làm marks it; once per device', (
      tester,
    ) async {
      final plan = planFresh();
      final (repo, container) = await _pump(tester, _gate(), plan: plan);
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsOneWidget);
      expect(find.text(l.cpTaskVitamin), findsOneWidget);
      await tester.tap(find.byKey(const Key('cpDueDone')));
      await tester.pumpAndSettle();
      final vitamin = plan.firstWhere((i) => i.time == '09:00');
      expect(repo.calls.single.$2, {'itemId': vitamin.id, 'status': 'done'});
      // Shown once on this device.
      final memory = container.read(carePlanDueMemoryProvider);
      expect(
        memory.due(
          CarePlanDueMemory.keyOf(minh.babyId, carePlanToday, vitamin.id),
          carePlanNow,
        ),
        isFalse,
      );
    });

    testWidgets('Để sau 10 phút brings it back after ten minutes', (
      tester,
    ) async {
      final plan = planFresh();
      final (repo, container) = await _pump(tester, _gate(), plan: plan);
      await _waitGate(tester);
      await tester.tap(find.byKey(const Key('cpDueLater')));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      final memory = container.read(carePlanDueMemoryProvider);
      final key = CarePlanDueMemory.keyOf(
        minh.babyId,
        carePlanToday,
        plan.firstWhere((i) => i.time == '09:00').id,
      );
      expect(
        memory.due(key, carePlanNow.add(const Duration(minutes: 9))),
        isFalse,
      );
      expect(
        memory.due(key, carePlanNow.add(const Duration(minutes: 10))),
        isTrue,
      );
    });

    testWidgets('never over the tour, a pushed screen, or one already shown', (
      tester,
    ) async {
      final plan = planFresh();
      final vitamin = plan.firstWhere((i) => i.time == '09:00');
      await _pump(tester, _gate(blocked: true), plan: plan);
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsNothing);
      await _pump(tester, _gate(tabRoot: false), plan: plan);
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsNothing);
      await _pump(
        tester,
        _gate(),
        plan: plan,
        prefs: {
          'carePlan.due.seen': [
            CarePlanDueMemory.keyOf(minh.babyId, carePlanToday, vitamin.id),
          ],
        },
      );
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsNothing);
    });

    testWidgets('a task push: its tasks, even off the tab root', (
      tester,
    ) async {
      final plan = planFresh();
      final tasks = plan.where((i) => i.time.compareTo('18:00') > 0).toList();
      final (_, container) = await _pump(
        tester,
        _gate(tabRoot: false),
        plan: plan,
      );
      container.read(carePlanDueRequestProvider.notifier).open((
        babyId: minh.babyId,
        date: carePlanToday,
        ids: [for (final i in tasks) i.id],
        done: false,
      ));
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsOneWidget);
      expect(find.text(l.cpDueDoneAll(tasks.length)), findsOneWidget);
      expect(container.read(carePlanDueRequestProvider), isNull);
    });

    testWidgets('the push\'s "Xong" (N1): done at once, no sheet', (
      tester,
    ) async {
      final plan = planFresh();
      final bath = plan.firstWhere((i) => i.task == CarePlanTask.bath);
      final (repo, container) = await _pump(
        tester,
        _gate(tabRoot: false),
        plan: plan,
      );
      container.read(carePlanDueRequestProvider.notifier).open((
        babyId: minh.babyId,
        date: carePlanToday,
        ids: [bath.id],
        done: true,
      ));
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsNothing);
      final (name, args) = repo.calls.single;
      expect(name, 'status');
      expect(args, {'itemId': bath.id, 'status': 'done'});
    });

    testWidgets('a push for a task already done: the day plan and a toast', (
      tester,
    ) async {
      final plan = planUnderway();
      final done = plan.firstWhere((i) => i.done);
      final (_, container) = await _pump(tester, _gate(), plan: plan);
      container.read(carePlanDueRequestProvider.notifier).open((
        babyId: minh.babyId,
        date: carePlanToday,
        ids: [done.id],
        done: false,
      ));
      await _waitGate(tester);
      expect(find.text(l.cpDueTitle), findsNothing);
      expect(find.text(l.cpDueGone), findsOneWidget);
    });
  });

  group('reminder settings (13, N1)', () {
    testWidgets('Nhắc trước and quiet hours are saved; Tắt hides quiet hours', (
      tester,
    ) async {
      final (repo, _) = await _pump(tester, const CarePlanSettingsScreen());
      expect(find.text(l.cpQuietHours), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cp_lead_10')));
      await tester.pumpAndSettle();
      expect(repo.calls.last.$2, {
        'leadMinutes': 10,
        'quietHours': true,
        'team': true,
      });
      await tester.tap(find.text(l.cpQuietHours));
      await tester.pumpAndSettle();
      await _pump(
        tester,
        const CarePlanSettingsScreen(),
        carePrefs: const CarePlanPrefs(leadMinutes: 0),
      );
      expect(find.text(l.cpQuietHours), findsNothing);
    });

    testWidgets('"Khi người khác làm xong" (N2 / N3) is saved, even with Tắt', (
      tester,
    ) async {
      final (repo, _) = await _pump(
        tester,
        const CarePlanSettingsScreen(),
        carePrefs: const CarePlanPrefs(leadMinutes: 0),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('cp_team')),
          matching: find.byType(ClToggle),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls.last.$2, {
        'leadMinutes': 0,
        'quietHours': true,
        'team': false,
      });
    });

    testWidgets('"Tự tạo lịch mỗi sáng": plan managers only, off by default', (
      tester,
    ) async {
      final (repo, _) = await _pump(
        tester,
        const CarePlanSettingsScreen(),
        me: mai,
      );
      expect(find.text(l.cpPlanSection), findsOneWidget);
      final toggle = find.descendant(
        of: find.byKey(const Key('cp_auto_draft')),
        matching: find.byType(ClToggle),
      );
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(repo.calls.last.$1, 'autoDraft');
      expect(repo.calls.last.$2, {'on': true});
      await _pump(tester, const CarePlanSettingsScreen(), me: lan);
      expect(find.text(l.cpAutoDraft), findsNothing);
    });
  });

  testWidgets('200 % text: section, sheet and settings do not overflow', (
    tester,
  ) async {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      await _pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: CarePlanTodaySection(enabled: true),
          ),
        ),
        textScaler: const TextScaler.linear(2),
        locale: locale,
      );
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        _gate(),
        textScaler: const TextScaler.linear(2),
        locale: locale,
      );
      await _waitGate(tester);
      expect(find.byKey(const Key('cpDueDone')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        const CarePlanSettingsScreen(),
        textScaler: const TextScaler.linear(2),
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    }
  });

  group('Bàn giao row: who is caring (Q1)', () {
    String? line(WidgetTester tester, ProviderContainer c) =>
        (tester.widget(find.byKey(const Key('probe'))) as Text).data;

    Widget probe() => Consumer(
      builder: (context, ref, _) => Text(
        carePlanHelperOnDuty(ref, AppLocalizations.of(context), minh) ?? '-',
        key: const Key('probe'),
      ),
    );

    testWidgets('a helper on duty, until their last task', (tester) async {
      final (_, c) = await _pump(
        tester,
        Scaffold(body: probe()),
        duty: CareDuty(
          uid: lan.uid,
          since: carePlanNow.subtract(const Duration(hours: 2)),
        ),
      );
      expect(line(tester, c), l.cpHelperOnUntil('Cô Lan', '13:00'));
    });

    testWidgets('never Ba or Mẹ, never "nobody"', (tester) async {
      var (_, c) = await _pump(
        tester,
        Scaffold(body: probe()),
        duty: CareDuty(uid: mai.uid, since: carePlanNow),
      );
      expect(line(tester, c), '-');
      (_, c) = await _pump(tester, Scaffold(body: probe()));
      expect(line(tester, c), '-');
    });
  });
}
