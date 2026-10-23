import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart' show careClockProvider;
import '../family/family_repository.dart' show familyMembersProvider;
import '../me/me_widgets.dart';
import 'personal_day_widgets.dart';
import 'personalization_events.dart';
import 'personalization_v2_repository.dart';
import 'personalization_v2_screen.dart';
import 'rhythm_labels.dart' show memberLabel;
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

typedef PersonalDayWrite = Future<bool> Function(Map<String, Object?> action);

/// A page of "Hôm nay của nhà mình" on today's snapshot: pull to refresh, one write at a time.
class PersonalDayPage extends ConsumerStatefulWidget {
  const PersonalDayPage({
    required this.title,
    required this.builder,
    this.onShown,
    super.key,
  });
  final String Function(AppLocalizations l) title;
  final List<Widget> Function(
    BuildContext context,
    WidgetRef ref,
    PersonalDayKey key,
    PersonalDay day,
    PersonalDayWrite write,
    bool busy,
  )
  builder;

  /// Once per baby and handover version, while the page is on top.
  final Future<void> Function(
    WidgetRef ref,
    PersonalDayKey key,
    PersonalDay day,
  )?
  onShown;

  @override
  ConsumerState<PersonalDayPage> createState() => _PersonalDayPageState();
}

class _PersonalDayPageState extends ConsumerState<PersonalDayPage> {
  bool _busy = false;
  final _shown = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = widget.title(l);
    final key = personalKey(context, ref);
    if (key == null) return MePage(title: title, children: const []);
    final state = ref.watch(personalDayProvider(key));
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final day = state.value;
    if (day == null || !day.current(now)) {
      return MePage(
        title: title,
        children: [
          Text(state.isLoading ? l.pv2Loading : l.pv2Unavailable),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l.pv2Retry,
            onPressed: () => ref.invalidate(personalDayProvider(key)),
          ),
        ],
      );
    }
    final onShown = widget.onShown;
    if (onShown != null &&
        _shown.add('${key.babyId}/${day.data['handoverVersion']}')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          unawaited(onShown(ref, key, day));
        }
      });
    }
    Future<bool> write(Map<String, Object?> action) async {
      if (_busy) return false;
      setState(() => _busy = true);
      final ok = await mutateDay(context, ref, key, action);
      if (mounted) setState(() => _busy = false);
      return ok;
    }

    return MePage(
      title: title,
      onRefresh: () async {
        try {
          final _ = await ref.refresh(personalDayProvider(key).future);
        } catch (_) {
          // The page shows the unavailable state itself.
        }
      },
      children:
          [
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                ...widget.builder(context, ref, key, day, write, _busy),
                const SizedBox(height: ClSpace.s6),
              ]
              .map(
                (child) =>
                    Material(type: MaterialType.transparency, child: child),
              )
              .toList(),
    );
  }
}

/// A section heading on these pages, with an optional muted line under it.
class PersonalHeading extends StatelessWidget {
  const PersonalHeading(this.text, {this.sub, super.key});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(text, style: cl.text.title2)),
          if (sub != null) ...[
            const SizedBox(height: ClSpace.s1),
            Text(
              sub!,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _muted(BuildContext context) =>
    context.cl.text.label.copyWith(color: context.cl.colors.inkMuted);

/// "Bàn giao cho người chăm": last records, open work and the acknowledgement.
class PersonalHandoverScreen extends StatelessWidget {
  const PersonalHandoverScreen({super.key});
  @override
  Widget build(BuildContext context) => PersonalDayPage(
    title: (l) => l.pv2Work,
    builder: (context, ref, key, day, write, busy) {
      final l = AppLocalizations.of(context);
      final cl = context.cl;
      final locale = Localizations.localeOf(context);
      final members =
          ref.watch(familyMembersProvider(key.babyId)).value ?? const [];
      final acknowledged =
          day.data['acknowledgedAt'] != null &&
          day.data['handoverChanged'] != true;
      String who(String uid) => memberLabel(
        l,
        members.where((m) => m.uid == uid).firstOrNull,
        myUid: key.uid,
        uid: uid,
      );
      return [
        Text(l.pv2WorkHint, style: _muted(context)),
        if (day.data['handoverChanged'] == true) ...[
          const SizedBox(height: ClSpace.s3),
          Text(l.pv2HandoverChanged, style: cl.text.bodyStrong),
        ],
        PersonalHeading(l.pv2LastRecords),
        if (dayRows(day.data['lastRecords']) case final records
            when records.isNotEmpty)
          ClCardGroup(
            children: [
              for (final record in records)
                MeRow(
                  title: careTypeLabel(
                    l,
                    CareType.values
                            .where((t) => t.name == record['type'])
                            .firstOrNull ??
                        CareType.bottle,
                  ),
                  value: [
                    dayStamp(day, record['at'], locale),
                    if (record['amountMl'] is num)
                      l.amountMl((record['amountMl'] as num).round()),
                  ].join(' · '),
                ),
            ],
          ),
        PersonalHeading(l.pv2Reminders),
        if (day.work.isEmpty) Text(l.pv2NoWork, style: _muted(context)),
        for (final work in day.work)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s3),
            child: RhCard(
              key: Key('personalWork:${work['id']}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${work['title']}',
                    style: cl.text.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s1),
                  Text(
                    dayStamp(day, work['dueAt'], locale),
                    style: _muted(context),
                  ),
                  if (work['state'] == 'accepted' && work['actorUid'] is String)
                    PersonalStatusLine([
                      l.pv2Accepted,
                      who(work['actorUid'] as String),
                    ])
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s2),
                      child: Text(l.pv2Unclaimed, style: _muted(context)),
                    ),
                  if (work['canAct'] == true) ...[
                    const SizedBox(height: ClSpace.s3),
                    Wrap(
                      spacing: ClSpace.s2,
                      runSpacing: ClSpace.s2,
                      children: [
                        if (work['state'] == 'unclaimed')
                          RhPillButton(
                            label: l.pv2Accept,
                            onTap: () => write({
                              'kind': 'work',
                              'reminderId': work['id'],
                              'transition': 'accept',
                              'revision': work['revision'],
                            }),
                          ),
                        if (work['state'] == 'accepted' &&
                            (work['actorUid'] == key.uid || day.parent)) ...[
                          RhPillButton(
                            label: l.pv2Complete,
                            onTap: () => write({
                              'kind': 'work',
                              'reminderId': work['id'],
                              'transition': 'complete',
                              'revision': work['revision'],
                            }),
                          ),
                          RhPillButton(
                            label: l.pv2Release,
                            primary: false,
                            onTap: () => write({
                              'kind': 'work',
                              'reminderId': work['id'],
                              'transition': 'release',
                              'revision': work['revision'],
                            }),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s4),
        if (acknowledged)
          PersonalStatusLine([
            l.pv2AcknowledgedShort,
            dayStamp(day, day.data['acknowledgedAt'], locale),
          ])
        else if (day.writable)
          ClButton(
            label: l.pv2Acknowledge,
            expand: true,
            onPressed: busy
                ? null
                : () => write({
                    'kind': 'acknowledge',
                    'version': day.data['handoverVersion'],
                  }),
          ),
      ];
    },
  );
}

/// "Nhịp riêng từ nhật ký", with the switch that hides it on an unusual day (co-parents).
class PersonalPatternsScreen extends StatelessWidget {
  const PersonalPatternsScreen({super.key});
  @override
  Widget build(BuildContext context) => PersonalDayPage(
    title: (l) => l.pv2Patterns,
    builder: (context, ref, key, day, write, busy) {
      final l = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context);
      return [
        Text(l.pv2PatternHint, style: _muted(context)),
        const SizedBox(height: ClSpace.s4),
        if (day.parent) ...[
          ClCardGroup(
            children: [
              MeRow(
                title: l.pv2Unusual,
                subtitle: l.pv2UnusualHint,
                trailing: ClToggle(
                  key: const Key('personalDayUnusual'),
                  semanticLabel: l.pv2Unusual,
                  value: day.data['unusual'] == true,
                  onChanged: busy
                      ? null
                      : (value) => write({'kind': 'routine', 'unusual': value}),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ],
        if (dayMap(day.data['sleep']) case final sleep
            when sleep['baseline'] is num && sleep['recent'] is num) ...[
          Text(
            '${l.pv2SleepRecent}: ${(sleep['recent'] as num).round()} ${l.pv2Minutes} · ${l.pv2SleepBaseline}: ${(sleep['baseline'] as num).round()} ${l.pv2Minutes}',
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        if (day.data['unusual'] == true)
          Text(l.pv2PatternsPaused, style: _muted(context))
        else if (day.patterns.isEmpty)
          Text(l.pv2Insufficient, style: _muted(context))
        else
          ClCardGroup(
            children: [
              for (final pattern in day.patterns)
                MeRow(
                  title:
                      '${patternLabel(l, pattern)}: ${pattern['lowMinutes']}–${pattern['highMinutes']} ${l.pv2Minutes}',
                  subtitle:
                      '${pattern['samples']} ${l.pv2Samples} · ${pattern['days']} ${l.pv2Days} · ${l.pv2Updated}: ${dayStamp(day, pattern['asOf'], locale)}',
                  trailing: day.parent && pattern['kind'] == 'feed_interval'
                      ? IconButton(
                          tooltip: l.pv2PatternReminder,
                          icon: ClIcon(
                            ClIcons.bell,
                            size: 20,
                            color: context.cl.colors.mintText,
                          ),
                          onPressed: () {
                            final midpoint =
                                ((pattern['lowMinutes'] as num) +
                                    (pattern['highMinutes'] as num)) /
                                2;
                            final interval = ((midpoint / 15).round() * 15)
                                .clamp(30, 720);
                            context.push(
                              '${Routes.ruleNew}?interval=$interval',
                            );
                          },
                        )
                      : null,
                ),
            ],
          ),
      ];
    },
  );
}

/// "Sổ tay nhà mình": confirmed notes, editable by their author (shared ones by co-parents).
class PersonalNotesScreen extends StatelessWidget {
  const PersonalNotesScreen({super.key});
  @override
  Widget build(BuildContext context) => PersonalDayPage(
    title: (l) => l.pv2Notes,
    builder: (context, ref, key, day, write, busy) {
      final l = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context);
      final expired = dayRows(day.data['expiredNotes']);
      return [
        Text(l.pv2NoteHint, style: _muted(context)),
        const SizedBox(height: ClSpace.s4),
        if (day.notes.isNotEmpty || expired.isNotEmpty)
          ClCardGroup(
            children: [
              for (final note in [...day.notes, ...expired])
                MeRow(
                  title: '${note['text']}',
                  subtitle: [
                    note['scope'] == 'person' ? l.pv2Personal : l.pv2Shared,
                    '${l.pv2Updated}: ${dayStamp(day, note['confirmedAt'], locale)}',
                    if (expired.any((n) => n['id'] == note['id']))
                      l.pv2ExpiredNote,
                  ].join('\n'),
                  trailing:
                      day.writable &&
                          (note['authorUid'] == key.uid ||
                              day.parent && note['scope'] == 'baby')
                      ? PopupMenuButton<String>(
                          icon: const PersonalDots(),
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
                              write({
                                'kind': 'delete_note',
                                'id': note['id'],
                                'revision': note['revision'],
                              });
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l.pv2Edit),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l.pv2Delete),
                            ),
                          ],
                        )
                      : null,
                ),
            ],
          ),
        if (day.writable) ...[
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l.pv2AddNote,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => showNotebookEditor(context, ref, key, day.parent),
          ),
        ],
      ];
    },
  );
}

/// "Đã lưu, đã thử và đã ẩn": the week's answers, then every idea by what the person did,
/// each with the step it still allows; co-parents also restore family exclusions.
class PersonalHistoryScreen extends StatelessWidget {
  const PersonalHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => PersonalDayPage(
    title: (l) => l.pv2History,
    builder: (context, ref, key, day, write, busy) {
      final l = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context);
      final now = ref.watch(careClockProvider).value ?? DateTime.now();
      final content = ref.watch(rhythmContentProvider).value;
      final weekly = dayMap(day.data['weekly']);
      final entries =
          day.responses.entries
              .where((e) => !e.key.startsWith('work:'))
              .toList()
            ..sort(
              (a, b) => '${dayMap(b.value)['at']}'.compareTo(
                '${dayMap(a.value)['at']}',
              ),
            );
      bool hidden(MapEntry<String, dynamic> e) =>
          day.suppressed(e.key, now) &&
          !['tried', 'helpful'].contains(dayMap(e.value)['value']);
      final groups = [
        (
          l.pv2SavedNow,
          entries.where((e) => dayMap(e.value)['saved'] == true).toList(),
        ),
        (
          l.pv2TriedBefore,
          entries.where((e) => dayMap(e.value)['triedAt'] != null).toList(),
        ),
        (l.pv2HiddenNow, entries.where(hidden).toList()),
      ];
      String title(String id) =>
          content?.activity(id)?.title.of(locale) ?? l.rhUnknownActivity;
      return [
        RhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.pv2Weekly, style: context.cl.text.bodyStrong),
              const SizedBox(height: ClSpace.s1),
              Text(
                l.pv2WeekLine(
                  (weekly['tried'] as num? ?? 0).toInt(),
                  (weekly['helpful'] as num? ?? 0).toInt(),
                ),
              ),
              const SizedBox(height: ClSpace.s1),
              Text(l.pv2WeekHint, style: _muted(context)),
            ],
          ),
        ),
        for (final (heading, rows) in groups)
          if (rows.isNotEmpty) ...[
            PersonalHeading(heading),
            ClCardGroup(
              children: [
                for (final e in rows)
                  PersonalIdeaRow(
                    key: Key('personalHistory:$heading:${e.key}'),
                    title: title(e.key),
                    status: responseStatus(l, day, e.key, locale, now),
                    trailing: !day.writable
                        ? null
                        : PopupMenuButton<String>(
                            icon: const PersonalDots(),
                            tooltip: l.pv2Controls,
                            onSelected: (value) async {
                              final ok = await write({
                                'kind': 'respond',
                                'contentId': e.key,
                                'value': value,
                              });
                              if (ok &&
                                  [
                                    'intend',
                                    'tried',
                                    'helpful',
                                    'unsure',
                                  ].contains(value)) {
                                personalEvent(
                                  ref,
                                  'personalizationOutcome',
                                  value,
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              for (final value in [
                                ...nextSteps(day, e.key),
                                if (hidden(e)) 'restore',
                              ])
                                PopupMenuItem(
                                  value: value,
                                  child: Text(responseLabel(l, value)),
                                ),
                            ],
                          ),
                  ),
              ],
            ),
          ],
        if (day.parent && dayRows(day.data['sharedExclusions']).isNotEmpty) ...[
          PersonalHeading(l.pv2Exclude),
          ClCardGroup(
            children: [
              for (final exclusion in dayRows(day.data['sharedExclusions']))
                MeRow(
                  title: title('${exclusion['id']}'),
                  trailing: PersonalTextAction(
                    label: l.pv2Restore,
                    onTap: () {
                      if (!busy) {
                        write({
                          'kind': 'respond',
                          'contentId': exclusion['id'],
                          'value': 'restore',
                          'scope': 'baby',
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ];
    },
  );
}
