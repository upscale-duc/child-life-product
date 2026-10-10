import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Media bytes are read through Storage Rules (ADR-004) and cached on the device: a media file
/// never changes once written, so a cached copy is valid until the item is purged.
abstract class MediaBytes {
  Future<Uint8List> read(String path);

  /// A local file for the video player and "Tải về".
  Future<File> file(String path);
}

class StorageMediaBytes implements MediaBytes {
  StorageMediaBytes([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _inFlight = <String, Future<Uint8List>>{};
  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationCacheDirectory();
    return _dir = await Directory('${base.path}/media').create(recursive: true);
  }

  Future<File> _local(String path) async =>
      File('${(await _cacheDir()).path}/${path.replaceAll('/', '_')}');

  @override
  Future<Uint8List> read(String path) => _inFlight[path] ??= () async {
    try {
      final local = await _local(path);
      if (await local.exists()) return local.readAsBytes();
      final bytes = await _storage.ref(path).getData(60 * 1024 * 1024);
      if (bytes == null) throw StateError('empty');
      await local.writeAsBytes(bytes, flush: true);
      return bytes;
    } finally {
      unawaited(Future<void>(() => _inFlight.remove(path)));
    }
  }();

  @override
  Future<File> file(String path) async {
    final local = await _local(path);
    if (await local.exists()) return local;
    final part = File('${local.path}.part');
    await _storage.ref(path).writeToFile(part);
    return part.rename(local.path);
  }
}

/// The loader [StorageImage] uses; tests replace it.
MediaBytes mediaBytes = StorageMediaBytes();

/// An image from a Rules-gated Storage path (thumb / display / poster).
@immutable
class StorageImage extends ImageProvider<StorageImage> {
  const StorageImage(this.path);
  final String path;

  @override
  Future<StorageImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

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
  bool operator ==(Object other) => other is StorageImage && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
