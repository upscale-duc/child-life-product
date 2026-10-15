import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/spending/import/import_repository.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/features/spending/spending_repository.dart';

/// Chi tiêu without Firestore: records what the screens write.
class FakeSpendingRepository implements SpendingRepository {
  final expenses =
      <
        ({
          String? id,
          int amount,
          String currency,
          String categoryId,
          String note,
          DateTime spentOn,
          Payer? payer,
          String? receiptPath,
          String? doseKey,
        })
      >[];
  final deleted = <(String id, bool undo)>[];
  final budgets = <Budget>[];
  final recurring =
      <
        ({
          String? id,
          String title,
          int amount,
          String currency,
          RecurringSchedule schedule,
          bool enabled,
          DateTime? recordedOn,
        })
      >[];
  final categories = <List<SpendingCategory>>[];
  final deletedCategories = <(String categoryId, String moveTo)>[];

  /// "Tiền tệ chính" writes (D-075 #4).
  final currencies = <String>[];

  @override
  String saveExpense({
    required String babyId,
    required Membership me,
    String? id,
    required int amount,
    String currency = 'VND',
    required String categoryId,
    required String note,
    required DateTime spentOn,
    required Payer? payer,
    String? receiptPath,
    String? doseKey,
    void Function(Object error)? onError,
  }) {
    expenses.add((
      id: id,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      note: note,
      spentOn: spentOn,
      payer: payer,
      receiptPath: receiptPath,
      doseKey: doseKey,
    ));
    return id ?? newExpenseId();
  }

  @override
  void deleteExpense(
    String babyId,
    String id,
    Membership me, {
    bool undo = false,
    void Function(Object error)? onError,
  }) => deleted.add((id, undo));

  @override
  void saveBudget(
    String babyId,
    Membership me,
    Budget budget, {
    void Function(Object error)? onError,
  }) => budgets.add(budget);

  @override
  void saveRecurring({
    required String babyId,
    required Membership me,
    String? id,
    required String title,
    required String categoryId,
    required int amount,
    String currency = 'VND',
    required Payer? payer,
    required RecurringSchedule schedule,
    required bool enabled,
    DateTime? recordedOn,
    void Function(Object error)? onError,
  }) => recurring.add((
    id: id,
    title: title,
    amount: amount,
    currency: currency,
    schedule: schedule,
    enabled: enabled,
    recordedOn: recordedOn,
  ));

  @override
  void saveCurrency(
    String familyId,
    Membership me,
    String currency, {
    void Function(Object error)? onError,
  }) => currencies.add(currency);

  @override
  void saveCategories(
    String familyId,
    Membership me,
    List<SpendingCategory> categories, {
    void Function(Object error)? onError,
  }) => this.categories.add(categories);

  @override
  Future<void> deleteCategory({
    required String babyId,
    required String categoryId,
    required String moveTo,
  }) async => deletedCategories.add((categoryId, moveTo));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _mom = CareAuthor(name: 'Mai', relation: Relation.mother);
const _dad = CareAuthor(name: 'Minh', relation: Relation.father);

Expense spend(
  String id,
  int amount,
  String categoryId,
  DateTime day, {
  String note = '',
  String createdBy = 'u_mai',
  CareAuthor author = _mom,
  Payer? payer,
  bool noPayer = false,
  String? receipt,
  ExpenseSource source = ExpenseSource.manual,
  String? sourceRef,
  String currency = 'VND',
}) => Expense(
  id: 'x_${id.padLeft(32, '0')}',
  babyId: 'b_00000000000000000001',
  amount: amount,
  currency: currency,
  categoryId: categoryId,
  note: note,
  spentOn: day,
  payer: noPayer ? null : (payer ?? const Payer(uid: 'u_mai', author: _mom)),
  source: source,
  sourceRef: sourceRef,
  receiptPath: receipt,
  createdBy: createdBy,
  author: author,
  createdAt: DateTime(day.year, day.month, day.day, 10, 24),
);

const dadPays = Payer(uid: 'u_minh', author: _dad);

/// October 2026 as drawn in 8b / 8f (4.215.000 ₫), plus a September and an older month.
List<Expense> mockSpending() => [
  spend(
    '1',
    1020000,
    'c_milk',
    DateTime(2026, 10, 12),
    note: 'Sữa công thức ×2',
    receipt: 'babies/b_00000000000000000001/expenses/r1aaaaaaaa.jpg',
  ),
  spend(
    '2',
    285000,
    'c_diaper',
    DateTime(2026, 10, 11),
    note: 'Tã dán size M',
    payer: dadPays,
  ),
  spend(
    '3',
    160000,
    'c_clothes',
    DateTime(2026, 10, 11),
    note: 'Bộ body cotton',
  ),
  spend(
    '4',
    395000,
    'c_health',
    DateTime(2026, 10, 9),
    note: 'Mũi 6 trong 1 · lần 2',
    source: ExpenseSource.vaccine,
    sourceRef: 'dtp_2',
    receipt: 'babies/b_00000000000000000001/expenses/r2aaaaaaaa.jpg',
  ),
  spend('5', 255000, 'c_diaper', DateTime(2026, 10, 5), note: 'Khăn ướt ×6'),
  spend(
    '6',
    100000,
    'c_milk',
    DateTime(2026, 10, 5),
    note: 'Bột ăn dặm vị bí đỏ',
    noPayer: true,
  ),
  spend(
    '7',
    2000000,
    'c_childcare',
    DateTime(2026, 10, 1),
    note: 'Cô giữ trẻ · nửa đầu tháng',
    payer: dadPays,
    source: ExpenseSource.recurring,
    sourceRef: 'rx_1',
  ),
  spend(
    '8',
    3500000,
    'c_childcare',
    DateTime(2026, 9, 1),
    note: 'Cô giữ trẻ · tháng 9',
  ),
  spend('9', 1100000, 'c_milk', DateTime(2026, 9, 8), note: 'Sữa công thức'),
  spend(
    '10',
    6200000,
    'c_other',
    DateTime(2026, 3, 20),
    note: 'Xe đẩy & nôi',
    payer: dadPays,
  ),
];

const swimCategory = SpendingCategory(
  id: 'c_0123456789abcdef0123',
  name: 'Bơi & vận động',
  icon: ClIcons.journal,
  tint: CategoryTint.sunshine,
  order: 5,
);

const mockBudget = Budget(
  monthlyTotal: 8000000,
  caps: {
    'c_childcare': 4000000,
    'c_milk': 2200000,
    'c_diaper': 1000000,
    'c_health': 400000,
  },
);

final mockRecurring = [
  RecurringExpense(
    id: 'rx_1',
    title: 'Cô giữ trẻ',
    categoryId: 'c_childcare',
    amount: 2000000,
    payer: dadPays,
    schedule: const Monthly([1, 16]),
    enabled: true,
    createdBy: 'u_mai',
    author: _mom,
  ),
  RecurringExpense(
    id: 'rx_2',
    title: 'Bảo hiểm sức khoẻ của bé',
    categoryId: 'c_health',
    amount: 1800000,
    payer: null,
    schedule: const Yearly(month: 3, day: 5),
    enabled: false,
    createdBy: 'u_mai',
    author: _mom,
  ),
];

const mockImportId = 'im_0123456789abcdef0123456789abcdef';

/// Nhập chi tiêu (D-060): a Money Lover file of 216 rows.
SpendingImport mockImport(ImportStatus status) => SpendingImport(
  id: mockImportId,
  kind: ImportKind.file,
  status: status,
  fileName: 'money-lover-2026.csv',
  preset: 'Money Lover',
  columns: const ['Id', 'Date', 'Category', 'Amount', 'Currency', 'Note'],
  mapping: const ImportMapping(
    firstRow: 1,
    date: 1,
    amount: 3,
    note: [5],
    category: 2,
  ),
  options: const ImportOptions(rows: RowSign.negative),
  mixedSigns: true,
  ambiguousDates: false,
  counts: const ImportCounts(
    rows: 216,
    ready: 210,
    duplicates: 3,
    income: 2,
    errors: 1,
  ),
  preview: const [
    ImportPreviewRow(
      row: 2,
      spentOn: '2026-10-12',
      amount: 1020000,
      note: 'Sữa công thức',
      category: 'Sữa',
      payer: '',
      issue: null,
    ),
  ],
  skipped: const [
    ImportPreviewRow(
      row: 3,
      spentOn: null,
      amount: 50000,
      note: 'Bánh',
      category: 'Ăn uống',
      payer: '',
      issue: ImportIssue.noDate,
    ),
  ],
  total: (amount: 41815000, from: '2026-03-20', to: '2026-10-12'),
  categories: const [
    SourceName(
      key: 'sua',
      name: 'Sữa',
      rows: 64,
      suggested: ExistingCategory('c_milk'),
    ),
    SourceName(key: 'boi', name: 'Bơi', rows: 4, suggested: NewCategory('Bơi')),
  ],
  payers: const [],
  progress: status == ImportStatus.importing ? 57 : 0,
  imported: switch (status) {
    ImportStatus.importing => 120,
    ImportStatus.done => 210,
    _ => 0,
  },
  issues: const [(3, ImportIssue.noDate)],
  failure: null,
  createdBy: 'u_mai',
  createdAt: DateTime(2026, 10, 12, 9),
  finishedAt: null,
  undoUntil: status == ImportStatus.done ? DateTime(2026, 10, 19, 9) : null,
);
