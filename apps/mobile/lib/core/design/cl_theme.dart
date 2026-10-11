import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cl_typography.dart';
import 'page_transitions.dart';
import 'tokens.g.dart';

/// Light = brand look; Night care = palette for night feeds, not a brand look (Figma 18:4).
enum ClPalette { light, nightCare }

/// Child Life design tokens available from any BuildContext: `context.cl.colors.mintDeep`.
@immutable
class ClTheme extends ThemeExtension<ClTheme> {
  const ClTheme({
    required this.palette,
    required this.colors,
    required this.care,
    required this.shadows,
    required this.text,
  });

  factory ClTheme.of(ClPalette palette) {
    final colors = palette == ClPalette.light ? lightColors : nightCareColors;
    return ClTheme(
      palette: palette,
      colors: colors,
      care: palette == ClPalette.light ? lightCareColors : nightCareCareColors,
      shadows: palette == ClPalette.light ? lightShadows : nightCareShadows,
      text: ClTypography(colors.ink),
    );
  }

  final ClPalette palette;
  final ClColors colors;
  final ClCareColors care;
  final ClShadows shadows;
  final ClTypography text;

  bool get isNightCare => palette == ClPalette.nightCare;

  @override
  ClTheme copyWith({ClPalette? palette}) =>
      palette == null ? this : ClTheme.of(palette);

  /// Colours, care tints and shadows blend over the theme animation, so Light ↔ Night care
  /// fades smoothly; behaviour that depends on the palette ([isNightCare]) flips halfway.
  @override
  ClTheme lerp(ClTheme? other, double t) {
    if (other == null || identical(this, other)) return this;
    if (t <= 0) return this;
    if (t >= 1) return other;
    final colors = ClColors.lerp(this.colors, other.colors, t);
    return ClTheme(
      palette: t < 0.5 ? palette : other.palette,
      colors: colors,
      care: ClCareColors.lerp(care, other.care, t),
      shadows: ClShadows.lerp(shadows, other.shadows, t),
      text: ClTypography(colors.ink),
    );
  }
}

extension ClThemeContext on BuildContext {
  ClTheme get cl => Theme.of(this).extension<ClTheme>()!;
}

ThemeData buildClTheme(ClPalette palette) {
  final cl = ClTheme.of(palette);
  final c = cl.colors;
  final t = cl.text;
  final brightness = palette == ClPalette.light
      ? Brightness.light
      : Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: ClTextSpecs.family,
    scaffoldBackgroundColor: c.cloud,
    canvasColor: c.cloud,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.mintDeep,
      onPrimary: c.onMintDeep,
      secondary: c.mint,
      onSecondary: c.onMintDeep,
      error: c.error,
      onError: c.surface,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerHighest: c.surface2,
      onSurfaceVariant: c.inkMuted,
      outline: c.controlBorder,
      outlineVariant: c.separator,
      scrim: c.scrim,
    ),
    textTheme: TextTheme(
      displayLarge: t.display,
      headlineLarge: t.largeTitle,
      headlineMedium: t.title,
      titleLarge: t.title2,
      titleMedium: t.headline,
      bodyLarge: t.body,
      bodyMedium: t.body,
      labelLarge: t.bodyStrong,
      labelMedium: t.label,
      bodySmall: t.caption,
    ),
    dividerTheme: DividerThemeData(color: c.separator, thickness: 1, space: 1),
    focusColor: c.focusRing,
    // Platform-default screen transitions (D-013); fade under Reduce Motion.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: ClPageTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.android: ClPageTransitionsBuilder(
          PredictiveBackPageTransitionsBuilder(),
        ),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      primaryColor: c.mintDeep,
      brightness: brightness,
    ),
    extensions: [cl],
  );
}
