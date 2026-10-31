import 'package:child_life/features/insights/insight_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'rhythm_fixtures.dart';

/// Hiểu con fixtures (synthetic), read on the morning of 8 Oct 2026 in Hà Nội (`careNow`): the
/// server's document `babies/{b}/insights/current` as JSON, parsed by the app's own reader.
/// Recent nights 1–7 Oct (the night of 3 Oct not counted), the week before 24–30 Sep.
DateTime vnAt(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, month, day, hour - 7, minute);

Map<String, Object?> longestUp() => {
  'kind': 'night_longest',
  'direction': 'up',
  'unit': 'minutes',
  'value': 172,
  'baselineValue': 141,
  'delta': 31,
  'recent': {'from': '2026-10-01', 'to': '2026-10-07'},
  'baseline': {'from': '2026-09-24', 'to': '2026-09-30'},
  'coverage': {'valid': 6, 'total': 7},
  'baselineCoverage': {'valid': 7, 'total': 7},
  'points': [
    for (final (i, v) in [140, 150, 128, 146, 145, 139, 139].indexed)
      {'date': '2026-09-${24 + i}', 'value': v, 'reason': null},
    for (final (i, v) in [158, 168, null, 175, 172, 180, 179].indexed)
      {
        'date': '2026-10-0${1 + i}',
        'value': v,
        'reason': v == null ? 'no_sleep' : null,
      },
  ],
  'peak': {
    'date': '2026-10-06',
    'value': 180,
    'startedAt': '2026-10-06T15:40:00.000Z',
  },
  'authors': [
    {'name': 'Mai', 'relation': 'mother'},
    {'name': 'Minh', 'relation': 'father'},
  ],
  'todayEligible': true,
  'score': 1.4,
};

Map<String, Object?> feedsDown() => {
  ...longestUp(),
  'kind': 'night_feeds',
  'direction': 'down',
  'unit': 'count',
  'value': 2,
  'baselineValue': 3,
  'delta': -1,
  'points': [
    for (var i = 0; i < 7; i++)
      {'date': '2026-09-${24 + i}', 'value': 3, 'reason': null},
    for (var i = 0; i < 7; i++)
      {
        'date': '2026-10-0${1 + i}',
        'value': i == 2 ? null : 2,
        'reason': i == 2 ? 'no_sleep' : null,
      },
  ],
  'peak': null,
  'score': 0.7,
};

Map<String, dynamic> insightDoc({
  bool premium = true,
  List<Map<String, Object?>>? items,
  int validNights = 6,
  String? today = 'night_longest',
  String todayOn = '2026-10-08',
  String? teaser,
  DateTime? computedAt,
}) => {
  'ruleVersion': 1,
  'computedAt': Timestamp.fromDate(computedAt ?? vnAt(10, 8, 6, 30)),
  'windowStart': Timestamp.fromDate(vnAt(9, 24, 18)),
  'windowEnd': Timestamp.fromDate(vnAt(10, 8, 6)),
  'from': '2026-09-24',
  'to': '2026-10-07',
  'premium': premium,
  'items': premium ? (items ?? [longestUp(), feedsDown()]) : const [],
  'progress': {'validNights': validNights, 'neededNights': 5},
  'today': premium ? today : null,
  'todayOn': todayOn,
  'teaser': teaser == null ? null : {'kind': teaser, 'direction': 'up'},
  'teaserOn': teaser == null ? null : '2026-10-08',
  'lastTodayOn': {'night_longest': '2026-10-08'},
};

Capabilities insightCaps({bool premium = true}) => Capabilities.fromJson(
  rhythmCaps(plan: premium ? 'premium' : 'free', groupA: premium),
)!;

/// The server's document and this person's answers that `familyOverrides()` serves (none).
final testInsightDocProvider = Provider<Map<String, dynamic>?>((ref) => null);
final testInsightPrefsProvider = Provider<InsightPrefs>(
  (ref) => const InsightPrefs(),
);

/// Overrides on top of `careOverrides()`: the plan, the server's document, the answers.
List<Override> insightOverrides({
  bool premium = true,
  Map<String, dynamic>? doc,
  InsightPrefs prefs = const InsightPrefs(),
}) => [
  testInsightDocProvider.overrideWithValue(doc),
  testInsightPrefsProvider.overrideWithValue(prefs),
  selectedCapabilitiesProvider.overrideWithValue(insightCaps(premium: premium)),
];
