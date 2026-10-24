import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../l10n/app_localizations.dart';
import '../reminders/reminder_notifications.dart' show LocalReminder;

/// P-179: "Mình sẽ thử" with a time. This phone reminds the person at that time ("Đến giờ thử
/// rồi") and, if they have not answered, asks the next morning at 08:30 ("Đã thử chưa?"). Both
/// open the activity. Device-local like the person's own reminders: the choice is made in the
/// app, so it is always scheduled. Any later answer (tried, an outcome, put away) clears it.
class TryReminder {
  const TryReminder({
    required this.contentId,
    required this.babyId,
    required this.title,
    required this.at,
  });
  final String contentId;
  final String babyId;

  /// The activity's title in the language it was chosen in (the payload never needs content).
  final String title;
  final DateTime at;

  /// The next morning at 08:30, local.
  DateTime get askAt => DateTime(at.year, at.month, at.day + 1, 8, 30);

  Map<String, Object> toJson() => {
    'b': babyId,
    't': title,
    'at': at.toIso8601String(),
  };
}

/// What this person asked to be reminded about, per phone.
class TryReminderStore {
  TryReminderStore(this._prefs, this.uid);
  final SharedPreferences _prefs;
  final String uid;
  String get _key => 'try.remind.$uid';

  Map<String, TryReminder> read() {
    try {
      final raw = jsonDecode(_prefs.getString(_key) ?? '{}');
      if (raw is! Map) return {};
      final out = <String, TryReminder>{};
      for (final e in raw.entries) {
        final v = e.value;
        final at = v is Map ? DateTime.tryParse('${v['at']}') : null;
        if (v is! Map || at == null) continue;
        out['${e.key}'] = TryReminder(
          contentId: '${e.key}',
          babyId: '${v['b']}',
          title: '${v['t']}',
          at: at,
        );
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, TryReminder> all) => _prefs.setString(
    _key,
    jsonEncode({for (final r in all.values) r.contentId: r.toJson()}),
  );

  Future<void> set(TryReminder r) => _write({...read(), r.contentId: r});

  /// Answered or put away: nothing more to remind about.
  Future<bool> clear(String contentId) async {
    final all = read();
    if (all.remove(contentId) == null) return false;
    await _write(all);
    return true;
  }

  /// Drops the ones whose morning question has passed.
  Future<void> prune(DateTime now) async {
    final all = read();
    final before = all.length;
    all.removeWhere((_, r) => !r.askAt.isAfter(now));
    if (all.length != before) await _write(all);
  }
}

/// Bumped on every change so the reminder sync reschedules.
final tryRemindersRevisionProvider = NotifierProvider<_Revision, int>(
  _Revision.new,
);

class _Revision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final tryReminderStoreProvider = Provider<TryReminderStore?>((ref) {
  ref.watch(tryRemindersRevisionProvider);
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return null;
  return TryReminderStore(
    ref.watch(sharedPreferencesProvider),
    session.user.uid,
  );
});

/// Answers that end the plan (an attempt, an outcome, put away); "save" or a new plan do not.
const tryReminderClearingValues = {
  'tried',
  'helpful',
  'unsure',
  'snooze',
  'hide',
  'dislike',
  'known',
  'exclude',
};

/// Notification ids above the reminder UUID range (28 bits) and the digest's `(1 << 28) + 7`.
int tryReminderId(String contentId, {required bool ask}) =>
    (1 << 29) + (contentId.hashCode & 0xFFFFF) * 2 + (ask ? 1 : 0);

/// Both notifications of each plan still ahead of [now].
List<LocalReminder> tryReminderNotifications(
  AppLocalizations l,
  Iterable<TryReminder> plans,
  DateTime now,
) => [
  for (final r in plans) ...[
    if (r.at.isAfter(now))
      LocalReminder(
        id: tryReminderId(r.contentId, ask: false),
        fireAt: r.at,
        title: l.pv2TryNowTitle,
        body: r.title,
        payload: jsonEncode({
          'k': 'try',
          'b': r.babyId,
          'c': r.contentId,
          'at': r.at.toIso8601String(),
        }),
      ),
    if (r.askAt.isAfter(now))
      LocalReminder(
        id: tryReminderId(r.contentId, ask: true),
        fireAt: r.askAt,
        title: l.pv2TryAskTitle,
        body: l.pv2TryAskBody(r.title),
        payload: jsonEncode({
          'k': 'try',
          'b': r.babyId,
          'c': r.contentId,
          'at': r.askAt.toIso8601String(),
        }),
      ),
  ],
];

/// The baby and activity a tapped try reminder opens, else null.
({String babyId, String contentId})? tryReminderFromPayload(String? payload) {
  try {
    final data = jsonDecode(payload ?? 'null');
    return data is Map &&
            data['k'] == 'try' &&
            data['b'] is String &&
            data['c'] is String
        ? (babyId: data['b'] as String, contentId: data['c'] as String)
        : null;
  } catch (_) {
    return null;
  }
}
