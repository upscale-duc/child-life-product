import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/timer_models.dart';
import '../library/content_repository.dart' show contentEmergencyNumberProvider;
import '../reminders/reminder_repository.dart';
import '../rhythm/personal_day_pages.dart' show PersonalHeading;
import '../rhythm/rhythm_calc.dart' show isoOf;
import '../rhythm/rhythm_labels.dart' show shortDay;
import '../rhythm/rhythm_models.dart';
import '../rhythm/rhythm_repository.dart';
import '../rhythm/rhythm_widgets.dart';
import '../vaccines/vaccine_format.dart';

/// The handover's live part (owner, 2026-10-25: "Thông tin màn hình bàn giao này đã đủ cho
/// người chăm sóc chưa"): what the next person needs in 30 seconds, read from the diary as it is
/// now, not from the week the summary covers. Bé lúc này (sleep, feed, diaper), Sắp tới (today's
/// reminders, the next vaccines), Cần lưu ý (health signs of the last two days, the emergency
/// number, Sơ cứu) and Cách giúp bé (ideas the family found helpful). Shown with or without an
/// AI summary; the screen already requires `historyRead`.
class HandoverNow extends ConsumerWidget {
  const HandoverNow({required this.me, super.key});
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    String hhmm(DateTime t) => DateFormat('HH:mm').format(inBabyZone(zone, t));
    final local = inBabyZone(zone, now);
    final todayStart = DateTime(local.year, local.month, local.day);
    bool isToday(DateTime t) => !inBabyZone(zone, t).isBefore(todayStart);

    final records = [
      for (final r
          in ref.watch(recentRecordsProvider(me.babyId)).value ??
              const <CareRecord>[])
        if (!r.deleted) r,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    CareRecord? latest(bool Function(CareRecord) test) =>
        records.where(test).firstOrNull;
    final sleepTimer = ref
        .watch(careTimerProvider((me.babyId, TimerType.sleep)))
        .value;
    final sleep = latest((r) => r.type == CareType.sleep && r.endedAt != null);
    final feed = latest(
      (r) => r.type == CareType.bottle || r.type == CareType.breast,
    );
    final diaper = latest((r) => r.type == CareType.diaper);
    final diapersToday = records
        .where((r) => r.type == CareType.diaper && isToday(r.occurredAt))
        .length;

    // The next feed: the last feed plus the usual gap of the last day (three feeds or more).
    DateTime? nextFeed;
    final dayFeeds = [
      for (final r in records)
        if ((r.type == CareType.bottle || r.type == CareType.breast) &&
            now.difference(r.occurredAt) < const Duration(hours: 24))
          r.occurredAt,
    ];
    if (feed != null && dayFeeds.length >= 3) {
      var gaps = 0;
      for (var i = 0; i + 1 < dayFeeds.length; i++) {
        gaps += dayFeeds[i].difference(dayFeeds[i + 1]).inMinutes;
      }
      final at = feed.occurredAt.add(
        Duration(minutes: gaps ~/ (dayFeeds.length - 1)),
      );
      if (at.isAfter(now)) nextFeed = at;
    }

    final sleepTile = sleepTimer != null
        ? _Tile(
            icon: ClIcons.sleep,
            label: l.hoSleep,
            value: l.hoSleepingSince(hhmm(sleepTimer.startedAt)),
            detail: durationLabel(
              l,
              now.difference(sleepTimer.startedAt).inMinutes,
            ),
          )
        : sleep != null
        ? _Tile(
            icon: ClIcons.sleep,
            label: l.hoSleep,
            value: l.hoAwakeSince(hhmm(sleep.endedAt!)),
            detail: relativeAgo(l, sleep.endedAt!, now),
          )
        : _Tile(icon: ClIcons.sleep, label: l.hoSleep, value: l.hoNoneYet);
    final feedTile = feed == null
        ? _Tile(icon: ClIcons.feed, label: l.hoFeed, value: l.hoNoneYet)
        : _Tile(
            icon: ClIcons.feed,
            label: careTypeLabel(l, feed.type),
            value: [
              hhmm(feed.occurredAt),
              if (feed.amountMl case final ml?) l.amountMl(ml),
            ].join(' · '),
            detail: nextFeed == null
                ? relativeAgo(l, feed.occurredAt, now)
                : l.hoNextFeed(hhmm(nextFeed)),
          );
    final diaperTile = diaper == null
        ? _Tile(icon: ClIcons.diaper, label: l.hoDiaper, value: l.hoNoneYet)
        : _Tile(
            icon: ClIcons.diaper,
            label: l.hoDiaper,
            value: [
              if (diaper.diaper case final kind?) diaperValue(l, kind),
              hhmm(diaper.occurredAt),
            ].join(' · '),
            detail: l.hoDiapersToday(diapersToday),
          );

    // Sắp tới: today's open reminders, then the next vaccines within a week.
    final reminders = [
      for (final r in ref.watch(remindersProvider(me.babyId)).value ?? const [])
        if (!r.done &&
            (r.allDay
                ? r.dueDate == isoOf(local)
                : isToday(r.dueAt) &&
                      r.dueAt.isAfter(now.subtract(const Duration(hours: 1)))))
          r,
    ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final vaccine = me.canViewBabyInfo
        ? switch (ref.watch(vaccineBookProvider(me))) {
            VaccineBookReady(:final book) => book.nextGroup,
            _ => null,
          }
        : null;
    final vaccineSoon =
        vaccine != null &&
        vaccine.date.difference(todayStart) <= const Duration(days: 7);

    // Cần lưu ý: health signs noted today or yesterday.
    final yesterday = isoOf(todayStart.subtract(const Duration(days: 1)));
    final health = [
      for (final c in ref.watch(checkInsProvider(me.babyId)).value ?? const [])
        if (c.date.compareTo(yesterday) >= 0 &&
            (c.needsHealthSupport || c.healthSigns.isNotEmpty))
          c,
    ];
    final emergency = ref.watch(contentEmergencyNumberProvider);

    // Cách giúp bé: the latest ideas found helpful, once each.
    final content = ref.watch(rhythmContentProvider).value;
    final helpful = <String>[];
    for (final f in [
      ...(ref.watch(recFeedbackProvider(me.babyId)).value ?? const []),
    ]..sort((a, b) => b.date.compareTo(a.date))) {
      if (f.kind == FeedbackKind.helpful && !helpful.contains(f.contentId)) {
        helpful.add(f.contentId);
      }
    }

    Widget row(
      ClIcons icon,
      String title, {
      String? trailing,
      Color? tint,
      VoidCallback? onTap,
    }) {
      final child = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        child: Row(
          children: [
            ClIcon(icon, size: 18, color: tint ?? cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                title,
                style: cl.text.body.copyWith(color: tint ?? cl.colors.ink),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            if (onTap != null) ...[
              const SizedBox(width: ClSpace.s1),
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
            ],
          ],
        ),
      );
      return onTap == null
          ? child
          : ClPressable(onPressed: onTap, semanticLabel: title, child: child);
    }

    Widget group(List<Widget> rows) => RhCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: ClSpace.s4),
                color: cl.colors.separator,
              ),
            r,
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalHeading(l.hoNow),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sleepTile),
            const SizedBox(width: ClSpace.s2),
            Expanded(child: feedTile),
            const SizedBox(width: ClSpace.s2),
            Expanded(child: diaperTile),
          ],
        ),
        PersonalHeading(l.hoUpcoming),
        if (reminders.isEmpty && !vaccineSoon)
          Text(
            l.hoNothingUpcoming,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          )
        else
          group([
            for (final r in reminders.take(4))
              row(
                ClIcons.bell,
                r.title,
                trailing: r.allDay ? l.hoAllDay : hhmm(r.dueAt),
              ),
            if (vaccineSoon)
              row(
                ClIcons.calendar,
                l.todayVaccineShots(vaccine.items.length),
                trailing: vxDay(vaccine.date),
                onTap: () => context.push(Routes.vaccines),
              ),
          ]),
        PersonalHeading(l.hoWatch),
        group([
          if (health.isEmpty)
            row(ClIcons.check, l.hoNoHealth)
          else
            for (final c in health.take(2))
              row(
                ClIcons.alert,
                l.hoHealthNoted(shortDay(locale, c.date)),
                tint: cl.colors.danger,
                onTap: () => context.push(Routes.rhythmHealth),
              ),
          row(
            ClIcons.phone,
            l.hoCall(emergency),
            onTap: () => ref.read(rhythmDialerProvider)(emergency),
          ),
          row(
            ClIcons.shield,
            l.hoFirstAid,
            onTap: () => context.push(Routes.firstAid),
          ),
        ]),
        if (helpful.isNotEmpty && content != null) ...[
          PersonalHeading(l.hoHelps),
          group([
            for (final id in helpful.take(3))
              if (content.activity(id) case final a?)
                row(
                  ClIcons.heart,
                  a.title.of(locale),
                  tint: cl.colors.mintText,
                  onTap: () => context.push('${Routes.rhythmActivity}/$id'),
                ),
          ]),
        ],
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });
  final ClIcons icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: [label, value, ?detail].join(', '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.control),
            border: Border.all(color: cl.colors.separator),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClIcon(icon, size: 14, color: cl.colors.inkMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s1),
              Text(value, style: cl.text.bodyStrong),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
