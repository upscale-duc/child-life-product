import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart' show openNotificationSettings;
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../me/me_widgets.dart';
import '../reminders/reminder_notifications.dart';
import '../rhythm/rhythm_repository.dart' show userPreferencesProvider;
import 'notification_models.dart';
import 'notification_repository.dart';

/// EN07 Cài đặt thông báo (560:2981, D-076 #2): the OS permission on top, then which pushes this
/// person gets, grouped as drawn (Nhắc việc bạn đặt · Gợi ý cho bé · Kỷ niệm & gia đình), and
/// the suggestion time and quiet hours, which live with EN02 (`settings/personalization`) and
/// open there. A switch off means no push and no inbox row (server `notifyUsers`). Rows a role
/// never gets are left out (the union of this person's roles across babies). Not drawn here:
/// "Vitamin & vi chất" (no such reminder yet) and "Người nhận" (chosen per reminder); "Chi tiêu"
/// is an engineering addition for the spending pushes.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from system settings: the permission may have changed.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(osNotificationsEnabledProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _system(bool enabled) async {
    if (!enabled) {
      final granted = await ref.read(reminderNotificationsProvider).request();
      ref.invalidate(osNotificationsEnabledProvider);
      if (granted) return;
    }
    // Turning off, or a refusal the app may not ask again: only system settings can.
    await openNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return ColoredBox(color: cl.colors.cloud);
    final uid = session.user.uid;
    final roles = {for (final m in session.active) m.role};
    final parent = roles.contains(MemberRole.coParent);
    final cares = parent || roles.contains(MemberRole.caregiver);
    final sees = parent || roles.contains(MemberRole.relative);
    final settings =
        ref.watch(notificationSettingsProvider(uid)).value ??
        NotificationSettings.defaults;
    final prefs = ref.watch(userPreferencesProvider(uid)).value;
    final system = ref.watch(osNotificationsEnabledProvider).value;

    Future<void> save(String key, bool value) async {
      final toaster = ClToaster.of(context);
      try {
        await ref
            .read(notificationRepositoryProvider)
            .saveSettings(uid, settings.set(key, value));
      } on Object {
        toaster.show(message: l10n.ntSaveFailed, error: true);
      }
    }

    Widget toggle(String key, String title, String hint) => MeRow(
      key: Key('nt-$key'),
      title: title,
      subtitle: hint,
      trailing: ClToggle(
        value: settings[key],
        semanticLabel: title,
        onChanged: (v) => unawaited(save(key, v)),
      ),
    );

    final quiet = prefs == null
        ? l10n.ntQuietRange('22:00', '06:00')
        : prefs.quietFrom != null && prefs.quietTo != null
        ? l10n.ntQuietRange(prefs.quietFrom!, prefs.quietTo!)
        : l10n.meOff;
    final digest = prefs?.digestTime;

    return MePage(
      title: l10n.meNotifications,
      children: [
        ClCardGroup(
          children: [
            MeRow(
              key: const Key('nt-system'),
              icon: ClIcons.alert,
              title: l10n.ntMaster,
              subtitle: system == false ? l10n.ntMasterOff : l10n.ntMasterOn,
              trailing: ClToggle(
                value: system ?? true,
                semanticLabel: l10n.ntMaster,
                onChanged: system == null
                    ? null
                    : (_) => unawaited(_system(system)),
              ),
            ),
          ],
        ),
        if (cares) ...[
          _Group(l10n.ntGroupReminders, hint: l10n.ntGroupRemindersHint),
          ClCardGroup(
            children: [
              toggle('reminders', l10n.ntCare, l10n.ntCareHint),
              toggle('vaccines', l10n.ntVaccines, l10n.ntVaccinesHint),
              if (parent)
                toggle('spending', l10n.ntSpending, l10n.ntSpendingHint),
            ],
          ),
        ],
        _Group(l10n.ntGroupBaby, hint: l10n.ntGroupBabyHint),
        ClCardGroup(
          children: [
            toggle('rhythm', l10n.ntRhythm, l10n.ntRhythmHint),
            toggle('stages', l10n.ntStages, l10n.ntStagesHint),
            toggle('milestones', l10n.ntMilestones, l10n.ntMilestonesHint),
            toggle('articles', l10n.ntArticles, l10n.ntArticlesHint),
            toggle('weeklySummary', l10n.ntWeekly, l10n.ntWeeklyHint),
          ],
        ),
        _Group(l10n.ntGroupFamily),
        ClCardGroup(
          children: [
            if (sees) toggle('memories', l10n.ntMemories, l10n.ntMemoriesHint),
            if (parent) ...[
              toggle('photoSuggestions', l10n.ntPhotos, l10n.ntPhotosHint),
              toggle('messages', l10n.ntMessages, l10n.ntMessagesHint),
            ],
            if (sees)
              toggle('keepsakePrompts', l10n.ntKeepsakes, l10n.ntKeepsakesHint),
            toggle(
              'familyActivity',
              l10n.ntFamilyActivity,
              l10n.ntFamilyActivityHint,
            ),
            if (parent) toggle('storage', l10n.ntStorage, l10n.ntStorageHint),
          ],
        ),
        _Group(l10n.ntGroupTiming),
        ClCardGroup(
          children: [
            MeRow(
              key: const Key('nt-digest'),
              title: l10n.ntDigest,
              subtitle: digest == null
                  ? l10n.meOff
                  : l10n.ntDigestDaily(digest),
              onTap: () => context.push(Routes.rhythmDigest),
            ),
            MeRow(
              key: const Key('nt-quiet'),
              title: l10n.ntQuiet,
              subtitle: quiet,
              onTap: () => context.push(Routes.rhythmDigest),
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

/// EN07 group header: muted caps, an optional helper line under it.
class _Group extends StatelessWidget {
  const _Group(this.title, {this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s1,
        ClSpace.s6,
        ClSpace.s1,
        ClSpace.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: cl.text.label.copyWith(
                color: cl.colors.inkMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
        ],
      ),
    );
  }
}
