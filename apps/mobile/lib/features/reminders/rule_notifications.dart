import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../home/home_shell.dart';
import 'rule_screens.dart';

/// A rule reminder push (D-051): `kind = reminderRule` with the baby, the rule and when it rang.
typedef RulePush = ({String babyId, String ruleId, String type});

RulePush? rulePushOf(Map<String, dynamic> data) {
  if (data['kind'] != 'reminderRule') return null;
  final babyId = data['babyId'], ruleId = data['ruleId'];
  if (babyId is! String || ruleId is! String) return null;
  return (babyId: babyId, ruleId: ruleId, type: '${data['type'] ?? 'feed'}');
}

/// The iOS side (ios/Runner/RuleNotifications.swift): which lock-screen action opened the app,
/// and re-registering the action titles after a language change.
class RuleNotificationChannel {
  const RuleNotificationChannel();

  static const _channel = MethodChannel('childlife/rules');

  Future<String?> takeLaunchAction() async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>(
        'takeLaunchAction',
      );
      return r?['action'] as String?;
    } on Object {
      return null; // Android, tests.
    }
  }

  Future<void> refreshCategories() async {
    try {
      await _channel.invokeMethod<void>('refreshCategories');
    } on Object {
      // Android, tests.
    }
  }
}

/// The care log a rule's "Ghi …" opens (Bú → the bottle sheet; the glance bridge handles
/// `/today?log=`).
String _logType(String ruleType) => switch (ruleType) {
  'sleep' => 'sleep',
  'diaper' => 'diaper',
  'pump' => 'pump',
  _ => 'bottle',
};

/// Opens what a rule reminder asks for: "Ghi …" → the log sheet on Hôm nay; a tap → 1g. Waits
/// (up to 10 s) for a cold start to sign in and show Hôm nay.
Future<void> openRulePush(
  WidgetRef ref,
  RulePush push, {
  String? action,
}) async {
  final selected = ref.read(selectedBabyIdProvider);
  if (selected != push.babyId) {
    ref.read(selectedBabyIdProvider.notifier).select(push.babyId);
  }
  final router = ref.read(routerProvider);
  if (action == 'log') {
    router.go('${Routes.today}?log=${_logType(push.type)}');
    return;
  }
  for (var i = 0; i < 40; i++) {
    final ready =
        ref.read(sessionProvider) is SessionSignedIn &&
        ref.read(selectedMembershipProvider)?.babyId == push.babyId;
    if (ready) break;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  unawaited(
    showRuleDueSheet(context, babyId: push.babyId, ruleId: push.ruleId),
  );
}
