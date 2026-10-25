import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_models.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_motion.dart';

String printMoney(BuildContext context, int value) => NumberFormat.currency(
  locale: Localizations.localeOf(context).toLanguageTag(),
  symbol: '₫',
  decimalDigits: 0,
).format(value);
String printProductName(AppLocalizations l, String p) => switch (p) {
  'single' => l.psSingle,
  'five' => l.psFive,
  'book' => l.psBook,
  _ => l.psTrio,
};
String printStyleName(AppLocalizations l, String s) => switch (s) {
  'playful' => l.psPlayful,
  'timeless' => l.psTimeless,
  _ => l.psMinimal,
};
String printStatusName(AppLocalizations l, String s) => switch (s) {
  'awaitingDeposit' || 'pendingConfirmation' => l.psPendingConfirmation,
  'confirmed' => l.psConfirmed,
  'printing' => l.psPrinting,
  'shipped' => l.psShipped,
  'delivered' => l.psDelivered,
  'cancelled' => l.psCancelled,
  _ => s,
};

class PrintCard extends StatelessWidget {
  const PrintCard({
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(14),
    this.lifted = true,
    this.radius = 20,
    this.outlined = false,
    super.key,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool selected, lifted, outlined;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final card = AnimatedContainer(
      duration: PrintMotion.duration(context),
      curve: PrintMotion.curve,
      padding: padding,
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: lifted ? cl.shadows.card : null,
        border: selected
            ? Border.all(color: cl.colors.mintDeep, width: 2)
            : outlined
            ? Border.all(color: cl.colors.separator)
            : null,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    return onTap == null ? card : ClPressable(onPressed: onTap, child: card);
  }
}

class PrintNotice extends StatelessWidget {
  const PrintNotice(this.text, {this.warning = false, super.key});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? context.cl.colors.peachSoft : context.cl.colors.mintSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClIcon(
          warning ? ClIcons.alert : ClIcons.check,
          size: 18,
          color: context.cl.colors.ink,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: psText(
              context,
              13,
              height: 1.45,
              color: context.cl.colors.mintText,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Vector layout translated from PS11/PS12 and the square pages in PS21.
/// Photos and copy stay dynamic; every coordinate is a fraction of the final trim size.
class PrintArtwork extends StatelessWidget {
  const PrintArtwork({
    required this.design,
    required this.media,
    this.page = 0,
    this.safeArea = false,
    this.onPhotoTap,
    this.onTextTap,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final int page;
  final bool safeArea;
  final ValueChanged<int>? onPhotoTap;
  final VoidCallback? onTextTap;
  @override
  Widget build(BuildContext context) {
    final d = design,
        l = AppLocalizations.of(context),
        dims = printSizes[d.size]!,
        playful = d.style == 'playful',
        timeless = d.style == 'timeless';
    final paper = Color(
          playful
              ? 0xfffceef1
              : timeless
              ? 0xffece5da
              : 0xfff8f3ea,
        ),
        ink = Color(
          playful
              ? 0xff2f4858
              : timeless
              ? 0xff4a3f35
              : 0xff3b3229,
        ),
        accent = Color(
          playful
              ? 0xffe9a23b
              : timeless
              ? 0xff8c7b66
              : 0xffb89b72,
        );
    return AspectRatio(
      aspectRatio: dims.$1 / dims.$2,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth,
              h = c.maxHeight,
              slots = d.slots(page),
              isInfo = !d.isBook && d.layoutPage(page) == 1,
              bookCover = d.isBook && page == 0,
              bookText = d.isBook && d.bookLayout(page) == 'text';
          Widget text(
            String value,
            double y,
            double size, {
            bool serif = false,
            bool italic = false,
            Color? color,
            double tracking = 0,
            double maxHeight = .16,
            FontWeight? weight,
          }) {
            return Positioned(
              left: w * .0625,
              top: h * y,
              width: w * .875,
              child: GestureDetector(
                onTap: onTextTap,
                child: LayoutBuilder(
                  builder: (context, b) {
                    var fs = w * size;
                    TextStyle style() => TextStyle(
                      fontFamily: serif
                          ? (timeless
                                ? 'Cormorant Garamond Keepsake'
                                : playful
                                ? 'Baloo 2 Keepsake'
                                : 'Playfair Display Keepsake')
                          : 'Be Vietnam Pro Keepsake',
                      fontSize: fs,
                      fontWeight:
                          weight ??
                          (serif
                              ? playful
                                    ? FontWeight.w700
                                    : FontWeight.w400
                              : FontWeight.w300),
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                      color: color ?? ink,
                      height: 1.25,
                      letterSpacing: w * tracking,
                    );
                    for (var attempt = 0; attempt < 12; attempt++) {
                      final p = TextPainter(
                        text: TextSpan(text: value, style: style()),
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: b.maxWidth);
                      final fits = p.height <= h * maxHeight;
                      p.dispose();
                      if (fits) break;
                      fs *= .91;
                    }
                    return Text(
                      value,
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.noScaling,
                      maxLines: 8,
                      overflow: TextOverflow.clip,
                      style: style(),
                    );
                  },
                ),
              ),
            );
          }

          Widget photo(
            int slot,
            double x,
            double y,
            double pw,
            double ph, {
            bool circle = false,
            int position = 0,
          }) {
            Widget image = _PrintPhoto(
              media: slot < d.mediaIds.length
                  ? media.where((m) => m.id == d.mediaIds[slot]).firstOrNull
                  : null,
            );
            if (circle) image = ClipOval(child: image);
            return Positioned(
              left: w * x,
              top: h * y,
              width: w * pw,
              height: h * ph,
              child: GestureDetector(
                onTap: onPhotoTap == null ? null : () => onPhotoTap!(position),
                child: image,
              ),
            );
          }

          final title = page < d.pageTitles.length
              ? d.pageTitles[page]
              : bookCover
              ? '${d.title}\n${d.name}'
              : '';
          final subtitle = page < d.pageSubtitles.length
              ? d.pageSubtitles[page]
              : '';
          final birth = d.birthDetails.split('\n');
          return ColoredBox(
            color: paper,
            child: Stack(
              children: [
                if (timeless)
                  for (final inset in [.04, .06])
                    Positioned(
                      left: w * inset,
                      top: h * inset,
                      width: w * (1 - 2 * inset),
                      height: h * (1 - 2 * inset),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: accent, width: .65),
                          ),
                        ),
                      ),
                    ),
                if (playful)
                  for (final p in [
                    (0.07, 0.06),
                    (0.88, 0.10),
                    (0.93, 0.80),
                    (0.05, 0.85),
                  ])
                    Positioned(
                      left: w * p.$1,
                      top: h * p.$2,
                      child: Container(
                        width: w * .035,
                        height: w * .035,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                if (bookText) ...[
                  text(title, .28, .08, serif: true, color: accent),
                  text(
                    d.message,
                    .44,
                    .055,
                    serif: true,
                    italic: true,
                    maxHeight: .40,
                  ),
                ] else if (d.isBook) ...[
                  if (slots.length == 4)
                    for (var i = 0; i < 4; i++)
                      photo(
                        slots[i],
                        .09375 + (i % 2) * .425,
                        .075 + (i ~/ 2) * .425,
                        .3875,
                        .3875,
                        position: i,
                      )
                  else if (slots.isNotEmpty)
                    photo(
                      slots.first,
                      bookCover ? .1333 : .09375,
                      bookCover ? .12 : .0875,
                      bookCover ? .7333 : .8125,
                      bookCover ? .5333 : .625,
                    ),
                  text(
                    title,
                    bookCover
                        ? .69
                        : slots.length == 4
                        ? .90
                        : .75,
                    bookCover
                        ? .08
                        : slots.length == 4
                        ? .05625
                        : .06875,
                    serif: true,
                    maxHeight: bookCover ? .18 : .12,
                  ),
                  if (subtitle.isNotEmpty)
                    text(subtitle, .85, .0375, color: accent),
                  if (bookCover)
                    text(
                      d.date.split('-').reversed.join('.'),
                      .916,
                      .035,
                      color: accent,
                      tracking: .004,
                    ),
                ] else if (isInfo) ...[
                  text(
                    'HELLO, LITTLE ONE',
                    .1222,
                    .0423,
                    color: accent,
                    tracking: .0084,
                  ),
                  text(d.name, .1667, .2077, serif: true, maxHeight: .23),
                  text(
                    d.title,
                    .3778,
                    .0923,
                    serif: true,
                    italic: true,
                    color: accent,
                  ),
                  Positioned(
                    left: w * .3846,
                    top: h * .5111,
                    width: w * .2308,
                    height: h * .0033,
                    child: ColoredBox(color: accent),
                  ),
                  if (d.showBirthDetails && birth.first.isNotEmpty) ...[
                    text(
                      l.psBirthDateLabel,
                      .5556,
                      .0323,
                      color: accent,
                      tracking: .0038,
                    ),
                    text(birth.first, .5833, .0654, serif: true),
                    if (birth.length > 1) ...[
                      text(
                        l.psBirthMeasureLabel,
                        .6667,
                        .0323,
                        color: accent,
                        tracking: .0038,
                      ),
                      text(
                        birth.skip(1).join(' · '),
                        .6944,
                        .0654,
                        serif: true,
                      ),
                    ],
                  ],
                  text(d.message, .8889, .04615, serif: true, italic: true),
                ] else ...[
                  if (slots.length == 4)
                    for (var i = 0; i < 4; i++)
                      photo(
                        slots[i],
                        .0923 + (i % 2) * .4231,
                        .0778 + (i ~/ 2) * .3433,
                        .3923,
                        .3258,
                        position: i,
                      )
                  else if (slots.isNotEmpty)
                    photo(
                      slots.first,
                      playful ? .1429 : .0923,
                      playful ? .1026 : .0778,
                      playful ? .7143 : .8154,
                      playful ? .5128 : .6356,
                      circle: playful,
                    ),
                  text(
                    slots.length == 4 ? '${d.name} — ${d.title}' : d.name,
                    slots.length == 4
                        ? .79
                        : playful
                        ? .72
                        : .7471,
                    slots.length == 4
                        ? .085
                        : playful
                        ? .14
                        : .1385,
                    serif: true,
                  ),
                  if (slots.length != 4)
                    text(
                      '${d.title.toUpperCase()} · ${d.date.split('-').reversed.join('.')}',
                      playful ? .88 : .886,
                      .0423,
                      color: accent,
                      tracking: .0076,
                    ),
                ],
                if (safeArea)
                  Positioned(
                    left: w * .045,
                    top: h * .035,
                    width: w * .91,
                    height: h * .93,
                    child: IgnorePointer(
                      child: CustomPaint(painter: _SafeAreaPainter()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrintPhoto extends StatelessWidget {
  const _PrintPhoto({this.media});
  final MediaItem? media;
  @override
  Widget build(BuildContext context) {
    final path = media?.displayPath;
    if (path == null) {
      return ColoredBox(
        color: const Color(0xffe8e2d8),
        child: Center(
          child: ClIcon(ClIcons.camera, color: const Color(0xff8c7b66)),
        ),
      );
    }
    return Image(
      image: StorageImage(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(child: ClIcon(ClIcons.alert)),
    );
  }
}

class _SafeAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffef8b84)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 4).clamp(0, size.width), 0),
        paint,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset((x + 4).clamp(0, size.width), size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, (y + 4).clamp(0, size.height)),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, y),
        Offset(size.width, (y + 4).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SafeAreaPainter oldDelegate) => false;
}

/// PS03 uses the supplied easel/edge assets; PS11 uses a front-facing tabletop.
class PrintFrame extends StatelessWidget {
  const PrintFrame({
    required this.design,
    required this.media,
    this.page = 0,
    this.standing = false,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final int page;
  final bool standing;
  @override
  Widget build(BuildContext context) {
    if (design.isBook) {
      return FittedBox(
        child: SizedBox(
          width: 96,
          height: 94,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 8,
                top: 6,
                width: 86,
                height: 86,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0x19000000)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4d332414),
                        blurRadius: 14,
                        offset: Offset(8, 14),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: 86,
                height: 86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: PrintArtwork(design: design, media: media, page: page),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: 5.16,
                height: 86,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: .28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final art = DecoratedBox(
      decoration: BoxDecoration(
        color: design.frame == 'wood'
            ? const Color(0xffc39d72)
            : const Color(0xfffbfaf7),
        border: Border.all(color: const Color(0x14000000)),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40332414),
            blurRadius: 12,
            offset: Offset(4, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: PrintArtwork(design: design, media: media, page: page),
      ),
    );
    if (!standing || design.isBook) return art;
    // Natural dimensions and layer slots from PS03 Standing frame · 3/4.
    final compact = design.count == 1;
    final suffix = compact
        ? '3'
        : page % 3 == 0
        ? ''
        : '${page % 3}';
    return FittedBox(
      child: SizedBox(
        width: compact ? 65.8998 : 105.455,
        height: compact ? 79.3849 : 127.728,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: compact ? -1.6 : -4.55,
              top: compact ? 60.05 : 90.24,
              child: Image.asset(
                'assets/print-studio/shadow${compact ? '1' : ''}.png',
                width: compact ? 60.4268 : 97.732,
                height: compact ? 13.3408 : 24.734,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset(
                'assets/print-studio/easel-leg$suffix.svg',
              ),
            ),
            Positioned(
              left: 0,
              top: compact ? -1.5526 : -2.741,
              child: SvgPicture.asset(
                'assets/print-studio/frame-edge$suffix.svg',
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: compact ? 49.29 : 76.345,
              height: compact ? 65.565 : 100.815,
              child: Transform(
                alignment: Alignment.topLeft,
                transform: Matrix4.identity()
                  ..setEntry(0, 1, .0813)
                  ..rotateZ(.0812),
                child: art,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrintScene extends StatelessWidget {
  const PrintScene({
    required this.design,
    required this.media,
    this.height = 300,
    this.standing = false,
    this.decorated = true,
    this.page,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final double height;
  final bool standing, decorated;
  final int? page;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) {
          final n = page != null || design.isBook ? 1 : design.count;
          final inset = standing
              ? 12.0
              : n == 1
              ? c.maxWidth * .22
              : 40.0;
          final gap = standing ? 0.0 : 12.0;
          final width = (c.maxWidth - inset * 2 - gap * (n - 1)) / n;
          final artHeight = design.isBook
              ? height * .78
              : standing
              ? (width * 1.21).clamp(0.0, height * .85)
              : (width * 1.35).clamp(0.0, height * .72);
          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xfff1e9de), Color(0xffe6daca)],
                    ),
                  ),
                ),
              ),
              if (!design.isBook)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * (standing ? .30 : .33),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xffdcc6a8), Color(0xffc9af8c)],
                      ),
                    ),
                  ),
                ),
              if (decorated && !design.isBook) ...[
                Positioned(
                  left: c.maxWidth * .05,
                  top: height * .18,
                  child: SizedBox(
                    width: c.maxWidth * .07,
                    height: height * .13,
                    child: FittedBox(
                      child: SvgPicture.asset(
                        'assets/print-studio/balloon-mint.svg',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: c.maxWidth * .04,
                  top: height * .12,
                  child: SizedBox(
                    width: c.maxWidth * .09,
                    height: height * .17,
                    child: FittedBox(
                      child: SvgPicture.asset(
                        'assets/print-studio/balloon.svg',
                      ),
                    ),
                  ),
                ),
              ],
              if (standing && !design.isBook)
                for (var p = 0; p < n; p++)
                  Positioned(
                    left: n == 1
                        ? c.maxWidth * .18
                        : c.maxWidth * (.04 + p * .31),
                    top: n == 1 ? height * .028 : height * .3132,
                    width: n == 1 ? c.maxWidth * .7086 : c.maxWidth * .32648,
                    height: n == 1
                        ? math.min(height * .90, c.maxWidth * .85)
                        : c.maxWidth * .3955,
                    child: PrintFrame(
                      design: design,
                      media: media,
                      page: page ?? p,
                      standing: true,
                    ),
                  )
              else
                Positioned(
                  left: inset,
                  right: inset,
                  bottom: design.isBook
                      ? height * .11
                      : height * (standing ? .14 : .23),
                  height: artHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var p = 0; p < n; p++) ...[
                        if (p > 0) SizedBox(width: gap),
                        Expanded(
                          child: PrintFrame(
                            design: design,
                            media: media,
                            page: page ?? p,
                            standing: standing,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class PrintBottomBar extends StatelessWidget {
  const PrintBottomBar({
    required this.label,
    required this.onPressed,
    this.price,
    this.busy = false,
    this.stacked = false,
    this.compactPrice = false,
    this.fillAction = false,
    this.priceLabel,
    this.caption,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });
  final String label;
  final String? priceLabel, secondaryLabel, caption;
  final VoidCallback? onSecondary;
  final int? price;
  final VoidCallback? onPressed;
  final bool busy, stacked, compactPrice, fillAction;
  @override
  Widget build(BuildContext context) {
    final button = ClButton(
      label: label,
      onPressed: onPressed,
      loading: busy,
      expand: true,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: context.cl.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: context.cl.shadows.card,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 30),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (price != null) ...[
                    Row(
                      children: [
                        if (priceLabel != null)
                          Expanded(
                            child: Text(
                              priceLabel!,
                              style: context.cl.text.caption,
                            ),
                          ),
                        Text(
                          printMoney(context, price!),
                          style: context.cl.text.bodyStrong,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  button,
                ],
              )
            : Row(
                children: [
                  if (price != null)
                    Flexible(
                      fit: compactPrice ? FlexFit.loose : FlexFit.tight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              printMoney(context, price!),
                              style: psText(
                                context,
                                18,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (caption != null)
                            Text(
                              caption!,
                              style: psText(
                                context,
                                11,
                                color: context.cl.colors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (secondaryLabel != null) ...[
                    ClButton(
                      label: secondaryLabel!,
                      style: ClButtonStyle.secondary,
                      onPressed: onSecondary,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (fillAction)
                    Expanded(
                      child: ClButton(
                        label: label,
                        onPressed: onPressed,
                        loading: busy,
                        expand: true,
                      ),
                    )
                  else
                    ClButton(label: label, onPressed: onPressed, loading: busy),
                ],
              ),
      ),
    );
  }
}

String printCancelReasonLabel(AppLocalizations l, String reason) =>
    switch (reason) {
      'price' => l.psCancelPrice,
      'shipping_fee' => l.psCancelShipping,
      'delivery_time' => l.psCancelDelivery,
      'design' => l.psCancelDesign,
      'unreachable' => l.psCancelUnreachable,
      'customer_changed_mind' => l.psCancelChangedMind,
      _ => l.psCancelOther,
    };

class PrintSectionLabel extends StatelessWidget {
  const PrintSectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: psText(
      context,
      13,
      weight: FontWeight.w700,
      color: context.cl.colors.inkMuted,
    ),
  );
}

class PrintPill extends StatelessWidget {
  const PrintPill(this.text, {this.selected = false, this.onTap, super.key});
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onTap ?? () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? context.cl.colors.ink : context.cl.colors.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: context.cl.text.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? context.cl.colors.surface : context.cl.colors.ink,
        ),
      ),
    ),
  );
}

class PrintSteps extends StatelessWidget {
  const PrintSteps(this.current, {super.key});
  final int current;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl;
    final labels = [l.psConfirmStep, l.psShippingStep, l.psOrderReviewStep];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text('–', style: cl.text.caption),
              ),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= current ? cl.colors.mintDeep : cl.colors.surface2,
              ),
              child: Text(
                '${i + 1}',
                style: cl.text.caption.copyWith(
                  fontSize: 11,
                  color: i <= current
                      ? cl.colors.onMintDeep
                      : cl.colors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                labels[i],
                style: cl.text.caption.copyWith(
                  fontSize: 12,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PrintInput extends StatelessWidget {
  const PrintInput({
    required this.label,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.autofillHints,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PrintSectionLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        style: context.cl.text.body.copyWith(fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.cl.colors.surface,
          contentPadding: const EdgeInsets.all(14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.cl.colors.controlBorder),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ],
  );
}

/// Natural SVG geometry from PS15 (940:13962 / 940:13978).
class PrintFrameConstruction extends StatelessWidget {
  const PrintFrameConstruction({this.side = false, super.key});
  final bool side;
  @override
  Widget build(BuildContext context) => FittedBox(
    child: SizedBox(
      width: side ? 46.3814 : 73.671,
      height: 84,
      child: Stack(
        children: [
          if (side) ...[
            Positioned(
              left: 4,
              top: 0,
              width: 5.411,
              height: 77.302,
              child: Transform.rotate(
                angle: -.14,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xfffafaf5), Color(0xffd1ccc2)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset('assets/print-studio/easel-side.svg'),
            ),
          ] else ...[
            Positioned(
              left: 0,
              top: 0,
              width: 54.723,
              height: 75.792,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffc7a378),
                  border: Border.all(
                    color: const Color(0xff997852),
                    width: 2.189,
                  ),
                ),
              ),
            ),
            for (final xy in [(24.63, .42), (24.63, 73.18)])
              Positioned(
                left: xy.$1,
                top: xy.$2,
                width: 5.472,
                height: 2.189,
                child: const ColoredBox(color: Color(0xffbfbfbf)),
              ),
            for (final x in [0.0, 52.53])
              Positioned(
                left: x,
                top: 29.69,
                width: 2.189,
                height: 5.472,
                child: const ColoredBox(color: Color(0xffbfbfbf)),
              ),
            Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset('assets/print-studio/easel-back.svg'),
            ),
            Positioned(
              left: 3.28,
              top: 6.06,
              width: 18.606,
              height: 8.756,
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Text(
                  'child life',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 1.915, color: Color(0xff3b3229)),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
