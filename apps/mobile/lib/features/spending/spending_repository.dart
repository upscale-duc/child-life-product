import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import 'spending_currency.dart';
import 'spending_models.dart';

/// Chi tiêu (P-140). Like care records, expenses, the budget, recurring items and categories are
/// written straight to Firestore (Rules check the shape, `firebase/firestore.rules`), so the local
/// cache is the offline outbox. Deleting a category moves expenses across babies, so it is a
/// callable. Amounts and descriptions are never logged.
class SpendingRepository {
  SpendingRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _expenses(String babyId) =>
      _db.collection('babies/$babyId/expenses');

  CollectionReference<Map<String, dynamic>> _recurring(String babyId) =>
      _db.collection('babies/$babyId/recurringExpenses');

  CollectionReference<Map<String, dynamic>> _categories(String familyId) =>
      _db.collection('families/$familyId/spendingCategories');

  DocumentReference<Map<String, dynamic>> _budget(String babyId) =>
      _db.doc('babies/$babyId/spending/budget');

  DocumentReference<Map<String, dynamic>> _settings(String familyId) =>
      _db.doc('families/$familyId/spendingSettings/main');

  /// Every live expense the caller may read, newest first: all of them with "Xem toàn bộ" (or
  /// Cùng nuôi), otherwise only their own (Rules refuse a wider query).
  Stream<List<Expense>> watchExpenses(String babyId, SpendingAccess access) {
    Query<Map<String, dynamic>> q = _expenses(babyId);
    if (!access.viewAll) q = q.where('createdBy', isEqualTo: access.uid);
    return q.snapshots(includeMetadataChanges: true).map((s) {
      final out = [
        for (final d in s.docs)
          if (Expense.fromSnapshot(d) case final e? when !e.deleted) e,
      ];
      out.sort(compareExpenses);
      return out;
    });
  }

  Stream<List<SpendingCategory>> watchCategories(String familyId) =>
      _categories(familyId).snapshots().map(
        (s) => mergeCategories([
          for (final d in s.docs) ?SpendingCategory.fromSnapshot(d),
        ]),
      );

  Stream<Budget> watchBudget(String babyId) =>
      _budget(babyId).snapshots().map((s) => Budget.fromJson(s.data()));

  /// The household's currency (D-075 #4).
  Stream<SpendingSettings> watchSettings(String familyId) => _settings(
    familyId,
  ).snapshots().map((s) => SpendingSettings.fromJson(s.data()));

  /// "Tiền tệ chính" (8h, Cùng nuôi): the add form's default and new budgets' currency.
  void saveCurrency(
    String familyId,
    Membership me,
    String currency, {
    void Function(Object error)? onError,
  }) => _run(
    _settings(familyId).set({
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    }),
    onError,
  );

  Stream<List<RecurringExpense>> watchRecurring(String babyId) =>
      _recurring(babyId).snapshots().map((s) {
        final out = [for (final d in s.docs) ?RecurringExpense.fromSnapshot(d)];
        out.sort((a, b) => a.title.compareTo(b.title));
        return out;
      });

  void _run(Future<void> write, void Function(Object error)? onError) =>
      write.catchError((Object e) => onError?.call(e));

  Map<String, Object?> _author(Membership me) => {
    'name': me.displayName,
    'relation': me.relation.name,
    'relationCustom': me.relationCustom,
  };

  /// 8c "Lưu khoản chi" (new) or 8g "Sửa" (an existing [id]). A vaccine cost (8k) passes
  /// [doseKey]. Returns the expense id.
  String saveExpense({
    required String babyId,
    required Membership me,
    String? id,
    required int amount,
    String currency = legacyCurrency,
    required String categoryId,
    required String note,
    required DateTime spentOn,
    required Payer? payer,
    String? receiptPath,
    String? doseKey,
    void Function(Object error)? onError,
  }) {
    final fields = <String, Object?>{
      'amount': amount,
      // D-075 #4: always written by this app (Rules: optional, absent = VND).
      'currency': currency,
      'categoryId': categoryId,
      'note': note.trim(),
      'spentOn': isoDay(spentOn),
      'payer': payer?.toJson(),
      'receiptPath': receiptPath,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    };
    if (id != null) {
      _run(_expenses(babyId).doc(id).update(fields), onError);
      return id;
    }
    final newId = newExpenseId();
    _run(
      _expenses(babyId).doc(newId).set({
        ...fields,
        'source': doseKey == null
            ? ExpenseSource.manual.name
            : ExpenseSource.vaccine.name,
        'sourceRef': doseKey,
        'createdBy': me.uid,
        'author': _author(me),
        'createdAt': FieldValue.serverTimestamp(),
        'deleted': false,
        'deletedAt': null,
        'deletedBy': null,
      }),
      onError,
    );
    return newId;
  }

  /// 8g "Xoá khoản chi" (soft, so "Hoàn tác" can bring it back).
  void deleteExpense(
    String babyId,
    String id,
    Membership me, {
    bool undo = false,
    void Function(Object error)? onError,
  }) => _run(
    _expenses(babyId).doc(id).update({
      'deleted': !undo,
      'deletedAt': undo ? null : FieldValue.serverTimestamp(),
      'deletedBy': undo ? null : me.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    }),
    onError,
  );

  /// 8h "Lưu ngân sách".
  void saveBudget(
    String babyId,
    Membership me,
    Budget budget, {
    void Function(Object error)? onError,
  }) => _run(
    _budget(babyId).set({
      ...budget.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    }, SetOptions(merge: true)),
    onError,
  );

  /// 8i add / edit. A null [id] creates one.
  void saveRecurring({
    required String babyId,
    required Membership me,
    String? id,
    required String title,
    required String categoryId,
    required int amount,
    String currency = legacyCurrency,
    required Payer? payer,
    required RecurringSchedule schedule,
    required bool enabled,

    /// 8c "Lặp lại hằng tháng": that day's expense is already saved, so the daily job starts after.
    DateTime? recordedOn,
    void Function(Object error)? onError,
  }) {
    final fields = <String, Object?>{
      'title': title.trim(),
      'categoryId': categoryId,
      'amount': amount,
      'currency': currency,
      'payer': payer?.toJson(),
      'schedule': schedule.toJson(),
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    };
    if (id != null) {
      _run(_recurring(babyId).doc(id).update(fields), onError);
      return;
    }
    _run(
      _recurring(babyId).doc(newRecurringId()).set({
        ...fields,
        'createdBy': me.uid,
        'author': _author(me),
        'createdAt': FieldValue.serverTimestamp(),
        if (recordedOn != null) 'lastOn': isoDay(recordedOn),
      }),
      onError,
    );
  }

  void setRecurringEnabled(
    String babyId,
    String id,
    Membership me,
    bool enabled, {
    void Function(Object error)? onError,
  }) => _run(
    _recurring(babyId).doc(id).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    }),
    onError,
  );

  void deleteRecurring(
    String babyId,
    String id, {
    void Function(Object error)? onError,
  }) => _run(_recurring(babyId).doc(id).delete(), onError);

  /// 8m / 8n: writes [categories] (a built-in not stored yet is seeded with its fixed id).
  void saveCategories(
    String familyId,
    Membership me,
    List<SpendingCategory> categories, {
    void Function(Object error)? onError,
  }) {
    final batch = _db.batch();
    for (final c in categories) {
      batch.set(_categories(familyId).doc(c.id), {
        ...c.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': me.uid,
      });
    }
    _run(batch.commit(), onError);
  }

  /// 8o "Xoá danh mục": expenses, recurring items and the cap move to [moveTo] (every baby of the
  /// family). Online only.
  Future<void> deleteCategory({
    required String babyId,
    required String categoryId,
    required String moveTo,
  }) => _functions.httpsCallable('deleteSpendingCategory').call<Object?>({
    'babyId': babyId,
    'categoryId': categoryId,
    'moveTo': moveTo,
  });
}

/// Newest day first; within a day, the latest recorded first.
int compareExpenses(Expense a, Expense b) {
  final byDay = b.spentOn.compareTo(a.spentOn);
  if (byDay != 0) return byDay;
  final at = a.createdAt, bt = b.createdAt;
  if (at == null || bt == null) return at == null ? (bt == null ? 0 : -1) : 1;
  return bt.compareTo(at);
}

final spendingRepositoryProvider = Provider<SpendingRepository>(
  (ref) => SpendingRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// Keyed by the membership so a change of rights re-queries.
final expensesProvider =
    StreamProvider.family<List<Expense>, (String, SpendingAccess)>(
      (ref, key) =>
          ref.watch(spendingRepositoryProvider).watchExpenses(key.$1, key.$2),
    );

final spendingCategoriesProvider =
    StreamProvider.family<List<SpendingCategory>, String>(
      (ref, familyId) =>
          ref.watch(spendingRepositoryProvider).watchCategories(familyId),
    );

final budgetProvider = StreamProvider.family<Budget, String>(
  (ref, babyId) => ref.watch(spendingRepositoryProvider).watchBudget(babyId),
);

/// `families/{familyId}/spendingSettings/main` (D-075 #4).
final spendingSettingsProvider =
    StreamProvider.family<SpendingSettings, String>(
      (ref, familyId) =>
          ref.watch(spendingRepositoryProvider).watchSettings(familyId),
    );

final recurringExpensesProvider =
    StreamProvider.family<List<RecurringExpense>, String>(
      (ref, babyId) =>
          ref.watch(spendingRepositoryProvider).watchRecurring(babyId),
    );
