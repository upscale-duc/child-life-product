import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../baby/baby_models.dart';
import 'vaccine_models.dart';

/// Sổ tiêm chủng (P-133). Like care records, writes go straight to Firestore (Rules check the
/// shape, `firebase/firestore.rules`), so the local cache is the offline outbox; a shot recorded
/// at the clinic without signal syncs later. Failures surface through `onError`.
class VaccineRepository {
  VaccineRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String babyId) =>
      _db.collection('babies/$babyId/vaccines');

  DocumentReference<Map<String, dynamic>> _plan(String babyId) =>
      _db.doc('babies/$babyId/vaccinePlan/main');

  Stream<Map<String, VaccineDoseRecord>> watch(String babyId) =>
      _col(babyId).snapshots(includeMetadataChanges: true).map((s) {
        final out = <String, VaccineDoseRecord>{};
        for (final d in s.docs) {
          final r = VaccineDoseRecord.fromSnapshot(d);
          if (r != null) out[r.key] = r;
        }
        return out;
      });

  Stream<VaccinePlan> watchPlan(String babyId) =>
      _plan(babyId).snapshots().map((s) => VaccinePlan.fromJson(s.data()));

  void _run(Future<void> write, void Function(Object error)? onError) =>
      write.catchError((Object e) => onError?.call(e));

  Map<String, Object?> _author(Membership me) => {
    'name': me.displayName,
    'relation': me.relation.name,
    'relationCustom': me.relationCustom,
  };

  /// Records a dose as given, declined or rescheduled. Creating keeps who first recorded it;
  /// editing (the same key) keeps it too.
  void save({
    required String babyId,
    required Membership me,
    required DoseItem item,
    required DoseRecordStatus status,
    DateTime? givenOn,
    String? givenTime,
    VaccinePlace? place,
    String? facility,
    String? reaction,
    String? declineReason,
    DateTime? plannedOn,
    String? photoPath,
    void Function(Object error)? onError,
  }) {
    final fields = <String, Object?>{
      'status': status.name,
      'givenOn': status == DoseRecordStatus.given && givenOn != null
          ? dayWire(givenOn)
          : null,
      'givenTime': status == DoseRecordStatus.given ? givenTime : null,
      'place': status == DoseRecordStatus.given ? place?.name : null,
      'facility': status == DoseRecordStatus.given ? _clean(facility) : null,
      'reaction': status == DoseRecordStatus.given ? _clean(reaction) : null,
      'declineReason': status == DoseRecordStatus.declined
          ? _clean(declineReason)
          : null,
      'plannedOn': status == DoseRecordStatus.planned && plannedOn != null
          ? dayWire(plannedOn)
          : null,
      'photoPath': status == DoseRecordStatus.given
          ? (photoPath ?? item.record?.photoPath)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': me.uid,
    };
    final ref = _col(babyId).doc(item.key);
    if (item.record == null) {
      _run(
        ref.set({
          'babyId': babyId,
          'vaccineId': item.def.id,
          'dose': item.dose,
          ...fields,
          'createdBy': me.uid,
          'author': _author(me),
          'createdAt': FieldValue.serverTimestamp(),
        }),
        onError,
      );
    } else {
      _run(ref.update(fields), onError);
    }
  }

  /// VX 0 "Lưu N mũi đã tiêm": every ticked dose, date unknown; the setup is then done.
  void saveSetup({
    required String babyId,
    required Membership me,
    required List<DoseItem> items,
    required VaccinePlan plan,
    void Function(Object error)? onError,
  }) {
    final batch = _db.batch();
    for (final item in items) {
      batch.set(_col(babyId).doc(item.key), {
        'babyId': babyId,
        'vaccineId': item.def.id,
        'dose': item.dose,
        'status': DoseRecordStatus.given.name,
        'givenOn': null,
        'givenTime': null,
        'place': null,
        'facility': null,
        'reaction': null,
        'declineReason': null,
        'plannedOn': null,
        'photoPath': null,
        'createdBy': me.uid,
        'author': _author(me),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': me.uid,
      });
    }
    batch.set(_plan(babyId), _planJson(plan.copyWith(setupDone: true), me));
    _run(batch.commit(), onError);
  }

  /// "Xoá mũi tiêm này" / undoing "Không tiêm" or "Dời lịch": the dose is open again.
  void delete(
    String babyId,
    DoseItem item, {
    void Function(Object error)? onError,
  }) => _run(_col(babyId).doc(item.key).delete(), onError);

  void savePlan(
    String babyId,
    Membership me,
    VaccinePlan plan, {
    void Function(Object error)? onError,
  }) => _run(_plan(babyId).set(_planJson(plan, me)), onError);

  Map<String, Object?> _planJson(VaccinePlan p, Membership me) => {
    'dtp': p.dtp?.wire,
    'setupDone': p.setupDone,
    'scheduleFrom': p.scheduleFrom == null ? null : dayWire(p.scheduleFrom!),
    'remind': p.remind,
    'recipients': p.recipients,
    'bookPhotos': p.bookPhotos,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': me.uid,
  };

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

final vaccineRepositoryProvider = Provider<VaccineRepository>(
  (ref) => VaccineRepository(ref.watch(firestoreProvider)),
);

final vaccineDosesProvider =
    StreamProvider.family<Map<String, VaccineDoseRecord>, String>(
      (ref, babyId) => ref.watch(vaccineRepositoryProvider).watch(babyId),
    );

final vaccinePlanProvider = StreamProvider.family<VaccinePlan, String>(
  (ref, babyId) => ref.watch(vaccineRepositoryProvider).watchPlan(babyId),
);
