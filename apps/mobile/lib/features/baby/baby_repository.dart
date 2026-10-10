import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'baby_models.dart';

/// Server error reasons from `createBabyProfile` / `setBabyAvatarImage` (firebase/functions).
enum BabyFailure { babyLimit, dobInFuture, network, other }

class BabyException implements Exception {
  const BabyException(this.failure);
  final BabyFailure failure;
}

BabyFailure _failureOf(FirebaseFunctionsException e) {
  final details = e.details;
  final reason = details is Map ? details['reason'] : null;
  return switch (reason) {
    'baby-limit' => BabyFailure.babyLimit,
    'dob-in-future' => BabyFailure.dobInFuture,
    _ => switch (e.code) {
      'unavailable' || 'deadline-exceeded' => BabyFailure.network,
      _ => BabyFailure.other,
    },
  };
}

class BabyRepository {
  BabyRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Profile photos are fetched through a member-checked callable (Storage stays closed to
  /// clients) and kept in memory for this session, keyed by version.
  final _avatarCache = <String, Uint8List>{};

  /// Every membership of [uid] (any status) — "my babies" (Rules: own uid only).
  Stream<List<Membership>> watchMemberships(String uid) => _db
      .collectionGroup('members')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) Membership.fromJson(d.data())]);

  Stream<Baby?> watchBaby(String babyId) => _db
      .doc('babies/$babyId')
      .snapshots()
      .map((d) => d.exists ? Baby.fromJson(d.id, d.data()!) : null);

  /// Only readable by Cùng nuôi / relatives with viewBabyInfo; others get permission-denied.
  Stream<BabyPrivateProfile?> watchPrivateProfile(String babyId) => _db
      .doc('babies/$babyId/restricted/profile')
      .snapshots()
      .map((d) => d.exists ? BabyPrivateProfile.fromJson(d.data()!) : null);

  Future<String> createBaby(NewBabyInput input) async {
    try {
      final result = await _functions
          .httpsCallable('createBabyProfile')
          .call<Map<String, dynamic>>(input.toJson());
      return result.data['babyId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw BabyException(_failureOf(e));
    }
  }

  Future<void> setAvatarPhoto(String babyId, Uint8List jpeg) async {
    try {
      final result = await _functions
          .httpsCallable('setBabyAvatarImage')
          .call<Map<String, dynamic>>({
            'babyId': babyId,
            'avatar': {'kind': 'photo', 'jpegBase64': base64Encode(jpeg)},
          });
      final version = result.data['version'];
      if (version is int) _avatarCache['$babyId:$version'] = jpeg;
    } on FirebaseFunctionsException catch (e) {
      throw BabyException(_failureOf(e));
    }
  }

  Future<void> setAvatarPreset(String babyId, int preset) async {
    try {
      await _functions
          .httpsCallable('setBabyAvatarImage')
          .call<Map<String, dynamic>>({
            'babyId': babyId,
            'avatar': {'kind': 'preset', 'preset': preset},
          });
    } on FirebaseFunctionsException catch (e) {
      throw BabyException(_failureOf(e));
    }
  }

  Future<Uint8List?> avatarPhoto(String babyId, int version) async {
    final key = '$babyId:$version';
    final cached = _avatarCache[key];
    if (cached != null) return cached;
    final result = await _functions
        .httpsCallable('getBabyAvatarImage')
        .call<Map<String, dynamic>?>({'babyId': babyId});
    final data = result.data;
    if (data == null || data['version'] != version) return null;
    final bytes = base64Decode(data['jpegBase64'] as String);
    _avatarCache[key] = bytes;
    return bytes;
  }
}

final babyRepositoryProvider = Provider<BabyRepository>(
  (ref) => BabyRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final babyProvider = StreamProvider.family<Baby?, String>(
  (ref, babyId) => ref.watch(babyRepositoryProvider).watchBaby(babyId),
);

final babyPrivateProfileProvider =
    StreamProvider.family<BabyPrivateProfile?, String>(
      (ref, babyId) =>
          ref.watch(babyRepositoryProvider).watchPrivateProfile(babyId),
    );

final babyAvatarPhotoProvider =
    FutureProvider.family<Uint8List?, (String, int)>(
      (ref, key) =>
          ref.watch(babyRepositoryProvider).avatarPhoto(key.$1, key.$2),
    );
