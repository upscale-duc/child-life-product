import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';

import '../../core/design/tokens.g.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';

/// The Premium v2 look (Figma 958:13863, Component · Gợi ý Premium, Thẻ tính năng, Chọn gói):
/// always dark with gold, in Light and Night care alike (the sheet keeps its own gradient on a
/// Light screen, E07). These are the one place its colours live.
abstract final class PremiumPalette {
  static const deep = Color(0xFF0E1716);
  static const scrim = Color(0x99000000); // Premium detail Dim, Figma 60%.
  static const deepTop = Color(0xFF13211F);
  static const sheetTop = Color(0xFF172624);
  static const sheetBottom = Color(0xFF0D1414);
  static const inlineStart = Color(0xFF172926);
  static const inlineEnd = Color(0xFF292414);
  static const cardTop = Color(0xFF293D38);
  static const cardBottom = Color(0xFF1A2624);
  static const gold = Color(0xFFE9C77B);
  static const goldLight = Color(0xFFF2D494);
  static const goldDeep = Color(0xFFD9A857);
  static const onGold = Color(0xFF1A1408);
  static const mint = Color(0xFF2CBFB3);
  static const text = Color(0xEBFFFFFF); // white 92 %
  static const textMuted = Color(0x9EFFFFFF); // white 62 %
  static const textFaint = Color(0x73FFFFFF); // white 45 %
  static const line = Color(0x1FFFFFFF); // white 12 %
  static const fill = Color(0x0DFFFFFF); // white 5 %

  /// Playfair Display (shipped for keepsakes) for the Premium headlines.
  static const serif = 'Playfair Display Keepsake';
}

/// "◆ CHILD LIFE PREMIUM".
class PremiumCrest extends StatelessWidget {
  const PremiumCrest({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Crest (1021:17688): "◆" 7 Medium, 6 apart, "CHILD LIFE PREMIUM" 9 Bold tracking 1.62.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '◆',
            style: TextStyle(
              color: PremiumPalette.gold,
              fontSize: 7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.pv2Crest,
            style: const TextStyle(
              color: PremiumPalette.gold,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.62,
            ),
          ),
        ],
      ),
    );
  }
}

/// The gold call to action. [compact]: the small pill of the inline card.
class PremiumGoldButton extends StatelessWidget {
  const PremiumGoldButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  /// Buying or verifying (P-4): a spinner beside the label, at full strength, not tappable.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: ClPressable(
        onPressed: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled || loading ? 1 : 0.5,
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 36 : 52),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? ClSpace.s3 : ClSpace.s4,
              vertical: compact ? ClSpace.s2 : ClSpace.s3,
            ),
            alignment: compact ? null : Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ClRadius.pill),
              gradient: const LinearGradient(
                colors: [PremiumPalette.goldLight, PremiumPalette.goldDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumPalette.gold.withValues(
                    alpha: compact ? .28 : .35,
                  ),
                  blurRadius: compact ? 8 : 18,
                  offset: Offset(0, compact ? 4 : 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  const CupertinoActivityIndicator(
                    color: PremiumPalette.onGold,
                    radius: 9,
                  ),
                  const SizedBox(width: ClSpace.s2),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PremiumPalette.onGold,
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      fontSize: compact ? 13 : 16,
                      height: 1.25,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet text button on the dark surfaces.
class PremiumTextButton extends StatelessWidget {
  const PremiumTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onPressed,
    semanticLabel: label,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xBFFFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// What a suggestion sheet ended with.
enum PremiumSuggestionChoice { primary, secondary, dismissed }

/// Component · Gợi ý Premium · Sheet (990:15657): crest, headline, one line of why, the gold
/// action and a way out that keeps the user's work. The caller decides where each goes.
Future<PremiumSuggestionChoice> showPremiumSuggestion(
  BuildContext context, {
  required String title,
  required String body,
  String? primary,
  String? secondary,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showModalBottomSheet<PremiumSuggestionChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheet) => PremiumSuggestionSheet(
      title: title,
      body: body,
      primary: primary ?? l10n.pv2SeePremium,
      secondary: secondary,
      onPrimary: () => Navigator.of(sheet).pop(PremiumSuggestionChoice.primary),
      onSecondary: () =>
          Navigator.of(sheet).pop(PremiumSuggestionChoice.secondary),
    ),
  );
  return choice ?? PremiumSuggestionChoice.dismissed;
}

/// The CTA before in-app purchase is open (owner, 2026-10-25): the paywall is complete, only
/// the store step waits for the App Store / Google Play account.
Future<void> showPaymentSoon(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showPremiumSuggestion(
    context,
    title: l10n.pv2PaySoonTitle,
    body: l10n.pv2PaySoonBody,
    primary: l10n.pv2GotIt,
  );
}

class PremiumSuggestionSheet extends StatelessWidget {
  const PremiumSuggestionSheet({
    required this.title,
    required this.body,
    required this.primary,
    required this.onPrimary,
    required this.onSecondary,
    this.secondary,
    super.key,
  });

  final String title;
  final String body;
  final String primary;
  final String? secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s6,
        ClSpace.s3,
        ClSpace.s6,
        bottom + ClSpace.s6,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: PremiumPalette.gold.withValues(alpha: 0.3)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PremiumPalette.sheetTop, PremiumPalette.sheetBottom],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: PremiumPalette.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          const PremiumCrest(),
          const SizedBox(height: ClSpace.s2),
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: PremiumPalette.serif,
                color: PremiumPalette.text,
                fontSize: 23,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            body,
            style: const TextStyle(
              color: PremiumPalette.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          PremiumGoldButton(label: primary, onPressed: onPrimary),
          if (secondary case final s?) ...[
            const SizedBox(height: ClSpace.s2),
            PremiumTextButton(label: s, onPressed: onSecondary),
          ],
        ],
      ),
    );
  }
}

/// Component · Gợi ý Premium · Inline (990:15668): a dark card inside a Light screen (E08,
/// E09, E13), with the gold pill and an optional quiet link.
class PremiumInlineCard extends StatelessWidget {
  const PremiumInlineCard({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.secondary,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumPalette.gold.withValues(alpha: 0.4)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PremiumPalette.inlineStart, PremiumPalette.inlineEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumCrest(),
          const SizedBox(height: ClSpace.s2),
          Text(
            title,
            style: const TextStyle(
              color: PremiumPalette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            body,
            style: const TextStyle(
              color: PremiumPalette.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Wrap(
            spacing: ClSpace.s3,
            runSpacing: ClSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PremiumGoldButton(
                label: '$action ›',
                compact: true,
                onPressed: onAction,
              ),
              if (secondary case final s?)
                ClPressable(
                  onPressed: onSecondary,
                  semanticLabel: s,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: Color(0xBFFFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "599.000đ" (vi, VND) / "$49.99" (international): the config's prices, never the store's
/// localized string (in-app purchase comes later).
String premiumPrice(BuildContext context, num value, {required bool vnd}) {
  if (vnd) {
    final s = value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$sđ';
  }
  return '\$${value.toStringAsFixed(2)}';
}

/// "1 GB", "6,2 GB" (vi decimal comma) / "6.2 GB".
String premiumGb(BuildContext context, int bytes) {
  final gb = bytes / (1024 * 1024 * 1024);
  final vi = Localizations.localeOf(context).languageCode == 'vi';
  final s = gb >= 10 || gb == gb.roundToDouble()
      ? gb.toStringAsFixed(gb == gb.roundToDouble() ? 0 : 1)
      : gb.toStringAsFixed(1);
  return '${vi ? s.replaceAll('.', ',') : s} GB';
}

/// Premium details retain the shared sheet route (motion, drag, keyboard and safe areas),
/// with Night care's dark surface around the feature's dark illustration and live text.
Future<T?> showPremiumDetails<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => Navigator.of(context, rootNavigator: true).push<T>(
  ClSheetRoute<T>(
    builder: builder,
    customSurface: true,
    scrimColor: PremiumPalette.scrim,
    dismissible: true,
    nightCare: context.cl.isNightCare,
    reduceMotion: context.reduceMotion,
    theme: buildClTheme(ClPalette.nightCare),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ),
);
