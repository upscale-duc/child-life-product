import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/navigation.dart' show SafePushContext;
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/format/age.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_repository.dart' show aiShareProvider;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_repository.dart';
import '../family/family_labels.dart' show relationLabel;
import '../family/family_repository.dart';
import '../keepsakes/keepsake_access.dart' show selectedKeepsakeAccessProvider;
import '../memories/memory_models.dart' show MediaItem;
import '../memories/memory_repository.dart' show completeMediaProvider;
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_gate.dart';
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import '../reminders/reminder_models.dart';
import '../reminders/reminder_repository.dart';
import '../vaccines/vaccine_format.dart';
import 'activity_history_screen.dart' show TriedHistoryLink;
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_own.dart' show RecentCheckIns, SleepFactsBlock;
import 'rhythm_repository.dart';
import 'rhythm_week.dart';
import 'rhythm_widgets.dart';
import 'personalization_v2_screen.dart' show PersonalWeekBlock;

/// EN09 "Tóm tắt tuần" (561:3102), reached from NL01, Hôm nay and the Sunday 20:30 notification
/// (EN07 / EN08). Two parts that never mix: "Đã ghi trong tuần" (free, the family's log, with
/// how much of it is complete) and "Nhìn lại tuần qua" (group A `rhythm.advanced`: the sleep
/// comparison, the week's check-ins, what was tried, one next idea — built from facts, no AI).
/// Without group A the look-back is explained by its reason, nothing fake is blurred. Only for
/// members who read care (`history.read`, D-072 #2). The mock's "Tuần 4" and figures are not
/// copied (extract 30 Q4–Q5): the week number counts from the date of birth.
class WeekSummaryScreen extends ConsumerWidget {
  const WeekSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final caps = ref.watch(selectedCapabilitiesProvider);
    final close = RhRoundIcon(
      icon: ClIcons.close,
      label: l10n.a11yClose,
      onPressed: () => leaveRhythm(context),
    );
    if (me == null) {
      return OnboardingScaffold(
        topBar: _TopBar(close: close),
        content: const [],
      );
    }
    Widget refused(String text) => OnboardingScaffold(
      topBar: _TopBar(close: close),
      content: [
        Text(l10n.rhWeekTitle, style: cl.text.title),
        const SizedBox(height: ClSpace.s3),
        RhInfoBox(icon: ClIcons.lock, text: text),
      ],
    );
    if (caps != null && !caps.features.rhythm) {
      return refused(l10n.pmGateDisabledBody);
    }
    if (!familyCan(me, FamilyAction.historyRead)) {
      return refused(l10n.rhWeekNoAccess);
    }

    final baby = ref.watch(babyProvider(me.babyId)).value;
    final name = baby?.nickname ?? '';
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = babyTodayIso(zone, now);
    final week = summaryWeekFor(today);
    final dob = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value?.dateOfBirth
        : null;
    final n = dob == null ? null : weekOfLife(dob, week);
    final range = weekRangeLabel(l10n, locale, week.start, week.end);
    // Owner, 2026-10-22: no "Tuần thứ N" (it read as the age); the dates say which week.
    final title = name.isEmpty
        ? l10n.rhWeekTitle
        : week.inProgress
        ? l10n.rhWeekOfNow(name)
        : l10n.rhWeekOfPast(name);
    final facts = ref.watch(
      weekFactsProvider((
        babyId: me.babyId,
        zone: zone,
        today: today,
        parent: me.role == MemberRole.coParent,
      )),
    );
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];

    return OnboardingScaffold(
      topBar: _TopBar(
        close: close,
        // Owner, 2026-10-22: "Gửi cho…" offers the week as a picture first (any app in the
        // share sheet), the plain text second.
        onShare: facts == null
            ? null
            : (origin) => showClSheet<void>(
                context: context,
                builder: (_) => _WeekShareSheet(
                  card: _WeekShareCard(
                    title: title,
                    range: range,
                    age: dob == null
                        ? null
                        : ageLong(l10n, dob, DateTime.parse(week.end)),
                    facts: facts,
                    zone: zone,
                    members: members,
                  ),
                  fileName: 'child-life-week-${week.start}.png',
                  onText: () => ref.read(aiShareProvider)(
                    weekShareText(
                      l10n,
                      locale,
                      title: title,
                      range: range,
                      facts: facts,
                      zone: zone,
                      members: members,
                    ),
                    l10n.rhWeekTitle,
                    origin,
                  ),
                ),
              ),
      ),
      content: [
        Text(range, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
        const SizedBox(height: 2),
        Semantics(header: true, child: Text(title, style: cl.text.title)),
        if (week.inProgress) ...[
          const SizedBox(height: ClSpace.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: RhPill(label: l10n.rhWeekInProgress, icon: ClIcons.clock),
          ),
        ],
        const SizedBox(height: ClSpace.s6),
        // D-116: no "Từ nhật ký của cả nhà" under the title; every figure here is from the log.
        _SectionTitle(title: l10n.rhWeekRecordedTitle),
        const SizedBox(height: ClSpace.s3),
        if (facts == null)
          const ClSkeleton(height: 220, radius: 16)
        else ...[
          _Tiles(facts: facts, zone: zone),
          // D-116: the sleep tile already says "trung bình ngày ghi đủ · 6/7 ngày ghi đủ"; the
          // note repeating it stays only in the shared text, where there is no tile.
          const SizedBox(height: ClSpace.s4),
          _FamilyCard(me: me, facts: facts, members: members),
        ],
        const SizedBox(height: ClSpace.s6),
        _NextWeek(me: me, week: week, zone: zone, now: now),
        const SizedBox(height: ClSpace.s6),
        _SectionTitle(title: l10n.rhWeekInsightTitle),
        const SizedBox(height: ClSpace.s3),
        _LookBack(me: me, caps: caps, week: week, zone: zone, today: today),
        WeekVideoButton(me: me, week: week, zone: zone, weekOfLife: n),
        const SizedBox(height: ClSpace.s3),
        const PersonalWeekBlock(),
        const SizedBox(height: ClSpace.s6),
        RhNote(l10n.rhWeekNoScore, icon: ClIcons.heart),
      ],
    );
  }
}

/// "5 – 11 tháng 10" / "28 tháng 9 – 4 tháng 10" ("5 – 11 October").
String weekRangeLabel(
  AppLocalizations l10n,
  Locale locale,
  String start,
  String end,
) {
  final tag = locale.languageCode == 'en' ? 'en' : 'vi';
  final a = DateTime.parse(start), b = DateTime.parse(end);
  final full = DateFormat('d MMMM', tag);
  return l10n.rhDateRange(
    a.month == b.month ? '${a.day}' : full.format(a),
    full.format(b),
  );
}

/// Close on the left, "Gửi cho…" on the right (EN09 top bar).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.close, this.onShare});
  final Widget close;
  final Future<void> Function(Rect? origin)? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Row(
      children: [
        close,
        const Spacer(),
        if (onShare != null)
          Builder(
            builder: (button) => ClPressable(
              semanticLabel: l10n.rhWeekShare,
              onPressed: () {
                final box = button.findRenderObject() as RenderBox?;
                onShare!(
                  box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                );
              },
              child: Container(
                height: ClSpace.tapMin,
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClIcon(ClIcons.upload, size: 16, color: cl.colors.ink),
                    const SizedBox(width: ClSpace.s2),
                    Text(
                      l10n.rhWeekShare,
                      style: cl.text.label.copyWith(
                        color: cl.colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
      child: Semantics(
        header: true,
        child: Text(title, style: cl.text.headline),
      ),
    );
  }
}

// ---------- Free records ----------

/// One stat tile: the care colour family of the record (EN09 2×2 grid).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.lines,
    required this.fill,
    required this.ink,
  });

  final ClIcons icon;
  final String label;
  final String value;
  final List<String> lines;
  final Color fill;

  /// Label, icon and detail lines on [fill]; the value stays `ink`.
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClIcon(icon, size: 16, color: ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: cl.text.caption.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              value,
              style: cl.text.headline.copyWith(
                color: cl.colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final line in lines) ...[
              const SizedBox(height: 2),
              Text(line, style: cl.text.caption.copyWith(color: ink)),
            ],
          ],
        ),
      ),
    );
  }
}

/// "4,3 kg" (the value of the growth tile) and "54,5 cm" (a line under it); length alone when
/// only the length was measured.
(String, String?) _measure(AppLocalizations l10n, String locale, WeekFacts f) {
  final g = f.growth!;
  final length = g.lengthCm == null
      ? null
      : l10n.lengthCm(decimal(locale, g.lengthCm!));
  return g.weightKg == null
      ? (length ?? '', null)
      : (l10n.weightKg(decimal(locale, g.weightKg!)), length);
}

/// "+0,4 kg so với 28/09", or the day it was measured.
String _growthLine(
  AppLocalizations l10n,
  Locale locale,
  WeekFacts f,
  String zone,
) {
  final g = f.growth!;
  final prev = f.previousWeight;
  if (g.weightKg == null || prev == null) {
    return l10n.rhWeekGrowthOn(shortDay(locale, measuredDate(zone, g)));
  }
  final delta = g.weightKg! - prev.weightKg!;
  final sign = delta > 0.04
      ? '+'
      : delta < -0.04
      ? '−'
      : '±';
  return l10n.rhWeekGrowthSince(
    '$sign${l10n.weightKg(decimal(locale.toLanguageTag(), delta.abs()))}',
    shortDay(locale, measuredDate(zone, prev)),
  );
}

/// The feeds, sleep, diapers, growth and Kỷ niệm figures of a week, as text lines
/// ([label], [value], [lines]); shared by the tiles and the plain-text share.
List<({String label, String value, List<String> lines})> weekFigures(
  AppLocalizations l10n,
  Locale locale,
  WeekFacts f,
  String zone,
) {
  final tag = locale.toLanguageTag();
  final ml = NumberFormat.decimalPattern(tag);
  final avg = f.averageSleepMinutes;
  final coverage = l10n.rhWeekCoverage(f.validDays, f.days.length);
  return [
    (
      label: l10n.rhWeekFeeds,
      value: f.feeds == 0 ? l10n.rhWeekNone : l10n.rhWeekFeedCount(f.feeds),
      lines: [
        if (f.bottleCount > 0) l10n.rhWeekBottle(ml.format(f.bottleMl)),
        if (f.breastCount > 0)
          l10n.rhWeekBreast(durationLabel(l10n, f.breastMinutes)),
      ],
    ),
    (
      label: l10n.rhWeekSleep,
      value: avg == null ? l10n.rhWeekSleepSparse : durationLabel(l10n, avg),
      lines: avg == null
          ? [coverage, l10n.rhWeekSleepNeed(f.minValidDays)]
          : [l10n.rhWeekSleepAvg, coverage],
    ),
    (
      label: l10n.rhWeekDiapers,
      value: f.diapers == 0
          ? l10n.rhWeekNone
          : l10n.rhWeekDiaperCount(f.diapers),
      lines: [if (f.diapers > 0) l10n.rhWeekDiaperKinds(f.wet, f.dirty)],
    ),
    if (f.growth != null)
      (
        label: l10n.rhWeekGrowth,
        value: _measure(l10n, tag, f).$1,
        lines: [?_measure(l10n, tag, f).$2, _growthLine(l10n, locale, f, zone)],
      ),
    if (f.hasMemories)
      (
        label: l10n.rhWeekMemories,
        value: l10n.rhWeekPhotos(f.photos),
        lines: [
          [
            if (f.videos > 0) l10n.rhWeekVideos(f.videos),
            if (f.notes > 0) l10n.rhWeekNotes(f.notes),
          ].join(' · '),
        ].where((s) => s.isNotEmpty).toList(),
      ),
  ];
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.facts, required this.zone});
  final WeekFacts facts;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final figures = weekFigures(l10n, locale, facts, zone);
    final care = cl.care;
    final styles = <(ClIcons, Color, Color)>[
      (ClIcons.feed, care.bottle.soft, care.bottle.ink),
      (ClIcons.sleep, care.sleep.soft, care.sleep.ink),
      (ClIcons.diaper, care.diaper.soft, care.diaper.ink),
      if (facts.growth != null)
        (ClIcons.ruler, care.growth.soft, care.growth.ink),
      // Ink on the soft warm fill, also in Night care.
      if (facts.hasMemories)
        (ClIcons.memories, cl.colors.sunshineSoft, cl.colors.ink),
    ];
    final tiles = [
      for (final (i, f) in figures.indexed)
        _Tile(
          icon: styles[i].$1,
          label: f.label,
          value: f.value,
          lines: f.lines,
          fill: styles[i].$2,
          ink: styles[i].$3,
        ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: ClSpace.s2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                // An odd last tile takes the whole row instead of leaving a hole.
                if (i + 1 < tiles.length) ...[
                  const SizedBox(width: ClSpace.s2),
                  Expanded(child: tiles[i + 1]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Mẹ": the family label of one author (D-024), "Bạn" for me on screen ([myUid]).
String authorName(
  AppLocalizations l10n,
  AuthorCount a,
  List<Membership> members, {
  required String myUid,
}) {
  final m = members.where((x) => x.uid == a.uid).firstOrNull;
  final who = m != null || a.uid == myUid
      ? memberLabel(l10n, m, myUid: myUid, uid: a.uid)
      : authorLabel(
          l10n,
          a.author,
          isMe: false,
          relationLabel: (r, c) => relationLabel(l10n, r, c),
        );
  return capitalized(who);
}

/// "Mẹ 41 lần" for one author (shared text and screen readers).
String authorCountLabel(
  AppLocalizations l10n,
  AuthorCount a,
  List<Membership> members, {
  required String myUid,
}) =>
    l10n.rhWeekFamilyCount(authorName(l10n, a, members, myUid: myUid), a.count);

/// "Cả nhà đã cùng chăm": entries per person, in the order they first logged; no ranking.
class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.me,
    required this.facts,
    required this.members,
  });
  final Membership me;
  final WeekFacts facts;
  final List<Membership> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final most = facts.authors.fold<int>(
      1,
      (m, a) => a.count > m ? a.count : m,
    );
    // A container, not merged: each person's bar is read on its own ("Mẹ 15 lần").
    return RhCard(
      child: Semantics(
        container: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RhIconTile(icon: ClIcons.family),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.rhWeekFamilyTitle, style: cl.text.bodyStrong),
                  const SizedBox(height: 2),
                  // One bar per person, in the order they first logged (D-102: numbers as a
                  // visual, not "Bạn 21 lần · Cô Lan 14 lần · Ba 20 lần" in a sentence).
                  if (facts.authors.isEmpty)
                    Text(
                      l10n.rhWeekFamilyEmpty,
                      style: cl.text.label.copyWith(color: cl.colors.ink),
                    )
                  else
                    for (final a in facts.authors)
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s1),
                        child: Semantics(
                          label: authorCountLabel(
                            l10n,
                            a,
                            members,
                            myUid: me.uid,
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    authorName(l10n, a, members, myUid: me.uid),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: cl.text.label.copyWith(
                                      color: cl.colors.ink,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, box) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: box.maxWidth * a.count / most,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: cl.colors.mintDeep,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${a.count}',
                                    textAlign: TextAlign.end,
                                    style: cl.text.label.copyWith(
                                      color: cl.colors.ink,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  if (facts.authors.isNotEmpty) ...[
                    const SizedBox(height: ClSpace.s1),
                    Text(
                      l10n.rhWeekFamilyNote,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Tuần tới ----------

typedef _NextItem = ({
  String sortKey,
  ClIcons icon,
  Color fill,
  Color ink,
  String title,
  String sub,
});

/// "Tuần tới": what the family already set for the next Monday–Sunday (open reminders, vaccine
/// doses of the book) and the reference-calendar window, if any (free). Nothing is invented.
class _NextWeek extends ConsumerWidget {
  const _NextWeek({
    required this.me,
    required this.week,
    required this.zone,
    required this.now,
  });
  final Membership me;
  final SummaryWeek week;
  final String zone;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final from = dayBoundsIn(zone, week.nextStart).start;
    final to = dayBoundsIn(zone, week.nextEnd).end;
    // "Thứ Bảy 10/10" / "Saturday 10 Oct".
    String when(DateTime local) => capitalized(
      DateFormat(
        locale.languageCode == 'en' ? 'EEEE d MMM' : 'EEEE dd/MM',
        tag,
      ).format(local),
    );

    final items = <_NextItem>[];
    // Relatives keep no reminders (S7); the Rules would refuse the read.
    if (me.role != MemberRole.relative) {
      final reminders =
          ref.watch(remindersProvider(me.babyId)).value ?? const <Reminder>[];
      for (final r in reminders) {
        if (r.done || r.dueAt.isBefore(from) || !r.dueAt.isBefore(to)) {
          continue;
        }
        if (r.dueAt.isBefore(now)) continue;
        final local = inBabyZone(zone, r.dueAt);
        // D-075 #5: an all-day reminder shows its day and "Cả ngày", not 23:59.
        final day = r.dueDay;
        items.add((
          sortKey: isoOf(day ?? local),
          icon: ClIcons.bell,
          fill: cl.colors.mintSoft,
          ink: cl.colors.mintText,
          title: r.title,
          sub: day != null
              ? '${when(day)} · ${l10n.reminderAllDay}'
              : '${when(local)} · ${DateFormat('HH:mm', tag).format(local)}',
        ));
      }
    }
    if (ref.watch(vaccineBookProvider(me)) case VaccineBookReady(
      :final book,
    ) when book.plan.exists) {
      for (final item in book.items) {
        final day = isoOf(item.planned);
        if (item.done ||
            day.compareTo(week.nextStart) < 0 ||
            day.compareTo(week.nextEnd) > 0) {
          continue;
        }
        items.add((
          sortKey: day,
          icon: ClIcons.check,
          fill: cl.colors.mintSoft,
          ink: cl.colors.mintText,
          title: vxDoseTitle(l10n, tag, item, book.plan),
          sub: when(item.planned),
        ));
      }
    }
    final due = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value?.dueDate?.date
        : null;
    final model = ref.watch(rhythmReferenceProvider).value;
    if (due != null && model != null) {
      for (final s in model.stages) {
        final w = windowOf(due, s);
        if (w.start.compareTo(week.nextEnd) > 0 ||
            w.end.compareTo(week.nextStart) < 0) {
          continue;
        }
        items.add((
          sortKey: w.start,
          icon: ClIcons.spark,
          fill: cl.care.sleep.soft,
          ink: cl.care.sleep.ink,
          title: l10n.rhStageName(s.number),
          sub: l10n.rhWeekReference(dayRange(l10n, locale, w)),
        ));
      }
    }
    items.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.rhWeekNextTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
          child: Text(
            weekRangeLabel(l10n, locale, week.nextStart, week.nextEnd),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        RhCard(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s2,
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
                  child: Text(
                    l10n.rhWeekNextEmpty,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, it) in items.indexed) ...[
                      if (i > 0)
                        Container(height: 1, color: cl.colors.separator),
                      MergeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: ClSpace.s3,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: it.fill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: ClIcon(it.icon, size: 18, color: it.ink),
                              ),
                              const SizedBox(width: ClSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.title,
                                      style: cl.text.label.copyWith(
                                        color: cl.colors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      it.sub,
                                      style: cl.text.caption.copyWith(
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
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------- Group A look-back ----------

/// "Nhìn lại tuần qua" with `rhythm.advanced`; else why not, by its reason (only
/// PREMIUM_REQUIRED leads to the plan, [showGateSheet] explains the rest).
class _LookBack extends ConsumerWidget {
  const _LookBack({
    required this.me,
    required this.caps,
    required this.week,
    required this.zone,
    required this.today,
  });
  final Membership me;
  final Capabilities? caps;
  final SummaryWeek week;
  final String zone;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final advanced = caps?.allows(Capability.rhythmAdvanced) ?? false;
    if (!advanced) {
      final reason =
          caps?.reasonFor(Capability.rhythmAdvanced) ??
          GateReason.premiumRequired;
      final premium = reason == GateReason.premiumRequired;
      return RhInfoBox(
        icon: ClIcons.spark,
        label: l10n.rhSupportTitle,
        text: premium ? l10n.rhWeekGatePremium : l10n.rhWeekGateOther,
        child: Align(
          alignment: Alignment.centerLeft,
          child: RhLink(
            label: premium ? l10n.rhLearnMore : l10n.rhWhy,
            onTap: () => premium
                ? openPaywall(context, entry: PaywallEntry.rhythm)
                : showGateSheet(context, reason),
          ),
        ),
      );
    }

    // The comparison as of the week's end: its last days against the usual level before them
    // (on a Sunday, the days up to yesterday).
    final compareDay = week.inProgress ? today : addDaysIso(week.end, 1);
    final summary = ref.watch(
      sleepSummaryProvider((babyId: me.babyId, zone: zone, today: compareDay)),
    );
    final checkIns =
        ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[];
    final notes = weekNotes(checkIns, week);
    final episode = ref
        .watch(episodesProvider(me.babyId))
        .value
        ?.where((e) => e.open)
        .firstOrNull;
    final feedback =
        ref.watch(recFeedbackProvider(me.babyId)).value ??
        const <RecFeedback>[];
    final tried = weekTried(feedback, week);
    final content = ref.watch(rhythmContentProvider).value;
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final rec = ref
        .watch(recommendationsProvider(me.babyId))
        .value
        ?.where((r) => r.active)
        .firstOrNull;
    final idea = rec == null ? null : content?.activity(rec.contentId);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          color: cl.colors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    Widget muted(String text) =>
        Text(text, style: cl.text.label.copyWith(color: cl.colors.inkMuted));
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
      child: Container(height: 1, color: cl.colors.separator),
    );

    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary == null)
            const ClSkeleton(height: 96)
          else
            SleepFactsBlock(summary: summary, today: compareDay),
          divider,
          heading(l10n.rhWeekNotesTitle),
          if (notes.isEmpty && episode == null)
            muted(l10n.rhWeekNoNotes)
          else ...[
            // Owner, 2026-10-22: the week's days at a glance (the same strip as Nhịp lớn
            // lên), then what changed as chips with their counts.
            RecentCheckIns(
              me: me,
              today: today,
              end: week.inProgress ? today : week.end,
            ),
            if (notes.observations.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s3),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in notes.observations)
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: cl.colors.sunshineSoft,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ink on the soft warm fill, also in Night care.
                          ClIcon(
                            RecentCheckIns.iconOf(o.observation),
                            size: 14,
                            color: cl.colors.ink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.rhWeekObsChip(
                              observationShort(l10n, o.observation),
                              o.days,
                            ),
                            style: cl.text.caption.copyWith(
                              color: cl.colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (episode != null) ...[
              const SizedBox(height: ClSpace.s2),
              RhPill(
                label: l10n.rhEpOpenTitle(shortDay(locale, episode.startDate)),
                icon: ClIcons.eye,
                mint: true,
              ),
            ],
          ],
          divider,
          heading(l10n.rhWeekTriedTitle),
          if (tried.isEmpty)
            muted(l10n.rhWeekNoTried)
          else ...[
            for (final f in tried)
              _TriedLine(
                feedback: f,
                title:
                    content?.activity(f.contentId)?.title.of(locale) ??
                    l10n.rhUnknownActivity,
                who: capitalized(
                  memberLabel(
                    l10n,
                    members.where((m) => m.uid == f.authorUid).firstOrNull,
                    myUid: me.uid,
                    uid: f.authorUid,
                  ),
                ),
              ),
            // D-076 #10: every plan and answer, answerable later.
            const TriedHistoryLink(),
          ],
          if (idea != null) ...[
            divider,
            heading(l10n.rhWeekNextIdea),
            Text(
              idea.title.of(locale),
              style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
            ),
            RhLink(
              label: l10n.rhHow,
              start: true,
              onTap: () => context.push(
                activityLocation(idea.id, checkInId: rec!.checkInId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TriedLine extends StatelessWidget {
  const _TriedLine({
    required this.feedback,
    required this.title,
    required this.who,
  });
  final RecFeedback feedback;
  final String title;
  final String who;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    // A plan is not "đã thử" (D-076 #10).
    final kind = feedback.kind == FeedbackKind.started
        ? l10n.rhPlannedPill
        : feedbackKindLabel(l10n, feedback.kind);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: ClSpace.s2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.label.copyWith(
                      color: cl.colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.rhWhoDay(who, shortDay(locale, feedback.date)),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            // The same tag colours as the handover: helpful solid mint, a plan sunshine.
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: switch (feedback.kind) {
                  FeedbackKind.helpful => cl.colors.mintDeep,
                  FeedbackKind.started => cl.colors.sunshineSoft,
                  _ => cl.colors.surface2,
                },
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                kind,
                style: cl.text.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: switch (feedback.kind) {
                    FeedbackKind.helpful => cl.colors.onMintDeep,
                    FeedbackKind.started => cl.colors.ink,
                    _ => cl.colors.inkMuted,
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- "Tạo video tuần N" (D-076 #3) ----------

/// The baby's own photos taken in [week] (baby-local days), oldest first: what a week video is
/// made from (never a card or a video Child Life made).
List<MediaItem> weekPhotos(
  List<MediaItem> media,
  SummaryWeek week,
  String zone,
) {
  final photos = [
    for (final m in media)
      if (m.isReady && !m.deleted && !m.isVideo && m.generatedKind == null)
        if (isoOf(inBabyZone(zone, m.captureAt)) case final day
            when day.compareTo(week.start) >= 0 && day.compareTo(week.end) <= 0)
          m,
  ];
  return photos..sort((a, b) => a.captureAt.compareTo(b.captureAt));
}

/// EN09 "Tạo video tuần N" (561:3102): Video kỷ niệm (MM04 → MM06) with the week's photos
/// already in the scenes; the flow keeps its own rules (the `memory_story` flag, Cùng nuôi only,
/// the export quota, Premium templates and the purchase resume, which keeps the photos). Hidden
/// without the flag or without a photo from the week. N is the week of life the title shows.
class WeekVideoButton extends ConsumerWidget {
  const WeekVideoButton({
    required this.me,
    required this.week,
    required this.zone,
    required this.weekOfLife,
    super.key,
  });

  final Membership me;
  final SummaryWeek week;
  final String zone;
  final int? weekOfLife;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(selectedKeepsakeAccessProvider).videos) {
      return const SizedBox.shrink();
    }
    final media =
        ref.watch(completeMediaProvider((me.babyId, true))).value ??
        const <MediaItem>[];
    final photos = weekPhotos(media, week, zone);
    if (photos.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final n = weekOfLife;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            key: const ValueKey('rh.weekVideo'),
            label: n == null
                ? l10n.rhWeekMakeVideoPlain
                : l10n.rhWeekMakeVideo(n),
            icon: ClIcons.video,
            expand: true,
            // D-076 nav: EN09 is above the tabs; Video kỷ niệm is a Kỷ niệm page.
            onPressed: () => context.pushSafe(
              Routes.memoryStory,
              extra: [for (final m in photos) m.id],
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.rhWeekVideoPhotos(photos.length),
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ---------- Share ----------

/// The week as a picture for "Gửi cho…": always drawn in Light (it is read by someone else, on
/// any screen), the free figures and who logged, never the look-back or notes.
class _WeekShareCard extends StatelessWidget {
  const _WeekShareCard({
    required this.title,
    required this.range,
    required this.age,
    required this.facts,
    required this.zone,
    required this.members,
  });
  final String title;
  final String range;
  final String? age;
  final WeekFacts facts;
  final String zone;
  final List<Membership> members;

  @override
  Widget build(BuildContext context) => Theme(
    data: buildClTheme(ClPalette.light),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        return Container(
          width: 360,
          padding: const EdgeInsets.all(ClSpace.s6),
          color: cl.colors.cloud,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: cl.text.title2.copyWith(fontWeight: FontWeight.w700),
              ),
              if (age case final a?) ...[
                const SizedBox(height: ClSpace.s1),
                Text(
                  a,
                  style: cl.text.label.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: ClSpace.s4),
              _Tiles(facts: facts, zone: zone),
              if (facts.authors.isNotEmpty) ...[
                const SizedBox(height: ClSpace.s3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ClSpace.s3),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    boxShadow: cl.shadows.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${l10n.rhWeekFamilyTitle}: ${[for (final a in facts.authors) authorCountLabel(l10n, a, members, myUid: '')].join(' · ')}',
                    style: cl.text.label.copyWith(color: cl.colors.ink),
                  ),
                ),
              ],
              const SizedBox(height: ClSpace.s4),
              Row(
                children: [
                  ClIcon(ClIcons.heart, size: 14, color: cl.colors.mintText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.rhWeekShareFooter,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// "Gửi tổng kết tuần": the picture as it will be sent, "Gửi ảnh" through the system share
/// sheet and "Gửi dạng chữ".
class _WeekShareSheet extends StatefulWidget {
  const _WeekShareSheet({
    required this.card,
    required this.fileName,
    required this.onText,
  });
  final Widget card;
  final String fileName;
  final Future<void> Function() onText;

  @override
  State<_WeekShareSheet> createState() => _WeekShareSheetState();
}

class _WeekShareSheetState extends State<_WeekShareSheet> {
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _sendImage() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: 1080 / boundary.size.width,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      await file.writeAsBytes(png!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: l10n.rhWeekTitle,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        ClSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.rhWeekShareSheet),
          Flexible(
            child: SingleChildScrollView(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RepaintBoundary(key: _boundary, child: widget.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            key: const Key('weekShareImage'),
            label: l10n.rhWeekShareImage,
            expand: true,
            onPressed: _busy ? null : _sendImage,
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            key: const Key('weekShareText'),
            label: l10n.rhWeekShareTextOnly,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: _busy ? null : widget.onText,
          ),
        ],
      ),
    );
  }
}

/// "Gửi cho…": the free figures of the week as plain text, with their coverage; never the
/// look-back. Family labels, never "Bạn" (the reader is someone else).
String weekShareText(
  AppLocalizations l10n,
  Locale locale, {
  required String title,
  required String range,
  required WeekFacts facts,
  required String zone,
  required List<Membership> members,
}) {
  final figures = weekFigures(l10n, locale, facts, zone);
  final avg = facts.averageSleepMinutes;
  String value(({String label, String value, List<String> lines}) f) =>
      [f.value, ...f.lines].join(' · ');
  return [
    '$title · $range',
    '',
    l10n.rhWeekShareFrom,
    for (final (i, f) in figures.indexed)
      '• ${l10n.rhWeekShareLine(f.label, i == 1 && avg != null ? [l10n.rhWeekShareSleep(durationLabel(l10n, avg)), l10n.rhWeekCoverage(facts.validDays, facts.days.length)].join(' · ') : value(f))}',
    if (facts.authors.isNotEmpty)
      '• ${l10n.rhWeekShareLine(l10n.rhWeekFamilyTitle, [for (final a in facts.authors) authorCountLabel(l10n, a, members, myUid: '')].join(' · '))}',
    '',
    l10n.rhWeekCoverageNote,
    l10n.rhWeekNoScore,
  ].join('\n');
}

// ---------- Entry (NL01, Hôm nay) ----------

/// "Tóm tắt tuần · Tuần 3 của Teddy · 28/09 – 04/10" → EN09. The caller checks the rollout and
/// `history.read`.
class WeekSummaryEntry extends ConsumerWidget {
  const WeekSummaryEntry({required this.me, super.key});
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final week = summaryWeekFor(babyTodayIso(zone, now));
    // Short dates here ("28/09 – 04/10"), so the row stays on one line.
    final range = l10n.rhDateRange(
      shortDay(locale, week.start),
      shortDay(locale, week.end),
    );
    // Owner, 2026-10-22: the dates alone (a week number read as the age).
    final sub = range;
    return RhCard(
      onTap: () => context.push(Routes.rhythmWeek),
      semanticLabel: '${l10n.rhWeekTitle}. $sub',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClIcon(ClIcons.journal, size: 20, color: cl.colors.mintText),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.rhWeekTitle, style: cl.text.bodyStrong),
                Text(
                  sub,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
        ],
      ),
    );
  }
}
