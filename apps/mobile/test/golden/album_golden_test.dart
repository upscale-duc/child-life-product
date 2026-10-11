@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/album_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/album_screens.dart';
import 'package:child_life/features/memories/media_viewer.dart';
import 'package:child_life/features/memories/memory_widgets.dart';
import 'package:child_life/features/memories/messages_screen.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
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

/// S10 albums, favourites, loves, relatives' view and messages in Light / Night care × vi / en
/// at 375 × 812 on the 10a mock (Thursday 8 Oct, 15:05).
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
  bool empty = false,
  List<Album> extraAlbums = const [],
  Set<String>? favorites,
}) => [
  ...careOverrides(me: me),
  ...memoryOverrides(
    journal: empty
        ? (memories: const <Memory>[], media: const <MediaItem>[])
        : _journal,
    store: store,
    milestones: milestones,
    extraAlbums: extraAlbums,
    favorites: favorites,
    loves: mockLoves(_journal),
    messages: mockMessages(_journal),
  ),
  memoryViewProvider.overrideWith(() => _View(view)),
  if (selected != null)
    memorySelectionProvider.overrideWith(() => _Selection(selected)),
];

Widget _tab() => const Scaffold(body: MemoriesScreen());

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

final _albums = mockAlbums(_journal.media);
final _bath = _albums.albums.first;
final _bathItems = [
  for (final m in _journal.media)
    if (_albums.items[_bath.id]!.containsKey(m.id)) m,
];

Future<void> _openOptions(WidgetTester t) async {
  await t.tap(find.bySemanticsLabel(_l10n(t).albOptions));
  await t.pumpAndSettle();
}

final _cases = <String, _Case>{
  '10a_journal_loves': (
    build: _tab,
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10d_albums': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.albums)),
    prefs: const {},
    act: null,
  ),
  // An empty album and an empty Yêu thích: mint cover, "Thêm ảnh" on the album only.
  '10d_albums_empty': (
    build: _tab,
    overrides: () => _base(
      view: const MemoryView(tab: MemoryTab.albums),
      favorites: const {},
      extraAlbums: [
        Album(
          id: 'alb_${'e' * 32}',
          name: 'Ngày đầu đi dạo',
          audience: Audience.parents,
          photos: 0,
          videos: 0,
          loveCount: 0,
          createdBy: 'u_mai',
          author: CareAuthor.of(mai),
          updatedAt: DateTime.utc(2026, 10, 8, 12),
        ),
      ],
    ),
    prefs: const {},
    act: null,
  ),
  '11e_albums_relative': (
    build: _tab,
    overrides: () => _base(
      me: hoa,
      view: const MemoryView(tab: MemoryTab.albums),
    ),
    prefs: const {},
    act: null,
  ),
  '10e_album_detail': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10e2_favorites': (
    build: () => const AlbumDetailScreen(albumKey: favoritesKey),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '11f_album_relative': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: () => _base(me: hoa),
    prefs: const {},
    act: null,
  ),
  '10e3_album_options': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: _openOptions,
  ),
  '10e5_cover': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await _openOptions(t);
      await t.tap(find.text(_l10n(t).albCover));
    },
  ),
  '10e7_sort': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await _openOptions(t);
      await t.tap(find.text(_l10n(t).albSort));
    },
  ),
  '10e8_select': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await _openOptions(t);
      await t.tap(find.text(_l10n(t).albSelect));
      await t.pumpAndSettle();
      await t.tap(find.byType(MediaTile).first);
      await t.tap(find.byType(MediaTile).at(2));
    },
  ),
  '10e10_delete_album': (
    build: () => AlbumDetailScreen(albumKey: _bath.id),
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await _openOptions(t);
      await t.tap(find.text(_l10n(t).albDelete));
    },
  ),
  '10e4_rename': (
    build: () => _Host((c, r, m) => showAlbumNameSheet(c, r, m, album: _bath)),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  'album_new': (
    build: () => _Host((c, r, m) => showNewAlbumSheet(c, r, m)),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10e6_album_audience': (
    build: () => _Host(
      (c, r, m) => showAlbumAudienceSheet(c, r, m, _bath, _bathItems.length),
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10e9_download_album': (
    build: () => _Host(
      (c, r, m) => showDownloadAlbumSheet(c, r, _bath.name, _bathItems),
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '10h5_album_picker': (
    build: () =>
        _Host((c, r, m) => showAlbumPicker(c, r, m, selected: [_bath.id])),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '11c_journal_relative': (
    build: _tab,
    overrides: () => _base(me: hoa),
    prefs: const {},
    act: null,
  ),
  '11g_viewer_relative': (
    build: () => MediaViewer(
      items: [
        for (final i in _journal.media)
          if (i.memoryId == _journal.memories[4].id && !i.isPrivate) i,
      ],
      start: 0,
      memory: _journal.memories[4],
    ),
    overrides: () => _base(me: hoa),
    prefs: const {},
    act: null,
  ),
  '10f_viewer_thread': (
    build: () => MediaViewer(
      items: [
        for (final i in _journal.media)
          if (i.memoryId == _journal.memories.first.id) i,
      ],
      start: 0,
      memory: _journal.memories.first,
    ),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '11h_relative_empty': (
    build: _tab,
    overrides: () => _base(me: hoa, empty: true),
    prefs: const {},
    act: null,
  ),
  'messages_list': (
    build: () => const MessagesScreen(),
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
                'goldens/s10/${name}_${palette.name}_${locale.languageCode}.png',
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
