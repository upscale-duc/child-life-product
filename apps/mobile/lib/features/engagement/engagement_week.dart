import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/route_guard.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import '../memories/media_viewer.dart';

final engagementWeekProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      final result = await ref
          .read(functionsProvider)
          .httpsCallable('actOnEngagement')
          .call<Object?>({'id': id, 'action': 'open', 'surface': 'in_app'});
      return Map<String, dynamic>.from(result.data as Map? ?? const {});
    });

/// The week is a source-authorized set of ready/saved ids, not a filter on capture dates.
class EngagementWeekScreen extends ConsumerWidget {
  const EngagementWeekScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context),
        week = ref.watch(engagementWeekProvider(id)),
        member = ref.watch(selectedMembershipProvider);
    if (member == null) {
      return MePage(title: l.engWeekly, children: [Text(l.engExpired)]);
    }
    return week.when(
      loading: () => MePage(
        title: l.engWeekly,
        children: const [ClSkeleton(height: 240, radius: 16)],
      ),
      error: (_, _) => MePage(
        title: l.engWeekly,
        children: [
          MeNotice(title: l.engOffline),
          ClButton(
            label: l.engRetry,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () => ref.invalidate(engagementWeekProvider(id)),
          ),
        ],
      ),
      data: (data) {
        if (data['babyId'] != member.babyId || data['state'] != 'ready') {
          return MePage(title: l.engWeekly, children: [Text(l.engExpired)]);
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
        return MePage(
          title: l.engWeekly,
          children: [
            if (items == null)
              const ClSkeleton(height: 240, radius: 16)
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
            for (final story in content['storyIds'] as List? ?? const [])
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
