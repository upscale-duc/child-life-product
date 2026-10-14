import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import 'care_models.dart';

/// Running timers (S5; P-011, R-070…R-073), mirroring `packages/contracts/src/care.ts`:
/// `babies/{b}/timers/{type}`, one per baby and type, shared live with the family. Time is
/// derived from timestamps on every frame — nothing is written per second.

enum TimerType { sleep, breast, pump }

extension TimerTypeCare on TimerType {
  CareType get careType => switch (this) {
    TimerType.sleep => CareType.sleep,
    TimerType.breast => CareType.breast,
    TimerType.pump => CareType.pump,
  };
}

/// One side of a breast / pump timer.
@immutable
class TimerSide {
  const TimerSide({this.accumulatedMs = 0, this.runningSince});

  final int accumulatedMs;
  final DateTime? runningSince;

  bool get running => runningSince != null;

  Duration elapsedAt(DateTime now) => Duration(
    milliseconds:
        accumulatedMs +
        (runningSince == null
            ? 0
            : now.difference(runningSince!).inMilliseconds.clamp(0, 1 << 40)),
  );

  TimerSide start(DateTime now) => running
      ? this
      : TimerSide(accumulatedMs: accumulatedMs, runningSince: now);

  TimerSide stop(DateTime now) =>
      running ? TimerSide(accumulatedMs: elapsedAt(now).inMilliseconds) : this;

  Map<String, Object?> toJson() => {
    'accumulatedMs': accumulatedMs,
    'runningSince': runningSince == null
        ? null
        : Timestamp.fromDate(runningSince!),
  };

  factory TimerSide.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return TimerSide(
      accumulatedMs: (map['accumulatedMs'] as num?)?.toInt() ?? 0,
      runningSince: dateOf(map['runningSince']),
    );
  }
}

@immutable
class CareTimer {
  const CareTimer({
    required this.babyId,
    required this.type,
    required this.sessionId,
    required this.startedAt,
    required this.startedBy,
    required this.author,
    this.left,
    this.right,
    this.paused = false,
    this.pausedSides = const [],
    this.pending = false,
  });

  final String babyId;
  final TimerType type;

  /// 32 hex; the record written on "Kết thúc" is `r_<sessionId>` — exactly once.
  final String sessionId;
  final DateTime startedAt;
  final String startedBy;
  final CareAuthor author;
  final TimerSide? left;
  final TimerSide? right;
  final bool paused;

  /// Sides to resume after "Tạm dừng".
  final List<Side> pausedSides;

  /// Started or changed on this device, not yet on the server (9c "Chỉ trên máy này").
  final bool pending;

  String get recordId => 'r_$sessionId';

  static String newSessionId() => const Uuid().v4().replaceAll('-', '');

  TimerSide sideOf(Side s) =>
      (s == Side.right ? right : left) ?? const TimerSide();

  /// Breastfeeding: total = sum of the sides (23b); pumping: wall clock while any side runs
  /// (23c, both sides run together); sleep: since the start.
  Duration totalAt(DateTime now) => switch (type) {
    TimerType.sleep => now.difference(startedAt),
    TimerType.breast =>
      sideOf(Side.left).elapsedAt(now) + sideOf(Side.right).elapsedAt(now),
    TimerType.pump => () {
      final l = sideOf(Side.left).elapsedAt(now);
      final r = sideOf(Side.right).elapsedAt(now);
      return l > r ? l : r;
    }(),
  };

  /// The side currently running for a breastfeed (one at a time).
  Side? get activeSide => sideOf(Side.left).running
      ? Side.left
      : sideOf(Side.right).running
      ? Side.right
      : null;

  CareTimer copyWith({
    DateTime? startedAt,
    TimerSide? left,
    TimerSide? right,
    bool? paused,
    List<Side>? pausedSides,
  }) => CareTimer(
    babyId: babyId,
    type: type,
    sessionId: sessionId,
    startedAt: startedAt ?? this.startedAt,
    startedBy: startedBy,
    author: author,
    left: left ?? this.left,
    right: right ?? this.right,
    paused: paused ?? this.paused,
    pausedSides: pausedSides ?? this.pausedSides,
    pending: pending,
  );

  /// "Chạm để đổi bên": stop the running side, start the other (23b).
  CareTimer switchTo(Side side, DateTime now) => copyWith(
    left: side == Side.left
        ? sideOf(Side.left).start(now)
        : sideOf(Side.left).stop(now),
    right: side == Side.right
        ? sideOf(Side.right).start(now)
        : sideOf(Side.right).stop(now),
    paused: false,
    pausedSides: const [],
  );

  /// Pump: "chạm 1 bên để dừng riêng" — toggles one side.
  CareTimer toggle(Side side, DateTime now) {
    final s = sideOf(side);
    final next = s.running ? s.stop(now) : s.start(now);
    return copyWith(
      left: side == Side.left ? next : null,
      right: side == Side.right ? next : null,
      paused: false,
      pausedSides: const [],
    );
  }

  /// "Tạm dừng" / "Tiếp tục".
  CareTimer pauseAt(DateTime now) => copyWith(
    left: sideOf(Side.left).stop(now),
    right: sideOf(Side.right).stop(now),
    paused: true,
    pausedSides: [
      if (sideOf(Side.left).running) Side.left,
      if (sideOf(Side.right).running) Side.right,
    ],
  );

  CareTimer resumeAt(DateTime now) {
    final sides = pausedSides.isEmpty ? [Side.left] : pausedSides;
    return copyWith(
      left: sides.contains(Side.left) ? sideOf(Side.left).start(now) : null,
      right: sides.contains(Side.right) ? sideOf(Side.right).start(now) : null,
      paused: false,
      pausedSides: const [],
    );
  }

  static CareTimer start({
    required TimerType type,
    required Membership me,
    required DateTime now,
    Side side = Side.left,
  }) => CareTimer(
    babyId: me.babyId,
    type: type,
    sessionId: newSessionId(),
    startedAt: now,
    startedBy: me.uid,
    author: CareAuthor.of(me),
    left: type == TimerType.sleep
        ? null
        : TimerSide(runningSince: side != Side.right ? now : null),
    right: type == TimerType.sleep
        ? null
        : TimerSide(
            runningSince:
                side == Side.right ||
                    (type == TimerType.pump && side == Side.both)
                ? now
                : null,
          ),
    pending: true,
  );

  /// The record "Kết thúc" writes (one per session). Written by whoever ends it ([by]: the
  /// timer is shared, and Rules want the writer's own uid and author, like the widget's "Thức
  /// dậy" in GlanceActions.swift); a sleep ends at most 24 h after it started.
  CareRecord toRecord(
    DateTime now, {
    int? pumpAmountMl,
    ({String uid, CareAuthor author})? by,
  }) {
    final total = totalAt(now);
    final minutes = (total.inSeconds / 60).round().clamp(
      1,
      CareLimits.durationMin.max,
    );
    final leftMin = (sideOf(Side.left).elapsedAt(now).inSeconds / 60).round();
    final rightMin = (sideOf(Side.right).elapsedAt(now).inSeconds / 60).round();
    final usedLeft = sideOf(Side.left).elapsedAt(now) > Duration.zero;
    final usedRight = sideOf(Side.right).elapsedAt(now) > Duration.zero;
    final side = usedLeft && usedRight
        ? Side.both
        : usedRight
        ? Side.right
        : Side.left;
    return CareRecord(
      id: recordId,
      babyId: babyId,
      type: type.careType,
      occurredAt: startedAt,
      endedAt: type == TimerType.sleep
          ? (now.isAfter(startedAt.add(const Duration(hours: 24)))
                ? startedAt.add(const Duration(hours: 24))
                : now)
          : startedAt.add(Duration(minutes: minutes)),
      createdBy: by?.uid ?? startedBy,
      author: by?.author ?? author,
      side: type == TimerType.sleep ? null : side,
      durationMin: type == TimerType.sleep ? null : minutes,
      leftMin: type == TimerType.breast ? leftMin : null,
      rightMin: type == TimerType.breast ? rightMin : null,
      endSide: type == TimerType.breast ? _endSide(now) : null,
      amountMl: pumpAmountMl,
      clientCreatedAt: now,
      pending: true,
    );
  }

  /// The side that ran last ("Lần trước kết thúc bên phải").
  Side? _endSide(DateTime now) =>
      activeSide ?? (pausedSides.length == 1 ? pausedSides.first : null);

  Map<String, Object?> toJson(String uid) => {
    'type': type.name,
    'babyId': babyId,
    'sessionId': sessionId,
    'startedAt': Timestamp.fromDate(startedAt),
    'startedBy': startedBy,
    'author': author.toJson(),
    'sides': type == TimerType.sleep
        ? null
        : {
            'left': sideOf(Side.left).toJson(),
            'right': sideOf(Side.right).toJson(),
          },
    'paused': paused,
    'pausedSides': [for (final s in pausedSides) s.name],
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
  };

  /// What an update may change (Rules: `validTimerUpdate`).
  Map<String, Object?> toUpdateJson(String uid) {
    final all = toJson(uid);
    return {
      for (final k in const [
        'startedAt',
        'sides',
        'paused',
        'pausedSides',
        'updatedAt',
        'updatedBy',
      ])
        k: all[k],
    };
  }

  static CareTimer? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data();
    if (json == null) return null;
    final type = TimerType.values.asNameMap()[json['type']];
    final startedAt = dateOf(json['startedAt']);
    if (type == null || startedAt == null) return null;
    final sides = json['sides'] is Map ? json['sides'] as Map : null;
    return CareTimer(
      babyId: json['babyId'] as String? ?? '',
      type: type,
      sessionId: json['sessionId'] as String? ?? '',
      startedAt: startedAt,
      startedBy: json['startedBy'] as String? ?? '',
      author: CareAuthor.fromJson(json['author']),
      left: sides == null ? null : TimerSide.fromJson(sides['left']),
      right: sides == null ? null : TimerSide.fromJson(sides['right']),
      paused: json['paused'] == true,
      pausedSides: [
        for (final s in (json['pausedSides'] as List?) ?? const [])
          ?Side.values.asNameMap()[s],
      ],
      pending: doc.metadata.hasPendingWrites,
    );
  }
}

/// Two sleeps found overlapping by the server (27, R-075).
@immutable
class SleepConflict {
  const SleepConflict({
    required this.id,
    required this.recordIds,
    required this.laterAuthor,
  });

  final String id;
  final List<String> recordIds;

  /// The member whose sync revealed it: they are shown 27.
  final String? laterAuthor;

  factory SleepConflict.fromJson(String id, Map<String, Object?> json) =>
      SleepConflict(
        id: id,
        recordIds: [
          for (final r in (json['recordIds'] as List?) ?? const []) r as String,
        ],
        laterAuthor: json['laterAuthor'] as String?,
      );
}
