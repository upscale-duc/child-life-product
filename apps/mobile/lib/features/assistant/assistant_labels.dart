import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/route_guard.dart';
import '../../l10n/app_localizations.dart';
import '../baby/time_zones.dart' show ensureTimeZones;
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart' show inBabyZone;
import 'assistant_models.dart';
import 'assistant_rules.dart';

/// Words for the assistant's typed data. Labels always come from the enums (state, kind,
/// reason), never from text the server or the model wrote.

String stateLabel(AppLocalizations l10n, DraftState s) => switch (s) {
  DraftState.draft => l10n.asStateDraft,
  DraftState.needsReview => l10n.asStateReview,
  DraftState.saving => l10n.asStateSaving,
  DraftState.saved => l10n.asStateSaved,
  DraftState.failed => l10n.asStateFailed,
  DraftState.discarded => l10n.asStateDiscarded,
};

String kindLabel(AppLocalizations l10n, DraftKind? k) => switch (k) {
  DraftKind.bottle => l10n.asKindBottle,
  DraftKind.breast => l10n.asKindBreast,
  DraftKind.sleep => l10n.asKindSleep,
  DraftKind.expense => l10n.asKindExpense,
  DraftKind.reminder => l10n.asKindReminder,
  DraftKind.observation => l10n.asKindObservation,
  DraftKind.meal => l10n.asKindMeal,
  null => l10n.asKindUnknown,
};

/// "Teddy · Nhật ký chăm sóc" / "Gia đình · Chi tiêu".
String moduleLabel(AppLocalizations l10n, DraftKind? k, String babyName) =>
    switch (k) {
      DraftKind.bottle ||
      DraftKind.breast ||
      DraftKind.sleep => l10n.asModuleCare(babyName),
      DraftKind.expense => l10n.asModuleSpending,
      DraftKind.reminder => l10n.asModuleReminders,
      DraftKind.observation => l10n.asModuleRhythm(babyName),
      DraftKind.meal => l10n.asModuleMeal(babyName),
      null => l10n.asKindUnknown,
    };

String problemLabel(AppLocalizations l10n, DraftProblem p) => switch (p) {
  DraftProblem.missingAmount => l10n.asProblemMissingAmount,
  DraftProblem.invalidAmount => l10n.asProblemInvalidAmount,
  DraftProblem.missingTime => l10n.asProblemMissingTime,
  DraftProblem.futureTime => l10n.asProblemFutureTime,
  DraftProblem.invalidTime => l10n.asProblemInvalidTime,
  DraftProblem.missingDate => l10n.asProblemMissingDate,
  DraftProblem.currencyUnsupported => l10n.asProblemCurrency,
  DraftProblem.missingTitle => l10n.asProblemMissingTitle,
};

/// The line under a failed card (CH07 puts the reason in "Dòng 1").
String failureLabel(AppLocalizations l10n, AssistantDraft d) =>
    switch (d.error) {
      AssistantReason.domainConflict => l10n.asErrConflict,
      AssistantReason.duplicateSuspected => l10n.asErrDuplicate,
      AssistantReason.writeDenied => l10n.asErrWriteDenied,
      AssistantReason.draftExpired => l10n.asErrExpired,
      AssistantReason.draftStale => l10n.asErrStale,
      AssistantReason.scopeChanged => l10n.asErrScope,
      AssistantReason.moduleUnavailable => l10n.asErrModule,
      AssistantReason.validationFailed || AssistantReason.reviewRequired =>
        d.problems.isEmpty
            ? l10n.asNeedsReview
            : problemLabel(l10n, d.problems.first),
      _ => l10n.asErrSaveFailed,
    };

/// "15/10" (vi) / "15 Oct" (en).
String shortDate(String locale, DateTime day) =>
    DateFormat(locale.startsWith('en') ? 'd MMM' : 'dd/MM', locale).format(day);

/// "Hôm nay 15/10", "Hôm qua 14/10" or "13/10" in the baby's zone.
String dayLabel(
  AppLocalizations l10n,
  String locale,
  DateTime instant,
  String zone,
  DateTime now,
) {
  final local = inBabyZone(zone, instant);
  final today = inBabyZone(zone, now);
  final d = DateTime(local.year, local.month, local.day);
  final t = DateTime(today.year, today.month, today.day);
  final label = shortDate(locale, d);
  if (d == t) return l10n.asDayToday(label);
  if (d == t.subtract(const Duration(days: 1))) {
    return l10n.asDayYesterday(label);
  }
  return label;
}

String hm(DateTime instant, String zone) =>
    DateFormat('HH:mm').format(inBabyZone(zone, instant));

String mlLabel(String locale, num ml) =>
    NumberFormat.decimalPattern(locale).format(ml.round());

/// "Hôm nay 15/10 · 08:00 · 120 ml": the facts of a draft, from its typed payload only.
String draftLine(
  AppLocalizations l10n,
  String locale,
  DraftPayload p,
  String zone,
  DateTime now, {
  String Function(String side)? side,
}) {
  String when(DateTime? at) => at == null
      ? l10n.asNoTime
      : '${dayLabel(l10n, locale, at, zone, now)} · ${hm(at, zone)}';
  String date(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    return d == null ? l10n.asNoDate : shortDate(locale, d);
  }

  return switch (p) {
    BottlePayload() => [
      when(p.occurredAt),
      p.amountMl == null
          ? l10n.asNoAmount
          : l10n.asAmountMl(mlLabel(locale, p.amountMl!)),
    ].join(' · '),
    BreastPayload() => [
      when(p.occurredAt),
      if (p.durationMin != null) durationLabel(l10n, p.durationMin!),
      if (p.side != null && side != null) side(p.side!),
    ].join(' · '),
    SleepPayload() => switch ((p.startedAt, p.endedAt)) {
      (final s?, final e?) => [
        dayLabel(l10n, locale, s, zone, now),
        '${hm(s, zone)} – ${hm(e, zone)}',
        if (e.isAfter(s)) durationLabel(l10n, e.difference(s).inMinutes),
      ].join(' · '),
      _ => l10n.asNoTime,
    },
    ExpensePayload() => [
      ?p.merchant,
      if (p.totalMinor != null)
        p.currency == 'VND' || p.currency == null
            ? '${NumberFormat.decimalPattern('vi').format(p.totalMinor)} ₫'
            : '${p.totalMinor} ${p.currency}',
      date(p.date),
    ].join(' · '),
    ReminderPayload() => [
      if (p.title.trim().isNotEmpty) p.title,
      date(p.date),
      ?p.time,
    ].join(' · '),
    ObservationPayload() => [date(p.date), ?p.note].join(' · '),
    MealPayload() => [
      p.title,
      if (p.occurredAt != null) when(p.occurredAt),
    ].join(' · '),
    UnknownPayload() => l10n.asKindUnknown,
  };
}

/// Where a saved record opens. Only allowlisted in-app locations are followed (the server's
/// module adapter builds them); anything else falls back to the module, never an arbitrary link.
String? recordLocation(AssistantDraft d) {
  final link = d.recordLink;
  final id = d.recordId;
  final safeId = RegExp(r'^[A-Za-z0-9_-]{1,120}$');
  // The server's module adapter names records `/care/records/{babyId}/{recordId}` and
  // `/rhythm/checkins/{babyId}/{checkInId}` (api.md "Confirm"): mapped to the app's routes.
  final adapter = RegExp(
    r'^/(care/records|rhythm/checkins)/[A-Za-z0-9_-]{1,128}/([A-Za-z0-9_-]{1,120})$',
  ).firstMatch(link ?? '');
  if (adapter != null) {
    return adapter.group(1) == 'care/records'
        ? '${Routes.record}/${adapter.group(2)}'
        : Routes.rhythm;
  }
  if (link != null) {
    final uri = Uri.tryParse(link);
    const allowed = [
      Routes.record,
      Routes.spendingExpense,
      Routes.reminders,
      Routes.rhythm,
      Routes.history,
    ];
    if (uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        allowed.any((a) => uri.path == a || uri.path.startsWith('$a/')) &&
        uri.pathSegments.every(safeId.hasMatch)) {
      return uri.path;
    }
  }
  return switch (d.kind) {
    DraftKind.bottle || DraftKind.breast || DraftKind.sleep =>
      id != null && safeId.hasMatch(id)
          ? '${Routes.record}/$id'
          : Routes.history,
    DraftKind.expense =>
      id != null && safeId.hasMatch(id)
          ? '${Routes.spendingExpense}/$id'
          : Routes.spending,
    DraftKind.reminder => Routes.reminders,
    DraftKind.observation => Routes.rhythm,
    _ => null,
  };
}

/// The module list a saved record lives in ("Mở nhật ký" / "Mở Chi tiêu").
String? moduleLocation(DraftKind? k) => switch (k) {
  DraftKind.bottle || DraftKind.breast || DraftKind.sleep => Routes.history,
  DraftKind.expense => Routes.spending,
  DraftKind.reminder => Routes.reminders,
  DraftKind.observation => Routes.rhythm,
  _ => null,
};

String openModuleLabel(AppLocalizations l10n, DraftKind? k) => switch (k) {
  DraftKind.expense => l10n.asOpenSpending,
  DraftKind.reminder => l10n.asOpenReminders,
  DraftKind.observation => l10n.asOpenRhythm,
  _ => l10n.asOpenLog,
};

/// The pill text of Chat/Mức dùng for [v] (never the component's default "18/20"). The reset
/// date is read in the household's (here: the baby's) zone.
String usagePillText(
  AppLocalizations l10n,
  String locale,
  UsageView v,
  String zone,
) {
  final reset = resetDate(locale, v.usage, zone);
  return switch (v.level) {
    UsageLevel.ok => l10n.asUsageLeft(v.remaining, v.limit),
    UsageLevel.near => l10n.asUsageNear(v.remaining, v.limit, reset),
    UsageLevel.out => l10n.asUsageOut(v.limit, reset),
  };
}

/// "01/11" / "1 Nov": the first day of the next window (`resetsAt` is its exclusive end).
String resetDate(String locale, AssistantUsage u, String zone) {
  final at = u.resetsAt;
  if (at == null) return '';
  final local = inBabyZone(zone, at);
  return shortDate(locale, DateTime(local.year, local.month, local.day));
}

/// The instant of a wall-clock time in the baby's zone (what the CH06 pickers return).
DateTime fromBabyWall(String zone, DateTime wall) {
  ensureTimeZones();
  try {
    return tz.TZDateTime(
      tz.getLocation(zone),
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    ).toUtc();
  } on Object {
    return wall.toUtc();
  }
}
