import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'feedback_repository.dart';
import 'review_prompt.dart';

/// "A screenshot was taken": iOS `userDidTakeScreenshotNotification`, Android 14+
/// `ScreenCaptureCallback` (older Android has no such signal, so FB4 does not show there).
const screenshotChannel = MethodChannel('childlife/screenshot');

/// Where the app is and how to open FB2: the router (tests replace it).
final feedbackNavProvider =
    Provider<({String Function() location, void Function(String) push})>(
      (ref) => (
        location: () => ref
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        push: (location) => unawaited(ref.read(routerProvider).push(location)),
      ),
    );

/// FB4 shows at most once per app session.
abstract final class _Session {
  static bool shotOffered = false;
}

/// Tests start each case as a fresh session.
@visibleForTesting
void resetScreenshotSession() => _Session.shotOffered = false;

/// App-wide Góp ý & đánh giá (D-065): FB4's toast after a screenshot, and FB5's "the app was
/// opened" (active days, a just-updated version).
class FeedbackHost extends ConsumerStatefulWidget {
  const FeedbackHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<FeedbackHost> createState() => _FeedbackHostState();
}

class _FeedbackHostState extends ConsumerState<FeedbackHost> {
  final _capture = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  FeedbackShot? _shot;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    screenshotChannel.setMethodCallHandler((call) async {
      if (call.method == 'taken') unawaited(_taken());
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_opened()));
    unawaited(_opened());
  }

  @override
  void dispose() {
    screenshotChannel.setMethodCallHandler(null);
    _lifecycle.dispose();
    _hide?.cancel();
    super.dispose();
  }

  Future<void> _opened() async {
    final version = await ref
        .read(appVersionProvider.future)
        .catchError((_) => '');
    try {
      await ref.read(reviewPrompterProvider).opened(DateTime.now(), version);
    } on Object {
      // Preferences unavailable: the next launch counts.
    }
  }

  Future<void> _taken() async {
    if (_Session.shotOffered || !mounted) return;
    if (ref.read(sessionProvider) is! SessionSignedIn) return;
    if (ref
        .read(feedbackNavProvider)
        .location()
        .startsWith(Routes.meFeedback)) {
      return;
    }
    final shot = await _snapshot();
    if (shot == null || !mounted) return;
    _Session.shotOffered = true;
    setState(() => _shot = shot);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 8), _dismiss);
  }

  /// What is on screen now, as the attachment (the app's own pixels, at 1×).
  Future<FeedbackShot?> _snapshot() async {
    try {
      final boundary =
          _capture.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return null;
      return FeedbackShot(data.buffer.asUint8List(), png: true);
    } on Object catch (e) {
      debugPrint('screenshot capture: $e');
      return null;
    }
  }

  void _dismiss() {
    _hide?.cancel();
    if (mounted) setState(() => _shot = null);
  }

  void _report() {
    final shot = _shot;
    _dismiss();
    if (shot == null) return;
    ref.read(pendingShotProvider.notifier).set(shot);
    ref.read(feedbackNavProvider).push('${Routes.meFeedback}?type=bug');
  }

  @override
  Widget build(BuildContext context) {
    final shot = _shot;
    return Stack(
      children: [
        RepaintBoundary(key: _capture, child: widget.child),
        if (shot != null)
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            // Above the tab dock and its "+", never on them (owner, 2026-10-14).
            bottom: _aboveDock(context),
            child: ScreenshotToast(
              shot: shot,
              onReport: _report,
              onClose: _dismiss,
            ),
          ),
      ],
    );
  }
}

/// The tab dock's bar (68) and "+" sit on the home indicator inset (or 24 without one).
double _aboveDock(BuildContext context) {
  final inset = MediaQuery.paddingOf(context).bottom;
  return (inset > 0 ? inset : ClSpace.s6) +
      68 +
      ClTabDock.actionExtent +
      ClSpace.s2;
}

/// FB4 (477:6564): ink card, the screenshot as a 36 × 64 thumbnail, "Báo lỗi" and close.
class ScreenshotToast extends StatelessWidget {
  const ScreenshotToast({
    required this.shot,
    required this.onReport,
    required this.onClose,
    super.key,
  });

  final FeedbackShot shot;
  final VoidCallback onReport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final white = cl.colors.surface;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: cl.colors.ink,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 64,
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: white, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  shot.bytes,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fbShotTitle,
                      style: cl.text.label.copyWith(
                        color: white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.fbShotBody,
                      style: cl.text.caption.copyWith(
                        color: white.withValues(alpha: 0.7),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              ClPressable(
                onPressed: onReport,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s3,
                    vertical: ClSpace.s2,
                  ),
                  decoration: BoxDecoration(
                    color: cl.colors.mintDeep,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  child: Text(
                    l10n.fbTypeBug,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.onMintDeep,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              ClPressable(
                semanticLabel: l10n.a11yClose,
                onPressed: onClose,
                child: SizedBox(
                  width: 36,
                  height: ClSpace.tapMin,
                  child: Center(
                    child: ClIcon(ClIcons.close, size: 16, color: white),
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
