import 'dart:async';

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
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_models.dart';
import '../home/home_shell.dart';
import '../memories/album_screens.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_sheets.dart';
import 'story_models.dart';
import 'story_repository.dart';
import 'story_widgets.dart';

/// 14b "Bản nháp": tap any title, paragraph or photo to edit; AI toolbar on paragraphs; add, arrange,
/// preview & save. Also edits saved stories (14g "Sửa"), which re-save without a notice (P-091).
class StoryEditorScreen extends ConsumerStatefulWidget {
  const StoryEditorScreen({required this.storyId, this.initial, super.key});
  final String storyId;

  /// A new story ("Viết", "Kể thành chuyện"); otherwise loaded from Firestore.
  final Story? initial;

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  Story? _story;
  late bool _exists = widget.initial == null;
  var _dirty = false;
  var _busy = false;
  String? _selected;
  final _title = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _load(widget.initial!);
    _title.addListener(() {
      final s = _story;
      if (s == null || s.title == _title.text) return;
      _set(s.copyWith(title: _title.text));
    });
  }

  void _load(Story s) {
    _story = s;
    _title.text = s.title;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _set(Story s) => setState(() {
    _story = s;
    _dirty = true;
  });

  void _replaceBlock(StoryBlock b) => _set(
    _story!.copyWith(
      blocks: [for (final x in _story!.blocks) x.id == b.id ? b : x],
    ),
  );

  void _removeBlock(String id) => _set(
    _story!.copyWith(
      blocks: [
        for (final x in _story!.blocks)
          if (x.id != id) x,
      ],
    ),
  );

  Map<String, Object?> get _author {
    final me = ref.read(selectedMembershipProvider)!;
    return CareAuthor.of(me).toJson();
  }

  Future<bool> _saveDraft({bool toast = true}) async {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(selectedMembershipProvider);
    final s = _story;
    if (me == null || s == null) return false;
    setState(() => _busy = true);
    try {
      // Saved to the Firestore cache at once (offline-safe); the server sees it when online.
      unawaited(
        ref
            .read(storyRepositoryProvider)
            .saveDraft(s, me.uid, _author, exists: _exists)
            .catchError((Object _) {}),
      );
      _exists = true;
      _dirty = false;
      if (toast && mounted) showClToast(context, message: l10n.sryDraftSaved);
      return true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryDiscardTitle),
          Text(
            l10n.sryDiscardBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.sryDiscard,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.sryKeepEditing,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  Future<void> _discardDraft() async {
    final s = _story!;
    if (_exists) {
      unawaited(
        ref
            .read(storyRepositoryProvider)
            .discard(s.babyId, s.id)
            .catchError((Object _) {}),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _preview() async {
    final l10n = AppLocalizations.of(context);
    final s = _story!;
    if (s.title.trim().isEmpty) {
      showClToast(context, message: l10n.sryNeedTitle);
      return;
    }
    final hasContent =
        s.coverMediaId != null ||
        s.blocks.any(
          (b) =>
              (b is ParagraphBlock && b.text.trim().isNotEmpty) ||
              b is PhotosBlock,
        );
    if (!hasContent) {
      showClToast(context, message: l10n.sryNeedContent);
      return;
    }
    // Empty paragraphs are dropped before saving.
    final clean = s.copyWith(
      blocks: [
        for (final b in s.blocks)
          if (b is! ParagraphBlock || b.text.trim().isNotEmpty) b,
      ],
    );
    _story = clean;
    await _saveDraft(toast: false);
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StoryPreviewScreen(story: clean)),
    );
    if (saved == true && mounted) {
      context.pushReplacement('${Routes.story}/${clean.id}');
    }
  }

  Future<void> _editParagraph(ParagraphBlock b, [StoryAssistOp? op]) async {
    final next = await Navigator.of(context).push<ParagraphBlock>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            ParagraphEditorScreen(story: _story!, block: b, initialOp: op),
      ),
    );
    if (next != null) _replaceBlock(next);
  }

  List<MediaItem> _media() {
    final s = _story!;
    final all =
        ref.read(mediaProvider((s.babyId, true))).value ?? const <MediaItem>[];
    return [
      for (final m in all)
        if (m.isReady && !m.deleted && !m.isVideo) m,
    ];
  }

  Future<List<String>?> _pick({int max = StoryLimits.photosPerGroup}) async {
    final l10n = AppLocalizations.of(context);
    final nickname =
        ref.read(babyProvider(_story!.babyId)).value?.nickname ?? '';
    return pickFromMemories(
      context,
      _media(),
      max: max,
      title: l10n.sryChangePhotoHint(nickname),
    );
  }

  Future<void> _photoActions(PhotosBlock b) async {
    final l10n = AppLocalizations.of(context);
    final nickname =
        ref.read(babyProvider(_story!.babyId)).value?.nickname ?? '';
    final action = await showClSheet<String>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryPhotosTitle),
          ClCardGroup(
            children: [
              ClListRow(
                title: l10n.sryChangePhoto,
                subtitle: l10n.sryChangePhotoHint(nickname),
                onTap: () => Navigator.of(sheet).pop('change'),
              ),
              if (b.items.length < StoryLimits.photosPerGroup)
                ClListRow(
                  title: l10n.sryAddToGroup,
                  subtitle: l10n.sryAddToGroupHint,
                  onTap: () => Navigator.of(sheet).pop('add'),
                ),
              ClListRow(
                title: l10n.sryCaption,
                subtitle: l10n.sryCaptionHint,
                onTap: () => Navigator.of(sheet).pop('caption'),
              ),
              ClListRow(
                title: l10n.sryMakeCover,
                onTap: () => Navigator.of(sheet).pop('cover'),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          MeDestructive(
            title: l10n.sryRemovePhotos,
            subtitle: l10n.sryRemovePhotosHint,
            onTap: () => Navigator.of(sheet).pop('remove'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'change':
        final ids = await _pick();
        if (ids != null && ids.isNotEmpty) {
          _replaceBlock(
            PhotosBlock(b.id, [for (final id in ids) StoryPhoto(id)]),
          );
        }
      case 'add':
        final ids = await _pick(
          max: StoryLimits.photosPerGroup - b.items.length,
        );
        if (ids != null && ids.isNotEmpty) {
          _replaceBlock(
            PhotosBlock(b.id, [
              ...b.items,
              for (final id in ids) StoryPhoto(id),
            ]),
          );
        }
      case 'caption':
        final text = await _askText(
          l10n.sryCaption,
          b.items.first.caption ?? '',
          StoryLimits.captionMax,
        );
        if (text != null) {
          _replaceBlock(
            PhotosBlock(b.id, [
              for (final (i, p) in b.items.indexed)
                i == 0 ? StoryPhoto(p.mediaId, text.isEmpty ? null : text) : p,
            ]),
          );
        }
      case 'cover':
        _set(_story!.copyWith(coverMediaId: b.items.first.mediaId));
      case 'remove':
        _removeBlock(b.id);
    }
  }

  Future<String?> _askText(String title, String initial, int max) {
    final controller = TextEditingController(text: initial);
    return showClSheet<String>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: title),
            ClTextField(
              label: title,
              placeholder: title,
              controller: controller,
              standalone: true,
              maxLength: max,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.actionDone,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(controller.text.trim()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBlock() async {
    final l10n = AppLocalizations.of(context);
    final kind = await showClSheet<String>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryAddBlock),
          ClCardGroup(
            children: [
              for (final (k, label, icon) in [
                ('paragraph', l10n.sryAddParagraph, ClIcons.edit),
                ('photos', l10n.sryAddPhotos, ClIcons.memories),
                ('milestone', l10n.sryAddMilestone, ClIcons.star),
                ('quote', l10n.sryAddQuote, ClIcons.journal),
              ])
                ClDetailRow(
                  icon: icon,
                  label: label,
                  onTap: () => Navigator.of(sheet).pop(k),
                ),
            ],
          ),
        ],
      ),
    );
    if (!mounted || kind == null) return;
    final s = _story!;
    if (s.blocks.length >= StoryLimits.blocksMax) return;
    switch (kind) {
      case 'paragraph':
        final b = ParagraphBlock(newBlockId(), '');
        _set(s.copyWith(blocks: [...s.blocks, b]));
        await _editParagraph(b);
      case 'photos':
        final ids = await _pick();
        if (ids != null && ids.isNotEmpty) {
          _set(
            s.copyWith(
              blocks: [
                ...s.blocks,
                PhotosBlock(newBlockId(), [
                  for (final id in ids) StoryPhoto(id),
                ]),
              ],
              coverMediaId: s.coverMediaId ?? ids.first,
            ),
          );
        }
      case 'milestone':
        final m = await _pickMilestone();
        if (m != null) {
          _set(
            s.copyWith(
              blocks: [
                ...s.blocks,
                MilestoneBlock(newBlockId(), m.name, m.date),
              ],
            ),
          );
        }
      case 'quote':
        final text = await _askText(l10n.sryAddQuote, '', StoryLimits.quoteMax);
        if (text != null && text.isNotEmpty) {
          _set(
            s.copyWith(blocks: [...s.blocks, QuoteBlock(newBlockId(), text)]),
          );
        }
    }
  }

  /// Milestones already tagged in Kỷ niệm (family milestones and the presets used on items).
  Future<MilestoneRef?> _pickMilestone() {
    final s = _story!;
    final media =
        ref.read(mediaProvider((s.babyId, true))).value ?? const <MediaItem>[];
    final family =
        ref.read(familyMilestonesProvider(s.babyId)).value ??
        const <FamilyMilestone>[];
    final refs = <String, MilestoneRef>{
      for (final f in family) f.name: f.ref,
      for (final m in media)
        if (m.milestone != null) m.milestone!.name: m.milestone!,
    };
    return showClSheet<MilestoneRef>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        final locale = Localizations.localeOf(sheet).toLanguageTag();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.sryAddMilestone),
            if (refs.isEmpty)
              Text(l10n.composeNoMilestone, style: sheet.cl.text.body)
            else
              ClCardGroup(
                children: [
                  for (final r in refs.values)
                    ClListRow(
                      title: r.name,
                      subtitle: DateFormat.yMMMd(locale).format(r.date),
                      onTap: () => Navigator.of(sheet).pop(r),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (_story == null) {
      final loaded = ref
          .watch(storyProvider((_babyId(ref), widget.storyId)))
          .value;
      if (loaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _story == null) setState(() => _load(loaded));
        });
      }
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    final s = _story!;
    final media = storyMedia(ref, s.babyId, true);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final meta = [
      if (s.rangeStart != null && s.rangeEnd != null)
        '${DateFormat('d', locale).format(s.rangeStart!)} – ${DateFormat('d MMMM', locale).format(s.rangeEnd!)}',
      if (s.mediaIds.isNotEmpty) l10n.sryMetaPhotos(s.mediaIds.length),
      if (s.milestone != null) l10n.sryMetaMilestone(s.milestone!.name),
    ].join(' · ');

    Widget selectable(String id, Widget child, {VoidCallback? onTap}) {
      final on = _selected == id;
      return ClPressable(
        onPressed: onTap ?? () => setState(() => _selected = on ? null : id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(ClSpace.s2),
          decoration: BoxDecoration(
            color: on ? cl.colors.mintSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(ClRadius.control + 4),
            border: Border.all(
              color: on ? cl.colors.mintDeep : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
      );
    }

    Widget toolbar(ParagraphBlock b) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: ClSpace.s2),
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: cl.colors.ink,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, icon, op) in [
              (l10n.actionEdit, ClIcons.edit, null),
              (l10n.sryRewrite, ClIcons.retry, StoryAssistOp.rewrite),
              (l10n.sryWarmer, ClIcons.spark, StoryAssistOp.warmer),
            ])
              ClPressable(
                onPressed: () => _editParagraph(b, op),
                semanticLabel: label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClSpace.s2,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      ClIcon(icon, size: 16, color: cl.colors.cloud),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: cl.text.label.copyWith(
                          color: cl.colors.cloud,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget block(StoryBlock b) => switch (b) {
      ParagraphBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          selectable(
            b.id,
            Text(
              b.text.isEmpty ? l10n.sryParagraphHint : b.text,
              style: cl.text.body.copyWith(
                height: 1.55,
                color: b.text.isEmpty ? cl.colors.inkMuted : cl.colors.ink,
              ),
            ),
          ),
          if (_selected == b.id) toolbar(b),
        ],
      ),
      PhotosBlock() => selectable(
        b.id,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: b.items.length == 1 ? 220 : 150,
              child: Row(
                children: [
                  for (final (i, p) in b.items.indexed) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: StoryImage(
                        item: media[p.mediaId],
                        display: b.items.length == 1,
                        radius: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (b.items.any((p) => p.caption != null)) ...[
              const SizedBox(height: 4),
              Text(
                b.items.map((p) => p.caption).whereType<String>().join(' · '),
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ],
        ),
        onTap: () => _photoActions(b),
      ),
      MilestoneBlock() => selectable(
        b.id,
        Align(
          alignment: Alignment.centerLeft,
          child: StoryMilestoneChip(
            label: '${b.name} · ${DateFormat('d MMM', locale).format(b.date)}',
          ),
        ),
        onTap: () => _confirmRemove(b.id),
      ),
      QuoteBlock() => selectable(
        b.id,
        Text(
          '“${b.text}”',
          style: cl.text.title2.copyWith(
            fontStyle: FontStyle.italic,
            color: cl.colors.mintText,
          ),
        ),
        onTap: () async {
          final text = await _askText(
            l10n.sryAddQuote,
            b.text,
            StoryLimits.quoteMax,
          );
          if (text == null) return;
          text.isEmpty
              ? _removeBlock(b.id)
              : _replaceBlock(QuoteBlock(b.id, text));
        },
      ),
    };

    final cover = media[s.coverMediaId];
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: cl.colors.cloud,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                child: Row(
                  children: [
                    ClButton(
                      label: l10n.actionCancel,
                      style: ClButtonStyle.plain,
                      onPressed: _cancel,
                    ),
                    Expanded(
                      child: Text(
                        s.saved ? l10n.actionEdit : l10n.sryDraft,
                        textAlign: TextAlign.center,
                        style: cl.text.headline,
                      ),
                    ),
                    ClButton(
                      label: s.saved ? l10n.actionSave : l10n.srySaveDraft,
                      style: ClButtonStyle.plain,
                      onPressed: _busy
                          ? null
                          : s.saved
                          ? _preview
                          : () => _saveDraft(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s2,
                    ClSpace.s4,
                    ClSpace.s6,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ClSpace.s3),
                      decoration: BoxDecoration(
                        color: cl.colors.mintSoft,
                        borderRadius: BorderRadius.circular(
                          ClRadius.control + 4,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClIcon(
                            ClIcons.spark,
                            size: 18,
                            color: cl.colors.mintText,
                          ),
                          const SizedBox(width: ClSpace.s2),
                          Expanded(
                            child: Text(
                              s.origin == 'ai'
                                  ? l10n.sryAiTip(s.sourcePhotos)
                                  : l10n.sryTip,
                              style: cl.text.label.copyWith(
                                color: cl.colors.mintText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ClSpace.s3),
                    if (s.kind == StoryKind.story)
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            StoryImage(item: cover, display: true, radius: 16),
                            Positioned(
                              right: ClSpace.s3,
                              bottom: ClSpace.s3,
                              child: ClButton(
                                label: cover == null
                                    ? l10n.sryAddCover
                                    : l10n.sryChangeCover,
                                icon: ClIcons.camera,
                                style: ClButtonStyle.secondary,
                                onPressed: () async {
                                  final ids = await _pick(max: 1);
                                  if (ids != null && ids.isNotEmpty) {
                                    _set(s.copyWith(coverMediaId: ids.first));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: ClSpace.s3),
                    TextField(
                      controller: _title,
                      maxLength: StoryLimits.titleMax,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: cl.text.title,
                      decoration: InputDecoration.collapsed(
                        hintText: l10n.sryTitleHint,
                        hintStyle: cl.text.title.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ).copyWith(counterText: ''),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    const SizedBox(height: ClSpace.s3),
                    for (final b in s.blocks) ...[
                      block(b),
                      const SizedBox(height: ClSpace.s2),
                    ],
                    ClPressable(
                      onPressed: _addBlock,
                      semanticLabel: l10n.sryAddBlock,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            ClRadius.control + 4,
                          ),
                          border: Border.all(
                            color: cl.colors.separator,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClIcon(
                              ClIcons.plus,
                              size: 18,
                              color: cl.colors.mintText,
                            ),
                            const SizedBox(width: ClSpace.s2),
                            Text(
                              l10n.sryAddBlock,
                              style: cl.text.label.copyWith(
                                color: cl.colors.mintText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!s.saved) ...[
                      const SizedBox(height: ClSpace.s6),
                      Center(
                        child: ClButton(
                          label: l10n.sryDiscardDraft,
                          style: ClButtonStyle.plain,
                          onPressed: _discardDraft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  ClSpace.s3,
                ),
                child: Row(
                  children: [
                    ClButton(
                      label: l10n.sryArrange,
                      style: ClButtonStyle.secondary,
                      onPressed: () async {
                        final next = await Navigator.of(context)
                            .push<List<StoryBlock>>(
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => ArrangeScreen(story: s),
                              ),
                            );
                        if (next != null) _set(s.copyWith(blocks: next));
                      },
                    ),
                    const SizedBox(width: ClSpace.s2),
                    Expanded(
                      child: ClButton(
                        label: l10n.sryPreviewSave,
                        expand: true,
                        onPressed: _preview,
                        loading: _busy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(String id) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryMilestoneRow),
          MeDestructive(
            title: l10n.sryRemovePhotos,
            onTap: () => Navigator.of(sheet).pop(true),
          ),
        ],
      ),
    );
    if (ok == true) _removeBlock(id);
  }
}

String _babyId(WidgetRef ref) =>
    ref.read(selectedMembershipProvider)?.babyId ?? '';

/// A destructive row in a sheet ("Bỏ khỏi câu chuyện · Ảnh vẫn còn trong Kỷ niệm").
class MeDestructive extends StatelessWidget {
  const MeDestructive({
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.errorSoft,
          borderRadius: BorderRadius.circular(ClRadius.control + 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: cl.text.bodyStrong.copyWith(color: cl.colors.error),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: cl.text.label.copyWith(color: cl.colors.error),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- 14c Sửa đoạn ----------

/// 14c: the paragraph, its word count and "Đã sửa · không còn là văn AI"; suggestions; AI bar
/// Viết lại / Ngắn hơn / Ấm hơn / Hoàn tác above the keyboard (R-132).
class ParagraphEditorScreen extends ConsumerStatefulWidget {
  const ParagraphEditorScreen({
    required this.story,
    required this.block,
    this.initialOp,
    super.key,
  });
  final Story story;
  final ParagraphBlock block;
  final StoryAssistOp? initialOp;

  @override
  ConsumerState<ParagraphEditorScreen> createState() => _ParagraphEditorState();
}

class _ParagraphEditorState extends ConsumerState<ParagraphEditorScreen> {
  late final _text = TextEditingController(text: widget.block.text);
  final _history = <String>[];
  late bool _ai = widget.block.ai;
  String? _aiText;
  List<String> _options = const [];
  var _option = 0;
  StoryAssistOp? _lastOp;
  var _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    if (widget.initialOp != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _assist(widget.initialOp!),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _isAi =>
      _ai &&
      (_aiText == null || _aiText == _text.text) &&
      _text.text == (_aiText ?? widget.block.text);

  Future<void> _assist(StoryAssistOp op) async {
    final l10n = AppLocalizations.of(context);
    if (_text.text.trim().isEmpty) return;
    setState(() {
      _working = true;
      _error = null;
      _lastOp = op;
    });
    try {
      final options = await ref
          .read(storyRepositoryProvider)
          .assist(
            widget.story,
            widget.block.id,
            op,
            _text.text,
            Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'vi',
          );
      setState(() {
        _options = options;
        _option = 0;
      });
    } on StoryActionException catch (e) {
      setState(
        () => _error = e.reason == 'assist-limit'
            ? l10n.sryAiLimit
            : l10n.sryAiUnavailable,
      );
    } on Object {
      setState(() => _error = l10n.sryAiUnavailable);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _use(String option) {
    _history.add(_text.text);
    final next = _lastOp == StoryAssistOp.suggest
        ? '${_text.text.trimRight()} $option'
        : option;
    _text.text = next;
    _ai = true;
    _aiText = next;
    setState(() => _options = const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final edited = widget.block.ai && !_isAi;
    final current = _options.isEmpty
        ? null
        : _options[_option % _options.length];
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
              child: Row(
                children: [
                  ClButton(
                    label: l10n.actionCancel,
                    style: ClButtonStyle.plain,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.sryEditParagraph,
                      textAlign: TextAlign.center,
                      style: cl.text.headline,
                    ),
                  ),
                  ClButton(
                    label: l10n.actionDone,
                    style: ClButtonStyle.plain,
                    onPressed: () => Navigator.of(context).pop(
                      ParagraphBlock(
                        widget.block.id,
                        _text.text.trim(),
                        ai: _isAi,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ClSpace.s4),
                children: [
                  Container(
                    padding: const EdgeInsets.all(ClSpace.s3),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(ClRadius.control + 4),
                      border: Border.all(color: cl.colors.mintDeep, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _text,
                          autofocus: widget.initialOp == null,
                          maxLines: null,
                          minLines: 4,
                          maxLength: StoryLimits.paragraphMax,
                          textCapitalization: TextCapitalization.sentences,
                          style: cl.text.body.copyWith(height: 1.55),
                          decoration: InputDecoration.collapsed(
                            hintText: l10n.sryParagraphHint,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: ClSpace.s2),
                        Row(
                          children: [
                            if (edited)
                              Expanded(
                                child: Text(
                                  l10n.sryEdited,
                                  style: cl.text.caption.copyWith(
                                    color: cl.colors.mintText,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            Text(
                              l10n.sryWords(wordCount(_text.text)),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  if (_working || current != null || _error != null) ...[
                    Text(
                      l10n.srySuggestFor,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                    const SizedBox(height: ClSpace.s2),
                    Container(
                      padding: const EdgeInsets.all(ClSpace.s3),
                      decoration: BoxDecoration(
                        color: cl.colors.surface2,
                        borderRadius: BorderRadius.circular(
                          ClRadius.control + 4,
                        ),
                      ),
                      child: _working
                          ? Text(l10n.sryAiWorking, style: cl.text.body)
                          : _error != null
                          ? Text(
                              _error!,
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '“$current”',
                                  style: cl.text.body.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: ClSpace.s3),
                                Wrap(
                                  spacing: ClSpace.s2,
                                  children: [
                                    ClButton(
                                      label: l10n.sryUseThis,
                                      style: ClButtonStyle.tinted,
                                      onPressed: () => _use(current!),
                                    ),
                                    ClButton(
                                      label: l10n.sryOtherSuggestion,
                                      style: ClButtonStyle.secondary,
                                      onPressed: () => _options.length > 1
                                          ? setState(() => _option++)
                                          : _assist(StoryAssistOp.suggest),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            ),
            // AI bar above the keyboard.
            Container(
              color: cl.colors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s2,
                vertical: ClSpace.s1,
              ),
              child: Row(
                children: [
                  for (final (label, icon, op) in [
                    (l10n.sryRewrite, ClIcons.retry, StoryAssistOp.rewrite),
                    (l10n.sryShorter, ClIcons.spark, StoryAssistOp.shorter),
                    (l10n.sryWarmer, ClIcons.spark, StoryAssistOp.warmer),
                  ])
                    _BarAction(
                      label: label,
                      icon: icon,
                      onTap: _working ? null : () => _assist(op),
                    ),
                  _BarAction(
                    label: l10n.sryUndo,
                    icon: ClIcons.clock,
                    onTap: _history.isEmpty
                        ? null
                        : () => setState(() {
                            _text.text = _history.removeLast();
                          }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({required this.label, required this.icon, this.onTap});
  final String label;
  final ClIcons icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = onTap == null ? cl.colors.inkMuted : cl.colors.mintText;
    return Expanded(
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClIcon(icon, size: 18, color: ink),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cl.text.caption.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- 14e Sắp xếp ----------

/// 14e: hold ≡ and drag to reorder; swipe left to delete a block (R-134).
class ArrangeScreen extends StatefulWidget {
  const ArrangeScreen({required this.story, super.key});
  final Story story;

  @override
  State<ArrangeScreen> createState() => _ArrangeScreenState();
}

class _ArrangeScreenState extends State<ArrangeScreen> {
  late final _blocks = [...widget.story.blocks];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    var paragraph = 0;
    String label(StoryBlock b) => switch (b) {
      ParagraphBlock() =>
        b.text.isEmpty
            ? l10n.sryParagraphN(++paragraph)
            : (++paragraph, b.text).$2,
      PhotosBlock() =>
        '${l10n.sryPhotoGroup} · ${l10n.sryMetaPhotos(b.items.length)}',
      MilestoneBlock() => '${l10n.sryMilestoneRow} · ${b.name}',
      QuoteBlock() => '${l10n.sryQuoteRow} · ${b.text}',
    };
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
              child: Row(
                children: [
                  ClButton(
                    label: l10n.actionCancel,
                    style: ClButtonStyle.plain,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.sryArrange,
                      textAlign: TextAlign.center,
                      style: cl.text.headline,
                    ),
                  ),
                  ClButton(
                    label: l10n.actionDone,
                    style: ClButtonStyle.plain,
                    onPressed: () => Navigator.of(context).pop(_blocks),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: Text(
                l10n.sryArrangeHint,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                onReorderItem: (from, to) => setState(() {
                  _blocks.insert(to, _blocks.removeAt(from));
                }),
                children: [
                  for (final (i, b) in _blocks.indexed)
                    Dismissible(
                      key: ValueKey(b.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: ClSpace.s4),
                        color: cl.colors.errorSoft,
                        child: ClIcon(ClIcons.trash, color: cl.colors.error),
                      ),
                      onDismissed: (_) => setState(() => _blocks.removeAt(i)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: ClSpace.s2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClSpace.s3,
                          vertical: ClSpace.s3,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.surface,
                          borderRadius: BorderRadius.circular(
                            ClRadius.control + 4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label(b),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: cl.text.body,
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.all(ClSpace.s1),
                                child: Text(
                                  '≡',
                                  style: cl.text.headline.copyWith(
                                    color: cl.colors.inkMuted,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 14f Xem trước & lưu ----------

/// 14f: the story on paper, then "Lưu câu chuyện": Chỉ ba mẹ / Gia đình, "Báo cho gia đình",
/// the D-002 note, "Lưu xong mới chia sẻ ra ngoài được." Pops true once saved.
class StoryPreviewScreen extends ConsumerStatefulWidget {
  const StoryPreviewScreen({required this.story, super.key});
  final Story story;

  @override
  ConsumerState<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends ConsumerState<StoryPreviewScreen> {
  late Audience _audience = widget.story.audience;
  var _notify = true;
  var _busy = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(storyRepositoryProvider)
          .save(
            widget.story.babyId,
            widget.story.id,
            _audience,
            _audience == Audience.family && _notify && !widget.story.saved,
          );
      toaster.show(message: r.notified ? l10n.srySavedNotified : l10n.srySaved);
      navigator.pop(true);
    } on Object {
      toaster.show(message: l10n.toastSaveFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final s = widget.story;
    final media = storyMedia(ref, s.babyId, true);
    final private = [
      for (final id in s.mediaIds)
        if (media[id]?.effectiveAudience == Audience.parents) id,
    ].length;
    final text = s.blocks
        .whereType<ParagraphBlock>()
        .map((b) => b.text)
        .join('\n\n');
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: StoryImage(
                          item: media[s.coverMediaId],
                          display: true,
                        ),
                      ),
                      Positioned(
                        left: ClSpace.s4,
                        top: MediaQuery.paddingOf(context).top + ClSpace.s2,
                        child: ClButton(
                          label: l10n.sryKeepEditing,
                          icon: ClIcons.back,
                          style: ClButtonStyle.secondary,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.all(ClSpace.s4),
                    padding: const EdgeInsets.all(ClSpace.s4),
                    decoration: BoxDecoration(
                      color: storyPaper(context),
                      borderRadius: BorderRadius.circular(ClRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sryPreviewLabel,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: ClSpace.s2),
                        Text(s.title, style: cl.text.title),
                        const SizedBox(height: ClSpace.s2),
                        Text(
                          text,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.body.copyWith(height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s4,
                ClSpace.s4,
                ClSpace.s3,
              ),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: cl.shadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.srySaveTitle, style: cl.text.title2),
                  const SizedBox(height: ClSpace.s3),
                  AudienceCards(
                    value: _audience,
                    onChanged: (a) => setState(() => _audience = a),
                  ),
                  if (_audience == Audience.family) ...[
                    if (!s.saved)
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.composeNotify,
                                    style: cl.text.bodyStrong,
                                  ),
                                  Text(
                                    l10n.sryOneNotice,
                                    style: cl.text.caption.copyWith(
                                      color: cl.colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ClToggle(
                              value: _notify,
                              semanticLabel: l10n.composeNotify,
                              onChanged: (v) => setState(() => _notify = v),
                            ),
                          ],
                        ),
                      ),
                    if (private > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: ClSpace.s2),
                        child: Text(
                          l10n.sryPrivatePhotos(private),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: ClSpace.s4),
                  ClButton(
                    label: l10n.srySaveTitle,
                    expand: true,
                    onPressed: _save,
                    loading: _busy,
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.sryShareAfter,
                    textAlign: TextAlign.center,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
