import 'dart:async';

import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'assistant_models.dart';
import 'assistant_rules.dart' show maxPhotoBytes;

/// Photos for the assistant (slice A5, CH09–CH14): the person picks ONE photo, the phone
/// re-encodes it (JPEG, ≤ 2048 px, no EXIF / GPS) and uploads it once to the owned path the
/// server gave (`createAttachmentUpload`), then `startTask` reads it. Nothing is uploaded before
/// the exact quote is shown and "Gửi ảnh" is tapped; a refused quote uploads nothing. Bytes are
/// kept in memory only (thumbnails of this session), never logged.

/// Where the photo comes from (CH09 "Chụp ảnh" / "Chọn từ thư viện").
enum PhotoSource { camera, library }

/// The picker could not open (permission, camera missing…): [denied] → "Mở Cài đặt".
class PhotoPickError implements Exception {
  const PhotoPickError({this.denied = false});
  final bool denied;
}

/// Picks one photo and re-encodes it (≤ 2048 px JPEG without metadata). Null when cancelled;
/// throws [PhotoPickError]. Tests replace it.
typedef PhotoPicker = Future<PickedPhoto?> Function(PhotoSource source);

/// One picked, re-encoded photo (in memory only).
@immutable
class PickedPhoto {
  const PickedPhoto({
    required this.name,
    required this.bytes,
    this.mime = 'image/jpeg',
  });
  final String name;
  final Uint8List bytes;
  final String mime;

  /// `createAttachmentUpload.sha256` (the server recomputes its own; never trusted).
  String get sha256 => crypto.sha256.convert(bytes).toString();
}

Future<PickedPhoto?> _pickAndEncode(PhotoSource source) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      requestFullMetadata: false,
    );
  } on PlatformException catch (e) {
    throw PhotoPickError(
      denied: e.code.contains('denied') || e.code.contains('access'),
    );
  }
  if (file == null) return null;
  // Re-encoded without EXIF (no location on a receipt or a note), legible and well under 8 MB.
  final jpeg = await FlutterImageCompress.compressWithList(
    await file.readAsBytes(),
    minWidth: 2048,
    minHeight: 2048,
    quality: 85,
    keepExif: false,
  );
  if (jpeg.isEmpty || jpeg.length > maxPhotoBytes) {
    throw const PhotoPickError();
  }
  return PickedPhoto(name: file.name, bytes: jpeg);
}

final assistantPhotoPickerProvider = Provider<PhotoPicker>(
  (ref) => _pickAndEncode,
);

// ---------- Upload ----------

/// The upload was cancelled by the person ("Huỷ" while uploading): nothing was started, so
/// nothing is charged.
class UploadCanceled implements Exception {
  const UploadCanceled();
}

/// One running upload: progress 0–1, completion, cancel.
abstract class AssistantUpload {
  Stream<double> get progress;

  /// Completes when the bytes are stored; throws [UploadCanceled] or a failure.
  Future<void> get done;
  Future<void> cancel();
}

/// Uploads the bytes once to the owned path (Storage Rules: create once, declared type).
abstract class AssistantUploader {
  AssistantUpload start(String path, Uint8List bytes, String mime);
}

class FirebaseAssistantUploader implements AssistantUploader {
  FirebaseAssistantUploader([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;

  @override
  AssistantUpload start(String path, Uint8List bytes, String mime) =>
      _FirebaseUpload(
        _storage.ref(path).putData(bytes, SettableMetadata(contentType: mime)),
      );
}

class _FirebaseUpload implements AssistantUpload {
  _FirebaseUpload(this._task);
  final UploadTask _task;
  var _canceled = false;

  @override
  Stream<double> get progress => _task.snapshotEvents.map(
    (s) => s.totalBytes <= 0 ? 0 : s.bytesTransferred / s.totalBytes,
  );

  @override
  Future<void> get done async {
    try {
      await _task;
    } on FirebaseException catch (e) {
      if (_canceled || e.code == 'canceled') throw const UploadCanceled();
      rethrow;
    }
    if (_canceled) throw const UploadCanceled();
  }

  @override
  Future<void> cancel() async {
    _canceled = true;
    try {
      await _task.cancel();
    } on Object {
      // Already finished or failed: [done] says which.
    }
  }
}

final assistantUploaderProvider = Provider<AssistantUploader>(
  (ref) => FirebaseAssistantUploader(),
);

/// Thumbnails of photos sent from this phone in this session, by attachment id (Storage Rules
/// give the app no read of the uploaded original). A few only; never persisted.
class AssistantPhotoCache {
  final _bytes = <String, Uint8List>{};

  Uint8List? operator [](String attachmentId) => _bytes[attachmentId];

  void put(String attachmentId, Uint8List bytes) {
    _bytes.remove(attachmentId);
    _bytes[attachmentId] = bytes;
    while (_bytes.length > 6) {
      _bytes.remove(_bytes.keys.first);
    }
  }
}

final assistantPhotoCacheProvider = Provider<AssistantPhotoCache>(
  (ref) => AssistantPhotoCache(),
);

/// The retention the person chose for a photo (D-075 #3 default: keep with the expense).
AttachmentRetention retentionFor({required bool keep}) => keep
    ? AttachmentRetention.keepWithRecord
    : AttachmentRetention.deleteAfterRead;
