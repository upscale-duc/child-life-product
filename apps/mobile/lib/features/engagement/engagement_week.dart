import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/route_guard.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import '../memories/media_viewer.dart';

final engagementWeekProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) async {
        final result = await ref
            .read(functionsProvider)
            .httpsCallable('actOnEngagement')
            .call<Object?>({'id': id, 'action': 'open', 'surface': 'in_app'});
        return Map<String, dynamic>.from(result.data as Map? ?? const {});
      },
      // AI-15: an error shows at once ("Thử lại" or expired), not a skeleton through retries.
      retry: (_, _) => null,
    );

/// The week is a source-authorized set of ready/saved ids, not a filter on capture dates.
class EngagementWeekScreen extends ConsumerWidget {
  const EngagementWeekScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context),
        week = ref.watch(engagementWeekProvider(id)),
        member = ref.watch(selectedMembershipProvider);
    // AI-15: an expired recap, or one for another account or child, is said so once; only a
    // network or server failure offers "Thử lại" (it was a retry loop for every error).
    final expired = MePage(
      title: l.engWeekly,
      children: [MeNotice(icon: ClIcons.clock, title: l.engExpired)],
    );
    if (member == null) return expired;
    Widget failed(String title, VoidCallback retry) => MeNotice(
      icon: ClIcons.alert,
      tone: MeTone.error,
      title: title,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClButton(
          label: l.engRetry,
          style: ClButtonStyle.plain,
          onPressed: retry,
        ),
      ),
    );
    return week.when(
      loading: () => MePage(
        title: l.engWeekly,
        children: const [ClSkeleton(height: 240, radius: 16)],
      ),
      error: (e, _) =>
          e is FirebaseFunctionsException &&
              const {
                'permission-denied',
                'not-found',
                'invalid-argument',
                'unauthenticated',
              }.contains(e.code)
          ? expired
          : MePage(
              title: l.engWeekly,
              children: [
                failed(
                  l.engWeekFailed,
                  () => ref.invalidate(engagementWeekProvider(id)),
                ),
              ],
            ),
      data: (data) {
        if (data['babyId'] != member.babyId || data['state'] != 'ready') {
          return expired;
        }
        final content = Map<String, dynamic>.from(
              data['content'] as Map? ?? const {},
            ),
            ids = Set<String>.from(content['mediaIds'] as List? ?? const []);
        final media = ref.watch(
          completeMediaProvider((
            member.babyId,
            member.role.name == 'coParent',
          )),
        );
        final items = media.value
            ?.where((m) => ids.contains(m.id) && m.isReady && !m.deleted)
            .toList();
        final stories = content['storyIds'] as List? ?? const [];
        final key = (member.babyId, member.role.name == 'coParent');
        return MePage(
          title: l.engWeekly,
          children: [
            // AI-15: the photos failing to load say so; never an endless skeleton.
            if (items == null && media.hasError)
              failed(
                l.engWeekMediaFailed,
                () => ref.invalidate(completeMediaProvider(key)),
              )
            else if (items == null)
              const ClSkeleton(height: 240, radius: 16)
            // Nothing left of the week (deleted since): said so, not a blank page.
            else if (items.isEmpty && stories.isEmpty)
              MeNotice(icon: ClIcons.memories, title: l.engWeekEmpty)
            else if (items.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, n) => MediaTile(
                  item: items[n],
                  onTap: () => openViewer(context, items: items, start: n),
                ),
              ),
            for (final story in stories)
              ClButton(
                label: l.engOpen,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () =>
                    ref.read(routerProvider).push('${Routes.story}/$story'),
              ),
          ],
        );
      },
    );
  }
}
