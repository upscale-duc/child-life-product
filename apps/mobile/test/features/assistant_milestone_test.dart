import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/milestones/milestone_models.dart';
import 'package:child_life/features/milestones/milestone_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/milestone_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi L5 (Mốc): "bé biết lẫy rồi" offers the milestone's own record sheet, on the day said.
/// Teddy was born 17/09/2026; today is Thursday 08/10/2026.
final l10n = lookupAppLocalizations(const Locale('vi'));

void main() {
  test('only a reference milestone page, with only a well-formed day', () {
    expect(
      milestoneRoute('/utilities/milestones/rolls_over?record=2026-10-31'),
      '/utilities/milestones/rolls_over?record=2026-10-31',
    );
    expect(
      milestoneRoute('/utilities/milestones/rolls_over'),
      '/utilities/milestones/rolls_over',
    );
    for (final bad in [
      null,
      'https://evil.example/utilities/milestones/rolls_over',
      '/utilities/milestones/rolls_over?record=31/10',
      '/utilities/milestones/rolls_over?record=2026-10-31&next=/me',
      '/utilities/milestones/own',
      '/utilities/milestones/Rolls',
      '/utilities/milestones',
    ]) {
      expect(milestoneRoute(bad), isNull, reason: bad);
    }
  });

  testWidgets('"Bé đã làm được" opens once on the day said; saved there', (
    tester,
  ) async {
    final repo = FakeMilestoneRepository();
    await pumpRouted(
      tester,
      MilestoneDetailScreen(id: 'first_smile', recordOn: DateTime(2026, 10, 7)),
      overrides: [
        ...familyOverrides(
          me: mai,
          now: DateTime(2026, 10, 8, 10),
          milestones: repo,
        ),
        ...memoryOverrides(),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.mtDateDid), findsOneWidget);
    expect(find.text('Thứ Tư, 07/10/2026'), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.mtSave));
    await tester.tap(find.text(l10n.mtSave));
    await tester.pumpAndSettle();
    expect(repo.writes.last, 'observe p_first_smile');
    expect(repo.records.single.status, RecordStatus.observed);
    expect(repo.records.single.date, DateTime(2026, 10, 7));
    expect(find.text(l10n.mtDateDid), findsNothing);
  });

  testWidgets('a caregiver gets no sheet', (tester) async {
    await pumpRouted(
      tester,
      MilestoneDetailScreen(id: 'first_smile', recordOn: DateTime(2026, 10, 7)),
      overrides: [
        ...familyOverrides(
          me: lan,
          now: DateTime(2026, 10, 8, 10),
          milestones: FakeMilestoneRepository(),
        ),
        ...memoryOverrides(),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.mtDateDid), findsNothing);
  });
}
