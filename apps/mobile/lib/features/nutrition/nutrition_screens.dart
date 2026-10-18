import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show decimal;
import '../care/history_screen.dart' show HistoryFilter;
import '../care/who_growth.dart';
import '../library/library_widgets.dart' show LbOfflineNote;
import 'nutrition_calc.dart';
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_repository.dart';
import 'nutrition_routes.dart';
import 'nutrition_state.dart';
import 'nutrition_widgets.dart';

/// Dinh dưỡng (Figma 9b `440:3767`, 9f `441:4018`; D-083, plan §4): the current stage for the
/// selected baby's age, every stage as a timeline, and a stage opened from it read-only.
/// Caregivers read everything except the growth card, banner and 9e (P-163 #8).

// ---------- 9b ----------

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = ref.watch(nuContentProvider);
    if (c == null) return ColoredBox(color: context.cl.colors.cloud);
    final b = c.baby;
    final stage = c.stage;
    return NuPage(
      children: [
        NuTitle(l10n.nuTitle),
        LbOfflineNote(l10n.nuOffline, top: ClSpace.s3),
        const SizedBox(height: ClSpace.s4),
        if (b.dob == null)
          NuNoDobCard(baby: b)
        else if (stage == null)
          c.loading
              ? const SizedBox(height: 120)
              : NuEmpty(title: l10n.nuEmptyTitle, body: l10n.nuEmptyBody)
        else
          ..._stageBody(
            context,
            ref,
            content: c,
            stage: stage,
            data: ref.watch(nuDataProvider),
            personal: true,
          ),
      ],
    );
  }
}

/// The 9b layout. [personal] = the baby's current stage with their own cards (growth banner,
/// milk average, growth); a stage opened from 9f shows the rest only (P-163 #14).
List<Widget> _stageBody(
  BuildContext context,
  WidgetRef ref, {
  required NuContent content,
  required NuStage stage,
  required NuData? data,
  required bool personal,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final tag = locale.toLanguageTag();
  final b = content.baby;
  final name = b.name;
  final signals = personal ? data?.signals : null;
  final growthRules = signals?.growth ?? const <NuRule>[];
  final taken = ref.watch(nuVitaminTakenProvider(b.babyId)).value ?? const {};
  final nutrients = [
    for (final id in stage.nutrientIds) ?content.nutrients[id],
  ];
  // "Gợi ý cho {bé}": the stage's tips while no growth rule fires; the rule's once one does.
  final ruleTips = growthRules.firstOrNull?.tips ?? const <NuTip>[];
  final tips = ruleTips.isNotEmpty ? ruleTips : stage.tips;
  final milk = stage.milk;
  return [
    for (final rule in growthRules) ...[
      NuBanner(
        key: Key('nuGrowthBanner_${rule.id}'),
        text: nuText(rule.banner, locale, name),
        action: l10n.nuSeeSuggestions,
        onTap: () => context.push(NuRoutes.growth(rule.id)),
      ),
      const SizedBox(height: ClSpace.s3),
    ],
    _StageCard(
      stage: stage,
      label: personal && b.dob != null
          ? l10n.nuStageAge(
              ageShort(l10n, b.dob!, b.today),
              nuAgeLabel(l10n, stage.age),
            )
          : [
              nuAgeLabel(l10n, stage.age),
              if (stage.id == content.stage?.id) l10n.nuCurrent,
            ].join(' · '),
      past: personal && content.past,
      link: personal,
    ),
    if (milk != null) ...[
      const SizedBox(height: ClSpace.s3),
      _MilkCard(
        milk: milk,
        name: name,
        average: personal ? data?.average : null,
        rule: signals?.milk,
        personal: personal,
        locale: tag,
      ),
    ],
    if (personal && b.coParent && data != null) ...[
      const SizedBox(height: ClSpace.s3),
      _GrowthCard(data: data, name: name),
    ],
    if (nutrients.isNotEmpty) ...[
      NuSection(l10n.nuNutrientsTitle),
      NuGroup(
        children: [
          for (final n in nutrients)
            NuNutrientRow(
              key: Key('nuNutrient_${n.id}'),
              nutrient: n,
              name: name,
              tag: _nextRoundTag(n, b, taken, tag),
              onTap: () => context.push(
                n.campaign != null
                    ? NuRoutes.vitamin(n.id)
                    : NuRoutes.nutrient(n.id),
              ),
            ),
        ],
      ),
    ],
    if (stage.sampleDay.isNotEmpty) ...[
      NuSection(l10n.nuSampleTitle),
      NuSampleDay(rows: stage.sampleDay, name: name),
    ],
    if (tips.isNotEmpty) ...[
      NuSection(l10n.nuTipsTitle(name)),
      for (final (i, t) in tips.indexed) ...[
        if (i > 0) const SizedBox(height: ClSpace.s3),
        NuTipCard(
          title: nuText(t.title, locale, name),
          body: nuText(t.body, locale, name),
        ),
      ],
    ],
    NuFootnote(item: stage),
  ];
}

/// The vitamin A row's next round ("1–2/12"), when the baby has a date of birth.
String? _nextRoundTag(
  NuNutrient n,
  NuBaby b,
  Map<String, String> taken,
  String locale,
) {
  final campaign = n.campaign;
  final dob = b.dob;
  if (campaign == null || dob == null) return null;
  final next = nuCampaignRounds(
    campaign,
    dob,
    b.today,
    taken,
  ).where((r) => r.state == NuRoundState.next).firstOrNull;
  return next == null ? null : nuRoundDays(locale, next.from, next.to);
}

/// Peach stage card: "{age} · giai đoạn 6–8 tháng", the title, one paragraph, "Xem các giai
/// đoạn" (9b) — or past the last stage, "Bé đã qua các giai đoạn trong app" (P-163 #9).
class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.label,
    required this.past,
    required this.link,
  });
  final NuStage stage;
  final String label;
  final bool past;
  final bool link;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final growth = cl.care.growth;
    return Container(
      key: const Key('nuStageCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: growth.soft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: cl.text.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: growth.ink,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              stage.title.pick(locale),
              style: cl.text.largeTitle.copyWith(fontSize: 26, height: 1.2),
            ),
          ),
          if (stage.summary != null) ...[
            const SizedBox(height: 8),
            Text(
              stage.summary!.pick(locale),
              style: cl.text.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
          if (past) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nuStagePast,
              key: const Key('nuPast'),
              style: cl.text.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: growth.ink,
              ),
            ),
          ],
          if (link) ...[
            const SizedBox(height: 10),
            ClPressable(
              key: const Key('nuSeeStages'),
              onPressed: () => context.push(NuRoutes.stages),
              semanticLabel: l10n.nuSeeStages,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.nuSeeStages,
                  style: cl.text.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cl.colors.mintText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Sữa mỗi ngày" → 9c: the band from `perDayMl` with the 7-day average marker (or the "chưa
/// đủ" line), the per-feed text, the breastfeeding note and the milk rule's calm line.
class _MilkCard extends StatelessWidget {
  const _MilkCard({
    required this.milk,
    required this.name,
    required this.average,
    required this.rule,
    required this.personal,
    required this.locale,
  });
  final NuMilk milk;
  final String name;
  final int? average;
  final NuRule? rule;
  final bool personal;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context);
    final bottle = cl.care.bottle;
    final band = milk.perDayMl;
    final line = nuMilkLine(
      l10n,
      locale,
      name: name,
      average: average,
      milk: milk,
      breastNote: nuText(milk.breastfeedingNote, loc, name),
      personal: personal,
    );
    final card = NuCard(
      key: const Key('nuMilkCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NuCardHeader(
            icon: ClIcons.feed,
            fill: bottle.soft,
            ink: bottle.ink,
            title: l10n.nuMilkTitle,
            subtitle: l10n.nuMilkSub,
            chevron: personal,
          ),
          if (band != null) ...[
            const SizedBox(height: 14),
            NuMilkBand(band: band, average: personal ? average : null),
          ],
          if (line.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              line,
              style: cl.text.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
          if (rule != null) ...[
            const SizedBox(height: 10),
            NuBanner(
              key: const Key('nuMilkRule'),
              text: nuText(rule!.banner, loc, name),
              warm: false,
            ),
          ],
        ],
      ),
    );
    if (!personal) return card;
    return ClPressable(
      onPressed: () => context.push(NuRoutes.milk),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [l10n.nuMilkTitle, line].join('. '),
      child: card,
    );
  }
}

/// "Tăng trưởng so với chuẩn WHO" (Cùng nuôi): last weight and length with their WHO position
/// and the date → 9e when a growth rule fires, else Tăng trưởng (20d). Nothing measured: "Chưa có
/// lần đo" → add a measurement.
class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.data, required this.name});
  final NuData data;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final growth = cl.care.growth;
    final weight = data.weights.firstOrNull;
    final length = data.lengths.firstOrNull;
    final last = data.lastMeasured;
    final rule = data.signals.growth.firstOrNull;
    final none = weight == null && length == null;
    final noMeasure = data.signals.noMeasurement;
    final subtitle = last == null
        ? l10n.nuGrowthNone
        : l10n.nuGrowthLast(nuDayMonth(last));
    return ClPressable(
      key: const Key('nuGrowthCard'),
      onPressed: () => context.push(
        none
            ? Routes.growth
            : rule != null
            ? NuRoutes.growth(rule.id)
            : '${Routes.history}?filter=${HistoryFilter.growth.name}',
      ),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [
        l10n.nuGrowthTitle,
        subtitle,
        if (weight != null) _measureLabel(l10n, locale, weight, true),
        if (length != null) _measureLabel(l10n, locale, length, false),
        if (none) l10n.growthAdd,
      ].join('. '),
      child: NuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NuCardHeader(
              icon: ClIcons.ruler,
              fill: growth.soft,
              ink: growth.ink,
              title: l10n.nuGrowthTitle,
              subtitle: subtitle,
            ),
            const SizedBox(height: 12),
            if (none)
              Row(
                children: [
                  ClIcon(ClIcons.plus, size: 16, color: cl.colors.mintText),
                  const SizedBox(width: 6),
                  Text(
                    l10n.growthAdd,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MeasureTile(
                        label: l10n.nuWeight,
                        measure: weight,
                        value: weight == null
                            ? null
                            : l10n.weightKg(
                                decimal(locale.toLanguageTag(), weight.value),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MeasureTile(
                        label: l10n.nuLength,
                        measure: length,
                        value: length == null
                            ? null
                            : l10n.lengthCm(
                                decimal(locale.toLanguageTag(), length.value),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            if (noMeasure != null) ...[
              const SizedBox(height: 10),
              NuBanner(
                key: const Key('nuNoMeasurement'),
                text: nuText(noMeasure.banner, locale, name),
                warm: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _measureLabel(
    AppLocalizations l10n,
    Locale locale,
    NuMeasure m,
    bool weight,
  ) => [
    weight ? l10n.nuWeight : l10n.nuLength,
    weight
        ? l10n.weightKg(decimal(locale.toLanguageTag(), m.value))
        : l10n.lengthCm(decimal(locale.toLanguageTag(), m.value)),
    if (m.band != null) nuBandLabel(l10n, m.band!),
  ].join(' ');
}

class _MeasureTile extends StatelessWidget {
  const _MeasureTile({
    required this.label,
    required this.measure,
    required this.value,
  });
  final String label;
  final NuMeasure? measure;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final band = measure?.band;
    final normal = band == GrowthBand.normal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: cl.text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? '—',
            style: cl.text.bodyStrong.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (band != null) ...[
            const SizedBox(height: 6),
            // Calm: mint inside the band, sunshine outside it; never red (P-163 #5).
            NuTag(
              nuBandLabel(l10n, band),
              fill: normal ? cl.colors.mintSoft : cl.colors.sunshineSoft,
              ink: normal ? cl.colors.mintText : cl.colors.ink,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 9f Các giai đoạn ----------

class NutritionStagesScreen extends ConsumerWidget {
  const NutritionStagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = ref.watch(nuContentProvider);
    if (c == null) return ColoredBox(color: context.cl.colors.cloud);
    final months = c.months;
    return NuPage(
      children: [
        NuTitle(l10n.nuStagesTitle),
        LbOfflineNote(l10n.nuOffline, top: ClSpace.s3),
        const SizedBox(height: ClSpace.s4),
        if (c.stages.isEmpty)
          c.loading
              ? const SizedBox(height: 120)
              : NuEmpty(title: l10n.nuEmptyTitle, body: l10n.nuEmptyBody)
        else
          for (final (i, s) in c.stages.indexed)
            _TimelineRow(
              key: Key('nuTimeline_${s.id}'),
              stage: s,
              time: months == null
                  ? NuStageTime.future
                  : nuStageTime(s, c.stage, months),
              last: i == c.stages.length - 1,
              name: c.baby.name,
            ),
      ],
    );
  }
}

/// 9f row: the rail (past filled, current mint-deep, future hollow) and the card (the current one
/// peach), opening the stage read-only (P-163 #14).
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stage,
    required this.time,
    required this.last,
    required this.name,
    super.key,
  });
  final NuStage stage;
  final NuStageTime time;
  final bool last;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final current = time == NuStageTime.current;
    final growth = cl.care.growth;
    final age = nuAgeLabel(l10n, stage.age);
    final title = nuText(stage.title, locale, name);
    final detail = nuText(stage.summary, locale, name);
    final dot = switch (time) {
      NuStageTime.current => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: cl.colors.mintDeep,
          shape: BoxShape.circle,
        ),
      ),
      NuStageTime.past => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cl.colors.inkMuted,
          shape: BoxShape.circle,
          border: Border.all(color: cl.colors.surface, width: 1.5),
        ),
      ),
      NuStageTime.future => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: cl.colors.controlBorder, width: 1.5),
        ),
      ),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!last)
                  Positioned(
                    top: 20,
                    bottom: 0,
                    child: Container(width: 1.5, color: cl.colors.separator),
                  ),
                Positioned(top: 18, child: dot),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: ClPressable(
                onPressed: () => context.push(NuRoutes.stage(stage.id)),
                pressedOpacity: ClPressable.surfaceOpacity,
                semanticLabel: [
                  age,
                  if (current) l10n.nuCurrent,
                  title,
                  if (detail.isNotEmpty) detail,
                ].join('. '),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: current ? growth.soft : cl.colors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        age,
                        style: cl.text.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: current ? growth.ink : cl.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stage opened from 9f: the 9b layout without the personal cards (P-163 #14).
class NutritionStageScreen extends ConsumerWidget {
  const NutritionStageScreen({required this.stageId, super.key});
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = ref.watch(nuContentProvider);
    if (c == null) return ColoredBox(color: context.cl.colors.cloud);
    final stage = c.stages.where((s) => s.id == stageId).firstOrNull;
    return NuPage(
      children: [
        if (stage == null)
          c.loading
              ? const SizedBox(height: 120)
              : NuEmpty(
                  title: l10n.nuStageMissing,
                  body: l10n.nuStageMissingBody,
                )
        else
          ..._stageBody(
            context,
            ref,
            content: c,
            stage: stage,
            data: null,
            personal: false,
          ),
      ],
    );
  }
}
