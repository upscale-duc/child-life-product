import 'package:flutter/widgets.dart';

import '../library/content_models.dart'
    show LbReview, LbSource, LbText, lbDate, lbDefaultEmergency, lbFillDoc;

/// Dinh dưỡng theo giai đoạn (D-083, P-163; Figma 9a–9g; plan `docs/product/nutrition-plan.md`).
/// Editorial content written in the portal and published one document per item to
/// `contentNutritionStages`, `contentNutrients` and `contentNutritionRules` (shapes:
/// `contentNutritionStageSchema`, `contentNutrientSchema`, `contentNutritionRuleSchema` in
/// `packages/contracts/src/content.ts`, built on `packages/contracts/src/nutrition.ts`).
///
/// Parsed defensively: a malformed part is dropped on its own, an item missing its essentials
/// (id, age, title) is skipped, so an older app still shows the rest. Text is `{vi, en}`; the
/// literal `{name}` in any text stands for the baby's nickname ([nuText]). Nothing here is about a
/// child; the per-baby vitamin A record is `babies/{babyId}/nutrition/vitaminA`.

final _stageId = RegExp(r'^nst_[a-z0-9_]{2,40}$');
final _nutrientId = RegExp(r'^nut_[a-z0-9_]{2,40}$');
final _ruleId = RegExp(r'^nru_[a-z0-9_]{2,40}$');

/// `nutritionLimits.maxAgeMonths`: stages run on completed months up to 36 (the last ends at 37).
const nuMaxAgeMonths = 36;

/// `nutritionLimits.maxMl` / `maxFeeds`.
const _maxMl = 2000;
const _maxFeeds = 16;

/// The picked language of [t] with `{name}` replaced by [name] (empty when [t] is null).
String nuText(LbText? t, Locale locale, String name) =>
    t == null ? '' : t.pick(locale).replaceAll('{name}', name);

/// Completed months from the date of birth, `to` exclusive (`nutritionAgeSchema`).
@immutable
class NuAge {
  const NuAge(this.from, this.to);
  final int from;
  final int to;

  /// `nutritionAgeContains`.
  bool contains(int months) => months >= from && months < to;

  /// `nutritionAgeLabel`: [0,1) "0–1", [6,9) "6–8", [24,37) "24–36".
  ({int from, int to}) get label =>
      (from: from, to: to - from == 1 ? to : to - 1);

  static NuAge? parse(Object? j) {
    if (j is! Map) return null;
    final f = j['from'];
    final t = j['to'];
    if (f is! num || t is! num) return null;
    final from = f.toInt();
    final to = t.toInt();
    if (from < 0 || from > nuMaxAgeMonths || to <= from) return null;
    if (to > nuMaxAgeMonths + 1) return null;
    return NuAge(from, to);
  }

  @override
  bool operator ==(Object other) =>
      other is NuAge && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// `{min, max}` whole numbers (ml, feeds).
@immutable
class NuRange {
  const NuRange(this.min, this.max);
  final int min;
  final int max;

  static NuRange? parse(Object? j, int limit) {
    if (j is! Map) return null;
    final a = j['min'];
    final b = j['max'];
    if (a is! num || b is! num) return null;
    final min = a.toInt();
    final max = b.toInt();
    if (min < 0 || max < min || max > limit) return null;
    return NuRange(min, max);
  }

  @override
  bool operator ==(Object other) =>
      other is NuRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// A suggestion card: "Gợi ý cho {bé}" (stage) or "Gợi ý trong lúc chờ khám" (rule).
@immutable
class NuTip {
  const NuTip(this.title, this.body);
  final LbText title;
  final LbText? body;

  static List<NuTip> list(Object? j) => [
    if (j is List)
      for (final t in j)
        if (t is Map && LbText.parse(t['title']) != null)
          NuTip(LbText.parse(t['title'])!, LbText.parse(t['body'])),
  ];
}

// ---------- NutritionStage (`nst_…`) ----------

/// Reference amounts for bottle feeding (each part optional: 0–1 month has no daily band).
@immutable
class NuMilk {
  const NuMilk({
    this.perFeedMl,
    this.feedsPerDay,
    this.perDayMl,
    this.breastfeedingNote,
  });
  final NuRange? perFeedMl;
  final NuRange? feedsPerDay;

  /// The 9b / 9c band.
  final NuRange? perDayMl;

  /// "Cho bú theo nhu cầu."
  final LbText? breastfeedingNote;

  bool get isEmpty =>
      perFeedMl == null &&
      feedsPerDay == null &&
      perDayMl == null &&
      breastfeedingNote == null;

  static NuMilk? parse(Object? j) {
    if (j is! Map) return null;
    final m = NuMilk(
      perFeedMl: NuRange.parse(j['perFeedMl'], _maxMl),
      feedsPerDay: NuRange.parse(j['feedsPerDay'], _maxFeeds),
      perDayMl: NuRange.parse(j['perDayMl'], _maxMl),
      breastfeedingNote: LbText.parse(j['breastfeedingNote']),
    );
    return m.isEmpty ? null : m;
  }
}

@immutable
class NuSolids {
  const NuSolids({required this.meals, this.texture});

  /// "2–3 bữa".
  final LbText meals;

  /// "Bột loãng → cháo rây, nghiền".
  final LbText? texture;

  static NuSolids? parse(Object? j) {
    if (j is! Map) return null;
    final meals = LbText.parse(j['meals']);
    if (meals == null) return null;
    return NuSolids(meals: meals, texture: LbText.parse(j['texture']));
  }
}

/// `sampleSlots`.
enum NuSlot { morning, noon, afternoon, evening, night }

/// `sampleKinds`: picks the row icon.
enum NuSampleKind { milk, solids, snack, sleep }

/// "Một ngày tham khảo" row.
@immutable
class NuSampleRow {
  const NuSampleRow(this.slot, this.kind, this.text);
  final NuSlot slot;
  final NuSampleKind kind;
  final LbText text;

  static List<NuSampleRow> list(Object? j) => [
    if (j is List)
      for (final r in j)
        if (r is Map)
          if ((
                NuSlot.values.asNameMap()[r['slot']],
                NuSampleKind.values.asNameMap()[r['kind']],
                LbText.parse(r['text']),
              )
              case (final slot?, final kind?, final text?))
            NuSampleRow(slot, kind, text),
  ];
}

/// Published editorial metadata shared by the three kinds.
mixin NuPublished {
  List<LbSource> get sources;
  LbReview? get review;

  /// True until a qualified reviewer signs it (D-082: a footnote, never a badge).
  bool get illustrative;
}

@immutable
class NuStage with NuPublished {
  const NuStage({
    required this.id,
    required this.age,
    required this.title,
    this.summary,
    this.milk,
    this.solids,
    this.sampleDay = const [],
    this.nutrientIds = const [],
    this.tips = const [],
    this.sources = const [],
    this.review,
    this.illustrative = true,
    this.revision = 1,
    this.publishedAt,
  });

  final String id;
  final NuAge age;

  /// "Bắt đầu ăn dặm".
  final LbText title;

  /// One paragraph (≤ 220).
  final LbText? summary;
  final NuMilk? milk;
  final NuSolids? solids;
  final List<NuSampleRow> sampleDay;

  /// Up to 6, in display order ("Cần chú ý ở giai đoạn này").
  final List<String> nutrientIds;

  /// "Gợi ý cho {bé}" while no growth rule fires.
  final List<NuTip> tips;
  @override
  final List<LbSource> sources;
  @override
  final LbReview? review;
  @override
  final bool illustrative;
  final int revision;
  final DateTime? publishedAt;

  /// `{emergency}` in its text becomes [emergency], the family's number (D-087).
  static NuStage? fromDoc(
    String id,
    Map<String, Object?>? doc, {
    String emergency = lbDefaultEmergency,
  }) {
    if (doc == null || !_stageId.hasMatch(id)) return null;
    if (doc['status'] != 'published') return null;
    final j = lbFillDoc(doc, emergency)!;
    final age = NuAge.parse(j['ageMonths']);
    final title = LbText.parse(j['title']);
    if (age == null || title == null) return null;
    final review = LbReview.parse(j['review']);
    final revision = j['revision'];
    return NuStage(
      id: id,
      age: age,
      title: title,
      summary: LbText.parse(j['summary']),
      milk: NuMilk.parse(j['milk']),
      solids: NuSolids.parse(j['solids']),
      sampleDay: NuSampleRow.list(j['sampleDay']).take(8).toList(),
      nutrientIds: [
        if (j['nutrientIds'] is List)
          for (final n in j['nutrientIds']! as List)
            if (n is String && _nutrientId.hasMatch(n)) n,
      ].take(6).toList(),
      tips: NuTip.list(j['tips']).take(4).toList(),
      sources: LbSource.list(j['sources']),
      review: review,
      // Never trust a "reviewed" flag without the review itself (P-141).
      illustrative: j['illustrative'] != false || review == null,
      revision: revision is num ? revision.toInt() : 1,
      publishedAt: lbDate(j['publishedAt']),
    );
  }
}

// ---------- Nutrient (`nut_…`) ----------

/// `nutrientKeys`: picks the icon and the tint; unknown keys read as [other].
enum NuNutrientKey {
  iron,
  zinc,
  vitaminD,
  vitaminA,
  calcium,
  dha,
  iodine,
  fibre,
  other,
}

/// "Theo giai đoạn" row of 9d; the one covering the baby is highlighted.
@immutable
class NuByAge {
  const NuByAge({required this.label, required this.text, this.age});
  final NuAge? age;
  final LbText label;
  final LbText text;

  static List<NuByAge> list(Object? j) => [
    if (j is List)
      for (final r in j)
        if (r is Map &&
            LbText.parse(r['label']) != null &&
            LbText.parse(r['text']) != null)
          NuByAge(
            age: NuAge.parse(r['ageMonths']),
            label: LbText.parse(r['label'])!,
            text: LbText.parse(r['text'])!,
          ),
  ];
}

/// One campaign round (`nutrientRoundSchema`): 1–2/6 and 1–2/12 for vitamin A in Việt Nam.
@immutable
class NuRound {
  const NuRound(this.month, this.fromDay, this.toDay);
  final int month;
  final int fromDay;
  final int toDay;

  static NuRound? parse(Object? j) {
    if (j is! Map) return null;
    final m = j['month'];
    final a = j['fromDay'];
    final b = j['toDay'];
    if (m is! num || a is! num || b is! num) return null;
    final month = m.toInt();
    final from = a.toInt();
    final to = b.toInt();
    if (month < 1 || month > 12 || from < 1 || to > 31 || to < from) {
      return null;
    }
    return NuRound(month, from, to);
  }
}

/// Vitamin A: national campaign days, free at the ward / commune health station.
@immutable
class NuCampaign {
  const NuCampaign({required this.rounds, required this.age, this.place});
  final List<NuRound> rounds;
  final NuAge age;
  final LbText? place;

  static NuCampaign? parse(Object? j) {
    if (j is! Map) return null;
    final rounds = [
      if (j['rounds'] is List)
        for (final r in j['rounds']! as List) ?NuRound.parse(r),
    ].take(4).toList();
    final age = NuAge.parse(j['ageMonths']);
    if (rounds.isEmpty || age == null) return null;
    return NuCampaign(
      rounds: rounds,
      age: age,
      place: LbText.parse(j['place']),
    );
  }
}

@immutable
class NuNutrient with NuPublished {
  const NuNutrient({
    required this.id,
    required this.key,
    required this.name,
    this.subtitle,
    this.focusAge,
    this.focusLabel,
    this.focusNote,
    this.why,
    this.foods = const [],
    this.tip,
    this.byAge = const [],
    this.warning,
    this.campaign,
    this.sources = const [],
    this.review,
    this.illustrative = true,
  });

  final String id;
  final NuNutrientKey key;

  /// "Sắt".
  final LbText name;

  /// The 9b row line.
  final LbText? subtitle;
  final NuAge? focusAge;

  /// "Quan trọng từ 6 tháng".
  final LbText? focusLabel;

  /// "4–6 tháng nếu bú mẹ".
  final LbText? focusNote;
  final LbText? why;
  final List<LbText> foods;
  final LbText? tip;
  final List<NuByAge> byAge;

  /// The medical note: "Dạng thuốc chỉ theo chỉ định bác sĩ".
  final LbText? warning;
  final NuCampaign? campaign;
  @override
  final List<LbSource> sources;
  @override
  final LbReview? review;
  @override
  final bool illustrative;

  /// `{emergency}` in its text becomes [emergency], the family's number (D-087).
  static NuNutrient? fromDoc(
    String id,
    Map<String, Object?>? doc, {
    String emergency = lbDefaultEmergency,
  }) {
    if (doc == null || !_nutrientId.hasMatch(id)) return null;
    if (doc['status'] != 'published') return null;
    final j = lbFillDoc(doc, emergency)!;
    final name = LbText.parse(j['name']);
    if (name == null) return null;
    final focus = j['focus'] is Map ? j['focus']! as Map : const {};
    final review = LbReview.parse(j['review']);
    return NuNutrient(
      id: id,
      key: NuNutrientKey.values.asNameMap()[j['key']] ?? NuNutrientKey.other,
      name: name,
      subtitle: LbText.parse(j['subtitle']),
      focusAge: NuAge.parse(focus['ageMonths']),
      focusLabel: LbText.parse(focus['label']),
      focusNote: LbText.parse(focus['note']),
      why: LbText.parse(j['why']),
      foods: [
        if (j['foods'] is List)
          for (final f in j['foods']! as List) ?LbText.parse(f),
      ].take(12).toList(),
      tip: LbText.parse(j['tip']),
      byAge: NuByAge.list(j['byAge']).take(6).toList(),
      warning: LbText.parse(j['warning']),
      campaign: NuCampaign.parse(j['campaign']),
      sources: LbSource.list(j['sources']),
      review: review,
      illustrative: j['illustrative'] != false || review == null,
    );
  }
}

// ---------- NutritionRule (`nru_…`) ----------

/// `nutritionMetrics`.
enum NuMetric { weight, length, milk, measurement }

/// `nutritionConditions`.
enum NuCondition { belowRange, aboveRange, milkOutsideStage, noMeasurement }

/// `conditionsFor`: the condition must belong to the metric.
bool nuRuleFits(NuMetric m, NuCondition c) => switch (m) {
  NuMetric.weight ||
  NuMetric.length => c == NuCondition.belowRange || c == NuCondition.aboveRange,
  NuMetric.milk => c == NuCondition.milkOutsideStage,
  NuMetric.measurement => c == NuCondition.noMeasurement,
};

@immutable
class NuRule {
  const NuRule({
    required this.id,
    required this.metric,
    required this.condition,
    required this.age,
    required this.banner,
    this.days,
    this.tips = const [],
    this.remindAfterDays,
    this.export = false,
  });

  final String id;
  final NuMetric metric;
  final NuCondition condition;

  /// `noMeasurement`: days without a weight or length (default 30).
  final int? days;
  final NuAge age;

  /// The calm sentence (growth rules say "không phải chẩn đoán").
  final LbText banner;
  final List<NuTip> tips;

  /// "Nhắc đo lại sau N ngày": an all-day reminder this many days ahead.
  final int? remindAfterDays;

  /// "Xuất báo cáo cho bác sĩ".
  final bool export;

  bool get isGrowth => metric == NuMetric.weight || metric == NuMetric.length;

  /// `{emergency}` in its text becomes [emergency], the family's number (D-087).
  static NuRule? fromDoc(
    String id,
    Map<String, Object?>? doc, {
    String emergency = lbDefaultEmergency,
  }) {
    if (doc == null || !_ruleId.hasMatch(id)) return null;
    if (doc['status'] != 'published') return null;
    final j = lbFillDoc(doc, emergency)!;
    final metric = NuMetric.values.asNameMap()[j['metric']];
    final condition = NuCondition.values.asNameMap()[j['condition']];
    final age = NuAge.parse(j['ageMonths']);
    final banner = LbText.parse(j['banner']);
    if (metric == null || condition == null || age == null || banner == null) {
      return null;
    }
    if (!nuRuleFits(metric, condition)) return null;
    int? within(Object? v, int min, int max) =>
        v is num && v.toInt() >= min && v.toInt() <= max ? v.toInt() : null;
    return NuRule(
      id: id,
      metric: metric,
      condition: condition,
      days: within(j['days'], 7, 120),
      age: age,
      banner: banner,
      tips: NuTip.list(j['tips']).take(4).toList(),
      remindAfterDays: within(j['remindAfterDays'], 7, 60),
      export: j['export'] == true,
    );
  }
}

// ---------- Per baby: vitamin A ----------

final _takenKey = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
final _isoDay = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// `babies/{babyId}/nutrition/vitaminA.taken` (`vitaminTakenSchema`): `{"2026-06": "2026-06-01"}`.
/// Keys or values that do not fit are left out.
Map<String, String> nuParseTaken(Object? j) => {
  if (j is Map)
    for (final MapEntry(:key, :value) in j.entries)
      if (key is String &&
          _takenKey.hasMatch(key) &&
          value is String &&
          _isoDay.hasMatch(value) &&
          DateTime.tryParse(value) != null)
        key: value,
};
