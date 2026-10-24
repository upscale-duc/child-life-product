import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/product_analytics.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../memories/memory_repository.dart';
import '../today/today_layout.dart';
import 'adaptive_engine.dart';
import 'experience_repository.dart';

/// Phase E of the Adaptive Experience (plan §4.4, §4.8): the usage and recency signals of the
/// ranking, the MET-01 events and the AX33 stage card.

// ---------- MET-01 (closed events, `adaptiveEvents` / `adaptiveDetails`) ----------

/// Sends one adaptive observation through the MET-01 outbox (the server drops it while
/// `product_analytics` is off for the family); never a name, date of birth or free text.
void reportAdaptive(
  WidgetRef ref,
  BuildContext context,
  String event,
  String detail, {
  String? babyId,
}) {
  final reporter = ref.read(productAnalyticsReporterProvider);
  final baby = babyId ?? ref.read(selectedMembershipProvider)?.babyId;
  if (reporter == null || baby == null) return;
  final language = Localizations.localeOf(context).languageCode;
  unawaited(
    reporter.observe(
      event,
      babyId: baby,
      detail: detail,
      platform: productAnalyticsPlatform,
      locale: language == 'en' || language == 'vi' ? language : 'other',
    ),
  );
}

/// The MET-01 "adaptive_customized" details for what AX14's "Xong" changed.
List<String> customizeDetails(Experience before, Experience after) => [
  if (after.pinned.any((w) => !before.pinned.contains(w))) 'pin',
  if (before.pinned.any((w) => !after.pinned.contains(w))) 'unpin',
  if (after.hidden.any((w) => !before.hidden.contains(w))) 'hide',
  if (after.shown.any((w) => !before.shown.contains(w)) ||
      before.hidden.any((w) => !after.hidden.contains(w)))
    'show',
  if (after.order.isNotEmpty && !_sameList(after.order, before.order))
    'reorder',
  if (!_sameList(after.goals, before.goals)) 'goals',
  if (after.order.isEmpty &&
      before.order.isNotEmpty &&
      after.hidden.isEmpty &&
      before.hidden.isNotEmpty)
    'restore',
];

bool _sameList<T>(List<T> a, List<T> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

// ---------- Usage (this person, this child, 28 days, on the phone) ----------

/// Taps on a Hôm nay widget, per day, kept on this phone for 28 days (never uploaded; the
/// MET-01 event carries only the widget id).
class UsageStore {
  UsageStore(this._read, this._write);
  final String? Function(String key) _read;
  final void Function(String key, String value) _write;

  static const days = 28;
  static String keyFor(String uid, String babyId) => 'usage.$uid.$babyId';

  static int _day(DateTime at) =>
      DateTime.utc(at.year, at.month, at.day).millisecondsSinceEpoch ~/
      86400000;

  Map<String, List<int>> _load(String key) {
    try {
      final raw = _read(key);
      if (raw == null) return {};
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          '${e.key}': [for (final d in e.value as List) d as int],
      };
    } on Object {
      return {};
    }
  }

  void record(String uid, String babyId, WidgetId id, DateTime now) {
    final key = keyFor(uid, babyId);
    final today = _day(now);
    final all = _load(key);
    all[id.wire] = [...?all[id.wire]?.where((d) => today - d < days), today];
    _write(key, jsonEncode(all));
  }

  /// 0–1 per widget: taps over the last 28 days against the most-tapped widget.
  Map<WidgetId, double> usage(String uid, String babyId, DateTime now) {
    final today = _day(now);
    final counts = <WidgetId, int>{
      for (final e in _load(keyFor(uid, babyId)).entries)
        if (WidgetId.fromWire(e.key) case final WidgetId id)
          id: e.value.where((d) => today - d < days).length,
    };
    final top = counts.values.fold(0, (a, b) => a > b ? a : b);
    if (top == 0) return const {};
    return {for (final e in counts.entries) e.key: e.value / top};
  }
}

final usageStoreProvider = Provider<UsageStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UsageStore(prefs.getString, (k, v) => prefs.setString(k, v).ignore());
});

/// Records a tap on [id] and the MET-01 "adaptive_widget_opened".
void recordWidgetTap(WidgetRef ref, BuildContext context, WidgetId id) {
  final me = ref.read(selectedMembershipProvider);
  if (me == null) return;
  try {
    ref.read(usageStoreProvider).record(me.uid, me.babyId, id, DateTime.now());
  } on Object {
    // No preferences (tests).
  }
  reportAdaptive(ref, context, 'adaptive_widget_opened', id.wire);
}

/// Wraps a ranked Hôm nay widget so a tap in it counts as using it. A scroll that ends on the
/// widget is not a tap: the finger must stay within [slop] and lift within [maxPress].
class AdaptiveTapTracker extends ConsumerStatefulWidget {
  const AdaptiveTapTracker({required this.id, required this.child, super.key});
  final WidgetId id;
  final Widget child;

  static const slop = 12.0;
  static const maxPress = Duration(milliseconds: 600);

  @override
  ConsumerState<AdaptiveTapTracker> createState() => _AdaptiveTapTrackerState();
}

class _AdaptiveTapTrackerState extends ConsumerState<AdaptiveTapTracker> {
  Offset? _down;
  DateTime? _at;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _down = e.position;
      _at = DateTime.now();
    },
    onPointerMove: (e) {
      if (_down != null &&
          (e.position - _down!).distance > AdaptiveTapTracker.slop) {
        _down = null;
      }
    },
    onPointerCancel: (_) => _down = null,
    onPointerUp: (e) {
      final down = _down, at = _at;
      _down = null;
      if (down == null || at == null) return;
      if ((e.position - down).distance > AdaptiveTapTracker.slop) return;
      if (DateTime.now().difference(at) > AdaptiveTapTracker.maxPress) return;
      recordWidgetTap(ref, context, widget.id);
    },
    child: widget.child,
  );
}

// ---------- Ranking signals, frozen for the visit ----------

/// The usage and the last 48 h of activity, read once per child per app run, so Hôm nay never
/// reshuffles under the finger (a log or a tap moves things on the next visit).
final rankSignalsProvider =
    NotifierProvider.family<RankSignalsNotifier, RankSignals, String>(
      RankSignalsNotifier.new,
    );

class RankSignalsNotifier extends Notifier<RankSignals> {
  RankSignalsNotifier(this.babyId);
  final String babyId;
  RankSignals? _frozen;

  @override
  RankSignals build() {
    if (_frozen case final f?) return f;
    final me = ref.watch(selectedMembershipProvider);
    final records = ref.watch(recentRecordsProvider(babyId));
    final growth = ref.watch(growthRecordsProvider(babyId));
    final media = ref.watch(
      mediaProvider((babyId, me?.role == MemberRole.coParent)),
    );
    if (me == null ||
        !records.hasValue ||
        !growth.hasValue ||
        !media.hasValue) {
      return const RankSignals();
    }
    final now = DateTime.now();
    bool recent(DateTime at) => now.difference(at).inHours < 48;
    Map<WidgetId, double> usage;
    try {
      usage = ref.read(usageStoreProvider).usage(me.uid, babyId, now);
    } on Object {
      usage = const {};
    }
    return _frozen = RankSignals(
      usage: usage,
      recent: {
        if (records.value!.any((r) => recent(r.occurredAt))) WidgetId.tiles,
        if (growth.value!.any((r) => recent(r.occurredAt))) WidgetId.growth,
        if (media.value!.any((m) => recent(m.captureAt))) ...{
          WidgetId.recentMemories,
          WidgetId.momentToday,
        },
      },
    );
  }
}

// ---------- AX33 "{tên} tròn 1 tuổi rồi!" ----------

/// The options of the stage card for [milestone], pre-ticked (AX33). Engineering wording for 36
/// and 72 months (only 12 is drawn, G-110).
enum StageOption {
  leadNewBand,
  hideFeeds,
  keepSleepDiaper,
  hideQuickLog,
  keepGrowth,
}

List<StageOption> stageOptions(int milestone) => switch (milestone) {
  12 => const [
    StageOption.leadNewBand,
    StageOption.hideFeeds,
    StageOption.keepSleepDiaper,
  ],
  36 => const [StageOption.leadNewBand, StageOption.hideQuickLog],
  _ => const [StageOption.leadNewBand, StageOption.keepGrowth],
};

/// "Áp dụng" with [picked]: suggests, never moves data; undo is in Tuỳ chỉnh Hôm nay. Feeds are
/// hidden from the quick log on this phone only (the child's trackers are the family's).
({Experience exp, Set<TrackerKind> hideTiles}) applyStage(
  Experience exp,
  int milestone,
  Set<StageOption> picked,
) {
  var next = exp.copyWith(
    stagePrompts: {...exp.stagePrompts, milestone: StageAnswer.applied},
  );
  if (picked.contains(StageOption.leadNewBand)) {
    next = applyBand(next, ageBandFor(milestone));
  }
  if (picked.contains(StageOption.hideQuickLog)) {
    next = next.copyWith(hidden: {...next.hidden, WidgetId.tiles}.toList());
  }
  if (picked.contains(StageOption.keepGrowth)) {
    next = next.copyWith(
      shown: {...next.shown, WidgetId.growth}.toList(),
      hidden: [...next.hidden.where((w) => w != WidgetId.growth)],
    );
  }
  return (
    exp: next,
    hideTiles: {
      if (picked.contains(StageOption.hideFeeds)) ...{
        TrackerKind.bottle,
        TrackerKind.breast,
        TrackerKind.pump,
      },
      if (milestone == 12 && !picked.contains(StageOption.keepSleepDiaper)) ...{
        TrackerKind.sleep,
        TrackerKind.diaper,
      },
    },
  );
}

class AxStageCard extends ConsumerStatefulWidget {
  const AxStageCard({super.key});

  @override
  ConsumerState<AxStageCard> createState() => _AxStageCardState();
}

class _AxStageCardState extends ConsumerState<AxStageCard> {
  Set<StageOption>? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    // The arrangement is the person's; relatives have no Tuỳ chỉnh.
    if (me == null || me.role == MemberRole.relative) {
      return const SizedBox.shrink();
    }
    final months = ref.watch(childMonthsProvider(me.babyId));
    final exp = ref.watch(experienceProvider(me.babyId));
    final milestone = months == null ? null : stagePromptDue(exp, months);
    if (milestone == null) return const SizedBox.shrink();
    final name = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
    final options = stageOptions(milestone);
    final picked = _picked ?? options.toSet();
    String label(StageOption o) => switch (o) {
      StageOption.leadNewBand => switch (milestone) {
        12 => l10n.axStageLeadMemories,
        36 => l10n.axStageLeadMoment,
        _ => l10n.axStageLeadJournal,
      },
      StageOption.hideFeeds => l10n.axStageHideFeeds,
      StageOption.keepSleepDiaper => l10n.axStageKeepSleep,
      StageOption.hideQuickLog => l10n.axStageHideQuickLog,
      StageOption.keepGrowth => l10n.axStageKeepGrowth,
    };

    void answer({required bool apply}) {
      final notifier = ref.read(experienceProvider(me.babyId).notifier);
      if (apply) {
        final r = applyStage(exp, milestone, picked);
        notifier.set(r.exp);
        if (r.hideTiles.isNotEmpty) {
          final layouts = ref.read(todayLayoutProvider(me.babyId).notifier);
          final layout = ref.read(todayLayoutProvider(me.babyId));
          layouts.set(
            layout.copyWith(
              hiddenTiles: {...layout.hiddenTiles, ...r.hideTiles},
            ),
          );
        }
      } else {
        notifier.set(
          exp.copyWith(
            stagePrompts: {...exp.stagePrompts, milestone: StageAnswer.kept},
          ),
        );
      }
      reportAdaptive(
        ref,
        context,
        'adaptive_stage_answered',
        apply ? 'applied' : 'kept',
      );
    }

    return Container(
      key: const Key('axStageCard'),
      margin: const EdgeInsets.only(top: ClSpace.s4),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🎂  ${switch (milestone) {
              12 => l10n.axStageTitle1(name),
              36 => l10n.axStageTitle3(name),
              _ => l10n.axStageTitle6(name),
            }}',
            // Ink on the soft warm fill (Night care, memory note).
            style: cl.text.bodyStrong.copyWith(
              fontSize: 17,
              color: cl.colors.ink,
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            milestone == 12 ? l10n.axStageBody1 : l10n.axStageBodyLater,
            style: cl.text.caption.copyWith(fontSize: 13, color: cl.colors.ink),
          ),
          const SizedBox(height: ClSpace.s2),
          for (final o in options)
            Semantics(
              checked: picked.contains(o),
              child: InkWell(
                key: ValueKey('stage_${o.name}'),
                onTap: () => setState(
                  () => _picked = picked.contains(o)
                      ? ({...picked}..remove(o))
                      : {...picked, o},
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: picked.contains(o) ? cl.colors.mintDeep : null,
                          borderRadius: BorderRadius.circular(7),
                          border: picked.contains(o)
                              ? null
                              : Border.all(
                                  color: cl.colors.controlBorder,
                                  width: 1.5,
                                ),
                        ),
                        child: picked.contains(o)
                            ? ClIcon(
                                ClIcons.check,
                                size: 14,
                                color: cl.colors.onMintDeep,
                              )
                            : null,
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(
                          label(o),
                          style: cl.text.caption.copyWith(
                            fontSize: 13,
                            color: cl.colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(
                child: ClButton(
                  key: const Key('axStageApply'),
                  label: l10n.axStageApply,
                  expand: true,
                  onPressed: () => answer(apply: true),
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: ClButton(
                  key: const Key('axStageKeep'),
                  label: l10n.axStageKeep,
                  style: ClButtonStyle.secondary,
                  expand: true,
                  onPressed: () => answer(apply: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
