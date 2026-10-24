import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart' show inBabyZone;
import 'personalization_events.dart';
import 'personalization_v2_repository.dart';
import 'personalization_v2_screen.dart';
import 'rhythm_calc.dart' show isoOf;

// P-172 (owner, 2026-10-22): whatever a person did on a suggestion stays visible on the card,
// on Home and on "Hôm nay bạn đã" after the app is reopened, not only in a toast.

String _zone(PersonalDay day) =>
    day.data['zone'] as String? ?? 'Asia/Ho_Chi_Minh';

/// Whether [value] (an ISO instant) falls on the snapshot's day in the baby's time zone.
bool onDay(PersonalDay day, Object? value) {
  final at = DateTime.tryParse('${value ?? ''}');
  return at != null && isoOf(inBabyZone(_zone(day), at)) == day.data['today'];
}

/// "10:20" on the snapshot's day, "21/10" on another.
String dayStamp(PersonalDay day, Object? value, Locale locale) {
  final at = DateTime.tryParse('${value ?? ''}');
  if (at == null) return '';
  return DateFormat(
    onDay(day, value) ? 'HH:mm' : 'dd/MM',
    locale.languageCode,
  ).format(inBabyZone(_zone(day), at));
}

const _hiding = ['hide', 'dislike', 'known'];

/// One thing the person did with an idea, as a chip (owner, 2026-10-22: recognised at a
/// glance by colour and icon, not read).
enum PersonalStatusKind { helpful, unsure, tried, intend, saved, hidden }

typedef PersonalStatus = ({PersonalStatusKind kind, String label});

/// This person's own state for [id], the outcome first ("Có ích", "Đã thử · 10:20", "Đã lưu").
/// Empty when they have not acted on it.
List<PersonalStatus> responseStatus(
  AppLocalizations l,
  PersonalDay day,
  String id,
  Locale locale,
  DateTime now,
) {
  final r = dayMap(day.responses[id]);
  if (r.isEmpty) return const [];
  final value = r['value'];
  final active = day.suppressed(id, now);
  final helped = r['outcome'] == 'helpful' || value == 'helpful';
  // Planned again after a helpful try: the plan is the state, the outcome its history ("Định
  // thử · 24/10", "Từng có ích"), not "Có ích" beside a plan (owner, 2026-10-24).
  final again = helped && r['triedAt'] == null && r['intendedAt'] != null;
  return [
    if (helped && !again)
      (kind: PersonalStatusKind.helpful, label: l.pv2ChipHelpful),
    if (r['outcome'] == 'unsure')
      (kind: PersonalStatusKind.unsure, label: l.pv2ChipUnsure),
    if (r['triedAt'] != null)
      (
        kind: PersonalStatusKind.tried,
        label: l.pv2StatusTried(dayStamp(day, r['triedAt'], locale)),
      )
    else if (r['intendedAt'] != null)
      (
        kind: PersonalStatusKind.intend,
        label: l.pv2StatusIntend(dayStamp(day, r['intendedAt'], locale)),
      ),
    if (again) (kind: PersonalStatusKind.tried, label: l.pv2ChipHelpedBefore),
    if (active && _hiding.contains(value))
      (kind: PersonalStatusKind.hidden, label: l.pv2StatusHidden),
    if (active && value == 'snooze')
      (
        kind: PersonalStatusKind.hidden,
        label: l.pv2StatusSnoozed(dayStamp(day, r['until'], locale)),
      ),
    if (active && value == 'exclude')
      (kind: PersonalStatusKind.hidden, label: l.pv2StatusExcluded),
    if (r['saved'] == true)
      (kind: PersonalStatusKind.saved, label: l.pv2StatusSaved),
  ];
}

/// The status chips of an idea: "Có ích" solid mint, an attempt mint, a plan sunshine, saved
/// with its bookmark, put away muted.
class PersonalStatusChips extends StatelessWidget {
  const PersonalStatusChips(this.items, {super.key});
  final List<PersonalStatus> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Semantics(
      label: items.map((i) => i.label).join(', '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in items)
              Builder(
                builder: (context) {
                  final (fill, ink, icon) = switch (item.kind) {
                    PersonalStatusKind.helpful => (
                      c.mintDeep,
                      c.onMintDeep,
                      ClIcons.heart,
                    ),
                    PersonalStatusKind.tried => (
                      c.mintSoft,
                      c.mintText,
                      ClIcons.check,
                    ),
                    // Soft warm fills take ink, also in Night care.
                    PersonalStatusKind.intend => (
                      c.sunshineSoft,
                      c.ink,
                      ClIcons.clock,
                    ),
                    PersonalStatusKind.saved => (
                      c.surface2,
                      c.mintText,
                      ClIcons.bookmarkFill,
                    ),
                    PersonalStatusKind.unsure ||
                    PersonalStatusKind.hidden => (c.surface2, c.inkMuted, null),
                  };
                  return Container(
                    key: Key('personalChip:${item.kind.name}'),
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          ClIcon(icon, size: 12, color: ink),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item.label,
                          style: cl.text.caption.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A row of an idea in a list ("Hôm nay bạn đã", history): its title, its chips and the one
/// action it still needs, never squeezed beside the text.
class PersonalIdeaRow extends StatelessWidget {
  const PersonalIdeaRow({
    required this.title,
    required this.status,
    this.trailing,
    this.onTap,
    super.key,
  });
  final String title;
  final List<PersonalStatus> status;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.body),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  PersonalStatusChips(status),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: ClSpace.s2),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: ClSpace.s1),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ],
      ),
    );
    return onTap == null
        ? MergeSemantics(child: row)
        : ClPressable(onPressed: onTap, semanticLabel: title, child: row);
  }
}

/// The activities this person acted on today (newest first), work cards left out: their state
/// is on the handover screen.
List<String> actedToday(PersonalDay day) {
  DateTime? latest(Map<String, dynamic> r) =>
      [r['at'], r['intendedAt'], r['triedAt'], r['outcomeAt']]
          .where((v) => onDay(day, v))
          .map((v) => DateTime.parse('$v'))
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  final rows = [
    for (final e in day.responses.entries)
      if (!e.key.startsWith('work:') && dayMap(e.value)['value'] != 'restore')
        if (latest(dayMap(e.value)) case final at?) (e.key, at),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final r in rows) r.$1];
}

/// The next step on an activity: plan, then tried, then how it went (never skipping "tried",
/// the server refuses an outcome before it).
List<String> nextSteps(PersonalDay day, String id) {
  final r = dayMap(day.responses[id]);
  if (r['triedAt'] != null) {
    return r['outcome'] == null ? const ['helpful', 'unsure'] : const [];
  }
  return r['intendedAt'] != null ? const ['tried'] : const ['intend', 'tried'];
}

/// The toast after a saved change says what changed and where it can be seen again.
String actionToast(AppLocalizations l, Map<String, Object?> action) =>
    switch (action['kind']) {
      'context' => l.pv2ToastContext(contextLabel(l, '${action['value']}')),
      'focus' =>
        action['value'] == null ? l.pv2ToastFocusOff : l.pv2ToastFocusOn,
      'routine' =>
        action['unusual'] == true ? l.pv2ToastUnusualOn : l.pv2ToastUnusualOff,
      'acknowledge' => l.pv2ToastAcknowledged,
      'respond' => switch (action['value']) {
        'save' => l.pv2ToastSaved,
        'unsave' => l.pv2ToastUnsaved,
        'intend' => l.pv2ToastIntend,
        'tried' => l.pv2ToastTried,
        'helpful' || 'unsure' => l.pv2ToastOutcome,
        'snooze' when '${action['contentId']}'.startsWith('work:') =>
          l.pv2ToastWorkSnoozed,
        'snooze' => l.pv2ToastSnoozed,
        'hide' || 'dislike' || 'known' => l.pv2ToastHidden,
        'exclude' => l.pv2ToastExcluded,
        'restore' => l.pv2ToastRestored,
        _ => l.pv2ChangeSaved,
      },
      _ => l.pv2ChangeSaved,
    };

/// The write that takes [action] back, when one exists ("Hoàn tác" on the toast). An attempt
/// or an outcome has none; a family exclusion is restored on "Đã lưu, đã thử và đã ẩn".
Map<String, Object?>? undoOf(
  Map<String, Object?> action,
  PersonalDay? before,
) => switch (action['kind']) {
  'context' when before != null && before.context != action['value'] => {
    'kind': 'context',
    'value': before.context,
  },
  'focus' when before != null && before.data['focus'] != action['value'] => {
    'kind': 'focus',
    'value': before.data['focus'],
  },
  'routine' => {'kind': 'routine', 'unusual': action['unusual'] != true},
  'respond' when action['value'] == 'save' || action['value'] == 'unsave' => {
    'kind': 'respond',
    'contentId': action['contentId'],
    'value': action['value'] == 'save' ? 'unsave' : 'save',
  },
  'respond'
      when ['hide', 'dislike', 'known', 'snooze'].contains(action['value']) =>
    {'kind': 'respond', 'contentId': action['contentId'], 'value': 'restore'},
  _ => null,
};

String contextHint(AppLocalizations l, String value) => switch (value) {
  'few_minutes' => l.pv2FewMinutesHint,
  'busy' => l.pv2BusyHint,
  _ => l.pv2UsualHint,
};

/// A mint line with a check: what this person already did ("Bạn định thử · 10:20").
class PersonalStatusLine extends StatelessWidget {
  const PersonalStatusLine(this.parts, {super.key});
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: cl.text.label.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three choices for today, each with what it does to the suggestions.
class DayContextOptions extends StatelessWidget {
  const DayContextOptions({
    required this.selected,
    required this.onSelect,
    this.color,
    super.key,
  });
  final String selected;
  final ValueChanged<String>? onSelect;

  /// Surface-2 inside a sheet.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClCardGroup(
      color: color,
      children: [
        for (final value in dayContexts)
          ClOptionRow(
            key: Key('dayContext:$value'),
            title: contextLabel(l, value),
            subtitle: contextHint(l, value),
            selected: selected == value,
            onTap: () {
              if (value != selected) onSelect?.call(value);
            },
          ),
      ],
    );
  }
}

/// "Thời gian hôm nay" from Home: the same choices in a sheet.
Future<void> chooseDayContext(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  PersonalDay day,
) async {
  final l = AppLocalizations.of(context);
  final choice = await showClSheet<String>(
    context: context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        ClSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l.pv2Context),
          DayContextOptions(
            color: sheet.cl.colors.surface2,
            selected: day.context,
            onSelect: (value) => Navigator.of(sheet).pop(value),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l.pv2Temporary,
            style: sheet.cl.text.caption.copyWith(
              color: sheet.cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    ),
  );
  if (choice != null && context.mounted) {
    await mutateDay(context, ref, key, {'kind': 'context', 'value': choice});
  }
}

/// "Thấy sao?" after an attempt: helpful or not clear yet.
Future<void> askOutcome(
  BuildContext context,
  WidgetRef ref,
  PersonalDayKey key,
  String id,
) async {
  final l = AppLocalizations.of(context);
  final value = await showClSheet<String>(
    context: context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        ClSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l.pv2HowWasItTitle),
          ClCardGroup(
            color: sheet.cl.colors.surface2,
            children: [
              for (final v in const ['helpful', 'unsure'])
                ClListRow(
                  title: responseLabel(l, v),
                  onTap: () => Navigator.of(sheet).pop(v),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l.pv2NoAnswer,
            style: sheet.cl.text.caption.copyWith(
              color: sheet.cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    ),
  );
  if (value != null && context.mounted) {
    final ok = await mutateDay(context, ref, key, {
      'kind': 'respond',
      'contentId': id,
      'value': value,
    });
    if (ok) personalEvent(ref, 'personalizationOutcome', value);
  }
}

/// A small mint text action at the end of a line ("Thấy sao?", "Xem thêm").
class PersonalTextAction extends StatelessWidget {
  const PersonalTextAction({
    required this.label,
    required this.onTap,
    this.chevron = false,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: cl.text.label.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 2),
              ClIcon(ClIcons.chevronRight, size: 14, color: cl.colors.mintText),
            ],
          ],
        ),
      ),
    );
  }
}

/// The saved bookmark: filled once saved; tapping it again takes the idea out of saved.
class PersonalSaveButton extends ConsumerWidget {
  const PersonalSaveButton({
    required this.dayKey,
    required this.day,
    required this.contentId,
    super.key,
  });
  final PersonalDayKey dayKey;
  final PersonalDay day;
  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final saved = dayMap(day.responses[contentId])['saved'] == true;
    return IconButton(
      tooltip: saved ? l.pv2Unsave : l.pv2Save,
      onPressed: () => mutateDay(context, ref, dayKey, {
        'kind': 'respond',
        'contentId': contentId,
        'value': saved ? 'unsave' : 'save',
      }),
      icon: ClIcon(
        saved ? ClIcons.bookmarkFill : ClIcons.bookmark,
        size: 20,
        color: saved ? cl.colors.mintText : cl.colors.inkMuted,
      ),
    );
  }
}

/// "⋯" for a card's other options (no such glyph in the icon set).
class PersonalMoreButton extends StatelessWidget {
  const PersonalMoreButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ink = context.cl.colors.inkMuted;
    return IconButton(
      tooltip: l.pv2Controls,
      onPressed: onPressed,
      icon: PersonalDots(color: ink),
    );
  }
}

/// Three dots in the icon line style, for "⋯" buttons and menus.
class PersonalDots extends StatelessWidget {
  const PersonalDots({this.color, super.key});
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color ?? context.cl.colors.inkMuted,
            shape: BoxShape.circle,
          ),
        ),
    ],
  );
}
