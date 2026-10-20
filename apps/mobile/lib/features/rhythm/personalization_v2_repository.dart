import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
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

/// P-172: callable responses never persist to disk. Cache keys include the signed-in viewer.
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
