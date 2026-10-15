import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'care_fixtures.dart';
import 'family_fixtures.dart';
import 'rhythm_fixtures.dart';

/// EN09 "Tóm tắt tuần" fixtures (synthetic; the mock's "Tuần 4" and figures are not copied).
/// With "today" Thursday 8/10 the summary is Mon 28/9 – Sun 4/10, Teddy's week 3 (born 17/09);
/// on Sunday 11/10 20:45 it is 5/10 – 11/10, week 4, still running.

/// Sunday 11/10/2026 20:45 in Hồ Chí Minh (after the 20:30 notification).
final sundayNow = DateTime.utc(2026, 10, 11, 13, 45);

/// [hour]:[minute] on [date] in Hồ Chí Minh.
DateTime vnAt(String date, int hour, [int minute = 0]) {
  final p = date.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2], hour - 7, minute);
}

/// A care log for the week starting [monday]. Full days: night sleep 19:00 → 06:00 (Ba), nap
/// 11:00–13:00 (Ba; Sunday 11:00–14:00), bottles 7:00 (90 ml, Mẹ) and 14:00 (100 ml, Ba),
/// breastfeeds 9:00 (15 min) and 17:00 (20 min, Mẹ), a wet diaper 10:00 and a dirty one 15:00
/// (Cô Lan). Wednesday holds only the end of Tuesday's night (long gaps: not valid) and Thursday
/// only the start of its night (not valid): 5/7 valid days, 13 h on four of them, 14 h on
/// Sunday. [fullDays] narrows the full days (by index, Monday = 0). Nothing after [until]
/// (a sleep still running is left out). [nightBefore]: the Sunday night crossing into Monday
/// (leave it out when the week before is logged too).
List<CareRecord> weekLog({
  String monday = '2026-09-28',
  Set<int> fullDays = const {0, 1, 4, 5, 6},
  DateTime? until,
  bool nightBefore = true,
}) {
  final out = <CareRecord>[];
  final last = until ?? DateTime.utc(2100);
  void add(CareRecord r) {
    if (r.occurredAt.isAfter(last)) return;
    if (r.endedAt != null && r.endedAt!.isAfter(last)) return;
    out.add(r);
  }

  // The night before the week (crosses into Monday).
  if (nightBefore) {
    final sunday = addDaysIso(monday, -1);
    add(rec(CareType.sleep, vnAt(sunday, 19), minh, endedAt: vnAt(monday, 6)));
  }
  for (var i = 0; i < 7; i++) {
    final d = addDaysIso(monday, i);
    final next = addDaysIso(d, 1);
    if (fullDays.contains(i)) {
      add(rec(CareType.bottle, vnAt(d, 7), mai, amountMl: 90));
      add(rec(CareType.breast, vnAt(d, 9), mai, durationMin: 15));
      add(rec(CareType.diaper, vnAt(d, 10), lan, diaper: DiaperKind.wet));
      add(
        rec(
          CareType.sleep,
          vnAt(d, 11),
          minh,
          endedAt: vnAt(d, i == 6 ? 14 : 13),
        ),
      );
      add(rec(CareType.bottle, vnAt(d, 14), minh, amountMl: 100));
      add(rec(CareType.diaper, vnAt(d, 15), lan, diaper: DiaperKind.dirty));
      add(rec(CareType.breast, vnAt(d, 17), mai, durationMin: 20));
    }
    // The night from this day: on full days, and Thursday (index 3) as the start of Friday.
    if (fullDays.contains(i) || i == 3) {
      add(rec(CareType.sleep, vnAt(d, 19), minh, endedAt: vnAt(next, 6)));
    }
  }
  return out;
}

const allDays = {0, 1, 2, 3, 4, 5, 6};

/// Two whole weeks before 28/9 and then [weekLog]: enough valid days for the sleep comparison
/// (the usual level, 13 h, is kept: "gần với mức thường").
List<CareRecord> longLog() => [
  ...weekLog(monday: '2026-09-14', fullDays: allDays),
  ...weekLog(monday: '2026-09-21', fullDays: allDays, nightBefore: false),
  ...weekLog(nightBefore: false),
];

/// Weighed Friday 2/10 (4,3 kg · 54,5 cm), after 3,9 kg on 24/9.
List<CareRecord> weekGrowth() => [
  rec(
    CareType.growth,
    vnAt('2026-09-24', 9),
    mai,
    weightKg: 3.9,
    measuredOn: DateTime(2026, 9, 24),
  ),
  rec(
    CareType.growth,
    vnAt('2026-10-02', 9),
    mai,
    weightKg: 4.3,
    lengthCm: 54.5,
    measuredOn: DateTime(2026, 10, 2),
  ),
];

/// Two moments in the week (3 photos and a video; a note) and one before it.
List<Memory> weekMemories() => [
  for (final (i, (date, photos, videos, media)) in const [
    ('2026-09-29', 3, 1, 4),
    ('2026-10-03', 0, 0, 0),
    ('2026-09-20', 5, 0, 5),
  ].indexed)
    Memory(
      id: 'm_$i',
      babyId: teddyId,
      audience: Audience.family,
      occurredAt: vnAt(date, 10),
      createdBy: 'u_mai',
      author: CareAuthor.of(mai),
      mediaIds: [for (var k = 0; k < media; k++) 'md_${i}_$k'],
      photos: photos,
      videos: videos,
    ),
];

/// [rhythmOverrides] plus the week's care log, growth and Kỷ niệm (served by range like
/// Firestore would).
List<Override> weekOverrides({
  required FakeRhythmRepository repo,
  Membership? me,
  Map<String, Object?>? caps,
  List<CareRecord>? log,
  List<CareRecord>? growth,
  List<Memory>? memories,
  List<Reminder> reminders = const [],
  DateTime? now,
}) {
  final records = log ?? weekLog();
  return [
    ...rhythmOverrides(
      repo: repo,
      me: me,
      caps: caps,
      sleepRecords: records,
      growth: growth ?? weekGrowth(),
      reminders: reminders,
      now: now,
    ),
    rangeRecordsProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final r in records)
          if (!r.occurredAt.isBefore(key.$2) && r.occurredAt.isBefore(key.$3))
            r,
      ]),
    ),
    memoriesProvider.overrideWith(
      (ref, key) => Stream.value(memories ?? weekMemories()),
    ),
  ];
}
