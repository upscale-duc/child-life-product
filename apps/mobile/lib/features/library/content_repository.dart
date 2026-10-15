import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import 'content_models.dart';

/// Published content as last seen: [fromCache] while the device has not heard from the server
/// (offline, "bản đã lưu trên máy").
typedef LbFeed<T> = ({List<T> items, bool fromCache});

/// One saved article (`users/{uid}/savedArticles/{articleId}`, per person, 4e / 4f): when it was
/// saved and the revision last read, so 4f can say "đã được cập nhật".
typedef LbSaved = ({String id, DateTime? savedAt, int revision});

/// Reads the published library and stages. Firestore keeps its own offline copy of every
/// document read, so both lists still open without a network; pictures are kept on disk.
class ContentStore {
  ContentStore(this._db, this._storage, {Future<Directory> Function()? dir})
    : _dirOf = dir ?? getApplicationSupportDirectory;

  final FirebaseFirestore Function() _db;
  final FirebaseStorage Function() _storage;
  final Future<Directory> Function() _dirOf;

  static const articles = 'contentArticles';
  static const stages = 'contentStages';

  Stream<LbFeed<T>> _published<T>(
    String collection,
    T? Function(String id, Map<String, Object?> data) parse,
  ) => _db()
      .collection(collection)
      // The Rules allow lists only with this filter (content.ts).
      .where('status', isEqualTo: 'published')
      .snapshots(includeMetadataChanges: true)
      .map(
        (q) => (
          items: [for (final d in q.docs) ?parse(d.id, d.data())],
          fromCache: q.metadata.isFromCache,
        ),
      );

  Stream<LbFeed<LbArticle>> watchArticles() =>
      _published(articles, LbArticle.fromDoc);

  Stream<LbFeed<LbStage>> watchStages() => _published(stages, LbStage.fromDoc);

  // ---------- Saved articles (per person) ----------

  CollectionReference<Map<String, dynamic>> _saved(String uid) =>
      _db().collection('users/$uid/savedArticles');

  Stream<List<LbSaved>> watchSaved(String uid) => _saved(uid)
      .orderBy('savedAt', descending: true)
      .limit(200)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            (
              id: d.id,
              savedAt: lbDate(d.data()['savedAt']) ?? DateTime.now(),
              revision: (d.data()['revision'] as num?)?.toInt() ?? 1,
            ),
        ],
      );

  /// "Lưu" (4e). Only the id, the time and the revision read: nothing about a child.
  Future<void> save(String uid, LbArticle a) => _saved(uid).doc(a.id).set({
    'savedAt': FieldValue.serverTimestamp(),
    'revision': a.revision,
  });

  Future<void> unsave(String uid, String id) => _saved(uid).doc(id).delete();

  /// The reader opened the newer revision of a saved article: the 4f banner goes away.
  Future<void> markRead(String uid, String id, int revision) =>
      _saved(uid).doc(id).update({'revision': revision});

  // ---------- Pictures (`content/library/{id}.webp`, public and immutable) ----------

  Directory? _dir;
  final _downloading = <String>{};
  final imagesOnDisk = StreamController<int>.broadcast();
  var _onDisk = 0;

  static String imagePath(String id) => 'content/library/$id.webp';

  Future<Directory> _root() async => _dir ??= await Directory(
    '${(await _dirOf()).path}/library',
  ).create(recursive: true);

  File? _file(String id) {
    final dir = _dir;
    if (dir == null) return null;
    final f = File('${dir.path}/$id.webp');
    return f.existsSync() ? f : null;
  }

  /// From disk once downloaded (offline reading), else from the network while it downloads.
  ImageProvider image(String id) {
    final file = _file(id);
    if (file != null) return FileImage(file);
    unawaited(_download(id));
    final bucket = _storage().bucket;
    return NetworkImage(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
      '${Uri.encodeComponent(imagePath(id))}?alt=media',
    );
  }

  Future<void> _download(String id) async {
    if (!_downloading.add(id)) return;
    try {
      final root = await _root();
      final file = File('${root.path}/$id.webp');
      if (file.existsSync()) return;
      final part = File('${file.path}.part');
      try {
        await _storage().ref(imagePath(id)).writeToFile(part);
        await part.rename(file.path);
        imagesOnDisk.add(++_onDisk);
      } on Object {
        // Offline or removed: next time.
        if (part.existsSync()) await part.delete();
      }
    } finally {
      _downloading.remove(id);
    }
  }
}

final contentStoreProvider = Provider<ContentStore>(
  (ref) => ContentStore(
    () => ref.read(firestoreProvider),
    () => FirebaseStorage.instance,
  ),
);

/// Signed in, with Firebase set up (screens that only peek at the library, like Chăm sóc's
/// tiles, then draw nothing instead of failing where Firebase is absent, e.g. widget tests).
bool _canRead(Ref ref) =>
    ref.watch(sessionProvider) is SessionSignedIn && Firebase.apps.isNotEmpty;

/// Every published article (both libraries; screens pick theirs).
final lbArticlesProvider = StreamProvider<LbFeed<LbArticle>>((ref) {
  if (!_canRead(ref)) {
    return Stream.value((items: const <LbArticle>[], fromCache: false));
  }
  return ref.watch(contentStoreProvider).watchArticles();
});

final lbStagesProvider = StreamProvider<LbFeed<LbStage>>((ref) {
  if (!_canRead(ref)) {
    return Stream.value((items: const <LbStage>[], fromCache: false));
  }
  return ref.watch(contentStoreProvider).watchStages();
});

final lbSavedProvider = StreamProvider<List<LbSaved>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn || !_canRead(ref)) {
    return Stream.value(const []);
  }
  return ref.watch(contentStoreProvider).watchSaved(session.user.uid);
});

final _lbImagesOnDiskProvider = StreamProvider<int>(
  (ref) => ref.watch(contentStoreProvider).imagesOnDisk.stream,
);

/// How a content picture is shown (tests return null: a tinted placeholder).
final lbImageProvider = Provider<ImageProvider? Function(String id)>((ref) {
  final store = ref.watch(contentStoreProvider);
  ref.watch(_lbImagesOnDiskProvider);
  return store.image;
});
