import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memory_models.dart';

/// MM10 "Chọn dịp" (D-068; `occasions` in `packages/contracts/src/keepsakes.ts`). Age occasions
/// (cake) are counted from the date of birth; first-time occasions (heart, star) take the date of
/// the newest memory tagged with their milestone, else today. The saved card is tagged with the
/// occasion's preset milestone.
enum Occasion {
  d7('d7', 'p_seven_days', days: 7),
  m1('m1', 'p_one_month', months: 1),
  d100('d100', 'p_hundred_days', days: 100),
  firstSmile('first_smile', 'p_first_smile'),
  rollsOver('rolls_over', 'p_rolls_over'),
  crawls('crawls', 'p_crawls'),
  firstSteps('first_steps', 'p_first_steps'),
  y1('y1', 'p_first_birthday', months: 12),
  // Chapter 01 set (E-7): offered in MM10 when they fit the baby; never nudged (D-068 #9).
  birth('birth', 'p_birth', days: 0),
  m2('m2', 'p_month_2', months: 2),
  m3('m3', 'p_month_3', months: 3),
  m4('m4', 'p_month_4', months: 4),
  m5('m5', 'p_month_5', months: 5),
  m6('m6', 'p_month_6', months: 6),
  m7('m7', 'p_month_7', months: 7),
  m8('m8', 'p_month_8', months: 8),
  m9('m9', 'p_month_9', months: 9),
  m10('m10', 'p_month_10', months: 10),
  m11('m11', 'p_month_11', months: 11),
  laughs('laughs', 'p_laughs'),
  sitsUp('sits_up', 'p_sits_up'),
  stands('stands', 'p_stands'),
  firstTooth('first_tooth', 'p_first_tooth'),
  firstSolids('first_solids', 'p_first_solids'),
  firstWord('first_word', 'p_first_word');

  /// The occasions with milestone nudges (D-068 #9) and always shown in MM10.
  static const nudged = [
    d7,
    m1,
    d100,
    firstSmile,
    rollsOver,
    crawls,
    firstSteps,
    y1,
  ];

  /// MM10's order: by age, then the first-time ones.
  static const _chipOrder = [
    birth, d7, m1, m2, m3, d100, m4, m5, m6, m7, m8, m9, m10, m11, y1, //
    firstSmile,
    laughs,
    rollsOver,
    sitsUp,
    crawls,
    firstTooth,
    firstSolids,
    stands,
    firstWord,
    firstSteps,
  ];

  /// Typical weeks of age for a first-time occasion (from the Kỷ niệm milestone presets).
  ({int from, int to})? get _weeks => switch (this) {
    laughs => (from: 8, to: 26),
    sitsUp => (from: 20, to: 44),
    stands => (from: 32, to: 60),
    firstTooth => (from: 20, to: 60),
    firstSolids => (from: 20, to: 40),
    firstWord => (from: 36, to: 104),
    _ => null,
  };

  /// MM10 chips for this baby: the nudged set, plus the Chapter 01 occasions that fit now (birth
  /// in the first two months, the current month, first-time ones in their usual weeks or already
  /// tagged), plus [current].
  static List<Occasion> chipsFor(
    DateTime dob,
    DateTime today,
    Iterable<MilestoneRef> tagged, {
    Occasion? current,
  }) {
    final t = DateTime(today.year, today.month, today.day);
    final ageDays = t.difference(DateTime(dob.year, dob.month, dob.day)).inDays;
    final ids = {for (final m in tagged) m.id};
    bool fits(Occasion o) {
      if (nudged.contains(o) || o == current) return true;
      if (o == birth) return ageDays <= 60;
      if (o.months != null) {
        final gap = o.dateFor(dob, const [])!.difference(t).inDays;
        return gap <= 14 && gap >= -30;
      }
      final w = o._weeks;
      return ids.contains(o.milestoneId) ||
          (w != null && ageDays >= w.from * 7 && ageDays <= w.to * 7);
    }

    return [
      for (final o in _chipOrder)
        if (fits(o)) o,
    ];
  }

  const Occasion(this.wire, this.milestoneId, {this.days, this.months});
  final String wire;
  final String milestoneId;
  final int? days;
  final int? months;

  bool get byAge => days != null || months != null;

  ClIcons get icon => switch (this) {
    Occasion.firstSmile || Occasion.laughs => ClIcons.heart,
    _ when byAge => ClIcons.cake,
    _ => ClIcons.star,
  };

  static Occasion? fromWire(String? w) =>
      values.where((o) => o.wire == w).firstOrNull;

  /// The chip label ("1 tháng", "Sinh nhật 1 tuổi").
  String label(AppLocalizations l10n) => switch (this) {
    Occasion.d7 => l10n.ksOccD7,
    Occasion.m1 => l10n.ksOccM1,
    Occasion.d100 => l10n.ksOccD100,
    Occasion.firstSmile => l10n.ksOccFirstSmile,
    Occasion.rollsOver => l10n.ksOccRollsOver,
    Occasion.crawls => l10n.ksOccCrawls,
    Occasion.firstSteps => l10n.ksOccFirstSteps,
    Occasion.y1 => l10n.ksOccY1,
    Occasion.birth => l10n.ksOccBirth,
    Occasion.laughs => l10n.ksOccLaughs,
    Occasion.sitsUp => l10n.ksOccSitsUp,
    Occasion.stands => l10n.ksOccStands,
    Occasion.firstTooth => l10n.ksOccFirstTooth,
    Occasion.firstSolids => l10n.ksOccFirstSolids,
    Occasion.firstWord => l10n.ksOccFirstWord,
    _ => l10n.ksOccMonth(months!),
  };

  /// C08 "Look what I can do!": the achievement in the baby's voice ("Con biết lẫy rồi!").
  String achievement(AppLocalizations l10n) => switch (this) {
    Occasion.rollsOver => l10n.ksAchieveRollsOver,
    Occasion.sitsUp => l10n.ksAchieveSitsUp,
    Occasion.crawls => l10n.ksAchieveCrawls,
    Occasion.stands => l10n.ksAchieveStands,
    Occasion.firstSteps => l10n.ksAchieveFirstSteps,
    _ => l10n.ksAchieveAny,
  };

  /// The big words on the card ("1 tháng", "1 tuổi").
  String title(AppLocalizations l10n) =>
      this == Occasion.y1 ? l10n.ksTitleY1 : label(l10n);

  /// The default "Lời nhắn" (MM11 "Một tháng yêu thương").
  String quote(AppLocalizations l10n) => switch (this) {
    Occasion.d7 => l10n.ksQuoteD7,
    Occasion.m1 => l10n.ksQuoteM1,
    Occasion.d100 => l10n.ksQuoteD100,
    Occasion.firstSmile => l10n.ksQuoteFirstSmile,
    Occasion.rollsOver => l10n.ksQuoteRollsOver,
    Occasion.crawls => l10n.ksQuoteCrawls,
    Occasion.firstSteps => l10n.ksQuoteFirstSteps,
    Occasion.y1 => l10n.ksQuoteY1,
    Occasion.birth => l10n.ksQuoteBirth,
    Occasion.laughs => l10n.ksQuoteLaughs,
    Occasion.sitsUp => l10n.ksQuoteSitsUp,
    Occasion.stands => l10n.ksQuoteStands,
    Occasion.firstTooth => l10n.ksQuoteFirstTooth,
    Occasion.firstSolids => l10n.ksQuoteFirstSolids,
    Occasion.firstWord => l10n.ksQuoteFirstWord,
    _ => l10n.ksQuoteMonth(months!),
  };

  /// The calendar day of an age occasion, or the newest tagged memory's day for a first-time
  /// one (null when none is tagged).
  DateTime? dateFor(DateTime dob, Iterable<MilestoneRef> tagged) {
    final b = DateTime(dob.year, dob.month, dob.day);
    if (days != null) return DateTime(b.year, b.month, b.day + days!);
    if (months != null) {
      // 31 Jan + 1 month = 28/29 Feb, not 3 Mar.
      final first = DateTime(b.year, b.month + months!);
      final last = DateTime(first.year, first.month + 1, 0).day;
      return DateTime(first.year, first.month, b.day > last ? last : b.day);
    }
    DateTime? newest;
    for (final m in tagged) {
      if (m.id == milestoneId && (newest == null || m.date.isAfter(newest))) {
        newest = m.date;
      }
    }
    return newest;
  }
}

/// "Gợi ý" (MM10): the main age occasion (7 ngày, 1 tháng, 100 ngày, 1 tuổi) closest to today
/// within 14 days ahead or 30 days back; else such a monthly one; else the next age occasion still
/// to come; else the first birthday.
Occasion suggestedOccasion(DateTime dob, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  Occasion? closest(Iterable<Occasion> from) {
    Occasion? best;
    var bestGap = 1 << 30;
    for (final o in from.where((o) => o.byAge)) {
      final gap = o.dateFor(dob, const [])!.difference(t).inDays;
      if (gap <= 14 && gap >= -30 && gap.abs() < bestGap) {
        best = o;
        bestGap = gap.abs();
      }
    }
    return best;
  }

  final near = closest(Occasion.nudged) ?? closest(Occasion.values);
  if (near != null) return near;
  Occasion? next;
  for (final o in Occasion.values.where((o) => o.byAge)) {
    final day = o.dateFor(dob, const [])!;
    if (!day.isBefore(t) &&
        (next == null || day.isBefore(next.dateFor(dob, const [])!))) {
      next = o;
    }
  }
  return next ?? Occasion.y1;
}
