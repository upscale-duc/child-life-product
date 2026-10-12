import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/platform/device_heartbeat.dart';
import '../../core/platform/install_source.dart';
import '../auth/auth_repository.dart';
import '../home/home_shell.dart';
import '../reminders/device_identity.dart';
import '../reminders/rule_notifications.dart';
import '../vaccines/vaccine_notifications.dart';

/// Registers this install under `users/{uid}/devices/{deviceId}` (13n device list) with its
/// push token for generic family notices (S10, R-120) when there is one, and the app language
/// for the notice copy. A remote "Đăng xuất" (S11) signs this install out. It never asks
/// for permission itself: iOS needs a granted notification permission and APNs (Apple team),
/// Android 13+ uses the permission reminders already ask for (8c). Tapping a notice opens
/// Kỷ niệm; a rule reminder (v1.0 1f) opens its sheet.
///
/// P-137: the first launch or return to the foreground on a local day also writes the activity
/// heartbeat (`lastActiveAt`, coarse `model`, `osVersion`) on that row, and on Android the
/// install source is reported once per account (`recordInstallSource`).
class PushRegistration extends ConsumerStatefulWidget {
  const PushRegistration({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<PushRegistration> createState() => _PushRegistrationState();
}

class _PushRegistrationState extends ConsumerState<PushRegistration> {
  String? _registeredFor;
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _foreground;
  String? _categoriesFor;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _signedOut;

  /// Writes this install's row for the registered account (null until [_register] ran).
  Future<void> Function(String? token, {bool beat})? _save;
  HeartbeatSchedule? _heartbeat;
  var _beating = false;
  late final AppLifecycleListener _lifecycle;
  String? _installFor;

  @override
  void initState() {
    super.initState();
    unawaited(_listenForTaps());
    // Back to the foreground on a new day: today's heartbeat (P-137).
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_resumed()));
    // Android: the Play install referrer is read on the first launch after install, and
    // reported once someone is signed in (P-137).
    unawaited(_readInstallChannel());
  }

  Future<void> _readInstallChannel() async {
    final reporter = ref.read(installSourceReporterProvider);
    if (!reporter.android) return;
    try {
      await reporter.channel();
    } on Object {
      // Preferences unavailable: read again when reporting.
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _refresh?.cancel();
    _opened?.cancel();
    _foreground?.cancel();
    _signedOut?.cancel();
    super.dispose();
  }

  Future<void> _listenForTaps() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) unawaited(_open(initial));
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => unawaited(_open(m)),
      );
      // A rule reminder that rings while the app is open shows 1g at once.
      _foreground = FirebaseMessaging.onMessage.listen((m) {
        final push = rulePushOf(m.data);
        if (push != null && mounted) unawaited(openRulePush(ref, push));
      });
    } on Object {
      // No messaging on this device (simulator without APNs, tests).
    }
  }

  Future<void> _open(RemoteMessage message) async {
    if (!mounted) return;
    // v1.0 1f / 1g: rule reminders open their sheet (or the log, from "Ghi …").
    final push = rulePushOf(message.data);
    if (push != null) {
      final action = await const RuleNotificationChannel().takeLaunchAction();
      if (mounted) await openRulePush(ref, push, action: action);
      return;
    }
    // Sổ tiêm chủng (VX 8).
    final vaccine = vaccinePushOf(message.data);
    if (vaccine != null) {
      final action = await const RuleNotificationChannel().takeLaunchAction();
      if (mounted) openVaccinePush(ref, vaccine, action: action);
      return;
    }
    // Chi tiêu: a recurring item added or 80 % of the budget (D-057).
    if (message.data['kind'] == 'spending' &&
        message.data['babyId'] is String) {
      final babyId = message.data['babyId'] as String;
      if (ref.read(selectedBabyIdProvider) != babyId) {
        ref.read(selectedBabyIdProvider.notifier).select(babyId);
      }
      // Chi tiêu lives in Tiện ích (450:6597).
      ref.read(routerProvider)
        ..go(Routes.utilities)
        ..push(Routes.spending);
      return;
    }
    ref.read(routerProvider).go(Routes.memories);
  }

  Future<void> _register(String uid, String language) async {
    final key = '$uid/$language';
    if (_registeredFor == key) return;
    _registeredFor = key;
    try {
      final device = await ref.read(deviceIdentityProvider.future);
      final info = await PackageInfo.fromPlatform();
      final db = ref.read(firestoreProvider);
      final doc = db.doc('users/$uid/devices/${device.id}');
      // 13n "Đăng xuất" from another device: this one leaves at once (S11).
      await _signedOut?.cancel();
      _signedOut = doc.snapshots().listen(
        (d) {
          if (d.data()?['signedOutAt'] != null) unawaited(_leave(doc));
        },
        // Signed out here (or the row removed): nothing to follow.
        onError: (Object _) {},
      );
      final traits = await readDeviceTraits();
      // Rules (`validDevice`): `updatedAt` is the request time on every write; `lastActiveAt`
      // is the request time when sent, otherwise left as it is (merge).
      Future<void> save(String? token, {bool beat = false}) => doc.set({
        'token': ?token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'language': language,
        'name': device.label,
        'appVersion': info.version,
        if (beat) ...{
          'lastActiveAt': FieldValue.serverTimestamp(),
          'osVersion': traits.osVersion,
          'model': traits.model,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _save = save;
      _heartbeat = HeartbeatSchedule(
        ref.read(sharedPreferencesProvider),
        uid: uid,
        deviceId: device.id,
      );
      // The row exists for "Thiết bị đang đăng nhập" even without push; on the first launch
      // of the day the same write is the heartbeat.
      if (!await _beat()) await save(null);
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await _apnsToken(messaging) == null) {
        return; // No APNs (simulator, or push not allowed for this build).
      }
      final token = await messaging.getToken();
      if (token == null) return;
      await save(token);
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen((t) => unawaited(save(t)));
    } on Object {
      _registeredFor = null; // Try again on the next change.
    }
  }

  /// P-137: at most once per local day per account and install; true when it wrote. The day
  /// is kept only once Firestore has the write, so a failed write is tried again.
  Future<bool> _beat() async {
    final save = _save;
    final schedule = _heartbeat;
    final now = DateTime.now();
    if (save == null || schedule == null || _beating || !schedule.isDue(now)) {
      return false;
    }
    _beating = true;
    try {
      await save(null, beat: true);
      await schedule.markSent(now);
      return true;
    } finally {
      _beating = false;
    }
  }

  Future<void> _resumed() async {
    try {
      await _beat();
    } on Object {
      // Offline or signed out meanwhile: the next launch or resume tries again.
    }
  }

  /// Android install source, once per account (P-137); a failure retries next session.
  Future<void> _reportInstall(String uid) async {
    if (_installFor == uid) return;
    _installFor = uid;
    try {
      await ref.read(installSourceReporterProvider).report(uid);
    } on Object {
      if (_installFor == uid) _installFor = null;
    }
  }

  /// On a device the APNs token arrives a moment after registration; wait up to ~10 s for it.
  Future<String?> _apnsToken(FirebaseMessaging messaging) async {
    for (var i = 0; i < 10; i++) {
      final token = await messaging.getAPNSToken();
      if (token != null || !mounted) return token;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Future<void> _leave(DocumentReference<Map<String, dynamic>> doc) async {
    await _signedOut?.cancel();
    _signedOut = null;
    _registeredFor = null;
    _save = null;
    _heartbeat = null;
    try {
      await doc.delete();
    } on Object {
      // Already gone.
    }
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'vi';
    if (session is! SessionSignedIn &&
        (_signedOut != null || _save != null || _installFor != null)) {
      unawaited(_signedOut?.cancel());
      _signedOut = null;
      _registeredFor = null;
      _save = null;
      _heartbeat = null;
      _installFor = null;
    }
    // The lock-screen action titles follow the app language (1f).
    if (_categoriesFor != language) {
      _categoriesFor = language;
      unawaited(const RuleNotificationChannel().refreshCategories());
    }
    if (session is SessionSignedIn && session.hasBaby && !session.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_register(session.user.uid, language)),
      );
    }
    if (session is SessionSignedIn && _installFor != session.user.uid) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_reportInstall(session.user.uid)),
      );
    }
    return widget.child;
  }
}

/// "Đăng xuất" here: this install leaves the device list, then signs out (13a, 13n).
Future<void> signOutThisDevice(WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session is SessionSignedIn) {
    try {
      final device = await ref.read(deviceIdentityProvider.future);
      await ref
          .read(firestoreProvider)
          .doc('users/${session.user.uid}/devices/${device.id}')
          .delete()
          .timeout(const Duration(seconds: 3));
    } on Object {
      // Offline: the row is removed when the delete syncs.
    }
  }
  await ref.read(authRepositoryProvider).signOut();
}
