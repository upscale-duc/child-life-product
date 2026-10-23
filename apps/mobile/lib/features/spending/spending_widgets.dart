import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../baby/baby_avatar_view.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import 'spending_currency.dart';
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_repository.dart';

/// What every spending screen reads: who is looking, with which rights, and today in the
/// baby's zone (R-061).
class SpendingScope {
  SpendingScope({
    required this.me,
    required this.baby,
    required this.access,
    required this.today,
    required this.expenses,
    required this.categories,
    required this.loading,
    this.currency = legacyCurrency,
  });

  final Membership me;
  final Baby? baby;
  final SpendingAccess access;
  final DateTime today;

  /// Live, newest first; only one's own without "Xem toàn bộ".
  final List<Expense> expenses;

  /// Every category of the family (hidden ones included), in order.
  final List<SpendingCategory> categories;
  final bool loading;

  /// The household's currency (D-075 #4): the add form's default, what totals and statistics
  /// count (other currencies show apart), a new budget's currency.
  final String currency;

  String get babyId => me.babyId;
  String get familyId => baby?.familyId ?? '';
  String get zone => baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';

  List<SpendingCategory> get visible => [
    for (final c in categories)
      if (!c.hidden) c,
  ];

  SpendingCategory category(String id) =>
      categories.where((c) => c.id == id).firstOrNull ??
      builtInCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => builtInCategories.last,
      );
}

SpendingScope? watchSpending(WidgetRef ref) => _scope(ref, watch: true);

/// The same, read once (callbacks, `initState`).
SpendingScope? readSpending(WidgetRef ref) => _scope(ref, watch: false);

SpendingScope? _scope(WidgetRef ref, {required bool watch}) {
  T get<T>(ProviderListenable<T> p) => watch ? ref.watch(p) : ref.read(p);
  final me = get(selectedMembershipProvider);
  if (me == null) return null;
  final baby = get(babyProvider(me.babyId)).value;
  final access = SpendingAccess.of(me);
  final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
  final now = get(careClockProvider).value ?? ref.read(timerClockProvider)();
  final expenses = access.any
      ? get(expensesProvider((me.babyId, access)))
      : const AsyncValue<List<Expense>>.data([]);
  final categories = baby == null
      ? null
      : get(spendingCategoriesProvider(baby.familyId)).value;
  // D-075 #4: the household's pick, else its country's currency, else VND.
  final settings = baby == null
      ? null
      : get(spendingSettingsProvider(baby.familyId)).value;
  final country = access.any
      ? get(selectedCapabilitiesProvider)?.country
      : null;
  return SpendingScope(
    currency: settings?.currency ?? currencyForCountry(country),
    me: me,
    baby: baby,
    access: access,
    today: babyToday(zone, now),
    expenses: expenses.value ?? const [],
    categories: categories ?? mergeCategories(const []),
    loading: !expenses.hasValue,
  );
}

/// The household's currency from a callback (D-075 #4): its pick, else its country's, else VND.
Future<String> householdCurrencyOf(ProviderContainer c, Membership me) async {
  try {
    final baby = c.read(babyProvider(me.babyId)).value;
    if (baby != null) {
      final p = spendingSettingsProvider(baby.familyId);
      // Riverpod pauses a provider nobody listens to: hold it while reading.
      final hold = c.listen(p, (_, _) {});
      try {
        final s = await c.read(p.future).timeout(const Duration(seconds: 2));
        if (s.currency != null) return s.currency!;
      } finally {
        hold.close();
      }
    }
  } on Object {
    // Offline or not loaded: the country's currency below.
  }
  return currencyForCountry(c.read(selectedCapabilitiesProvider)?.country);
}

/// The frame of a pushed spending screen: back (or close), the baby, a scrolling body and an
/// optional bottom bar with one primary button.
class SpPage extends ConsumerWidget {
  const SpPage({
    required this.children,
    this.bottom,
    this.trailing,
    this.close = false,
    this.showBaby = true,
    super.key,
  });

  final List<Widget> children;
  final Widget? bottom;
  final Widget? trailing;
  final bool close;
  final bool showBaby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: close ? null : () => Navigator.of(context).maybePop(),
                brand: close
                    ? SpRoundIcon(
                        icon: ClIcons.close,
                        label: l10n.a11yClose,
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    : null,
                trailing:
                    trailing ??
                    (baby == null || !showBaby
                        ? null
                        : ClBabySwitcher(
                            label: baby.nickname,
                            avatar: SavedBabyAvatar(baby: baby, size: 32),
                          )),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  (bottom == null ? media.padding.bottom : 0) + ClSpace.s8,
                ),
                children: children,
              ),
            ),
            if (bottom != null)
              Container(
                color: cl.colors.cloud,
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s3,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

class SpRoundIcon extends StatelessWidget {
  const SpRoundIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final ClIcons icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: cl.colors.ink),
      ),
    );
  }
}

class SpTitle extends StatelessWidget {
  const SpTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.cl.text.largeTitle),
  );
}

/// White card (radius 20, the card shadow).
class SpCard extends StatelessWidget {
  const SpCard({
    required this.child,
    this.padding = const EdgeInsets.all(ClSpace.s4),
    this.radius = 20,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cl.shadows.card,
      ),
      child: child,
    );
  }
}

/// A white list group (radius 16); rows sit on it without hairlines, as drawn.
class SpGroup extends StatelessWidget {
  const SpGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        boxShadow: cl.shadows.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Row titles in lists (SemiBold 15) and their sublines (Medium 12).
TextStyle spRowTitle(BuildContext context) => context.cl.text.body.copyWith(
  fontSize: 15,
  height: 20 / 15,
  fontWeight: FontWeight.w600,
);

TextStyle spRowSub(BuildContext context) => context.cl.text.caption.copyWith(
  color: context.cl.colors.inkMuted,
  fontWeight: FontWeight.w500,
);

/// The 36 px category chip (soft tint, 18 px icon in the tint's ink).
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.category, this.size = 36, super.key});
  final SpendingCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = tintColors(context, category.tint);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.soft,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: ClIcon(category.icon, size: size / 2, color: t.ink),
    );
  }
}

/// 8 px share bar on surface-2.
class ShareBar extends StatelessWidget {
  const ShareBar({
    required this.share,
    required this.color,
    this.height = 8,
    super.key,
  });

  final double share;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: cl.colors.surface2),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: share.clamp(0, 1).toDouble(),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tx" row: chip · title · subline · amount (· "Có hoá đơn").
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.category,
    required this.subline,
    this.onTap,
    super.key,
  });

  final Expense expense;
  final SpendingCategory category;
  final String subline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final locale = spLocale(context);
    final title = expense.note.isEmpty
        ? categoryName(l10n, category)
        : expense.note;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          CategoryBadge(category: category),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: spRowTitle(context),
                ),
                if (subline.isNotEmpty || expense.pending)
                  Text(
                    [
                      if (subline.isNotEmpty) subline,
                      if (expense.pending) l10n.spPending,
                    ].join(' · '),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClTabularText(
                money(locale, expense.amount, expense.currency),
                style: spRowTitle(context),
              ),
              if (expense.hasReceipt)
                Text(
                  l10n.spHasReceipt,
                  style: cl.text.caption.copyWith(
                    color: cl.colors.mintText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel:
          '$title, ${money(locale, expense.amount, expense.currency)}',
      child: SizedBox(width: double.infinity, child: row),
    );
  }
}

/// A category with its amount and share bar (8b, 8d).
class CategoryShareRow extends StatelessWidget {
  const CategoryShareRow({
    required this.category,
    required this.amount,
    required this.share,
    this.subline,
    this.trailing,
    this.barColor,
    this.currency = legacyCurrency,
    super.key,
  });

  final SpendingCategory category;
  final int amount;

  /// What [amount] is in (D-075 #4).
  final String currency;
  final double share;
  final String? subline;
  final String? trailing;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final t = tintColors(context, category.tint);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          CategoryBadge(category: category),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryName(l10n, category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: spRowTitle(context),
                      ),
                    ),
                    ClTabularText(
                      trailing ?? money(spLocale(context), amount, currency),
                      style: spRowTitle(context).copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ShareBar(share: share, color: barColor ?? t.accent),
                if (subline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subline!,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
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

/// Footnote / info banner (surface-2 or mint-soft, icon, muted text).
class SpBanner extends StatelessWidget {
  const SpBanner({
    required this.icon,
    required this.text,
    this.mint = false,
    super.key,
  });

  final ClIcons icon;
  final String text;
  final bool mint;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = mint ? cl.colors.mintText : cl.colors.inkMuted;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: mint ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(icon, size: 18, color: ink),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill with an icon (8b shortcuts).
class SpPill extends StatelessWidget {
  const SpPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final ClIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          border: Border.all(color: cl.colors.separator),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 14, color: cl.colors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small label above a form part ("Danh mục", "Ai trả").
class SpLabel extends StatelessWidget {
  const SpLabel(this.text, {this.trailing, super.key});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s4, bottom: ClSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(
                color: cl.colors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A choice chip: a category (8c, tinted when chosen) or a payer.
class SpChoiceChip extends StatelessWidget {
  const SpChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.tint,
    this.dashed = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ClIcons? icon;
  final CategoryTint? tint;

  /// "+ Danh mục".
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final t = tint == null ? null : tintColors(context, tint!);
    final fill = selected ? (t?.soft ?? cl.colors.mintSoft) : cl.colors.surface;
    final ink = dashed
        ? cl.colors.mintText
        : selected
        ? (t?.ink ?? cl.colors.mintText)
        : cl.colors.ink;
    final border = selected
        ? Border.all(color: t?.accent ?? cl.colors.mintDeep, width: 1.5)
        : Border.all(
            color: dashed ? cl.colors.controlBorder : cl.colors.separator,
          );
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ClIcon(
                icon!,
                size: 16,
                color: selected || dashed ? ink : (t?.ink ?? ink),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                color: ink,
                fontWeight: selected || dashed
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable row in a white group: icon chip · label · trailing.
class SpActionRow extends StatelessWidget {
  const SpActionRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  final ClIcons icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, size: 18, color: cl.colors.ink),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: spRowTitle(context)),
                if (value != null)
                  Text(
                    value!,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
              ],
            ),
          ),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : ClIcon(
                      ClIcons.chevronRight,
                      size: 18,
                      color: cl.colors.inkMuted,
                    )),
        ],
      ),
    );
    if (onTap == null) return row;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: value == null ? label : '$label, $value',
      child: SizedBox(width: double.infinity, child: row),
    );
  }
}

/// A small text link under the bottom-bar button ("Nhập từ app khác hoặc Excel").
class SpSmallLink extends StatelessWidget {
  const SpSmallLink({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ClIcon(icon!, size: 16, color: cl.colors.mintText),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: cl.text.label.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The primary bottom-bar button.
class SpBottomButton extends StatelessWidget {
  const SpBottomButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) =>
      ClButton(label: label, icon: icon, expand: true, onPressed: onPressed);
}
