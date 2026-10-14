import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import 'memory_models.dart';
import 'memory_repository.dart';
import 'memory_sheets.dart';
import 'quick_add.dart';
import 'upload_queue.dart';

/// 10k "Chia sẻ từ app Ảnh" (Figma 150:17772, R-117, D-046). The iOS share extension copies the
/// shared photos and videos into the App Group with a manifest; this side tells it which babies
/// the account may add memories to (Cùng nuôi only) and which strings to show (D-012), and moves
/// finished shares into the upload queue when the app opens. Nothing is uploaded from the
/// extension itself (native background transfer is SP-2).
///
/// Android (A4, Q-065) has no extension: a share opens the app, SharedInbox.kt copies the files
/// in with a manifest that has no baby yet, and the app asks here — the baby when there are
/// several, then "Soạn & chia sẻ" (10h) with its audience and notice.

@immutable
class SharedFile {
  const SharedFile({
    required this.file,
    required this.type,
    required this.name,
    required this.captureAt,
    this.width,
    this.height,
    this.durationMs,
  });

  factory SharedFile.fromJson(Map<String, Object?> j) => SharedFile(
    file: j['file']! as String,
    type: j['type'] == 'video' ? MediaKind.video : MediaKind.photo,
    name: j['name'] as String? ?? j['file']! as String,
    captureAt:
        DateTime.tryParse(j['captureAt'] as String? ?? '') ?? DateTime.now(),
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    durationMs: (j['durationMs'] as num?)?.toInt(),
  );

  final String file;
  final MediaKind type;
  final String name;
  final DateTime captureAt;
  final int? width;
  final int? height;
  final int? durationMs;
}

/// One "Thêm" from the extension.
@immutable
class SharedBatch {
  const SharedBatch({
    required this.id,
    required this.dir,
    required this.babyId,
    required this.audience,
    required this.notifyFamily,
    required this.items,
    this.skipped = 0,
  });

  factory SharedBatch.fromJson(Map<String, Object?> j) => SharedBatch(
    id: j['id']! as String,
    dir: j['dir']! as String,
    babyId: j['babyId'] as String?,
    audience: j['audience'] == 'parents' ? Audience.parents : Audience.family,
    notifyFamily: j['notifyFamily'] == true,
    items: [
      for (final i in (j['items'] as List? ?? const []))
        SharedFile.fromJson(Map<String, Object?>.from(i as Map)),
    ],
    skipped: (j['skipped'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String dir;

  /// Null on Android: chosen in the app ([offerSharedBatch]).
  final String? babyId;
  final Audience audience;
  final bool notifyFamily;
  final List<SharedFile> items;

  /// Items left out (over the per-add limit, or not a photo or video).
  final int skipped;

  List<PickedMedia> get picked => [
    for (final i in items)
      PickedMedia(
        file: File('$dir/${i.file}'),
        type: i.type,
        name: i.name,
        captureAt: i.captureAt,
        durationMs: i.durationMs,
        width: i.width,
        height: i.height,
      ),
  ];
}

/// The App Group as seen from Dart (iOS method channel; no share extension elsewhere yet).
abstract class ShareBridge {
  Future<void> setTargets(String json);
  Future<List<SharedBatch>> takeInbox();
  Future<void> finish(String id);
}

class ChannelShareBridge implements ShareBridge {
  static const _channel = MethodChannel('childlife/share');

  @override
  Future<void> setTargets(String json) =>
      _channel.invokeMethod<void>('setTargets', json);

  @override
  Future<List<SharedBatch>> takeInbox() async {
    final raw =
        await _channel.invokeListMethod<Object?>('takeInbox') ?? const [];
    final out = <SharedBatch>[];
    for (final r in raw) {
      try {
        out.add(SharedBatch.fromJson(Map<String, Object?>.from(r! as Map)));
      } on Object {
        // A manifest from another version: left for the 1-day cleanup.
      }
    }
    return out;
  }

  @override
  Future<void> finish(String id) => _channel.invokeMethod<void>('finish', id);
}

final shareBridgeProvider = Provider<ShareBridge?>(
  (ref) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => ChannelShareBridge(),
    _ => null,
  },
);

/// What the extension shows: Cùng nuôi babies, the last selected one, and its strings.
String shareTargetsJson({
  required bool signedIn,
  required List<(String, String)> babies,
  required String? lastBabyId,
  required int maxItems,
  required AppLocalizations l10n,
}) {
  // ICU plurals cannot cross to Swift, so each count is sent as "one" and "other" templates.
  String template(String Function(int) f, int n) =>
      f(n).replaceAll('$n', '{n}');
  return jsonEncode({
    'signedIn': signedIn,
    'babies': [
      for (final (id, nickname) in babies) {'id': id, 'nickname': nickname},
    ],
    'lastBabyId': lastBabyId,
    'maxItems': maxItems,
    'copy': {
      'title': l10n.shareExtTitle,
      'cancel': l10n.actionCancel,
      'add': l10n.shareExtAdd,
      'baby': l10n.shareExtBaby,
      'who': l10n.composeWho,
      'parents': l10n.audParents,
      'family': l10n.audFamily,
      'notify': l10n.composeNotify,
      'notifyHint': l10n.shareExtNotifyHint,
      'footnote': l10n.shareExtFootnote,
      'signedOut': l10n.shareExtSignedOut,
      'noBaby': l10n.shareExtNoBaby,
      'nothing': l10n.shareExtNothing,
      'close': l10n.shareExtClose,
      'photosOne': template(l10n.shareExtPhotos, 1),
      'photosOther': template(l10n.shareExtPhotos, 7),
      'videosOne': template(l10n.shareExtVideos, 1),
      'videosOther': template(l10n.shareExtVideos, 7),
    },
  });
}

/// Moves finished shares into the upload queue (the same request as 10h "Tải lên N mục", by
/// capture date, no caption / milestone / album). Shares for a baby the account can no longer
/// add to are dropped. Returns how many items were queued.
Future<int> importSharedBatches({
  required ShareBridge bridge,
  required Set<String> parentOf,
  required Future<void> Function({
    required String babyId,
    required Map<String, Object?> request,
    required List<PickedMedia> picked,
  })
  enqueue,
}) async {
  var queued = 0;
  for (final batch in await bridge.takeInbox()) {
    // Android: the baby is chosen in the app (offerSharedBatch).
    if (batch.babyId == null) continue;
    if (parentOf.contains(batch.babyId) && batch.items.isNotEmpty) {
      final family = batch.audience == Audience.family;
      await enqueue(
        babyId: batch.babyId!,
        request: {
          'babyId': batch.babyId,
          'memoryId': newMemoryId(),
          'batchId': newBatchId(),
          'caption': null,
          'audience': batch.audience.name,
          'notifyFamily': family && batch.notifyFamily,
          'dateMode': 'capture',
          'date': null,
          'milestone': null,
          'albumIds': const <String>[],
        },
        picked: batch.picked,
      );
      queued += batch.items.length;
    }
    // The queue has its own copies now (or the share is not allowed): remove the hand-off.
    await bridge.finish(batch.id);
  }
  return queued;
}

/// Android (Q-065): a share opened the app. Asks for the baby when the account adds memories to
/// several, opens Kỷ niệm and "Soạn & chia sẻ" (10h) with the shared items. False when it cannot
/// be shown yet (no screen at hand): the share waits for the next resume.
Future<bool> offerSharedBatch(
  WidgetRef ref,
  GoRouter router,
  SharedBatch batch,
) async {
  final context = contextInsideOverlay(router);
  final session = ref.read(sessionProvider);
  if (context == null || !context.mounted || session is! SessionSignedIn) {
    return false;
  }
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  final babies = [
    for (final m in session.active)
      if (m.role == MemberRole.coParent)
        (m.babyId, ref.read(babyProvider(m.babyId)).value?.nickname ?? ''),
  ];
  if (batch.items.isEmpty || babies.isEmpty) {
    toaster.show(
      message: babies.isEmpty ? l10n.shareExtNoBaby : l10n.shareExtNothing,
    );
    return true;
  }
  final max = ref.read(publicLimitsProvider).value?.mediaItemsPerAdd ?? 30;
  if (batch.skipped > 0 && batch.items.length >= max) {
    toaster.show(message: l10n.pickLimit(max));
  }
  final babyId = babies.length == 1
      ? babies.single.$1
      : await _chooseBaby(context, ref, batch, babies);
  if (babyId == null) return true;
  ref.read(selectedBabyIdProvider.notifier).select(babyId);
  router.go(Routes.memories);
  try {
    await ref
        .read(babyProvider(babyId).future)
        .timeout(const Duration(seconds: 3));
  } on Object {
    // Compose shows without the nickname.
  }
  await WidgetsBinding.instance.endOfFrame;
  final host = contextInsideOverlay(router);
  if (host == null || !host.mounted) return false;
  final c = memoryCtxNow(host, ref);
  if (c == null || !c.isParent) return true;
  await showComposeSheet(host, ref, c, batch.picked);
  return true;
}

/// "Thêm vào Kỷ niệm · Bé": which baby the shared items are for (the iOS extension's picker).
Future<String?> _chooseBaby(
  BuildContext context,
  WidgetRef ref,
  SharedBatch batch,
  List<(String, String)> babies,
) {
  final l10n = AppLocalizations.of(context);
  final cl = context.cl;
  final photos = batch.items.where((i) => i.type == MediaKind.photo).length;
  final videos = batch.items.length - photos;
  final current = ref.read(selectedBabyIdProvider);
  return showClSheet<String>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(
          title: l10n.shareExtTitle,
          onClose: () => Navigator.of(sheet).pop(),
        ),
        Text(
          [
            if (photos > 0) l10n.shareExtPhotos(photos),
            if (videos > 0) l10n.shareExtVideos(videos),
          ].join(' · '),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClSectionHeader(title: l10n.shareExtBaby),
        ClCardGroup(
          children: [
            for (final (id, nickname) in babies)
              ClOptionRow(
                title: nickname,
                selected: id == current,
                onTap: () => Navigator.of(sheet).pop(id),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Keeps the extension's targets current and drains the inbox on open and on resume.
class ShareInbox extends ConsumerStatefulWidget {
  const ShareInbox({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ShareInbox> createState() => _ShareInboxState();
}

class _ShareInboxState extends ConsumerState<ShareInbox>
    with WidgetsBindingObserver {
  String? _sentTargets;
  var _draining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Android: SharedInbox.kt says when a share's files are in (the app may already be open).
    if (defaultTargetPlatform == TargetPlatform.android) {
      const MethodChannel('childlife/share').setMethodCallHandler((call) async {
        if (call.method == 'received') unawaited(_drain());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_drain());
  }

  Set<String> _parentOf(Session session) => session is SessionSignedIn
      ? {
          for (final m in session.active)
            if (m.role == MemberRole.coParent) m.babyId,
        }
      : const {};

  Future<void> _drain() async {
    final bridge = ref.read(shareBridgeProvider);
    final session = ref.read(sessionProvider);
    if (bridge == null || _draining || session is! SessionSignedIn) return;
    _draining = true;
    try {
      final queue = ref.read(uploadQueueProvider.notifier);
      await importSharedBatches(
        bridge: bridge,
        parentOf: _parentOf(session),
        enqueue: queue.enqueue,
      );
      // Android: one share at a time, each through "Soạn & chia sẻ".
      for (final b in await bridge.takeInbox()) {
        if (b.babyId != null || !mounted) continue;
        if (!await offerSharedBatch(ref, ref.read(routerProvider), b)) break;
        await bridge.finish(b.id);
      }
    } on Object {
      // Tried again on the next resume.
    } finally {
      _draining = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(shareBridgeProvider);
    if (bridge != null) {
      final session = ref.watch(sessionProvider);
      ref.listen(sessionProvider, (_, next) {
        if (next is SessionSignedIn) unawaited(_drain());
      });
      if (session is! SessionLoading) {
        final parentOf = _parentOf(session);
        final babies = [
          for (final id in parentOf)
            (id, ref.watch(babyProvider(id)).value?.nickname ?? ''),
        ]..removeWhere((b) => b.$2.isEmpty);
        final json = shareTargetsJson(
          signedIn: session is SessionSignedIn,
          babies: babies,
          lastBabyId: ref.watch(selectedBabyIdProvider),
          maxItems:
              ref.watch(publicLimitsProvider).value?.mediaItemsPerAdd ?? 30,
          l10n: AppLocalizations.of(context),
        );
        if (json != _sentTargets) {
          _sentTargets = json;
          unawaited(bridge.setTargets(json).catchError((Object _) {}));
        }
      }
    }
    return widget.child;
  }
}
