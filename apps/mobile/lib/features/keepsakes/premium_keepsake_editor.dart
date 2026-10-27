import '../premium/premium_repository.dart';
import '../premium/premium_v2.dart';
import 'video_quality_selector.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';
import '../memories/media_picker.dart';
import '../memories/memories_screen.dart' show MemoryCtx, memoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/upload_queue.dart';
import 'keepsake_card_view.dart';
import 'keepsake_catalog.dart';
import 'keepsake_jobs.dart';
import 'keepsake_occasions.dart';
import 'keepsake_personalization.dart';
import 'keepsake_preview.dart';
import 'memory_story_screens.dart' show KeepsakeMusicSheet;
import 'milestone_card_screens.dart'
    show CardDraft, exportCard, cardMemoryRequest;

/// Premium templates. All creative copy and field labels come from the catalog.
/// Old templates keep their existing editors. Nothing here unlocks premium access.
class PremiumKeepsakeEditor extends ConsumerStatefulWidget {
  const PremiumKeepsakeEditor({
    required this.template,
    required this.babyId,
    this.cardDraft,
    this.mediaIds = const [],
    this.initialLocale,
    super.key,
  });
  final KeepsakeTemplate template;
  final String babyId;
  final CardDraft? cardDraft;
  final List<String> mediaIds;
  final String? initialLocale;

  @override
  ConsumerState<PremiumKeepsakeEditor> createState() => _PremiumEditorState();
}

class _PremiumEditorState extends ConsumerState<PremiumKeepsakeEditor> {
  final _boundary = GlobalKey();
  final _scroll = ScrollController();
  int _section = 0;
  String? _quality;
  bool _detailsExpanded = false;
  final _fields = <String, TextEditingController>{};

  // Profile streams may resolve after the first build. Seed once, without
  // replacing a parent's edit (including an intentionally cleared field).
  final _profileEdits = <String>{};
  final _copies = <String, TextEditingController>{};
  final _overrides = <String, Map<String, String>>{'vi': {}, 'en': {}};
  final _crops = <({double x, double y, double zoom, String fit})>[];
  final _photos = <CardPhoto?>[];
  var _activeSlot = 0;
  late KeepsakeFormat _format = widget.cardDraft?.format == KeepsakeFormat.story
      ? KeepsakeFormat.story
      : KeepsakeFormat.portrait;
  Locale? _locale;
  var _reduced = false;
  var _busy = false;
  var _previewing = false;
  ({String? id})? _music;
  String? _requestId;
  KeepsakeTemplate get _t => widget.template;
  KeepsakePersonalization get _spec => _t.personalization!;
  bool get _video => _t.kind == KeepsakeKind.video;
  Occasion? get _occasion =>
      _t.occasions.length == 1 ? Occasion.fromWire(_t.occasions.first) : null;
  Map<String, String> get _values => {
    for (final e in _fields.entries) e.key: e.value.text.trim(),
  };
  Map<String, String> get _copy => resolveKeepsakeCopy(
    _spec,
    _values,
    _locale!,
    _overrides[_locale!.languageCode]!,
  );

  void _initialize(MemoryCtx c) {
    if (_locale != null) return;
    _reduced = MediaQuery.disableAnimationsOf(context);
    _locale = Locale(
      (widget.initialLocale ?? Localizations.localeOf(context).languageCode) ==
              'en'
          ? 'en'
          : 'vi',
    );
    for (final f in _spec.fields) {
      final value = switch (f.source) {
        'babyName' => c.nickname,
        'birthDate' =>
          c.dob == null ? '' : DateFormat('yyyy-MM-dd').format(c.dob!),
        // A first embrace's date is not inferred from today's date or a photo upload.
        _ => f.type == 'confirmation' ? 'false' : '',
      };
      _fields[f.key] = TextEditingController(text: value)
        ..addListener(() => _profileEdits.add(f.key));
    }
    for (var slot = 0; slot < _t.photosMax; slot++) {
      _photos.add(widget.cardDraft?.photoAt(slot));
    }
    _activeSlot = _photos.indexWhere((p) => p == null);
    if (_activeSlot < 0) _activeSlot = 0;
    for (final _ in _spec.beats) {
      _crops.add((x: 0, y: 0, zoom: 1, fit: 'contain'));
    }
    if (_video) _format = KeepsakeFormat.story;
  }

  void _fillProfile(MemoryCtx c) {
    for (final f in _spec.fields) {
      if (_profileEdits.contains(f.key)) continue;
      final value = switch (f.source) {
        'babyName' => c.baby?.nickname,
        'birthDate' =>
          c.dob == null ? null : DateFormat('yyyy-MM-dd').format(c.dob!),
        _ => null,
      };
      if (value == null) continue;
      if (_fields[f.key]!.text != value) {
        _fields[f.key]!.text = value;
        _requestId = null;
      }
      _profileEdits.add(f.key);
    }
  }

  void _changed() => setState(() {
    _requestId = null;
  });

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [..._fields.values, ..._copies.values]) {
      c.dispose();
    }
    super.dispose();
  }

  CardContent get _content => CardContent(
    occasion: '',
    name: _values['babyName'] ?? '',
    date: '',
    quote: '',
    photos: _photos,
    personalized: _copy,
  );

  bool get _fieldsValid {
    for (final f in _spec.fields) {
      final v = _values[f.key] ?? '';
      if (f.options.isNotEmpty &&
          (v.isNotEmpty || f.required) &&
          !f.options.any((o) => o.value == v)) {
        return false;
      }
      if (f.required && f.type == 'confirmation' && v != 'true') return false;
      if (f.type == 'month' &&
          v.isNotEmpty &&
          !RegExp(r'^(0?[1-9]|1[0-2])$').hasMatch(v)) {
        return false;
      }
      if ((f.required && v.isEmpty) ||
          v.length > f.max ||
          RegExp(r'[{}]').hasMatch(v)) {
        return false;
      }
    }
    if (_spec.dateRange case final range?) {
      final start = DateTime.tryParse(_values[range.start] ?? '');
      final end = DateTime.tryParse(_values[range.end] ?? '');
      if (start != null && end != null && end.isBefore(start)) return false;
    }
    return true;
  }

  bool get _valid {
    if (!_fieldsValid) return false;
    for (final c in _spec.copy) {
      final text = _copy[c.key] ?? '';
      if (text.length > c.max || RegExp(r'[{}]').hasMatch(text)) return false;
    }
    return true;
  }

  bool get _fits => _video
      ? (_t.composition != 'PremiumLittleThings' ||
                [
                  'favorite',
                  'detail',
                  'memory',
                ].every((key) => premiumVideoNoteFits(_copy[key] ?? ''))) &&
            _spec.beats.every(
              (b) => premiumVideoTextFits(_copy[b.textKey] ?? ''),
            ) &&
            premiumVideoMetadataFits(
              [
                _copy['signature'],
                _copy['detail0'],
              ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            ) &&
            premiumVideoMetadataFits(
              [
                _copy['detail1'],
                _copy['detail2'],
              ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            )
      : premiumCardFits(_t, _format, _content);

  Future<void> _pickField(KeepsakePersonalField f) async {
    final ctrl = _fields[f.key]!;
    if (f.type == 'date') {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(ctrl.text) ?? now,
        firstDate: DateTime(1900),
        lastDate: DateTime(now.year + 1, 12, 31),
      );
      if (date != null && mounted) {
        ctrl.text = DateFormat('yyyy-MM-dd').format(date);
        _changed();
      }
    } else {
      final old = ctrl.text.split(':');
      final time = await showTimePicker(
        context: context,
        initialTime: old.length == 2
            ? TimeOfDay(
                hour: int.tryParse(old[0]) ?? 0,
                minute: int.tryParse(old[1]) ?? 0,
              )
            : const TimeOfDay(hour: 12, minute: 0),
      );
      if (time != null && mounted) {
        ctrl.text =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        _changed();
      }
    }
  }

  void _putPhoto(int slot, CardPhoto photo) {
    setState(() {
      _photos[slot] = photo;
      final next = _photos.indexWhere((p) => p == null);
      _activeSlot = next < 0 ? slot : next;
    });
  }

  Future<void> _devicePhoto() async {
    final picked = await pickFromLibrary(context, ref);
    if (picked == null || !mounted) return;
    final available = [
      _activeSlot,
      for (var i = 0; i < _photos.length; i++)
        if (i != _activeSlot && _photos[i] == null) i,
    ];
    for (final (i, item)
        in picked
            .where((m) => m.type == MediaKind.photo)
            .take(available.length)
            .indexed) {
      _putPhoto(available[i], CardPhoto(FileImage(item.file)));
    }
  }

  Future<void> _memoryPhoto(List<MediaItem> media, int slot) async {
    setState(() => _activeSlot = slot);
    final picked = await showModalBottomSheet<MediaItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * 0.65,
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final m in media.where(
                (m) =>
                    m.isReady &&
                    !m.deleted &&
                    !m.isVideo &&
                    m.generatedKind == null,
              ))
                InkWell(
                  onTap: () => Navigator.of(sheet).pop(m),
                  child: Image(
                    image: StorageImage(m.thumbPath ?? m.displayPath!),
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      _putPhoto(
        slot,
        CardPhoto(
          StorageImage(picked.displayPath ?? picked.thumbPath!),
          takenAt: picked.captureAt,
        ),
      );
    }
  }

  Map<String, Object?> get _presentation => {
    'values': _values,
    'overrides': _overrides[_locale!.languageCode]!,
    'crops': [
      for (final c in _crops)
        {'x': c.x, 'y': c.y, 'zoom': c.zoom, 'fit': c.fit},
    ],
    'format': _format.name,
    'reducedMotion': _reduced,
  };

  ({String? id})? get _effectiveMusic =>
      _music ??
      (_t.composition == 'PremiumFirstCelebration' &&
              [
                'neutral',
                'tet',
                'christmas',
              ].contains(_values['celebrationTheme'])
          ? (id: 'music_p48_celebrate_${_values['celebrationTheme']}')
          : null);

  KeepsakeMusic? _track(KeepsakeCatalog? catalog) => catalog?.track(
    _effectiveMusic == null ? _t.defaultMusic : _effectiveMusic!.id,
  );

  Future<void> _previewVideo(Map<String, MediaItem> byId) async {
    final toaster = ClToaster.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _previewing = true);
    try {
      final photos = <String>[];
      for (final id in widget.mediaIds) {
        final path = byId[id]?.displayPath ?? byId[id]?.thumbPath;
        if (path == null) throw StateError('photo-unavailable');
        photos.add(
          'data:image/jpeg;base64,${base64Encode(await mediaBytes.read(path))}',
        );
      }
      final track = _track(ref.read(keepsakeCatalogProvider).value);
      final music = _music != null && _music!.id == null
          ? null
          : keepsakeMusicAsset(_t, track);
      final p = _t.palette;
      String hex(Color c) => '#${c.toARGB32().toRadixString(16).substring(2)}';
      final request = KeepsakePreviewRequest(
        composition: _t.composition!,
        props: {
          'photos': photos,
          'title': _copy['title'] ?? '',
          'message': '',
          'name': _values['babyName'] ?? '',
          'dateLine': '',
          'mark': null,
          'palette': {
            'background': hex(p.background),
            'ink': hex(p.ink),
            'accent': hex(p.accent),
          },
          'music': music == null ? null : keepsakeAssetUrl(music),
          'artAssets': {
            for (final e in _t.videoAssets.entries)
              e.key: keepsakeAssetUrl(e.value),
          },
          'durationSec': 35,
          'brand': _t.brand?.toJson(),
          'locale': _locale!.languageCode,
          'presentation': {
            ..._presentation,
            'copy': _copy,
            'beats': [
              for (final b in _spec.beats)
                {'slots': b.slots, 'textKey': b.textKey},
            ],
          },
        },
      );
      if (!mounted) return;
      await ref.read(keepsakePreviewLauncherProvider)(context, request);
    } on Object {
      toaster.show(message: l10n.p48PreviewFailed, error: true);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _previewCard() => showDialog<void>(
    context: context,
    builder: (dialog) => Dialog(
      child: SingleChildScrollView(
        child: PremiumCardMotion(
          reduced: _reduced,
          builder: (progress) => KeepsakeCardView(
            previewProgress: progress,
            reducedMotion: _reduced,
            template: _t,
            format: _format,
            content: _content,
            width: math.min(MediaQuery.sizeOf(context).width - 80, 420),
          ),
        ),
      ),
    ),
  );

  Future<void> _save(MemoryCtx c) async {
    if (!_valid || !_fits) return;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() {
      _busy = true;
      // Card export needs its actual artwork painted, including when saving from another section.
      if (!_video) _section = 2;
    });
    if (!_video && _scroll.hasClients) _scroll.jumpTo(0);
    try {
      if (_video) {
        _requestId ??= newKeepsakeRequestId();
        final job = await ref
            .read(keepsakeJobRepositoryProvider)
            .request(
              requestId: _requestId!,
              babyId: c.babyId,
              template: _t,
              mediaIds: widget.mediaIds,
              title: '',
              message: '',
              locale: _locale!.languageCode,
              presentation: _presentation,
              quality: videoExportQuality(ref, widget.babyId, _quality),
              audience: Audience.parents,
              occasion: _occasion,
              music: _effectiveMusic,
            );
        if (mounted) {
          unawaited(
            context.push('${Routes.memoryStoryJob}/$job?baby=${c.babyId}'),
          );
        }
        _requestId = null;
      } else {
        final assetOf = ref.read(keepsakeAssetImageProvider);
        if (_photos.any((p) => p == null)) return;
        await Future.wait([
          for (final photo in _photos) precacheImage(photo!.image, context),
          for (final a in _t.assets(_format))
            precacheImage(assetOf(a), context),
          precacheKeepsakeBrand(),
        ]);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final day =
            DateTime.tryParse(
              _values['birthDate'] ?? _values['momentDate'] ?? '',
            ) ??
            widget.cardDraft?.date ??
            c.now;
        final draft = CardDraft(
          babyId: c.babyId,
          occasion: _occasion ?? widget.cardDraft?.occasion ?? Occasion.birth,
          date: day,
          format: _format,
          template: _t,
          palette: _t.palette,
          quote: _copy['message'] ?? '',
          photos: List.of(_photos),
        );
        final result = await exportCard(_boundary, draft);
        final req = cardMemoryRequest(
          draft: draft,
          today: c.now,
          milestoneName: _copy['title'] ?? '',
        );
        req['milestone'] = null;
        (req['generated']! as Map<String, Object?>)['occasion'] =
            _occasion?.wire;
        await ref
            .read(uploadQueueProvider.notifier)
            .enqueue(
              babyId: c.babyId,
              request: req,
              picked: [
                PickedMedia(
                  file: result.jpg,
                  type: MediaKind.photo,
                  name: result.jpg.uri.pathSegments.last,
                  captureAt: day,
                  width: draft.exportWidth.round(),
                  height: (draft.exportWidth / _format.aspect).round(),
                ),
              ],
            );
        if (mounted) {
          context.pushReplacement(Routes.milestoneCardDone, extra: result);
        }
      }
    } on KeepsakeJobException catch (e) {
      if (e.reason == 'PREMIUM_REQUIRED') {
        ref.invalidate(familyPlanV2Provider(c.babyId));
        ref.invalidate(capabilitiesProvider(c.babyId));
      }
      toaster.show(
        message: e.reason == 'PREMIUM_REQUIRED'
            ? l10n.videoPremiumChanged
            : e.reason == 'rate-limit'
            ? l10n.videoRenderRateLimit
            : l10n.ksSaveFailed,
        error: true,
      );
    } on Object {
      toaster.show(message: l10n.ksSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(familyPlanV2Provider(widget.babyId));
    ref.watch(capabilitiesProvider(widget.babyId));
    final c = memoryCtx(context, ref);
    if (c == null) return const SizedBox.shrink();
    _initialize(c);
    _fillProfile(c);
    final l10n = AppLocalizations.of(context), cl = context.cl;
    final uiLocale = Localizations.localeOf(context);
    final media =
        ref.watch(completeMediaProvider((c.babyId, true))).value ??
        <MediaItem>[];
    final byId = {for (final m in media) m.id: m};
    final catalog = ref.watch(keepsakeCatalogProvider).value;
    final copy = _copy;
    final valid = _valid, fits = _fits;
    final ready = _video
        ? widget.mediaIds.length == _t.photosMax
        : _photos.whereType<CardPhoto>().length == _t.photosMax;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      appBar: AppBar(
        title: Text(_t.name.of(uiLocale), style: cl.text.bodyStrong),
        actions: [
          IconButton(
            tooltip: l10n.p48Settings,
            onPressed: _busy ? null : _showSettings,
            icon: const ClIcon(ClIcons.sliders),
          ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: cl.colors.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s2,
              ClSpace.s4,
              ClSpace.s3 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!ready || !valid || !fits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ClSpace.s2),
                    child: Semantics(
                      liveRegion: true,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _selectSection(
                                !ready
                                    ? 2
                                    : !_fieldsValid
                                    ? 0
                                    : 1,
                              ),
                        child: Text(
                          !ready
                              ? (_video
                                    ? l10n.ksVideoNeedMore(
                                        _t.photosMax - widget.mediaIds.length,
                                      )
                                    : l10n.ksCardMissingPhotos(
                                        _t.photosMax -
                                            _photos
                                                .whereType<CardPhoto>()
                                                .length,
                                      ))
                              : !valid
                              ? l10n.p48Invalid
                              : l10n.p48TooLong,
                          textAlign: TextAlign.center,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.mintText,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (MediaQuery.viewInsetsOf(context).bottom == 0)
                  ClButton(
                    label: l10n.ksPreview,
                    style: ClButtonStyle.plain,
                    expand: true,
                    loading: _previewing,
                    onPressed: _busy || _previewing || !ready || !valid || !fits
                        ? null
                        : () => _video ? _previewVideo(byId) : _previewCard(),
                  ),
                if (_video)
                  VideoQualitySelector(
                    babyId: widget.babyId,
                    selection: _quality,
                    enabled: !_busy,
                    onChanged: (value) => setState(() {
                      _quality = value;
                      _requestId = null;
                    }),
                  ),
                ClButton(
                  label: _video
                      ? videoExportLabel(ref, widget.babyId, _quality, l10n)
                      : l10n.ksSaveCard,
                  expand: true,
                  loading: _busy,
                  onPressed: _busy || !ready || !valid || !fits
                      ? null
                      : () => _save(c),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s4,
              vertical: ClSpace.s2,
            ),
            child: Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s1,
              children: [
                for (final (index, label) in [
                  l10n.p48InfoTab,
                  l10n.p48TextTab,
                  _video ? l10n.p48MediaTab : l10n.p48PhotosTab,
                ].indexed)
                  ChoiceChip(
                    key: ValueKey('p48-section-$index'),
                    label: Text(label),
                    selected: _section == index,
                    showCheckmark: false,
                    selectedColor: cl.colors.mintDeep,
                    labelStyle: cl.text.label.copyWith(
                      color: _section == index
                          ? cl.colors.onMintDeep
                          : cl.colors.ink,
                    ),
                    onSelected: _busy ? null : (_) => _selectSection(index),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(ClSpace.s4),
              children: [
                if (_section == 0) ...[
                  Text(l10n.p48Details, style: cl.text.bodyStrong),
                  const SizedBox(height: ClSpace.s4),
                  if (_spec.fields.any((f) => f.suggestion != null)) ...[
                    Text(l10n.p48SuggestionsHint, style: cl.text.label),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              for (final f in _spec.fields) {
                                if (f.suggestion != null &&
                                    _fields[f.key]!.text.trim().isEmpty) {
                                  _fields[f.key]!.text = f.suggestion!.of(
                                    _locale!,
                                  );
                                }
                              }
                              _changed();
                            },
                      child: Text(l10n.p48UseSuggestions),
                    ),
                  ],
                  for (final f in _spec.fields.where(
                    (f) => !_optionalDetail(f),
                  ))
                    _field(f),
                  if (_spec.fields.any(_optionalDetail))
                    ExpansionTile(
                      key: const ValueKey('p48-optional-details'),
                      initiallyExpanded: _detailsExpanded,
                      onExpansionChanged: (value) => _detailsExpanded = value,
                      trailing: const ClIcon(ClIcons.chevronDown),
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        l10n.p48MoreDetails,
                        style: cl.text.bodyStrong,
                      ),
                      subtitle: Text(
                        l10n.p48OptionalDetails,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      children: [
                        for (final f in _spec.fields.where(_optionalDetail))
                          _field(f),
                      ],
                    ),
                ],
                if (_section == 1) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _overrides[_locale!.languageCode]!.clear();
                              _requestId = null;
                            }),
                      child: Text(l10n.p48Reset),
                    ),
                  ),
                  for (final item in _spec.copy.where((x) => x.editable))
                    Builder(
                      builder: (context) {
                        final key = '${_locale!.languageCode}:${item.key}';
                        final ctrl = _copies.putIfAbsent(
                          key,
                          () => TextEditingController(),
                        );
                        if (ctrl.text != copy[item.key]) {
                          ctrl.text = copy[item.key] ?? '';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: ClSpace.s3),
                          child: AbsorbPointer(
                            absorbing: _busy,
                            child: ClTextField(
                              key: ValueKey(key),
                              label: item.label.of(uiLocale),
                              controller: ctrl,
                              maxLength: item.max,
                              maxLines: 3,
                              onChanged: (v) {
                                _overrides[_locale!.languageCode]![item.key] =
                                    v;
                                _changed();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
                if (_section == 2) ...[
                  if (!_video)
                    LayoutBuilder(
                      builder: (context, box) => Center(
                        child: RepaintBoundary(
                          key: _boundary,
                          child: KeepsakeCardView(
                            template: _t,
                            format: _format,
                            content: _content,
                            width: math.min(box.maxWidth, 420),
                            onPhotoTap: _busy
                                ? null
                                : (slot) => _memoryPhoto(media, slot),
                            onPhotoChanged: _busy
                                ? null
                                : (slot, p) =>
                                      setState(() => _photos[slot] = p),
                            activeSlot: !_busy && _t.photosMax > 1
                                ? _activeSlot
                                : null,
                            photoPlaceholder: Text(
                              l10n.ksChoosePhoto,
                              style: cl.text.label.copyWith(
                                color: _t.palette.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_video && _t.photosMax > 1)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var slot = 0; slot < _t.photosMax; slot++)
                          ChoiceChip(
                            key: ValueKey('premium-photo-$slot'),
                            label: Text(l10n.p48PhotoSlot(slot + 1)),
                            selected: slot == _activeSlot,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() => _activeSlot = slot),
                          ),
                      ],
                    ),
                  if (!_video)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _memoryPhoto(media, _activeSlot),
                          child: Text(l10n.ksFromMemories),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _devicePhoto,
                          child: Text(l10n.ksFromDevice),
                        ),
                      ],
                    ),
                  const SizedBox(height: ClSpace.s4),
                  if (_video) ...[
                    const SizedBox(height: ClSpace.s4),
                    Text(l10n.p48CropHint, style: cl.text.label),
                    for (final (i, beat) in _spec.beats.indexed)
                      _cropTile(i, beat.slots.first, byId),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: Text(l10n.p48ChangePhotos),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.ksVideoMusic),
                      subtitle: Text(
                        _music != null && _music!.id == null
                            ? l10n.ksMusicNone
                            : _track(catalog)?.title.of(uiLocale) ??
                                  l10n.ksMusicNone,
                      ),
                      trailing: const ClIcon(ClIcons.chevronRight),
                      onTap: _busy
                          ? null
                          : () async {
                              final picked = await showClSheet<({String? id})>(
                                context: context,
                                builder: (sheet) => KeepsakeMusicSheet(
                                  tracks: catalog?.music ?? [],
                                  selected: _effectiveMusic == null
                                      ? _t.defaultMusic
                                      : _effectiveMusic!.id,
                                  defaultId: _t.defaultMusic,
                                  onPick: (id) =>
                                      Navigator.of(sheet).pop((id: id)),
                                ),
                              );
                              if (picked != null && mounted) {
                                setState(() {
                                  _music = picked;
                                  _requestId = null;
                                });
                              }
                            },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Only known incidental metadata is collapsed. Required fields, choices and
  // confirmations always stay visible in Information for every template family.
  bool _optionalDetail(KeepsakePersonalField f) =>
      !f.required && const {'birthTime', 'placeName'}.contains(f.key);

  void _selectSection(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _section = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _field(KeepsakePersonalField f) {
    final uiLocale = Localizations.localeOf(context), cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: f.options.isNotEmpty
          ? DropdownButtonFormField<String>(
              key: ValueKey('p48-field-${f.key}'),
              isExpanded: true,
              initialValue: _fields[f.key]!.text.isEmpty
                  ? null
                  : _fields[f.key]!.text,
              decoration: InputDecoration(labelText: f.label.of(uiLocale)),
              items: [
                for (final o in f.options)
                  DropdownMenuItem(
                    value: o.value,
                    child: Text(o.label.of(uiLocale)),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      _fields[f.key]!.text = v ?? '';
                      _changed();
                    },
            )
          : f.type == 'month'
          ? DropdownButtonFormField<String>(
              initialValue: _fields[f.key]!.text.isEmpty
                  ? null
                  : _fields[f.key]!.text.padLeft(2, '0'),
              decoration: InputDecoration(labelText: f.label.of(uiLocale)),
              items: [
                for (var month = 1; month <= 12; month++)
                  DropdownMenuItem(
                    value: '$month'.padLeft(2, '0'),
                    child: Text('$month'.padLeft(2, '0')),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      _fields[f.key]!.text = value ?? '';
                      _changed();
                    },
            )
          : f.type == 'confirmation'
          ? CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(f.label.of(uiLocale)),
              value: _fields[f.key]!.text == 'true',
              onChanged: _busy
                  ? null
                  : (v) {
                      _fields[f.key]!.text = v == true ? 'true' : 'false';
                      _changed();
                    },
            )
          : f.type == 'text'
          ? AbsorbPointer(
              absorbing: _busy,
              child: ClTextField(
                key: ValueKey('p48-input-${f.key}'),
                label: f.label.of(uiLocale),
                controller: _fields[f.key],
                placeholder: f.suggestion?.of(_locale!),
                maxLength: f.max,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _changed(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  f.label.of(uiLocale),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: ClSpace.s1),
                TextField(
                  key: ValueKey('p48-input-${f.key}'),
                  controller: _fields[f.key],
                  readOnly: true,
                  onTap: _busy ? null : () => _pickField(f),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ClRadius.card),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(ClSpace.s3),
                      child: ClIcon(
                        f.type == 'time' ? ClIcons.clock : ClIcons.calendar,
                      ),
                    ),
                    suffixIcon: _fields[f.key]!.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: AppLocalizations.of(context).p48ClearValue,
                            icon: const ClIcon(ClIcons.close),
                            onPressed: _busy
                                ? null
                                : () {
                                    _fields[f.key]!.clear();
                                    _changed();
                                  },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showSettings() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    await showClSheet<void>(
      context: context,
      builder: (sheet) => MediaQuery(
        data: mediaQuery,
        child: StatefulBuilder(
          builder: (sheet, refresh) {
            void changed(VoidCallback update) {
              setState(update);
              refresh(() {});
            }

            return Material(
              color: context.cl.colors.surface,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClSheetHeader(title: l10n.p48Settings),
                    DropdownButtonFormField<String>(
                      initialValue: _locale!.languageCode,
                      isExpanded: true,
                      icon: const ClIcon(ClIcons.chevronDown),
                      decoration: InputDecoration(labelText: l10n.p48Language),
                      items: const [
                        DropdownMenuItem(
                          value: 'vi',
                          child: Text('Tiếng Việt'),
                        ),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => changed(() {
                              _locale = Locale(v!);
                              _requestId = null;
                            }),
                    ),
                    const SizedBox(height: ClSpace.s3),
                    DropdownButtonFormField<KeepsakeFormat>(
                      initialValue: _format,
                      icon: const ClIcon(ClIcons.chevronDown),
                      decoration: InputDecoration(labelText: l10n.p48Format),
                      items: const [
                        DropdownMenuItem(
                          value: KeepsakeFormat.portrait,
                          child: Text('4:5'),
                        ),
                        DropdownMenuItem(
                          value: KeepsakeFormat.story,
                          child: Text('9:16'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => changed(() {
                              _format = v!;
                              _requestId = null;
                            }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.p48ReducedMotion),
                      value: _reduced,
                      onChanged: _busy
                          ? null
                          : (v) => changed(() {
                              _reduced = v;
                              _requestId = null;
                            }),
                    ),

                    const SizedBox(height: ClSpace.s4),
                    ClButton(
                      label: l10n.actionDone,
                      expand: true,
                      onPressed: () => Navigator.of(sheet).pop(),
                    ),
                    const SizedBox(height: ClSpace.s4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cropTile(int beat, int slot, Map<String, MediaItem> byId) {
    final l10n = AppLocalizations.of(context);
    final crop = _crops[beat];
    final path = slot < widget.mediaIds.length
        ? (byId[widget.mediaIds[slot]]?.displayPath ??
              byId[widget.mediaIds[slot]]?.thumbPath)
        : null;
    void update({double? x, double? y, double? zoom, String? fit}) =>
        setState(() {
          _crops[beat] = (
            x: x ?? crop.x,
            y: y ?? crop.y,
            zoom: zoom ?? crop.zoom,
            fit: fit ?? crop.fit,
          );
          _requestId = null;
        });
    return ExpansionTile(
      key: ValueKey('premium-crop-$beat'),
      trailing: const ClIcon(ClIcons.chevronDown),
      tilePadding: EdgeInsets.zero,
      title: Text('${l10n.p48Crop} · ${beat + 1}'),
      children: [
        DropdownButton<String>(
          isExpanded: true,
          icon: const ClIcon(ClIcons.chevronDown),
          value: crop.fit,
          items: [
            DropdownMenuItem(value: 'contain', child: Text(l10n.p48WholePhoto)),
            DropdownMenuItem(value: 'cover', child: Text(l10n.p48FillFrame)),
          ],
          onChanged: _busy ? null : (v) => update(fit: v),
        ),
        if (path != null)
          SizedBox(
            width: 220,
            height:
                220 *
                (_format == KeepsakeFormat.story ? 1200 / 888 : 630 / 888),
            child: ClipRect(
              child: Transform.scale(
                scale: crop.zoom,
                child: Image(
                  image: StorageImage(path),
                  fit: crop.fit == 'contain' ? BoxFit.contain : BoxFit.cover,
                  alignment: Alignment(crop.x, crop.y),
                ),
              ),
            ),
          ),
        for (final entry in [
          (l10n.p48Horizontal, crop.x, -1.0, 1.0, (double v) => update(x: v)),
          (l10n.p48Vertical, crop.y, -1.0, 1.0, (double v) => update(y: v)),
          (l10n.p48Zoom, crop.zoom, 1.0, 2.0, (double v) => update(zoom: v)),
        ])
          Row(
            children: [
              SizedBox(width: 96, child: Text(entry.$1)),
              Expanded(
                child: Slider(
                  value: entry.$2,
                  min: entry.$3,
                  max: entry.$4,
                  onChanged: _busy ? null : entry.$5,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A 4-second preview of the real card; static exports always contain the settled complete card.
class PremiumCardMotion extends StatefulWidget {
  const PremiumCardMotion({
    required this.builder,
    this.reduced = false,
    super.key,
  });
  final Widget Function(double progress) builder;
  final bool reduced;
  @override
  State<PremiumCardMotion> createState() => _PremiumCardMotionState();
}

class _PremiumCardMotionState extends State<PremiumCardMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(_controller.value),
  );
}
