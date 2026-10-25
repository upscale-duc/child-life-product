import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
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
import '../rhythm/rhythm_calc.dart' show isoOf;
import '../rhythm/rhythm_labels.dart' show shortDay;
import '../rhythm/rhythm_models.dart';
import '../rhythm/rhythm_repository.dart';
import '../vaccines/vaccine_format.dart';

/// P-180 v2 (owner, 2026-10-25, mockup approved): the handover's live part, read from the diary
/// as it is now. A carer's 5-second question is "is the baby asleep, and since when?": one hero
/// card answers it with the duration in large type and a 24 h strip of sleep, feeds and diapers.
/// Then the last feed and diaper as "how long ago" tiles, what comes next (the next feed with a
/// progress bar, today's reminders, vaccines within a week) and the ideas found helpful. Health
/// signs and the emergency buttons are [HandoverSafety], placed by the screen above its action.
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
    String ago(DateTime t) => relativeAgo(l, t, now);
    String span(Duration d) => durationLabel(l, math.max(1, d.inMinutes));

    final records = [
      for (final r
          in ref.watch(recentRecordsProvider(me.babyId)).value ??
              const <CareRecord>[])
        if (!r.deleted) r,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    bool isFeed(CareRecord r) =>
        r.type == CareType.bottle || r.type == CareType.breast;
    final timer = ref
        .watch(careTimerProvider((me.babyId, TimerType.sleep)))
        .value;
    final sleeps = [
      for (final r in records)
        if (r.type == CareType.sleep && r.endedAt != null) r,
    ];
    final lastSleep = sleeps.firstOrNull;
    final feed = records.where(isFeed).firstOrNull;
    final diaper = records.where((r) => r.type == CareType.diaper).firstOrNull;
    final diapersToday = records
        .where((r) => r.type == CareType.diaper && isToday(r.occurredAt))
        .length;
    // Last night: a sleep of 3 h or more that ended today (a carer's "did they sleep?").
    final night = sleeps
        .where(
          (r) =>
              isToday(r.endedAt!) &&
              r.endedAt!.difference(r.occurredAt).inHours >= 3,
        )
        .firstOrNull;

    // The next feed: the last feed plus the usual gap over the last day (three feeds or more).
    DateTime? nextFeed;
    final dayFeeds = [
      for (final r in records)
        if (isFeed(r) &&
            now.difference(r.occurredAt) < const Duration(hours: 24))
          r.occurredAt,
    ];
    if (feed != null && dayFeeds.length >= 3) {
      final gap =
          dayFeeds.first.difference(dayFeeds.last).inMinutes ~/
          (dayFeeds.length - 1);
      nextFeed = feed.occurredAt.add(Duration(minutes: gap));
    }

    // Tiếp theo: the next feed, today's open reminders, the next vaccines within a week.
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

    final content = ref.watch(rhythmContentProvider).value;
    final helpful = <String>[];
    for (final f in [
      ...(ref.watch(recFeedbackProvider(me.babyId)).value ?? const []),
    ]..sort((a, b) => b.date.compareTo(a.date))) {
      if (f.kind == FeedbackKind.helpful && !helpful.contains(f.contentId)) {
        helpful.add(f.contentId);
      }
    }

    final asleep = timer != null;
    final since = asleep ? timer.startedAt : lastSleep?.endedAt;
    final sub = [
      if (!asleep && lastSleep != null && lastSleep != night)
        l.hoLastNap(span(lastSleep.endedAt!.difference(lastSleep.occurredAt))),
      if (night != null)
        l.hoLastNight(span(night.endedAt!.difference(night.occurredAt))),
    ];
    final hero = _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: asleep ? l.hoAsleep : l.hoAwake,
                fill: cl.care.sleep.soft,
                ink: cl.care.sleep.ink,
              ),
              if (since != null) ...[
                const SizedBox(width: ClSpace.s2),
                Text(
                  asleep ? l.hoSleptAt(hhmm(since)) : l.hoWokeAt(hhmm(since)),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ClTabularText(
              since == null ? l.hoNoneYet : span(now.difference(since)),
              style: cl.text.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub.join(' · '),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          _DayStrip(
            now: now,
            sleeps: [
              for (final r in sleeps) (r.occurredAt, r.endedAt!),
              if (timer != null) (timer.startedAt, now),
            ],
            feeds: [
              for (final r in records)
                if (isFeed(r)) r.occurredAt,
            ],
            diapers: [
              for (final r in records)
                if (r.type == CareType.diaper) r.occurredAt,
            ],
            label: hhmm,
          ),
        ],
      ),
    );

    final feedTile = _Stat(
      label: l.hoLastFeed,
      value: feed == null ? l.hoNoneYet : ago(feed.occurredAt),
      detail: feed == null
          ? null
          : [
              hhmm(feed.occurredAt),
              if (feed.type == CareType.breast)
                careTypeLabel(l, feed.type)
              else if (feed.amountMl case final ml?)
                l.hoBottleMl(l.amountMl(ml)),
            ].join(' · '),
    );
    final diaperTile = _Stat(
      label: l.hoLastDiaper,
      value: diaper == null ? l.hoNoneYet : ago(diaper.occurredAt),
      detail: diaper == null
          ? null
          : [
              hhmm(diaper.occurredAt),
              if (diaper.diaper case final kind?) diaperChoice(l, kind),
              l.hoDiapersToday(diapersToday),
            ].join(' · '),
    );

    final nextRows = <Widget>[
      if (nextFeed != null && feed != null)
        _NextFeed(
          at: hhmm(nextFeed),
          progress:
              (now.difference(feed.occurredAt).inMinutes /
                      math.max(
                        1,
                        nextFeed.difference(feed.occurredAt).inMinutes,
                      ))
                  .clamp(0.0, 1.0),
          note: nextFeed.isAfter(now)
              ? l.hoNextFeedLeft(span(nextFeed.difference(now)))
              : l.hoFeedDue,
          due: !nextFeed.isAfter(now),
        ),
      for (final r in reminders.take(4))
        _Row(
          icon: ClIcons.bell,
          title: r.title,
          trailing: r.allDay ? l.hoAllDay : hhmm(r.dueAt),
        ),
      // Overdue reads as such, on the warm fill; never as something "next".
      if (vaccineSoon)
        _Row(
          icon: ClIcons.calendar,
          title: vaccine.date.isBefore(todayStart)
              ? l.hoVaccineOverdue(vaccine.items.length)
              : l.hoVaccineNext(vaccine.items.length),
          trailing: vxDay(vaccine.date),
          warm: vaccine.date.isBefore(todayStart),
          onTap: () => context.push(Routes.vaccines),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        const SizedBox(height: ClSpace.s2),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: feedTile),
              const SizedBox(width: ClSpace.s2),
              Expanded(child: diaperTile),
            ],
          ),
        ),
        _Label(l.hoUpcoming),
        if (nextRows.isEmpty)
          Text(
            l.hoNothingUpcoming,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          )
        else
          _Group(rows: nextRows),
        if (helpful.isNotEmpty && content != null) ...[
          _Label(l.hoHelps),
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final id in helpful.take(3))
                if (content.activity(id) case final a?)
                  ClPressable(
                    onPressed: () =>
                        context.push('${Routes.rhythmActivity}/$id'),
                    semanticLabel: a.title.of(locale),
                    child: _Pill(
                      label: a.title.of(locale),
                      icon: ClIcons.heart,
                      fill: cl.colors.mintSoft,
                      ink: cl.colors.mintText,
                      large: true,
                    ),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Health signs of today and yesterday (or one quiet line), then "Gọi 115" and "Sơ cứu" as two
/// always-there buttons: the screen puts this right above its action (P-180 v2).
class HandoverSafety extends ConsumerWidget {
  const HandoverSafety({required this.me, super.key});
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
    final local = inBabyZone(zone, now);
    final yesterday = isoOf(DateTime(local.year, local.month, local.day - 1));
    final health = [
      for (final c in ref.watch(checkInsProvider(me.babyId)).value ?? const [])
        if (c.date.compareTo(yesterday) >= 0 &&
            (c.needsHealthSupport || c.healthSigns.isNotEmpty))
          c,
    ];
    final emergency = ref.watch(contentEmergencyNumberProvider);
    Widget button(ClIcons icon, String label, VoidCallback onTap) => Expanded(
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cl.colors.controlBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClIcon(icon, size: 16, color: cl.colors.ink),
              const SizedBox(width: ClSpace.s1),
              Text(label, style: cl.text.bodyStrong),
            ],
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s4),
        if (health.isEmpty)
          Row(
            children: [
              ClIcon(ClIcons.check, size: 16, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s1),
              Expanded(
                child: Text(
                  l.hoNoHealth,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          )
        else
          _Group(
            rows: [
              for (final c in health.take(2))
                _Row(
                  icon: ClIcons.alert,
                  title: l.hoHealthNoted(shortDay(locale, c.date)),
                  warm: true,
                  onTap: () => context.push(Routes.rhythmHealth),
                ),
            ],
          ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            button(
              ClIcons.phone,
              l.hoCall(emergency),
              () => ref.read(rhythmDialerProvider)(emergency),
            ),
            const SizedBox(width: ClSpace.s2),
            button(
              ClIcons.shield,
              l.hoFirstAid,
              () => context.push(Routes.firstAid),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
    );
  }
}

/// The last 24 h as one strip: sleep blocks, feed ticks, diaper dots; four clock labels.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.now,
    required this.sleeps,
    required this.feeds,
    required this.diapers,
    required this.label,
  });
  final DateTime now;
  final List<(DateTime, DateTime)> sleeps;
  final List<DateTime> feeds;
  final List<DateTime> diapers;
  final String Function(DateTime) label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    final start = now.subtract(const Duration(hours: 24));
    double at(DateTime t) =>
        (t.difference(start).inMinutes / (24 * 60)).clamp(0.0, 1.0);
    final legend = cl.text.caption.copyWith(color: cl.colors.inkMuted);
    final sleepColor = cl.care.sleep.accent.withValues(alpha: 0.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.hoStripA11y,
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                return SizedBox(
                  height: 28,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cl.colors.surface2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      for (final (s, e) in sleeps)
                        if (e.isAfter(start))
                          Positioned(
                            left: w * at(s),
                            width: math.max(2, w * (at(e) - at(s))),
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: sleepColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      for (final f in feeds)
                        if (f.isAfter(start))
                          Positioned(
                            left: math.min(w - 3, w * at(f)),
                            width: 3,
                            top: 3,
                            bottom: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: cl.care.bottle.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      for (final d in diapers)
                        if (d.isAfter(start))
                          Positioned(
                            left: math.min(w - 6, w * at(d)),
                            bottom: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: cl.care.diaper.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.hoYesterdayAt(label(start)), style: legend),
            Text(label(start.add(const Duration(hours: 8))), style: legend),
            Text(label(start.add(const Duration(hours: 16))), style: legend),
            Text(l.hoNowLabel, style: legend),
          ],
        ),
        const SizedBox(height: ClSpace.s1),
        Wrap(
          spacing: ClSpace.s3,
          children: [
            _Legend(color: sleepColor, label: l.hoSleep),
            _Legend(color: cl.care.bottle.accent, label: l.hoFeed, thin: true),
            _Legend(
              color: cl.care.diaper.accent,
              label: l.hoDiaper,
              round: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.thin = false,
    this.round = false,
  });
  final Color color;
  final String label;
  final bool thin;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: thin ? 3 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
      ],
    );
  }
}

class _NextFeed extends StatelessWidget {
  const _NextFeed({
    required this.at,
    required this.progress,
    required this.note,
    required this.due,
  });
  final String at;
  final double progress;
  final String note;
  final bool due;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.feed, size: 18, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s3),
              Expanded(child: Text(l.hoNextFeedTitle, style: cl.text.body)),
              Text(
                l.hoAround(at),
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cl.colors.surface2,
              color: due ? cl.colors.sunshine : cl.care.bottle.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: cl.text.caption.copyWith(
              color: due ? cl.colors.ink : cl.colors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    this.warm = false,
    this.onTap,
  });
  final ClIcons icon;
  final String title;
  final String? trailing;
  final bool warm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          ClIcon(
            icon,
            size: 18,
            color: warm ? cl.colors.ink : cl.colors.inkMuted,
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(child: Text(title, style: cl.text.body)),
          if (trailing != null)
            Text(
              trailing!,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          if (onTap != null) ...[
            const SizedBox(width: ClSpace.s1),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ],
      ),
    );
    // Ink on the soft warm fill, also in Night care.
    final body = warm
        ? ColoredBox(color: cl.colors.sunshineSoft, child: row)
        : row;
    return onTap == null
        ? body
        : ClPressable(onPressed: onTap, semanticLabel: title, child: body);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return _Card(
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
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding ?? const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        border: Border.all(color: cl.colors.separator),
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.detail});
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: [label, value, ?detail].join(', '),
      child: ExcludeSemantics(
        child: _Card(
          padding: const EdgeInsets.all(ClSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ClTabularText(value, style: cl.text.headline),
              ),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fill,
    required this.ink,
    this.icon,
    this.large = false,
  });
  final String label;
  final Color fill;
  final Color ink;
  final ClIcons? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? ClSpace.s3 : ClSpace.s2,
        vertical: large ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: (large ? cl.text.label : cl.text.caption).copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small muted section label (the hero carries the weight, not the headings).
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: cl.text.label.copyWith(
            color: cl.colors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
