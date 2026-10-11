@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/vaccines/vaccine_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/vaccine_fixtures.dart';

/// Sổ tiêm chủng (Figma VX 0 – VX 9a) in Light / Night care × vi / en at 375 × 812, on the mock
/// of the design: Teddy, born 17/9/2026, on 8/10/2026 with the three birth doses given.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

const _plan = VaccinePlan(setupDone: true, exists: true);

_Case _book({
  Map<String, Object> prefs = const {},
  Map<String, VaccineDoseRecord>? vaccines,
  Future<void> Function(WidgetTester tester)? act,
}) => (
  build: () => const VaccineBookScreen(),
  overrides: () =>
      careOverrides(vaccines: vaccines ?? vxBirthDoses(), vaccinePlan: _plan),
  prefs: prefs,
  act: act,
);

Map<String, VaccineDoseRecord> _overdue() => {
  ...vxBirthDoses(),
  for (final id in ['dtp', 'rota', 'pcv'])
    '${id}_1': vxRec(
      id,
      1,
      status: DoseRecordStatus.planned,
      plannedOn: DateTime(2026, 10, 3),
    ),
};

final _cases = <String, _Case>{
  'vx1_book': _book(),
  'vx1b_by_age': _book(prefs: const {'vaccines.view': 'byAge'}),
  'vx1a_view_sheet': _book(
    act: (t) async {
      await t.tap(find.byKey(const Key('vxView')));
      await t.pumpAndSettle();
    },
  ),
  'vx5_quick': _book(
    act: (t) async {
      await t.tap(find.bySemanticsLabel(RegExp('^(Mũi|Dose) 1, ')).at(4));
      await t.pumpAndSettle();
    },
  ),
  'vx9_overdue': _book(vaccines: _overdue()),
  'vx9a_overdue_sheet': _book(
    vaccines: _overdue(),
    act: (t) async {
      await t.tap(
        find
            .bySemanticsLabel(RegExp(r'^(Mũi|Dose) 1, (Quá hạn|Overdue)'))
            .at(1),
      );
      await t.pumpAndSettle();
    },
  ),
  'vx0_setup': (
    build: () => const VaccineSetupScreen(),
    overrides: () => careOverrides(),
    prefs: const {},
    act: null,
  ),
  'vx2_milestone': (
    build: () => const VaccineMilestoneScreen(months: 2),
    overrides: () => careOverrides(
      vaccines: vxBirthDoses(),
      vaccinePlan: _plan.copyWith(dtp: DtpChoice.sixInOne),
    ),
    prefs: const {},
    act: null,
  ),
  'vx3_record': (
    build: () => const VaccineMilestoneScreen(months: 2),
    overrides: () => careOverrides(
      vaccines: vxBirthDoses(),
      vaccinePlan: _plan.copyWith(dtp: DtpChoice.sixInOne),
    ),
    prefs: const {},
    act: (t) async {
      await t.tap(find.bySemanticsLabel(RegExp('^(Rota)')).first);
      await t.pumpAndSettle();
      await t.tap(find.textContaining(RegExp('Thêm chi tiết|Add details')));
      await t.pumpAndSettle();
    },
  ),
  'vx6_dose': (
    build: () => const VaccineDoseScreen(doseKey: 'dtp_1'),
    overrides: () => careOverrides(
      vaccines: {
        ...vxBirthDoses(),
        'dtp_1': vxRec(
          'dtp',
          1,
          on: DateTime(2026, 10, 6),
          reaction: 'Sốt nhẹ buổi tối, hết sau 1 ngày',
          photo: 'babies/b_teddy/vaccines/slip00000001.jpg',
        ),
      },
      vaccinePlan: _plan.copyWith(dtp: DtpChoice.sixInOne),
    ),
    prefs: const {},
    act: null,
  ),
  'vx7_info': (
    build: () => const VaccineInfoScreen(vaccineId: 'rota'),
    overrides: () =>
        careOverrides(vaccines: vxBirthDoses(), vaccinePlan: _plan),
    prefs: const {},
    act: null,
  ),
};

/// Storage images decode outside the fake clock: let every visible one finish first.
Future<void> _precacheImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isEmpty) return;
  await tester.runAsync(() async {
    for (final image in images) {
      final element = tester.element(find.byWidget(image).first);
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
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
          await _precacheImages(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/vx/${name}_${palette.name}_${locale.languageCode}.png',
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
