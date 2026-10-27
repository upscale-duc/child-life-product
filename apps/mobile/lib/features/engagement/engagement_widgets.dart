import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/navigation.dart' show SafePush;
import '../../app/router.dart';
import '../../app/session.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_occasions.dart';
import 'engagement_repository.dart';

String engagementTitle(AppLocalizations l, String kind) => switch (kind) {
  'ENG-01' => l.engPending,
  'ENG-02' => l.engMilestone,
  'ENG-03' => l.engWeekly,
  'ENG-05' => l.engFamily,
  'ENG-06' => l.engLumi,
  _ => l.engTitle,
};

/// Both push and inbox open via the server resolver. No cached family route is trusted.
Future<bool> openEngagement(
  WidgetRef ref,
  String id, {
  String surface = 'in_app',
}) async {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) return false;
  final before = ref.read(sessionProvider);
  final owner = before is SessionSignedIn ? before.user.uid : null;
  final Map<String, dynamic> response;
  try {
    response = await actEngagement(ref, id, 'open', surface: surface);
  } on Object {
    // Expired, another account's, feature off or offline: callers show their "gone" toast.
    return false;
  }
  final session = ref.read(sessionProvider),
      babyId = response['babyId'],
      route = response['route'];
  if (session is! SessionSignedIn ||
      session.user.uid != owner ||
      route is! String ||
      babyId is! String ||
      session.membershipFor(babyId) == null) {
    return false;
  }
  ref.read(selectedBabyIdProvider.notifier).select(babyId);
  final allowed =
      route == Routes.autoSaveReview ||
      route == Routes.personalDay ||
      route == Routes.memories ||
      route.startsWith('${Routes.memoryStory}?occasion=') ||
      route.startsWith('${Routes.memories}?week=') ||
      route == Routes.notifications ||
      route == Routes.messages ||
      RegExp(r'^/memories/album/[A-Za-z0-9_-]{1,128}$').hasMatch(route) ||
      RegExp(r'^/story/[A-Za-z0-9_-]{1,128}$').hasMatch(route);
  if (!allowed) return false;
  final router = ref.read(routerProvider);
  // The Kỷ niệm tab root is switched to; any other page opens on top of the current one, so Back
  // returns to where the card was (owner, 2026-10-26: "Ảnh đang chờ chọn lưu" opened the review
  // and Back landed on Tự lưu instead of Kỷ niệm, because `go` rebuilt the stack).
  if (surface == 'in_app' && Uri.parse(route).path == Routes.memories) {
    router.go(route);
  } else if (surface == 'in_app') {
    unawaited(router.push<Object?>(route));
  } else {
    // From a push or the inbox: on top of what is showing, so Back returns there.
    unawaited(router.push<Object?>(router.notificationLocation(route)));
  }
  return true;
}

class EngagementShelf extends ConsumerStatefulWidget {
  const EngagementShelf({super.key});
  @override
  ConsumerState<EngagementShelf> createState() => _EngagementShelfState();
}

class _EngagementShelfState extends ConsumerState<EngagementShelf> {
  final seen = <String>{};
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        state = ref.watch(engagementProvider);
    // Keep what is showing while the list reloads. It reloads whenever the media count or Tự lưu
    // state changes (both change for a while after the app opens) and each reload waits up to a
    // minute to settle (doc 18 #20); drawing those reloads as "loading" hid the card and brought
    // it back later (owner, 2026-10-26: "chưa xem mà nó tự mất … mở app nó lại hiển thị rồi mất").
    return state.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const SizedBox.shrink(),
      // Only someone who already had the shelf sees "offline"; feature-off, an undeployed
      // callable or the refresh limit stay invisible.
      error: (_, _) => state.value?['enabled'] != true
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: ClSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.engOffline,
                      style: context.cl.text.caption.copyWith(
                        color: context.cl.colors.inkMuted,
                      ),
                    ),
                  ),
                  ClButton(
                    label: l.engRetry,
                    style: ClButtonStyle.plain,
                    // The person asked: reload now, past the background settling.
                    onPressed: () =>
                        ref.read(engagementRevisionProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
      data: (data) {
        if (data['enabled'] != true) return const SizedBox.shrink();
        final suggestions = List<Map>.from(
          data['suggestions'] as List? ?? const [],
        );
        // One retrospective suggestion leads the shelf; a user may choose any milestone in the creator.
        var historical = false;
        return Column(
          children: [
            for (final item in suggestions.where((i) {
              if (i['context'] != 'retrospective') return true;
              if (historical) return false;
              historical = true;
              return true;
            }))
              Builder(
                builder: (context) {
                  final id = '${item['id']}', kind = '${item['kind']}';
                  if (!seen.contains(id)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted &&
                          ModalRoute.of(context)?.isCurrent == true &&
                          (context.findRenderObject() is RenderBox) &&
                          ((context.findRenderObject()! as RenderBox)
                                  .localToGlobal(Offset.zero)
                                  .dy <
                              MediaQuery.sizeOf(context).height) &&
                          ((context.findRenderObject()! as RenderBox)
                                      .localToGlobal(Offset.zero)
                                      .dy +
                                  (context.findRenderObject()! as RenderBox)
                                      .size
                                      .height >
                              0) &&
                          seen.add(id)) {
                        unawaited(
                          actEngagement(
                            ref,
                            id,
                            'view',
                          ).catchError((_) => <String, dynamic>{}),
                        );
                      }
                    });
                  }
                  Future<void> action(String choice) async {
                    try {
                      if (choice == 'open') {
                        if (!await openEngagement(ref, id) && context.mounted) {
                          ClToaster.of(context).show(message: l.engExpired);
                        }
                      } else {
                        await actEngagement(ref, id, choice);
                      }
                    } catch (_) {
                      // AI-15: what did not happen, not "Chưa kiểm tra được gợi ý".
                      if (context.mounted) {
                        ClToaster.of(context).show(
                          message: choice == 'open'
                              ? l.engOpenFailed
                              : l.engActFailed,
                          error: true,
                        );
                      }
                    }
                  }

                  // D-120: one row like "Tự lưu kỷ niệm" above it (it was a Material Card with
                  // three text buttons and a sentence telling parents they decide). The card
                  // opens the suggestion; "Để sau" and "Bỏ qua gợi ý" sit behind "…".
                  final title = item['context'] == 'retrospective'
                      ? l.engBackfill
                      : engagementTitle(l, kind);
                  final occasion =
                      kind == 'ENG-02' && item['occasion'] is String
                      ? Occasion.fromWire(item['occasion'] as String)?.label(l)
                      : null;
                  final line = item['context'] == 'retrospective'
                      ? l.engBackfillBody
                      : occasion;
                  final cl = context.cl;
                  return Padding(
                    padding: const EdgeInsets.only(top: ClSpace.s3),
                    child: ClPressable(
                      onPressed: () => action('open'),
                      semanticLabel: [title, ?line].join('. '),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          ClSpace.s3,
                          10,
                          ClSpace.s1,
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.surface,
                          boxShadow: cl.shadows.card,
                          borderRadius: BorderRadius.circular(
                            ClRadius.card - 6,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cl.colors.mintSoft,
                                borderRadius: BorderRadius.circular(
                                  ClRadius.control,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: ClIcon(
                                kind == 'ENG-02'
                                    ? ClIcons.video
                                    : ClIcons.memories,
                                size: 16,
                                color: cl.colors.mintText,
                              ),
                            ),
                            const SizedBox(width: ClSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: cl.text.bodyStrong),
                                  if (line != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      line,
                                      style: cl.text.caption.copyWith(
                                        color: cl.colors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ClPressable(
                              key: Key('engMore_$id'),
                              onPressed: () async {
                                final choice = await showClSheet<String>(
                                  context: context,
                                  builder: (sheet) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ClSheetHeader(title: title),
                                      ClButton(
                                        label: kind == 'ENG-02'
                                            ? l.engChooseTemplate
                                            : l.engOpen,
                                        expand: true,
                                        onPressed: () =>
                                            Navigator.of(sheet).pop('open'),
                                      ),
                                      const SizedBox(height: ClSpace.s2),
                                      ClButton(
                                        label: l.engLater,
                                        style: ClButtonStyle.secondary,
                                        expand: true,
                                        onPressed: () =>
                                            Navigator.of(sheet).pop('snooze'),
                                      ),
                                      ClButton(
                                        label: l.engDismiss,
                                        style: ClButtonStyle.plain,
                                        expand: true,
                                        onPressed: () =>
                                            Navigator.of(sheet).pop('dismiss'),
                                      ),
                                    ],
                                  ),
                                );
                                if (choice != null) await action(choice);
                              },
                              semanticLabel: l.engMore,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Text(
                                    '•••',
                                    style: cl.text.label.copyWith(
                                      color: cl.colors.inkMuted,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
