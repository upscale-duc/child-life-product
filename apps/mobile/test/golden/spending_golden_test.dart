@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/spending/import/import_repository.dart';
import 'package:child_life/features/spending/import/import_screens.dart';
import 'package:child_life/features/spending/spending_categories.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/features/spending/spending_plan_screens.dart';
import 'package:child_life/features/spending/spending_screens.dart';
import 'package:child_life/features/spending/spending_sheets.dart';
import 'package:child_life/features/spending/spending_stats.dart';
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
import '../helpers/spending_fixtures.dart';

/// Chi tiêu (Figma v1.1 8a–8o) in Light / Night care × vi / en at 375 × 812, on the mock of the
/// design: Monday 12/10/2026, October = 4.215.000 ₫ against an 8.000.000 ₫ budget.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

List<Override> _data({
  List<Expense>? expenses,
  List<SpendingCategory> categories = const [],
  String? currency,
  Budget budget = mockBudget,
}) => familyOverrides(
  now: DateTime(2026, 10, 12, 9),
  expenses: expenses ?? mockSpending(),
  categories: categories,
  budget: budget,
  recurring: mockRecurring,
  spendingCurrency: currency,
);

_Case _screen(
  Widget Function() build, {
  List<Expense>? expenses,
  List<SpendingCategory> categories = const [],
  ImportStatus importStatus = ImportStatus.ready,
  Future<void> Function(WidgetTester tester)? act,
  String? currency,
  Budget budget = mockBudget,
}) => (
  build: build,
  overrides: () => [
    ..._data(
      expenses: expenses,
      categories: categories,
      currency: currency,
      budget: budget,
    ),
    // Nhập chi tiêu (D-060).
    spendingImportsProvider.overrideWith(
      (ref, id) => Stream.value([mockImport(ImportStatus.done)]),
    ),
    spendingImportProvider.overrideWith(
      (ref, key) => Stream.value(mockImport(importStatus)),
    ),
  ],
  prefs: const {},
  act: act,
);

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

final _hidden = SpendingCategory(
  id: 'c_0123456789abcdef0000',
  name: 'Đồ dùng & đồ chơi',
  icon: ClIcons.spark,
  tint: CategoryTint.sleep,
  order: 6,
  hidden: true,
);

/// Chi tiêu currencies (D-075 #4): October with a dollar and a yen purchase.
List<Expense> _mixed() => [
  spend(
    '50',
    1250,
    'c_milk',
    DateTime(2026, 10, 12),
    note: 'Formula online',
    currency: 'USD',
  ),
  spend(
    '51',
    2000,
    'c_other',
    DateTime(2026, 10, 11),
    note: 'Gift shop',
    currency: 'JPY',
  ),
  ...mockSpending(),
];

final _cases = <String, _Case>{
  '8b_month': _screen(() => const SpendingScreen()),
  '8b_month_scrolled': _screen(
    () => const SpendingScreen(),
    act: (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await t.pumpAndSettle();
    },
  ),
  '8j_first': _screen(() => const SpendingScreen(), expenses: const []),
  '8c_add': _screen(
    () => const SpendingScreen(),
    act: (t) async {
      await _tap(t, find.byKey(const Key('spAdd')));
      await t.enterText(find.byKey(const Key('spAmount')), '1020000');
      await t.tap(find.byKey(const Key('spCat-c_milk')));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    },
  ),
  '8d_six_months': _screen(() => const SpendingStatsScreen()),
  '8e_since_birth': _screen(
    () => const SpendingStatsScreen(),
    act: (t) async {
      await t.tap(find.textContaining(RegExp('Từ khi sinh|Since birth')).first);
      await t.pumpAndSettle();
    },
  ),
  '8f_history': _screen(() => const SpendingHistoryScreen()),
  '8g_detail': _screen(
    () => ExpenseDetailScreen(expenseId: mockSpending()[3].id),
  ),
  '8h_budget': _screen(() => const BudgetScreen()),
  '8i_recurring': _screen(() => const RecurringScreen()),
  '8k_vaccine_cost': _screen(
    () => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => offerVaccineCost(
              context,
              me: mai,
              doseKey: 'dtp_3',
              doseTitle: 'Mũi 6 trong 1 · lần 3',
              givenOn: DateTime(2026, 10, 12),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ),
    act: (t) async {
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    },
  ),
  '8m_categories': _screen(
    () => const CategoriesScreen(),
    categories: [swimCategory, _hidden],
  ),
  '8n_new_category': _screen(() => const CategoryEditorScreen()),
  '8o_delete_category': _screen(
    () => const CategoryEditorScreen(category: swimCategory),
    categories: [swimCategory],
    act: (t) async {
      await t.scrollUntilVisible(
        find.byKey(const Key('spDeleteCategory')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(t, find.byKey(const Key('spDeleteCategory')));
    },
  ),
  // ---- Chi tiêu currencies (D-075 #4; not drawn) ----
  'cur_8b_month_mixed': _screen(
    () => const SpendingScreen(),
    expenses: _mixed(),
  ),
  'cur_8c_add_usd': _screen(
    () => const SpendingScreen(),
    act: (t) async {
      await _tap(t, find.byKey(const Key('spAdd')));
      await _tap(t, find.byKey(const Key('spCurrency')));
      await _tap(t, find.byKey(const Key('spCur-USD')));
      await t.enterText(find.byKey(const Key('spAmount')), '12');
      await t.tap(find.byKey(const Key('spCat-c_milk')));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    },
  ),
  'cur_picker': _screen(
    () => const SpendingScreen(),
    act: (t) async {
      await _tap(t, find.byKey(const Key('spAdd')));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await _tap(t, find.byKey(const Key('spCurrency')));
    },
  ),
  'cur_8f_history_mixed': _screen(
    () => const SpendingHistoryScreen(),
    expenses: _mixed(),
  ),
  'cur_8h_budget_usd': _screen(
    () => const BudgetScreen(),
    expenses: _mixed(),
    currency: 'USD',
    // Kept in VND before the household moved to dollars.
    budget: Budget.fromJson(const {
      'monthlyTotal': 8000000,
      'caps': {'c_milk': 2200000},
      'alert80': true,
    }),
  ),
  // ---- end Chi tiêu currencies ----
  // Nhập chi tiêu (D-060; not drawn).
  'im1_sources': _screen(() => const SpendingImportScreen()),
  'im2_review': _screen(
    () => const SpendingImportReviewScreen(importId: mockImportId),
  ),
  'im2_review_scrolled': _screen(
    () => const SpendingImportReviewScreen(importId: mockImportId),
    act: (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await t.pumpAndSettle();
    },
  ),
  'im2_adjust': _screen(
    () => const SpendingImportReviewScreen(importId: mockImportId),
    act: (t) async {
      await _tap(t, find.byKey(const Key('imAdjust')));
    },
  ),
  'im2_skipped': _screen(
    () => const SpendingImportReviewScreen(importId: mockImportId),
    act: (t) async {
      await _tap(t, find.byKey(const Key('imSkipped')));
    },
  ),
  'im3_importing': _screen(
    () => const SpendingImportResultScreen(importId: mockImportId),
    importStatus: ImportStatus.importing,
  ),
  'im3_done': _screen(
    () => const SpendingImportResultScreen(importId: mockImportId),
    importStatus: ImportStatus.done,
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
              GoRoute(
                path: '/:a/:b/:c',
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
                'goldens/sp/${name}_${palette.name}_${locale.languageCode}.png',
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
