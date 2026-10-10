import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/stories/share_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';
import 'reminder_fixtures.dart';

/// S11 fixtures: 13b numbers (Teddy 2,4 GB · Na 0,8 GB of 10 GB), a nearly full and a full
/// family, devices for 13n and a ready export.

const _gb = 1024 * 1024 * 1024;
const naId = 'b_00000000000000000002';

FamilyStorage mockStorage({double teddyGb = 2.4, double naGb = 0.8}) {
  int b(double gb) => (gb * _gb).round();
  return FamilyStorage(
    familyId: 'f_1',
    isOwner: true,
    quotaBytes: 10 * _gb,
    usedBytes: b(teddyGb + naGb) + 40 * 1024 * 1024,
    binBytes: 0,
    notesBytes: 40 * 1024 * 1024,
    babies: [
      BabyUsage(
        babyId: teddyId,
        nickname: 'Teddy',
        photos: 312,
        videos: 24,
        photoBytes: b(teddyGb * 0.3),
        videoBytes: b(teddyGb * 0.7),
      ),
      BabyUsage(
        babyId: naId,
        nickname: 'Na',
        photos: 96,
        videos: 6,
        photoBytes: b(naGb * 0.4),
        videoBytes: b(naGb * 0.6),
      ),
    ],
    largestVideos: const [],
  );
}

final mockDevices = [
  SignedInDevice(
    id: testDeviceId,
    name: 'iPhone',
    platform: 'ios',
    updatedAt: DateTime(2026, 10, 8, 9),
    signedOut: false,
  ),
  SignedInDevice(
    id: 'd_${'b' * 32}',
    name: 'iPad',
    platform: 'ios',
    updatedAt: DateTime(2026, 10, 5, 10),
    signedOut: false,
  ),
];

final mockExports = [
  ExportJob(
    id: 'ex_1',
    kind: ExportKind.care,
    babyId: teddyId,
    state: ExportState.ready,
    createdAt: DateTime(2026, 10, 8, 9),
    path: 'exports/u_mai/ex_1/child-life-care.zip',
    expiresAt: DateTime(2026, 10, 9, 6),
  ),
];

/// S11 providers on top of [familyOverrides].
List<Override> meOverrides({
  FamilyStorage? storage,
  List<SignedInDevice>? devices,
  List<ExportJob> exports = const [],
  String? offeredTo,
  MeRepository? repo,
}) => [
  familyStorageProvider.overrideWith(
    (ref, babyId) async => storage ?? mockStorage(),
  ),
  devicesProvider.overrideWith(
    (ref, uid) => Stream.value(devices ?? mockDevices),
  ),
  exportsProvider.overrideWith((ref, uid) => Stream.value(exports)),
  offeredToProvider.overrideWith((ref, familyId) => Stream.value(offeredTo)),
  deletionJobProvider.overrideWith((ref, jobId) => Stream.value(null)),
  // 13a "Đã chia sẻ ra ngoài" (S13).
  sharedOutProvider.overrideWith((ref, uid) => Stream.value(const <SharedOut>[])),
  if (repo != null) meRepositoryProvider.overrideWithValue(repo),
];

/// What the Me screens asked the server to do.
class FakeMeRepository extends Fake implements MeRepository {
  final calls = <(String, Map<String, Object?>)>[];

  @override
  String locale = 'vi';

  @override
  Future<void> requestStorage(
    String babyId,
    int amountGb,
    String message,
  ) async =>
      calls.add(('requestStorage', {'amountGb': amountGb, 'message': message}));

  @override
  Future<String> deleteBaby(String babyId, String typed) async {
    calls.add(('deleteBaby', {'babyId': babyId, 'typed': typed}));
    return 'del_$babyId';
  }

  @override
  Future<void> updateBaby(String babyId, Map<String, Object?> change) async =>
      calls.add(('updateBaby', change));

  @override
  Future<void> savePrefs(String uid, NotificationPrefs prefs) async =>
      calls.add(('savePrefs', prefs.toMap()));

  @override
  Future<void> signOutDevice(String deviceId) async =>
      calls.add(('signOutDevice', {'deviceId': deviceId}));

  @override
  Future<String> sendHelp(
    HelpCategory category,
    String message,
    Map<String, Object?>? diagnostics,
  ) async {
    calls.add(('sendHelp', {'category': category.name, 'message': message}));
    return 'CL-1001';
  }

  @override
  Future<String> answerOwnership(String familyId, String answer) async {
    calls.add(('answerOwnership', {'answer': answer}));
    return answer;
  }
}
