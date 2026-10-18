import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memory_models.dart' show MediaKind;
import '../memories/upload_queue.dart' show PickedMedia;

/// Photos and videos picked for a milestone and kept on this phone until "Tạo kỷ niệm", shown
/// from the phone's own files: a photo can be zoomed, a video plays with the system controls.
/// Once they are in Kỷ niệm, the record opens the Memories viewer instead.
Future<void> openPickedPreview(
  BuildContext context, {
  required List<PickedMedia> items,
  required int start,
}) {
  if (items.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) =>
          _PickedPreview(items: items, start: start.clamp(0, items.length - 1)),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _PickedPreview extends StatefulWidget {
  const _PickedPreview({required this.items, required this.start});
  final List<PickedMedia> items;
  final int start;

  @override
  State<_PickedPreview> createState() => _PickedPreviewState();
}

class _PickedPreviewState extends State<_PickedPreview> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return item.type == MediaKind.video
                  ? _LocalVideo(file: item.file, active: i == _index)
                  : InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: Image.file(
                          item.file,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClPressable(
                key: const Key('mtPreviewClose'),
                semanticLabel: l10n.a11yClose,
                onPressed: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const ClIcon(
                    ClIcons.close,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A video file on the phone, played with media_kit's adaptive controls; only the visible page
/// plays.
class _LocalVideo extends StatefulWidget {
  const _LocalVideo({required this.file, required this.active});
  final File file;
  final bool active;

  @override
  State<_LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<_LocalVideo> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  @override
  void initState() {
    super.initState();
    unawaited(_player.open(Media(widget.file.path), play: widget.active));
  }

  @override
  void didUpdateWidget(_LocalVideo old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active && !widget.active) {
      unawaited(_player.pause());
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Video(
    controller: _controller,
    controls: AdaptiveVideoControls,
    fill: Colors.black,
  );
}
