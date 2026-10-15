import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/route_guard.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart' show Relation;
import '../baby/time_zones.dart' show ensureTimeZones;
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart' show inBabyZone;
import '../onboarding/setup_screens.dart' show relationLabel;
import '../spending/spending_currency.dart' show isSpCurrency;
import '../spending/spending_format.dart' show categoryName, money;
import '../spending/spending_models.dart' show builtInCategories;
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
  DraftProblem.invalidTitle => l10n.asProblemInvalidTitle,
  DraftProblem.pastTime => l10n.asProblemPastTime,
  DraftProblem.invalidAssignee => l10n.asProblemInvalidAssignee,
};

/// D-075 #2 author labels, like record authors (D-024): Mẹ / Ba / Bà / Ông read as the
/// relation, a custom relation as written, anyone else by name; yourself is "Bạn".
String authorName(
  AppLocalizations l10n,
  AssistantAuthor a, {
  required String? myUid,
}) {
  if (a.uid == myUid) return l10n.careYou;
  final relation = Relation.values.asNameMap()[a.relation];
  return switch (relation) {
    Relation.mother ||
    Relation.father ||
    Relation.grandmother ||
    Relation.grandfather => relationLabel(l10n, relation!),
    _ when (a.relationCustom ?? '').trim().isNotEmpty =>
      a.relationCustom!.trim(),
    _ when a.name.trim().isNotEmpty => a.name.trim(),
    _ => relation == null ? l10n.deletedUser : relationLabel(l10n, relation),
  };
}

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
      // Rework 2026-10-15: only the length was said ("ngủ 9 tiếng").
      _ when p.durationMin != null => [
        durationLabel(l10n, p.durationMin!),
        l10n.asNoTime,
      ].join(' · '),
      _ => l10n.asNoTime,
    },
    ExpensePayload() => [
      date(p.date),
      if (p.totalMinor != null) moneyLabel(locale, p.totalMinor!, p.currency),
    ].join(' · '),
    ReminderPayload() => l10n.asRemindLine(
      [
        p.date == null ? l10n.asNoDate : weekdayDate(locale, p.date!),
        p.time ?? l10n.asNoTime,
      ].join(' · '),
    ),
    ObservationPayload() => [date(p.date), ?p.note].join(' · '),
    MealPayload() => [
      p.title,
      if (p.occurredAt != null) when(p.occurredAt),
    ].join(' · '),
    UnknownPayload() => l10n.asKindUnknown,
  };
}

/// An amount in minor units with Chi tiêu's own formatting ("486.000 ₫", "$4,860.00"); a code
/// Chi tiêu does not know stays plain ("12.50 XYZ"). Never a float in the data.
String moneyLabel(String locale, int minor, String? currency) {
  final code = currency ?? 'VND';
  if (isSpCurrency(code)) return money(locale, minor, code);
  final digits = currencyDigits(code);
  var unit = 1;
  for (var i = 0; i < digits; i++) {
    unit *= 10;
  }
  final major = NumberFormat(
    digits == 0 ? '#,##0' : '#,##0.${'0' * digits}',
    locale,
  ).format(minor / unit);
  return '$major $code';
}

/// "14/10/2026" (vi) / "14 Oct 2026" (en) for an ISO local date.
String fullDate(String locale, String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat(
    locale.startsWith('en') ? 'd MMM y' : 'dd/MM/y',
    locale,
  ).format(d);
}

/// "Thứ Ba 20/10" (vi) / "Tue 20 Oct" (en): the real weekday of the date (G03).
String weekdayDate(String locale, String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat(
    locale.startsWith('en') ? 'EEE d MMM' : 'EEEE dd/MM',
    locale,
  ).format(d);
}

/// A built-in Chi tiêu category's name ("Sữa & ăn dặm"); null for one this app cannot name.
String? expenseCategoryName(AppLocalizations l10n, String? categoryId) {
  final c = builtInCategories.where((c) => c.id == categoryId).firstOrNull;
  return c == null ? null : categoryName(l10n, c);
}

/// The card title of a draft: the reminder's own words, "Danh mục · Cửa hàng" for an expense,
/// else the kind (never text the model wrote).
String draftTitle(AppLocalizations l10n, AssistantDraft d) =>
    switch (d.payload) {
      ReminderPayload(:final title) when title.trim().isNotEmpty =>
        title.trim(),
      // Rework 2026-10-15: what was bought ("Học bơi") before the store.
      ExpensePayload(:final merchant, :final categoryId, :final note) => [
        ?expenseCategoryName(l10n, categoryId),
        ?(note ?? merchant),
      ].join(' · ').ifEmpty(l10n.asKindExpense),
      ObservationPayload() => l10n.asObservationTitle,
      _ => kindLabel(l10n, d.kind),
    };

extension AsIfEmpty on String {
  /// [other] when this is empty.
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// CH15 / CH16: what the person reported ("khó vào giấc · giấc đêm").
String sleepConcernLabel(AppLocalizations l10n, String? kind, String? when) => [
  ?switch (kind) {
    'falling_asleep' => l10n.asSleepFalling,
    'night_waking' => l10n.asSleepWaking,
    'both' => l10n.asSleepBoth,
    _ => null,
  },
  ?switch (when) {
    'night' => l10n.asWhenNight,
    'day' => l10n.asWhenDay,
    'both' => l10n.asWhenBoth,
    _ => null,
  },
].join(' · ');

/// CH17 outcome words ("Có ích", "Chưa rõ", "Không phù hợp", "Chưa thử").
String outcomeLabel(AppLocalizations l10n, FeedbackOutcome o) => switch (o) {
  FeedbackOutcome.helpful => l10n.asOutcomeHelpful,
  FeedbackOutcome.unsure => l10n.asOutcomeUnsure,
  FeedbackOutcome.notSuitable => l10n.asOutcomeNotSuitable,
  FeedbackOutcome.notTried => l10n.asOutcomeNotTried,
};

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
