import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../nutrition/nutrition_widgets.dart' show NuIconChip;
import 'solids_calc.dart' show SdRoles;
import 'solids_format.dart';
import 'solids_personal.dart' show sdSuggestionsProvider;
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';

/// Ăn dặm outside its own pages (plan §3 #1, §5): the 5h Today card (`314:2169`), the Dinh dưỡng
/// 9b link row, and whether the quick log offers "Ăn dặm".

/// Whether Hôm nay may show the 5h card: tracking on, the family's 5a toggle on, and a member who
/// reads the diary. The device's own "Tuỳ chỉnh Hôm nay" row comes on top of this.
final sdOnTodayProvider = Provider<bool>((ref) {
  final s = ref.watch(sdStateProvider);
  return s != null && s.tracking && s.settings.showOnToday && s.me.sdReads;
});

/// The quick log (+) offers "Ăn dặm" while tracking is on, to who logs.
final sdQuickLogProvider = Provider<bool>((ref) {
  final s = ref.watch(sdStateProvider);
  return s != null && s.tracking && s.me.sdLogs;
});

/// 5h "Ăn dặm hôm nay · N bữa": the latest dish and time, today's first tries, "Ghi bữa", and the
/// primary suggestion's title when there is one (plan §7). The card opens 5b.
class SdTodayCard extends ConsumerWidget {
  const SdTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sdOnTodayProvider)) return const SizedBox.shrink();
    final s = ref.watch(sdStateProvider)!;
    final day = ref.watch(sdTodayProvider);
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final count = day?.count ?? 0;
    final latest = day?.latest;
    final firsts = [
      for (final id in day?.firstTries ?? const <String>[])
        sdFoodName(id, s.foods, locale),
    ];
    // Plan §5 5h: the primary suggestion's title as a second line (phase D).
    final suggestion = ref
        .watch(sdSuggestionsProvider(locale.languageCode))
        .where((c) => c.primary)
        .firstOrNull;
    final head = l10n.sdTodayCard(count);
    final line = latest == null
        ? l10n.sdEmptyToday
        : l10n.sdLatest(
            sdMealTitle(latest, s.foods, locale),
            sdTime(tag, latest.occurredAt),
          );
    return ClPressable(
      key: const Key('sdTodayCard'),
      onPressed: () => context.push(SdRoutes.home),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [
        head,
        line,
        if (firsts.isNotEmpty) l10n.sdFirstToday(firsts.join(', ')),
        ?suggestion?.title,
      ].join('. '),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NuIconChip(
                  icon: ClIcons.feed,
                  fill: cl.care.bottle.soft,
                  ink: cl.care.bottle.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        head,
                        style: cl.text.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.bodyStrong.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (suggestion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestion.title,
                          key: const Key('sdTodaySuggestion'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.label.copyWith(
                            fontSize: 13,
                            color: cl.colors.mintText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (firsts.isNotEmpty)
                  Flexible(
                    child: Container(
                      key: const Key('sdTodayFirst'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cl.colors.sunshineSoft,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClIcon(ClIcons.spark, size: 12, color: cl.colors.ink),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              l10n.sdFirstToday(firsts.join(', ')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cl.text.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cl.colors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (s.me.sdLogs)
                  ClPressable(
                    key: const Key('sdTodayLog'),
                    onPressed: () => unawaited(openMealSheet(context)),
                    semanticLabel: l10n.sdLogMeal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cl.colors.mintDeep,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClIcon(
                            ClIcons.plus,
                            size: 14,
                            color: cl.colors.onMintDeep,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.sdLogMeal,
                            style: cl.text.label.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cl.colors.onMintDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dinh dưỡng 9b (P-164 #1): "Ăn dặm hôm nay · N bữa · Mở nhật ký" while tracking is on.
class SdNutritionRow extends ConsumerWidget {
  const SdNutritionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sdStateProvider);
    final day = ref.watch(sdTodayProvider);
    if (s == null || !s.tracking || !s.me.sdReads || day == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final label = l10n.sdNutritionRow(day.count);
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: ClPressable(
        key: const Key('sdNutritionRow'),
        onPressed: () => context.push(SdRoutes.home),
        pressedOpacity: ClPressable.surfaceOpacity,
        semanticLabel: '$label. ${l10n.sdOpenDiary}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            boxShadow: cl.shadows.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              NuIconChip(
                icon: ClIcons.feed,
                fill: cl.care.bottle.soft,
                ink: cl.care.bottle.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.sdOpenDiary,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.mintText,
                ),
              ),
              const SizedBox(width: 4),
              ClIcon(ClIcons.chevronRight, size: 14, color: cl.colors.mintText),
            ],
          ),
        ),
      ),
    );
  }
}

/// The quick log's "Ăn dặm" tile (19a), wide under the six care tiles.
class SdQuickLogTile extends StatelessWidget {
  const SdQuickLogTile({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final bottle = cl.care.bottle;
    return ClPressable(
      key: const Key('quickSolids'),
      onPressed: onTap,
      semanticLabel: l10n.careSolids,
      child: Container(
        height: 64,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: bottle.soft,
          borderRadius: BorderRadius.circular(ClRadius.tile),
        ),
        child: Row(
          children: [
            ClIcon(ClIcons.feed, size: 28, color: bottle.ink),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                l10n.careSolids,
                style: cl.text.headline.copyWith(color: bottle.ink),
              ),
            ),
            ClIcon(ClIcons.plus, size: 18, color: bottle.ink),
          ],
        ),
      ),
    );
  }
}
