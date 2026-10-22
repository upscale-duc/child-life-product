import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart' show timerClockProvider;
import '../care/history_screen.dart' show weekdayShort;
import '../me/me_widgets.dart';
import 'notification_destinations.dart';
import 'notification_links.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

/// EN06 Hộp thông báo (560:2884, D-076 #2): every push the server sent this person in the last
/// 90 days, newest first, under Hôm nay · Tuần này · Trước đó; chips filter by the P-174 inbox
/// groups Kỷ niệm · Gia đình · Chăm sóc · Khác. Unread rows are white cards with a dot; a tap
/// reads the row and opens what the push opens (one resolver, P-174); "Đánh dấu đã đọc" reads
/// the loaded ones; a swipe hides one (archived). 30 rows load first, 30 more at the end; pull
/// to refresh re-subscribes. The sliders button opens EN07 (engineering addition: the design
/// has no way there from here).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxGroup? _filter;
  int _limit = inboxPageSize;

  /// The last page shown, kept on screen while a bigger one loads.
  InboxPage? _last;
  String? _lastUid;

  Future<void> _refresh(({String uid, int limit}) key) async {
    ref.invalidate(inboxProvider(key));
    try {
      await ref
          .read(inboxProvider(key).future)
          .timeout(const Duration(seconds: 10));
    } on Object {
      // The error state (or the old rows) stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return ColoredBox(color: cl.colors.cloud);
    final uid = session.user.uid;
    if (_lastUid != uid) {
      _last = null;
      _lastUid = uid;
    }
    final key = (uid: uid, limit: _limit);
    final async = ref.watch(inboxProvider(key));
    if (async.hasValue) _last = async.value;
    final page = async.hasValue ? async.value : _last;
    final all = page?.items ?? const <InboxItem>[];
    final unread = [
      for (final i in all)
        if (i.unread) i.id,
    ];
    final shown = [
      for (final i in all)
        if (_filter == null || i.inboxGroup == _filter) i,
    ];

    Widget chip(String label, InboxGroup? value) => ClFilterChip(
      key: Key('ntChip-${value?.name ?? 'all'}'),
      label: label,
      selected: _filter == value,
      onTap: () => setState(() => _filter = value),
    );

    return MePage(
      title: l10n.ntInboxTitle,
      onRefresh: () => _refresh(key),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unread.isNotEmpty)
            ClPressable(
              key: const Key('ntMarkAllRead'),
              semanticLabel: l10n.ntMarkAllRead,
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markRead(uid, unread)
                  .catchError((Object _) {}),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                child: Text(
                  l10n.ntMarkAllRead,
                  style: cl.text.label.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ClPressable(
            key: const Key('ntOpenSettings'),
            semanticLabel: l10n.ntOpenSettings,
            onPressed: () => context.push(Routes.meNotifications),
            child: SizedBox(
              width: ClSpace.tapMin,
              height: ClSpace.tapMin,
              child: Center(
                child: ClIcon(ClIcons.sliders, size: 22, color: cl.colors.ink),
              ),
            ),
          ),
        ],
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              chip(l10n.ntFilterAll, null),
              const SizedBox(width: ClSpace.s2),
              chip(l10n.ntFilterMemories, InboxGroup.memories),
              const SizedBox(width: ClSpace.s2),
              chip(l10n.ntFilterFamily, InboxGroup.family),
              const SizedBox(width: ClSpace.s2),
              chip(l10n.ntFilterCare, InboxGroup.care),
              const SizedBox(width: ClSpace.s2),
              chip(l10n.ntFilterOther, InboxGroup.other),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        if (async.hasError && page == null)
          Padding(
            key: const Key('ntError'),
            padding: const EdgeInsets.only(top: ClSpace.s6),
            child: ClEmptyState(
              icon: ClIcons.bell,
              title: l10n.ntLoadFailedTitle,
              message: l10n.ntLoadFailed,
              actionLabel: l10n.actionRetry,
              onAction: () => _refresh(key),
            ),
          )
        else if (page == null)
          const _Loading()
        else if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s6),
            child: ClEmptyState(
              icon: ClIcons.bell,
              title: l10n.ntEmptyTitle,
              message: l10n.ntEmptyBody,
            ),
          )
        else ...[
          if (shown.isEmpty)
            _Note(l10n.ntEmptyFiltered)
          else
            ..._sections(context, shown),
          if (page.more) ...[
            const SizedBox(height: ClSpace.s2),
            async.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(ClSpace.s3),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : ClButton(
                    key: const Key('ntLoadMore'),
                    label: l10n.ntLoadMore,
                    style: ClButtonStyle.tinted,
                    expand: true,
                    onPressed: () => setState(() => _limit += inboxPageSize),
                  ),
          ],
          const SizedBox(height: ClSpace.s4),
          _Note(l10n.ntKept),
        ],
      ],
    );
  }

  List<Widget> _sections(BuildContext context, List<InboxItem> items) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(timerClockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final groups = <String, List<InboxItem>>{};
    for (final i in items) {
      final at = i.createdAt.toLocal();
      final day = DateTime(at.year, at.month, at.day);
      final key = !day.isBefore(today)
          ? l10n.ntSectionToday
          : !day.isBefore(weekStart)
          ? l10n.ntSectionWeek
          : l10n.ntSectionEarlier;
      (groups[key] ??= []).add(i);
    }
    return [
      for (final MapEntry(key: title, value: rows) in groups.entries) ...[
        _SectionTitle(title),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: InboxRow(item: row, now: now),
          ),
        const SizedBox(height: ClSpace.s2),
      ],
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: cl.text.label.copyWith(
            color: cl.colors.inkMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// Content-shaped placeholders while the first page loads (Motion spec 271:393).
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      key: const Key('ntLoading'),
      label: l10n.ntLoading,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: ClSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClSkeleton(width: 32, height: 32, radius: ClRadius.control),
                    SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClSkeleton(height: 16),
                          SizedBox(height: ClSpace.s2),
                          ClSkeleton(width: 180, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Text(text, style: cl.text.label.copyWith(color: cl.colors.inkMuted));
  }
}

/// One EN06 row: tinted icon tile, title + time, the push's body; unread = white card + dot.
class InboxRow extends ConsumerWidget {
  const InboxRow({required this.item, required this.now, super.key});
  final InboxItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final language = locale == 'en' ? 'en' : 'vi';
    final (icon, tint, ink) = _look(cl, item);
    final title = item.titleIn(language);
    final body = item.bodyIn(language);
    final time = _time(locale, item.createdAt.toLocal(), now);
    final row = Container(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s3,
        ClSpace.s3,
        ClSpace.s3,
        ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: item.unread ? cl.colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(ClRadius.control),
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: 18, color: ink),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: ClSpace.s2),
                    Text(
                      time,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: ClSpace.s4,
            child: item.unread
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      key: const Key('ntUnreadDot'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cl.colors.mintDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
    final label = [
      title,
      body,
      time,
      if (item.unread) l10n.ntUnread,
    ].where((s) => s.isNotEmpty).join(', ');
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.card),
        ),
        child: Text(
          l10n.ntHide,
          style: cl.text.label.copyWith(color: cl.colors.ink),
        ),
      ),
      onDismissed: (_) {
        final session = ref.read(sessionProvider);
        if (session is SessionSignedIn) {
          ref
              .read(notificationRepositoryProvider)
              .archive(session.user.uid, item.id)
              .catchError((Object _) {});
        }
      },
      child: ClPressable(
        semanticLabel: label,
        pressedOpacity: ClPressable.surfaceOpacity,
        onPressed: () => openInboxRow(context, ref, item),
        child: row,
      ),
    );
  }
}

/// Today "20:30"; the last 7 days "T7" / "Sat"; older "8/10" / "10/8".
String _time(String locale, DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (!day.isBefore(today)) return DateFormat.Hm(locale).format(at);
  if (today.difference(day).inDays < 7) return weekdayShort(locale, at);
  return locale == 'en'
      ? DateFormat('M/d').format(at)
      : DateFormat('d/M').format(at);
}

/// EN06 icon tiles: mint = reminders, care tints by activity, sunshine = memories, peach =
/// family (text on soft warm fills is ink).
(ClIcons, Color, Color) _look(ClTheme cl, InboxItem item) {
  final c = cl.colors;
  final care = cl.care;
  return switch (item.kind) {
    'vaccine' => (ClIcons.check, c.mintSoft, c.mintText),
    'reminderRule' => switch (item.data['type']) {
      'sleep' => (ClIcons.sleep, care.sleep.soft, care.sleep.ink),
      'diaper' => (ClIcons.diaper, care.diaper.soft, care.diaper.ink),
      'pump' => (ClIcons.drop, care.pump.soft, care.pump.ink),
      _ => (ClIcons.feed, care.bottle.soft, care.bottle.ink),
    },
    'rhythm' => (ClIcons.spark, care.sleep.soft, care.sleep.ink),
    'stage' || 'milestone' => (ClIcons.star, care.growth.soft, care.growth.ink),
    'article' => (ClIcons.journal, c.mintSoft, c.mintText),
    'weeklySummary' => (ClIcons.today, c.mintSoft, c.mintText),
    'memories' ||
    'shared' ||
    'album' ||
    'story' ||
    'keepsakeVideo' ||
    'keepsakeVideoFailed' ||
    'photoSuggestion' ||
    'keepsakePrompt' => (ClIcons.memories, c.sunshineSoft, c.ink),
    'message' || 'familyActivity' => (ClIcons.family, c.peachSoft, c.ink),
    // D-092 membership events (ink on the soft warm fill, Night care too).
    'memberJoined' => (ClIcons.family, c.peachSoft, c.ink),
    'inviteDeclined' => (ClIcons.mail, c.peachSoft, c.ink),
    'roleChanged' => (ClIcons.shield, c.peachSoft, c.ink),
    'memberRemoved' => (ClIcons.lock, c.peachSoft, c.ink),
    'storage' || 'storageGranted' => (ClIcons.upload, c.surface2, c.ink),
    _ => (ClIcons.bell, c.mintSoft, c.mintText),
  };
}
