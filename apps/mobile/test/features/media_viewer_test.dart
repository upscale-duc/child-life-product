import 'dart:io';

import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/media_picker.dart';
import 'package:child_life/features/memories/media_viewer.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/social_widgets.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/features/memories/viewer_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// The native player cannot run in widget tests: this one records what the viewer asks for.
class _FakeVideo implements ViewerVideo {
  final calls = <String>[];
  final _state = ValueNotifier(
    const ViewerVideoState(duration: Duration(seconds: 24)),
  );

  @override
  ValueListenable<ViewerVideoState> get state => _state;

  @override
  Future<void> open(String filePath) async {
    calls.add('open');
    _state.value = _state.value.copyWith(playing: true);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _state.value = _state.value.copyWith(playing: true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _state.value = _state.value.copyWith(playing: false);
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek ${position.inSeconds}');
    _state.value = _state.value.copyWith(position: position);
  }

  /// The native player draws its first frame.
  void render() => _state.value = _state.value.copyWith(rendered: true);

  @override
  Widget view(BuildContext context) => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async => calls.add('dispose');
}

class _FileBytes extends FakeMediaBytes {
  @override
  Future<File> file(String path) async => File('/tmp/video.mp4');
}

class _FakePicker implements MediaLibraryPicker {
  int? max;
  VideoLimits? limits;

  @override
  Future<List<PickedMedia>?> pick(
    BuildContext context, {
    required int max,
    required VideoLimits limits,
  }) async {
    this.max = max;
    this.limits = limits;
    return [pickedPhoto('a.jpg'), pickedVideo('b.mov')];
  }
}

final _at = DateTime(2026, 10, 9, 9, 20);

double _chromeOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byKey(const Key('viewerChrome')))
    .opacity;

/// One tap on the media; a photo waits out the double-tap window first.
Future<void> _tapMedia(
  WidgetTester tester, [
  Offset at = const Offset(187, 400),
]) async {
  await tester.tapAt(at);
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

ScrollPhysics? _pagerPhysics(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).physics;

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  group('10f viewer', () {
    testWidgets('chrome floats over the media; a tap hides and shows it', (
      tester,
    ) async {
      final items = [
        mediaItem('mem1', _at, colour: 'peach'),
        mediaItem('mem1', _at, colour: 'sky'),
      ];
      await pumpRouted(
        tester,
        MediaViewer(items: items, start: 0),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await tester.pumpAndSettle();

      // The page fills the screen: the chrome takes no layout space.
      expect(tester.getSize(find.byType(PageView)), const Size(375, 812));
      expect(_chromeOpacity(tester), 1);
      expect(find.text('Gia đình'), findsOneWidget);

      // A strip of thumbnails, not dots; a tap on one jumps to it.
      final thumbs = find.byKey(const Key('viewerThumbs'));
      expect(thumbs, findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNothing);
      await tester.tap(find.bySemanticsLabel('Mục 2 trên 2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1,
      );
      // It is the last thing on screen.
      expect(
        tester.getRect(thumbs).top,
        greaterThan(tester.getRect(find.byType(RailButton).last).bottom),
      );
      // A swipe that starts on the caption, over the bottom fade, still pages.
      await tester.flingFrom(
        Offset(60, tester.getRect(thumbs).top - 24),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );

      await _tapMedia(tester);
      expect(_chromeOpacity(tester), 0);
      // Hidden chrome lets taps through to the media.
      final ignoring = tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.byKey(const Key('viewerChrome')),
              matching: find.byType(IgnorePointer),
            ),
          )
          .first;
      expect(ignoring.ignoring, isTrue);

      await _tapMedia(tester);
      expect(_chromeOpacity(tester), 1);
    });

    testWidgets('double tap zooms a photo and holds the pager until unzoomed', (
      tester,
    ) async {
      final items = [
        mediaItem('mem1', _at, colour: 'peach'),
        mediaItem('mem1', _at, colour: 'sky'),
      ];
      await pumpRouted(
        tester,
        MediaViewer(items: items, start: 0),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await tester.pumpAndSettle();
      expect(_pagerPhysics(tester), isNull);

      Future<void> doubleTap() async {
        await tester.tapAt(const Offset(187, 400));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(const Offset(187, 400));
        await tester.pumpAndSettle();
      }

      await doubleTap();
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer).first,
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(2),
      );
      expect(_pagerPhysics(tester), isA<NeverScrollableScrollPhysics>());
      // A double tap is not a chrome toggle.
      expect(_chromeOpacity(tester), 1);

      await doubleTap();
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1, 0.01),
      );
      expect(_pagerPhysics(tester), isNull);

      // Unzoomed, a swipe pages.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      final pager = tester.widget<PageView>(find.byType(PageView));
      expect(pager.controller!.page, 1);
    });

    testWidgets('a video plays in place with play / pause and a scrubber', (
      tester,
    ) async {
      mediaBytes = _FileBytes();
      final video = _FakeVideo();
      final items = [
        mediaItem('mem1', _at, colour: 'sky', video: true, durationMs: 24000),
      ];
      await pumpRouted(
        tester,
        MediaViewer(items: items, start: 0),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(),
          viewerVideoProvider.overrideWithValue(() => video),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.bySemanticsLabel('Phát video'));
      await tester.pumpAndSettle();

      expect(video.calls, ['open']);
      expect(find.byType(Slider), findsOneWidget);
      // The poster covers the player until its first frame: no black flash.
      Finder posterImage() => find.descendant(
        of: find.byKey(const ValueKey('poster')),
        matching: find.byType(Image),
      );
      expect(posterImage(), findsOneWidget);
      video.render();
      await tester.pumpAndSettle();
      expect(posterImage(), findsNothing);
      expect(find.bySemanticsLabel('Tạm dừng video'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Tạm dừng video'));
      await tester.pumpAndSettle();
      expect(video.calls.last, 'pause');

      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(video.calls.last, startsWith('seek'));

      // Icon-only actions in a column on the right; the scrubber is the last row.
      for (final label in ['Tải về', 'Chia sẻ', 'Yêu thích']) {
        expect(find.text(label), findsNothing);
      }
      final rail = find.byType(RailButton);
      expect(rail, findsNWidgets(4));
      final xs = {
        for (final e in rail.evaluate())
          tester.getCenter(find.byWidget(e.widget)).dx,
      };
      expect(xs, hasLength(1));
      expect(xs.single, greaterThan(375 / 2));
      final slider = tester.getRect(find.byType(Slider));
      expect(slider.top, greaterThan(tester.getRect(rail.last).bottom));
      // Play / pause sits on the caption's left edge.
      final play = find.bySemanticsLabel('Phát video');
      final lefts = [
        for (var i = 0; i < play.evaluate().length; i++)
          tester.getRect(play.at(i)).left,
      ];
      expect(lefts.reduce((a, b) => a < b ? a : b), 16);

      // A tap on the video hides the controls with the rest of the chrome.
      await _tapMedia(tester, const Offset(187, 300));

      expect(_chromeOpacity(tester), 0);
    });

    testWidgets('Reduce Motion: the chrome hides at once', (tester) async {
      await pumpRouted(
        tester,
        MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            disableAnimations: true,
          ),
          child: MediaViewer(
            items: [mediaItem('mem1', _at, colour: 'peach')],
            start: 0,
          ),
        ),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(187, 400));
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 10));
      final opacity = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('viewerChrome')),
      );
      expect(opacity.opacity, 0);
      expect(opacity.duration, Duration.zero);
    });
  });

  group('10g library', () {
    testWidgets(
      'the picker gets the batch limit (R-102) and video limits (D-011)',
      (tester) async {
        final picker = _FakePicker();
        List<PickedMedia>? picked;
        await pumpRouted(
          tester,
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async =>
                    picked = await pickFromLibrary(context, ref),
                child: const Text('pick'),
              ),
            ),
          ),
          overrides: [
            ...careOverrides(),
            ...memoryOverrides(),
            mediaLibraryPickerProvider.overrideWithValue(picker),
            videoLimitsProvider.overrideWith(
              (ref) => Stream.value(
                const VideoLimits(maxDuration: Duration(minutes: 3)),
              ),
            ),
          ],
        );
        await tester.tap(find.text('pick'));
        await tester.pumpAndSettle();
        expect(picker.max, 30);
        expect(picker.limits!.maxDuration, const Duration(minutes: 3));
        expect(picked!.map((p) => p.type), [MediaKind.photo, MediaKind.video]);
      },
    );
  });
}
