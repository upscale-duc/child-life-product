import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import 'content_models.dart';
import 'content_repository.dart';

/// Shared pieces of Thư viện chăm bé (4a–4f) and Giai đoạn của bé (2a–2c).

// ---------- The baby the content follows ----------

/// The selected baby as the content uses it. [dob] is null when this member cannot see the date
/// of birth (2c); [canAddDob]: a Cùng nuôi, who may edit the profile.
typedef LbBaby = ({
  String babyId,
  String name,
  DateTime? dob,
  DateTime today,
  MemberRole role,
  bool canAddDob,
});

final lbBabyProvider = Provider<LbBaby?>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  final dob = me.canViewBabyInfo
      ? ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
      : null;
  final now = ref.watch(minuteClockProvider).value ?? DateTime.now();
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  return (
    babyId: me.babyId,
    name: baby?.nickname ?? '',
    // BabyPrivateProfile falls back to 2000-01-01 for an unreadable date: treat it as missing.
    dob: dob == null || dob.year < 2005 ? null : dob,
    today: babyToday(zone, now),
    role: me.role,
    canAddDob: me.role == MemberRole.coParent,
  );
});

/// "Teddy · 3 tuần" (null without a date of birth).
String? lbAgeLabel(AppLocalizations l10n, LbBaby? b) =>
    b?.dob == null ? null : ageShort(l10n, b!.dob!, b.today);

// ---------- Labels ----------

String lbTopicLabel(AppLocalizations l10n, LbTopic t) => switch (t) {
  LbTopic.feeding => l10n.lbTopicFeeding,
  LbTopic.sleep => l10n.lbTopicSleep,
  LbTopic.teething => l10n.lbTopicTeething,
  LbTopic.illness => l10n.lbTopicIllness,
  LbTopic.dailyCare => l10n.lbTopicDailyCare,
  LbTopic.development => l10n.lbTopicDevelopment,
};

/// "0–3 tháng", "0–2 tuần", "1–2 tuổi" for an article's age range in weeks (`to` exclusive).
String lbWeeksLabel(AppLocalizations l10n, LbWeeks w) {
  // Weeks for the first two months, then months ("0–3 tháng" as 4b draws it).
  if (w.to <= 9) return l10n.lbRangeWeeks(w.from, w.to);
  int months(int weeks) => (weeks * 7 / 30.4375).round();
  final from = months(w.from);
  final to = months(w.to);
  if (from % 12 == 0 && to % 12 == 0 && to > 12) {
    return l10n.lbRangeYears(from ~/ 12, to ~/ 12);
  }
  return l10n.lbRangeMonths(from, to);
}

/// "0–2 tuần", "3–4 tuần", "1 tháng", "12–14 tháng" (`stageAgeLabel`: from to the last value).
String lbStageLabel(AppLocalizations l10n, LbStageAge a) {
  final week = a.unit == LbUnit.week;
  if (a.from == a.last) {
    return week ? l10n.lbStageWeek(a.from) : l10n.lbStageMonth(a.from);
  }
  return week
      ? l10n.lbRangeWeeks(a.from, a.last)
      : l10n.lbRangeMonths(a.from, a.last);
}

/// "Được BS. Hà · Nhi khoa rà soát 09/2026".
String lbReviewLabel(AppLocalizations l10n, LbReview r) => l10n.lbReviewedBy(
  r.reviewer,
  r.credential,
  DateFormat('MM/yyyy').format(r.reviewedOn),
);

// ---------- Topic look (4a tiles, chips, placeholders) ----------

/// A picture's look: the tinted fill, the icon and its ink (existing colour tokens only).
typedef LbLook = ({Color soft, Color ink, ClIcons icon});
typedef LbTopicLook = LbLook;

LbTopicLook lbTopicLook(BuildContext context, LbTopic t) {
  final cl = context.cl;
  return switch (t) {
    LbTopic.feeding => (
      soft: cl.care.bottle.soft,
      ink: cl.care.bottle.ink,
      icon: ClIcons.feed,
    ),
    LbTopic.sleep => (
      soft: cl.care.sleep.soft,
      ink: cl.care.sleep.ink,
      icon: ClIcons.sleep,
    ),
    // Ink on soft warm fills, also in Night care.
    LbTopic.teething => (
      soft: cl.colors.sunshineSoft,
      ink: cl.colors.ink,
      icon: ClIcons.star,
    ),
    LbTopic.illness => (
      soft: cl.colors.errorSoft,
      ink: cl.colors.error,
      icon: ClIcons.alert,
    ),
    LbTopic.dailyCare => (
      soft: cl.care.diaper.soft,
      ink: cl.care.diaper.ink,
      icon: ClIcons.diaper,
    ),
    LbTopic.development => (
      soft: cl.colors.mintSoft,
      ink: cl.colors.mintText,
      icon: ClIcons.spark,
    ),
  };
}

/// Thư viện ăn dặm groups (D-087, P-166 #5): each its own icon and tint, so the list no longer
/// repeats the feeding bottle. Ink on the soft warm fills, also in Night care.
LbLook lbSubtopicLook(BuildContext context, LbSubtopic s) {
  final cl = context.cl;
  final c = cl.colors;
  LbLook care(ClCareColor t, ClIcons icon) =>
      (soft: t.soft, ink: t.ink, icon: icon);
  return switch (s) {
    LbSubtopic.start => (soft: c.sunshineSoft, ink: c.ink, icon: ClIcons.spoon),
    LbSubtopic.methods => (
      soft: c.mintSoft,
      ink: c.mintText,
      icon: ClIcons.hand,
    ),
    LbSubtopic.textures => (soft: c.peachSoft, ink: c.ink, icon: ClIcons.bowl),
    LbSubtopic.nutrition => care(cl.care.diaper, ClIcons.carrot),
    LbSubtopic.allergy => (soft: c.sunshineSoft, ink: c.ink, icon: ClIcons.egg),
    LbSubtopic.safety => care(cl.care.breast, ClIcons.shield),
    LbSubtopic.menus => care(cl.care.sleep, ClIcons.calendar),
    LbSubtopic.skills => care(cl.care.bottle, ClIcons.hand),
    LbSubtopic.health => care(cl.care.growth, ClIcons.cup),
    LbSubtopic.gear => care(cl.care.pump, ClIcons.highChair),
    LbSubtopic.family => (
      soft: c.mintSoft,
      ink: c.mintText,
      icon: ClIcons.bowl,
    ),
  };
}

/// An article's picture look: its Ăn dặm group when it has one, else its topic.
LbLook lbArticleLook(BuildContext context, LbArticle a) => a.subtopic == null
    ? lbTopicLook(context, a.topic)
    : lbSubtopicLook(context, a.subtopic!);

// ---------- Chrome ----------

/// White 44 pt round button (back, "Đã lưu" lives in [LbPillButton]).
class LbRoundButton extends StatelessWidget {
  const LbRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: cl.colors.ink),
      ),
    );
  }
}

/// 4a "Đã lưu" pill: white, bookmark 16, SemiBold 14.
class LbPillButton extends StatelessWidget {
  const LbPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final fill = selected ? cl.colors.mintSoft : cl.colors.surface;
    final ink = selected ? cl.colors.mintText : cl.colors.ink;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 16, color: ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pushed content page (no dock): back, an optional trailing action, the scrolling body and an
/// optional fixed bottom bar. The 4d reader adds a [header] under the top bar (reading
/// progress), an [overlay] at the bottom right of the body ("Lên đầu") and caps the body at
/// [maxContentWidth], centred on tablets (D-087).
class LbPage extends StatelessWidget {
  const LbPage({
    required this.children,
    this.trailing,
    this.bottom,
    this.controller,
    this.header,
    this.overlay,
    this.maxContentWidth,
    super.key,
  });

  final List<Widget> children;
  final Widget? trailing;
  final Widget? bottom;
  final ScrollController? controller;
  final Widget? header;
  final Widget? overlay;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    Widget list(double side) => ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        side,
        ClSpace.s4,
        side,
        (bottom == null ? media.padding.bottom : 0) + ClSpace.s8,
      ),
      children: children,
    );
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: SizedBox(
                height: ClSpace.tapMin,
                child: Row(
                  children: [
                    LbRoundButton(
                      key: const Key('lbBack'),
                      icon: ClIcons.back,
                      label: l10n.a11yBack,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
              ),
            ),
            ?header,
            Expanded(
              child: maxContentWidth == null && overlay == null
                  ? list(ClSpace.s4)
                  : LayoutBuilder(
                      builder: (context, box) {
                        final cap = maxContentWidth;
                        final side = cap == null
                            ? ClSpace.s4
                            : math.max(ClSpace.s4, (box.maxWidth - cap) / 2);
                        return Stack(
                          children: [
                            Positioned.fill(child: list(side)),
                            if (overlay != null)
                              Positioned(
                                right: side,
                                bottom: ClSpace.s4,
                                child: overlay!,
                              ),
                          ],
                        );
                      },
                    ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Large page title (Bold 28).
class LbTitle extends StatelessWidget {
  const LbTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.cl.text.largeTitle.copyWith(fontSize: 28)),
  );
}

/// Section header (Bold 17) with an optional "Xem thêm" link.
class LbSection extends StatelessWidget {
  const LbSection(this.title, {this.link, this.onLink, super.key});
  final String title;
  final String? link;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: ClSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: cl.text.headline.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (link != null)
            ClPressable(
              onPressed: onLink,
              semanticLabel: link,
              child: Text(
                link!,
                style: cl.text.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.mintText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The white list group (radius 16, no dividers).
class LbGroup extends StatelessWidget {
  const LbGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cl.colors.surface,
      boxShadow: context.cl.shadows.card,
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// White card with the card shadow (2b "Bé đang thế nào", the 2c prompt).
class LbCard extends StatelessWidget {
  const LbCard({required this.child, this.color, super.key});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: color == null ? cl.shadows.card : null,
      ),
      child: child,
    );
  }
}

/// 2c: "Không có kết nối. … đang hiện bản đã lưu trên máy." (surface-2, cloud-off 16).
class LbOfflineBanner extends StatelessWidget {
  const LbOfflineBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('lbOffline'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: ClIcon(
                ClIcons.cloudOff,
                size: 16,
                color: cl.colors.inkMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [LbOfflineBanner] while the device is offline (care's connectivity watch).
class LbOfflineNote extends ConsumerWidget {
  const LbOfflineNote(this.message, {this.top = 0, this.bottom = 0, super.key});
  final String message;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(onlineProvider).value ?? true) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: LbOfflineBanner(message),
    );
  }
}

/// "Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ" (D-082): a small
/// footnote at the end of an article until an expert signs it (D-073 #2); never a badge up top.
class LbGuidanceNote extends StatelessWidget {
  const LbGuidanceNote({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Text(
      AppLocalizations.of(context).lbIllustrative,
      key: const Key('lbIllustrative'),
      style: cl.text.caption.copyWith(
        fontSize: 11,
        height: 1.4,
        color: cl.colors.inkMuted,
      ),
    );
  }
}

/// A small pill chip (2b / 4d: range, topic, minutes).
class LbChip extends StatelessWidget {
  const LbChip(this.label, {this.fill, this.ink, super.key});
  final String label;
  final Color? fill;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill ?? cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        label,
        style: cl.text.label.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink ?? cl.colors.ink,
        ),
      ),
    );
  }
}

/// A content picture, or a tinted placeholder with its icon (no picture, offline, tests): the
/// [look] when given (an Ăn dặm group, a recipe's main ingredient), else the [topic]'s. A cover
/// image always wins.
class LbPicture extends ConsumerWidget {
  const LbPicture({
    required this.image,
    required this.width,
    required this.height,
    required this.radius,
    this.topic,
    this.look,
    this.alt,
    super.key,
  });

  final String? image;
  final double? width;
  final double height;
  final double radius;
  final LbTopic? topic;
  final LbLook? look;
  final String? alt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final look =
        this.look ?? (topic == null ? null : lbTopicLook(context, topic!));
    final provider = image == null ? null : ref.watch(lbImageProvider)(image!);
    final placeholder = Container(
      color: look?.soft ?? cl.colors.surface2,
      alignment: Alignment.center,
      child: ClIcon(
        look?.icon ?? ClIcons.journal,
        size: height >= 100 ? 32 : 20,
        color: look?.ink ?? cl.colors.inkMuted,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: provider == null
            ? ExcludeSemantics(child: placeholder)
            : Image(
                image: provider,
                fit: BoxFit.cover,
                semanticLabel: alt,
                excludeFromSemantics: alt == null,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, sync) =>
                    frame == null && !sync ? placeholder : child,
              ),
      ),
    );
  }
}

/// Article row of the white groups (4a "Mới cập nhật", 4b, 4f, related): thumbnail, title,
/// meta and a trailing bookmark (toggles) or chevron.
class LbArticleRow extends StatelessWidget {
  const LbArticleRow({
    required this.article,
    required this.meta,
    required this.onTap,
    this.thumb = 64,
    this.saved,
    this.onBookmark,
    super.key,
  });

  final LbArticle article;
  final String meta;
  final VoidCallback onTap;
  final double thumb;

  /// Null = a chevron instead of the bookmark.
  final bool? saved;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final title = article.title.of(context);
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$title. $meta',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            LbPicture(
              key: Key('lbThumb_${article.id}'),
              image: article.cover?.id,
              width: thumb,
              height: thumb,
              radius: thumb >= 60 ? 14 : 12,
              look: lbArticleLook(context, article),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (saved == null)
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted)
            else
              ClPressable(
                key: Key('lbBookmark_${article.id}'),
                onPressed: onBookmark,
                selected: saved,
                semanticLabel: saved! ? l10n.lbUnsave : l10n.lbSave,
                child: ClIcon(
                  saved! ? ClIcons.bookmarkFill : ClIcons.bookmark,
                  size: 18,
                  color: saved! ? cl.colors.mintText : cl.colors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Giấc ngủ · 6 phút đọc".
String lbMeta(AppLocalizations l10n, LbArticle a, {bool age = false}) => [
  lbTopicLabel(l10n, a.topic),
  if (age) lbWeeksLabel(l10n, a.weeks),
  // 4b's longer line keeps "6 phút" short (as drawn).
  age
      ? l10n.lbMinutesShort(a.readingMinutes)
      : l10n.lbMinutes(a.readingMinutes),
].join(' · ');

/// Bullet rows of 2b (eye / heart icons) and Today.
class LbPoints extends StatelessWidget {
  const LbPoints({
    required this.items,
    required this.icon,
    required this.color,
    super.key,
  });
  final List<String> items;
  final ClIcons icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, t) in items.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ClIcon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t,
                  style: cl.text.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Calm empty state for a library or stage list with nothing published yet (honest: no
/// sample content in a real build).
class LbEmpty extends StatelessWidget {
  const LbEmpty({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });
  final ClIcons icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      key: const Key('lbEmpty'),
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s8, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, color: cl.colors.mintText),
          ),
          const SizedBox(height: ClSpace.s4),
          Text(title, textAlign: TextAlign.center, style: cl.text.headline),
          const SizedBox(height: ClSpace.s1),
          Text(
            body,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
