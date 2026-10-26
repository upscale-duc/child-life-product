import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart' show functionsProvider;
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart' show openNotificationSettings;
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../engagement/engagement_local.dart' show engagementRevisionProvider;
import '../engagement/engagement_repository.dart' show engagementProvider;
import '../engagement/engagement_widgets.dart' show engagementTitle;
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

    Widget toggle(String key, String title, [String? hint]) => MeRow(
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
        // D-098: switched off in system settings, nothing here reaches the phone; say so first.
        if (system == false) ...[
          MeNotice(
            key: const Key('nt-off'),
            tone: MeTone.warn,
            icon: ClIcons.alert,
            title: l10n.ntOffTitle,
            body: l10n.ntOffBody,
            onTap: () => unawaited(_system(false)),
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        ClCardGroup(
          children: [
            MeRow(
              key: const Key('nt-system'),
              // A bell, not the warning mark: this row reads "on" most of the time.
              icon: ClIcons.bell,
              title: l10n.ntMaster,
              // The switch shows "on"; only "off" needs saying (owner, 2026-10-26: no labels
              // that add nothing).
              subtitle: system == false ? l10n.ntMasterOff : null,
              trailing: ClToggle(
                value: system ?? true,
                semanticLabel: l10n.ntMaster,
                onChanged: system == null
                    ? null
                    : (_) => unawaited(_system(system)),
              ),
            ),
            // D-094: a parent of two tells the babies apart; off says "bé" on the lock screen.
            toggle('babyName', l10n.ntBabyName, l10n.ntBabyNameHint),
          ],
        ),
        // What the person set comes first; the app's own suggestions follow the groups of
        // pushes they already know (owner, 2026-10-26).
        if (cares) ...[
          _Group(l10n.ntGroupReminders, hint: l10n.ntGroupRemindersHint),
          ClCardGroup(
            children: [
              toggle('reminders', l10n.ntCare),
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
            // D-092: everyone who sees family content, like familyActivity.
            toggle(
              'familyMembers',
              l10n.ntFamilyMembers,
              l10n.ntFamilyMembersHint,
            ),
            if (parent) toggle('storage', l10n.ntStorage, l10n.ntStorageHint),
            // D-093: whoever reads care can be sent a handover.
            if (cares)
              toggle('handovers', l10n.ntHandovers, l10n.ntHandoversHint),
          ],
        ),
        const _SmartSuggestions(),
        _Group(l10n.ntGroupTiming),
        ClCardGroup(
          children: [
            // The time also shows, and opens, on "Gợi ý mỗi ngày" above (D-099); twice in a row
            // was one label too many (owner, 2026-10-26).
            if (ref.watch(engagementProvider).value?['enabled'] != true)
              MeRow(
                key: const Key('nt-digest'),
                title: l10n.ntDigest,
                subtitle: l10n.ntDigestDaily(digest ?? '20:30'),
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

/// Gợi ý thông minh (ENG-01…06) in this screen's own rows. D-098: on until the person turns it
/// off. A switch moves at once and stays (the reload of `getEngagement` is paced for background
/// changes and would hold the old value for up to a minute); a failed save puts it back. The
/// kinds follow the main switch: off, they are greyed out.
class _SmartSuggestions extends ConsumerStatefulWidget {
  const _SmartSuggestions();

  @override
  ConsumerState<_SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends ConsumerState<_SmartSuggestions> {
  static const _kinds = ['ENG-01', 'ENG-02', 'ENG-03', 'ENG-05', 'ENG-06'];
  bool? _consent;
  Map<String, bool>? _chosen;

  Future<void> _call(Map<String, Object?> change) => ref
      .read(functionsProvider)
      .httpsCallable('setEngagementPreferences')
      .call<Object?>(change);

  Future<void> _save(bool consent, Map<String, bool> kinds) async {
    final toaster = ClToaster.of(context);
    final l10n = AppLocalizations.of(context);
    final before = (_consent, _chosen);
    setState(() {
      _consent = consent;
      _chosen = kinds;
    });
    try {
      await _call({
        'preferences': {'consent': consent, 'kinds': kinds},
      });
      ref.read(engagementRevisionProvider.notifier).refresh();
    } on Object {
      if (!mounted) return;
      setState(() {
        _consent = before.$1;
        _chosen = before.$2;
      });
      toaster.show(message: l10n.ntSaveFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(engagementProvider).value;
    final session = ref.watch(sessionProvider);
    // The server's default slot until the person picks one (D-099).
    final digestTime =
        (session is SessionSignedIn
            ? ref
                  .watch(userPreferencesProvider(session.user.uid))
                  .value
                  ?.digestTime
            : null) ??
        '20:30';
    if (data?['enabled'] != true) return const SizedBox.shrink();
    final fatigue = Map<String, dynamic>.from(
      data?['fatigue'] as Map? ?? const {},
    );
    final prefs = Map<String, dynamic>.from(
      data?['preferences'] as Map? ?? const {},
    );
    final stored = Map<String, dynamic>.from(
      prefs['kinds'] as Map? ?? const {},
    );
    final consent = _consent ?? prefs['consent'] != false;
    final kinds = {
      for (final k in _kinds) k: _chosen?[k] ?? stored[k] != false,
    };
    final paused = fatigue['paused'] == true;
    final cooling =
        (fatigue['pausedUntil'] as num? ?? 0) >
        DateTime.now().millisecondsSinceEpoch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Caps like the other group headers (the term itself stays "Gợi ý thông minh").
        _Group(l10n.engTitle.toUpperCase(), hint: l10n.engSettingsHint),
        if (paused) ...[
          MeNotice(title: l10n.engPaused),
          const SizedBox(height: ClSpace.s2),
        ],
        ClCardGroup(
          children: [
            MeRow(
              key: const Key('eng-consent'),
              title: l10n.engConsent,
              trailing: ClToggle(
                value: consent,
                semanticLabel: l10n.engConsent,
                onChanged: (v) => unawaited(_save(v, kinds)),
              ),
            ),
            for (final k in _kinds)
              MeRow(
                key: Key('eng-$k'),
                title: engagementTitle(l10n, k),
                // D-099: the daily suggestion says when it comes; tapping the row picks the time.
                subtitle: k == 'ENG-06' ? l10n.ntDigestDaily(digestTime) : null,
                onTap: k == 'ENG-06'
                    ? () => context.push(Routes.rhythmDigest)
                    : null,
                trailing: ClToggle(
                  value: consent && kinds[k]!,
                  semanticLabel: engagementTitle(l10n, k),
                  onChanged: consent
                      ? (v) => unawaited(_save(true, {...kinds, k: v}))
                      : null,
                ),
              ),
          ],
        ),
        // Only while paused and past the 14-day cool-down.
        if (paused && !cooling)
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: l10n.engResume,
              style: ClButtonStyle.plain,
              onPressed: () async {
                final toaster = ClToaster.of(context);
                try {
                  await _call({'resume': true});
                  ref.read(engagementRevisionProvider.notifier).refresh();
                } on Object {
                  toaster.show(message: l10n.ntSaveFailed, error: true);
                }
              },
            ),
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
