import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show timerClockProvider;
import '../home/home_shell.dart';
import '../premium/premium_repository.dart';
import '../reminders/reminder_notifications.dart'
    show LocalReminder, loadSettled;
import 'rhythm_access.dart';
import 'rhythm_repository.dart';
import 'rhythm_calc.dart';
import 'rhythm_models.dart';

/// What Nhịp lớn lên keeps on this phone only, per person: the NL02c reminder switches (the
/// stage reminder and the evening check-in prompt are local notifications, and
/// `userPreferencesSchema` has no field for them; quiet hours live in the person's preferences)
/// and whether the setup (NL02a–c) was already shown for a baby.

/// NL02c switches: the stage reminder on, the evening prompt off (Figma `570:1183`), the
/// weekly summary on (EN07 560:2981 "Tóm tắt tuần · Chủ nhật 20:30" is drawn on).
@immutable
class RhythmReminders {
  const RhythmReminders({
    this.stage = true,
    this.evening = false,
    this.weekly = true,
  });
  final bool stage;
  final bool evening;
  final bool weekly;

  RhythmReminders copyWith({bool? stage, bool? evening, bool? weekly}) =>
      RhythmReminders(
        stage: stage ?? this.stage,
        evening: evening ?? this.evening,
        weekly: weekly ?? this.weekly,
      );

  static RhythmReminders fromJson(Object? json) {
    if (json is! Map) return const RhythmReminders();
    return RhythmReminders(
      stage: json['stage'] != false,
      evening: json['evening'] == true,
      weekly: json['weekly'] != false,
    );
  }

  Map<String, Object?> toJson() => {
    'stage': stage,
    'evening': evening,
    'weekly': weekly,
  };

  @override
  bool operator ==(Object other) =>
      other is RhythmReminders &&
      other.stage == stage &&
      other.evening == evening &&
      other.weekly == weekly;

  @override
  int get hashCode => Object.hash(stage, evening, weekly);
}

/// The reminder switches of one person ([uid]) on this phone.
final rhythmRemindersProvider =
    NotifierProvider.family<RhythmRemindersNotifier, RhythmReminders, String>(
      RhythmRemindersNotifier.new,
    );

class RhythmRemindersNotifier extends Notifier<RhythmReminders> {
  RhythmRemindersNotifier(this.uid);
  final String uid;

  String get _key => 'rhythm.reminders.$uid';

  @override
  RhythmReminders build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      return raw == null
          ? const RhythmReminders()
          : RhythmReminders.fromJson(jsonDecode(raw));
    } on Object {
      return const RhythmReminders();
    }
  }

  void set(RhythmReminders value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(value.toJson()))
        .ignore();
  }
}

bool _flag(WidgetRef ref, String key) {
  try {
    return ref.read(sharedPreferencesProvider).getBool(key) ?? false;
  } on Object {
    return true;
  }
}

void _setFlag(WidgetRef ref, String key) {
  try {
    ref.read(sharedPreferencesProvider).setBool(key, true).ignore();
  } on Object {
    // Best effort: at worst the question comes once more.
  }
}

/// Whether NL02a–c already ran (finished or closed) for [babyId] on this phone.
bool rhythmSetupSeen(WidgetRef ref, String uid, String babyId) =>
    _flag(ref, 'rhythm.setupSeen.$uid.$babyId');

void markRhythmSetupSeen(WidgetRef ref, String uid, String babyId) =>
    _setFlag(ref, 'rhythm.setupSeen.$uid.$babyId');

/// Whether the owner was already asked the region on NL01's first open (D-072 #3); NL01 keeps
/// an inline "Chọn khu vực" until it is chosen, without asking again.
bool rhythmRegionAsked(WidgetRef ref, String uid, String babyId) =>
    _flag(ref, 'rhythm.regionAsked.$uid.$babyId');

void markRhythmRegionAsked(WidgetRef ref, String uid, String babyId) =>
    _setFlag(ref, 'rhythm.regionAsked.$uid.$babyId');

/// Hour of the stage reminder (local time on the phone).
const stageReminderHour = 9;

/// NL02c "Trước giai đoạn tham khảo": one reminder per stage, 3 days before its window, at
/// [stageReminderHour], only for stages still ahead. Pure, so it is tested without a phone.
///
/// TODO(rhythm): schedule these. The app's local notifications are one desired list synced by
/// `lib/features/reminders/reminder_notifications.dart` (anything not in it is cancelled), so
/// the stage reminders must join that list there, next to the keepsake nudges; that file is
/// outside Nhịp lớn lên. Until then the switch is stored and nothing is scheduled.
List<({ReferenceStage stage, DateTime fireAt})> stageReminderPlan({
  required String? dueDate,
  required List<ReferenceStage> stages,
  required DateTime now,
  required bool enabled,
}) {
  if (!enabled || dueDate == null) return const [];
  return [
    for (final s in [
      ...stages,
    ]..sort((a, b) => a.startOffsetDays.compareTo(b.startOffsetDays)))
      if (DateTime.parse(addDaysIso(windowOf(dueDate, s).start, -3))
          case final day
          when DateTime(
            day.year,
            day.month,
            day.day,
            stageReminderHour,
          ).isAfter(now))
        (
          stage: s,
          fireAt: DateTime(day.year, day.month, day.day, stageReminderHour),
        ),
  ];
}

/// Whether everything the Nhịp lớn lên plans below read has answered (the selected baby only),
/// so the reminder sync does not take "still loading" for "nothing to schedule".
final rhythmPlansReadyProvider = Provider.autoDispose<bool>((ref) {
  try {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return true;
    final caps = ref.watch(capabilitiesProvider(me.babyId));
    if (!loadSettled(caps)) return false;
    if (!(caps.value?.features.rhythm ?? false)) return true;
    final reminders = ref.watch(rhythmRemindersProvider(me.uid));
    final reads = <AsyncValue<Object?>>[
      if (me.canViewBabyInfo && (reminders.stage || reminders.weekly))
        ref.watch(rhythmProfileProvider(me.babyId)),
      if (me.canViewBabyInfo && reminders.stage)
        ref.watch(rhythmReferenceProvider),
      if (reminders.evening || reminders.weekly)
        ref.watch(userPreferencesProvider(me.uid)),
      if (reminders.evening) ...[
        ref.watch(checkInsProvider(me.babyId)),
        ref.watch(babyProvider(me.babyId)),
      ],
    ];
    return reads.every(loadSettled);
  } on Object {
    // Best effort, like the plans: a problem here never holds the other reminders back.
    return true;
  }
});

/// NL02c "Trước giai đoạn tham khảo · 3 ngày trước": the selected baby's stage reminders this
/// phone should schedule, for the reminder sync (it cancels anything it is not given). Only for a
/// member who may read the due date, with the rhythm rollout on and the switch on; stages without
/// a published notice are skipped. Best effort: a problem here never stops other reminders.
final rhythmStageReminderPlanProvider =
    Provider.autoDispose<
      List<({String babyId, ReferenceStage stage, DateTime fireAt})>
    >((ref) {
      try {
        final me = ref.watch(selectedMembershipProvider);
        final caps = ref.watch(selectedCapabilitiesProvider);
        if (me == null ||
            caps == null ||
            !caps.features.rhythm ||
            !me.canViewBabyInfo) {
          return const [];
        }
        final due = ref.watch(rhythmProfileProvider(me.babyId)).value?.dueDate;
        final model = ref.watch(rhythmReferenceProvider).value;
        if (due == null || model == null) return const [];
        final plan = stageReminderPlan(
          dueDate: due.date,
          stages: model.stages,
          now: ref.read(timerClockProvider)(),
          enabled: ref.watch(rhythmRemindersProvider(me.uid)).stage,
        );
        return [
          for (final p in plan)
            if (p.stage.noticeTitle != null && p.stage.noticeBody != null)
              (babyId: me.babyId, stage: p.stage, fireAt: p.fireAt),
        ];
      } on Object {
        return const [];
      }
    });

/// One stage reminder as a local notification; no baby name in the text (R-120). Ids apart
/// from reminders (28 bits) and keepsake nudges (bit 30): bit 29 set.
LocalReminder rhythmStageNotification(
  Locale locale,
  ({String babyId, ReferenceStage stage, DateTime fireAt}) p,
) {
  final title = p.stage.noticeTitle!.of(locale);
  final body = p.stage.noticeBody!.of(locale);
  final hash = '${p.babyId}/${p.stage.id}'.codeUnits.fold<int>(
    17,
    (h, c) => (h * 31 + c) & 0x0fffffff,
  );
  return LocalReminder(
    id: (1 << 29) | hash,
    fireAt: p.fireAt,
    title: title,
    body: body,
    payload: jsonEncode({
      'k': 'rhythm',
      'b': p.babyId,
      's': p.stage.id,
      'at': p.fireAt.millisecondsSinceEpoch,
      't': title,
      'x': body,
    }),
  );
}

/// The baby id of a stage-reminder payload, or null for anything else.
String? rhythmOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is Map && json['k'] == 'rhythm' && json['b'] is String) {
      return json['b'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}

// ---------- Evening check-in prompt (NL02c "Check-in buổi tối") ----------

/// "20:30 · bỏ qua nếu đã ghi trong ngày" (Figma 570:1183), local time on the phone.
const eveningCheckInHour = 20;
const eveningCheckInMinute = 30;

/// How many evenings ahead are scheduled; each sync (a check-in, a switch, a restart) renews them,
/// so a phone left unopened stops asking after a few days.
const eveningPromptDays = 3;

/// The earliest an evening prompt may move to when 20:30 falls in the person's quiet hours.
const _eveningEarliestMinutes = 18 * 60;

int _minutes(String hhmm) =>
    int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

/// [at] (20:30) when it is outside the quiet hours [from]–[to] (either may wrap past midnight);
/// else 30 minutes before they start, if that is still the evening (18:00 or later); else null.
DateTime? eveningTimeOutsideQuiet(DateTime at, String? from, String? to) {
  if (from == null || to == null) return at;
  final f = _minutes(from), t = _minutes(to), m = at.hour * 60 + at.minute;
  final inside = f == t
      ? false
      : f < t
      ? (m >= f && m < t)
      : (m >= f || m < t);
  if (!inside) return at;
  final earlier = f - 30;
  if (earlier >= _eveningEarliestMinutes && earlier < m) {
    return DateTime(at.year, at.month, at.day, earlier ~/ 60, earlier % 60);
  }
  return null;
}

/// NL02c evening prompt: the next [days] evenings at 20:30 (moved before the person's quiet
/// hours, or dropped when no evening time is left), today skipped once this person already noted
/// something for the baby, nothing in the past. Pure, so it is tested without a phone.
List<DateTime> eveningCheckInPlan({
  required bool enabled,
  required DateTime now,
  required bool checkedInToday,
  String? quietFrom,
  String? quietTo,
  int days = eveningPromptDays,
}) {
  if (!enabled) return const [];
  return [
    for (var i = 0; i < days; i++)
      if (!(i == 0 && checkedInToday))
        if (eveningTimeOutsideQuiet(
              DateTime(
                now.year,
                now.month,
                now.day + i,
                eveningCheckInHour,
                eveningCheckInMinute,
              ),
              quietFrom,
              quietTo,
            )
            case final at? when at.isAfter(now))
          at,
  ];
}

/// The evening prompts this phone should schedule for the selected baby: only for a person who
/// may check in, with the rhythm rollout and their own switch on. Best effort, like the stage
/// reminders: a problem here never stops other reminders.
final rhythmEveningPlanProvider =
    Provider.autoDispose<List<({String babyId, DateTime fireAt})>>((ref) {
      try {
        final me = ref.watch(selectedMembershipProvider);
        final caps = ref.watch(selectedCapabilitiesProvider);
        if (me == null ||
            caps == null ||
            !caps.features.rhythm ||
            !familyCan(me, FamilyAction.rhythmCheckin)) {
          return const [];
        }
        if (!ref.watch(rhythmRemindersProvider(me.uid)).evening) {
          return const [];
        }
        final prefs =
            ref.watch(userPreferencesProvider(me.uid)).value ??
            UserPreferences.defaults;
        final checkIns = ref.watch(checkInsProvider(me.babyId)).value;
        final zone =
            ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
            'Asia/Ho_Chi_Minh';
        final now = ref.read(timerClockProvider)();
        final today = babyTodayIso(zone, now);
        final mine =
            checkIns?.any((c) => c.authorUid == me.uid && c.date == today) ??
            false;
        // NL02c "tối đa 1 thông báo Nhịp lớn lên mỗi ngày": on a Sunday with the weekly summary,
        // the summary takes the evening.
        final weekly = {
          for (final w in ref.watch(rhythmWeeklyPlanProvider))
            DateTime(w.fireAt.year, w.fireAt.month, w.fireAt.day),
        };
        return [
          for (final at in eveningCheckInPlan(
            enabled: true,
            now: now,
            checkedInToday: mine,
            quietFrom: prefs.quietFrom,
            quietTo: prefs.quietTo,
          ))
            if (!weekly.contains(DateTime(at.year, at.month, at.day)))
              (babyId: me.babyId, fireAt: at),
        ];
      } on Object {
        return const [];
      }
    });

/// One evening prompt as a local notification; no baby name (R-120). Ids: bit 29 (Nhịp lớn lên)
/// and bit 28 (apart from the stage reminders, whose hash stays under bit 28).
LocalReminder rhythmEveningNotification(
  AppLocalizations l10n,
  ({String babyId, DateTime fireAt}) p,
) {
  final title = l10n.rhCheckInEntry;
  final body = l10n.rhEveningBody;
  final day = '${p.fireAt.year}-${p.fireAt.month}-${p.fireAt.day}';
  final hash = '${p.babyId}/evening/$day'.codeUnits.fold<int>(
    17,
    (h, c) => (h * 31 + c) & 0x0fffffff,
  );
  return LocalReminder(
    id: (1 << 29) | (1 << 28) | hash,
    fireAt: p.fireAt,
    title: title,
    body: body,
    payload: jsonEncode({
      'k': 'rhythm_checkin',
      'b': p.babyId,
      'at': p.fireAt.millisecondsSinceEpoch,
      't': title,
      'x': body,
    }),
  );
}

/// The baby id of an evening-prompt payload, or null for anything else.
String? rhythmCheckInOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is Map && json['k'] == 'rhythm_checkin' && json['b'] is String) {
      return json['b'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}

// ---------- Weekly summary (EN07 "Tóm tắt tuần · Chủ nhật 20:30" → EN09) ----------

/// Sunday 20:30, local time on the phone (EN07).
const weeklySummaryHour = 20;
const weeklySummaryMinute = 30;

/// How many Sundays ahead are scheduled; each sync renews them.
const weeklySummaryWeeks = 2;

/// The next [weeks] Sundays at 20:30 (moved before the person's quiet hours like the evening
/// prompt, or dropped when no evening time is left), none before [earliest] (the first Sunday
/// that closes a whole week of the baby's life) and nothing in the past. Pure, so it is tested
/// without a phone.
List<DateTime> weeklySummaryPlan({
  required bool enabled,
  required DateTime now,
  String? quietFrom,
  String? quietTo,
  DateTime? earliest,
  int weeks = weeklySummaryWeeks,
}) {
  if (!enabled) return const [];
  final toSunday = (DateTime.sunday - now.weekday) % 7;
  final out = <DateTime>[];
  // One more Sunday than asked, in case this Sunday's 20:30 has passed.
  for (var i = 0; i <= weeks && out.length < weeks; i++) {
    final day = DateTime(now.year, now.month, now.day + toSunday + 7 * i);
    if (earliest != null &&
        day.isBefore(DateTime(earliest.year, earliest.month, earliest.day))) {
      continue;
    }
    final at = eveningTimeOutsideQuiet(
      DateTime(
        day.year,
        day.month,
        day.day,
        weeklySummaryHour,
        weeklySummaryMinute,
      ),
      quietFrom,
      quietTo,
    );
    if (at != null && at.isAfter(now)) out.add(at);
  }
  return out;
}

/// The first Sunday whose Monday–Sunday the baby lived whole (born by that Monday).
DateTime firstWeeklySummaryDay(DateTime dateOfBirth) {
  // Day 7 of life, then the Sunday on or after it.
  final seventh = DateTime.parse(addDaysIso(isoOf(dateOfBirth), 6));
  return DateTime.parse(
    addDaysIso(isoOf(seventh), (DateTime.sunday - seventh.weekday) % 7),
  );
}

/// The weekly summaries this phone should schedule for the selected baby: only for a person who
/// may read the week (`history.read`), with the rhythm rollout and their own switch on, and once
/// a whole week of life has passed (date of birth, when they may read it). Best effort, like the
/// other Nhịp lớn lên reminders.
final rhythmWeeklyPlanProvider =
    Provider.autoDispose<List<({String babyId, DateTime fireAt})>>((ref) {
      try {
        final me = ref.watch(selectedMembershipProvider);
        final caps = ref.watch(selectedCapabilitiesProvider);
        if (me == null ||
            caps == null ||
            !caps.features.rhythm ||
            !familyCan(me, FamilyAction.historyRead)) {
          return const [];
        }
        if (!ref.watch(rhythmRemindersProvider(me.uid)).weekly) {
          return const [];
        }
        final prefs =
            ref.watch(userPreferencesProvider(me.uid)).value ??
            UserPreferences.defaults;
        final dob = me.canViewBabyInfo
            ? ref.watch(rhythmProfileProvider(me.babyId)).value?.dateOfBirth
            : null;
        return [
          for (final at in weeklySummaryPlan(
            enabled: true,
            now: ref.read(timerClockProvider)(),
            quietFrom: prefs.quietFrom,
            quietTo: prefs.quietTo,
            // The Sunday ending the first Monday–Sunday the baby lived whole.
            earliest: dob == null ? null : firstWeeklySummaryDay(dob),
          ))
            (babyId: me.babyId, fireAt: at),
        ];
      } on Object {
        return const [];
      }
    });

/// One weekly summary as a local notification: no baby name and no figures (R-120). Ids: bits 30
/// and 29 together (keepsake nudges use bit 30 alone, the other rhythm reminders bit 29 alone).
LocalReminder rhythmWeeklyNotification(
  AppLocalizations l10n,
  ({String babyId, DateTime fireAt}) p,
) {
  final title = l10n.rhWeekNotifTitle;
  final body = l10n.rhWeekNotifBody;
  final day = '${p.fireAt.year}-${p.fireAt.month}-${p.fireAt.day}';
  final hash = '${p.babyId}/week/$day'.codeUnits.fold<int>(
    17,
    (h, c) => (h * 31 + c) & 0x0fffffff,
  );
  return LocalReminder(
    id: (1 << 30) | (1 << 29) | hash,
    fireAt: p.fireAt,
    title: title,
    body: body,
    payload: jsonEncode({
      'k': 'rhythm_week',
      'b': p.babyId,
      'at': p.fireAt.millisecondsSinceEpoch,
      't': title,
      'x': body,
    }),
  );
}

/// The baby id of a weekly-summary payload, or null for anything else.
String? rhythmWeekOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is Map && json['k'] == 'rhythm_week' && json['b'] is String) {
      return json['b'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}
