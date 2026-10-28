import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/privacy/local_privacy.dart';
import '../memories/media_bytes.dart';

final headerPhotoCacheProvider = Provider<HeaderPhotoCache>(
  (ref) => HeaderPhotoCache(),
);

/// Disk cache follows media-v2's existing account/baby purge and co-parent policy.
/// The selected image is hydrated and decoded before runApp; reads remain gated
/// by the current membership, including after revocation or account changes.
class HeaderPhotoCache {
  HeaderPhotoCache({
    SharedPreferences? preferences,
    this.directory,
    LocalPrivacy? access,
  }) : _prefs = preferences,
       _privacy = access ?? localPrivacy;

  final SharedPreferences? _prefs;
  final Directory? directory;
  final LocalPrivacy _privacy;
  final _photos = <(String, String), CachedHeaderPhoto>{};
  final _revisions = <(String, String), int>{};
  Future<void> _writes = Future.value();
  Future<void> flush() => _writes;

  static Future<HeaderPhotoCache> open(
    SharedPreferences prefs, {
    String? uid,
    Directory? directory,
    LocalPrivacy? access,
  }) async {
    final cache = HeaderPhotoCache(
      preferences: prefs,
      directory: directory ?? await getApplicationCacheDirectory(),
      access: access,
    );
    if (uid != null) {
      final selected = prefs.getString('today.selectedBabyId');
      final babies = selected != null
          ? [selected]
          : prefs
                .getKeys()
                .where((k) => k.startsWith('today.header.cache.$uid.'))
                .map((k) => k.substring('today.header.cache.$uid.'.length));
      for (final baby in babies) {
        final photo = await cache.load(uid, baby);
        if (photo != null && !await _decode(photo.image)) {
          await cache.forget(uid, baby);
        }
      }
    }
    return cache;
  }

  static String _key(String uid, String baby) =>
      'today.header.cache.$uid.$baby';

  File _file(String uid, String baby, String choice, String source) {
    final hash = sha256.convert(utf8.encode('$choice|$source'));
    return File(
      '${directory!.path}/media-v2/${Uri.encodeComponent(uid)}/'
      'babies_${baby}_header_$hash',
    );
  }

  int _authorize(String uid, String baby) {
    final epoch = _privacy.authorize(uid, 'babies/$baby/avatar');
    if (!_privacy.parents.contains(baby)) throw StateError('not-cacheable');
    return epoch;
  }

  CachedHeaderPhoto? read(String uid, String baby, String choice) {
    try {
      _authorize(uid, baby);
      final photo = _photos[(uid, baby)];
      return photo?.choice == choice ? photo : null;
    } on StateError {
      return null;
    }
  }

  /// Hydration may precede the session. Only [read] exposes an authorized image.
  Future<CachedHeaderPhoto?> load(String uid, String baby) async {
    if (_photos[(uid, baby)] case final photo?) return photo;
    final raw = _prefs?.getString(_key(uid, baby));
    if (raw == null || directory == null) return null;
    final revision = _revisions[(uid, baby)];
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final choice = data['choice'] as String;
      final source = data['source'] as String;
      final file = _file(uid, baby, choice, source);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || _revisions[(uid, baby)] != revision) return null;
      // An image arriving from the network while disk loads always wins.
      return _photos.putIfAbsent((
        uid,
        baby,
      ), () => CachedHeaderPhoto(choice, source, bytes));
    } on Object {
      // A purged/corrupt cache never blocks startup or the normal photo loader.
      return null;
    }
  }

  Future<void> remember(
    String uid,
    String baby,
    String choice,
    String source,
    Uint8List bytes,
  ) async {
    final epoch = _authorize(uid, baby);
    final previous = _photos[(uid, baby)];
    if (previous?.choice == choice &&
        previous?.source == source &&
        listEquals(previous?.image.bytes, bytes)) {
      return;
    }
    final photo = CachedHeaderPhoto(choice, source, bytes);
    _photos[(uid, baby)] = photo;
    if (directory == null || _prefs == null) return;
    final write = _writes.then((_) async {
      if (!identical(_photos[(uid, baby)], photo)) return;
      _privacy.check(epoch);
      final file = _file(uid, baby, choice, source);
      final part = File('${file.path}.part');
      try {
        await file.parent.create(recursive: true);
        await part.writeAsBytes(bytes, flush: true);
        _privacy.check(epoch);
        _authorize(uid, baby);
        if (!identical(_photos[(uid, baby)], photo)) return;
        await part.rename(file.path);
        _privacy.check(epoch);
        await _prefs.setString(
          _key(uid, baby),
          jsonEncode({'choice': choice, 'source': source}),
        );
        if (previous != null &&
            (previous.source != source || previous.choice != choice)) {
          final old = _file(uid, baby, previous.choice, previous.source);
          if (await old.exists()) await old.delete();
        }
      } finally {
        if (await part.exists()) await part.delete();
      }
    });
    _writes = write.catchError((Object _) {});
    await write;
  }

  Future<void> forget(String uid, String baby) async {
    _revisions[(uid, baby)] = (_revisions[(uid, baby)] ?? 0) + 1;
    final old = _photos.remove((uid, baby));
    await _prefs?.remove(_key(uid, baby));
    if (old != null && directory != null) {
      final file = _file(uid, baby, old.choice, old.source);
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // A concurrent membership purge can remove it first.
      }
    }
  }

  Future<void> forgetAccount(String uid) async {
    final babies = {
      for (final key in _photos.keys)
        if (key.$1 == uid) key.$2,
      for (final key in _prefs?.getKeys() ?? <String>{})
        if (key.startsWith('today.header.cache.$uid.'))
          key.substring('today.header.cache.$uid.'.length),
    };
    for (final baby in babies) {
      await forget(uid, baby);
    }
  }

  static Future<bool> _decode(ImageProvider image) async {
    final done = Completer<bool>();
    final stream = image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    void finish(bool valid) {
      stream.removeListener(listener);
      if (!done.isCompleted) done.complete(valid);
    }

    listener = ImageStreamListener((info, _) {
      info.dispose();
      finish(true);
    }, onError: (_, _) => finish(false));
    stream.addListener(listener);
    return done.future;
  }
}

class CachedHeaderPhoto {
  CachedHeaderPhoto(this.choice, this.source, Uint8List bytes)
    : image = MemoryImage(bytes);
  final String choice;
  final String source;
  final MemoryImage image;
}

final headerCachedPhotoProvider = FutureProvider.family<void, (String, String)>(
  (ref, key) async {
    await ref.watch(headerPhotoCacheProvider).load(key.$1, key.$2);
  },
);

final headerMemoryBytesProvider = FutureProvider.family<Uint8List, String>(
  (ref, path) => mediaBytes.read(path),
);
