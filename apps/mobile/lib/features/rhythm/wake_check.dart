import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart'
    show appearanceSettingsProvider, sharedPreferencesProvider;
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart';
import '../care/timer_models.dart';
import '../baby/baby_models.dart' show MemberRole;
import '../reminders/reminder_notifications.dart'
    show LocalReminder, NotificationButtons;
import 'coming_up.dart';
import 'rhythm_repository.dart' show userPreferencesProvider;

/// L6 "Bé dậy chưa?" (lumi-plan §7.1, owner 2026-10-30): one local notification to the person
/// who started a sleep timer that is still running, at a time taken from this baby's own sleeps.
/// It exists to close the sleep with the right time, never to judge how long the baby sleeps.
/// Device-only: nothing goes through the server, no child data leaves the phone.

/// "Hỏi khi đếm giấc ngủ còn chạy" (EN07), on by default, per account on this phone.
class WakeCheckSwitch extends Notifier<bool> {
  WakeCheckSwitch(this.uid);
  final String uid;

  String get _key => 'wakeCheck.$uid';

  @override
  bool build() {
    try {
      return ref.read(sharedPreferencesProvider).getBool(_key) ?? true;
    } on Object {
      return true;
    }
  }

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
  }
}

final wakeCheckSwitchProvider =
    NotifierProvider.family<WakeCheckSwitch, bool, String>(WakeCheckSwitch.new);

typedef WakeCheckPlan = ({
  String babyId,
  String sessionId,
  DateTime start,
  DateTime fireAt,

  /// The ask after "Vẫn ngủ": no third one, so it offers only "Dậy rồi" and "Dậy lúc…".
  bool second,

  /// For the first ask: how long "Vẫn ngủ" waits, and the latest time it may ask again.
  int againMinutes,
  DateTime? until,

  /// No sound or vibration: Night care at [fireAt].
  bool silent,

  /// Says where the switch is: the first ask this phone shows.
  bool hint,
});

/// "No sound or vibration in Night care" (§7.1), for the time it rings: the "Tối" theme or the
/// Night care schedule. Not "Tự động" (the system's look at that hour is unknown) nor the running
/// timer that turns Night care on in the app: a sleep timer always runs here.
bool wakeCheckSilent(AppearanceSettings s, DateTime at) =>
    s.theme == ThemePreference.dark ||
    (s.nightCareScheduleEnabled &&
        isWithinDailyWindow(s.scheduleStart, s.scheduleEnd, at.toLocal()));

const _hintKey = 'wakeCheck.hinted';

/// Whether the next first ask still says where to turn it off: none was shown yet (the one
/// remembered by [wakeCheckRememberHint] rings later, or was cancelled before it rang).
bool wakeCheckHint(SharedPreferences prefs, DateTime now) {
  final shown = prefs.getInt(_hintKey);
  return shown == null || shown > now.millisecondsSinceEpoch;
}

/// After a sync: remembers when the ask with the hint rings, or forgets one that was cancelled
/// before it rang, so the hint is shown once.
Future<void> wakeCheckRememberHint(
  SharedPreferences prefs,
  Iterable<LocalReminder> scheduled,
  DateTime now,
) async {
  final hinted = [
    for (final d in scheduled)
      if (_decode(d.payload)?['h'] == 1) d.fireAt.millisecondsSinceEpoch,
  ]..sort();
  final shown = prefs.getInt(_hintKey);
  if (hinted.isNotEmpty) {
    if (shown != hinted.first) await prefs.setInt(_hintKey, hinted.first);
  } else if (shown != null && shown > now.millisecondsSinceEpoch) {
    await prefs.remove(_hintKey);
  }
}

/// The notification buttons (iOS categories in RuleNotifications.swift, same ids).
const wakeCheckUp = 'WC_UP';
const wakeCheckPick = 'WC_AT';
const wakeCheckAgain = 'WC_AGAIN';

String _againKey(String sessionId) => 'wakeCheck.again.$sessionId';

/// When "Vẫn ngủ" asks again, by timer session: written by the background handler (the app may
/// not be open), so the app reloads the preferences before it syncs.
final wakeCheckAgainProvider = Provider<Map<String, DateTime>>((ref) {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    return {
      for (final k in prefs.getKeys())
        if (k.startsWith('wakeCheck.again.'))
          if (prefs.get(k) case final int ms)
            k.substring('wakeCheck.again.'.length):
                DateTime.fromMillisecondsSinceEpoch(ms),
    };
  } on Object {
    return const {};
  }
});

/// "Vẫn ngủ": when to ask again for the first ask's [payload], or null when it would fall in
/// the night window, the quiet hours or past the timer's limit (then there is no second ask).
/// Kept in [prefs] for the app's plan; other sessions' entries are dropped.
Future<DateTime?> wakeCheckSnooze(
  SharedPreferences prefs,
  String? payload,
  DateTime now,
) async {
  final json = _decode(payload);
  if (json == null || json['n'] == 2) return null;
  final s = json['s'], g = json['g'], u = json['u'];
  if (s is! String || g is! int || u is! int) return null;
  final again = now.add(Duration(minutes: g));
  if (again.millisecondsSinceEpoch > u) return null;
  for (final k in prefs.getKeys().toList()) {
    if (k.startsWith('wakeCheck.again.')) await prefs.remove(k);
  }
  await prefs.setInt(_againKey(s), again.millisecondsSinceEpoch);
  return again;
}

/// The second ask for the first ask's [payload], once [wakeCheckSnooze] gave its time.
WakeCheckPlan? wakeCheckSecondPlan(
  String? payload,
  DateTime at,
  AppearanceSettings appearance,
) {
  final json = _decode(payload);
  final b = json?['b'], s = json?['s'], st = json?['st'];
  if (b is! String || s is! String || st is! int) return null;
  return (
    babyId: b,
    sessionId: s,
    start: DateTime.fromMillisecondsSinceEpoch(st),
    fireAt: at,
    second: true,
    againMinutes: 0,
    until: null,
    silent: wakeCheckSilent(appearance, at),
    hint: false,
  );
}

Map<Object?, Object?>? _decode(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    return json is Map && json['k'] == 'wake_check' ? json : null;
  } on FormatException {
    return null;
  }
}

/// Ids apart from reminders (< 2^28), the daily digest (2^28 + 7) and Nhịp lớn lên (bit 29+).
int wakeCheckNotificationId(String babyId) {
  var h = 0x811c9dc5;
  for (final c in babyId.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFF;
  }
  return (1 << 28) + 0x100 + h;
}

/// The running sleep timers this person started, with when to ask. Best effort like the other
/// local plans: a problem here never stops reminders.
final wakeCheckPlanProvider = Provider.autoDispose<List<WakeCheckPlan>>((ref) {
  try {
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return const [];
    final uid = session.user.uid;
    if (!ref.watch(wakeCheckSwitchProvider(uid))) return const [];
    // The timers first: the log, the zone and the quiet hours are read only for a sleep timer
    // this person runs (most of the time there is none).
    final mine = [
      for (final m in session.active)
        if (m.role == MemberRole.coParent || m.role == MemberRole.caregiver)
          if (ref.watch(careTimerProvider((m.babyId, TimerType.sleep))).value
              case final t? when t.startedBy == uid)
            (m, t),
    ];
    if (mine.isEmpty) return const [];
    final prefs = ref.watch(userPreferencesProvider(uid)).value;
    final again = ref.watch(wakeCheckAgainProvider);
    final appearance = ref.watch(appearanceSettingsProvider);
    final now = DateTime.now();
    final hint = wakeCheckHint(ref.read(sharedPreferencesProvider), now);
    final out = <WakeCheckPlan>[];
    for (final (m, timer) in mine) {
      final zone =
          ref.watch(babyProvider(m.babyId)).value?.timeZone.zone ??
          'Asia/Ho_Chi_Minh';
      // Until the log arrives the rules fall back to their defaults (2 h 30 / the morning).
      if (again[timer.sessionId] case final at?) {
        // "Vẫn ngủ" was answered: only the second ask is left, then nothing.
        if (at.isAfter(now)) {
          out.add((
            babyId: m.babyId,
            sessionId: timer.sessionId,
            start: timer.startedAt,
            fireAt: at,
            second: true,
            againMinutes: 0,
            until: null,
            silent: wakeCheckSilent(appearance, at),
            hint: false,
          ));
        }
        continue;
      }
      final records = ref.watch(recentRecordsProvider(m.babyId)).value ?? [];
      final times = wakeCheckTimes(
        records: records,
        start: timer.startedAt,
        now: now,
        zone: zone,
        quietFrom: prefs?.quietFrom,
        quietTo: prefs?.quietTo,
      );
      if (times != null) {
        out.add((
          babyId: m.babyId,
          sessionId: timer.sessionId,
          start: timer.startedAt,
          fireAt: times.ask,
          second: false,
          againMinutes: times.againMinutes,
          until: times.until,
          silent: wakeCheckSilent(appearance, times.ask),
          hint: hint,
        ));
      }
    }
    return out;
  } on Object {
    return const [];
  }
});

/// The notification: no baby name on the lock screen (R-120), words never a verdict.
LocalReminder wakeCheckNotification(AppLocalizations l10n, WakeCheckPlan p) {
  final minutes = p.fireAt.difference(p.start).inMinutes;
  return LocalReminder(
    id: wakeCheckNotificationId(p.babyId),
    fireAt: p.fireAt,
    title: l10n.wcTitle,
    body: p.hint
        ? l10n.wcBodyFirst(durationLabel(l10n, minutes))
        : l10n.wcBody(durationLabel(l10n, minutes)),
    payload: jsonEncode({
      'k': 'wake_check',
      'b': p.babyId,
      's': p.sessionId,
      'st': p.start.millisecondsSinceEpoch,
      'at': p.fireAt.millisecondsSinceEpoch,
      if (p.silent) 'q': 1,
      if (p.hint) 'h': 1,
      if (p.second)
        'n': 2
      else ...{
        'g': p.againMinutes,
        if (p.until case final u?) 'u': u.millisecondsSinceEpoch,
      },
    }),
    buttons: p.second
        ? NotificationButtons.wakeCheckLast
        : NotificationButtons.wakeCheck,
    silent: p.silent,
  );
}

/// The baby of a "Bé dậy chưa?" tap, or null for anything else.
String? wakeCheckOfPayload(String? payload) => switch (_decode(payload)?['b']) {
  final String b => b,
  _ => null,
};

/// The timer session a "Bé dậy chưa?" was asked for: "Dậy rồi" ends only that sleep.
String? wakeCheckSessionOfPayload(String? payload) =>
    switch (_decode(payload)?['s']) {
      final String s => s,
      _ => null,
    };
