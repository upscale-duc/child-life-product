import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show trackerLabel;
import '../reminders/reminder_repository.dart';
import '../care/care_repository.dart';

/// The three parts of Hôm nay that "Tuỳ chỉnh Hôm nay" arranges (v1.0 improvement 370:1525).
enum TodaySection { tiles, reminders, rhythm }

/// What Hôm nay shows and in which order, kept on this device per baby (the design does not say
/// whose setting it is; like Giao diện, P-061, it stays on the phone). Which trackers a baby has
/// is the family's choice at setup; this only hides tiles from this view.
@immutable
class TodayLayout {
  const TodayLayout({
    this.order = TodaySection.values,
    this.hidden = const {},
    this.hiddenTiles = const {},
  });

  final List<TodaySection> order;
  final Set<TodaySection> hidden;
  final Set<TrackerKind> hiddenTiles;

  bool shows(TodaySection s) => !hidden.contains(s);

  Map<String, Object?> toJson() => {
    'order': [for (final s in order) s.name],
    'hidden': [for (final s in hidden) s.name],
    'hiddenTiles': [for (final t in hiddenTiles) t.name],
  };

  factory TodayLayout.fromJson(Map<String, Object?> j) {
    List<T> names<T extends Enum>(Object? v, List<T> values) => [
      for (final n in (v as List? ?? const []))
        if (values.asNameMap()[n] case final T x) x,
    ];
    final order = names(j['order'], TodaySection.values);
    return TodayLayout(
      // Sections missing from a saved order (added later) go at the end.
      order: [
        ...order,
        ...TodaySection.values.where((s) => !order.contains(s)),
      ],
      hidden: names(j['hidden'], TodaySection.values).toSet(),
      hiddenTiles: names(j['hiddenTiles'], TrackerKind.values).toSet(),
    );
  }
}

final todayLayoutProvider =
    NotifierProvider.family<TodayLayoutNotifier, TodayLayout, String>(
      TodayLayoutNotifier.new,
    );

class TodayLayoutNotifier extends Notifier<TodayLayout> {
  TodayLayoutNotifier(this.babyId);
  final String babyId;

  String get _key => 'today.layout.$babyId';

  @override
  TodayLayout build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      if (raw == null) return const TodayLayout();
      return TodayLayout.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      return const TodayLayout();
    }
  }

  void set(TodayLayout layout) {
    state = layout;
    try {
      ref
          .read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(layout.toJson()));
    } on StateError {
      // No preferences (tests).
    }
  }
}

/// 370:1525 "Tuỳ chỉnh Hôm nay": turn the sections on or off, drag them into order, and pick
/// the visible tiles; "Đặt lại" restores the default, "Xong" saves.
Future<void> showTodayCustomizeSheet(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (_) => const _CustomizeSheet(),
);

class _CustomizeSheet extends ConsumerStatefulWidget {
  const _CustomizeSheet();

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  TodayLayout? _draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    // Callbacks read the draft when they run, so quick taps build on each other.
    TodayLayout cur() => _draft ?? ref.read(todayLayoutProvider(me.babyId));
    final draft = cur();
    final trackers =
        ref.watch(babyProvider(me.babyId)).value?.trackers ??
        const <TrackerKind>[];
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final remindersOn = (ref.watch(remindersProvider(me.babyId)).value ?? [])
        .where((r) => !r.done && r.dueAt.isAfter(now))
        .length;

    (String, String) labels(TodaySection s) => switch (s) {
      TodaySection.tiles => (l10n.sectionTiles, l10n.sectionTilesSub),
      TodaySection.reminders => (
        l10n.sectionReminders,
        l10n.careRemindersOn(remindersOn),
      ),
      TodaySection.rhythm => (l10n.sectionRhythm, l10n.sectionRhythmSub),
    };

    void update(TodayLayout next) => setState(() => _draft = next);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.customizeTitle),
        Text(
          l10n.customizeIntro,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: cl.shadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) {
              final order = [...cur().order];
              order.insert(to, order.removeAt(from));
              update(
                TodayLayout(
                  order: order,
                  hidden: cur().hidden,
                  hiddenTiles: cur().hiddenTiles,
                ),
              );
            },
            children: [
              for (final (i, section) in draft.order.indexed)
                Material(
                  key: ValueKey(section),
                  color: cl.colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClSpace.s3,
                      vertical: ClSpace.s3,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Semantics(
                            label: l10n.a11yDragToReorder,
                            child: Padding(
                              padding: const EdgeInsets.all(ClSpace.s2),
                              child: _Handle(color: cl.colors.inkMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(labels(section).$1, style: cl.text.body),
                              Text(
                                labels(section).$2,
                                style: cl.text.caption.copyWith(
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClToggle(
                          value: draft.shows(section),
                          semanticLabel: labels(section).$1,
                          onChanged: (on) => update(
                            TodayLayout(
                              order: cur().order,
                              hidden: on
                                  ? (cur().hidden.toSet()..remove(section))
                                  : (cur().hidden.toSet()..add(section)),
                              hiddenTiles: cur().hiddenTiles,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.visibleTiles,
          style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final kind in trackers)
              _TileChip(
                label: trackerLabel(l10n, kind),
                selected: !draft.hiddenTiles.contains(kind),
                onTap: () => update(
                  TodayLayout(
                    order: cur().order,
                    hidden: cur().hidden,
                    hiddenTiles: cur().hiddenTiles.contains(kind)
                        ? (cur().hiddenTiles.toSet()..remove(kind))
                        : (cur().hiddenTiles.toSet()..add(kind)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        Row(
          children: [
            Expanded(
              child: ClButton(
                label: l10n.customizeReset,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => update(const TodayLayout()),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: ClButton(
                label: l10n.customizeDone,
                expand: true,
                onPressed: () {
                  ref.read(todayLayoutProvider(me.babyId).notifier).set(cur());
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

class _TileChip extends StatelessWidget {
  const _TileChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? cl.colors.mintText : cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 370:1525 drag handle: three 14×2 bars.
class _Handle extends StatelessWidget {
  const _Handle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 3),
          Container(
            width: 14,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    ),
  );
}
