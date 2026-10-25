import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_models.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_widgets.dart';
import 'print_motion.dart';

class PrintBookSpread extends StatelessWidget {
  const PrintBookSpread({
    required this.design,
    required this.media,
    required this.page,
    this.single = false,
    this.bound = false,
    this.onPage,
    this.onPhoto,
    this.onDrop,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final int page;
  final bool single, bound;
  final ValueChanged<int>? onPage;
  final void Function(MediaItem photo, int page)? onDrop;
  final void Function(int page, int slot)? onPhoto;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final width = math.min(c.maxWidth, c.maxHeight * (single ? 1 : 2));
      return Center(
        child: SizedBox(
          width: width,
          height: width / (single ? 1 : 2),
          child: Container(
            padding: EdgeInsets.all(bound ? 7 : 0),
            decoration: BoxDecoration(
              color: bound ? const Color(0xff2f514b) : const Color(0xfff8f3ea),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40332414),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < (single ? 1 : 2); i++)
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DragTarget<MediaItem>(
                            onAcceptWithDetails: (detail) =>
                                onDrop?.call(detail.data, page + i),
                            builder: (context, _, _) => PrintArtwork(
                              design: design,
                              media: media,
                              page: (page + i).clamp(0, design.pages - 1),
                              onPhotoTap: onPhoto == null
                                  ? null
                                  : (slot) => onPhoto!(page + i, slot),
                              onTextTap: onPage == null
                                  ? null
                                  : () => onPage!(page + i),
                            ),
                          ),
                        ),
                        if (!single)
                          Positioned(
                            left: i == 1 ? 0 : null,
                            right: i == 0 ? 0 : null,
                            top: 0,
                            bottom: 0,
                            width: 16,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: i == 0
                                        ? [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: .10),
                                          ]
                                        : [
                                            Colors.black.withValues(alpha: .16),
                                            Colors.transparent,
                                          ],
                                  ),
                                ),
                              ),
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
    },
  );
}

/// PS21 + 1018:13871. The open spread and the month's actual photo library share a page.
class PrintBookViewer extends StatefulWidget {
  const PrintBookViewer({
    required this.design,
    required this.media,
    required this.onChanged,
    required this.onEdit,
    required this.favorites,
    required this.dob,
    this.onPhoto,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final Set<String> favorites;
  final DateTime? dob;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ValueChanged<int> onEdit;
  final void Function(int page, int slot)? onPhoto;
  @override
  State<PrintBookViewer> createState() => _PrintBookViewerState();
}

class _PrintBookViewerState extends State<PrintBookViewer> {
  final controller = PageController();
  int spread = 0, month = 1, selectedChapter = 1;
  String filter = 'unused';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<MediaItem> get monthly => photosInMonth(month);
  List<MediaItem> photosInMonth(int month) {
    final dob = widget.dob;
    return widget.media.where((m) {
      if (!m.isReady || m.deleted || m.generatedKind != null) return false;
      if (dob == null) return true;
      final from = DateTime(
            dob.year,
            dob.month + math.max(0, month - 1),
            dob.day,
          ),
          until = DateTime(dob.year, dob.month + math.max(1, month), dob.day);
      return !m.captureAt.isBefore(from) &&
          m.captureAt.isBefore(
            month == 0 ? from.add(const Duration(days: 7)) : until,
          );
    }).toList();
  }

  void selectChapter(int chapter) {
    final d = widget.design;
    final photoIds = chapter == 4
        ? <String>{}
        : photosInMonth(chapter).map((m) => m.id).toSet();
    final target = List.generate(d.pages, (p) => p)
        .where(
          (p) => chapter == 4
              ? d.bookLayout(p) == 'text'
              : d
                    .slots(p)
                    .any(
                      (i) =>
                          i < d.mediaIds.length &&
                          photoIds.contains(d.mediaIds[i]),
                    ),
        )
        .firstOrNull;
    setState(() {
      selectedChapter = chapter;
      if (chapter != 4) month = chapter;
    });
    if (target != null) controller.jumpToPage(target ~/ 2);
  }

  Set<String> get used => {
    for (var p = 0; p < widget.design.pages; p++)
      for (final i in widget.design.slots(p))
        if (i < widget.design.mediaIds.length) widget.design.mediaIds[i],
  };
  void addPhoto(MediaItem photo, int page, {int? slot}) {
    if (photo.isVideo) return;
    final d = widget.design, registry = [...d.mediaIds];
    var index = registry.indexOf(photo.id);
    if (index < 0) {
      if (registry.length >= 40) return;
      index = registry.length;
      registry.add(photo.id);
    }
    final pages = List.generate(d.pages, (i) => [...d.slots(i)]),
        layouts = List.generate(d.pages, d.bookLayout);
    final current = pages[page];
    if (slot != null && current.contains(slot)) {
      current[current.indexOf(slot)] = index;
    } else if (current.length < 4) {
      current.add(index);
    } else {
      current[0] = index;
    }
    if (current.length > 1) {
      while (current.length < 4) {
        current.add(current.last);
      }
    }
    layouts[page] = current.length > 1 ? 'collage' : 'portrait';
    widget.onChanged({
      'mediaIds': registry,
      'pagePhotos': pages,
      'pageLayouts': layouts,
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.design,
        l = AppLocalizations.of(context),
        cl = context.cl,
        all = monthly,
        available = all
            .where(
              (m) => switch (filter) {
                'used' => used.contains(m.id),
                'favorites' => widget.favorites.contains(m.id),
                'video' => m.isVideo,
                'all' => true,
                _ => !m.isVideo && !used.contains(m.id),
              },
            )
            .toList();
    Widget chip(
      String text,
      bool selected,
      VoidCallback tap, {
      bool photoFilter = false,
    }) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? (photoFilter ? cl.colors.mintDeep : cl.colors.ink)
                : cl.colors.surface2,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: cl.colors.separator),
          ),
          child: Text(
            text,
            style: psText(
              context,
              12,
              weight: FontWeight.w600,
              color: selected ? cl.colors.surface : cl.colors.ink,
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '${l.psPage} ${spread * 2 + 1}–${math.min(d.pages, spread * 2 + 2)} / ${d.pages}',
            style: psText(
              context,
              13,
              weight: FontWeight.w600,
              color: cl.colors.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: (MediaQuery.sizeOf(context).width - 32) / 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: controller,
                  itemCount: (d.pages / 2).ceil(),
                  onPageChanged: (i) => setState(() => spread = i),
                  itemBuilder: (context, i) => PrintBookSpread(
                    design: d,
                    media: widget.media,
                    page: i * 2,
                    onPage: widget.onEdit,
                    onPhoto: widget.onPhoto,
                    onDrop: (photo, page) => addPhoto(photo, page),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  tooltip: l.psFullscreen,
                  style: IconButton.styleFrom(
                    backgroundColor: cl.colors.inkMuted.withValues(alpha: .85),
                  ),
                  onPressed: () async {
                    final result =
                        await Navigator.push<({int page, bool edit})>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrintBookFullscreen(
                              design: d,
                              media: widget.media,
                              initialPage: spread * 2,
                              onEdit: (p) =>
                                  Navigator.pop(context, (page: p, edit: true)),
                              onClose: (p) => Navigator.pop(context, (
                                page: p,
                                edit: false,
                              )),
                            ),
                          ),
                        );
                    if (result != null && mounted) {
                      controller.jumpToPage(result.page ~/ 2);
                      if (result.edit) widget.onEdit(result.page);
                    }
                  },
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            l.psBookPageHelp,
            style: psText(context, 12, color: cl.colors.inkMuted),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: d.pages,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) => InkWell(
              onTap: () => controller.animateToPage(
                i ~/ 2,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              child: Container(
                width: 58,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: spread == i ~/ 2
                      ? cl.colors.mintDeep
                      : cl.colors.surface2,
                ),
                child: PrintArtwork(design: d, media: widget.media, page: i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 29,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              chip(l.psBookBirth, selectedChapter == 0, () => selectChapter(0)),
              for (var m = 1; m <= 3; m++)
                chip(
                  l.psBookMonth('$m'),
                  selectedChapter == m,
                  () => selectChapter(m),
                ),
              chip(
                l.psBookMessages,
                selectedChapter == 4,
                () => selectChapter(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                l.psBookMonthPhotos('$month', d.name),
                style: psText(context, 17, weight: FontWeight.w700),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => filter = 'all'),
              child: Text(
                l.psSeeAll,
                style: psText(context, 13, color: cl.colors.mintText),
              ),
            ),
          ],
        ),
        Text(
          l.psBookMonthSummary(
            widget.dob == null
                ? ''
                : DateFormat('dd/MM').format(
                    DateTime(
                      widget.dob!.year,
                      widget.dob!.month + math.max(0, month - 1),
                      widget.dob!.day,
                    ),
                  ),
            widget.dob == null
                ? ''
                : DateFormat('dd/MM').format(
                    DateTime(
                      widget.dob!.year,
                      widget.dob!.month + math.max(1, month),
                      widget.dob!.day,
                    ),
                  ),
            '${all.length}',
            '${all.where((m) => used.contains(m.id)).length}',
          ),
          style: psText(context, 12, color: cl.colors.inkMuted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final row in [
                ('unused', l.psUnused),
                ('used', l.psUsed),
                ('favorites', l.psFavorites),
                ('video', l.psVideos),
              ])
                chip(
                  row.$2,
                  filter == row.$1,
                  () => setState(() => filter = row.$1),
                  photoFilter: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (available.isEmpty)
          PrintNotice(l.psBookSparseMonth)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: available.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, i) {
              final item = available[i];
              final photo = ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image(
                  image: StorageImage(item.displayPath ?? item.thumbPath ?? ''),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: ClIcon(ClIcons.camera)),
                ),
              );
              return LongPressDraggable<MediaItem>(
                data: item,
                feedback: SizedBox(width: 90, height: 90, child: photo),
                child: InkWell(
                  onTap: () => addPhoto(item, spread * 2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo,
                      if (!used.contains(item.id))
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: cl.colors.mintDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      if (used.contains(item.id))
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            color: cl.colors.inkMuted.withValues(alpha: .7),
                            padding: const EdgeInsets.all(3),
                            child: Text(
                              l.psBookUsedPage(
                                '${List.generate(d.pages, (p) => p).firstWhere((p) => d.slots(p).any((slot) => slot < d.mediaIds.length && d.mediaIds[slot] == item.id)) + 1}',
                              ),
                              style: psText(context, 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        PrintNotice(l.psBookLibraryHelp),
      ],
    );
  }
}

class PrintBookFullscreen extends StatefulWidget {
  const PrintBookFullscreen({
    required this.design,
    required this.media,
    required this.initialPage,
    required this.onEdit,
    this.onClose,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final int initialPage;
  final ValueChanged<int> onEdit;
  final ValueChanged<int>? onClose;
  @override
  State<PrintBookFullscreen> createState() => _PrintBookFullscreenState();
}

class _PrintBookFullscreenState extends State<PrintBookFullscreen> {
  late int page = widget.initialPage;
  late PageController controller = PageController(
    initialPage: widget.initialPage,
  );
  bool controls = true;
  bool lastLandscape = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void turn(int by, bool landscape) {
    final target = ((page / (landscape ? 2 : 1)).floor() + by).clamp(
      0,
      (widget.design.pages / (landscape ? 2 : 1)).ceil() - 1,
    );
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    if (landscape != lastLandscape) {
      final previous = controller;
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      controller = PageController(initialPage: landscape ? page ~/ 2 : page);
      lastLandscape = landscape;
    }
    return Scaffold(
      backgroundColor: const Color(0xff09090b),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => controls = !controls),
                child: AnimatedPadding(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : PrintMotion.fullscreen,
                  curve: PrintMotion.curve,
                  padding: EdgeInsets.fromLTRB(
                    landscape ? (controls ? 70 : 16) : 20,
                    landscape ? (controls ? 55 : 4) : 80,
                    landscape ? (controls ? 70 : 16) : 10,
                    landscape
                        ? (controls ? 12 : 4)
                        : controls
                        ? 150
                        : 30,
                  ),
                  child: PageView.builder(
                    controller: controller,
                    itemCount: (widget.design.pages / (landscape ? 2 : 1))
                        .ceil(),
                    onPageChanged: (i) =>
                        setState(() => page = i * (landscape ? 2 : 1)),
                    itemBuilder: (_, i) => PrintBookSpread(
                      design: widget.design,
                      media: widget.media,
                      page: i * (landscape ? 2 : 1),
                      single: !landscape,
                      bound: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !controls,
                child: AnimatedOpacity(
                  opacity: controls ? 1 : 0,
                  duration: PrintMotion.duration(context, full: true),
                  curve: PrintMotion.curve,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 10,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: l.psClose,
                              onPressed: () => widget.onClose != null
                                  ? widget.onClose!(page)
                                  : Navigator.pop(context),
                              icon: const ClIcon(
                                ClIcons.close,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                landscape
                                    ? '${l.psPage} ${page + 1}–${math.min(page + 2, widget.design.pages)} / ${widget.design.pages}'
                                    : l.psOpenPage(
                                        '${page + 1}',
                                        '${widget.design.pages}',
                                      ),
                                style: psText(
                                  context,
                                  13,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: landscape
                                  ? () => widget.onEdit(page)
                                  : () =>
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]),
                              child: Text(
                                landscape ? l.psEditPage : l.psLandscape,
                                style: psText(
                                  context,
                                  12,
                                  color: Colors.white,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (landscape) ...[
                        Positioned(
                          left: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: () => turn(-1, true),
                              icon: const ClIcon(
                                ClIcons.back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: () => turn(1, true),
                              icon: const ClIcon(
                                ClIcons.chevronRight,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 22,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 58,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (widget.design.pages / 2).ceil(),
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (context, i) => InkWell(
                                    onTap: () => controller.jumpToPage(i * 2),
                                    child: Container(
                                      width: 58,
                                      padding: const EdgeInsets.all(3),
                                      color: page ~/ 2 == i
                                          ? const Color(0xff087f7b)
                                          : const Color(0xfff8f3ea),
                                      child: PrintArtwork(
                                        design: widget.design,
                                        media: widget.media,
                                        page: i * 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: (page + 1) / widget.design.pages,
                                color: Colors.white,
                                backgroundColor: Colors.white24,
                                minHeight: 3,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l.psBookFullscreenHelp,
                                style: psText(
                                  context,
                                  11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
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
    );
  }
}
