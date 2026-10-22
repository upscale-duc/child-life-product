import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/privacy/local_privacy.dart';

/// Media bytes are read through Storage Rules (ADR-004) and cached on the device: a media file
/// never changes once written, so a cached copy is valid until the item is purged.
abstract class MediaBytes {
  Future<Uint8List> read(String path);

  /// A local file for the video player and "Tải về".
  Future<File> file(String path);

  /// What the video player opens: the cached file when there is one, else the object streamed
  /// straight from Storage (range requests, so playback starts after the first bytes rather
  /// than the whole download; still behind Storage Rules, signed in as the viewer).
  Future<MediaSource> playable(String path);
}

/// A URI for the player and the headers it needs.
@immutable
class MediaSource {
  const MediaSource(this.uri, {this.headers = const {}});
  final String uri;
  final Map<String, String> headers;
}

class StorageMediaBytes implements MediaBytes {
  StorageMediaBytes({
    this._storage,
    String? Function()? owner,
    Future<Directory> Function()? cacheDirectory,
    LocalPrivacy? access,
  }) : _owner = owner ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _cacheDirectory = cacheDirectory ?? getApplicationCacheDirectory,
       _privacy = access ?? localPrivacy;

  final FirebaseStorage? _storage;
  FirebaseStorage get _firebase => _storage ?? FirebaseStorage.instance;
  final String? Function() _owner;
  final Future<Directory> Function() _cacheDirectory;
  final LocalPrivacy _privacy;
  final _inFlight = <String, Future<Uint8List>>{};
  String _uid() => _owner() ?? (throw StateError('signed-out'));

  (String, int) _access(String path) {
    final uid = _uid();
    return (uid, _privacy.authorize(uid, path));
  }

  void _check(String uid, int epoch) {
    if (_uid() != uid) throw StateError('local-session-changed');
    _privacy.check(epoch);
  }

  Future<Directory> _cacheDir(String uid) async {
    final base = await _cacheDirectory();
    return Directory(
      '${base.path}/media-v2/${Uri.encodeComponent(uid)}',
    ).create(recursive: true);
  }

  Future<File> _local(String uid, String path) async =>
      File('${(await _cacheDir(uid)).path}/${path.replaceAll('/', '_')}');

  @override
  Future<Uint8List> read(String path) {
    final (uid, epoch) = _access(path);
    final key = '$uid|$epoch|$path';
    return _inFlight[key] ??= () async {
      try {
        final local = await _local(uid, path);
        // Only Cùng nuôi reads come from (and go to) the device cache; other roles never
        // read it back, so writing their bytes would be disk work for nothing.
        final cacheable = _privacy.parents.contains(path.split('/')[1]);
        if (cacheable && await local.exists()) {
          final cached = await local.readAsBytes();
          _check(uid, epoch);
          _access(path);
          return cached;
        }
        final bytes = await _firebase.ref(path).getData(60 * 1024 * 1024);
        _check(uid, epoch);
        if (bytes == null) throw StateError('empty');
        if (cacheable) {
          // Write beside, then rename: a reader never sees a half-written file.
          final part = File('${local.path}.$epoch.part');
          await part.writeAsBytes(bytes);
          _check(uid, epoch);
          await part.rename(local.path);
        }
        _check(uid, epoch);
        _access(path);
        return bytes;
      } finally {
        _inFlight.remove(key);
      }
    }();
  }

  @override
  Future<MediaSource> playable(String path) async {
    final (uid, epoch) = _access(path);
    final local = await _local(uid, path);
    final cached =
        _privacy.parents.contains(path.split('/')[1]) && await local.exists();
    final token = cached
        ? null
        : await FirebaseAuth.instance.currentUser?.getIdToken();
    _check(uid, epoch);
    _access(path);
    if (cached) return MediaSource(Uri.file(local.path).toString());
    if (token == null) throw StateError('signed-out');
    return MediaSource(
      'https://firebasestorage.googleapis.com/v0/b/${_firebase.bucket}/o/${Uri.encodeComponent(path)}?alt=media',
      headers: {'Authorization': 'Firebase $token'},
    );
  }

  @override
  Future<File> file(String path) async {
    final (uid, epoch) = _access(path);
    final local = await _local(uid, path);
    if (!_privacy.parents.contains(path.split('/')[1]) ||
        !await local.exists()) {
      final part = File('${local.path}.$epoch.part');
      await _firebase.ref(path).writeToFile(part);
      _check(uid, epoch);
      await part.rename(local.path);
    }
    _check(uid, epoch);
    _access(path);
    return local;
  }
}

/// The loader [StorageImage] uses; tests replace it.
MediaBytes mediaBytes = StorageMediaBytes();

/// An image from a Rules-gated Storage path (thumb / display / poster).
@immutable
class StorageImage extends ImageProvider<StorageImage> {
  const StorageImage(this.path) : scope = null;
  const StorageImage._scoped(this.path, this.scope);
  final String? scope;
  final String path;

  @override
  Future<StorageImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(
        StorageImage._scoped(
          path,
          '${localPrivacy.owner}|${localPrivacy.generation}',
        ),
      );

  @override
  ImageStreamCompleter loadImage(
    StorageImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: () async {
      final bytes = await mediaBytes.read(key.path);
      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    }(),
    scale: 1,
    debugLabel: 'StorageImage',
  );

  @override
  bool operator ==(Object other) =>
      other is StorageImage && other.path == path && other.scope == scope;

  @override
  int get hashCode => Object.hash(path, scope);
}
