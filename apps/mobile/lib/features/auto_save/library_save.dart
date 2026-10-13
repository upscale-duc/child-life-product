import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

import 'auto_save_controller.dart';
import 'auto_save_native.dart';

/// "Tải về" (10f / 10b3): saves an original to the phone's library. On iOS it goes through
/// PhotoKit so the new item's id is recorded and Tự lưu never suggests a Child Life download
/// back (P-150); elsewhere through `gal` as before. Throws when it could not be saved.
Future<void> saveToLibrary(
  BuildContext context,
  File file, {
  required bool video,
  String? album,
}) async {
  if (!autoSaveSupported) {
    if (!await Gal.hasAccess(toAlbum: album != null)) {
      await Gal.requestAccess(toAlbum: album != null);
    }
    video
        ? await Gal.putVideo(file.path, album: album)
        : await Gal.putImage(file.path, album: album);
    return;
  }
  final container = ProviderScope.containerOf(context, listen: false);
  final id = await container
      .read(autoSaveNativeProvider)
      .save(file.path, video: video, album: album);
  if (id != null) {
    await container.read(autoSaveProvider.notifier).recordFromApp(id);
  }
}
