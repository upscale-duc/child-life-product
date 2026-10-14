import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/environment.dart';
import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../me/me_widgets.dart';
import '../memories/memories_screen.dart' show memoryCtx, openUploads;
import '../memories/memory_sheets.dart' show showAddSheet;
import '../memories/upload_queue.dart';
import 'auto_save_controller.dart';
import 'auto_save_engine.dart' show SuggestionGroup;
import 'auto_save_native.dart';
import 'auto_save_setup.dart';
import 'auto_save_widgets.dart';

/// `/memories/auto-save`: the AS02 intro until set up, then the feature home (AS06, AS12 – AS17).
class AutoSaveHomeScreen extends ConsumerWidget {
  const AutoSaveHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(autoSaveProvider);
    if (!view.loaded) {
      return Scaffold(
        backgroundColor: context.cl.colors.cloud,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!view.state.consented) return const AutoSaveIntro();
    return const _Home();
  }
}

class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(autoSaveProvider);
    final s = view.state;
    final now = DateTime.now();
    final c = ref.read(autoSaveProvider.notifier);
    String name(String id) => ref.watch(babyProvider(id)).value?.nickname ?? '';
    final ready = [
      for (final e in s.babies.entries)
        if (e.value.samples.isNotEmpty) e.key,
    ];
    final noSamples = [
      for (final e in s.babies.entries)
        if (e.value.samples.isEmpty) e.key,
    ];
    final names = joinNames(l10n, [for (final id in ready) name(id)]);
    final pending = view.pendingFor();
    final queue = ref.watch(uploadQueueProvider);
    final uploading = queue.batches
        .expand((b) => b.items)
        .where(
          (i) =>
              i.state != QueueState.uploaded &&
              i.state != QueueState.unreadable &&
              i.state != QueueState.cancelled,
        )
        .length;
    final month = DateFormat(
      'MMMM',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(now);
    final scan = view.scan;
    final last = s.lastScanAt;

    final status = <Widget>[];
    if (!s.enabled) {
      status.add(
        MeNotice(
          icon: ClIcons.sliders,
          title: l10n.autoSaveOffTitle,
          body: l10n.autoSaveOffBody,
          onTap: () => context.push(Routes.autoSaveSettings),
        ),
      );
    } else if (view.access == LibraryAccess.denied ||
        view.access == LibraryAccess.notDetermined) {
      // AS14: paused, not off; only iOS Settings can grant it again.
      status.add(
        MeNotice(
          tone: MeTone.error,
          icon: ClIcons.lock,
          title: l10n.autoSaveDeniedTitle,
          body: l10n.autoSaveDeniedBody,
          child: ClButton(
            label: l10n.autoSaveOpenSettings,
            expand: true,
            onPressed: () => unawaited(
              view.access == LibraryAccess.notDetermined
                  ? c.requestAccess()
                  : ref.read(autoSaveNativeProvider).openSettings(),
            ),
          ),
        ),
      );
    } else if (scan != null) {
      // AS06 (first check) / AS17: scan progress, kept apart from upload progress.
      status.add(
        AutoSaveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(icon: ClIcons.search, text: l10n.autoSaveChecking),
              const SizedBox(height: ClSpace.s1),
              Text(
                (last == null
                    ? l10n.autoSaveCheckingFirst
                    : l10n.autoSaveCheckingProgress)(
                  NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(scan.checked),
                  NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(scan.total),
                ),
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(height: ClSpace.s2),
              ClProgress(value: scan.value),
              const SizedBox(height: ClSpace.s2),
              Text(
                last == null
                    ? l10n.autoSaveCheckingPause
                    : l10n.autoSaveCheckingSeparate,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      );
    } else if (view.access == LibraryAccess.limited) {
      // AS13: a normal state, limited to the photos the parent shared.
      status.add(
        MeNotice(
          tone: MeTone.warn,
          icon: ClIcons.lock,
          title: l10n.autoSaveLimitedTitle,
          body: [
            l10n.autoSaveLimitedBody,
            if (last != null) checkedAt(context, last, now),
          ].join(' · '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClButton(
                label: l10n.autoSavePickMore,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => unawaited(c.pickMore()),
              ),
              ClButton(
                label: l10n.autoSaveAllowAll,
                style: ClButtonStyle.plain,
                onPressed: () =>
                    unawaited(ref.read(autoSaveNativeProvider).openSettings()),
              ),
            ],
          ),
        ),
      );
    } else if (pending == 0 && last != null && ready.isNotEmpty) {
      // AS16 (483:7315): a calm empty result. A white card like AS12, so the secondary
      // "Kiểm tra ảnh mới" keeps its fill (on a surface-2 notice it vanished).
      status.add(
        AutoSaveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cl.colors.mintSoft,
                      borderRadius: BorderRadius.circular(ClRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: ClIcon(
                      ClIcons.check,
                      size: 18,
                      color: cl.colors.mintText,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.autoSaveNothingTitle(names),
                          style: cl.text.bodyStrong,
                        ),
                        Text(
                          l10n.autoSaveNothingBody(
                            s.lastScanCount,
                            checkedAt(context, last, now),
                          ),
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              ClButton(
                label: l10n.autoSaveCheckNow,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => unawaited(c.scan()),
              ),
            ],
          ),
        ),
      );
    } else if (ready.isNotEmpty) {
      // AS12
      status.add(
        AutoSaveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(
                icon: ClIcons.search,
                text: last == null
                    ? l10n.autoSaveNotYet
                    : l10n.autoSaveLastCheck(checkedAt(context, last, now)),
              ),
              if (last != null)
                Text(
                  l10n.autoSaveNewFiles(s.lastScanCount, names),
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              const SizedBox(height: ClSpace.s3),
              ClButton(
                label: l10n.autoSaveCheckNow,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => unawaited(c.scan()),
              ),
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.autoSaveWhen,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      );
    }

    return AutoSavePage(
      title: l10n.autoSaveTitle,
      beta: true,
      trailing: ClRoundButton(
        icon: ClIcons.sliders,
        semanticLabel: l10n.autoSaveSettingsTitle,
        onPressed: () => context.push(Routes.autoSaveSettings),
      ),
      onRefresh: s.enabled ? c.scan : null,
      children: [
        ...status,
        // AS15: a baby turned on without samples is paused until it has some.
        for (final id in noSamples)
          if (s.enabled)
            MeNotice(
              tone: MeTone.warn,
              icon: ClIcons.camera,
              title: l10n.autoSaveNoSamplesTitle(name(id)),
              body: l10n.autoSaveNoSamplesBody(name(id)),
              child: ClButton(
                label: l10n.autoSaveAddSamples,
                expand: true,
                onPressed: () => context.push('${Routes.autoSaveSamples}/$id'),
              ),
            ),
        if (pending > 0) ...[
          if (noSamples.isNotEmpty && s.enabled)
            const SizedBox(height: ClSpace.s3),
          AutoSaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scan != null && last == null) ...[
                  _Title(
                    icon: ClIcons.spark,
                    text: l10n.autoSaveFound(pending),
                  ),
                  Text(
                    l10n.autoSaveFoundHint,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ] else
                  _Title(
                    icon: ClIcons.spark,
                    text: scan != null
                        ? l10n.autoSavePendingMore(pending)
                        : l10n.autoSavePending(pending),
                  ),
                const SizedBox(height: ClSpace.s3),
                _Thumbs(groups: view.groups(), total: pending),
                const SizedBox(height: ClSpace.s3),
                ClButton(
                  label: scan != null && last == null
                      ? l10n.autoSaveSeeFound(pending)
                      : l10n.autoSaveReview,
                  expand: true,
                  onPressed: () => context.push(Routes.autoSaveReview),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            if (uploading > 0)
              MeRow(
                icon: ClIcons.upload,
                title: l10n.autoSaveUploadingRow,
                value: l10n.autoSaveUploadingValue(uploading),
                onTap: () {
                  final mc = memoryCtx(context, ref);
                  if (mc != null) openUploads(context, ref, mc);
                },
              ),
            MeRow(
              icon: ClIcons.check,
              title: l10n.autoSaveSavedRow,
              value: l10n.autoSaveSavedValue(view.savedIn(now), month),
            ),
            MeRow(
              icon: ClIcons.plus,
              title: l10n.autoSaveManual,
              subtitle: l10n.autoSaveManualHint,
              onTap: () {
                final mc = memoryCtx(context, ref);
                if (mc != null) unawaited(showAddSheet(context, ref, mc));
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// AS12's strip: the best of the first groups; when more wait, the last tile says "+n" (owner,
/// 2026-10-14), n counting the suggestions not shown.
class _Thumbs extends StatelessWidget {
  const _Thumbs({required this.groups, required this.total});
  final List<SuggestionGroup> groups;
  final int total;

  static const _max = 5;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final more = groups.length > _max;
    final shown = groups.take(more ? _max - 1 : _max).toList();
    final rest = total - shown.fold<int>(0, (n, g) => n + g.items.length);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (final g in shown)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox.square(
                dimension: 56,
                child: LibraryTile(
                  assetId: g.best.asset.id,
                  video: g.best.asset.video,
                ),
              ),
            ),
          if (more && rest > 0)
            SizedBox.square(
              dimension: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryTile(assetId: groups[_max - 1].best.asset.id),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '+$rest',
                        style: cl.text.bodyStrong.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.icon, required this.text});
  final ClIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        ClIcon(icon, size: 18, color: cl.colors.mintText),
        const SizedBox(width: ClSpace.s2),
        Expanded(child: Text(text, style: cl.text.bodyStrong)),
      ],
    );
  }
}

// ---------- AS19 Cài đặt Tự lưu ----------

class AutoSaveSettingsScreen extends ConsumerWidget {
  const AutoSaveSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(autoSaveProvider);
    final s = view.state;
    final c = ref.read(autoSaveProvider.notifier);
    final now = DateTime.now();
    final session = ref.watch(sessionProvider);
    final parentOf = session is SessionSignedIn
        ? [
            for (final m in session.active)
              if (m.role == MemberRole.coParent) m.babyId,
          ]
        : const <String>[];
    final addable = [
      for (final id in parentOf)
        if (!s.babies.containsKey(id)) id,
    ];
    final last = s.lastScanAt;
    return AutoSavePage(
      title: l10n.autoSaveSettingsTitle,
      children: [
        ClCardGroup(
          children: [
            ClSettingRow(
              icon: ClIcons.spark,
              title: l10n.autoSaveTitle,
              subtitle: s.enabled ? l10n.autoSaveOnBeta : l10n.autoSaveOffValue,
              value: s.enabled,
              onChanged: (on) => unawaited(c.setEnabled(on)),
            ),
          ],
        ),
        MeSection(l10n.autoSaveLookIn),
        ClCardGroup(
          children: [
            ClSettingRow(
              icon: ClIcons.memories,
              title: l10n.autoSavePhotos,
              value: s.photos,
              onChanged: (on) => unawaited(c.setKinds(photos: on)),
            ),
            ClSettingRow(
              icon: ClIcons.camera,
              title: l10n.autoSaveVideos,
              subtitle: l10n.autoSaveVideosHint,
              value: s.videos,
              onChanged: (on) => unawaited(c.setKinds(videos: on)),
            ),
            // Q-056 proposal: the app-wide video rule, as for manual uploads.
            ClSettingRow(
              icon: ClIcons.upload,
              title: l10n.autoSaveWifi,
              subtitle: l10n.autoSaveWifiHint,
              value: ref.watch(videoWifiOnlyProvider),
              onChanged: (on) =>
                  ref.read(videoWifiOnlyProvider.notifier).set(on),
            ),
            ClSettingRow(
              icon: ClIcons.bell,
              title: l10n.autoSaveNotifyNew,
              subtitle: l10n.autoSaveNotifyNewHint,
              value: s.notify,
              onChanged: (on) => unawaited(c.setNotify(on)),
            ),
          ],
        ),
        MeSection(l10n.autoSaveBabies),
        ClCardGroup(
          children: [
            for (final e in s.babies.entries)
              MeRow(
                title: ref.watch(babyProvider(e.key)).value?.nickname ?? '',
                subtitle: e.value.samples.isEmpty
                    ? l10n.autoSaveSamplesNone
                    : l10n.autoSaveSamplesOn(e.value.picked.length),
                onTap: () => context.push('${Routes.autoSaveSamples}/${e.key}'),
              ),
            for (final id in addable)
              MeRow(
                icon: ClIcons.plus,
                title:
                    '${l10n.autoSaveAddBaby} · ${ref.watch(babyProvider(id)).value?.nickname ?? ''}',
                onTap: () async {
                  await c.addBaby(id);
                  if (context.mounted) {
                    unawaited(context.push('${Routes.autoSaveSamples}/$id'));
                  }
                },
              ),
          ],
        ),
        MeSection(l10n.autoSaveLastStatus),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.autoSaveCheckRow,
              subtitle: last == null
                  ? l10n.autoSaveNotYet
                  : l10n.autoSaveCheckValue(
                      checkedAt(context, last, now),
                      s.lastScanCount,
                      view.pendingFor(),
                    ),
            ),
            MeRow(
              title: l10n.autoSavePermission,
              value: switch (view.access) {
                LibraryAccess.full => l10n.autoSaveAccessFull,
                LibraryAccess.limited => l10n.autoSaveAccessLimited,
                _ => l10n.autoSaveAccessDenied,
              },
              onTap: () =>
                  unawaited(ref.read(autoSaveNativeProvider).openSettings()),
            ),
          ],
        ),
        // Dev builds only: why each item of the last checks was or was not suggested.
        if (ref.watch(environmentProvider) == AppEnvironment.dev)
          const _Diagnostics(),
        const SizedBox(height: ClSpace.s4),
        MeNotice(
          icon: ClIcons.lock,
          title: l10n.autoSaveOffNote,
          body: l10n.autoSaveOnDevice,
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.autoSaveWhatKept,
              onTap: () => showWhatKeptSheet(context),
            ),
            MeRow(
              title: l10n.autoSaveWipe,
              destructive: true,
              onTap: () => unawaited(_confirmWipe(context, ref)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.autoSaveWipe),
            Text(
              l10n.autoSaveWipeBody,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.autoSaveWipeAction,
              style: ClButtonStyle.destructive,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ref.read(autoSaveProvider.notifier).wipe();
    toaster.show(message: l10n.autoSaveWiped);
    if (context.mounted) context.go(Routes.memories);
  }
}

class _Diagnostics extends ConsumerWidget {
  const _Diagnostics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(autoSaveProvider);
    String n(double? x) => x == null ? '–' : x.toStringAsFixed(3);
    String why(AutoSaveTrace t) => switch (t.reason) {
      'match' => l10n.autoSaveDiagMatch(n(t.distance), n(t.threshold)),
      'far' => l10n.autoSaveDiagFar(n(t.distance), n(t.threshold)),
      'negative' => l10n.autoSaveDiagNegative,
      'noFace' => l10n.autoSaveDiagNoFace,
      'small' => l10n.autoSaveDiagSmall,
      'utility' => l10n.autoSaveDiagUtility,
      'unreadable' => l10n.autoSaveDiagUnreadable,
      _ => l10n.autoSaveDiagHandled,
    };
    final how = view.fromHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeSection(l10n.autoSaveDiagTitle),
        AutoSaveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                how == null
                    ? l10n.autoSaveDiagNone
                    : l10n.autoSaveDiagHow(
                        how
                            ? l10n.autoSaveDiagHistory
                            : l10n.autoSaveDiagByDate,
                        view.state.lastScanCount,
                      ),
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              for (final t in view.trace)
                Padding(
                  padding: const EdgeInsets.only(top: ClSpace.s2),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 40,
                        child: LibraryTile(
                          assetId: t.assetId,
                          video: t.video,
                          radius: 6,
                        ),
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Text(
                          why(t),
                          style: cl.text.label.copyWith(
                            color: t.reason == 'match'
                                ? cl.colors.mintText
                                : cl.colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: ClSpace.s3),
              ClButton(
                label: l10n.autoSaveDiagRescan,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: view.scan != null
                    ? null
                    : () => unawaited(
                        ref.read(autoSaveProvider.notifier).rescan(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
