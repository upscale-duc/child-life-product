@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/ai/ai_models.dart';
import 'package:child_life/features/ai/handover_screen.dart';
import 'package:child_life/features/care/care_duty.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ai_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con step 3 (D-135): Cô Lan's Hôm nay on her shift (16), her Bàn giao to Ba và Mẹ
// (17: who, "Trong ca", the tasks left, her message) and Mẹ reading it after Ba received it.
// Synthetic data, Light / Night care × vi / en.
// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/care_plan_shift_golden_test.dart

const _day = '2026-10-08';

/// Cô Lan's morning done (Ngủ 08:30), the rest open.
List<CarePlanItem> _plan() => [
  for (final i in planFresh())
    if (i.time == '08:30')
      i.copyWith(status: CarePlanStatus.done, doneBy: lan.uid)
    else if (i.time == '07:00')
      i.copyWith(status: CarePlanStatus.done, doneBy: mai.uid)
    else
      i,
];

final _onDuty = CareDuty(uid: lan.uid, since: DateTime.utc(2026, 10, 8, 0, 5));
const _note = '{"tags":["ateWell","smiles"],"text":"Khăn sạch ở ngăn trên"}';

typedef _Case = ({
  Widget child,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  double height,
});

FakeAiRepository _received() {
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
        seenAt: DateTime.utc(2026, 10, 8, 10, 5),
        receivedAt: DateTime.utc(2026, 10, 8, 10, 5),
        receivedBy: minh.uid,
        shiftSince: DateTime.utc(2026, 10, 8, 0, 5),
        note: 'Ăn ngon · Cười nhiều. Khăn sạch ở ngăn trên',
        family: true,
      ),
  ]);
  return ai;
}

final _cases = <String, _Case>{
  'helper_home': (
    child: const Scaffold(body: TodayScreen()),
    overrides: () => [
      // The rollout flags on, as in the family's app (Bàn giao needs `rhythm` + `ai_assist`).
      ...aiOverrides(
        ai: FakeAiRepository(),
        member: lan,
        records: mockDay(),
        carePlan: false,
        duty: _onDuty,
      ),
      ...carePlanOverrides(days: {_day: _plan()}),
    ],
    prefs: {'carePlan.shiftNote.$teddyId.$_day': _note},
    height: 1900,
  ),
  'handover_helper': (
    child: const HandoverScreen(),
    overrides: () => [
      ...aiOverrides(
        ai: FakeAiRepository(stored: [handover()])..sender = lan.uid,
        member: lan,
        records: mockDay(),
        carePlan: false,
        duty: _onDuty,
      ),
      ...carePlanOverrides(days: {_day: _plan()}),
    ],
    prefs: {'carePlan.shiftNote.$teddyId.$_day': _note},
    height: 2600,
  ),
  'handover_family_received': (
    child: HandoverScreen(summaryId: handover().id),
    overrides: () => [
      ...aiOverrides(
        ai: _received(),
        member: mai,
        records: mockDay(),
        carePlan: false,
      ),
      ...carePlanOverrides(days: {_day: _plan()}),
    ],
    prefs: const {},
    height: 2600,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('care plan shift $name ${palette.name} $language', (
          tester,
        ) async {
          debugDisableShadows = false;
          try {
            await pumpRouted(
              tester,
              c.child,
              locale: Locale(language),
              palette: palette,
              viewport: Size(375, c.height),
              prefs: c.prefs,
              overrides: c.overrides(),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(Overlay).first,
              matchesGoldenFile(
                'goldens/care_plan_shift/${name}_${palette.name}_$language.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
