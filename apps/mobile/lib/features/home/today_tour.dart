import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_misc.dart';
import '../../l10n/app_localizations.dart';

/// What the first-run tour points at (18 / 18b / 18c).
abstract final class TourTargets {
  static final bottle = GlobalKey(debugLabel: 'tour.bottle');
  static final growth = GlobalKey(debugLabel: 'tour.growth');
  static final quickLog = GlobalKey(debugLabel: 'tour.quickLog');
}

const _kTourDone = 'tour.today.done';

/// Seen once per device; also ends with the first log ("Coachmark tắt sau lần ghi đầu tiên").
final todayTourDoneProvider = NotifierProvider<TodayTourDone, bool>(
  TodayTourDone.new,
);

class TodayTourDone extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_kTourDone) ?? false;

  void finish() {
    ref.read(sharedPreferencesProvider).setBool(_kTourDone, true);
    state = true;
  }
}

/// 18 → 18b → 18c: scrim with a spotlight on the Bú bình tile, the Tăng trưởng tile and "+",
/// with a TourTip (23:349) each. Steps whose target is not on screen are skipped.
class TodayTour extends ConsumerStatefulWidget {
  const TodayTour({required this.babyNickname, super.key});
  final String babyNickname;

  @override
  ConsumerState<TodayTour> createState() => _TodayTourState();
}

class _TodayTourState extends ConsumerState<TodayTour> {
  int _step = 0;
  Rect? _hole;

  List<GlobalKey> get _targets => [
    TourTargets.bottle,
    TourTargets.growth,
    TourTargets.quickLog,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  int _attempts = 0;

  /// Finds the current (or next visible) target's rect in this overlay's coordinates. Tiles
  /// may still be loading, so each target gets a few frames before its step is skipped.
  void _measure() {
    if (!mounted) return;
    final me = context.findRenderObject() as RenderBox?;
    while (_step < _targets.length) {
      final box =
          _targets[_step].currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && me != null && me.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero, ancestor: me);
        _attempts = 0;
        setState(() => _hole = (topLeft & box.size).inflate(4));
        return;
      }
      if (_attempts++ < 20) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        WidgetsBinding.instance.scheduleFrame();
        return;
      }
      _attempts = 0;
      _step++;
    }
    ref.read(todayTourDoneProvider.notifier).finish();
  }

  void _next() {
    _step++;
    _hole = null;
    _measure();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final hole = _hole;
    if (hole == null) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final (title, body) = switch (_step) {
      0 => (l10n.tour1Title, l10n.tour1Body),
      1 => (l10n.tour2Title(widget.babyNickname), l10n.tour2Body),
      _ => (l10n.tour3Title, l10n.tour3Body),
    };
    const tipWidth = 300.0;
    final below = hole.center.dy < size.height / 2;
    final left = (hole.center.dx - tipWidth / 2).clamp(
      ClSpace.s4,
      size.width - tipWidth - ClSpace.s4,
    );
    final last = _step == _targets.length - 1;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                scrim: cl.colors.scrim,
                ring: cl.colors.mint,
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: below ? hole.bottom + ClSpace.s2 : null,
          bottom: below ? null : size.height - hole.top + ClSpace.s2,
          child: Semantics(
            liveRegion: true,
            child: ClTourTip(
              step: l10n.tourStep(_step + 1),
              title: title,
              body: body,
              skipLabel: l10n.actionSkip,
              nextLabel: last ? l10n.tourStart : l10n.actionNext,
              onSkip: () => ref.read(todayTourDoneProvider.notifier).finish(),
              onNext: last
                  ? () => ref.read(todayTourDoneProvider.notifier).finish()
                  : _next,
              pointerUp: below,
              pointerX: (hole.center.dx - left - 10).clamp(16, tipWidth - 36),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
  });

  final Rect hole;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = RRect.fromRectAndRadius(
      hole,
      const Radius.circular(ClRadius.tile + 4),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(cut),
      ),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      cut,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.scrim != scrim;
}
