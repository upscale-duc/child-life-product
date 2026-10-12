import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';

/// Photos of the vaccination book / slip (VX 0, VX 3, VX 6; P-133). One per dose plus up to
/// [maxBookPhotos] of the whole book on the plan. They live at `babies/{babyId}/vaccines/{id}.jpg`
/// (Storage Rules: whoever reads care reads them, Cùng nuôi and Người chăm sóc add them, Cùng nuôi
/// remove them) and never appear in Kỷ niệm, story links or exports. Health data: no path,
/// size or file name is logged.
abstract class VaccinePhotoStore {
  /// The chosen photo as a ≤1600 px JPEG without metadata; null when cancelled.
  Future<Uint8List?> pick(ImageSource source);

  /// Uploads [jpeg] and returns its Storage path. [folder] `expenses` holds spending receipts
  /// (Chi tiêu 8c / 8k, same rules of handling).
  Future<String> upload(String babyId, Uint8List jpeg, {String folder});

  /// Best effort (Cùng nuôi only by Rules).
  Future<void> remove(String path);
}

const maxBookPhotos = 10;

class FirebaseVaccinePhotoStore implements VaccinePhotoStore {
  FirebaseVaccinePhotoStore([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    // Re-encode without EXIF (no location on a health document); legible yet well under 4 MB.
    return FlutterImageCompress.compressWithList(
      await file.readAsBytes(),
      minWidth: 1600,
      minHeight: 1600,
      quality: 82,
      keepExif: false,
    );
  }

  @override
  Future<String> upload(
    String babyId,
    Uint8List jpeg, {
    String folder = 'vaccines',
  }) async {
    final id = const Uuid().v4().replaceAll('-', '');
    final path = 'babies/$babyId/$folder/$id.jpg';
    await _storage
        .ref(path)
        .putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));
    _fresh[path] = jpeg;
    return path;
  }

  @override
  Future<void> remove(String path) async {
    _fresh.remove(path);
    try {
      await _storage.ref(path).delete();
    } on FirebaseException {
      // Not Cùng nuôi, offline or already gone: the record no longer points at it.
    }
  }
}

final vaccinePhotoStoreProvider = Provider<VaccinePhotoStore>(
  (ref) => FirebaseVaccinePhotoStore(),
);

/// Photos uploaded in this run, shown from memory instead of downloading them again.
final _fresh = <String, Uint8List>{};

ImageProvider vxPhotoImage(String path) {
  final bytes = _fresh[path];
  return bytes != null ? MemoryImage(bytes) : StorageImage(path);
}

/// "Chụp ảnh" / "Chọn từ thư viện", then pick, compress and upload. Null when cancelled or failed
/// (a toast says why).
Future<String?> addVxPhoto(
  BuildContext context,
  WidgetRef ref,
  String babyId, {
  void Function(bool busy)? onBusy,

  /// Chi tiêu: a receipt (title, privacy note and Storage folder of its own).
  bool receipt = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final source = await showClSheet<ImageSource>(
    context: context,
    builder: (sheet) => _SourceSheet(
      title: receipt ? l10n.spReceiptAdd : l10n.vxPhotoAdd,
      note: receipt ? l10n.spReceiptPrivate : l10n.vxPhotoPrivate,
    ),
  );
  if (source == null || !context.mounted) return null;
  final store = ref.read(vaccinePhotoStoreProvider);
  final toaster = ClToaster.of(context);
  try {
    final jpeg = await store.pick(source);
    if (jpeg == null) return null;
    onBusy?.call(true);
    return await store.upload(
      babyId,
      jpeg,
      folder: receipt ? 'expenses' : 'vaccines',
    );
  } on PlatformException catch (e) {
    final denied = e.code.contains('denied') || e.code.contains('access');
    toaster.show(
      message: denied
          ? (source == ImageSource.camera
                ? l10n.avatarCameraDenied
                : l10n.avatarLibraryDenied)
          : l10n.vxPhotoFailed,
      actionLabel: denied ? l10n.actionOpenSettings : null,
      onAction: denied ? openAppSettings : null,
    );
  } on Object {
    toaster.show(message: l10n.vxPhotoFailed);
  } finally {
    onBusy?.call(false);
  }
  return null;
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.title, required this.note});
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget action(ClIcons icon, String label, ImageSource source) =>
        ClPressable(
          semanticLabel: label,
          onPressed: () => Navigator.of(context).pop(source),
          child: Padding(
            padding: const EdgeInsets.all(ClSpace.s4),
            child: Row(
              children: [
                ClIcon(icon, size: 20, color: cl.colors.mintText),
                const SizedBox(width: ClSpace.s3),
                Expanded(child: Text(label, style: cl.text.body)),
                ClIcon(
                  ClIcons.chevronRight,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.card),
          ),
          child: Column(
            children: [
              action(ClIcons.camera, l10n.avatarCamera, ImageSource.camera),
              Container(height: 1, color: cl.colors.separator),
              action(ClIcons.memories, l10n.avatarLibrary, ImageSource.gallery),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClIcon(ClIcons.lock, size: 14, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s1),
            Flexible(
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

/// The design's dashed camera button: "Chụp sổ tiêm / phiếu tiêm" (VX 3, radius 14) and
/// "Chụp sổ tiêm chủng để lưu lại" (VX 0, radius 16).
class VxPhotoButton extends StatelessWidget {
  const VxPhotoButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.radius = 14,
    this.height = 48,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double radius;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      onPressed: busy ? null : onPressed,
      semanticLabel: busy ? l10n.vxPhotoUploading : label,
      child: CustomPaint(
        foregroundPainter: _DashedBorder(
          color: cl.colors.controlBorder,
          radius: radius,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cl.colors.mintText,
                  ),
                )
              else
                ClIcon(ClIcons.camera, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Flexible(
                child: Text(
                  busy ? l10n.vxPhotoUploading : label,
                  style: cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cl.colors.mintText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}

/// A 100 × 120 thumbnail (VX 6 "Ảnh sổ tiêm"); [onRemove] adds the corner "×" (VX 3, VX 0).
class VxPhotoThumb extends StatelessWidget {
  const VxPhotoThumb({
    required this.path,
    required this.onPressed,
    this.onRemove,
    this.width = 100,
    this.height = 120,
    super.key,
  });

  final String path;
  final VoidCallback onPressed;
  final VoidCallback? onRemove;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClPressable(
              onPressed: onPressed,
              semanticLabel: l10n.vxPhoto,
              // ClPressable centres its child: fill the tile.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image(
                  width: width,
                  height: height,
                  image: vxPhotoImage(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: cl.colors.surface2,
                    child: Center(
                      child: ClIcon(
                        ClIcons.camera,
                        size: 22,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                  frameBuilder: (_, child, frame, sync) =>
                      frame == null && !sync
                      ? ColoredBox(color: cl.colors.surface2)
                      : child,
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: ClPressable(
                onPressed: onRemove,
                semanticLabel: l10n.vxPhotoRemove,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const ClIcon(
                    ClIcons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full screen, pinch to zoom, swipe between [paths]; [onDelete] (Cùng nuôi) adds "Xoá ảnh".
Future<void> showVxPhotoViewer(
  BuildContext context,
  List<String> paths, {
  int index = 0,
  Future<void> Function(String path)? onDelete,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) =>
        _Viewer(paths: paths, index: index, onDelete: onDelete),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class _Viewer extends StatefulWidget {
  const _Viewer({required this.paths, required this.index, this.onDelete});
  final List<String> paths;
  final int index;
  final Future<void> Function(String path)? onDelete;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final _pages = PageController(initialPage: widget.index);
  late int _at = widget.index;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget round(ClIcons icon, String label, VoidCallback onTap) => ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: Colors.white),
      ),
    );
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _at = i),
              children: [
                for (final p in widget.paths)
                  InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image(image: vxPhotoImage(p), fit: BoxFit.contain),
                    ),
                  ),
              ],
            ),
            Positioned(
              top: ClSpace.s2,
              left: ClSpace.s4,
              right: ClSpace.s4,
              child: Row(
                children: [
                  round(
                    ClIcons.close,
                    l10n.a11yClose,
                    () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: widget.paths.length > 1
                        ? Text(
                            '${_at + 1} / ${widget.paths.length}',
                            textAlign: TextAlign.center,
                            style: cl.text.label.copyWith(color: Colors.white),
                          )
                        : const SizedBox(),
                  ),
                  if (widget.onDelete != null)
                    round(ClIcons.trash, l10n.vxPhotoDelete, () async {
                      final nav = Navigator.of(context);
                      await widget.onDelete!(widget.paths[_at]);
                      nav.pop();
                    })
                  else
                    const SizedBox(width: ClSpace.tapMin),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
