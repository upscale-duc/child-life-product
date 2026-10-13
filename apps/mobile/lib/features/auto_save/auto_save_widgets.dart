import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/environment.dart';
import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../memories/memory_widgets.dart' show PlayGlyph;
import 'auto_save_controller.dart';

// Only the phone calls the background entry point; exporting it keeps it in release builds.
export 'auto_save_background.dart' show autoSaveBackground;

/// The `auto_save` rollout for one baby (P-148): asked from the server (`getFeatureAccess`,
/// which knows staff families and percent buckets) and remembered on the phone, so background
/// checks follow a kill switch too. Dev builds always have it, for testing.
final autoSaveFlagProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  babyId,
) async {
  if (!ref.watch(autoSaveNativeProvider).supported) return false;
  final controller = ref.read(autoSaveProvider.notifier);
  bool on;
  if (ref.watch(environmentProvider) == AppEnvironment.dev) {
    on = true;
  } else {
    try {
      final result = await ref
          .watch(functionsProvider)
          .httpsCallable('getFeatureAccess')
          .call<Object?>({'babyId': babyId});
      on = (result.data as Map?)?['autoSave'] == true;
    } on Object {
      // Offline or failing: the last answer this phone got.
      await controller.ready();
      return ref.read(autoSaveProvider).state.allowed[babyId] ?? false;
    }
  }
  unawaited(controller.rememberAllowed(babyId, on));
  return on;
});

/// Tự lưu is offered to the selected baby (iOS only, D-066 #3).
final autoSaveAvailableProvider = Provider<bool>((ref) {
  final babyId = ref.watch(selectedBabyIdProvider);
  if (babyId == null) return false;
  return ref.watch(autoSaveFlagProvider(babyId)).value ?? false;
});

/// Loads a library thumbnail by PhotoKit id; replaced in tests.
final libraryThumbLoaderProvider =
    Provider<Future<Uint8List?> Function(String id)>((ref) => _loadThumb);

final _thumbs = <String, Future<Uint8List?>>{};

Future<Uint8List?> _loadThumb(String id) {
  if (_thumbs.length > 300) _thumbs.clear();
  return _thumbs[id] ??= () async {
    try {
      final a = await AssetEntity.fromId(id);
      return a?.thumbnailDataWithSize(const ThumbnailSize.square(300));
    } on Object {
      return null;
    }
  }();
}

/// "Beta miễn phí" (D-066): travels with the feature name.
class AutoSaveBetaBadge extends StatelessWidget {
  const AutoSaveBetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        AppLocalizations.of(context).autoSaveBeta,
        // ink, not onWarm: onWarm is for the bright sunshine fill and stays dark in Night.
        style: cl.text.caption.copyWith(
          color: cl.colors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A library photo or video as a square tile, with the selection mark and tags (AS07).
class LibraryTile extends ConsumerWidget {
  const LibraryTile({
    required this.assetId,
    this.video = false,
    this.durationMs = 0,
    this.selected,
    this.onTap,
    this.onLongPress,
    this.badge,
    this.dimmed = false,
    this.radius = 8,
    super.key,
  });

  final String assetId;
  final bool video;
  final int durationMs;

  /// Null: no selection mark.
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Bottom-left: "+3", "Rõ nhất", "Đã có".
  final Widget? badge;
  final bool dimmed;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final load = ref.watch(libraryThumbLoaderProvider);
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: cl.colors.surface2),
          FutureBuilder<Uint8List?>(
            future: load(assetId),
            builder: (_, snap) => snap.data == null
                ? const SizedBox.shrink()
                : Image.memory(
                    snap.data!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
          if (dimmed)
            ColoredBox(color: cl.colors.cloud.withValues(alpha: 0.55)),
          if (video)
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const PlayGlyph(size: 9),
                  const SizedBox(width: 3),
                  Text(
                    _duration(durationMs),
                    style: cl.text.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(blurRadius: 3, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (badge != null)
            Positioned(left: 6, bottom: video ? 24 : 6, child: badge!),
          if (selected != null)
            Positioned(
              top: 6,
              right: 6,
              child: AutoSaveCheck(selected: selected!),
            ),
        ],
      ),
    );
    return ClPressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      pressedOpacity: 0.7,
      child: tile,
    );
  }
}

String _duration(int ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The round tick of a selectable tile.
class AutoSaveCheck extends StatelessWidget {
  const AutoSaveCheck({required this.selected, this.size = 22, super.key});
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? cl.colors.mintDeep
            : Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected
          ? ClIcon(ClIcons.check, size: size * 0.6, color: cl.colors.onMintDeep)
          : null,
    );
  }
}

/// A small tag on a tile ("Đã có", "Trên iCloud", "Rõ nhất", "+3").
class AutoSaveTag extends StatelessWidget {
  const AutoSaveTag(
    this.label, {
    this.warm = false,
    this.dark = false,
    super.key,
  });
  final String label;
  final bool warm;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (bg, ink) = dark
        ? (cl.colors.ink, cl.colors.surface)
        : warm
        ? (cl.colors.sunshineSoft, cl.colors.ink)
        : (cl.colors.surface, cl.colors.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        label,
        style: cl.text.caption.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "Teddy" / "Teddy và Na" / "Teddy, Na và Bin".
String joinNames(AppLocalizations l10n, List<String> names) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  return l10n.autoSaveAnd(
    names.sublist(0, names.length - 1).join(', '),
    names.last,
  );
}

/// "9:12" today, "11/10 9:12" otherwise.
String checkedAt(BuildContext context, DateTime t, DateTime now) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final time = DateFormat.Hm(locale).format(t);
  final today = t.year == now.year && t.month == now.month && t.day == now.day;
  return today ? time : '${DateFormat('d/M', locale).format(t)} $time';
}

/// AS01 / AR04: the way into Tự lưu at the top of Kỷ niệm, for parents (D-066).
class AutoSaveEntryCard extends ConsumerWidget {
  const AutoSaveEntryCard({
    required this.babyId,
    required this.name,
    super.key,
  });
  final String babyId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(autoSaveAvailableProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(autoSaveProvider);
    final pending = view.active ? view.pendingFor(babyId) : 0;
    final last = view.state.lastScanAt;
    final subtitle = pending > 0 && last != null
        ? l10n.autoSaveEntryPending(
            pending,
            checkedAt(context, last, DateTime.now()),
          )
        : l10n.autoSaveEntryHint(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: ClPressable(
        semanticLabel: '${l10n.autoSaveTitle}, ${l10n.autoSaveBeta}. $subtitle',
        onPressed: () => context.push(Routes.autoSave),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s3,
            ClSpace.s3,
            ClSpace.s3,
            ClSpace.s3,
          ),
          decoration: BoxDecoration(
            color: pending > 0 ? cl.colors.sunshineSoft : cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card - 6),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: pending > 0
                      ? cl.colors.surface
                      : cl.colors.sunshineSoft,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                alignment: Alignment.center,
                child: ClIcon(ClIcons.spark, size: 16, color: cl.colors.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l10n.autoSaveTitle, style: cl.text.bodyStrong),
                        const AutoSaveBetaBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.ink,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.autoSaveReviewShort,
                    style: cl.text.label.copyWith(
                      color: cl.colors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ClIcon(
                  ClIcons.chevronRight,
                  size: 16,
                  color: cl.colors.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps Tự lưu loaded while the app runs, so a check starts when the app opens (AR01).
class AutoSaveKeeper extends ConsumerWidget {
  const AutoSaveKeeper({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(autoSaveAvailableProvider)) {
      ref.listen(autoSaveProvider, (_, _) {});
    }
    return child;
  }
}

/// A Tự lưu page: back bar, large title (with the beta badge where drawn), subtitle, content and
/// an optional pinned action area at the bottom.
class AutoSavePage extends StatelessWidget {
  const AutoSavePage({
    required this.title,
    required this.children,
    this.subtitle,
    this.beta = false,
    this.onBack,
    this.trailing,
    this.bottom,
    this.onRefresh,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool beta;
  final List<Widget> children;

  /// Defaults to closing the page.
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        bottom == null
            ? MediaQuery.paddingOf(context).bottom + ClSpace.s6
            : ClSpace.s4,
      ),
      children: [
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: cl.text.largeTitle),
            ),
            if (beta) const AutoSaveBetaBadge(),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: ClSpace.s1),
          Text(
            subtitle!,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Column(
        children: [
          Expanded(
            child: ClPinnedHeaderScaffold(
              collapsedTitle: title,
              header: ClTopBar(
                onBack: onBack ?? () => Navigator.of(context).maybePop(),
                trailing: trailing,
              ),
              body: onRefresh == null
                  ? list
                  : RefreshIndicator(onRefresh: onRefresh!, child: list),
            ),
          ),
          if (bottom != null)
            Container(
              color: cl.colors.cloud,
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                MediaQuery.paddingOf(context).bottom + ClSpace.s3,
              ),
              child: bottom,
            ),
        ],
      ),
    );
  }
}

/// A white card with rounded corners, the building block of AS05 / AS12.
class AutoSaveCard extends StatelessWidget {
  const AutoSaveCard({required this.child, this.color, this.border, super.key});
  final Widget child;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: ClSpace.s3),
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 6),
        border: border == null ? null : Border.all(color: border!, width: 1.5),
      ),
      child: child,
    );
  }
}
