import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import 'media_picker.dart';
import 'memories_screen.dart';
import 'memory_sheets.dart';

/// The camera and photo-library widgets (owner request 2026-10-11): `/memories?add=camera` or
/// `?add=library` opens Kỷ niệm, then the camera (photo or video) or the library, then the
/// usual "Soạn & chia sẻ" (10h). Only Cùng nuôi add memories.
enum QuickAdd { camera, library }

/// What a widget link asks for, or null.
QuickAdd? quickAddRequest(Uri uri) {
  if (uri.path != Routes.memories) return null;
  return QuickAdd.values.asNameMap()[uri.queryParameters['add']];
}

/// [memoryCtx] outside a build (reads, no watches).
MemoryCtx? memoryCtxNow(BuildContext context, WidgetRef ref) {
  final me = ref.read(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.read(babyProvider(me.babyId)).value;
  final isParent = me.role == MemberRole.coParent;
  final view = ref.read(memoryViewProvider);
  return MemoryCtx(
    me: me,
    baby: baby,
    zone: baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
    dob: me.canViewBabyInfo
        ? ref.read(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
        : null,
    isParent: isParent,
    parentView: isParent && !view.asRelative,
    now: ref.read(careClockProvider).value ?? DateTime.now(),
    locale: Localizations.localeOf(context).toLanguageTag(),
  );
}

/// A context inside the root navigator's overlay. The navigator's own context has no Overlay
/// above it, and the pickers, sheets and toasts need one (a link may arrive on a cold start,
/// before any screen of ours is at hand).
BuildContext? _insideOverlay(GoRouter router) {
  final overlay = router.routerDelegate.navigatorKey.currentState?.overlay;
  if (overlay == null || !overlay.mounted) return null;
  BuildContext? child;
  overlay.context.visitChildElements((e) => child ??= e);
  return child;
}

/// Runs the camera or library and opens compose with what came back.
Future<void> openQuickAdd(
  GoRouter router,
  WidgetRef ref,
  QuickAdd source,
) async {
  final context = _insideOverlay(router);
  if (context == null || !context.mounted) return;
  final c = memoryCtxNow(context, ref);
  if (c == null || !c.isParent) return;
  final picked = source == QuickAdd.camera
      ? await captureWithCamera(context, c.nickname)
      : await pickFromLibrary(context, ref);
  if (picked == null || picked.isEmpty || !context.mounted) return;
  await showComposeSheet(context, ref, c, picked);
}
