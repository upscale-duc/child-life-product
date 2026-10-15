import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../baby/baby_repository.dart' show babyProvider;
import '../home/home_shell.dart' show selectedBabyIdProvider;
import 'assistant_controller.dart' show assistantChatProvider;
import 'assistant_photos.dart';
import 'assistant_repository.dart';

/// Not decided yet (the session or the selected baby is still loading): nothing is cleared.
const assistantOwnerUnknown = '?';

/// Who the assistant state on this phone belongs to: `<uid>|<familyId>` of the selected baby
/// (`<uid>|` without one), null when signed out.
final assistantOwnerProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  switch (session) {
    case SessionLoading():
      return assistantOwnerUnknown;
    case SessionSignedOut():
      return null;
    case SessionSignedIn(:final user):
      final babyId = ref.watch(selectedBabyIdProvider);
      if (babyId == null) return '${user.uid}|';
      final baby = ref.watch(babyProvider(babyId));
      // A load error is not a family switch: wait for the baby.
      if (!baby.hasValue || baby.hasError) return assistantOwnerUnknown;
      return '${user.uid}|${baby.value?.familyId ?? ''}';
  }
});

/// The owner the stored assistant state was written for. Inside the store's `assistant.` prefix,
/// so clearing the store clears it too.
const assistantOwnerKey = 'assistant.owner';

/// Sign-out and family switch (CLAUDE.md security: no child data left on the device): this phone
/// forgets the assistant's kept inputs, open threads and task lists ([AssistantLocalStore]), the
/// photo thumbnails ([AssistantPhotoCache]) and every cached answer (chat, usage, snapshots,
/// CH08 sources). The owner is kept in preferences, so an account or family change while the app
/// was closed is caught on the next launch too. Watched once by the app root.
final assistantDeviceGuardProvider = Provider<void>((ref) {
  ref.listen<String?>(assistantOwnerProvider, (_, owner) {
    if (owner == assistantOwnerUnknown) return;
    unawaited(_settle(ref, owner));
  }, fireImmediately: true);
});

Future<void> _settle(Ref ref, String? owner) async {
  final String? stored;
  try {
    stored = ref.read(sharedPreferencesProvider).getString(assistantOwnerKey);
  } on Object {
    return; // No preferences (tests without them).
  }
  if (stored == owner) return;
  await forgetAssistantDevice(ref);
  if (owner != null) {
    await ref
        .read(sharedPreferencesProvider)
        .setString(assistantOwnerKey, owner);
  }
}

/// Everything the assistant keeps on this phone, gone (the server keeps the conversations).
Future<void> forgetAssistantDevice(Ref ref) async {
  ref.read(assistantPhotoCacheProvider).clear();
  ref.invalidate(assistantChatProvider);
  ref.invalidate(assistantUsageProvider);
  ref.invalidate(assistantTaskSnapshotProvider);
  ref.invalidate(summarySourcesProvider);
  await ref.read(assistantLocalStoreProvider).clearAll();
}
