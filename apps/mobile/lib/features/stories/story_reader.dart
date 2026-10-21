import 'dart:async';
import '../engagement/engagement_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../memories/album_models.dart';
import '../memories/media_viewer.dart';
import '../memories/memories_screen.dart';
import '../memories/memory_models.dart';
import '../memories/social_widgets.dart';
import 'share_screens.dart';
import 'story_editor.dart';
import 'story_models.dart';
import 'story_repository.dart';
import 'story_widgets.dart';

/// 14g "Câu chuyện đã lưu" (parents: Sửa, Chia sẻ, names who loved it) and 11i (relatives:
/// Thương and "Nhắn ba mẹ…"). Photos open in the viewer.
class StoryReaderScreen extends ConsumerWidget {
  const StoryReaderScreen({required this.storyId, super.key});
  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref);
    final s = c == null
        ? null
        : ref.watch(storyProvider((c.babyId, storyId))).value;
    if (c == null || s == null) {
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        unawaited(engagementContentViewed(ref, c.babyId, 'story', storyId));
      }
    });
    final parent = c.me.role == MemberRole.coParent;
    final media = storyMedia(ref, c.babyId, parent);
    final locale = c.locale;
    final when = storyWhen(
      l10n,
      c.zone,
      c.now,
      s.savedAt ?? s.updatedAt,
      locale,
    );
    final who = storyAuthor(l10n, s, c.me.uid);
    final meta = parent
        ? l10n.sryMetaSaved(
            who,
            when,
            s.audience == Audience.family ? l10n.audFamily : l10n.audParents,
          )
        : l10n.sryRelMeta(who, when);
    final photos = [
      for (final id in s.mediaIds)
        if (media[id] != null) media[id]!,
    ];
    void view(String id) => openViewer(
      context,
      items: photos,
      start: photos.indexWhere((m) => m.id == id),
    );

    final children = storyBlockWidgets(
      context,
      s,
      media,
      locale: locale,
      onView: view,
    );

    return Scaffold(
      backgroundColor: s.kind == StoryKind.letter
          ? storyPaper(context)
          : cl.colors.cloud,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    if (s.kind == StoryKind.story)
                      AspectRatio(
                        aspectRatio: storyCoverRatio(media[s.coverMediaId]),
                        child: ClPressable(
                          onPressed:
                              s.coverMediaId == null ||
                                  media[s.coverMediaId] == null
                              ? null
                              : () => view(s.coverMediaId!),
                          child: StoryImage(
                            item: media[s.coverMediaId],
                            display: true,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: MediaQuery.paddingOf(context).top + 64),
                    Positioned(
                      left: ClSpace.s4,
                      right: ClSpace.s4,
                      top: MediaQuery.paddingOf(context).top + ClSpace.s2,
                      child: Row(
                        children: [
                          _Round(
                            icon: ClIcons.back,
                            label: l10n.a11yBack,
                            onTap: () => context.pop(),
                          ),
                          const Spacer(),
                          if (parent) ...[
                            ClButton(
                              label: l10n.actionEdit,
                              icon: ClIcons.edit,
                              style: ClButtonStyle.secondary,
                              onPressed: () =>
                                  context.push('${Routes.story}/${s.id}/edit'),
                            ),
                            const SizedBox(width: 6),
                            ClButton(
                              label: l10n.sryShare,
                              icon: ClIcons.upload,
                              onPressed: () => showShareSheet(context, ref, s),
                            ),
                            const SizedBox(width: 6),
                            _Round(
                              icon: ClIcons.sliders,
                              label: l10n.sryMore,
                              onTap: () => _confirmDelete(context, ref, s),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(ClSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClIcon(
                            s.audience == Audience.family
                                ? ClIcons.family
                                : ClIcons.lock,
                            size: 16,
                            color: cl.colors.inkMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              meta,
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ClSpace.s2),
                      Semantics(
                        header: true,
                        child: Text(
                          s.title,
                          style: cl.text.largeTitle.copyWith(fontSize: 28),
                        ),
                      ),
                      if (s.milestone != null) ...[
                        const SizedBox(height: ClSpace.s2),
                        StoryMilestoneChip(
                          label: l10n.sryMilestoneOn(
                            s.milestone!.name,
                            DateFormat(
                              'd MMM',
                              locale,
                            ).format(s.milestone!.date),
                          ),
                        ),
                      ],
                      const SizedBox(height: ClSpace.s4),
                      ...children,
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                ClSpace.s2,
              ),
              child: parent
                  ? LovesLine(
                      target: LoveTarget.story,
                      targetId: s.id,
                      count: s.loveCount,
                    )
                  : Row(
                      children: [
                        LoveButton(
                          target: LoveTarget.story,
                          targetId: s.id,
                          count: s.loveCount,
                        ),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: ClPressable(
                            onPressed: () => showMessageComposer(
                              context,
                              kind: MessageContext.story,
                              contextId: s.id,
                            ),
                            semanticLabel: l10n.messageParents,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: ClSpace.s3,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: cl.colors.surface2,
                                borderRadius: BorderRadius.circular(
                                  ClRadius.pill,
                                ),
                              ),
                              child: Text(
                                l10n.messagePlaceholder,
                                style: cl.text.label.copyWith(
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.label, required this.onTap});
  final ClIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: cl.colors.ink),
      ),
    );
  }
}

/// "Xoá câu chuyện" (G-050): the photos stay in Kỷ niệm.
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Story s,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showClSheet<bool>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.sryDeleteTitle),
        Text(
          l10n.sryDeleteBody,
          style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        MeDestructive(
          title: l10n.sryDelete,
          onTap: () => Navigator.of(sheet).pop(true),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final toaster = ClToaster.of(context);
  final router = GoRouter.of(context);
  try {
    await withClProgress(
      context,
      () => ref.read(storyRepositoryProvider).delete(s.babyId, s.id),
    );
    toaster.show(message: l10n.sryDeleted);
    router.pop();
  } on Object {
    toaster.show(message: l10n.toastActionFailed, error: true);
  }
}
