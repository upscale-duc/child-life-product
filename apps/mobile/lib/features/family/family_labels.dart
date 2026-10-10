import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../onboarding/setup_screens.dart' show relationLabel;

export '../onboarding/setup_screens.dart' show relationLabel;

String roleLabel(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.coParent => l10n.roleCoParent,
  MemberRole.caregiver => l10n.roleCaregiver,
  MemberRole.relative => l10n.roleRelative,
};

/// "Mẹ" / custom label of a membership.
String memberRelation(AppLocalizations l10n, Membership m) =>
    relationLabel(l10n, m.relation, m.relationCustom ?? '');

/// "Mẹ · Cùng nuôi" (14a).
String memberDetail(AppLocalizations l10n, Membership m) =>
    l10n.memberDetail(memberRelation(l10n, m), roleLabel(l10n, m.role));

String initialOf(String name) =>
    name.trim().characters.firstOrNull?.toUpperCase() ?? '?';

/// "15 thg 10" / "15 Oct" (pending invite expiry, join date).
String shortDate(BuildContext context, DateTime date) => DateFormat(
  'd MMM',
  Localizations.localeOf(context).toLanguageTag(),
).format(date.toLocal());

/// "31 tháng 12, 2026" / "31 December 2026" (14f Thời hạn).
String longDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  return DateFormat(
    locale.languageCode == 'vi' ? 'd MMMM, y' : 'd MMMM y',
    locale.toLanguageTag(),
  ).format(date);
}

/// What each role can do, as permission tiles (16) and the details sheet (14b). Caregiver tiles
/// follow 30:1259; the other two follow the business-map matrix (§5) and D-018 / D-019.
List<(String, bool)> rolePermissions(
  AppLocalizations l10n,
  MemberRole role, [
  ExtraRights? extra,
]) => switch (role) {
  MemberRole.coParent => [
    (l10n.permLogCare, true),
    (l10n.permAddMemories, true),
    (l10n.permInvite, true),
    (l10n.rightBabyInfo, true),
  ],
  MemberRole.caregiver => [
    (l10n.permLogCare, true),
    (l10n.permViewSchedule, true),
    (l10n.permViewReminders, true),
    (l10n.permMemories, false),
  ],
  MemberRole.relative => [
    (l10n.permViewMemories, true),
    (l10n.permLove, true),
    (l10n.rightBabyInfo, extra?.viewBabyInfo ?? false),
    (l10n.permDailyCare, extra?.viewDailyCare ?? false),
  ],
};
