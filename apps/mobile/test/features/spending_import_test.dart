import 'package:child_life/core/design/tabular_text.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/spending/import/import_repository.dart';
import 'package:child_life/features/spending/import/import_screens.dart';
import 'package:child_life/features/spending/spending_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/spending_fixtures.dart';

/// Nhập chi tiêu (D-060, P-144): sources, review, result.

const _id = mockImportId;

class _FakeImports implements SpendingImportRepository {
  final analyzed = <(ImportMapping?, ImportOptions?)>[];
  ({Map<String, CategoryChoice> categories, Map<String, String?> payers})?
  confirmed;
  final undone = <String>[];
  final pages = <int>[];

  @override
  Future<ImportPage> page(String babyId, String importId, int page) async {
    pages.add(page);
    return ImportPage(
      rows: [
        for (var i = 0; i < 50; i++)
          ImportPreviewRow(
            row: page * 50 + i + 2,
            spentOn: '2026-10-01',
            amount: 1000 * (i + 1),
            note: 'Khoản ${page * 50 + i + 1}',
            category: 'Sữa',
            payer: '',
            issue: null,
          ),
      ],
      total: 210,
      page: page,
      pages: 5,
    );
  }

  @override
  Future<void> analyze({
    required String babyId,
    required String importId,
    required ImportKind kind,
    String? fileName,
    String? text,
    int? images,
    ImportMapping? mapping,
    ImportOptions? options,
  }) async => analyzed.add((mapping, options));

  @override
  Future<void> confirm({
    required String babyId,
    required String importId,
    required ImportMapping mapping,
    required ImportOptions options,
    required Map<String, CategoryChoice> categories,
    required Map<String, String?> payers,
  }) async => confirmed = (categories: categories, payers: payers);

  @override
  Future<int> undo(String babyId, String importId) async {
    undone.add(importId);
    return 210;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder _t(String text) => find.byWidgetPredicate(
  (w) =>
      (w is Text && (w.data ?? w.textSpan?.toPlainText()) == text) ||
      (w is ClTabularText && w.text == text),
  description: 'text "$text"',
);

Future<void> _see(WidgetTester tester, Finder f) => tester.scrollUntilVisible(
  f,
  200,
  scrollable: find.byType(Scrollable).first,
);

Future<(List<Visit>, ProviderContainer)> _pump(
  WidgetTester tester,
  Widget screen, {
  Membership? me,
  ImportStatus status = ImportStatus.ready,
  _FakeImports? repo,
}) {
  return pumpRouted(
    tester,
    Scaffold(body: screen),
    overrides: [
      ...familyOverrides(
        me: me,
        now: DateTime(2026, 10, 12, 9),
        expenses: mockSpending(),
      ),
      spendingImportRepositoryProvider.overrideWithValue(
        repo ?? _FakeImports(),
      ),
      spendingImportsProvider.overrideWith(
        (ref, id) => Stream.value([mockImport(status)]),
      ),
      spendingImportProvider.overrideWith(
        (ref, key) => Stream.value(mockImport(status)),
      ),
    ],
  );
}

void main() {
  testWidgets('Chi tiêu offers a small "Nhập" under "Thêm khoản chi"', (
    tester,
  ) async {
    final (visits, _) = await _pump(tester, const SpendingScreen());
    final add = tester.getCenter(find.byKey(const Key('spAdd')));
    final import = tester.getCenter(find.byKey(const Key('spImport')));
    expect(import.dy, greaterThan(add.dy));
    await tester.tap(find.byKey(const Key('spImport')));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/utilities/spending/import');
  });

  testWidgets('sources and the recent imports; parents only', (tester) async {
    final (visits, _) = await pumpRouted(
      tester,
      const Scaffold(body: SpendingImportScreen()),
      overrides: [
        ...familyOverrides(now: DateTime(2026, 10, 12, 9)),
        spendingImportsProvider.overrideWith(
          (ref, id) => Stream.value([mockImport(ImportStatus.done)]),
        ),
      ],
    );
    expect(_t('Tệp CSV hoặc Excel'), findsOneWidget);
    expect(_t('Dán văn bản'), findsOneWidget);
    expect(_t('Ảnh chụp sổ chi tiêu'), findsOneWidget);
    expect(_t('money-lover-2026.csv'), findsOneWidget);
    await tester.tap(_t('money-lover-2026.csv'));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/utilities/spending/import/$_id');
  });

  testWidgets('a caregiver cannot import', (tester) async {
    await _pump(tester, const SpendingImportScreen(), me: lan);
    expect(_t('Chỉ Cùng nuôi được nhập chi tiêu.'), findsOneWidget);
    expect(_t('Tệp CSV hoặc Excel'), findsNothing);
  });

  testWidgets('review: counts, columns, signs, categories; confirm', (
    tester,
  ) async {
    final repo = _FakeImports();
    final (visits, _) = await _pump(
      tester,
      const SpendingImportReviewScreen(importId: _id),
      repo: repo,
    );
    expect(_t('210'), findsOneWidget);
    expect(_t('khoản chi sẵn sàng nhập'), findsOneWidget);
    expect(_t('Tổng 41.815.000 ₫'), findsOneWidget);
    expect(_t('Từ 20/03/2026 đến 12/10/2026'), findsOneWidget);
    expect(_t('Tệp Money Lover · số âm là khoản chi'), findsOneWidget);
    // Columns and options wait in "Chỉnh"; the rows left out in their own sheet.
    expect(_t('Cột trong tệp'), findsNothing);
    expect(_t('Bỏ qua 6 dòng'), findsOneWidget);
    await tester.tap(_t('Bỏ qua 6 dòng'));
    await tester.pumpAndSettle();
    expect(_t('Thiếu ngày'), findsOneWidget);
    expect(_t('Và 5 dòng khác'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Đóng').last);
    await tester.pumpAndSettle();

    // Spending is the positive rows: read again, from "Chỉnh".
    await tester.tap(find.byKey(const Key('imAdjust')));
    await tester.pumpAndSettle();
    expect(_t('Cột trong tệp'), findsOneWidget);
    await tester.tap(_t('Số dương'));
    await tester.pumpAndSettle();
    expect(repo.analyzed.single.$2?.rows, RowSign.positive);
    await tester.tap(_t('Xong'));
    await tester.pumpAndSettle();

    // "Bơi" has no match: it becomes a category of its own unless changed.
    expect(
      _t(
        '1 mục chưa có trong Chi tiêu sẽ được tạo thành danh mục mới. Chạm để đổi.',
      ),
      findsOneWidget,
    );
    expect(_t('Mới'), findsOneWidget);
    expect(_t('Vào: Tạo mới “Bơi”'), findsOneWidget);
    expect(_t('Vào: Sữa & ăn dặm'), findsOneWidget);
    await tester.tap(find.byKey(const Key('imCat-boi')));
    await tester.pumpAndSettle();
    await tester.tap(_t('Quần áo').last);
    await tester.pumpAndSettle();
    expect(_t('Vào: Quần áo'), findsOneWidget);
    expect(_t('Mới'), findsNothing);

    // Every row, 50 a page.
    await _see(tester, _t('Xem tất cả 210'));
    await tester.tap(_t('Xem tất cả 210'));
    await tester.pumpAndSettle();
    expect(_t('210 khoản sẽ nhập'), findsOneWidget);
    expect(_t('Trang 1/5'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Trang sau'));
    await tester.pumpAndSettle();
    expect(_t('Trang 2/5'), findsOneWidget);
    expect(repo.pages, [0, 1]);
    await tester.tap(find.bySemanticsLabel('Quay lại').last);
    await tester.pumpAndSettle();

    await _see(tester, _t('Sữa công thức'));
    await tester.tap(_t('Nhập 210 khoản'));
    await tester.pumpAndSettle();
    expect(repo.confirmed?.categories, {
      'sua': const ExistingCategory('c_milk'),
      'boi': const ExistingCategory('c_clothes'),
    });
    expect(visits.last.location, '/utilities/spending/import/$_id');
  });

  testWidgets('result while importing says it will mail', (tester) async {
    await _pump(
      tester,
      const SpendingImportResultScreen(importId: _id),
      status: ImportStatus.importing,
    );
    expect(_t('Đang nhập chi tiêu…'), findsOneWidget);
    expect(_t('120 / 210 khoản'), findsOneWidget);
    expect(
      _t('Bạn có thể đóng app. Child Life sẽ gửi email và thông báo khi xong.'),
      findsOneWidget,
    );
  });

  testWidgets('result when done: counts, issues, undo', (tester) async {
    final repo = _FakeImports();
    await _pump(
      tester,
      const SpendingImportResultScreen(importId: _id),
      status: ImportStatus.done,
      repo: repo,
    );
    expect(find.byKey(const Key('imDone')), findsOneWidget);
    expect(_t('Đã nhập 210 khoản'), findsWidgets);
    expect(
      _t('Bỏ qua: 3 khoản trùng, 2 khoản thu, 1 dòng lỗi.'),
      findsOneWidget,
    );
    await _see(tester, find.byKey(const Key('imUndo')));
    expect(find.textContaining('Có thể hoàn tác đến'), findsOneWidget);
    expect(
      _t('Có thể hoàn tác đến 09:00 ngày 19/10/2026 (còn 7 ngày)'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('imUndo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('imUndoConfirm')));
    await tester.pumpAndSettle();
    expect(repo.undone, [_id]);
    expect(_t('Đã xoá 210 khoản đã nhập'), findsOneWidget);
  });
}
