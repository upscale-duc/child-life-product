import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../premium/premium_repository.dart';
import 'first_aid_models.dart';

/// Sơ cứu works without a network (D-058): the last published pack is kept as a file and every
/// picture is downloaded once to the app's support directory (not the cache, which the OS may
/// empty). Firestore's own offline cache serves the document when it is newer than the file.
/// The guide is public content: nothing here is about a child.
class FirstAidStore {
  FirstAidStore(this._db, this._storage, {Future<Directory> Function()? dir})
    : _dirOf = dir ?? getApplicationSupportDirectory;

  final FirebaseFirestore Function() _db;
  final FirebaseStorage Function() _storage;
  final Future<Directory> Function() _dirOf;
  Directory? _dir;
  bool _syncing = false;

  /// Bumped whenever more pictures are on disk (pictures rebuild from disk instead of network).
  final imagesOnDisk = StreamController<int>.broadcast();
  int _onDisk = 0;

  static const _docId = 'content_firstAid';
  static String imagePath(String id) => 'content/first-aid/$id.webp';

  Future<Directory> _root() async => _dir ??= await Directory(
    '${(await _dirOf()).path}/first_aid',
  ).create(recursive: true);

  Future<File> _packFile() async => File('${(await _root()).path}/pack.json');

  /// The local picture for [id] when downloaded (checked synchronously by the widgets).
  File? imageFile(String id) {
    final dir = _dir;
    if (dir == null) return null;
    final f = File('${dir.path}/$id.webp');
    return f.existsSync() ? f : null;
  }

  /// A public download URL for a picture not on disk yet (shown while it downloads).
  String imageUrl(String id) {
    final bucket = _storage().bucket;
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        '${Uri.encodeComponent(imagePath(id))}?alt=media';
  }

  /// The guide: the copy on disk first, then every published change. Null when nothing has ever
  /// been published (the Chăm sóc entry stays hidden, e.g. prod before the medical review).
  Stream<FirstAidPack?> watch() async* {
    await _root();
    FirstAidPack? last;
    try {
      final file = await _packFile();
      if (await file.exists()) {
        last = FirstAidPack.fromDoc(
          (jsonDecode(await file.readAsString()) as Map)
              .cast<String, Object?>(),
        );
      }
    } on Object {
      last = null;
    }
    if (last != null) {
      yield last;
      unawaited(syncImages(last));
    }
    await for (final snap
        in _db()
            .doc('publicConfig/$_docId')
            .snapshots(includeMetadataChanges: true)) {
      final data = snap.data();
      final pack = FirstAidPack.fromDoc(data);
      if (pack != null) {
        if (pack.version != last?.version) {
          try {
            await (await _packFile()).writeAsString(jsonEncode(data));
          } on Object {
            // Disk full: the Firestore cache still has it.
          }
        }
        last = pack;
        yield pack;
        unawaited(syncImages(pack));
      } else if (!snap.exists && !snap.metadata.isFromCache) {
        // Withdrawn on the server: forget it.
        last = null;
        try {
          await (await _packFile()).delete();
        } on Object {
          // Nothing kept.
        }
        yield null;
      } else if (last == null) {
        yield null;
      }
    }
  }

  /// Downloads every picture the pack uses that is not on disk yet, one at a time.
  Future<void> syncImages(FirstAidPack pack) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final root = await _root();
      for (final id in pack.images) {
        final file = File('${root.path}/$id.webp');
        if (file.existsSync()) continue;
        final part = File('${file.path}.part');
        try {
          await _storage().ref(imagePath(id)).writeToFile(part);
          await part.rename(file.path);
          imagesOnDisk.add(++_onDisk);
        } on Object {
          // Offline or not yet uploaded: next time.
          if (part.existsSync()) await part.delete();
        }
      }
    } finally {
      _syncing = false;
    }
  }

  // ---------- Saved situations (per account) ----------

  DocumentReference<Map<String, dynamic>> _saved(String uid) =>
      _db().doc('users/$uid/settings/firstAid');

  Stream<List<String>> watchSaved(String uid) => _saved(uid).snapshots().map(
    (s) => [for (final id in (s.data()?['saved'] as List?) ?? const []) '$id'],
  );

  Future<void> setSaved(String uid, List<String> ids) => _saved(
    uid,
  ).set({'saved': ids, 'updatedAt': FieldValue.serverTimestamp()});
}

final firstAidStoreProvider = Provider<FirstAidStore>(
  (ref) => FirstAidStore(
    () => ref.read(firestoreProvider),
    () => FirebaseStorage.instance,
  ),
);

/// The pack as published (cached on the device), before the family's number is filled in.
final firstAidSourceProvider = StreamProvider<FirstAidPack?>(
  (ref) => ref.watch(firstAidStoreProvider).watch(),
);

/// The guide for the selected family: its country's emergency number in the text and the call
/// buttons (D-078).
final firstAidPackProvider = Provider<AsyncValue<FirstAidPack?>>((ref) {
  final source = ref.watch(firstAidSourceProvider);
  final pack = source.value;
  // No guide yet: nothing to fill, and no need to look at the family.
  if (pack == null) return source;
  return AsyncValue.data(
    pack.forCountry(ref.watch(selectedFamilyCountryProvider)),
  );
});

/// How a picture is shown: from disk once downloaded, else from the network. Tests replace it.
final firstAidImageProvider = Provider<ImageProvider Function(String id)>((
  ref,
) {
  final store = ref.watch(firstAidStoreProvider);
  ref.watch(_imagesOnDiskProvider);
  return (id) {
    final file = store.imageFile(id);
    return file != null ? FileImage(file) : NetworkImage(store.imageUrl(id));
  };
});

final _imagesOnDiskProvider = StreamProvider<int>(
  (ref) => ref.watch(firstAidStoreProvider).imagesOnDisk.stream,
);

final firstAidSavedProvider = StreamProvider<List<String>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return Stream.value(const []);
  return ref.watch(firstAidStoreProvider).watchSaved(session.user.uid);
});

/// "Lưu" / "Bỏ lưu" (7b bookmark).
Future<void> toggleFirstAidSaved(WidgetRef ref, String id) async {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return;
  final now = [...?ref.read(firstAidSavedProvider).value];
  now.contains(id) ? now.remove(id) : now.insert(0, id);
  await ref
      .read(firstAidStoreProvider)
      .setSaved(session.user.uid, now.take(40).toList());
}
