import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart' show onlineProvider;
import '../vaccines/vaccine_photos.dart'
    show
        VaccinePhotoStore,
        VxPhotoButton,
        showVxPhotoViewer,
        vaccinePhotoStoreProvider,
        vxPhotoImage;
import 'solids_models.dart';

/// Meal photos (owner: allowed, D-085 #2; plan §3 #5): one photo per meal, taken or picked in
/// 5c, re-encoded as a JPEG without metadata (≤ 1600 px, well under [sdPhotoMaxBytes]) and
/// uploaded to `babies/{babyId}/meals/{32 hex}.jpg`, the Sổ tiêm chủng book-photo pattern
/// (`vaccine_photos.dart`, same store): the upload happens in the sheet, "Lưu bữa" waits for it,
/// and offline the meal saves without a photo (adding one needs the network).
///
/// Storage Rules: members who read care read them, Cùng nuôi and Người chăm sóc add them, only
/// Cùng nuôi delete them. So a Cùng nuôi who replaces or removes a photo deletes the old object
/// when the meal is saved; a caregiver only clears `photoPath` (the bin purge removes photos of
/// deleted meals). Child data: no path, size or file name is ever logged.

/// The Storage Rules' limit.
const sdPhotoMaxBytes = 4 * 1024 * 1024;

/// "Chụp ảnh" / "Chọn từ thư viện", pick, compress and upload: the Storage path, or null when
/// cancelled or failed (a toast says why; the meal still saves).
Future<String?> sdAddMealPhoto(
  BuildContext context,
  WidgetRef ref,
  String babyId, {
  void Function(bool busy)? onBusy,
}) async {
  final l10n = AppLocalizations.of(context);
  final source = await showClSheet<ImageSource>(
    context: context,
    builder: (_) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return null;
  final store = ref.read(vaccinePhotoStoreProvider);
  final toaster = ClToaster.of(context);
  try {
    final jpeg = await store.pick(source);
    if (jpeg == null) return null;
    if (jpeg.isEmpty || jpeg.length > sdPhotoMaxBytes) {
      toaster.show(message: l10n.sdPhotoFailed);
      return null;
    }
    onBusy?.call(true);
    return await store.upload(babyId, jpeg, folder: 'meals');
  } on PlatformException catch (e) {
    final denied = e.code.contains('denied') || e.code.contains('access');
    toaster.show(
      message: denied
          ? (source == ImageSource.camera
                ? l10n.avatarCameraDenied
                : l10n.avatarLibraryDenied)
          : l10n.sdPhotoFailed,
      actionLabel: denied ? l10n.actionOpenSettings : null,
      onAction: denied ? openAppSettings : null,
    );
  } on Object {
    toaster.show(message: l10n.sdPhotoFailed);
  } finally {
    onBusy?.call(false);
  }
  return null;
}

/// Deletes [paths] from Storage when [manages] (Cùng nuôi; Storage Rules refuse anyone else).
/// Best effort: offline or already gone, the meal no longer points at them.
void sdDropPhotos(
  VaccinePhotoStore store,
  Iterable<String?> paths, {
  required bool manages,
}) {
  if (!manages) return;
  for (final p in {...paths}) {
    if (p != null && sdMealPhotoPath(p)) unawaited(store.remove(p));
  }
}

/// The 5c photo field: the dashed "Thêm ảnh bữa ăn" button, or the photo with "×" and "Đổi ảnh".
/// [onChanged] gets a new path (just uploaded) or null (removed).
class SdPhotoField extends ConsumerWidget {
  const SdPhotoField({
    required this.babyId,
    required this.path,
    required this.busy,
    required this.onBusy,
    required this.onChanged,
    super.key,
  });

  final String babyId;
  final String? path;
  final bool busy;
  final ValueChanged<bool> onBusy;
  final ValueChanged<String?> onChanged;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final p = await sdAddMealPhoto(context, ref, babyId, onBusy: onBusy);
    if (p != null) onChanged(p);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final online = ref.watch(onlineProvider).value ?? true;
    final current = path;
    if (current == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VxPhotoButton(
            key: const Key('sdPhotoAdd'),
            label: l10n.sdPhotoAdd,
            busy: busy,
            onPressed: online ? () => unawaited(_add(context, ref)) : null,
          ),
          if (!online)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.sdPhotoOffline,
                key: const Key('sdPhotoOffline'),
                style: cl.text.caption.copyWith(
                  fontSize: 12,
                  color: cl.colors.inkMuted,
                ),
              ),
            ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SdPhotoTile(
          key: const Key('sdPhotoThumb'),
          path: current,
          size: 88,
          onRemove: busy ? null : () => onChanged(null),
        ),
        const SizedBox(width: ClSpace.s3),
        if (busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cl.colors.mintText,
            ),
          )
        else if (online)
          ClButton(
            key: const Key('sdPhotoReplace'),
            label: l10n.sdPhotoReplace,
            icon: ClIcons.camera,
            style: ClButtonStyle.plain,
            onPressed: () => unawaited(_add(context, ref)),
          ),
      ],
    );
  }
}

/// A meal photo: square, rounded, opens full screen; the ingredient icon while it loads or when
/// it cannot load (offline, removed). [onRemove] adds the corner "×".
class SdPhotoTile extends StatelessWidget {
  const SdPhotoTile({
    required this.path,
    this.size = 56,
    this.width,
    this.onRemove,
    this.open = true,
    super.key,
  });

  final String path;
  final double size;

  /// Wider than tall (meal detail): the full width.
  final double? width;
  final VoidCallback? onRemove;

  /// Tap opens the photo full screen (off inside a card that opens the meal).
  final bool open;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(size >= 56 ? 14 : 12);
    final placeholder = ColoredBox(
      color: cl.care.bottle.soft,
      child: Center(
        child: ClIcon(
          ClIcons.feed,
          size: (size * 0.42).clamp(16, 40),
          color: cl.care.bottle.ink,
        ),
      ),
    );
    final image = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width ?? size,
        height: size,
        child: Image(
          image: vxPhotoImage(path),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => placeholder,
          frameBuilder: (_, child, frame, sync) =>
              frame == null && !sync ? placeholder : child,
        ),
      ),
    );
    final tile = open
        ? ClPressable(
            onPressed: () => unawaited(showVxPhotoViewer(context, [path])),
            semanticLabel: l10n.sdPhoto,
            child: image,
          )
        : Semantics(label: l10n.sdPhoto, image: true, child: image);
    if (onRemove == null) return tile;
    return SizedBox(
      width: width ?? size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(child: tile),
          Positioned(
            top: 4,
            right: 4,
            child: ClPressable(
              key: const Key('sdPhotoRemove'),
              onPressed: onRemove,
              semanticLabel: l10n.sdPhotoRemove,
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

/// "Chụp ảnh" / "Chọn từ thư viện" with the privacy line (as the book photo's sheet).
class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget action(Key key, ClIcons icon, String label, ImageSource source) =>
        ClPressable(
          key: key,
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
        ClSheetHeader(title: l10n.sdPhotoAdd),
        Container(
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.card),
          ),
          child: Column(
            children: [
              action(
                const Key('sdPhotoCamera'),
                ClIcons.camera,
                l10n.avatarCamera,
                ImageSource.camera,
              ),
              Container(height: 1, color: cl.colors.separator),
              action(
                const Key('sdPhotoLibrary'),
                ClIcons.memories,
                l10n.avatarLibrary,
                ImageSource.gallery,
              ),
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
                l10n.sdPhotoPrivate,
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
