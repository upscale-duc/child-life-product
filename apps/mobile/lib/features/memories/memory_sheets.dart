import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../feedback/review_prompt.dart';
import '../keepsakes/keepsake_access.dart';
import 'album_screens.dart' show albumsValue, showAlbumPicker;
import 'media_picker.dart';
import 'media_viewer.dart';
import 'memories_screen.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_widgets.dart';
import 'upload_queue.dart';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String presetName(AppLocalizations l10n, PresetMilestone p) => switch (p) {
  PresetMilestone.firstSmile => l10n.msFirstSmile,
  PresetMilestone.firstBath => l10n.msFirstBath,
  PresetMilestone.liftsHead => l10n.msLiftsHead,
  PresetMilestone.firstOuting => l10n.msFirstOuting,
  PresetMilestone.oneMonth => l10n.msOneMonth,
  PresetMilestone.meetsGrandparents => l10n.msMeetsGrandparents,
  PresetMilestone.rollsOver => l10n.msRollsOver,
  PresetMilestone.laughs => l10n.msLaughs,
  PresetMilestone.firstSolids => l10n.msFirstSolids,
  PresetMilestone.sitsUp => l10n.msSitsUp,
  PresetMilestone.firstTooth => l10n.msFirstTooth,
  PresetMilestone.crawls => l10n.msCrawls,
  PresetMilestone.firstWord => l10n.msFirstWord,
  PresetMilestone.firstSteps => l10n.msFirstSteps,
  PresetMilestone.firstBirthday => l10n.msFirstBirthday,
};

/// Header fixed, the rest scrolls when it is taller than the sheet (as CareSheetFrame); the
/// sheet itself keeps clear of the keyboard and the home indicator (cl_sheet.dart).
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

// ---------- 10a2 "Thêm vào Kỷ niệm" ----------

class _EntryOption extends StatelessWidget {
  const _EntryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.badge,
  });
  final ClIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  /// "Mới" next to the title.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: primary ? cl.colors.mintSoft : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
          border: primary
              ? Border.all(color: cl.colors.mintDeep, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary ? cl.colors.mintDeep : cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              alignment: Alignment.center,
              child: ClIcon(
                icon,
                size: 20,
                color: primary ? cl.colors.onMintDeep : cl.colors.mintText,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: cl.text.bodyStrong)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cl.colors.mintSoft,
                            borderRadius: BorderRadius.circular(ClRadius.pill),
                          ),
                          child: Text(
                            badge!,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.mintText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
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
}

Future<void> showAddSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
) async {
  final l10n = AppLocalizations.of(context);
  final keepsakes = ref.read(selectedKeepsakeAccessProvider);
  final choice = await showClSheet<String>(
    context: context,
    builder: (sheet) => _sheet([
      ClSheetHeader(title: l10n.addTitle),
      RecentToday(
        zone: c.zone,
        onPick: (_) => Navigator.of(sheet).pop('recent'),
      ),
      _EntryOption(
        icon: ClIcons.camera,
        // Android's system camera does photo or video, not both in one screen: two rows
        // (Q-066).
        title: defaultTargetPlatform == TargetPlatform.android
            ? l10n.addCameraPhoto
            : l10n.addCamera,
        subtitle: l10n.addCameraHint,
        primary: true,
        onTap: () => Navigator.of(sheet).pop('camera'),
      ),
      if (defaultTargetPlatform == TargetPlatform.android) ...[
        const SizedBox(height: ClSpace.s2),
        _EntryOption(
          icon: ClIcons.video,
          title: l10n.addCameraVideo,
          subtitle: l10n.addCameraHint,
          // Not 'video': that is "Video kỷ niệm" below.
          onTap: () => Navigator.of(sheet).pop('cameraVideo'),
        ),
      ],
      const SizedBox(height: ClSpace.s2),
      _EntryOption(
        icon: ClIcons.memories,
        title: l10n.addLibrary,
        subtitle: l10n.addLibraryHint,
        onTap: () => Navigator.of(sheet).pop('library'),
      ),
      const SizedBox(height: ClSpace.s2),
      _EntryOption(
        icon: ClIcons.upload,
        title: l10n.addFiles,
        subtitle: l10n.addFilesHint,
        onTap: () => Navigator.of(sheet).pop('files'),
      ),
      const SizedBox(height: ClSpace.s2),
      _EntryOption(
        icon: ClIcons.edit,
        title: l10n.addNote,
        subtitle: l10n.addNoteHint,
        onTap: () => Navigator.of(sheet).pop('note'),
      ),
      // MM02 "SÁNG TẠO & TỰ ĐỘNG" (D-068): in the beta, for parents.
      if (c.isParent && (keepsakes.cards || keepsakes.videos)) ...[
        const SizedBox(height: ClSpace.s4),
        Padding(
          padding: const EdgeInsets.only(left: ClSpace.s1),
          child: Text(
            l10n.ksCreateGroup,
            style: context.cl.text.caption.copyWith(
              color: context.cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        // The same rows as above (on the sheet's own surface, a card tile would vanish).
        if (keepsakes.videos) ...[
          const SizedBox(height: ClSpace.s2),
          _EntryOption(
            icon: ClIcons.camera,
            title: l10n.ksVideoTitle,
            subtitle: l10n.ksVideoTileHint,
            badge: l10n.ksNew,
            onTap: () => Navigator.of(sheet).pop('video'),
          ),
        ],
        if (keepsakes.cards) ...[
          const SizedBox(height: ClSpace.s2),
          _EntryOption(
            icon: ClIcons.star,
            title: l10n.ksCardTitle,
            subtitle: l10n.ksCardTileHintShort,
            badge: l10n.ksNew,
            onTap: () => Navigator.of(sheet).pop('card'),
          ),
        ],
      ],
    ]),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'card' || choice == 'video') {
    unawaited(
      context.push(
        choice == 'card' ? Routes.milestoneCard : Routes.memoryStory,
      ),
    );
    return;
  }
  List<PickedMedia>? picked;
  switch (choice) {
    case 'note':
      await showComposeSheet(context, ref, c, const []);
      return;
    case 'library':
      picked = await pickFromLibrary(context, ref);
    case 'files':
      picked = await pickFromFiles(context, ref);
    case 'camera':
      picked = await captureWithCamera(context, c.nickname);
    case 'cameraVideo':
      picked = await captureWithCamera(context, c.nickname, video: true);
    case 'recent':
      picked = lastRecentPick;
  }
  if (picked == null || picked.isEmpty || !context.mounted) return;
  await showComposeSheet(context, ref, c, picked);
}

// ---------- 10h "Soạn & chia sẻ" ----------

Future<void> showComposeSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  List<PickedMedia> picked,
) => showClSheet<void>(
  context: context,
  builder: (_) => ComposeSheet(ctx: c, picked: picked),
);

class ComposeSheet extends ConsumerStatefulWidget {
  const ComposeSheet({required this.ctx, required this.picked, super.key});
  final MemoryCtx ctx;
  final List<PickedMedia> picked;

  @override
  ConsumerState<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<ComposeSheet> {
  final _caption = TextEditingController();
  var _single = false;
  late DateTime _date = babyToday(widget.ctx.zone, widget.ctx.now);
  MilestoneRef? _milestone;
  var _albumIds = <String>[];
  var _switchedToFamily = false;
  var _audience = Audience.family; // D-001
  var _notify = true;
  String? _error;
  var _busy = false;

  bool get _note => widget.picked.isEmpty;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  DateTime get _memoryDate {
    if (_note || _single) return _date;
    final first = widget.picked
        .map((p) => p.captureAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final l = inBabyZone(widget.ctx.zone, first);
    return DateTime(l.year, l.month, l.day);
  }

  Future<void> _pickDate() async {
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final picked = widget.picked;
    String? range;
    if (picked.isNotEmpty) {
      final dates = picked.map((p) => inBabyZone(c.zone, p.captureAt)).toList()
        ..sort();
      final f = DateFormat('d MMM', c.locale);
      range =
          dates.first.day == dates.last.day &&
              dates.first.month == dates.last.month
          ? f.format(dates.first)
          : '${f.format(dates.first)} – ${f.format(dates.last)}';
    }
    final result = await showMemoryDateSheet(
      context,
      ctx: c,
      single: _single || _note,
      date: _date,
      captureRange: range,
      allowCapture: !_note,
    );
    if (result != null) {
      setState(() {
        _single = result.$1;
        _date = result.$2;
      });
    }
  }

  Future<void> _pickMilestone() async {
    final result = await showMilestoneSheet(
      context,
      ctx: memoryCtx(context, ref) ?? widget.ctx,
      selected: _milestone,
      date: _memoryDate,
    );
    if (result != null) setState(() => _milestone = result.$1);
  }

  /// 10h5: several albums; a Gia đình album switches "Ai thấy" to Gia đình (D-002).
  Future<void> _pickAlbums() async {
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final picked = await showAlbumPicker(context, ref, c, selected: _albumIds);
    if (picked == null || !mounted) return;
    final albums = ref.read(albumsProvider((c.babyId, true))).value ?? const [];
    final family = albums.any(
      (a) => picked.contains(a.id) && a.audience == Audience.family,
    );
    setState(() {
      _albumIds = picked;
      _switchedToFamily = family && _audience != Audience.family;
      if (family) _audience = Audience.family;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final caption = _caption.text.trim();
    if (_note && caption.isEmpty) {
      setState(() => _error = l10n.composeNoteRequired);
      return;
    }
    setState(() => _busy = true);
    final request = <String, Object?>{
      'babyId': c.babyId,
      'memoryId': newMemoryId(),
      'batchId': newBatchId(),
      'caption': caption.isEmpty ? null : caption,
      'audience': _audience.name,
      'notifyFamily': _audience == Audience.family && _notify,
      'dateMode': _single || _note ? 'single' : 'capture',
      'date': _single || _note ? isoDateOf(_date) : null,
      'milestone': _milestone?.toJson(),
      'albumIds': _albumIds,
    };
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final queue = ref.read(uploadQueueProvider.notifier);
    navigator.pop();
    if (_note) toaster.show(message: l10n.composeNoteSaved);
    await queue.enqueue(
      babyId: c.babyId,
      request: request,
      picked: widget.picked,
    );
    // FB5: a memory or a milestone saved is a happy moment (D-065).
    unawaited(
      ref
          .read(reviewPrompterProvider)
          .trigger(
            _milestone != null ? ReviewTrigger.milestone : ReviewTrigger.memory,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final picked = widget.picked;
    final dateValue = _note || _single
        ? (_date == babyToday(c.zone, c.now)
              ? _cap(l10n.dayToday)
              : DateFormat('d MMM y', c.locale).format(_date))
        : l10n.composeByCapture;
    return _sheet([
      ClSheetHeader(title: l10n.addTitle),
      if (picked.isNotEmpty) ...[
        Row(
          children: [
            for (var n = 0; n < 6; n++) ...[
              if (n > 0) const SizedBox(width: 6),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: n < 5 && n < picked.length
                      ? _PickedThumb(picked: picked[n])
                      : n == 5 && picked.length > 5
                      ? Container(
                          decoration: BoxDecoration(
                            color: cl.colors.surface2,
                            borderRadius: BorderRadius.circular(ClRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.composeMore(picked.length - 5),
                            style: cl.text.bodyStrong,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
      // Same field as "Tên album" in a sheet; a few lines grow in place.
      ClTextField(
        placeholder: _note ? l10n.composeNoteHint : l10n.composeCaption,
        controller: _caption,
        maxLength: 2000,
        maxLines: 5,
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
      ClCardGroup(
        color: cl.colors.surface2,
        children: [
          ClDetailRow(
            icon: ClIcons.clock,
            label: l10n.composeDate,
            value: dateValue,
            onTap: _pickDate,
          ),
          ClDetailRow(
            icon: ClIcons.star,
            label: l10n.composeMilestone,
            value: _milestone?.name ?? l10n.composeNoMilestone,
            onTap: _pickMilestone,
          ),
          if (!_note)
            ClDetailRow(
              icon: ClIcons.memories,
              label: l10n.memAlbums,
              value: albumsValue(
                l10n,
                ref.watch(albumsProvider((c.babyId, true))).value ?? const [],
                _albumIds,
              ),
              onTap: _pickAlbums,
            ),
        ],
      ),
      if (_switchedToFamily) ...[
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.albFamilySwitched,
          style: cl.text.caption.copyWith(color: cl.colors.mintText),
        ),
      ],
      const SizedBox(height: ClSpace.s4),
      Text(l10n.composeWho, style: cl.text.headline),
      const SizedBox(height: ClSpace.s2),
      AudienceCards(
        value: _audience,
        onChanged: (a) => setState(() => _audience = a),
      ),
      if (_audience == Audience.family) ...[
        const SizedBox(height: ClSpace.s3),
        _NotifyRow(
          title: l10n.composeNotify,
          subtitle: l10n.composeNotifyHint,
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
      ],
      const SizedBox(height: ClSpace.s4),
      ClButton(
        label: _note ? l10n.composeSaveNote : l10n.composeUpload(picked.length),
        expand: true,
        onPressed: _submit,
        loading: _busy,
      ),
      if (!_note) ...[
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.composeFootnote,
          textAlign: TextAlign.center,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    ]);
  }
}

class _PickedThumb extends StatelessWidget {
  const _PickedThumb({required this.picked});
  final PickedMedia picked;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClRadius.sm),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cl.colors.surface2),
            if (picked.thumbBytes != null)
              Image.memory(picked.thumbBytes!, fit: BoxFit.cover)
            else if (picked.type == MediaKind.photo)
              Image.file(picked.file, fit: BoxFit.cover, cacheWidth: 160),
            if (picked.type == MediaKind.video)
              Positioned(
                left: 3,
                bottom: 3,
                child: Text(
                  videoDuration(picked.durationMs),
                  style: cl.text.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Chỉ ba mẹ · Chỉ ba mẹ xem được" / "Gia đình · Cả nhà cùng xem" (10h, 10k).
class AudienceCards extends StatelessWidget {
  const AudienceCards({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final Audience value;
  final ValueChanged<Audience> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget card(Audience a, ClIcons icon, String title, String subtitle) {
      final on = a == value;
      return Expanded(
        child: ClPressable(
          onPressed: () => onChanged(a),
          selected: on,
          semanticLabel: '$title. $subtitle',
          // Fills its half: the pressable centres a child that only wraps its text, which
          // left the two cards narrow and far apart.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: on ? cl.colors.mintSoft : cl.colors.surface2,
              borderRadius: BorderRadius.circular(ClRadius.control + 4),
              border: Border.all(
                color: on ? cl.colors.mintDeep : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClIcon(
                  icon,
                  size: 20,
                  color: on ? cl.colors.mintText : cl.colors.ink,
                ),
                const SizedBox(height: ClSpace.s2),
                Text(
                  title,
                  style: cl.text.bodyStrong.copyWith(
                    color: on ? cl.colors.mintText : cl.colors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          Audience.parents,
          ClIcons.lock,
          l10n.audParents,
          l10n.audParentsHint,
        ),
        const SizedBox(width: ClSpace.s2),
        card(
          Audience.family,
          ClIcons.family,
          l10n.audFamily,
          l10n.audFamilyHint,
        ),
      ],
    );
  }
}

class _NotifyRow extends StatelessWidget {
  const _NotifyRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s3,
        ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.control + 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.bodyStrong),
                Text(
                  subtitle,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          ClToggle(value: value, onChanged: onChanged, semanticLabel: title),
        ],
      ),
    );
  }
}

// ---------- 10h2 "Ngày của kỷ niệm" ----------

/// (oneDateForAll, date); null when closed.
Future<(bool, DateTime)?> showMemoryDateSheet(
  BuildContext context, {
  required MemoryCtx ctx,
  required bool single,
  required DateTime date,
  required String? captureRange,
  bool allowCapture = true,
}) {
  var one = single || !allowCapture;
  var picked = date;
  final today = babyToday(ctx.zone, ctx.now);
  final min = ctx.dob ?? DateTime(today.year - 5);
  return showClSheet<(bool, DateTime)>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        return _sheet([
          ClSheetHeader(title: l10n.dateTitle),
          if (allowCapture)
            ClCardGroup(
              color: cl.colors.surface2,
              children: [
                ClOptionRow(
                  title: l10n.composeByCapture,
                  subtitle: l10n.dateByCaptureHint(captureRange ?? ''),
                  selected: !one,
                  onTap: () => setState(() => one = false),
                ),
                ClOptionRow(
                  title: l10n.dateOneForAll,
                  subtitle: l10n.dateOneForAllHint,
                  selected: one,
                  onTap: () => setState(() => one = true),
                ),
              ],
            ),
          const SizedBox(height: ClSpace.s3),
          IgnorePointer(
            ignoring: !one,
            child: Opacity(
              opacity: one ? 1 : 0.4,
              child: SizedBox(
                height: 180,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: cl.isNightCare
                        ? Brightness.dark
                        : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: cl.text.title2.copyWith(
                        color: cl.colors.ink,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: picked.isBefore(min) ? min : picked,
                    minimumDate: min,
                    maximumDate: today,
                    onDateTimeChanged: (d) =>
                        picked = DateTime(d.year, d.month, d.day),
                  ),
                ),
              ),
            ),
          ),
          if (ctx.dob != null)
            Text(
              l10n.dateBeforeBirth(ctx.nickname),
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop((one, picked)),
          ),
        ]);
      },
    ),
  );
}

// ---------- 10h3 / 10h4 milestones ----------

/// (milestone or null for "Không gắn mốc"); null when closed.
Future<(MilestoneRef?,)?> showMilestoneSheet(
  BuildContext context, {
  required MemoryCtx ctx,
  required MilestoneRef? selected,
  required DateTime date,
}) => showClSheet<(MilestoneRef?,)>(
  context: context,
  builder: (_) => _MilestoneSheet(ctx: ctx, selected: selected, date: date),
);

class _MilestoneSheet extends ConsumerStatefulWidget {
  const _MilestoneSheet({
    required this.ctx,
    required this.selected,
    required this.date,
  });
  final MemoryCtx ctx;
  final MilestoneRef? selected;
  final DateTime date;

  @override
  ConsumerState<_MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends ConsumerState<_MilestoneSheet> {
  final _search = TextEditingController();
  late MilestoneRef? _selected = widget.selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await showCreateMilestoneSheet(
      context,
      ctx: widget.ctx,
      name: _search.text.trim(),
    );
    if (created != null && mounted) Navigator.of(context).pop((created,));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final q = _search.text.trim().toLowerCase();
    final weeks = c.dob == null ? 0 : ageWeekOf(c.dob!, widget.date);
    final presets = [
      for (final p in PresetMilestone.forAgeWeeks(math.max(0, weeks - 1)))
        MilestoneRef(id: p.id, name: presetName(l10n, p), date: widget.date),
    ].where((m) => q.isEmpty || m.name.toLowerCase().contains(q)).toList();
    final own = [
      for (final m
          in ref.watch(familyMilestonesProvider(c.babyId)).value ??
              const <FamilyMilestone>[])
        m.ref,
    ].where((m) => q.isEmpty || m.name.toLowerCase().contains(q)).toList();

    Widget chip(MilestoneRef m) {
      final on = _selected?.id == m.id;
      return ClPressable(
        onPressed: () => setState(() => _selected = on ? null : m),
        selected: on,
        semanticLabel: m.name,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s3,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: on ? cl.colors.ink : cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClIcon(
                ClIcons.star,
                size: 14,
                color: on ? cl.colors.surface : cl.colors.ink,
              ),
              const SizedBox(width: 4),
              Text(
                m.name,
                style: cl.text.label.copyWith(
                  color: on ? cl.colors.surface : cl.colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final age = c.dob == null
        ? ''
        : ageShort(l10n, c.dob!, babyToday(c.zone, c.now));
    return _sheet([
      ClSheetHeader(title: l10n.msTitle),
      ClTextField(
        placeholder: l10n.msSearch,
        controller: _search,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: ClSpace.s3),
      if (presets.isNotEmpty) ...[
        Text(
          l10n.msSuggest(age),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [for (final m in presets) chip(m)],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
      if (own.isNotEmpty) ...[
        Text(
          l10n.msOwn,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [for (final m in own) chip(m)],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
      ClPressable(
        onPressed: _create,
        semanticLabel: l10n.msCreate,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClRadius.pill),
            border: Border.all(color: cl.colors.controlBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText),
              const SizedBox(width: 6),
              Text(
                q.isEmpty
                    ? l10n.msCreate
                    : '${l10n.msCreate}: “${_search.text.trim()}”',
                style: cl.text.label.copyWith(
                  color: cl.colors.mintText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: ClSpace.s3),
      Row(
        children: [
          ClPressable(
            onPressed: () => setState(() => _selected = null),
            semanticLabel: l10n.composeNoMilestone,
            child: Text(
              l10n.composeNoMilestone,
              style: cl.text.label.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            l10n.msOnePer,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
      ClButton(
        label: l10n.actionDone,
        expand: true,
        onPressed: () => Navigator.of(context).pop((_selected,)),
      ),
    ]);
  }
}

/// 10h4 "Tạo mốc mới": name + date (default today), shared with the whole family (R-105).
Future<MilestoneRef?> showCreateMilestoneSheet(
  BuildContext context, {
  required MemoryCtx ctx,
  String name = '',
}) => showClSheet<MilestoneRef>(
  context: context,
  builder: (_) => _CreateMilestone(ctx: ctx, name: name),
);

class _CreateMilestone extends ConsumerStatefulWidget {
  const _CreateMilestone({required this.ctx, required this.name});
  final MemoryCtx ctx;
  final String name;

  @override
  ConsumerState<_CreateMilestone> createState() => _CreateMilestoneState();
}

class _CreateMilestoneState extends ConsumerState<_CreateMilestone> {
  late final _name = TextEditingController(text: widget.name);
  late DateTime _date = babyToday(widget.ctx.zone, widget.ctx.now);
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.msNameRequired);
      return;
    }
    setState(() => _busy = true);
    final toaster = ClToaster.of(context);
    try {
      final ref0 = await ref
          .read(memoryRepositoryProvider)
          .createMilestone(widget.ctx.babyId, widget.ctx.me, name, _date)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              // Offline: the write is queued by Firestore; use it now.
              return MilestoneRef(
                id: newMilestoneId(),
                name: name,
                date: _date,
              );
            },
          );
      if (mounted) Navigator.of(context).pop(ref0);
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = memoryCtx(context, ref) ?? widget.ctx;
    final today = babyToday(c.zone, c.now);
    final dateLabel = _date == today
        ? _cap(l10n.dayToday)
        : DateFormat('d MMM y', c.locale).format(_date);
    final preview = MilestoneRef(
      id: 'p_preview',
      name: _name.text.trim().isEmpty ? l10n.msName : _name.text.trim(),
      date: _date,
    );
    return _sheet([
      ClSheetHeader(title: l10n.msCreate),
      ClTextField(
        label: l10n.msName,
        controller: _name,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() => _error = null),
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: cl.text.label.copyWith(color: cl.colors.error)),
      ],
      const SizedBox(height: ClSpace.s3),
      ClCardGroup(
        color: cl.colors.surface2,
        children: [
          ClDetailRow(
            icon: ClIcons.clock,
            label: l10n.composeDate,
            value: dateLabel,
            onTap: () async {
              final r = await showMemoryDateSheet(
                context,
                ctx: c,
                single: true,
                date: _date,
                captureRange: null,
                allowCapture: false,
              );
              if (r != null) setState(() => _date = r.$2);
            },
          ),
        ],
      ),
      const SizedBox(height: ClSpace.s3),
      Row(
        children: [
          Text(
            l10n.msPreview,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(width: ClSpace.s2),
          Flexible(child: MilestoneChip(milestone: preview)),
        ],
      ),
      const SizedBox(height: ClSpace.s3),
      Text(
        l10n.msShared,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s4),
      ClButton(
        label: l10n.msCreateTag,
        expand: true,
        onPressed: _save,
        loading: _busy,
      ),
    ]);
  }
}

// ---------- 10i "Hàng đợi tải lên" ----------

Future<void> showQueueSheet(BuildContext context, WidgetRef ref, MemoryCtx c) =>
    showClSheet<void>(
      context: context,
      builder: (_) => QueueSheet(ctx: c),
    );

class QueueSheet extends ConsumerWidget {
  const QueueSheet({required this.ctx, super.key});
  final MemoryCtx ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(uploadQueueProvider);
    final queue = ref.read(uploadQueueProvider.notifier);
    final all = [
      for (final b in view.batches)
        if (b.babyId == ctx.babyId) b,
    ];
    // While something uploads, only what is still going: a finished batch kept for its result
    // made "2 of 5" out of 4 chosen (owner, 2026-10-15). Once all are done, their results.
    final active = [
      for (final b in all)
        if (!b.done) b,
    ];
    final batches = active.isEmpty ? all : active;
    final items = [
      for (final b in batches)
        for (final i in b.items)
          if (i.state != QueueState.cancelled) i,
    ];
    final done = items.where((i) => i.state == QueueState.uploaded).length;
    final failed = items.where((i) => i.state == QueueState.failed).length;
    final unreadable = items
        .where((i) => i.state == QueueState.unreadable)
        .length;
    final sent = items.fold<int>(0, (s, i) => s + math.min(i.sent, i.bytes));
    final bytes = items.fold<int>(0, (s, i) => s + i.bytes);
    final notify = batches.any((b) => b.notifyFamily && !b.done);
    final finished = batches.every((b) => b.done);

    return _sheet([
      ClSheetHeader(title: l10n.qTitle),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
          child: Text(
            l10n.qEmpty,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.control + 4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.qSummaryNoEta(done, items.length),
                      style: cl.text.bodyStrong,
                    ),
                  ),
                  if (!finished)
                    ClButton(
                      label: view.paused ? l10n.qResume : l10n.qPause,
                      style: ClButtonStyle.secondary,
                      onPressed: () => queue.setPaused(!view.paused),
                    ),
                ],
              ),
              const SizedBox(height: ClSpace.s2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: bytes == 0 ? 0 : sent / bytes,
                  minHeight: 6,
                  color: cl.colors.mintDeep,
                  backgroundColor: cl.colors.surface,
                ),
              ),
              if (notify) ...[
                const SizedBox(height: ClSpace.s2),
                Text(
                  l10n.qNotice,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
              if (failed + unreadable > 0) ...[
                const SizedBox(height: ClSpace.s2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cl.colors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      [
                        if (failed > 0) l10n.qFailed(failed),
                        if (unreadable > 0) l10n.qUnreadable(unreadable),
                      ].join(' · '),
                      style: cl.text.caption.copyWith(color: cl.colors.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.35,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final b in batches)
                for (final i in b.items)
                  if (i.state != QueueState.cancelled)
                    _QueueRow(
                      item: i,
                      locale: ctx.locale,
                      paused: b.paused,
                      refused: b.refused,
                    ),
            ],
          ),
        ),
      ],
      const SizedBox(height: ClSpace.s3),
      _NotifyRow(
        title: l10n.qWifiOnly,
        subtitle: l10n.qWifiOnlyHint,
        value: ref.watch(videoWifiOnlyProvider),
        onChanged: (v) {
          ref.read(videoWifiOnlyProvider.notifier).set(v);
          unawaited(queue.retry());
        },
      ),
      if (failed > 0) ...[
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.qRetryAll(failed),
          icon: ClIcons.retry,
          style: ClButtonStyle.secondary,
          expand: true,
          onPressed: () => queue.retry(),
        ),
      ],
      if (finished && batches.isNotEmpty) ...[
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: () {
            for (final b in batches) {
              unawaited(queue.dismiss(b.batchId));
            }
            Navigator.of(context).pop();
          },
        ),
      ],
      const SizedBox(height: ClSpace.s2),
      Text(
        l10n.qFootnote,
        textAlign: TextAlign.center,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    ]);
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    required this.item,
    required this.locale,
    this.paused = false,
    this.refused = false,
  });
  final QueueItem item;
  final String locale;

  /// The session was refused: uploads switched off (waits) or not allowed ("Thử lại").
  final bool paused;
  final bool refused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final queue = ref.read(uploadQueueProvider.notifier);
    final i = item;
    final (String status, Color tone) = switch (i.state) {
      QueueState.uploading => (
        l10n.rowProgress(
          i.bytes == 0 ? 0 : (i.sent * 100 ~/ i.bytes).clamp(0, 100),
          byteSize(locale, i.sent),
          byteSize(locale, i.bytes),
        ),
        cl.colors.mintText,
      ),
      QueueState.waitingWifi => (
        l10n.rowWaitingWifi(byteSize(locale, i.bytes)),
        cl.colors.inkMuted,
      ),
      QueueState.failed when refused || i.rejected => (
        l10n.rowRejected,
        cl.colors.error,
      ),
      QueueState.failed => (l10n.rowFailed, cl.colors.error),
      QueueState.unreadable => (l10n.rowUnreadable, cl.colors.error),
      QueueState.uploaded => (l10n.rowDone, cl.colors.inkMuted),
      QueueState.paused => (l10n.rowPaused, cl.colors.inkMuted),
      QueueState.waitingQuota => (l10n.rowWaitingQuota, cl.colors.error),
      QueueState.cancelled => (l10n.rowCancelled, cl.colors.inkMuted),
      QueueState.pendingSession when paused => (
        l10n.rowUploadsPaused,
        cl.colors.inkMuted,
      ),
      QueueState.pendingSession => (l10n.rowPreparing, cl.colors.inkMuted),
      QueueState.queued => (l10n.rowQueued, cl.colors.inkMuted),
    };
    final thumb = i.thumbPath ?? (i.isVideo ? i.posterPath : i.localPath);
    // "×" removes the item from the queue in every unfinished state, failed ones included.
    final remove = ClPressable(
      onPressed: () => queue.cancel(i.mediaId),
      semanticLabel: l10n.a11yCancelUpload(i.name),
      child: SizedBox(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        child: Center(
          child: ClIcon(ClIcons.close, size: 18, color: cl.colors.inkMuted),
        ),
      ),
    );
    final action = switch (i.state) {
      QueueState.uploaded => ClIcon(
        ClIcons.check,
        size: 20,
        color: cl.colors.mintText,
      ),
      // Icon-only so the file name and status keep their room.
      QueueState.failed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClPressable(
            onPressed: () => queue.retry(i.mediaId),
            semanticLabel: '${l10n.actionRetry} · ${i.name}',
            child: SizedBox(
              width: ClSpace.tapMin,
              height: ClSpace.tapMin,
              child: Center(
                child: ClIcon(
                  ClIcons.retry,
                  size: 20,
                  color: cl.colors.mintText,
                ),
              ),
            ),
          ),
          remove,
        ],
      ),
      _ => remove,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ClRadius.sm),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: cl.colors.surface2),
                  if (thumb != null && File(thumb).existsSync())
                    Image.file(File(thumb), fit: BoxFit.cover, cacheWidth: 120),
                  if (i.state == QueueState.failed ||
                      i.state == QueueState.unreadable)
                    ColoredBox(
                      color: Colors.black38,
                      child: Center(
                        child: ClIcon(
                          ClIcons.alert,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.label,
                ),
                Text(status, style: cl.text.caption.copyWith(color: tone)),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}

// ---------- 10b3 selection actions ----------

List<MediaItem> _selectedItems(WidgetRef ref, MemoryCtx c) {
  final ids = ref.read(memorySelectionProvider) ?? const {};
  final all = ref.read(mediaProvider((c.babyId, c.isParent))).value ?? const [];
  return [
    for (final i in all)
      if (ids.contains(i.id)) i,
  ];
}

/// True when the change was saved.
Future<bool> _update(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  List<MediaItem> items,
  Map<String, Object?> change,
  String done, {
  VoidCallback? undo,
}) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  try {
    await withClProgress(
      context,
      () => ref.read(memoryRepositoryProvider).update(c.babyId, [
        for (final i in items) i.id,
      ], change),
    );
    ref.read(memorySelectionProvider.notifier).end();
    toaster.show(
      message: done,
      actionLabel: undo == null ? null : l10n.undo,
      onAction: undo,
    );
    return true;
  } on Object {
    toaster.show(message: l10n.toastActionFailed, error: true);
    return false;
  }
}

Future<void> showSelectionActions(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
) async {
  final items = _selectedItems(ref, c);
  if (items.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  final parent = c.isParent;
  // Thiệp cột mốc / Video kỷ niệm from the chosen photos (D-068), when the family has them.
  final keepsakes = ref.read(selectedKeepsakeAccessProvider);
  final photos = [
    for (final i in items)
      if (!i.isVideo && i.generatedKind == null) i.id,
  ];
  final action = await showClSheet<String>(
    context: context,
    builder: (sheet) {
      final cl = sheet.cl;
      Widget tile(ClIcons icon, String label, String? value) => Expanded(
        child: ClPressable(
          onPressed: value == null
              ? null
              : () => Navigator.of(sheet).pop(value),
          semanticLabel: label,
          child: Opacity(
            opacity: value == null ? 0.4 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control + 4),
              ),
              child: Column(
                children: [
                  ClIcon(icon, size: 22, color: cl.colors.mintText),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      Widget row(ClIcons icon, String title, String subtitle, String? value) =>
          ClPressable(
            onPressed: value == null
                ? null
                : () => Navigator.of(sheet).pop(value),
            semanticLabel: '$title. $subtitle',
            child: Opacity(
              opacity: value == null ? 0.5 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s3,
                  vertical: ClSpace.s3,
                ),
                child: Row(
                  children: [
                    ClIcon(icon, size: 20, color: cl.colors.mintText),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: cl.text.bodyStrong),
                          Text(
                            subtitle,
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (value != null)
                      ClIcon(
                        ClIcons.chevronRight,
                        size: 18,
                        color: cl.colors.inkMuted,
                      ),
                  ],
                ),
              ),
            ),
          );
      return _sheet([
        ClSheetHeader(title: l10n.memSelected(items.length)),
        Row(
          children: [
            tile(ClIcons.family, l10n.actWho, parent ? 'who' : null),
            const SizedBox(width: ClSpace.s2),
            tile(ClIcons.memories, l10n.actAlbum, parent ? 'album' : null),
            const SizedBox(width: ClSpace.s2),
            tile(ClIcons.download, l10n.actDownload, 'download'),
            const SizedBox(width: ClSpace.s2),
            tile(ClIcons.link, l10n.actSend, parent ? 'send' : null),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.actMore,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          color: cl.colors.surface2,
          children: [
            row(
              ClIcons.bookmark,
              l10n.actFavorite,
              l10n.actFavoriteHint,
              'favorite',
            ),
            row(
              ClIcons.star,
              l10n.msTitle,
              l10n.actMilestoneHint,
              parent ? 'milestone' : null,
            ),
            row(
              ClIcons.clock,
              l10n.actDate,
              l10n.actDateHint,
              parent ? 'date' : null,
            ),
            if (parent && keepsakes.cards)
              row(
                ClIcons.star,
                l10n.actMakeCard,
                l10n.actMakeCardHint,
                photos.isEmpty ? null : 'card',
              ),
            if (parent && keepsakes.videos)
              row(
                ClIcons.camera,
                l10n.actMakeVideo,
                l10n.actMakeVideoHint,
                photos.isEmpty ? null : 'video',
              ),
            row(ClIcons.spark, l10n.actStory, l10n.actSoon, null),
            row(
              ClIcons.memories,
              l10n.actCover,
              l10n.actCoverHint,
              parent && items.length == 1 && !items.single.isVideo
                  ? 'cover'
                  : null,
            ),
          ],
        ),
      ]);
    },
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case 'card' || 'video':
      ref.read(memorySelectionProvider.notifier).end();
      unawaited(
        context.push(
          action == 'card' ? Routes.milestoneCard : Routes.memoryStory,
          extra: photos,
        ),
      );
    case 'album':
      final picked = await showAlbumPicker(
        context,
        ref,
        c,
        mediaIds: [for (final i in items) i.id],
      );
      if (picked == null || picked.isEmpty || !context.mounted) return;
      final repo = ref.read(memoryRepositoryProvider);
      final toaster = ClToaster.of(context);
      final albums =
          ref.read(albumsProvider((c.babyId, true))).value ?? const [];
      try {
        await withClProgress(context, () async {
          for (final a in picked) {
            await repo.addToAlbum(c.babyId, a, [for (final i in items) i.id]);
          }
        });
        ref.read(memorySelectionProvider.notifier).end();
        toaster.show(
          message: l10n.albAdded(
            items.length,
            albums.where((a) => a.id == picked.first).firstOrNull?.name ?? '',
          ),
        );
      } on Object {
        toaster.show(message: l10n.toastActionFailed, error: true);
      }
    case 'favorite':
      final toaster = ClToaster.of(context);
      try {
        // A Firestore write (instant, also offline): no spinner, it would wait for the network.
        for (final i in items) {
          await ref
              .read(memoryRepositoryProvider)
              .setFavorite(c.babyId, c.me.uid, i.id, true);
        }
        ref.read(memorySelectionProvider.notifier).end();
        toaster.show(message: l10n.favAdded);
      } on Object {
        toaster.show(message: l10n.toastActionFailed, error: true);
      }
    case 'cover':
      final picked = await showAlbumPicker(context, ref, c);
      if (picked == null || picked.isEmpty || !context.mounted) return;
      final repo = ref.read(memoryRepositoryProvider);
      final toaster = ClToaster.of(context);
      try {
        await withClProgress(context, () async {
          await repo.addToAlbum(c.babyId, picked.first, [items.single.id]);
          await repo.updateAlbum(c.babyId, picked.first, {
            'kind': 'cover',
            'mediaId': items.single.id,
          });
        });
        ref.read(memorySelectionProvider.notifier).end();
        toaster.show(message: l10n.albCoverSet);
      } on Object {
        toaster.show(message: l10n.toastActionFailed, error: true);
      }
    case 'download':
      await saveToPhotos(context, items);
    case 'send':
      await shareItems(context, items);
    case 'who':
      await _changeAudience(context, ref, c, items);
    case 'milestone':
      final first = items
          .map((i) => i.captureAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final l = inBabyZone(c.zone, first);
      final r = await showMilestoneSheet(
        context,
        ctx: c,
        selected: null,
        date: DateTime(l.year, l.month, l.day),
      );
      if (r == null || !context.mounted) return;
      await _update(context, ref, c, items, {
        'kind': 'milestone',
        'milestone': r.$1?.toJson(),
      }, l10n.toastTagged(items.length));
    case 'date':
      final first = inBabyZone(c.zone, items.first.captureAt);
      final r = await showMemoryDateSheet(
        context,
        ctx: c,
        single: true,
        date: DateTime(first.year, first.month, first.day),
        captureRange: null,
        allowCapture: false,
      );
      if (r == null || !context.mounted) return;
      await _update(context, ref, c, items, {
        'kind': 'date',
        'date': isoDateOf(r.$2),
      }, l10n.toastDateChanged(items.length));
  }
}

/// "Ai thấy" for a selection; widening private items goes through 10o.
Future<void> _changeAudience(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  List<MediaItem> items,
) async {
  final l10n = AppLocalizations.of(context);
  var choice = items.every((i) => i.effectiveAudience == Audience.family)
      ? Audience.family
      : Audience.parents;
  final picked = await showClSheet<Audience>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) => _sheet([
        ClSheetHeader(title: l10n.whoItemsTitle(items.length)),
        AudienceCards(
          value: choice,
          onChanged: (a) => setState(() => choice = a),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.viewApply,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(choice),
        ),
      ]),
    ),
  );
  if (picked == null || !context.mounted) return;
  if (picked == Audience.parents) {
    await _update(context, ref, c, items, {
      'kind': 'audience',
      'audience': 'parents',
      'notifyFamily': false,
    }, l10n.toastParentsOnly(items.length));
    return;
  }
  final private = [
    for (final i in items)
      if (i.effectiveAudience == Audience.parents) i,
  ];
  if (private.isEmpty) return;
  await showSharePrivateSheet(context, ref, c, private);
}

/// 10o "Chia sẻ với gia đình?" (158:21457, R-118).
Future<void> showSharePrivateSheet(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  List<MediaItem> items,
) async {
  final l10n = AppLocalizations.of(context);
  var notify = true;
  final allPhotos = items.every((i) => !i.isVideo);
  final ok = await showClSheet<bool>(
    context: context,
    builder: (sheet) => Consumer(
      builder: (context, ref, _) => StatefulBuilder(
        builder: (context, setState) {
          final cl = context.cl;
          final members =
              ref.watch(familyMembersProvider(c.babyId)).value ?? const [];
          final relatives = members
              .where((m) => m.role == MemberRole.relative && m.isActive)
              .length;
          final caregivers = [
            for (final m in members)
              if (m.role == MemberRole.caregiver && m.isActive) m.displayName,
          ];
          return _sheet([
            ClSheetHeader(title: l10n.shareTitle),
            Row(
              children: [
                for (final (n, i) in items.take(3).indexed) ...[
                  if (n > 0) const SizedBox(width: 6),
                  SizedBox(width: 48, height: 48, child: MediaTile(item: i)),
                ],
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    allPhotos
                        ? l10n.sharePrivatePhotos(items.length)
                        : l10n.sharePrivateItems(items.length),
                    style: cl.text.bodyStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.shareWillSee,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control + 4),
              ),
              child: Row(
                children: [
                  const AuthorAvatar(name: 'G'),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.audFamily, style: cl.text.bodyStrong),
                        Text(
                          l10n.shareRelatives(relatives),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClIcon(ClIcons.eye, size: 20, color: cl.colors.mintText),
                ],
              ),
            ),
            if (caregivers.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.shareCaregivers(caregivers.join(', ')),
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: ClSpace.s3),
            _NotifyRow(
              title: l10n.composeNotify,
              subtitle: l10n.shareNotifyHint,
              value: notify,
              onChanged: (v) => setState(() => notify = v),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: allPhotos
                  ? l10n.shareNPhotos(items.length)
                  : l10n.shareN(items.length),
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            ClButton(
              label: l10n.actionLater,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ]);
        },
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await _update(context, ref, c, items, {
    'kind': 'audience',
    'audience': 'family',
    'notifyFamily': notify,
  }, l10n.toastShared(items.length));
}

// ---------- 10b4 delete ----------

Future<void> confirmDeleteSelection(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
) async {
  await confirmDeleteMedia(context, ref, c, _selectedItems(ref, c));
}

/// 10b4 for [items] (the selection, or the one open in the viewer): true once deleted (Thùng
/// rác keeps them 30 days, "Hoàn tác" on the toast).
Future<bool> confirmDeleteMedia(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
  List<MediaItem> items,
) async {
  if (items.isEmpty) return false;
  final l10n = AppLocalizations.of(context);
  final ok = await showClSheet<bool>(
    context: context,
    builder: (sheet) {
      final cl = sheet.cl;
      return _sheet([
        ClSheetHeader(title: l10n.delTitle(items.length)),
        SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final (n, i) in items.take(5).indexed) ...[
                if (n > 0) const SizedBox(width: 6),
                SizedBox(width: 56, height: 56, child: MediaTile(item: i)),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Text(l10n.delBody, style: cl.text.body),
        const SizedBox(height: ClSpace.s3),
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.control + 4),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.clock, size: 18, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(child: Text(l10n.delRecover, style: cl.text.label)),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Row(
          children: [
            ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s2),
            Text(
              l10n.delParentsOnly,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.delN(items.length),
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
        ClButton(
          label: l10n.actionCancel,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
      ]);
    },
  );
  if (ok != true || !context.mounted) return false;
  final repo = ref.read(memoryRepositoryProvider);
  return _update(
    context,
    ref,
    c,
    items,
    {'kind': 'delete'},
    l10n.toastDeleted(items.length),
    undo: () => unawaited(
      repo
          .update(c.babyId, [for (final i in items) i.id], {'kind': 'restore'})
          .catchError((Object _) {}),
    ),
  );
}

// ---------- 10b5 "Đi tới tháng" ----------

Future<void> showGotoMonth(
  BuildContext context,
  MemoryCtx c,
  Map<DateTime, List<MediaItem>> months,
  void Function(DateTime month) jumpTo,
) async {
  final today = babyToday(c.zone, c.now);
  final firstYear =
      c.dob?.year ??
      months.keys.fold<int>(today.year, (y, m) => math.min(y, m.year));
  final years = [for (var y = firstYear; y <= today.year; y++) y];
  var year = months.keys.isEmpty ? today.year : months.keys.first.year;
  final picked = await showClSheet<DateTime>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        int count(int y, int m) => months[DateTime(y, m)]?.length ?? 0;
        bool hasYear(int y) => months.keys.any((k) => k.year == y);
        return _sheet([
          ClSheetHeader(title: l10n.gotoTitle),
          Wrap(
            spacing: ClSpace.s2,
            children: [
              for (final y in years)
                Opacity(
                  opacity: hasYear(y) ? 1 : 0.4,
                  child: ClFilterChip(
                    label: '$y',
                    selected: y == year,
                    onTap: hasYear(y) ? () => setState(() => year = y) : () {},
                  ),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ClSpace.s2,
            crossAxisSpacing: ClSpace.s2,
            childAspectRatio: 1.25,
            children: [
              for (var m = 1; m <= 12; m++)
                () {
                  final n = count(year, m);
                  final current =
                      DateTime(year, m) == DateTime(today.year, today.month);
                  final label = c.locale.startsWith('vi')
                      ? l10n.gotoMonthShort(m, '')
                      : l10n.gotoMonthShort(
                          0,
                          DateFormat.MMM(c.locale).format(DateTime(year, m)),
                        );
                  return Opacity(
                    opacity: n == 0 ? 0.45 : 1,
                    child: ClPressable(
                      onPressed: n == 0
                          ? null
                          : () => Navigator.of(sheet).pop(DateTime(year, m)),
                      semanticLabel: label,
                      child: Container(
                        decoration: BoxDecoration(
                          color: current
                              ? cl.colors.mintSoft
                              : cl.colors.surface2,
                          borderRadius: BorderRadius.circular(ClRadius.control),
                          border: current
                              ? Border.all(
                                  color: cl.colors.mintDeep,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: cl.text.bodyStrong),
                            Text(
                              n == 0 ? '—' : l10n.memItemCount(n),
                              style: cl.text.caption.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
          if (c.dob != null) ...[
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.gotoNote(
                c.nickname,
                DateFormat('d MMMM, y', c.locale).format(c.dob!),
              ),
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ]);
      },
    ),
  );
  if (picked != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpTo(picked));
  }
}

// ---------- v1.0 10b sheets (391:2761, 391:2888, 391:3028) ----------

/// "Xem ảnh theo": Tuần tuổi · Tháng tuổi · Tháng trong năm; a tap applies and closes.
Future<void> showPhotoGroupSheet(BuildContext context, WidgetRef ref) =>
    showClSheet<void>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        final view = ref.read(memoryViewProvider);
        return _sheet([
          ClSheetHeader(title: l10n.photoByTitle),
          _OptionGroup(
            children: [
              for (final (g, title, sub) in [
                (PhotoGroup.ageWeek, l10n.photoByWeek, l10n.photoByWeekSub),
                (
                  PhotoGroup.ageMonth,
                  l10n.photoByAgeMonth,
                  l10n.photoByAgeMonthSub,
                ),
                (PhotoGroup.month, l10n.photoByMonth, l10n.photoByMonthSub),
              ])
                _OptionRow(
                  leading: _Radio(on: view.photoGroup == g),
                  title: title,
                  subtitle: sub,
                  selected: view.photoGroup == g,
                  onTap: () {
                    ref
                        .read(memoryViewProvider.notifier)
                        .set(view.copyWith(photoGroup: g));
                    Navigator.of(sheet).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
        ]);
      },
    );

/// "Hiển thị": Ảnh & video · Chỉ ảnh · Chỉ video · Đã yêu thích, each with its count.
Future<void> showPhotoShowSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<MediaItem> items,
  required Set<String> favorites,
}) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final view = ref.read(memoryViewProvider);
    final photos = items.where((i) => !i.isVideo).length;
    final videos = items.length - photos;
    final faved = items.where((i) => favorites.contains(i.id)).length;
    return _sheet([
      ClSheetHeader(title: l10n.photoShowTitle),
      _OptionGroup(
        children: [
          for (final (show, icon, title, count) in [
            (
              PhotoShow.all,
              ClIcons.camera,
              l10n.photoShowAll,
              l10n.memItemCount(items.length),
            ),
            (
              PhotoShow.photos,
              ClIcons.memories,
              l10n.photoShowPhotos,
              l10n.memPhotoCount(photos),
            ),
            (
              PhotoShow.videos,
              ClIcons.eye,
              l10n.photoShowVideos,
              l10n.memVideoCount(videos),
            ),
            (
              PhotoShow.favorites,
              ClIcons.bookmark,
              l10n.photoShowFavorites,
              l10n.memItemCount(faved),
            ),
          ])
            _OptionRow(
              leading: ClIcon(icon, size: 20, color: sheet.cl.colors.mintText),
              title: title,
              subtitle: count,
              selected: view.photoShow == show,
              trailingCheck: true,
              onTap: () {
                ref
                    .read(memoryViewProvider.notifier)
                    .set(view.copyWith(photoShow: show));
                Navigator.of(sheet).pop();
              },
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
    ]);
  },
);

/// One week (or month) of age in "Đi tới tuần".
typedef PhotoSection = ({
  Object key,
  String title,
  String subtitle,
  MediaItem? cover,
});

/// "Đi tới tuần" / "Đi tới tháng tuổi": newest first, a cover, the range and how many items;
/// the one in view is checked.
Future<void> showGotoSection(
  BuildContext context, {
  required String title,
  required List<PhotoSection> sections,
  required Object? current,
  required void Function(Object key) jumpTo,
}) async {
  final picked = await showClSheet<Object>(
    context: context,
    builder: (sheet) => _sheet([
      ClSheetHeader(title: title),
      _OptionGroup(
        children: [
          for (final s in sections)
            _OptionRow(
              leading: SizedBox(
                width: 44,
                height: 44,
                child: s.cover == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: sheet.cl.colors.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    : IgnorePointer(
                        child: MediaTile(item: s.cover!, radius: 10),
                      ),
              ),
              title: s.title,
              subtitle: s.subtitle,
              selected: s.key == current,
              trailingCheck: true,
              onTap: () => Navigator.of(sheet).pop(s.key),
            ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
    ]),
  );
  if (picked != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpTo(picked));
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cl.colors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? c.mintDeep : c.controlBorder,
          width: on ? 7 : 1.5,
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailingCheck = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final bool trailingCheck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong.copyWith(fontSize: 15)),
                  Text(
                    subtitle,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingCheck && selected)
              ClIcon(ClIcons.check, size: 20, color: cl.colors.mintText),
          ],
        ),
      ),
    );
  }
}

// ---------- 10c "Cách xem" ----------

Future<void> showViewOptions(
  BuildContext context,
  WidgetRef ref,
  MemoryCtx c,
) async {
  var v = ref.read(memoryViewProvider);
  final result = await showClSheet<MemoryView>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        Widget group<T>(
          String label,
          List<(T, String)> options,
          T value,
          void Function(T) onTap,
        ) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final (o, name) in options)
                  ClFilterChip(
                    label: name,
                    selected: o == value,
                    onTap: () => setState(() => onTap(o)),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
          ],
        );
        return _sheet([
          ClSheetHeader(title: l10n.viewTitle),
          group(
            l10n.viewGroup,
            [
              (MemoryGroup.day, l10n.viewDay),
              (MemoryGroup.week, l10n.viewWeek),
              (MemoryGroup.month, l10n.viewMonth),
            ],
            v.group,
            (g) => v = v.copyWith(group: g),
          ),
          group(
            l10n.viewLayout,
            [
              (MemoryLayout.small, l10n.viewSmall),
              (MemoryLayout.large, l10n.viewLarge),
              (MemoryLayout.list, l10n.viewList),
            ],
            v.layout,
            (g) => v = v.copyWith(layout: g),
          ),
          group(
            l10n.viewShow,
            [
              (MemoryShow.all, l10n.filterAll),
              (MemoryShow.photos, l10n.memPhotos),
              (MemoryShow.videos, l10n.pickVideos),
              (MemoryShow.milestones, l10n.viewWithMilestone),
            ],
            v.show,
            (g) => v = v.copyWith(show: g),
          ),
          if (c.isParent)
            group(
              l10n.composeWho,
              [
                (MemoryWho.all, l10n.filterAll),
                (MemoryWho.family, l10n.audFamily),
                (MemoryWho.parents, l10n.audParents),
              ],
              v.who,
              (g) => v = v.copyWith(who: g),
            ),
          if (c.isParent) ...[
            ClCardGroup(
              color: cl.colors.surface2,
              children: [
                ClListRow(
                  title: l10n.viewAsRelative,
                  subtitle: l10n.viewAsRelativeHint,
                  leading: ClIcon(
                    ClIcons.eye,
                    size: 20,
                    color: cl.colors.mintText,
                  ),
                  onTap: () => Navigator.of(
                    sheet,
                  ).pop(v.copyWith(asRelative: true, who: MemoryWho.all)),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
          ],
          ClButton(
            label: l10n.viewApply,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(v),
          ),
        ]);
      },
    ),
  );
  if (result != null) {
    ref.read(memoryViewProvider.notifier).set(result);
    if (result.asRelative) ref.read(memorySelectionProvider.notifier).end();
  }
}
