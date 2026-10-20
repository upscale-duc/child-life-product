import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../family/family_repository.dart' show familyMembersProvider;
import 'rhythm_labels.dart' show memberLabel;
import 'rhythm_access.dart';
import '../me/me_widgets.dart';
import '../reminders/device_identity.dart';
import '../reminders/reminder_notifications.dart';
import 'personalization_events.dart';
import 'personalization_v2_repository.dart';
import 'rhythm_repository.dart';
import 'rhythm_models.dart';
import 'rhythm_widgets.dart';
import '../today/today_for_baby.dart' show ForBabyCard;

PersonalDayKey? personalKey(BuildContext context, WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  return me == null || !familyCan(me, FamilyAction.historyRead)
      ? null
      : (
          babyId: me.babyId,
          uid: me.uid,
          locale: Localizations.localeOf(context).languageCode,
        );
}

String contextLabel(AppLocalizations l, String value) => switch (value) {
  'few_minutes' => l.pv2FewMinutes,
  'busy' => l.pv2Busy,
  'other_carer' => l.pv2OtherCarer,
  _ => l.pv2Usual,
};
String responseLabel(AppLocalizations l, String value) => switch (value) {
  'save' => l.pv2Save,
  'hide' => l.pv2Hide,
  'snooze' => l.pv2Snooze,
  'dislike' => l.pv2Dislike,
  'known' => l.pv2Known,
  'exclude' => l.pv2Exclude,
  'restore' => l.pv2Restore,
  'intend' => l.pv2Intend,
  'tried' => l.pv2Tried,
  'helpful' => l.pv2Helpful,
  _ => l.pv2Unsure,
};

Future<bool> mutateDay(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  Map<String, Object?> action,
) async {
  final l = AppLocalizations.of(context);
  try {
    await updatePersonalDay(ref, key, action);
    if (context.mounted) showClToast(context, message: l.pv2ChangeSaved);
    return true;
  } catch (error) {
    if (ref.context.mounted) ref.invalidate(personalDayProvider(key));
    final conflict =
        error is FirebaseFunctionsException &&
        error.code == 'failed-precondition';
    if (context.mounted) {
      showClToast(
        context,
        message: conflict ? l.pv2Conflict : l.pv2Unavailable,
      );
    }
    return false;
  }
}

/// Common per-viewer controls for cards from any module. Baby exclusions require a co-parent.
Future<void> dayCardControls(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  String contentId, {
  bool parent = false,
}) async {
  final l = AppLocalizations.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final value in [
            'save',
            'snooze',
            'hide',
            'dislike',
            'known',
            if (parent && contentId.startsWith('act_')) 'exclude',
            'restore',
          ])
            ListTile(
              title: Text(responseLabel(l, value)),
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    ),
  );
  if (choice != null && context.mounted) {
    final ok = await mutateDay(context, ref, key, {
      'kind': 'respond',
      'contentId': contentId,
      'value': choice,
    });
    if (ok) personalEvent(ref, 'feedCardAnswered', choice);
  }
}

class PersonalDayHome extends ConsumerWidget {
  const PersonalDayHome({this.primary, super.key});
  final ForBabyCard? primary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = personalKey(context, ref);
    if (key == null) return const SizedBox.shrink();
    final day = ref.watch(personalDayProvider(key)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final l = AppLocalizations.of(context);
    if (day == null || !day.current(now)) return const SizedBox.shrink();
    final candidate =
        day.health || day.work.isNotEmpty || day.activityIds.isEmpty
        ? null
        : ref
              .watch(rhythmContentProvider)
              .value
              ?.activity(day.activityIds.first);
    final activity =
        candidate?.status == ContentStatus.published &&
            day.data['contentVersion'] ==
                ref.watch(rhythmContentProvider).value?.version
        ? candidate
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: RhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.pv2Title, style: context.cl.text.bodyStrong),
            if (day.writable)
              Wrap(
                spacing: 6,
                children: [
                  for (final value in [
                    'usual',
                    'few_minutes',
                    'busy',
                    'other_carer',
                  ])
                    ChoiceChip(
                      label: Text(contextLabel(l, value)),
                      selected: day.context == value,
                      onSelected: (_) => mutateDay(context, ref, key, {
                        'kind': 'context',
                        'value': value,
                      }),
                    ),
                ],
              ),
            if (primary != null) ...[
              const SizedBox(height: 8),
              PersonalImpression(
                identity:
                    '${key.uid}:${key.babyId}:${day.data['today']}:${primary!.id}',
                reason: primary!.id.startsWith('act_')
                    ? 'INTEREST'
                    : switch (primary!.priority) {
                        0 => 'health',
                        1 => 'reminder',
                        2 => 'module',
                        3 => 'rhythm',
                        4 => 'milestone',
                        5 => 'moments',
                        _ => 'AGE_CONTENT',
                      },
                child: Text(primary!.title, style: context.cl.text.bodyStrong),
              ),
              ClButton(
                label: primary!.action,
                expand: true,
                onPressed: () => primary!.onOpen(context),
              ),
              if (day.writable && !primary!.essential)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: l.pv2Save,
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () => mutateDay(context, ref, key, {
                        'kind': 'respond',
                        'contentId': primary!.id,
                        'value': 'save',
                      }),
                    ),
                    IconButton(
                      tooltip: l.pv2Controls,
                      icon: const Icon(Icons.close),
                      onPressed: () => dayCardControls(
                        context,
                        ref,
                        key,
                        primary!.id,
                        parent: day.parent,
                      ),
                    ),
                  ],
                ),
            ] else if (activity != null) ...[
              const SizedBox(height: 8),
              PersonalImpression(
                identity:
                    '${key.uid}:${key.babyId}:${day.data['today']}:${activity.id}',
                child: Text(
                  activity.title.of(Localizations.localeOf(context)),
                  style: context.cl.text.bodyStrong,
                ),
              ),
              Text('${activity.durationMin} ${l.pv2Minutes}'),
            ],
            const SizedBox(height: 8),
            ClButton(
              label: l.pv2Open,
              expand: true,
              style: ClButtonStyle.secondary,
              onPressed: () => context.push(Routes.personalDay),
            ),
          ],
        ),
      ),
    );
  }
}

/// B2 extends the existing Sunday summary; it never introduces another weekly notification.
class PersonalWeekBlock extends ConsumerWidget {
  const PersonalWeekBlock({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = personalKey(context, ref);
    if (key == null) return const SizedBox.shrink();
    final day = ref.watch(personalDayProvider(key)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    if (day == null || !day.current(now)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final content = ref.watch(rhythmContentProvider).value;
    final age = content?.ageCards
        .where((a) => a.id == day.data['ageCardId'])
        .firstOrNull;
    final weekly = dayMap(day.data['weekly']);
    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pv2Weekly, style: context.cl.text.bodyStrong),
          if (age != null) Text(age.body.of(locale)),
          Text(
            '${weekly['tried'] ?? 0} ${l.pv2WeekTried} · ${weekly['helpful'] ?? 0} ${l.pv2WeekHelpful}',
          ),
          Text(l.pv2WeekHint),
          if (!day.health)
            if (day.activityIds.firstOrNull case final id?)
              if (content?.activity(id) case final a?) Text(a.title.of(locale)),
          if (age != null)
            for (final line in age.watchFor.of(locale)) Text(line),
          ClButton(
            label: l.pv2Open,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => context.push(Routes.personalDay),
          ),
        ],
      ),
    );
  }
}

class PersonalizationDayScreen extends ConsumerStatefulWidget {
  const PersonalizationDayScreen({super.key});
  @override
  ConsumerState<PersonalizationDayScreen> createState() =>
      _PersonalizationDayScreenState();
}

class _PersonalizationDayScreenState
    extends ConsumerState<PersonalizationDayScreen> {
  bool _busy = false;
  Future<bool> _write(PersonalDayKey key, Map<String, Object?> action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    final ok = await mutateDay(context, ref, key, action);
    if (mounted) setState(() => _busy = false);
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = personalKey(context, ref);
    if (key == null) return MePage(title: l.pv2Title, children: const []);
    final state = ref.watch(personalDayProvider(key));
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final day = state.value;
    if (day == null || !day.current(now)) {
      return MePage(
        title: l.pv2Title,
        children: [
          Text(state.isLoading ? l.pv2Loading : l.pv2Unavailable),
          ClButton(
            label: l.pv2Retry,
            onPressed: () => ref.invalidate(personalDayProvider(key)),
          ),
        ],
      );
    }
    final content = ref.watch(rhythmContentProvider).value;
    final locale = Localizations.localeOf(context);
    final responses = day.responses;
    final members =
        ref.watch(familyMembersProvider(key.babyId)).value ?? const [];
    String when(Object? value) {
      final at = DateTime.tryParse('$value');
      return at == null
          ? ''
          : DateFormat('dd/MM HH:mm', locale.languageCode).format(
              inBabyZone(day.data['zone'] as String? ?? 'Asia/Ho_Chi_Minh', at),
            );
    }

    final device = ref.watch(deviceIdentityProvider).value;
    final delivery = dayMap(day.data['delivery']);
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(label, style: context.cl.text.headline),
    );
    Widget button(String label, VoidCallback action) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ClButton(
        label: label,
        expand: true,
        style: ClButtonStyle.secondary,
        onPressed: _busy ? null : action,
      ),
    );
    return MePage(
      title: l.pv2Title,
      children: [
        if (_busy) const LinearProgressIndicator(),
        button(l.pv2Refresh, () => ref.invalidate(personalDayProvider(key))),
        if (day.writable) ...[
          heading(l.pv2Context),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in [
                'usual',
                'few_minutes',
                'busy',
                'other_carer',
              ])
                ChoiceChip(
                  label: Text(contextLabel(l, value)),
                  selected: day.context == value,
                  onSelected: _busy
                      ? null
                      : (_) => _write(key, {'kind': 'context', 'value': value}),
                ),
            ],
          ),
          Text(l.pv2Temporary, style: context.cl.text.caption),
          heading(l.pv2Focus),
          Wrap(
            spacing: 6,
            children: [
              for (final pair in [
                (null, l.pv2NoFocus),
                ('play', l.pv2Play),
                ('handover', l.pv2Handover),
                ('routine', l.pv2Routine),
              ])
                ChoiceChip(
                  label: Text(pair.$2),
                  selected: day.data['focus'] == pair.$1,
                  onSelected: _busy
                      ? null
                      : (_) => _write(key, {'kind': 'focus', 'value': pair.$1}),
                ),
            ],
          ),
          if (day.parent)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.pv2Unusual),
              subtitle: Text(l.pv2UnusualHint),
              value: day.data['unusual'] == true,
              onChanged: _busy
                  ? null
                  : (value) =>
                        _write(key, {'kind': 'routine', 'unusual': value}),
            ),
        ],
        if (day.health)
          button(l.rhHealthCardAction, () => context.push(Routes.rhythmHealth)),
        if (!day.health) ...[
          heading(l.pv2Next),
          for (final id in day.activityIds.where(
            (_) => day.data['contentVersion'] == content?.version,
          ))
            if (content?.activity(id) case final activity?
                when activity.status == ContentStatus.published)
              PersonalImpression(
                identity: '${key.uid}:${key.babyId}:${day.data['today']}:$id',
                reason: day.data['reason'] == 'SELF_REPORTED_NEED'
                    ? 'SELF_REPORTED_NEED'
                    : 'INTEREST',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RhCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          activity.title.of(locale),
                          style: context.cl.text.bodyStrong,
                        ),
                        Text('${activity.durationMin} ${l.pv2Minutes}'),
                        Text(switch (day.data['reason']) {
                          'SELF_REPORTED_NEED' => l.pv2BecauseNeed,
                          'WEEKLY_FOCUS' => l.pv2BecauseFocus,
                          _ => l.pv2BecauseInterest,
                        }),
                        button(
                          l.pv2OpenActivity,
                          () => context.push('${Routes.rhythmActivity}/$id'),
                        ),
                        if (day.writable) ...[
                          button(
                            l.pv2Controls,
                            () => dayCardControls(
                              context,
                              ref,
                              key,
                              id,
                              parent: day.parent,
                            ),
                          ),
                          for (final value in [
                            if (dayMap(responses[id])['value'] != 'intend')
                              'intend',
                            if (dayMap(responses[id])['triedAt'] == null)
                              'tried',
                            if (dayMap(responses[id])['triedAt'] != null) ...[
                              'helpful',
                              'unsure',
                            ],
                          ])
                            button(responseLabel(l, value), () async {
                              final ok = await _write(key, {
                                'kind': 'respond',
                                'contentId': id,
                                'value': value,
                              });
                              if (mounted && ok) {
                                personalEvent(
                                  ref,
                                  'personalizationOutcome',
                                  value,
                                );
                              }
                            }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          if (day.activityIds.isEmpty && day.data['ageCardId'] != null)
            button(
              l.rhWeekTitle,
              () =>
                  context.push('${Routes.rhythmAge}/${day.data['ageCardId']}'),
            ),
          Text(l.pv2NoAnswer, style: context.cl.text.caption),
        ],
        heading(l.pv2Patterns),
        if (dayMap(day.data['sleep']) case final sleep
            when sleep['baseline'] is num && sleep['recent'] is num)
          Text(
            '${l.pv2SleepRecent}: ${(sleep['recent'] as num).round()} ${l.pv2Minutes} · ${l.pv2SleepBaseline}: ${(sleep['baseline'] as num).round()} ${l.pv2Minutes}',
          ),
        Text(l.pv2PatternHint),
        if (day.patterns.isEmpty) Text(l.pv2Insufficient),
        for (final pattern in day.patterns)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              pattern['kind'] == 'feed_interval'
                  ? l.pv2FeedPattern
                  : l.pv2SleepPattern,
            ),
            subtitle: Text(
              '${pattern['lowMinutes']}–${pattern['highMinutes']} ${l.pv2Minutes} · ${pattern['samples']} ${l.pv2Samples} · ${pattern['days']} ${l.pv2Days}\n${l.pv2Updated}: ${when(pattern['asOf'])}',
            ),
            trailing: day.parent && pattern['kind'] == 'feed_interval'
                ? IconButton(
                    tooltip: l.pv2PatternReminder,
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      final midpoint =
                          ((pattern['lowMinutes'] as num) +
                              (pattern['highMinutes'] as num)) /
                          2;
                      final interval = ((midpoint / 15).round() * 15).clamp(
                        30,
                        720,
                      );
                      context.push('${Routes.ruleNew}?interval=$interval');
                    },
                  )
                : null,
          ),
        heading(l.pv2Work),
        Text(l.pv2WorkHint),
        for (final record in dayRows(day.data['lastRecords']))
          Text(
            '${careTypeLabel(l, CareType.values.where((t) => t.name == record['type']).firstOrNull ?? CareType.bottle)} · ${when(record['at'])}${record['amountMl'] is num ? ' · ${l.amountMl((record['amountMl'] as num).round())}' : ''}',
          ),
        if (day.work.isEmpty) Text(l.pv2NoWork),
        for (final work in day.work)
          RhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${work['title']}', style: context.cl.text.bodyStrong),
                Text(
                  '${when(work['dueAt'])} · ${work['state'] == 'accepted' ? l.pv2Accepted : l.pv2Unclaimed}',
                ),
                if (work['actorUid'] case final String uid)
                  Text(
                    memberLabel(
                      l,
                      members.where((m) => m.uid == uid).firstOrNull,
                      myUid: key.uid,
                      uid: uid,
                    ),
                  ),
                if (work['canAct'] == true) ...[
                  if (work['state'] == 'unclaimed')
                    button(
                      l.pv2Accept,
                      () => _write(key, {
                        'kind': 'work',
                        'reminderId': work['id'],
                        'transition': 'accept',
                        'revision': work['revision'],
                      }),
                    ),
                  if (work['state'] == 'accepted' &&
                      (work['actorUid'] == key.uid || day.parent)) ...[
                    button(
                      l.pv2Complete,
                      () => _write(key, {
                        'kind': 'work',
                        'reminderId': work['id'],
                        'transition': 'complete',
                        'revision': work['revision'],
                      }),
                    ),
                    button(
                      l.pv2Release,
                      () => _write(key, {
                        'kind': 'work',
                        'reminderId': work['id'],
                        'transition': 'release',
                        'revision': work['revision'],
                      }),
                    ),
                  ],
                ],
              ],
            ),
          ),
        if (day.writable)
          button(
            l.pv2Acknowledge,
            () => _write(key, {
              'kind': 'acknowledge',
              'version': day.data['handoverVersion'],
            }),
          ),
        if (day.data['acknowledgedAt'] != null)
          Text('${l.pv2Acknowledged} ${when(day.data['acknowledgedAt'])}'),
        if (day.data['handoverChanged'] == true)
          Text(l.pv2HandoverChanged, style: context.cl.text.bodyStrong),
        heading(l.pv2Notes),
        Text(l.pv2NoteHint),
        for (final note in [...day.notes, ...dayRows(day.data['expiredNotes'])])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${note['text']}'),
            subtitle: Text(
              '${note['scope'] == 'person' ? l.pv2Personal : l.pv2Shared}\n${l.pv2Updated}: ${when(note['confirmedAt'])}${dayRows(day.data['expiredNotes']).any((n) => n['id'] == note['id']) ? '\n${l.pv2ExpiredNote}' : ''}',
            ),
            trailing:
                day.writable &&
                    (note['authorUid'] == key.uid ||
                        day.parent && note['scope'] == 'baby')
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showNotebookEditor(
                          context,
                          ref,
                          key,
                          day.parent,
                          note: note,
                        );
                      } else {
                        _write(key, {
                          'kind': 'delete_note',
                          'id': note['id'],
                          'revision': note['revision'],
                        });
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(l.pv2Edit)),
                      PopupMenuItem(value: 'delete', child: Text(l.pv2Delete)),
                    ],
                  )
                : null,
          ),
        if (day.writable)
          button(
            l.pv2AddNote,
            () => showNotebookEditor(context, ref, key, day.parent),
          ),
        heading(l.pv2Weekly),
        Text(
          '${dayMap(day.data['weekly'])['tried'] ?? 0} ${l.pv2WeekTried} · ${dayMap(day.data['weekly'])['helpful'] ?? 0} ${l.pv2WeekHelpful}',
        ),
        Text(l.pv2WeekHint),
        heading(l.pv2History),
        if (day.parent)
          for (final exclusion in dayRows(day.data['sharedExclusions']))
            ListTile(
              title: Text(
                content?.activity('${exclusion['id']}')?.title.of(locale) ??
                    l.rhUnknownActivity,
              ),
              subtitle: Text(l.pv2Exclude),
              trailing: TextButton(
                onPressed: _busy
                    ? null
                    : () => _write(key, {
                        'kind': 'respond',
                        'contentId': exclusion['id'],
                        'value': 'restore',
                        'scope': 'baby',
                      }),
                child: Text(l.pv2Restore),
              ),
            ),
        for (final entry in responses.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              content?.activity(entry.key)?.title.of(locale) ?? l.pv2Saved,
            ),
            subtitle: Text(responseLabel(l, '${dayMap(entry.value)['value']}')),
            trailing: day.writable
                ? PopupMenuButton<String>(
                    tooltip: l.pv2Controls,
                    onSelected: (value) async {
                      final ok = await _write(key, {
                        'kind': 'respond',
                        'contentId': entry.key,
                        'value': value,
                      });
                      if (mounted &&
                          ok &&
                          [
                            'intend',
                            'tried',
                            'helpful',
                            'unsure',
                          ].contains(value)) {
                        personalEvent(ref, 'personalizationOutcome', value);
                      }
                    },
                    itemBuilder: (_) => [
                      for (final value in [
                        if (dayMap(entry.value)['intendedAt'] != null &&
                            dayMap(entry.value)['triedAt'] == null)
                          'tried',
                        if (dayMap(entry.value)['triedAt'] != null) ...[
                          'helpful',
                          'unsure',
                        ],
                        'restore',
                      ])
                        PopupMenuItem(
                          value: value,
                          child: Text(responseLabel(l, value)),
                        ),
                    ],
                  )
                : null,
          ),
        if (day.writable)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.pv2Digest),
            subtitle: Text(l.pv2DigestHint),
            value:
                delivery['enabled'] == true &&
                delivery['deviceId'] == device?.id,
            onChanged: _busy || device == null
                ? null
                : (enabled) async {
                    if (enabled &&
                        !await ref
                            .read(reminderNotificationsProvider)
                            .request()) {
                      return;
                    }
                    if (mounted) {
                      await _write(key, {
                        'kind': 'digest',
                        'enabled': enabled,
                        'deviceId': device.id,
                      });
                    }
                  },
          ),
        const SizedBox(height: 24),
      ].map((child) => Material(type: MaterialType.transparency, child: child)).toList(),
    );
  }
}

Future<void> showNotebookEditor(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  bool parent, {
  Map<String, dynamic>? note,
}) async {
  final action = await showModalBottomSheet<Map<String, Object?>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NotebookEditor(
      parent: parent,
      note: note,
      activities: ref.read(rhythmContentProvider).value?.activities ?? const [],
    ),
  );
  if (action != null && context.mounted) {
    await mutateDay(context, ref, key, action);
  }
}

class _NotebookEditor extends StatefulWidget {
  const _NotebookEditor({
    required this.parent,
    this.note,
    this.activities = const [],
  });
  final List<Activity> activities;
  final bool parent;
  final Map<String, dynamic>? note;
  @override
  State<_NotebookEditor> createState() => _NotebookEditorState();
}

class _NotebookEditorState extends State<_NotebookEditor> {
  late final _text = TextEditingController(
    text: widget.note?['text'] as String? ?? '',
  );
  late String _category = widget.note?['category'] as String? ?? 'other';
  late bool _shared = widget.note?['scope'] != 'person';
  int? _days = 7;
  late String? _avoidActivityId = widget.note?['avoidActivityId'] as String?;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.pv2Notes, style: context.cl.text.headline),
              TextField(
                controller: _text,
                maxLength: 200,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l.pv2NoteText),
                onChanged: (_) => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l.pv2Category),
                items: [
                  for (final pair in [
                    ('sleep', l.pv2Sleep),
                    ('soothing', l.pv2Soothing),
                    ('feeding', l.pv2Feeding),
                    ('avoid', l.pv2Avoid),
                    ('routine', l.pv2Routine),
                    ('carer', l.pv2Carer),
                    ('other', l.pv2Other),
                  ])
                    DropdownMenuItem(value: pair.$1, child: Text(pair.$2)),
                ],
                onChanged: (value) => setState(() {
                  _category = value ?? 'other';
                  if (!widget.parent && _category == 'avoid') _shared = false;
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.pv2Shared),
                value: _shared,
                onChanged: !widget.parent && _category == 'avoid'
                    ? null
                    : (value) => setState(() => _shared = value),
              ),
              if (_category == 'avoid' && _shared && widget.parent)
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.activities.any((a) => a.id == _avoidActivityId)
                      ? _avoidActivityId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.pv2AvoidActivity),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l.pv2NoFocus),
                    ),
                    for (final a in widget.activities.where(
                      (a) => a.status == ContentStatus.published,
                    ))
                      DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          a.title.of(Localizations.localeOf(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _avoidActivityId = value),
                ),
              Text(l.pv2Expiry),
              Wrap(
                spacing: 6,
                children: [
                  for (final pair in [
                    (1, l.pv2OneDay),
                    (7, l.pv2SevenDays),
                    (30, l.pv2ThirtyDays),
                    (null, l.pv2NoExpiry),
                  ])
                    ChoiceChip(
                      label: Text(pair.$2),
                      selected: _days == pair.$1,
                      onSelected: (_) => setState(() => _days = pair.$1),
                    ),
                ],
              ),
              ClButton(
                label: l.pv2ConfirmNote,
                expand: true,
                onPressed:
                    _text.text.trim().isEmpty ||
                        !widget.parent && _shared && _category == 'avoid'
                    ? null
                    : () => Navigator.of(context).pop({
                        'kind': 'note',
                        'id':
                            widget.note?['id'] ??
                            'nb_${const Uuid().v4().replaceAll('-', '')}',
                        'revision': widget.note?['revision'] ?? 0,
                        'text': _text.text.trim(),
                        'category': _category,
                        'scope': _shared ? 'baby' : 'person',
                        'days': _days,
                        'avoidActivityId': _category == 'avoid' && _shared
                            ? _avoidActivityId
                            : null,
                        'source': widget.note?['source'] ?? 'app',
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
