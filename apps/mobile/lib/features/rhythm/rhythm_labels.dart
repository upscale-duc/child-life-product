import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_format.dart' show durationLabel;
import '../family/family_labels.dart' show relationLabel;
import 'rhythm_calc.dart';
import 'rhythm_models.dart';

/// Copy for Nhịp lớn lên: every string comes from the ARB catalogs (D-012).

String observationLabel(AppLocalizations l10n, Observation o) => switch (o) {
  Observation.sleep => l10n.rhObsSleep,
  Observation.feeding => l10n.rhObsFeeding,
  Observation.soothing => l10n.rhObsSoothing,
  Observation.newSkill => l10n.rhObsNewSkill,
  Observation.usual => l10n.rhObsUsual,
  Observation.health => l10n.rhObsHealth,
};

String observationShort(AppLocalizations l10n, Observation o) => switch (o) {
  Observation.sleep => l10n.rhObsShortSleep,
  Observation.feeding => l10n.rhObsShortFeeding,
  Observation.soothing => l10n.rhObsShortSoothing,
  Observation.newSkill => l10n.rhObsShortNewSkill,
  Observation.usual => l10n.rhObsShortUsual,
  Observation.health => l10n.rhObsShortHealth,
};

/// "con khó vào giấc" / "Teddy struggled to settle".
String observationWhat(AppLocalizations l10n, Observation o, String baby) =>
    switch (o) {
      Observation.sleep => l10n.rhWhatSleep(baby),
      Observation.feeding => l10n.rhWhatFeeding(baby),
      Observation.soothing => l10n.rhWhatSoothing(baby),
      Observation.newSkill => l10n.rhWhatNewSkill(baby),
      _ => l10n.rhWhatOther(baby),
    };

String whenLabel(AppLocalizations l10n, Observation o, CheckInWhen w) =>
    switch ((o, w)) {
      (Observation.sleep, CheckInWhen.night) => l10n.rhWhenNightSleep,
      (Observation.sleep, CheckInWhen.day) => l10n.rhWhenDaySleep,
      (_, CheckInWhen.night) => l10n.rhWhenNight,
      (_, CheckInWhen.day) => l10n.rhWhenDay,
      (_, CheckInWhen.both) => l10n.rhWhenBoth,
    };

String whenSummary(AppLocalizations l10n, Observation o, CheckInWhen w) =>
    switch ((o, w)) {
      (Observation.sleep, CheckInWhen.night) => l10n.rhSumNightSleep,
      (Observation.sleep, CheckInWhen.day) => l10n.rhSumDaySleep,
      (_, CheckInWhen.night) => l10n.rhSumNight,
      (_, CheckInWhen.day) => l10n.rhSumDay,
      (_, CheckInWhen.both) => l10n.rhSumBoth,
    };

String sinceLabel(AppLocalizations l10n, CheckInSince s) => switch (s) {
  CheckInSince.today => l10n.rhSinceToday,
  CheckInSince.days2to3 => l10n.rhSince23,
  CheckInSince.longer => l10n.rhSinceLonger,
};

String sinceSummary(AppLocalizations l10n, CheckInSince s) => switch (s) {
  CheckInSince.today => l10n.rhSumToday,
  CheckInSince.days2to3 => l10n.rhSince23,
  CheckInSince.longer => l10n.rhSumLonger,
};

String triedLabel(AppLocalizations l10n, Tried t) => switch (t) {
  Tried.rocking => l10n.rhTriedRocking,
  Tried.whiteNoise => l10n.rhTriedWhiteNoise,
  Tried.feeding => l10n.rhTriedFeeding,
  Tried.skinToSkin => l10n.rhTriedSkin,
  Tried.swaddle => l10n.rhTriedSwaddle,
  Tried.none => l10n.rhTriedNone,
};

String signLabel(AppLocalizations l10n, HealthSign s) => switch (s) {
  HealthSign.feverYoung => l10n.rhSignFeverYoung,
  HealthSign.breathing => l10n.rhSignBreathing,
  HealthSign.lethargic => l10n.rhSignLethargic,
  HealthSign.poorFeeding => l10n.rhSignPoorFeeding,
  HealthSign.inconsolable => l10n.rhSignInconsolable,
  HealthSign.lostSkill => l10n.rhSignLostSkill,
  HealthSign.dehydration => l10n.rhSignDehydration,
  HealthSign.seizure => l10n.rhSignSeizure,
};

/// The published label when there is one, else the app's own (NL05b works offline).
String signText(AppLocalizations l10n, Locale locale, HealthSignContent s) {
  final published = s.label.of(locale);
  return published.isEmpty ? signLabel(l10n, s.sign) : published;
}

String feedbackKindLabel(AppLocalizations l10n, FeedbackKind k) => switch (k) {
  FeedbackKind.helpful => l10n.rhHelpful,
  FeedbackKind.unsure => l10n.rhUnsure,
  FeedbackKind.notSuitable => l10n.rhNotAFit,
  FeedbackKind.notToday => l10n.rhNotToday,
  FeedbackKind.started => l10n.rhIllTry,
};

String changeLabel(AppLocalizations l10n, RecChange c) => switch (c) {
  RecChange.prefersHelpful => l10n.rhChangePrefersHelpful,
  RecChange.excludedNotSuitable => l10n.rhChangeExcluded,
  RecChange.coolingDown => l10n.rhChangeCooling,
};

/// "Khó vào giấc · giấc đêm · 2–3 ngày" (PS01 saved banner).
List<String> checkInParts(AppLocalizations l10n, CheckIn c) => [
  observationShort(l10n, c.observation),
  if (c.when case final w?) whenSummary(l10n, c.observation, w),
  if (c.since case final s?) sinceSummary(l10n, s),
];

/// "khó vào giấc, giấc đêm, 2–3 ngày" for quotes (PS01 why, AC01 reason).
String checkInQuote(AppLocalizations l10n, CheckIn c) {
  final text = checkInParts(l10n, c).join(', ');
  return l10n.rhQuoted(text.isEmpty ? text : _lowerFirst(text));
}

String _lowerFirst(String s) => s[0].toLowerCase() + s.substring(1);

/// "A, B và C" / "A, B and C".
String joinNames(AppLocalizations l10n, List<String> names) =>
    switch (names.length) {
      0 => '',
      1 => names.single,
      _ => l10n.rhJoinTwo(
        names.sublist(0, names.length - 1).join(', '),
        names.last,
      ),
    };

/// D-024 for members: Mẹ / Ba / Bà / Ông read as the label, everyone else as their name; you are
/// "Bạn" ([sentenceStart]) or "bạn".
String memberLabel(
  AppLocalizations l10n,
  Membership? m, {
  required String myUid,
  String? uid,
  bool sentenceStart = true,
}) {
  final who = uid ?? m?.uid;
  if (who == myUid) return sentenceStart ? l10n.careYou : l10n.rhWhoYou;
  if (m == null) return l10n.deletedUser;
  return switch (m.relation) {
    Relation.mother ||
    Relation.father ||
    Relation.grandmother ||
    Relation.grandfather => relationLabel(l10n, m.relation),
    _ => m.displayName,
  };
}

/// "11/10" (vi) / "11 Oct" (en).
String shortDay(Locale locale, String isoDate) {
  final d = DateTime.parse(isoDate);
  return locale.languageCode == 'en'
      ? DateFormat('d MMM', 'en').format(d)
      : DateFormat('dd/MM', 'vi').format(d);
}

String dayRange(AppLocalizations l10n, Locale locale, StageWindow w) =>
    l10n.rhDateRange(shortDay(locale, w.start), shortDay(locale, w.end));

/// "hôm nay" / "tối qua" / "hôm qua" / "ngày 07/10" for a check-in date, seen on [today].
String checkInWhen(
  AppLocalizations l10n,
  Locale locale,
  CheckIn c,
  String today,
) {
  if (c.date == today) return l10n.rhWhenToday;
  if (c.date == addDaysIso(today, -1)) {
    return c.when == CheckInWhen.night
        ? l10n.rhWhenLastNight
        : l10n.rhWhenYesterday;
  }
  return l10n.rhWhenOn(shortDay(locale, c.date));
}

/// "0–3 tháng" from an age range in days.
String ageRangeLabel(AppLocalizations l10n, AgeRange r) =>
    l10n.rhMonthsRange((r.from / 30.44).round(), ((r.to + 1) / 30.44).round());

String activityMeta(AppLocalizations l10n, Activity a) => l10n.rhDurationFit(
  durationLabel(l10n, a.durationMin),
  ageRangeLabel(l10n, a.ageDays),
);

/// "Nội dung minh hoạ · chờ chuyên môn duyệt" until a reviewer signs it (D-073 #2).
String reviewLabel(AppLocalizations l10n, ContentReview? r) => r == null
    ? l10n.rhReviewPending
    : l10n.rhReviewedBy(r.reviewer, r.credential);
