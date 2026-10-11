import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_models.dart';
import '../memories/memories_screen.dart';
import '../memories/memory_models.dart';
import 'story_models.dart';
import 'story_repository.dart';
import 'story_widgets.dart';

enum _Filter { all, drafts, shared }

/// 14a "Câu chuyện": this week's suggestion, filters, story / letter / draft cards and "Viết".
/// Relatives read saved Gia đình stories only (11i).
class StoriesView extends ConsumerStatefulWidget {
  const StoriesView({required this.ctx, super.key});
  final MemoryCtx ctx;

  @override
  ConsumerState<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends ConsumerState<StoriesView> {
  var _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.ctx;
    final all =
        ref.watch(storiesProvider((c.babyId, c.me.uid, c.parentView))).value ??
        const <Story>[];
    final stories = c.parentView
        ? all
        : [
            for (final s in all)
              if (s.saved && s.audience == Audience.family) s,
          ];
    final suggestions = [
      for (final s in stories)
        if (s.suggestion && s.isAiDraft) s,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final suggestion = suggestions.firstOrNull;
    final drafts = [
      for (final s in stories)
        if (!s.saved && !s.suggestion) s,
    ];
    final saved =
        [
          for (final s in stories)
            if (s.saved) s,
        ]..sort(
          (a, b) =>
              (b.savedAt ?? b.updatedAt).compareTo(a.savedAt ?? a.updatedAt),
        );
    final shown = switch (_filter) {
      _Filter.all => [...drafts, ...saved, ...suggestions.skip(1)],
      _Filter.drafts => [...drafts, ...suggestions.skip(1)],
      _Filter.shared => [
        for (final s in saved)
          if (s.audience == Audience.family) s,
      ],
    };
    final media = storyMedia(ref, c.babyId, c.parentView);

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s2,
              ClSpace.s4,
              ClTabDock.contentBottomPadding + 144,
            ),
            children: [
              if (suggestion != null) ...[
                _SuggestionCard(story: suggestion, media: media),
                const SizedBox(height: ClSpace.s4),
              ],
              if (c.parentView) ...[
                Wrap(
                  spacing: ClSpace.s2,
                  children: [
                    ClFilterChip(
                      label: l10n.filterAll,
                      selected: _filter == _Filter.all,
                      onTap: () => setState(() => _filter = _Filter.all),
                    ),
                    ClFilterChip(
                      label: l10n.sryDrafts(drafts.length + suggestions.length),
                      selected: _filter == _Filter.drafts,
                      onTap: () => setState(() => _filter = _Filter.drafts),
                    ),
                    ClFilterChip(
                      label: l10n.sryShared,
                      selected: _filter == _Filter.shared,
                      onTap: () => setState(() => _filter = _Filter.shared),
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
              ],
              if (shown.isEmpty && suggestion == null)
                Padding(
                  padding: const EdgeInsets.only(top: ClSpace.s8),
                  child: ClEmptyState(
                    icon: ClIcons.journal,
                    title: l10n.sryEmptyTitle,
                    message: c.parentView
                        ? l10n.sryEmptyBody
                        : l10n.sryRelEmpty,
                  ),
                ),
              for (final s in shown) ...[
                StoryCard(story: s, ctx: c, media: media),
                const SizedBox(height: ClSpace.s4),
              ],
            ],
          ),
        ),
        if (c.parentView)
          Positioned(
            right: ClSpace.s4,
            // Above the dock (inset + 24 + 68) and the Kỷ niệm tabs (12 + ~52), plus 12.
            bottom: MediaQuery.paddingOf(context).bottom + 168,
            child: ClButton(
              label: l10n.sryWrite,
              icon: ClIcons.edit,
              onPressed: () => startStory(context, ref, c),
            ),
          ),
      ],
    );
  }
}

/// "Viết": a story or a letter (choice not drawn).
Future<void> startStory(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
) async {
  final kind = await showClSheet<StoryKind>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryNewTitle),
          ClCardGroup(
            children: [
              ClOptionRow(
                title: l10n.sryKindStory,
                subtitle: l10n.sryKindStoryHint,
                selected: false,
                onTap: () => Navigator.of(sheet).pop(StoryKind.story),
              ),
              ClOptionRow(
                title: l10n.sryKindLetter,
                subtitle: l10n.sryKindLetterHint,
                selected: false,
                onTap: () => Navigator.of(sheet).pop(StoryKind.letter),
              ),
            ],
          ),
        ],
      );
    },
  );
  if (kind == null || !context.mounted) return;
  final story = Story.blank(
    babyId: c.babyId,
    uid: c.me.uid,
    author: CareAuthor.of(c.me),
    kind: kind,
    now: c.now,
  );
  await context.push('${Routes.story}/${story.id}/edit', extra: story);
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.story, required this.media});
  final Story story;
  final Map<String, MediaItem> media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final thumbs = story.mediaIds.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClIcon(ClIcons.spark, size: 16, color: cl.colors.mintText),
                    const SizedBox(width: 4),
                    Text(
                      l10n.srySuggestTag,
                      style: cl.text.label.copyWith(
                        color: cl.colors.mintText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s2),
                Text(story.title, style: cl.text.headline),
                Text(
                  l10n.srySuggestSub(story.sourcePhotos),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s3),
                ClButton(
                  label: l10n.srySuggestCta,
                  onPressed: () =>
                      context.push('${Routes.story}/${story.id}/edit'),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          SizedBox(
            width: 92,
            height: 112,
            child: Stack(
              children: [
                for (final (i, id) in thumbs.indexed)
                  Positioned(
                    right: i * 14.0,
                    top: i * 10.0,
                    child: Transform.rotate(
                      angle: (i - 1) * 0.08,
                      child: Container(
                        width: 64,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cl.colors.surface,
                            width: 3,
                          ),
                        ),
                        child: StoryImage(item: media[id], radius: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One story in the list (14a variants: 1 photo, collage, letter, draft, AI draft row).
class StoryCard extends StatelessWidget {
  const StoryCard({
    required this.story,
    required this.ctx,
    required this.media,
    super.key,
  });
  final Story story;
  final MemoryCtx ctx;
  final Map<String, MediaItem> media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final s = story;
    void open() => context.push(
      s.saved ? '${Routes.story}/${s.id}' : '${Routes.story}/${s.id}/edit',
    );

    if (s.isAiDraft && s.suggestion) {
      return ClPressable(
        onPressed: open,
        semanticLabel: '${s.title}. ${l10n.sryFromSuggestion}',
        child: Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClRadius.card - 6),
            border: Border.all(color: cl.colors.separator, width: 1.5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: StoryImage(item: media[s.coverMediaId], radius: 10),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: cl.text.bodyStrong),
                    Row(
                      children: [
                        ClIcon(
                          ClIcons.spark,
                          size: 14,
                          color: cl.colors.mintText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.sryFromSuggestion,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.mintText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
            ],
          ),
        ),
      );
    }

    final who = storyAuthor(l10n, s, ctx.me.uid);
    final when = storyWhen(
      l10n,
      ctx.zone,
      ctx.now,
      s.savedAt ?? s.updatedAt,
      ctx.locale,
    );
    final meta = s.kind == StoryKind.letter
        ? l10n.sryWroteBy(who, when)
        : l10n.sryToldBy(who, when);
    final photos = s.mediaIds;
    final letter = s.kind == StoryKind.letter;
    final excerpt = s.firstText;

    Widget badges() => Wrap(
      spacing: ClSpace.s2,
      children: [
        if (!s.saved) _Badge(text: l10n.sryDraft),
        if (s.audience == Audience.parents)
          _Badge(text: l10n.audParents, icon: ClIcons.lock),
      ],
    );

    final body = Padding(
      padding: const EdgeInsets.all(ClSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!s.saved || s.audience == Audience.parents) ...[
            badges(),
            const SizedBox(height: ClSpace.s2),
          ],
          Text(s.title.isEmpty ? '…' : s.title, style: cl.text.title2),
          if (excerpt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              letter ? excerpt : '“$excerpt”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: cl.text.body.copyWith(
                fontFamily: 'Lora',
                fontStyle: FontStyle.italic,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
          if (s.milestone != null ||
              s.blocks.any((b) => b is MilestoneBlock)) ...[
            const SizedBox(height: ClSpace.s2),
            StoryMilestoneChip(
              label:
                  s.milestone?.name ??
                  s.blocks.whereType<MilestoneBlock>().first.name,
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  meta,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              if (s.saved) ...[
                ClIcon(
                  s.audience == Audience.family ? ClIcons.family : ClIcons.lock,
                  size: 16,
                  color: cl.colors.inkMuted,
                ),
                if (s.loveCount > 0) ...[
                  const SizedBox(width: ClSpace.s2),
                  ClIcon(ClIcons.heart, size: 16, color: cl.colors.peach),
                  const SizedBox(width: 2),
                  Text(
                    '${s.loveCount}',
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );

    Widget? cover;
    if (!letter && photos.length == 1) {
      cover = AspectRatio(
        aspectRatio: 4 / 3,
        child: StoryImage(item: media[photos.first], display: true),
      );
    } else if (!letter && photos.length > 1) {
      final more = photos.length - 3;
      cover = SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: StoryImage(item: media[photos[0]], display: true),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: StoryImage(item: media[photos[1]])),
                  const SizedBox(height: 2),
                  Expanded(
                    child: photos.length > 2
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              StoryImage(item: media[photos[2]]),
                              if (more > 0)
                                ColoredBox(
                                  color: Colors.black38,
                                  child: Center(
                                    child: Text(
                                      '+$more',
                                      style: cl.text.headline.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : ColoredBox(color: cl.colors.surface2),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ClPressable(
      onPressed: open,
      semanticLabel: '${s.title}. $meta',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: letter ? storyPaper(context) : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?cover, body],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon});
  final String text;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: 3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 12, color: cl.colors.inkMuted),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: cl.text.caption.copyWith(
              color: cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
