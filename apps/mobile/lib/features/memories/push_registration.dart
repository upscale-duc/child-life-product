import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../reminders/device_identity.dart';

/// Registers this install's push token for generic family notices (S10, R-120) under
/// `users/{uid}/devices/{deviceId}`, with the app language for the notice copy. It never asks
/// for permission itself: iOS needs a granted notification permission and APNs (Apple team),
/// Android 13+ uses the permission reminders already ask for (8c). Tapping a notice opens
/// Kỷ niệm.
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

  @override
  void initState() {
    super.initState();
    unawaited(_listenForTaps());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _opened?.cancel();
    super.dispose();
  }

  Future<void> _listenForTaps() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open();
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((_) => _open());
    } on Object {
      // No messaging on this device (simulator without APNs, tests).
    }
  }

  void _open() {
    if (!mounted) return;
    ref.read(routerProvider).go(Routes.memories);
  }

  Future<void> _register(String uid, String language) async {
    final key = '$uid/$language';
    if (_registeredFor == key) return;
    _registeredFor = key;
    try {
      final device = await ref.read(deviceIdentityProvider.future);
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await messaging.getAPNSToken() == null) {
        return; // No APNs (simulator or no Apple team yet).
      }
      final token = await messaging.getToken();
      if (token == null) return;
      final db = ref.read(firestoreProvider);
      Future<void> save(String t) =>
          db.doc('users/$uid/devices/${device.id}').set({
            'token': t,
            'platform': defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
            'language': language,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await save(token);
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen((t) => unawaited(save(t)));
    } on Object {
      _registeredFor = null; // Try again on the next change.
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'vi';
    if (session is SessionSignedIn && session.hasBaby && !session.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_register(session.user.uid, language)),
      );
    }
    return widget.child;
  }
}
