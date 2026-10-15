import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/design/tabular_text.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/family/family_screen.dart';
import 'package:child_life/features/spending/spending_categories.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/features/spending/spending_plan_screens.dart';
import 'package:child_life/features/spending/spending_screens.dart';
import 'package:child_life/features/spending/spending_sheets.dart';
import 'package:child_life/features/spending/spending_stats.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/spending_fixtures.dart';

/// A plain or tabular (amount) text.
Finder _t(String text) => find.byWidgetPredicate(
  (w) =>
      (w is Text && (w.data ?? w.textSpan?.toPlainText()) == text) ||
      (w is ClTabularText && w.text == text),
  description: 'text "$text"',
);

/// Scrolls the page until [finder] is built, then to the middle of the screen (clear of the
/// bottom bar).
Future<void> _see(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

/// [screen] pushed over a launcher, so it can pop itself.
Widget _over(Widget screen) => Builder(
  builder: (context) => TextButton(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen)),
    child: const Text('open'),
  ),
);

String _amount(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('spAmount')))
    .controller!
    .text;

/// Chi tiêu (v1.1 8a–8o) on the mock of the design: Monday 12/10/2026, October = 4.215.000 ₫.
final _now = DateTime(2026, 10, 12, 9);

class _FakeFamily extends Fake implements FamilyRepository {
  final roles = <(String uid, MemberRole role, ExtraRights? rights)>[];

  @override
  Future<void> updateRole({
    required String babyId,
    required String uid,
    required MemberRole role,
    ExtraRights? extraRights,
  }) async => roles.add((uid, role, extraRights));
}

Future<(List<Visit>, ProviderContainer)> _pump(
  WidgetTester tester,
  Widget screen, {
  Membership? me,
  List<Expense>? expenses,
  List<SpendingCategory> categories = const [],
  Budget budget = mockBudget,
  List<RecurringExpense>? recurring,
  FakeSpendingRepository? repo,
  Locale locale = const Locale('vi'),
  String? currency,
}) {
  return pumpRouted(
    tester,
    Scaffold(body: screen),
    locale: locale,
    overrides: familyOverrides(
      me: me,
      now: _now,
      expenses: expenses ?? mockSpending(),
      categories: categories,
      budget: budget,
      recurring: recurring ?? mockRecurring,
      spendingRepo: repo,
      spendingCurrency: currency,
    ),
  );
}

void main() {
  group('8b month', () {
    testWidgets('total against the budget, KPIs, categories, recent', (
      tester,
    ) async {
      final (visits, _) = await _pump(tester, const SpendingScreen());
      expect(_t('Tháng 10 · 2026'), findsOneWidget);
      expect(_t('Đến 12/10'), findsOneWidget);
      expect(_t('Đã chi cho Teddy'), findsOneWidget);
      expect(_t('4.215.000 ₫'), findsOneWidget);
      expect(_t('53% ngân sách 8.000.000 ₫'), findsOneWidget);
      expect(_t('Còn 3.785.000 ₫'), findsOneWidget);
      expect(_t('351.000 ₫'), findsOneWidget);
      expect(_t('Thấp hơn 8%'), findsOneWidget);
      expect(_t('So với tháng 9'), findsOneWidget);
      expect(_t('Giữ trẻ & học'), findsOneWidget);
      expect(_t('2 khoản · Gồm 1 mũi tiêm'), findsNothing);
      expect(_t('1 khoản · Gồm 1 mũi tiêm'), findsOneWidget);
      await _see(tester, _t('Hôm nay · Mẹ trả'));
      await _see(tester, _t('Sữa công thức ×2'));
      expect(_t('Có hoá đơn'), findsWidgets);

      await _see(tester, _t('Xem tất cả'));
      await tester.tap(_t('Xem tất cả'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.spendingHistory);
    });

    testWidgets('the previous month, and back; no future months', (
      tester,
    ) async {
      await _pump(tester, const SpendingScreen());
      await tester.tap(find.bySemanticsLabel('Tháng trước'));
      await tester.pumpAndSettle();
      expect(_t('Tháng 9 · 2026'), findsOneWidget);
      expect(_t('4.600.000 ₫'), findsOneWidget);
      expect(_t('Đến 12/10'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Tháng sau'));
      await tester.pumpAndSettle();
      expect(_t('Tháng 10 · 2026'), findsOneWidget);
    });

    testWidgets('8j first use when nothing is recorded', (tester) async {
      await _pump(tester, const SpendingScreen(), expenses: const []);
      expect(_t('Ghi lại chi tiêu cho Teddy'), findsOneWidget);
      expect(_t('Thêm khoản chi đầu tiên'), findsOneWidget);
      await tester.tap(find.byKey(const Key('spFirstAdd')));
      await tester.pumpAndSettle();
      expect(_t('Lưu khoản chi'), findsOneWidget);
    });

    testWidgets('"Ghi khoản đã chi" only: own items, no totals (D-055)', (
      tester,
    ) async {
      final nanny = member(
        'u_lan',
        'Cô Lan',
        MemberRole.caregiver,
        Relation.nanny,
        extra: const ExtraRights(recordSpending: true),
      );
      await _pump(
        tester,
        const SpendingScreen(),
        me: nanny,
        expenses: [
          spend(
            '1',
            120000,
            'c_diaper',
            DateTime(2026, 10, 12),
            note: 'Khăn ướt',
            createdBy: 'u_lan',
          ),
        ],
      );
      expect(_t('Khoản bạn đã ghi'), findsOneWidget);
      expect(_t('Khăn ướt'), findsOneWidget);
      expect(find.textContaining('ngân sách'), findsNothing);
      expect(_t('Thống kê'), findsNothing);
    });

    testWidgets('no right, no spending', (tester) async {
      await _pump(tester, const SpendingScreen(), me: hoa);
      expect(find.textContaining('chỉ cha mẹ xem'), findsOneWidget);
      expect(_t('Thêm khoản chi'), findsNothing);
    });
  });

  group('8c add', () {
    testWidgets('amount, category, payer; saved for Teddy', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const SpendingScreen(), repo: repo);
      await tester.tap(find.byKey(const Key('spAdd')));
      await tester.pumpAndSettle();
      expect(_t('Lần trước 1.020.000'), findsNothing);
      await tester.enterText(find.byKey(const Key('spAmount')), '285000');
      await tester.pump();
      expect(_amount(tester), '285.000');
      await tester.tap(find.byKey(const Key('spCat-c_diaper')));
      await tester.pump();
      expect(_t('Lần trước 285.000'), findsOneWidget);
      await tester.tap(_t('+100.000'));
      await tester.pump();
      expect(_amount(tester), '385.000');
      await tester.enterText(find.byType(EditableText).at(1), 'Tã dán size M');
      await tester.ensureVisible(_t('Ba'));
      await tester.tap(_t('Ba'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('spSave')));
      await tester.tap(find.byKey(const Key('spSave')));
      await tester.pumpAndSettle();
      final saved = repo.expenses.single;
      expect(saved.amount, 385000);
      expect(saved.categoryId, 'c_diaper');
      expect(saved.note, 'Tã dán size M');
      expect(saved.payer?.uid, 'u_minh');
      expect(saved.spentOn, DateTime(2026, 10, 12));
      expect(repo.recurring, isEmpty);
      expect(_t('Đã lưu khoản chi'), findsOneWidget);
    });

    testWidgets('"Lặp lại hằng tháng" adds a monthly item after today', (
      tester,
    ) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const SpendingScreen(), repo: repo);
      await tester.tap(find.byKey(const Key('spAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('spAmount')), '2000000');
      await tester.tap(find.byKey(const Key('spCat-c_childcare')));
      await tester.pump();
      await tester.ensureVisible(find.byType(CupertinoSwitch).last);
      await tester.tap(find.byType(CupertinoSwitch).last);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('spSave')));
      await tester.tap(find.byKey(const Key('spSave')));
      await tester.pumpAndSettle();
      expect(repo.expenses.single.amount, 2000000);
      final r = repo.recurring.single;
      expect(r.title, 'Giữ trẻ & học');
      expect(r.schedule.toJson(), {
        'kind': 'monthly',
        'days': [12],
      });
      expect(r.recordedOn, DateTime(2026, 10, 12));
    });

    testWidgets('no amount, no save', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const SpendingScreen(), repo: repo);
      await tester.tap(find.byKey(const Key('spAdd')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('spSave')));
      await tester.tap(find.byKey(const Key('spSave')));
      await tester.pumpAndSettle();
      expect(repo.expenses, isEmpty);
      expect(_t('Nhập số tiền'), findsOneWidget);
    });
  });

  group('8f history', () {
    testWidgets('this month by day, search and the receipt filter', (
      tester,
    ) async {
      await _pump(tester, const SpendingHistoryScreen());
      expect(_t('Hôm nay · 12/10'), findsOneWidget);
      expect(_t('Hôm qua · 11/10'), findsOneWidget);
      expect(_t('445.000 ₫'), findsOneWidget);
      expect(_t('Mẹ trả · từ Tiêm chủng'), findsOneWidget);
      expect(_t('Ba trả · định kỳ'), findsOneWidget);
      expect(_t('Cô giữ trẻ · tháng 9'), findsNothing);

      await tester.enterText(find.byKey(const Key('spSearch')), 'ta dan');
      await tester.pump();
      expect(_t('Tã dán size M'), findsOneWidget);
      expect(_t('Sữa công thức ×2'), findsNothing);
      await tester.enterText(find.byKey(const Key('spSearch')), '');
      await tester.pump();
      await tester.ensureVisible(_t('Có hoá đơn').first);
      await tester.tap(_t('Có hoá đơn').first);
      await tester.pump();
      await _see(tester, _t('Sữa công thức ×2'));
      expect(_t('Tã dán size M'), findsNothing);
    });
  });

  group('8g detail', () {
    testWidgets('rows, the vaccine link, delete with undo', (tester) async {
      final repo = FakeSpendingRepository();
      final (visits, _) = await _pump(
        tester,
        ExpenseDetailScreen(expenseId: mockSpending()[3].id),
        repo: repo,
      );
      expect(_t('395.000 ₫'), findsOneWidget);
      expect(_t('Mũi 6 trong 1 · lần 2'), findsOneWidget);
      expect(_t('09/10/2026'), findsOneWidget);
      expect(_t('Bạn · 09/10, 10:24'), findsOneWidget);
      expect(_t('Lịch tiêm chủng · Mũi 6 trong 1 · lần 2'), findsOneWidget);
      await tester.tap(_t('Liên kết'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.vaccineDose}/dtp_2');
    });

    testWidgets('delete is soft and can be undone', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        ExpenseDetailScreen(expenseId: mockSpending().first.id),
        repo: repo,
      );
      await tester.ensureVisible(find.byKey(const Key('spDeleteExpense')));
      await tester.tap(find.byKey(const Key('spDeleteExpense')));
      await tester.pump();
      expect(repo.deleted.single.$2, isFalse);
      await tester.tap(_t('Hoàn tác'));
      await tester.pump();
      expect(repo.deleted.last.$2, isTrue);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a viewer cannot edit another member\'s item', (tester) async {
      final viewer = member(
        'u_hoa',
        'Bà nội Hoa',
        MemberRole.relative,
        Relation.grandmother,
        extra: const ExtraRights(viewSpending: true),
      );
      await _pump(
        tester,
        ExpenseDetailScreen(expenseId: mockSpending().first.id),
        me: viewer,
      );
      expect(_t('1.020.000 ₫'), findsOneWidget);
      expect(find.byKey(const Key('spDeleteExpense')), findsNothing);
      expect(find.bySemanticsLabel('Sửa'), findsNothing);
    });
  });

  group('8h budget', () {
    testWidgets('caps, near the limit, alert; saved', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const BudgetScreen(), repo: repo);
      expect(_t('8.000.000 ₫'), findsOneWidget);
      expect(_t('Tháng 10: đã dùng 53%'), findsOneWidget);
      expect(_t('2.000.000 / 4.000.000'), findsOneWidget);
      expect(_t('50% đã dùng'), findsOneWidget);
      expect(_t('Gần chạm mức · còn 5.000 ₫'), findsOneWidget);
      expect(_t('Chưa đặt mức'), findsWidgets);

      await _see(tester, _t('Quần áo'));
      await tester.tap(_t('Quần áo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('spAmount')), '500000');
      await tester.tap(find.byKey(const Key('spAmountDone')));
      await tester.pumpAndSettle();
      expect(_t('160.000 / 500.000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('spSaveBudget')));
      await tester.pumpAndSettle();
      expect(repo.budgets.single.caps['c_clothes'], 500000);
      expect(repo.budgets.single.monthlyTotal, 8000000);
    });
  });

  group('8i recurring', () {
    testWidgets('schedules, payer, the next one; add one', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const RecurringScreen(), repo: repo);
      expect(_t('Ngày 1 và 16 hằng tháng · Ba trả'), findsOneWidget);
      expect(_t('Ngày 5/3 hằng năm'), findsOneWidget);
      expect(
        _t(
          'Ngày 16/10: Cô giữ trẻ 2.000.000 ₫ sẽ được thêm. Bạn có thể sửa số tiền sau khi thêm.',
        ),
        findsOneWidget,
      );
      await _see(tester, find.byKey(const Key('spAddRecurring')));
      await tester.tap(find.byKey(const Key('spAddRecurring')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('spAmount')), '1020000');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('spRecurringName')),
          matching: find.byType(EditableText),
        ),
        'Sữa công thức',
      );
      await tester.ensureVisible(_t('Theo tuần'));
      await tester.tap(_t('Theo tuần'));
      await tester.pump();
      expect(_t('Mỗi 2 tuần'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('spSaveRecurring')));
      await tester.tap(find.byKey(const Key('spSaveRecurring')));
      await tester.pumpAndSettle();
      final r = repo.recurring.single;
      expect(r.title, 'Sữa công thức');
      expect(r.amount, 1020000);
      expect(r.schedule, isA<EveryWeeks>());
      expect(r.recordedOn, isNull);
    });
  });

  group('8m–8o categories', () {
    testWidgets('list, hidden ones, show again', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        const CategoriesScreen(),
        repo: repo,
        categories: [
          swimCategory,
          const SpendingCategory(
            id: 'c_0123456789abcdef0000',
            name: 'Đồ dùng & đồ chơi',
            icon: ClIcons.spark,
            tint: CategoryTint.sleep,
            order: 6,
            hidden: true,
          ),
        ],
      );
      expect(_t('Bơi & vận động'), findsOneWidget);
      expect(_t('Tự tạo · 0 khoản'), findsOneWidget);
      expect(_t('Mặc định · không xoá được'), findsOneWidget);
      expect(_t('Đã ẩn'), findsOneWidget);
      await tester.tap(_t('Hiện lại'));
      await tester.pump();
      expect(repo.categories.single.single.hidden, isFalse);
    });

    testWidgets('8n new category: name, icon, colour', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, _over(const CategoryEditorScreen()), repo: repo);
      await tester.tap(_t('open'));
      await tester.pumpAndSettle();
      expect(_t('Danh mục mới'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('spCategoryName')),
          matching: find.byType(EditableText),
        ),
        'Bơi & vận động',
      );
      await _see(tester, find.bySemanticsLabel('Màu 2'));
      await tester.tap(find.bySemanticsLabel('Màu 2'));
      await tester.tap(_t('Lưu danh mục'));
      await tester.pumpAndSettle();
      final c = repo.categories.single.single;
      expect(c.name, 'Bơi & vận động');
      expect(c.tint, CategoryTint.bottle);
      expect(c.builtIn, isFalse);
      expect(c.id, matches(RegExp(r'^c_[a-f0-9]{20}$')));
    });

    testWidgets('8n a name already taken is refused', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, _over(const CategoryEditorScreen()), repo: repo);
      await tester.tap(_t('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('spCategoryName')),
          matching: find.byType(EditableText),
        ),
        'quần áo',
      );
      await tester.tap(_t('Lưu danh mục'));
      await tester.pumpAndSettle();
      expect(repo.categories, isEmpty);
      expect(_t('Đã có danh mục tên này'), findsOneWidget);
    });

    testWidgets('8o delete moves the items to Khác', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        _over(const CategoryEditorScreen(category: swimCategory)),
        repo: repo,
        categories: [swimCategory],
        expenses: [
          ...mockSpending(),
          spend(
            '20',
            1240000,
            swimCategory.id,
            DateTime(2026, 10, 3),
            note: 'Học bơi',
          ),
        ],
      );
      await tester.tap(_t('open'));
      await tester.pumpAndSettle();
      expect(_t('Sửa danh mục'), findsOneWidget);
      await _see(tester, find.byKey(const Key('spDeleteCategory')));
      await tester.tap(find.byKey(const Key('spDeleteCategory')));
      await tester.pumpAndSettle();
      expect(_t('Xoá “Bơi & vận động”?'), findsOneWidget);
      expect(
        _t(
          'Danh mục này có 1 khoản chi (1.240.000 ₫). Chọn nơi chuyển các khoản này:',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('spConfirmDeleteCategory')));
      await tester.pumpAndSettle();
      expect(repo.deletedCategories.single, (swimCategory.id, otherCategoryId));
    });
  });

  group('8d / 8e statistics', () {
    testWidgets('six months: KPIs, legend, payers', (tester) async {
      await _pump(tester, const SpendingStatsScreen());
      expect(_t('8,8 tr'), findsOneWidget);
      expect(_t('Tổng 6 tháng'), findsOneWidget);
      expect(_t('Cao nhất · T9'), findsOneWidget);
      expect(_t('T10 đang tính đến 12/10'), findsOneWidget);
      await _see(tester, _t('Ai trả'));
    });

    testWidgets('since birth: total, largest first, CSV', (tester) async {
      await _pump(tester, const SpendingStatsScreen());
      await tester.tap(_t('Từ khi sinh'));
      await tester.pumpAndSettle();
      expect(_t('Từ khi Teddy chào đời'), findsOneWidget);
      await _see(tester, _t('Khoản lớn nhất'));
      await _see(tester, _t('Xuất file chi tiêu (CSV)'));
    });
  });

  group('8k vaccine cost', () {
    testWidgets('prefilled from the last cost of the vaccine; saved', (
      tester,
    ) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
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
        repo: repo,
      );
      await tester.tap(_t('go'));
      await tester.pumpAndSettle();
      expect(_t('Ghi chi phí mũi tiêm?'), findsOneWidget);
      expect(_amount(tester), '395.000');
      await tester.tap(find.byKey(const Key('spVaccineSave')));
      await tester.pumpAndSettle();
      final e = repo.expenses.single;
      expect(e.doseKey, 'dtp_3');
      expect(e.categoryId, healthCategoryId);
      expect(e.amount, 395000);
      expect(e.note, 'Mũi 6 trong 1 · lần 3');
    });

    testWidgets('not again for a dose that has a cost, nor without a right', (
      tester,
    ) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => offerVaccineCost(
                  context,
                  me: mai,
                  doseKey: 'dtp_2',
                  doseTitle: 'x',
                  givenOn: DateTime(2026, 10, 9),
                ),
                child: const Text('again'),
              ),
              TextButton(
                onPressed: () => offerVaccineCost(
                  context,
                  me: lan,
                  doseKey: 'dtp_3',
                  doseTitle: 'x',
                  givenOn: DateTime(2026, 10, 9),
                ),
                child: const Text('nanny'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(_t('again'));
      await tester.pumpAndSettle();
      await tester.tap(_t('nanny'));
      await tester.pumpAndSettle();
      expect(_t('Ghi chi phí mũi tiêm?'), findsNothing);
    });
  });

  group('8l member rights', () {
    testWidgets('a caregiver gets the two spending switches', (tester) async {
      final family = _FakeFamily();
      await pumpRouted(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showMemberSheet(context, babyId: teddyId, uid: lan.uid),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: [
          ...familyOverrides(now: _now),
          familyRepositoryProvider.overrideWithValue(family),
        ],
      );
      await tester.tap(_t('open'));
      await tester.pumpAndSettle();
      expect(_t('Ghi khoản đã chi'), findsOneWidget);
      expect(_t('Xem toàn bộ chi tiêu'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('rightRecordSpending')));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('rightRecordSpending')),
          matching: find.byType(CupertinoSwitch),
        ),
      );
      await tester.pumpAndSettle();
      final (uid, role, rights) = family.roles.single;
      expect(uid, 'u_lan');
      expect(role, MemberRole.caregiver);
      expect(rights?.recordSpending, isTrue);
      expect(rights?.viewSpending, isFalse);
    });
  });

  // ---- Chi tiêu currencies (D-075 #4) ----
  group('currencies (D-075 #4)', () {
    final mixed = [
      spend(
        '50',
        1250,
        'c_milk',
        DateTime(2026, 10, 12),
        note: 'Formula online',
        currency: 'USD',
      ),
      spend('51', 2000, 'c_other', DateTime(2026, 10, 12), currency: 'JPY'),
      ...mockSpending(),
    ];

    testWidgets('8c: another currency from the picker, saved in cents', (
      tester,
    ) async {
      final repo = FakeSpendingRepository();
      await _pump(tester, const SpendingScreen(), repo: repo);
      await tester.tap(find.byKey(const Key('spAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('spAmount')), '12');
      await tester.pump();
      await tester.tap(find.byKey(const Key('spCurrency')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('spCur-USD')));
      await tester.tap(find.byKey(const Key('spCur-USD')));
      await tester.pumpAndSettle();
      // The typed number stays, now in dollars; the steps are whole dollars.
      expect(_amount(tester), '12,00');
      expect(_t('+10'), findsOneWidget);
      expect(_t('+100.000'), findsNothing);
      await tester.enterText(find.byKey(const Key('spAmount')), '12,5');
      await tester.pump();
      expect(_amount(tester), '12,5');
      await tester.ensureVisible(find.byKey(const Key('spSave')));
      await tester.tap(find.byKey(const Key('spSave')));
      await tester.pumpAndSettle();
      final saved = repo.expenses.single;
      expect(saved.amount, 1250);
      expect(saved.currency, 'USD');
    });

    testWidgets('8c: the household currency is the default', (tester) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        const SpendingScreen(),
        repo: repo,
        currency: 'EUR',
        locale: const Locale('en'),
        expenses: const [],
      );
      await tester.tap(find.byKey(const Key('spFirstAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('spAmount')), '7.99');
      await tester.pump();
      expect(_amount(tester), '7.99');
      await tester.ensureVisible(find.byKey(const Key('spSave')));
      await tester.tap(find.byKey(const Key('spSave')));
      await tester.pumpAndSettle();
      expect(repo.expenses.single.amount, 799);
      expect(repo.expenses.single.currency, 'EUR');
    });

    testWidgets('8b: totals in the household currency, the others apart', (
      tester,
    ) async {
      await _pump(tester, const SpendingScreen(), expenses: mixed);
      expect(_t('4.215.000 ₫'), findsOneWidget);
      expect(_t('53% ngân sách 8.000.000 ₫'), findsOneWidget);
      expect(find.byKey(const Key('spOtherCurrencies')), findsOneWidget);
      expect(_t('Ngoài ra: 2.000\u00A0¥ · 12,50\u00A0\$'), findsOneWidget);
      // The recent list shows every currency, each in its own.
      await _see(tester, _t('Formula online'));
      expect(_t('12,50\u00A0\$'), findsOneWidget);
    });

    testWidgets(
      '8b: a budget kept in another currency does not measure this one',
      (tester) async {
        await _pump(
          tester,
          const SpendingScreen(),
          expenses: mixed,
          currency: 'USD',
          locale: const Locale('en'),
          // Stored before D-075 #4: VND.
          budget: Budget.fromJson({
            'monthlyTotal': 8000000,
            'caps': <String, Object?>{},
            'alert80': true,
          }),
        );
        expect(_t(r'$12.50'), findsWidgets);
        expect(_t('Also: ¥2,000 · 4,215,000 ₫'), findsOneWidget);
        expect(find.textContaining('budget'), findsNothing);
      },
    );

    testWidgets('8h: main currency row; an old VND budget starts over in USD', (
      tester,
    ) async {
      final repo = FakeSpendingRepository();
      await _pump(
        tester,
        const BudgetScreen(),
        repo: repo,
        currency: 'USD',
        locale: const Locale('en'),
        expenses: mixed,
        budget: Budget.fromJson({
          'monthlyTotal': 8000000,
          'caps': {'c_milk': 2200000},
          'alert80': true,
        }),
      );
      expect(_t('Main currency'), findsOneWidget);
      expect(_t('USD · US dollar'), findsOneWidget);
      expect(
        _t(
          'The budget is kept in VND. Set the amounts again and save to count USD.',
        ),
        findsOneWidget,
      );
      expect(_t('8,000,000 ₫'), findsNothing);
      await tester.tap(find.byKey(const Key('spMainCurrency')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('spCur-EUR')));
      await tester.tap(find.byKey(const Key('spCur-EUR')));
      await tester.pumpAndSettle();
      expect(repo.currencies, ['EUR']);
      await tester.tap(find.byKey(const Key('spSaveBudget')));
      await tester.pumpAndSettle();
      expect(repo.budgets.single.currency, 'USD');
      expect(repo.budgets.single.monthlyTotal, isNull);
    });

    testWidgets('8h: caps count the budget currency only', (tester) async {
      await _pump(tester, const BudgetScreen(), expenses: mixed);
      // c_milk: 1.020.000 + 100.000 đ; the 12,50 $ is not counted.
      expect(_t('1.120.000 / 2.200.000'), findsOneWidget);
    });

    testWidgets('8f: a day sums each currency apart', (tester) async {
      await _pump(tester, const SpendingHistoryScreen(), expenses: mixed);
      expect(_t('1.020.000 ₫ · 2.000\u00A0¥ · 12,50\u00A0\$'), findsOneWidget);
    });

    testWidgets(
      '8d: statistics count the household currency, note the others',
      (tester) async {
        await _pump(tester, const SpendingStatsScreen(), expenses: mixed);
        expect(find.byKey(const Key('spStatsOtherCurrencies')), findsOneWidget);
        expect(
          _t(
            'Không cộng vào tổng (tiền tệ khác): 2.000\u00A0¥ · 12,50\u00A0\$',
          ),
          findsOneWidget,
        );
      },
    );
  });
  // ---- end Chi tiêu currencies ----
}
