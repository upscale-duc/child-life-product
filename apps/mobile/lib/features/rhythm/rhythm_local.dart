import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import 'rhythm_calc.dart';
import 'rhythm_models.dart';

/// What Nhịp lớn lên keeps on this phone only, per person: the NL02c reminder switches (the
/// stage reminder and the evening check-in prompt are local notifications, and
/// `userPreferencesSchema` has no field for them; quiet hours live in the person's preferences)
/// and whether the setup (NL02a–c) was already shown for a baby.

/// NL02c switches: the stage reminder on, the evening prompt off (Figma `570:1183`).
@immutable
class RhythmReminders {
  const RhythmReminders({this.stage = true, this.evening = false});
  final bool stage;
  final bool evening;

  RhythmReminders copyWith({bool? stage, bool? evening}) => RhythmReminders(
    stage: stage ?? this.stage,
    evening: evening ?? this.evening,
  );

  static RhythmReminders fromJson(Object? json) {
    if (json is! Map) return const RhythmReminders();
    return RhythmReminders(
      stage: json['stage'] != false,
      evening: json['evening'] == true,
    );
  }

  Map<String, Object?> toJson() => {'stage': stage, 'evening': evening};

  @override
  bool operator ==(Object other) =>
      other is RhythmReminders &&
      other.stage == stage &&
      other.evening == evening;

  @override
  int get hashCode => Object.hash(stage, evening);
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
