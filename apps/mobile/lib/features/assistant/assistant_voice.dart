import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';

/// Lumi voice input (owner request 2026-10-15: "Lumi chat nên có voice nữa. Mẹ bỉm không rảnh để
/// text."). Dictation only: the phone's own speech service turns speech into words that stream
/// into the composer; the words stay editable and go to Lumi only when the parent taps "Gửi"
/// (draft → confirm stays). No audio is recorded, stored or uploaded by the app, no credits are
/// used, and transcripts are never logged. On-device recognition is asked for first; where the
/// phone cannot do it (or does not have the language) the system service may use Apple's or
/// Google's servers, which the first-run explainer says plainly.

/// Whether dictation can start now.
enum DictationReady { ready, denied, unavailable, language }

/// What the recognizer reports while listening.
@immutable
sealed class DictationEvent {
  const DictationEvent();
}

/// The words so far ([done]: the recognizer's final words for this listen).
class DictationWords extends DictationEvent {
  const DictationWords(this.text, {this.done = false});
  final String text;
  final bool done;
}

/// The input level, 0…1 (drives the meter).
class DictationLevel extends DictationEvent {
  const DictationLevel(this.level);
  final double level;
}

/// The listen ended ([failed]: an error, not silence or a stop).
class DictationEnded extends DictationEvent {
  const DictationEnded({this.failed = false});
  final bool failed;
}

/// The recognizer seam (the app uses [SpeechDictation]; tests a fake).
abstract class AssistantDictation {
  /// Asks for the microphone / speech permission the first time and checks that the phone can
  /// recognize [languageCode] (`vi` / `en`).
  Future<DictationReady> prepare(String languageCode);

  /// Starts listening; the stream closes after [DictationEnded].
  Stream<DictationEvent> listen(String languageCode);

  /// Stops and keeps the words (a final result may still arrive).
  Future<void> stop();

  /// Stops and drops the words.
  Future<void> cancel();
}

final assistantDictationProvider = Provider<AssistantDictation>(
  (ref) => SpeechDictation(),
);

/// [AssistantDictation] over the `speech_to_text` plugin (SFSpeechRecognizer / Android
/// SpeechRecognizer).
class SpeechDictation implements AssistantDictation {
  final _stt = SpeechToText();
  StreamController<DictationEvent>? _events;
  String? _localeId;
  var _heard = false;
  var _onDevice = true;
  String _language = 'vi';
  double _lo = double.infinity;
  double _hi = -double.infinity;

  void _add(DictationEvent e) {
    final c = _events;
    if (c != null && !c.isClosed) c.add(e);
  }

  void _end({bool failed = false}) {
    final c = _events;
    if (c == null || c.isClosed) return;
    c.add(DictationEnded(failed: failed));
    unawaited(c.close());
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _end();
  }

  void _onError(SpeechRecognitionError e) {
    // Never the words; only the code decides what happens next.
    final msg = e.errorMsg;
    final silence = msg == 'error_no_match' || msg == 'error_speech_timeout';
    if (!_heard && _onDevice && !silence && msg != 'error_permission') {
      // This phone cannot recognize the language on device: once more through the system
      // service (the explainer told the parent it may use the platform's servers).
      _onDevice = false;
      unawaited(_start());
      return;
    }
    _end(failed: !silence);
  }

  @override
  Future<DictationReady> prepare(String languageCode) async {
    bool ok;
    try {
      ok = await _stt.initialize(onError: _onError, onStatus: _onStatus);
    } on PlatformException {
      ok = false;
    }
    if (!ok) {
      final permitted = await _stt.hasPermission.catchError(
        (Object _) => false,
      );
      return permitted ? DictationReady.unavailable : DictationReady.denied;
    }
    final locales = await _stt.locales().catchError(
      (Object _) => <LocaleName>[],
    );
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();
    final mine = [
      for (final l in locales)
        if (norm(l.localeId).split('_').first == languageCode) l.localeId,
    ];
    final country = languageCode == 'vi' ? 'vn' : 'us';
    _localeId =
        mine.where((id) => norm(id).endsWith('_$country')).firstOrNull ??
        mine.firstOrNull;
    // An empty list (some Android services) does not mean "none": try the usual tag.
    if (_localeId == null && locales.isNotEmpty) return DictationReady.language;
    _localeId ??= languageCode == 'vi' ? 'vi_VN' : 'en_US';
    return DictationReady.ready;
  }

  Future<void> _start() async {
    try {
      await _stt.listen(
        onResult: (r) {
          if (r.recognizedWords.isNotEmpty) _heard = true;
          _add(DictationWords(r.recognizedWords, done: r.finalResult));
        },
        onSoundLevelChange: (db) {
          // Android reports about −2…10 dB, iOS about −50…0: normalise to what was seen.
          _lo = math.min(_lo, db);
          _hi = math.max(_hi, db);
          final span = _hi - _lo;
          _add(DictationLevel(span < 1 ? 0 : ((db - _lo) / span).clamp(0, 1)));
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          onDevice: _onDevice,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          localeId: _localeId,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        ),
      );
    } on Object {
      _end(failed: true);
    }
  }

  @override
  Stream<DictationEvent> listen(String languageCode) {
    unawaited(_events?.close());
    final c = StreamController<DictationEvent>();
    _events = c;
    _heard = false;
    _onDevice = true;
    _language = languageCode;
    _lo = double.infinity;
    _hi = -double.infinity;
    unawaited(_start());
    return c.stream;
  }

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } on Object {
      _end();
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } on Object {
      // Nothing to keep.
    }
    _end();
  }

  @override
  String toString() => 'SpeechDictation($_language)';
}

/// How a listen ended, for the composer's note.
enum VoiceStop {
  done,
  canceled,
  noSpeech,
  denied,
  unavailable,
  language,
  failed,
}

enum VoicePhase { idle, starting, listening, stopping }

/// One dictation into [text]: what was typed before stays first, the words follow and update
/// live; "×" / swipe left puts the field back as it was. Stops by itself after
/// [silence] without new words (and [firstWords] before the first one).
class VoiceSession extends ChangeNotifier {
  VoiceSession({
    required this.dictation,
    required this.text,
    required this.onEnd,
    this.silence = const Duration(seconds: 2),
    this.firstWords = const Duration(seconds: 6),
  });

  final AssistantDictation dictation;
  final TextEditingController text;
  final void Function(VoiceStop stop) onEnd;
  final Duration silence;
  final Duration firstWords;

  var phase = VoicePhase.idle;
  var level = 0.0;

  /// Unavailable / no language this session: the mic hides.
  var hidden = false;
  String _before = '';
  String _words = '';
  StreamSubscription<DictationEvent>? _sub;
  Timer? _quiet;
  Timer? _drain;
  var _disposed = false;

  bool get active => phase != VoicePhase.idle;
  bool get listening => phase == VoicePhase.listening;
  bool get heard => _words.isNotEmpty;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start(String languageCode) async {
    if (active || hidden) return;
    phase = VoicePhase.starting;
    _notify();
    DictationReady ready;
    try {
      ready = await dictation.prepare(languageCode);
    } on Object {
      ready = DictationReady.unavailable;
    }
    if (_disposed || phase != VoicePhase.starting) return;
    if (ready != DictationReady.ready) {
      if (ready != DictationReady.denied) hidden = true;
      _finish(switch (ready) {
        DictationReady.denied => VoiceStop.denied,
        DictationReady.language => VoiceStop.language,
        _ => VoiceStop.unavailable,
      });
      return;
    }
    _before = text.text.trimRight();
    _words = '';
    level = 0;
    phase = VoicePhase.listening;
    _arm(firstWords);
    _notify();
    _sub = dictation.listen(languageCode).listen(_on, onDone: _ended);
  }

  void _arm(Duration d) {
    _quiet?.cancel();
    _quiet = Timer(d, () => unawaited(stop()));
  }

  void _on(DictationEvent e) {
    switch (e) {
      case DictationWords(:final text, :final done):
        if (text != _words) {
          _words = text;
          _write();
          _arm(silence);
        }
        if (done) unawaited(stop());
        _notify();
      case DictationLevel(level: final l):
        level = l;
        _notify();
      case DictationEnded(:final failed):
        _ended(failed: failed);
    }
  }

  void _ended({bool failed = false}) {
    if (phase == VoicePhase.idle) return;
    _finish(
      _words.isNotEmpty
          ? VoiceStop.done
          : (failed ? VoiceStop.failed : VoiceStop.noSpeech),
    );
  }

  void _write() {
    final value = [
      if (_before.isNotEmpty) _before,
      if (_words.isNotEmpty) _words,
    ].join(' ');
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  /// "Dừng": keeps the words (the last ones may still come, briefly).
  Future<void> stop() async {
    if (phase != VoicePhase.listening) return;
    phase = VoicePhase.stopping;
    _quiet?.cancel();
    _notify();
    _drain = Timer(const Duration(milliseconds: 900), _ended);
    try {
      await dictation.stop();
    } on Object {
      _ended(failed: true);
    }
  }

  /// "×" / swipe left: the field goes back to what was typed before.
  Future<void> cancel() async {
    if (!active) return;
    final wasStarting = phase == VoicePhase.starting;
    phase = VoicePhase.idle;
    if (!wasStarting) {
      text.value = TextEditingValue(
        text: _before,
        selection: TextSelection.collapsed(offset: _before.length),
      );
    }
    _words = '';
    _cleanup();
    try {
      await dictation.cancel();
    } on Object {
      // Already stopped.
    }
    _notify();
    onEnd(VoiceStop.canceled);
  }

  /// A call, the app going to the background, the screen closing: stop and keep the words.
  void interrupt() {
    if (phase == VoicePhase.listening) unawaited(stop());
    if (phase == VoicePhase.starting) unawaited(cancel());
  }

  void _cleanup() {
    _quiet?.cancel();
    _drain?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    level = 0;
  }

  void _finish(VoiceStop stop) {
    if (phase == VoicePhase.idle) return;
    phase = VoicePhase.idle;
    _cleanup();
    _notify();
    if (!_disposed) onEnd(stop);
  }

  @override
  void dispose() {
    _disposed = true;
    if (active) unawaited(dictation.cancel().catchError((Object _) {}));
    _cleanup();
    super.dispose();
  }
}

/// Whether this phone's speech service may leave the device (the explainer says so plainly).
String voiceServerLine(AppLocalizations l10n) {
  if (kIsWeb) return l10n.asVoiceIntroServerAndroid;
  try {
    return Platform.isIOS
        ? l10n.asVoiceIntroServerIos
        : l10n.asVoiceIntroServerAndroid;
  } on Object {
    return l10n.asVoiceIntroServerAndroid;
  }
}

/// The first-run explainer before the system asks for the microphone: what is heard, who turns
/// it into words, what is kept (nothing) and what it costs (nothing). True = go on.
Future<bool> showVoiceIntro(BuildContext context) async {
  final ok = await showClSheet<bool>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cl = sheet.cl;
      Widget row(ClIcons icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: ClSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 16, color: cl.colors.mintText),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                text,
                style: cl.text.label.copyWith(
                  height: 1.4,
                  color: cl.colors.ink,
                ),
              ),
            ),
          ],
        ),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.asVoiceIntroTitle),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(ClIcons.edit, l10n.asVoiceIntroWords),
                  row(ClIcons.globe, voiceServerLine(l10n)),
                  row(ClIcons.lock, l10n.asVoiceIntroNothingKept),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.asVoiceIntroAllow,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.asVoiceIntroLater,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

// ---------- Drawing ----------

/// A microphone in the app's line-icon style (no SVG of its own yet).
class MicGlyph extends StatelessWidget {
  const MicGlyph({required this.color, this.size = 20, super.key});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MicPainter(color)),
  );
}

class _MicPainter extends CustomPainter {
  _MicPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9 * s, 3.5 * s, 6 * s, 11 * s),
        Radius.circular(3 * s),
      ),
      p,
    );
    final arc = Path()
      ..moveTo(6 * s, 11.5 * s)
      ..cubicTo(6 * s, 14.8 * s, 8.7 * s, 17.5 * s, 12 * s, 17.5 * s)
      ..cubicTo(15.3 * s, 17.5 * s, 18 * s, 14.8 * s, 18 * s, 11.5 * s)
      ..moveTo(12 * s, 17.5 * s)
      ..lineTo(12 * s, 20.5 * s);
    canvas.drawPath(arc, p);
  }

  @override
  bool shouldRepaint(_MicPainter old) => old.color != color;
}

/// Five bars that follow the input level (still bars with Reduce Motion: the level only).
class VoiceLevelMeter extends StatelessWidget {
  const VoiceLevelMeter({
    required this.level,
    required this.color,
    this.height = 16,
    super.key,
  });
  final double level;
  final Color color;
  final double height;

  static const _shape = [0.45, 0.75, 1.0, 0.75, 0.45];

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (i, f) in _shape.indexed) ...[
              if (i > 0) const SizedBox(width: 3),
              AnimatedContainer(
                duration: reduce ? Duration.zero : ClMotion.instant,
                curve: ClCurves.instant,
                width: 3,
                height: math.max(3, height * f * (0.25 + 0.75 * level)),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A soft ring that breathes around the stop button while listening (a still ring with Reduce
/// Motion); its size follows the input level a little.
class ListeningRing extends StatefulWidget {
  const ListeningRing({
    required this.child,
    required this.level,
    required this.color,
    this.size = 40,
    super.key,
  });
  final Widget child;
  final double level;
  final Color color;
  final double size;

  @override
  State<ListeningRing> createState() => _ListeningRingState();
}

class _ListeningRingState extends State<ListeningRing>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: _RingPainter(
          pulse: reduce ? null : _pulse,
          level: widget.level,
          color: widget.color,
        ),
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.level, required this.color, this.pulse})
    : super(repaint: pulse);
  final Animation<double>? pulse;
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final t = pulse?.value;
    if (t == null) {
      canvas.drawCircle(
        c,
        r + 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.45),
      );
      return;
    }
    final grow = 3 + 7 * t + 4 * level;
    canvas.drawCircle(
      c,
      r + grow,
      Paint()..color = color.withValues(alpha: 0.28 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.level != level || old.color != color || old.pulse != pulse;
}
