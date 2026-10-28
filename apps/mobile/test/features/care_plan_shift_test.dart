import 'package:child_life/features/ai/ai_models.dart';
import 'package:child_life/features/ai/handover_screen.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/care_plan/care_plan_shift.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/ai_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con step 3 (D-135; ANALYSIS §3, §4): the helper's Hôm nay on a shift day (16), their
// handover to both parents (17) and the family's single receipt. 8/10 at 10:00 in Hồ Chí Minh:
// Cô Lan has Ngủ 08:30, Thay tã 10:30 and Bú bình 13:00.
final l = lookupAppLocalizations(const Locale('vi'));
const _day = '2026-10-08';

Future<void> _tap(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('helper’s Hôm nay (16)', () {
    Future<List<bool>> pumpHome(
      WidgetTester tester, {
      dynamic me,
      CareDuty? duty,
    }) async {
      final writes = <bool>[];
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        viewport: const Size(375, 2400),
        overrides: [
          ...careOverrides(me: me ?? lan, carePlan: false, duty: duty),
          ...carePlanOverrides(days: {_day: planFresh()}),
          careDutyWriterProvider.overrideWithValue((
            babyId, {
            required take,
          }) async {
            writes.add(take);
          }),
        ],
      );
      await tester.pumpAndSettle();
      return writes;
    }

    testWidgets('the shift: greeting, card, my tasks, notes; Bắt đầu ca', (
      tester,
    ) async {
      final writes = await pumpHome(tester);
      expect(find.text(l.cpShiftHello('Cô Lan')), findsOneWidget);
      expect(find.byType(TodayLivingHeader), findsNothing);
      expect(find.text('08:30 – 13:00'), findsOneWidget);
      expect(find.text(l.cpShiftLeft(3)), findsOneWidget);
      expect(find.byKey(const Key('cpMyTasks')), findsOneWidget);
      expect(find.byKey(const Key('cpShiftNotes')), findsOneWidget);
      // The parents' section is not the helper's.
      expect(find.byKey(const Key('cpTodaySection')), findsNothing);
      await _tap(tester, find.byKey(const Key('cpShiftStart')));
      expect(writes, [true]);
    });

    testWidgets('on duty: since when, no start button', (tester) async {
      await pumpHome(
        tester,
        duty: CareDuty(uid: lan.uid, since: DateTime.utc(2026, 10, 8, 0, 5)),
      );
      expect(find.text(l.cpShiftOnSince('07:05')), findsOneWidget);
      expect(find.byKey(const Key('cpShiftStart')), findsNothing);
    });

    testWidgets('Ba and Mẹ keep their Hôm nay', (tester) async {
      await pumpHome(tester, me: mai);
      expect(find.byType(TodayLivingHeader), findsOneWidget);
      expect(find.byKey(const Key('cpShiftCard')), findsNothing);
    });

    testWidgets('notes are kept on this phone and become the message', (
      tester,
    ) async {
      await pumpHome(tester);
      await _tap(tester, find.byKey(const ValueKey('cpNoteTag_ateWell')));
      await _tap(tester, find.byKey(const ValueKey('cpNoteTag_sleptWell')));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('cpNoteText')),
          matching: find.byType(EditableText),
        ),
        'Khăn sạch ở ngăn trên',
      );
      await tester.pumpAndSettle();
      final note = CarePlanShiftNote(
        tags: {CarePlanNoteTag.ateWell, CarePlanNoteTag.sleptWell},
        text: 'Khăn sạch ở ngăn trên',
      );
      expect(note.message(l), 'Ăn ngon · Ngủ sâu. Khăn sạch ở ngăn trên');
      // Kept on this phone for the day, never sent until the handover.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('carePlan.shiftNote.$teddyId.$_day'),
        contains('Khăn sạch ở ngăn trên'),
      );
    });
  });

  group('Bàn giao from a helper to the parents (17)', () {
    testWidgets(
      'to Ba và Mẹ, the shift, the tasks left, the message; one send for both',
      (tester) async {
        final ai = FakeAiRepository(stored: [handover()])..sender = lan.uid;
        await pumpRouted(
          tester,
          const HandoverScreen(),
          viewport: const Size(375, 3200),
          prefs: {
            'carePlan.shiftNote.$teddyId.$_day':
                '{"tags":["smiles"],"text":"Khăn sạch ở ngăn trên"}',
          },
          overrides: [
            ...aiOverrides(
              ai: ai,
              member: lan,
              carePlan: false,
              duty: CareDuty(uid: lan.uid, since: DateTime.utc(2026, 10, 8, 0)),
            ),
            ...carePlanOverrides(days: {_day: planFresh()}),
          ],
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('handoverWho')), findsOneWidget);
        expect(find.text(l.hoShiftEnds('13:00')), findsOneWidget);
        expect(find.text(l.hoInShift), findsOneWidget);
        expect(find.byKey(const Key('cpRemaining')), findsOneWidget);
        expect(
          find.text('“Cười nhiều. Khăn sạch ở ngăn trên”'),
          findsOneWidget,
        );
        // A helper never picks one person here: both parents receive it.
        expect(find.byKey(const Key('handoverSend')), findsNothing);
        await _tap(tester, find.byKey(const Key('handoverSendParents')));
        expect(ai.sends.map((s) => s.recipientUid).toSet(), {
          mai.uid,
          minh.uid,
        });
        expect(ai.sends.every((s) => s.family), isTrue);
        expect(ai.sends.first.note, 'Cười nhiều. Khăn sạch ở ngăn trên');
        expect(find.byKey(const Key('handoverSendStatus')), findsOneWidget);
      },
    );

    testWidgets('the other parent received it first: no second receipt', (
      tester,
    ) async {
      final h = handover();
      final ai = FakeAiRepository(stored: [h]);
      ai.sends.addAll([
        for (final to in [mai.uid, minh.uid])
          HandoverSend(
            id: 'hs_$to',
            summaryId: h.id,
            senderUid: lan.uid,
            recipientUid: to,
            sentAt: DateTime.utc(2026, 10, 8, 10),
            note: 'Bé ngủ ngon',
            family: true,
          ),
      ]);
      await pumpRouted(
        tester,
        HandoverScreen(summaryId: h.id, summaryOpen: true),
        viewport: const Size(375, 3200),
        overrides: aiOverrides(ai: ai, member: mai),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.hoSentToFamily('Cô Lan', '17:00')), findsOneWidget);
      expect(find.text('“Bé ngủ ngon”'), findsOneWidget);
      // Mẹ's own row: the server settled it when Ba received his (the fake mirrors it here).
      await ai.markHandover(
        babyId: teddyId,
        sendId: 'hs_${minh.uid}',
        received: true,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('handoverAcknowledge')), findsNothing);
      expect(find.text(l.aiSendReceived('Ba', '20:42')), findsOneWidget);
    });

    testWidgets('a parent acknowledges, never "Tôi nhận trông bé"', (
      tester,
    ) async {
      final h = handover();
      final ai = FakeAiRepository(stored: [h]);
      ai.sends.add(
        HandoverSend(
          id: 'hs_one',
          summaryId: h.id,
          senderUid: lan.uid,
          recipientUid: mai.uid,
          sentAt: DateTime.utc(2026, 10, 8, 10),
          family: true,
        ),
      );
      await pumpRouted(
        tester,
        HandoverScreen(summaryId: h.id, summaryOpen: true),
        viewport: const Size(375, 3200),
        overrides: aiOverrides(ai: ai, member: mai),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.pv2Acknowledge), findsOneWidget);
      expect(find.text(l.hoTakeOver), findsNothing);
    });
  });
}
