import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show trackerArt, trackerLabel;
import '../reminders/reminder_repository.dart';
import '../reminders/rule_repository.dart';
import '../care/care_repository.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../spending/spending_models.dart' show SpendingAccess;

/// The parts of Hôm nay that "Tuỳ chỉnh Hôm nay" arranges (v1.0 improvement 370:1525). The first
/// three are the design's; the others are opt-in (owner, 2026-10-12) and start hidden.
/// [forYou] is "Dành cho bé hôm nay" (559:57583, `today_for_baby.dart`): right after the quick-track
/// tiles by default (D-076 #8); it shows only when the family's `rhythm` flag is on.
enum TodaySection {
  forYou,
  tiles,
  reminders,
  quickActions,
  vaccine,
  spending,
  rhythm,
}

/// Shortcuts in "Tạo nhanh" (owner, 2026-10-12), each shown only to who may do it.
enum QuickAction { reminder, expense, vaccine, memory }

/// What Hôm nay shows and in which order, kept on this device per baby (the design does not say
/// whose setting it is; like Giao diện, P-061, it stays on the phone). Which trackers a baby has
/// is the family's choice at setup; this only hides tiles from this view and orders them.
@immutable
class TodayLayout {
  const TodayLayout({
    this.order = defaultOrder,
    this.hidden = defaultHidden,
    this.tileOrder = const [],
    this.hiddenTiles = const {},
    this.actionOrder = QuickAction.values,
    this.hiddenActions = const {},
  });

  /// As drawn (370:1525): tiles, reminders, the day's rhythm; the opt-in parts in between.
  static const defaultOrder = [
    TodaySection.tiles,
    TodaySection.forYou,
    TodaySection.reminders,
    TodaySection.quickActions,
    TodaySection.vaccine,
    TodaySection.spending,
    TodaySection.rhythm,
  ];
  static const defaultHidden = {
    TodaySection.quickActions,
    TodaySection.vaccine,
    TodaySection.spending,
  };

  final List<TodaySection> order;
  final Set<TodaySection> hidden;

  /// Tile order chosen here; trackers not in it follow in the baby's order.
  final List<TrackerKind> tileOrder;
  final Set<TrackerKind> hiddenTiles;
  final List<QuickAction> actionOrder;
  final Set<QuickAction> hiddenActions;

  bool shows(TodaySection s) => !hidden.contains(s);

  /// The baby's [trackers] in this layout's order (hidden ones included).
  List<TrackerKind> tiles(List<TrackerKind> trackers) => [
    for (final t in tileOrder)
      if (trackers.contains(t)) t,
    for (final t in trackers)
      if (!tileOrder.contains(t)) t,
  ];

  TodayLayout copyWith({
    List<TodaySection>? order,
    Set<TodaySection>? hidden,
    List<TrackerKind>? tileOrder,
    Set<TrackerKind>? hiddenTiles,
    List<QuickAction>? actionOrder,
    Set<QuickAction>? hiddenActions,
  }) => TodayLayout(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    tileOrder: tileOrder ?? this.tileOrder,
    hiddenTiles: hiddenTiles ?? this.hiddenTiles,
    actionOrder: actionOrder ?? this.actionOrder,
    hiddenActions: hiddenActions ?? this.hiddenActions,
  );

  /// Saved layouts before it put "Dành cho bé hôm nay" first; from this version on, its place
  /// is the person's (D-076 #8).
  static const version = 2;

  Map<String, Object?> toJson() => {
    'v': version,
    'order': [for (final s in order) s.name],
    'hidden': [for (final s in hidden) s.name],
    'tileOrder': [for (final t in tileOrder) t.name],
    'hiddenTiles': [for (final t in hiddenTiles) t.name],
    'actionOrder': [for (final a in actionOrder) a.name],
    'hiddenActions': [for (final a in hiddenActions) a.name],
  };

  factory TodayLayout.fromJson(Map<String, Object?> j) {
    List<T> names<T extends Enum>(Object? v, List<T> values) => [
      for (final n in (v as List? ?? const []))
        if (values.asNameMap()[n] case final T x) x,
    ];
    final order = names(j['order'], TodaySection.values);
    // D-076 #8: a layout saved before version 2 had "Dành cho bé hôm nay" where the app put it
    // (first); it moves to its new default place, right after the tiles. Hidden stays hidden.
    if ((j['v'] is int ? j['v']! as int : 1) < version) {
      order.remove(TodaySection.forYou);
    }
    // Sections missing from a saved order (added later) go in their default place, with their
    // default visibility.
    final added = [
      for (final s in defaultOrder)
        if (!order.contains(s)) s,
    ];
    final merged = [...order];
    for (final s in added) {
      final before = defaultOrder.sublist(0, defaultOrder.indexOf(s));
      final at = merged.lastIndexWhere(before.contains);
      merged.insert(at + 1, s);
    }
    final actions = names(j['actionOrder'], QuickAction.values);
    return TodayLayout(
      order: merged,
      hidden: {
        ...names(j['hidden'], TodaySection.values),
        ...added.where(defaultHidden.contains),
      },
      tileOrder: names(j['tileOrder'], TrackerKind.values),
      hiddenTiles: names(j['hiddenTiles'], TrackerKind.values).toSet(),
      actionOrder: [
        ...actions,
        ...QuickAction.values.where((a) => !actions.contains(a)),
      ],
      hiddenActions: names(j['hiddenActions'], QuickAction.values).toSet(),
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

/// Shortcuts [me] may use (reminders: not relatives; spending: "Ghi khoản đã chi" or Cùng nuôi;
/// vaccines: P-133 loggers; memories: Cùng nuôi, who upload).
List<QuickAction> allowedActions(Membership me) => [
  for (final a in QuickAction.values)
    if (switch (a) {
      QuickAction.reminder => me.role != MemberRole.relative,
      QuickAction.expense => SpendingAccess.of(me).record,
      QuickAction.vaccine => me.role != MemberRole.relative,
      QuickAction.memory => me.role == MemberRole.coParent,
    })
      a,
];

/// Sections [me] can have: spending needs "Xem toàn bộ" (or Cùng nuôi), shortcuts need one,
/// "Dành cho bé hôm nay" the family's `rhythm` flag.
List<TodaySection> allowedSections(
  Membership me, {
  required bool hasTiles,
  bool rhythm = false,
}) => [
  for (final s in TodaySection.values)
    if (switch (s) {
      TodaySection.forYou => rhythm,
      TodaySection.tiles => hasTiles,
      TodaySection.quickActions => allowedActions(me).isNotEmpty,
      TodaySection.spending => SpendingAccess.of(me).viewAll,
      _ => true,
    })
      s,
];

/// [full] with the [visible] items moved from [from] to [to] (indexes into [visible]); items the
/// viewer cannot see keep their places.
List<T> reorderVisible<T>(List<T> full, List<T> visible, int from, int to) {
  final moved = [...visible];
  moved.insert(to, moved.removeAt(from));
  var k = 0;
  return [for (final item in full) visible.contains(item) ? moved[k++] : item];
}

/// 370:1525 "Tuỳ chỉnh Hôm nay", grown on owner feedback (2026-10-12): every part on its own
/// row (each tracker tile too) with a switch, the opt-in parts (Tạo nhanh, Mũi tiêm sắp tới,
/// Chi tiêu tháng này), and dragging by the handle or by a long press anywhere on a row.
/// "Đặt lại" restores the design's default, "Xong" saves.
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
    void update(TodayLayout next) => setState(() => _draft = next);

    final trackers =
        ref.watch(babyProvider(me.babyId)).value?.trackers ??
        const <TrackerKind>[];
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final remindersOn =
        (ref.watch(remindersProvider(me.babyId)).value ?? [])
            .where((r) => !r.done && r.dueAt.isAfter(now))
            .length +
        (ref.watch(reminderRulesProvider(me.babyId)).value ?? [])
            .where((r) => r.enabled)
            .length;

    final sections = [
      for (final s in draft.order)
        if (allowedSections(
          me,
          hasTiles: trackers.isNotEmpty,
          rhythm:
              ref.watch(selectedCapabilitiesProvider)?.features.rhythm ?? false,
        ).contains(s))
          s,
    ];
    final tiles = draft.tiles(trackers);
    final allowed = allowedActions(me);
    final actions = [
      for (final a in draft.actionOrder)
        if (allowed.contains(a)) a,
    ];

    (String, String) sectionLabels(TodaySection s) => switch (s) {
      TodaySection.forYou => (l10n.rhSectionForYou, l10n.rhSectionForYouSub),
      TodaySection.tiles => (l10n.sectionTiles, l10n.sectionTilesSub),
      TodaySection.reminders => (
        l10n.sectionReminders,
        l10n.careRemindersOn(remindersOn),
      ),
      TodaySection.quickActions => (
        l10n.sectionQuickActions,
        l10n.sectionQuickActionsSub,
      ),
      TodaySection.vaccine => (l10n.sectionVaccine, l10n.sectionVaccineSub),
      TodaySection.spending => (l10n.sectionSpending, l10n.sectionSpendingSub),
      TodaySection.rhythm => (l10n.sectionRhythm, l10n.sectionRhythmSub),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Its own node: next to the scrolling body the title and "Đóng" would read as one.
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: ClSheetHeader(title: l10n.customizeTitle),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.customizeIntro,
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s3),
                _ReorderGroup<TodaySection>(
                  key: const Key('customizeSections'),
                  items: sections,
                  title: (s) => sectionLabels(s).$1,
                  // A part with choices shows them instead of a summary once it is on.
                  subtitle: (s) =>
                      draft.shows(s) &&
                          (s == TodaySection.tiles ||
                              s == TodaySection.quickActions)
                      ? null
                      : sectionLabels(s).$2,
                  isOn: (s) => draft.shows(s),
                  onToggle: (s, on) => update(
                    cur().copyWith(
                      hidden: on
                          ? (cur().hidden.toSet()..remove(s))
                          : (cur().hidden.toSet()..add(s)),
                    ),
                  ),
                  onReorder: (from, to) => update(
                    cur().copyWith(
                      order: reorderVisible(cur().order, sections, from, to),
                    ),
                  ),
                  below: (s) => switch (s) {
                    TodaySection.tiles when tiles.isNotEmpty => _ChoiceWrap(
                      children: [
                        for (final k in tiles)
                          _CheckChip(
                            key: Key('tileChip-${k.name}'),
                            label: trackerLabel(l10n, k),
                            leading: ClArt(
                              trackerArt(k),
                              width: 18,
                              height: 18,
                            ),
                            selected: !draft.hiddenTiles.contains(k),
                            onTap: () => update(
                              cur().copyWith(
                                hiddenTiles: cur().hiddenTiles.contains(k)
                                    ? (cur().hiddenTiles.toSet()..remove(k))
                                    : (cur().hiddenTiles.toSet()..add(k)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    TodaySection.quickActions => _ChoiceWrap(
                      children: [
                        for (final a in actions)
                          _CheckChip(
                            key: Key('actionChip-${a.name}'),
                            label: quickActionLabel(l10n, a),
                            leading: QuickActionIcon(action: a, size: 18),
                            selected: !draft.hiddenActions.contains(a),
                            onTap: () => update(
                              cur().copyWith(
                                hiddenActions: cur().hiddenActions.contains(a)
                                    ? (cur().hiddenActions.toSet()..remove(a))
                                    : (cur().hiddenActions.toSet()..add(a)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    _ => null,
                  },
                ),
                const SizedBox(height: ClSpace.s4),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
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

/// The choices of a part, right under its row (owner, 2026-10-12: tick them there, no
/// separate list to scroll to).
class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(48, 0, ClSpace.s3, ClSpace.s3),
    child: Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: children,
    ),
  );
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface,
          border: Border.all(
            color: selected ? cl.colors.mintDeep : cl.colors.separator,
          ),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(
              selected ? ClIcons.check : ClIcons.plus,
              size: 14,
              color: selected ? cl.colors.mintText : cl.colors.inkMuted,
            ),
            const SizedBox(width: 6),
            if (leading != null) ...[
              Opacity(opacity: selected ? 1 : 0.5, child: leading!),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? cl.colors.mintText : cl.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rows with a switch, reordered by dragging the handle (at once) or anywhere on the row after
/// a long press; the lifted row floats with a shadow.
class _ReorderGroup<T extends Object> extends StatelessWidget {
  const _ReorderGroup({
    required this.items,
    required this.title,
    required this.isOn,
    required this.onToggle,
    required this.onReorder,
    this.subtitle,
    this.leading,
    this.below,
    this.dimmed = false,
    super.key,
  });

  final List<T> items;

  /// Shown under an item's row while it is on (its choices); moves with it when dragged.
  final Widget? Function(T)? below;
  final String Function(T) title;
  final String? Function(T)? subtitle;
  final Widget Function(T)? leading;
  final bool Function(T) isOn;
  final void Function(T, bool) onToggle;
  final void Function(int from, int to) onReorder;

  /// The part these belong to is off: still editable, shown faded.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget line(int i, T item) {
      final sub = subtitle?.call(item);
      return Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(0, 6, ClSpace.s3, 6),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: i,
              child: Semantics(
                label: l10n.a11yDragToReorder,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: _Handle(color: cl.colors.inkMuted)),
                ),
              ),
            ),
            if (leading != null) ...[
              leading!(item),
              const SizedBox(width: ClSpace.s3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title(item), style: cl.text.body),
                  if (sub != null)
                    Text(
                      sub,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClToggle(
              value: isOn(item),
              semanticLabel: title(item),
              onChanged: (on) => onToggle(item, on),
            ),
          ],
        ),
      );
    }

    Widget row(int i, T item) {
      final extra = isOn(item) ? below?.call(item) : null;
      return AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [line(i, item), ?extra],
        ),
      );
    }

    return AnimatedOpacity(
      opacity: dimmed ? 0.55 : 1,
      duration: const Duration(milliseconds: 150),
      child: Container(
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
          onReorderItem: onReorder,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final t = Curves.easeOut.transform(animation.value);
              return Transform.scale(
                scale: 1 + 0.02 * t,
                child: Material(
                  color: cl.colors.surface,
                  elevation: 8 * t,
                  shadowColor: cl.colors.ink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
              );
            },
            child: child,
          ),
          children: [
            for (final (i, item) in items.indexed)
              ReorderableDelayedDragStartListener(
                key: ValueKey(item),
                index: i,
                child: Material(color: cl.colors.surface, child: row(i, item)),
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

String quickActionLabel(AppLocalizations l10n, QuickAction a) => switch (a) {
  QuickAction.reminder => l10n.quickReminder,
  QuickAction.expense => l10n.quickExpense,
  QuickAction.vaccine => l10n.quickVaccine,
  QuickAction.memory => l10n.quickMemory,
};

String quickActionHint(AppLocalizations l10n, QuickAction a) => switch (a) {
  QuickAction.reminder => l10n.quickReminderHint,
  QuickAction.expense => l10n.quickExpenseHint,
  QuickAction.vaccine => l10n.quickVaccineHint,
  QuickAction.memory => l10n.quickMemoryHint,
};

/// A shortcut's tinted icon chip (the tint of its feature tile on Chăm sóc).
class QuickActionIcon extends StatelessWidget {
  const QuickActionIcon({required this.action, this.size = 40, super.key});
  final QuickAction action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (icon, soft, ink) = switch (action) {
      QuickAction.reminder => (
        ClIcons.clock,
        cl.colors.mintSoft,
        cl.colors.mintText,
      ),
      QuickAction.expense => (
        ClIcons.grid,
        cl.care.growth.soft,
        cl.care.growth.ink,
      ),
      QuickAction.vaccine => (
        ClIcons.heart,
        cl.colors.peachSoft,
        cl.care.growth.ink,
      ),
      QuickAction.memory => (
        ClIcons.camera,
        cl.care.sleep.soft,
        cl.care.sleep.ink,
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: ClIcon(icon, size: size * 0.5, color: ink),
    );
  }
}
