import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'media_bytes.dart';

/// What the 10f viewer shows for a playing video: the frame plus our own controls.
@immutable
class ViewerVideoState {
  const ViewerVideoState({
    this.playing = false,
    this.completed = false,
    this.buffering = false,
    this.rendered = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool playing;
  final bool completed;
  final bool buffering;

  /// A frame is really on screen: until then the viewer keeps the poster up, so play does not
  /// flash black. media_kit's "first frame rendered" fires when the texture is sized, before
  /// anything is drawn, so this also waits for playback to move.
  final bool rendered;
  final Duration position;
  final Duration duration;

  ViewerVideoState copyWith({
    bool? playing,
    bool? completed,
    bool? buffering,
    bool? rendered,
    Duration? position,
    Duration? duration,
  }) => ViewerVideoState(
    playing: playing ?? this.playing,
    completed: completed ?? this.completed,
    buffering: buffering ?? this.buffering,
    rendered: rendered ?? this.rendered,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}

/// One video in the viewer. The app plays with media_kit; widget tests use a fake, since the
/// native player cannot run there.
abstract class ViewerVideo {
  ValueListenable<ViewerVideoState> get state;

  /// Opens the cached file or the streamed original and starts playing.
  Future<void> open(MediaSource source);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// The frame, letterboxed on black, without the package's controls.
  Widget view(BuildContext context);
  Future<void> dispose();
}

/// A media_kit player set up for streaming from Storage: a larger read-ahead and, after a
/// stall, waiting for a few seconds of video instead of one, so a slow connection plays in
/// longer runs rather than stopping every second (mpv: cache-pause-wait, cache-secs).
Player streamingPlayer() {
  final player = Player(
    configuration: const PlayerConfiguration(bufferSize: 128 * 1024 * 1024),
  );
  final native = player.platform;
  if (native is NativePlayer) {
    for (final (name, value) in const [
      ('cache-pause-initial', 'yes'),
      ('cache-pause-wait', '3'),
      ('cache-secs', '60'),
      ('demuxer-readahead-secs', '60'),
    ]) {
      unawaited(native.setProperty(name, value).catchError((Object _) {}));
    }
  }
  return player;
}

/// Makes a player per video page; overridden in tests.
final viewerVideoProvider = Provider<ViewerVideo Function()>(
  (_) => MediaKitViewerVideo.new,
);

/// media_kit (libmpv) playback; MediaKit is initialised in bootstrap.
class MediaKitViewerVideo implements ViewerVideo {
  MediaKitViewerVideo() {
    // The texture exists before the first frame arrives.
    _controller = VideoController(_player);
    _subs.addAll([
      _player.stream.playing.listen((v) => _set(_value.copyWith(playing: v))),
      _player.stream.completed.listen((v) {
        _set(_value.copyWith(completed: v));
        _maybeRendered();
      }),
      _player.stream.buffering.listen(
        (v) => _set(_value.copyWith(buffering: v)),
      ),
      _player.stream.position.listen((v) {
        _set(_value.copyWith(position: v));
        _maybeRendered();
      }),
      _player.stream.duration.listen((v) => _set(_value.copyWith(duration: v))),
    ]);
    unawaited(
      _controller.waitUntilFirstFrameRendered.then((_) {
        _sized = true;
        _maybeRendered();
      }, onError: (Object _) {}),
    );
  }

  var _sized = false;

  /// Sized texture and a moving clock (or the end): a frame has been drawn. One more frame of
  /// Flutter so the texture is composited before the poster goes.
  void _maybeRendered() {
    if (_value.rendered || !_sized) return;
    if (_value.position <= Duration.zero && !_value.completed) return;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _set(_value.copyWith(rendered: true)),
    );
    SchedulerBinding.instance.scheduleFrame();
  }

  final _player = streamingPlayer();
  late final VideoController _controller;
  final _subs = <StreamSubscription<Object?>>[];
  final _state = ValueNotifier(const ViewerVideoState());
  var _disposed = false;

  ViewerVideoState get _value => _state.value;

  void _set(ViewerVideoState v) {
    if (!_disposed) _state.value = v;
  }

  @override
  ValueListenable<ViewerVideoState> get state => _state;

  @override
  Future<void> open(MediaSource source) async {
    await _player.open(Media(source.uri, httpHeaders: source.headers));
  }

  @override
  Future<void> play() async {
    // At the end, play again from the start (like the system player).
    if (_value.completed) await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Widget view(BuildContext context) => Video(
    controller: _controller,
    controls: NoVideoControls,
    fill: const Color(0xFF000000),
  );

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _state.dispose();
    await _player.dispose();
  }
}
