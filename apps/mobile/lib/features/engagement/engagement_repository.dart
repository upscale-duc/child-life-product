import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_core/firebase_core.dart';
import '../reminders/reminder_notifications.dart'
    show reminderNotificationsProvider, PluginReminderNotifications;
import '../memories/memory_repository.dart';
import '../keepsakes/keepsake_nudges.dart' show nudgeStoreProvider;
export 'engagement_local.dart' show engagementRevisionProvider;
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../auto_save/auto_save_controller.dart';
import '../home/home_shell.dart';
import '../reminders/device_identity.dart';
import '../notifications/notification_repository.dart'
    show osNotificationsEnabledProvider;
import 'engagement_local.dart';

/// Unknown/loading/offline is not an empty source. No offline schedule reservation is made.
/// Overridden with [buildEngagement] in AccountLocalScope: it reads the account-scoped Auto Save
/// and Memories state, so it must never be built in the root container (it would start a second
/// AutoSaveController that outlives sign-out).
final engagementProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  buildEngagement,
  retry: (_, _) => null,
);

Future<Map<String, dynamic>> buildEngagement(Ref ref) async {
  // Optional engagement is inert until the app's normal Firebase bootstrap succeeds.
  if (Firebase.apps.isEmpty) return {};
  ref.watch(engagementRevisionProvider);
  // Session and Membership have no value equality: every members snapshot (metadata changes
  // too) is a new object. Watch only what this reads, or each snapshot re-calls getEngagement.
  final uid = ref.watch(
    sessionProvider.select(
      (s) => s is SessionSignedIn && !s.isAnonymous ? s.user.uid : null,
    ),
  );
  final selected = ref.watch(
    selectedMembershipProvider.select(
      (m) => m == null ? null : (babyId: m.babyId, role: m.role),
    ),
  );
  final session = ref.read(sessionProvider);
  final baby = ref.read(selectedMembershipProvider);
  if (uid == null ||
      selected == null ||
      session is! SessionSignedIn ||
      session.user.uid != uid ||
      baby == null) {
    return {};
  }
  if (baby.role.name == 'coParent' || baby.role.name == 'relative') {
    ref.watch(
      completeMediaProvider((
        baby.babyId,
        baby.role.name == 'coParent',
      )).select((s) => s.value?.where((m) => m.isReady && !m.deleted).length),
    );
  }
  final device = await ref.watch(deviceIdentityProvider.future);
  final view = ref.watch(
    autoSaveProvider.select(
      (v) => (
        loaded: v.loaded,
        pending: v.pendingFor(baby.babyId) > 0,
        available:
            v.canRead && v.active && v.state.babies.containsKey(baby.babyId),
        scanScopes: ({
          ...v.state.babies.keys,
          ...v.state.pending.map((c) => c.match.babyId),
        }.toList()..sort()).join('|'),
      ),
    ),
  );
  final prefs = ref.read(sharedPreferencesProvider),
      local = EngagementLocal(prefs, session.user.uid);
  Map<String, Object?>? pending;
  if (view.loaded && prefs.getString('privacy.owner') == session.user.uid) {
    final key = 'engagement.backgroundParents.${session.user.uid}';
    await prefs.setStringList(
      key,
      view.scanScopes.isEmpty ? [] : view.scanScopes.split('|'),
    );
    if (prefs.getString('privacy.owner') != session.user.uid) {
      await prefs.remove(key);
      return {};
    }
  }
  if (view.loaded) {
    pending = await local.pending(
      baby.babyId,
      pending: view.pending,
      available: view.available,
    );
  }
  final permission = ref.watch(osNotificationsEnabledProvider).value == true;
  String? zone;
  try {
    zone = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    /* Unknown zone: in-app only. */
  }
  final response = await ref
      .read(functionsProvider)
      .httpsCallable('getEngagement')
      .call<Object?>({
        'babyId': baby.babyId,
        'ownerUid': session.user.uid,
        'deviceId': device.id,
        'pushAllowed': permission,
        'recipientZone': ?zone,
        'handoffKinds': [
          for (final item in {
            'pending': 'ENG-01',
            'milestone': 'ENG-02',
            'lumi': 'ENG-06',
          }.entries)
            if (prefs.getBool(
                  'engagement.handoff.${session.user.uid}.${baby.babyId}.${item.key}',
                ) ==
                true)
              item.value,
        ],
        'legacyDismissedCampaigns': [
          for (final kind in ['m1', 'd100', 'm6', 'y1'])
            if (ref
                .read(nudgeStoreProvider)
                .dismissed()
                .contains('${baby.babyId}|$kind'))
              kind,
        ],
        'pending': ?pending,
      });
  final nowSession = ref.read(sessionProvider);
  if (nowSession is! SessionSignedIn ||
      nowSession.user.uid != session.user.uid) {
    return {};
  }
  final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
  var released = false;
  for (final lane in ['milestone', 'pending', 'lumi']) {
    final owned =
        data['enabled'] == true &&
        data['owns${lane[0].toUpperCase()}${lane.substring(1)}'] == true;
    // A definite server answer that the lane is not owned (flag off, rollback) hands it back.
    if (!owned && await local.release(lane, baby.babyId)) released = true;
  }
  if (released) ref.read(engagementRevisionProvider.notifier).refresh();
  if (data['enabled'] == true) {
    for (final lane in ['milestone', 'pending', 'lumi']) {
      if (data['owns${lane[0].toUpperCase()}${lane.substring(1)}'] != true) {
        continue;
      }
      final ackKey =
          'engagement.handoff.${session.user.uid}.${baby.babyId}.$lane';
      if (prefs.getBool(ackKey) == true) continue;
      await local.handoff(lane, baby.babyId);
      final adapter = ref.read(reminderNotificationsProvider);
      bool acknowledged = false;
      if (lane == 'pending') {
        acknowledged = await ref
            .read(autoSaveNativeProvider)
            .cancelProactiveAlerts();
      } else if (adapter is PluginReminderNotifications) {
        acknowledged = await adapter.cancelEngagementLegacy(baby.babyId, lane);
      }
      if (acknowledged) {
        await local.acknowledge(lane, baby.babyId);
        ref.read(engagementRevisionProvider.notifier).refresh();
      }
    }
  }
  return data;
}

Future<Map<String, dynamic>> actEngagement(
  WidgetRef ref,
  String id,
  String action, {
  String surface = 'in_app',
  String? sourceId,
  String? sourceType,
}) async {
  final device = await ref.read(deviceIdentityProvider.future);
  final response = await ref
      .read(functionsProvider)
      .httpsCallable('actOnEngagement')
      .call<Object?>({
        'id': id,
        'action': action,
        'surface': surface,
        'deviceId': device.id,
        'sourceId': ?sourceId,
        'sourceType': ?sourceType,
      });
  ref.read(engagementRevisionProvider.notifier).refresh();
  return Map<String, dynamic>.from(response.data as Map? ?? const {});
}

class EngagementScope extends ConsumerStatefulWidget {
  const EngagementScope({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<EngagementScope> createState() => _EngagementScopeState();
}

class _EngagementScopeState extends ConsumerState<EngagementScope> {
  late final AppLifecycleListener listener;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    listener = AppLifecycleListener(
      onResume: () {
        ref.invalidate(osNotificationsEnabledProvider);
        ref.read(engagementRevisionProvider.notifier).refresh();
      },
    );
    timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        ref.read(engagementRevisionProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(engagementProvider);
    return widget.child;
  }
}

final _viewReceiptsProvider = Provider<Set<String>>((ref) {
  ref.watch(
    sessionProvider.select((s) => s is SessionSignedIn ? s.user.uid : null),
  );
  return <String>{};
});
Future<void> engagementContentViewed(
  WidgetRef ref,
  String babyId,
  String type,
  String source,
) async {
  try {
    if (ref.read(engagementProvider).value?['enabled'] != true) return;
    final seen = ref.read(_viewReceiptsProvider), key = '$babyId/$type/$source';
    if (!seen.add(key)) return;
    if (seen.length > 2000) seen.clear();
    await ref
        .read(functionsProvider)
        .httpsCallable('engagementContentViewed')
        .call<Object?>({
          'babyId': babyId,
          'sourceType': type,
          'sourceId': source,
        });
  } catch (_) {
    /* An unobserved completion stays unknown; no child data is logged. */
  }
}
