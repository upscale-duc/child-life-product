import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  /// The first frame is on screen: until then the viewer keeps the poster up, so play does
  /// not flash black.
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

  /// Opens a local file (the Rules-gated, cached original) and starts playing.
  Future<void> open(String filePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// The frame, letterboxed on black, without the package's controls.
  Widget view(BuildContext context);
  Future<void> dispose();
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
      _player.stream.completed.listen(
        (v) => _set(_value.copyWith(completed: v)),
      ),
      _player.stream.buffering.listen(
        (v) => _set(_value.copyWith(buffering: v)),
      ),
      _player.stream.position.listen((v) => _set(_value.copyWith(position: v))),
      _player.stream.duration.listen((v) => _set(_value.copyWith(duration: v))),
    ]);
    unawaited(
      _controller.waitUntilFirstFrameRendered.then(
        (_) => _set(_value.copyWith(rendered: true)),
        onError: (Object _) {},
      ),
    );
  }

  final _player = Player();
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
  Future<void> open(String filePath) async {
    await _player.open(Media(Uri.file(filePath).toString()));
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
