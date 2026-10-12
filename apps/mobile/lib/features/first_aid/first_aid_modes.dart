import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'first_aid_models.dart';
import 'first_aid_repository.dart';
import 'first_aid_widgets.dart';

/// Step mode (7f / 7g), CPR mode (7i) and the call sheet (7h) of Sơ cứu (D-058, P-141).

/// The device side of the guided modes: keep the screen on, beep, buzz, dial. Tests replace it.
class FirstAidDevice {
  AudioPlayer? _player;

  Future<void> keepAwake(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } on Object {
      // Not available (simulator, tests): the guide still works.
    }
  }

  /// One metronome beat: a short beep and a light tap (the design's "bíp và rung theo nhịp").
  Future<void> beat() async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final player = _player ??= AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource('sounds/cpr_beep.wav'));
    } on Object {
      // Audio unavailable: the vibration and the pulsing dot still keep time.
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }

  /// Opens the phone app with [number]; false when it could not.
  Future<bool> dial(String number) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } on Object {
      return false;
    }
  }
}

final firstAidDeviceProvider = Provider<FirstAidDevice>((ref) {
  final device = FirstAidDevice();
  ref.onDispose(() => unawaited(device.dispose()));
  return device;
});

// ---------- 7h Gọi 115 ----------

/// The interstitial before dialling: who the baby is (to read out) and what to tell the operator.
/// "Báo cho cả nhà" (sharing the location with the family) waits for an owner decision (P-141).
Future<void> showFirstAidCallSheet(
  BuildContext context, {
  FaSituation? situation,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _CallSheet(situation: situation),
);

class _CallSheet extends ConsumerWidget {
  const _CallSheet({this.situation});
  final FaSituation? situation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final number =
        ref.watch(firstAidPackProvider).value?.emergencyNumber ?? '115';
    final baby = ref.watch(faBabyProvider(l10n));
    final locale = Localizations.localeOf(context);
    final who = baby == null
        ? null
        : [
            baby.name,
            ?baby.ageLabel,
            if (baby.weightKg != null)
              l10n.faWeightKg(faKg(locale, baby.weightKg!)),
          ].join(' · ');
    final tell = [
      l10n.faCallTell1,
      l10n.faCallTell2,
      l10n.faCallTell3,
      l10n.faCallTell4,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.faCallTitle(number)),
        if (who != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cl.colors.cardPeach,
                    shape: BoxShape.circle,
                  ),
                  child: ClIcon(
                    ClIcons.cake,
                    size: 20,
                    color: cl.colors.onCard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        who,
                        style: cl.text.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (situation != null)
                        Text(
                          l10n.faCallHandling(situation!.title.of(context)),
                          style: cl.text.label.copyWith(
                            fontSize: 13,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          l10n.faCallTell,
          style: cl.text.bodyStrong.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final (i, line) in tell.indexed) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cl.colors.mintDeep,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: cl.text.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cl.colors.onMintDeep,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line,
                  style: cl.text.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        FaCallButton(
          number: number,
          expand: true,
          onPressed: () async {
            final toaster = ClToaster.of(context);
            final ok = await ref.read(firstAidDeviceProvider).dial(number);
            if (!ok) toaster.show(message: l10n.faCallFailed(number));
          },
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- Guided chrome ----------

class _GuidedPage extends StatelessWidget {
  const _GuidedPage({
    required this.segments,
    required this.done,
    required this.label,
    required this.children,
    required this.bottom,
    this.emergencyNumber,
    this.situation,
  });

  final int segments;
  final int done;
  final String label;
  final List<Widget> children;
  final List<Widget> bottom;
  final String? emergencyNumber;
  final FaSituation? situation;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: Row(
                children: [
                  FaRoundButton(
                    key: const Key('faClose'),
                    icon: ClIcons.close,
                    label: l10n.faClose,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  if (emergencyNumber != null)
                    FaCallButton(
                      number: emergencyNumber!,
                      small: true,
                      onPressed: () => unawaited(
                        showFirstAidCallSheet(context, situation: situation),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s4,
                  ClSpace.s4,
                  ClSpace.s4,
                ),
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < segments; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: i < done
                                  ? cl.colors.mintDeep
                                  : cl.colors.surface2,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s3),
                  ...children,
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                media.padding.bottom > 0 ? 0 : ClSpace.s3,
              ),
              child: Row(children: bottom),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Hồi sức tim phổi · dưới 1 tuổi": the title without its bracketed abbreviation (7f, 7i).
String _variantTitle(BuildContext context, FaSituation s, FaVariant v) => [
  s.title.of(context).replaceAll(RegExp(r'\s*\(.*?\)'), ''),
  if (v.label != null) v.label!.of(context).toLowerCase(),
].join(' · ');

Widget _stepText(BuildContext context, FaStep step, {double body = 18}) {
  final cl = context.cl;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(
          step.title.of(context),
          style: cl.text.largeTitle.copyWith(fontSize: 28, height: 1.2),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        step.body.of(context),
        style: cl.text.body.copyWith(
          fontSize: body,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    ],
  );
}

Widget _footnote(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: ClSpace.s4),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: context.cl.text.caption.copyWith(color: context.cl.colors.inkMuted),
  ),
);

// ---------- 7f / 7g Làm theo từng bước ----------

class FirstAidStepScreen extends ConsumerStatefulWidget {
  const FirstAidStepScreen({
    required this.situationId,
    this.variantId,
    super.key,
  });
  final String situationId;
  final String? variantId;

  @override
  ConsumerState<FirstAidStepScreen> createState() => _FirstAidStepScreenState();
}

class _FirstAidStepScreenState extends ConsumerState<FirstAidStepScreen> {
  var _index = 0;
  var _count = 0;
  late final FirstAidDevice _device = ref.read(firstAidDeviceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_device.keepAwake(true));
  }

  @override
  void dispose() {
    unawaited(_device.keepAwake(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    final s = pack?.situation(widget.situationId);
    if (pack == null || s == null) {
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    final v = s.variant(widget.variantId) ?? s.variants.first;
    if (v.steps.isEmpty) return Scaffold(backgroundColor: cl.colors.cloud);
    final step = v.steps[_index];
    final last = _index == v.steps.length - 1;
    void go(int to) => setState(() {
      _index = to;
      _count = 0;
    });

    return _GuidedPage(
      segments: v.steps.length,
      done: _index + 1,
      label: l10n.faStepOf(
        _variantTitle(context, s, v),
        _index + 1,
        v.steps.length,
      ),
      emergencyNumber: s.emergency ? pack.emergencyNumber : null,
      situation: s,
      bottom: [
        Expanded(
          child: Opacity(
            opacity: _index == 0 ? 0.4 : 1,
            child: ClButton(
              label: l10n.faBack,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: _index == 0 ? null : () => go(_index - 1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClButton(
            key: const Key('faNext'),
            label: last ? l10n.faFinish : l10n.faNext,
            expand: true,
            onPressed: last ? () => context.pop() : () => go(_index + 1),
          ),
        ),
      ],
      children: [
        // A step without its own picture shows the page's (7f "Vỗ lưng").
        FaImage(step.image ?? v.hero ?? s.hero),
        const SizedBox(height: ClSpace.s4),
        _stepText(context, step),
        if (step.count != null) ...[
          const SizedBox(height: ClSpace.s4),
          _TapCounter(
            total: step.count!,
            count: _count,
            onTap: () => setState(() {
              if (_count < step.count!) _count++;
            }),
          ),
        ],
        _footnote(context, l10n.faScreenOn),
      ],
    );
  }
}

class _TapCounter extends StatelessWidget {
  const _TapCounter({
    required this.total,
    required this.count,
    required this.onTap,
  });
  final int total;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('faCounter'),
      onPressed: onTap,
      semanticLabel: '${l10n.faTapToCount}: $count / $total',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.faTapToCount,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
                Text(
                  '$count / $total',
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= total; i++)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: i <= count ? cl.colors.mintDeep : null,
                      shape: BoxShape.circle,
                      border: i <= count
                          ? null
                          : Border.all(color: cl.colors.mintDeep, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: i <= count
                            ? cl.colors.onMintDeep
                            : cl.colors.mintText,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 7i CPR ----------

/// Hồi sức tim phổi, guided: the steps of the CPR variant, with a metronome on the compressions
/// step (beep and vibration at the protocol's rate, counting to 30 by itself) and a breaths step
/// that closes a cycle and starts the next one.
class FirstAidCprScreen extends ConsumerStatefulWidget {
  const FirstAidCprScreen({this.variantId, super.key});
  final String? variantId;

  @override
  ConsumerState<FirstAidCprScreen> createState() => _FirstAidCprScreenState();
}

class _FirstAidCprScreenState extends ConsumerState<FirstAidCprScreen>
    with SingleTickerProviderStateMixin {
  var _index = 0;
  var _cycle = 1;
  var _count = 0;
  var _paused = false;
  Timer? _metronome;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final FirstAidDevice _device = ref.read(firstAidDeviceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_device.keepAwake(true));
  }

  @override
  void dispose() {
    _metronome?.cancel();
    _pulse.dispose();
    unawaited(_device.keepAwake(false));
    super.dispose();
  }

  void _start(FaCpr protocol, VoidCallback onSet) {
    _metronome?.cancel();
    if (_paused) return;
    final beat = Duration(
      milliseconds: (60000 / protocol.ratePerMinute).round(),
    );
    _metronome = Timer.periodic(beat, (_) {
      if (!mounted) return;
      unawaited(_device.beat());
      unawaited(_pulse.forward(from: 0));
      setState(() => _count++);
      if (_count >= protocol.compressions) {
        _metronome?.cancel();
        _metronome = null;
        onSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    final s = pack?.cprSituation;
    final v =
        s?.variant(widget.variantId) ??
        s?.variants.firstWhere(
          (v) => v.cpr != null,
          orElse: () => s.variants.first,
        );
    final protocol = pack?.protocol(v?.cpr);
    if (pack == null ||
        s == null ||
        v == null ||
        protocol == null ||
        v.steps.isEmpty) {
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    final steps = v.steps;
    final step = steps[_index];
    final compressionsAt = steps.indexWhere(
      (st) => st.cprRole == FaCprRole.compressions,
    );
    final breathsAt = steps.indexWhere((st) => st.cprRole == FaCprRole.breaths);
    final compressing = step.cprRole == FaCprRole.compressions;
    final breathing = step.cprRole == FaCprRole.breaths;

    void go(int to) {
      _metronome?.cancel();
      _metronome = null;
      setState(() {
        _index = to;
        _count = 0;
      });
      if (steps[to].cprRole == FaCprRole.compressions) {
        _start(protocol, () {
          if (breathsAt >= 0) go(breathsAt);
        });
      }
    }

    if (compressing && _metronome == null && !_paused && _count == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _metronome == null && _index == compressionsAt) {
          _start(protocol, () {
            if (breathsAt >= 0) go(breathsAt);
          });
        }
      });
    }

    final List<Widget> bottom;
    if (breathing) {
      bottom = [
        Expanded(
          child: ClButton(
            key: const Key('faBreathsDone'),
            label: l10n.faCprBreathsDone(protocol.breaths),
            expand: true,
            onPressed: () {
              setState(() => _cycle++);
              if (compressionsAt >= 0) go(compressionsAt);
            },
          ),
        ),
      ];
    } else if (compressing) {
      bottom = [
        Expanded(
          child: ClButton(
            key: const Key('faPause'),
            label: _paused ? l10n.faCprResume : l10n.faCprPause,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () {
              setState(() => _paused = !_paused);
              if (_paused) {
                _metronome?.cancel();
                _metronome = null;
              } else {
                _start(protocol, () {
                  if (breathsAt >= 0) go(breathsAt);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClButton(
            key: const Key('faBreathing'),
            label: l10n.faCprBreathing,
            expand: true,
            onPressed: () {
              final toaster = ClToaster.of(context);
              context.pop();
              toaster.show(
                message: l10n.faCprStopped,
                visibleFor: const Duration(seconds: 8),
              );
            },
          ),
        ),
      ];
    } else {
      bottom = [
        Expanded(
          child: Opacity(
            opacity: _index == 0 ? 0.4 : 1,
            child: ClButton(
              label: l10n.faBack,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: _index == 0 ? null : () => go(_index - 1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClButton(
            key: const Key('faNext'),
            label: l10n.faNext,
            expand: true,
            onPressed: _index + 1 < steps.length ? () => go(_index + 1) : null,
          ),
        ),
      ];
    }

    return _GuidedPage(
      segments: steps.length,
      done: _index + 1,
      label: l10n.faCprStep(
        _variantTitle(context, s, v),
        _index + 1,
        steps.length,
        _cycle,
      ),
      emergencyNumber: pack.emergencyNumber,
      situation: s,
      bottom: bottom,
      children: [
        FaImage(
          compressing
              ? (protocol.image ?? step.image ?? v.hero ?? s.hero)
              : (step.image ?? v.hero ?? s.hero),
        ),
        const SizedBox(height: ClSpace.s4),
        if (compressing)
          _stepText(
            context,
            FaStep(title: step.title, body: protocol.compressionText),
            body: 17,
          )
        else
          _stepText(context, step, body: 17),
        if (compressing) ...[
          const SizedBox(height: ClSpace.s4),
          _Metronome(
            count: _count,
            total: protocol.compressions,
            rate: protocol.ratePerMinute,
            breaths: protocol.breaths,
            pulse: _pulse,
          ),
          _footnote(context, l10n.faCprFootnote),
        ] else if (breathing)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FaTag(
                l10n.faCprNextCompressions(protocol.compressions),
                background: cl.colors.mintSoft,
                ink: cl.colors.mintText,
              ),
            ),
          )
        else
          _footnote(context, l10n.faScreenOn),
      ],
    );
  }
}

class _Metronome extends StatelessWidget {
  const _Metronome({
    required this.count,
    required this.total,
    required this.rate,
    required this.breaths,
    required this.pulse,
  });

  final int count;
  final int total;
  final int rate;
  final int breaths;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: '$count / $total',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: total == 0 ? 0 : count / total,
                    strokeWidth: 8,
                    color: cl.colors.mintDeep,
                    backgroundColor: cl.colors.surface2,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$count',
                          style: cl.text.title.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '/ $total',
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: pulse,
                        builder: (_, _) => Transform.scale(
                          scale: 1 + 0.5 * (1 - pulse.value),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cl.colors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.faCprRate(rate),
                          style: cl.text.bodyStrong.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.faCprBeep,
                    style: cl.text.label.copyWith(
                      fontSize: 13,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                  if (breaths > 0) ...[
                    const SizedBox(height: 8),
                    FaTag(
                      l10n.faCprNextBreaths(breaths),
                      background: cl.colors.mintSoft,
                      ink: cl.colors.mintText,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Chăm sóc entry (7a): shown once a guide is on the device.
class FirstAidEntry extends ConsumerWidget {
  const FirstAidEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    if (pack == null) return const SizedBox.shrink();
    final title = l10n.faEntryTitle;
    final sub = l10n.faEntrySub(pack.situations.length);
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: ClPressable(
        key: const Key('faEntry'),
        onPressed: () => context.push(Routes.firstAid),
        semanticLabel: '$title. $sub',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cl.colors.dangerSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cl.colors.danger,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClIcon(
                  ClIcons.plus,
                  size: 20,
                  color: cl.colors.onDanger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cl.colors.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
