import '../engagement/engagement_local.dart';
import '../../core/appearance/appearance_providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/session.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../reminders/device_identity.dart';
import 'personalization_v2_repository.dart';
import 'rhythm_repository.dart';

const personalDigestNotificationId = (1 << 28) + 7;
final personalDeliveryProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, uid) => ref
          .watch(firestoreProvider)
          .doc('users/$uid/settings/personalizationDelivery')
          .snapshots()
          .map((s) => s.data() ?? {}),
    );

/// Server reserves one install and one fresh daily slot; local notification carries no care facts.
final personalDigestPlanProvider =
    FutureProvider.autoDispose<({String babyId, DateTime fireAt})?>((
      ref,
    ) async {
      final session = ref.watch(sessionProvider);
      if (session is! SessionSignedIn) return null;
      final delivery = ref
          .watch(personalDeliveryProvider(session.user.uid))
          .value;
      final device = ref.watch(deviceIdentityProvider).value;
      if (delivery == null ||
          device == null ||
          delivery['enabled'] != true ||
          delivery['deviceId'] != device.id) {
        return null;
      }
      final babyId = delivery['babyId'];
      if (babyId is! String || session.membershipFor(babyId) == null) {
        return null;
      }
      ref.watch(engagementRevisionProvider);
      if (EngagementLocal(
        ref.read(sharedPreferencesProvider),
        session.user.uid,
      ).ownsLegacy('lumi', babyId)) {
        return null;
      }
      ref.watch(userPreferencesProvider(session.user.uid));
      ref.watch(
        personalDayProvider((
          babyId: babyId,
          uid: session.user.uid,
          locale: 'vi',
        )),
      );
      ref.watch(babyProvider(babyId));
      // Clock rollover renews only after the app is active on the new day.
      ref.watch(careClockProvider.select((v) => v.value?.toUtc().hour));
      try {
        final reply = await ref
            .read(functionsProvider)
            .httpsCallable('reservePersonalizationDigest')
            .call<Object?>({'babyId': babyId, 'deviceId': device.id});
        final fireAt = DateTime.tryParse('${dayMap(reply.data)['fireAt']}');
        return fireAt == null ? null : (babyId: babyId, fireAt: fireAt);
      } catch (_) {
        return null;
      }
    }, retry: (_, _) => null);

String? personalDayFromPayload(String? payload) {
  try {
    final data = jsonDecode(payload ?? 'null');
    return data is Map && data['k'] == 'personal_day' && data['b'] is String
        ? data['b'] as String
        : null;
  } catch (_) {
    return null;
  }
}
