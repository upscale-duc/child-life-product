import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Kỷ niệm 2.0 template catalog (D-068; plan `docs/product/remember-2-plan.md` §4.1), mirroring
/// `packages/contracts/src/keepsakes.ts`. Staff manage it in the portal (Mẫu kỷ niệm) and publish
/// it to `publicConfig/keepsakes`; the artwork lives at `content/keepsakes/{asset}` (D-068 #7:
/// nothing about a template is built into the app). A card is layers of a fixed set of
/// primitives drawn by `KeepsakeCardView`; anything this app cannot read is skipped, so an older
/// app never draws a newer template wrongly.

enum KeepsakeKind { card, video }

/// MM10 "Dọc 4:5 · Vuông · Story 9:16".
enum KeepsakeFormat {
  portrait(4 / 5),
  square(1),
  story(9 / 16);

  const KeepsakeFormat(this.aspect);

  /// Width / height.
  final double aspect;

  /// Export width in pixels (`keepsakeFormatSize`).
  static const exportWidth = 2160.0;
}

enum KeepsakeTier { free, premium }

String keepsakeAssetPath(String asset) => 'content/keepsakes/$asset';

@immutable
class Localized {
  const Localized(this.vi, this.en);
  final String vi;
  final String en;

  String of(Locale locale) => locale.languageCode == 'en' ? en : vi;

  static Localized? fromJson(Object? json) {
    if (json is! Map) return null;
    final vi = json['vi'], en = json['en'];
    if (vi is! String || en is! String) return null;
    return Localized(vi, en);
  }
}

Color? _hex(Object? v) {
  if (v is! String) return null;
  final m = RegExp(r'^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$').firstMatch(v);
  if (m == null) return null;
  return Color(int.parse('${m[2] ?? 'FF'}${m[1]}', radix: 16));
}

@immutable
class KeepsakePalette {
  const KeepsakePalette({
    required this.background,
    required this.ink,
    required this.accent,
  });
  final Color background;
  final Color ink;
  final Color accent;

  static KeepsakePalette? fromJson(Object? json) {
    if (json is! Map) return null;
    final b = _hex(json['background']),
        i = _hex(json['ink']),
        a = _hex(json['accent']);
    if (b == null || i == null || a == null) return null;
    return KeepsakePalette(background: b, ink: i, accent: a);
  }

  @override
  bool operator ==(Object other) =>
      other is KeepsakePalette &&
      other.background == background &&
      other.ink == ink &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(background, ink, accent);
}

/// A palette slot ("Màu" swaps it) or a fixed colour.
@immutable
class KeepsakeColor {
  const KeepsakeColor.slot(this.slot) : fixed = null;
  const KeepsakeColor.fixed(Color this.fixed) : slot = null;
  final String? slot;
  final Color? fixed;

  Color resolve(KeepsakePalette p) =>
      fixed ??
      switch (slot) {
        'background' => p.background,
        'accent' => p.accent,
        _ => p.ink,
      };

  static KeepsakeColor? fromJson(Object? v) {
    if (v == 'background' || v == 'ink' || v == 'accent') {
      return KeepsakeColor.slot(v! as String);
    }
    final c = _hex(v);
    return c == null ? null : KeepsakeColor.fixed(c);
  }
}

/// Position and size as fractions of the card.
@immutable
class KeepsakeRect {
  const KeepsakeRect(this.x, this.y, this.w, this.h);
  final double x, y, w, h;

  Rect scale(Size s) =>
      Rect.fromLTWH(x * s.width, y * s.height, w * s.width, h * s.height);

  static KeepsakeRect? fromJson(Object? json) {
    if (json is! Map) return null;
    final x = json['x'], y = json['y'], w = json['w'], h = json['h'];
    if (x is! num || y is! num || w is! num || h is! num) return null;
    return KeepsakeRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  }
}

/// The fixed set of primitives a card is made of (`keepsakeLayerSchema`).
@immutable
sealed class KeepsakeLayer {
  const KeepsakeLayer();

  static KeepsakeLayer? fromJson(Object? j) {
    if (j is! Map) return null;
    final rect = KeepsakeRect.fromJson(j['rect']);
    double n(String k, [double d = 0]) => (j[k] as num?)?.toDouble() ?? d;
    switch (j['type']) {
      case 'background':
        final color = KeepsakeColor.fromJson(j['color']);
        return color == null
            ? null
            : KeepsakeBackground(color: color, asset: j['asset'] as String?);
      case 'photo':
        if (rect == null) return null;
        return KeepsakePhotoSlot(
          slot: (j['slot'] as num?)?.toInt() ?? 0,
          rect: rect,
          circle: j['shape'] == 'circle',
          radius: n('radius'),
          rotate: n('rotate'),
        );
      case 'text':
        final color = KeepsakeColor.fromJson(j['color']);
        final field = j['field'];
        if (rect == null || color == null || field is! String) return null;
        return KeepsakeTextLayer(
          field: field,
          rect: rect,
          font: j['font'] as String? ?? 'beVietnamPro',
          weight: (j['weight'] as num?)?.toInt() ?? 400,
          size: n('size', 0.05),
          color: color,
          opacity: n('opacity', 1),
          align: switch (j['align']) {
            'left' => TextAlign.left,
            'right' => TextAlign.right,
            _ => TextAlign.center,
          },
          italic: j['italic'] == true,
          maxLines: (j['maxLines'] as num?)?.toInt() ?? 1,
          rotate: n('rotate'),
          letterSpacing: n('letterSpacing'),
          caps: j['caps'] == true,
        );
      case 'shape':
        final color = KeepsakeColor.fromJson(j['color']);
        final shape = j['shape'];
        if (rect == null || color == null || shape is! String) return null;
        if (!const ['rect', 'circle', 'star'].contains(shape)) return null;
        return KeepsakeShape(
          shape: shape,
          rect: rect,
          color: color,
          gradientTo: KeepsakeColor.fromJson(j['gradientTo']),
          radius: n('radius'),
          stroke: n('stroke'),
          rotate: n('rotate'),
        );
      case 'image':
        final asset = j['asset'];
        if (rect == null || asset is! String) return null;
        return KeepsakeImage(
          asset: asset,
          rect: rect,
          fit: switch (j['fit']) {
            'contain' => BoxFit.contain,
            'fill' => BoxFit.fill,
            _ => BoxFit.cover,
          },
          opacity: n('opacity', 1),
          rotate: n('rotate'),
        );
      case 'brand':
        final color = KeepsakeColor.fromJson(j['color']);
        if (rect == null || color == null || j['kind'] != 'lockup') return null;
        return KeepsakeBrand(
          rect: rect,
          color: color,
          opacity: n('opacity', 0.6),
        );
    }
    return null;
  }
}

class KeepsakeBackground extends KeepsakeLayer {
  const KeepsakeBackground({required this.color, this.asset});
  final KeepsakeColor color;
  final String? asset;
}

class KeepsakePhotoSlot extends KeepsakeLayer {
  const KeepsakePhotoSlot({
    required this.slot,
    required this.rect,
    required this.circle,
    required this.radius,
    this.rotate = 0,
  });

  /// Degrees (E-3).
  final double rotate;
  final int slot;
  final KeepsakeRect rect;
  final bool circle;

  /// Fraction of the card width.
  final double radius;
}

class KeepsakeTextLayer extends KeepsakeLayer {
  const KeepsakeTextLayer({
    required this.field,
    required this.rect,
    required this.font,
    required this.weight,
    required this.size,
    required this.color,
    required this.opacity,
    required this.align,
    required this.italic,
    required this.maxLines,
    this.rotate = 0,
    this.letterSpacing = 0,
    this.caps = false,
  });

  KeepsakeTextLayer withRect(KeepsakeRect rect) => KeepsakeTextLayer(
    field: field,
    rect: rect,
    font: font,
    weight: weight,
    size: size,
    color: color,
    opacity: opacity,
    align: align,
    italic: italic,
    maxLines: maxLines,
    rotate: rotate,
    letterSpacing: letterSpacing,
    caps: caps,
  );

  /// Degrees (E-3).
  final double rotate;

  /// Em (E-4).
  final double letterSpacing;
  final bool caps;

  /// occasion · name · date · nameDate · quote · title · age · ageNumber · ageUnit · birthStats ·
  /// headline · message · photoLabel0 · photoLabel1.
  final String field;
  final KeepsakeRect rect;
  final String font;
  final int weight;

  /// Fraction of the card width.
  final double size;
  final KeepsakeColor color;
  final double opacity;
  final TextAlign align;
  final bool italic;
  final int maxLines;
}

class KeepsakeShape extends KeepsakeLayer {
  const KeepsakeShape({
    required this.shape,
    required this.rect,
    required this.color,
    required this.gradientTo,
    required this.radius,
    required this.stroke,
    this.rotate = 0,
  });
  final double rotate;
  final String shape;
  final KeepsakeRect rect;
  final KeepsakeColor color;
  final KeepsakeColor? gradientTo;
  final double radius;

  /// 0 = filled; otherwise an outline this thick (fraction of the card width).
  final double stroke;
}

class KeepsakeImage extends KeepsakeLayer {
  const KeepsakeImage({
    required this.asset,
    required this.rect,
    required this.fit,
    required this.opacity,
    this.rotate = 0,
  });
  final double rotate;
  final String asset;
  final KeepsakeRect rect;
  final BoxFit fit;
  final double opacity;
}

/// The Child Life lockup (D-068 #10), one colour, fitted in [rect].
class KeepsakeBrand extends KeepsakeLayer {
  const KeepsakeBrand({
    required this.rect,
    required this.color,
    required this.opacity,
  });
  final KeepsakeRect rect;
  final KeepsakeColor color;
  final double opacity;
}

/// A video template's logo (D-068 #10): the corner mark and the closing lockup.
@immutable
class KeepsakeVideoBrand {
  const KeepsakeVideoBrand({
    required this.corner,
    required this.endCard,
    required this.opacity,
  });
  final bool corner;
  final bool endCard;
  final double opacity;

  static KeepsakeVideoBrand? fromJson(Object? j) => j is Map
      ? KeepsakeVideoBrand(
          corner: j['corner'] == true,
          endCard: j['endCard'] == true,
          opacity: (j['opacity'] as num?)?.toDouble() ?? 0.75,
        )
      : null;

  Map<String, Object?> toJson() => {
    'corner': corner,
    'endCard': endCard,
    'opacity': opacity,
  };
}

/// A video scene (MM06 "Cảnh 7: Bé cười"); one per photo slot.
@immutable
class KeepsakeScene {
  const KeepsakeScene({
    required this.hint,
    required this.optional,
    this.ageDays,
    this.occasion,
  });
  final Localized hint;
  final bool optional;

  /// When its photo was taken (days since birth); null: any photo, newest first.
  final ({int min, int max})? ageDays;

  /// The milestone it shows (an occasion's wire id): photos tagged with it come first.
  final String? occasion;
}

({int min, int max})? _ageWindow(Object? age) =>
    age is Map && age['min'] is num && age['max'] is num
    ? (min: (age['min'] as num).toInt(), max: (age['max'] as num).toInt())
    : null;

@immutable
class KeepsakeText {
  const KeepsakeText({
    required this.key,
    required this.defaultText,
    required this.max,
  });
  final String key;
  final Localized defaultText;
  final int max;
}

@immutable
class KeepsakePersonalField {
  const KeepsakePersonalField(
    this.key,
    this.label,
    this.type,
    this.max,
    this.required,
    this.source, [
    this.suggestion,
  ]);
  final Localized? suggestion;
  final String key, type;
  final Localized label;
  final int max;
  final bool required;
  final String? source;
}

@immutable
class KeepsakePersonalCopy {
  const KeepsakePersonalCopy(
    this.key,
    this.label,
    this.text,
    this.fallback,
    this.requires,
    this.editable,
    this.max,
  );
  final String key;
  final Localized label, text, fallback;
  final List<String> requires;
  final bool editable;
  final int max;
}

@immutable
class KeepsakePersonalization {
  const KeepsakePersonalization({
    required this.group,
    required this.fields,
    required this.copy,
    required this.beats,
    this.dateRange,
  });
  final ({String start, String end})? dateRange;
  final Localized group;
  final List<KeepsakePersonalField> fields;
  final List<KeepsakePersonalCopy> copy;
  final List<({List<int> slots, String textKey})> beats;

  static KeepsakePersonalization? fromJson(Object? j) {
    if (j is! Map) return null;
    final group = Localized.fromJson(j['group']);
    if (group == null || j['fields'] is! List || j['copy'] is! List) {
      return null;
    }
    return KeepsakePersonalization(
      group: group,
      dateRange:
          j['dateRange'] is Map &&
              (j['dateRange'] as Map)['start'] is String &&
              (j['dateRange'] as Map)['end'] is String
          ? (
              start: (j['dateRange'] as Map)['start'] as String,
              end: (j['dateRange'] as Map)['end'] as String,
            )
          : null,
      fields: [
        for (final f in j['fields'] as List)
          if (f is Map && Localized.fromJson(f['label']) != null)
            KeepsakePersonalField(
              f['key'] as String,
              Localized.fromJson(f['label'])!,
              f['type'] as String,
              (f['max'] as num).toInt(),
              f['required'] == true,
              f['source'] as String?,
              Localized.fromJson(f['suggestion']),
            ),
      ],
      copy: [
        for (final c in j['copy'] as List)
          if (c is Map && Localized.fromJson(c['text']) != null)
            KeepsakePersonalCopy(
              c['key'] as String,
              Localized.fromJson(c['label'])!,
              Localized.fromJson(c['text'])!,
              Localized.fromJson(c['fallback']) ?? const Localized('', ''),
              (c['requires'] as List? ?? []).cast<String>(),
              c['editable'] == true,
              (c['max'] as num?)?.toInt() ?? 160,
            ),
      ],
      beats: [
        for (final b in j['beats'] as List? ?? [])
          if (b is Map)
            (
              slots: (b['slots'] as List)
                  .cast<num>()
                  .map((n) => n.toInt())
                  .toList(),
              textKey: b['textKey'] as String,
            ),
      ],
    );
  }
}

@immutable
class KeepsakeTemplate {
  const KeepsakeTemplate({
    required this.id,
    required this.version,
    required this.kind,
    required this.name,
    required this.tier,
    required this.order,
    required this.palette,
    this.layouts = const {},
    this.composition,
    this.occasions = const [],
    this.ageDays,
    this.photosMin = 1,
    this.photosMax = 1,
    this.scenes = const [],
    this.texts = const [],
    this.palettes = const [],
    this.durationSec,
    this.thumb,
    this.musicAsset,
    this.defaultMusic,
    this.preview,
    this.brand,
    this.personalization,
    this.videoAssets = const {},
    this.previews = const {},
    this.thumbs = const {},
  });

  final Map<String, String> previews, thumbs;
  String? previewFor(Locale locale) =>
      previews.isEmpty ? preview : previews[locale.languageCode];
  String? thumbFor(Locale locale) => thumbs[locale.languageCode] ?? thumb;
  final Map<String, String> videoAssets;
  final KeepsakePersonalization? personalization;
  final String id;
  final int version;
  final KeepsakeKind kind;
  final Localized name;
  final KeepsakeTier tier;
  final int order;

  /// Card layers per format; the formats offered are the keys.
  final Map<KeepsakeFormat, List<KeepsakeLayer>> layouts;
  final String? composition;

  /// Occasion ids; empty: any.
  final List<String> occasions;
  final ({int min, int max})? ageDays;
  final int photosMin;
  final int photosMax;
  final List<KeepsakeScene> scenes;
  final List<KeepsakeText> texts;
  final KeepsakePalette palette;

  /// MM11 "Màu"; the first is [palette].
  final List<KeepsakePalette> palettes;
  final int? durationSec;
  final String? thumb;

  /// Videos: the track uploaded in the portal (`assets.music`), if any (Q-062).
  final String? musicAsset;

  /// Videos: the Thư viện nhạc track played unless the parent picks another (MM07).
  final String? defaultMusic;

  /// Videos: a real `.mp4` of the template made in the portal from licensed sample photos;
  /// "Xem mẫu" plays it, else the composition with sample pictures.
  final String? preview;

  /// Videos: the Child Life logo; null for templates published before it.
  final KeepsakeVideoBrand? brand;

  bool get premium => tier == KeepsakeTier.premium;
  List<KeepsakeFormat> get formats => [
    for (final f in KeepsakeFormat.values)
      if (layouts.containsKey(f)) f,
  ];

  KeepsakeText? text(String key) =>
      texts.where((t) => t.key == key).firstOrNull;

  /// Whether a layer shows [field] in [format] ("Lời nhắn" is offered only then).
  bool shows(KeepsakeFormat format, String field) =>
      (layouts[format] ?? const []).any(
        (l) => l is KeepsakeTextLayer && l.field == field,
      );

  /// Null when the document does not hold a published template this app can use.
  static KeepsakeTemplate? fromJson(Object? json) {
    if (json is! Map || json['status'] != 'published') return null;
    final id = json['id'], version = json['version'];
    final kind = KeepsakeKind.values.asNameMap()[json['kind']];
    final tier = KeepsakeTier.values.asNameMap()[json['tier']];
    final name = Localized.fromJson(json['name']);
    final palette = KeepsakePalette.fromJson(json['palette']);
    if (id is! String ||
        version is! num ||
        kind == null ||
        tier == null ||
        name == null ||
        palette == null) {
      return null;
    }
    final layouts = <KeepsakeFormat, List<KeepsakeLayer>>{};
    if (json['layouts'] case final Map raw) {
      for (final e in raw.entries) {
        final format = KeepsakeFormat.values.asNameMap()[e.key];
        if (format == null || e.value is! List) continue;
        final layers = [
          for (final l in e.value as List) ?KeepsakeLayer.fromJson(l),
        ];
        // A layer this app does not understand: skip the format rather than draw it wrong.
        if (layers.length == (e.value as List).length && layers.isNotEmpty) {
          layouts[format] = layers;
        }
      }
    }
    if (kind == KeepsakeKind.card && layouts.isEmpty) return null;
    final photos = json['photos'] is Map ? json['photos'] as Map : const {};
    final age = json['ageDays'];
    return KeepsakeTemplate(
      previews: json['previews'] is Map
          ? (json['previews'] as Map).cast<String, String>()
          : const {},
      thumbs: json['thumbs'] is Map
          ? (json['thumbs'] as Map).cast<String, String>()
          : const {},
      videoAssets: {
        if (json['assets'] is Map)
          for (final e in (json['assets'] as Map).entries)
            if (e.key is String && e.value is String && e.key != 'music')
              e.key as String: e.value as String,
      },
      personalization: KeepsakePersonalization.fromJson(
        json['personalization'],
      ),
      id: id,
      version: version.toInt(),
      kind: kind,
      name: name,
      tier: tier,
      order: (json['order'] as num?)?.toInt() ?? 0,
      layouts: layouts,
      composition: json['composition'] as String?,
      occasions: [
        for (final o in (json['occasions'] as List? ?? const []))
          if (o is String) o,
      ],
      ageDays: _ageWindow(age),
      photosMin: (photos['min'] as num?)?.toInt() ?? 1,
      photosMax: (photos['max'] as num?)?.toInt() ?? 1,
      scenes: [
        for (final sc in (json['scenes'] as List? ?? const []))
          if (sc is Map && Localized.fromJson(sc['hint']) != null)
            KeepsakeScene(
              hint: Localized.fromJson(sc['hint'])!,
              optional: sc['optional'] == true,
              ageDays: _ageWindow(sc['ageDays']),
              occasion: sc['occasion'] as String?,
            ),
      ],
      texts: [
        for (final t in (json['texts'] as List? ?? const []))
          if (t is Map &&
              t['key'] is String &&
              Localized.fromJson(t['default']) != null)
            KeepsakeText(
              key: t['key'] as String,
              defaultText: Localized.fromJson(t['default'])!,
              max: (t['max'] as num?)?.toInt() ?? 60,
            ),
      ],
      palette: palette,
      palettes: [
        for (final p in (json['palettes'] as List? ?? const []))
          ?KeepsakePalette.fromJson(p),
      ],
      durationSec: (json['durationSec'] as num?)?.toInt(),
      thumb: json['thumb'] as String?,
      musicAsset: json['assets'] is Map
          ? (json['assets'] as Map)['music'] as String?
          : null,
      defaultMusic: json['defaultMusic'] as String?,
      preview: json['preview'] as String?,
      brand: KeepsakeVideoBrand.fromJson(json['brand']),
    );
  }

  /// The photo slots [format] draws, in order (two for Then & Now).
  List<int> photoSlots(KeepsakeFormat format) => {
    for (final l in layouts[format] ?? const <KeepsakeLayer>[])
      if (l is KeepsakePhotoSlot) l.slot,
  }.toList()..sort();

  /// Every picture the card needs in [format] (loaded before export).
  List<String> assets(KeepsakeFormat format) => [
    for (final l in layouts[format] ?? const <KeepsakeLayer>[])
      if (l is KeepsakeImage)
        l.asset
      else if (l is KeepsakeBackground && l.asset != null)
        l.asset!,
  ];
}

/// One Thư viện nhạc track (licensed in the portal; only published ones reach the app).
@immutable
class KeepsakeMusic {
  const KeepsakeMusic({
    required this.id,
    required this.title,
    required this.asset,
    this.artist = '',
    this.mood = '',
    this.durationSec = 0,
    this.order = 0,
  });
  final String id;
  final Localized title;
  final String artist;
  final String mood;
  final int durationSec;
  final String asset;
  final int order;

  static KeepsakeMusic? fromJson(Object? json) {
    if (json is! Map || json['status'] != 'published') return null;
    final id = json['id'], asset = json['asset'];
    final title = Localized.fromJson(json['title']);
    if (id is! String || asset is! String || title == null) return null;
    return KeepsakeMusic(
      id: id,
      title: title,
      asset: asset,
      artist: json['artist'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// What a Cao cấp template means, set in the portal for the whole catalog (D-068 #8):
/// `everyone` (the free beta), `hidden`, or `subscribers` (shown with its badge, used only with
/// the household's `templates.premium`: MO02, Q1). The server enforces it too.
enum PremiumAccess { everyone, hidden, subscribers }

@immutable
class KeepsakeCatalog {
  const KeepsakeCatalog(
    this.templates, {
    this.premiumAccess = PremiumAccess.everyone,
    this.badges = true,
    this.music = const [],
  });
  final List<KeepsakeTemplate> templates;

  /// Thư viện nhạc, in display order.
  final List<KeepsakeMusic> music;

  KeepsakeMusic? track(String? id) =>
      id == null ? null : music.where((m) => m.id == id).firstOrNull;
  final PremiumAccess premiumAccess;

  /// "Miễn phí" / "★ Cao cấp" on the templates (MM10).
  final bool badges;

  static KeepsakeCatalog fromJson(Object? json) {
    final premium = json is Map && json['premium'] is Map
        ? json['premium'] as Map
        : const {};
    return KeepsakeCatalog(
      [
        if (json is Map)
          for (final t in (json['templates'] as List? ?? const []))
            ?KeepsakeTemplate.fromJson(t),
      ],
      // Unknown (a newer mode): treat as hidden, never as open.
      premiumAccess: switch (premium['access']) {
        null || 'everyone' => PremiumAccess.everyone,
        'subscribers' => PremiumAccess.subscribers,
        _ => PremiumAccess.hidden,
      },
      badges: premium['badges'] != false,
      music: [
        if (json is Map)
          for (final m in (json['music'] as List? ?? const []))
            ?KeepsakeMusic.fromJson(m),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  /// MM10's grid, in display order, without the Cao cấp ones when the portal hides them. In
  /// `subscribers` mode they stay listed and are gated when picked (`ensureTemplateAllowed`).
  List<KeepsakeTemplate> get cards => _of(KeepsakeKind.card);
  List<KeepsakeTemplate> get videos => _of(KeepsakeKind.video);

  List<KeepsakeTemplate> _of(KeepsakeKind kind) =>
      [
        for (final t in templates)
          if (t.kind == kind &&
              (!t.premium || premiumAccess != PremiumAccess.hidden))
            t,
      ]..sort((a, b) {
        final o = a.order.compareTo(b.order);
        return o != 0 ? o : a.id.compareTo(b.id);
      });
}

/// The published catalog (`publicConfig/keepsakes`); Firestore's offline cache keeps the last
/// one. Empty until staff publish one (MM10 then shows its empty state).
final keepsakeCatalogProvider = StreamProvider<KeepsakeCatalog>(
  (ref) => ref
      .watch(firestoreProvider)
      .doc('publicConfig/keepsakes')
      .snapshots()
      .map((s) => KeepsakeCatalog.fromJson(s.data())),
);
