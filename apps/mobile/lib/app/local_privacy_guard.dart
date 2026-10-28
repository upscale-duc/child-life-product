import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../core/appearance/appearance_providers.dart';
import '../core/privacy/local_privacy.dart';
import '../features/auto_save/auto_save_controller.dart';
import '../features/auto_save/auto_save_native.dart';
import '../features/baby/baby_repository.dart';
import '../features/baby/baby_models.dart';
import '../features/auth/auth_repository.dart';
import '../features/care/care_repository.dart' show careClockProvider;
import '../features/memories/background_uploads.dart';
import '../features/memories/memory_repository.dart';
import '../features/memories/upload_queue.dart';
import '../features/premium/purchase_resume.dart';
import '../features/today/header_photo_cache.dart';
import 'session.dart';

/// FAM-01: bind before rendering child UI, including remote revocation/account changes.
final localPrivacyGuardProvider = Provider<int>(bindLocalPrivacy);

int bindLocalPrivacy(Ref ref) {
  ref.watch(careClockProvider.select((v) => v.value?.minute));
  final session = ref.watch(sessionProvider);
  if (session is SessionLoading) {
    final authUid = ref.watch(authUserProvider).value?.uid;
    if (authUid != localPrivacy.owner) {
      final prefs = ref.read(sharedPreferencesProvider);
      // The in-memory owner is null on every cold launch; the persisted owner says
      // whether the account really changed. Same account: keep native uploads,
      // the auto-save schedule and purchase-resume drafts (MO03/M17).
      final previous = localPrivacy.owner ?? prefs.getString('privacy.owner');
      localPrivacy.bind(authUid, {});
      if (previous != null && previous != authUid) {
        unawaited(prefs.remove('privacy.backgroundUntil'));
        unawaited(BackgroundTransport.cancelDeviceWork());
        unawaited(AutoSaveNative().unschedule());
        unawaited(ResumeDrafts(prefs, owner: previous).clearAll());
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      }
    }
    return localPrivacy.generation;
  }
  final uid = session is SessionSignedIn ? session.user.uid : null;
  final allowed = session is SessionSignedIn
      ? {for (final m in session.active) m.babyId}
      : <String>{};
  final prefs = ref.read(sharedPreferencesProvider);
  // The persisted owner is the last fully bound account: the loading branch above
  // already binds the new auth uid in memory, so it cannot tell an account change.
  final previous = prefs.getString('privacy.owner') ?? localPrivacy.owner;
  final removed = localPrivacy.babies.difference(allowed);
  final parents = session is SessionSignedIn
      ? {
          for (final m in session.active)
            if (m.role == MemberRole.coParent) m.babyId,
        }
      : <String>{};
  final policies = session is SessionSignedIn
      ? {
          for (final m in session.active)
            m.babyId: '${m.role.name}|${m.extraRights.toJson()}',
        }
      : <String, String>{};
  final restricted = localPrivacy.parents.difference(parents)
    ..addAll({
      for (final old in localPrivacy.policies.entries)
        if (policies[old.key] != old.value) old.key,
    });
  localPrivacy.bind(
    uid,
    allowed,
    coParents: parents,
    permissions: policies,
    until: session is SessionSignedIn
        ? {
            for (final m in session.active)
              if (m.accessUntilAt != null) m.babyId: m.accessUntilAt!,
          }
        : {},
  );
  if (uid == null) {
    unawaited(prefs.remove('privacy.owner'));
    unawaited(prefs.remove('privacy.backgroundUntil'));
  } else {
    // This rebuilds every minute (the lease below): write only what changed.
    if (prefs.getString('privacy.owner') != uid) {
      unawaited(prefs.setString('privacy.owner', uid));
    }
    // Headless checks cannot refresh authorization. Expire their local lease, also
    // bounded by each membership's access expiry below.
    var until = DateTime.now().add(const Duration(hours: 24));
    if (session is SessionSignedIn) {
      for (final m in session.active) {
        if (m.accessUntilAt != null && m.accessUntilAt!.isBefore(until)) {
          until = m.accessUntilAt!;
        }
      }
    }
    // Extend the lease at most every 15 minutes; shorten it (a nearer expiry) at once.
    final current = prefs.getInt('privacy.backgroundUntil');
    final next = until.millisecondsSinceEpoch;
    if (current == null ||
        next < current ||
        next - current >= const Duration(minutes: 15).inMilliseconds) {
      unawaited(prefs.setInt('privacy.backgroundUntil', next));
    }
  }
  Future<void> cleanup() async {
    if (localPrivacy.owner == null) {
      await prefs.remove('privacy.owner');
      await prefs.remove('privacy.backgroundUntil');
    }
    // Await native cancellation before another account can use its stores.
    await BackgroundTransport.cancelDeviceWork();
    await AutoSaveNative().unschedule();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (previous != null) {
      for (final key
          in prefs
              .getKeys()
              .where(
                (k) =>
                    k.startsWith('care.quickAmounts.$previous.') ||
                    k.startsWith('premium.prices.$previous.') ||
                    k.startsWith('engagement.pending.$previous.') ||
                    k.startsWith('engagement.owns.$previous.') ||
                    k.startsWith('engagement.handoff.$previous.') ||
                    k == 'engagement.backgroundParents.$previous',
              )
              .toList()) {
        if (previous != uid ||
            [...removed, ...restricted].any((baby) => key.contains('.$baby'))) {
          await prefs.remove(key);
        }
      }
      final support = await getApplicationSupportDirectory();
      final faces = Directory(
        '${support.path}/accounts/${Uri.encodeComponent(previous)}/auto_save',
      );
      try {
        if (await faces.exists()) await faces.delete(recursive: true);
      } on FileSystemException {
        /* Another account-scope cleanup may have removed it. */
      }
      await ResumeDrafts(prefs, owner: previous).clearAll();
    }
  }

  // Legacy stores have no provable owner. Never silently assign them to a
  // freshly signed-in account: remove unowned biometrics/cache, retain unsent
  // uploads in a quarantine with no automatic reader.
  if (prefs.getBool('privacy.migratedV2') != true) {
    unawaited(
      () async {
        await BackgroundTransport.cancelDeviceWork();
        await AutoSaveNative().unschedule();
        final support = await getApplicationSupportDirectory();
        final cache = await getApplicationCacheDirectory();
        for (final path in [
          '${support.path}/auto_save',
          '${cache.path}/media',
        ]) {
          final dir = Directory(path);
          if (await dir.exists()) await dir.delete(recursive: true);
        }
        final quarantine = Directory('${support.path}/legacy-unowned');
        await quarantine.create(recursive: true);
        for (final name in ['upload_queue.json', 'uploads']) {
          final path = '${support.path}/$name';
          if (await FileSystemEntity.type(path) ==
              FileSystemEntityType.directory) {
            await Directory(path).rename('${quarantine.path}/$name');
          } else if (await File(path).exists()) {
            await File(path).rename('${quarantine.path}/$name');
          }
        }
        for (final key in prefs.getKeys().where(
          (k) => k.startsWith('premium.draft.') && k.split('.').length == 3,
        )) {
          await prefs.remove(key);
        }
        await prefs.setBool('privacy.migratedV2', true);
      }().catchError((Object _) {
        // Keep the marker unset: retry next launch, without ever reading legacy data.
      }),
    );
  }
  localPrivacy.cleanup = cleanup;
  if (previous != uid) {
    if (previous != null) {
      unawaited(ref.read(headerPhotoCacheProvider).forgetAccount(previous));
    }
    ref.invalidate(babyRepositoryProvider);
    ref.invalidate(babyAvatarPhotoProvider);
    ref.invalidate(uploadQueueProvider);
    ref.invalidate(autoSaveProvider);
    ref.invalidate(historyTailProvider);
    ref.invalidate(mediaProvider);
    ref.invalidate(memoriesProvider);
    ref.invalidate(familyMilestonesProvider);
    unawaited(cleanup());
  }
  if ((removed.isNotEmpty || restricted.isNotEmpty) && previous == uid) {
    ref.invalidate(historyTailProvider);
    // Cancel/persist only the revoked baby's work; other babies retain their queue.
    unawaited(() async {
      await BackgroundTransport.cancelDeviceWork();
      for (final id in {...removed, ...restricted}) {
        await ref.read(headerPhotoCacheProvider).forget(uid!, id);
        await ref.read(uploadQueueProvider.notifier).forgetBaby(id);
        await ref.read(autoSaveProvider.notifier).removeBaby(id);
        ref.read(babyRepositoryProvider).forgetBaby(id);
        final cache = Directory(
          '${(await getApplicationCacheDirectory()).path}/media-v2/${Uri.encodeComponent(uid)}',
        );
        if (await cache.exists()) {
          await for (final file in cache.list()) {
            if (file is File &&
                file.uri.pathSegments.last.startsWith('babies_${id}_')) {
              await file.delete();
            }
          }
        }
        ref.invalidate(mediaProvider((id, true)));
        ref.invalidate(mediaProvider((id, false)));
        ref.invalidate(memoriesProvider((id, true)));
        ref.invalidate(memoriesProvider((id, false)));
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }());
  }
  return localPrivacy.generation;
}
