import 'dart:io';
import 'dart:typed_data';

import 'package:child_life/app/session.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/auto_save/auto_save_controller.dart';
import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:child_life/features/auto_save/auto_save_native.dart';
import 'package:child_life/features/auto_save/auto_save_store.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// Tự lưu kỷ niệm (D-066): the on-device store (P-147, P-150) and the controller that checks
/// the library, keeps suggestions and queues what the parent approves. The PhotoKit side is a
/// fake channel; face prints are tiny vectors whose direction stands for a person.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('childlife/autosave');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final t0 = DateTime(2026, 10, 12, 9);
  Float32List v(List<double> xs) => Float32List.fromList(xs);
  final teddyFace = v([1, 0, 0]);
  final strangerFace = v([0, 0, 1]);

  late Directory dir;
  late List<String> library;
  late Map<String, Map<String, Object?>> described;
  late List<MethodCall> calls;
  late String access;

  Map<String, Object?> photo(
    String id, {
    Duration at = Duration.zero,
    Float32List? face,
    Float32List? print,
  }) => {
    'id': id,
    'captureAt': t0.add(at).millisecondsSinceEpoch,
    'width': 4032,
    'height': 3024,
    'print': print ?? v([1, 0]),
    'faces': [
      if (face != null) {'size': 0.3, 'quality': 0.8, 'print': face},
    ],
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('autosave');
    calls = [];
    access = 'full';
    library = [];
    described = {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
      switch (call.method) {
        case 'access':
        case 'requestAccess':
          return access;
        case 'changes':
          return {
            'ids': library,
            'token': Uint8List.fromList([7]),
            'fromHistory': args['token'] != null,
          };
        case 'analyze':
          return [
            for (final id in args['ids']! as List)
              described[id] ?? {'id': id, 'missing': true},
          ];
        case 'analyzeFile':
          return {...photo('file', face: teddyFace), 'id': args['path']};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({'app.locale': 'vi'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        ...memoryOverrides(),
        sharedPreferencesProvider.overrideWithValue(prefs),
        sessionProvider.overrideWithValue(
          SessionSignedIn(
            user: FakeUser(uid: mai.uid),
            memberships: [mai],
          ),
        ),
        babyProvider.overrideWith((ref, id) => Stream.value(teddy)),
        autoSaveNativeProvider.overrideWithValue(
          AutoSaveNative(supported: true),
        ),
        autoSaveStoreProvider.overrideWithValue(
          AutoSaveStore(dir: () async => Directory('${dir.path}/state')),
        ),
        libraryResolverProvider.overrideWithValue(
          (id) async => PickedMedia(
            file: File('${dir.path}/$id.jpg'),
            type: MediaKind.photo,
            name: '$id.jpg',
            captureAt: t0,
            assetId: id,
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<AutoSaveController> setUpTeddy(ProviderContainer c) async {
    // The setup screen has the baby loaded; so does this.
    c.listen(babyProvider(teddyId), (_, _) {});
    await pumpEventQueue();
    final ctl = c.read(autoSaveProvider.notifier);
    await ctl.ready();
    await ctl.setUp(
      samples: {
        teddyId: [
          SampleFace(ref: 'm:1', print: teddyFace),
          SampleFace(ref: 'm:2', print: v([0.98, 0.2, 0])),
          SampleFace(ref: 'm:3', print: v([0.97, 0, 0.2])),
        ],
      },
      scanFrom: t0.subtract(const Duration(days: 30)),
    );
    await ctl.scan();
    return ctl;
  }

  group('AutoSaveStore', () {
    test('round-trips settings, samples, ledger and suggestions', () async {
      final store = AutoSaveStore(dir: () async => dir);
      final asset = AssetInfo.fromMap(photo('a', face: teddyFace))!;
      await store.save(
        AutoSaveState(
          enabled: true,
          consentVersion: autoSaveConsentVersion,
          consentAt: t0,
          babies: {
            teddyId: AutoSaveBaby(
              samples: [SampleFace(ref: 'm:1', print: teddyFace)],
              negatives: [strangerFace],
            ),
          },
          token: Uint8List.fromList([1, 2]),
          ledger: {
            'x': {teddyId: LedgerState.uploaded},
            'y': {'*': LedgerState.fromApp},
          },
          pending: [
            Candidate(
              asset: asset,
              match: FaceMatch(babyId: teddyId, distance: 0.01, face: 0),
            ),
          ],
          savedByMonth: const {'2026-10': 4},
        ),
      );
      final back = await store.load();
      expect(back.consented, isTrue);
      expect(back.babies[teddyId]!.samples.single.print, teddyFace);
      expect(back.babies[teddyId]!.negatives.single, strangerFace);
      expect(back.token, [1, 2]);
      expect(back.handled('x', teddyId), isTrue);
      expect(
        back.handled('y', 'anyone'),
        isTrue,
        reason: 'downloads count for every baby',
      );
      final p = back.pending.single;
      expect(p.asset.id, 'a');
      expect(
        p.asset.faces.single.print,
        teddyFace,
        reason: 'approving it makes it a sample',
      );
      expect(back.savedByMonth['2026-10'], 4);
    });

    test('wiping keeps only what prevents suggesting things twice', () {
      final s = AutoSaveState(
        enabled: true,
        consentVersion: autoSaveConsentVersion,
        babies: {
          teddyId: AutoSaveBaby(
            samples: [SampleFace(ref: 'm:1', print: teddyFace)],
          ),
        },
        ledger: {
          'up': {teddyId: LedgerState.uploaded},
          'skip': {teddyId: LedgerState.skipped},
          'app': {'*': LedgerState.fromApp},
        },
      ).wipeFaces();
      expect(s.consented, isFalse);
      expect(s.enabled, isFalse);
      expect(s.babies, isEmpty);
      expect(s.ledger.keys, unorderedEquals(['up', 'app']));
    });

    test('a damaged file starts over instead of failing', () async {
      Directory('${dir.path}/s').createSync();
      File('${dir.path}/s/state.json').writeAsStringSync('{nope');
      final s = await AutoSaveStore(
        dir: () async => Directory('${dir.path}/s'),
      ).load();
      expect(s.enabled, isFalse);
    });
  });

  group('AutoSaveController', () {
    test(
      'the first check looks back by date, suggests the baby and remembers the place',
      () async {
        library = ['a', 'b', 'c', 'gone'];
        described = {
          'a': photo('a', face: teddyFace),
          'b': photo('b', at: const Duration(minutes: 10), face: strangerFace),
          'c': photo('c', at: const Duration(minutes: 20)),
        };
        final c = await container();
        await setUpTeddy(c);
        final view = c.read(autoSaveProvider);
        expect(view.active, isTrue);
        expect([for (final p in view.state.pending) p.asset.id], ['a']);
        expect(view.state.token, [7]);
        expect(view.state.lastScanCount, 4);
        expect(view.state.scanFrom, isNull);
        final first = calls.firstWhere((m) => m.method == 'changes');
        expect(
          (first.arguments as Map)['token'],
          isNull,
          reason: 'setup looks back by date',
        );

        // The next check follows the change history and skips what it already saw.
        calls.clear();
        await c.read(autoSaveProvider.notifier).scan();
        final next = calls.firstWhere((m) => m.method == 'changes');
        expect((next.arguments as Map)['token'], [7]);
        expect(calls.where((m) => m.method == 'analyze'), isEmpty);
      },
    );

    test(
      'no check without consent, without samples or without photo access',
      () async {
        library = ['a'];
        described = {'a': photo('a', face: teddyFace)};
        final c = await container();
        final ctl = c.read(autoSaveProvider.notifier);
        await ctl.ready();
        await ctl.scan();
        expect(calls.where((m) => m.method == 'changes'), isEmpty);

        access = 'denied';
        await setUpTeddy(c);
        expect(calls.where((m) => m.method == 'changes'), isEmpty);
        expect(c.read(autoSaveProvider).access, LibraryAccess.denied);
      },
    );

    test(
      'approving queues one memory, parents only, and marks the rest of the review',
      () async {
        library = ['a', 'b'];
        described = {
          'a': photo('a', face: teddyFace),
          'b': photo(
            'b',
            at: const Duration(seconds: 5),
            face: teddyFace,
            print: v([1, 0.01]),
          ),
        };
        final c = await container();
        final ctl = await setUpTeddy(c);
        final pending = c.read(autoSaveProvider).state.pending;
        expect(pending, hasLength(2));
        final groups = c.read(autoSaveProvider).groups();
        expect(groups, hasLength(1), reason: 'near-copies form one group');

        final n = await ctl.approve(
          chosen: [pending.first],
          reviewed: pending,
          audience: Audience.parents,
          notifyFamily: true,
        );
        expect(n, 1);
        final batch = c.read(uploadQueueProvider).batches.single;
        expect(batch.request['audience'], 'parents');
        expect(
          batch.request['notifyFamily'],
          false,
          reason: 'only a family audience is told',
        );
        expect(batch.request['dateMode'], 'capture');
        final s = c.read(autoSaveProvider).state;
        expect(s.pending, isEmpty);
        expect(
          s.ledger[pending.first.asset.id]?[teddyId],
          LedgerState.uploaded,
        );
        expect(s.ledger[pending.last.asset.id]?[teddyId], LedgerState.skipped);
        expect(
          s.babies[teddyId]!.samples.where((x) => x.approved),
          hasLength(1),
        );
        expect(s.savedByMonth.values.single, 1);
      },
    );

    test(
      '"Bỏ qua lần này" and "Không phải ảnh của bé" can be undone',
      () async {
        library = ['a', 'b'];
        described = {
          'a': photo('a', face: teddyFace),
          'b': photo('b', at: const Duration(minutes: 10), face: teddyFace),
        };
        final c = await container();
        final ctl = await setUpTeddy(c);
        final pending = c.read(autoSaveProvider).state.pending;

        final undoSkip = await ctl.skip(pending);
        expect(c.read(autoSaveProvider).state.pending, isEmpty);
        await ctl.undo(undoSkip);
        expect(c.read(autoSaveProvider).state.pending, hasLength(2));

        await ctl.reject(pending.first);
        final s = c.read(autoSaveProvider).state;
        expect(s.pending, hasLength(1));
        expect(
          s.ledger[pending.first.asset.id]?[teddyId],
          LedgerState.rejected,
        );
        expect(s.babies[teddyId]!.negatives, hasLength(1));
      },
    );

    test(
      'items queued by hand or saved from Child Life are never suggested',
      () async {
        library = ['a', 'b'];
        described = {
          'a': photo('a', face: teddyFace),
          'b': photo('b', at: const Duration(minutes: 10), face: teddyFace),
        };
        final c = await container();
        final ctl = await setUpTeddy(c);
        await c
            .read(uploadQueueProvider.notifier)
            .enqueue(
              babyId: teddyId,
              request: {
                'babyId': teddyId,
                'memoryId': 'mem_1',
                'batchId': 'bat_1',
                'audience': 'family',
              },
              picked: [
                PickedMedia(
                  file: File('${dir.path}/a.jpg'),
                  type: MediaKind.photo,
                  name: 'a.jpg',
                  captureAt: t0,
                  assetId: 'a',
                ),
              ],
            );
        await ctl.recordFromApp('b');
        final s = c.read(autoSaveProvider).state;
        expect(s.pending, isEmpty);
        expect(s.handled('a', teddyId), isTrue);
        expect(s.handled('b'), isTrue);
      },
    );

    test(
      'turning off keeps the data 30 days; wiping clears it at once',
      () async {
        library = ['a'];
        described = {'a': photo('a', face: teddyFace)};
        final c = await container();
        final ctl = await setUpTeddy(c);
        await ctl.setEnabled(false);
        var s = c.read(autoSaveProvider).state;
        expect(s.enabled, isFalse);
        expect(s.offAt, isNotNull);
        expect(s.babies, isNotEmpty);
        await ctl.wipe();
        s = c.read(autoSaveProvider).state;
        expect(s.babies, isEmpty);
        expect(s.consented, isFalse);
        expect(s.pending, isEmpty);
      },
    );
  });

  group('AR03 notification', () {
    final l10n = AppLocalizationsVi();
    Candidate fresh(String id) => Candidate(
      asset: AssetInfo(id: id, captureAt: t0),
      match: const FaceMatch(babyId: teddyId, distance: 0.1, face: 0),
    );
    const on = AutoSaveState(
      enabled: true,
      consentVersion: autoSaveConsentVersion,
      names: {teddyId: 'Teddy'},
    );

    test('names the baby and counts the new photos', () {
      final note = autoSaveNote(
        state: on,
        fresh: [fresh('a'), fresh('b')],
        now: DateTime(2026, 10, 18, 9, 41),
        l10n: l10n,
      )!;
      expect(note.title, 'Có 2 ảnh mới có thể có Teddy');
      expect(note.body, 'Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.');
      expect(note.at, DateTime(2026, 10, 18, 9, 41));
    });

    test('nothing new, switched off in AS19, or already told today: none', () {
      final now = DateTime(2026, 10, 18, 15);
      expect(autoSaveNote(state: on, fresh: [], now: now, l10n: l10n), isNull);
      expect(
        autoSaveNote(
          state: on.copyWith(notify: false),
          fresh: [fresh('a')],
          now: now,
          l10n: l10n,
        ),
        isNull,
      );
      expect(
        autoSaveNote(
          state: on.copyWith(notifiedAt: DateTime(2026, 10, 18, 7)),
          fresh: [fresh('a')],
          now: now,
          l10n: l10n,
        ),
        isNull,
      );
    });

    test('found in quiet hours (22:00 – 06:00): told at 07:00', () {
      final late = autoSaveNote(
        state: on,
        fresh: [fresh('a')],
        now: DateTime(2026, 10, 18, 23, 30),
        l10n: l10n,
      )!;
      expect(late.at, DateTime(2026, 10, 19, 7));
      final early = autoSaveNote(
        state: on,
        fresh: [fresh('a')],
        now: DateTime(2026, 10, 19, 3),
        l10n: l10n,
      )!;
      expect(early.at, DateTime(2026, 10, 19, 7));
      // Already told for the 19th: the night find waits.
      expect(
        autoSaveNote(
          state: on.copyWith(notifiedAt: DateTime(2026, 10, 19, 7)),
          fresh: [fresh('a')],
          now: DateTime(2026, 10, 19, 3),
          l10n: l10n,
        ),
        isNull,
      );
    });

    test(
      'a background check answers once, then stays quiet that day',
      () async {
        library = ['a'];
        described = {'a': photo('a', face: teddyFace)};
        final c = await container();
        final ctl = await setUpTeddy(c);
        library = ['a', 'b'];
        described['b'] = photo(
          'b',
          at: const Duration(minutes: 30),
          face: teddyFace,
        );
        final reply = await ctl.backgroundCheck();
        expect(reply?['title'], 'Có 1 ảnh mới có thể có Teddy');
        expect(c.read(autoSaveProvider).state.notifiedAt, isNotNull);
        expect(calls.where((m) => m.method == 'schedule'), isNotEmpty);

        library = ['a', 'b', 'c'];
        described['c'] = photo(
          'c',
          at: const Duration(hours: 2),
          face: teddyFace,
        );
        expect(await ctl.backgroundCheck(), isNull, reason: 'one a day');
        expect(c.read(autoSaveProvider).state.pending, hasLength(3));
      },
    );

    test('"Để sau" hides the banner until something new arrives', () async {
      library = ['a'];
      described = {'a': photo('a', face: teddyFace)};
      final c = await container();
      final ctl = await setUpTeddy(c);
      await ctl.hideBanner();
      expect(c.read(autoSaveProvider).state.bannerHidden, {'a'});
    });
  });
}
