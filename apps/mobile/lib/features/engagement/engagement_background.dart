import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/bootstrap.dart' show bootstrapBackgroundFirebase;
import '../../app/providers.dart' show functionsRegion;
import '../auto_save/auto_save_controller.dart';
import '../auto_save/auto_save_native.dart';
import 'engagement_local.dart';

class EngagementBackground {
  const EngagementBackground({required this.mayScan, this.sync});
  final bool mayScan;
  final Future<void> Function(AutoSaveView)? sync;
}

/// Runs BEFORE opening the biometric store. A new lease requires live authorization of
/// every cached scan scope; offline cannot renew the original 24-hour privacy boundary.
Future<EngagementBackground?> prepareEngagementBackground(
  SharedPreferences prefs,
  String owner,
) async {
  final parents =
      prefs.getStringList('engagement.backgroundParents.$owner') ??
      const <String>[];
  // Only babies whose family handed ENG-01 over need the live lease; the others keep the
  // legacy background path and must not be refused because their family is outside rollout.
  final owned = [
    for (final b in parents)
      if (EngagementLocal(prefs, owner).ownsLegacy('pending', b)) b,
  ];
  if (owned.isEmpty) return null;
  final existingUntil = prefs.getInt('privacy.backgroundUntil') ?? 0;
  try {
    await bootstrapBackgroundFirebase();
    final auth = FirebaseAuth.instance;
    final user = await auth.authStateChanges().first.timeout(
      const Duration(seconds: 3),
    );
    if (user?.uid != owner || prefs.getString('privacy.owner') != owner) {
      return const EngagementBackground(mayScan: false);
    }
    final device = prefs.getString('device.id');
    if (device == null) return const EngagementBackground(mayScan: false);
    final functions = FirebaseFunctions.instanceFor(region: functionsRegion);
    final access = await functions
        .httpsCallable('getEngagementBackgroundAccess')
        .call<Object?>({
          'ownerUid': owner,
          'deviceId': device,
          'babyIds': owned,
        })
        .timeout(const Duration(seconds: 8));
    final data = access.data is Map ? access.data! as Map : const {};
    if (data['authorized'] != true || data['leaseUntil'] is! num) {
      return const EngagementBackground(mayScan: false);
    }
    final until = (data['leaseUntil'] as num).toInt();
    if (prefs.getString('privacy.owner') != owner ||
        auth.currentUser?.uid != owner) {
      return const EngagementBackground(mayScan: false);
    }
    await prefs.setInt('privacy.backgroundUntil', until);
    return EngagementBackground(
      mayScan: until > DateTime.now().millisecondsSinceEpoch,
      sync: (view) async {
        if (prefs.getString('privacy.owner') != owner ||
            auth.currentUser?.uid != owner ||
            !view.loaded) {
          return;
        }
        final native = AutoSaveNative(),
            permission = await AutoSaveNative().notificationCapability();
        String? zone;
        try {
          zone = (await FlutterTimezone.getLocalTimezone()).identifier;
        } catch (_) {
          /* Unknown zone prevents push. */
        }
        final local = EngagementLocal(prefs, owner);
        for (final baby in view.state.babies.keys) {
          if (!owned.contains(baby)) continue;
          final pending = await local.pending(
            baby,
            pending: view.pendingFor(baby) > 0,
            available: view.canRead && view.active,
          );
          if (pending == null ||
              auth.currentUser?.uid != owner ||
              prefs.getString('privacy.owner') != owner) {
            return;
          }
          // This is source verification, never a local push or automatic upload/render.
          await functions
              .httpsCallable('getEngagement')
              .call<Object?>({
                'ownerUid': owner,
                'babyId': baby,
                'deviceId': device,
                'pushAllowed': permission,
                'recipientZone': ?zone,
                'pendingOnly': true,
                'pending': pending,
                'handoffKinds':
                    prefs.getBool('engagement.handoff.$owner.$baby.pending') ==
                        true
                    ? ['ENG-01']
                    : [],
              })
              .timeout(const Duration(seconds: 8));
        }
        // Retain the already-installed native scan callback; no second scheduler is created.
        await native.schedule();
      },
    );
  } on FirebaseFunctionsException catch (e) {
    if ([
      'permission-denied',
      'unauthenticated',
      'not-found',
      'invalid-argument',
    ].contains(e.code)) {
      return const EngagementBackground(mayScan: false);
    }
    return EngagementBackground(
      mayScan: existingUntil > DateTime.now().millisecondsSinceEpoch,
    );
  } catch (_) {
    return EngagementBackground(
      mayScan: existingUntil > DateTime.now().millisecondsSinceEpoch,
    );
  }
}
