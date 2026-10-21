import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import '../core/appearance/appearance_providers.dart';
import '../features/auto_save/auto_save_controller.dart';
import '../features/auto_save/auto_save_store.dart';
import '../features/engagement/engagement_repository.dart';
import '../features/memories/memory_repository.dart';
import '../features/memories/upload_queue.dart';
import '../features/premium/purchase_resume.dart';
import 'local_owner.dart';
import 'local_privacy_guard.dart';

/// A real container lifetime per account: invalidating a Notifier alone can reuse
/// its instance and captured stores. All asynchronous work stays in its UID scope.
class AccountLocalScope extends StatefulWidget {
  const AccountLocalScope({required this.uid, required this.child, super.key});
  final String? uid;
  final Widget child;
  @override
  State<AccountLocalScope> createState() => _AccountLocalScopeState();
}

class _AccountLocalScopeState extends State<AccountLocalScope> {
  List<Override>? _overrides;
  String? _owner;
  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    if (_overrides == null || _owner != uid) {
      _owner = uid;
      _overrides = [
        localOwnerProvider.overrideWithValue(uid),
        queueStoreProvider.overrideWith((ref) => FileQueueStore(owner: uid)),
        mediaPreparerProvider.overrideWith(
          (ref) => DeviceMediaPreparer(owner: uid),
        ),
        autoSaveStoreProvider.overrideWith(
          (ref) => AutoSaveStore(
            owner: uid,
            onCreated: ref.read(autoSaveNativeProvider).excludeFromBackup,
          ),
        ),
        resumeDraftsProvider.overrideWith(
          (ref) =>
              ResumeDrafts(ref.read(sharedPreferencesProvider), owner: uid),
        ),
        uploadQueueProvider.overrideWith(UploadQueue.new),
        autoSaveProvider.overrideWith(AutoSaveController.new),
        historyTailProvider.overrideWith(HistoryTailController.new),
        mediaProvider.overrideWith(
          (ref, key) => ref
              .read(memoryRepositoryProvider)
              .watchMedia(key.$1, parent: key.$2),
        ),
        memoriesProvider.overrideWith(
          (ref, key) => ref
              .read(memoryRepositoryProvider)
              .watchMemories(key.$1, parent: key.$2),
        ),
        completeMediaProvider.overrideWith(buildCompleteMedia),
        completeMemoriesProvider.overrideWith(buildCompleteMemories),
        engagementProvider.overrideWith(buildEngagement),
        localPrivacyGuardProvider.overrideWith(bindLocalPrivacy),
      ];
    }
    return ProviderScope(
      key: ValueKey(uid),
      overrides: _overrides!,
      child: _LocalLifetime(owner: uid, child: widget.child),
    );
  }
}

class _LocalLifetime extends ConsumerStatefulWidget {
  const _LocalLifetime({required this.owner, required this.child});
  final String? owner;
  final Widget child;
  @override
  ConsumerState<_LocalLifetime> createState() => _LocalLifetimeState();
}

class _LocalLifetimeState extends ConsumerState<_LocalLifetime> {
  AutoSaveStore? _faces;
  @override
  Widget build(BuildContext context) {
    if (widget.owner != null) _faces ??= ref.read(autoSaveStoreProvider);
    return widget.child;
  }

  @override
  void dispose() {
    // Drain the captured store's pending writes before removing private face data.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final faces = _faces;
    if (faces != null) unawaited(faces.clear().catchError((Object _) {}));
    super.dispose();
  }
}
