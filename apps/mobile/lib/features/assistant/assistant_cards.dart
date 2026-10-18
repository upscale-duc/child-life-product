import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart' show ClToggle;
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'assistant_models.dart';
import 'assistant_widgets.dart';

/// Slice A5 chat components (Figma page 568:18): Chat/Tệp đính kèm (photo bubble, CH09–CH14),
/// the CH09 photo card with the exact quote and the retention choice, the CH11 receipt card,
/// the CH16 guidance card, the CH18 recipe card and the CH15 safety note. Every colour is a token
/// (Light and Night care); text on the soft warm fills is `ink`.

TextStyle _semi(BuildContext context, double size, Color color) =>
    context.cl.text.label.copyWith(
      fontSize: size,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: color,
    );

// ---------- Chat/Tệp đính kèm ----------

/// The tone of a photo bubble's label.
enum AsPhotoTone { muted, done, error }

/// Chat/Tệp đính kèm (`Đang tải lên` / `Đang đọc` / `Đã đọc` / `Ảnh mờ`): the photo the
/// person sent (this phone's copy, else a paper placeholder — the app never reads the upload
/// back), a progress bar while uploading, and its label.
class AsPhotoBubble extends StatelessWidget {
  const AsPhotoBubble({
    required this.label,
    this.bytes,
    this.icon,
    this.tone = AsPhotoTone.muted,
    this.dimmed = false,
    this.blurred = false,
    this.progress,
    this.onCancel,
    this.cancelLabel,
    super.key,
  });

  final String label;
  final Uint8List? bytes;
  final ClIcons? icon;
  final AsPhotoTone tone;

  /// Pending (uploading / reading): the photo sits under a dark veil.
  final bool dimmed;

  /// CH14 "Ảnh mờ".
  final bool blurred;

  /// 0–1 while uploading; null hides the bar.
  final double? progress;
  final VoidCallback? onCancel;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final ink = switch (tone) {
      AsPhotoTone.muted => c.inkMuted,
      AsPhotoTone.done => c.mintText,
      AsPhotoTone.error => c.error,
    };
    Widget photo = bytes != null ? _thumb(bytes!) : const _Paper();
    if (blurred) {
      photo = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
        child: photo,
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 166,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo,
                    if (dimmed || blurred)
                      ColoredBox(
                        color: const Color(
                          0xFF000000,
                        ).withValues(alpha: blurred ? 0.25 : 0.35),
                      ),
                  ],
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(ClRadius.pill),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: c.surface2,
                  color: c.mintDeep,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Semantics(
              liveRegion: dimmed,
              child: Row(
                children: [
                  if (icon != null) ...[
                    ClIcon(icon!, size: 12, color: ink),
                    const SizedBox(width: 4),
                  ],
                  Expanded(child: Text(label, style: _semi(context, 12, ink))),
                ],
              ),
            ),
            if (onCancel != null)
              Align(
                alignment: Alignment.centerRight,
                child: ClPressable(
                  onPressed: onCancel,
                  semanticLabel: cancelLabel,
                  minSize: const Size(44, 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      cancelLabel ?? '',
                      style: _semi(context, 13, c.mintText),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// This phone's copy of the photo; the paper placeholder until it is decoded (or if it fails).
Widget _thumb(Uint8List bytes) => Image.memory(
  bytes,
  fit: BoxFit.cover,
  gaplessPlayback: true,
  excludeFromSemantics: true,
  frameBuilder: (context, child, frame, sync) =>
      frame == null && !sync ? const _Paper() : child,
  errorBuilder: (context, _, _) => const _Paper(),
);

/// The receipt / note placeholder when this phone has no copy of the photo.
class _Paper extends StatelessWidget {
  const _Paper();

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    Widget bar(double w) => Container(
      width: w,
      height: 5,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: c.separator,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return ColoredBox(
      color: c.surface2,
      child: FittedBox(
        child: Container(
          width: 92,
          height: 118,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(50), bar(68), bar(40), bar(60), bar(30), bar(56)],
          ),
        ),
      ),
    );
  }
}

// ---------- CH09: the chosen photo, its exact quote and the retention choice ----------

class AsPhotoReadyCard extends StatelessWidget {
  const AsPhotoReadyCard({
    required this.bytes,
    required this.keep,
    required this.onKeep,
    required this.onSend,
    required this.onRemove,
    this.canceled = false,
    super.key,
  });

  final Uint8List? bytes;

  final bool keep;
  final ValueChanged<bool>? onKeep;
  final VoidCallback? onSend;
  final VoidCallback onRemove;
  final bool canceled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return AsCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: bytes == null ? const _Paper() : _thumb(bytes!),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.asPhotoChosenTitle,
                    style: _semi(context, 15, c.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.asPhotoOnlyThis,
                    style: cl.text.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.asKeepReceipt,
                  style: _semi(context, 14, c.ink),
                ),
              ),
              ClToggle(value: keep, onChanged: onKeep),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          keep ? l10n.asKeepReceiptOn : l10n.asKeepReceiptOff,
          style: cl.text.caption.copyWith(height: 1.4, color: c.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        AsFootnote(icon: ClIcons.lock, text: l10n.asPhotoTextIsData),
        if (canceled) ...[
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.asUploadCanceled,
            style: cl.text.caption.copyWith(color: c.inkMuted),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            Expanded(
              child: AsButton(
                label: l10n.asRemovePhoto,
                style: AsButtonStyle.secondary,
                expand: true,
                onPressed: onRemove,
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: AsButton(
                label: l10n.asSendPhoto,
                expand: true,
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- CH11 receipt card ----------

/// One field of the receipt card: muted label, SemiBold value; [flagged] = must be checked
/// ("14/10/2026 ?" on `sunshine-soft` with an alert).
typedef AsField = ({
  String label,
  String value,
  bool flagged,
  VoidCallback? onTap,
});

/// The duplicate box of CH11 ("Có thể trùng …"): open the logged one or save anyway.
typedef AsDuplicate = ({
  bool acknowledged,
  VoidCallback? onOpen,
  VoidCallback? onAcknowledge,
});

class AsReceiptCard extends StatelessWidget {
  const AsReceiptCard({
    required this.title,
    required this.stateLabel,
    required this.review,
    required this.fields,
    this.footnote,
    this.duplicate,
    this.notes = const [],
    this.actions = const [],
    this.saving = false,
    this.primary,
    this.privateHint,
    this.ask,
    super.key,
  });

  final String title;
  final String stateLabel;

  /// LUMI-16: Lumi's question with its answer field ("Hết bao nhiêu tiền?"), above the fields.
  final Widget? ask;

  /// The card's main action as a filled button ("Lưu chi tiêu"); [actions] stay links.
  final AsCardAction? primary;

  /// "Chỉ bạn thấy": spending stays out of the baby's shared thread (D-075 #2).
  final String? privateHint;

  /// "Cần kiểm tra": the `sunshine` edge and pill.
  final bool review;
  final List<AsField> fields;
  final String? footnote;
  final AsDuplicate? duplicate;
  final List<String> notes;
  final List<AsCardAction> actions;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    Widget field(AsField f) {
      final row = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: f.flagged ? c.sunshineSoft : c.cloud,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              f.label,
              style: cl.text.label.copyWith(
                fontSize: 13,
                color: f.flagged ? c.ink : c.inkMuted,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                f.flagged ? '${f.value} ?' : f.value,
                textAlign: TextAlign.end,
                style: _semi(context, 14, c.ink),
              ),
            ),
            if (f.flagged) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClIcon(ClIcons.alert, size: 14, color: c.ink),
              ),
            ],
          ],
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: f.onTap == null
            ? Semantics(
                label: '${f.label}, ${f.value}',
                child: ExcludeSemantics(child: row),
              )
            : ClPressable(
                onPressed: f.onTap,
                semanticLabel: f.flagged
                    ? l10n.asFieldCheckA11y(f.label, f.value)
                    : '${f.label}, ${f.value}',
                pressedOpacity: 0.7,
                child: row,
              ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: asCardWidth,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: review
              ? Border.all(color: c.sunshine, width: 1.5)
              : Border.all(color: c.separator),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.peachSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(ClIcons.grid, size: 16, color: c.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _semi(context, 15, c.ink),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: review ? c.sunshineSoft : c.surface2,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Semantics(
                    liveRegion: saving,
                    child: Text(
                      stateLabel,
                      style: cl.text.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: review ? c.ink : c.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (ask case final a?) ...[const SizedBox(height: 6), a],
            for (final f in fields) field(f),
            if (footnote != null) ...[
              const SizedBox(height: 8),
              Text(
                footnote!,
                style: cl.text.caption.copyWith(height: 1.4, color: c.inkMuted),
              ),
            ],
            if (duplicate case final d?) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ClIcon(
                            d.acknowledged ? ClIcons.check : ClIcons.alert,
                            size: 13,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.acknowledged
                                ? l10n.asDuplicateAcknowledged
                                : l10n.asDuplicateBody,
                            style: cl.text.caption.copyWith(
                              fontSize: 12.5,
                              height: 1.4,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: ClSpace.s4,
                      children: [
                        if (d.onOpen != null)
                          _InlineLink(
                            label: l10n.asOpenDuplicate,
                            onPressed: d.onOpen!,
                            color: c.mintText,
                          ),
                        if (!d.acknowledged && d.onAcknowledge != null)
                          _InlineLink(
                            label: l10n.asSaveAnywayShort,
                            onPressed: d.onAcknowledge!,
                            color: c.ink,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            for (final n in notes) ...[
              const SizedBox(height: 6),
              Text(
                n,
                style: cl.text.caption.copyWith(
                  fontSize: 12.5,
                  color: c.inkMuted,
                ),
              ),
            ],
            if (privateHint != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ClIcon(ClIcons.lock, size: 12, color: c.inkMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      privateHint!,
                      style: cl.text.caption.copyWith(color: c.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (actions.isNotEmpty || primary != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: ClSpace.s4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (primary case final p?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AsButton(
                        label: p.label,
                        icon: ClIcons.check,
                        loading: saving,
                        onPressed: p.onPressed,
                      ),
                    ),
                  for (final (i, a) in actions.indexed)
                    Opacity(
                      opacity: a.onPressed == null
                          ? ClMotion.disabledOpacity
                          : 1,
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
                                  i == 0 && primary == null
                                      ? c.mintText
                                      : c.inkMuted,
                                ).copyWith(
                                  fontWeight: i == 0 && primary == null
                                      ? FontWeight.w700
                                      : null,
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
      ),
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({
    required this.label,
    required this.onPressed,
    required this.color,
  });
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onPressed,
    semanticLabel: label,
    minSize: const Size(0, 36),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: _semi(context, 13, color)),
    ),
  );
}

// ---------- CH15 safety note ----------

/// "Nếu con sốt, khó thở, li bì hoặc bỏ bú — mở Hướng dẫn sức khoẻ (miễn phí)" with its link
/// (health is never behind credits).
class AsSafetyNote extends StatelessWidget {
  const AsSafetyNote({required this.onOpenHealth, super.key});
  final VoidCallback onOpenHealth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: asCardWidth,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        decoration: BoxDecoration(
          color: c.errorSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClIcon(ClIcons.alert, size: 14, color: c.error),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.asSleepSafety,
                    style: cl.text.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.error,
                    ),
                  ),
                ),
              ],
            ),
            AsLink(
              label: l10n.asOpenHealth,
              onPressed: onOpenHealth,
              color: c.error,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- CH16 guidance ----------

/// "Từ Thư viện chăm bé": the published item's own words (title, summary, steps, safety), the
/// reason from what the person reported, and "chờ chuyên môn duyệt" until reviewed.
class AsGuidanceCard extends StatelessWidget {
  const AsGuidanceCard({
    required this.content,
    required this.reason,
    required this.reviewed,
    this.children = const [],
    super.key,
  });

  final ApprovedContentText content;
  final String reason;
  final bool reviewed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return AsCard(
      children: [
        Row(
          children: [
            ClIcon(ClIcons.journal, size: 14, color: c.mintText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                content.durationMin > 0
                    ? l10n.asFromCareLibraryMinutes(content.durationMin)
                    : l10n.asFromCareLibrary,
                style: _semi(
                  context,
                  12,
                  c.mintText,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            content.title,
            style: _semi(
              context,
              16,
              c.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (content.summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            content.summary,
            style: cl.text.label.copyWith(
              fontSize: 14,
              height: 1.4,
              color: c.ink,
            ),
          ),
        ],
        if (content.steps.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s2),
          for (final (i, step) in content.steps.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: c.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: _semi(context, 11, c.mintText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: cl.text.label.copyWith(
                        fontSize: 13.5,
                        height: 1.4,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (content.safety case final safety?) ...[
          const SizedBox(height: ClSpace.s2),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.sunshineSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClIcon(ClIcons.alert, size: 13, color: c.ink),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    safety,
                    style: cl.text.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (reason.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s2),
          Text(
            reason,
            style: cl.text.caption.copyWith(height: 1.4, color: c.inkMuted),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          reviewed ? l10n.asContentReviewed : l10n.asContentUnreviewed,
          style: cl.text.caption.copyWith(
            fontSize: 11,
            height: 1.4,
            color: c.inkMuted,
          ),
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          ...children,
        ],
      ],
    );
  }
}

// ---------- CH18 recipes ----------

/// The approved recipes (≤ 3) with why, the count left out for a recorded reaction (a family
/// note, not an allergy diagnosis), the unknown-tolerance caveat and "Ghi bữa ăn" (no meal log
/// yet → unavailable).
class AsRecipeCard extends StatelessWidget {
  const AsRecipeCard({
    required this.items,
    required this.excludedCount,
    required this.caveat,
    required this.mealLogAvailable,
    super.key,
  });

  final List<RecipeListItem> items;
  final int excludedCount;
  final String? caveat;
  final bool mealLogAvailable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final fills = [c.sunshineSoft, c.peachSoft, cl.care.bottle.soft];
    return AsCard(
      children: [
        Text(
          l10n.asRecipesFrom,
          style: _semi(
            context,
            12,
            c.inkMuted,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        for (final (i, r) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: fills[i % fills.length],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    // Soft warm fills take `ink` (Night care).
                    child: ClIcon(ClIcons.feed, size: 20, color: c.ink),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: _semi(context, 14, c.ink)),
                        Text(
                          [
                            if (r.durationMin > 0)
                              l10n.asRecipeMinutes(r.durationMin),
                            if (r.why.isNotEmpty) r.why,
                          ].join(' · '),
                          style: cl.text.caption.copyWith(color: c.inkMuted),
                        ),
                        if (r.summary.isNotEmpty)
                          Text(
                            r.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.caption.copyWith(
                              height: 1.4,
                              color: c.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (excludedCount > 0) ...[
          const SizedBox(height: ClSpace.s3),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClIcon(ClIcons.alert, size: 13, color: c.ink),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.asRecipesExcluded(excludedCount),
                    style: cl.text.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        Text(
          // With an exclusion the box above already says it; the tolerance caveat stays.
          excludedCount > 0
              ? l10n.asRecipesCaveat
              : (caveat ?? l10n.asRecipesCaveat),
          style: cl.text.caption.copyWith(height: 1.4, color: c.inkMuted),
        ),
        if (!mealLogAvailable) ...[
          const SizedBox(height: ClSpace.s3),
          AsButton(
            label: l10n.asLogMeal,
            style: AsButtonStyle.outline,
            expand: true,
            onPressed: null,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.asLogMealUnavailable,
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: c.inkMuted),
          ),
        ],
      ],
    );
  }
}

// ---------- Small pieces ----------

/// A centred day divider ("Hôm nay 16/10") before a later question in the same thread.
class AsDayDivider extends StatelessWidget {
  const AsDayDivider({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(label, style: _semi(context, 11, context.cl.colors.inkMuted)),
  );
}

/// A "notice" card for a coded server text (no approved content, region, paused, age).
class AsNoticeCard extends StatelessWidget {
  const AsNoticeCard({
    required this.icon,
    required this.text,
    this.action,
    super.key,
  });
  final ClIcons icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AsCard(
    tone: AsTone.quiet,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClIcon(icon, size: 15, color: context.cl.colors.inkMuted),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              text,
              style: context.cl.text.label.copyWith(
                fontSize: 13.5,
                height: 1.4,
                color: context.cl.colors.ink,
              ),
            ),
          ),
        ],
      ),
      ?action,
    ],
  );
}
