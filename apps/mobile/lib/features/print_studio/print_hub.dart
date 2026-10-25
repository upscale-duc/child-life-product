import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../l10n/app_localizations.dart';
import '../memories/memories_screen.dart' show MemoryCtx;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import 'print_repository.dart';
import 'print_models.dart';
import 'print_policy.dart';
import 'print_screen.dart';
import 'print_widgets.dart';

/// PS03: the catalogue sits beneath the existing child switcher and scrolling tabs.
class PrintKeepsakesView extends ConsumerWidget {
  const PrintKeepsakesView({required this.ctx, super.key});
  final MemoryCtx ctx;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context), cl = context.cl;
    if (!ctx.parentView) {
      return ClEmptyState(
        icon: ClIcons.lock,
        title: l.psTab,
        message: l.psForParents,
      );
    }
    final media =
        ref.watch(completeMediaProvider((ctx.babyId, true))).value ??
        const <MediaItem>[];
    final catalog = ref.watch(printCatalogProvider).value;
    final draft = ref.watch(printDraftProvider(ctx.babyId)).value;
    void open(String product, {bool info = false}) => context.push(
      '${Routes.printStudio}?product=$product&detail=1${info ? '&info=1' : ''}',
    );
    Widget quick(String label, ClIcons icon, String route) => Expanded(
      child: PrintCard(
        lifted: false,
        radius: 18,
        padding: const EdgeInsets.all(12),
        onTap: () => context.push(route),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cl.colors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClIcon(icon, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: cl.text.label.copyWith(
                  fontFamily: 'Be Vietnam Pro Keepsake',
                  height: 1.3,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Widget heading(
      String title, {
      bool delivery = false,
      VoidCallback? onTap,
    }) => Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: cl.text.headline.copyWith(
              fontFamily: 'Be Vietnam Pro Keepsake',
              height: 1.3,
              fontSize: delivery ? 20 : 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (delivery)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l.psNationwide,
              style: cl.text.caption.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.3,
                fontSize: 10,
                color: cl.colors.mintText,
              ),
            ),
          )
        else
          TextButton(
            onPressed: onTap,
            child: Text(
              l.psSeeAll,
              style: cl.text.caption.copyWith(
                fontFamily: 'Be Vietnam Pro Keepsake',
                height: 1.3,
                color: cl.colors.mintText,
              ),
            ),
          ),
      ],
    );
    Widget tile(String key, {bool info = false, bool firstYear = false}) {
      var d = newPrintDesign(ctx, media, key, l);
      if (info) {
        d = d.copy({
          'pageLayouts': ['text'],
          'pagePhotos': [<int>[]],
        });
      }
      if (firstYear) d = d.copy({'style': 'timeless', 'title': l.psFirstYear});
      final price = catalog?.price(d);
      return Expanded(
        child: PrintCard(
          padding: const EdgeInsets.all(8),
          onTap: () => open(key, info: info),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrintScene(
                design: d,
                media: media,
                standing: !d.isBook,
                decorated: false,
                page: info
                    ? 0
                    : key == 'five'
                    ? 2
                    : null,
                height: d.isBook ? 118 : 90,
              ),
              const SizedBox(height: 7),
              Text(
                firstYear
                    ? l.psFirstYear
                    : info
                    ? l.psInformationFrame
                    : d.isBook
                    ? l.psBook
                    : printProductName(l, key),
                style: cl.text.caption.copyWith(
                  fontFamily: 'Be Vietnam Pro Keepsake',
                  height: 1.3,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cl.colors.ink,
                ),
              ),
              if (price != null)
                Text(
                  d.isBook
                      ? '${l.psBookPagesCount('${d.pages}')} · ${printMoney(context, price)}'
                      : key == 'single'
                      ? l.psFromPrice(printMoney(context, price))
                      : printMoney(context, price),
                  style: cl.text.caption.copyWith(
                    fontFamily: 'Be Vietnam Pro Keepsake',
                    height: 1.3,
                    fontSize: 11,
                    color: cl.colors.mintText,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final hero = newPrintDesign(ctx, media, 'trio', l);
    void policy() => showPrintPolicy(context, catalog ?? PrintCatalog({}));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 230),
      children: [
        Text(
          l.psMadeFrom(ctx.nickname),
          style: cl.text.caption.copyWith(
            fontFamily: 'Be Vietnam Pro Keepsake',
            height: 1.3,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            quick(l.ksVideoTitle, ClIcons.camera, Routes.memoryStory),
            const SizedBox(width: 10),
            quick(l.ksCardTitle, ClIcons.star, Routes.milestoneCard),
          ],
        ),
        if (draft != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ClButton(
              label: l.psResume,
              style: ClButtonStyle.tinted,
              onPressed: () => context.push('${Routes.printStudio}?resume=1'),
            ),
          ),
        const SizedBox(height: 14),
        heading(l.psTitle, delivery: true),
        const SizedBox(height: 12),
        PrintCard(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          onTap: () => open('trio'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrintScene(
                design: hero,
                media: media,
                height: 230,
                standing: true,
                decorated: false,
              ),
              const SizedBox(height: 10),
              Text(
                l.psHeroTitle(hero.title),
                style: cl.text.label.copyWith(
                  fontFamily: 'Be Vietnam Pro Keepsake',
                  height: 1.3,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (catalog?.price(hero) case final price?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    printMoney(context, price),
                    style: cl.text.label.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        heading(
          l.psFrames,
          onTap: () => context.push('${Routes.printStudio}?select=1'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tile('single'),
            const SizedBox(width: 8),
            tile('five'),
            const SizedBox(width: 8),
            tile('single', info: true),
          ],
        ),
        const SizedBox(height: 8),
        heading(l.psBooks, onTap: () => open('book')),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tile('book'),
            const SizedBox(width: 8),
            tile('book', firstYear: true),
          ],
        ),
        const SizedBox(height: 14),
        PrintCard(
          lifted: false,
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _HubRow(
                icon: ClIcons.journal,
                title: l.psOrders,
                onTap: () => context.push(Routes.printStudioOrders),
              ),
              _HubRow(
                icon: ClIcons.alert,
                title: l.psPolicy,
                subtitle: l.psPolicySummary,
                onTap: policy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final ClIcons icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cl.colors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClIcon(icon, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.cl.text.label.copyWith(
                    fontFamily: 'Be Vietnam Pro Keepsake',
                    height: 1.3,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.cl.text.caption.copyWith(
                      fontFamily: 'Be Vietnam Pro Keepsake',
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const ClIcon(ClIcons.chevronRight, size: 16),
        ],
      ),
    ),
  );
}
