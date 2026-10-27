import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memories_screen.dart' show MemoryCtx, memoryCtx;
import '../memories/memory_models.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_repository.dart';
import 'print_models.dart';
import 'print_repository.dart';
import 'print_widgets.dart';
import 'print_product_details.dart';
import 'print_policy.dart';
import 'print_checkout.dart';
import 'print_address_editor.dart';
import 'print_ui.dart';
import 'print_book.dart';
import 'print_book_editor.dart';
import 'print_motion.dart';
import '../family/countries.dart' show countryName;

enum _Step {
  preview,
  edit,
  options,
  checkout,
  success,
  export,
  details,
  products,
  bookIntro,
}

class PrintStudioScreen extends ConsumerStatefulWidget {
  const PrintStudioScreen({
    this.product = 'trio',
    this.resume = false,
    this.photoId,
    this.detail = false,
    this.select = false,
    this.info = false,
    super.key,
  });
  final String product;
  final bool resume;
  final String? photoId;
  final bool detail, select, info;
  @override
  ConsumerState<PrintStudioScreen> createState() => _PrintStudioScreenState();
}

class _PrintStudioScreenState extends ConsumerState<PrintStudioScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.select) {
      _step = _Step.products;
    } else if (widget.detail && widget.product != 'book' && !widget.resume) {
      _step = _Step.details;
    } else if (widget.product == 'book' && !widget.resume) {
      _step = _Step.bookIntro;
    }
  }

  PrintDesign? _design;
  String? _babyId;
  _Step _step = _Step.preview;
  final _history = <_Step>[];
  int _page = 0, _quantity = 1;
  bool _busy = false,
      _approved = false,
      _dirty = false,
      _saveFailed = false,
      _saving = false,
      _leaving = false;
  Timer? _debounce;
  Future<void>? _saveInFlight;
  String _requestId = const Uuid().v4();
  final _funnelId = const Uuid().v4();
  final _signals = <String>{};
  Future<void> _signal(String event) async {
    if (!_signals.add(event) || _design == null) return;
    try {
      await printCall(ref, 'printStudioSignal', {
        'requestId': _funnelId,
        'event': event,
        'product': _design!.product,
      });
    } catch (_) {
      /* Best-effort aggregate funnel event; never blocks an order. */
    }
  }

  final _recipient = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController(),
      _country = TextEditingController(text: 'VN'),
      _giftMessage = TextEditingController();
  bool _gift = false;
  String _payment = 'cod';
  String? _successId;
  int _successTotal = 0;
  bool _addressSeeded = false;
  DateTime? _neededBy, _savedAt;
  String _format = 'pdf';
  bool _cropMarks = false;

  /// PR-1 (D-127 Q8): the print file job this design is building, or built.
  String? _exportJobId;
  bool _exportSeeded = false;

  /// PR-4: the last order attempt got no answer; the order may already exist.
  bool _orderMaybeSent = false;
  AppLocalizations get l => AppLocalizations.of(context);
  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_recipient, _phone, _address, _country, _giftMessage]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Step s) {
    if (s == _Step.options || s == _Step.edit) {
      unawaited(_signal('designStarted'));
    }
    setState(() {
      _history.add(_step);
      _step = s;
    });
  }

  void _change(Map<String, dynamic> v) {
    unawaited(_signal('designStarted'));
    setState(() {
      _design = _design!.copy(v);
      _dirty = true;
      _approved = false;
      _exportJobId = null;
      _requestId = const Uuid().v4();
    });
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 900),
      () => unawaited(_save()),
    );
  }

  Future<void> _save({bool force = false}) async {
    if (_saveInFlight != null) {
      await _saveInFlight;
      if (_dirty && mounted) return _save();
      return;
    }
    if ((!_dirty && !force) || _design == null || _babyId == null) return;
    final snapshot = _design!, baby = _babyId!;
    final done = Completer<void>();
    _saveInFlight = done.future;
    if (mounted) {
      setState(() {
        _saving = true;
        _saveFailed = false;
      });
    }
    try {
      await printCall(ref, 'printStudioSaveDraft', {
        'babyId': baby,
        'design': snapshot.toJson(),
      });
      if (mounted) {
        setState(() {
          if (identical(snapshot, _design)) _dirty = false;
          _savedAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
      _saveInFlight = null;
      done.complete();
    }
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_step == _Step.success) {
      context.go(Routes.memories);
      return;
    }
    if (_history.isNotEmpty) {
      setState(() => _step = _history.removeLast());
      return;
    }
    _debounce?.cancel();
    await _save();
    if (!mounted) return;
    if (_dirty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(l.psUnsaved),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.psKeep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.psLeave),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    setState(() => _leaving = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.memories);
    }
  }

  Future<void> _perform(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (e) {
      if (mounted) {
        final reason = e is FirebaseFunctionsException
            ? (e.details is Map ? (e.details as Map)['reason'] : e.message)
            : null;
        final message = switch (reason) {
          'low-resolution' => l.psLowQualityHelp,
          'photos-missing' || 'photo-unavailable' => l.psPhotosMissing,
          'price-changed' => l.psPriceChanged,
          'deadline-too-soon' => l.psTooSoon,
          'ordering-unavailable' => l.psUnavailable,
          'product-unavailable' => l.psProductNotOpen,
          _ => l.psError,
        };
        if (reason == 'price-changed') ref.invalidate(printCatalogProvider);
        showClToast(context, message: message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<MediaItem> _media() =>
      ref.read(completeMediaProvider((_babyId!, true))).value ?? const [];
  Future<void> _pick(int slot, {int? bookPage, int? position}) async {
    final media = _media()
        .where(
          (m) =>
              m.isReady &&
              !m.isVideo &&
              !m.deleted &&
              m.paths?.original != null,
        )
        .toList();
    String? selected;
    final id = await showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: PrintMotion.sheet(context),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cl.colors.surface,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(c).height * .64,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.psPickPhotoTitle('${_page + 1}'),
                          style: context.cl.text.title2.copyWith(
                            fontFamily: 'Be Vietnam Pro Keepsake',
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(c),
                        icon: const ClIcon(ClIcons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PrintPill(l.psSuggested, selected: true),
                  const SizedBox(height: 10),
                  Text(l.psPickPhotoHelp, style: context.cl.text.caption),
                  const SizedBox(height: 10),
                  if (media.isEmpty)
                    Expanded(child: Center(child: Text(l.psNoPhotos)))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                            ),
                        itemCount: media.length,
                        itemBuilder: (c, i) => Semantics(
                          label: '${l.psChoose} ${i + 1}',
                          button: true,
                          selected: selected == media[i].id,
                          child: InkWell(
                            onTap: () => set(() => selected = media[i].id),
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: selected == media[i].id
                                    ? Border.all(
                                        color: context.cl.colors.mintDeep,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image(
                                  image: StorageImage(media[i].displayPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: ClIcon(ClIcons.alert),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ClButton(
                    label: l.psUsePhoto,
                    expand: true,
                    onPressed: selected == null
                        ? null
                        : () => Navigator.pop(c, selected),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (id == null || !mounted) return;
    if (bookPage != null) {
      final d = _design!, registry = [...d.mediaIds];
      var index = registry.indexOf(id);
      if (index < 0) {
        if (registry.length >= 40) {
          showClToast(context, message: l.psError);
          return;
        }
        index = registry.length;
        registry.add(id);
      }
      final pages = List.generate(d.pages, (i) => [...d.slots(i)]),
          p = pages[bookPage];
      if (position != null && position < p.length) {
        p[position] = index;
      } else if (p.contains(slot)) {
        p[p.indexOf(slot)] = index;
      } else if (p.length < 4) {
        p.add(index);
      }
      _change({'mediaIds': registry, 'pagePhotos': pages});
      return;
    }
    final ids = [..._design!.mediaIds];
    while (ids.length <= slot) {
      ids.add('');
    }
    ids[slot] = id;
    _change({'mediaIds': ids});
  }

  Future<void> _pickDate({bool delivery = false}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: delivery
          ? (_neededBy ?? today.add(const Duration(days: 14)))
          : DateTime.tryParse(_design!.date) ?? today,
      firstDate: delivery ? today : DateTime(1900),
      lastDate: DateTime(today.year + 10),
    );
    if (date != null && mounted) {
      if (delivery) {
        setState(() => _neededBy = date);
      } else {
        _change({'date': DateFormat('yyyy-MM-dd').format(date)});
      }
    }
  }

  Future<void> _download() async {
    if (!_design!.ready) {
      showClToast(context, message: l.psPhotosMissing);
      return;
    }
    bool accept = false;
    if (_design!.lowQuality(_media())) {
      accept =
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(l.psLowQuality),
              content: Text(l.psLowQualityHelp),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l.psPhotoChange),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(l.psAcceptQuality),
                ),
              ],
            ),
          ) ??
          false;
      if (!accept || !mounted) return;
    }
    // PR-1: the server builds the file as a job; this returns at once and the parent may leave.
    await _perform(() async {
      final result = await printCall(ref, 'printStudioExportStart', {
        'babyId': _babyId,
        'requestId': const Uuid().v4(),
        'design': _design!.toJson(),
        'format': _format,
        'cropMarks': _cropMarks,
        'acknowledgeQuality': accept,
      });
      if (mounted) setState(() => _exportJobId = result['jobId'] as String);
    });
  }

  /// The job being followed, live; null without one or once its file expired.
  PrintExportJob? _watchJob() {
    final id = _exportJobId, baby = _babyId;
    if (id == null || baby == null) return null;
    return PrintExportJob.fromMap(
      id,
      ref.watch(printExportJobProvider((baby, id))).value,
      DateTime.now(),
    );
  }

  /// A fresh link each time (files are kept 24 hours).
  Future<void> _openExport(PrintExportJob job) => _perform(() async {
    final r = await printCall(ref, 'printStudioExportUrl', {
      'babyId': _babyId,
      'jobId': job.id,
    });
    if (!await launchUrl(
      Uri.parse(r['url'] as String),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('open-failed');
    }
  });

  String _exportError(String? reason) => switch (reason) {
    'low-resolution' => l.psLowQualityHelp,
    'photos-missing' || 'photo-unavailable' => l.psPhotosMissing,
    'export-paused' => l.psUnavailable,
    _ => l.psExportFailed,
  };

  /// PR-4: no answer is not "Kiểm tra kết nối": the order may already be recorded.
  static bool _noAnswer(Object e) =>
      e is TimeoutException ||
      (e is FirebaseFunctionsException &&
          (e.code == 'deadline-exceeded' || e.code == 'unavailable'));

  Future<void> _order(PrintCatalog catalog) async {
    if (!_approved) return;
    setState(() => _orderMaybeSent = false);
    await _perform(() async {
      // The request id survives a timeout/retry. A changed design creates a new intent.
      final Map<String, dynamic> result;
      try {
        result = await printCall(ref, 'printStudioOrder', {
          'babyId': _babyId,
          'requestId': _requestId,
          'catalogVersion': catalog.version,
          'design': _design!.toJson(),
          'quantity': _quantity,
          'approved': true,
          'paymentMethod': _payment,
          'address': {
            'recipient': _recipient.text.trim(),
            'phone': _phone.text.replaceAll(RegExp(r'[\s()-]'), ''),
            'address': _address.text.trim(),
            'country': _country.text.trim().toUpperCase(),
            'neededBy': _neededBy == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_neededBy!),
            'gift': _gift,
            'giftMessage': _giftMessage.text.trim(),
          },
        });
      } on Object catch (e) {
        if (!_noAnswer(e)) rethrow;
        if (mounted) setState(() => _orderMaybeSent = true);
        return;
      }
      if (mounted) {
        _dirty = false;
        _leaving = true;
        setState(() {
          _leaving = false;
          _successId = result['id'] as String;
          // PR-5: the server's total; the local estimate only for an older server.
          _successTotal =
              (result['total'] as num?)?.toInt() ??
              catalog.totals(_design!, _quantity, giftWrap: _gift).total;
          _history.clear();
          _step = _Step.success;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = _buildScreen(context);
    return PopScope(
      canPop: _leaving || _design == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: PrintFlowTransition(
        identity: (
          _step,
          _step == _Step.export && _watchJob()?.state == PrintExportState.ready,
        ),
        child: screen,
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final ctx = memoryCtx(context, ref), cl = context.cl;
    if (ctx == null || !ctx.parentView) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: Center(child: Text(l.psForParents)),
      );
    }
    // A child switch cannot reuse another child's design or shipping request.
    if (_babyId != null && _babyId != ctx.babyId) {
      return Scaffold(
        body: Center(
          child: ClButton(
            label: l.psReturn,
            onPressed: () => context.go(Routes.memories),
          ),
        ),
      );
    }
    final mediaAsync = ref.watch(completeMediaProvider((ctx.babyId, true)));
    final catalogAsync = ref.watch(printCatalogProvider);
    final draftAsync = widget.resume
        ? ref.watch(printDraftProvider(ctx.babyId))
        : null;
    if (mediaAsync.isLoading ||
        catalogAsync.isLoading ||
        (widget.resume && draftAsync!.isLoading)) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (mediaAsync.hasError ||
        catalogAsync.hasError ||
        (draftAsync?.hasError ?? false)) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: ClEmptyState(
          icon: ClIcons.cloudOff,
          title: l.psError,
          message: l.psIntro,
          actionLabel: l.psRetry,
          onAction: () {
            ref.invalidate(completeMediaProvider((ctx.babyId, true)));
            ref.invalidate(printCatalogProvider);
            ref.invalidate(printDraftProvider(ctx.babyId));
          },
        ),
      );
    }
    final media = mediaAsync.value ?? [], catalog = catalogAsync.requireValue;
    // PR-1: a resumed draft shows the print file it was building or built.
    final remembered = ref.watch(printDraftExportJobProvider(ctx.babyId));
    if (!_exportSeeded && remembered.hasValue) {
      _exportSeeded = true;
      if (widget.resume) _exportJobId ??= remembered.value;
    }
    if (_design == null) {
      _babyId = ctx.babyId;
      _design = widget.resume ? draftAsync!.value : null;
      _design ??= newPrintDesign(
        ctx,
        media,
        widget.product,
        l,
        photoId: widget.photoId,
      );
    }
    if (widget.info &&
        _design!.product == 'single' &&
        _design!.pageLayouts.isEmpty) {
      _design = _design!.copy({
        'pageLayouts': ['text'],
        'pagePhotos': [<int>[]],
      });
    }
    if (!_signals.contains('viewed')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_signal('viewed'));
      });
    }
    if (_step == _Step.checkout && !_addressSeeded) {
      final orders = ref.watch(printOrdersProvider(ctx.babyId));
      if (orders.hasValue) {
        _addressSeeded = true;
        if (_recipient.text.isEmpty && orders.requireValue.isNotEmpty) {
          final address = orders.requireValue.first['address'];
          if (address is Map) {
            _recipient.text = address['recipient'] as String? ?? '';
            _phone.text = address['phone'] as String? ?? '';
            _address.text = address['address'] as String? ?? '';
          }
        }
      }
    }
    final d = _design!;
    final job = _watchJob();
    if (_step == _Step.export && job?.state != PrintExportState.ready) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                child: PrintScene(design: d, media: media),
              ),
            ),
            Positioned.fill(child: ColoredBox(color: cl.colors.scrim)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: cl.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * .68,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cl.colors.separator,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.psExportTitle,
                                  style: cl.text.title2.copyWith(
                                    fontFamily: 'Be Vietnam Pro Keepsake',
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _busy ? null : _back,
                                icon: const ClIcon(ClIcons.close),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView(children: _body(d, media, catalog)),
                          ),
                          const SizedBox(height: 10),
                          // While the job builds the parent may close; the CTA waits.
                          ClButton(
                            label: job?.state == PrintExportState.failed
                                ? l.psRetry
                                : l.psDownload,
                            expand: true,
                            onPressed:
                                _busy ||
                                    !catalog.digital ||
                                    !d.ready ||
                                    job?.state == PrintExportState.working
                                ? null
                                : _download,
                            loading: _busy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_step == _Step.success) {
      return Scaffold(
        backgroundColor: cl.colors.cloud,
        body: SafeArea(
          child: PrintOrderSuccess(
            id: _successId!,
            name: d.name,
            total: _successTotal,
            payment: _payment,
            days: catalog.leadDays,
            onView: () => context.pushReplacement(
              '${Routes.printStudioOrders}/$_successId?baby=$_babyId',
            ),
            onMemories: () => context.go(Routes.memories),
          ),
        ),
      );
    }
    final title = switch (_step) {
      _Step.preview => printProductName(l, d.product),
      _Step.details => l.psDetails,
      _Step.products => l.psSetTitle(d.title, d.name),
      _Step.bookIntro => l.psBookTitle(d.title, d.name),
      _Step.edit => l.psCustomize,
      _Step.options => d.isBook ? l.psBookOptions : l.psOptions,
      _Step.checkout => l.psCheckout,
      _Step.success => l.psOrderSuccess,
      _Step.export =>
        job?.state == PrintExportState.ready
            ? l.psExportReady
            : l.psExportTitle,
    };
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_step != _Step.details)
              PrintHeader(
                onBack: _busy ? null : _back,
                title: _step == _Step.checkout ? l.psCheckout : null,
                action: _step == _Step.edit
                    ? l.psDone
                    : _step == _Step.preview
                    ? (d.isBook
                          ? (_saving
                                ? l.psSaving
                                : _savedAt == null
                                ? l.psAutoSave
                                : l.psAutoSavedAt(
                                    DateFormat('HH:mm').format(_savedAt!),
                                  ))
                          : _saving
                          ? l.psSaving
                          : l.psSave)
                    : null,
                mutedAction: _step == _Step.preview && d.isBook,
                onAction: _busy
                    ? null
                    : () async {
                        if (_step == _Step.edit) {
                          if (d.name.trim().isEmpty) {
                            showClToast(context, message: l.psNameRequired);
                            return;
                          }
                          setState(() => _step = _history.removeLast());
                        } else {
                          await _save(force: true);
                          if (context.mounted && !_saveFailed) {
                            showClToast(context, message: l.psSaved);
                          }
                        }
                      },
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (!{
                    _Step.preview,
                    _Step.details,
                    _Step.bookIntro,
                    _Step.checkout,
                  }.contains(_step)) ...[
                    Text(
                      title,
                      style: psText(
                        context,
                        24,
                        weight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_saveFailed) PrintNotice(l.psSaveFailed, warning: true),
                  // PR-1: the print file keeps building after the parent left.
                  if (_step == _Step.preview &&
                      job != null &&
                      job.state != PrintExportState.failed)
                    _gap(
                      PrintCard(
                        lifted: false,
                        onTap: () => _go(_Step.export),
                        child: Text(
                          job.state == PrintExportState.ready
                              ? l.psExportBannerReady
                              : l.psExportProgress(job.done, job.total),
                          style: psText(context, 14, weight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ..._body(d, media, catalog),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _step == _Step.edit ? null : _bottom(d, catalog),
    );
  }

  Widget _field(
    String key,
    String label,
    String value,
    int max,
    ValueChanged<String> change, {
    int lines = 1,
    String? hint,
  }) => _gap(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: psText(
            context,
            13,
            weight: FontWeight.w600,
            color: context.cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('$key:$_page'),
          initialValue: value,
          maxLength: max,
          maxLines: lines,
          style: context.cl.text.body.copyWith(
            fontFamily: 'Be Vietnam Pro Keepsake',
            height: 1.3,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: context.cl.colors.surface,
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.cl.colors.inkMuted.withValues(alpha: .6),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: change,
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: psText(context, 12, color: context.cl.colors.inkMuted),
          ),
        ],
      ],
    ),
  );
  Widget _gap(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  Widget _heading(String text) => _gap(PrintSectionLabel(text));
  Widget _flat(
    PrintDesign d,
    List<MediaItem> media,
    int page, {
    bool safe = false,
  }) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 320),
      child: PrintArtwork(
        design: d,
        media: media,
        page: page,
        safeArea: safe,
        onPhotoTap: (position) => _pick(d.slots(_page)[position]),
      ),
    ),
  );
  List<Widget> _body(PrintDesign d, List<MediaItem> media, PrintCatalog c) {
    final price = c.price(d);
    switch (_step) {
      case _Step.details:
        return [
          PrintProductDetails(
            design: d,
            media: media,
            price: price,
            initialPage: 0,
            onBack: _back,
            onCustomize: () => _go(d.isBook ? _Step.bookIntro : _Step.preview),
            onChoose: () => _go(_Step.products),
            onPolicy: () => _policy(c),
          ),
        ];
      case _Step.products:
        return [
          _gap(Text(l.psSelectionHelp, style: context.cl.text.caption)),
          for (final product in ['trio', 'single', 'five'])
            _gap(
              PrintCard(
                selected: d.product == product,
                padding: const EdgeInsets.all(12),
                onTap: () => _change({'product': product}),
                child: Column(
                  children: [
                    PrintScene(
                      design: d.copy({'product': product}),
                      media: media,
                      height: 164,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _radio(d.product == product),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            printProductName(l, product),
                            style: context.cl.text.bodyStrong,
                          ),
                        ),
                        if (c.price(d.copy({'product': product}))
                            case final value?)
                          Text(
                            printMoney(context, value),
                            style: context.cl.text.label.copyWith(
                              fontFamily: 'Be Vietnam Pro Keepsake',
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ];
      case _Step.bookIntro:
        return [
          _gap(
            PrintScene(design: d, media: media, height: 288, decorated: false),
          ),
          _gap(
            Text(
              l.psBookTitle(d.title, d.name),
              style: context.cl.text.title.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _gap(
            Text(
              l.psBookHelp,
              style: context.cl.text.body.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.3,
                fontSize: 15,
              ),
            ),
          ),
          _gap(
            Wrap(
              spacing: 8,
              children: [
                PrintPill(l.psBookPagesCount(d.pages)),
                PrintPill('${d.mediaIds.toSet().length} ${l.memPhotos}'),
              ],
            ),
          ),
          _gap(PrintNotice(l.psBookSourceNote)),
        ];
      case _Step.preview:
        if (d.isBook) {
          final ctx = memoryCtx(context, ref)!;
          final favorites =
              ref.watch(favoritesProvider((ctx.babyId, ctx.me.uid))).value ??
              <String>{};
          return [
            PrintBookViewer(
              design: d,
              media: media,
              dob: ctx.dob,
              favorites: favorites,
              onChanged: _change,
              onEdit: (p) => _editBookPage(p),
              onPhoto: (p, position) =>
                  _pick(d.slots(p)[position], bookPage: p, position: position),
            ),
          ];
        }
        return [
          _gap(
            PrintFlowTransition(
              identity: d.style,
              child: PrintScene(design: d, media: media),
            ),
          ),
          _gap(
            Text(
              l.psMadeFor(d.title, d.name),
              style: context.cl.text.label.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 16 / 13,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.cl.colors.mintText,
              ),
            ),
          ),
          _heading(l.psStyle),
          _gap(_styleChoices(d, media)),
          _heading(l.psInSet),
          _gap(
            PrintCard(
              lifted: false,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (var p = 0; p < d.count; p++)
                    InkWell(
                      onTap: () {
                        setState(() => _page = p);
                        _go(_Step.edit);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 50,
                              child: PrintArtwork(
                                design: d,
                                media: media,
                                page: p,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l.psFrameNumber('${p + 1}')} · ${p == 1
                                        ? l.psInfo
                                        : p == 2
                                        ? l.psCollage
                                        : l.psPortrait}',
                                    style: context.cl.text.label.copyWith(
                                      fontFamily: 'Be Vietnam Pro Keepsake',
                                      height: 1.3,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p == 1
                                        ? l.psInfoHelp
                                        : p == 2
                                        ? l.psCollageHelp
                                        : l.psPortraitHelp,
                                    style: context.cl.text.caption.copyWith(
                                      fontFamily: 'Be Vietnam Pro Keepsake',
                                      height: 1.3,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              l.psEdit,
                              style: context.cl.text.label.copyWith(
                                fontFamily: 'Be Vietnam Pro Keepsake',
                                height: 1.3,
                                fontSize: 13,
                                color: context.cl.colors.mintText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!d.ready) _gap(PrintNotice(l.psPhotosMissing, warning: true)),
        ];
      case _Step.edit:
        return [
          if (!d.isBook && d.count > 1)
            _gap(
              PrintSegments<int>(
                values: List.generate(d.count, (i) => i),
                value: _page,
                label: (i) => l.psFrameNumber('${i + 1}'),
                onChanged: (i) => setState(() => _page = i),
              ),
            ),
          _gap(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.cl.colors.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: 264,
                child: _flat(d, media, _page, safe: true),
              ),
            ),
          ),
          _gap(
            Center(
              child: Text(
                l.psSafeArea,
                style: context.cl.text.caption.copyWith(
                  fontFamily: 'Be Vietnam Pro Keepsake',
                  height: 1.3,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _field('name', l.psName, d.name, 40, (v) => _change({'name': v})),
          if (d.isBook)
            _field(
              'page',
              l.psPrintTitle,
              _page < d.pageTitles.length ? d.pageTitles[_page] : '',
              80,
              (v) {
                final titles = [...d.pageTitles];
                while (titles.length <= _page) {
                  titles.add('');
                }
                titles[_page] = v;
                _change({'pageTitles': titles});
              },
              lines: 2,
            ),
          if (!d.isBook && d.layoutPage(_page) == 1) ...[
            _field(
              'message',
              l.psMessage,
              d.message,
              120,
              (v) => _change({'message': v}),
              hint: l.psFrameMessageHint,
            ),
            _gap(
              PrintCard(
                lifted: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.psShowBirth,
                            style: psText(context, 15, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.psBirthHelp,
                            style: psText(
                              context,
                              12,
                              color: context.cl.colors.inkMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PrintToggle(
                      value: d.showBirthDetails,
                      onChanged: (v) => _change({'showBirthDetails': v}),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.psOccasion, style: context.cl.text.label),
            trailing: const ClIcon(ClIcons.chevronDown, size: 18),
            children: [
              if (d.layoutPage(_page) == 1)
                _field(
                  'birth',
                  l.psBirthDetails,
                  d.birthDetails,
                  100,
                  (v) => _change({'birthDetails': v}),
                  lines: 2,
                ),
              Wrap(
                spacing: 6,
                children: [
                  for (final occasion in [
                    'month',
                    'hundred',
                    'birthday',
                    'custom',
                  ])
                    ChoiceChip(
                      label: Text(_occasionName(occasion)),
                      selected: d.occasion == occasion,
                      onSelected: (_) => _change({
                        'occasion': occasion,
                        'title': _occasionName(occasion),
                        'date': DateFormat('yyyy-MM-dd').format(
                          _occasionDate(memoryCtx(context, ref)!, occasion),
                        ),
                      }),
                    ),
                ],
              ),
              _field(
                'title',
                l.psPrintTitle,
                d.title,
                120,
                (v) => _change({'title': v}),
                lines: 2,
              ),
              _gap(
                ClButton(
                  label: '${l.psDate}: ${d.date}',
                  style: ClButtonStyle.secondary,
                  onPressed: () => _pickDate(),
                ),
              ),
            ],
          ),
        ];
      case _Step.options:
        return [
          _heading(d.isBook ? l.psSize : l.psSetSize),
          _gap(
            PrintCard(
              lifted: false,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final size
                      in d.isBook
                          ? ['20x20:24', '20x20:40', '15x15:24']
                          : ['10x15', '13x18', '15x21'])
                    _sizeOption(d, c, size),
                ],
              ),
            ),
          ),
          _heading(d.isBook ? l.psBookStyle : l.psFrameLabel),
          if (d.isBook)
            _gap(_styleChoices(d, media))
          else
            _gap(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final frame in ['white', 'wood', 'gift'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: frame == 'gift' ? 0 : 8,
                        ),
                        child: PrintCard(
                          selected: d.frame == frame,
                          lifted: false,
                          outlined: true,
                          padding: const EdgeInsets.all(8),
                          radius: 16,
                          onTap: () => _change({'frame': frame}),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 72,
                                child: PrintFrame(
                                  design: d.copy({'frame': frame}),
                                  media: media,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                frame == 'white'
                                    ? l.psWhite
                                    : frame == 'wood'
                                    ? l.psWood
                                    : l.psGift,
                                textAlign: TextAlign.center,
                                style: context.cl.text.caption.copyWith(
                                  fontFamily: 'Be Vietnam Pro Keepsake',
                                  height: 1.3,
                                  fontSize: 11,
                                  color: context.cl.colors.ink,
                                  fontWeight: d.frame == frame
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              if (frame == 'gift')
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    '+${printMoney(context, (c.json['giftSurcharge'] as num).toInt())}',
                                    style: context.cl.text.caption.copyWith(
                                      fontFamily: 'Be Vietnam Pro Keepsake',
                                      height: 1.3,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (!d.isBook)
            _gap(
              PrintCard(
                lifted: false,
                child: Row(
                  children: [
                    const ClIcon(ClIcons.check, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.psAcrylicTitle,
                            style: context.cl.text.label.copyWith(
                              fontFamily: 'Be Vietnam Pro Keepsake',
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(l.psAcrylicHelp, style: context.cl.text.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _gap(
            PrintNotice(
              l.psFrameDelivery(
                DateFormat(
                  'dd/MM',
                ).format(DateTime.now().add(Duration(days: c.leadDays))),
                DateFormat(
                  'dd/MM',
                ).format(DateTime.now().add(Duration(days: c.leadDays + 2))),
              ),
            ),
          ),
          if (d.lowQuality(media))
            _gap(PrintNotice(l.psLowQualityHelp, warning: true)),
          if (!c.canOrder(d))
            _gap(
              PrintNotice(c.physical ? l.psProductNotOpen : l.psUnavailable),
            ),
        ];
      case _Step.checkout:
        final country = _country.text.trim().toUpperCase();
        return [
          if (_orderMaybeSent)
            _gap(PrintNotice(l.psOrderMaybeSent, warning: true)),
          if (_orderMaybeSent)
            _gap(
              ClButton(
                label: l.psViewOrders,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () =>
                    context.push('${Routes.printStudioOrders}?baby=$_babyId'),
              ),
            ),
          if (country.isNotEmpty && !c.countries.contains(country)) ...[
            _gap(
              PrintNotice(
                c.digital
                    ? l.psCountryUnsupportedDigital(_countryLabel(country))
                    : l.psCountryUnsupported(_countryLabel(country)),
                warning: true,
              ),
            ),
            if (c.digital)
              _gap(
                ClButton(
                  label: l.psDownloadShort,
                  style: ClButtonStyle.secondary,
                  expand: true,
                  onPressed: () => _go(_Step.export),
                ),
              ),
          ],
          PrintCheckout(
            design: d,
            media: media,
            catalog: c,
            quantity: _quantity,
            approved: _approved,
            address: _shippingAddress(),
            gift: _gift,
            giftController: _giftMessage,
            onGiftMessage: (v) => _requestId = const Uuid().v4(),
            payment: _payment,
            busy: _busy,
            onQuantity: (q) => setState(() {
              _quantity = q;
              _requestId = const Uuid().v4();
            }),
            onApproved: (v) => setState(() => _approved = v),
            onGift: (v) => setState(() {
              _gift = v;
              _requestId = const Uuid().v4();
            }),
            onPayment: (v) => setState(() {
              _payment = v;
              _requestId = const Uuid().v4();
            }),
            onAddress: () => _editAddress(c),
            onProof: () => _go(_Step.preview),
            onPolicy: () => _policy(c),
          ),
        ];
      case _Step.success:
        return [];
      case _Step.export:
        final job = _watchJob();
        if (job?.state == PrintExportState.ready) {
          return [
            _gap(PrintNotice(l.psExportReadyHelp)),
            _gap(
              PrintCard(
                child: Column(
                  children: [
                    const ClIcon(ClIcons.check, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      l.psExportFiles(
                        job!.pages ?? job.total,
                        (job.format ?? 'pdf').toUpperCase(),
                      ),
                      style: context.cl.text.bodyStrong,
                    ),
                  ],
                ),
              ),
            ),
            _gap(
              ClButton(
                label: l.psOpenFile,
                loading: _busy,
                onPressed: _busy ? null : () => _openExport(job),
              ),
            ),
          ];
        }
        final working = job?.state == PrintExportState.working;
        return [
          if (working)
            _gap(PrintExportProgress(done: job!.done, total: job.total))
          else if (job?.state == PrintExportState.failed)
            _gap(PrintNotice(_exportError(job!.error), warning: true)),
          _heading(l.psFormat),
          for (final f in ['pdf', 'jpg', 'png'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: InkWell(
                onTap: _busy ? null : () => setState(() => _format = f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _radio(_format == f),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f == 'pdf'
                              ? l.psPdf
                              : f == 'jpg'
                              ? l.psJpg
                              : l.psPng,
                          style: context.cl.text.label.copyWith(
                            fontFamily: 'Be Vietnam Pro Keepsake',
                            height: 1.3,
                            fontSize: 15,
                            fontWeight: _format == f
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _heading(l.psSize),
          _gap(
            PrintSegments<String>(
              values: d.isBook
                  ? const ['15x15', '20x20']
                  : const ['10x15', '13x18', '15x21'],
              value: d.size,
              label: (size) => size.replaceAll('x', ' × '),
              onChanged: _busy
                  ? (_) {}
                  : (size) => _change({
                      'size': size,
                      if (d.isBook && size == '15x15') 'pages': 24,
                    }),
            ),
          ),
          _gap(
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(l.psCropMarks, style: context.cl.text.label),
                value: _cropMarks,
                onChanged: _busy ? null : (v) => setState(() => _cropMarks = v),
              ),
            ),
          ),
          _gap(
            Text(
              l.psExportHelp,
              style: context.cl.text.caption.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.3,
                fontSize: 12,
              ),
            ),
          ),
          if (!d.ready) _gap(PrintNotice(l.psPhotosMissing, warning: true)),
        ];
    }
  }

  Widget _radio(bool selected) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? context.cl.colors.mintDeep : Colors.transparent,
      border: Border.all(
        color: selected
            ? context.cl.colors.mintDeep
            : context.cl.colors.controlBorder,
        width: 1.4,
      ),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: context.cl.colors.onMintDeep,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );

  Widget _sizeOption(PrintDesign d, PrintCatalog c, String value) {
    final parts = value.split(':'), size = parts.first;
    final pages = parts.length > 1 ? int.parse(parts[1]) : d.pages;
    final price = c.price(d.copy({'size': size, 'pages': pages}));
    if (price == null) return const SizedBox.shrink();
    final selected = d.size == size && (!d.isBook || d.pages == pages);
    final subtitle = d.isBook
        ? l.psBookPagesCount(pages)
        : size == '10x15'
        ? l.psFrameSizeHelpSmall
        : size == '13x18'
        ? l.psFrameSizeHelpMedium
        : l.psFrameSizeHelpLarge;
    return InkWell(
      onTap: () => _change({'size': size, 'pages': pages}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _radio(selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${size.replaceAll('x', ' × ')} cm${d.isBook
                        ? ' · $pages'
                        : size == '13x18'
                        ? ' · ${l.psRecommended}'
                        : ''}',
                    style: context.cl.text.label.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.3,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.cl.text.caption.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              printMoney(context, price),
              style: context.cl.text.label.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.3,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styleChoices(PrintDesign d, List<MediaItem> media) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final style in ['minimal', 'playful', 'timeless'])
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: style == 'timeless' ? 0 : 8),
            child: PrintCard(
              selected: d.style == style,
              lifted: false,
              outlined: true,
              radius: 16,
              padding: const EdgeInsets.all(8),
              onTap: () => _change({'style': style}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 78,
                    child: Center(
                      child: PrintArtwork(
                        design: d.copy({'style': style}),
                        media: media,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    printStyleName(l, style),
                    style: context.cl.text.caption.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.25,
                      fontSize: 12,
                      fontWeight: d.style == style
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: context.cl.colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _bottom(PrintDesign d, PrintCatalog c) {
    final (label, action) = switch (_step) {
      _Step.details => (
        l.psDetailsPreview(d.name),
        () => _go(d.isBook ? _Step.bookIntro : _Step.preview),
      ),
      _Step.products => (l.psPreview, () => _go(_Step.preview)),
      _Step.bookIntro => (l.psPreview, () => _go(_Step.preview)),
      _Step.preview => (
        d.isBook ? l.psOrder : l.psNext,
        () => _go(_Step.options),
      ),
      _Step.edit => (
        l.psDone,
        () {
          if (d.name.trim().isEmpty) {
            showClToast(context, message: l.psNameRequired);
            return;
          }
          setState(() => _step = _history.removeLast());
        },
      ),
      _Step.options => (
        !d.ready
            ? l.psChoose
            : c.canOrder(d) && d.lowQuality(_media())
            ? l.psPhotoChange
            : c.canOrder(d)
            ? l.psOrder
            : l.psOrder,
        !d.ready
            ? () {
                setState(() => _page = 0);
                _go(_Step.edit);
              }
            : c.canOrder(d) && d.lowQuality(_media())
            ? () {
                setState(() => _page = 0);
                _go(_Step.edit);
              }
            : c.canOrder(d) && c.price(d) != null
            ? () => _go(_Step.checkout)
            : null,
      ),
      _Step.checkout => (l.psCheckout, () => _submit(c)),
      _Step.success => (l.psViewOrder, null),
      _Step.export => switch (_watchJob()?.state) {
        PrintExportState.ready => (l.psDone, _back),
        PrintExportState.working => (l.psDownload, null),
        _ => (l.psDownload, c.digital && d.ready ? _download : null),
      },
    };
    return PrintBottomBar(
      stacked: false,
      compactPrice: _step == _Step.preview,
      fillAction: _step == _Step.checkout,
      priceLabel: c.pricesEstimated ? l.psEstimatedTotal : l.psTotal,
      // PR-3: the caption follows the chosen payment.
      caption: _step == _Step.checkout
          ? (_payment == 'bankTransfer'
                ? l.psPayByTransfer
                : l.psNoAdvancePayment)
          : _step == _Step.options
          ? l.psShippingLater
          : _step == _Step.preview && !d.isBook
          ? l.psPreviewPriceCaption(d.count, d.size.replaceAll('x', '×'))
          : '${d.size.replaceAll('x', '×')} cm',
      label: label,
      onPressed: _busy ? null : action,
      busy: _busy,
      secondaryLabel: _step == _Step.options && c.digital
          ? l.psDownloadShort
          : null,
      onSecondary: () => _go(_Step.export),
      price: _step == _Step.export
          ? null
          : _step == _Step.checkout
          ? c.totals(d, _quantity, giftWrap: _gift).total
          : c.price(d) == null
          ? null
          : c.price(d)! * _quantity,
    );
  }

  Future<void> _editBookPage(int page) async {
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: PrintMotion.sheet(context),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cl.colors.surface,
      builder: (context) => PrintBookPageEditor(
        design: _design!,
        media: _media(),
        page: page,
        onChanged: _change,
        onPhoto: (position) {
          Navigator.pop(context);
          _pick(
            _design!.slots(page)[position],
            bookPage: page,
            position: position,
          );
        },
      ),
    );
  }

  Map<String, dynamic> _shippingAddress() => {
    'recipient': _recipient.text,
    'phone': _phone.text,
    'address': _address.text,
    'country': _country.text,
    'neededBy': _neededBy == null
        ? null
        : DateFormat('yyyy-MM-dd').format(_neededBy!),
  };
  Future<void> _editAddress(PrintCatalog c) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      sheetAnimationStyle: PrintMotion.sheet(context),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cl.colors.cloud,
      builder: (_) =>
          PrintAddressEditor(initial: _shippingAddress(), leadDays: c.leadDays),
    );
    if (result == null || !mounted) return;
    setState(() {
      _recipient.text = result['recipient'] as String;
      _phone.text = result['phone'] as String;
      _address.text = result['address'] as String;
      _country.text = result['country'] as String;
      _neededBy = DateTime.tryParse(result['neededBy'] as String? ?? '');
      _requestId = const Uuid().v4();
    });
    // PR-2: an unsupported country is said on checkout, never a silent jump to "Tải file".
  }

  Future<void> _submit(PrintCatalog c) async {
    if (!_approved) {
      showClToast(context, message: l.psCheckoutProof);
      return;
    }
    if (_recipient.text.trim().length < 2 ||
        _address.text.trim().length < 10 ||
        !RegExp(
          r'^(0|\+84)[35789]\d{8}$',
        ).hasMatch(_phone.text.replaceAll(RegExp(r'[\s()-]'), ''))) {
      await _editAddress(c);
      return;
    }
    if (!c.countries.contains(_country.text)) {
      showClToast(
        context,
        message: l.psCountryUnsupported(_countryLabel(_country.text)),
        error: true,
      );
      return;
    }
    if (!c.canOrder(_design!)) {
      showClToast(context, message: l.psUnavailable);
      return;
    }
    if (_neededBy != null &&
        _neededBy!.isBefore(
          DateUtils.dateOnly(DateTime.now()).add(Duration(days: c.leadDays)),
        )) {
      showClToast(context, message: l.psTooSoon);
      return;
    }
    await _order(c);
  }

  String _occasionName(String o) => switch (o) {
    'month' => l.psMonth,
    'birthday' => l.psBirthday,
    'custom' => l.psCustom,
    _ => l.psHundred,
  };
  void _policy(PrintCatalog c) => showPrintPolicy(context, c);
  String _countryLabel(String code) => countryName(l, code);
}

DateTime _occasionDate(MemoryCtx ctx, String occasion) {
  final dob = ctx.dob;
  if (dob == null || occasion == 'custom') return DateUtils.dateOnly(ctx.now);
  return switch (occasion) {
    'month' => DateTime(dob.year, dob.month + 1, dob.day),
    'birthday' => DateTime(
      ctx.now.year +
          (DateTime(
                ctx.now.year,
                dob.month,
                dob.day,
              ).isBefore(DateUtils.dateOnly(ctx.now))
              ? 1
              : 0),
      dob.month,
      dob.day,
    ),
    _ => dob.add(const Duration(days: 100)),
  };
}

PrintDesign newPrintDesign(
  MemoryCtx ctx,
  List<MediaItem> media,
  String product,
  AppLocalizations l, {
  String? photoId,
}) {
  final selectedPhoto = photoId == null
      ? null
      : media.where((m) => m.id == photoId).firstOrNull;
  final age = ctx.dob == null ? 100 : ctx.now.difference(ctx.dob!).inDays;
  final occasion = selectedPhoto != null
      ? 'custom'
      : product == 'book'
      ? 'hundred'
      : age < 60
      ? 'month'
      : age < 180
      ? 'hundred'
      : 'birthday';
  final day = selectedPhoto?.captureAt ?? _occasionDate(ctx, occasion);
  final from = occasion == 'birthday'
      ? day.subtract(const Duration(days: 365))
      : ctx.dob;
  final photos = media
      .where(
        (m) =>
            m.isReady &&
            !m.deleted &&
            !m.isVideo &&
            m.paths?.original != null &&
            m.generatedKind == null &&
            (selectedPhoto != null ||
                ((from == null || !m.captureAt.isBefore(from)) &&
                    m.captureAt.isBefore(day.add(const Duration(days: 1))))),
      )
      .toList();
  // Deterministic, diverse chronology. No invented milestone or face-quality claim.
  photos.sort((a, b) => a.captureAt.compareTo(b.captureAt));
  final chosen = <String>[];
  if (photoId != null && photos.any((m) => m.id == photoId)) {
    chosen.add(photoId);
  }
  final limit = product == 'book'
      ? 40
      : product == 'five'
      ? 7
      : 5;
  if (photos.length <= limit) {
    chosen.addAll(photos.map((m) => m.id).where((id) => !chosen.contains(id)));
  } else {
    for (var i = 0; i < limit; i++) {
      final id = photos[(i * (photos.length - 1) / (limit - 1)).round()].id;
      if (!chosen.contains(id)) chosen.add(id);
    }
  }
  return PrintDesign(
    name: ctx.nickname,
    title: occasion == 'month'
        ? l.psMonth
        : occasion == 'birthday'
        ? l.psBirthday
        : occasion == 'custom'
        ? l.psCustom
        : l.psHundred,
    occasion: occasion,
    date: DateFormat('yyyy-MM-dd').format(day),
    product: product,
    size: product == 'book' ? '20x20' : '13x18',
    message: l.psDefaultMessage,
    birthDetails: ctx.dob == null
        ? ''
        : DateFormat('dd.MM.yyyy').format(ctx.dob!),
    mediaIds: chosen.take(limit).toList(),
    pageLayouts: product == 'five'
        ? const ['collage', 'portrait', 'text', 'portrait', 'collage']
        : const [],
    pagePhotos: product == 'five'
        ? const [
            [0, 1, 2, 3],
            [4],
            [],
            [5],
            [1, 2, 6, 0],
          ]
        : const [],
    pageTitles: product == 'book'
        ? List.generate(
            24,
            (i) => i == 0
                ? '${l.psHundred}\n${ctx.nickname}'
                : photos.isEmpty
                ? ''
                : photos
                          .firstWhere((m) => m.id == chosen[i % chosen.length])
                          .milestone
                          ?.name ??
                      '',
          )
        : const [],
    pageSubtitles: product == 'book'
        ? List.generate(
            24,
            (i) => photos.isEmpty
                ? ''
                : DateFormat('dd.MM.yyyy').format(
                    photos
                        .firstWhere((m) => m.id == chosen[i % chosen.length])
                        .captureAt,
                  ),
          )
        : const [],
    locale: ctx.locale.startsWith('en') ? 'en' : 'vi',
  );
}
