import 'package:flutter/material.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memory_models.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_reviews.dart';
import 'print_widgets.dart';

/// PS15: a real product page, separate from the editable design preview.
class PrintProductDetails extends StatefulWidget {
  const PrintProductDetails({
    required this.design,
    required this.media,
    required this.onCustomize,
    required this.onBack,
    required this.onChoose,
    required this.onPolicy,
    required this.price,
    this.initialPage = 0,
    super.key,
  });
  final PrintDesign design;
  final List<MediaItem> media;
  final VoidCallback onCustomize, onChoose, onPolicy, onBack;
  final int? price;
  final int initialPage;
  @override
  State<PrintProductDetails> createState() => _PrintProductDetailsState();
}

class _PrintProductDetailsState extends State<PrintProductDetails> {
  late int page;
  @override
  void initState() {
    super.initState();
    page = widget.initialPage;
  }

  String _angle(int i) {
    final l = AppLocalizations.of(context);
    return [
      l.psGalleryTable,
      l.psGalleryAngle,
      l.psFrameBack,
      l.psFrameSide,
    ][i];
  }

  Widget _round(IconData icon, VoidCallback tap) => Material(
    color: Colors.white.withValues(alpha: .92),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: tap,
      icon: Icon(icon, size: 20),
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    ),
  );
  Widget _gallery(double height, {int? angle}) {
    final a = angle ?? page;
    if (a >= 2) {
      return Container(
        color: const Color(0xffeee4d7),
        padding: const EdgeInsets.all(30),
        child: PrintFrameConstruction(side: a == 3),
      );
    }
    return LayoutBuilder(
      builder: (context, c) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: OverflowBox(
          maxWidth: c.maxWidth * 1.35112,
          minWidth: c.maxWidth * 1.35112,
          alignment: Alignment.center,
          child: PrintScene(
            design: widget.design,
            media: widget.media,
            height: height,
            standing: true,
            decorated: false,
            page: a == 1 ? 0 : null,
          ),
        ),
      ),
    );
  }

  void _fullscreen() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xff0b171a),
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _angle(page),
                      style: psText(context, 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(c).width,
                      height: 330,
                      child: _gallery(330),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final cl = context.cl, l = AppLocalizations.of(context), d = widget.design;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text(
        text,
        style: cl.text.headline.copyWith(
          fontFamily: 'Be Vietnam Pro Keepsake',
          height: 1.3,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 330,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _fullscreen,
                  child: _gallery(330),
                ),
              ),
              Positioned(
                top: 12,
                left: 0,
                child: _round(Icons.arrow_back, widget.onBack),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _round(Icons.fullscreen, _fullscreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 78,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => page = i),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: page == i
                                  ? cl.colors.mintDeep
                                  : cl.colors.controlBorder,
                              width: page == i ? 2 : 1,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: 343,
                              height: 330,
                              child: _gallery(330, angle: i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _angle(i),
                          style: psText(
                            context,
                            10,
                            weight: page == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          d.isBook
              ? l.psBookTitle(d.title, d.name)
              : '${printProductName(l, d.product)} · ${d.title}',
          style: cl.text.title2.copyWith(
            fontFamily: 'Be Vietnam Pro Keepsake',
            height: 1.25,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.price != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              printMoney(context, widget.price!),
              style: cl.text.title2.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.25,
                color: cl.colors.mintText,
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(l.psSamplePrice, style: cl.text.caption),
        const SizedBox(height: 14),
        if (!d.isBook) ...[
          heading(l.psHowStands),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: PrintCard(
                      lifted: false,
                      radius: 16,
                      padding: const EdgeInsets.all(8),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (c) => Dialog(
                          backgroundColor: cl.colors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 300,
                                  child: i == 0
                                      ? PrintFrame(
                                          design: d,
                                          media: widget.media,
                                          standing: true,
                                        )
                                      : PrintFrameConstruction(side: i == 2),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: Text(l.psClose),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 96,
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xfff2ebde),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: i == 0
                                ? PrintFrame(
                                    design: d,
                                    media: widget.media,
                                    standing: true,
                                  )
                                : PrintFrameConstruction(side: i == 2),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            i == 0
                                ? l.psStanding
                                : i == 1
                                ? l.psFrameBack
                                : l.psFrameSide,
                            textAlign: TextAlign.center,
                            style: cl.text.caption.copyWith(
                              fontFamily: 'Be Vietnam Pro Keepsake',
                              height: 1.3,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cl.colors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i == 0
                                ? l.psStandingHelp
                                : i == 1
                                ? l.psFrameBackHelp
                                : l.psFrameSideHelp,
                            textAlign: TextAlign.center,
                            style: cl.text.caption.copyWith(
                              fontFamily: 'Be Vietnam Pro Keepsake',
                              height: 1.3,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PrintCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.psSizeComparison,
                  style: cl.text.label.copyWith(
                    fontFamily: 'Be Vietnam Pro Keepsake',
                    height: 1.3,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 123,
                      width: 93,
                      child: PrintFrame(design: d, media: widget.media),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      height: 88,
                      width: 43,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cl.colors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cl.colors.inkMuted,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    l.psComparisonHelp,
                    style: cl.text.caption.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.3,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        heading(l.psInYourSet),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < (d.isBook ? 1 : d.count); i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < d.count - 1 ? 8 : 0),
                  child: PrintCard(
                    padding: const EdgeInsets.all(8),
                    lifted: false,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: PrintFrame(
                            design: d,
                            media: widget.media,
                            page: i,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.isBook
                              ? l.psBook
                              : i == 1
                              ? l.psInfo
                              : i == 2
                              ? l.psCollage
                              : l.psPortrait,
                          style: cl.text.caption.copyWith(
                            fontFamily: 'Be Vietnam Pro Keepsake',
                            height: 1.3,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        heading(l.psProductInfo),
        PrintCard(
          lifted: false,
          child: Column(
            children: [
              for (final row in [
                (l.psSize, '${d.size.replaceAll('x', ' × ')} cm'),
                (
                  l.psFrames,
                  d.frame == 'white'
                      ? l.psWhite
                      : d.frame == 'wood'
                      ? l.psWood
                      : l.psGift,
                ),
                (l.psAcrylicTitle, l.psAcrylicHelp),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(row.$1, style: cl.text.caption)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.$2,
                          style: cl.text.caption.copyWith(
                            fontFamily: 'Be Vietnam Pro Keepsake',
                            height: 1.3,
                            color: cl.colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        heading(l.psCustomerReviews),
        const PrintReviews(),
        heading(l.psShippingAndPayment),
        PrintCard(
          lifted: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ClIcon(ClIcons.check, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.psNoDepositTitle,
                      style: cl.text.label.copyWith(
                        fontFamily: 'Be Vietnam Pro Keepsake',
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.psNoDepositHelp, style: cl.text.caption),
              TextButton(onPressed: widget.onPolicy, child: Text(l.psPolicy)),
            ],
          ),
        ),
        TextButton(onPressed: widget.onChoose, child: Text(l.psChooseProduct)),
      ],
    );
  }
}
