@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/stories/share_repository.dart';
import 'package:child_life/features/stories/share_screens.dart';
import 'package:child_life/features/stories/story_editor.dart';
import 'package:child_life/features/stories/story_reader.dart';
import 'package:child_life/features/stories/story_widgets.dart';
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
import '../helpers/story_fixtures.dart';

/// S12 stories (14a–14g, 11i) in Light / Night care × vi / en at 375 × 812 on the 10a mock.
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
final _stories = mockStories(_journal);

List<Override> _base({
  Membership? me,
  MemoryView view = const MemoryView(tab: MemoryTab.journal),
  Set<String>? selected,
  MemoryQueueStore? store,
  List<FamilyMilestone> milestones = const [],
  bool empty = false,
}) => [
  ...careOverrides(me: me),
  ...memoryOverrides(
    journal: empty
        ? (memories: const <Memory>[], media: const <MediaItem>[])
        : _journal,
    store: store,
    milestones: milestones,
    loves: mockLoves(_journal),
    messages: mockMessages(_journal),
  ),
  ...storyOverrides(stories: _stories),
  ...shareOverrides(rows: mockSharedOut(_stories)),
  memoryViewProvider.overrideWith(() => _View(view)),
  if (selected != null)
    memorySelectionProvider.overrideWith(() => _Selection(selected)),
];

Widget _tab() => const Scaffold(body: MemoriesScreen());

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

Future<void> _tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text).last);
  await t.pumpAndSettle();
}

Widget _editor() => StoryEditorScreen(storyId: sid(1));

final _cases = <String, _Case>{
  '14a_stories': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.stories)),
    prefs: const {},
    act: null,
  ),
  '14a_stories_relative': (
    build: _tab,
    overrides: () => _base(
      me: hoa,
      view: const MemoryView(tab: MemoryTab.stories),
    ),
    prefs: const {},
    act: null,
  ),
  'new_story': (
    build: _tab,
    overrides: () => _base(view: const MemoryView(tab: MemoryTab.stories)),
    prefs: const {},
    act: (t) => _tapText(t, _l10n(t).sryWrite),
  ),
  '14b_editor': (build: _editor, overrides: _base, prefs: const {}, act: null),
  '14b_selected': (
    build: _editor,
    overrides: _base,
    prefs: const {},
    act: (t) => _tapText(t, _stories.first.firstText),
  ),
  '14c_paragraph': (
    build: _editor,
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await _tapText(t, _stories.first.firstText);
      await _tapText(t, _l10n(t).sryWarmer);
    },
  ),
  '14d_photos': (
    build: _editor,
    overrides: _base,
    prefs: const {},
    act: (t) async {
      await t.tap(find.byType(StoryImage).at(1));
      await t.pumpAndSettle();
    },
  ),
  '14e_arrange': (
    build: _editor,
    overrides: _base,
    prefs: const {},
    act: (t) => _tapText(t, _l10n(t).sryArrange),
  ),
  '14f_preview': (
    build: _editor,
    overrides: _base,
    prefs: const {},
    act: (t) => _tapText(t, _l10n(t).sryPreviewSave),
  ),
  '14g_reader': (
    build: () => StoryReaderScreen(storyId: sid(2)),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '11i_reader_relative': (
    build: () => StoryReaderScreen(storyId: sid(2)),
    overrides: () => _base(me: hoa),
    prefs: const {},
    act: null,
  ),
  '14h_share': (
    build: () => StoryReaderScreen(storyId: sid(2)),
    overrides: _base,
    prefs: const {},
    act: (t) => _tapText(t, _l10n(t).sryShare),
  ),
  for (final tpl in CardTemplate.values)
    '14i_card_${tpl.name}': (
      build: () => CardScreen(story: _stories[1]),
      overrides: _base,
      prefs: const {},
      act: tpl == CardTemplate.moment
          ? null
          : (t) async {
              await t.tap(find.text(_cardLabel(_l10n(t), tpl)).last);
              await t.pumpAndSettle();
            },
    ),
  '14k_link': (
    build: () => LinkScreen(story: _stories[1]),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
  '14m_shared_out': (
    build: () => const SharedOutScreen(),
    overrides: _base,
    prefs: const {},
    act: null,
  ),
};

String _cardLabel(AppLocalizations l10n, CardTemplate t) => switch (t) {
  CardTemplate.moment => l10n.cdMoment,
  CardTemplate.three => l10n.cdThree,
  CardTemplate.four => l10n.cdFour,
  CardTemplate.letter => l10n.cdLetter,
  CardTemplate.night => l10n.cdNight,
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
                'goldens/s12/${name}_${palette.name}_${locale.languageCode}.png',
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
