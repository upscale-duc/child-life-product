@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/features/milestones/milestone_repository.dart';
import 'package:child_life/features/milestones/milestone_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/milestone_fixtures.dart';

/// Mốc phát triển (Figma v1.1 3a–3g `311:1184` … `311:41795`; D-076 #6) in Light / Night care
/// × vi / en. Teddy, born 17/09/2026, on Thursday 08/10/2026; the reference milestones are the
/// engineering seed (`review: null`). Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/milestone_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
  double height,
});

const _note = 'Bé cười khi mẹ hát bài “Cả nhà thương nhau” sau cữ bú sáng.';

List<Override> _base(
  FakeMilestoneRepository repo, {
  ({List<Memory> memories, List<MediaItem> media})? journal,
}) => [
  ...familyOverrides(now: DateTime(2026, 10, 8, 10), milestones: repo),
  ...memoryOverrides(journal: journal ?? (memories: const [], media: const [])),
];

/// 3d / 3e: "Mỉm cười đáp lại" observed today with the note and two photos still on the phone.
List<Override> _saved() => [
  ..._base(
    FakeMilestoneRepository(
      records: [
        observed(
          'p_first_smile',
          'Mỉm cười đáp lại',
          DateTime(2026, 10, 8),
          note: _note,
        ),
      ],
    ),
  ),
  pendingMilestonePhotosProvider.overrideWith(_Pending.new),
];

class _Pending extends PendingMilestonePhotos {
  @override
  Map<String, List<PickedMedia>> build() => {
    'p_first_smile': [pickedPhoto('IMG_1.JPG'), pickedPhoto('IMG_2.JPG')],
  };
}

/// 3f: the observation and a Gia đình memory tagged with it (two photos).
List<Override> _linked() {
  final record = observed(
    'p_first_smile',
    'Mỉm cười đáp lại',
    DateTime(2026, 10, 8),
    note: _note,
  );
  final tag = record.ref!;
  const memoryId = 'mem_77777777777777777777777777777777';
  final media = [
    mediaItem(
      memoryId,
      DateTime(2026, 10, 8, 9),
      colour: 'peach',
      milestone: tag,
    ),
    mediaItem(
      memoryId,
      DateTime(2026, 10, 8, 9, 1),
      colour: 'sun',
      milestone: tag,
    ),
  ];
  return _base(
    FakeMilestoneRepository(records: [record]),
    journal: (
      memories: [
        Memory(
          id: memoryId,
          babyId: teddyId,
          audience: Audience.family,
          occurredAt: DateTime(2026, 10, 8, 9),
          milestone: tag,
          caption: 'Lần đầu Teddy cười đáp lại mẹ 💛',
          mediaIds: [for (final m in media) m.id],
          photos: 2,
          createdBy: 'u_mai',
          author: CareAuthor.of(mai),
        ),
      ],
      media: media,
    ),
  );
}

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(Scaffold).first));

final Map<String, _Case> _cases = {
  // 3a 311:1184: two observed (one own), suggestions around 3 weeks.
  '3a_list': (
    build: () => const MilestonesScreen(),
    overrides: () => _base(FakeMilestoneRepository(records: drawnRecords())),
    act: null,
    height: 1240,
  ),
  // 3b 311:1308.
  '3b_detail': (
    build: () => const MilestoneDetailScreen(id: 'first_smile'),
    overrides: () => _base(FakeMilestoneRepository()),
    act: null,
    height: 1240,
  ),
  // 3c 311:1364: the record sheet over 3b.
  '3c_record': (
    build: () => const MilestoneDetailScreen(id: 'first_smile'),
    overrides: () => _base(FakeMilestoneRepository()),
    act: (t) async {
      final f = find.text(_l10n(t).mtMarkSeen);
      await t.scrollUntilVisible(
        f,
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
      await t.enterText(find.byType(EditableText).first, _note);
      await t.pumpAndSettle();
    },
    height: 812,
  ),
  // 3d 311:1436.
  '3d_saved': (
    build: () => const MilestoneDetailScreen(id: 'first_smile'),
    overrides: _saved,
    act: null,
    height: 1000,
  ),
  // 3e 311:41672: "Kỷ niệm mới" over 3d.
  '3e_memory': (
    build: () => const MilestoneDetailScreen(id: 'first_smile'),
    overrides: _saved,
    act: (t) async {
      final f = find.text(_l10n(t).mtCreateMemory);
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
    },
    height: 900,
  ),
  // 3f 311:41752.
  '3f_linked': (
    build: () => const MilestoneDetailScreen(id: 'first_smile'),
    overrides: _linked,
    act: null,
    height: 1000,
  ),
  // 3g 311:41795.
  '3g_own': (
    build: () => const OwnMilestoneScreen(),
    overrides: () => _base(FakeMilestoneRepository()),
    act: (t) async {
      await t.enterText(find.byType(EditableText).first, 'Lần đầu về quê');
      await t.enterText(
        find.byType(EditableText).at(1),
        'Cả nhà về Nam Định thăm ông bà. Teddy ngủ suốt chặng đường.',
      );
      await t.pumpAndSettle();
    },
    height: 812,
  ),
  // Caregiver / relative: the guide only.
  '3a_relative': (
    build: () => const MilestonesScreen(),
    overrides: () => [
      ...familyOverrides(
        me: hoa,
        now: DateTime(2026, 10, 8, 10),
        milestones: FakeMilestoneRepository(records: drawnRecords()),
      ),
      ...memoryOverrides(),
    ],
    act: null,
    height: 1000,
  ),
};

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

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          mediaBytes = FakeMediaBytes();
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = Size(375, c.height);
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
                data: MediaQueryData(
                  size: Size(375, c.height),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
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
                'goldens/ms/${name}_${palette.name}_${locale.languageCode}.png',
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
