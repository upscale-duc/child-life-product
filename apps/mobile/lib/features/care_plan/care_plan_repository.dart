import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'care_plan_models.dart';

/// Cùng Chăm Con (D-135): read from Firestore, changed only through the plan Functions
/// (`firebase/functions/src/care-plan.ts`). Calls throw [FirebaseFunctionsException].
class CarePlanRepository {
  CarePlanRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _day(String babyId, String date) =>
      _db.doc('babies/$babyId/carePlanDays/$date');

  Stream<CarePlanDay?> watchDay(String babyId, String date) => _day(
    babyId,
    date,
  ).snapshots().map((s) => CarePlanDay.fromJson(date, s.data()));

  Stream<List<CarePlanItem>> watchItems(String babyId, String date) =>
      _day(babyId, date)
          .collection('items')
          .snapshots()
          .map(
            (s) => sortedPlan([
              for (final d in s.docs) ?CarePlanItem.fromJson(d.data()),
            ]),
          );

  DocumentReference<Map<String, dynamic>> _prefs(String uid) =>
      _db.doc('users/$uid/settings/carePlan');

  /// This person's task reminders (N1): "Nhắc trước", "Nhắc cả trong giờ yên lặng".
  Stream<CarePlanPrefs> watchPrefs(String uid) =>
      _prefs(uid).snapshots().map((s) => CarePlanPrefs.fromJson(s.data()));

  Future<void> savePrefs(String uid, CarePlanPrefs prefs) => _prefs(uid).set({
    'leadMinutes': prefs.leadMinutes,
    'quietHours': prefs.quietHours,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// 20 Lịch sử thay đổi / 11 Báo cáo: the plan's changes since [since], newest first.
  Stream<List<CarePlanChange>> watchHistory(String babyId, DateTime since) =>
      _db
          .collection('babies/$babyId/carePlanHistory')
          .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('at', descending: true)
          .limit(5000)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs) ?CarePlanChange.fromJson(d.id, d.data()),
            ],
          );

  /// How many tasks are kept "Mọi ngày" (04-0 offers to start from them).
  Stream<int> watchEverydayCount(String babyId) => _db
      .collection('babies/$babyId/carePlanTemplate')
      .snapshots()
      .map((s) => s.size);

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    final r = await _functions.httpsCallable(name).call<Object?>(data);
    final out = r.data;
    return out is Map ? out.cast<String, Object?>() : const {};
  }

  /// 04-0: `everyday`, `yesterday`, `empty`, or a draft (`rhythm`, `basic`, `easy35`, `easy4`,
  /// D-136). A day in use stays as it is; a draft started another way is replaced.
  Future<void> startDay(String babyId, String date, String from) =>
      _call('startCarePlanDay', {'babyId': babyId, 'date': date, 'from': from});

  /// 02 "Dùng lịch này": the draft becomes the family's plan.
  Future<void> publishDay(String babyId, String date) =>
      _call('publishCarePlanDay', {'babyId': babyId, 'date': date});

  /// The family's plan settings: "Tự tạo lịch mỗi sáng" and the way last used.
  Stream<CarePlanFamilySettings> watchFamilySettings(String babyId) => _db
      .doc('babies/$babyId/carePlanSettings/family')
      .snapshots()
      .map((s) => CarePlanFamilySettings.fromJson(s.data()));

  Future<void> setAutoDraft(String babyId, {required bool on}) =>
      _call('setCarePlanAutoDraft', {'babyId': babyId, 'on': on});

  /// 06 / 06b: create or edit [itemId]; [everyDay] also keeps it for the days to come.
  Future<void> saveItem(
    String babyId,
    String date, {
    required String itemId,
    required CarePlanTask task,
    required String? title,
    required String time,
    required List<String> assignees,
    required bool everyDay,
    int? amountMl,
  }) => _call('saveCarePlanItem', {
    'babyId': babyId,
    'date': date,
    'itemId': itemId,
    'task': task.name,
    'title': task == CarePlanTask.custom ? title : null,
    'time': time,
    'assignees': assignees,
    'scope': everyDay ? 'everyDay' : 'today',
    if (carePlanAmountTasks.contains(task)) 'amountMl': amountMl,
  });

  Future<void> deleteItem(
    String babyId,
    String date,
    String itemId, {
    required bool everyDay,
  }) => _call('deleteCarePlanItem', {
    'babyId': babyId,
    'date': date,
    'itemId': itemId,
    'scope': everyDay ? 'everyDay' : 'today',
  });

  /// 05: the same people on [itemIds] (one task, or "Giao cả ca"); empty = nobody.
  Future<void> assign(
    String babyId,
    String date,
    List<String> itemIds,
    List<String> assignees,
  ) => _call('assignCarePlanItems', {
    'babyId': babyId,
    'date': date,
    'itemIds': itemIds,
    'assignees': assignees,
  });

  Future<void> setStatus(
    String babyId,
    String date,
    String itemId,
    CarePlanStatus status,
  ) => _call('setCarePlanItemStatus', {
    'babyId': babyId,
    'date': date,
    'itemId': itemId,
    'status': status.name,
  });
}

final carePlanRepositoryProvider = Provider<CarePlanRepository>(
  (ref) => CarePlanRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

typedef CarePlanKey = (String babyId, String date);

final carePlanDayProvider = StreamProvider.family<CarePlanDay?, CarePlanKey>(
  (ref, k) => ref.watch(carePlanRepositoryProvider).watchDay(k.$1, k.$2),
);

final carePlanItemsProvider =
    StreamProvider.family<List<CarePlanItem>, CarePlanKey>(
      (ref, k) => ref.watch(carePlanRepositoryProvider).watchItems(k.$1, k.$2),
    );

/// The day's tasks in use: none while the day is a draft (D-136), so Hôm nay, the helper's
/// shift and "Đến giờ rồi" never show a draft as something to do.
final carePlanLiveItemsProvider =
    Provider.family<AsyncValue<List<CarePlanItem>>, CarePlanKey>(
      (ref, k) => ref
          .watch(carePlanItemsProvider(k))
          .whenData(
            (items) => [
              for (final i in items)
                if (!i.draft) i,
            ],
          ),
    );

final carePlanFamilySettingsProvider =
    StreamProvider.family<CarePlanFamilySettings, String>(
      (ref, babyId) =>
          ref.watch(carePlanRepositoryProvider).watchFamilySettings(babyId),
    );

typedef CarePlanSince = (String babyId, DateTime since);

final carePlanHistoryProvider =
    StreamProvider.family<List<CarePlanChange>, CarePlanSince>(
      (ref, k) =>
          ref.watch(carePlanRepositoryProvider).watchHistory(k.$1, k.$2),
    );

final carePlanEverydayCountProvider = StreamProvider.family<int, String>(
  (ref, babyId) =>
      ref.watch(carePlanRepositoryProvider).watchEverydayCount(babyId),
);

/// The ring answers at once: a status this phone set, until the server's copy agrees (or the
/// call fails and the toast says so).
class CarePlanPendingStatus extends Notifier<Map<String, CarePlanStatus>> {
  @override
  Map<String, CarePlanStatus> build() => const {};

  void set(String itemId, CarePlanStatus status) =>
      state = {...state, itemId: status};

  void clear(String itemId) => state = {...state}..remove(itemId);
}

final carePlanPendingProvider =
    NotifierProvider<CarePlanPendingStatus, Map<String, CarePlanStatus>>(
      CarePlanPendingStatus.new,
    );

final carePlanPrefsProvider = StreamProvider.family<CarePlanPrefs, String>(
  (ref, uid) => ref.watch(carePlanRepositoryProvider).watchPrefs(uid),
);
