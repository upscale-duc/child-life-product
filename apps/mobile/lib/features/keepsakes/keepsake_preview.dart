import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../memories/media_bytes.dart';
import '../memories/viewer_video.dart' show streamingPlayer;
import 'keepsake_catalog.dart';
import 'milestone_card_screens.dart' show KeepsakeRoundIcon;

/// Video kỷ niệm previews (D-068): the renderer's own compositions played on the phone in a
/// WebView (`apps/renderer/player`, served from the environment's player site), so what parents
/// see is what the server renders, without a render and without a release when a composition is
/// added. A template's demo uses the page's sample pictures (illustrations); the personal preview
/// passes the chosen photos as data URLs: they never leave the phone. A template with a real
/// preview video made in the portal (licensed sample photos) plays that instead.

@immutable
class KeepsakePreviewRequest {
  const KeepsakePreviewRequest({
    required this.composition,
    required this.props,
    this.startFrame = 0,
    this.videoUrl,
    this.title,
    this.info,
    this.onUse,
  });
  final String composition;

  /// Picking a template (owner, 2026-10-14: "ấn vào là sang màn hình play luôn"): its name in
  /// the top bar, what it needs under the player, and "Dùng mẫu này" (the player closes first).
  final String? title;
  final String? info;
  final VoidCallback? onUse;

  KeepsakePreviewRequest withUse({
    required String title,
    required String info,
    required VoidCallback onUse,
  }) => KeepsakePreviewRequest(
    composition: composition,
    props: props,
    startFrame: startFrame,
    videoUrl: videoUrl,
    title: title,
    info: info,
    onUse: onUse,
  );

  /// "Xem mẫu" of a template with a portal-made `.mp4`: played as is, no WebView.
  final String? videoUrl;

  /// `MemoryStoryProps` of the renderer.
  final Map<String, Object?> props;
  final int startFrame;

  String toJson() => jsonEncode({
    'composition': composition,
    'props': props,
    'startFrame': startFrame,
  });
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The public URL of a template asset (artwork and music, never child media).
String keepsakeAssetUrl(String asset) {
  try {
    final bucket = FirebaseStorage.instance.bucket;
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        '${Uri.encodeComponent(keepsakeAssetPath(asset))}?alt=media';
  } on Object {
    return '';
  }
}

Map<String, Object?> _baseProps(
  KeepsakeTemplate t, {
  required List<String> photos,
  required String title,
  required String message,
  required String name,
  required String dateLine,
  required String? mark,
  required String? music,
  Map<String, String> extra = const {},
  String locale = 'vi',
  List<String?> labels = const [],
}) => {
  'photos': photos,
  'title': title,
  'message': message,
  // Chapter 01 (E-8 / E-9): the template's extra texts, the language and the photos' ages.
  ...extra,
  'locale': locale,
  'photoInfo': [
    for (final l in labels) {'takenAt': null, 'label': l},
  ],
  'name': name,
  'dateLine': dateLine,
  'mark': mark,
  'palette': {
    'background': _hex(t.palette.background),
    'ink': _hex(t.palette.ink),
    'accent': _hex(t.palette.accent),
  },
  'music': music == null ? null : keepsakeAssetUrl(music),
  'durationSec': t.durationSec ?? 30,
  // The same logo the render will have (D-068 #10).
  'brand': t.brand?.toJson(),
};

/// The track a video plays: the parent's pick, else the template's default from Thư viện nhạc,
/// else the template's own upload (Q-062).
String? keepsakeMusicAsset(KeepsakeTemplate t, KeepsakeMusic? track) =>
    track?.asset ?? t.musicAsset;

/// "Xem mẫu": the portal's preview video, else the template with sample pictures and the
/// baby's name.
KeepsakePreviewRequest demoPreview(
  KeepsakeTemplate t, {
  required String name,
  required Locale locale,
  String? mark,
  KeepsakeMusic? track,
}) => KeepsakePreviewRequest(
  videoUrl: t.preview == null ? null : keepsakeAssetUrl(t.preview!),
  composition: t.composition ?? 'LittleMoments',
  props: _baseProps(
    t,
    photos: [for (var i = 0; i < t.photosMax; i++) '/samples/${i % 6 + 1}.jpg'],
    title: (t.text('title')?.defaultText.of(locale) ?? '').replaceAll(
      '{name}',
      name,
    ),
    message: (t.text('message')?.defaultText.of(locale) ?? '').replaceAll(
      '{name}',
      name,
    ),
    name: name,
    dateLine: '',
    mark: mark,
    music: keepsakeMusicAsset(t, track),
    extra: {
      for (final key in const ['headline', 'lines', 'letter', 'closing'])
        if (t.text(key) case final own?)
          key: own.defaultText.of(locale).replaceAll('{name}', name),
    },
    locale: locale.languageCode,
  ),
);

/// MM07 "Xem trước": the parent's photos (thumbnails, as data URLs) and texts.
Future<KeepsakePreviewRequest> personalPreview(
  KeepsakeTemplate t, {
  required List<String> photoPaths,
  required String title,
  required String message,
  required String name,
  required String dateLine,
  required String? mark,
  required String? music,
  Map<String, String> extra = const {},
  String locale = 'vi',
  List<String?> labels = const [],
}) async {
  final photos = <String>[];
  for (final p in photoPaths) {
    try {
      photos.add(
        'data:image/jpeg;base64,${base64Encode(await mediaBytes.read(p))}',
      );
    } on Object {
      // A photo that cannot be read is left out of the preview only.
    }
  }
  return KeepsakePreviewRequest(
    composition: t.composition ?? 'LittleMoments',
    props: _baseProps(
      t,
      photos: photos,
      title: title,
      message: message,
      name: name,
      dateLine: dateLine,
      mark: mark,
      music: music,
      extra: extra,
      locale: locale,
      labels: labels,
    ),
  );
}

typedef KeepsakePreviewLauncher =
    Future<void> Function(BuildContext context, KeepsakePreviewRequest request);

/// Opens the preview; tests replace it (no WebView in widget tests).
final keepsakePreviewLauncherProvider = Provider<KeepsakePreviewLauncher>((
  ref,
) {
  final origin = ref.watch(environmentProvider).keepsakePlayerOrigin;
  return (context, request) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => KeepsakePreviewScreen(origin: origin, request: request),
    ),
  );
});

class KeepsakePreviewScreen extends StatefulWidget {
  const KeepsakePreviewScreen({
    required this.origin,
    required this.request,
    super.key,
  });
  final String origin;
  final KeepsakePreviewRequest request;

  @override
  State<KeepsakePreviewScreen> createState() => _PreviewState();
}

class _PreviewState extends State<KeepsakePreviewScreen> {
  WebViewController? _web;
  Player? _player;
  VideoController? _video;
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.request.videoUrl case final url?) {
      final player = _player = streamingPlayer();
      _video = VideoController(player);
      player.stream.error.listen((_) {
        if (mounted) setState(() => _failed = true);
      });
      // The spinner while it waits for data: at the start and after a stall.
      player.stream.playing.listen((p) {
        if (p && mounted && _loading) setState(() => _loading = false);
      });
      player.stream.buffering.listen((b) {
        if (mounted && b != _loading) setState(() => _loading = b);
      });
      unawaited(player.setPlaylistMode(PlaylistMode.single));
      unawaited(player.open(Media(url)));
      return;
    }
    final web = _web = WebViewController();
    web
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1517))
      ..addJavaScriptChannel(
        'ChildLifePreview',
        onMessageReceived: (m) async {
          if (m.message != 'ready') return;
          await web.runJavaScript(
            'window.childLifePreview(${widget.request.toJson()})',
          );
          if (mounted) setState(() => _loading = false);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) {
              if (mounted) setState(() => _failed = true);
            }
          },
          // Only the player page itself; nothing else opens in here.
          onNavigationRequest: (r) => r.url.startsWith(widget.origin)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(Uri.parse('${widget.origin}/'));
  }

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1517),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: Row(
                children: [
                  KeepsakeRoundIcon(
                    icon: ClIcons.close,
                    label: l10n.a11yClose,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Text(
                      widget.request.title ?? l10n.ksPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.headline.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_video case final video?)
                          Video(
                            controller: video,
                            fill: const Color(0xFF000000),
                          )
                        else
                          WebViewWidget(controller: _web!),
                        if (_loading && !_failed)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        if (_failed)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(ClSpace.s6),
                              child: Text(
                                l10n.ksPreviewFailed,
                                textAlign: TextAlign.center,
                                style: cl.text.body.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.request.info case final info?) ...[
                    Text(
                      info,
                      textAlign: TextAlign.center,
                      style: cl.text.label.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: ClSpace.s1),
                  ],
                  Text(
                    widget.request.videoUrl != null
                        ? l10n.ksPreviewVideoNote
                        : l10n.ksPreviewNote,
                    textAlign: TextAlign.center,
                    style: cl.text.caption.copyWith(color: Colors.white60),
                  ),
                  if (widget.request.onUse case final use?) ...[
                    const SizedBox(height: ClSpace.s3),
                    ClButton(
                      label: l10n.ksUseTemplate,
                      expand: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        use();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
