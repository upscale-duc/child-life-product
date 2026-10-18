import 'package:child_life/features/memories/media_picker.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/features/milestones/milestone_screens.dart';
import 'package:child_life/features/milestones/milestone_widgets.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/family_fixtures.dart';
import '../../helpers/memory_fixtures.dart';
import '../../helpers/milestone_fixtures.dart';
import '../../helpers/router_pump.dart';

final l10n = lookupAppLocalizations(const Locale('vi'));

/// Like the real picker: a full page pushed over the sheet that pops with the selection.
class _PagePicker implements MediaLibraryPicker {
  _PagePicker(this.result);
  final List<PickedMedia> result;

  @override
  Future<List<PickedMedia>?> pick(
    BuildContext context, {
    required int max,
    required VideoLimits limits,
  }) => Navigator.of(context, rootNavigator: true).push<List<PickedMedia>>(
    MaterialPageRoute(
      builder: (page) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(page).maybePop(result),
          child: const Text('done'),
        ),
      ),
    ),
  );
}

Future<void> _openRecordSheet(
  WidgetTester tester,
  List<PickedMedia> pick,
) async {
  await pumpRouted(
    tester,
    const MilestoneDetailScreen(id: 'first_smile'),
    overrides: [
      ...familyOverrides(
        me: mai,
        now: DateTime(2026, 10, 8, 10),
        milestones: FakeMilestoneRepository(),
      ),
      ...memoryOverrides(),
      mediaLibraryPickerProvider.overrideWithValue(_PagePicker(pick)),
    ],
  );
  final mark = find.text(l10n.mtMarkSeen);
  await tester.ensureVisible(mark);
  await tester.tap(mark);
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(l10n.mtAddPhotos));
  await tester.pumpAndSettle();
  await tester.tap(find.text('done'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('3c: picked photos and videos show in the strip', (tester) async {
    await _openRecordSheet(tester, [
      pickedPhoto('a.jpg'),
      pickedVideo('b.mov'),
    ]);
    expect(find.byType(MtPickedImage), findsNWidgets(2));
    // The video keeps Kỷ niệm's play badge.
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
