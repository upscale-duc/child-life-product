import 'dart:async';
import 'dart:typed_data';

import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/auto_save/auto_save_controller.dart';
import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:child_life/features/auto_save/auto_save_home.dart';
import 'package:child_life/features/auto_save/auto_save_native.dart';
import 'package:child_life/features/auto_save/auto_save_review.dart';
import 'package:child_life/features/auto_save/auto_save_setup.dart';
import 'package:child_life/features/auto_save/auto_save_store.dart';
import 'package:child_life/features/auto_save/auto_save_today.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/features/auto_save/auto_save_widgets.dart';
import 'package:child_life/features/me/me_widgets.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/premium_v2_fixtures.dart';

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

  List<Override> overrides({
    bool available = true,
    Future<FamilyStorage> Function()? storage,
  }) => [
    ...careOverrides(),
    ...memoryOverrides(),
    familyStorageProvider.overrideWith(
      (ref, babyId) => storage?.call() ?? Future.value(mockStorage()),
    ),
    autoSaveAvailableProvider.overrideWithValue(available),
    autoSaveEventSinkProvider.overrideWithValue((_, _) async {}),
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
    allowed: const {teddyId: true},
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
    expect(
      find.text('Beta miễn phí'),
      findsNothing,
    ); // D-121 / D-122: intro only, by tier
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

  testWidgets(
    'AS16: nothing new is a white card with a filled "Kiểm tra ảnh mới"',
    (tester) async {
      await store().save(ready());
      await pumpRouted(
        tester,
        const AutoSaveHomeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có ảnh mới có thể có Teddy'), findsOneWidget);
      // On a surface-2 notice the secondary button lost its fill (owner, 2026-10-13).
      expect(
        find.ancestor(
          of: find.text('Kiểm tra ảnh mới'),
          matching: find.byType(AutoSaveCard),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Kiểm tra ảnh mới'),
          matching: find.byType(MeNotice),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('AS12: five sharp thumbs, the last one "+n" when more wait', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 9; i++)
            candidate('p$i', Duration(hours: i), v([i.toDouble(), 1, 0]), 0.5),
        ],
      ),
    );
    await pumpRouted(
      tester,
      const AutoSaveHomeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LibraryTile), findsNWidgets(5));
    expect(find.text('+5'), findsOneWidget);
    // Not a disabled button: ClPressable would draw it at 40 % (owner, 2026-10-14).
    expect(
      find.ancestor(
        of: find.byType(LibraryTile).first,
        matching: find.byType(ClPressable),
      ),
      findsNothing,
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
    'AS07: near-copies are shown together, the clearest pre-ticked; counts are files (D-123)',
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
      // Every file is a tile and every count counts files.
      expect(find.text('Ảnh & video · 3'), findsOneWidget);
      expect(find.text('2 ảnh giống nhau · đã chọn 1'), findsOneWidget);
      expect(find.text('Rõ nhất'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Đã chọn 2 · 2 ảnh, 0 video'),
        findsOneWidget,
      );
      await tester.tap(find.text('Chọn cả nhóm'));
      await tester.pumpAndSettle();
      expect(find.text('2 ảnh giống nhau · đã chọn 2'), findsOneWidget);
      expect(find.text('Tiếp tục với 3 mục'), findsOneWidget);
      await tester.tap(find.text('Chỉ giữ ảnh rõ nhất'));
      await tester.pumpAndSettle();

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

  testWidgets('AS07 holds one upload; the rest wait for the next (D-070)', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 205; i++)
            candidate('p$i', Duration(minutes: 10 * i), v([1, 0]), 0.5),
        ],
      ),
    );
    final (visits, _) = await pumpRouted(
      tester,
      const AutoSaveReviewScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Đã chọn 200 · 200 ảnh, 0 video'),
      findsOneWidget,
    );
    expect(
      find.text('Mỗi lần tải tối đa 200 mục · 5 gợi ý còn lại chờ lần sau'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tiếp tục với 200 mục'));
    await tester.pumpAndSettle();
    final decision = visits.last.extra! as AutoSaveDecision;
    expect(decision.chosen, hasLength(200));
    expect(decision.reviewed, hasLength(200), reason: 'the rest stay pending');
  });

  testWidgets(
    'AS07 reviews a week of age at a time; a sent week reads "xong" (P-171)',
    (tester) async {
      // Teddy was born 17 Sep; t0 (12 Oct) is week 4, nine days earlier is week 3.
      await store().save(
        ready(
          pending: [
            candidate('w3a', const Duration(days: -9), v([1, 0]), 0.5),
            candidate(
              'w3b',
              const Duration(days: -9, hours: 3),
              v([0, 1]),
              0.5,
            ),
            candidate('w4', Duration.zero, v([1, 1]), 0.5),
          ],
        ),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const AutoSaveReviewScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();
      // The newest week opens first (owner, 2026-10-23), with only its own items counted;
      // the week pill lists the others, newest first.
      expect(find.text('Tuần 4 · 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('autoSaveWeekPill')));
      await tester.pumpAndSettle();
      // Each week in words: what waits (and what is already in Kỷ niệm), newest first.
      expect(
        find.descendant(
          of: find.byKey(const Key('autoSaveWeek:3')),
          matching: find.textContaining('2 chờ bạn xem'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('autoSaveWeek:4'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('autoSaveWeek:3'))).dy),
      );
      await tester.tapAt(const Offset(20, 80)); // closes the sheet
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với 1 mục'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục với 1 mục'));
      await tester.pumpAndSettle();
      final decision = visits.last.extra! as AutoSaveDecision;
      expect(decision.chosen.map((c) => c.asset.id), ['w4']);
      // Only this week is decided; week 3 stays pending for its own upload.
      expect(decision.reviewed.map((c) => c.asset.id), ['w4']);
    },
  );

  testWidgets(
    'AS07 "Tất cả các tuần" reviews every week in one upload (owner, 2026-10-26)',
    (tester) async {
      await store().save(
        ready(
          pending: [
            candidate('w3', const Duration(days: -9), v([1, 0]), 0.5),
            candidate('w4', Duration.zero, v([0, 1]), 0.5),
          ],
        ),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const AutoSaveReviewScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với 1 mục'), findsOneWidget);
      await tester.tap(find.byKey(const Key('autoSaveWeekPill')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('autoSaveWeek:all')));
      await tester.pumpAndSettle();
      expect(find.text('Tất cả các tuần · 2'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục với 2 mục'));
      await tester.pumpAndSettle();
      final decision = visits.last.extra! as AutoSaveDecision;
      expect(
        decision.chosen.map((c) => c.asset.id),
        unorderedEquals(['w3', 'w4']),
      );
    },
  );

  testWidgets(
    'AS07: a week sent earlier reads "xong"; the next week is up (P-171)',
    (tester) async {
      // Back on the review with week 4 gone from pending: it is marked done, week 3 is up.
      await store().save(
        ready(
          pending: [
            candidate('w3a', const Duration(days: -9), v([1, 0]), 0.5),
            candidate(
              'w3b',
              const Duration(days: -9, hours: 3),
              v([0, 1]),
              0.5,
            ),
          ],
        ),
      );
      final (_, container) = await pumpRouted(
        tester,
        const AutoSaveReviewScreen(),
        overrides: overrides(),
      );
      container.read(reviewedWeeksProvider.notifier).add(teddyId, 4);
      await tester.pumpAndSettle();
      expect(find.text('Tuần 3 · 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('autoSaveWeekPill')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('autoSaveWeek:4')),
          matching: find.textContaining('Đã xem hết'),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với 2 mục'), findsOneWidget);
    },
  );

  testWidgets('AS07 "Bỏ chọn hết" clears the picks to choose a few', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 3; i++)
            candidate('p$i', Duration(minutes: 10 * i), v([1, 0]), 0.5),
        ],
      ),
    );
    final (visits, _) = await pumpRouted(
      tester,
      const AutoSaveReviewScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Đã chọn 3 · 3 ảnh, 0 video'), findsOneWidget);

    await tester.tap(find.text('Bỏ chọn hết'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Đã chọn 0 · 0 ảnh, 0 video'), findsOneWidget);

    // One picked by hand, then on.
    await tester.tap(find.bySemanticsLabel('Chọn').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Đã chọn 1 · 1 ảnh, 0 video'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục với 1 mục'));
    await tester.pumpAndSettle();
    final decision = visits.last.extra! as AutoSaveDecision;
    expect(decision.chosen, hasLength(1));
    expect(decision.reviewed, hasLength(3));
  });

  testWidgets('AS07 "Chọn hết" ticks every new item again', (tester) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 3; i++)
            candidate('p$i', Duration(minutes: 10 * i), v([1, 0]), 0.5),
        ],
      ),
    );
    await pumpRouted(
      tester,
      const AutoSaveReviewScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ chọn hết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn hết'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Đã chọn 3 · 3 ảnh, 0 video'), findsOneWidget);
    expect(find.text('Bỏ chọn hết'), findsOneWidget);
  });

  testWidgets(
    'AS07 "Đã có" waits folded at the end, unticked, and can be ticked (D-123)',
    (tester) async {
      await store().save(
        ready(
          pending: [
            candidate('new', Duration.zero, v([1, 0]), 0.9),
            candidate('kept', const Duration(hours: 2), v([0, 1]), 0.5),
          ],
        ),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const AutoSaveReviewScreen(),
        overrides: [
          ...overrides(),
          alreadySavedProvider.overrideWith((ref) => {'kept'}),
        ],
      );
      await tester.pumpAndSettle();
      // Not counted with what waits (it seems saved already), not ticked, folded.
      expect(find.text('Ảnh & video · 1'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Đã chọn 1 · 1 ảnh, 0 video'),
        findsOneWidget,
      );
      final kept = find.byWidgetPredicate(
        (w) => w is LibraryTile && w.assetId == 'kept',
      );
      expect(kept, findsNothing);
      await tester.tap(find.text('Đã có trong Kỷ niệm · 1'));
      await tester.pumpAndSettle();
      expect(kept, findsOneWidget);
      // The duplicate check can be wrong: tick it.
      await tester.ensureVisible(kept);
      await tester.tapAt(tester.getTopRight(kept) + const Offset(-12, 12));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục với 2 mục'));
      await tester.pumpAndSettle();
      final decision = visits.last.extra! as AutoSaveDecision;
      expect(
        decision.chosen.map((c) => c.asset.id),
        unorderedEquals(['new', 'kept']),
      );
    },
  );
  testWidgets('AS07: ticking past the limit says so (D-070)', (tester) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 199; i++)
            candidate('p$i', Duration(minutes: 10 * i), v([1, 0]), 0.5),
          // A day of its own, newest, still in the same week of age (P-171 reviews per
          // week), so its opened group sits right under a one-tile grid.
          candidate(
            'pair-a',
            const Duration(days: 2, hours: 1),
            v([1, 0]),
            0.9,
          ),
          candidate(
            'pair-b',
            const Duration(days: 2, hours: 1, seconds: 5),
            v([1, 0.01]),
            0.5,
          ),
        ],
      ),
    );
    await pumpRouted(
      tester,
      const AutoSaveReviewScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Đã chọn 200 · 200 ảnh, 0 video'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('autoSaveRoundRest')), findsNothing);

    final second = find.byWidgetPredicate(
      (w) => w is LibraryTile && w.assetId == 'pair-b',
    );
    await tester.ensureVisible(second);
    await tester.tapAt(tester.getTopRight(second) + const Offset(-12, 12));
    await tester.pump();
    expect(find.text('Mỗi lần tải tối đa 200 mục'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Đã chọn 200 · 200 ảnh, 0 video'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('AR02: "Xem & chọn ảnh" opens the review; counts are the tiles', (
    tester,
  ) async {
    await store().save(
      ready(
        pending: [
          // A and its near-copy a2 are one tile; b another (owner, 2026-10-15).
          candidate('a', Duration.zero, v([1, 0]), 0.9),
          candidate('a2', const Duration(seconds: 20), v([1, 0]), 0.5),
          candidate('b', const Duration(hours: 2), v([0, 1]), 0.5),
        ],
      ),
    );
    final (visits, _) = await pumpRouted(
      tester,
      Scaffold(body: ListView(children: const [AutoSaveTodayBanner()])),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 ảnh mới có thể có Teddy'), findsOneWidget);
    expect(find.byType(LibraryTile), findsNWidgets(2));
    await tester.tap(find.text('Xem & chọn ảnh'));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/memories/auto-save/review');
  });

  testWidgets('AR02: a big batch opens AS07 too', (tester) async {
    await store().save(
      ready(
        pending: [
          for (var i = 0; i < 9; i++)
            candidate('p$i', Duration(minutes: 10 * i), v([1, 0]), 0.5),
        ],
      ),
    );
    final (visits, _) = await pumpRouted(
      tester,
      Scaffold(body: ListView(children: const [AutoSaveTodayBanner()])),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('9 ảnh mới có thể có Teddy'), findsOneWidget);

    await tester.tap(find.text('Xem & chọn ảnh'));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/memories/auto-save/review');
    expect(find.text('Tải lên 8 mục'), findsNothing);
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

  testWidgets('AS10: "Chỉ ba mẹ" and "Gia đình" share the width equally', (
    tester,
  ) async {
    final c = candidate('a', Duration.zero, v([1, 0]), 0.5);
    await pumpRouted(
      tester,
      AutoSaveConfirmScreen(
        decision: AutoSaveDecision(chosen: [c], reviewed: [c]),
      ),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    Size card(String title) => tester.getSize(
      find
          .ancestor(of: find.text(title), matching: find.byType(Container))
          .first,
    );
    final parents = card('Chỉ ba mẹ');
    final family = card('Gia đình');
    expect(parents, family);
    // 375 pt wide, 16 pt margins, 8 pt between.
    expect(parents.width, closeTo((375 - 32 - 8) / 2, 0.5));
  });

  // Owner, 2026-10-26: "hết bộ nhớ lại cho chuẩn bị file … ko show premium … text hiển thị cũng
  // kỳ … muốn được xem mỗi file đó chuẩn bị gì và đang như thế nào".
  FamilyStorage room(int leftBytes) => FamilyStorage(
    familyId: 'f_1',
    isOwner: true,
    quotaBytes: 10 * 1024 * 1024 * 1024,
    usedBytes: 10 * 1024 * 1024 * 1024 - leftBytes,
    binBytes: 0,
    notesBytes: 0,
    babies: const [],
    largestVideos: const [],
  );
  Future<void> confirm(
    WidgetTester tester,
    List<Candidate> chosen, {
    Future<FamilyStorage> Function()? storage,
    List<Override> extra = const [],
  }) async {
    await pumpRouted(
      tester,
      AutoSaveConfirmScreen(
        decision: AutoSaveDecision(chosen: chosen, reviewed: chosen),
      ),
      overrides: [
        ...overrides(storage: storage),
        ...extra,
      ],
    );
  }

  testWidgets('AS10: nothing uploads while the space is still being checked', (
    tester,
  ) async {
    final c = candidate('a', Duration.zero, v([1, 0]), 0.5);
    await confirm(tester, [
      c,
    ], storage: () => Completer<FamilyStorage>().future);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đang kiểm tra dung lượng…'), findsOneWidget);
    expect(
      tester
          .widget<ClButton>(find.byKey(const Key('autoSaveUpload')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('AS18: with no space left, the only way on is "Thêm dung lượng"', (
    tester,
  ) async {
    final c = candidate('a', Duration.zero, v([1, 0]), 0.5);
    await confirm(tester, [c], storage: () async => room(0));
    await tester.pumpAndSettle();
    expect(find.text('Gia đình đã hết dung lượng'), findsOneWidget);
    expect(find.byKey(const Key('autoSaveAddSpace')), findsOneWidget);
    // D-125: named by plan; without Premium v2 it is the Dung lượng screen, not Premium.
    expect(find.text('Quản lý dung lượng'), findsOneWidget);
    expect(find.textContaining('Premium'), findsNothing);
    expect(find.byKey(const Key('autoSaveUpload')), findsNothing);
    expect(find.textContaining('tải trước 0'), findsNothing);
  });

  testWidgets(
    'AS18 (D-125): a Free family on Premium v2 sees Premium named before the tap',
    (tester) async {
      final c = candidate('a', Duration.zero, v([1, 0]), 0.5);
      await confirm(
        tester,
        [c],
        storage: () async => room(0),
        extra: [
          capabilitiesProvider.overrideWith(
            (ref, babyId) async => Capabilities.fromJson(v2Answer()),
          ),
          familyPlanV2Provider.overrideWith((ref, id) async => freePlan),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Thêm dung lượng với Premium'), findsOneWidget);
      expect(
        find.textContaining('Premium có thêm dung lượng cho cả nhà.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AS18 (D-127): a Premium member who does not manage the plan asks the manager',
    (tester) async {
      final c = candidate('a', Duration.zero, v([1, 0]), 0.5);
      await confirm(
        tester,
        [c],
        storage: () async => room(0),
        extra: [
          capabilitiesProvider.overrideWith(
            (ref, babyId) async => Capabilities.fromJson(v2Answer()),
          ),
          familyPlanV2Provider.overrideWith(
            (ref, id) async => asMember(premiumPlan),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nhờ '), findsOneWidget);
      expect(find.text('Mua thêm dung lượng'), findsNothing);
    },
  );

  testWidgets('AS18: room for some: upload those, or add space', (
    tester,
  ) async {
    final a = candidate('a', Duration.zero, v([1, 0]), 0.5);
    final b = candidate('b', const Duration(hours: 1), v([0, 1]), 0.5);
    await confirm(
      tester,
      [a, b],
      // One 4032 × 3024 photo is about 3.6 MB: room for one of the two.
      storage: () async => room(5 * 1024 * 1024),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chỉ đủ chỗ cho 1/2 mục'), findsOneWidget);
    expect(find.text('Tải trước 1 mục vừa đủ'), findsOneWidget);
    expect(find.byKey(const Key('autoSaveAddSpace')), findsOneWidget);
  });

  testWidgets('AS10: each file shows its state; unreadable ones stay listed', (
    tester,
  ) async {
    final a = candidate('a', Duration.zero, v([1, 0]), 0.5);
    await confirm(
      tester,
      [a],
      extra: [
        // The phone cannot open it.
        libraryResolverProvider.overrideWithValue((_) async => null),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải lên 1 mục'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('autoSavePrep:a')), findsOneWidget);
    expect(find.text('Không đọc được tệp'), findsOneWidget);
    expect(
      find.text('0 mục đã vào hàng tải · 1 không đọc được'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('autoSavePrepDone')), findsOneWidget);
  });

  testWidgets('AS03 → AS04 → AS05 are pages of their own (slide, swipe back)', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const AutoSaveSetupScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý ảnh của bé nào?'), findsWidgets);
    await tester.tap(find.text('Tiếp'));
    await tester.pump();
    // Mid-transition both pages are on screen: a real route, not a swapped body.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Gợi ý ảnh của bé nào?'), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('Chọn vài ảnh rõ mặt Teddy'), findsWidgets);
    await tester.tap(find.byType(ClBackButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý ảnh của bé nào?'), findsWidgets);
    expect(find.text('Chọn vài ảnh rõ mặt Teddy'), findsNothing);
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
