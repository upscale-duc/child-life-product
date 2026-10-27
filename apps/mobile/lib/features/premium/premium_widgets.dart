import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'billing_models.dart';
import 'paywall_screen.dart';
import 'premium_models.dart';

/// MO03 (593:6797): "Đã mở Premium · tiếp tục chỗ bạn đang làm" on the template the parent was
/// brought back to after a verified purchase.
class ResumedBanner extends StatelessWidget {
  const ResumedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s3,
        vertical: ClSpace.s2,
      ),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: Row(
        children: [
          ClIcon(ClIcons.check, size: 16, color: cl.colors.mintText),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              AppLocalizations.of(context).pmResumedBanner,
              style: cl.text.label.copyWith(
                color: cl.colors.mintText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PR04 (593:6990): the plan ended, history stays. A quiet strip, never a lock over data; the
/// renewal link only for the owner (D-072 #1).
class PremiumExpiredStrip extends StatelessWidget {
  const PremiumExpiredStrip({
    required this.canRenew,
    this.entry = PaywallEntry.rhythm,
    super.key,
  });
  final bool canRenew;
  final PaywallEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ClIcon(ClIcons.lock, size: 16, color: cl.colors.ink),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pmExpiredStrip,
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
                if (canRenew)
                  ClPressable(
                    onPressed: () => openPaywall(context, entry: entry),
                    semanticLabel: l10n.pmRenewPremium,
                    child: Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s2),
                      child: Text(
                        l10n.pmRenewPremium,
                        style: cl.text.label.copyWith(
                          color: cl.colors.mintText,
                          fontWeight: FontWeight.w700,
                        ),
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

/// "làm mới 01/11" (vi) / "resets 1 Nov" (en): the window's end, never an ambiguous dd/mm in
/// English (I1).
String quotaResetDate(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context);
  final local = at.toLocal();
  return locale.languageCode == 'vi'
      ? DateFormat('dd/MM').format(local)
      : DateFormat.MMMd(locale.toLanguageTag()).format(local);
}

/// MO04 quota card (593:6843): "Lượt xuất video kỳ này · 3 / 5", a bar of used (deep) and
/// reserved (light) exports, "2 đã dùng · 1 đang giữ chỗ · làm mới 01/11. Thẻ ảnh không tính lượt."
class VideoQuotaCard extends StatelessWidget {
  const VideoQuotaCard({required this.quota, super.key});
  final VideoQuota quota;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final q = quota;
    if (q.unlimited) {
      return Text(l10n.premiumUnlimitedVideo, style: cl.text.bodyStrong);
    }
    final detail = q.resetsAt == null
        ? l10n.pmQuotaDetailNoDate(q.used, q.reserved)
        : l10n.pmQuotaDetail(
            q.used,
            q.reserved,
            quotaResetDate(context, q.resetsAt!),
          );
    final limit = q.limit <= 0 ? 1 : q.limit;
    return Semantics(
      container: true,
      label: '${l10n.pmQuotaTitle}: ${q.taken} / ${q.limit}. $detail',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.control + 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.pmQuotaTitle, style: cl.text.bodyStrong),
                ),
                Text(
                  '${q.taken} / ${q.limit}',
                  style: cl.text.bodyStrong.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.pill),
              child: SizedBox(
                height: 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.used > 0)
                      Expanded(
                        flex: q.used.clamp(0, limit),
                        child: ColoredBox(color: cl.colors.mintDeep),
                      ),
                    if (q.reserved > 0)
                      Expanded(
                        flex: q.reserved.clamp(0, limit),
                        child: ColoredBox(color: cl.colors.mint),
                      ),
                    if (limit - q.taken > 0)
                      Expanded(
                        flex: limit - q.taken,
                        child: ColoredBox(color: cl.colors.surface),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              '$detail. ${l10n.pmQuotaCards}',
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// MO04 "Khi hết lượt", after `QUOTA_EXCEEDED` from `requestMemoryStory`. Never a paywall: the
/// parent can still browse templates and make cards. "Xem Premium" only when the family is not
/// on Premium and the Premium budget is larger (both from the server).
Future<void> showVideoQuotaSheet(
  BuildContext context, {
  required VideoQuota? quota,
  required Capabilities? caps,
  String? occasion,
}) {
  final l10n = AppLocalizations.of(context);
  final premiumHelps =
      caps != null &&
      caps.plan != HouseholdPlan.premium &&
      quota?.premiumLimit != null &&
      quota!.premiumLimit! > quota.limit;
  return showClSheet<void>(
    context: context,
    builder: (sheet) {
      final cl = sheet.cl;
      final reset = quota?.resetsAt;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.pmQuotaOutTitle),
          Text(
            reset == null
                ? l10n.pmQuotaOutBodyNoDate
                : l10n.pmQuotaOutBody(quotaResetDate(sheet, reset)),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          if (quota != null) ...[
            const SizedBox(height: ClSpace.s3),
            VideoQuotaCard(quota: quota),
          ],
          if (premiumHelps) ...[
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.pmQuotaPremiumNote(quota.premiumLimit!),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.pmQuotaMakeCard,
            expand: true,
            onPressed: () {
              Navigator.of(sheet).pop();
              context.push(
                occasion == null
                    ? Routes.milestoneCard
                    : '${Routes.milestoneCard}?occasion=$occasion',
              );
            },
          ),
          const SizedBox(height: ClSpace.s2),
          if (premiumHelps) ...[
            ClButton(
              label: l10n.pmSeePremium,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(sheet).pop();
                openPaywall(context, entry: PaywallEntry.templates);
              },
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          ClButton(
            label: l10n.pmGateOk,
            style: premiumHelps ? ClButtonStyle.plain : ClButtonStyle.secondary,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
          const SizedBox(height: ClSpace.s4),
        ],
      );
    },
  );
}
