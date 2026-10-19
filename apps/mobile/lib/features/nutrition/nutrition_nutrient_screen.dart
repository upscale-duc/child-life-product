import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'nutrition_calc.dart';
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_repository.dart';
import 'nutrition_routes.dart';
import 'nutrition_state.dart';
import 'nutrition_widgets.dart';

/// 9d Vi chất (Figma `440:4217`, the template for every micronutrient, P-163 #15): head, "Vì sao
/// cần", foods, a tip, "Theo giai đoạn" with the row covering the baby highlighted, a campaign
/// card to 9g when the nutrient has one, the medical note and the sources.
class NutrientScreen extends ConsumerWidget {
  const NutrientScreen({required this.nutrientId, super.key});
  final String nutrientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final c = ref.watch(nuContentProvider);
    if (c == null) return ColoredBox(color: cl.colors.cloud);
    final n = c.nutrients[nutrientId];
    if (n == null) {
      return NuPage(
        children: [
          if (!ref.watch(nuNutrientsProvider).isLoading)
            NuEmpty(title: l10n.nuStageMissing, body: l10n.nuStageMissingBody),
        ],
      );
    }
    final b = c.baby;
    final name = b.name;
    final look = nuNutrientLook(context, n.key);
    final months = c.months;
    final campaign = n.campaign;
    // Outside Việt Nam: a note instead of the campaign card (P-166 #6).
    final abroad = campaign != null && ref.watch(nuCampaignAbroadProvider);
    final taken = ref.watch(nuVitaminTakenProvider(b.babyId)).value ?? const {};
    final next = campaign == null || b.dob == null
        ? null
        : nuFirstEligible(nuCampaignRounds(campaign, b.dob!, b.today, taken));
    final focus = [
      nuText(n.focusLabel, locale, name),
      nuText(n.focusNote, locale, name),
    ].where((s) => s.isNotEmpty).join(' · ');
    final muted = cl.text.body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );
    return NuPage(
      children: [
        Row(
          children: [
            NuIconChip(
              icon: look.icon,
              fill: look.soft,
              ink: look.ink,
              size: 56,
              radius: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NuTitle(nuText(n.name, locale, name)),
                  if (focus.isNotEmpty)
                    Text(
                      focus,
                      style: muted.copyWith(color: cl.colors.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (n.why != null) ...[
          const SizedBox(height: ClSpace.s4),
          NuCard(
            flat: true,
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nuWhy,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(nuText(n.why, locale, name), style: muted),
                ],
              ),
            ),
          ),
        ],
        if (n.foods.isNotEmpty) ...[
          NuSection(l10n.nuFoodsTitle),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in n.foods)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                    border: Border.all(color: cl.colors.separator),
                  ),
                  child: Text(
                    nuText(f, locale, name),
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cl.colors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (n.tip != null) ...[
          const SizedBox(height: ClSpace.s4),
          NuTipCard(title: l10n.nuTip, body: nuText(n.tip, locale, name)),
        ],
        if (n.byAge.isNotEmpty) ...[
          NuSection(l10n.nuByStageTitle),
          NuGroup(
            inset: 0,
            children: [
              for (final (i, r) in n.byAge.indexed)
                _ByAgeRow(
                  key: Key('nuByAge_$i'),
                  row: r,
                  // The first row covering the baby (rows may overlap, e.g. "12 tháng").
                  current:
                      months != null &&
                      r.age != null &&
                      r.age!.contains(months) &&
                      n.byAge.indexWhere(
                            (x) => x.age != null && x.age!.contains(months),
                          ) ==
                          i,
                  name: name,
                ),
            ],
          ),
        ],
        if (abroad) ...[
          const SizedBox(height: ClSpace.s4),
          NuBanner(
            key: const Key('nuVitaAbroad'),
            warm: false,
            text: l10n.nuVitaAbroad,
          ),
        ] else if (campaign != null) ...[
          const SizedBox(height: ClSpace.s4),
          ClPressable(
            key: const Key('nuCampaignCard'),
            onPressed: () => context.push(NuRoutes.vitamin(n.id)),
            pressedOpacity: ClPressable.surfaceOpacity,
            semanticLabel: [
              l10n.nuCampaignTitle,
              if (next != null)
                l10n.nuNextRound(
                  nuRoundDays(tag, next.from, next.to, year: true),
                ),
            ].join('. '),
            child: NuCard(
              child: NuCardHeader(
                icon: ClIcons.clock,
                fill: look.soft,
                ink: look.ink,
                title: l10n.nuCampaignTitle,
                subtitle: next == null
                    ? null
                    : l10n.nuNextRound(
                        nuRoundDays(tag, next.from, next.to, year: true),
                      ),
              ),
            ),
          ),
        ],
        if (n.warning != null) ...[
          const SizedBox(height: ClSpace.s4),
          NuBanner(text: nuText(n.warning, locale, name)),
        ],
        NuFootnote(item: n, doctor: false),
      ],
    );
  }
}

class _ByAgeRow extends StatelessWidget {
  const _ByAgeRow({
    required this.row,
    required this.current,
    required this.name,
    super.key,
  });
  final NuByAge row;
  final bool current;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final growth = cl.care.growth;
    return MergeSemantics(
      child: Container(
        color: current ? growth.soft : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nuText(row.label, locale, name),
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: current ? growth.ink : cl.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nuText(row.text, locale, name),
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (current) ...[
              const SizedBox(width: 8),
              NuTag(l10n.nuCurrent, fill: cl.colors.surface, ink: growth.ink),
            ],
          ],
        ),
      ),
    );
  }
}
