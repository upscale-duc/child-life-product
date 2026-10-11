import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_models.dart';
import '../memories/memory_sheets.dart';
import 'share_repository.dart';
import 'story_models.dart';
import 'story_repository.dart';
import 'story_widgets.dart';

// ---------- 14h Chia sẻ ----------

/// 14h: who reads it in the family, and (parents only) a card or a private link outside.
Future<void> showShareSheet(BuildContext context, WidgetRef ref, Story s) =>
    showClSheet<void>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        final cl = sheet.cl;
        final family = s.audience == Audience.family;
        void go(Widget page) {
          Navigator.of(sheet).pop();
          Navigator.of(context).push(
            MaterialPageRoute(fullscreenDialog: true, builder: (_) => page),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.sryShare),
            MeSection(l10n.shInFamily),
            ClCardGroup(
              children: [
                MeRow(
                  icon: family ? ClIcons.family : ClIcons.lock,
                  title: family ? l10n.shFamilyReading : l10n.shParentsReading,
                  subtitle: family
                      ? l10n.shTapToChange
                      : l10n.shTapToChangeParents,
                  trailing: ClIcon(
                    ClIcons.check,
                    size: 18,
                    color: cl.colors.mintText,
                  ),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    changeReaders(context, ref, s);
                  },
                ),
              ],
            ),
            MeSection(l10n.shOutside),
            ClCardGroup(
              children: [
                MeRow(
                  icon: ClIcons.camera,
                  title: l10n.shCard,
                  subtitle: l10n.shCardHint,
                  onTap: () => go(CardScreen(story: s)),
                ),
                MeRow(
                  icon: ClIcons.link,
                  title: l10n.shLink,
                  subtitle: l10n.shLinkHint,
                  onTap: () => go(LinkScreen(story: s)),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            MeNotice(
              icon: ClIcons.alert,
              title: l10n.shOutsideNote,
              body: l10n.shPrivatePhotosNote,
            ),
          ],
        );
      },
    );

/// "chạm để đổi": Chỉ ba mẹ / Gia đình for the saved story.
Future<void> changeReaders(BuildContext context, WidgetRef ref, Story s) async {
  final l10n = AppLocalizations.of(context);
  var audience = s.audience;
  final next = await showClSheet<Audience>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sryWhoReads),
          AudienceCards(
            value: audience,
            onChanged: (a) => setState(() => audience = a),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionSave,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(audience),
          ),
        ],
      ),
    ),
  );
  if (next == null || next == s.audience || !context.mounted) return;
  final toaster = ClToaster.of(context);
  try {
    await ref.read(storyRepositoryProvider).save(s.babyId, s.id, next, false);
    toaster.show(message: l10n.sryAudienceChanged);
  } on Object {
    toaster.show(message: l10n.toastActionFailed);
  }
}

// ---------- 14i Thiệp ảnh ----------

/// What a card shows (never the real name; the age, or the birth date when asked).
@immutable
class CardData {
  const CardData({
    required this.title,
    required this.quote,
    required this.excerpt,
    required this.photos,
    required this.idLine,
    required this.rangeLine,
    required this.handLine,
    required this.signature,
    required this.greeting,
  });
  final String title;
  final String quote;
  final String excerpt;
  final List<MediaItem> photos;

  /// "TEDDY · 3 TUẦN TUỔI".
  final String idLine;

  /// "1 – 8 tháng 10 · 3 tuần tuổi".
  final String rangeLine;

  /// Handwritten line: "Lần đầu cười · 5.10" / "tháng mười, 2026".
  final String handLine;
  final String signature;
  final String greeting;
}

const _cream = Color(0xFFFAF5EC);
const _ink = Color(0xFF173D44);
const _muted = Color(0xFF55707A);
const _nightBg = Color(0xFF1E262C);
const _gold = Color(0xFFD6B478);

TextStyle _lora(
  double size, {
  bool italic = false,
  FontWeight w = FontWeight.w400,
  Color c = _ink,
}) => TextStyle(
  fontFamily: 'Lora',
  fontSize: size,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  fontWeight: w,
  color: c,
  height: 1.35,
);
TextStyle _hand(double size, {Color c = _ink}) => TextStyle(
  fontFamily: 'Dancing Script',
  fontSize: size,
  color: c,
  fontWeight: FontWeight.w600,
);
TextStyle _small(double size, {Color c = _muted}) => TextStyle(
  fontFamily: 'Be Vietnam Pro',
  fontSize: size,
  color: c,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
);

Widget _photo(MediaItem? m, {double radius = 4}) => ClipRRect(
  borderRadius: BorderRadius.circular(radius),
  child: m?.displayPath == null
      ? const ColoredBox(color: Color(0xFFE8E2D6))
      : Image(image: StorageImage(m!.displayPath!), fit: BoxFit.cover),
);

Widget _brand({Color c = _muted}) => Align(
  alignment: Alignment.bottomRight,
  child: Text(
    'Child Life',
    style: _small(9, c: c).copyWith(letterSpacing: 0.4),
  ),
);

/// The StoryCard set (14n): 4:5, drawn at any size and exported at 1080 × 1350.
class StoryCardView extends StatelessWidget {
  const StoryCardView({required this.template, required this.data, super.key});
  final CardTemplate template;
  final CardData data;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 5,
    child: LayoutBuilder(
      builder: (context, c) {
        // Designed at 304 × 380 (208:109); scaled to the space given.
        return FittedBox(
          child: SizedBox(width: 304, height: 380, child: _card()),
        );
      },
    ),
  );

  Widget _card() {
    final d = data;
    final p = d.photos;
    MediaItem? at(int i) => i < p.length ? p[i] : null;
    switch (template) {
      case CardTemplate.moment:
        return Container(
          color: _cream,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Transform.rotate(
                angle: 0.05,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 196,
                        height: 170,
                        child: _photo(at(0), radius: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(d.handLine, style: _hand(15)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '“${d.quote}”',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _lora(15, italic: true),
              ),
              const SizedBox(height: 10),
              Text(d.idLine, style: _small(9)),
              _brand(),
            ],
          ),
        );
      case CardTemplate.three:
        return Container(
          color: _cream,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.title, maxLines: 2, style: _lora(20, w: FontWeight.w600)),
              Text(d.handLine, style: _hand(15, c: _muted)),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: Stack(
                  children: [
                    for (final (i, a) in const [(-0.06), 0.04, -0.02].indexed)
                      Positioned(
                        left: 4.0 + i * 86,
                        top: i.isOdd ? 14 : 0,
                        child: Transform.rotate(
                          angle: a,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            color: Colors.white,
                            child: SizedBox(
                              width: 92,
                              height: 118,
                              child: _photo(at(i), radius: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                d.excerpt,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: _lora(13, italic: true, c: _muted),
              ),
              _brand(),
            ],
          ),
        );
      case CardTemplate.four:
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [for (var i = 0; i < 4; i++) _photo(at(i))],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                d.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _lora(18, w: FontWeight.w600),
              ),
              Text(d.rangeLine, style: _small(9).copyWith(letterSpacing: 0.2)),
              _brand(),
            ],
          ),
        );
      case CardTemplate.letter:
        return Container(
          color: _cream,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: CustomPaint(
            painter: _Lines(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(d.greeting, style: _hand(22))),
                    Transform.rotate(
                      angle: 0.06,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.white,
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: _photo(at(0), radius: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    d.excerpt,
                    overflow: TextOverflow.fade,
                    style: _lora(13).copyWith(height: 1.65),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(d.signature, style: _hand(15)),
                ),
                _brand(),
              ],
            ),
          ),
        );
      case CardTemplate.night:
        return Container(
          color: _nightBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.55, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: _photo(at(0), radius: 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      maxLines: 2,
                      style: _lora(20, w: FontWeight.w600, c: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '“${d.quote}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _lora(14, italic: true, c: _gold),
                    ),
                    const SizedBox(height: 14),
                    _brand(c: Colors.white70),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _Lines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6DCC8)
      ..strokeWidth = 0.6;
    for (var y = 70.0; y < size.height - 30; y += 21.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 14i "Thiệp ảnh": 5 templates, the quote and photo, "Hiện tuổi thay ngày sinh"; "Tiếp" makes
/// one 1080 × 1350 image for the OS share sheet (14j) and lists it under 14m (R-161, R-162).
class CardScreen extends ConsumerStatefulWidget {
  const CardScreen({required this.story, super.key});
  final Story story;

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  final _boundary = GlobalKey();
  final _pages = PageController(viewportFraction: 0.86);
  var _template = CardTemplate.moment;
  late String _quote = _quotes.first;
  String? _photoId;
  var _showAge = true;
  var _busy = false;

  List<String> get _quotes {
    final s = widget.story;
    final quotes = [
      for (final b in s.blocks)
        if (b is QuoteBlock) b.text,
      for (final b in s.blocks)
        if (b is ParagraphBlock)
          ...b.text
              .split(RegExp(r'(?<=[.!?…])\s+'))
              .map((x) => x.trim())
              .where((x) => x.length > 12 && x.length < 140),
    ];
    return quotes.isEmpty ? [s.title] : quotes;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  CardData _data(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.story;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final media = storyMedia(ref, s.babyId, true);
    final familyOnly = [
      for (final id in s.mediaIds)
        if (media[id]?.effectiveAudience == Audience.family) media[id]!,
    ];
    final first = _photoId == null ? null : media[_photoId];
    final photos = [
      ?first,
      for (final m in familyOnly)
        if (m.id != _photoId) m,
    ];
    final baby = ref.watch(babyProvider(s.babyId)).value;
    final dob = ref
        .watch(babyPrivateProfileProvider(s.babyId))
        .value
        ?.dateOfBirth;
    final now = ref.read(timerClockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final nick = baby?.nickname ?? '';
    final age = dob == null ? '' : ageLong(l10n, dob, today);
    final idTail = _showAge
        ? age
        : (dob == null ? '' : DateFormat('d.M.y').format(dob));
    final end = s.rangeEnd ?? s.savedAt ?? s.updatedAt;
    final season = DateFormat('MMMM, y', locale).format(end);
    final milestone =
        s.milestone ??
        s.blocks
            .whereType<MilestoneBlock>()
            .map((b) => (name: b.name, date: b.date))
            .firstOrNull;
    return CardData(
      title: s.title,
      quote: _quote,
      excerpt: s.firstText,
      photos: photos,
      idLine: [
        nick.toUpperCase(),
        if (idTail.isNotEmpty) idTail.toUpperCase(),
      ].join(' · '),
      rangeLine: [
        if (s.rangeStart != null && s.rangeEnd != null)
          '${DateFormat('d', locale).format(s.rangeStart!)} – ${DateFormat('d MMMM', locale).format(s.rangeEnd!)}',
        if (_showAge && age.isNotEmpty) age,
      ].join(' · '),
      handLine: milestone == null
          ? season
          : '${milestone.name} · ${DateFormat('d.M').format(milestone.date)}',
      signature:
          '— ${s.author == null ? '' : storyAuthor(l10n, s, '')}, $season',
      greeting: l10n.cdTo(nick),
    );
  }

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      final box =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: 1080 / box.size.width);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/child-life-card-${widget.story.id.substring(4, 12)}.png',
      );
      await file.writeAsBytes(png!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: widget.story.title,
        ),
      );
      await ref
          .read(shareRepositoryProvider)
          .recordCard(widget.story, _template);
      toaster.show(message: l10n.cdSaved);
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final data = _data(context);
    final labels = {
      CardTemplate.moment: l10n.cdMoment,
      CardTemplate.three: l10n.cdThree,
      CardTemplate.four: l10n.cdFour,
      CardTemplate.letter: l10n.cdLetter,
      CardTemplate.night: l10n.cdNight,
    };
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: l10n.shCard,
              action: l10n.cdNext,
              onAction: _busy ? null : _next,
            ),
            SizedBox(
              height: 380,
              child: PageView(
                controller: _pages,
                onPageChanged: (i) =>
                    setState(() => _template = CardTemplate.values[i]),
                children: [
                  for (final t in CardTemplate.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        child: t == _template
                            ? RepaintBoundary(
                                key: _boundary,
                                child: StoryCardView(template: t, data: data),
                              )
                            : StoryCardView(template: t, data: data),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
              child: Row(
                children: [
                  for (final (i, t) in CardTemplate.values.indexed) ...[
                    if (i > 0) const SizedBox(width: ClSpace.s2),
                    ClPressable(
                      onPressed: () => _pages.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      selected: t == _template,
                      semanticLabel: labels[t],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClSpace.s3,
                          vertical: ClSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          color: t == _template
                              ? cl.colors.ink
                              : cl.colors.surface2,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          labels[t]!,
                          style: cl.text.label.copyWith(
                            color: t == _template
                                ? cl.colors.cloud
                                : cl.colors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ClSpace.s4),
                children: [
                  ClCardGroup(
                    children: [
                      MeRow(
                        title: l10n.cdQuote,
                        value:
                            '“${_quote.length > 22 ? '${_quote.substring(0, 22)}…' : _quote}”',
                        onTap: () async {
                          final q = await showClSheet<String>(
                            context: context,
                            builder: (sheet) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClSheetHeader(title: l10n.cdQuote),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: ClCardGroup(
                                      children: [
                                        for (final q in _quotes)
                                          ClOptionRow(
                                            title: q,
                                            selected: q == _quote,
                                            onTap: () =>
                                                Navigator.of(sheet).pop(q),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (q != null) setState(() => _quote = q);
                        },
                      ),
                      MeRow(
                        title: l10n.cdPhoto,
                        value: _photoId == null ? l10n.cdCover : '1',
                        onTap: () async {
                          final media = storyMedia(
                            ref,
                            widget.story.babyId,
                            true,
                          );
                          final choices = [
                            for (final id in widget.story.mediaIds)
                              if (media[id]?.effectiveAudience ==
                                  Audience.family)
                                media[id]!,
                          ];
                          final picked = await showClSheet<String>(
                            context: context,
                            builder: (sheet) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClSheetHeader(title: l10n.cdPhoto),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final m in choices)
                                      ClPressable(
                                        onPressed: () =>
                                            Navigator.of(sheet).pop(m.id),
                                        child: SizedBox(
                                          width: 76,
                                          height: 76,
                                          child: StoryImage(item: m, radius: 8),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                          if (picked != null) setState(() => _photoId = picked);
                        },
                      ),
                      MeRow(
                        title: l10n.cdShowAge,
                        trailing: ClToggle(
                          value: _showAge,
                          semanticLabel: l10n.cdShowAge,
                          onChanged: (v) => setState(() => _showAge = v),
                        ),
                      ),
                    ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
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
              title,
              textAlign: TextAlign.center,
              style: cl.text.headline,
            ),
          ),
          if (action != null)
            ClButton(
              label: action!,
              style: ClButtonStyle.plain,
              onPressed: onAction,
            )
          else
            const SizedBox(width: 72),
        ],
      ),
    );
  }
}

// ---------- 14k Liên kết xem riêng ----------

/// 14k: expiry, hide identity (on), downloads (off), passcode (off); "Sao chép & chia sẻ" creates
/// the link (so no unused links are left behind) and opens the OS share sheet.
class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({required this.story, super.key});
  final Story story;

  @override
  ConsumerState<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends ConsumerState<LinkScreen> {
  var _expiry = LinkExpiry.d7;
  var _hide = true;
  var _download = false;
  var _passcode = false;
  var _busy = false;
  CreatedLink? _link;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      final link =
          _link ??
          await ref
              .read(shareRepositoryProvider)
              .createLink(
                widget.story,
                expiry: _expiry,
                hideIdentity: _hide,
                allowDownload: _download,
                passcode: _passcode,
              );
      // The call is done: the spinner stops before the passcode and share sheets open.
      setState(() {
        _link = link;
        _busy = false;
      });
      // The passcode is shown once, before anything else (P-096).
      if (link.passcode != null && mounted) await _showPasscode(link.passcode!);
      unawaited(
        Clipboard.setData(ClipboardData(text: link.url)).then(
          (_) => toaster.show(message: l10n.lkCopied),
          onError: (Object _) => null,
        ),
      );
      await SharePlus.instance.share(
        ShareParams(text: '${widget.story.title}\n${link.url}'),
      );
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPasscode(String code) => showClSheet<void>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final cl = sheet.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.lkPasscodeTitle),
          Center(
            child: Text(
              code,
              style: cl.text.display.copyWith(
                letterSpacing: 12,
                color: cl.colors.ink,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.lkPasscodeBody,
            textAlign: TextAlign.center,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.lkCopy,
            expand: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (sheet.mounted) Navigator.of(sheet).pop();
            },
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final nick =
        ref.watch(babyProvider(widget.story.babyId)).value?.nickname ?? '';
    final url = _link?.url ?? 'childlife.app/s/…';
    final locked = _link != null;
    Widget toggle(
      String title,
      String hint,
      bool value,
      ValueChanged<bool> on,
    ) => MeRow(
      title: title,
      subtitle: hint,
      trailing: ClToggle(
        value: value,
        semanticLabel: title,
        onChanged: locked ? null : on,
      ),
    );
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: l10n.shLink),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ClSpace.s4),
                children: [
                  Container(
                    padding: const EdgeInsets.all(ClSpace.s3),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(ClRadius.control + 4),
                    ),
                    child: Row(
                      children: [
                        ClIcon(
                          ClIcons.link,
                          size: 18,
                          color: cl.colors.mintText,
                        ),
                        const SizedBox(width: ClSpace.s2),
                        Expanded(
                          child: Text(
                            url.replaceFirst(RegExp(r'^https?://'), ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.bodyStrong,
                          ),
                        ),
                        if (_link != null)
                          MeRowAction(
                            label: l10n.lkCopy,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _link!.url),
                              );
                              if (context.mounted) {
                                showClToast(context, message: l10n.lkCopied);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  MeSection(l10n.lkExpires),
                  ClSegmented<LinkExpiry>(
                    options: LinkExpiry.values,
                    selected: _expiry,
                    labelOf: (e) => switch (e) {
                      LinkExpiry.h24 => l10n.lk24h,
                      LinkExpiry.d7 => l10n.lk7d,
                      LinkExpiry.d30 => l10n.lk30d,
                    },
                    onChanged: (e) {
                      if (!locked) setState(() => _expiry = e);
                    },
                  ),
                  const SizedBox(height: ClSpace.s4),
                  ClCardGroup(
                    children: [
                      toggle(
                        l10n.lkHideIdentity,
                        l10n.lkHideIdentityHint(nick),
                        _hide,
                        (v) => setState(() => _hide = v),
                      ),
                      toggle(
                        l10n.lkDownload,
                        l10n.lkDownloadHint,
                        _download,
                        (v) => setState(() => _download = v),
                      ),
                      toggle(
                        l10n.lkPasscode,
                        l10n.lkPasscodeHint,
                        _passcode,
                        (v) => setState(() => _passcode = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s3),
                  MeNotice(
                    icon: ClIcons.eye,
                    title: l10n.lkNote,
                    body: l10n.lkScreenshotNote,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: ClButton(
                label: l10n.lkCopyShare,
                expand: true,
                onPressed: _create,
                loading: _busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 14m Đã chia sẻ ra ngoài ----------

/// 14m under Tôi: open links (views, time left, "Thu hồi"), saved cards (irrevocable), expired.
class SharedOutScreen extends ConsumerWidget {
  const SharedOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final rows =
        ref.watch(sharedOutProvider(me.uid)).value ?? const <SharedOut>[];
    final now = ref.read(timerClockProvider)();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final media = storyMedia(ref, me.babyId, true);
    final open = [
      for (final r in rows)
        if (r.openAt(now)) r,
    ];
    final cards = [
      for (final r in rows)
        if (r.kind == 'card') r,
    ];
    final closed = [
      for (final r in rows)
        if (r.kind == 'link' && !r.openAt(now)) r,
    ];
    String left(DateTime at) {
      final d = at.difference(now);
      return d.inHours >= 24
          ? l10n.soDays(d.inDays)
          : l10n.soHours(d.inHours.clamp(1, 23));
    }

    Widget thumb(SharedOut r) => SizedBox(
      width: 44,
      height: 44,
      child: StoryImage(item: media[r.coverMediaId], radius: 10),
    );

    return MePage(
      title: l10n.soTitle,
      children: [
        if (rows.isEmpty)
          Text(
            l10n.soEmpty,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        if (open.isNotEmpty) ...[
          MeSection(l10n.soOpen),
          ClCardGroup(
            children: [
              for (final r in open)
                MeRow(
                  leading: thumb(r),
                  title: r.title,
                  subtitle: l10n.soViewsLeftDays(r.views, left(r.expiresAt!)),
                  trailing: MeRowAction(
                    label: l10n.soRevoke,
                    destructive: true,
                    onPressed: () => _revoke(context, ref, r),
                  ),
                ),
            ],
          ),
        ],
        if (cards.isNotEmpty) ...[
          MeSection(l10n.soCards),
          ClCardGroup(
            children: [
              for (final r in cards)
                MeRow(
                  leading: thumb(r),
                  title: r.title,
                  subtitle: l10n.soCardRow,
                ),
            ],
          ),
        ],
        if (closed.isNotEmpty) ...[
          MeSection(l10n.soClosed),
          Opacity(
            opacity: 0.6,
            child: ClCardGroup(
              children: [
                for (final r in closed)
                  MeRow(
                    leading: thumb(r),
                    title: r.title,
                    subtitle: r.status == 'revoked'
                        ? l10n.soRevoked
                        : l10n.soExpiredOn(
                            DateFormat('d MMM', locale).format(r.expiresAt!),
                          ),
                    destructive: r.status != 'revoked',
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, SharedOut r) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.soRevokeTitle),
          Text(
            l10n.soRevokeBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.soRevoke,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final toaster = ClToaster.of(context);
    try {
      await ref.read(shareRepositoryProvider).revoke(r.token!);
      toaster.show(message: l10n.soRevoked);
    } on Object {
      toaster.show(message: l10n.toastActionFailed);
    }
  }
}
