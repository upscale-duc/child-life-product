import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../ai/ai_repository.dart' show dataVersionProvider;
import '../care/care_repository.dart' show careClockProvider, babyToday;
import '../baby/baby_repository.dart' show babyProvider;
import '../premium/premium_repository.dart' show capabilitiesProvider;
import 'rhythm_repository.dart';
import 'rhythm_access.dart';

Map<String, dynamic> dayMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> dayRows(Object? value) =>
    value is List ? value.whereType<Map>().map(dayMap).toList() : [];

/// P-172: callable responses never persist to disk, except the reduced Home copy below
/// ([PersonalDayHomeCache], D-091). Cache keys include the signed-in viewer.
class PersonalDay {
  PersonalDay(Map<String, dynamic> data) : data = Map.unmodifiable(data);
  final Map<String, dynamic> data;
  bool current(DateTime now) {
    final asOf = DateTime.tryParse('${data['asOf']}');
    final expiry = DateTime.tryParse('${data['expiresAt']}');
    return asOf != null &&
        !asOf.isAfter(now.add(const Duration(minutes: 5))) &&
        expiry != null &&
        expiry.isAfter(now);
  }

  bool get writable => data['writable'] == true;
  bool get parent => data['parent'] == true;
  bool get health => data['health'] == true;
  String get context => data['context'] as String? ?? 'usual';
  List<String> get activityIds =>
      (data['activityIds'] as List? ?? []).whereType<String>().toList();

  /// D-154 Q5: the child is older than every published idea; the age, in years, they stop at.
  int? get ideasUpToYears => switch (data['ideasMaxAgeDays']) {
    final num days => (days + 1) ~/ 365,
    _ => null,
  };
  List<Map<String, dynamic>> get notes => dayRows(data['notes']);
  List<Map<String, dynamic>> get work => dayRows(data['work']);
  List<Map<String, dynamic>> get patterns => dayRows(data['patterns']);
  Map<String, dynamic> get responses => dayMap(data['responses']);
  bool suppressed(String id, DateTime now) {
    final response = dayMap(responses[id]);
    final until = response['until'];
    final active =
        until == null || (DateTime.tryParse('$until')?.isAfter(now) ?? false);
    return active &&
        const [
          'hide',
          'snooze',
          'dislike',
          'known',
          'exclude',
          'tried',
          'helpful',
        ].contains(response['value']);
  }
}

typedef PersonalDayKey = ({String babyId, String uid, String locale});

class PersonalizationRepository {
  PersonalizationRepository(this._functions);
  final FirebaseFunctions _functions;
  Future<PersonalDay> read(PersonalDayKey key) async {
    final result = await _functions
        .httpsCallable('getPersonalizedDay')
        .call<Object?>({
          'babyId': key.babyId,
          'locale': key.locale == 'en' ? 'en' : 'vi',
        });
    return PersonalDay(dayMap(result.data));
  }

  Future<void> update(String babyId, Map<String, Object?> action) async {
    await _functions.httpsCallable('updatePersonalizedDay').call<Object?>({
      'babyId': babyId,
      'action': action,
    });
  }
}

final personalizationRepositoryProvider = Provider(
  (ref) => PersonalizationRepository(ref.watch(functionsProvider)),
);
final personalDayProvider = FutureProvider.autoDispose
    .family<PersonalDay, PersonalDayKey>((ref, key) {
      final session = ref.watch(sessionProvider);
      final me = session is SessionSignedIn
          ? session.membershipFor(key.babyId)
          : null;
      if (me == null ||
          me.uid != key.uid ||
          !familyCan(me, FamilyAction.historyRead)) {
        throw const RhythmException('ROLE_DENIED');
      }
      ref.watch(dataVersionProvider(key.babyId));
      ref.watch(rhythmContentProvider);
      ref.watch(userPreferencesProvider(key.uid));
      final zone =
          ref.watch(babyProvider(key.babyId)).value?.timeZone.zone ??
          'Asia/Ho_Chi_Minh';
      ref.watch(capabilitiesProvider(key.babyId));
      ref.watch(
        careClockProvider.select((value) {
          final now = value.value;
          return now == null ? null : (now.toUtc().hour, babyToday(zone, now));
        }),
      );
      return ref.watch(personalizationRepositoryProvider).read(key);
    }, retry: (_, _) => null);

Future<void> updatePersonalDay(
  WidgetRef ref,
  PersonalDayKey key,
  Map<String, Object?> action,
) async {
  await ref.read(personalizationRepositoryProvider).update(key.babyId, action);
  if (!ref.context.mounted) return;
  ref.invalidate(personalDayProvider(key));
  ref.invalidate(homeCompositionProvider);
}

/// D-091 (owner, 2026-10-22): the Home card draws at once from a reduced copy of today's
/// snapshot kept on this phone per person and baby, then the fresh answer replaces it. Only
/// what the card needs and no child data: activity ids, this person's own responses to them,
/// today's time, the weekly focus and counts. Never notes, care records, reminder titles,
/// patterns, the age card or anything on a health day (that day removes the copy). It expires
/// with the snapshot (next local midnight) and is used on Home only; every other page waits
/// for the server.
class PersonalDayHomeCache {
  PersonalDayHomeCache(this._prefs);
  final SharedPreferences _prefs;

  static String _key(PersonalDayKey key) =>
      'personal.day.home.${key.uid}.${key.babyId}';

  static const _kept = [
    'asOf',
    'expiresAt',
    'today',
    'zone',
    'writable',
    'parent',
    'contentVersion',
    'context',
    'focus',
    'reason',
    'activityIds',
    'weekly',
    // A content limit (the pack's last age), not child data: Home needs it to say why.
    'ideasMaxAgeDays',
  ];
  static const _responseFields = [
    'value',
    'at',
    'until',
    'saved',
    'intendedAt',
    'triedAt',
    'outcome',
    'outcomeAt',
  ];

  /// The copy kept for [day]: null on a health day (nothing is kept then).
  static Map<String, Object?>? reduce(PersonalDay day) {
    if (day.health) return null;
    return {
      for (final k in _kept)
        if (day.data.containsKey(k)) k: day.data[k],
      'responses': {
        for (final e in day.responses.entries)
          if (e.key.startsWith('act_'))
            e.key: {
              for (final f in _responseFields)
                if (dayMap(e.value).containsKey(f)) f: dayMap(e.value)[f],
            },
      },
      'fromCache': true,
    };
  }

  void write(PersonalDayKey key, PersonalDay day) {
    final copy = reduce(day);
    if (copy == null) {
      _prefs.remove(_key(key));
    } else {
      _prefs.setString(_key(key), jsonEncode(copy));
    }
  }

  /// Today's copy, or null when there is none, it is unreadable or it has expired.
  PersonalDay? read(PersonalDayKey key, DateTime now) {
    final raw = _prefs.getString(_key(key));
    if (raw == null) return null;
    try {
      final day = PersonalDay(dayMap(jsonDecode(raw)));
      return day.current(now) ? day : null;
    } on FormatException {
      return null;
    }
  }
}

final personalDayHomeCacheProvider = Provider<PersonalDayHomeCache?>((ref) {
  try {
    return PersonalDayHomeCache(ref.watch(sharedPreferencesProvider));
  } on Object {
    return null;
  }
});

/// Today's snapshot for Home: the fresh one, or while it loads the kept copy (D-091). Null on
/// an error (a caregiver without the diary, offline with nothing kept).
final personalDayHomeProvider = Provider.autoDispose
    .family<PersonalDay?, PersonalDayKey>((ref, key) {
      final cache = ref.watch(personalDayHomeCacheProvider);
      final fresh = ref.watch(personalDayProvider(key));
      if (fresh.hasValue) {
        final day = fresh.value!;
        cache?.write(key, day);
        return day;
      }
      if (fresh.hasError) return null;
      final kept = cache?.read(
        key,
        ref.read(careClockProvider).value ?? DateTime.now(),
      );
      if (kept == null) return null;
      // A health sign noted since (another phone): the card must not offer an idea meanwhile.
      final checkIns = ref.watch(checkInsProvider(key.babyId));
      if (!checkIns.hasValue) return null;
      final health = checkIns.value!.any(
        (c) => c.date == kept.data['today'] && c.needsHealthSupport,
      );
      return health ? null : kept;
    });
