import 'dart:async';
import 'dart:io';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/privacy/local_privacy.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/today/header_photo_cache.dart';
import 'package:child_life/features/today/header_settings.dart';
import 'package:child_life/features/today/living_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'preview does not replace the saved cache; Apply caches the new version',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final privacy = LocalPrivacy()
        ..bind(mai.uid, {teddyId}, coParents: {teddyId});
      final cache = HeaderPhotoCache(access: privacy);
      final bytes = (await rootBundle.load(
        'assets/premium/baby-newborn.jpg',
      )).buffer.asUint8List();
      await cache.remember(mai.uid, teddyId, 'memory:m1', 'old-source', bytes);
      final container = ProviderContainer(
        overrides: [
          ...familyOverrides(),
          sharedPreferencesProvider.overrideWithValue(prefs),
          headerPhotoCacheProvider.overrideWithValue(cache),
          babyProvider(teddyId).overrideWith(
            (ref) => Stream.value(
              Baby(
                id: teddy.id,
                familyId: teddy.familyId,
                ownerUid: teddy.ownerUid,
                nickname: teddy.nickname,
                avatar: const PhotoAvatar(2),
                trackers: teddy.trackers,
                timeZone: teddy.timeZone,
              ),
            ),
          ),
          babyAvatarPhotoProvider((
            teddyId,
            2,
          )).overrideWith((ref) async => bytes),
        ],
      );
      addTearDown(container.dispose);
      const saved = HeaderSettings(
        background: HeaderBackground.memory,
        mediaId: 'm1',
      );
      const draft = HeaderSettings(background: HeaderBackground.avatar);
      await container.read(headerSettingsProvider.notifier).save(saved);
      final preview = container.listen(headerPhotoProvider(draft), (_, _) {});
      addTearDown(preview.close);
      await container.read(babyProvider(teddyId).future);
      await container.read(babyAvatarPhotoProvider((teddyId, 2)).future);
      expect(container.read(headerPhotoProvider(draft)), isA<MemoryImage>());
      expect(cache.read(mai.uid, teddyId, 'memory:m1'), isNotNull);
      expect(cache.read(mai.uid, teddyId, 'avatar:'), isNull);
      await container.read(headerSettingsProvider.notifier).save(draft);
      expect(container.read(headerPhotoProvider(draft)), isA<MemoryImage>());
      await cache.flush();
      expect(cache.read(mai.uid, teddyId, 'avatar:')?.source, 'avatar:2');
    },
  );

  test(
    'cold launch hydrates and decodes the chosen image without any network',
    () async {
      final dir = await Directory.systemTemp.createTemp('header-photo');
      addTearDown(() => dir.delete(recursive: true));
      SharedPreferences.setMockInitialValues({'today.selectedBabyId': teddyId});
      final prefs = await SharedPreferences.getInstance();
      final privacy = LocalPrivacy()
        ..bind(mai.uid, {teddyId}, coParents: {teddyId});
      final bytes = (await rootBundle.load(
        'assets/premium/baby-newborn.jpg',
      )).buffer.asUint8List();
      final first = HeaderPhotoCache(
        preferences: prefs,
        directory: dir,
        access: privacy,
      );
      await first.remember(mai.uid, teddyId, 'avatar:', 'avatar:2', bytes);
      PaintingBinding.instance.imageCache.clear();
      final restarted = await HeaderPhotoCache.open(
        prefs,
        uid: mai.uid,
        directory: dir,
        access: privacy,
      );
      final image = restarted.read(mai.uid, teddyId, 'avatar:')!.image;
      expect(image.bytes, bytes);
      final key = await image.obtainKey(ImageConfiguration.empty);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(key).keepAlive,
        isTrue,
      );
      expect(restarted.read(mai.uid, 'other-baby', 'avatar:'), isNull);
      expect(restarted.read('other-account', teddyId, 'avatar:'), isNull);
      expect(restarted.read(mai.uid, teddyId, 'memory:other'), isNull);
      privacy.bind(mai.uid, {
        teddyId,
      }); // restricted role: no persistent photo reads
      expect(restarted.read(mai.uid, teddyId, 'avatar:'), isNull);
      privacy.bind(null, {});
      expect(restarted.read(mai.uid, teddyId, 'avatar:'), isNull);
    },
  );

  test(
    'corrupt/missing cache is recoverable; forgetting removes the index and image',
    () async {
      final dir = await Directory.systemTemp.createTemp('header-photo');
      addTearDown(() => dir.delete(recursive: true));
      SharedPreferences.setMockInitialValues({'today.selectedBabyId': teddyId});
      final prefs = await SharedPreferences.getInstance();
      final privacy = LocalPrivacy()
        ..bind(mai.uid, {teddyId}, coParents: {teddyId});
      final cache = HeaderPhotoCache(
        preferences: prefs,
        directory: dir,
        access: privacy,
      );
      await cache.remember(
        mai.uid,
        teddyId,
        'avatar:',
        'avatar:1',
        Uint8List.fromList([1, 2, 3]),
      );
      final restarted = await HeaderPhotoCache.open(
        prefs,
        uid: mai.uid,
        directory: dir,
        access: privacy,
      );
      expect(restarted.read(mai.uid, teddyId, 'avatar:'), isNull);
      expect(prefs.getString('today.header.cache.${mai.uid}.$teddyId'), isNull);
      expect(await restarted.load(mai.uid, teddyId), isNull);
      await cache.forgetAccount(mai.uid);
      expect(cache.read(mai.uid, teddyId, 'avatar:'), isNull);
    },
  );

  for (final background in [HeaderBackground.avatar, HeaderBackground.memory]) {
    test(
      'saved ${background.name} is available synchronously while metadata waits; known removal wins',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final privacy = LocalPrivacy()
          ..bind(mai.uid, {teddyId}, coParents: {teddyId});
        final cache = HeaderPhotoCache(access: privacy);
        final settings = HeaderSettings(
          background: background,
          mediaId: background == HeaderBackground.memory ? 'm1' : null,
        );
        final choice = '${background.name}:${settings.mediaId ?? ''}';
        final bytes = (await rootBundle.load(
          'assets/premium/baby-newborn.jpg',
        )).buffer.asUint8List();
        await cache.remember(
          mai.uid,
          teddyId,
          choice,
          background == HeaderBackground.avatar
              ? 'avatar:1'
              : 'babies/$teddyId/media/m1/photo.jpg',
          bytes,
        );
        final babies = StreamController<Baby?>();
        final media = StreamController<List<MediaItem>>();
        final container = ProviderContainer(
          overrides: [
            ...familyOverrides(),
            sharedPreferencesProvider.overrideWithValue(prefs),
            headerPhotoCacheProvider.overrideWithValue(cache),
            if (background == HeaderBackground.avatar)
              babyProvider(teddyId).overrideWith((ref) => babies.stream)
            else
              mediaProvider((
                teddyId,
                true,
              )).overrideWith((ref) => media.stream),
          ],
        );
        addTearDown(() async {
          container.dispose();
          if (background == HeaderBackground.avatar) await babies.close();
          if (background == HeaderBackground.memory) await media.close();
        });
        await container.read(headerSettingsProvider.notifier).save(settings);
        final subscription = container.listen(
          headerPhotoProvider(settings),
          (_, _) {},
        );
        addTearDown(subscription.close);
        expect(
          container.read(headerPhotoProvider(settings)),
          same(cache.read(mai.uid, teddyId, choice)!.image),
        );
        if (background == HeaderBackground.avatar) {
          babies.add(teddy); // known preset, so the cached photo must disappear
          await container.read(babyProvider(teddyId).future);
        } else {
          media.add([]); // deleted/revoked/not in the visible media list
          await container.read(mediaProvider((teddyId, true)).future);
        }
        await container.pump();
        expect(container.read(headerPhotoProvider(settings)), isNull);
        expect(cache.read(mai.uid, teddyId, choice), isNull);
      },
    );
  }
}
