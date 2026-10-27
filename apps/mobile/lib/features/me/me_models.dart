import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Me, storage and account shapes (S11). Mirrors `packages/contracts/src/account.ts`.

const _gb = 1024 * 1024 * 1024;

/// "Sắp đầy" from 80 %, uploads paused at 100 % (13c, 13d). [unknown]: the limit was not read,
/// never shown as full or "0 B" (D-127).
enum StorageState { ok, nearFull, full, unknown }

/// [used] is used + reserved: "full" is the server's own arithmetic (D-127 Q2).
StorageState storageStateOf(int used, int? quota) {
  if (quota == null || quota <= 0) return StorageState.unknown;
  if (used >= quota) return StorageState.full;
  return used >= quota * 0.8 ? StorageState.nearFull : StorageState.ok;
}

/// The one storage percentage (Me and the Premium card, ST-2): floored, so 100 % only when full.
int storagePercent(int used, int quota) =>
    quota <= 0 ? 0 : (used * 100 / quota).floor().clamp(0, 100);

/// "3,2 GB" / "3.2 GB", "40 MB": one decimal, locale separator, no trailing ",0".
String formatBytes(int bytes, String locale) {
  final comma = locale.startsWith('vi');
  String one(double v) {
    final s = v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return comma ? s.replaceAll('.', ',') : s;
  }

  // "0,8 GB" (13a): gigabytes from a tenth of one.
  if (bytes >= _gb ~/ 10) return '${one(bytes / _gb)} GB';
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

@immutable
class BabyUsage {
  const BabyUsage({
    required this.babyId,
    required this.nickname,
    required this.photos,
    required this.videos,
    required this.photoBytes,
    required this.videoBytes,
  });
  final String babyId;
  final String nickname;
  final int photos;
  final int videos;
  final int photoBytes;
  final int videoBytes;
  int get bytes => photoBytes + videoBytes;

  factory BabyUsage.fromJson(Map<String, Object?> j) => BabyUsage(
    babyId: j['babyId']! as String,
    nickname: j['nickname'] as String? ?? '',
    photos: (j['photos'] as num?)?.toInt() ?? 0,
    videos: (j['videos'] as num?)?.toInt() ?? 0,
    photoBytes: (j['photoBytes'] as num?)?.toInt() ?? 0,
    videoBytes: (j['videoBytes'] as num?)?.toInt() ?? 0,
  );
}

@immutable
class LargeVideo {
  const LargeVideo({
    required this.babyId,
    required this.mediaId,
    required this.bytes,
    required this.durationMs,
    required this.captureAt,
  });
  final String babyId;
  final String mediaId;
  final int bytes;
  final int? durationMs;
  final DateTime captureAt;

  factory LargeVideo.fromJson(Map<String, Object?> j) => LargeVideo(
    babyId: j['babyId']! as String,
    mediaId: j['mediaId']! as String,
    bytes: (j['bytes'] as num?)?.toInt() ?? 0,
    durationMs: (j['durationMs'] as num?)?.toInt(),
    captureAt: DateTime.parse(j['captureAt']! as String),
  );
}

/// 13b, from `getFamilyStorage` (P-003: every Cùng nuôi of the family).
@immutable
class FamilyStorage {
  const FamilyStorage({
    required this.familyId,
    required this.isOwner,
    required int? quotaBytes,
    required this.usedBytes,
    required this.binBytes,
    required this.notesBytes,
    required this.babies,
    required this.largestVideos,
    this.reservedBytes = 0,
    this.reservedItems = 0,
    this.openRequestGb,
    this.openRequestAt,
  }) : quota = quotaBytes;

  final String familyId;
  final bool isOwner;

  /// The limit in force; null when the answer had none (ST-1: unknown, never "full").
  final int? quota;

  /// [quota] or 0, for callers that only draw a bar. Never decide "full" from it.
  int get quotaBytes => quota ?? 0;
  final int usedBytes;

  /// Held by uploads in flight, and how many items hold it (D-127 Q2).
  final int reservedBytes;
  final int reservedItems;
  final int binBytes;
  final int notesBytes;
  final List<BabyUsage> babies;
  final List<LargeVideo> largestVideos;
  final int? openRequestGb;
  final DateTime? openRequestAt;

  /// Used + reserved: what the server counts against the limit.
  int get countedBytes => usedBytes + reservedBytes;
  StorageState get state => storageStateOf(countedBytes, quota);
  int get percent => storagePercent(countedBytes, quotaBytes);

  /// What the next upload can use; null when the limit is unknown.
  int? get availableBytes =>
      quota == null ? null : (quota! - countedBytes).clamp(0, quota!);
  int get videoBytes => babies.fold(0, (s, b) => s + b.videoBytes);
  int get photoBytes => babies.fold(0, (s, b) => s + b.photoBytes);

  factory FamilyStorage.fromJson(Map<String, Object?> j) {
    final open = (j['openRequest'] as Map?)?.cast<String, Object?>();
    List<Map<String, Object?>> list(String k) => [
      for (final e in (j[k] as List? ?? const []))
        (e as Map).cast<String, Object?>(),
    ];
    return FamilyStorage(
      familyId: j['familyId'] as String? ?? '',
      isOwner: j['isOwner'] == true,
      quotaBytes: switch ((j['quotaBytes'] as num?)?.toInt()) {
        final q? when q > 0 => q,
        _ => null,
      },
      usedBytes: (j['usedBytes'] as num?)?.toInt() ?? 0,
      reservedBytes: (j['reservedBytes'] as num?)?.toInt() ?? 0,
      reservedItems: (j['reservedItems'] as num?)?.toInt() ?? 0,
      binBytes: (j['binBytes'] as num?)?.toInt() ?? 0,
      notesBytes: (j['notesBytes'] as num?)?.toInt() ?? 0,
      babies: list('babies').map(BabyUsage.fromJson).toList(),
      largestVideos: list('largestVideos').map(LargeVideo.fromJson).toList(),
      openRequestGb: (open?['amountGb'] as num?)?.toInt(),
      openRequestAt: open == null
          ? null
          : DateTime.parse(open['createdAt']! as String),
    );
  }
}

/// One install in "Thiết bị đang đăng nhập" (13n).
@immutable
class SignedInDevice {
  const SignedInDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.updatedAt,
    required this.signedOut,
  });
  final String id;
  final String name;
  final String platform;
  final DateTime? updatedAt;
  final bool signedOut;

  factory SignedInDevice.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return SignedInDevice(
      id: d.id,
      name: m['name'] as String? ?? '',
      platform: m['platform'] as String? ?? '',
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      signedOut: m['signedOutAt'] != null,
    );
  }
}

/// "Thông báo" (G-056). Missing = all on.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.memories = true,
    this.messages = true,
    this.reminders = true,
    this.storage = true,
  });
  final bool memories;
  final bool messages;
  final bool reminders;
  final bool storage;

  bool get allOn => memories && messages && reminders && storage;
  bool get allOff => !memories && !messages && !reminders && !storage;

  NotificationPrefs copyWith({
    bool? memories,
    bool? messages,
    bool? reminders,
    bool? storage,
  }) => NotificationPrefs(
    memories: memories ?? this.memories,
    messages: messages ?? this.messages,
    reminders: reminders ?? this.reminders,
    storage: storage ?? this.storage,
  );

  factory NotificationPrefs.fromMap(Map<String, dynamic>? m) =>
      NotificationPrefs(
        memories: m?['memories'] != false,
        messages: m?['messages'] != false,
        reminders: m?['reminders'] != false,
        storage: m?['storage'] != false,
      );

  Map<String, Object?> toMap() => {
    'memories': memories,
    'messages': messages,
    'reminders': reminders,
    'storage': storage,
  };
}

/// What `users/{uid}` tells the Me tab: an ownership offer waiting for me (Q-016), and a
/// transfer Child Life Hỗ trợ asks me, the owner, to confirm (A17, P-136).
@immutable
class AccountDoc {
  const AccountDoc({this.ownedBabyCount = 0, this.offer, this.staffTransfer});
  final int ownedBabyCount;
  final OwnershipOffer? offer;
  final StaffTransferRequest? staffTransfer;

  factory AccountDoc.fromMap(Map<String, dynamic>? m) {
    final o = (m?['pendingOwnership'] as Map?)?.cast<String, Object?>();
    return AccountDoc(
      ownedBabyCount: (m?['ownedBabyCount'] as num?)?.toInt() ?? 0,
      offer: o == null
          ? null
          : OwnershipOffer(
              familyId: o['familyId']! as String,
              fromName: o['fromName'] as String? ?? '',
              babyIds: [for (final b in (o['babyIds'] as List? ?? [])) '$b'],
            ),
      staffTransfer: StaffTransferRequest.fromMap(m?['pendingStaffTransfer']),
    );
  }
}

/// `users/{uid}.pendingStaffTransfer`, set by `staffOpenTransfer` (A17, P-136): Hỗ trợ asks the
/// owner to hand the family to [toMasked] (a Cùng nuôi of every baby). The owner answers within
/// 48 hours with `answerStaffOwnershipRequest`; agreeing makes the usual 13n offer.
@immutable
class StaffTransferRequest {
  const StaffTransferRequest({
    required this.transferId,
    required this.toMasked,
    required this.expiresAt,
    this.ticket,
    this.at,
  });

  /// `ft_` + 20 hex characters.
  final String transferId;

  /// The candidate's masked email ("m***@gmail.com"); never the full address.
  final String toMasked;

  /// "CL-1042", or null when the request has no ticket.
  final String? ticket;
  final DateTime? at;
  final DateTime expiresAt;

  /// Still answerable at [now] (the server expires it hourly after 48 hours).
  bool isOpenAt(DateTime now) => expiresAt.isAfter(now);

  /// Null when absent or malformed (nothing to show).
  static StaffTransferRequest? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['transferId'];
    final to = raw['toMasked'];
    final ticket = raw['ticket'];
    final expires = raw['expiresAt'];
    if (id is! String || !RegExp(r'^ft_[a-f0-9]{20}$').hasMatch(id)) {
      return null;
    }
    if (to is! String || to.isEmpty || expires is! Timestamp) return null;
    final at = raw['at'];
    return StaffTransferRequest(
      transferId: id,
      toMasked: to,
      ticket: ticket is String && ticket.isNotEmpty ? ticket : null,
      at: at is Timestamp ? at.toDate() : null,
      expiresAt: expires.toDate(),
    );
  }
}

@immutable
class OwnershipOffer {
  const OwnershipOffer({
    required this.familyId,
    required this.fromName,
    required this.babyIds,
  });
  final String familyId;
  final String fromName;
  final List<String> babyIds;
}

enum ExportKind { care, media }

enum ExportState { queued, running, ready, failed, expired }

/// "Xuất dữ liệu" job (R-187).
@immutable
class ExportJob {
  const ExportJob({
    required this.id,
    required this.kind,
    required this.babyId,
    required this.state,
    required this.createdAt,
    this.path,
    this.expiresAt,
  });
  final String id;
  final ExportKind kind;
  final String babyId;
  final ExportState state;
  final DateTime createdAt;
  final String? path;
  final DateTime? expiresAt;

  factory ExportJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return ExportJob(
      id: d.id,
      kind: ExportKind.values.asNameMap()[m['exportKind']] ?? ExportKind.care,
      babyId: m['babyId'] as String? ?? '',
      state: ExportState.values.asNameMap()[m['state']] ?? ExportState.failed,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      path: m['path'] as String?,
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A deletion job the caller started (13l "Đang xoá…", 13n).
@immutable
class DeletionJob {
  const DeletionJob({required this.id, required this.state, this.failedStep});
  final String id;
  final String state;
  final String? failedStep;
  bool get done => state == 'done';
  bool get failed => state == 'failed';

  factory DeletionJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      DeletionJob(
        id: d.id,
        state: d.data()?['state'] as String? ?? 'queued',
        failedStep: d.data()?['failedStep'] as String?,
      );
}

enum HelpCategory { memories, family, invites, sync, account, storage, stories }

/// Server error reasons the screens turn into copy.
class AccountActionException implements Exception {
  const AccountActionException(this.reason);
  final String reason;
  @override
  String toString() => 'AccountActionException($reason)';
}
