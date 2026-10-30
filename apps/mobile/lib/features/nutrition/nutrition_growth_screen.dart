import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show decimal;
import '../care/growth_chart.dart';
import '../care/growth_reference.dart';
import '../home/home_shell.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/reminder_screens.dart' show maybeAskForNotifications;
import 'nutrition_calc.dart';
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_reminders.dart';
import 'nutrition_share.dart';
import 'nutrition_state.dart';
import 'nutrition_widgets.dart';

/// 9e Gợi ý theo tăng trưởng (Figma `441:3917`, P-163 #6–#7), Cùng nuôi only: the WHO chart of
/// the rule's metric, the rule's calm banner and tips, "Nhắc đo lại sau N ngày" (an all-day
/// one-time reminder) and "Xuất báo cáo cho bác sĩ" (a plain-text summary on the share sheet).
/// Never a diagnosis.
class NutritionGrowthScreen extends ConsumerWidget {
  const NutritionGrowthScreen({required this.ruleId, super.key});
  final String ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final c = ref.watch(nuContentProvider);
    final data = ref.watch(nuDataProvider);
    if (c == null || data == null) return ColoredBox(color: cl.colors.cloud);
    final b = c.baby;
    final rule = c.rules.where((r) => r.id == ruleId).firstOrNull;
    // Caregivers have no growth suggestions (P-163 #8); a withdrawn rule shows nothing.
    if (!b.coParent || rule == null || !rule.isGrowth) {
      return NuPage(
        children: [
          NuEmpty(
            title: l10n.nuGrowthNoneTitle,
            body: l10n.nuGrowthNoSignal(b.name),
          ),
        ],
      );
    }
    final weight = rule.metric == NuMetric.weight;
    final measure = nuGrowthMeasure(rule.metric);
    final measures = weight ? data.weights : data.lengths;
    final fires = data.signals.growth.any((r) => r.id == rule.id);
    final latest = measures.firstOrNull;
    final dob = b.dob;
    final boy = b.boy;
    String value(double v) => weight
        ? l10n.weightKg(decimal(tag, v))
        : l10n.lengthCm(decimal(tag, v));
    final reference = ref.watch(growthReferenceProvider);
    final points = [
      for (final m in measures.reversed)
        if (m.ageDays != null) (m.ageDays!, m.value),
    ];
    final banner = nuText(rule.banner, locale, b.name);

    // "Nhắc đo lại sau N ngày" → "Đã đặt nhắc · {date}" while that reminder is open.
    final title = weight ? l10n.nuRemeasureWeight : l10n.nuRemeasureLength;
    final open = nuOpenReminder(
      l10n,
      ref.watch(remindersProvider(b.babyId)).value ?? const [],
      title,
      b.now,
      b.zone,
    );
    final days = rule.remindAfterDays;

    return NuPage(
      children: [
        NuTitle(
          weight
              ? l10n.nuGrowthWeightTitle(b.name)
              : l10n.nuGrowthLengthTitle(b.name),
          size: 26,
        ),
        const SizedBox(height: ClSpace.s4),
        if (boy != null && dob != null && points.isNotEmpty)
          NuCard(
            key: const Key('nuGrowthChart'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        boy ? l10n.nuWhoBoy : l10n.nuWhoGirl,
                        style: cl.text.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cl.colors.ink,
                        ),
                      ),
                    ),
                    if (latest != null)
                      Text(
                        '${value(latest.value)} · ${ageShort(l10n, dob, latest.on)}',
                        style: cl.text.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cl.care.bottle.ink,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ClSpace.s3),
                ExcludeSemantics(
                  child: WhoGrowthChart(
                    measure: measure,
                    boy: boy,
                    points: points,
                    unit: weight ? 'kg' : 'cm',
                    reference: reference,
                    height: 160,
                    // Every 4th week / 3rd month, so the labels never overlap.
                    axisLabel: (a) => a.value == 0
                        ? l10n.whoBirth
                        : a.weeks
                        ? (a.value % 4 == 0 ? l10n.whoWeeks(a.value) : '')
                        : (a.value % 3 == 0 ? l10n.whoMonths(a.value) : ''),
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s3,
                  runSpacing: 4,
                  children: [
                    for (final (color, label) in [
                      (cl.colors.mintSoft, l10n.nuLegendBand),
                      (cl.colors.mintDeep, l10n.whoMedianLine),
                      (cl.colors.peach, b.name),
                    ])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (fires) ...[
          const SizedBox(height: ClSpace.s4),
          NuBanner(key: const Key('nuGrowthRuleBanner'), text: banner),
          if (rule.tips.isNotEmpty) ...[
            NuSection(l10n.nuWhileWaiting),
            NuGroup(
              children: [
                for (final t in rule.tips)
                  MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NuIconChip(
                            icon: ClIcons.spark,
                            fill: cl.colors.mintSoft,
                            ink: cl.colors.mintText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nuText(t.title, locale, b.name),
                                  style: cl.text.bodyStrong.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (t.body != null)
                                  Text(
                                    nuText(t.body, locale, b.name),
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
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: ClSpace.s6),
          if (days != null)
            open == null
                ? ClButton(
                    key: const Key('nuRemind'),
                    label: days % 7 == 0
                        ? l10n.nuRemindWeeks(days ~/ 7)
                        : l10n.nuRemindDays(days),
                    expand: true,
                    onPressed: () => _remind(context, ref, b, days, title),
                  )
                : ClButton(
                    key: const Key('nuReminded'),
                    label: l10n.nuReminded(
                      nuDayMonth(open.dueDay ?? open.dueAt),
                    ),
                    style: ClButtonStyle.tinted,
                    icon: ClIcons.check,
                    expand: true,
                    onPressed: null,
                  ),
          if (rule.export) ...[
            const SizedBox(height: ClSpace.s3),
            Builder(
              builder: (button) => ClButton(
                key: const Key('nuExport'),
                label: l10n.nuExport,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => _export(button, ref, b, data, rule),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.nuGrowthNoSignal(b.name),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        NuFootnote(item: null, doctor: false, extra: l10n.nuGrowthFooter),
      ],
    );
  }

  Future<void> _remind(
    BuildContext context,
    WidgetRef ref,
    NuBaby b,
    int days,
    String title,
  ) async {
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final day = DateTime(b.today.year, b.today.month, b.today.day + days);
    await nuCreateReminder(
      ref,
      me: me,
      zone: b.zone,
      title: title,
      day: day,
      onError: (_) => toaster.show(message: l10n.careSaveFailed, error: true),
    );
    if (!context.mounted) return;
    // 8c: the reminder is saved first, then this device may ask for notifications.
    await maybeAskForNotifications(context, ref);
    toaster.show(message: l10n.nuRemindToast(nuDate(day)));
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    NuBaby b,
    NuData data,
    NuRule rule,
  ) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final toaster = ClToaster.of(context);
    final text = nuDoctorReport(
      l10n,
      locale: locale.toLanguageTag(),
      dob: b.dob,
      today: b.today,
      boy: b.boy,
      weights: data.weights,
      lengths: data.lengths,
      milkAverage: data.average,
      // No name in the summary: "{name}" reads as "bé".
      banner: nuText(rule.banner, locale, l10n.nuReportBaby),
    );
    try {
      await ref.read(nuShareProvider)(
        text: text,
        subject: l10n.nuReportSubject,
        origin: nuShareOrigin(context),
      );
    } on Object {
      toaster.show(message: l10n.nuShareFailed, error: true);
    }
  }
}
