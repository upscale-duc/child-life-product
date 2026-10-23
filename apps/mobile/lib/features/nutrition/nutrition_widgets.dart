import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_repository.dart';
import '../library/library_widgets.dart' show lbReviewLabel;
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_state.dart';

/// Shared pieces of Dinh dưỡng (D-083, Figma 9b–9g): the page chrome with the baby chip, cards,
/// banners, the milk band, nutrient rows, suggestion cards and the footnote.

/// Sentences in one line, each closed with a full stop when it has none.
String nuSentences(Iterable<String> parts) => [
  for (final p in parts)
    if (p.trim().isNotEmpty)
      RegExp(r'[.!?…]$').hasMatch(p.trim()) ? p.trim() : '${p.trim()}.',
].join(' ');

// ---------- Chrome ----------

/// A pushed page: back · baby chip (like Tiêm chủng and the other care pages), then content.
class NuPage extends ConsumerWidget {
  const NuPage({required this.children, this.bottom, super.key});

  final List<Widget> children;

  /// A fixed bar under the scrolling content (9e actions).
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final b = ref.watch(nuBabyProvider);
    final baby = b == null ? null : ref.watch(babyProvider(b.babyId)).value;
    final media = MediaQuery.of(context);
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
              child: ClTopBar(
                onBack: () => context.pop(),
                trailing: baby == null
                    ? null
                    : ClBabySwitcher(
                        label: baby.nickname,
                        avatar: SavedBabyAvatar(baby: baby, size: 32),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  (bottom == null ? media.padding.bottom : 0) + ClSpace.s8,
                ),
                children: children,
              ),
            ),
            if (bottom != null)
              Container(
                color: cl.colors.cloud,
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s3,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Large page title (Bold 28; 26 on 9e).
class NuTitle extends StatelessWidget {
  const NuTitle(this.text, {this.size = 28, super.key});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: context.cl.text.largeTitle.copyWith(fontSize: size, height: 1.2),
    ),
  );
}

/// Section header (Bold 17), 22 above.
class NuSection extends StatelessWidget {
  const NuSection(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: ClSpace.s3),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: context.cl.text.headline.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// White card (radius 20, the card shadow unless [flat]).
class NuCard extends StatelessWidget {
  const NuCard({
    required this.child,
    this.color,
    this.flat = false,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final Color? color;
  final bool flat;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: color == null && !flat ? cl.shadows.card : null,
      ),
      child: child,
    );
  }
}

/// The white list group (radius 16) with hairlines between rows.
class NuGroup extends StatelessWidget {
  const NuGroup({required this.children, this.inset = 60, super.key});
  final List<Widget> children;

  /// Where the hairline starts: after the 34 pt chip of icon rows, 0 for full-width rows.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      decoration: BoxDecoration(
        color: cl.colors.surface,
        boxShadow: cl.shadows.card,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(left: inset),
                child: Container(height: 1, color: cl.colors.separator),
              ),
            c,
          ],
        ],
      ),
    );
  }
}

/// A rounded icon chip (34 in rows, 56 on the 9d head).
class NuIconChip extends StatelessWidget {
  const NuIconChip({
    required this.icon,
    required this.fill,
    required this.ink,
    this.size = 34,
    this.radius = 12,
    super.key,
  });
  final ClIcons icon;
  final Color fill;
  final Color ink;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
    ),
    alignment: Alignment.center,
    child: ClIcon(icon, size: size * 0.5, color: ink),
  );
}

/// A small pill tag ("Trong khoảng chuẩn", "Hiện tại", "1–2/12").
class NuTag extends StatelessWidget {
  const NuTag(this.label, {required this.fill, required this.ink, super.key});
  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(ClRadius.pill),
    ),
    child: Text(
      label,
      style: context.cl.text.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
}

/// The calm banner: sunshine-soft for "look at this" (9b growth, 9d medical note, 9e), surface-2
/// for a neutral note (9c). Ink on the warm fill, also in Night care. Never red (P-163 #5).
class NuBanner extends StatelessWidget {
  const NuBanner({
    required this.text,
    this.warm = true,
    this.action,
    this.onTap,
    super.key,
  });
  final String text;
  final bool warm;

  /// "Xem gợi ý".
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = warm ? cl.colors.ink : cl.colors.inkMuted;
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warm ? cl.colors.sunshineSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClIcon(ClIcons.alert, size: 16, color: ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: cl.text.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: cl.colors.ink,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action!,
                        style: cl.text.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cl.colors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ClIcon(
                        ClIcons.chevronRight,
                        size: 14,
                        color: cl.colors.ink,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return Semantics(container: true, child: body);
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [text, ?action].join('. '),
      child: body,
    );
  }
}

/// A card header: icon chip · title + subline · chevron (9b milk and growth cards).
class NuCardHeader extends StatelessWidget {
  const NuCardHeader({
    required this.icon,
    required this.fill,
    required this.ink,
    required this.title,
    this.subtitle,
    this.chevron = true,
    super.key,
  });
  final ClIcons icon;
  final Color fill;
  final Color ink;
  final String title;
  final String? subtitle;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        NuIconChip(icon: icon, fill: fill, ink: ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: cl.text.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cl.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (chevron) ...[
          const SizedBox(width: 8),
          ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
        ],
      ],
    );
  }
}

// ---------- Milk band (9b) ----------

/// The reference band on a 0–max track (bottle-soft with a bottle-accent edge), the 7-day average
/// as a marker above it (clamped to the track), and the band's ends below. Without an average the
/// band shows alone (P-163 #4).
class NuMilkBand extends StatelessWidget {
  const NuMilkBand({required this.band, this.average, super.key});
  final NuRange band;
  final int? average;

  /// The track runs a little past the band's top (600–900 → 0–1100) or the average.
  static int trackMax(NuRange band, int? average) {
    final top = [
      band.max * 1.22,
      (average ?? 0) * 1.1,
    ].reduce((a, b) => a > b ? a : b);
    final rounded = ((top / 100).ceil() * 100);
    return rounded < 100 ? 100 : rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bottle = cl.care.bottle;
    final max = trackMax(band, average);
    final label = cl.text.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: cl.colors.inkMuted,
    );
    final semantics = [
      l10n.nuMilkBandLabel(nuRangeText(locale, band)),
      if (average != null) l10n.nuMilkMarkerLabel(nuMl(locale, average!)),
    ].join('. ');
    return Semantics(
      label: semantics,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 46,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              double x(num ml) => (w * ml / max).clamp(0.0, w);
              final left = x(band.min);
              final right = x(band.max);
              final marker = average == null ? null : x(average!);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 18,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: cl.colors.surface2,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  // Band.
                  Positioned(
                    left: left,
                    width: (right - left).clamp(4.0, w),
                    top: 18,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: bottle.soft,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: bottle.accent),
                      ),
                    ),
                  ),
                  if (marker != null) ...[
                    Positioned(
                      left: (marker - 30).clamp(0.0, w - 60),
                      width: 60,
                      top: 0,
                      child: Text(
                        '${nuMl(locale, average!)} ml',
                        textAlign: TextAlign.center,
                        style: label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: bottle.ink,
                        ),
                      ),
                    ),
                    Positioned(
                      left: (marker - 8).clamp(0.0, w - 16),
                      top: 15,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: bottle.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cl.colors.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    left: (left - 20).clamp(0.0, w - 40),
                    width: 40,
                    top: 32,
                    child: Text(
                      nuMl(locale, band.min),
                      textAlign: TextAlign.center,
                      style: label,
                    ),
                  ),
                  Positioned(
                    left: (right - 30).clamp(0.0, w - 60),
                    width: 60,
                    top: 32,
                    child: Text(
                      '${nuMl(locale, band.max)} ml',
                      textAlign: TextAlign.center,
                      style: label,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Rows and cards ----------

/// "Cần chú ý ở giai đoạn này" row: chip · name + subline · optional tag · chevron.
class NuNutrientRow extends StatelessWidget {
  const NuNutrientRow({
    required this.nutrient,
    required this.name,
    required this.onTap,
    this.tag,
    super.key,
  });
  final NuNutrient nutrient;

  /// The baby's nickname (`{name}` in the copy).
  final String name;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final look = nuNutrientLook(context, nutrient.key);
    final title = nuText(nutrient.name, locale, name);
    final sub = nuText(nutrient.subtitle, locale, name);
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [title, if (sub.isNotEmpty) sub, ?tag].join('. '),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            NuIconChip(icon: look.icon, fill: look.soft, ink: look.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
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
            if (tag != null) ...[
              const SizedBox(width: 8),
              NuTag(tag!, fill: cl.colors.sunshineSoft, ink: cl.colors.ink),
            ],
            const SizedBox(width: 8),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// "Một ngày tham khảo": slot and text, icon by kind, no chevrons.
class NuSampleDay extends StatelessWidget {
  const NuSampleDay({required this.rows, required this.name, super.key});
  final List<NuSampleRow> rows;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return NuCard(
      flat: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (final r in rows)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    NuIconChip(
                      icon: nuSampleIcon(r.kind),
                      fill: cl.colors.surface2,
                      ink: cl.colors.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nuSlotLabel(l10n, r.slot),
                            style: cl.text.bodyStrong.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            nuText(r.text, locale, name),
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A mint suggestion card ("Gợi ý cho {bé}", the 9d tip).
class NuTipCard extends StatelessWidget {
  const NuTipCard({required this.title, this.body, super.key});
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cl.colors.mintText,
              ),
            ),
            if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body!,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: cl.colors.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The page footer: the reviewer line once an expert signed the item, else the D-082 guidance
/// footnote; then "Không thay thế tư vấn của bác sĩ…" ([doctor]; after the footnote, which already
/// says so, only the line about oral doses) and the sources.
class NuFootnote extends StatelessWidget {
  const NuFootnote({
    required this.item,
    this.doctor = true,
    this.extra,
    super.key,
  });

  /// The content shown (null: only the doctor line).
  final NuPublished? item;
  final bool doctor;

  /// A line of the page's own before the rest (9e "Gợi ý chung theo quy tắc chuyên gia…").
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final i = item;
    final style = cl.text.caption.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: cl.colors.inkMuted,
    );
    final review = i?.review;
    final signed = review != null && !(i?.illustrative ?? true);
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key: const Key('nuFootnote'),
            nuSentences([
              ?extra,
              if (i != null)
                signed
                    ? lbReviewLabel(l10n, review)
                    // D-082: a footnote, never a badge, until an expert signs it.
                    : l10n.lbIllustrative,
              if (doctor)
                i != null && !signed ? l10n.nuFooterDose : l10n.nuFooter,
            ]),
            style: style,
          ),
          if (i != null && i.sources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.lbSources}: ${i.sources.map((s) => s.label).join(' · ')}',
              style: style.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// 9b without a date of birth (P-163 #9): one card. A Cùng nuôi opens the profile; anyone else,
/// who may not see the date of birth, is told why no stage is shown.
class NuNoDobCard extends StatelessWidget {
  const NuNoDobCard({required this.baby, super.key});
  final NuBaby baby;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final parent = baby.coParent;
    return NuCard(
      key: const Key('nuNoDob'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ink on soft warm fills, also in Night care.
              NuIconChip(
                icon: ClIcons.cake,
                fill: cl.colors.sunshineSoft,
                ink: cl.colors.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent ? l10n.lbNoDobTitle : l10n.nuNoDobViewerTitle,
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parent
                          ? l10n.nuNoDobBody(baby.name)
                          : l10n.nuNoDobViewer(baby.name),
                      style: cl.text.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (parent) ...[
            const SizedBox(height: 12),
            ClButton(
              key: const Key('nuAddDob'),
              label: l10n.lbNoDobAction,
              style: ClButtonStyle.tinted,
              expand: true,
              onPressed: () =>
                  context.push('${Routes.babyEdit}/${baby.babyId}'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Calm empty state (nothing published for this age, or an item withdrawn).
class NuEmpty extends StatelessWidget {
  const NuEmpty({required this.title, required this.body, super.key});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      key: const Key('nuEmpty'),
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s8, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cl.care.bottle.soft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(ClIcons.feed, color: cl.care.bottle.ink),
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
