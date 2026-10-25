import 'package:flutter/material.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memory_models.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_widgets.dart';

/// PS22: edit the selected page in a sheet above the open spread.
class PrintBookPageEditor extends StatefulWidget {
  const PrintBookPageEditor({
    required this.design,
    required this.media,
    required this.page,
    required this.onChanged,
    required this.onPhoto,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final int page;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ValueChanged<int> onPhoto;
  @override
  State<PrintBookPageEditor> createState() => _PrintBookPageEditorState();
}

class _PrintBookPageEditorState extends State<PrintBookPageEditor> {
  late PrintDesign design = widget.design;
  String tab = 'text';
  late final title = TextEditingController(
        text: widget.page < design.pageTitles.length
            ? design.pageTitles[widget.page]
            : '',
      ),
      subtitle = TextEditingController(
        text: widget.page < design.pageSubtitles.length
            ? design.pageSubtitles[widget.page]
            : '',
      );
  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    super.dispose();
  }

  void change(Map<String, dynamic> fields) {
    setState(() => design = design.copy(fields));
    widget.onChanged(fields);
  }

  void textChanged() {
    final titles = List.generate(
          design.pages,
          (i) => i < design.pageTitles.length ? design.pageTitles[i] : '',
        ),
        subtitles = List.generate(
          design.pages,
          (i) => i < design.pageSubtitles.length ? design.pageSubtitles[i] : '',
        );
    titles[widget.page] = title.text;
    subtitles[widget.page] = subtitle.text;
    change({'pageTitles': titles, 'pageSubtitles': subtitles});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.psPage} ${widget.page + 1}${title.text.isEmpty ? '' : ' · ${title.text}'}',
              style: psText(context, 24, weight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            PrintSegments<String>(
              values: const ['photos', 'text', 'layout'],
              value: tab,
              label: (v) => v == 'photos'
                  ? l.psBookImages
                  : v == 'text'
                  ? l.psBookText
                  : l.psBookLayout,
              onChanged: (v) => setState(() => tab = v),
            ),
            const SizedBox(height: 14),
            if (tab == 'text') ...[
              PrintInput(
                label: l.psPrintTitle,
                controller: title,
                maxLength: 80,
              ),
              const SizedBox(height: 14),
              PrintInput(
                label: l.psBookSubtitle,
                controller: subtitle,
                maxLength: 100,
              ),
              const SizedBox(height: 6),
              Text(
                l.psBookTitleHint,
                style: psText(context, 12, color: cl.colors.inkMuted),
              ),
            ],
            if (tab == 'photos') ...[
              SizedBox(
                height: 170,
                child: Center(
                  child: PrintArtwork(
                    design: design,
                    media: widget.media,
                    page: widget.page,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (
                    var position = 0;
                    position < design.slots(widget.page).length;
                    position++
                  )
                    ClButton(
                      label: '${l.psPhotoChange} ${position + 1}',
                      style: ClButtonStyle.secondary,
                      onPressed: () => widget.onPhoto(position),
                    ),
                ],
              ),
            ],
            if (tab == 'layout')
              Row(
                children: [
                  for (final layout in ['portrait', 'collage', 'text'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PrintCard(
                          selected: design.bookLayout(widget.page) == layout,
                          outlined: true,
                          lifted: false,
                          onTap: () {
                            final layouts = List.generate(
                                  design.pages,
                                  design.bookLayout,
                                ),
                                pages = List.generate(
                                  design.pages,
                                  (i) => [...design.slots(i)],
                                );
                            layouts[widget.page] = layout;
                            pages[widget.page] = layout == 'text'
                                ? []
                                : List.generate(
                                    layout == 'collage' ? 4 : 1,
                                    (i) => design.mediaIds.isEmpty
                                        ? 0
                                        : (widget.page + i) %
                                              design.mediaIds.length,
                                  );
                            change({
                              'pageLayouts': layouts,
                              'pagePhotos': pages,
                            });
                          },
                          child: Column(
                            children: [
                              SizedBox(
                                height: 90,
                                child: PrintArtwork(
                                  design: design.copy({
                                    'pageLayouts': List.generate(
                                      design.pages,
                                      (i) => i == widget.page
                                          ? layout
                                          : design.bookLayout(i),
                                    ),
                                    'pagePhotos': List.generate(
                                      design.pages,
                                      (i) => i == widget.page
                                          ? (layout == 'text'
                                                ? <int>[]
                                                : List.generate(
                                                    layout == 'collage' ? 4 : 1,
                                                    (s) =>
                                                        design.mediaIds.isEmpty
                                                        ? 0
                                                        : (i + s) %
                                                              design
                                                                  .mediaIds
                                                                  .length,
                                                  ))
                                          : design.slots(i),
                                    ),
                                  }),
                                  media: widget.media,
                                  page: widget.page,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                layout == 'portrait'
                                    ? l.psPortrait
                                    : layout == 'collage'
                                    ? l.psCollage
                                    : l.psBookText,
                                style: psText(context, 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            ClButton(
              label: l.psDone,
              expand: true,
              onPressed: () {
                textChanged();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
