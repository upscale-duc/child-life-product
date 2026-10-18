import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../ai/handover_screen.dart' show HandoverEntry;
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../library/library_today.dart'
    show lbForBabyCardsProvider, lbWeekTeaserProvider;
import '../milestones/milestone_today.dart' show mtForBabyCardsProvider;
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_calc.dart';
import '../rhythm/rhythm_home.dart' show ForYouSection;
import '../rhythm/rhythm_models.dart';
import '../rhythm/rhythm_repository.dart';

export '../rhythm/rhythm_home.dart' show soothingDays;

/// Hôm nay · "Dành cho bé hôm nay" (D-076 #4, Figma 559:57583 as a reference; the order is the
/// owner's of 2026-10-15, see [ForYouSection]):
///
/// 1. heading and "≈ Theo điều bạn quan tâm · Đổi" (Đổi opens EN01, the person's interests);
/// 2. Nhịp lớn lên's suggestion (compact), then "Để ý tuần này": small cards from other modules
///    ([ForBabyCard]) through the providers below, ranked by the person's interests; then
///    "Hôm nay con có gì khác?";
/// 3. "Tuần này của {bé}": one card whose teaser is the current stage's first "Bé đang thế nào"
///    point ([lbWeekTeaserProvider]; the carousel then leaves that stage out) or the Nhịp lớn lên
///    age card, with the reference calendar and the week summary as rows.
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
    final query = (babyId: me.babyId, uid: me.uid, languageCode: language);
    final teaser = ref.watch(lbWeekTeaserProvider(query));
    final cards = [
      for (final c in ref.watch(forBabyCardsProvider(query)))
        if (c.id != teaser?.id) c,
    ];
    final interests =
        ref.watch(userPreferencesProvider(me.uid)).value?.interests ??
        const <Interest>[];
    return Padding(
      // With ForYouSection's own 16: the 24 between Hôm nay's sections.
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: ForYouSection(
        header: ForBabyHeader(hasInterests: interests.isNotEmpty),
        weekTeaser: teaser,
        more: [if (cards.isNotEmpty) ForBabyCarousel(cards: cards)],
      ),
    );
  }
}

/// "Bàn giao cho người chăm tiếp" (SU01) on Hôm nay, with the care tools under the tiles (owner,
/// 2026-10-15) rather than among the suggestions. As before: only with the `rhythm` rollout and
/// not on a day a health sign was noted; [HandoverEntry] checks `ai_assist` and the role.
class TodayHandoverRow extends ConsumerWidget {
  const TodayHandoverRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    final caps = ref.watch(selectedCapabilitiesProvider);
    if (me == null || caps == null || !caps.features.rhythm) {
      return const SizedBox.shrink();
    }
    final language = Localizations.localeOf(context).languageCode;
    if (!HandoverEntry.visibleFor(ref, me, caps, language)) {
      return const SizedBox.shrink();
    }
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = isoOf(babyToday(zone, now));
    final health = familyCan(me, FamilyAction.historyRead)
        ? (ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[])
              .any((c) => c.date == today && c.needsHealthSupport)
        : false;
    if (health) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: ClSpace.s3),
      child: HandoverEntry(),
    );
  }
}

/// "Dành cho bé hôm nay" with a small interests button at its end (owner, 2026-10-18: the line
/// "Theo điều bạn quan tâm · Đổi" took a row that is rarely needed). Before the person picked
/// anything, the button carries a dot so "Chọn" is still noticed.
class ForBabyHeader extends StatelessWidget {
  const ForBabyHeader({required this.hasInterests, super.key});
  final bool hasInterests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final link = hasInterests ? l10n.hnForBabyChange : l10n.hnForBabyPick;
    final why = hasInterests
        ? l10n.hnForBabyBecause
        : l10n.hnForBabyNoInterests;
    return Padding(
      padding: const EdgeInsets.only(left: ClSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.rhSectionForYou, style: cl.text.headline),
            ),
          ),
          ClPressable(
            key: const Key('forBabyChange'),
            onPressed: () => context.push(Routes.rhythmInterests),
            semanticLabel: '$why · $link · ${l10n.rhInterestsRow}',
            child: SizedBox.square(
              dimension: ClSpace.tapMin,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cl.colors.surface2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClIcon(ClIcons.sliders, size: 18, color: cl.colors.ink),
                      if (!hasInterests)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cl.colors.mintText,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
            // "Để ý tuần này" (owner, 2026-10-15): what the cards are, in one small line.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s1,
                ClSpace.s1,
                ClSpace.s1,
                ClSpace.s2,
              ),
              child: Text(
                l10n.hnWatchThisWeek,
                style: cl.text.label.copyWith(
                  color: cl.colors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
