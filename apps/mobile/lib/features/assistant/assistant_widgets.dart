import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_rules.dart';

/// The chat components of Figma page 568:18 (Chat/Thẻ nháp 611:7695, Chat/Mức dùng 611:7726,
/// Chat/Ô nhập 611:7763, Chat/Tin nhắn, Chat/Gợi ý nhanh, Chat/Duyệt hàng loạt, Chat/Đầu trang,
/// Chat/Nút trợ lý). Every colour is a token, so Light and Night care both work (the design has
/// no Night frames); text on the soft warm fills is `ink` (memory: ink on soft warm fills).

/// Width of assistant cards and draft cards (Figma 300 on a 375 frame).
const asCardWidth = 320.0;

/// Width of a chat bubble (Figma 276).
const asBubbleWidth = 290.0;

TextStyle _semi(BuildContext context, double size, Color color) =>
    context.cl.text.label.copyWith(
      fontSize: size,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: color,
    );

// ---------- Chat/Mức dùng ----------

/// The ring of the usage pill: the part left, drawn from the server's numbers.
class _Ring extends StatelessWidget {
  const _Ring({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 16,
    height: 16,
    child: CustomPaint(
      painter: _RingPainter(
        fraction.clamp(0, 1),
        color,
        context.cl.colors.separator,
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);
  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(1.5),
      0,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect.deflate(1.5),
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        stroke..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Chat/Mức dùng: `Gói` × `Mức` from the snapshot; text from the numbers, never the default.
class AsUsagePill extends StatelessWidget {
  const AsUsagePill({required this.view, required this.zone, super.key});
  final UsageView view;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.cl.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (fill, ink) = switch (view.level) {
      UsageLevel.ok when view.premium => (c.mintSoft, c.mintText),
      UsageLevel.ok => (c.surface2, c.ink),
      UsageLevel.near => (c.sunshineSoft, c.ink),
      UsageLevel.out => (c.errorSoft, c.error),
    };
    return Semantics(
      label: l10n.asUsageA11y(
        view.remaining,
        view.limit,
        resetDate(locale, view.usage, zone),
      ),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Ring(fraction: view.fraction, color: ink),
              const SizedBox(width: ClSpace.s2),
              Flexible(
                child: Text(
                  usagePillText(l10n, locale, view, zone),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _semi(context, 12, ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Chat/Đầu trang ----------

class AsRoundButton extends StatelessWidget {
  const AsRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: c.ink),
      ),
    );
  }
}

/// Chat/Đầu trang: back · scope chip ("Teddy · 3 tuần" / "Gia đình") · Lịch sử · Mới.
class AsChatHeader extends StatelessWidget {
  const AsChatHeader({
    required this.scopeLabel,
    required this.household,
    required this.onBack,
    required this.onScope,
    required this.onHistory,
    required this.onNew,
    super.key,
  });

  final String scopeLabel;
  final bool household;
  final VoidCallback onBack;
  final VoidCallback? onScope;
  final VoidCallback onHistory;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Row(
      children: [
        AsRoundButton(
          icon: ClIcons.back,
          label: l10n.a11yBack,
          onPressed: onBack,
        ),
        const SizedBox(width: ClSpace.s2),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClPressable(
              onPressed: onScope,
              semanticLabel: scopeLabel,
              child: Container(
                height: 40,
                padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                  border: Border.all(color: cl.colors.separator),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cl.colors.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: ClIcon(
                        household ? ClIcons.family : ClIcons.cake,
                        size: 16,
                        color: cl.colors.mintText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        scopeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _semi(context, 13.5, cl.colors.ink),
                      ),
                    ),
                    if (onScope != null) ...[
                      const SizedBox(width: 4),
                      ClIcon(
                        ClIcons.chevronDown,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: ClSpace.s2),
        AsRoundButton(
          icon: ClIcons.clock,
          label: l10n.asHistory,
          onPressed: onHistory,
        ),
        const SizedBox(width: ClSpace.s2),
        AsRoundButton(
          icon: ClIcons.edit,
          label: l10n.asNewChat,
          onPressed: onNew,
        ),
      ],
    );
  }
}

// ---------- Chat/Tin nhắn ----------

/// A message bubble: the parent's (right, mint-deep) or the assistant's (left, surface).
class AsBubble extends StatelessWidget {
  const AsBubble({
    required this.text,
    this.mine = false,
    this.status,
    this.statusIcon,
    super.key,
  });

  final String text;
  final bool mine;

  /// Under the bubble ("Chưa gửi", "Đang gửi…").
  final String? status;
  final ClIcons? statusIcon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    const r = Radius.circular(18);
    const tail = Radius.circular(6);
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: asBubbleWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? cl.colors.mintDeep : cl.colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: mine ? r : tail,
          bottomRight: mine ? tail : r,
        ),
      ),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontSize: 15,
          height: 1.4,
          color: mine ? cl.colors.onMintDeep : cl.colors.ink,
        ),
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          bubble,
          if (status != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) ...[
                  ClIcon(statusIcon!, size: 12, color: cl.colors.inkMuted),
                  const SizedBox(width: 4),
                ],
                Text(
                  status!,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Trợ lý đang đọc…" while the task is queued or processing, with "Huỷ".
class AsWorking extends StatelessWidget {
  const AsWorking({this.onCancel, super.key});
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reduce Motion: a still mark instead of the spinner.
            if (context.reduceMotion)
              ClIcon(ClIcons.clock, size: 14, color: cl.colors.inkMuted)
            else
              CupertinoActivityIndicator(color: cl.colors.inkMuted, radius: 7),
            const SizedBox(width: ClSpace.s2),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.asThinking,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            if (onCancel != null)
              ClPressable(
                onPressed: onCancel,
                semanticLabel: l10n.asCancelTask,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
                  child: Text(
                    l10n.asCancelTask,
                    style: _semi(context, 13, cl.colors.mintText),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- Chat/Gợi ý nhanh ----------

class AsChip extends StatelessWidget {
  const AsChip({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: busy ? () {} : onPressed,
      semanticLabel: label,
      selected: selected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: selected ? c.mintDeep : c.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              CupertinoActivityIndicator(color: c.mintText, radius: 6),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: _semi(context, 14, selected ? c.mintText : c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small muted note (CH05 "không trừ thêm lượt", CH23).
class AsFootnote extends StatelessWidget {
  const AsFootnote({required this.text, this.icon = ClIcons.check, super.key});
  final String text;
  final ClIcons icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClIcon(icon, size: 12, color: cl.colors.inkMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Cards ----------

enum AsTone { surface, quiet, warn, errorEdge, danger }

/// An assistant card (300 wide, radius 18, padding 14): white, quiet `surface-2`, warning
/// `sunshine-soft`, white with an error edge (CH25) or `error-soft` (CH28).
class AsCard extends StatelessWidget {
  const AsCard({
    required this.children,
    this.tone = AsTone.surface,
    this.icon,
    this.title,
    this.body,
    this.width = asCardWidth,
    super.key,
  });

  final AsTone tone;
  final ClIcons? icon;
  final String? title;
  final String? body;
  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final (fill, border, titleColor, bodyColor) = switch (tone) {
      AsTone.surface => (c.surface, null, c.ink, c.ink),
      AsTone.quiet => (c.surface2, null, c.ink, c.inkMuted),
      AsTone.warn => (c.sunshineSoft, null, c.ink, c.ink),
      AsTone.errorEdge => (c.surface, Border.all(color: c.error), c.ink, c.ink),
      AsTone.danger => (c.errorSoft, null, c.error, c.ink),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: ClIcon(icon!, size: 16, color: titleColor),
                    ),
                    const SizedBox(width: ClSpace.s2),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: cl.text.label.copyWith(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (body != null) ...[
              if (title != null) const SizedBox(height: 6),
              Text(
                body!,
                style: cl.text.label.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: bodyColor,
                ),
              ),
            ],
            if (children.isNotEmpty) ...[
              if (title != null || body != null)
                const SizedBox(height: ClSpace.s3),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

/// A pill button sized for cards (SemiBold 13, 40 tall), primary / secondary / outline.
enum AsButtonStyle { primary, secondary, outline }

class AsButton extends StatelessWidget {
  const AsButton({
    required this.label,
    required this.onPressed,
    this.style = AsButtonStyle.primary,
    this.expand = false,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AsButtonStyle style;
  final bool expand;
  final bool loading;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final (fill, ink, border) = switch (style) {
      AsButtonStyle.primary => (c.mintDeep, c.onMintDeep, null),
      AsButtonStyle.secondary => (c.surface2, c.ink, null),
      AsButtonStyle.outline => (
        c.surface,
        c.ink,
        Border.all(color: c.controlBorder),
      ),
    };
    final disabled = onPressed == null && !loading;
    return Opacity(
      opacity: disabled ? ClMotion.disabledOpacity : 1,
      child: ClPressable(
        onPressed: loading ? () {} : onPressed,
        semanticLabel: label,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: fill,
            border: border,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                CupertinoActivityIndicator(color: ink, radius: 7),
                const SizedBox(width: ClSpace.s2),
              ] else if (icon != null) ...[
                ClIcon(icon!, size: 16, color: ink),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _semi(context, 14, ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text link in a card ("Mở nhật ký nguồn", "Mở Hướng dẫn sức khoẻ").
class AsLink extends StatelessWidget {
  const AsLink({
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      minSize: const Size(0, 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: _semi(context, 13, color ?? context.cl.colors.mintText),
        ),
      ),
    ),
  );
}

// ---------- Chat/Thẻ nháp ----------

/// The icon tile of a draft kind.
(ClIcons, Color, Color) kindTile(BuildContext context, DraftKind? k) {
  final cl = context.cl;
  return switch (k) {
    DraftKind.bottle => (ClIcons.feed, cl.care.bottle.soft, cl.care.bottle.ink),
    DraftKind.breast => (ClIcons.drop, cl.care.breast.soft, cl.care.breast.ink),
    DraftKind.sleep => (ClIcons.sleep, cl.care.sleep.soft, cl.care.sleep.ink),
    DraftKind.expense => (ClIcons.grid, cl.colors.peachSoft, cl.colors.ink),
    DraftKind.reminder => (
      ClIcons.bell,
      cl.colors.mintSoft,
      cl.colors.mintText,
    ),
    DraftKind.observation => (
      ClIcons.journal,
      cl.colors.mintSoft,
      cl.colors.mintText,
    ),
    DraftKind.meal => (ClIcons.spark, cl.colors.sunshineSoft, cl.colors.ink),
    null => (ClIcons.alert, cl.colors.surface2, cl.colors.inkMuted),
  };
}

/// One card action ("Sửa", "Mở nhật ký"); the first is bold mint, the rest muted.
typedef AsCardAction = ({String label, VoidCallback? onPressed});

/// Chat/Thẻ nháp: the six states come from [state] (the enum), never from badge text.
class AsDraftCard extends StatelessWidget {
  const AsDraftCard({
    required this.state,
    required this.kind,
    required this.title,
    required this.line,
    required this.module,
    this.selected,
    this.onSelected,
    this.notes = const [],
    this.noteIsError = false,
    this.actions = const [],
    this.stateLabelOverride,
    super.key,
  });

  final DraftState state;
  final DraftKind? kind;
  final String title;
  final String line;
  final String module;

  /// Null hides the check (saved, failed, saving, viewer).
  final bool? selected;
  final ValueChanged<bool>? onSelected;
  final List<String> notes;
  final bool noteIsError;
  final List<AsCardAction> actions;

  /// "Hết hạn" for a draft past its TTL (still from the data, not free text).
  final String? stateLabelOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final (pillFill, pillInk) = switch (state) {
      DraftState.needsReview => (c.sunshineSoft, c.ink),
      DraftState.saved => (c.mintSoft, c.mintText),
      DraftState.failed => (c.errorSoft, c.error),
      _ => (c.surface2, c.inkMuted),
    };
    final border = switch (state) {
      DraftState.needsReview => Border.all(color: c.sunshine, width: 1.5),
      DraftState.failed => Border.all(color: c.error, width: 1.5),
      _ => Border.all(color: c.separator),
    };
    final (icon, tileFill, tileInk) = kindTile(context, kind);
    final label = stateLabelOverride ?? stateLabel(l10n, state);
    final card = Container(
      width: asCardWidth,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (selected != null) ...[
                _Check(checked: selected!, label: title, onChanged: onSelected),
                const SizedBox(width: 10),
              ],
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tileFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: 16, color: tileInk),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.label.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Semantics(
                label: label,
                liveRegion: state == DraftState.saving,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: pillFill,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state == DraftState.saving) ...[
                          CupertinoActivityIndicator(color: pillInk, radius: 5),
                          const SizedBox(width: 4),
                        ] else if (state == DraftState.saved) ...[
                          ClIcon(ClIcons.check, size: 11, color: pillInk),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          label,
                          style: cl.text.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: pillInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            line,
            style: cl.text.label.copyWith(
              fontSize: 14,
              height: 1.35,
              color: c.ink,
            ),
          ),
          for (final n in notes) ...[
            const SizedBox(height: 4),
            Text(
              n,
              style: cl.text.caption.copyWith(
                fontSize: 12.5,
                color: noteIsError ? c.error : c.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              ClIcon(ClIcons.cake, size: 13, color: c.inkMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  module,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.caption.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: ClSpace.s4,
              children: [
                for (final (i, a) in actions.indexed)
                  ClPressable(
                    onPressed: a.onPressed,
                    semanticLabel: a.label,
                    minSize: const Size(0, 36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        a.label,
                        style: _semi(
                          context,
                          13.5,
                          i == 0 ? c.mintText : c.inkMuted,
                        ).copyWith(fontWeight: i == 0 ? FontWeight.w700 : null),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: state == DraftState.discarded
          ? Opacity(opacity: 0.55, child: card)
          : card,
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.checked, required this.label, this.onChanged});
  final bool checked;
  final String label;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Semantics(
      checked: checked,
      label: label,
      child: ClPressable(
        onPressed: onChanged == null ? null : () => onChanged!(!checked),
        isButton: false,
        minSize: const Size(32, 32),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: checked ? c.mintDeep : c.surface,
            borderRadius: BorderRadius.circular(6),
            border: checked
                ? null
                : Border.all(color: c.controlBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: checked
              ? ClIcon(ClIcons.check, size: 14, color: c.onMintDeep)
              : null,
        ),
      ),
    );
  }
}

// ---------- Chat/Duyệt hàng loạt ----------

/// "Sẵn sàng": save the ticked drafts / discard all.
class AsBatchBar extends StatelessWidget {
  const AsBatchBar({
    required this.count,
    required this.onSave,
    required this.onDiscardAll,
    this.saving = false,
    super.key,
  });
  final int count;
  final VoidCallback? onSave;
  final VoidCallback? onDiscardAll;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.cl.colors;
    return Container(
      width: asCardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AsButton(
            label: count == 0
                ? l10n.asChooseToSave
                : l10n.asSaveSelected(count),
            expand: true,
            loading: saving,
            onPressed: count == 0 ? null : onSave,
          ),
          if (onDiscardAll != null)
            AsLink(
              label: l10n.asDiscardAll,
              onPressed: saving ? null : onDiscardAll,
              color: c.inkMuted,
            ),
        ],
      ),
    );
  }
}

/// "Một phần": counts from the server's per-item results; retry only what a retry can fix.
class AsPartialBar extends StatelessWidget {
  const AsPartialBar({
    required this.saved,
    required this.failed,
    this.onRetry,
    this.retrying = false,
    super.key,
  });
  final int saved;
  final int failed;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      width: asCardWidth,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cl.colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.asPartial(saved, saved + failed, failed),
              style: _semi(context, 14, cl.colors.ink),
            ),
          ),
          if (onRetry != null) ...[
            AsLink(
              label: l10n.asRetryFailed,
              onPressed: retrying ? null : onRetry,
            ),
            Text(
              l10n.asRetryFree,
              style: cl.text.caption.copyWith(color: cl.colors.ink),
            ),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------- CH08 read summary ----------

class AsSummaryCard extends StatelessWidget {
  const AsSummaryCard({
    required this.summary,
    required this.zone,
    required this.now,
    required this.onOpenSource,
    super.key,
  });

  final CareSummary summary;
  final String zone;
  final DateTime now;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime.tryParse(summary.date) ?? now;
    final until = summary.until;
    final day = dayLabel(
      l10n,
      locale,
      DateTime(date.year, date.month, date.day, 12).toUtc(),
      zone,
      now,
    );
    Widget row(ClIcons icon, ClCareColor tint, String title, String? sub) =>
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: 16, color: tint.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _semi(context, 14, cl.colors.ink)),
                    if (sub != null)
                      Text(
                        sub,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AsCard(
          children: [
            Text(
              until == null ? day : l10n.asSummaryMeta(day, hm(until, zone)),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            if (summary.empty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  l10n.asSummaryNone,
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
              ),
            if (summary.bottle.count > 0)
              row(
                ClIcons.feed,
                cl.care.bottle,
                l10n.asSummaryBottle(
                  summary.bottle.count,
                  mlLabel(locale, summary.bottle.amount),
                ),
                null,
              ),
            if (summary.breast.count > 0)
              row(
                ClIcons.drop,
                cl.care.breast,
                l10n.asSummaryBreast(
                  summary.breast.count,
                  summary.breast.amount,
                ),
                l10n.asSummaryBreastNote,
              ),
            if (summary.sleep.count > 0)
              row(
                ClIcons.sleep,
                cl.care.sleep,
                l10n.asSummarySleep(
                  summary.sleep.count,
                  _duration(l10n, summary.sleep.amount),
                ),
                null,
              ),
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: summary.coverage == SummaryCoverage.complete
                    ? cl.colors.surface2
                    : cl.colors.sunshineSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClIcon(
                    summary.coverage == SummaryCoverage.complete
                        ? ClIcons.check
                        : ClIcons.alert,
                    size: 14,
                    color: cl.colors.ink,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary.coverage == SummaryCoverage.complete
                          ? l10n.asSummaryComplete
                          : l10n.asSummaryPartial,
                      style: cl.text.caption.copyWith(
                        fontSize: 12.5,
                        color: cl.colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenSource != null) ...[
              const SizedBox(height: 4),
              AsLink(label: l10n.asOpenSourceLog, onPressed: onOpenSource),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ClIcon(ClIcons.check, size: 12, color: cl.colors.inkMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.asNoRecordCreated,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _duration(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.durationMinutes(minutes);
  final m = minutes % 60;
  return m == 0
      ? l10n.durationHours(minutes ~/ 60)
      : l10n.durationHoursMinutes(minutes ~/ 60, m);
}

// ---------- CH28 health support ----------

/// Free, no quota, never a paywall: the region's emergency number from the health pack (no
/// default hotline), and HL01.
class AsHealthCard extends StatelessWidget {
  const AsHealthCard({
    required this.number,
    required this.onCall,
    required this.onOpenHealth,
    super.key,
  });

  /// From the published health pack for the household's country; null → "Gọi bác sĩ của bé".
  final String? number;
  final VoidCallback onCall;
  final VoidCallback onOpenHealth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget block(
      String label,
      Color fill,
      Color ink,
      VoidCallback onTap, {
      ClIcons? icon,
    }) => ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              ClIcon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: _semi(
                  context,
                  14,
                  ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    return AsCard(
      tone: AsTone.danger,
      icon: ClIcons.alert,
      title: l10n.asHealthTitle,
      body: l10n.asHealthBody,
      children: [
        block(
          number == null ? l10n.asHealthCallDoctor : l10n.asHealthCall(number!),
          number == null ? cl.colors.surface : cl.colors.danger,
          number == null ? cl.colors.ink : cl.colors.onDanger,
          onCall,
          icon: ClIcons.phone,
        ),
        const SizedBox(height: ClSpace.s2),
        block(
          l10n.asOpenHealth,
          cl.colors.surface,
          cl.colors.ink,
          onOpenHealth,
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.asHealthFree,
          style: cl.text.caption.copyWith(
            fontSize: 11,
            color: cl.colors.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ---------- Chat/Ô nhập ----------

/// Chat/Ô nhập states: `Trống` / `Có nội dung` come from the text; `Hết lượt` and `Chỉ xem`
/// from the household's pool and the person's role.
enum ComposerMode { open, out, viewer }

class AsComposer extends StatelessWidget {
  const AsComposer({
    required this.controller,
    required this.mode,
    required this.hint,
    required this.onSend,
    this.focusNode,
    this.onCamera,
    this.sending = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ComposerMode mode;
  final String hint;
  final VoidCallback onSend;

  /// Null hides the camera (photo reading off, or a viewer).
  final VoidCallback? onCamera;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.cl.colors;
    final locked = mode == ComposerMode.out;
    final muted = mode != ComposerMode.open;
    return Container(
      color: c.cloud,
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s2,
        ClSpace.s4,
        ClSpace.s2 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.all(ClSpace.s2),
        decoration: BoxDecoration(
          color: muted ? c.surface2 : c.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.controlBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (mode != ComposerMode.viewer && (locked || onCamera != null))
              Opacity(
                opacity: locked || onCamera == null
                    ? ClMotion.disabledOpacity
                    : 1,
                child: _Circle(
                  icon: ClIcons.camera,
                  label: l10n.asAddPhoto,
                  fill: c.surface2,
                  ink: c.ink,
                  onPressed: locked ? null : onCamera,
                ),
              ),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: locked,
                  enabled: !locked,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: AssistantLimits.maxTextChars,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.cl.text.label.copyWith(
                    fontSize: 15,
                    height: 1.35,
                    color: c.ink,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: context.cl.text.label.copyWith(
                      fontSize: 15,
                      height: 1.35,
                      color: c.inkMuted,
                    ),
                  ).copyWith(counterText: ''),
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final ready = !locked && controller.text.trim().isNotEmpty;
                return Opacity(
                  opacity: locked ? ClMotion.disabledOpacity : 1,
                  child: _Circle(
                    icon: ClIcons.arrowRight,
                    label: l10n.asSend,
                    fill: ready ? c.mintDeep : c.surface2,
                    ink: ready ? c.onMintDeep : c.inkMuted,
                    busy: sending,
                    onPressed: ready && !sending ? onSend : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.icon,
    required this.label,
    required this.fill,
    required this.ink,
    required this.onPressed,
    this.busy = false,
  });
  final ClIcons icon;
  final String label;
  final Color fill;
  final Color ink;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onPressed,
    semanticLabel: label,
    minSize: const Size(40, 40),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: busy
          ? CupertinoActivityIndicator(color: ink, radius: 8)
          : ClIcon(icon, size: 20, color: ink),
    ),
  );
}

// ---------- Chat/Nút trợ lý ----------

/// The floating assistant button (628:9074), from tokens (the Figma gradient has no Night twin).
class AsFloatingButton extends StatelessWidget {
  const AsFloatingButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: l10n.asFabLabel,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cl.colors.mint, cl.colors.mintDeep],
          ),
          border: Border.all(
            color: cl.colors.surface.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: cl.isNightCare
              ? null
              : [
                  BoxShadow(
                    color: cl.colors.mintDeep.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: ClIcon(ClIcons.spark, size: 26, color: cl.colors.onMintDeep),
      ),
    );
  }
}

/// The spark tile of the assistant (CH01 card, CH02 greeting).
class AsSparkTile extends StatelessWidget {
  const AsSparkTile({this.size = 28, this.circle = false, super.key});
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.mintSoft,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: ClIcon(ClIcons.spark, size: size * 0.55, color: c.mintText),
    );
  }
}
