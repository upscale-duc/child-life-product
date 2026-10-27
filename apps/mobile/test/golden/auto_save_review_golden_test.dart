@Tags(['golden'])
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auto_save/auto_save_controller.dart';
import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:child_life/features/auto_save/auto_save_native.dart';
import 'package:child_life/features/auto_save/auto_save_review.dart';
import 'package:child_life/features/auto_save/auto_save_store.dart';
import 'package:child_life/features/auto_save/auto_save_widgets.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/memories/upload_queue.dart'
    show PickedMedia;
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// AS07 "Có thể có {tên}" (Tự lưu kỷ niệm review): two weeks of age, photos and videos over
/// three days, one group of near-copies and one "Đã có", the grid and the opened "Đã có" section, in Light / Night care × vi / en at 375 × 812.
/// Synthetic data only. Regenerate on macOS: flutter test --tags golden --update-goldens
class _Store extends AutoSaveStore {
  _Store(this.state);
  AutoSaveState state;
  @override
  Future<AutoSaveState> load() async => state;
  @override
  Future<void> save(AutoSaveState s) async => state = s;
  @override
  Future<void> clear() async => state = const AutoSaveState();
}

const _tints = [
  Color(0xFFF6C6AE),
  Color(0xFFA9E3D3),
  Color(0xFFF9DE97),
  Color(0xFFD7C8F0),
  Color(0xFFB5D3F2),
];

Future<Uint8List> _png(Color c) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(c, BlendMode.src);
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  const channel = MethodChannel('childlife/autosave');
  // Teddy was born 17 Sep; these fall in weeks 4 and 5 of age.
  final t0 = DateTime(2026, 10, 18, 9);
  Float32List v(List<double> xs) => Float32List.fromList(xs);

  Candidate candidate(
    String id,
    Duration at, {
    bool video = false,
    int durationMs = 0,
    List<double> print = const [1, 0],
  }) => Candidate(
    asset: AssetInfo(
      id: id,
      captureAt: t0.add(at),
      video: video,
      durationMs: durationMs,
      width: 4032,
      height: 3024,
      print: v(print),
      faces: [
        FaceInfo(size: 0.3, quality: 0.6, print: v([1, 0, 0])),
      ],
    ),
    match: const FaceMatch(babyId: teddyId, distance: 0.05, face: 0),
  );

  final pending = [
    // Week 5: today-ish, a day earlier, two near-copies grouped.
    candidate('a1', const Duration(days: 6), video: true, durationMs: 36000),
    candidate('a2', const Duration(days: 6, hours: 1), print: [0, 1]),
    candidate('a3', const Duration(days: 5), video: true, durationMs: 81000),
    candidate('a4', const Duration(days: 5, hours: 2), print: [0.2, 1]),
    candidate(
      'a5',
      const Duration(days: 5, hours: 2, seconds: 20),
      print: [0.21, 1],
    ),
    candidate('a6', const Duration(days: 5, hours: 3), print: [1, 1]),
    candidate('a7', const Duration(days: 4), print: [0.5, 0.2]),
    // Week 4.
    candidate('b1', const Duration(days: -2), print: [0.7, 0.1]),
    candidate('b2', const Duration(days: -3), video: true, durationMs: 12000),
  ];

  for (final mode in const [
    'review',
    'saved_open',
    'weeks',
    'as10_full',
    'as10_prep',
  ]) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        final name = mode.startsWith('as10') ? mode : 'as07_$mode';
        final confirm = mode.startsWith('as10');
        final chosen = pending.take(5).toList();
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (call) async {
                switch (call.method) {
                  case 'access':
                  case 'requestAccess':
                    return 'full';
                  case 'changes':
                    return {'ids': <String>[], 'token': Uint8List(1)};
                  case 'analyze':
                    return <Object>[];
                  default:
                    return null;
                }
              });
          addTearDown(
            () => TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
          final thumbs = await tester.runAsync(
            () async => [for (final c in _tints) await _png(c)],
          );
          final store = _Store(
            AutoSaveState(
              enabled: true,
              consentVersion: autoSaveConsentVersion,
              consentAt: t0,
              babies: {
                teddyId: AutoSaveBaby(
                  samples: [
                    SampleFace(ref: 'm:1', print: v([1, 0, 0])),
                  ],
                ),
              },
              allowed: const {teddyId: true},
              lastScanAt: t0.add(const Duration(days: 6, hours: 6)),
              lastScanCount: 46,
              pending: pending,
            ),
          );
          await pumpRouted(
            tester,
            confirm
                ? AutoSaveConfirmScreen(
                    decision: AutoSaveDecision(
                      chosen: chosen,
                      reviewed: chosen,
                    ),
                  )
                : const AutoSaveReviewScreen(),
            locale: locale,
            palette: palette,
            overrides: [
              ...careOverrides(),
              ...memoryOverrides(),
              familyStorageProvider.overrideWith(
                (ref, babyId) async => mode == 'as10_full'
                    // Nothing left: "Thêm dung lượng" is the only way on.
                    ? FamilyStorage(
                        familyId: 'f_1',
                        isOwner: true,
                        quotaBytes: 10 << 30,
                        usedBytes: 10 << 30,
                        binBytes: 0,
                        notesBytes: 0,
                        babies: const [],
                        largestVideos: const [],
                      )
                    : mockStorage(),
              ),
              // AS10 preparing: the two oldest can't be read, the next is still being read.
              libraryResolverProvider.overrideWithValue(
                (id) => id == 'a3' || id == 'a4'
                    ? Future<PickedMedia?>.value()
                    : Completer<PickedMedia?>().future,
              ),
              autoSaveAvailableProvider.overrideWithValue(true),
              autoSaveEventSinkProvider.overrideWithValue((_, _) async {}),
              autoSaveNativeProvider.overrideWithValue(
                AutoSaveNative(supported: true),
              ),
              autoSaveStoreProvider.overrideWithValue(store),
              libraryThumbLoaderProvider.overrideWithValue(
                (id) async => thumbs![id.codeUnitAt(1) % thumbs.length],
              ),
              libraryLocalProvider.overrideWith((ref, id) async => true),
              // One the app thinks is already in Kỷ niệm: unticked, still pickable.
              alreadySavedProvider.overrideWith((ref) => {'a6'}),
              // Already in Kỷ niệm: a few from week 6, more from week 5, for the week sheet's bars.
              completeMediaProvider.overrideWith(
                (ref, key) => AsyncValue.data([
                  for (var i = 0; i < 3; i++)
                    mediaItem('m6', t0.add(Duration(days: 5, hours: i))),
                  for (var i = 0; i < 9; i++)
                    mediaItem('m5', t0.subtract(Duration(days: 2, hours: i))),
                ]),
              ),
            ],
          );
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
          if (mode == 'as10_prep') {
            await tester.tap(find.byKey(const Key('autoSaveUpload')));
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
          if (mode == 'weeks') {
            await tester.tap(find.byKey(const Key('autoSaveWeekPill')));
            await tester.pumpAndSettle();
          }
          if (mode == 'saved_open') {
            // Scrolled to the end, "Đã có trong Kỷ niệm" opened.
            final saved = find.byKey(const Key('autoSaveSavedSection'));
            await tester.scrollUntilVisible(
              saved,
              300,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(saved);
            await tester.pumpAndSettle();
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
          }
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/as/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
