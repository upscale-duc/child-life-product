import 'package:flutter/widgets.dart';

/// Renders text with equal-width digits so timers and numerals don't jitter.
///
/// Figma requires tabular figures (18:353), but the shipped Be Vietnam Pro has no `tnum`
/// feature (P-064), so each digit is laid out in a box as wide as the widest digit.
class ClTabularText extends StatelessWidget {
  const ClTabularText(
    this.text, {
    required this.style,
    this.semanticsLabel,
    super.key,
  });

  final String text;
  final TextStyle style;
  final String? semanticsLabel;

  static final Map<TextStyle, double> _digitWidthCache = {};

  static double digitWidth(TextStyle style, TextScaler scaler) {
    final key = style.copyWith(fontSize: scaler.scale(style.fontSize ?? 14));
    return _digitWidthCache.putIfAbsent(key, () {
      var widest = 0.0;
      for (var d = 0; d <= 9; d++) {
        final painter = TextPainter(
          text: TextSpan(text: '$d', style: key),
          textDirection: TextDirection.ltr,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      return widest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final width = digitWidth(style, scaler);
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (final char in text.characters)
            if (RegExp(r'\d').hasMatch(char))
              SizedBox(
                width: width,
                child: Text(char, style: style, textAlign: TextAlign.center),
              )
            else
              Text(char, style: style),
        ],
      ),
    );
  }
}
