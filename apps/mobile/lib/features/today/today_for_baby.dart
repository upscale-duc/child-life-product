import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../library/library_today.dart' show lbForBabyCardsProvider;
import '../milestones/milestone_today.dart' show mtForBabyCardsProvider;
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_calc.dart';
import '../rhythm/rhythm_home.dart' show ForYouSection;
import '../rhythm/rhythm_labels.dart';
import '../rhythm/rhythm_models.dart';
import '../rhythm/rhythm_repository.dart';
import '../rhythm/rhythm_widgets.dart';

/// Hôm nay · "Dành cho bé hôm nay" (D-076 #4, Figma 559:57583, adapted to the v2.0 rules):
///
/// 1. heading and "≈ Theo điều bạn quan tâm · Đổi" (Đổi opens EN01, the person's interests);
/// 2. Nhịp lớn lên's own cards ([ForYouSection]: health first, the current suggestion from
///    `recommend()` / `composeHome`, check-in, handover, the age card, the week summary,
///    "Hỗ trợ phù hợp"), with the reference calendar drawn as the large lavender card
///    "Nhịp lớn lên · Beta" ([ForBabyRhythmCard]) at its place — never first, and hidden on a
///    health day, as the brief requires;
/// 3. a carousel of small cards from other modules ([ForBabyCard]), through the providers
///    below, ranked by the person's interests.
///
/// The section shows only with the family's `rhythm` rollout (ForYouSection checks it); roles
/// are those of each card (`familyCan`).
class TodayForBabySection extends ConsumerWidget {
  const TodayForBabySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    // Nothing is read (preferences, other modules' cards) without the rollout.
    if (me == null ||
        !(ref.watch(selectedCapabilitiesProvider)?.features.rhythm ?? false)) {
      return const SizedBox.shrink();
    }
    final language = Localizations.localeOf(context).languageCode;
    final cards = ref.watch(
      forBabyCardsProvider((
        babyId: me.babyId,
        uid: me.uid,
        languageCode: language,
      )),
    );
    final interests =
        ref.watch(userPreferencesProvider(me.uid)).value?.interests ??
        const <Interest>[];
    return Padding(
      // With ForYouSection's own 16: the 24 between Hôm nay's sections.
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: ForYouSection(
        header: ForBabyHeader(hasInterests: interests.isNotEmpty),
        calendar: (compact) => ForBabyRhythmCard(compact: compact),
        more: [if (cards.isNotEmpty) ForBabyCarousel(cards: cards)],
      ),
    );
  }
}

/// "Dành cho bé hôm nay" and the line under it: "Theo điều bạn quan tâm · Đổi", or "Chưa chọn
/// … · Chọn" before the person picked anything.
class ForBabyHeader extends StatelessWidget {
  const ForBabyHeader({required this.hasInterests, super.key});
  final bool hasInterests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final link = hasInterests ? l10n.hnForBabyChange : l10n.hnForBabyPick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(title: l10n.rhSectionForYou),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
          child: Row(
            children: [
              ClIcon(ClIcons.sliders, size: 14, color: cl.colors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasInterests
                      ? l10n.hnForBabyBecause
                      : l10n.hnForBabyNoInterests,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              ClPressable(
                key: const Key('forBabyChange'),
                onPressed: () => context.push(Routes.rhythmInterests),
                semanticLabel: '$link · ${l10n.rhInterestsRow}',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ClSpace.tapMin,
                    minWidth: ClSpace.tapMin,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text(
                      link,
                      style: cl.text.label.copyWith(
                        color: cl.colors.mintText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 559:57583 "Nhịp lớn lên · Beta": the reference stage now or next ("Sắp đến giai đoạn 1
/// (Wonder Weeks)"), its expected window and, for who reads care, how many of the last three
/// days someone noted "cần được dỗ nhiều hơn". [compact] (a suggestion is shown above it)
/// leaves out the body. Opens Nhịp lớn lên.
class ForBabyRhythmCard extends ConsumerWidget {
  const ForBabyRhythmCard({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = isoOf(babyToday(zone, now));
    final due = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value?.dueDate?.date
        : null;
    final reference = ref.watch(rhythmReferenceProvider).value;
    if (due == null || reference == null) return const SizedBox.shrink();
    final stages = currentStages(due, today, reference.stages);
    final focus = stages.current.firstOrNull ?? stages.next;
    if (focus == null) return const SizedBox.shrink();
    final title = stages.current.isNotEmpty
        ? l10n.rhStageInN(focus.number)
        : l10n.rhStageComingN(focus.number);
    final soothing = familyCan(me, FamilyAction.historyRead)
        ? soothingDays(
            ref.watch(checkInsProvider(me.babyId)).value ?? const [],
            today,
          )
        : 0;
    final body = [
      l10n.hnRhythmExpected(dayRange(l10n, locale, windowOf(due, focus))),
      if (soothing > 0) l10n.hnRhythmSoothing(soothing),
    ].join(' ');
    final sleep = cl.care.sleep;
    final see = l10n.rhSeeRhythm(baby?.nickname ?? '');
    return RhCard(
      key: const Key('forBabyRhythm'),
      color: sleep.soft,
      onTap: () => context.push(Routes.rhythm),
      semanticLabel: [
        l10n.hnRhythmPill,
        title,
        if (!compact) body,
        see,
      ].join('. '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  l10n.hnRhythmPill,
                  style: cl.text.caption.copyWith(
                    color: sleep.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              ClIcon(ClIcons.chevronRight, size: 18, color: sleep.ink),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            title,
            style: (compact ? cl.text.bodyStrong : cl.text.headline).copyWith(
              color: sleep.ink,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: ClSpace.s1),
            Text(body, style: cl.text.body.copyWith(color: cl.colors.ink)),
          ],
          const SizedBox(height: ClSpace.s2),
          Row(
            children: [
              Flexible(
                child: Text(
                  see,
                  style: cl.text.label.copyWith(
                    color: sleep.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ClIcon(ClIcons.arrowRight, size: 14, color: sleep.ink),
            ],
          ),
        ],
      ),
    );
  }
}

/// Days among the last three (today included) on which someone noted "cần được dỗ nhiều hơn".
int soothingDays(List<CheckIn> checkIns, String today) {
  final from = addDaysIso(today, -2);
  return {
    for (final c in checkIns)
      if (c.observation == Observation.soothing &&
          c.date.compareTo(from) >= 0 &&
          c.date.compareTo(today) <= 0)
        c.date,
  }.length;
}

// ---------------------------------------------------------------------------------------------
// Small cards from other modules (the 559:57583 carousel). HOOK for Mốc phát triển and Thư viện
// chăm bé: fill the provider of your module (replace its body with a watch of your own
// provider) and the carousel shows your cards; nothing else here needs to change.
// ---------------------------------------------------------------------------------------------

/// The tinted icon tile of a small card (soft fills take `ink`, also in Night care).
enum ForBabyTone { growth, mint, sleep, peach, sunshine }

/// One small card: "Mốc có thể thấy · tuần 3–6" / "Bé ngẩng đầu khi nằm sấp" / "Ghi nhận khi bé
/// làm được →". Strings come localised; no child data beyond what the family sees anyway.
@immutable
class ForBabyCard {
  const ForBabyCard({
    required this.id,
    required this.kicker,
    required this.title,
    required this.action,
    required this.onOpen,
    this.icon = ClIcons.star,
    this.tone = ForBabyTone.mint,
    this.interest,
    this.onDismiss,
  });

  /// Stable and unique across modules, e.g. `milestone:ms_head_up`, `article:art_startle`.
  final String id;

  /// The small line by the icon ("Mốc có thể thấy · tuần 3–6", "Đọc 2 phút").
  final String kicker;
  final String title;

  /// The call to action at the bottom ("Ghi nhận khi bé làm được", "Đọc bài").
  final String action;
  final ClIcons icon;
  final ForBabyTone tone;

  /// What the card is about; cards on the person's interests come first, and cards on a topic
  /// they turned down ("Ít gợi ý kiểu này hơn", EN05) are left out.
  final Interest? interest;

  /// Opens the card (push a route of your module).
  final void Function(BuildContext context) onOpen;

  /// The × (EN05 "Bé đã làm được / Nhắc lại sau 3 ngày / Ẩn thẻ này / Ít gợi ý kiểu này hơn");
  /// no × when null. The module keeps its own done / snoozed / hidden state and stops
  /// returning the card.
  final void Function(BuildContext context)? onDismiss;
}

/// Who and what the cards are for. Sources check the viewer's role themselves (`familyCan`).
typedef ForBabyQuery = ({String babyId, String uid, String languageCode});

/// Mốc phát triển: "Mốc có thể thấy" cards for the baby (`milestones/milestone_today.dart`,
/// D-076 #6).
final milestoneForBabyCardsProvider =
    Provider.family<List<ForBabyCard>, ForBabyQuery>(
      (ref, q) => ref.watch(mtForBabyCardsProvider(q)),
    );

/// Thư viện chăm bé and Giai đoạn của bé: the current stage (or "Thêm ngày sinh") and short
/// reads for the baby's age (`library/library_today.dart`, D-076 #5 / #7).
final articleForBabyCardsProvider =
    Provider.family<List<ForBabyCard>, ForBabyQuery>(
      (ref, q) => ref.watch(lbForBabyCardsProvider(q)),
    );

/// At most this many small cards (559:57583 draws three page dots).
const forBabyCardLimit = 3;

/// The carousel: every source, ranked by [rankForBabyCards].
final forBabyCardsProvider = Provider.family<List<ForBabyCard>, ForBabyQuery>((
  ref,
  q,
) {
  final prefs =
      ref.watch(userPreferencesProvider(q.uid)).value ??
      UserPreferences.defaults;
  return rankForBabyCards([
    ...ref.watch(milestoneForBabyCardsProvider(q)),
    ...ref.watch(articleForBabyCardsProvider(q)),
  ], prefs);
});

/// Cards on the person's interests first (each source's order kept), turned-down topics left
/// out, duplicates dropped, at most [limit].
List<ForBabyCard> rankForBabyCards(
  List<ForBabyCard> cards,
  UserPreferences prefs, {
  int limit = forBabyCardLimit,
}) {
  final seen = <String>{};
  final kept = [
    for (final c in cards)
      if (!(c.interest != null && prefs.fewer.contains(c.interest)) &&
          seen.add(c.id))
        c,
  ];
  bool liked(ForBabyCard c) =>
      c.interest != null && prefs.interests.contains(c.interest);
  return [
    ...kept.where(liked),
    ...kept.where((c) => !liked(c)),
  ].take(limit).toList();
}

/// The small cards side by side (one fills the width), with page dots.
class ForBabyCarousel extends StatefulWidget {
  const ForBabyCarousel({required this.cards, super.key});
  final List<ForBabyCard> cards;

  @override
  State<ForBabyCarousel> createState() => _ForBabyCarouselState();
}

class _ForBabyCarouselState extends State<ForBabyCarousel> {
  final _scroll = ScrollController();
  int _page = 0;
  double _step = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      final page = p.pixels >= p.maxScrollExtent - 1
          ? widget.cards.length - 1
          : (p.pixels / _step).round();
      if (page != _page) setState(() => _page = page);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final cards = widget.cards;
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final width = cards.length == 1 ? full : math.min(280.0, full * 0.8);
        _step = width + ClSpace.s3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              key: const Key('forBabyCarousel'),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cards.indexed) ...[
                      if (i > 0) const SizedBox(width: ClSpace.s3),
                      SizedBox(
                        width: width,
                        child: _SmallCard(card: c),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (cards.length > 1) ...[
              const SizedBox(height: ClSpace.s3),
              Semantics(
                label: l10n.hnCardPage(_page + 1, cards.length),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: i == _page ? 14 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? cl.colors.mintDeep
                                : cl.colors.controlBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({required this.card});
  final ForBabyCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tint = switch (card.tone) {
      ForBabyTone.growth => cl.care.growth.soft,
      ForBabyTone.mint => cl.colors.mintSoft,
      ForBabyTone.sleep => cl.care.sleep.soft,
      ForBabyTone.peach => cl.colors.peachSoft,
      ForBabyTone.sunshine => cl.colors.sunshineSoft,
    };
    final dismiss = card.onDismiss;
    return ClPressable(
      onPressed: () => card.onOpen(context),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '${card.kicker}. ${card.title}. ${card.action}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s3,
          ClSpace.s3,
          ClSpace.s3,
          ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(card.icon, size: 14, color: cl.colors.ink),
                ),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Text(
                    card.kicker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ),
                if (dismiss != null)
                  ClPressable(
                    onPressed: () => dismiss(context),
                    semanticLabel: l10n.hnCardOptions,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: ClIcon(
                          ClIcons.close,
                          size: 14,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: cl.text.bodyStrong,
            ),
            const Spacer(),
            const SizedBox(height: ClSpace.s2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    card.action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.label.copyWith(
                      color: cl.colors.mintText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ClIcon(ClIcons.arrowRight, size: 14, color: cl.colors.mintText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
