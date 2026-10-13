import 'dart:typed_data';

import 'package:child_life/features/auto_save/auto_save_controller.dart';
import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:child_life/features/auto_save/auto_save_home.dart';
import 'package:child_life/features/auto_save/auto_save_native.dart';
import 'package:child_life/features/auto_save/auto_save_review.dart';
import 'package:child_life/features/auto_save/auto_save_store.dart';
import 'package:child_life/features/auto_save/auto_save_today.dart';
import 'package:child_life/features/auto_save/auto_save_widgets.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// Tự lưu kỷ niệm screens (D-066): the AS01 entry, the AS02 intro, the AS14 paused state and
/// the AS07 review grid with near-copies grouped (P-146).
void main() {
  const channel = MethodChannel('childlife/autosave');
  final t0 = DateTime(2026, 10, 12, 9);
  Float32List v(List<double> xs) => Float32List.fromList(xs);
  late _MemoryStore saved;
  var access = 'full';

  setUp(() {
    saved = _MemoryStore();
    access = 'full';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'access':
            case 'requestAccess':
              return access;
            case 'changes':
              return {'ids': <String>[], 'token': Uint8List(1)};
            case 'analyze':
              return <Object>[];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  AutoSaveStore store() => saved;

  List<Override> overrides({bool available = true}) => [
    ...careOverrides(),
    ...memoryOverrides(),
    familyStorageProvider.overrideWith((ref, babyId) async => mockStorage()),
    autoSaveAvailableProvider.overrideWithValue(available),
    autoSaveNativeProvider.overrideWithValue(AutoSaveNative(supported: true)),
    autoSaveStoreProvider.overrideWithValue(store()),
    libraryThumbLoaderProvider.overrideWithValue((_) async => null),
    libraryLocalProvider.overrideWith((ref, id) async => true),
  ];

  Candidate candidate(
    String id,
    Duration at,
    Float32List print,
    double quality,
  ) => Candidate(
    asset: AssetInfo(
      id: id,
      captureAt: t0.add(at),
      width: 4032,
      height: 3024,
      print: print,
      faces: [
        FaceInfo(size: 0.3, quality: quality, print: v([1, 0, 0])),
      ],
    ),
    match: const FaceMatch(babyId: teddyId, distance: 0.05, face: 0),
  );

  AutoSaveState ready({List<Candidate> pending = const []}) => AutoSaveState(
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
    lastScanAt: t0,
    lastScanCount: 46,
    pending: pending,
  );

  testWidgets('AS01: parents see the entry on Kỷ niệm and it opens Tự lưu', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      const Scaffold(body: MemoriesScreen()),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tự lưu kỷ niệm'), findsWidgets);
    expect(find.text('Beta miễn phí'), findsWidgets);
    await tester.tap(find.text('Tự lưu kỷ niệm').first);
    await tester.pumpAndSettle();
    expect(visits.last.location, '/memories/auto-save');
  });

  testWidgets(
    'AS01: hidden where Tự lưu is not offered (Android, prod without the flag)',
    (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: overrides(available: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tự lưu kỷ niệm'), findsNothing);
    },
  );

  testWidgets('AS02 until set up; AS14 when photos are not allowed', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const AutoSaveHomeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu thiết lập'), findsOneWidget);
    expect(
      find.textContaining('không gửi đi'),
      findsOneWidget,
      reason: 'P-147',
    );
  });

  testWidgets('AS14: paused without photo access, manual add still there', (
    tester,
  ) async {
    access = 'denied';
    await store().save(ready());
    await pumpRouted(
      tester,
      const AutoSaveHomeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Child Life chưa được xem ảnh'), findsOneWidget);
    expect(find.text('Mở Cài đặt điện thoại'), findsOneWidget);
    expect(find.text('Thêm ảnh thủ công'), findsOneWidget);
  });

  testWidgets(
    'AS07: near-copies collapse behind "+n" with the best pre-ticked',
    (tester) async {
      await store().save(
        ready(
          pending: [
            candidate('blurry', Duration.zero, v([1, 0.01]), 0.2),
            candidate('sharp', const Duration(seconds: 4), v([1, 0.02]), 0.9),
            candidate('later', const Duration(minutes: 30), v([0, 1]), 0.5),
          ],
        ),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const AutoSaveReviewScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('Đã chọn 2 · 2 ảnh, 0 video'), findsOneWidget);
      expect(find.textContaining('Đã gộp 1 ảnh giống nhau'), findsOneWidget);

      // Opening the group shows both, the clearest first.
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('2 ảnh giống nhau · đã chọn 1'), findsOneWidget);
      expect(find.text('Rõ nhất'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục với 2 mục'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/auto-save/review/confirm');
      final decision = visits.last.extra! as AutoSaveDecision;
      expect([
        for (final c in decision.chosen) c.asset.id,
      ], unorderedEquals(['sharp', 'later']));
      expect(decision.reviewed, hasLength(3));
    },
  );

  testWidgets('AR02 → AR05 → AR08: banner, quick review, skip with undo', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          candidate('a', Duration.zero, v([1, 0]), 0.5),
          candidate('b', const Duration(minutes: 10), v([0, 1]), 0.5),
          candidate('c', const Duration(minutes: 20), v([1, 1]), 0.5),
        ],
      ),
    );
    await pumpRouted(
      tester,
      Scaffold(body: ListView(children: const [AutoSaveTodayBanner()])),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 ảnh mới có thể có Teddy'), findsOneWidget);
    expect(find.text('Từ thư viện máy · chưa tải lên'), findsOneWidget);

    await tester.tap(find.text('Xem & chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Tải lên 3 mục'), findsOneWidget);
    expect(find.text('Nhật ký · Chỉ ba mẹ'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua lần này'));
    await tester.pumpAndSettle();
    expect(find.text('Đã bỏ qua 3 ảnh · sẽ không gợi ý lại'), findsOneWidget);
    expect(saved.state.pending, isEmpty);
    expect(find.byKey(const Key('autoSaveBanner')), findsNothing);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(saved.state.pending, hasLength(3));
    expect(find.byKey(const Key('autoSaveBanner')), findsOneWidget);
  });

  testWidgets('AR02 "Để sau" hides the banner until new suggestions', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          candidate('a', Duration.zero, v([1, 0]), 0.5),
        ],
      ),
    );
    await pumpRouted(
      tester,
      Scaffold(body: ListView(children: const [AutoSaveTodayBanner()])),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('autoSaveBanner')), findsNothing);
    expect(saved.state.bannerHidden, {'a'});
  });

  testWidgets('AR02: a dot on Kỷ niệm while suggestions wait', (tester) async {
    await store().save(
      ready(
        pending: [
          candidate('a', Duration.zero, v([1, 0]), 0.5),
        ],
      ),
    );
    final (_, container) = await pumpRouted(
      tester,
      const Scaffold(body: SizedBox()),
      overrides: overrides(),
    );
    final dot = container.listen(autoSaveTabDotProvider, (_, _) {});
    await tester.pumpAndSettle();
    expect(dot.read(), isTrue);
    await container
        .read(autoSaveProvider.notifier)
        .skip(container.read(autoSaveProvider).state.pending);
    await tester.pumpAndSettle();
    expect(dot.read(), isFalse);
  });
}

/// Widget tests run in fake time, where file I/O never finishes: the state stays in memory.
class _MemoryStore extends AutoSaveStore {
  AutoSaveState state = const AutoSaveState();

  @override
  Future<AutoSaveState> load() async => state;

  @override
  Future<void> save(AutoSaveState s) async => state = s;

  @override
  Future<void> clear() async => state = const AutoSaveState();
}
