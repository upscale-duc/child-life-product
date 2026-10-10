import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import 'story_models.dart';

/// External sharing (S13): private links (14k), cards (14i) and "Đã chia sẻ ra ngoài" (14m).

enum LinkExpiry { h24, d7, d30 }

extension on LinkExpiry {
  String get wire => switch (this) {
    LinkExpiry.h24 => '24h',
    LinkExpiry.d7 => '7d',
    LinkExpiry.d30 => '30d',
  };
}

enum CardTemplate { moment, three, four, letter, night }

@immutable
class CreatedLink {
  const CreatedLink({
    required this.url,
    required this.passcode,
    required this.expiresAt,
  });
  final String url;

  /// Shown once to copy (P-096).
  final String? passcode;
  final DateTime expiresAt;
}

/// One row of 14m.
@immutable
class SharedOut {
  const SharedOut({
    required this.id,
    required this.kind,
    required this.title,
    required this.storyId,
    required this.babyId,
    required this.createdAt,
    this.coverMediaId,
    this.token,
    this.views = 0,
    this.status = 'active',
    this.expiresAt,
  });
  final String id;

  /// 'link' or 'card'.
  final String kind;
  final String title;
  final String storyId;
  final String babyId;
  final DateTime createdAt;
  final String? coverMediaId;
  final String? token;
  final int views;
  final String status;
  final DateTime? expiresAt;

  bool openAt(DateTime now) =>
      kind == 'link' &&
      status == 'active' &&
      (expiresAt?.isAfter(now) ?? false);

  factory SharedOut.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return SharedOut(
      id: d.id,
      kind: m['kind'] as String? ?? 'link',
      title: m['title'] as String? ?? '',
      storyId: m['storyId'] as String? ?? '',
      babyId: m['babyId'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      coverMediaId: m['coverMediaId'] as String?,
      token: m['token'] as String?,
      views: (m['views'] as num?)?.toInt() ?? 0,
      status: m['status'] as String? ?? 'active',
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ShareRepository {
  ShareRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      final v = r.data;
      return v is Map ? v.cast<String, Object?>() : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw StoryActionException(
        (details is Map ? details['reason'] as String? : null) ?? e.code,
      );
    }
  }

  Future<CreatedLink> createLink(
    Story story, {
    required LinkExpiry expiry,
    required bool hideIdentity,
    required bool allowDownload,
    required bool passcode,
  }) async {
    final r = await _call('createStoryLink', {
      'requestId': const Uuid().v4(),
      'babyId': story.babyId,
      'storyId': story.id,
      'expiry': expiry.wire,
      'hideIdentity': hideIdentity,
      'allowDownload': allowDownload,
      'passcode': passcode,
    });
    return CreatedLink(
      url: r['url']! as String,
      passcode: r['passcode'] as String?,
      expiresAt: DateTime.parse(r['expiresAt']! as String),
    );
  }

  Future<void> revoke(String token) =>
      _call('revokeStoryLink', {'token': token});

  Future<void> recordCard(Story story, CardTemplate template) =>
      _call('recordStoryCard', {
        'requestId': const Uuid().v4(),
        'babyId': story.babyId,
        'storyId': story.id,
        'template': template.name,
      });

  Stream<List<SharedOut>> watch(String uid) => _db
      .collection('users/$uid/sharedOut')
      .snapshots()
      .map(
        (s) =>
            s.docs.map(SharedOut.fromDoc).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
}

final shareRepositoryProvider = Provider<ShareRepository>(
  (ref) => ShareRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final sharedOutProvider = StreamProvider.family<List<SharedOut>, String>(
  (ref, uid) => ref.watch(shareRepositoryProvider).watch(uid),
);
