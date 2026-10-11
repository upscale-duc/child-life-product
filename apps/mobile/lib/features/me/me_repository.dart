import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../baby/baby_models.dart';
import '../memories/memory_repository.dart';
import 'me_models.dart';

/// Me, storage, profiles and the account (S11). Sensitive changes go through callables (zod on
/// the server); notification settings and device rows are the account's own documents.
class MeRepository {
  MeRepository(this._db, this._functions, this._storage, {this.locale = 'vi'});

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  /// Language for service mail (storage request, help, deletion).
  String locale;

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>({
        ...data,
        'locale': locale,
      });
      final v = r.data;
      return v is Map ? v.cast<String, Object?>() : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      throw AccountActionException(reason ?? e.code);
    }
  }

  // ---------- Storage (13b–13e) ----------

  Future<FamilyStorage> familyStorage(String babyId) async =>
      FamilyStorage.fromJson(
        await _call('getFamilyStorage', {'babyId': babyId}),
      );

  Future<void> requestStorage(String babyId, int amountGb, String message) =>
      _call('requestMoreStorage', {
        'requestId': const Uuid().v4(),
        'babyId': babyId,
        'amountGb': amountGb,
        if (message.trim().isNotEmpty) 'message': message.trim(),
      });

  // ---------- Baby profile (13k, 13l) ----------

  Future<void> updateBaby(String babyId, Map<String, Object?> change) =>
      _call('updateBabyProfileInfo', {'babyId': babyId, ...change});

  Future<String> deleteBaby(String babyId, String typed) async =>
      (await _call('deleteBabyProfile', {
            'babyId': babyId,
            'confirmNickname': typed,
          }))['jobId']!
          as String;

  Stream<DeletionJob?> watchDeletionJob(String jobId) => _db
      .doc('deletionJobs/$jobId')
      .snapshots()
      .map((d) => d.exists ? DeletionJob.fromDoc(d) : null);

  // ---------- Your profile (13m) ----------

  Future<void> updateProfile({
    String? displayName,
    List<({String babyId, Relation relation, String? custom})> relations =
        const [],
  }) => _call('updateMyProfileInfo', {
    'displayName': ?displayName,
    if (relations.isNotEmpty)
      'relations': [
        for (final r in relations)
          {
            'babyId': r.babyId,
            'relation': r.relation.name,
            'relationCustom': r.relation == Relation.other ? r.custom : null,
          },
      ],
  });

  // ---------- Account (13n) ----------

  Stream<AccountDoc> watchAccount(String uid) => _db
      .doc('users/$uid')
      .snapshots()
      .map((d) => AccountDoc.fromMap(d.data()));

  Future<void> offerOwnership(String toUid) =>
      _call('offerFamilyOwnership', {'toUid': toUid});

  Future<String> answerOwnership(String familyId, String answer) async =>
      (await _call('answerFamilyOwnership', {
            'familyId': familyId,
            'answer': answer,
          }))['state']
          as String? ??
      '';

  /// Family whose transfer I offered (owner side), from the family document.
  Stream<String?> watchOfferedTo(String familyId) => _db
      .doc('families/$familyId')
      .snapshots()
      .map((d) => d.data()?['transfer']?['toUid'] as String?);

  Future<String> deleteAccount() async =>
      (await _call('deleteMyAccount', {'confirm': true}))['jobId']! as String;

  Stream<List<SignedInDevice>> watchDevices(String uid) => _db
      .collection('users/$uid/devices')
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map(SignedInDevice.fromDoc)
                .where((d) => !d.signedOut)
                .toList()
              ..sort(
                (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
                  a.updatedAt ?? DateTime(2000),
                ),
              ),
      );

  Future<void> signOutDevice(String deviceId) =>
      _call('signOutMyDevice', {'deviceId': deviceId});

  // ---------- Notifications (G-056) ----------

  Stream<NotificationPrefs> watchPrefs(String uid) => _db
      .doc('users/$uid/settings/notifications')
      .snapshots()
      .map((d) => NotificationPrefs.fromMap(d.data()));

  Future<void> savePrefs(String uid, NotificationPrefs prefs) => _db
      .doc('users/$uid/settings/notifications')
      .set({...prefs.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  // ---------- Export (R-187) ----------

  Future<String> requestExport(String babyId, ExportKind kind) async =>
      (await _call('requestDataExport', {
            'requestId': const Uuid().v4(),
            'babyId': babyId,
            'kind': kind.name,
          }))['jobId']!
          as String;

  Stream<List<ExportJob>> watchExports(String uid) => _db
      .collection('dataJobs')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(ExportJob.fromDoc).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// Downloads a ready export to a temporary file (Storage Rules re-check the right, R-187).
  Future<File> downloadExport(ExportJob job) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${job.path!.split('/').last}');
    await _storage.ref(job.path).writeToFile(file);
    return file;
  }

  // ---------- Help (G-057) ----------

  Future<String> sendHelp(
    HelpCategory category,
    String message,
    Map<String, Object?>? diagnostics,
  ) async =>
      (await _call('createHelpTicket', {
            'requestId': const Uuid().v4(),
            'category': category.name,
            'message': message.trim(),
            'diagnostics': diagnostics,
          }))['ticket']!
          as String;
}

final meRepositoryProvider = Provider<MeRepository>(
  (ref) => MeRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
    FirebaseStorage.instance,
  ),
);

/// 13b for the selected baby's family; refreshed on pull, after a request, and whenever the
/// baby's media change (an upload lands or a photo is deleted): the callable sums the bytes, and
/// the Me tab stays alive in the shell, so it would otherwise keep its first answer.
final familyStorageProvider = FutureProvider.autoDispose
    .family<FamilyStorage, String>((ref, babyId) {
      ref.listen(_mediaSignatureProvider(babyId), (previous, next) {
        if (previous != null && next != previous) ref.invalidateSelf();
      });
      return ref.watch(meRepositoryProvider).familyStorage(babyId);
    });

/// Changes when the baby's media set or any item's state changes; null until known, and for
/// members who cannot read the parents' media (they do not see storage).
final _mediaSignatureProvider = Provider.autoDispose.family<int?, String>((
  ref,
  babyId,
) {
  final session = ref.watch(sessionProvider);
  final parent =
      session is SessionSignedIn &&
      session.membershipFor(babyId)?.role == MemberRole.coParent;
  if (!parent) return null;
  final items = ref.watch(mediaProvider((babyId, true))).value;
  return items == null
      ? null
      : Object.hashAll(items.map((m) => (m.id, m.status)));
});

final accountDocProvider = StreamProvider.family<AccountDoc, String>(
  (ref, uid) => ref.watch(meRepositoryProvider).watchAccount(uid),
);

final devicesProvider = StreamProvider.family<List<SignedInDevice>, String>(
  (ref, uid) => ref.watch(meRepositoryProvider).watchDevices(uid),
);

final notificationPrefsProvider =
    StreamProvider.family<NotificationPrefs, String>(
      (ref, uid) => ref.watch(meRepositoryProvider).watchPrefs(uid),
    );

final exportsProvider = StreamProvider.family<List<ExportJob>, String>(
  (ref, uid) => ref.watch(meRepositoryProvider).watchExports(uid),
);

final deletionJobProvider = StreamProvider.family<DeletionJob?, String>(
  (ref, jobId) => ref.watch(meRepositoryProvider).watchDeletionJob(jobId),
);

final offeredToProvider = StreamProvider.family<String?, String>(
  (ref, familyId) => ref.watch(meRepositoryProvider).watchOfferedTo(familyId),
);
