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
  testWidgets('Chi tiêu offers "Nhập" to Cùng nuôi', (tester) async {
    await _pump(tester, const SpendingScreen());
    expect(find.byKey(const Key('spImport')), findsOneWidget);
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
    expect(_t('Sẽ nhập 210 khoản'), findsOneWidget);
    expect(
      _t('216 dòng · 3 khoản trùng · 2 khoản thu · 1 dòng lỗi'),
      findsOneWidget,
    );
    expect(_t('money-lover-2026.csv · Nhận dạng: Money Lover'), findsOneWidget);
    expect(_t('Date'), findsOneWidget);

    // Spending is the positive rows: read again.
    await _see(tester, _t('Số dương'));
    await tester.tap(_t('Số dương'));
    await tester.pumpAndSettle();
    expect(repo.analyzed.single.$2?.rows, RowSign.positive);

    // "Bơi" has no match: it goes to a new category.
    await _see(tester, find.byKey(const Key('imCat-boi')));
    expect(_t('Vào: Sữa & ăn dặm'), findsOneWidget);
    expect(_t('Vào: Khác'), findsOneWidget);
    await tester.tap(find.byKey(const Key('imCat-boi')));
    await tester.pumpAndSettle();
    await tester.tap(_t('Tạo mới “Bơi”').last);
    await tester.pumpAndSettle();
    expect(_t('Vào: Tạo mới “Bơi”'), findsOneWidget);

    await _see(tester, _t('Thiếu ngày'));
    await tester.tap(_t('Nhập 210 khoản'));
    await tester.pumpAndSettle();
    expect(repo.confirmed?.categories, {
      'sua': const ExistingCategory('c_milk'),
      'boi': const NewCategory('Bơi'),
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
    await tester.tap(find.byKey(const Key('imUndo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('imUndoConfirm')));
    await tester.pumpAndSettle();
    expect(repo.undone, [_id]);
    expect(_t('Đã xoá 210 khoản đã nhập'), findsOneWidget);
  });
}
