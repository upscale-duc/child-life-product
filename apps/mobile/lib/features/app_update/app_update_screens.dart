import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../me/me_widgets.dart';
import '../memories/upload_queue.dart';
import 'app_update_models.dart';
import 'app_update_repository.dart';

/// Opens the store page, or says it could not.
Future<void> openStore(BuildContext context, WidgetRef ref, Uri? url) async {
  final l10n = AppLocalizations.of(context);
  final toaster = ClToaster.of(context);
  try {
    if (url == null) throw StateError('no store link');
    await ref.read(openStoreProvider)(url);
  } on Object {
    toaster.show(message: l10n.upNoStore);
  }
}

// ---------- UP1 · Bắt buộc cập nhật ----------

/// Wraps the whole app (D-061): below the oldest allowed version only UP1 shows, offline too
/// (the last config is cached). Its own navigator lets "Có gì mới trong …" open the pages.
class AppUpdateGate extends ConsumerWidget {
  const AppUpdateGate({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appUpdateStatusProvider);
    if (status is! UpdateRequired) return child;
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => UpdateRequiredScreen(status: status),
      ),
    );
  }
}

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({required this.status, super.key});
  final UpdateRequired status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final release = ref.watch(appUpdateConfigProvider).value?.release;
    final notes =
        release != null &&
            release.version == status.latest &&
            release.pages.isNotEmpty
        ? release
        : null;
    final pending = [
      for (final b in ref.watch(uploadQueueProvider).batches)
        for (final i in b.items)
          if (!{
            QueueState.uploaded,
            QueueState.unreadable,
            QueueState.cancelled,
          }.contains(i.state))
            i,
    ].length;
    final appStore = ref.watch(updateFromAppStoreProvider);

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  ClSpace.s6,
                  20,
                  ClSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UpdateArt(from: status.installed, to: status.latest),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.upRequiredTitle,
                              style: cl.text.largeTitle.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: ClSpace.s3),
                          Text(
                            l10n.upRequiredBody,
                            style: cl.text.body.copyWith(
                              fontSize: 15,
                              height: 1.5,
                              color: cl.colors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: ClSpace.s3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cl.colors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                _SafeRow(
                                  icon: ClIcons.lock,
                                  title: l10n.upSafeTitle,
                                  body: l10n.upSafeBody,
                                ),
                                if (pending > 0) ...[
                                  const SizedBox(height: 10),
                                  _SafeRow(
                                    icon: ClIcons.cloudOff,
                                    title: l10n.upPendingTitle(pending),
                                    body: l10n.upPendingBody,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                ClSpace.s2,
                24,
                ClSpace.s4,
              ),
              child: Column(
                children: [
                  ClButton(
                    key: const Key('upStore'),
                    label: appStore ? l10n.upOpenAppStore : l10n.upOpenPlay,
                    expand: true,
                    onPressed: () => openStore(context, ref, status.storeUrl),
                  ),
                  if (notes != null)
                    _TextAction(
                      label: l10n.upWhatsNewIn('${notes.version}'),
                      onTap: () => openWhatsNew(context, notes),
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

/// UP1's picture: the app icon with an "up" badge over soft circles, and "1.0.3 → 1.2.0".
class _UpdateArt extends StatelessWidget {
  const _UpdateArt({required this.from, required this.to});
  final AppVersion from;
  final AppVersion to;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ExcludeSemantics(
      child: Container(
        height: 300,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cl.colors.sunshineSoft, cl.colors.mintSoft],
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 24,
              right: 20,
              child: _Dot(size: 90, color: cl.colors.sunshine),
            ),
            Positioned(
              top: 60,
              child: _Dot(
                size: 200,
                color: cl.colors.surface.withValues(alpha: 0.6),
              ),
            ),
            Positioned(
              top: 100,
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const ClLogo(height: 64),
              ),
            ),
            Positioned(
              top: 160,
              child: Transform.translate(
                offset: const Offset(46, 0),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cl.colors.mintDeep,
                    shape: BoxShape.circle,
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: ClIcon(
                      ClIcons.arrowRight,
                      size: 18,
                      color: cl.colors.onMintDeep,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 246,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$from',
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClIcon(
                      ClIcons.arrowRight,
                      size: 14,
                      color: cl.colors.inkMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$to',
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cl.colors.mintText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _SafeRow extends StatelessWidget {
  const _SafeRow({required this.icon, required this.title, required this.body});
  final ClIcons icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClIcon(icon, size: 18, color: cl.colors.mintText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: cl.text.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cl.colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: cl.text.caption.copyWith(
                  color: cl.colors.inkMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 44,
          minWidth: double.infinity,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cl.colors.mintText,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- UP2 · Có bản mới (không bắt buộc) ----------

/// Shows UP2 over Hôm nay once per offered version, then again after "Để sau" runs out.
class AppUpdatePrompt extends ConsumerStatefulWidget {
  const AppUpdatePrompt({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends ConsumerState<AppUpdatePrompt> {
  Timer? _wait;
  var _showing = false;

  @override
  void initState() {
    super.initState();
    final delegate = ref.read(routerProvider).routerDelegate;
    delegate.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _wait?.cancel();
    ref.read(routerProvider).routerDelegate.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted || _showing) return;
    final status = ref.read(appUpdateStatusProvider);
    final config = ref.read(appUpdateConfigProvider).value;
    if (status is! UpdateAvailable || config == null) return;
    final memory = ref.read(appUpdateMemoryProvider);
    if (memory.snoozed(status.latest, DateTime.now())) return;
    final router = ref.read(routerProvider);
    String path() => router.routerDelegate.currentConfiguration.uri.path;
    if (path() != Routes.today) return;
    // Let Hôm nay settle first; leaving it cancels the sheet.
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 1200), () {
      final context = router.routerDelegate.navigatorKey.currentContext;
      if (!mounted || context == null) return;
      if (path() != Routes.today) return;
      _showing = true;
      ref
          .read(appUpdateMemoryProvider.notifier)
          .snooze(status.latest, config.snoozeDays, DateTime.now());
      showClSheet<void>(
        context: context,
        builder: (_) => UpdateSheet(status: status, release: config.release),
      ).whenComplete(() => _showing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateStatusProvider, (_, _) => _check());
    return widget.child;
  }
}

class UpdateSheet extends ConsumerWidget {
  const UpdateSheet({required this.status, this.release, super.key});
  final UpdateAvailable status;
  final UpdateRelease? release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final highlights = release?.version == status.latest
        ? release!.highlights
        : const <UpdateHighlight>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, ClSpace.s2, 16, ClSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const ClLogo(height: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tag(l10n.upNewTag('${status.latest}')),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.upNewTitle,
                        style: cl.text.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final h in highlights) ...[
            const SizedBox(height: 14),
            _HighlightRow(highlight: h, lang: lang),
          ],
          const SizedBox(height: ClSpace.s4),
          ClButton(
            key: const Key('upUpdate'),
            label: l10n.upUpdate,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(openStore(context, ref, status.storeUrl));
            },
          ),
          _TextAction(
            key: const Key('upLater'),
            label: l10n.upLater,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight, required this.lang});
  final UpdateHighlight highlight;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (soft, ink) = toneColors(context, highlight.tone);
    return MergeSemantics(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClIcon(iconOf(highlight.icon), size: 20, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title.of(lang),
                  style: cl.text.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  highlight.body.of(lang),
                  style: cl.text.caption.copyWith(
                    fontSize: 13,
                    letterSpacing: 0,
                    color: cl.colors.inkMuted,
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

ClIcons iconOf(UpdateIcon icon) => switch (icon) {
  UpdateIcon.alert => ClIcons.alert,
  UpdateIcon.grid => ClIcons.grid,
  UpdateIcon.heart => ClIcons.heart,
  UpdateIcon.cake => ClIcons.cake,
  UpdateIcon.spark => ClIcons.spark,
  UpdateIcon.bell => ClIcons.bell,
  UpdateIcon.camera => ClIcons.camera,
  UpdateIcon.sleep => ClIcons.sleep,
  UpdateIcon.family => ClIcons.family,
  UpdateIcon.star => ClIcons.star,
};

/// (background, icon) for a UP2 row: the care colours, red for first aid.
(Color, Color) toneColors(BuildContext context, UpdateTone tone) {
  final c = context.cl.colors;
  final care = context.cl.care;
  return switch (tone) {
    UpdateTone.danger => (c.errorSoft, c.error),
    UpdateTone.growth => (care.growth.soft, care.growth.ink),
    UpdateTone.pump => (care.pump.soft, care.pump.ink),
    UpdateTone.sleep => (care.sleep.soft, care.sleep.ink),
    UpdateTone.bottle => (care.bottle.soft, care.bottle.ink),
    UpdateTone.mint => (c.mintSoft, c.mintText),
    UpdateTone.sunshine => (c.sunshineSoft, c.ink),
  };
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cl.colors.sunshine,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        label,
        style: cl.text.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: cl.colors.ink,
        ),
      ),
    );
  }
}

// ---------- UP3 / UP4 · Có gì mới ----------

/// The release's pages, full screen. Opening them closes the UP5 banner.
Future<void> openWhatsNew(BuildContext context, UpdateRelease release) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appUpdateMemoryProvider.notifier).closeBanner(release.version);
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => WhatsNewScreen(release: release),
    ),
  );
}

class WhatsNewScreen extends ConsumerStatefulWidget {
  const WhatsNewScreen({required this.release, super.key});
  final UpdateRelease release;

  @override
  ConsumerState<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends ConsumerState<WhatsNewScreen> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final pages = widget.release.pages;
    final last = _index >= pages.length - 1;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, ClSpace.s4, 8, 0),
              child: Row(
                children: [
                  Semantics(
                    label: l10n.upPageOf(_index + 1, pages.length),
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < pages.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            AnimatedContainer(
                              duration: ClMotion.quick,
                              width: i == _index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? cl.colors.mintDeep
                                    : cl.colors.controlBorder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ClPressable(
                    key: const Key('upSkip'),
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: l10n.upSkip,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 44,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: Text(
                            l10n.upSkip,
                            style: cl.text.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final p in pages)
                    _WhatsNewPage(page: p, version: widget.release.version),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                ClSpace.s2,
                24,
                ClSpace.s4,
              ),
              child: ClButton(
                key: const Key('upNext'),
                label: last ? l10n.upPagesDone : l10n.upNext,
                expand: true,
                onPressed: () {
                  if (last) {
                    Navigator.of(context).pop();
                  } else if (context.reduceMotion) {
                    _pages.jumpToPage(_index + 1);
                  } else {
                    _pages.nextPage(
                      duration: ClMotion.gentle,
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNewPage extends StatelessWidget {
  const _WhatsNewPage({required this.page, required this.version});
  final UpdatePage page;
  final AppVersion version;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final url = page.imageUrl;
    final placeholder = ColoredBox(
      color: cl.colors.mintSoft,
      child: const Center(child: ClLogo(height: 72)),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 18, bottom: ClSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url == null)
                      placeholder
                    else
                      Image.network(
                        url.toString(),
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => placeholder,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : ColoredBox(color: cl.colors.mintSoft),
                      ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.sunshine,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          l10n.upPageTag('$version'),
                          style: cl.text.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: cl.colors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    page.title.of(lang),
                    style: cl.text.largeTitle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: ClSpace.s3),
                Text(
                  page.body.of(lang),
                  style: cl.text.body.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: cl.colors.inkMuted,
                  ),
                ),
                if (page.where case final where?) ...[
                  const SizedBox(height: ClSpace.s3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClIcon(ClIcons.grid, size: 16, color: cl.colors.ink),
                        const SizedBox(width: 8),
                        Text(
                          where.of(lang),
                          style: cl.text.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: cl.colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- UP5 · Banner on Hôm nay ----------

/// "Đã cập nhật 1.2.0 · Sơ cứu, chi tiêu chung, lịch tiêm · Xem ×", after an update only.
class WhatsNewBanner extends ConsumerWidget {
  const WhatsNewBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(whatsNewBannerProvider);
    if (release == null) return const SizedBox.shrink();
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = l10n.upBannerTitle('${release.version}');
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: ClPressable(
        key: const Key('upBanner'),
        onPressed: () => openWhatsNew(context, release),
        semanticLabel:
            '$title. ${release.summary.of(lang)}. ${l10n.upBannerSee}',
        child: Container(
          padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: cl.colors.sunshineSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cl.colors.sunshine,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClIcon(ClIcons.spark, size: 18, color: cl.colors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      release.summary.of(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cl.text.caption.copyWith(
                        letterSpacing: 0,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.upBannerSee,
                style: cl.text.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cl.colors.mintText,
                ),
              ),
              ClPressable(
                key: const Key('upBannerClose'),
                onPressed: () => ref
                    .read(appUpdateMemoryProvider.notifier)
                    .closeBanner(release.version),
                semanticLabel: l10n.upBannerClose,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: ClIcon(
                      ClIcons.close,
                      size: 16,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- UP6 · Tôi · Phiên bản ----------

/// "Phiên bản 1.0.3 · Có bản mới 1.2.0 · [Cập nhật]" in Tôi; up to date, "Đây là bản mới nhất"
/// (and the release pages when this version has them).
class AppVersionRow extends ConsumerWidget {
  const AppVersionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(appUpdateStatusProvider);
    final installed = ref.watch(installedVersionProvider).value;
    final release = ref.watch(appUpdateConfigProvider).value?.release;
    final notes =
        release != null &&
            release.version == installed &&
            release.pages.isNotEmpty
        ? release
        : null;
    final (newer, url) = switch (status) {
      UpdateAvailable(:final latest, :final storeUrl) => (latest, storeUrl),
      UpdateRequired(:final latest, :final storeUrl) => (latest, storeUrl),
      UpToDate() => (null, null),
    };
    return MeRow(
      key: const Key('meVersion'),
      icon: ClIcons.retry,
      title: l10n.meVersion(version),
      subtitle: newer != null
          ? l10n.upNewVersion('$newer')
          : l10n.upLatestVersion,
      trailing: newer != null ? _Tag(l10n.upUpdate) : null,
      onTap: newer != null
          ? () => openStore(context, ref, url)
          : notes != null
          ? () => openWhatsNew(context, notes)
          : null,
    );
  }
}
