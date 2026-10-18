import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show babyToday;
import '../home/home_shell.dart';
import '../memories/memories_screen.dart' show MemoryCtx, memoryCtx;
import '../memories/memory_models.dart' show MediaKind;
import '../memories/upload_queue.dart' show PickedMedia;
import '../rhythm/rhythm_access.dart';
import 'milestone_models.dart';

/// Shared chrome and pieces of Mốc phát triển (3a–3g; shared chrome in extract 20 Part B).

/// What every Mốc screen needs: Kỷ niệm's context plus who may record (`moments.create`).
class MtCtx {
  const MtCtx(this.c);
  final MemoryCtx c;

  /// Records are a Cùng nuôi's (Rules: `moments.create`); others read the guide only.
  bool get canRecord => familyCan(c.me, FamilyAction.momentsCreate);
  DateTime get today => babyToday(c.zone, c.now);
  String get lang => c.locale.split('-').first;
  DateTime? get dob => c.dob;
  String get babyId => c.babyId;
  String get nickname => c.nickname;
}

MtCtx? mtCtx(BuildContext context, WidgetRef ref) {
  final c = memoryCtx(context, ref);
  return c == null ? null : MtCtx(c);
}

// ---------- Groups ----------

String groupLabel(AppLocalizations l10n, MilestoneGroup? g) => switch (g) {
  MilestoneGroup.motor => l10n.mtGroupMotor,
  MilestoneGroup.communication => l10n.mtGroupCommunication,
  MilestoneGroup.cognitive => l10n.mtGroupCognitive,
  MilestoneGroup.socialEmotional => l10n.mtGroupSocial,
  null => l10n.mtOwn,
};

/// 3a's pairing (extract: Giao tiếp = peach + heart, Vận động = growth + ruler, Nhận thức = sleep
/// + spark, Cảm xúc – xã hội = mint + family, Mốc riêng = sunshine + star). Icons and text on
/// these soft fills use `ink`, also in Night care.
({ClIcons icon, Color fill}) groupStyle(
  BuildContext context,
  MilestoneGroup? g,
) {
  final cl = context.cl;
  return switch (g) {
    MilestoneGroup.communication => (
      icon: ClIcons.heart,
      fill: cl.colors.peachSoft,
    ),
    MilestoneGroup.motor => (icon: ClIcons.ruler, fill: cl.care.growth.soft),
    MilestoneGroup.cognitive => (icon: ClIcons.spark, fill: cl.care.sleep.soft),
    MilestoneGroup.socialEmotional => (
      icon: ClIcons.family,
      fill: cl.colors.mintSoft,
    ),
    null => (icon: ClIcons.star, fill: cl.colors.sunshineSoft),
  };
}

String rangeLabel(AppLocalizations l10n, MilestoneAgeRange r) =>
    r.unit == AgeUnit.weeks
    ? l10n.mtRangeWeeks(r.from, r.to)
    : l10n.mtRangeMonths(r.from, r.to);

String rangeChipLabel(AppLocalizations l10n, MilestoneAgeRange r) =>
    r.unit == AgeUnit.weeks
    ? l10n.mtRangeChipWeeks(r.from, r.to)
    : l10n.mtRangeChipMonths(r.from, r.to);

// ---------- Reading ----------

final _sentenceEnd = RegExp(r'(?<=[.!?…])\s+(?=[\p{Lu}"“‘])', unicode: true);

/// Splits a portal paragraph ("Cách nhận biết") into short points to scan. A fragment under
/// [minLength] (a quoted reply such as "Ăn cơm.") stays with the sentence before it.
List<String> readingChunks(String text, {int minLength = 32}) {
  final paragraphs = text
      .split(RegExp(r'\n\s*'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  final chunks = <String>[];
  for (final p in paragraphs) {
    var first = true;
    for (final s in p.split(_sentenceEnd)) {
      if (!first && chunks.isNotEmpty && s.length < minLength) {
        chunks.last = '${chunks.last} $s';
      } else {
        chunks.add(s);
      }
      first = false;
    }
  }
  return chunks;
}

// ---------- Dates ----------

/// "Thứ Năm, 08/10/2026" / "Thursday, 8 Oct 2026".
String longDay(String lang, DateTime d) => lang == 'en'
    ? DateFormat('EEEE, d MMM y', 'en').format(d)
    : DateFormat('EEEE, dd/MM/yyyy', 'vi').format(d);

/// "05/10" / "5 Oct".
String badgeDay(String lang, DateTime d) => lang == 'en'
    ? DateFormat('d MMM', 'en').format(d)
    : DateFormat('dd/MM', 'vi').format(d);

/// The day sheet (from the date of birth, else three years back, to today).
Future<DateTime?> pickMilestoneDay(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) {
  var picked = initial.isAfter(last)
      ? last
      : (initial.isBefore(first) ? first : initial);
  return showClSheet<DateTime>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.mtPickDate),
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: cl.isNightCare ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: cl.text.title2.copyWith(
                    color: cl.colors.ink,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(
              sheet,
            ).pop(DateTime(picked.year, picked.month, picked.day)),
          ),
        ],
      );
    },
  );
}

// ---------- Page chrome ----------

/// A pushed page: back (or close) · baby chip, then the content (extract shared chrome: cloud
/// page, content px 16, gap 14).
class MtPage extends ConsumerWidget {
  const MtPage({
    required this.children,
    this.close = false,
    this.bottom,
    super.key,
  });

  final List<Widget> children;
  final bool close;

  /// Pinned under the content (3g "Lưu mốc").
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
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
                onBack: close ? null : () => context.pop(),
                brand: close
                    ? MtRoundIcon(
                        icon: ClIcons.close,
                        label: l10n.a11yClose,
                        onPressed: () => context.pop(),
                      )
                    : null,
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
              Padding(
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

/// The round 44 px white button of the design's top row (back / close).
class MtRoundIcon extends StatelessWidget {
  const MtRoundIcon({
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
          color: cl.colors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, color: cl.colors.ink),
      ),
    );
  }
}

class MtTitle extends StatelessWidget {
  const MtTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.cl.text.largeTitle.copyWith(fontSize: 28)),
  );
}

/// Bold 17 section header.
class MtSection extends StatelessWidget {
  const MtSection(this.text, {this.trailing, super.key});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: ClSpace.s3),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: context.cl.text.headline.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// The white list group (radius 16).
class MtGroupCard extends StatelessWidget {
  const MtGroupCard({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cl.colors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// The icon chip on its group tint (p 8, radius 12, 18 px icon).
class MtGroupIcon extends StatelessWidget {
  const MtGroupIcon(this.group, {this.size = 18, super.key});
  final MilestoneGroup? group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = groupStyle(context, group);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClIcon(style.icon, size: size, color: context.cl.colors.ink),
    );
  }
}

/// A list row: icon chip, title, subline, and a date badge, a tag or a chevron.
class MtRow extends StatelessWidget {
  const MtRow({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final MilestoneGroup? group;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            MtGroupIcon(group),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                ClIcon(
                  ClIcons.chevronRight,
                  size: 16,
                  color: cl.colors.inkMuted,
                ),
          ],
        ),
      ),
    );
  }
}

/// "✓ 05/10" (mint) or a quiet tag ("Sắp tới", "Chưa ghi").
class MtBadge extends StatelessWidget {
  const MtBadge({required this.label, this.check = false, super.key});
  final String label;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final fg = check ? cl.colors.mintText : cl.colors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: check ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (check) ...[
            ClIcon(ClIcons.check, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: cl.text.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip (radius 999, px 12 / py 6, SemiBold 13) on [fill], ink text.
class MtChip extends StatelessWidget {
  const MtChip({
    required this.label,
    required this.fill,
    this.icon,
    this.color,
    super.key,
  });
  final String label;
  final Color fill;
  final ClIcons? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final fg = color ?? cl.colors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: cl.text.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled box (label SemiBold 13 muted; white box, 1 px control border, radius 14).
class MtField extends StatelessWidget {
  const MtField({
    required this.label,
    required this.child,
    this.onTap,
    this.semanticLabel,
    super.key,
  });
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        border: Border.all(color: cl.colors.controlBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: cl.text.label.copyWith(
            color: cl.colors.inkMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        if (onTap == null)
          box
        else
          ClPressable(
            onPressed: onTap,
            semanticLabel: semanticLabel ?? label,
            child: box,
          ),
      ],
    );
  }
}

/// The date box: cake · "Thứ Năm, 08/10/2026" · chevron.
class MtDateField extends StatelessWidget {
  const MtDateField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MtField(
      label: label,
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: Row(
        children: [
          ClIcon(ClIcons.cake, size: 18, color: cl.colors.ink),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              value,
              style: cl.text.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ClIcon(ClIcons.chevronDown, size: 16, color: cl.colors.inkMuted),
        ],
      ),
    );
  }
}

/// Picked photos (76 px, radius 14) and the dashed camera slot.
class MtPhotoStrip extends StatelessWidget {
  const MtPhotoStrip({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.size = 76,
    super.key,
  });
  final List<PickedMedia> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final (i, p) in photos.indexed)
          ClPressable(
            onPressed: () => onRemove(i),
            semanticLabel: l10n.mtRemovePhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: size,
                height: size,
                child: MtPickedImage(p),
              ),
            ),
          ),
        ClPressable(
          onPressed: onAdd,
          semanticLabel: l10n.mtAddPhotos,
          child: CustomPaint(
            painter: MtDashedBorder(color: cl.colors.controlBorder, radius: 14),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: ClIcon(ClIcons.camera, size: 18, color: cl.colors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A picked photo or video from the phone (its thumbnail, else the file); a video has a play
/// badge as in Kỷ niệm's grid.
class MtPickedImage extends StatelessWidget {
  const MtPickedImage(this.picked, {super.key});
  final PickedMedia picked;

  @override
  Widget build(BuildContext context) {
    final bytes = picked.thumbBytes;
    final fallback = ColoredBox(color: context.cl.colors.surface2);
    final video = picked.type == MediaKind.video;
    final Widget image;
    if (bytes != null) {
      image = Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (video) {
      image = fallback;
    } else {
      image = Image.file(
        File(picked.file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (!video) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// The 1 px dashed outline of the design's add tiles.
class MtDashedBorder extends CustomPainter {
  const MtDashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.5),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(MtDashedBorder old) =>
      old.color != color || old.radius != radius;
}

/// "+ Tạo mốc riêng": the dashed button.
class MtDashedButton extends StatelessWidget {
  const MtDashedButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: CustomPaint(
        painter: MtDashedBorder(color: cl.colors.controlBorder, radius: 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(ClIcons.plus, size: 16, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Text(
                label,
                style: cl.text.body.copyWith(
                  color: cl.colors.mintText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Nội dung minh hoạ · chờ chuyên môn duyệt" (D-073 #2), or who reviewed it.
class MtContentNote extends StatelessWidget {
  const MtContentNote({required this.illustrative, this.reviewer, super.key});
  final bool illustrative;
  final String? reviewer;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final text = illustrative || reviewer == null
        ? l10n.mtIllustrative
        : l10n.mtReviewed(reviewer!);
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    );
  }
}
