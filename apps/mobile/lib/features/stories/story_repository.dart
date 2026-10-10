import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../memories/memory_models.dart';
import 'story_models.dart';

/// Stories in Firestore (S12). Drafts are written here (the Firestore cache keeps offline edits);
/// saving, deleting a saved story and AI help are callables (server-side guardrails, P-092).
class StoryRepository {
  StoryRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _stories(String babyId) =>
      _db.collection('babies/$babyId/stories');

  /// Parents: saved stories + my drafts + untaken suggestions. Relatives: saved Gia đình ones.
  Stream<List<Story>> watch(String babyId, String uid, {required bool parent}) {
    List<Story> parse(QuerySnapshot<Map<String, dynamic>> s) =>
        s.docs.map(Story.fromDoc).toList();
    if (!parent) {
      return _stories(babyId)
          .where('status', isEqualTo: 'saved')
          .where('audience', isEqualTo: 'family')
          .snapshots()
          .map(parse);
    }
    final saved = _stories(
      babyId,
    ).where('status', isEqualTo: 'saved').snapshots().map(parse);
    final mine = _stories(
      babyId,
    ).where('createdBy', whereIn: [uid, 'ai']).snapshots().map(parse);
    return _merge(saved, mine);
  }

  Stream<List<Story>> _merge(Stream<List<Story>> a, Stream<List<Story>> b) {
    late StreamController<List<Story>> out;
    List<Story>? la, lb;
    StreamSubscription<List<Story>>? sa, sb;
    void emit() {
      if (la == null || lb == null) return;
      final byId = {
        for (final s in [...la!, ...lb!]) s.id: s,
      };
      out.add(byId.values.toList());
    }

    out = StreamController<List<Story>>(
      onListen: () {
        sa = a.listen((v) {
          la = v;
          emit();
        }, onError: out.addError);
        sb = b.listen((v) {
          lb = v;
          emit();
        }, onError: out.addError);
      },
      onCancel: () async {
        await sa?.cancel();
        await sb?.cancel();
      },
    );
    return out.stream;
  }

  Stream<Story?> watchOne(String babyId, String storyId) => _stories(
    babyId,
  ).doc(storyId).snapshots().map((d) => d.exists ? Story.fromDoc(d) : null);

  /// "Lưu nháp": the whole draft; a suggestion becomes mine.
  Future<void> saveDraft(
    Story story,
    String uid,
    Map<String, Object?> author, {
    required bool exists,
  }) {
    final content = {
      'title': story.title,
      'coverMediaId': story.coverMediaId,
      'blocks': [for (final b in story.blocks) b.toJson()],
      'kind': story.kind.name,
      if (!story.saved) 'audience': story.audience.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };
    final ref = _stories(story.babyId).doc(story.id);
    if (!exists) {
      return ref.set({
        'id': story.id,
        'babyId': story.babyId,
        'origin': 'manual',
        'suggestion': false,
        'status': 'draft',
        'createdBy': uid,
        'author': author,
        'loveCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        ...content,
      });
    }
    return ref.update({
      ...content,
      if (story.createdBy == 'ai') ...{
        'createdBy': uid,
        'author': author,
        'suggestion': false,
      },
    });
  }

  /// Bỏ bản nháp (not drawn): drafts and suggestions only.
  Future<void> discard(String babyId, String storyId) =>
      _stories(babyId).doc(storyId).delete();

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

  /// 14f "Lưu câu chuyện": returns how many private photos the family will now see (D-002).
  Future<({int madeVisible, bool notified})> save(
    String babyId,
    String storyId,
    Audience audience,
    bool notifyFamily,
  ) async {
    final r = await _call('saveFamilyStory', {
      'babyId': babyId,
      'storyId': storyId,
      'audience': audience.name,
      'notifyFamily': notifyFamily,
    });
    return (
      madeVisible: (r['madeVisible'] as num?)?.toInt() ?? 0,
      notified: r['notificationId'] != null,
    );
  }

  Future<void> delete(String babyId, String storyId) =>
      _call('deleteFamilyStory', {'babyId': babyId, 'storyId': storyId});

  /// 14b / 14c AI help: alternatives for one paragraph.
  Future<List<String>> assist(
    Story story,
    String blockId,
    StoryAssistOp op,
    String text,
    String locale,
  ) async {
    final r = await _call('storyParagraphAssist', {
      'babyId': story.babyId,
      'storyId': story.id,
      'blockId': blockId,
      'op': op.name,
      'text': text,
      'locale': locale,
    });
    return [for (final o in (r['options'] as List? ?? const [])) '$o'];
  }
}

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// (babyId, uid, parentView).
typedef StoryKey = (String, String, bool);

final storiesProvider = StreamProvider.family<List<Story>, StoryKey>(
  (ref, key) =>
      ref.watch(storyRepositoryProvider).watch(key.$1, key.$2, parent: key.$3),
);

final storyProvider = StreamProvider.family<Story?, (String, String)>(
  (ref, key) => ref.watch(storyRepositoryProvider).watchOne(key.$1, key.$2),
);
