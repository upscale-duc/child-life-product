import 'package:flutter/painting.dart';

import 'tokens.g.dart';

/// Figma text styles (18:351). Colour defaults to ink; callers override per token.
class ClTypography {
  ClTypography(Color ink)
    : display = _style(ClTextSpecs.display, ink),
      largeTitle = _style(ClTextSpecs.largeTitle, ink),
      title = _style(ClTextSpecs.title, ink),
      title2 = _style(ClTextSpecs.title2, ink),
      headline = _style(ClTextSpecs.headline, ink),
      body = _style(ClTextSpecs.body, ink),
      bodyStrong = _style(ClTextSpecs.bodyStrong, ink),
      label = _style(ClTextSpecs.label, ink),
      caption = _style(ClTextSpecs.caption, ink),
      numeralXl = _style(ClTextSpecs.numeralXl, ink),
      numeral = _style(ClTextSpecs.numeral, ink);

  final TextStyle display;
  final TextStyle largeTitle;
  final TextStyle title;
  final TextStyle title2;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle numeralXl;
  final TextStyle numeral;

  static TextStyle _style(ClTextSpec spec, Color color) => TextStyle(
    fontFamily: ClTextSpecs.family,
    fontSize: spec.size,
    height: spec.lineHeight / spec.size,
    fontWeight: FontWeight.values.firstWhere((w) => w.value == spec.weight),
    letterSpacing: spec.letterSpacing,
    leadingDistribution: TextLeadingDistribution.even,
    color: color,
    // Be Vietnam Pro ships no `tnum` feature; ClTabularText keeps digits steady (P-064).
    fontFeatures: spec.tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
