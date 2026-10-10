import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
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
  );
}

// ---------- "Ảnh mới chụp hôm nay" (10a2) ----------

/// What the recent strip picked; read by the add sheet after it closes.
List<PickedMedia>? lastRecentPick;

/// Today's photos and videos, only when the library is already shared (never prompts here).
class RecentToday extends StatefulWidget {
  const RecentToday({required this.zone, required this.onPick, super.key});
  final String zone;
  final void Function(PickedMedia picked) onPick;

  @override
  State<RecentToday> createState() => _RecentTodayState();
}

class _RecentTodayState extends State<RecentToday> {
  List<(AssetEntity, Uint8List?)>? _assets;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
      if (!state.hasAccess) return;
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
      if (paths.isEmpty) return;
      final assets = await paths.first.getAssetListRange(start: 0, end: 10);
      final out = <(AssetEntity, Uint8List?)>[];
      for (final a in assets) {
        out.add((
          a,
          await a.thumbnailDataWithSize(const ThumbnailSize.square(160)),
        ));
      }
      if (mounted && out.isNotEmpty) setState(() => _assets = out);
    } on Object {
      // No library on this device: no strip.
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = _assets;
    if (assets == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.addRecent, style: cl.text.bodyStrong),
              const Spacer(),
              Text(
                l10n.addRecentHint,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: assets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (a, thumb) = assets[i];
                return ClPressable(
                  onPressed: () async {
                    final p = await _fromAsset(a, thumb);
                    if (p == null) return;
                    lastRecentPick = [p];
                    widget.onPick(p);
                  },
                  semanticLabel: l10n.addRecentHint,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ClRadius.sm),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: thumb == null
                          ? ColoredBox(color: cl.colors.surface2)
                          : Image.memory(thumb, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 10g "Chọn từ Thư viện ảnh" ----------

Future<List<PickedMedia>?> pickFromLibrary(
  BuildContext context,
  WidgetRef ref,
) {
  final max = ref.read(publicLimitsProvider).value?.mediaItemsPerAdd ?? 30;
  return Navigator.of(context, rootNavigator: true).push<List<PickedMedia>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LibraryPicker(max: max),
    ),
  );
}

enum _Source { recent, videos, album }

class LibraryPicker extends StatefulWidget {
  const LibraryPicker({required this.max, super.key});
  final int max;

  @override
  State<LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<LibraryPicker> {
  PermissionState? _permission;
  var _source = _Source.recent;
  AssetPathEntity? _path;
  AssetPathEntity? _album;
  final _assets = <AssetEntity>[];
  final _thumbs = <String, Uint8List?>{};
  final _selected = <AssetEntity>[];
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    setState(() => _permission = state);
    if (state.hasAccess) await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _assets.clear();
    });
    final order = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate)],
    );
    AssetPathEntity? path;
    if (_source == _Source.album && _album != null) {
      path = _album;
    } else {
      final paths = await PhotoManager.getAssetPathList(
        type: _source == _Source.videos
            ? RequestType.video
            : RequestType.common,
        onlyAll: true,
        filterOption: order,
      );
      path = paths.firstOrNull;
    }
    _path = path;
    if (path != null) {
      _assets.addAll(await path.getAssetListPaged(page: 0, size: 120));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _more() async {
    final path = _path;
    if (path == null || _loading) return;
    final total = await path.assetCountAsync;
    if (_assets.length >= total) return;
    _loading = true;
    final next = await path.getAssetListPaged(
      page: _assets.length ~/ 120,
      size: 120,
    );
    if (!mounted) return;
    setState(() {
      _assets.addAll(next.where((a) => !_assets.any((b) => b.id == a.id)));
      _loading = false;
    });
  }

  Future<Uint8List?> _thumb(AssetEntity a) async => _thumbs[a.id] ??= await a
      .thumbnailDataWithSize(const ThumbnailSize.square(240));

  void _toggle(AssetEntity a) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (_selected.any((s) => s.id == a.id)) {
        _selected.removeWhere((s) => s.id == a.id);
      } else if (_selected.length >= widget.max) {
        showClToast(context, message: l10n.pickLimit(widget.max));
      } else {
        _selected.add(a);
      }
    });
  }

  Future<void> _pickAlbum() async {
    final l10n = AppLocalizations.of(context);
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
    if (!mounted) return;
    final picked = await showClSheet<AssetPathEntity>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.pickAlbumsTitle),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in paths.where((p) => !p.isAll))
                  ListTile(
                    title: Text(p.name, style: sheet.cl.text.body),
                    onTap: () => Navigator.of(sheet).pop(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    _album = picked;
    _source = _Source.album;
    await _load();
  }

  Future<void> _done() async {
    setState(() => _busy = true);
    final out = <PickedMedia>[];
    for (final a in _selected) {
      final p = await _fromAsset(a, _thumbs[a.id]);
      if (p != null) out.add(p);
    }
    if (mounted) Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final permission = _permission;
    final photos = _selected.where((a) => a.type != AssetType.video).length;
    final videos = _selected.length - photos;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s2,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: Row(
                children: [
                  ClButton(
                    label: l10n.actionCancel,
                    style: ClButtonStyle.plain,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      switch (_source) {
                        _Source.recent => l10n.pickRecent,
                        _Source.videos => l10n.pickVideos,
                        _Source.album => _album?.name ?? l10n.pickAlbums,
                      },
                      textAlign: TextAlign.center,
                      style: cl.text.headline,
                    ),
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s4,
                vertical: ClSpace.s2,
              ),
              child: Row(
                children: [
                  ClFilterChip(
                    label: l10n.pickRecent,
                    selected: _source == _Source.recent,
                    onTap: () {
                      _source = _Source.recent;
                      unawaited(_load());
                    },
                  ),
                  const SizedBox(width: ClSpace.s2),
                  ClFilterChip(
                    label: l10n.pickVideos,
                    selected: _source == _Source.videos,
                    onTap: () {
                      _source = _Source.videos;
                      unawaited(_load());
                    },
                  ),
                  const SizedBox(width: ClSpace.s2),
                  ClFilterChip(
                    label: l10n.pickAlbums,
                    selected: _source == _Source.album,
                    onTap: _pickAlbum,
                  ),
                ],
              ),
            ),
            if (permission == PermissionState.limited)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.pickLimited,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ),
                    ClButton(
                      label: l10n.pickChooseMore,
                      style: ClButtonStyle.plain,
                      onPressed: () async {
                        await PhotoManager.presentLimited();
                        await _load();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: permission == null
                  ? const Center(child: CircularProgressIndicator())
                  : !permission.hasAccess
                  ? Padding(
                      padding: const EdgeInsets.all(ClSpace.s6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClEmptyState(
                            icon: ClIcons.memories,
                            title: l10n.addLibrary,
                            message: l10n.pickNoAccess,
                          ),
                          ClButton(
                            label: l10n.actionOpenSettings,
                            onPressed: PhotoManager.openSetting,
                          ),
                        ],
                      ),
                    )
                  : _assets.isEmpty && !_loading
                  ? Center(
                      child: Text(
                        l10n.pickEmpty,
                        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.extentAfter < 600) unawaited(_more());
                        return false;
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                            ),
                        itemCount: _assets.length,
                        itemBuilder: (_, i) {
                          final a = _assets[i];
                          final on = _selected.any((s) => s.id == a.id);
                          return ClPressable(
                            onPressed: () => _toggle(a),
                            selected: on,
                            haptic: false,
                            minSize: Size.zero,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FutureBuilder<Uint8List?>(
                                  future: _thumb(a),
                                  builder: (_, s) => s.data == null
                                      ? ColoredBox(color: cl.colors.surface2)
                                      : Image.memory(
                                          s.data!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                ),
                                if (a.type == AssetType.video)
                                  Positioned(
                                    left: 4,
                                    bottom: 4,
                                    child: Text(
                                      videoDuration(
                                        a.videoDuration.inMilliseconds,
                                      ),
                                      style: cl.text.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        shadows: const [Shadow(blurRadius: 4)],
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: on
                                          ? cl.colors.mintDeep
                                          : Colors.black26,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: on
                                        ? ClIcon(
                                            ClIcons.check,
                                            size: 14,
                                            color: cl.colors.onMintDeep,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  ClSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ClRadius.card),
                  ),
                  boxShadow: cl.shadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selected.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final thumb = _thumbs[_selected[i].id];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: thumb == null
                                  ? ColoredBox(color: cl.colors.surface2)
                                  : Image.memory(thumb, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: ClSpace.s2),
                    Row(
                      children: [
                        Text(
                          l10n.pickSummary(_selected.length, photos, videos),
                          style: cl.text.label,
                        ),
                        const Spacer(),
                        Text(
                          l10n.pickMax(widget.max),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s2),
                    ClButton(
                      label: l10n.pickAdd(_selected.length),
                      expand: true,
                      onPressed: _busy ? null : _done,
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

/// The system camera, one photo; the in-app burst camera (10a3) replaces this.
Future<List<PickedMedia>?> captureWithCamera(
  BuildContext context,
  String nickname,
) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
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
