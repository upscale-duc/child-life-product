import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../app/route_guard.dart';
import '../../core/widgets/cl_feedback.dart';
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
  if (surface == 'in_app') {
    router.go(route);
  } else {
    // From a push or the inbox: on top of what is showing, so Back returns there.
    unawaited(router.push<Object?>(route));
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
    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox.shrink(),
      // Only someone who already had the shelf sees "offline"; feature-off, an undeployed
      // callable or the refresh limit stay invisible.
      error: (_, _) => state.value?['enabled'] != true
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(l.engOffline)),
                  TextButton(
                    // The person asked: reload now, past the background settling.
                    onPressed: () =>
                        ref.read(engagementRevisionProvider.notifier).refresh(),
                    child: Text(l.engRetry),
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
                      if (context.mounted) {
                        ClToaster.of(context).show(message: l.engOffline);
                      }
                    }
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['context'] == 'retrospective'
                                ? l.engBackfill
                                : engagementTitle(l, kind),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (kind == 'ENG-02' && item['occasion'] is String)
                            Text(
                              Occasion.fromWire(
                                    item['occasion'] as String,
                                  )?.label(l) ??
                                  '',
                            ),
                          Text(
                            item['context'] == 'retrospective'
                                ? l.engBackfillBody
                                : l.engBody,
                          ),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: () => action('open'),
                                child: Text(
                                  kind == 'ENG-02'
                                      ? l.engChooseTemplate
                                      : l.engOpen,
                                ),
                              ),
                              TextButton(
                                onPressed: () => action('snooze'),
                                child: Text(l.engLater),
                              ),
                              TextButton(
                                onPressed: () => action('dismiss'),
                                child: Text(l.engDismiss),
                              ),
                            ],
                          ),
                        ],
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

class EngagementPreferencesPanel extends ConsumerWidget {
  const EngagementPreferencesPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context),
        data = ref.watch(engagementProvider).value;
    if (data?['enabled'] != true) return const SizedBox.shrink();
    final fatigue = Map<String, dynamic>.from(
      data?['fatigue'] as Map? ?? const {},
    );
    final prefs = Map<String, dynamic>.from(
          data?['preferences'] as Map? ?? const {},
        ),
        kinds = Map<String, dynamic>.from(prefs['kinds'] as Map? ?? const {});
    Future<void> save(Map<String, Object?> change) async {
      try {
        await ref
            .read(functionsProvider)
            .httpsCallable('setEngagementPreferences')
            .call<Object?>(change);
        ref.invalidate(engagementProvider);
      } catch (_) {
        if (context.mounted) ClToaster.of(context).show(message: l.engOffline);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.engTitle, style: Theme.of(context).textTheme.titleMedium),
        Text(l.engSettingsHint),
        if (fatigue['paused'] == true) Text(l.engPaused),
        SwitchListTile(
          title: Text(l.engConsent),
          value: prefs['consent'] == true,
          onChanged: (v) => save({
            'preferences': {'consent': v, 'kinds': kinds},
          }),
        ),
        for (final kind in ['ENG-01', 'ENG-02', 'ENG-03', 'ENG-05', 'ENG-06'])
          SwitchListTile(
            title: Text(engagementTitle(l, kind)),
            value: kinds[kind] == true,
            onChanged: (v) => save({
              'preferences': {
                'consent': prefs['consent'] == true,
                'kinds': {...kinds, kind: v},
              },
            }),
          ),
        TextButton(
          onPressed:
              fatigue['paused'] == true &&
                  (fatigue['pausedUntil'] as num? ?? 0) >
                      DateTime.now().millisecondsSinceEpoch
              ? null
              : () => save({'resume': true}),
          child: Text(l.engResume),
        ),
      ],
    );
  }
}
