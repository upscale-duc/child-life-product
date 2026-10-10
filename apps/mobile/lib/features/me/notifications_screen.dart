import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_widgets.dart';

/// "Thông báo" (13a "Thông báo · Bật"; screen not drawn, G-056): which pushes this account
/// receives. Kinds a role never gets are not shown (messages and storage are for parents).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final prefs =
        ref.watch(notificationPrefsProvider(me.uid)).value ??
        const NotificationPrefs();
    final parent = me.role == MemberRole.coParent;
    Future<void> save(NotificationPrefs next) async {
      try {
        await ref.read(meRepositoryProvider).savePrefs(me.uid, next);
      } on Object {
        if (context.mounted) {
          showClToast(context, message: l10n.toastSaveFailed);
        }
      }
    }

    Widget toggle(
      String title,
      String hint,
      bool value,
      NotificationPrefs Function(bool) next,
    ) => MeRow(
      title: title,
      subtitle: hint,
      trailing: ClToggle(
        value: value,
        semanticLabel: title,
        onChanged: (v) => save(next(v)),
      ),
    );

    return MePage(
      title: l10n.meNotifications,
      children: [
        ClCardGroup(
          children: [
            if (me.role != MemberRole.caregiver)
              toggle(
                l10n.ntMemories,
                l10n.ntMemoriesHint,
                prefs.memories,
                (v) => prefs.copyWith(memories: v),
              ),
            if (parent)
              toggle(
                l10n.ntMessages,
                l10n.ntMessagesHint,
                prefs.messages,
                (v) => prefs.copyWith(messages: v),
              ),
            if (me.role != MemberRole.relative)
              toggle(
                l10n.ntReminders,
                l10n.ntRemindersHint,
                prefs.reminders,
                (v) => prefs.copyWith(reminders: v),
              ),
            if (parent)
              toggle(
                l10n.ntStorage,
                l10n.ntStorageHint,
                prefs.storage,
                (v) => prefs.copyWith(storage: v),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.ntFootnote,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}
