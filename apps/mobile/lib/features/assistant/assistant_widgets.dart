import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_rules.dart';
import 'assistant_voice.dart';
import 'lumi_button.dart' show LumiMascot;

export 'lumi_button.dart'
    show AsFloatingButton, AsFloatingButtonState, LumiMascot;

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

// ---------- Chat/Mức dùng (top-bar icon) ----------

/// The usage glyph of the chat top bar (D-076 #12: the credits pill 612:7737 is gone, "Chi tiết"
/// 612:7741 becomes this icon): a meter in the line-icon style, no numbers.
class _GaugeGlyph extends StatelessWidget {
  const _GaugeGlyph({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: _GaugePainter(color)),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..color = color;
    final c = Offset(12 * s, 14 * s);
    // A 240° dial open at the bottom, and a needle to the upper right.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 8.5 * s),
      math.pi * 5 / 6,
      math.pi * 4 / 3,
      false,
      stroke,
    );
    canvas.drawLine(c, c + Offset(4.2 * s, -4.2 * s), stroke);
    canvas.drawCircle(c, 1.4 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.color != color;
}

// ---------- Chat/Đầu trang ----------

class AsRoundButton extends StatelessWidget {
  const AsRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.tooltip = false,
    this.size = 40,
    super.key,
  });
  final ClIcons icon;

  /// The circle (the tap area stays 44 through [ClPressable]).
  final double size;
  final String label;
  final VoidCallback? onPressed;

  /// Drawn instead of [icon] (the usage meter has no SVG of its own).
  final Widget? glyph;

  /// Long-press shows [label] too (a glyph not every person reads at once).
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final button = ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: glyph ?? ClIcon(icon, size: size / 2, color: c.ink),
      ),
    );
    return tooltip
        ? Tooltip(message: label, excludeFromSemantics: true, child: button)
        : button;
  }
}

/// Chat/Đầu trang (612:7715), reworked 2026-10-15: back · Lumi (face, name and the baby chip
/// "Teddy · 3 tuần ▾" / "Gia đình", with "Chỉ bạn thấy" where the chat is private to the
/// person) · Mức dùng · Lịch sử · Mới. Mức dùng replaces the credits pill and its "Chi tiết"
/// link (D-076 #12): the numbers stay in CH19 and in the quote before a task.
class AsChatHeader extends StatelessWidget {
  const AsChatHeader({
    required this.scopeLabel,
    required this.household,
    required this.onBack,
    required this.onScope,
    required this.onHistory,
    required this.onNew,
    this.onUsage,
    this.privateHint = false,
    super.key,
  });

  final String scopeLabel;
  final bool household;
  final VoidCallback onBack;
  final VoidCallback? onScope;
  final VoidCallback onHistory;
  final VoidCallback onNew;

  /// Opens CH19; no button without it.
  final VoidCallback? onUsage;

  /// "Chỉ bạn thấy" under the name (household / spending: never in the shared thread).
  final bool privateHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (household) ...[
          ClIcon(ClIcons.family, size: 13, color: c.mintText),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            scopeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _semi(context, 12.5, c.mintText),
          ),
        ),
        if (onScope != null) ...[
          const SizedBox(width: 2),
          ClIcon(ClIcons.chevronDown, size: 13, color: c.mintText),
        ],
        // The words "Chỉ bạn thấy" are in the semantics label and on the spending cards; the
        // header keeps the lock (room for the baby chip and three buttons at 375 pt).
        if (privateHint) ...[
          const SizedBox(width: 6),
          ClIcon(ClIcons.lock, size: 12, color: c.inkMuted),
        ],
      ],
    );
    return Row(
      children: [
        AsRoundButton(
          icon: ClIcons.back,
          label: l10n.a11yBack,
          onPressed: onBack,
        ),
        const SizedBox(width: ClSpace.s2),
        Expanded(
          child: ClPressable(
            onPressed: onScope,
            semanticLabel: [
              l10n.asLumiName,
              scopeLabel,
              if (privateHint) l10n.asOnlyYou,
            ].join(', '),
            child: Row(
              children: [
                const LumiMascot(size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.asLumiName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _semi(
                          context,
                          16,
                          c.ink,
                        ).copyWith(fontWeight: FontWeight.w700, height: 1.2),
                      ),
                      const SizedBox(height: 1),
                      chip,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onUsage != null) ...[
          const SizedBox(width: 4),
          AsRoundButton(
            key: const ValueKey('as.usage'),
            icon: ClIcons.sliders,
            glyph: _GaugeGlyph(color: c.ink),
            label: l10n.asUsageButton,
            tooltip: true,
            size: 36,
            onPressed: onUsage,
          ),
        ],
        const SizedBox(width: 4),
        AsRoundButton(
          icon: ClIcons.clock,
          label: l10n.asHistory,
          size: 36,
          onPressed: onHistory,
        ),
        const SizedBox(width: 4),
        AsRoundButton(
          icon: ClIcons.edit,
          label: l10n.asNewChat,
          size: 36,
          onPressed: onNew,
        ),
      ],
    );
  }
}

// ---------- Chat/Tin nhắn ----------

/// Where a sent message stands (shown under my bubble).
enum AsSendState { sending, unsent, failed }

/// A message bubble: mine (right, mint-deep), Lumi's (left, surface) or another member's in
/// the shared thread (left, surface-2, their label above; D-075 #2). A tap shows its time, a
/// long press copies the words; my bubble carries its send state with an inline action.
class AsBubble extends StatefulWidget {
  const AsBubble({
    required this.text,
    this.mine = false,
    this.status,
    this.statusIcon,
    this.author,
    this.sendState,
    this.action,
    this.time,
    this.live = false,
    super.key,
  });

  final String text;
  final bool mine;

  /// Another member's message: who wrote it ("Mẹ", "Cô Lan").
  final String? author;

  /// Under the bubble ("Chưa gửi", "Đang gửi…").
  final String? status;
  final ClIcons? statusIcon;

  /// Colours the status line (failed reads as an error, sending as muted).
  final AsSendState? sendState;

  /// An inline action after the status ("Thử lại", "Gửi").
  final AsCardAction? action;

  /// "14:20", shown on a tap (null: no time to show).
  final String? time;

  /// A new message from Lumi: screen readers read it out once.
  final bool live;

  @override
  State<AsBubble> createState() => _AsBubbleState();
}

class _AsBubbleState extends State<AsBubble> {
  var _showTime = false;

  void _copy() {
    final l10n = AppLocalizations.of(context);
    unawaited(Clipboard.setData(ClipboardData(text: widget.text)));
    if (!context.cl.isNightCare) unawaited(HapticFeedback.selectionClick());
    ClToaster.of(context).show(message: l10n.asCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    const r = Radius.circular(18);
    const tail = Radius.circular(6);
    final mine = widget.mine;
    final other = !mine && widget.author != null;
    final failed = widget.sendState == AsSendState.failed;
    final bubble = AnimatedOpacity(
      opacity: widget.sendState == AsSendState.sending ? 0.75 : 1,
      duration: context.motion(ClMotion.quick),
      child: Container(
        constraints: const BoxConstraints(maxWidth: asBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? cl.colors.mintDeep
              : (other ? cl.colors.surface2 : cl.colors.surface),
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: mine ? r : tail,
            bottomRight: mine ? tail : r,
          ),
        ),
        child: Text(
          widget.text,
          style: cl.text.label.copyWith(
            fontSize: 15,
            height: 1.4,
            color: mine ? cl.colors.onMintDeep : cl.colors.ink,
          ),
        ),
      ),
    );
    final who = mine ? l10n.asYou : (widget.author ?? l10n.asLumiName);
    final statusColor = failed ? cl.colors.error : cl.colors.inkMuted;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (other) ...[
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                widget.author!,
                style: _semi(context, 12, cl.colors.inkMuted),
              ),
            ),
            const SizedBox(height: 3),
          ],
          Semantics(
            container: true,
            liveRegion: widget.live,
            label: '$who: ${widget.text}',
            onLongPressHint: l10n.asCopy,
            onLongPress: _copy,
            onTapHint: widget.time == null ? null : l10n.asShowTime,
            onTap: widget.time == null
                ? null
                : () => setState(() => _showTime = !_showTime),
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.time == null
                    ? null
                    : () => setState(() => _showTime = !_showTime),
                onLongPress: _copy,
                child: bubble,
              ),
            ),
          ),
          AsSize(
            duration: context.motion(ClMotion.quick),
            curve: ClCurves.quick,
            alignment: mine ? Alignment.topRight : Alignment.topLeft,
            child: _showTime && widget.time != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                    child: Text(
                      widget.time!,
                      style: cl.text.caption.copyWith(
                        fontSize: 11.5,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
          ),
          if (widget.status != null) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: mine ? WrapAlignment.end : WrapAlignment.start,
                spacing: 4,
                children: [
                  if (widget.statusIcon != null)
                    ClIcon(widget.statusIcon!, size: 12, color: statusColor),
                  Text(
                    widget.status!,
                    style: cl.text.caption.copyWith(color: statusColor),
                  ),
                  if (widget.action case final a?)
                    ClPressable(
                      onPressed: a.onPressed,
                      semanticLabel: a.label,
                      minSize: const Size(0, 32),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          a.label,
                          style: _semi(context, 12.5, cl.colors.mintText),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The first entry of a run of Lumi's messages: her face and name (and the time on demand).
class AsLumiHeader extends StatelessWidget {
  const AsLumiHeader({this.time, super.key});
  final String? time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const LumiMascot(size: 22),
            const SizedBox(width: 8),
            Text(l10n.asLumiName, style: _semi(context, 13, cl.colors.ink)),
            if (time != null) ...[
              const SizedBox(width: 6),
              Text(
                time!,
                style: cl.text.caption.copyWith(
                  fontSize: 11.5,
                  color: cl.colors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Lumi đang soạn…": her face and a bubble of three dots that rise in turn (still dots with
/// Reduce Motion), read out once; "Huỷ" for the task's author.
class AsTyping extends StatefulWidget {
  const AsTyping({required this.label, this.onCancel, super.key});
  final String label;
  final VoidCallback? onCancel;

  @override
  State<AsTyping> createState() => _AsTypingState();
}

class _AsTypingState extends State<AsTyping>
    with SingleTickerProviderStateMixin {
  late final _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _dots.stop();
    } else if (!_dots.isAnimating) {
      unawaited(_dots.repeat());
    }
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final reduce = context.reduceMotion;
    Widget dot(int i) => AnimatedBuilder(
      animation: _dots,
      builder: (context, _) {
        // Each dot rises and brightens in its third of the loop.
        final t = reduce ? 0.0 : ((_dots.value * 3 - i) % 3);
        final up = t < 1 ? math.sin(math.pi * t) : 0.0;
        return Transform.translate(
          offset: Offset(0, -3 * up),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c.inkMuted.withValues(alpha: 0.45 + 0.55 * up),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const LumiMascot(size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        dot(0),
                        const SizedBox(width: 4),
                        dot(1),
                        const SizedBox(width: 4),
                        dot(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.label,
                        style: cl.text.label.copyWith(
                          fontSize: 13.5,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onCancel != null)
            ClPressable(
              onPressed: widget.onCancel,
              semanticLabel: l10n.asCancelTask,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
                child: Text(
                  l10n.asCancelTask,
                  style: _semi(context, 13, c.mintText),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry of the thread arriving: a fade with a short rise (Motion spec: quick, 8 px, 30 ms
/// stagger); with Reduce Motion a quick fade only, and Night care without the spring. [animate]
/// false shows it at once (history, an entry seen before).
class AsEnter extends StatefulWidget {
  const AsEnter({
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
    this.fromRight = false,
    super.key,
  });
  final Widget child;
  final bool animate;
  final Duration delay;

  /// My own bubble rises from the right a little.
  final bool fromRight;

  @override
  State<AsEnter> createState() => _AsEnterState();
}

class _AsEnterState extends State<AsEnter> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null || !widget.animate) return;
    final reduce = context.reduceMotion;
    final night = context.cl.isNightCare;
    final c = AnimationController(
      vsync: this,
      duration: reduce
          ? const Duration(milliseconds: 150)
          : (night ? ClMotion.quick : ClMotion.standard),
    );
    _c = c;
    final delay = reduce ? Duration.zero : widget.delay;
    if (delay == Duration.zero) {
      unawaited(c.forward());
    } else {
      _wait = Timer(delay, () {
        if (mounted) unawaited(c.forward());
      });
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    final reduce = context.reduceMotion;
    final night = context.cl.isNightCare;
    final fade = CurvedAnimation(parent: c, curve: ClCurves.quick);
    if (reduce) return FadeTransition(opacity: fade, child: widget.child);
    final move = CurvedAnimation(
      parent: c,
      curve: night ? ClCurves.quick : ClCurves.standard,
    );
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: move,
        child: widget.child,
        builder: (context, child) {
          final t = 1 - move.value;
          return Transform.translate(
            offset: Offset(
              widget.fromRight ? ClMotion.shiftChip * t : 0,
              ClMotion.shiftChip * t,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// [AnimatedSize] that is a plain box with Reduce Motion (a zero-length size animation would
/// re-dirty its own layout).
class AsSize extends StatelessWidget {
  const AsSize({
    required this.child,
    required this.duration,
    this.curve = Curves.linear,
    this.alignment = Alignment.center,
    super.key,
  });
  final Widget child;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) =>
      context.reduceMotion || duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration,
          curve: curve,
          alignment: alignment,
          child: child,
        );
}

/// "↓ Tin mới": new content arrived below while the person reads further up.
class AsNewPill extends StatelessWidget {
  const AsNewPill({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: l10n.asNewMessages,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.mintDeep,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          boxShadow: context.cl.shadows.sheet,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: math.pi / 2,
              child: ClIcon(ClIcons.arrowRight, size: 14, color: c.onMintDeep),
            ),
            const SizedBox(width: 6),
            Text(l10n.asNewMessages, style: _semi(context, 13, c.onMintDeep)),
          ],
        ),
      ),
    );
  }
}

/// The offline line under the header: what still works while there is no network.
class AsOfflineBanner extends StatelessWidget {
  const AsOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: ClIcon(ClIcons.cloudOff, size: 14, color: cl.colors.ink),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.asOfflineBanner,
                style: cl.text.caption.copyWith(color: cl.colors.ink),
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
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool busy;
  final ClIcons? icon;

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
            ] else if (icon != null) ...[
              ClIcon(
                icon!,
                size: 14,
                color: selected ? c.mintText : c.inkMuted,
              ),
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
    widthFactor: 1,
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
    this.tile,
    this.onTap,
    this.privateHint,
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

  /// The icon tile when the kind's own does not fit (CH17 feedback: heart on mint).
  final (ClIcons, Color, Color)? tile;

  /// A tap on the card's facts opens its editor (same as "Sửa").
  final VoidCallback? onTap;

  /// "Chỉ bạn thấy" next to the module (spending stays out of the shared thread).
  final String? privateHint;

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
    final (icon, tileFill, tileInk) = tile ?? kindTile(context, kind);
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
          if (onTap == null)
            Text(
              line,
              style: cl.text.label.copyWith(
                fontSize: 14,
                height: 1.35,
                color: c.ink,
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      line,
                      style: cl.text.label.copyWith(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ClIcon(ClIcons.edit, size: 14, color: c.inkMuted),
                  ),
                ],
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
              if (privateHint != null) ...[
                const SizedBox(width: 6),
                ClIcon(ClIcons.lock, size: 11, color: c.inkMuted),
                const SizedBox(width: 3),
                Text(
                  privateHint!,
                  style: cl.text.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: ClSpace.s4,
              children: [
                for (final (i, a) in actions.indexed)
                  Opacity(
                    opacity: a.onPressed == null ? ClMotion.disabledOpacity : 1,
                    child: ClPressable(
                      onPressed: a.onPressed,
                      semanticLabel: a.label,
                      minSize: const Size(0, 36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          a.label,
                          style:
                              _semi(
                                context,
                                13.5,
                                i == 0 ? c.mintText : c.inkMuted,
                              ).copyWith(
                                fontWeight: i == 0 ? FontWeight.w700 : null,
                              ),
                        ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: asCardWidth),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ClSpace.s3,
        runSpacing: 4,
        children: [
          AsButton(
            label: count == 0
                ? l10n.asChooseToSave
                : l10n.asSaveSelected(count),
            icon: count == 0 ? null : ClIcons.check,
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
    this.bottleFeeds,
    this.breastFeeds,
    super.key,
  });

  final CareSummary summary;
  final String zone;
  final DateTime now;
  final VoidCallback? onOpenSource;

  /// The counted bottles / nursing sessions with their times ([summaryFeeds]); null shows the
  /// totals only.
  final List<SummaryItem>? bottleFeeds;
  final List<SummaryItem>? breastFeeds;

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
    Widget row(
      ClIcons icon,
      ClCareColor tint,
      String title,
      List<String> subs,
    ) => Padding(
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
                for (final sub in subs)
                  Text(
                    sub,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
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
                [
                  if (bottleFeeds case final feeds? when feeds.isNotEmpty)
                    feeds
                        .map(
                          (f) => l10n.asSummaryFeedMl(
                            hm(f.at, zone),
                            mlLabel(locale, f.ml ?? 0),
                          ),
                        )
                        .join(' · '),
                ],
              ),
            if (summary.breast.count > 0)
              row(
                ClIcons.drop,
                cl.care.breast,
                l10n.asSummaryBreast(
                  summary.breast.count,
                  summary.breast.amount,
                ),
                [
                  if (breastFeeds case final feeds? when feeds.isNotEmpty)
                    feeds
                        .map(
                          (f) => l10n.asSummaryFeedMinutes(
                            hm(f.at, zone),
                            f.minutes ?? 0,
                          ),
                        )
                        .join(' · '),
                  l10n.asSummaryBreastNote,
                ],
              ),
            if (summary.sleep.count > 0)
              row(
                ClIcons.sleep,
                cl.care.sleep,
                l10n.asSummarySleep(
                  summary.sleep.count,
                  _duration(l10n, summary.sleep.amount),
                ),
                const [],
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

/// A suggestion above the composer: it only prefills (or opens the photo sheet); never sends.
typedef AsSuggestion = ({String label, ClIcons icon, VoidCallback onPressed});

/// Chat/Ô nhập, reworked 2026-10-15: a growing field (up to 5 lines), suggestions that step
/// aside while typing, the camera, and one trailing button that is the mic while the field is
/// empty and "Gửi" once there are words (messaging-app style). While dictating the camera
/// becomes "×", the trailing button "Dừng" with a breathing ring, and a level meter with
/// "Đang nghe…" shows above the words; a swipe to the left cancels too.
class AsComposer extends StatelessWidget {
  const AsComposer({
    required this.controller,
    required this.mode,
    required this.hint,
    required this.onSend,
    this.focusNode,
    this.onCamera,
    this.sending = false,
    this.voice,
    this.onMic,
    this.suggestions = const [],
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

  /// Dictation (null: no mic on this phone / in this mode).
  final VoiceSession? voice;
  final VoidCallback? onMic;
  final List<AsSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final v = voice;
    if (v == null) return _build(context, null);
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) => _build(context, v),
    );
  }

  Widget _build(BuildContext context, VoiceSession? v) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final locked = mode == ComposerMode.out;
    final muted = mode != ComposerMode.open;
    final dictating = v?.active ?? false;
    final listening = v != null && v.phase == VoicePhase.listening;
    final micReady = v != null && !v.hidden && onMic != null && !locked;
    var drag = 0.0;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: locked,
      enabled: !locked,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLength: AssistantLimits.maxTextChars,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textCapitalization: TextCapitalization.sentences,
      style: cl.text.label.copyWith(fontSize: 15, height: 1.35, color: c.ink),
      cursorColor: c.mintDeep,
      decoration: InputDecoration.collapsed(
        hintText: dictating ? l10n.asVoiceListening : hint,
        hintStyle: cl.text.label.copyWith(
          fontSize: 15,
          height: 1.35,
          color: c.inkMuted,
        ),
      ).copyWith(counterText: ''),
    );
    final leading = dictating
        ? _Circle(
            key: const ValueKey('as.voice.cancel'),
            icon: ClIcons.close,
            label: l10n.asVoiceCancel,
            fill: c.surface2,
            ink: c.ink,
            onPressed: () => unawaited(v!.cancel()),
          )
        : (mode != ComposerMode.viewer && (locked || onCamera != null))
        ? Opacity(
            opacity: locked || onCamera == null ? ClMotion.disabledOpacity : 1,
            child: _Circle(
              icon: ClIcons.camera,
              label: l10n.asAddPhoto,
              fill: c.surface2,
              ink: c.ink,
              onPressed: locked ? null : onCamera,
            ),
          )
        : null;
    final trailing = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;
        final Widget button;
        if (dictating) {
          button = ListeningRing(
            key: const ValueKey('as.voice.stop'),
            level: v!.level,
            color: c.mintDeep,
            child: _Circle(
              icon: ClIcons.stop,
              label: l10n.asVoiceStop,
              fill: c.mintDeep,
              ink: c.onMintDeep,
              busy: !listening && v.phase == VoicePhase.starting,
              onPressed: listening ? () => unawaited(v.stop()) : null,
            ),
          );
        } else if (!hasText && micReady) {
          button = _Circle(
            key: const ValueKey('as.voice.mic'),
            icon: ClIcons.spark,
            glyph: MicGlyph(color: c.ink),
            label: l10n.asVoiceStart,
            fill: c.surface2,
            ink: c.ink,
            onPressed: onMic,
          );
        } else {
          final ready = !locked && hasText && !sending;
          button = Opacity(
            key: const ValueKey('as.send'),
            opacity: locked ? ClMotion.disabledOpacity : 1,
            child: _Circle(
              icon: ClIcons.arrowRight,
              label: l10n.asSend,
              fill: ready ? c.mintDeep : c.surface2,
              ink: ready ? c.onMintDeep : c.inkMuted,
              onPressed: ready ? onSend : null,
            ),
          );
        }
        return AnimatedSwitcher(
          duration: context.motion(ClMotion.quick),
          switchInCurve: ClCurves.quick,
          switchOutCurve: ClCurves.exit,
          transitionBuilder: (child, a) => context.reduceMotion
              ? FadeTransition(opacity: a, child: child)
              : ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                ),
          child: button,
        );
      },
    );
    final box = AnimatedContainer(
      duration: context.motion(ClMotion.quick),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(ClSpace.s2),
      decoration: BoxDecoration(
        color: muted ? c.surface2 : c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dictating ? c.mintDeep : c.controlBorder,
          width: dictating ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ?leading,
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (dictating)
                    Padding(
                      key: const ValueKey('as.voice.listening'),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Semantics(
                        liveRegion: true,
                        label: l10n.asVoiceListening,
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              VoiceLevelMeter(
                                level: v!.level,
                                color: c.mintText,
                                height: 14,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  v.heard
                                      ? l10n.asVoiceListening
                                      : l10n.asVoiceSwipe,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: cl.text.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: c.mintText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  field,
                ],
              ),
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          trailing,
        ],
      ),
    );
    final chips = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final show =
            suggestions.isNotEmpty &&
            !dictating &&
            !locked &&
            controller.text.isEmpty;
        return AsSize(
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: context.motion(ClMotion.quick),
            child: show
                ? SizedBox(
                    key: const ValueKey('as.suggestions'),
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(
                        ClSpace.s4,
                        0,
                        ClSpace.s4,
                        ClSpace.s2,
                      ),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: ClSpace.s2),
                      itemBuilder: (context, i) {
                        final s = suggestions[i];
                        return ClPressable(
                          onPressed: s.onPressed,
                          semanticLabel: s.label,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(
                                ClRadius.pill,
                              ),
                              border: Border.all(color: c.controlBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClIcon(s.icon, size: 14, color: c.mintText),
                                const SizedBox(width: 6),
                                Text(
                                  s.label,
                                  maxLines: 1,
                                  style: _semi(context, 13, c.ink),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        );
      },
    );
    return Container(
      color: c.cloud,
      padding: EdgeInsets.only(
        top: ClSpace.s2,
        bottom: ClSpace.s2 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          chips,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: dictating
                ? GestureDetector(
                    // Swipe left to cancel the dictation.
                    onHorizontalDragStart: (_) => drag = 0,
                    onHorizontalDragUpdate: (d) => drag += d.delta.dx,
                    onHorizontalDragEnd: (_) {
                      if (drag < -60) unawaited(v!.cancel());
                    },
                    child: box,
                  )
                : box,
          ),
        ],
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
    this.glyph,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final Color fill;
  final Color ink;
  final VoidCallback? onPressed;
  final bool busy;
  final Widget? glyph;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onPressed,
    semanticLabel: label,
    minSize: const Size(40, 40),
    child: AnimatedContainer(
      duration: context.motion(ClMotion.quick),
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: busy
          ? CupertinoActivityIndicator(color: ink, radius: 8)
          : (glyph ?? ClIcon(icon, size: 20, color: ink)),
    ),
  );
}

// ---------- Chat/Nút trợ lý: Lumi (lumi_button.dart) ----------

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
