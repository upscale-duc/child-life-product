import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import 'care_models.dart';
import 'who_growth.dart' show GrowthMeasure;

/// Copy rules for care (S4): relative times (Q-029 → D-023), attribution (Q-030 → D-024),
/// amounts with the locale's decimal comma (28: "4,3 kg").

/// Full form in the app: "Vừa xong", "45 phút trước", "1 giờ 25 phút trước", "2 ngày trước".
String relativeAgo(AppLocalizations l10n, DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return l10n.agoJustNow;
  if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) {
    final minutes = diff.inMinutes % 60;
    return minutes == 0
        ? l10n.agoHours(diff.inHours)
        : l10n.agoHoursMinutes(diff.inHours, minutes);
  }
  return l10n.agoDays(diff.inDays);
}

/// "15 phút", "1 giờ 20 phút".
String durationLabel(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.durationMinutes(minutes);
  final m = minutes % 60;
  return m == 0
      ? l10n.durationHours(minutes ~/ 60)
      : l10n.durationHoursMinutes(minutes ~/ 60, m);
}

/// "4,3" / "4.3" — one decimal, trailing ",0" dropped ("4 kg", "53 cm").
String decimal(String locale, double value) {
  final format = NumberFormat('#0.#', locale);
  return format.format(value);
}

/// Parses "4,3" or "4.3" typed with either separator.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// D-024: Mẹ / Ba / Bà / Ông read as the label, everyone else as their name; you are "Bạn".
String authorLabel(
  AppLocalizations l10n,
  CareAuthor author, {
  required bool isMe,
  required String Function(Relation, String) relationLabel,
}) {
  if (isMe) return l10n.careYou;
  if (author.deleted) return l10n.deletedUser;
  return switch (author.relation) {
    Relation.mother ||
    Relation.father ||
    Relation.grandmother ||
    Relation.grandfather => relationLabel(author.relation, ''),
    _ => author.name,
  };
}

/// "Mẹ Mai (bạn)" on 21 "Người ghi": label + name, "(bạn)" for yourself.
String authorFull(
  AppLocalizations l10n,
  CareAuthor author, {
  required bool isMe,
  required String Function(Relation, String) relationLabel,
}) {
  if (author.deleted) return l10n.deletedUser;
  final label = relationLabel(author.relation, author.relationCustom ?? '');
  final full = switch (author.relation) {
    Relation.mother ||
    Relation.father ||
    Relation.grandmother ||
    Relation.grandfather => '$label ${author.name}',
    _ => author.name,
  };
  return isMe ? l10n.careYouSuffix(full) : full;
}

String milkLabel(AppLocalizations l10n, MilkType milk) => switch (milk) {
  MilkType.breastMilk => l10n.milkBreast,
  MilkType.formula => l10n.milkFormula,
};

String sideLabel(AppLocalizations l10n, Side side) => switch (side) {
  Side.left => l10n.sideLeft,
  Side.right => l10n.sideRight,
  Side.both => l10n.sideBoth,
};

/// Tile value: "Tã ướt".
String diaperValue(AppLocalizations l10n, DiaperKind kind) => switch (kind) {
  DiaperKind.wet => l10n.diaperWetValue,
  DiaperKind.dirty => l10n.diaperDirtyValue,
  DiaperKind.both => l10n.diaperBothValue,
};

/// Choice tile label: "Ướt".
String diaperChoice(AppLocalizations l10n, DiaperKind kind) => switch (kind) {
  DiaperKind.wet => l10n.diaperWet,
  DiaperKind.dirty => l10n.diaperDirty,
  DiaperKind.both => l10n.sideBoth,
};

String careTypeLabel(AppLocalizations l10n, CareType type) => switch (type) {
  CareType.bottle => l10n.trackerBottle,
  CareType.breast => l10n.trackerBreast,
  CareType.pump => l10n.trackerPump,
  CareType.sleep => l10n.trackerSleep,
  CareType.diaper => l10n.trackerDiaper,
  CareType.growth => l10n.trackerGrowth,
};

/// The headline of a record: "120 ml", "15 phút", "Tã ướt", "4,3 kg".
String recordValue(AppLocalizations l10n, String locale, CareRecord r) =>
    switch (r.type) {
      CareType.bottle =>
        r.amountMl != null
            ? l10n.amountMl(r.amountMl!)
            : milkLabel(l10n, r.milk ?? MilkType.formula),
      CareType.breast =>
        r.durationMin != null
            ? durationLabel(l10n, r.durationMin!)
            : sideLabel(l10n, r.side ?? Side.both),
      CareType.pump => l10n.amountMl(r.amountMl ?? 0),
      CareType.diaper => diaperValue(l10n, r.diaper ?? DiaperKind.wet),
      CareType.growth => l10n.weightKg(decimal(locale, r.weightKg ?? 0)),
      CareType.sleep => durationLabel(
        l10n,
        (r.endedAt ?? r.occurredAt).difference(r.occurredAt).inMinutes,
      ),
    };

/// Toast and list summary: "Bú bình 120 ml", "Thay tã · Ướt".
String recordSummary(AppLocalizations l10n, String locale, CareRecord r) =>
    '${careTypeLabel(l10n, r.type)} · ${switch (r.type) {
      CareType.diaper => diaperChoice(l10n, r.diaper ?? DiaperKind.wet),
      _ => recordValue(l10n, locale, r),
    }}';

/// The 20d / 20i tab of a growth measure: "Cân nặng" / "Chiều dài" / "Vòng đầu".
String growthMeasureTab(AppLocalizations l10n, GrowthMeasure m) => switch (m) {
  GrowthMeasure.weight => l10n.growthWeightTab,
  GrowthMeasure.length => l10n.growthLengthTab,
  GrowthMeasure.head => l10n.growthHeadTab,
};

/// What a refused care write was (SY-4): the toast names the record and the action.
enum CareWrite { create, edit, delete, restore, timer }

/// "Chưa lưu được: Bú bình · 120 ml, 14:05", plus "Có thể quyền của bạn đã thay đổi." only when
/// the server said so (SY-4: one generic sentence covered every failure before).
String careWriteFailed(
  AppLocalizations l10n,
  String locale,
  CareWrite write,
  Object error, [
  CareRecord? record,
]) {
  final what = record == null ? '' : recordSummary(l10n, locale, record);
  final at = record == null
      ? ''
      : DateFormat.Hm(locale).format(record.occurredAt);
  final message = switch (write) {
    _ when record == null => l10n.careFailedTimer,
    CareWrite.create => l10n.careFailedNew(what, at),
    CareWrite.edit => l10n.careFailedEdit(what, at),
    CareWrite.delete => l10n.careFailedDelete(what, at),
    CareWrite.restore => l10n.careFailedRestore(what, at),
    CareWrite.timer => l10n.careFailedTimer,
  };
  return error is FirebaseException && error.code == 'permission-denied'
      ? l10n.careFailedDenied(message)
      : message;
}
