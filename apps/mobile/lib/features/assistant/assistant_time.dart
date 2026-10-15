import 'package:flutter/foundation.dart';

import '../../l10n/app_localizations.dart';
import '../care/care_format.dart' show durationLabel;
import '../care/care_repository.dart' show inBabyZone;
import 'assistant_labels.dart' show fromBabyWall, hm, shortDate;

/// Linked time editing for the chat's drafts and clarifications (owner feedback 2026-10-15:
/// "báo ngủ 9 tiếng … chọn giờ ngủ thì không tự chọn giờ dậy để đủ 9 tiếng"). Start, end and
/// duration move together: a new start keeps the duration (the end follows), a new duration
/// moves the end, a new end changes the duration. Times are instants; the pickers show the
/// baby's wall clock, and a wall time resolves to the occurrence nearest the current value, so
/// "21:00" next to a 06:00 wake-up is yesterday evening (cross-midnight).

/// Shortest and longest span the editors offer (a sleep log, not a clinical norm).
const minSpanMinutes = 5;
const maxSpanMinutes = 24 * 60;

@immutable
class LinkedSpan {
  const LinkedSpan(this.start, this.end);

  /// A span of [minutes] that ends at [end] (the woke-up-now guess of a "ngủ 9 tiếng").
  factory LinkedSpan.endingAt(DateTime end, int minutes) =>
      LinkedSpan(end.subtract(Duration(minutes: minutes)), end);

  final DateTime start;
  final DateTime end;

  int get minutes => end.difference(start).inMinutes;

  /// A new start keeps the duration: the end moves with it.
  LinkedSpan withStart(DateTime s) =>
      LinkedSpan(s, s.add(end.difference(start)));

  /// A new end changes the duration (the start stays).
  LinkedSpan withEnd(DateTime e) => LinkedSpan(start, e);

  /// A new duration moves the end, clamped to [minSpanMinutes]…[maxSpanMinutes].
  LinkedSpan withMinutes(int m) => LinkedSpan(
    start,
    start.add(Duration(minutes: m.clamp(minSpanMinutes, maxSpanMinutes))),
  );

  @override
  bool operator ==(Object other) =>
      other is LinkedSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'LinkedSpan($start → $end)';
}

/// The occurrence of wall time [hour]:[minute] in [zone] nearest to [near] (the day before,
/// the same day or the day after [near]'s wall day).
DateTime nearestWall(
  String zone,
  int hour,
  int minute, {
  required DateTime near,
}) {
  final wall = inBabyZone(zone, near);
  DateTime on(int dayOffset) => fromBabyWall(
    zone,
    DateTime(wall.year, wall.month, wall.day + dayOffset, hour, minute),
  );
  final candidates = [on(-1), on(0), on(1)];
  candidates.sort(
    (a, b) => a
        .difference(near)
        .inSeconds
        .abs()
        .compareTo(b.difference(near).inSeconds.abs()),
  );
  return candidates.first;
}

/// The first occurrence of wall time [hour]:[minute] after [start] (within a day): an end picked
/// before the start's clock time crosses midnight.
DateTime wallAfter(String zone, int hour, int minute, DateTime start) {
  final wall = inBabyZone(zone, start);
  for (var d = 0; d <= 2; d++) {
    final at = fromBabyWall(
      zone,
      DateTime(wall.year, wall.month, wall.day + d, hour, minute),
    );
    if (at.isAfter(start)) return at;
  }
  return start.add(const Duration(minutes: minSpanMinutes));
}

/// The occurrence of wall time [hour]:[minute] at or before [end] (within a day): the start of a
/// span whose end is fixed.
DateTime wallBefore(String zone, int hour, int minute, DateTime end) {
  final wall = inBabyZone(zone, end);
  for (var d = 0; d >= -2; d--) {
    final at = fromBabyWall(
      zone,
      DateTime(wall.year, wall.month, wall.day + d, hour, minute),
    );
    if (at.isBefore(end)) return at;
  }
  return end.subtract(const Duration(minutes: minSpanMinutes));
}

/// Moves [span]'s start to wall time [hour]:[minute] (the occurrence nearest the current
/// start), keeping the duration. A start after [now] is never a completed log, so it then
/// moves to the day before ("23:00" picked at 14:00 is last night).
LinkedSpan pickStart(
  LinkedSpan span,
  String zone,
  int hour,
  int minute, {
  required DateTime now,
}) {
  var s = nearestWall(zone, hour, minute, near: span.start);
  if (s.isAfter(now)) s = s.subtract(const Duration(days: 1));
  return span.withStart(s);
}

/// Moves [span]'s end to the first wall time [hour]:[minute] after its start.
LinkedSpan pickEnd(LinkedSpan span, String zone, int hour, int minute) =>
    span.withEnd(wallAfter(zone, hour, minute, span.start));

/// "Hôm nay" / "Hôm qua" / "13/10" for the wall day of [at] (lower case inside a line).
String relativeDay(
  AppLocalizations l10n,
  String locale,
  DateTime at,
  String zone,
  DateTime now, {
  bool lower = false,
}) {
  final d = inBabyZone(zone, at);
  final t = inBabyZone(zone, now);
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inHours ~/ 24;
  final out = switch (diff) {
    0 => l10n.asWhenToday,
    1 => l10n.asWhenYesterday,
    -1 => l10n.asWhenTomorrow,
    _ => shortDate(locale, day),
  };
  return lower ? out.toLowerCase() : out;
}

/// "21:00 – 06:00 · 9 giờ", with "hôm qua" after the start when it is on another day than the
/// end, and the end's day when that is not today ("21:00 hôm qua – 06:00 · 9 giờ").
String spanLine(
  AppLocalizations l10n,
  String locale,
  LinkedSpan span,
  String zone,
  DateTime now,
) {
  final startDay = relativeDay(
    l10n,
    locale,
    span.start,
    zone,
    now,
    lower: true,
  );
  final endDay = relativeDay(l10n, locale, span.end, zone, now, lower: true);
  final crosses =
      inBabyZone(zone, span.start).day != inBabyZone(zone, span.end).day;
  final endToday = endDay == l10n.asWhenToday.toLowerCase();
  final start = crosses
      ? l10n.asTimeOnDay(hm(span.start, zone), startDay)
      : hm(span.start, zone);
  final end = endToday
      ? hm(span.end, zone)
      : l10n.asTimeOnDay(hm(span.end, zone), endDay);
  final minutes = span.minutes;
  return l10n.asSpanLine(
    start,
    end,
    minutes > 0 ? durationLabel(l10n, minutes) : l10n.asSpanInvalid,
  );
}

/// The duration a parent said in words ("ngủ 9 tiếng", "1 tiếng rưỡi", "45 phút", "for 2
/// hours"), in minutes; null when none is said. "9 giờ" and "9h" are clock times in Vietnamese,
/// so they never count as a duration.
int? spokenDurationMinutes(String text) {
  final t = text.toLowerCase();
  var minutes = 0;
  var found = false;
  final hours = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(?:tiếng|tieng|hours?|hrs?)(?![a-zà-ỹ])(\s*rưỡi)?',
  ).firstMatch(t);
  if (hours != null) {
    final n = double.tryParse(hours.group(1)!.replaceAll(',', '.'));
    if (n != null) {
      minutes += (n * 60).round();
      if (hours.group(2) != null) minutes += 30;
      found = true;
    }
  }
  final rest = hours == null ? t : t.substring(hours.end);
  final mins = RegExp(
    r'(\d+)\s*(?:phút|phut|mins?|minutes?)(?![a-zà-ỹ])',
  ).firstMatch(rest);
  if (mins != null) {
    minutes += int.parse(mins.group(1)!);
    found = true;
  }
  if (!found || minutes < minSpanMinutes || minutes > maxSpanMinutes) {
    return null;
  }
  return minutes;
}

/// A clarification that asks for a clock time (the free answer then gets a time picker).
bool isTimeField(String field) {
  final f = field.toLowerCase();
  return f == 'time.missing' ||
      f.endsWith('.time') ||
      f.endsWith('.start') ||
      f.endsWith('.end') ||
      f.endsWith('startedat') ||
      f.endsWith('endedat') ||
      f.endsWith('occurredat') ||
      f.endsWith('.wake') ||
      f.endsWith('.onset_time');
}

/// The asked time is the END of a span (wake-up), so a known duration previews its start.
bool isEndField(String field) {
  final f = field.toLowerCase();
  return f.endsWith('.end') || f.endsWith('endedat') || f.endsWith('.wake');
}

/// "HH:mm" (what a clarification's free answer carries; the server reads Vietnamese and 24 h).
String hhmm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
