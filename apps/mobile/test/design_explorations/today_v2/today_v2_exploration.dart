// Design exploration only (Step 9A.1). Renders Hôm nay (Adaptive) as it is today ("current", the
// production TodayScreen), Version A and Version B, side by side, into
// docs/design/explorations/today-adaptive-v2/assets/. Not a regression test: run it on macOS with
//
//   cd apps/mobile && flutter test --update-goldens test/design_explorations/today_v2/today_v2_exploration.dart
//
// `--update-goldens` here writes ONLY the images this file names (all under docs/…/assets/);
// production baselines in test/golden/goldens are never touched. The file name has no `_test.dart`
// suffix, so `flutter test` / CI never picks it up on their own.
import 'dart:async';
import 'dart:io';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:child_life/features/adaptive/experience_repository.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/adaptive_fixtures.dart';
import '../../helpers/care_fixtures.dart';
import '../../helpers/family_fixtures.dart';
import '../../helpers/memory_fixtures.dart';
import 'today_v2_prototypes.dart';

const _assets = '../../../../../docs/design/explorations/today-adaptive-v2/assets';
const _phone = Size(375, 812);

final _photos = [
  for (var d = 0; d < 3; d++) mediaItem('mem_$d', DateTime(2026, 10, 7 - d)),
];

/// The same fixture recipe as test/golden/adaptive_golden_test.dart (`_band`), plus levers for
/// the states this exploration needs.
List<Override> _overrides(
  AgeBand band, {
  bool noRecords = false,
  bool noMedia = false,
  Experience? exp,
  Membership? me,
  bool offline = false,
}) => [
  ...careOverrides(
    me: me,
    records: noRecords
        ? const []
        : offline
        ? mockDay(offline: true)
        : null,
    growth: noRecords ? const [] : mockGrowth(),
    online: !offline,
  ),
  ...adaptiveOverrides(
    band: band,
    repo: FakeExperienceRepository(exp ?? Experience.defaults(band)),
    media: noMedia ? const [] : _photos,
  ),
];

/// A nested scope for the states the shared fixtures cannot express (documented in README).
typedef _Scoped = List<Override> Function();

class _Scenario {
  const _Scenario(
    this.id,
    this.title,
    this.band,
    this.overrides, {
    this.scoped,
    this.textScale = 1,
    this.variants = const [('light', 'vi')],
  });
  final String id;
  final String title;
  final AgeBand band;
  final List<Override> Function() overrides;
  final _Scoped? scoped;
  final double textScale;
  final List<(String, String)> variants;
}

const _all4 = [
  ('light', 'vi'),
  ('nightCare', 'vi'),
  ('light', 'en'),
  ('nightCare', 'en'),
];

/// A Cùng nuôi's own Tuỳ chỉnh for a 0–1 child: memories pinned, reminders moved above the care
/// tiles, growth hidden.
final _customized = Experience(
  goals: presetGoals[AgeBand.b0_1]!,
  goalsSource: GoalsSource.chosen,
  bandApplied: AgeBand.b0_1,
  pinned: const [WidgetId.recentMemories],
  order: const [
    WidgetId.recentMemories,
    WidgetId.reminders,
    WidgetId.tiles,
    WidgetId.careDuty,
    WidgetId.growth,
  ],
  hidden: const [WidgetId.growth],
);

final _longName = Baby(
  id: teddy.id,
  familyId: teddy.familyId,
  ownerUid: teddy.ownerUid,
  nickname: 'Nguyễn Hoàng Bảo Ngọc Anh',
  avatar: teddy.avatar,
  trackers: teddy.trackers,
  timeZone: teddy.timeZone,
);

/// Records that never arrive: the first frames after opening the app.
final _neverRecords = StreamController<List<CareRecord>>.broadcast();

final _relativeDailyCare = member(
  'u_hoa',
  'Bà nội Hoa',
  MemberRole.relative,
  Relation.grandmother,
  extra: const ExtraRights(viewBabyInfo: true, viewDailyCare: true),
);

final _scenarios = <_Scenario>[
  _Scenario(
    '0-1',
    '0–1 · Cùng nuôi · dữ liệu đầy đủ',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1),
    variants: _all4,
  ),
  _Scenario(
    '1-3',
    '1–3',
    AgeBand.b1_3,
    () => _overrides(AgeBand.b1_3),
    variants: const [('light', 'vi'), ('nightCare', 'en')],
  ),
  _Scenario(
    '3-6',
    '3–6',
    AgeBand.b3_6,
    () => _overrides(AgeBand.b3_6),
    variants: const [('light', 'vi'), ('nightCare', 'en')],
  ),
  _Scenario(
    '6-12',
    '6–12',
    AgeBand.b6_12,
    () => _overrides(AgeBand.b6_12),
    variants: const [('light', 'vi'), ('nightCare', 'en')],
  ),
  _Scenario(
    'customized',
    '0–1 · pinned Kỷ niệm, Nhắc việc above tiles, Tăng trưởng hidden',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1, exp: _customized),
    variants: const [('light', 'vi'), ('light', 'en')],
  ),
  _Scenario(
    'first-run',
    'First run (no logs, no photos)',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1, noRecords: true, noMedia: true),
    variants: const [('light', 'vi'), ('light', 'en')],
  ),
  _Scenario(
    'first-run-3-6',
    'First run 3–6',
    AgeBand.b3_6,
    () => _overrides(AgeBand.b3_6, noRecords: true, noMedia: true),
  ),
  _Scenario(
    'empty-care',
    'No care logs, has photos (not first run)',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1, noRecords: true),
  ),
  _Scenario(
    'loading',
    'Loading (records not arrived yet)',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1),
    scoped: () => [
      recentRecordsProvider.overrideWith((ref, id) => _neverRecords.stream),
    ],
    variants: const [('light', 'vi'), ('nightCare', 'vi')],
  ),
  _Scenario(
    'long-name',
    'Long child name',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1),
    scoped: () => [
      babyProvider.overrideWith((ref, id) => Stream.value(_longName)),
    ],
    variants: const [('light', 'vi'), ('light', 'en')],
  ),
  _Scenario(
    'offline',
    'Offline with pending logs',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1, offline: true),
  ),
  _Scenario(
    'text-200',
    'Text scale 200 %',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1),
    textScale: 2,
    variants: const [('light', 'vi'), ('light', 'en')],
  ),
  _Scenario(
    'relative',
    'Người thân with daily care (read-only)',
    AgeBand.b0_1,
    () => _overrides(AgeBand.b0_1, me: _relativeDailyCare),
  ),
];

enum _Panel { current, a, b }

Widget _panel(_Panel p) => switch (p) {
  _Panel.current => const Scaffold(body: TodayScreen()),
  _Panel.a => const Scaffold(body: TodayProtoA()),
  _Panel.b => const Scaffold(body: TodayProtoB()),
};

String _label(_Panel p, String locale) => switch (p) {
  _Panel.current => locale == 'vi' ? 'Hiện tại' : 'Current',
  _Panel.a => locale == 'vi' ? 'A · Tinh chỉnh' : 'A · Refined current',
  _Panel.b => locale == 'vi' ? 'B · Bản tin' : 'B · Adaptive Briefing',
};

/// Writes the ranked order the panels consumed, so the README can show it is the engine's.
class _RankProbe extends ConsumerWidget {
  const _RankProbe(this.id, this.sink);
  final String id;
  final Map<String, String> sink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me != null) {
      final ranked = ref.watch(adaptiveTodayProvider(me.babyId));
      sink[id] = [
        for (final w in ranked)
          '${w.id.wire}${w.visible ? '' : ' (hidden)'}${w.pinned ? ' [pinned]' : ''}',
      ].join(' → ');
    }
    return const SizedBox.shrink();
  }
}

final _orders = <String, String>{};
final _overflows = <String, String>{};

Future<void> _render(
  WidgetTester tester,
  _Scenario s,
  String palette,
  String locale,
  List<_Panel> panels,
  String file,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  const labelH = 28.0;
  final triptych = panels.length > 1;
  final size = Size(
    _phone.width * panels.length,
    _phone.height + (triptych ? labelH : 0),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = buildClTheme(
    palette == 'light' ? ClPalette.light : ClPalette.nightCare,
  );

  Widget phone(_Panel p) {
    Widget child = MediaQuery(
      data: MediaQueryData(
        size: _phone,
        disableAnimations: true,
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        textScaler: TextScaler.linear(s.textScale),
      ),
      child: SizedBox.fromSize(size: _phone, child: _panel(p)),
    );
    if (s.scoped != null) {
      child = ProviderScope(overrides: s.scoped!(), child: child);
    }
    return child;
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (triptych)
                SizedBox(
                  height: labelH,
                  child: Row(
                    children: [
                      for (final p in panels)
                        SizedBox(
                          width: _phone.width,
                          child: Center(
                            child: Text(
                              _label(p, locale),
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final p in panels) phone(p)],
              ),
              _RankProbe('${s.id} $palette $locale', _orders),
            ],
          ),
        ),
      ),
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
        ...s.overrides(),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: RepaintBoundary(
          key: const ValueKey('exploration'),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: Locale(locale),
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
  // The loading scenario never settles its records; pump a fixed time instead.
  if (s.id == 'loading') {
    await tester.pump(const Duration(seconds: 1));
  } else {
    await tester.pumpAndSettle();
  }
  // Layout overflows are evidence, not a reason to skip the image (200 % text): record them.
  final errors = <String>[];
  for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
    errors.add(e.toString().split('\n').first);
  }
  if (errors.isNotEmpty) _overflows[file] = errors.join(' | ');
  debugDisableShadows = false;
  try {
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('exploration')),
      matchesGoldenFile('$_assets/$file'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  for (final s in _scenarios) {
    for (final (palette, locale) in s.variants) {
      final suffix = '${s.id}_${palette}_$locale';
      testWidgets('compare $suffix', (tester) async {
        await _render(
          tester,
          s,
          palette,
          locale,
          _Panel.values,
          'compare_$suffix.png',
        );
      });
      for (final p in [_Panel.a, _Panel.b]) {
        final name = p == _Panel.a ? 'version-a' : 'version-b';
        testWidgets('$name $suffix', (tester) async {
          await _render(tester, s, palette, locale, [p], '${name}_$suffix.png');
        });
      }
    }
  }
  tearDownAll(() {
    final out = File(
      '../../docs/design/explorations/today-adaptive-v2/assets/ranked_orders.txt',
    );
    final lines = (_orders.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}: ${e.value}');
    out.writeAsStringSync('${lines.join('\n')}\n');
    File(
      '../../docs/design/explorations/today-adaptive-v2/assets/overflows.txt',
    ).writeAsStringSync(
      _overflows.isEmpty
          ? 'No layout exceptions.\n'
          : '${(_overflows.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}: ${e.value}').join('\n')}\n',
    );
  });
}
