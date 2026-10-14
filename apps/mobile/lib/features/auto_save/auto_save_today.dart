import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../memories/memory_models.dart';
import 'auto_save_controller.dart';
import 'auto_save_engine.dart';
import 'auto_save_review.dart' show AutoSaveDecision;
import 'auto_save_widgets.dart';

/// At most this many tiles in the quick sheet (AR05); more opens the full review.
const _quickTiles = 8;

/// Suggestions for the selected baby the Hôm nay banner should mention: pending, and not all
/// put off with "Để sau" (AR02).
final autoSaveBannerProvider = Provider.autoDispose<List<Candidate>>((ref) {
  if (!ref.watch(autoSaveAvailableProvider)) return const [];
  final view = ref.watch(autoSaveProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  if (!view.active || babyId == null) return const [];
  final pending = [
    for (final c in view.state.pending)
      if (c.match.babyId == babyId) c,
  ];
  if (pending.every((c) => view.state.bannerHidden.contains(c.asset.id))) {
    return const [];
  }
  return pending;
});

/// Whether the Kỷ niệm tab shows a dot (AR02): suggestions wait for the selected baby.
final autoSaveTabDotProvider = Provider.autoDispose<bool>((ref) {
  if (!ref.watch(autoSaveAvailableProvider)) return false;
  final view = ref.watch(autoSaveProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  return view.active && babyId != null && view.pendingFor(babyId) > 0;
});

/// AR02: "8 ảnh mới có thể có Teddy" on Hôm nay, above the care tiles.
class AutoSaveTodayBanner extends ConsumerWidget {
  const AutoSaveTodayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(autoSaveBannerProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final babyId = pending.first.match.babyId;
    final name = ref.watch(babyProvider(babyId)).value?.nickname ?? '';
    final title = l10n.autoSaveBannerTitle(pending.length, name);
    final later = ref.read(autoSaveProvider.notifier).hideBanner;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Container(
        key: const Key('autoSaveBanner'),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: cl.colors.sunshineSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 486:7227: up to three thumbs side by side, each ringed in the banner's own
                // colour so an overlap reads as a stack, not one blurred picture.
                SizedBox(
                  width: 36.0 + (math.min(pending.length, 3) - 1) * 24,
                  height: 36,
                  child: Stack(
                    children: [
                      for (final (i, c) in pending.take(3).indexed)
                        Positioned(
                          left: i * 24.0,
                          child: Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cl.colors.sunshineSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LibraryTile(assetId: c.asset.id, radius: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.autoSaveBannerBody,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClPressable(
                  key: const Key('autoSaveBannerClose'),
                  onPressed: () => unawaited(later()),
                  semanticLabel: l10n.autoSaveBannerLater,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: ClIcon(
                        ClIcons.close,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                // The main button takes the room, "Để sau" its own width (486:7227), so
                // "Xem & chọn ảnh" is never cut.
                children: [
                  Expanded(
                    child: ClButton(
                      label: l10n.autoSaveBannerOpen,
                      expand: true,
                      // The quick sheet only when every group fits in it; a bigger batch
                      // goes straight to the full review (AS07), not to 8 of 200.
                      onPressed: () => unawaited(
                        ref.read(autoSaveProvider).groups(babyId).length >
                                _quickTiles
                            ? GoRouter.of(context).push(Routes.autoSaveReview)
                            : showAutoSaveQuickSheet(context, babyId),
                      ),
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  ClButton(
                    label: l10n.autoSaveBannerLater,
                    style: ClButtonStyle.secondary,
                    onPressed: () => unawaited(later()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AR05 "Duyệt nhanh": the newest groups, best photos pre-ticked, uploaded with the Tự lưu
/// defaults; "Đổi" goes to AS10, "Xem lớn từng ảnh" to AS07, "Bỏ qua lần này" drops the batch
/// with Hoàn tác (AR08).
Future<void> showAutoSaveQuickSheet(BuildContext context, String babyId) =>
    showClSheet<void>(
      context: context,
      builder: (_) => _QuickSheet(babyId: babyId, host: context),
    );

class _QuickSheet extends ConsumerStatefulWidget {
  const _QuickSheet({required this.babyId, required this.host});
  final String babyId;

  /// The screen under the sheet: navigation and toasts continue there once it closes.
  final BuildContext host;

  @override
  ConsumerState<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends ConsumerState<_QuickSheet> {
  Set<String>? _selected;
  var _busy = false;

  /// What the sheet showed when "Tải lên" was tapped: approving takes the items out of the live
  /// list before the sheet closes, which drew "0 ảnh mới" and "Tải lên 0 mục" meanwhile.
  List<SuggestionGroup>? _frozen;
  var _closing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(autoSaveProvider);
    final live = view.groups(widget.babyId).take(_quickTiles).toList();
    final groups = _busy ? (_frozen ?? live) : live;
    // Nothing left to review (handled elsewhere): the sheet goes instead of showing 0.
    if (groups.isEmpty && !_busy && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
    final shown = [for (final g in groups) ...g.items];
    final selected = _selected ??= {for (final g in groups) ...g.preselected};
    final chosen = [
      for (final c in shown)
        if (selected.contains(c.asset.id)) c,
    ];
    final name = ref.watch(babyProvider(widget.babyId)).value?.nickname ?? '';
    final days = [for (final c in shown) c.asset.captureAt]..sort();
    final range = days.isEmpty ? '' : _range(days.first, days.last);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(widget.host);
    final toaster = ClToaster.of(widget.host);
    final controller = ref.read(autoSaveProvider.notifier);

    Future<void> upload() async {
      setState(() {
        _busy = true;
        _frozen = groups;
      });
      try {
        final n = await controller.approve(
          chosen: chosen,
          reviewed: shown,
          audience: Audience.parents,
          notifyFamily: false,
        );
        _closing = true;
        navigator.pop();
        toaster.show(message: l10n.autoSaveQueued(n));
      } on Object {
        if (mounted) setState(() => _busy = false);
        toaster.show(message: l10n.toastActionFailed, error: true);
      }
    }

    Future<void> skip() async {
      final undo = await controller.skip(shown);
      navigator.pop();
      toaster.show(
        message: l10n.autoSaveSkipped(shown.length),
        actionLabel: l10n.autoSaveUndo,
        onAction: () => unawaited(controller.undo(undo)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: l10n.autoSaveBannerTitle(shown.length, name),
          onClose: navigator.pop,
        ),
        if (range.isNotEmpty)
          Text(
            l10n.autoSaveQuickSub(range),
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        const SizedBox(height: ClSpace.s3),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final g in groups)
              LibraryTile(
                assetId: g.best.asset.id,
                video: g.best.asset.video,
                durationMs: g.best.asset.durationMs,
                selected: selected.contains(g.best.asset.id),
                badge: g.items.length > 1
                    ? AutoSaveTag('+${g.items.length - 1}', dark: true)
                    : null,
                onTap: () => setState(
                  () => selected.contains(g.best.asset.id)
                      ? selected.remove(g.best.asset.id)
                      : selected.add(g.best.asset.id),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.lock, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.autoSaveQuickDefaults, style: cl.text.label),
                    Text(
                      l10n.autoSaveQuickNoNotify,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ClButton(
                label: l10n.autoSaveChange,
                style: ClButtonStyle.plain,
                onPressed: chosen.isEmpty
                    ? null
                    : () {
                        navigator.pop();
                        unawaited(
                          router.push(
                            Routes.autoSaveConfirm,
                            extra: AutoSaveDecision(
                              chosen: chosen,
                              reviewed: shown,
                            ),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.autoSaveUploadCount(chosen.length),
          expand: true,
          loading: _busy,
          onPressed: chosen.isEmpty || _busy ? null : () => unawaited(upload()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClButton(
              label: l10n.autoSaveQuickBig,
              style: ClButtonStyle.plain,
              onPressed: () {
                navigator.pop();
                unawaited(router.push(Routes.autoSaveReview));
              },
            ),
            ClButton(
              label: l10n.autoSaveSkipBatch,
              style: ClButtonStyle.plain,
              onPressed: _busy ? null : () => unawaited(skip()),
            ),
          ],
        ),
      ],
    );
  }
}

/// "15–18/10", or "18/10" for one day, or "28/9–2/10" across months.
String _range(DateTime a, DateTime b) {
  String d(DateTime t) => '${t.day}/${t.month}';
  if (a.year == b.year && a.month == b.month && a.day == b.day) return d(a);
  if (a.year == b.year && a.month == b.month) return '${a.day}–${d(b)}';
  return '${d(a)}–${d(b)}';
}
