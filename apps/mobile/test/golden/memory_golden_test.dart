@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/media_viewer.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_sheets.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';

/// S9 Kỷ niệm in Light / Night care × vi / en at 375 × 812 on the 10a mock (Thursday 8 Oct,
/// 15:05; Teddy born 17 Sep).
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

class _View extends MemoryViewState {
  _View(this.initial);
  final MemoryView initial;
  @override
  MemoryView build() => initial;
}

class _Selection extends MemorySelection {
  _Selection(this.initial);
  final Set<String> initial;
  @override
  Set<String>? build() => initial;
}

final _journal = mockJournal();

List<Override> _base({
  Membership? me,
  MemoryView view = const MemoryView(tab: MemoryTab.journal),
  Set<String>? selected,
  MemoryQueueStore? store,
  List<FamilyMilestone> milestones = const [],
  FakeMemoryRepository? repo,
  NetworkKind network = NetworkKind.wifi,
}) => [
  ...careOverrides(me: me),
  ...memoryOverrides(
    journal: _journal,
    store: store,
    milestones: milestones,
    repo: repo,
    network: network,
  ),
  memoryViewProvider.overrideWith(() => _View(view)),
  if (selected != null)
    memorySelectionProvider.overrideWith(() => _Selection(selected)),
];

Widget _tab() => const Scaffold(body: MemoriesScreen());

/// The tab with the shell's floating upload pill where it sits above the dock (D-048).
Widget _tabWithPill() => const Scaffold(
  body: Stack(
    children: [
      Positioned.fill(child: MemoriesScreen()),
      Positioned(
        left: 16,
        right: 16,
        bottom: 12 + 68 + 24,
        child: GlobalUploadPill(),
      ),
    ],
  ),
);

/// Opens a sheet from a host that has the screen's context.
class _Host extends ConsumerStatefulWidget {
  const _Host(this.open);
  final Future<void> Function(BuildContext, WidgetRef, MemoryCtx) open;
  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = memoryCtx(context, ref);
      if (c != null) widget.open(context, ref, c);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: MemoriesScreen());
}

/// Media bytes decode outside the fake clock: let every visible image finish first.
Future<void> _precacheImages(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    await tester.runAsync(() async {
      for (final image in images) {
        final element = tester.element(find.byWidget(image).first);
        await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
  }
}

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(Scaffold).first));

QueueBatch _uploadingBatch() => QueueBatch(
  batchId: 'bat_${'a' * 32}',
  babyId: teddyId,
  memoryId: 'mem_${'a' * 32}',
  request: const {'audience': 'family', 'notifyFamily': true},
  createdAt: DateTime(2026, 10, 8),
  sessionCreated: true,
  items: [
    for (final (n, s, sent, video) in [
      ('IMG_2039.HEIC', QueueState.uploaded, 3400000, false),
      ('IMG_2040.HEIC', QueueState.uploaded, 3100000, false),
      ('IMG_2042.HEIC', QueueState.uploaded, 2900000, false),
      ('IMG_2045.HEIC', QueueState.uploaded, 2800000, false),
      ('IMG_2041.HEIC', QueueState.uploading, 2100000, false),
      ('IMG_2043.MOV', QueueState.waitingWifi, 0, true),
      ('IMG_2044.HEIC', QueueState.failed, 0, false),
      ('IMG_2050.HEIC', QueueState.unreadable, 0, false),
    ])
      QueueItem(
        mediaId: 'med_${n.hashCode.toRadixString(16).padLeft(32, '0')}',
        type: video ? MediaKind.video : MediaKind.photo,
        name: n,
        localPath: '/nope/$n',
        contentType: video ? 'video/quicktime' : 'image/jpeg',
        bytes: video ? 48000000 : 3400000,
        captureAt: DateTime(2026, 10, 8),
        state: s,
        sent: s == QueueState.uploaded ? (video ? 48000000 : 3400000) : sent,
      ),
  ],
);

QueueItem _item(String n, QueueState s, {bool video = false}) => QueueItem(
  mediaId: 'med_${n.hashCode.toRadixString(16).padLeft(32, '0')}',
  type: video ? MediaKind.video : MediaKind.photo,
  name: n,
  localPath: '/nope/$n',
  contentType: video ? 'video/quicktime' : 'image/jpeg',
  bytes: video ? 48000000 : 3400000,
  captureAt: DateTime(2026, 10, 8),
  state: s,
);

/// A batch whose upload session the server refused: `uploads-paused` (A11) or a refusal.
QueueBatch _blockedBatch(String id, String blocked, QueueState state) =>
    QueueBatch(
      batchId: 'bat_${id * 32}',
      babyId: teddyId,
      memoryId: 'mem_${id * 32}',
      request: {
        'audience': 'family',
        'notifyFamily': true,
        'batchId': 'bat_${id * 32}',
      },
      createdAt: DateTime(2026, 10, 8),
      blocked: blocked,
      items: [
        _item('IMG_3${id}01.HEIC', state),
        _item('IMG_3${id}02.MOV', state, video: true),
      ],
    );

QueueBatch _plainBatch(String id, List<QueueItem> items) => QueueBatch(
  batchId: 'bat_${id * 32}',
  babyId: teddyId,
  memoryId: 'mem_${id * 32}',
  request: const {'audience': 'family', 'notifyFamily': true},
  createdAt: DateTime(2026, 10, 8),
  sessionCreated: true,
  items: items,
);

/// The server keeps refusing the blocked batches, so their state holds while the screen settles.
FakeMemoryRepository _refusing() => FakeMemoryRepository()
  ..refuseBatches = {
    'bat_${'b' * 32}': FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'uploads-paused',
      details: {'reason': 'uploads-paused'},
    ),
    'bat_${'c' * 32}': FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'not-allowed',
      details: {'reason': 'not-allowed'},
    ),
  };

final _cases = <String, _Case>{
  '10i_queue_states': (
    build: () => _Host((c, r, m) => showQueueSheet(c, r, m)),
    overrides: () => _base(
      repo: _refusing(),
      store: MemoryQueueStore()
        ..saved = [
          _blockedBatch('b', 'uploads-paused', QueueState.pendingSession),
          _blockedBatch('c', 'not-allowed', QueueState.failed),
          _plainBatch('d', [
            _item('IMG_3d01.HEIC', QueueState.paused),
            _item('IMG_3d02.HEIC', QueueState.waitingQuota),
          ]),
        ],
    ),
    prefs: const {},
    act: null,
  ),
  '10a_pill_uploads_paused': (
    build: _tabWithPill,
    overrides: () => _base(
      repo: _refusing(),
      store: MemoryQueueStore()
        ..saved = [
          _blockedBatch('b', 'uploads-paused', QueueState.pendingSession),
        ],
    ),
    prefs: const {},
    act: null,
  ),
  '10a_pill_failed': (
    build: _tabWithPill,
    overrides: () => _base(
      repo: _refusing(),
      store: MemoryQueueStore()
        ..saved = [_blockedBatch('c', 'not-allowed', QueueState.failed)],
    ),
    prefs: const {},
    act: null,
  ),
  '10a_pill_offline': (
    build: _tabWithPill,
    overrides: () => _base(
      network: NetworkKind.none,
      store: MemoryQueueStore()
        ..saved = [
          _plainBatch('d', [
            _item('IMG_3d01.HEIC', QueueState.paused),
            _item('IMG_3d02.HEIC', QueueState.paused),
          ]),
        ],
    ),
    prefs: const {},
    act: null,
  ),
  '10a_journal': (build: _tab, overrides: _base, prefs: const {}, act: null),
  '10a_uploading': (
    build: _tabWithPill,
    overrides: () =>
        _base(store: MemoryQueueStore()..saved = [_uploadingBatch()]),
    prefs: const {},
    act: null,
  ),
  '7b_journal_relative': (
    build: _tab,
    overrides: () => _base(me: hoa),
    prefs: const {},
    act: null,
  ),
  '10b_photos': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.photos)),
    prefs: const {},
    act: null,
  ),
  '10b2_select': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(tab: MemoryTab.photos),
      selected: {for (final i in _journal.media.take(5)) i.id},
    ),
    prefs: const {},
    act: null,
  ),
  '10b3_actions': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(tab: MemoryTab.photos),
      selected: {for (final i in _journal.media.take(5)) i.id},
    ),
    prefs: const {},
    act: (t) async => t.tap(find.bySemanticsLabel(_l10n(t).a11yShareOptions)),
  ),
  '10b4_delete': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(tab: MemoryTab.photos),
      selected: {for (final i in _journal.media.take(5)) i.id},
    ),
    prefs: const {},
    act: (t) async => t.tap(find.bySemanticsLabel(_l10n(t).a11yDeleteSelected)),
  ),
  '10b5_goto_month': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(
        tab: MemoryTab.photos,
        photoGroup: PhotoGroup.month,
      ),
    ),
    prefs: const {},
    act: (t) async => t.tap(find.byKey(const Key('photoScrubber'))),
  ),
  // v1.0 "Nhật ký gọn hơn" (382:2793): the three sheets of 10b.
  'v1i_10b_group_sheet': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.photos)),
    prefs: const {},
    act: (t) async => t.tap(find.text(_l10n(t).photoPillWeek)),
  ),
  'v1i_10b_show_sheet': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.photos)),
    prefs: const {},
    act: (t) async => t.tap(find.text(_l10n(t).photoShowAll)),
  ),
  'v1i_10b_goto_week': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.photos)),
    prefs: const {},
    act: (t) async => t.tap(find.byKey(const Key('photoScrubber'))),
  ),
  'v1i_10b_by_age_month': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(
        tab: MemoryTab.photos,
        photoGroup: PhotoGroup.ageMonth,
      ),
    ),
    prefs: const {},
    act: null,
  ),
  '10c_view_options': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.photos)),
    prefs: const {},
    act: (t) async => t.tap(find.bySemanticsLabel(_l10n(t).a11yViewOptions)),
  ),
  '10a2_add': (
    build: _tab,
    overrides: _base,
    prefs: const {},
    act: (t) async => t.tap(find.bySemanticsLabel(_l10n(t).a11yAddMemory)),
  ),
  '10h_compose': (
    build: () => _Host(
      (c, r, m) => showComposeSheet(c, r, m, [
        for (var i = 0; i < 7; i++)
          i == 3 ? pickedVideo('IMG_20$i.MOV') : pickedPhoto('IMG_20$i.HEIC'),
      ]),
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10h_note': (
    build: () => _Host((c, r, m) => showComposeSheet(c, r, m, const [])),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10h2_date': (
    build: () =>
        _Host((c, r, m) => showComposeSheet(c, r, m, [pickedPhoto('a.HEIC')])),
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await t.pumpAndSettle();
      await t.tap(find.text(_l10n(t).composeDate));
    },
  ),
  '10h3_milestone': (
    build: () =>
        _Host((c, r, m) => showComposeSheet(c, r, m, [pickedPhoto('a.HEIC')])),
    overrides: () => _base(
      milestones: [
        FamilyMilestone(
          id: 'ms_${'1' * 32}',
          name: 'Ngày đầu về nhà',
          date: DateTime(2026, 9, 20),
        ),
        FamilyMilestone(
          id: 'ms_${'2' * 32}',
          name: 'Lần đầu nắm tay ba',
          date: DateTime(2026, 10, 1),
        ),
      ],
    ),
    prefs: const {},
    act: (t) async {
      await t.pumpAndSettle();
      await t.tap(find.text(_l10n(t).composeMilestone));
    },
  ),
  '10h4_create_milestone': (
    build: () => _Host(
      (c, r, m) =>
          showCreateMilestoneSheet(c, ctx: m, name: 'Lần đầu lật người'),
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10i_queue': (
    build: () => _Host((c, r, m) => showQueueSheet(c, r, m)),
    overrides: () =>
        _base(store: MemoryQueueStore()..saved = [_uploadingBatch()]),
    prefs: const {},
    act: null,
  ),
  '10f_viewer': (
    build: () => MediaViewer(
      items: [
        for (final i in _journal.media)
          if (i.memoryId == _journal.memories[4].id) i,
      ],
      start: 0,
      memory: _journal.memories[4],
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10o_share_private': (
    build: () => _Host(
      (c, r, m) => showSharePrivateSheet(c, r, m, [
        for (final i in _journal.media.take(3))
          MediaItem(
            id: i.id,
            babyId: i.babyId,
            memoryId: i.memoryId,
            type: MediaKind.photo,
            status: MediaStatus.ready,
            audience: Audience.parents,
            effectiveAudience: Audience.parents,
            captureAt: i.captureAt,
            createdBy: i.createdBy,
            paths: i.paths,
          ),
      ]),
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          mediaBytes = FakeMediaBytes();
          SharedPreferences.setMockInitialValues(c.prefs);
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: buildClTheme(palette),
                    locale: locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    routerConfig: router,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester);
          await tester.pumpAndSettle();
          await _precacheImages(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/s9/${name}_${palette.name}_${locale.languageCode}.png',
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
