import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import 'care_models.dart';
import 'care_repository.dart';
import 'who_growth.dart';

/// 20i "Tiêu chuẩn tăng trưởng WHO" (v1.0 improvement, 347:806): the WHO weight / length bands
/// by week (0–13) or month (0–24), boys or girls, with the baby's own row marked from their latest
/// measurement. Opened from the growth card on 20d.
class GrowthStandardsScreen extends ConsumerStatefulWidget {
  const GrowthStandardsScreen({this.length = false, super.key});

  /// Open on Chiều dài instead of Cân nặng (follows the 20d tab).
  final bool length;

  static Future<void> open(BuildContext context, {bool length = false}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GrowthStandardsScreen(length: length),
        ),
      );

  @override
  ConsumerState<GrowthStandardsScreen> createState() =>
      _GrowthStandardsScreenState();
}

class _GrowthStandardsScreenState extends ConsumerState<GrowthStandardsScreen> {
  late GrowthMeasure _measure = widget.length
      ? GrowthMeasure.length
      : GrowthMeasure.weight;
  bool? _boy;
  bool? _weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final profile = me == null
        ? null
        : ref.watch(babyPrivateProfileProvider(me.babyId)).value;
    final records = me == null
        ? const <CareRecord>[]
        : ref.watch(growthRecordsProvider(me.babyId)).value ?? const [];
    final today = DateUtils.dateOnly(
      ref.watch(careClockProvider).value ?? DateTime.now(),
    );
    final dob = profile == null
        ? null
        : DateUtils.dateOnly(profile.dateOfBirth);
    final ageDays = dob == null ? null : today.difference(dob).inDays;
    final babyBoy = switch (profile?.gender) {
      Gender.boy => true,
      Gender.girl => false,
      _ => null,
    };
    final boy = _boy ?? babyBoy ?? true;
    final weeks = _weeks ?? (ageDays == null || ageDays < 14 * 7);
    final ages = WhoGrowth.ages(weeks: weeks);
    final fixed = NumberFormat('0.0', locale);

    // The baby's latest measurement of this kind, placed at their age on that day.
    final latest =
        ([...records]..sort(
              (a, b) => (b.measuredOn ?? b.occurredAt).compareTo(
                a.measuredOn ?? a.occurredAt,
              ),
            ))
            .where(
              (r) =>
                  (_measure == GrowthMeasure.weight
                      ? r.weightKg
                      : r.lengthCm) !=
                  null,
            )
            .firstOrNull;
    int? youRow;
    String? youLabel;
    GrowthBand? youBand;
    if (latest != null && dob != null && babyBoy == boy) {
      final on = DateUtils.dateOnly(latest.measuredOn ?? latest.occurredAt);
      final days = on.difference(dob).inDays;
      final value = _measure == GrowthMeasure.weight
          ? latest.weightKg!
          : latest.lengthCm!;
      youBand = WhoGrowth.band(_measure, boy: boy, ageDays: days, value: value);
      if (youBand != null && days <= ages.last.days + (weeks ? 6 : 30)) {
        youRow = WhoGrowth.rowFor(ages, days);
        final unit = _measure == GrowthMeasure.weight ? 'kg' : 'cm';
        youLabel = l10n.whoBabyAt(
          baby?.nickname ?? '',
          '${NumberFormat('#0.#', locale).format(value)} $unit',
          switch (youBand) {
            GrowthBand.below => l10n.whoBelow,
            GrowthBand.above => l10n.whoAbove,
            GrowthBand.normal => l10n.whoNormal,
          },
        );
      }
    }

    String ageLabel(GrowthAge a) => a.value == 0
        ? l10n.whoBirth
        : a.weeks
        ? l10n.whoWeeks(a.value)
        : l10n.whoMonths(a.value);

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: () => Navigator.of(context).maybePop(),
                trailing: baby == null
                    ? null
                    : ClBabySwitcher(
                        label: baby.nickname,
                        avatar: SavedBabyAvatar(baby: baby, size: 32),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClSpace.s8,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.whoStandardsTitle, style: cl.text.largeTitle),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.whoIntro,
                    style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  ClSegmented<GrowthMeasure>(
                    options: GrowthMeasure.values,
                    selected: _measure,
                    labelOf: (m) => m == GrowthMeasure.weight
                        ? l10n.growthWeightTab
                        : l10n.growthLengthTab,
                    onChanged: (m) => setState(() => _measure = m),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Wrap(
                    spacing: ClSpace.s2,
                    runSpacing: ClSpace.s2,
                    children: [
                      _SmallChip(
                        label: l10n.whoBoy,
                        selected: boy,
                        dark: true,
                        onTap: () => setState(() => _boy = true),
                      ),
                      _SmallChip(
                        label: l10n.whoGirl,
                        selected: !boy,
                        dark: true,
                        onTap: () => setState(() => _boy = false),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      _SmallChip(
                        label: l10n.whoByWeek,
                        selected: weeks,
                        onTap: () => setState(() => _weeks = true),
                      ),
                      _SmallChip(
                        label: l10n.whoByMonth,
                        selected: !weeks,
                        onTap: () => setState(() => _weeks = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Container(
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(ClRadius.control),
                      boxShadow: cl.shadows.card,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _Row(
                          header: true,
                          age: l10n.whoAge,
                          low: l10n.whoLow,
                          median: l10n.whoMedian,
                          high: l10n.whoHigh,
                        ),
                        for (final (i, a) in ages.indexed) ...[
                          () {
                            final r = WhoGrowth.range(
                              _measure,
                              boy: boy,
                              ageDays: a.days,
                            )!;
                            return _Row(
                              age: ageLabel(a),
                              low: fixed.format(r.low),
                              median: fixed.format(r.median),
                              high: fixed.format(r.high),
                              highlighted: i == youRow,
                              you: i == youRow ? youLabel : null,
                              youBand: youBand,
                            );
                          }(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Text(
                    _measure == GrowthMeasure.weight
                        ? l10n.whoUnitKg
                        : l10n.whoUnitCm,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Container(
                    padding: const EdgeInsets.all(ClSpace.s3),
                    decoration: BoxDecoration(
                      color: cl.colors.chip,
                      borderRadius: BorderRadius.circular(ClRadius.control),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClIcon(
                          ClIcons.heart,
                          size: 16,
                          color: cl.colors.inkMuted,
                        ),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Text(
                            l10n.whoDoctor,
                            style: cl.text.label.copyWith(color: cl.colors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  Text(
                    l10n.whoSource,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 28px option chip on 20i: sex (dark when chosen, with a check) or period (mint when chosen).
class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (bg, ink, border) = !selected
        ? (cl.colors.surface, cl.colors.ink, cl.colors.controlBorder)
        : dark
        ? (cl.colors.ink, cl.colors.surface, cl.colors.ink)
        : (cl.colors.mintSoft, cl.colors.mintText, cl.colors.mintSoft);
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected && dark) ...[
              ClIcon(ClIcons.check, size: 14, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.age,
    required this.low,
    required this.median,
    required this.high,
    this.header = false,
    this.highlighted = false,
    this.you,
    this.youBand,
  });

  final String age;
  final String low;
  final String median;
  final String high;
  final bool header;
  final bool highlighted;
  final String? you;
  final GrowthBand? youBand;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final base = header
        ? cl.text.caption.copyWith(color: cl.colors.inkMuted)
        : cl.text.body;
    Widget cell(String text, {bool strong = false, bool muted = false}) =>
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: base.copyWith(
              fontWeight: strong && !header ? FontWeight.w700 : null,
              color: muted && !header ? cl.colors.inkMuted : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
    final normal = youBand == null || youBand == GrowthBand.normal;
    return Container(
      color: header
          ? cl.colors.surface2
          : highlighted
          ? (normal ? cl.colors.mintSoft : cl.colors.peachSoft)
          : null,
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        ClSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Text(
                  age,
                  style: base.copyWith(
                    fontWeight: header ? null : FontWeight.w500,
                  ),
                ),
              ),
              Expanded(flex: 5, child: Row(children: [cell(low, muted: true)])),
              Expanded(
                flex: 5,
                child: Row(children: [cell(median, strong: true)]),
              ),
              Expanded(
                flex: 4,
                child: Row(children: [cell(high, muted: true)]),
              ),
            ],
          ),
          if (you != null) ...[
            const SizedBox(height: ClSpace.s2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s3,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(
                    normal ? ClIcons.check : ClIcons.alert,
                    size: 14,
                    color: normal ? cl.colors.mintText : cl.colors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    you!,
                    style: cl.text.caption.copyWith(
                      color: normal ? cl.colors.mintText : cl.colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
