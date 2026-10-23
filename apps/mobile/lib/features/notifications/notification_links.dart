import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import 'notification_destinations.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

/// Where an inbox row (EN06) goes (D-076 #2, P-174): the same resolver a push uses. The row is
/// read first; the toast (fallback or gone) comes from [openNotification].
Future<NotificationOpenOutcome> openInboxItem(
  WidgetRef ref,
  InboxItem item, {
  ClToaster? toaster,
  AppLocalizations? l10n,
}) async {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return NotificationOpenOutcome.unavailable;
  if (item.unread) {
    unawaited(_markRead(ref, session.user.uid, [item.id]));
  }
  return openNotification(
    ref,
    item.target,
    surface: NotificationSurface.inbox,
    toaster: toaster,
    l10n: l10n,
  );
}

/// An inbox open in flight: a second tap (a double tap, or a tap while a Smart Engagement row
/// asks the server where it goes) is ignored instead of opening the screen twice.
var _opening = false;

/// [openInboxItem] from a row of the screen at [context].
Future<void> openInboxRow(
  BuildContext context,
  WidgetRef ref,
  InboxItem item,
) async {
  // Already opened something: the inbox is under it (its page may still be sliding in).
  if (_opening || ModalRoute.of(context)?.isCurrent == false) return;
  _opening = true;
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  try {
    await openInboxItem(ref, item, toaster: toaster, l10n: l10n);
  } on Object {
    // The row went away mid-open (the inbox closed): nothing to open on.
  } finally {
    _opening = false;
  }
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
