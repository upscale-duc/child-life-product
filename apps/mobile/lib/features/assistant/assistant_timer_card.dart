import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart'
    show careTimerProvider, timerClockProvider, timerTicksProvider;
import '../care/timer_models.dart';
import '../care/timer_screens.dart' show clockLabel;
import 'assistant_labels.dart' show hm;

/// Lumi 2026-10-16: the running timer inside a chat card ("Đang ngủ · 00:12:31"), live from the
/// same document the timer screen, Home tile and widgets read (`babies/{b}/timers/{type}`), so
/// a start from chat, the app or another phone shows the same. [sessionId] (when known) ties
/// the line to one session: another session running reads "Đang tính giờ từ 00:25", none
/// reads "Đồng hồ đã kết thúc". Elapsed time is computed per second from timestamps; nothing
/// is written.
class AsTimerLine extends ConsumerStatefulWidget {
  const AsTimerLine({
    required this.babyId,
    required this.type,
    required this.zone,
    this.sessionId,
    super.key,
  });

  final String babyId;
  final TimerType type;
  final String zone;
  final String? sessionId;

  @override
  ConsumerState<AsTimerLine> createState() => _AsTimerLineState();
}

class _AsTimerLineState extends ConsumerState<AsTimerLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (ref.read(timerTicksProvider)) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final timer = ref
        .watch(careTimerProvider((widget.babyId, widget.type)))
        .value;
    final now = ref.read(timerClockProvider)();
    final mine =
        timer != null &&
        (widget.sessionId == null || timer.sessionId == widget.sessionId);
    final sleep = widget.type == TimerType.sleep;
    final text = timer == null
        ? l10n.asTimerEnded
        : mine
        ? (sleep ? l10n.asTimerSleeping : l10n.asTimerFeeding)(
            clockLabel(timer.totalAt(now), hours: sleep),
          )
        : l10n.asTimerRunningSince(hm(timer.startedAt, widget.zone));
    final running = mine && !timer.paused;
    return Semantics(
      liveRegion: false,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: running ? c.mintDeep : c.inkMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              key: const ValueKey('as.timer.live'),
              style: cl.text.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: running ? c.ink : c.inkMuted,
              ),
            ),
          ),
          if (running) ...[
            const SizedBox(width: 6),
            ClIcon(
              sleep ? ClIcons.sleep : ClIcons.drop,
              size: 14,
              color: c.inkMuted,
            ),
          ],
        ],
      ),
    );
  }
}
