import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../app/providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_widgets.dart';
import 'upload_queue.dart';

const _photoExt = {'jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'};
const _videoExt = {'mov', 'mp4', 'm4v', '3gp'};

MediaKind? _kindOf(String name) {
  final ext = name.split('.').last.toLowerCase();
  if (_photoExt.contains(ext)) return MediaKind.photo;
  if (_videoExt.contains(ext)) return MediaKind.video;
  return null;
}

Future<PickedMedia?> _fromAsset(AssetEntity a, Uint8List? thumb) async {
  final file = await a.originFile ?? await a.file;
  if (file == null) return null;
  final type = a.type == AssetType.video ? MediaKind.video : MediaKind.photo;
  return PickedMedia(
    file: file,
    type: type,
    name: await a.titleAsync,
    captureAt: a.createDateTime,
    durationMs: type == MediaKind.video ? a.videoDuration.inMilliseconds : null,
    width: a.orientatedWidth,
    height: a.orientatedHeight,
    thumbBytes:
        thumb ?? await a.thumbnailDataWithSize(const ThumbnailSize.square(200)),
    assetId: a.id,
  );
}

/// A library item by its PhotoKit id (Tự lưu suggestions, AS10); null when it is gone. The
/// original may come down from iCloud first (AS11 "Đang lấy tệp gốc từ iCloud").
Future<PickedMedia?> pickedFromLibrary(String id) async {
  final a = await AssetEntity.fromId(id);
  return a == null ? null : _fromAsset(a, null);
}

// ---------- "Ảnh mới chụp hôm nay" (10a2) ----------

/// What the recent strip picked; read by the add sheet after it closes.
List<PickedMedia>? lastRecentPick;

/// One of today's photos or videos in the strip; the file is fetched only when added (it may
/// have to come down from iCloud).
@immutable
class RecentItem {
  const RecentItem({required this.resolve, this.thumb, this.isVideo = false});
  final Uint8List? thumb;
  final bool isVideo;
  final Future<PickedMedia?> Function() resolve;
}

/// Today's newest 10, only when the library is already shared (never prompts here).
Future<List<RecentItem>> loadRecentToday() async {
  try {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    if (!state.hasAccess) return const [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(min: start, max: now),
        orders: [const OrderOption(type: OrderOptionType.createDate)],
      ),
    );
    if (paths.isEmpty) return const [];
    final assets = await paths.first.getAssetListRange(start: 0, end: 10);
    return [
      for (final a in assets)
        await () async {
          final thumb = await a.thumbnailDataWithSize(
            const ThumbnailSize.square(160),
          );
          return RecentItem(
            thumb: thumb,
            isVideo: a.type == AssetType.video,
            resolve: () => _fromAsset(a, thumb),
          );
        }(),
    ];
  } on Object {
    // No library on this device: no strip.
    return const [];
  }
}

/// "Ảnh mới chụp hôm nay" (10a2): tap to select one or several (numbered in tap order), then
/// "Thêm N mục" goes on to compose with all of them (owner, 2026-10-11; a tap used to add one).
class RecentToday extends StatefulWidget {
  const RecentToday({
    required this.zone,
    required this.onPick,
    this.load = loadRecentToday,
    super.key,
  });
  final String zone;
  final void Function(List<PickedMedia> picked) onPick;

  /// Replaced in tests (the native library cannot run there).
  final Future<List<RecentItem>> Function() load;

  @override
  State<RecentToday> createState() => _RecentTodayState();
}

class _RecentTodayState extends State<RecentToday> {
  List<RecentItem>? _items;

  /// Indices in the order they were tapped.
  final _selected = <int>[];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.load().then((items) {
        if (mounted && items.isNotEmpty) setState(() => _items = items);
      }),
    );
  }

  void _toggle(int i) => setState(
    () => _selected.contains(i) ? _selected.remove(i) : _selected.add(i),
  );

  Future<void> _add() async {
    final items = _items;
    if (items == null || _selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    final picked = <PickedMedia>[];
    for (final i in _selected) {
      final p = await items[i].resolve();
      if (p != null) picked.add(p);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (picked.isEmpty) return;
    lastRecentPick = picked;
    widget.onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final count = _selected.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.addRecent, style: cl.text.bodyStrong),
              const Spacer(),
              Text(
                count == 0 ? l10n.addRecentHint : l10n.addRecentCount(count),
                style: cl.text.caption.copyWith(
                  color: count == 0 ? cl.colors.inkMuted : cl.colors.mintText,
                  fontWeight: count == 0 ? null : FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final item = items[i];
                final order = _selected.indexOf(i);
                final on = order >= 0;
                return ClPressable(
                  key: ValueKey('recent$i'),
                  onPressed: _busy ? null : () => _toggle(i),
                  selected: on,
                  semanticLabel: item.isVideo
                      ? l10n.pickVideos
                      : l10n.memPhotos,
                  minSize: Size.zero,
                  child: Container(
                    width: 64,
                    height: 64,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cl.colors.surface2,
                      borderRadius: BorderRadius.circular(ClRadius.sm),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ClRadius.sm),
                      border: on
                          ? Border.all(color: cl.colors.mintDeep, width: 3)
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.thumb case final t?)
                          Image.memory(t, fit: BoxFit.cover),
                        if (item.isVideo)
                          const Positioned(
                            left: 5,
                            bottom: 5,
                            child: PlayGlyph(size: 10),
                          ),
                        // iOS-style: an empty ring, or the tap order once chosen.
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? cl.colors.mintDeep : Colors.black26,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: on
                                ? Text(
                                    '${order + 1}',
                                    style: cl.text.caption.copyWith(
                                      fontSize: 11,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                      color: cl.colors.onMintDeep,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (count > 0) ...[
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: l10n.addRecentAdd(count),
              expand: true,
              loading: _busy,
              onPressed: _add,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 10g "Chọn từ Thư viện ảnh" ----------

/// Video limits from `publicConfig/limits` (D-011): no duration limit by default, 4 GB per file.
@immutable
class VideoLimits {
  const VideoLimits({this.maxDuration, this.maxBytes = 4 * 1024 * 1024 * 1024});
  final Duration? maxDuration;
  final int maxBytes;
}

final videoLimitsProvider = StreamProvider<VideoLimits>(
  (ref) => ref
      .watch(firestoreProvider)
      .doc('publicConfig/limits')
      .snapshots()
      .map((s) {
        final d = s.data() ?? const {};
        final sec = (d['videoMaxDurationSec'] as num?)?.toInt();
        return VideoLimits(
          maxDuration: sec == null ? null : Duration(seconds: sec),
          maxBytes:
              (d['videoMaxBytes'] as num?)?.toInt() ?? 4 * 1024 * 1024 * 1024,
        );
      }),
);

/// The photo-library picker behind "Chọn từ Thư viện ảnh"; the app uses wechat_assets_picker,
/// widget tests a fake (the native library cannot run there).
abstract interface class MediaLibraryPicker {
  /// Null when cancelled or the library is not shared.
  Future<List<PickedMedia>?> pick(
    BuildContext context, {
    required int max,
    required VideoLimits limits,
  });
}

final mediaLibraryPickerProvider = Provider<MediaLibraryPicker>(
  (_) => const WechatLibraryPicker(),
);

/// The provider's current value, waiting briefly for the first snapshot when nothing is
/// listening yet (an unlistened provider is paused).
Future<T> _current<T>(
  WidgetRef ref,
  StreamProvider<T> provider,
  T fallback,
) async {
  final now = ref.read(provider).value;
  if (now != null) return now;
  final sub = ref.listenManual(provider, (_, _) {});
  try {
    return await ref.read(provider.future).timeout(const Duration(seconds: 2));
  } on Object {
    return fallback;
  } finally {
    sub.close();
  }
}

Future<List<PickedMedia>?> pickFromLibrary(
  BuildContext context,
  WidgetRef ref,
) async {
  final picker = ref.read(mediaLibraryPickerProvider);
  // At most 30 items per add (R-102); video limits are server configuration (D-011).
  final (limits, video) = await (
    _current(ref, publicLimitsProvider, const PublicLimits()),
    _current(ref, videoLimitsProvider, const VideoLimits()),
  ).wait;
  if (!context.mounted) return null;
  return picker.pick(context, max: limits.mediaItemsPerAdd, limits: video);
}

const _libraryPermission = PermissionRequestOption(
  androidPermission: AndroidPermission(
    type: RequestType.common,
    mediaLocation: false,
  ),
);

/// wechat_assets_picker in the app's palette (Light / Night care) and language, with drag to
/// select: a horizontal drag (or long press, then drag) over the grid selects every photo it
/// passes, like Photos; starting on a selected one deselects instead.
class WechatLibraryPicker implements MediaLibraryPicker {
  const WechatLibraryPicker();

  @override
  Future<List<PickedMedia>?> pick(
    BuildContext context, {
    required int max,
    required VideoLimits limits,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    PermissionState permission;
    try {
      permission = await PhotoManager.requestPermissionExtend(
        requestOption: _libraryPermission,
      );
    } on Object {
      permission = PermissionState.denied;
    }
    if (!context.mounted) return null;
    if (!permission.hasAccess) {
      await _showNoAccess(context);
      return null;
    }

    var lastToast = DateTime(0);
    void toast(String message) {
      // Drag to select asks for many items at once: one toast, not one per item.
      final now = DateTime.now();
      if (now.difference(lastToast) < const Duration(seconds: 2)) return;
      lastToast = now;
      toaster.show(message: message);
    }

    final provider = DefaultAssetPickerProvider(
      maxAssets: max,
      pageSize: 120,
      requestType: RequestType.common,
      initializeDelayDuration: const Duration(milliseconds: 250),
    );
    final delegate = _ClPickerDelegate(
      provider: provider,
      initialPermission: permission,
      l10n: l10n,
      pickerTheme: _pickerTheme(context),
      textDelegate: _pickerText(context, l10n),
      locale: Localizations.maybeLocaleOf(context),
      selectPredicate: (_, asset, selected) {
        if (selected) return true;
        if (provider.selectedAssets.length >= max) {
          toast(l10n.pickLimit(max));
          return false;
        }
        final longest = limits.maxDuration;
        if (asset.type == AssetType.video &&
            longest != null &&
            asset.videoDuration > longest) {
          toast(l10n.pickVideoTooLong(videoDuration(longest.inMilliseconds)));
          return false;
        }
        return true;
      },
    );
    final List<AssetEntity>? assets;
    try {
      assets =
          await AssetPicker.pickAssetsWithDelegate<
            AssetEntity,
            AssetPathEntity,
            DefaultAssetPickerProvider,
            _ClPickerDelegate
          >(
            context,
            delegate: delegate,
            permissionRequestOption: _libraryPermission,
          );
    } on StateError {
      // Access was withdrawn between the check and the picker.
      if (context.mounted) await _showNoAccess(context);
      return null;
    }
    if (assets == null || assets.isEmpty) return null;

    // iCloud originals may download first: say so when it takes a moment.
    final slow = Timer(
      const Duration(milliseconds: 400),
      () => toaster.show(message: l10n.pickPreparing),
    );
    final out = <PickedMedia>[];
    var tooBig = false;
    try {
      for (final a in assets) {
        final p = await _fromAsset(a, null);
        if (p == null) continue;
        if (p.type == MediaKind.video &&
            await p.file.length() > limits.maxBytes) {
          tooBig = true; // D-011: the client refuses what the server would.
          continue;
        }
        out.add(p);
      }
    } finally {
      slow.cancel();
    }
    if (tooBig) {
      toaster.show(message: l10n.pickVideoTooBig(_size(limits.maxBytes)));
    } else if (out.isNotEmpty) {
      dismissClToasts();
    }
    return out;
  }
}

String _size(int bytes) {
  const gb = 1024 * 1024 * 1024;
  const mb = 1024 * 1024;
  return bytes >= gb
      ? '${(bytes / gb).round()} GB'
      : '${(bytes / mb).round()} MB';
}

/// Denied: what the library is for and the way to Settings (10g; nothing is drawn for it).
Future<void> _showNoAccess(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClEmptyState(
            icon: ClIcons.memories,
            title: l10n.addLibrary,
            message: l10n.pickNoAccess,
          ),
          ClButton(
            label: l10n.actionOpenSettings,
            expand: true,
            onPressed: () {
              Navigator.of(sheet).pop();
              unawaited(PhotoManager.openSetting());
            },
          ),
        ],
      ),
    );
  },
);

/// The picker's Material theme from the current palette, so Night care stays dark and calm.
ThemeData _pickerTheme(BuildContext context) {
  final base = Theme.of(context);
  final cl = context.cl;
  final c = cl.colors;
  final overlay = cl.isNightCare
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;
  return base.copyWith(
    primaryColor: c.surface,
    canvasColor: c.cloud,
    scaffoldBackgroundColor: c.cloud,
    cardColor: c.surface,
    // The grid's video and GIF fades.
    splashColor: Colors.black54,
    focusColor: c.surface2,
    // The ring of an unselected item sits on the photo.
    unselectedWidgetColor: Colors.white,
    iconTheme: IconThemeData(color: c.ink),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: c.surface,
      foregroundColor: c.ink,
      elevation: 0,
      systemOverlayStyle: overlay,
      iconTheme: IconThemeData(color: c.ink),
    ),
    bottomAppBarTheme: base.bottomAppBarTheme.copyWith(color: c.surface),
    colorScheme: base.colorScheme.copyWith(
      // A selected item gets a soft veil of the background; the badge is mint.
      primary: c.cloud,
      secondary: c.mintDeep,
      onSecondary: c.onMintDeep,
      surface: c.surface,
    ),
  );
}

/// The package's Vietnamese or English copy for the app locale (D-012), with the strings the
/// app already says its own way taken from ARB.
AssetPickerTextDelegate _pickerText(
  BuildContext context,
  AppLocalizations l10n,
) => Localizations.localeOf(context).languageCode == 'en'
    ? _EnPickerText(l10n)
    : _ViPickerText(l10n);

mixin _ClPickerCopy on AssetPickerTextDelegate {
  AppLocalizations get l10n;

  @override
  String get confirm => l10n.pickConfirm;
  @override
  String get cancel => l10n.actionCancel;
  @override
  String get emptyList => l10n.pickEmpty;
  @override
  String get unableToAccessAll => l10n.pickNoAccess;
  @override
  String get accessAllTip => l10n.pickLimited;
  @override
  String get viewingLimitedAssetsTip => l10n.pickLimited;
  @override
  String get changeAccessibleLimitedAssets => l10n.pickChooseMore;
  @override
  String get goToSystemSettings => l10n.actionOpenSettings;
  @override
  String get accessiblePathName => l10n.pickRecent;
}

class _ViPickerText extends VietnameseAssetPickerTextDelegate
    with _ClPickerCopy {
  _ViPickerText(this.l10n);
  @override
  final AppLocalizations l10n;
}

class _EnPickerText extends EnglishAssetPickerTextDelegate with _ClPickerCopy {
  _EnPickerText(this.l10n);
  @override
  final AppLocalizations l10n;
}

class _ClPickerDelegate
    extends DefaultAssetPickerBuilderDelegate<DefaultAssetPickerProvider> {
  _ClPickerDelegate({
    required super.provider,
    required super.initialPermission,
    required this.l10n,
    required super.pickerTheme,
    required super.textDelegate,
    required super.locale,
    required super.selectPredicate,
  }) : super(
         gridCount: 4,
         // Tap selects (10g); drag across thumbnails selects many at once.
         specialPickerType: SpecialPickerType.noPreview,
         dragToSelect: true,
         gridThumbnailSize: const ThumbnailSize.square(240),
         // The limited state is a bar under the grid, not a blocking overlay.
         limitedPermissionOverlayPredicate: (_) => false,
         pathNameBuilder: (path) => path.isAll ? l10n.pickRecent : path.name,
       );

  final AppLocalizations l10n;

  @override
  Widget accessLimitedBottomTip(BuildContext context) {
    final cl = context.cl;
    return Container(
      height: permissionLimitedBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      color: cl.colors.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.pickLimited,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          ClButton(
            label: l10n.pickChooseMore,
            style: ClButtonStyle.plain,
            // The picker refreshes itself when the shared set changes.
            onPressed: () => unawaited(PhotoManager.presentLimited()),
          ),
        ],
      ),
    );
  }

  @override
  Widget confirmButton(BuildContext context) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final cl = context.cl;
      final selected = provider.selectedAssets;
      final videos = selected.where((a) => a.type == AssetType.video).length;
      final enabled = selected.isNotEmpty;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 40,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                enabled
                    ? l10n.pickSummary(
                        selected.length,
                        selected.length - videos,
                        videos,
                      )
                    : l10n.pickMax(provider.maxAssets),
                overflow: TextOverflow.ellipsis,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            ClPressable(
              onPressed: enabled
                  ? () => Navigator.maybeOf(context)?.maybePop(selected)
                  : null,
              semanticLabel: enabled
                  ? l10n.pickAdd(selected.length)
                  : l10n.pickConfirm,
              minSize: const Size(0, ClSpace.tapMin),
              child: AnimatedContainer(
                duration: context.motion(ClMotion.quick),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled ? cl.colors.mintDeep : cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  enabled ? l10n.pickAdd(selected.length) : l10n.pickConfirm,
                  style: cl.text.bodyStrong.copyWith(
                    color: enabled ? cl.colors.onMintDeep : cl.colors.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------- "Chọn từ Tệp" ----------

Future<List<PickedMedia>?> pickFromFiles(
  BuildContext context,
  WidgetRef ref,
) async {
  final max = ref.read(publicLimitsProvider).value?.mediaItemsPerAdd ?? 30;
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final files = await FilePicker.pickFiles(type: FileType.media);
  if (files.isEmpty) return null;
  final out = <PickedMedia>[];
  for (final f in files) {
    final path = f.path;
    final kind = _kindOf(f.name);
    if (path == null || kind == null) continue;
    final file = File(path);
    out.add(
      PickedMedia(
        file: file,
        type: kind,
        name: f.name,
        captureAt: (await file.lastModified()),
      ),
    );
  }
  if (out.length > max) {
    toaster.show(message: l10n.pickLimit(max));
    return out.take(max).toList();
  }
  return out;
}

// ---------- 10a3 camera (until the in-app burst camera lands) ----------

/// The system camera (ios/Runner/CameraCapture.swift): photo or video in one screen, video
/// length capped by the server limit (D-011). Elsewhere (Android) one photo via image_picker.
const _camera = MethodChannel('childlife/camera');

/// The system camera; the in-app burst camera (10a3) replaces this.
Future<List<PickedMedia>?> captureWithCamera(
  BuildContext context,
  String nickname,
) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  if (Platform.isIOS) {
    final container = ProviderScope.containerOf(context, listen: false);
    var limits = const VideoLimits();
    final sub = container.listen(videoLimitsProvider, (_, _) {});
    try {
      limits = await container
          .read(videoLimitsProvider.future)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Offline: no length cap from here; the size check below still applies.
    } finally {
      sub.close();
    }
    try {
      final r = await _camera.invokeMapMethod<String, Object?>('capture', {
        'maxDurationSec': limits.maxDuration?.inSeconds,
      });
      if (r == null) return null;
      final file = File(r['path']! as String);
      final video = r['kind'] == 'video';
      if (video && await file.length() > limits.maxBytes) {
        toaster.show(message: l10n.pickVideoTooBig(_size(limits.maxBytes)));
        return null;
      }
      return [
        PickedMedia(
          file: file,
          type: video ? MediaKind.video : MediaKind.photo,
          name: r['name']! as String,
          captureAt: DateTime.now(),
          durationMs: (r['durationMs'] as num?)?.toInt(),
          width: (r['width'] as num?)?.toInt(),
          height: (r['height'] as num?)?.toInt(),
        ),
      ];
    } on Object {
      toaster.show(message: l10n.camUnavailable);
      return null;
    }
  }
  try {
    final shot = await ImagePicker().pickImage(source: ImageSource.camera);
    if (shot == null) return null;
    return [
      PickedMedia(
        file: File(shot.path),
        type: MediaKind.photo,
        name: shot.name,
        captureAt: DateTime.now(),
      ),
    ];
  } on Object {
    toaster.show(message: l10n.camUnavailable);
    return null;
  }
}
