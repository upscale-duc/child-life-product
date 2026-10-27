import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/environment.dart';
import '../../core/appearance/appearance_providers.dart';
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
import '../memories/viewer_video.dart' show streamingPlayer;
import '../premium/premium_entries.dart'
    show askManagerForStorage, planManagerName, showStorageFullSuggestion;
import '../premium/premium_repository.dart' show capabilitiesProvider;
import '../premium/premium_v2.dart' show familyPlanV2Provider;
import 'auto_save_controller.dart';

// Only the phone calls the background entry point; exporting it keeps it in release builds.
export 'auto_save_background.dart' show autoSaveBackground;

/// The `auto_save` rollout for one baby (P-148): asked from the server (`getFeatureAccess`,
/// which knows the families picked in the portal and percent buckets) and remembered on the
/// phone, so background checks follow a kill switch too. Debug runs against dev always have it;
/// release builds, dev included, follow the flag like everyone else.
final autoSaveFlagProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  babyId,
) async {
  if (!ref.watch(autoSaveNativeProvider).supported) return false;
  final controller = ref.read(autoSaveProvider.notifier);
  bool on;
  if (kDebugMode && ref.watch(environmentProvider) == AppEnvironment.dev) {
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

/// D-122: Tự lưu's tier on the portal (Tính năng › Hạng) is Beta for [babyId]'s family, asked
/// from `getFeatureAccess` and remembered on the phone for offline. No answer yet, no badge.
final autoSaveBetaProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  babyId,
) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'autoSave.beta.$babyId';
  // No Firebase (widget tests, a broken install): the last answer, never a call.
  if (Firebase.apps.isEmpty) return prefs.getBool(key) ?? false;
  try {
    final result = await ref
        .watch(functionsProvider)
        .httpsCallable('getFeatureAccess')
        .call<Object?>({'babyId': babyId});
    final beta = (result.data as Map?)?['autoSaveBeta'] == true;
    await prefs.setBool(key, beta);
    return beta;
  } on Object {
    return prefs.getBool(key) ?? false;
  }
}, retry: (_, _) => null);

/// Tự lưu is offered to the selected baby (iOS only, D-066 #3).
final autoSaveAvailableProvider = Provider<bool>((ref) {
  final babyId = ref.watch(selectedBabyIdProvider);
  if (babyId == null) return false;
  return ref.watch(autoSaveFlagProvider(babyId)).value ?? false;
});

/// A library video's local file, for playing it in the review (null when it cannot be had,
/// e.g. offline and in iCloud); replaced in tests.
final libraryVideoPathProvider = Provider<Future<String?> Function(String id)>(
  (ref) => (id) async {
    try {
      final a = await AssetEntity.fromId(id);
      return (await a?.file)?.path;
    } on Object {
      return null;
    }
  },
);

/// A library video in the review (AS08): the poster until it plays, played while its page is
/// in view, paused by a tap or when swiped away.
class LibraryVideo extends ConsumerStatefulWidget {
  const LibraryVideo({
    required this.assetId,
    required this.active,
    required this.poster,
    super.key,
  });

  final String assetId;
  final bool active;
  final Widget poster;

  @override
  ConsumerState<LibraryVideo> createState() => _LibraryVideoState();
}

class _LibraryVideoState extends ConsumerState<LibraryVideo> {
  Player? _player;
  VideoController? _video;
  var _started = false;
  var _playing = false;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    if (widget.active) unawaited(_open());
  }

  @override
  void didUpdateWidget(LibraryVideo old) {
    super.didUpdateWidget(old);
    if (widget.active && _player == null) unawaited(_open());
    if (!widget.active) unawaited(_player?.pause());
  }

  Future<void> _open() async {
    final path = await ref.read(libraryVideoPathProvider)(widget.assetId);
    if (path == null || !mounted || _player != null) return;
    final player = _player = streamingPlayer();
    _video = VideoController(player);
    _subs
      ..add(
        player.stream.position.listen((p) {
          if (!_started && p > Duration.zero && mounted) {
            setState(() => _started = true);
          }
        }),
      )
      ..add(
        player.stream.playing.listen((p) {
          if (mounted) setState(() => _playing = p);
        }),
      );
    await player.setPlaylistMode(PlaylistMode.loop);
    await player.open(Media(path), play: widget.active);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_player?.playOrPause()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null)
            Video(
              controller: video,
              controls: NoVideoControls,
              fill: Colors.transparent,
            ),
          // The poster stays until a frame is shown, so there is no black flash.
          if (!_started) widget.poster,
          if (video != null && _started && !_playing)
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xE6FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Center(
                    child: PlayGlyph(size: 20, color: Colors.black87),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads a library thumbnail by PhotoKit id; replaced in tests.
final libraryThumbLoaderProvider =
    Provider<Future<Uint8List?> Function(String id)>((ref) => _loadThumb);

final _thumbs = <String, Future<Uint8List?>>{};

Future<Uint8List?> _loadThumb(String id) {
  if (_thumbs.length > 300) _thumbs.clear();
  return _thumbs[id] ??= _fetchThumb(id).then((bytes) {
    // A miss (an iCloud-only video still downloading, Photos busy) is not remembered: the next
    // build asks again instead of keeping a blank tile for the whole run.
    if (bytes == null) _thumbs.remove(id);
    return bytes;
  });
}

Future<Uint8List?> _fetchThumb(String id) async {
  final AssetEntity? a;
  try {
    a = await AssetEntity.fromId(id);
  } on Object {
    return null;
  }
  if (a == null) return null;
  final exact = await _thumbOf(a, DeliveryMode.highQualityFormat);
  // The exact square can fail for some videos; the quick frame beats an empty tile.
  return exact ?? _thumbOf(a, DeliveryMode.opportunistic);
}

Future<Uint8List?> _thumbOf(AssetEntity a, DeliveryMode mode) async {
  try {
    // The finished picture, cropped to the square, not iOS's quick blurry first pass
    // (owner, 2026-10-14: "đừng làm thumbnail mờ").
    return await a.thumbnailDataWithOption(
      defaultTargetPlatform == TargetPlatform.iOS
          ? ThumbnailOption.ios(
              size: const ThumbnailSize.square(400),
              quality: 90,
              deliveryMode: mode,
              resizeMode: ResizeMode.exact,
              resizeContentMode: ResizeContentMode.fill,
            )
          : const ThumbnailOption(size: ThumbnailSize.square(400), quality: 90),
    );
  } on Object {
    return null;
  }
}

/// "Beta miễn phí" (D-066), only while the portal has Tự lưu at the Beta tier (D-122).
class AutoSaveBetaBadge extends ConsumerWidget {
  const AutoSaveBetaBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyId = ref.watch(selectedBabyIdProvider);
    if (babyId == null ||
        ref.watch(autoSaveBetaProvider(babyId)).value != true) {
      return const SizedBox.shrink();
    }
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // The bright sunshine fill of AS12–AS19 with its own text colour: the same in Light and
      // Night care, so it reads on both.
      decoration: BoxDecoration(
        color: cl.colors.sunshine,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        AppLocalizations.of(context).autoSaveBeta,
        style: cl.text.caption.copyWith(
          color: cl.colors.onWarm,
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
                  // An unknown length shows the play mark alone, never "0:00".
                  if (durationMs > 0) ...[
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
    // A tile with nothing to do is a plain picture: ClPressable shows a disabled control at 40 %
    // opacity, which washed the thumbnails out on AS12 and AR02 (owner, 2026-10-14).
    if (onTap == null && onLongPress == null) return tile;
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
    this.padding = const EdgeInsets.only(bottom: ClSpace.s3),
    super.key,
  });
  final String babyId;
  final String name;

  /// Around the card, so the gaps above and below match the tab it sits in.
  final EdgeInsets padding;

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
      padding: padding,
      child: ClPressable(
        semanticLabel: '${l10n.autoSaveTitle}. $subtitle',
        onPressed: () => context.push(Routes.autoSave),
        // AS01 (479:7358): one row on the surface, the spark on a sunshine-soft tile, a
        // chevron; waiting suggestions add a count, not a second button (owner, 2026-10-14).
        child: Container(
          padding: const EdgeInsets.fromLTRB(ClSpace.s3, 10, ClSpace.s2, 10),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            boxShadow: cl.shadows.card,
            borderRadius: BorderRadius.circular(ClRadius.card - 6),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cl.colors.sunshineSoft,
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
                    // D-121: "Beta miễn phí" is said once, on the intro (AS02) where the parent
                    // decides; not on this row they pass every day.
                    Text(l10n.autoSaveTitle, style: cl.text.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.caption.copyWith(
                        color: pending > 0
                            ? cl.colors.mintText
                            : cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              if (pending > 0) ...[
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.mintDeep,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    pending > 99 ? '99+' : '$pending',
                    textAlign: TextAlign.center,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.onMintDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
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

/// The way out of a full family space, named before the tap (D-125, D-126): a Free family on
/// Premium v2 is offered Premium, a Premium family the paid add-on, and without v2 the Dung lượng
/// screen; a Premium member who doesn't manage the plan asks the manager (D-127 Q7). Used by
/// AS18 and the upload queue.
enum StorageWayOut { premium, addOn, ask, manage }

StorageWayOut storageWayOut(WidgetRef ref, String babyId) {
  final v2 =
      ref.watch(capabilitiesProvider(babyId)).value?.features.premiumV2 ??
      false;
  if (!v2) return StorageWayOut.manage;
  final plan = ref.watch(familyPlanV2Provider(babyId)).value;
  if (!(plan?.premium ?? false)) return StorageWayOut.premium;
  return plan!.isManager ? StorageWayOut.addOn : StorageWayOut.ask;
}

String storageWayOutLabel(
  WidgetRef ref,
  AppLocalizations l10n,
  String babyId,
  StorageWayOut way,
) => switch (way) {
  StorageWayOut.premium => l10n.autoSaveAddSpacePremium,
  StorageWayOut.addOn => l10n.autoSaveBuySpace,
  StorageWayOut.ask => l10n.pv2AskStorage(planManagerName(ref, l10n, babyId)),
  StorageWayOut.manage => l10n.autoSaveManageSpace,
};

void openStorageWayOut(
  BuildContext context,
  WidgetRef ref,
  String babyId,
  StorageWayOut way, {
  bool autoSave = false,
}) => switch (way) {
  StorageWayOut.manage => unawaited(context.push(Routes.meStorage)),
  StorageWayOut.ask => unawaited(askManagerForStorage(context)),
  _ => unawaited(
    showStorageFullSuggestion(context, ref, babyId, autoSave: autoSave),
  ),
};
