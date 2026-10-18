import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../feedback/review_prompt.dart';
import '../memories/media_picker.dart' show pickFromLibrary;
import '../memories/memory_models.dart';
import '../memories/memory_sheets.dart' show AudienceCards;
import '../memories/upload_queue.dart';
import 'milestone_models.dart';
import 'milestone_repository.dart';
import 'milestone_widgets.dart';

/// 3c "Đã quan sát" (record a milestone) and 3e "Kỷ niệm mới" (a memory from a milestone).
/// Photos stay on the phone until a memory is made: Kỷ niệm's own upload takes them, tagged
/// with the record (`milestone.id = recordId`), and the record keeps the memory id. Nothing is
/// copied (D-076 #6, contracts milestones.ts).

/// Header fixed, the rest scrolls (as Kỷ niệm's sheets).
Widget _sheet(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    children.first,
    Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.sublist(1),
        ),
      ),
    ),
  ],
);

/// A write that may wait offline: Firestore queues it and it lands later (as MS01 does).
Future<bool> _write(Future<void> write) async {
  try {
    await write.timeout(const Duration(seconds: 4));
    return true;
  } on TimeoutException {
    write.ignore();
    return true;
  } on Object {
    return false;
  }
}

/// Photos and videos picked from the library. They wait on the phone until "Tạo kỷ niệm" sends
/// them through Kỷ niệm's upload, which takes both (a video picked here was dropped silently).
Future<List<PickedMedia>> pickMilestonePhotos(
  BuildContext context,
  WidgetRef ref,
) async => await pickFromLibrary(context, ref) ?? const <PickedMedia>[];

// ---------- 3c Ghi nhận mốc ----------

/// Records (or edits) [reference] for the baby, or edits a custom [record]. True when saved.
Future<bool> showRecordSheet(
  BuildContext context, {
  required MtCtx ctx,
  ReferenceMilestone? reference,
  MilestoneRecord? record,
}) async =>
    await showClSheet<bool>(
      context: context,
      builder: (_) =>
          _RecordSheet(ctx: ctx, reference: reference, record: record),
    ) ??
    false;

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({required this.ctx, this.reference, this.record});
  final MtCtx ctx;
  final ReferenceMilestone? reference;
  final MilestoneRecord? record;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  late DateTime _date = widget.record?.date ?? widget.ctx.today;
  late final _note = TextEditingController(text: widget.record?.note ?? '');
  late final _name = TextEditingController(text: widget.record?.name ?? '');
  late List<PickedMedia> _photos = [
    ...?ref.read(pendingMilestonePhotosProvider)[_recordId],
  ];
  var _busy = false;

  bool get _custom => widget.reference == null;
  bool get _edit => widget.record?.observed ?? false;
  String get _recordId => widget.record?.id ?? widget.reference!.recordId;

  @override
  void dispose() {
    _note.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final c = widget.ctx;
    final today = c.today;
    final picked = await pickMilestoneDay(
      context,
      initial: _date,
      first: c.dob ?? DateTime(today.year - 3, today.month, today.day),
      last: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addPhotos() async {
    final more = await pickMilestonePhotos(context, ref);
    if (more.isNotEmpty && mounted) {
      setState(() => _photos = [..._photos, ...more]);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final c = widget.ctx;
    final repo = ref.read(milestoneRepositoryProvider);
    final name = _custom
        ? _name.text.trim()
        : widget.reference!.title.of(c.lang);
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final record = widget.record;
    final ok = await _write(
      _edit && record != null
          ? repo.edit(c.c.me, record, name: name, date: _date, note: _note.text)
          : repo.observeReference(
              c.c.me,
              widget.reference!,
              name: name,
              date: _date,
              note: _note.text,
              existing: record,
            ),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      toaster.show(message: l10n.mtSaveFailed, error: true);
      return;
    }
    final pending = ref.read(pendingMilestonePhotosProvider.notifier);
    if (_photos.isEmpty) {
      pending.clear(_recordId);
    } else {
      pending.set(_recordId, _photos);
    }
    navigator.pop(true);
    toaster.show(message: l10n.mtSaved);
    if (!_edit) {
      // FB5: a milestone saved is a happy moment (D-065).
      unawaited(
        ref.read(reviewPrompterProvider).trigger(ReviewTrigger.milestone),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = widget.ctx;
    return _sheet([
      ClSheetHeader(title: _custom ? l10n.mtEditTitle : l10n.mtSeen),
      if (!_custom)
        Text(
          widget.reference!.title.of(c.lang),
          style: cl.text.body.copyWith(
            color: cl.colors.inkMuted,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        )
      else
        ClTextField(
          label: l10n.mtName,
          placeholder: l10n.mtNameHint,
          controller: _name,
          standalone: true,
          maxLength: MilestoneLimits.nameMax,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
      const SizedBox(height: ClSpace.s3),
      MtDateField(
        label: l10n.mtDateDid,
        value: longDay(c.lang, _date),
        onTap: _pickDate,
      ),
      const SizedBox(height: ClSpace.s3),
      ClTextField(
        label: l10n.mtNote,
        placeholder: l10n.mtNoteHint,
        controller: _note,
        standalone: true,
        maxLines: 4,
        maxLength: MilestoneLimits.noteMax,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: ClSpace.s3),
      Text(
        l10n.mtPhotosOptional,
        style: cl.text.label.copyWith(
          color: cl.colors.inkMuted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 6),
      MtPhotoStrip(
        photos: _photos,
        onAdd: _addPhotos,
        onRemove: (i) => setState(() => _photos = [..._photos]..removeAt(i)),
      ),
      const SizedBox(height: ClSpace.s4),
      ClButton(
        label: l10n.mtSave,
        expand: true,
        loading: _busy,
        onPressed: _custom && _name.text.trim().isEmpty ? null : _save,
      ),
    ]);
  }
}

// ---------- 3e Tạo kỷ niệm từ mốc ----------

/// Kỷ niệm's upload for a memory of [record]: tagged with it, dated on its day, in [audience]
/// (Gia đình by default, D-001; the family is told as in compose). Returns the memory id once
/// queued.
Future<String> createMilestoneMemory(
  WidgetRef ref, {
  required String babyId,
  required MilestoneRef milestone,
  required String? caption,
  required Audience audience,
  required List<PickedMedia> photos,
}) async {
  final memoryId = newMemoryId();
  final text = caption?.trim() ?? '';
  await ref
      .read(uploadQueueProvider.notifier)
      .enqueue(
        babyId: babyId,
        request: {
          'babyId': babyId,
          'memoryId': memoryId,
          'batchId': newBatchId(),
          'caption': text.isEmpty ? null : text,
          'audience': audience.name,
          'notifyFamily': audience == Audience.family,
          'dateMode': 'single',
          'date': isoDateOf(milestone.date),
          'milestone': milestone.toJson(),
          'albumIds': const <String>[],
        },
        picked: photos,
      );
  return memoryId;
}

/// Memories made in this run, shown as "Đang tải lên Kỷ niệm…" until they arrive.
final recentMilestoneMemoriesProvider =
    NotifierProvider<RecentMilestoneMemories, Set<String>>(
      RecentMilestoneMemories.new,
    );

class RecentMilestoneMemories extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String id) => state = {...state, id};
}

/// 3e: true when a memory was made.
Future<bool> showMilestoneMemorySheet(
  BuildContext context, {
  required MtCtx ctx,
  required MilestoneRecord record,
}) async =>
    await showClSheet<bool>(
      context: context,
      builder: (_) => _MemorySheet(ctx: ctx, record: record),
    ) ??
    false;

class _MemorySheet extends ConsumerStatefulWidget {
  const _MemorySheet({required this.ctx, required this.record});
  final MtCtx ctx;
  final MilestoneRecord record;

  @override
  ConsumerState<_MemorySheet> createState() => _MemorySheetState();
}

class _MemorySheetState extends ConsumerState<_MemorySheet> {
  late final _caption = TextEditingController(text: widget.record.note ?? '');
  late List<PickedMedia> _photos = [
    ...?ref.read(pendingMilestonePhotosProvider)[widget.record.id],
  ];
  var _audience = Audience.family; // D-001
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final more = await pickMilestonePhotos(context, ref);
    if (more.isNotEmpty && mounted) {
      setState(() {
        _photos = [..._photos, ...more];
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final r = widget.record;
    final ref0 = r.ref;
    if (ref0 == null) return;
    if (_photos.isEmpty && _caption.text.trim().isEmpty) {
      setState(() => _error = l10n.mtCaptionRequired);
      return;
    }
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final c = widget.ctx;
    setState(() => _busy = true);
    final memoryId = await createMilestoneMemory(
      ref,
      babyId: c.babyId,
      milestone: ref0,
      caption: _caption.text,
      audience: _audience,
      photos: _photos,
    );
    ref.read(recentMilestoneMemoriesProvider.notifier).add(memoryId);
    ref.read(pendingMilestonePhotosProvider.notifier).clear(r.id);
    unawaited(
      _write(
        ref.read(milestoneRepositoryProvider).linkMemory(c.c.me, r, memoryId),
      ),
    );
    if (!mounted) return;
    navigator.pop(true);
    toaster.show(message: l10n.mtMemoryCreated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = widget.record;
    return _sheet([
      ClSheetHeader(title: l10n.mtNewMemory),
      MtPhotoStrip(
        photos: _photos,
        size: 96,
        onAdd: _addPhotos,
        onRemove: (i) => setState(() => _photos = [..._photos]..removeAt(i)),
      ),
      const SizedBox(height: ClSpace.s3),
      ClTextField(
        label: l10n.mtCaption,
        placeholder: l10n.mtCaptionHint,
        controller: _caption,
        standalone: true,
        maxLines: 4,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: cl.text.label.copyWith(color: cl.colors.error)),
      ],
      const SizedBox(height: ClSpace.s3),
      Wrap(
        spacing: ClSpace.s2,
        runSpacing: ClSpace.s2,
        children: [
          MtChip(
            label: l10n.mtTag(r.name),
            fill: cl.colors.peachSoft,
            icon: ClIcons.star,
          ),
          if (r.date != null)
            MtChip(
              label: longDay(widget.ctx.lang, r.date!).split(', ').last,
              fill: cl.colors.surface2,
              icon: ClIcons.cake,
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
      Text(l10n.mtWhoSees, style: cl.text.headline),
      const SizedBox(height: ClSpace.s2),
      AudienceCards(
        value: _audience,
        onChanged: (a) => setState(() => _audience = a),
      ),
      const SizedBox(height: ClSpace.s4),
      ClButton(
        label: l10n.mtSaveMemory,
        expand: true,
        loading: _busy,
        onPressed: _save,
      ),
    ]);
  }
}

// ---------- Remove ----------

Future<bool> confirmRemoveRecord(BuildContext context) async =>
    await showClSheet<bool>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.mtDeleteTitle),
            Text(
              l10n.mtDeleteBody,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.mtDelete,
              expand: true,
              style: ClButtonStyle.destructive,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: ClSpace.s2),
            ClButton(
              label: l10n.actionCancel,
              expand: true,
              style: ClButtonStyle.secondary,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ],
        );
      },
    ) ??
    false;

/// Writes for screens (offline-tolerant).
Future<bool> milestoneWrite(Future<void> write) => _write(write);
