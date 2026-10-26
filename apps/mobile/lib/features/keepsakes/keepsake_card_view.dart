import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/widgets/cl_icon.dart';
import '../memories/media_bytes.dart';
import 'keepsake_catalog.dart';
import 'keepsake_personalization.dart' show premiumTextFit, premiumCardLayers;

/// The one-colour Child Life lockup card `brand` layers tint (D-068 #10); written from
/// contracts by `packages/contracts/scripts/keepsake-fixture.mjs`.
const keepsakeBrandAsset = 'assets/logo/lockup-h-tint.svg';

/// Loads the lockup before a card is exported, so the picture never misses it.
Future<void> precacheKeepsakeBrand() async {
  final loader = SvgAssetLoader(keepsakeBrandAsset);
  await svg.cache.putIfAbsent(
    loader.cacheKey(null),
    () => loader.loadBytes(null),
  );
}

/// The parent's photo in a slot, with "kéo để căn" (drag to reposition) and pinch to zoom.
@immutable
class CardPhoto {
  const CardPhoto(
    this.image, {
    this.align = Alignment.center,
    this.zoom = 1,
    this.takenAt,
  });
  final ImageProvider image;
  final Alignment align;
  final double zoom;

  /// When the photo was taken (Kỷ niệm media), for "Ngày đầu" / "Tháng 6" labels.
  final DateTime? takenAt;

  CardPhoto copyWith({Alignment? align, double? zoom}) => CardPhoto(
    image,
    align: align ?? this.align,
    zoom: zoom ?? this.zoom,
    takenAt: takenAt,
  );
}

/// What the text fields of a card say, filled from the baby's profile and the parent's edits.
@immutable
class CardContent {
  const CardContent({
    required this.occasion,
    required this.name,
    required this.date,
    required this.quote,
    this.title = '',
    this.photos = const [],
    this.age = '',
    this.ageNumber = '',
    this.ageUnit = '',
    this.birthStats = '',
    this.headline = '',
    this.message = '',
    this.photoLabels = const [],
    this.personalized = const {},
  });
  final Map<String, String> personalized;
  final String occasion;
  final String name;
  final String date;
  final String quote;
  final String title;
  final List<CardPhoto?> photos;

  /// "3 tháng"; and split for big-number layouts: "3" + "tháng" (E-2).
  final String age;
  final String ageNumber;
  final String ageUnit;

  /// "3,2 kg · 50 cm" from the first growth record (C01); empty when there is none.
  final String birthStats;
  final String headline;
  final String message;

  /// Per photo slot ("Ngày đầu", "Tháng 6"; C10).
  final List<String> photoLabels;

  String field(String key) =>
      personalized[key] ??
      switch (key) {
        'occasion' => occasion,
        'name' => name,
        'date' => date,
        'nameDate' => [name, date].where((s) => s.isNotEmpty).join(' · '),
        'quote' => quote.isEmpty ? '' : '“$quote”',
        'title' => title,
        'age' => age,
        'ageNumber' => ageNumber,
        'ageUnit' => ageUnit,
        'birthStats' => birthStats,
        'headline' => headline,
        'message' => message,
        'photoLabel0' => photoLabels.isNotEmpty ? photoLabels[0] : '',
        'photoLabel1' => photoLabels.length > 1 ? photoLabels[1] : '',
        _ => '',
      };
}

/// How a template asset is loaded (`content/keepsakes/{asset}`, public and cached like media);
/// tests replace it.
final keepsakeAssetImageProvider = Provider<ImageProvider Function(String)>(
  (_) =>
      (asset) => StorageImage(keepsakeAssetPath(asset)),
);

/// Bundled with the app, so the export never falls back to a system font. Be Vietnam Pro has its
/// own family here with the Bold weight the cards need (pubspec).
const _fontFamilies = {
  'beVietnamPro': 'Be Vietnam Pro Keepsake',
  'lora': 'Lora',
  'dancingScript': 'Dancing Script',
  'playfair': 'Playfair Display Keepsake',
  'baloo': 'Baloo 2 Keepsake',
  'patrickHand': 'Patrick Hand Keepsake',
};

/// Draws any card template from its layers (D-068 #7): background, photo, text, shape, image.
/// Everything scales with [width], so the on-screen card and the 2160 px export are the same
/// drawing.
class KeepsakeCardView extends ConsumerWidget {
  const KeepsakeCardView({
    required this.template,
    required this.format,
    required this.content,
    required this.width,
    this.palette,
    this.onPhotoTap,
    this.onPhotoChanged,
    this.photoPlaceholder,
    this.activeSlot,
    this.previewProgress,
    this.reducedMotion = false,
    super.key,
  });

  final KeepsakeTemplate template;
  final KeepsakeFormat format;
  final CardContent content;
  final double width;

  /// MM11 "Màu"; defaults to the template's.
  final KeepsakePalette? palette;

  /// MM11 "Chạm ảnh để đổi".
  final ValueChanged<int>? onPhotoTap;

  /// MM11 "kéo để căn": the slot and its new position / zoom.
  final void Function(int slot, CardPhoto photo)? onPhotoChanged;

  /// What an empty slot shows (the editor's "Chọn ảnh").
  final Widget? photoPlaceholder;

  /// Templates with several photos: the slot the editor fills next, outlined. Never set while
  /// exporting.
  final int? activeSlot;
  final double? previewProgress;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = Size(width, width / format.aspect);
    final p = palette ?? template.palette;
    final asset = ref.watch(keepsakeAssetImageProvider);
    final layers = template.personalization != null
        ? premiumCardLayers(template, format, content)
        : template.layouts[format] ??
              template.layouts.values.firstOrNull ??
              const [];
    return SizedBox.fromSize(
      size: size,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final l in layers)
              if (previewProgress == null)
                _layer(l, size, p, asset)
              else
                _animatedLayer(l, size, p, asset),
          ],
        ),
      ),
    );
  }

  Widget _animatedLayer(
    KeepsakeLayer l,
    Size size,
    KeepsakePalette p,
    ImageProvider Function(String) asset,
  ) {
    final start = reducedMotion
        ? 0.0
        : switch (l) {
            KeepsakePhotoSlot(:final slot) =>
              0.15 +
                  (template.photosMax > 1
                      ? 0.08 * slot / (template.photosMax - 1)
                      : 0),
            KeepsakeTextLayer() || KeepsakeBrand() => 0.35,
            _ => 0.0,
          };
    final end = reducedMotion
        ? 0.15
        : switch (l) {
            KeepsakePhotoSlot(:final slot) =>
              template.photosMax > 1
                  ? 0.27 + 0.08 * slot / (template.photosMax - 1)
                  : 0.35,
            KeepsakeTextLayer() || KeepsakeBrand() => 0.55,
            _ => 0.15,
          };
    final progress = Curves.easeOut.transform(
      ((previewProgress! - start) / (end - start)).clamp(0.0, 1.0),
    );
    return Positioned.fill(
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(
            0,
            reducedMotion || l is KeepsakeBackground
                ? 0
                : (1 - progress) * 12 * size.width / 1080,
          ),
          child: Stack(children: [_layer(l, size, p, asset)]),
        ),
      ),
    );
  }

  /// A positioned layer, tilted about its centre (E-3).
  static Widget _place(Rect r, double degrees, Widget child) =>
      Positioned.fromRect(
        rect: r,
        child: degrees == 0
            ? child
            : Transform.rotate(angle: degrees * math.pi / 180, child: child),
      );

  Widget _layer(
    KeepsakeLayer l,
    Size size,
    KeepsakePalette p,
    ImageProvider Function(String) asset,
  ) {
    switch (l) {
      case KeepsakeBackground():
        return Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: l.color.resolve(p),
              image: l.asset == null
                  ? null
                  : DecorationImage(image: asset(l.asset!), fit: BoxFit.cover),
            ),
          ),
        );
      case KeepsakePhotoSlot():
        final r = l.rect.scale(size);
        final photo = l.slot < content.photos.length
            ? content.photos[l.slot]
            : null;
        return _place(
          r,
          l.rotate,
          _PhotoSlot(
            slot: l.slot,
            photo: photo,
            size: r.size,
            circle: l.circle,
            radius: l.radius * size.width,
            fallback: p.accent.withValues(alpha: 0.18),
            placeholder: photoPlaceholder,
            onTap: onPhotoTap,
            onChanged: onPhotoChanged,
            active: activeSlot == l.slot,
            ring: p.accent,
          ),
        );
      case KeepsakeTextLayer():
        final r = l.rect.scale(size);
        final raw = content.field(l.field);
        if (raw.isEmpty) return const SizedBox.shrink();
        // Script faces are never set in capitals (§1.2).
        final value =
            l.caps && l.font != 'dancingScript' && l.font != 'patrickHand'
            ? raw.toUpperCase()
            : raw;
        final fontSize = template.personalization == null
            ? l.size * size.width
            : premiumTextFit(value, l, size).size;
        final text = Text(
          value,
          // Template coordinates describe a fixed export canvas. System text size
          // scales the editor controls, not the artwork or the exported image.
          textScaler: TextScaler.noScaling,
          maxLines: l.maxLines,
          overflow: template.personalization == null
              ? TextOverflow.ellipsis
              : TextOverflow.clip,
          textAlign: l.align,
          softWrap: l.maxLines > 1,
          style: TextStyle(
            fontFamily: _fontFamilies[l.font] ?? 'Be Vietnam Pro Keepsake',
            fontWeight: FontWeight.values[(l.weight ~/ 100 - 1).clamp(0, 8)],
            fontStyle: l.italic ? FontStyle.italic : FontStyle.normal,
            fontSize: fontSize,
            letterSpacing: l.letterSpacing * fontSize,
            height: 1.25,
            color: l.color.resolve(p).withValues(alpha: l.opacity),
          ),
        );
        final x = switch (l.align) {
          TextAlign.left => -1.0,
          TextAlign.right => 1.0,
          _ => 0.0,
        };
        return _place(
          r,
          l.rotate,
          Align(
            alignment: Alignment(x, -1),
            // One line never wraps or clips: a long name shrinks to fit instead.
            child: template.personalization == null && l.maxLines == 1
                ? FittedBox(fit: BoxFit.scaleDown, child: text)
                : text,
          ),
        );
      case KeepsakeShape():
        final r = l.rect.scale(size);
        final color = l.color.resolve(p);
        final stroke = l.stroke * size.width;
        if (l.shape == 'star') {
          return _place(
            r,
            l.rotate,
            CustomPaint(painter: _StarPainter(color, stroke)),
          );
        }
        final to = l.gradientTo?.resolve(p);
        return _place(
          r,
          l.rotate,
          DecoratedBox(
            decoration: BoxDecoration(
              color: stroke > 0 || to != null ? null : color,
              gradient: stroke == 0 && to != null
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, to],
                    )
                  : null,
              border: stroke > 0
                  ? Border.all(color: color, width: stroke)
                  : null,
              shape: l.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: l.shape == 'circle'
                  ? null
                  : BorderRadius.circular(l.radius * size.width),
            ),
          ),
        );
      case KeepsakeBrand():
        return Positioned.fromRect(
          rect: l.rect.scale(size),
          child: Opacity(
            opacity: l.opacity,
            child: SvgPicture.asset(
              keepsakeBrandAsset,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                l.color.resolve(p),
                BlendMode.srcIn,
              ),
              semanticsLabel: 'Child Life',
            ),
          ),
        );
      case KeepsakeImage():
        return _place(
          l.rect.scale(size),
          l.rotate,
          Opacity(
            opacity: l.opacity,
            child: Image(
              image: asset(l.asset),
              fit: l.fit,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
    }
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.slot,
    required this.photo,
    required this.size,
    required this.circle,
    required this.radius,
    required this.fallback,
    required this.placeholder,
    required this.onTap,
    required this.onChanged,
    this.active = false,
    this.ring = const Color(0xFFFFFFFF),
  });

  final bool active;
  final Color ring;
  final int slot;
  final CardPhoto? photo;
  final Size size;
  final bool circle;
  final double radius;
  final Color fallback;
  final Widget? placeholder;
  final ValueChanged<int>? onTap;
  final void Function(int, CardPhoto)? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = photo;
    Widget child = p == null
        ? ColoredBox(
            color: fallback,
            child: Center(
              child:
                  placeholder ??
                  ClIcon(
                    ClIcons.camera,
                    size: math.min(size.width, size.height) * 0.2,
                    color: const Color(0x99FFFFFF),
                  ),
            ),
          )
        : ClipRect(
            child: Transform.scale(
              scale: p.zoom,
              alignment: p.align,
              child: Image(
                image: p.image,
                width: size.width,
                height: size.height,
                fit: BoxFit.cover,
                alignment: p.align,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: fallback),
              ),
            ),
          );
    child = circle
        ? ClipOval(child: child)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    if (active) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
          border: Border.all(color: ring, width: 3),
        ),
        child: child,
      );
    }
    if (onTap == null && onChanged == null) return child;
    var start = 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(slot),
      onScaleStart: (_) => start = p?.zoom ?? 1,
      onScaleUpdate: p == null || onChanged == null
          ? null
          : (d) {
              // Dragging right shows more of the left side of the picture.
              final a = Alignment(
                (p.align.x - d.focalPointDelta.dx / (size.width / 2)).clamp(
                  -1,
                  1,
                ),
                (p.align.y - d.focalPointDelta.dy / (size.height / 2)).clamp(
                  -1,
                  1,
                ),
              );
              onChanged!(
                slot,
                p.copyWith(align: a, zoom: (start * d.scale).clamp(1.0, 3.0)),
              );
            },
      child: child,
    );
  }
}

/// A five-point star, outlined (MM10's decoration) or filled.
class _StarPainter extends CustomPainter {
  const _StarPainter(this.color, this.stroke);
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = math.min(size.width, size.height) / 2 - stroke / 2;
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = stroke > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.stroke != stroke;
}
