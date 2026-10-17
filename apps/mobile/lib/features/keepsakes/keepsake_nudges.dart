import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show timerClockProvider;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../reminders/reminder_notifications.dart'
    show LocalReminder, loadSettled;
import 'keepsake_access.dart';
import 'keepsake_occasions.dart';

/// Milestone nudges (D-068 #9; Figma MM03 `528:9864`). Everything is worked out on the phone from
/// the date of birth and what is in Kỷ niệm (no server job, nothing about the baby leaves the
/// phone), for babies the person is Cùng nuôi of in a family in the beta:
/// - **On the day** of an age occasion (7 ngày, 1 tháng, 100 ngày, 1 tuổi), a local notification
///   at 09:00: "Hôm nay Teddy tròn 1 tháng".
/// - **Looking back**: once the person has used Child Life for 7 days, each occasion the baby has
///   already passed that has photos in Kỷ niệm and no card yet gets one notification, at 09:00,
///   at least 3 days apart. A slot once given never moves, so opening the app every day does not
///   push it back.
/// - **In the app**, MM03's card on Ảnh from 7 days before to 14 days after an age occasion, and
///   for 7 days after a first-time occasion is tagged.
/// No setting turns them off (owner: always suggest); the OS notification permission still
/// applies. A card made for the occasion, or × on MM03, ends that occasion's nudges.

const nudgeHour = 9;
const lookBackAfterDays = 7;
const lookBackGapDays = 3;
const _maxLookBackPending = 3;

/// One occasion of one baby (`babyId|occasion`).
String nudgeKey(String babyId, Occasion o) => '$babyId|${o.wire}';

@immutable
class NudgeBaby {
  const NudgeBaby({
    required this.babyId,
    required this.name,
    required this.dob,
    required this.media,
  });
  final String babyId;
  final String name;
  final DateTime dob;

  /// The baby's Kỷ niệm (parents' view).
  final List<MediaItem> media;

  /// Occasions that already have a card.
  Set<Occasion> get carded => {
    for (final m in media)
      if (m.generatedKind == 'card' && !m.deleted)
        for (final o in Occasion.nudged)
          if (m.milestone?.id == o.milestoneId) o,
  };

  /// Photos of an occasion: tagged with its milestone, or taken within 3 days of an age
  /// occasion's day (cards themselves never count).
  int photosOf(Occasion o, DateTime? date) => media.where((m) {
    if (m.isVideo || m.deleted || !m.isReady || m.generatedKind != null) {
      return false;
    }
    if (m.milestone?.id == o.milestoneId) return true;
    return o.byAge &&
        date != null &&
        m.captureAt.difference(date).inHours.abs() <= 3 * 24 + 12;
  }).length;
}

enum NudgeKind { onTheDay, lookBack }

@immutable
class Nudge {
  const Nudge({
    required this.babyId,
    required this.name,
    required this.occasion,
    required this.kind,
    required this.fireAt,
    this.photos = 0,
  });
  final String babyId;
  final String name;
  final Occasion occasion;
  final NudgeKind kind;
  final DateTime fireAt;
  final int photos;

  String get key => nudgeKey(babyId, occasion);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _at9(DateTime d) => DateTime(d.year, d.month, d.day, nudgeHour);

/// The notifications this phone should have pending, and the look-back slots it gave out now
/// (to keep). Pure, so it is tested without a phone.
({List<Nudge> nudges, Map<String, DateTime> newSlots}) planNudges({
  required List<NudgeBaby> babies,
  required DateTime now,
  required DateTime usingSince,
  required Map<String, DateTime> slots,
  required Set<String> dismissed,
}) {
  final today = _day(now);
  final out = <Nudge>[];
  final newSlots = <String, DateTime>{};

  // On the day: the next two age occasions of each baby still to come.
  for (final b in babies) {
    final carded = b.carded;
    final next = [
      for (final o in Occasion.nudged.where((o) => o.byAge))
        if (!carded.contains(o) && !dismissed.contains(nudgeKey(b.babyId, o)))
          (o, _at9(o.dateFor(b.dob, const [])!)),
    ]..removeWhere((e) => !e.$2.isAfter(now));
    next.sort((a, c) => a.$2.compareTo(c.$2));
    for (final (o, at) in next.take(2)) {
      out.add(
        Nudge(
          babyId: b.babyId,
          name: b.name,
          occasion: o,
          kind: NudgeKind.onTheDay,
          fireAt: at,
        ),
      );
    }
  }

  // Looking back: occasions passed, with photos, no card, oldest first.
  final candidates = <(NudgeBaby, Occasion, DateTime, int)>[];
  for (final b in babies) {
    final carded = b.carded;
    final tagged = [for (final m in b.media) ?m.milestone];
    for (final o in Occasion.nudged) {
      final key = nudgeKey(b.babyId, o);
      if (carded.contains(o) || dismissed.contains(key)) continue;
      final date = o.dateFor(b.dob, tagged);
      if (date == null || !_day(date).isBefore(today)) continue;
      final photos = b.photosOf(o, date);
      if (photos == 0) continue;
      candidates.add((b, o, date, photos));
    }
  }
  candidates.sort((a, c) => a.$3.compareTo(c.$3));
  var last = [
    ...slots.values,
  ].fold<DateTime?>(null, (m, d) => m == null || d.isAfter(m) ? d : m);
  final earliest = _at9(
    _day(usingSince).add(const Duration(days: lookBackAfterDays)),
  );
  var pending = 0;
  for (final (b, o, _, photos) in candidates) {
    final key = nudgeKey(b.babyId, o);
    var at = slots[key];
    if (at == null) {
      // A new slot: after the 7 days, tomorrow at the earliest, 3 days after the last one.
      var t = _at9(today.add(const Duration(days: 1)));
      if (t.isBefore(earliest)) t = earliest;
      if (last != null) {
        final gap = _at9(_day(last).add(const Duration(days: lookBackGapDays)));
        if (t.isBefore(gap)) t = gap;
      }
      at = t;
      newSlots[key] = at;
      last = at;
    }
    // A slot in the past has had its notification: never again.
    if (!at.isAfter(now) || pending >= _maxLookBackPending) continue;
    pending++;
    out.add(
      Nudge(
        babyId: b.babyId,
        name: b.name,
        occasion: o,
        kind: NudgeKind.lookBack,
        fireAt: at,
        photos: photos,
      ),
    );
  }
  return (nudges: out, newSlots: newSlots);
}

/// MM03 on Ảnh: the occasion to show now, if any (age: 7 days before to 14 after; first-time:
/// 7 days after it is tagged), skipping cards made, × and "Để sau" (3 days).
({Occasion occasion, DateTime date})? inAppNudge(
  NudgeBaby b,
  DateTime now, {
  required Set<String> dismissed,
  required Map<String, DateTime> snoozed,
}) {
  final today = _day(now);
  final carded = b.carded;
  final tagged = [for (final m in b.media) ?m.milestone];
  ({Occasion occasion, DateTime date})? best;
  var bestGap = 1 << 30;
  for (final o in Occasion.nudged) {
    final key = nudgeKey(b.babyId, o);
    if (carded.contains(o) || dismissed.contains(key)) continue;
    final until = snoozed[key];
    if (until != null && today.isBefore(until)) continue;
    final date = o.dateFor(b.dob, tagged);
    if (date == null) continue;
    final gap = _day(date).difference(today).inDays;
    final inWindow = o.byAge ? gap >= -14 && gap <= 7 : gap >= -7 && gap <= 0;
    if (inWindow && gap.abs() < bestGap) {
      best = (occasion: o, date: _day(date));
      bestGap = gap.abs();
    }
  }
  return best;
}

// ---------- On this phone ----------

/// What the nudges remember on this phone (never synced: like Tự lưu's settings, D-066 #5).
class NudgeStore {
  NudgeStore(this._prefs);
  final SharedPreferences _prefs;

  static const _firstSeen = 'keepsakes.firstSeen';
  static const _slots = 'keepsakes.lookBackSlots';
  static const _dismissed = 'keepsakes.dismissed';
  static const _snoozed = 'keepsakes.snoozed';

  DateTime firstSeen(DateTime now) {
    final v = DateTime.tryParse(_prefs.getString(_firstSeen) ?? '');
    if (v != null) return v;
    _prefs.setString(_firstSeen, now.toIso8601String()).ignore();
    return now;
  }

  Map<String, DateTime> _dates(String k) {
    try {
      final m = jsonDecode(_prefs.getString(k) ?? '{}') as Map;
      return {
        for (final e in m.entries) '${e.key}': ?DateTime.tryParse('${e.value}'),
      };
    } on Object {
      return {};
    }
  }

  Future<void> _putDates(String k, Map<String, DateTime> v) => _prefs.setString(
    k,
    jsonEncode({for (final e in v.entries) e.key: e.value.toIso8601String()}),
  );

  Map<String, DateTime> slots() => _dates(_slots);
  Future<void> addSlots(Map<String, DateTime> add) =>
      add.isEmpty ? Future.value() : _putDates(_slots, {...slots(), ...add});

  Set<String> dismissed() => {...?_prefs.getStringList(_dismissed)};
  Future<void> dismiss(String key) =>
      _prefs.setStringList(_dismissed, [...dismissed(), key]);

  Map<String, DateTime> snoozed() => _dates(_snoozed);
  Future<void> snooze(String key, DateTime until) =>
      _putDates(_snoozed, {...snoozed(), key: until});
}

/// Bumped when MM03's × or "Để sau" changes what to show.
class NudgeRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final nudgeRevisionProvider = NotifierProvider<NudgeRevision, int>(
  NudgeRevision.new,
);

final nudgeStoreProvider = Provider<NudgeStore>(
  (ref) => NudgeStore(ref.watch(sharedPreferencesProvider)),
);

/// The babies to nudge about: Cùng nuôi in the beta, with a date of birth.
final nudgeBabiesProvider = Provider.autoDispose<List<NudgeBaby>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return const [];
  return [
    for (final m in session.active)
      if (m.role == MemberRole.coParent &&
          (ref.watch(keepsakeAccessProvider(m.babyId)).value?.cards ?? false))
        if (ref.watch(babyPrivateProfileProvider(m.babyId)).value?.dateOfBirth
            case final dob?)
          NudgeBaby(
            babyId: m.babyId,
            name: ref.watch(babyProvider(m.babyId)).value?.nickname ?? '',
            dob: dob,
            media: ref.watch(mediaProvider((m.babyId, true))).value ?? const [],
          ),
  ];
});

/// Whether everything [nudgeBabiesProvider] reads has answered, so the reminder sync does not
/// take "still loading" for "no nudges" and cancel the ones already scheduled.
final nudgePlanReadyProvider = Provider.autoDispose<bool>((ref) {
  try {
    final session = ref.watch(sessionProvider);
    if (session is SessionLoading) return false;
    if (session is! SessionSignedIn) return true;
    for (final m in session.active) {
      if (m.role != MemberRole.coParent) continue;
      final access = ref.watch(keepsakeAccessProvider(m.babyId));
      if (!loadSettled(access)) return false;
      if (!(access.value?.cards ?? false)) continue;
      final profile = ref.watch(babyPrivateProfileProvider(m.babyId));
      if (!loadSettled(profile)) return false;
      if (profile.value?.dateOfBirth == null) continue;
      if (!loadSettled(ref.watch(babyProvider(m.babyId))) ||
          !loadSettled(ref.watch(mediaProvider((m.babyId, true))))) {
        return false;
      }
    }
    return true;
  } on Object {
    // Best effort: a nudge problem must never stop reminders from being scheduled.
    return true;
  }
});

/// The plan for this phone right now, for the reminder sync to schedule.
final nudgePlanProvider =
    Provider.autoDispose<
      ({List<Nudge> nudges, Map<String, DateTime> newSlots})
    >((ref) {
      ref.watch(nudgeRevisionProvider);
      final now = ref.read(timerClockProvider)();
      // Best effort: a nudge problem must never stop reminders from being scheduled.
      final NudgeStore store;
      try {
        store = ref.watch(nudgeStoreProvider);
      } on Object {
        return (nudges: const <Nudge>[], newSlots: const <String, DateTime>{});
      }
      final session = ref.watch(sessionProvider);
      var since = store.firstSeen(now);
      // Seven days of use counts from the account, for people who were here before this.
      if (session is SessionSignedIn) {
        try {
          final created = session.user.metadata.creationTime;
          if (created != null && created.isBefore(since)) since = created;
        } on Object {
          // No metadata (tests): this phone's first look.
        }
      }
      return planNudges(
        babies: ref.watch(nudgeBabiesProvider),
        now: now,
        usingSince: since,
        slots: store.slots(),
        dismissed: store.dismissed(),
      );
    });

/// The notification for a nudge; tapping it opens MM10 with the occasion picked.
LocalReminder nudgeNotification(AppLocalizations l10n, Nudge n) {
  final (title, body) = switch (n.kind) {
    NudgeKind.onTheDay => (
      l10n.ksNudgeTodayTitle(n.name, n.occasion.title(l10n)),
      l10n.ksNudgeTodayBody,
    ),
    NudgeKind.lookBack => (
      n.occasion.byAge
          ? l10n.ksNudgeBackAgeTitle(n.name, n.occasion.title(l10n))
          : l10n.ksNudgeBackFirstTitle(n.name, n.occasion.label(l10n)),
      l10n.ksNudgeBackBody(n.photos),
    ),
  };
  return LocalReminder(
    id: nudgeNotificationId(n.key, n.kind),
    fireAt: n.fireAt,
    title: title,
    body: body,
    payload: jsonEncode({
      'k': 'keepsake',
      'b': n.babyId,
      'o': n.occasion.wire,
      'at': n.fireAt.millisecondsSinceEpoch,
      't': title,
      'x': body,
    }),
  );
}

/// Ids apart from reminders' (28 bits): bit 30 set.
int nudgeNotificationId(String key, NudgeKind kind) {
  var h = 0x811c9dc5;
  for (final c in '$key|${kind.name}'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x0FFFFFFF;
  }
  return 0x40000000 | h;
}

/// (babyId, occasion) from a nudge notification, or null for anything else.
(String, Occasion)? nudgeOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final j = jsonDecode(payload);
    if (j is! Map || j['k'] != 'keepsake') return null;
    final o = Occasion.fromWire(j['o'] as String?);
    final b = j['b'];
    if (o == null || b is! String) return null;
    return (b, o);
  } on Object {
    return null;
  }
}
