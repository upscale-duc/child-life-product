import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../memories/media_viewer.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import '../memories/upload_queue.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_widgets.dart';

/// Items held on this device for quota ("3 mục mới được giữ trên máy", 13d).
int heldForQuota(WidgetRef ref) => [
  for (final b in ref.watch(uploadQueueProvider).batches)
    for (final i in b.items)
      if (i.state == QueueState.waitingQuota) i,
].length;

/// 13b / 13c / 13d "Dung lượng" for any Cùng nuôi (P-003).
class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final async = ref.watch(familyStorageProvider(me.babyId));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final held = heldForQuota(ref);
    Future<void> refresh() =>
        ref.refresh(familyStorageProvider(me.babyId).future).then((_) {});

    final s = async.value;
    if (s == null) {
      return MePage(
        title: l10n.meStorage,
        onRefresh: refresh,
        children: [
          if (async.hasError)
            ClEmptyState(
              icon: ClIcons.cloudOff,
              title: l10n.meStorage,
              message: l10n.stLoadFailed,
            )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final tints = babySoftTints(context);
    final full = s.state == StorageState.full;
    final quota = formatBytes(s.quotaBytes, locale);
    return MePage(
      title: l10n.meStorage,
      onRefresh: refresh,
      children: [
        Semantics(
          label: l10n.meStorageOf(formatBytes(s.usedBytes, locale), quota),
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatBytes(s.usedBytes, locale),
                style: cl.text.largeTitle.copyWith(
                  fontSize: 40,
                  color: full ? cl.colors.error : cl.colors.ink,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Text(
                l10n.stOfQuota(quota),
                style: cl.text.headline.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        StorageBar(
          segments: [for (final b in s.babies) b.bytes],
          quota: s.quotaBytes,
          full: full,
          height: 12,
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.stFootnote,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        if (s.state == StorageState.nearFull) ...[
          const SizedBox(height: ClSpace.s4),
          MeNotice(
            tone: MeTone.warn,
            icon: ClIcons.alert,
            title: l10n.stNearTitle(s.percent),
            body: l10n.stNearBody,
          ),
        ],
        if (full) ...[
          const SizedBox(height: ClSpace.s4),
          MeNotice(
            tone: MeTone.error,
            icon: ClIcons.cloudOff,
            title: l10n.stFullTitle(quota),
            body: held > 0 ? l10n.stFullBody(held) : l10n.stFullBodyNone,
          ),
        ],
        MeSection(l10n.stByBaby),
        ClCardGroup(
          children: [
            for (final (i, b) in s.babies.indexed)
              MeRow(
                icon: ClIcons.cake,
                iconTint: tints[i % tints.length],
                title: b.nickname,
                subtitle: l10n.stCounts(b.photos, b.videos),
                value: formatBytes(b.bytes, locale),
                onTap: () => context.push('${Routes.meBabies}/${b.babyId}'),
              ),
          ],
        ),
        MeSection(l10n.stByType),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.stVideo,
              subtitle: l10n.stVideoHint,
              value: formatBytes(s.videoBytes, locale),
              onTap: () => context.push(Routes.meVideos),
            ),
            MeRow(
              title: l10n.stPhotos,
              value: formatBytes(s.photoBytes, locale),
            ),
            MeRow(
              title: l10n.stNotes,
              value: formatBytes(s.notesBytes, locale),
            ),
            if (s.binBytes > 0)
              MeRow(
                title: l10n.stBin,
                subtitle: l10n.stBinHint,
                value: formatBytes(s.binBytes, locale),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        MeNotice(
          title: l10n.stNeedMore,
          body: l10n.stNeedMoreBody(quota),
          child: s.openRequestGb != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stRequested(
                        s.openRequestGb!,
                        DateFormat.MMMd(locale).format(s.openRequestAt!),
                      ),
                      style: cl.text.bodyStrong.copyWith(
                        color: cl.colors.mintText,
                      ),
                    ),
                    Text(
                      l10n.stRequestedHint,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ],
                )
              : ClButton(
                  label: l10n.stContact,
                  style: full ? ClButtonStyle.primary : ClButtonStyle.secondary,
                  expand: true,
                  onPressed: () =>
                      showStorageRequestSheet(context, me.babyId, s),
                ),
        ),
      ],
    );
  }
}

/// 13e "Xin thêm dung lượng": +10 GB / +20 GB (D-010), message, email and usage attached.
Future<void> showStorageRequestSheet(
  BuildContext context,
  String babyId,
  FamilyStorage storage,
) => showClSheet<void>(
  context: context,
  builder: (_) => _RequestSheet(babyId: babyId, storage: storage),
);

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({required this.babyId, required this.storage});
  final String babyId;
  final FamilyStorage storage;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _message = TextEditingController();
  var _amount = 10;
  var _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(meRepositoryProvider)
          .requestStorage(widget.babyId, _amount, _message.text);
      ref.invalidate(familyStorageProvider(widget.babyId));
      navigator.pop();
      toaster.show(message: l10n.stReqSent);
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final session = ref.watch(sessionProvider);
    final email = session is SessionSignedIn ? session.user.email ?? '' : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.stReqTitle),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.stReqHow, style: cl.text.bodyStrong),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s2,
                  children: [
                    for (final gb in const [10, 20])
                      ClFilterChip(
                        label: '+$gb GB',
                        selected: _amount == gb,
                        onTap: () => setState(() => _amount = gb),
                      ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
                ClTextField(
                  label: l10n.stReqMessage,
                  placeholder: l10n.stReqMessage,
                  standalone: true,
                  controller: _message,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: ClSpace.s3),
                if (email.isEmpty)
                  MeNotice(tone: MeTone.warn, title: l10n.needEmailAccount)
                else
                  MeNotice(
                    title: l10n.stReqAttach(
                      email,
                      formatBytes(widget.storage.usedBytes, locale),
                      formatBytes(widget.storage.quotaBytes, locale),
                    ),
                  ),
                const SizedBox(height: ClSpace.s4),
                ClButton(
                  label: l10n.stReqSend,
                  expand: true,
                  onPressed: _busy || email.isEmpty ? null : _send,
                  loading: _busy,
                ),
                const SizedBox(height: ClSpace.s3),
                Text(
                  l10n.stReqFootnote,
                  textAlign: TextAlign.center,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Xem video lớn nhất" (G-058): the family's largest videos, opened in the viewer.
class LargestVideosScreen extends ConsumerWidget {
  const LargestVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final videos =
        ref.watch(familyStorageProvider(me.babyId)).value?.largestVideos ??
        const <LargeVideo>[];
    final byBaby = <String, Map<String, MediaItem>>{};
    for (final b in {for (final v in videos) v.babyId}) {
      byBaby[b] = {
        for (final m
            in ref.watch(mediaProvider((b, true))).value ?? const <MediaItem>[])
          m.id: m,
      };
    }
    final items = [
      for (final v in videos)
        if (byBaby[v.babyId]?[v.mediaId] case final m?) (v, m),
    ];
    return MePage(
      title: l10n.stVideosTitle,
      children: [
        Text(
          l10n.stVideosHint,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        if (items.isEmpty)
          ClEmptyState(
            icon: ClIcons.memories,
            title: l10n.stVideosTitle,
            message: l10n.stVideosEmpty,
          )
        else
          ClCardGroup(
            children: [
              for (final (i, (v, m)) in items.indexed)
                MeRow(
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: MediaTile(item: m, radius: 10),
                  ),
                  title: formatBytes(v.bytes, locale),
                  subtitle:
                      '${videoDuration(v.durationMs)} · ${DateFormat.yMMMd(locale).format(v.captureAt.toLocal())}',
                  onTap: () => openViewer(
                    context,
                    items: [for (final (_, x) in items) x],
                    start: i,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
