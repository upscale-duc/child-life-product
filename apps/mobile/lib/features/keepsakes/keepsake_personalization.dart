import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'keepsake_catalog.dart';
import 'keepsake_card_view.dart';

/// Mirrors resolveKeepsakeCopy. Missing metadata removes a line, never invents a date.
Map<String, String> resolveKeepsakeCopy(
  KeepsakePersonalization spec,
  Map<String, String> values,
  Locale locale, [
  Map<String, String> overrides = const {},
]) {
  var elapsedDays = '';
  if (spec.dateRange case final range?) {
    final start = DateTime.tryParse(values[range.start] ?? '');
    final end = DateTime.tryParse(values[range.end] ?? '');
    if (start != null && end != null) {
      final days = DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      if (days >= 0) elapsedDays = '$days';
    }
  }
  String value(String key) {
    if (key == 'elapsedDays') return elapsedDays;
    if (key == 'elapsedUnit') {
      return elapsedDays.isEmpty
          ? ''
          : locale.languageCode == 'vi'
          ? 'ngày'
          : elapsedDays == '1'
          ? 'day'
          : 'days';
    }
    final raw = values[key]?.trim() ?? '';
    final field = spec.fields.where((f) => f.key == key).firstOrNull;
    if (field?.type == 'month' && raw.isNotEmpty) return raw.padLeft(2, '0');
    if (raw.isEmpty || field?.type != 'date') return raw;
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    return DateFormat(
      locale.languageCode == 'vi' ? 'd MMMM, yyyy' : 'd MMMM yyyy',
      locale.languageCode,
    ).format(date);
  }

  return {
    for (final c in spec.copy)
      c.key:
          overrides[c.key] ??
          (c.requires.every((key) {
                    final f = spec.fields
                        .where((f) => f.key == key)
                        .firstOrNull;
                    final raw = key == 'elapsedDays'
                        ? elapsedDays
                        : key == 'elapsedUnit'
                        ? value(key)
                        : values[key]?.trim() ?? '';
                    return raw.isNotEmpty &&
                        (f?.type != 'confirmation' || raw == 'true');
                  })
                  ? c.text.of(locale)
                  : c.fallback.of(locale))
              .replaceAllMapped(RegExp(r'\{([^}]+)\}'), (m) => value(m[1]!)),
  };
}

const premiumFontFamilies = {
  'beVietnamPro': 'Be Vietnam Pro Keepsake',
  'lora': 'Lora',
};

/// Bounded reduction only. The same measurement gates export and draws the card.
({double size, bool fits}) premiumTextFit(
  String value,
  KeepsakeTextLayer l,
  Size size,
) {
  final rect = l.rect.scale(size);
  final base = l.size * size.width;
  var candidate = base;
  for (var step = 0; step <= 4; step++) {
    final minimum =
        (l.font == 'lora'
            ? 64
            : l.size >= 0.032
            ? 36
            : 28) *
        size.width /
        1080;
    candidate = (base * (1 - step * 0.05)).clamp(
      minimum > base ? base : minimum,
      base,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: premiumFontFamilies[l.font] ?? 'Be Vietnam Pro Keepsake',
          fontWeight: FontWeight.values[(l.weight ~/ 100 - 1).clamp(0, 8)],
          fontSize: candidate,
          height: 1.25,
          letterSpacing: l.letterSpacing * candidate,
        ),
      ),
      maxLines: l.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    final fits =
        !painter.didExceedMaxLines && painter.height <= rect.height + 0.01;
    painter.dispose();
    if (fits) return (size: candidate, fits: true);
  }
  return (size: candidate, fits: false);
}

/// Optional metadata columns reflow to the available width when date/time/place are omitted.
List<KeepsakeLayer> premiumCardLayers(
  KeepsakeTemplate template,
  KeepsakeFormat format,
  CardContent content,
) {
  final layers = (template.layouts[format] ?? const <KeepsakeLayer>[])
      .where(
        (l) =>
            l is! KeepsakeImage ||
            l.when == null ||
            content.field(l.when!.field) == l.when!.equals,
      )
      .toList();
  if (template.personalization == null) return layers;
  final labels = layers
      .whereType<KeepsakeTextLayer>()
      .where((l) => RegExp(r'^label[0-2]$').hasMatch(l.field))
      .toList();
  if (labels.length < 2 ||
      labels.any((l) => (l.rect.y - labels.first.rect.y).abs() > 0.001)) {
    return layers;
  }
  final visible = labels
      .where(
        (l) =>
            content.field(l.field.replaceFirst('label', 'detail')).isNotEmpty,
      )
      .toList();
  if (visible.isEmpty) return layers;
  final start = labels.map((l) => l.rect.x).reduce((a, b) => a < b ? a : b);
  final end = labels
      .map((l) => l.rect.x + l.rect.w)
      .reduce((a, b) => a > b ? a : b);
  return [
    for (final layer in layers)
      if (layer is KeepsakeTextLayer &&
          RegExp(r'^(label|detail)[0-2]$').hasMatch(layer.field) &&
          content.field(layer.field).isNotEmpty)
        layer.withRect(
          KeepsakeRect(
            start +
                visible.indexWhere(
                      (l) => l.field.endsWith(
                        layer.field.substring(layer.field.length - 1),
                      ),
                    ) *
                    (end - start) /
                    visible.length,
            layer.rect.y,
            (end - start) / visible.length - 0.02,
            layer.rect.h,
          ),
        )
      else
        layer,
  ];
}

bool premiumCardFits(
  KeepsakeTemplate template,
  KeepsakeFormat format,
  CardContent content,
) {
  const width = 1080.0;
  final size = Size(width, width / format.aspect);
  return premiumCardLayers(
    template,
    format,
    content,
  ).whereType<KeepsakeTextLayer>().every((l) {
    final text = content.field(l.field);
    return text.isEmpty ||
        premiumTextFit(l.caps ? text.toUpperCase() : text, l, size).fits;
  });
}

bool premiumVideoTextFits(String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        fontSize: 36,
        height: 1.25,
      ),
    ),
    maxLines: 2,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 888);
  final fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}

/// Metadata shares one line below the main caption, above the video safe-area boundary.
bool premiumVideoMetadataFits(String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'Be Vietnam Pro Keepsake',
        fontSize: 28,
        height: 1.3,
      ),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 888);
  final fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}

/// Small fixed note labels in V05; reject long copy before preview/export instead of clipping.
bool premiumVideoNoteFits(String text) {
  for (final word in text.split(RegExp(r'\s+'))) {
    final wordPainter = TextPainter(
      text: TextSpan(
        text: word,
        style: const TextStyle(
          fontFamily: 'Be Vietnam Pro Keepsake',
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final tooWide = wordPainter.width > 208;
    wordPainter.dispose();
    if (tooWide) return false;
  }

  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'Be Vietnam Pro Keepsake',
        fontSize: 28,
        height: 1.3,
      ),
    ),
    maxLines: 2,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 208);
  final fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}
