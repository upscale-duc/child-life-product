import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../family/emergency_numbers.dart';
import '../premium/premium_repository.dart';
import 'first_aid_models.dart';
import 'first_aid_repository.dart';
import 'first_aid_widgets.dart';

/// Hands-free first aid (Figma v1.1 revision 2; D-058, P-141): nothing to tap while helping the
/// baby. The guide is read aloud and scrolls along, CPR plays its own beat, and "Gọi 115" dials
/// at once. This file holds the device side and the CPR / call cards of the situation page.

/// Keep the screen on, beep, buzz, speak, dial. Tests replace it.
class FirstAidDevice {
  AudioPlayer? _player;
  FlutterTts? _tts;

  Future<void> keepAwake(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } on Object {
      // Not available (simulator, tests): the guide still works.
    }
  }

  /// One metronome beat: a short beep and a light tap.
  Future<void> beat() async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final player = _player ??= AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource('sounds/cpr_beep.wav'));
    } on Object {
      // Audio unavailable: the vibration and the pulsing disc still keep time.
    }
  }

  /// Speaks [text] with the device's own (offline) voice; completes when it has been said.
  Future<void> speak(String text, Locale locale) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage(locale.languageCode == 'en' ? 'en-US' : 'vi-VN');
      await tts.setSpeechRate(0.45);
      await tts.speak(text);
    } on Object {
      // No voice for this language: the page stays readable.
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } on Object {
      // Nothing to stop.
    }
  }

  Future<void> dispose() async {
    await stopSpeaking();
    await _player?.dispose();
    _player = null;
  }

  /// Opens the phone app dialling [number]; false when it could not.
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

/// When "Gọi 115" was pressed (the bar then reads "Đang gọi 115 · 00:42"). Shared by every page.
final firstAidCallStartedProvider =
    NotifierProvider<FirstAidCallStarted, DateTime?>(FirstAidCallStarted.new);

class FirstAidCallStarted extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? at) => state = at;
}

/// Dials the emergency number at once (7h revision 2: no sheet before the call).
Future<void> callEmergency(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final number =
      ref.read(firstAidPackProvider).value?.emergencyNumber ??
      emergencyNumbers[ref.read(selectedFamilyCountryProvider)] ??
      '115';
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await ref.read(firstAidDeviceProvider).dial(number);
  if (ok) {
    ref.read(firstAidCallStartedProvider.notifier).set(DateTime.now());
  } else {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.faCallFailed(number))));
  }
}

/// The big red "Gọi 115" of the bottom bar, or, once dialled, the green "Đang gọi 115 · 00:42".
class FaCallBar extends ConsumerStatefulWidget {
  const FaCallBar({required this.number, super.key});
  final String number;

  @override
  ConsumerState<FaCallBar> createState() => _FaCallBarState();
}

class _FaCallBarState extends ConsumerState<FaCallBar> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final started = ref.watch(firstAidCallStartedProvider);
    if (started == null) {
      _tick?.cancel();
      _tick = null;
      return FaCallButton(
        number: widget.number,
        expand: true,
        onPressed: () => unawaited(callEmergency(context, ref)),
      );
    }
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    final elapsed = DateTime.now().difference(started);
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final label = l10n.faCalling(widget.number, '$mm:$ss');
    return ClPressable(
      key: const Key('faCalling'),
      // Back from the call: tapping dials again.
      onPressed: () => unawaited(callEmergency(context, ref)),
      semanticLabel: label,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: cl.colors.live,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(ClIcons.phone, size: 20, color: cl.colors.onLive),
            const SizedBox(width: 8),
            Text(
              label,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cl.colors.onLive,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TH01 "Nhịp ép đang phát · tự động": the beat plays by itself while the page is open; after every
/// set of compressions the app says "thổi ngạt 2 lần" and the beat waits a few seconds for them.
class FaMetronomeCard extends ConsumerStatefulWidget {
  const FaMetronomeCard({
    required this.protocol,
    this.paused = false,
    super.key,
  });

  final FaCpr protocol;

  /// While the guide is read aloud the beat waits, so the two voices never overlap.
  final bool paused;

  @override
  ConsumerState<FaMetronomeCard> createState() => _FaMetronomeCardState();
}

class _FaMetronomeCardState extends ConsumerState<FaMetronomeCard>
    with SingleTickerProviderStateMixin {
  Timer? _beat;
  var _count = 0;
  var _breathing = false;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final FirstAidDevice _device;

  /// How long the beat waits after the breaths prompt (two rescue breaths ≈ 1 s each).
  static const breathPause = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _device = ref.read(firstAidDeviceProvider);
    unawaited(_device.keepAwake(true));
    _restart();
  }

  @override
  void didUpdateWidget(FaMetronomeCard old) {
    super.didUpdateWidget(old);
    if (old.protocol.id != widget.protocol.id || old.paused != widget.paused) {
      _count = 0;
      _restart();
    }
  }

  @override
  void dispose() {
    _beat?.cancel();
    _pulse.dispose();
    unawaited(_device.keepAwake(false));
    super.dispose();
  }

  void _restart() {
    _beat?.cancel();
    _beat = null;
    if (widget.paused) return;
    final p = widget.protocol;
    _beat = Timer.periodic(
      Duration(milliseconds: (60000 / p.ratePerMinute).round()),
      (_) => unawaited(_onBeat()),
    );
  }

  Future<void> _onBeat() async {
    if (!mounted || _breathing) return;
    unawaited(_device.beat());
    unawaited(_pulse.forward(from: 0));
    _count++;
    final p = widget.protocol;
    if (_count < p.compressions || p.breaths == 0) return;
    _count = 0;
    _breathing = true;
    _beat?.cancel();
    final l10n = AppLocalizations.of(context);
    await _device.speak(
      l10n.faSayBreaths(p.breaths),
      Localizations.localeOf(context),
    );
    await Future<void>.delayed(breathPause);
    if (!mounted) return;
    _breathing = false;
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final p = widget.protocol;
    return Semantics(
      container: true,
      label: l10n.faMetronomeTitle,
      child: Container(
        key: const Key('faMetronome'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cl.colors.dangerSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: _pulse.isAnimating ? 1 + 0.12 * (1 - _pulse.value) : 1,
                child: child,
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cl.colors.danger,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${p.ratePerMinute}',
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cl.colors.onDanger,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.paused
                        ? l10n.faMetronomePaused
                        : l10n.faMetronomeTitle,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cl.colors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.faMetronomeBody(p.compressions, p.breaths),
                    style: cl.text.label.copyWith(fontSize: 13, height: 1.45),
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

/// 7h "Nói với tổng đài": what to read out to the operator, once the call is placed.
class FaTellOperatorCard extends ConsumerStatefulWidget {
  const FaTellOperatorCard({required this.situation, super.key});
  final FaSituation situation;

  @override
  ConsumerState<FaTellOperatorCard> createState() => _FaTellOperatorCardState();
}

class _FaTellOperatorCardState extends ConsumerState<FaTellOperatorCard> {
  var _open = true;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
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
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: cl.text.label.copyWith(
              fontSize: 13,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      key: const Key('faTellOperator'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClPressable(
            onPressed: () => setState(() => _open = !_open),
            semanticLabel: l10n.faTellOperator,
            selected: _open,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.faTellOperator,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: ClIcon(
                    ClIcons.chevronDown,
                    size: 18,
                    color: cl.colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_open) ...[
            if (who != null) row(l10n.faTellBaby, who),
            row(l10n.faTellCondition, widget.situation.lead.of(context)),
          ],
        ],
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
