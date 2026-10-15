import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../memories/push_registration.dart' show keepsakeJobPushOf;
import '../reminders/rule_notifications.dart';
import '../vaccines/vaccine_notifications.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

/// Where an inbox row (EN06) or its push goes (D-076 #2): the same screens a push opens.
/// Returns false when the row points at a baby this person no longer follows.
Future<bool> openInboxItem(WidgetRef ref, InboxItem item) async {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return false;
  if (item.unread) {
    unawaited(_markRead(ref, session.user.uid, [item.id]));
  }
  final babyId = item.babyId;
  if (babyId != null && !session.active.any((m) => m.babyId == babyId)) {
    return false;
  }
  void select() {
    if (babyId != null && ref.read(selectedBabyIdProvider) != babyId) {
      ref.read(selectedBabyIdProvider.notifier).select(babyId);
    }
  }

  final router = ref.read(routerProvider);
  switch (item.route) {
    case 'ruleReminder':
      final push = rulePushOf(item.data);
      if (push != null) await openRulePush(ref, push);
    case 'vaccine':
      final push = vaccinePushOf(item.data);
      if (push != null) openVaccinePush(ref, push);
    case 'spending':
      select();
      router
        ..go(Routes.utilities)
        ..push(Routes.spending);
      final importId = item.data['importId'];
      if (importId != null && RegExp(r'^im_[a-f0-9]{32}$').hasMatch(importId)) {
        router.push('${Routes.spendingImport}/$importId');
      }
    case 'keepsakeJob':
      final job = keepsakeJobPushOf(item.data);
      if (job == null) break;
      select();
      router
        ..go(Routes.memories)
        ..push('${Routes.memoryStoryJob}/${job.jobId}?baby=${job.babyId}');
    case 'memories':
      select();
      router.go(Routes.memories);
    default:
    // Shown in full in the inbox (e.g. the delivery check): nothing to open.
  }
  return true;
}

/// [openInboxItem] from a row, with the toast when it cannot open.
Future<void> openInboxRow(
  BuildContext context,
  WidgetRef ref,
  InboxItem item,
) async {
  final gone = AppLocalizations.of(context).ntGone;
  final toaster = ClToaster.of(context);
  if (!await openInboxItem(ref, item)) toaster.show(message: gone);
}

Future<void> _markRead(WidgetRef ref, String uid, List<String> ids) async {
  try {
    await ref.read(notificationRepositoryProvider).markRead(uid, ids);
  } on Object {
    // Offline: the write syncs later; a failure leaves the row unread.
  }
}

/// A push carries its inbox row's id (`inboxId`): opening the push reads the row.
void markPushRead(WidgetRef ref, Map<String, dynamic> data) {
  final id = data['inboxId'];
  final session = ref.read(sessionProvider);
  if (id is! String || session is! SessionSignedIn) return;
  if (!RegExp(r'^n_[A-Za-z0-9_-]{6,120}$').hasMatch(id)) return;
  unawaited(_markRead(ref, session.user.uid, [id]));
}

/// Pushes with nothing else to open (the delivery check, future suggestion kinds) open EN06.
bool pushOpensInbox(Map<String, dynamic> data) =>
    data['inboxId'] is String && !_pushKindsWithScreens.contains(data['kind']);

const _pushKindsWithScreens = {
  'reminderRule',
  'vaccine',
  'spending',
  'keepsakeVideo',
  'keepsakeVideoFailed',
  'memories',
  'shared',
  'album',
  'story',
  'message',
  'storage',
  'storageGranted',
};
