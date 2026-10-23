import 'dart:async';
import 'dart:convert';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/rhythm/personalization_v2_repository.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart' show isoOf;
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D-091: the reduced Home copy of today's personal snapshot.
void main() {
  final now = DateTime.now();
  final today = isoOf(now);
  const key = (babyId: 'b_teddy', uid: 'u_mai', locale: 'vi');

  PersonalDay full({bool health = false}) => PersonalDay({
    'asOf': now.subtract(const Duration(minutes: 1)).toUtc().toIso8601String(),
    'expiresAt': now.add(const Duration(hours: 2)).toUtc().toIso8601String(),
    'today': today,
    'writable': true,
    'health': health,
    'context': 'few_minutes',
    'activityIds': ['act_walk'],
    'weekly': {'tried': 1, 'helpful': 0},
    'notes': [
      {'text': 'Bé dị ứng trứng', 'scope': 'baby'},
    ],
    'lastRecords': [
      {'type': 'bottle', 'at': '2026-10-08T02:30:00Z', 'amountMl': 90},
    ],
    'work': [
      {'id': 'rm_1', 'title': 'Uống thuốc'},
    ],
    'patterns': [
      {'kind': 'feed_interval', 'lowMinutes': 120},
    ],
    'ageCardId': 'age_week_3',
    'sleep': {'recent': 600, 'baseline': 620},
    'responses': {
      'act_walk': {
        'value': 'intend',
        'intendedAt': '2026-10-08T02:00:00Z',
        'note': 'x',
      },
      'work:rm_1': {'value': 'snooze'},
    },
  });

  test('keeps only what the Home card needs, and no child data', () {
    final copy = PersonalDayHomeCache.reduce(full())!;
    final text = jsonEncode(copy);
    for (final gone in [
      'notes',
      'lastRecords',
      'work',
      'patterns',
      'ageCardId',
      'sleep',
      'health',
    ]) {
      expect(copy.containsKey(gone), isFalse, reason: gone);
    }
    expect(text, isNot(contains('dị ứng')));
    expect(text, isNot(contains('Uống thuốc')));
    expect(copy['responses'], {
      'act_walk': {'value': 'intend', 'intendedAt': '2026-10-08T02:00:00Z'},
    });
    expect(copy['context'], 'few_minutes');
  });

  test('a health day keeps nothing and removes the old copy', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = PersonalDayHomeCache(prefs);
    cache.write(key, full());
    expect(cache.read(key, now), isNotNull);
    cache.write(key, full(health: true));
    expect(cache.read(key, now), isNull);
    expect(PersonalDayHomeCache.reduce(full(health: true)), isNull);
  });

  test('an expired copy is not used, and another person has none', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = PersonalDayHomeCache(prefs);
    cache.write(key, full());
    expect(cache.read(key, now.add(const Duration(hours: 3))), isNull);
    expect(
      cache.read((babyId: 'b_teddy', uid: 'u_minh', locale: 'vi'), now),
      isNull,
    );
  });

  Future<ProviderContainer> container({
    required Future<PersonalDay> fresh,
    List<CheckIn> checkIns = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    PersonalDayHomeCache(prefs).write(key, full());
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        personalDayProvider.overrideWith((ref, _) => fresh),
        checkInsProvider.overrideWith((ref, _) => Stream.value(checkIns)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'Home draws from the copy while the server answers, then the fresh one',
    () async {
      final pending = Completer<PersonalDay>();
      final c = await container(fresh: pending.future);
      final sub = c.listen(personalDayHomeProvider(key), (_, _) {});
      await c.read(checkInsProvider(key.babyId).future);
      expect(sub.read()?.data['fromCache'], isTrue);
      expect(sub.read()?.activityIds, ['act_walk']);
      pending.complete(full());
      await c.read(personalDayProvider(key).future);
      expect(sub.read()?.data['fromCache'], isNull);
      expect(sub.read()?.notes, isNotEmpty);
    },
  );

  test('a health sign noted since keeps the copy off Home', () async {
    final c = await container(
      fresh: Completer<PersonalDay>().future,
      checkIns: [
        CheckIn(
          id: 'ci_1',
          babyId: key.babyId,
          date: today,
          authorUid: 'u_minh',
          observation: Observation.health,
          healthSigns: const [HealthSign.breathing],
        ),
      ],
    );
    final sub = c.listen(personalDayHomeProvider(key), (_, _) {});
    await c.read(checkInsProvider(key.babyId).future);
    expect(sub.read(), isNull);
  });
}
