import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/navigation.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/motion.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_status.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_repository.dart';
import '../baby/time_zones.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'care_format.dart';
import 'care_models.dart';
import 'care_repository.dart';
import 'care_screens.dart';
import 'care_sheets.dart';
import 'sleep_ambient.dart';
import 'timer_models.dart';

/// "01:27:06" for sleep; "11:52" (or "1:05:20") for feeds.
String clockLabel(Duration d, {bool hours = false}) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  if (hours) return '${two(h)}:${two(m)}:${two(s)}';
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Opens the running timer of [type], or starts one (P-011: if someone else started it first,
/// the server refuses this start and the app follows theirs). Everything is captured from
/// [context] up front, so a sheet may close right after calling it.
void openOrStartTimer(
  BuildContext context,
  TimerType type, {
  Side side = Side.left,
  bool replace = false,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final router = GoRouter.of(context);
  final toaster = ClToaster.of(context);
  final l10n = AppLocalizations.of(context);
  final me = container.read(selectedMembershipProvider);
  if (me == null) return;
  final running = container.read(careTimerProvider((me.babyId, type))).value;
  if (running == null) {
    container
        .read(careRepositoryProvider)
        .startTimer(
          CareTimer.start(type: type, me: me, now: DateTime.now(), side: side),
          onError: (e) => toaster.show(
            message: careWriteFailed(l10n, '', CareWrite.timer, e),
            error: true,
          ),
        );
  }
  final location = '${Routes.timer}/${type.name}';
  replace ? router.pushReplacement(location) : router.push(location);
}

/// 25 Timer ngủ (47:3028), 23b Timer bú mẹ (112:11135), 23c Timer hút sữa (113:11207), and 9c
/// when the timer has not reached the server. Elapsed time is computed from timestamps; the
/// sleep ring "breathes" (Motion spec P10 272:368, static with Reduce Motion). Live Activities
/// are a later slice (SP-1).
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({required this.type, super.key});
  final TimerType type;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _tick;
  Timer? _gone;
  String? _sessionSeen;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(timerTicksProvider)) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    // Opened from a widget, notification or Live Activity after the timer ended elsewhere: no
    // timer ever shows up, so leave rather than stay blank.
    _gone = Timer(const Duration(seconds: 3), () {
      final me = ref.read(selectedMembershipProvider);
      if (!mounted || _leaving || _sessionSeen != null || me == null) return;
      final timer = ref.read(careTimerProvider((me.babyId, widget.type)));
      if (timer.hasValue && timer.value == null) context.popOrToday();
    });
  }

  DateTime _now() => ref.read(timerClockProvider)();

  @override
  void dispose() {
    _tick?.cancel();
    _gone?.cancel();
    super.dispose();
  }

  CareRepository get _repo => ref.read(careRepositoryProvider);

  void _failed(Object e) {
    if (mounted) {
      showClToast(
        context,
        message: careWriteFailed(
          AppLocalizations.of(context),
          '',
          CareWrite.timer,
          e,
        ),
        error: true,
      );
    }
  }

  void _update(CareTimer next) {
    final me = ref.read(selectedMembershipProvider);
    if (me != null) _repo.updateTimer(next, me.uid, onError: _failed);
  }

  Future<void> _end(CareTimer timer) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (widget.type == TimerType.pump) {
      // "Xong · nhập lượng sữa": stop, then 23a saves the record and ends the timer.
      final stopped = timer.pauseAt(_now());
      _update(stopped);
      await showClSheet<void>(
        context: context,
        builder: (_) => PumpSheet(timer: stopped),
      );
      return;
    }
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final record = timer.toRecord(
      _now(),
      by: (uid: me.uid, author: CareAuthor.of(me)),
    );
    final toaster = ClToaster.of(context);
    final repo = _repo;
    // The screen is gone when the server answers: the toaster outlives it (SY-4).
    void Function(Object) failed(CareWrite write) =>
        (e) => toaster.show(
          message: careWriteFailed(l10n, locale, write, e, record),
          error: true,
        );
    _leaving = true;
    repo.endTimer(timer, record, onError: failed(CareWrite.create));
    ClHaptics.success();
    ref.read(lastSavedProvider.notifier).mark(record.type);
    context.popOrToday();
    toaster.show(
      message: l10n.savedToast(recordSummary(l10n, locale, record)),
      actionLabel: l10n.undo,
      onAction: () =>
          repo.softDelete(record, me.uid, onError: failed(CareWrite.delete)),
    );
  }

  Future<void> _cancel(CareTimer timer) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showClSheet<bool>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.cancelConfirmTitle),
          Text(
            l10n.cancelConfirmBody,
            style: sheetContext.cl.text.body.copyWith(
              color: sheetContext.cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.cancelNoSave,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          ClButton(
            label: l10n.keepTiming,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final toaster = ClToaster.of(context);
    _leaving = true;
    _repo.cancelTimer(
      timer,
      onError: (e) => toaster.show(
        message: careWriteFailed(l10n, '', CareWrite.timer, e),
        error: true,
      ),
    );
    context.popOrToday();
  }

  Future<void> _editStart(CareTimer timer) async {
    final picked = await pickCareTime(
      context,
      initial: timer.startedAt,
      earliest: DateTime.now().subtract(const Duration(hours: 24)),
    );
    if (picked != null && mounted) _update(timer.copyWith(startedAt: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final timer = ref.watch(careTimerProvider((me.babyId, widget.type))).value;
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final nickname = baby?.nickname ?? '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hm = DateFormat.Hm(locale);

    if (timer == null) {
      // Ended or cancelled (here or by someone else): nothing left to show. A timer that was
      // just started may not have reached the local cache yet — wait for it.
      if (!_leaving && _sessionSeen != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.popOrToday();
        });
      }
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    if (_sessionSeen != null && _sessionSeen != timer.sessionId) {
      // Our start lost to another device's (P-011): follow theirs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showClToast(
            context,
            message: l10n.timerJoined(
              authorLabel(
                l10n,
                timer.author,
                isMe: false,
                relationLabel: (r, c) => relationLabel(l10n, r, c),
              ),
            ),
          );
        }
      });
    }
    _sessionSeen = timer.sessionId;

    final now = _now();
    final who = authorLabel(
      l10n,
      timer.author,
      isMe: false,
      relationLabel: (r, c) => relationLabel(l10n, r, c),
    );
    final type = widget.type;
    final care = careColor(context, type.careType);

    final (title, subtitle) = switch (type) {
      TimerType.sleep => (
        l10n.sleepTimerTitle(nickname),
        l10n.timerStartedBy(who, hm.format(timer.startedAt)),
      ),
      TimerType.breast => (
        l10n.breastTimerTitle(nickname),
        l10n.timerStartedBy(who, hm.format(timer.startedAt)),
      ),
      TimerType.pump => (
        l10n.pumpTimerTitle(who),
        l10n.pumpStartedFor(hm.format(timer.startedAt), nickname),
      ),
    };

    final body = switch (type) {
      TimerType.sleep => Center(
        child: SleepRing(
          elapsed: timer.totalAt(now),
          label: l10n.sleepRingLabel,
          since: l10n.sinceTime(hm.format(timer.startedAt)),
          color: care.accent,
        ),
      ),
      _ => _SidesBody(timer: timer, now: now, clock: _now, onChanged: _update),
    };

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.popOrToday(),
        trailing: ClSyncStatus(
          state: timer.pending ? ClSyncState.pending : ClSyncState.synced,
          label: timer.pending ? l10n.timerOnlyHere : l10n.timerFamilySees,
        ),
      ),
      content: [
        ScreenHeading(title: title, subtitle: subtitle, large: false),
        if (timer.pending) ...[
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              ClIcon(ClIcons.cloudOff, size: 18, color: cl.colors.pending),
              const SizedBox(width: ClSpace.s2),
              Text(
                type == TimerType.sleep
                    ? l10n.sleepNotSynced
                    : l10n.timerNotSynced,
                style: cl.text.label.copyWith(color: cl.colors.pending),
              ),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s6),
        body,
      ],
      bottom: [
        ClButton(
          label: switch (type) {
            TimerType.sleep => l10n.endSleep,
            TimerType.breast => l10n.endFeed,
            TimerType.pump => l10n.pumpDone,
          },
          expand: true,
          onPressed: () => _end(timer),
        ),
        const SizedBox(height: ClSpace.s3),
        if (type == TimerType.sleep)
          ClButton(
            label: l10n.editStart,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => _editStart(timer),
          )
        else
          ClButton(
            label: timer.paused ? l10n.resumeTimer : l10n.pauseTimer,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => _update(
              timer.paused
                  ? timer.resumeAt(DateTime.now())
                  : timer.pauseAt(DateTime.now()),
            ),
          ),
        ClButton(
          label: l10n.cancelNoSave,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => _cancel(timer),
        ),
      ],
    );
  }
}

/// SleepTimer (10:83): 272 px ring, arc over the current hour, elapsed in tabular numerals.
/// Ambient motion follows Motion spec P10 272:368 (see [SleepBreath]): the moon and halo breathe
/// on a 4 s cycle while the arc advances evenly with the seconds. This replaces the component's
/// older "arc opacity 1 ↔ 0.55" note (open issue 6 in 10-motion-spec.md).
class SleepRing extends StatefulWidget {
  const SleepRing({
    required this.elapsed,
    required this.label,
    required this.since,
    required this.color,
    super.key,
  });

  final Duration elapsed;
  final String label;
  final String since;
  final Color color;

  @override
  State<SleepRing> createState() => _SleepRingState();
}

class _SleepRingState extends State<SleepRing>
    with SingleTickerProviderStateMixin {
  static const double _size = 272;

  /// Motion spec P10 272:368: one repeating controller drives the moon and the halo; the
  /// counter text and the arc are not rebuilt by it.
  late final _breath = AnimationController(
    vsync: this,
    duration: SleepBreath.cycle,
  );
  late final Animation<double> _phase = _breath.drive(
    CurveTween(curve: const SleepBreathCurve()),
  );
  late final Animation<double> _moonScale = _phase.drive(
    Tween(begin: 1, end: SleepBreath.moonScalePeak),
  );
  late final AppLifecycleListener _lifecycle;
  bool _visible = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    // Ambient rules 272:425: run only while the screen is visible; pause in the background.
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _visible = state == AppLifecycleState.resumed;
        _sync();
      },
    );
    final state = WidgetsBinding.instance.lifecycleState;
    _visible = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambient rules 272:425: Reduce Motion leaves only the counter. Ticks off (tests) too.
    _allowed =
        !context.reduceMotion &&
        ProviderScope.containerOf(context).read(timerTicksProvider);
    _sync();
  }

  void _sync() {
    if (_allowed && _visible) {
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final minutes = widget.elapsed.inSeconds % 3600 / 3600;
    const halo = _size * SleepBreath.haloToRing;
    return Semantics(
      label:
          '${widget.label} ${clockLabel(widget.elapsed, hours: true)}, ${widget.since}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // The halo is 170/150 of the ring, so it reaches slightly past it, fading out.
              Positioned(
                left: (_size - halo) / 2,
                top: (_size - halo) / 2,
                width: halo,
                height: halo,
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey('sleep-halo'),
                    painter: SleepHaloPainter(
                      phase: _phase,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(
                    track: cl.colors.surface2,
                    color: widget.color,
                    fraction: minutes == 0 ? 0.002 : minutes,
                  ),
                ),
              ),
              // Inside the ring at any text size: large text scales the block down to fit
              // rather than running across the arc.
              SizedBox(
                width: _size,
                height: _size,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _ringContent(cl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringContent(ClTheme cl) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RepaintBoundary(
        child: ScaleTransition(
          key: const ValueKey('sleep-moon'),
          scale: _moonScale,
          child: const ClArt(ClIllustration.miniMoon, width: 48, height: 48),
        ),
      ),
      // D-112: no "Đang ngủ" / "Từ 13:37" here; the heading right above says both (the screen
      // reader still hears them through the ring's label).
      const SizedBox(height: ClSpace.s2),
      ClTabularText(
        clockLabel(widget.elapsed, hours: true),
        style: cl.text.numeralXl.copyWith(color: cl.colors.ink),
      ),
      // Balances the moon, so the readout sits at the ring's centre.
      const SizedBox(height: 56),
    ],
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.track,
    required this.color,
    required this.fraction,
  });

  final Color track;
  final Color color;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.fraction != fraction || old.track != track;
}

/// 23b / 23c: total and two 150 px side discs. Breast: one side at a time, tap to switch.
/// Pump: both can run, tap a side to stop or start it.
class _SidesBody extends ConsumerWidget {
  const _SidesBody({
    required this.timer,
    required this.now,
    required this.clock,
    required this.onChanged,
  });

  final CareTimer timer;
  final DateTime now;
  final DateTime Function() clock;
  final ValueChanged<CareTimer> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pump = timer.type == TimerType.pump;
    final care = careColor(context, timer.type.careType);
    final recent =
        ref.watch(recentRecordsProvider(timer.babyId)).value ?? const [];
    final lastBreast = recent
        .where((r) => r.type == CareType.breast)
        .firstOrNull;
    final lastEnd =
        lastBreast?.endSide ??
        (lastBreast?.side == Side.both ? null : lastBreast?.side);
    final hint = pump
        ? l10n.doublePumpHint
        : switch (lastEnd) {
            Side.left => l10n.lastEndedLeft,
            Side.right => l10n.lastEndedRight,
            _ => null,
          };

    Widget disc(Side side) {
      final s = timer.sideOf(side);
      final running = s.running;
      final state = running
          ? (pump ? l10n.pumpingNow : l10n.feedingNow)
          : timer.paused
          ? l10n.pausedLabel
          : pump
          ? l10n.tapToStart
          : l10n.tapToSwitch;
      final label = side == Side.left ? l10n.sideLeftCaps : l10n.sideRightCaps;
      final ink = running ? Colors.white : care.ink;
      return ClPressable(
        onPressed: () => onChanged(
          pump
              ? timer.toggle(side, DateTime.now())
              : timer.switchTo(side, DateTime.now()),
        ),
        semanticLabel: '$label ${clockLabel(s.elapsedAt(now))} $state',
        child: AnimatedContainer(
          duration: context.motion(ClMotion.quick),
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: running ? care.accent : care.soft,
            border: Border.all(color: care.accent, width: running ? 0 : 1.5),
            boxShadow: running ? cl.shadows.card : null,
          ),
          padding: const EdgeInsets.all(ClSpace.s4),
          child: ExcludeSemantics(
            // Stays inside the disc at large text sizes.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: cl.text.label.copyWith(color: ink, letterSpacing: 1),
                  ),
                  ClTabularText(
                    clockLabel(s.elapsedAt(now)),
                    style: cl.text.title.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(state, style: cl.text.caption.copyWith(color: ink)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          l10n.totalTime,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ClTabularText(
            clockLabel(timer.totalAt(now)),
            style: cl.text.numeralXl.copyWith(color: cl.colors.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              disc(Side.left),
              const SizedBox(width: ClSpace.s4),
              disc(Side.right),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: ClSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: ClSpace.s1,
            ),
            decoration: BoxDecoration(
              color: care.soft,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Text(hint, style: cl.text.caption.copyWith(color: care.ink)),
          ),
        ],
      ],
    );
  }
}

/// 25a Ghi giấc ngủ (69:4213): timer (recommended) or a past sleep.
Future<void> showSleepChooser(BuildContext context, WidgetRef ref) {
  final host = context;
  return showClSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final me = ref.read(selectedMembershipProvider);
      final nickname = me == null
          ? ''
          : ref.read(babyProvider(me.babyId)).value?.nickname ?? '';
      final care = sheetContext.cl.care.sleep;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sleepChooserTitle),
          Text(
            l10n.sleepChooserPrompt(nickname),
            style: sheetContext.cl.text.body,
          ),
          const SizedBox(height: ClSpace.s4),
          ClEntryOption(
            icon: ClIcons.clock,
            title: l10n.sleepStartTimer,
            subtitle: l10n.sleepStartTimerHint(nickname),
            care: care,
            primary: true,
            onTap: () {
              Navigator.of(sheetContext).pop();
              openOrStartTimer(host, TimerType.sleep);
            },
          ),
          const SizedBox(height: ClSpace.s3),
          ClEntryOption(
            icon: ClIcons.edit,
            title: l10n.sleepManual,
            subtitle: l10n.sleepManualHint,
            care: care,
            onTap: () {
              Navigator.of(sheetContext).pop();
              host.push(Routes.manualSleep);
            },
          ),
          // D-110: no footnote on switching modes; each option already says what it does.
        ],
      );
    },
  );
}

/// 26 Nhập giấc ngủ (47:3074): start and end with "Hôm qua / Hôm nay", "Qua đêm", the
/// per-day split note, and a way into the timer. Also "Sửa tay từ bản của tôi" (27).
class ManualSleepScreen extends ConsumerStatefulWidget {
  const ManualSleepScreen({this.edit, this.endAt, super.key});
  final CareRecord? edit;

  /// "Ghi bù" (20e): the sleep ends at this time on an earlier day.
  final DateTime? endAt;

  @override
  ConsumerState<ManualSleepScreen> createState() => _ManualSleepScreenState();
}

class _ManualSleepScreenState extends ConsumerState<ManualSleepScreen> {
  late final String _id = widget.edit?.id ?? newRecordId();
  late DateTime _end;
  late DateTime _start;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = ref.read(timerClockProvider)();
    _end =
        widget.edit?.endedAt ??
        widget.endAt ??
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _start = widget.edit?.occurredAt ?? _end.subtract(const Duration(hours: 1));
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    if (!_end.isAfter(_start)) {
      return setState(() => _error = l10n.sleepEndBeforeStart);
    }
    if (_end.difference(_start) > const Duration(hours: 24)) {
      return setState(() => _error = l10n.sleepTooLong);
    }
    final edit = widget.edit;
    final record = edit != null
        ? CareRecord(
            id: edit.id,
            babyId: edit.babyId,
            type: CareType.sleep,
            occurredAt: _start,
            endedAt: _end,
            createdBy: edit.createdBy,
            author: edit.author,
            createdAt: edit.createdAt,
            clientCreatedAt: edit.clientCreatedAt,
            pending: true,
          )
        : CareRecord(
            id: _id,
            babyId: me.babyId,
            type: CareType.sleep,
            occurredAt: _start,
            endedAt: _end,
            createdBy: me.uid,
            author: CareAuthor.of(me),
            clientCreatedAt: DateTime.now(),
            pending: true,
          );
    commitRecord(context, ref, record, isEdit: edit != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final minutes = _end.difference(_start).inMinutes;
    final overnight = !DateUtils.isSameDay(_start, _end);
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final care = cl.care.sleep;

    Future<void> pick(bool start) async {
      final picked = await pickCareTime(
        context,
        initial: start ? _start : _end,
        earliest: now.subtract(const Duration(days: 30)),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _error = null;
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.popOrToday(),
        trailing: baby == null
            ? null
            : ClBabySwitcher(
                label: baby.nickname,
                avatar: SavedBabyAvatar(baby: baby, size: 32),
              ),
      ),
      content: [
        ScreenHeading(title: l10n.manualSleepTitle),
        const SizedBox(height: ClSpace.s4),
        // D-112: start and end are the task, so they come first; the duration is their result,
        // read as the total of the same group (it was a 140 pt card above the inputs).
        ClCardGroup(
          shadow: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: ClTimeRow(
                icon: ClIcons.sleep,
                label: l10n.startLabel,
                value: timeChipLabel(context, _start, isNow: false, now: now),
                onTap: () => pick(true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: ClTimeRow(
                icon: ClIcons.sunrise,
                label: l10n.sleepEnd,
                value: timeChipLabel(context, _end, isNow: false, now: now),
                onTap: () => pick(false),
              ),
            ),
            MergeSemantics(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(ClSpace.s4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ClSpace.s3,
                  runSpacing: ClSpace.s1,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.durationLabel,
                          style: cl.text.body.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                        if (overnight) ...[
                          const SizedBox(width: ClSpace.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ClSpace.s2,
                              vertical: ClSpace.s1,
                            ),
                            decoration: BoxDecoration(
                              color: care.soft,
                              borderRadius: BorderRadius.circular(
                                ClRadius.pill,
                              ),
                            ),
                            child: Text(
                              l10n.overnight,
                              style: cl.text.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: care.ink,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      minutes > 0 ? durationLabel(l10n, minutes) : '—',
                      style: cl.text.title.copyWith(color: cl.colors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: ClSpace.s2),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: cl.text.label.copyWith(color: cl.colors.error),
            ),
          ),
        ],
        // D-110: how an overnight sleep is split only matters when the sleep is overnight.
        if (overnight) ...[
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.overnightNote(gmtOffsetLabel(zone, now)),
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        if (widget.edit == null) ...[
          const SizedBox(height: ClSpace.s4),
          ClPressable(
            onPressed: () {
              // 26 → 25: the timer takes this screen's place.
              openOrStartTimer(context, TimerType.sleep, replace: true);
            },
            semanticLabel:
                '${l10n.sleepingNow(baby?.nickname ?? '')} ${l10n.sleepStartTimer}',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s4,
                vertical: ClSpace.s3,
              ),
              decoration: BoxDecoration(
                color: care.soft,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              child: Row(
                children: [
                  ClIcon(ClIcons.clock, size: 18, color: care.ink),
                  const SizedBox(width: ClSpace.s2),
                  // One paragraph, so at large text the question and the link wrap together.
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${l10n.sleepingNow(baby?.nickname ?? '')} ',
                            style: cl.text.label.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                          TextSpan(
                            text: l10n.sleepStartTimer,
                            style: cl.text.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: care.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClIcon(ClIcons.chevronRight, size: 16, color: care.ink),
                ],
              ),
            ),
          ),
        ],
      ],
      bottom: [ClButton(label: l10n.saveSleep, expand: true, onPressed: _save)],
    );
  }
}

/// 27 Giấc ngủ trùng nhau (47:3145): pick the right sleep; the other goes to the 30-day bin.
/// Nothing is merged or overwritten (R-075).
class OverlapScreen extends ConsumerStatefulWidget {
  const OverlapScreen({required this.conflictId, super.key});
  final String conflictId;

  @override
  ConsumerState<OverlapScreen> createState() => _OverlapScreenState();
}

class _OverlapScreenState extends ConsumerState<OverlapScreen> {
  String? _keep;
  bool _busy = false;

  Future<void> _resolve(String babyId) async {
    final l10n = AppLocalizations.of(context);
    final keep = _keep;
    if (keep == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(careRepositoryProvider)
          .resolveConflict(
            babyId: babyId,
            conflictId: widget.conflictId,
            keepRecordId: keep,
          );
      if (!mounted) return;
      showClToast(context, message: l10n.overlapKept);
      context.popOrToday();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final reason = e.details is Map ? (e.details as Map)['reason'] : null;
      showClToast(
        context,
        message: reason == 'not-allowed'
            ? l10n.overlapNotAllowed
            : l10n.familyErrorGeneric,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final conflicts =
        ref.watch(openConflictsProvider(me.babyId)).value ?? const [];
    final conflict = conflicts
        .where((c) => c.id == widget.conflictId)
        .firstOrNull;
    final records = [
      for (final id in conflict?.recordIds ?? const <String>[])
        ?ref.watch(careRecordProvider((me.babyId, id))).value,
    ];
    if (conflict == null || records.length < 2) {
      return OnboardingScaffold(
        topBar: ClTopBar(onBack: () => context.popOrToday()),
        content: [
          const SizedBox(height: ClSpace.s8),
          Center(
            child: Text(
              l10n.recordGone,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      );
    }
    records.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final hm = DateFormat.Hm(locale);
    final from = records
        .map((r) => r.occurredAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final to = records
        .map((r) => r.endedAt ?? r.occurredAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final axisStart = DateTime(from.year, from.month, from.day, from.hour);
    final axisEnd = DateTime(to.year, to.month, to.day, to.hour + 1);
    final span = axisEnd.difference(axisStart).inMinutes.toDouble();
    final hours = [
      for (
        var t = axisStart;
        !t.isAfter(axisEnd);
        t = t.add(const Duration(hours: 1))
      )
        t,
    ];
    final mine = records.where((r) => r.createdBy == me.uid).firstOrNull;

    Widget option(CareRecord r) {
      final selected = _keep == r.id;
      final left = r.occurredAt.difference(axisStart).inMinutes / span;
      final width =
          (r.endedAt ?? r.occurredAt).difference(r.occurredAt).inMinutes / span;
      final bar = r.pending ? cl.colors.sunshine : cl.colors.mint;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: ClPressable(
          onPressed: () => setState(() => _keep = r.id),
          pressedOpacity: ClPressable.surfaceOpacity,
          semanticLabel:
              '${hm.format(r.occurredAt)} – ${hm.format(r.endedAt!)}',
          child: AnimatedContainer(
            duration: context.motion(ClMotion.quick),
            padding: const EdgeInsets.all(ClSpace.s4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.card),
              border: Border.all(
                color: selected ? cl.colors.mintDeep : Colors.transparent,
                width: 2,
              ),
              boxShadow: cl.shadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: cl.colors.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Positioned(
                        left: c.maxWidth * left,
                        width: math.max(6, c.maxWidth * width),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ClSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: ClTabularText(
                        '${hm.format(r.occurredAt)} – ${hm.format(r.endedAt!)}',
                        style: cl.text.title2.copyWith(color: cl.colors.ink),
                      ),
                    ),
                    ClRadio(selected: selected),
                  ],
                ),
                const SizedBox(height: ClSpace.s2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${durationLabel(l10n, r.endedAt!.difference(r.occurredAt).inMinutes)} · ${loggedBy(l10n, r, me.uid)}',
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ),
                    ClSyncStatus(
                      state: r.pending
                          ? ClSyncState.pending
                          : ClSyncState.synced,
                      label: r.pending
                          ? l10n.timerOnlyHere
                          : l10n.timerFamilySees,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.popOrToday(),
        trailing: ClSyncStatus(
          state: ClSyncState.synced,
          label: l10n.backOnline,
        ),
      ),
      content: [
        ScreenHeading(
          title: l10n.overlapTitle,
          subtitle: l10n.overlapBody,
          large: false,
        ),
        const SizedBox(height: ClSpace.s4),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in hours)
                Text(
                  DateFormat('HH:mm', locale).format(h),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        for (final r in records) ...[
          option(r),
          const SizedBox(height: ClSpace.s3),
        ],
      ],
      bottom: [
        ClButton(
          label: l10n.keepSelected,
          expand: true,
          loading: _busy,
          onPressed: _keep == null || _busy ? null : () => _resolve(me.babyId),
        ),
        if (mine != null)
          ClButton(
            label: l10n.editMine,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => context.push(Routes.manualSleep, extra: mine),
          ),
      ],
    );
  }
}
