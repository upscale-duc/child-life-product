import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/widgets/onboarding_layout.dart';

String hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 13 Giao diện (29:1063): changes apply at once, stored per device (P-061, R-011).
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final settings = ref.watch(appearanceSettingsProvider);
    final controller = ref.read(appearanceSettingsProvider.notifier);
    final start = hhmm(settings.scheduleStart);
    final end = hhmm(settings.scheduleEnd);
    Widget option(ThemePreference pref, ClThemePreview preview, String label) =>
        Expanded(
          child: ClThemeOption(
            preview: preview,
            label: label,
            selected: settings.theme == pref,
            onTap: () => controller.update(settings.copyWith(theme: pref)),
          ),
        );
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop()),
      content: [
        ScreenHeading(title: l10n.appearanceTitle),
        const SizedBox(height: ClSpace.s6),
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: Row(
            children: [
              option(
                ThemePreference.light,
                ClThemePreview.light,
                l10n.themeLight,
              ),
              option(ThemePreference.dark, ClThemePreview.dark, l10n.themeDark),
              option(ThemePreference.auto, ClThemePreview.auto, l10n.themeAuto),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClSettingRow(
          icon: ClIcons.sleep,
          title: l10n.nightCareTitle,
          subtitle: settings.nightCareScheduleEnabled
              ? l10n.nightCareScheduled(start, end)
              : l10n.nightCareOff,
          value: settings.nightCareScheduleEnabled,
          onChanged: (on) => controller.update(
            settings.copyWith(nightCareScheduleEnabled: on),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.nightCareSchedule,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          shadow: true,
          children: [
            ClDetailRow(
              icon: ClIcons.sleep,
              label: l10n.nightCareOn,
              value: start,
              valueIsAccent: true,
              onTap: () => showNightCareScheduleSheet(context, editEnd: false),
            ),
            ClDetailRow(
              icon: ClIcons.sunrise,
              label: l10n.nightCareOffAt,
              value: end,
              valueIsAccent: true,
              onTap: () => showNightCareScheduleSheet(context, editEnd: true),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          l10n.nightCareHint,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.appearanceAppliesNow,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// Minutes from [start] to [end] on a 24 h clock, crossing midnight (21:00 → 06:00 = 9 h).
int windowMinutes(TimeOfDay start, TimeOfDay end) {
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  return (e - s + 24 * 60) % (24 * 60);
}

String durationLabel(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? l10n.durationHours(h) : l10n.durationHoursMinutes(h, m);
}

/// 13a Lịch Night care (43:2067): one end at a time, 5-minute steps, presets, duration hint.
Future<void> showNightCareScheduleSheet(
  BuildContext context, {
  required bool editEnd,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _ScheduleSheet(editEnd: editEnd),
);

class _ScheduleSheet extends ConsumerStatefulWidget {
  const _ScheduleSheet({required this.editEnd});
  final bool editEnd;

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  late bool _editEnd = widget.editEnd;
  late TimeOfDay _start = ref.read(appearanceSettingsProvider).scheduleStart;
  late TimeOfDay _end = _snap(ref.read(appearanceSettingsProvider).scheduleEnd);
  late FixedExtentScrollController _hours;
  late FixedExtentScrollController _minutes;

  static TimeOfDay _snap(TimeOfDay t) =>
      TimeOfDay(hour: t.hour, minute: (t.minute ~/ 5) * 5);

  TimeOfDay get _current => _editEnd ? _end : _start;

  @override
  void initState() {
    super.initState();
    _start = _snap(_start);
    _resetWheels();
  }

  void _resetWheels() {
    _hours = FixedExtentScrollController(initialItem: _current.hour);
    _minutes = FixedExtentScrollController(initialItem: _current.minute ~/ 5);
  }

  void _set(TimeOfDay t) => setState(() => _editEnd ? _end = t : _start = t);

  void _jump(TimeOfDay t) {
    _set(t);
    _hours.jumpToItem(t.hour);
    _minutes.jumpToItem(t.minute ~/ 5);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final presets = _editEnd ? const [5, 6, 7, 8] : const [20, 21, 22, 23];
    final itemStyle = cl.text.headline.copyWith(color: cl.colors.ink);
    Widget wheel(
      FixedExtentScrollController c,
      int count,
      String Function(int) label,
      ValueChanged<int> onChanged,
    ) => Expanded(
      child: CupertinoPicker(
        scrollController: c,
        itemExtent: 44,
        looping: true,
        onSelectedItemChanged: onChanged,
        children: [
          for (var i = 0; i < count; i++)
            Center(child: Text(label(i), style: itemStyle)),
        ],
      ),
    );
    final minutes = windowMinutes(_start, _end);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        MediaQuery.of(context).padding.bottom + ClSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(
            title: l10n.nightCareSchedule,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: ClSpace.s2),
          ClSegmented<bool>(
            options: const [false, true],
            selected: _editEnd,
            labelOf: (end) => end
                ? l10n.nightCareSegmentOff(hhmm(_end))
                : l10n.nightCareSegmentOn(hhmm(_start)),
            onChanged: (end) => setState(() {
              _editEnd = end;
              _hours.jumpToItem(_current.hour);
              _minutes.jumpToItem(_current.minute ~/ 5);
            }),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    l10n.pickerHour,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.pickerMinute,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                wheel(
                  _hours,
                  24,
                  (i) => i.toString().padLeft(2, '0'),
                  (i) => _set(TimeOfDay(hour: i, minute: _current.minute)),
                ),
                wheel(
                  _minutes,
                  12,
                  (i) => (i * 5).toString().padLeft(2, '0'),
                  (i) => _set(TimeOfDay(hour: _current.hour, minute: i * 5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in presets)
                ClFilterChip(
                  label: hhmm(TimeOfDay(hour: h, minute: 0)),
                  selected: _current == TimeOfDay(hour: h, minute: 0),
                  onTap: () => _jump(TimeOfDay(hour: h, minute: 0)),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(ClIcons.sleep, size: 16, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s1),
              Flexible(
                child: Text(
                  l10n.nightCareDuration(
                    durationLabel(l10n, minutes),
                    hhmm(_end),
                  ),
                  style: cl.text.label.copyWith(color: cl.colors.mintText),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () {
              final controller = ref.read(appearanceSettingsProvider.notifier);
              final settings = ref.read(appearanceSettingsProvider);
              controller.update(
                settings.copyWith(scheduleStart: _start, scheduleEnd: _end),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
