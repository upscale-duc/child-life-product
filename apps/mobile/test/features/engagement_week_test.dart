import 'package:child_life/features/engagement/engagement_week.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// AI-15 (audit 2026-10-26 §2.5): "Nhìn lại tuần qua" tells expired from failed, never loops on
/// "Thử lại", never shows a skeleton forever or a blank page.
final l = lookupAppLocalizations(const Locale('vi'));

Future<void> _pump(
  WidgetTester tester,
  Future<Map<String, dynamic>> Function() week, {
  AsyncValue<List<MediaItem>> media = const AsyncValue.data([]),
}) => pumpRouted(
  tester,
  EngagementWeekScreen(id: 'a' * 64),
  overrides: <Override>[
    ...familyOverrides(),
    engagementWeekProvider.overrideWith((ref, _) => week()),
    completeMediaProvider.overrideWith((ref, _) => media),
  ],
);

Map<String, dynamic> _ready({List<String> media = const ['m1']}) => {
  'state': 'ready',
  'babyId': teddyId,
  'content': {'mediaIds': media, 'storyIds': <String>[]},
};

void main() {
  testWidgets('another account or a gone recap: expired, no retry loop', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => throw FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'not-allowed',
      ),
    );
    expect(find.text(l.engExpired), findsOneWidget);
    expect(find.text(l.engRetry), findsNothing);
  });

  testWidgets('a network or server failure: says so, with a retry', (
    tester,
  ) async {
    await _pump(
      tester,
      () async =>
          throw FirebaseFunctionsException(code: 'unavailable', message: 'x'),
    );
    expect(find.text(l.engWeekFailed), findsOneWidget);
    expect(find.text(l.engRetry), findsOneWidget);
  });

  testWidgets('nothing of the week is left: said so, not a blank page', (
    tester,
  ) async {
    await _pump(tester, () async => _ready());
    expect(find.text(l.engWeekEmpty), findsOneWidget);
  });

  testWidgets('the photos fail to load: an error, not an endless skeleton', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => _ready(),
      media: AsyncValue.error(StateError('x'), StackTrace.empty),
    );
    expect(find.text(l.engWeekMediaFailed), findsOneWidget);
  });
}
