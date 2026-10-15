import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show decimal, durationLabel;
import '../care/care_repository.dart' show inBabyZone;
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_rules.dart';
import 'assistant_time.dart' show wallAfter, wallBefore;
import 'assistant_widgets.dart' show AsFixChip, AsFixRow;

/// Lumi 2026-10-16 (owner: "Tự động hiển thị sửa được không, chứ phải ấn vào Sửa nữa. Mẹ bỉm
/// không có thời gian nhiều."): what a "Cần kiểm tra" draft is missing, in plain words, with
/// the fix in place — chips first, a picker or the full editor ("Khác…") only when no chip fits.
/// Every row patches the draft (`patchDraft`) with the field it fixes as confirmed; the server
/// then says whether anything still blocks. Optional fields ("ban ngày / ban đêm" of a sleep
/// note) are offered, muted, and never block.

/// What the fixes do (the screen supplies them).
class FixActions {
  const FixActions({
    required this.patch,
    required this.edit,
    required this.pickTime,
    required this.pickDate,
  });

  /// `patchDraft` with [confirmed] = the field(s) the person just set or confirmed.
  final Future<void> Function(DraftPayload payload, List<String> confirmed)
  patch;

  /// The full editor (CH06 sheet) for what a chip cannot say ("Khác…", a title).
  final Future<void> Function() edit;

  /// A wall-clock time "HH:mm", or null when closed.
  final Future<String?> Function(DateTime? initial) pickTime;

  /// A local date, or null when closed; [past]: a day already gone (a measurement), else one
  /// from yesterday on (a reminder).
  final Future<DateTime?> Function(DateTime? initial, {bool past}) pickDate;
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The fix rows of [d] (empty when nothing needs the person). [optional] adds the rows that
/// never block (a sleep note's day / night).
List<AsFixRow> fixRowsFor({
  required AppLocalizations l10n,
  required String locale,
  required AssistantDraft d,
  required String zone,
  required DateTime now,
  required FixActions act,
}) {
  final p = d.payload;
  final rows = <AsFixRow>[];
  String at(DateTime t) => hm(t, zone);
  AsFixChip chip(String label, Future<void> Function() onTap) =>
      (label: label, onTap: onTap, opens: false);
  AsFixChip opener(String label, Future<void> Function() onTap) =>
      (label: label, onTap: onTap, opens: true);
  AsFixChip confirm(String field) =>
      chip(l10n.asFixRight, () => act.patch(p, [field]));
  AsFixChip other() => opener(l10n.asClarifyOwn, act.edit);
  Future<DateTime?> pickBefore(DateTime end, DateTime? initial) async {
    final v = await act.pickTime(initial);
    if (v == null) return null;
    final parts = v.split(':');
    return wallBefore(zone, int.parse(parts[0]), int.parse(parts[1]), end);
  }

  Future<DateTime?> pickAfter(DateTime start, DateTime? initial) async {
    final v = await act.pickTime(initial);
    if (v == null) return null;
    final parts = v.split(':');
    return wallAfter(zone, int.parse(parts[0]), int.parse(parts[1]), start);
  }

  final ago = [
    (l10n.asFixJustNow(at(now)), Duration.zero),
    (
      l10n.asFixAgo30(at(now.subtract(const Duration(minutes: 30)))),
      const Duration(minutes: 30),
    ),
    (
      l10n.asFixAgo60(at(now.subtract(const Duration(hours: 1)))),
      const Duration(hours: 1),
    ),
  ];

  for (final g in reviewGaps(d, now)) {
    final f = g.field;
    final future = g.problem == DraftProblem.futureTime;
    final invalid = g.problem == DraftProblem.invalidTime;
    AsFixRow row(String reason, List<AsFixChip> chips) =>
        (field: f, reason: reason, chips: chips, optional: false);
    switch ((p, f)) {
      // ---- A feed's (a pump's, a diaper's, a meal's) time: "Vừa xong (01:08)" means it ended
      // then (a nursing or pumping length is kept).
      case (BottlePayload(), 'occurredAt') ||
          (BreastPayload(), 'occurredAt') ||
          (PumpPayload(), 'occurredAt') ||
          (DiaperPayload(), 'occurredAt') ||
          (MealPayload(), 'occurredAt'):
        final cur = switch (p) {
          BottlePayload(:final occurredAt) ||
          BreastPayload(:final occurredAt) ||
          PumpPayload(:final occurredAt) ||
          DiaperPayload(:final occurredAt) ||
          MealPayload(:final occurredAt) => occurredAt,
          _ => null,
        };
        final length = switch (p) {
          BreastPayload(:final durationMin) ||
          PumpPayload(:final durationMin) => durationMin,
          _ => null,
        };
        DraftPayload withAt(DateTime t) => switch (p) {
          final BottlePayload b => b.copyWith(occurredAt: t),
          final BreastPayload b => b.copyWith(occurredAt: t),
          final PumpPayload b => b.copyWith(occurredAt: t),
          final DiaperPayload b => b.copyWith(occurredAt: t),
          final MealPayload b => MealPayload(
            title: b.title,
            recipeId: b.recipeId,
            occurredAt: t,
          ),
          _ => p,
        };
        rows.add(
          row(
            cur == null || g.missing
                ? switch (p) {
                    PumpPayload() => l10n.asGapPumpTime,
                    DiaperPayload() => l10n.asGapDiaperTime,
                    MealPayload() => l10n.asProblemMissingTime,
                    _ => l10n.asGapFeedTime,
                  }
                : future
                ? l10n.asGapTimeFuture(at(cur))
                : l10n.asGapTimeUnsure(at(cur)),
            [
              if (cur != null && !g.missing && !future) confirm(f),
              for (final (label, back) in ago)
                chip(
                  label,
                  () => act.patch(
                    withAt(now.subtract(back + Duration(minutes: length ?? 0))),
                    [f],
                  ),
                ),
              opener(l10n.asFixPickTime, () async {
                final t = await pickBefore(now, cur);
                if (t != null) await act.patch(withAt(t), [f]);
              }),
            ],
          ),
        );
      case (final BottlePayload b, 'amountMl'):
        final ml = b.amountMl;
        rows.add(
          row(
            ml == null || g.missing
                ? l10n.asGapAmount
                : g.problem == DraftProblem.invalidAmount
                ? l10n.asGapAmountRange
                : l10n.asGapAmountUnsure(mlLabel(locale, ml)),
            [
              if (ml != null &&
                  !g.missing &&
                  g.problem != DraftProblem.invalidAmount)
                confirm(f),
              for (final v in const [60, 90, 120, 150, 180])
                chip(
                  l10n.asFixMl('$v'),
                  () => act.patch(b.copyWith(amountMl: v), [f]),
                ),
              other(),
            ],
          ),
        );
      case (final BottlePayload b, 'milk'):
        DraftPayload withMilk(String m) => BottlePayload(
          amountMl: b.amountMl,
          occurredAt: b.occurredAt,
          milk: m,
        );
        rows.add(
          row(l10n.asGapMilk, [
            chip(
              l10n.milkBreast,
              () => act.patch(withMilk('breast_milk'), [f]),
            ),
            chip(l10n.milkFormula, () => act.patch(withMilk('formula'), [f])),
          ]),
        );
      case (final BreastPayload b, 'side'):
        rows.add(
          row(l10n.asGapSide, [
            for (final (side, label) in [
              ('left', l10n.sideLeft),
              ('right', l10n.sideRight),
              ('both', l10n.sideBoth),
            ])
              chip(label, () => act.patch(b.copyWith(side: side), [f])),
          ]),
        );
      case (final BreastPayload b, 'durationMin'):
        final m = b.durationMin;
        final tooLong = g.problem == DraftProblem.invalidAmount;
        rows.add(
          row(
            tooLong || m == null
                ? l10n.asGapDurationRange
                : l10n.asGapDurationUnsure(durationLabel(l10n, m)),
            [
              if (m != null && !tooLong) confirm(f),
              for (final v in const [10, 15, 20, 30])
                chip(
                  durationLabel(l10n, v),
                  () => act.patch(b.copyWith(durationMin: v), [f]),
                ),
              other(),
            ],
          ),
        );
      // ---- A sleep: the start from the wake-up ("Ngủ 2 tiếng (từ 23:05)"), or a picked time.
      case (final SleepPayload s, 'startedAt'):
        final end = s.endedAt;
        rows.add(
          row(
            s.startedAt == null || g.missing
                ? l10n.asGapSleepStart
                : l10n.asGapSleepStartUnsure(at(s.startedAt!)),
            [
              if (s.startedAt != null && !g.missing) confirm(f),
              if (end != null)
                for (final h in const [1, 2, 3])
                  chip(
                    l10n.asFixSlept(h, at(end.subtract(Duration(hours: h)))),
                    () => act.patch(
                      SleepPayload(
                        startedAt: end.subtract(Duration(hours: h)),
                        endedAt: end,
                      ),
                      [f],
                    ),
                  ),
              opener(l10n.asFixPickTime, () async {
                final t = await pickBefore(end ?? now, s.startedAt);
                if (t != null) {
                  await act.patch(
                    SleepPayload(startedAt: t, endedAt: s.endedAt),
                    [f],
                  );
                }
              }),
            ],
          ),
        );
      case (final SleepPayload s, 'endedAt'):
        final start = s.startedAt;
        final cur = s.endedAt;
        SleepPayload withEnd(DateTime e) =>
            SleepPayload(startedAt: start, endedAt: e);
        rows.add(
          row(
            cur == null || g.missing
                ? l10n.asGapSleepEnd
                : invalid
                ? l10n.asGapSleepOrder
                : future
                ? l10n.asGapTimeFuture(at(cur))
                : l10n.asGapSleepEndUnsure(at(cur)),
            [
              if (cur != null && !g.missing && !future && !invalid) confirm(f),
              chip(
                l10n.asFixWokeNow(at(now)),
                () => act.patch(withEnd(now), [f]),
              ),
              chip(
                l10n.asFixAgo30(at(now.subtract(const Duration(minutes: 30)))),
                () => act.patch(
                  withEnd(now.subtract(const Duration(minutes: 30))),
                  [f],
                ),
              ),
              opener(l10n.asFixPickTime, () async {
                final t = start == null
                    ? await pickBefore(now, cur)
                    : await pickAfter(start, cur);
                if (t != null) await act.patch(withEnd(t), [f]);
              }),
            ],
          ),
        );
      case (final SleepPayload s, 'durationMin'):
        rows.add(
          row(
            l10n.asGapDurationUnsure(
              durationLabel(l10n, s.minutes ?? s.durationMin ?? 0),
            ),
            [confirm(f), opener(l10n.asEdit, act.edit)],
          ),
        );
      // ---- A note's day, a reminder's date.
      case (final ObservationPayload o, 'date'):
        final wall = inBabyZone(zone, now);
        final today = DateTime(wall.year, wall.month, wall.day);
        DraftPayload withDate(DateTime day) => ObservationPayload(
          observation: o.observation,
          date: _isoDate(day),
          when: o.when,
          note: o.note,
        );
        rows.add(
          row(
            l10n.asGapDateUnsure(
              DateTime.tryParse(o.date) == null
                  ? o.date
                  : shortDate(locale, DateTime.parse(o.date)),
            ),
            [
              chip(l10n.asFixToday, () => act.patch(withDate(today), [f])),
              chip(
                l10n.asFixYesterday,
                () => act.patch(
                  withDate(today.subtract(const Duration(days: 1))),
                  [f],
                ),
              ),
            ],
          ),
        );
      case (final ObservationPayload o, 'when'):
        DraftPayload withWhen(String w) => ObservationPayload(
          observation: o.observation,
          date: o.date,
          when: w,
          note: o.note,
        );
        rows.add(
          row(l10n.asGapWhenAsk, [
            if (o.when != null) confirm(f),
            for (final (w, label) in [
              ('day', l10n.asFixDayTime),
              ('night', l10n.asFixNightTime),
              ('both', l10n.sideBoth),
            ])
              chip(label, () => act.patch(withWhen(w), [f])),
          ]),
        );
      case (final ObservationPayload o, 'note'):
        rows.add(
          row(l10n.asGapNote, [
            confirm(f),
            chip(
              l10n.asFixDropNote,
              () => act.patch(
                ObservationPayload(
                  observation: o.observation,
                  date: o.date,
                  when: o.when,
                ),
                [f],
              ),
            ),
          ]),
        );
      case (ObservationPayload(), 'observation'):
        rows.add(row(l10n.asGapObservation, [confirm(f)]));
      case (final ReminderPayload r, 'date'):
        final wall = inBabyZone(zone, now);
        final today = DateTime(wall.year, wall.month, wall.day);
        DraftPayload withDate(DateTime day) => ReminderPayload(
          title: r.title,
          date: _isoDate(day),
          time: r.time,
          assigneeUid: r.assigneeUid,
        );
        rows.add(
          row(
            r.date == null || g.missing
                ? l10n.asGapReminderDate
                : g.problem == DraftProblem.pastTime ||
                      g.problem == DraftProblem.invalidTime
                ? l10n.asGapReminderPast
                : l10n.asGapDateUnsure(weekdayDate(locale, r.date!)),
            [
              if (r.date != null && !g.missing && g.problem == null) confirm(f),
              // Today only while its time is still ahead (a reminder is for later).
              if (r.time == null ||
                  fromBabyWall(
                    zone,
                    DateTime(
                      today.year,
                      today.month,
                      today.day,
                      int.parse(r.time!.substring(0, 2)),
                      int.parse(r.time!.substring(3, 5)),
                    ),
                  ).isAfter(now))
                chip(l10n.asFixToday, () => act.patch(withDate(today), [f])),
              chip(
                l10n.asFixTomorrow,
                () => act.patch(withDate(today.add(const Duration(days: 1))), [
                  f,
                ]),
              ),
              opener(l10n.asFixPickDate, () async {
                final day = await act.pickDate(
                  r.date == null ? null : DateTime.tryParse(r.date!),
                );
                if (day != null) await act.patch(withDate(day), [f]);
              }),
            ],
          ),
        );
      case (final ReminderPayload r, 'assigneeUid'):
        rows.add(
          row(problemLabel(l10n, DraftProblem.invalidAssignee), [
            chip(
              l10n.asFixNoAssignee,
              () => act.patch(
                ReminderPayload(title: r.title, date: r.date, time: r.time),
                [f],
              ),
            ),
          ]),
        );
      case (ReminderPayload(), 'title'):
        rows.add(row(l10n.asGapTitle, [opener(l10n.asEdit, act.edit)]));
      // LUMI-11: a reminder time already gone: today → a later time (or the same time
      // tomorrow); an earlier day → the same time tomorrow or another day.
      case (final ReminderPayload r, 'time')
          when g.problem == DraftProblem.pastTime && r.time != null:
        final wall = inBabyZone(zone, now);
        final today = DateTime(wall.year, wall.month, wall.day);
        final tomorrow = today.add(const Duration(days: 1));
        final onToday = r.date == null || r.date == _isoDate(today);
        DraftPayload withWhen(String? date, String time) => ReminderPayload(
          title: r.title,
          date: date,
          time: time,
          assigneeUid: r.assigneeUid,
        );
        final again = chip(
          l10n.asFixTomorrowAt(r.time!),
          () => act.patch(withWhen(_isoDate(tomorrow), r.time!), [f, 'date']),
        );
        rows.add(
          onToday
              ? row(problemLabel(l10n, DraftProblem.pastTime), [
                  opener(l10n.asFixPickTime, () async {
                    final v = await act.pickTime(null);
                    if (v != null) {
                      await act.patch(withWhen(_isoDate(today), v), [f]);
                    }
                  }),
                  again,
                ])
              : row(l10n.asGapReminderPast, [
                  again,
                  opener(l10n.asFixPickDate, () async {
                    final day = await act.pickDate(tomorrow);
                    if (day != null) {
                      await act.patch(withWhen(_isoDate(day), r.time!), [
                        f,
                        'date',
                      ]);
                    }
                  }),
                ]),
        );
      // A reminder the server still wants a time for (photo notes before D-075 #5).
      case (ReminderPayload(), 'time'):
        rows.add(
          row(problemLabel(l10n, DraftProblem.missingTime), [
            opener(l10n.asCheckReminder, act.edit),
          ]),
        );
      // ---- A timer's time: now, or a picked time.
      case (final TimerPayload t, 'at'):
        rows.add(
          row(
            invalid && !t.isStart && t.startedAt != null
                ? l10n.asGapTimerEnd(at(t.startedAt!))
                : invalid
                ? l10n.asGapTimerOld
                : future && t.at != null
                ? l10n.asGapTimeFuture(at(t.at!))
                : l10n.asProblemMissingTime,
            [
              chip(
                l10n.asFixJustNow(at(now)),
                () => act.patch(t.copyWith(at: now), [f]),
              ),
              opener(l10n.asFixPickTime, () async {
                final v = t.isStart || t.startedAt == null
                    ? await pickBefore(now, t.at)
                    : await pickAfter(t.startedAt!, t.at);
                if (v != null) await act.patch(t.copyWith(at: v), [f]);
              }),
            ],
          ),
        );
      // LUMI-07: a nursing timer's first side (one side at a time).
      case (final TimerPayload t, 'side') when !t.isSleep && t.isStart:
        rows.add(
          row(l10n.asGapSide, [
            if (t.side != null && !g.missing) confirm(f),
            for (final (side, label) in [
              ('left', l10n.sideLeft),
              ('right', l10n.sideRight),
            ])
              chip(label, () => act.patch(t.copyWith(side: side), [f])),
          ]),
        );
      // ---- LUMI-01: a pump, a diaper, a measurement (the care forms' fields) ----
      case (final PumpPayload x, 'amountMl'):
        final ml = x.amountMl;
        final bad = g.problem == DraftProblem.invalidAmount;
        rows.add(
          row(
            ml == null || g.missing
                ? l10n.asGapPumpAmount
                : bad
                ? l10n.asGapPumpAmountRange
                : l10n.asGapAmountUnsure(mlLabel(locale, ml)),
            [
              if (ml != null && !g.missing && !bad) confirm(f),
              for (final v in const [60, 90, 120, 150, 200])
                chip(
                  l10n.asFixMl('$v'),
                  () => act.patch(x.copyWith(amountMl: v), [f]),
                ),
              other(),
            ],
          ),
        );
      case (final PumpPayload x, 'side'):
        rows.add(
          row(l10n.asGapPumpSide, [
            if (x.side != null && !g.missing) confirm(f),
            for (final (side, label) in [
              ('left', l10n.sideLeft),
              ('right', l10n.sideRight),
              ('both', l10n.sideBoth),
            ])
              chip(label, () => act.patch(x.copyWith(side: side), [f])),
          ]),
        );
      case (final PumpPayload x, 'durationMin'):
        final m = x.durationMin;
        final tooLong = g.problem == DraftProblem.invalidAmount;
        rows.add(
          row(
            tooLong
                ? l10n.asGapPumpDurationRange
                : m == null || g.missing
                ? l10n.asGapPumpDuration
                : l10n.asGapDurationUnsure(durationLabel(l10n, m)),
            [
              if (m != null && !tooLong && !g.missing) confirm(f),
              for (final v in const [10, 15, 20, 30])
                chip(
                  durationLabel(l10n, v),
                  () => act.patch(x.copyWith(durationMin: v), [f]),
                ),
              other(),
            ],
          ),
        );
      case (final DiaperPayload x, 'diaper'):
        rows.add(
          row(l10n.asGapDiaper, [
            if (x.diaper != null && !g.missing) confirm(f),
            for (final k in diaperKinds)
              chip(
                diaperWord(l10n, k)!,
                () => act.patch(x.copyWith(diaper: k), [f]),
              ),
          ]),
        );
      case (final GrowthPayload x, 'weightKg'):
        final kg = x.weightKg;
        final bad = g.problem == DraftProblem.invalidAmount;
        rows.add(
          row(
            kg == null || g.missing
                ? l10n.asGapWeight
                : bad
                ? l10n.growthWeightRequired
                : l10n.asGapWeightUnsure(decimal(locale, kg.toDouble())),
            [
              if (kg != null && !g.missing && !bad) confirm(f),
              opener(l10n.asFixEnterWeight, act.edit),
            ],
          ),
        );
      case (final GrowthPayload x, 'lengthCm'):
        final cm = x.lengthCm;
        final bad = g.problem == DraftProblem.invalidAmount;
        rows.add(
          row(
            cm == null || g.missing
                ? l10n.asGapLength
                : bad
                ? l10n.growthLengthRange
                : l10n.asGapLengthUnsure(decimal(locale, cm.toDouble())),
            [
              if (cm != null && !g.missing && !bad) confirm(f),
              opener(l10n.asFixEnterLength, act.edit),
              // The length is optional: keep the weight without it.
              if (cm != null)
                chip(
                  l10n.asFixDropLength,
                  () => act.patch(x.withoutLength(), [f]),
                ),
            ],
          ),
        );
      case (final GrowthPayload x, 'measuredOn'):
        final wall = inBabyZone(zone, now);
        final today = DateTime(wall.year, wall.month, wall.day);
        final cur = x.measuredOn == null
            ? null
            : DateTime.tryParse(x.measuredOn!);
        rows.add(
          row(
            cur == null || g.missing
                ? l10n.asGapMeasuredOn
                : future
                ? l10n.asGapMeasuredOnFuture
                : l10n.asGapMeasuredOnUnsure(shortDate(locale, cur)),
            [
              if (cur != null && !g.missing && !future) confirm(f),
              chip(
                l10n.asFixToday,
                () => act.patch(x.copyWith(measuredOn: _isoDate(today)), [f]),
              ),
              chip(
                l10n.asFixYesterday,
                () => act.patch(
                  x.copyWith(
                    measuredOn: _isoDate(
                      today.subtract(const Duration(days: 1)),
                    ),
                  ),
                  [f],
                ),
              ),
              opener(l10n.asFixPickDate, () async {
                final day = await act.pickDate(
                  cur == null || cur.isAfter(today) ? today : cur,
                  past: true,
                );
                if (day != null) {
                  await act.patch(x.copyWith(measuredOn: _isoDate(day)), [f]);
                }
              }),
            ],
          ),
        );
      // Last resort: a field no row knows (an older or newer draft) — the editor.
      default:
        rows.add(row(l10n.asNeedsReview, [opener(l10n.asEdit, act.edit)]));
    }
  }

  // Optional, never blocking: a sleep note's day or night ("Ban ngày / Ban đêm / Cả hai").
  if (p case ObservationPayload(
    observation: 'sleep',
    when: null,
  ) when !rows.any((r) => r.field == 'when')) {
    rows.add((
      field: 'when',
      reason: l10n.asGapWhen,
      chips: [
        for (final (w, label) in [
          ('day', l10n.asFixDayTime),
          ('night', l10n.asFixNightTime),
          ('both', l10n.sideBoth),
        ])
          chip(
            label,
            () => act.patch(
              ObservationPayload(
                observation: p.observation,
                date: p.date,
                when: w,
                note: p.note,
              ),
              ['when'],
            ),
          ),
      ],
      optional: true,
    ));
  }
  return rows;
}
