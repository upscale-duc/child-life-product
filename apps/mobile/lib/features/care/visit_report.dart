import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/appearance/appearance_providers.dart'
    show sharedPreferencesProvider;
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_calc.dart';
import '../rhythm/rhythm_repository.dart'
    show babyTodayIso, rhythmProfileProvider;
import '../rhythm/rhythm_week.dart';
import '../vaccines/vaccine_format.dart';
import '../vaccines/vaccine_models.dart' show DoseItem, DoseStatus;
import 'care_format.dart' show careTypeLabel, durationLabel;
import 'care_models.dart';
import 'care_repository.dart';
import 'who_growth.dart';

/// U1 "Chuẩn bị đi khám" (sprint Premium, owner 2026-10-30): what a doctor asks, from the
/// family's own log: growth with the WHO band, feeds / sleep / diapers per day over the last 7
/// complete days against the 7 before, vaccines, and the family's own questions. Facts only, no
/// interpretation; sleep counts complete days only (missing is never zero, D-073).

/// Who gets it: reads care and the baby's information, in a household with `rhythm.advanced`.
/// Nothing for others (no upgrade prompt while the purchase is closed, audit COM-01).
bool visitReportAllowed(Membership me, Capabilities? caps) =>
    familyCan(me, FamilyAction.historyRead) &&
    me.canViewBabyInfo &&
    (caps?.allows(Capability.rhythmAdvanced) ?? false);

/// The two weeks: the 7 complete days before [today], and the 7 before those.
({SummaryWeek recent, SummaryWeek before}) visitWeeks(String today) => (
  recent: SummaryWeek(
    start: addDaysIso(today, -7),
    end: addDaysIso(today, -1),
    inProgress: false,
  ),
  before: SummaryWeek(
    start: addDaysIso(today, -14),
    end: addDaysIso(today, -8),
    inProgress: false,
  ),
);

/// "7,4" (vi) / "7.4" (en): a per-day average with one decimal at most.
String perDay(String locale, num total, [int days = 7]) =>
    NumberFormat('#0.#', locale).format(total / days);

/// The family's questions for the doctor, on this phone only (per person and baby).
class VisitQuestions extends Notifier<List<String>> {
  VisitQuestions(this.key);
  final (String uid, String babyId) key;

  String get _pref => 'visitQuestions.${key.$1}.${key.$2}';

  @override
  List<String> build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_pref);
      return raw == null
          ? const []
          : List<String>.from(jsonDecode(raw) as List);
    } on Object {
      return const [];
    }
  }

  Future<void> _save(List<String> next) async {
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_pref, jsonEncode(next));
  }

  Future<void> add(String q) =>
      q.trim().isEmpty ? Future.value() : _save([...state, q.trim()]);

  Future<void> removeAt(int i) => _save([...state]..removeAt(i));
}

final visitQuestionsProvider =
    NotifierProvider.family<VisitQuestions, List<String>, (String, String)>(
      VisitQuestions.new,
    );

class VisitReportScreen extends ConsumerStatefulWidget {
  const VisitReportScreen({super.key});

  @override
  ConsumerState<VisitReportScreen> createState() => _VisitReportState();
}

class _VisitReportState extends ConsumerState<VisitReportScreen> {
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    if (me == null ||
        !visitReportAllowed(me, ref.watch(selectedCapabilitiesProvider))) {
      return MePage(title: l10n.vrTitle, children: const []);
    }
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final name = baby?.nickname ?? '';
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = babyTodayIso(zone, now);
    final todayDate = DateTime.parse(today);
    final profile = ref.watch(rhythmProfileProvider(me.babyId)).value;
    final private = ref.watch(babyPrivateProfileProvider(me.babyId)).value;
    final dob = profile?.dateOfBirth ?? private?.dateOfBirth;
    final weeks = visitWeeks(today);
    final from = dayBoundsIn(zone, weeks.before.start).start;
    final to = dayBoundsIn(zone, weeks.recent.end).end;
    final records = ref
        .watch(rangeRecordsProvider((me.babyId, from, to)))
        .value;
    final growth =
        ref.watch(growthRecordsProvider(me.babyId)).value ?? const [];
    final questions = ref.watch(visitQuestionsProvider((me.uid, me.babyId)));
    final day = DateFormat('dd/MM/yyyy', locale);

    // ---- Who ----
    final age = dob == null ? null : ageLong(l10n, dob, todayDate);
    final corrected = dob == null
        ? null
        : cardAgeDays(dob, profile?.dueDate?.date, todayDate);
    final correctedLabel =
        dob != null &&
            corrected != null &&
            corrected != ageInDays(dob, todayDate)
        ? l10n.vrCorrectedAge(
            ageLong(l10n, dob, dob.add(Duration(days: corrected))),
          )
        : null;

    // ---- Growth: the latest value of each measure, with the WHO band at that age ----
    final boy = switch (private?.gender) {
      Gender.boy => true,
      Gender.girl => false,
      _ => null,
    };
    String? band(GrowthMeasure m, double? value, CareRecord r) {
      if (value == null || boy == null || dob == null) return null;
      final at = DateTime.parse(measuredDate(zone, r));
      final b = WhoGrowth.band(
        m,
        boy: boy,
        ageDays: ageInDays(dob, at),
        value: value,
      );
      return switch (b) {
        GrowthBand.below => l10n.whoBelow,
        GrowthBand.above => l10n.whoAbove,
        GrowthBand.normal => l10n.whoNormal,
        null => null,
      };
    }

    final num1 = NumberFormat('#0.##', locale);
    final growthRows = <({String label, String? value, String? sub})>[];
    for (final (m, label, pick, unit) in [
      (GrowthMeasure.weight, l10n.vrWeight, (CareRecord r) => r.weightKg, 'kg'),
      (GrowthMeasure.length, l10n.vrLength, (CareRecord r) => r.lengthCm, 'cm'),
      (GrowthMeasure.head, l10n.vrHead, (CareRecord r) => r.headCm, 'cm'),
    ]) {
      final r = growth.where((r) => !r.deleted && pick(r) != null).firstOrNull;
      if (r == null) continue;
      final b = band(m, pick(r), r);
      growthRows.add((
        label: label,
        value: '${num1.format(pick(r))} $unit',
        sub: [
          l10n.vrMeasuredOn(day.format(DateTime.parse(measuredDate(zone, r)))),
          ?b,
        ].join(' · '),
      ));
    }

    // ---- Feeds, sleep, diapers ----
    WeekFacts? facts(SummaryWeek w) => records == null
        ? null
        : weekFacts(
            zone: zone,
            week: w,
            now: now,
            records: records,
            rules: defaultRhythmRules,
          );
    final recent = facts(weeks.recent);
    final before = facts(weeks.before);
    String bottle(WeekFacts f) => l10n.vrFeedsMl(
      perDay(locale, f.bottleCount),
      perDay(locale, f.bottleMl).split(RegExp('[.,]')).first,
    );
    String breast(WeekFacts f) => l10n.vrFeedsMin(
      perDay(locale, f.breastCount),
      perDay(locale, f.breastMinutes).split(RegExp('[.,]')).first,
    );
    String sleep(WeekFacts f) => switch (f.averageSleepMinutes) {
      final m? => durationLabel(l10n, m),
      null => l10n.vrSleepSparse,
    };
    final sleepKnown = recent?.averageSleepMinutes != null;
    String diapers(WeekFacts f) =>
        l10n.vrDiapers(perDay(locale, f.wet), perDay(locale, f.dirty));
    final careRows = recent == null || before == null
        ? const <({String label, String? value, String? sub})>[]
        : [
            if (recent.bottleCount + before.bottleCount > 0)
              (
                label: careTypeLabel(l10n, CareType.bottle),
                value: bottle(recent),
                sub: l10n.vrBefore(bottle(before)),
              ),
            if (recent.breastCount + before.breastCount > 0)
              (
                label: careTypeLabel(l10n, CareType.breast),
                value: breast(recent),
                sub: l10n.vrBefore(breast(before)),
              ),
            // A sentence, not a value, when there are not enough complete days.
            (
              label: careTypeLabel(l10n, CareType.sleep),
              value: sleepKnown ? sleep(recent) : null,
              sub: [
                if (!sleepKnown) sleep(recent),
                l10n.vrBefore(sleep(before)),
              ].join(' · '),
            ),
            if (recent.diapers + before.diapers > 0)
              (
                label: careTypeLabel(l10n, CareType.diaper),
                value: diapers(recent),
                sub: l10n.vrBefore(diapers(before)),
              ),
          ];

    // ---- Vaccines ----
    final book = switch (ref.watch(vaccineBookProvider(me))) {
      VaccineBookReady(:final book) => book,
      _ => null,
    };
    final due = [
      for (final i in book?.items ?? const <DoseItem>[])
        if (i.status != DoseStatus.declined && !i.planned.isAfter(book!.today))
          i,
    ];
    final vaccineRows = <({String label, String? value, String? sub})>[
      if (book != null) ...[
        (
          label: l10n.vrVaccinesGiven(
            due.where((i) => i.status == DoseStatus.given).length,
            due.length,
          ),
          value: null,
          sub: null,
        ),
        if (book.overdue.isNotEmpty)
          (
            label: l10n.vrVaccineOverdue,
            value: null,
            sub: vxGroupLine(l10n, locale, book.overdue, book.plan),
          ),
        // The next visit ahead; anything already past is under "Quá hẹn".
        if (book.milestones.where((g) => g.date.isAfter(book.today)).firstOrNull
            case final g?)
          (
            label: '${l10n.vrVaccineNext} · ${day.format(g.date)}',
            value: null,
            sub: vxGroupLine(l10n, locale, g.items, book.plan),
          ),
      ],
    ];

    String asText() {
      String lines(List<({String label, String? value, String? sub})> rows) => [
        for (final r in rows)
          '• ${r.label}: ${r.value}${r.sub == null ? '' : ' (${r.sub})'}',
      ].join('\n');
      return [
        '${l10n.vrTitle} · $name',
        [
          ?age,
          ?correctedLabel,
          l10n.vrMadeOn(day.format(todayDate)),
        ].join(' · '),
        if (growthRows.isNotEmpty) '\n${l10n.vrGrowth}\n${lines(growthRows)}',
        if (careRows.isNotEmpty) '\n${l10n.vrCare}\n${lines(careRows)}',
        if (vaccineRows.isNotEmpty) '\n${lines(vaccineRows)}',
        if (questions.isNotEmpty)
          '\n${l10n.vrQuestions}\n${[for (final q in questions) '• $q'].join('\n')}',
        '\n${l10n.vrDisclaimer}',
      ].join('\n');
    }

    Widget rowsCard(List<({String label, String? value, String? sub})> rows) =>
        ClCardGroup(
          children: [
            for (final r in rows)
              MeRow(title: r.label, value: r.value, subtitle: r.sub),
          ],
        );

    return MePage(
      title: l10n.vrTitle,
      children: [
        Text(
          [name, ?age, ?correctedLabel].where((s) => s.isNotEmpty).join(' · '),
          style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
        ),
        Text(
          l10n.vrMadeOn(day.format(todayDate)),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        MeSection(l10n.vrGrowth),
        if (growthRows.isEmpty)
          ClCardGroup(children: [MeRow(title: l10n.vrNoGrowth)])
        else
          rowsCard(growthRows),
        MeSection(l10n.vrCare),
        if (records == null)
          const ClSkeleton(height: 160, radius: ClRadius.card)
        else
          rowsCard(careRows),
        if (vaccineRows.isNotEmpty) ...[
          MeSection(l10n.vrVaccines),
          rowsCard(vaccineRows),
        ],
        MeSection(l10n.vrQuestions),
        ClCardGroup(
          children: [
            for (final (i, q) in questions.indexed)
              MeRow(
                title: q,
                trailing: ClPressable(
                  semanticLabel: l10n.vrQuestionRemove(q),
                  onPressed: () => unawaited(
                    ref
                        .read(
                          visitQuestionsProvider((me.uid, me.babyId)).notifier,
                        )
                        .removeAt(i),
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: ClIcon(
                        ClIcons.close,
                        size: 18,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        Row(
          children: [
            Expanded(
              child: ClTextField(
                label: l10n.vrQuestions,
                placeholder: l10n.vrQuestionHint,
                standalone: true,
                controller: _question,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClButton(
              label: l10n.vrQuestionAdd,
              style: ClButtonStyle.plain,
              onPressed: _question.text.trim().isEmpty
                  ? null
                  : () {
                      unawaited(
                        ref
                            .read(
                              visitQuestionsProvider((
                                me.uid,
                                me.babyId,
                              )).notifier,
                            )
                            .add(_question.text),
                      );
                      _question.clear();
                      setState(() {});
                    },
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.vrDisclaimer,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('visitShare'),
          label: l10n.vrShare,
          expand: true,
          onPressed: records == null
              ? null
              : () async {
                  final box = context.findRenderObject() as RenderBox?;
                  final toaster = ClToaster.of(context);
                  try {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: asText(),
                        subject: l10n.vrTitle,
                        sharePositionOrigin: box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      ),
                    );
                  } on Object {
                    toaster.show(message: l10n.toastActionFailed, error: true);
                  }
                },
        ),
      ],
    );
  }
}
