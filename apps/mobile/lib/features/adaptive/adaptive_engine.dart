import 'package:flutter/foundation.dart';

/// Adaptive Experience (Figma 930:11858, AX00–AX45; `docs/product/adaptive-experience-plan.md`).
/// One app and one nav for every age: the child's age band + the person's goals only ORDER what
/// V1 already has and set the "Gợi ý cho …" labels. Nothing is locked by age (AX00 rule 1), and a
/// birthday never hides anything by itself (rule 5, AX33). Mirrors
/// `packages/contracts/src/adaptive.ts` on the same fixtures.

enum AgeBand { b0_1, b1_3, b3_6, b6_12 }

/// AX33: the stage card is offered once at each of these ages (months).
const stageMilestones = [12, 36, 72];

/// Whole calendar months from [dob] to [today], both local calendar dates of the child (AX00 rule
/// 7: in the child's time zone; the caller converts).
int ageInMonths(DateTime dob, DateTime today) {
  var months = (today.year - dob.year) * 12 + today.month - dob.month;
  // A birthday on the 31st counts from the month's last day in shorter months.
  final lastDay = DateTime.utc(today.year, today.month + 1, 0).day;
  if (today.day < (dob.day < lastDay ? dob.day : lastDay)) months -= 1;
  return months < 0 ? 0 : months;
}

/// 0–1 under 12 months, 1–3 to 35, 3–6 to 71, then 6–12 (open-ended until a later chapter, Q-094).
AgeBand ageBandFor(int months) => months < 12
    ? AgeBand.b0_1
    : months < 36
    ? AgeBand.b1_3
    : months < 72
    ? AgeBand.b3_6
    : AgeBand.b6_12;

/// The latest stage milestone reached, or null before 12 months.
int? milestoneReached(int months) {
  int? reached;
  for (final m in stageMilestones) {
    if (months >= m) reached = m;
  }
  return reached;
}

/// AX03 / AX04 "Bạn muốn Child Life giúp gì cho …?". Wire names are the contract's.
enum Goal {
  trackCare('track_care'),
  memories('memories'),
  growthVaccines('growth_vaccines'),
  family('family'),
  spending('spending'),
  reminders('reminders');

  const Goal(this.wire);
  final String wire;

  static Goal? fromWire(Object? w) {
    for (final g in values) {
      if (g.wire == w) return g;
    }
    return null;
  }
}

/// AX00 "Mục tiêu gợi ý sẵn": pre-ticked, badge "Gợi ý cho {tuổi}".
const presetGoals = <AgeBand, List<Goal>>{
  AgeBand.b0_1: [Goal.trackCare, Goal.memories],
  AgeBand.b1_3: [Goal.memories, Goal.growthVaccines],
  AgeBand.b3_6: [Goal.memories, Goal.spending, Goal.family],
  AgeBand.b6_12: [Goal.memories, Goal.reminders, Goal.spending],
};

/// The goal list as AX03/AX04 show it: the band's presets first, then the rest.
List<Goal> goalOrder(AgeBand band) => [
  ...presetGoals[band]!,
  ...Goal.values.where((g) => !presetGoals[band]!.contains(g)),
];

/// Hôm nay widgets. The first eight keep the names of `TodaySection` so saved layouts map one to
/// one; the rest are the AX10–AX13 widgets. Wire names are the contract's.
enum WidgetId {
  tiles('tiles', [Goal.trackCare]),
  forYou('forYou', [Goal.trackCare]),
  solids('solids', [Goal.trackCare]),
  reminders('reminders', [Goal.reminders]),
  quickActions('quickActions', []),
  vaccine('vaccine', [Goal.growthVaccines]),
  spending('spending', [Goal.spending]),
  rhythm('rhythm', []),
  recentMemories('recent_memories', [Goal.memories]),
  momentToday('moment_today', [Goal.memories]),
  createFromMemories('create_from_memories', [Goal.memories]),
  growth('growth', [Goal.growthVaccines]),
  familyView('family_view', [Goal.family]),

  /// P-181 "Ai đang trông bé": the chip under the title (rendered there, not in the list). On by
  /// age up to 6 (bé cần người trông và bàn giao nhiều), from 6 only with the Gia đình goal or
  /// the person's own switch (owner, 2026-10-25).
  careDuty('care_duty', [Goal.family]);

  const WidgetId(this.wire, this.goals);
  final String wire;

  /// Goals this widget serves ("Vì: …", "Theo mục tiêu …"); none = "Luôn có".
  final List<Goal> goals;

  /// Product priority 0–1 (AX00 weight 10 %). All 0 at launch.
  double get product => 0;

  static WidgetId? fromWire(Object? w) {
    for (final id in values) {
      if (id.wire == w) return id;
    }
    return null;
  }
}

/// AX00 "Hôm nay · thứ tự mặc định", with the existing sections in their D-076 places. These
/// lists already encode the band's preset goals.
const bandDefaults = <AgeBand, List<WidgetId>>{
  AgeBand.b0_1: [
    WidgetId.tiles,
    WidgetId.forYou,
    WidgetId.solids,
    WidgetId.reminders,
    WidgetId.recentMemories,
    WidgetId.growth,
    WidgetId.careDuty,
  ],
  AgeBand.b1_3: [
    WidgetId.recentMemories,
    WidgetId.tiles,
    WidgetId.forYou,
    WidgetId.solids,
    WidgetId.reminders,
    WidgetId.growth,
    WidgetId.careDuty,
  ],
  AgeBand.b3_6: [
    WidgetId.momentToday,
    WidgetId.createFromMemories,
    WidgetId.spending,
    WidgetId.reminders,
    WidgetId.familyView,
    WidgetId.careDuty,
  ],
  AgeBand.b6_12: [
    WidgetId.recentMemories,
    WidgetId.reminders,
    WidgetId.spending,
    WidgetId.growth,
  ],
};

/// AX00 weights, "trọng số khởi tạo để thử nghiệm".
abstract final class RankWeights {
  static const goal = 0.35;
  static const age = 0.25;
  static const usage = 0.2;
  static const recent = 0.1;
  static const product = 0.1;
}

enum GoalsSource { chosen, skipped, migrated }

enum StageAnswer { applied, kept }

/// The person's arrangement of one child's Hôm nay, `users/{uid}/experience/{babyId}` (P-175).
@immutable
class Experience {
  const Experience({
    required this.goals,
    required this.goalsSource,
    required this.bandApplied,
    this.order = const [],
    this.pinned = const [],
    this.shown = const [],
    this.hidden = const [],
    this.stagePrompts = const {},
  });

  factory Experience.defaults(
    AgeBand band, {
    GoalsSource source = GoalsSource.skipped,
  }) => Experience(
    goals: presetGoals[band]!,
    goalsSource: source,
    bandApplied: band,
  );

  final List<Goal> goals;
  final GoalsSource goalsSource;

  /// The band whose defaults are in force. Changes only on "Áp dụng" (AX33), "Khôi phục gợi ý
  /// theo tuổi" (AX14) or a goal edit, never on a birthday alone.
  final AgeBand bandApplied;

  /// The person's own order; empty = ranked.
  final List<WidgetId> order;

  /// "Ghim · luôn ở đầu", in pin order.
  final List<WidgetId> pinned;

  /// Turned on although hidden by default.
  final List<WidgetId> shown;

  /// Turned off; never comes back by itself.
  final List<WidgetId> hidden;

  /// Milestone (12, 36, 72) → the person's answer to AX33.
  final Map<int, StageAnswer> stagePrompts;

  Experience copyWith({
    List<Goal>? goals,
    GoalsSource? goalsSource,
    AgeBand? bandApplied,
    List<WidgetId>? order,
    List<WidgetId>? pinned,
    List<WidgetId>? shown,
    List<WidgetId>? hidden,
    Map<int, StageAnswer>? stagePrompts,
  }) => Experience(
    goals: goals ?? this.goals,
    goalsSource: goalsSource ?? this.goalsSource,
    bandApplied: bandApplied ?? this.bandApplied,
    order: order ?? this.order,
    pinned: pinned ?? this.pinned,
    shown: shown ?? this.shown,
    hidden: hidden ?? this.hidden,
    stagePrompts: stagePrompts ?? this.stagePrompts,
  );

  /// The Firestore document for [babyId] (without `updatedAt`, which the repository sets).
  Map<String, Object?> toJson(String babyId) => {
    'v': 1,
    'babyId': babyId,
    'goals': [for (final g in goals) g.wire],
    'goalsSource': goalsSource.name,
    'bandApplied': bandApplied.name,
    'order': [for (final w in order) w.wire],
    'pinned': [for (final w in pinned) w.wire],
    'shown': [for (final w in shown) w.wire],
    'hidden': [for (final w in hidden) w.wire],
    'stagePrompts': {
      for (final e in stagePrompts.entries) 'm${e.key}': e.value.name,
    },
  };

  /// Unknown ids (from a newer app) are dropped rather than failing the whole arrangement.
  static Experience? fromJson(Map<String, Object?> j) {
    final band = AgeBand.values.asNameMap()[j['bandApplied']];
    if (band == null) return null;
    List<WidgetId> ids(Object? v) => [
      for (final w in (v is List ? v : const []))
        if (WidgetId.fromWire(w) case final WidgetId id) id,
    ];
    final prompts = <int, StageAnswer>{};
    if (j['stagePrompts'] case final Map<Object?, Object?> m) {
      for (final e in m.entries) {
        final at = int.tryParse('${e.key}'.replaceFirst('m', ''));
        final answer = StageAnswer.values.asNameMap()[e.value];
        if (at != null && stageMilestones.contains(at) && answer != null) {
          prompts[at] = answer;
        }
      }
    }
    return Experience(
      goals: [
        for (final g in (j['goals'] is List ? j['goals']! as List : const []))
          if (Goal.fromWire(g) case final Goal goal) goal,
      ],
      goalsSource:
          GoalsSource.values.asNameMap()[j['goalsSource']] ??
          GoalsSource.chosen,
      bandApplied: band,
      order: ids(j['order']),
      pinned: ids(j['pinned']),
      shown: ids(j['shown']),
      hidden: ids(j['hidden']),
      stagePrompts: prompts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Experience &&
      listEquals(goals, other.goals) &&
      goalsSource == other.goalsSource &&
      bandApplied == other.bandApplied &&
      listEquals(order, other.order) &&
      listEquals(pinned, other.pinned) &&
      listEquals(shown, other.shown) &&
      listEquals(hidden, other.hidden) &&
      mapEquals(stagePrompts, other.stagePrompts);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(goals),
    goalsSource,
    bandApplied,
    Object.hashAll(order),
    Object.hashAll(pinned),
    Object.hashAll(shown),
    Object.hashAll(hidden),
    Object.hashAllUnordered(stagePrompts.entries.map((e) => (e.key, e.value))),
  );
}

/// Why a widget is on Hôm nay ("Vì: …", "Theo mục tiêu …") or hidden ("Ẩn theo gợi ý tuổi").
sealed class WidgetReason {
  const WidgetReason();
}

class ReasonGoal extends WidgetReason {
  const ReasonGoal(this.goal);
  final Goal goal;
  @override
  bool operator ==(Object other) => other is ReasonGoal && other.goal == goal;
  @override
  int get hashCode => goal.hashCode;
}

class ReasonAge extends WidgetReason {
  const ReasonAge();
}

/// "Vì: Luôn có".
class ReasonAlways extends WidgetReason {
  const ReasonAlways();
}

class ReasonPinned extends WidgetReason {
  const ReasonPinned();
}

@immutable
class RankedWidget {
  const RankedWidget({
    required this.id,
    required this.visible,
    required this.pinned,
    required this.reason,
    required this.score,
  });
  final WidgetId id;
  final bool visible;
  final bool pinned;
  final WidgetReason reason;
  final double score;
}

/// Ranking inputs beyond age and goals: [usage] 0–1 per widget (this person's opens of its
/// module over 28 days, normalised), [recent] widgets whose module had activity in 48 h.
@immutable
class RankSignals {
  const RankSignals({this.usage = const {}, this.recent = const {}});
  final Map<WidgetId, double> usage;
  final Set<WidgetId> recent;
}

/// [explicit]: the person ticked the goals (AX03/AX04 or "Sửa"). Then every ticked goal counts
/// the same; before that (skipped, migrated) the goal term is relative to the band's presets, so
/// Hôm nay is exactly the AX00 default (D-097 Q-087). Owner, 2026-10-24: a 17-month-old's ticked
/// "Lưu giữ kỷ niệm" and "Tăng trưởng & tiêm chủng" ranked last, under the goals added to them.
double scoreWidget(
  WidgetId id,
  AgeBand band,
  List<Goal> chosen, [
  RankSignals signals = const RankSignals(),
  bool explicit = false,
]) {
  bool serves(List<Goal> gs) => id.goals.any(gs.contains);
  final goal = explicit
      ? (serves(chosen) ? 1 : 0)
      : (serves(chosen) ? 1 : 0) - (serves(presetGoals[band]!) ? 1 : 0);
  final list = bandDefaults[band]!;
  final at = list.indexOf(id);
  final age = at < 0 ? 0.0 : 1 - at / list.length;
  final usage = (signals.usage[id] ?? 0).clamp(0.0, 1.0);
  final recent = signals.recent.contains(id) ? 1 : 0;
  return RankWeights.goal * goal +
      RankWeights.age * age +
      RankWeights.usage * usage +
      RankWeights.recent * recent +
      RankWeights.product * id.product;
}

/// Shown unless the person changed it: in the band's default list, or serving a goal the person
/// added beyond the band's presets (the presets are already in the list).
bool defaultVisible(WidgetId id, AgeBand band, List<Goal> chosen) {
  final added = chosen.where((g) => !presetGoals[band]!.contains(g));
  return bandDefaults[band]!.contains(id) || id.goals.any(added.contains);
}

WidgetReason _reasonFor(WidgetId id, AgeBand band, List<Goal> chosen) {
  for (final g in id.goals) {
    if (chosen.contains(g)) return ReasonGoal(g);
  }
  if (bandDefaults[band]!.contains(id)) return const ReasonAge();
  return const ReasonAlways();
}

/// Hôm nay for one child. [available] = the widgets this viewer can have right now (released,
/// flag, role, capability, data such as trackers), decided by the caller; nothing else is listed.
/// Order: pinned (in pin order, never moved) → the person's manual order if any (widgets it does
/// not know follow it, by score, P-176) → otherwise by score. Hidden widgets come back with
/// `visible: false` so "Đã ẩn" can list them.
List<RankedWidget> rankToday(
  Experience exp,
  Iterable<WidgetId> available, [
  RankSignals signals = const RankSignals(),
]) {
  final band = exp.bandApplied;
  final defaults = bandDefaults[band]!;
  int tie(WidgetId id) {
    final at = defaults.indexOf(id);
    return (at < 0 ? defaults.length : at) * 100 + id.index;
  }

  final avail = [
    for (final id in WidgetId.values)
      if (available.contains(id)) id,
  ];
  final scored = {
    for (final id in avail)
      id: scoreWidget(
        id,
        band,
        exp.goals,
        signals,
        exp.goalsSource == GoalsSource.chosen,
      ),
  };
  int byScore(WidgetId a, WidgetId b) {
    final d = scored[b]!.compareTo(scored[a]!);
    return d != 0 ? d : tie(a) - tie(b);
  }

  final pinned = [
    for (final id in exp.pinned)
      if (scored.containsKey(id)) id,
  ];
  final rest = [
    for (final id in avail)
      if (!pinned.contains(id)) id,
  ];
  final List<WidgetId> ordered;
  if (exp.order.isNotEmpty) {
    final known = [
      for (final id in exp.order)
        if (rest.contains(id)) id,
    ];
    ordered = [
      ...known,
      ...rest.where((w) => !known.contains(w)).toList()..sort(byScore),
    ];
  } else {
    ordered = [...rest]..sort(byScore);
  }

  return [
    for (final id in [...pinned, ...ordered])
      RankedWidget(
        id: id,
        pinned: pinned.contains(id),
        visible: exp.shown.contains(id)
            ? true
            : exp.hidden.contains(id)
            ? false
            : pinned.contains(id) || defaultVisible(id, band, exp.goals),
        reason: pinned.contains(id)
            ? const ReasonPinned()
            : _reasonFor(id, band, exp.goals),
        score: scored[id]!,
      ),
  ];
}

/// AX33: the milestone to offer, when the child passed one the person has not answered and whose
/// band is newer than the one applied. Never changes anything by itself.
int? stagePromptDue(Experience exp, int months) {
  final m = milestoneReached(months);
  if (m == null || exp.stagePrompts.containsKey(m)) return null;
  return ageBandFor(m).index > exp.bandApplied.index ? m : null;
}

/// "Áp dụng" (AX33): the new band's defaults take over; pins and the person's hides survive, the
/// manual order resets. "Khôi phục gợi ý theo tuổi" (AX14, [restore]) also clears the hides.
Experience applyBand(Experience exp, AgeBand band, {bool restore = false}) =>
    exp.copyWith(
      bandApplied: band,
      order: const [],
      shown: const [],
      hidden: restore ? const [] : exp.hidden,
    );

/// P-177: a Today layout this device saved before (`today.layout.<babyId>`, P-061) becomes the
/// person's arrangement, so existing families see the same Hôm nay and are never onboarded again.
/// A saved layout means the person customised it: its order is kept as manual and its hides
/// (including the old opt-in defaults) stay hidden. Goals are the band's presets.
Experience migrateTodayLayout({
  required AgeBand band,
  required List<String> order,
  required Iterable<String> hidden,
}) {
  List<WidgetId> ids(Iterable<String> names) => [
    for (final n in names)
      if (WidgetId.fromWire(n) case final WidgetId id) id,
  ];
  return Experience(
    goals: presetGoals[band]!,
    goalsSource: GoalsSource.migrated,
    bandApplied: band,
    order: ids(order),
    hidden: ids(hidden),
  );
}
